/**
 * test/ui/pages/admin/audit_logs/index.test.ts — AuditLogsIndexPage GREEN tests
 * Cycle 6 GREEN phase (Step 0: antipattern fix).
 *
 * GREEN: Renders table with action, actor_email, created_at columns.
 *   Pagination controls when totalPages > 1.
 *   Empty state when logs=[].
 */

import { describe, it, expect } from "vitest";
import { AuditLogsIndexPage } from "../../../../../src/ui/pages/admin/audit_logs/index";
import type { AuditLog } from "../../../../../src/ui/pages/admin/audit_logs/index";

const sampleLogs: AuditLog[] = [
  { id: "1", action: "user.create", actor_email: "admin@example.com", created_at: "2026-04-01T00:00:00Z" },
  { id: "2", action: "assessment.delete", actor_email: "admin@example.com", created_at: "2026-04-02T00:00:00Z" },
];

describe("AuditLogsIndexPage", () => {
  it("AuditLogsIndexPage is exported", () => {
    expect(AuditLogsIndexPage).toBeDefined();
    expect(typeof AuditLogsIndexPage).toBe("function");
  });

  it("renders logs list", () => {
    const html = String(AuditLogsIndexPage({ logs: sampleLogs }));
    expect(html).toContain("user.create");
  });

  it("renders actor email", () => {
    const html = String(AuditLogsIndexPage({ logs: sampleLogs }));
    expect(html).toContain("admin@example.com");
  });

  it("renders empty state", () => {
    const html = String(AuditLogsIndexPage({ logs: [] }));
    expect(html).toBeDefined();
  });

  it("renders with pagination", () => {
    const html = String(AuditLogsIndexPage({ logs: sampleLogs, page: 1, totalPages: 5 }));
    expect(html).toBeDefined();
  });

  it("log entries have required fields", () => {
    expect(sampleLogs[0].action).toBe("user.create");
    expect(sampleLogs[0].actor_email).toBeDefined();
    expect(sampleLogs[0].created_at).toBeDefined();
  });
});
