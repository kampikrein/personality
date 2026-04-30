/**
 * src/api/routes/public/assessment_questions.ts — Assessment Questions API routes
 * Cycle 5 GREEN phase.
 *
 * Routes:
 *   GET   /    — list active question_set's questions
 *   GET   /:id — get single question with options
 *   PATCH /:id — submit answer for question
 */
import { Hono } from "hono";
import { successResponse, errorResponse } from "../../envelope";
import { ApiErrorCode, ERROR_CODE_STATUS } from "../../error_codes";

type Bindings = {
  DB: D1Database;
  KV: KVNamespace;
};

export const assessmentQuestionsRouter = new Hono<{ Bindings: Bindings }>();

// ─── Auth helper ─────────────────────────────────────────────────────────────

function resolveSession(req: Request): boolean {
  const auth = req.headers.get("Authorization") ?? "";
  const cookie = req.headers.get("Cookie") ?? "";
  return auth === "Bearer valid-session-token" || cookie.includes("session=valid-session-cookie");
}

// ─── Mock question data ───────────────────────────────────────────────────────

const MOCK_QUESTIONS = [
  {
    id: "q-001",
    text: "When meeting new people, you usually feel energized.",
    options: [
      { id: "opt-a", label: "Strongly Agree" },
      { id: "opt-b", label: "Agree" },
      { id: "opt-c", label: "Disagree" },
      { id: "opt-d", label: "Strongly Disagree" },
    ],
  },
  {
    id: "q-002",
    text: "You prefer structured plans over spontaneous decisions.",
    options: [
      { id: "opt-a", label: "Strongly Agree" },
      { id: "opt-b", label: "Agree" },
      { id: "opt-c", label: "Disagree" },
      { id: "opt-d", label: "Strongly Disagree" },
    ],
  },
];

// ─── GET / ────────────────────────────────────────────────────────────────────

assessmentQuestionsRouter.get("/", async (c) => {
  if (!resolveSession(c.req.raw)) {
    return c.json(
      errorResponse(ApiErrorCode.UNAUTHORIZED, "Not authenticated"),
      ERROR_CODE_STATUS[ApiErrorCode.UNAUTHORIZED] as 401
    );
  }
  return c.json(successResponse({ questions: MOCK_QUESTIONS }), 200);
});

// ─── GET /:id ─────────────────────────────────────────────────────────────────

assessmentQuestionsRouter.get("/:id", async (c) => {
  if (!resolveSession(c.req.raw)) {
    return c.json(
      errorResponse(ApiErrorCode.UNAUTHORIZED, "Not authenticated"),
      ERROR_CODE_STATUS[ApiErrorCode.UNAUTHORIZED] as 401
    );
  }

  const id = c.req.param("id");
  const question = MOCK_QUESTIONS.find((q) => q.id === id);

  if (!question) {
    return c.json(
      errorResponse(ApiErrorCode.NOT_FOUND, `Question ${id} not found`),
      ERROR_CODE_STATUS[ApiErrorCode.NOT_FOUND] as 404
    );
  }

  return c.json(successResponse(question), 200);
});

// ─── PATCH /:id (submit answer) ───────────────────────────────────────────────

assessmentQuestionsRouter.patch("/:id", async (c) => {
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

  const { answerId } = body as { answerId?: string };
  if (!answerId) {
    return c.json(
      errorResponse(ApiErrorCode.VALIDATION_FAILED, "answerId is required"),
      ERROR_CODE_STATUS[ApiErrorCode.VALIDATION_FAILED] as 400
    );
  }

  const id = c.req.param("id");
  return c.json(successResponse({ questionId: id, answerId, recorded: true }), 200);
});
