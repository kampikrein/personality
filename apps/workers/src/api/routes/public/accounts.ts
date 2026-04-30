/**
 * src/api/routes/public/accounts.ts — Accounts API routes
 * Cycle 5 stub — RED phase.
 *
 * Routes:
 *   POST  /api/accounts    — signup
 *   GET   /api/accounts/me — get current account
 *   PATCH /api/accounts/me — update current account
 *
 * GREEN phase: integrate with BetterAuth signUp + AccountService.
 */
import { Hono } from "hono";

type Bindings = {
  DB: D1Database;
  KV: KVNamespace;
};

export const accountsRouter = new Hono<{ Bindings: Bindings }>();

accountsRouter.post("/", async (_c) => {
  throw new Error("not implemented");
});

accountsRouter.get("/me", async (_c) => {
  throw new Error("not implemented");
});

accountsRouter.patch("/me", async (_c) => {
  throw new Error("not implemented");
});
