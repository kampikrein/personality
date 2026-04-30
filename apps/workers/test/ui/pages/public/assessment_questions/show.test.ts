/**
 * test/ui/pages/public/assessment_questions/show.test.ts — AssessmentQuestionShowPage RED tests
 * Cycle 6 RED phase.
 *
 * Stimulus mapping:
 *   - likert_controller: select → submit on click (200ms delay)
 *   - countdown_controller: response_time field populated on form submit
 *   - autosave_controller: sessionStorage save/restore of progress
 *   - questionnaire_controller: outer orchestrator
 *   - progress_controller: bar animation
 *
 * GREEN: Renders question text, answer options (radio/likert), CSRF, progress indicator,
 *   skip button, hidden response_time field.
 */

import { describe, it, expect } from "vitest";
import { AssessmentQuestionShowPage } from "../../../../../src/ui/pages/public/assessment_questions/show";
import type { AnswerOption } from "../../../../../src/ui/pages/public/assessment_questions/show";

const options: AnswerOption[] = [
  { value: "1", label: "Strongly Disagree" },
  { value: "2", label: "Disagree" },
  { value: "3", label: "Neutral" },
  { value: "4", label: "Agree" },
  { value: "5", label: "Strongly Agree" },
];

describe("AssessmentQuestionShowPage (RED phase)", () => {
  it("AssessmentQuestionShowPage is exported", () => {
    expect(AssessmentQuestionShowPage).toBeDefined();
    expect(typeof AssessmentQuestionShowPage).toBe("function");
  });

  it("renders question with answer options", () => {
    expect(() =>
      AssessmentQuestionShowPage({
        questionId: "q-001",
        questionText: "I enjoy meeting new people",
        options,
        csrfToken: "csrf-q",
        assessmentId: "assessment-001",
        questionNumber: 5,
        totalQuestions: 40,
      })
    ).toThrow("not implemented: AssessmentQuestionShowPage");
  });

  it("renders with response time tracking", () => {
    expect(() =>
      AssessmentQuestionShowPage({
        questionId: "q-001",
        questionText: "I enjoy solitude",
        options,
        csrfToken: "csrf-q",
        assessmentId: "assessment-001",
        questionNumber: 6,
        totalQuestions: 40,
        responseTimeField: true,
      })
    ).toThrow("not implemented: AssessmentQuestionShowPage");
  });

  it("options array is 5-point likert scale", () => {
    expect(options).toHaveLength(5);
    expect(options[0].value).toBe("1");
    expect(options[4].value).toBe("5");
  });
});
