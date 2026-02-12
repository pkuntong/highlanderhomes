/// <reference types="node" />
"use node";

import { v } from "convex/values";
import { action } from "./_generated/server";
import { api } from "./_generated/api";

const DEFAULT_RENTCAST_BASE_URL = "https://api.rentcast.io/v1";

type LiveSnapshot = {
  estimatePrice?: number;
  estimateRent?: number;
  yoyChangePct?: number;
  demandLevel: "low" | "normal" | "high";
  source: string;
  sourceURL?: string;
  notes?: string;
};

function toAddressLine(property: {
  address: string;
  city: string;
  state: string;
  zipCode: string;
}) {
  return `${property.address}, ${property.city}, ${property.state} ${property.zipCode}`;
}

function asNumber(value: unknown): number | undefined {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string") {
    const parsed = Number(value.replace(/[^0-9.-]/g, ""));
    return Number.isFinite(parsed) ? parsed : undefined;
  }
  return undefined;
}

function pickFirstNumber(payload: any, keys: string[]): number | undefined {
  if (!payload || typeof payload !== "object") return undefined;
  for (const key of keys) {
    const direct = asNumber(payload[key]);
    if (direct !== undefined) return direct;
  }
  return undefined;
}

function deriveDemandLevel(yoyChangePct?: number): "low" | "normal" | "high" {
  if (yoyChangePct === undefined) return "normal";
  if (yoyChangePct >= 5) return "high";
  if (yoyChangePct <= -2) return "low";
  return "normal";
}

async function fetchRentCastJson(url: string, apiKey: string) {
  const response = await fetch(url, {
    headers: {
      "X-Api-Key": apiKey,
      Accept: "application/json",
    },
  });
  if (!response.ok) {
    const body = await response.text();
    throw new Error(`RentCast ${response.status}: ${body.slice(0, 220)}`);
  }
  return response.json();
}

async function fetchLiveSnapshotForAddress(addressLine: string): Promise<LiveSnapshot> {
  const apiKey = process.env.RENTCAST_API_KEY;
  if (!apiKey) {
    throw new Error("Missing RENTCAST_API_KEY in Convex environment variables.");
  }

  const base = process.env.RENTCAST_BASE_URL || DEFAULT_RENTCAST_BASE_URL;
  const encodedAddress = encodeURIComponent(addressLine);

  const valueUrl = `${base}/avm/value?address=${encodedAddress}`;
  const rentUrl = `${base}/avm/rent/long-term?address=${encodedAddress}`;

  const [valuePayload, rentPayload] = await Promise.all([
    fetchRentCastJson(valueUrl, apiKey),
    fetchRentCastJson(rentUrl, apiKey),
  ]);

  const estimatePrice =
    pickFirstNumber(valuePayload, ["price", "value", "estimate"]) ??
    pickFirstNumber(valuePayload?.data, ["price", "value", "estimate"]);

  const estimateRent =
    pickFirstNumber(rentPayload, ["rent", "price", "estimate"]) ??
    pickFirstNumber(rentPayload?.data, ["rent", "price", "estimate"]);

  const yoyChangePct =
    pickFirstNumber(valuePayload, ["yoyChangePct", "yearOverYearChange", "priceChange"]) ??
    pickFirstNumber(rentPayload, ["yoyChangePct", "yearOverYearChange", "rentChange"]);

  const demandLevel = deriveDemandLevel(yoyChangePct);

  return {
    estimatePrice,
    estimateRent,
    yoyChangePct,
    demandLevel,
    source: "RentCast",
    sourceURL: "https://www.rentcast.io/",
    notes: `Live pull at ${new Date().toISOString()}`,
  };
}

export const refreshForProperty = action({
  args: {
    userId: v.id("users"),
    propertyId: v.id("properties"),
  },
  handler: async (ctx, args) => {
    const property = await ctx.runQuery(api.properties.get, { id: args.propertyId });
    if (!property) throw new Error("Property not found.");

    const addressLine = toAddressLine(property);
    const snapshot = await fetchLiveSnapshotForAddress(addressLine);

    const created = await ctx.runMutation(api.marketTrends.create, {
      userId: args.userId,
      propertyId: args.propertyId,
      title: "Live Market Pull",
      marketType: "areaTrend",
      areaLabel: `${property.city}, ${property.state} ${property.zipCode}`,
      estimatePrice: snapshot.estimatePrice,
      estimateRent: snapshot.estimateRent,
      yoyChangePct: snapshot.yoyChangePct,
      demandLevel: snapshot.demandLevel,
      source: snapshot.source,
      sourceURL: snapshot.sourceURL,
      notes: snapshot.notes,
      observedAt: Date.now(),
    });

    return {
      success: true,
      propertyId: args.propertyId,
      propertyName: property.name,
      trendId: created?._id ?? null,
      estimatePrice: snapshot.estimatePrice ?? null,
      estimateRent: snapshot.estimateRent ?? null,
      source: snapshot.source,
    };
  },
});

export const refreshPortfolio = action({
  args: {
    userId: v.id("users"),
  },
  handler: async (ctx, args) => {
    const properties = await ctx.runQuery(api.properties.list, { userId: args.userId });
    if (!properties.length) {
      return {
        success: true,
        totalProperties: 0,
        refreshed: 0,
        failed: 0,
        refreshedItems: [] as Array<{ propertyId: string; propertyName: string }>,
        failedItems: [] as Array<{ propertyId: string; propertyName: string; error: string }>,
      };
    }

    const refreshedItems: Array<{ propertyId: string; propertyName: string }> = [];
    const failedItems: Array<{ propertyId: string; propertyName: string; error: string }> = [];

    for (const property of properties) {
      try {
        const addressLine = toAddressLine(property);
        const snapshot = await fetchLiveSnapshotForAddress(addressLine);

        await ctx.runMutation(api.marketTrends.create, {
          userId: args.userId,
          propertyId: property._id,
          title: "Live Market Pull",
          marketType: "areaTrend",
          areaLabel: `${property.city}, ${property.state} ${property.zipCode}`,
          estimatePrice: snapshot.estimatePrice,
          estimateRent: snapshot.estimateRent,
          yoyChangePct: snapshot.yoyChangePct,
          demandLevel: snapshot.demandLevel,
          source: snapshot.source,
          sourceURL: snapshot.sourceURL,
          notes: snapshot.notes,
          observedAt: Date.now(),
        });

        refreshedItems.push({ propertyId: property._id, propertyName: property.name });
      } catch (error) {
        failedItems.push({
          propertyId: property._id,
          propertyName: property.name,
          error: error instanceof Error ? error.message : "Unknown error",
        });
      }
    }

    return {
      success: true,
      totalProperties: properties.length,
      refreshed: refreshedItems.length,
      failed: failedItems.length,
      refreshedItems,
      failedItems,
    };
  },
});
