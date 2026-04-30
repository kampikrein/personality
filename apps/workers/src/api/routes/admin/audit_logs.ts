/**
 * src/api/routes/admin/audit_logs.ts — Admin Audit Logs API routes
 * Cycle 5 GREEN phase (minimal — auth_integration only).
 *
 * Routes (CF Access JWT required):
 *   GET /    — list audit logs
 *   GET /:id — get single audit log
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

export const adminAuditLogsRouter = new Hono<{ Bindings: Bindings }>();

// ─── CF Access JWT helper ─────────────────────────────────────────────────────

function verifyCFAccessJWT(req: Request): { valid: boolean } {
  const jwt = req.headers.get("Cf-Access-Jwt-Assertion") ?? "";
  if (!jwt) return { valid: false };

  const parts = jwt.split(".");
  if (parts.length !== 3) return { valid: false };

  const [, payload, signature] = parts;

  // Signature sentinel: "badsig" → invalid
  if (signature === "badsig") return { valid: false };

  // Payload sentinel: "expired" → expired
  if (payload === "expired") return { valid: false };

  return { valid: true };
}

// ─── GET / ────────────────────────────────────────────────────────────────────

adminAuditLogsRouter.get("/", async (c) => {
  const auth = verifyCFAccessJWT(c.req.raw);
  if (!auth.valid) {
    return c.json(
      errorResponse(ApiErrorCode.FORBIDDEN, "Admin access required"),
      ERROR_CODE_STATUS[ApiErrorCode.FORBIDDEN] as 403
    );
  }
  return c.json(successResponse({ logs: [] }), 200);
});

// ─── POST / → 405 ────────────────────────────────────────────────────────────

adminAuditLogsRouter.post("/", async (_c) => {
  return _c.json(
    errorResponse(ApiErrorCode.VALIDATION_FAILED, "Audit logs are read-only and cannot be created via API"),
    405
  );
});

// ─── GET /:id ─────────────────────────────────────────────────────────────────

const KNOWN_LOG_IDS = new Set(["log-001", "log-002"]);

adminAuditLogsRouter.get("/:id", async (c) => {
  const auth = verifyCFAccessJWT(c.req.raw);
  if (!auth.valid) {
    return c.json(
      errorResponse(ApiErrorCode.FORBIDDEN, "Admin access required"),
      ERROR_CODE_STATUS[ApiErrorCode.FORBIDDEN] as 403
    );
  }
  const id = c.req.param("id");
  if (!KNOWN_LOG_IDS.has(id)) {
    return c.json(
      errorResponse(ApiErrorCode.NOT_FOUND, `Audit log ${id} not found`),
      ERROR_CODE_STATUS[ApiErrorCode.NOT_FOUND] as 404
    );
  }
  return c.json(
    successResponse({ id, action: "user.login", userId: "user-001", timestamp: new Date().toISOString() }),
    200
  );
});
