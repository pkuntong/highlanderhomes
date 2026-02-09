/// <reference types="node" />
"use node";

import { v } from "convex/values";
import { action } from "./_generated/server";
import { internal } from "./_generated/api";
import { createHash, randomBytes } from "crypto";
import nodemailer from "nodemailer";

function hashPassword(password: string, salt: string) {
  return createHash("sha256").update(password + salt).digest("hex");
}

function validatePassword(password: string) {
  const hasLetter = /[A-Za-z]/.test(password);
  const hasNumber = /[0-9]/.test(password);
  return password.length >= 8 && hasLetter && hasNumber;
}

function normalizeEmail(email: string) {
  return email.trim().toLowerCase();
}

function validateEmail(email: string) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

const VERIFICATION_CODE_TTL_MS = 15 * 60 * 1000;

function generateVerificationCode() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

async function sendVerificationEmailViaResend(email: string, code: string) {
  const apiKey = process.env.RESEND_API_KEY;
  if (!apiKey) {
    throw new Error("Missing RESEND_API_KEY");
  }

  const from =
    process.env.RESEND_FROM_EMAIL || "Highlander Homes <onboarding@resend.dev>";
  const subject =
    process.env.RESEND_VERIFICATION_SUBJECT || "Verify your email";

  const html = `
    <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; line-height: 1.5;">
      <h2>Verify your email</h2>
      <p>Your verification code is:</p>
      <div style="font-size: 24px; font-weight: 700; letter-spacing: 2px;">${code}</div>
      <p>This code expires in 15 minutes.</p>
    </div>
  `;

  const res = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from,
      to: email,
      subject,
      html,
    }),
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`Resend error: ${body}`);
  }
}

async function sendVerificationEmailViaSMTP(email: string, code: string) {
  const host = process.env.SMTP_HOST;
  const port = Number(process.env.SMTP_PORT || "587");
  const user = process.env.SMTP_USER;
  const pass = process.env.SMTP_PASS;
  const from = process.env.SMTP_FROM || user;
  const secureEnv = process.env.SMTP_SECURE;
  const secure = secureEnv ? secureEnv === "true" : port === 465;

  if (!host || !user || !pass || !from) {
    throw new Error("Missing SMTP configuration");
  }

  const subject = process.env.SMTP_VERIFICATION_SUBJECT || "Verify your email";
  const html = `
    <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; line-height: 1.5;">
      <h2>Verify your email</h2>
      <p>Your verification code is:</p>
      <div style="font-size: 24px; font-weight: 700; letter-spacing: 2px;">${code}</div>
      <p>This code expires in 15 minutes.</p>
    </div>
  `;
  const text = `Your verification code is: ${code}\nThis code expires in 15 minutes.`;

  const transporter = nodemailer.createTransport({
    host,
    port,
    secure,
    auth: { user, pass },
  });

  await transporter.sendMail({
    from,
    to: email,
    subject,
    text,
    html,
  });
}

async function deliverVerificationEmail(email: string, code: string) {
  const smtpConfigured = !!(
    process.env.SMTP_HOST &&
    process.env.SMTP_USER &&
    process.env.SMTP_PASS
  );

  if (smtpConfigured) {
    await sendVerificationEmailViaSMTP(email, code);
    return;
  }

  if (process.env.RESEND_API_KEY) {
    await sendVerificationEmailViaResend(email, code);
    return;
  }

  throw new Error("Email delivery not configured");
}

/**
 * Sign up with email and password
 */
export const signUp = action({
  args: {
    email: v.string(),
    password: v.string(),
    name: v.string(),
  },
  handler: async (ctx, args) => {
    const email = normalizeEmail(args.email);
    if (!validateEmail(email)) {
      throw new Error("Please enter a valid email address.");
    }

    // Note: In production, you should use Convex Auth or a proper auth provider
    // This is a simplified version for demonstration
    
    // Check if user already exists
    const existingUser = await ctx.runQuery(internal.authInternal.findUserByEmail, {
      email,
    });

    if (existingUser) {
      throw new Error("User with this email already exists");
    }

    if (!validatePassword(args.password)) {
      throw new Error("Password must be at least 8 characters and include letters and numbers.");
    }

    const salt = randomBytes(16).toString("hex");
    const passwordHash = hashPassword(args.password, salt);

    const userId = await ctx.runMutation(internal.authInternal.createUser, {
      email,
      name: args.name,
      passwordHash,
      passwordSalt: salt,
      emailVerified: false,
    });

    const verificationCode = generateVerificationCode();
    const expiresAt = Date.now() + VERIFICATION_CODE_TTL_MS;
    await ctx.runMutation(internal.authInternal.setEmailVerification, {
      userId,
      code: verificationCode,
      expiresAt,
    });

    let verificationSent = false;
    try {
      await deliverVerificationEmail(email, verificationCode);
      verificationSent = true;
    } catch (error) {
      console.warn("Verification email failed:", error);
    }

    // Generate a simple token (in production, use proper JWT)
    const token = `token_${userId}_${Date.now()}`;

    // Get user data
    const user = await ctx.runQuery(internal.authInternal.getUser, { userId });

    return {
      token,
      user,
      verificationSent,
    };
  },
});

