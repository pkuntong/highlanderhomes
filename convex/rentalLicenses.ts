import { v } from "convex/values";
import { mutation, query } from "./_generated/server";
import { internal } from "./_generated/api";

type RentalLicenseSeedInput = {
  propertyLabel: string;
  category: string;
  licenseNumber: string;
  dateFrom: string;
  dateTo: string;
  unitFees: string;
  link?: string;
  notes?: string;
};

const DEFAULT_RENTAL_LICENSES: RentalLicenseSeedInput[] = [
  {
    propertyLabel: "7304 Mayhill dr",
    category: "Montgomery County Rent License",
    licenseNumber: "142492",
    dateFrom: "7/1/2023",
    dateTo: "6/30/2026",
    unitFees: "$130",
    link: "https://ex11.montgomerycountymd.gov/ojn3/ijn17/DHCA-LicensingAndRegistration/License/List",
  },
  {
    propertyLabel: "3140 Ryerson Cir",
    category: "Baltimore County Rent License",
    licenseNumber: "RHR-2025-01242",
    dateFrom: "3/19/2025",
    dateTo: "3/8/2028",
    unitFees: "$60",
    link: "https://citizenaccess.baltimorecountymd.gov/CitizenAccess/Login.aspx",
  },
];

function normalizeEmail(email: string) {
  return email.trim().toLowerCase();
}

function normalizeLabel(label: string) {
  return label.toLowerCase().replace(/[^a-z0-9]/g, "");
}

function parseMoney(value: string) {
  const cleaned = value.replace(/[^0-9.]/g, "");
  const parsed = Number.parseFloat(cleaned);
  return Number.isNaN(parsed) ? 0 : parsed;
}

function parseDate(value: string) {
  const parsed = Date.parse(value);
  if (Number.isNaN(parsed)) {
    throw new Error(`Unable to parse date: "${value}"`);
  }
  return parsed;
}

async function resolveUserId(
  ctx: any,
  args: { userId?: string; ownerEmail?: string }
) {
  if (args.userId) return args.userId;
  if (!args.ownerEmail) {
    throw new Error("userId or ownerEmail is required.");
  }
  const user = await ctx.runQuery(internal.authInternal.findUserByEmail, {
    email: normalizeEmail(args.ownerEmail),
  });
  if (!user) {
    throw new Error("User not found for email.");
  }
  return user._id;
}

async function buildPropertyMap(ctx: any, userId: string) {
  const properties = await ctx.db
    .query("properties")
    .withIndex("by_user", (q) => q.eq("userId", userId as any))
    .collect();
  const map = new Map<string, string>();

  for (const property of properties) {
    const label = `${property.address}, ${property.city}, ${property.state} ${property.zipCode}`;
    map.set(normalizeLabel(label), property._id);
    map.set(normalizeLabel(property.address), property._id);
    map.set(normalizeLabel(property.name), property._id);
  }

  return map;
}

async function insertLicenses(
  ctx: any,
  userId: string,
  licenses: RentalLicenseSeedInput[]
) {
  const existing = await ctx.db
    .query("rentalLicenses")
    .withIndex("by_user", (q) => q.eq("userId", userId as any))
    .collect();

  const existingKeys = new Set(
    existing.map(
      (license) =>
        `${normalizeLabel(license.propertyLabel)}|${license.licenseNumber}`.toLowerCase()
    )
  );

  const propertyMap = await buildPropertyMap(ctx, userId);

  let created = 0;
  let skipped = 0;
  const now = Date.now();

  for (const license of licenses) {
    const key = `${normalizeLabel(license.propertyLabel)}|${license.licenseNumber}`.toLowerCase();
    if (existingKeys.has(key)) {
      skipped += 1;
      continue;
    }

    const propertyId = propertyMap.get(normalizeLabel(license.propertyLabel));

    await ctx.db.insert("rentalLicenses", {
      propertyId: propertyId as any,
      propertyLabel: license.propertyLabel,
      category: license.category,
      licenseNumber: license.licenseNumber,
      dateFrom: parseDate(license.dateFrom),
      dateTo: parseDate(license.dateTo),
      unitFees: parseMoney(license.unitFees),
      link: license.link,
      notes: license.notes,
      userId: userId as any,
      createdAt: now,
      updatedAt: now,
    });

    existingKeys.add(key);
    created += 1;
  }

  return { created, skipped };
}

