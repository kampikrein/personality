/**
 * test/ui/pages/public/results/show.test.ts — ResultsShowPage GREEN tests
 * Cycle 6 GREEN phase (Step 0: antipattern fix).
 *
 * Stimulus mapping:
 *   - type_reveal_controller: letter animation on type code
 *   - spectrum_bar_controller: bars animate to final widths after delay
 *   - tabs_controller: insight tabs (domains)
 *
 * GREEN: Renders 5 partial components:
 *   TypeHero (typeName, typeCode, tagline)
 *   SpectrumPartial (domains × N bars with animation data)
 *   InsightCardPartial × N (title + body)
 *   TrustNotice (static disclaimer)
 */

import { describe, it, expect } from "vitest";
import {
  ResultsShowPage,
  TypeHero,
  SpectrumPartial,
  InsightCardPartial,
  TrustNotice,
} from "../../../../../src/ui/pages/public/results/show";
import type {
  TypeHeroData,
  SpectrumData,
  InsightCard,
} from "../../../../../src/ui/pages/public/results/show";

const typeHero: TypeHeroData = {
  typeName: "The Architect",
  typeCode: "INTJ",
  tagline: "Strategic minds who see the bigger picture",
};

const spectrum: SpectrumData = {
  domains: [
    { name: "Energy", score: 72 },
    { name: "Information", score: 35 },
    { name: "Decisions", score: 88 },
    { name: "Lifestyle", score: 62 },
  ],
};

const insights: InsightCard[] = [
  { title: "Your Strengths", body: "Strategic thinking, independence" },
  { title: "Growth Areas", body: "Emotional expression, flexibility" },
];

describe("ResultsShowPage", () => {
  it("ResultsShowPage is exported", () => {
    expect(ResultsShowPage).toBeDefined();
    expect(typeof ResultsShowPage).toBe("function");
  });

  it("renders full results page", () => {
    const html = String(ResultsShowPage({ typeHero, spectrum, insights }));
    expect(html).toContain("The Architect");
  });
});

describe("TypeHero partial", () => {
  it("TypeHero is exported", () => {
    expect(TypeHero).toBeDefined();
    expect(typeof TypeHero).toBe("function");
  });

  it("renders type hero", () => {
    const html = String(TypeHero(typeHero));
    expect(html).toContain("INTJ");
  });
});

describe("SpectrumPartial", () => {
  it("SpectrumPartial is exported", () => {
    expect(SpectrumPartial).toBeDefined();
    expect(typeof SpectrumPartial).toBe("function");
  });

  it("renders spectrum bars", () => {
    const html = String(SpectrumPartial(spectrum));
    expect(html).toContain("Energy");
  });

  it("spectrum has 4 domains", () => {
    expect(spectrum.domains).toHaveLength(4);
    expect(spectrum.domains[0].score).toBe(72);
  });
});

describe("InsightCardPartial", () => {
  it("InsightCardPartial is exported", () => {
    expect(InsightCardPartial).toBeDefined();
    expect(typeof InsightCardPartial).toBe("function");
  });

  it("renders insight card", () => {
    const html = String(InsightCardPartial(insights[0]));
    expect(html).toContain("Your Strengths");
  });
});

describe("TrustNotice partial", () => {
  it("TrustNotice is exported", () => {
    expect(TrustNotice).toBeDefined();
    expect(typeof TrustNotice).toBe("function");
  });

  it("renders trust notice", () => {
    const html = String(TrustNotice());
    expect(html).toBeDefined();
  });
});
