/// <reference types="node" />
"use node";

import { v } from "convex/values";
import { action } from "./_generated/server";
import { internal, api } from "./_generated/api";
import { createHash, randomBytes } from "crypto";

function hashPassword(password: string, salt: string) {
  return createHash("sha256").update(password + salt).digest("hex");
}

function normalizeEmail(email: string) {
  return email.trim().toLowerCase();
}

export const seedScreenshotData = action({
  args: {
    email: v.string(),
    password: v.string(),
    name: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const email = normalizeEmail(args.email);
    const name = args.name || "Demo Owner";

    let user = await ctx.runQuery(internal.authInternal.findUserByEmail, { email });
    if (!user) {
      const salt = randomBytes(16).toString("hex");
      const passwordHash = hashPassword(args.password, salt);
      const userId = await ctx.runMutation(internal.authInternal.createUser, {
        email,
        name,
        passwordHash,
        passwordSalt: salt,
        emailVerified: true,
      });
      user = await ctx.runQuery(internal.authInternal.getUser, { userId });
    } else {
      const salt = randomBytes(16).toString("hex");
      const passwordHash = hashPassword(args.password, salt);
      await ctx.runMutation(internal.authInternal.setPassword, {
        userId: user._id,
        passwordHash,
        passwordSalt: salt,
      });
      await ctx.runMutation(internal.authInternal.markEmailVerified, {
        userId: user._id,
      });
    }

    await ctx.runMutation(api.users.setPremiumStatus, {
      userId: user._id,
      isPremium: true,
    });

    const propertyInputs = [
      {
        name: "Dunran Row",
        address: "3441 Dunran Rd",
        city: "Baltimore",
        state: "MD",
        zipCode: "21222",
        propertyType: "Single Family",
        units: 1,
        monthlyRent: 1700,
      },
      {
        name: "Ryerson Circle",
        address: "3140 Ryerson Cir",
        city: "Halethorpe",
        state: "MD",
        zipCode: "21227",
        propertyType: "Single Family",
        units: 1,
        monthlyRent: 1600,
      },
      {
        name: "Guilford Flats",
        address: "1812 Guilford Ave",
        city: "Baltimore",
        state: "MD",
        zipCode: "21202",
        propertyType: "Multi-Family",
        units: 3,
        monthlyRent: 5060,
      },
      {
        name: "Mayhill Heights",
        address: "7304 Mayhill Dr",
        city: "Gaithersburg",
        state: "MD",
        zipCode: "20879",
        propertyType: "Single Family",
        units: 1,
        monthlyRent: 2790,
      },
    ];

    const createdProperties = [];
    for (const prop of propertyInputs) {
      const created = await ctx.runMutation(api.properties.create, {
        ...prop,
        purchasePrice: undefined,
        currentValue: undefined,
        imageURL: undefined,
        notes: "Demo data for screenshots",
        userId: user._id,
      });
      createdProperties.push(created);
    }

    const [p1, p2, p3, p4] = createdProperties;

    await ctx.runMutation(api.tenants.create, {
      firstName: "Shanta",
      lastName: "Watson",
      email: "shanta.watson@example.com",
      phone: "443-583-6112",
      unit: "Unit A",
      propertyId: p1._id,
      leaseStartDate: Date.now() - 1000 * 60 * 60 * 24 * 120,
      leaseEndDate: Date.now() + 1000 * 60 * 60 * 24 * 365,
      monthlyRent: 1700,
      securityDeposit: 1700,
      isActive: true,
      userId: user._id,
    });

    await ctx.runMutation(api.tenants.create, {
      firstName: "Joi",
      lastName: "White",
      email: "joi.white@example.com",
      phone: "410-536-3454",
      unit: "Unit 1",
      propertyId: p2._id,
      leaseStartDate: Date.now() - 1000 * 60 * 60 * 24 * 365,
      leaseEndDate: Date.now() + 1000 * 60 * 60 * 24 * 365,
      monthlyRent: 1600,
      securityDeposit: 1500,
      isActive: true,
      userId: user._id,
    });

    await ctx.runMutation(api.tenants.create, {
      firstName: "Dwayne",
      lastName: "Powell",
      email: "dwayne.powell@example.com",
      phone: "443-630-2900",
      unit: "Unit 2B",
      propertyId: p3._id,
      leaseStartDate: Date.now() - 1000 * 60 * 60 * 24 * 200,
      leaseEndDate: Date.now() + 1000 * 60 * 60 * 24 * 300,
      monthlyRent: 2500,
      securityDeposit: 2500,
      isActive: true,
      userId: user._id,
    });

    const contractorInputs = [
      {
        companyName: "Anchor Mechanical",
        contactName: "Brian Dimick",
        email: "bdimick@anchormech.com",
        phone: "443-564-3437",
        specialty: ["HVAC"],
        isPreferred: true,
      },
      {
        companyName: "Solomon's Termite & Pest Control",
        contactName: "Solomon's Termite",
        email: "office@solomonspestcontrol.com",
        phone: "410-358-7175",
        specialty: ["Pest Control"],
        isPreferred: true,
      },
      {
        companyName: "Custom Home Renovations",
        contactName: "Jon Poe",
        email: "info@chrhomesmd.com",
        phone: "443-333-1589",
        specialty: ["Roofing"],
        isPreferred: false,
      },
      {
        companyName: "5 Stars Handyman Services",
        contactName: "Ivan Bautista",
        email: "ivanhandyman@yahoo.com",
        phone: "443-850-9591",
        specialty: ["Handyman"],
        isPreferred: true,
      },
    ];

    const contractorIds = [];
    for (const contractor of contractorInputs) {
      const created = await ctx.runMutation(api.contractors.create, {
        ...contractor,
        address: undefined,
        website: undefined,
        notes: undefined,
        hourlyRate: undefined,
        rating: undefined,
        userId: user._id,
      });
      contractorIds.push(created._id);
    }

    const hvacRequest = await ctx.runMutation(api.maintenanceRequests.create, {
      propertyId: p1._id,
      tenantId: undefined,
      title: "AC not cooling",
      descriptionText: "Tenant reports AC blowing warm air.",
      category: "HVAC",
      priority: "high",
      userId: user._id,
    });

    await ctx.runMutation(api.maintenanceRequests.assignContractor, {
      requestId: hvacRequest._id,
      contractorId: contractorIds[0],
    });
    await ctx.runMutation(api.maintenanceRequests.updateStatus, {
      id: hvacRequest._id,
      status: "scheduled",
    });

    const plumbingRequest = await ctx.runMutation(api.maintenanceRequests.create, {
      propertyId: p2._id,
      tenantId: undefined,
      title: "Kitchen faucet leak",
      descriptionText: "Minor leak under sink. Needs washer replacement.",
      category: "Plumbing",
      priority: "normal",
      userId: user._id,
    });

    await ctx.runMutation(api.maintenanceRequests.assignContractor, {
      requestId: plumbingRequest._id,
      contractorId: contractorIds[3],
    });
    await ctx.runMutation(api.maintenanceRequests.updateStatus, {
      id: plumbingRequest._id,
      status: "inProgress",
    });

    await ctx.runMutation(api.rentPayments.create, {
      propertyId: p1._id,
      tenantId: undefined,
      amount: 1700,
      paymentDate: Date.now() - 1000 * 60 * 60 * 24 * 15,
      dueDate: Date.now() - 1000 * 60 * 60 * 24 * 20,
      paymentMethod: "bank_transfer",
      status: "completed",
      notes: "On-time",
      userId: user._id,
    });

    await ctx.runMutation(api.expenses.create, {
      propertyId: p3._id,
      title: "Roof inspection",
      description: "Annual inspection",
      amount: 250,
      category: "maintenance",
      date: Date.now() - 1000 * 60 * 60 * 24 * 10,
      isRecurring: false,
      notes: "No issues found",
      userId: user._id,
    });

    await ctx.runMutation(api.insurancePolicies.create, {
      propertyId: p1._id,
      propertyLabel: p1.address,
      insuranceName: "Safeco",
      policyNumber: "OF3278498",
      termStart: Date.now() - 1000 * 60 * 60 * 24 * 60,
      termEnd: Date.now() + 1000 * 60 * 60 * 24 * 300,
      premium: 3568,
      notes: "Lender: Select Portfolio Servicing",
      agent: "EnsuranceMax LLC",
      userId: user._id,
    });

    await ctx.runMutation(api.rentalLicenses.create, {
      propertyId: p3._id,
      propertyLabel: p3.address,
      category: "Rental License",
      licenseNumber: "RHR-2025-01242",
      dateFrom: Date.now() - 1000 * 60 * 60 * 24 * 300,
      dateTo: Date.now() + 1000 * 60 * 60 * 24 * 700,
      unitFees: 60,
      link: "https://citizenaccess.baltimorecountymd.gov/CitizenAccess/Login.aspx",
      notes: "Baltimore County",
      userId: user._id,
    });

    return {
      userId: user._id,
      email,
      properties: createdProperties.length,
    };
  },
});

export const clearScreenshotData = action({
  args: { email: v.string() },
  handler: async (ctx, args) => {
    const email = normalizeEmail(args.email);
    const user = await ctx.runQuery(internal.authInternal.findUserByEmail, { email });
    if (!user) {
      return { success: false, message: "User not found" };
    }
    await ctx.runMutation(api.users.deleteAccount, { userId: user._id });
    return { success: true };
  },
});
