/**
 * src/ui/pages/public/sessions/new.tsx — Login form page stub
 * Cycle 6 RED phase.
 */

export interface SessionsNewProps {
  csrfToken: string;
  error?: string;
}

export function SessionsNewPage(props: SessionsNewProps): string {
  const errorHtml = props.error ? `<p class="error">${props.error}</p>` : "";
  return `<div class="sessions-new">
  <h1>Sign In</h1>
  ${errorHtml}
  <form method="post" action="/api/sessions">
    <input type="hidden" name="csrf_token" value="${props.csrfToken}">
    <label>Email<input type="email" name="email"></label>
    <label>Password<input type="password" name="password"></label>
    <button type="submit">Sign In</button>
  </form>
  <a href="/signup">Create account</a>
</div>`;
}
