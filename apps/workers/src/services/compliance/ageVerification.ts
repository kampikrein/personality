/**
 * src/services/compliance/ageVerification.ts — RED phase stub
 * Rails: N/A (신규 — cycle 8 책임)
 *
 * PIPA Article 22 / COPPA: 14세 미만 사용자 처리.
 * - signup 시 birthdate parse → 14 미만이면 보호자 동의 또는 거부
 * - birthdate 미입력 → 400 validation_failed
 * - 14+ → 정상 signup 허용
 *
 * GREEN phase: signup route 연동 + parental_consent 흐름 (Phase 2)
 */

export const MINIMUM_AGE_YEARS = 14;

export type AgeVerificationResult =
  | { eligible: true }
  | {
      eligible: false;
      reason: "under_minimum_age" | "birthdate_required";
      minimumAge: number;
    };

/**
 * verifyAge(birthdate: string) → AgeVerificationResult
 * birthdate: ISO 8601 (YYYY-MM-DD).
 * 14 미만 → eligible: false, reason: "under_minimum_age"
 * 미입력 → eligible: false, reason: "birthdate_required"
 */
export function verifyAge(_birthdate: string | undefined | null): AgeVerificationResult {
  throw new Error("not implemented");
}

/**
 * calculateAgeFromBirthdate(birthdate: string, referenceDate?: Date) → number
 * 생년월일 → 현재(또는 referenceDate) 나이 계산.
 */
export function calculateAgeFromBirthdate(
  _birthdate: string,
  _referenceDate?: Date
): number {
  throw new Error("not implemented");
}

export interface ParentalConsentRequest {
  minorUserId?: number;
  minorSessionId?: number;
  parentEmail: string;
  parentName: string;
}

/**
 * initiateParentalConsentFlow(db, params) — Phase 2 placeholder.
 * RED phase: stub만. GREEN Phase 2에서 구현.
 */
export async function initiateParentalConsentFlow(
  _db: unknown,
  _params: ParentalConsentRequest
): Promise<{ requestId: string }> {
  throw new Error("not implemented — Phase 2 carryover");
}
