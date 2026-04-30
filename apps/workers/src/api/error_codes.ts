/**
 * src/api/error_codes.ts — API error code catalog
 * Cycle 5 stub — RED phase.
 *
 * Error codes are typed enum constants + helper for building error responses.
 * GREEN phase: implement enum + apiError() helper.
 */

/**
 * ApiErrorCode — exhaustive list of error codes
 */
export enum ApiErrorCode {
  VALIDATION_FAILED = "validation_failed",
  UNAUTHORIZED = "unauthorized",
  FORBIDDEN = "forbidden",
  NOT_FOUND = "not_found",
  CONFLICT = "conflict",
  RATE_LIMITED = "rate_limited",
  INTERNAL_ERROR = "internal_error",
}

/**
 * HTTP status mapping for each error code
 */
export const ERROR_CODE_STATUS: Record<ApiErrorCode, number> = {
  [ApiErrorCode.VALIDATION_FAILED]: 400,
  [ApiErrorCode.UNAUTHORIZED]: 401,
  [ApiErrorCode.FORBIDDEN]: 403,
  [ApiErrorCode.NOT_FOUND]: 404,
  [ApiErrorCode.CONFLICT]: 409,
  [ApiErrorCode.RATE_LIMITED]: 429,
  [ApiErrorCode.INTERNAL_ERROR]: 500,
};

/**
 * apiError — build a typed error response payload
 */
export function apiError(
  code: ApiErrorCode,
  message: string,
  details?: unknown
): { success: false; error: { code: ApiErrorCode; message: string; details?: unknown } } {
  throw new Error("not implemented");
}
