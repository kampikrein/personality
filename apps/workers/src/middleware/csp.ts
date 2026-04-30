/**
 * src/middleware/csp.ts — Content-Security-Policy middleware stub
 * Cycle 4 RED phase.
 *
 * Green phase impl:
 *   - default-src 'self'
 *   - script-src 'self' (+ optional nonce)
 *   - style-src 'self'
 *   - img-src 'self' data:
 *   - Nonce-based CSP option for inline scripts
 *   - Hono app.use(cspMiddleware)
 */

import type { MiddlewareHandler } from "hono";

export interface CspOptions {
  nonce?: boolean;
  extraDirectives?: Record<string, string>;
}

/**
 * createCspMiddleware — CSP header middleware factory
 * RED phase: throws 'not implemented'
 */
export function createCspMiddleware(_options?: CspOptions): MiddlewareHandler {
  throw new Error("not implemented");
}
