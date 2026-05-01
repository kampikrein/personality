---
id: "009"
type: research
title: "R2 — D1 transaction → saga 또는 Durable Object"
created: 2026-04-29
traces_brief: "001"
traces_scope: "007"
research_axis: "R2"
summary: >
  ResultsController scoring 8단계의 정합성 보장 전략 결정. D1 batch는 단일
  HTTP round-trip 내 BEGIN..COMMIT으로 atomic이지만 30초·100KB·100KQ
  하드 제약과 read-after-write feedback 부재가 8단계 전체를 한 batch로
  묶을 수 없게 만든다. Durable Object SQLite는 in-process 실시간
  BEGIN/COMMIT을 지원(2025-04-07 GA)하지만 단일 thread 1,000 req/s 천장과
  10GB/object 한도, 글로벌 single-instance routing이 비용·확장
  trade-off를 만든다. 최종 권고: **하이브리드 — D1 batch로 단계 1-5
  (read+score+persist domain_scores)를 atomic 처리, Profile/Insights
  생성을 각 단계별 idempotent batch + saga compensation log로 처리,
  step-7(Profile create) 직전 실패만 user-facing 노출한다**. DO는 본
  도메인에 과잉(scoring은 cross-user lock 불필요·throughput-critical
  아님). saga state는 `assessment.status` enum + audit_log 행으로 추적,
  보상은 `Profile.delete + DomainScore.update_all(blocked)` 두 단계로
  충분.
keywords: [d1, transaction, saga, durable-object, scoring, idempotency, compensation, hono, drizzle]
---

# R2 — D1 transaction → saga 또는 Durable Object

## Research Overview

본 사이클은 Brief 결정 4·Major #3·R12를 닫는 결정 연구다. 8단계 scoring 파이프라인(`server/app/controllers/results_controller.rb:21-67`)을 D1 환경에서 어떻게 정합 보장할지 결정한다.

