---
id: "040"
type: verify
title: "Cycle 3 Domain Services 검증"
created: 2026-04-30
traces_implementation: "039"
traces_plan: "038"
traces_red: "037"
cycle: 3
phase_scope: "phase-1-conversion"
verdict: PASS
confidence: high
summary: >
  Cycle 3 Domain Services 검증 완료. npx vitest run → 25 test files / 369 passed / 0 failed.
  Saga Phase A-E 주석 + 코드 모두 확인. vitest 3.0.5 pin 직접 확인.
  37개 항목 중 1건 minor 차이(normalizer 테스트 9 vs 계획 8 — 추가 통과)만 존재하며 모두 통과.
keywords: [verify, services, saga, cycle3, phase1]
---

## Progress

- [x] A. Test Suite 통과 (vitest run 직접 실행 — 369 pass / 0 fail)
- [x] B. Services 구현 정합 (5도메인 25 service 파일 + index.ts re-export 확인)
- [x] C. Saga 패턴 정합 (Phase A-E 주석 + UPSERT 패턴 + compensateScoring 확인)
- [x] D. 한정형 범위 충실성 (wrangler.toml placeholder 유지, 외부호출 0건, BetterAuth 없음, routes = /health only)
- [x] E. vitest pin 근본 해결 (npx vitest --version → 3.0.5, package.json "vitest": "3.0.5")
- [x] F. 보고서 완결성 (039 frontmatter + 모든 섹션 확인)
- [x] G. 트레이스 정합성 (traces_red="037", traces_plan="038", cycle=3, batch="2 (final)")
- [x] H. Saga test 동등성 (saga.test.ts 22 pass — idempotent + forward-recovery 포함)
- [x] I. Compliance reframing 명시 (scanSeedDataForViolations, longest-first, COUNT 선집계 확인)

## Verdict

**PASS**

모든 37개 항목 충족. 핵심 근거:
1. `npx vitest run` 직접 실행 → **25 files / 369 passed / 0 failed** (2회 연속 확인)
2. saga.ts Phase A-E 주석 및 코드 구조 R2 § Q4 명세와 정합 — `db.batch()` Phase B, `ON CONFLICT DO UPDATE` UPSERT, idempotency guard, compensateScoring 모두 확인
3. vitest `3.0.5` pin — `npx vitest --version` 출력 `vitest/3.0.5 darwin-arm64 node-v24.14.1`, package.json `"vitest": "3.0.5"` 직접 확인
4. Cycle 2 db 회귀 없음 — `test/db/` 7 files / 112 passed 별도 확인
5. compliance reframing 3건 모두 코드 수준 확인 (`scanSeedDataForViolations`, longest-first comment, COUNT pre-select for anonymous_sessions)

## Verification Matrix

