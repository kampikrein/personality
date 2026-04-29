---
id: "034"
type: plan
title: "Cycle 2 DB Layer GREEN Plan"
created: 2026-04-29
traces_brief: "021"
traces_scope: "026"
traces_red: "033"
traces_research: ["008", "011"]
traces_synthesis: "018"
cycle: 2
phase_scope: "phase-1-conversion"
status: completed
confidence: high
summary: >
  Cycle 2 DB Layer GREEN phase 구현 계획. 14 tables Drizzle schema + 9 JSON 컬럼 매핑 + 14 FK
  + UNIQUE 3건 + R4 분리 컬럼 + seed 16 row 작성. 0 fail / 112 pass 목표.
keywords: [plan, drizzle, d1, schema, green, cycle2]
---

# Cycle 2 DB Layer GREEN Plan

## Goal

GREEN phase의 가시적 결과: `npm test` 실행 시 **0 fail / 112 pass**.

현재 상태: 104 failed / 8 passed (모든 fail 원인 = `D1_ERROR: no such table: X` — schema/migration 미적용).

구현 완료 기준:
- `apps/workers/src/db/schema.ts` — 14 tables, 9 JSON columns, 14 FK, UNIQUE 3건, R4 분리 컬럼
- `apps/workers/migrations/0000_*.sql` — drizzle-kit generate 산출
- `apps/workers/src/db/seed.ts` — PersonalityType × 16 rows
- `apps/workers/src/db/index.ts` — Drizzle client 생성 함수
- `apps/workers/src/db/types.ts` — JSON 컬럼 $type<T>() 타입 정의
- `test/setup.ts` — migration auto-apply 활성화
- `npm test` 0 fail / 112 pass 확인

## Scope

### Included

- `apps/workers/src/db/schema.ts` — 14 tables Drizzle 정의 (R4 분리 컬럼 + 9 JSON + 14 FK + UNIQUE 3건)
- `apps/workers/src/db/index.ts` — Drizzle client `createDb(d1: D1Database)` 함수
- `apps/workers/src/db/seed.ts` — PersonalityType × 16 + QuestionSet/Questions fixture
- `apps/workers/src/db/types.ts` — 9 JSON 컬럼 타입 정의
- `apps/workers/migrations/0000_*.sql` — drizzle-kit generate 산출 (in-memory D1 local 적용)
- `apps/workers/test/setup.ts` — GREEN phase migration auto-apply hook
- `apps/workers/package.json` — vitest 3.0.x pin 검토

### Excluded

- BetterAuth user/session/account 테이블 — Cycle 4에서 별도 migration 0001로 추가
- saga 패턴 (scoring 8단계 Pure Saga) — Cycle 3
- 실 D1 production 배포 — Phase 2 cutover
- wrangler.toml D1 binding 활성화 — Cycle 1에서 이미 placeholder 설정됨, 본 cycle은 local 검증만
- QuestionSet/Questions seed — schema 검증 대상이지만 PersonalityType만 seed.test.ts가 요구

## Structural Decisions

| # | Decision | 채택 | 근거 |
|---|----------|------|------|
| 1 | SOT 모델 | Drizzle = schema source, Wrangler = migration runner | R1-F1. drizzle-kit migrate D1 함께 사용 금지(이중 추적). |
| 2 | User schema | R4 분리 컬럼 (`email_hash` + `email_enc` + `encryption_version`) | Brief 021 Decision 3, Synthesis S-018-F1. email_enc 내에 R1 envelope JSON 보존 (Rails wire-format 호환). |
| 3 | JSON columns 9개 | `text({ mode: 'json' }).$type<T>()` | R1-F2. blob mode 금지 (D1 JSON1 함수 BLOB 거부). |
| 4 | UNIQUE 3건 | schema 차원에서 `uniqueIndex()` 강제 | Brief 021 Model Anchors 5, Synthesis S-018-F3. saga UPSERT 전제 조건. |
| 5 | FK 14건 | `ON DELETE CASCADE` | Rails `dependent: :destroy` 1:1 매핑. |
| 6 | Migration 폴더 | `apps/workers/migrations/` | drizzle.config.ts `out: "./migrations"`와 정렬. |
| 7 | vitest 호환 | 루트 3.2.4가 실행됨 (경고 있지만 동작) | RED 보고서 메모. workers 로컬 pin은 optional — 기존 동작 확인 후 결정. |
| 8 | test/setup.ts | `globalSetup` 파일로 분리하거나 각 테스트 파일 `beforeAll` 직접 선언 | Workers 런타임 내 setup 파일에서 `node:fs` 접근 불가 — GREEN 구현 시 해결 방향 확인. |
| 9 | Timestamp 컬럼 | `text("created_at").notNull().default(sql\`CURRENT_TIMESTAMP\`)` | D1은 DATETIME 미지원, text 일관 사용. |
| 10 | JSON default | `text(...).notNull().default(sql\`'[]'\`)` or `sql\`'{}'\`` | D1 SQLite의 TEXT default literal이 JSON 배열/객체로 취급되지 않으므로 SQL literal로 전달. |

## File Change Summary

### New Files

| # | Path | 설명 |
|---|------|------|
| 1 | `apps/workers/src/db/schema.ts` | 14 tables Drizzle 정의 (R4 분리 컬럼 + 9 JSON + 14 FK + UNIQUE 3건) |
| 2 | `apps/workers/src/db/index.ts` | `createDb(d1: D1Database): DrizzleD1Database<typeof schema>` |
| 3 | `apps/workers/src/db/seed.ts` | PersonalityType × 16 + seeds.rb 1:1 매핑 |
| 4 | `apps/workers/src/db/types.ts` | 9 JSON 컬럼 타입 + ScoreVector / SuggestedAction / AuditMetadata 등 |
| 5 | `apps/workers/migrations/0000_*.sql` | drizzle-kit generate 산출 (명령 실행 시 생성, plan에서 내용 미작성) |

### Modified Files

