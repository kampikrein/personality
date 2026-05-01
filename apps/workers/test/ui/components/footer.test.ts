/**
 * test/ui/components/footer.test.ts — Footer component GREEN tests
 * Cycle 6 GREEN phase (Step 0: antipattern fix).
 *
 * Footer renders copyright year, links (privacy, terms, contact).
 */

import { describe, it, expect } from "vitest";
import { Footer } from "../../../src/ui/components/footer";

describe("Footer component", () => {
  it("Footer is exported", () => {
    expect(Footer).toBeDefined();
    expect(typeof Footer).toBe("function");
  });

  it("renders with default year", () => {
    const html = String(Footer({}));
    expect(html).toContain("©");
  });

  it("renders with explicit year", () => {
    const html = String(Footer({ year: 2026 }));
    expect(html).toContain("2026");
  });
});
