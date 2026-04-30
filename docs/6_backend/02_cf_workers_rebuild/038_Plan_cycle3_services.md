---
id: "038"
type: plan
title: "Cycle 3 Domain Services GREEN Plan"
created: 2026-04-30
traces_brief: "021"
traces_scope: "026"
traces_red: "037"
traces_research: ["009"]
traces_synthesis: "018"
traces_cycle2_impl: "035"
cycle: 3
phase_scope: "phase-1-conversion"
status: completed
confidence: high
summary: >
  Cycle 3 GREEN plan. 20 services + saga (Phase A-E) + corpus 이식. 7-step 순차 진행. 0 fail / 369 pass 목표.
keywords: [plan, services, saga, scoring, insights, profiles, quality, compliance, green]
---

## Goal

Cycle 3 GREEN phase 목표는 RED 037에서 작성된 254 fail / 369 total 상태를 **0 fail / 369 pass**로 전환하는 것이다.

구체적으로는 5개 도메인(scoring, profiles, insights, quality, compliance)의 20 service 파일과 saga orchestrator(scoring/saga.ts)를 구현하고, Rails 원본 14 spec에서 도출된 vitest 계약을 모두 만족시킨다. Cycle 2의 115 pass(db layer)는 회귀 없이 유지해야 한다.

Brief 021 Ideal Criteria 매핑: 서비스별 pure function 분리(Decision 5), D1 UPSERT idempotency(Decision 10), Hybrid Pure Saga Phase A-E 구현(Decision 4), restricted_terms corpus 이식(In Scope 12), 16 types × 2 locales 데이터(In Scope 6).

## Scope

### Included

| 항목 | 상세 |
|------|------|
| scoring 5 services | domainCalculator, normalizer, typeClassifier, reliabilityAdjuster, policyChecker |
| scoring/saga | runScoringPipeline (Phase A-E, 8 step) + compensateScoring |
| profiles 3 services + data | composer, toneFilter, typeContentService + type_content_data (16 types × 2 locales) |
| insights 7 services | contextEngine, explanationBuilder, careerModule, learningModule, collaborationModule, conflictModule, recoveryModule |
| quality 2 services | speedAnalyzer, botDetector |
| compliance 5 services + corpus | restrictedTerms (+ RESTRICTED_TERMS corpus 이식), textPolicyFilter, deletionProcessor, snapshot |
| vitest pin | vitest 3.0.5 로컬 pin (RED R5 vitest 갭 해결) |
| 5 도메인 index.ts | re-export 갱신 (현재 stub → 실 구현체 export) |

### Excluded

| 항목 | 이유 |
|------|------|
| BetterAuth 인증 | Cycle 4 scope |
| API routes (Hono) | Cycle 5 scope |
| Admin UI | Cycle 6 scope |
| audit endpoints (GDPR/PIPA) | Cycle 8 scope |
| Durable Object | R2 결정으로 제외 — Hybrid Pure Saga로 대체 |
| Rails 원본 서비스 수정 | Read-only reference |

## Structural Decisions

| # | Decision | 채택 | 근거 |
|---|----------|------|------|
| 1 | Saga 패턴 | Hybrid Pure Saga D1 only — Phase A(pure compute) / B(D1 batch) / C(conditional batch) / D(idempotent step-by-step) / E(finalize) | R2 § Q4 결정. DO 불필요. ~150 LOC. |
| 2 | restricted_terms corpus 위치 | TS 상수 (`restrictedTermsCorpus.ts`) — Step 0에서 Rails 원본 크기 확인 후 결정. 크면 D1 seed fallback | Rails corpus 항목 수가 적을 경우 TS 상수가 단순. D1 seed는 운영 의존성 증가. |
| 3 | type_content_data 위치 | TS 상수 (`typeContentData.ts`) — 16 types × 2 locales (ko/en) | Rails `server/db/seeds.rb` personality_types 16 rows 이식. 작은 정적 데이터이므로 TS 상수 최적. |
| 4 | snapshot reframing | Rails ERB 스캔 제거 → D1 seed 스캔으로 범위 재정의 (RED 037 § R4 흡수) | TS 환경에 ERB 없음. D1 seed data 무결성 + restricted_terms 스캔으로 동등성 확보. |
| 5 | 구현 의존성 순서 | quality(독립) → scoring pure(1-5) → saga → profiles → insights → compliance 순 | 의존성 DAG 기반. quality는 DB만 의존하여 scoring과 병렬 가능하나 단일 에이전트이므로 순차 처리. |
| 6 | vitest pin | `apps/workers/package.json`에 `"vitest": "3.0.5"` 로컬 pin | RED 037 § R5: `@cloudflare/vitest-pool-workers`가 vitest 3.2.4에서 포트 충돌 간헐 발생. 3.0.5 범위 내 공식 지원. |
| 7 | Pure function 분리 | scoring 5 services + toneFilter + explanationBuilder + insight modules + speedAnalyzer + botDetector = 모두 pure function | D1 의존 없는 서비스는 DB fixture 없이 단위 테스트 가능. 테스트 속도 향상. |
| 8 | Drizzle batch 패턴 | Phase B: `db.batch([...])`, Phase D: step-by-step `.run()` | Phase B는 atomic 보장 필요(4 UPSERT + status UPDATE). Phase D는 각 step 독립 idempotent이므로 batch 불필요. |

