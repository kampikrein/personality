/**
 * test/auth/emailHashHook.test.ts — BetterAuth email_hash hook RED phase
 * Cycle 4.
 *
 * Assertions:
 *   1. emailHashBeforeCreateHook adds email_hash to user object
 *   2. email_hash = SHA-256 hex (64 chars)
 *   3. Same email → same email_hash (deterministic)
 *   4. Different email → different email_hash
 *   5. Email change recalculates email_hash
 *   6. generateEmailHash standalone: 64-char hex
 *   7. generateEmailHash same input → same output
 *
 * RED phase: stubs throw 'not implemented'.
 */

import { describe, it, expect } from "vitest";
import {
  generateEmailHash,
  emailHashBeforeCreateHook,
} from "../../src/auth/emailHashHook";

describe("emailHashHook — BetterAuth before-create", () => {
  it("emailHashBeforeCreateHook adds email_hash field", async () => {
    const user: Record<string, unknown> = {
      email: "user@example.com",
      name: "Test User",
    };
    const result = await emailHashBeforeCreateHook(user);
    expect(result).toHaveProperty("email_hash");
  });

  it("email_hash is 64-char lowercase hex", async () => {
    const user: Record<string, unknown> = { email: "hexcheck@example.com" };
    const result = await emailHashBeforeCreateHook(user);
    expect(result.email_hash as string).toMatch(/^[0-9a-f]{64}$/);
  });

  it("same email → same email_hash (deterministic)", async () => {
    const user1 = await emailHashBeforeCreateHook({ email: "same@example.com" });
    const user2 = await emailHashBeforeCreateHook({ email: "same@example.com" });
    expect(user1.email_hash).toBe(user2.email_hash);
  });

  it("different email → different email_hash", async () => {
    const user1 = await emailHashBeforeCreateHook({ email: "a@example.com" });
    const user2 = await emailHashBeforeCreateHook({ email: "b@example.com" });
    expect(user1.email_hash).not.toBe(user2.email_hash);
  });

  it("email change recalculates email_hash", async () => {
    const originalEmail = "original@example.com";
    const newEmail = "updated@example.com";
    const user1 = await emailHashBeforeCreateHook({ email: originalEmail });
    const user2 = await emailHashBeforeCreateHook({ email: newEmail });
    expect(user1.email_hash).not.toBe(user2.email_hash);
    // Confirm each hash matches standalone generateEmailHash
    expect(user1.email_hash).toBe(await generateEmailHash(originalEmail));
    expect(user2.email_hash).toBe(await generateEmailHash(newEmail));
  });
});

describe("generateEmailHash — standalone SHA-256", () => {
  it("returns 64-char lowercase hex", async () => {
    const hash = await generateEmailHash("test@example.com");
    expect(hash).toMatch(/^[0-9a-f]{64}$/);
    expect(hash).toHaveLength(64);
  });

  it("same input → same hash (deterministic)", async () => {
    const h1 = await generateEmailHash("consistent@example.com");
    const h2 = await generateEmailHash("consistent@example.com");
    expect(h1).toBe(h2);
  });

  it("different input → different hash", async () => {
    const h1 = await generateEmailHash("a@example.com");
    const h2 = await generateEmailHash("b@example.com");
    expect(h1).not.toBe(h2);
  });

  it("empty string → produces a hash (not empty)", async () => {
    const hash = await generateEmailHash("");
    expect(hash).toMatch(/^[0-9a-f]{64}$/);
  });
});
