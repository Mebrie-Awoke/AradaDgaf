"""Compatibility API for the existing AradaDgaf Flutter application.

The mobile client currently uses an in-memory repository. These endpoints expose
its existing domain model without requiring any changes to the Flutter project.
They use the existing MongoDB collections and bearer-token authentication.
"""
import hashlib
import re
import secrets
from datetime import datetime, timedelta, timezone

from bson import ObjectId
from django.conf import settings
from django.contrib.auth.hashers import check_password
from pymongo import ReturnDocument
from rest_framework import serializers, status
from rest_framework.exceptions import AuthenticationFailed, NotFound, PermissionDenied, ValidationError
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from .db import get_database
from .utils import json_safe


CATEGORIES = {"maintenance", "antivirus", "software", "technical", "other"}
DEVICES = {"computer", "printer", "network", "copyMachine", "other"}
OUTCOMES = {"solutionGiven", "solutionNotGiven", "referredExternally"}
RATINGS = {"veryHigh", "high", "medium", "low"}


def utcnow():
    return datetime.now(timezone.utc)


def ok(data, http_status=status.HTTP_200_OK):
    return Response({"success": True, "data": json_safe(data)}, status=http_status)


def normalize_payload(data, aliases):
    """Accept Dart model camelCase keys and conventional API snake_case keys."""
    values = data.copy()
    for api_key, model_key in aliases.items():
        if api_key not in values and model_key in values:
            values[api_key] = values[model_key]
    return values


def enum_value(value, allowed, field, required=False):
    if value is None and not required:
        return None
    if value not in allowed:
        raise ValidationError({field: f"Choose one of: {', '.join(sorted(allowed))}."})
    return value


def find_ticket(database, ticket_number):
    ticket = database.tickets.find_one({"number": ticket_number})
    if not ticket:
        raise NotFound("Ticket not found.")
    return ticket


def ensure_ticket_access(user, ticket):
    if user.role == "employee" and str(ticket.get("owner_id")) != user.id:
        raise NotFound("Ticket not found.")
    if user.role not in {"employee", "support", "admin"}:
        raise PermissionDenied()


def mobile_status(ticket):
    explicit = ticket.get("mobile_status")
    if explicit in {"submitted", "inProgress", "resolved", "notResolved", "referred"}:
        return explicit
    return {
        "submitted": "submitted",
        "assigned": "inProgress",
        "in_progress": "inProgress",
        "resolved": "resolved",
        "closed": "resolved",
    }.get(ticket.get("status"), "submitted")


def timeline_for(ticket):
    events = ticket.get("timeline")
    if events:
        return json_safe(events)
    created = ticket.get("created_at") or utcnow()
    current = mobile_status(ticket)
    assigned_at = ticket.get("started_at") or ticket.get("updated_at") or created
    timeline = [{
        "titleKey": "request_submitted",
        "subtitle": "Request submitted",
        "timestamp": created,
        "isCompleted": True,
    }]
    in_progress = current in {"inProgress", "resolved", "notResolved", "referred"}
    timeline.append({
        "titleKey": "in_progress",
        "subtitle": (
            f"Assigned to {ticket.get('assigned_technician') or 'technician'}"
            if ticket.get("assigned_technician") else "(Waiting for technician)"
        ),
        "timestamp": assigned_at,
        "isCompleted": in_progress,
    })
    work = ticket.get("work_record")
    timeline.append({
        "titleKey": "outcome" if work else "outcome_pending",
        "subtitle": (
            f"{work.get('outcome', 'Work completed')}: {work.get('problem_description', '')}"
            if work else "Outcome pending"
        ),
        "timestamp": work.get("solution_date_time", assigned_at) if work else assigned_at,
        "isCompleted": bool(work),
    })
    return json_safe(timeline)


def mobile_ticket(ticket):
    work = ticket.get("work_record")
    rating = ticket.get("service_rating")
    return {
        "id": ticket.get("number", str(ticket.get("_id", ""))),
        "category": ticket.get("category", "other"),
        "deviceType": ticket.get("device_type"),
        "problemDescription": ticket.get("problem_description", ticket.get("description", "")),
        "department": ticket.get("department", ""),
        "officeLocation": ticket.get("office_location", ""),
        "phoneNumber": ticket.get("phone_number", ""),
        "createdAt": ticket.get("created_at"),
        "status": mobile_status(ticket),
        "requesterName": ticket.get("owner_name", ""),
        "assignedTechnician": ticket.get("assigned_technician"),
        "timeline": timeline_for(ticket),
        "workRecord": ({
            "deviceType": work.get("device_type", ""),
            "model": work.get("model"),
            "serialNumber": work.get("serial_number"),
            "problemDescription": work.get("problem_description", ""),
            "toolsMaterials": work.get("tools_materials"),
            "outcome": work.get("outcome", "solutionGiven"),
            "solutionDateTime": work.get("solution_date_time"),
        } if work else None),
        "rating": ({
            "quality": rating.get("quality"),
            "speed": rating.get("speed"),
            "ratedAt": rating.get("rated_at"),
        } if rating else None),
    }


