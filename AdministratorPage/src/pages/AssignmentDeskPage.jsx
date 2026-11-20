import { useState, useEffect, useCallback, useMemo } from "react";
import {
  Activity,
  AlertCircle,
  ArrowRight,
  CalendarDays,
  CheckCircle2,
  Clock3,
  ClipboardList,
  Filter,
  Headset,
  RefreshCw,
  Search,
  Sparkles,
  UserRound,
  Users,
  X,
  Zap,
} from "lucide-react";
import { apiRequest, unwrap } from "../api/client";
import { useAuth } from "../context/AuthContext";
import { formatDate } from "./DashboardPage";
import "./AssignmentDeskPage.css";

const ACTIONABLE_STATUSES = ["submitted", "assigned", "in_progress"];

const priorityMeta = {
  critical: { label: "Critical", className: "critical" },
  high: { label: "High", className: "high" },
  medium: { label: "Medium", className: "medium" },
  low: { label: "Low", className: "low" },
};

const statusMeta = {
  submitted: { label: "Submitted", className: "submitted" },
  assigned: { label: "Assigned", className: "assigned" },
  in_progress: { label: "In progress", className: "in-progress" },
  resolved: { label: "Resolved", className: "resolved" },
  rejected: { label: "Rejected", className: "rejected" },
  closed: { label: "Closed", className: "closed" },
};

function getTicketNumber(ticket) {
  return String(ticket?.number ?? ticket?.id ?? "—");
}

function getPriority(priority) {
  return priorityMeta[String(priority || "medium").toLowerCase()] || priorityMeta.medium;
}

function getStatus(status) {
  const key = String(status || "submitted").toLowerCase();
  return statusMeta[key] || { label: key.replaceAll("_", " "), className: "unknown" };
}

function getInitials(name = "Technician") {
  return String(name)
    .trim()
    .split(/\s+/)
    .slice(0, 2)
    .map((part) => part[0] || "")
    .join("")
    .toUpperCase();
}

function formatSafeDate(value) {
  if (!value) return "Not set";
  try {
    return formatDate(value);
  } catch {
    return "Not set";
  }
}

function TicketPriority({ priority }) {
  const meta = getPriority(priority);
  return <span className={`ad-priority ad-priority--${meta.className}`}>{meta.label}</span>;
}

function TicketStatus({ status }) {
  const meta = getStatus(status);
  return <span className={`ad-status ad-status--${meta.className}`}><i />{meta.label}</span>;
}

function WorkloadLevel({ count }) {
  const level = count >= 4 ? "busy" : count >= 2 ? "steady" : "light";
  const label = count >= 4 ? "Busy" : count >= 2 ? "Steady" : "Available";
  return <span className={`ad-workload ad-workload--${level}`}>{label} · {count} active</span>;
}

