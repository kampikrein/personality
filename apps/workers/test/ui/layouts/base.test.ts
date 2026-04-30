/**
 * test/ui/layouts/base.test.ts — BaseLayout RED tests
 * Cycle 6 RED phase.
 *
 * GREEN: BaseLayout renders <html><head><title>{title}</title></head><body>…</body></html>
 *   - title prop reflected
 *   - nonce passed to <script> tags
 *   - children rendered in body
 */

import { describe, it, expect } from "vitest";
import { BaseLayout } from "../../../src/ui/layouts/base";

describe("BaseLayout (RED phase)", () => {
  it("BaseLayout is exported", () => {
    expect(BaseLayout).toBeDefined();
    expect(typeof BaseLayout).toBe("function");
  });

  it("renders html structure with title", () => {
    expect(() =>
      BaseLayout({ title: "Test Page" })
    ).toThrow("not implemented: BaseLayout");
  });

  it("accepts nonce prop for CSP inline scripts", () => {
    expect(() =>
      BaseLayout({ title: "Test Page", nonce: "abc123" })
    ).toThrow("not implemented: BaseLayout");
  });

  it("accepts children prop", () => {
    expect(() =>
      BaseLayout({ title: "Test Page", children: "body content" })
    ).toThrow("not implemented: BaseLayout");
  });
});
