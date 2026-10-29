import hashlib
import re
import secrets
from datetime import datetime, timedelta, timezone
from pathlib import Path
from uuid import uuid4

from bson import ObjectId
from django.conf import settings
from django.contrib.auth.hashers import check_password, make_password
from pymongo import DESCENDING, ReturnDocument
from rest_framework import status
from rest_framework.exceptions import APIException, AuthenticationFailed, NotFound, PermissionDenied, ValidationError
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .db import get_database
from .pagination import paginate_mongo
from .permissions import IsAdmin, can_access_ticket
from .serializers import (
    AttachmentMetadataSerializer, CommentSerializer, LoginSerializer,
    NamedResourceSerializer, ProvisionUserSerializer, RegistrationSerializer,
    TicketCreateSerializer, TicketUpdateSerializer,
)
from .utils import json_safe, public_user


def now():
    return datetime.now(timezone.utc)


def success(data, http_status=status.HTTP_200_OK):
    return Response({"success": True, "data": json_safe(data)}, status=http_status)


def parse_object_id(value, field="id"):
    if not ObjectId.is_valid(str(value)):
        raise ValidationError({field: "A valid identifier is required."})
    return ObjectId(str(value))


def require_reference(database, collection, value, field):
    if not value:
        return None
    reference_id = parse_object_id(value, field)
    if not database[collection].find_one({"_id": reference_id}):
        raise ValidationError({field: "The selected record does not exist."})
    return reference_id


def insert_audit(database, ticket, actor, action, changes=None):
    database.ticket_audit.insert_one({
        "ticket_id": ticket["_id"], "ticket_number": ticket["number"],
        "actor_id": ObjectId(actor.id), "actor_name": actor.name or actor.email,
        "action": action, "changes": changes or {}, "created_at": now(),
    })


def notify(database, user_id, kind, message, ticket):
    if user_id:
        database.notifications.insert_one({
            "user_id": ObjectId(str(user_id)), "kind": kind, "message": message,
            "ticket_id": ticket["_id"], "ticket_number": ticket["number"],
            "created_at": now(), "read": False,
        })


def get_ticket(database, ticket_id):
    ticket = database.tickets.find_one({"_id": parse_object_id(ticket_id, "ticket_id")})
    if not ticket:
        raise NotFound("Ticket not found.")
    return ticket


def check_ticket_access(user, ticket):
    if not can_access_ticket(user, ticket):
        raise NotFound("Ticket not found.")


class HealthCheckView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def get(self, request):
        return Response({
            "success": True,
            "message": "Nexora API is running successfully.",
            "service": "Nexora Backend",
        }, status=status.HTTP_200_OK)


class RegistrationView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        serializer = RegistrationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        database = get_database()
        values = serializer.validated_data
        department_id = require_reference(database, "departments", values.get("department_id"), "department_id")
        user = {
            "email": values["email"], "name": values["name"],
            "password": make_password(values["password"]), "role": "employee",
            "department_id": department_id, "is_active": True,
            "created_at": now(), "updated_at": now(),
        }
        inserted = database.users.insert_one(user)
        user["_id"] = inserted.inserted_id
        return success({"user": public_user(user)}, status.HTTP_201_CREATED)


class LoginView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        database = get_database()
        values = serializer.validated_data
        user = database.users.find_one({"email": values["email"]})
        if not user or not user.get("is_active", True) or not check_password(values["password"], user["password"]):
            raise AuthenticationFailed("Invalid email or password.")
        token = secrets.token_urlsafe(40)
        expires_at = now() + timedelta(seconds=settings.ACCESS_TOKEN_TTL_SECONDS)
        database.access_tokens.insert_one({
            "token_hash": hashlib.sha256(token.encode("utf-8")).hexdigest(),
            "user_id": user["_id"], "expires_at": expires_at, "created_at": now(),
        })
        return success({"access_token": token, "token_type": "Bearer", "expires_at": expires_at, "user": public_user(user)})


class LogoutView(APIView):
    def post(self, request):
        get_database().access_tokens.delete_one({"_id": request.auth["_id"]})
        return success({"message": "Logged out."})


