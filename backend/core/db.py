from threading import Lock

from django.conf import settings
from pymongo import ASCENDING, DESCENDING, MongoClient
from pymongo.errors import PyMongoError


_client = None
_initialized = False
_lock = Lock()


def get_database():
    global _client, _initialized
    if not settings.MONGODB_URI:
        raise RuntimeError("MongoDB is not configured. Set MONGODB_URI.")
    if _client is None:
        with _lock:
            if _client is None:
                _client = MongoClient(
                    settings.MONGODB_URI,
                    serverSelectionTimeoutMS=settings.MONGODB_SERVER_SELECTION_TIMEOUT_MS,
                    connectTimeoutMS=settings.MONGODB_SERVER_SELECTION_TIMEOUT_MS,
                    retryWrites=True,
                    tls=True,
                    tz_aware=True,
                )
    database = _client[settings.MONGODB_DATABASE]
    if not _initialized:
        with _lock:
            if not _initialized:
                _ensure_schema(database)
                _initialized = True
    return database


def close_database_connection():
    global _client, _initialized
    if _client is not None:
        _client.close()
    _client = None
    _initialized = False


def _ensure_schema(database):
    validators = {
        "users": {"$jsonSchema": {"bsonType": "object", "required": ["email", "password", "role", "created_at"], "properties": {"email": {"bsonType": "string"}, "password": {"bsonType": "string"}, "role": {"enum": ["employee", "support", "admin"]}}}},
        "tickets": {"$jsonSchema": {"bsonType": "object", "required": ["number", "title", "description", "status", "priority", "owner_id", "created_at"], "properties": {"number": {"bsonType": "string"}, "status": {"enum": ["open", "in_progress", "resolved", "closed"]}, "priority": {"enum": ["low", "normal", "high", "urgent"]}}}},
        "ticket_comments": {"$jsonSchema": {"bsonType": "object", "required": ["ticket_id", "author_id", "body", "created_at"]}},
        "ticket_audit": {"$jsonSchema": {"bsonType": "object", "required": ["ticket_id", "actor_id", "action", "created_at"]}},
        "notifications": {"$jsonSchema": {"bsonType": "object", "required": ["user_id", "kind", "message", "created_at", "read"]}},
        "departments": {"$jsonSchema": {"bsonType": "object", "required": ["name", "created_at"]}},
        "categories": {"$jsonSchema": {"bsonType": "object", "required": ["name", "created_at"]}},
        "attachments": {"$jsonSchema": {"bsonType": "object", "required": ["ticket_id", "uploaded_by", "filename", "content_type", "size", "storage_key", "created_at"], "properties": {"filename": {"bsonType": "string"}, "content_type": {"enum": ["application/pdf", "image/jpeg", "image/png", "text/plain", "application/zip", "application/vnd.openxmlformats-officedocument.wordprocessingml.document"]}, "size": {"bsonType": ["int", "long"], "minimum": 1}, "storage_key": {"bsonType": "string"}}}},
        "access_tokens": {"$jsonSchema": {"bsonType": "object", "required": ["token_hash", "user_id", "expires_at", "created_at"]}},
    }
    for collection, validator in validators.items():
        if collection not in database.list_collection_names():
            database.create_collection(collection, validator=validator)
        else:
            database.command({"collMod": collection, "validator": validator, "validationLevel": "strict"})

    indexes = {
        "users": [([("email", ASCENDING)], {"unique": True})],
        "tickets": [([("number", ASCENDING)], {"unique": True}), ([("owner_id", ASCENDING), ("created_at", DESCENDING)], {}), ([("status", ASCENDING), ("priority", ASCENDING)], {})],
        "ticket_comments": [([("ticket_id", ASCENDING), ("created_at", ASCENDING)], {})],
        "ticket_audit": [([("ticket_id", ASCENDING), ("created_at", ASCENDING)], {})],
        "notifications": [([("user_id", ASCENDING), ("created_at", DESCENDING)], {})],
        "departments": [([("name", ASCENDING)], {"unique": True})],
        "categories": [([("name", ASCENDING)], {"unique": True})],
        "attachments": [([("ticket_id", ASCENDING), ("created_at", DESCENDING)], {}), ([("storage_key", ASCENDING)], {"unique": True})],
        "access_tokens": [([("token_hash", ASCENDING)], {"unique": True}), ([ ("expires_at", ASCENDING)], {"expireAfterSeconds": 0})],
    }
    for collection, definitions in indexes.items():
        for keys, options in definitions:
            database[collection].create_index(keys, **options)


def mongo_errors():
    return (PyMongoError,)