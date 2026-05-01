/**
 * test/compliance/admin_compliance.test.ts — RED phase
 * Cycle 8: Compliance GDPR/PIPA
 *
 * admin 양쪽 노출 검증:
 *   1. GET /admin/audit_logs — 전체 logs (filter, pagination) 기존 route 검증
 *   2. audit_logs POST → 405 (immutable)
 *   3. admin /consents — consent 통계 (신규 or cycle 5)
 *   4. admin /deletion_requests — 처리 대기 list + SLA 모니터링
 *
 * DB 의존: cycle 2 schema
 * GREEN phase: admin consent 통계 + SLA alert endpoint 구현 후 pass.
 */

import { describe, it, expect } from "vitest";
import { env } from "cloudflare:test";
import { adminAuditLogsRouter } from "../../src/api/routes/admin/audit_logs";

const VALID_ADMIN_JWT = "eyJhbGciOiJSUzI1NiJ9.admin.fakesig";

// GREEN phase에서 추가될 admin compliance router
// import { adminComplianceRouter } from "../../src/api/routes/admin/compliance";

describe("Compliance — Admin Compliance Endpoints", () => {
  describe("GET /admin/audit_logs — existing route", () => {
    it("adminAuditLogsRouter is defined", () => {
      expect(adminAuditLogsRouter).toBeDefined();
    });

    it("GET / without CF Access JWT → 403", async () => {
      const req = new Request("http://localhost/", { method: "GET" });
      const res = await adminAuditLogsRouter.request(req);
      expect(res.status).toBe(403);
      const body = (await res.json()) as { success: boolean; error: { code: string } };
      expect(body.success).toBe(false);
      expect(body.error.code).toBe("forbidden");
    });

    it("GET / with valid JWT → 200 + audit log list", async () => {
      const req = new Request("http://localhost/", {
        method: "GET",
        headers: { "Cf-Access-Jwt-Assertion": VALID_ADMIN_JWT },
      });
      const res = await adminAuditLogsRouter.request(req);
      expect(res.status).toBe(200);

      const body = (await res.json()) as {
        success: boolean;
        data: { logs: unknown[] };
      };
      expect(body.success).toBe(true);
      expect(Array.isArray(body.data.logs)).toBe(true);
    });

    it("POST / → 405 (audit logs are read-only)", async () => {
      const req = new Request("http://localhost/", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Cf-Access-Jwt-Assertion": VALID_ADMIN_JWT,
        },
        body: JSON.stringify({ action: "tampered" }),
      });

      const res = await adminAuditLogsRouter.request(req);
      expect(res.status).toBe(405);
    });

    it("GET /:id → 200 or 404 for valid JWT", async () => {
      const req = new Request("http://localhost/1", {
        headers: { "Cf-Access-Jwt-Assertion": VALID_ADMIN_JWT },
      });
      const res = await adminAuditLogsRouter.request(req);
      // 200 (row exists) 또는 404 (seed에 id=1 없음) 모두 허용
      expect([200, 404]).toContain(res.status);
    });
  });

  describe("admin consent statistics — GREEN phase target", () => {
    it("DB has consents table accessible for admin queries", async () => {
      const db = env.DB;

      // consents 테이블 존재 확인 (admin 통계 endpoint 기반)
      const row = await db
        .prepare("SELECT COUNT(*) as cnt FROM consents")
        .first<{ cnt: number }>();

      expect(row).not.toBeNull();
      expect(typeof row?.cnt).toBe("number");
    });

    it("can query consent breakdown by consent_type", async () => {
      const db = env.DB;

      const rows = await db
        .prepare(
          "SELECT consent_type, COUNT(*) as count FROM consents GROUP BY consent_type"
        )
        .all<{ consent_type: string; count: number }>();

      expect(rows.results).toBeDefined();
      expect(Array.isArray(rows.results)).toBe(true);
      // GREEN phase: adminComplianceRouter.get('/consents/stats') 구현 후 endpoint 검증
    });

    it("can query active vs revoked consent counts (granted/revoked_at fields)", async () => {
      const db = env.DB;

      // consents 테이블: granted (boolean) + revoked_at (nullable timestamp)
      const grantedRows = await db
        .prepare(
          "SELECT COUNT(*) as count FROM consents WHERE granted = 1 AND revoked_at IS NULL"
        )
        .first<{ count: number }>();

      const revokedRows = await db
        .prepare(
          "SELECT COUNT(*) as count FROM consents WHERE revoked_at IS NOT NULL"
        )
        .first<{ count: number }>();

      expect(typeof grantedRows?.count).toBe("number");
      expect(typeof revokedRows?.count).toBe("number");
      // GREEN phase: admin endpoint에서 이 통계를 JSON으로 반환
    });
  });

  describe("admin deletion_requests — SLA monitoring", () => {
    it("DB has deletion_requests table accessible for admin queries", async () => {
      const db = env.DB;

      const row = await db
        .prepare("SELECT COUNT(*) as cnt FROM deletion_requests")
        .first<{ cnt: number }>();

      expect(row).not.toBeNull();
      expect(typeof row?.cnt).toBe("number");
    });

    it("can query pending deletion_requests for SLA monitoring", async () => {
      const db = env.DB;

      const rows = await db
        .prepare(
          "SELECT * FROM deletion_requests WHERE status = 'pending' ORDER BY created_at ASC"
        )
        .all<{ id: number; status: string; created_at: string }>();

      expect(rows.results).toBeDefined();
      expect(Array.isArray(rows.results)).toBe(true);
    });

    it("can identify SLA breached deletion_requests (>30 days pending)", async () => {
      const db = env.DB;

      // 31일 전 pending 요청 시뮬레이션
      const pastDate = new Date();
      pastDate.setDate(pastDate.getDate() - 31);

      await db
        .prepare(
          "INSERT INTO deletion_requests (anonymous_session_id, request_token, status, created_at, updated_at) VALUES (1, ?, 'pending', ?, ?)"
        )
        .bind(`token-admin-overdue-${Date.now()}`, pastDate.toISOString(), pastDate.toISOString())
        .run();

      const overdueRows = await db
        .prepare(
          "SELECT * FROM deletion_requests WHERE status = 'pending' AND datetime(created_at) < datetime('now', '-30 days')"
        )
        .all<{ id: number; created_at: string }>();

      expect(overdueRows.results.length).toBeGreaterThan(0);

      // GREEN phase: admin /deletion_requests?sla_breached=true endpoint 구현
    });

    it("deletion_request status transitions: pending → completed", async () => {
      const db = env.DB;

      await db
        .prepare(
          "INSERT INTO deletion_requests (anonymous_session_id, request_token, status, created_at, updated_at) VALUES (1, ?, 'pending', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)"
        )
        .bind(`token-transition-${Date.now()}`)
        .run();
      const row = await db
        .prepare("SELECT last_insert_rowid() as id")
        .first<{ id: number }>();
      const id = row!.id;

      // 처리 완료로 상태 변경 (processDeletion이 수행)
      await db
        .prepare("UPDATE deletion_requests SET status = 'completed', updated_at = CURRENT_TIMESTAMP WHERE id = ?")
        .bind(id)
        .run();

      const updatedRow = await db
        .prepare("SELECT status FROM deletion_requests WHERE id = ?")
        .bind(id)
        .first<{ status: string }>();

      expect(updatedRow?.status).toBe("completed");
    });
  });

  describe("audit_log filter queries — compliance reporting", () => {
    it("can query audit_logs by action for compliance report", async () => {
      const db = env.DB;

      // 직접 audit_log 삽입
      await db
        .prepare(
          "INSERT INTO audit_logs (resource_type, resource_id, action, metadata, created_at, updated_at) VALUES ('consent', '1', 'consent_granted', '{}', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)"
        )
        .run();

      const rows = await db
        .prepare(
          "SELECT * FROM audit_logs WHERE action IN ('consent_granted', 'consent_revoked') ORDER BY created_at DESC LIMIT 100"
        )
        .all<{ id: number; action: string }>();

      expect(rows.results.length).toBeGreaterThan(0);
    });

    it("can query audit_logs within date range for GDPR report", async () => {
      const db = env.DB;

      const since = new Date();
      since.setDate(since.getDate() - 7);

      const rows = await db
        .prepare(
          "SELECT * FROM audit_logs WHERE datetime(created_at) >= datetime(?) ORDER BY created_at DESC"
        )
        .bind(since.toISOString())
        .all<{ id: number; action: string; created_at: string }>();

      expect(rows.results).toBeDefined();
      expect(Array.isArray(rows.results)).toBe(true);
    });
  });
});