def hydrated_mobile_ticket(database, ticket):
    """Fill Flutter display fields when a ticket was created through the v1 API."""
    document = dict(ticket)
    if not document.get("category") and document.get("category_id"):
        category = database.categories.find_one({"_id": document["category_id"]})
        raw_category = (category or {}).get("name", "").strip().lower().replace(" ", "_")
        document["category"] = raw_category if raw_category in CATEGORIES else "other"
    if not document.get("department") and document.get("department_id"):
        department = database.departments.find_one({"_id": document["department_id"]})
        document["department"] = (department or {}).get("name", "")
    if document.get("owner_id"):
        owner = database.users.find_one({"_id": document["owner_id"]})
        if owner:
            if not document.get("owner_name"):
                document["owner_name"] = owner.get("name", "")
            if not document.get("phone_number"):
                document["phone_number"] = owner.get("phone_number", "")
            if not document.get("office_location"):
                document["office_location"] = owner.get("office_location", "")
            if not document.get("department") and owner.get("department_id"):
                department = database.departments.find_one({"_id": owner["department_id"]})
                document["department"] = (department or {}).get("name", "")
    return mobile_ticket(document)


def append_timeline(ticket, title_key, subtitle, at, completed):
    events = list(ticket.get("timeline") or [])
    event = {
        "titleKey": title_key,
        "subtitle": subtitle,
        "timestamp": at,
        "isCompleted": completed,
    }
    if title_key == "in_progress":
        for index, existing in enumerate(events):
            if existing.get("titleKey") == "in_progress":
                events[index] = event
                return events
    events.append(event)
    return events


def mobile_notification(document):
    kind = document.get("kind", "ticket_status_changed")
    notification_type = {
        "ticket_created": "submitted",
        "ticket_assigned": "assigned",
        "ticket_started": "assigned",
        "ticket_resolved": "resolved",
        "rating_requested": "ratingRequest",
    }.get(kind, "resolved" if "resolved" in kind else "assigned")
    ticket_id = document.get("ticket_number") or str(document.get("ticket_id", ""))
    title = document.get("title") or f"Ticket {ticket_id} update"
    return {
        "id": str(document.get("_id", "")),
        "title": title,
        "message": document.get("message", ""),
        "ticketId": ticket_id,
        "timestamp": document.get("created_at"),
        "isRead": bool(document.get("read", False)),
        "type": notification_type,
    }


class MobileLoginSerializer(serializers.Serializer):
    username = serializers.CharField(max_length=254)
    password = serializers.CharField(max_length=128, trim_whitespace=False)
    role = serializers.ChoiceField(choices=["employee", "technician"], required=False)


class MobileTicketCreateSerializer(serializers.Serializer):
    category = serializers.ChoiceField(choices=sorted(CATEGORIES))
    device_type = serializers.ChoiceField(choices=sorted(DEVICES), required=False, allow_null=True)
    problem_description = serializers.CharField(max_length=500, trim_whitespace=True)
    department = serializers.CharField(max_length=120, trim_whitespace=True)
    office_location = serializers.CharField(max_length=200, trim_whitespace=True)
    phone_number = serializers.CharField(max_length=30, trim_whitespace=True)
    requester_name = serializers.CharField(max_length=120, required=False, allow_blank=True)
    created_at = serializers.DateTimeField(required=False)


class MobileWorkRecordSerializer(serializers.Serializer):
    device_type = serializers.CharField(max_length=80, trim_whitespace=True)
    model = serializers.CharField(max_length=120, required=False, allow_blank=True, allow_null=True)
    serial_number = serializers.CharField(max_length=120, required=False, allow_blank=True, allow_null=True)
    problem_description = serializers.CharField(max_length=1000, trim_whitespace=True)
    tools_materials = serializers.CharField(max_length=500, required=False, allow_blank=True, allow_null=True)
    outcome = serializers.ChoiceField(choices=sorted(OUTCOMES))
    solution_date_time = serializers.DateTimeField(required=False)


