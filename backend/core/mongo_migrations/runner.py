from importlib import import_module

MIGRATIONS = (
    "core.mongo_migrations.0001_initial",
    "core.mongo_migrations.0002_ticket_workflow",
    "core.mongo_migrations.0003_admin_audit",
)


def apply_migrations(database):
    if "schema_migrations" not in database.list_collection_names():
        database.create_collection("schema_migrations")
        database.schema_migrations.create_index("version", unique=True)
    applied = {
        item["version"]
        for item in database.schema_migrations.find({}, {"version": 1})
    }
    for module_path in MIGRATIONS:
        migration = import_module(module_path)
        if migration.version not in applied:
            migration.upgrade(database)
            database.schema_migrations.insert_one({
                "version": migration.version,
                "description": migration.description,
            })
