/**
 * src/auth/emailHashHook.ts — BetterAuth email_hash generation hook
 * Cycle 4 GREEN phase.
 *
 * BetterAuth before-create hook that auto-sets email_hash field.
 * email_hash = SHA-256 hex (64 chars), key-independent, deterministic.
 * Recalculates on email change.
 */

import { sha256Hex } from "../crypto/emailHash";

/**
 * generateEmailHash — SHA-256(email.toLowerCase().trim()) → 64-char hex
 * Normalizes email before hashing: lowercase + trim.
 */
export async function generateEmailHash(email: string): Promise<string> {
  return sha256Hex(email.toLowerCase().trim());
}

/**
 * emailHashBeforeCreateHook — BetterAuth before hook that adds email_hash.
 *
 * Accepts a user record (Record<string, unknown>), reads the email field,
 * computes the SHA-256 hash, and returns a new record with email_hash added.
 *
 * BetterAuth v1.6.9 hooks.before pattern:
 *   { matcher: (ctx) => ctx.path === "/sign-up/email", handler: emailHashBeforeCreateHook }
 */
export async function emailHashBeforeCreateHook(
  user: Record<string, unknown>,
): Promise<Record<string, unknown>> {
  const email = typeof user.email === "string" ? user.email : "";
  const emailHash = await generateEmailHash(email);
  return {
    ...user,
    email_hash: emailHash,
  };
}
