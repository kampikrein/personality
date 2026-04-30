/**
 * src/services/scoring/reliabilityAdjuster.ts — GREEN phase
 * Rails: server/app/services/scoring/reliability_adjuster.rb
 *
 * adjustReliability(responses) → ReliabilityResult
 * reliability_coefficient = 0.4*consistency + 0.2*(speed?0:1) + 0.2*(1-non_response) + 0.2*(1-extreme)
 * Pearson r: split-half correlation
 * Spearman-Brown: 2r/(1+r), clamped to [0,1]
 * Flags: "low_split_half_consistency", "high_extreme_response_rate", "speed_anomaly", "high_non_response_rate"
 */

export interface ReliabilityResult {
  reliability_coefficient: number;
  consistency_index: number;
  speed_flag: boolean;
  non_response_rate: number;
  extreme_response_rate: number;
  flags: string[];
}

export interface ResponseForReliability {
  value: number | null;
  response_time_ms: number | null;
}

/**
 * Pearson correlation coefficient between two arrays.
 * Returns null if arrays have < 2 elements or zero variance in either array.
 */
export function pearsonR(a: number[], b: number[]): number | null {
  if (a.length < 2 || b.length < 2 || a.length !== b.length) return null;

  const n = a.length;
  const meanA = a.reduce((s, v) => s + v, 0) / n;
  const meanB = b.reduce((s, v) => s + v, 0) / n;

  let cov = 0;
  let varA = 0;
  let varB = 0;

  for (let i = 0; i < n; i++) {
    const da = a[i] - meanA;
    const db = b[i] - meanB;
    cov += da * db;
    varA += da * da;
    varB += db * db;
  }

  if (varA === 0 || varB === 0) return null;

  return cov / Math.sqrt(varA * varB);
}

/**
 * Spearman-Brown prophecy formula: 2r/(1+r), clamped to [0,1].
 */
function spearmanBrown(r: number): number {
  const sb = (2 * r) / (1 + r);
  return Math.max(0, Math.min(1, sb));
}

export function adjustReliability(
  responses: ResponseForReliability[]
): ReliabilityResult {
  if (responses.length === 0) {
    return {
      reliability_coefficient: 0.2, // 0.4*0 + 0.2*1 + 0.2*1 + 0.2*1
      consistency_index: 0.0,
      speed_flag: false,
      non_response_rate: 0.0,
      extreme_response_rate: 0.0,
      flags: ["low_split_half_consistency"],
    };
  }

  const total = responses.length;
  const answered = responses.filter((r) => r.value != null);
  const answeredValues = answered.map((r) => r.value as number);

  // Non-response rate
  const non_response_rate = (total - answered.length) / total;

  // Extreme response rate (value 1 or 5)
  const extremeCount = answeredValues.filter((v) => v === 1 || v === 5).length;
  const extreme_response_rate = total > 0 ? extremeCount / total : 0.0;

  // Speed flag: > 50% of responses < 500ms
  const times = responses.map((r) => r.response_time_ms).filter((t): t is number => t != null);
  const fastCount = times.filter((t) => t < 500).length;
  const speed_flag = times.length > 0 && fastCount / times.length > 0.5;

  // Split-half consistency via Pearson r + Spearman-Brown
  let consistency_index = 0.0;
  if (answeredValues.length >= 4) {
    const half = Math.floor(answeredValues.length / 2);
    const firstHalf = answeredValues.slice(0, half);
    const secondHalf = answeredValues.slice(half, half * 2);
    const r = pearsonR(firstHalf, secondHalf);
    if (r != null && r > 0) {
      consistency_index = spearmanBrown(r);
    }
  }

  // Flags
  const flags: string[] = [];
  if (consistency_index < 0.5) {
    flags.push("low_split_half_consistency");
  }
  if (extreme_response_rate >= 0.8) {
    flags.push("high_extreme_response_rate");
  }
  if (speed_flag) {
    flags.push("speed_anomaly");
  }
  if (non_response_rate > 0.2) {
    flags.push("high_non_response_rate");
  }

  // Reliability coefficient (weighted)
  const reliability_coefficient =
    0.4 * consistency_index +
    0.2 * (speed_flag ? 0.0 : 1.0) +
    0.2 * (1.0 - non_response_rate) +
    0.2 * (1.0 - extreme_response_rate);

  return {
    reliability_coefficient: Math.round(reliability_coefficient * 1000) / 1000,
    consistency_index,
    speed_flag,
    non_response_rate,
    extreme_response_rate,
    flags,
  };
}
