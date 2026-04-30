/**
 * test/api/routes/admin/alerts.test.ts — Admin Alerts API routes RED phase
 * Cycle 5.
 *
 * Rails origin: Admin::AlertsController (resources :alerts, only: [:index, :show, :update])
 *   GET   /admin/alerts     — index
 *   GET   /admin/alerts/:id — show
 *   PATCH /admin/alerts/:id — acknowledge/update
 *
 * Assertions:
 *   1. adminAlertsRouter is exported
 *   2. GET / without JWT → 403
 *   3. GET / → 200 + alert list
 *   4. GET /:id → 200 + single alert
 *   5. GET /:id not found → 404
 *   6. PATCH /:id → 200 + acknowledged alert
 *   7. POST / → 405 (alerts are system-generated, not creatable via API)
 *
 * RED phase: stubs throw 'not implemented' → all fail.
 * GREEN phase: implement alerts.ts with cfAccessVerifier.
 */

import { describe, it, expect } from "vitest";
import { adminAlertsRouter } from "../../../../src/api/routes/admin/alerts";

const VALID_ADMIN_JWT = "eyJhbGciOiJSUzI1NiJ9.admin.fakesig";

describe("Admin Alerts API Routes — RED phase", () => {
  it("adminAlertsRouter is defined and exported", () => {
    expect(adminAlertsRouter).toBeDefined();
  });

  describe("GET / (index)", () => {
    it("returns 403 without CF Access JWT", async () => {
      const req = new Request("http://localhost/", { method: "GET" });
      const res = await adminAlertsRouter.request(req);
      expect(res.status).toBe(403);
    });

    it("returns 200 + alert list with valid JWT", async () => {
      const req = new Request("http://localhost/", {
        method: "GET",
        headers: { "Cf-Access-Jwt-Assertion": VALID_ADMIN_JWT },
      });
      const res = await adminAlertsRouter.request(req);
      expect(res.status).toBe(200);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(true);
      expect(Array.isArray((body.data as Record<string, unknown>).alerts)).toBe(true);
    });
  });

  describe("GET /:id", () => {
    it("returns single alert with valid JWT", async () => {
      const req = new Request("http://localhost/alert-001", {
        method: "GET",
        headers: { "Cf-Access-Jwt-Assertion": VALID_ADMIN_JWT },
      });
      const res = await adminAlertsRouter.request(req);
      expect(res.status).toBe(200);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(true);
      expect((body.data as Record<string, unknown>).id).toBe("alert-001");
    });

    it("returns 404 for unknown alert", async () => {
      const req = new Request("http://localhost/nonexistent", {
        method: "GET",
        headers: { "Cf-Access-Jwt-Assertion": VALID_ADMIN_JWT },
      });
      const res = await adminAlertsRouter.request(req);
      expect(res.status).toBe(404);
    });
  });

  describe("PATCH /:id (acknowledge)", () => {
    it("acknowledges alert and returns updated status", async () => {
      const req = new Request("http://localhost/alert-001", {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "Cf-Access-Jwt-Assertion": VALID_ADMIN_JWT,
        },
        body: JSON.stringify({ status: "acknowledged" }),
      });
      const res = await adminAlertsRouter.request(req);
      expect(res.status).toBe(200);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(true);
      expect((body.data as Record<string, unknown>).status).toBe("acknowledged");
    });
  });

  describe("write constraints", () => {
    it("POST / returns 405 (alerts are system-generated)", async () => {
      const req = new Request("http://localhost/", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Cf-Access-Jwt-Assertion": VALID_ADMIN_JWT,
        },
        body: JSON.stringify({}),
      });
      const res = await adminAlertsRouter.request(req);
      expect(res.status).toBe(405);
    });
  });
});
