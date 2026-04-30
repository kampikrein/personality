/**
 * test/crypto/emailHash.test.ts — SHA-256 email hash standalone RED phase
 * Cycle 4.
 *
 * Assertions:
 *   1. sha256Hex returns 64-char lowercase hex
 *   2. Same input → same hash (deterministic)
 *   3. Different input → different hash
 *   4. Empty string → valid 64-char hash (SHA-256("") is defined)
 *   5. Unicode email → valid 64-char hash
 *   6. Key-independence: sha256Hex uses no HMAC key
 *
 * RED phase: stub throws 'not implemented'.
 */

import { describe, it, expect } from "vitest";
import { sha256Hex } from "../../src/crypto/emailHash";

describe("sha256Hex — Web Crypto SHA-256", () => {
  it("returns 64-char lowercase hex string", async () => {
    const hash = await sha256Hex("test@example.com");
    expect(hash).toHaveLength(64);
    expect(hash).toMatch(/^[0-9a-f]{64}$/);
  });

  it("same input → same hash (deterministic)", async () => {
    const h1 = await sha256Hex("same@example.com");
    const h2 = await sha256Hex("same@example.com");
    expect(h1).toBe(h2);
  });

  it("different input → different hash", async () => {
    const h1 = await sha256Hex("a@example.com");
    const h2 = await sha256Hex("b@example.com");
    expect(h1).not.toBe(h2);
  });

  it("empty string → valid 64-char hash", async () => {
    const hash = await sha256Hex("");
    expect(hash).toHaveLength(64);
    expect(hash).toMatch(/^[0-9a-f]{64}$/);
  });

  it("SHA-256('') produces known value", async () => {
    // SHA-256 of empty string is a known constant
    const hash = await sha256Hex("");
    expect(hash).toBe("e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855");
  });

  it("unicode email → valid 64-char hash", async () => {
    const hash = await sha256Hex("tëst@ëxämplé.com");
    expect(hash).toHaveLength(64);
    expect(hash).toMatch(/^[0-9a-f]{64}$/);
  });

  it("email case sensitivity: lowercase ≠ uppercase", async () => {
    const h1 = await sha256Hex("user@example.com");
    const h2 = await sha256Hex("USER@EXAMPLE.COM");
    // SHA-256 is case-sensitive; caller normalizes email before hashing
    expect(h1).not.toBe(h2);
  });
});
