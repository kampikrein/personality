/**
 * src/db/schema.ts — Drizzle schema (GREEN phase)
 *
 * Rails server/db/schema.rb 14 tables 1:1 매핑.
 * R4 분리 컬럼 (email_hash + email_enc + encryption_version).
 * 9 JSON 컬럼, 14 FK, UNIQUE 3건 (Model Anchors 5) + 추가 UNIQUE.
 *
 * 의존성 순서:
 *   Leaf (no FK): users, personality_types, question_sets, alerts, audit_logs
 *   1-hop: anonymous_sessions (→ users), questions (→ question_sets)
 *   2-hop: assessments (→ anonymous_sessions, question_sets)
 *          consents (→ anonymous_sessions, users)
 *          deletion_requests (→ anonymous_sessions)
 *   3-hop: domain_scores (→ assessments)
 *          profiles (→ anonymous_sessions, assessments, personality_types)
 *   4-hop: insights (→ profiles)
 *          responses (→ assessments, questions)
 */

import {
  sqliteTable,
  text,
  integer,
  real,
  uniqueIndex,
} from "drizzle-orm/sqlite-core";
import { sql } from "drizzle-orm";
import type { AlertMetadata, AuditMetadata, ScoreVector, SuggestedAction } from "./types";

// ============================================================
// Leaf tables (no FK)
// ============================================================

/**
 * users — R4 분리 컬럼 (Brief 021 Decision 3 + Synthesis S-018-F1)
 * Rails: users.email → email_hash (SHA-256) + email_enc (R1 envelope JSON)
 */
export const users = sqliteTable("users", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  emailHash: text("email_hash").notNull().unique(),
  emailEnc: text("email_enc").notNull(),
  encryptionVersion: integer("encryption_version").notNull().default(1),
  displayName: text("display_name"),
  passwordDigest: text("password_digest"),
  deletedAt: text("deleted_at"),
  createdAt: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updatedAt: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
});

/**
 * personality_types — 16 MBTI types
 * JSON columns: strengths, caution_patterns
 */
export const personalityTypes = sqliteTable("personality_types", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  code: text("code").notNull().unique(),
  characterNameKo: text("character_name_ko").notNull(),
  characterNameEn: text("character_name_en").notNull(),
  summaryKo: text("summary_ko"),
  summaryEn: text("summary_en"),
  strengths: text("strengths", { mode: "json" })
    .$type<string[]>()
    .notNull()
    .default(sql`'[]'`),
  cautionPatterns: text("caution_patterns", { mode: "json" })
    .$type<string[]>()
    .notNull()
    .default(sql`'[]'`),
  collaborationStyle: text("collaboration_style"),
  conflictStyle: text("conflict_style"),
  learningStyle: text("learning_style"),
  careerHints: text("career_hints"),
  recoveryStyle: text("recovery_style"),
  createdAt: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updatedAt: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
});

/**
 * question_sets — UNIQUE: version_code
 */
export const questionSets = sqliteTable("question_sets", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  versionCode: text("version_code").unique(),
  status: text("status"),
  createdAt: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updatedAt: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
});

/**
 * alerts — JSON column: metadata
 */
export const alerts = sqliteTable("alerts", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  alertType: text("alert_type").notNull(),
  severity: text("severity").notNull().default("medium"),
  status: text("status").notNull().default("open"),
  message: text("message"),
  notes: text("notes"),
  metadata: text("metadata", { mode: "json" })
    .$type<AlertMetadata>()
    .notNull()
    .default(sql`'{}'`),
  resolvedAt: text("resolved_at"),
  createdAt: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updatedAt: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
});

/**
 * audit_logs — JSON column: metadata
 * Rails: t.bigint actor_id / resource_id → integer (SQLite에 bigint 없음)
 */
export const auditLogs = sqliteTable("audit_logs", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  action: text("action").notNull(),
  actorId: integer("actor_id"),
  actorType: text("actor_type"),
  resourceId: integer("resource_id"),
  resourceType: text("resource_type"),
  metadata: text("metadata", { mode: "json" })
    .$type<AuditMetadata>()
    .notNull()
    .default(sql`'{}'`),
  createdAt: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updatedAt: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
});

