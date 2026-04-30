/**
 * src/services/scoring/saga.ts — GREEN phase
 * R2 Hybrid Pure Saga (D1 only) — 8 step scoring pipeline.
 *
 * Phase A (steps 1-4): pure compute, no DB writes
 * Phase B (step 5+5b): D1 batch UPSERT domain_scores + UPDATE assessment status='scored'
 * Phase C (step 6): policy gate — conditional batch if blocked
 * Phase D (step 7+8): idempotent step-by-step profile UPSERT + insight UPSERT × 5
 * Phase E (step 8b): final UPDATE assessment status='completed'
 *
 * Forward-recovery: failure → compensateScoring() → status='failed'
 * Idempotency: all DB writes are UPSERT with ON CONFLICT DO UPDATE
 * Re-run guard: if status is already 'completed' or 'failed', re-run is idempotent
 */

import { calculateDomainScores } from "./domainCalculator";
import { normalizeScores } from "./normalizer";
import { classifyType } from "./typeClassifier";
import { adjustReliability } from "./reliabilityAdjuster";
import { checkPolicy } from "./policyChecker";
import { composeProfile } from "../profiles/composer";
import { generateInsight } from "../insights/contextEngine";

export type SagaStatus =
  | "submitted"
  | "scoring"
  | "scored"
  | "profiled"
  | "completed"
  | "failed";

export interface SagaRunResult {
  status: SagaStatus;
  assessmentId: number;
  profileId?: number;
  insightIds?: number[];
  failedStep?: number;
  error?: string;
}

// ─── Internal interfaces ─────────────────────────────────────────────────────

interface AssessmentStatusRow {
  status: string | null;
  anonymous_session_id: number;
}

interface ResponseRow {
  id: number;
  question_id: number;
  value: number | null;
  response_time_ms: number | null;
  sequence_number: number | null;
  domain: string;
  polarity: string;
}

const INSIGHT_CONTEXTS = ["collaboration", "conflict", "learning", "career", "recovery"] as const;

// ─── Main saga ───────────────────────────────────────────────────────────────

/**
 * runScoringPipeline(db, assessmentId) → SagaRunResult
 *
 * Idempotent guard:
 *   - 'completed': return immediately with existing result
 *   - 'failed': allow retry from scratch (reset guard at caller)
 *   - All other statuses: run the full pipeline (UPSERT semantics make this safe)
 */
