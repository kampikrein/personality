/**
 * src/crypto/emailHash.ts — SHA-256 email hash
 * Cycle 4 GREEN phase.
 *
 * Web Crypto SubtleCrypto.digest("SHA-256", utf8Encode(input))
 * Returns 64-char lowercase hex string.
 * Deterministic: same email → same hash.
 * Key-independent (no HMAC key required).
 */

/**
 * sha256Hex — SHA-256(input) → 64-char lowercase hex
 */
export async function sha256Hex(input: string): Promise<string> {
  const data = new TextEncoder().encode(input);
  const digest = await crypto.subtle.digest("SHA-256", data);
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}