| # | Path | 변경 내용 |
|---|------|---------|
| 1 | `apps/workers/src/db/schema.ts` | RED phase stub (`export const TABLES = {}`) → 14 tables 완전 정의 |
| 2 | `apps/workers/test/setup.ts` | no-op stub → migration SQL auto-apply + seed hook |
| 3 | `apps/workers/package.json` | vitest pin 검토 (현재 3.2.4 루트가 실행 중 — 동작 확인 후 필요 시 수정) |

### Reviewed Files (Read-only)

| Path | 목적 |
|------|------|
| `server/db/schema.rb` | Rails 14 tables 1:1 매핑 기준 |
| `server/db/seeds.rb` | PersonalityType 16 rows 원본 |
| `server/app/models/*.rb` | validates / has_many / belongs_to / scope 확인 |
| `apps/workers/test/db/*.test.ts` | 각 step 완료 판단 근거 |

## User Inputs Required

없음. 외부 자원 미접촉, `npm install` + `wrangler d1 migrations apply --local`만 사용.

---

## Step 1 — Rails schema.rb 정밀 매핑

### Approach

`server/db/schema.rb` 전체 + 각 모델의 validates/association을 기준으로 14 tables의 컬럼·타입·제약을 정리한다. (본 plan 작성 시 이미 Read 완료 — 아래 § Cross-Reference Table에 매핑 표 수록.)

### Commands

```bash
# 참조 전용 (read-only)
cat server/db/schema.rb
cat server/app/models/user.rb
cat server/app/models/assessment.rb
# ... 전체 모델
```

### After Code

해당 없음 (read-only step).

### 검증

Cross-Reference Table(아래 § Cross-Reference Table)이 14 rows 완성되고, 각 row의 컬럼 list, 제약, FK 방향이 schema.rb + 모델 validates와 일치.

### Impact Analysis

- Imports/types: 없음
- Tests: schema.test.ts 20 테스트가 정확한 컬럼명 기대 — 매핑 표가 테스트 기준
- Config: 없음
- Cascade: Step 2 schema.ts 작성의 직접 입력

---

## Step 2 — Drizzle schema.ts 14 tables 작성 가이드

### Approach

`apps/workers/src/db/schema.ts`를 14 tables 완전 정의로 교체한다. 아래 각 테이블별 정의 발췌가 구현 시 복사 기준. 전체 구조:

1. 의존성 없는 테이블: `users`, `personality_types`, `question_sets`, `alerts`, `audit_logs`
2. 1-hop 의존: `anonymous_sessions`(users FK), `questions`(question_sets FK)
3. 2-hop 의존: `assessments`(anonymous_sessions + question_sets FK), `consents`(anonymous_sessions + users FK), `deletion_requests`(anonymous_sessions FK)
4. 3-hop 의존: `domain_scores`(assessments FK), `profiles`(anonymous_sessions + assessments + personality_types FK)
5. 4-hop 의존: `insights`(profiles FK), `responses`(assessments + questions FK)

forward reference가 필요한 경우 arrow function `() => table.column` 사용.

### Commands

```bash
# 파일 작성
# apps/workers/src/db/schema.ts 전체 교체
```

### After Code (핵심 발췌)

