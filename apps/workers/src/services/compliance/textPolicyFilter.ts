/**
 * src/services/compliance/textPolicyFilter.ts — GREEN phase
 * Rails: server/app/services/compliance/text_policy_filter.rb
 *
 * filterText(text, context?) → { clean, violations, filtered_text }
 * Contexts: 'content' (default) | 'trust_notice'
 * Restricted terms are replaced with "[REMOVED]" in filtered_text.
 * Invalid context → throws /Unknown context/.
 */

import { RESTRICTED_TERMS, ALLOWED_IN_TRUST_NOTICE } from "./restrictedTerms";

export type FilterContext = "content" | "trust_notice";

export interface FilterResult {
  clean: boolean;
  violations: string[];
  filtered_text: string;
}

function escapeRegExp(term: string): string {
  return term.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function buildTermRegex(term: string): RegExp {
  const escaped = escapeRegExp(term);
  const isAscii = /^[\x00-\x7F]+$/.test(term);
  const pattern = isAscii ? `\\b${escaped}\\b` : escaped;
  return new RegExp(pattern, "gi");
}

/**
 * filterText(text, context?) → FilterResult
 *
 * Processing order for replacement is longest-term-first (RESTRICTED_TERMS is
 * already ordered longest-first) so "Myers-Briggs Type Indicator" is replaced
 * before "Myers-Briggs".
 */
export function filterText(
  text: string | null | undefined,
  context: FilterContext = "content"
): FilterResult {
  if (context !== "content" && context !== "trust_notice") {
    throw new Error(`Unknown context: ${context}`);
  }

  const safe = text ?? "";

  const skipTerms =
    context === "trust_notice"
      ? new Set(ALLOWED_IN_TRUST_NOTICE)
      : new Set<string>();

  const violations: string[] = [];
  let filtered = safe;

  for (const term of RESTRICTED_TERMS) {
    if (skipTerms.has(term)) continue;

    const regex = buildTermRegex(term);

    // Check first (reset lastIndex via new regex instance in buildTermRegex)
    if (regex.test(safe)) {
      violations.push(term);
      // Replace all occurrences in filtered
      const replaceRegex = buildTermRegex(term);
      filtered = filtered.replace(replaceRegex, "[REMOVED]");
    }
  }

  return {
    clean: violations.length === 0,
    violations,
    filtered_text: filtered,
  };
}
