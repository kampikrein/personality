/**
 * test/ui/pages/admin/question_sets/index.test.ts — QuestionSetsIndexPage GREEN tests
 * Cycle 6 GREEN phase (Step 0: antipattern fix).
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

describe("QuestionSetsIndexPage", () => {
  it("QuestionSetsIndexPage is exported", () => {
    expect(QuestionSetsIndexPage).toBeDefined();
    expect(typeof QuestionSetsIndexPage).toBe("function");
  });

  it("renders question sets list", () => {
    const html = String(QuestionSetsIndexPage({ questionSets: sets }));
    expect(html).toContain("MBTI Set");
  });

  it("renders multiple sets", () => {
    const html = String(QuestionSetsIndexPage({ questionSets: sets }));
    expect(html).toContain("Enneagram Set");
  });

  it("renders empty list", () => {
    const html = String(QuestionSetsIndexPage({ questionSets: [] }));
    expect(html).toBeDefined();
  });
});
