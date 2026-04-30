/**
 * src/auth/emailHashHook.ts — BetterAuth email_hash generation hook stub
 * Cycle 4 RED phase.
 *
 * Green phase impl:
 *   - BetterAuth before-create hook or mounter middleware
 *   - email_hash = SHA-256 hex (64 chars), key-independent (Web Crypto)
 *   - Recalculates on email change
 */

/**
 * generateEmailHash — SHA-256(email) → 64-char hex
 * RED phase: throws 'not implemented'
 */
export async function generateEmailHash(_email: string): Promise<string> {
  throw new Error("not implemented");
}

/**
 * emailHashBeforeCreateHook — BetterAuth hook that auto-sets email_hash
 * RED phase: throws 'not implemented'
 */
export function emailHashBeforeCreateHook(_user: Record<string, unknown>): Promise<Record<string, unknown>> {
  throw new Error("not implemented");
}
