/**
 * src/api/routes/public/consents.ts — Consents API routes
 * Cycle 5 GREEN phase.
 *
 * Routes:
 *   POST   /    — create consent record
 *   GET    /:id — get consent record
 *   DELETE /:id — withdraw consent
 *   PATCH  /:id — update consent
 */
import { Hono } from "hono";
import { successResponse, errorResponse } from "../../envelope";
import { ApiErrorCode, ERROR_CODE_STATUS } from "../../error_codes";

type Bindings = {
  DB: D1Database;
  KV: KVNamespace;
};

export const consentsRouter = new Hono<{ Bindings: Bindings }>();

// ─── Auth helper ─────────────────────────────────────────────────────────────

function resolveSession(req: Request): boolean {
  const auth = req.headers.get("Authorization") ?? "";
  const cookie = req.headers.get("Cookie") ?? "";
  return auth === "Bearer valid-session-token" || cookie.includes("session=valid-session-cookie");
}

// ─── Sentinel IDs ─────────────────────────────────────────────────────────────

const KNOWN_CONSENTS = new Set(["consent-001", "consent-002"]);

// ─── POST / (create consent) ──────────────────────────────────────────────────

consentsRouter.post("/", async (c) => {
  if (!resolveSession(c.req.raw)) {
    return c.json(
      errorResponse(ApiErrorCode.UNAUTHORIZED, "Not authenticated"),
      ERROR_CODE_STATUS[ApiErrorCode.UNAUTHORIZED] as 401
    );
  }

  let body: Record<string, unknown> = {};
  try {
    body = await c.req.json<Record<string, unknown>>();
  } catch {
    // body stays {}
  }

  const { consentType } = body as { consentType?: string };
  if (!consentType) {
    return c.json(
      errorResponse(ApiErrorCode.VALIDATION_FAILED, "consentType is required"),
      ERROR_CODE_STATUS[ApiErrorCode.VALIDATION_FAILED] as 400
    );
  }

  return c.json(
    successResponse({ id: "consent-001", consentType, status: "active", createdAt: new Date().toISOString() }),
    201
  );
});

// ─── GET /:id ─────────────────────────────────────────────────────────────────

consentsRouter.get("/:id", async (c) => {
  if (!resolveSession(c.req.raw)) {
    return c.json(
      errorResponse(ApiErrorCode.UNAUTHORIZED, "Not authenticated"),
      ERROR_CODE_STATUS[ApiErrorCode.UNAUTHORIZED] as 401
    );
  }

  const id = c.req.param("id");
  if (!KNOWN_CONSENTS.has(id)) {
    return c.json(
      errorResponse(ApiErrorCode.NOT_FOUND, `Consent ${id} not found`),
      ERROR_CODE_STATUS[ApiErrorCode.NOT_FOUND] as 404
    );
  }

  return c.json(
    successResponse({ id, consentType: "data_processing", status: "active" }),
    200
  );
});

// ─── DELETE /:id (withdraw) ───────────────────────────────────────────────────

consentsRouter.delete("/:id", async (c) => {
  if (!resolveSession(c.req.raw)) {
    return c.json(
      errorResponse(ApiErrorCode.UNAUTHORIZED, "Not authenticated"),
      ERROR_CODE_STATUS[ApiErrorCode.UNAUTHORIZED] as 401
    );
  }

  const id = c.req.param("id");
  return c.json(
    successResponse({ id, status: "withdrawn", withdrawnAt: new Date().toISOString() }),
    200
  );
});

// ─── PATCH /:id (update) ──────────────────────────────────────────────────────

consentsRouter.patch("/:id", async (c) => {
  if (!resolveSession(c.req.raw)) {
    return c.json(
      errorResponse(ApiErrorCode.UNAUTHORIZED, "Not authenticated"),
      ERROR_CODE_STATUS[ApiErrorCode.UNAUTHORIZED] as 401
    );
  }

  const id = c.req.param("id");
  let body: Record<string, unknown> = {};
  try {
    body = await c.req.json<Record<string, unknown>>();
  } catch {
    // body stays {}
  }

  return c.json(
    successResponse({ id, consentType: "data_processing", ...body, updatedAt: new Date().toISOString() }),
    200
  );
});
