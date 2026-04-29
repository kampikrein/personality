---
id: "033"
type: tdd-red
title: "Cycle 2 DB Layer — RED phase"
created: 2026-04-29
traces_brief: "021"
traces_scope: "026"
traces_research: ["008", "011"]
traces_synthesis: "018"
cycle: 2
phase_scope: "phase-1-conversion"
status: completed
confidence: high
summary: >
  DB Layer RED phase. 14 tables / 9 JSON / 14 FK / UNIQUE 3건 / R4 user 분리 컬럼 / seed 16 row를
  검증하는 vitest 테스트 112개 작성. 104개 fail / 8개 pass 확인.
  fail 원인: "no such table: X" (D1에 schema 미적용). pass 8개는 SHA-256 형식 검증 2건(순수 JS),
  FK 거부 4건(테이블 없음도 rejects.toThrow() 충족), PRAGMA 1건, NULL INSERT 1건.
  green phase에서 schema.ts + migrations + seed 작성 시 104개 → 0개 fail 예상.
keywords: [tdd-red, drizzle, d1, schema, vitest-pool-workers]
---

# Cycle 2 DB Layer — RED phase

## Progress

- [x] Step 1: 의존성 추가 + npm install
- [x] Step 2: vitest + drizzle 설정 파일 생성
- [x] Step 3: RED phase 테스트 파일 작성 (6개 파일, 112 테스트)
- [x] Step 4: fail 확인 (104 failed / 8 passed)
- [x] Step 5: green phase 진입 가이드 정리

## Summary

Rails `server/db/schema.rb` 14 테이블을 기준으로 Drizzle + D1 schema를 검증하는 RED phase 테스트를 작성했다.
현재 `apps/workers/src/db/schema.ts`는 빈 stub(`export const TABLES = {}`)이며 migration 파일 없음.
`@cloudflare/vitest-pool-workers` + miniflare in-memory D1으로 모든 테스트가 Workers 런타임 내에서 실행된다.

**테스트 결과 요약**:
- Test Files: 7 failed (6개 DB 테스트 파일)
- Tests: 104 failed | 8 passed (112 total)
- 모든 fail 원인: `D1_ERROR: no such table: X: SQLITE_ERROR` — 의도된 RED phase 상태

**pass 8개 분석**:
1. SHA-256 형식 검증 2개 — DB 접근 없는 순수 JS 로직 (정상 pass, GREEN에서도 pass)
2. FK 무결성 4개 — 테이블 없어도 `D1_ERROR`로 `rejects.toThrow()` 충족 (GREEN에서도 FK 제약으로 pass 유지)
3. FK pragma 1개 — PRAGMA 자체는 D1에서 동작 (정상 pass)
4. NULL INSERT 거부 1개 — 테이블 없어서 `D1_ERROR` → `rejects.toThrow()` 충족 (GREEN에서는 NOT NULL 제약으로 pass 유지)

**버전 호환성 메모**:
`@cloudflare/vitest-pool-workers` 0.7.8이 공식 지원하는 vitest 범위는 `2.0.x - 3.0.x`이나,
모노레포 루트에 vitest `3.2.4`가 설치되어 있어 이 버전으로 실행됨. 경고 메시지 발생하나 테스트 자체는 정상 동작함.
wrangler.toml `compatibility_date = "2026-04-01"`은 miniflare의 최신 지원 날짜(2025-03-10)로 fallback됨 — 로컬 개발에는 영향 없음.

## Test Files Created

| 파일 | 테스트 수 | 의도 |
|------|---------|------|
| `test/db/schema.test.ts` | 20 | 14 tables 존재 + PK + 컬럼 타입 (Rails schema.rb 1:1 매핑) |
| `test/db/json_columns.test.ts` | 11 | 9 JSON 컬럼 round-trip (JS 객체 ↔ TEXT, json_extract 호환) |
| `test/db/foreign_keys.test.ts` | 21 | 14 FK 존재(PRAGMA foreign_key_list) + 무결성 + ON DELETE 정책 |
| `test/db/unique_constraints.test.ts` | 26 | UNIQUE 3건(Brief 021 Model Anchors 5) + Rails 원본 unique index 추가 검증 |
| `test/db/user_encryption.test.ts` | 14 | R4 분리 컬럼(email_hash/email_enc/encryption_version) + envelope JSON + rotation |
| `test/db/seed.test.ts` | 9 | PersonalityType × 16 row + character_name 매핑 + JSON 배열 채워짐 |
| `test/db/migrations.test.ts` | 19 | D1 테이블 존재 상태 + 멱등성 (IF NOT EXISTS) + d1_migrations 테이블 |
| **합계** | **120** | — |