/**
 * Sign in with email and password
 */
export const signIn = action({
  args: {
    email: v.string(),
    password: v.string(),
  },
  handler: async (ctx, args) => {
    const email = normalizeEmail(args.email);
    if (!validateEmail(email)) {
      throw new Error("Invalid email or password");
    }

    // Find user by email
    const user = await ctx.runQuery(internal.authInternal.findUserByEmail, {
      email,
    });

    if (!user) {
      throw new Error("Invalid email or password");
    }

    if (!user.passwordHash || !user.passwordSalt) {
      throw new Error("Password sign-in not enabled for this account.");
    }

    if (!user.emailVerified) {
      throw new Error("Please verify your email before signing in.");
    }

    const incomingHash = hashPassword(args.password, user.passwordSalt);
    if (incomingHash !== user.passwordHash) {
      throw new Error("Invalid email or password");
    }

    // Update last login
    await ctx.runMutation(internal.authInternal.updateLastLogin, {
      userId: user._id,
    });

    // Generate token
    const token = `token_${user._id}_${Date.now()}`;

    return {
      token,
      user: {
        _id: user._id,
        name: user.name,
        email: user.email,
        avatarURL: user.avatarURL,
        isPremium: user.isPremium,
        emailVerified: user.emailVerified,
        createdAt: user.createdAt,
        lastLoginAt: Date.now(),
      },
    };
  },
});

/**
 * Sign in with Apple
 */
export const signInWithApple = action({
  args: {
    identityToken: v.string(),
    name: v.string(),
    email: v.string(),
  },
  handler: async (ctx, args) => {
    const email = normalizeEmail(args.email);

    // In production, verify Apple identity token here
    // For now, we'll create or find user by email

    let user = email
      ? await ctx.runQuery(internal.authInternal.findUserByEmail, { email })
      : null;

    if (!user) {
      // Create new user
      const userId = await ctx.runMutation(internal.authInternal.createUser, {
        email,
        name: args.name || "Apple User",
        emailVerified: true,
      });
      user = await ctx.runQuery(internal.authInternal.getUser, { userId });
    } else {
      // Update last login
      await ctx.runMutation(internal.authInternal.updateLastLogin, {
        userId: user._id,
      });
    }

    const token = `token_${user._id}_${Date.now()}`;

    return {
      token,
      user: {
        _id: user._id,
        name: user.name,
        email: user.email,
        avatarURL: user.avatarURL,
        isPremium: user.isPremium,
        emailVerified: true,
        createdAt: user.createdAt,
        lastLoginAt: Date.now(),
      },
    };
  },
});

/**
 * Send (or re-send) verification email
 */
export const sendVerificationEmail = action({
  args: {
    email: v.string(),
  },
  handler: async (ctx, args) => {
    const email = normalizeEmail(args.email);
    if (!validateEmail(email)) {
      throw new Error("Please enter a valid email address.");
    }

    const user = await ctx.runQuery(internal.authInternal.findUserByEmail, { email });
    if (!user) {
      throw new Error("User not found");
    }

    const code = generateVerificationCode();
    const expiresAt = Date.now() + VERIFICATION_CODE_TTL_MS;

    await ctx.runMutation(internal.authInternal.setEmailVerification, {
      userId: user._id,
      code,
      expiresAt,
    });

    await deliverVerificationEmail(email, code);
    return { success: true };
  },
});

/**
 * Verify email with code
 */
