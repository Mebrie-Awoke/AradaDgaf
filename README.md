# AradaDgaf    

**AradaDgaf** is an IT service management and support ticketing platform designed to help organizations receive, assign, track, and resolve employee IT support requests.

The project provides a Django REST API backed by MongoDB Atlas, with role-based access for employees, support technicians, and administrators. A Flutter mobile application is included in the repository. Its current interface uses a mock data repository; the backend includes a documented mobile API contract for a future integration phase.

---

## Table of Contents

- [Overview](#overview)
- [Core Features](#core-features)
- [Technology Stack](#technology-stack)
- [Repository Structure](#repository-structure)
- [Architecture](#architecture)
- [Getting Started](#getting-started)
- [Environment Configuration](#environment-configuration)
- [Running the Backend](#running-the-backend)
- [Initial Administrator Setup](#initial-administrator-setup)
- [API Reference](#api-reference)
- [Mobile API Integration Status](#mobile-api-integration-status)
- [Database Migrations](#database-migrations)
- [Security Considerations](#security-considerations)
- [Testing](#testing)
- [Project Status](#project-status)

## Overview

AradaDgaf centralizes IT support operations in one system. Employees can submit technical issues and follow their progress, while support staff can manage incoming requests, record work, and update ticket statuses. Administrators manage users and supporting configuration.

The backend exposes versioned REST endpoints and a separate compatibility API intended to match the data structures used by the Flutter application.

## Core Features

### Ticket Management
- Submit and track IT support requests.
- Assign tickets to support personnel.
- Manage ticket priorities and workflow statuses.
- Search, filter, and paginate ticket records.
- Maintain ticket timelines and audit history.

### User and Access Management
- Role-based access for employees, support staff, and administrators.
- Authenticated API access using bearer tokens.
- Administrator-managed support and administrator accounts.
- Employee access restricted to their own tickets.

### Support Operations
- Department and issue-category management.
- Public ticket comments and private support notes.
- Work records documenting troubleshooting and outcomes.
- Service ratings after ticket resolution.
- Notifications for relevant ticket events.

### Attachments and Reporting
- Private image attachments for supported ticket workflows.
- Dashboard summaries and administrative audit records.

## Technology Stack

| Layer | Technology |
|---|---|
| Backend framework | Django |
| API | Django REST Framework |
| Application database | MongoDB Atlas |
| MongoDB access | PyMongo |
| Django admin and session storage | SQLite |
| Mobile application | Flutter |
| API authentication | Bearer-token authentication |

## Repository Structure

```text
AradaDgaf/
├── AdministratorPage/       # React administrator portal
│   ├── src/
│   ├── package.json
│   └── README.md
├── backend/
│   ├── core/
│   │   ├── mongo_migrations/
│   │   ├── authentication.py
│   │   ├── mobile_compat.py
│   │   ├── serializers.py
│   │   ├── urls.py
│   │   └── views.py
│   ├── manage.py
│   ├── requirements.txt
│   └── MOBILE_API.md
└── arada_digaf_Mobile/
    └── Flutter application source
```

The backend and mobile application are maintained in separate directories. Backend API changes should not require changes to the mobile interface unless a frontend integration or feature update is intentionally being carried out.

## Architecture

The backend is responsible for authentication, authorization, ticket workflows, notifications, and persistence.

- **Django REST Framework** exposes the HTTP API.
- **MongoDB Atlas** stores application records such as users, tickets, categories, departments, and notifications.
- **SQLite** is used for Django's built-in administrative and session-related functionality, not as the primary application database.
- **Flutter** provides the mobile client interface. The current mobile source still uses an in-memory mock repository and is not yet connected to the live backend API.

## Getting Started

### Prerequisites

Install the following before setting up the project:

- Python 3.11 or later
- pip
- MongoDB Atlas account and database
- Git

### 1. Clone the repository

```powershell
git clone https://github.com/Mebrie-Awoke/AradaDgaf.git
cd AradaDgaf
```

### 2. Create and activate a virtual environment

On Windows PowerShell:

```powershell
py -3 -m venv .venv
.\.venv\Scripts\Activate.ps1
```

If PowerShell blocks script activation, use Command Prompt instead:

```cmd
.venv\Scripts\activate.bat
```

### 3. Install backend dependencies

```powershell
python -m pip install -r backend\requirements.txt
```

### 4. Configure environment variables

Create a local `.env` file from the project's environment template, if provided, and configure the required values. See [Environment Configuration](#environment-configuration).

Do not commit your local `.env` file or share credentials in source control.

## Environment Configuration

Configure the backend's environment variables before starting the application. At minimum, review the settings for:

- Django secret key
- Debug mode
- Allowed hosts
- MongoDB Atlas connection URI and database name
- CORS trusted origins / frontend origins
- Private attachment storage settings, where applicable

Use separate credentials for development and production. Store production secrets in the deployment platform's secret manager rather than in the repository.

## Running the Backend

Run these commands from the repository root after activating the virtual environment:

### Check the Django configuration

```powershell
python backend\manage.py check
```

### Run the backend tests

```powershell
python backend\manage.py test core --verbosity 2
```

### Start the development server

```powershell
python backend\manage.py runserver
```

The local API is available at:

```text
http://127.0.0.1:8000/
```

API base path:

```text
http://127.0.0.1:8000/api/
```

The Django development server is intended for local development only. Use a production-ready application server and HTTPS in deployed environments.

## Initial Administrator Setup

After configuring a reachable MongoDB database, create the initial administrator:

```powershell
python backend\manage.py create_initial_admin admin@example.com "AradaDgaf Administrator"
```

Follow the prompts to set the administrator password.

Public registration is intended for employee accounts. Support and administrator accounts should be provisioned through the administrative workflow.

## API Reference

All protected endpoints require a bearer token:

```http
Authorization: Bearer <access_token>
```

### Main API

The primary API is mounted under `/api/v1/`.

| Endpoint | Purpose |
|---|---|
| `/api/v1/auth/` | Registration, login, and logout |
| `/api/v1/users/` | User management |
| `/api/v1/tickets/` | Ticket operations, comments, history, and attachments |
| `/api/v1/departments/` | Department management |
| `/api/v1/categories/` | Ticket category management |
| `/api/v1/notifications/` | User notifications |
| `/api/v1/dashboard/` | Dashboard summaries |
| `/api/v1/admin/audit/` | Administrative audit records |
| `/api/health/` | Application health endpoint |

### Flutter Compatibility API

A separate compatibility API is available under `/api/mobile/`. It is designed to expose ticket, user, and notification fields expected by the current Flutter data models.

The mobile API includes:
- Authentication and logout.
- Ticket listing, creation, and details.
- Technician start-work and work-record actions.
- Ticket service ratings.
- Notification listing and read-status updates.

See **[backend/MOBILE_API.md](backend/MOBILE_API.md)** for endpoint details, payload examples, and response fields.

> **Integration note:** The compatibility API is a backend contract. The Flutter application currently uses `MockTicketRepository`; it has not yet been switched to HTTP requests against these endpoints.

## Database Migrations

MongoDB schema and index changes are managed through versioned migrations in `backend/core/mongo_migrations/`.

Migrations are designed to run automatically before database-backed requests. They create or update collections, validators, and indexes.

When changing the database schema:

1. Add a new forward-only migration.
2. Do not edit migrations that have already been applied to shared environments.
3. Test the migration against a development database before production use.
4. Confirm that the application can connect to MongoDB Atlas.

The automated test suite uses a mocked MongoDB connection in relevant tests. A successful Django check, test run, or health response does not by itself prove that the configured Atlas cluster is reachable.

## Security Considerations

Before deploying or using the system with real organizational data:

- Set `DEBUG=false` and use a strong, persistent Django secret key.
- Configure production allowed hosts and trusted frontend origins explicitly.
- Serve the application over HTTPS and enable appropriate secure-cookie and HSTS settings.
- Use a dedicated MongoDB application user with only the permissions required for the AradaDgaf database.
- Restrict MongoDB Atlas network access to trusted sources.
- Keep credentials, tokens, and environment files out of Git.
- Ensure uploaded attachments are stored privately and are only accessible to authorized users.
- Review role permissions and ticket ownership rules with the responsible IT administrator.
- Rotate any credentials that may have been exposed during development.

## Testing

Run the backend checks and tests with:

```powershell
python backend\manage.py check
python backend\manage.py test core --verbosity 2
```

Tests that use mocked database connections are useful for validating application behavior, but live integration testing is still required to verify MongoDB Atlas connectivity, migrations, and complete ticket workflows.

## Project Status

The repository currently contains:

- A Django REST backend with the primary `/api/v1/` endpoints.
- A Flutter-oriented compatibility API under `/api/mobile/`.
- Documentation for the mobile API contract.
- A Flutter mobile application that still uses mock in-memory data.

The next integration milestone is to verify the backend against a reachable development MongoDB Atlas database, then connect the Flutter data layer to the mobile API and test authentication and ticket workflows end to end.

---

## License

No license is specified in this repository at this time.
