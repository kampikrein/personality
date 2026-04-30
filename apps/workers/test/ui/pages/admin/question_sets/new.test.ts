/**
 * test/ui/pages/admin/question_sets/new.test.ts — QuestionSetsNewPage RED tests
 * Cycle 6 RED phase.
 *
 * GREEN: Renders create form (name, description, active checkbox) with CSRF + validation messages.
 */

import { describe, it, expect } from "vitest";
import { QuestionSetsNewPage } from "../../../../../src/ui/pages/admin/question_sets/new";

describe("QuestionSetsNewPage (RED phase)", () => {
  it("QuestionSetsNewPage is exported", () => {
    expect(QuestionSetsNewPage).toBeDefined();
    expect(typeof QuestionSetsNewPage).toBe("function");
  });

  it("renders create form", () => {
    expect(() =>
      QuestionSetsNewPage({ csrfToken: "csrf-abc" })
    ).toThrow("not implemented: QuestionSetsNewPage");
  });

  it("renders with validation errors", () => {
    expect(() =>
      QuestionSetsNewPage({ csrfToken: "csrf-abc", errors: { name: ["can't be blank"] } })
    ).toThrow("not implemented: QuestionSetsNewPage");
  });
});
