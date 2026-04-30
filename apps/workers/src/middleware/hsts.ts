/**
 * src/middleware/hsts.ts — HTTP Strict Transport Security middleware
 * Cycle 4 GREEN phase.
 */

import type { Context, MiddlewareHandler } from "hono";

export interface HstsOptions {
  maxAge?: number;         // default: 31536000 (1 year)
  includeSubDomains?: boolean;
  preload?: boolean;
  productionOnly?: boolean;
}

/**
 * createHstsMiddleware — HSTS header middleware factory
 */
export function createHstsMiddleware(options?: HstsOptions): MiddlewareHandler {
  const maxAge = options?.maxAge ?? 31536000;
  const includeSubDomains = options?.includeSubDomains ?? true;
  const preload = options?.preload ?? false;
  const productionOnly = options?.productionOnly ?? false;

  return async (c: Context, next) => {
    await next();

    if (productionOnly) {
      // Check CF Workers ENV binding or NODE_ENV
      const env = (c.env as Record<string, unknown>)?.ENV ?? process.env.NODE_ENV;
      if (env !== "production") {
        return;
      }
    }

    let value = `max-age=${maxAge}`;
    if (includeSubDomains) {
      value += "; includeSubDomains";
    }
    if (preload) {
      value += "; preload";
    }

    c.header("Strict-Transport-Security", value);
  };
}
