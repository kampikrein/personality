/**
 * src/ui/pages/admin/audit_logs/index.tsx — Admin audit logs list stub
 * Cycle 6 RED phase.
 */

export interface AuditLog {
  id: string;
  action: string;
  actor_email: string;
  created_at: string;
}

export interface AuditLogsIndexProps {
  logs: AuditLog[];
  page?: number;
  totalPages?: number;
}

// RED stub — not implemented
export function AuditLogsIndexPage(_props: AuditLogsIndexProps): unknown {
  throw new Error("not implemented: AuditLogsIndexPage");
}
