/**
 * src/services/profiles/toneFilter.ts — GREEN phase
 * Rails: server/app/services/profiles/tone_filter.rb
 *
 * applyToneFilter(text) → tone-softened string
 * 7 replacement rules (in order):
 *   "you are"    → "you tend toward"
 *   "always"     → "often"  (case-preserving)
 *   "never"      → "rarely" (case-preserving)
 *   "can't "     → "may find challenging "
 *   "unable to"  → "may find it challenging to"
 *   "better than " → ""
 *   "worse than "  → ""
 * Final: collapse double spaces.
 * null/blank → ""
 */

type Replacement = {
  pattern: RegExp;
  replacement: string | ((match: string) => string);
};

const REPLACEMENTS: Replacement[] = [
  { pattern: /you are/gi, replacement: "you tend toward" },
  {
    pattern: /always/gi,
    replacement: (m: string) => m[0] === m[0].toUpperCase() && m[0] !== m[0].toLowerCase() ? "Often" : "often",
  },
  {
    pattern: /never/gi,
    replacement: (m: string) => m[0] === m[0].toUpperCase() && m[0] !== m[0].toLowerCase() ? "Rarely" : "rarely",
  },
  { pattern: /can't /gi, replacement: "may find challenging " },
  { pattern: /unable to/gi, replacement: "may find it challenging to" },
  { pattern: /better than /gi, replacement: "" },
  { pattern: /worse than /gi, replacement: "" },
];

export function applyToneFilter(text: string | null | undefined): string {
  if (!text) return "";

  let result = text;
  for (const { pattern, replacement } of REPLACEMENTS) {
    if (typeof replacement === "function") {
      result = result.replace(pattern, replacement);
    } else {
      result = result.replace(pattern, replacement);
    }
  }

  // Collapse double spaces
  result = result.replace(/  +/g, " ");

  return result;
}
