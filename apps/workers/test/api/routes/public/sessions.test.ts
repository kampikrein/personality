/**
 * test/api/routes/public/sessions.test.ts — Sessions API routes RED phase
 * Cycle 5.
 *
 * Rails origin: SessionsController
 *   POST   /api/sessions    — login (create)
 *   DELETE /api/sessions    — logout (destroy)
 *   GET    /api/sessions/me — current session (new → me)
 *
 * Assertions:
 *   1. sessionsRouter is exported
 *   2. POST / → 200 + envelope { success: true, data: { userId, sessionToken } }
 *   3. POST / with invalid credentials → 401 + envelope error
 *   4. POST / with missing fields → 400 + validation_failed
 *   5. DELETE / → 200 + envelope { success: true, data: null }
 *   6. DELETE / without session → 401
 *   7. GET /me → 200 + envelope { success: true, data: { id, email } }
 *   8. GET /me without session → 401
 *
 * RED phase: stubs throw 'not implemented' → all fail.
 * GREEN phase: implement sessions.ts with BetterAuth.
 */

import { describe, it, expect } from "vitest";
import { sessionsRouter } from "../../../../src/api/routes/public/sessions";

describe("Sessions API Routes — RED phase", () => {
  it("sessionsRouter is defined and exported", () => {
    expect(sessionsRouter).toBeDefined();
  });

  describe("POST / (login)", () => {
    it("returns session token on valid credentials", async () => {
      const req = new Request("http://localhost/", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email: "user@example.com", password: "password123" }),
      });
      const res = await sessionsRouter.request(req);
      expect(res.status).toBe(200);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(true);
      expect((body.data as Record<string, unknown>).sessionToken).toBeDefined();
    });

    it("returns 401 on invalid credentials", async () => {
      const req = new Request("http://localhost/", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email: "user@example.com", password: "wrong" }),
      });
      const res = await sessionsRouter.request(req);
      expect(res.status).toBe(401);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(false);
      expect((body.error as Record<string, unknown>).code).toBe("unauthorized");
    });

    it("returns 400 when email or password missing", async () => {
      const req = new Request("http://localhost/", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email: "user@example.com" }),
      });
      const res = await sessionsRouter.request(req);
      expect(res.status).toBe(400);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(false);
      expect((body.error as Record<string, unknown>).code).toBe("validation_failed");
    });
  });

  describe("DELETE / (logout)", () => {
    it("logs out and returns { success: true, data: null }", async () => {
      const req = new Request("http://localhost/", {
        method: "DELETE",
        headers: { "Authorization": "Bearer valid-session-token" },
      });
      const res = await sessionsRouter.request(req);
      expect(res.status).toBe(200);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(true);
      expect((body.data as null | unknown)).toBeNull();
    });

    it("returns 401 without session", async () => {
      const req = new Request("http://localhost/", { method: "DELETE" });
      const res = await sessionsRouter.request(req);
      expect(res.status).toBe(401);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(false);
    });
  });

  describe("GET /me", () => {
    it("returns current user in envelope", async () => {
      const req = new Request("http://localhost/me", {
        method: "GET",
        headers: { "Authorization": "Bearer valid-session-token" },
      });
      const res = await sessionsRouter.request(req);
      expect(res.status).toBe(200);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(true);
      expect((body.data as Record<string, unknown>).id).toBeDefined();
    });

    it("returns 401 without session", async () => {
      const req = new Request("http://localhost/me", { method: "GET" });
      const res = await sessionsRouter.request(req);
      expect(res.status).toBe(401);
    });
  });
});
