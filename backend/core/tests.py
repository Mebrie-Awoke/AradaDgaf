from datetime import datetime, timezone
from unittest.mock import MagicMock, patch

from bson import ObjectId
from django.contrib.auth.hashers import check_password, make_password
from django.test import TestCase
from rest_framework.test import APIClient

from .authentication import MongoUser
from .permissions import can_access_ticket


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
        self.assertEqual(stored["status"], "open")
        self.assertEqual(stored["number"], f"NX-{datetime.now(timezone.utc).year}-000007")
        database.ticket_audit.insert_one.assert_called_once()

    @patch("core.views.get_database")
    def test_employee_cannot_change_priority_or_access_other_users_ticket(self, get_database):
        database = MagicMock()
        ticket_id = ObjectId()
        ticket = {"_id": ticket_id, "owner_id": self.employee_id, "status": "open", "version": 1}
        database.tickets.find_one.return_value = ticket
        get_database.return_value = database
        self.client.force_authenticate(user=self.employee)
        response = self.client.patch(f"/api/v1/tickets/{ticket_id}/", {"priority": "urgent"}, format="json")
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
            "_id": ticket_id, "number": "NX-2026-000001", "owner_id": self.employee_id,
            "status": "in_progress", "priority": "normal", "version": 1,
        }
        database.tickets.find_one.return_value = ticket
        database.tickets.find_one_and_update.return_value = {**ticket, "status": "resolved", "version": 2}
        get_database.return_value = database
        support = MongoUser({**self.employee_doc, "_id": ObjectId(), "role": "support"})
        self.client.force_authenticate(user=support)
        response = self.client.patch(f"/api/v1/tickets/{ticket_id}/", {"status": "resolved"}, format="json")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["data"]["status"], "resolved")
        self.assertEqual(database.tickets.find_one_and_update.call_args.args[0]["version"], 1)
        database.ticket_audit.insert_one.assert_called_once()
        database.notifications.insert_one.assert_called_once()