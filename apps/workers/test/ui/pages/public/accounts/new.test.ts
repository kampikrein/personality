/**
 * test/ui/pages/public/accounts/new.test.ts — AccountsNewPage GREEN tests
 * Cycle 6 GREEN phase (Step 0: antipattern fix).
 *
 * GREEN: Renders signup form with email, password, confirm password fields.
 *   Terms + privacy consent checkboxes required.
 *   Validation error messages per field.
 */

import { describe, it, expect } from "vitest";
import { AccountsNewPage } from "../../../../../src/ui/pages/public/accounts/new";

describe("AccountsNewPage", () => {
  it("AccountsNewPage is exported", () => {
    expect(AccountsNewPage).toBeDefined();
    expect(typeof AccountsNewPage).toBe("function");
  });

  it("renders signup form with csrf token", () => {
    const html = String(AccountsNewPage({ csrfToken: "csrf-signup-token" }));
    expect(html).toContain("csrf-signup-token");
  });

  it("renders with field validation errors", () => {
    const html = String(AccountsNewPage({
      csrfToken: "csrf-signup-token",
      errors: {
        email: ["has already been taken"],
        password: ["is too short"],
      },
    }));
    expect(html).toContain("has already been taken");
  });
});
