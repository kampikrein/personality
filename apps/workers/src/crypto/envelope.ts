/**
 * src/crypto/envelope.ts — AES-256-GCM envelope encrypt/decrypt stub
 * Cycle 4 RED phase.
 *
 * Green phase impl:
 *   - IV = HMAC-SHA256(detKey, plaintext)[:12] (deterministic — same plaintext+key → same IV)
 *   - AES-256-GCM encrypt using Web Crypto API
 *   - Envelope JSON: { iv: <hex12>, ct: <base64>, v: <encryption_version> }
 *   - v field identifies key version for parallel-key rotation
 *   - Stored as email_enc column value (R1 wire-format compat per Synthesis 018)
 */

export interface EnvelopeJSON {
  iv: string; // 12-byte hex
  ct: string; // base64 ciphertext
  v: number;  // encryption_version
}

/**
 * encryptEnvelope — AES-256-GCM deterministic envelope
 * RED phase: throws 'not implemented'
 */
export async function encryptEnvelope(
  _plaintext: string,
  _detKey: CryptoKey,
  _version: number,
): Promise<EnvelopeJSON> {
  throw new Error("not implemented");
}

/**
 * decryptEnvelope — AES-256-GCM envelope decrypt
 * RED phase: throws 'not implemented'
 */
export async function decryptEnvelope(
  _envelope: EnvelopeJSON,
  _detKey: CryptoKey,
): Promise<string> {
  throw new Error("not implemented");
}

/**
 * deriveIV — HMAC-SHA256(detKey, plaintext)[:12]
 * RED phase: throws 'not implemented'
 */
export async function deriveIV(
  _detKey: CryptoKey,
  _plaintext: string,
): Promise<Uint8Array> {
  throw new Error("not implemented");
}