class MobileRatingSerializer(serializers.Serializer):
    quality = serializers.ChoiceField(choices=sorted(RATINGS))
    speed = serializers.ChoiceField(choices=sorted(RATINGS))
    rated_at = serializers.DateTimeField(required=False)


class MobileLoginView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        serializer = MobileLoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        values = serializer.validated_data
        identity = values["username"].strip()
        database = get_database()
        normalized = identity.lower()
        user_doc = database.users.find_one({
            "$or": [{"username": identity}, {"email": normalized}]
        })
        if not user_doc and "@" not in identity:
            matches = list(database.users.find({
                "email": {"$regex": "^" + re.escape(normalized) + "@"}
            }).limit(2))
            user_doc = matches[0] if len(matches) == 1 else None
        if (
            not user_doc
            or not user_doc.get("is_active", True)
            or not user_doc.get("password")
            or not check_password(values["password"], user_doc["password"])
        ):
            raise AuthenticationFailed("Invalid username or password.")
        if user_doc.get("role") not in {"employee", "support", "admin"}:
            raise AuthenticationFailed("This account does not have a mobile application role.")
        expected_role = "employee" if user_doc["role"] == "employee" else "technician"
        if (
            values.get("role") and values["role"] != expected_role
        ):
            raise AuthenticationFailed("This account does not have the selected role.")
        token = secrets.token_urlsafe(40)
        expires = utcnow() + timedelta(seconds=settings.ACCESS_TOKEN_TTL_SECONDS)
        database.access_tokens.insert_one({
            "token_hash": hashlib.sha256(token.encode("utf-8")).hexdigest(),
            "user_id": user_doc["_id"], "expires_at": expires, "created_at": utcnow(),
        })
        department = ""
        if user_doc.get("department_id"):
            doc = database.departments.find_one({"_id": user_doc["department_id"]})
            department = doc.get("name", "") if doc else ""
        user = {
            "username": user_doc.get("username") or user_doc["email"].split("@")[0],
            "fullName": user_doc.get("name", ""),
            "role": expected_role,
            "department": department,
            "officeLocation": user_doc.get("office_location", ""),
            "phoneNumber": user_doc.get("phone_number", ""),
        }
        return ok({
            "access_token": token, "token_type": "Bearer",
            "expires_at": expires, "user": user,
        })


class MobileLogoutView(APIView):
    def post(self, request):
        get_database().access_tokens.delete_one({"_id": request.auth["_id"]})
        return ok({"message": "Logged out."})


class MobileTicketListCreateView(APIView):
    def get(self, request):
        query = {}
        if request.user.role == "employee":
            query["owner_id"] = ObjectId(request.user.id)
        database = get_database()
        docs = list(database.tickets.find(query).sort("created_at", -1).limit(200))
        return ok([hydrated_mobile_ticket(database, doc) for doc in docs])

    def post(self, request):
        if request.user.role != "employee":
            raise PermissionDenied("Only employees can submit service requests.")
        serializer = MobileTicketCreateSerializer(data=normalize_payload(request.data, {
            "device_type": "deviceType",
            "problem_description": "problemDescription",
            "office_location": "officeLocation",
            "phone_number": "phoneNumber",
            "requester_name": "requesterName",
            "created_at": "createdAt",
        }))
        serializer.is_valid(raise_exception=True)
        values = serializer.validated_data
        database = get_database()
        created = values.get("created_at") or utcnow()
        counter = database.counters.find_one_and_update(
            {"_id": f"mobile_ticket:{created.year}"},
            {"$inc": {"sequence": 1}},
            upsert=True, return_document=ReturnDocument.AFTER,
        )
        number = f"AD-{created.year}-{counter['sequence']:04d}"
        ticket = {
            "number": number,
            "title": f"{values['category'].replace('_', ' ').title()} service request",
            "description": values["problem_description"],
            "category": values["category"],
            "device_type": values.get("device_type"),
            "problem_description": values["problem_description"],
            "department": values["department"],
            "office_location": values["office_location"],
            "phone_number": values["phone_number"],
            "status": "submitted",
            "mobile_status": "submitted",
            "priority": "medium",
            "owner_id": ObjectId(request.user.id),
            "owner_name": values.get("requester_name") or request.user.name or request.user.email,
            "assigned_to": None,
            "assigned_technician": None,
            "timeline": [{
                "titleKey": "request_submitted", "subtitle": "Request submitted",
                "timestamp": created, "isCompleted": True,
            }, {
                "titleKey": "in_progress", "subtitle": "(Waiting for technician)",
                "timestamp": created, "isCompleted": False,
            }, {
                "titleKey": "outcome_pending", "subtitle": "Outcome pending",
                "timestamp": created, "isCompleted": False,
            }],
            "created_at": created, "updated_at": utcnow(), "version": 1,
        }
        inserted = database.tickets.insert_one(ticket)
        ticket["_id"] = inserted.inserted_id
        database.ticket_audit.insert_one({
            "ticket_id": inserted.inserted_id, "ticket_number": number,
            "actor_id": ObjectId(request.user.id), "actor_name": request.user.name,
            "action": "ticket_created", "changes": {"mobile_status": "submitted"},
            "created_at": utcnow(),
        })
        database.notifications.insert_one({
            "user_id": ObjectId(request.user.id), "kind": "ticket_created",
            "title": f"Your request {number} has been submitted.",
            "message": "Your ticket is in the queue waiting for technician assignment.",
            "ticket_id": inserted.inserted_id, "ticket_number": number,
            "created_at": utcnow(), "read": False,
        })
        return ok(hydrated_mobile_ticket(database, ticket), status.HTTP_201_CREATED)


