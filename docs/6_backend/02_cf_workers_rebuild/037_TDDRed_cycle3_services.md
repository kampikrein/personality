---
id: "037"
type: tdd-red
title: "Cycle 3 Domain Services Port — RED phase"
created: 2026-04-29
traces_brief: "021"
traces_scope: "026"
traces_research: ["009"]
traces_synthesis: "018"
traces_cycle2_impl: "035"
cycle: 3
phase_scope: "phase-1-conversion"
status: completed
confidence: high
summary: >
  20 services + saga 8 step + RSpec 14 동등성을 검증하는 vitest 테스트 작성.
  Cycle 2 의 115 pass 유지 + 신규 cycle 3 test 254개 모두 fail 확인 (18 test files).
  green phase에서 services 구현 시 통과 예상.
keywords: [tdd-red, services, saga, scoring, insights, profiles, quality, compliance, vitest]
---

## Progress

- [x] Step 1 — Rails specs 정밀 매핑 (14 spec 파일 전수 Read)
- [x] Step 2 — Vitest 디렉토리 구조 결정
- [x] Step 3 — saga 8 step 테스트 (`scoring/saga.test.ts`)
- [x] Step 4 — services 단위 테스트 (5 도메인 × 단위 파일)
- [x] Step 5 — services 디렉토리 stub 파일 생성 (20 stub files)
- [x] Step 6 — fail 확인 (npm test: 115 pass + 254 fail)
- [x] Step 7 — green phase 진입 가이드

## Summary

Rails 20 services (scoring/5 + profiles/3 + insights/7 + quality/2 + compliance/3) 및 Rails spec 14개에 대해 TypeScript vitest 동등성 테스트를 작성했다. R2 Hybrid Pure Saga (D1 only) 8 step 파이프라인 테스트가 핵심이다.

**결과**: Cycle 2 기존 115 tests pass 유지, Cycle 3 신규 254 tests 전부 fail. 모든 stub은 `throw new Error('not implemented')` 패턴으로 RED phase 의도 충족.

테스트 파일 합계: 25 files (7 cycle-2 + 18 cycle-3). 총 369 tests.

## Spec Mapping

Rails 14 spec → Vitest 매핑 표 (RSpec 1:1):

| Rails Spec 파일 | 테스트 수 (RSpec) | 핵심 contract | Vitest 파일 |
|---------------|----------------|-------------|-----------|
| `scoring/domain_calculator_spec.rb` | 9 | `calculateDomainScores(assessment)` → `{ energy, decision_making, relationship, recovery }`. positive/negative polarity, nil skip, empty. | `test/services/scoring/domainCalculator.test.ts` (10 tests) |
| `scoring/normalizer_spec.rb` | 8 | `normalizeScores(rawScores, responses)` → `0-100\|null`. formula: (raw-min)/(max-min)*100, round 1dp. | `test/services/scoring/normalizer.test.ts` (8 tests) |
| `scoring/type_classifier_spec.rb` | 18 | `classifyType(normalizedScores)` → `{ type_code, axes }`. >= 50 → high letter (E/N/F/P), < 50 → low (I/S/T/J). nil → low. | `test/services/scoring/typeClassifier.test.ts` (19 tests) |
| `scoring/reliability_adjuster_spec.rb` | 13 | `adjustReliability(responses)` → `ReliabilityResult`. Pearson r split-half, Spearman-Brown, 4 flag types. | `test/services/scoring/reliabilityAdjuster.test.ts` (13 tests) |
| `scoring/policy_checker_spec.rb` | 12 | `checkPolicy(reliabilityResult)` → `{ blocked, reasons }`. 3 block conditions, boundary values. | `test/services/scoring/policyChecker.test.ts` (12 tests) |
| `profiles/composer_spec.rb` | 8 | `composeProfile(db, assessmentId, typeCode)` → `ComposedProfile`. UPSERT, score_vector, ToneFilter, unknown type error. | `test/services/profiles/composer.test.ts` (10 tests) |
| `profiles/tone_filter_spec.rb` | 9 | `applyToneFilter(text)` → softened string. 7 replacement rules + blank/no-match. | `test/services/profiles/toneFilter.test.ts` (11 tests) |
| `insights/context_engine_spec.rb` | 15 (3×5+3) | `generateInsight(db, profileId, context)` → `InsightResult`. 5 contexts × create/context/explanation/suggestions + invalid + idempotent. | `test/services/insights/contextEngine.test.ts` (22 tests) |
| `quality/speed_analyzer_spec.rb` | 6 | `analyzeSpeed(responses, durationMs?)` → `{ anomaly, flags, median, rate }`. 3 flag types. | `test/services/quality/speedAnalyzer.test.ts` (6 tests) |
| `quality/bot_detector_spec.rb` | 6 | `detectBot(responses)` → `{ bot_suspected, patterns, confidence }`. 3 heuristics, confidence proportion. | `test/services/quality/botDetector.test.ts` (6 tests) |
| `compliance/restricted_terms_spec.rb` | 17 | `scanRestrictedTerms(text)` + `isTextClean(text, opts?)`. RESTRICTED corpus, ALLOWED_IN_TRUST_NOTICE. | `test/services/compliance/restrictedTerms.test.ts` (22 tests) |
| `compliance/text_policy_filter_spec.rb` | 20 | `filterText(text, context?)` → `{ clean, violations, filtered_text }`. content/trust_notice contexts, [REMOVED] replacement. | `test/services/compliance/textPolicyFilter.test.ts` (20 tests) |
| `compliance/deletion_processor_spec.rb` | 12 | `processDeletion(db, requestId)` → `DeletionResult`. cascade delete, audit_log, deleted_counts. | `test/services/compliance/deletionProcessor.test.ts` (11 tests) |
| `compliance/snapshot_spec.rb` | 14 | Seed data compliance: 16 types, restricted term scan, character name originality. | `test/services/compliance/snapshot.test.ts` (10 tests) |

