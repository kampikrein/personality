/**
 * src/middleware/csrf.ts — CSRF middleware (Origin + Sec-Fetch-Site dual check)
 * Cycle 4 GREEN phase.
 *
 * Synthesis BC1: Cookie isolation — api.<DOMAIN> ↔ admin.<DOMAIN> host-scoped.
 * OQ-5: mobile Bearer JWT bypass (no Cookie = no CSRF risk).
 */

import type { Context, MiddlewareHandler } from "hono";

export interface CsrfOptions {
  allowedOrigins: string[];
  skipMethods?: string[];   // default: ['GET', 'HEAD', 'OPTIONS']
  strictAdmin?: boolean;    // extra strict for admin.* routes
}

const SAFE_METHODS = new Set(["GET", "HEAD", "OPTIONS"]);

/**
 * createCsrfMiddleware — CSRF protection (Origin + Sec-Fetch-Site dual check)
 */
export function createCsrfMiddleware(options: CsrfOptions): MiddlewareHandler {
  const allowedOrigins = new Set(options.allowedOrigins);
  const skipMethods = options.skipMethods
    ? new Set(options.skipMethods)
    : SAFE_METHODS;

  return async (c: Context, next) => {
    const method = c.req.method;

    // Safe methods bypass
    if (skipMethods.has(method)) {
      return next();
    }

    // Mobile Bearer JWT bypass: Authorization: Bearer present AND no Cookie
    const auth = c.req.header("Authorization") ?? "";
    const cookie = c.req.header("Cookie") ?? "";
    if (auth.startsWith("Bearer ") && cookie === "") {
      return next();
    }

    // Origin check
    const origin = c.req.header("Origin") ?? "";
    if (!allowedOrigins.has(origin)) {
      return c.json({ error: "Forbidden" }, 403);
    }

    // Sec-Fetch-Site check: must be 'same-origin' or 'none'
    const secFetchSite = c.req.header("Sec-Fetch-Site") ?? "";
    if (secFetchSite !== "" && secFetchSite !== "same-origin" && secFetchSite !== "none") {
      return c.json({ error: "Forbidden" }, 403);
    }

    return next();
  };
}
