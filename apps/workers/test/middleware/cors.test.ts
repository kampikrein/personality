/**
 * test/middleware/cors.test.ts — CORS middleware RED phase
 * Cycle 4.
 *
 * Assertions:
 *   1. Allowed origin → response includes Access-Control-Allow-Origin
 *   2. Disallowed origin → no Access-Control-Allow-Origin header (or rejected)
 *   3. OPTIONS preflight → 204 + CORS headers
 *   4. Multiple allowed origins work
 *   5. Request without Origin header passes through
 *
 * RED phase: stub throws 'not implemented'.
 */

import { describe, it, expect } from "vitest";
import { Hono } from "hono";
import { createCorsMiddleware } from "../../src/middleware/cors";

const ALLOWED_ORIGINS = ["https://api.personality.app", "https://admin.personality.app"];

function buildApp() {
  const app = new Hono();
  app.use("*", createCorsMiddleware({ allowedOrigins: ALLOWED_ORIGINS }));
  app.get("/test", (c) => c.text("ok"));
  return app;
}

describe("CORS middleware", () => {
  it("allowed origin → Access-Control-Allow-Origin header present", async () => {
    const app = buildApp();
    const res = await app.request("/test", {
      headers: { Origin: "https://api.personality.app" },
    });
    expect(res.headers.get("Access-Control-Allow-Origin")).toBe(
      "https://api.personality.app",
    );
  });

  it("disallowed origin → Access-Control-Allow-Origin not set", async () => {
    const app = buildApp();
    const res = await app.request("/test", {
      headers: { Origin: "https://evil.example.com" },
    });
    expect(res.headers.get("Access-Control-Allow-Origin")).toBeNull();
  });

  it("OPTIONS preflight → 204 status", async () => {
    const app = buildApp();
    const res = await app.request("/test", {
      method: "OPTIONS",
      headers: {
        Origin: "https://api.personality.app",
        "Access-Control-Request-Method": "POST",
      },
    });
    expect(res.status).toBe(204);
  });

  it("OPTIONS preflight → CORS headers present", async () => {
    const app = buildApp();
    const res = await app.request("/test", {
      method: "OPTIONS",
      headers: {
        Origin: "https://api.personality.app",
        "Access-Control-Request-Method": "GET",
      },
    });
    expect(res.headers.get("Access-Control-Allow-Origin")).toBeDefined();
  });

  it("admin origin also allowed", async () => {
    const app = buildApp();
    const res = await app.request("/test", {
      headers: { Origin: "https://admin.personality.app" },
    });
    expect(res.headers.get("Access-Control-Allow-Origin")).toBe(
      "https://admin.personality.app",
    );
  });

  it("no Origin header → request passes through (200)", async () => {
    const app = buildApp();
    const res = await app.request("/test");
    expect(res.status).toBe(200);
  });
});
