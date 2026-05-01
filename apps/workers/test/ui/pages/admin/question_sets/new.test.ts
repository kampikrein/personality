/**
 * test/ui/pages/admin/question_sets/new.test.ts — QuestionSetsNewPage GREEN tests
 * Cycle 6 GREEN phase (Step 0: antipattern fix).
 *
 * GREEN: Renders create form (name, description, active checkbox) with CSRF + validation messages.
 */

import { describe, it, expect } from "vitest";
import { QuestionSetsNewPage } from "../../../../../src/ui/pages/admin/question_sets/new";

describe("QuestionSetsNewPage", () => {
  it("QuestionSetsNewPage is exported", () => {
    expect(QuestionSetsNewPage).toBeDefined();
    expect(typeof QuestionSetsNewPage).toBe("function");
  });

  it("renders create form", () => {
    const html = String(QuestionSetsNewPage({ csrfToken: "csrf-abc" }));
    expect(html).toContain("csrf-abc");
  });

  it("renders with validation errors", () => {
    const html = String(QuestionSetsNewPage({ csrfToken: "csrf-abc", errors: { name: ["can't be blank"] } }));
    expect(html).toContain("can't be blank");
  });
});
