/**
 * src/crypto/emailHash.ts — SHA-256 email hash stub
 * Cycle 4 RED phase.
 *
 * Green phase impl:
 *   - Web Crypto SubtleCrypto.digest("SHA-256", utf8Encode(email))
 *   - returns 64-char lowercase hex string
 *   - deterministic: same email → same hash
 *   - key-independent (no HMAC key required — see emailHashHook for BetterAuth hook)
 */

/**
 * sha256Hex — SHA-256(input) → 64-char lowercase hex
 * RED phase: throws 'not implemented'
 */
export async function sha256Hex(_input: string): Promise<string> {
  throw new Error("not implemented");
}
