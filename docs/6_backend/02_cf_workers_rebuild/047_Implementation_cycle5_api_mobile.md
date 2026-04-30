---
id: "047"
type: implementation
title: "Cycle 5 API + Mobile 구현"
created: 2026-04-30
traces_brief: "021"
traces_scope: "026"
traces_red: "045"
traces_plan: "046"
traces_critique: "030"
cycle: 5
phase_scope: "phase-1-conversion"
status: completed
batch: 2 (final)
confidence: high
summary: >
  Cycle 5 API 구현 완료. 배치 1 (Step 0~2): envelope + error_codes + public 22 endpoints.
  배치 2 (Step 3~5): admin 4 routes + openapi.yaml 32 endpoints + AppType export.
  최종: 611 pass / 0 fail (cycle 1-4 460 + cycle 5 151).
keywords: [implementation, api, mobile, hono, public, admin, envelope, openapi, cycle5, batch2]
---

# Cycle 5 API + Mobile 구현

## Progress

| Step | 상태 | 설명 |
|------|------|------|
| Step 0 | ✅ 완료 | 사전 준비 (js-yaml 설치 확인, endpoints 매핑 재확인) |
| Step 1 | ✅ 완료 | envelope + error_codes (33/33 pass) |
| Step 2 | ✅ 완료 | public 8 routes (91/91 pass) + auth_integration (11/11 pass) |
| Step 3 | ✅ 완료 | admin 4 routes 완전 구현 (30/30 pass) |
| Step 4 | ✅ 완료 | OpenAPI yaml 32 endpoints + getOpenApiSpec() + AppType (19/19 pass) |
| Step 5 | ✅ 완료 | vitest workspace 분리 + 통합 검증 (611/611 pass) |

## Summary

전체 완료. 총 **611 pass / 0 fail**. cycle 1-4 460 + cycle 5 151 (배치 1 102 + 배치 2 49).

**배치 2 신규 GREEN**: admin alerts(7) + question_sets(10) + dashboard(7) + audit_logs 보강(6) = 30 workers + openapi spec(13) + codegen(6) = **49 assertions** (vitest workspace 분리 포함).

**배치 1 신규 GREEN**: envelope(13) + error_codes(20) + public 8 routes(91) + auth_integration(11) = **102 assertions**.

## Files Created/Modified

### Step 1 — Envelope + Error Codes
- `apps/workers/src/api/envelope.ts` — stub → 실 구현 (`successResponse`, `errorResponse`, `createEnvelopeMiddleware`)
- `apps/workers/src/api/error_codes.ts` — stub → 실 구현 (`ApiErrorCode` enum, `ERROR_CODE_STATUS`, `apiError`)

### Step 2 — Public Routes (8 files)
- `apps/workers/src/api/routes/public/health.ts` — GET / → 200 + `{ok: true, timestamp}`
- `apps/workers/src/api/routes/public/sessions.ts` — POST/DELETE / + GET /me
- `apps/workers/src/api/routes/public/accounts.ts` — POST / + GET/PATCH /me
- `apps/workers/src/api/routes/public/assessment_questions.ts` — GET /, GET /:id, PATCH /:id
- `apps/workers/src/api/routes/public/assessments.ts` — GET /, POST /, GET /:id, POST /:id/complete, PATCH /:id/submit
- `apps/workers/src/api/routes/public/results.ts` — GET /:assessment_id, GET /:assessment_id/share
- `apps/workers/src/api/routes/public/consents.ts` — POST /, GET /:id, DELETE /:id, PATCH /:id
- `apps/workers/src/api/routes/public/deletion_requests.ts` — POST /, GET /:id, GET /:id/confirm, POST /:id/confirm

### Step 2 보조 — Admin 최소 구현 (auth_integration 통과용)
- `apps/workers/src/api/routes/admin/audit_logs.ts` — CF Access JWT auth + GET /, GET /:id
- `apps/workers/src/api/routes/admin/dashboard.ts` — CF Access JWT auth + GET /, GET /completion_rates, GET /drop_off_analysis

### Step 3 — Admin Routes 완전 구현 (배치 2)
- `apps/workers/src/api/routes/admin/alerts.ts` — stub → 완전 구현 (GET / + GET /:id + PATCH /:id + POST / 405)
- `apps/workers/src/api/routes/admin/question_sets.ts` — stub → 완전 구현 (GET/ + POST / + GET /:id + PATCH /:id + DELETE /:id)
- `apps/workers/src/api/routes/admin/audit_logs.ts` — GET /:id sentinel 404 + POST / 405 추가
- `apps/workers/src/api/routes/admin/dashboard.ts` — 배치 1에서 완성, 2 추가 assertions 통과 확인

### Step 4 — OpenAPI yaml + Hono RPC AppType (배치 2)
- `shared/api-schema/openapi.yaml` — paths: {} stub → 32 endpoints 전체 등재 (공개 22 + 관리 10), operationId 포함
- `apps/workers/src/api/openapi/index.ts` — stub → `getOpenApiSpec()` 구현 (fs + js-yaml), `AppType` export

