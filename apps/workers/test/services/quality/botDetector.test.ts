/**
 * test/services/quality/botDetector.test.ts — RED phase
 * RSpec: server/spec/services/quality/bot_detector_spec.rb (6 tests)
 *
 * Contract: detectBot(responses) → { bot_suspected, patterns, confidence }
 * Patterns:
 *   - uniform: all responses have the same value
 *   - sequential: values repeat in a cycle [1,2,3,4,5,1,2,3,4,5,...]
 *   - zero_variance_timing: all response_time_ms are identical
 * confidence = proportion of fired heuristics (0.0 to 1.0, rounded to 2 decimal places)
 * bot_suspected = confidence > 0
 */

import { describe, it, expect } from "vitest";
import { detectBot } from "../../../src/services/quality/botDetector";

describe("BotDetector (RED phase)", () => {
  describe("with uniform responses (all same value)", () => {
    it("detects uniform pattern", () => {
      const responses = Array.from({ length: 20 }, () => ({
        value: 3,
        response_time_ms: Math.floor(Math.random() * 4000) + 1000,
      }));
      const result = detectBot(responses);
      expect(result.bot_suspected).toBe(true);
      expect(result.patterns).toContain("uniform");
    });
  });

  describe("with sequential pattern (repeating cycle)", () => {
    it("detects sequential pattern", () => {
      const cycle = [1, 2, 3, 4, 5];
      const responses = Array.from({ length: 20 }, (_, i) => ({
        value: cycle[i % 5],
        response_time_ms: Math.floor(Math.random() * 4000) + 1000,
      }));
      const result = detectBot(responses);
      expect(result.bot_suspected).toBe(true);
      expect(result.patterns).toContain("sequential");
    });
  });

  describe("with zero variance timing", () => {
    it("detects zero variance timing", () => {
      const responses = Array.from({ length: 20 }, (_, i) => ({
        value: (i % 3) + 1, // varied values
        response_time_ms: 1500, // identical timing
      }));
      const result = detectBot(responses);
      expect(result.bot_suspected).toBe(true);
      expect(result.patterns).toContain("zero_variance_timing");
    });
  });

  describe("with fewer than 2 responses", () => {
    it("returns safe default (no data)", () => {
      const result = detectBot([]);
      expect(result.bot_suspected).toBe(false);
      expect(result.patterns).toHaveLength(0);
      expect(result.confidence).toBe(0.0);
    });

    it("returns safe default for 1 response", () => {
      const result = detectBot([{ value: 3, response_time_ms: 2000 }]);
      expect(result.bot_suspected).toBe(false);
      expect(result.confidence).toBe(0.0);
    });
  });

  describe("confidence calculation", () => {
    it("is the proportion of fired heuristics (all-3s with identical timing)", () => {
      const responses = Array.from({ length: 20 }, () => ({
        value: 3,
        response_time_ms: 1000,
      }));
      const result = detectBot(responses);
      // uniform + zero_variance_timing fires (2/3 = 0.67)
      // sequential does NOT fire for all-3s (no cycle pattern with >1 unique value)
      expect(result.confidence).toBe(Number((2 / 3).toFixed(2)));
    });
  });
});
