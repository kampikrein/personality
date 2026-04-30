/**
 * test/ui/components/csrf_meta.test.ts — CsrfMeta component RED tests
 * Cycle 6 RED phase.
 *
 * GREEN: CsrfMeta renders <meta name="csrf-token" content="{token}">
 *   Uses cycle 4 csrf middleware token value.
 */

import { describe, it, expect } from "vitest";
import { CsrfMeta } from "../../../src/ui/components/csrf_meta";

describe("CsrfMeta component (RED phase)", () => {
  it("CsrfMeta is exported", () => {
    expect(CsrfMeta).toBeDefined();
    expect(typeof CsrfMeta).toBe("function");
  });

  it("renders with csrf token", () => {
    expect(() =>
      CsrfMeta({ token: "csrf-token-value-abc123" })
    ).toThrow("not implemented: CsrfMeta");
  });

  it("renders with different token values", () => {
    expect(() =>
      CsrfMeta({ token: "another-csrf-token" })
    ).toThrow("not implemented: CsrfMeta");
  });

  it("token prop is a string", () => {
    const props = { token: "test-csrf" };
    expect(typeof props.token).toBe("string");
  });
});
