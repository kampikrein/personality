/**
 * test/services/compliance/deletionProcessor.test.ts — RED phase
 * RSpec: server/spec/services/compliance/deletion_processor_spec.rb (12 tests)
 *
 * Contract: processDeletion(db, deletionRequestId) → DeletionResult
 * GDPR/PIPA deletion: removes all session-related data in cascade order.
 * Creates audit_log entries (at least 3).
 * Returns accurate deleted_counts.
 * On error: returns { success: false, error: message }, marks deletion_request as 'failed'.
 */

import { describe, it, expect, beforeEach } from "vitest";
import { env } from "cloudflare:test";
import { processDeletion } from "../../../src/services/compliance/deletionProcessor";

async function setupDeletionFixture(db: D1Database): Promise<{
  deletionRequestId: number;
  sessionId: number;
  assessmentId: number;
  profileId: number;
}> {
  const sessionId = 8000 + Math.floor(Math.random() * 1000);
  const assessmentId = 8000 + Math.floor(Math.random() * 1000);
  const profileId = 8000 + Math.floor(Math.random() * 1000);
  const requestToken = `del_token_${sessionId}`;

  // Create session
  await db.prepare(
    `INSERT OR IGNORE INTO anonymous_sessions (id, session_token, created_at, updated_at)
     VALUES (?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
  ).bind(sessionId, `del_session_${sessionId}`).run();

  // Create deletion_request
  await db.prepare(
    `INSERT OR IGNORE INTO deletion_requests
       (anonymous_session_id, request_token, status, created_at, updated_at)
     VALUES (?, ?, 'pending', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
  ).bind(sessionId, requestToken).run();

  const reqRow = await db.prepare(
    "SELECT id FROM deletion_requests WHERE request_token = ?"
  ).bind(requestToken).first<{ id: number }>();
  const deletionRequestId = reqRow!.id;

  // Create assessment
  await db.prepare(
    `INSERT OR IGNORE INTO assessments
       (id, anonymous_session_id, question_set_id, status, created_at, updated_at)
     VALUES (?, ?, 1, 'completed', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
  ).bind(assessmentId, sessionId).run();

  // Create questions for responses (avoid FK issue)
  const qId = 9000 + sessionId;
  await db.prepare(
    `INSERT OR IGNORE INTO questions
       (id, question_set_id, domain, position, body_ko, polarity, created_at, updated_at)
     VALUES (?, 1, 'energy', ?, 'del q', 'positive', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
  ).bind(qId, qId).run();

  // Create 5 responses
  for (let i = 0; i < 5; i++) {
    const qiId = qId + i;
    await db.prepare(
      `INSERT OR IGNORE INTO questions
         (id, question_set_id, domain, position, body_ko, polarity, created_at, updated_at)
       VALUES (?, 1, 'energy', ?, 'del q ${i}', 'positive', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
    ).bind(qiId, qiId).run();

    await db.prepare(
      `INSERT OR IGNORE INTO responses
         (assessment_id, question_id, value, sequence_number, created_at, updated_at)
       VALUES (?, ?, 3, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
    ).bind(assessmentId, qiId, i + 1).run();
  }

  // Create 4 domain scores
  for (const domain of ["energy", "decision_making", "relationship", "recovery"]) {
    await db.prepare(
      `INSERT OR IGNORE INTO domain_scores
         (assessment_id, domain, raw_score, normalized_score, consistency_index,
          reliability_coefficient, speed_flag, policy_blocked, created_at, updated_at)
       VALUES (?, ?, 15, 60.0, 0.7, 0.8, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
    ).bind(assessmentId, domain).run();
  }

  // Get personality_type id
  const ptRow = await db.prepare(
    "SELECT id FROM personality_types WHERE code = 'ENFP' LIMIT 1"
  ).first<{ id: number }>();
  const ptId = ptRow?.id ?? 1;

  // Create profile
  try {
    await db.prepare(
      `INSERT INTO profiles
         (id, anonymous_session_id, assessment_id, personality_type_id, type_code,
          score_vector, strengths, caution_patterns, suggested_actions, created_at, updated_at)
       VALUES (?, ?, ?, ?, 'ENFP', '{}', '[]', '[]', '[]', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
    ).bind(profileId, sessionId, assessmentId, ptId).run();
  } catch (e) {
    // Ignore if already exists
  }

  // Create 5 insights
  for (const ctx of ["collaboration", "conflict", "learning", "career", "recovery"]) {
    await db.prepare(
      `INSERT OR IGNORE INTO insights
         (profile_id, context, explanation, suggestions, created_at, updated_at)
       VALUES (?, ?, 'test explanation', '[]', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
    ).bind(profileId, ctx).run();
  }

  // Create consent
  await db.prepare(
    `INSERT OR IGNORE INTO consents
       (anonymous_session_id, consent_type, granted, created_at, updated_at)
     VALUES (?, 'terms', 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
  ).bind(sessionId).run();

  return { deletionRequestId, sessionId, assessmentId, profileId };
}

describe("DeletionProcessor (RED phase)", () => {
  describe("with a full assessment chain", () => {
    it("returns success", async () => {
      const { deletionRequestId } = await setupDeletionFixture(env.DB);
      const result = await processDeletion(env.DB, deletionRequestId);
      expect(result.success).toBe(true);
    });

    it("deletes all responses", async () => {
      const { deletionRequestId, assessmentId } = await setupDeletionFixture(env.DB);
      await processDeletion(env.DB, deletionRequestId);
      const count = await env.DB.prepare(
        "SELECT COUNT(*) as cnt FROM responses WHERE assessment_id = ?"
      ).bind(assessmentId).first<{ cnt: number }>();
      expect(count?.cnt).toBe(0);
    });

    it("deletes all domain scores", async () => {
      const { deletionRequestId, assessmentId } = await setupDeletionFixture(env.DB);
      await processDeletion(env.DB, deletionRequestId);
      const count = await env.DB.prepare(
        "SELECT COUNT(*) as cnt FROM domain_scores WHERE assessment_id = ?"
      ).bind(assessmentId).first<{ cnt: number }>();
      expect(count?.cnt).toBe(0);
    });

    it("deletes all insights (via profile cascade)", async () => {
      const { deletionRequestId, profileId } = await setupDeletionFixture(env.DB);
      await processDeletion(env.DB, deletionRequestId);
      const count = await env.DB.prepare(
        "SELECT COUNT(*) as cnt FROM insights WHERE profile_id = ?"
      ).bind(profileId).first<{ cnt: number }>();
      expect(count?.cnt).toBe(0);
    });

    it("deletes the profile", async () => {
      const { deletionRequestId, assessmentId } = await setupDeletionFixture(env.DB);
      await processDeletion(env.DB, deletionRequestId);
      const count = await env.DB.prepare(
        "SELECT COUNT(*) as cnt FROM profiles WHERE assessment_id = ?"
      ).bind(assessmentId).first<{ cnt: number }>();
      expect(count?.cnt).toBe(0);
    });

    it("deletes assessments", async () => {
      const { deletionRequestId, sessionId } = await setupDeletionFixture(env.DB);
      await processDeletion(env.DB, deletionRequestId);
      const count = await env.DB.prepare(
        "SELECT COUNT(*) as cnt FROM assessments WHERE anonymous_session_id = ?"
      ).bind(sessionId).first<{ cnt: number }>();
      expect(count?.cnt).toBe(0);
    });

    it("deletes consents", async () => {
      const { deletionRequestId, sessionId } = await setupDeletionFixture(env.DB);
      await processDeletion(env.DB, deletionRequestId);
      const count = await env.DB.prepare(
        "SELECT COUNT(*) as cnt FROM consents WHERE anonymous_session_id = ?"
      ).bind(sessionId).first<{ cnt: number }>();
      expect(count?.cnt).toBe(0);
    });

    it("deletes the anonymous session", async () => {
      const { deletionRequestId, sessionId } = await setupDeletionFixture(env.DB);
      await processDeletion(env.DB, deletionRequestId);
      const row = await env.DB.prepare(
        "SELECT id FROM anonymous_sessions WHERE id = ?"
      ).bind(sessionId).first<{ id: number }>();
      expect(row).toBeNull();
    });

    it("creates audit log entries (at least 3)", async () => {
      const { deletionRequestId, sessionId } = await setupDeletionFixture(env.DB);
      const countBefore = await env.DB.prepare(
        "SELECT COUNT(*) as cnt FROM audit_logs"
      ).first<{ cnt: number }>();
      const before = countBefore?.cnt ?? 0;

      await processDeletion(env.DB, deletionRequestId);

      const countAfter = await env.DB.prepare(
        "SELECT COUNT(*) as cnt FROM audit_logs"
      ).first<{ cnt: number }>();
      expect((countAfter?.cnt ?? 0) - before).toBeGreaterThanOrEqual(3);
    });

    it("returns accurate deleted_counts", async () => {
      const { deletionRequestId } = await setupDeletionFixture(env.DB);
      const result = await processDeletion(env.DB, deletionRequestId);
      // 5 responses, 4 domain_scores, 5 insights, 1 profile, 1 assessment, 1 consent, 1 session
      expect(result.deleted_counts.responses).toBe(5);
      expect(result.deleted_counts.domain_scores).toBe(4);
      expect(result.deleted_counts.insights).toBe(5);
      expect(result.deleted_counts.profiles).toBe(1);
      expect(result.deleted_counts.assessments).toBe(1);
      expect(result.deleted_counts.consents).toBe(1);
      expect(result.deleted_counts.anonymous_sessions).toBe(1);
    });
  });

  describe("with no assessments (minimal session)", () => {
    it("still succeeds", async () => {
      const sessionId = 8500 + Math.floor(Math.random() * 500);
      const requestToken = `min_del_${sessionId}`;

      await env.DB.prepare(
        `INSERT OR IGNORE INTO anonymous_sessions (id, session_token, created_at, updated_at)
         VALUES (?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
      ).bind(sessionId, `min_session_${sessionId}`).run();

      await env.DB.prepare(
        `INSERT OR IGNORE INTO deletion_requests
           (anonymous_session_id, request_token, status, created_at, updated_at)
         VALUES (?, ?, 'pending', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
      ).bind(sessionId, requestToken).run();

      await env.DB.prepare(
        `INSERT OR IGNORE INTO consents
           (anonymous_session_id, consent_type, granted, created_at, updated_at)
         VALUES (?, 'terms', 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
      ).bind(sessionId).run();

      const reqRow = await env.DB.prepare(
        "SELECT id FROM deletion_requests WHERE request_token = ?"
      ).bind(requestToken).first<{ id: number }>();
      const deletionRequestId = reqRow!.id;

      const result = await processDeletion(env.DB, deletionRequestId);
      expect(result.success).toBe(true);
    });
  });
});
