import { v } from "convex/values";
import { internalMutation, internalQuery } from "./_generated/server";
import { isOwnerEmail, normalizeEmail as normalizeEmailHelper } from "./limits";

function normalizeEmail(email: string) {
  return normalizeEmailHelper(email);
}

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
    const normalizedEmail = normalizeEmail(args.email);
    const ownerAccount = isOwnerEmail(normalizedEmail);
    const userId = await ctx.db.insert("users", {
      name: args.name,
      email: normalizedEmail,
      isPremium: ownerAccount,
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

export const setPassword = internalMutation({
  args: {
    userId: v.id("users"),
    passwordHash: v.string(),
    passwordSalt: v.string(),
  },
  handler: async (ctx, args) => {
    await ctx.db.patch(args.userId, {
      passwordHash: args.passwordHash,
      passwordSalt: args.passwordSalt,
    });
  },
});
