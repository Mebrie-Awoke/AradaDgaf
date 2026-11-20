import { useState, useEffect, useCallback, useMemo } from "react";
import {
  CheckCircle2,
  XCircle,
  Clock,
  Search,
  RefreshCw,
  UserCheck,
  Wrench,
  User,
  ShieldCheck,
  Phone,
  Building2,
  Hash,
  AlertTriangle,
  X,
  FileText,
  BadgeCheck,
  Mail,
  CalendarDays,
  Filter,
  Sparkles,
  Users,
  Check,
  ArrowUpRight,
  ShieldAlert,
  BriefcaseBusiness,
  Fingerprint,
  LoaderCircle,
  ClipboardCheck,
} from "lucide-react";
import { apiRequest, unwrap } from "../api/client";
import { useAuth } from "../context/AuthContext";
import { formatDate } from "./DashboardPage";

const ALL_SPECIALTIES = [
  { id: "network", label: "Network & Internet", icon: "🌐" },
  { id: "hardware", label: "Computer Hardware", icon: "💻" },
  { id: "software", label: "Software & OS", icon: "⚙️" },
  { id: "printer", label: "Printers & Peripherals", icon: "🖨️" },
  { id: "cctv", label: "CCTV & Security", icon: "📹" },
  { id: "general", label: "General IT Support", icon: "🛠️" },
];

const getInitials = (name = "") =>
  name
    .trim()
    .split(/\s+/)
    .slice(0, 2)
    .map((part) => part[0]?.toUpperCase())
    .join("") || "U";

const getSpecialtyLabel = (id) =>
  ALL_SPECIALTIES.find((s) => s.id === id)?.label || id;

const getRoleLabel = (role) =>
  role === "support" ? "IT Technician" : "Employee";

const getStatusLabel = (status) => {
  const labels = {
    pending: "Pending Review",
    active: "Approved",
    rejected: "Rejected",
  };
  return labels[status] || status;
};

const getRelativeDate = (date) => {
  if (!date) return "Date unavailable";
  const diff = Date.now() - new Date(date).getTime();
  const days = Math.floor(diff / 86400000);

  if (days < 0) return "Recently submitted";
  if (days === 0) return "Submitted today";
  if (days === 1) return "Submitted yesterday";
  if (days < 7) return `${days} days ago`;
  return formatDate(date);
};

