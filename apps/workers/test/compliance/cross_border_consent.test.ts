/**
 * test/compliance/cross_border_consent.test.ts — RED phase
 * Cycle 8: Compliance GDPR/PIPA (신규 책임)
 *
 * 국외 이전 고지·동의 흐름:
 *   1. POST /api/cross_border_consents → 동의 기록 (consent row)
 *   2. 동의 없이 데이터 처리 시도 → 거부 + audit_log
 *   3. 동의 철회 → 영향 (처리 중단 표시 + audit_log)
 *   4. crossBorderConsentsRouter export 확인
 *   5. recordCrossBorderConsent / revokeCrossBorderConsent / checkCrossBorderConsent 서비스 계약
 *
 * DB 의존: cycle 2 schema (consents, audit_logs)
 * GREEN phase: crossBorderConsent.ts 구현 + route 연동 + 0002 migration (cross_border 컬럼) 후 pass.
 */

import { describe, it, expect } from "vitest";
import { env } from "cloudflare:test";
import { crossBorderConsentsRouter } from "../../src/api/routes/public/cross_border_consents";
import {
  recordCrossBorderConsent,
  revokeCrossBorderConsent,
  checkCrossBorderConsent,
} from "../../src/services/compliance/crossBorderConsent";

describe("Compliance — Cross-Border Consent (신규 책임)", () => {
  describe("crossBorderConsentsRouter — route export", () => {
    it("crossBorderConsentsRouter is defined and exported", () => {
      expect(crossBorderConsentsRouter).toBeDefined();
    });

    it("POST / → 201 with consent record", async () => {
      const db = env.DB;

      const req = new Request("http://localhost/", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-Session-Token": "test-session-token",
        },
        body: JSON.stringify({
          transferDestination: "AWS ap-northeast-1 (Japan)",
          consentVersion: "1.0",
          consentTextSnapshot:
            "귀하의 데이터는 일본 AWS 서버로 이전될 수 있습니다. 동의하십니까?",
        }),
      });

      const res = await crossBorderConsentsRouter.fetch(req, { DB: db });
      expect(res.status).toBe(201);

      const body = (await res.json()) as {
        success: boolean;
        data: { id: number; consentType: string; status: string };
      };
      expect(body.success).toBe(true);
      expect(body.data.consentType).toBe("cross_border_transfer");
      expect(body.data.status).toBe("granted");
    });

    it("DELETE /:id → 200 revokes cross-border consent", async () => {
      const db = env.DB;

      // 먼저 동의 생성
      const createReq = new Request("http://localhost/", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-Session-Token": "test-session-token",
        },
        body: JSON.stringify({
          transferDestination: "GCP asia-east1 (Taiwan)",
          consentVersion: "1.0",
          consentTextSnapshot: "Cross-border transfer consent.",
        }),
      });
      const createRes = await crossBorderConsentsRouter.fetch(createReq, { DB: db });
      const createBody = (await createRes.json()) as {
        success: boolean;
        data: { id: number };
      };
      const consentId = createBody.data.id;

      // 철회
      const deleteReq = new Request(`http://localhost/${consentId}`, {
        method: "DELETE",
        headers: { "X-Session-Token": "test-session-token" },
      });
      const deleteRes = await crossBorderConsentsRouter.fetch(deleteReq, { DB: db });
      expect(deleteRes.status).toBe(200);
    });

    it("POST without auth → 401", async () => {
      const db = env.DB;

      const req = new Request("http://localhost/", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          transferDestination: "AWS us-east-1 (US)",
          consentVersion: "1.0",
          consentTextSnapshot: "Transfer to US.",
        }),
      });

      const res = await crossBorderConsentsRouter.fetch(req, { DB: db });
      expect(res.status).toBe(401);
    });
  });

  describe("recordCrossBorderConsent service", () => {
    it("inserts consent row and returns consentId", async () => {
      const db = env.DB;

      const result = await recordCrossBorderConsent(db, {
        sessionId: 1,
        transferDestination: "AWS ap-southeast-1 (Singapore)",
        consentTextSnapshot: "Data may be transferred to Singapore.",
        consentVersion: "1.0",
      });

      expect(result.success).toBe(true);
      expect(result.consentId).toBeGreaterThan(0);

      // DB에 row 존재
      const row = await db
        .prepare("SELECT * FROM consents WHERE id = ?")
        .bind(result.consentId)
        .first<{ id: number; consent_type: string; status: string }>();

      expect(row).not.toBeNull();
      expect(row?.consent_type).toBe("cross_border_transfer");
    });

    it("records audit_log with cross_border_consent_granted action", async () => {
      const db = env.DB;

      const result = await recordCrossBorderConsent(db, {
        sessionId: 1,
        transferDestination: "Azure East Asia (Hong Kong)",
        consentTextSnapshot: "Cross-border transfer to Hong Kong.",
        consentVersion: "1.0",
      });

      const auditRow = await db
        .prepare(
          "SELECT * FROM audit_logs WHERE resource_type = 'consent' AND resource_id = ? AND action = 'cross_border_consent_granted'"
        )
        .bind(String(result.consentId))
        .first<{ id: number; action: string }>();

      expect(auditRow).not.toBeNull();
      expect(auditRow?.action).toBe("cross_border_consent_granted");
    });
  });

  describe("revokeCrossBorderConsent service", () => {
    it("marks consent as revoked and records audit_log", async () => {
      const db = env.DB;

      const createResult = await recordCrossBorderConsent(db, {
        sessionId: 1,
        transferDestination: "AWS us-west-2 (Oregon)",
        consentTextSnapshot: "Transfer to Oregon.",
        consentVersion: "1.0",
      });

      const revokeResult = await revokeCrossBorderConsent(
        db,
        createResult.consentId!
      );

      expect(revokeResult.success).toBe(true);

      const auditRow = await db
        .prepare(
          "SELECT action FROM audit_logs WHERE resource_type = 'consent' AND resource_id = ? AND action = 'cross_border_consent_revoked'"
        )
        .bind(String(createResult.consentId))
        .first<{ action: string }>();

      expect(auditRow?.action).toBe("cross_border_consent_revoked");
    });
  });

  describe("checkCrossBorderConsent service", () => {
    it("returns true when active cross-border consent exists", async () => {
      const db = env.DB;

      await recordCrossBorderConsent(db, {
        sessionId: 1,
        transferDestination: "Test Region",
        consentTextSnapshot: "Test.",
        consentVersion: "1.0",
      });

      const hasConsent = await checkCrossBorderConsent(db, { sessionId: 1 });
      expect(hasConsent).toBe(true);
    });

    it("returns false when no active cross-border consent exists", async () => {
      const db = env.DB;

      // sessionId 9999는 동의 없음
      const hasConsent = await checkCrossBorderConsent(db, { sessionId: 9999 });
      expect(hasConsent).toBe(false);
    });

    it("returns false after consent is revoked", async () => {
      const db = env.DB;

      const createResult = await recordCrossBorderConsent(db, {
        sessionId: 2,
        transferDestination: "Test Region",
        consentTextSnapshot: "Test.",
        consentVersion: "1.0",
      });

      await revokeCrossBorderConsent(db, createResult.consentId!);

      const hasConsent = await checkCrossBorderConsent(db, { sessionId: 2 });
      expect(hasConsent).toBe(false);
    });
  });
});
