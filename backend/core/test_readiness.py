from unittest.mock import patch, MagicMock

from django.test import TestCase
from rest_framework.test import APIClient


class ReadinessCheckTests(TestCase):
    def setUp(self):
        self.client = APIClient()

    @patch("core.readiness.get_database")
    def test_readiness_returns_200_when_mongodb_is_available(self, get_database):
        database = MagicMock()
        database.name = "AradaDgaf"
        get_database.return_value = database

        response = self.client.get("/api/ready/")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["database"], "connected")
        database.command.assert_called_once_with("ping")

    @patch("core.readiness.get_database", side_effect=RuntimeError("MongoDB is not configured"))
    def test_readiness_returns_503_when_mongodb_is_unavailable(self, get_database):
        response = self.client.get("/api/ready/")

        self.assertEqual(response.status_code, 503)
        self.assertFalse(response.json()["success"])
