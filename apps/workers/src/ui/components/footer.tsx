/**
 * src/ui/components/footer.tsx — Site footer
 * Cycle 6 GREEN phase.
 */

export interface FooterProps {
  year?: number;
}

export function Footer(props: FooterProps): string {
  const year = props.year ?? new Date().getFullYear();
  return `<footer>
<p>© ${year} Personality. All rights reserved.</p>
<nav>
<a href="/privacy">Privacy Policy</a>
<a href="/terms">Terms of Service</a>
<a href="/contact">Contact</a>
</nav>
</footer>`;
}
