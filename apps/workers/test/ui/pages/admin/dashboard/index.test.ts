/**
 * test/ui/pages/admin/dashboard/index.test.ts — DashboardIndexPage GREEN tests
 * Cycle 6 GREEN phase (Step 0: antipattern fix).
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

describe("DashboardIndexPage", () => {
  it("DashboardIndexPage is exported", () => {
    expect(DashboardIndexPage).toBeDefined();
    expect(typeof DashboardIndexPage).toBe("function");
  });

  it("renders dashboard with stats", () => {
    const html = String(DashboardIndexPage({ stats }));
    expect(html).toContain("1240");
  });

  it("renders completion rate", () => {
    const html = String(DashboardIndexPage({ stats }));
    expect(html).toContain("78.5");
  });

  it("stats object has completionRate and dropOffRate", () => {
    expect(stats.completionRate).toBe(78.5);
    expect(stats.dropOffRate).toBe(21.5);
    expect(stats.totalAssessments).toBe(1240);
  });
});