// ============================================================
// 1-hop dependencies
// ============================================================

/**
 * anonymous_sessions — FK: users (optional, Rails belongs_to :user, optional: true)
 * UNIQUE: session_token
 */
export const anonymousSessions = sqliteTable("anonymous_sessions", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  userId: integer("user_id").references(() => users.id, { onDelete: "set null" }),
  sessionToken: text("session_token").notNull().unique(),
  ipHash: text("ip_hash"),
  ipFingerprint: text("ip_fingerprint"),
  userAgentHash: text("user_agent_hash"),
  startedAt: text("started_at"),
  createdAt: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updatedAt: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
});

/**
 * questions — FK: question_sets (CASCADE)
 * UNIQUE: (question_set_id, domain, position)
 */
export const questions = sqliteTable(
  "questions",
  {
    id: integer("id").primaryKey({ autoIncrement: true }),
    questionSetId: integer("question_set_id")
      .notNull()
      .references(() => questionSets.id, { onDelete: "cascade" }),
    domain: text("domain").notNull(),
    position: integer("position").notNull(),
    bodyKo: text("body_ko").notNull(),
    bodyEn: text("body_en"),
    polarity: text("polarity").notNull().default("positive"),
    active: integer("active", { mode: "boolean" }).notNull().default(true),
    createdAt: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
    updatedAt: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  },
  (t) => ({
    uniqueQsDomainPosition: uniqueIndex(
      "index_questions_on_question_set_id_and_domain_and_position"
    ).on(t.questionSetId, t.domain, t.position),
  })
);

// ============================================================
// 2-hop dependencies
// ============================================================

/**
 * assessments — FK: anonymous_sessions (CASCADE), question_sets (CASCADE)
 */
export const assessments = sqliteTable("assessments", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  anonymousSessionId: integer("anonymous_session_id")
    .notNull()
    .references(() => anonymousSessions.id, { onDelete: "cascade" }),
  questionSetId: integer("question_set_id")
    .notNull()
    .references(() => questionSets.id, { onDelete: "cascade" }),
  status: text("status"),
  currentQuestionIndex: integer("current_question_index"),
  completionRate: real("completion_rate"),
  nonResponseRate: real("non_response_rate"),
  extremeResponseRate: real("extreme_response_rate"),
  retryToken: text("retry_token"),
  startedAt: text("started_at"),
  completedAt: text("completed_at"),
  createdAt: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updatedAt: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
});

/**
 * consents — FK: anonymous_sessions (optional), users (optional)
 * Rails: validate :has_session_or_user — 둘 다 optional
 */
export const consents = sqliteTable("consents", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  anonymousSessionId: integer("anonymous_session_id").references(
    () => anonymousSessions.id,
    { onDelete: "cascade" }
  ),
  userId: integer("user_id").references(() => users.id, { onDelete: "cascade" }),
  consentType: text("consent_type"),
  consentVersion: text("consent_version"),
  consentTextSnapshot: text("consent_text_snapshot"),
  granted: integer("granted", { mode: "boolean" }),
  grantedAt: text("granted_at"),
  revokedAt: text("revoked_at"),
  createdAt: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updatedAt: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
});

/**
 * deletion_requests — FK: anonymous_sessions (CASCADE)
 * UNIQUE: request_token
 */
export const deletionRequests = sqliteTable("deletion_requests", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  anonymousSessionId: integer("anonymous_session_id")
    .notNull()
    .references(() => anonymousSessions.id, { onDelete: "cascade" }),
  requestToken: text("request_token").notNull().unique(),
  status: text("status").notNull().default("pending"),
  slaDeadline: text("sla_deadline"),
  createdAt: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updatedAt: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
});

// ============================================================
// 3-hop dependencies
// ============================================================

/**
 * domain_scores — FK: assessments (CASCADE)
 * UNIQUE (assessment_id, domain) — Model Anchors 5, UNIQUE 1/3
 */