```typescript
import { sqliteTable, text, integer, real, uniqueIndex, index } from "drizzle-orm/sqlite-core";
import { sql } from "drizzle-orm";

// ============================================================
// Leaf tables (no FK)
// ============================================================

export const users = sqliteTable("users", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  // R4 분리 컬럼 (Brief 021 Decision 3 + Synthesis S-018-F1)
  emailHash: text("email_hash").notNull().unique(),       // SHA-256(plain) — 검색용
  emailEnc: text("email_enc").notNull(),                  // R1 envelope JSON { p, h:{iv, at} }
  encryptionVersion: integer("encryption_version").notNull().default(1),
  displayName: text("display_name"),
  passwordDigest: text("password_digest"),
  deletedAt: text("deleted_at"),
  createdAt: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updatedAt: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
});

export const personalityTypes = sqliteTable("personality_types", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  code: text("code").notNull().unique(),
  characterNameKo: text("character_name_ko").notNull(),
  characterNameEn: text("character_name_en").notNull(),
  summaryKo: text("summary_ko"),
  summaryEn: text("summary_en"),
  // JSON columns × 2
  strengths: text("strengths", { mode: "json" })
    .$type<string[]>().notNull().default(sql`'[]'`),
  cautionPatterns: text("caution_patterns", { mode: "json" })
    .$type<string[]>().notNull().default(sql`'[]'`),
  collaborationStyle: text("collaboration_style"),
  conflictStyle: text("conflict_style"),
  learningStyle: text("learning_style"),
  careerHints: text("career_hints"),
  recoveryStyle: text("recovery_style"),
  createdAt: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updatedAt: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
});

export const questionSets = sqliteTable("question_sets", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  versionCode: text("version_code").unique(),
  status: text("status"),
  createdAt: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updatedAt: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
});

export const alerts = sqliteTable("alerts", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  alertType: text("alert_type").notNull(),
  severity: text("severity").notNull().default("medium"),
  status: text("status").notNull().default("open"),
  message: text("message"),
  notes: text("notes"),
  // JSON column × 1
  metadata: text("metadata", { mode: "json" })
    .$type<Record<string, unknown>>().notNull().default(sql`'{}'`),
  resolvedAt: text("resolved_at"),
  createdAt: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updatedAt: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
});

export const auditLogs = sqliteTable("audit_logs", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  action: text("action").notNull(),
  actorId: integer("actor_id"),
  actorType: text("actor_type"),
  resourceId: integer("resource_id"),
  resourceType: text("resource_type"),
  // JSON column × 1
  metadata: text("metadata", { mode: "json" })
    .$type<Record<string, unknown>>().notNull().default(sql`'{}'`),
  createdAt: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updatedAt: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
});

// ============================================================
// 1-hop dependencies
// ============================================================

export const anonymousSessions = sqliteTable("anonymous_sessions", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  userId: integer("user_id").references(() => users.id),   // optional FK
  sessionToken: text("session_token").notNull().unique(),
  ipHash: text("ip_hash"),
  ipFingerprint: text("ip_fingerprint"),
  userAgentHash: text("user_agent_hash"),
  startedAt: text("started_at"),
  createdAt: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updatedAt: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
});

export const questions = sqliteTable("questions", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  questionSetId: integer("question_set_id").notNull().references(() => questionSets.id),
  domain: text("domain").notNull(),
  position: integer("position").notNull(),
  bodyKo: text("body_ko").notNull(),
  bodyEn: text("body_en"),
  polarity: text("polarity").notNull().default("positive"),
  active: integer("active", { mode: "boolean" }).notNull().default(true),
  createdAt: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updatedAt: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
}, (t) => ({
  uniqueQsDomainPosition: uniqueIndex("index_questions_on_question_set_id_and_domain_and_position")
    .on(t.questionSetId, t.domain, t.position),
}));

// ============================================================
// 2-hop dependencies
// ============================================================

export const assessments = sqliteTable("assessments", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  anonymousSessionId: integer("anonymous_session_id").notNull().references(() => anonymousSessions.id),
  questionSetId: integer("question_set_id").notNull().references(() => questionSets.id),
  status: text("status"),
  currentQuestionIndex: integer("current_question_index"),
  completionRate: real("completion_rate"),
  nonResponseRate: real("non_response_rate"),
  extremeResponseRate: real("extreme_response_rate"),
  retryToken: text("retry_token"),
  startedAt: text("started_at"),
  completedAt: text("completed_at"),
  createdAt: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updatedAt: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
});

export const consents = sqliteTable("consents", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  anonymousSessionId: integer("anonymous_session_id").references(() => anonymousSessions.id),
  userId: integer("user_id").references(() => users.id),
  consentType: text("consent_type"),
  consentVersion: text("consent_version"),
  consentTextSnapshot: text("consent_text_snapshot"),
  granted: integer("granted", { mode: "boolean" }),
  grantedAt: text("granted_at"),
  revokedAt: text("revoked_at"),
  createdAt: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updatedAt: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
});

export const deletionRequests = sqliteTable("deletion_requests", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  anonymousSessionId: integer("anonymous_session_id").notNull().references(() => anonymousSessions.id),
  requestToken: text("request_token").notNull().unique(),
  status: text("status").notNull().default("pending"),
  slaDeadline: text("sla_deadline"),
  createdAt: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updatedAt: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
});

// ============================================================
// 3-hop dependencies
// ============================================================

export const domainScores = sqliteTable("domain_scores", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  assessmentId: integer("assessment_id").notNull().references(() => assessments.id),
  domain: text("domain"),
  rawScore: real("raw_score"),
  normalizedScore: real("normalized_score"),
  consistencyIndex: real("consistency_index"),
  reliabilityCoefficient: real("reliability_coefficient"),
  speedFlag: integer("speed_flag", { mode: "boolean" }),
  policyBlocked: integer("policy_blocked", { mode: "boolean" }),
  createdAt: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updatedAt: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
}, (t) => ({
  // UNIQUE 1/3 (Brief 021 Model Anchors 5)
  uniqueAssessmentDomain: uniqueIndex("index_domain_scores_on_assessment_id_and_domain")
    .on(t.assessmentId, t.domain),
}));

export const profiles = sqliteTable("profiles", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  anonymousSessionId: integer("anonymous_session_id").notNull().references(() => anonymousSessions.id),
  assessmentId: integer("assessment_id").notNull().references(() => assessments.id),
  personalityTypeId: integer("personality_type_id").notNull().references(() => personalityTypes.id),
  typeCode: text("type_code").notNull(),
  // JSON columns × 4
  scoreVector: text("score_vector", { mode: "json" })
    .$type<Record<string, number>>().notNull().default(sql`'{}'`),
  strengths: text("strengths", { mode: "json" })
    .$type<string[]>().notNull().default(sql`'[]'`),
  cautionPatterns: text("caution_patterns", { mode: "json" })
    .$type<string[]>().notNull().default(sql`'[]'`),
  suggestedActions: text("suggested_actions", { mode: "json" })
    .$type<unknown[]>().notNull().default(sql`'[]'`),
  policyBlocked: integer("policy_blocked", { mode: "boolean" }).default(false),
  fallbackMessage: text("fallback_message"),
  createdAt: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updatedAt: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
}, (t) => ({
  // UNIQUE 2/3 (Brief 021 Model Anchors 5)
  uniqueAssessmentId: uniqueIndex("index_profiles_on_assessment_id")
    .on(t.assessmentId),
}));

// ============================================================
// 4-hop dependencies
// ============================================================

export const insights = sqliteTable("insights", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  profileId: integer("profile_id").notNull().references(() => profiles.id),
  context: text("context").notNull(),
  explanation: text("explanation"),
  // JSON column × 1
  suggestions: text("suggestions", { mode: "json" })
    .$type<string[]>().notNull().default(sql`'[]'`),
  createdAt: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updatedAt: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
}, (t) => ({
  // UNIQUE 3/3 (Brief 021 Model Anchors 5)
  uniqueProfileContext: uniqueIndex("index_insights_on_profile_id_and_context")
    .on(t.profileId, t.context),
}));

export const responses = sqliteTable("responses", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  assessmentId: integer("assessment_id").notNull().references(() => assessments.id),
  questionId: integer("question_id").notNull().references(() => questions.id),
  value: integer("value"),
  sequenceNumber: integer("sequence_number"),
  responseTimeMs: integer("response_time_ms"),
  createdAt: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updatedAt: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
}, (t) => ({
  uniqueAssessmentQuestion: uniqueIndex("index_responses_on_assessment_id_and_question_id")
    .on(t.assessmentId, t.questionId),
}));
```

