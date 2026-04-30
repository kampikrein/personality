/**
 * test/ui/pages/admin/alerts/index.test.ts — AlertsIndexPage RED tests
 * Cycle 6 RED phase.
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

describe("AlertsIndexPage (RED phase)", () => {
  it("AlertsIndexPage is exported", () => {
    expect(AlertsIndexPage).toBeDefined();
    expect(typeof AlertsIndexPage).toBe("function");
  });

  it("renders active alerts", () => {
    expect(() =>
      AlertsIndexPage({ alerts })
    ).toThrow("not implemented: AlertsIndexPage");
  });

  it("renders empty state", () => {
    expect(() =>
      AlertsIndexPage({ alerts: [] })
    ).toThrow("not implemented: AlertsIndexPage");
  });

  it("alerts have severity field", () => {
    expect(alerts[0].severity).toBe("high");
    expect(alerts[0].active).toBe(true);
  });
});
