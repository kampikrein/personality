/**
 * src/services/compliance/auditLogger.ts — GREEN phase
 * Rails: ApplicationRecord callbacks + AuditLog model
 *
 * 표준 audit logging helper. 모든 민감 작업에서 호출.
 * cycle 3 deletionProcessor.ts가 직접 INSERT하는 패턴을 중앙화.
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

export interface AuditLogEntry {
  id: number;
  action: string;
  actorId?: number | string;
  actorType?: string;
  resourceId?: number | string;
  resourceType?: string;
  metadata?: Record<string, unknown>;
  createdAt: string;
  updatedAt: string;
}

/**
 * auditLog(db, params) → { id: number }
 * audit_logs 테이블에 행 삽입. 실패 시 throw.
 */
export async function auditLog(
  db: D1Database,
  params: AuditLogParams
): Promise<{ id: number }> {
  const {
    resourceType,
    resourceId,
    action,
    actorType,
    actorId,
    metadata = {},
    ipAddress,
  } = params;

  // metadata에 ip + timestamp 보강
  const enrichedMeta: Record<string, unknown> = {
    ...metadata,
  };
  if (ipAddress && !enrichedMeta.ip) {
    enrichedMeta.ip = ipAddress;
  }
  if (!enrichedMeta.timestamp) {
    enrichedMeta.timestamp = new Date().toISOString();
  }

  const metaJson = JSON.stringify(enrichedMeta);
  const resourceIdNum =
    resourceId != null ? Number(resourceId) || null : null;
  const actorIdNum =
    actorId != null ? Number(actorId) || null : null;

  await db
    .prepare(
      `INSERT INTO audit_logs (resource_type, resource_id, action, actor_type, actor_id, metadata, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
    )
    .bind(
      resourceType,
      resourceIdNum,
      action,
      actorType ?? null,
      actorIdNum,
      metaJson
    )
    .run();

  const row = await db
    .prepare("SELECT last_insert_rowid() as id")
    .first<{ id: number }>();

  return { id: row!.id };
}

/**
 * getAuditLogs(db, filter) → AuditLogEntry[]
 * admin 조회용. filter: resourceType, action, actorId, since, limit, offset.
 */
export async function getAuditLogs(
  db: D1Database,
  filter?: {
    resourceType?: string;
    action?: string;
    actorId?: number | string;
    since?: string;
    limit?: number;
    offset?: number;
  }
): Promise<AuditLogEntry[]> {
  const conditions: string[] = [];
  const binds: (string | number | null)[] = [];

  if (filter?.resourceType) {
    conditions.push("resource_type = ?");
    binds.push(filter.resourceType);
  }
  if (filter?.action) {
    conditions.push("action = ?");
    binds.push(filter.action);
  }
  if (filter?.actorId != null) {
    conditions.push("actor_id = ?");
    binds.push(Number(filter.actorId));
  }
  if (filter?.since) {
    conditions.push("datetime(created_at) >= datetime(?)");
    binds.push(filter.since);
  }

  const where = conditions.length > 0 ? `WHERE ${conditions.join(" AND ")}` : "";
  const limit = filter?.limit ?? 50;
  const offset = filter?.offset ?? 0;

  const sql = `SELECT id, action, actor_id, actor_type, resource_id, resource_type, metadata, created_at, updated_at
               FROM audit_logs ${where} ORDER BY id DESC LIMIT ? OFFSET ?`;
  binds.push(limit, offset);

  const stmt = db.prepare(sql);
  const result = await stmt.bind(...binds).all<{
    id: number;
    action: string;
    actor_id: number | null;
    actor_type: string | null;
    resource_id: number | null;
    resource_type: string | null;
    metadata: string | null;
    created_at: string;
    updated_at: string;
  }>();

  return result.results.map((row) => ({
    id: row.id,
    action: row.action,
    actorId: row.actor_id ?? undefined,
    actorType: row.actor_type ?? undefined,
    resourceId: row.resource_id ?? undefined,
    resourceType: row.resource_type ?? undefined,
    metadata: row.metadata ? (JSON.parse(row.metadata) as Record<string, unknown>) : undefined,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  }));
}
