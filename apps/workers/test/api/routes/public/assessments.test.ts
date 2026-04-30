/**
 * test/api/routes/public/assessments.test.ts — Assessments API routes RED phase
 * Cycle 5.
 *
 * Rails origin: AssessmentsController
 *   POST   /api/assessments            — create
 *   GET    /api/assessments/:id        — show
 *   POST   /api/assessments/:id/complete — complete (triggers saga)
 *   PATCH  /api/assessments/:id/submit  — submit
 *
 * Assertions:
 *   1. Router is exported (assessmentsRouter)
 *   2. POST / → 200 + envelope { success: true, data: { id, status } }
 *   3. POST / without auth → 401 + envelope error
 *   4. GET /:id → 200 + envelope { success: true, data: { id, status } }
 *   5. GET /:id not found → 404 + envelope error { code: 'not_found' }
 *   6. POST /:id/complete → 200 + envelope { success: true, data: { status: 'completed' } }
 *   7. POST /:id/complete already completed → 409 conflict
 *   8. PATCH /:id/submit → 200 + envelope
 *   9. All routes require BetterAuth session (Bearer or cookie)
 *
 * RED phase: stubs throw 'not implemented' → all fail.
 * GREEN phase: implement assessments.ts.
 */

import { describe, it, expect } from "vitest";
import { assessmentsRouter } from "../../../../src/api/routes/public/assessments";

describe("Assessments API Routes — RED phase", () => {
  it("assessmentsRouter is defined and exported", () => {
    expect(assessmentsRouter).toBeDefined();
  });

  describe("POST /", () => {
    it("creates assessment and returns envelope { success: true, data: { id, status } }", async () => {
      const req = new Request("http://localhost/", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer valid-session-token",
        },
        body: JSON.stringify({}),
      });
      const res = await assessmentsRouter.request(req);
      expect(res.status).toBe(200);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(true);
      expect((body.data as Record<string, unknown>).id).toBeDefined();
      expect((body.data as Record<string, unknown>).status).toBe("pending");
    });

    it("returns 401 when no auth provided", async () => {
      const req = new Request("http://localhost/", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({}),
      });
      const res = await assessmentsRouter.request(req);
      expect(res.status).toBe(401);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(false);
      expect((body.error as Record<string, unknown>).code).toBe("unauthorized");
    });
  });

  describe("GET /:id", () => {
    it("returns assessment status in envelope", async () => {
      const req = new Request("http://localhost/test-id-123", {
        method: "GET",
        headers: { "Authorization": "Bearer valid-session-token" },
      });
      const res = await assessmentsRouter.request(req);
      expect(res.status).toBe(200);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(true);
      expect((body.data as Record<string, unknown>).id).toBe("test-id-123");
    });

    it("returns 404 for unknown id", async () => {
      const req = new Request("http://localhost/nonexistent-id", {
        method: "GET",
        headers: { "Authorization": "Bearer valid-session-token" },
      });
      const res = await assessmentsRouter.request(req);
      expect(res.status).toBe(404);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(false);
      expect((body.error as Record<string, unknown>).code).toBe("not_found");
    });
  });

  describe("POST /:id/complete", () => {
    it("completes assessment and returns { status: 'completed' }", async () => {
      const req = new Request("http://localhost/test-id-123/complete", {
        method: "POST",
        headers: { "Authorization": "Bearer valid-session-token" },
      });
      const res = await assessmentsRouter.request(req);
      expect(res.status).toBe(200);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(true);
      expect((body.data as Record<string, unknown>).status).toBe("completed");
    });

    it("returns 409 when already completed", async () => {
      const req = new Request("http://localhost/completed-id/complete", {
        method: "POST",
        headers: { "Authorization": "Bearer valid-session-token" },
      });
      const res = await assessmentsRouter.request(req);
      expect(res.status).toBe(409);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(false);
      expect((body.error as Record<string, unknown>).code).toBe("conflict");
    });
  });

  describe("PATCH /:id/submit", () => {
    it("submits assessment and returns envelope", async () => {
      const req = new Request("http://localhost/test-id-123/submit", {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer valid-session-token",
        },
        body: JSON.stringify({ answers: [] }),
      });
      const res = await assessmentsRouter.request(req);
      expect(res.status).toBe(200);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(true);
    });
  });
});
