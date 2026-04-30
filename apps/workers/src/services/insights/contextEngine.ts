/**
 * src/services/insights/contextEngine.ts — GREEN phase
 * Rails: server/app/services/insights/context_engine.rb
 *
 * generateInsight(db, profileId, context) → InsightResult
 * - 5 contexts: collaboration | conflict | learning | career | recovery
 * - Dispatches to appropriate module
 * - Enriches explanation with buildExplanation
 * - UPSERT insights (ON CONFLICT(profile_id, context) DO UPDATE)
 * - idempotent
 */

import { buildExplanation } from "./explanationBuilder";
import { generateCareerInsight } from "./careerModule";
import { generateLearningInsight } from "./learningModule";
import { generateCollaborationInsight } from "./collaborationModule";
import { generateConflictInsight } from "./conflictModule";
import { generateRecoveryInsight } from "./recoveryModule";
import type { ProfileForInsight } from "./careerModule";

export const INSIGHT_CONTEXTS = [
  "collaboration",
  "conflict",
  "learning",
  "career",
  "recovery",
] as const;

export type InsightContext = (typeof INSIGHT_CONTEXTS)[number];

export interface InsightResult {
  id: number;
  profileId: number;
  context: InsightContext;
  explanation: string;
  suggestions: string[];
}

interface ProfileRow {
  type_code: string;
  score_vector: string | null;
  strengths: string | null;
  caution_patterns: string | null;
  collaboration_style: string | null;
  conflict_style: string | null;
  learning_style: string | null;
  career_hints: string | null;
  recovery_style: string | null;
}

interface InsightRow {
  id: number;
}

function dispatch(context: InsightContext, profile: ProfileForInsight) {
  switch (context) {
    case "collaboration": return generateCollaborationInsight(profile);
    case "conflict":      return generateConflictInsight(profile);
    case "learning":      return generateLearningInsight(profile);
    case "career":        return generateCareerInsight(profile);
    case "recovery":      return generateRecoveryInsight(profile);
  }
}

export async function generateInsight(
  db: D1Database,
  profileId: number,
  context: string
): Promise<InsightResult> {
  if (!(INSIGHT_CONTEXTS as readonly string[]).includes(context)) {
    throw new Error(`Unknown insight context: ${context}`);
  }

  const ctx = context as InsightContext;

  // Fetch profile + personality_type data
  const profileRow = await db
    .prepare(
      `SELECT p.type_code, p.score_vector, p.strengths, p.caution_patterns,
              pt.collaboration_style, pt.conflict_style, pt.learning_style,
              pt.career_hints, pt.recovery_style
       FROM profiles p
       LEFT JOIN personality_types pt ON pt.code = p.type_code
       WHERE p.id = ?`
    )
    .bind(profileId)
    .first<ProfileRow>();

  if (!profileRow) {
    throw new Error(`Profile not found: ${profileId}`);
  }

  const profile: ProfileForInsight = {
    typeCode: profileRow.type_code,
    scoreVector: profileRow.score_vector ? JSON.parse(profileRow.score_vector) : {},
    strengths: profileRow.strengths ? JSON.parse(profileRow.strengths) : [],
    cautionPatterns: profileRow.caution_patterns ? JSON.parse(profileRow.caution_patterns) : [],
    collaborationStyle: profileRow.collaboration_style,
    conflictStyle: profileRow.conflict_style,
    learningStyle: profileRow.learning_style,
    careerHints: profileRow.career_hints,
    recoveryStyle: profileRow.recovery_style,
  };

  const moduleResult = dispatch(ctx, profile);
  const enrichedExplanation = buildExplanation(moduleResult.explanation, moduleResult.suggestions);

  // UPSERT insight (ON CONFLICT(profile_id, context) DO UPDATE)
  const upsertResult = await db
    .prepare(
      `INSERT INTO insights (profile_id, context, explanation, suggestions, created_at, updated_at)
       VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
       ON CONFLICT(profile_id, context) DO UPDATE SET
         explanation = excluded.explanation,
         suggestions = excluded.suggestions,
         updated_at = CURRENT_TIMESTAMP
       RETURNING id`
    )
    .bind(
      profileId,
      ctx,
      enrichedExplanation,
      JSON.stringify(moduleResult.suggestions)
    )
    .first<InsightRow>();

  if (!upsertResult) {
    throw new Error("Insight UPSERT failed");
  }

  return {
    id: upsertResult.id,
    profileId,
    context: ctx,
    explanation: enrichedExplanation,
    suggestions: moduleResult.suggestions,
  };
}