**주의사항**:
- `anonymousSessions.userId`: optional FK (Rails `belongs_to :user, optional: true`). `references(() => users.id)` — not null 없음.
- `consents`: `anonymousSessionId` + `userId` 둘 다 optional (Rails validate `has_session_or_user`).
- `questions`: Rails UNIQUE `(question_set_id, domain, position)` → `uniqueIndex` 추가.
- `responses`: Rails UNIQUE `(assessment_id, question_id)` → `uniqueIndex` 추가.
- `PRAGMA foreign_keys = ON`: D1 in-memory에서 default OFF. migration SQL 첫 줄에 추가 또는 `test/setup.ts`에서 `env.DB.exec("PRAGMA foreign_keys = ON")` 호출.

### 검증

`npm run db:generate` 실행 후 `migrations/0000_*.sql`에서 14 CREATE TABLE 문 + UNIQUE INDEX + FK 정의 확인.

### Impact Analysis

- Imports/types: `schema.ts`가 `index.ts`, `seed.ts`, 모든 테스트 파일에서 임포트됨
- Tests: `schema.test.ts` (14 tables + PK + 컬럼 타입), `foreign_keys.test.ts` (FK 14건), `unique_constraints.test.ts` (UNIQUE 3건 + 추가), `user_encryption.test.ts` (email_hash/email_enc/encryption_version)
- Config: drizzle.config.ts `schema: "./src/db/schema.ts"` 경로와 일치
- Cascade: Step 4(generate), Step 6(seed), Step 7(index.ts) 모두 이 파일에 의존

---

## Step 3 — types.ts 9 JSON 컬럼 타입 정의

### Approach

`apps/workers/src/db/types.ts`에 9 JSON 컬럼의 `$type<T>()` 타입을 정의한다. `schema.ts`에서 임포트.

### Commands

```bash
# 파일 신규 생성
# apps/workers/src/db/types.ts
```

### After Code

```typescript
// apps/workers/src/db/types.ts

// 1. alerts.metadata
export type AlertMetadata = Record<string, unknown>;

// 2. audit_logs.metadata
export interface AuditMetadata {
  before?: Record<string, unknown>;
  after?: Record<string, unknown>;
  ip_hash?: string;
  user_agent_hash?: string;
  [key: string]: unknown;
}

// 3. personality_types.strengths
// → string[]  (inline 정의로 충분)

// 4. personality_types.caution_patterns
// → string[]

// 5. insights.suggestions
export type InsightSuggestion = string;  // 현재 seeds.rb 기준 string[]

// 6. profiles.score_vector — domain별 점수 (0–100 float)
export interface ScoreVector {
  energy?: number;
  decision_making?: number;
  relationship?: number;
  recovery?: number;
  [domain: string]: number | undefined;
}

// 7. profiles.strengths
// → string[]

// 8. profiles.caution_patterns
// → string[]

// 9. profiles.suggested_actions
export interface SuggestedAction {
  action: string;
  priority?: "high" | "medium" | "low";
  context?: string;
}
```

schema.ts에서의 임포트 패턴:
```typescript
import type { AlertMetadata, AuditMetadata, ScoreVector, SuggestedAction } from "./types";

// 사용 예
metadata: text("metadata", { mode: "json" }).$type<AlertMetadata>()
scoreVector: text("score_vector", { mode: "json" }).$type<ScoreVector>()
```

### 검증

`npx tsc --noEmit` 타입 오류 0. `json_columns.test.ts`의 각 JSON round-trip 테스트가 해당 타입 구조와 일치.

### Impact Analysis

- Imports/types: `schema.ts`에서 임포트. 런타임 영향 없음 (컴파일 타임 안전성만).
- Tests: `json_columns.test.ts` 11개 테스트 — JSON 객체 insert/select round-trip + `json_extract` 호환
- Config: 없음
- Cascade: schema.ts Step 2에 의존 (순서: types.ts 먼저 작성 → schema.ts에서 임포트)

---

## Step 4 — drizzle-kit generate

### Approach

`schema.ts` 완성 후 `drizzle-kit generate`를 실행하여 `migrations/0000_*.sql`을 생성한다. 생성된 SQL을 검토하여 14 CREATE TABLE + UNIQUE INDEX + FK + PRAGMA 설정이 포함됐는지 확인.

### Commands

```bash
cd apps/workers
npm run db:generate
# → migrations/0000_<name>.sql 생성

# 생성된 SQL 확인
cat migrations/0000_*.sql
```

### After Code (생성 결과 검토 포인트)

생성된 SQL에서 확인할 항목:

```sql
-- 1. PRAGMA foreign_keys
PRAGMA foreign_keys=OFF;  -- drizzle-kit 기본. migration 완료 후 ON으로 전환 필요

-- 2. 14 CREATE TABLE IF NOT EXISTS 구문 존재 확인
CREATE TABLE `users` (
  `id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
  `email_hash` text NOT NULL,
  `email_enc` text NOT NULL,
  `encryption_version` integer DEFAULT 1 NOT NULL,
  ...
);

-- 3. UNIQUE INDEX 3건 이상 확인
CREATE UNIQUE INDEX `index_domain_scores_on_assessment_id_and_domain` ON `domain_scores` (`assessment_id`,`domain`);
CREATE UNIQUE INDEX `index_profiles_on_assessment_id` ON `profiles` (`assessment_id`);
CREATE UNIQUE INDEX `index_insights_on_profile_id_and_context` ON `insights` (`profile_id`,`context`);

