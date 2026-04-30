/**
 * src/api/routes/public/sessions.ts — Sessions API routes
 * Cycle 5 stub — RED phase.
 *
 * Routes:
 *   POST   /api/sessions    — login (via BetterAuth)
 *   DELETE /api/sessions    — logout
 *   GET    /api/sessions/me — current session info
 *
 * GREEN phase: integrate with BetterAuth signIn/signOut/getSession.
 */
import { Hono } from "hono";

type Bindings = {
  DB: D1Database;
  KV: KVNamespace;
};

export const sessionsRouter = new Hono<{ Bindings: Bindings }>();

sessionsRouter.post("/", async (_c) => {
  throw new Error("not implemented");
});

sessionsRouter.delete("/", async (_c) => {
  throw new Error("not implemented");
});

sessionsRouter.get("/me", async (_c) => {
  throw new Error("not implemented");
});
