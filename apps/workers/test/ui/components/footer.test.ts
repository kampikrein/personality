/**
 * test/ui/components/footer.test.ts — Footer component RED tests
 * Cycle 6 RED phase.
 *
 * GREEN: Footer renders copyright year, links (privacy, terms, contact).
 */

import { describe, it, expect } from "vitest";
import { Footer } from "../../../src/ui/components/footer";

describe("Footer component (RED phase)", () => {
  it("Footer is exported", () => {
    expect(Footer).toBeDefined();
    expect(typeof Footer).toBe("function");
  });

  it("renders with default year", () => {
    expect(() =>
      Footer({})
    ).toThrow("not implemented: Footer");
  });

  it("renders with explicit year", () => {
    expect(() =>
      Footer({ year: 2026 })
    ).toThrow("not implemented: Footer");
  });
});
