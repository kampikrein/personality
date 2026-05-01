/**
 * src/ui/pages/public/deletion_requests/new.tsx — Delete request form stub
 * Cycle 6 RED phase.
 */

export interface DeletionRequestsNewProps {
  csrfToken: string;
  userId: string;
}

export function DeletionRequestsNewPage(props: DeletionRequestsNewProps): string {
  return `<div class="deletion-request-new">
  <h1>Request Data Deletion</h1>
  <p class="warning">Warning: This action will permanently delete all your data and cannot be undone.</p>
  <form method="post" action="/api/deletion_requests">
    <input type="hidden" name="csrf_token" value="${props.csrfToken}">
    <input type="hidden" name="user_id" value="${props.userId}">
    <button type="submit" class="danger-btn">Confirm Delete My Data</button>
  </form>
  <a href="/settings">Cancel</a>
</div>`;
}
