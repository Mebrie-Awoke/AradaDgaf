from rest_framework.exceptions import APIException
from rest_framework.response import Response
from rest_framework.views import exception_handler
from pymongo.errors import DuplicateKeyError, PyMongoError


def api_exception_handler(exc, context):
    if isinstance(exc, DuplicateKeyError):
        return Response({"success": False, "error": {"detail": "A record with that unique value already exists.", "code": "unique_conflict"}}, status=409)
    if isinstance(exc, PyMongoError):
        return Response({"success": False, "error": {"detail": "Database service is temporarily unavailable.", "code": "database_unavailable"}}, status=503)
    if isinstance(exc, RuntimeError) and "MONGODB_URI" in str(exc):
        return Response({"success": False, "error": {"detail": "Database service is not configured.", "code": "database_unavailable"}}, status=503)
    response = exception_handler(exc, context)
    if response is not None:
        detail = response.data
        if isinstance(exc, APIException):
            response.data = {"success": False, "error": {"detail": detail, "code": exc.default_code}}
        else:
            response.data = {"success": False, "error": {"detail": detail}}
        return response
    return Response({"success": False, "error": {"detail": "An unexpected error occurred."}}, status=500)