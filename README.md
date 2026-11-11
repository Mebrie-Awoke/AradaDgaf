# AradaDgaf 

**AradaDgaf** is an IT support ticketing system for managing employee IT requests, assignments, and support activities.

## Technology

- Django REST Framework — REST API
- MongoDB Atlas with PyMongo — application data
- SQLite — Django admin and session framework only

## Features

- Role-based access: employee, support, and admin
- User registration and administrator-managed accounts
- Ticket submission, assignment, priorities, and status tracking
- Departments and categories
- Public comments and private support notes
- Notifications, dashboards, and audit history
- Private image attachments
- Search, filtering, and pagination

## Setup

Requirements: Python 3.11+ and a MongoDB Atlas database.

From the repository root, run in PowerShell:

```powershell
py -3 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r backend\requirements.txt
Copy-Item .env.example .env
```

Edit `.env` and configure your Django secret key, MongoDB connection string, allowed hosts, and frontend origins. Keep `.env` private; do not commit it.

## Run locally

```powershell
python backend\manage.py check
python backend\manage.py test core
python backend\manage.py runserver
```

API base URL: `http://127.0.0.1:8000/api/`

## Create the first administrator

After configuring MongoDB:

```powershell
python backend\manage.py create_initial_admin admin@example.com "AradaDgaf Administrator"
```

You will be prompted to set the administrator password. Public registration creates employee accounts; administrators manage support and admin accounts.

## API overview

All protected endpoints require a bearer token:

`Authorization: Bearer <access_token>`

| Endpoint | Purpose |
|---|---|
| `/api/v1/auth/` | Registration, login, and logout |
| `/api/v1/users/` | User management |
| `/api/v1/tickets/` | Tickets, comments, history, and attachments |
| `/api/v1/departments/` | Department management |
| `/api/v1/categories/` | Category management |
| `/api/v1/notifications/` | User notifications |
| `/api/v1/dashboard/` | Ticket summary |
| `/api/v1/admin/audit/` | Administrative audit records |
| `/api/health/` | Application liveness check |

## Database migrations

Versioned MongoDB migrations run automatically before database-backed requests. They create and update collections, validators, and indexes. Add new changes as forward-only migrations; do not modify migrations that have already been applied.

The automated tests use a mocked MongoDB connection. A passing test or health check does not confirm that your Atlas database is reachable.

## Notes

- Tickets use the statuses `submitted`, `assigned`, `in_progress`, `resolved`, and `closed`.
- Priorities are `low`, `medium`, `high`, and `critical`.
- A resolution note is required to resolve a ticket.
- Attachments are limited to JPEG and PNG images and must be stored privately.
- Confirm ticket workflow, priority permissions, employee closure/reopening, attachment rules, and internal-note visibility with the IT supervisor before production use.

## Security

Use a least-privilege MongoDB user, restrict Atlas network access, enable HTTPS, and set `DJANGO_DEBUG=false` with production secrets and allowed hosts before deployment. Never commit credentials or expose private attachment storage.
