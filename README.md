# AradaDgaf    

**AradaDgaf** is an IT service management and support ticketing platform designed to help organizations receive, assign, track, and resolve employee IT support requests.

The project provides a Django REST API backed by MongoDB Atlas, with role-based access for employees, support technicians, and administrators. It includes a Flutter mobile client and a React administrator portal. Both clients use the shared backend API.

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

The backend exposes versioned REST endpoints and a mobile compatibility API matching the Flutter application's data models.

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
- **Flutter** provides the mobile client interface and communicates with the `/api/mobile/` endpoints using HTTPS in deployed environments. The app stores its bearer token with platform secure storage.

## Getting Started

### Prerequisites

Install the following before setting up the project:

- Python 3.11 or later
- Node.js 18+ and npm
- Flutter SDK (3.24+ recommended, tested with Flutter 3.44.8 / Dart 3.12.2)
- Android SDK (for mobile builds/emulation)
- MongoDB Atlas account or cluster (URI configured in `.env`)
- Git

---

### 1. Backend Setup & Run

From the repository root:

```powershell
# Create and activate virtual environment
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1

# Install dependencies
pip install -r requirements.txt

# Configure environment variables (copy from .env.example)
copy .env.example .env
# Edit .env to set MONGODB_URI and MONGODB_DATABASE=AradaDgaf

# Run Django system checks & tests
python manage.py check
python manage.py test core --verbosity 2

# Seed the development database (DEV ONLY)
python manage.py dev_seed --force

# Start the development backend server
python manage.py runserver 0.0.0.0:8000
```

The backend API will be available at:
- Base API: `http://127.0.0.1:8000/api/`
- Mobile Compatibility API: `http://127.0.0.1:8000/api/mobile/`
- Administrator Portal API: `http://127.0.0.1:8000/api/v1/`

---

### 2. Administrator Portal Setup & Run

The administrator portal is a responsive Vite + React web application designed for desktop monitors and mobile touchscreens (down to 360x800px).

```powershell
cd AdministratorPage

# Install npm dependencies
npm install

# Configure environment variables
copy .env.example .env
# Verify VITE_API_URL=http://127.0.0.1:8000/api/v1

# Start the Vite development server
npm run dev

# Or build for production
npm run build
```

The admin portal will be running at `http://localhost:5173/` (or the port reported by Vite).

---

### 3. Flutter Mobile Application Setup & Run

The Flutter mobile application supports both English and Amharic, Ethiopian calendar conversion, employee ticket reporting & rating, technician work logs, and user self-registration with real administrative approval.

```powershell
cd arada_digaf_Mobile

# Fetch dependencies
flutter pub get

# Run static analysis and widget/unit tests
flutter analyze --no-fatal-infos
flutter test

# Run on Android Emulator (points to host via 10.0.2.2)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api

# Run on Physical Android Device (replace 192.168.1.X with your dev PC's LAN IP)
# Ensure your PC firewall allows incoming traffic on port 8000 and runserver is bound to 0.0.0.0:8000
flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8000/api

# Build release APKs (split by ABI)
flutter build apk --release --split-per-abi --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

Release APK outputs are placed in `arada_digaf_Mobile/build/app/outputs/flutter-apk/`:
- `app-arm64-v8a-release.apk` (modern 64-bit Android devices)
- `app-armeabi-v7a-release.apk` (legacy 32-bit Android devices)
- `app-x86_64-release.apk` (64-bit Android emulators)

---

### 4. Automated End-to-End Verification

A comprehensive 21-step E2E lifecycle test script is included in `scripts/e2e_check.py`. It verifies:
- Self-service employee and technician registration
- Login blocking with machine-readable codes (`account_pending`, `account_rejected`, `account_suspended`)
- Administrator review, approval with specialty confirmation, and rejection with mandatory reason
- Re-submission of rejected registration
- Ticket creation, assignment with due date and priority, technician start-work, work-record, and rating
- Server-side ticket isolation (employee cannot view another employee's tickets)
- Dev seed idempotency

To run the verification:

```powershell
python scripts\e2e_check.py
```

---

## Development Seed Credentials (DEV ONLY)

> [!WARNING]
> **DEV ONLY**: The credentials below are pre-seeded solely for local testing and demonstration. Dev seeding is disabled in production unless `DEV_SEED_ENABLED=true` is set. Never use these credentials in production environments.

### Administrator Accounts
| Role | Username | Email | Password | Purpose |
|---|---|---|---|---|
| **System Administrator** | `admin` | `admin@arada.gov.et` | `AdminPassword123!` | Full portal access: approve/reject registrations, assign tickets, manage users & categories |

### IT Support Technicians
| Specialty | Username | Email | Password | Status |
|---|---|---|---|---|
| **Network Support** | `tech_network` | `tech.network@arada.gov.et` | `TechPassword123!` | Active (Specialties: Network, Anti-virus & security) |
| **Hardware Support** | `tech_hardware` | `tech.hardware@arada.gov.et` | `TechPassword123!` | Active (Specialties: Hardware, Printers & copiers) |
| **Software Support** | `tech_software` | `tech.software@arada.gov.et` | `TechPassword123!` | Active (Specialties: Software, Anti-virus & security) |

### Active Employees
| Department | Username | Email | Password | Status |
|---|---|---|---|---|
| **Finance Department** | `selam` | `selam.worku@arada.gov.et` | `EmpPassword123!` | Active (Accounts Payable, Room 204) |
| **HR Department** | `dawit` | `dawit.kebede@arada.gov.et` | `EmpPassword123!` | Active (Personnel Records, Room 105) |
| **Legal Affairs** | `almaz` | `almaz.haile@arada.gov.et` | `EmpPassword123!` | Active (Legal Consultation, Room 302) |

### Pre-Seeded Pending Registrations (For Testing Approval Workflow)
| Role | Username | Reference # | Department / Specialties | Initial Status |
|---|---|---|---|---|
| **Employee** | `tariku` | `REG-2026-0001` | Planning Department (Strategic Planning) | Pending Approval |
| **Employee** | `marta` | `REG-2026-0002` | Administration (Executive Office) | Pending Approval |
| **Technician** | `yosef` | `REG-2026-0003` | IT Office (Specialties: Network, Hardware) | Pending Approval |

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

The Flutter app uses an HTTP repository for login, tickets, technician workflows, ratings, and notifications. See [backend/MOBILE_API.md](backend/MOBILE_API.md) for API details and the mobile build configuration.

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
- A Flutter mobile application connected to the compatibility API through an HTTP repository.

The mobile client integration is implemented in source. Flutter analysis, automated tests, live Atlas-backed API workflows, and release APK installation still need to be verified before production use.

---

## License

No license is specified in this repository at this time.
