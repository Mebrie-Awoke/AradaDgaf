from getpass import getpass

from django.contrib.auth.hashers import make_password
from django.core.management.base import BaseCommand, CommandError
from django.core.validators import validate_email
from django.utils import timezone
from pymongo.errors import DuplicateKeyError

from core.db import get_database


class Command(BaseCommand):
    help = (
        "Update the email and password of an existing administrator in MongoDB. "
        "The password is entered interactively and is never stored in source code."
    )

    def add_arguments(self, parser):
        parser.add_argument("current_email", help="Current administrator email address")
        parser.add_argument("new_email", help="New administrator email address")

    def handle(self, *args, **options):
        current_email = options["current_email"].strip().lower()
        new_email = options["new_email"].strip().lower()

        try:
            validate_email(current_email)
            validate_email(new_email)
        except Exception as exc:
            raise CommandError("Enter valid current and new email addresses.") from exc

        database = get_database()
        admin = database.users.find_one({"email": current_email, "role": "admin"})
        if not admin:
            raise CommandError(
                "No administrator was found with that current email address. "
                "No database records were changed."
            )

        duplicate = database.users.find_one({
            "email": new_email,
            "_id": {"$ne": admin["_id"]},
        })
        if duplicate:
            raise CommandError(
                "The new email address is already in use. No database records were changed."
            )

        password = getpass("New administrator password (minimum 12 characters): ")
        confirmation = getpass("Confirm new password: ")
        if len(password) < 12:
            raise CommandError(
                "Password must contain at least 12 characters. No changes were made."
            )
        if password != confirmation:
            raise CommandError("Passwords do not match. No changes were made.")

        try:
            result = database.users.update_one(
                {"_id": admin["_id"], "role": "admin"},
                {
                    "$set": {
                        "email": new_email,
                        "password": make_password(password),
                        "updated_at": timezone.now(),
                    }
                },
            )
        except DuplicateKeyError as exc:
            raise CommandError(
                "The new email address is already in use. No database records were changed."
            ) from exc

        if result.modified_count != 1:
            raise CommandError("The administrator record was not changed.")

        self.stdout.write(
            self.style.SUCCESS(
                f"Updated administrator credentials for {new_email}. "
                "The existing account ID, role, and other profile fields were preserved."
            )
        )
