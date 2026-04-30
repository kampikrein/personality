/**
 * test/ui/pages/admin/dashboard/index.test.ts — DashboardIndexPage RED tests
 * Cycle 6 RED phase.
 *
 * GREEN: Renders stat cards: totalAssessments, completionRate (%), dropOffRate (%), activeUsers.
 *   Links to sub-sections: audit_logs, question_sets, alerts.
 */

import { describe, it, expect } from "vitest";
import { DashboardIndexPage } from "../../../../../src/ui/pages/admin/dashboard/index";
import type { DashboardStats } from "../../../../../src/ui/pages/admin/dashboard/index";

const stats: DashboardStats = {
  totalAssessments: 1240,
  completionRate: 78.5,
  dropOffRate: 21.5,
  activeUsers: 342,
};

describe("DashboardIndexPage (RED phase)", () => {
  it("DashboardIndexPage is exported", () => {
    expect(DashboardIndexPage).toBeDefined();
    expect(typeof DashboardIndexPage).toBe("function");
  });

  it("renders dashboard with stats", () => {
    expect(() =>
      DashboardIndexPage({ stats })
    ).toThrow("not implemented: DashboardIndexPage");
  });

  it("stats object has completionRate and dropOffRate", () => {
    expect(stats.completionRate).toBe(78.5);
    expect(stats.dropOffRate).toBe(21.5);
    expect(stats.totalAssessments).toBe(1240);
  });
});
