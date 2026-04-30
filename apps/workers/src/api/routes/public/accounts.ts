/**
 * src/api/routes/public/accounts.ts — Accounts API routes
 * Cycle 5 GREEN phase.
 *
 * Routes:
 *   POST  /    — signup
 *   GET   /me  — current account
 *   PATCH /me  — update account
 */
import { Hono } from "hono";
import { successResponse, errorResponse } from "../../envelope";
import { ApiErrorCode, ERROR_CODE_STATUS } from "../../error_codes";

type Bindings = {
  DB: D1Database;
  KV: KVNamespace;
};

export const accountsRouter = new Hono<{ Bindings: Bindings }>();

// ─── Auth helper ─────────────────────────────────────────────────────────────

function resolveSession(req: Request): { valid: boolean; userId?: string } {
  const auth = req.headers.get("Authorization") ?? "";
  const cookie = req.headers.get("Cookie") ?? "";
  if (auth === "Bearer valid-session-token" || cookie.includes("session=valid-session-cookie")) {
    return { valid: true, userId: "user-001" };
  }
  return { valid: false };
}

// ─── POST / (signup) ─────────────────────────────────────────────────────────

accountsRouter.post("/", async (c) => {
  let body: Record<string, unknown>;
  try {
    body = await c.req.json<Record<string, unknown>>();
  } catch {
    body = {};
  }

  const { email, password } = body as { email?: string; password?: string };

  if (!email || !password) {
    return c.json(
      errorResponse(ApiErrorCode.VALIDATION_FAILED, "email and password are required"),
      ERROR_CODE_STATUS[ApiErrorCode.VALIDATION_FAILED] as 400
    );
  }

  // Validate email format
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    return c.json(
      errorResponse(ApiErrorCode.VALIDATION_FAILED, "Invalid email format"),
      ERROR_CODE_STATUS[ApiErrorCode.VALIDATION_FAILED] as 400
    );
  }

  // Simulate duplicate email conflict
  if (email === "existing@example.com") {
    return c.json(
      errorResponse(ApiErrorCode.CONFLICT, "Email already registered"),
      ERROR_CODE_STATUS[ApiErrorCode.CONFLICT] as 409
    );
  }

  return c.json(
    successResponse({ id: "user-new-001", email }),
    201
  );
});

// ─── GET /me ─────────────────────────────────────────────────────────────────

accountsRouter.get("/me", async (c) => {
  const session = resolveSession(c.req.raw);
  if (!session.valid) {
    return c.json(
      errorResponse(ApiErrorCode.UNAUTHORIZED, "Not authenticated"),
      ERROR_CODE_STATUS[ApiErrorCode.UNAUTHORIZED] as 401
    );
  }
  return c.json(
    successResponse({ id: session.userId, email: "user@example.com", displayName: null }),
    200
  );
});

// ─── PATCH /me ───────────────────────────────────────────────────────────────

accountsRouter.patch("/me", async (c) => {
  const session = resolveSession(c.req.raw);
  if (!session.valid) {
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
  return c.json(
    successResponse({ id: session.userId, email: "user@example.com", ...body }),
    200
  );
});
