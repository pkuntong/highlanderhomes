import { v } from "convex/values";
import { action, internalMutation, internalQuery } from "./_generated/server";
import { internal } from "./_generated/api";
import { createHash, randomBytes } from "crypto";

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
    if (!email) {
      throw new Error("Apple Sign-In did not provide an email. Please use email sign-in.");
    }
    if (!validateEmail(email)) {
      throw new Error("Please enter a valid email address.");
    }

    // Note: In production, you should use Convex Auth or a proper auth provider
    // This is a simplified version for demonstration
    
    // Check if user already exists
    const existingUser = await ctx.runQuery(internal.auth.findUserByEmail, {
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

    const userId = await ctx.runMutation(internal.auth.createUser, {
      email,
      name: args.name,
      passwordHash,
      passwordSalt: salt,
      emailVerified: false,
    });

    const verificationCode = generateVerificationCode();
    const expiresAt = Date.now() + VERIFICATION_CODE_TTL_MS;
    await ctx.runMutation(internal.auth.setEmailVerification, {
      userId,
      code: verificationCode,
      expiresAt,
    });

    let verificationSent = false;
    try {
      await sendVerificationEmailViaResend(email, verificationCode);
      verificationSent = true;
    } catch (error) {
      console.warn("Verification email failed:", error);
    }

    // Generate a simple token (in production, use proper JWT)
    const token = `token_${userId}_${Date.now()}`;

    // Get user data
    const user = await ctx.runQuery(internal.auth.getUser, { userId });

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
    const user = await ctx.runQuery(internal.auth.findUserByEmail, {
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
    await ctx.runMutation(internal.auth.updateLastLogin, {
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
      ? await ctx.runQuery(internal.auth.findUserByEmail, { email })
      : null;

    if (!user) {
      // Create new user
      const userId = await ctx.runMutation(internal.auth.createUser, {
        email,
        name: args.name || "Apple User",
        emailVerified: true,
      });
      user = await ctx.runQuery(internal.auth.getUser, { userId });
    } else {
      // Update last login
      await ctx.runMutation(internal.auth.updateLastLogin, {
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

    const user = await ctx.runQuery(internal.auth.findUserByEmail, { email });
    if (!user) {
      throw new Error("User not found");
    }

    const code = generateVerificationCode();
    const expiresAt = Date.now() + VERIFICATION_CODE_TTL_MS;

    await ctx.runMutation(internal.auth.setEmailVerification, {
      userId: user._id,
      code,
      expiresAt,
    });

    await sendVerificationEmailViaResend(email, code);
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

    const user = await ctx.runQuery(internal.auth.findUserByEmail, { email });
    if (!user) {
      throw new Error("User not found");
    }

    if (user.emailVerified) {
      return await ctx.runQuery(internal.auth.getUser, { userId: user._id });
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

    await ctx.runMutation(internal.auth.markEmailVerified, {
      userId: user._id,
    });

    return await ctx.runQuery(internal.auth.getUser, { userId: user._id });
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
    const user = await ctx.runQuery(internal.auth.findUserByEmail, {
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

// Internal functions
export const findUserByEmail = internalQuery({
  args: { email: v.string() },
  handler: async (ctx, args) => {
    const email = normalizeEmail(args.email);
    return await ctx.db
      .query("users")
      .withIndex("by_email", (q) => q.eq("email", email))
      .first();
  },
});

export const createUser = internalMutation({
  args: {
    email: v.string(),
    name: v.string(),
    passwordHash: v.optional(v.string()),
    passwordSalt: v.optional(v.string()),
    emailVerified: v.optional(v.boolean()),
    emailVerificationCode: v.optional(v.string()),
    emailVerificationExpiresAt: v.optional(v.number()),
  },
  handler: async (ctx, args) => {
    const userId = await ctx.db.insert("users", {
      name: args.name,
      email: args.email,
      isPremium: false,
      passwordHash: args.passwordHash,
      passwordSalt: args.passwordSalt,
      emailVerified: args.emailVerified ?? false,
      emailVerificationCode: args.emailVerificationCode,
      emailVerificationExpiresAt: args.emailVerificationExpiresAt,
      createdAt: Date.now(),
    });
    return userId;
  },
});

export const getUser = internalQuery({
  args: { userId: v.id("users") },
  handler: async (ctx, args) => {
    const user = await ctx.db.get(args.userId);
    if (!user) {
      throw new Error("User not found");
    }
    return {
      _id: user._id,
      name: user.name,
      email: user.email,
      avatarURL: user.avatarURL,
      isPremium: user.isPremium,
      emailVerified: user.emailVerified,
      createdAt: user.createdAt,
      lastLoginAt: user.lastLoginAt,
    };
  },
});

export const setEmailVerification = internalMutation({
  args: {
    userId: v.id("users"),
    code: v.string(),
    expiresAt: v.number(),
  },
  handler: async (ctx, args) => {
    await ctx.db.patch(args.userId, {
      emailVerificationCode: args.code,
      emailVerificationExpiresAt: args.expiresAt,
    });
  },
});

export const markEmailVerified = internalMutation({
  args: {
    userId: v.id("users"),
  },
  handler: async (ctx, args) => {
    await ctx.db.patch(args.userId, {
      emailVerified: true,
      emailVerificationCode: undefined,
      emailVerificationExpiresAt: undefined,
    });
  },
});

export const updateLastLogin = internalMutation({
  args: { userId: v.id("users") },
  handler: async (ctx, args) => {
    await ctx.db.patch(args.userId, {
      lastLoginAt: Date.now(),
    });
  },
});
