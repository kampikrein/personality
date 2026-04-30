/**
 * src/api/routes/public/deletion_requests.ts — Deletion Requests API routes
 * Cycle 5 stub — RED phase.
 *
 * Routes:
 *   POST /api/deletion_requests        — create deletion request
 *   GET  /api/deletion_requests/:id    — get deletion request status
 *   GET  /api/deletion_requests/:id/confirm — confirm deletion
 *   POST /api/deletion_requests/:id/confirm — confirm deletion (form submission)
 *
 * GREEN phase: integrate with DeletionService.
 */
import { Hono } from "hono";

type Bindings = {
  DB: D1Database;
  KV: KVNamespace;
};

export const deletionRequestsRouter = new Hono<{ Bindings: Bindings }>();

deletionRequestsRouter.post("/", async (_c) => {
  throw new Error("not implemented");
});

deletionRequestsRouter.get("/:id", async (_c) => {
  throw new Error("not implemented");
});

deletionRequestsRouter.get("/:id/confirm", async (_c) => {
  throw new Error("not implemented");
});

deletionRequestsRouter.post("/:id/confirm", async (_c) => {
  throw new Error("not implemented");
});
