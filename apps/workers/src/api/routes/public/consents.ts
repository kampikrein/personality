/**
 * src/api/routes/public/consents.ts — Consents API routes
 * Cycle 5 stub — RED phase.
 *
 * Routes:
 *   GET    /api/consents/:id — get consent record
 *   POST   /api/consents     — create consent record
 *   DELETE /api/consents/:id — withdraw consent
 *   PATCH  /api/consents/:id — update consent
 *
 * GREEN phase: integrate with ConsentService.
 */
import { Hono } from "hono";

type Bindings = {
  DB: D1Database;
  KV: KVNamespace;
};

export const consentsRouter = new Hono<{ Bindings: Bindings }>();

consentsRouter.get("/:id", async (_c) => {
  throw new Error("not implemented");
});

consentsRouter.post("/", async (_c) => {
  throw new Error("not implemented");
});

consentsRouter.delete("/:id", async (_c) => {
  throw new Error("not implemented");
});

consentsRouter.patch("/:id", async (_c) => {
  throw new Error("not implemented");
});
