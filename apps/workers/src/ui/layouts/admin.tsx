/**
 * src/ui/layouts/admin.tsx — Admin layout stub
 * Cycle 6 RED phase. Wraps admin pages with CF Access user context.
 */

import type { CFAccessPayload } from "../../auth/cfAccessVerifier";

export interface AdminLayoutProps {
  title: string;
  user: CFAccessPayload;
  nonce?: string;
  children?: unknown;
}

// RED stub — not implemented
export function AdminLayout(_props: AdminLayoutProps): unknown {
  throw new Error("not implemented: AdminLayout");
}
