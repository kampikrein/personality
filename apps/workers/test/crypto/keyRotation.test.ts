/**
 * test/crypto/keyRotation.test.ts — Parallel-key rotation RED phase
 * Cycle 4.
 *
 * R4-F3 5-phase rotation assertions:
 *   1. createRotationContext with single key
 *   2. selectKeyForVersion picks correct key
 *   3. dual-read: unknown version falls back to current
 *   4. addNewKey (Phase 1): K_{n+1} added, dual-read enabled
 *   5. selectKeyForVersion after addNewKey: version=1 → K_1, version=2 → K_2
 *   6. reEncryptRow (Phase 2): produces new envelope + incremented version
 *   7. reEncryptRow: version mismatch → throws
 *   8. retireKey (Phase 5): K_n removed from context
 *   9. retireKey then access retired version → throws
 *  10. currentVersion updated after addNewKey
 *
 * RED phase: stubs throw 'not implemented'.
 * GREEN phase: implement key rotation logic.
 */

import { describe, it, expect, beforeAll } from "vitest";
import {
  createRotationContext,
  selectKeyForVersion,
  addNewKey,
  reEncryptRow,
  retireKey,
  type RotationKey,
  type RotationContext,
} from "../../src/crypto/keyRotation";

// ─── Helpers ────────────────────────────────────────────────────────────────

async function genKey(): Promise<CryptoKey> {
  return crypto.subtle.generateKey(
    { name: "AES-GCM", length: 256 },
    true,
    ["encrypt", "decrypt"],
  );
}

// ─── Phase 0: Normal Operation ───────────────────────────────────────────────

describe("createRotationContext — Phase 0 normal operation", () => {
  let k1: CryptoKey;

  beforeAll(async () => {
    k1 = await genKey();
  });

  it("creates context with one key", () => {
    const ctx = createRotationContext([{ version: 1, key: k1 }]);
    expect(ctx).toBeDefined();
    expect(ctx.keys).toHaveLength(1);
    expect(ctx.currentVersion).toBe(1);
  });

  it("selectKeyForVersion returns correct key for version 1", () => {
    const ctx = createRotationContext([{ version: 1, key: k1 }]);
    const key = selectKeyForVersion(ctx, 1);
    expect(key).toBe(k1);
  });

  it("selectKeyForVersion throws for unknown version", () => {
    const ctx = createRotationContext([{ version: 1, key: k1 }]);
    expect(() => selectKeyForVersion(ctx, 99)).toThrow();
  });
});

// ─── Phase 1: Add K_{n+1} + dual-read ────────────────────────────────────────

describe("addNewKey — Phase 1 dual-read activation", () => {
  let k1: CryptoKey;
  let k2: CryptoKey;

  beforeAll(async () => {
    k1 = await genKey();
    k2 = await genKey();
  });

  it("addNewKey registers K_2 alongside K_1", () => {
    const ctx = createRotationContext([{ version: 1, key: k1 }]);
    const newCtx = addNewKey(ctx, { version: 2, key: k2 });
    expect(newCtx.keys).toHaveLength(2);
  });

  it("currentVersion updated to 2 after addNewKey", () => {
    const ctx = createRotationContext([{ version: 1, key: k1 }]);
    const newCtx = addNewKey(ctx, { version: 2, key: k2 });
    expect(newCtx.currentVersion).toBe(2);
  });

  it("dual-read: version=1 → K_1, version=2 → K_2", () => {
    const ctx = createRotationContext([{ version: 1, key: k1 }]);
    const newCtx = addNewKey(ctx, { version: 2, key: k2 });
    expect(selectKeyForVersion(newCtx, 1)).toBe(k1);
    expect(selectKeyForVersion(newCtx, 2)).toBe(k2);
  });
});

// ─── Phase 2: Re-encrypt ──────────────────────────────────────────────────────

describe("reEncryptRow — Phase 2 re-encryption", () => {
  let k1: CryptoKey;
  let k2: CryptoKey;
  let ctx: RotationContext;

  beforeAll(async () => {
    k1 = await genKey();
    k2 = await genKey();
    // Setup context with both keys
    const base = createRotationContext([{ version: 1, key: k1 }]);
    ctx = addNewKey(base, { version: 2, key: k2 });
  });

  it("reEncryptRow returns new emailEnc with incremented version", async () => {
    // Simulate existing email_enc (in reality, an EnvelopeJSON stringified with K_1)
    const fakeEmailEnc = JSON.stringify({ iv: "a".repeat(24), ct: "base64ct==", v: 1 });
    const result = await reEncryptRow(ctx, fakeEmailEnc, 1, 2);
    expect(result).toBeDefined();
    expect(result.encryptionVersion).toBe(2);
    expect(typeof result.emailEnc).toBe("string");
  });

  it("reEncryptRow with wrong oldVersion (key not found) → throws", async () => {
    const fakeEmailEnc = JSON.stringify({ iv: "b".repeat(24), ct: "xyz==", v: 1 });
    await expect(reEncryptRow(ctx, fakeEmailEnc, 99, 2)).rejects.toThrow();
  });
});

// ─── Phase 5: Retire K_n ─────────────────────────────────────────────────────

describe("retireKey — Phase 5 K_n removal", () => {
  let k1: CryptoKey;
  let k2: CryptoKey;

  beforeAll(async () => {
    k1 = await genKey();
    k2 = await genKey();
  });

  it("retireKey removes K_1 from context", () => {
    const base = createRotationContext([{ version: 1, key: k1 }]);
    const withTwo = addNewKey(base, { version: 2, key: k2 });
    const retired = retireKey(withTwo, 1);
    expect(retired.keys).toHaveLength(1);
    expect(retired.keys[0].version).toBe(2);
  });

  it("selectKeyForVersion after retire → throws for retired version", () => {
    const base = createRotationContext([{ version: 1, key: k1 }]);
    const withTwo = addNewKey(base, { version: 2, key: k2 });
    const retired = retireKey(withTwo, 1);
    expect(() => selectKeyForVersion(retired, 1)).toThrow();
  });

  it("selectKeyForVersion after retire → K_2 still accessible", () => {
    const base = createRotationContext([{ version: 1, key: k1 }]);
    const withTwo = addNewKey(base, { version: 2, key: k2 });
    const retired = retireKey(withTwo, 1);
    expect(selectKeyForVersion(retired, 2)).toBe(k2);
  });
});