## File Change Summary

### New Files (31개)

| # | Path | 설명 | Pure / D1 |
|---|------|------|-----------|
| 1 | `src/services/scoring/domainCalculator.ts` | DOMAINS 상수, polarity 로직 → raw_scores | Pure |
| 2 | `src/services/scoring/normalizer.ts` | proportional range formula, round 1dp | Pure |
| 3 | `src/services/scoring/typeClassifier.ts` | 4 axis threshold 50, letter map (E/I N/S F/T P/J) | Pure |
| 4 | `src/services/scoring/reliabilityAdjuster.ts` | Pearson r split-half, Spearman-Brown, 4 flags | Pure |
| 5 | `src/services/scoring/policyChecker.ts` | 3 block conditions, boundary strict | Pure |
| 6 | `src/services/scoring/saga.ts` | runScoringPipeline + compensateScoring (Phase A-E) | D1 |
| 7 | `src/services/profiles/toneFilter.ts` | 7 regex replacements, case-preserve | Pure |
| 8 | `src/services/profiles/typeContentService.ts` | locale ko/en fallback, D1 query | D1 |
| 9 | `src/services/profiles/typeContentData.ts` | 16 types × 2 locales TS 상수 | Pure |
| 10 | `src/services/profiles/composer.ts` | UPSERT profile + score_vector + ToneFilter | D1 |
| 11 | `src/services/insights/explanationBuilder.ts` | enrich: ≥2 suggestions → append | Pure |
| 12 | `src/services/insights/careerModule.ts` | 커리어 인사이트 pure compute | Pure |
| 13 | `src/services/insights/learningModule.ts` | 학습 인사이트 pure compute | Pure |
| 14 | `src/services/insights/collaborationModule.ts` | 협업 인사이트 pure compute | Pure |
| 15 | `src/services/insights/conflictModule.ts` | 갈등 인사이트 pure compute | Pure |
| 16 | `src/services/insights/recoveryModule.ts` | 회복 인사이트 pure compute | Pure |
| 17 | `src/services/insights/contextEngine.ts` | dispatcher + ExplanationBuilder + insight UPSERT | D1 |
| 18 | `src/services/quality/speedAnalyzer.ts` | 3 flags, median calculation | Pure |
| 19 | `src/services/quality/botDetector.ts` | 3 heuristics, confidence proportion | Pure |
| 20 | `src/services/compliance/restrictedTerms.ts` | RESTRICTED_TERMS corpus + scanRestrictedTerms + isTextClean | Pure |
| 21 | `src/services/compliance/restrictedTermsCorpus.ts` | corpus 상수 파일 (Step 0 size 확인 후 결정) | Pure |
| 22 | `src/services/compliance/textPolicyFilter.ts` | context enum, [REMOVED] replacement | Pure |
| 23 | `src/services/compliance/deletionProcessor.ts` | cascade delete, audit_log, counts | D1 |
| 24 | `src/services/compliance/snapshot.ts` | D1 seed scan + originality check | D1 |

**합계**: 24 new service files (20 services + saga + typeContentData + restrictedTermsCorpus + snapshot)

### Modified Files

| # | Path | 변경 내용 |
|---|------|-----------|
| 1 | `src/services/scoring/index.ts` | stub export → domainCalculator + normalizer + typeClassifier + reliabilityAdjuster + policyChecker + saga re-export |
| 2 | `src/services/profiles/index.ts` | stub export → composer + toneFilter + typeContentService re-export |
| 3 | `src/services/insights/index.ts` | stub export → contextEngine + explanationBuilder + 5 modules re-export |
| 4 | `src/services/quality/index.ts` | stub export → speedAnalyzer + botDetector re-export |
| 5 | `src/services/compliance/index.ts` | stub export → restrictedTerms + textPolicyFilter + deletionProcessor + snapshot re-export |
| 6 | `apps/workers/package.json` | vitest `"3.0.5"` pin 추가 (현재 3.2.4 → 3.0.5) |

### Reviewed Files (Read-only)

| Path | 목적 |
|------|------|
| `server/app/services/scoring/*.rb` | Rails 원본 계약 확인 |
| `server/app/services/profiles/*.rb` | ToneFilter 7 규칙 + TypeContent locale 확인 |
| `server/app/services/insights/*.rb` | 5 contexts + ExplanationBuilder 확인 |
| `server/app/services/quality/*.rb` | SpeedAnalyzer / BotDetector 3 heuristics 확인 |
| `server/app/services/compliance/*.rb` | RestrictedTerms corpus + Snapshot ERB 스캔 원본 확인 |
| `server/db/seeds.rb` | PersonalityType 16 rows locale 데이터 확인 |
| `apps/workers/src/db/schema.ts` | UNIQUE constraints + FK 확인 (이미 Cycle 2에서 완료) |
| `apps/workers/test/services/**/*.test.ts` | 각 step 완료 판단 기준 |

## Step 0 — 사전 준비

### Approach

vitest 버전 pin 결정 및 Rails 원본 데이터(restricted_terms corpus, type_content) 위치와 크기를 확인한다. 이 정보가 Step 2, 3의 corpus 파일 배치 전략을 결정한다. `npm install`은 plan 본문에 명시할 뿐, makeplan 에이전트가 실행하지 않는다.

### Commands