**Rails에 spec 없는 서비스 (contract 직접 분석)**:
- `profiles/type_content_service.rb` → `test/services/profiles/typeContentService.test.ts` (7 tests)
- `insights/{career,learning,collaboration,conflict,recovery}_module.rb` → `test/services/insights/insightModules.test.ts` (15 tests)
- `insights/explanation_builder.rb` → `test/services/insights/explanationBuilder.test.ts` (5 tests)

**saga 전용** (R2 Hybrid Pure Saga):
- `test/services/scoring/saga.test.ts` (24 tests)

## Test Files Created

| 도메인 | 파일 | Tests | 비고 |
|-------|------|-------|------|
| **scoring** | `saga.test.ts` | 24 | 8 step + forward-recovery + e2e (D1 사용) |
| **scoring** | `domainCalculator.test.ts` | 10 | RSpec 9→10 (pure function) |
| **scoring** | `normalizer.test.ts` | 8 | RSpec 8 1:1 (pure function) |
| **scoring** | `typeClassifier.test.ts` | 19 | RSpec 18→19 (pure function) |
| **scoring** | `reliabilityAdjuster.test.ts` | 13 | RSpec 13 1:1 (pure function) |
| **scoring** | `policyChecker.test.ts` | 12 | RSpec 12 1:1 (pure function) |
| **profiles** | `composer.test.ts` | 10 | RSpec 8→10 (D1 사용) |
| **profiles** | `toneFilter.test.ts` | 11 | RSpec 9→11 (pure function) |
| **profiles** | `typeContentService.test.ts` | 7 | spec 없음 → 직접 도출 (D1 사용) |
| **insights** | `contextEngine.test.ts` | 22 | RSpec 15→22 (D1 사용) |
| **insights** | `explanationBuilder.test.ts` | 5 | spec 없음 → 직접 도출 (pure function) |
| **insights** | `insightModules.test.ts` | 15 | spec 없음 → 직접 도출 (pure function) |
| **quality** | `speedAnalyzer.test.ts` | 6 | RSpec 6 1:1 (pure function) |
| **quality** | `botDetector.test.ts` | 6 | RSpec 6 1:1 (pure function) |
| **compliance** | `restrictedTerms.test.ts` | 22 | RSpec 17→22 (pure function) |
| **compliance** | `textPolicyFilter.test.ts` | 20 | RSpec 20 1:1 (pure function) |
| **compliance** | `deletionProcessor.test.ts` | 11 | RSpec 12→11 (D1 사용) |
| **compliance** | `snapshot.test.ts` | 10 | RSpec 14→10 (D1 사용, ERB scan → D1 scan) |

**총 합계**: 18 파일, 254 tests (cycle 3 신규)

## Saga Test Details

### R2 8 Step 명세 (009_Research_axis2_d1_saga.md § Q4 의사코드)

