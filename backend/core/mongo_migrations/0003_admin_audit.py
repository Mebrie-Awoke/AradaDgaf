from pymongo import ASCENDING, DESCENDING
from pymongo.errors import CollectionInvalid

version = 3
description = "Add immutable audit history for privileged administration actions."


def upgrade(database):
    validator = {"$jsonSchema": {
        "bsonType": "object",
        "required": ["actor_id", "action", "created_at"],
        "properties": {
            "actor_id": {"bsonType": "objectId"},
            "actor_email": {"bsonType": "string"},
            "action": {"bsonType": "string"},
            "created_at": {"bsonType": "date"},
        },
    }}
    if "admin_audit" not in database.list_collection_names():
        try:
            database.create_collection("admin_audit", validator=validator)
        except CollectionInvalid:
            pass
    else:
        database.command({
            "collMod": "admin_audit",
            "validator": validator,
            "validationLevel": "moderate",
        })
    database.admin_audit.create_index([("created_at", DESCENDING)])
    database.admin_audit.create_index([("actor_id", ASCENDING), ("created_at", DESCENDING)])
