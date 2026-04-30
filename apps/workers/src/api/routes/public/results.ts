/**
 * src/api/routes/public/results.ts — Results API routes
 * Cycle 5 stub — RED phase.
 *
 * Routes:
 *   GET /api/results/:assessment_id — get assessment result (profile + insights)
 *   GET /api/results/:assessment_id/share — sharable result summary
 *
 * GREEN phase: integrate with ResultsService + InsightService.
 */
import { Hono } from "hono";

type Bindings = {
  DB: D1Database;
  KV: KVNamespace;
};

export const resultsRouter = new Hono<{ Bindings: Bindings }>();

resultsRouter.get("/:assessment_id", async (_c) => {
  throw new Error("not implemented");
});

resultsRouter.get("/:assessment_id/share", async (_c) => {
  throw new Error("not implemented");
});
