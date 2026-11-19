import { useState, useEffect, useCallback } from "react";
import {
  CheckCircle2,
  XCircle,
  Clock,
  Search,
  RefreshCw,
  UserCheck,
  Wrench,
  User,
  Shield,
  Phone,
  Building,
  Hash,
  AlertTriangle,
  X,
  FileText,
  BadgeCheck,
} from "lucide-react";
import { apiRequest, unwrap } from "../api/client";
import { useAuth } from "../context/AuthContext";
import { formatDate } from "./DashboardPage";

const ALL_SPECIALTIES = [
  { id: "network", label: "Network & Internet" },
  { id: "hardware", label: "Computer Hardware" },
  { id: "software", label: "Software & OS" },
  { id: "printer", label: "Printers & Peripherals" },
  { id: "cctv", label: "CCTV & Security" },
  { id: "general", label: "General IT Support" },
];

export default function ApprovalsPage({ onBadgeUpdate }) {
  const { token } = useAuth();
  const [registrations, setRegistrations] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");
  const [roleFilter, setRoleFilter] = useState("all"); // 'all' | 'employee' | 'support'
  const [statusFilter, setStatusFilter] = useState("pending"); // 'pending' | 'active' | 'rejected' | 'all'
  const [searchQuery, setSearchQuery] = useState("");

  // Modals state
  const [approveTarget, setApproveTarget] = useState(null);
  const [rejectTarget, setRejectTarget] = useState(null);
  const [selectedSpecialties, setSelectedSpecialties] = useState([]);
  const [rejectionReason, setRejectionReason] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const fetchRegistrations = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      const params = new URLSearchParams({ page_size: "100" });
      if (statusFilter !== "all") params.set("status", statusFilter);
      if (roleFilter !== "all") params.set("role", roleFilter);

      const res = await apiRequest(`/v1/registrations/?${params.toString()}`, { token });
      const items = unwrap(res) || [];
      setRegistrations(items);

      // Count pending for live badge
      const pendingCount = items.filter((r) => r.status === "pending").length;
      if (onBadgeUpdate) onBadgeUpdate(pendingCount);
    } catch (e) {
      setError(e.message || "Failed to load registrations.");
    } finally {
      setLoading(false);
    }
  }, [token, statusFilter, roleFilter, onBadgeUpdate]);

  useEffect(() => {
    fetchRegistrations();
  }, [fetchRegistrations]);

  function handleOpenApprove(reg) {
    setApproveTarget(reg);
    const initialSpecs = Array.isArray(reg.specialties) && reg.specialties.length > 0
      ? reg.specialties
      : ["general"];
    setSelectedSpecialties(initialSpecs);
  }

  function handleToggleSpecialty(specId) {
    setSelectedSpecialties((prev) =>
      prev.includes(specId)
        ? prev.filter((s) => s !== specId)
        : [...prev, specId]
    );
  }

  async function handleConfirmApprove(e) {
    e.preventDefault();
    if (!approveTarget) return;
    setSubmitting(true);
    setError("");
    try {
      const body = approveTarget.role === "support"
        ? { specialties: selectedSpecialties }
        : {};

      await apiRequest(`/v1/registrations/${approveTarget.id}/approve/`, {
        token,
        method: "POST",
        body,
      });

      setNotice(`Account for ${approveTarget.name} has been approved and activated.`);
      setApproveTarget(null);
      fetchRegistrations();
    } catch (e) {
      setError(e.message || "Approval failed.");
    } finally {
      setSubmitting(false);
    }
  }

  function handleOpenReject(reg) {
    setRejectTarget(reg);
    setRejectionReason("");
  }

  async function handleConfirmReject(e) {
    e.preventDefault();
    if (!rejectTarget) return;
    if (rejectionReason.trim().length < 5) {
      setError("Please provide a rejection reason of at least 5 characters.");
      return;
    }

    setSubmitting(true);
    setError("");
    try {
      await apiRequest(`/v1/registrations/${rejectTarget.id}/reject/`, {
        token,
        method: "POST",
        body: { reason: rejectionReason.trim() },
      });

      setNotice(`Registration for ${rejectTarget.name} has been rejected.`);
      setRejectTarget(null);
      fetchRegistrations();
    } catch (e) {
      setError(e.message || "Rejection failed.");
    } finally {
      setSubmitting(false);
    }
  }

  const filtered = registrations.filter((r) => {
    if (!searchQuery) return true;
    const q = searchQuery.toLowerCase();
    const name = (r.name || "").toLowerCase();
    const username = (r.username || "").toLowerCase();
    const empId = (r.employee_id || "").toLowerCase();
    const ref = (r.registration_reference || "").toLowerCase();
    const dept = (r.department_name || "").toLowerCase();
    const phone = (r.phone_number || "").toLowerCase();
    return (
      name.includes(q) ||
      username.includes(q) ||
      empId.includes(q) ||
      ref.includes(q) ||
      dept.includes(q) ||
      phone.includes(q)
    );
  });

  const pendingCount = registrations.filter((r) => r.status === "pending").length;

  return (
    <>
      <div className="page-heading">
        <div>
          <div className="eyebrow">ACCESS GOVERNANCE</div>
          <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
            <h1>Account Approvals</h1>
            {pendingCount > 0 && (
              <span className="badge-count" title={`${pendingCount} pending reviews`}>
                {pendingCount}
              </span>
            )}
          </div>
          <p>
            Review self-service registrations for subcity employees and IT technicians.
          </p>
        </div>
        <button className="secondary-btn" onClick={fetchRegistrations}>
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

      {/* Tabs & Filters */}
      <section className="panel" style={{ marginBottom: 16 }}>
        <div className="approvals-filter-container">
          {/* Role Tabs */}
          <div className="tab-pill-group">
            <button
              className={`tab-pill ${roleFilter === "all" ? "active" : ""}`}
              onClick={() => setRoleFilter("all")}
            >
              All Roles
            </button>
            <button
              className={`tab-pill ${roleFilter === "employee" ? "active" : ""}`}
              onClick={() => setRoleFilter("employee")}
            >
              <User size={14} /> Employees
            </button>
            <button
              className={`tab-pill ${roleFilter === "support" ? "active" : ""}`}
              onClick={() => setRoleFilter("support")}
            >
              <Wrench size={14} /> Technicians
            </button>
          </div>

          {/* Status Filter */}
          <div className="status-select-wrap">
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="field-select"
              style={{ minWidth: 140 }}
            >
              <option value="pending">Pending Review</option>
              <option value="active">Approved / Active</option>
              <option value="rejected">Rejected</option>
              <option value="all">All Statuses</option>
            </select>
          </div>

          {/* Search Box */}
          <div className="search-box" style={{ flex: 1, minWidth: 200 }}>
            <Search size={16} />
            <input
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search by name, ID, phone, reference..."
            />
          </div>
        </div>
      </section>

      {/* Content */}
      <section className="panel">
        {loading ? (
          <div className="empty-state">Loading registration requests…</div>
        ) : filtered.length === 0 ? (
          <div className="empty-state">
            <BadgeCheck size={36} style={{ color: "var(--brand)", marginBottom: 8 }} />
            <p>No registration requests match these filters.</p>
          </div>
        ) : (
          <>
            {/* Desktop Table View (>= 768px) */}
            <div className="table-wrap desktop-only-table">
              <table>
                <thead>
                  <tr>
                    <th>Registrant</th>
                    <th>Role</th>
                    <th>Employee ID / Ref</th>
                    <th>Department & Unit</th>
                    <th>Contact</th>
                    <th>Status</th>
                    <th>Submitted</th>
                    <th style={{ textAlign: "right" }}>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {filtered.map((reg) => (
                    <tr key={reg.id}>
                      <td>
                        <div className="person-cell">
                          <div className="avatar small">
                            {(reg.name || "U").slice(0, 1).toUpperCase()}
                          </div>
                          <div>
                            <b>{reg.name}</b>
                            <small>@{reg.username}</small>
                          </div>
                        </div>
                      </td>
                      <td>
                        <span className={`role-pill ${reg.role}`}>
                          {reg.role === "support" ? "Technician" : "Employee"}
                        </span>
                        {reg.role === "support" && reg.specialties && reg.specialties.length > 0 && (
                          <div className="spec-tag-list" style={{ marginTop: 4 }}>
                            {reg.specialties.map((s) => (
                              <span key={s} className="mini-spec-tag">
                                {s}
                              </span>
                            ))}
                          </div>
                        )}
                      </td>
                      <td>
                        <div style={{ fontSize: 13 }}>
                          <b>{reg.employee_id || "—"}</b>
                          <br />
                          <small style={{ color: "var(--muted)", fontFamily: "monospace" }}>
                            {reg.registration_reference || "—"}
                          </small>
                        </div>
                      </td>
                      <td>
                        <div style={{ fontSize: 13 }}>
                          <span>{reg.department_name || reg.department || "—"}</span>
                          {reg.work_unit && (
                            <small style={{ display: "block", color: "var(--muted)" }}>
                              {reg.work_unit}
                            </small>
                          )}
                        </div>
                      </td>
                      <td>
                        <div style={{ fontSize: 13 }}>
                          <span>{reg.phone_number || "—"}</span>
                          {reg.email && (
                            <small style={{ display: "block", color: "var(--muted)" }}>
                              {reg.email}
                            </small>
                          )}
                        </div>
                      </td>
                      <td>
                        <span className={`status-pill ${reg.status}`}>
                          {reg.status === "pending"
                            ? "Pending"
                            : reg.status === "active"
                            ? "Active"
                            : reg.status === "rejected"
                            ? "Rejected"
                            : reg.status}
                        </span>
                        {reg.rejection_reason && (
                          <small
                            style={{
                              display: "block",
                              color: "var(--danger)",
                              maxWidth: 150,
                              whiteSpace: "nowrap",
                              overflow: "hidden",
                              textOverflow: "ellipsis",
                            }}
                            title={reg.rejection_reason}
                          >
                            Reason: {reg.rejection_reason}
                          </small>
                        )}
                      </td>
                      <td className="date-cell">{formatDate(reg.created_at)}</td>
                      <td style={{ textAlign: "right" }}>
                        {reg.status === "pending" ? (
                          <div style={{ display: "inline-flex", gap: 6 }}>
                            <button
                              className="action-btn approve"
                              onClick={() => handleOpenApprove(reg)}
                              title="Approve registration"
                            >
                              <CheckCircle2 size={16} /> Approve
                            </button>
                            <button
                              className="action-btn reject"
                              onClick={() => handleOpenReject(reg)}
                              title="Reject registration"
                            >
                              <XCircle size={16} /> Reject
                            </button>
                          </div>
                        ) : (
                          <span style={{ fontSize: 12, color: "var(--muted)" }}>Completed</span>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            {/* Mobile Card List (< 768px) */}
            <div className="mobile-cards-container">
              {filtered.map((reg) => (
                <div key={reg.id} className="approval-card">
                  <div className="approval-card-header">
                    <div className="person-cell">
                      <div className="avatar">
                        {(reg.name || "U").slice(0, 1).toUpperCase()}
                      </div>
                      <div>
                        <b>{reg.name}</b>
                        <small>@{reg.username}</small>
                      </div>
                    </div>
                    <span className={`status-pill ${reg.status}`}>
                      {reg.status === "pending"
                        ? "Pending"
                        : reg.status === "active"
                        ? "Active"
                        : "Rejected"}
                    </span>
                  </div>

                  <div className="approval-card-details">
                    <div className="card-detail-item">
                      <span className="detail-label">Role:</span>
                      <span className={`role-pill ${reg.role}`}>
                        {reg.role === "support" ? "Technician" : "Employee"}
                      </span>
                    </div>

                    <div className="card-detail-item">
                      <span className="detail-label">Employee ID:</span>
                      <b>{reg.employee_id || "—"}</b>
                    </div>

                    <div className="card-detail-item">
                      <span className="detail-label">Ref #:</span>
                      <code style={{ fontSize: 12 }}>{reg.registration_reference || "—"}</code>
                    </div>

                    <div className="card-detail-item">
                      <span className="detail-label">Department:</span>
                      <span>{reg.department_name || reg.department || "—"}</span>
                    </div>

                    {reg.work_unit && (
                      <div className="card-detail-item">
                        <span className="detail-label">Work Unit:</span>
                        <span>{reg.work_unit}</span>
                      </div>
                    )}

                    <div className="card-detail-item">
                      <span className="detail-label">Phone:</span>
                      <span>{reg.phone_number || "—"}</span>
                    </div>

                    {reg.role === "support" && reg.specialties && reg.specialties.length > 0 && (
                      <div className="card-detail-item full-width">
                        <span className="detail-label">Specialties:</span>
                        <div className="spec-tag-list">
                          {reg.specialties.map((s) => (
                            <span key={s} className="mini-spec-tag">
                              {s}
                            </span>
                          ))}
                        </div>
                      </div>
                    )}

                    {reg.qualification_note && (
                      <div className="card-detail-item full-width">
                        <span className="detail-label">Qualifications:</span>
                        <p style={{ margin: "4px 0 0", fontSize: 12, color: "var(--muted)" }}>
                          {reg.qualification_note}
                        </p>
                      </div>
                    )}

                    {reg.rejection_reason && (
                      <div className="card-detail-item full-width rejection-box">
                        <span className="detail-label" style={{ color: "var(--danger)" }}>
                          Rejection Reason:
                        </span>
                        <p style={{ margin: "2px 0 0", fontSize: 12 }}>{reg.rejection_reason}</p>
                      </div>
                    )}
                  </div>

                  {reg.status === "pending" && (
                    <div className="approval-card-actions">
                      <button
                        className="action-btn approve full-width"
                        onClick={() => handleOpenApprove(reg)}
                      >
                        <CheckCircle2 size={16} /> Approve
                      </button>
                      <button
                        className="action-btn reject full-width"
                        onClick={() => handleOpenReject(reg)}
                      >
                        <XCircle size={16} /> Reject
                      </button>
                    </div>
                  )}
                </div>
              ))}
            </div>
          </>
        )}
      </section>

      {/* Approve Modal / Bottom Sheet */}
      {approveTarget && (
        <div
          className="modal-backdrop"
          onMouseDown={(e) => e.target === e.currentTarget && setApproveTarget(null)}
        >
          <form className="modal-card modal-bottom-sheet" onSubmit={handleConfirmApprove}>
            <div className="modal-heading">
              <div>
                <div className="eyebrow">REGISTRATION APPROVAL</div>
                <h2>Approve {approveTarget.name}</h2>
              </div>
              <button
                type="button"
                className="icon-btn"
                onClick={() => setApproveTarget(null)}
              >
                <X size={19} />
              </button>
            </div>

            <div className="ticket-summary">
              <b>
                {approveTarget.role === "support" ? "IT Support Technician" : "Subcity Employee"}
              </b>
              <p>
                Employee ID: <strong>{approveTarget.employee_id}</strong> · Dept:{" "}
                <strong>{approveTarget.department_name || approveTarget.department}</strong> · Ref:{" "}
                <code>{approveTarget.registration_reference}</code>
              </p>
            </div>

            {approveTarget.role === "support" && (
              <div style={{ marginTop: 14 }}>
                <label style={{ display: "block", marginBottom: 6, fontWeight: 600 }}>
                  Confirm or override technician specialties:
                </label>
                <div className="spec-checkbox-grid">
                  {ALL_SPECIALTIES.map((spec) => {
                    const checked = selectedSpecialties.includes(spec.id);
                    return (
                      <label key={spec.id} className={`spec-checkbox-item ${checked ? "checked" : ""}`}>
                        <input
                          type="checkbox"
                          checked={checked}
                          onChange={() => handleToggleSpecialty(spec.id)}
                        />
                        <span>{spec.label}</span>
                      </label>
                    );
                  })}
                </div>
              </div>
            )}

            <div className="modal-actions" style={{ marginTop: 20 }}>
              <button
                type="button"
                className="secondary-btn"
                onClick={() => setApproveTarget(null)}
              >
                Cancel
              </button>
              <button className="primary-btn" disabled={submitting}>
                {submitting ? "Approving…" : "Confirm & Activate"}
              </button>
            </div>
          </form>
        </div>
      )}

      {/* Reject Modal / Bottom Sheet */}
      {rejectTarget && (
        <div
          className="modal-backdrop"
          onMouseDown={(e) => e.target === e.currentTarget && setRejectTarget(null)}
        >
          <form className="modal-card modal-bottom-sheet" onSubmit={handleConfirmReject}>
            <div className="modal-heading">
              <div>
                <div className="eyebrow" style={{ color: "var(--danger)" }}>
                  REGISTRATION REJECTION
                </div>
                <h2>Reject Registration</h2>
              </div>
              <button
                type="button"
                className="icon-btn"
                onClick={() => setRejectTarget(null)}
              >
                <X size={19} />
              </button>
            </div>

            <div className="ticket-summary" style={{ borderColor: "rgba(220, 38, 38, 0.2)" }}>
              <b>{rejectTarget.name}</b>
              <p>
                Ref: <code>{rejectTarget.registration_reference}</code> · ID:{" "}
                <strong>{rejectTarget.employee_id}</strong>
              </p>
            </div>

            <div style={{ marginTop: 14 }}>
              <label style={{ display: "block", marginBottom: 6, fontWeight: 600 }}>
                Reason for Rejection <span style={{ color: "var(--danger)" }}>*</span>
              </label>
              <textarea
                className="field-textarea"
                rows={4}
                required
                minLength={5}
                value={rejectionReason}
                onChange={(e) => setRejectionReason(e.target.value)}
                placeholder="Explain why this registration is rejected (at least 5 characters). This will be shown to the applicant."
              />
              <small style={{ color: "var(--muted)", display: "block", marginTop: 4 }}>
                Minimum 5 characters. Currently: {rejectionReason.trim().length} chars.
              </small>
            </div>

            <div className="modal-actions" style={{ marginTop: 20 }}>
              <button
                type="button"
                className="secondary-btn"
                onClick={() => setRejectTarget(null)}
              >
                Cancel
              </button>
              <button
                className="danger-btn"
                disabled={submitting || rejectionReason.trim().length < 5}
              >
                {submitting ? "Rejecting…" : "Reject Registration"}
              </button>
            </div>
          </form>
        </div>
      )}
    </>
  );
}
