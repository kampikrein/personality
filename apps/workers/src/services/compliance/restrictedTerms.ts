/**
 * src/services/compliance/restrictedTerms.ts — RED phase stub
 * Rails: server/app/services/compliance/restricted_terms.rb
 *
 * Canonical list of trademarked/restricted terms.
 * Pure functions: scan() and clean?.
 */

export const RESTRICTED_TERMS: string[] = [];
// GREEN phase: populate from Rails original list

export const ALLOWED_IN_TRUST_NOTICE: string[] = [];
// GREEN phase: ["MBTI", "Myers-Briggs"]

export function scanRestrictedTerms(_text: string | null | undefined): string[] {
  throw new Error("not implemented");
}

export function isTextClean(
  _text: string | null | undefined,
  _options?: { allowTrustNotice?: boolean }
): boolean {
  throw new Error("not implemented");
}
