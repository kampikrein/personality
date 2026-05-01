---
id: "026"
type: scope
title: "Phase 1 — Rails → TS Conversion Scope (Brief 021 매핑)"
created: 2026-04-29
traces_brief: "021"
parent_brief: "001"
parent_scope: "007"
complexity: complex
research_needed: false
research_reason: "Brief 021 deep_critique 완료(022/023/024 + Synthesis 025), Phase 2 Carryover § 2.3에 research-deferred 항목 별도 명시. 본 Phase 1은 추가 research 불요."
auto_run: false
effort_mode: deep
tdd_mode: true
deep_critique: true
critique_docs: ["027", "028", "029"]
critique_synthesis: "030"
planned_cycles: 7
deliberation_mode: skipped
deliberation_skip_reason: "Brief 001 + 021 모두 deep-critique 완료 (002-005, 022-024 + Synthesis 006/025). 프로젝트에 analyst/researcher/architect/critic 메타 역할 에이전트 부재 (도메인 전문가 7개만)."
intent: >
  Brief 021(Phase 1 = Rails → TS conversion only, Toss/Cutover/외부 자원 deferred)을
  alignment anchor로 받아, 7 활성 사이클(Foundation 한정형 + DB + Services +
  Auth+Security + API+Mobile + Admin+Public UI + Compliance) + tail (eval/qualify/
  push/retro)로 구체화. 외부 자원 미접촉 운영 (wrangler dev --local + vitest-pool-workers).
  기존 pipeline DB 재사용 — 새 init 금지.
summary: >
  7 활성 영역, 의존성 7건, 7 impl 사이클 + tail (cycle-10 eval/qualify/push + cycle-99 retro).
  TDD 적용: Cycles 2-6, 8 (인프라/cutover 외). Pipeline DB는 이미 정렬됨 — Cycle 7/9/10 interrupted.
  Scope 007의 narrowing 결과로 본 Scope 026이 Phase 1 alignment anchor 역할.
keywords: [phase-1, rails-to-typescript-scope, conversion-focus, local-first, deep-mode, tdd-mode, brief-021]
research_axes: []
research_cycles: 0
impl_cycles: 7
deferred_cycles: [7, 9, 10_partial]
deferred_reason: "Brief 021 Out of Scope: Cycle 7 Toss(seq 35-38) + Cycle 9 Cutover Safety(seq 43-45) + Cycle 10 makeplan/impl/verify(seq 46-48) — pipeline.sh edit interrupted 적용 완료 (reason='phase-2-deferred')"
phase_1_tail: "Cycle 10 eval/qualify/push (seq 49-51) + cycle-99 retro 활성 유지 (Phase 1 종료 검증)"
cycles:
  - cycle: 1
    area: "Foundation 한정형 (CF infra 파일 템플릿 + 로컬 검증 인프라) — C1 S1 보강"
    in_scope: [1, 2]
    depends_on: []
    research_needed: false
    tdd_red: false
    decisions: [1, 2, 14, 15]
    note: "Plan 020의 외부 자원 step (U1-U8) skip. wrangler.toml stub + package.json + tsconfig + .github/workflows placeholder + README setup runbook + npm install. **추가 (C1 S1)**: wrangler dev --local --persist 셋업 + miniflare config + @cloudflare/vitest-pool-workers 베이스 테스트 1건 (D1 binding smoke). **Mn4**: scheduled handler stub-only `export default { scheduled() { return new Response('stub-only Phase 2', {status: 501}) } }`."
  - cycle: 2
    area: "DB Layer (Drizzle schema)"
    in_scope: [3]
    depends_on: [1]
    research_needed: false
    tdd_red: true
    note: "R1 SOT(Drizzle=schema, wrangler=runner) + R2 UNIQUE 제약 3건 + R4 user 분리 컬럼(email_hash/email_enc/encryption_version) 통합. 9 JSON 컬럼 + 14 FK + PersonalityType 16 seed."
  - cycle: 3
    area: "Domain Services Port (services + saga)"
    in_scope: [4, 9]
    depends_on: [2]
    research_needed: false
    tdd_red: true
    note: "20 services / 1,850 LOC Ruby → TS. scoring 8단계 Pure Saga (Phase A-E forward-recovery, step 7 UPSERT). RSpec 18 → Vitest 1:1 동등성."
  - cycle: 4
    area: "Auth + Security Baseline"
    in_scope: [5, 9]
    depends_on: [1, 2]
    research_needed: false
    tdd_red: true
    note: "BetterAuth(D1+KV) + CF Access verifier(JWKS resolver DI 패턴 — M1) + Web Crypto AES-GCM envelope JSON + email_hash hook + KV sessions + parallel-key rotation 함수 + 보안 baseline 5종(CORS/CSP/HSTS/rate limit/CSRF). 실 SSO/실 키/WAF는 Phase 2."
  - cycle: 5
    area: "API Layer + Mobile Contract"
    in_scope: [6, 9]
    decisions: [8, 9]
    depends_on: [3, 4]
    research_needed: false
    tdd_red: true
    note: "13 컨트롤러 + admin → Hono routes. 모바일 JSON API 신설. OpenAPI 3 + Hono RPC(TS) + Dart codegen(JAR build-time 예외 — Decision 9). API envelope `{success,data,error}` 미들웨어 + 에러 코드 카탈로그."
  - cycle: 6
    area: "Admin UI + Public Assessment Flow SSR (영역 확장)"
    in_scope: [7, 9]
    depends_on: [5]
    research_needed: false
    tdd_red: true
    note: "9 ERB admin → Hono SSR vanilla (~600 TSX). 18 ERB + 8 Stimulus 공개 평가 흐름 → Hono SSR + hx-boost 옵셔널. EV-015-S1 흡수."
  - cycle: 8
    area: "Compliance (GDPR/PIPA flows)"
    in_scope: [8, 9]
    depends_on: [5, 6]
    research_needed: false
    tdd_red: true
    note: "consent / deletion_request / audit_log / alert 모델 이전. 5 흐름: consent 수집·철회, 계정 삭제, audit log, 국외 이전 고지·동의, 14세 미만."
  - cycle: 10_tail
    area: "Phase 1 Tail (eval / qualify / push)"
    in_scope: []
    depends_on: [1, 2, 3, 4, 5, 6, 8]
    research_needed: false
    tdd_red: false
    note: "Cycle 10 makeplan/impl/verify는 interrupted (Phase 2 deferred). eval/qualify/push (seq 49-51)만 Phase 1 종료 검증으로 활성. Brief 021 Ideal Criteria 28개 충족 점검."
  - cycle: 99_retro
    area: "Phase 1 Retro"
    in_scope: []
    depends_on: [10_tail]
    research_needed: false
    tdd_red: false
    note: "Phase 1 retrospective. Phase 2 재진입 시 입력으로 활용."
