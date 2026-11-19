# Deploy AradaDgaf Backend to Render

The repository includes a Render Blueprint at the project root. It creates a Python web service named `aradadgaf-api` and uses the `backend/` directory as its root.

## 1. Prepare MongoDB Atlas

1. Create or select the AradaDgaf Atlas project and cluster.
2. Create a database user with a strong password and only the permissions needed for the application database.
3. In **Network Access**, allow connections from Render. For a quick initial test, Atlas can allow access from anywhere (`0.0.0.0/0`), but this exposes the database endpoint to the internet and should only be used with a strong database user. Prefer Render's static outbound IP allowlist when your Render plan provides it.
4. Copy the Atlas **Drivers** connection string. Replace its username/password placeholders and keep the URI private.

The database name configured by the Blueprint is `AradaDgaf`.

## 2. Create the Render service

1. Push the repository to GitHub.
2. In Render, choose **New + → Blueprint**.
3. Connect `Mebrie-Awoke/AradaDgaf` and select the `main` branch.
4. Render detects the root `render.yaml`. Review the service and create it.
5. In the service's Environment settings, provide:
   - `MONGODB_URI`: the complete Atlas connection string.
   - `CORS_ALLOWED_ORIGINS`: comma-separated browser origins, for example `https://your-admin-portal.vercel.app`. Do not include a trailing slash. Add localhost origins only if you need local browser development.
6. Keep `DJANGO_DEBUG=false`, and do not replace the generated `DJANGO_SECRET_KEY` with a public or committed value.
7. Deploy and inspect the build/deploy logs.

The Blueprint runs Django's built-in migrations, applies the versioned MongoDB migrations, and then starts Gunicorn. Render checks `/api/ready/`; this endpoint reports healthy only when MongoDB can be reached.

## 3. Verify the deployment

After Render reports the service as live, open:

- `https://YOUR-SERVICE.onrender.com/api/health/` — basic API process check.
- `https://YOUR-SERVICE.onrender.com/api/ready/` — database readiness check.

A successful readiness response includes `"database": "connected"`. Then test login and ticket operations using provisioned test accounts. Never put passwords or Atlas credentials in source control or chat.

## 4. Important storage and database notes

- The application stores operational records in MongoDB Atlas. Django's SQLite database is only for Django's built-in admin/session framework; Render's default filesystem is ephemeral, so SQLite data is not durable across all redeploys/restarts. Do not rely on Django admin/session persistence unless you configure persistent storage or move those Django tables to a managed database.
- Ticket attachments currently use the configured private storage backend. The default is local filesystem storage, which is ephemeral on Render. Before relying on attachments in production, configure durable private object storage (for example, an S3-compatible bucket) and the corresponding storage backend credentials, or attach a Render persistent disk on a plan that supports it.
- Confirm the MongoDB Atlas cluster is backed up and that you know how to restore it.
- Configure CORS with the exact deployed administrator portal origin. CORS is not an authentication mechanism.
- After deployment, run a complete workflow test: employee creates ticket → administrator assigns it → technician records work/resolves it → employee views and rates it.

## Render settings summary

The Blueprint defines:

| Setting | Value |
|---|---|
| Runtime | Python |
| Root directory | `backend` |
| Build command | `pip install -r requirements.txt` |
| Start command | Django migrations, MongoDB migrations, then Gunicorn |
| Health check | `/api/ready/` |
| Database | MongoDB Atlas |
