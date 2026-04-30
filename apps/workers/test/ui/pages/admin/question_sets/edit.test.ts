/**
 * test/ui/pages/admin/question_sets/edit.test.ts — QuestionSetsEditPage RED tests
 * Cycle 6 RED phase.
 *
 * GREEN: Renders edit form pre-filled with existing values + CSRF + validation messages.
 */

import { describe, it, expect } from "vitest";
import { QuestionSetsEditPage } from "../../../../../src/ui/pages/admin/question_sets/edit";
import type { QuestionSet } from "../../../../../src/ui/pages/admin/question_sets/index";

const qs: QuestionSet = { id: "qs-1", name: "MBTI Set", description: "Core", active: true };

describe("QuestionSetsEditPage (RED phase)", () => {
  it("QuestionSetsEditPage is exported", () => {
    expect(QuestionSetsEditPage).toBeDefined();
    expect(typeof QuestionSetsEditPage).toBe("function");
  });

  it("renders edit form with existing values", () => {
    expect(() =>
      QuestionSetsEditPage({ questionSet: qs, csrfToken: "csrf-xyz" })
    ).toThrow("not implemented: QuestionSetsEditPage");
  });

  it("renders with validation errors", () => {
    expect(() =>
      QuestionSetsEditPage({
        questionSet: qs,
        csrfToken: "csrf-xyz",
        errors: { name: ["is too short"] },
      })
    ).toThrow("not implemented: QuestionSetsEditPage");
  });
});
