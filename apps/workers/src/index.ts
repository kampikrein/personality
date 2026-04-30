import { Hono } from "hono";
import { scheduled } from "./scheduled/d1-backup";
import {
  createHstsMiddleware,
  createCspMiddleware,
  createCorsMiddleware,
  createRateLimitMiddleware,
  createCsrfMiddleware,
} from "./middleware";

type Bindings = {
  DB: D1Database;
  KV: KVNamespace;
  R2_BACKUP: R2Bucket;
  R2_SECRETS: R2Bucket;
  R2_UPLOADS: R2Bucket;
  ENV: "production" | "staging" | "preview" | "development";
};

const ALLOWED_ORIGINS = [
  "https://api.personality.app",
  "https://admin.personality.app",
];

const app = new Hono<{ Bindings: Bindings }>();

// Security middleware (SD-11 순서: HSTS → CSP → CORS → rateLimit → CSRF)
app.use("*", createHstsMiddleware({ productionOnly: true }));
app.use("*", createCspMiddleware({ extraDirectives: { "img-src": "'self' data:" } }));
app.use("*", createCorsMiddleware({ allowedOrigins: ALLOWED_ORIGINS }));
app.use("*", async (c, next) => {
  if (c.env?.KV) {
    return createRateLimitMiddleware({
      kv: c.env.KV,
      limit: 100,
      windowSeconds: 60,
    })(c, next);
  }
  return next();
});
app.use("*", createCsrfMiddleware({ allowedOrigins: ALLOWED_ORIGINS }));

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
