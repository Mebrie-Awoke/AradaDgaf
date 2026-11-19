# Integration Audit: Arada Digaf IT-Support Ticketing System

**Date:** 2026-11-19  
**Branch:** `feature/e2e-registration-approval`  
**Author:** Senior Full-Stack Engineer & Integration Lead  
**Scope:** `backend/`, `AdministratorPage/`, `arada_digaf_Mobile/`

---

## 1. System Stack & Versions

### 1.1 Backend (`backend/`)
- **Runtime:** Python `3.12.10`
- **Framework:** Django `6.1.2` (configured via `config/settings.py`, requirements specify `Django>=5.2,<5.3`)
- **API Framework:** Django REST Framework `3.16.x` (`djangorestframework>=3.16,<3.17`)
- **Database Engine:** MongoDB via PyMongo `4.10.x` (`pymongo[srv]>=4.10,<5`).
  *Note:* Django ORM models are not used for domain data; domain storage is handled directly via PyMongo in `core/db.py`, collections defined in `core/mongo_migrations/`. SQLite (`db.sqlite3`) is retained solely for Django's internal admin/sessions.
- **CORS:** `django-cors-headers>=4.7,<5`
- **Environment Management:** `python-dotenv>=1,<2`
- **WSGI/Production:** Gunicorn `23.x` (`gunicorn>=23,<24`)

### 1.2 Administrator Web Portal (`AdministratorPage/`)
- **Build Tool:** Vite `5.4.14` (`vite.config.js`)
- **Framework:** React `18.3.1`, React DOM `18.3.1` (`package.json`)
- **Language:** JavaScript (ES modules, JSX). *Note:* TypeScript is NOT used in this project.
- **Icons:** `lucide-react` `0.468.0`
- **Node / Package Manager:** Node `v24.15.0`, npm `11.12.1`

### 1.3 Mobile Application (`arada_digaf_Mobile/`)
- **Framework:** Flutter `3.44.8` (channel stable)
- **Dart SDK:** Dart `3.12.2` (pubspec `^3.12.2`)
- **Key Dependencies:**
  - `http: ^1.2.2` (REST client)
  - `flutter_secure_storage: ^9.2.4` (secure token caching)
  - `flutter_lints: ^6.0.0`
- **Platform:** Android (debug/release configs in `android/app/src/`)

### 1.4 CI/CD Workflows (`.github/workflows/`)
- `backend-ci.yml`: Triggers on push and PR for `backend/**`; runs on `ubuntu-latest` with Python 3.12, tests `manage.py check` and `manage.py test core --verbosity 2`.
- `mobile-flutter.yml`: Triggers on push and PR for `arada_digaf_Mobile/**`; runs on `ubuntu-latest`, runs `flutter pub get`, `flutter analyze --no-fatal-infos`, and `flutter test`.

---

## 2. How to Run Each Subsystem

### 2.1 Backend
```bash
cd backend
python -m venv .venv
# Windows:
.venv\Scripts\activate
# Linux/macOS:
# source .venv/bin/activate

pip install -r requirements.txt
# Ensure .env exists with MONGODB_URI, DJANGO_SECRET_KEY, DJANGO_DEBUG=true
python manage.py migrate  # Sets up SQLite for Django internals
python manage.py dev_seed # Creates seed data (admin, technicians, employees, categories, depts)
python manage.py runserver 0.0.0.0:8000
```

### 2.2 Administrator Portal
```bash
cd AdministratorPage
npm install
# Ensure .env contains VITE_API_BASE_URL=http://127.0.0.1:8000/api
npm run dev
# Portal serves on http://localhost:5173
```

### 2.3 Mobile App
```bash
cd arada_digaf_Mobile
flutter pub get
# For Android Emulator:
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
# For physical device on local Wi-Fi:
flutter run --dart-define=API_BASE_URL=http://<YOUR_LAN_IP>:8000/api
```

---

## 3. Real Endpoint Matrix & Contract Discrepancies

