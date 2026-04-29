import type { Config } from "drizzle-kit";

/**
 * drizzle.config.ts — drizzle-kit 설정
 *
 * SOT: Drizzle schema (src/db/schema.ts) = 단일 진실의 원천
 * Migration runner: wrangler d1 migrations apply --local
 *
 * dialect: sqlite — D1은 SQLite 호환 (D1 HTTP driver)
 * driver: d1-http 또는 로컬 introspection 시 better-sqlite3 사용
 *
 * NOTE: production migration은 wrangler d1 migrations apply --env production
 *       로컬 개발은 npm run db:migrate:local (wrangler d1 --local)
 */
export default {
  schema: "./src/db/schema.ts",
  out: "./migrations",
  dialect: "sqlite",
  // D1 HTTP driver — wrangler d1 migrations apply가 실제 runner
  // drizzle-kit generate로 SQL 파일 생성, wrangler가 D1에 적용
  driver: "d1-http",
} satisfies Config;
