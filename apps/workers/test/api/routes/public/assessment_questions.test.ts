/**
 * test/api/routes/public/assessment_questions.test.ts — Assessment Questions API routes RED phase
 * Cycle 5.
 *
 * Rails origin: AssessmentQuestionsController
 *   GET   /api/assessments/:assessment_id/questions/:id — show question
 *   PATCH /api/assessments/:assessment_id/questions/:id — submit answer
 *   GET   /api/assessment_questions                     — list active question set questions
 *
 * Assertions:
 *   1. assessmentQuestionsRouter is exported
 *   2. GET / → 200 + list of questions for active question_set
 *   3. GET / without auth → 401
 *   4. GET /:id → 200 + single question with options
 *   5. GET /:id not found → 404
 *   6. PATCH /:id → 200 + envelope (answer recorded)
 *   7. PATCH /:id with invalid answer → 400 validation_failed
 *
 * RED phase: stubs throw 'not implemented' → all fail.
 * GREEN phase: implement assessment_questions.ts.
 */

import { describe, it, expect } from "vitest";
import { assessmentQuestionsRouter } from "../../../../src/api/routes/public/assessment_questions";

describe("Assessment Questions API Routes — RED phase", () => {
  it("assessmentQuestionsRouter is defined and exported", () => {
    expect(assessmentQuestionsRouter).toBeDefined();
  });

  describe("GET / (list active question set)", () => {
    it("returns active question set questions in envelope", async () => {
      const req = new Request("http://localhost/", {
        method: "GET",
        headers: { "Authorization": "Bearer valid-session-token" },
      });
      const res = await assessmentQuestionsRouter.request(req);
      expect(res.status).toBe(200);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(true);
      expect(Array.isArray((body.data as Record<string, unknown>).questions)).toBe(true);
    });

    it("returns 401 without auth", async () => {
      const req = new Request("http://localhost/", { method: "GET" });
      const res = await assessmentQuestionsRouter.request(req);
      expect(res.status).toBe(401);
    });
  });

  describe("GET /:id", () => {
    it("returns single question with options", async () => {
      const req = new Request("http://localhost/q-001", {
        method: "GET",
        headers: { "Authorization": "Bearer valid-session-token" },
      });
      const res = await assessmentQuestionsRouter.request(req);
      expect(res.status).toBe(200);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(true);
      expect((body.data as Record<string, unknown>).id).toBe("q-001");
      expect(Array.isArray((body.data as Record<string, unknown>).options)).toBe(true);
    });

    it("returns 404 for unknown question", async () => {
      const req = new Request("http://localhost/nonexistent", {
        method: "GET",
        headers: { "Authorization": "Bearer valid-session-token" },
      });
      const res = await assessmentQuestionsRouter.request(req);
      expect(res.status).toBe(404);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(false);
      expect((body.error as Record<string, unknown>).code).toBe("not_found");
    });
  });

  describe("PATCH /:id (submit answer)", () => {
    it("records answer and returns envelope", async () => {
      const req = new Request("http://localhost/q-001", {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer valid-session-token",
        },
        body: JSON.stringify({ answerId: "opt-a" }),
      });
      const res = await assessmentQuestionsRouter.request(req);
      expect(res.status).toBe(200);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(true);
    });

    it("returns 400 when answerId missing", async () => {
      const req = new Request("http://localhost/q-001", {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer valid-session-token",
        },
        body: JSON.stringify({}),
      });
      const res = await assessmentQuestionsRouter.request(req);
      expect(res.status).toBe(400);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(false);
      expect((body.error as Record<string, unknown>).code).toBe("validation_failed");
    });
  });
});