**조사 대상**:
- D1 batch atomicity 공식 docs + 2025/2026 release notes
- Durable Objects SQLite GA (2025-04-07) docs + storage API
- Drizzle D1 transaction 이슈 (drizzle-team/drizzle-orm#2463, 2024-06 ~ 2026-04 진행)
- Saga 패턴 정형 정의 (microservices.io, learn.microsoft.com)
- ResultsController 원본 8단계 + 각 service의 부수효과 분석

**스코프 외**: D1 read replication(R3 별도 risk), Hyperdrive(외부 PG, Brief Out of Scope 2).

## Q1 — D1 batch atomicity 정확한 경계

### 공식 문서 인용 (1차 출처)

> "Batched statements are SQL transactions. If a statement in the sequence fails, then an error is returned for that specific statement, and it aborts or rolls back the entire sequence."
> — `developers.cloudflare.com/d1/worker-api/d1-database/`

> "D1 operates in auto-commit. Our implementation guarantees that each statement in the list will execute and commit, sequentially, non-concurrently."
> — 같은 페이지 (D1 Database API reference)

> "if you try running BEGIN TRANSACTION in D1 you'll get an error … only one write transaction can be open at once, meaning that if D1 permitted BEGIN TRANSACTION, any one Worker request, anywhere in the world, could effectively block your whole database."
> — `blog.cloudflare.com/whats-new-with-d1` (architectural rationale, 2022-09 / 여전히 유효 — D1 PM 2025-03 confirm)

### 정확한 경계

| 차원 | 보장 / 제약 | 출처 |
|------|----------|------|
| **단일 statement** | atomic (SQLite ACID) | SQLite 표준 |
| **`db.batch([s1, s2, …])`** | **단일 transaction에서 BEGIN..COMMIT으로 wrap** — 한 statement 실패 시 전체 rollback | D1 API ref |
| **statement 간 read-after-write feedback** | **불가능** — Worker JS 코드가 batch 중간에 결과를 받아 다음 statement를 결정할 수 없음 (batch는 미리 준비된 statement 배열) | drizzle#2463 (duducpp 시나리오: createdUser.id를 다음 statement에 사용 불가) |
| **`db.exec(multiquery)`** | atomicity 미보장 — "execution stops and further statements are not executed" 단순 stop, 앞 statement는 commit됨 | D1 API ref |
| **`BEGIN TRANSACTION`/`SAVEPOINT` SQL** | **금지** — 명시적 에러 반환. Drizzle `db.transaction()` 사용 시 동일 에러 (2026-04 시점 미해결) | drizzle#2463 |
| **batch size hard limit** | 단일 statement 100 KB, parameter 100개, query duration 합계 30초, queries/invocation 1,000 (Paid) / 50 (Free) | `developers.cloudflare.com/d1/platform/limits/` |
| **개별 statement size 제약** | batch 내 각 statement에 동일 적용 (총합 아님) | 같은 page |

### 결론: D1 batch는 "프리페어된 deterministic SQL 배열" 한정 atomic

`db.batch()`는 prepared statement **배열을 미리 받고 한 round-trip에서 BEGIN..COMMIT으로 실행**한다. 따라서:

1. **가능**: scoring 1-4단계 결과를 JS로 계산한 뒤, 결과 행 N개의 INSERT/UPDATE를 한 batch로 묶기
2. **불가능**: insert 결과로 받은 PK를 다음 statement bind에 사용 (Profile insert → returning id → Insight insert × 5)
3. **불가능**: 외부 API 호출(Profile.composer ToneFilter는 순수함수 → 무관, 다만 향후 LLM tone filter 추가 시 불가)

8단계 전체를 단일 batch로 묶으려면 모든 단계가 prepared SQL 시퀀스여야 하는데, 본 시스템에서는 다음이 불가능:
- 단계 1-4 (raw_score, normalized, classification, reliability)는 **JS 계산**이라 SQL 외 영역 — batch와 무관
- 단계 7 (Profile create)이 **PK 반환** 후 단계 8 (Insight create × 5)에서 사용

→ 8단계는 **여러 batch로 분할 + saga로 단계 간 정합성 보장** 또는 **Durable Object SQLite로 in-process BEGIN/COMMIT** 두 옵션만 남는다.

## Q2 — 8단계 idempotency 분석

원본 코드: `server/app/controllers/results_controller.rb:21-67`.

| 단계 | 작업 | 부수효과 | Idempotency | 근거 |
|------|------|---------|-------------|------|
| **1. DomainCalculator** | 4 도메인 raw_score 계산 | **none** (read-only, in-memory) | ✓ pure | `services/scoring/domain_calculator.rb:27-39` — assessment.responses sum |
| **2. Normalizer** | raw → 0-100 normalize | **none** (read-only) | ✓ pure | `services/scoring/normalizer.rb` (size 72 LOC, 통계 변환만) |
| **3. TypeClassifier** | 4-letter 타입 코드 도출 | **none** (read-only) | ✓ pure | `services/scoring/type_classifier.rb:40-56` — 임계값 비교만 |
| **4. ReliabilityAdjuster** | reliability_coefficient 등 계산 | **none** (read-only) | ✓ pure | `services/scoring/reliability_adjuster.rb:43-59` — Pearson r·split-half |
| **5. domain_scores persist** | `find_or_create_by!(domain:)` × 4행 | **D1 INSERT × 4** | **조건부** (UNIQUE(assessment_id, domain) 필요) | `results_controller.rb:35-44` — find_or_create_by 의미는 `INSERT ... ON CONFLICT(assessment_id, domain) DO UPDATE SET …` |
| **5b. assessment.score!** | status enum: submitted → scored | **D1 UPDATE assessment** | ✓ idempotent (state machine guarded) | AASM/state_machine 가정 — `score!`은 status가 submitted일 때만 |
| **6. PolicyChecker** | reliability 기반 차단 판단 | **none** (read-only) — blocked 시 `domain_scores.update_all(policy_blocked:true)` + `assessment.fail!` | **조건부** — update_all은 idempotent (멱등 set), fail!도 state-guarded | `services/scoring/policy_checker.rb:28-39` + `results_controller.rb:51-55` |
| **7. Profiles::Composer** | Profile 1행 생성 | **D1 INSERT profile** + ToneFilter 호출 (순수) | **불가능 (현재)** — `Profile.create!`은 두 번 호출 시 `assessment_id` UNIQUE 제약 충돌 또는 중복 생성 | `services/profiles/composer.rb:142-153` — 보강 필요: `INSERT ... ON CONFLICT(assessment_id) DO UPDATE` |
| **8. ContextEngine × 5** | Insight 5개 생성 (collaboration/conflict/learning/career/recovery) | **D1 INSERT/UPDATE insight × 5** | ✓ **현재도 idempotent** | `services/insights/context_engine.rb:63-69` — `find_or_initialize_by(context:).save!` 패턴 |
| **8b. assessment.complete!** | status: scored → completed | **D1 UPDATE** | ✓ idempotent (state-guarded) | state machine |

### 정리

- 단계 1-4는 read-only/in-memory → 자유롭게 retry 가능
- 단계 5, 8은 이미 idempotent (`find_or_create_by!`, `find_or_initialize_by`)
- 단계 5b/6/8b는 state machine guard로 idempotent
- **단계 7만 비-idempotent** — TS 이식 시 Drizzle `INSERT ... ON CONFLICT(assessment_id) DO UPDATE` 또는 선검사 후 INSERT 패턴으로 보강하면 전체 8단계 모두 idempotent

→ 8단계 전부 idempotent로 만들 수 있다. 이는 **재실행(forward-recovery)이 안전함**을 의미하며, 보상 트랜잭션의 부담을 크게 줄인다.

## Q3 — Saga vs Durable Object 비교 매트릭스

### 비교 옵션 정의

| Option | 정의 |
|--------|------|
| **A. Pure Saga (D1 only)** | 8단계를 N개 batch로 분할, 각 batch atomic, 실패 시 보상 batch 실행. saga state는 D1 `assessment.status` + `audit_log` 행으로 추적 |
| **B. Durable Object SQLite** | Assessment scoring을 DO 인스턴스에 라우팅, DO 내부 SQLite에서 `ctx.storage.transactionSync()`로 8단계 통합 BEGIN/COMMIT. 결과를 D1으로 별도 sync (또는 DO에 영구 저장) |
| **C. Hybrid (권고)** | 단계 1-5를 D1 batch 1개(read+score 결과 INSERT/UPDATE), 단계 6은 read+conditional batch, 단계 7-8은 idempotent step-by-step + saga compensation log. DO 미사용. |

### 매트릭스

| 차원 | A. Pure Saga (D1) | B. Durable Object SQLite | C. Hybrid (권고) |
|------|------|------|------|
| **Atomicity 보장 단위** | per-batch | 8단계 전체 (in-process BEGIN/COMMIT) | per-batch + idempotent retry |
| **Latency (한국 → CF Seoul → DB)** | D1 round-trip × N batches (~50-150ms each, primary in 한국 외 가능) | DO 단일 round-trip (~1-5ms in-process queries) | D1 batch × 3 (~150-300ms 총합) |
| **Storage 한도** | 10 GB / DB (R2 risk) | 10 GB / DO (GA 2025-04-07) — 1 user 1 DO 시 사실상 무한 | 10 GB / DB (동일) |
| **Throughput 천장** | DB 단일 thread (~1k qps if 1ms queries) | DO 단일 instance 1,000 req/s soft cap | DB 단일 thread |
| **글로벌 routing** | D1 primary + read replica beta (R3) | **DO는 globally singleton** — assessment_id별 DO 인스턴스가 한 region에 위치, 다른 region 접근 시 cross-region hop | D1과 동일 |
| **운영 복잡도 (1인)** | 중간 (saga state 설계 + 보상 함수 작성) | 높음 (DO class 정의 + 라우팅 + ID 전략 + DO ↔ D1 sync) | 낮음 (단계별 idempotent + 단순 보상 2개) |
| **구현 LOC 추정** | ~250 LOC (saga 프레임 + 8 step + 보상 4) | ~350 LOC (DO class + binding + sync 로직 + 8 step) | **~150 LOC** (단계별 idempotent SQL + 보상 2개) |
| **Vitest 테스트 부담** | 중 (saga state machine fixture) | 높음 (`@cloudflare/vitest-pool-workers` DO 마운트 필요, miniflare DO 모킹 한계 — 2025년 시점) | 낮음 (D1 binding 테스트는 표준 패턴) |
| **Cost — Workers paid plan** | D1 reads/writes만 청구 | DO requests + storage (2026-01-07부터 SQLite storage 청구 시작) + duration | D1만 |
| **Failure mode (보상)** | saga compensation log → 명시적 보상 호출 | DO 내부 BEGIN/COMMIT 자동 rollback | 단계 7만 보상 필요 (Profile delete) |
| **User-facing 일관성** | per-batch 단위 일관 — 중간 노출 차단 패턴 필요 | 8단계 전체 atomic — 자연스러운 차단 | `assessment.status`로 판별 — show 액션이 status=completed만 노출 |
| **D1 제약 회피** | 30s/100KB/1k qps에 완전 노출 | DO 내 in-process이므로 회피 | D1 제약 안에서 batch 분할 |
| **Vendor lock-in 심화** | 동일 (CF D1) | **DO 의존 추가** — D1 → SQLite export로는 DO state 백업 불가 (별도 PITR 사용) | 동일 |

### 1인 운영 부담 차원의 결정 가중치

Brief Constraint: "단일 또는 매우 작은 개발팀" + "TypeScript 단일" + "운영 baseline은 In Scope 19".

본 도메인 특성:
- **scoring은 cross-user lock 불필요** — assessment_id별로 독립. DO의 핵심 가치(글로벌 단일 인스턴스 일관성)가 본 도메인에 무관.
- **scoring은 throughput-critical 아님** — 사용자가 검사 1회 제출 시 1회 실행. 1k req/s 천장 무관.
- **scoring 결과는 영구 보관 + 다른 화면(`/results/show`)에서 조회** — DO에 저장하면 D1으로 sync 추가 비용. D1만 사용하면 단일 storage.

→ DO는 본 도메인에 **과잉(over-engineering)**. saga 패턴(D1 only)으로 충분.

## Q4 — 보상 흐름 의사코드 + user-facing 일관성 패턴

### Hybrid (권고) 흐름 의사코드

```ts
// scoring/pipeline.ts
type SagaState = 'submitted' | 'scoring' | 'scored' | 'profiled' | 'completed' | 'failed';

async function runScoringPipeline(db: D1Database, assessmentId: number) {
  // ── Phase A: pure compute (no DB writes) ────────────────────────────────
  const assessment = await loadAssessment(db, assessmentId);
  if (assessment.status !== 'submitted') return;  // idempotent guard

  const rawScores       = DomainCalculator(assessment);          // step 1
  const normalized      = Normalizer(assessment, rawScores);     // step 2
  const classification  = TypeClassifier(normalized);            // step 3
  const reliability     = ReliabilityAdjuster(assessment);       // step 4

  // ── Phase B: domain_scores + status (atomic batch) ──────────────────────
  // step 5 + 5b — single D1 batch, all-or-nothing.
  await db.batch([
    ...Object.entries(normalized).map(([domain, score]) =>
      db.prepare(`
        INSERT INTO domain_scores
          (assessment_id, domain, raw_score, normalized_score,
           reliability_coefficient, consistency_index, speed_flag, policy_blocked)
        VALUES (?, ?, ?, ?, ?, ?, ?, 0)
        ON CONFLICT(assessment_id, domain) DO UPDATE SET
          raw_score = excluded.raw_score,
          normalized_score = excluded.normalized_score,
          reliability_coefficient = excluded.reliability_coefficient,
          consistency_index = excluded.consistency_index,
          speed_flag = excluded.speed_flag,
          policy_blocked = 0
      `).bind(assessmentId, domain, rawScores[domain], score,
              reliability.reliability_coefficient,
              reliability.consistency_index,
              reliability.speed_flag ? 1 : 0)
    ),
    db.prepare(`UPDATE assessments SET status='scored'
                WHERE id=? AND status='submitted'`).bind(assessmentId),
  ]);

  // ── Phase C: policy gate ────────────────────────────────────────────────
  // step 6 — read reliability, decide block, second batch if blocked.
  const policy = PolicyChecker(reliability);
  if (policy.blocked) {
    await db.batch([
      db.prepare(`UPDATE domain_scores SET policy_blocked=1
                  WHERE assessment_id=?`).bind(assessmentId),
      db.prepare(`UPDATE assessments SET status='failed', failure_reason=?
                  WHERE id=? AND status='scored'`).bind(policy.reasons.join(','), assessmentId),
      db.prepare(`INSERT INTO audit_log (resource_type, resource_id, action, metadata, created_at)
                  VALUES ('Assessment', ?, 'scoring_blocked', ?, datetime('now'))`)
        .bind(assessmentId, JSON.stringify(policy.reasons)),
    ]);
    return;  // user-facing: status=failed, /results/show redirects with alert
  }

  // ── Phase D: profile + insights (idempotent step-by-step) ───────────────
  // step 7 — INSERT profile with ON CONFLICT (idempotent)
  let profileId: number;
  try {
    const result = await db.prepare(`
      INSERT INTO profiles (assessment_id, type_code, score_vector, strengths,
                            caution_patterns, suggested_actions, created_at)
      VALUES (?, ?, ?, ?, ?, ?, datetime('now'))
      ON CONFLICT(assessment_id) DO UPDATE SET
        type_code = excluded.type_code,
        score_vector = excluded.score_vector,
        strengths = excluded.strengths,
        caution_patterns = excluded.caution_patterns,
        suggested_actions = excluded.suggested_actions
      RETURNING id
    `).bind(assessmentId, classification.type_code,
            JSON.stringify(buildScoreVector(normalized)),
            JSON.stringify(applyToneFilter(personalityType.strengths)),
            JSON.stringify(applyToneFilter(personalityType.caution_patterns)),
            JSON.stringify(applyToneFilter(generateSuggestedActions(...))))
      .first<{ id: number }>();
    profileId = result!.id;

    await db.prepare(`UPDATE assessments SET status='profiled'
                      WHERE id=? AND status='scored'`).bind(assessmentId).run();
  } catch (err) {
    // Compensation: revert to 'scored' is automatic (no Profile inserted on failure).
    await logFailure(db, assessmentId, 'profile_create_failed', err);
    throw err;
  }

  // step 8 — Insights × 5 contexts. Each idempotent batch.
  const contexts = ['collaboration','conflict','learning','career','recovery'];
  for (const ctx of contexts) {
    const insight = ContextEngine(profile, ctx);  // pure compute
    await db.prepare(`
      INSERT INTO insights (profile_id, context, suggestions, explanation, created_at)
      VALUES (?, ?, ?, ?, datetime('now'))
      ON CONFLICT(profile_id, context) DO UPDATE SET
        suggestions = excluded.suggestions,
        explanation = excluded.explanation
    `).bind(profileId, ctx, JSON.stringify(insight.suggestions), insight.explanation).run();
  }

  // ── Phase E: finalize ────────────────────────────────────────────────────
  await db.prepare(`UPDATE assessments SET status='completed'
                    WHERE id=? AND status='profiled'`).bind(assessmentId).run();
}
```

### 보상 (compensation) 절차

scoring 실패 시 호출되는 forward-recovery 우선 보상:

```ts
async function compensateScoring(db: D1Database, assessmentId: number) {
  // 1. Mark assessment failed (idempotent state guard).
  await db.prepare(`
    UPDATE assessments SET status='failed', failure_reason='scoring_aborted'
    WHERE id=? AND status IN ('submitted','scoring','scored','profiled')
  `).bind(assessmentId).run();

  // 2. Audit (always, for compliance + rollback evidence).
  await db.prepare(`
    INSERT INTO audit_log (resource_type, resource_id, action, metadata, created_at)
    VALUES ('Assessment', ?, 'scoring_compensated', ?, datetime('now'))
  `).bind(assessmentId, JSON.stringify({ reason: 'partial_failure' })).run();

  // NOTE: Profile/Insight rows are NOT deleted — they are idempotent and
  // re-running the pipeline on retry will UPSERT them. Keeping them is safer
  // than deleting (deletion creates a window where retry sees inconsistent state).
  // User-facing show action gates on status='completed'.
}
```

**핵심 결정**: Profile/Insight 행을 **삭제하지 않는다**. 재실행 시 UPSERT가 동일 결과를 만들고, 사용자 화면은 `assessment.status='completed'`만을 노출 트리거로 사용한다 (`results_controller.rb:9-15` 패턴 그대로 — "결과를 생성할 수 없습니다" alert).

### User-facing 일관성 패턴

1. **Status-gated read** — `/results/show`는 `status='completed'`인 assessment만 결과 노출. 다른 status는 "처리 중" 또는 "다시 시도" 안내. (현 Rails 동작 동일)
2. **No partial reveal** — Phase B 끝(`status='scored'`)에서도 사용자에게 결과 미노출. Phase E 완료 후만 노출.
3. **Retry-safe link** — `/results/show?assessment_id=X` 재요청 시 status≠'completed'면 `runScoringPipeline()` 재실행. 모든 단계 idempotent이므로 부분 진행 상태에서 이어서 완료 가능.
4. **Audit trail** — 보상·실패는 `audit_log`로 기록 (Brief In Scope 16.3과 동일 테이블 활용).

## Cross-Analysis

### 의존성 영향

- **Cycle 2 (DB Layer, R1)**: `domain_scores` 테이블에 `UNIQUE(assessment_id, domain)`, `profiles`에 `UNIQUE(assessment_id)`, `insights`에 `UNIQUE(profile_id, context)` 제약 필수. R1 (Drizzle ↔ wrangler 통합) deliverable에 반영해야 함.
- **Cycle 3 (Domain Services, 본 R2)**: 본 결정이 직접 적용. saga state는 별도 라이브러리 도입 없이 `assessment.status` enum + audit_log 행으로 처리.
- **Cycle 8 (Compliance)**: audit_log 테이블이 saga 보상 기록과 GDPR/PIPA audit 양쪽 사용 — 스키마 설계 시 일관 칼럼 사용.

### Brief 결정 매핑

| Brief 항목 | R2 결정 영향 |
|-----------|-------------|
| Decision 4 / In Scope 4 / M3 / R12 | **본 결정으로 종결** — Hybrid (D1 batch + idempotent step-by-step + saga compensation log) 채택 |
| Decision 3 (Drizzle) | Drizzle `db.batch()` 사용. `db.transaction()`은 D1에서 사용 금지 (drizzle#2463 미해결) |
| Constraint "암호화 키 단일 실패점" | scoring은 PII 직접 접근 없음 (assessment_id만 사용) — 영향 없음 |

### 미해결 위험

- **D1 batch 30s 한도**: 현재 8단계 추정 합계 < 1s (4 inserts + 5 updates × ~10ms). 100배 안전 마진. Brief 30K MAU 가정 내 안전.
- **Read-after-write feedback 부재**: Phase D step-by-step에서 보완 (batch 안 함). 약간의 latency 증가 수용.
- **DO 미선택의 future risk**: cross-user concurrency (예: admin이 동시에 같은 assessment를 처리) 시 race condition 가능 — 단, scoring은 sole-trigger (사용자 본인 또는 cron)이고 status guard로 방지.

## Comprehensive Conclusion

### 권고 — Hybrid (Pure Saga, D1 only)

Pure D1 saga 채택. Durable Object 미사용. 8단계는 다음과 같이 분할:
- **Phase A** (1-4): in-memory pure compute, no DB
- **Phase B** (5+5b): D1 batch 1개 (UPSERT × 4 + UPDATE assessment)
- **Phase C** (6): conditional batch (blocked 시 UPDATE × 2 + audit INSERT)
- **Phase D** (7+8): idempotent step-by-step (UPSERT profile + UPSERT insight × 5)
- **Phase E** (8b): final UPDATE assessment

보상은 forward-recovery 우선 — 실패 시 행 삭제 대신 status='failed' 마킹 + audit, 재실행으로 완성. user-facing은 `status='completed'` gate.

### 우선순위 정렬 발견

| ID | Severity | Finding | Action |
|----|----------|---------|--------|
| **R2-F1** | **Critical** | D1 `db.transaction()` (Drizzle 포함) 호출 시 런타임 에러 — 단일 batch 외에는 atomic 보장 수단 없음 | `db.batch()`만 사용. Drizzle은 batch API 사용. SQL `BEGIN`/`SAVEPOINT` 금지 |
| **R2-F2** | **Critical** | 8단계 중 step 7 (Profile create)이 현재 비-idempotent (`Profile.create!`) | TS 이식 시 `ON CONFLICT(assessment_id) DO UPDATE` 패턴 필수. DB 스키마 `UNIQUE(assessment_id)` 제약 추가 |
| **R2-F3** | **Major** | DO SQLite는 본 도메인(scoring)에 cross-user lock 불필요 + low throughput → 과잉 | DO 미선택. ~200 LOC + 운영 학습곡선 절감 |
| **R2-F4** | **Major** | saga state 별도 추적 인프라 도입 시 1인 운영 부담 — 별도 라이브러리(Temporal 등) 불필요 | `assessment.status` enum + `audit_log` 행으로 충분. saga state machine 외부 라이브러리 도입 금지 |
| **R2-F5** | **Major** | 보상 행 삭제(`Profile.delete`) 시 retry window에 inconsistent state 노출 가능 | **Forward-recovery 우선** — 행 삭제 대신 status 마킹 + UPSERT 재실행. user-facing은 status gate |
| **R2-F6** | **Medium** | step 5 `domain_scores` 테이블에 `UNIQUE(assessment_id, domain)` 제약 누락 시 batch UPSERT 불가 | R1 (DB Layer)에서 Drizzle schema에 명시. 본 보고서 Cross-Analysis 참조 |
| **R2-F7** | **Medium** | step 8 `insights` 테이블에 `UNIQUE(profile_id, context)` 제약 누락 시 중복 insight 가능 | R1 deliverable에 반영 |
| **R2-F8** | **Medium** | scoring 30s 한도 초과 시 (예상 < 1s, 100배 마진) 무한 retry loop 가능 | makeplan 단계에서 retry budget(예: 3회) + monitoring alert 정의 |
| **R2-F9** | **Low** | 미래에 ToneFilter/Insights에 외부 LLM 호출 추가 시 batch 외 latency 증가 + 부수효과 idempotency 재검토 필요 | 본 phase 무관. 향후 phase에서 재검토 트리거 |
| **R2-F10** | **Low** | DO를 미래에 도입한다면 (예: realtime collaborative scoring) 본 결정 reversal 비용 | 현 결정 reversal 비용 ~200 LOC + DO 학습. 수용 가능 |

## Recommended Pattern + 근거

**채택**: **Pure Saga (Option C — D1 only Hybrid)**

**근거 4가지**:
1. **8단계 모두 idempotent로 만들 수 있음** (step 7만 schema 보강 필요) — 보상 부담 최소화. forward-recovery로 충분.
2. **DO의 핵심 가치(globally singleton consistent state)가 본 도메인에 무관** — scoring은 assessment_id별 독립, cross-user race 없음.
3. **1인 운영 부담** — saga D1 only는 ~150 LOC, DO는 ~350 LOC + DO ↔ D1 sync + miniflare 테스트 학습. Brief Constraint 정합.
4. **Vendor lock-in 동등 + 백업 우위** — D1 only는 D1 → SQLite export로 데이터 portable (Brief Constraint "D1 → SQLite export 백업 유지" 정합). DO state는 PITR 별도.

## Open Questions (makeplan 위임)

1. **Retry budget**: scoring 실패 시 자동 retry 횟수·간격. (제안: 3회 exponential backoff, makeplan 단계에서 확정)
2. **Audit log volume**: 매 scoring마다 audit 행 1-2개 — 30K MAU × 1 scoring = 30K 행/년. D1 10GB 한도 영향 (~수 MB) 무시 가능 확인 필요.
3. **Concurrent scoring**: admin 도구가 동일 assessment를 재계산하려는 경우 — `status='scored' AND profile EXISTS` 가드로 차단? 또는 force-rescore 플래그? (makeplan)
4. **Vitest 테스트 패턴**: `@cloudflare/vitest-pool-workers`로 D1 binding을 사용할 때 saga 시나리오(부분 실패 → 보상 → retry)를 어떻게 fixture로 표현 — Brief Decision 7 / In Scope 8 makeplan 단계.

## References

### 공식 1차 출처

- D1 Database API reference — `https://developers.cloudflare.com/d1/worker-api/d1-database/`
- D1 Limits — `https://developers.cloudflare.com/d1/platform/limits/`
- D1 Release notes — `https://developers.cloudflare.com/d1/platform/release-notes/`
- D1 Best practices: query — `https://developers.cloudflare.com/d1/best-practices/query-d1/`
- "D1: our quest to simplify databases" (2022 BEGIN TRANSACTION rationale) — `https://blog.cloudflare.com/whats-new-with-d1`
- Durable Objects SQLite Storage API — `https://developers.cloudflare.com/durable-objects/api/sql-storage/`
- Durable Objects Storage API (general) — `https://developers.cloudflare.com/durable-objects/api/storage-api/`
- Durable Objects Limits — `https://developers.cloudflare.com/durable-objects/platform/limits/`
- Durable Objects Pricing — `https://developers.cloudflare.com/durable-objects/platform/pricing/`
- "Zero-latency SQLite storage in every Durable Object" — `https://blog.cloudflare.com/sqlite-in-durable-objects/`
- SQLite in DO GA changelog (2025-04-07) — `https://developers.cloudflare.com/changelog/post/2025-04-07-sqlite-in-durable-objects-ga/`

### 패턴·이슈 추적

- microservices.io — Saga pattern — `https://microservices.io/patterns/data/saga.html`
- learn.microsoft.com — Saga design pattern — `https://learn.microsoft.com/en-us/azure/architecture/patterns/saga`
- Drizzle issue #2463 (D1 transaction) — `https://github.com/drizzle-team/drizzle-orm/issues/2463`
- Cloudflare workers-sdk #2733 (D1 transaction support) — `https://github.com/cloudflare/workers-sdk/issues/2733`

### 프로젝트 내 참조

- `server/app/controllers/results_controller.rb:1-73` (8단계 원본 파이프라인)
- `server/app/services/scoring/domain_calculator.rb` (step 1)
- `server/app/services/scoring/normalizer.rb` (step 2)
- `server/app/services/scoring/type_classifier.rb` (step 3)
- `server/app/services/scoring/reliability_adjuster.rb` (step 4)
- `server/app/services/scoring/policy_checker.rb` (step 6)
- `server/app/services/profiles/composer.rb` (step 7)
- `server/app/services/profiles/tone_filter.rb` (순수 함수, ToneFilter)
- `server/app/services/insights/context_engine.rb` (step 8 entry)
- Brief: `docs/6_backend/02_cf_workers_rebuild/001_Brief_cf_workers_rebuild.md`
- Scope: `docs/6_backend/02_cf_workers_rebuild/007_Scope_cf_workers_rebuild.md`
