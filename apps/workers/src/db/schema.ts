/**
 * src/db/schema.ts — Drizzle schema stub (RED phase)
 *
 * GREEN phase에서 14 테이블 Drizzle 정의로 교체한다.
 * 현재는 빈 객체 export — 테스트가 "TABLES is empty" 또는
 * "table X does not exist" 형태로 명확히 fail하도록 한다.
 *
 * GREEN phase 구현 대상:
 *   - users (R4: email_hash, email_enc, encryption_version)
 *   - anonymous_sessions, assessments, question_sets, questions
 *   - responses, domain_scores, profiles, personality_types
 *   - insights, consents, deletion_requests, audit_logs, alerts
 *   총 14 테이블 + R2 UNIQUE 3건 + 9 JSON columns + 14 FK
 */

// RED phase stub — production 코드 없음
export const TABLES: Record<string, unknown> = {};

// GREEN phase에서 이 자리에 Drizzle sqliteTable 정의가 들어온다:
// export const users = sqliteTable("users", { ... });
// export const assessments = sqliteTable("assessments", { ... });
// ...
