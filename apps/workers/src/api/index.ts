/**
 * src/api/index.ts — API module re-exports
 * Cycle 5 stub — RED phase.
 *
 * GREEN phase: wire all routers into Hono app instance + export AppType.
 */

export * from "./envelope";
export * from "./error_codes";
export * from "./routes/public/assessments";
export * from "./routes/public/sessions";
export * from "./routes/public/accounts";
export * from "./routes/public/assessment_questions";
export * from "./routes/public/results";
export * from "./routes/public/consents";
export * from "./routes/public/deletion_requests";
export * from "./routes/public/health";
export * from "./routes/admin/audit_logs";
export * from "./routes/admin/question_sets";
export * from "./routes/admin/alerts";
export * from "./routes/admin/dashboard";
export * from "./openapi/index";
