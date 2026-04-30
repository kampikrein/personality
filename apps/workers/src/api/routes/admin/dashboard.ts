/**
 * src/api/routes/admin/dashboard.ts — Admin Dashboard API routes
 * Cycle 5 stub — RED phase.
 *
 * Routes (CF Access JWT required):
 *   GET /admin/dashboard                    — dashboard index + stats
 *   GET /admin/dashboard/completion_rates   — completion rate stats
 *   GET /admin/dashboard/drop_off_analysis  — drop-off analysis
 *
 * GREEN phase: integrate with cfAccessVerifier + DashboardService.
 */
import { Hono } from "hono";

type Bindings = {
  DB: D1Database;
  KV: KVNamespace;
};

export const adminDashboardRouter = new Hono<{ Bindings: Bindings }>();

adminDashboardRouter.get("/", async (_c) => {
  throw new Error("not implemented");
});

adminDashboardRouter.get("/completion_rates", async (_c) => {
  throw new Error("not implemented");
});

adminDashboardRouter.get("/drop_off_analysis", async (_c) => {
  throw new Error("not implemented");
});
