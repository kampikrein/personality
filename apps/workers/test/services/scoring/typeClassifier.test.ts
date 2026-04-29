/**
 * test/services/scoring/typeClassifier.test.ts — RED phase
 * RSpec: server/spec/services/scoring/type_classifier_spec.rb (18 tests)
 *
 * Contract: classifyType(normalizedScores) → { type_code, axes }
 * Axis mapping (score >= 50 → high letter):
 *   energy:         >= 50 → E, < 50 → I
 *   decision_making: >= 50 → N, < 50 → S
 *   relationship:   >= 50 → F, < 50 → T
 *   recovery:       >= 50 → P, < 50 → J
 *   nil → defaults to low letter
 */

import { describe, it, expect } from "vitest";
import { classifyType } from "../../../src/services/scoring/typeClassifier";

describe("TypeClassifier (RED phase)", () => {
  describe("when all scores are high (>= 50)", () => {
    const scores = { energy: 75.0, decision_making: 80.0, relationship: 60.0, recovery: 90.0 };

    it("returns ENFP", () => {
      expect(classifyType(scores).type_code).toBe("ENFP");
    });

    it("assigns the high letter to each axis", () => {
      const { axes } = classifyType(scores);
      expect(axes.energy.letter).toBe("E");
      expect(axes.decision_making.letter).toBe("N");
      expect(axes.relationship.letter).toBe("F");
      expect(axes.recovery.letter).toBe("P");
    });

    it("preserves the original scores on each axis", () => {
      const { axes } = classifyType(scores);
      expect(axes.energy.score).toBe(75.0);
      expect(axes.decision_making.score).toBe(80.0);
      expect(axes.relationship.score).toBe(60.0);
      expect(axes.recovery.score).toBe(90.0);
    });
  });

  describe("when all scores are low (< 50)", () => {
    const scores = { energy: 10.0, decision_making: 20.0, relationship: 30.0, recovery: 40.0 };

    it("returns ISTJ", () => {
      expect(classifyType(scores).type_code).toBe("ISTJ");
    });

    it("assigns the low letter to each axis", () => {
      const { axes } = classifyType(scores);
      expect(axes.energy.letter).toBe("I");
      expect(axes.decision_making.letter).toBe("S");
      expect(axes.relationship.letter).toBe("T");
      expect(axes.recovery.letter).toBe("J");
    });
  });

  describe("boundary value: score exactly 50 on each axis", () => {
    const scores = { energy: 50.0, decision_making: 50.0, relationship: 50.0, recovery: 50.0 };

    it("maps to the high letter (>= threshold)", () => {
      expect(classifyType(scores).type_code).toBe("ENFP");
    });

    it("assigns E for energy at 50", () => {
      expect(classifyType(scores).axes.energy.letter).toBe("E");
    });

    it("assigns N for decision_making at 50", () => {
      expect(classifyType(scores).axes.decision_making.letter).toBe("N");
    });

    it("assigns F for relationship at 50", () => {
      expect(classifyType(scores).axes.relationship.letter).toBe("F");
    });

    it("assigns P for recovery at 50", () => {
      expect(classifyType(scores).axes.recovery.letter).toBe("P");
    });
  });

  describe("boundary value: score 49.9 (just below threshold)", () => {
    it("maps to the low letter (< threshold)", () => {
      const scores = { energy: 49.9, decision_making: 49.9, relationship: 49.9, recovery: 49.9 };
      expect(classifyType(scores).type_code).toBe("ISTJ");
    });
  });

  describe("boundary value: score 50.1 (just above threshold)", () => {
    it("maps to the high letter (>= threshold)", () => {
      const scores = { energy: 50.1, decision_making: 50.1, relationship: 50.1, recovery: 50.1 };
      expect(classifyType(scores).type_code).toBe("ENFP");
    });
  });

  describe("mixed scores across domains", () => {
    const scores = { energy: 30.0, decision_making: 70.0, relationship: 25.0, recovery: 80.0 };

    it("returns INTP", () => {
      expect(classifyType(scores).type_code).toBe("INTP");
    });

    it("assigns I for low energy", () => {
      expect(classifyType(scores).axes.energy.letter).toBe("I");
    });

    it("assigns N for high decision_making", () => {
      expect(classifyType(scores).axes.decision_making.letter).toBe("N");
    });

    it("assigns T for low relationship", () => {
      expect(classifyType(scores).axes.relationship.letter).toBe("T");
    });

    it("assigns P for high recovery", () => {
      expect(classifyType(scores).axes.recovery.letter).toBe("P");
    });
  });

  describe("when all scores are nil", () => {
    const scores = { energy: null, decision_making: null, relationship: null, recovery: null };

    it("defaults to the low letter for each axis → ISTJ", () => {
      expect(classifyType(scores).type_code).toBe("ISTJ");
    });

    it("stores null as the score", () => {
      const { axes } = classifyType(scores);
      Object.values(axes).forEach((axis) => {
        expect(axis.score).toBeNull();
      });
    });
  });

  describe("when a single domain score is nil", () => {
    it("defaults that domain to the low letter while classifying others normally", () => {
      const scores = { energy: 75.0, decision_making: null, relationship: 60.0, recovery: 90.0 };
      const result = classifyType(scores);
      expect(result.type_code).toBe("ESFP");
      expect(result.axes.energy.letter).toBe("E");
      expect(result.axes.decision_making.letter).toBe("S");
      expect(result.axes.relationship.letter).toBe("F");
      expect(result.axes.recovery.letter).toBe("P");
    });
  });

  describe("domain to letter pair mapping", () => {
    it("maps energy to E/I", () => {
      const high = classifyType({ energy: 60.0, decision_making: 50.0, relationship: 50.0, recovery: 50.0 });
      const low  = classifyType({ energy: 40.0, decision_making: 50.0, relationship: 50.0, recovery: 50.0 });
      expect(high.axes.energy.letter).toBe("E");
      expect(low.axes.energy.letter).toBe("I");
    });

    it("maps decision_making to N/S", () => {
      const high = classifyType({ energy: 50.0, decision_making: 60.0, relationship: 50.0, recovery: 50.0 });
      const low  = classifyType({ energy: 50.0, decision_making: 40.0, relationship: 50.0, recovery: 50.0 });
      expect(high.axes.decision_making.letter).toBe("N");
      expect(low.axes.decision_making.letter).toBe("S");
    });

    it("maps relationship to F/T", () => {
      const high = classifyType({ energy: 50.0, decision_making: 50.0, relationship: 60.0, recovery: 50.0 });
      const low  = classifyType({ energy: 50.0, decision_making: 50.0, relationship: 40.0, recovery: 50.0 });
      expect(high.axes.relationship.letter).toBe("F");
      expect(low.axes.relationship.letter).toBe("T");
    });

    it("maps recovery to P/J", () => {
      const high = classifyType({ energy: 50.0, decision_making: 50.0, relationship: 50.0, recovery: 60.0 });
      const low  = classifyType({ energy: 50.0, decision_making: 50.0, relationship: 50.0, recovery: 40.0 });
      expect(high.axes.recovery.letter).toBe("P");
      expect(low.axes.recovery.letter).toBe("J");
    });
  });

  describe("return structure", () => {
    const scores = { energy: 72.0, decision_making: 58.5, relationship: 65.0, recovery: 80.0 };

    it("returns a hash with type_code and axes keys", () => {
      const result = classifyType(scores);
      expect(result).toHaveProperty("type_code");
      expect(result).toHaveProperty("axes");
    });

    it("returns axes as a hash of domain symbols", () => {
      const { axes } = classifyType(scores);
      expect(Object.keys(axes)).toEqual(
        expect.arrayContaining(["energy", "decision_making", "relationship", "recovery"])
      );
    });

    it("returns each axis with letter and score keys", () => {
      const { axes } = classifyType(scores);
      Object.values(axes).forEach((axis) => {
        expect(axis).toHaveProperty("letter");
        expect(axis).toHaveProperty("score");
      });
    });
  });
});