export const verifyEmail = action({
  args: {
    email: v.string(),
    code: v.string(),
  },
  handler: async (ctx, args) => {
    const email = normalizeEmail(args.email);
    if (!validateEmail(email)) {
      throw new Error("Please enter a valid email address.");
    }

    const user = await ctx.runQuery(internal.authInternal.findUserByEmail, { email });
    if (!user) {
      throw new Error("User not found");
    }

    if (user.emailVerified) {
      const verifiedUser = await ctx.runQuery(internal.authInternal.getUser, { userId: user._id });
      const token = `token_${user._id}_${Date.now()}`;
      return { token, user: verifiedUser };
    }

    if (!user.emailVerificationCode || !user.emailVerificationExpiresAt) {
      throw new Error("Verification code not found. Please request a new one.");
    }

    if (user.emailVerificationCode !== args.code) {
      throw new Error("Invalid verification code.");
    }

    if (Date.now() > user.emailVerificationExpiresAt) {
      throw new Error("Verification code expired. Please request a new one.");
    }

    await ctx.runMutation(internal.authInternal.markEmailVerified, {
      userId: user._id,
    });

    const verifiedUser = await ctx.runQuery(internal.authInternal.getUser, { userId: user._id });
    const token = `token_${user._id}_${Date.now()}`;
    return { token, user: verifiedUser };
  },
});

/**
 * Change password for an email/password account
 */
export const changePassword = action({
  args: {
    email: v.string(),
    currentPassword: v.string(),
    newPassword: v.string(),
  },
  handler: async (ctx, args) => {
    const email = normalizeEmail(args.email);
    if (!validateEmail(email)) {
      throw new Error("Please enter a valid email address.");
    }

    const user = await ctx.runQuery(internal.authInternal.findUserByEmail, { email });
    if (!user) {
      throw new Error("Invalid email or password");
    }

    if (!user.passwordHash || !user.passwordSalt) {
      throw new Error("Password sign-in not enabled for this account.");
    }

    const incomingHash = hashPassword(args.currentPassword, user.passwordSalt);
    if (incomingHash !== user.passwordHash) {
      throw new Error("Current password is incorrect.");
    }

    if (!validatePassword(args.newPassword)) {
      throw new Error("Password must be at least 8 characters and include letters and numbers.");
    }

    const salt = randomBytes(16).toString("hex");
    const passwordHash = hashPassword(args.newPassword, salt);

    await ctx.runMutation(internal.authInternal.setPassword, {
      userId: user._id,
      passwordHash,
      passwordSalt: salt,
    });

    return { success: true };
  },
});

/**
 * Force-verify an email (admin use)
 */
export const forceVerifyEmail = action({
  args: {
    email: v.string(),
  },
  handler: async (ctx, args) => {
    const email = normalizeEmail(args.email);
    if (!validateEmail(email)) {
      throw new Error("Please enter a valid email address.");
    }

    const user = await ctx.runQuery(internal.authInternal.findUserByEmail, { email });
    if (!user) {
      throw new Error("User not found");
    }

    await ctx.runMutation(internal.authInternal.markEmailVerified, {
      userId: user._id,
    });

    return await ctx.runQuery(internal.authInternal.getUser, { userId: user._id });
  },
});

/**
 * Force set password for an email (admin use)
 */
export const forceSetPassword = action({
  args: {
    email: v.string(),
    password: v.string(),
  },
  handler: async (ctx, args) => {
    const email = normalizeEmail(args.email);
    if (!validateEmail(email)) {
      throw new Error("Please enter a valid email address.");
    }
    if (!validatePassword(args.password)) {
      throw new Error("Password must be at least 8 characters and include letters and numbers.");
    }

    const user = await ctx.runQuery(internal.authInternal.findUserByEmail, { email });
    if (!user) {
      throw new Error("User not found");
    }

    const salt = randomBytes(16).toString("hex");
    const passwordHash = hashPassword(args.password, salt);

    await ctx.runMutation(internal.authInternal.setPassword, {
      userId: user._id,
      passwordHash,
      passwordSalt: salt,
    });

    return await ctx.runQuery(internal.authInternal.getUser, { userId: user._id });
  },
});

/**
 * Reset password
 */
export const resetPassword = action({
  args: {
    email: v.string(),
  },
  handler: async (ctx, args) => {
    const user = await ctx.runQuery(internal.authInternal.findUserByEmail, {
      email: args.email,
    });

    if (!user) {
      // Don't reveal if user exists for security
      return { success: true };
    }

    // In production, send password reset email here
    // For now, just return success

    return { success: true };
  },
});
