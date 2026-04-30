/**
 * src/ui/index.ts — UI module re-exports
 * Cycle 6 RED phase.
 */

// Layouts
export { BaseLayout } from "./layouts/base";
export { AdminLayout } from "./layouts/admin";
export { PublicLayout } from "./layouts/public";

// Components
export { Header } from "./components/header";
export { Footer } from "./components/footer";
export { Alert } from "./components/alert";
export { CsrfMeta } from "./components/csrf_meta";

// Admin pages
export { AuditLogsIndexPage } from "./pages/admin/audit_logs/index";
export { QuestionSetsIndexPage } from "./pages/admin/question_sets/index";
export { QuestionSetsShowPage } from "./pages/admin/question_sets/show";
export { QuestionSetsNewPage } from "./pages/admin/question_sets/new";
export { QuestionSetsEditPage } from "./pages/admin/question_sets/edit";
export { AlertsIndexPage } from "./pages/admin/alerts/index";
export { DashboardIndexPage } from "./pages/admin/dashboard/index";

// Public pages
export { SessionsNewPage } from "./pages/public/sessions/new";
export { AccountsNewPage } from "./pages/public/accounts/new";
export { ConsentsNewPage } from "./pages/public/consents/new";
export { DeletionRequestsNewPage } from "./pages/public/deletion_requests/new";
export { DeletionRequestsShowPage } from "./pages/public/deletion_requests/show";
export { AssessmentShowPage } from "./pages/public/assessments/show";
export { AssessmentQuestionShowPage } from "./pages/public/assessment_questions/show";
export {
  ResultsShowPage,
  TypeHero,
  SpectrumPartial,
  InsightCardPartial,
  TrustNotice,
} from "./pages/public/results/show";
