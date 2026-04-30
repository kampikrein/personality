/**
 * src/api/routes/admin/audit_logs.ts — Admin Audit Logs API routes
 * Cycle 5 stub — RED phase.
 *
 * Routes (CF Access JWT required):
 *   GET /admin/audit_logs     — list audit logs
 *   GET /admin/audit_logs/:id — get single audit log
 *
 * GREEN phase: integrate with cfAccessVerifier + AuditLogService.
 */
import { Hono } from "hono";

type Bindings = {
  DB: D1Database;
  KV: KVNamespace;
};

export const adminAuditLogsRouter = new Hono<{ Bindings: Bindings }>();

adminAuditLogsRouter.get("/", async (_c) => {
  throw new Error("not implemented");
});

adminAuditLogsRouter.get("/:id", async (_c) => {
  throw new Error("not implemented");
});