```bash
# 1. Rails restricted_terms corpus 크기 확인
grep -c "RESTRICTED\|restricted_term" server/app/services/compliance/restricted_terms.rb

# 2. type_content seeds 크기 확인 (16 rows × ko/en)
grep -c "personality_type\|name:\|locale" server/db/seeds.rb

# 3. vitest 현재 버전 확인
cat apps/workers/package.json | grep vitest

# 4. vitest pin 적용
cd apps/workers && npm install vitest@3.0.5 --save-dev

# 5. 설치 검증
cd apps/workers && npm install
```

### 검증

- `server/app/services/compliance/restricted_terms.rb` 항목 수 ≤ 50 → TS 상수 채택
- `apps/workers/package.json` `"vitest": "3.0.5"` 반영 확인
- `npm install` 오류 없음

### Impact Analysis

| 항목 | 영향 |
|------|------|
| 파일 | `apps/workers/package.json` 1개 수정 |
| 테스트 | vitest pin으로 Workers 포트 충돌 간헐 오류 제거 |
| 의존성 | Step 1-7 전체의 테스트 실행 안정성 확보 |
| 리스크 | vitest 3.0.5가 현재 test helpers와 호환 여부 — 기존 115 pass 유지로 확인 |

## Step 1 — Quality 도메인

### Approach

`speedAnalyzer.ts`와 `botDetector.ts` 2개 파일을 구현한다. 두 서비스는 DB 의존이 없는 pure function이므로 가장 먼저 구현하기 쉽고, 다른 도메인과 의존성이 없어 독립적으로 검증 가능하다.

- `analyzeSpeed(responses, durationMs?)` → `{ anomaly: boolean, flags: string[], median: number, rate: number }`. 3 flag 타입: `too_fast`, `uniform_timing`, `short_duration`.
- `detectBot(responses)` → `{ bot_suspected: boolean, patterns: string[], confidence: number }`. 3 heuristics: 직선형 패턴, 교번 패턴, 균일 응답. confidence = 감지 패턴 수 / 전체 heuristic 수.

### Commands

```bash
# 구현 후 quality 테스트만 실행
cd apps/workers && npx vitest run test/services/quality/
```

### 검증

- `test/services/quality/speedAnalyzer.test.ts` 6 tests pass
- `test/services/quality/botDetector.test.ts` 6 tests pass
- **quality 합계**: 12 tests pass, 0 fail
- Cycle 2 회귀: 115 tests 여전히 pass

### Impact Analysis

| 항목 | 영향 |
|------|------|
| 파일 | `speedAnalyzer.ts`, `botDetector.ts`, `quality/index.ts` 수정 |
| 테스트 | +12 pass (374 total 중 12 신규 통과) |
| 의존성 | 없음 (pure function) — 이후 어떤 step도 quality에 의존하지 않음 |
| 리스크 | median 계산 정렬 누락 시 경계값 테스트 실패 가능 |

## Step 2 — Scoring (saga 제외)

### Approach

5개 pure function 서비스를 구현한다. 모두 DB 의존 없이 in-memory 계산만 수행한다. 구현 순서는 의존성 흐름(DomainCalculator → Normalizer → TypeClassifier → ReliabilityAdjuster → PolicyChecker)을 따른다.

핵심 계약:
- `calculateDomainScores(assessment)` → `{ energy, decision_making, relationship, recovery }`. positive/negative polarity 분기, nil/undefined 응답 skip.
- `normalizeScores(rawScores, responses)` → `0-100 | null`. formula: `(raw - min) / (max - min) * 100`, round 1dp.
- `classifyType(normalizedScores)` → `{ type_code: string, axes: object }`. ≥50 → high letter (E/N/F/P), <50 → low (I/S/T/J). null → low로 처리.
- `adjustReliability(responses)` → `ReliabilityResult`. Pearson r split-half, Spearman-Brown correction, 4 flag types.
- `checkPolicy(reliabilityResult)` → `{ blocked: boolean, reasons: string[] }`. 3 block conditions (low reliability / speed anomaly / bot detection), boundary strict.

### Commands

```bash
# scoring pure 5개 테스트 실행 (saga 제외)
cd apps/workers && npx vitest run test/services/scoring/domainCalculator.test.ts test/services/scoring/normalizer.test.ts test/services/scoring/typeClassifier.test.ts test/services/scoring/reliabilityAdjuster.test.ts test/services/scoring/policyChecker.test.ts
```

### 검증

- `domainCalculator.test.ts` 10 tests pass
- `normalizer.test.ts` 8 tests pass
- `typeClassifier.test.ts` 19 tests pass
- `reliabilityAdjuster.test.ts` 13 tests pass
- `policyChecker.test.ts` 12 tests pass
- **scoring pure 합계**: 62 tests pass, 0 fail
- 누적 통과: 115 (Cycle 2) + 12 (quality) + 62 = 189 pass

### Impact Analysis

| 항목 | 영향 |
|------|------|
| 파일 | 5 service ts + `scoring/index.ts` 수정 (saga export는 Step 6 후 추가) |
| 테스트 | +62 pass |
| 의존성 | saga(Step 6), profiles(Step 3)의 blocking 선행 조건 |
| 리스크 | Spearman-Brown formula 오류 → reliabilityAdjuster 13 tests fail 연쇄. Pearson r 계산 정밀도 float 비교 — epsilon 허용 필요 여부 test 케이스 확인 필수 |

