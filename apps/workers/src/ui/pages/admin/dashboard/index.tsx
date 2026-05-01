/**
 * src/ui/pages/admin/dashboard/index.tsx — Admin dashboard page
 * Cycle 6 GREEN phase.
 */

export interface DashboardStats {
  totalAssessments: number;
  completionRate: number;
  dropOffRate: number;
  activeUsers: number;
}

export interface DashboardIndexProps {
  stats: DashboardStats;
  user?: { email: string };
  cspNonce?: string;
}

export function DashboardIndexPage(props: DashboardIndexProps): string {
  const { stats } = props;
  return `<div class="admin-dashboard">
  <h1>Dashboard</h1>
  <div class="stat-cards">
    <div class="stat-card">
      <h2>Total Assessments</h2>
      <p>${stats.totalAssessments}</p>
    </div>
    <div class="stat-card">
      <h2>Completion Rate</h2>
      <p>${stats.completionRate}%</p>
    </div>
    <div class="stat-card">
      <h2>Drop-Off Rate</h2>
      <p>${stats.dropOffRate}%</p>
    </div>
    <div class="stat-card">
      <h2>Active Users</h2>
      <p>${stats.activeUsers}</p>
    </div>
  </div>
  <nav class="admin-links">
    <a href="/admin/audit_logs">Audit Logs</a>
    <a href="/admin/question_sets">Question Sets</a>
    <a href="/admin/alerts">Alerts</a>
  </nav>
</div>`;
}
