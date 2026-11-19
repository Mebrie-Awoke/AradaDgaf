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

    def test_ticket_access_is_limited_to_owner_assignee_or_admin(self):
        ticket = {"owner_id": self.employee_id}
        other = MongoUser({**self.employee_doc, "_id": ObjectId()})
        support_id = ObjectId()
        support = MongoUser({**self.employee_doc, "_id": support_id, "role": "support"})
        admin = MongoUser({**self.employee_doc, "_id": ObjectId(), "role": "admin"})
        self.assertTrue(can_access_ticket(self.employee, ticket))
        self.assertFalse(can_access_ticket(other, ticket))
        self.assertFalse(can_access_ticket(support, ticket))
        ticket["assigned_to"] = support_id
        self.assertTrue(can_access_ticket(support, ticket))
        self.assertTrue(can_access_ticket(admin, ticket))

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
        support_id = ObjectId()
        ticket = {
            "_id": ticket_id, "number": "AF-2026-000001", "owner_id": self.employee_id,
            "assigned_to": support_id,
            "status": "in_progress", "priority": "medium", "version": 1,
        }
        database.tickets.find_one.return_value = ticket
        database.tickets.find_one_and_update.return_value = {**ticket, "status": "resolved", "resolution_note": "Reconfigured the network adapter.", "version": 2}
        get_database.return_value = database
        support = MongoUser({**self.employee_doc, "_id": support_id, "role": "support"})
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


    @patch("core.views.get_database")
    def test_employee_cannot_create_internal_comment(self, get_database):
        ticket = self.attachment_ticket()
        database = MagicMock()
        database.tickets.find_one.return_value = ticket
        get_database.return_value = database
        self.client.force_authenticate(user=self.employee)

        response = self.client.post(
            f"/api/v1/tickets/{ticket['_id']}/comments/",
            {"body": "Internal support note", "internal_only": True},
            format="json",
        )

        self.assertEqual(response.status_code, 403)
        database.ticket_comments.insert_one.assert_not_called()

    @patch("core.views.get_database")
    def test_employee_comment_list_excludes_internal_notes(self, get_database):
        ticket = self.attachment_ticket()
        database = MagicMock()
        database.tickets.find_one.return_value = ticket
        database.ticket_comments.count_documents.return_value = 0
        get_database.return_value = database
        self.client.force_authenticate(user=self.employee)

        response = self.client.get(f"/api/v1/tickets/{ticket['_id']}/comments/")

        self.assertEqual(response.status_code, 200)
        database.ticket_comments.count_documents.assert_called_once_with({
            "ticket_id": ticket["_id"], "internal_only": {"$ne": True},
        })

    @patch("core.views.get_database")
    def test_dashboard_limits_employee_ticket_counts_to_owner(self, get_database):
        database = MagicMock()
        database.tickets.aggregate.side_effect = [[], []]
        database.tickets.count_documents.return_value = 2
        database.notifications.count_documents.return_value = 1
        get_database.return_value = database
        self.client.force_authenticate(user=self.employee)

        response = self.client.get("/api/v1/dashboard/")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["data"]["total_tickets"], 2)
        database.tickets.count_documents.assert_called_once_with({"owner_id": self.employee_id})

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

    @patch("core.mobile_compat.get_database")
    def test_mobile_registration_creates_pending_account_with_reference(self, get_database):
        database = MagicMock()
        database.users.find_one.return_value = None
        database.departments.find_one.return_value = {"_id": ObjectId(), "name": "Finance Department"}
        database.counters.find_one_and_update.return_value = {"sequence": 42}
        new_id = ObjectId()
        database.users.insert_one.return_value.inserted_id = new_id
        get_database.return_value = database

        response = self.client.post("/api/mobile/auth/register/", {
            "fullName": "Abebe Tessema",
            "employeeId": "EMP-9021",
            "username": "abebe.t",
            "password": "Password123!",
            "phone": "0911223344",
            "department": "Finance Department",
            "role": "employee",
        }, format="json")

        self.assertEqual(response.status_code, 201)
        data = response.json()["data"]
        self.assertEqual(data["status"], "pending")
        self.assertTrue(data["referenceNumber"].startswith("REG-"))
        self.assertEqual(data["referenceNumber"], f"REG-{datetime.now(timezone.utc).year}-0042")
        stored = database.users.insert_one.call_args.args[0]
        self.assertEqual(stored["status"], "pending")
        self.assertFalse(stored["is_active"])
        self.assertEqual(stored["phone_number"], "+251911223344")
        self.assertTrue(check_password("Password123!", stored["password"]))

    @patch("core.mobile_compat.get_database")
    def test_mobile_login_returns_machine_readable_error_for_non_active_accounts(self, get_database):
        database = MagicMock()
        get_database.return_value = database
        hashed = make_password("Secret123!")

        # 1. Pending account
        database.users.find_one.return_value = {
            "_id": ObjectId(),
            "username": "pending_user",
            "password": hashed,
            "status": "pending",
            "is_active": False,
            "role": "employee",
            "registration_reference": "REG-2026-0001",
        }
        res_pending = self.client.post("/api/mobile/auth/login/", {
            "username": "pending_user",
            "password": "Secret123!",
        }, format="json")
        self.assertEqual(res_pending.status_code, 403)
        self.assertEqual(res_pending.json()["error"], "account_pending")
        self.assertNotIn("access_token", res_pending.json())

        # 2. Rejected account
        database.users.find_one.return_value = {
            "_id": ObjectId(),
            "username": "rejected_user",
            "password": hashed,
            "status": "rejected",
            "is_active": False,
            "role": "employee",
            "rejection_reason": "Employee ID does not match records.",
            "registration_reference": "REG-2026-0002",
        }
        res_rejected = self.client.post("/api/mobile/auth/login/", {
            "username": "rejected_user",
            "password": "Secret123!",
        }, format="json")
        self.assertEqual(res_rejected.status_code, 403)
        self.assertEqual(res_rejected.json()["error"], "account_rejected")
        self.assertIn("Employee ID does not match", res_rejected.json()["reason"])
        self.assertNotIn("access_token", res_rejected.json())

        # 3. Suspended account
        database.users.find_one.return_value = {
            "_id": ObjectId(),
            "username": "suspended_user",
            "password": hashed,
            "status": "suspended",
            "is_active": False,
            "role": "employee",
        }
        res_suspended = self.client.post("/api/mobile/auth/login/", {
            "username": "suspended_user",
            "password": "Secret123!",
        }, format="json")
        self.assertEqual(res_suspended.status_code, 403)
        self.assertEqual(res_suspended.json()["error"], "account_suspended")
        self.assertNotIn("access_token", res_suspended.json())

    @patch("core.views.get_database")
    def test_admin_registration_endpoints_require_admin_permission(self, get_database):
        # Non-admin user gets 403 Forbidden
        self.client.force_authenticate(user=self.employee)
        res = self.client.get("/api/v1/registrations/")
        self.assertEqual(res.status_code, 403)

        # Admin user gets 200 OK
        admin_doc = {
            "_id": ObjectId(),
            "email": "admin@example.com",
            "role": "admin",
            "is_active": True,
        }
        admin_user = MongoUser(admin_doc)
        database = MagicMock()
        database.users.count_documents.return_value = 0
        database.users.find.return_value.sort.return_value.skip.return_value.limit.return_value = []
        get_database.return_value = database
        self.client.force_authenticate(user=admin_user)

        res_admin = self.client.get("/api/v1/registrations/")
        self.assertEqual(res_admin.status_code, 200)

    @patch("core.views.get_database")
    def test_admin_approve_and_reject_flows_with_audit(self, get_database):
        admin_doc = {
            "_id": ObjectId(),
            "email": "admin@example.com",
            "name": "Admin",
            "role": "admin",
            "is_active": True,
        }
        admin_user = MongoUser(admin_doc)
        self.client.force_authenticate(user=admin_user)

        database = MagicMock()
        target_id = ObjectId()
        target_doc = {
            "_id": target_id,
            "username": "target_tech",
            "email": "tech@example.com",
            "name": "Target Tech",
            "role": "support",
            "status": "pending",
            "is_active": False,
            "created_at": datetime.now(timezone.utc),
        }
        database.users.find_one.return_value = target_doc
        approved_doc = {**target_doc, "status": "active", "is_active": True, "specialties": ["Network"]}
        database.users.find_one_and_update.return_value = approved_doc
        get_database.return_value = database

        # Approve
        res_approve = self.client.post(f"/api/v1/registrations/{target_id}/approve/", {
            "specialties": ["Network"],
        }, format="json")
        self.assertEqual(res_approve.status_code, 200)
        self.assertEqual(res_approve.json()["data"]["user"]["status"], "active")
        database.admin_audit.insert_one.assert_called()

        # Reject
        rejected_doc = {**target_doc, "status": "rejected", "is_active": False, "rejection_reason": "Incomplete profile details"}
        database.users.find_one_and_update.return_value = rejected_doc
        res_reject = self.client.post(f"/api/v1/registrations/{target_id}/reject/", {
            "reason": "Incomplete profile details",
        }, format="json")
        self.assertEqual(res_reject.status_code, 200)
        self.assertEqual(res_reject.json()["data"]["user"]["status"], "rejected")
