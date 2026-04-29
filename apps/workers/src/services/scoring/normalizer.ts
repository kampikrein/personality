/**
 * src/services/scoring/normalizer.ts — RED phase stub
 * Rails: server/app/services/scoring/normalizer.rb
 */

export interface NormalizedScores {
  energy: number | null;
  decision_making: number | null;
  relationship: number | null;
  recovery: number | null;
}

export interface ResponseForNorm {
  domain: string;
  value: number | null;
}

export function normalizeScores(
  _rawScores: Record<string, number>,
  _responses: ResponseForNorm[]
): NormalizedScores {
  throw new Error("not implemented");
}
