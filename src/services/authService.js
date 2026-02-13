import { api } from "../../convex/_generated/api";
import {
  runConvexAction,
} from "./convexClient";

const SESSION_STORAGE_KEY = "highlanderhomes_web_session";

function sanitizeSession(payload) {
  if (!payload?.user || !payload?.token) {
    return null;
  }
  return {
    token: payload.token,
    user: payload.user,
  };
}

export function loadSession() {
  try {
    const raw = localStorage.getItem(SESSION_STORAGE_KEY);
    if (!raw) {
      return null;
    }
    return sanitizeSession(JSON.parse(raw));
  } catch (error) {
    console.error("Failed to parse saved session:", error);
    return null;
  }
}

export function saveSession(session) {
  const sanitized = sanitizeSession(session);
  if (!sanitized) {
    return null;
  }
  localStorage.setItem(SESSION_STORAGE_KEY, JSON.stringify(sanitized));
  return sanitized;
}

export function clearSession() {
  localStorage.removeItem(SESSION_STORAGE_KEY);
}

export async function signInWithEmail(email, password) {
  const response = await runConvexAction(api.auth.signIn, {
    email,
    password,
  });
  return saveSession(response);
}

export async function signUpWithEmail({ name, email, password }) {
  return runConvexAction(api.auth.signUp, {
    name,
    email,
    password,
  });
}

export async function verifyEmailCode({ email, code }) {
  const response = await runConvexAction(api.auth.verifyEmail, {
    email,
    code,
  });
  return saveSession(response);
}

export async function resendEmailCode(email) {
  return runConvexAction(api.auth.sendVerificationEmail, { email });
}

export async function requestPasswordReset(email) {
  return runConvexAction(api.auth.resetPassword, { email });
}

export async function changePassword({ email, currentPassword, newPassword }) {
  return runConvexAction(api.auth.changePassword, {
    email,
    currentPassword,
    newPassword,
  });
}
