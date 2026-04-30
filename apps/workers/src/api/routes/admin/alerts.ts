/**
 * src/api/routes/admin/alerts.ts — Admin Alerts API routes
 * Cycle 5 stub — RED phase.
 *
 * Routes (CF Access JWT required):
 *   GET   /admin/alerts     — list alerts
 *   GET   /admin/alerts/:id — get single alert
 *   PATCH /admin/alerts/:id — acknowledge/update alert
 *
 * GREEN phase: integrate with cfAccessVerifier + AlertService.
 */
import { Hono } from "hono";

type Bindings = {
  DB: D1Database;
  KV: KVNamespace;
};

export const adminAlertsRouter = new Hono<{ Bindings: Bindings }>();

adminAlertsRouter.get("/", async (_c) => {
  throw new Error("not implemented");
});

adminAlertsRouter.get("/:id", async (_c) => {
  throw new Error("not implemented");
});

adminAlertsRouter.patch("/:id", async (_c) => {
  throw new Error("not implemented");
});
