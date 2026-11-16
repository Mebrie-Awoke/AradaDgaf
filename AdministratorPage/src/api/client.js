const API_BASE = (import.meta.env.VITE_API_BASE_URL || "http://127.0.0.1:8000/api").replace(/\/$/, "");

export class ApiError extends Error {
  constructor(message, statusCode, details) { super(message); this.statusCode = statusCode; this.details = details; }
}

export async function apiRequest(path, { token, method = "GET", body, headers = {} } = {}) {
  const response = await fetch(`${API_BASE}${path.startsWith("/") ? path : `/${path}`}`, {
    method,
    headers: {
      ...(body instanceof FormData ? {} : body ? { "Content-Type": "application/json" } : {}),
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...headers,
    },
    ...(body !== undefined ? { body: body instanceof FormData ? body : JSON.stringify(body) } : {}),
  });
  const payload = response.status === 204 ? {} : await response.json().catch(() => ({}));
  if (!response.ok || payload.success === false) {
    const detail = payload.detail || payload.message || payload.errors || payload;
    const message = typeof detail === "string" ? detail : Object.entries(detail || {}).map(([k,v]) => `${k}: ${Array.isArray(v) ? v.join(", ") : typeof v === "string" ? v : JSON.stringify(v)}`).join(" · ") || `Request failed (${response.status})`;
    throw new ApiError(message, response.status, detail);
  }
  return payload;
}

export const unwrap = (payload) => payload?.data ?? payload;
export { API_BASE };