export async function runScoringPipeline(
  db: D1Database,
  assessmentId: number
): Promise<SagaRunResult> {
  // ── Idempotency guard: check current status ───────────────────────────────
  const assessmentRow = await db
    .prepare("SELECT status, anonymous_session_id FROM assessments WHERE id = ?")
    .bind(assessmentId)
    .first<AssessmentStatusRow>();

  if (!assessmentRow) {
    return { status: "failed", assessmentId, error: `Assessment not found: ${assessmentId}` };
  }

  const currentStatus = assessmentRow.status as SagaStatus | null;

  // Already completed — return existing result idempotently
  if (currentStatus === "completed") {
    const profileRow = await db
      .prepare("SELECT id FROM profiles WHERE assessment_id = ?")
      .bind(assessmentId)
      .first<{ id: number }>();
    return { status: "completed", assessmentId, profileId: profileRow?.id };
  }

  try {
    // ── Phase A: pure compute (no DB writes) ────────────────────────────────
    // Load responses with question domain/polarity
    const responsesResult = await db
      .prepare(
        `SELECT r.id, r.question_id, r.value, r.response_time_ms, r.sequence_number,
                q.domain, q.polarity
         FROM responses r
         JOIN questions q ON q.id = r.question_id
         WHERE r.assessment_id = ?
         ORDER BY r.sequence_number`
      )
      .bind(assessmentId)
      .all<ResponseRow>();

    const responses = responsesResult.results;

    // Step 1: DomainCalculator
    const rawScores = calculateDomainScores({
      id: assessmentId,
      responses: responses.map((r) => ({
        value: r.value,
        polarity: r.polarity,
        domain: r.domain,
      })),
    });

    // Step 2: Normalizer
    const normalized = normalizeScores(
      rawScores,
      responses.map((r) => ({ domain: r.domain, value: r.value }))
    );

    // Step 3: TypeClassifier
    const classification = classifyType(normalized);

    // Step 4: ReliabilityAdjuster
    const reliability = adjustReliability(
      responses.map((r) => ({
        value: r.value,
        response_time_ms: r.response_time_ms,
      }))
    );

    // ── Phase B: D1 batch — domain_scores UPSERT + assessment status='scored' ──
    // Step 5 + 5b — single batch, all-or-nothing
    const domains = ["energy", "decision_making", "relationship", "recovery"] as const;

    const batchStatements = [
      ...domains.map((domain) =>
        db
          .prepare(
            `INSERT INTO domain_scores
               (assessment_id, domain, raw_score, normalized_score,
                consistency_index, reliability_coefficient, speed_flag, policy_blocked,
                created_at, updated_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
             ON CONFLICT(assessment_id, domain) DO UPDATE SET
               raw_score = excluded.raw_score,
               normalized_score = excluded.normalized_score,
               consistency_index = excluded.consistency_index,
               reliability_coefficient = excluded.reliability_coefficient,
               speed_flag = excluded.speed_flag,
               policy_blocked = 0,
               updated_at = CURRENT_TIMESTAMP`
          )
          .bind(
            assessmentId,
            domain,
            rawScores[domain],
            normalized[domain],
            reliability.consistency_index,
            reliability.reliability_coefficient,
            reliability.speed_flag ? 1 : 0
          )
      ),
      db
        .prepare(
          `UPDATE assessments SET status = 'scored', updated_at = CURRENT_TIMESTAMP
           WHERE id = ? AND status IN ('submitted', 'scoring')`
        )
        .bind(assessmentId),
    ];

    await db.batch(batchStatements);

    // ── Phase C: policy gate ─────────────────────────────────────────────────
    // Step 6 — check policy, block if needed
    const policy = checkPolicy(reliability);

    if (policy.blocked) {
      await db.batch([
        db
          .prepare(
            `UPDATE domain_scores SET policy_blocked = 1, updated_at = CURRENT_TIMESTAMP
             WHERE assessment_id = ?`
          )
          .bind(assessmentId),
        db
          .prepare(
            `UPDATE assessments SET status = 'failed', updated_at = CURRENT_TIMESTAMP
             WHERE id = ? AND status = 'scored'`
          )
          .bind(assessmentId),
        db
          .prepare(
            `INSERT INTO audit_logs (resource_type, resource_id, action, metadata, created_at, updated_at)
             VALUES ('Assessment', ?, 'scoring_blocked', ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
          )
          .bind(assessmentId, JSON.stringify({ reasons: policy.reasons })),
      ]);

      return { status: "failed", assessmentId, failedStep: 6 };
    }

    // ── Phase D: idempotent profile + insights ───────────────────────────────
    // Step 7: Profile UPSERT
    const profile = await composeProfile(db, assessmentId, classification.type_code);
    const profileId = profile.id;

    // Update assessment status to 'profiled'
    await db
      .prepare(
        `UPDATE assessments SET status = 'profiled', updated_at = CURRENT_TIMESTAMP
         WHERE id = ? AND status = 'scored'`
      )
      .bind(assessmentId)
      .run();

    // Step 8: Insight UPSERT × 5 contexts
    const insightIds: number[] = [];
    for (const ctx of INSIGHT_CONTEXTS) {
      const insight = await generateInsight(db, profileId, ctx);
      insightIds.push(insight.id);
    }

    // ── Phase E: finalize ────────────────────────────────────────────────────
    // Step 8b: assessment status='completed'
    await db
      .prepare(
        `UPDATE assessments SET status = 'completed', updated_at = CURRENT_TIMESTAMP
         WHERE id = ? AND status = 'profiled'`
      )
      .bind(assessmentId)
      .run();

    return { status: "completed", assessmentId, profileId, insightIds };
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);

    // Forward-recovery: mark as failed, preserve partial state
    await compensateScoring(db, assessmentId);

    return { status: "failed", assessmentId, error: message };
  }
}

// ─── Compensation ─────────────────────────────────────────────────────────────

/**
 * compensateScoring(db, assessmentId)
 *
 * Forward-recovery compensation:
 *   1. Mark assessment as 'failed' (idempotent — only updates non-terminal statuses)
 *   2. Write audit log entry (always, for compliance trail)
 *
 * NOTE: Profile/Insight rows are NOT deleted — idempotent retry will UPSERT them.
 * User-facing show action gates on status='completed' only.
 */
export async function compensateScoring(
  db: D1Database,
  assessmentId: number
): Promise<void> {
  // 1. Mark assessment failed (idempotent state guard)
  await db
    .prepare(
      `UPDATE assessments SET status = 'failed', updated_at = CURRENT_TIMESTAMP
       WHERE id = ? AND status IN ('submitted', 'scoring', 'scored', 'profiled')`
    )
    .bind(assessmentId)
    .run();

  // 2. Audit (always, for compliance + rollback evidence)
  await db
    .prepare(
      `INSERT INTO audit_logs (resource_type, resource_id, action, metadata, created_at, updated_at)
       VALUES ('Assessment', ?, 'scoring_compensated', ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
    )
    .bind(assessmentId, JSON.stringify({ reason: "partial_failure" }))
    .run();
}
