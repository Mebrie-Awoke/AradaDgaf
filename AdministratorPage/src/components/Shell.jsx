import { Activity, Bell, Boxes, Building2, ChevronDown, ClipboardList, LayoutDashboard, LogOut, Menu, ShieldCheck, Users, X } from "lucide-react";
import { useState } from "react";
import { useAuth } from "../context/AuthContext";

const links = [
  { id: "dashboard", label: "Overview", icon: LayoutDashboard },
  { id: "tickets", label: "Ticket management", icon: ClipboardList },
  { id: "staff", label: "People & access", icon: Users },
  { id: "resources", label: "Departments & categories", icon: Boxes },
  { id: "audit", label: "Audit activity", icon: Activity },
];

export default function Shell({ page, setPage, children }) {
  const { user, logout } = useAuth();
  const [mobileOpen, setMobileOpen] = useState(false);
  return <div className="app-shell">
    <aside className={`sidebar ${mobileOpen ? "sidebar-open" : ""}`}>
      <div className="brand"><div className="brand-mark">A</div><div><strong>AradaDgaf</strong><span>ADMIN CONSOLE</span></div><button className="icon-btn mobile-close" onClick={() => setMobileOpen(false)}><X size={18}/></button></div>
      <div className="workspace-label">WORKSPACE</div>
      <nav>{links.map(item => { const Icon = item.icon; return <button key={item.id} className={page === item.id ? "nav-link active" : "nav-link"} onClick={() => { setPage(item.id); setMobileOpen(false); }}><Icon size={18}/><span>{item.label}</span>{item.id === "tickets" && <span className="nav-dot"/>}</button>; })}</nav>
      <div className="sidebar-bottom"><div className="secure-note"><ShieldCheck size={17}/><div><b>Secure workspace</b><span>Administrator access</span></div></div><button className="nav-link logout-link" onClick={logout}><LogOut size={18}/><span>Sign out</span></button></div>
    </aside>
    {mobileOpen && <button className="mobile-scrim" aria-label="Close menu" onClick={() => setMobileOpen(false)}/>}
    <main className="main-area">
      <header className="topbar"><button className="icon-btn menu-toggle" onClick={() => setMobileOpen(true)}><Menu size={20}/></button><div className="crumb">Arada Subcity <span>/</span> <b>{links.find(x => x.id === page)?.label || "Overview"}</b></div><div className="topbar-right"><div className="system-status"><i/> API workspace</div><div className="user-chip"><div className="avatar">{(user?.name || "A").slice(0,1).toUpperCase()}</div><div><b>{user?.name || "Administrator"}</b><span>Administrator</span></div><ChevronDown size={15}/></div></div></header>
      <div className="page-content">{children}</div>
      <footer className="footer"><span>AradaDgaf · IT Service Management</span><span>Administrator portal</span></footer>
    </main>
  </div>;
}