from django.conf import settings
from django.core.files.storage import storages
from django.core.management.base import BaseCommand, CommandError
from pymongo import DeleteMany

from core.db import get_database


CONFIRMATION = "RESET-ARADADGAF-PRODUCTION"


class Command(BaseCommand):
    help = (
        "Reset AradaDgaf operational data while preserving administrator accounts, "
        "departments, categories, and administrator audit history."
    )

    def add_arguments(self, parser):
        parser.add_argument(
            "--confirm",
            type=str,
            default="",
            help=f"Required confirmation phrase: {CONFIRMATION}",
        )

    def handle(self, *args, **options):
        if options["confirm"] != CONFIRMATION:
            raise CommandError(
                "No data was changed. Re-run with "
                f"--confirm {CONFIRMATION} after reviewing the reset scope."
            )

        database = get_database()
        admin_users = list(database.users.find({"role": "admin"}, {"_id": 1}))
        admin_ids = [user["_id"] for user in admin_users]
        non_admin_users = list(database.users.find(
            {"role": {"$in": ["employee", "support"]}},
            {"_id": 1, "email": 1, "role": 1},
        ))
        removed_user_ids = [user["_id"] for user in non_admin_users]
        tickets = list(database.tickets.find({}, {"_id": 1}))
        ticket_ids = [ticket["_id"] for ticket in tickets]
        attachments = list(database.attachments.find({}, {"_id": 1, "storage_key": 1}))

        self.stdout.write("Reset preview:")
        self.stdout.write(f"  Tickets: {len(ticket_ids)}")
        self.stdout.write(f"  Employee and IT support accounts: {len(removed_user_ids)}")
        self.stdout.write(f"  Attachments: {len(attachments)}")
        self.stdout.write(f"  Administrator accounts to preserve: {len(admin_ids)}")
        self.stdout.write("  Departments, categories, and administrator audit history: preserved")

        # Remove physical files first. If any file cannot be removed, stop before
        # deleting its metadata or the related ticket records.
        storage = storages["private_attachments"]
        failed_files = []
        for attachment in attachments:
            key = attachment.get("storage_key")
            if not key:
                continue
            try:
                storage.delete(key)
            except Exception as exc:
                failed_files.append((key, str(exc)))

        if failed_files:
            details = "; ".join(f"{key}: {error}" for key, error in failed_files[:5])
            raise CommandError(
                f"Stopped without deleting MongoDB records because "
                f"{len(failed_files)} attachment file(s) could not be removed. {details}"
            )

        # Operational data associated with the old workspace.
        database.attachments.delete_many({})
        database.ticket_comments.delete_many({})
        database.ticket_audit.delete_many({})
        database.notifications.delete_many({})
        database.tickets.delete_many({})

        if removed_user_ids:
            database.access_tokens.delete_many({"user_id": {"$in": removed_user_ids}})
            database.users.delete_many({"_id": {"$in": removed_user_ids}})

        database.counters.delete_many({"_id": {"$regex": "^ticket:"}})

        # Confirm the administrator account(s) and reusable configuration remain.
        remaining_admins = database.users.count_documents({"role": "admin"})
        remaining_tickets = database.tickets.count_documents({})
        remaining_support = database.users.count_documents({"role": "support"})
        remaining_employees = database.users.count_documents({"role": "employee"})

        self.stdout.write(self.style.SUCCESS("Workspace operational data reset."))
        self.stdout.write(f"  Remaining administrators: {remaining_admins}")
        self.stdout.write(f"  Remaining tickets: {remaining_tickets}")
        self.stdout.write(f"  Remaining IT support accounts: {remaining_support}")
        self.stdout.write(f"  Remaining employee accounts: {remaining_employees}")
        self.stdout.write("  Departments and categories were not changed.")
