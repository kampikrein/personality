/**
 * test/ui/layouts/base.test.ts — BaseLayout GREEN tests
 * Cycle 6 GREEN phase (Step 0: antipattern fix).
 *
 * BaseLayout renders <html><head><title>{title}</title></head><body>…</body></html>
 *   - title prop reflected
 *   - nonce passed to meta tag
 *   - children rendered in body
 */

import { describe, it, expect } from "vitest";
import { BaseLayout } from "../../../src/ui/layouts/base";

describe("BaseLayout", () => {
  it("BaseLayout is exported", () => {
    expect(BaseLayout).toBeDefined();
    expect(typeof BaseLayout).toBe("function");
  });

  it("renders html structure with title", () => {
    const html = String(BaseLayout({ title: "Test Page" }));
    expect(html).toContain("<title>Test Page</title>");
  });

  it("accepts nonce prop for CSP inline scripts", () => {
    const html = String(BaseLayout({ title: "Test Page", nonce: "abc123" }));
    expect(html).toContain("abc123");
  });

  it("accepts children prop", () => {
    const html = String(BaseLayout({ title: "Test Page", children: "body content" }));
    expect(html).toContain("body content");
  });
});
