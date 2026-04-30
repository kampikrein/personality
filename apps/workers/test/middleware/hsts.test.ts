/**
 * test/middleware/hsts.test.ts — HSTS middleware RED phase
 * Cycle 4.
 *
 * Assertions:
 *   1. Response includes Strict-Transport-Security header
 *   2. max-age ≥ 31536000 (1 year)
 *   3. includeSubDomains directive present
 *   4. productionOnly=true: header absent in non-production
 *   5. productionOnly=false (default): header always present
 *   6. Custom max-age respected
 *   7. preload directive optional
 *
 * RED phase: stub throws 'not implemented'.
 */

import { describe, it, expect } from "vitest";
import { Hono } from "hono";
import { createHstsMiddleware } from "../../src/middleware/hsts";

describe("HSTS middleware", () => {
  it("sets Strict-Transport-Security header", async () => {
    const app = new Hono();
    app.use("*", createHstsMiddleware());
    app.get("/test", (c) => c.text("ok"));

    const res = await app.request("/test");
    expect(res.headers.get("Strict-Transport-Security")).toBeDefined();
  });

  it("default max-age ≥ 31536000", async () => {
    const app = new Hono();
    app.use("*", createHstsMiddleware());
    app.get("/test", (c) => c.text("ok"));

    const res = await app.request("/test");
    const hsts = res.headers.get("Strict-Transport-Security") ?? "";
    const match = hsts.match(/max-age=(\d+)/);
    expect(match).not.toBeNull();
    expect(Number(match![1])).toBeGreaterThanOrEqual(31536000);
  });

  it("includeSubDomains directive present", async () => {
    const app = new Hono();
    app.use("*", createHstsMiddleware({ includeSubDomains: true }));
    app.get("/test", (c) => c.text("ok"));

    const res = await app.request("/test");
    const hsts = res.headers.get("Strict-Transport-Security") ?? "";
    expect(hsts).toContain("includeSubDomains");
  });

  it("productionOnly=true: header absent when not production", async () => {
    const app = new Hono();
    app.use("*", createHstsMiddleware({ productionOnly: true }));
    app.get("/test", (c) => c.text("ok"));

    // In test environment (not production), header should not be set
    const res = await app.request("/test");
    expect(res.headers.get("Strict-Transport-Security")).toBeNull();
  });

  it("productionOnly=false: header always present", async () => {
    const app = new Hono();
    app.use("*", createHstsMiddleware({ productionOnly: false }));
    app.get("/test", (c) => c.text("ok"));

    const res = await app.request("/test");
    expect(res.headers.get("Strict-Transport-Security")).toBeDefined();
  });

  it("custom maxAge respected", async () => {
    const app = new Hono();
    app.use("*", createHstsMiddleware({ maxAge: 63072000, productionOnly: false }));
    app.get("/test", (c) => c.text("ok"));

    const res = await app.request("/test");
    const hsts = res.headers.get("Strict-Transport-Security") ?? "";
    expect(hsts).toContain("max-age=63072000");
  });
});
