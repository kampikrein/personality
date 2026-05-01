/**
 * src/ui/pages/public/assessments/show.tsx — Assessment progress page stub
 * Cycle 6 RED phase.
 */

export interface AssessmentShowProps {
  assessmentId: string;
  progress: number;       // 0–100
  totalQuestions: number;
  answeredQuestions: number;
}

export function AssessmentShowPage(props: AssessmentShowProps): string {
  return `<div class="assessment-show">
  <h1>Assessment Progress</h1>
  <div class="progress-bar">
    <div class="progress" style="width:${props.progress}%"></div>
  </div>
  <p>${props.answeredQuestions} / ${props.totalQuestions} questions answered</p>
  ${props.progress < 100
    ? `<a href="/api/assessments/${props.assessmentId}/next_question">Continue</a>`
    : `<a href="/results/${props.assessmentId}">View Results</a>`
  }
</div>`;
}