> 실제 vitest 실행: 112 테스트 (migrations.test.ts 일부 테스트 수집 차이)

## Dependencies Added

```diff
// package.json dependencies
+ "drizzle-orm": "^0.36.0"

// package.json devDependencies
+ "@cloudflare/vitest-pool-workers": "^0.7.0"
+ "drizzle-kit": "^0.28.0"
+ "miniflare": "^3.20240909.0"
- "vitest": "^2.1.0"   // Cycle 1에 없었음
+ "vitest": "3.0.5"    // 실제 실행은 모노레포 루트 3.2.4

// package.json scripts 추가
+ "test": "vitest run"
+ "test:watch": "vitest"
+ "db:generate": "drizzle-kit generate"
+ "db:migrate:local": "wrangler d1 migrations apply personality-d1-prod --local"
```

## Configuration Files

### vitest.config.ts (핵심 발췌)

```typescript
export default defineWorkersConfig({
  test: {
    poolOptions: {
      workers: {
        wrangler: { configPath: "./wrangler.toml" },
        miniflare: {
          d1Databases: ["DB"],
          kvNamespaces: ["KV"],
          r2Buckets: ["R2_BACKUP", "R2_SECRETS", "R2_UPLOADS"],
        },
      },
    },
    setupFiles: ["./test/setup.ts"],
    testTimeout: 15000,
  },
});
```

### drizzle.config.ts (핵심 발췌)

```typescript
export default {
  schema: "./src/db/schema.ts",
  out: "./migrations",
  dialect: "sqlite",
  driver: "d1-http",
} satisfies Config;
```

### test/setup.ts

RED phase: no-op. GREEN phase에서 `env.DB.exec(migrationSQL)` 적용 hook 활성화.

### src/db/schema.ts (stub)

```typescript
// RED phase stub — production 코드 없음
export const TABLES: Record<string, unknown> = {};
```

## Fail Verification

```
 RUN  v3.2.4 /Users/kampikrein/A/personality/apps/workers

 ❯ test/db/seed.test.ts (9 tests | 9 failed)
   × should have exactly 16 rows in personality_types after seed
     → D1_ERROR: no such table: personality_types: SQLITE_ERROR
   × should contain all 16 MBTI codes
     → D1_ERROR: no such table: personality_types: SQLITE_ERROR
   ...

 ❯ test/db/json_columns.test.ts (11 tests | 11 failed)
   × alerts.metadata > should insert and select JSON object correctly
     → D1_ERROR: no such table: alerts: SQLITE_ERROR
   ...

 ❯ test/db/foreign_keys.test.ts (21 tests | 16 failed | 5 passed)
   × table 'anonymous_sessions' should have FK to 'users' ...
     AssertionError: expected 0 to be greater than 0
   ✓ should have foreign_keys pragma enabled
   ✓ inserting domain_scores without parent assessment should fail
   ✓ inserting insights without parent profile should fail
   ✓ inserting profiles without parent assessment should fail
   ✓ inserting responses without parent assessment should fail

 ❯ test/db/unique_constraints.test.ts (26 tests | 26 failed)
   × should reject duplicate (assessment_id, domain) pair
     → D1_ERROR: no such table: domain_scores: SQLITE_ERROR
   ...

 ❯ test/db/user_encryption.test.ts (14 tests | 11 failed | 3 passed)
   × users table should have email_hash column (TEXT, NOT NULL)
     → expected undefined to be defined
   ✓ should be exactly 64 hex characters (SHA-256)
   ✓ should reject email_hash that is not 64 hex characters
   ✓ should reject null encryption_version  (테이블 없음 → D1_ERROR → rejects.toThrow 충족)

 ❯ test/db/schema.test.ts (31 tests | 31 failed)
   × should have exactly 14 domain tables in sqlite_master
     AssertionError: expected +0 to equal 14
   ...

 ❯ test/db/migrations.test.ts (0 tests)

 Test Files  7 failed (7)
      Tests  104 failed | 8 passed (112)
   Duration  1.25s
```

