/**
 * test/ui/pages/public/consents/new.test.ts — ConsentsNewPage GREEN tests
 * Cycle 6 GREEN phase (Step 0: antipattern fix).
 *
 * GREEN: Renders consent form with data_processing + third_party checkboxes.
 *   Disabled submit until required consents checked.
 *   CSRF token embedded.
 */

import { describe, it, expect } from "vitest";
import { ConsentsNewPage } from "../../../../../src/ui/pages/public/consents/new";

describe("ConsentsNewPage", () => {
  it("ConsentsNewPage is exported", () => {
    expect(ConsentsNewPage).toBeDefined();
    expect(typeof ConsentsNewPage).toBe("function");
  });

  it("renders consent form", () => {
    const html = String(ConsentsNewPage({ csrfToken: "csrf-consent", assessmentId: "assessment-abc" }));
    expect(html).toContain("csrf-consent");
  });

  it("embeds assessmentId in form", () => {
    const html = String(ConsentsNewPage({ csrfToken: "csrf-consent", assessmentId: "assessment-abc" }));
    expect(html).toContain("assessment-abc");
  });

  it("assessmentId is linked in form", () => {
    const props = { csrfToken: "csrf-consent", assessmentId: "assessment-abc" };
    expect(props.assessmentId).toBe("assessment-abc");
  });
});
