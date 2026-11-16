import { Activity, ArrowDownRight, ArrowUpRight, ArrowUpRight as OpenIcon, Clock3, ClipboardCheck, ClipboardList, Users } from "lucide-react";
import { useEffect, useState } from "react";
import { apiRequest, unwrap } from "../api/client";
import { useAuth } from "../context/AuthContext";

const STATUSES = [{key:"submitted",label:"New requests",tone:"blue"},{key:"assigned",label:"Assigned",tone:"violet"},{key:"in_progress",label:"In progress",tone:"amber"},{key:"resolved",label:"Resolved",tone:"green"},{key:"closed",label:"Closed",tone:"slate"}];
export default function DashboardPage({ go }) {
  const { token } = useAuth();
  const [stats,setStats] = useState(null); const [tickets,setTickets] = useState([]); const [users,setUsers] = useState([]); const [error,setError] = useState(""); const [loading,setLoading] = useState(true);
  useEffect(()=>{ let live=true; async function load(){ setLoading(true); setError(""); try {
    const [d,t,u] = await Promise.all([apiRequest("/v1/dashboard/",{token}),apiRequest("/v1/tickets/?page_size=8",{token}),apiRequest("/v1/users/?page_size=100",{token})]);
    if(live){setStats(unwrap(d));setTickets(unwrap(t)||[]);setUsers(unwrap(u)||[]);}
  } catch(e){if(live)setError(e.message);} finally{if(live)setLoading(false);} } load(); return()=>{live=false}; },[token]);
  const total=stats?.total_tickets ?? 0; const active=users.filter(u=>u.role==="support"||u.role==="admin").length; const open=(stats?.by_status?.submitted||0)+(stats?.by_status?.assigned||0)+(stats?.by_status?.in_progress||0);
  return <><div className="page-heading"><div><div className="eyebrow">OPERATIONS OVERVIEW</div><h1>Good day, administrator</h1><p>Here’s what’s happening across your IT support service.</p></div><button className="secondary-btn" onClick={()=>go("tickets")}><ClipboardList size={16}/> Manage tickets</button></div>
    {error && <div className="alert-error">{error}</div>}
    <div className="stat-grid">
      <Stat label="Total tickets" value={total} detail="All recorded requests" icon={ClipboardList} color="blue"/>
      <Stat label="Open workload" value={open} detail="Awaiting or being handled" icon={Clock3} color="amber"/>
      <Stat label="Resolved" value={stats?.by_status?.resolved||0} detail="Successfully completed" icon={ClipboardCheck} color="green"/>
      <Stat label="IT personnel" value={active} detail="Support & admin accounts" icon={Users} color="violet"/>
    </div>
    <div className="dashboard-grid"><section className="panel status-panel"><div className="panel-heading"><div><h3>Ticket status</h3><p>Current distribution of service requests</p></div><span className="live-tag"><i/> LIVE DATA</span></div>
      <div className="status-list">{STATUSES.map(s=>{const n=stats?.by_status?.[s.key]||0;const pct=total?Math.round(n/total*100):0;return <div className="status-row" key={s.key}><div className="status-label"><span className={`status-dot ${s.tone}`}/><b>{s.label}</b><strong>{n}</strong></div><div className="progress-track"><div className={`progress-fill ${s.tone}`} style={{width:`${pct}%`}}/></div></div>})}</div>
    </section><section className="panel workload-panel"><div className="panel-heading"><div><h3>Priority overview</h3><p>Requests by urgency</p></div></div><div className="priority-cards">{["critical","high","medium","low"].map((p,i)=><div className="priority-card" key={p}><span className={`priority-dot p-${p}`}/><span>{p}</span><b>{stats?.by_priority?.[p]||0}</b></div>)}</div><div className="workload-note"><Activity size={17}/><span>Keep critical and high-priority requests moving first.</span></div></section></div>
    <section className="panel recent-panel"><div className="panel-heading"><div><h3>Recently updated tickets</h3><p>Latest requests across the organization</p></div><button className="text-btn" onClick={()=>go("tickets")}>View all <OpenIcon size={15}/></button></div>
      {loading?<div className="empty-state">Loading operational data…</div>:tickets.length===0?<div className="empty-state">No tickets have been submitted yet.</div>:<div className="table-wrap"><table><thead><tr><th>Ticket</th><th>Request</th><th>Priority</th><th>Status</th><th>Updated</th></tr></thead><tbody>{tickets.slice(0,8).map(t=><tr key={t.id}><td className="ticket-number">{t.number||t.id}</td><td><b>{t.title}</b><small>{t.owner_name||"Employee"}</small></td><td><span className={`priority-pill ${t.priority}`}>{t.priority||"medium"}</span></td><td><StatusPill status={t.status}/></td><td className="date-cell">{formatDate(t.updated_at||t.created_at)}</td></tr>)}</tbody></table></div>}
    </section></>;
}
function Stat({label,value,detail,icon:Icon,color}){return <div className="stat-card"><div className={`stat-icon ${color}`}><Icon size={19}/></div><div className="stat-label">{label}</div><div className="stat-value">{value}</div><div className="stat-detail">{detail}</div></div>}
export function StatusPill({status}){const label=(status||"submitted").replace("_"," ");return <span className={`status-pill ${status||"submitted"}`}>{label}</span>}
export function formatDate(value){if(!value)return "—";const d=new Date(value);return Number.isNaN(d.getTime())?"—":d.toLocaleDateString(undefined,{month:"short",day:"numeric",year:"numeric"})}