---

# Phase 1 — Rails → TS Conversion Scope

## 작업 목표

Brief 021(Phase 1 = Rails → TS conversion only)을 7 활성 사이클 + tail로 구체화. Brief 021 § Ideal Criteria 28개 충족이 본 scope의 성공 기준.

**제약** (Brief 021 Constraints 그대로 승계):
- 외부 자원 미접촉 (wrangler dev --local + vitest-pool-workers)
- archive Rails read-only (server/ 디렉토리 수정 금지)
- TDD red-green-refactor (Cycles 2-6, 8)
- 20 MAN-DAY 한도 (50% 초과 시 Brief 재검토 트리거)
- conversion_fidelity 우선 (RSpec 18 → Vitest 1:1 동등성)
- Phase 2 재진입 호환성 보존
- 도구 버전 pin (Brief 021 Phase 2 Carryover § 2.4)

**deferred** (Brief 021 Out of Scope, 본 scope 미포함):
- Cycle 7 Toss 결제 (seq 35-38, interrupted)
- Cycle 9 Cutover safety (seq 43-45, interrupted)
- Cycle 10 makeplan/impl/verify (seq 46-48, interrupted)
- Phase 2 Carryover § 2.3 9개 항목 (production-only 검증)

## 접근 방향

### 핵심 원칙

1. **Pipeline DB 재사용 + Brief 021 narrowing 흡수**: 새 init은 destructive이라 금지. 기존 DB(`007_cf_workers_rebuild_1c64.db`)에서 Cycle 7/9/10 interrupted 처리 완료 (Brief 021 Decision 14 + Synthesis 025 C2 적용). 본 Scope 026은 Phase 1 alignment anchor로 추가만.
2. **Foundation 한정형 → 데이터 → 도메인 → 경계 순**: Cycle 1 한정형(파일 템플릿) → 2 DB → 3 Services → 4 Auth+Security → 5 API → 6 Admin+Public → 8 Compliance.
3. **인증/보안은 도메인 다음, API 이전**: Cycle 4(Auth+Security)가 Cycle 5(API)보다 선행 — 보안 baseline 미수립 상태로 API 노출 금지.
4. **TDD는 코드 사이클에만**: Cycle 1 한정형은 파일 템플릿이라 단위 테스트 의미 적음 → tdd-red 미적용. Cycles 2-6, 8은 모두 tdd-red 적용.

