import hashlib
import logging
import re
import secrets
from datetime import datetime, timedelta, timezone
from pathlib import Path
from uuid import uuid4

from bson import ObjectId
from django.conf import settings
from django.contrib.auth.hashers import check_password, make_password
from django.core.files.base import ContentFile
from django.core.files.storage import storages
from django.http import FileResponse
from pymongo import DESCENDING, ReturnDocument
from pymongo.errors import PyMongoError
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


logger = logging.getLogger(__name__)


class AttachmentStorageUnavailable(APIException):
    status_code = status.HTTP_503_SERVICE_UNAVAILABLE
    default_detail = "Attachment storage is temporarily unavailable."
    default_code = "storage_unavailable"


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


def private_attachment_storage():
    try:
        return storages["private_attachments"]
    except Exception as exc:
        logger.exception("Could not initialize private attachment storage")
        raise AttachmentStorageUnavailable() from exc


def public_attachment(document):
    result = json_safe(document)
    result.pop("storage_key", None)
    return result


def valid_attachment_content(content_type, data):
    if content_type == "image/jpeg":
        return data.startswith(b"\xff\xd8\xff") and data.endswith(b"\xff\xd9")
    if content_type == "image/png":
        return data.startswith(b"\x89PNG\r\n\x1a\n") and b"IEND" in data[-16:]
    return False


def validate_storage_key(storage_key, ticket_id):
    if not isinstance(storage_key, str):
        return False
    prefix = f"{ticket_id}/"
    if not storage_key.startswith(prefix):
        return False
    filename = storage_key[len(prefix):]
    return re.fullmatch(r"[0-9a-f]{32}\.(?:jpg|jpeg|png)", filename) is not None


def cleanup_failed_attachment(database, storage, storage_key):
    try:
        database.attachments.delete_one({"storage_key": storage_key})
    except PyMongoError:
        logger.exception("Could not roll back attachment metadata for storage key %s", storage_key)
    try:
        storage.delete(storage_key)
    except Exception:
        logger.exception("Could not remove failed attachment file with storage key %s", storage_key)


