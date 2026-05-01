/**
 * src/services/compliance/crossBorderConsent.ts — GREEN phase
 * Rails: N/A (신규 — cycle 8 책임)
 *
 * GDPR Article 46 / PIPA Article 17: 국외 이전 동의 처리.
 * consents 테이블 재사용 (consent_type = 'cross_border_transfer').
 */

import { auditLog } from "./auditLogger";

export interface CrossBorderConsentResult {
  success: boolean;
  consentId?: number;
  error?: string;
}

/**
 * recordCrossBorderConsent(db, params) → CrossBorderConsentResult
 * consents 테이블에 consent_type='cross_border_transfer' 행 삽입 + audit_log.
 */
export async function recordCrossBorderConsent(
  db: D1Database,
  params: {
    sessionId?: number;
    userId?: number;
    transferDestination: string;
    consentTextSnapshot: string;
    consentVersion: string;
  }
): Promise<CrossBorderConsentResult> {
  const { sessionId, userId, transferDestination, consentTextSnapshot, consentVersion } = params;

  await db
    .prepare(
      `INSERT INTO consents (anonymous_session_id, user_id, consent_type, consent_version, consent_text_snapshot, granted, granted_at, created_at, updated_at)
       VALUES (?, ?, 'cross_border_transfer', ?, ?, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
    )
    .bind(sessionId ?? null, userId ?? null, consentVersion, consentTextSnapshot)
    .run();

  const row = await db
    .prepare("SELECT last_insert_rowid() as id")
    .first<{ id: number }>();
  const consentId = row!.id;

  // audit_log
  await auditLog(db, {
    resourceType: "consent",
    resourceId: consentId,
    action: "cross_border_consent_granted",
    actorType: sessionId ? "user" : "anonymous",
    actorId: sessionId ?? userId,
    metadata: {
      transfer_destination: transferDestination,
      consent_version: consentVersion,
    },
  });

  return { success: true, consentId };
}

/**
 * revokeCrossBorderConsent(db, consentId, actorId?) → CrossBorderConsentResult
 * consents 테이블에서 revoked_at 설정 + audit_log.
 */
export async function revokeCrossBorderConsent(
  db: D1Database,
  consentId: number,
  actorId?: number
): Promise<CrossBorderConsentResult> {
  await db
    .prepare(
      "UPDATE consents SET revoked_at = CURRENT_TIMESTAMP, granted = 0, updated_at = CURRENT_TIMESTAMP WHERE id = ? AND consent_type = 'cross_border_transfer'"
    )
    .bind(consentId)
    .run();

  await auditLog(db, {
    resourceType: "consent",
    resourceId: consentId,
    action: "cross_border_consent_revoked",
    actorType: "user",
    actorId: actorId,
    metadata: {},
  });

  return { success: true, consentId };
}

/**
 * checkCrossBorderConsent(db, { sessionId?, userId? }) → boolean
 * 활성 국외 이전 동의 여부 반환. revoked_at IS NULL인 행이 존재하면 true.
 */
export async function checkCrossBorderConsent(
  db: D1Database,
  params: { sessionId?: number; userId?: number }
): Promise<boolean> {
  const { sessionId, userId } = params;

  let sql: string;
  let bindVal: number;

  if (sessionId != null) {
    sql = "SELECT id FROM consents WHERE anonymous_session_id = ? AND consent_type = 'cross_border_transfer' AND revoked_at IS NULL AND granted = 1 LIMIT 1";
    bindVal = sessionId;
  } else if (userId != null) {
    sql = "SELECT id FROM consents WHERE user_id = ? AND consent_type = 'cross_border_transfer' AND revoked_at IS NULL AND granted = 1 LIMIT 1";
    bindVal = userId;
  } else {
    return false;
  }

  const row = await db
    .prepare(sql)
    .bind(bindVal)
    .first<{ id: number }>();

  return row != null;
}
