/**
 * src/api/envelope.ts — API response envelope middleware + helpers
 * Cycle 5 stub — RED phase.
 *
 * Envelope format: { success: true, data: T } | { success: false, error: { code, message, details? } }
 * GREEN phase: implement Hono middleware that wraps c.json calls.
 */

export type SuccessResponse<T = unknown> = {
  success: true;
  data: T;
};

export type ErrorResponse = {
  success: false;
  error: {
    code: string;
    message: string;
    details?: unknown;
  };
};

export type ApiResponse<T = unknown> = SuccessResponse<T> | ErrorResponse;

/**
 * successResponse — wrap data in envelope
 */
export function successResponse<T>(data: T): SuccessResponse<T> {
  throw new Error("not implemented");
}

/**
 * errorResponse — wrap error in envelope
 */
export function errorResponse(
  code: string,
  message: string,
  details?: unknown
): ErrorResponse {
  throw new Error("not implemented");
}

/**
 * createEnvelopeMiddleware — Hono middleware factory
 * Intercepts c.json and auto-wraps successful responses.
 * On 4xx/5xx: wraps in error envelope.
 */
export function createEnvelopeMiddleware() {
  throw new Error("not implemented");
}
