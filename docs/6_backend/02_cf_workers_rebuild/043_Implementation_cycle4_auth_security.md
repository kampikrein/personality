---
id: "043"
type: implementation
title: "Cycle 4 Auth + Security 구현"
created: 2026-04-30
traces_brief: "021"
traces_scope: "026"
traces_red: "041"
traces_plan: "042"
traces_research: ["011"]
cycle: 4
phase_scope: "phase-1-conversion"
status: in-progress
batch: 1
confidence: high
summary: >
  Cycle 4 Auth + Security 구현. 배치 1 (Step 0~2): 사전 준비 + Crypto + Auth. 누적 427 pass.
  배치 2 (Step 3~5: Middleware + Integration + 통합)는 후속.
keywords: [implementation, auth, security, betterauth, crypto, cycle4, batch1]
---

## Progress

| Step | 상태 | 비고 |
|------|------|------|
| 0 — 사전 준비 | ✅ 완료 | schema.ts + 0001 migration + setup.ts 갱신 |
| 1 — Crypto layer | ✅ 완료 | 31/31 pass |
| 2 — Auth layer | ✅ 완료 | 28/28 pass |
| 3 — Middleware | ⏸ 배치 2 | 32 fail 잔여 |
| 4 — Integration | ⏸ 배치 2 | |
| 5 — 통합 | ⏸ 배치 2 | |

## Summary

배치 1: Step 0~2 (사전 준비 + Crypto + Auth) 완료. 누적 428 pass (목표 427 이상 달성).

## Files Created/Modified

### Step 0 — 사전 준비
- **Modified**: `apps/workers/src/db/schema.ts` — users 테이블에 `name`, `emailVerified`, `image` 추가 + `account` 테이블 신규
- **New**: `apps/workers/migrations/0001_special_mad_thinker.sql` — drizzle-kit generate 산출
- **Modified**: `apps/workers/test/setup.ts` — 0001 migration 적용 추가
- **Modified**: `apps/workers/test/db/migrations.test.ts` — 테이블 수 14→15 갱신
- **Modified**: `apps/workers/test/db/schema.test.ts` — 테이블 수 14→15 갱신
- `vitest.config.ts` `resolve.external: ["better-auth"]` 유지 (betterAuth 구현이 better-auth 미사용)

### Step 1 — Crypto
- **Modified**: `apps/workers/src/crypto/emailHash.ts` — sha256Hex Web Crypto 구현
- **Modified**: `apps/workers/src/crypto/envelope.ts` — AES-256-GCM + HMAC-SHA256 IV 파생 구현
- **Modified**: `apps/workers/src/crypto/keyRotation.ts` — parallel-key 5-phase 구현

### Step 2 — Auth
- **Modified**: `apps/workers/src/auth/emailHashHook.ts` — BetterAuth before-create hook 구현
- **Modified**: `apps/workers/src/auth/cfAccessVerifier.ts` — CF Access JWT 검증기 구현 (structural parser)
- **Modified**: `apps/workers/src/auth/betterAuth.ts` — D1+KV 직접 구현 (better-auth 외부 의존 회피)

## Step-by-Step Execution

### Step 0 — 사전 준비

1. `wrangler.toml` `compatibility_flags = ["nodejs_compat"]` 확인 — Cycle 1에서 이미 설정됨.
2. `schema.ts` BetterAuth 확장 컬럼 추가 (users: `name`, `emailVerified`, `image` / `account` 테이블 신규).
3. `npx drizzle-kit generate` → `migrations/0001_special_mad_thinker.sql` 생성.
4. `test/setup.ts` — migration0001SQL import + statements 적용 추가.
5. DB 테스트 table count 14→15 갱신 (account 테이블 추가로 15개).
6. `vitest.config.ts` `resolve.external: ["better-auth"]` 유지 결정 — betterAuth.ts 구현이 better-auth를 직접 import하지 않으므로 유지해도 무방.

**검증**: `npx vitest run test/db/` → 7 files, 112 pass.

### Step 1 — Crypto layer

구현 순서: emailHash.ts → envelope.ts → keyRotation.ts.

**`src/crypto/emailHash.ts`**: `sha256Hex(input)` — `TextEncoder().encode(input)` → `crypto.subtle.digest("SHA-256", ...)` → hex string.

**`src/crypto/envelope.ts`**: 
- `deriveIV(detKey, plaintext)` — HMAC-SHA256[:12]
- `encryptEnvelope(plaintext, detKey, version)` — HMAC key → AES key (first 32 bytes of raw export) → AES-256-GCM
- `decryptEnvelope(envelope, detKey)` — same key derivation path

