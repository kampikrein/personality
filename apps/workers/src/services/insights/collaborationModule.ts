/**
 * src/services/insights/collaborationModule.ts — GREEN phase
 * Rails: server/app/services/insights/collaboration_module.rb
 *
 * generateCollaborationInsight(profile) → { suggestions, explanation }
 * Pure compute — no DB access.
 */

import type { ModuleResult, ProfileForInsight } from "./careerModule";

export function generateCollaborationInsight(profile: ProfileForInsight): ModuleResult {
  const suggestions: string[] = [];

  if (profile.collaborationStyle) {
    suggestions.push(profile.collaborationStyle);
  }

  suggestions.push("Build on your teamwork strengths to enhance group dynamics.");

  const explanation = `Collaboration insights for ${profile.typeCode}: Your approach to working with others reflects your personality type.`;

  return { suggestions, explanation };
}
