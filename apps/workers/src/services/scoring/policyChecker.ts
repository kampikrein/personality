/**
 * src/services/scoring/policyChecker.ts — RED phase stub
 * Rails: server/app/services/scoring/policy_checker.rb
 */

import type { ReliabilityResult } from "./reliabilityAdjuster";

export interface PolicyResult {
  blocked: boolean;
  reasons: string[];
}

export function checkPolicy(
  _reliabilityResult: ReliabilityResult
): PolicyResult {
  throw new Error("not implemented");
}