## Step 3 — Profiles

### Approach

toneFilter(pure) → typeContentData(TS 상수) → typeContentService(D1) → composer(D1) 순으로 구현한다.

**toneFilter**: 7개 regex replacement 규칙을 Rails 원본 그대로 이식. case-preserve 처리 포함. 이중 공백 collapse 마지막 적용.

**typeContentData**: 16 types × 2 locales(ko/en) TS 상수. `server/db/seeds.rb` PersonalityType 16 rows에서 strengths, caution_patterns, suggested_actions 추출하여 이식.

**typeContentService**: `getTypeContent(db, typeCode, locale)` → `TypeContent`. locale fallback(en → ko). D1 personality_types 테이블 조회.

**composer**: `composeProfile(db, assessmentId, typeCode)` → `ComposedProfile`. UPSERT profile + score_vector JSON + ToneFilter 적용. `ON CONFLICT(assessment_id) DO UPDATE RETURNING id`.

### Commands

```bash
# profiles 테스트 실행
cd apps/workers && npx vitest run test/services/profiles/
```

### 검증

- `toneFilter.test.ts` 11 tests pass
- `typeContentService.test.ts` 7 tests pass
- `composer.test.ts` 10 tests pass
- **profiles 합계**: 28 tests pass, 0 fail
- 누적 통과: 189 + 28 = 217 pass

### Impact Analysis

| 항목 | 영향 |
|------|------|
| 파일 | toneFilter.ts + typeContentData.ts + typeContentService.ts + composer.ts + `profiles/index.ts` 수정 |
| 테스트 | +28 pass |
| 의존성 | insights(Step 4)의 blocking 선행 조건. saga(Step 6) step 7에서 composer 호출 |
| 리스크 | 16 types locale 데이터 미이식 시 typeContentService 7 tests 전부 fail. Rails seeds.rb Read 필수 |

## Step 4 — Insights

### Approach

5개 insight module(pure) → explanationBuilder(pure) → contextEngine(D1) 순서로 구현한다.

**5 modules** (careerModule, learningModule, collaborationModule, conflictModule, recoveryModule): 각각 `generate(profile, locale)` → `{ suggestions: string[], raw_text: string }` 형태의 pure function. Rails 원본 각 module에서 suggestions 목록과 context별 텍스트 생성 로직을 이식.

**explanationBuilder**: `buildExplanation(moduleOutput)` → enriched string. ≥2 suggestions 있을 때 append 로직 적용.

**contextEngine**: `generateInsight(db, profileId, context)` → `InsightResult`. 5 contexts dispatcher + ExplanationBuilder 통합 + insight UPSERT (`ON CONFLICT(profile_id, context) DO UPDATE`). idempotent 보장.

### Commands

```bash
# insights 테스트 실행
cd apps/workers && npx vitest run test/services/insights/
```

### 검증

- `insightModules.test.ts` 15 tests pass (5 modules × 3 cases each)
- `explanationBuilder.test.ts` 5 tests pass
- `contextEngine.test.ts` 22 tests pass
- **insights 합계**: 42 tests pass, 0 fail
- 누적 통과: 217 + 42 = 259 pass

### Impact Analysis

| 항목 | 영향 |
|------|------|
| 파일 | 7 service ts + `insights/index.ts` 수정 |
| 테스트 | +42 pass |
| 의존성 | compliance/snapshot(Step 5)의 profile 데이터 스캔 선행 조건 |
| 리스크 | contextEngine idempotent 테스트 — 2회 실행 결과 동일 여부 검증. INSIGHT_CONTEXTS 상수(`contextEngine.ts` stub에 이미 선언됨) 활용 확인 |

## Step 5 — Compliance

### Approach

restrictedTerms(pure) → textPolicyFilter(pure) → deletionProcessor(D1) → snapshot(D1) 순서로 구현한다. restrictedTermsCorpus.ts는 Step 0에서 확인한 크기에 따라 배치.

**restrictedTerms**: `scanRestrictedTerms(text)` + `isTextClean(text, opts?)`. RESTRICTED_TERMS 배열(한국어 exact match + 영어 case-insensitive), ALLOWED_IN_TRUST_NOTICE 예외 목록. Rails 원본 corpus 그대로 이식.

**textPolicyFilter**: `filterText(text, context?)` → `{ clean: boolean, violations: string[], filtered_text: string }`. context enum(`content` / `trust_notice`). 위반 단어를 `[REMOVED]`로 치환.

**deletionProcessor**: `processDeletion(db, requestId)` → `DeletionResult`. cascade delete(anonymous_session → 하위 FK ON DELETE CASCADE), audit_log INSERT. `deleted_counts` 반환.

**snapshot**: D1 seed data 스캔 → 16 personality_types 존재 확인 + restricted term scan + character name originality check. Rails ERB 스캔 제거, D1 조회로 대체.

### Commands

```bash
# compliance 테스트 실행
cd apps/workers && npx vitest run test/services/compliance/
```

### 검증

- `restrictedTerms.test.ts` 22 tests pass
- `textPolicyFilter.test.ts` 20 tests pass
- `deletionProcessor.test.ts` 11 tests pass
- `snapshot.test.ts` 10 tests pass
- **compliance 합계**: 63 tests pass, 0 fail
- 누적 통과: 259 + 63 = 322 pass

### Impact Analysis