-- 4. FK 참조 확인 (D1은 FK DDL은 지원하지만 ON DELETE CASCADE 지원 수준 확인)
```

**주의**: drizzle-kit는 SQLite의 FK를 `REFERENCES` 키워드로 인라인 정의. 별도 `ADD FOREIGN KEY` 없음.

**PRAGMA foreign_keys = ON 삽입**: migration SQL 첫 줄 또는 test/setup.ts에서 `env.DB.exec("PRAGMA foreign_keys = ON")` 명시적 호출. `foreign_keys.test.ts`의 FK 무결성 테스트가 통과하려면 이 설정이 필수.

### 검증

- `migrations/0000_*.sql` 파일 존재
- `grep -c "CREATE TABLE" migrations/0000_*.sql` = 14
- `grep "UNIQUE INDEX" migrations/0000_*.sql | wc -l` >= 5 (3 Model Anchors + questions + responses 추가 UNIQUE)

### Impact Analysis

- Imports/types: 없음
- Tests: `migrations.test.ts` (d1_migrations 테이블 row 1개), `schema.test.ts` (sqlite_master에서 14 tables)
- Config: `drizzle.config.ts`의 `out: "./migrations"` 경로와 일치
- Cascade: Step 5 (wrangler apply) + test/setup.ts (SQL 파일 읽기)의 입력

---

## Step 5 — wrangler d1 migrations apply --local

### Approach

생성된 migration SQL을 local D1에 적용한다. `test/setup.ts`가 vitest 시작 시 이 SQL을 자동으로 D1에 적용하도록 설정한다.

Workers 런타임 setup 파일에서 `node:fs` 접근 불가 제약 해결 방법:

**방법 A (권장)**: vitest.config.ts의 `globalSetup` 파일 사용 — Node.js 환경에서 실행되어 파일 시스템 접근 가능. 단, globalSetup에서는 Workers binding(`env.DB`) 접근 불가.

**방법 B (테스트 파일 내 beforeAll)**: 각 테스트 파일에서 `env.DB.exec(migrationSql)` 직접 호출. 코드 중복이 있지만 Workers 런타임 내 동작.

**방법 C (wrangler migrations apply --local + env.DB 공유)**: wrangler가 `.wrangler/state/v3/d1/`에 상태를 저장. vitest-pool-workers가 이 상태를 재사용. 별도 hook 없이도 테스트 시작 전 apply 완료 상태면 동작.

**권장 방법**: 방법 C + 방법 B 조합.
1. `npm run db:migrate:local`로 로컬 D1에 migration 적용
2. `test/setup.ts`에서 `beforeAll`에 `env.DB.exec(migrationSQL)` + PRAGMA 설정 추가 (in-memory D1은 매 테스트 실행 시 초기화되므로 항상 적용 필요)

### Commands

```bash
cd apps/workers

# 로컬 D1에 migration 적용 (상태 저장)
npm run db:migrate:local
# = wrangler d1 migrations apply personality-d1-prod --local

# 적용 확인
wrangler d1 migrations list personality-d1-prod --local
```

### After Code (test/setup.ts — GREEN phase 활성화)

```typescript
// apps/workers/test/setup.ts
import { env } from "cloudflare:test";
import { readFileSync, readdirSync } from "node:fs";
import { join } from "node:path";

// Workers 런타임 내 setup 파일 — node:fs 사용 제약 있음
// vitest-pool-workers 0.7.x의 setupFiles는 Workers 런타임에서 실행됨
// node:fs가 필요하면 globalSetup으로 분리 필요

// 대안: SQL 인라인 임포트 (Vite의 ?raw 쿼리 사용)
// import migrationSQL from "../migrations/0000_initial_schema.sql?raw";

beforeAll(async () => {
  // PRAGMA foreign_keys ON (D1 default OFF)
  await env.DB.exec("PRAGMA foreign_keys = ON");
  
  // Migration SQL 적용
  // 방법: 파일을 ?raw로 임포트하거나, 내용을 직접 포함
  // vitest-pool-workers에서 동적 fs 읽기가 불가한 경우 아래 패턴 사용:
  // import migrationSQL from "../migrations/0000_initial_schema.sql?raw";
  // await env.DB.exec(migrationSQL);
  
  // seed 실행 (seed.test.ts에서 필요한 경우)
  // import { seed } from "../src/db/seed";
  // await seed(env.DB);
});
```

**주의**: `vitest.config.ts`의 `setupFiles`는 Workers 런타임에서 실행. `node:fs` 직접 사용 시 오류 가능. Vite의 `?raw` import 또는 `globalSetup`(Node.js 환경) 두 경로 중 실제 동작 방법으로 구현.

### 검증

```bash
# migration 적용 후 확인
wrangler d1 migrations list personality-d1-prod --local
# → 1 row 출력

# 테이블 수 확인
wrangler d1 execute personality-d1-prod --local \
  --command "SELECT count(*) as cnt FROM sqlite_master WHERE type='table' AND name NOT LIKE 'd1_%'"
# → cnt = 14
```

### Impact Analysis

- Imports/types: test/setup.ts에서 migration SQL 임포트 방식 결정 필요
- Tests: 모든 DB 테스트가 이 step 완료를 전제 (특히 schema.test.ts의 sqlite_master 쿼리)
- Config: wrangler.toml의 `database_name`, `migrations_dir` 설정과 일치해야 함
- Cascade: Step 6(seed), Step 9(통합 검증) 모두 migration 적용 상태 전제

---

## Step 6 — seed.ts 작성

### Approach

`server/db/seeds.rb`의 PersonalityType 16종을 TypeScript로 이식한다. `INSERT ... ON CONFLICT(code) DO NOTHING` 패턴으로 멱등 실행.

### Commands

```bash
# 신규 파일 생성
# apps/workers/src/db/seed.ts
```

### After Code

```typescript
// apps/workers/src/db/seed.ts
import { drizzle } from "drizzle-orm/d1";
import { personalityTypes } from "./schema";
import * as schema from "./schema";

