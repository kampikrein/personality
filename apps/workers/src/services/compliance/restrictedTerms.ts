/**
 * src/services/compliance/restrictedTerms.ts — GREEN phase
 * Rails: server/app/services/compliance/restricted_terms.rb
 *
 * Canonical list of trademarked/restricted terms.
 * Pure functions: scanRestrictedTerms() and isTextClean().
 */

/**
 * RESTRICTED_TERMS — full corpus from Rails restricted_terms.rb
 * Ordered longest-first to ensure longest-match wins on replacement
 * (e.g., "Myers-Briggs Type Indicator" before "Myers-Briggs").
 */
export const RESTRICTED_TERMS: string[] = [
  // Full trademark / official designations (longest first)
  "Myers-Briggs Type Indicator",
  "마이어스-브릭스",
  "Myers-Briggs",
  "MBTI",
  "Enneagram",
  "에니어그램",

  // Korean official MBTI type names
  "선의의 옹호자",
  "정의의 사도",
  "재기발랄한 활동가",
  "호기심 많은 예술가",
  "모험을 즐기는 사업가",
  "용감한 수호자",
  "열정적인 중재자",
  "옹호자",
  "중재자",
  "논리학자",
  "건축가",
  "과학자",
  "전략가",
  "활동가",
  "사업가",
  "경영자",
  "수호자",
  "현실주의자",

  // English official MBTI type names
  "The Inspector",
  "The Protector",
  "The Counselor",
  "The Mastermind",
  "The Crafter",
  "The Composer",
  "The Healer",
  "The Architect",
  "The Dynamo",
  "The Performer",
  "The Champion",
  "The Visionary",
  "The Supervisor",
  "The Provider",
  "The Teacher",
  "The Commander",
];

/**
 * ALLOWED_IN_TRUST_NOTICE — terms that may appear in a legal trust notice
 * ("This service is not affiliated with MBTI or Myers-Briggs")
 */
export const ALLOWED_IN_TRUST_NOTICE: string[] = ["MBTI", "Myers-Briggs"];

/**
 * MBTI 4-letter type codes (ENFP etc.) — NOT restricted.
 * Used to avoid false positives when a restricted term is a substring of a type code.
 * (Currently not needed because none of the restricted terms are 4-letter codes,
 *  but kept as a safeguard for future corpus changes.)
 */
const FOUR_LETTER_CODES = new Set([
  "ENFP","ENFJ","ENTP","ENTJ",
  "ESFP","ESFJ","ESTP","ESTJ",
  "INFP","INFJ","INTP","INTJ",
  "ISFP","ISFJ","ISTP","ISTJ",
]);

/**
 * Escape a term for use in a RegExp.
 */
function escapeRegExp(term: string): string {
  return term.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

/**
 * Build a case-insensitive RegExp that matches `term` as a whole word or phrase.
 * For Korean terms (no ASCII word boundaries), we skip the word-boundary assertion.
 */
function buildTermRegex(term: string): RegExp {
  const escaped = escapeRegExp(term);
  // If term contains only ASCII characters, add word boundaries to avoid
  // matching "MBTI" inside "MBTIX" etc.
  const isAscii = /^[\x00-\x7F]+$/.test(term);
  const pattern = isAscii ? `\\b${escaped}\\b` : escaped;
  return new RegExp(pattern, "gi");
}

/**
 * scanRestrictedTerms(text) → string[] of canonical violated terms
 * - Case-insensitive matching
 * - Returns canonical form (not the matched form) for each violated term
 * - Does NOT flag 4-letter MBTI type codes (ENFP, INTP, etc.)
 * - Returns [] for null / empty input
 */
export function scanRestrictedTerms(text: string | null | undefined): string[] {
  if (!text) return [];

  const violated: string[] = [];
  for (const term of RESTRICTED_TERMS) {
    const regex = buildTermRegex(term);
    if (regex.test(text)) {
      violated.push(term);
    }
  }

  return violated;
}

/**
 * isTextClean(text, options?) → boolean
 * - Returns true if no restricted terms are found
 * - allowTrustNotice: true → ALLOWED_IN_TRUST_NOTICE terms are skipped during scan
 */
export function isTextClean(
  text: string | null | undefined,
  options?: { allowTrustNotice?: boolean }
): boolean {
  if (!text) return true;

  const skipTerms = options?.allowTrustNotice
    ? new Set(ALLOWED_IN_TRUST_NOTICE)
    : new Set<string>();

  for (const term of RESTRICTED_TERMS) {
    if (skipTerms.has(term)) continue;
    const regex = buildTermRegex(term);
    if (regex.test(text)) return false;
  }

  return true;
}
