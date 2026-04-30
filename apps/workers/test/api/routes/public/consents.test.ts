/**
 * test/api/routes/public/consents.test.ts — Consents API routes RED phase
 * Cycle 5.
 *
 * Rails origin: ConsentsController (resources :consents, only: [:new, :create, :show, :update])
 *   GET    /api/consents/:id — show
 *   POST   /api/consents     — create
 *   DELETE /api/consents/:id — withdraw (mapped from update action)
 *   PATCH  /api/consents/:id — update
 *
 * Assertions:
 *   1. consentsRouter is exported
 *   2. POST / → 201 + envelope { success: true, data: { id, consentType, status } }
 *   3. POST / without auth → 401
 *   4. POST / with missing fields → 400 validation_failed
 *   5. GET /:id → 200 + consent record
 *   6. GET /:id not found → 404
 *   7. DELETE /:id → 200 + envelope (withdrawal confirmed)
 *   8. DELETE /:id without auth → 401
 *   9. PATCH /:id → 200 + updated consent
 *
 * RED phase: stubs throw 'not implemented' → all fail.
 * GREEN phase: implement consents.ts.
 */

import { describe, it, expect } from "vitest";
import { consentsRouter } from "../../../../src/api/routes/public/consents";

describe("Consents API Routes — RED phase", () => {
  it("consentsRouter is defined and exported", () => {
    expect(consentsRouter).toBeDefined();
  });

  describe("POST / (create consent)", () => {
    it("creates consent record and returns 201 with envelope", async () => {
      const req = new Request("http://localhost/", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer valid-session-token",
        },
        body: JSON.stringify({ consentType: "data_processing", agreed: true }),
      });
      const res = await consentsRouter.request(req);
      expect(res.status).toBe(201);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(true);
      expect((body.data as Record<string, unknown>).id).toBeDefined();
      expect((body.data as Record<string, unknown>).status).toBe("active");
    });

    it("returns 401 without auth", async () => {
      const req = new Request("http://localhost/", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ consentType: "data_processing", agreed: true }),
      });
      const res = await consentsRouter.request(req);
      expect(res.status).toBe(401);
    });

    it("returns 400 when consentType missing", async () => {
      const req = new Request("http://localhost/", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer valid-session-token",
        },
        body: JSON.stringify({}),
      });
      const res = await consentsRouter.request(req);
      expect(res.status).toBe(400);
      const body = await res.json() as Record<string, unknown>;
      expect((body.error as Record<string, unknown>).code).toBe("validation_failed");
    });
  });

  describe("GET /:id", () => {
    it("returns consent record in envelope", async () => {
      const req = new Request("http://localhost/consent-001", {
        method: "GET",
        headers: { "Authorization": "Bearer valid-session-token" },
      });
      const res = await consentsRouter.request(req);
      expect(res.status).toBe(200);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(true);
    });

    it("returns 404 for unknown consent", async () => {
      const req = new Request("http://localhost/nonexistent", {
        method: "GET",
        headers: { "Authorization": "Bearer valid-session-token" },
      });
      const res = await consentsRouter.request(req);
      expect(res.status).toBe(404);
    });
  });

  describe("DELETE /:id (withdraw)", () => {
    it("withdraws consent and returns envelope", async () => {
      const req = new Request("http://localhost/consent-001", {
        method: "DELETE",
        headers: { "Authorization": "Bearer valid-session-token" },
      });
      const res = await consentsRouter.request(req);
      expect(res.status).toBe(200);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(true);
      expect((body.data as Record<string, unknown>).status).toBe("withdrawn");
    });

    it("returns 401 without auth", async () => {
      const req = new Request("http://localhost/consent-001", { method: "DELETE" });
      const res = await consentsRouter.request(req);
      expect(res.status).toBe(401);
    });
  });

  describe("PATCH /:id", () => {
    it("updates consent and returns envelope", async () => {
      const req = new Request("http://localhost/consent-001", {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer valid-session-token",
        },
        body: JSON.stringify({ agreed: false }),
      });
      const res = await consentsRouter.request(req);
      expect(res.status).toBe(200);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(true);
    });
  });
});
