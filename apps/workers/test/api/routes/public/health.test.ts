/**
 * test/api/routes/public/health.test.ts — Health API route RED phase
 * Cycle 5.
 *
 * Rails origin: GET /up → rails/health#show
 * Hono: GET /api/health (envelope-wrapped version of existing /health)
 *
 * Assertions:
 *   1. healthRouter is exported
 *   2. GET / → 200 + envelope { success: true, data: { ok: true } }
 *   3. Response includes timestamp
 *   4. No auth required
 *
 * RED phase: stubs throw 'not implemented' → all fail.
 * GREEN phase: implement health.ts (wrap existing /health with envelope).
 */

import { describe, it, expect } from "vitest";
import { healthRouter } from "../../../../src/api/routes/public/health";

describe("Health API Route — RED phase", () => {
  it("healthRouter is defined and exported", () => {
    expect(healthRouter).toBeDefined();
  });

  describe("GET /", () => {
    it("returns 200 with envelope { success: true, data: { ok: true } }", async () => {
      const req = new Request("http://localhost/", { method: "GET" });
      const res = await healthRouter.request(req);
      expect(res.status).toBe(200);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(true);
      expect((body.data as Record<string, unknown>).ok).toBe(true);
    });

    it("response includes timestamp", async () => {
      const req = new Request("http://localhost/", { method: "GET" });
      const res = await healthRouter.request(req);
      const body = await res.json() as Record<string, unknown>;
      expect((body.data as Record<string, unknown>).timestamp).toBeDefined();
      // Should be a valid ISO date string
      const ts = (body.data as Record<string, unknown>).timestamp as string;
      expect(new Date(ts).toISOString()).toBe(ts);
    });

    it("no auth required", async () => {
      // Should succeed without Authorization header
      const req = new Request("http://localhost/", { method: "GET" });
      const res = await healthRouter.request(req);
      expect(res.status).toBe(200);
    });
  });
});