| 항목 | 영향 |
|------|------|
| 파일 | 5 service ts + restrictedTermsCorpus.ts + `compliance/index.ts` 수정 |
| 테스트 | +63 pass |
| 의존성 | saga(Step 6)의 Phase C에서 PolicyChecker 사용 — compliance는 saga와 직접 의존 없음 |
| 리스크 | 한국어 Unicode 정규식 `escapeRegExp` 미구현 시 restricted_terms 22 tests 다수 fail. Rails `Regexp.escape` 동등 구현 필수 |

## Step 6 — Saga (orchestrator)

### Approach

`scoring/saga.ts`를 구현한다. scoring 5 services(Step 2)와 profiles composer(Step 3), insights contextEngine(Step 4)이 모두 완료된 후 구현해야 한다. R2 § Q4 의사코드를 기반으로 Phase A-E를 순차 구현한다.

**runScoringPipeline(db, assessmentId)**:

```
Phase A (pure compute — no DB writes):
  Step 1: DomainCalculator → raw_scores (energy, decision_making, relationship, recovery)
  Step 2: Normalizer → normalized_scores (0-100 | null per domain)
  Step 3: TypeClassifier → type_code (4-letter) + axes
  Step 4: ReliabilityAdjuster → reliability_coefficient, consistency_index, speed_flag, etc.

Phase B (D1 batch — atomic):
  Step 5: UPSERT domain_scores × 4 + UPDATE assessments status='scored'
  SQL: INSERT INTO domain_scores (...) VALUES (...)
       ON CONFLICT(assessment_id, domain) DO UPDATE SET ...
  (+ Step 5b: UPDATE assessments SET status='scored' WHERE id=? AND status='submitted')

Phase C (conditional batch):
  Step 6: PolicyChecker → if blocked:
    - UPDATE domain_scores SET policy_blocked=1 WHERE assessment_id=?
    - UPDATE assessments SET status='failed', failure_reason=? WHERE id=? AND status='scored'
    - INSERT INTO audit_logs (resource_type, resource_id, action, metadata, created_at)
      VALUES ('Assessment', ?, 'scoring_blocked', ?, datetime('now'))

Phase D (idempotent step-by-step):
  Step 7: Profile UPSERT (INSERT ... ON CONFLICT(assessment_id) DO UPDATE RETURNING id)
           → R2-F2 필수 보강. UPDATE assessments SET status='profiled' WHERE id=? AND status='scored'
  Step 8: Insight UPSERT × 5 contexts
           (ON CONFLICT(profile_id, context) DO UPDATE SET ...)

Phase E (finalize):
  Step 8b: UPDATE assessments SET status='completed' WHERE id=? AND status='profiled'
```

**compensateScoring(db, assessmentId)** — forward-recovery 우선 보상:
```
1. UPDATE assessments SET status='failed', failure_reason='scoring_aborted'
   WHERE id=? AND status IN ('submitted','scoring','scored','profiled')
2. INSERT INTO audit_logs (...) VALUES ('Assessment', ?, 'scoring_compensated', ?, datetime('now'))
NOTE: Profile/Insight 행 삭제 안 함 — retry 시 UPSERT가 동일 결과 재생성.
      user-facing은 status='completed' gate.
```

### Commands

```bash
# saga 테스트만 실행
cd apps/workers && npx vitest run test/services/scoring/saga.test.ts
```

### 검증

- `saga.test.ts` 24 tests pass
  - Phase A-E 각 단계 DB 검증 (9 tests)
  - Idempotency 2회 실행 동일 결과 (2 tests)
  - Forward-recovery: compensate + partial preserve (4 tests)
  - E2E: 정상 완료, assessmentId 반환, step 4 throw (3 tests)
  - 기타 (6 tests)
- 누적 통과: 322 + 24 = 346 pass

### Impact Analysis

| 항목 | 영향 |
|------|------|
| 파일 | `saga.ts` + `scoring/index.ts` (saga export 추가) |
| 테스트 | +24 pass |
| 의존성 | Step 2(scoring pure 5개) + Step 3(profiles composer) + Step 4(insights contextEngine) 완료 후에만 진행 가능 |
| 리스크 | D1 batch INSERT 순서 오류 → Phase B atomic 보장 실패. Step 7 UPSERT RETURNING id 미지원 환경 → miniflare D1 binding에서 RETURNING 지원 여부 확인 필수 |

## Step 7 — 통합 검증

### Approach

전체 테스트 스위트를 실행하여 0 fail / 369 pass를 확인한다. Cycle 2 db layer 115 tests 회귀 없음을 포함한다. miniflare Workers 런타임 포트 충돌 간헐 오류가 발생하면 잠시 후 재실행.

### Commands

```bash
# 전체 테스트 실행
cd apps/workers && npm test

# 실패 시 도메인별 분리 실행으로 원인 추적
cd apps/workers && npx vitest run test/db/          # cycle 2 회귀 확인
cd apps/workers && npx vitest run test/services/    # cycle 3 전체
```

### 검증

- `Test Files`: 25 passed (0 failed)
- `Tests`: 369 passed (0 failed)
  - Cycle 2 db: 115 pass (회귀 없음)
  - Cycle 3 services: 254 pass (전부 신규 통과)