```
Phase A — pure compute (no DB writes):
  Step 1: DomainCalculator → raw_scores (energy, decision_making, relationship, recovery)
  Step 2: Normalizer → normalized_scores (0-100 | null per domain)
  Step 3: TypeClassifier → type_code (4-letter) + axes
  Step 4: ReliabilityAdjuster → reliability_coefficient, consistency_index, speed_flag, etc.

Phase B — D1 batch (atomic):
  Step 5: UPSERT domain_scores × 4 + UPDATE assessment status='scored'
  (ON CONFLICT(assessment_id, domain) DO UPDATE)

Phase C — conditional batch:
  Step 6: PolicyChecker → if blocked: UPDATE domain_scores policy_blocked=1
            + UPDATE assessment status='failed' + INSERT audit_log

Phase D — idempotent step-by-step:
  Step 7: Profile UPSERT (INSERT ... ON CONFLICT(assessment_id) DO UPDATE RETURNING id)
           → R2-F2 필수 보강
  Step 8: Insight UPSERT × 5 contexts (ON CONFLICT(profile_id, context) DO UPDATE)

Phase E — finalize:
  Step 8b: UPDATE assessment SET status='completed' WHERE status='profiled'
```

### Forward-Recovery 보상 절차 (`compensateScoring`)

```
1. UPDATE assessments SET status='failed' WHERE id=? AND status IN ('submitted','scoring','scored','profiled')
2. INSERT audit_log (resource_type='Assessment', action='scoring_compensated')
   → Profile/Insight 행 삭제 안 함 (R2 § Q4: forward-recovery 우선)
   → retry 시 UPSERT가 동일 결과 재생성
   → user-facing은 status='completed' gate
```

### saga 테스트 커버리지

| 테스트 그룹 | 테스트 수 | 내용 |
|-----------|---------|------|
| Phase A-E (각 단계) | 9 | step별 DB 검증 |
| Idempotency | 2 | re-run 동일 결과 |
| Forward-recovery | 4 | compensate + partial preserve |
| E2E | 3 | 정상 완료, assessmentId 반환, 4번 step throw |
| **합계** | **24** | |

## Stub Files

`apps/workers/src/services/` 하위 생성된 stub 파일 목록:

```
src/services/
├── scoring/
│   ├── index.ts               (export 집합)
│   ├── domainCalculator.ts    (throw 'not implemented')
│   ├── normalizer.ts          (throw 'not implemented')
│   ├── reliabilityAdjuster.ts (throw 'not implemented')
│   ├── typeClassifier.ts      (throw 'not implemented')
│   ├── policyChecker.ts       (throw 'not implemented')
│   └── saga.ts                (throw 'not implemented')
├── profiles/
│   ├── index.ts               (export 집합)
│   ├── composer.ts            (throw 'not implemented')
│   ├── toneFilter.ts          (throw 'not implemented')
│   └── typeContentService.ts  (throw 'not implemented')
├── insights/
│   ├── index.ts               (export 집합)
│   ├── contextEngine.ts       (INSIGHT_CONTEXTS 상수 + throw)
│   ├── explanationBuilder.ts  (throw 'not implemented')
│   ├── careerModule.ts        (throw 'not implemented')
│   ├── learningModule.ts      (throw 'not implemented')
│   ├── collaborationModule.ts (throw 'not implemented')
│   ├── conflictModule.ts      (throw 'not implemented')
│   └── recoveryModule.ts      (throw 'not implemented')
├── quality/
│   ├── index.ts               (export 집합)
│   ├── speedAnalyzer.ts       (throw 'not implemented')
│   └── botDetector.ts         (throw 'not implemented')
└── compliance/
    ├── index.ts               (export 집합)
    ├── restrictedTerms.ts     (throw 'not implemented')
    ├── textPolicyFilter.ts    (throw 'not implemented')
    ├── deletionProcessor.ts   (throw 'not implemented')
    └── snapshot.ts            (throw 'not implemented')
```

**합계**: 6 index.ts + 20 stub service files = 26 files

## Test Results

첫 번째 실행 (정상 동작 확인됨):

```
Test Files  18 failed | 7 passed (25)
     Tests  254 failed | 115 passed (369)
  Start at  16:28:25
  Duration  4.17s (transform 644ms, setup 10.94s, collect 886ms, tests 25.73s)
```

**Cycle 2 pass (7 files, 115 tests)**:
- `test/db/seed.test.ts` ✓ (9 tests)
- `test/db/json_columns.test.ts` ✓ (11 tests)
- `test/db/migrations.test.ts` ✓
- `test/db/schema.test.ts` ✓
- `test/db/unique_constraints.test.ts` ✓
- `test/db/foreign_keys.test.ts` ✓
- `test/db/user_encryption.test.ts` ✓

