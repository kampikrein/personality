/**
 * test/middleware/csp.test.ts — CSP middleware RED phase
 * Cycle 4.
 *
 * Assertions:
 *   1. Response includes Content-Security-Policy header
 *   2. Policy contains default-src 'self'
 *   3. Policy contains script-src 'self'
 *   4. Policy contains style-src 'self'
 *   5. Nonce option: policy contains 'nonce-...' in script-src
 *   6. Extra directives appended correctly
 *
 * RED phase: stub throws 'not implemented'.
 */

import { describe, it, expect } from "vitest";
import { Hono } from "hono";
import { createCspMiddleware } from "../../src/middleware/csp";

describe("CSP middleware", () => {
  it("sets Content-Security-Policy header", async () => {
    const app = new Hono();
    app.use("*", createCspMiddleware());
    app.get("/test", (c) => c.text("ok"));

    const res = await app.request("/test");
    expect(res.headers.get("Content-Security-Policy")).toBeDefined();
    expect(res.headers.get("Content-Security-Policy")).not.toBe("");
  });

  it("policy contains default-src 'self'", async () => {
    const app = new Hono();
    app.use("*", createCspMiddleware());
    app.get("/test", (c) => c.text("ok"));

    const res = await app.request("/test");
    const csp = res.headers.get("Content-Security-Policy") ?? "";
    expect(csp).toContain("default-src 'self'");
  });

  it("policy contains script-src 'self'", async () => {
    const app = new Hono();
    app.use("*", createCspMiddleware());
    app.get("/test", (c) => c.text("ok"));

    const res = await app.request("/test");
    const csp = res.headers.get("Content-Security-Policy") ?? "";
    expect(csp).toContain("script-src");
    expect(csp).toContain("'self'");
  });

  it("policy contains style-src 'self'", async () => {
    const app = new Hono();
    app.use("*", createCspMiddleware());
    app.get("/test", (c) => c.text("ok"));

    const res = await app.request("/test");
    const csp = res.headers.get("Content-Security-Policy") ?? "";
    expect(csp).toContain("style-src");
  });

  it("nonce option: script-src includes 'nonce-...'", async () => {
    const app = new Hono();
    app.use("*", createCspMiddleware({ nonce: true }));
    app.get("/test", (c) => c.text("ok"));

    const res = await app.request("/test");
    const csp = res.headers.get("Content-Security-Policy") ?? "";
    expect(csp).toMatch(/'nonce-[A-Za-z0-9+/=]+'/);
  });

  it("extraDirectives appended to policy", async () => {
    const app = new Hono();
    app.use(
      "*",
      createCspMiddleware({
        extraDirectives: { "img-src": "'self' data:" },
      }),
    );
    app.get("/test", (c) => c.text("ok"));

    const res = await app.request("/test");
    const csp = res.headers.get("Content-Security-Policy") ?? "";
    expect(csp).toContain("img-src");
  });
});