| Method | Endpoint | Defined In | Consumed In | Discrepancies / Gaps |
|---|---|---|---|---|
| `POST` | `/api/mobile/auth/login/` | `core/mobile_compat.py` | `api_ticket_repository.dart` | Documented in `MOBILE_API.md`. Currently returns generic `401 Invalid username or password` for inactive accounts; does not distinguish `account_pending`, `account_rejected`, or `account_suspended`. |
| `POST` | `/api/mobile/auth/logout/` | `core/mobile_compat.py` | `api_ticket_repository.dart` | Matches contract. |
| `POST` | `/api/mobile/auth/register/` | **MISSING** | **MISSING** | **Critical Gap**: Required for public registration of employees and technicians with `pending` status, Ethiopian phone validation, employee ID, and reference number (`REG-2026-####`). |
| `GET` | `/api/mobile/auth/registration-status/` | **MISSING** | **MISSING** | **Critical Gap**: Needed for registrant to check status via reference number + username. |
| `GET` | `/api/mobile/tickets/` | `core/mobile_compat.py` | `api_ticket_repository.dart` | Matches contract. Returns list for employee (own) or technician (queue). |
| `POST` | `/api/mobile/tickets/` | `core/mobile_compat.py` | `api_ticket_repository.dart` | Generates `AD-YYYY-NNNN` ticket number. Server takes owner from auth user. |
| `GET` | `/api/mobile/tickets/<number>/` | `core/mobile_compat.py` | `api_ticket_repository.dart` | Matches contract. |
| `POST` | `/api/mobile/tickets/<number>/start-work/` | `core/mobile_compat.py` | `api_ticket_repository.dart` | Technician assigns themselves and marks `inProgress`. |
| `POST` | `/api/mobile/tickets/<number>/work-record/` | `core/mobile_compat.py` | `api_ticket_repository.dart` | Technician records outcome and resolution notes. |
| `POST` | `/api/mobile/tickets/<number>/rating/` | `core/mobile_compat.py` | `api_ticket_repository.dart` | Employee rates service quality and speed. |
| `GET` | `/api/mobile/notifications/` | `core/mobile_compat.py` | `api_ticket_repository.dart` | Matches contract. Supports `?unread=true`. |
| `PATCH` | `/api/mobile/notifications/<id>/` | `core/mobile_compat.py` | `api_ticket_repository.dart` | Marks notification as read. |
| `GET` | `/api/health/` | `core/views.py` | Unused | Not in `MOBILE_API.md`. |
| `POST` | `/api/v1/auth/register/` | `core/views.py` | Unused | Legacy v1 register. Only creates active employees, no reference numbers, no pending status, no technician support. |
| `POST` | `/api/v1/auth/login/` | `core/views.py` | `AdministratorPage/AuthContext.jsx` | Authenticates admin using email + password. Returns Bearer token. |
| `POST` | `/api/v1/auth/logout/` | `core/views.py` | `AdministratorPage/AuthContext.jsx` | Revokes Bearer token. |
| `GET` | `/api/v1/registrations/` | **MISSING** | **MISSING** | **Critical Gap**: Admin endpoint to list pending/reviewed registrations filtered by role and status. |
| `POST` | `/api/v1/registrations/<id>/approve/` | **MISSING** | **MISSING** | **Critical Gap**: Admin endpoint to approve registration (activates account, assigns specialties for technician, writes audit log). |
| `POST` | `/api/v1/registrations/<id>/reject/` | **MISSING** | **MISSING** | **Critical Gap**: Admin endpoint to reject registration with required reason (min 5 characters) and audit log. |
| `GET` | `/api/v1/dashboard/` | `core/views.py` | `DashboardPage.jsx` | Returns ticket counts by status and priority, total tickets, unread notifications. |
| `GET` | `/api/v1/users/` | `core/views.py` | `UsersPage.jsx`, `TicketsPage.jsx` | Admin-only. Supports query filtering and pagination. |
| `POST` | `/api/v1/users/` | `core/views.py` | `UsersPage.jsx` | Admin manual provisioning. |
| `PATCH` | `/api/v1/users/<id>/` | `core/views.py` | `UsersPage.jsx` | Admin user update (active status, department, role). |
| `GET` | `/api/v1/departments/` | `core/views.py` | `ResourcesPage.jsx`, `UsersPage.jsx` | Lists departments. |
| `POST` | `/api/v1/departments/` | `core/views.py` | `ResourcesPage.jsx` | Creates department. |
| `PATCH` | `/api/v1/departments/<id>/` | `core/views.py` | `ResourcesPage.jsx` | Updates department. |
| `GET` | `/api/v1/categories/` | `core/views.py` | `ResourcesPage.jsx` | Lists ticket categories. |
| `POST` | `/api/v1/categories/` | `core/views.py` | `ResourcesPage.jsx` | Creates category. |
| `PATCH` | `/api/v1/categories/<id>/` | `core/views.py` | `ResourcesPage.jsx` | Updates category. |
| `GET` | `/api/v1/tickets/` | `core/views.py` | `TicketsPage.jsx`, `DashboardPage.jsx` | Lists tickets with filtering. Discrepancy: generates `AF-YYYY-NNNNN` prefix while mobile generates `AD-YYYY-NNNN`. |
| `PATCH` | `/api/v1/tickets/<id>/` | `core/views.py` | `TicketsPage.jsx` | Assigns technician, updates status and resolution note. |
| `GET` | `/api/v1/admin/audit/` | `core/views.py` | `AuditPage.jsx` | Lists administrative audit entries. |

