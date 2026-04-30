/**
 * src/api/envelope.ts — API response envelope middleware + helpers
 * Cycle 5 GREEN phase.
 *
 * Envelope format: { success: true, data: T } | { success: false, error: { code, message, details? } }
 */

import type { MiddlewareHandler } from "hono";

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
  return { success: true, data };
}

/**
 * errorResponse — wrap error in envelope
 */
export function errorResponse(
  code: string,
  message: string,
  details?: unknown
): ErrorResponse {
  const err: ErrorResponse = {
    success: false,
    error: { code, message },
  };
  if (details !== undefined) {
    err.error.details = details;
  }
  return err;
}

/**
 * isEnveloped — detect if a response body is already wrapped.
 * Avoids double-wrapping when route explicitly calls successResponse/errorResponse.
 */
function isEnveloped(body: unknown): boolean {
  if (body === null || typeof body !== "object") return false;
  const obj = body as Record<string, unknown>;
  return (
    typeof obj.success === "boolean" &&
    ("data" in obj || "error" in obj)
  );
}

/**
 * createEnvelopeMiddleware — Hono middleware factory
 * Intercepts outgoing JSON responses and wraps them in the standard envelope.
 * Already-enveloped responses (success: true/false + data/error) are passed through unchanged.
 *
 * Method B: response transformer via afterResponse interception.
 */
export function createEnvelopeMiddleware(): MiddlewareHandler {
  return async (c, next) => {
    await next();

    const contentType = c.res.headers.get("content-type") ?? "";
    if (!contentType.includes("application/json")) return;

    const body = await c.res.clone().json();

    // Do not double-wrap already-enveloped responses
    if (isEnveloped(body)) return;

    const status = c.res.status;
    let wrapped: ApiResponse<unknown>;

    if (status >= 400) {
      // Extract code + message from body if available, fallback to generic
      const b = body as Record<string, unknown>;
      const code = (typeof b?.code === "string" ? b.code : "error") as string;
      const message = (typeof b?.message === "string" ? b.message : "An error occurred") as string;
      wrapped = errorResponse(code, message);
    } else {
      wrapped = successResponse(body);
    }

    c.res = new Response(JSON.stringify(wrapped), {
      status: c.res.status,
      headers: c.res.headers,
    });
  };
}
