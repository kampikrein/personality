/**
 * test/api/envelope.test.ts — API response envelope middleware RED phase
 * Cycle 5.
 *
 * Assertions:
 *   1. successResponse wraps data in { success: true, data }
 *   2. errorResponse wraps error in { success: false, error: { code, message } }
 *   3. errorResponse includes optional details when provided
 *   4. createEnvelopeMiddleware returns a Hono middleware function
 *   5. Middleware applied to app — success route → JSON has success: true
 *   6. Middleware applied to app — error route (4xx) → JSON has success: false
 *   7. successResponse is typed: SuccessResponse<T> satisfies shape
 *   8. errorResponse is typed: ErrorResponse satisfies shape
 *   9. Envelope does not double-wrap already-wrapped responses
 *  10. createEnvelopeMiddleware works with app.use("*", ...)
 *
 * RED phase: stubs throw 'not implemented' → all fail.
 * GREEN phase: implement envelope.ts functions + middleware.
 */

import { describe, it, expect } from "vitest";
import { Hono } from "hono";
import {
  successResponse,
  errorResponse,
  createEnvelopeMiddleware,
  type SuccessResponse,
  type ErrorResponse,
} from "../../src/api/envelope";

describe("API Envelope — RED phase", () => {
  describe("successResponse()", () => {
    it("wraps data in { success: true, data }", () => {
      const result = successResponse({ id: "abc", name: "test" });
      expect(result.success).toBe(true);
      expect((result as SuccessResponse<{ id: string; name: string }>).data).toEqual({
        id: "abc",
        name: "test",
      });
    });

    it("works with primitive data", () => {
      const result = successResponse(42);
      expect(result.success).toBe(true);
      expect((result as SuccessResponse<number>).data).toBe(42);
    });

    it("works with null data", () => {
      const result = successResponse(null);
      expect(result.success).toBe(true);
      expect((result as SuccessResponse<null>).data).toBeNull();
    });

    it("satisfies SuccessResponse<T> shape", () => {
      const result = successResponse({ x: 1 });
      // TypeScript structural check — shape has success + data
      expect("success" in result).toBe(true);
      expect("data" in result).toBe(true);
      expect("error" in result).toBe(false);
    });
  });

  describe("errorResponse()", () => {
    it("wraps error in { success: false, error: { code, message } }", () => {
      const result = errorResponse("not_found", "Resource not found");
      expect(result.success).toBe(false);
      expect(result.error.code).toBe("not_found");
      expect(result.error.message).toBe("Resource not found");
    });

    it("includes details when provided", () => {
      const details = { field: "email", reason: "invalid format" };
      const result = errorResponse("validation_failed", "Validation failed", details);
      expect(result.error.details).toEqual(details);
    });

    it("omits details when not provided", () => {
      const result = errorResponse("unauthorized", "Not logged in");
      expect(result.error.details).toBeUndefined();
    });

    it("satisfies ErrorResponse shape", () => {
      const result = errorResponse("forbidden", "Forbidden");
      expect("success" in result).toBe(true);
      expect("error" in result).toBe(true);
      expect("data" in result).toBe(false);
      expect(result.success).toBe(false);
    });
  });

  describe("createEnvelopeMiddleware()", () => {
    it("returns a middleware function (not null/undefined)", () => {
      const mw = createEnvelopeMiddleware();
      expect(typeof mw).toBe("function");
    });

    it("can be registered with app.use('*', ...)", async () => {
      const app = new Hono();
      expect(() => {
        app.use("*", createEnvelopeMiddleware());
      }).not.toThrow();
    });

    it("success route returns envelope { success: true, data }", async () => {
      const app = new Hono();
      app.use("*", createEnvelopeMiddleware());
      app.get("/test", (c) => c.json({ message: "hello" }, 200));

      const res = await app.request("/test");
      expect(res.status).toBe(200);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(true);
      expect(body.data).toBeDefined();
      expect((body.data as Record<string, unknown>).message).toBe("hello");
    });

    it("error route (404) returns envelope { success: false, error }", async () => {
      const app = new Hono();
      app.use("*", createEnvelopeMiddleware());
      app.get("/test", (c) => c.json({ code: "not_found", message: "Not found" }, 404));

      const res = await app.request("/test");
      expect(res.status).toBe(404);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(false);
      expect(body.error).toBeDefined();
    });

    it("does not double-wrap already-enveloped responses", async () => {
      const app = new Hono();
      app.use("*", createEnvelopeMiddleware());
      app.get("/test", (c) =>
        c.json(successResponse({ id: "1" }), 200)
      );

      const res = await app.request("/test");
      const body = await res.json() as Record<string, unknown>;
      // Should NOT be { success: true, data: { success: true, data: ... } }
      expect(body.success).toBe(true);
      expect((body.data as Record<string, unknown>)?.success).toBeUndefined();
    });
  });
});
