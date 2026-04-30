/**
 * src/services/insights/learningModule.ts — GREEN phase
 * Rails: server/app/services/insights/learning_module.rb
 *
 * generateLearningInsight(profile) → { suggestions, explanation }
 * Pure compute — no DB access.
 */

import type { ModuleResult, ProfileForInsight } from "./careerModule";

export function generateLearningInsight(profile: ProfileForInsight): ModuleResult {
  const suggestions: string[] = [];

  if (profile.learningStyle) {
    suggestions.push(profile.learningStyle);
  }

  suggestions.push("Explore resources that match your preferred learning approach.");

  const explanation = `Learning insights for ${profile.typeCode}: Understanding your learning style helps you grow more effectively.`;

  return { suggestions, explanation };
}
