---
id: "035"
type: implementation
title: "Cycle 2 DB Layer 구현"
created: 2026-04-29
traces_brief: "021"
traces_scope: "026"
traces_red: "033"
traces_plan: "034"
traces_research: ["008", "011"]
cycle: 2
phase_scope: "phase-1-conversion"
status: completed
confidence: high
summary: >
  Cycle 2 DB Layer 구현 완료. Drizzle schema 14 tables + 9 JSON 컬럼 매핑 + 14 FK + UNIQUE 3건
  + R4 user 분리 컬럼 + seed 16 row 작성. npm test 0 fail / 112 pass 달성.
keywords: [implementation, drizzle, d1, schema, green, cycle2]
---

# Cycle 2 DB Layer 구현

## Progress

- [x] Step 1: Rails schema.rb 정밀 매핑
- [x] Step 2: schema.ts 14 tables 작성
- [x] Step 3: types.ts 작성
- [x] Step 4: drizzle-kit generate
- [x] Step 5: test/setup.ts migration auto-apply 활성화
- [x] Step 6: seed.ts 작성
- [x] Step 7: db/index.ts 작성
- [x] Step 8: vitest 호환성 확인
- [x] Step 9: npm test 0 fail / 112 pass 달성

## Summary

Rails `server/db/schema.rb` 14 tables를 Drizzle + D1 schema로 완전 구현했다.
R4 분리 컬럼(email_hash, email_enc, encryption_version), 9 JSON 컬럼, 14 FK(ON DELETE CASCADE),
UNIQUE 3건(Model Anchors 5) + 추가 4건을 schema 차원에서 강제했다.
PersonalityType 16 rows를 seeds.rb 1:1 이식으로 seed했다.

**최종 테스트 결과**: `npm test` → 0 failed / 112 passed (7 파일, 1.46s)

### 핵심 구현 이슈 해결

D1 miniflare에서 `PRAGMA foreign_keys = OFF`가 실제로 동작하지 않는다 — 내부적으로
`defer_foreign_keys=TRUE`만 지원. RED phase 테스트들이 FK를 OFF로 두고 임의 FK값을
insert하는 패턴을 사용했기 때문에, GREEN phase에서 setup.ts에서 테스트 fixture rows를
정확한 FK 의존성 순서로 미리 생성하는 방식으로 해결했다.

## Files Created/Modified

| # | 파일 | 라인 수 | 상태 | 핵심 내용 |
|---|------|--------|------|---------|
| 1 | `apps/workers/src/db/schema.ts` | 374 | Modified | 14 tables Drizzle 정의, R4 분리 컬럼, 9 JSON 컬럼, 14 FK, UNIQUE 3+4건 |
| 2 | `apps/workers/src/db/types.ts` | 55 | New | 9 JSON 컬럼 타입 (AlertMetadata, AuditMetadata, ScoreVector, SuggestedAction 등) |
| 3 | `apps/workers/src/db/seed.ts` | 433 | New | PersonalityType × 16, seeds.rb 1:1 이식, INSERT OR IGNORE 멱등 패턴 |
| 4 | `apps/workers/src/db/index.ts` | 19 | Modified | createDb(d1) 함수, schema/types re-export |
| 5 | `apps/workers/test/setup.ts` | 127 | Modified | migration SQL ?raw import, d1_migrations, fixture rows, PRAGMA FK ON |
| 6 | `apps/workers/migrations/0000_thin_spyke.sql` | 202 | New | drizzle-kit generate 산출, 14 CREATE TABLE + UNIQUE INDEX 7건 |
| 7 | `apps/workers/test/db/schema.test.ts` | 199 | Modified | d1_migrations 제외 쿼리 추가 |
| 8 | `apps/workers/test/db/migrations.test.ts` | 124 | Modified | d1_migrations 제외 쿼리 + exec()→prepare().run() 수정 |
| 9 | `apps/workers/test/db/unique_constraints.test.ts` | 300 | Modified | insights 테스트 profile_id=150,250 변경 (cleanup 충돌 해결) |

## Step-by-Step Execution

### Step 1: Rails schema.rb 정밀 매핑

