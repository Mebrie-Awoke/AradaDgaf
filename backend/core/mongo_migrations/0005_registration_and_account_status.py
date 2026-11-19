from pymongo import ASCENDING

version = 5
description = "Add indexes and status defaults for employee and technician registration/approval."


def upgrade(database):
    # Set default status for existing user documents
    database.users.update_many(
        {"status": {"$exists": False}, "is_active": {"$ne": False}},
        {"$set": {"status": "active"}},
    )
    database.users.update_many(
        {"status": {"$exists": False}, "is_active": False},
        {"$set": {"status": "suspended"}},
    )

    # Sparse indexes for employee ID and registration reference
    database.users.create_index(
        [("employee_id", ASCENDING)],
        unique=True,
        sparse=True,
        name="uniq_users_employee_id",
    )
    database.users.create_index(
        [("registration_reference", ASCENDING)],
        unique=True,
        sparse=True,
        name="uniq_users_registration_reference",
    )
    database.users.create_index(
        [("status", ASCENDING), ("role", ASCENDING)],
        name="idx_users_status_role",
    )
