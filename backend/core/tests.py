from io import BytesIO
from datetime import datetime, timezone
from tempfile import TemporaryDirectory
from unittest.mock import MagicMock, patch

from bson import ObjectId
from django.contrib.auth.hashers import check_password, make_password
from django.core.files.uploadedfile import SimpleUploadedFile
from django.core.files.storage import FileSystemStorage
from django.test import TestCase, override_settings
from pymongo.errors import PyMongoError
from rest_framework.test import APIClient

from .authentication import MongoUser
from .permissions import can_access_ticket
from .serializers import AttachmentMetadataSerializer


class ApiTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.employee_id = ObjectId()
        self.employee_doc = {
            "_id": self.employee_id,
            "email": "employee@example.com",
            "name": "Employee",
            "role": "employee",
            "is_active": True,
            "created_at": datetime.now(timezone.utc),
        }
        self.employee = MongoUser(self.employee_doc)

    def test_health_endpoint_remains_available(self):
        response = self.client.get("/api/health/")
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.json()["success"])

    @patch("core.views.get_database")
    def test_registration_hashes_password_and_cannot_choose_role(self, get_database):
        database = MagicMock()
        database.users.insert_one.return_value.inserted_id = self.employee_id
        get_database.return_value = database
        response = self.client.post("/api/v1/auth/register/", {
            "email": "Employee@Example.com", "name": "Employee",
            "password": "Correct-Horse-Battery-42!", "role": "admin",
        }, format="json")
        self.assertEqual(response.status_code, 201)
        stored = database.users.insert_one.call_args.args[0]
        self.assertEqual(stored["role"], "employee")
        self.assertNotEqual(stored["password"], "Correct-Horse-Battery-42!")
        self.assertTrue(check_password("Correct-Horse-Battery-42!", stored["password"]))
        self.assertNotIn("password", response.json()["data"]["user"])

    @patch("core.views.get_database")
    def test_login_stores_only_token_digest_and_logout_revokes_it(self, get_database):
        database = MagicMock()
        user = {**self.employee_doc, "password": make_password("Correct-Horse-Battery-42!")}
        database.users.find_one.return_value = user
        get_database.return_value = database
        login = self.client.post("/api/v1/auth/login/", {
            "email": "EMPLOYEE@example.com", "password": "Correct-Horse-Battery-42!",
        }, format="json")
        self.assertEqual(login.status_code, 200)
        token = login.json()["data"]["access_token"]
        stored_session = database.access_tokens.insert_one.call_args.args[0]
        self.assertNotEqual(stored_session["token_hash"], token)
        self.client.force_authenticate(user=self.employee, token={"_id": ObjectId()})
        logout = self.client.post("/api/v1/auth/logout/", {}, format="json")
        self.assertEqual(logout.status_code, 200)
        database.access_tokens.delete_one.assert_called_once()

    def test_ticket_ownership_is_limited_to_owner_or_support(self):
        ticket = {"owner_id": self.employee_id}
        other = MongoUser({**self.employee_doc, "_id": ObjectId()})
        support = MongoUser({**self.employee_doc, "role": "support"})
        self.assertTrue(can_access_ticket(self.employee, ticket))
        self.assertFalse(can_access_ticket(other, ticket))
        self.assertTrue(can_access_ticket(support, ticket))

    @patch("core.views.get_database")
    def test_employee_creates_ticket_with_server_owned_fields_and_audit(self, get_database):
        database = MagicMock()
        database.counters.find_one_and_update.return_value = {"sequence": 7}
        database.tickets.insert_one.return_value.inserted_id = ObjectId()
        get_database.return_value = database
        self.client.force_authenticate(user=self.employee)
        response = self.client.post("/api/v1/tickets/", {
            "title": "Cannot connect to VPN", "description": "Connection fails from the office network.",
            "priority": "high", "owner_id": str(ObjectId()), "status": "closed",
        }, format="json")
        self.assertEqual(response.status_code, 201)
        stored = database.tickets.insert_one.call_args.args[0]
        self.assertEqual(stored["owner_id"], self.employee_id)
        self.assertEqual(stored["status"], "submitted")
        self.assertEqual(stored["number"], f"AF-{datetime.now(timezone.utc).year}-00007")
        database.ticket_audit.insert_one.assert_called_once()

    @patch("core.views.get_database")
    def test_employee_cannot_change_priority_or_access_other_users_ticket(self, get_database):
        database = MagicMock()
        ticket_id = ObjectId()
        ticket = {"_id": ticket_id, "owner_id": self.employee_id, "status": "submitted", "version": 1}
        database.tickets.find_one.return_value = ticket
        get_database.return_value = database
        self.client.force_authenticate(user=self.employee)
        response = self.client.patch(f"/api/v1/tickets/{ticket_id}/", {"priority": "critical"}, format="json")
        self.assertEqual(response.status_code, 403)
        ticket["owner_id"] = ObjectId()
        response = self.client.get(f"/api/v1/tickets/{ticket_id}/")
        self.assertEqual(response.status_code, 404)

    def test_invalid_ticket_priority_is_rejected(self):
        self.client.force_authenticate(user=self.employee)
        response = self.client.post("/api/v1/tickets/", {
            "title": "Issue", "description": "Details", "priority": "immediate",
        }, format="json")
        self.assertEqual(response.status_code, 400)

    @patch("core.views.get_database")
    def test_support_can_resolve_ticket_and_resolution_is_audited(self, get_database):
        database = MagicMock()
        ticket_id = ObjectId()
        ticket = {
            "_id": ticket_id, "number": "AF-2026-000001", "owner_id": self.employee_id,
            "status": "in_progress", "priority": "medium", "version": 1,
        }
        database.tickets.find_one.return_value = ticket
        database.tickets.find_one_and_update.return_value = {**ticket, "status": "resolved", "resolution_note": "Reconfigured the network adapter.", "version": 2}
        get_database.return_value = database
        support = MongoUser({**self.employee_doc, "_id": ObjectId(), "role": "support"})
        self.client.force_authenticate(user=support)
        response = self.client.patch(f"/api/v1/tickets/{ticket_id}/", {"status": "resolved", "resolution_note": "Reconfigured the network adapter."}, format="json")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["data"]["status"], "resolved")
        self.assertEqual(database.tickets.find_one_and_update.call_args.args[0]["version"], 1)
        database.ticket_audit.insert_one.assert_called_once()
        database.notifications.insert_one.assert_called_once()

    def attachment_ticket(self):
        return {
            "_id": ObjectId(),
            "number": "AF-2026-000009",
            "owner_id": self.employee_id,
        }

    @patch("core.views.private_attachment_storage")
    @patch("core.views.get_database")
    def test_attachment_upload_stores_file_and_metadata_without_exposing_storage_key(
        self, get_database, private_storage,
    ):
        ticket = self.attachment_ticket()
        database = MagicMock()
        database.tickets.find_one.return_value = ticket
        database.attachments.insert_one.return_value.inserted_id = ObjectId()
        get_database.return_value = database
        storage = MagicMock()
        storage.save.side_effect = lambda name, content: name
        private_storage.return_value = storage
        self.client.force_authenticate(user=self.employee)

        response = self.client.post(
            f"/api/v1/tickets/{ticket['_id']}/attachments/",
            {"file": SimpleUploadedFile(
                "photo.jpg", b"\xff\xd8\xffattachment test\xff\xd9", content_type="image/jpeg",
            )},
            format="multipart",
        )

        self.assertEqual(response.status_code, 201)
        document = database.attachments.insert_one.call_args.args[0]
        self.assertEqual(document["filename"], "photo.jpg")
        self.assertEqual(document["content_type"], "image/jpeg")
        self.assertEqual(document["size"], len(b"\xff\xd8\xffattachment test\xff\xd9"))
        self.assertRegex(document["storage_key"], rf"^{ticket['_id']}/[0-9a-f]{{32}}\.jpg$")
        self.assertNotIn("storage_key", response.json()["data"])
        storage.save.assert_called_once()

    @patch("core.views.private_attachment_storage")
    @patch("core.views.get_database")
    def test_attachment_download_streams_file_for_ticket_owner(self, get_database, private_storage):
        ticket = self.attachment_ticket()
        attachment_id = ObjectId()
        storage_key = f"{ticket['_id']}/{'a' * 32}.jpg"
        database = MagicMock()
        database.tickets.find_one.return_value = ticket
        database.attachments.find_one.return_value = {
            "_id": attachment_id,
            "ticket_id": ticket["_id"],
            "filename": "photo.jpg",
            "content_type": "image/jpeg",
            "size": 8,
            "storage_key": storage_key,
        }
        get_database.return_value = database
        storage = MagicMock()
        storage.open.return_value = BytesIO(b"\xff\xd8\xfftest\xff\xd9")
        private_storage.return_value = storage
        self.client.force_authenticate(user=self.employee)

        response = self.client.get(
            f"/api/v1/tickets/{ticket['_id']}/attachments/{attachment_id}/download/",
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(b"".join(response.streaming_content), b"\xff\xd8\xfftest\xff\xd9")
        self.assertIn("attachment", response["Content-Disposition"])
        self.assertEqual(response["Cache-Control"], "private, no-store")
        storage.open.assert_called_once_with(storage_key, "rb")

    @patch("core.views.private_attachment_storage")
    @patch("core.views.get_database")
    def test_local_private_storage_round_trips_attachment(self, get_database, private_storage):
        ticket = self.attachment_ticket()
        attachment_id = ObjectId()
        database = MagicMock()
        database.tickets.find_one.return_value = ticket
        database.attachments.insert_one.return_value.inserted_id = attachment_id
        get_database.return_value = database
        content = b"\xff\xd8\xffprivate attachment\xff\xd9"
        self.client.force_authenticate(user=self.employee)

        with TemporaryDirectory() as upload_root:
            storage = FileSystemStorage(location=upload_root)
            private_storage.return_value = storage
            upload_response = self.client.post(
                f"/api/v1/tickets/{ticket['_id']}/attachments/",
                {"file": SimpleUploadedFile(
                    "photo.jpg", content, content_type="image/jpeg",
                )},
                format="multipart",
            )
            self.assertEqual(upload_response.status_code, 201)
            attachment = database.attachments.insert_one.call_args.args[0]
            attachment["_id"] = attachment_id
            database.attachments.find_one.return_value = attachment

            download_response = self.client.get(
                f"/api/v1/tickets/{ticket['_id']}/attachments/{attachment_id}/download/",
            )

            self.assertEqual(download_response.status_code, 200)
            self.assertTrue(storage.exists(attachment["storage_key"]))
            self.assertEqual(b"".join(download_response.streaming_content), content)

    @patch("core.views.private_attachment_storage")
    @patch("core.views.get_database")
    def test_attachment_download_hides_other_users_ticket(self, get_database, private_storage):
        ticket = self.attachment_ticket()
        ticket["owner_id"] = ObjectId()
        database = MagicMock()
        database.tickets.find_one.return_value = ticket
        get_database.return_value = database
        self.client.force_authenticate(user=self.employee)

        response = self.client.get(
            f"/api/v1/tickets/{ticket['_id']}/attachments/{ObjectId()}/download/",
        )

        self.assertEqual(response.status_code, 404)
        database.attachments.find_one.assert_not_called()
        private_storage.assert_not_called()

    @patch("core.views.private_attachment_storage")
    @patch("core.views.get_database")
    def test_attachment_download_reports_missing_file(self, get_database, private_storage):
        ticket = self.attachment_ticket()
        attachment_id = ObjectId()
        database = MagicMock()
        database.tickets.find_one.return_value = ticket
        database.attachments.find_one.return_value = {
            "_id": attachment_id,
            "ticket_id": ticket["_id"],
            "filename": "photo.jpg",
            "content_type": "image/jpeg",
            "size": 8,
            "storage_key": f"{ticket['_id']}/{'a' * 32}.jpg",
        }
        get_database.return_value = database
        storage = MagicMock()
        storage.open.side_effect = FileNotFoundError
        private_storage.return_value = storage
        self.client.force_authenticate(user=self.employee)

        response = self.client.get(
            f"/api/v1/tickets/{ticket['_id']}/attachments/{attachment_id}/download/",
        )

        self.assertEqual(response.status_code, 404)

    @patch("core.views.private_attachment_storage")
    @patch("core.views.get_database")
    def test_invalid_attachment_content_is_rejected(self, get_database, private_storage):
        ticket = self.attachment_ticket()
        database = MagicMock()
        database.tickets.find_one.return_value = ticket
        get_database.return_value = database
        storage = MagicMock()
        private_storage.return_value = storage
        self.client.force_authenticate(user=self.employee)

        response = self.client.post(
            f"/api/v1/tickets/{ticket['_id']}/attachments/",
            {"file": SimpleUploadedFile(
                "fake.jpg", b"not a JPEG", content_type="image/jpeg",
            )},
            format="multipart",
        )

        self.assertEqual(response.status_code, 400)
        storage.save.assert_not_called()
        database.attachments.insert_one.assert_not_called()

    @override_settings(MAX_ATTACHMENT_BYTES=4)
    @patch("core.views.private_attachment_storage")
    @patch("core.views.get_database")
    def test_attachment_size_limit_is_enforced_before_storage(self, get_database, private_storage):
        ticket = self.attachment_ticket()
        database = MagicMock()
        database.tickets.find_one.return_value = ticket
        get_database.return_value = database
        storage = MagicMock()
        private_storage.return_value = storage
        self.client.force_authenticate(user=self.employee)

        response = self.client.post(
            f"/api/v1/tickets/{ticket['_id']}/attachments/",
            {"file": SimpleUploadedFile(
                "photo.jpg", b"\xff\xd8\xffxy", content_type="image/jpeg",
            )},
            format="multipart",
        )

        self.assertEqual(response.status_code, 400)
        storage.save.assert_not_called()

    @patch("core.views.private_attachment_storage")
    @patch("core.views.get_database")
    def test_attachment_storage_failure_returns_service_error(self, get_database, private_storage):
        ticket = self.attachment_ticket()
        database = MagicMock()
        database.tickets.find_one.return_value = ticket
        get_database.return_value = database
        storage = MagicMock()
        storage.save.side_effect = OSError("disk unavailable")
        private_storage.return_value = storage
        self.client.force_authenticate(user=self.employee)

        response = self.client.post(
            f"/api/v1/tickets/{ticket['_id']}/attachments/",
            {"file": SimpleUploadedFile(
                "photo.jpg", b"\xff\xd8\xffattachment test\xff\xd9", content_type="image/jpeg",
            )},
            format="multipart",
        )

        self.assertEqual(response.status_code, 503)
        database.attachments.insert_one.assert_not_called()

    @patch("core.views.private_attachment_storage")
    @patch("core.views.get_database")
    def test_database_failure_removes_saved_attachment(self, get_database, private_storage):
        ticket = self.attachment_ticket()
        database = MagicMock()
        database.tickets.find_one.return_value = ticket
        database.attachments.insert_one.side_effect = PyMongoError("database unavailable")
        get_database.return_value = database
        storage = MagicMock()
        storage.save.side_effect = lambda name, content: name
        private_storage.return_value = storage
        self.client.force_authenticate(user=self.employee)

        response = self.client.post(
            f"/api/v1/tickets/{ticket['_id']}/attachments/",
            {"file": SimpleUploadedFile(
                "photo.jpg", b"\xff\xd8\xffattachment test\xff\xd9", content_type="image/jpeg",
            )},
            format="multipart",
        )

        self.assertEqual(response.status_code, 503)
        saved_key = storage.save.call_args.args[0]
        storage.delete.assert_called_once_with(saved_key)
        database.attachments.delete_one.assert_called_once_with({"storage_key": saved_key})

    def test_attachment_serializer_does_not_accept_storage_keys_from_clients(self):
        serializer = AttachmentMetadataSerializer(data={
            "filename": "photo.jpg",
            "content_type": "image/jpeg",
            "size": 8,
            "storage_key": "../../private/photo.jpg",
        })

        self.assertTrue(serializer.is_valid(), serializer.errors)
        self.assertNotIn("storage_key", serializer.validated_data)

    def test_attachment_serializer_rejects_path_filenames(self):
        for filename in ("../photo.jpg", "folder\\photo.jpg", "report\n.jpg"):
            with self.subTest(filename=filename):
                serializer = AttachmentMetadataSerializer(data={
                    "filename": filename,
                    "content_type": "image/jpeg",
                    "size": 8,
                })

                self.assertFalse(serializer.is_valid())