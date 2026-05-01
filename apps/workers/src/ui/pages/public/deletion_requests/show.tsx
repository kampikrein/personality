/**
 * src/ui/pages/public/deletion_requests/show.tsx — Delete request status stub
 * Cycle 6 RED phase.
 */

export type DeletionStatus = "pending" | "approved" | "rejected" | "completed";

export interface DeletionRequest {
  id: string;
  status: DeletionStatus;
  requested_at: string;
  processed_at?: string;
}

export interface DeletionRequestsShowProps {
  deletionRequest: DeletionRequest;
}

export function DeletionRequestsShowPage(props: DeletionRequestsShowProps): string {
  const { deletionRequest: dr } = props;
  const processedAt = dr.processed_at
    ? `<p>Processed: ${dr.processed_at}</p>`
    : "";

  return `<div class="deletion-request-show">
  <h1>Deletion Request Status</h1>
  <p>Status: ${dr.status}</p>
  <p>Requested: ${dr.requested_at}</p>
  ${processedAt}
</div>`;
}
