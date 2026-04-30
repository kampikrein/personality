/**
 * test/api/routes/admin/question_sets.test.ts — Admin Question Sets API routes RED phase
 * Cycle 5.
 *
 * Rails origin: Admin::QuestionSetsController (resources :question_sets — full CRUD)
 *   GET    /admin/question_sets     — index
 *   POST   /admin/question_sets     — create
 *   GET    /admin/question_sets/:id — show
 *   PATCH  /admin/question_sets/:id — update
 *   DELETE /admin/question_sets/:id — destroy
 *
 * Assertions:
 *   1. adminQuestionSetsRouter is exported
 *   2. All routes return 403 without CF Access JWT
 *   3. GET / → 200 + question set list
 *   4. POST / → 201 + created question set
 *   5. GET /:id → 200 + single question set
 *   6. GET /:id not found → 404
 *   7. PATCH /:id → 200 + updated question set
 *   8. DELETE /:id → 200 + deletion confirmed
 *   9. POST / with invalid data → 400 validation_failed
 *
 * RED phase: stubs throw 'not implemented' → all fail.
 * GREEN phase: implement question_sets.ts with cfAccessVerifier.
 */

import { describe, it, expect } from "vitest";
import { adminQuestionSetsRouter } from "../../../../src/api/routes/admin/question_sets";

const VALID_ADMIN_JWT = "eyJhbGciOiJSUzI1NiJ9.admin.fakesig";

describe("Admin Question Sets API Routes — RED phase", () => {
  it("adminQuestionSetsRouter is defined and exported", () => {
    expect(adminQuestionSetsRouter).toBeDefined();
  });

  describe("Authorization — all routes require CF Access JWT", () => {
    it("GET / returns 403 without JWT", async () => {
      const req = new Request("http://localhost/", { method: "GET" });
      const res = await adminQuestionSetsRouter.request(req);
      expect(res.status).toBe(403);
    });

    it("POST / returns 403 without JWT", async () => {
      const req = new Request("http://localhost/", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name: "Q Set 1" }),
      });
      const res = await adminQuestionSetsRouter.request(req);
      expect(res.status).toBe(403);
    });
  });

  describe("GET / (index)", () => {
    it("returns question set list in envelope", async () => {
      const req = new Request("http://localhost/", {
        method: "GET",
        headers: { "Cf-Access-Jwt-Assertion": VALID_ADMIN_JWT },
      });
      const res = await adminQuestionSetsRouter.request(req);
      expect(res.status).toBe(200);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(true);
      expect(Array.isArray((body.data as Record<string, unknown>).questionSets)).toBe(true);
    });
  });

  describe("POST / (create)", () => {
    it("creates question set and returns 201", async () => {
      const req = new Request("http://localhost/", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Cf-Access-Jwt-Assertion": VALID_ADMIN_JWT,
        },
        body: JSON.stringify({ name: "New Q Set", version: "1.0" }),
      });
      const res = await adminQuestionSetsRouter.request(req);
      expect(res.status).toBe(201);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(true);
      expect((body.data as Record<string, unknown>).id).toBeDefined();
    });

    it("returns 400 with validation_failed for missing name", async () => {
      const req = new Request("http://localhost/", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Cf-Access-Jwt-Assertion": VALID_ADMIN_JWT,
        },
        body: JSON.stringify({}),
      });
      const res = await adminQuestionSetsRouter.request(req);
      expect(res.status).toBe(400);
      const body = await res.json() as Record<string, unknown>;
      expect((body.error as Record<string, unknown>).code).toBe("validation_failed");
    });
  });

  describe("GET /:id", () => {
    it("returns single question set", async () => {
      const req = new Request("http://localhost/qs-001", {
        method: "GET",
        headers: { "Cf-Access-Jwt-Assertion": VALID_ADMIN_JWT },
      });
      const res = await adminQuestionSetsRouter.request(req);
      expect(res.status).toBe(200);
    });

    it("returns 404 for unknown question set", async () => {
      const req = new Request("http://localhost/nonexistent", {
        method: "GET",
        headers: { "Cf-Access-Jwt-Assertion": VALID_ADMIN_JWT },
      });
      const res = await adminQuestionSetsRouter.request(req);
      expect(res.status).toBe(404);
    });
  });

  describe("PATCH /:id", () => {
    it("updates question set and returns envelope", async () => {
      const req = new Request("http://localhost/qs-001", {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "Cf-Access-Jwt-Assertion": VALID_ADMIN_JWT,
        },
        body: JSON.stringify({ name: "Updated Q Set" }),
      });
      const res = await adminQuestionSetsRouter.request(req);
      expect(res.status).toBe(200);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(true);
    });
  });

  describe("DELETE /:id", () => {
    it("deletes question set and returns envelope", async () => {
      const req = new Request("http://localhost/qs-001", {
        method: "DELETE",
        headers: { "Cf-Access-Jwt-Assertion": VALID_ADMIN_JWT },
      });
      const res = await adminQuestionSetsRouter.request(req);
      expect(res.status).toBe(200);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(true);
    });
  });
});
