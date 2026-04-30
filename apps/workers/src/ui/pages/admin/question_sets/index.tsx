/**
 * src/ui/pages/admin/question_sets/index.tsx — Admin question sets list stub
 * Cycle 6 RED phase.
 */

export interface QuestionSet {
  id: string;
  name: string;
  description?: string;
  active: boolean;
}

export interface QuestionSetsIndexProps {
  questionSets: QuestionSet[];
}

// RED stub — not implemented
export function QuestionSetsIndexPage(_props: QuestionSetsIndexProps): unknown {
  throw new Error("not implemented: QuestionSetsIndexPage");
}
