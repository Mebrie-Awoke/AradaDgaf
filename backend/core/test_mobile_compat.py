from datetime import datetime, timezone

from django.test import SimpleTestCase

from .mobile_compat import (
    MobileTicketCreateSerializer,
    MobileWorkRecordSerializer,
    mobile_notification,
    mobile_status,
    mobile_ticket,
)


class MobileCompatibilityTests(SimpleTestCase):
    def test_existing_backend_statuses_map_to_flutter_status_names(self):
        cases = {
            "submitted": "submitted",
            "assigned": "inProgress",
            "in_progress": "inProgress",
            "resolved": "resolved",
            "closed": "resolved",
        }
        for backend_status, expected in cases.items():
            with self.subTest(status=backend_status):
                self.assertEqual(mobile_status({"status": backend_status}), expected)

    def test_work_outcome_overrides_resolved_status_for_flutter(self):
        self.assertEqual(
            mobile_status({"status": "resolved", "mobile_status": "notResolved"}),
            "notResolved",
        )
        self.assertEqual(
            mobile_status({"status": "resolved", "mobile_status": "referred"}),
            "referred",
        )

    def test_ticket_response_uses_flutter_model_field_names(self):
        created = datetime(2026, 11, 16, tzinfo=timezone.utc)
        payload = mobile_ticket({
            "number": "AD-2026-0423",
            "category": "maintenance",
            "device_type": "computer",
            "problem_description": "Computer cannot connect to network.",
            "department": "IT Office",
            "office_location": "Building B",
            "phone_number": "+251911112222",
            "created_at": created,
            "status": "submitted",
            "owner_name": "Selam Tesfaye",
            "timeline": [],
        })
        self.assertEqual(payload["id"], "AD-2026-0423")
        self.assertEqual(payload["category"], "maintenance")
        self.assertEqual(payload["deviceType"], "computer")
        self.assertEqual(payload["problemDescription"], "Computer cannot connect to network.")
        self.assertEqual(payload["status"], "submitted")
        self.assertEqual(payload["requesterName"], "Selam Tesfaye")
        self.assertIn("workRecord", payload)
        self.assertIn("rating", payload)
        self.assertIn("timeline", payload)

    def test_mobile_ticket_creation_accepts_current_flutter_categories_and_devices(self):
        serializer = MobileTicketCreateSerializer(data={
            "category": "maintenance",
            "device_type": "copyMachine",
            "problem_description": "Copy machine is not working.",
            "department": "Finance",
            "office_location": "Building A",
            "phone_number": "+251911112222",
            "requester_name": "Employee",
        })
        self.assertTrue(serializer.is_valid(), serializer.errors)

    def test_mobile_ticket_creation_rejects_unknown_category(self):
        serializer = MobileTicketCreateSerializer(data={
            "category": "urgent",
            "device_type": "computer",
            "problem_description": "Issue details",
            "department": "Finance",
            "office_location": "Building A",
            "phone_number": "+251911112222",
        })
        self.assertFalse(serializer.is_valid())
        self.assertIn("category", serializer.errors)

    def test_work_record_uses_flutter_enum_values(self):
        serializer = MobileWorkRecordSerializer(data={
            "device_type": "Computer",
            "model": "Dell OptiPlex",
            "serial_number": "SN12345",
            "problem_description": "Replaced faulty memory.",
            "tools_materials": "Screwdriver",
            "outcome": "solutionGiven",
        })
        self.assertTrue(serializer.is_valid(), serializer.errors)

    def test_notification_shape_matches_flutter_model(self):
        created = datetime(2026, 11, 16, tzinfo=timezone.utc)
        payload = mobile_notification({
            "_id": "notification-1",
            "kind": "ticket_created",
            "title": "Your request AD-2026-0423 has been submitted.",
            "message": "Waiting for technician assignment.",
            "ticket_number": "AD-2026-0423",
            "created_at": created,
            "read": False,
        })
        self.assertEqual(payload["id"], "notification-1")
        self.assertEqual(payload["ticketId"], "AD-2026-0423")
        self.assertEqual(payload["type"], "submitted")
        self.assertFalse(payload["isRead"])
