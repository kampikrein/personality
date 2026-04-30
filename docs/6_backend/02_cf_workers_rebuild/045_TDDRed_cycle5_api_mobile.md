---
id: "045"
type: tdd-red
title: "Cycle 5 API Layer + Mobile Contract — RED phase"
created: 2026-04-30
traces_brief: "021"
traces_scope: "026"
traces_critique: "030"
traces_cycle4_impl: "043"
cycle: 5
phase_scope: "phase-1-conversion"
status: completed
confidence: high
summary: >
  32 endpoints (public 22 + admin 10) Hono routes + envelope middleware + error codes catalog + OpenAPI 3 + Hono RPC
  + auth integration 검증 vitest 테스트 작성. cycle 1-4 (460 pass) 유지 + cycle 5 120 fail 의도. green phase에서 routes 구현 시 통과.
keywords: [tdd-red, api, mobile, hono, openapi, envelope, error-codes, cycle5]
---

## Progress

- [x] Step 1 — Endpoints inventory 정확화
- [x] Step 2 — Vitest 테스트 디렉토리 구조
- [x] Step 3 — RED 테스트 작성
- [x] Step 4 — Stub 파일 생성
- [x] Step 5 — fail 확인 (`npx vitest run` → 17 failed files | 36 passed | 120 fail | 491 pass)
- [x] Step 6 — green phase 진입 가이드

## Summary

Cycle 5 RED phase 완료:

- **Stub 파일**: `apps/workers/src/api/` 신규 디렉토리 (envelope.ts, error_codes.ts, routes/public 8 + routes/admin 4 + openapi/index.ts, index.ts = 15 파일)
- **테스트 파일**: `apps/workers/test/api/` 신규 디렉토리 (13개 test 파일, 총 151 assertions)
- **OpenAPI stub**: `shared/api-schema/openapi.yaml` 신규 (paths: {} 의도적 빈 stub)
- **누적 결과**: Tests 611 (491 pass + 120 fail) | Test Files 53 (36 pass + 17 fail)
- **Cycle 1-4 회귀 없음**: 36 파일 / 460 tests 모두 pass 유지

## Endpoints Inventory

Critique 030 § C3 routes.rb 실측 결과 + routes.rb 직접 확인:

### Public Endpoints (22)

| # | HTTP Method | Path | Rails 원본 | 인증 | Envelope |
|---|------------|------|-----------|------|---------|
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

### Admin Endpoints (10)

| # | HTTP Method | Path | Rails 원본 | 인증 | Envelope |
|---|------------|------|-----------|------|---------|
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

**비고**: admin dashboard/completion_rates, dashboard/drop_off_analysis가 Rails 원본에 포함. 총 endpoint 수 = 22 + 13 = 35 (Critique 030 §32 추정보다 3 더 많음; makeplan에서 최종 확정).

## Test Files Created

| 파일 | 도메인 | Assertions |
|-----|-------|-----------|
| `test/api/envelope.test.ts` | API envelope middleware | 12 |
| `test/api/error_codes.test.ts` | Error code catalog | 16 |
| `test/api/routes/public/assessments.test.ts` | Assessments CRUD | 9 |
| `test/api/routes/public/sessions.test.ts` | Login/Logout/Me | 8 |
| `test/api/routes/public/accounts.test.ts` | Signup/Account | 8 |
| `test/api/routes/public/assessment_questions.test.ts` | Questions list + answer | 7 |
| `test/api/routes/public/results.test.ts` | Results + share | 6 |
| `test/api/routes/public/consents.test.ts` | Consent CRUD | 9 |
| `test/api/routes/public/deletion_requests.test.ts` | Deletion flow | 8 |
| `test/api/routes/public/health.test.ts` | Health check | 3 |
| `test/api/routes/admin/audit_logs.test.ts` | Audit logs (read-only) | 6 |
| `test/api/routes/admin/question_sets.test.ts` | Question sets CRUD | 9 |
| `test/api/routes/admin/alerts.test.ts` | Alerts manage | 7 |
| `test/api/routes/admin/dashboard.test.ts` | Dashboard stats | 6 |
| `test/api/openapi/spec.test.ts` | OpenAPI 3 spec validation | 12 |
| `test/api/codegen/dart_client.test.ts` | Hono RPC AppType | 5 |
| `test/api/auth_integration.test.ts` | Auth + routes 통합 | 11 |
| **합계** | | **151** |