### 숙의 모드 미적용

Brief 001 + Brief 021 모두 status: completed + deep_critique 완료 → 통상 4역할 숙의 트리거. 본 토픽 skip 근거:
1. Brief 001 deep critique (002-005) + Brief 021 deep critique (022-024) 합계 8 비평 관점이 이미 적대적 검토 흡수 (Critical 6 + Major 25 + Medium 15+)
2. 프로젝트 `.claude/agents/` = 도메인 전문가 7개 (coding/flutter/mbti/enneagram/tarot/uiux/psychology). analyst/researcher/architect/critic 메타 역할 부재.
3. 사이클별 makeplan에서 critic 1인 견제 + tail eval로 종합 점검.

## Research 판단

- **판단**: **불필요**
- **근거**: Brief 021 status: completed + deep_critique: true + 15 Decisions ≥ 10 + Phase 2 Carryover § 2.3에 research-deferred 9건 별도 명시. 본 Phase 1에서 추가 research 호출 없음. (Phase 2 재진입 시 carryover 항목 일부가 새 research 사이클로 재진입 가능.)
- **파이프라인**: Agent(makeplan) → Agent(impl) → Agent(verify) per cycle, 마지막 사이클 후 [tail] eval → qualify → push → retro.

## 영역 식별

| # | 영역 | 주요 파일/모듈 | 설명 | Brief 021 In Scope |
|---|------|-------------|------|------------------|
| 1 | **Foundation 한정형 + 로컬 검증 인프라** (C1 S1 보강) | `wrangler.toml`, `package.json`, `tsconfig.json`, `.github/workflows/*.yml`, `README.md`, `vitest.config.ts`, `tests/smoke/d1_binding.test.ts` | CF infra 파일 템플릿 + wrangler dev --local --persist 셋업 + miniflare + vitest-pool-workers 베이스. compatibility_flags=nodejs_compat (Decision 15) | 1, 2 |
| 2 | **DB Layer** | `db/schema.ts`, `db/migrations/*.sql`, `db/seed.ts`, `tests/db/*.test.ts` | 14 테이블 Drizzle, R4 user 분리 컬럼 + R2 UNIQUE 제약 + R1 envelope. PersonalityType 16 seed. | 3 |
| 3 | **Domain Services Port** | `lib/services/{scoring,tone_filter,restricted_terms,insights}.ts`, `lib/saga/*.ts`, `tests/services/*.test.ts` | 1,850 LOC Ruby → TS. Pure Saga (Phase A-E). RSpec 18 → Vitest 1:1 동등성. | 4, 9 |
| 4 | **Auth + Security** | `lib/auth/{betterauth,cf_access_verifier,encryption,email_hash,session}.ts`, `lib/middleware/{cors,csp,hsts,rate_limit,csrf}.ts`, `tests/auth/*.test.ts` | BetterAuth + CF Access JWKS DI verifier + Web Crypto envelope + parallel-key rotation 함수 + 보안 5종 (실 SSO/WAF Phase 2) | 5, 9 |
| 5 | **API Layer + Mobile** | `app/routes/api/*.ts`, `app/routes/admin/api/*.ts`, `shared/api-schema/openapi.yaml`, `shared/api-schema/dart/*`, `lib/middleware/envelope.ts`, `tests/routes/*.test.ts` | 13 컨트롤러 → Hono routes. OpenAPI 3 + Hono RPC TS + Dart codegen. envelope 강제. | 6, 9 |
| 6 | **Admin UI + Public Flow** (C1 S2 ERB 정정) | `app/routes/admin/*.ts`, `app/routes/assessments/*.ts`, `app/routes/auth/*.ts`, `app/routes/results/*.ts`, `app/components/*.tsx`, `tests/admin/*.test.ts`, `tests/assessments/*.test.ts` | **9 ERB admin + 13 ERB 공개 흐름 + 8 Stimulus → Hono SSR vanilla + hx-boost 옵셔널**. layouts/pwa 5건은 전환 제외(Hono 자체 layout, manifest 별도). | 7, 9 |
| 7 | **Compliance** | `lib/compliance/{consent,deletion,audit,jurisdiction}.ts`, `app/routes/api/{consents,deletion-requests}/*.ts`, `tests/compliance/*.test.ts` | 4 모델 이전 + 5 흐름 (consent/deletion/audit/국외 이전/14세 미만) | 8, 9 |

