/**
 * src/services/compliance/textPolicyFilter.ts — RED phase stub
 * Rails: server/app/services/compliance/text_policy_filter.rb
 */

export type FilterContext = "content" | "trust_notice";

export interface FilterResult {
  clean: boolean;
  violations: string[];
  filtered_text: string;
}

export function filterText(
  _text: string | null | undefined,
  _context?: FilterContext
): FilterResult {
  throw new Error("not implemented");
}
