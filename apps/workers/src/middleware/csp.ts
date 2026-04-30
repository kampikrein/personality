/**
 * src/middleware/csp.ts — Content-Security-Policy middleware
 * Cycle 4 GREEN phase.
 */

import type { Context, MiddlewareHandler } from "hono";

export interface CspOptions {
  nonce?: boolean;
  extraDirectives?: Record<string, string>;
}

/**
 * Generate a random nonce string (base64url, 16 bytes)
 */
function generateNonce(): string {
  const bytes = new Uint8Array(16);
  crypto.getRandomValues(bytes);
  return btoa(String.fromCharCode(...bytes));
}

/**
 * createCspMiddleware — CSP header middleware factory
 */
export function createCspMiddleware(options?: CspOptions): MiddlewareHandler {
  const useNonce = options?.nonce ?? false;
  const extraDirectives = options?.extraDirectives ?? {};

  return async (c: Context, next) => {
    const nonce = useNonce ? generateNonce() : null;

    if (nonce) {
      c.set("cspNonce", nonce);
    }

    await next();

    const scriptSrc = nonce ? `script-src 'self' 'nonce-${nonce}'` : `script-src 'self'`;

    const directives: string[] = [
      "default-src 'self'",
      scriptSrc,
      "style-src 'self' 'unsafe-inline'",
    ];

    for (const [key, value] of Object.entries(extraDirectives)) {
      directives.push(`${key} ${value}`);
    }

    c.header("Content-Security-Policy", directives.join("; "));
  };
}
