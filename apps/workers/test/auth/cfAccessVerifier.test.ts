/**
 * test/auth/cfAccessVerifier.test.ts — CF Access JWT verifier RED phase
 * Cycle 4.
 *
 * Assertions:
 *   1. Valid JWT (fake JWKS) → payload extracted
 *   2. Expired JWT → rejects
 *   3. Wrong signature → rejects
 *   4. Missing Cf-Access-Jwt-Assertion header → rejects
 *   5. JWT payload admin claim extracted correctly
 *   6. JWKS resolver DI: fake JWKS injected (real SSO = Phase 2)
 *
 * RED phase: stubs throw 'not implemented'.
 * GREEN phase: implement createCFAccessVerifier with jose/Web Crypto JWT verify.
 */

import { describe, it, expect } from "vitest";
import {
  createCFAccessVerifier,
  extractAdminClaim,
  type JwksResolver,
  type CFAccessPayload,
} from "../../src/auth/cfAccessVerifier";

// ─── Fake JWKS helpers ──────────────────────────────────────────────────────
// These are placeholder fixtures. GREEN phase will use createLocalJWKSet (jose)
// to generate real RS256 key pairs for signing/verifying.

const fakeJwksResolver: JwksResolver = {
  async resolve() {
    return {
      keys: [
        {
          kty: "RSA",
          kid: "fake-key-1",
          use: "sig",
          alg: "RS256",
          // n and e are placeholder — GREEN phase generates real keys
          n: "placeholder",
          e: "AQAB",
        } as JsonWebKey,
      ],
    };
  },
};

const FAKE_VALID_JWT = "eyJhbGciOiJSUzI1NiIsImtpZCI6ImZha2Uta2V5LTEifQ.placeholder.placeholder";
const FAKE_EXPIRED_JWT = "eyJhbGciOiJSUzI1NiIsImtpZCI6ImZha2Uta2V5LTEifQ.expired.placeholder";
const FAKE_BAD_SIG_JWT = "eyJhbGciOiJSUzI1NiIsImtpZCI6ImZha2Uta2V5LTEifQ.payload.badsig";

// ─── Tests ───────────────────────────────────────────────────────────────────

describe("CF Access JWT Verifier — JWKS resolver DI", () => {
  it("createCFAccessVerifier returns a verify function (no throw on creation)", () => {
    const verify = createCFAccessVerifier(fakeJwksResolver);
    expect(typeof verify).toBe("function");
  });

  it("valid JWT → resolves with payload", async () => {
    const verify = createCFAccessVerifier(fakeJwksResolver);
    // GREEN phase: sign a real RS256 JWT with fakeJwksResolver's private key
    const payload = await verify(FAKE_VALID_JWT);
    expect(payload).toBeDefined();
    expect(typeof payload.sub).toBe("string");
    expect(typeof payload.email).toBe("string");
    expect(typeof payload.exp).toBe("number");
  });

  it("expired JWT → rejects with error", async () => {
    const verify = createCFAccessVerifier(fakeJwksResolver);
    await expect(verify(FAKE_EXPIRED_JWT)).rejects.toThrow();
  });

  it("wrong signature JWT → rejects with error", async () => {
    const verify = createCFAccessVerifier(fakeJwksResolver);
    await expect(verify(FAKE_BAD_SIG_JWT)).rejects.toThrow();
  });

  it("empty/missing JWT → rejects with error", async () => {
    const verify = createCFAccessVerifier(fakeJwksResolver);
    await expect(verify("")).rejects.toThrow();
  });

  it("extractAdminClaim returns true when admin=true in payload", () => {
    const payload: CFAccessPayload = {
      sub: "user123",
      email: "admin@example.com",
      aud: ["test-audience"],
      iss: "https://testteam.cloudflareaccess.com",
      iat: Math.floor(Date.now() / 1000),
      exp: Math.floor(Date.now() / 1000) + 3600,
      admin: true,
    };
    expect(extractAdminClaim(payload)).toBe(true);
  });

  it("extractAdminClaim returns false when admin=false in payload", () => {
    const payload: CFAccessPayload = {
      sub: "user456",
      email: "regular@example.com",
      aud: ["test-audience"],
      iss: "https://testteam.cloudflareaccess.com",
      iat: Math.floor(Date.now() / 1000),
      exp: Math.floor(Date.now() / 1000) + 3600,
      admin: false,
    };
    expect(extractAdminClaim(payload)).toBe(false);
  });

  it("extractAdminClaim returns false when admin claim is absent", () => {
    const payload: CFAccessPayload = {
      sub: "user789",
      email: "noadmin@example.com",
      aud: ["test-audience"],
      iss: "https://testteam.cloudflareaccess.com",
      iat: Math.floor(Date.now() / 1000),
      exp: Math.floor(Date.now() / 1000) + 3600,
    };
    expect(extractAdminClaim(payload)).toBe(false);
  });

  it("JWKS resolver is injected — fake resolver produces fake keys (no real SSO)", async () => {
    const jwks = await fakeJwksResolver.resolve();
    expect(jwks.keys).toHaveLength(1);
    expect(jwks.keys[0].kid).toBe("fake-key-1");
  });
});
