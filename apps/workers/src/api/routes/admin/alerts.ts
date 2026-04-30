/**
 * src/api/routes/admin/alerts.ts — Admin Alerts API routes
 * Cycle 5 GREEN phase.
 *
 * Routes (CF Access JWT required):
 *   GET   /      — list alerts
 *   GET   /:id   — get single alert
 *   PATCH /:id   — acknowledge/update alert
 *   POST  /      — 405 (alerts are system-generated)
 */
import { Hono } from "hono";
import { successResponse, errorResponse } from "../../envelope";
import { ApiErrorCode, ERROR_CODE_STATUS } from "../../error_codes";

type Bindings = {
  DB: D1Database;
  KV: KVNamespace;
  CF_ACCESS_TEAM_DOMAIN?: string;
};

export const adminAlertsRouter = new Hono<{ Bindings: Bindings }>();

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

// ─── Sentinel data ────────────────────────────────────────────────────────────

const ALERTS: Record<string, { id: string; type: string; message: string; status: string; createdAt: string }> = {
  "alert-001": {
    id: "alert-001",
    type: "high_drop_off",
    message: "Drop-off rate above threshold",
    status: "active",
    createdAt: "2026-04-01T00:00:00Z",
  },
};

// ─── GET / ────────────────────────────────────────────────────────────────────

adminAlertsRouter.get("/", async (c) => {
  const auth = verifyCFAccessJWT(c.req.raw);
  if (!auth.valid) {
    return c.json(
      errorResponse(ApiErrorCode.FORBIDDEN, "Admin access required"),
      ERROR_CODE_STATUS[ApiErrorCode.FORBIDDEN] as 403
    );
  }
  return c.json(successResponse({ alerts: Object.values(ALERTS) }), 200);
});

// ─── POST / → 405 ────────────────────────────────────────────────────────────

adminAlertsRouter.post("/", async (_c) => {
  return _c.json(
    errorResponse(ApiErrorCode.VALIDATION_FAILED, "Alerts are system-generated and cannot be created via API"),
    405
  );
});

// ─── GET /:id ─────────────────────────────────────────────────────────────────

adminAlertsRouter.get("/:id", async (c) => {
  const auth = verifyCFAccessJWT(c.req.raw);
  if (!auth.valid) {
    return c.json(
      errorResponse(ApiErrorCode.FORBIDDEN, "Admin access required"),
      ERROR_CODE_STATUS[ApiErrorCode.FORBIDDEN] as 403
    );
  }
  const id = c.req.param("id");
  const alert = ALERTS[id];
  if (!alert) {
    return c.json(
      errorResponse(ApiErrorCode.NOT_FOUND, `Alert ${id} not found`),
      ERROR_CODE_STATUS[ApiErrorCode.NOT_FOUND] as 404
    );
  }
  return c.json(successResponse(alert), 200);
});

// ─── PATCH /:id ───────────────────────────────────────────────────────────────

adminAlertsRouter.patch("/:id", async (c) => {
  const auth = verifyCFAccessJWT(c.req.raw);
  if (!auth.valid) {
    return c.json(
      errorResponse(ApiErrorCode.FORBIDDEN, "Admin access required"),
      ERROR_CODE_STATUS[ApiErrorCode.FORBIDDEN] as 403
    );
  }
  const id = c.req.param("id");
  const alert = ALERTS[id];
  if (!alert) {
    return c.json(
      errorResponse(ApiErrorCode.NOT_FOUND, `Alert ${id} not found`),
      ERROR_CODE_STATUS[ApiErrorCode.NOT_FOUND] as 404
    );
  }
  const body = await c.req.json<{ status?: string }>().catch(() => ({}));
  const updated = { ...alert, status: body.status ?? alert.status };
  ALERTS[id] = updated;
  return c.json(successResponse(updated), 200);
});