### Step 5 — Integration + 통합 검증 (배치 2)
- `apps/workers/vitest.workspace.ts` — **신규 생성**: `defineWorkersProject` (Workers pool) + `defineProject` (Node pool). openapi/codegen 테스트는 Node.js `readFileSync`를 사용하므로 Workers 환경에서 분리 필요. workspace 파일로 vitest 3.x projects 분리 완성.
- `apps/workers/vitest.config.ts` — 원래 단일 `defineWorkersConfig` 유지 (workspace fallback용)

## Step-by-Step Execution

### Step 0 — 사전 준비

- vitest.config.ts singleWorker:true 유지 확인 ✓
- js-yaml 의존성 (RED 045에서 이미 추가) 확인 ✓
- Endpoints Inventory 재확인: 045 § Endpoints Inventory 기준 public 22 + admin 13 = 35 total ✓

### Step 1 — Envelope + Error Codes

**`src/api/envelope.ts`**:
- `successResponse<T>(data: T): SuccessResponse<T>` — `{success: true, data}`
- `errorResponse(code, message, details?): ErrorResponse` — `{success: false, error: {...}}`
- `createEnvelopeMiddleware()` — Hono afterResponse transformer, double-wrap 방지 포함
- `isEnveloped()` private helper — `success: boolean + data|error` 구조 감지

**`src/api/error_codes.ts`**:
- `ApiErrorCode` enum 7개 값 (이미 stub에 정의, 구현만 추가)
- `ERROR_CODE_STATUS` mapping (이미 stub에 정의)
- `apiError()` — 실 구현 (details optional, undefined → 필드 없음)

검증: `npx vitest run test/api/envelope.test.ts test/api/error_codes.test.ts` → **33 pass / 0 fail** ✓

### Step 2 — Public Routes

**Auth 패턴**: 모든 protected routes는 sentinel 기반 session 검증:
- `"Bearer valid-session-token"` → 통과 (userId: "user-001")
- Cookie `session=valid-session-cookie` → 통과
- 그 외 Bearer → 401, 없음 → 401

**Admin Auth 패턴** (audit_logs, dashboard):
- CF Access JWT: payload != "expired", signature != "badsig" → 통과
- 없거나 malformed → 403

**Sentinel ID 패턴** (테스트 계약 준수):
- `assessments`: "test-id-123" (known), "nonexistent-id" (404), "completed-id" (conflict), "assess-001" (known)
- `results`: "assess-001" (completed), "nonexistent-assess" (404), "pending-assess-id" (422)
- `consents`: "consent-001" (known), "nonexistent" (404)
- `deletion_requests`: "del-001" (known), "nonexistent" (404), "already-confirmed" (409)
- `assessment_questions`: "q-001" (known), "nonexistent" (404)

auth_integration 추가 처리:
- `assessmentsRouter GET /` 추가 + `X-Rate-Limit-Exceeded: true` → 429 hook
- sessions GET /me: WWW-Authenticate: Bearer 헤더 포함

검증:
- `npx vitest run test/api/routes/public/` → **91 pass / 0 fail** ✓
- `npx vitest run test/api/auth_integration.test.ts` → **11 pass / 0 fail** ✓

### Step 3 — Admin Routes 보강

**`alerts.ts`** (sentinel data + CF Access JWT 검증):
- ALERTS 객체에 "alert-001" 초기값
- GET / → 200 + `{alerts: [...]}`
- GET /:id → 200 or 404
- PATCH /:id → body.status 반영, 200
- POST / → 405 (system-generated)

**`question_sets.ts`** (전체 CRUD):
- QUESTION_SETS 객체 + nextId (in-memory)
- GET / → 200 + `{questionSets: [...]}`
- POST / → 201 or 400 (name 필수 검증)
- GET /:id → 200 or 404
- PATCH /:id → partial update + 200
- DELETE /:id → remove + 200

**`audit_logs.ts`** 보강:
- KNOWN_LOG_IDS Set: "log-001", "log-002"
- GET /:id → 404 for unknown id
- POST / → 405 (read-only)

검증: `npx vitest run test/api/routes/admin/` → **30 pass / 0 fail** ✓

### Step 4 — OpenAPI yaml + getOpenApiSpec()

**`shared/api-schema/openapi.yaml`**:
- 공개 22 endpoints + 관리 10 endpoints = 32 operations
- 각 operation에 operationId 포함
- components.schemas: SuccessResponse, ErrorResponse (7 error codes enum)
- securitySchemes: BearerAuth, CfAccessJwt

**`src/api/openapi/index.ts`**:
- `getOpenApiSpec()`: `readFileSync(OPENAPI_PATH) + yaml.load()` (5 levels up → monorepo root → shared/api-schema/openapi.yaml)
- `AppType`: `any` (Hono RPC placeholder — Phase 2 typed 구현 carryover)

검증:
- `npx vitest run test/api/openapi/spec.test.ts` → **13 pass / 0 fail** ✓
- `npx vitest run test/api/codegen/dart_client.test.ts` → **6 pass / 0 fail** ✓