### 파일 목록 추정

| Cycle | Modified (actual change) | Reviewed (check-only) | Confidence |
|-------|------------------------|---------------------|------------|
| 1 | `wrangler.toml`, `package.json`, `tsconfig.json`, `.github/workflows/{prod,preview,staging}.yml`, `README.md`, `.gitignore` | `server/Gemfile.lock` | high |
| 2 | `db/schema.ts`, `db/migrations/0000_init.sql`, `db/seed.ts`, `tests/db/*.test.ts` (≥3) | `server/db/schema.rb`, 15 모델 | high |
| 3 | `lib/services/scoring/*.ts` (≥3 modules), `tone_filter.ts`, `restricted_terms.ts`, `insights.ts`, `lib/saga/*.ts` (≥2), `tests/services/*.test.ts` (≥18 동등성) | `server/app/services/*.rb` (20개) | medium |
| 4 | `lib/auth/{betterauth,cf_access_verifier,encryption,email_hash,session,key_rotation}.ts`, `lib/middleware/{cors,csp,hsts,rate_limit,csrf}.ts`, `tests/auth/*.test.ts` (≥6) | `server/app/models/user.rb`, `server/app/controllers/sessions_controller.rb` | medium |
| 5 | `app/routes/api/*.ts` (**32 endpoints: public 22 + admin 10 — C2 S2**), `app/routes/admin/api/*.ts`, `shared/api-schema/openapi.yaml`, codegen 출력, `lib/middleware/envelope.ts`, `tests/routes/*.test.ts` (≥32) | `server/config/routes.rb`, 13 controllers | **medium** (C2 보강 후) |
| 6 | `app/routes/admin/*.ts` (9), `app/routes/assessments/*.ts` (3), `app/routes/auth/*.ts` (2), `app/routes/results/*.ts` (5), `app/routes/{consents,deletion-requests}/*.ts` (3 UI), `app/components/*.tsx` (~4), `tests/admin/*.test.ts`, `tests/assessments/*.test.ts` | `server/app/views/admin/*.erb`(9), `assessment_questions/`(2), `assessments/`(1), `accounts/`(1), `sessions/`(1), `consents/`(1), `deletion_requests/`(2), `results/`(5) [공개 13], `app/javascript/controllers/*.js`(8) [Stimulus] | **medium** (C1 S2 보강 후 — 13 + 9 = 22 routes) |
| 7 (Cycle 8) | `lib/compliance/*.ts` (≥4), `app/routes/api/{consents,deletion-requests}/*.ts`, `tests/compliance/*.test.ts` | `server/app/models/{consent,deletion_request,audit_log,alert}.rb` | medium |

**비평 030 보강 후 confidence 갱신**: Cycle 5/6 모두 medium으로 격상 (실측 인벤토리 통합). 5의 32 endpoints는 `server/config/routes.rb` 분석 결과 (public 22 + admin 10). 6의 ERB 분류는 27 = admin 9 + 공개 13 + layouts/pwa 5 (실측, layouts/pwa 전환 제외).

### ERB → TSX 매핑 표 (Cycle 6 makeplan 입력 — C1 S2 + Mn2)

| 분류 | ERB 파일 | TSX 매핑 위치 | 분류 |
|------|---------|------------|------|
| admin | alerts/(2), audit_logs/(2), dashboard/(1), question_sets/(4) = 9 | `app/routes/admin/*.tsx` | Cycle 6 |
| 공개 평가 | assessment_questions/_question, show (2) + assessments/show (1) = 3 | `app/routes/assessments/*.tsx` | Cycle 6 |
| 결과 표시 | results/show (1) + 4 partials (_insight_card, _spectrum, _trust_notice, _type_hero) = 5 | `app/routes/results/*.tsx` | Cycle 6 |
| 인증 | accounts/new (1) + sessions/new (1) = 2 | `app/routes/auth/*.tsx` | Cycle 4 + 6 공유 |
| 동의·삭제 UI | consents/new (1) + deletion_requests/{new, show} (2) = 3 | `app/routes/{consents,deletion-requests}/*.tsx` | Cycle 6 (UI) + Cycle 8 (logic) |
| **전환 제외** | layouts/{admin, application, mailer.html, mailer.text} (4) + pwa/manifest.json (1) = 5 | Hono 자체 layout / manifest 별도 처리 | — |
| **합계** | **27 ERB** | **22 TSX routes (5 layouts/pwa 제외)** | — |

