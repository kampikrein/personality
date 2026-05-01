/**
 * src/ui/pages/admin/question_sets/show.tsx — Admin question set detail stub
 * Cycle 6 RED phase.
 */

import type { QuestionSet } from "./index";

export interface QuestionSetsShowProps {
  questionSet: QuestionSet;
}

export function QuestionSetsShowPage(props: QuestionSetsShowProps): string {
  const { questionSet: qs } = props;
  return `<div class="admin-question-set-detail">
  <h1>${qs.name}</h1>
  <p>${qs.description ?? ""}</p>
  <p>Status: ${qs.active ? "Active" : "Inactive"}</p>
  <a href="/admin/question_sets/${qs.id}/edit">Edit</a>
  <form method="post" action="/admin/question_sets/${qs.id}">
    <input type="hidden" name="_method" value="DELETE">
    <button type="submit">Delete</button>
  </form>
</div>`;
}
