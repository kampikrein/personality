/**
 * src/middleware/rateLimit.ts — KV-based sliding window rate limit stub
 * Cycle 4 RED phase.
 *
 * Green phase impl:
 *   - KV sliding window: key = `ratelimit:<ip>` or `ratelimit:user:<userId>`
 *   - Stores request timestamps array (JSON) with TTL
 *   - Exceeds limit → 429 Too Many Requests
 *   - IP-based by default, user-based option
 *   - Hono app.use(rateLimitMiddleware)
 */

import type { MiddlewareHandler } from "hono";

export interface RateLimitOptions {
  kv: KVNamespace;
  limit: number;          // max requests per window
  windowSeconds: number;  // sliding window size in seconds
  keyPrefix?: string;     // default: 'ratelimit'
  keyBy?: "ip" | "user";
}

/**
 * createRateLimitMiddleware — KV sliding window rate limit factory
 * RED phase: throws 'not implemented'
 */
export function createRateLimitMiddleware(_options: RateLimitOptions): MiddlewareHandler {
  throw new Error("not implemented");
}
