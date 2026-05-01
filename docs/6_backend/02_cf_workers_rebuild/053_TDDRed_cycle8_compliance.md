---
id: "053"
type: tdd-red
title: "Cycle 8 Compliance (GDPR/PIPA) — RED phase"
created: 2026-05-01
traces_brief: "021"
traces_scope: "026"
traces_cycle6_impl: "051"
cycle: 8
phase_scope: "phase-1-conversion"
status: completed
confidence: high
summary: >
  GDPR/PIPA 5 흐름 (consent / deletion / audit log / cross-border / age verification) E2E 통합 + 신규 endpoint
  검증 vitest 테스트 작성. cycle 1-6 (722 pass) → cycle 8 추가 후 742 pass + 41 fail 의도.
  green phase에서 신규 service + endpoint 구현 시 통과.
keywords: [tdd-red, compliance, gdpr, pipa, audit-log, deletion, consent, age-verification, cycle8]
---

## Progress

- [x] Step 0: 보고서 스켈레톤 Write
- [x] Step 1: Context grep (Brief/Scope/schema/routes)
- [x] Step 2: Stub files 생성 (4개)
- [x] Step 3: RED 테스트 작성 (6 파일 × N tests)
- [x] Step 4: vitest run → 41 fail / 742 pass
- [x] Step 5: Implementation hints

## Summary

Cycle 8 Compliance (GDPR/PIPA) RED phase 완료. 6개 테스트 파일 + 4개 stub 파일 작성.

**결과**: cycle 1-6 기존 742 pass 유지 + cycle 8 신규 41 fail (의도적 RED).

41개 fail의 root cause 분류:
- **auditLogger stub**: `auditLog()` / `getAuditLogs()` `throw "not implemented"` → consent_flow, audit_log_integrity 테스트 전부
- **crossBorderConsent stub**: `recordCrossBorderConsent` / `revokeCrossBorderConsent` / `checkCrossBorderConsent` `throw "not implemented"`
- **ageVerification stub**: `verifyAge()` / `calculateAgeFromBirthdate()` `throw "not implemented"`
- **cross_border_consents route stub**: `throw "not implemented"` → 3개 route 테스트
- **accounts route 미연동**: birthdate 검증 미구현 → signup 400/403 미반환
- **deletion route audit 미연동**: POST 201 미반환 + audit_log 미기록
- **deletionProcessor audit action 차이**: `deletion_processed` action 검증 → 현재 processor가 다른 action 사용
- **SLA `completed` status**: deletion_request 처리 후 `completed` 미반환

## Compliance Flow Inventory

| Flow | Rails 원본 | TS 신규/기존 | Cycle 흡수 | Cycle 8 신규 |
|------|-----------|------------|-----------|-------------|
| consent 수집·철회 | consents_controller.rb (TYPES: data_processing/account_linking/analytics) | routes/public/consents.ts | cycle 5 | E2E + audit_log 연동 |
| deletion_request | deletion_requests_controller.rb | routes/public/deletion_requests.ts + deletionProcessor.ts | cycle 3,5 | E2E + audit_log + SLA 검증 |
| audit_log | ApplicationRecord callback | auditLogger.ts (신규 helper) | cycle 3 일부 | 중앙화 helper + immutability + admin retrieval |
| 국외 이전 고지·동의 | N/A (미구현) | crossBorderConsent.ts + cross_border_consents route (신규) | **신규** | 전체 |
| 14세 미만 처리 | N/A (미구현) | ageVerification.ts (신규) | **신규** | 전체 |

**Schema 확인**: consents 테이블 — `granted` (boolean) + `granted_at` + `revoked_at` (no `status` column). deletion_requests — `request_token` NOT NULL UNIQUE (직접 INSERT 시 필수).

## Test Files Created (6 files × 총 61 tests)

