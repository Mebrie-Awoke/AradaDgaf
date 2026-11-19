from django.core.management.base import BaseCommand, CommandError
from pymongo.errors import PyMongoError

from core.db import get_database


class Command(BaseCommand):
    help = "Connect to MongoDB Atlas and apply pending AradaDgaf schema migrations."

    def handle(self, *args, **options):
        try:
            database = get_database()
            database.command("ping")
        except (PyMongoError, RuntimeError) as exc:
            raise CommandError(
                "Could not connect to MongoDB or apply MongoDB migrations. "
                "Check MONGODB_URI, Atlas network access, and database permissions."
            ) from exc

        self.stdout.write(self.style.SUCCESS(
            f"MongoDB is reachable and migrations are up to date for '{database.name}'."
        ))
