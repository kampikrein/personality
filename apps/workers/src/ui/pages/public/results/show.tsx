/**
 * src/ui/pages/public/results/show.tsx — Results page stub
 * Cycle 6 RED phase. Integrates 5 partials: type_hero, spectrum, insight_card×N, trust_notice.
 */

export interface TypeHeroData {
  typeName: string;
  typeCode: string;
  tagline: string;
}

export interface SpectrumData {
  domains: Array<{ name: string; score: number }>;
}

export interface InsightCard {
  title: string;
  body: string;
}

export interface ResultsShowProps {
  typeHero: TypeHeroData;
  spectrum: SpectrumData;
  insights: InsightCard[];
}

// RED stub — not implemented
export function ResultsShowPage(_props: ResultsShowProps): unknown {
  throw new Error("not implemented: ResultsShowPage");
}

// Partial stubs
export function TypeHero(_props: TypeHeroData): unknown {
  throw new Error("not implemented: TypeHero");
}

export function SpectrumPartial(_props: SpectrumData): unknown {
  throw new Error("not implemented: SpectrumPartial");
}

export function InsightCardPartial(_props: InsightCard): unknown {
  throw new Error("not implemented: InsightCardPartial");
}

export function TrustNotice(): unknown {
  throw new Error("not implemented: TrustNotice");
}
