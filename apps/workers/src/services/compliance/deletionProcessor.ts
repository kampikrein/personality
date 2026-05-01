/**
 * src/services/compliance/deletionProcessor.ts — GREEN phase
 * Rails: server/app/services/compliance/deletion_processor.rb
 *
 * GDPR/PIPA data deletion: removes all session-related data in cascade order.
 * Creates audit_log entries for compliance trail.
 * Returns accurate deleted_counts.
 */

export interface DeletionResult {
  success: boolean;
  deleted_counts: {
    responses: number;
    domain_scores: number;
    insights: number;
    profiles: number;
    assessments: number;
    consents: number;
    anonymous_sessions: number;
  };
  error?: string;
}

interface DeletionRequestRow {
  id: number;
  anonymous_session_id: number;
  status: string;
}

interface AssessmentRow {
  id: number;
}

interface ProfileRow {
  id: number;
}

/**
 * processDeletion(db, deletionRequestId) → DeletionResult
 *
 * Cascade deletion order (leaf → root, FK-safe):
 *   responses → domain_scores → insights → profiles → assessments → consents → anonymous_sessions
 *
 * Audit log entries created:
 *   1. deletion_started
 *   2. data_deleted
 *   3. session_deleted
 *   (≥ 3 entries as per spec)
 */
export async function processDeletion(
  db: D1Database,
  deletionRequestId: number
): Promise<DeletionResult> {
  const counts: DeletionResult["deleted_counts"] = {
    responses: 0,
    domain_scores: 0,
    insights: 0,
    profiles: 0,
    assessments: 0,
    consents: 0,
    anonymous_sessions: 0,
  };

  try {
    // Load deletion request
    const req = await db
      .prepare("SELECT id, anonymous_session_id, status FROM deletion_requests WHERE id = ?")
      .bind(deletionRequestId)
      .first<DeletionRequestRow>();

    if (!req) {
      return {
        success: false,
        deleted_counts: counts,
        error: `DeletionRequest not found: ${deletionRequestId}`,
      };
    }

    const sessionId = req.anonymous_session_id;

    // Audit: deletion_processed (cycle 8 통일 — was: deletion_started)
    await db
      .prepare(
        `INSERT INTO audit_logs (resource_type, resource_id, action, metadata, created_at, updated_at)
         VALUES ('deletion_request', ?, 'deletion_processed', '{}', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
      )
      .bind(deletionRequestId)
      .run();

    // Find all assessments for session
    const assessmentsResult = await db
      .prepare("SELECT id FROM assessments WHERE anonymous_session_id = ?")
      .bind(sessionId)
      .all<AssessmentRow>();

    const assessmentIds = assessmentsResult.results.map((r) => r.id);

    // Delete per-assessment data
    for (const assessmentId of assessmentIds) {
      // Find profiles for this assessment
      const profilesResult = await db
        .prepare("SELECT id FROM profiles WHERE assessment_id = ?")
        .bind(assessmentId)
        .all<ProfileRow>();

      const profileIds = profilesResult.results.map((r) => r.id);

      // Delete insights (per profile)
      for (const profileId of profileIds) {
        const delInsights = await db
          .prepare("DELETE FROM insights WHERE profile_id = ?")
          .bind(profileId)
          .run();
        counts.insights += delInsights.meta.changes ?? 0;
      }

      // Delete profiles
      const delProfiles = await db
        .prepare("DELETE FROM profiles WHERE assessment_id = ?")
        .bind(assessmentId)
        .run();
      counts.profiles += delProfiles.meta.changes ?? 0;

      // Delete responses
      const delResponses = await db
        .prepare("DELETE FROM responses WHERE assessment_id = ?")
        .bind(assessmentId)
        .run();
      counts.responses += delResponses.meta.changes ?? 0;

      // Delete domain_scores
      const delDomainScores = await db
        .prepare("DELETE FROM domain_scores WHERE assessment_id = ?")
        .bind(assessmentId)
        .run();
      counts.domain_scores += delDomainScores.meta.changes ?? 0;
    }

    // Delete assessments
    const delAssessments = await db
      .prepare("DELETE FROM assessments WHERE anonymous_session_id = ?")
      .bind(sessionId)
      .run();
    counts.assessments += delAssessments.meta.changes ?? 0;

    // Delete consents
    const delConsents = await db
      .prepare("DELETE FROM consents WHERE anonymous_session_id = ?")
      .bind(sessionId)
      .run();
    counts.consents += delConsents.meta.changes ?? 0;

    // Audit: data_deleted
    await db
      .prepare(
        `INSERT INTO audit_logs (resource_type, resource_id, action, metadata, created_at, updated_at)
         VALUES ('AnonymousSession', ?, 'data_deleted', ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
      )
      .bind(sessionId, JSON.stringify(counts))
      .run();

    // Count before deleting anonymous_session (for accurate reporting)
    const sessionCount = await db
      .prepare("SELECT COUNT(*) as cnt FROM anonymous_sessions WHERE id = ?")
      .bind(sessionId)
      .first<{ cnt: number }>();
    const sessionExisted = sessionCount?.cnt ?? 0;

    // Mark deletion_request as completed before session deletion.
    // deletion_requests FK is SET NULL (test env) or CASCADE (prod migration).
    // Setting completed status first preserves audit trail in both cases.
    await db
      .prepare(
        "UPDATE deletion_requests SET status = 'completed', updated_at = CURRENT_TIMESTAMP WHERE id = ?"
      )
      .bind(deletionRequestId)
      .run();

    // Delete anonymous_session
    await db
      .prepare("DELETE FROM anonymous_sessions WHERE id = ?")
      .bind(sessionId)
      .run();
    counts.anonymous_sessions += sessionExisted;

    // Audit: session_deleted
    await db
      .prepare(
        `INSERT INTO audit_logs (resource_type, resource_id, action, metadata, created_at, updated_at)
         VALUES ('AnonymousSession', ?, 'session_deleted', '{}', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
      )
      .bind(sessionId)
      .run();

    return { success: true, deleted_counts: counts };
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);

    // Mark deletion_request as failed
    try {
      await db
        .prepare("UPDATE deletion_requests SET status = 'failed', updated_at = CURRENT_TIMESTAMP WHERE id = ?")
        .bind(deletionRequestId)
        .run();
    } catch {
      // best-effort
    }

    return {
      success: false,
      deleted_counts: counts,
      error: message,
    };
  }
}
