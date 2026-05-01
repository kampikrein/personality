/**
 * src/ui/pages/public/accounts/new.tsx — Signup form page stub
 * Cycle 6 RED phase.
 */

export interface AccountsNewProps {
  csrfToken: string;
  errors?: Record<string, string[]>;
}

export function AccountsNewPage(props: AccountsNewProps): string {
  const errorMessages = props.errors
    ? Object.values(props.errors).flat().map((e) => `<p class="error">${e}</p>`).join("")
    : "";

  return `<div class="accounts-new">
  <h1>Create Account</h1>
  ${errorMessages}
  <form method="post" action="/api/accounts">
    <input type="hidden" name="csrf_token" value="${props.csrfToken}">
    <label>Email<input type="email" name="email"></label>
    <label>Password<input type="password" name="password"></label>
    <label>Confirm Password<input type="password" name="password_confirmation"></label>
    <label><input type="checkbox" name="terms" required> I agree to the Terms of Service</label>
    <label><input type="checkbox" name="privacy" required> I agree to the Privacy Policy</label>
    <button type="submit">Create Account</button>
  </form>
  <a href="/signin">Already have an account?</a>
</div>`;
}
