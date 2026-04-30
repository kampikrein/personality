/**
 * src/api/routes/admin/question_sets.ts — Admin Question Sets API routes
 * Cycle 5 stub — RED phase.
 *
 * Routes (CF Access JWT required):
 *   GET    /admin/question_sets     — list question sets
 *   POST   /admin/question_sets     — create question set
 *   GET    /admin/question_sets/:id — get question set
 *   PATCH  /admin/question_sets/:id — update question set
 *   DELETE /admin/question_sets/:id — delete question set
 *   GET    /admin/question_sets/:id/edit — edit form (admin UI)
 *   GET    /admin/question_sets/new     — new form (admin UI)
 *
 * GREEN phase: integrate with cfAccessVerifier + QuestionSetService.
 */
import { Hono } from "hono";

type Bindings = {
  DB: D1Database;
  KV: KVNamespace;
};

export const adminQuestionSetsRouter = new Hono<{ Bindings: Bindings }>();

adminQuestionSetsRouter.get("/", async (_c) => {
  throw new Error("not implemented");
});

adminQuestionSetsRouter.post("/", async (_c) => {
  throw new Error("not implemented");
});

adminQuestionSetsRouter.get("/new", async (_c) => {
  throw new Error("not implemented");
});

adminQuestionSetsRouter.get("/:id", async (_c) => {
  throw new Error("not implemented");
});

adminQuestionSetsRouter.get("/:id/edit", async (_c) => {
  throw new Error("not implemented");
});

adminQuestionSetsRouter.patch("/:id", async (_c) => {
  throw new Error("not implemented");
});

adminQuestionSetsRouter.delete("/:id", async (_c) => {
  throw new Error("not implemented");
});