const PERSONALITY_TYPES_DATA = [
  {
    code: "ENFP",
    characterNameKo: "빛나는 탐험가",
    characterNameEn: "Radiant Explorer",
    summaryKo: "끝없는 호기심과 따뜻한 에너지로 새로운 가능성을 발견하는 사람...",
    summaryEn: "Someone who discovers new possibilities with endless curiosity...",
    strengths: ["공감 능력이 뛰어남", "창의적 문제 해결", "팀 분위기 활성화", "빠른 적응력"],
    cautionPatterns: ["여러 프로젝트 동시 진행 시 완성도 저하 가능", "감정에 휘둘릴 수 있음"],
    collaborationStyle: "자유로운 브레인스토밍을 좋아하고...",
    conflictStyle: "갈등 상황에서 조율하는 역할을...",
    learningStyle: "실험과 토론을 통해 가장 잘 배웁니다...",
    careerHints: "창의성과 사람과의 연결이 모두 필요한 역할에서...",
    recoveryStyle: "새로운 경험과 사람들과의 교류에서...",
  },
  // ... 나머지 15개 (seeds.rb 1:1 매핑)
] as const;

export async function seed(d1: D1Database): Promise<void> {
  const db = drizzle(d1, { schema });
  
  for (const pt of PERSONALITY_TYPES_DATA) {
    await db.insert(personalityTypes)
      .values(pt)
      .onConflictDoNothing({ target: personalityTypes.code });
  }
}

// 실행 시: await seed(env.DB)
```

**구현 시 주의사항**:
- `PERSONALITY_TYPES_DATA` 배열은 seeds.rb의 16개 항목을 전부 포함해야 함 (ENFP, ENFJ, ENTP, ENTJ, ESFP, ESFJ, ESTP, ESTJ, INFP, INFJ, INTP, INTJ, ISFP, ISFJ, ISTP, ISTJ).
- `seed.test.ts`가 요구하는 character_name 매핑이 seeds.rb와 정확히 일치해야 함.
- `onConflictDoNothing`은 Drizzle의 `INSERT OR IGNORE` 동등 패턴 — 멱등성 보장.

### 검증

```bash
# seed 실행 후 count 확인
wrangler d1 execute personality-d1-prod --local \
  --command "SELECT count(*) as cnt FROM personality_types"
# → cnt = 16
```

`seed.test.ts` 9개 테스트:
- should have exactly 16 rows in personality_types after seed
- should contain all 16 MBTI codes
- JSON 배열 채워짐 확인

### Impact Analysis

- Imports/types: `schema.ts`에서 `personalityTypes` 임포트. `types.ts` 필요 없음.
- Tests: `seed.test.ts` 9개, `schema.test.ts` 일부(personality_types 존재)
- Config: 없음
- Cascade: test/setup.ts에서 seed 함수 호출. seed.test.ts에서 직접 호출.

---

## Step 7 — db/index.ts 작성

### Approach

Drizzle client 생성 함수를 `apps/workers/src/db/index.ts`에 작성한다. D1 binding을 주입받아 type-safe DrizzleD1Database를 반환.

### Commands

```bash
# 신규 파일 생성
# apps/workers/src/db/index.ts
```

### After Code

```typescript
// apps/workers/src/db/index.ts
import { drizzle } from "drizzle-orm/d1";
import * as schema from "./schema";

export function createDb(d1: D1Database) {
  return drizzle(d1, { schema });
}

export type Db = ReturnType<typeof createDb>;

// 편의 export (테스트 및 서비스에서 직접 임포트)
export * from "./schema";
export * from "./types";
```

사용 예 (Hono route handler):
```typescript
import { createDb } from "../db";

app.get("/api/personality-types", async (c) => {
  const db = createDb(c.env.DB);
  const types = await db.select().from(personalityTypes);
  return c.json({ success: true, data: types });
});
```

### 검증

`npx tsc --noEmit` 타입 오류 0.

테스트에서의 사용:
```typescript
import { createDb } from "../../src/db";
import { env } from "cloudflare:test";

const db = createDb(env.DB);
const result = await db.select().from(personalityTypes);
```

### Impact Analysis

- Imports/types: 서비스 레이어(Cycle 3), API routes(Cycle 5)가 이 함수를 임포트
- Tests: 테스트 파일이 `createDb(env.DB)` 패턴 사용 가능 (현재는 drizzle 직접 호출도 허용)
- Config: 없음
- Cascade: Cycle 3(services), Cycle 5(API routes)의 DB 접근 기반

---

## Step 8 — vitest 호환성 pin

### Approach

현재 RED phase 결과: 루트 vitest 3.2.4가 실행되고 있으며 테스트는 정상 동작(경고만 발생). GREEN phase에서도 동일하게 동작하면 변경 불필요.

- `@cloudflare/vitest-pool-workers` 0.7.8의 공식 지원 범위: vitest 2.0.x - 3.0.x
- 루트 3.2.4가 경고 발생하지만 동작 중 → GREEN에서 fail이 발생하면 workers 로컬 pin 적용

### Commands (조건부)

```bash
# 현재 버전 확인
cd apps/workers && npm list vitest

# GREEN 테스트 완료 후 fail 없으면 변경 없음
# fail이 발생하고 vitest 버전이 원인이면 아래 적용:
# apps/workers/package.json에 vitest 3.0.5 로컬 pin 추가
```

### After Code (필요 시만 적용)

```json
// apps/workers/package.json — 필요 시 추가
{
  "devDependencies": {
    "vitest": "3.0.5"
  }
}
```

루트 패키지와 격리하려면 workers의 `package.json`에 로컬 버전을 명시하면 workspace 우선 적용.

### 검증

`npm test` 실행 시 vitest 버전 관련 경고가 test fail을 유발하지 않으면 OK.

### Impact Analysis

- Imports/types: 없음
- Tests: 전체 테스트 스위트
- Config: 루트 package.json과 workers package.json의 버전 충돌 주의
- Cascade: 없음

---

## Step 9 — 통합 검증

### Approach

모든 파일 작성 완료 후 `npm test`를 실행하여 0 fail / 112 pass를 확인한다. Migration 멱등 dry-run도 함께 수행.

### Commands

```bash
cd apps/workers

# 1. 타입 체크
npx tsc --noEmit

# 2. drizzle-kit generate (최신 schema 반영)
npm run db:generate

# 3. 로컬 migration 적용
npm run db:migrate:local