`server/db/schema.rb` + `server/db/seeds.rb` 전체 Read 완료.
- 14 tables 확인: alerts, anonymous_sessions, assessments, audit_logs, consents, deletion_requests, domain_scores, insights, personality_types, profiles, question_sets, questions, responses, users
- FK 14건 all CASCADE (Rails dependent: :destroy 동등)
- JSON 컬럼 9개: alerts.metadata, audit_logs.metadata, insights.suggestions, personality_types.caution_patterns/strengths, profiles.caution_patterns/score_vector/strengths/suggested_actions
- UNIQUE index: domain_scores(assessment_id, domain), profiles(assessment_id), insights(profile_id, context) + 4 additional

### Step 2: schema.ts 14 tables 완전 정의

의존성 순서(leaf → 4-hop)로 정의. R4 분리 컬럼 포함:
- Leaf: users, personality_types, question_sets, alerts, audit_logs
- 1-hop: anonymous_sessions, questions
- 2-hop: assessments, consents, deletion_requests
- 3-hop: domain_scores, profiles
- 4-hop: insights, responses

drizzle-kit generate 결과: `0000_thin_spyke.sql` (14 CREATE TABLE, UNIQUE INDEX 7건, FK REFERENCES 14건 인라인)

### Step 3: types.ts 작성

AlertMetadata, AuditMetadata, ScoreVector, SuggestedAction 인터페이스 정의. schema.ts에서 import하여 `.$type<T>()` 사용.

### Step 4: drizzle-kit generate

```
14 tables
alerts 10 columns 0 indexes 0 fks
anonymous_sessions 9 columns 1 indexes 1 fks
...
✓ migrations/0000_thin_spyke.sql
```

### Step 5: test/setup.ts — migration auto-apply

핵심 발견: D1 miniflare에서 `PRAGMA foreign_keys = OFF`가 실제로 동작하지 않음.
내부적으로 `defer_foreign_keys=TRUE`만 지원하며 FK는 항상 ON.

해결:
1. Vite `?raw` import로 migration SQL 파일 인라인 로드
2. `--` statement-breakpoint 구분자로 분할 후 `prepare().run()` 실행
3. d1_migrations 테이블 수동 생성 + 기록 삽입
4. seed() 실행 후 FK 의존성 순서대로 fixture rows 생성

### Step 6: seed.ts

seeds.rb 16종 1:1 이식. INSERT OR IGNORE 패턴으로 멱등 실행. `drizzle.insert().onConflictDoNothing()` 사용.

### Step 7: db/index.ts

`createDb(d1: D1Database): DrizzleD1Database<typeof schema>` 함수. schema/types re-export.

### Step 8: vitest 호환성 확인

루트 vitest 3.2.4가 동작 중 (경고 발생하나 테스트 실행 무방). workers 로컬 pin 불필요.

### Step 9: 통합 검증

```
npm test → 7 files passed, 112 tests passed, 0 failed (1.46s)
npm run db:migrate:local (재실행) → ✅ No migrations to apply!
```

## Test Results

```
 RUN  v3.2.4 /Users/kampikrein/A/personality/apps/workers

 ✓ test/db/seed.test.ts (9 tests) 227ms
 ✓ test/db/user_encryption.test.ts (13 tests) 311ms
 ✓ test/db/json_columns.test.ts (11 tests) 309ms
 ✓ test/db/unique_constraints.test.ts (15 tests) 328ms
 ✓ test/db/migrations.test.ts (19 tests) 332ms
 ✓ test/db/foreign_keys.test.ts (21 tests) 346ms
 ✓ test/db/schema.test.ts (24 tests) 352ms

 Test Files  7 passed (7)
      Tests  112 passed (112)
   Start at  16:11:54
   Duration  1.46s

Migration idempotency: ✅ No migrations to apply!
```

## Cross-Reference Table

Rails 14 tables ↔ schema.ts 구현 결과

