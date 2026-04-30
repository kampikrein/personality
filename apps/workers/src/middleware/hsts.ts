/**
 * src/middleware/hsts.ts — HTTP Strict Transport Security middleware stub
 * Cycle 4 RED phase.
 *
 * Green phase impl:
 *   - Strict-Transport-Security: max-age=31536000; includeSubDomains
 *   - Apply only in production (NODE_ENV=production or CF env var)
 *   - Hono app.use(hstsMiddleware)
 */

import type { MiddlewareHandler } from "hono";

export interface HstsOptions {
  maxAge?: number;         // default: 31536000 (1 year)
  includeSubDomains?: boolean;
  preload?: boolean;
  productionOnly?: boolean;
}

/**
 * createHstsMiddleware — HSTS header middleware factory
 * RED phase: throws 'not implemented'
 */
export function createHstsMiddleware(_options?: HstsOptions): MiddlewareHandler {
  throw new Error("not implemented");
}