# 4. 전체 테스트 실행
npm test
# 목표: 0 failed / 112 passed

# 5. Migration 멱등성 확인 (재실행 시 오류 없음)
npm run db:migrate:local
# → "No pending migrations" 메시지

# 6. D1 상태 확인
wrangler d1 migrations list personality-d1-prod --local
# → 1 row

# 7. PersonalityType count 확인
wrangler d1 execute personality-d1-prod --local \
  --command "SELECT count(*) as cnt FROM personality_types"
# → cnt = 16 (seed 실행 후)

# 8. PRAGMA foreign_key_list 확인 (FK 14건)
wrangler d1 execute personality-d1-prod --local \
  --command "SELECT count(*) FROM pragma_foreign_key_list('assessments')"
```

### After Code

해당 없음 (검증 전용 step).

### 검증 기준

| 항목 | 기대 결과 |
|------|---------|
| `npm test` | 0 failed / 112 passed |
| `wrangler d1 migrations list --local` | 1 row |
| `SELECT count(*) FROM sqlite_master WHERE type='table'` | 14+ (d1_migrations 제외 시 14) |
| `SELECT count(*) FROM personality_types` | 16 |
| Migration 재실행 | 오류 없음 (멱등) |

### Impact Analysis

- Imports/types: 없음
- Tests: 전체 스위트 — 0 fail이 cycle 2 complete 판단 기준
- Config: 없음
- Cascade: Cycle 3(services) 진입 gate

---

## Cross-Reference Table

Rails 14 tables ↔ Drizzle schema.ts 매핑. schema.rb 기준.

| # | Rails 테이블 | Drizzle export 명 | 컬럼 수 | JSON 컬럼 | FK 수 | UNIQUE 제약 | 검증 테스트 |
|---|------------|-----------------|--------|---------|-------|------------|-----------|
| 1 | `alerts` | `alerts` | 10 | metadata | 0 | - | schema.test.ts, json_columns.test.ts |
| 2 | `anonymous_sessions` | `anonymousSessions` | 9 | - | 1 (users, optional) | session_token | schema.test.ts, foreign_keys.test.ts, unique_constraints.test.ts |
| 3 | `assessments` | `assessments` | 12 | - | 2 (anon_sess, qs) | - | schema.test.ts, foreign_keys.test.ts |
| 4 | `audit_logs` | `auditLogs` | 8 | metadata | 0 | - | schema.test.ts, json_columns.test.ts |
| 5 | `consents` | `consents` | 10 | - | 2 (anon_sess optional, users optional) | - | schema.test.ts, foreign_keys.test.ts |
| 6 | `deletion_requests` | `deletionRequests` | 7 | - | 1 (anon_sess) | request_token | schema.test.ts, foreign_keys.test.ts, unique_constraints.test.ts |
| 7 | `domain_scores` | `domainScores` | 10 | - | 1 (assessments) | **(assessment_id, domain)** Model Anchor 5 | schema.test.ts, foreign_keys.test.ts, unique_constraints.test.ts |
| 8 | `insights` | `insights` | 6 | suggestions | 1 (profiles) | **(profile_id, context)** Model Anchor 5 | schema.test.ts, foreign_keys.test.ts, json_columns.test.ts, unique_constraints.test.ts |
| 9 | `personality_types` | `personalityTypes` | 14 | strengths, caution_patterns | 0 | code | schema.test.ts, json_columns.test.ts, seed.test.ts |
| 10 | `profiles` | `profiles` | 14 | score_vector, strengths, caution_patterns, suggested_actions | 3 (anon_sess, assessments, personality_types) | **(assessment_id)** Model Anchor 5 | schema.test.ts, foreign_keys.test.ts, json_columns.test.ts, unique_constraints.test.ts |
| 11 | `question_sets` | `questionSets` | 5 | - | 0 | version_code | schema.test.ts, unique_constraints.test.ts |
| 12 | `questions` | `questions` | 9 | - | 1 (question_sets) | (qs_id, domain, position) | schema.test.ts, foreign_keys.test.ts, unique_constraints.test.ts |
| 13 | `responses` | `responses` | 7 | - | 2 (assessments, questions) | (assessment_id, question_id) | schema.test.ts, foreign_keys.test.ts, unique_constraints.test.ts |
| 14 | `users` | `users` | 9 | - (R4 분리 컬럼) | 0 | **email_hash** | schema.test.ts, user_encryption.test.ts |

### Rails FK 14건 → Drizzle 매핑

| Rails add_foreign_key | Drizzle `.references()` 위치 | ON DELETE |
|----------------------|---------------------------|-----------|
| `anonymous_sessions` → `users` | `anonymousSessions.userId` | (Rails nullify → nullable FK) |
| `assessments` → `anonymous_sessions` | `assessments.anonymousSessionId` | CASCADE |
| `assessments` → `question_sets` | `assessments.questionSetId` | CASCADE |
| `consents` → `anonymous_sessions` | `consents.anonymousSessionId` | CASCADE |
| `consents` → `users` | `consents.userId` | CASCADE |
| `deletion_requests` → `anonymous_sessions` | `deletionRequests.anonymousSessionId` | CASCADE |
| `domain_scores` → `assessments` | `domainScores.assessmentId` | CASCADE |
| `insights` → `profiles` | `insights.profileId` | CASCADE |
| `profiles` → `anonymous_sessions` | `profiles.anonymousSessionId` | CASCADE |
| `profiles` → `assessments` | `profiles.assessmentId` | CASCADE |
| `profiles` → `personality_types` | `profiles.personalityTypeId` | CASCADE |
| `questions` → `question_sets` | `questions.questionSetId` | CASCADE |
| `responses` → `assessments` | `responses.assessmentId` | CASCADE |
| `responses` → `questions` | `responses.questionId` | CASCADE |

### Rails schema.rb 컬럼 → Drizzle 타입 매핑

| Rails 타입 | Drizzle 정의 |
|----------|------------|
| `t.string` | `text("col")` |
| `t.text` | `text("col")` |
| `t.integer` | `integer("col")` |
| `t.bigint` | `integer("col")` (SQLite는 bigint 없음) |
| `t.float` | `real("col")` |
| `t.boolean` | `integer("col", { mode: "boolean" })` |
| `t.datetime` | `text("col")` (D1 DATETIME 미지원) |
| `t.json` | `text("col", { mode: "json" }).$type<T>()` |

### 주요 컬럼별 R4 매핑

| Rails `users` 컬럼 | Drizzle 컬럼 | 설명 |
|----------------|------------|------|
| `email` (encrypted deterministic) | `email_hash` TEXT UNIQUE + `email_enc` TEXT | R4 분리 패턴. email_hash = SHA-256(plain), email_enc = R1 envelope JSON |
| `display_name` (encrypted) | `display_name` TEXT | non-deterministic, 단순 ciphertext 저장 가능 (Cycle 4에서 encryption hook 추가) |
| `password_digest` | `password_digest` TEXT | BetterAuth가 Cycle 4에서 관리 |
| (없음) | `encryption_version` INTEGER DEFAULT 1 | R4 추가 컬럼. parallel-key rotation 진행률 추적 |

---

## Verification Plan

| 검증 항목 | 명령 / 방법 | 기대 결과 |
|---------|-----------|---------|
| 전체 테스트 | `npm test` | 0 failed / 112 passed |
| Migration 적용 상태 | `wrangler d1 migrations list personality-d1-prod --local` | 1 row |
| 테이블 수 | `SELECT count(*) FROM sqlite_master WHERE type='table' AND name NOT LIKE 'd1_%'` | 14 |
| FK pragma | `PRAGMA foreign_key_list('assessments')` | 2 rows (anonymous_session_id, question_set_id) |
| PRAGMA foreign_keys | `PRAGMA foreign_keys` | 1 (ON) |
| PersonalityType seed | `SELECT count(*) FROM personality_types` | 16 |
| UNIQUE constraints | `SELECT count(*) FROM sqlite_master WHERE type='index' AND sql LIKE '%UNIQUE%'` | 5+ |
| Migration 멱등 | `npm run db:migrate:local` 재실행 | 오류 없음 |
| 타입 체크 | `npx tsc --noEmit` | 오류 없음 |

---

## Risks & Mitigations

| 위험 | 가능성 | 완화 방법 |
|------|--------|---------|
| `test/setup.ts`에서 node:fs 접근 불가 (Workers 런타임 제약) | 높음 | Vite의 `?raw` import 사용하거나 각 테스트 파일에 beforeAll 직접 선언. globalSetup 분리 가능하나 env.DB 접근 불가 — ?raw 패턴이 최적. |
| drizzle-kit이 D1 driver를 'd1-http'로 인식 못 할 때 | 낮음 | drizzle.config.ts에서 `dialect: 'sqlite'` + driver 생략 (binding 사용 시 driver 없어도 generate 동작). d1-http는 remote introspect용. |
| BetterAuth 테이블이 Cycle 4에 추가될 때 migration 충돌 | 중간 | Cycle 4 makeplan에서 별도 migration `0001_betterauth.sql`로 처리. 본 plan은 `0000`만 책임. |
| vitest 버전 경고가 실제 fail로 전환 | 낮음 | 루트 3.2.4가 이미 동작 중. 문제 발생 시 workers 로컬 pin 3.0.5 적용 (Step 8). |
| JSON default SQL literal이 D1에서 다르게 처리 | 낮음 | `sql\`'[]'\`` 패턴이 R1-F2에서 검증된 방식. 문제 발생 시 `$default(() => [])` ORM 레벨 기본값으로 fallback. |
| PRAGMA foreign_keys = ON 누락으로 FK 무결성 테스트 fail | 중간 | `test/setup.ts`의 beforeAll에서 `await env.DB.exec("PRAGMA foreign_keys = ON")` 명시 추가. migration SQL 첫 줄에도 삽입. |
| questions / responses UNIQUE 제약 — RED 테스트가 기대하는 인덱스명 불일치 | 낮음 | `unique_constraints.test.ts`를 미리 읽어 기대하는 인덱스명과 Drizzle uniqueIndex 이름이 일치하는지 확인. |