- Duration 기준: RED phase 4.17s와 유사 범위 (pure function 비중 높아 큰 증가 없을 것)
- saga 8 step idempotent 검증: 동일 assessmentId로 2회 실행 → 동일 결과
- forward-recovery scenario: Step 4 throw → compensateScoring → status='failed' + audit_log 확인

### Impact Analysis

| 항목 | 영향 |
|------|------|
| 파일 | 수정 없음 (검증 전용) |
| 테스트 | 369 / 369 pass 도달 확인 |
| 의존성 | Step 0-6 모두 완료 후 |
| 리스크 | miniflare 포트 충돌 → vitest 3.0.5 pin으로 해결. 미해결 시 `--pool=forks` 옵션 검토 |

## Implementation Details

### ToneFilter 7 규칙 (Rails 원본 그대로 이식)

```ts
// src/services/profiles/toneFilter.ts
const replacements = [
  { pattern: /you are/gi,     replacement: 'you tend toward' },
  { pattern: /always/gi,      replacement: (m: string) => m[0] === m[0].toUpperCase() ? 'Often' : 'often' },
  { pattern: /never/gi,       replacement: (m: string) => m[0] === m[0].toUpperCase() ? 'Rarely' : 'rarely' },
  { pattern: /can't /gi,      replacement: 'may find challenging ' },
  { pattern: /unable to/gi,   replacement: 'may find it challenging to' },
  { pattern: /better than /gi, replacement: '' },
  { pattern: /worse than /gi,  replacement: '' },
];
// 마지막: 이중 공백 collapse
text = text.replace(/  +/g, ' ');
```

`replacement`가 함수인 경우(`always` / `never`)는 match 문자열의 첫 글자 대소문자를 보존한다. `String.prototype.replace(pattern, fn)` 방식으로 구현.

### RestrictedTerms Corpus (Rails 원본)

```ts
// src/services/compliance/restrictedTermsCorpus.ts
export const RESTRICTED_TERMS = [
  "MBTI", "Myers-Briggs", "마이어스-브릭스", "Myers-Briggs Type Indicator",
  "에니어그램", "Enneagram",
  "옹호자", "중재자", "선의의 옹호자", "정의의 사도",
  "논리학자", "건축가", "과학자", "전략가",
  "활동가", "재기발랄한 활동가", "호기심 많은 예술가", "모험을 즐기는 사업가",
  "사업가", "경영자", "수호자", "현실주의자",
  "용감한 수호자", "열정적인 중재자",
  "The Inspector", "The Protector", "The Counselor", "The Mastermind",
  "The Crafter", "The Composer", "The Healer", "The Architect",
  "The Dynamo", "The Performer", "The Champion", "The Visionary",
  "The Supervisor", "The Provider", "The Teacher", "The Commander",
];
export const ALLOWED_IN_TRUST_NOTICE = ["MBTI", "Myers-Briggs"];
```

`scanRestrictedTerms(text)`: RESTRICTED_TERMS 각 항목을 `escapeRegExp`로 이스케이프 후 RegExp 생성. 영어 terms는 `gi` 플래그(case-insensitive), 한국어는 `g` 플래그(exact match).

`isTextClean(text, opts?)`: `opts.allowTrustNotice=true`이면 ALLOWED_IN_TRUST_NOTICE 항목을 스캔 제외. 반환: `boolean`.

### Dependency DAG (구현 순서 전체)

```
DB layer (Cycle 2 완료 — 115 pass 기준)
        │
        ├─── [Step 1] quality/speedAnalyzer.ts  ──── pure, 독립
        │           quality/botDetector.ts       ──── pure, 독립
        │
        ├─── [Step 2] scoring/domainCalculator.ts ─── pure
        │           scoring/normalizer.ts         ─── pure
        │           scoring/typeClassifier.ts      ─── pure
        │           scoring/reliabilityAdjuster.ts ─── pure
        │           scoring/policyChecker.ts       ─── pure
        │                     │
        │             [Step 3] profiles/toneFilter.ts          ─── pure
        │                     profiles/typeContentData.ts      ─── TS 상수
        │                     profiles/typeContentService.ts   ─── D1
        │                     profiles/composer.ts             ─── D1
        │                               │
        │                     [Step 4] insights/*Module.ts (×5) ── pure
        │                              insights/explanationBuilder.ts ─ pure
        │                              insights/contextEngine.ts      ─ D1
        │
        ├─── [Step 5] compliance/restrictedTerms.ts   ─── pure, 독립
        │           compliance/textPolicyFilter.ts    ─── pure
        │           compliance/deletionProcessor.ts   ─── D1
        │           compliance/snapshot.ts            ─── D1 (seed scan)
        │
        └─── [Step 6] scoring/saga.ts  ←── 모든 Step 2-4 완료 후
                  (Phase A-E orchestrator)
                          │
                  [Step 7] npm test — 전체 369 pass 확인
```

### 누적 Pass 진행 요약

| Step 완료 후 | Pass | Fail |
|-------------|------|------|
| 시작 (RED) | 115 | 254 |
| Step 1 완료 | 127 | 242 |
| Step 2 완료 | 189 | 180 |
| Step 3 완료 | 217 | 152 |
| Step 4 완료 | 259 | 110 |
| Step 5 완료 | 322 | 47 |
| Step 6 완료 | 346 | 23 |
| Step 7 (검증) | **369** | **0** |

### 옵션 A — 단일 에이전트 (패턴 D) — **권장**

