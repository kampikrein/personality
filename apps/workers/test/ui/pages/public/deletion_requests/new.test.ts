/**
 * test/ui/pages/public/deletion_requests/new.test.ts — DeletionRequestsNewPage GREEN tests
 * Cycle 6 GREEN phase (Step 0: antipattern fix).
 *
 * GREEN: Renders deletion request confirmation form with CSRF + userId embedded.
 *   Warning message about data deletion consequences.
 */

import { describe, it, expect } from "vitest";
import { DeletionRequestsNewPage } from "../../../../../src/ui/pages/public/deletion_requests/new";

describe("DeletionRequestsNewPage", () => {
  it("DeletionRequestsNewPage is exported", () => {
    expect(DeletionRequestsNewPage).toBeDefined();
    expect(typeof DeletionRequestsNewPage).toBe("function");
  });

  it("renders deletion request form", () => {
    const html = String(DeletionRequestsNewPage({ csrfToken: "csrf-del", userId: "user-123" }));
    expect(html).toContain("csrf-del");
  });

  it("embeds userId in form", () => {
    const html = String(DeletionRequestsNewPage({ csrfToken: "csrf-del", userId: "user-123" }));
    expect(html).toContain("user-123");
  });
});
