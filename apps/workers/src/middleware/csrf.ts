/**
 * src/middleware/csrf.ts — Hono CSRF middleware stub (Origin + Sec-Fetch-Site double check)
 * Cycle 4 RED phase.
 *
 * Green phase impl (Synthesis BC1 + OQ-5):
 *   - Cookie isolation: api.<DOMAIN> vs admin.<DOMAIN> host-scoped (BC1)
 *   - Origin header: must match api.* or admin.* allowlist
 *   - Sec-Fetch-Site: must be 'same-origin' or 'none'
 *   - Fail → 403 Forbidden
 *   - Safe methods (GET/HEAD/OPTIONS) bypass
 *   - Mobile Bearer JWT bypass (no Cookie = no CSRF risk)
 *   - Admin routes: strict Origin check
 *   - Hono app.use(csrfMiddleware)
 */

import type { MiddlewareHandler } from "hono";

export interface CsrfOptions {
  allowedOrigins: string[];
  skipMethods?: string[];   // default: ['GET', 'HEAD', 'OPTIONS']
  strictAdmin?: boolean;    // extra strict for admin.* routes
}

/**
 * createCsrfMiddleware — CSRF protection (Origin + Sec-Fetch-Site dual check)
 * RED phase: throws 'not implemented'
 */
export function createCsrfMiddleware(_options: CsrfOptions): MiddlewareHandler {
  throw new Error("not implemented");
}