Step 0 → 1 → 2 → 3 → 4 → 5 → 6 → 7을 하나의 에이전트가 순차 처리한다.

**근거**: scoring → profiles → insights의 의존성 DAG가 strict sequential이므로 병렬화 이점이 제한된다. quality와 compliance는 독립적이나, 단일 에이전트가 컨텍스트를 유지하며 saga 직전(Step 6)까지 모든 선행 의존성을 완성하는 것이 더 안전하다. 총 서비스 수 20+1이 단일 에이전트 컨텍스트 내에서 처리 가능한 범위다.

| 항목 | 단일 에이전트 |
|------|-------------|
| 컨텍스트 공유 | 전 구간 유지 |
| 의존성 관리 | 직접 추적 가능 |
| 진행 속도 | 순차 (병렬 이점 제한) |
| 컨텍스트 80% 위험 | Step 5-6 도달 전 압박 가능 — fallback 옵션 B 활용 |

### 옵션 B — Agent Teams (패턴 E) — 컨텍스트 80% fallback

단일 에이전트 컨텍스트가 80%에 도달하거나 Step 4 완료 이후 압박이 발생할 경우 Agent Teams로 전환한다.

- Member 1: scoring pure 5 (Step 2)
- Member 2: profiles + insights (Step 3-4) — Member 1 완료 후 시작
- Member 3: quality + compliance (Step 1, 5) — 독립 병렬
- Member 4: saga (Step 6) — Member 1+2 완료 후 시작
- 검증 에이전트: Step 7 통합 검증 — Member 1-4 완료 후 시작

**권장: 옵션 A**. 컨텍스트 80% 도달 시에만 옵션 B로 전환.

## Cross-Reference Table

RED 037 § Spec Mapping을 기반으로 Step 컬럼을 추가한 14 RSpec ↔ 18 vitest ↔ Step 매핑:

| Rails Spec 파일 | RSpec 수 | Vitest 파일 | Vitest 수 | 핵심 contract | Step |
|----------------|---------|------------|----------|--------------|------|
| `scoring/domain_calculator_spec.rb` | 9 | `domainCalculator.test.ts` | 10 | `calculateDomainScores(assessment)` → 4 domains. polarity, nil skip. | Step 2 |
| `scoring/normalizer_spec.rb` | 8 | `normalizer.test.ts` | 8 | `normalizeScores(rawScores, responses)` → 0-100\|null. round 1dp. | Step 2 |
| `scoring/type_classifier_spec.rb` | 18 | `typeClassifier.test.ts` | 19 | `classifyType(normalizedScores)` → type_code + axes. ≥50 = high letter. | Step 2 |
| `scoring/reliability_adjuster_spec.rb` | 13 | `reliabilityAdjuster.test.ts` | 13 | Pearson r, Spearman-Brown, 4 flags. | Step 2 |
| `scoring/policy_checker_spec.rb` | 12 | `policyChecker.test.ts` | 12 | 3 block conditions, boundary strict. | Step 2 |
| `profiles/composer_spec.rb` | 8 | `composer.test.ts` | 10 | UPSERT profile, score_vector, ToneFilter, unknown type error. | Step 3 |
| `profiles/tone_filter_spec.rb` | 9 | `toneFilter.test.ts` | 11 | 7 replacement rules + blank/no-match. | Step 3 |
| `insights/context_engine_spec.rb` | 15 | `contextEngine.test.ts` | 22 | 5 contexts × create/context/explanation/suggestions + idempotent. | Step 4 |
| `quality/speed_analyzer_spec.rb` | 6 | `speedAnalyzer.test.ts` | 6 | 3 flags, median, rate. | Step 1 |
| `quality/bot_detector_spec.rb` | 6 | `botDetector.test.ts` | 6 | 3 heuristics, confidence proportion. | Step 1 |
| `compliance/restricted_terms_spec.rb` | 17 | `restrictedTerms.test.ts` | 22 | RESTRICTED corpus, ALLOWED_IN_TRUST_NOTICE. | Step 5 |
| `compliance/text_policy_filter_spec.rb` | 20 | `textPolicyFilter.test.ts` | 20 | content/trust_notice contexts, [REMOVED] replacement. | Step 5 |
| `compliance/deletion_processor_spec.rb` | 12 | `deletionProcessor.test.ts` | 11 | cascade delete, audit_log, deleted_counts. | Step 5 |
| `compliance/snapshot_spec.rb` | 14 | `snapshot.test.ts` | 10 | D1 seed scan, restricted term scan, originality. | Step 5 |
| — (spec 없음) | — | `typeContentService.test.ts` | 7 | locale ko/en fallback, D1 query. | Step 3 |
| — (spec 없음) | — | `explanationBuilder.test.ts` | 5 | ≥2 suggestions → append. | Step 4 |
| — (spec 없음) | — | `insightModules.test.ts` | 15 | 5 modules × 3 cases. | Step 4 |
| R2 Hybrid Pure Saga | — | `saga.test.ts` | 24 | Phase A-E, idempotency, forward-recovery, E2E. | Step 6 |
| **합계** | **147** | | **254** | | |

## Verification Plan

