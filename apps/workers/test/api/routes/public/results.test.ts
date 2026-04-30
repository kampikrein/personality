/**
 * test/api/routes/public/results.test.ts — Results API routes RED phase
 * Cycle 5.
 *
 * Rails origin: ResultsController (resources :results, param: :assessment_id)
 *   GET /api/results/:assessment_id       — show result (profile + insights)
 *   GET /api/results/:assessment_id/share — sharable summary
 *
 * Assertions:
 *   1. resultsRouter is exported
 *   2. GET /:assessment_id → 200 + envelope { success: true, data: { profile, insights } }
 *   3. GET /:assessment_id without auth → 401
 *   4. GET /:assessment_id not found → 404
 *   5. GET /:assessment_id for pending assessment → 422 (not ready)
 *   6. GET /:assessment_id/share → 200 + envelope (public summary)
 *
 * RED phase: stubs throw 'not implemented' → all fail.
 * GREEN phase: implement results.ts.
 */

import { describe, it, expect } from "vitest";
import { resultsRouter } from "../../../../src/api/routes/public/results";

describe("Results API Routes — RED phase", () => {
  it("resultsRouter is defined and exported", () => {
    expect(resultsRouter).toBeDefined();
  });

  describe("GET /:assessment_id", () => {
    it("returns profile + insights in envelope", async () => {
      const req = new Request("http://localhost/assess-001", {
        method: "GET",
        headers: { "Authorization": "Bearer valid-session-token" },
      });
      const res = await resultsRouter.request(req);
      expect(res.status).toBe(200);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(true);
      expect((body.data as Record<string, unknown>).profile).toBeDefined();
      expect(Array.isArray((body.data as Record<string, unknown>).insights)).toBe(true);
    });

    it("returns 401 without auth", async () => {
      const req = new Request("http://localhost/assess-001", { method: "GET" });
      const res = await resultsRouter.request(req);
      expect(res.status).toBe(401);
    });

    it("returns 404 for unknown assessment", async () => {
      const req = new Request("http://localhost/nonexistent-assess", {
        method: "GET",
        headers: { "Authorization": "Bearer valid-session-token" },
      });
      const res = await resultsRouter.request(req);
      expect(res.status).toBe(404);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(false);
      expect((body.error as Record<string, unknown>).code).toBe("not_found");
    });

    it("returns 422 for pending (not-yet-scored) assessment", async () => {
      const req = new Request("http://localhost/pending-assess-id", {
        method: "GET",
        headers: { "Authorization": "Bearer valid-session-token" },
      });
      const res = await resultsRouter.request(req);
      expect(res.status).toBe(422);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(false);
    });
  });

  describe("GET /:assessment_id/share", () => {
    it("returns public share summary in envelope", async () => {
      const req = new Request("http://localhost/assess-001/share", {
        method: "GET",
        headers: { "Authorization": "Bearer valid-session-token" },
      });
      const res = await resultsRouter.request(req);
      expect(res.status).toBe(200);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(true);
      expect((body.data as Record<string, unknown>).shareUrl).toBeDefined();
    });
  });
});
