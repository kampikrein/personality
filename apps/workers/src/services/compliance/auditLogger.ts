/**
 * src/services/compliance/auditLogger.ts — RED phase stub
 * Rails: ApplicationRecord callbacks + AuditLog model
 *
 * 표준 audit logging helper. 모든 민감 작업에서 호출.
 * cycle 3 deletionProcessor.ts가 직접 INSERT하는 패턴을 중앙화.
 *
 * GREEN phase: DB INSERT 구현. 모든 service에서 auditLog(env.DB, ...) 호출.
 */

export type AuditAction =
  | "consent_granted"
  | "consent_revoked"
  | "cross_border_consent_granted"
  | "cross_border_consent_revoked"
  | "deletion_requested"
  | "deletion_processed"
  | "deletion_failed"
  | "account_created"
  | "account_updated"
  | "password_reset"
  | "login_failed"
  | "login_success"
  | "assessment_invalidated"
  | "under_age_signup_blocked";

export interface AuditLogParams {
  resourceType: string;
  resourceId?: number | string;
  action: AuditAction | string;
  actorType?: "user" | "admin" | "system" | "anonymous";
  actorId?: number | string;
  metadata?: Record<string, unknown>;
  ipAddress?: string;
}

export interface AuditLogEntry extends AuditLogParams {
  id: number;
  createdAt: string;
  updatedAt: string;
}

/**
 * auditLog(db, params) → { id: number }
 * audit_logs 테이블에 행 삽입. 실패 시 throw.
 * immutable: UPDATE/DELETE 금지 (schema trigger 또는 app-level).
 */
export async function auditLog(
  _db: unknown,
  _params: AuditLogParams
): Promise<{ id: number }> {
  throw new Error("not implemented");
}

/**
 * getAuditLogs(db, filter) → AuditLogEntry[]
 * admin 조회용. filter: resourceType, action, actorId, since, limit, offset.
 */
export async function getAuditLogs(
  _db: unknown,
  _filter?: {
    resourceType?: string;
    action?: string;
    actorId?: number | string;
    since?: string;
    limit?: number;
    offset?: number;
  }
): Promise<AuditLogEntry[]> {
  throw new Error("not implemented");
}
