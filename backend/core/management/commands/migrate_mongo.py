import re

from django.core.management.base import BaseCommand, CommandError
from pymongo.errors import PyMongoError

from core.db import get_database


def safe_error_message(exc):
    """Return useful MongoDB diagnostics without exposing URI credentials."""
    message = str(exc)
    message = re.sub(
        r"(mongodb(?:\+srv)?://)([^/@\s]+)@",
        r"\1[REDACTED]@",
        message,
        flags=re.IGNORECASE,
    )
    return message[:1500]


class Command(BaseCommand):
    help = "Connect to MongoDB Atlas and apply pending AradaDgaf schema migrations."

    def handle(self, *args, **options):
        try:
            database = get_database()
            database.command("ping")
        except (PyMongoError, RuntimeError) as exc:
            self.stderr.write(
                self.style.ERROR(
                    f"MongoDB diagnostic ({type(exc).__name__}): "
                    f"{safe_error_message(exc)}"
                )
            )
            raise CommandError(
                "Could not connect to MongoDB or apply MongoDB migrations. "
                "See the MongoDB diagnostic above; verify MONGODB_URI, "
                "Atlas network access, and database permissions."
            ) from exc

        self.stdout.write(self.style.SUCCESS(
            f"MongoDB is reachable and migrations are up to date for '{database.name}'."
        ))
