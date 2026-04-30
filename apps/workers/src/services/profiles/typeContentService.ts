/**
 * src/services/profiles/typeContentService.ts — GREEN phase
 * Rails: server/app/services/profiles/type_content_service.rb
 *
 * getTypeContent(db, typeCode, locale?) → TypeContent
 * - locale: 'ko' | 'en', default 'ko'
 * - fallback: if primary locale is blank → use other locale
 * - raises for unknown typeCode
 * - normalizes type_code to uppercase
 */

export interface TypeContent {
  character_name: string;
  summary: string | null;
  strengths: string[];
  caution_patterns: string[];
}

interface PersonalityTypeRow {
  character_name_ko: string;
  character_name_en: string;
  summary_ko: string | null;
  summary_en: string | null;
  strengths: string | null;
  caution_patterns: string | null;
}

export async function getTypeContent(
  db: D1Database,
  typeCode: string,
  locale: "ko" | "en" = "ko"
): Promise<TypeContent> {
  const code = typeCode.toUpperCase();

  const row = await db
    .prepare(
      `SELECT character_name_ko, character_name_en,
              summary_ko, summary_en,
              strengths, caution_patterns
       FROM personality_types WHERE code = ?`
    )
    .bind(code)
    .first<PersonalityTypeRow>();

  if (!row) {
    throw new Error(`Unknown personality type: ${code}`);
  }

  // Strengths & caution_patterns are stored as JSON strings
  const strengths: string[] = row.strengths ? JSON.parse(row.strengths) : [];
  const caution_patterns: string[] = row.caution_patterns ? JSON.parse(row.caution_patterns) : [];

  // Locale-aware name selection with fallback
  let character_name: string;
  let summary: string | null;

  if (locale === "ko") {
    character_name = row.character_name_ko || row.character_name_en;
    summary = row.summary_ko || row.summary_en || null;
  } else {
    character_name = row.character_name_en || row.character_name_ko;
    summary = row.summary_en || row.summary_ko || null;
  }

  return {
    character_name,
    summary,
    strengths,
    caution_patterns,
  };
}