| 검증 항목 | 명령 / 확인 방법 | 합격 기준 |
|----------|----------------|---------|
| 전체 테스트 | `cd apps/workers && npm test` | 0 fail / 369 pass |
| Cycle 2 회귀 | `npx vitest run test/db/` | 115 pass (7 files) |
| Cycle 3 신규 | `npx vitest run test/services/` | 254 pass (18 files) |
| saga idempotency | `saga.test.ts` idempotency group | 동일 assessmentId 2회 실행 → 동일 DB 결과 |
| saga forward-recovery | `saga.test.ts` forward-recovery group | Step 4 throw → status='failed' + audit_log 1행 삽입. Profile/Insight 행 보존 |
| vitest 버전 | `cat apps/workers/package.json \| grep vitest` | `"vitest": "3.0.5"` 확인 |
| Phase B atomic | saga Phase B batch 테스트 | 4 domain_scores UPSERT + assessments status='scored' 동시 완료 |
| Phase E finalize | saga Phase E 테스트 | status='completed' — user-facing 노출 gate 확인 |

## Risks & Mitigations

| # | 리스크 | 심각도 | 원인 | 완화 전략 |
|---|--------|--------|------|----------|
| R1 | saga Step 7 UPSERT 누락 | Critical | `profiles` 테이블 UPSERT에 `ON CONFLICT(assessment_id) DO UPDATE`가 없으면 2회 실행 시 UNIQUE 제약 위반 오류 | schema.ts `uniqueIndex("index_profiles_on_assessment_id")` 이미 확인됨. saga.ts Step 7에 반드시 `ON CONFLICT(assessment_id) DO UPDATE ... RETURNING id` 명시 |
| R2 | restricted_terms corpus 크기 | Medium | corpus가 예상보다 크면 TS 상수 파일이 비대해져 bundle 영향 | Step 0에서 Rails 원본 항목 수 확인 후 결정. 크면 D1 seed 방식으로 전환 (personality_types 테이블 패턴 참조) |
| R3 | type_content locale 데이터 누락 | Medium | 16 types × 2 locales 이식 시 일부 type 누락 또는 locale key 오타 | `server/db/seeds.rb` 전체 Read 후 체계적으로 이식. typeContentData.ts에 총 32 항목 확인 |
| R4 | snapshot Phase 2 carryover | Low | snapshot.ts가 Cycle 2 D1 seed 스캔 의존 — Cycle 2 seed 데이터가 없으면 snapshot 테스트 실패 | Cycle 2 seed.test.ts pass 확인 후 진행 (이미 Step 7에서 회귀 확인 포함) |
| R5 | vitest 갭 (miniflare 포트 충돌) | Low | `@cloudflare/vitest-pool-workers`가 vitest 3.2.4에서 Workers 런타임 인스턴스 포트 충돌 간헐 발생 | Step 0에서 vitest 3.0.5 pin. 미해결 시 `--pool=forks` 또는 테스트 파일 분할 실행 |
| R6 | D1 batch INSERT 동작 차이 | Low | miniflare D1 batch에서 `RETURNING` 절 지원 여부가 CloudFlare Workers 로컬과 다를 수 있음 | saga Step 7 구현 전 miniflare 버전의 `RETURNING` 지원 확인 (현재 vitest-pool-workers 기반 미니플레어에서 RETURNING 지원됨 — RED phase saga.test.ts fixture 패턴 참조) |

## References

| 문서 | 경로 | 용도 |
|------|------|------|
| RED 037 | `docs/6_backend/02_cf_workers_rebuild/037_TDDRed_cycle3_services.md` | Spec Mapping, Saga Test Details, Stub Files, Risks — 본 plan의 핵심 입력 |
| R2 D1 Saga | `docs/6_backend/02_cf_workers_rebuild/009_Research_axis2_d1_saga.md` | § Q4 의사코드 — saga Phase A-E + compensateScoring |
| Brief 021 | `docs/6_backend/02_cf_workers_rebuild/021_Brief_conversion_phase1.md` | Decision 5/10 (saga + TDD), Ideal Criteria |
| Scope 026 | `docs/6_backend/02_cf_workers_rebuild/026_Scope_conversion_phase1.md` | In Scope 6/12/16, Excluded 정의 |
| Synthesis 018 | `docs/6_backend/02_cf_workers_rebuild/018_Synthesis_research_cycle.md` | S-018-F1/F3 schema 결정 사항 |
| Cycle 2 Plan 034 | `docs/6_backend/02_cf_workers_rebuild/034_Plan_cycle2_db.md` | Cross-Reference Table 패턴, Step 구조 템플릿 |
| Cycle 2 Impl 035 | `docs/6_backend/02_cf_workers_rebuild/035_*.md` | Cycle 2 산출 schema/types 참조 |
| DB schema.ts | `apps/workers/src/db/schema.ts` | UNIQUE constraints (profiles, domain_scores, insights) + FK 확인 |
| DB types.ts | `apps/workers/src/db/types.ts` | ScoreVector, AuditMetadata, InsightSuggestion 등 |
| Service stubs | `apps/workers/src/services/` | 현재 stub 파일 — GREEN phase에서 구현체로 교체 대상 |
| Vitest tests | `apps/workers/test/services/` | 18개 test 파일 — GREEN phase 통과 기준 |
| Rails services | `server/app/services/{scoring,profiles,insights,quality,compliance}/` | 원본 계약 (plan 작성 시 RED 037 § Spec Mapping으로 매핑 완료) |
| Rails specs | `server/spec/services/` | RSpec 14개 파일 — vitest 계약 근거 |