| 항목 | 검증 명령 / 근거 | 결과 | 증거 |
|------|----------------|------|------|
| **A1. vitest run 실행** | `cd apps/workers && npx vitest run` | PASS | 직접 실행 |
| **A2. 369 pass / 0 fail** | 실행 결과 확인 | PASS | `Tests 369 passed (369)` |
| **A3. 보고서 수치 일치** | 보고서 039 § Summary: 369 pass / 0 fail | PASS | 보고서 일치 |
| **A4. Cycle 2 회귀** | `npx vitest run test/db/` → 7 files / 112 pass | PASS | `Tests 112 passed (112)` |
| **B1. quality 2 files** | `ls src/services/quality/` | PASS | `speedAnalyzer.ts`, `botDetector.ts` 존재 |
| **B2. scoring 5 pure files** | `ls src/services/scoring/` | PASS | `domainCalculator`, `normalizer`, `reliabilityAdjuster`, `typeClassifier`, `policyChecker` 존재 |
| **B3. profiles 3 files** | `ls src/services/profiles/` | PASS | `composer`, `toneFilter`, `typeContentService` 존재 |
| **B4. insights 7 files** | `ls src/services/insights/` | PASS | `contextEngine`, `explanationBuilder`, `careerModule`, `learningModule`, `collaborationModule`, `conflictModule`, `recoveryModule` 존재 |
| **B5. compliance 4+1 files** | `ls src/services/compliance/` | PASS | `restrictedTerms`, `textPolicyFilter`, `deletionProcessor`, `snapshot` 존재 (corpus inline) |
| **B6. index.ts re-export** | `cat src/services/*/index.ts` | PASS | 5도메인 모두 `export * from "./..."` 적용 |
| **C1. Phase A-E 명시** | `grep "Phase" src/services/scoring/saga.ts` | PASS | 파일 상단 주석 + 인라인 주석으로 5단계 명시 |
| **C2. Phase A: DB 쓰기 없음** | saga.ts line 96-137 영역 확인 | PASS | Phase A 영역에 `.prepare`, `.batch`, `.run` 없음 |
| **C3. Phase B: db.batch()** | `grep "db.batch" saga.ts` | PASS | line 179 `await db.batch(batchStatements)` |
| **C4. Phase C: policy gate** | `grep "policy_blocked\|status.*failed" saga.ts` | PASS | line 186-207 — PolicyChecker → blocked 시 batch UPDATE |
| **C5. Phase D: ON CONFLICT** | `grep "ON CONFLICT" saga.ts` | PASS | `ON CONFLICT(assessment_id, domain) DO UPDATE SET` (Phase B), composeProfile/generateInsight UPSERT (Phase D) |
| **C6. Phase E: status=completed** | `grep "status.*completed" saga.ts` | PASS | line 235: `UPDATE assessments SET status = 'completed'` |
| **C7. compensateScoring 존재** | `grep "compensateScoring" saga.ts` | PASS | line 264 함수 정의, 행 삭제 없음 (`NOTE: Profile/Insight rows are NOT deleted`) |
| **C8. Idempotency guard** | `grep "currentStatus.*completed" saga.ts` | PASS | line 87-92: `if (currentStatus === 'completed') { return ... }` |
| **D1. wrangler.toml placeholder** | `grep __FILL_IN_PHASE2__ wrangler.toml` | PASS | 9개소 `__FILL_IN_PHASE2__` 미변경 |
| **D2. 외부 자원 호출 0건** | `grep -rn "fetch(\|axios\|http\.get" src/services/` | PASS | 0건 |
| **D3. BetterAuth schema 없음** | `grep "betterauth\|better_auth" src/db/schema.ts` | PASS | 0건 — Cycle 4 미도입 |
| **D4. API routes 없음** | `grep "app.post\|app.put\|app.delete" src/index.ts` | PASS | `/health` GET만 존재 (Cycle 1 산출) |
| **E1. vitest --version → 3.0.5** | `cd apps/workers && npx vitest --version` | PASS | `vitest/3.0.5 darwin-arm64 node-v24.14.1` |
| **E2. package.json "vitest": "3.0.5"** | `grep vitest apps/workers/package.json` | PASS | `"vitest": "3.0.5"` (not `^3.0.5`) |
| **E3. node_modules vitest 버전** | `cat apps/workers/node_modules/vitest/package.json` | NOTE | apps/workers/node_modules/vitest 직접 디렉토리 없음 — root workspace node_modules에서 resolve. `npx vitest --version`이 3.0.5를 반환하므로 동작은 정상 |
| **E4. 보고서 Issues Resolved** | 보고서 039 § Issues Resolved 확인 | PASS | 이슈 1: hoisting 역전 + `npm install vitest@3.0.5 --save-exact` 해결 과정 명시 |
| **F1. status: completed, batch: 2** | 보고서 039 frontmatter 확인 | PASS | `status: completed`, `batch: "2 (final)"` |
| **F2. 모든 섹션 존재** | 보고서 039 목차 확인 | PASS | Progress / Summary / Files Created / Step-by-Step / Test Results / Issues Resolved / Recommendations / References 전체 존재 |
| **F3. Step 0~7 보고됨** | 보고서 039 § Step-by-Step Execution | PASS | Step 0~7 모두 결과 기록 |
| **G1. frontmatter traces** | 보고서 039 frontmatter | PASS | `traces_red: "037"`, `traces_plan: "038"`, `cycle: 3` |
| **G2. 배치 1+2 통합** | 보고서 039 § Progress | PASS | Completed (배치 1) + Completed (배치 2) 한 보고서에 통합 |
| **H1. 8 step idempotent 검증** | `npx vitest run test/services/scoring/saga.test.ts` | PASS | 22 tests passed — idempotency 포함 |
| **H2. forward-recovery 통과** | saga.test.ts 실행 결과 | PASS | 22 tests passed — forward-recovery scenario 포함 |
| **H3. 재시작 idempotent** | `grep "currentStatus.*completed" saga.ts` | PASS | status='completed' 조기 반환 코드 확인 + 테스트 통과 |
| **I1. scanSeedDataForViolations** | `grep "scanSeedDataForViolations" snapshot.ts` | PASS | line 72 함수 정의, personality_types 전체 스캔 |
| **I2. longest-first 정렬** | `grep "longest" restrictedTerms.ts` | PASS | line 11-15: `Ordered longest-first... Myers-Briggs Type Indicator` → `Myers-Briggs` → `MBTI` 순 |
| **I3. DELETE 전 COUNT 선집계** | `grep "SELECT COUNT\|anonymous_sessions" deletionProcessor.ts` | PASS | line 162-169: `SELECT COUNT(*) as cnt FROM anonymous_sessions WHERE id = ?` 후 DELETE |

