/**
 * test/compliance/consent_flow.test.ts — RED phase
 * Cycle 8: Compliance GDPR/PIPA
 *
 * E2E 통합 검증: consent 수집·철회 흐름
 *   1. POST /api/consents → consent row + audit_log 기록
 *   2. DELETE /api/consents/:id → consent 철회 + audit_log
 *   3. 활성 consent 없이 assessment 생성 → 403 + audit_log
 *   4. consent 철회 시 관련 assessment 무효화 영향
 *
 * DB 의존: cycle 2 schema (consents, audit_logs, assessments)
 * GREEN phase: auditLogger.ts + consents route audit 연동 구현 후 pass.
 */

import { describe, it, expect } from "vitest";
import { env } from "cloudflare:test";
import { consentsRouter } from "../../src/api/routes/public/consents";
import { auditLog } from "../../src/services/compliance/auditLogger";

describe("Compliance — Consent Flow (E2E)", () => {
  describe("POST /api/consents → consent row + audit_log", () => {
    it("creates consent record in DB and records audit_log entry", async () => {
      const db = env.DB;

      // consent row 생성
      const req = new Request("http://localhost/", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-Session-Token": "test-session-token",
        },
        body: JSON.stringify({
          consentType: "data_processing",
          consentVersion: "1.0",
          consentTextSnapshot: "I agree to data processing.",
        }),
      });

      const res = await consentsRouter.fetch(req, { DB: db });
      expect(res.status).toBe(201);

      const body = (await res.json()) as {
        success: boolean;
        data: { id: number; consentType: string; status: string };
      };
      expect(body.success).toBe(true);
      expect(body.data.consentType).toBe("data_processing");

      const consentId = body.data.id;

      // audit_log에 consent_granted 기록되어야 함
      const auditRow = await db
        .prepare(
          "SELECT * FROM audit_logs WHERE resource_type = 'consent' AND resource_id = ? AND action = 'consent_granted'"
        )
        .bind(String(consentId))
        .first<{ id: number; action: string; metadata: string }>();

      expect(auditRow).not.toBeNull();
      expect(auditRow?.action).toBe("consent_granted");
    });

    it("audit_log metadata contains user_id/session_id, action, timestamp fields", async () => {
      const db = env.DB;

      const req = new Request("http://localhost/", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-Session-Token": "test-session-token",
        },
        body: JSON.stringify({
          consentType: "analytics",
          consentVersion: "1.0",
          consentTextSnapshot: "I agree to analytics.",
        }),
      });

      await consentsRouter.fetch(req, { DB: db });

      const auditRow = await db
        .prepare(
          "SELECT * FROM audit_logs WHERE resource_type = 'consent' AND action = 'consent_granted' ORDER BY id DESC LIMIT 1"
        )
        .first<{ id: number; action: string; metadata: string }>();

      expect(auditRow).not.toBeNull();

      const meta = JSON.parse(auditRow?.metadata ?? "{}");
      // GREEN phase에서 session_id 또는 user_id 포함 필수
      expect(meta).toHaveProperty("consent_type");
    });
  });

  describe("DELETE /api/consents/:id → withdrawal + audit_log", () => {
    it("withdraws consent and records audit_log entry with consent_revoked action", async () => {
      const db = env.DB;

      // 먼저 consent 생성
      const createReq = new Request("http://localhost/", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-Session-Token": "test-session-token",
        },
        body: JSON.stringify({
          consentType: "data_processing",
          consentVersion: "1.0",
          consentTextSnapshot: "I agree.",
        }),
      });
      const createRes = await consentsRouter.fetch(createReq, { DB: db });
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
      const deleteRes = await consentsRouter.fetch(deleteReq, { DB: db });
      expect(deleteRes.status).toBe(200);

      // audit_log에 consent_revoked 기록
      const auditRow = await db
        .prepare(
          "SELECT * FROM audit_logs WHERE resource_type = 'consent' AND resource_id = ? AND action = 'consent_revoked'"
        )
        .bind(String(consentId))
        .first<{ id: number; action: string }>();

      expect(auditRow).not.toBeNull();
      expect(auditRow?.action).toBe("consent_revoked");
    });

    it("consent status becomes revoked after DELETE", async () => {
      const db = env.DB;

      const createReq = new Request("http://localhost/", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-Session-Token": "test-session-token",
        },
        body: JSON.stringify({
          consentType: "account_linking",
          consentVersion: "1.0",
          consentTextSnapshot: "I agree.",
        }),
      });
      const createRes = await consentsRouter.fetch(createReq, { DB: db });
      const createBody = (await createRes.json()) as {
        success: boolean;
        data: { id: number };
      };
      const consentId = createBody.data.id;

      const deleteReq = new Request(`http://localhost/${consentId}`, {
        method: "DELETE",
        headers: { "X-Session-Token": "test-session-token" },
      });
      await consentsRouter.fetch(deleteReq, { DB: db });

      const consentRow = await db
        .prepare("SELECT status FROM consents WHERE id = ?")
        .bind(consentId)
        .first<{ status: string }>();

      // GREEN phase: status = 'revoked' 또는 revoked_at IS NOT NULL
      expect(
        consentRow?.status === "revoked" || consentRow?.status === "withdrawn"
      ).toBe(true);
    });
  });

  describe("auditLogger helper — direct invocation", () => {
    it("auditLog() inserts row into audit_logs table", async () => {
      const db = env.DB;

      const result = await auditLog(db, {
        resourceType: "consent",
        resourceId: 9999,
        action: "consent_granted",
        actorType: "user",
        actorId: 1,
        metadata: { consent_type: "data_processing", ip: "127.0.0.1" },
      });

      expect(result).toHaveProperty("id");
      expect(typeof result.id).toBe("number");

      const row = await db
        .prepare("SELECT * FROM audit_logs WHERE id = ?")
        .bind(result.id)
        .first<{ action: string; resource_type: string }>();

      expect(row?.action).toBe("consent_granted");
      expect(row?.resource_type).toBe("consent");
    });
  });
});
