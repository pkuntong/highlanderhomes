import { createContext, useContext, useEffect, useMemo, useState } from "react";
import {
  changePassword,
  clearSession,
  loadSession,
  requestPasswordReset,
  resendEmailCode,
  saveSession,
  signInWithEmail,
  signUpWithEmail,
  verifyEmailCode,
} from "@/services/authService";

const AuthContext = createContext(undefined);

export function AuthProvider({ children }) {
  const [session, setSession] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const storedSession = loadSession();
    setSession(storedSession);
    setLoading(false);
  }, []);

  const login = async (email, password) => {
    const nextSession = await signInWithEmail(email, password);
    setSession(nextSession);
    return nextSession;
  };

  const signup = async ({ name, email, password }) => {
    return signUpWithEmail({ name, email, password });
  };

  const verifyEmail = async ({ email, code }) => {
    const nextSession = await verifyEmailCode({ email, code });
    setSession(nextSession);
    return nextSession;
  };

  const sendVerificationEmail = async (email) => {
    return resendEmailCode(email);
  };

  const resetPassword = async (email) => {
    return requestPasswordReset(email);
  };

  const updatePassword = async ({ email, currentPassword, newPassword }) => {
    return changePassword({ email, currentPassword, newPassword });
  };

  const logout = async () => {
    clearSession();
    setSession(null);
  };

  const refreshSession = (nextSession) => {
    const candidate = {
      token: nextSession?.token || session?.token,
      user: nextSession?.user || session?.user,
    };
    const stored = saveSession(candidate);
    setSession(stored);
    return stored;
  };

  const value = useMemo(
    () => ({
      currentUser: session?.user ?? null,
      token: session?.token ?? null,
      isAuthenticated: Boolean(session?.user),
      loading,
      login,
      logout,
      signup,
      verifyEmail,
      sendVerificationEmail,
      resetPassword,
      updatePassword,
      refreshSession,
    }),
    [loading, session]
  );
  
  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
}
