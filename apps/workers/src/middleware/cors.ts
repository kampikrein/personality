/**
 * src/middleware/cors.ts — CORS middleware stub
 * Cycle 4 RED phase.
 *
 * Green phase impl:
 *   - allowedOrigins: api.<DOMAIN> + admin.<DOMAIN>
 *   - Reject unknown origins (no Access-Control-Allow-Origin)
 *   - Handle OPTIONS preflight with 204
 *   - Hono app.use(corsMiddleware)
 */

import type { MiddlewareHandler } from "hono";

export interface CorsOptions {
  allowedOrigins: string[];
  allowedMethods?: string[];
  allowedHeaders?: string[];
}

/**
 * createCorsMiddleware — CORS middleware factory
 * RED phase: throws 'not implemented'
 */
export function createCorsMiddleware(_options: CorsOptions): MiddlewareHandler {
  throw new Error("not implemented");
}
