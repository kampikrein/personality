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

export function TypeHero(props: TypeHeroData): string {
  return `<div class="type-hero">
  <h1 class="type-code">${props.typeCode}</h1>
  <h2 class="type-name">${props.typeName}</h2>
  <p class="tagline">${props.tagline}</p>
</div>`;
}

export function SpectrumPartial(props: SpectrumData): string {
  const bars = props.domains.map(
    (d) =>
      `<div class="spectrum-bar">
    <span class="domain-name">${d.name}</span>
    <div class="bar-track"><div class="bar-fill" style="width:${d.score}%"></div></div>
    <span class="score">${d.score}</span>
  </div>`
  ).join("");

  return `<div class="spectrum">${bars}</div>`;
}

export function InsightCardPartial(props: InsightCard): string {
  return `<div class="insight-card">
  <h3>${props.title}</h3>
  <p>${props.body}</p>
</div>`;
}

export function TrustNotice(): string {
  return `<div class="trust-notice">
  <p>This assessment is for personal insight only and is not a clinical diagnosis. Results may vary.</p>
</div>`;
}

export function ResultsShowPage(props: ResultsShowProps): string {
  const insightsHtml = props.insights.map((card) => InsightCardPartial(card)).join("");

  return `<div class="results-show">
  ${TypeHero(props.typeHero)}
  ${SpectrumPartial(props.spectrum)}
  <div class="insights">${insightsHtml}</div>
  ${TrustNotice()}
</div>`;
}
