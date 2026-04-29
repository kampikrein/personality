/**
 * src/services/scoring/saga.ts — RED phase stub
 * R2 Hybrid Pure Saga (D1 only) — 8 step scoring pipeline.
 *
 * Phase A (steps 1-4): pure compute, no DB writes
 * Phase B (step 5+5b): D1 batch UPSERT domain_scores + UPDATE assessment status='scored'
 * Phase C (step 6): policy gate — conditional batch if blocked
 * Phase D (step 7+8): idempotent step-by-step profile UPSERT + insight UPSERT × 5
 * Phase E (step 8b): final UPDATE assessment status='completed'
 */

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

export async function runScoringPipeline(
  _db: unknown,
  _assessmentId: number
): Promise<SagaRunResult> {
  throw new Error("not implemented");
}

export async function compensateScoring(
  _db: unknown,
  _assessmentId: number
): Promise<void> {
  throw new Error("not implemented");
}
