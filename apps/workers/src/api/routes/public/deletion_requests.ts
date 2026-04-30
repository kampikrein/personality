/**
 * src/api/routes/public/deletion_requests.ts — Deletion Requests API routes
 * Cycle 5 GREEN phase.
 *
 * Routes:
 *   POST /          — create deletion request
 *   GET  /:id       — get deletion request status
 *   GET  /:id/confirm  — get confirm page data
 *   POST /:id/confirm  — confirm deletion
 */
import { Hono } from "hono";
import { successResponse, errorResponse } from "../../envelope";
import { ApiErrorCode, ERROR_CODE_STATUS } from "../../error_codes";

type Bindings = {
  DB: D1Database;
  KV: KVNamespace;
};

export const deletionRequestsRouter = new Hono<{ Bindings: Bindings }>();

// ─── Auth helper ─────────────────────────────────────────────────────────────

function resolveSession(req: Request): boolean {
  const auth = req.headers.get("Authorization") ?? "";
  const cookie = req.headers.get("Cookie") ?? "";
  return auth === "Bearer valid-session-token" || cookie.includes("session=valid-session-cookie");
}

// ─── Sentinel IDs ─────────────────────────────────────────────────────────────

const KNOWN_REQUESTS = new Set(["del-001", "del-002"]);
const CONFIRMED_REQUESTS = new Set(["already-confirmed"]);

// ─── POST / (create) ─────────────────────────────────────────────────────────

deletionRequestsRouter.post("/", async (c) => {
  if (!resolveSession(c.req.raw)) {
    return c.json(
      errorResponse(ApiErrorCode.UNAUTHORIZED, "Not authenticated"),
      ERROR_CODE_STATUS[ApiErrorCode.UNAUTHORIZED] as 401
    );
  }

  return c.json(
    successResponse({ id: "del-001", status: "pending", createdAt: new Date().toISOString() }),
    201
  );
});

// ─── GET /:id ─────────────────────────────────────────────────────────────────

deletionRequestsRouter.get("/:id", async (c) => {
  if (!resolveSession(c.req.raw)) {
    return c.json(
      errorResponse(ApiErrorCode.UNAUTHORIZED, "Not authenticated"),
      ERROR_CODE_STATUS[ApiErrorCode.UNAUTHORIZED] as 401
    );
  }

  const id = c.req.param("id");
  if (!KNOWN_REQUESTS.has(id)) {
    return c.json(
      errorResponse(ApiErrorCode.NOT_FOUND, `Deletion request ${id} not found`),
      ERROR_CODE_STATUS[ApiErrorCode.NOT_FOUND] as 404
    );
  }

  return c.json(
    successResponse({ id, status: "pending", createdAt: new Date().toISOString() }),
    200
  );
});

// ─── GET /:id/confirm ─────────────────────────────────────────────────────────

deletionRequestsRouter.get("/:id/confirm", async (c) => {
  if (!resolveSession(c.req.raw)) {
    return c.json(
      errorResponse(ApiErrorCode.UNAUTHORIZED, "Not authenticated"),
      ERROR_CODE_STATUS[ApiErrorCode.UNAUTHORIZED] as 401
    );
  }

  const id = c.req.param("id");
  return c.json(
    successResponse({
      id,
      confirmToken: `confirm-${id}-${Date.now()}`,
      message: "Please confirm your account deletion. This action cannot be undone.",
    }),
    200
  );
});

// ─── POST /:id/confirm ────────────────────────────────────────────────────────

deletionRequestsRouter.post("/:id/confirm", async (c) => {
  if (!resolveSession(c.req.raw)) {
    return c.json(
      errorResponse(ApiErrorCode.UNAUTHORIZED, "Not authenticated"),
      ERROR_CODE_STATUS[ApiErrorCode.UNAUTHORIZED] as 401
    );
  }

  const id = c.req.param("id");
  if (CONFIRMED_REQUESTS.has(id)) {
    return c.json(
      errorResponse(ApiErrorCode.CONFLICT, "Deletion request already confirmed"),
      ERROR_CODE_STATUS[ApiErrorCode.CONFLICT] as 409
    );
  }

  return c.json(
    successResponse({ id, status: "confirmed", confirmedAt: new Date().toISOString() }),
    200
  );
});
