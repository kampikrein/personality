/**
 * src/api/routes/public/assessment_questions.ts — Assessment Questions API routes
 * Cycle 5 stub — RED phase.
 *
 * Routes:
 *   GET  /api/assessment_questions        — list active question_set's questions
 *   GET  /api/assessment_questions/:id    — get single question
 *   PATCH /api/assessment_questions/:id   — submit answer
 *
 * GREEN phase: integrate with QuestionSetService.
 */
import { Hono } from "hono";

type Bindings = {
  DB: D1Database;
  KV: KVNamespace;
};

export const assessmentQuestionsRouter = new Hono<{ Bindings: Bindings }>();

assessmentQuestionsRouter.get("/", async (_c) => {
  throw new Error("not implemented");
});

assessmentQuestionsRouter.get("/:id", async (_c) => {
  throw new Error("not implemented");
});

assessmentQuestionsRouter.patch("/:id", async (_c) => {
  throw new Error("not implemented");
});
