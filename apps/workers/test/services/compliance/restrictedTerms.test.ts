/**
 * test/services/compliance/restrictedTerms.test.ts — RED phase
 * RSpec: server/spec/services/compliance/restricted_terms_spec.rb (17 tests)
 *
 * Contract:
 *   scanRestrictedTerms(text) → string[] of violated terms
 *   isTextClean(text, options?) → boolean
 *
 * RESTRICTED corpus (from Rails):
 *   Trademarks: MBTI, Myers-Briggs, 마이어스-브릭스, Myers-Briggs Type Indicator, 에니어그램, Enneagram
 *   Korean official names: 옹호자, 중재자, 선의의 옹호자, 정의의 사도, 논리학자, 건축가, 과학자, 전략가,
 *     활동가, 재기발랄한 활동가, 호기심 많은 예술가, 모험을 즐기는 사업가, 사업가, 경영자, 수호자, 현실주의자,
 *     용감한 수호자, 열정적인 중재자
 *   English official names: The Inspector, The Protector, The Counselor, The Mastermind,
 *     The Crafter, The Composer, The Healer, The Architect, The Dynamo, The Performer,
 *     The Champion, The Visionary, The Supervisor, The Provider, The Teacher, The Commander
 *
 * ALLOWED_IN_TRUST_NOTICE: ["MBTI", "Myers-Briggs"]
 */

import { describe, it, expect } from "vitest";
import {
  scanRestrictedTerms,
  isTextClean,
} from "../../../src/services/compliance/restrictedTerms";

describe("RestrictedTerms (RED phase)", () => {
  describe("scan", () => {
    it("detects 'MBTI' in text", () => {
      expect(scanRestrictedTerms("Your MBTI result is ready")).toContain("MBTI");
    });

    it("detects 'MBTI' case-insensitively", () => {
      expect(scanRestrictedTerms("your mbti result is ready")).toContain("MBTI");
    });

    it("detects 'Myers-Briggs' in text", () => {
      expect(scanRestrictedTerms("Based on Myers-Briggs methodology")).toContain("Myers-Briggs");
    });

    it("detects 'Myers-Briggs' case-insensitively", () => {
      expect(scanRestrictedTerms("based on myers-briggs methodology")).toContain("Myers-Briggs");
    });

    it("detects Korean term '마이어스-브릭스'", () => {
      expect(scanRestrictedTerms("마이어스-브릭스 유형 검사")).toContain("마이어스-브릭스");
    });

    it("detects Korean term '옹호자'", () => {
      expect(scanRestrictedTerms("당신은 옹호자 유형입니다")).toContain("옹호자");
    });

    it("detects '에니어그램'", () => {
      expect(scanRestrictedTerms("에니어그램 검사를 진행합니다")).toContain("에니어그램");
    });

    it("detects 'Enneagram'", () => {
      expect(scanRestrictedTerms("This is an Enneagram assessment")).toContain("Enneagram");
    });

    it("does NOT flag 4-letter personality type codes like ENFP", () => {
      expect(scanRestrictedTerms("Your type is ENFP")).toHaveLength(0);
    });

    it("does NOT flag 4-letter personality type codes like INTP", () => {
      expect(scanRestrictedTerms("INTP personality profile")).toHaveLength(0);
    });

    it("does NOT flag 4-letter personality type codes like ISTJ", () => {
      expect(scanRestrictedTerms("ISTJ results are ready")).toHaveLength(0);
    });

    it("returns an empty array for clean text", () => {
      expect(scanRestrictedTerms("Your personality assessment is complete")).toHaveLength(0);
    });

    it("returns an empty array for null input", () => {
      expect(scanRestrictedTerms(null)).toHaveLength(0);
    });

    it("returns an empty array for empty string", () => {
      expect(scanRestrictedTerms("")).toHaveLength(0);
    });

    it("detects multiple restricted terms in the same text", () => {
      const violations = scanRestrictedTerms("MBTI and Myers-Briggs are trademarks");
      expect(violations).toContain("MBTI");
      expect(violations).toContain("Myers-Briggs");
    });

    it("detects English official type names", () => {
      expect(scanRestrictedTerms("You are The Architect of your own life")).toContain("The Architect");
    });

    it("detects Korean official type names like '논리학자'", () => {
      expect(scanRestrictedTerms("논리학자 유형의 특성")).toContain("논리학자");
    });
  });

  describe("isTextClean", () => {
    it("returns true for text with no restricted terms", () => {
      expect(isTextClean("Your personality profile is ready")).toBe(true);
    });

    it("returns false for text containing MBTI", () => {
      expect(isTextClean("Your MBTI type is ENFP")).toBe(false);
    });

    it("returns false for text containing Myers-Briggs", () => {
      expect(isTextClean("Based on Myers-Briggs")).toBe(false);
    });

    it("returns false for text containing Korean restricted terms", () => {
      expect(isTextClean("마이어스-브릭스 유형")).toBe(false);
    });

    describe("with allowTrustNotice: true", () => {
      it("allows 'MBTI' in text", () => {
        expect(isTextClean("This is not affiliated with MBTI", { allowTrustNotice: true })).toBe(true);
      });

      it("allows 'Myers-Briggs' in text", () => {
        expect(isTextClean("Not affiliated with Myers-Briggs", { allowTrustNotice: true })).toBe(true);
      });

      it("still flags non-trust-notice restricted terms", () => {
        expect(isTextClean("You are The Architect type", { allowTrustNotice: true })).toBe(false);
      });

      it("still flags Korean restricted terms not in ALLOWED_IN_TRUST_NOTICE", () => {
        expect(isTextClean("마이어스-브릭스 유형", { allowTrustNotice: true })).toBe(false);
      });

      it("allows text with only MBTI and Myers-Briggs", () => {
        const text = "This service is not affiliated with MBTI or Myers-Briggs";
        expect(isTextClean(text, { allowTrustNotice: true })).toBe(true);
      });
    });

    describe("with allowTrustNotice: false (default)", () => {
      it("flags MBTI", () => {
        expect(isTextClean("Not affiliated with MBTI")).toBe(false);
      });

      it("flags Myers-Briggs", () => {
        expect(isTextClean("Not affiliated with Myers-Briggs")).toBe(false);
      });
    });
  });
});