### 32 Endpoints 인벤토리 (Cycle 5 makeplan 입력 — C2 S2)

`server/config/routes.rb` 실측 (resources expansion 포함):

| 분류 | Controller | Actions | 개수 |
|------|-----------|---------|-----|
| public | sessions | new, create, destroy | 3 |
| public | accounts | new, create | 2 |
| public | assessments | index, show, start, complete | 4 |
| public | assessment_questions | show, answer | 2 |
| public | results | show, share | 2 |
| public | consents | new, create, withdraw | 3 |
| public | deletion_requests | new, create, show, confirm | 4 |
| public | misc | health check, sitemap | 2 |
| **public 합계** | | | **22** |
| admin | sessions (admin SSO) | login, logout | 2 |
| admin | dashboard | index | 1 |
| admin | question_sets | index, show, new, create, edit, update, destroy | 7 |
| admin | alerts | index, show, acknowledge | 2 (acknowledge merge) — 2 |
| admin | audit_logs | index, show | 2 |
| **admin 합계** | | | **10** (정합 cross-check 필요 — makeplan에서 확정) |
| **합계** | | | **32 (실측 권고치)** |

(정확한 카운트는 Cycle 5 makeplan에서 routes.rb dry-run 인벤토리로 최종 확정.)

## 의존성 맵

```
            ┌──────────────────────────┐
            │ Cycle 1 Foundation 한정형 │
            └──┬─────────────────────┬─┘
               │                     │
        ┌──────┴──────┐              │
        │ Cycle 2 DB  │              │
        └─┬───────┬───┘              │
          │       │                  │
   ┌──────┴┐    ┌─┴────────────┐     │
   │ 3 Svc │    │ 4 Auth+Sec   │←────┘
   └────┬──┘    └──────┬───────┘   (Cycle 1 secrets)
        │              │
        └──────┬───────┘
               │
        ┌──────┴────────┐
        │ Cycle 5 API   │
        │  + Mobile     │
        └──┬─────────┬──┘
           │         │
   ┌───────┴───┐  ┌──┴──────────┐
   │ 6 Admin   │  │ 8 Compliance│
   │  + Public │  │             │
   └───────┬───┘  └──┬──────────┘
           │         │
           └────┬────┘
                │
       ┌────────┴───────────┐
       │ [tail] eval →      │
       │  qualify →         │
       │  push →            │
       │  retro             │
       └────────────────────┘
```

### 의존 관계 상세

| From → To | 의존 내용 | 근거 |
|----------|---------|------|
| 1 → 2 | wrangler.toml binding 정의 + drizzle-kit + wrangler d1 통합 | Brief 021 In Scope 1, 3 |
| 1 → 4 | secrets 운영 모델 (parallel-key rotation 함수의 Wrangler secret 인터페이스) | Brief 021 In Scope 1, 5 |
| 2 → 3 | Drizzle ORM 호출 + UNIQUE 제약 + saga UPSERT | R2 + R1 + R4 통합 결정 |
| 2 → 4 | user 분리 컬럼 schema + key rotation 진척 추적 | R4 결정 |
| 3, 4 → 5 | Hono routes가 services + auth middleware 결합 | Brief 021 In Scope 6 |
| 5 → 6 | Admin UI가 admin API 호출 또는 services 직접 호출 | R3 winner 패턴 |
| 5, 6 → 8 | consent / deletion 흐름은 API + admin UI 양쪽 노출 | Brief 021 In Scope 8 |
| 1-6, 8 → tail | 모든 활성 사이클 verify 후 종합 검증 | Phase 1 완료 정의 |

## 실행 순서

### Impl Phase

| 사이클 | 영역 | 선행 | TDD | 파이프라인 |
|--------|------|------|-----|-----------|
| 1 | Foundation 한정형 | 없음 | ✗ | makeplan → impl → verify |
| 2 | DB Layer | 1 | ✓ | tdd-red → makeplan → impl → verify |
| 3 | Domain Services | 2 | ✓ | tdd-red → makeplan → impl → verify |
| 4 | Auth + Security | 1, 2 | ✓ | tdd-red → makeplan → impl → verify |
| 5 | API Layer + Mobile | 3, 4 | ✓ | tdd-red → makeplan → impl → verify |
| 6 | Admin UI + Public Flow | 5 | ✓ | tdd-red → makeplan → impl → verify |
| 8 | Compliance | 5, 6 | ✓ | tdd-red → makeplan → impl → verify |
| **[tail]** | eval → qualify → push → retro | 모든 cycle | — | 4 sub-agents 순차 |

