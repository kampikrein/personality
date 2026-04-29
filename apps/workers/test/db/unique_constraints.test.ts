/**
 * test/db/unique_constraints.test.ts — UNIQUE 제약 3건 검증 (RED phase)
 *
 * Brief 021 § Model Anchors 5 + Synthesis S-018-F2:
 *   1. domain_scores: UNIQUE(assessment_id, domain)
 *   2. profiles: UNIQUE(assessment_id)
 *   3. insights: UNIQUE(profile_id, context)
 *
 * RED phase: 테이블 없음 → insert 자체 fail → 의도된 fail
 * GREEN phase: schema에 UNIQUE 제약 → 중복 insert 시 SQLITE_CONSTRAINT_UNIQUE
 *
 * 추가: Rails 원본 unique index도 함께 검증
 *   - users.email_hash UNIQUE (R4 분리 컬럼)
 *   - personality_types.code UNIQUE
 *   - question_sets.version_code UNIQUE
 *   - deletion_requests.request_token UNIQUE
 *   - anonymous_sessions.session_token UNIQUE
 *   - responses: UNIQUE(assessment_id, question_id)
 *   - questions: UNIQUE(question_set_id, domain, position)
 */

import { describe, it, expect, beforeEach } from "vitest";
import { env } from "cloudflare:test";

/**
 * 각 테스트 전 FK 비활성화 + 클린업 (독립적 테스트 보장)
 * RED phase에선 테이블 자체가 없으므로 이 setup도 fail → 의도된 fail
 */
async function disableFKs() {
  await env.DB.prepare("PRAGMA foreign_keys = OFF").run();
}

async function enableFKs() {
  await env.DB.prepare("PRAGMA foreign_keys = ON").run();
}

