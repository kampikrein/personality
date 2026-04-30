/**
 * test/api/routes/admin/audit_logs.test.ts — Admin Audit Logs API routes RED phase
 * Cycle 5.
 *
 * Rails origin: Admin::AuditLogsController (resources :audit_logs, only: [:index, :show])
 *   GET /admin/audit_logs     — index
 *   GET /admin/audit_logs/:id — show
 *
 * Assertions:
 *   1. adminAuditLogsRouter is exported
 *   2. GET / without CF Access JWT → 403 + envelope error { code: 'forbidden' }
 *   3. GET / with valid CF Access JWT → 200 + envelope { success: true, data: { logs: [...] } }
 *   4. GET /:id with valid JWT → 200 + single log entry
 *   5. GET /:id not found → 404
 *   6. POST / → 405 (audit logs are read-only)
 *
 * RED phase: stubs throw 'not implemented' → all fail.
 * GREEN phase: implement audit_logs.ts with cfAccessVerifier.
 */

import { describe, it, expect } from "vitest";
import { adminAuditLogsRouter } from "../../../../src/api/routes/admin/audit_logs";

const VALID_ADMIN_JWT = "eyJhbGciOiJSUzI1NiJ9.admin.fakesig";

describe("Admin Audit Logs API Routes — RED phase", () => {
  it("adminAuditLogsRouter is defined and exported", () => {
    expect(adminAuditLogsRouter).toBeDefined();
  });

  describe("GET / (list)", () => {
    it("returns 403 without CF Access JWT", async () => {
      const req = new Request("http://localhost/", { method: "GET" });
      const res = await adminAuditLogsRouter.request(req);
      expect(res.status).toBe(403);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(false);
      expect((body.error as Record<string, unknown>).code).toBe("forbidden");
    });

    it("returns 200 + audit log list with valid JWT", async () => {
      const req = new Request("http://localhost/", {
        method: "GET",
        headers: { "Cf-Access-Jwt-Assertion": VALID_ADMIN_JWT },
      });
      const res = await adminAuditLogsRouter.request(req);
      expect(res.status).toBe(200);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(true);
      expect(Array.isArray((body.data as Record<string, unknown>).logs)).toBe(true);
    });
  });

  describe("GET /:id", () => {
    it("returns single audit log entry with valid JWT", async () => {
      const req = new Request("http://localhost/log-001", {
        method: "GET",
        headers: { "Cf-Access-Jwt-Assertion": VALID_ADMIN_JWT },
      });
      const res = await adminAuditLogsRouter.request(req);
      expect(res.status).toBe(200);
      const body = await res.json() as Record<string, unknown>;
      expect(body.success).toBe(true);
      expect((body.data as Record<string, unknown>).id).toBe("log-001");
    });

    it("returns 404 for unknown log", async () => {
      const req = new Request("http://localhost/nonexistent", {
        method: "GET",
        headers: { "Cf-Access-Jwt-Assertion": VALID_ADMIN_JWT },
      });
      const res = await adminAuditLogsRouter.request(req);
      expect(res.status).toBe(404);
    });
  });

  describe("write operations are not allowed", () => {
    it("POST returns 405 (audit logs are read-only)", async () => {
      const req = new Request("http://localhost/", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Cf-Access-Jwt-Assertion": VALID_ADMIN_JWT,
        },
        body: JSON.stringify({}),
      });
      const res = await adminAuditLogsRouter.request(req);
      expect(res.status).toBe(405);
    });
  });
});
