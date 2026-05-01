/**
 * src/ui/layouts/admin.tsx — Admin layout
 * Cycle 6 GREEN phase. Wraps admin pages with CF Access user context.
 */

import type { CFAccessPayload } from "../../auth/cfAccessVerifier";
import { BaseLayout } from "./base";

export interface AdminLayoutProps {
  title: string;
  user: CFAccessPayload;
  nonce?: string;
  children?: unknown;
}

export function AdminLayout(props: AdminLayoutProps): string {
  const nav = `<nav>
  <a href="/admin/dashboard">Dashboard</a>
  <a href="/admin/audit_logs">Audit Logs</a>
  <a href="/admin/question_sets">Question Sets</a>
  <a href="/admin/alerts">Alerts</a>
  <span>${props.user.email}</span>
</nav>`;
  const body = `${nav}${props.children ?? ""}`;
  return BaseLayout({ title: props.title, nonce: props.nonce, children: body });
}