describe("UNIQUE Constraints — 3건 (Brief 021 Model Anchors 5) (RED phase)", () => {
  beforeEach(async () => {
    await disableFKs();
    // cleanup: 각 테스트마다 테스트 데이터 제거 (GREEN phase)
    // RED phase에서는 테이블 없으므로 에러 무시
    try {
      await env.DB.prepare("DELETE FROM domain_scores WHERE assessment_id IN (100, 200)").run();
      await env.DB.prepare("DELETE FROM profiles WHERE assessment_id IN (100, 200)").run();
      await env.DB.prepare("DELETE FROM insights WHERE profile_id IN (100, 200)").run();
    } catch {
      // RED phase: 테이블 없음 → 무시
    }
  });

  describe("1. domain_scores: UNIQUE(assessment_id, domain)", () => {
    it("should allow inserting first domain_score row", async () => {
      await expect(
        env.DB.prepare(
          `INSERT INTO domain_scores (assessment_id, domain, created_at, updated_at)
           VALUES (100, 'energy', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
        ).run()
      ).resolves.toBeDefined();
    });

    it("should reject duplicate (assessment_id, domain) pair", async () => {
      // 첫 번째 insert
      await env.DB.prepare(
        `INSERT INTO domain_scores (assessment_id, domain, created_at, updated_at)
         VALUES (100, 'energy', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
      ).run();

      // 중복 insert → UNIQUE constraint violation
      await expect(
        env.DB.prepare(
          `INSERT INTO domain_scores (assessment_id, domain, created_at, updated_at)
           VALUES (100, 'energy', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
        ).run()
      ).rejects.toThrow();
    });

    it("should allow same assessment_id with different domain", async () => {
      await env.DB.prepare(
        `INSERT INTO domain_scores (assessment_id, domain, created_at, updated_at)
         VALUES (200, 'energy', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
      ).run();

      // 같은 assessment_id지만 다른 domain → 허용
      await expect(
        env.DB.prepare(
          `INSERT INTO domain_scores (assessment_id, domain, created_at, updated_at)
           VALUES (200, 'decision_making', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
        ).run()
      ).resolves.toBeDefined();
    });
  });

  describe("2. profiles: UNIQUE(assessment_id)", () => {
    it("should allow inserting first profile row", async () => {
      await expect(
        env.DB.prepare(
          `INSERT INTO profiles (anonymous_session_id, assessment_id, personality_type_id, type_code,
            score_vector, strengths, caution_patterns, suggested_actions, created_at, updated_at)
           VALUES (1, 100, 1, 'ENFP', '{}', '[]', '[]', '[]', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
        ).run()
      ).resolves.toBeDefined();
    });

    it("should reject duplicate assessment_id in profiles", async () => {
      await env.DB.prepare(
        `INSERT INTO profiles (anonymous_session_id, assessment_id, personality_type_id, type_code,
          score_vector, strengths, caution_patterns, suggested_actions, created_at, updated_at)
         VALUES (1, 100, 1, 'ENFP', '{}', '[]', '[]', '[]', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
      ).run();

      // 같은 assessment_id → UNIQUE constraint violation
      await expect(
        env.DB.prepare(
          `INSERT INTO profiles (anonymous_session_id, assessment_id, personality_type_id, type_code,
            score_vector, strengths, caution_patterns, suggested_actions, created_at, updated_at)
           VALUES (2, 100, 1, 'ENFJ', '{}', '[]', '[]', '[]', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
        ).run()
      ).rejects.toThrow();
    });

    it("UPSERT (ON CONFLICT DO UPDATE) should succeed on assessment_id conflict", async () => {
      // scoring saga step 7 패턴 검증 (Brief 021 Model Anchors 6)
      await env.DB.prepare(
        `INSERT INTO profiles (anonymous_session_id, assessment_id, personality_type_id, type_code,
          score_vector, strengths, caution_patterns, suggested_actions, created_at, updated_at)
         VALUES (1, 200, 1, 'ENFP', '{}', '[]', '[]', '[]', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
      ).run();

      // UPSERT — ON CONFLICT(assessment_id) DO UPDATE
      await expect(
        env.DB.prepare(
          `INSERT INTO profiles (anonymous_session_id, assessment_id, personality_type_id, type_code,
            score_vector, strengths, caution_patterns, suggested_actions, created_at, updated_at)
           VALUES (1, 200, 1, 'ENFJ', '{}', '["updated"]', '[]', '[]', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
           ON CONFLICT(assessment_id) DO UPDATE SET type_code = excluded.type_code, strengths = excluded.strengths`
        ).run()
      ).resolves.toBeDefined();

      const result = await env.DB.prepare(
        `SELECT type_code, strengths FROM profiles WHERE assessment_id = 200`
      ).first<{ type_code: string; strengths: string }>();
      expect(result).not.toBeNull();
      expect(result!.type_code).toBe("ENFJ");
    });
  });

  describe("3. insights: UNIQUE(profile_id, context)", () => {
    // profile_id=150, 250 사용 (beforeEach cleanup의 100/200 삭제 범위 밖)
    // setup.ts에서 profiles(id=150, 250) fixture 생성됨

    it("should allow inserting first insight row", async () => {
      // cleanup
      await env.DB.prepare("DELETE FROM insights WHERE profile_id = 150").run().catch(() => {});
      await expect(
        env.DB.prepare(
          `INSERT INTO insights (profile_id, context, suggestions, created_at, updated_at)
           VALUES (150, 'career', '[]', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
        ).run()
      ).resolves.toBeDefined();
    });

    it("should reject duplicate (profile_id, context) pair", async () => {
      // cleanup
      await env.DB.prepare("DELETE FROM insights WHERE profile_id = 150").run().catch(() => {});
      await env.DB.prepare(
        `INSERT INTO insights (profile_id, context, suggestions, created_at, updated_at)
         VALUES (150, 'career', '[]', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
      ).run();

      // 중복 (profile_id, context) → UNIQUE constraint violation
      await expect(
        env.DB.prepare(
          `INSERT INTO insights (profile_id, context, suggestions, created_at, updated_at)
           VALUES (150, 'career', '["new suggestion"]', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
        ).run()
      ).rejects.toThrow();
    });

    it("should allow same profile_id with different context", async () => {
      // cleanup
      await env.DB.prepare("DELETE FROM insights WHERE profile_id = 250").run().catch(() => {});
      await env.DB.prepare(
        `INSERT INTO insights (profile_id, context, suggestions, created_at, updated_at)
         VALUES (250, 'career', '[]', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
      ).run();

      // 같은 profile_id지만 다른 context → 허용
      await expect(
        env.DB.prepare(
          `INSERT INTO insights (profile_id, context, suggestions, created_at, updated_at)
           VALUES (250, 'relationship', '[]', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
        ).run()
      ).resolves.toBeDefined();
    });
  });
});

describe("Additional UNIQUE constraints (Rails 원본 unique indexes)", () => {
  beforeEach(disableFKs);

  it("personality_types.code should be UNIQUE", async () => {
    await env.DB.prepare(
      `INSERT INTO personality_types (code, character_name_en, character_name_ko, caution_patterns, strengths, created_at, updated_at)
       VALUES ('UQ_TEST', 'Test EN', 'Test KO', '[]', '[]', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
    ).run();

    await expect(
      env.DB.prepare(
        `INSERT INTO personality_types (code, character_name_en, character_name_ko, caution_patterns, strengths, created_at, updated_at)
         VALUES ('UQ_TEST', 'Dup EN', 'Dup KO', '[]', '[]', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
      ).run()
    ).rejects.toThrow();
  });

  it("users.email_hash should be UNIQUE (R4 분리 컬럼)", async () => {
    const hash = "a".repeat(64); // 64자 SHA-256 hex placeholder

    await env.DB.prepare(
      `INSERT INTO users (email_hash, email_enc, encryption_version, created_at, updated_at)
       VALUES (?, 'enc_test', 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
    )
      .bind(hash)
      .run();

    await expect(
      env.DB.prepare(
        `INSERT INTO users (email_hash, email_enc, encryption_version, created_at, updated_at)
         VALUES (?, 'enc_test2', 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
      )
        .bind(hash)
        .run()
    ).rejects.toThrow();
  });

  it("question_sets.version_code should be UNIQUE", async () => {
    await env.DB.prepare(
      `INSERT INTO question_sets (version_code, status, created_at, updated_at)
       VALUES ('qset_v1', 'active', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
    ).run();

    await expect(
      env.DB.prepare(
        `INSERT INTO question_sets (version_code, status, created_at, updated_at)
         VALUES ('qset_v1', 'active', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
      ).run()
    ).rejects.toThrow();
  });

  it("deletion_requests.request_token should be UNIQUE", async () => {
    await env.DB.prepare(
      `INSERT INTO deletion_requests (anonymous_session_id, request_token, status, created_at, updated_at)
       VALUES (1, 'unique_token_123', 'pending', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
    ).run();

    await expect(
      env.DB.prepare(
        `INSERT INTO deletion_requests (anonymous_session_id, request_token, status, created_at, updated_at)
         VALUES (2, 'unique_token_123', 'pending', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
      ).run()
    ).rejects.toThrow();
  });

  it("anonymous_sessions.session_token should be UNIQUE", async () => {
    await env.DB.prepare(
      `INSERT INTO anonymous_sessions (session_token, created_at, updated_at)
       VALUES ('session_abc', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
    ).run();

    await expect(
      env.DB.prepare(
        `INSERT INTO anonymous_sessions (session_token, created_at, updated_at)
         VALUES ('session_abc', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
      ).run()
    ).rejects.toThrow();
  });

  it("responses: UNIQUE(assessment_id, question_id)", async () => {
    await env.DB.prepare(
      `INSERT INTO responses (assessment_id, question_id, value, created_at, updated_at)
       VALUES (1, 1, 4, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
    ).run();

    await expect(
      env.DB.prepare(
        `INSERT INTO responses (assessment_id, question_id, value, created_at, updated_at)
         VALUES (1, 1, 3, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
      ).run()
    ).rejects.toThrow();
  });
});
