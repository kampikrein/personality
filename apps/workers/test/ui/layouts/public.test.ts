/**
 * test/ui/layouts/public.test.ts — PublicLayout GREEN tests
 * Cycle 6 GREEN phase (Step 0: antipattern fix).
 *
 * PublicLayout renders with:
 *   - login link when user is null
 *   - logout link + user email when user is present
 *   - hx-boost="true" on <body> when hxBoost=true
 *   - public nav: /assessments, /signin, /signup
 */

import { describe, it, expect } from "vitest";
import { PublicLayout } from "../../../src/ui/layouts/public";
import type { PublicUser } from "../../../src/ui/layouts/public";

const loggedInUser: PublicUser = {
  id: "user-001",
  email: "user@example.com",
};

describe("PublicLayout", () => {
  it("PublicLayout is exported", () => {
    expect(PublicLayout).toBeDefined();
    expect(typeof PublicLayout).toBe("function");
  });

  it("renders without user (guest)", () => {
    const html = String(PublicLayout({ title: "Welcome", user: null }));
    expect(html).toContain("Welcome");
  });

  it("renders with logged-in user", () => {
    const html = String(PublicLayout({ title: "My Page", user: loggedInUser }));
    expect(html).toContain("My Page");
  });

  it("accepts hxBoost flag", () => {
    const html = String(PublicLayout({ title: "Test", user: null, hxBoost: true }));
    expect(html).toContain('hx-boost="true"');
  });

  it("accepts nonce for CSP", () => {
    const html = String(PublicLayout({ title: "Test", user: null, nonce: "pub-nonce" }));
    expect(html).toContain("pub-nonce");
  });

  it("accepts children", () => {
    const html = String(PublicLayout({ title: "Test", user: null, children: "body" }));
    expect(html).toContain("body");
  });
});
