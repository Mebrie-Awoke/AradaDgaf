import { useState, useEffect, useCallback } from "react";
import {
  ClipboardList,
  UserCheck,
  Clock,
  AlertCircle,
  Search,
  Filter,
  RefreshCw,
  X,
  Calendar,
  CheckCircle2,
  ChevronRight,
  Briefcase,
  AlertTriangle,
  UserPlus,
} from "lucide-react";
import { apiRequest, unwrap } from "../api/client";
import { useAuth } from "../context/AuthContext";
import { StatusPill, formatDate } from "./DashboardPage";

export default function AssignmentDeskPage() {
  const { token } = useAuth();
  const [tickets, setTickets] = useState([]);
  const [technicians, setTechnicians] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");

  // Filters
  const [statusFilter, setStatusFilter] = useState("actionable"); // 'actionable' | 'submitted' | 'assigned' | 'in_progress' | 'all'
  const [priorityFilter, setPriorityFilter] = useState("all");
  const [searchQuery, setSearchQuery] = useState("");

  // Assignment Modal
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

      // Filter active technicians/support
      const techList = allUsers.filter(
        (u) => ["support", "admin"].includes(u.role) && u.is_active !== false
      );

      // Compute active workload for each technician (assigned or in_progress tickets)
      const techsWithWorkload = techList.map((tech) => {
        const activeCount = allTickets.filter(
          (t) =>
            t.assigned_to === tech.id &&
            ["assigned", "in_progress"].includes(t.status)
        ).length;
        const resolvedCount = allTickets.filter(
          (t) => t.assigned_to === tech.id && t.status === "resolved"
        ).length;
        return {
          ...tech,
          activeWorkload: activeCount,
          resolvedCount,
        };
      });

      // Sort technicians by workload (ascending)
      techsWithWorkload.sort((a, b) => a.activeWorkload - b.activeWorkload);

      setTickets(allTickets);
      setTechnicians(techsWithWorkload);
    } catch (e) {
      setError(e.message || "Failed to load assignment data.");
    } finally {
      setLoading(false);
    }
  }, [token]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  function openAssignModal(ticket) {
    setSelectedTicket(ticket);
    setAssigneeId(ticket.assigned_to || "");
    setPriority(ticket.priority || "medium");
    setDueDate(ticket.due_date || "");
    setNote("");
  }

  async function handleSaveAssignment(e) {
    e.preventDefault();
    if (!selectedTicket) return;
    setSaving(true);
    setError("");

    try {
      const patch = {
        assigned_to: assigneeId || null,
        priority,
      };

      if (assigneeId && selectedTicket.status === "submitted") {
        patch.status = "assigned";
      }

      if (dueDate) {
        patch.due_date = dueDate;
      }

      if (note.trim()) {
        patch.note = note.trim();
      }

      await apiRequest(`/v1/tickets/${selectedTicket.id}/`, {
        token,
        method: "PATCH",
        body: patch,
      });

      const techObj = technicians.find((t) => t.id === assigneeId);
      const assigneeName = techObj ? techObj.name : "Unassigned";

      setNotice(
        `Ticket ${selectedTicket.number || selectedTicket.id} assigned to ${assigneeName} (${priority} priority).`
      );
      setSelectedTicket(null);
      loadData();
    } catch (e) {
      setError(e.message || "Assignment failed.");
    } finally {
      setSaving(false);
    }
  }

  // Filter tickets
  const filteredTickets = tickets.filter((t) => {
    if (statusFilter === "actionable") {
      if (!["submitted", "assigned", "in_progress"].includes(t.status)) return false;
    } else if (statusFilter !== "all" && t.status !== statusFilter) {
      return false;
    }

    if (priorityFilter !== "all" && t.priority !== priorityFilter) {
      return false;
    }

    if (searchQuery) {
      const q = searchQuery.toLowerCase();
      const num = (t.number || t.id || "").toLowerCase();
      const title = (t.title || "").toLowerCase();
      const desc = (t.description || "").toLowerCase();
      const owner = (t.owner_name || "").toLowerCase();
      const dept = (t.department_name || t.department || "").toLowerCase();
      if (!num.includes(q) && !title.includes(q) && !desc.includes(q) && !owner.includes(q) && !dept.includes(q)) {
        return false;
      }
    }

    return true;
  });

  const unassignedCount = tickets.filter((t) => !t.assigned_to && t.status === "submitted").length;
  const inProgressCount = tickets.filter((t) => t.status === "in_progress").length;

  return (
    <>
      <div className="page-heading">
        <div>
          <div className="eyebrow">TRIAGE & DISPATCH</div>
          <h1>Assignment Desk</h1>
          <p>
            Monitor technician workloads, dispatch incoming requests, set due dates and priorities.
          </p>
        </div>
        <button className="secondary-btn" onClick={loadData}>
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

      {/* Technician Workload Overview Cards */}
      <section className="panel" style={{ marginBottom: 18 }}>
        <div className="panel-heading" style={{ marginBottom: 12 }}>
          <div>
            <h3>Technician Workload Monitor</h3>
            <p style={{ margin: 0 }}>Active cases assigned per support personnel</p>
          </div>
          <span className="live-tag">
            <i /> {technicians.length} ACTIVE PERSONNEL
          </span>
        </div>

        <div className="tech-workload-grid">
          {technicians.map((tech) => {
            const isHeavy = tech.activeWorkload >= 4;
            const isMedium = tech.activeWorkload >= 2 && tech.activeWorkload < 4;
            return (
              <div key={tech.id} className="tech-card">
                <div className="tech-card-header">
                  <div className="avatar small">
                    {(tech.name || "T").slice(0, 1).toUpperCase()}
                  </div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <b style={{ display: "block", fontSize: 13, textOverflow: "ellipsis", overflow: "hidden", whiteSpace: "nowrap" }}>
                      {tech.name}
                    </b>
                    <small style={{ color: "var(--muted)", textTransform: "capitalize" }}>
                      {tech.role === "admin" ? "Admin / Tech" : "IT Support"}
                    </small>
                  </div>
                  <span
                    className={`workload-badge ${
                      isHeavy ? "heavy" : isMedium ? "medium" : "light"
                    }`}
                  >
                    {tech.activeWorkload} active
                  </span>
                </div>
                {tech.specialties && tech.specialties.length > 0 && (
                  <div className="spec-tag-list" style={{ marginTop: 8 }}>
                    {tech.specialties.slice(0, 3).map((s) => (
                      <span key={s} className="mini-spec-tag">
                        {s}
                      </span>
                    ))}
                    {tech.specialties.length > 3 && (
                      <span className="mini-spec-tag">+{tech.specialties.length - 3}</span>
                    )}
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </section>

      {/* Actionable Ticket Queue */}
      <section className="panel ticket-panel">
        <div className="filter-bar">
          <div className="tab-pill-group">
            <button
              className={`tab-pill ${statusFilter === "actionable" ? "active" : ""}`}
              onClick={() => setStatusFilter("actionable")}
            >
              Actionable ({unassignedCount + inProgressCount})
            </button>
            <button
              className={`tab-pill ${statusFilter === "submitted" ? "active" : ""}`}
              onClick={() => setStatusFilter("submitted")}
            >
              Unassigned ({unassignedCount})
            </button>
            <button
              className={`tab-pill ${statusFilter === "in_progress" ? "active" : ""}`}
              onClick={() => setStatusFilter("in_progress")}
            >
              In Progress ({inProgressCount})
            </button>
            <button
              className={`tab-pill ${statusFilter === "all" ? "active" : ""}`}
              onClick={() => setStatusFilter("all")}
            >
              All Tickets
            </button>
          </div>

          <div style={{ display: "flex", gap: 10, flexWrap: "wrap", flex: 1 }}>
            <div className="filter-select">
              <Filter size={16} />
              <select
                value={priorityFilter}
                onChange={(e) => setPriorityFilter(e.target.value)}
              >
                <option value="all">All Priorities</option>
                <option value="critical">Critical</option>
                <option value="high">High</option>
                <option value="medium">Medium</option>
                <option value="low">Low</option>
              </select>
            </div>

            <div className="search-box" style={{ flex: 1, minWidth: 180 }}>
              <Search size={16} />
              <input
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search ticket #, title, requester..."
              />
            </div>
          </div>
        </div>

        {loading ? (
          <div className="empty-state">Loading assignment queue…</div>
        ) : filteredTickets.length === 0 ? (
          <div className="empty-state">No tickets need assignment matching these filters.</div>
        ) : (
          <>
            {/* Desktop Table View */}
            <div className="table-wrap desktop-only-table">
              <table>
                <thead>
                  <tr>
                    <th>Ticket Details</th>
                    <th>Department</th>
                    <th>Priority</th>
                    <th>Current Assignee</th>
                    <th>Due Date</th>
                    <th>Status</th>
                    <th>Created</th>
                    <th style={{ textAlign: "right" }}>Assign</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredTickets.map((t) => {
                    const assignee = technicians.find((tech) => tech.id === t.assigned_to);
                    return (
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
                          {assignee ? (
                            <div>
                              <b>{assignee.name}</b>
                              <small style={{ display: "block", color: "var(--muted)" }}>
                                {assignee.activeWorkload} active case(s)
                              </small>
                            </div>
                          ) : (
                            <span style={{ color: "var(--amber)", fontWeight: 600 }}>
                              Unassigned
                            </span>
                          )}
                        </td>
                        <td>{t.due_date ? formatDate(t.due_date) : "—"}</td>
                        <td>
                          <StatusPill status={t.status} />
                        </td>
                        <td className="date-cell">{formatDate(t.created_at)}</td>
                        <td style={{ textAlign: "right" }}>
                          <button
                            className="primary-btn table-action"
                            onClick={() => openAssignModal(t)}
                          >
                            <UserPlus size={15} /> Assign
                          </button>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>

            {/* Mobile Card List (< 768px) */}
            <div className="mobile-cards-container">
              {filteredTickets.map((t) => {
                const assignee = technicians.find((tech) => tech.id === t.assigned_to);
                return (
                  <div key={t.id} className="approval-card">
                    <div className="approval-card-header">
                      <div>
                        <b style={{ fontSize: 15, color: "var(--brand)" }}>
                          {t.number || t.id}
                        </b>
                        <h3 style={{ margin: "4px 0 2px", fontSize: 14 }}>{t.title}</h3>
                        <small style={{ color: "var(--muted)" }}>
                          By {t.owner_name || "Employee"} · {t.department_name || t.department || "—"}
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
                        <span className="detail-label">Assignee:</span>
                        {assignee ? (
                          <span>
                            <b>{assignee.name}</b> ({assignee.activeWorkload} active)
                          </span>
                        ) : (
                          <span style={{ color: "var(--amber)", fontWeight: 600 }}>
                            Unassigned
                          </span>
                        )}
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
                        onClick={() => openAssignModal(t)}
                      >
                        <UserPlus size={16} /> Assign / Reassign
                      </button>
                    </div>
                  </div>
                );
              })}
            </div>
          </>
        )}
      </section>

      {/* Assignment Modal / Bottom Sheet */}
      {selectedTicket && (
        <div
          className="modal-backdrop"
          onMouseDown={(e) => e.target === e.currentTarget && setSelectedTicket(null)}
        >
          <form className="modal-card modal-bottom-sheet" onSubmit={handleSaveAssignment}>
            <div className="modal-heading">
              <div>
                <div className="eyebrow">TICKET ASSIGNMENT</div>
                <h2>Assign Ticket {selectedTicket.number || selectedTicket.id}</h2>
              </div>
              <button
                type="button"
                className="icon-btn"
                onClick={() => setSelectedTicket(null)}
              >
                <X size={19} />
              </button>
            </div>

            <div className="ticket-summary">
              <b>{selectedTicket.title}</b>
              <p>{selectedTicket.description}</p>
              <div style={{ marginTop: 6, fontSize: 12, color: "var(--muted)" }}>
                Requester: <strong>{selectedTicket.owner_name}</strong> · Department:{" "}
                <strong>{selectedTicket.department_name || selectedTicket.department}</strong>
              </div>
            </div>

            {/* Technician Selection with Workload */}
            <div style={{ marginTop: 14 }}>
              <label style={{ display: "block", marginBottom: 6, fontWeight: 600 }}>
                Assign to IT Technician <span style={{ color: "var(--danger)" }}>*</span>
              </label>
              <select
                className="field-select full-width"
                required
                value={assigneeId}
                onChange={(e) => setAssigneeId(e.target.value)}
              >
                <option value="">Select Technician...</option>
                {technicians.map((tech) => (
                  <option key={tech.id} value={tech.id}>
                    {tech.name} · {tech.activeWorkload} active ticket(s)
                    {tech.specialties?.length ? ` [${tech.specialties.join(", ")}]` : ""}
                  </option>
                ))}
              </select>
            </div>

            {/* Priority Selection */}
            <div style={{ marginTop: 14 }}>
              <label style={{ display: "block", marginBottom: 6, fontWeight: 600 }}>
                Priority Level
              </label>
              <select
                className="field-select full-width"
                value={priority}
                onChange={(e) => setPriority(e.target.value)}
              >
                <option value="low">Low - Routine issue</option>
                <option value="medium">Medium - Standard workflow</option>
                <option value="high">High - Urgent attention needed</option>
                <option value="critical">Critical - System / office blocked</option>
              </select>
            </div>

            {/* Due Date */}
            <div style={{ marginTop: 14 }}>
              <label style={{ display: "block", marginBottom: 6, fontWeight: 600 }}>
                Target Resolution Due Date (Optional)
              </label>
              <input
                type="date"
                className="field-input full-width"
                value={dueDate}
                onChange={(e) => setDueDate(e.target.value)}
              />
            </div>

            {/* Assignment Note */}
            <div style={{ marginTop: 14 }}>
              <label style={{ display: "block", marginBottom: 6, fontWeight: 600 }}>
                Assignment Note / Instructions (Optional)
              </label>
              <textarea
                className="field-textarea full-width"
                rows={3}
                value={note}
                onChange={(e) => setNote(e.target.value)}
                placeholder="Add special instructions or context for the technician..."
              />
            </div>

            <div className="modal-actions" style={{ marginTop: 20 }}>
              <button
                type="button"
                className="secondary-btn"
                onClick={() => setSelectedTicket(null)}
              >
                Cancel
              </button>
              <button className="primary-btn" disabled={saving}>
                {saving ? "Saving Assignment…" : "Confirm Assignment"}
              </button>
            </div>
          </form>
        </div>
      )}
    </>
  );
}
