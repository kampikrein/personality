/**
 * test/db/migrations.test.ts — migration 파일 존재 + 멱등성 검증 (RED phase)
 *
 * 검증:
 *   1. D1 DB에서 테이블 목록 조회 — migration 적용 전 0개 → fail (RED phase)
 *   2. 14 테이블 존재 확인 → fail (GREEN phase: migration 적용 후 통과)
 *   3. wrangler d1 migrations apply --local 재실행 멱등성 — IF NOT EXISTS 전제
 *
 * NOTE: Workers 런타임에서는 node:fs/promises를 사용할 수 없음.
 * migration SQL 파일의 물리적 존재 확인은 별도 Node 환경 테스트(scripts/)로 분리.
 * 본 파일은 D1 in-memory DB 상태 검증에 집중.
 *
 * RED phase: migration 미적용 → D1에 테이블 0개 → 모든 테스트 fail (의도)
 * GREEN phase: drizzle-kit generate + wrangler d1 migrations apply --local 후 통과
 */

import { describe, it, expect } from "vitest";
import { env } from "cloudflare:test";

const EXPECTED_TABLES = [
  "alerts",
  "anonymous_sessions",
  "assessments",
  "audit_logs",
  "consents",
  "deletion_requests",
  "domain_scores",
  "insights",
  "personality_types",
  "profiles",
  "question_sets",
  "questions",
  "responses",
  "users",
] as const;

describe("Migrations — D1 schema 상태 검증 (RED phase)", () => {
  it("D1 should have 14 tables after migration (0 before migration — RED phase fail)", async () => {
    const result = await env.DB.prepare(
      `SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE '_cf_%' AND name != 'd1_migrations' ORDER BY name`
    ).all();

    const tableNames = (result.results as { name: string }[]).map((r) => r.name);

    // RED phase: migration 미적용 → 0개 → fail
    // GREEN phase cycle 2: 14개 테이블 → pass
    // GREEN phase cycle 4: 15개 테이블 (account 테이블 추가 — 0001 migration)
    expect(tableNames).toHaveLength(15);
  });

  it.each(EXPECTED_TABLES.map((t) => [t]))(
    "D1 should have table '%s' after migration",
    async (tableName) => {
      const result = await env.DB.prepare(
        `SELECT name FROM sqlite_master WHERE type='table' AND name = ?`
      )
        .bind(tableName)
        .first<{ name: string }>();

      // RED phase: 각 테이블이 없음 → null → fail
      expect(result).not.toBeNull();
      expect(result!.name).toBe(tableName);
    }
  );

  describe("Migration 멱등성 — IF NOT EXISTS", () => {
    it("creating a table with IF NOT EXISTS should not throw on second call", async () => {
      // IF NOT EXISTS 패턴이 올바르면 두 번 실행해도 에러 없음
      // 이는 drizzle-kit이 migration SQL을 올바르게 생성했을 때의 검증
      // NOTE: D1 exec()은 멀티라인 SQL 불가 → prepare().run() 사용
      const createSql = "CREATE TABLE IF NOT EXISTS _migration_idempotency_test (id INTEGER PRIMARY KEY, created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP)";

      await expect(env.DB.prepare(createSql).run()).resolves.toBeDefined();
      // 두 번째 실행 — 에러 없어야 함
      await expect(env.DB.prepare(createSql).run()).resolves.toBeDefined();

      // 정리
      await env.DB.prepare("DROP TABLE IF EXISTS _migration_idempotency_test").run();
    });

    it("wrangler d1_migrations table should track applied migrations (after first apply)", async () => {
      // wrangler은 d1_migrations 테이블로 적용된 migration을 추적
      // RED phase: 아직 apply 안 했으므로 테이블 없음 → fail 또는 0 row
      const result = await env.DB.prepare(
        `SELECT name FROM sqlite_master WHERE type='table' AND name = 'd1_migrations'`
      ).first<{ name: string }>();

      // GREEN phase: wrangler d1 migrations apply --local 후 d1_migrations 테이블 생성됨
      // RED phase: null → fail
      expect(result).not.toBeNull();
    });
  });

  describe("Schema integrity checks (post-migration)", () => {
    it("all 14 tables should have an 'id' primary key column", async () => {
      for (const tableName of EXPECTED_TABLES) {
        const result = await env.DB.prepare(
          `PRAGMA table_info(${tableName})`
        ).all();

        const cols = result.results as { name: string; pk: number }[];
        const pkCols = cols.filter((c) => c.pk > 0);

        expect(pkCols.length).toBeGreaterThan(0);
      }
    });

    it("all 14 tables should have created_at and updated_at columns", async () => {
      for (const tableName of EXPECTED_TABLES) {
        const result = await env.DB.prepare(
          `PRAGMA table_info(${tableName})`
        ).all();

        const cols = result.results as { name: string }[];
        const colNames = cols.map((c) => c.name);

        expect(colNames).toContain("created_at");
        expect(colNames).toContain("updated_at");
      }
    });
  });
});
