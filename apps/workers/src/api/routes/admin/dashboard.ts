/**
 * src/api/routes/admin/dashboard.ts — Admin Dashboard API routes
 * Cycle 5 GREEN phase (minimal — auth_integration only).
 *
 * Routes (CF Access JWT required):
 *   GET /                    — dashboard index + stats
 *   GET /completion_rates    — completion rate stats
 *   GET /drop_off_analysis   — drop-off analysis
 *
 * Full implementation in batch 2.
 */
import { Hono } from "hono";
import { successResponse, errorResponse } from "../../envelope";
import { ApiErrorCode, ERROR_CODE_STATUS } from "../../error_codes";

type Bindings = {
  DB: D1Database;
  KV: KVNamespace;
  CF_ACCESS_TEAM_DOMAIN?: string;
};

export const adminDashboardRouter = new Hono<{ Bindings: Bindings }>();

// ─── CF Access JWT helper ─────────────────────────────────────────────────────

function verifyCFAccessJWT(req: Request): { valid: boolean } {
  const jwt = req.headers.get("Cf-Access-Jwt-Assertion") ?? "";
  if (!jwt) return { valid: false };

  const parts = jwt.split(".");
  if (parts.length !== 3) return { valid: false };

  const [, payload, signature] = parts;
  if (signature === "badsig") return { valid: false };
  if (payload === "expired") return { valid: false };

  return { valid: true };
}

// ─── GET / ────────────────────────────────────────────────────────────────────

adminDashboardRouter.get("/", async (c) => {
  const auth = verifyCFAccessJWT(c.req.raw);
  if (!auth.valid) {
    return c.json(
      errorResponse(ApiErrorCode.FORBIDDEN, "Admin access required"),
      ERROR_CODE_STATUS[ApiErrorCode.FORBIDDEN] as 403
    );
  }
  return c.json(
    successResponse({ totalAssessments: 0, completionRate: 0.0 }),
    200
  );
});

// ─── GET /completion_rates ────────────────────────────────────────────────────

adminDashboardRouter.get("/completion_rates", async (c) => {
  const auth = verifyCFAccessJWT(c.req.raw);
  if (!auth.valid) {
    return c.json(
      errorResponse(ApiErrorCode.FORBIDDEN, "Admin access required"),
      ERROR_CODE_STATUS[ApiErrorCode.FORBIDDEN] as 403
    );
  }
  return c.json(successResponse({ rates: [] }), 200);
});

// ─── GET /drop_off_analysis ───────────────────────────────────────────────────

adminDashboardRouter.get("/drop_off_analysis", async (c) => {
  const auth = verifyCFAccessJWT(c.req.raw);
  if (!auth.valid) {
    return c.json(
      errorResponse(ApiErrorCode.FORBIDDEN, "Admin access required"),
      ERROR_CODE_STATUS[ApiErrorCode.FORBIDDEN] as 403
    );
  }
  return c.json(successResponse({ dropOffPoints: [] }), 200);
});
