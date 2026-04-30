/**
 * src/services/profiles/composer.ts — GREEN phase
 * Rails: server/app/services/profiles/composer.rb
 *
 * composeProfile(db, assessmentId, typeCode) → ComposedProfile
 * - UPSERT: INSERT ... ON CONFLICT(assessment_id) DO UPDATE RETURNING id
 * - builds score_vector from domain_scores
 * - applies ToneFilter to strengths
 * - generates suggested_actions based on domain scores
 * - raises for unknown type_code
 */

import { applyToneFilter } from "./toneFilter";
import { getTypeContent } from "./typeContentService";

export interface ComposedProfile {
  id: number;
  assessmentId: number;
  anonymousSessionId: number;
  personalityTypeId: number;
  typeCode: string;
  scoreVector: Record<string, number>;
  strengths: string[];
  cautionPatterns: string[];
  suggestedActions: Array<{ action: string; context?: string }>;
}

interface AssessmentRow {
  anonymous_session_id: number;
}

interface DomainScoreRow {
  domain: string;
  normalized_score: number | null;
}

interface PersonalityTypeRow {
  id: number;
  strengths: string | null;
  caution_patterns: string | null;
  collaboration_style: string | null;
  career_hints: string | null;
  recovery_style: string | null;
}

interface ProfileRow {
  id: number;
  anonymous_session_id: number;
  personality_type_id: number;
}

function buildSuggestedActions(
  domainScores: Record<string, number | null>,
  typeRow: PersonalityTypeRow
): Array<{ action: string; context?: string }> {
  const actions: Array<{ action: string; context?: string }> = [];

  // Base action — teamwork/collaboration hint (always present)
  actions.push({
    action: `Embrace collaboration and teamwork opportunities`,
    context: "teamwork",
  });

  // High score (>= 75): strength domain action
  for (const [domain, score] of Object.entries(domainScores)) {
    if (score != null && score >= 75) {
      actions.push({
        action: `Leverage your ${domain} strength`,
        context: "energy",
      });
      break; // one strong domain action is enough
    }
  }

  // Low score (<= 25): growth domain action
  for (const [domain, score] of Object.entries(domainScores)) {
    if (score != null && score <= 25) {
      actions.push({
        action: `Working on ${domain} skills can benefit your growth`,
        context: "recovery",
      });
      break;
    }
  }

  return actions;
}

export async function composeProfile(
  db: D1Database,
  assessmentId: number,
  typeCode: string
): Promise<ComposedProfile> {
  const code = typeCode.toUpperCase();

  // Validate type exists (will throw if not)
  await getTypeContent(db, code);

  // Get assessment row for anonymous_session_id
  const assessment = await db
    .prepare("SELECT anonymous_session_id FROM assessments WHERE id = ?")
    .bind(assessmentId)
    .first<AssessmentRow>();

  if (!assessment) {
    throw new Error(`Assessment not found: ${assessmentId}`);
  }

  // Get personality_type row
  const typeRow = await db
    .prepare(
      `SELECT id, strengths, caution_patterns, collaboration_style, career_hints, recovery_style
       FROM personality_types WHERE code = ?`
    )
    .bind(code)
    .first<PersonalityTypeRow>();

  if (!typeRow) {
    throw new Error(`Unknown personality type: ${code}`);
  }

  // Get domain_scores
  const domainScoresResult = await db
    .prepare(
      "SELECT domain, normalized_score FROM domain_scores WHERE assessment_id = ?"
    )
    .bind(assessmentId)
    .all<DomainScoreRow>();

  const scoreVector: Record<string, number> = {};
  for (const row of domainScoresResult.results) {
    if (row.normalized_score != null) {
      scoreVector[row.domain] = row.normalized_score;
    }
  }

  // Parse type content
  const strengths: string[] = typeRow.strengths ? JSON.parse(typeRow.strengths) : [];
  const cautionPatterns: string[] = typeRow.caution_patterns ? JSON.parse(typeRow.caution_patterns) : [];

  // Apply ToneFilter
  const filteredStrengths = strengths.map((s) => applyToneFilter(s));

  // Build suggested actions
  const suggestedActions = buildSuggestedActions(scoreVector, typeRow);

  // UPSERT profile with ON CONFLICT(assessment_id) DO UPDATE RETURNING id
  const upsertResult = await db
    .prepare(
      `INSERT INTO profiles
         (anonymous_session_id, assessment_id, personality_type_id, type_code,
          score_vector, strengths, caution_patterns, suggested_actions,
          created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
       ON CONFLICT(assessment_id) DO UPDATE SET
         personality_type_id = excluded.personality_type_id,
         type_code = excluded.type_code,
         score_vector = excluded.score_vector,
         strengths = excluded.strengths,
         caution_patterns = excluded.caution_patterns,
         suggested_actions = excluded.suggested_actions,
         updated_at = CURRENT_TIMESTAMP
       RETURNING id, anonymous_session_id, personality_type_id`
    )
    .bind(
      assessment.anonymous_session_id,
      assessmentId,
      typeRow.id,
      code,
      JSON.stringify(scoreVector),
      JSON.stringify(filteredStrengths),
      JSON.stringify(cautionPatterns),
      JSON.stringify(suggestedActions)
    )
    .first<ProfileRow>();

  if (!upsertResult) {
    throw new Error("Profile UPSERT failed");
  }

  return {
    id: upsertResult.id,
    assessmentId,
    anonymousSessionId: upsertResult.anonymous_session_id,
    personalityTypeId: upsertResult.personality_type_id,
    typeCode: code,
    scoreVector,
    strengths: filteredStrengths,
    cautionPatterns,
    suggestedActions,
  };
}
