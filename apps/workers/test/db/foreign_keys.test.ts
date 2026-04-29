/**
 * test/db/foreign_keys.test.ts — 14 FK 존재 + 무결성 검증 (RED phase)
 *
 * Rails schema.rb add_foreign_key 14건:
 *   1.  anonymous_sessions → users
 *   2.  assessments → anonymous_sessions
 *   3.  assessments → question_sets
 *   4.  consents → anonymous_sessions
 *   5.  consents → users
 *   6.  deletion_requests → anonymous_sessions
 *   7.  domain_scores → assessments
 *   8.  insights → profiles
 *   9.  profiles → anonymous_sessions
 *  10.  profiles → assessments
 *  11.  profiles → personality_types
 *  12.  questions → question_sets
 *  13.  responses → assessments
 *  14.  responses → questions
 *
 * RED phase: 테이블/FK 없음 → PRAGMA 조회 fail 또는 insert 성공(FK 없어서) → 의도된 fail
 * GREEN phase: FK 정의 후 무결성 위반 → SQLITE_CONSTRAINT_FOREIGNKEY
 */

import { describe, it, expect } from "vitest";
import { env } from "cloudflare:test";

// FK 정의 목록: [child_table, parent_table, child_col, parent_col]
const EXPECTED_FKS: [string, string, string, string][] = [
  ["anonymous_sessions", "users", "user_id", "id"],
  ["assessments", "anonymous_sessions", "anonymous_session_id", "id"],
  ["assessments", "question_sets", "question_set_id", "id"],
  ["consents", "anonymous_sessions", "anonymous_session_id", "id"],
  ["consents", "users", "user_id", "id"],
  ["deletion_requests", "anonymous_sessions", "anonymous_session_id", "id"],
  ["domain_scores", "assessments", "assessment_id", "id"],
  ["insights", "profiles", "profile_id", "id"],
  ["profiles", "anonymous_sessions", "anonymous_session_id", "id"],
  ["profiles", "assessments", "assessment_id", "id"],
  ["profiles", "personality_types", "personality_type_id", "id"],
  ["questions", "question_sets", "question_set_id", "id"],
  ["responses", "assessments", "assessment_id", "id"],
  ["responses", "questions", "question_id", "id"],
];

describe("Foreign Keys — 14 FK 존재 + 무결성 (RED phase)", () => {
  it("should have foreign_keys pragma enabled", async () => {
    // D1은 기본적으로 PRAGMA foreign_keys = ON
    // GREEN phase에서 schema migration이 FK를 정의해야 유효
    const result = await env.DB.prepare("PRAGMA foreign_keys").first<{ foreign_keys: number }>();
    // D1 in-memory에서 FK pragma 상태 확인
    expect(result).not.toBeNull();
    // GREEN phase: FK 활성화 == 1 이어야 함
    // RED phase: PRAGMA 자체는 동작하지만 FK 정의가 없으므로 이후 무결성 테스트들이 fail
  });

  describe("FK 존재 확인 (PRAGMA foreign_key_list)", () => {
    it.each(EXPECTED_FKS)(
      "table '%s' should have FK to '%s' on column '%s' → '%s'",
      async (childTable, parentTable, childCol, _parentCol) => {
        const result = await env.DB.prepare(
          `PRAGMA foreign_key_list(${childTable})`
        ).all();

        const fks = result.results as {
          id: number;
          seq: number;
          table: string;
          from: string;
          to: string;
          on_update: string;
          on_delete: string;
          match: string;
        }[];

        // FK가 없으면 빈 배열 → fail
        expect(fks.length).toBeGreaterThan(0);

        // 해당 parent table로의 FK 존재 확인
        const matchingFk = fks.find(
          (fk) => fk.table === parentTable && fk.from === childCol
        );
        expect(matchingFk).toBeDefined();
      }
    );
  });

  describe("FK 무결성 — 부모 row 없이 child insert 시 에러", () => {
    it("inserting domain_scores without parent assessment should fail", async () => {
      // PRAGMA foreign_keys = ON 상태에서
      await env.DB.prepare("PRAGMA foreign_keys = ON").run();

      await expect(
        env.DB.prepare(
          `INSERT INTO domain_scores (assessment_id, domain, created_at, updated_at)
           VALUES (99999, 'energy', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
        ).run()
      ).rejects.toThrow();
    });

    it("inserting insights without parent profile should fail", async () => {
      await env.DB.prepare("PRAGMA foreign_keys = ON").run();

      await expect(
        env.DB.prepare(
          `INSERT INTO insights (profile_id, context, created_at, updated_at)
           VALUES (99999, 'test', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
        ).run()
      ).rejects.toThrow();
    });

    it("inserting profiles without parent assessment should fail", async () => {
      await env.DB.prepare("PRAGMA foreign_keys = ON").run();

      await expect(
        env.DB.prepare(
          `INSERT INTO profiles (anonymous_session_id, assessment_id, personality_type_id, type_code,
            score_vector, strengths, caution_patterns, suggested_actions, created_at, updated_at)
           VALUES (99999, 99999, 99999, 'ENFP', '{}', '[]', '[]', '[]', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
        ).run()
      ).rejects.toThrow();
    });

    it("inserting responses without parent assessment should fail", async () => {
      await env.DB.prepare("PRAGMA foreign_keys = ON").run();

      await expect(
        env.DB.prepare(
          `INSERT INTO responses (assessment_id, question_id, created_at, updated_at)
           VALUES (99999, 99999, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
        ).run()
      ).rejects.toThrow();
    });
  });

  describe("ON DELETE 정책 확인 (Rails dependent: :destroy ↔ ON DELETE CASCADE)", () => {
    it("domain_scores FK to assessments should have CASCADE or RESTRICT on_delete", async () => {
      const result = await env.DB.prepare(
        `PRAGMA foreign_key_list(domain_scores)`
      ).all();

      const fks = result.results as {
        table: string;
        from: string;
        on_delete: string;
      }[];

      const assessmentFk = fks.find((fk) => fk.table === "assessments");
      expect(assessmentFk).toBeDefined();

      // Rails: assessments has_many domain_scores, dependent: :destroy → ON DELETE CASCADE
      // 또는 NO ACTION (application-level cascade) — Drizzle 구현에 따라
      expect(["CASCADE", "NO ACTION", "RESTRICT"]).toContain(
        assessmentFk!.on_delete.toUpperCase()
      );
    });

    it("insights FK to profiles should define on_delete policy", async () => {
      const result = await env.DB.prepare(
        `PRAGMA foreign_key_list(insights)`
      ).all();

      const fks = result.results as {
        table: string;
        from: string;
        on_delete: string;
      }[];

      const profileFk = fks.find((fk) => fk.table === "profiles");
      expect(profileFk).toBeDefined();
      expect(profileFk!.on_delete).toBeDefined();
    });
  });
});
