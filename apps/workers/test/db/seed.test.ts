/**
 * test/db/seed.test.ts — PersonalityType × 16 seed 검증 (RED phase)
 *
 * Rails server/db/seeds.rb 원본:
 *   16개 MBTI 코드 (ENFP, ENFJ, ENTP, ENTJ, ESFP, ESFJ, ESTP, ESTJ,
 *                   INFP, INFJ, INTP, INTJ, ISFP, ISFJ, ISTP, ISTJ)
 *
 * 검증:
 *   1. personality_types 테이블에 16 row 존재
 *   2. 각 row의 code/character_name_en/character_name_ko 채워짐
 *   3. JSON 컬럼 (strengths, caution_patterns) 비어있지 않은 배열
 *   4. 16개 code가 정확히 일치 (순서 무관)
 *
 * RED phase: 테이블 없음 → 쿼리 fail → 의도된 fail
 * GREEN phase: migration + seed 실행 후 통과
 */

import { describe, it, expect } from "vitest";
import { env } from "cloudflare:test";

// Rails seeds.rb의 16개 MBTI 코드
const EXPECTED_CODES = [
  "ENFP", "ENFJ", "ENTP", "ENTJ",
  "ESFP", "ESFJ", "ESTP", "ESTJ",
  "INFP", "INFJ", "INTP", "INTJ",
  "ISFP", "ISFJ", "ISTP", "ISTJ",
] as const;

// Rails seeds.rb의 character_name_ko 매핑 (부분 검증)
const CODE_TO_CHARACTER_KO: Record<string, string> = {
  ENFP: "빛나는 탐험가",
  ENFJ: "따뜻한 이끌림",
  ENTP: "날카로운 발명가",
  ENTJ: "결단의 항해사",
  ESFP: "자유로운 무대",
  ESFJ: "든든한 연결고리",
  ESTP: "현장의 해결사",
  ESTJ: "믿음직한 기둥",
  INFP: "고요한 몽상가",
  INFJ: "깊은 통찰자",
  INTP: "조용한 설계자",
  INTJ: "먼 곳을 보는 눈",
  ISFP: "감각의 예술가",
  ISFJ: "조용한 돌봄이",
  ISTP: "냉철한 장인",
  ISTJ: "묵묵한 완성자",
};

describe("Seed — PersonalityType × 16 (RED phase)", () => {
  it("should have exactly 16 rows in personality_types after seed", async () => {
    const result = await env.DB.prepare(
      `SELECT COUNT(*) as cnt FROM personality_types`
    ).first<{ cnt: number }>();

    expect(result).not.toBeNull();
    // RED phase: 테이블 없음 → fail
    // GREEN phase: seed 실행 후 → 16
    expect(result!.cnt).toBe(16);
  });

  it("should contain all 16 MBTI codes", async () => {
    const result = await env.DB.prepare(
      `SELECT code FROM personality_types ORDER BY code`
    ).all();

    const codes = (result.results as { code: string }[]).map((r) => r.code);

    for (const expectedCode of EXPECTED_CODES) {
      expect(codes).toContain(expectedCode);
    }
  });

  it("should have no extra codes beyond 16", async () => {
    const result = await env.DB.prepare(
      `SELECT code FROM personality_types`
    ).all();

    const codes = (result.results as { code: string }[]).map((r) => r.code);
    expect(codes).toHaveLength(16);

    const expectedSet = new Set(EXPECTED_CODES);
    for (const code of codes) {
      expect(expectedSet.has(code as (typeof EXPECTED_CODES)[number])).toBe(true);
    }
  });

  describe("각 row의 필수 컬럼 채워짐 검증", () => {
    it("each personality_type should have non-empty code, character_name_ko, character_name_en", async () => {
      const result = await env.DB.prepare(
        `SELECT code, character_name_ko, character_name_en FROM personality_types`
      ).all();

      const rows = result.results as {
        code: string;
        character_name_ko: string;
        character_name_en: string;
      }[];

      expect(rows).toHaveLength(16);

      for (const row of rows) {
        expect(row.code).toBeTruthy();
        expect(row.code.length).toBe(4); // ENFP 등 4자
        expect(row.character_name_ko).toBeTruthy();
        expect(row.character_name_en).toBeTruthy();
      }
    });

    it("character_name_ko should match seeds.rb values", async () => {
      const result = await env.DB.prepare(
        `SELECT code, character_name_ko FROM personality_types`
      ).all();

      const rows = result.results as { code: string; character_name_ko: string }[];

      for (const row of rows) {
        const expectedKo = CODE_TO_CHARACTER_KO[row.code];
        expect(expectedKo).toBeDefined();
        expect(row.character_name_ko).toBe(expectedKo);
      }
    });

    it("each personality_type should have non-empty strengths array (JSON)", async () => {
      const result = await env.DB.prepare(
        `SELECT code, strengths FROM personality_types`
      ).all();

      const rows = result.results as { code: string; strengths: string }[];

      for (const row of rows) {
        const strengths = JSON.parse(row.strengths);
        expect(Array.isArray(strengths)).toBe(true);
        // seeds.rb 데이터에서 모든 타입에 4개 강점이 정의됨
        expect(strengths.length).toBeGreaterThan(0);
      }
    });

    it("each personality_type should have non-empty caution_patterns array (JSON)", async () => {
      const result = await env.DB.prepare(
        `SELECT code, caution_patterns FROM personality_types`
      ).all();

      const rows = result.results as { code: string; caution_patterns: string }[];

      for (const row of rows) {
        const caution = JSON.parse(row.caution_patterns);
        expect(Array.isArray(caution)).toBe(true);
        expect(caution.length).toBeGreaterThan(0);
      }
    });

    it("each personality_type should have non-empty text fields", async () => {
      const result = await env.DB.prepare(
        `SELECT code, summary_ko, summary_en, collaboration_style, conflict_style, learning_style, career_hints, recovery_style
         FROM personality_types`
      ).all();

      const rows = result.results as {
        code: string;
        summary_ko: string;
        summary_en: string;
        collaboration_style: string;
        conflict_style: string;
        learning_style: string;
        career_hints: string;
        recovery_style: string;
      }[];

      for (const row of rows) {
        expect(row.summary_ko).toBeTruthy();
        expect(row.summary_en).toBeTruthy();
        expect(row.collaboration_style).toBeTruthy();
        expect(row.conflict_style).toBeTruthy();
        expect(row.learning_style).toBeTruthy();
        expect(row.career_hints).toBeTruthy();
        expect(row.recovery_style).toBeTruthy();
      }
    });
  });

  describe("find_or_create_by 멱등성 (Rails seed 패턴 동등)", () => {
    it("should be idempotent — re-inserting same codes on conflict should not throw", async () => {
      // Rails: PersonalityType.find_or_initialize_by(code:).save! 패턴
      // SQLite: INSERT OR IGNORE INTO / ON CONFLICT(code) DO NOTHING
      await expect(
        env.DB.prepare(
          `INSERT OR IGNORE INTO personality_types (code, character_name_en, character_name_ko, caution_patterns, strengths, created_at, updated_at)
           VALUES ('ENFP', 'Radiant Explorer', '빛나는 탐험가', '[]', '[]', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
        ).run()
      ).resolves.toBeDefined();

      // 재실행해도 count는 변하지 않아야 함
      const result = await env.DB.prepare(
        `SELECT COUNT(*) as cnt FROM personality_types WHERE code = 'ENFP'`
      ).first<{ cnt: number }>();
      expect(result!.cnt).toBe(1);
    });
  });
});
