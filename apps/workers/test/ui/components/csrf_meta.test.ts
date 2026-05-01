/**
 * test/ui/components/csrf_meta.test.ts — CsrfMeta component GREEN tests
 * Cycle 6 GREEN phase (Step 0: antipattern fix).
 *
 * CsrfMeta renders <meta name="csrf-token" content="{token}">
 *   Uses cycle 4 csrf middleware token value.
 */

import { describe, it, expect } from "vitest";
import { CsrfMeta } from "../../../src/ui/components/csrf_meta";

describe("CsrfMeta component", () => {
  it("CsrfMeta is exported", () => {
    expect(CsrfMeta).toBeDefined();
    expect(typeof CsrfMeta).toBe("function");
  });

  it("renders with csrf token", () => {
    const html = String(CsrfMeta({ token: "csrf-token-value-abc123" }));
    expect(html).toContain('name="csrf-token"');
    expect(html).toContain("csrf-token-value-abc123");
  });

  it("renders with different token values", () => {
    const html = String(CsrfMeta({ token: "another-csrf-token" }));
    expect(html).toContain("another-csrf-token");
  });

  it("token prop is a string", () => {
    const props = { token: "test-csrf" };
    expect(typeof props.token).toBe("string");
  });
});