class UsersView(APIView):
    permission_classes = [IsAdmin]

    def get(self, request):
        return paginate_mongo(get_database().users, request, projection={"password": 0}, transform=public_user)

    def post(self, request):
        serializer = ProvisionUserSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        database = get_database()
        values = serializer.validated_data
        department_id = require_reference(database, "departments", values.get("department_id"), "department_id")
        user = {
            "email": values["email"], "name": values["name"],
            "password": make_password(values["password"]), "role": values["role"],
            "department_id": department_id, "is_active": True,
            "created_at": now(), "updated_at": now(),
        }
        inserted = database.users.insert_one(user)
        user["_id"] = inserted.inserted_id
        return success({"user": public_user(user)}, status.HTTP_201_CREATED)


class TicketListCreateView(APIView):
    def get(self, request):
        database = get_database()
        query = {}
        if request.user.role == "employee":
            query["owner_id"] = ObjectId(request.user.id)
        for field in ("status", "priority"):
            value = request.query_params.get(field)
            allowed = {"open", "in_progress", "resolved", "closed"} if field == "status" else {"low", "normal", "high", "urgent"}
            if value:
                if value not in allowed:
                    raise ValidationError({field: "Invalid filter value."})
                query[field] = value
        for param, field, collection in (
            ("department_id", "department_id", "departments"),
            ("category_id", "category_id", "categories"),
            ("assigned_to", "assigned_to", "users"),
        ):
            if request.query_params.get(param):
                query[field] = require_reference(database, collection, request.query_params[param], param)
        search = request.query_params.get("q", "").strip()
        if search:
            safe = re.escape(search[:100])
            query["$or"] = [
                {"title": {"$regex": safe, "$options": "i"}},
                {"description": {"$regex": safe, "$options": "i"}},
                {"number": {"$regex": safe, "$options": "i"}},
            ]
        return paginate_mongo(database.tickets, request, query=query)

    def post(self, request):
        serializer = TicketCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        database = get_database()
        values = serializer.validated_data
        category_id = require_reference(database, "categories", values.get("category_id"), "category_id")
        department_id = require_reference(database, "departments", values.get("department_id"), "department_id")
        created = now()
        sequence = database.counters.find_one_and_update(
            {"_id": f"ticket:{created.year}"}, {"$inc": {"sequence": 1}},
            upsert=True, return_document=ReturnDocument.AFTER,
        )
        ticket = {
            "number": f"NX-{created.year}-{sequence['sequence']:06d}",
            "title": values["title"], "description": values["description"],
            "status": "open", "priority": values["priority"],
            "owner_id": ObjectId(request.user.id), "owner_name": request.user.name or request.user.email,
            "assigned_to": None, "category_id": category_id, "department_id": department_id,
            "created_at": created, "updated_at": created, "resolved_at": None,
            "closed_at": None, "version": 1,
        }
        inserted = database.tickets.insert_one(ticket)
        ticket["_id"] = inserted.inserted_id
        insert_audit(database, ticket, request.user, "ticket_created", {"status": "open"})
        return success(ticket, status.HTTP_201_CREATED)