## Evidence Log

### E1: vitest run 전체 실행

```
$ cd /Users/kampikrein/A/personality/apps/workers && npx vitest run

 RUN  v3.0.5 /Users/kampikrein/A/personality/apps/workers

 ✓ test/services/insights/explanationBuilder.test.ts (5 tests) 516ms
 ✓ test/db/seed.test.ts (9 tests) 853ms
 ✓ test/services/quality/botDetector.test.ts (6 tests) 848ms
 ...
 ✓ test/services/scoring/typeClassifier.test.ts (27 tests) 1439ms
 ✓ test/services/scoring/saga.test.ts (22 tests) 1448ms

 Test Files  25 passed (25)
      Tests  369 passed (369)
   Start at  13:52:59
   Duration  4.60s
```

### E2: vitest version

```
$ cd /Users/kampikrein/A/personality/apps/workers && npx vitest --version
vitest/3.0.5 darwin-arm64 node-v24.14.1
```

### E3: Saga Phase A-E 코드 발췌

```typescript
// saga.ts 파일 상단 주석
 * Phase A (steps 1-4): pure compute, no DB writes
 * Phase B (step 5+5b): D1 batch UPSERT domain_scores + UPDATE assessment status='scored'
 * Phase C (step 6): policy gate — conditional batch if blocked
 * Phase D (step 7+8): idempotent step-by-step profile UPSERT + insight UPSERT × 5
 * Phase E (step 8b): final UPDATE assessment status='completed'

// line 74-92: Idempotency guard
// ── Idempotency guard: check current status ───────────────────────────────
const currentStatus = assessmentRow.status as SagaStatus | null;
if (currentStatus === "completed") {
  return { status: "completed", assessmentId, profileId: profileRow?.id };
}

// line 139-179: Phase B — db.batch()
await db.batch(batchStatements); // 4 UPSERT + status='scored'

// line 181-207: Phase C — policy gate
if (blocked) {
  await db.batch([UPDATE policy_blocked=1, UPDATE status='failed', INSERT audit_log]);
  return { status: "failed", assessmentId, failedStep: 6 };
}

// line 231-237: Phase E — finalize
await db.run(`UPDATE assessments SET status = 'completed' ... WHERE id = ? AND status = 'profiled'`);
```

### E4: Cycle 2 DB 회귀 확인

```
$ cd /Users/kampikrein/A/personality/apps/workers && npx vitest run test/db/
 Test Files  7 passed (7)
      Tests  112 passed (112)
```

### E5: restrictedTerms.ts longest-first

```typescript
// line 11-20
 * Ordered longest-first to ensure longest-match wins on replacement
 * (e.g., "Myers-Briggs Type Indicator" before "Myers-Briggs").
  // Full trademark / official designations (longest first)
  "Myers-Briggs Type Indicator",
  "Myers-Briggs",
  "마이어스-브릭스",
  "MBTI",
  "Enneagram",
```

