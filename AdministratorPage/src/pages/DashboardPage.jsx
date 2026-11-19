import { Activity, ClipboardCheck, ClipboardList, Clock3, RefreshCw, Users } from "lucide-react";
import { useEffect, useState } from "react";
import { apiRequest, unwrap } from "../api/client";
import { useAuth } from "../context/AuthContext";

const STATUSES = [
  { key: "submitted", label: "New requests", tone: "blue" },
  { key: "assigned", label: "Assigned", tone: "violet" },
  { key: "in_progress", label: "In progress", tone: "amber" },
  { key: "resolved", label: "Resolved", tone: "green" },
  { key: "closed", label: "Closed", tone: "slate" },
];

export default function DashboardPage({ go }) {
  const { token } = useAuth();
  const [stats, setStats] = useState(null);
  const [tickets, setTickets] = useState([]);
  const [users, setUsers] = useState([]);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);
  const [refreshKey, setRefreshKey] = useState(0);

  useEffect(() => {
    let active = true;
    async function load() {
      setLoading(true);
      setError("");
      try {
        const [dashboard, ticketResponse, userResponse] = await Promise.all([
          apiRequest("/v1/dashboard/", { token }),
          apiRequest("/v1/tickets/?page_size=8", { token }),
          apiRequest("/v1/users/?page_size=100", { token }),
        ]);
        if (!active) return;
        setStats(unwrap(dashboard));
        setTickets(unwrap(ticketResponse) || []);
        setUsers(unwrap(userResponse) || []);
      } catch (err) {
        if (active) setError(err.message || "Unable to load dashboard information.");
      } finally {
        if (active) setLoading(false);
      }
    }
    load();
    return () => { active = false; };
  }, [token, refreshKey]);

  const total = stats?.total_tickets ?? 0;
  const open = (stats?.by_status?.submitted || 0)
    + (stats?.by_status?.assigned || 0)
    + (stats?.by_status?.in_progress || 0);
  const personnel = users.filter((user) =>
    ["support", "admin"].includes(user.role) && user.is_active !== false
  ).length;
  const displayValue = (value) => stats ? value : "—";

  return <>
    <div className="page-heading">
      <div>
        <div className="eyebrow">OPERATIONS OVERVIEW</div>
        <h1>Service overview</h1>
        <p>Monitor service requests and administrator-managed IT operations.</p>
      </div>
      <div className="heading-actions">
        <button className="secondary-btn" onClick={() => setRefreshKey((key) => key + 1)} disabled={loading}>
          <RefreshCw size={16}/> Refresh
        </button>
        <button className="primary-btn" onClick={() => go("tickets")}>
          <ClipboardList size={16}/> Manage tickets
        </button>
      </div>
    </div>

    {error && <div className="alert-error" role="alert">{error}</div>}

    <div className="stat-grid">
      <Stat label="Total tickets" value={displayValue(total)} detail="Recorded service requests" icon={ClipboardList} color="blue"/>
      <Stat label="Open workload" value={displayValue(open)} detail="Awaiting or being handled" icon={Clock3} color="amber"/>
      <Stat label="Resolved tickets" value={displayValue(stats?.by_status?.resolved || 0)} detail="Successfully completed" icon={ClipboardCheck} color="green"/>
      <Stat label="Active IT personnel" value={loading && !stats ? "—" : personnel} detail="Support and administrator accounts" icon={Users} color="violet"/>
    </div>

    <div className="dashboard-grid">
      <section className="panel status-panel">
        <div className="panel-heading">
          <div><h3>Ticket status</h3><p>Current distribution of service requests</p></div>
          {stats && <span className="live-tag"><i/> BACKEND DATA</span>}
        </div>
        {loading && !stats ? <div className="empty-state">Loading ticket statistics…</div> : stats ? (
          <div className="status-list">
            {STATUSES.map((status) => {
              const count = stats.by_status?.[status.key] || 0;
              const percentage = total ? Math.round((count / total) * 100) : 0;
              return <div className="status-row" key={status.key}>
                <div className="status-label">
                  <span className={`status-dot ${status.tone}`}/>
                  <b>{status.label}</b>
                  <strong>{count}</strong>
                </div>
                <div className="progress-track">
                  <div className={`progress-fill ${status.tone}`} style={{ width: `${percentage}%` }}/>
                </div>
              </div>;
            })}
          </div>
        ) : <div className="empty-state">Ticket statistics are unavailable.</div>}
      </section>

      <section className="panel workload-panel">
        <div className="panel-heading"><div><h3>Priority overview</h3><p>Requests grouped by urgency</p></div></div>
        {loading && !stats ? <div className="empty-state">Loading priority information…</div> : stats ? (
          <div className="priority-cards">
            {["critical", "high", "medium", "low"].map((priority) =>
              <div className="priority-card" key={priority}>
                <span className={`priority-dot p-${priority}`}/>
                <span>{priority}</span>
                <b>{stats.by_priority?.[priority] || 0}</b>
              </div>
            )}
          </div>
        ) : <div className="empty-state">Priority information is unavailable.</div>}
        <div className="workload-note"><Activity size={17}/><span>Review critical and high-priority requests first.</span></div>
      </section>
    </div>

    <section className="panel recent-panel">
      <div className="panel-heading">
        <div><h3>Recently updated tickets</h3><p>Latest service requests returned by the system</p></div>
        <button className="text-btn" onClick={() => go("tickets")}>View all <ClipboardList size={15}/></button>
      </div>
      {loading ? <div className="empty-state">Loading recent tickets…</div>
        : tickets.length === 0 ? <div className="empty-state">No service requests have been submitted yet.</div>
        : <div className="table-wrap"><table>
          <thead><tr><th>Ticket</th><th>Request</th><th>Priority</th><th>Status</th><th>Updated</th></tr></thead>
          <tbody>{tickets.map((ticket) => <tr key={ticket.id}>
            <td className="ticket-number">{ticket.number || ticket.id}</td>
            <td><b>{ticket.title}</b><small>{ticket.owner_name || "Requester"}</small></td>
            <td><span className={`priority-pill ${ticket.priority || "medium"}`}>{ticket.priority || "—"}</span></td>
            <td><StatusPill status={ticket.status}/></td>
            <td className="date-cell">{formatDate(ticket.updated_at || ticket.created_at)}</td>
          </tr>)}</tbody>
        </table></div>}
    </section>
  </>;
}

function Stat({ label, value, detail, icon: Icon, color }) {
  return <div className="stat-card">
    <div className={`stat-icon ${color}`}><Icon size={19}/></div>
    <div className="stat-label">{label}</div>
    <div className="stat-value">{value}</div>
    <div className="stat-detail">{detail}</div>
  </div>;
}

export function StatusPill({ status }) {
  const value = status || "submitted";
  return <span className={`status-pill ${value}`}>{value.replaceAll("_", " ")}</span>;
}

export function formatDate(value) {
  if (!value) return "—";
  const date = new Date(value);
  return Number.isNaN(date.getTime())
    ? "—"
    : date.toLocaleDateString(undefined, { month: "short", day: "numeric", year: "numeric" });
}