export default function AssignmentDeskPage() {
  const { token } = useAuth();
  const [tickets, setTickets] = useState([]);
  const [technicians, setTechnicians] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");

  // Queue filters
  const [statusFilter, setStatusFilter] = useState("actionable");
  const [priorityFilter, setPriorityFilter] = useState("all");
  const [searchQuery, setSearchQuery] = useState("");

  // Assignment editor
  const [selectedTicket, setSelectedTicket] = useState(null);
  const [assigneeId, setAssigneeId] = useState("");
  const [priority, setPriority] = useState("medium");
  const [dueDate, setDueDate] = useState("");
  const [note, setNote] = useState("");
  const [saving, setSaving] = useState(false);

  const loadData = useCallback(async () => {
    setLoading(true);
    setError("");

    try {
      const [ticketsRes, usersRes] = await Promise.all([
        apiRequest("/v1/tickets/?page_size=100", { token }),
        apiRequest("/v1/users/?page_size=100", { token }),
      ]);

      const allTickets = unwrap(ticketsRes) || [];
      const allUsers = unwrap(usersRes) || [];

      const techList = allUsers.filter(
        (user) => ["support", "admin"].includes(user.role) && user.is_active !== false
      );

      const techsWithWorkload = techList.map((tech) => {
        const activeWorkload = allTickets.filter(
          (ticket) =>
            String(ticket.assigned_to ?? "") === String(tech.id) &&
            ["assigned", "in_progress"].includes(ticket.status)
        ).length;
        const resolvedCount = allTickets.filter(
          (ticket) =>
            String(ticket.assigned_to ?? "") === String(tech.id) &&
            ticket.status === "resolved"
        ).length;

        return { ...tech, activeWorkload, resolvedCount };
      });

      // Lightest workloads appear first to make balanced dispatch easier.
      techsWithWorkload.sort((a, b) => a.activeWorkload - b.activeWorkload);
      setTickets(Array.isArray(allTickets) ? allTickets : []);
      setTechnicians(techsWithWorkload);
    } catch (loadError) {
      setError(loadError.message || "Failed to load assignment data.");
    } finally {
      setLoading(false);
    }
  }, [token]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  function openAssignModal(ticket) {
    setSelectedTicket(ticket);
    setAssigneeId(ticket.assigned_to == null ? "" : String(ticket.assigned_to));
    setPriority(ticket.priority || "medium");
    setDueDate(ticket.due_date ? String(ticket.due_date).slice(0, 10) : "");
    setNote("");
  }

  function closeAssignModal() {
    if (saving) return;
    setSelectedTicket(null);
  }

  async function handleSaveAssignment(event) {
    event.preventDefault();
    if (!selectedTicket || !assigneeId) return;

    setSaving(true);
    setError("");

    try {
      const patch = {
        assigned_to: assigneeId,
        priority,
      };

      if (selectedTicket.status === "submitted") {
        patch.status = "assigned";
      }
      if (dueDate) patch.due_date = dueDate;
      if (note.trim()) patch.note = note.trim();

      await apiRequest(`/v1/tickets/${selectedTicket.id}/`, {
        token,
        method: "PATCH",
        body: patch,
      });

      const assignedTechnician = technicians.find(
        (tech) => String(tech.id) === String(assigneeId)
      );
      setNotice(
        `Ticket ${getTicketNumber(selectedTicket)} dispatched to ${assignedTechnician?.name || "the selected technician"}.`
      );
      setSelectedTicket(null);
      await loadData();
    } catch (saveError) {
      setError(saveError.message || "Assignment failed. Please try again.");
    } finally {
      setSaving(false);
    }
  }

  const metrics = useMemo(() => {
    const actionable = tickets.filter((ticket) => ACTIONABLE_STATUSES.includes(ticket.status));
    const unassigned = tickets.filter(
      (ticket) => !ticket.assigned_to && ticket.status === "submitted"
    );
    const inProgress = tickets.filter((ticket) => ticket.status === "in_progress");
    const critical = actionable.filter((ticket) => ticket.priority === "critical");

    return {
      actionable: actionable.length,
      unassigned: unassigned.length,
      inProgress: inProgress.length,
      critical: critical.length,
    };
  }, [tickets]);

  const filteredTickets = useMemo(() => {
    const query = searchQuery.trim().toLowerCase();

    return tickets.filter((ticket) => {
      if (statusFilter === "actionable") {
        if (!ACTIONABLE_STATUSES.includes(ticket.status)) return false;
      } else if (statusFilter !== "all" && ticket.status !== statusFilter) {
        return false;
      }

      if (priorityFilter !== "all" && ticket.priority !== priorityFilter) return false;

      if (query) {
        const searchable = [
          getTicketNumber(ticket),
          ticket.title,
          ticket.description,
          ticket.owner_name,
          ticket.department_name,
          ticket.department,
        ]
          .map((value) => String(value ?? "").toLowerCase())
          .join(" ");
        if (!searchable.includes(query)) return false;
      }

      return true;
    });
  }, [tickets, statusFilter, priorityFilter, searchQuery]);

  const recommendedTechnician = technicians[0];
  const selectedAssignee = technicians.find(
    (tech) => String(tech.id) === String(assigneeId)
  );

  return (
    <main className="assignment-desk">
      <header className="ad-hero">
        <div className="ad-hero-orb ad-hero-orb--one" />
        <div className="ad-hero-orb ad-hero-orb--two" />
        <div className="ad-hero-content">
          <div className="ad-kicker"><span className="ad-kicker-dot" /> ARADA DIGAF <span className="ad-kicker-divider">/</span> SERVICE OPERATIONS</div>
          <h1>Assignment <em>Desk</em></h1>
          <p>Your command center for smarter IT support dispatch. Keep requests moving and workloads balanced.</p>
          <div className="ad-hero-meta">
            <span><Activity size={14} /> Live operations view</span>
            <span><Users size={14} /> {technicians.length} support personnel</span>
          </div>
        </div>
        <div className="ad-hero-actions">
          <span className="ad-live-indicator"><i /> LIVE QUEUE</span>
          <button className="ad-refresh-btn" onClick={loadData} disabled={loading} type="button">
            <RefreshCw size={16} className={loading ? "ad-spin" : ""} />
            {loading ? "Refreshing" : "Refresh data"}
          </button>
        </div>
        <div className="ad-hero-watermark"><ClipboardList size={150} strokeWidth={0.8} /></div>
      </header>

      {error && (
        <div className="ad-alert ad-alert--error" role="alert">
          <AlertCircle size={18} />
          <span>{error}</span>
          <button type="button" onClick={() => setError("")} aria-label="Dismiss error"><X size={16} /></button>
        </div>
      )}
      {notice && (
        <div className="ad-alert ad-alert--success" role="status">
          <CheckCircle2 size={18} />
          <span>{notice}</span>
          <button type="button" onClick={() => setNotice("")} aria-label="Dismiss message"><X size={16} /></button>
        </div>
      )}

      <section className="ad-metrics" aria-label="Assignment overview">
        <article className="ad-metric-card ad-metric-card--primary">
          <div className="ad-metric-top"><span>Active queue</span><span className="ad-metric-icon"><ClipboardList size={18} /></span></div>
          <div className="ad-metric-value">{loading ? "—" : metrics.actionable}</div>
          <div className="ad-metric-foot"><span className="ad-metric-dot" /> Tickets needing attention</div>
        </article>
        <article className="ad-metric-card">
          <div className="ad-metric-top"><span>Awaiting assignment</span><span className="ad-metric-icon ad-metric-icon--amber"><Clock3 size={18} /></span></div>
          <div className="ad-metric-value">{loading ? "—" : metrics.unassigned}</div>
          <div className="ad-metric-foot">New requests without an owner</div>
        </article>
        <article className="ad-metric-card">
          <div className="ad-metric-top"><span>In progress</span><span className="ad-metric-icon ad-metric-icon--blue"><Zap size={18} /></span></div>
          <div className="ad-metric-value">{loading ? "—" : metrics.inProgress}</div>
          <div className="ad-metric-foot">Currently being handled</div>
        </article>
        <article className="ad-metric-card ad-metric-card--critical">
          <div className="ad-metric-top"><span>Critical priority</span><span className="ad-metric-icon ad-metric-icon--red"><AlertCircle size={18} /></span></div>
          <div className="ad-metric-value">{loading ? "—" : metrics.critical}</div>
          <div className="ad-metric-foot">Needs urgent attention</div>
        </article>
      </section>

      <section className="ad-section ad-team-section">
        <div className="ad-section-heading">
          <div>
            <div className="ad-section-eyebrow">THE PEOPLE BEHIND THE FIXES</div>
            <h2>Technician workload</h2>
            <p>Choose the right person, not just the next available person.</p>
          </div>
          <div className="ad-team-count"><Users size={16} /><strong>{technicians.length}</strong> active personnel</div>
        </div>

        {loading && technicians.length === 0 ? (
          <div className="ad-tech-grid">
            {[1, 2, 3].map((item) => <div className="ad-tech-skeleton" key={item} />)}
          </div>
        ) : technicians.length === 0 ? (
          <div className="ad-empty ad-empty--compact"><Headset size={25} /><strong>No active technicians found</strong><span>Active IT support and admin accounts will appear here.</span></div>
        ) : (
          <div className="ad-tech-grid">
            {technicians.map((tech, index) => {
              const maxWorkload = Math.max(...technicians.map((person) => person.activeWorkload), 1);
              const loadWidth = tech.activeWorkload === 0 ? 4 : Math.max(10, (tech.activeWorkload / maxWorkload) * 100);
              return (
                <article className={`ad-tech-card ${index === 0 ? "ad-tech-card--recommended" : ""}`} key={tech.id}>
                  <div className="ad-tech-card-top">
                    <div className="ad-avatar">{getInitials(tech.name)}</div>
                    <div className="ad-tech-identity">
                      <strong title={tech.name}>{tech.name || "Unnamed technician"}</strong>
                      <span>{tech.role === "admin" ? "Admin / Technician" : "IT Support"}</span>
                    </div>
                    {index === 0 && <span className="ad-recommended-tag"><Sparkles size={11} /> Lightest load</span>}
                  </div>
                  <div className="ad-tech-load-row"><WorkloadLevel count={tech.activeWorkload} /><span className="ad-tech-resolved"><CheckCircle2 size={13} /> {tech.resolvedCount} resolved</span></div>
                  <div className="ad-load-track"><span style={{ width: `${loadWidth}%` }} /></div>
                  {tech.specialties?.length > 0 ? (
                    <div className="ad-specialties">
                      {tech.specialties.slice(0, 3).map((specialty) => <span key={specialty}>{specialty}</span>)}
                      {tech.specialties.length > 3 && <span>+{tech.specialties.length - 3}</span>}
                    </div>
                  ) : (
                    <div className="ad-specialties ad-specialties--empty"><span>General IT support</span></div>
                  )}
                </article>
              );
            })}
          </div>
        )}
      </section>

      <section className="ad-section ad-queue-section">
        <div className="ad-section-heading ad-queue-heading">
          <div>
            <div className="ad-section-eyebrow">FROM REQUEST TO RESOLUTION</div>
            <h2>Dispatch queue <span className="ad-queue-total">{filteredTickets.length}</span></h2>
            <p>Review each request and send it to the right technician.</p>
          </div>
          <div className="ad-queue-note"><span className="ad-queue-note-icon"><Zap size={15} /></span><span><strong>Smart dispatch tip</strong><small>Start with unassigned and critical requests.</small></span></div>
        </div>

        <div className="ad-toolbar">
          <div className="ad-tabs" role="tablist" aria-label="Filter tickets by status">
            <button type="button" role="tab" aria-selected={statusFilter === "actionable"} className={statusFilter === "actionable" ? "is-active" : ""} onClick={() => setStatusFilter("actionable")}>Actionable <b>{metrics.actionable}</b></button>
            <button type="button" role="tab" aria-selected={statusFilter === "submitted"} className={statusFilter === "submitted" ? "is-active" : ""} onClick={() => setStatusFilter("submitted")}>Submitted <b>{tickets.filter((ticket) => ticket.status === "submitted").length}</b></button>
            <button type="button" role="tab" aria-selected={statusFilter === "assigned"} className={statusFilter === "assigned" ? "is-active" : ""} onClick={() => setStatusFilter("assigned")}>Assigned <b>{tickets.filter((ticket) => ticket.status === "assigned").length}</b></button>
            <button type="button" role="tab" aria-selected={statusFilter === "in_progress"} className={statusFilter === "in_progress" ? "is-active" : ""} onClick={() => setStatusFilter("in_progress")}>In progress <b>{metrics.inProgress}</b></button>
            <button type="button" role="tab" aria-selected={statusFilter === "all"} className={statusFilter === "all" ? "is-active" : ""} onClick={() => setStatusFilter("all")}>All tickets</button>
          </div>
          <div className="ad-filter-controls">
            <label className="ad-priority-filter"><Filter size={15} /><span className="ad-sr-only">Filter by priority</span>
              <select value={priorityFilter} onChange={(event) => setPriorityFilter(event.target.value)}>
                <option value="all">All priorities</option>
                <option value="critical">Critical</option>
                <option value="high">High</option>
                <option value="medium">Medium</option>
                <option value="low">Low</option>
              </select>
            </label>
            <label className="ad-search"><Search size={16} /><span className="ad-sr-only">Search tickets</span>
              <input value={searchQuery} onChange={(event) => setSearchQuery(event.target.value)} placeholder="Search ticket, requester, department…" />
              {searchQuery && <button type="button" onClick={() => setSearchQuery("")} aria-label="Clear search"><X size={14} /></button>}
            </label>
          </div>
        </div>

        {loading ? (
          <div className="ad-empty"><div className="ad-loading-spinner" /><strong>Loading your dispatch queue</strong><span>Getting the latest requests and technician availability…</span></div>
        ) : filteredTickets.length === 0 ? (
          <div className="ad-empty"><div className="ad-empty-icon"><CheckCircle2 size={26} /></div><strong>{searchQuery || priorityFilter !== "all" || statusFilter !== "actionable" ? "No matching tickets" : "The queue is clear!"}</strong><span>{searchQuery || priorityFilter !== "all" ? "Try adjusting your search or filters." : "There are no tickets in this view right now."}</span><button type="button" onClick={() => { setStatusFilter("actionable"); setPriorityFilter("all"); setSearchQuery(""); }}>Reset filters <ArrowRight size={14} /></button></div>
        ) : (
          <>
            <div className="ad-table-wrap">
              <table className="ad-table">
                <thead>
                  <tr><th>Ticket / Requester</th><th>Department</th><th>Priority</th><th>Assigned to</th><th>Due date</th><th>Status</th><th><span className="ad-sr-only">Action</span></th></tr>
                </thead>
                <tbody>
                  {filteredTickets.map((ticket) => {
                    const assignee = technicians.find((tech) => String(tech.id) === String(ticket.assigned_to));
                    return (
                      <tr key={ticket.id}>
                        <td><div className="ad-ticket-main"><span className="ad-ticket-number">#{getTicketNumber(ticket)}</span><strong>{ticket.title || "Untitled request"}</strong><small><UserRound size={12} /> {ticket.owner_name || "Employee"}</small></div></td>
                        <td><span className="ad-department">{ticket.department_name || ticket.department || "—"}</span></td>
                        <td><TicketPriority priority={ticket.priority} /></td>
                        <td>{assignee ? <div className="ad-assignee"><span className="ad-assignee-avatar">{getInitials(assignee.name)}</span><span><strong>{assignee.name}</strong><small>{assignee.activeWorkload} active cases</small></span></div> : <span className="ad-unassigned"><i /> Unassigned</span>}</td>
                        <td><span className={`ad-due-date ${ticket.due_date ? "" : "is-empty"}`}><CalendarDays size={13} />{formatSafeDate(ticket.due_date)}</span></td>
                        <td><TicketStatus status={ticket.status} /></td>
                        <td><button type="button" className="ad-assign-btn" onClick={() => openAssignModal(ticket)}>{ticket.assigned_to ? "Manage" : "Assign"}<ArrowRight size={14} /></button></td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>

            <div className="ad-mobile-ticket-list">
              {filteredTickets.map((ticket) => {
                const assignee = technicians.find((tech) => String(tech.id) === String(ticket.assigned_to));
                return (
                  <article className="ad-mobile-ticket" key={ticket.id}>
                    <div className="ad-mobile-ticket-top"><span className="ad-ticket-number">#{getTicketNumber(ticket)}</span><TicketStatus status={ticket.status} /></div>
                    <h3>{ticket.title || "Untitled request"}</h3>
                    <p><UserRound size={13} /> {ticket.owner_name || "Employee"} <span>·</span> {ticket.department_name || ticket.department || "No department"}</p>
                    <div className="ad-mobile-ticket-meta"><TicketPriority priority={ticket.priority} /><span><CalendarDays size={13} /> {formatSafeDate(ticket.due_date)}</span></div>
                    <div className="ad-mobile-ticket-bottom"><span>{assignee ? `Assigned to ${assignee.name}` : "Awaiting technician"}</span><button type="button" className="ad-assign-btn" onClick={() => openAssignModal(ticket)}>{ticket.assigned_to ? "Manage" : "Assign"}<ArrowRight size={14} /></button></div>
                  </article>
                );
              })}
            </div>
          </>
        )}
        {!loading && filteredTickets.length > 0 && <div className="ad-queue-footer">Showing <strong>{filteredTickets.length}</strong> of <strong>{tickets.length}</strong> tickets</div>}
      </section>

      {selectedTicket && (
        <div className="ad-modal-backdrop" onMouseDown={(event) => event.target === event.currentTarget && closeAssignModal()}>
          <form className="ad-assignment-modal" onSubmit={handleSaveAssignment}>
            <div className="ad-modal-header">
              <div><span className="ad-modal-kicker"><Sparkles size={13} /> DISPATCH WORKFLOW</span><h2>{selectedTicket.assigned_to ? "Manage assignment" : "Assign a technician"}</h2><p>Route this request to the right person and set clear expectations.</p></div>
              <button type="button" className="ad-modal-close" onClick={closeAssignModal} aria-label="Close assignment window"><X size={19} /></button>
            </div>

            <div className="ad-modal-ticket-summary">
              <div className="ad-summary-top"><span className="ad-ticket-number">#{getTicketNumber(selectedTicket)}</span><TicketStatus status={selectedTicket.status} /><TicketPriority priority={selectedTicket.priority} /></div>
              <h3>{selectedTicket.title || "Untitled request"}</h3>
              <p>{selectedTicket.description || "No additional description was provided."}</p>
              <div className="ad-summary-details"><span><UserRound size={13} /> {selectedTicket.owner_name || "Employee"}</span><span><ClipboardList size={13} /> {selectedTicket.department_name || selectedTicket.department || "No department"}</span></div>
            </div>

            <div className="ad-form-section">
              <div className="ad-field-heading"><label htmlFor="ad-technician">Choose IT technician <b>*</b></label><span>Sorted by lightest workload</span></div>
              <select id="ad-technician" className="ad-field" required value={assigneeId} onChange={(event) => setAssigneeId(event.target.value)}>
                <option value="">Select a technician…</option>
                {technicians.map((tech) => (
                  <option key={tech.id} value={String(tech.id)}>{tech.name} · {tech.activeWorkload} active {tech.activeWorkload === 1 ? "ticket" : "tickets"}</option>
                ))}
              </select>
              {recommendedTechnician && (
                <div className="ad-suggestion"><span className="ad-suggestion-icon"><Sparkles size={15} /></span><span><strong>Suggested: {recommendedTechnician.name}</strong><small>Currently has the lightest active workload ({recommendedTechnician.activeWorkload} active).</small></span><button type="button" onClick={() => setAssigneeId(String(recommendedTechnician.id))}>Choose</button></div>
              )}
              {selectedAssignee && <div className="ad-selected-tech"><span className="ad-avatar ad-avatar--small">{getInitials(selectedAssignee.name)}</span><span><strong>{selectedAssignee.name}</strong><small>{selectedAssignee.activeWorkload} active · {selectedAssignee.resolvedCount} resolved</small></span><WorkloadLevel count={selectedAssignee.activeWorkload} /></div>}
            </div>

            <div className="ad-form-grid">
              <div className="ad-form-section"><label htmlFor="ad-priority">Priority level</label><select id="ad-priority" className="ad-field" value={priority} onChange={(event) => setPriority(event.target.value)}><option value="low">Low — Routine</option><option value="medium">Medium — Standard</option><option value="high">High — Urgent</option><option value="critical">Critical — Office blocked</option></select></div>
              <div className="ad-form-section"><label htmlFor="ad-due-date">Target due date <span>(optional)</span></label><div className="ad-date-field"><CalendarDays size={16} /><input id="ad-due-date" type="date" value={dueDate} onChange={(event) => setDueDate(event.target.value)} /></div></div>
            </div>

            <div className="ad-form-section"><label htmlFor="ad-note">Instructions for technician <span>(optional)</span></label><textarea id="ad-note" className="ad-field ad-textarea" rows={3} value={note} onChange={(event) => setNote(event.target.value)} placeholder="Add useful context, location details, or steps already tried…" /></div>

            <div className="ad-modal-actions"><button type="button" className="ad-cancel-btn" onClick={closeAssignModal} disabled={saving}>Cancel</button><button type="submit" className="ad-confirm-btn" disabled={saving || !assigneeId}>{saving ? <><span className="ad-button-spinner" /> Saving assignment…</> : <>{selectedTicket.assigned_to ? "Save changes" : "Confirm dispatch"}<ArrowRight size={16} /></>}</button></div>
            <div className="ad-modal-footnote"><CheckCircle2 size={13} /> The ticket record will be updated in the Arada Digaf system.</div>
          </form>
        </div>
      )}
    </main>
  );
}
