from pymongo import ASCENDING

version = 4
description = "Add unique optional usernames for mobile application sign-in."


def upgrade(database):
    # Sparse keeps legacy user documents without a username out of this index.
    database.users.create_index(
        [("username", ASCENDING)],
        unique=True,
        sparse=True,
        name="uniq_users_username",
    )
