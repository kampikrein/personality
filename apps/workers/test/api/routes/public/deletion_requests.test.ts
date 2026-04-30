/**
 * test/api/routes/public/deletion_requests.test.ts — Deletion Requests API routes RED phase
 * Cycle 5.
 *
 * Rails origin: DeletionRequestsController (resources :deletion_requests, only: [:new, :create, :show])
 *   POST /api/deletion_requests             — create
 *   GET  /api/deletion_requests/:id         — show
 *   GET  /api/deletion_requests/:id/confirm — confirm form
 *   POST /api/deletion_requests/:id/confirm — confirm submission
 *
 * Assertions:
 *   1. deletionRequestsRouter is exported
 *   2. POST / → 201 + envelope { success: true, data: { id, status: 'pending' } }
 *   3. POST / without auth → 401
 *   4. GET /:id → 200 + deletion request status
 *   5. GET /:id not found → 404
 *   6. GET /:id/confirm → 200 + confirm page data
 *   7. POST /:id/confirm → 200 + confirmed (triggers deletion pipeline)
 *   8. POST /:id/confirm for already-confirmed request → 409
 *
 * RED phase: stubs throw 'not implemented' → all fail.
 * GREEN phase: implement deletion_requests.ts.
 */

import { describe, it, expect } from "vitest";
import { deletionRequestsRouter } from "../../../../src/api/routes/public/deletion_requests";

describe("Deletion Requests API Routes — RED phase", () => {
  it("deletionRequestsRouter is defined and exported", () => {
    expect(deletionRequestsRouter).toBeDefined();
  });

  describe("POST / (create deletion request)", () => {
    it("creates deletion request and returns 201", async () => {
      const req = new Request("http://localhost/", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer valid-session-token",
        },
        body: JSON.stringify({ reason: "No longer needed" }),
      });
      const res = await deletionRequestsRouter.request(req);
      expect(res.status).toBe(201);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(true);
      expect((body.data as Record<string, unknown>).status).toBe("pending");
    });

    it("returns 401 without auth", async () => {
      const req = new Request("http://localhost/", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({}),
      });
      const res = await deletionRequestsRouter.request(req);
      expect(res.status).toBe(401);
    });
  });

  describe("GET /:id", () => {
    it("returns deletion request status in envelope", async () => {
      const req = new Request("http://localhost/del-001", {
        method: "GET",
        headers: { "Authorization": "Bearer valid-session-token" },
      });
      const res = await deletionRequestsRouter.request(req);
      expect(res.status).toBe(200);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(true);
      expect((body.data as Record<string, unknown>).id).toBe("del-001");
    });

    it("returns 404 for unknown deletion request", async () => {
      const req = new Request("http://localhost/nonexistent", {
        method: "GET",
        headers: { "Authorization": "Bearer valid-session-token" },
      });
      const res = await deletionRequestsRouter.request(req);
      expect(res.status).toBe(404);
    });
  });

  describe("GET /:id/confirm", () => {
    it("returns confirm page data", async () => {
      const req = new Request("http://localhost/del-001/confirm", {
        method: "GET",
        headers: { "Authorization": "Bearer valid-session-token" },
      });
      const res = await deletionRequestsRouter.request(req);
      expect(res.status).toBe(200);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(true);
    });
  });

  describe("POST /:id/confirm", () => {
    it("confirms deletion and triggers pipeline", async () => {
      const req = new Request("http://localhost/del-001/confirm", {
        method: "POST",
        headers: { "Authorization": "Bearer valid-session-token" },
      });
      const res = await deletionRequestsRouter.request(req);
      expect(res.status).toBe(200);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(true);
      expect((body.data as Record<string, unknown>).status).toBe("confirmed");
    });

    it("returns 409 for already-confirmed request", async () => {
      const req = new Request("http://localhost/already-confirmed/confirm", {
        method: "POST",
        headers: { "Authorization": "Bearer valid-session-token" },
      });
      const res = await deletionRequestsRouter.request(req);
      expect(res.status).toBe(409);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(false);
      expect((body.error as Record<string, unknown>).code).toBe("conflict");
    });
  });
});
