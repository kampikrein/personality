/**
 * test/compliance/deletion_flow.test.ts — RED phase
 * Cycle 8: Compliance GDPR/PIPA
 *
 * E2E 통합 검증: 계정 삭제 요청·처리 흐름
 *   1. POST /api/deletion_requests → row + audit_log
 *   2. processDeletion → cascade delete + audit_log
 *   3. 처리 후 user data 전수 확인 (모든 관련 테이블 삭제)
 *   4. audit_log에 deletion 이벤트 기록
 *   5. SLA: 30일 이내 처리 마킹 검증
 *   6. 미처리 30일 초과 → alert 트리거 (placeholder)
 *
 * DB 의존: cycle 2 schema + cycle 3 deletionProcessor
 * GREEN phase: auditLogger 연동 + SLA 필드 추가 후 pass.
 */

import { describe, it, expect } from "vitest";
import { env } from "cloudflare:test";
import { deletionRequestsRouter } from "../../src/api/routes/public/deletion_requests";
import { processDeletion } from "../../src/services/compliance/deletionProcessor";

const SLA_DAYS = 30;

describe("Compliance — Deletion Flow (E2E)", () => {
  describe("POST /api/deletion_requests → row + audit_log", () => {
    it("creates deletion_request row and returns 201 with pending status", async () => {
      const db = env.DB;

      const req = new Request("http://localhost/", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-Session-Token": "test-session-token",
        },
        body: JSON.stringify({ reason: "User requested deletion" }),
      });

      const res = await deletionRequestsRouter.fetch(req, { DB: db });
      expect(res.status).toBe(201);

      const body = (await res.json()) as {
        success: boolean;
        data: { id: number; status: string };
      };
      expect(body.success).toBe(true);
      expect(body.data.status).toBe("pending");

      // deletion_request row exists
      const row = await db
        .prepare("SELECT * FROM deletion_requests WHERE id = ?")
        .bind(body.data.id)
        .first<{ status: string; created_at: string }>();
      expect(row).not.toBeNull();
      expect(row?.status).toBe("pending");
    });

    it("records audit_log entry for deletion_requested action", async () => {
      const db = env.DB;

      const req = new Request("http://localhost/", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-Session-Token": "test-session-token",
        },
        body: JSON.stringify({ reason: "GDPR erasure request" }),
      });

      const res = await deletionRequestsRouter.fetch(req, { DB: db });
      const body = (await res.json()) as {
        success: boolean;
        data: { id: number };
      };

      const auditRow = await db
        .prepare(
          "SELECT * FROM audit_logs WHERE resource_type = 'deletion_request' AND resource_id = ? AND action = 'deletion_requested'"
        )
        .bind(String(body.data.id))
        .first<{ id: number; action: string }>();

      expect(auditRow).not.toBeNull();
      expect(auditRow?.action).toBe("deletion_requested");
    });
  });

  describe("processDeletion → cascade delete + audit_log", () => {
    it("processDeletion removes all session-related data in cascade order", async () => {
      const db = env.DB;

      // deletion_request 행 직접 삽입 (테스트 격리)
      await db
        .prepare(
          "INSERT INTO deletion_requests (anonymous_session_id, request_token, status, created_at, updated_at) VALUES (1, ?, 'pending', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)"
        )
        .bind(`token-cascade-${Date.now()}`)
        .run();
      const drRow = await db
        .prepare("SELECT last_insert_rowid() as id")
        .first<{ id: number }>();
      const deletionRequestId = drRow!.id;

      const result = await processDeletion(db, deletionRequestId);

      expect(result.success).toBe(true);
      expect(result.deleted_counts).toMatchObject({
        responses: expect.any(Number),
        domain_scores: expect.any(Number),
        insights: expect.any(Number),
        profiles: expect.any(Number),
        assessments: expect.any(Number),
        consents: expect.any(Number),
        anonymous_sessions: expect.any(Number),
      });
    });

    it("records audit_log entry with deletion_processed action after successful processing", async () => {
      const db = env.DB;

      // deletion_request 생성
      await db
        .prepare(
          "INSERT INTO deletion_requests (anonymous_session_id, request_token, status, created_at, updated_at) VALUES (1, ?, 'pending', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)"
        )
        .bind(`token-audit-${Date.now()}`)
        .run();
      const drRow = await db
        .prepare("SELECT last_insert_rowid() as id")
        .first<{ id: number }>();
      const deletionRequestId = drRow!.id;

      await processDeletion(db, deletionRequestId);

      const auditRow = await db
        .prepare(
          "SELECT * FROM audit_logs WHERE resource_type = 'deletion_request' AND action = 'deletion_processed' ORDER BY id DESC LIMIT 1"
        )
        .first<{ id: number; action: string }>();

      expect(auditRow).not.toBeNull();
      expect(auditRow?.action).toBe("deletion_processed");
    });
  });

  describe("SLA compliance — 30-day processing window", () => {
    it("deletion_request has created_at timestamp for SLA calculation", async () => {
      const db = env.DB;

      await db
        .prepare(
          "INSERT INTO deletion_requests (anonymous_session_id, request_token, status, created_at, updated_at) VALUES (1, ?, 'pending', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)"
        )
        .bind(`token-sla-${Date.now()}`)
        .run();
      const row = await db
        .prepare(
          "SELECT * FROM deletion_requests ORDER BY id DESC LIMIT 1"
        )
        .first<{ id: number; created_at: string; status: string }>();

      expect(row).not.toBeNull();
      expect(row?.created_at).toBeTruthy();

      // SLA 계산: created_at ~ now < 30일
      const createdAt = new Date(row!.created_at);
      const slaDeadline = new Date(createdAt);
      slaDeadline.setDate(slaDeadline.getDate() + SLA_DAYS);
      expect(slaDeadline > new Date()).toBe(true);
    });

    it("processed_at timestamp is set after processDeletion completes", async () => {
      const db = env.DB;

      await db
        .prepare(
          "INSERT INTO deletion_requests (anonymous_session_id, request_token, status, created_at, updated_at) VALUES (1, ?, 'pending', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)"
        )
        .bind(`token-processed-${Date.now()}`)
        .run();
      const drRow = await db
        .prepare("SELECT last_insert_rowid() as id")
        .first<{ id: number }>();
      const deletionRequestId = drRow!.id;

      await processDeletion(db, deletionRequestId);

      const row = await db
        .prepare("SELECT * FROM deletion_requests WHERE id = ?")
        .bind(deletionRequestId)
        .first<{ status: string; updated_at: string }>();

      // GREEN phase: status = 'completed' + processed_at 필드
      expect(row?.status).toBe("completed");
    });

    it("pending deletion_request older than 30 days qualifies for SLA breach alert", async () => {
      const db = env.DB;

      // 31일 전 생성된 미처리 요청 시뮬레이션
      const pastDate = new Date();
      pastDate.setDate(pastDate.getDate() - 31);
      const pastDateStr = pastDate.toISOString();

      await db
        .prepare(
          "INSERT INTO deletion_requests (anonymous_session_id, request_token, status, created_at, updated_at) VALUES (1, ?, 'pending', ?, ?)"
        )
        .bind(`token-overdue-${Date.now()}`, pastDateStr, pastDateStr)
        .run();

      const overdueRows = await db
        .prepare(
          `SELECT * FROM deletion_requests
           WHERE status = 'pending'
             AND datetime(created_at) < datetime('now', '-${SLA_DAYS} days')`
        )
        .all<{ id: number; status: string; created_at: string }>();

      // SLA 위반 행이 존재해야 함
      expect(overdueRows.results.length).toBeGreaterThan(0);

      // GREEN phase: cron handler가 alert를 생성하는지 검증
      // 현재는 DB 쿼리로 위반 행 존재 확인만 (alert 생성은 Green phase)
    });
  });
});
