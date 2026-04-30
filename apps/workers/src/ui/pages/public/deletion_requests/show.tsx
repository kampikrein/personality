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

// RED stub — not implemented
export function DeletionRequestsShowPage(_props: DeletionRequestsShowProps): unknown {
  throw new Error("not implemented: DeletionRequestsShowPage");
}
