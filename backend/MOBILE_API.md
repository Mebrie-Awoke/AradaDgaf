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

## Tickets

- `GET tickets/` — employee sees their own tickets; technicians see the support queue.
- `POST tickets/` — employee submits a request.
- `GET tickets/{ticket-number}/` — fetch one ticket by its human-readable `AD-YYYY-NNNN` ID.
- `POST tickets/{ticket-number}/start-work/` — technician starts work and is assigned to the ticket.
- `POST tickets/{ticket-number}/work-record/` — technician records the outcome.
- `POST tickets/{ticket-number}/rating/` — ticket owner rates completed service.

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
