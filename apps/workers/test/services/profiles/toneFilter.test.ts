/**
 * test/services/profiles/toneFilter.test.ts — RED phase
 * RSpec: server/spec/services/profiles/tone_filter_spec.rb (9 tests)
 *
 * Contract: applyToneFilter(text) → tone-softened string
 * Rules (from Rails ToneFilter):
 *   "you are" → "you tend toward"
 *   "always" → "often" (case-preserving)
 *   "never" → "rarely"
 *   "can't" / "unable to" → "may find challenging to"
 *   "better than" → removed
 *   "worse than" → removed
 *   Double spaces collapsed.
 *   null/blank → ""
 */

import { describe, it, expect } from "vitest";
import { applyToneFilter } from "../../../src/services/profiles/toneFilter";

describe("ToneFilter (RED phase)", () => {
  it("replaces 'you are' with 'you tend toward'", () => {
    expect(applyToneFilter("you are introverted")).toBe("you tend toward introverted");
  });

  it("replaces 'always' with 'often'", () => {
    expect(applyToneFilter("You always work hard")).toBe("You often work hard");
  });

  it("replaces 'never' with 'rarely'", () => {
    expect(applyToneFilter("You never give up")).toBe("You rarely give up");
  });

  it("replaces inability framing — can't", () => {
    expect(applyToneFilter("You can't do this")).toBe("You may find challenging do this");
  });

  it("replaces inability framing — unable to", () => {
    expect(applyToneFilter("unable to focus")).toBe("may find it challenging to focus");
  });

  it("removes comparative judgments — better than", () => {
    expect(applyToneFilter("better than others in this area")).toBe("others in this area");
  });

  it("removes comparative judgments — worse than", () => {
    expect(applyToneFilter("worse than average")).toBe("average");
  });

  it("preserves case of original match", () => {
    expect(applyToneFilter("Always early")).toBe("Often early");
    expect(applyToneFilter("always early")).toBe("often early");
  });

  it("collapses double spaces from removals", () => {
    const result = applyToneFilter("much better than average");
    expect(result).not.toContain("  ");
  });

  it("handles blank text", () => {
    expect(applyToneFilter("")).toBe("");
    expect(applyToneFilter(null)).toBe("");
  });

  it("returns text unchanged when no patterns match", () => {
    const original = "You have a creative approach";
    expect(applyToneFilter(original)).toBe(original);
  });
});
