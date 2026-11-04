# Nexora IT Support Ticketing System 

## Backend    

The Django REST Framework API uses PyMongo for application data in MongoDB Atlas. Django's SQLite database is only used by Django's built-in admin/session framework; it does not store users, tickets, or other Nexora records. Mongo collections and indexes are initialized lazily when the first data request arrives. `/api/health/` does not require MongoDB and is suitable for a process liveness check.

### Requirements and local setup

- Python 3.11 or newer
- MongoDB Atlas cluster with a database user restricted to the Nexora database
- Network access from the deployment host to Atlas

From the repository root in PowerShell:

```powershell
py -3 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r backend\requirements.txt
Copy-Item .env.example .env
```

Edit `.env`: set `DJANGO_SECRET_KEY` to a unique random value, `DJANGO_DEBUG=true` for local development, and replace the Atlas URI and frontend origins. Keep `.env` private. Start the server:

```powershell
python backend\manage.py check
python backend\manage.py runserver
```

The API is available at `http://127.0.0.1:8000/api/`. Use `python backend\manage.py test core` to run the automated tests; database-dependent API tests mock PyMongo and do not require Atlas.

### Initial administrator

With a working MongoDB connection and `.env` configured, bootstrap the first admin interactively. The password is prompted (not passed on the command line) and stored using Django's password hashers:

```powershell
python backend\manage.py create_initial_admin admin@example.com "Nexora Administrator"
```

Public registration always creates an employee. Only an authenticated administrator can provision support/admin users through `POST /api/v1/users/`. Do not expose an initial-admin bootstrap endpoint publicly.

### API conventions

- JSON success: `{"success": true, "data": ...}`. Collection responses also include `meta` with count/page/page_size/pages.
- JSON errors: `{"success": false, "error": {"detail": ..., "code": ...}}`.
- Use `Authorization: Bearer <access_token>` for protected endpoints. Tokens are random opaque values; only SHA-256 digests are stored and logout revokes the active token.
- Page with `?page=1&page_size=25`; page size is capped at 100. Ticket filters include `status`, `priority`, `department_id`, `category_id`, `assigned_to`, and escaped text search `q`.
- Roles are `employee`, `support`, and `admin`. Employees see only their own tickets and can close resolved tickets. Support/admin can manage tickets; admin alone can manage users, departments, and categories.
- Ticket status values: `open`, `in_progress`, `resolved`, `closed`. Priority values: `low`, `normal`, `high`, `urgent`.

### Endpoints

| Method | Path | Access | Purpose |
| --- | --- | --- | --- |
| GET | `/api/health/` | Public | Liveness check |
| POST | `/api/v1/auth/register/` | Public, throttled | Register an employee |
| POST | `/api/v1/auth/login/` | Public, throttled | Obtain a bearer token |
| POST | `/api/v1/auth/logout/` | Authenticated | Revoke current token |
| GET, POST | `/api/v1/users/` | Admin | List users or provision an account |
| GET, POST | `/api/v1/departments/` | Authenticated / Admin | List or create departments |
| GET, POST | `/api/v1/categories/` | Authenticated / Admin | List or create issue categories |
| GET, POST | `/api/v1/tickets/` | Authenticated | List/filter tickets or create a ticket |
| GET, PATCH | `/api/v1/tickets/{id}/` | Owner, support, admin | Retrieve/update ticket, assign, prioritize, resolve, close |
| GET, POST | `/api/v1/tickets/{id}/comments/` | Owner, support, admin | List or add comments |
| GET | `/api/v1/tickets/{id}/audit/` | Owner, support, admin | Read immutable audit events |
| GET, POST | `/api/v1/tickets/{id}/attachments/` | Owner, support, admin | List/upload a validated attachment |
| GET | `/api/v1/tickets/{id}/attachments/{attachment_id}/download/` | Owner, support, admin | Download an attachment from an accessible ticket |
| GET | `/api/v1/notifications/` | Authenticated | List own notifications (`?unread=true`) |
| PATCH | `/api/v1/notifications/{id}/` | Notification owner | Mark as read |

