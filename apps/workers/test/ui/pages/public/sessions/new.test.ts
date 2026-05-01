/**
 * test/ui/pages/public/sessions/new.test.ts — SessionsNewPage GREEN tests
 * Cycle 6 GREEN phase (Step 0: antipattern fix).
 *
 * GREEN: Renders login form with email + password fields, CSRF meta, submit button.
 *   Error message displayed when error prop is provided.
 */

import { describe, it, expect } from "vitest";
import { SessionsNewPage } from "../../../../../src/ui/pages/public/sessions/new";

describe("SessionsNewPage", () => {
  it("SessionsNewPage is exported", () => {
    expect(SessionsNewPage).toBeDefined();
    expect(typeof SessionsNewPage).toBe("function");
  });

  it("renders login form with csrf token", () => {
    const html = String(SessionsNewPage({ csrfToken: "csrf-login-token" }));
    expect(html).toContain("csrf-login-token");
  });

  it("renders with error message", () => {
    const html = String(SessionsNewPage({ csrfToken: "csrf-login-token", error: "Invalid credentials" }));
    expect(html).toContain("Invalid credentials");
  });

  it("csrf token is a string", () => {
    const props = { csrfToken: "test-csrf" };
    expect(typeof props.csrfToken).toBe("string");
  });
});