---

## References

| 문서 | 경로 | 관련 항목 |
|------|------|---------|
| RED phase 보고서 | `docs/6_backend/02_cf_workers_rebuild/033_TDDRed_cycle2_db.md` | Test Files, Implementation Hints, Cross-References |
| Brief 021 | `docs/6_backend/02_cf_workers_rebuild/021_Brief_conversion_phase1.md` | Decision 3 (R4 user schema), Model Anchors 5 (UNIQUE 3건) |
| Scope 026 | `docs/6_backend/02_cf_workers_rebuild/026_Scope_conversion_phase1.md` | Cycle 2 DB Layer scope, 의존성 맵 |
| R1 Drizzle+D1 | `docs/6_backend/02_cf_workers_rebuild/008_Research_axis1_drizzle_d1.md` | SOT 모델, JSON 9 컬럼, envelope JSON, rollback |
| R4 Auth schema | `docs/6_backend/02_cf_workers_rebuild/011_Research_axis4_auth_hybrid.md` | email_hash + email_enc + encryption_version, parallel-key rotation |
| Synthesis 018 | `docs/6_backend/02_cf_workers_rebuild/018_Synthesis_research_cycle.md` | S-018-F1 (R4 우위), S-018-F2/F3 (UNIQUE 3건) |
| Rails schema.rb | `server/db/schema.rb` | 14 tables, 14 FK, 컬럼 타입 원본 |
| Rails seeds.rb | `server/db/seeds.rb` | PersonalityType × 16 rows |
| Rails models | `server/app/models/*.rb` | validates, has_many, belongs_to, scope |
| Plan 020 (Cycle 1) | `docs/6_backend/02_cf_workers_rebuild/020_Plan_cycle1_foundation.md` | Step 형식 템플릿 |
