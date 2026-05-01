/**
 * test/ui/pages/admin/question_sets/edit.test.ts — QuestionSetsEditPage GREEN tests
 * Cycle 6 GREEN phase (Step 0: antipattern fix).
 *
 * GREEN: Renders edit form pre-filled with existing values + CSRF + validation messages.
 */

import { describe, it, expect } from "vitest";
import { QuestionSetsEditPage } from "../../../../../src/ui/pages/admin/question_sets/edit";
import type { QuestionSet } from "../../../../../src/ui/pages/admin/question_sets/index";

const qs: QuestionSet = { id: "qs-1", name: "MBTI Set", description: "Core", active: true };

describe("QuestionSetsEditPage", () => {
  it("QuestionSetsEditPage is exported", () => {
    expect(QuestionSetsEditPage).toBeDefined();
    expect(typeof QuestionSetsEditPage).toBe("function");
  });

  it("renders edit form with existing values", () => {
    const html = String(QuestionSetsEditPage({ questionSet: qs, csrfToken: "csrf-xyz" }));
    expect(html).toContain("MBTI Set");
  });

  it("renders csrf token", () => {
    const html = String(QuestionSetsEditPage({ questionSet: qs, csrfToken: "csrf-xyz" }));
    expect(html).toContain("csrf-xyz");
  });

  it("renders with validation errors", () => {
    const html = String(QuestionSetsEditPage({
      questionSet: qs,
      csrfToken: "csrf-xyz",
      errors: { name: ["is too short"] },
    }));
    expect(html).toContain("is too short");
  });
});