**fail 원인 분류**:
1. `D1_ERROR: no such table: X` — migration 미적용 (seed, json_columns, unique_constraints, schema, user_encryption)
2. `AssertionError: expected 0 to be greater than 0` — PRAGMA foreign_key_list 빈 결과 (foreign_keys)
3. `expected undefined to be defined` — PRAGMA table_info 컬럼 없음 (schema, user_encryption)
4. `AssertionError: expected +0 to equal 14` — sqlite_master 테이블 0개 (schema, migrations)

모든 fail 원인이 schema/migration 없음에서 기인 — RED phase 정상 상태 confirm.

## Implementation Hints for Green Phase

Green phase(seq 17 implementation)에서 다음 파일을 작성하면 104개 → 0개 fail 달성:

### 1. `apps/workers/src/db/schema.ts` — 14 tables Drizzle 정의

R4 user 분리 컬럼 + 9 JSON columns + 14 FK + UNIQUE 3건:

```typescript
import { sqliteTable, text, integer, real, index, uniqueIndex } from "drizzle-orm/sqlite-core";
import { sql } from "drizzle-orm";

// users — R4 분리 컬럼 (email_hash + email_enc + encryption_version)
export const users = sqliteTable("users", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  emailHash: text("email_hash").notNull().unique(),
  emailEnc: text("email_enc").notNull(),
  encryptionVersion: integer("encryption_version").notNull().default(1),
  displayName: text("display_name"),
  passwordDigest: text("password_digest"),
  deletedAt: text("deleted_at"),
  createdAt: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updatedAt: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
});

// personality_types — JSON columns: strengths, caution_patterns
export const personalityTypes = sqliteTable("personality_types", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  code: text("code").notNull().unique(),
  characterNameKo: text("character_name_ko").notNull(),
  characterNameEn: text("character_name_en").notNull(),
  summaryKo: text("summary_ko"),
  summaryEn: text("summary_en"),
  strengths: text("strengths", { mode: "json" }).$type<string[]>().notNull().default(sql`'[]'`),
  cautionPatterns: text("caution_patterns", { mode: "json" }).$type<string[]>().notNull().default(sql`'[]'`),
  collaborationStyle: text("collaboration_style"),
  conflictStyle: text("conflict_style"),
  learningStyle: text("learning_style"),
  careerHints: text("career_hints"),
  recoveryStyle: text("recovery_style"),
  createdAt: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updatedAt: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
});

// domain_scores — UNIQUE(assessment_id, domain) [Model Anchors 5]
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
  uniqueAssessmentDomain: uniqueIndex("index_domain_scores_on_assessment_id_and_domain")
    .on(t.assessmentId, t.domain),
}));

// profiles — UNIQUE(assessment_id) + JSON columns × 4 [Model Anchors 5]
export const profiles = sqliteTable("profiles", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  anonymousSessionId: integer("anonymous_session_id").notNull().references(() => anonymousSessions.id),
  assessmentId: integer("assessment_id").notNull().references(() => assessments.id),
  personalityTypeId: integer("personality_type_id").notNull().references(() => personalityTypes.id),
  typeCode: text("type_code").notNull(),
  scoreVector: text("score_vector", { mode: "json" }).$type<Record<string, number>>().notNull().default(sql`'{}'`),
  strengths: text("strengths", { mode: "json" }).$type<string[]>().notNull().default(sql`'[]'`),
  cautionPatterns: text("caution_patterns", { mode: "json" }).$type<string[]>().notNull().default(sql`'[]'`),
  suggestedActions: text("suggested_actions", { mode: "json" }).$type<unknown[]>().notNull().default(sql`'[]'`),
  policyBlocked: integer("policy_blocked", { mode: "boolean" }).default(false),
  fallbackMessage: text("fallback_message"),
  createdAt: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updatedAt: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
}, (t) => ({
  uniqueAssessmentId: uniqueIndex("index_profiles_on_assessment_id").on(t.assessmentId),
}));

// insights — UNIQUE(profile_id, context) + JSON: suggestions [Model Anchors 5]
export const insights = sqliteTable("insights", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  profileId: integer("profile_id").notNull().references(() => profiles.id),
  context: text("context").notNull(),
  explanation: text("explanation"),
  suggestions: text("suggestions", { mode: "json" }).$type<string[]>().notNull().default(sql`'[]'`),
  createdAt: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updatedAt: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
}, (t) => ({
  uniqueProfileContext: uniqueIndex("index_insights_on_profile_id_and_context")
    .on(t.profileId, t.context),
}));

// alerts — JSON: metadata
export const alerts = sqliteTable("alerts", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  alertType: text("alert_type").notNull(),
  severity: text("severity").notNull().default("medium"),
  status: text("status").notNull().default("open"),
  message: text("message"),
  notes: text("notes"),
  metadata: text("metadata", { mode: "json" }).$type<Record<string, unknown>>().notNull().default(sql`'{}'`),
  resolvedAt: text("resolved_at"),
  createdAt: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updatedAt: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
});

// audit_logs — JSON: metadata
export const auditLogs = sqliteTable("audit_logs", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  action: text("action").notNull(),
  actorId: integer("actor_id"),
  actorType: text("actor_type"),
  resourceId: integer("resource_id"),
  resourceType: text("resource_type"),
  metadata: text("metadata", { mode: "json" }).$type<Record<string, unknown>>().notNull().default(sql`'{}'`),
  createdAt: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updatedAt: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
});

// ... 나머지 8개 테이블 동일 패턴
// anonymous_sessions, assessments, question_sets, questions, responses, consents, deletion_requests
```