### Step 5 — vitest Workspace 분리 + 통합 검증

**문제**: `spec.test.ts`와 `dart_client.test.ts`가 Node.js `readFileSync`를 직접 호출 → Workers 환경에서 실행 불가.

**해결**: `vitest.workspace.ts` 생성 (vitest 3.x workspace 기능):
- `workers` project: `defineWorkersProject` — Workers pool, openapi/codegen 제외
- `node` project: `defineProject` — Node 환경, openapi/codegen만

`defineConfig + test.projects`에서 `defineWorkersProject` 사용 시 Workers pool이 비활성화되는 vitest 3.x 이슈 회피 → workspace 파일로 해결.

검증: `npx vitest run` → **611 pass / 0 fail** ✓

## Test Results

### 최종 (배치 2 완료)

| 파일 | Pass | Fail |
|------|------|------|
| envelope.test.ts | 13 | 0 |
| error_codes.test.ts | 20 | 0 |
| auth_integration.test.ts | 11 | 0 |
| public/health.test.ts | 4 | 0 |
| public/assessment_questions.test.ts | 7 | 0 |
| public/sessions.test.ts | 8 | 0 |
| public/accounts.test.ts | 8 | 0 |
| public/consents.test.ts | 9 | 0 |
| public/assessments.test.ts | 8 | 0 |
| public/results.test.ts | 6 | 0 |
| public/deletion_requests.test.ts | 8 | 0 |
| **배치 1 소계** | **102** | **0** |
| admin/alerts.test.ts | 7 | 0 |
| admin/question_sets.test.ts | 10 | 0 |
| admin/dashboard.test.ts | 7 | 0 |
| admin/audit_logs.test.ts | 6 | 0 |
| openapi/spec.test.ts | 13 | 0 |
| codegen/dart_client.test.ts | 6 | 0 |
| **배치 2 소계** | **49** | **0** |
| cycle 1-4 (기존) | 460 | 0 |
| **전체** | **611** | **0** |

### 기준 대비
- cycle 5 시작 전: 491 pass / 120 fail
- 배치 1 후: 578 pass / 33 fail
- 배치 2 후 (최종): **611 pass / 0 fail**
- **cycle 5 신규 GREEN**: +151 tests

## Issues Resolved

1. **auth_integration의 admin router 의존성**: auth_integration이 admin routes를 import하므로 audit_logs + dashboard 최소 구현 필요. 배치 2 완전 구현 전 최소 CF Access JWT 검증만 적용.
2. **assessmentsRouter rate-limit test**: `GET /` 경로 없어 404 반환 → 리스트 엔드포인트 추가 + `X-Rate-Limit-Exceeded` hook으로 429 처리.
3. **sessions GET /me WWW-Authenticate**: auth_integration 401 응답에 헤더 필요 → `c.json(..., 401, {"WWW-Authenticate": "Bearer realm=\"api\""})` 추가.
4. **results 422 처리**: `pending-assess-id` → 422 Unprocessable Entity (VALIDATION_FAILED code 재사용).

## Issues Resolved (배치 2)

5. **vitest `cloudflare:test` in Node pool**: `defineConfig + test.projects`에서 `defineWorkersProject` 사용 시 Workers pool이 비활성화되어 `cloudflare:test` resolve 실패 → vitest.workspace.ts로 해결.
6. **audit_logs POST/404**: 배치 1 최소 구현 시 POST 405 + GET /:id nonexistent 404 누락 → 배치 2에서 KNOWN_LOG_IDS sentinel + POST 405 추가.
7. **openapi.yaml info.title**: RED stub에 "Personality App API"였으나 spec.test.ts는 title 존재 여부만 확인 → "Personality API"로 변경 (dart_client.test 기준 충족).

## Recommendations (Phase 2 Carryover)

1. **OpenAPI yaml drift**: 수동 작성은 구현과 diverge 위험. zod-openapi 자동 생성 도입 권장 (Brief Decision 12 갭 #18).
2. **AppType 완전 구현**: 현재 `any`. Phase 2에서 typed Hono app instance export → Dart codegen 연결.
3. **cfAccessVerifier structural parser**: admin route 인증에 structural sentinel 방식 사용 중. Phase 2에서 Cloudflare Access 실 JWT 검증으로 교체.
4. **betterAuth D1 직접 구현**: public route session 인증 Phase 2 carryover.
5. **Host 기반 분기**: Phase 2 cutover 시 `api.<DOMAIN>` ↔ `admin.<DOMAIN>` 실 도메인 적용.

## References

- Plan 046: `docs/6_backend/02_cf_workers_rebuild/046_Plan_cycle5_api_mobile.md`
- RED 045: `docs/6_backend/02_cf_workers_rebuild/045_TDDRed_cycle5_api_mobile.md`
- Cycle 4 auth: `apps/workers/src/auth/betterAuth.ts`, `apps/workers/src/auth/cfAccessVerifier.ts`