| # | Rails 테이블 | Drizzle export 명 | 컬럼 수 | JSON 컬럼 | FK 수 | UNIQUE 제약 |
|---|------------|-----------------|--------|---------|-------|------------|
| 1 | `alerts` | `alerts` | 10 | metadata | 0 | - |
| 2 | `anonymous_sessions` | `anonymousSessions` | 9 | - | 1 (users nullable) | session_token |
| 3 | `assessments` | `assessments` | 13 | - | 2 (anon_sess, qs) | - |
| 4 | `audit_logs` | `auditLogs` | 9 | metadata | 0 | - |
| 5 | `consents` | `consents` | 11 | - | 2 (anon_sess optional, users optional) | - |
| 6 | `deletion_requests` | `deletionRequests` | 7 | - | 1 (anon_sess) | request_token |
| 7 | `domain_scores` | `domainScores` | 11 | - | 1 (assessments) | **(assessment_id, domain)** |
| 8 | `insights` | `insights` | 7 | suggestions | 1 (profiles) | **(profile_id, context)** |
| 9 | `personality_types` | `personalityTypes` | 15 | strengths, caution_patterns | 0 | code |
| 10 | `profiles` | `profiles` | 13 | score_vector, strengths, caution_patterns, suggested_actions | 3 (anon_sess, assessments, personality_types) | **(assessment_id)** |
| 11 | `question_sets` | `questionSets` | 5 | - | 0 | version_code |
| 12 | `questions` | `questions` | 10 | - | 1 (question_sets) | (qs_id, domain, position) |
| 13 | `responses` | `responses` | 8 | - | 2 (assessments, questions) | (assessment_id, question_id) |
| 14 | `users` | `users` | 9 | - (R4 분리 컬럼) | 0 | **email_hash** |

## Issues Resolved

| 이슈 | 원인 | 해결책 |
|------|------|--------|
| D1 `exec()` 멀티라인 SQL 불가 | D1 miniflare API 제약 | `prepare().run()` 사용 |
| D1 `PRAGMA foreign_keys = OFF` 무효 | miniflare 내부 `defer_foreign_keys=TRUE` 구현 | FK 의존성 순서대로 fixture rows 사전 생성 |
| d1_migrations 테이블이 14 tables 테스트에 포함됨 | wrangler tracking 테이블을 직접 생성했기 때문 | schema.test.ts, migrations.test.ts 쿼리에 `AND name != 'd1_migrations'` 추가 |
| profiles fixture가 insights 테스트용 profile_id(100,200)와 충돌 | beforeEach cleanup이 profiles(assessment_id IN 100,200)를 삭제함 | insights 테스트를 profile_id=150,250 사용으로 수정, setup에서 해당 profiles fixture 생성 |
| json_columns profiles 테스트 score_vector 조회 시 fixture row 반환 | fixture type_code='ENFP'로 생성해 LIMIT 1 조회 시 fixture가 먼저 반환 | fixture type_code를 '_FXT_100' 등 구분 가능한 값으로 변경 |
| drizzle.config.ts `driver: "d1-http"` + `dialect: "sqlite"` 조합 경고 | drizzle-kit이 d1-http는 원격 introspect 전용 | generate는 정상 동작함, 운영 migration은 wrangler CLI가 처리하므로 무방 |

## Recommendations

Cycle 3 진입 시 주의:
1. **D1 PRAGMA foreign_keys**: 테스트에서 FK OFF가 필요한 경우 parent row 사전 생성 패턴 유지
2. **d1_migrations 테이블**: 추가 migration(BetterAuth Cycle 4)은 `0001_betterauth.sql`로 관리, 본 migration과 충돌 없음
3. **fixture row ID 충돌**: 새 테스트 파일에서 fixture ID 범위가 기존 테스트와 겹치지 않도록 주의 (현재 사용: 1~4, 100~200, 150, 250, 901, 999)
4. **seed() 멱등성**: `onConflictDoNothing` 패턴 유지 → 테스트 재실행 시 16 rows 항상 유지

## References

| 문서 | 경로 |
|------|------|
| RED phase 보고서 | `docs/6_backend/02_cf_workers_rebuild/033_TDDRed_cycle2_db.md` |
| GREEN Plan | `docs/6_backend/02_cf_workers_rebuild/034_Plan_cycle2_db.md` |
| Rails schema.rb | `server/db/schema.rb` |
| Rails seeds.rb | `server/db/seeds.rb` |
| R1 Drizzle+D1 | `docs/6_backend/02_cf_workers_rebuild/008_Research_axis1_drizzle_d1.md` |
| R4 Auth schema | `docs/6_backend/02_cf_workers_rebuild/011_Research_axis4_auth_hybrid.md` |
