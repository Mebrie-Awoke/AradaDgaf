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

  async function submit(event) {
    event.preventDefault();
    setError("");
    setBusy(true);
    try {
      await login(email.trim(), password);
    } catch (err) {
      setError(err.message || "Unable to sign in. Please try again.");
    } finally {
      setBusy(false);
    }
  }

  return <div className="login-screen">
    <div className="login-decoration">
      <div className="deco-orb orb-one"/><div className="deco-orb orb-two"/>
      <div className="login-brand"><div className="brand-mark">A</div><span>ARADA SUBCITY · DIGITAL SERVICES</span></div>
      <div className="login-message">
        <div className="eyebrow light">IT SERVICE MANAGEMENT</div>
        <h1>One place to keep<br/>your services moving.</h1>
        <p>Manage service requests, coordinate IT teams, and support departments through one secure workspace.</p>
        <div className="login-feature"><ShieldCheck size={19}/><span>Protected administrator workspace</span></div>
      </div>
      <div className="login-bottom">ARADADGAF <span>·</span> SUPPORT OPERATIONS</div>
    </div>

    <div className="login-panel">
      <form className="login-card" onSubmit={submit}>
        <div className="login-icon"><LockKeyhole size={22}/></div>
        <div className="eyebrow">ADMINISTRATOR ACCESS</div>
        <h2>Sign in to AradaDgaf</h2>
        <p className="muted">Use your provisioned administrator account to continue.</p>
        <label htmlFor="admin-email">Email address</label>
        <div className="input-wrap"><Mail size={17}/><input id="admin-email" type="email" value={email}
          onChange={(event) => setEmail(event.target.value)} placeholder="Enter your administrator email"
          autoComplete="username" required/></div>
        <label htmlFor="admin-password">Password</label>
        <div className="input-wrap"><LockKeyhole size={17}/><input id="admin-password" type={visible ? "text" : "password"}
          value={password} onChange={(event) => setPassword(event.target.value)}
          placeholder="Enter your password" autoComplete="current-password" required/>
          <button type="button" className="reveal" onClick={() => setVisible((value) => !value)}
            aria-label={visible ? "Hide password" : "Show password"}>
            {visible ? <EyeOff size={17}/> : <Eye size={17}/>}
          </button>
        </div>
        {error && <div className="form-error" role="alert">{error}</div>}
        <button className="primary-btn login-submit" disabled={busy}>
          {busy ? "Signing in…" : "Sign in"} <ArrowRight size={17}/>
        </button>
        <div className="login-security"><ShieldCheck size={15}/> Secure access · Administrator accounts only</div>
      </form>
    </div>
  </div>;
}
