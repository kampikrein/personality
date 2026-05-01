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

export function QuestionSetsEditPage(props: QuestionSetsEditProps): string {
  const { questionSet: qs } = props;
  const errorMessages = props.errors
    ? Object.values(props.errors).flat().map((e) => `<p class="error">${e}</p>`).join("")
    : "";

  return `<div class="admin-question-set-edit">
  <h1>Edit: ${qs.name}</h1>
  ${errorMessages}
  <form method="post" action="/admin/question_sets/${qs.id}">
    <input type="hidden" name="_method" value="PATCH">
    <input type="hidden" name="csrf_token" value="${props.csrfToken}">
    <label>Name<input type="text" name="name" value="${qs.name}"></label>
    <label>Description<textarea name="description">${qs.description ?? ""}</textarea></label>
    <label><input type="checkbox" name="active" value="1"${qs.active ? " checked" : ""}> Active</label>
    <button type="submit">Update</button>
  </form>
</div>`;
}
