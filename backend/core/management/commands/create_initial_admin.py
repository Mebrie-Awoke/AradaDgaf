from getpass import getpass

from django.contrib.auth.hashers import make_password
from django.core.management.base import BaseCommand, CommandError
from django.core.validators import validate_email
from django.utils import timezone
from pymongo.errors import DuplicateKeyError

from core.db import get_database


class Command(BaseCommand):
    help = "Create the initial Nexora administrator in MongoDB."

    def add_arguments(self, parser):
        parser.add_argument("email")
        parser.add_argument("name")

    def handle(self, *args, **options):
        email = options["email"].strip().lower()
        try:
            validate_email(email)
        except Exception as exc:
            raise CommandError("Enter a valid email address.") from exc
        password = getpass("Admin password (minimum 12 characters): ")
        confirmation = getpass("Confirm password: ")
        if password != confirmation or len(password) < 12:
            raise CommandError("Passwords must match and be at least 12 characters.")
        database = get_database()
        if database.users.find_one({"role": "admin"}):
            raise CommandError("An administrator already exists; use the protected admin provisioning API.")
        try:
            database.users.insert_one({
                "email": email,
                "name": options["name"].strip(),
                "password": make_password(password),
                "role": "admin",
                "department_id": None,
                "is_active": True,
                "created_at": timezone.now(),
                "updated_at": timezone.now(),
            })
        except DuplicateKeyError as exc:
            raise CommandError("That email address already exists.") from exc
        self.stdout.write(self.style.SUCCESS(f"Created initial administrator {email}."))