import { useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { AlertCircle, CheckCircle2, Mail, ShieldCheck } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { useAuth } from "@/contexts/AuthContext";

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function getErrorMessage(error, fallback) {
  const raw = error?.data?.message || error?.message || fallback;
  return String(raw).replace(/^Uncaught Error:\s*/, "");
}

export default function Login() {
  const navigate = useNavigate();
  const {
    isAuthenticated,
    login,
    signup,
    verifyEmail,
    sendVerificationEmail,
    resetPassword,
  } = useAuth();

  const [mode, setMode] = useState("signin");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [pendingEmail, setPendingEmail] = useState("");

  const [signInForm, setSignInForm] = useState({ email: "", password: "" });
  const [signUpForm, setSignUpForm] = useState({
    name: "",
    email: "",
    password: "",
    confirmPassword: "",
  });
  const [verifyForm, setVerifyForm] = useState({ email: "", code: "" });
  const [resetEmail, setResetEmail] = useState("");

  useEffect(() => {
    if (isAuthenticated) {
      navigate("/dashboard");
    }
  }, [isAuthenticated, navigate]);

  const heading = useMemo(() => {
    if (mode === "signup") return "Create account";
    if (mode === "verify") return "Verify email";
    if (mode === "reset") return "Reset password";
    return "Sign in";
  }, [mode]);

  async function handleSignIn(event) {
    event.preventDefault();
    setLoading(true);
    setError("");
    setSuccess("");
    try {
      await login(signInForm.email.trim(), signInForm.password);
      navigate("/dashboard");
    } catch (nextError) {
      setError(getErrorMessage(nextError, "Sign in failed."));
    } finally {
      setLoading(false);
    }
  }

  async function handleSignUp(event) {
    event.preventDefault();
    setLoading(true);
    setError("");
    setSuccess("");

    try {
      const trimmedEmail = signUpForm.email.trim();
      if (!signUpForm.name.trim()) {
        throw new Error("Name is required.");
      }
      if (!EMAIL_PATTERN.test(trimmedEmail)) {
        throw new Error("Enter a valid email.");
      }
      if (signUpForm.password !== signUpForm.confirmPassword) {
        throw new Error("Passwords do not match.");
      }

      const result = await signup({
        name: signUpForm.name.trim(),
        email: trimmedEmail,
        password: signUpForm.password,
      });

      setPendingEmail(trimmedEmail);
      setVerifyForm({ email: trimmedEmail, code: "" });
      if (result?.verificationSent) {
        setSuccess("Account created. Enter the 6-digit verification code from your email.");
      } else {
        setSuccess("Account created. Email delivery is not configured yet, so request code from admin/Convex logs.");
      }
      setMode("verify");
    } catch (nextError) {
      setError(getErrorMessage(nextError, "Sign up failed."));
    } finally {
      setLoading(false);
    }
  }

  async function handleVerify(event) {
    event.preventDefault();
    setLoading(true);
    setError("");
    setSuccess("");
    try {
      const payload = {
        email: verifyForm.email.trim(),
        code: verifyForm.code.trim(),
      };
      await verifyEmail(payload);
      setSuccess("Email verified. You are now signed in.");
      navigate("/dashboard");
    } catch (nextError) {
      setError(getErrorMessage(nextError, "Verification failed."));
    } finally {
      setLoading(false);
    }
  }

  async function handleResendCode() {
    setLoading(true);
    setError("");
    setSuccess("");
    try {
      const email = verifyForm.email.trim() || pendingEmail;
      if (!email) {
        throw new Error("Enter your email first.");
      }
      await sendVerificationEmail(email);
      setSuccess("Verification code sent.");
    } catch (nextError) {
      setError(getErrorMessage(nextError, "Failed to resend verification code."));
    } finally {
      setLoading(false);
    }
  }

  async function handleReset(event) {
    event.preventDefault();
    setLoading(true);
    setError("");
    setSuccess("");
    try {
      const email = resetEmail.trim();
      if (!EMAIL_PATTERN.test(email)) {
        throw new Error("Enter a valid email.");
      }
      await resetPassword(email);
      setSuccess("If this account exists, a reset flow was triggered.");
    } catch (nextError) {
      setError(getErrorMessage(nextError, "Reset request failed."));
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-slate-100 to-white dark:from-slate-950 dark:to-slate-900 flex items-center justify-center px-4 py-10">
      <div className="w-full max-w-5xl grid md:grid-cols-2 gap-6">
        <Card className="border-0 shadow-xl">
          <CardHeader className="space-y-3">
            <img
              src="/HH Logo.png"
              alt="Highlander Homes"
              className="h-12 w-auto object-contain"
            />
            <CardTitle className="text-2xl">Highlander Homes Web</CardTitle>
            <p className="text-sm text-muted-foreground">
              Same account as iOS. Data syncs through Convex.
            </p>
          </CardHeader>
          <CardContent className="space-y-4 text-sm text-muted-foreground">
            <div className="flex items-start gap-3">
              <ShieldCheck className="h-4 w-4 mt-0.5 text-emerald-600" />
              <p>Use the same email and password from the iOS app.</p>
            </div>
            <div className="flex items-start gap-3">
              <Mail className="h-4 w-4 mt-0.5 text-blue-600" />
              <p>Email verification is required for new signups.</p>
            </div>
            <div className="flex items-start gap-3">
              <CheckCircle2 className="h-4 w-4 mt-0.5 text-violet-600" />
              <p>Phase 1 includes Dashboard, Properties, Maintenance, Finance, Contractors, and Profile.</p>
            </div>
          </CardContent>
        </Card>

        <Card className="shadow-xl">
          <CardHeader>
            <CardTitle>{heading}</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex gap-2 flex-wrap">
              <Button
                variant={mode === "signin" ? "default" : "outline"}
                size="sm"
                onClick={() => {
                  setMode("signin");
                  setError("");
                  setSuccess("");
                }}
                disabled={loading}
              >
                Sign in
              </Button>
              <Button
                variant={mode === "signup" ? "default" : "outline"}
                size="sm"
                onClick={() => {
                  setMode("signup");
                  setError("");
                  setSuccess("");
                }}
                disabled={loading}
              >
                Sign up
              </Button>
              <Button
                variant={mode === "verify" ? "default" : "outline"}
                size="sm"
                onClick={() => {
                  setMode("verify");
                  setError("");
                  setSuccess("");
                }}
                disabled={loading}
              >
                Verify email
              </Button>
              <Button
                variant={mode === "reset" ? "default" : "outline"}
                size="sm"
                onClick={() => {
                  setMode("reset");
                  setError("");
                  setSuccess("");
                }}
                disabled={loading}
              >
                Reset password
              </Button>
            </div>

            {error ? (
              <Alert variant="destructive">
                <AlertCircle className="h-4 w-4" />
                <AlertDescription>{error}</AlertDescription>
              </Alert>
            ) : null}

            {success ? (
              <Alert>
                <CheckCircle2 className="h-4 w-4" />
                <AlertDescription>{success}</AlertDescription>
              </Alert>
            ) : null}

            {mode === "signin" ? (
              <form className="space-y-3" onSubmit={handleSignIn}>
                <div className="space-y-1">
                  <Label htmlFor="signin-email">Email</Label>
                  <Input
                    id="signin-email"
                    type="email"
                    value={signInForm.email}
                    onChange={(event) =>
                      setSignInForm((prev) => ({ ...prev, email: event.target.value }))
                    }
                    required
                  />
                </div>
                <div className="space-y-1">
                  <Label htmlFor="signin-password">Password</Label>
                  <Input
                    id="signin-password"
                    type="password"
                    value={signInForm.password}
                    onChange={(event) =>
                      setSignInForm((prev) => ({ ...prev, password: event.target.value }))
                    }
                    required
                  />
                </div>
                <Button type="submit" className="w-full" disabled={loading}>
                  {loading ? "Signing in..." : "Sign in"}
                </Button>
              </form>
            ) : null}

            {mode === "signup" ? (
              <form className="space-y-3" onSubmit={handleSignUp}>
                <div className="space-y-1">
                  <Label htmlFor="signup-name">Name</Label>
                  <Input
                    id="signup-name"
                    value={signUpForm.name}
                    onChange={(event) =>
                      setSignUpForm((prev) => ({ ...prev, name: event.target.value }))
                    }
                    required
                  />
                </div>
                <div className="space-y-1">
                  <Label htmlFor="signup-email">Email</Label>
                  <Input
                    id="signup-email"
                    type="email"
                    value={signUpForm.email}
                    onChange={(event) =>
                      setSignUpForm((prev) => ({ ...prev, email: event.target.value }))
                    }
                    required
                  />
                </div>
                <div className="space-y-1">
                  <Label htmlFor="signup-password">Password</Label>
                  <Input
                    id="signup-password"
                    type="password"
                    value={signUpForm.password}
                    onChange={(event) =>
                      setSignUpForm((prev) => ({ ...prev, password: event.target.value }))
                    }
                    required
                  />
                </div>
                <div className="space-y-1">
                  <Label htmlFor="signup-confirm-password">Confirm password</Label>
                  <Input
                    id="signup-confirm-password"
                    type="password"
                    value={signUpForm.confirmPassword}
                    onChange={(event) =>
                      setSignUpForm((prev) => ({ ...prev, confirmPassword: event.target.value }))
                    }
                    required
                  />
                </div>
                <Button type="submit" className="w-full" disabled={loading}>
                  {loading ? "Creating account..." : "Create account"}
                </Button>
              </form>
            ) : null}

            {mode === "verify" ? (
              <form className="space-y-3" onSubmit={handleVerify}>
                <div className="space-y-1">
                  <Label htmlFor="verify-email">Email</Label>
                  <Input
                    id="verify-email"
                    type="email"
                    value={verifyForm.email}
                    onChange={(event) =>
                      setVerifyForm((prev) => ({ ...prev, email: event.target.value }))
                    }
                    required
                  />
                </div>
                <div className="space-y-1">
                  <Label htmlFor="verify-code">Verification code</Label>
                  <Input
                    id="verify-code"
                    inputMode="numeric"
                    value={verifyForm.code}
                    onChange={(event) =>
                      setVerifyForm((prev) => ({ ...prev, code: event.target.value }))
                    }
                    required
                  />
                </div>
                <div className="flex gap-2">
                  <Button type="submit" className="flex-1" disabled={loading}>
                    {loading ? "Verifying..." : "Verify"}
                  </Button>
                  <Button
                    type="button"
                    variant="outline"
                    className="flex-1"
                    onClick={handleResendCode}
                    disabled={loading}
                  >
                    Resend code
                  </Button>
                </div>
              </form>
            ) : null}

            {mode === "reset" ? (
              <form className="space-y-3" onSubmit={handleReset}>
                <div className="space-y-1">
                  <Label htmlFor="reset-email">Email</Label>
                  <Input
                    id="reset-email"
                    type="email"
                    value={resetEmail}
                    onChange={(event) => setResetEmail(event.target.value)}
                    required
                  />
                </div>
                <Button type="submit" className="w-full" disabled={loading}>
                  {loading ? "Submitting..." : "Send reset request"}
                </Button>
              </form>
            ) : null}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
