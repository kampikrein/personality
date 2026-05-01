/**
 * src/services/compliance/crossBorderConsent.ts — RED phase stub
 * Rails: N/A (신규 — cycle 8 책임)
 *
 * GDPR Article 46 / PIPA Article 17: 국외 이전 동의 처리.
 * - 국외 이전 고지 및 사용자 동의 기록
 * - 동의 없이 처리 시 거부 + audit_log
 * - 동의 철회 시 처리 중단 + audit_log
 *
 * GREEN phase: DB 읽기/쓰기 구현 + audit_logger 연동
 */

export interface CrossBorderConsentResult {
  success: boolean;
  consentId?: number;
  error?: string;
}

export interface CrossBorderConsentRecord {
  id: number;
  userId?: number;
  sessionId?: number;
  transferDestination: string;
  consentType: "cross_border_transfer";
  grantedAt?: string;
  revokedAt?: string;
  status: "granted" | "revoked";
}

/**
 * recordCrossBorderConsent(db, params) → CrossBorderConsentResult
 * 국외 이전 동의 기록. consents 테이블 cross_border=true 행 삽입.
 */
export async function recordCrossBorderConsent(
  _db: unknown,
  _params: {
    sessionId?: number;
    userId?: number;
    transferDestination: string;
    consentTextSnapshot: string;
    consentVersion: string;
  }
): Promise<CrossBorderConsentResult> {
  throw new Error("not implemented");
}

/**
 * revokeCrossBorderConsent(db, consentId, actorId) → CrossBorderConsentResult
 * 국외 이전 동의 철회 + audit_log 기록.
 */
export async function revokeCrossBorderConsent(
  _db: unknown,
  _consentId: number,
  _actorId?: number
): Promise<CrossBorderConsentResult> {
  throw new Error("not implemented");
}

/**
 * checkCrossBorderConsent(db, sessionId|userId) → boolean
 * 활성 국외 이전 동의 여부 반환. 없으면 false.
 */
export async function checkCrossBorderConsent(
  _db: unknown,
  _params: { sessionId?: number; userId?: number }
): Promise<boolean> {
  throw new Error("not implemented");
}
