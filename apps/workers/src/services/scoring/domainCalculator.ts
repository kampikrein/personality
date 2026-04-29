/**
 * src/services/scoring/domainCalculator.ts — RED phase stub
 * Rails: server/app/services/scoring/domain_calculator.rb
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

export function calculateDomainScores(
  _assessment: AssessmentWithResponses
): DomainScores {
  throw new Error("not implemented");
}
