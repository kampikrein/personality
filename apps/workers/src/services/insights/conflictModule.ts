/**
 * src/services/insights/conflictModule.ts — GREEN phase
 * Rails: server/app/services/insights/conflict_module.rb
 *
 * generateConflictInsight(profile) → { suggestions, explanation }
 * Pure compute — no DB access.
 */

import type { ModuleResult, ProfileForInsight } from "./careerModule";

export function generateConflictInsight(profile: ProfileForInsight): ModuleResult {
  const suggestions: string[] = [];

  if (profile.conflictStyle) {
    suggestions.push(profile.conflictStyle);
  }

  suggestions.push("Approach conflict with curiosity rather than defensiveness.");

  const explanation = `Conflict insights for ${profile.typeCode}: Understanding your conflict patterns helps you navigate disagreements more effectively.`;

  return { suggestions, explanation };
}
