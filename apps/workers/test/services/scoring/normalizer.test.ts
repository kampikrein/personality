/**
 * test/services/scoring/normalizer.test.ts — RED phase
 * RSpec: server/spec/services/scoring/normalizer_spec.rb (8 tests)
 *
 * Contract: normalizeScores(rawScores, responses) → { domain: 0-100 | null }
 * Formula: (raw - effective_min) / (effective_max - effective_min) * 100
 * effective_min = answeredCount * 1, effective_max = answeredCount * 5
 * Rounds to 1 decimal place.
 * Returns null if answeredCount = 0.
 */

import { describe, it, expect } from "vitest";
import { normalizeScores } from "../../../src/services/scoring/normalizer";

function makeResponses(domain: string, value: number, count: number) {
  return Array.from({ length: count }, () => ({ domain, value }));
}

describe("Normalizer (RED phase)", () => {
  describe("when all answers are 1 (minimum)", () => {
    it("normalizes to 0.0", () => {
      const responses = makeResponses("energy", 1, 5);
      const result = normalizeScores({ energy: 5 }, responses);
      // (5-5)/(25-5)*100 = 0.0
      expect(result["energy"]).toBe(0.0);
    });
  });

  describe("when all answers are 5 (maximum)", () => {
    it("normalizes to 100.0", () => {
      const responses = makeResponses("energy", 5, 5);
      const result = normalizeScores({ energy: 25 }, responses);
      expect(result["energy"]).toBe(100.0);
    });
  });

  describe("when all answers are 3 (midpoint)", () => {
    it("normalizes to 50.0", () => {
      const responses = makeResponses("energy", 3, 5);
      const result = normalizeScores({ energy: 15 }, responses);
      expect(result["energy"]).toBe(50.0);
    });
  });

  describe("when only some questions are answered (partial answers)", () => {
    it("adjusts the normalization range proportionally", () => {
      const responses = makeResponses("energy", 3, 3);
      const result = normalizeScores({ energy: 9 }, responses);
      // 3 answered: effective_min=3, effective_max=15
      // (9-3)/(15-3)*100 = 50.0
      expect(result["energy"]).toBe(50.0);
    });
  });

  describe("when no questions are answered for a domain", () => {
    it("returns null for that domain", () => {
      const result = normalizeScores({ energy: 0 }, []);
      expect(result["energy"]).toBeNull();
    });
  });

  describe("with multiple domains", () => {
    it("normalizes each domain independently", () => {
      const responses = [
        ...makeResponses("energy", 1, 5),
        ...makeResponses("decision_making", 5, 5),
        ...makeResponses("relationship", 3, 5),
        ...makeResponses("recovery", 4, 5),
      ];
      const result = normalizeScores(
        { energy: 5, decision_making: 25, relationship: 15, recovery: 20 },
        responses
      );
      expect(result["energy"]).toBe(0.0);
      expect(result["decision_making"]).toBe(100.0);
      expect(result["relationship"]).toBe(50.0);
      // (20-5)/(25-5)*100 = 75.0
      expect(result["recovery"]).toBe(75.0);
    });
  });

  describe("with partial answers at extreme values", () => {
    it("normalizes using the proportional range", () => {
      const responses = makeResponses("energy", 5, 2);
      const result = normalizeScores({ energy: 10 }, responses);
      // 2 answered: effective_min=2, effective_max=10
      // (10-2)/(10-2)*100 = 100.0
      expect(result["energy"]).toBe(100.0);
    });
  });

  describe("with a single answered question", () => {
    it("normalizes with a single-item range", () => {
      const responses = makeResponses("energy", 3, 1);
      const result = normalizeScores({ energy: 3 }, responses);
      // 1 answered: effective_min=1, effective_max=5
      // (3-1)/(5-1)*100 = 50.0
      expect(result["energy"]).toBe(50.0);
    });
  });

  describe("rounding", () => {
    it("rounds to one decimal place", () => {
      const responses = [
        { domain: "energy", value: 2 },
        { domain: "energy", value: 2 },
        { domain: "energy", value: 3 },
      ];
      const result = normalizeScores({ energy: 7 }, responses);
      // 3 answered: effective_min=3, effective_max=15
      // (7-3)/(15-3)*100 = 33.333... => 33.3
      expect(result["energy"]).toBe(33.3);
    });
  });
});
