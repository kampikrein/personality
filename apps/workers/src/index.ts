import { Hono } from "hono";
import { scheduled } from "./scheduled/d1-backup";

type Bindings = {
  DB: D1Database;
  KV: KVNamespace;
  R2_BACKUP: R2Bucket;
  R2_SECRETS: R2Bucket;
  R2_UPLOADS: R2Bucket;
  ENV: "production" | "staging" | "preview" | "development";
};

const app = new Hono<{ Bindings: Bindings }>();

app.get("/health", (c) => {
  const host = c.req.header("host") ?? "";
  const plane =
    host.startsWith("admin.") ? "admin" :
    host.startsWith("api.") ? "api" :
    "dev";
  return c.json({
    ok: true,
    plane,
    env: c.env.ENV,
    timestamp: new Date().toISOString(),
  });
});

// Cycle 1은 /health만 — 실제 routes는 후속 cycles에서 추가
app.notFound((c) => c.json({ error: "not found" }, 404));

export { scheduled };
export default app;