**Cycle 3 fail (18 files, 254 tests)**: 모든 fail 원인 = `Error: not implemented` (의도된 RED phase). Cycle 2 tests는 영향 없음.

참고: 두 번째 이후 실행 시 miniflare Workers 런타임 포트 연결 오류가 간헐적으로 발생함 (`Can't assign requested address`). 이는 동시 Workers 런타임 인스턴스 수 초과로 인한 것으로, 잠시 후 재실행하면 정상 동작. 첫 번째 실행 결과(254 fail + 115 pass)가 기준값.

## Implementation Hints for Green Phase

### 5 도메인 그룹별 service 파일 매핑

**scoring/** (Pure compute — 먼저 구현):
```
domain_calculator.rb → domainCalculator.ts   (DOMAINS 상수, polarity 로직)
normalizer.rb        → normalizer.ts          (proportional range, round 1dp)
type_classifier.rb   → typeClassifier.ts      (4 axis threshold 50, letter map)
reliability_adjuster.rb → reliabilityAdjuster.ts (Pearson r, Spearman-Brown, 4 flags)
policy_checker.rb    → policyChecker.ts       (3 block conditions, boundary strict)
```

**saga.ts** (Phase A-E orchestration — scoring 5개 완료 후):
- `runScoringPipeline(db, assessmentId)` → 8 step 순차 실행
- `compensateScoring(db, assessmentId)` → status='failed' + audit_log

**profiles/** (scoring 완료 후):
```
tone_filter.rb         → toneFilter.ts         (7 regex replacements, case-preserve)
type_content_service.rb → typeContentService.ts (locale ko/en fallback, D1 query)
composer.rb            → composer.ts           (UPSERT profile + score_vector + ToneFilter)
```

**insights/** (profiles 완료 후):
```
explanation_builder.rb → explanationBuilder.ts (enrich: ≥2 suggestions → append)
{career,learning,collaboration,conflict,recovery}_module.rb → *Module.ts (pure compute)
context_engine.rb → contextEngine.ts (dispatcher + ExplanationBuilder + insight UPSERT)
```

**quality/** (독립 — 병렬 구현 가능):
```
speed_analyzer.rb → speedAnalyzer.ts (3 flags, median calculation)
bot_detector.rb   → botDetector.ts   (3 heuristics, confidence proportion)
```

**compliance/** (독립 — 병렬 구현 가능):
```
restricted_terms.rb    → restrictedTerms.ts    (RESTRICTED corpus, ALLOWED_IN_TRUST_NOTICE)
text_policy_filter.rb  → textPolicyFilter.ts   (context enum, [REMOVED] replacement)
deletion_processor.rb  → deletionProcessor.ts  (cascade delete, audit_log, counts)
snapshot.ts            → snapshot.ts           (D1 seed scan + originality check)
```

### saga 8 step 구현 시 중요 포인트

1. **Step 5 UPSERT SQL** (domain_scores):
   ```sql
   INSERT INTO domain_scores (...) VALUES (...)
   ON CONFLICT(assessment_id, domain) DO UPDATE SET ...
   ```

2. **Step 7 UPSERT SQL** (profiles — R2-F2):
   ```sql
   INSERT INTO profiles (...) VALUES (...)
   ON CONFLICT(assessment_id) DO UPDATE SET ...
   RETURNING id
   ```

3. **Step 8 UPSERT SQL** (insights):
   ```sql
   INSERT INTO insights (profile_id, context, ...) VALUES (...)
   ON CONFLICT(profile_id, context) DO UPDATE SET ...
   ```

4. **idempotency guard**: `WHERE status='submitted'` 조건으로 중복 실행 차단

### ToneFilter 7 규칙 (Rails 원본 그대로 이식)

```ts
const replacements = [
  { pattern: /you are/gi, replacement: 'you tend toward' },
  { pattern: /always/gi,  replacement: (m) => m[0] === m[0].toUpperCase() ? 'Often' : 'often' },
  { pattern: /never/gi,   replacement: (m) => m[0] === m[0].toUpperCase() ? 'Rarely' : 'rarely' },
  { pattern: /can't /gi,  replacement: 'may find challenging ' },
  { pattern: /unable to/gi, replacement: 'may find it challenging to' },
  { pattern: /better than /gi, replacement: '' },
  { pattern: /worse than /gi,  replacement: '' },
];
// 마지막: 이중 공백 collapse
text = text.replace(/  +/g, ' ');
```

### RestrictedTerms corpus (Rails 원본 그대로)

```ts
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

### 의존성 그래프 (구현 순서)

```
DB layer (Cycle 2 — 완료)
    ↓
scoring/* (pure compute: domainCalculator → normalizer → typeClassifier → reliabilityAdjuster → policyChecker)
    ↓
scoring/saga.ts (orchestration)
    ↓
profiles/toneFilter.ts (pure) → profiles/typeContentService.ts (D1)
    ↓
profiles/composer.ts (D1 + saga step 7)
    ↓
insights/*Module.ts (pure) → insights/explanationBuilder.ts (pure)
    ↓
insights/contextEngine.ts (D1 + saga step 8)
    ↓
[병렬] quality/speedAnalyzer.ts, quality/botDetector.ts (pure)
[병렬] compliance/restrictedTerms.ts (pure) → compliance/textPolicyFilter.ts (pure)
         → compliance/deletionProcessor.ts (D1) → compliance/snapshot.ts (D1)
```

## Risks

### R1 — saga step 7 UPSERT 필수 (R2-F2 Critical)
`profiles` 테이블에 `UNIQUE(assessment_id)` 제약이 schema에 있어야 `ON CONFLICT(assessment_id) DO UPDATE`가 동작한다. Cycle 2 schema.ts에 `uniqueIndex("index_profiles_on_assessment_id").on(t.assessmentId)` 확인 완료 → OK.

### R2 — restricted_terms 한국어 corpus 데이터 (Medium)
RED phase에서는 corpus 자체는 empty array stub. GREEN phase에서 Rails 원본 그대로 이식해야 한다. 한국어 Unicode 정규식 `Regexp.escape` → `escapeRegExp` 동등 구현 필요. 대소문자 구분: 영어 terms는 case-insensitive, 한국어는 exact match.

### R3 — deletion_processor transactional 처리 (Major)
Rails는 `ActiveRecord::Base.transaction` 블록으로 원자적 삭제. D1은 `db.batch()` 또는 step-by-step 처리. cascade FK(`ON DELETE CASCADE`)를 이용하면 anonymous_session 삭제만으로 하위 데이터 자동 삭제 가능. 단, audit_log는 CASCADE 대상이 아니므로 별도 INSERT 필요. D1 batch의 한 statement가 FK 참조하는 row를 삭제하는 순서 주의.

### R4 — snapshot service (Low)
Rails snapshot_spec.rb는 ERB 파일 스캔 (`Dir.glob("**/*.erb")`)을 포함하지만, TS 환경에서는 해당 없음. TS Snapshot 서비스는 D1 seed data 스캔으로 범위를 재정의. Trust Notice 검증은 textPolicyFilter의 trust_notice context 테스트로 대체됨.

