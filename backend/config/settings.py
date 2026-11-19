
"""
Django settings for config project.

Production-ready configuration for Arada Digaf.
"""

import json
import os
import secrets
from pathlib import Path

from dotenv import load_dotenv


# ============================================================
# BASE CONFIGURATION
# ============================================================

BASE_DIR = Path(__file__).resolve().parent.parent

load_dotenv(BASE_DIR / ".env")
load_dotenv(BASE_DIR.parent / ".env")


# ============================================================
# SECURITY SETTINGS
# ============================================================

DEBUG = os.getenv("DJANGO_DEBUG", "false").lower() == "true"

SECRET_KEY = os.getenv("DJANGO_SECRET_KEY") or secrets.token_urlsafe(48)

ALLOWED_HOSTS = [
    host.strip()
    for host in os.getenv(
        "DJANGO_ALLOWED_HOSTS",
        "localhost,127.0.0.1,10.0.2.2,testserver",
    ).split(",")
    if host.strip()
]

if DEBUG and "*" not in ALLOWED_HOSTS:
    ALLOWED_HOSTS.append("*")


# ============================================================
# APPLICATION DEFINITION
# ============================================================

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",

    "rest_framework",
    "corsheaders",
    "core",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "corsheaders.middleware.CorsMiddleware",
    "core.middleware.RequestSizeLimitMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "config.wsgi.application"


# ============================================================
# DATABASE
# ============================================================

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.sqlite3",
        "NAME": BASE_DIR / "db.sqlite3",
    }
}

# Django uses SQLite for its own admin/session framework.
# Application records are stored in MongoDB through PyMongo.


# ============================================================
# PASSWORD VALIDATION
# ============================================================

AUTH_PASSWORD_VALIDATORS = [
    {
        "NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.MinimumLengthValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.CommonPasswordValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.NumericPasswordValidator",
    },
]


# ============================================================
# INTERNATIONALIZATION
# ============================================================

LANGUAGE_CODE = "en-us"

TIME_ZONE = "UTC"

USE_I18N = True

USE_TZ = True


# ============================================================
# STATIC FILES
# ============================================================

STATIC_URL = "static/"

# Required by collectstatic on Render.
STATIC_ROOT = BASE_DIR / "staticfiles"

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"


# ============================================================
# CORS CONFIGURATION
# ============================================================

CORS_ALLOWED_ORIGINS = [
    origin.strip()
    for origin in os.getenv(
        "CORS_ALLOWED_ORIGINS",
        "http://localhost:5173,"
        "http://127.0.0.1:5173,"
        "http://localhost:3000,"
        "http://127.0.0.1:3000",
    ).split(",")
    if origin.strip()
]

if DEBUG:
    CORS_ALLOW_ALL_ORIGINS = True

CORS_ALLOW_CREDENTIALS = False


# ============================================================
# REQUEST AND FILE UPLOAD LIMITS
# ============================================================

DATA_UPLOAD_MAX_MEMORY_SIZE = int(
    os.getenv("MAX_REQUEST_BYTES", str(10 * 1024 * 1024))
)

FILE_UPLOAD_MAX_MEMORY_SIZE = int(
    os.getenv("FILE_UPLOAD_MEMORY_BYTES", str(2 * 1024 * 1024))
)

MAX_ATTACHMENT_BYTES = int(
    os.getenv("MAX_ATTACHMENT_BYTES", str(5 * 1024 * 1024))
)


# ============================================================
# SECURITY HEADERS AND HTTPS
# ============================================================

SECURE_CONTENT_TYPE_NOSNIFF = True

SESSION_COOKIE_SECURE = not DEBUG

CSRF_COOKIE_SECURE = not DEBUG

SECURE_SSL_REDIRECT = (
    os.getenv("SECURE_SSL_REDIRECT", "false").lower() == "true"
)

SECURE_HSTS_SECONDS = int(
    os.getenv("SECURE_HSTS_SECONDS", "0")
)

SECURE_HSTS_INCLUDE_SUBDOMAINS = SECURE_HSTS_SECONDS > 0

SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")


# ============================================================
# DJANGO REST FRAMEWORK
# ============================================================

REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": [
        "core.authentication.BearerTokenAuthentication"
    ],

    "DEFAULT_PERMISSION_CLASSES": [
        "rest_framework.permissions.IsAuthenticated"
    ],

    "DEFAULT_PAGINATION_CLASS": "core.pagination.ApiPagination",

    "PAGE_SIZE": 25,

    "EXCEPTION_HANDLER": "core.exceptions.api_exception_handler",

    "DEFAULT_RENDERER_CLASSES": [
        "rest_framework.renderers.JSONRenderer"
    ],

    "DEFAULT_PARSER_CLASSES": [
        "rest_framework.parsers.JSONParser",
        "rest_framework.parsers.FormParser",
        "rest_framework.parsers.MultiPartParser",
    ],
}


# ============================================================
# MONGODB CONFIGURATION
# ============================================================

MONGODB_URI = os.getenv("MONGODB_URI", "")

MONGODB_DATABASE = os.getenv("MONGODB_DATABASE", "AradaDgaf")

MONGODB_SERVER_SELECTION_TIMEOUT_MS = int(
    os.getenv("MONGODB_TIMEOUT_MS", "10000")
)


# ============================================================
# AUTHENTICATION TOKEN CONFIGURATION
# ============================================================

ACCESS_TOKEN_TTL_SECONDS = int(
    os.getenv("ACCESS_TOKEN_TTL_SECONDS", "43200")
)


# ============================================================
# PRIVATE FILE STORAGE
# ============================================================

PRIVATE_UPLOAD_ROOT = Path(
    os.getenv(
        "PRIVATE_UPLOAD_ROOT",
        str(BASE_DIR.parent / "private_uploads"),
    )
)

if not PRIVATE_UPLOAD_ROOT.is_absolute():
    PRIVATE_UPLOAD_ROOT = BASE_DIR.parent / PRIVATE_UPLOAD_ROOT

PRIVATE_UPLOAD_ROOT = PRIVATE_UPLOAD_ROOT.resolve()

PRIVATE_STORAGE_BACKEND = os.getenv(
    "PRIVATE_STORAGE_BACKEND",
    "django.core.files.storage.FileSystemStorage",
).strip()

try:
    PRIVATE_STORAGE_OPTIONS = json.loads(
        os.getenv("PRIVATE_STORAGE_OPTIONS", "{}")
    )
except json.JSONDecodeError as exc:
    raise RuntimeError(
        "PRIVATE_STORAGE_OPTIONS must be a JSON object."
    ) from exc

if not isinstance(PRIVATE_STORAGE_OPTIONS, dict):
    raise RuntimeError(
        "PRIVATE_STORAGE_OPTIONS must be a JSON object."
    )

if PRIVATE_STORAGE_BACKEND == "django.core.files.storage.FileSystemStorage":
    PRIVATE_STORAGE_OPTIONS.setdefault(
        "location",
        str(PRIVATE_UPLOAD_ROOT),
    )

STORAGES = {
    "default": {
        "BACKEND": "django.core.files.storage.FileSystemStorage",
    },

    "staticfiles": {
        "BACKEND": "django.contrib.staticfiles.storage.StaticFilesStorage",
    },

    "private_attachments": {
        "BACKEND": PRIVATE_STORAGE_BACKEND,
        "OPTIONS": PRIVATE_STORAGE_OPTIONS,
    },
}


# ============================================================
# API THROTTLING
# ============================================================

REST_FRAMEWORK["DEFAULT_THROTTLE_CLASSES"] = [
    "rest_framework.throttling.AnonRateThrottle",
    "rest_framework.throttling.UserRateThrottle",
]

REST_FRAMEWORK["DEFAULT_THROTTLE_RATES"] = {
    "anon": "30/hour",
    "user": "1200/hour",
}


# ============================================================
# PRODUCTION ENVIRONMENT VALIDATION
# ============================================================

if (
    os.getenv("DJANGO_ENV", "development").lower() == "production"
    and not os.getenv("DJANGO_SECRET_KEY")
):
    raise RuntimeError(
        "DJANGO_SECRET_KEY must be configured when DJANGO_DEBUG is false."
    )


# ============================================================
# EMAIL CONFIGURATION
# ============================================================

MAILERS = {
    "default": {
        "BACKEND": "django.core.mail.backends.console.EmailBackend",
    },
}
