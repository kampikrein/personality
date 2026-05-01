/**
 * src/ui/pages/admin/audit_logs/show.tsx — Admin audit log detail page
 * Cycle 6 GREEN phase.
 */

import type { AuditLog } from "./index";

export interface AuditLogsShowProps {
  log: AuditLog;
  user?: { email: string };
  cspNonce?: string;
}

export function AuditLogsShowPage(props: AuditLogsShowProps): string {
  const { log } = props;
  return `<div class="admin-audit-log-detail">
  <h1>Audit Log Detail</h1>
  <p>Action: ${log.action}</p>
  <p>Actor: ${log.actor_email}</p>
  <p>Created: ${log.created_at}</p>
  <a href="/admin/audit_logs">Back to Audit Logs</a>
</div>`;
}
