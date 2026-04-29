/**
 * test/services/compliance/textPolicyFilter.test.ts — RED phase
 * RSpec: server/spec/services/compliance/text_policy_filter_spec.rb (20 tests)
 *
 * Contract: filterText(text, context?) → { clean, violations, filtered_text }
 * Contexts: 'content' (default) | 'trust_notice'
 * Replacement: restricted terms → "[REMOVED]"
 * Default context: 'content'
 * Invalid context → throws ArgumentError
 */

import { describe, it, expect } from "vitest";
import { filterText } from "../../../src/services/compliance/textPolicyFilter";

describe("TextPolicyFilter (RED phase)", () => {
  describe("with :content context", () => {
    it("blocks MBTI in content", () => {
      const result = filterText("Your MBTI type is ENFP", "content");
      expect(result.clean).toBe(false);
      expect(result.violations).toContain("MBTI");
    });

    it("blocks Myers-Briggs in content", () => {
      const result = filterText("Based on Myers-Briggs methodology", "content");
      expect(result.clean).toBe(false);
      expect(result.violations).toContain("Myers-Briggs");
    });

    it("blocks Korean restricted terms in content", () => {
      const result = filterText("마이어스-브릭스 유형 검사", "content");
      expect(result.clean).toBe(false);
      expect(result.violations).toContain("마이어스-브릭스");
    });

    it("blocks official type names in content", () => {
      const result = filterText("You are The Architect", "content");
      expect(result.clean).toBe(false);
      expect(result.violations).toContain("The Architect");
    });

    it("replaces restricted terms with [REMOVED] in filtered text", () => {
      const result = filterText("Your MBTI type is ENFP", "content");
      expect(result.filtered_text).toBe("Your [REMOVED] type is ENFP");
      expect(result.filtered_text).not.toContain("MBTI");
    });

    it("replaces multiple restricted terms", () => {
      const result = filterText("MBTI and Myers-Briggs are trademarks", "content");
      expect(result.filtered_text).toBe("[REMOVED] and [REMOVED] are trademarks");
      expect(result.violations).toEqual(
        expect.arrayContaining(["MBTI", "Myers-Briggs"])
      );
    });

    it("returns clean result for text without restricted terms", () => {
      const result = filterText("Your personality type is ENFP", "content");
      expect(result.clean).toBe(true);
      expect(result.violations).toHaveLength(0);
      expect(result.filtered_text).toBe("Your personality type is ENFP");
    });

    it("does not alter text when no violations are found", () => {
      const original = "This is a safe personality assessment result";
      const result = filterText(original, "content");
      expect(result.filtered_text).toBe(original);
    });
  });

  describe("with :trust_notice context", () => {
    it("allows MBTI in trust notice", () => {
      const result = filterText("This service is not affiliated with MBTI", "trust_notice");
      expect(result.clean).toBe(true);
      expect(result.violations).toHaveLength(0);
    });

    it("allows Myers-Briggs in trust notice", () => {
      const result = filterText("Not affiliated with Myers-Briggs Type Indicator", "trust_notice");
      // "Myers-Briggs Type Indicator" is a separate restricted term not in ALLOWED_IN_TRUST_NOTICE
      expect(result.violations).toContain("Myers-Briggs Type Indicator");
    });

    it("allows both MBTI and Myers-Briggs together in trust notice", () => {
      const text = "This service is not affiliated with MBTI or Myers-Briggs";
      const result = filterText(text, "trust_notice");
      expect(result.clean).toBe(true);
      expect(result.violations).toHaveLength(0);
    });

    it("still blocks non-trust-notice restricted terms", () => {
      const result = filterText("You are The Architect according to MBTI", "trust_notice");
      expect(result.clean).toBe(false);
      expect(result.violations).toContain("The Architect");
      expect(result.violations).not.toContain("MBTI");
    });

    it("still blocks Korean restricted terms not in allowed list", () => {
      const result = filterText("옹호자 유형 - MBTI disclaimer", "trust_notice");
      expect(result.clean).toBe(false);
      expect(result.violations).toContain("옹호자");
    });

    it("replaces only non-allowed terms in filtered text", () => {
      const result = filterText("옹호자 MBTI disclaimer", "trust_notice");
      expect(result.filtered_text).toContain("MBTI");
      expect(result.filtered_text).toContain("[REMOVED]");
      expect(result.filtered_text).not.toContain("옹호자");
    });
  });

  describe("with invalid context", () => {
    it("raises ArgumentError", () => {
      expect(() => filterText("some text", "invalid" as any)).toThrow(/Unknown context/);
    });
  });

  describe("default context", () => {
    it("defaults to :content when no context is provided", () => {
      const result = filterText("Your MBTI type");
      expect(result.clean).toBe(false);
      expect(result.violations).toContain("MBTI");
    });
  });

  describe("return structure", () => {
    it("returns a hash with clean, violations, and filtered_text keys", () => {
      const result = filterText("test text", "content");
      expect(result).toHaveProperty("clean");
      expect(result).toHaveProperty("violations");
      expect(result).toHaveProperty("filtered_text");
    });

    it("returns violations as an array", () => {
      const result = filterText("test text", "content");
      expect(Array.isArray(result.violations)).toBe(true);
    });

    it("returns filtered_text as a string", () => {
      const result = filterText("test text", "content");
      expect(typeof result.filtered_text).toBe("string");
    });

    it("returns clean as a boolean", () => {
      const result = filterText("test text", "content");
      expect(typeof result.clean).toBe("boolean");
    });
  });

  describe("case insensitivity in content replacement", () => {
    it("replaces case-variant matches", () => {
      const result = filterText("mbti is a trademark", "content");
      expect(result.filtered_text).toBe("[REMOVED] is a trademark");
      expect(result.violations).toContain("MBTI");
    });
  });

  describe("with nil text", () => {
    it("handles null by converting to empty string", () => {
      const result = filterText(null, "content");
      expect(result.clean).toBe(true);
      expect(result.violations).toHaveLength(0);
      expect(result.filtered_text).toBe("");
    });
  });
});
