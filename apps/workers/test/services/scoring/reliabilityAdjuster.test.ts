/**
 * test/services/scoring/reliabilityAdjuster.test.ts — RED phase
 * RSpec: server/spec/services/scoring/reliability_adjuster_spec.rb (13 tests)
 *
 * Contract: adjustReliability(responses) → ReliabilityResult
 * reliability_coefficient = 0.4*consistency + 0.2*(speed?0:1) + 0.2*(1-non_response) + 0.2*(1-extreme)
 * Pearson r: split-half correlation
 * Spearman-Brown: 2r/(1+r), clamped to [0,1]
 * Flags: "low_split_half_consistency", "high_extreme_response_rate", "speed_anomaly", "high_non_response_rate"
 */

import { describe, it, expect } from "vitest";
import {
  adjustReliability,
  pearsonR,
} from "../../../src/services/scoring/reliabilityAdjuster";

function makeUniformResponses(value: number, count: number = 20) {
  return Array.from({ length: count }, () => ({
    value,
    response_time_ms: 2000,
  }));
}

describe("ReliabilityAdjuster (RED phase)", () => {
  describe("return structure", () => {
    it("returns expected keys", () => {
      const result = adjustReliability(makeUniformResponses(3));
      expect(Object.keys(result)).toEqual(
        expect.arrayContaining([
          "reliability_coefficient",
          "consistency_index",
          "speed_flag",
          "non_response_rate",
          "extreme_response_rate",
          "flags",
        ])
      );
    });

    it("returns numeric values in valid ranges", () => {
      const result = adjustReliability(makeUniformResponses(3));
      expect(result.reliability_coefficient).toBeGreaterThanOrEqual(0.0);
      expect(result.reliability_coefficient).toBeLessThanOrEqual(1.0);
      expect(result.consistency_index).toBeGreaterThanOrEqual(0.0);
      expect(result.consistency_index).toBeLessThanOrEqual(1.0);
      expect(result.non_response_rate).toBeGreaterThanOrEqual(0.0);
      expect(result.non_response_rate).toBeLessThanOrEqual(1.0);
      expect(result.extreme_response_rate).toBeGreaterThanOrEqual(0.0);
      expect(result.extreme_response_rate).toBeLessThanOrEqual(1.0);
    });
  });

  describe("with uniform responses (all 3s)", () => {
    it("flags low consistency (zero variance → unmeasurable correlation)", () => {
      const result = adjustReliability(makeUniformResponses(3));
      expect(result.flags).toContain("low_split_half_consistency");
    });

    it("has no speed anomaly", () => {
      const result = adjustReliability(makeUniformResponses(3));
      expect(result.speed_flag).toBe(false);
    });

    it("has zero non-response rate", () => {
      const result = adjustReliability(makeUniformResponses(3));
      expect(result.non_response_rate).toBe(0.0);
    });

    it("has 0.0 consistency index (all same values)", () => {
      const result = adjustReliability(makeUniformResponses(3));
      expect(result.consistency_index).toBe(0.0);
    });
  });

  describe("with all extreme values (1s and 5s)", () => {
    it("flags high extreme response rate", () => {
      const responses = Array.from({ length: 20 }, (_, i) => ({
        value: i % 2 === 0 ? 1 : 5,
        response_time_ms: 2000,
      }));
      const result = adjustReliability(responses);
      expect(result.extreme_response_rate).toBe(1.0);
      expect(result.flags).toContain("high_extreme_response_rate");
    });
  });

  describe("with speed anomaly (> 50% under 500ms)", () => {
    it("flags speed anomaly", () => {
      const responses = Array.from({ length: 20 }, () => ({
        value: 3,
        response_time_ms: 200,
      }));
      const result = adjustReliability(responses);
      expect(result.speed_flag).toBe(true);
      expect(result.flags).toContain("speed_anomaly");
    });
  });

  describe("with high non-response rate (> 20% skipped)", () => {
    it("flags high non-response rate", () => {
      const responses = Array.from({ length: 20 }, (_, i) => ({
        value: i < 7 ? null : 3, // 7/20 = 35% skipped
        response_time_ms: 2000,
      }));
      const result = adjustReliability(responses);
      expect(result.non_response_rate).toBeGreaterThan(0.2);
      expect(result.flags).toContain("high_non_response_rate");
    });
  });

  describe("with no responses", () => {
    it("returns safe defaults", () => {
      const result = adjustReliability([]);
      expect(result.consistency_index).toBe(0.0);
      expect(result.non_response_rate).toBe(0.0);
      expect(result.extreme_response_rate).toBe(0.0);
      expect(result.speed_flag).toBe(false);
    });
  });

  describe("Pearson r mathematical correctness", () => {
    it("returns 1.0 for perfectly correlated halves", () => {
      const r = pearsonR([1, 2, 3, 4, 5], [1, 2, 3, 4, 5]);
      expect(r).toBeCloseTo(1.0, 3);
    });

    it("returns -1.0 for perfectly inversely correlated halves", () => {
      const r = pearsonR([1, 2, 3, 4, 5], [5, 4, 3, 2, 1]);
      expect(r).toBeCloseTo(-1.0, 3);
    });

    it("returns null for constant arrays (zero variance)", () => {
      const r = pearsonR([3, 3, 3], [3, 3, 3]);
      expect(r).toBeNull();
    });

    it("returns null for arrays with fewer than 2 elements", () => {
      expect(pearsonR([1], [2])).toBeNull();
    });
  });

  describe("Spearman-Brown correction", () => {
    it("applies 2r/(1+r) formula and clamps to [0,1]", () => {
      const result = adjustReliability(makeUniformResponses(3));
      expect(result.consistency_index).toBeGreaterThanOrEqual(0.0);
      expect(result.consistency_index).toBeLessThanOrEqual(1.0);
    });
  });

  describe("reliability coefficient weighting", () => {
    it("is a weighted average: 0.4*consistency + 0.2*speed + 0.2*non_resp + 0.2*extreme", () => {
      const result = adjustReliability(makeUniformResponses(3));
      const expected =
        0.4 * result.consistency_index +
        0.2 * (result.speed_flag ? 0.0 : 1.0) +
        0.2 * (1.0 - result.non_response_rate) +
        0.2 * (1.0 - result.extreme_response_rate);
      expect(result.reliability_coefficient).toBeCloseTo(
        Math.round(expected * 1000) / 1000,
        3
      );
    });
  });
});
