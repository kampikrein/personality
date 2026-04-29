/**
 * test/services/insights/insightModules.test.ts — RED phase
 * Rails: no per-module RSpec (modules tested via context_engine_spec.rb)
 * Contract derived from Rails module pattern.
 *
 * Contract: generate*Insight(profile) → { suggestions: string[], explanation: string }
 * Pure compute functions — no DB access.
 * profile input: { typeCode, scoreVector, strengths, cautionPatterns, ... }
 */

import { describe, it, expect } from "vitest";
import { generateCareerInsight } from "../../../src/services/insights/careerModule";
import { generateLearningInsight } from "../../../src/services/insights/learningModule";
import { generateCollaborationInsight } from "../../../src/services/insights/collaborationModule";
import { generateConflictInsight } from "../../../src/services/insights/conflictModule";
import { generateRecoveryInsight } from "../../../src/services/insights/recoveryModule";

const FIXTURE_PROFILE = {
  typeCode: "ENFP",
  scoreVector: { energy: 75.0, decision_making: 80.0, relationship: 60.0, recovery: 70.0 },
  strengths: ["Creative thinking", "Empathy", "Enthusiasm"],
  cautionPatterns: ["May lose focus", "Overcommits"],
  collaborationStyle: "Works well in teams",
  conflictStyle: "Seeks compromise",
  learningStyle: "Hands-on learner",
  careerHints: "Explore creative fields",
  recoveryStyle: "Needs variety",
};

describe("Insight Modules — pure compute (RED phase)", () => {
  describe("CareerModule", () => {
    it("returns suggestions array", () => {
      const result = generateCareerInsight(FIXTURE_PROFILE);
      expect(Array.isArray(result.suggestions)).toBe(true);
    });

    it("returns explanation string", () => {
      const result = generateCareerInsight(FIXTURE_PROFILE);
      expect(typeof result.explanation).toBe("string");
    });

    it("suggestions are non-empty (career context uses careerHints)", () => {
      const result = generateCareerInsight(FIXTURE_PROFILE);
      expect(result.suggestions.length).toBeGreaterThan(0);
    });
  });

  describe("LearningModule", () => {
    it("returns suggestions array", () => {
      const result = generateLearningInsight(FIXTURE_PROFILE);
      expect(Array.isArray(result.suggestions)).toBe(true);
    });

    it("returns explanation string", () => {
      const result = generateLearningInsight(FIXTURE_PROFILE);
      expect(typeof result.explanation).toBe("string");
    });
  });

  describe("CollaborationModule", () => {
    it("returns suggestions array", () => {
      const result = generateCollaborationInsight(FIXTURE_PROFILE);
      expect(Array.isArray(result.suggestions)).toBe(true);
    });

    it("returns explanation string", () => {
      const result = generateCollaborationInsight(FIXTURE_PROFILE);
      expect(typeof result.explanation).toBe("string");
    });
  });

  describe("ConflictModule", () => {
    it("returns suggestions array", () => {
      const result = generateConflictInsight(FIXTURE_PROFILE);
      expect(Array.isArray(result.suggestions)).toBe(true);
    });

    it("returns explanation string", () => {
      const result = generateConflictInsight(FIXTURE_PROFILE);
      expect(typeof result.explanation).toBe("string");
    });
  });

  describe("RecoveryModule", () => {
    it("returns suggestions array", () => {
      const result = generateRecoveryInsight(FIXTURE_PROFILE);
      expect(Array.isArray(result.suggestions)).toBe(true);
    });

    it("returns explanation string", () => {
      const result = generateRecoveryInsight(FIXTURE_PROFILE);
      expect(typeof result.explanation).toBe("string");
    });
  });

  describe("All modules return consistent structure", () => {
    const moduleResults = [
      { name: "career", fn: () => generateCareerInsight(FIXTURE_PROFILE) },
      { name: "learning", fn: () => generateLearningInsight(FIXTURE_PROFILE) },
      { name: "collaboration", fn: () => generateCollaborationInsight(FIXTURE_PROFILE) },
      { name: "conflict", fn: () => generateConflictInsight(FIXTURE_PROFILE) },
      { name: "recovery", fn: () => generateRecoveryInsight(FIXTURE_PROFILE) },
    ];

    for (const { name, fn } of moduleResults) {
      it(`${name} module returns { suggestions, explanation } keys`, () => {
        const result = fn();
        expect(result).toHaveProperty("suggestions");
        expect(result).toHaveProperty("explanation");
      });
    }
  });
});
