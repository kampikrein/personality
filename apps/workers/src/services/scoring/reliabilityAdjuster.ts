/**
 * src/services/scoring/reliabilityAdjuster.ts — RED phase stub
 * Rails: server/app/services/scoring/reliability_adjuster.rb
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

export function adjustReliability(
  _responses: ResponseForReliability[]
): ReliabilityResult {
  throw new Error("not implemented");
}

export function pearsonR(
  _a: number[],
  _b: number[]
): number | null {
  throw new Error("not implemented");
}
