/**
 * src/services/insights/careerModule.ts — RED phase stub
 * Rails: server/app/services/insights/career_module.rb
 */

export interface ModuleResult {
  suggestions: string[];
  explanation: string;
}

export function generateCareerInsight(_profile: unknown): ModuleResult {
  throw new Error("not implemented");
}
