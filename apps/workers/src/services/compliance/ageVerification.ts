/**
 * src/services/compliance/ageVerification.ts — GREEN phase
 * Rails: N/A (신규 — cycle 8 책임)
 *
 * PIPA Article 22 / COPPA: 14세 미만 사용자 처리.
 * - signup 시 birthdate parse → 14 미만이면 거부
 * - birthdate 미입력 → 400 validation_failed
 * - 14+ → 정상 signup 허용
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
 * calculateAgeFromBirthdate(birthdate: string, referenceDate?: Date) → number
 * 생년월일 → 현재(또는 referenceDate) 나이 계산.
 */
export function calculateAgeFromBirthdate(
  birthdate: string,
  referenceDate?: Date
): number {
  const ref = referenceDate ?? new Date();
  const bd = new Date(birthdate);

  let age = ref.getFullYear() - bd.getFullYear();
  const monthDiff = ref.getMonth() - bd.getMonth();
  if (monthDiff < 0 || (monthDiff === 0 && ref.getDate() < bd.getDate())) {
    age--;
  }
  return age;
}

/**
 * verifyAge(birthdate: string) → AgeVerificationResult
 * birthdate: ISO 8601 (YYYY-MM-DD).
 * 14 미만 → eligible: false, reason: "under_minimum_age"
 * 미입력/빈문자열 → eligible: false, reason: "birthdate_required"
 */
export function verifyAge(birthdate: string | undefined | null): AgeVerificationResult {
  if (!birthdate || birthdate.trim() === "") {
    return { eligible: false, reason: "birthdate_required", minimumAge: MINIMUM_AGE_YEARS };
  }

  const age = calculateAgeFromBirthdate(birthdate);
  if (age < MINIMUM_AGE_YEARS) {
    return { eligible: false, reason: "under_minimum_age", minimumAge: MINIMUM_AGE_YEARS };
  }

  return { eligible: true };
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
