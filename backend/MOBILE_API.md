# Flutter Mobile API Contract

The Flutter app now uses an HTTP repository for these endpoints. Authentication tokens are stored using platform secure storage, and the API base URL is supplied at build time through `API_BASE_URL`.

Base URL: `/api/mobile/`

All authenticated requests use:

```http
Authorization: Bearer <access_token>
Content-Type: application/json
```

Successful responses use `{"success": true, "data": ...}`. Errors use the backend's standard `success: false` error envelope.

## Authentication

### `POST auth/login/`

Accepts a username or email, password, and optional selected role.

```json
{
  "username": "selam",
  "password": "your-password",
  "role": "employee"
}
```

Roles exposed to the app are `employee` and `technician`; backend `support` and `admin` accounts are represented as `technician`.

**Successful response (HTTP 200):**
The response contains `access_token`, `token_type`, `expires_at`, and a user object using the Flutter fields `username`, `fullName`, `role`, `department`, `officeLocation`, and `phoneNumber`.

**Account Status Responses (HTTP 403 Forbidden):**
If credentials match but the account is not active, the endpoint returns a machine-readable error code:
- `account_pending`: Registration has been submitted and is awaiting administrator approval. Includes `referenceNumber` and `username`.
- `account_rejected`: Registration was rejected by the administrator. Includes `rejectionReason`, `referenceNumber`, and `user` object for resubmission.
- `account_suspended`: Account has been deactivated or suspended by an administrator.

**Invalid Credentials Response (HTTP 401 Unauthorized):**
Returned when the username/email does not exist or the password does not match.

### `POST auth/register/`

Public registration endpoint for employees and technicians. Accounts are created in `pending` status (`is_active: false`) awaiting administrative review.

```json
{
  "role": "employee",
  "fullName": "Abebe Tessema",
  "employeeId": "EMP-9021",
  "username": "abebe.t",
  "password": "Password123!",
  "confirmPassword": "Password123!",
  "phone": "0911223344",
  "email": "abebe.tessema@arada.gov.et",
  "department": "Finance Department",
  "workUnit": "Budget Division",
  "officeLocation": "Building B, Room 104"
}
```

For technicians (`role: "technician"`):
- `specialties`: array containing at least one of `["Network", "Hardware", "Software", "Printers & copiers", "Anti-virus & security"]`.
- `qualificationNote`: optional note regarding certifications or skills.

The phone number is normalized server-side to `+251XXXXXXXXX`. Server returns reference number `REG-2026-####`:

```json
{
  "success": true,
  "data": {
    "referenceNumber": "REG-2026-0004",
    "username": "abebe.t",
    "fullName": "Abebe Tessema",
    "role": "employee",
    "status": "pending",
    "createdAt": "2026-11-19T17:00:00Z"
  }
}
```

### `GET auth/registration-status/?ref=REG-2026-####&username=abebe.t`

Public status check endpoint for registrants to inspect their application status without exposing private records:

```json
{
  "success": true,
  "data": {
    "referenceNumber": "REG-2026-0004",
    "username": "abebe.t",
    "fullName": "Abebe Tessema",
    "role": "employee",
    "status": "pending",
    "rejectionReason": "",
    "createdAt": "2026-11-19T17:00:00Z"
  }
}
```

### `POST auth/logout/`

Revokes the current bearer token. Requires the authenticated Authorization header.

## Administrator Endpoints (`/api/v1/`)

Authenticated administrator endpoints (`Authorization: Bearer <token>`):

- `GET /api/v1/registrations/?status=pending&role=employee` — list pending registrations.
- `POST /api/v1/registrations/{id}/approve/` — approve registration, activate account, and optionally assign technician specialties (`{"specialties": [...]}`).
- `POST /api/v1/registrations/{id}/reject/` — reject registration with a required reason (`{"reason": "Invalid employee ID..."}`).


## Tickets

- `GET tickets/` — employee sees their own tickets; technicians see the support queue. Existing v1 tickets are enriched with their linked category, department, and requester profile where available.
- `POST tickets/` — employee submits a request.
- `GET tickets/{ticket-number}/` — fetch one ticket by its human-readable `AD-YYYY-NNNN` ID.
- `POST tickets/{ticket-number}/start-work/` — technician starts work and is assigned to the ticket.
- `POST tickets/{ticket-number}/work-record/` — technician records the outcome.
- `POST tickets/{ticket-number}/rating/` — ticket owner rates completed service.

Example create-ticket payload:

```json
{
  "category": "maintenance",
  "deviceType": "computer",
  "problemDescription": "Computer cannot connect to the office network.",
  "department": "Finance",
  "officeLocation": "Building A, Room 12",
  "phoneNumber": "+251911112222",
  "createdAt": "2026-11-16T09:30:00+03:00"
}
```

The requester name is taken from the authenticated account, not trusted from the request body.

Example work-record payload:

```json
{
  "deviceType": "Computer",
  "model": "Dell OptiPlex",
  "serialNumber": "SN12345",
  "problemDescription": "Replaced the faulty network adapter.",
  "toolsMaterials": "Network adapter",
  "outcome": "solutionGiven",
  "solutionDateTime": "2026-11-16T11:00:00+03:00"
}
```

Example rating payload:

```json
{
  "quality": "high",
  "speed": "veryHigh",
  "ratedAt": "2026-11-16T12:00:00+03:00"
}
```

Ticket responses use the Flutter model names: `id`, `category`, `deviceType`, `problemDescription`, `department`, `officeLocation`, `phoneNumber`, `createdAt`, `status`, `requesterName`, `assignedTechnician`, `timeline`, `workRecord`, and `rating`.

Supported category values: `maintenance`, `antivirus`, `software`, `technical`, `other`.

Supported device values: `computer`, `printer`, `network`, `copyMachine`, `other`.

Flutter status values: `submitted`, `inProgress`, `resolved`, `notResolved`, `referred`. Work outcomes map to the last three values. The backend stores a canonical workflow status separately from the Flutter-facing status.

Create-ticket, work-record, and rating requests accept both camelCase Flutter field names and snake_case API field names.

## Notifications

- `GET notifications/` — current user's notifications.
- `GET notifications/?unread=true` — only unread notifications.
- `PATCH notifications/{notification-id}/` with `{"read": true}` — mark as read.

Notification responses use `id`, `title`, `message`, `ticketId`, `timestamp`, `isRead`, and `type`. Types are `submitted`, `resolved`, `ratingRequest`, and `assigned`.

## Client configuration

The mobile client reads `API_BASE_URL` at compile time. For a Render deployment, build with the full API prefix, for example:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://YOUR-RENDER-SERVICE.onrender.com/api
```

For Android Emulator local development, the default is `http://10.0.2.2:8000/api`. For a physical device, pass your development computer's LAN address instead. Use HTTPS for deployed builds.

The mobile client calls the endpoints above for login/logout, ticket CRUD/workflows, ratings, and notifications. Live deployment, backend connectivity, and signed APK testing remain separate verification steps.
