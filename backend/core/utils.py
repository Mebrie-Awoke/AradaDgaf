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
        "email": document["email"],
        "name": document.get("name", ""),
        "role": document["role"],
        "department_id": str(document["department_id"]) if document.get("department_id") else None,
        "created_at": document["created_at"].isoformat(),
    }