### R5 — miniflare Workers 런타임 포트 연결 오류 (Low)
25개 test file 동시 실행 시 Workers 런타임 인스턴스 포트 충돌 간헐적 발생. 원인: `@cloudflare/vitest-pool-workers`가 vitest 3.0.x까지만 공식 지원하는데 vitest 3.2.4가 사용 중. 임시 해결: 잠시 후 재실행. 근본 해결: vitest-pool-workers 버전 업그레이드 또는 test 파일 분할. GREEN phase makeplan에서 vitest 버전 pin 검토 필요.

### R6 — saga D1 fixture 충돌 (Low)
saga 테스트는 랜덤 ID (`5000 + Math.random() * 1000`)를 사용하여 setup.ts fixture와의 충돌을 방지했다. 단, ID 공간이 제한적이므로 병렬 실행 시 UNIQUE 충돌 가능성. INSERT OR IGNORE 패턴으로 방어하되, GREEN phase 구현 시 better fixture isolation 전략 검토.

## References

- Brief 021: `docs/6_backend/02_cf_workers_rebuild/021_Brief_conversion_phase1.md`
- Scope 026: `docs/6_backend/02_cf_workers_rebuild/026_Scope_conversion_phase1.md`
- R2 D1 saga: `docs/6_backend/02_cf_workers_rebuild/009_Research_axis2_d1_saga.md`
- Synthesis 018: `docs/6_backend/02_cf_workers_rebuild/018_Synthesis_research_cycle.md`
- Cycle 2 RED: `docs/6_backend/02_cf_workers_rebuild/033_TDDRed_cycle2_db.md`
- Rails services: `server/app/services/{scoring,profiles,insights,quality,compliance}/`
- Rails specs: `server/spec/services/{scoring,profiles,insights,quality,compliance}/`
- Vitest tests: `apps/workers/test/services/`
- Service stubs: `apps/workers/src/services/`
