/**
 * src/ui/pages/admin/audit_logs/index.tsx — Admin audit logs list
 * Cycle 6 GREEN phase.
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
  user?: { email: string };
  cspNonce?: string;
}

export function AuditLogsIndexPage(props: AuditLogsIndexProps): string {
  const rows = props.logs.map(
    (log) =>
      `<tr>
    <td>${log.action}</td>
    <td>${log.actor_email}</td>
    <td>${log.created_at}</td>
  </tr>`
  ).join("");

  const pagination =
    props.totalPages && props.totalPages > 1
      ? `<div class="pagination">Page ${props.page ?? 1} of ${props.totalPages}</div>`
      : "";

  return `<div class="admin-audit-logs">
  <h1>Audit Logs</h1>
  <table>
    <thead><tr><th>Action</th><th>Actor</th><th>Created</th></tr></thead>
    <tbody>${rows}</tbody>
  </table>
  ${pagination}
</div>`;
}
