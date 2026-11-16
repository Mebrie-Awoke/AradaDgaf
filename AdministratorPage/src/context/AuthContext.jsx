import { createContext, useContext, useEffect, useMemo, useState } from "react";
import { apiRequest, unwrap } from "../api/client";

const AuthContext = createContext(null);
const STORAGE_KEY = "aradadgaf.admin.session";

export function AuthProvider({ children }) {
  const [session, setSession] = useState(() => {
    try { return JSON.parse(localStorage.getItem(STORAGE_KEY) || "null"); } catch { return null; }
  });
  const [checking, setChecking] = useState(Boolean(session?.token));

  useEffect(() => {
    let active = true;
    async function verify() {
      if (!session?.token) { setChecking(false); return; }
      try {
        const result = unwrap(await apiRequest("/v1/dashboard/", { token: session.token }));
        if (!active || !result) return;
      } catch {
        if (active) { localStorage.removeItem(STORAGE_KEY); setSession(null); }
      } finally { if (active) setChecking(false); }
    }
    verify();
    return () => { active = false; };
  }, []);

  async function login(email, password) {
    const data = unwrap(await apiRequest("/v1/auth/login/", { method: "POST", body: { email, password } }));
    if (data.user?.role !== "admin") throw new Error("This portal is restricted to administrator accounts.");
    const next = { token: data.access_token, user: data.user };
    localStorage.setItem(STORAGE_KEY, JSON.stringify(next));
    setSession(next);
    return next;
  }

  async function logout() {
    const token = session?.token;
    localStorage.removeItem(STORAGE_KEY);
    setSession(null);
    if (token) { try { await apiRequest("/v1/auth/logout/", { token, method: "POST" }); } catch { /* local session is already cleared */ } }
  }

  const value = useMemo(() => ({ session, user: session?.user, token: session?.token, checking, login, logout }), [session, checking]);
  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}
export const useAuth = () => useContext(AuthContext);