class MobileTicketDetailView(APIView):
    def get(self, request, ticket_number):
        database = get_database()
        ticket = find_ticket(database, ticket_number)
        ensure_ticket_access(request.user, ticket)
        return ok(hydrated_mobile_ticket(database, ticket))


class MobileStartWorkView(APIView):
    def post(self, request, ticket_number):
        if request.user.role not in {"support", "admin"}:
            raise PermissionDenied("Technician access is required.")
        database = get_database()
        ticket = find_ticket(database, ticket_number)
        at = utcnow()
        assigned_to = ticket.get("assigned_to")
        if mobile_status(ticket) not in {"submitted", "inProgress"}:
            raise ValidationError({"status": "This request cannot be started in its current state."})
        if assigned_to and str(assigned_to) != request.user.id and request.user.role != "admin":
            raise PermissionDenied("This request is assigned to another technician.")
        if ticket.get("status") == "in_progress" and assigned_to and str(assigned_to) == request.user.id:
            return ok(hydrated_mobile_ticket(database, ticket))
        technician = request.user.name or request.user.email
        updates = {
            "status": "in_progress", "mobile_status": "inProgress",
            "assigned_to": ObjectId(request.user.id), "assigned_technician": technician,
            "started_at": at, "updated_at": at,
            "timeline": append_timeline(ticket, "in_progress", f"Technician {technician} started work", at, True),
        }
        updated = database.tickets.find_one_and_update(
            {"_id": ticket["_id"], "version": ticket.get("version", 1)},
            {"$set": updates, "$inc": {"version": 1}},
            return_document=ReturnDocument.AFTER,
        )
        if not updated:
            raise ValidationError({"status": "This request was updated by another technician. Refresh and retry."})
        database.ticket_audit.insert_one({
            "ticket_id": ticket["_id"], "ticket_number": ticket_number,
            "actor_id": ObjectId(request.user.id), "actor_name": technician,
            "action": "work_started", "changes": {"status": "inProgress"}, "created_at": at,
        })
        database.notifications.insert_one({
            "user_id": ticket["owner_id"], "kind": "ticket_started",
            "title": f"Ticket {ticket_number} is in progress.",
            "message": f"Technician {technician} has started working on your request.",
            "ticket_id": ticket["_id"], "ticket_number": ticket_number,
            "created_at": at, "read": False,
        })
        return ok(hydrated_mobile_ticket(database, updated))


