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

// RED stub — not implemented
export function AssessmentShowPage(_props: AssessmentShowProps): unknown {
  throw new Error("not implemented: AssessmentShowPage");
}
