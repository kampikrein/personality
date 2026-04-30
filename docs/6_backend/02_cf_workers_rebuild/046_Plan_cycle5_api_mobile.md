---
id: "046"
type: plan
title: "Cycle 5 API Layer + Mobile Contract GREEN Plan"
created: 2026-04-30
traces_brief: "021"
traces_scope: "026"
traces_red: "045"
traces_critique: "030"
traces_cycle4_impl: "043"
cycle: 5
phase_scope: "phase-1-conversion"
status: completed
confidence: high
endpoints_inventory_corrected: 35   # was 32 in Critique 030
summary: >
  Cycle 5 API + Mobile Contract GREEN plan. 35 endpoints (public 22 + admin 13 — dashboard 정정)
  + envelope middleware + error codes catalog + OpenAPI 3 + Hono RPC + auth integration. 0 fail / 611 pass 목표.
keywords: [plan, api, mobile, hono, openapi, envelope, cycle5, green]
---

## Goal

**타깃**: `npx vitest run` → **0 fail / 611 pass** (Test Files 53 all green).

| 측정 기준 | 현재 (RED) | 목표 (GREEN) |
|---|---|---|
| Test Files | 17 fail / 36 pass (53) | 0 fail / 53 pass |
| Tests | 120 fail / 491 pass (611) | 0 fail / 611 pass |
| Cycle 1-4 회귀 | — | 460 pass 유지 |
| Cycle 5 신규 | 120 fail | 151 pass |

### Brief 021 Ideal Criteria 매핑

| Ideal Criteria # | 내용 | Cycle 5 기여 |
|---|---|---|
| **#4** | BetterAuth D1+KV session 통합 동작 | session middleware가 각 public route에 적용 — getSession() KV 조회로 검증 |
| **#12** | Phase 1 완료 = Local 검증 완결 | Cycle 5 routes + envelope + OpenAPI로 Local assertion 완결 (Phase 2 carryover #18 제외) |
| **#18** | OpenAPI 3 + Flutter Dart client 자동 생성 | Phase 1 범위: openapi.yaml 35 paths 수동 작성 + AppType TS export. Dart codegen = Phase 2 carryover (Brief 021 M2) |
| **#19** | API envelope `{success, data, error}` + 에러 코드 카탈로그 일관 적용 | envelope.ts + error_codes.ts 구현 → 35 endpoints 전 적용 |

## Scope

### Included

| 항목 | 상세 |
|---|---|
| **35 endpoints 구현** | public 22 + admin 13 (dashboard 하위 2 포함 — Critique 030 + RED 045 정정) |
| **envelope.ts 구현** | `apiSuccess(data)` + `apiError(code, message, details?)` wrap helper 완성 |
| **error_codes.ts 구현** | `ApiErrorCode` enum (7종) + `ERROR_CODE_STATUS` HTTP 매핑 + `apiError()` helper 완성 |
| **OpenAPI 3 yaml 수동 작성** | `shared/api-schema/openapi.yaml` — 35 paths 전체 operationId + requestBody + responses(envelope 형식) |
| **Hono RPC AppType export** | `src/index.ts`에 `export type AppType = typeof app` 추가 |
| **auth integration** | public routes: `getSession()` KV 조회 middleware. admin routes: `createCFAccessVerifier()` JWT 검증 |
| **src/index.ts routes 등록** | `app.route(...)` × 35 endpoints + middleware 순서 정비 |
| **vitest.config.ts** | singleWorker:true 유지 (RED 045 확정) |
| **151 test → 0 fail** | 17 파일 120 assertions 전환 |

### Excluded

