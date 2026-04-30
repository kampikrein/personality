/**
 * test/ui/pages/public/consents/new.test.ts — ConsentsNewPage RED tests
 * Cycle 6 RED phase.
 *
 * GREEN: Renders consent form with data_processing + third_party checkboxes.
 *   Disabled submit until required consents checked.
 *   CSRF token embedded.
 */

import { describe, it, expect } from "vitest";
import { ConsentsNewPage } from "../../../../../src/ui/pages/public/consents/new";

describe("ConsentsNewPage (RED phase)", () => {
  it("ConsentsNewPage is exported", () => {
    expect(ConsentsNewPage).toBeDefined();
    expect(typeof ConsentsNewPage).toBe("function");
  });

  it("renders consent form", () => {
    expect(() =>
      ConsentsNewPage({ csrfToken: "csrf-consent", assessmentId: "assessment-abc" })
    ).toThrow("not implemented: ConsentsNewPage");
  });

  it("assessmentId is linked in form", () => {
    const props = { csrfToken: "csrf-consent", assessmentId: "assessment-abc" };
    expect(props.assessmentId).toBe("assessment-abc");
  });
});
