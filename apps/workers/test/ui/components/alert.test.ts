/**
 * test/ui/components/alert.test.ts — Alert component RED tests
 * Cycle 6 RED phase.
 *
 * GREEN: Alert renders message with variant-specific styles (success/warning/error/info).
 */

import { describe, it, expect } from "vitest";
import { Alert } from "../../../src/ui/components/alert";
import type { AlertVariant } from "../../../src/ui/components/alert";

describe("Alert component (RED phase)", () => {
  it("Alert is exported", () => {
    expect(Alert).toBeDefined();
    expect(typeof Alert).toBe("function");
  });

  const variants: AlertVariant[] = ["success", "warning", "error", "info"];

  for (const variant of variants) {
    it(`renders ${variant} variant`, () => {
      expect(() =>
        Alert({ variant, message: `Test ${variant} message` })
      ).toThrow("not implemented: Alert");
    });
  }

  it("renders message text", () => {
    expect(() =>
      Alert({ variant: "success", message: "Saved successfully" })
    ).toThrow("not implemented: Alert");
  });

  it("renders error message", () => {
    expect(() =>
      Alert({ variant: "error", message: "Something went wrong" })
    ).toThrow("not implemented: Alert");
  });
});
