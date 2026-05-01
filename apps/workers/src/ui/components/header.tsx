/**
 * src/ui/components/header.tsx — Site header
 * Cycle 6 GREEN phase.
 */

export interface HeaderProps {
  isAdmin?: boolean;
  userEmail?: string | null;
  currentPath?: string;
}

export function Header(props: HeaderProps): string {
  const { isAdmin = false, userEmail = null, currentPath = "" } = props;
  const userLinks = userEmail
    ? `<span>${userEmail}</span><a href="/signout">Logout</a>`
    : `<a href="/signin">Login</a><a href="/signup">Sign Up</a>`;
  const adminLinks = isAdmin
    ? `<a href="/admin/dashboard">Admin</a>`
    : "";
  return `<header>
<a href="/">Personality</a>
${adminLinks}
<nav data-current-path="${currentPath}">${userLinks}</nav>
</header>`;
}
