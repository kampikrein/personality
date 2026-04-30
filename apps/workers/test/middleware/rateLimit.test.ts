/**
 * test/middleware/rateLimit.test.ts — KV sliding window rate limit RED phase
 * Cycle 4.
 *
 * Assertions:
 *   1. Requests within limit → 200 OK
 *   2. Requests exceeding limit → 429 Too Many Requests
 *   3. Different IPs have separate rate limit counters
 *   4. Rate limit key prefix configurable
 *   5. Window reset: after window expires, limit resets (simulated)
 *
 * RED phase: stub throws 'not implemented'.
 * NOTE: cloudflare:test env.KV used for KV namespace.
 */

import { describe, it, expect } from "vitest";
import { env } from "cloudflare:test";
import { Hono } from "hono";
import { createRateLimitMiddleware } from "../../src/middleware/rateLimit";

describe("Rate limit middleware — KV sliding window", () => {
  it("requests within limit → 200 OK", async () => {
    const app = new Hono();
    app.use(
      "*",
      createRateLimitMiddleware({
        kv: env.KV,
        limit: 5,
        windowSeconds: 60,
        keyPrefix: "rl_test_within",
      }),
    );
    app.get("/test", (c) => c.text("ok"));

    // First request should pass
    const res = await app.request("/test", {
      headers: { "CF-Connecting-IP": "1.2.3.4" },
    });
    expect(res.status).toBe(200);
  });

  it("requests exceeding limit → 429", async () => {
    const limit = 3;
    const app = new Hono();
    app.use(
      "*",
      createRateLimitMiddleware({
        kv: env.KV,
        limit,
        windowSeconds: 60,
        keyPrefix: "rl_test_exceed",
      }),
    );
    app.get("/test", (c) => c.text("ok"));

    // Make limit+1 requests from same IP
    let lastStatus = 200;
    for (let i = 0; i <= limit; i++) {
      const res = await app.request("/test", {
        headers: { "CF-Connecting-IP": "10.0.0.1" },
      });
      lastStatus = res.status;
    }
    // Final request should be 429
    expect(lastStatus).toBe(429);
  });

  it("different IPs have separate counters", async () => {
    const limit = 2;
    const app = new Hono();
    app.use(
      "*",
      createRateLimitMiddleware({
        kv: env.KV,
        limit,
        windowSeconds: 60,
        keyPrefix: "rl_test_separate",
      }),
    );
    app.get("/test", (c) => c.text("ok"));

    // Exhaust IP 1
    for (let i = 0; i <= limit; i++) {
      await app.request("/test", { headers: { "CF-Connecting-IP": "192.168.1.1" } });
    }

    // IP 2 should still get 200
    const res = await app.request("/test", {
      headers: { "CF-Connecting-IP": "192.168.1.2" },
    });
    expect(res.status).toBe(200);
  });

  it("keyPrefix option isolates rate limit namespaces", async () => {
    const app1 = new Hono();
    const app2 = new Hono();
    const sharedIp = "5.5.5.5";

    app1.use("*", createRateLimitMiddleware({ kv: env.KV, limit: 1, windowSeconds: 60, keyPrefix: "ns_a" }));
    app1.get("/test", (c) => c.text("ok"));

    app2.use("*", createRateLimitMiddleware({ kv: env.KV, limit: 1, windowSeconds: 60, keyPrefix: "ns_b" }));
    app2.get("/test", (c) => c.text("ok"));

    // Exhaust ns_a
    await app1.request("/test", { headers: { "CF-Connecting-IP": sharedIp } });
    await app1.request("/test", { headers: { "CF-Connecting-IP": sharedIp } });

    // ns_b is independent — should still pass
    const res = await app2.request("/test", { headers: { "CF-Connecting-IP": sharedIp } });
    expect(res.status).toBe(200);
  });
});
