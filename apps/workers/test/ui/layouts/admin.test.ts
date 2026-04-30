/**
 * test/ui/layouts/admin.test.ts — AdminLayout RED tests
 * Cycle 6 RED phase.
 *
 * GREEN: AdminLayout renders BaseLayout with admin nav (audit_logs, question_sets, alerts, dashboard)
 *   - user email shown in header
 *   - hx-boost script included
 *   - cfAccessVerifier payload (admin: true) accepted
 */

import { describe, it, expect } from "vitest";
import { AdminLayout } from "../../../src/ui/layouts/admin";
import type { CFAccessPayload } from "../../../src/auth/cfAccessVerifier";

const adminUser: CFAccessPayload = {
  sub: "admin-001",
  email: "admin@personality.app",
  aud: ["test-audience"],
  iss: "https://team.cloudflareaccess.com",
  iat: Math.floor(Date.now() / 1000),
  exp: Math.floor(Date.now() / 1000) + 3600,
  admin: true,
};

describe("AdminLayout (RED phase)", () => {
  it("AdminLayout is exported", () => {
    expect(AdminLayout).toBeDefined();
    expect(typeof AdminLayout).toBe("function");
  });

  it("renders with CF Access admin user", () => {
    expect(() =>
      AdminLayout({ title: "Admin Dashboard", user: adminUser })
    ).toThrow("not implemented: AdminLayout");
  });

  it("accepts nonce for CSP", () => {
    expect(() =>
      AdminLayout({ title: "Admin", user: adminUser, nonce: "nonce-xyz" })
    ).toThrow("not implemented: AdminLayout");
  });

  it("accepts children", () => {
    expect(() =>
      AdminLayout({ title: "Admin", user: adminUser, children: "page content" })
    ).toThrow("not implemented: AdminLayout");
  });

  it("user payload has admin flag", () => {
    // Structural test: AdminLayout prop type accepts admin user
    const props = { title: "Admin", user: adminUser };
    expect(props.user.admin).toBe(true);
    expect(props.user.email).toBe("admin@personality.app");
  });
});
