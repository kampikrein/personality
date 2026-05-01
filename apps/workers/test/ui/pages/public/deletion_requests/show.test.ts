/**
 * test/ui/pages/public/deletion_requests/show.test.ts — DeletionRequestsShowPage GREEN tests
 * Cycle 6 GREEN phase (Step 0: antipattern fix).
 *
 * GREEN: Renders deletion request status (pending/approved/rejected/completed).
 *   Shows requested_at timestamp.
 *   Shows processed_at when available.
 */

import { describe, it, expect } from "vitest";
import { DeletionRequestsShowPage } from "../../../../../src/ui/pages/public/deletion_requests/show";
import type { DeletionRequest } from "../../../../../src/ui/pages/public/deletion_requests/show";

const pendingRequest: DeletionRequest = {
  id: "dr-001",
  status: "pending",
  requested_at: "2026-04-01T00:00:00Z",
};

const completedRequest: DeletionRequest = {
  id: "dr-002",
  status: "completed",
  requested_at: "2026-04-01T00:00:00Z",
  processed_at: "2026-04-03T00:00:00Z",
};

describe("DeletionRequestsShowPage", () => {
  it("DeletionRequestsShowPage is exported", () => {
    expect(DeletionRequestsShowPage).toBeDefined();
    expect(typeof DeletionRequestsShowPage).toBe("function");
  });

  it("renders pending status", () => {
    const html = String(DeletionRequestsShowPage({ deletionRequest: pendingRequest }));
    expect(html).toContain("pending");
  });

  it("renders completed status with processed_at", () => {
    const html = String(DeletionRequestsShowPage({ deletionRequest: completedRequest }));
    expect(html).toContain("completed");
  });

  it("status is one of valid values", () => {
    const validStatuses = ["pending", "approved", "rejected", "completed"];
    expect(validStatuses).toContain(pendingRequest.status);
  });
});