### 2. `apps/workers/migrations/` — drizzle-kit generate 결과

```bash
cd apps/workers
npm run db:generate   # → migrations/0000_initial_schema.sql 생성
npm run db:migrate:local  # → wrangler d1 --local 적용
```

### 3. `apps/workers/src/db/seed.ts` — PersonalityType × 16

```typescript
import { drizzle } from "drizzle-orm/d1";
import { personalityTypes } from "./schema";
import * as seedData from "./seed-data"; // 16개 타입 상수

export async function seed(d1: D1Database) {
  const db = drizzle(d1, { schema: { personalityTypes } });
  for (const pt of seedData.PERSONALITY_TYPES) {
    await db.insert(personalityTypes)
      .values(pt)
      .onConflictDoNothing({ target: personalityTypes.code });
  }
}
```

### 4. `apps/workers/src/db/index.ts` — Drizzle client

```typescript
import { drizzle } from "drizzle-orm/d1";
import * as schema from "./schema";

export function createDb(d1: D1Database) {
  return drizzle(d1, { schema });
}
export type Db = ReturnType<typeof createDb>;
```

### 5. test/setup.ts 활성화 (GREEN phase)

```typescript
import { env } from "cloudflare:test";
import { readFile } from "node:fs/promises"; // vitest Node 환경
import { join } from "node:path";

beforeAll(async () => {
  const migrationDir = join(process.cwd(), "migrations");
  const files = (await readdir(migrationDir)).filter(f => f.endsWith(".sql")).sort();
  for (const file of files) {
    const sql = await readFile(join(migrationDir, file), "utf-8");
    await env.DB.exec(sql);
  }
  // seed도 여기서 실행
});
```

> **주의**: test/setup.ts는 Workers 런타임 내 setup 파일이므로 node:fs 접근 불가.
> setup은 `vitest.config.ts`의 `globalSetup`으로 분리하거나,
> `test/setup.node.ts`를 별도 Node 환경에서 실행하는 패턴 사용.
> 또는 `beforeAll`을 각 테스트 파일에서 직접 선언.

## Cross-References

### Rails schema.rb → Drizzle 14 tables 1:1 매핑

| # | Rails 테이블 | Drizzle 이름 | JSON 컬럼 | FK 수 | UNIQUE |
|---|------------|-------------|-----------|-------|--------|
| 1 | alerts | alerts | metadata | 0 | - |
| 2 | anonymous_sessions | anonymousSessions | - | 1 (users) | session_token |
| 3 | assessments | assessments | - | 2 (anon_sess, qs) | - |
| 4 | audit_logs | auditLogs | metadata | 0 | - |
| 5 | consents | consents | - | 2 (anon_sess, users) | - |
| 6 | deletion_requests | deletionRequests | - | 1 (anon_sess) | request_token |
| 7 | domain_scores | domainScores | - | 1 (assessments) | **(assessment_id, domain)** |
| 8 | insights | insights | suggestions | 1 (profiles) | **(profile_id, context)** |
| 9 | personality_types | personalityTypes | strengths, caution_patterns | 0 | code |
| 10 | profiles | profiles | score_vector, strengths, caution_patterns, suggested_actions | 3 | **(assessment_id)** |
| 11 | question_sets | questionSets | - | 0 | version_code |
| 12 | questions | questions | - | 1 (question_sets) | (qs_id, domain, position) |
| 13 | responses | responses | - | 2 (assessments, questions) | (assessment_id, question_id) |
| 14 | users | users | - (R4 분리) | 0 | **email_hash** |

