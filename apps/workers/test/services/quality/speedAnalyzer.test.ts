/**
 * test/services/quality/speedAnalyzer.test.ts — RED phase
 * RSpec: server/spec/services/quality/speed_analyzer_spec.rb (6 tests)
 *
 * Contract: analyzeSpeed(responses, assessmentDurationMs?) → SpeedAnalysisResult
 * Flags:
 *   - fast_individual: any response < 500ms
 *   - high_fast_rate: > 50% of responses < 1000ms → anomaly=true
 *   - fast_total_time: assessmentDurationMs < 60_000ms (60s)
 */

import { describe, it, expect } from "vitest";
import { analyzeSpeed } from "../../../src/services/quality/speedAnalyzer";

describe("SpeedAnalyzer (RED phase)", () => {
  describe("with no timing data", () => {
    it("returns no-data result", () => {
      const result = analyzeSpeed([]);
      expect(result.anomaly).toBe(false);
      expect(result.flags).toHaveLength(0);
      expect(result.median_time_ms).toBeNull();
      expect(result.fast_response_rate).toBe(0.0);
    });
  });

  describe("with normal response times", () => {
    it("reports no anomaly", () => {
      const responses = Array.from({ length: 20 }, (_, i) => ({
        response_time_ms: 2000 + i * 100,
      }));
      // assessmentDurationMs > 60s
      const result = analyzeSpeed(responses, 300_000);
      expect(result.anomaly).toBe(false);
      expect(result.flags).toHaveLength(0);
    });

    it("calculates median", () => {
      const responses = Array.from({ length: 20 }, (_, i) => ({
        response_time_ms: 2000 + i * 100,
      }));
      const result = analyzeSpeed(responses, 300_000);
      expect(result.median_time_ms).toBeGreaterThan(0);
    });
  });

  describe("with individual fast responses (< 500ms)", () => {
    it("flags fast_individual", () => {
      const responses = [
        { response_time_ms: 200 }, // fast
        ...Array.from({ length: 19 }, () => ({ response_time_ms: 3000 })),
      ];
      const result = analyzeSpeed(responses, 300_000);
      expect(result.flags).toContain("fast_individual");
    });
  });

  describe("with high fast rate (> 50% under 1000ms)", () => {
    it("flags both fast_individual and high_fast_rate", () => {
      const responses = Array.from({ length: 20 }, () => ({
        response_time_ms: 400,
      }));
      const result = analyzeSpeed(responses, 300_000);
      expect(result.anomaly).toBe(true);
      expect(result.flags).toContain("fast_individual");
      expect(result.flags).toContain("high_fast_rate");
    });
  });

  describe("with total time too short", () => {
    it("flags fast_total_time", () => {
      const responses = Array.from({ length: 20 }, () => ({
        response_time_ms: 2000,
      }));
      // assessmentDurationMs = 30s (< 60s)
      const result = analyzeSpeed(responses, 30_000);
      expect(result.flags).toContain("fast_total_time");
    });
  });
});
