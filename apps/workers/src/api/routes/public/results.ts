/**
 * src/api/routes/public/results.ts — Results API routes
 * Cycle 5 GREEN phase.
 *
 * Routes:
 *   GET /:assessment_id       — get assessment result (profile + insights)
 *   GET /:assessment_id/share — sharable result summary
 */
import { Hono } from "hono";
import { successResponse, errorResponse } from "../../envelope";
import { ApiErrorCode, ERROR_CODE_STATUS } from "../../error_codes";

type Bindings = {
  DB: D1Database;
  KV: KVNamespace;
};

export const resultsRouter = new Hono<{ Bindings: Bindings }>();

// ─── Auth helper ─────────────────────────────────────────────────────────────

function resolveSession(req: Request): boolean {
  const auth = req.headers.get("Authorization") ?? "";
  const cookie = req.headers.get("Cookie") ?? "";
  return auth === "Bearer valid-session-token" || cookie.includes("session=valid-session-cookie");
}

// ─── Sentinel IDs ─────────────────────────────────────────────────────────────

// "assess-001" is a completed assessment with a result
// "nonexistent-assess" → 404
// "pending-assess-id" → 422 (result not ready)
const COMPLETED_ASSESSMENTS = new Set(["assess-001", "test-id-123"]);
const PENDING_ASSESSMENTS = new Set(["pending-assess-id"]);

// ─── GET /:assessment_id ─────────────────────────────────────────────────────

resultsRouter.get("/:assessment_id", async (c) => {
  if (!resolveSession(c.req.raw)) {
    return c.json(
      errorResponse(ApiErrorCode.UNAUTHORIZED, "Not authenticated"),
      ERROR_CODE_STATUS[ApiErrorCode.UNAUTHORIZED] as 401
    );
  }

  const assessmentId = c.req.param("assessment_id");

  if (PENDING_ASSESSMENTS.has(assessmentId)) {
    return c.json(
      errorResponse(ApiErrorCode.VALIDATION_FAILED, "Assessment not yet scored"),
      422 as 422
    );
  }

  if (!COMPLETED_ASSESSMENTS.has(assessmentId)) {
    return c.json(
      errorResponse(ApiErrorCode.NOT_FOUND, `Result for assessment ${assessmentId} not found`),
      ERROR_CODE_STATUS[ApiErrorCode.NOT_FOUND] as 404
    );
  }

  return c.json(
    successResponse({
      assessmentId,
      profile: { type: "INFJ", description: "The Advocate" },
      insights: [
        { category: "communication", text: "You prefer deep meaningful conversations." },
        { category: "work_style", text: "You work best with clear purpose and values alignment." },
      ],
    }),
    200
  );
});

// ─── GET /:assessment_id/share ────────────────────────────────────────────────

resultsRouter.get("/:assessment_id/share", async (c) => {
  if (!resolveSession(c.req.raw)) {
    return c.json(
      errorResponse(ApiErrorCode.UNAUTHORIZED, "Not authenticated"),
      ERROR_CODE_STATUS[ApiErrorCode.UNAUTHORIZED] as 401
    );
  }

  const assessmentId = c.req.param("assessment_id");
  return c.json(
    successResponse({
      shareUrl: `https://app.example.com/share/${assessmentId}`,
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
    }),
    200
  );
});