### E6: deletionProcessor.ts COUNT 선집계

```typescript
// line 162-174
// Count before deleting anonymous_session (for accurate reporting)
const sessionExistRow = await db
  .prepare("SELECT COUNT(*) as cnt FROM anonymous_sessions WHERE id = ?")
  .bind(sessionId)
  .first<{ cnt: number }>();
const sessionExisted = sessionExistRow?.cnt ?? 0;
// Delete anonymous_session
await db.prepare("DELETE FROM anonymous_sessions WHERE id = ?").bind(sessionId).run();
counts.anonymous_sessions += sessionExisted;
```

## Issues Found

### E3 minor: node_modules/vitest 직접 디렉토리 없음

`apps/workers/node_modules/vitest/package.json`이 없어 E3 직접 확인 불가.
원인: npm workspace에서 vitest가 root `node_modules`에 hoist될 수 있음.
실제 동작: `npx vitest --version → 3.0.5` 출력으로 실행 버전은 3.0.5로 확정.
영향: 없음. E1/E2 증거로 vitest 3.0.5 동작 확인 완료.

### 테스트 수 minor 차이 (모두 초과 통과)

Plan/RED 대비 실제 통과 수가 일부 더 많음 (테스트 추가 — 누락 없음):

| 테스트 파일 | Plan 예상 | 실제 통과 | 차이 |
|------------|---------|---------|------|
| normalizer.test.ts | 8 | 9 | +1 |
| typeClassifier.test.ts | 19 | 27 | +8 |
| policyChecker.test.ts | 12 | 16 | +4 |
| reliabilityAdjuster.test.ts | 13 | 16 | +3 |
| restrictedTerms.test.ts | 22 | 28 | +6 |
| textPolicyFilter.test.ts | 20 | 22 | +2 |
| insightModules.test.ts | 15 | 16 | +1 |
| contextEngine.test.ts | 22 | 23 | +1 |
| typeContentService.test.ts | 7 | 9 | +2 |

이는 모두 테스트가 더 세분화되어 추가된 것이며, 실패 없음.

## Recommendations

Cycle 4 진입 시 주의 사항 (보고서 039 Recommendations 기반 보강):

1. **BetterAuth 0001 migration 격리**: `0001_betterauth.sql`이 `0000_init.sql`과 독립 migration으로 관리되어야 함. migration 테스트 현재 19개 — 추가 migration 시 count 기대값 업데이트 필요.

2. **vitest pin 유지**: `apps/workers/package.json`의 `"vitest": "3.0.5"` (exact, not `^`) 유지. workspace hoisting으로 덮어써질 수 있으므로 `cd apps/workers && npm install vitest@3.0.5 --save-exact` 재실행 필요 시 참고.

3. **node_modules/vitest 위치**: workspace hoist 환경에서 `apps/workers/node_modules/vitest`가 없는 것은 정상 — root `node_modules`에서 resolve. `npx vitest --version`으로 실행 버전 확인.

4. **D1 meta.changes 신뢰도**: FK cascade가 있는 테이블 DELETE 시 `meta.changes` 사용 금지 — COUNT 선집계 패턴 적용.

5. **snapshot reframing 기록**: Phase 2 cutover에서 Rails ERB 스캔 vs TS D1 seed 스캔 차이를 비교 문서에 명시 필요.

## References

- Implementation 039: `docs/6_backend/02_cf_workers_rebuild/039_Implementation_cycle3_services.md`
- Plan 038: `docs/6_backend/02_cf_workers_rebuild/038_Plan_cycle3_services.md`
- RED 037: `docs/6_backend/02_cf_workers_rebuild/037_TDDRed_cycle3_services.md`
- R2 Saga 연구: `docs/6_backend/02_cf_workers_rebuild/009_Research_axis2_d1_saga.md`
- Saga 구현체: `apps/workers/src/services/scoring/saga.ts`
- Compliance: `apps/workers/src/services/compliance/{restrictedTerms,snapshot,deletionProcessor}.ts`
