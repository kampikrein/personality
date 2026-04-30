/**
 * src/services/compliance/snapshot.ts — GREEN phase
 * Rails: spec/services/compliance/snapshot_spec.rb (model spec equivalent)
 *
 * D1 seed data compliance verification.
 * Scans personality_types seed data for restricted term violations.
 * Verifies character name originality (no overlap with official MBTI names).
 */

import { scanRestrictedTerms } from "./restrictedTerms";

export interface SnapshotViolation {
  code: string;
  field: string;
  value: string;
  terms: string[];
}

interface PersonalityTypeRow {
  code: string;
  character_name_ko: string | null;
  character_name_en: string | null;
  summary_ko: string | null;
  summary_en: string | null;
  strengths: string | null;
  caution_patterns: string | null;
  collaboration_style: string | null;
  conflict_style: string | null;
  learning_style: string | null;
  career_hints: string | null;
  recovery_style: string | null;
}

/** Text fields to scan for restricted terms */
const TEXT_FIELDS: Array<keyof PersonalityTypeRow> = [
  "character_name_ko",
  "character_name_en",
  "summary_ko",
  "summary_en",
  "strengths",
  "caution_patterns",
  "collaboration_style",
  "conflict_style",
  "learning_style",
  "career_hints",
  "recovery_style",
];

/** Official MBTI English type names — character_name_en must not match these */
const OFFICIAL_MBTI_NAMES_EN = new Set([
  "The Inspector", "The Protector", "The Counselor", "The Mastermind",
  "The Crafter", "The Composer", "The Healer", "The Architect",
  "The Dynamo", "The Performer", "The Champion", "The Visionary",
  "The Supervisor", "The Provider", "The Teacher", "The Commander",
]);

/** Official MBTI Korean type names — character_name_ko must not match these */
const OFFICIAL_MBTI_NAMES_KO = new Set([
  "옹호자", "중재자", "선의의 옹호자", "정의의 사도",
  "논리학자", "건축가", "과학자", "전략가",
  "활동가", "재기발랄한 활동가", "호기심 많은 예술가", "모험을 즐기는 사업가",
  "사업가", "경영자", "수호자", "현실주의자",
  "용감한 수호자", "열정적인 중재자",
]);

/**
 * scanSeedDataForViolations(db) → SnapshotViolation[]
 *
 * Scans all text fields of all personality_types rows for restricted terms.
 * Returns an array of violations (empty = fully compliant seed data).
 */
export async function scanSeedDataForViolations(
  db: D1Database
): Promise<SnapshotViolation[]> {
  const rows = await db
    .prepare(
      `SELECT code, character_name_ko, character_name_en, summary_ko, summary_en,
              strengths, caution_patterns, collaboration_style, conflict_style,
              learning_style, career_hints, recovery_style
       FROM personality_types`
    )
    .all<PersonalityTypeRow>();

  const violations: SnapshotViolation[] = [];

  for (const row of rows.results) {
    for (const field of TEXT_FIELDS) {
      const rawValue = row[field];
      if (!rawValue) continue;

      // JSON array fields: scan each element separately, but also join for phrase scan
      let textToScan: string;
      if (rawValue.startsWith("[")) {
        try {
          const arr: string[] = JSON.parse(rawValue);
          textToScan = arr.join(" ");
        } catch {
          textToScan = rawValue;
        }
      } else {
        textToScan = rawValue;
      }

      const terms = scanRestrictedTerms(textToScan);
      if (terms.length > 0) {
        violations.push({
          code: row.code,
          field: field as string,
          value: rawValue,
          terms,
        });
      }
    }
  }

  return violations;
}

/**
 * verifyCharacterNameOriginality(db) → { violations, hasUniqueNames }
 *
 * Checks:
 *   1. character_name_ko and character_name_en do not match any official MBTI names
 *   2. All 16 character_name_ko values are unique
 */
export async function verifyCharacterNameOriginality(
  db: D1Database
): Promise<{ violations: SnapshotViolation[]; hasUniqueNames: boolean }> {
  const rows = await db
    .prepare("SELECT code, character_name_ko, character_name_en FROM personality_types")
    .all<{ code: string; character_name_ko: string | null; character_name_en: string | null }>();

  const violations: SnapshotViolation[] = [];

  for (const row of rows.results) {
    // Check character_name_ko against official MBTI Korean names
    if (row.character_name_ko && OFFICIAL_MBTI_NAMES_KO.has(row.character_name_ko)) {
      violations.push({
        code: row.code,
        field: "character_name_ko",
        value: row.character_name_ko,
        terms: [row.character_name_ko],
      });
    }

    // Check character_name_en against official MBTI English names
    if (row.character_name_en && OFFICIAL_MBTI_NAMES_EN.has(row.character_name_en)) {
      violations.push({
        code: row.code,
        field: "character_name_en",
        value: row.character_name_en,
        terms: [row.character_name_en],
      });
    }
  }

  // Check uniqueness of character_name_ko
  const koNames = rows.results
    .map((r) => r.character_name_ko)
    .filter((n): n is string => n !== null);
  const uniqueKo = new Set(koNames);
  const hasUniqueNames = uniqueKo.size === rows.results.length;

  return { violations, hasUniqueNames };
}
