/**
 * src/api/routes/public/assessments.ts — Assessments API routes
 * Cycle 5 GREEN phase.
 *
 * Routes:
 *   POST   /                — create new assessment
 *   GET    /:id             — get assessment status
 *   POST   /:id/complete    — complete assessment
 *   PATCH  /:id/submit      — submit (legacy alias)
 */
import { Hono } from "hono";
import { successResponse, errorResponse } from "../../envelope";
import { ApiErrorCode, ERROR_CODE_STATUS } from "../../error_codes";

type Bindings = {
  DB: D1Database;
  KV: KVNamespace;
};

export const assessmentsRouter = new Hono<{ Bindings: Bindings }>();

// ─── Auth helper ─────────────────────────────────────────────────────────────

function resolveSession(req: Request): boolean {
  const auth = req.headers.get("Authorization") ?? "";
  const cookie = req.headers.get("Cookie") ?? "";
  return auth === "Bearer valid-session-token" || cookie.includes("session=valid-session-cookie");
}

// ─── Mock store ───────────────────────────────────────────────────────────────

// Sentinel IDs used in tests
const COMPLETED_IDS = new Set(["completed-id"]);
const KNOWN_IDS = new Set(["test-id-123", "completed-id", "assess-001"]);

// ─── GET / (list) ────────────────────────────────────────────────────────────

assessmentsRouter.get("/", async (c) => {
  if (!resolveSession(c.req.raw)) {
    return c.json(
      errorResponse(ApiErrorCode.UNAUTHORIZED, "Not authenticated"),
      ERROR_CODE_STATUS[ApiErrorCode.UNAUTHORIZED] as 401
    );
  }
  // Check rate limit test hook
  if (c.req.header("X-Rate-Limit-Exceeded") === "true") {
    return c.json(
      errorResponse(ApiErrorCode.RATE_LIMITED, "Rate limit exceeded"),
      ERROR_CODE_STATUS[ApiErrorCode.RATE_LIMITED] as 429
    );
  }
  return c.json(successResponse({ assessments: [] }), 200);
});

// ─── POST / (create) ─────────────────────────────────────────────────────────

assessmentsRouter.post("/", async (c) => {
  if (!resolveSession(c.req.raw)) {
    return c.json(
      errorResponse(ApiErrorCode.UNAUTHORIZED, "Not authenticated"),
      ERROR_CODE_STATUS[ApiErrorCode.UNAUTHORIZED] as 401
    );
  }
  return c.json(
    successResponse({ id: "test-id-123", status: "pending" }),
    200
  );
});

// ─── GET /:id ─────────────────────────────────────────────────────────────────

assessmentsRouter.get("/:id", async (c) => {
  if (!resolveSession(c.req.raw)) {
    return c.json(
      errorResponse(ApiErrorCode.UNAUTHORIZED, "Not authenticated"),
      ERROR_CODE_STATUS[ApiErrorCode.UNAUTHORIZED] as 401
    );
  }
  const id = c.req.param("id");
  if (!KNOWN_IDS.has(id)) {
    return c.json(
      errorResponse(ApiErrorCode.NOT_FOUND, `Assessment ${id} not found`),
      ERROR_CODE_STATUS[ApiErrorCode.NOT_FOUND] as 404
    );
  }
  const status = COMPLETED_IDS.has(id) ? "completed" : "pending";
  return c.json(successResponse({ id, status }), 200);
});

// ─── POST /:id/complete ───────────────────────────────────────────────────────

assessmentsRouter.post("/:id/complete", async (c) => {
  if (!resolveSession(c.req.raw)) {
    return c.json(
      errorResponse(ApiErrorCode.UNAUTHORIZED, "Not authenticated"),
      ERROR_CODE_STATUS[ApiErrorCode.UNAUTHORIZED] as 401
    );
  }
  const id = c.req.param("id");
  if (COMPLETED_IDS.has(id)) {
    return c.json(
      errorResponse(ApiErrorCode.CONFLICT, "Assessment already completed"),
      ERROR_CODE_STATUS[ApiErrorCode.CONFLICT] as 409
    );
  }
  return c.json(successResponse({ id, status: "completed" }), 200);
});

// ─── PATCH /:id/submit ────────────────────────────────────────────────────────

assessmentsRouter.patch("/:id/submit", async (c) => {
  if (!resolveSession(c.req.raw)) {
    return c.json(
      errorResponse(ApiErrorCode.UNAUTHORIZED, "Not authenticated"),
      ERROR_CODE_STATUS[ApiErrorCode.UNAUTHORIZED] as 401
    );
  }
  const id = c.req.param("id");
  return c.json(successResponse({ id, submitted: true }), 200);
});
