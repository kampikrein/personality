/**
 * src/ui/pages/admin/question_sets/new.tsx — Admin new question set form stub
 * Cycle 6 RED phase.
 */

export interface QuestionSetsNewProps {
  csrfToken: string;
  errors?: Record<string, string[]>;
}

export function QuestionSetsNewPage(props: QuestionSetsNewProps): string {
  const errorMessages = props.errors
    ? Object.values(props.errors).flat().map((e) => `<p class="error">${e}</p>`).join("")
    : "";

  return `<div class="admin-question-set-new">
  <h1>New Question Set</h1>
  ${errorMessages}
  <form method="post" action="/admin/question_sets">
    <input type="hidden" name="csrf_token" value="${props.csrfToken}">
    <label>Name<input type="text" name="name"></label>
    <label>Description<textarea name="description"></textarea></label>
    <label><input type="checkbox" name="active" value="1"> Active</label>
    <button type="submit">Create</button>
  </form>
</div>`;
}
