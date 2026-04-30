/**
 * src/api/routes/public/assessments.ts — Assessments API routes
 * Cycle 5 stub — RED phase.
 *
 * Routes:
 *   POST   /api/assessments            — create new assessment
 *   GET    /api/assessments/:id        — get assessment status
 *   POST   /api/assessments/:id/complete — complete assessment (trigger saga)
 *   PATCH  /api/assessments/:id/submit  — submit (legacy alias)
 *
 * GREEN phase: implement with AssessmentService + envelope middleware.
 */
import { Hono } from "hono";

type Bindings = {
  DB: D1Database;
  KV: KVNamespace;
};

export const assessmentsRouter = new Hono<{ Bindings: Bindings }>();

assessmentsRouter.post("/", async (_c) => {
  throw new Error("not implemented");
});

assessmentsRouter.get("/:id", async (_c) => {
  throw new Error("not implemented");
});

assessmentsRouter.post("/:id/complete", async (_c) => {
  throw new Error("not implemented");
});

assessmentsRouter.patch("/:id/submit", async (_c) => {
  throw new Error("not implemented");
});
