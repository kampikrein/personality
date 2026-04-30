/**
 * src/middleware/cors.ts — CORS middleware
 * Cycle 4 GREEN phase.
 */

import type { Context, MiddlewareHandler } from "hono";

export interface CorsOptions {
  allowedOrigins: string[];
  allowedMethods?: string[];
  allowedHeaders?: string[];
}

/**
 * createCorsMiddleware — CORS middleware factory
 */
export function createCorsMiddleware(options: CorsOptions): MiddlewareHandler {
  const allowedOrigins = options.allowedOrigins;
  const allowedMethods = options.allowedMethods ?? ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"];
  const allowedHeaders = options.allowedHeaders ?? ["Content-Type", "Authorization"];

  return async (c: Context, next) => {
    const origin = c.req.header("Origin");
    const isAllowed = origin != null && allowedOrigins.includes(origin);

    // Handle OPTIONS preflight
    if (c.req.method === "OPTIONS") {
      if (isAllowed) {
        c.header("Access-Control-Allow-Origin", origin!);
        c.header("Access-Control-Allow-Methods", allowedMethods.join(", "));
        c.header("Access-Control-Allow-Headers", allowedHeaders.join(", "));
        c.header("Access-Control-Max-Age", "86400");
      }
      return c.body(null, 204);
    }

    await next();

    if (isAllowed) {
      c.header("Access-Control-Allow-Origin", origin!);
    }
  };
}
