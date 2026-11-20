import {
  Activity,
  Boxes,
  Briefcase,
  ChevronDown,
  ClipboardList,
  LayoutDashboard,
  LogOut,
  Menu,
  MoreHorizontal,
  ShieldCheck,
  UserCheck,
  Users,
  X,
} from "lucide-react";

import { useState } from "react";
import { useAuth } from "../context/AuthContext";

const links = [
  { id: "dashboard", label: "Overview", icon: LayoutDashboard },
  { id: "assignment", label: "Assignment Desk", icon: Briefcase },
  { id: "approvals", label: "Approvals", icon: UserCheck, badge: true },
  { id: "tickets", label: "Ticket management", icon: ClipboardList },
  { id: "staff", label: "People & access", icon: Users },
  { id: "resources", label: "Departments & categories", icon: Boxes },
  { id: "audit", label: "Audit activity", icon: Activity },
];

const mobileBottomNavItems = [
  { id: "dashboard", label: "Dashboard", icon: LayoutDashboard },
  { id: "assignment", label: "Assignment", icon: Briefcase },
  { id: "approvals", label: "Approvals", icon: UserCheck, badge: true },
  { id: "tickets", label: "Tickets", icon: ClipboardList },
  { id: "more", label: "More", icon: MoreHorizontal },
];

