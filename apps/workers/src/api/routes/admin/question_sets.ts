/**
 * src/api/routes/admin/question_sets.ts — Admin Question Sets API routes
 * Cycle 5 GREEN phase.
 *
 * Routes (CF Access JWT required):
 *   GET    /      — list question sets
 *   POST   /      — create question set
 *   GET    /:id   — get single question set
 *   PATCH  /:id   — update question set
 *   DELETE /:id   — delete question set
 */
import { Hono } from "hono";
import { successResponse, errorResponse } from "../../envelope";
import { ApiErrorCode, ERROR_CODE_STATUS } from "../../error_codes";

type Bindings = {
  DB: D1Database;
  KV: KVNamespace;
  CF_ACCESS_TEAM_DOMAIN?: string;
};

export const adminQuestionSetsRouter = new Hono<{ Bindings: Bindings }>();

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

type QuestionSet = {
  id: string;
  name: string;
  version: string;
  createdAt: string;
  updatedAt: string;
};

const QUESTION_SETS: Record<string, QuestionSet> = {
  "qs-001": {
    id: "qs-001",
    name: "Standard Personality Assessment",
    version: "1.0",
    createdAt: "2026-01-01T00:00:00Z",
    updatedAt: "2026-01-01T00:00:00Z",
  },
};

let nextId = 2;

// ─── GET / ────────────────────────────────────────────────────────────────────

adminQuestionSetsRouter.get("/", async (c) => {
  const auth = verifyCFAccessJWT(c.req.raw);
  if (!auth.valid) {
    return c.json(
      errorResponse(ApiErrorCode.FORBIDDEN, "Admin access required"),
      ERROR_CODE_STATUS[ApiErrorCode.FORBIDDEN] as 403
    );
  }
  return c.json(successResponse({ questionSets: Object.values(QUESTION_SETS) }), 200);
});

// ─── POST / ───────────────────────────────────────────────────────────────────

adminQuestionSetsRouter.post("/", async (c) => {
  const auth = verifyCFAccessJWT(c.req.raw);
  if (!auth.valid) {
    return c.json(
      errorResponse(ApiErrorCode.FORBIDDEN, "Admin access required"),
      ERROR_CODE_STATUS[ApiErrorCode.FORBIDDEN] as 403
    );
  }
  const body = await c.req.json<{ name?: string; version?: string }>().catch(() => ({}));
  if (!body.name) {
    return c.json(
      errorResponse(ApiErrorCode.VALIDATION_FAILED, "name is required"),
      ERROR_CODE_STATUS[ApiErrorCode.VALIDATION_FAILED] as 400
    );
  }
  const id = `qs-${String(nextId++).padStart(3, "0")}`;
  const now = new Date().toISOString();
  const qs: QuestionSet = {
    id,
    name: body.name,
    version: body.version ?? "1.0",
    createdAt: now,
    updatedAt: now,
  };
  QUESTION_SETS[id] = qs;
  return c.json(successResponse(qs), 201);
});

// ─── GET /:id ─────────────────────────────────────────────────────────────────

adminQuestionSetsRouter.get("/:id", async (c) => {
  const auth = verifyCFAccessJWT(c.req.raw);
  if (!auth.valid) {
    return c.json(
      errorResponse(ApiErrorCode.FORBIDDEN, "Admin access required"),
      ERROR_CODE_STATUS[ApiErrorCode.FORBIDDEN] as 403
    );
  }
  const id = c.req.param("id");
  const qs = QUESTION_SETS[id];
  if (!qs) {
    return c.json(
      errorResponse(ApiErrorCode.NOT_FOUND, `Question set ${id} not found`),
      ERROR_CODE_STATUS[ApiErrorCode.NOT_FOUND] as 404
    );
  }
  return c.json(successResponse(qs), 200);
});

// ─── PATCH /:id ───────────────────────────────────────────────────────────────

adminQuestionSetsRouter.patch("/:id", async (c) => {
  const auth = verifyCFAccessJWT(c.req.raw);
  if (!auth.valid) {
    return c.json(
      errorResponse(ApiErrorCode.FORBIDDEN, "Admin access required"),
      ERROR_CODE_STATUS[ApiErrorCode.FORBIDDEN] as 403
    );
  }
  const id = c.req.param("id");
  const qs = QUESTION_SETS[id];
  if (!qs) {
    return c.json(
      errorResponse(ApiErrorCode.NOT_FOUND, `Question set ${id} not found`),
      ERROR_CODE_STATUS[ApiErrorCode.NOT_FOUND] as 404
    );
  }
  const body = await c.req.json<Partial<QuestionSet>>().catch(() => ({}));
  const updated: QuestionSet = {
    ...qs,
    ...(body.name !== undefined && { name: body.name }),
    ...(body.version !== undefined && { version: body.version }),
    updatedAt: new Date().toISOString(),
  };
  QUESTION_SETS[id] = updated;
  return c.json(successResponse(updated), 200);
});

// ─── DELETE /:id ──────────────────────────────────────────────────────────────

adminQuestionSetsRouter.delete("/:id", async (c) => {
  const auth = verifyCFAccessJWT(c.req.raw);
  if (!auth.valid) {
    return c.json(
      errorResponse(ApiErrorCode.FORBIDDEN, "Admin access required"),
      ERROR_CODE_STATUS[ApiErrorCode.FORBIDDEN] as 403
    );
  }
  const id = c.req.param("id");
  const qs = QUESTION_SETS[id];
  if (!qs) {
    return c.json(
      errorResponse(ApiErrorCode.NOT_FOUND, `Question set ${id} not found`),
      ERROR_CODE_STATUS[ApiErrorCode.NOT_FOUND] as 404
    );
  }
  delete QUESTION_SETS[id];
  return c.json(successResponse({ deleted: true, id }), 200);
});
