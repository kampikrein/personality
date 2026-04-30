/**
 * test/middleware/csrf.test.ts — CSRF middleware (Origin + Sec-Fetch-Site dual check) RED phase
 * Cycle 4.
 *
 * Synthesis BC1: Cookie isolation — api.<DOMAIN> ↔ admin.<DOMAIN> host-scoped.
 * OQ-5: mobile Bearer JWT bypass (no Cookie = no CSRF risk).
 *
 * Assertions:
 *   1. Safe methods (GET/HEAD/OPTIONS) pass without CSRF check
 *   2. POST with valid Origin + Sec-Fetch-Site: same-origin → 200
 *   3. POST with valid Origin + Sec-Fetch-Site: none → 200 (cross-origin safe)
 *   4. POST with disallowed Origin → 403
 *   5. POST with Sec-Fetch-Site: cross-site → 403
 *   6. POST with no Origin header → 403 (strict)
 *   7. POST with Bearer token (no Cookie) → 200 bypass (mobile)
 *
 * RED phase: stub throws 'not implemented'.
 */

import { describe, it, expect } from "vitest";
import { Hono } from "hono";
import { createCsrfMiddleware } from "../../src/middleware/csrf";

const ALLOWED_ORIGINS = ["https://api.personality.app", "https://admin.personality.app"];

function buildApp(strictAdmin = false) {
  const app = new Hono();
  app.use(
    "*",
    createCsrfMiddleware({ allowedOrigins: ALLOWED_ORIGINS, strictAdmin }),
  );
  app.get("/test", (c) => c.text("ok"));
  app.post("/test", (c) => c.json({ success: true }));
  app.delete("/resource", (c) => c.json({ deleted: true }));
  return app;
}

describe("CSRF middleware — Origin + Sec-Fetch-Site dual check", () => {
  // ── Safe methods bypass ──────────────────────────────────────────────────

  it("GET request passes without CSRF check", async () => {
    const app = buildApp();
    const res = await app.request("/test", { method: "GET" });
    expect(res.status).toBe(200);
  });

  it("HEAD request passes without CSRF check", async () => {
    const app = buildApp();
    const res = await app.request("/test", { method: "HEAD" });
    expect(res.status).not.toBe(403);
  });

  it("OPTIONS request passes without CSRF check", async () => {
    const app = buildApp();
    const res = await app.request("/test", { method: "OPTIONS" });
    expect(res.status).not.toBe(403);
  });

  // ── Valid POST requests ──────────────────────────────────────────────────

  it("POST with allowed Origin + Sec-Fetch-Site: same-origin → 200", async () => {
    const app = buildApp();
    const res = await app.request("/test", {
      method: "POST",
      headers: {
        Origin: "https://api.personality.app",
        "Sec-Fetch-Site": "same-origin",
        Cookie: "session=abc123",
      },
    });
    expect(res.status).toBe(200);
  });

  it("POST with allowed Origin + Sec-Fetch-Site: none → 200", async () => {
    const app = buildApp();
    const res = await app.request("/test", {
      method: "POST",
      headers: {
        Origin: "https://api.personality.app",
        "Sec-Fetch-Site": "none",
        Cookie: "session=abc123",
      },
    });
    expect(res.status).toBe(200);
  });

  // ── Rejected requests → 403 ──────────────────────────────────────────────

  it("POST with disallowed Origin → 403", async () => {
    const app = buildApp();
    const res = await app.request("/test", {
      method: "POST",
      headers: {
        Origin: "https://evil.example.com",
        "Sec-Fetch-Site": "same-origin",
        Cookie: "session=abc123",
      },
    });
    expect(res.status).toBe(403);
  });

  it("POST with Sec-Fetch-Site: cross-site → 403", async () => {
    const app = buildApp();
    const res = await app.request("/test", {
      method: "POST",
      headers: {
        Origin: "https://api.personality.app",
        "Sec-Fetch-Site": "cross-site",
        Cookie: "session=abc123",
      },
    });
    expect(res.status).toBe(403);
  });

  it("POST with no Origin header + Cookie → 403 (strict)", async () => {
    const app = buildApp();
    const res = await app.request("/test", {
      method: "POST",
      headers: {
        Cookie: "session=abc123",
        // No Origin header
      },
    });
    expect(res.status).toBe(403);
  });

  // ── Mobile Bearer JWT bypass ─────────────────────────────────────────────

  it("POST with Authorization: Bearer (no Cookie) → 200 bypass", async () => {
    // Mobile clients use Bearer JWT, no Cookie → no CSRF risk
    const app = buildApp();
    const res = await app.request("/test", {
      method: "POST",
      headers: {
        Authorization: "Bearer eyJhbGciOiJSUzI1NiJ9.fake.token",
        // No Cookie header
      },
    });
    expect(res.status).toBe(200);
  });

  // ── DELETE also protected ────────────────────────────────────────────────

  it("DELETE with disallowed Origin → 403", async () => {
    const app = buildApp();
    const res = await app.request("/resource", {
      method: "DELETE",
      headers: {
        Origin: "https://evil.example.com",
        Cookie: "session=xyz",
      },
    });
    expect(res.status).toBe(403);
  });
});
