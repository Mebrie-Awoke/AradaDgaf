from datetime import datetime

from bson import ObjectId


def json_safe(value):
    if isinstance(value, ObjectId):
        return str(value)
    if isinstance(value, datetime):
        return value.isoformat()
    if isinstance(value, dict):
        return {
            ("id" if key == "_id" else key): json_safe(item)
            for key, item in value.items()
            if key not in {"password", "token_hash"}
        }
    if isinstance(value, (list, tuple)):
        return [json_safe(item) for item in value]
    return value


def public_user(document):
    return {
        "id": str(document["_id"]),
        "email": document.get("email", ""),
        "name": document.get("name", ""),
        "username": document.get("username") or (document.get("email", "").split("@")[0] if "@" in document.get("email", "") else ""),
        "phone_number": document.get("phone_number", ""),
        "office_location": document.get("office_location", ""),
        "work_unit": document.get("work_unit", ""),
        "employee_id": document.get("employee_id", ""),
        "role": document.get("role", "employee"),
        "status": document.get("status", "active" if document.get("is_active", True) else "suspended"),
        "is_active": document.get("is_active", True),
        "department_id": str(document["department_id"]) if document.get("department_id") else None,
        "specialties": document.get("specialties", []),
        "qualification_note": document.get("qualification_note", ""),
        "registration_reference": document.get("registration_reference", ""),
        "rejection_reason": document.get("rejection_reason", ""),
        "created_at": document["created_at"].isoformat() if isinstance(document.get("created_at"), datetime) else str(document.get("created_at", "")),
    }