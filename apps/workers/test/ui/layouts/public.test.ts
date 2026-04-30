/**
 * test/ui/layouts/public.test.ts — PublicLayout RED tests
 * Cycle 6 RED phase.
 *
 * GREEN: PublicLayout renders with:
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

describe("PublicLayout (RED phase)", () => {
  it("PublicLayout is exported", () => {
    expect(PublicLayout).toBeDefined();
    expect(typeof PublicLayout).toBe("function");
  });

  it("renders without user (guest)", () => {
    expect(() =>
      PublicLayout({ title: "Welcome", user: null })
    ).toThrow("not implemented: PublicLayout");
  });

  it("renders with logged-in user", () => {
    expect(() =>
      PublicLayout({ title: "My Page", user: loggedInUser })
    ).toThrow("not implemented: PublicLayout");
  });

  it("accepts hxBoost flag", () => {
    expect(() =>
      PublicLayout({ title: "Test", user: null, hxBoost: true })
    ).toThrow("not implemented: PublicLayout");
  });

  it("accepts nonce for CSP", () => {
    expect(() =>
      PublicLayout({ title: "Test", user: null, nonce: "pub-nonce" })
    ).toThrow("not implemented: PublicLayout");
  });

  it("accepts children", () => {
    expect(() =>
      PublicLayout({ title: "Test", user: null, children: "body" })
    ).toThrow("not implemented: PublicLayout");
  });
});
