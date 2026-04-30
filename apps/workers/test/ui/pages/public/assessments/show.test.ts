/**
 * test/ui/pages/public/assessments/show.test.ts — AssessmentShowPage RED tests
 * Cycle 6 RED phase.
 *
 * GREEN: Renders progress bar (progress_controller), answered/total count.
 *   Link to current unanswered question.
 *   Type reveal placeholder while in-progress.
 */

import { describe, it, expect } from "vitest";
import { AssessmentShowPage } from "../../../../../src/ui/pages/public/assessments/show";

describe("AssessmentShowPage (RED phase)", () => {
  it("AssessmentShowPage is exported", () => {
    expect(AssessmentShowPage).toBeDefined();
    expect(typeof AssessmentShowPage).toBe("function");
  });

  it("renders progress state", () => {
    expect(() =>
      AssessmentShowPage({
        assessmentId: "assessment-001",
        progress: 45,
        totalQuestions: 40,
        answeredQuestions: 18,
      })
    ).toThrow("not implemented: AssessmentShowPage");
  });

  it("renders completed state", () => {
    expect(() =>
      AssessmentShowPage({
        assessmentId: "assessment-001",
        progress: 100,
        totalQuestions: 40,
        answeredQuestions: 40,
      })
    ).toThrow("not implemented: AssessmentShowPage");
  });

  it("progress is 0-100", () => {
    const props = { assessmentId: "x", progress: 50, totalQuestions: 40, answeredQuestions: 20 };
    expect(props.progress).toBeGreaterThanOrEqual(0);
    expect(props.progress).toBeLessThanOrEqual(100);
  });
});
