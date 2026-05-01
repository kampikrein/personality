/**
 * src/ui/components/csrf_meta.tsx — CSRF meta tag
 * Cycle 6 GREEN phase. Embeds csrf-token for JS fetch usage.
 */

export interface CsrfMetaProps {
  token: string;
}

export function CsrfMeta(props: CsrfMetaProps): string {
  return `<meta name="csrf-token" content="${props.token}">`;
}
