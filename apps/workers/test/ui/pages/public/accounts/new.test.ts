/**
 * test/ui/pages/public/accounts/new.test.ts — AccountsNewPage RED tests
 * Cycle 6 RED phase.
 *
 * GREEN: Renders signup form with email, password, confirm password fields.
 *   Terms + privacy consent checkboxes required.
 *   Validation error messages per field.
 */

import { describe, it, expect } from "vitest";
import { AccountsNewPage } from "../../../../../src/ui/pages/public/accounts/new";

describe("AccountsNewPage (RED phase)", () => {
  it("AccountsNewPage is exported", () => {
    expect(AccountsNewPage).toBeDefined();
    expect(typeof AccountsNewPage).toBe("function");
  });

  it("renders signup form with csrf token", () => {
    expect(() =>
      AccountsNewPage({ csrfToken: "csrf-signup-token" })
    ).toThrow("not implemented: AccountsNewPage");
  });

  it("renders with field validation errors", () => {
    expect(() =>
      AccountsNewPage({
        csrfToken: "csrf-signup-token",
        errors: {
          email: ["has already been taken"],
          password: ["is too short"],
        },
      })
    ).toThrow("not implemented: AccountsNewPage");
  });
});
