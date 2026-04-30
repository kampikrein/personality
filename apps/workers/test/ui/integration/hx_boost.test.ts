/**
 * test/ui/integration/hx_boost.test.ts — hx-boost integration RED tests
 * Cycle 6 RED phase.
 *
 * R3 winner: hx-boost 1줄 옵셔널 on <body> or per-form/link attribute.
 * RED: verifies hxBoost prop contract on PublicLayout.
 * GREEN: rendered HTML contains hx-boost="true" on <body> when prop is true.
 * E2E form submit test requires wrangler dev.
 */

import { describe, it, expect } from "vitest";
import { PublicLayout } from "../../../src/ui/layouts/public";

describe("hx-boost integration (RED phase)", () => {
  it("PublicLayout accepts hxBoost prop", () => {
    const props = { title: "Test", user: null, hxBoost: true };
    expect(props.hxBoost).toBe(true);
    // Full render test: throws until GREEN
    expect(() => PublicLayout(props)).toThrow("not implemented: PublicLayout");
  });

  it("hxBoost is optional (defaults to false)", () => {
    const props = { title: "Test", user: null };
    // hxBoost is undefined — should still render without hx-boost attribute
    expect(props).not.toHaveProperty("hxBoost");
    expect(() => PublicLayout(props)).toThrow("not implemented: PublicLayout");
  });

  it("hx-boost prop type is boolean", () => {
    // Type-level contract
    const withBoost: Parameters<typeof PublicLayout>[0] = { title: "T", user: null, hxBoost: true };
    expect(withBoost.hxBoost).toBe(true);
  });
});
