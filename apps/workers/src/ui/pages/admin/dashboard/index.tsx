/**
 * src/ui/pages/admin/dashboard/index.tsx — Admin dashboard stub
 * Cycle 6 RED phase.
 */

export interface DashboardStats {
  totalAssessments: number;
  completionRate: number;
  dropOffRate: number;
  activeUsers: number;
}

export interface DashboardIndexProps {
  stats: DashboardStats;
}

// RED stub — not implemented
export function DashboardIndexPage(_props: DashboardIndexProps): unknown {
  throw new Error("not implemented: DashboardIndexPage");
}