선형 직렬 (병렬은 makeplan별 검토). Cycle 4가 Cycle 5보다 선행 — 보안 baseline 없이 API 노출 금지.

### Pipeline DB 정렬 상태 (이미 적용됨)

```
[cycle-1] makeplan: done (020)
[cycle-1] implementation: pending (seq 13) ← 다음
[cycle-1] verify: pending (seq 14)
[cycle-2] tdd-red, makeplan, implementation, verify: pending (seq 15-18)
[cycle-3] tdd-red, makeplan, implementation, verify: pending (seq 19-22)
[cycle-4] tdd-red, makeplan, implementation, verify: pending (seq 23-26)
[cycle-5] tdd-red, makeplan, implementation, verify: pending (seq 27-30)
[cycle-6] tdd-red, makeplan, implementation, verify: pending (seq 31-34)
[cycle-7] tdd-red, makeplan, implementation, verify: interrupted (seq 35-38, phase-2-deferred)
[cycle-8] tdd-red, makeplan, implementation, verify: pending (seq 39-42)
[cycle-9] makeplan, implementation, verify: interrupted (seq 43-45, phase-2-deferred)
[cycle-10] makeplan, implementation, verify: interrupted (seq 46-48, phase-2-deferred)
[cycle-10] eval, qualify, push: pending (seq 49-51, Phase 1 tail)
[cycle-99] retro: pending (Phase 1 retro)
```

## 사이클별 makeplan 입력 (Brief 021 Decision 11 + Synthesis 018/025 통합)

| Cycle | Research 입력 | Critique 보강 |
|-------|------------|-------------|
| 1 Foundation | R4 secrets 운영 모델 | Plan 020 Step 8 cron handler를 stub-only로 변경 (M5). compatibility_flags 명시 (MS3). 외부 자원 step (U1-U8) skip. |
| 2 DB | R1 (SOT, JSON1, envelope) + R2 (UNIQUE 제약) + R4 (user 분리 컬럼) | — |
| 3 Services | R2 (Pure Saga, 7/8 idempotent, Phase A-E, ~150 LOC) | RSpec 18 → Vitest 1:1 매핑 명시 |
| 4 Auth+Sec | R4 (BetterAuth + CF Access verifier + parallel-key rotation) | M1 (CF Access verifier JWKS resolver DI 패턴), M3 (CSRF caveat 복원), M11 (JWKS rotation fixture test) |
| 5 API | (Brief 021 Decision 8/9 직접) | M2 (Dart codegen build-time JAR 예외), Anchor 2 외부 자원 정의 확장 |
| 6 Admin+Public | R3 (Hono SSR vanilla + hx-boost) | EV-015-S1 흡수 — 18 ERB + 8 Stimulus 공개 흐름 포함 |
| 8 Compliance | (Brief 021 In Scope 8 직접) | — |

## 예상 밖 의존성 대응 규칙 (template 승계)

연구/구현 중 이전 사이클 수정 발견 시:
- 수정 범위 ≤ 3 파일 → 현재 사이클 plan에 포함 (gate makeplan 흡수)
- 수정 범위 > 3 파일 → Scope 026 update + 사이클 재조정 (gate add-cycle / edit)

## Critique Integration (Synthesis 030)

본 Scope는 --deep critique 3 관점(027 매핑/028 makeplan 진입 준비도/029 Pipeline DB 일관성)을 받아 P1 Critical 3건 + P2 Major 일부 + Missing 3건을 통합. 자세한 finding은 [`030_Critique_Synthesis_scope.md`](./030_Critique_Synthesis_scope.md).

### Critical 3건 (inline 적용 완료)

| # | Source | Finding | 적용 위치 |
|---|--------|---------|---------|
| C1 | S1 | Brief In Scope 2 "로컬 검증 인프라" Cycle 미매핑 | Cycle 1 in_scope=[1, 2] + 영역 명칭 보강 + note (적용) |
| C2 | S2 | Scope/Brief "18 ERB" 사실 오류 — 실측 13 + layouts/pwa 5 제외 | Cycle 6 영역 식별 표 + ERB → TSX 매핑 표 (적용) |
| C3 | S2 | Cycle 5 "≥10 endpoints" → 실측 32 (public 22 + admin 10) | Cycle 5 영역 + 파일 목록 + 32 Endpoints 인벤토리 표 (적용) |

### MS1 — Decision-Cycle 매핑 표 (Brief 021 15 Decisions × 7 Cycles)