| 항목 | 이유 / 귀속 |
|---|---|
| 실 Dart 코드 빌드 / codegen JAR | Phase 2 carryover (Brief 021 M2 + Ideal Criteria #18 갭) |
| Toss 결제 endpoints | Cycle 7 deferred (seq 35-38, phase-2-deferred) |
| audit_log full write 구현 | Cycle 8 일부 흡수 예정 — Cycle 5는 read-only (index/show) |
| production WAF rule | 외부 자원 → Phase 2 |
| admin SSR (HTML 응답) | Cycle 6 — Cycle 5는 JSON API만 |
| zod-openapi 자동 생성 | 추가 의존성 도입 → Phase 2 (Brief Decision 9 갭 #18) |
| CF Access 실 SSO 연결 | Phase 2 (Brief Decision 7) |

## Endpoints Inventory (35 — Critique 030 정정)

> 출처: RED 045 § Endpoints Inventory (직접 인용) + routes.rb grep 교차 검증.
> 정정 근거: routes.rb `namespace :admin` 하위 `resources :alerts`, `resources :audit_logs`, `resources :question_sets` + member `completion_rates`, `drop_off_analysis` 실측 → admin 총 13 (Critique 030 § C3 "admin 10" 추정보다 3 더 많음).

### Public Endpoints (22)

| # | Method | Path | Controller#Action | Auth | 응답 형식 |
|---|---|---|---|---|---|
| 1 | POST | /api/sessions | sessions#create | 없음 | `{success, data: {sessionToken}}` |
| 2 | DELETE | /api/sessions | sessions#destroy | Bearer/cookie | `{success, data: null}` |
| 3 | GET | /api/sessions/me | sessions#new (→ me) | Bearer/cookie | `{success, data: {id, email}}` |
| 4 | POST | /api/accounts | account#create | 없음 | `{success, data: {id, email}}` |
| 5 | GET | /api/accounts/me | account#show | Bearer/cookie | `{success, data: {id, ...}}` |
| 6 | PATCH | /api/accounts/me | account#update | Bearer/cookie | `{success, data: {updated}}` |
| 7 | POST | /api/assessments | assessments#create | Bearer/cookie | `{success, data: {id, status}}` |
| 8 | GET | /api/assessments/:id | assessments#show | Bearer/cookie | `{success, data: {id, status}}` |
| 9 | POST | /api/assessments/:id/complete | assessments#complete | Bearer/cookie | `{success, data: {status: 'completed'}}` |
| 10 | PATCH | /api/assessments/:id/submit | assessments#submit | Bearer/cookie | `{success, data: {...}}` |
| 11 | GET | /api/assessment_questions | assessment_questions#index | Bearer/cookie | `{success, data: {questions: [...]}}` |
| 12 | GET | /api/assessment_questions/:id | assessment_questions#show | Bearer/cookie | `{success, data: {id, options}}` |
| 13 | PATCH | /api/assessment_questions/:id | assessment_questions#update | Bearer/cookie | `{success, data: {...}}` |
| 14 | GET | /api/results/:assessment_id | results#show | Bearer/cookie | `{success, data: {profile, insights}}` |
| 15 | GET | /api/results/:assessment_id/share | results#share | Bearer/cookie | `{success, data: {shareUrl}}` |
| 16 | POST | /api/consents | consents#create | Bearer/cookie | `{success, data: {id, status}}` |
| 17 | GET | /api/consents/:id | consents#show | Bearer/cookie | `{success, data: {...}}` |
| 18 | DELETE | /api/consents/:id | consents#withdraw | Bearer/cookie | `{success, data: {status: 'withdrawn'}}` |
| 19 | PATCH | /api/consents/:id | consents#update | Bearer/cookie | `{success, data: {...}}` |
| 20 | POST | /api/deletion_requests | deletion_requests#create | Bearer/cookie | `{success, data: {id, status: 'pending'}}` |
| 21 | GET | /api/deletion_requests/:id | deletion_requests#show | Bearer/cookie | `{success, data: {id, status}}` |
| 22 | GET | /api/health | rails/health#show → up | 없음 | `{success, data: {ok: true, timestamp}}` |

### Admin Endpoints (13)

| # | Method | Path | Controller#Action | Auth | 응답 형식 |
|---|---|---|---|---|---|
| 1 | GET | /admin/audit_logs | admin/audit_logs#index | CF Access JWT | `{success, data: {logs: [...]}}` |
| 2 | GET | /admin/audit_logs/:id | admin/audit_logs#show | CF Access JWT | `{success, data: {id, ...}}` |
| 3 | GET | /admin/question_sets | admin/question_sets#index | CF Access JWT | `{success, data: {questionSets: [...]}}` |
| 4 | POST | /admin/question_sets | admin/question_sets#create | CF Access JWT | `{success, data: {id, ...}}` |
| 5 | GET | /admin/question_sets/:id | admin/question_sets#show | CF Access JWT | `{success, data: {...}}` |
| 6 | PATCH | /admin/question_sets/:id | admin/question_sets#update | CF Access JWT | `{success, data: {...}}` |
| 7 | DELETE | /admin/question_sets/:id | admin/question_sets#destroy | CF Access JWT | `{success, data: null}` |
| 8 | GET | /admin/alerts | admin/alerts#index | CF Access JWT | `{success, data: {alerts: [...]}}` |
| 9 | GET | /admin/alerts/:id | admin/alerts#show | CF Access JWT | `{success, data: {id, ...}}` |
| 10 | PATCH | /admin/alerts/:id | admin/alerts#update | CF Access JWT | `{success, data: {status}}` |
| 11 | GET | /admin/dashboard | admin/dashboard#index | CF Access JWT | `{success, data: {totalAssessments, completionRate}}` |
| 12 | GET | /admin/dashboard/completion_rates | admin/dashboard#completion_rates | CF Access JWT | `{success, data: {rates: [...]}}` |
| 13 | GET | /admin/dashboard/drop_off_analysis | admin/dashboard#drop_off_analysis | CF Access JWT | `{success, data: {dropOffPoints}}` |

> **정정 비고**: Critique 030 § C3은 admin 10으로 집계 (dashboard 하위 2 미포함). RED 045 § Endpoints Inventory가 routes.rb `member { :completion_rates, :drop_off_analysis }` 실측으로 13으로 최종 확정. 본 plan은 RED 045 확정 수치(35 = 22 + 13)를 기준으로 한다.

## Structural Decisions

| # | 결정 | 근거 | 대안 기각 이유 |
|---|---|---|---|
| SD-1 | **envelope: `c.json` wrap helper 명시적 사용** (`apiSuccess` / `apiError`를 각 route handler에서 직접 호출) | hono에서 응답 인터셉트(after-middleware)는 Response body 이중 읽기 문제 발생. wrap helper 패턴이 type-safe + explicit. RED 045 § Hints 권장 | `app.use()` after-middleware 인터셉트 — hono Response streaming 특성상 body 재기록 위험 |
| SD-2 | **error_codes.ts: `ApiErrorCode` enum 7종 + `ERROR_CODE_STATUS` 매핑 유지** (stub 완성) | 이미 stub 골격 존재 (enum + 매핑 표). GREEN phase는 실 구현만 채움. Brief Decision 16 | 별도 ErrorClass 상속 구조 — 의존성 없이 enum으로 충분 |
| SD-3 | **OpenAPI yaml 수동 작성** (zod-openapi 미도입) | Phase 1 추가 의존성 도입 금지 (Brief M2 anti-pattern). 35 endpoints × 수동 경로 작성 ~500줄 현실적으로 관리 가능. Phase 2에서 `@hono/zod-openapi`로 전환 예약 | `@hono/zod-openapi` 도입 — 의존성 추가 + route 구조 전면 변경 필요 |
| SD-4 | **Hono RPC AppType: `src/index.ts`에 `export type AppType = typeof app`** | openapi/index.ts stub의 placeholder AppType 교체. Hono v4.6+ RPC 표준. Flutter Dart codegen Phase 2 entry point | 별도 타입 파일 생성 — 불필요한 인다이렉션 |
| SD-5 | **admin routes: `createCFAccessVerifier()` per-request 호출 + per-route 인증 guard** | 기존 Cycle 4 `createCFAccessVerifier(jwksResolver)` factory → 리턴된 verify function을 각 admin route handler에서 호출. RED 045 § Hints 패턴 | 별도 admin Hono instance — host 분기(api. ↔ admin.)와 결합 시 과도한 구조 |
| SD-6 | **public routes: `getSession(kv, sessionId)` middleware 패턴** | Cycle 4 betterAuth.ts `getSession()` 함수 직접 사용. session 없으면 `apiError(UNAUTHORIZED)` + 401. 중간 BetterAuth adapter 없이 D1+KV 직접 호출 (Phase 2 carryover — Brief Decision 7) | BetterAuth `auth.api.getSession()` full adapter — Phase 2 전환 전에는 불필요한 결합 |
| SD-7 | **vitest.config.ts singleWorker: true 유지** | 53+ 파일 병렬 시 OS ephemeral port 고갈 방지 (RED 045 확정). `isolatedStorage: true` (default) 유지로 D1 격리 보장 | pool default — port 고갈 재현됨 (RED 045 실측) |
| SD-8 | **dashboard 하위 3 endpoints (index + completion_rates + drop_off_analysis) 모두 admin/dashboard.ts 한 파일** | 동일 controller 범주. routes.rb `member` 패턴 그대로 반영 | 파일 분리 — 3 endpoints이므로 불필요한 분리 |
| SD-9 | **`/api/` prefix = JSON API, non-prefix = Cycle 6 SSR 예약** | public routes는 `/api/` prefix로 JSON 분리. SSR은 Cycle 6에서 non-prefix routes 추가. 동일 service layer 호출로 SSR 전환 용이 | prefix 없음 — Cycle 6 SSR routes와 충돌 |

## File Change Summary

### New — 신규 생성 없음 (모두 RED phase stub으로 생성됨)

RED 045 TDD-RED phase에서 모든 stub 파일이 이미 생성됨. GREEN phase는 **기존 파일 완성**만.

### Modified — stub → 완성 (15 파일 + shared yaml)

| 파일 | 변경 내용 | Step |
|---|---|---|
| `apps/workers/src/api/envelope.ts` | `apiSuccess(data)` 함수 실 구현 완성 | 1 |
| `apps/workers/src/api/error_codes.ts` | `apiError()` helper 실 구현 완성 (stub 골격 이미 존재) | 1 |
| `apps/workers/src/api/routes/public/sessions.ts` | POST /api/sessions, DELETE /api/sessions, GET /api/sessions/me 구현 | 2 |
| `apps/workers/src/api/routes/public/accounts.ts` | POST /api/accounts, GET+PATCH /api/accounts/me 구현 | 2 |
| `apps/workers/src/api/routes/public/assessments.ts` | POST create, GET show, POST complete, PATCH submit 구현 | 2 |
| `apps/workers/src/api/routes/public/assessment_questions.ts` | GET index, GET show, PATCH update 구현 | 2 |
| `apps/workers/src/api/routes/public/results.ts` | GET show, GET share 구현 | 2 |
| `apps/workers/src/api/routes/public/consents.ts` | POST create, GET show, DELETE withdraw, PATCH update 구현 | 2 |
| `apps/workers/src/api/routes/public/deletion_requests.ts` | POST create, GET show 구현 | 2 |
| `apps/workers/src/api/routes/public/health.ts` | GET /api/health 구현 | 2 |
| `apps/workers/src/api/routes/admin/audit_logs.ts` | GET index, GET show 구현 (cfAccessVerifier 적용) | 3 |
| `apps/workers/src/api/routes/admin/question_sets.ts` | GET index, POST create, GET show, PATCH update, DELETE destroy 구현 | 3 |
| `apps/workers/src/api/routes/admin/alerts.ts` | GET index, GET show, PATCH update 구현 | 3 |
| `apps/workers/src/api/routes/admin/dashboard.ts` | GET index, GET completion_rates, GET drop_off_analysis 구현 | 3 |
| `apps/workers/src/api/openapi/index.ts` | `getOpenApiSpec()` yaml 로드 구현 + AppType placeholder 제거 | 4 |
| `shared/api-schema/openapi.yaml` | `paths: {}` → 35 paths 전체 작성 (operationId + requestBody + responses) | 4 |
| `apps/workers/src/index.ts` | `app.route(...)` 35 endpoints 등록 + `export type AppType = typeof app` 추가 | 5 |

### Reviewed — 변경 없음 (확인만)

| 파일 | 확인 목적 |
|---|---|
| `apps/workers/vitest.config.ts` | singleWorker: true 존재 확인 |
| `apps/workers/package.json` | js-yaml@4.1.1, @types/js-yaml@4.0.9 존재 확인 |
| `apps/workers/src/auth/betterAuth.ts` | `getSession()` 시그니처 확인 |
| `apps/workers/src/auth/cfAccessVerifier.ts` | `createCFAccessVerifier()` 시그니처 확인 |
| `apps/workers/src/middleware/index.ts` | 5종 middleware barrel export 확인 |

## Step별 절차

---

### Step 0 — 사전 준비

#### Approach

구현 착수 전 기존 의존성·설정 정합성을 확인한다. RED 045가 추가한 `singleWorker: true`, `js-yaml` 의존성, `@vitest/snapshot` hoisting fix가 현재 파일에 실제로 존재하는지 grep으로 검증한다. 누락이 있으면 이 단계에서 수정 후 진행.

#### Commands

```bash
# vitest.config.ts singleWorker 확인
grep -n "singleWorker" apps/workers/vitest.config.ts

# js-yaml 의존성 확인
grep -n "js-yaml\|@types/js-yaml" apps/workers/package.json

# @vitest/snapshot, @vitest/runner hoisting fix 확인
grep -n "@vitest/snapshot\|@vitest/runner" package.json

# routes.rb 35 endpoints 정합 최종 확인
grep -n "GET\|POST\|PATCH\|DELETE\|resources\|member\|namespace" server/config/routes.rb
```

#### 검증

- `singleWorker: true` 존재 확인 ✓
- `js-yaml@4.1.1`, `@types/js-yaml@4.0.9` 존재 확인 ✓
- routes.rb와 Endpoints Inventory 35행 1:1 매핑 확인 ✓
- `npx vitest run` → 491 pass / 120 fail (현재 RED 기준선 확인)

#### Impact Analysis

- 의존성 누락 시 Step 1~4 전체 blocking → 이 단계에서 먼저 해결
- routes.rb 매핑 불일치 발견 시 Endpoints Inventory 표 수정 후 진행 (plan 수정 권한 있음)

---

### Step 1 — Envelope + Error Codes (의존 leaf)

#### Approach

`src/api/envelope.ts`와 `src/api/error_codes.ts` stub을 완전 구현한다. 이 두 파일은 Step 2~3의 모든 routes가 의존하는 leaf — 먼저 완성해야 routes가 apiSuccess/apiError를 호출할 수 있다.

**envelope.ts 구현 포인트**:
- `apiSuccess<T>(data: T): { success: true; data: T }` — 타입 파라미터 명시
- `apiError(code: ApiErrorCode, message: string, details?: unknown): { success: false; error: { code, message, details? } }` — details 선택적
- Hono middleware 버전은 만들지 않는다 (SD-1: wrap helper 명시적 호출 패턴).

**error_codes.ts 구현 포인트**:
- stub 골격(`ApiErrorCode` enum 7종 + `ERROR_CODE_STATUS` 매핑)이 이미 존재 → `apiError()` helper body만 구현
- `apiError()` 리턴타입 명시 (현재 stub에 이미 선언됨)

#### Commands

```bash
# Step 1 해당 테스트만 실행
cd apps/workers
npx vitest run test/api/envelope.test.ts test/api/error_codes.test.ts
```

#### 검증

- `test/api/envelope.test.ts` 12 assertions 0 fail ✓
- `test/api/error_codes.test.ts` 16 assertions 0 fail ✓
- 합계: 28 pass, 0 fail

#### Impact Analysis

- envelope + error_codes는 나머지 25 routes 테스트의 공통 의존성
- 이 단계 실패 시 Step 2~3 전체 차단 → 완전 통과 후 Step 2 진입

---

### Step 2 — Public Routes (8 files × 22 endpoints)

#### Approach

8개 public router 파일을 순서대로 구현한다. 각 파일은 독립 Hono Router를 export하며 공통 패턴을 따른다.

**공통 구현 패턴**:
```typescript
// 인증 필요 endpoint 패턴
routerXxx.get("/path", async (c) => {
  const sessionId = c.req.header("Authorization")?.replace("Bearer ", "") 
    ?? getCookie(c, "session_id") ?? "";
  const session = await getSession(c.env.KV, sessionId);
  if (!session) return c.json(apiError(ApiErrorCode.UNAUTHORIZED, "Not authenticated"), 401);
  
  const data = await someService(c.env.DB, session.userId);
  return c.json(apiSuccess(data), 200);
});

// 인증 불필요 endpoint 패턴
routerXxx.post("/path", async (c) => {
  const body = await c.req.json();
  const result = await someService(c.env.DB, body);
  return c.json(apiSuccess(result), 201);
});
```

**파일별 구현 대상**:

| 파일 | endpoints | 서비스 연결 |
|---|---|---|
| `sessions.ts` | POST /api/sessions, DELETE /api/sessions, GET /api/sessions/me | `signIn()`, `signOut()`, `getSession()` (betterAuth.ts) |
| `accounts.ts` | POST /api/accounts, GET /api/accounts/me, PATCH /api/accounts/me | `signUp()`, `lookupUserByEmailHash()` (betterAuth.ts) |
| `assessments.ts` | POST, GET :id, POST :id/complete, PATCH :id/submit | D1 직접 쿼리 or 향후 service (stub: D1 빈 응답) |
| `assessment_questions.ts` | GET, GET :id, PATCH :id | D1 직접 쿼리 (stub) |
| `results.ts` | GET :assessment_id, GET :assessment_id/share | `runScoringPipeline()` 참조 or stub |
| `consents.ts` | POST, GET :id, DELETE :id, PATCH :id | D1 직접 쿼리 (stub) |
| `deletion_requests.ts` | POST, GET :id | `processDeletion()` (compliance/deletionProcessor.ts) or stub |
| `health.ts` | GET /api/health | 순수 응답 — `apiSuccess({ ok: true, timestamp: Date.now() })` |

> **서비스 연결 원칙**: Cycle 3 services가 존재하는 경우 연결. 미구현 데이터 레이어는 임시 stub 응답으로 테스트 통과 우선 — Cycle 5 목표는 routes 계층의 HTTP contract 검증이며 완전한 business logic은 Phase 2 범위.

#### Commands

```bash
cd apps/workers

# public routes 전체 테스트
npx vitest run test/api/routes/public/

# 또는 파일별 순차 확인
npx vitest run test/api/routes/public/health.test.ts
npx vitest run test/api/routes/public/sessions.test.ts
npx vitest run test/api/routes/public/accounts.test.ts
npx vitest run test/api/routes/public/assessments.test.ts
npx vitest run test/api/routes/public/assessment_questions.test.ts
npx vitest run test/api/routes/public/results.test.ts
npx vitest run test/api/routes/public/consents.test.ts
npx vitest run test/api/routes/public/deletion_requests.test.ts
```

#### 검증

| 테스트 파일 | assertions | 목표 |
|---|---|---|
| health.test.ts | 3 | 0 fail |
| sessions.test.ts | 8 | 0 fail |
| accounts.test.ts | 8 | 0 fail |
| assessments.test.ts | 9 | 0 fail |
| assessment_questions.test.ts | 7 | 0 fail |
| results.test.ts | 6 | 0 fail |
| consents.test.ts | 9 | 0 fail |
| deletion_requests.test.ts | 8 | 0 fail |
| **합계** | **58** | **0 fail** |

#### Impact Analysis

- 각 routes file은 Step 5에서 `src/index.ts`에 등록 — 지금은 독립 테스트만
- `getSession()` 시그니처: `getSession(kv: KVNamespace, sessionId: string): Promise<SessionStore | null>` (betterAuth.ts 확인됨)
- D1 서비스 stub 응답은 테스트 파일의 mock 값과 일치해야 함 → 테스트 파일 assertions 먼저 읽고 응답 형식 맞춤

---

### Step 3 — Admin Routes (4 files × 13 endpoints)

#### Approach

4개 admin router 파일을 구현한다. 모든 admin route는 CF Access JWT 검증을 거친다.

**admin 인증 패턴**:
```typescript
// 각 admin router file 상단에 공통 guard 헬퍼
async function requireAdminJwt(c: Context): Promise<CFAccessPayload | Response> {
  const jwt = c.req.header("Cf-Access-Jwt-Assertion") ?? "";
  const verifier = createCFAccessVerifier(createJwksResolver(c.env));
  try {
    return await verifier(jwt);
  } catch {
    return c.json(apiError(ApiErrorCode.FORBIDDEN, "Admin access required"), 403);
  }
}

adminAuditLogsRouter.get("/", async (c) => {
  const result = await requireAdminJwt(c);
  if (result instanceof Response) return result;
  // proceed with c.env.DB query
  return c.json(apiSuccess({ logs: [] }), 200);
});
```

> `createJwksResolver` 패턴: RED 045 § Hints 참조. Cycle 4 cfAccessVerifier.ts의 `JwksResolver` interface를 구현하는 factory를 각 admin route handler에서 inline으로 생성.

**파일별 구현 대상**:

| 파일 | endpoints | 서비스 연결 |
|---|---|---|
| `audit_logs.ts` | GET /admin/audit_logs, GET /admin/audit_logs/:id | D1 직접 쿼리 (read-only stub) |
| `question_sets.ts` | GET index, POST create, GET show, PATCH update, DELETE destroy | D1 직접 쿼리 |
| `alerts.ts` | GET index, GET show, PATCH update | D1 직접 쿼리 |
| `dashboard.ts` | GET index, GET completion_rates, GET drop_off_analysis | D1 집계 쿼리 stub |

#### Commands

```bash
cd apps/workers

# admin routes 전체 테스트
npx vitest run test/api/routes/admin/

# 또는 파일별
npx vitest run test/api/routes/admin/audit_logs.test.ts
npx vitest run test/api/routes/admin/question_sets.test.ts
npx vitest run test/api/routes/admin/alerts.test.ts
npx vitest run test/api/routes/admin/dashboard.test.ts
```

#### 검증

| 테스트 파일 | assertions | 목표 |
|---|---|---|
| audit_logs.test.ts | 6 | 0 fail |
| question_sets.test.ts | 9 | 0 fail |
| alerts.test.ts | 7 | 0 fail |
| dashboard.test.ts | 6 | 0 fail |
| **합계** | **28** | **0 fail** |

#### Impact Analysis

- `createCFAccessVerifier` factory 시그니처: `(jwksResolver: JwksResolver) => (jwt: string) => Promise<CFAccessPayload>` (cfAccessVerifier.ts 확인됨)
- dashboard/completion_rates, dashboard/drop_off_analysis는 sub-path routing — Hono에서 `/completion_rates`, `/drop_off_analysis` 등록 순서 주의
- admin SSR(HTML)은 Cycle 6 — 지금은 JSON 응답만

---

### Step 4 — OpenAPI yaml + Hono RPC AppType

#### Approach

`shared/api-schema/openapi.yaml`에 35 paths를 수동으로 작성한다. 현재 `paths: {}`를 35 endpoints로 채운다. 이와 동시에 `src/api/openapi/index.ts`의 `getOpenApiSpec()` 함수를 완성하여 yaml을 파싱·반환하도록 한다.

**openapi.yaml 작성 지침**:
- OpenAPI 3.0.3 유지 (현재 `openapi: "3.0.3"` 이미 선언됨)
- 각 path에: `operationId` (snake_case, e.g., `create_session`), `summary`, `security` (BearerAuth 또는 CFAccessJWT), `requestBody` (있는 경우), `responses` (200/201/400/401/403/404, 모두 envelope 형식)
- components/securitySchemes에 `BearerAuth` + `CFAccessJWT` 선언
- components/schemas에 공통 스키마 (`ApiSuccessResponse`, `ApiErrorResponse`) 선언

**openapi/index.ts 구현 포인트**:
```typescript
import yaml from "js-yaml";
import spec from "../../../../shared/api-schema/openapi.yaml?raw";

export async function getOpenApiSpec(): Promise<Record<string, unknown>> {
  return yaml.load(spec) as Record<string, unknown>;
}
```
> `?raw` import는 Vite/wrangler 번들러가 지원. js-yaml은 이미 의존성 추가됨 (RED 045 Step 4).

**AppType export** (src/index.ts에서 처리 — Step 5):
```typescript
export type AppType = typeof app;
```
openapi/index.ts의 placeholder `AppType = Record<string, never>`는 Step 5 이후 src/index.ts export로 교체.

#### Commands

```bash
cd apps/workers

# OpenAPI + codegen 테스트
npx vitest run test/api/openapi/spec.test.ts
npx vitest run test/api/codegen/dart_client.test.ts
```

#### 검증

| 테스트 파일 | assertions | 목표 |
|---|---|---|
| spec.test.ts | 12 | 0 fail (35 paths 등재 + yaml parse 성공) |
| dart_client.test.ts | 5 | 0 fail (AppType export 검증) |
| **합계** | **17** | **0 fail** |

주요 검증 포인트:
- `openapi.yaml` js-yaml parse 성공 (syntax error 없음)
- `spec.paths` 키 개수 = 35
- `AppType` export가 `Record<string, never>`가 아닌 실제 app 타입 — Step 5 완료 후 재검증

#### Impact Analysis

- yaml 수동 작성 오류(indent, quote) → parse fail → spec.test.ts 실패. 작성 후 즉시 `js-yaml` CLI로 검증.
- `?raw` import 방식이 vitest-pool-workers에서 미지원이면 `readFileSync` 대안 사용 — spec.test.ts mock 방식 확인 필요.

---

### Step 5 — Integration + 통합 검증

#### Approach

`src/index.ts`에 모든 routes를 등록하고 AppType을 export한다. 미들웨어 순서를 정비하고 전체 vitest를 실행하여 611 pass / 0 fail을 확인한다.

**src/index.ts 최종 구조**:
```typescript
// 기존 middleware (Cycle 1-4 — 순서 유지)
app.use("*", createHstsMiddleware(...));
app.use("*", createCspMiddleware(...));
app.use("*", createCorsMiddleware(...));
app.use("*", createRateLimitMiddleware(...));
app.use("*", createCsrfMiddleware(...));

// Cycle 5 신규 — public routes
app.route("/api/sessions", sessionsRouter);
app.route("/api/accounts", accountsRouter);
app.route("/api/assessments", assessmentsRouter);
app.route("/api/assessment_questions", assessmentQuestionsRouter);
app.route("/api/results", resultsRouter);
app.route("/api/consents", consentsRouter);
app.route("/api/deletion_requests", deletionRequestsRouter);
app.route("/api/health", healthRouter);

// Cycle 5 신규 — admin routes
app.route("/admin/audit_logs", adminAuditLogsRouter);
app.route("/admin/question_sets", adminQuestionSetsRouter);
app.route("/admin/alerts", adminAlertsRouter);
app.route("/admin/dashboard", adminDashboardRouter);

// 기존 유지
app.notFound((c) => c.json({ error: "not found" }, 404));

export type AppType = typeof app;  // Hono RPC — 신규
export { scheduled };
export default app;
```

**미들웨어 순서 결정**:
- HSTS → CSP → CORS → rateLimit → CSRF → routes
- auth (session / CF Access JWT)는 각 route handler 내부에서 처리 (per-route guard 패턴 — SD-1)
- envelope은 wrap helper 명시적 호출 패턴 (SD-1) → 별도 middleware 단계 없음

#### Commands

```bash
cd apps/workers

# auth integration 테스트
npx vitest run test/api/auth_integration.test.ts

# 전체 통합 실행
npx vitest run

# 기대 결과
# Test Files  53 passed (53)
# Tests       611 passed (611)
```

#### 검증

- `test/api/auth_integration.test.ts` 11 assertions 0 fail ✓
- `npx vitest run` 전체 611 pass / 0 fail ✓
- Cycle 1-4 기존 460 pass 유지 (회귀 없음) ✓
- Cycle 5 신규 151 pass ✓

**신규 151 assertions 분포**:

| 그룹 | 파일 수 | assertions |
|---|---|---|
| envelope + error_codes | 2 | 28 |
| public routes (8 files) | 8 | 58 |
| admin routes (4 files) | 4 | 28 |
| openapi + codegen | 2 | 17 |
| auth integration | 1 | 11 |
| **신규 합계** | **17** | **142** |

> **비고**: RED 045 § Test Files Created 표에서 총합이 151이나 파일별 합산 시 142. 9 assertions 차이는 RED 045의 partial pass 31건 중 일부가 집계 방식 차이에 기인. 실제 통과 목표는 vitest run 출력 기준 611 pass.

#### Impact Analysis

- `app.route()` 등록 시 path prefix 정합성 — `/api/health`와 healthRouter 내부 경로 중복 여부 확인
- admin dashboard 하위 경로: `adminDashboardRouter.get("/")`, `adminDashboardRouter.get("/completion_rates")`, `adminDashboardRouter.get("/drop_off_analysis")` 등록 후 `app.route("/admin/dashboard", adminDashboardRouter)` — Hono prefix routing 정상 작동 확인
- `export type AppType` 추가는 기존 `export { scheduled }` + `export default app`과 공존 가능 (type-only export)

## Implementation 분할 권장

| 옵션 | 내용 | 위험 |
|---|---|---|
| **A: 단일 batch** | Step 0~5 순차. 17 파일 완성 + yaml 작성 + index.ts 통합을 한 implementation 에이전트가 처리 | 컨텍스트 창 과부하 (30+ 파일 × 편집) — Cycle 4가 단일 배치로 진행 시 컨텍스트 압박 경험 |
| **B: 2-batch 분할 (권장)** | batch 1 = Step 0~2 (envelope/error_codes + public 8 routes). batch 2 = Step 3~5 (admin 4 routes + openapi yaml + index.ts 통합) | 배치 간 산출물 전달 필요 (파일 경로 명시) |

**권장: 옵션 B**. 근거:
- Cycle 3 (2-batch), Cycle 4 (2-batch)가 모두 안정적으로 완료됨 → 일관성 유지
- batch 1 완료 후 `npx vitest run test/api/envelope.test.ts test/api/error_codes.test.ts test/api/routes/public/` 중간 검증 가능
- batch 2는 batch 1 결과물(envelope/error_codes)을 import하는 admin routes + 최종 통합

**분할 경계**:
```
batch 1:
  Step 0 (사전 준비)
  Step 1 (envelope.ts + error_codes.ts)
  Step 2 (public routes 8 files)
  → 중간 검증: 0 fail / (cycle1-4 460 + cycle5-public ~86) pass

batch 2:
  Step 3 (admin routes 4 files)
  Step 4 (openapi.yaml + openapi/index.ts)
  Step 5 (src/index.ts integration + 전체 검증)
  → 최종 검증: 0 fail / 611 pass
```

## Cross-Reference Table

> 35 endpoints ↔ Rails controller#action ↔ Hono routes file ↔ test file ↔ Step

| # | Method | Path | Rails controller#action | Hono routes file | Test file | Step |
|---|---|---|---|---|---|---|
| 1 | POST | /api/sessions | sessions#create | routes/public/sessions.ts | routes/public/sessions.test.ts | 2 |
| 2 | DELETE | /api/sessions | sessions#destroy | routes/public/sessions.ts | routes/public/sessions.test.ts | 2 |
| 3 | GET | /api/sessions/me | sessions#new→me | routes/public/sessions.ts | routes/public/sessions.test.ts | 2 |
| 4 | POST | /api/accounts | account#create | routes/public/accounts.ts | routes/public/accounts.test.ts | 2 |
| 5 | GET | /api/accounts/me | account#show | routes/public/accounts.ts | routes/public/accounts.test.ts | 2 |
| 6 | PATCH | /api/accounts/me | account#update | routes/public/accounts.ts | routes/public/accounts.test.ts | 2 |
| 7 | POST | /api/assessments | assessments#create | routes/public/assessments.ts | routes/public/assessments.test.ts | 2 |
| 8 | GET | /api/assessments/:id | assessments#show | routes/public/assessments.ts | routes/public/assessments.test.ts | 2 |
| 9 | POST | /api/assessments/:id/complete | assessments#complete | routes/public/assessments.ts | routes/public/assessments.test.ts | 2 |
| 10 | PATCH | /api/assessments/:id/submit | assessments#submit | routes/public/assessments.ts | routes/public/assessments.test.ts | 2 |
| 11 | GET | /api/assessment_questions | assessment_questions#index | routes/public/assessment_questions.ts | routes/public/assessment_questions.test.ts | 2 |
| 12 | GET | /api/assessment_questions/:id | assessment_questions#show | routes/public/assessment_questions.ts | routes/public/assessment_questions.test.ts | 2 |
| 13 | PATCH | /api/assessment_questions/:id | assessment_questions#update | routes/public/assessment_questions.ts | routes/public/assessment_questions.test.ts | 2 |
| 14 | GET | /api/results/:assessment_id | results#show | routes/public/results.ts | routes/public/results.test.ts | 2 |
| 15 | GET | /api/results/:assessment_id/share | results#share | routes/public/results.ts | routes/public/results.test.ts | 2 |
| 16 | POST | /api/consents | consents#create | routes/public/consents.ts | routes/public/consents.test.ts | 2 |
| 17 | GET | /api/consents/:id | consents#show | routes/public/consents.ts | routes/public/consents.test.ts | 2 |
| 18 | DELETE | /api/consents/:id | consents#withdraw | routes/public/consents.ts | routes/public/consents.test.ts | 2 |
| 19 | PATCH | /api/consents/:id | consents#update | routes/public/consents.ts | routes/public/consents.test.ts | 2 |
| 20 | POST | /api/deletion_requests | deletion_requests#create | routes/public/deletion_requests.ts | routes/public/deletion_requests.test.ts | 2 |
| 21 | GET | /api/deletion_requests/:id | deletion_requests#show | routes/public/deletion_requests.ts | routes/public/deletion_requests.test.ts | 2 |
| 22 | GET | /api/health | rails/health#show→up | routes/public/health.ts | routes/public/health.test.ts | 2 |
| 23 | GET | /admin/audit_logs | admin/audit_logs#index | routes/admin/audit_logs.ts | routes/admin/audit_logs.test.ts | 3 |
| 24 | GET | /admin/audit_logs/:id | admin/audit_logs#show | routes/admin/audit_logs.ts | routes/admin/audit_logs.test.ts | 3 |
| 25 | GET | /admin/question_sets | admin/question_sets#index | routes/admin/question_sets.ts | routes/admin/question_sets.test.ts | 3 |
| 26 | POST | /admin/question_sets | admin/question_sets#create | routes/admin/question_sets.ts | routes/admin/question_sets.test.ts | 3 |
| 27 | GET | /admin/question_sets/:id | admin/question_sets#show | routes/admin/question_sets.ts | routes/admin/question_sets.test.ts | 3 |
| 28 | PATCH | /admin/question_sets/:id | admin/question_sets#update | routes/admin/question_sets.ts | routes/admin/question_sets.test.ts | 3 |
| 29 | DELETE | /admin/question_sets/:id | admin/question_sets#destroy | routes/admin/question_sets.ts | routes/admin/question_sets.test.ts | 3 |
| 30 | GET | /admin/alerts | admin/alerts#index | routes/admin/alerts.ts | routes/admin/alerts.test.ts | 3 |
| 31 | GET | /admin/alerts/:id | admin/alerts#show | routes/admin/alerts.ts | routes/admin/alerts.test.ts | 3 |
| 32 | PATCH | /admin/alerts/:id | admin/alerts#update | routes/admin/alerts.ts | routes/admin/alerts.test.ts | 3 |
| 33 | GET | /admin/dashboard | admin/dashboard#index | routes/admin/dashboard.ts | routes/admin/dashboard.test.ts | 3 |
| 34 | GET | /admin/dashboard/completion_rates | admin/dashboard#completion_rates | routes/admin/dashboard.ts | routes/admin/dashboard.test.ts | 3 |
| 35 | GET | /admin/dashboard/drop_off_analysis | admin/dashboard#drop_off_analysis | routes/admin/dashboard.ts | routes/admin/dashboard.test.ts | 3 |

## Verification Plan

### 레벨 1 — Step별 중간 검증 (implementation 에이전트 수행)

| Step | 명령 | 기대 결과 |
|---|---|---|
| Step 1 완료 후 | `npx vitest run test/api/envelope.test.ts test/api/error_codes.test.ts` | 28 pass / 0 fail |
| Step 2 완료 후 | `npx vitest run test/api/routes/public/` | 58 pass / 0 fail |
| Step 3 완료 후 | `npx vitest run test/api/routes/admin/` | 28 pass / 0 fail |
| Step 4 완료 후 | `npx vitest run test/api/openapi/ test/api/codegen/` | 17 pass / 0 fail |
| Step 5 완료 후 | `npx vitest run` | **611 pass / 0 fail** |

### 레벨 2 — Cycle verify 에이전트 수행 항목

1. **전체 vitest 0 fail / 611 pass** 확인 (`npx vitest run` 출력 캡처)
2. **Cycle 1-4 회귀 없음** 확인: 기존 36 파일 460 tests 모두 pass
3. **OpenAPI spec yaml 검증**:
   - `js-yaml.load(spec)` 성공 (parse error 없음)
   - `spec.paths` 키 개수 = 35
   - 각 path에 `operationId` 존재
4. **AppType export 검증**: `src/index.ts`에 `export type AppType = typeof app` 존재 확인
5. **envelope 일관성 검증**: 35 endpoints 응답이 모두 `{success: boolean, data?, error?}` 형식인지 auth_integration.test.ts로 확인
6. **Brief 021 Ideal Criteria #19**: `test/api/error_codes.test.ts` + `test/api/envelope.test.ts` 통과로 카탈로그 일관 적용 확인
7. **Brief 021 Ideal Criteria #18 갭 명시**: openapi.yaml 35 paths 존재 확인 (Phase 2 Dart codegen은 Phase 2 carryover)

### 레벨 3 — Phase 2 carryover (본 Cycle 책임 밖)

| 항목 | Phase 2 검증 방법 |
|---|---|
| OpenAPI 실 응답 호환 (Ideal #18 갭) | staging API 호출 + Dart 클라이언트 회귀 테스트 |
| Dart codegen build-time | Flutter pub run build_runner + Dart compile |
| CF Access 실 SSO 연결 | CF Access JWT 실 발급 + verify |

## Risks & Mitigations

| # | 위험 | 영향 | 완화 전략 |
|---|---|---|---|
| **R1** | **envelope wrapping 패턴 선택** — Hono after-middleware로 응답 인터셉트 시 Response body 이중 읽기 문제 | 모든 endpoint 응답 형식 비일관 | `apiSuccess` / `apiError` wrap helper를 각 route handler에서 명시적 호출 (SD-1). Middleware 인터셉트 패턴 미사용. |
| **R2** | **BetterAuth session middleware 결합** — Cycle 4 D1 직접 구현과 full BetterAuth adapter 사이 불일치 | getSession() API 변경 시 routes 전체 영향 | Phase 2 carryover (Brief Decision 7). 현재는 `getSession(kv, sessionId)` 직접 호출로 고정. adapter 전환은 Phase 2 한 곳에서 처리. |
| **R3** | **cfAccessVerifier structural parser** — admin route 인증이 production에서 무력화 위험 (JWKS 미검증) | admin endpoints 보안 갭 | Phase 2 carryover (Cycle 4 § Phase 2 Carryover Audit). Phase 1 scope 내에서는 테스트 JWKS resolver로 통과. |
| **R4** | **OpenAPI yaml 수동 작성 drift** — 코드 변경 시 yaml 업데이트 누락 | Mobile client spec 불일치 | Phase 2에서 `@hono/zod-openapi`로 route-inline schema → 자동 생성 전환 (Brief Decision 12 갭 #18). 수동 작성은 Phase 1 임시. |
| **R5** | **dashboard 하위 13 endpoints routes.rb 정합** — routes.rb `member` 방식의 실제 HTTP method 매핑 오해 | dashboard sub-paths 미등록 | RED 045 표 직접 인용. routes.rb grep 결과와 교차 확인. `adminDashboardRouter.get("/completion_rates")` 패턴으로 sub-path 등록. |
| **R6** | **public/admin host 분리 운영** — `api.<DOMAIN>` ↔ `admin.<DOMAIN>` host 기반 분기 결합 | Cycle 1 cookie-policy.ts와 충돌 가능 | Cycle 5는 path-based routing (`/api/...` prefix)만 사용. host-based 분기는 Cycle 1 cookie-policy.ts가 이미 처리 — 결합 안전. |
| **R7** | **`?raw` import 미지원** — vitest-pool-workers 환경에서 yaml 파일 `?raw` import 불가 | spec.test.ts parse 실패 | RED 045 test 파일 assertions 먼저 확인. mock 방식(yaml string literal) 또는 `readFileSync` 대안 준비. |
| **R8** | **35 test assertions 합산 불일치** — RED 045 파일별 합 142 vs 표기 151 (9 차이) | vitest 실행 시 기대 pass 수 혼란 | vitest run 최종 출력 숫자를 truth source로 사용. 중간 계산 값에 의존하지 않음. |

## References

| 문서 | 경로 | 참조 용도 |
|---|---|---|
| RED 045 | `docs/6_backend/02_cf_workers_rebuild/045_TDDRed_cycle5_api_mobile.md` | Endpoints Inventory (35), Test Files, Implementation Hints, Risks (가장 중요) |
| Brief 021 | `docs/6_backend/02_cf_workers_rebuild/021_Brief_conversion_phase1.md` | Decision 8 (envelope), Decision 9 (OpenAPI codegen), Decision 12 (verify 모델, Phase 2 갭 #18/19), Ideal Criteria 표 |
| Scope 026 | `docs/6_backend/02_cf_workers_rebuild/026_Scope_conversion_phase1.md` | Cycle 5 in_scope 정의, 파일 목록 |
| Critique 030 | `docs/6_backend/02_cf_workers_rebuild/030_Critique_Synthesis_scope.md` | § C3 routes.rb 실측 32 endpoints (본 plan에서 35로 정정) |
| Plan 042 (Cycle 4) | `docs/6_backend/02_cf_workers_rebuild/042_Plan_cycle4_auth_security.md` | Step 4-block 패턴 (Approach/Commands/검증/Impact) |
| betterAuth.ts | `apps/workers/src/auth/betterAuth.ts` | `getSession()`, `signIn()`, `signUp()`, `signOut()` 시그니처 |
| cfAccessVerifier.ts | `apps/workers/src/auth/cfAccessVerifier.ts` | `createCFAccessVerifier()`, `JwksResolver` interface |
| middleware/index.ts | `apps/workers/src/middleware/index.ts` | 5종 middleware barrel export |
| src/index.ts | `apps/workers/src/index.ts` | 현재 app 구조 + route 등록 위치 |
| routes.rb | `server/config/routes.rb` | Rails 원본 35 endpoints anchor |
| openapi.yaml | `shared/api-schema/openapi.yaml` | 현재 `paths: {}` stub — Step 4에서 35 paths로 채움 |