class MobileRecordWorkView(APIView):
    def post(self, request, ticket_number):
        if request.user.role not in {"support", "admin"}:
            raise PermissionDenied("Technician access is required.")
        serializer = MobileWorkRecordSerializer(data=normalize_payload(request.data, {
            "device_type": "deviceType",
            "serial_number": "serialNumber",
            "problem_description": "problemDescription",
            "tools_materials": "toolsMaterials",
            "solution_date_time": "solutionDateTime",
        }))
        serializer.is_valid(raise_exception=True)
        values = serializer.validated_data
        database = get_database()
        ticket = find_ticket(database, ticket_number)
        if ticket.get("status") not in {"in_progress", "assigned"}:
            raise ValidationError({"status": "Start work before recording the outcome."})
        assigned_to = ticket.get("assigned_to")
        if assigned_to and str(assigned_to) != request.user.id and request.user.role != "admin":
            raise PermissionDenied("This request is assigned to another technician.")
        at = values.get("solution_date_time") or utcnow()
        outcome = values["outcome"]
        mobile_state = {
            "solutionGiven": "resolved",
            "solutionNotGiven": "notResolved",
            "referredExternally": "referred",
        }[outcome]
        technician = request.user.name or request.user.email
        work = {
            "device_type": values["device_type"], "model": values.get("model"),
            "serial_number": values.get("serial_number"),
            "problem_description": values["problem_description"],
            "tools_materials": values.get("tools_materials"),
            "outcome": outcome, "solution_date_time": at,
            "recorded_by": ObjectId(request.user.id),
        }
        updates = {
            "work_record": work,
            "status": {
                "solutionGiven": "resolved",
                "solutionNotGiven": "closed",
                "referredExternally": "closed",
            }[outcome],
            "mobile_status": mobile_state,
            "resolution_note": values["problem_description"], "resolved_at": at,
            "updated_at": at,
            "timeline": append_timeline(
                ticket, "outcome",
                f"{outcome}: {values['problem_description']}", at, True,
            ),
        }
        updated = database.tickets.find_one_and_update(
            {"_id": ticket["_id"], "version": ticket.get("version", 1)},
            {"$set": updates, "$inc": {"version": 1}},
            return_document=ReturnDocument.AFTER,
        )
        if not updated:
            raise ValidationError({"status": "This request was updated by another technician. Refresh and retry."})
        database.ticket_audit.insert_one({
            "ticket_id": ticket["_id"], "ticket_number": ticket_number,
            "actor_id": ObjectId(request.user.id), "actor_name": technician,
            "action": "work_recorded", "changes": {"outcome": outcome}, "created_at": at,
        })
        database.notifications.insert_one({
            "user_id": ticket["owner_id"], "kind": "ticket_resolved",
            "title": f"Ticket {ticket_number}: {outcome}.",
            "message": f"Technician {technician} recorded the outcome. Please rate your service.",
            "ticket_id": ticket["_id"], "ticket_number": ticket_number,
            "created_at": at, "read": False,
        })
        return ok(hydrated_mobile_ticket(database, updated))


class MobileRateTicketView(APIView):
    def post(self, request, ticket_number):
        serializer = MobileRatingSerializer(data=normalize_payload(request.data, {
            "rated_at": "ratedAt",
        }))
        serializer.is_valid(raise_exception=True)
        values = serializer.validated_data
        database = get_database()
        ticket = find_ticket(database, ticket_number)
        ensure_ticket_access(request.user, ticket)
        if request.user.role != "employee" or str(ticket.get("owner_id")) != request.user.id:
            raise PermissionDenied("Only the employee who submitted this request can rate it.")
        if mobile_status(ticket) not in {"resolved", "notResolved", "referred"}:
            raise ValidationError({"status": "You can rate a request after work has been recorded."})
        at = values.get("rated_at") or utcnow()
        rating = {"quality": values["quality"], "speed": values["speed"], "rated_at": at}
        updated = database.tickets.find_one_and_update(
            {"_id": ticket["_id"]},
            {"$set": {"service_rating": rating, "updated_at": at}, "$inc": {"version": 1}},
            return_document=ReturnDocument.AFTER,
        )
        return ok(hydrated_mobile_ticket(database, updated))


class MobileNotificationsView(APIView):
    def get(self, request):
        query = {"user_id": ObjectId(request.user.id)}
        if request.query_params.get("unread", "").lower() in {"true", "1"}:
            query["read"] = False
        docs = list(get_database().notifications.find(query).sort("created_at", -1).limit(200))
        return ok([mobile_notification(doc) for doc in docs])


class MobileNotificationReadView(APIView):
    def patch(self, request, notification_id):
        database = get_database()
        try:
            object_id = ObjectId(notification_id)
        except Exception as exc:
            raise NotFound("Notification not found.") from exc
        result = database.notifications.update_one(
            {"_id": object_id, "user_id": ObjectId(request.user.id)},
            {"$set": {"read": True, "read_at": utcnow()}},
        )
        if not result.matched_count:
            raise NotFound("Notification not found.")
        return ok({"id": notification_id, "isRead": True})
