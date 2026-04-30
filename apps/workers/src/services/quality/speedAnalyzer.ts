/**
 * src/services/quality/speedAnalyzer.ts — GREEN phase
 * Rails: server/app/services/quality/speed_analyzer.rb
 *
 * analyzeSpeed(responses, assessmentDurationMs?) → SpeedAnalysisResult
 * Flags:
 *   - fast_individual: any response < 500ms
 *   - high_fast_rate: > 50% of responses < 1000ms → anomaly=true
 *   - fast_total_time: assessmentDurationMs < 60_000ms
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

function median(values: number[]): number {
  const sorted = [...values].sort((a, b) => a - b);
  const mid = Math.floor(sorted.length / 2);
  if (sorted.length % 2 === 0) {
    return (sorted[mid - 1] + sorted[mid]) / 2;
  }
  return sorted[mid];
}

export function analyzeSpeed(
  responses: ResponseTiming[],
  assessmentDurationMs?: number
): SpeedAnalysisResult {
  const flags: Array<"fast_individual" | "high_fast_rate" | "fast_total_time"> = [];

  if (responses.length === 0) {
    return {
      anomaly: false,
      flags,
      median_time_ms: null,
      fast_response_rate: 0.0,
    };
  }

  const times = responses
    .map((r) => r.response_time_ms)
    .filter((t): t is number => t != null);

  const median_time_ms = times.length > 0 ? median(times) : null;

  // Flag: fast_individual — any response < 500ms
  const hasFastIndividual = times.some((t) => t < 500);
  if (hasFastIndividual) {
    flags.push("fast_individual");
  }

  // Flag: high_fast_rate — > 50% of responses < 1000ms
  const fastCount = times.filter((t) => t < 1000).length;
  const fast_response_rate = times.length > 0 ? fastCount / times.length : 0.0;
  if (fast_response_rate > 0.5) {
    flags.push("high_fast_rate");
  }

  // Flag: fast_total_time — assessmentDurationMs < 60_000
  if (assessmentDurationMs != null && assessmentDurationMs < 60_000) {
    flags.push("fast_total_time");
  }

  // anomaly = true when high_fast_rate fires
  const anomaly = flags.includes("high_fast_rate");

  return {
    anomaly,
    flags,
    median_time_ms,
    fast_response_rate,
  };
}
