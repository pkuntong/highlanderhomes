import { ConvexHttpClient } from "convex/browser";

const DEFAULT_CONVEX_URL = "https://acrobatic-nightingale-459.convex.cloud";
const CONVEX_URL = import.meta.env.VITE_CONVEX_URL || DEFAULT_CONVEX_URL;

export const convex = new ConvexHttpClient(CONVEX_URL);

function normalizeError(error, fallbackMessage) {
  const rawMessage =
    error?.data?.message ||
    error?.message ||
    fallbackMessage;
  const message = String(rawMessage).replace(/^Uncaught Error:\s*/, "");
  return new Error(message);
}

export async function runConvexQuery(functionReference, args = {}) {
  try {
    return await convex.query(functionReference, args);
  } catch (error) {
    throw normalizeError(error, "Failed to run query.");
  }
}

export async function runConvexMutation(functionReference, args = {}) {
  try {
    return await convex.mutation(functionReference, args);
  } catch (error) {
    throw normalizeError(error, "Failed to run mutation.");
  }
}

export async function runConvexAction(functionReference, args = {}) {
  try {
    return await convex.action(functionReference, args);
  } catch (error) {
    throw normalizeError(error, "Failed to run action.");
  }
}
