import { Search, UserPlus, Users, X, Shield, UserCog, RefreshCw } from "lucide-react";
import { useEffect, useState } from "react";
import { apiRequest, unwrap } from "../api/client";
import { useAuth } from "../context/AuthContext";

const blank = {
  name: "",
  email: "",
  username: "",
  password: "",
  role: "support",
  department_id: "",
  phone_number: "",
  office_location: "",
};

export default function UsersPage() {
  const { token } = useAuth();
  const [users, setUsers] = useState([]);
  const [departments, setDepartments] = useState([]);
  const [query, setQuery] = useState("");
  const [modal, setModal] = useState(false);
  const [form, setForm] = useState(blank);
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");
  const [busy, setBusy] = useState(false);

  async function load() {
    setBusy(true);
    try {
      const [u, d] = await Promise.all([
        apiRequest("/v1/users/?page_size=100", { token }),
        apiRequest("/v1/departments/?page_size=100", { token }),
      ]);
      setUsers(unwrap(u) || []);
      setDepartments(unwrap(d) || []);
    } catch (e) {
      setError(e.message);
    } finally {
      setBusy(false);
    }
  }

  useEffect(() => {
    load();
  }, [token]);

  async function create(e) {
    e.preventDefault();
    setError("");
    try {
      await apiRequest("/v1/users/", { token, method: "POST", body: form });
      setModal(false);
      setForm(blank);
      setNotice("Account created. Share the initial password securely with the account owner.");
      load();
    } catch (e) {
      setError(e.message);
    }
  }

  async function update(user, patch) {
    try {
      await apiRequest(`/v1/users/${user.id}/`, { token, method: "PATCH", body: patch });
      setNotice("User account updated.");
      load();
    } catch (e) {
      setError(e.message);
    }
  }

  const filtered = users.filter((u) =>
    [u.name, u.email, u.username, u.role, u.phone_number].join(" ").toLowerCase().includes(query.toLowerCase())
  );

  return (
    <>
      <div className="page-heading">
        <div>
          <div className="eyebrow">TEAM DIRECTORY</div>
          <h1>People & access</h1>
          <p>Provision support staff and administrator accounts, and manage access roles.</p>
        </div>
        <button
          className="primary-btn"
          onClick={() => {
            setForm(blank);
            setModal(true);
            setError("");
          }}
        >
          <UserPlus size={17} /> Add account
        </button>
      </div>

      {error && <div className="alert-error">{error}</div>}
      {notice && (
        <div className="alert-success">
          {notice}
          <button onClick={() => setNotice("")}>
            <X size={14} />
          </button>
        </div>
      )}

      <div className="people-stats">
        <div className="mini-stat">
          <Users size={18} />
          <span>All accounts</span>
          <b>{users.length}</b>
        </div>
        <div className="mini-stat">
          <UserCog size={18} />
          <span>IT support</span>
          <b>{users.filter((u) => u.role === "support").length}</b>
        </div>
        <div className="mini-stat">
          <Shield size={18} />
          <span>Administrators</span>
          <b>{users.filter((u) => u.role === "admin").length}</b>
        </div>
      </div>

      <section className="panel">
        <div className="list-toolbar">
          <div className="search-box">
            <Search size={17} />
            <input
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Search name, email or role…"
            />
          </div>
          <button className="icon-btn" onClick={load}>
            <RefreshCw size={17} />
          </button>
        </div>

        {busy ? (
          <div className="empty-state">Loading accounts…</div>
        ) : filtered.length === 0 ? (
          <div className="empty-state">No user accounts found.</div>
        ) : (
          <>
            {/* Desktop Table View */}
            <div className="table-wrap desktop-only-table">
              <table>
                <thead>
                  <tr>
                    <th>Person</th>
                    <th>Role</th>
                    <th>Department</th>
                    <th>Contact</th>
                    <th>Access</th>
                  </tr>
                </thead>
                <tbody>
                  {filtered.map((u) => (
                    <tr key={u.id}>
                      <td>
                        <div className="person-cell">
                          <div className="avatar small">
                            {(u.name || "U").slice(0, 1).toUpperCase()}
                          </div>
                          <div>
                            <b>{u.name}</b>
                            <small>{u.email}</small>
                          </div>
                        </div>
                      </td>
                      <td>
                        <span className={`role-pill ${u.role}`}>
                          {u.role === "support"
                            ? "IT Support"
                            : u.role === "admin"
                            ? "Administrator"
                            : "Employee"}
                        </span>
                      </td>
                      <td>{departments.find((d) => d.id === u.department_id)?.name || "—"}</td>
                      <td>{u.phone_number || "—"}</td>
                      <td>
                        <select
                          className="access-select"
                          value={u.is_active === false ? "false" : "true"}
                          onChange={(e) => update(u, { is_active: e.target.value === "true" })}
                          disabled={u.id === null}
                        >
                          <option value="true">Active</option>
                          <option value="false">Inactive</option>
                        </select>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            {/* Mobile Card List (< 768px) */}
            <div className="mobile-cards-container">
              {filtered.map((u) => (
                <div key={u.id} className="approval-card">
                  <div className="approval-card-header">
                    <div className="person-cell">
                      <div className="avatar">
                        {(u.name || "U").slice(0, 1).toUpperCase()}
                      </div>
                      <div>
                        <b>{u.name}</b>
                        <small>{u.email}</small>
                      </div>
                    </div>
                    <span className={`role-pill ${u.role}`}>
                      {u.role === "support"
                        ? "IT Support"
                        : u.role === "admin"
                        ? "Admin"
                        : "Employee"}
                    </span>
                  </div>

                  <div className="approval-card-details">
                    <div className="card-detail-item">
                      <span className="detail-label">Username:</span>
                      <code>@{u.username}</code>
                    </div>
                    <div className="card-detail-item">
                      <span className="detail-label">Department:</span>
                      <span>
                        {departments.find((d) => d.id === u.department_id)?.name || "—"}
                      </span>
                    </div>
                    <div className="card-detail-item">
                      <span className="detail-label">Phone:</span>
                      <span>{u.phone_number || "—"}</span>
                    </div>
                    <div className="card-detail-item">
                      <span className="detail-label">Access State:</span>
                      <select
                        className="access-select"
                        value={u.is_active === false ? "false" : "true"}
                        onChange={(e) => update(u, { is_active: e.target.value === "true" })}
                        disabled={u.id === null}
                      >
                        <option value="true">Active</option>
                        <option value="false">Inactive</option>
                      </select>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </>
        )}
      </section>

      {modal && (
        <div
          className="modal-backdrop"
          onMouseDown={(e) => e.target === e.currentTarget && setModal(false)}
        >
          <form className="modal-card modal-bottom-sheet" onSubmit={create}>
            <div className="modal-heading">
              <div>
                <div className="eyebrow">NEW ACCOUNT</div>
                <h2>Provision a user</h2>
              </div>
              <button
                type="button"
                className="icon-btn"
                onClick={() => setModal(false)}
              >
                <X size={19} />
              </button>
            </div>
            <div className="form-grid">
              <div className="form-field full">
                <label>Full name</label>
                <input
                  required
                  value={form.name}
                  onChange={(e) => setForm({ ...form, name: e.target.value })}
                />
              </div>
              <div className="form-field">
                <label>Email</label>
                <input
                  type="email"
                  required
                  value={form.email}
                  onChange={(e) => setForm({ ...form, email: e.target.value })}
                />
              </div>
              <div className="form-field">
                <label>Username</label>
                <input
                  required
                  minLength="3"
                  value={form.username}
                  onChange={(e) => setForm({ ...form, username: e.target.value })}
                />
              </div>
              <div className="form-field">
                <label>Initial password (12+ characters)</label>
                <input
                  type="password"
                  required
                  minLength="12"
                  value={form.password}
                  onChange={(e) => setForm({ ...form, password: e.target.value })}
                />
              </div>
              <div className="form-field">
                <label>Role</label>
                <select
                  value={form.role}
                  onChange={(e) => setForm({ ...form, role: e.target.value })}
                >
                  <option value="support">IT Support</option>
                  <option value="admin">Administrator</option>
                  <option value="employee">Employee</option>
                </select>
              </div>
              <div className="form-field">
                <label>Department</label>
                <select
                  value={form.department_id}
                  onChange={(e) => setForm({ ...form, department_id: e.target.value })}
                >
                  <option value="">No department</option>
                  {departments.map((d) => (
                    <option key={d.id} value={d.id}>
                      {d.name}
                    </option>
                  ))}
                </select>
              </div>
              <div className="form-field">
                <label>Phone number</label>
                <input
                  value={form.phone_number}
                  onChange={(e) => setForm({ ...form, phone_number: e.target.value })}
                />
              </div>
              <div className="form-field full">
                <label>Office location</label>
                <input
                  value={form.office_location}
                  onChange={(e) => setForm({ ...form, office_location: e.target.value })}
                />
              </div>
            </div>
            <div className="modal-actions">
              <button
                type="button"
                className="secondary-btn"
                onClick={() => setModal(false)}
              >
                Cancel
              </button>
              <button className="primary-btn">Create account</button>
            </div>
          </form>
        </div>
      )}
    </>
  );
}