## Stub Files

### `apps/workers/src/api/` (신규 15 파일)

```
src/api/
├── envelope.ts          — successResponse, errorResponse, createEnvelopeMiddleware (stub)
├── error_codes.ts       — ApiErrorCode enum, ERROR_CODE_STATUS, apiError (stub)
├── index.ts             — re-export all
├── openapi/
│   └── index.ts         — getOpenApiSpec, AppType (stub)
└── routes/
    ├── public/
    │   ├── assessments.ts
    │   ├── sessions.ts
    │   ├── accounts.ts
    │   ├── assessment_questions.ts
    │   ├── results.ts
    │   ├── consents.ts
    │   ├── deletion_requests.ts
    │   └── health.ts
    └── admin/
        ├── audit_logs.ts
        ├── question_sets.ts
        ├── alerts.ts
        └── dashboard.ts
```

모든 stub: `throw new Error("not implemented")` — TDD RED 원칙 준수.

### `shared/api-schema/openapi.yaml` (신규 stub)

OpenAPI 3.0.3 껍데기. `paths: {}` 의도적으로 빈 상태. GREEN phase에서 32+ endpoint 전체 채움.

## Test Results

```
Test Files  17 failed | 36 passed (53)
     Tests  120 failed | 491 passed (611)
  Duration  5.62s
```

- **Cycle 1-4 기존 36 파일 / 460 pass → 회귀 없음 ✓**
- **Cycle 5 신규 17 파일 / 120 fail → 의도된 RED ✓**
- **Cycle 5 신규 31 partial passes**: 라우터 export 확인, enum 값 확인, YAML parse 확인 등 stub 수준에서도 pass 가능한 assertions

### 추가 변경사항

- `vitest.config.ts`: `singleWorker: true` 추가 (53+ 파일 병렬 시 OS ephemeral port 고갈 방지)
- root `package.json`: `@vitest/runner@3.0.5`, `@vitest/snapshot@3.0.5` 추가 (hoisting fix)
- `apps/workers/package.json`: `js-yaml@4.1.1`, `@types/js-yaml@4.0.9` 추가 (spec.test.ts YAML parse)

## Implementation Hints for Green Phase

### 1. Envelope Middleware (`src/api/envelope.ts`)

```typescript
// 패턴: Hono afterResponse hook 또는 응답 helper
export function successResponse<T>(data: T): SuccessResponse<T> {
  return { success: true, data };
}

export function errorResponse(code: string, message: string, details?: unknown): ErrorResponse {
  return { success: false, error: { code, message, ...(details !== undefined ? { details } : {}) } };
}

// createEnvelopeMiddleware: 모든 c.json 호출을 자동 wrap
// 방법 A: Hono middleware로 응답 가로채기 (response transformer)
// 방법 B: enveloped c.json helper를 context에 주입
// 권장: 방법 B (명시적, type-safe)
//   c.var.ok = (data) => c.json(successResponse(data))
//   c.var.err = (code, msg, details?) => c.json(errorResponse(code, msg, details), statusCode)
```

### 2. Error Codes (`src/api/error_codes.ts`)

```typescript
// enum은 이미 stub에 정의됨 — 실제 구현만 추가
export function apiError(code: ApiErrorCode, message: string, details?: unknown) {
  return {
    success: false as const,
    error: { code, message, ...(details !== undefined ? { details } : {}) },
  };
}
```

### 3. Public Routes

각 router file에서 서비스 레이어 호출 + envelope wrap:

```typescript
// assessments.ts 예시 (GREEN):
assessmentsRouter.post("/", sessionMiddleware, async (c) => {
  const userId = c.var.session.userId;
  const assessment = await assessmentService.create(c.env.DB, userId);
  return c.json(successResponse(assessment), 200);
});
```

BetterAuth session middleware 패턴 (Cycle 4 산출물 활용):
- `createAuth(c.env.DB, c.env.KV)` → session 검증
- session 없으면 `c.json(apiError(ApiErrorCode.UNAUTHORIZED, "Not authenticated"), 401)`

### 4. Admin Routes

CF Access JWT 검증:

