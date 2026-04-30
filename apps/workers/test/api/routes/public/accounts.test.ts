/**
 * test/api/routes/public/accounts.test.ts — Accounts API routes RED phase
 * Cycle 5.
 *
 * Rails origin: AccountController (resource :account)
 *   POST  /api/accounts    — signup (create)
 *   GET   /api/accounts/me — current account
 *   PATCH /api/accounts/me — update account
 *
 * Assertions:
 *   1. accountsRouter is exported
 *   2. POST / → 201 + envelope { success: true, data: { id, email } }
 *   3. POST / with duplicate email → 409 conflict
 *   4. POST / with invalid email → 400 validation_failed
 *   5. GET /me → 200 + envelope { success: true, data: { id, email } }
 *   6. GET /me without auth → 401
 *   7. PATCH /me → 200 + envelope { success: true, data: updated account }
 *   8. PATCH /me without auth → 401
 *
 * RED phase: stubs throw 'not implemented' → all fail.
 * GREEN phase: implement accounts.ts.
 */

import { describe, it, expect } from "vitest";
import { accountsRouter } from "../../../../src/api/routes/public/accounts";

describe("Accounts API Routes — RED phase", () => {
  it("accountsRouter is defined and exported", () => {
    expect(accountsRouter).toBeDefined();
  });

  describe("POST / (signup)", () => {
    it("creates account and returns 201 with envelope", async () => {
      const req = new Request("http://localhost/", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          email: "new@example.com",
          password: "secure-password-123",
        }),
      });
      const res = await accountsRouter.request(req);
      expect(res.status).toBe(201);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(true);
      expect((body.data as Record<string, unknown>).id).toBeDefined();
      expect((body.data as Record<string, unknown>).email).toBe("new@example.com");
    });

    it("returns 409 conflict on duplicate email", async () => {
      const req = new Request("http://localhost/", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          email: "existing@example.com",
          password: "password123",
        }),
      });
      const res = await accountsRouter.request(req);
      expect(res.status).toBe(409);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(false);
      expect((body.error as Record<string, unknown>).code).toBe("conflict");
    });

    it("returns 400 with validation_failed for invalid email", async () => {
      const req = new Request("http://localhost/", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email: "not-an-email", password: "password" }),
      });
      const res = await accountsRouter.request(req);
      expect(res.status).toBe(400);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(false);
      expect((body.error as Record<string, unknown>).code).toBe("validation_failed");
    });
  });

  describe("GET /me", () => {
    it("returns current account in envelope", async () => {
      const req = new Request("http://localhost/me", {
        method: "GET",
        headers: { "Authorization": "Bearer valid-session-token" },
      });
      const res = await accountsRouter.request(req);
      expect(res.status).toBe(200);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(true);
      expect((body.data as Record<string, unknown>).id).toBeDefined();
    });

    it("returns 401 without auth", async () => {
      const req = new Request("http://localhost/me", { method: "GET" });
      const res = await accountsRouter.request(req);
      expect(res.status).toBe(401);
    });
  });

  describe("PATCH /me", () => {
    it("updates account and returns updated data", async () => {
      const req = new Request("http://localhost/me", {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer valid-session-token",
        },
        body: JSON.stringify({ displayName: "New Name" }),
      });
      const res = await accountsRouter.request(req);
      expect(res.status).toBe(200);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(true);
    });

    it("returns 401 without auth", async () => {
      const req = new Request("http://localhost/me", {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({}),
      });
      const res = await accountsRouter.request(req);
      expect(res.status).toBe(401);
    });
  });
});
