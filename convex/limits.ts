export const FREE_PROPERTY_LIMIT = 3;
export const OWNER_EMAIL = "highlanderhomes22@gmail.com";

export function normalizeEmail(email: string) {
  return email.trim().toLowerCase();
}

export function isOwnerEmail(email?: string | null) {
  if (!email) return false;
  return normalizeEmail(email) === OWNER_EMAIL;
}
