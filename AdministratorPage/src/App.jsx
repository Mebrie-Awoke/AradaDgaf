import { useState, useEffect, useCallback } from "react";
import { useAuth } from "./context/AuthContext";
import { apiRequest, unwrap } from "./api/client";
import Shell from "./components/Shell";
import LoginPage from "./pages/LoginPage";
import DashboardPage from "./pages/DashboardPage";
import AssignmentDeskPage from "./pages/AssignmentDeskPage";
import ApprovalsPage from "./pages/ApprovalsPage";
import TicketsPage from "./pages/TicketsPage";
import UsersPage from "./pages/UsersPage";
import ResourcesPage from "./pages/ResourcesPage";
import AuditPage from "./pages/AuditPage";

export default function App() {
  const { session, checking, token } = useAuth();
  const [page, setPage] = useState("dashboard");
  const [pendingApprovalsCount, setPendingApprovalsCount] = useState(0);

  const refreshPendingCount = useCallback(async () => {
    if (!token) return;
    try {
      const res = await apiRequest("/v1/registrations/?status=pending&page_size=100", { token });
      const items = unwrap(res) || [];
      setPendingApprovalsCount(items.length);
    } catch (_) {
      // Ignore background poll errors
    }
  }, [token]);

  useEffect(() => {
    refreshPendingCount();
    const interval = setInterval(refreshPendingCount, 20000);
    return () => clearInterval(interval);
  }, [refreshPendingCount]);

  if (checking) {
    return (
      <div className="boot-screen">
        <div className="brand-mark">A</div>
        <span>Checking secure session…</span>
      </div>
    );
  }

  if (!session) return <LoginPage />;

  let content;
  switch (page) {
    case "assignment":
      content = <AssignmentDeskPage />;
      break;
    case "approvals":
      content = (
        <ApprovalsPage
          onBadgeUpdate={(count) => {
            setPendingApprovalsCount(count);
          }}
        />
      );
      break;
    case "tickets":
      content = <TicketsPage />;
      break;
    case "staff":
      content = <UsersPage />;
      break;
    case "resources":
      content = <ResourcesPage />;
      break;
    case "audit":
      content = <AuditPage />;
      break;
    default:
      content = <DashboardPage go={setPage} />;
  }

  return (
    <Shell
      page={page}
      setPage={setPage}
      pendingApprovalsCount={pendingApprovalsCount}
      refreshPendingCount={refreshPendingCount}
    >
      {content}
    </Shell>
  );
}
