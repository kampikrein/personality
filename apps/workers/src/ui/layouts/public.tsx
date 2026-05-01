/**
 * src/ui/layouts/public.tsx — Public layout
 * Cycle 6 GREEN phase. Wraps public pages with optional session + hx-boost.
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

export function PublicLayout(props: PublicLayoutProps): string {
  const nonceTag = props.nonce
    ? `<meta name="csp-nonce" content="${props.nonce}">`
    : "";
  const hxBoostAttr = props.hxBoost ? ` hx-boost="true"` : "";
  const userLinks = props.user
    ? `<span>${props.user.email}</span><a href="/signout">Logout</a>`
    : `<a href="/signin">Login</a><a href="/signup">Sign Up</a>`;
  const nav = `<nav>${userLinks}</nav>`;
  return `<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${props.title}</title>
${nonceTag}
</head>
<body${hxBoostAttr}>${nav}${props.children ?? ""}</body>
</html>`;
}
