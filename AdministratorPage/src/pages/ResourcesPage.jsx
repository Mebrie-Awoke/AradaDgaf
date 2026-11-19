import { Plus, X, RefreshCw, Building2, Tags } from "lucide-react";
import { useCallback, useEffect, useState } from "react";
import { apiRequest, unwrap } from "../api/client";
import { useAuth } from "../context/AuthContext";

export default function ResourcesPage() {
  const { token } = useAuth();
  const [kind, setKind] = useState("departments");
  const [items, setItems] = useState([]);
  const [name, setName] = useState("");
  const [description, setDescription] = useState("");
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      const response = await apiRequest(`/v1/${kind}/?page_size=100`, { token });
      setItems(unwrap(response) || []);
    } catch (err) {
      setError(err.message || "Unable to load configuration.");
    } finally {
      setLoading(false);
    }
  }, [kind, token]);

  useEffect(() => { load(); }, [load]);

  async function add(event) {
    event.preventDefault();
    setError("");
    setNotice("");
    setSaving(true);
    try {
      await apiRequest(`/v1/${kind}/`, {
        token, method: "POST", body: { name: name.trim(), description: description.trim() },
      });
      setName("");
      setDescription("");
      setNotice("The item has been added.");
      await load();
    } catch (err) {
      setError(err.message || "Unable to add this item.");
    } finally {
      setSaving(false);
    }
  }

  async function toggle(item) {
    setError("");
    try {
      await apiRequest(`/v1/${kind}/${item.id}/`, {
        token, method: "PATCH", body: { is_active: item.is_active === false },
      });
      await load();
    } catch (err) {
      setError(err.message || "Unable to update this item.");
    }
  }

  return <>
    <div className="page-heading">
      <div><div className="eyebrow">SYSTEM CONFIGURATION</div><h1>Departments & categories</h1>
        <p>Maintain organizational departments and ticket classification options.</p></div>
      <button className="secondary-btn" onClick={load} disabled={loading}><RefreshCw size={16}/> Refresh</button>
    </div>
    {error && <div className="alert-error" role="alert">{error}</div>}
    {notice && <div className="alert-success" role="status">{notice}<button onClick={() => setNotice("")} aria-label="Dismiss notification"><X size={14}/></button></div>}

    <div className="tabs">
      <button className={kind === "departments" ? "tab active" : "tab"} onClick={() => setKind("departments")}><Building2 size={16}/> Departments</button>
      <button className={kind === "categories" ? "tab active" : "tab"} onClick={() => setKind("categories")}><Tags size={16}/> Categories</button>
    </div>

    <div className="resource-layout">
      <section className="panel resource-list">
        <div className="panel-heading"><div><h3>{kind === "departments" ? "Departments" : "Ticket categories"}</h3>
          <p>{items.length} configured {items.length === 1 ? "item" : "items"}</p></div></div>
        {loading ? <div className="empty-state">Loading configuration…</div>
          : items.length === 0 ? <div className="empty-state">No {kind} have been configured yet.</div>
          : items.map((item) => <div className="resource-row" key={item.id}>
            <div className="resource-icon">{kind === "departments" ? <Building2 size={18}/> : <Tags size={18}/>}</div>
            <div className="resource-copy"><b>{item.name}</b><span>{item.description || "No description provided"}</span></div>
            <button className={item.is_active === false ? "small-toggle inactive" : "small-toggle"}
              onClick={() => toggle(item)}>{item.is_active === false ? "Inactive" : "Active"}</button>
          </div>)}
      </section>

      <section className="panel add-resource">
        <div className="panel-heading"><div><h3>Add {kind === "departments" ? "department" : "category"}</h3>
          <p>New options become available in ticket workflows.</p></div></div>
        <form onSubmit={add}>
          <label htmlFor="resource-name">Name</label>
          <input id="resource-name" required maxLength="100" value={name}
            onChange={(event) => setName(event.target.value)}
            placeholder={kind === "departments" ? "Department name" : "Category name"}/>
          <label htmlFor="resource-description">Description <span className="optional">(optional)</span></label>
          <textarea id="resource-description" rows="4" maxLength="500" value={description}
            onChange={(event) => setDescription(event.target.value)} placeholder="Describe this item…"/>
          <button className="primary-btn" disabled={saving}><Plus size={16}/>{saving ? "Adding…" : "Add item"}</button>
        </form>
      </section>
    </div>
  </>;
}
