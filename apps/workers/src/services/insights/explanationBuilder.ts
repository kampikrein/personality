/**
 * src/services/insights/explanationBuilder.ts — GREEN phase
 * Rails: server/app/services/insights/explanation_builder.rb
 *
 * buildExplanation(baseExplanation, suggestions) → string
 * - 0 or 1 suggestions: returns baseExplanation as-is
 * - 2+ suggestions: appends "Suggestions cover: <truncated>" suffix
 */

export function buildExplanation(
  baseExplanation: string,
  suggestions: string[]
): string {
  if (suggestions.length < 2) {
    return baseExplanation;
  }

  const truncated = suggestions.slice(0, 3).join("; ");
  return `${baseExplanation} Suggestions cover: ${truncated}`;
}
