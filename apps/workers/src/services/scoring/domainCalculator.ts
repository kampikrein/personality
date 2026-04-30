/**
 * src/services/scoring/domainCalculator.ts — GREEN phase
 * Rails: server/app/services/scoring/domain_calculator.rb
 *
 * calculateDomainScores(assessment) → { energy, decision_making, relationship, recovery }
 * - positive polarity: sum values directly
 * - negative polarity: reverse-score (6 - value)
 * - skipped (null/undefined value): excluded from sum
 * - empty assessment: 0 for all domains
 */

export interface DomainScores {
  energy: number;
  decision_making: number;
  relationship: number;
  recovery: number;
}

export interface ResponseRow {
  value: number | null;
  polarity: string;
  domain: string;
}

export interface AssessmentWithResponses {
  id: number;
  responses: ResponseRow[];
}

type DomainKey = keyof DomainScores;
const DOMAINS: DomainKey[] = ["energy", "decision_making", "relationship", "recovery"];

export function calculateDomainScores(
  assessment: AssessmentWithResponses
): DomainScores {
  const result: DomainScores = {
    energy: 0,
    decision_making: 0,
    relationship: 0,
    recovery: 0,
  };

  for (const response of assessment.responses) {
    const domain = response.domain as DomainKey;
    if (!DOMAINS.includes(domain)) continue;
    if (response.value == null) continue;

    const value =
      response.polarity === "negative"
        ? 6 - response.value
        : response.value;

    result[domain] += value;
  }

  return result;
}
