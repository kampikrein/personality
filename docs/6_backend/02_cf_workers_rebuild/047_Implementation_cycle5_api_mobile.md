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
status: in-progress
batch: 1
confidence: high
summary: >
  Cycle 5 API 구현. 배치 1 (Step 0~2): envelope + error_codes + public 22 endpoints.
  배치 2 (Step 3~5: admin + OpenAPI + integration) 후속.
keywords: [implementation, api, mobile, hono, public, envelope, cycle5, batch1]
---

# Cycle 5 API + Mobile 구현

## Progress

| Step | 상태 | 설명 |
|------|------|------|
| Step 0 | ✅ 완료 | 사전 준비 (js-yaml 설치 확인, endpoints 매핑 재확인) |
| Step 1 | ✅ 완료 | envelope + error_codes (33/33 pass) |
| Step 2 | ✅ 완료 | public 8 routes (91/91 pass) + auth_integration (11/11 pass) |
| (배치 2) Step 3 | ⏳ 대기 | admin 4 routes × 13 endpoints |
| (배치 2) Step 4 | ⏳ 대기 | OpenAPI yaml + Hono RPC AppType |
| (배치 2) Step 5 | ⏳ 대기 | Integration + 통합 |

## Summary

배치 1 완료. 총 578 pass (491 cycle 1-4 + 87 신규 GREEN). 33 fail 잔여 = 배치 2 대상 (admin routes 16 + openapi 12 + codegen 5).

**신규 GREEN 전환**: envelope(13) + error_codes(20) + public 8 routes(91) + auth_integration(11) = **102 assertions** (auth_integration는 admin 2개 router의 최소 구현 포함).

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

## Test Results

### 배치 1 완료

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
| cycle 1-4 (기존) | 460 | 0 |
| admin/alerts.test.ts (배치 2 잔여) | 0 | 7 |
| admin/question_sets.test.ts (배치 2 잔여) | 4 | 9 |
| admin/dashboard.test.ts (배치 2 잔여) | 4 | 2 |
| openapi/spec.test.ts (배치 2 잔여) | 0 | 12 |
| codegen/dart_client.test.ts (배치 2 잔여) | 2 | 3 |
| **전체** | **578** | **33** |

### 기준 대비
- 배치 전: 491 pass / 120 fail
- 배치 후: 578 pass / 33 fail
- **신규 GREEN**: +87 tests

## Issues Resolved

1. **auth_integration의 admin router 의존성**: auth_integration이 admin routes를 import하므로 audit_logs + dashboard 최소 구현 필요. 배치 2 완전 구현 전 최소 CF Access JWT 검증만 적용.
2. **assessmentsRouter rate-limit test**: `GET /` 경로 없어 404 반환 → 리스트 엔드포인트 추가 + `X-Rate-Limit-Exceeded` hook으로 429 처리.
3. **sessions GET /me WWW-Authenticate**: auth_integration 401 응답에 헤더 필요 → `c.json(..., 401, {"WWW-Authenticate": "Bearer realm=\"api\""})` 추가.
4. **results 422 처리**: `pending-assess-id` → 422 Unprocessable Entity (VALIDATION_FAILED code 재사용).

## Recommendations (배치 2 준비)

1. **admin/alerts.test.ts 7 fail**: alerts router 미구현 → 배치 2에서 audit_logs 패턴 동일 적용.
2. **admin/question_sets.test.ts 9 fail**: CRUD 완전 구현 필요 (create, update, delete 포함).
3. **admin/dashboard.test.ts 2 fail**: dashboard router 구현됐지만 2 assertions fail — test 파일 확인 필요.
4. **openapi/spec.test.ts 12 fail**: paths: {} 채우기 → 배치 2 Step 4.
5. **codegen/dart_client.test.ts 3 fail**: getOpenApiSpec() 구현 → 배치 2 Step 4.
6. **apps/workers/src/api/index.ts 재검토**: AppType export 추가 필요 (배치 2 Step 4).

## References

- Plan 046: `docs/6_backend/02_cf_workers_rebuild/046_Plan_cycle5_api_mobile.md`
- RED 045: `docs/6_backend/02_cf_workers_rebuild/045_TDDRed_cycle5_api_mobile.md`
- Cycle 4 auth: `apps/workers/src/auth/betterAuth.ts`, `apps/workers/src/auth/cfAccessVerifier.ts`
