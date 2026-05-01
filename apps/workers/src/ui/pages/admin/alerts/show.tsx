/**
 * src/ui/pages/admin/alerts/show.tsx — Admin alert detail page
 * Cycle 6 GREEN phase.
 */

import type { AdminAlert } from "./index";

export interface AlertsShowProps {
  alert: AdminAlert;
  user?: { email: string };
  cspNonce?: string;
}

export function AlertsShowPage(props: AlertsShowProps): string {
  const { alert: a } = props;
  return `<div class="admin-alert-detail">
  <h1>Alert Detail</h1>
  <p>Message: ${a.message}</p>
  <p>Severity: ${a.severity}</p>
  <p>Active: ${a.active ? "Yes" : "No"}</p>
  <p>Created: ${a.created_at}</p>
  <a href="/admin/alerts">Back to Alerts</a>
</div>`;
}
