import { v } from "convex/values";
import { action, internalMutation, internalQuery } from "./_generated/server";
import { internal } from "./_generated/api";

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
    // Note: In production, you should use Convex Auth or a proper auth provider
    // This is a simplified version for demonstration
    
    // Check if user already exists
    const existingUser = await ctx.runQuery(internal.auth.findUserByEmail, {
      email: args.email,
    });

    if (existingUser) {
      throw new Error("User with this email already exists");
    }

    // Create user (in production, hash password properly)
    const userId = await ctx.runMutation(internal.auth.createUser, {
      email: args.email,
      name: args.name,
    });

    // Generate a simple token (in production, use proper JWT)
    const token = `token_${userId}_${Date.now()}`;

    // Get user data
    const user = await ctx.runQuery(internal.auth.getUser, { userId });

    return {
      token,
      user,
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
    // Find user by email
    const user = await ctx.runQuery(internal.auth.findUserByEmail, {
      email: args.email,
    });

    if (!user) {
      throw new Error("Invalid email or password");
    }

    // In production, verify password hash here
    // For now, we'll just check if user exists

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
    // In production, verify Apple identity token here
    // For now, we'll create or find user by email

    let user = await ctx.runQuery(internal.auth.findUserByEmail, {
      email: args.email,
    });

    if (!user) {
      // Create new user
      const userId = await ctx.runMutation(internal.auth.createUser, {
        email: args.email,
        name: args.name || "Apple User",
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
        createdAt: user.createdAt,
        lastLoginAt: Date.now(),
      },
    };
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
    return await ctx.db
      .query("users")
      .withIndex("by_email", (q) => q.eq("email", args.email))
      .first();
  },
});

export const createUser = internalMutation({
  args: {
    email: v.string(),
    name: v.string(),
  },
  handler: async (ctx, args) => {
    const userId = await ctx.db.insert("users", {
      name: args.name,
      email: args.email,
      isPremium: false,
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
      createdAt: user.createdAt,
      lastLoginAt: user.lastLoginAt,
    };
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
