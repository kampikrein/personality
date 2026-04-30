/**
 * src/crypto/envelope.ts — AES-256-GCM envelope encrypt/decrypt
 * Cycle 4 GREEN phase.
 *
 * IV = HMAC-SHA256(detKey, plaintext)[:12] — deterministic
 * AES key derived from detKey raw bytes (exportKey → importKey as AES-256-GCM)
 * Envelope JSON: { iv: hex(12 bytes), ct: base64(ciphertext), v: encryption_version }
 *
 * Stored as email_enc column value (R1 wire-format per Synthesis 018).
 */

export interface EnvelopeJSON {
  iv: string; // 12-byte hex (24 hex chars)
  ct: string; // base64 ciphertext
  v: number;  // encryption_version
}

// ─── Helpers ────────────────────────────────────────────────────────────────

function toHex(bytes: Uint8Array): string {
  return Array.from(bytes)
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

function fromHex(hex: string): Uint8Array {
  const bytes = new Uint8Array(hex.length / 2);
  for (let i = 0; i < hex.length; i += 2) {
    bytes[i / 2] = parseInt(hex.slice(i, i + 2), 16);
  }
  return bytes;
}

function toBase64(bytes: Uint8Array): string {
  return btoa(String.fromCharCode(...bytes));
}

function fromBase64(b64: string): Uint8Array {
  return Uint8Array.from(atob(b64), (c) => c.charCodeAt(0));
}

/**
 * deriveAesKeyFromHmac — exports HMAC key raw bytes, takes first 32 bytes as AES-256-GCM key.
 * HMAC-SHA256 key is 512 bits (64 bytes); AES-256 requires exactly 256 bits (32 bytes).
 * We use the first 32 bytes as the AES key material (both share the same secret root).
 */
async function deriveAesKeyFromHmac(hmacKey: CryptoKey): Promise<CryptoKey> {
  const raw = await crypto.subtle.exportKey("raw", hmacKey);
  // HMAC-SHA256 raw key is 64 bytes; take first 32 bytes for AES-256
  const aesKeyBytes = new Uint8Array(raw).slice(0, 32);
  return crypto.subtle.importKey(
    "raw",
    aesKeyBytes,
    { name: "AES-GCM", length: 256 },
    false,
    ["encrypt", "decrypt"],
  );
}

// ─── Public API ───────────────────────────────────────────────────────────────

/**
 * deriveIV — HMAC-SHA256(detKey, plaintext)[:12]
 * Deterministic 96-bit GCM IV.
 */
export async function deriveIV(
  detKey: CryptoKey,
  plaintext: string,
): Promise<Uint8Array> {
  const data = new TextEncoder().encode(plaintext);
  const sig = await crypto.subtle.sign("HMAC", detKey, data);
  return new Uint8Array(sig).slice(0, 12);
}

/**
 * encryptEnvelope — AES-256-GCM deterministic envelope.
 *
 * detKey: HMAC-SHA256 key (used for IV derivation; AES key is derived from same key material)
 * version: encryption_version stored in envelope JSON
 *
 * Returns EnvelopeJSON { iv: hex, ct: base64, v: number }
 */
export async function encryptEnvelope(
  plaintext: string,
  detKey: CryptoKey,
  version: number,
): Promise<EnvelopeJSON> {
  const iv = await deriveIV(detKey, plaintext);
  const aesKey = await deriveAesKeyFromHmac(detKey);
  const ct = await crypto.subtle.encrypt(
    { name: "AES-GCM", iv },
    aesKey,
    new TextEncoder().encode(plaintext),
  );
  return {
    iv: toHex(iv),
    ct: toBase64(new Uint8Array(ct)),
    v: version,
  };
}

/**
 * decryptEnvelope — AES-256-GCM envelope decrypt.
 *
 * detKey: same HMAC key used during encryption (used to derive AES key)
 * Throws if decryption fails (wrong key or tampered ciphertext).
 */
export async function decryptEnvelope(
  envelope: EnvelopeJSON,
  detKey: CryptoKey,
): Promise<string> {
  const iv = fromHex(envelope.iv);
  const ct = fromBase64(envelope.ct);
  const aesKey = await deriveAesKeyFromHmac(detKey);
  const pt = await crypto.subtle.decrypt(
    { name: "AES-GCM", iv },
    aesKey,
    ct,
  );
  return new TextDecoder().decode(pt);
}