---

## 4. User Model, Role Representation & Auth Mechanism

### 4.1 Backend User Document (`database.users`)
- `_id`: `ObjectId`
- `email`: String (unique index)
- `username`: String (sparse unique index in migration 0004)
- `name`: String
- `password`: Django hashed password (`make_password`, PBKDF2-SHA256)
- `role`: Canonical role in backend is one of `['employee', 'support', 'admin']`
- `employee_id`: Proposed and needed for registration (`employeeId`)
- `phone_number`: String (to be normalized to `+251XXXXXXXXX`)
- `office_location`: String
- `work_unit`: String (work unit within department)
- `department_id`: `ObjectId` referencing `database.departments`
- `specialties`: Array of Strings (for technicians: `Network`, `Hardware`, `Software`, `Printers & copiers`, `Anti-virus & security`)
- `qualification_note`: String (optional notes for technician)
- `status`: String (`pending`, `active`, `rejected`, `suspended`). Currently only `is_active: bool` exists.
- `rejection_reason`: String (if rejected)
- `registration_reference`: String (e.g. `REG-2026-0001`)
- `created_at`, `updated_at`: Datetime (UTC)

### 4.2 Role Mapping
- **Backend:** `employee`, `support`, `admin`.
- **Mobile Client:** `employee`, `technician`.
  *Mapping in `mobile_compat.py`:* backend `support` and `admin` map to mobile `technician`. Mobile `employee` maps to backend `employee`.
- **Admin Portal:** Accessible only by accounts with backend `role == "admin"`.

### 4.3 Authentication & Session Management
- **Type:** Bearer token authentication (`core.authentication.BearerTokenAuthentication`).
- **Token Generation:** 40-byte URL-safe string (`secrets.token_urlsafe(40)`).
- **Storage:** Stored in `database.access_tokens` as SHA-256 digest (`token_hash`).
- **TTL / Lifetime:** Configured by `ACCESS_TOKEN_TTL_SECONDS` (default `43200` seconds = 12 hours). Expired tokens are purged automatically by MongoDB TTL index on `expires_at`.
- **Mobile Caching:** `FlutterSecureStorage` under key `arada_access_token`. On `401 Unauthorized`, cached token is deleted and user is redirected to login.
- **Admin Caching:** `localStorage` under key `aradadgaf.admin.session`.

---

## 5. Ticket Status Vocabulary & Cross-Platform Alignment

### 5.1 Status Mappings Across Layers

