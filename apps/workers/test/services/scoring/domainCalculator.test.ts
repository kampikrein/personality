/**
 * test/services/scoring/domainCalculator.test.ts — RED phase
 * RSpec: server/spec/services/scoring/domain_calculator_spec.rb (9 tests)
 *
 * Contract: calculateDomainScores(assessment) → { energy, decision_making, relationship, recovery }
 * - positive polarity: sum values directly
 * - negative polarity: reverse-score (6 - value)
 * - skipped (nil value): excluded from sum
 * - empty assessment: 0 for all domains
 */

import { describe, it, expect } from "vitest";
import { calculateDomainScores } from "../../../src/services/scoring/domainCalculator";

const DOMAINS = ["energy", "decision_making", "relationship", "recovery"] as const;

function makeAssessment(responses: Array<{
  domain: string;
  value: number | null;
  polarity: string;
}>) {
  return {
    id: 1,
    responses: responses.map((r) => ({
      value: r.value,
      polarity: r.polarity,
      domain: r.domain,
    })),
  };
}

describe("DomainCalculator (RED phase)", () => {
  describe("with positive polarity questions", () => {
    it("sums values directly for positive polarity", () => {
      const responses = Array.from({ length: 5 }, () => ({
        domain: "energy",
        value: 4,
        polarity: "positive",
      }));
      const result = calculateDomainScores(makeAssessment(responses));
      // 5 questions * value 4 = 20
      expect(result["energy"]).toBe(20);
    });
  });

  describe("with negative polarity questions", () => {
    it("reverse-scores using (6 - value)", () => {
      const responses = Array.from({ length: 5 }, () => ({
        domain: "decision_making",
        value: 2,
        polarity: "negative",
      }));
      const result = calculateDomainScores(makeAssessment(responses));
      // 5 questions, each value=2, reversed => 6-2=4, total = 5*4 = 20
      expect(result["decision_making"]).toBe(20);
    });
  });

  describe("with a mix of positive and negative polarity questions", () => {
    it("sums positive directly and reverses negative", () => {
      const responses = [
        ...Array.from({ length: 3 }, () => ({ domain: "relationship", value: 3, polarity: "positive" })),
        ...Array.from({ length: 2 }, () => ({ domain: "relationship", value: 3, polarity: "negative" })),
      ];
      const result = calculateDomainScores(makeAssessment(responses));
      // Positive: 3 * 3 = 9; Negative: 2 * (6-3) = 6; Total = 15
      expect(result["relationship"]).toBe(15);
    });
  });

  describe("with skipped responses (nil value)", () => {
    it("excludes skipped responses from the sum", () => {
      const responses = [
        ...Array.from({ length: 3 }, () => ({ domain: "recovery", value: 5, polarity: "positive" })),
        ...Array.from({ length: 2 }, () => ({ domain: "recovery", value: null, polarity: "positive" })),
      ];
      const result = calculateDomainScores(makeAssessment(responses));
      // 3 answered * 5 = 15 (nil excluded)
      expect(result["recovery"]).toBe(15);
    });
  });

  describe("with an empty assessment (no responses)", () => {
    it("returns 0 for all domains", () => {
      const result = calculateDomainScores(makeAssessment([]));
      expect(result).toEqual({
        energy: 0,
        decision_making: 0,
        relationship: 0,
        recovery: 0,
      });
    });
  });

  describe("return structure", () => {
    it("returns a hash with all four domain keys", () => {
      const result = calculateDomainScores(makeAssessment([]));
      expect(Object.keys(result)).toEqual(
        expect.arrayContaining(["energy", "decision_making", "relationship", "recovery"])
      );
    });
  });

  describe("with extreme values", () => {
    it("sums all 1s correctly (positive polarity)", () => {
      const responses = Array.from({ length: 5 }, () => ({
        domain: "energy",
        value: 1,
        polarity: "positive",
      }));
      const result = calculateDomainScores(makeAssessment(responses));
      expect(result["energy"]).toBe(5);
    });

    it("sums all 5s correctly (positive polarity)", () => {
      const responses = Array.from({ length: 5 }, () => ({
        domain: "energy",
        value: 5,
        polarity: "positive",
      }));
      const result = calculateDomainScores(makeAssessment(responses));
      expect(result["energy"]).toBe(25);
    });

    it("reverse-scores to maximum (6-1=5) for negative polarity value=1", () => {
      const responses = Array.from({ length: 5 }, () => ({
        domain: "energy",
        value: 1,
        polarity: "negative",
      }));
      const result = calculateDomainScores(makeAssessment(responses));
      // 5 * (6-1) = 25
      expect(result["energy"]).toBe(25);
    });

    it("reverse-scores to minimum (6-5=1) for negative polarity value=5", () => {
      const responses = Array.from({ length: 5 }, () => ({
        domain: "energy",
        value: 5,
        polarity: "negative",
      }));
      const result = calculateDomainScores(makeAssessment(responses));
      // 5 * (6-5) = 5
      expect(result["energy"]).toBe(5);
    });
  });
});
