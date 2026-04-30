/**
 * test/api/routes/admin/dashboard.test.ts — Admin Dashboard API routes RED phase
 * Cycle 5.
 *
 * Rails origin: Admin::DashboardController
 *   GET /admin/dashboard                   — index (root)
 *   GET /admin/dashboard/completion_rates  — completion rate stats
 *   GET /admin/dashboard/drop_off_analysis — drop-off analysis
 *
 * Assertions:
 *   1. adminDashboardRouter is exported
 *   2. GET / without JWT → 403
 *   3. GET / → 200 + dashboard summary stats
 *   4. GET /completion_rates → 200 + completion rate data
 *   5. GET /drop_off_analysis → 200 + drop-off analysis data
 *   6. All routes require CF Access JWT
 *
 * RED phase: stubs throw 'not implemented' → all fail.
 * GREEN phase: implement dashboard.ts with cfAccessVerifier.
 */

import { describe, it, expect } from "vitest";
import { adminDashboardRouter } from "../../../../src/api/routes/admin/dashboard";

const VALID_ADMIN_JWT = "eyJhbGciOiJSUzI1NiJ9.admin.fakesig";

describe("Admin Dashboard API Routes — RED phase", () => {
  it("adminDashboardRouter is defined and exported", () => {
    expect(adminDashboardRouter).toBeDefined();
  });

  describe("GET / (index)", () => {
    it("returns 403 without CF Access JWT", async () => {
      const req = new Request("http://localhost/", { method: "GET" });
      const res = await adminDashboardRouter.request(req);
      expect(res.status).toBe(403);
    });

    it("returns dashboard summary stats with valid JWT", async () => {
      const req = new Request("http://localhost/", {
        method: "GET",
        headers: { "Cf-Access-Jwt-Assertion": VALID_ADMIN_JWT },
      });
      const res = await adminDashboardRouter.request(req);
      expect(res.status).toBe(200);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(true);
      const data = body.data as Record<string, unknown>;
      expect(data.totalAssessments).toBeDefined();
      expect(data.completionRate).toBeDefined();
    });
  });

  describe("GET /completion_rates", () => {
    it("returns 403 without JWT", async () => {
      const req = new Request("http://localhost/completion_rates", { method: "GET" });
      const res = await adminDashboardRouter.request(req);
      expect(res.status).toBe(403);
    });

    it("returns completion rate data with valid JWT", async () => {
      const req = new Request("http://localhost/completion_rates", {
        method: "GET",
        headers: { "Cf-Access-Jwt-Assertion": VALID_ADMIN_JWT },
      });
      const res = await adminDashboardRouter.request(req);
      expect(res.status).toBe(200);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(true);
      expect(Array.isArray((body.data as Record<string, unknown>).rates)).toBe(true);
    });
  });

  describe("GET /drop_off_analysis", () => {
    it("returns 403 without JWT", async () => {
      const req = new Request("http://localhost/drop_off_analysis", { method: "GET" });
      const res = await adminDashboardRouter.request(req);
      expect(res.status).toBe(403);
    });

    it("returns drop-off analysis with valid JWT", async () => {
      const req = new Request("http://localhost/drop_off_analysis", {
        method: "GET",
        headers: { "Cf-Access-Jwt-Assertion": VALID_ADMIN_JWT },
      });
      const res = await adminDashboardRouter.request(req);
      expect(res.status).toBe(200);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(true);
      expect((body.data as Record<string, unknown>).dropOffPoints).toBeDefined();
    });
  });
});
