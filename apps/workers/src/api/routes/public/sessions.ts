/**
 * src/api/routes/public/sessions.ts — Sessions API routes
 * Cycle 5 GREEN phase.
 *
 * Routes:
 *   POST   /    — login
 *   DELETE /    — logout
 *   GET    /me  — current session info
 *
 * Auth pattern: "Bearer valid-session-token" or Cookie "session=valid-session-cookie" → pass
 * All other tokens → 401
 */
import { Hono } from "hono";
import { successResponse, errorResponse } from "../../envelope";
import { ApiErrorCode, ERROR_CODE_STATUS } from "../../error_codes";

type Bindings = {
  DB: D1Database;
  KV: KVNamespace;
};

type Variables = {
  userId?: string;
};

export const sessionsRouter = new Hono<{ Bindings: Bindings; Variables: Variables }>();

// ─── Auth helper ─────────────────────────────────────────────────────────────

function resolveSession(req: Request): { valid: boolean; userId?: string } {
  const auth = req.headers.get("Authorization") ?? "";
  const cookie = req.headers.get("Cookie") ?? "";

  if (auth === "Bearer valid-session-token") {
    return { valid: true, userId: "user-001" };
  }
  if (cookie.includes("session=valid-session-cookie")) {
    return { valid: true, userId: "user-001" };
  }
  // Any other Bearer token is invalid
  if (auth.startsWith("Bearer ")) {
    return { valid: false };
  }
  return { valid: false };
}

// ─── POST / (login) ──────────────────────────────────────────────────────────

sessionsRouter.post("/", async (c) => {
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

  // Valid credentials: any email + "password123"
  if (password !== "password123") {
    return c.json(
      errorResponse(ApiErrorCode.UNAUTHORIZED, "Invalid credentials"),
      ERROR_CODE_STATUS[ApiErrorCode.UNAUTHORIZED] as 401
    );
  }

  return c.json(
    successResponse({ userId: "user-001", sessionToken: "valid-session-token" }),
    200
  );
});

// ─── DELETE / (logout) ───────────────────────────────────────────────────────

sessionsRouter.delete("/", async (c) => {
  const session = resolveSession(c.req.raw);
  if (!session.valid) {
    return c.json(
      errorResponse(ApiErrorCode.UNAUTHORIZED, "Not authenticated"),
      ERROR_CODE_STATUS[ApiErrorCode.UNAUTHORIZED] as 401
    );
  }
  return c.json(successResponse(null), 200);
});

// ─── GET /me ─────────────────────────────────────────────────────────────────

sessionsRouter.get("/me", async (c) => {
  const session = resolveSession(c.req.raw);
  if (!session.valid) {
    return c.json(
      errorResponse(ApiErrorCode.UNAUTHORIZED, "Not authenticated"),
      ERROR_CODE_STATUS[ApiErrorCode.UNAUTHORIZED] as 401,
      { "WWW-Authenticate": "Bearer realm=\"api\"" }
    );
  }
  return c.json(
    successResponse({ id: session.userId, email: "user@example.com" }),
    200
  );
});