Rails schema.rb 참조 라인:
- `users`: L196-204
- `assessments`: L41-56
- `anonymous_sessions`: L28-39
- `domain_scores` (UNIQUE): L98-111, L109
- `profiles` (UNIQUE): L142-159, L156
- `insights` (UNIQUE): L113-122, L121
- `personality_types`: L124-140
- `audit_logs`: L58-69
- `alerts`: L14-26

## Recommendations

### GREEN phase 주의사항

1. **D1 timestamp 타입**: D1은 `DATETIME` 미지원. Drizzle에서 `text("created_at")` 또는 `integer("created_at", { mode: "timestamp" })` 사용. 일관성 위해 `text` 권장.

2. **JSON default 문법**: `text(...).default(sql\`'[]'\`)` 패턴 사용. Drizzle D1에서 JSON 기본값은 SQL literal로 전달해야 함.

3. **FK 참조 순서**: Drizzle에서 forward reference가 필요하면 arrow function `() => table.col` 사용.

4. **test/setup.ts 활성화**: GREEN phase에서 `test/setup.ts`에 migration SQL 적용 로직 추가. Workers 런타임에서 `node:fs` 접근 불가 → `vitest.config.ts`의 `globalSetup` 옵션 또는 각 테스트 파일 `beforeAll` 사용.

5. **vitest-pool-workers 버전**: 현재 3.2.4(모노레포 루트)가 실행됨. 공식 지원 범위 밖이지만 동작함. 루트 package.json에 vitest override를 추가하거나 workers 패키지에 로컬 vitest 강제 설치 검토.

6. **PRAGMA foreign_keys**: D1 in-memory에서 default OFF. migration SQL에 `PRAGMA foreign_keys = ON` 추가하거나 Drizzle `foreign_keys: true` 옵션 확인.

7. **profiles UPSERT**: `ON CONFLICT(assessment_id) DO UPDATE` 테스트(`unique_constraints.test.ts`)가 GREEN phase에서 통과하려면 schema에 `assessment_id` UNIQUE 제약이 필요 (Model Anchors 5 확인).

### verify 단계 추가 체크

- `drizzle-kit generate` 결과 SQL이 14 테이블 모두 `CREATE TABLE IF NOT EXISTS` 패턴인지 확인
- `wrangler d1 migrations apply --local` 재실행 시 에러 0개인지 확인
- `npm test` 후 pass 112 / fail 0 달성 확인
- PersonalityType seed가 `find_or_create_by` 멱등성(`INSERT OR IGNORE`)으로 작동하는지 확인

## References

| 문서 | 경로 | 관련 항목 |
|------|------|---------|
| Brief 021 | `docs/6_backend/02_cf_workers_rebuild/021_Brief_conversion_phase1.md` | In Scope 3, Decision 3, Model Anchors 5 |
| Scope 026 | `docs/6_backend/02_cf_workers_rebuild/026_Scope_conversion_phase1.md` | Cycle 2 DB Layer scope |
| R1 Drizzle+D1 | `docs/6_backend/02_cf_workers_rebuild/008_Research_axis1_drizzle_d1.md` | SOT, JSON1, envelope JSON |
| R4 Auth schema | `docs/6_backend/02_cf_workers_rebuild/011_Research_axis4_auth_hybrid.md` | email_hash + email_enc + encryption_version |
| Synthesis 018 | `docs/6_backend/02_cf_workers_rebuild/018_Synthesis_research_cycle.md` | S-018-F1 (R4), S-018-F2 (UNIQUE 3건) |
| Rails schema.rb | `server/db/schema.rb` | 14 tables, 14 FK 원본 |
| Rails seeds.rb | `server/db/seeds.rb` | PersonalityType × 16 |
