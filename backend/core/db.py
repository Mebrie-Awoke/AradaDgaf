from threading import Lock

from django.conf import settings
from pymongo import MongoClient
from pymongo.errors import PyMongoError

from .mongo_migrations.runner import apply_migrations

_client = None
_lock = Lock()


def get_database():
    global _client
    if not settings.MONGODB_URI:
        raise RuntimeError("MongoDB is not configured. Set MONGODB_URI.")
    if _client is None:
        with _lock:
            if _client is None:
                _client = MongoClient(
                    settings.MONGODB_URI,
                    serverSelectionTimeoutMS=settings.MONGODB_SERVER_SELECTION_TIMEOUT_MS,
                    connectTimeoutMS=settings.MONGODB_SERVER_SELECTION_TIMEOUT_MS,
                    retryWrites=True,
                    tls=True,
                    tz_aware=True,
                )
    database = _client[settings.MONGODB_DATABASE]
    _client.admin.command("ping")
    apply_migrations(database)
    return database


def close_database_connection():
    global _client
    with _lock:
        if _client is not None:
            _client.close()
            _client = None


def mongo_errors():
    return (PyMongoError,)
