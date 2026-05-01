/**
 * src/ui/pages/admin/alerts/index.tsx — Admin active alerts list
 * Cycle 6 GREEN phase.
 */

export interface AdminAlert {
  id: string;
  message: string;
  severity: "low" | "medium" | "high";
  active: boolean;
  created_at: string;
}

export interface AlertsIndexProps {
  alerts: AdminAlert[];
  user?: { email: string };
  cspNonce?: string;
}

export function AlertsIndexPage(props: AlertsIndexProps): string {
  const rows = props.alerts.map(
    (a) =>
      `<tr>
    <td>${a.message}</td>
    <td>${a.severity}</td>
    <td>${a.created_at}</td>
    <td><form method="post" action="/admin/alerts/${a.id}/dismiss"><button type="submit">Dismiss</button></form></td>
  </tr>`
  ).join("");

  return `<div class="admin-alerts">
  <h1>Active Alerts</h1>
  <table>
    <thead><tr><th>Message</th><th>Severity</th><th>Created</th><th>Actions</th></tr></thead>
    <tbody>${rows}</tbody>
  </table>
</div>`;
}
