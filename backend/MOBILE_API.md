# Flutter Mobile API Contract

The Flutter source currently uses an in-memory repository. The endpoints below are a backend contract for a later frontend integration phase; they do not change or connect the current mock repository.

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

Roles exposed to the app are `employee` and `technician`; backend `support` and `admin` accounts are represented as `technician`. The response contains `access_token`, `token_type`, `expires_at`, and a user object using the Flutter fields `username`, `fullName`, `role`, `department`, `officeLocation`, and `phoneNumber`.

The endpoint does not accept the Flutter demo credentials. Accounts must exist in the backend.

### `POST auth/logout/`

Revokes the current bearer token. Requires the authenticated Authorization header.

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

## Important phase boundary

These endpoints are additive. The existing `/api/v1/` API remains available, and the Flutter source folder is not modified. The app still uses `MockTicketRepository` until a separate frontend integration phase replaces it with an HTTP repository and production login flow.
