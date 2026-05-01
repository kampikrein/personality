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

export function QuestionSetsIndexPage(props: QuestionSetsIndexProps): string {
  const rows = props.questionSets.map(
    (qs) =>
      `<tr>
    <td><a href="/admin/question_sets/${qs.id}">${qs.name}</a></td>
    <td>${qs.active ? "Active" : "Inactive"}</td>
    <td>
      <a href="/admin/question_sets/${qs.id}/edit">Edit</a>
      <form method="post" action="/admin/question_sets/${qs.id}" style="display:inline">
        <input type="hidden" name="_method" value="DELETE">
        <button type="submit">Delete</button>
      </form>
    </td>
  </tr>`
  ).join("");

  return `<div class="admin-question-sets">
  <h1>Question Sets</h1>
  <a href="/admin/question_sets/new">New Question Set</a>
  <table>
    <thead><tr><th>Name</th><th>Status</th><th>Actions</th></tr></thead>
    <tbody>${rows}</tbody>
  </table>
</div>`;
}
