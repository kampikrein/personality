/**
 * test/auth/betterAuth.test.ts — BetterAuth(D1+KV) RED phase
 * Cycle 4.
 *
 * Assertions:
 *   1. createAuth produces an auth instance (D1 + KV adapter)
 *   2. signUp → user row with email_hash + email_enc + encryption_version
 *   3. signUp email_hash is 64-char SHA-256 hex (deterministic)
 *   4. signIn → session stored in KV
 *   5. signOut → session removed from KV
 *   6. getSession → null after signOut
 *   7. lookupUserByEmailHash — deterministic email lookup
 *   8. Schema compatibility: users table has R4 columns (email_hash, email_enc, encryption_version)
 *   9. Duplicate email signup → error (unique email_hash constraint)
 *
 * RED phase: all stubs throw 'not implemented' → all fail.
 * GREEN phase: implement betterAuth.ts + emailHashHook.ts.
 */

import { describe, it, expect, beforeEach } from "vitest";
import { env } from "cloudflare:test";
import {
  createAuth,
  signUp,
  signIn,
  signOut,
  getSession,
  lookupUserByEmailHash,
} from "../../src/auth/betterAuth";

describe("BetterAuth — D1 + KV", () => {
  let auth: unknown;

  beforeEach(() => {
    auth = createAuth({ d1: env.DB, kv: env.KV });
  });

  it("createAuth returns an auth instance without throwing", () => {
    expect(auth).toBeDefined();
    expect(auth).not.toBeNull();
  });

  it("signUp inserts user row with email_hash, email_enc, encryption_version", async () => {
    const email = `test_${Date.now()}@example.com`;
    const user = await signUp(auth, email, "password123");

    expect(user).toBeDefined();
    expect(user.emailHash).toBeDefined();
    expect(user.emailEnc).toBeDefined();
    expect(user.encryptionVersion).toBeGreaterThanOrEqual(1);
    expect(typeof user.id).toBe("number");
  });

  it("signUp email_hash is 64-char lowercase hex (SHA-256)", async () => {
    const email = `hashcheck_${Date.now()}@example.com`;
    const user = await signUp(auth, email, "password456");

    expect(user.emailHash).toMatch(/^[0-9a-f]{64}$/);
  });

  it("signUp same email → same email_hash (deterministic)", async () => {
    const email = `det_${Date.now()}@example.com`;
    const user1 = await signUp(auth, email, "pw1");
    // Lookup by hash should find same user
    const found = await lookupUserByEmailHash(env.DB, user1.emailHash);
    expect(found).not.toBeNull();
    expect(found!.emailHash).toBe(user1.emailHash);
  });

  it("signIn returns session with sessionId stored in KV", async () => {
    const email = `signin_${Date.now()}@example.com`;
    await signUp(auth, email, "securepass");
    const result = await signIn(auth, email, "securepass");

    expect(result).toBeDefined();
    expect(typeof result.sessionId).toBe("string");
    expect(result.sessionId.length).toBeGreaterThan(0);
    expect(result.user.emailHash).toMatch(/^[0-9a-f]{64}$/);

    // Session should be in KV
    const session = await getSession(env.KV, result.sessionId);
    expect(session).not.toBeNull();
    expect(session!.userId).toBe(result.user.id);
  });

  it("signOut removes session from KV", async () => {
    const email = `signout_${Date.now()}@example.com`;
    await signUp(auth, email, "securepass");
    const { sessionId } = await signIn(auth, email, "securepass");

    await signOut(env.KV, sessionId);
    const session = await getSession(env.KV, sessionId);
    expect(session).toBeNull();
  });

  it("getSession returns null for unknown sessionId", async () => {
    const session = await getSession(env.KV, "nonexistent-session-id");
    expect(session).toBeNull();
  });

  it("lookupUserByEmailHash returns null for unknown hash", async () => {
    const result = await lookupUserByEmailHash(env.DB, "0".repeat(64));
    expect(result).toBeNull();
  });

  it("users table has R4 columns: email_hash, email_enc, encryption_version", async () => {
    // Verify schema compatibility via D1 PRAGMA
    const result = await env.DB.prepare("PRAGMA table_info(users)").all<{
      name: string;
      type: string;
      notnull: number;
    }>();
    const columns = result.results.map((r) => r.name);
    expect(columns).toContain("email_hash");
    expect(columns).toContain("email_enc");
    expect(columns).toContain("encryption_version");
  });

  it("duplicate email signup throws unique constraint error", async () => {
    const email = `dup_${Date.now()}@example.com`;
    await signUp(auth, email, "pass1");
    await expect(signUp(auth, email, "pass2")).rejects.toThrow();
  });
});
