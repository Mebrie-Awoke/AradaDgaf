<<<<<<< HEAD
import { Filter, Search, UserRound, X, RefreshCw, ChevronLeft, ChevronRight } from "lucide-react";
=======
import {
  Filter,
  Search,
  UserRound,
  X,
  RefreshCw,
  ChevronLeft,
  ChevronRight,
  UserPlus,
} from "lucide-react";
>>>>>>> feature/e2e-registration-approval
import { useCallback, useEffect, useState } from "react";
import { apiRequest, unwrap } from "../api/client";
import { useAuth } from "../context/AuthContext";
import { StatusPill, formatDate } from "./DashboardPage";

export default function TicketsPage() {
  const { token } = useAuth();
  const [tickets, setTickets] = useState([]);
  const [staff, setStaff] = useState([]);
  const [meta, setMeta] = useState({ page: 1, pages: 1, count: 0 });
  const [page, setPage] = useState(1);
  const [status, setStatus] = useState("");
<<<<<<< HEAD
  const [query, setQuery] = useState("");
  const [search, setSearch] = useState("");
  const [busy, setBusy] = useState(true);
  const [error, setError] = useState("");
  const [selected, setSelected] = useState(null);
  const [assignee, setAssignee] = useState("");
  const [priority, setPriority] = useState("medium");
=======
  const [q, setQ] = useState("");
  const [search, setSearch] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");

  // Assignment Modal
  const [selected, setSelected] = useState(null);
  const [assignee, setAssignee] = useState("");
  const [priority, setPriority] = useState("medium");
  const [dueDate, setDueDate] = useState("");
  const [note, setNote] = useState("");
>>>>>>> feature/e2e-registration-approval
  const [saving, setSaving] = useState(false);
  const [notice, setNotice] = useState("");

  const load = useCallback(async () => {
    setBusy(true);
    setError("");
    try {
      const params = new URLSearchParams({ page: String(page), page_size: "25" });
      if (status) params.set("status", status);
      if (search) params.set("q", search);
<<<<<<< HEAD
      const [ticketResponse, userResponse] = await Promise.all([
        apiRequest(`/v1/tickets/?${params}`, { token }),
        apiRequest("/v1/users/?page_size=100", { token }),
      ]);
      setTickets(unwrap(ticketResponse) || []);
      setMeta(ticketResponse.meta || { page: 1, pages: 1, count: 0 });
      setStaff((unwrap(userResponse) || []).filter((user) =>
        user.role === "support" && user.is_active !== false
      ));
    } catch (err) {
      setError(err.message || "Unable to load service requests.");
=======

      const [t, u] = await Promise.all([
        apiRequest(`/v1/tickets/?${params}`, { token }),
        apiRequest("/v1/users/?page_size=100", { token }),
      ]);

      const ticketList = unwrap(t) || [];
      const userList = unwrap(u) || [];
      const activeStaff = userList.filter(
        (x) => ["support", "admin"].includes(x.role) && x.is_active !== false
      );

      // Compute technician workload
      const staffWithWorkload = activeStaff.map((person) => {
        const count = ticketList.filter(
          (tk) => tk.assigned_to === person.id && ["assigned", "in_progress"].includes(tk.status)
        ).length;
        return { ...person, activeWorkload: count };
      });

      setTickets(ticketList);
      setMeta(t.meta || { page: 1, pages: 1, count: 0 });
      setStaff(staffWithWorkload);
    } catch (e) {
      setError(e.message);
>>>>>>> feature/e2e-registration-approval
    } finally {
      setBusy(false);
    }
  }, [token, page, status, search]);

<<<<<<< HEAD
  useEffect(() => { load(); }, [load]);
=======
  useEffect(() => {
    load();
  }, [load]);
>>>>>>> feature/e2e-registration-approval

  function openAssign(ticket) {
    setSelected(ticket);
    setAssignee(ticket.assigned_to || "");
    setPriority(ticket.priority || "medium");
<<<<<<< HEAD
    setNotice("");
  }

  async function saveAssignment(event) {
    event.preventDefault();
=======
    setDueDate(ticket.due_date || "");
    setNote("");
    setNotice("");
  }

  async function saveAssignment(e) {
    e.preventDefault();
>>>>>>> feature/e2e-registration-approval
    if (!selected) return;
    setSaving(true);
    setError("");
    try {
<<<<<<< HEAD
      const patch = { assigned_to: assignee || null, priority };
      if (assignee && selected.status === "submitted") patch.status = "assigned";
      const result = unwrap(await apiRequest(`/v1/tickets/${selected.id}/`, {
        token, method: "PATCH", body: patch,
      }));
      setTickets((rows) => rows.map((ticket) => ticket.id === selected.id ? result : ticket));
      setSelected(null);
      setNotice(assignee
        ? `Ticket ${selected.number || selected.id} assigned. The selected IT person will receive an in-app notification.`
        : `Ticket ${selected.number || selected.id} updated.`);
      await load();
    } catch (err) {
      setError(err.message || "Unable to save the assignment.");
=======
      const patch = {
        assigned_to: assignee || null,
        priority,
      };
      if (assignee && selected.status === "submitted") patch.status = "assigned";
      if (dueDate) patch.due_date = dueDate;
      if (note.trim()) patch.note = note.trim();

      const result = unwrap(
        await apiRequest(`/v1/tickets/${selected.id}/`, {
          token,
          method: "PATCH",
          body: patch,
        })
      );
      setTickets((rows) => rows.map((t) => (t.id === selected.id ? result : t)));
      setSelected(null);
      setNotice(`Ticket ${selected.number || selected.id} updated successfully.`);
      load();
    } catch (e) {
      setError(e.message);
>>>>>>> feature/e2e-registration-approval
    } finally {
      setSaving(false);
    }
  }

<<<<<<< HEAD
  return <>
    <div className="page-heading">
      <div><div className="eyebrow">SERVICE DESK</div><h1>Ticket management</h1>
        <p>Review requests, assign work to registered IT support personnel, and manage priorities.</p></div>
      <button className="secondary-btn" onClick={load} disabled={busy}><RefreshCw size={16}/> Refresh</button>
    </div>
    {error && <div className="alert-error" role="alert">{error}</div>}
    {notice && <div className="alert-success" role="status">{notice}<button onClick={() => setNotice("")} aria-label="Dismiss"><X size={14}/></button></div>}

    <section className="panel ticket-panel">
      <div className="filter-bar">
        <div className="search-box"><Search size={17}/>
          <input value={query} onChange={(event) => setQuery(event.target.value)}
            onKeyDown={(event) => event.key === "Enter" && (setPage(1), setSearch(query.trim()))}
            placeholder="Search ticket number or request…"/>
          <button onClick={() => { setPage(1); setSearch(query.trim()); }}>Search</button>
        </div>
        <div className="filter-select"><Filter size={16}/>
          <select value={status} onChange={(event) => { setPage(1); setStatus(event.target.value); }}>
            <option value="">All statuses</option><option value="submitted">New</option>
            <option value="assigned">Assigned</option><option value="in_progress">In progress</option>
            <option value="resolved">Resolved</option><option value="closed">Closed</option>
          </select>
        </div>
      </div>
      {staff.length === 0 && !busy && <div className="alert-info">
        No active IT support personnel are registered yet. Add an IT Support account under People &amp; access before assigning requests.
      </div>}
      {busy ? <div className="empty-state">Loading service requests…</div>
        : tickets.length === 0 ? <div className="empty-state">No service requests match these filters.</div>
        : <div className="table-wrap"><table>
          <thead><tr><th>Ticket details</th><th>Department</th><th>Priority</th><th>Assigned to</th><th>Status</th><th>Created</th><th/></tr></thead>
          <tbody>{tickets.map((ticket) => <tr key={ticket.id}>
            <td><div className="ticket-cell"><b>{ticket.number || ticket.id}</b><span>{ticket.title}</span><small>{ticket.owner_name || "Employee"}</small></div></td>
            <td>{ticket.department_name || ticket.department || "—"}</td>
            <td><span className={`priority-pill ${ticket.priority || "medium"}`}>{ticket.priority || "medium"}</span></td>
            <td>{ticket.assigned_technician || staff.find((person) => person.id === ticket.assigned_to)?.name || "Unassigned"}</td>
            <td><StatusPill status={ticket.status}/></td>
            <td className="date-cell">{formatDate(ticket.created_at)}</td>
            <td><button className="table-action" onClick={() => openAssign(ticket)} title="Assign and manage"><UserRound size={16}/> Manage</button></td>
          </tr>)}</tbody>
        </table></div>}
      <div className="pagination"><span>{meta.count || 0} tickets · Page {meta.page || page} of {meta.pages || 1}</span>
        <div><button disabled={page <= 1 || busy} onClick={() => setPage((value) => value - 1)}><ChevronLeft size={16}/></button>
          <button disabled={page >= (meta.pages || 1) || busy} onClick={() => setPage((value) => value + 1)}><ChevronRight size={16}/></button></div>
      </div>
    </section>

    {selected && <div className="modal-backdrop" onMouseDown={(event) => event.target === event.currentTarget && setSelected(null)}>
      <form className="modal-card" onSubmit={saveAssignment}>
        <div className="modal-heading"><div><div className="eyebrow">TICKET {selected.number || selected.id}</div><h2>Assign &amp; manage</h2></div>
          <button type="button" className="icon-btn" onClick={() => setSelected(null)} aria-label="Close"><X size={19}/></button>
        </div>
        <div className="ticket-summary"><b>{selected.title}</b><p>{selected.description}</p></div>
        <label htmlFor="ticket-assignee">Assign to IT support personnel</label>
        <select id="ticket-assignee" className="field-select" value={assignee} onChange={(event) => setAssignee(event.target.value)}>
          <option value="">Unassigned</option>
          {staff.map((person) => <option value={person.id} key={person.id}>{person.name} · {person.email}</option>)}
        </select>
        {staff.length === 0 && <p className="muted">Register an active IT Support account before assigning this ticket.</p>}
        <label htmlFor="ticket-priority">Priority</label>
        <select id="ticket-priority" className="field-select" value={priority} onChange={(event) => setPriority(event.target.value)}>
          {["low", "medium", "high", "critical"].map((value) => <option value={value} key={value}>{value[0].toUpperCase() + value.slice(1)}</option>)}
        </select>
        <div className="modal-meta"><span>Current status</span><StatusPill status={selected.status}/></div>
        <div className="modal-actions"><button type="button" className="secondary-btn" onClick={() => setSelected(null)}>Cancel</button>
          <button className="primary-btn" disabled={saving}>{saving ? "Saving…" : "Save assignment"}</button></div>
      </form>
    </div>}
  </>;
=======
  return (
    <>
      <div className="page-heading">
        <div>
          <div className="eyebrow">SERVICE DESK</div>
          <h1>Ticket management</h1>
          <p>Review incoming requests, assign IT personnel, and manage priorities.</p>
        </div>
        <button className="secondary-btn" onClick={load}>
          <RefreshCw size={16} /> Refresh
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

      <section className="panel ticket-panel">
        <div className="filter-bar">
          <div className="search-box">
            <Search size={17} />
            <input
              value={q}
              onChange={(e) => setQ(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && (setPage(1), setSearch(q.trim()))}
              placeholder="Search ticket number or request…"
            />
            <button
              onClick={() => {
                setPage(1);
                setSearch(q.trim());
              }}
            >
              Search
            </button>
          </div>
          <div className="filter-select">
            <Filter size={16} />
            <select
              value={status}
              onChange={(e) => {
                setPage(1);
                setStatus(e.target.value);
              }}
            >
              <option value="">All statuses</option>
              <option value="submitted">New / Submitted</option>
              <option value="assigned">Assigned</option>
              <option value="in_progress">In progress</option>
              <option value="resolved">Resolved</option>
              <option value="closed">Closed</option>
            </select>
          </div>
        </div>

        {busy ? (
          <div className="empty-state">Loading tickets…</div>
        ) : tickets.length === 0 ? (
          <div className="empty-state">No tickets match these filters.</div>
        ) : (
          <>
            {/* Desktop Table */}
            <div className="table-wrap desktop-only-table">
              <table>
                <thead>
                  <tr>
                    <th>Ticket details</th>
                    <th>Department</th>
                    <th>Priority</th>
                    <th>Assigned to</th>
                    <th>Status</th>
                    <th>Created</th>
                    <th style={{ textAlign: "right" }} />
                  </tr>
                </thead>
                <tbody>
                  {tickets.map((t) => (
                    <tr key={t.id}>
                      <td>
                        <div className="ticket-cell">
                          <b>{t.number || t.id}</b>
                          <span>{t.title}</span>
                          <small>{t.owner_name || "Employee"}</small>
                        </div>
                      </td>
                      <td>{t.department_name || t.department || "—"}</td>
                      <td>
                        <span className={`priority-pill ${t.priority}`}>
                          {t.priority || "medium"}
                        </span>
                      </td>
                      <td>
                        {t.assigned_to_name ||
                          staff.find((s) => s.id === t.assigned_to)?.name || (
                            <span style={{ color: "var(--amber)", fontWeight: 500 }}>
                              Unassigned
                            </span>
                          )}
                      </td>
                      <td>
                        <StatusPill status={t.status} />
                      </td>
                      <td className="date-cell">{formatDate(t.created_at)}</td>
                      <td style={{ textAlign: "right" }}>
                        <button
                          className="table-action"
                          onClick={() => openAssign(t)}
                          title="Assign and manage"
                        >
                          <UserRound size={16} /> Manage
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            {/* Mobile Card List (< 768px) */}
            <div className="mobile-cards-container">
              {tickets.map((t) => (
                <div key={t.id} className="approval-card">
                  <div className="approval-card-header">
                    <div>
                      <b style={{ fontSize: 14, color: "var(--brand)" }}>
                        {t.number || t.id}
                      </b>
                      <h4 style={{ margin: "2px 0", fontSize: 14 }}>{t.title}</h4>
                      <small style={{ color: "var(--muted)" }}>
                        {t.owner_name || "Employee"} · {t.department_name || t.department || "—"}
                      </small>
                    </div>
                    <StatusPill status={t.status} />
                  </div>

                  <div className="approval-card-details">
                    <div className="card-detail-item">
                      <span className="detail-label">Priority:</span>
                      <span className={`priority-pill ${t.priority}`}>
                        {t.priority || "medium"}
                      </span>
                    </div>

                    <div className="card-detail-item">
                      <span className="detail-label">Assigned:</span>
                      <span>
                        {t.assigned_to_name ||
                          staff.find((s) => s.id === t.assigned_to)?.name ||
                          "Unassigned"}
                      </span>
                    </div>

                    {t.due_date && (
                      <div className="card-detail-item">
                        <span className="detail-label">Due Date:</span>
                        <span>{formatDate(t.due_date)}</span>
                      </div>
                    )}

                    <div className="card-detail-item">
                      <span className="detail-label">Created:</span>
                      <span>{formatDate(t.created_at)}</span>
                    </div>
                  </div>

                  <div className="approval-card-actions">
                    <button
                      className="primary-btn full-width"
                      onClick={() => openAssign(t)}
                    >
                      <UserRound size={16} /> Manage Assignment
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </>
        )}

        <div className="pagination">
          <span>
            {meta.count || 0} tickets · Page {meta.page || page} of {meta.pages || 1}
          </span>
          <div>
            <button disabled={page <= 1} onClick={() => setPage((p) => p - 1)}>
              <ChevronLeft size={16} />
            </button>
            <button
              disabled={page >= (meta.pages || 1)}
              onClick={() => setPage((p) => p + 1)}
            >
              <ChevronRight size={16} />
            </button>
          </div>
        </div>
      </section>

      {/* Assignment Modal / Bottom Sheet */}
      {selected && (
        <div
          className="modal-backdrop"
          onMouseDown={(e) => e.target === e.currentTarget && setSelected(null)}
        >
          <form className="modal-card modal-bottom-sheet" onSubmit={saveAssignment}>
            <div className="modal-heading">
              <div>
                <div className="eyebrow">TICKET {selected.number || selected.id}</div>
                <h2>Assign & manage</h2>
              </div>
              <button
                type="button"
                className="icon-btn"
                onClick={() => setSelected(null)}
              >
                <X size={19} />
              </button>
            </div>

            <div className="ticket-summary">
              <b>{selected.title}</b>
              <p>{selected.description}</p>
            </div>

            <div style={{ marginTop: 14 }}>
              <label style={{ display: "block", marginBottom: 6, fontWeight: 600 }}>
                Assign to IT personnel
              </label>
              <select
                className="field-select full-width"
                value={assignee}
                onChange={(e) => setAssignee(e.target.value)}
              >
                <option value="">Unassigned</option>
                {staff.map((s) => (
                  <option value={s.id} key={s.id}>
                    {s.name} · {s.role === "admin" ? "Admin" : "IT Support"} (
                    {s.activeWorkload !== undefined ? `${s.activeWorkload} active` : ""})
                  </option>
                ))}
              </select>
            </div>

            <div style={{ marginTop: 14 }}>
              <label style={{ display: "block", marginBottom: 6, fontWeight: 600 }}>
                Priority
              </label>
              <select
                className="field-select full-width"
                value={priority}
                onChange={(e) => setPriority(e.target.value)}
              >
                {["low", "medium", "high", "critical"].map((p) => (
                  <option value={p} key={p}>
                    {p[0].toUpperCase() + p.slice(1)}
                  </option>
                ))}
              </select>
            </div>

            <div style={{ marginTop: 14 }}>
              <label style={{ display: "block", marginBottom: 6, fontWeight: 600 }}>
                Target Due Date (Optional)
              </label>
              <input
                type="date"
                className="field-input full-width"
                value={dueDate}
                onChange={(e) => setDueDate(e.target.value)}
              />
            </div>

            <div style={{ marginTop: 14 }}>
              <label style={{ display: "block", marginBottom: 6, fontWeight: 600 }}>
                Assignment Note (Optional)
              </label>
              <textarea
                className="field-textarea full-width"
                rows={3}
                value={note}
                onChange={(e) => setNote(e.target.value)}
                placeholder="Note for the technician..."
              />
            </div>

            <div className="modal-meta" style={{ marginTop: 16 }}>
              <span>Current status</span>
              <StatusPill status={selected.status} />
            </div>

            <div className="modal-actions" style={{ marginTop: 20 }}>
              <button
                type="button"
                className="secondary-btn"
                onClick={() => setSelected(null)}
              >
                Cancel
              </button>
              <button className="primary-btn" disabled={saving}>
                {saving ? "Saving…" : "Save assignment"}
              </button>
            </div>
          </form>
        </div>
      )}
    </>
  );
>>>>>>> feature/e2e-registration-approval
}
