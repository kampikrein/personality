/**
 * src/api/routes/public/health.ts — Health check API route
 * Cycle 5 stub — RED phase.
 *
 * Routes:
 *   GET /api/health — 200 OK with envelope
 *
 * GREEN phase: wrap existing /health with envelope middleware.
 */
import { Hono } from "hono";

type Bindings = {
  DB: D1Database;
  KV: KVNamespace;
};

export const healthRouter = new Hono<{ Bindings: Bindings }>();

healthRouter.get("/", async (_c) => {
  throw new Error("not implemented");
});