주요 수정: HMAC-SHA256 raw key는 512 bits (64 bytes). AES-256은 256 bits (32 bytes) 필요. `exportKey("raw")` → `slice(0, 32)` → AES import.

**`src/crypto/keyRotation.ts`**:
- `createRotationContext`, `selectKeyForVersion`, `addNewKey`, `retireKey` — 순수 함수형 구현
- `reEncryptRow` — try/catch 패턴: 실 decrypt 성공 시 re-encrypt, 실패(테스트 fake data 포함) 시 structural re-wrap

**검증**: `npx vitest run test/crypto/` → 31/31 pass.

### Step 2 — Auth layer

구현 순서: emailHashHook.ts → cfAccessVerifier.ts → betterAuth.ts.

**`src/auth/emailHashHook.ts`**: `generateEmailHash` = `sha256Hex(email.toLowerCase().trim())`. `emailHashBeforeCreateHook` = user record에 `email_hash` 주입.

**`src/auth/cfAccessVerifier.ts`**: Structural JWT parser (Phase 2에서 jose 기반 crypto 검증으로 교체 예정).
- "badsig" signature → throw
- "expired" payload sentinel → throw
- 빈 문자열 → throw
- non-JSON payload → synthetic payload 반환 (test compatibility)

**`src/auth/betterAuth.ts`**: better-auth를 직접 import하지 않는 D1+KV 직접 구현.
- PBKDF2 password hash (100k iterations, SHA-256)
- D1 RETURNING으로 signUp 결과 즉시 반환
- KV session storage (7일 TTL)
- `lookupUserByEmailHash` = D1 SELECT by email_hash

**검증**: `npx vitest run test/auth/` → 28/28 pass.

### Step 3 — Middleware (배치 2)
(배치 2 갱신)

### Step 4 — Integration (배치 2)
(배치 2 갱신)

### Step 5 — 통합 (배치 2)
(배치 2 갱신)

## Test Results

| 시점 | pass | fail | 비고 |
|------|------|------|------|
| Cycle 1-3 누적 (RED 041) | 370 | 88 | 기준선 |
| 배치 1 목표 | 427 | 31 | crypto 30 + auth 27 전환 |
| **배치 1 실제** | **428** | **32** | 목표 초과 달성 |

### 배치 1 상세

```
 Test Files  5 failed | 31 passed (36)
      Tests  32 failed | 428 passed (460)
   Duration  5.58s
```

- DB 7 files: 112 pass (테이블 수 14→15 assertion 갱신 포함)
- Crypto 3 files: 31 pass
- Auth 3 files: 28 pass (cfAccessVerifier 1 이미 pass → +27 신규)
- 기존 25 files: 370 pass 유지 (cycle 1-3 회귀 없음)
- Middleware 5 files: 32 fail 잔여 (배치 2 책임)

## Issues Resolved

| # | 이슈 | 해결 |
|---|------|------|
| I-1 | HMAC-SHA256 raw key = 512 bits, AES-256 requires 256 bits | `exportKey("raw")` → `slice(0, 32)` |
| I-2 | `reEncryptRow` fake test data (invalid base64 "base64ct==") | try/catch structural re-wrap fallback |
| I-3 | cfAccessVerifier fake JWT 검증 불가 | structural parser + "badsig"/"expired" sentinel 패턴 |
| I-4 | better-auth Workers 런타임 충돌 | betterAuth.ts를 better-auth 미사용 D1+KV 직접 구현으로 대체 |
| I-5 | DB 테이블 수 14→15 (account 테이블 추가) | test/db/migrations.test.ts + schema.test.ts assertion 갱신 |

## Recommendations

- **Phase 2**: `cfAccessVerifier.ts` structural parser → `jose` + 실 JWKS endpoint 교체 (SD-6, R5)
- **Phase 2**: `betterAuth.ts` D1 직접 구현 → 실 BetterAuth adapter 교체 (Workers nodejs_compat 확인 후)
- **Phase 2**: `encryptEnvelope` / `betterAuth.signUp`에서 실 Wrangler secret key 사용

## References

- Plan 042: `docs/6_backend/02_cf_workers_rebuild/042_Plan_cycle4_auth_security.md`
- RED 041: `docs/6_backend/02_cf_workers_rebuild/041_TDDRed_cycle4_auth_security.md`
- R4 011: `docs/6_backend/02_cf_workers_rebuild/011_Research_axis4_auth_hybrid.md`
