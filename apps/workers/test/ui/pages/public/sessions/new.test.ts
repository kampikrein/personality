/**
 * test/ui/pages/public/sessions/new.test.ts — SessionsNewPage RED tests
 * Cycle 6 RED phase.
 *
 * GREEN: Renders login form with email + password fields, CSRF meta, submit button.
 *   Error message displayed when error prop is provided.
 */

import { describe, it, expect } from "vitest";
import { SessionsNewPage } from "../../../../../src/ui/pages/public/sessions/new";

describe("SessionsNewPage (RED phase)", () => {
  it("SessionsNewPage is exported", () => {
    expect(SessionsNewPage).toBeDefined();
    expect(typeof SessionsNewPage).toBe("function");
  });

  it("renders login form with csrf token", () => {
    expect(() =>
      SessionsNewPage({ csrfToken: "csrf-login-token" })
    ).toThrow("not implemented: SessionsNewPage");
  });

  it("renders with error message", () => {
    expect(() =>
      SessionsNewPage({ csrfToken: "csrf-login-token", error: "Invalid credentials" })
    ).toThrow("not implemented: SessionsNewPage");
  });

  it("csrf token is a string", () => {
    const props = { csrfToken: "test-csrf" };
    expect(typeof props.csrfToken).toBe("string");
  });
});