| 파일 | 테스트 수 | RED fail | 설명 |
|------|----------|---------|------|
| `test/compliance/consent_flow.test.ts` | 7 | 5 | consent E2E + auditLogger 연동 |
| `test/compliance/deletion_flow.test.ts` | 7 | 4 | deletion E2E + SLA + cascade |
| `test/compliance/audit_log_integrity.test.ts` | 11 | 9 | auditLog helper + immutability + pagination |
| `test/compliance/cross_border_consent.test.ts` | 14 | 12 | 국외 이전 동의 신규 책임 전체 |
| `test/compliance/age_verification.test.ts` | 11 | 9 | verifyAge + calculateAge + signup route |
| `test/compliance/admin_compliance.test.ts` | 11 | 2 | admin audit_logs (기존) + SLA + consent stats |

**총 61 tests, 41 fail (RED), 20 pass (인프라/DB schema 직접 검증)**

### Pass 이유 분석 (20개)

- `crossBorderConsentsRouter is defined` — Hono 인스턴스 자체는 생성됨
- `initiateParentalConsentFlow throws 'not implemented'` — Phase 2 placeholder 의도 pass
- `allows signup for 14+ with birthdate provided` — 현재 accounts route가 birthdate 무시 → 201 반환 (GREEN에서 엄격해짐)
- `processDeletion removes all session-related data` — cycle 3 이미 구현됨 → pass
- `deletion_request has created_at timestamp` — DB 직접 조회 → pass
- `pending deletion_request older than 30 days qualifies` — DB 직접 SQL 쿼리 → pass
- admin_compliance 대부분 — DB 직접 쿼리 또는 기존 adminAuditLogsRouter (cycle 5 구현) 사용

## Stub Files

```
apps/workers/src/services/compliance/
  ├── auditLogger.ts          — auditLog() + getAuditLogs() stub
  ├── crossBorderConsent.ts   — recordCrossBorderConsent() + revokeCrossBorderConsent() + checkCrossBorderConsent() stub
  └── ageVerification.ts      — verifyAge() + calculateAgeFromBirthdate() + initiateParentalConsentFlow() stub

apps/workers/src/api/routes/public/
  └── cross_border_consents.ts — POST/GET/:id/DELETE/:id stub
```

모두 `throw new Error("not implemented")` — GREEN phase에서 구현.

## Test Results

```
Test Files  5 failed | 79 passed (84)
      Tests  41 failed | 742 passed (783)
   Start at  22:06:15
```

**이전 (cycle 1-6)**: 722 pass  
**cycle 8 추가 후**: 742 pass + 41 fail  
**신규 추가**: 61 tests (20 pass + 41 fail)

cycle 1-6 기존 테스트 영향 없음.

## Implementation Hints for Green Phase

### 1. auditLogger.ts (최우선 — 다른 모든 flow 의존)

```typescript
// apps/workers/src/services/compliance/auditLogger.ts
export async function auditLog(db: D1Database, params: AuditLogParams) {
  const stmt = await db.prepare(
    `INSERT INTO audit_logs (resource_type, resource_id, action, actor_type, actor_id, metadata, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
  ).bind(
    params.resourceType, params.resourceId ?? null, params.action,
    params.actorType ?? null, params.actorId ?? null,
    JSON.stringify(params.metadata ?? {})
  ).run();
  return { id: stmt.meta.last_row_id };
}
```

- `getAuditLogs`: dynamic WHERE builder (resourceType, action, since, limit, offset)
- 모든 민감 service에서 `await auditLog(db, { ... })` 호출

### 2. consents route audit 연동

```typescript
// routes/public/consents.ts POST / 마지막에 추가
await auditLog(db, {
  resourceType: 'consent', resourceId: consentId,
  action: 'consent_granted', actorType: 'user',
  metadata: { consent_type, consent_version }
});