export default function Shell({ page, setPage, pendingApprovalsCount = 0, children }) {
  const { user, logout } = useAuth();
  const [mobileOpen, setMobileOpen] = useState(false);

  return <div className="app-shell">
    <aside className={`sidebar ${mobileOpen ? "sidebar-open" : ""}`}>
      <div className="brand">
        <div className="brand-mark">A</div>
        <div><strong>AradaDgaf</strong><span>ADMIN CONSOLE</span></div>
        <button className="icon-btn mobile-close" onClick={() => setMobileOpen(false)} aria-label="Close navigation"><X size={18}/></button>
      </div>
      <div className="workspace-label">WORKSPACE</div>
      <nav aria-label="Administrator navigation">
        {links.map((item) => {
          const Icon = item.icon;
          return <button key={item.id} className={page === item.id ? "nav-link active" : "nav-link"}
            aria-current={page === item.id ? "page" : undefined}
            onClick={() => { setPage(item.id); setMobileOpen(false); }}>
            <Icon size={18}/><span>{item.label}</span>
          </button>;
        })}
      </nav>
      <div className="sidebar-bottom">
        <div className="secure-note"><ShieldCheck size={17}/><div><b>Secure workspace</b><span>Administrator access</span></div></div>
        <button className="nav-link logout-link" onClick={logout}><LogOut size={18}/><span>Sign out</span></button>
      </div>
    </aside>

    {mobileOpen && <button className="mobile-scrim" aria-label="Close menu" onClick={() => setMobileOpen(false)}/>}
    <main className="main-area">
      <header className="topbar">
        <button className="icon-btn menu-toggle" onClick={() => setMobileOpen(true)} aria-label="Open navigation"><Menu size={20}/></button>
        <div className="crumb">Arada Subcity <span>/</span> <b>{links.find((item) => item.id === page)?.label || "Overview"}</b></div>
        <div className="topbar-right">
          <div className="system-status">Administrator workspace</div>
          <div className="user-chip">
            <div className="avatar">{(user?.name || "A").slice(0, 1).toUpperCase()}</div>
            <div><b>{user?.name || "Administrator"}</b><span>Administrator</span></div>
            <ChevronDown size={15}/>
          </div>
        </div>
      </header>
      <div className="page-content">{children}</div>
      <footer className="footer"><span>AradaDgaf · IT Service Management</span><span>Administrator portal</span></footer>
    </main>
  </div>;

  const [moreSheetOpen, setMoreSheetOpen] = useState(false);

  function handleNavClick(id) {
    if (id === "more") {
      setMoreSheetOpen(true);
      return;
    }
    setPage(id);
    setMobileOpen(false);
    setMoreSheetOpen(false);
  }

  return (
    <div className="app-shell">
      {/* Desktop Sidebar */}
      <aside className={`sidebar ${mobileOpen ? "sidebar-open" : ""}`}>
        <div className="brand">
          <div className="brand-mark">A</div>
          <div>
            <strong>AradaDgaf</strong>
            <span>ADMIN CONSOLE</span>
          </div>
          <button
            className="icon-btn mobile-close"
            onClick={() => setMobileOpen(false)}
            aria-label="Close navigation"
          >
            <X size={18} />
          </button>
        </div>

        <div className="workspace-label">WORKSPACE</div>
        <nav>
          {links.map((item) => {
            const Icon = item.icon;
            const isActive = page === item.id;
            return (
              <button
                key={item.id}
                className={isActive ? "nav-link active" : "nav-link"}
                onClick={() => handleNavClick(item.id)}
              >
                <Icon size={18} />
                <span>{item.label}</span>
                {item.badge && pendingApprovalsCount > 0 && (
                  <span className="sidebar-badge">{pendingApprovalsCount}</span>
                )}
                {item.id === "tickets" && !item.badge && <span className="nav-dot" />}
              </button>
            );
          })}
        </nav>

        <div className="sidebar-bottom">
          <div className="secure-note">
            <ShieldCheck size={17} />
            <div>
              <b>Secure workspace</b>
              <span>Administrator access</span>
            </div>
          </div>
          <button className="nav-link logout-link" onClick={logout}>
            <LogOut size={18} />
            <span>Sign out</span>
          </button>
        </div>
      </aside>

      {/* Scrim for Mobile Sidebar */}
      {mobileOpen && (
        <button
          className="mobile-scrim"
          aria-label="Close menu"
          onClick={() => setMobileOpen(false)}
        />
      )}

      {/* Main Area */}
      <main className="main-area">
        <header className="topbar">
          <button
            className="icon-btn menu-toggle"
            onClick={() => setMobileOpen(true)}
            aria-label="Open menu"
          >
            <Menu size={20} />
          </button>

          <div className="crumb">
            Arada Subcity <span>/</span>{" "}
            <b>{links.find((x) => x.id === page)?.label || "Overview"}</b>
          </div>

          <div className="topbar-right">
            <div className="system-status">
              <i /> API workspace
            </div>
            <div className="user-chip">
              <div className="avatar">
                {(user?.name || "A").slice(0, 1).toUpperCase()}
              </div>
              <div>
                <b>{user?.name || "Administrator"}</b>
                <span>Administrator</span>
              </div>
              <ChevronDown size={15} />
            </div>
          </div>
        </header>

        <div className="page-content">{children}</div>

        <footer className="footer">
          <span>AradaDgaf · IT Service Management</span>
          <span>Administrator portal</span>
        </footer>

        {/* Mobile Sticky Bottom Navigation (< 768px) */}
        <nav className="mobile-bottom-nav" aria-label="Bottom navigation">
          {mobileBottomNavItems.map((item) => {
            const Icon = item.icon;
            const isMoreActive =
              item.id === "more" && ["staff", "resources", "audit"].includes(page);
            const isActive = page === item.id || isMoreActive;
            return (
              <button
                key={item.id}
                className={`bottom-nav-btn ${isActive ? "active" : ""}`}
                onClick={() => handleNavClick(item.id)}
              >
                <div className="bottom-nav-icon-wrap">
                  <Icon size={20} />
                  {item.badge && pendingApprovalsCount > 0 && (
                    <span className="bottom-nav-badge">{pendingApprovalsCount}</span>
                  )}
                </div>
                <span>{item.label}</span>
              </button>
            );
          })}
        </nav>
      </main>

      {/* More Options Bottom Sheet (< 768px) */}
      {moreSheetOpen && (
        <div
          className="modal-backdrop"
          onMouseDown={(e) => e.target === e.currentTarget && setMoreSheetOpen(false)}
        >
          <div className="modal-card modal-bottom-sheet more-sheet">
            <div className="modal-heading">
              <div>
                <div className="eyebrow">ADMINISTRATION</div>
                <h2>More Options</h2>
              </div>
              <button
                type="button"
                className="icon-btn"
                onClick={() => setMoreSheetOpen(false)}
              >
                <X size={19} />
              </button>
            </div>

            <div className="more-menu-list">
              <button
                className={`more-menu-item ${page === "staff" ? "active" : ""}`}
                onClick={() => handleNavClick("staff")}
              >
                <Users size={20} />
                <div style={{ textAlign: "left", flex: 1 }}>
                  <b>People & access</b>
                  <small>Manage support staff and administrator accounts</small>
                </div>
              </button>

              <button
                className={`more-menu-item ${page === "resources" ? "active" : ""}`}
                onClick={() => handleNavClick("resources")}
              >
                <Boxes size={20} />
                <div style={{ textAlign: "left", flex: 1 }}>
                  <b>Departments & categories</b>
                  <small>Service categories, units, and request routing</small>
                </div>
              </button>

              <button
                className={`more-menu-item ${page === "audit" ? "active" : ""}`}
                onClick={() => handleNavClick("audit")}
              >
                <Activity size={20} />
                <div style={{ textAlign: "left", flex: 1 }}>
                  <b>Audit activity</b>
                  <small>Security logs and administrative actions</small>
                </div>
              </button>

              <div className="divider" style={{ margin: "10px 0" }} />

              <button
                className="more-menu-item danger-item"
                onClick={() => {
                  setMoreSheetOpen(false);
                  logout();
                }}
              >
                <LogOut size={20} />
                <div style={{ textAlign: "left", flex: 1 }}>
                  <b>Sign out</b>
                  <small>End this administrative session</small>
                </div>
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
