/**
 * test/ui/components/header.test.ts — Header component RED tests
 * Cycle 6 RED phase.
 *
 * GREEN: Header renders site name, admin nav (when isAdmin=true), user email, login/logout.
 */

import { describe, it, expect } from "vitest";
import { Header } from "../../../src/ui/components/header";

describe("Header component (RED phase)", () => {
  it("Header is exported", () => {
    expect(Header).toBeDefined();
    expect(typeof Header).toBe("function");
  });

  it("renders guest header (no user)", () => {
    expect(() =>
      Header({ isAdmin: false, userEmail: null })
    ).toThrow("not implemented: Header");
  });

  it("renders admin header", () => {
    expect(() =>
      Header({ isAdmin: true, userEmail: "admin@personality.app" })
    ).toThrow("not implemented: Header");
  });

  it("renders public user header", () => {
    expect(() =>
      Header({ isAdmin: false, userEmail: "user@example.com" })
    ).toThrow("not implemented: Header");
  });

  it("accepts currentPath for active link highlighting", () => {
    expect(() =>
      Header({ isAdmin: false, userEmail: null, currentPath: "/signin" })
    ).toThrow("not implemented: Header");
  });
});
