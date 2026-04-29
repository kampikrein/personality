/**
 * test/db/json_columns.test.ts — 9 JSON 컬럼 round-trip 검증 (RED phase)
 *
 * Rails schema.rb의 t.json 컬럼 9개:
 *   1. alerts.metadata (default: {})
 *   2. audit_logs.metadata (default: {})
 *   3. insights.suggestions (default: [])
 *   4. personality_types.caution_patterns (default: [])
 *   5. personality_types.strengths (default: [])
 *   6. profiles.caution_patterns (default: [])
 *   7. profiles.score_vector (default: {})
 *   8. profiles.strengths (default: [])
 *   9. profiles.suggested_actions (default: [])
 *
 * Drizzle 매핑: text({ mode: 'json' }).$type<T>()
 * 검증: insert JS 객체/배열 → select → JS 객체/배열 round-trip
 *
 * RED phase: 테이블 미생성 → 모든 insert fail → 의도된 fail
 */

import { describe, it, expect } from "vitest";
import { env } from "cloudflare:test";

describe("JSON columns — 9개 round-trip 검증 (RED phase)", () => {
  describe("alerts.metadata (JSON object, default: {})", () => {
    it("should insert and select JSON object correctly", async () => {
      const metadata = { key: "value", count: 42, nested: { ok: true } };

      await env.DB.prepare(
        `INSERT INTO alerts (alert_type, severity, status, metadata, created_at, updated_at)
         VALUES (?, 'medium', 'open', ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
      )
        .bind("test_type", JSON.stringify(metadata))
        .run();

      const result = await env.DB.prepare(
        `SELECT metadata FROM alerts WHERE alert_type = 'test_type' LIMIT 1`
      ).first<{ metadata: string }>();

      expect(result).not.toBeNull();
      const parsed = JSON.parse(result!.metadata);
      expect(parsed).toEqual(metadata);
    });

    it("should default to empty object when not provided", async () => {
      await env.DB.prepare(
        `INSERT INTO alerts (alert_type, severity, status, created_at, updated_at)
         VALUES ('default_test', 'low', 'open', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
      ).run();

      const result = await env.DB.prepare(
        `SELECT metadata FROM alerts WHERE alert_type = 'default_test' LIMIT 1`
      ).first<{ metadata: string }>();

      expect(result).not.toBeNull();
      const parsed = JSON.parse(result!.metadata);
      expect(parsed).toEqual({});
    });
  });

  describe("audit_logs.metadata (JSON object, default: {})", () => {
    it("should insert and select JSON object correctly", async () => {
      const metadata = { ip: "127.0.0.1", user_agent: "test-agent" };

      await env.DB.prepare(
        `INSERT INTO audit_logs (action, metadata, created_at, updated_at)
         VALUES ('test_action', ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
      )
        .bind(JSON.stringify(metadata))
        .run();

      const result = await env.DB.prepare(
        `SELECT metadata FROM audit_logs WHERE action = 'test_action' LIMIT 1`
      ).first<{ metadata: string }>();

      expect(result).not.toBeNull();
      const parsed = JSON.parse(result!.metadata);
      expect(parsed).toEqual(metadata);
    });
  });

  describe("insights.suggestions (JSON array, default: [])", () => {
    it("should insert and select JSON array correctly", async () => {
      // profile_id FK가 있으므로 profiles 테이블이 존재해야 함 (테이블 없으면 fail)
      const suggestions = ["suggestion 1", "suggestion 2", "더 많은 연습을 하세요"];

      // 임시 profile_id = 999 (FK 검증 테스트가 별도이므로 여기선 pragmatic)
      await env.DB.prepare(`PRAGMA foreign_keys = OFF`).run();
      await env.DB.prepare(
        `INSERT INTO insights (profile_id, context, suggestions, created_at, updated_at)
         VALUES (999, 'test_context', ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
      )
        .bind(JSON.stringify(suggestions))
        .run();
      await env.DB.prepare(`PRAGMA foreign_keys = ON`).run();

      const result = await env.DB.prepare(
        `SELECT suggestions FROM insights WHERE context = 'test_context' LIMIT 1`
      ).first<{ suggestions: string }>();

      expect(result).not.toBeNull();
      const parsed = JSON.parse(result!.suggestions);
      expect(parsed).toEqual(suggestions);
    });
  });

  describe("personality_types.caution_patterns (JSON array, default: [])", () => {
    it("should insert and select JSON array correctly", async () => {
      const caution = ["주의사항 1", "주의사항 2"];

      await env.DB.prepare(
        `INSERT INTO personality_types (code, character_name_en, character_name_ko, caution_patterns, strengths, created_at, updated_at)
         VALUES ('TEST', 'Test EN', 'Test KO', ?, '[]', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
      )
        .bind(JSON.stringify(caution))
        .run();

      const result = await env.DB.prepare(
        `SELECT caution_patterns FROM personality_types WHERE code = 'TEST' LIMIT 1`
      ).first<{ caution_patterns: string }>();

      expect(result).not.toBeNull();
      const parsed = JSON.parse(result!.caution_patterns);
      expect(parsed).toEqual(caution);
    });
  });

  describe("personality_types.strengths (JSON array, default: [])", () => {
    it("should insert and select JSON array correctly", async () => {
      const strengths = ["강점 1", "강점 2", "강점 3"];

      await env.DB.prepare(
        `INSERT INTO personality_types (code, character_name_en, character_name_ko, caution_patterns, strengths, created_at, updated_at)
         VALUES ('TST2', 'Test2 EN', 'Test2 KO', '[]', ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
      )
        .bind(JSON.stringify(strengths))
        .run();

      const result = await env.DB.prepare(
        `SELECT strengths FROM personality_types WHERE code = 'TST2' LIMIT 1`
      ).first<{ strengths: string }>();

      expect(result).not.toBeNull();
      const parsed = JSON.parse(result!.strengths);
      expect(parsed).toEqual(strengths);
    });
  });

  describe("profiles JSON columns — score_vector, strengths, caution_patterns, suggested_actions", () => {
    it("should store and retrieve score_vector as JSON object", async () => {
      const scoreVector = { energy: 0.75, decision_making: 0.6, relationship: 0.4, recovery: 0.55 };

      await env.DB.prepare(`PRAGMA foreign_keys = OFF`).run();
      await env.DB.prepare(
        `INSERT INTO profiles (anonymous_session_id, assessment_id, personality_type_id, type_code,
          score_vector, strengths, caution_patterns, suggested_actions, created_at, updated_at)
         VALUES (1, 1, 1, 'ENFP', ?, '[]', '[]', '[]', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
      )
        .bind(JSON.stringify(scoreVector))
        .run();
      await env.DB.prepare(`PRAGMA foreign_keys = ON`).run();

      const result = await env.DB.prepare(
        `SELECT score_vector FROM profiles WHERE type_code = 'ENFP' LIMIT 1`
      ).first<{ score_vector: string }>();

      expect(result).not.toBeNull();
      const parsed = JSON.parse(result!.score_vector);
      expect(parsed).toEqual(scoreVector);
    });

    it("should store and retrieve profiles.strengths as JSON array", async () => {
      const strengths = ["공감 능력이 뛰어남", "창의적 문제 해결"];

      await env.DB.prepare(`PRAGMA foreign_keys = OFF`).run();
      await env.DB.prepare(
        `INSERT INTO profiles (anonymous_session_id, assessment_id, personality_type_id, type_code,
          score_vector, strengths, caution_patterns, suggested_actions, created_at, updated_at)
         VALUES (2, 2, 1, 'ENFJ', '{}', ?, '[]', '[]', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
      )
        .bind(JSON.stringify(strengths))
        .run();
      await env.DB.prepare(`PRAGMA foreign_keys = ON`).run();

      const result = await env.DB.prepare(
        `SELECT strengths FROM profiles WHERE type_code = 'ENFJ' LIMIT 1`
      ).first<{ strengths: string }>();

      expect(result).not.toBeNull();
      const parsed = JSON.parse(result!.strengths);
      expect(parsed).toEqual(strengths);
    });

    it("should store and retrieve profiles.caution_patterns as JSON array", async () => {
      const caution = ["여러 프로젝트 동시 진행 시 완성도 저하 가능"];

      await env.DB.prepare(`PRAGMA foreign_keys = OFF`).run();
      await env.DB.prepare(
        `INSERT INTO profiles (anonymous_session_id, assessment_id, personality_type_id, type_code,
          score_vector, strengths, caution_patterns, suggested_actions, created_at, updated_at)
         VALUES (3, 3, 1, 'ENTP', '{}', '[]', ?, '[]', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
      )
        .bind(JSON.stringify(caution))
        .run();
      await env.DB.prepare(`PRAGMA foreign_keys = ON`).run();

      const result = await env.DB.prepare(
        `SELECT caution_patterns FROM profiles WHERE type_code = 'ENTP' LIMIT 1`
      ).first<{ caution_patterns: string }>();

      expect(result).not.toBeNull();
      const parsed = JSON.parse(result!.caution_patterns);
      expect(parsed).toEqual(caution);
    });

    it("should store and retrieve profiles.suggested_actions as JSON array", async () => {
      const actions = [{ action: "명상 10분", priority: 1 }, { action: "독서", priority: 2 }];

      await env.DB.prepare(`PRAGMA foreign_keys = OFF`).run();
      await env.DB.prepare(
        `INSERT INTO profiles (anonymous_session_id, assessment_id, personality_type_id, type_code,
          score_vector, strengths, caution_patterns, suggested_actions, created_at, updated_at)
         VALUES (4, 4, 1, 'ENTJ', '{}', '[]', '[]', ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
      )
        .bind(JSON.stringify(actions))
        .run();
      await env.DB.prepare(`PRAGMA foreign_keys = ON`).run();

      const result = await env.DB.prepare(
        `SELECT suggested_actions FROM profiles WHERE type_code = 'ENTJ' LIMIT 1`
      ).first<{ suggested_actions: string }>();

      expect(result).not.toBeNull();
      const parsed = JSON.parse(result!.suggested_actions);
      expect(parsed).toEqual(actions);
    });
  });

  describe("JSON1 extension compatibility", () => {
    it("json_extract should work on JSON columns (D1 JSON1 함수 호환)", async () => {
      await env.DB.prepare(`PRAGMA foreign_keys = OFF`).run();
      await env.DB.prepare(
        `INSERT INTO personality_types (code, character_name_en, character_name_ko, caution_patterns, strengths, created_at, updated_at)
         VALUES ('JSON1_TEST', 'JSON1 EN', 'JSON1 KO', '[]', ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
      )
        .bind(JSON.stringify(["강점A", "강점B"]))
        .run();
      await env.DB.prepare(`PRAGMA foreign_keys = ON`).run();

      // json_extract로 배열 첫 번째 원소 조회 — D1 JSON1 호환 확인
      const result = await env.DB.prepare(
        `SELECT json_extract(strengths, '$[0]') as first_strength FROM personality_types WHERE code = 'JSON1_TEST'`
      ).first<{ first_strength: string }>();

      expect(result).not.toBeNull();
      expect(result!.first_strength).toBe("강점A");
    });
  });
});
