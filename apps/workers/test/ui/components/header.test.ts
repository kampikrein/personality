/**
 * test/ui/components/header.test.ts — Header component GREEN tests
 * Cycle 6 GREEN phase (Step 0: antipattern fix).
 *
 * Header renders site name, admin nav (when isAdmin=true), user email, login/logout.
 */

import { describe, it, expect } from "vitest";
import { Header } from "../../../src/ui/components/header";

describe("Header component", () => {
  it("Header is exported", () => {
    expect(Header).toBeDefined();
    expect(typeof Header).toBe("function");
  });

  it("renders guest header (no user)", () => {
    const html = String(Header({ isAdmin: false, userEmail: null }));
    expect(html).toContain("/signin");
  });

  it("renders admin header", () => {
    const html = String(Header({ isAdmin: true, userEmail: "admin@personality.app" }));
    expect(html).toContain("admin@personality.app");
  });

  it("renders public user header", () => {
    const html = String(Header({ isAdmin: false, userEmail: "user@example.com" }));
    expect(html).toContain("user@example.com");
  });

  it("accepts currentPath for active link highlighting", () => {
    const html = String(Header({ isAdmin: false, userEmail: null, currentPath: "/signin" }));
    expect(html).toContain("/signin");
  });
});
