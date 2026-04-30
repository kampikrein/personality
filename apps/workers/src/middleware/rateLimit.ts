/**
 * src/middleware/rateLimit.ts — KV-based sliding window rate limit
 * Cycle 4 GREEN phase.
 */

import type { Context, MiddlewareHandler } from "hono";

export interface RateLimitOptions {
  kv: KVNamespace;
  limit: number;          // max requests per window
  windowSeconds: number;  // sliding window size in seconds
  keyPrefix?: string;     // default: 'ratelimit'
  keyBy?: "ip" | "user";
}

/**
 * createRateLimitMiddleware — KV sliding window rate limit factory
 */
export function createRateLimitMiddleware(options: RateLimitOptions): MiddlewareHandler {
  const { kv, limit, windowSeconds } = options;
  const keyPrefix = options.keyPrefix ?? "ratelimit";
  const keyBy = options.keyBy ?? "ip";

  return async (c: Context, next) => {
    const ip = c.req.header("CF-Connecting-IP") ?? "anon";
    const identifier = keyBy === "ip" ? ip : (c.get("userId") as string | undefined) ?? ip;
    const key = `${keyPrefix}:${identifier}`;

    const now = Date.now();
    const windowMs = windowSeconds * 1000;

    // Load existing timestamps
    const raw = await kv.get(key);
    let timestamps: number[] = raw ? (JSON.parse(raw) as number[]) : [];

    // Slide the window — remove entries older than windowMs
    timestamps = timestamps.filter((t) => now - t < windowMs);

    if (timestamps.length >= limit) {
      const oldestTs = timestamps[0] ?? now;
      const retryAfter = Math.ceil((oldestTs + windowMs - now) / 1000);
      c.header("Retry-After", String(Math.max(retryAfter, 1)));
      return c.json({ error: "Too Many Requests" }, 429);
    }

    // Record this request
    timestamps.push(now);
    await kv.put(key, JSON.stringify(timestamps), { expirationTtl: windowSeconds + 1 });

    await next();
  };
}
