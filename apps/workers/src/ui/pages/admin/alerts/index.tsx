/**
 * src/ui/pages/admin/alerts/index.tsx — Admin active alerts list stub
 * Cycle 6 RED phase.
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
}

// RED stub — not implemented
export function AlertsIndexPage(_props: AlertsIndexProps): unknown {
  throw new Error("not implemented: AlertsIndexPage");
}
