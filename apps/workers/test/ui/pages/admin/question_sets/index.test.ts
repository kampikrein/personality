/**
 * test/ui/pages/admin/question_sets/index.test.ts — QuestionSetsIndexPage RED tests
 * Cycle 6 RED phase.
 *
 * GREEN: Renders list with name, active status, links to show/edit/delete.
 */

import { describe, it, expect } from "vitest";
import { QuestionSetsIndexPage } from "../../../../../src/ui/pages/admin/question_sets/index";
import type { QuestionSet } from "../../../../../src/ui/pages/admin/question_sets/index";

const sets: QuestionSet[] = [
  { id: "qs-1", name: "MBTI Set", description: "Core MBTI questions", active: true },
  { id: "qs-2", name: "Enneagram Set", description: "Enneagram questions", active: false },
];

describe("QuestionSetsIndexPage (RED phase)", () => {
  it("QuestionSetsIndexPage is exported", () => {
    expect(QuestionSetsIndexPage).toBeDefined();
    expect(typeof QuestionSetsIndexPage).toBe("function");
  });

  it("renders question sets list", () => {
    expect(() =>
      QuestionSetsIndexPage({ questionSets: sets })
    ).toThrow("not implemented: QuestionSetsIndexPage");
  });

  it("renders empty list", () => {
    expect(() =>
      QuestionSetsIndexPage({ questionSets: [] })
    ).toThrow("not implemented: QuestionSetsIndexPage");
  });
});
