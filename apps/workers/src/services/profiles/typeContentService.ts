/**
 * src/services/profiles/typeContentService.ts — RED phase stub
 * Rails: server/app/services/profiles/type_content_service.rb
 *
 * Maps type_code → personality_types content (locale-aware).
 * Supports locales: 'ko' | 'en'. Falls back to the other locale if primary is blank.
 */

export interface TypeContent {
  character_name: string;
  summary: string | null;
  strengths: string[];
  caution_patterns: string[];
}

export async function getTypeContent(
  _db: unknown,
  _typeCode: string,
  _locale?: "ko" | "en"
): Promise<TypeContent> {
  throw new Error("not implemented");
}
