/**
 * src/services/scoring/policyChecker.ts — GREEN phase
 * Rails: server/app/services/scoring/policy_checker.rb
 *
 * checkPolicy(reliabilityResult) → { blocked, reasons }
 * Block conditions:
 *   - reliability_coefficient < 0.3  → "reliability_coefficient_below_threshold"
 *   - non_response_rate > 0.5        → "non_response_rate_above_threshold"
 *   - speed_flag === true             → "speed_anomaly_detected"
 * Boundary: strict (< 0.3, > 0.5)
 */

import type { ReliabilityResult } from "./reliabilityAdjuster";

export interface PolicyResult {
  blocked: boolean;
  reasons: string[];
}

export function checkPolicy(
  reliabilityResult: ReliabilityResult
): PolicyResult {
  const reasons: string[] = [];

  if (reliabilityResult.reliability_coefficient < 0.3) {
    reasons.push("reliability_coefficient_below_threshold");
  }

  if (reliabilityResult.non_response_rate > 0.5) {
    reasons.push("non_response_rate_above_threshold");
  }

  if (reliabilityResult.speed_flag === true) {
    reasons.push("speed_anomaly_detected");
  }

  return {
    blocked: reasons.length > 0,
    reasons,
  };
}
