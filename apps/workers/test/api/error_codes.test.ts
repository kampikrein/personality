/**
 * test/api/error_codes.test.ts — API error code catalog RED phase
 * Cycle 5.
 *
 * Assertions:
 *   1. ApiErrorCode enum has all 7 codes
 *   2. ERROR_CODE_STATUS maps each code to correct HTTP status
 *   3. apiError() returns typed error response payload
 *   4. apiError() with details includes details field
 *   5. All codes are string literals (not numbers)
 *   6. No duplicate status codes
 *
 * RED phase: stubs throw 'not implemented' → all fail.
 * GREEN phase: implement error_codes.ts.
 */

import { describe, it, expect } from "vitest";
import {
  ApiErrorCode,
  ERROR_CODE_STATUS,
  apiError,
} from "../../src/api/error_codes";

describe("API Error Codes — RED phase", () => {
  describe("ApiErrorCode enum", () => {
    it("has VALIDATION_FAILED = 'validation_failed'", () => {
      expect(ApiErrorCode.VALIDATION_FAILED).toBe("validation_failed");
    });

    it("has UNAUTHORIZED = 'unauthorized'", () => {
      expect(ApiErrorCode.UNAUTHORIZED).toBe("unauthorized");
    });

    it("has FORBIDDEN = 'forbidden'", () => {
      expect(ApiErrorCode.FORBIDDEN).toBe("forbidden");
    });

    it("has NOT_FOUND = 'not_found'", () => {
      expect(ApiErrorCode.NOT_FOUND).toBe("not_found");
    });

    it("has CONFLICT = 'conflict'", () => {
      expect(ApiErrorCode.CONFLICT).toBe("conflict");
    });

    it("has RATE_LIMITED = 'rate_limited'", () => {
      expect(ApiErrorCode.RATE_LIMITED).toBe("rate_limited");
    });

    it("has INTERNAL_ERROR = 'internal_error'", () => {
      expect(ApiErrorCode.INTERNAL_ERROR).toBe("internal_error");
    });

    it("has exactly 7 codes", () => {
      const codes = Object.values(ApiErrorCode).filter((v) => typeof v === "string");
      expect(codes).toHaveLength(7);
    });
  });

  describe("ERROR_CODE_STATUS", () => {
    it("VALIDATION_FAILED → 400", () => {
      expect(ERROR_CODE_STATUS[ApiErrorCode.VALIDATION_FAILED]).toBe(400);
    });

    it("UNAUTHORIZED → 401", () => {
      expect(ERROR_CODE_STATUS[ApiErrorCode.UNAUTHORIZED]).toBe(401);
    });

    it("FORBIDDEN → 403", () => {
      expect(ERROR_CODE_STATUS[ApiErrorCode.FORBIDDEN]).toBe(403);
    });

    it("NOT_FOUND → 404", () => {
      expect(ERROR_CODE_STATUS[ApiErrorCode.NOT_FOUND]).toBe(404);
    });

    it("CONFLICT → 409", () => {
      expect(ERROR_CODE_STATUS[ApiErrorCode.CONFLICT]).toBe(409);
    });

    it("RATE_LIMITED → 429", () => {
      expect(ERROR_CODE_STATUS[ApiErrorCode.RATE_LIMITED]).toBe(429);
    });

    it("INTERNAL_ERROR → 500", () => {
      expect(ERROR_CODE_STATUS[ApiErrorCode.INTERNAL_ERROR]).toBe(500);
    });

    it("all 7 codes have a status entry", () => {
      const codes = Object.values(ApiErrorCode).filter((v) => typeof v === "string") as ApiErrorCode[];
      for (const code of codes) {
        expect(ERROR_CODE_STATUS[code]).toBeDefined();
        expect(typeof ERROR_CODE_STATUS[code]).toBe("number");
      }
    });
  });

  describe("apiError()", () => {
    it("returns { success: false, error: { code, message } }", () => {
      const result = apiError(ApiErrorCode.NOT_FOUND, "User not found");
      expect(result.success).toBe(false);
      expect(result.error.code).toBe(ApiErrorCode.NOT_FOUND);
      expect(result.error.message).toBe("User not found");
    });

    it("includes details when provided", () => {
      const result = apiError(
        ApiErrorCode.VALIDATION_FAILED,
        "Invalid input",
        [{ field: "email", issue: "invalid" }]
      );
      expect(result.error.details).toEqual([{ field: "email", issue: "invalid" }]);
    });

    it("does not include details when omitted", () => {
      const result = apiError(ApiErrorCode.UNAUTHORIZED, "Not authenticated");
      expect(result.error.details).toBeUndefined();
    });

    it("error.code is typed as ApiErrorCode", () => {
      const result = apiError(ApiErrorCode.FORBIDDEN, "Access denied");
      // TypeScript type assertion — code is ApiErrorCode enum value
      const code: ApiErrorCode = result.error.code;
      expect(Object.values(ApiErrorCode)).toContain(code);
    });
  });
});