Ticket update JSON fields are `title`, `description`, `priority`, `status`, `assigned_to`, `category_id`, and `department_id`. Account creation JSON fields are `email`, `name`, `password`, and optional `department_id`; the admin provisioning endpoint additionally accepts `role`. Passwords must be at least 12 characters and pass Django's configured validators.

### Examples

Register an employee:

```http
POST /api/v1/auth/register/
Content-Type: application/json

{"email":"alex@example.com","name":"Alex Rivera","password":"Correct-Horse-Battery-42!"}
```

Log in, then create a ticket using the returned token:

```http
POST /api/v1/auth/login/
Content-Type: application/json

{"email":"alex@example.com","password":"Correct-Horse-Battery-42!"}
```

```http
POST /api/v1/tickets/
Authorization: Bearer <access_token>
Content-Type: application/json

{"title":"VPN connection fails","description":"The office VPN disconnects after sign-in.","priority":"high"}
```

Support staff update a ticket with `PATCH /api/v1/tickets/{id}/` and for example `{"assigned_to":"<support-user-object-id>","status":"in_progress"}`. Uploads use multipart form field `file`; allowed types are PDF, JPEG, PNG, UTF-8 plain text, ZIP, and DOCX, limited by `MAX_ATTACHMENT_BYTES`. The API validates filenames, extensions, declared MIME types, and file content, then generates a random storage key. Clients never supply or receive storage keys. Attachment metadata is stored in MongoDB; file bytes use Django's private storage alias. The default backend is `django.core.files.storage.FileSystemStorage`, rooted at `PRIVATE_UPLOAD_ROOT`. Configure `PRIVATE_STORAGE_BACKEND` and `PRIVATE_STORAGE_OPTIONS` (a JSON object passed to the backend) to use another Django storage backend. For local storage, set `PRIVATE_UPLOAD_ROOT` to a private, durable volume that is not served as static or public media; container filesystems are otherwise ephemeral. The API does not expose the storage directory.

Download an attachment with `GET /api/v1/tickets/{ticket_id}/attachments/{attachment_id}/download/` and an authenticated bearer token. The requester must have access to the associated ticket (the ticket owner, support, or admin). Downloads are streamed as attachments and are never served from a public URL.

### MongoDB data and security

Collections include users, access tokens, tickets, ticket counters, departments, categories, comments, audit events, attachments, and notifications. Unique indexes protect email, ticket number, department name, and category name. Ticket numbers use an atomic yearly counter. Mongo JSON Schema validators enforce required fields and core enums; timestamp and query indexes are created on first connection. Audit events have no update/delete API. ObjectIds and datetimes are serialized to JSON strings.

Set `DJANGO_DEBUG=false` in production and provide `DJANGO_SECRET_KEY`, exact `DJANGO_ALLOWED_HOSTS`, and exact `CORS_ALLOWED_ORIGINS`. `SECURE_SSL_REDIRECT=true` and a positive `SECURE_HSTS_SECONDS` should be enabled only behind correctly configured HTTPS/proxy termination. Keep Atlas credentials in the deployment secret manager, use TLS and a least-privilege Atlas user, restrict Atlas network access, and ensure the private upload directory is durable, access-controlled, and backed up. Set request and attachment size limits for the actual proxy and application server too. Never serve `PRIVATE_UPLOAD_ROOT` as static/public media.

### Deployment checklist

1. Install `backend/requirements.txt` in a pinned/locked deployment environment and inject production variables from a secret manager.
2. Set `DJANGO_DEBUG=false`, secret key, hosts, CORS origins, Atlas URI/database, private storage backend/options, and HTTPS settings.
3. Ensure the deployment identity can reach Atlas and the private storage backend; when using local storage, mount a durable private volume at `PRIVATE_UPLOAD_ROOT`. Run the initial admin command once.
4. Run `python backend/manage.py check --deploy` and `python backend/manage.py test core` in CI. The deploy check may require appropriate HTTPS/HSTS settings.
5. Run behind an HTTPS-terminating reverse proxy using a production WSGI server (for example, Gunicorn) and configure the proxy forwarded-protocol header consistently with `SECURE_PROXY_SSL_HEADER`.
6. Monitor application/database errors, back up MongoDB and attachments, and plan index/validator changes as schema evolves.
