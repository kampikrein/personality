/**
 * test/services/insights/explanationBuilder.test.ts — RED phase
 * Rails: no RSpec (explanation_builder.rb — spec 없음)
 * Contract derived from context_engine.rb enrich_explanation logic.
 *
 * Contract: buildExplanation(baseExplanation, suggestions) → string
 * - With 0 or 1 suggestions: returns baseExplanation as-is
 * - With multiple suggestions: appends "Suggestions cover: <truncated>" suffix
 * - Always returns a string
 */

import { describe, it, expect } from "vitest";
import { buildExplanation } from "../../../src/services/insights/explanationBuilder";

describe("ExplanationBuilder (RED phase)", () => {
  it("returns baseExplanation unchanged when suggestions has 0 items", () => {
    const base = "You tend to collaborate effectively.";
    expect(buildExplanation(base, [])).toBe(base);
  });

  it("returns baseExplanation unchanged when suggestions has 1 item", () => {
    const base = "You tend to collaborate effectively.";
    expect(buildExplanation(base, ["Share your thoughts openly."])).toBe(base);
  });

  it("appends suggestions cover suffix when 2+ suggestions", () => {
    const base = "You work well in teams.";
    const suggestions = ["Listen actively.", "Ask clarifying questions.", "Share your perspective."];
    const result = buildExplanation(base, suggestions);
    expect(result).toContain(base);
    expect(result).toMatch(/Suggestions cover:/);
  });

  it("includes truncated suggestion text in suffix", () => {
    const base = "Base explanation.";
    const suggestions = ["Suggestion A", "Suggestion B"];
    const result = buildExplanation(base, suggestions);
    expect(result).toContain("Suggestion A");
  });

  it("always returns a string", () => {
    expect(typeof buildExplanation("", [])).toBe("string");
    expect(typeof buildExplanation("", ["a", "b"])).toBe("string");
  });
});