| Lifecycle Stage | Backend (`status`) | Backend (`mobile_status`) | Mobile (`TicketStatus`) | Admin Portal Display |
|---|---|---|---|---|
| Submitted / New | `submitted` | `submitted` | `submitted` ("የቀረበ") | `submitted` ("New requests") |
| Assigned | `assigned` | `inProgress` | `inProgress` ("በሂደት ላይ") | `assigned` ("Assigned") |
| In Progress | `in_progress` | `inProgress` | `inProgress` ("በሂደት ላይ") | `in_progress` ("In progress") |
| Resolved (Solution Given) | `resolved` | `resolved` | `resolved` ("የተፈታ") | `resolved` ("Resolved") |
| Closed / Unresolved | `closed` | `notResolved` | `notResolved` ("ያልተፈታ") | `closed` ("Closed") |
| Closed / Referred | `closed` | `referred` | `referred` ("የተላለፈ") | `closed` ("Closed") |

### 5.2 Access & Isolation Rules
- **Employee:** Can ONLY list and retrieve tickets where `owner_id == request.user.id`. Guessing ticket IDs or numbers returns 404. Can only close a resolved ticket or submit ratings.
- **Technician:** Can view the support queue and tickets assigned to them. Starting work assigns the ticket. Only the assigned technician or an admin can record work on an in-progress ticket.
- **Administrator:** Can view all tickets across all departments, reassign, adjust priority and status, and review audit history.

---

## 6. What Currently Works, What Is Mocked, What Is Broken

### 6.1 Backend
- **Works:**
  - Bearer token authentication and validation.
  - Mobile ticket creation, queue listing, start work, record work, rating, and notifications (`/api/mobile/`).
  - Admin endpoints for dashboard metrics, tickets, users, departments, categories, and audit log (`/api/v1/`).
- **Broken / Gaps:**
  - No public registration endpoint for mobile app (`/api/mobile/auth/register/`).
  - No registration status lookup endpoint (`/api/mobile/auth/registration-status/`).
  - Login fails with generic `401` on inactive accounts rather than returning structured error codes (`account_pending`, `account_rejected`, `account_suspended`).
  - No administrator approval workflow endpoints (`/api/v1/registrations/`).
  - Inconsistency in ticket prefix generation (`AD-` in mobile vs `AF-` in v1).

### 6.2 Mobile App
- **Works:**
  - Login screen authenticates against `/api/mobile/auth/login/` and persists token in `flutter_secure_storage`.
  - Tickets list, new ticket creation flow, timeline visualization, and rating screens function against live backend.
  - Bilingual UI support (English and Amharic) and Ethiopian date picker.
- **Broken / Gaps:**
  - **No account registration flow:** No "Register" button on login screen; no registration stepper wizard.
  - **No registration post-submit or status screens:** Missing "Registration Submitted", "Pending Approval", "Registration Not Approved" (with resubmit capability), and "Account Suspended".
  - `app_state.dart` swallows structured login error codes and only flags a generic boolean.
  - Android debug manifest lacks `android:usesCleartextTraffic="true"` for local HTTP testing against emulator (`10.0.2.2`) or local LAN.

### 6.3 Admin Portal
- **Works:**
  - Administrator login and session validation with token storage in `localStorage`.
  - Dashboard stats, tickets list with filter and basic assignment modal, users list and provision modal, departments/categories management, audit log.
- **Broken / Gaps:**
  - **Approvals Screen Missing:** No interface to view pending employee/technician registrations, inspect credentials, approve with specialties, or reject with reason.
  - **Assignment Desk Deficient:** No dedicated assignment view with technician workload tracking, due date setting, or assignment notes.
  - **Not Phone-Friendly:** Desktop-only layout with fixed tables that break on mobile screens (< 768px). Lacks bottom navigation bar, mobile card views, bottom-sheet dialogs/filters, and 44px minimum touch targets.

---

## 7. Action Plan by Phase

1. **Phase 1: Local Run & Dev Seeding**
   - Configure cleartext HTTP in Android debug manifest.
   - Verify CORS headers in Django settings.
   - Implement `python manage.py dev_seed` command populating administrative roles, technicians with paper-form specialties, active employees, pending registrations, standard departments, and sample tickets.

