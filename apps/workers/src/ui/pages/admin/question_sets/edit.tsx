/**
 * src/ui/pages/admin/question_sets/edit.tsx — Admin edit question set form stub
 * Cycle 6 RED phase.
 */

import type { QuestionSet } from "./index";

export interface QuestionSetsEditProps {
  questionSet: QuestionSet;
  csrfToken: string;
  errors?: Record<string, string[]>;
}

// RED stub — not implemented
export function QuestionSetsEditPage(_props: QuestionSetsEditProps): unknown {
  throw new Error("not implemented: QuestionSetsEditPage");
}
