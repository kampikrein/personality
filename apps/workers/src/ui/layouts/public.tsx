/**
 * src/ui/layouts/public.tsx — Public layout stub
 * Cycle 6 RED phase. Wraps public pages with optional session + hx-boost.
 */

export interface PublicUser {
  id: string;
  email: string;
}

export interface PublicLayoutProps {
  title: string;
  user?: PublicUser | null;
  nonce?: string;
  hxBoost?: boolean;
  children?: unknown;
}

// RED stub — not implemented
export function PublicLayout(_props: PublicLayoutProps): unknown {
  throw new Error("not implemented: PublicLayout");
}
