/**
 * test/ui/pages/public/deletion_requests/new.test.ts — DeletionRequestsNewPage RED tests
 * Cycle 6 RED phase.
 *
 * GREEN: Renders deletion request confirmation form with CSRF + userId embedded.
 *   Warning message about data deletion consequences.
 */

import { describe, it, expect } from "vitest";
import { DeletionRequestsNewPage } from "../../../../../src/ui/pages/public/deletion_requests/new";

describe("DeletionRequestsNewPage (RED phase)", () => {
  it("DeletionRequestsNewPage is exported", () => {
    expect(DeletionRequestsNewPage).toBeDefined();
    expect(typeof DeletionRequestsNewPage).toBe("function");
  });

  it("renders deletion request form", () => {
    expect(() =>
      DeletionRequestsNewPage({ csrfToken: "csrf-del", userId: "user-123" })
    ).toThrow("not implemented: DeletionRequestsNewPage");
  });
});
