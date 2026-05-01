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

export function AssessmentQuestionShowPage(props: AssessmentQuestionShowProps): string {
  const optionsHtml = props.options.map(
    (opt) =>
      `<label class="likert-option">
    <input type="radio" name="answer" value="${opt.value}">
    ${opt.label}
  </label>`
  ).join("");

  const responseTimeField = props.responseTimeField
    ? `<input type="hidden" name="response_time" id="response_time" value="0">`
    : "";

  return `<div class="assessment-question">
  <div class="progress-bar">
    <div class="progress" style="width:${Math.round((props.questionNumber / props.totalQuestions) * 100)}%"></div>
  </div>
  <p class="question-count">${props.questionNumber} / ${props.totalQuestions}</p>
  <form method="post" action="/api/assessment_questions/${props.questionId}/answer">
    <input type="hidden" name="csrf_token" value="${props.csrfToken}">
    <input type="hidden" name="assessment_id" value="${props.assessmentId}">
    ${responseTimeField}
    <p class="question-text">${props.questionText}</p>
    <div class="likert-scale">${optionsHtml}</div>
    <button type="submit" class="skip-btn">Skip</button>
  </form>
</div>`;
}
