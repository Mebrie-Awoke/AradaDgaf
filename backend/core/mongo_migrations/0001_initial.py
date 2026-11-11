from pymongo import ASCENDING, DESCENDING
from pymongo.errors import CollectionInvalid

version = 1
description = "Create core AradaDgaf collections, validators, and indexes."


def upgrade(database):
    validators = {
        "users": {"$jsonSchema": {"bsonType": "object", "required": ["email", "password", "role", "created_at"], "properties": {"email": {"bsonType": "string"}, "password": {"bsonType": "string"}, "role": {"enum": ["employee", "support", "admin"]}}}},
        "tickets": {"$jsonSchema": {"bsonType": "object", "required": ["number", "title", "description", "status", "priority", "owner_id", "created_at"], "properties": {"number": {"bsonType": "string"}, "status": {"enum": ["submitted", "assigned", "in_progress", "resolved", "closed", "open"]}, "priority": {"enum": ["low", "medium", "high", "critical", "normal", "urgent"]}}}},
        "ticket_comments": {"$jsonSchema": {"bsonType": "object", "required": ["ticket_id", "author_id", "body", "created_at"]}},
        "ticket_audit": {"$jsonSchema": {"bsonType": "object", "required": ["ticket_id", "actor_id", "action", "created_at"]}},
        "notifications": {"$jsonSchema": {"bsonType": "object", "required": ["user_id", "kind", "message", "created_at", "read"]}},
        "departments": {"$jsonSchema": {"bsonType": "object", "required": ["name", "created_at"]}},
        "categories": {"$jsonSchema": {"bsonType": "object", "required": ["name", "created_at"]}},
        "attachments": {"$jsonSchema": {"bsonType": "object", "required": ["ticket_id", "uploaded_by", "filename", "content_type", "size", "storage_key", "created_at"]}},
        "access_tokens": {"$jsonSchema": {"bsonType": "object", "required": ["token_hash", "user_id", "expires_at", "created_at"]}},
        "counters": {"$jsonSchema": {"bsonType": "object", "required": ["sequence"]}},
    }
    for name, validator in validators.items():
        if name not in database.list_collection_names():
            try:
                database.create_collection(name, validator=validator)
            except CollectionInvalid:
                pass
        else:
            database.command({"collMod": name, "validator": validator, "validationLevel": "moderate"})
    indexes = {
        "users": [([("email", ASCENDING)], {"unique": True})],
        "tickets": [
            ([("number", ASCENDING)], {"unique": True}),
            ([("owner_id", ASCENDING), ("created_at", DESCENDING)], {}),
            ([("status", ASCENDING), ("priority", ASCENDING), ("created_at", DESCENDING)], {}),
            ([("assigned_to", ASCENDING), ("status", ASCENDING)], {}),
            ([("department_id", ASCENDING), ("created_at", DESCENDING)], {}),
            ([("category_id", ASCENDING), ("created_at", DESCENDING)], {}),
        ],
        "ticket_comments": [([("ticket_id", ASCENDING), ("created_at", ASCENDING)], {})],
        "ticket_audit": [([("ticket_id", ASCENDING), ("created_at", ASCENDING)], {})],
        "notifications": [([("user_id", ASCENDING), ("created_at", DESCENDING)], {})],
        "departments": [([("name", ASCENDING)], {"unique": True})],
        "categories": [([("name", ASCENDING)], {"unique": True})],
        "attachments": [([("ticket_id", ASCENDING), ("created_at", DESCENDING)], {}), ([("storage_key", ASCENDING)], {"unique": True})],
        "access_tokens": [([("token_hash", ASCENDING)], {"unique": True}), ([("expires_at", ASCENDING)], {"expireAfterSeconds": 0})],
    }
    for collection, definitions in indexes.items():
        for keys, options in definitions:
            database[collection].create_index(keys, **options)
