import { Filter, Search, UserRound, X, RefreshCw, ChevronLeft, ChevronRight } from "lucide-react";
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
  const [query, setQuery] = useState("");
  const [search, setSearch] = useState("");
  const [busy, setBusy] = useState(true);
  const [error, setError] = useState("");
  const [selected, setSelected] = useState(null);
  const [assignee, setAssignee] = useState("");
  const [priority, setPriority] = useState("medium");
  const [saving, setSaving] = useState(false);
  const [notice, setNotice] = useState("");

  const load = useCallback(async () => {
    setBusy(true);
    setError("");
    try {
      const params = new URLSearchParams({ page: String(page), page_size: "25" });
      if (status) params.set("status", status);
      if (search) params.set("q", search);
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
    } finally {
      setBusy(false);
    }
  }, [token, page, status, search]);

  useEffect(() => { load(); }, [load]);

  function openAssign(ticket) {
    setSelected(ticket);
    setAssignee(ticket.assigned_to || "");
    setPriority(ticket.priority || "medium");
    setNotice("");
  }

  async function saveAssignment(event) {
    event.preventDefault();
    if (!selected) return;
    setSaving(true);
    setError("");
    try {
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
    } finally {
      setSaving(false);
    }
  }

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
}
