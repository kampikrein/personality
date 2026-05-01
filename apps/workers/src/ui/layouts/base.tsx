/**
 * src/ui/layouts/base.tsx — Base HTML layout
 * Cycle 6 GREEN phase. SSR layout with CSP nonce slot.
 */

export interface BaseLayoutProps {
  title: string;
  nonce?: string;
  children?: unknown;
}

export function BaseLayout(props: BaseLayoutProps): string {
  const nonceTag = props.nonce
    ? `<meta name="csp-nonce" content="${props.nonce}">`
    : "";
  return `<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${props.title}</title>
${nonceTag}
</head>
<body>${props.children ?? ""}</body>
</html>`;
}
