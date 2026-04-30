/**
 * src/api/routes/public/health.ts — Health check API route
 * Cycle 5 GREEN phase.
 *
 * Routes:
 *   GET / → 200 + envelope { success: true, data: { ok: true, timestamp } }
 */
import { Hono } from "hono";
import { successResponse } from "../../envelope";

type Bindings = {
  DB: D1Database;
  KV: KVNamespace;
};

export const healthRouter = new Hono<{ Bindings: Bindings }>();

healthRouter.get("/", async (c) => {
  return c.json(successResponse({ ok: true, timestamp: new Date().toISOString() }), 200);
});
