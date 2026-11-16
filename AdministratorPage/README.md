# AradaDgaf Administrator Portal

React + Vite administrator interface for the existing AradaDgaf Django REST API.

## Run locally

From this directory:

```bash
npm install
```

Copy `.env.example` to `.env` and set `VITE_API_BASE_URL` to the backend API root (the URL ending in `/api`). For local development the default is `http://127.0.0.1:8000/api`.

```bash
npm run dev
```

Open http://localhost:5173.

## Backend endpoints used

- `POST /api/v1/auth/login/` and `POST /api/v1/auth/logout/`
- `GET /api/v1/dashboard/`
- `GET /api/v1/tickets/` and `PATCH /api/v1/tickets/{ticket-id}/`
- `GET /api/v1/users/`, `POST /api/v1/users/`, `PATCH /api/v1/users/{user-id}/`
- `GET/POST /api/v1/departments/` and `/api/v1/categories/`
- `PATCH /api/v1/departments/{id}/` and `/api/v1/categories/{id}/`
- `GET /api/v1/admin/audit/`

The portal uses the same MongoDB-backed users, tickets, departments, categories, and bearer-token authentication as the backend. Flutter's separate `/api/mobile/` compatibility routes and source are not modified.

## Security notes

- Sign-in is restricted in the UI to accounts whose backend role is `admin`. The backend remains the authority for authorization.
- Access tokens are stored in browser local storage for this first implementation. Deploy only over HTTPS, restrict allowed CORS origins, and consider an HttpOnly-cookie session design before production use.
- Never expose the MongoDB connection string or Django secrets in Vite environment variables. Only the public API base URL belongs in `VITE_*` variables.
- All writes go through existing API permission checks and validation. An administrator cannot bypass backend role or workflow rules.
