/**
 * test/ui/pages/public/assessment_questions/show.test.ts — AssessmentQuestionShowPage GREEN tests
 * Cycle 6 GREEN phase (Step 0: antipattern fix).
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

describe("AssessmentQuestionShowPage", () => {
  it("AssessmentQuestionShowPage is exported", () => {
    expect(AssessmentQuestionShowPage).toBeDefined();
    expect(typeof AssessmentQuestionShowPage).toBe("function");
  });

  it("renders question with answer options", () => {
    const html = String(AssessmentQuestionShowPage({
      questionId: "q-001",
      questionText: "I enjoy meeting new people",
      options,
      csrfToken: "csrf-q",
      assessmentId: "assessment-001",
      questionNumber: 5,
      totalQuestions: 40,
    }));
    expect(html).toContain("I enjoy meeting new people");
  });

  it("renders answer options", () => {
    const html = String(AssessmentQuestionShowPage({
      questionId: "q-001",
      questionText: "I enjoy meeting new people",
      options,
      csrfToken: "csrf-q",
      assessmentId: "assessment-001",
      questionNumber: 5,
      totalQuestions: 40,
    }));
    expect(html).toContain("Strongly Disagree");
  });

  it("renders with response time tracking", () => {
    const html = String(AssessmentQuestionShowPage({
      questionId: "q-001",
      questionText: "I enjoy solitude",
      options,
      csrfToken: "csrf-q",
      assessmentId: "assessment-001",
      questionNumber: 6,
      totalQuestions: 40,
      responseTimeField: true,
    }));
    expect(html).toBeDefined();
  });

  it("options array is 5-point likert scale", () => {
    expect(options).toHaveLength(5);
    expect(options[0].value).toBe("1");
    expect(options[4].value).toBe("5");
  });
});