// DELETE /:id 마지막에
await auditLog(db, {
  resourceType: 'consent', resourceId: id,
  action: 'consent_revoked', actorType: 'user',
  metadata: { revoked_by: sessionId }
});
```

### 3. crossBorderConsent.ts

consents 테이블 재사용 (`consent_type = 'cross_border_transfer'`). 별도 테이블 불필요.  
- GREEN phase 0002 migration 불필요 (기존 schema로 충분)  
- `checkCrossBorderConsent`: `SELECT * FROM consents WHERE ... AND consent_type = 'cross_border_transfer' AND revoked_at IS NULL`

### 4. ageVerification.ts

```typescript
export function verifyAge(birthdate: string | undefined | null): AgeVerificationResult {
  if (!birthdate) return { eligible: false, reason: 'birthdate_required', minimumAge: 14 };
  const age = calculateAgeFromBirthdate(birthdate);
  if (age < 14) return { eligible: false, reason: 'under_minimum_age', minimumAge: 14 };
  return { eligible: true };
}

export function calculateAgeFromBirthdate(birthdate: string, ref = new Date()): number {
  const bd = new Date(birthdate);
  let age = ref.getFullYear() - bd.getFullYear();
  const m = ref.getMonth() - bd.getMonth();
  if (m < 0 || (m === 0 && ref.getDate() < bd.getDate())) age--;
  return age;
}
```

### 5. accounts route — birthdate 검증 연동

```typescript
// routes/public/accounts.ts POST / (signup)
const { email, password, birthdate } = await c.req.json();
const ageResult = verifyAge(birthdate);
if (!ageResult.eligible) {
  if (ageResult.reason === 'birthdate_required') {
    return errorResponse(ApiErrorCode.VALIDATION_FAILED, 'birthdate is required', 400);
  }
  await auditLog(db, { action: 'under_age_signup_blocked', resourceType: 'user', metadata: { email } });
  return errorResponse(ApiErrorCode.FORBIDDEN, 'under_age_blocked', 403);
}
```

### 6. deletionProcessor audit action 통일

현재 `deletion_processor.ts`가 audit_log에 기록하는 action 값 확인 후 `deletion_processed` 통일.  
SLA: `deletion_requests.status` → `'completed'` (현재 processor가 다른 값 사용할 수 있음, 확인 필요).

### 7. cross_border_consents route

```typescript
crossBorderConsentsRouter.post("/", async (c) => {
  const token = c.req.header("X-Session-Token");
  if (!token) return errorResponse(ApiErrorCode.UNAUTHORIZED, "auth required", 401);
  const result = await recordCrossBorderConsent(c.env.DB, { ... });
  return c.json({ success: true, data: { id: result.consentId, consentType: 'cross_border_transfer', status: 'granted' } }, 201);
});
```

## Risks

| Risk | 영향 | 대응 |
|------|------|------|
| audit_log immutability 강제 | schema trigger vs app-level | GREEN: app-level guard 우선, SQLite trigger는 Phase 2 |
| cross_border 정의 모호 | 국외 이전 기준 불명확 | consents.consent_type = 'cross_border_transfer' 단일 기준으로 통일 |
| deletionProcessor audit action 불일치 | `deletion_processed` vs 실제 기록 action | GREEN: deletionProcessor 코드 확인 후 통일 |
| 보호자 동의 흐름 | Phase 2 carryover | initiateParentalConsentFlow Phase 2 stub 유지 |
| SLA monitoring 자동화 | cron handler 미구현 | GREEN: cycle 1 cron에 30일 초과 체크 추가 |
| consents.status 컬럼 없음 | `granted` boolean + `revoked_at` 사용 | GREEN: `revoked_at IS NOT NULL` 패턴으로 통일 |

## References

- `/Users/kampikrein/A/personality/apps/workers/src/db/schema.ts` — consents, deletion_requests, audit_logs 테이블
- `/Users/kampikrein/A/personality/apps/workers/src/services/compliance/deletionProcessor.ts` — processDeletion()
- `/Users/kampikrein/A/personality/apps/workers/src/api/routes/public/consents.ts` — consentsRouter
- `/Users/kampikrein/A/personality/apps/workers/src/api/routes/public/deletion_requests.ts` — deletionRequestsRouter
- `/Users/kampikrein/A/personality/apps/workers/src/api/routes/admin/audit_logs.ts` — adminAuditLogsRouter
- `/Users/kampikrein/A/personality/server/app/models/consent.rb` — TYPES: data_processing / account_linking / analytics
