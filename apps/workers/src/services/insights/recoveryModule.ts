/**
 * src/services/insights/recoveryModule.ts — GREEN phase
 * Rails: server/app/services/insights/recovery_module.rb
 *
 * generateRecoveryInsight(profile) → { suggestions, explanation }
 * Pure compute — no DB access.
 */

import type { ModuleResult, ProfileForInsight } from "./careerModule";

export function generateRecoveryInsight(profile: ProfileForInsight): ModuleResult {
  const suggestions: string[] = [];

  if (profile.recoveryStyle) {
    suggestions.push(profile.recoveryStyle);
  }

  suggestions.push("Schedule regular recovery time that aligns with your personality needs.");

  const explanation = `Recovery insights for ${profile.typeCode}: Knowing how you recharge helps you maintain sustained performance.`;

  return { suggestions, explanation };
}