2. **Phase 2: Backend Registration & Approval System**
   - Add `POST /api/mobile/auth/register/` with validation (Ethiopian phone normalization, unique username and employee ID, reference number `REG-2026-####`, initial `status="pending"`).
   - Update `MobileLoginView` to inspect account status and return structured error codes: `account_pending`, `account_rejected` (with reason), `account_suspended`.
   - Add `GET /api/mobile/auth/registration-status/`.
   - Add admin registration management endpoints (`GET /api/v1/registrations/`, `POST /api/v1/registrations/<id>/approve/`, `POST /api/v1/registrations/<id>/reject/`).
   - Implement rate throttling on auth endpoints.

3. **Phase 3: Mobile Registration Wizard & Status Screens**
   - Add registration entry point to `login_screen.dart`.
   - Build 2-step stepper wizard (Step 1: Account info, Step 2: Work & specialties).
   - Implement inline client validation matching backend rules.
   - Create post-submission and status screens (`RegistrationSubmittedScreen`, `PendingApprovalScreen`, `RegistrationRejectedScreen`).
   - Wire registration repository methods with `USE_MOCK` fallback support.

4. **Phase 4: Admin Portal Real API & Mobile Responsiveness**
   - Build dedicated **Approvals** tab (Employees / Technicians) with real-time pending badges, approval modal, and rejection modal with required reason.
   - Enhance **Assignment Desk** to display technician workload metrics and permit setting due dates and notes.
   - Implement mobile responsive design (< 768px) with top bar, bottom navigation tab bar (Dashboard, Assignment, Approvals, Tickets, More), responsive card layouts, and touch-optimized controls.

5. **Phase 5 & 6: Ticket Lifecycle Alignment & Security Verification**
   - Validate and ensure ticket isolation across roles.
   - Ensure proper password hashing, security headers, CORS boundaries, and sanitize error responses.

6. **Phase 7 & 8: End-to-End Testing & Packaging**
   - Write comprehensive Django and Flutter tests.
   - Implement automated E2E script (`scripts/e2e_check.py`).
   - Update `README.md`, `backend/MOBILE_API.md`, and produce release artifacts in `delivery/`.

---

## 8. Final Integration & Verification Report

### 8.1 Automated Test Execution Summary

| Component | Test Suite | Command | Outcome |
|---|---|---|---|
| **Backend** | Django Unit & Integration Tests | `python backend/manage.py test core` | **39 / 39 PASSED** (0 failures, 0 errors) |
| **Backend** | Django Configuration Check | `python backend/manage.py check` | **PASSED** (0 issues silenced) |
| **Mobile App** | Flutter Static Analysis | `flutter analyze --no-fatal-infos` | **PASSED** (0 issues found) |
| **Mobile App** | Flutter Unit & Widget Tests | `flutter test` | **14 / 14 PASSED** (All tests passed) |
| **Admin Portal** | Vite Production Build | `npm run build` | **PASSED** (Clean production bundle built in 5.4s) |
| **End-to-End** | 21-Step Full Lifecycle Verification | `python scripts/e2e_check.py` | **21 / 21 PASSED** (100% success rate) |

### 8.2 End-to-End Lifecycle Verification Matrix (`scripts/e2e_check.py`)

