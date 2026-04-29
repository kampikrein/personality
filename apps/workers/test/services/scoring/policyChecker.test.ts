/**
 * test/services/scoring/policyChecker.test.ts — RED phase
 * RSpec: server/spec/services/scoring/policy_checker_spec.rb (12 tests)
 *
 * Contract: checkPolicy(reliabilityResult) → { blocked, reasons }
 * Block conditions:
 *   - reliability_coefficient < 0.3 → "reliability_coefficient_below_threshold"
 *   - non_response_rate > 0.5 → "non_response_rate_above_threshold"
 *   - speed_flag === true → "speed_anomaly_detected"
 */

import { describe, it, expect } from "vitest";
import { checkPolicy } from "../../../src/services/scoring/policyChecker";
import type { ReliabilityResult } from "../../../src/services/scoring/reliabilityAdjuster";

function makeReliability(overrides: Partial<ReliabilityResult> = {}): ReliabilityResult {
  return {
    reliability_coefficient: 0.8,
    consistency_index: 0.75,
    speed_flag: false,
    non_response_rate: 0.05,
    extreme_response_rate: 0.2,
    flags: [],
    ...overrides,
  };
}

describe("PolicyChecker (RED phase)", () => {
  describe("when reliability coefficient is below threshold (< 0.3)", () => {
    it("blocks the assessment", () => {
      const result = checkPolicy(makeReliability({
        reliability_coefficient: 0.2,
        consistency_index: 0.3,
        flags: ["low_split_half_consistency"],
      }));
      expect(result.blocked).toBe(true);
    });

    it("includes the reliability reason", () => {
      const result = checkPolicy(makeReliability({ reliability_coefficient: 0.2 }));
      expect(result.reasons).toContain("reliability_coefficient_below_threshold");
    });
  });

  describe("when non-response rate is above threshold (> 0.5)", () => {
    it("blocks the assessment", () => {
      const result = checkPolicy(makeReliability({
        non_response_rate: 0.6,
        flags: ["high_non_response_rate"],
      }));
      expect(result.blocked).toBe(true);
    });

    it("includes the non-response reason", () => {
      const result = checkPolicy(makeReliability({ non_response_rate: 0.6 }));
      expect(result.reasons).toContain("non_response_rate_above_threshold");
    });
  });

  describe("when speed flag is true", () => {
    it("blocks the assessment", () => {
      const result = checkPolicy(makeReliability({ speed_flag: true }));
      expect(result.blocked).toBe(true);
    });

    it("includes the speed anomaly reason", () => {
      const result = checkPolicy(makeReliability({ speed_flag: true }));
      expect(result.reasons).toContain("speed_anomaly_detected");
    });
  });

  describe("when all indicators are within acceptable range", () => {
    it("does not block the assessment", () => {
      const result = checkPolicy(makeReliability());
      expect(result.blocked).toBe(false);
    });

    it("returns no reasons", () => {
      const result = checkPolicy(makeReliability());
      expect(result.reasons).toHaveLength(0);
    });
  });

  describe("when multiple blocking conditions are present", () => {
    it("blocks the assessment", () => {
      const result = checkPolicy(makeReliability({
        reliability_coefficient: 0.1,
        speed_flag: true,
        non_response_rate: 0.8,
      }));
      expect(result.blocked).toBe(true);
    });

    it("includes all applicable reasons", () => {
      const result = checkPolicy(makeReliability({
        reliability_coefficient: 0.1,
        speed_flag: true,
        non_response_rate: 0.8,
      }));
      expect(result.reasons).toEqual(
        expect.arrayContaining([
          "reliability_coefficient_below_threshold",
          "non_response_rate_above_threshold",
          "speed_anomaly_detected",
        ])
      );
    });
  });

  describe("at boundary: reliability coefficient exactly 0.3", () => {
    it("does not block (threshold is strictly less than)", () => {
      const result = checkPolicy(makeReliability({ reliability_coefficient: 0.3 }));
      expect(result.blocked).toBe(false);
    });
  });

  describe("at boundary: non-response rate exactly 0.5", () => {
    it("does not block (threshold is strictly greater than)", () => {
      const result = checkPolicy(makeReliability({ non_response_rate: 0.5 }));
      expect(result.blocked).toBe(false);
    });
  });

  describe("at boundary: reliability coefficient just below threshold (0.299)", () => {
    it("blocks the assessment", () => {
      const result = checkPolicy(makeReliability({ reliability_coefficient: 0.299 }));
      expect(result.blocked).toBe(true);
    });
  });

  describe("at boundary: non-response rate just above threshold (0.501)", () => {
    it("blocks the assessment", () => {
      const result = checkPolicy(makeReliability({ non_response_rate: 0.501 }));
      expect(result.blocked).toBe(true);
    });
  });

  describe("return structure", () => {
    it("returns a hash with blocked and reasons keys", () => {
      const result = checkPolicy(makeReliability());
      expect(result).toHaveProperty("blocked");
      expect(result).toHaveProperty("reasons");
    });

    it("returns reasons as an array", () => {
      const result = checkPolicy(makeReliability());
      expect(Array.isArray(result.reasons)).toBe(true);
    });
  });
});
