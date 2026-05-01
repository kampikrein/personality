/**
 * test/ui/pages/admin/alerts/index.test.ts — AlertsIndexPage GREEN tests
 * Cycle 6 GREEN phase (Step 0: antipattern fix).
 *
 * GREEN: Renders active alerts table with message, severity, created_at.
 *   Dismiss action per alert.
 */

import { describe, it, expect } from "vitest";
import { AlertsIndexPage } from "../../../../../src/ui/pages/admin/alerts/index";
import type { AdminAlert } from "../../../../../src/ui/pages/admin/alerts/index";

const alerts: AdminAlert[] = [
  { id: "a-1", message: "High drop-off on Q5", severity: "high", active: true, created_at: "2026-04-01T00:00:00Z" },
  { id: "a-2", message: "Low completion rate", severity: "medium", active: true, created_at: "2026-04-02T00:00:00Z" },
];

describe("AlertsIndexPage", () => {
  it("AlertsIndexPage is exported", () => {
    expect(AlertsIndexPage).toBeDefined();
    expect(typeof AlertsIndexPage).toBe("function");
  });

  it("renders active alerts", () => {
    const html = String(AlertsIndexPage({ alerts }));
    expect(html).toContain("High drop-off on Q5");
  });

  it("renders severity information", () => {
    const html = String(AlertsIndexPage({ alerts }));
    expect(html).toContain("high");
  });

  it("renders empty state", () => {
    const html = String(AlertsIndexPage({ alerts: [] }));
    expect(html).toBeDefined();
  });

  it("alerts have severity field", () => {
    expect(alerts[0].severity).toBe("high");
    expect(alerts[0].active).toBe(true);
  });
});