1. `[PASS]` **1. Register Employee A**: Public registration endpoint creates pending account with reference `REG-2026-####`.
2. `[PASS]` **2. Reject Login for Pending Employee A**: Status 403 returned with structured machine-readable code `account_pending`.
3. `[PASS]` **3. Query Registration Status by Reference #**: Status check returns `status: pending` without leaking credentials.
4. `[PASS]` **4. Admin Login and Token Retrieval**: System administrator logs in and retrieves valid Bearer access token.
5. `[PASS]` **5. Admin Approves Employee A**: Admin lists pending registrations and approves Employee A, activating the account.
6. `[PASS]` **6. Employee A Login After Approval**: Employee A logs in successfully and receives mobile Bearer token.
7. `[PASS]` **7. Employee A Creates Ticket (AD-2026-####)**: Employee creates maintenance ticket with human-readable ID format.
8. `[PASS]` **8. Admin Assigns Technician, Sets Priority High & Due Date**: Admin patches ticket with assigned technician, priority, due date, and note.
9. `[PASS]` **9. Technician T Login**: Assigned technician logs in with technician role and acquires Bearer token.
10. `[PASS]` **10. Technician Starts Work (Status In Progress)**: Technician calls `start-work`, updating ticket status to `inProgress`.
11. `[PASS]` **11. Technician Records Work and Resolves Ticket**: Technician records diagnostic findings, tools used, and marks outcome `solutionGiven` (`resolved`).
12. `[PASS]` **12. Employee A Rates Ticket Quality & Speed (5 Stars)**: Ticket owner rates completed service with 5-star quality and speed.
13. `[PASS]` **13. Admin Sees Recorded Ticket Rating on Detail View**: Rating data is recorded and visible to administrator.
14. `[PASS]` **14. Register Technician B (Pending Status)**: Technician self-registers with specialties (`hardware`, `network`).
15. `[PASS]` **15. Admin Rejects Technician B With Mandatory Reason**: Admin rejects registration with reason (`>= 5` characters).
16. `[PASS]` **16. Technician B Login Blocked With account_rejected & Rejection Reason**: Login returns HTTP 403 with `account_rejected` and administrative reason.
17. `[PASS]` **17. Technician B Resubmits Registration (Re-enters Pending Status)**: Rejected technician updates application and resubmits into `pending` queue.
18. `[PASS]` **18. Admin Approves Technician B With Confirmed Specialties**: Admin reviews updated application and approves with confirmed specialties.
19. `[PASS]` **19. Technician B Login After Re-Approval**: Re-approved technician logs in successfully.
20. `[PASS]` **20. Server-Side Ticket Isolation**: Employee A attempting to access Employee C's private ticket receives HTTP 404/403.
21. `[PASS]` **21. Dev Seed Command Idempotency**: `dev_seed` command runs repeatedly without duplicate key collisions.

### 8.3 Honest Status: Verified vs NOT Verified

#### What is VERIFIED:
- **Backend API & Migrations**: Django REST API running with live MongoDB Atlas database. All 5 migrations applied cleanly.
- **Self-Service Registration & Status Checks**: Employees and technicians register, receive reference numbers `REG-2026-####`, and check status.
- **Login Blocking**: Non-active accounts are blocked at login with structured HTTP 403 error codes (`account_pending`, `account_rejected`, `account_suspended`).
- **Administrative Approvals & Rejections**: Full workflow with specialty assignment and mandatory rejection reasons.
- **Mobile Responsive Admin Portal**: Tested layout down to 360x800px with bottom navigation bar, card lists, bottom sheets, and touch targets >= 44px.
- **Ticket Lifecycle & Isolation**: Complete path from ticket creation to technician work-recording, resolution, and rating. Server-side isolation blocks cross-employee access.
- **Flutter Test Suite & Static Analysis**: Zero analysis warnings; 14 of 14 unit and widget tests passing.
- **Release APK Generation**: Split-per-ABI release APKs compiled for arm64-v8a, armeabi-v7a, and x86_64.

#### What is NOT Verified:
- **Physical Phone on HTTPS**: App tested against Android emulator cleartext dev config (`http://10.0.2.2:8000/api`) and automated script. Physical smartphone installation over a production HTTPS domain was not verified as no physical device or production domain was attached.
- **Push Notifications (FCM / APNs)**: In-app database notifications are verified end-to-end; native push notification gateways (Firebase Cloud Messaging / Apple APNs) require external cloud provider credentials not configured in this local environment.
- **Production Server Deployment (Gunicorn / Nginx)**: Tested on Django's WSGI server locally; deployment to a production Linux container (e.g. Render / Docker) was not executed.
