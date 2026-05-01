/**
 * test/compliance/age_verification.test.ts — RED phase
 * Cycle 8: Compliance GDPR/PIPA (신규 책임)
 *
 * 14세 미만 처리 흐름:
 *   1. verifyAge(birthdate) → 14 미만: eligible false
 *   2. verifyAge(birthdate) → 14+: eligible true
 *   3. verifyAge(undefined) → eligible false, reason: birthdate_required
 *   4. calculateAgeFromBirthdate 정확도
 *   5. signup 시 birthdate → 14 미만 → 400 + audit_log
 *   6. initiateParentalConsentFlow — Phase 2 placeholder
 *
 * DB 의존: cycle 2 schema (audit_logs, users)
 * GREEN phase: ageVerification.ts 구현 + accounts route 연동 후 pass.
 */

import { describe, it, expect } from "vitest";
import { env } from "cloudflare:test";
import {
  verifyAge,
  calculateAgeFromBirthdate,
  MINIMUM_AGE_YEARS,
  initiateParentalConsentFlow,
} from "../../src/services/compliance/ageVerification";
import { accountsRouter } from "../../src/api/routes/public/accounts";

describe("Compliance — Age Verification (신규 책임)", () => {
  describe("verifyAge — pure function", () => {
    it("returns eligible: true for 14-year-old", () => {
      const refDate = new Date("2026-01-01");
      const birthdate = "2012-01-01"; // 정확히 14세
      const result = verifyAge(birthdate);
      // GREEN phase: eligible true
      expect(result.eligible).toBe(true);
    });

    it("returns eligible: true for 20-year-old", () => {
      const birthdate = "2006-01-01"; // 20세
      const result = verifyAge(birthdate);
      expect(result.eligible).toBe(true);
    });

    it("returns eligible: false for 13-year-old with reason under_minimum_age", () => {
      const birthdate = "2013-06-15"; // 2026년 기준 12~13세
      const result = verifyAge(birthdate);
      expect(result.eligible).toBe(false);
      if (!result.eligible) {
        expect(result.reason).toBe("under_minimum_age");
        expect(result.minimumAge).toBe(MINIMUM_AGE_YEARS);
      }
    });

    it("returns eligible: false for newborn", () => {
      const birthdate = "2025-12-01"; // 0세
      const result = verifyAge(birthdate);
      expect(result.eligible).toBe(false);
      if (!result.eligible) {
        expect(result.reason).toBe("under_minimum_age");
      }
    });

    it("returns eligible: false with reason birthdate_required for undefined", () => {
      const result = verifyAge(undefined);
      expect(result.eligible).toBe(false);
      if (!result.eligible) {
        expect(result.reason).toBe("birthdate_required");
      }
    });

    it("returns eligible: false with reason birthdate_required for null", () => {
      const result = verifyAge(null);
      expect(result.eligible).toBe(false);
      if (!result.eligible) {
        expect(result.reason).toBe("birthdate_required");
      }
    });

    it("returns eligible: false with reason birthdate_required for empty string", () => {
      const result = verifyAge("");
      expect(result.eligible).toBe(false);
      if (!result.eligible) {
        expect(result.reason).toBe("birthdate_required");
      }
    });
  });

  describe("calculateAgeFromBirthdate — pure function", () => {
    it("calculates age correctly for birthday today (just turned 14)", () => {
      const ref = new Date("2026-04-29");
      const birthdate = "2012-04-29"; // 정확히 14세
      const age = calculateAgeFromBirthdate(birthdate, ref);
      expect(age).toBe(14);
    });

    it("calculates age correctly for birthday tomorrow (still 13)", () => {
      const ref = new Date("2026-04-29");
      const birthdate = "2012-04-30"; // 내일이 14세 생일
      const age = calculateAgeFromBirthdate(birthdate, ref);
      expect(age).toBe(13);
    });

    it("calculates age correctly for 25 years", () => {
      const ref = new Date("2026-01-01");
      const birthdate = "2001-01-01";
      const age = calculateAgeFromBirthdate(birthdate, ref);
      expect(age).toBe(25);
    });

    it("uses current date when referenceDate is not provided", () => {
      const birthdate = "2000-01-01";
      const age = calculateAgeFromBirthdate(birthdate);
      expect(age).toBeGreaterThan(20);
    });
  });

  describe("signup route — birthdate validation", () => {
    it("returns 400 validation_failed when birthdate is missing", async () => {
      const db = env.DB;

      const req = new Request("http://localhost/", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          email: "nobirthdate@example.com",
          password: "password123",
          // birthdate 없음
        }),
      });

      const res = await accountsRouter.fetch(req, { DB: db });
      // GREEN phase: birthdate 필수 → 400
      expect(res.status).toBe(400);

      const body = (await res.json()) as {
        success: boolean;
        error: { code: string };
      };
      expect(body.success).toBe(false);
      expect(body.error.code).toBe("validation_failed");
    });

    it("returns 403 with under_age_blocked when 14 미만 birthdate provided", async () => {
      const db = env.DB;

      const underAgeBirthdate = "2015-06-15"; // 10~11세

      const req = new Request("http://localhost/", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          email: "underage@example.com",
          password: "password123",
          birthdate: underAgeBirthdate,
        }),
      });

      const res = await accountsRouter.fetch(req, { DB: db });
      // GREEN phase: 14 미만 → 403 under_age_blocked
      expect(res.status).toBe(403);

      const body = (await res.json()) as {
        success: boolean;
        error: { code: string };
      };
      expect(body.error.code).toBe("under_age_blocked");
    });

    it("records audit_log with under_age_signup_blocked action when minor attempts signup", async () => {
      const db = env.DB;

      const underAgeBirthdate = "2016-01-01";

      const req = new Request("http://localhost/", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          email: "minor@example.com",
          password: "password123",
          birthdate: underAgeBirthdate,
        }),
      });

      await accountsRouter.fetch(req, { DB: db });

      const auditRow = await db
        .prepare(
          "SELECT * FROM audit_logs WHERE action = 'under_age_signup_blocked' ORDER BY id DESC LIMIT 1"
        )
        .first<{ id: number; action: string; metadata: string }>();

      expect(auditRow).not.toBeNull();
      expect(auditRow?.action).toBe("under_age_signup_blocked");
    });

    it("allows signup for 14+ with birthdate provided", async () => {
      const db = env.DB;

      const adultBirthdate = "2000-01-01"; // 26세

      const req = new Request("http://localhost/", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          email: `adult_${Date.now()}@example.com`,
          password: "password123",
          birthdate: adultBirthdate,
        }),
      });

      const res = await accountsRouter.fetch(req, { DB: db });
      // GREEN phase: 정상 signup → 201
      expect(res.status).toBe(201);
    });
  });

  describe("initiateParentalConsentFlow — Phase 2 placeholder", () => {
    it("throws 'not implemented' for Phase 2 carryover", async () => {
      const db = env.DB;

      await expect(
        initiateParentalConsentFlow(db, {
          minorSessionId: 1,
          parentEmail: "parent@example.com",
          parentName: "Parent Name",
        })
      ).rejects.toThrow(/not implemented/i);
    });
  });
});
