/**
 * test/crypto/envelope.test.ts — AES-256-GCM envelope RED phase
 * Cycle 4.
 *
 * Assertions:
 *   1. encryptEnvelope returns EnvelopeJSON { iv, ct, v }
 *   2. iv is 24-char hex (12 bytes)
 *   3. ct is non-empty base64 string
 *   4. v matches version parameter
 *   5. IV = HMAC-SHA256(detKey, plaintext)[:12] — deterministic
 *   6. Same plaintext + same detKey → same IV → same ciphertext
 *   7. Different plaintext → different IV
 *   8. decryptEnvelope recovers original plaintext
 *   9. Wrong key → decrypt throws
 *  10. v field identifies key version
 *  11. deriveIV returns 12-byte Uint8Array
 *
 * RED phase: stubs throw 'not implemented'.
 * GREEN phase: Web Crypto SubtleCrypto AES-256-GCM + HMAC-SHA256.
 */

import { describe, it, expect, beforeAll } from "vitest";
import {
  encryptEnvelope,
  decryptEnvelope,
  deriveIV,
  type EnvelopeJSON,
} from "../../src/crypto/envelope";

// ─── Helpers ────────────────────────────────────────────────────────────────

async function generateTestKey(): Promise<CryptoKey> {
  return crypto.subtle.generateKey(
    { name: "AES-GCM", length: 256 },
    true,
    ["encrypt", "decrypt"],
  );
}

async function generateHmacKey(): Promise<CryptoKey> {
  return crypto.subtle.generateKey(
    { name: "HMAC", hash: "SHA-256" },
    true,
    ["sign", "verify"],
  );
}

// ─── Tests ───────────────────────────────────────────────────────────────────

describe("encryptEnvelope — AES-256-GCM deterministic", () => {
  let detKey: CryptoKey;

  beforeAll(async () => {
    detKey = await generateHmacKey();
  });

  it("returns EnvelopeJSON with iv, ct, v fields", async () => {
    const aesKey = await generateTestKey();
    const envelope = await encryptEnvelope("hello@example.com", detKey, 1);
    // Note: encryptEnvelope needs both detKey (for IV derivation) and aesKey (for encryption)
    // GREEN phase will clarify the signature — detKey is the HMAC key, AES key is separate
    expect(envelope).toHaveProperty("iv");
    expect(envelope).toHaveProperty("ct");
    expect(envelope).toHaveProperty("v");
  });

  it("iv is 24-char hex string (12 bytes = 24 hex chars)", async () => {
    const envelope = await encryptEnvelope("test@example.com", detKey, 1);
    expect(envelope.iv).toMatch(/^[0-9a-f]{24}$/);
  });

  it("ct is non-empty base64 string", async () => {
    const envelope = await encryptEnvelope("test@example.com", detKey, 1);
    expect(envelope.ct.length).toBeGreaterThan(0);
    // base64 chars only
    expect(envelope.ct).toMatch(/^[A-Za-z0-9+/=]+$/);
  });

  it("v field matches version parameter", async () => {
    const envelope = await encryptEnvelope("test@example.com", detKey, 2);
    expect(envelope.v).toBe(2);
  });

  it("same plaintext + same detKey → same IV (deterministic)", async () => {
    const plaintext = "deterministic@example.com";
    const env1 = await encryptEnvelope(plaintext, detKey, 1);
    const env2 = await encryptEnvelope(plaintext, detKey, 1);
    expect(env1.iv).toBe(env2.iv);
  });

  it("same plaintext + same detKey → same ciphertext (deterministic)", async () => {
    const plaintext = "same@example.com";
    const env1 = await encryptEnvelope(plaintext, detKey, 1);
    const env2 = await encryptEnvelope(plaintext, detKey, 1);
    expect(env1.ct).toBe(env2.ct);
  });

  it("different plaintext → different IV", async () => {
    const env1 = await encryptEnvelope("a@example.com", detKey, 1);
    const env2 = await encryptEnvelope("b@example.com", detKey, 1);
    expect(env1.iv).not.toBe(env2.iv);
  });
});

describe("decryptEnvelope — round-trip", () => {
  let detKey: CryptoKey;

  beforeAll(async () => {
    detKey = await generateHmacKey();
  });

  it("decryptEnvelope recovers original plaintext", async () => {
    const plaintext = "roundtrip@example.com";
    const envelope = await encryptEnvelope(plaintext, detKey, 1);
    const recovered = await decryptEnvelope(envelope, detKey);
    expect(recovered).toBe(plaintext);
  });

  it("wrong detKey → decryptEnvelope throws", async () => {
    const plaintext = "wrongkey@example.com";
    const envelope = await encryptEnvelope(plaintext, detKey, 1);
    const wrongKey = await generateHmacKey();
    await expect(decryptEnvelope(envelope, wrongKey)).rejects.toThrow();
  });

  it("v field preserved through round-trip", async () => {
    const plaintext = "version@example.com";
    const envelope = await encryptEnvelope(plaintext, detKey, 3);
    expect(envelope.v).toBe(3);
    const recovered = await decryptEnvelope(envelope, detKey);
    expect(recovered).toBe(plaintext);
  });
});

describe("deriveIV — HMAC-SHA256[:12]", () => {
  let hmacKey: CryptoKey;

  beforeAll(async () => {
    hmacKey = await generateHmacKey();
  });

  it("returns Uint8Array of length 12", async () => {
    const iv = await deriveIV(hmacKey, "test@example.com");
    expect(iv).toBeInstanceOf(Uint8Array);
    expect(iv.byteLength).toBe(12);
  });

  it("same key + same input → same IV (deterministic)", async () => {
    const iv1 = await deriveIV(hmacKey, "consistent@example.com");
    const iv2 = await deriveIV(hmacKey, "consistent@example.com");
    expect(Array.from(iv1)).toEqual(Array.from(iv2));
  });

  it("different input → different IV", async () => {
    const iv1 = await deriveIV(hmacKey, "a@example.com");
    const iv2 = await deriveIV(hmacKey, "b@example.com");
    expect(Array.from(iv1)).not.toEqual(Array.from(iv2));
  });
});
