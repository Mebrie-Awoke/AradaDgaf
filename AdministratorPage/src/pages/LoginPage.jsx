import { ArrowRight, Eye, EyeOff, LockKeyhole, Mail, ShieldCheck } from "lucide-react";
import { useState } from "react";
import { useAuth } from "../context/AuthContext";

export default function LoginPage() {
  const { login } = useAuth();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [visible, setVisible] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  async function submit(e) {
    e.preventDefault(); setError(""); setBusy(true);
    try { await login(email.trim(), password); } catch (err) { setError(err.message || "Unable to sign in."); }
    finally { setBusy(false); }
  }
  return <div className="login-screen"><div className="login-decoration"><div className="deco-orb orb-one"/><div className="deco-orb orb-two"/><div className="login-brand"><div className="brand-mark">A</div><span>ARADA SUBCITY · DIGITAL SERVICES</span></div><div className="login-message"><div className="eyebrow light">IT SERVICE MANAGEMENT</div><h1>One place to keep<br/>your services moving.</h1><p>Manage requests, coordinate IT teams, and keep every department connected.</p><div className="login-feature"><ShieldCheck size={19}/><span>Protected administrator workspace</span></div></div><div className="login-bottom">ARADADGAF <span>·</span> SUPPORT OPERATIONS</div></div>
    <div className="login-panel"><form className="login-card" onSubmit={submit}><div className="login-icon"><LockKeyhole size={22}/></div><div className="eyebrow">WELCOME BACK</div><h2>Administrator sign in</h2><p className="muted">Use your provisioned administrator account to continue.</p>
      <label>Email address</label><div className="input-wrap"><Mail size={17}/><input type="email" value={email} onChange={e=>setEmail(e.target.value)} placeholder="admin@organization.gov.et" autoComplete="username" required/></div>
      <label>Password</label><div className="input-wrap"><LockKeyhole size={17}/><input type={visible ? "text" : "password"} value={password} onChange={e=>setPassword(e.target.value)} placeholder="Enter your password" autoComplete="current-password" required/><button type="button" className="reveal" onClick={()=>setVisible(!visible)}>{visible ? <EyeOff size={17}/> : <Eye size={17}/>}</button></div>
      {error && <div className="form-error">{error}</div>}<button className="primary-btn login-submit" disabled={busy}>{busy ? "Signing in…" : "Sign in to portal"} <ArrowRight size={17}/></button><div className="login-security"><ShieldCheck size={15}/> Secure access · Administrator accounts only</div>
    </form></div></div>;
}