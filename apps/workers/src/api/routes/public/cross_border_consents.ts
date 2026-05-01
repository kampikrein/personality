/**
 * src/api/routes/public/cross_border_consents.ts — RED phase stub
 * Rails: N/A (신규 — cycle 8 책임)
 *
 * 국외 이전 동의 endpoint.
 *   POST   /   — 국외 이전 동의 기록
 *   DELETE /:id — 국외 이전 동의 철회
 *   GET    /:id — 동의 상태 조회
 *
 * GREEN phase: crossBorderConsent service + audit_logger 연동, SSR 고지 페이지
 */

import { Hono } from "hono";

type Bindings = {
  DB: D1Database;
};

export const crossBorderConsentsRouter = new Hono<{ Bindings: Bindings }>();

// ─── POST / (grant cross-border consent) ─────────────────────────────────────

crossBorderConsentsRouter.post("/", async (_c) => {
  throw new Error("not implemented");
});

// ─── GET /:id ─────────────────────────────────────────────────────────────────

crossBorderConsentsRouter.get("/:id", async (_c) => {
  throw new Error("not implemented");
});

// ─── DELETE /:id (revoke) ─────────────────────────────────────────────────────

crossBorderConsentsRouter.delete("/:id", async (_c) => {
  throw new Error("not implemented");
});
