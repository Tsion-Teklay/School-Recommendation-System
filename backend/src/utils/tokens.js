import { randomBytes } from "node:crypto";

/**
 * Cryptographically-random URL-safe token. 48 bytes → 96 hex chars (fits
 * the 128-char column with headroom). Used for email verification + password
 * reset links emailed to users.
 */
export function generateToken(bytes = 48) {
  return randomBytes(bytes).toString("hex");
}

/**
 * Token lifetimes (in milliseconds). Tweak in one place.
 */
export const EMAIL_VERIFICATION_TTL_MS = 24 * 60 * 60 * 1000; // 24h
export const PASSWORD_RESET_TTL_MS = 60 * 60 * 1000; // 1h

export function expiresAt(ttlMs) {
  return new Date(Date.now() + ttlMs);
}
export const PHONE_VERIFICATION_TTL_MS = 10 * 60 * 1000; // 10 minutes
