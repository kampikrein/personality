/**
 * test/db/schema.test.ts — 14 tables 존재 + PK + 컬럼 타입 검증 (RED phase)
 *
 * 검증 대상 (Rails server/db/schema.rb 원본 14 tables):
 *   1. alerts
 *   2. anonymous_sessions
 *   3. assessments
 *   4. audit_logs
 *   5. consents
 *   6. deletion_requests
 *   7. domain_scores
 *   8. insights
 *   9. personality_types
 *  10. profiles
 *  11. question_sets
 *  12. questions
 *  13. responses
 *  14. users
 *
 * RED phase: schema.ts stub + migration 없음 → 모든 테스트 fail 의도
 * GREEN phase: schema.ts 14 tables 정의 + drizzle-kit generate + wrangler d1 migrations apply --local 후 통과
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

describe("DB Schema — 14 tables existence (RED phase)", () => {
  it("should have exactly 14 domain tables in sqlite_master", async () => {
    const result = await env.DB.prepare(
      `SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE '_cf_%' AND name != 'd1_migrations' ORDER BY name`
    ).all();

    const tableNames = (result.results as { name: string }[]).map((r) => r.name);

    // RED phase: migration 미적용 → 0개 테이블 → fail
    // Cycle 4: 15개 테이블 (14 original + account from 0001 migration)
    expect(tableNames).toHaveLength(15);
  });

  it("should contain all 14 expected table names", async () => {
    const result = await env.DB.prepare(
      `SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE '_cf_%' ORDER BY name`
    ).all();

    const tableNames = (result.results as { name: string }[]).map((r) => r.name);

    for (const tableName of EXPECTED_TABLES) {
      expect(tableNames).toContain(tableName);
    }
  });

  // 각 테이블의 Primary Key 존재 확인
  it.each(EXPECTED_TABLES.map((t) => [t]))(
    "table '%s' should have a primary key column",
    async (tableName) => {
      const result = await env.DB.prepare(
        `PRAGMA table_info(${tableName})`
      ).all();

      const columns = result.results as {
        cid: number;
        name: string;
        type: string;
        notnull: number;
        dflt_value: unknown;
        pk: number;
      }[];

      const pkColumns = columns.filter((c) => c.pk > 0);
      expect(pkColumns.length).toBeGreaterThan(0);
    }
  );

  describe("Column types — Rails schema.rb 매핑 검증", () => {
    it("users table should have correct columns matching Rails schema", async () => {
      const result = await env.DB.prepare(`PRAGMA table_info(users)`).all();
      const cols = result.results as { name: string; type: string; notnull: number }[];
      const colMap = Object.fromEntries(cols.map((c) => [c.name, c]));

      // Rails: t.string "email" → TEXT in SQLite
      expect(colMap["email_hash"]).toBeDefined();
      expect(colMap["email_hash"].type.toUpperCase()).toContain("TEXT");

      // R4 분리 컬럼
      expect(colMap["email_enc"]).toBeDefined();
      expect(colMap["encryption_version"]).toBeDefined();
      expect(colMap["encryption_version"].type.toUpperCase()).toContain("INTEGER");

      // Rails 공통 timestamps
      expect(colMap["created_at"]).toBeDefined();
      expect(colMap["updated_at"]).toBeDefined();
    });

    it("assessments table should have correct columns", async () => {
      const result = await env.DB.prepare(`PRAGMA table_info(assessments)`).all();
      const cols = result.results as { name: string; type: string }[];
      const colMap = Object.fromEntries(cols.map((c) => [c.name, c]));

      expect(colMap["anonymous_session_id"]).toBeDefined();
      expect(colMap["question_set_id"]).toBeDefined();
      expect(colMap["status"]).toBeDefined();
      // Rails: t.float "completion_rate" → REAL in SQLite
      expect(colMap["completion_rate"]).toBeDefined();
    });

    it("domain_scores table should have correct columns", async () => {
      const result = await env.DB.prepare(`PRAGMA table_info(domain_scores)`).all();
      const cols = result.results as { name: string; type: string }[];
      const colMap = Object.fromEntries(cols.map((c) => [c.name, c]));

      expect(colMap["assessment_id"]).toBeDefined();
      expect(colMap["domain"]).toBeDefined();
      expect(colMap["normalized_score"]).toBeDefined();
      expect(colMap["raw_score"]).toBeDefined();
    });

    it("personality_types table should have required columns", async () => {
      const result = await env.DB.prepare(`PRAGMA table_info(personality_types)`).all();
      const cols = result.results as { name: string; type: string }[];
      const colMap = Object.fromEntries(cols.map((c) => [c.name, c]));

      expect(colMap["code"]).toBeDefined();
      expect(colMap["character_name_en"]).toBeDefined();
      expect(colMap["character_name_ko"]).toBeDefined();
      // JSON columns
      expect(colMap["strengths"]).toBeDefined();
      expect(colMap["caution_patterns"]).toBeDefined();
    });

    it("profiles table should have required columns", async () => {
      const result = await env.DB.prepare(`PRAGMA table_info(profiles)`).all();
      const cols = result.results as { name: string; type: string }[];
      const colMap = Object.fromEntries(cols.map((c) => [c.name, c]));

      expect(colMap["assessment_id"]).toBeDefined();
      expect(colMap["anonymous_session_id"]).toBeDefined();
      expect(colMap["personality_type_id"]).toBeDefined();
      expect(colMap["type_code"]).toBeDefined();
      // JSON columns
      expect(colMap["score_vector"]).toBeDefined();
      expect(colMap["strengths"]).toBeDefined();
      expect(colMap["caution_patterns"]).toBeDefined();
      expect(colMap["suggested_actions"]).toBeDefined();
    });

    it("insights table should have required columns", async () => {
      const result = await env.DB.prepare(`PRAGMA table_info(insights)`).all();
      const cols = result.results as { name: string; type: string }[];
      const colMap = Object.fromEntries(cols.map((c) => [c.name, c]));

      expect(colMap["profile_id"]).toBeDefined();
      expect(colMap["context"]).toBeDefined();
      expect(colMap["explanation"]).toBeDefined();
      // JSON column
      expect(colMap["suggestions"]).toBeDefined();
    });

    it("alerts table should have required columns", async () => {
      const result = await env.DB.prepare(`PRAGMA table_info(alerts)`).all();
      const cols = result.results as { name: string; type: string }[];
      const colMap = Object.fromEntries(cols.map((c) => [c.name, c]));

      expect(colMap["alert_type"]).toBeDefined();
      expect(colMap["severity"]).toBeDefined();
      expect(colMap["status"]).toBeDefined();
      // JSON column
      expect(colMap["metadata"]).toBeDefined();
    });

    it("audit_logs table should have required columns", async () => {
      const result = await env.DB.prepare(`PRAGMA table_info(audit_logs)`).all();
      const cols = result.results as { name: string; type: string }[];
      const colMap = Object.fromEntries(cols.map((c) => [c.name, c]));

      expect(colMap["action"]).toBeDefined();
      expect(colMap["actor_id"]).toBeDefined();
      expect(colMap["resource_type"]).toBeDefined();
      // JSON column
      expect(colMap["metadata"]).toBeDefined();
    });
  });
});
