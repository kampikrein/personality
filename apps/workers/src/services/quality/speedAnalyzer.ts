/**
 * src/services/quality/speedAnalyzer.ts — RED phase stub
 * Rails: server/app/services/quality/speed_analyzer.rb
 */

export interface SpeedAnalysisResult {
  anomaly: boolean;
  flags: Array<"fast_individual" | "high_fast_rate" | "fast_total_time">;
  median_time_ms: number | null;
  fast_response_rate: number;
}

export interface ResponseTiming {
  response_time_ms: number | null;
}

export function analyzeSpeed(
  _responses: ResponseTiming[],
  _assessmentDurationMs?: number
): SpeedAnalysisResult {
  throw new Error("not implemented");
}