```typescript
// admin routes 공통 패턴:
const adminAuth = createCFAccessVerifier(c.env); // Cycle 4 stub → GREEN: jose JWT verify
if (!adminAuth.valid) {
  return c.json(apiError(ApiErrorCode.FORBIDDEN, "Admin access required"), 403);
}
```

### 5. OpenAPI YAML (`shared/api-schema/openapi.yaml`)

선택지 3가지:
- **A. 수동 작성**: 35 endpoints × operationId + requestBody + responses 직접 작성 (~500줄)
- **B. zod-openapi**: `@hono/zod-openapi`로 routes에서 schema 정의 → openapi.yaml 자동 생성
- **C. openapi-typescript**: 완성된 openapi.yaml → TypeScript 타입 자동 생성

권장: B. GREEN phase에서 `@hono/zod-openapi`로 route별 schema 정의 → `app.getOpenAPIDocument()` → openapi.yaml 저장.

### 6. Hono RPC AppType

```typescript
// src/api/index.ts (GREEN):
import { Hono } from "hono";
const app = new Hono<{ Bindings: Bindings }>()
  .route("/api/assessments", assessmentsRouter)
  // ... 나머지 routers
  ;
export type AppType = typeof app;
export default app;
```

Flutter Dart 클라이언트 생성 (Phase 2 carryover, Brief 021 § Decision 12 갭 #18):
- `openapi-generator-cli` (JAR build-time 의존성 — Brief 021 M2 carryover)
- 또는 `dart-openapi` Node CLI
- Phase 1에서는 AppType export만 확인 (Dart 실 빌드 미포함)

### 7. CSRF 분기 (Cycle 4 OQ-5)

모바일 Bearer 요청은 CSRF 검사 제외:
```typescript
// src/middleware/csrf.ts GREEN 수정:
if (req.headers.get("Authorization")?.startsWith("Bearer ")) {
  return next(); // Bearer = stateless → CSRF 불필요
}
// Origin + Sec-Fetch-Site 이중 체크는 cookie-based session 전용
```

## Risks

| Risk | 영향 | 완화 방안 |
|------|------|---------|
| Envelope wrapping 패턴 선택 | 모든 route의 응답 형식 통일성 | `c.var` helper 주입 패턴 권장 (type-safe, explicit) |
| Dart codegen build-time JAR | Brief 021 M2 외부 자원 의존성 | Phase 1 = AppType TS export만, Phase 2 = Dart CLI |
| OpenAPI auto-gen vs 수동 | 스키마-코드 drift | `@hono/zod-openapi` 도입 권장 (route별 inline schema) |
| Admin: SSR vs JSON 선택 | admin 라우트가 Cycle 6 SSR과 겹침 | API(JSON) + SSR(HTML) 분리 — 동일 service 호출, 응답 형식만 다름 |
| Public 22 endpoint 모두 JSON 노출 | Cycle 6 SSR 페이지와 분기 | `/api/` prefix로 JSON API 분리, SSR은 non-prefix routes |
| singleWorker=true 추가 | 기존 DB 격리 테스트에 영향 가능 | `isolatedStorage: true` (default) 유지로 D1 격리 보장 |
| `@vitest/snapshot` hoisting | vitest-pool-workers 0.7.x 의존성 충돌 | root package.json에 고정버전 추가로 해결 |

## References

- Brief 021 § In Scope 6, § Decision 8 (envelope), § Decision 9 (OpenAPI codegen), § Decision 12 (Phase 1 verify): `/Users/kampikrein/A/personality/docs/6_backend/02_cf_workers_rebuild/021_Brief_conversion_phase1.md`
- Scope 026 § Cycle 5 (32 endpoints inventory): `/Users/kampikrein/A/personality/docs/6_backend/02_cf_workers_rebuild/026_Scope_conversion_phase1.md`
- Critique 030 § C3 (routes.rb 실측 32 endpoints): `/Users/kampikrein/A/personality/docs/6_backend/02_cf_workers_rebuild/030_Critique_Synthesis_scope.md`
- Cycle 4 auth stubs: `apps/workers/src/auth/betterAuth.ts`, `apps/workers/src/auth/cfAccessVerifier.ts`
- Rails routes: `server/config/routes.rb`
- Vitest config: `apps/workers/vitest.config.ts` (singleWorker 추가)
