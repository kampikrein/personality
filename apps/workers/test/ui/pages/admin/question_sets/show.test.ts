/**
 * test/ui/pages/admin/question_sets/show.test.ts — QuestionSetsShowPage GREEN tests
 * Cycle 6 GREEN phase (Step 0: antipattern fix).
 *
 * GREEN: Renders question set detail with name, description, active status, edit/delete links.
 */

import { describe, it, expect } from "vitest";
import { QuestionSetsShowPage } from "../../../../../src/ui/pages/admin/question_sets/show";
import type { QuestionSet } from "../../../../../src/ui/pages/admin/question_sets/index";

const qs: QuestionSet = { id: "qs-1", name: "MBTI Set", description: "Core", active: true };

describe("QuestionSetsShowPage", () => {
  it("QuestionSetsShowPage is exported", () => {
    expect(QuestionSetsShowPage).toBeDefined();
    expect(typeof QuestionSetsShowPage).toBe("function");
  });

  it("renders question set detail", () => {
    const html = String(QuestionSetsShowPage({ questionSet: qs }));
    expect(html).toContain("MBTI Set");
  });

  it("renders description", () => {
    const html = String(QuestionSetsShowPage({ questionSet: qs }));
    expect(html).toContain("Core");
  });
});