class TicketDetailView(APIView):
    def get(self, request, ticket_id):
        ticket = get_ticket(get_database(), ticket_id)
        check_ticket_access(request.user, ticket)
        return success(ticket)

    def patch(self, request, ticket_id):
        database = get_database()
        ticket = get_ticket(database, ticket_id)
        check_ticket_access(request.user, ticket)
        serializer = TicketUpdateSerializer(data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        updates = serializer.validated_data.copy()
        privileged_fields = {"priority", "assigned_to", "status", "category_id", "department_id"}
        if request.user.role == "employee":
            if set(updates) - {"status"}:
                raise PermissionDenied("Employees may only close a resolved ticket.")
            if updates.get("status") != "closed" or ticket["status"] != "resolved":
                raise PermissionDenied("Employees may only close a resolved ticket.")
        elif request.user.role not in {"support", "admin"}:
            raise PermissionDenied()
        if request.user.role in {"support", "admin"} and set(updates) & privileged_fields:
            if "assigned_to" in updates:
                assignee = updates["assigned_to"]
                if assignee:
                    assignee_id = parse_object_id(assignee, "assigned_to")
                    assignee_doc = database.users.find_one({"_id": assignee_id, "role": {"$in": ["support", "admin"]}, "is_active": {"$ne": False}})
                    if not assignee_doc:
                        raise ValidationError({"assigned_to": "Assignee must be an active support user."})
                    updates["assigned_to"] = assignee_id
                else:
                    updates["assigned_to"] = None
            for field, collection in (("category_id", "categories"), ("department_id", "departments")):
                if field in updates:
                    updates[field] = require_reference(database, collection, updates[field], field)
            if "status" in updates:
                transitions = {
                    "open": {"in_progress", "resolved", "closed"},
                    "in_progress": {"open", "resolved", "closed"},
                    "resolved": {"in_progress", "closed"},
                    "closed": set(),
                }
                if updates["status"] not in transitions[ticket["status"]]:
                    raise ValidationError({"status": f"Cannot change status from {ticket['status']} to {updates['status']}."})
        elif request.user.role == "employee" and ticket["status"] != "resolved":
            raise PermissionDenied("Only resolved tickets can be closed by employees.")

        changed = {key: {"from": ticket.get(key), "to": value} for key, value in updates.items() if ticket.get(key) != value}
        if not changed:
            return success(ticket)
        updated_at = now()
        updates["updated_at"] = updated_at
        if updates.get("status") == "resolved":
            updates["resolved_at"] = updated_at
        if updates.get("status") == "closed":
            updates["closed_at"] = updated_at
        if ticket["status"] == "resolved" and updates.get("status") == "in_progress":
            updates["resolved_at"] = None
        result = database.tickets.find_one_and_update(
            {"_id": ticket["_id"], "version": ticket.get("version", 1)},
            {"$set": updates, "$inc": {"version": 1}}, return_document=ReturnDocument.AFTER,
        )
        if not result:
            raise APIException("Ticket changed concurrently; reload and retry.", code="write_conflict")
        insert_audit(database, result, request.user, "ticket_updated", changed)
        if "assigned_to" in updates and updates["assigned_to"]:
            notify(database, updates["assigned_to"], "ticket_assigned", f"Ticket {ticket['number']} was assigned to you.", result)
        if "status" in updates:
            notify(database, ticket["owner_id"], "ticket_status_changed", f"Ticket {ticket['number']} is now {updates['status']}.", result)
        return success(result)


class TicketCommentsView(APIView):
    def get(self, request, ticket_id):
        database = get_database()
        ticket = get_ticket(database, ticket_id)
        check_ticket_access(request.user, ticket)
        return paginate_mongo(database.ticket_comments, request, {"ticket_id": ticket["_id"]}, [("created_at", 1)])

    def post(self, request, ticket_id):
        database = get_database()
        ticket = get_ticket(database, ticket_id)
        check_ticket_access(request.user, ticket)
        serializer = CommentSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        comment = {
            "ticket_id": ticket["_id"], "author_id": ObjectId(request.user.id),
            "author_name": request.user.name or request.user.email,
            "author_role": request.user.role, "body": serializer.validated_data["body"], "created_at": now(),
        }
        inserted = database.ticket_comments.insert_one(comment)
        comment["_id"] = inserted.inserted_id
        insert_audit(database, ticket, request.user, "comment_added", {"comment_id": str(inserted.inserted_id)})
        recipient = ticket["owner_id"] if str(ticket["owner_id"]) != request.user.id else ticket.get("assigned_to")
        notify(database, recipient, "ticket_comment", f"A comment was added to ticket {ticket['number']}.", ticket)
        return success(comment, status.HTTP_201_CREATED)


class TicketAuditView(APIView):
    def get(self, request, ticket_id):
        database = get_database()
        ticket = get_ticket(database, ticket_id)
        check_ticket_access(request.user, ticket)
        return paginate_mongo(database.ticket_audit, request, {"ticket_id": ticket["_id"]}, [("created_at", 1)])


class NamedResourcesView(APIView):
    def get(self, request, resource):
        return paginate_mongo(get_database()[resource], request, {"is_active": {"$ne": False}}, [("name", 1)])

    def post(self, request, resource):
        self.permission_classes = [IsAdmin]
        self.check_permissions(request)
        serializer = NamedResourceSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        document = {**serializer.validated_data, "created_at": now(), "is_active": True}
        inserted = get_database()[resource].insert_one(document)
        document["_id"] = inserted.inserted_id
        return success(document, status.HTTP_201_CREATED)


class TicketAttachmentsView(APIView):
    parser_classes = [MultiPartParser, FormParser]

    def post(self, request, ticket_id):
        database = get_database()
        ticket = get_ticket(database, ticket_id)
        check_ticket_access(request.user, ticket)
        uploaded = request.FILES.get("file")
        if uploaded is None:
            raise ValidationError({"file": "Upload a file using the 'file' field."})
        serializer = AttachmentMetadataSerializer(data={
            "filename": uploaded.name, "content_type": uploaded.content_type or "", "size": uploaded.size,
        })
        serializer.is_valid(raise_exception=True)
        extension = Path(uploaded.name).suffix.lower()
        if extension not in {".pdf", ".jpg", ".jpeg", ".png", ".txt", ".zip", ".docx"}:
            raise ValidationError({"file": "File extension is not allowed."})
        prefix = uploaded.read(16)
        uploaded.seek(0)
        expected = {
            "application/pdf": prefix.startswith(b"%PDF-"),
            "image/jpeg": prefix.startswith(b"\xff\xd8\xff"),
            "image/png": prefix.startswith(b"\x89PNG\r\n\x1a\n"),
            "text/plain": b"\x00" not in prefix,
            "application/zip": prefix.startswith(b"PK\x03\x04"),
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document": prefix.startswith(b"PK\x03\x04"),
        }
        if not expected[serializer.validated_data["content_type"]]:
            raise ValidationError({"file": "File content does not match the declared content type."})
        storage_key = f"{ticket['_id']}/{uuid4().hex}{extension}"
        path = settings.PRIVATE_UPLOAD_ROOT / storage_key
        path.parent.mkdir(parents=True, exist_ok=True)
        try:
            with path.open("xb") as destination:
                for chunk in uploaded.chunks():
                    destination.write(chunk)
        except OSError as exc:
            raise APIException("Unable to store attachment.") from exc
        attachment = {
            "ticket_id": ticket["_id"], "uploaded_by": ObjectId(request.user.id),
            "filename": serializer.validated_data["filename"],
            "content_type": serializer.validated_data["content_type"],
            "size": serializer.validated_data["size"], "storage_key": storage_key, "created_at": now(),
        }
        inserted = database.attachments.insert_one(attachment)
        attachment["_id"] = inserted.inserted_id
        insert_audit(database, ticket, request.user, "attachment_added", {"attachment_id": str(inserted.inserted_id)})
        return success(attachment, status.HTTP_201_CREATED)

    def get(self, request, ticket_id):
        database = get_database()
        ticket = get_ticket(database, ticket_id)
        check_ticket_access(request.user, ticket)
        return paginate_mongo(database.attachments, request, {"ticket_id": ticket["_id"]}, [("created_at", DESCENDING)])


class NotificationsView(APIView):
    def get(self, request):
        database = get_database()
        query = {"user_id": ObjectId(request.user.id)}
        if request.query_params.get("unread", "").lower() in {"true", "1"}:
            query["read"] = False
        return paginate_mongo(database.notifications, request, query=query)


class NotificationDetailView(APIView):
    def patch(self, request, notification_id):
        if request.data.get("read") is not True:
            raise ValidationError({"read": "Only marking a notification as read is supported."})
        result = get_database().notifications.update_one(
            {"_id": parse_object_id(notification_id, "notification_id"), "user_id": ObjectId(request.user.id)},
            {"$set": {"read": True, "read_at": now()}},
        )
        if not result.matched_count:
            raise NotFound("Notification not found.")
        return success({"id": notification_id, "read": True})