| Decision | 내용 | Cycle 매핑 |
|---------|------|----------|
| 1 Phase 분리 | Brief 001 frozen + 021 활성 | (모든 cycle 함의) |
| 2 외부 자원 미접촉 운영 | wrangler dev --local + vitest-pool-workers | **Cycle 1** (셋업 책임) |
| 3 R4 schema 패턴 | email_hash + email_enc + encryption_version | **Cycle 2** (schema 정의) + Cycle 4 (운용) |
| 4 Cycle 6 영역 확장 | Admin + Public Assessment Flow | **Cycle 6** |
| 5 Pure Saga (D1 only) | scoring 8단계 forward-recovery | **Cycle 3** |
| 6 Hono SSR vanilla | + hx-boost 옵셔널 | **Cycle 6** |
| 7 BetterAuth + CF Access verifier | JWKS resolver DI 패턴 (M1) | **Cycle 4** |
| 8 API envelope | `{success, data, error}` + 에러 코드 | **Cycle 5** |
| 9 OpenAPI 3 + codegen | Hono RPC TS + Dart codegen JAR build-time | **Cycle 5** |
| 10 TDD red-green-refactor | Cycles 2-6, 8 적용 | **Cycle 2-6, 8 tdd_red=true** |
| 11 Toss 정정사항(BC2/BC3) 보존 | Phase 2 Cycle 7 입력 | **Phase 2 carryover (deferred)** |
| 12 로컬 검증만 — Local/Partial/Production-only 매트릭스 | verify_scope 표기 | **Cycle 10_tail eval/qualify** |
| 13 Phase 1 완료 정의 | Ideal Criteria 28 + RSpec 18 동등성 | **Cycle 10_tail / Cycle 99_retro** |
| 14 Pipeline DB 재진입 | interrupted 처리 + 한정형 implementation | (이미 적용 — DB 정렬) |
| 15 compatibility_flags | nodejs_compat | **Cycle 1** (wrangler.toml) |

### MS2 — Out of Scope cycle 영향 표 (Brief 021 Out of Scope 10 항목)

| Out of Scope | 영향받는 Cycle | Phase 2 재진입 시점 |
|------------|------------|------------------|
| 1 Toss 결제 7-stage | Cycle 7 (interrupted seq 35-38) | Phase 2 — Toss 가맹점 등록 후 |
| 2 Cutover safety (archive smoke + rollback drill) | Cycle 9 (interrupted seq 43-45) | Phase 1 완료 + 외부 환경 |
| 3 Cutover execution (Phase A→B→C) | Cycle 10 makeplan/impl/verify (interrupted seq 46-48) | Phase 1 완료 + 사용자 결정 |
| 4 Production monitoring | (현 cycle 미할당, Phase 2 신설) | 외부 deploy 후 |
| 5 Foundation 외부 자원 | Cycle 1 (한정형으로 흡수, 외부 step skip) | 사용자 작업 |
| 6 CF Access 실 SSO 연결 | Cycle 4 (verifier 코드만 작성) | Phase 2 |
| 7 D1 자동 export → R2 cron | Cycle 1 (stub-only, Mn4) + Phase 2 활성 | Phase 2 Cycle 9 |
| 8 Rails 코드 archive 이동 + 폐기 | Phase 2 Cycle 10 | Phase 1 완료 후 |
| 9 글로벌 결제 (Stripe) | (Brief 001 Decision 13 계승) | Stripe Korea 또는 해외 법인 |
| 10 새 도메인 기능 추가 | (별도 phase) | 별도 phase |

### MS3 — Phase 2 Carryover cycle 인지 표 (Brief 021 § 2 — 11 항목)

| Carryover | 내용 | Cycle 인지 책임 |
|----------|------|------------|
| BC2 | Toss webhook 모델 이중화 (Model A secret / Model B HMAC v1) | Phase 2 Cycle 7 makeplan |
| BC3 | idempotency key 정확 명칭 `tosspayments-webhook-transmission-id` | Phase 2 Cycle 7 makeplan |
| OQ-1 | Cycle 6 공개 평가 흐름 인터랙션 매핑 | **Cycle 6 makeplan** (이미 본 Scope에서 ERB 매핑 표로 일부 해소) |
| OQ-2 | BetterAuth `email_hash` hook 위치 | **Cycle 4 makeplan** |
| OQ-3 | Cycle 7 webhook Model B dormant 코드 작성 여부 | Phase 2 Cycle 7 makeplan |
| OQ-4 | Cycle 9 archive smoke test 자동화 빈도 | Phase 2 Cycle 9 makeplan |
| OQ-5 | Cycle 4 CSRF 미들웨어 분기 (모바일 Bearer / admin strict Origin) | **Cycle 4/5 makeplan 통합** |
| W3 #6 | R4 envelope JSON wire-format Rails 호환 검증 | Phase 2 Cycle 9 |
| W3 #14 | Web Crypto byte-level workerd↔production 동일성 | Phase 2 staging deploy 후 |
| W3 #15 | parallel-key rotation 실 wrangler secret flow | Phase 2 Cycle 4 sub-cycle 또는 Cycle 9 drill |
| W3 #18 | OpenAPI Dart codegen 실 응답 호환 | Phase 2 staging API 회귀 |

