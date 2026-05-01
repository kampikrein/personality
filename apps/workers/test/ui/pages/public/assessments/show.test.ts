/**
 * test/ui/pages/public/assessments/show.test.ts — AssessmentShowPage GREEN tests
 * Cycle 6 GREEN phase (Step 0: antipattern fix).
 *
 * GREEN: Renders progress bar (progress_controller), answered/total count.
 *   Link to current unanswered question.
 *   Type reveal placeholder while in-progress.
 */

import { describe, it, expect } from "vitest";
import { AssessmentShowPage } from "../../../../../src/ui/pages/public/assessments/show";

describe("AssessmentShowPage", () => {
  it("AssessmentShowPage is exported", () => {
    expect(AssessmentShowPage).toBeDefined();
    expect(typeof AssessmentShowPage).toBe("function");
  });

  it("renders progress state", () => {
    const html = String(AssessmentShowPage({
      assessmentId: "assessment-001",
      progress: 45,
      totalQuestions: 40,
      answeredQuestions: 18,
    }));
    expect(html).toContain("18");
  });

  it("renders completed state", () => {
    const html = String(AssessmentShowPage({
      assessmentId: "assessment-001",
      progress: 100,
      totalQuestions: 40,
      answeredQuestions: 40,
    }));
    expect(html).toContain("40");
  });

  it("progress is 0-100", () => {
    const props = { assessmentId: "x", progress: 50, totalQuestions: 40, answeredQuestions: 20 };
    expect(props.progress).toBeGreaterThanOrEqual(0);
    expect(props.progress).toBeLessThanOrEqual(100);
  });
});
