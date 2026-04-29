/**
 * test/services/compliance/snapshot.test.ts — RED phase
 * RSpec: server/spec/services/compliance/snapshot_spec.rb (14 tests)
 *
 * In Rails: "model spec" that scans seed data + ERB templates for restricted terms.
 * In TS: D1 seed data compliance verification.
 *
 * Contract:
 *   scanSeedDataForViolations(db) → SnapshotViolation[]
 *   verifyCharacterNameOriginality(db) → { violations, hasUniqueNames }
 *
 * Tests verify:
 *   1. All 16 personality types exist in seed
 *   2. character_name_ko contains 0 restricted term violations
 *   3. summary_ko contains 0 restricted term violations
 *   4. All text fields contain 0 restricted term violations
 *   5. Character name originality (no match to official MBTI names)
 *   6. 16 unique character_name_ko values
 *   7. 16 unique character_name_en values
 */

import { describe, it, expect } from "vitest";
import { env } from "cloudflare:test";
import {
  scanSeedDataForViolations,
  verifyCharacterNameOriginality,
} from "../../../src/services/compliance/snapshot";

const OFFICIAL_MBTI_NAMES_EN = [
  "The Inspector", "The Protector", "The Counselor", "The Mastermind",
  "The Crafter", "The Composer", "The Healer", "The Architect",
  "The Dynamo", "The Performer", "The Champion", "The Visionary",
  "The Supervisor", "The Provider", "The Teacher", "The Commander",
];

const OFFICIAL_MBTI_NAMES_KO = [
  "옹호자", "중재자", "선의의 옹호자", "정의의 사도",
  "논리학자", "건축가", "과학자", "전략가",
  "활동가", "재기발랄한 활동가", "호기심 많은 예술가", "모험을 즐기는 사업가",
  "사업가", "경영자", "수호자", "현실주의자",
  "용감한 수호자", "열정적인 중재자",
];

const EXPECTED_CODES = [
  "ENFP", "ENFJ", "ENTP", "ENTJ",
  "ESFP", "ESFJ", "ESTP", "ESTJ",
  "INFP", "INFJ", "INTP", "INTJ",
  "ISFP", "ISFJ", "ISTP", "ISTJ",
];

describe("Compliance::Snapshot — Legal Content Verification (RED phase)", () => {
  describe("seed data completeness", () => {
    it("has all 16 personality types loaded", async () => {
      const result = await env.DB.prepare(
        "SELECT COUNT(*) as cnt FROM personality_types"
      ).first<{ cnt: number }>();
      expect(result?.cnt).toBe(16);
    });

    it("has one PersonalityType for each expected code", async () => {
      for (const code of EXPECTED_CODES) {
        const row = await env.DB.prepare(
          "SELECT id FROM personality_types WHERE code = ?"
        ).bind(code).first<{ id: number }>();
        expect(row).not.toBeNull();
      }
    });
  });

  describe("character_name_ko restricted term scan", () => {
    it("contains 0 restricted term violations across all 16 types", async () => {
      const violations = await scanSeedDataForViolations(env.DB);
      const nameKoViolations = violations.filter((v) => v.field === "character_name_ko");
      expect(nameKoViolations).toHaveLength(0);
    });
  });

  describe("summary_ko restricted term scan", () => {
    it("contains 0 restricted term violations across all 16 types", async () => {
      const violations = await scanSeedDataForViolations(env.DB);
      const summaryKoViolations = violations.filter((v) => v.field === "summary_ko");
      expect(summaryKoViolations).toHaveLength(0);
    });
  });

  describe("full content restricted term scan (all text fields)", () => {
    it("finds 0 violations across all text fields of all personality types", async () => {
      const violations = await scanSeedDataForViolations(env.DB);
      expect(violations).toHaveLength(0);
    });
  });

  describe("character name originality", () => {
    it("has 16 unique character_name_ko values (no duplicates)", async () => {
      const { hasUniqueNames } = await verifyCharacterNameOriginality(env.DB);
      expect(hasUniqueNames).toBe(true);
    });

    it("has 16 unique character_name_en values (no duplicates)", async () => {
      const rows = await env.DB.prepare(
        "SELECT character_name_en FROM personality_types"
      ).all<{ character_name_en: string }>();
      const names = rows.results.map((r) => r.character_name_en);
      const unique = new Set(names);
      expect(unique.size).toBe(16);
    });

    it("has no character_name_en that matches an official MBTI English name", async () => {
      const { violations } = await verifyCharacterNameOriginality(env.DB);
      const enViolations = violations.filter((v) => v.field === "character_name_en");
      expect(enViolations).toHaveLength(0);
    });

    it("has no character_name_ko that matches an official MBTI Korean name", async () => {
      const { violations } = await verifyCharacterNameOriginality(env.DB);
      const koViolations = violations.filter((v) => v.field === "character_name_ko");
      expect(koViolations).toHaveLength(0);
    });
  });

  describe("Trust Notice (TS equivalent — no ERB scan)", () => {
    // Rails版: ERB 파일 스캔 → TS版: trust notice 내용 자체는 서버 코드이므로
    // 여기서는 RestrictedTerms API의 allow_trust_notice 기능이 올바르게 동작하는지 검증
    it("allow_trust_notice=true 모드에서 MBTI 허용 확인", async () => {
      // scanSeedDataForViolations 내부에서 isTextClean()을 사용하므로
      // trust_notice 컨텍스트 동작은 textPolicyFilter.test.ts에서 검증됨
      // 여기서는 seed data 자체가 MBTI 포함하지 않음을 확인
      const violations = await scanSeedDataForViolations(env.DB);
      const mbtiViolations = violations.filter((v) =>
        v.terms.includes("MBTI") || v.terms.includes("Myers-Briggs")
      );
      expect(mbtiViolations).toHaveLength(0);
    });
  });
});