/**
 * List all rental licenses
 */
export const list = query({
  args: {
    userId: v.optional(v.id("users")),
  },
  handler: async (ctx, args) => {
    let query = ctx.db.query("rentalLicenses");
    if (args.userId) {
      query = query.withIndex("by_user", (q) => q.eq("userId", args.userId!));
    }

    const licenses = await query.collect();

    return licenses.map((license) => ({
      _id: license._id,
      id: license._id,
      propertyId: license.propertyId,
      propertyLabel: license.propertyLabel,
      category: license.category,
      licenseNumber: license.licenseNumber,
      dateFrom: license.dateFrom,
      dateTo: license.dateTo,
      unitFees: license.unitFees,
      link: license.link,
      notes: license.notes,
      createdAt: license.createdAt,
      updatedAt: license.updatedAt,
    }));
  },
});

/**
 * Create a new rental license
 */
export const create = mutation({
  args: {
    propertyId: v.optional(v.id("properties")),
    propertyLabel: v.string(),
    category: v.string(),
    licenseNumber: v.string(),
    dateFrom: v.number(),
    dateTo: v.number(),
    unitFees: v.number(),
    link: v.optional(v.string()),
    notes: v.optional(v.string()),
    userId: v.id("users"),
  },
  handler: async (ctx, args) => {
    const now = Date.now();
    const licenseId = await ctx.db.insert("rentalLicenses", {
      propertyId: args.propertyId,
      propertyLabel: args.propertyLabel,
      category: args.category,
      licenseNumber: args.licenseNumber,
      dateFrom: args.dateFrom,
      dateTo: args.dateTo,
      unitFees: args.unitFees,
      link: args.link,
      notes: args.notes,
      userId: args.userId,
      createdAt: now,
      updatedAt: now,
    });

    const license = await ctx.db.get(licenseId);
    return {
      _id: license!._id,
      id: license!._id,
      propertyId: license!.propertyId,
      propertyLabel: license!.propertyLabel,
      category: license!.category,
      licenseNumber: license!.licenseNumber,
      dateFrom: license!.dateFrom,
      dateTo: license!.dateTo,
      unitFees: license!.unitFees,
      link: license!.link,
      notes: license!.notes,
      createdAt: license!.createdAt,
      updatedAt: license!.updatedAt,
    };
  },
});

/**
 * Update a rental license
 */
export const update = mutation({
  args: {
    id: v.id("rentalLicenses"),
    propertyId: v.optional(v.id("properties")),
    propertyLabel: v.optional(v.string()),
    category: v.optional(v.string()),
    licenseNumber: v.optional(v.string()),
    dateFrom: v.optional(v.number()),
    dateTo: v.optional(v.number()),
    unitFees: v.optional(v.number()),
    link: v.optional(v.string()),
    notes: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const { id, ...updates } = args;
    const license = await ctx.db.get(id);
    if (!license) {
      throw new Error("Rental license not found");
    }

    await ctx.db.patch(id, {
      ...updates,
      updatedAt: Date.now(),
    });

    const updated = await ctx.db.get(id);
    return {
      _id: updated!._id,
      id: updated!._id,
      propertyId: updated!.propertyId,
      propertyLabel: updated!.propertyLabel,
      category: updated!.category,
      licenseNumber: updated!.licenseNumber,
      dateFrom: updated!.dateFrom,
      dateTo: updated!.dateTo,
      unitFees: updated!.unitFees,
      link: updated!.link,
      notes: updated!.notes,
      createdAt: updated!.createdAt,
      updatedAt: updated!.updatedAt,
    };
  },
});

/**
 * Delete a rental license
 */
export const remove = mutation({
  args: {
    id: v.id("rentalLicenses"),
  },
  handler: async (ctx, args) => {
    const license = await ctx.db.get(args.id);
    if (!license) {
      throw new Error("Rental license not found");
    }
    await ctx.db.delete(args.id);
    return { id: args.id };
  },
});

/**
 * Seed default rental licenses for a user
 */
export const seedDefault = mutation({
  args: {
    userId: v.optional(v.id("users")),
    ownerEmail: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const userId = await resolveUserId(ctx, {
      userId: args.userId as any,
      ownerEmail: args.ownerEmail,
    });
    return await insertLicenses(ctx, userId as any, DEFAULT_RENTAL_LICENSES);
  },
});