export const domainScores = sqliteTable(
  "domain_scores",
  {
    id: integer("id").primaryKey({ autoIncrement: true }),
    assessmentId: integer("assessment_id")
      .notNull()
      .references(() => assessments.id, { onDelete: "cascade" }),
    domain: text("domain"),
    rawScore: real("raw_score"),
    normalizedScore: real("normalized_score"),
    consistencyIndex: real("consistency_index"),
    reliabilityCoefficient: real("reliability_coefficient"),
    speedFlag: integer("speed_flag", { mode: "boolean" }),
    policyBlocked: integer("policy_blocked", { mode: "boolean" }),
    createdAt: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
    updatedAt: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  },
  (t) => ({
    uniqueAssessmentDomain: uniqueIndex(
      "index_domain_scores_on_assessment_id_and_domain"
    ).on(t.assessmentId, t.domain),
  })
);

/**
 * profiles — FK: anonymous_sessions (CASCADE), assessments (CASCADE), personality_types (CASCADE)
 * UNIQUE (assessment_id) — Model Anchors 5, UNIQUE 2/3
 * JSON columns × 4: score_vector, strengths, caution_patterns, suggested_actions
 */
export const profiles = sqliteTable(
  "profiles",
  {
    id: integer("id").primaryKey({ autoIncrement: true }),
    anonymousSessionId: integer("anonymous_session_id")
      .notNull()
      .references(() => anonymousSessions.id, { onDelete: "cascade" }),
    assessmentId: integer("assessment_id")
      .notNull()
      .references(() => assessments.id, { onDelete: "cascade" }),
    personalityTypeId: integer("personality_type_id")
      .notNull()
      .references(() => personalityTypes.id, { onDelete: "cascade" }),
    typeCode: text("type_code").notNull(),
    scoreVector: text("score_vector", { mode: "json" })
      .$type<ScoreVector>()
      .notNull()
      .default(sql`'{}'`),
    strengths: text("strengths", { mode: "json" })
      .$type<string[]>()
      .notNull()
      .default(sql`'[]'`),
    cautionPatterns: text("caution_patterns", { mode: "json" })
      .$type<string[]>()
      .notNull()
      .default(sql`'[]'`),
    suggestedActions: text("suggested_actions", { mode: "json" })
      .$type<SuggestedAction[]>()
      .notNull()
      .default(sql`'[]'`),
    policyBlocked: integer("policy_blocked", { mode: "boolean" }).default(false),
    fallbackMessage: text("fallback_message"),
    createdAt: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
    updatedAt: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  },
  (t) => ({
    uniqueAssessmentId: uniqueIndex("index_profiles_on_assessment_id").on(
      t.assessmentId
    ),
  })
);

// ============================================================
// 4-hop dependencies
// ============================================================

/**
 * insights — FK: profiles (CASCADE)
 * UNIQUE (profile_id, context) — Model Anchors 5, UNIQUE 3/3
 * JSON column: suggestions
 */
export const insights = sqliteTable(
  "insights",
  {
    id: integer("id").primaryKey({ autoIncrement: true }),
    profileId: integer("profile_id")
      .notNull()
      .references(() => profiles.id, { onDelete: "cascade" }),
    context: text("context").notNull(),
    explanation: text("explanation"),
    suggestions: text("suggestions", { mode: "json" })
      .$type<string[]>()
      .notNull()
      .default(sql`'[]'`),
    createdAt: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
    updatedAt: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  },
  (t) => ({
    uniqueProfileContext: uniqueIndex(
      "index_insights_on_profile_id_and_context"
    ).on(t.profileId, t.context),
  })
);

/**
 * responses — FK: assessments (CASCADE), questions (CASCADE)
 * UNIQUE (assessment_id, question_id)
 */
export const responses = sqliteTable(
  "responses",
  {
    id: integer("id").primaryKey({ autoIncrement: true }),
    assessmentId: integer("assessment_id")
      .notNull()
      .references(() => assessments.id, { onDelete: "cascade" }),
    questionId: integer("question_id")
      .notNull()
      .references(() => questions.id, { onDelete: "cascade" }),
    value: integer("value"),
    sequenceNumber: integer("sequence_number"),
    responseTimeMs: integer("response_time_ms"),
    createdAt: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
    updatedAt: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  },
  (t) => ({
    uniqueAssessmentQuestion: uniqueIndex(
      "index_responses_on_assessment_id_and_question_id"
    ).on(t.assessmentId, t.questionId),
  })
);