### Major 핵심 보강 (사이클별 makeplan 입력 강화)

| Cycle | 추가 입력 (M source) |
|-------|------------------|
| 3 Services | M8 — Synthesis 018 § R2 Phase A-E 의사코드 (saga commit/compensate) + M6 "DO 미사용, D1 only" 강조 |
| 4 Auth+Sec | M5 — frontmatter `decisions: [3, 7]` 추가. M9 — 6 모듈 export interface 표: `betterauth(d1, kv) → BetterAuth 인스턴스`, `cf_access_verifier(jwks_resolver) → (jwt: string) => boolean` (DI 패턴), `encryption.envelope(plaintext, detKey) → {p, h:{iv, at}}`, `email_hash(email) → SHA-256 hex`, `session(kv) → SessionStore`, `key_rotation(K_n, K_n+1) → MigrationContext`. M11 — JWKS rotation fixture test (createLocalJWKSet 2개 dual-read) |
| 5 API | M2 — Dart codegen JAR build-time 예외 명시 (Brief 021 Anchor 2 외부 자원 정의 확장 인용) |
| 8 Compliance | M11 — 14세 미만 = 가입 차단 정책 (KYC 외부 미사용, 출생연도 기반 차단). 외부 KYC API 검토는 Phase 2 carryover |
| All | M12 — Brief 021 § 2.4 도구 버전 pin (wrangler ≥3.80, vitest-pool-workers ≥0.7, drizzle-kit ≥0.28, drizzle-orm ≥0.36, hono ≥4.6, better-auth ≥1.6.9, miniflare ≥3) 사이클별 makeplan 입력 강제 |

### DB 정합성 (S3) 처리

- M13 auto_run 정렬: Scope frontmatter `auto_run: false` 명시 (현 상태). 사용자가 `--run` 추가 호출 시 토글.
- M14 planned_cycles 갱신: DB 메타 7로 갱신 + Scope frontmatter `planned_cycles: 7` 명시 (적용).
- M (cycle 표기): `cycles[].cycle`이 "10_tail"/"99_retro" 문자열 표기 — DB는 INTEGER. read-time 정합성 OK이나 명문화: DB가 source of truth, Scope frontmatter는 표시용 (Mn8).

### 위임 (Scope 미수정)

| # | 발견 | 위임처 |
|---|------|--------|
| Mn5 | 사이클별 ideal_criteria_owned 표 | makeplan 시점 (각 사이클이 자신의 owned criteria를 plan 문서에 인라인) |
| Mn9 | DB had_interruption flag | 별도 작업 (DB schema 변경) |

## 참조

- Brief 021 (alignment anchor): [`021_Brief_conversion_phase1.md`](./021_Brief_conversion_phase1.md)
- Brief 001 (frozen parent): [`001_Brief_cf_workers_rebuild.md`](./001_Brief_cf_workers_rebuild.md)
- Scope 007 (parent scope, supersededs by 026 for Phase 1): [`007_Scope_cf_workers_rebuild.md`](./007_Scope_cf_workers_rebuild.md)
- Critique Synthesis: [`006_Critique_Synthesis.md`](./006_Critique_Synthesis.md) (Brief 001), [`025_Critique_Synthesis.md`](./025_Critique_Synthesis.md) (Brief 021)
- Research Synthesis: [`018_Synthesis_research_cycle.md`](./018_Synthesis_research_cycle.md)
- Plan 020 (Cycle 1 Foundation, M5 보강 필요): [`020_Plan_cycle1_foundation.md`](./020_Plan_cycle1_foundation.md)
- Pipeline DB: `tmp/007_cf_workers_rebuild_1c64.db` (재사용 — 새 init 금지)

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 25s | 43455 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 25s |
| Total Tokens | 43455 |
| Input Tokens | 6 |
| Output Tokens | 1821 |
| Cache Read | 0 |
| Cache Creation | 41628 |
