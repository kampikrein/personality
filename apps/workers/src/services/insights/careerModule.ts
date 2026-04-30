/**
 * src/services/insights/careerModule.ts — GREEN phase
 * Rails: server/app/services/insights/career_module.rb
 *
 * generateCareerInsight(profile) → { suggestions, explanation }
 * Pure compute — no DB access.
 */

export interface ModuleResult {
  suggestions: string[];
  explanation: string;
}

export interface ProfileForInsight {
  typeCode: string;
  scoreVector?: Record<string, number | null>;
  strengths?: string[];
  cautionPatterns?: string[];
  collaborationStyle?: string | null;
  conflictStyle?: string | null;
  learningStyle?: string | null;
  careerHints?: string | null;
  recoveryStyle?: string | null;
}

export function generateCareerInsight(profile: ProfileForInsight): ModuleResult {
  const suggestions: string[] = [];

  if (profile.careerHints) {
    suggestions.push(profile.careerHints);
  }

  if (profile.strengths && profile.strengths.length > 0) {
    suggestions.push(`Leverage your strengths: ${profile.strengths.slice(0, 2).join(", ")}`);
  }

  const explanation = `Career insights for ${profile.typeCode}: Align your work with your natural strengths and preferences.`;

  return { suggestions, explanation };
}
