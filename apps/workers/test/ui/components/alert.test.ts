/**
 * test/ui/components/alert.test.ts — Alert component GREEN tests
 * Cycle 6 GREEN phase (Step 0: antipattern fix).
 *
 * Alert renders message with variant-specific styles (success/warning/error/info).
 */

import { describe, it, expect } from "vitest";
import { Alert } from "../../../src/ui/components/alert";
import type { AlertVariant } from "../../../src/ui/components/alert";

describe("Alert component", () => {
  it("Alert is exported", () => {
    expect(Alert).toBeDefined();
    expect(typeof Alert).toBe("function");
  });

  const variants: AlertVariant[] = ["success", "warning", "error", "info"];

  for (const variant of variants) {
    it(`renders ${variant} variant`, () => {
      const html = String(Alert({ variant, message: `Test ${variant} message` }));
      expect(html).toContain(variant);
    });
  }

  it("renders message text", () => {
    const html = String(Alert({ variant: "success", message: "Saved successfully" }));
    expect(html).toContain("Saved successfully");
  });

  it("renders error message", () => {
    const html = String(Alert({ variant: "error", message: "Something went wrong" }));
    expect(html).toContain("Something went wrong");
  });
});