class HealthCheckView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def get(self, request):
        return Response({
            "success": True,
            "message": "AradaDgaf API is running successfully.",
            "service": "AradaDgaf Backend",
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
            allowed = {"submitted", "assigned", "in_progress", "resolved", "closed"} if field == "status" else {"low", "medium", "high", "critical"}
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
            "number": f"AF-{created.year}-{sequence['sequence']:05d}",
            "title": values["title"], "description": values["description"],
            "status": "submitted", "priority": values["priority"],
            "owner_id": ObjectId(request.user.id), "owner_name": request.user.name or request.user.email,
            "assigned_to": None, "category_id": category_id, "department_id": department_id,
            "created_at": created, "updated_at": created, "resolved_at": None,
            "closed_at": None, "version": 1,
        }
        inserted = database.tickets.insert_one(ticket)
        ticket["_id"] = inserted.inserted_id
        insert_audit(database, ticket, request.user, "ticket_created", {"status": "submitted"})
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
                    "submitted": {"assigned", "in_progress", "resolved"},
                    "assigned": {"in_progress", "resolved"},
                    "in_progress": {"assigned", "resolved"},
                    "resolved": {"in_progress", "closed"},
                    "closed": set(),
                }
                if updates["status"] not in transitions[ticket["status"]]:
                    raise ValidationError({"status": f"Cannot change status from {ticket['status']} to {updates['status']}."})
        elif request.user.role == "employee" and ticket["status"] != "resolved":
            raise PermissionDenied("Only resolved tickets can be closed by employees.")

        if updates.get("status") == "resolved":
            note = updates.get("resolution_note", ticket.get("resolution_note", ""))
            if not note or not note.strip():
                raise ValidationError({"resolution_note": "A resolution note is required before resolving a ticket."})
        if updates.get("assigned_to") and ticket.get("status") == "submitted" and "status" not in updates:
            updates["status"] = "assigned"
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
        query = {"ticket_id": ticket["_id"]}
        if request.user.role == "employee":
            query["internal_only"] = {"$ne": True}
        return paginate_mongo(database.ticket_comments, request, query, [("created_at", 1)])

    def post(self, request, ticket_id):
        database = get_database()
        ticket = get_ticket(database, ticket_id)
        check_ticket_access(request.user, ticket)
        serializer = CommentSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        internal_only = serializer.validated_data["internal_only"]
        if internal_only and request.user.role == "employee":
            raise PermissionDenied("Only support staff and administrators can add internal comments.")
        comment = {
            "ticket_id": ticket["_id"], "author_id": ObjectId(request.user.id),
            "author_name": request.user.name or request.user.email,
            "author_role": request.user.role, "body": serializer.validated_data["body"],
            "internal_only": internal_only, "created_at": now(),
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
        if request.user.role != "admin":
            raise PermissionDenied("Administrator access is required.")
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
        filename = uploaded.name
        if (
            not filename
            or len(filename) > 255
            or "/" in filename
            or "\\" in filename
            or filename in {".", ".."}
        ):
            raise ValidationError({"file": "Filename must be a simple filename without a path."})
        if uploaded.size > settings.MAX_ATTACHMENT_BYTES:
            raise ValidationError({"file": "File exceeds the maximum allowed size."})
        extension = Path(filename).suffix.lower()
        content_types = {
            ".jpg": "image/jpeg",
            ".jpeg": "image/jpeg",
            ".png": "image/png",
        }
        content_type = content_types.get(extension)
        reported_type = (uploaded.content_type or "").lower()
        if not content_type or (
            reported_type
            and reported_type != "application/octet-stream"
            and reported_type != content_type
        ):
            raise ValidationError({"file": "File extension does not match the declared content type."})
        data = uploaded.read()
        serializer = AttachmentMetadataSerializer(data={
            "filename": filename, "content_type": content_type, "size": len(data),
        })
        serializer.is_valid(raise_exception=True)
        if uploaded.size != len(data) or not valid_attachment_content(content_type, data):
            raise ValidationError({"file": "File content does not match the declared content type."})
        storage_key = f"{ticket['_id']}/{uuid4().hex}{extension}"
        storage = private_attachment_storage()
        try:
            saved_key = storage.save(storage_key, ContentFile(data))
        except Exception as exc:
            try:
                storage.delete(storage_key)
            except Exception:
                logger.exception("Could not remove a partially saved attachment")
            logger.exception("Could not save an attachment")
            raise AttachmentStorageUnavailable() from exc
        if saved_key != storage_key or not validate_storage_key(saved_key, ticket["_id"]):
            try:
                storage.delete(saved_key)
            except Exception:
                logger.exception("Could not remove attachment saved under an unexpected storage key")
            raise AttachmentStorageUnavailable("Storage returned an invalid attachment key.")
        attachment = {
            "ticket_id": ticket["_id"], "uploaded_by": ObjectId(request.user.id),
            "filename": serializer.validated_data["filename"],
            "content_type": serializer.validated_data["content_type"],
            "size": serializer.validated_data["size"], "storage_key": saved_key, "created_at": now(),
        }
        try:
            inserted = database.attachments.insert_one(attachment)
            attachment["_id"] = inserted.inserted_id
            insert_audit(database, ticket, request.user, "attachment_added", {"attachment_id": str(inserted.inserted_id)})
        except PyMongoError:
            cleanup_failed_attachment(database, storage, saved_key)
            raise
        return success(public_attachment(attachment), status.HTTP_201_CREATED)

    def get(self, request, ticket_id):
        database = get_database()
        ticket = get_ticket(database, ticket_id)
        check_ticket_access(request.user, ticket)
        return paginate_mongo(
            database.attachments, request, {"ticket_id": ticket["_id"]},
            [("created_at", DESCENDING)], transform=public_attachment,
        )


class TicketAttachmentDownloadView(APIView):
    def get(self, request, ticket_id, attachment_id):
        database = get_database()
        ticket = get_ticket(database, ticket_id)
        check_ticket_access(request.user, ticket)
        attachment = database.attachments.find_one({
            "_id": parse_object_id(attachment_id, "attachment_id"),
            "ticket_id": ticket["_id"],
        })
        if not attachment:
            raise NotFound("Attachment not found.")
        storage_key = attachment.get("storage_key")
        if not validate_storage_key(storage_key, ticket["_id"]):
            raise AttachmentStorageUnavailable("Attachment storage metadata is invalid.")
        storage = private_attachment_storage()
        try:
            uploaded_file = storage.open(storage_key, "rb")
        except FileNotFoundError as exc:
            raise NotFound("Attachment file not found.") from exc
        except Exception as exc:
            logger.exception("Could not open attachment storage key %s", storage_key)
            raise AttachmentStorageUnavailable() from exc
        response = FileResponse(
            uploaded_file,
            as_attachment=True,
            filename=attachment["filename"],
            content_type=attachment["content_type"],
        )
        response["Cache-Control"] = "private, no-store"
        return response


class DashboardView(APIView):
    def get(self, request):
        database = get_database()
        match = {}
        if request.user.role == "employee":
            match["owner_id"] = ObjectId(request.user.id)
        status_rows = list(database.tickets.aggregate([
            {"$match": match},
            {"$group": {"_id": "$status", "count": {"$sum": 1}}},
        ]))
        priority_rows = list(database.tickets.aggregate([
            {"$match": match},
            {"$group": {"_id": "$priority", "count": {"$sum": 1}}},
        ]))
        return success({
            "total_tickets": database.tickets.count_documents(match),
            "by_status": {row["_id"]: row["count"] for row in status_rows},
            "by_priority": {row["_id"]: row["count"] for row in priority_rows},
            "unread_notifications": database.notifications.count_documents({
                "user_id": ObjectId(request.user.id), "read": False,
            }),
        })


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