import { Activity, RefreshCw } from "lucide-react";
import { useCallback, useEffect, useState } from "react";
import { apiRequest, unwrap } from "../api/client";
import { useAuth } from "../context/AuthContext";
import { formatDate } from "./DashboardPage";

export default function AuditPage() {
  const { token } = useAuth();
  const [rows, setRows] = useState([]);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      const response = await apiRequest("/v1/admin/audit/?page_size=50", { token });
      setRows(unwrap(response) || []);
    } catch (err) {
      setError(err.message || "Unable to load audit activity.");
    } finally {
      setLoading(false);
    }
  }, [token]);

  useEffect(() => { load(); }, [load]);

  return <>
    <div className="page-heading">
      <div><div className="eyebrow">ACCOUNTABILITY</div><h1>Audit activity</h1>
        <p>Review administrative changes recorded by the system.</p></div>
      <button className="secondary-btn" onClick={load} disabled={loading}><RefreshCw size={16}/> Refresh</button>
    </div>
    {error && <div className="alert-error" role="alert">{error}</div>}
    <section className="panel">
      <div className="panel-heading">
        <div><h3>Administrative events</h3><p>Most recent audit records</p></div>
        <span className="live-tag"><Activity size={13}/> AUDIT LOG</span>
      </div>
      {loading ? <div className="empty-state">Loading audit records…</div>
        : rows.length === 0 ? <div className="empty-state">No administrative events have been recorded.</div>
        : <div className="audit-list">{rows.map((row, index) =>
          <div className="audit-row" key={row.id || index}>
            <div className="audit-icon"><Activity size={16}/></div>
            <div className="audit-content">
              <b>{(row.action || "System event").replaceAll("_", " ")}</b>
              <span>{row.actor_email || row.actor_name || "Administrator"}{row.target_user_id ? " · User account" : row.target_id ? " · System resource" : ""}</span>
              {row.changes && Object.keys(row.changes).length > 0 && <small>{JSON.stringify(row.changes)}</small>}
            </div>
            <time>{formatDate(row.created_at)}</time>
          </div>
        )}</div>}
    </section>
  </>;
}
