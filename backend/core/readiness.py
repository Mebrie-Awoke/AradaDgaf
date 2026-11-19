import logging

from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from .db import get_database

logger = logging.getLogger(__name__)


class ReadinessCheckView(APIView):
    """Return ready only when the configured MongoDB database is reachable."""

    permission_classes = [AllowAny]
    authentication_classes = []

    def get(self, request):
        try:
            database = get_database()
            database.command("ping")
        except Exception:
            logger.exception("Backend readiness check failed")
            return Response(
                {"success": False, "message": "Backend dependencies are unavailable."},
                status=503,
            )

        return Response({
            "success": True,
            "message": "AradaDgaf API and database are ready.",
            "service": "AradaDgaf Backend",
            "database": "connected",
        })
