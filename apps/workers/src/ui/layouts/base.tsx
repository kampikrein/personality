/**
 * src/ui/layouts/base.tsx — Base HTML layout stub
 * Cycle 6 RED phase. SSR layout with CSP nonce slot.
 */

export interface BaseLayoutProps {
  title: string;
  nonce?: string;
  children?: unknown;
}

// RED stub — not implemented
export function BaseLayout(_props: BaseLayoutProps): unknown {
  throw new Error("not implemented: BaseLayout");
}
