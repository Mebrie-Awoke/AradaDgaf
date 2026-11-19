import { Search, UserPlus, Users, X, Shield, UserCog, RefreshCw, Pencil, Trash2 } from "lucide-react";
import { useEffect, useState } from "react";
import { apiRequest, unwrap } from "../api/client";
import { useAuth } from "../context/AuthContext";

const blank = {
<<<<<<< HEAD
  name: "", email: "", username: "", password: "", role: "support",
  department_id: "", phone_number: "", office_location: "",
};

export default function UsersPage() {
  const { token, user: currentUser } = useAuth();
=======
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
>>>>>>> feature/e2e-registration-approval
  const [users, setUsers] = useState([]);
  const [departments, setDepartments] = useState([]);
  const [query, setQuery] = useState("");
  const [modal, setModal] = useState(false);
<<<<<<< HEAD
  const [editingUser, setEditingUser] = useState(null);
  const [form, setForm] = useState(blank);
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");
  const [busy, setBusy] = useState(true);
  const [saving, setSaving] = useState(false);

  async function load() {
    setBusy(true);
    setError("");
    try {
      const [userResponse, departmentResponse] = await Promise.all([
        apiRequest("/v1/users/?page_size=100", { token }),
        apiRequest("/v1/departments/?page_size=100", { token }),
      ]);
      setUsers(unwrap(userResponse) || []);
      setDepartments(unwrap(departmentResponse) || []);
    } catch (err) {
      setError(err.message || "Unable to load directory information.");
=======
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
>>>>>>> feature/e2e-registration-approval
    } finally {
      setBusy(false);
    }
  }

<<<<<<< HEAD
  useEffect(() => { load(); }, [token]);

  async function create(event) {
    event.preventDefault();
    setError("");
    setNotice("");
    setSaving(true);
    try {
      if (editingUser) {
        const { password, email, ...updates } = form;
        await apiRequest("/v1/users/" + editingUser.id + "/", { token, method: "PATCH", body: updates });
        setNotice("Account details updated.");
      } else {
        await apiRequest("/v1/users/", { token, method: "POST", body: form });
        setNotice("Account created. Share the initial password securely with the account owner.");
      }
      setModal(false);
      setEditingUser(null);
      setForm(blank);
      await load();
    } catch (err) {
      setError(err.message || "Unable to create this account.");
    } finally {
      setSaving(false);
=======
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
>>>>>>> feature/e2e-registration-approval
    }
  }

  async function update(user, patch) {
<<<<<<< HEAD
    setError("");
    try {
      await apiRequest(`/v1/users/${user.id}/`, { token, method: "PATCH", body: patch });
      setNotice("User account updated.");
      await load();
    } catch (err) {
      setError(err.message || "Unable to update this account.");
    }
  }

  function edit(user) {
    setEditingUser(user);
    setForm({
      ...blank, name: user.name || "", email: user.email || "",
      username: user.username || "", role: user.role || "support",
      department_id: user.department_id || "", phone_number: user.phone_number || "",
      office_location: user.office_location || "",
    });
    setError("");
    setModal(true);
  }

  async function remove(user) {
    if (!window.confirm("Delete " + (user.name || user.email) + "? Their login and notifications will be removed; ticket history will be preserved.")) return;
    setError("");
    try {
      await apiRequest("/v1/users/" + user.id + "/", { token, method: "DELETE" });
      setNotice("Account deleted. Existing ticket history was preserved.");
      await load();
    } catch (err) {
      setError(err.message || "Unable to delete this account.");
    }
  }

  const personnel = users.filter((user) => ["admin", "support"].includes(user.role));
  const filtered = personnel.filter((user) =>
    [user.name, user.email, user.username, user.role]
      .join(" ").toLowerCase().includes(query.trim().toLowerCase())
  );

  return <>
    <div className="page-heading">
      <div><div className="eyebrow">PERSONNEL DIRECTORY</div><h1>People & access</h1>
        <p>Manage administrator accounts and registered IT support personnel.</p></div>
      <div className="heading-actions">
        <button className="secondary-btn" onClick={load} disabled={busy}><RefreshCw size={16}/> Refresh</button>
        <button className="primary-btn" onClick={() => { setEditingUser(null); setForm(blank); setModal(true); setError(""); }}>
          <UserPlus size={17}/> Add account
        </button>
      </div>
    </div>

    {error && <div className="alert-error" role="alert">{error}</div>}
    {notice && <div className="alert-success" role="status">{notice}<button onClick={() => setNotice("")} aria-label="Dismiss notification"><X size={14}/></button></div>}

    <div className="people-stats">
      <div className="mini-stat"><Users size={18}/><span>IT personnel</span><b>{personnel.length}</b></div>
      <div className="mini-stat"><UserCog size={18}/><span>Active IT support</span><b>{users.filter((user) => user.role === "support" && user.is_active !== false).length}</b></div>
      <div className="mini-stat"><Shield size={18}/><span>Administrators</span><b>{users.filter((user) => user.role === "admin").length}</b></div>
    </div>

    <section className="panel">
      <div className="list-toolbar">
        <div className="search-box"><Search size={17}/><input value={query}
          onChange={(event) => setQuery(event.target.value)} placeholder="Search name, email or role…"
          aria-label="Search accounts"/></div>
      </div>
      {busy ? <div className="empty-state">Loading account directory…</div>
        : filtered.length === 0 ? <div className="empty-state">
          {personnel.length === 0 ? "No IT personnel are registered yet. The administrator account will appear here." : "No personnel match your search."}
        </div>
        : <div className="table-wrap"><table>
          <thead><tr><th>Person</th><th>Role</th><th>Department</th><th>Contact</th><th>Access</th><th>Actions</th></tr></thead>
          <tbody>{filtered.map((user) => <tr key={user.id}>
            <td><div className="person-cell">
              <div className="avatar small">{(user.name || "U").slice(0, 1).toUpperCase()}</div>
              <div><b>{user.name || "Unnamed account"}</b><small>{user.email}</small></div>
            </div></td>
            <td><span className={`role-pill ${user.role}`}>
              {user.role === "support" ? "IT Support" : "Administrator"}
            </span></td>
            <td>{departments.find((department) => department.id === user.department_id)?.name || "—"}</td>
            <td>{user.phone_number || "—"}</td>
            <td><select className="access-select" aria-label={`Access status for ${user.name || user.email}`}
              value={user.is_active === false ? "false" : "true"}
              onChange={(event) => update(user, { is_active: event.target.value === "true" })}
              disabled={user.id === undefined || user.id === null}>
              <option value="true">Active</option><option value="false">Inactive</option>
            </select></td>
            <td><div className="heading-actions">
              <button type="button" className="secondary-btn" onClick={() => edit(user)}><Pencil size={14}/> Edit</button>
              <button type="button" className="secondary-btn" onClick={() => remove(user)}
                disabled={user.id === currentUser?.id} aria-label={"Delete " + (user.name || user.email)}>
                <Trash2 size={14}/> Delete
              </button>
            </div></td>
          </tr>)}</tbody>
        </table></div>}
    </section>

    {modal && <div className="modal-backdrop" onMouseDown={(event) => event.target === event.currentTarget && setModal(false)}>
      <form className="modal-card" onSubmit={create}>
        <div className="modal-heading"><div><div className="eyebrow">{editingUser ? "EDIT ACCOUNT" : "NEW ACCOUNT"}</div><h2>{editingUser ? "Update account" : "Provision a user"}</h2></div>
          <button type="button" className="icon-btn" onClick={() => setModal(false)} aria-label="Close form"><X size={19}/></button>
        </div>
        <div className="form-grid">
          <div className="form-field full"><label htmlFor="user-name">Full name</label><input id="user-name" required value={form.name} onChange={(event) => setForm({ ...form, name: event.target.value })}/></div>
          <div className="form-field"><label htmlFor="user-email">Email</label><input id="user-email" type="email" required disabled={Boolean(editingUser)} value={form.email} onChange={(event) => setForm({ ...form, email: event.target.value })}/></div>
          <div className="form-field"><label htmlFor="user-username">Username</label><input id="user-username" required minLength="3" value={form.username} onChange={(event) => setForm({ ...form, username: event.target.value })}/></div>
          {!editingUser && <div className="form-field"><label htmlFor="user-password">Initial password (12+ characters)</label><input id="user-password" type="password" required minLength="12" autoComplete="new-password" value={form.password} onChange={(event) => setForm({ ...form, password: event.target.value })}/></div>}
          <div className="form-field"><label htmlFor="user-role">Role</label><select id="user-role" value={form.role} onChange={(event) => setForm({ ...form, role: event.target.value })}>
            <option value="support">IT Support</option><option value="admin">Administrator</option>
          </select></div>
          <div className="form-field"><label htmlFor="user-department">Department</label><select id="user-department" value={form.department_id} onChange={(event) => setForm({ ...form, department_id: event.target.value })}>
            <option value="">No department</option>{departments.map((department) => <option key={department.id} value={department.id}>{department.name}</option>)}
          </select></div>
          <div className="form-field"><label htmlFor="user-phone">Phone number</label><input id="user-phone" value={form.phone_number} onChange={(event) => setForm({ ...form, phone_number: event.target.value })}/></div>
          <div className="form-field full"><label htmlFor="user-office">Office location</label><input id="user-office" value={form.office_location} onChange={(event) => setForm({ ...form, office_location: event.target.value })}/></div>
        </div>
        <div className="modal-actions">
          <button type="button" className="secondary-btn" onClick={() => { setModal(false); setEditingUser(null); }}>Cancel</button>
          <button className="primary-btn" disabled={saving}>{saving ? "Saving…" : editingUser ? "Save changes" : "Create account"}</button>
        </div>
      </form>
    </div>}
  </>;
=======
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
>>>>>>> feature/e2e-registration-approval
}
