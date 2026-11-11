version = 2
description = "Normalize legacy ticket statuses and priorities; add resolution/comment defaults."


def upgrade(database):
    tickets = database.tickets
    tickets.update_many(
        {"status": "open", "assigned_to": {"$ne": None}},
        {"$set": {"status": "assigned"}},
    )
    tickets.update_many({"status": "open"}, {"$set": {"status": "submitted"}})
    tickets.update_many({"priority": "normal"}, {"$set": {"priority": "medium"}})
    tickets.update_many({"priority": "urgent"}, {"$set": {"priority": "critical"}})
    tickets.update_many(
        {"resolution_note": {"$exists": False}},
        {"$set": {"resolution_note": ""}},
    )
    tickets.update_many(
        {"version": {"$exists": False}},
        {"$set": {"version": 1}},
    )
    database.ticket_comments.update_many(
        {"internal_only": {"$exists": False}},
        {"$set": {"internal_only": False}},
    )
    database.command({"collMod": "tickets", "validator": {"$jsonSchema": {
        "bsonType": "object",
        "required": ["number", "title", "description", "status", "priority", "owner_id", "created_at"],
        "properties": {
            "number": {"bsonType": "string"},
            "status": {"enum": ["submitted", "assigned", "in_progress", "resolved", "closed"]},
            "priority": {"enum": ["low", "medium", "high", "critical"]},
            "resolution_note": {"bsonType": "string"},
        },
    }}, "validationLevel": "strict"})
    database.command({"collMod": "attachments", "validator": {"$jsonSchema": {
        "bsonType": "object",
        "required": ["ticket_id", "uploaded_by", "filename", "content_type", "size", "storage_key", "created_at"],
        "properties": {
            "content_type": {"enum": ["image/jpeg", "image/png"]},
            "size": {"bsonType": ["int", "long"], "minimum": 1},
            "storage_key": {"bsonType": "string"},
        },
    }}, "validationLevel": "strict"})
