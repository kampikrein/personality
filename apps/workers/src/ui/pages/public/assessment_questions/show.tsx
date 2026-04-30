/**
 * src/ui/pages/public/assessment_questions/show.tsx — Assessment question page stub
 * Cycle 6 RED phase. Maps to Stimulus: likert_controller + countdown_controller + autosave_controller.
 */

export interface AnswerOption {
  value: string;
  label: string;
}

export interface AssessmentQuestionShowProps {
  questionId: string;
  questionText: string;
  options: AnswerOption[];
  csrfToken: string;
  assessmentId: string;
  questionNumber: number;
  totalQuestions: number;
  responseTimeField?: boolean; // countdown_controller target
}

// RED stub — not implemented
export function AssessmentQuestionShowPage(_props: AssessmentQuestionShowProps): unknown {
  throw new Error("not implemented: AssessmentQuestionShowPage");
}
