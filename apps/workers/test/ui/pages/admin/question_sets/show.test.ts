/**
 * test/ui/pages/admin/question_sets/show.test.ts — QuestionSetsShowPage RED tests
 * Cycle 6 RED phase.
 *
 * GREEN: Renders question set detail with name, description, active status, edit/delete links.
 */

import { describe, it, expect } from "vitest";
import { QuestionSetsShowPage } from "../../../../../src/ui/pages/admin/question_sets/show";
import type { QuestionSet } from "../../../../../src/ui/pages/admin/question_sets/index";

const qs: QuestionSet = { id: "qs-1", name: "MBTI Set", description: "Core", active: true };

describe("QuestionSetsShowPage (RED phase)", () => {
  it("QuestionSetsShowPage is exported", () => {
    expect(QuestionSetsShowPage).toBeDefined();
    expect(typeof QuestionSetsShowPage).toBe("function");
  });

  it("renders question set detail", () => {
    expect(() =>
      QuestionSetsShowPage({ questionSet: qs })
    ).toThrow("not implemented: QuestionSetsShowPage");
  });
});
