/**
 * src/services/scoring/normalizer.ts — GREEN phase
 * Rails: server/app/services/scoring/normalizer.rb
 *
 * normalizeScores(rawScores, responses) → { domain: 0-100 | null }
 * Formula: (raw - effective_min) / (effective_max - effective_min) * 100
 * effective_min = answeredCount * 1, effective_max = answeredCount * 5
 * Rounds to 1 decimal place.
 * Returns null if answeredCount = 0.
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

const DOMAINS = ["energy", "decision_making", "relationship", "recovery"] as const;
type DomainKey = typeof DOMAINS[number];

function roundTo1dp(val: number): number {
  return Math.round(val * 10) / 10;
}

export function normalizeScores(
  rawScores: Record<string, number>,
  responses: ResponseForNorm[]
): NormalizedScores {
  const result: NormalizedScores = {
    energy: null,
    decision_making: null,
    relationship: null,
    recovery: null,
  };

  for (const domain of DOMAINS) {
    const answeredCount = responses.filter(
      (r) => r.domain === domain && r.value != null
    ).length;

    if (answeredCount === 0) {
      result[domain] = null;
      continue;
    }

    const raw = rawScores[domain] ?? 0;
    const effectiveMin = answeredCount * 1;
    const effectiveMax = answeredCount * 5;
    const range = effectiveMax - effectiveMin;

    if (range === 0) {
      result[domain] = 0.0;
      continue;
    }

    const normalized = ((raw - effectiveMin) / range) * 100;
    result[domain] = roundTo1dp(normalized);
  }

  return result;
}