export default function ApprovalsPage({ onBadgeUpdate }) {
  const { token } = useAuth();

  const [registrations, setRegistrations] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");

  const [roleFilter, setRoleFilter] = useState("all");
  const [statusFilter, setStatusFilter] = useState("pending");
  const [searchQuery, setSearchQuery] = useState("");

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

      if (statusFilter !== "all") {
        params.set("status", statusFilter);
      }

      if (roleFilter !== "all") {
        params.set("role", roleFilter);
      }

      const res = await apiRequest(
        `/v1/registrations/?${params.toString()}`,
        { token }
      );

      const items = unwrap(res) || [];

      setRegistrations(items);

      const pendingCount = items.filter(
        (r) => r.status === "pending"
      ).length;

      if (onBadgeUpdate) {
        onBadgeUpdate(pendingCount);
      }
    } catch (e) {
      setError(e.message || "Failed to load registrations.");
    } finally {
      setLoading(false);
    }
  }, [token, statusFilter, roleFilter, onBadgeUpdate]);

  useEffect(() => {
    fetchRegistrations();
  }, [fetchRegistrations]);

  const filtered = useMemo(() => {
    const q = searchQuery.trim().toLowerCase();

    if (!q) return registrations;

    return registrations.filter((r) => {
      const searchable = [
        r.name,
        r.username,
        r.employee_id,
        r.registration_reference,
        r.department_name,
        r.department,
        r.phone_number,
        r.email,
        r.work_unit,
      ];

      return searchable.some((value) =>
        String(value || "").toLowerCase().includes(q)
      );
    });
  }, [registrations, searchQuery]);

  const statistics = useMemo(() => {
    return {
      total: registrations.length,
      pending: registrations.filter((r) => r.status === "pending").length,
      active: registrations.filter((r) => r.status === "active").length,
      rejected: registrations.filter((r) => r.status === "rejected").length,
      employees: registrations.filter((r) => r.role === "employee").length,
      technicians: registrations.filter((r) => r.role === "support").length,
    };
  }, [registrations]);

  function handleOpenApprove(reg) {
    setError("");
    setApproveTarget(reg);

    const initialSpecs =
      Array.isArray(reg.specialties) && reg.specialties.length > 0
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
      const body =
        approveTarget.role === "support"
          ? { specialties: selectedSpecialties }
          : {};

      await apiRequest(
        `/v1/registrations/${approveTarget.id}/approve/`,
        {
          token,
          method: "POST",
          body,
        }
      );

      setNotice(
        `Account for ${approveTarget.name} has been approved and activated.`
      );

      setApproveTarget(null);
      await fetchRegistrations();
    } catch (e) {
      setError(e.message || "Approval failed.");
    } finally {
      setSubmitting(false);
    }
  }

  function handleOpenReject(reg) {
    setError("");
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
      await apiRequest(
        `/v1/registrations/${rejectTarget.id}/reject/`,
        {
          token,
          method: "POST",
          body: { reason: rejectionReason.trim() },
        }
      );

      setNotice(
        `Registration for ${rejectTarget.name} has been rejected.`
      );

      setRejectTarget(null);
      await fetchRegistrations();
    } catch (e) {
      setError(e.message || "Rejection failed.");
    } finally {
      setSubmitting(false);
    }
  }

  function closeModals() {
    if (submitting) return;
    setApproveTarget(null);
    setRejectTarget(null);
    setError("");
  }

  return (
    <div className="approval-hub">
      <style>{`
        .approval-hub {
          --ah-brand: var(--brand, #087f72);
          --ah-brand-dark: #075e55;
          --ah-brand-light: #e8f7f3;
          --ah-ink: #172b32;
          --ah-muted: #71828a;
          --ah-border: #e7edef;
          --ah-surface: #ffffff;
          --ah-bg: #f7faf9;
          --ah-green: #07875c;
          --ah-red: #dc4545;
          --ah-amber: #d28a1d;
          color: var(--ah-ink);
          width: 100%;
          min-width: 0;
        }

        .approval-hub * {
          box-sizing: border-box;
        }

        .approval-hub button,
        .approval-hub input,
        .approval-hub select,
        .approval-hub textarea {
          font: inherit;
        }

        .approval-hub button {
          cursor: pointer;
        }

        .approval-hub .ah-hero {
          position: relative;
          overflow: hidden;
          display: flex;
          justify-content: space-between;
          align-items: center;
          gap: 24px;
          padding: 30px;
          margin-bottom: 22px;
          border-radius: 22px;
          color: white;
          background:
            radial-gradient(circle at 88% 15%, rgba(255,255,255,.18), transparent 25%),
            radial-gradient(circle at 72% 120%, rgba(255,255,255,.12), transparent 28%),
            linear-gradient(120deg, #075e55 0%, #087f72 50%, #13a28d 100%);
          box-shadow: 0 12px 30px rgba(5, 105, 91, .14);
        }

        .approval-hub .ah-hero::after {
          content: "";
          position: absolute;
          width: 270px;
          height: 270px;
          border: 1px solid rgba(255,255,255,.13);
          border-radius: 50%;
          right: 100px;
          top: -160px;
          pointer-events: none;
        }

        .approval-hub .ah-hero-content {
          position: relative;
          z-index: 1;
        }

        .approval-hub .ah-eyebrow {
          display: flex;
          align-items: center;
          gap: 8px;
          margin-bottom: 10px;
          color: rgba(255,255,255,.78);
          font-size: 10px;
          font-weight: 800;
          letter-spacing: 1.8px;
          text-transform: uppercase;
        }

        .approval-hub .ah-hero h1 {
          margin: 0;
          color: white;
          font-size: clamp(25px, 3vw, 33px);
          font-weight: 800;
          letter-spacing: -1.1px;
        }

        .approval-hub .ah-hero p {
          max-width: 520px;
          margin: 9px 0 0;
          color: rgba(255,255,255,.78);
          font-size: 13px;
          line-height: 1.7;
        }

        .approval-hub .ah-hero-right {
          position: relative;
          z-index: 1;
          display: flex;
          flex-direction: column;
          align-items: flex-end;
          gap: 13px;
        }

        .approval-hub .ah-hero-number {
          font-size: 43px;
          font-weight: 800;
          line-height: 1;
          color: white;
        }

        .approval-hub .ah-hero-caption {
          color: rgba(255,255,255,.76);
          font-size: 11px;
          font-weight: 700;
          text-transform: uppercase;
          letter-spacing: 1px;
        }

        .approval-hub .ah-refresh {
          display: inline-flex;
          align-items: center;
          justify-content: center;
          gap: 8px;
          padding: 11px 17px;
          border: 1px solid rgba(255,255,255,.3);
          border-radius: 11px;
          background: rgba(255,255,255,.13);
          color: white;
          font-size: 12px;
          font-weight: 700;
          transition: .2s ease;
        }

        .approval-hub .ah-refresh:hover {
          background: rgba(255,255,255,.23);
          transform: translateY(-1px);
        }

        .approval-hub .ah-stats {
          display: grid;
          grid-template-columns: repeat(4, minmax(0, 1fr));
          gap: 14px;
          margin-bottom: 22px;
        }

        .approval-hub .ah-stat {
          position: relative;
          overflow: hidden;
          display: flex;
          align-items: center;
          gap: 14px;
          min-width: 0;
          padding: 19px;
          border: 1px solid var(--ah-border);
          border-radius: 17px;
          background: white;
          transition: transform .2s ease, box-shadow .2s ease;
        }

        .approval-hub .ah-stat:hover {
          transform: translateY(-3px);
          box-shadow: 0 9px 24px rgba(25,55,60,.07);
        }

        .approval-hub .ah-stat-icon {
          display: flex;
          flex-shrink: 0;
          align-items: center;
          justify-content: center;
          width: 45px;
          height: 45px;
          border-radius: 14px;
        }

        .approval-hub .ah-stat-icon.teal {
          color: #078b77;
          background: #e6f6f2;
        }

        .approval-hub .ah-stat-icon.amber {
          color: #c1841d;
          background: #fff5df;
        }

        .approval-hub .ah-stat-icon.blue {
          color: #3978cb;
          background: #eaf2ff;
        }

        .approval-hub .ah-stat-icon.red {
          color: #d54a4a;
          background: #fff0ef;
        }

        .approval-hub .ah-stat-copy {
          min-width: 0;
        }

        .approval-hub .ah-stat-number {
          display: block;
          font-size: 25px;
          font-weight: 800;
          line-height: 1.1;
          letter-spacing: -.7px;
          color: var(--ah-ink);
        }

        .approval-hub .ah-stat-label {
          display: block;
          margin-top: 5px;
          color: var(--ah-muted);
          font-size: 11px;
          font-weight: 600;
        }

        .approval-hub .ah-section {
          padding: 20px;
          border: 1px solid var(--ah-border);
          border-radius: 18px;
          background: white;
          margin-bottom: 18px;
        }

        .approval-hub .ah-section-heading {
          display: flex;
          align-items: center;
          justify-content: space-between;
          gap: 12px;
          margin-bottom: 17px;
        }

        .approval-hub .ah-section-heading h3 {
          margin: 0;
          font-size: 15px;
          font-weight: 800;
          color: var(--ah-ink);
        }

        .approval-hub .ah-section-heading p {
          margin: 5px 0 0;
          color: var(--ah-muted);
          font-size: 11px;
        }

        .approval-hub .ah-filter-layout {
          display: flex;
          align-items: center;
          flex-wrap: wrap;
          gap: 12px;
        }

        .approval-hub .ah-role-tabs {
          display: flex;
          flex-wrap: wrap;
          gap: 5px;
          padding: 4px;
          border-radius: 12px;
          background: #f2f6f5;
        }

        .approval-hub .ah-role-tab {
          display: inline-flex;
          align-items: center;
          justify-content: center;
          gap: 7px;
          padding: 10px 13px;
          border: none;
          border-radius: 9px;
          background: transparent;
          color: #71828a;
          font-size: 11px;
          font-weight: 700;
          transition: .2s ease;
        }

        .approval-hub .ah-role-tab:hover {
          color: var(--ah-brand);
          background: rgba(255,255,255,.7);
        }

        .approval-hub .ah-role-tab.active {
          color: var(--ah-brand-dark);
          background: white;
          box-shadow: 0 2px 6px rgba(20,50,50,.08);
        }

        .approval-hub .ah-filter-control {
          position: relative;
          display: flex;
          align-items: center;
          gap: 8px;
          min-height: 42px;
          padding: 0 12px;
          border: 1px solid var(--ah-border);
          border-radius: 10px;
          background: white;
          color: var(--ah-muted);
        }

        .approval-hub .ah-filter-control select {
          width: 100%;
          min-width: 145px;
          border: none;
          outline: none;
          background: transparent;
          color: var(--ah-ink);
          font-size: 11px;
          font-weight: 700;
          cursor: pointer;
        }

        .approval-hub .ah-search {
          display: flex;
          align-items: center;
          flex: 1;
          min-width: 190px;
          min-height: 42px;
          gap: 9px;
          padding: 0 13px;
          border: 1px solid var(--ah-border);
          border-radius: 10px;
          background: #fff;
          color: var(--ah-muted);
          transition: .2s ease;
        }

        .approval-hub .ah-search:focus-within {
          border-color: var(--ah-brand);
          box-shadow: 0 0 0 3px rgba(8,127,114,.08);
        }

        .approval-hub .ah-search input {
          width: 100%;
          min-width: 0;
          border: none;
          outline: none;
          background: transparent;
          color: var(--ah-ink);
          font-size: 11px;
        }

        .approval-hub .ah-search input::placeholder {
          color: #a5b0b5;
        }

        .approval-hub .ah-results-line {
          display: flex;
          justify-content: space-between;
          align-items: center;
          gap: 12px;
          margin: 4px 2px 15px;
        }

        .approval-hub .ah-results-line span {
          color: var(--ah-muted);
          font-size: 11px;
        }

        .approval-hub .ah-results-line strong {
          color: var(--ah-ink);
          font-weight: 800;
        }

        .approval-hub .ah-cards {
          display: grid;
          grid-template-columns: repeat(2, minmax(0, 1fr));
          gap: 14px;
        }

        .approval-hub .ah-card {
          position: relative;
          min-width: 0;
          overflow: hidden;
          padding: 19px;
          border: 1px solid var(--ah-border);
          border-radius: 16px;
          background: white;
          transition: transform .2s ease, border-color .2s ease, box-shadow .2s ease;
        }

        .approval-hub .ah-card:hover {
          transform: translateY(-2px);
          border-color: rgba(8,127,114,.25);
          box-shadow: 0 10px 25px rgba(20,55,55,.06);
        }

        .approval-hub .ah-card::before {
          content: "";
          position: absolute;
          top: 0;
          left: 0;
          width: 4px;
          height: 100%;
          background: #d7e7e4;
        }

        .approval-hub .ah-card.pending::before {
          background: #e8ab43;
        }

        .approval-hub .ah-card.active::before {
          background: #12a477;
        }

        .approval-hub .ah-card.rejected::before {
          background: #df6969;
        }

        .approval-hub .ah-card-top {
          display: flex;
          align-items: flex-start;
          justify-content: space-between;
          gap: 12px;
          margin-bottom: 18px;
        }

        .approval-hub .ah-person {
          display: flex;
          align-items: center;
          gap: 12px;
          min-width: 0;
        }

        .approval-hub .ah-avatar {
          display: flex;
          align-items: center;
          justify-content: center;
          flex-shrink: 0;
          width: 46px;
          height: 46px;
          border-radius: 14px;
          color: #087568;
          background: linear-gradient(135deg, #def5ef, #eaf3ff);
          font-size: 14px;
          font-weight: 800;
        }

        .approval-hub .ah-avatar.support {
          color: #4f69b6;
          background: linear-gradient(135deg, #e9edff, #eaf5ff);
        }

        .approval-hub .ah-person-details {
          min-width: 0;
        }

        .approval-hub .ah-person-name {
          display: block;
          overflow: hidden;
          color: var(--ah-ink);
          font-size: 13px;
          font-weight: 800;
          text-overflow: ellipsis;
          white-space: nowrap;
        }

        .approval-hub .ah-username {
          display: block;
          margin-top: 4px;
          color: var(--ah-muted);
          font-size: 10px;
        }

        .approval-hub .ah-status {
          display: inline-flex;
          align-items: center;
          gap: 5px;
          flex-shrink: 0;
          padding: 6px 9px;
          border-radius: 20px;
          font-size: 9px;
          font-weight: 800;
          white-space: nowrap;
        }

        .approval-hub .ah-status.pending {
          color: #9a6714;
          background: #fff4dc;
        }

        .approval-hub .ah-status.active {
          color: #087a52;
          background: #e4f7ee;
        }

        .approval-hub .ah-status.rejected {
          color: #bb4242;
          background: #ffebeb;
        }

        .approval-hub .ah-role {
          display: inline-flex;
          align-items: center;
          gap: 5px;
          padding: 6px 9px;
          border-radius: 7px;
          font-size: 10px;
          font-weight: 700;
        }

        .approval-hub .ah-role.employee {
          color: #3975bd;
          background: #edf4ff;
        }

        .approval-hub .ah-role.support {
          color: #7655b6;
          background: #f2edff;
        }

        .approval-hub .ah-divider {
          height: 1px;
          margin: 15px 0;
          background: var(--ah-border);
        }

        .approval-hub .ah-info-grid {
          display: grid;
          grid-template-columns: repeat(2, minmax(0, 1fr));
          gap: 15px 12px;
        }

        .approval-hub .ah-info-item {
          display: flex;
          align-items: flex-start;
          gap: 8px;
          min-width: 0;
        }

        .approval-hub .ah-info-icon {
          flex-shrink: 0;
          margin-top: 1px;
          color: #8ba0a3;
        }

        .approval-hub .ah-info-content {
          min-width: 0;
        }

        .approval-hub .ah-info-label {
          display: block;
          margin-bottom: 4px;
          color: #94a1a7;
          font-size: 9px;
          font-weight: 700;
          text-transform: uppercase;
          letter-spacing: .6px;
        }

        .approval-hub .ah-info-value {
          display: block;
          overflow-wrap: anywhere;
          color: #34494f;
          font-size: 10px;
          font-weight: 700;
        }

        .approval-hub .ah-reference {
          display: inline-flex;
          align-items: center;
          padding: 4px 6px;
          border-radius: 5px;
          background: #f2f6f5;
          color: #60777a;
          font-size: 10px;
          font-family: monospace;
        }

        .approval-hub .ah-specialties {
          display: flex;
          flex-wrap: wrap;
          gap: 5px;
          margin-top: 14px;
        }

        .approval-hub .ah-specialty {
          padding: 5px 8px;
          border: 1px solid #e4e9f7;
          border-radius: 6px;
          background: #f7f8ff;
          color: #6872a6;
          font-size: 9px;
          font-weight: 700;
        }

        .approval-hub .ah-qualification {
          margin-top: 13px;
          padding: 10px 11px;
          border-radius: 9px;
          background: #f7faf9;
          color: #63777c;
          font-size: 10px;
          line-height: 1.6;
        }

        .approval-hub .ah-rejection {
          margin-top: 12px;
          padding: 11px;
          border: 1px solid #f5dddd;
          border-radius: 9px;
          background: #fff7f7;
          color: #ae5555;
          font-size: 10px;
          line-height: 1.6;
        }

        .approval-hub .ah-card-bottom {
          display: flex;
          justify-content: space-between;
          align-items: center;
          gap: 8px;
          margin-top: 17px;
          padding-top: 13px;
          border-top: 1px solid var(--ah-border);
        }

        .approval-hub .ah-date {
          display: inline-flex;
          align-items: center;
          gap: 6px;
          color: #93a0a5;
          font-size: 9px;
          font-weight: 600;
        }

        .approval-hub .ah-actions {
          display: flex;
          gap: 7px;
        }

        .approval-hub .ah-action {
          display: inline-flex;
          align-items: center;
          justify-content: center;
          gap: 6px;
          padding: 9px 12px;
          border: 1px solid transparent;
          border-radius: 9px;
          font-size: 10px;
          font-weight: 800;
          transition: .2s ease;
        }

        .approval-hub .ah-action:disabled {
          opacity: .6;
          cursor: not-allowed;
        }

        .approval-hub .ah-action.approve {
          border-color: #d9eee4;
          background: #eaf8f0;
          color: #078153;
        }

        .approval-hub .ah-action.approve:hover {
          background: #d7f1e3;
          transform: translateY(-1px);
        }

        .approval-hub .ah-action.reject {
          border-color: #f2dddd;
          background: #fff0f0;
          color: #d24b4b;
        }

        .approval-hub .ah-action.reject:hover {
          background: #ffe1e1;
          transform: translateY(-1px);
        }

        .approval-hub .ah-completed {
          display: inline-flex;
          align-items: center;
          gap: 5px;
          color: #84969a;
          font-size: 10px;
          font-weight: 700;
        }

        .approval-hub .ah-alert {
          display: flex;
          align-items: flex-start;
          justify-content: space-between;
          gap: 12px;
          padding: 13px 15px;
          border: 1px solid;
          border-radius: 11px;
          margin-bottom: 15px;
          font-size: 12px;
          line-height: 1.5;
        }

        .approval-hub .ah-alert.error {
          border-color: #f3d3d3;
          background: #fff3f3;
          color: #ba4545;
        }

        .approval-hub .ah-alert.success {
          border-color: #ccebdd;
          background: #edfaf3;
          color: #087a53;
        }

        .approval-hub .ah-alert button {
          display: flex;
          border: none;
          background: transparent;
          color: inherit;
        }

        .approval-hub .ah-empty {
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: center;
          min-height: 260px;
          padding: 35px 15px;
          text-align: center;
        }

        .approval-hub .ah-empty-icon {
          display: flex;
          align-items: center;
          justify-content: center;
          width: 70px;
          height: 70px;
          border-radius: 22px;
          background: #e9f7f2;
          color: var(--ah-brand);
          margin-bottom: 15px;
        }

        .approval-hub .ah-empty h3 {
          margin: 0;
          color: var(--ah-ink);
          font-size: 15px;
          font-weight: 800;
        }

        .approval-hub .ah-empty p {
          max-width: 320px;
          margin: 8px 0 0;
          color: var(--ah-muted);
          font-size: 11px;
          line-height: 1.7;
        }

        .approval-hub .ah-empty-button {
          margin-top: 16px;
          padding: 9px 14px;
          border: 1px solid #d8ebe5;
          border-radius: 9px;
          background: #eff8f5;
          color: var(--ah-brand-dark);
          font-size: 10px;
          font-weight: 800;
        }

        .approval-hub .ah-skeleton {
          min-height: 180px;
          border: 1px solid var(--ah-border);
          border-radius: 15px;
          background: linear-gradient(
            100deg,
            #f4f7f6 25%,
            #eaf0ee 45%,
            #f4f7f6 65%
          );
          background-size: 200% 100%;
          animation: ah-shimmer 1.5s infinite;
        }

        @keyframes ah-shimmer {
          to { background-position: -200% 0; }
        }

        .approval-hub .ah-modal-backdrop {
          position: fixed;
          inset: 0;
          z-index: 1000;
          display: flex;
          align-items: center;
          justify-content: center;
          padding: 18px;
          background: rgba(12, 30, 34, .58);
          backdrop-filter: blur(5px);
          animation: ah-fade .18s ease;
        }

        @keyframes ah-fade {
          from { opacity: 0; }
          to { opacity: 1; }
        }

        .approval-hub .ah-modal {
          width: 100%;
          max-width: 540px;
          max-height: 90vh;
          overflow-y: auto;
          padding: 25px;
          border: 1px solid rgba(255,255,255,.5);
          border-radius: 20px;
          background: white;
          box-shadow: 0 25px 80px rgba(0,0,0,.2);
          animation: ah-modal-in .22s ease;
        }

        @keyframes ah-modal-in {
          from { opacity: 0; transform: translateY(12px) scale(.98); }
          to { opacity: 1; transform: translateY(0) scale(1); }
        }

        .approval-hub .ah-modal-heading {
          display: flex;
          align-items: flex-start;
          justify-content: space-between;
          gap: 12px;
          margin-bottom: 18px;
        }

        .approval-hub .ah-modal-heading h2 {
          margin: 5px 0 0;
          color: var(--ah-ink);
          font-size: 21px;
          font-weight: 800;
          letter-spacing: -.5px;
        }

        .approval-hub .ah-modal-eyebrow {
          color: var(--ah-brand);
          font-size: 9px;
          font-weight: 800;
          letter-spacing: 1.4px;
        }

        .approval-hub .ah-modal-close {
          display: flex;
          align-items: center;
          justify-content: center;
          width: 34px;
          height: 34px;
          flex-shrink: 0;
          border: 1px solid var(--ah-border);
          border-radius: 9px;
          background: #f8faf9;
          color: #71828a;
        }

        .approval-hub .ah-modal-close:hover {
          background: #fff0f0;
          color: var(--ah-red);
        }

        .approval-hub .ah-identity {
          display: flex;
          align-items: center;
          gap: 13px;
          padding: 15px;
          border: 1px solid #e5efeb;
          border-radius: 12px;
          background: #f6faf8;
          margin-bottom: 20px;
        }

        .approval-hub .ah-identity-avatar {
          display: flex;
          align-items: center;
          justify-content: center;
          flex-shrink: 0;
          width: 43px;
          height: 43px;
          border-radius: 13px;
          background: #e1f3ec;
          color: #087a67;
          font-size: 13px;
          font-weight: 800;
        }

        .approval-hub .ah-identity strong {
          display: block;
          color: var(--ah-ink);
          font-size: 12px;
        }

        .approval-hub .ah-identity small {
          display: block;
          margin-top: 5px;
          color: var(--ah-muted);
          font-size: 10px;
        }

        .approval-hub .ah-field-label {
          display: block;
          margin-bottom: 9px;
          color: #34494f;
          font-size: 11px;
          font-weight: 800;
        }

        .approval-hub .ah-required {
          color: var(--ah-red);
        }

        .approval-hub .ah-spec-grid {
          display: grid;
          grid-template-columns: repeat(2, minmax(0, 1fr));
          gap: 9px;
        }

        .approval-hub .ah-spec-option {
          display: flex;
          align-items: center;
          gap: 9px;
          min-height: 47px;
          padding: 10px;
          border: 1px solid var(--ah-border);
          border-radius: 10px;
          background: white;
          color: #596d73;
          font-size: 10px;
          font-weight: 700;
          cursor: pointer;
          transition: .2s ease;
        }

        .approval-hub .ah-spec-option:hover {
          border-color: #a9d9cc;
          background: #f7fbf9;
        }

        .approval-hub .ah-spec-option.checked {
          border-color: #82c9b6;
          background: #edfaf5;
          color: #08705f;
        }

        .approval-hub .ah-spec-option input {
          accent-color: var(--ah-brand);
          width: 15px;
          height: 15px;
          margin: 0;
        }

        .approval-hub .ah-textarea {
          width: 100%;
          min-height: 120px;
          padding: 12px;
          border: 1px solid var(--ah-border);
          border-radius: 10px;
          outline: none;
          resize: vertical;
          color: var(--ah-ink);
          font-size: 11px;
          line-height: 1.6;
        }

        .approval-hub .ah-textarea:focus {
          border-color: var(--ah-brand);
          box-shadow: 0 0 0 3px rgba(8,127,114,.08);
        }

        .approval-hub .ah-helper {
          display: block;
          margin-top: 7px;
          color: var(--ah-muted);
          font-size: 10px;
        }

        .approval-hub .ah-modal-footer {
          display: flex;
          justify-content: flex-end;
          gap: 9px;
          margin-top: 23px;
          padding-top: 17px;
          border-top: 1px solid var(--ah-border);
        }

        .approval-hub .ah-footer-btn {
          display: inline-flex;
          align-items: center;
          justify-content: center;
          gap: 7px;
          min-height: 40px;
          padding: 0 15px;
          border: 1px solid var(--ah-border);
          border-radius: 9px;
          background: white;
          color: #60747a;
          font-size: 11px;
          font-weight: 800;
        }

        .approval-hub .ah-footer-btn:disabled {
          opacity: .6;
          cursor: not-allowed;
        }

        .approval-hub .ah-footer-btn.primary {
          border-color: var(--ah-brand);
          background: var(--ah-brand);
          color: white;
        }

        .approval-hub .ah-footer-btn.primary:hover:not(:disabled) {
          background: var(--ah-brand-dark);
        }

        .approval-hub .ah-footer-btn.danger {
          border-color: #d84d4d;
          background: #d84d4d;
          color: white;
        }

        .approval-hub .ah-footer-btn.danger:hover:not(:disabled) {
          background: #b93838;
        }

        .approval-hub .ah-modal-warning {
          display: flex;
          align-items: flex-start;
          gap: 10px;
          margin-bottom: 17px;
          padding: 12px;
          border: 1px solid #f3dddd;
          border-radius: 10px;
          background: #fff5f4;
          color: #a84d4d;
          font-size: 10px;
          line-height: 1.6;
        }

        .approval-hub .ah-spinner {
          animation: ah-spin .8s linear infinite;
        }

        @keyframes ah-spin {
          to { transform: rotate(360deg); }
        }

        @media (max-width: 1050px) {
          .approval-hub .ah-cards {
            grid-template-columns: 1fr;
          }
        }

        @media (max-width: 800px) {
          .approval-hub .ah-stats {
            grid-template-columns: repeat(2, minmax(0, 1fr));
          }

          .approval-hub .ah-hero {
            padding: 23px;
          }
        }

        @media (max-width: 600px) {
          .approval-hub .ah-hero {
            align-items: flex-start;
            padding: 22px 18px;
          }

          .approval-hub .ah-hero p {
            font-size: 11px;
          }

          .approval-hub .ah-hero-right {
            gap: 10px;
          }

          .approval-hub .ah-hero-number {
            font-size: 32px;
          }

          .approval-hub .ah-hero-caption {
            font-size: 8px;
          }

          .approval-hub .ah-refresh {
            padding: 9px;
            font-size: 0;
          }

          .approval-hub .ah-stats {
            gap: 9px;
          }

          .approval-hub .ah-stat {
            padding: 13px;
            gap: 10px;
          }

          .approval-hub .ah-stat-icon {
            width: 37px;
            height: 37px;
            border-radius: 11px;
          }

          .approval-hub .ah-stat-number {
            font-size: 21px;
          }

          .approval-hub .ah-stat-label {
            font-size: 9px;
          }

          .approval-hub .ah-section {
            padding: 14px;
          }

          .approval-hub .ah-filter-layout {
            align-items: stretch;
            flex-direction: column;
          }

          .approval-hub .ah-role-tabs {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
          }

          .approval-hub .ah-role-tab {
            padding: 10px 5px;
            font-size: 9px;
          }

          .approval-hub .ah-filter-control,
          .approval-hub .ah-search {
            width: 100%;
            min-width: 0;
          }

          .approval-hub .ah-filter-control select {
            min-width: 0;
          }

          .approval-hub .ah-card {
            padding: 15px;
          }

          .approval-hub .ah-info-grid {
            gap: 13px 8px;
          }

          .approval-hub .ah-card-bottom {
            align-items: flex-start;
            flex-direction: column;
          }

          .approval-hub .ah-actions {
            width: 100%;
          }

          .approval-hub .ah-action {
            flex: 1;
          }

          .approval-hub .ah-modal {
            padding: 19px;
            border-radius: 16px;
          }

          .approval-hub .ah-modal-heading h2 {
            font-size: 18px;
          }

          .approval-hub .ah-spec-grid {
            grid-template-columns: 1fr;
          }
        }

        @media (max-width: 380px) {
          .approval-hub .ah-hero {
            gap: 10px;
          }

          .approval-hub .ah-hero-number {
            font-size: 27px;
          }

          .approval-hub .ah-info-grid {
            grid-template-columns: 1fr;
          }

          .approval-hub .ah-modal-footer {
            flex-direction: column-reverse;
          }

          .approval-hub .ah-footer-btn {
            width: 100%;
          }
        }
      `}</style>

      {/* HERO HEADER */}
      <header className="ah-hero">
        <div className="ah-hero-content">
          <div className="ah-eyebrow">
            <ShieldCheck size={14} />
            ARADA DIGAF · ACCESS GOVERNANCE
          </div>

          <h1>Account Approvals</h1>

          <p>
            Every great team starts with the right people. Review registrations,
            verify identities, and give employees and IT technicians access
            to the Arada Digaf platform.
          </p>
        </div>

        <div className="ah-hero-right">
          <div style={{ textAlign: "right" }}>
            <div className="ah-hero-number">
              {statistics.pending}
            </div>
            <div className="ah-hero-caption">Awaiting review</div>
          </div>

          <button
            className="ah-refresh"
            onClick={fetchRegistrations}
            disabled={loading}
          >
            <RefreshCw
              size={15}
              className={loading ? "ah-spinner" : ""}
            />
            {loading ? "Refreshing..." : "Refresh data"}
          </button>
        </div>
      </header>

      {/* STATISTICS */}
      <section className="ah-stats">
        <div className="ah-stat">
          <div className="ah-stat-icon teal">
            <Users size={21} />
          </div>
          <div className="ah-stat-copy">
            <span className="ah-stat-number">{statistics.total}</span>
            <span className="ah-stat-label">Loaded registrations</span>
          </div>
        </div>

        <div className="ah-stat">
          <div className="ah-stat-icon amber">
            <Clock size={21} />
          </div>
          <div className="ah-stat-copy">
            <span className="ah-stat-number">{statistics.pending}</span>
            <span className="ah-stat-label">Pending review</span>
          </div>
        </div>

        <div className="ah-stat">
          <div className="ah-stat-icon blue">
            <UserCheck size={21} />
          </div>
          <div className="ah-stat-copy">
            <span className="ah-stat-number">{statistics.active}</span>
            <span className="ah-stat-label">Approved accounts</span>
          </div>
        </div>

        <div className="ah-stat">
          <div className="ah-stat-icon red">
            <XCircle size={21} />
          </div>
          <div className="ah-stat-copy">
            <span className="ah-stat-number">{statistics.rejected}</span>
            <span className="ah-stat-label">Rejected accounts</span>
          </div>
        </div>
      </section>

      {/* ALERTS */}
      {error && (
        <div className="ah-alert error">
          <span style={{ display: "flex", gap: 9 }}>
            <AlertTriangle size={17} />
            {error}
          </span>
          <button onClick={() => setError("")}>
            <X size={16} />
          </button>
        </div>
      )}

      {notice && (
        <div className="ah-alert success">
          <span style={{ display: "flex", gap: 9, alignItems: "center" }}>
            <CheckCircle2 size={17} />
            {notice}
          </span>
          <button onClick={() => setNotice("")}>
            <X size={16} />
          </button>
        </div>
      )}

      {/* FILTER PANEL */}
      <section className="ah-section">
        <div className="ah-section-heading">
          <div>
            <h3>Registration Directory</h3>
            <p>Find, filter, and review account applications.</p>
          </div>

          <div style={{ color: "var(--ah-muted)" }}>
            <Filter size={18} />
          </div>
        </div>

        <div className="ah-filter-layout">
          <div className="ah-role-tabs">
            <button
              className={`ah-role-tab ${
                roleFilter === "all" ? "active" : ""
              }`}
              onClick={() => setRoleFilter("all")}
            >
              <Users size={14} />
              All roles
            </button>

            <button
              className={`ah-role-tab ${
                roleFilter === "employee" ? "active" : ""
              }`}
              onClick={() => setRoleFilter("employee")}
            >
              <User size={14} />
              Employees
            </button>

            <button
              className={`ah-role-tab ${
                roleFilter === "support" ? "active" : ""
              }`}
              onClick={() => setRoleFilter("support")}
            >
              <Wrench size={14} />
              Technicians
            </button>
          </div>

          <div className="ah-filter-control">
            <Filter size={15} />

            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
            >
              <option value="pending">Pending Review</option>
              <option value="active">Approved / Active</option>
              <option value="rejected">Rejected</option>
              <option value="all">All Statuses</option>
            </select>
          </div>

          <div className="ah-search">
            <Search size={16} />

            <input
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search name, ID, phone, reference..."
            />

            {searchQuery && (
              <button
                onClick={() => setSearchQuery("")}
                style={{
                  display: "flex",
                  border: "none",
                  background: "transparent",
                  color: "#84969a",
                }}
                aria-label="Clear search"
              >
                <X size={14} />
              </button>
            )}
          </div>
        </div>
      </section>

      {/* REGISTRATION CARDS */}
      <section className="ah-section">
        <div className="ah-results-line">
          <span>
            Showing <strong>{filtered.length}</strong> registration
            {filtered.length !== 1 ? "s" : ""}
          </span>

          <span>
            {loading ? "Updating..." : "Latest available data"}
          </span>
        </div>

        {loading ? (
          <div className="ah-cards">
            {[1, 2, 3, 4].map((item) => (
              <div key={item} className="ah-skeleton" />
            ))}
          </div>
        ) : filtered.length === 0 ? (
          <div className="ah-empty">
            <div className="ah-empty-icon">
              {searchQuery ? (
                <Search size={30} />
              ) : statusFilter === "pending" ? (
                <BadgeCheck size={32} />
              ) : (
                <FileText size={30} />
              )}
            </div>

            <h3>
              {searchQuery
                ? "No matching registrations"
                : statusFilter === "pending"
                ? "All caught up!"
                : "No registrations found"}
            </h3>

            <p>
              {searchQuery
                ? "Try another name, employee ID, phone number, or registration reference."
                : statusFilter === "pending"
                ? "There are no pending registration requests matching your current filters. Great work!"
                : "No registration requests match these filters. Try changing the role or status filter."}
            </p>

            {(searchQuery || roleFilter !== "all" || statusFilter !== "pending") && (
              <button
                className="ah-empty-button"
                onClick={() => {
                  setSearchQuery("");
                  setRoleFilter("all");
                  setStatusFilter("pending");
                }}
              >
                Reset filters
              </button>
            )}
          </div>
        ) : (
          <div className="ah-cards">
            {filtered.map((reg) => (
              <article
                key={reg.id}
                className={`ah-card ${reg.status}`}
              >
                {/* CARD HEADER */}
                <div className="ah-card-top">
                  <div className="ah-person">
                    <div
                      className={`ah-avatar ${
                        reg.role === "support" ? "support" : ""
                      }`}
                    >
                      {getInitials(reg.name)}
                    </div>

                    <div className="ah-person-details">
                      <strong className="ah-person-name">
                        {reg.name || "Unnamed User"}
                      </strong>

                      <span className="ah-username">
                        @{reg.username || "unknown"}
                      </span>
                    </div>
                  </div>

                  <span className={`ah-status ${reg.status}`}>
                    {reg.status === "pending" && <Clock size={11} />}
                    {reg.status === "active" && <CheckCircle2 size={11} />}
                    {reg.status === "rejected" && <XCircle size={11} />}
                    {getStatusLabel(reg.status)}
                  </span>
                </div>

                {/* ROLE */}
                <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                  <span className={`ah-role ${reg.role}`}>
                    {reg.role === "support" ? (
                      <Wrench size={12} />
                    ) : (
                      <User size={12} />
                    )}
                    {getRoleLabel(reg.role)}
                  </span>

                  {reg.role === "support" && (
                    <span
                      style={{
                        color: "#89969a",
                        fontSize: 9,
                        fontWeight: 600,
                      }}
                    >
                      Technical team
                    </span>
                  )}
                </div>

                <div className="ah-divider" />

                {/* REGISTRATION INFORMATION */}
                <div className="ah-info-grid">
                  <div className="ah-info-item">
                    <Hash className="ah-info-icon" size={14} />

                    <div className="ah-info-content">
                      <span className="ah-info-label">Employee ID</span>
                      <span className="ah-info-value">
                        {reg.employee_id || "Not provided"}
                      </span>
                    </div>
                  </div>

                  <div className="ah-info-item">
                    <Fingerprint className="ah-info-icon" size={14} />

                    <div className="ah-info-content">
                      <span className="ah-info-label">Reference</span>
                      <span className="ah-reference">
                        {reg.registration_reference || "—"}
                      </span>
                    </div>
                  </div>

                  <div className="ah-info-item">
                    <Building2 className="ah-info-icon" size={14} />

                    <div className="ah-info-content">
                      <span className="ah-info-label">Department</span>
                      <span className="ah-info-value">
                        {reg.department_name || reg.department || "—"}
                      </span>
                    </div>
                  </div>

                  <div className="ah-info-item">
                    <BriefcaseBusiness
                      className="ah-info-icon"
                      size={14}
                    />

                    <div className="ah-info-content">
                      <span className="ah-info-label">Work Unit</span>
                      <span className="ah-info-value">
                        {reg.work_unit || "Not specified"}
                      </span>
                    </div>
                  </div>

                  <div className="ah-info-item">
                    <Phone className="ah-info-icon" size={14} />

                    <div className="ah-info-content">
                      <span className="ah-info-label">Phone</span>
                      <span className="ah-info-value">
                        {reg.phone_number || "Not provided"}
                      </span>
                    </div>
                  </div>

                  <div className="ah-info-item">
                    <Mail className="ah-info-icon" size={14} />

                    <div className="ah-info-content">
                      <span className="ah-info-label">Email</span>
                      <span className="ah-info-value">
                        {reg.email || "Not provided"}
                      </span>
                    </div>
                  </div>
                </div>

                {/* TECHNICIAN SPECIALTIES */}
                {reg.role === "support" &&
                  Array.isArray(reg.specialties) &&
                  reg.specialties.length > 0 && (
                    <div className="ah-specialties">
                      {reg.specialties.map((s) => (
                        <span className="ah-specialty" key={s}>
                          {getSpecialtyLabel(s)}
                        </span>
                      ))}
                    </div>
                  )}

                {/* QUALIFICATION NOTE */}
                {reg.qualification_note && (
                  <div className="ah-qualification">
                    <strong style={{ color: "#53686e" }}>
                      Qualifications
                    </strong>
                    <div style={{ marginTop: 4 }}>
                      {reg.qualification_note}
                    </div>
                  </div>
                )}

                {/* REJECTION REASON */}
                {reg.rejection_reason && (
                  <div className="ah-rejection">
                    <strong>Rejection reason</strong>
                    <div>{reg.rejection_reason}</div>
                  </div>
                )}

                {/* CARD FOOTER */}
                <div className="ah-card-bottom">
                  <span className="ah-date">
                    <CalendarDays size={12} />
                    {getRelativeDate(reg.created_at)}
                  </span>

                  {reg.status === "pending" ? (
                    <div className="ah-actions">
                      <button
                        className="ah-action approve"
                        onClick={() => handleOpenApprove(reg)}
                        disabled={submitting}
                      >
                        <CheckCircle2 size={14} />
                        Approve
                      </button>

                      <button
                        className="ah-action reject"
                        onClick={() => handleOpenReject(reg)}
                        disabled={submitting}
                      >
                        <XCircle size={14} />
                        Reject
                      </button>
                    </div>
                  ) : (
                    <span className="ah-completed">
                      <BadgeCheck size={14} />
                      Review completed
                    </span>
                  )}
                </div>
              </article>
            ))}
          </div>
        )}
      </section>

      {/* APPROVE MODAL */}
      {approveTarget && (
        <div
          className="ah-modal-backdrop"
          onMouseDown={(e) => {
            if (e.target === e.currentTarget) closeModals();
          }}
        >
          <form
            className="ah-modal"
            onSubmit={handleConfirmApprove}
          >
            <div className="ah-modal-heading">
              <div>
                <div className="ah-modal-eyebrow">
                  <ShieldCheck
                    size={12}
                    style={{ display: "inline", marginRight: 5 }}
                  />
                  REGISTRATION APPROVAL
                </div>

                <h2>Approve account</h2>
              </div>

              <button
                type="button"
                className="ah-modal-close"
                onClick={closeModals}
                disabled={submitting}
              >
                <X size={18} />
              </button>
            </div>

            <div className="ah-identity">
              <div className="ah-identity-avatar">
                {getInitials(approveTarget.name)}
              </div>

              <div>
                <strong>{approveTarget.name}</strong>
                <small>
                  {getRoleLabel(approveTarget.role)} · @
                  {approveTarget.username}
                </small>
              </div>
            </div>

            <div
              style={{
                display: "grid",
                gridTemplateColumns: "1fr 1fr",
                gap: 10,
                marginBottom: 20,
              }}
            >
              <div>
                <span className="ah-info-label">Employee ID</span>
                <span className="ah-info-value">
                  {approveTarget.employee_id || "—"}
                </span>
              </div>

              <div>
                <span className="ah-info-label">Department</span>
                <span className="ah-info-value">
                  {approveTarget.department_name ||
                    approveTarget.department ||
                    "—"}
                </span>
              </div>
            </div>

            {/* TECHNICIAN SPECIALTIES */}
            {approveTarget.role === "support" && (
              <div>
                <label className="ah-field-label">
                  Assign technician specialties
                  <span className="ah-required"> *</span>
                </label>

                <p
                  style={{
                    margin: "-3px 0 12px",
                    fontSize: 10,
                    lineHeight: 1.6,
                    color: "var(--ah-muted)",
                  }}
                >
                  Select the areas this technician is qualified to support.
                </p>

                <div className="ah-spec-grid">
                  {ALL_SPECIALTIES.map((spec) => {
                    const checked = selectedSpecialties.includes(spec.id);

                    return (
                      <label
                        key={spec.id}
                        className={`ah-spec-option ${
                          checked ? "checked" : ""
                        }`}
                      >
                        <input
                          type="checkbox"
                          checked={checked}
                          onChange={() =>
                            handleToggleSpecialty(spec.id)
                          }
                        />

                        <span>{spec.icon}</span>
                        <span>{spec.label}</span>

                        {checked && (
                          <Check
                            size={13}
                            style={{ marginLeft: "auto" }}
                          />
                        )}
                      </label>
                    );
                  })}
                </div>
              </div>
            )}

            <div className="ah-modal-footer">
              <button
                type="button"
                className="ah-footer-btn"
                onClick={closeModals}
                disabled={submitting}
              >
                Cancel
              </button>

              <button
                type="submit"
                className="ah-footer-btn primary"
                disabled={
                  submitting ||
                  (approveTarget.role === "support" &&
                    selectedSpecialties.length === 0)
                }
              >
                {submitting ? (
                  <>
                    <LoaderCircle size={15} className="ah-spinner" />
                    Approving...
                  </>
                ) : (
                  <>
                    <CheckCircle2 size={15} />
                    Confirm & Activate
                  </>
                )}
              </button>
            </div>
          </form>
        </div>
      )}

      {/* REJECT MODAL */}
      {rejectTarget && (
        <div
          className="ah-modal-backdrop"
          onMouseDown={(e) => {
            if (e.target === e.currentTarget) closeModals();
          }}
        >
          <form
            className="ah-modal"
            onSubmit={handleConfirmReject}
          >
            <div className="ah-modal-heading">
              <div>
                <div
                  className="ah-modal-eyebrow"
                  style={{ color: "var(--ah-red)" }}
                >
                  <ShieldAlert
                    size={12}
                    style={{ display: "inline", marginRight: 5 }}
                  />
                  REGISTRATION REVIEW
                </div>

                <h2>Reject registration</h2>
              </div>

              <button
                type="button"
                className="ah-modal-close"
                onClick={closeModals}
                disabled={submitting}
              >
                <X size={18} />
              </button>
            </div>

            <div className="ah-identity">
              <div
                className="ah-identity-avatar"
                style={{
                  background: "#fff0ef",
                  color: "#c94c4c",
                }}
              >
                {getInitials(rejectTarget.name)}
              </div>

              <div>
                <strong>{rejectTarget.name}</strong>
                <small>
                  {getRoleLabel(rejectTarget.role)} · @
                  {rejectTarget.username}
                </small>
              </div>
            </div>

            <div className="ah-modal-warning">
              <AlertTriangle size={18} style={{ flexShrink: 0 }} />
              <span>
                You are about to reject this registration. The applicant
                will be able to see the reason you provide. Please make
                sure the explanation is clear and professional.
              </span>
            </div>

            <label className="ah-field-label">
              Reason for rejection
              <span className="ah-required"> *</span>
            </label>

            <textarea
              className="ah-textarea"
              rows={4}
              required
              minLength={5}
              value={rejectionReason}
              onChange={(e) => setRejectionReason(e.target.value)}
              placeholder="Explain why this registration cannot be approved. Include any corrections the applicant needs to make..."
            />

            <span className="ah-helper">
              Minimum 5 characters · Currently:{" "}
              {rejectionReason.trim().length} characters
            </span>

            <div className="ah-modal-footer">
              <button
                type="button"
                className="ah-footer-btn"
                onClick={closeModals}
                disabled={submitting}
              >
                Cancel
              </button>

              <button
                type="submit"
                className="ah-footer-btn danger"
                disabled={
                  submitting || rejectionReason.trim().length < 5
                }
              >
                {submitting ? (
                  <>
                    <LoaderCircle size={15} className="ah-spinner" />
                    Rejecting...
                  </>
                ) : (
                  <>
                    <XCircle size={15} />
                    Confirm Rejection
                  </>
                )}
              </button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
}