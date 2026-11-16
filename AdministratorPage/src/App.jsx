import { useState } from "react";
import { useAuth } from "./context/AuthContext";
import Shell from "./components/Shell";
import LoginPage from "./pages/LoginPage";
import DashboardPage from "./pages/DashboardPage";
import TicketsPage from "./pages/TicketsPage";
import UsersPage from "./pages/UsersPage";
import ResourcesPage from "./pages/ResourcesPage";
import AuditPage from "./pages/AuditPage";

export default function App(){
 const {session,checking}=useAuth();const [page,setPage]=useState("dashboard");
 if(checking)return <div className="boot-screen"><div className="brand-mark">A</div><span>Checking secure session…</span></div>;
 if(!session)return <LoginPage/>;
 let content;
 switch(page){case"tickets":content=<TicketsPage/>;break;case"staff":content=<UsersPage/>;break;case"resources":content=<ResourcesPage/>;break;case"audit":content=<AuditPage/>;break;default:content=<DashboardPage go={setPage}/>;}
 return <Shell page={page} setPage={setPage}>{content}</Shell>;
}