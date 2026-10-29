import hashlib
from datetime import datetime, timezone

from rest_framework.authentication import BaseAuthentication, get_authorization_header
from rest_framework.exceptions import AuthenticationFailed

from .db import get_database


class MongoUser:
    is_authenticated = True
    is_anonymous = False

    def __init__(self, document):
        self.id = str(document["_id"])
        self.email = document["email"]
        self.name = document.get("name", "")
        self.role = document["role"]
        self.department_id = str(document["department_id"]) if document.get("department_id") else None
        self.is_active = document.get("is_active", True)
        self.is_staff = self.role == "admin"


class BearerTokenAuthentication(BaseAuthentication):
    def authenticate(self, request):
        parts = get_authorization_header(request).split()
        if not parts:
            return None
        if len(parts) != 2 or parts[0].lower() != b"bearer":
            raise AuthenticationFailed("Use an Authorization: Bearer <token> header.")
        try:
            token = parts[1].decode("ascii")
        except UnicodeDecodeError as exc:
            raise AuthenticationFailed("Invalid access token.") from exc
        digest = hashlib.sha256(token.encode("utf-8")).hexdigest()
        database = get_database()
        session = database.access_tokens.find_one({"token_hash": digest})
        if not session or session["expires_at"] <= datetime.now(timezone.utc):
            raise AuthenticationFailed("Invalid or expired access token.")
        user = database.users.find_one({"_id": session["user_id"], "is_active": {"$ne": False}})
        if not user:
            raise AuthenticationFailed("User account is inactive or unavailable.")
        return MongoUser(user), session

    def authenticate_header(self, request):
        return "Bearer"