---
id: "014"
type: eval
title: "Eval R2 — D1 saga vs Durable Object"
created: 2026-04-29
traces_research: "009"
verdict: sufficient
depth_score: 6
k_score: 3
c_score: 3
cycle: 2
phase: research
---

# Eval R2 — D1 saga vs Durable Object

## Verdict + Depth

| 차원 | 점수 | 근거 |
|------|------|------|
| **K-score** | 3 / 3 | Q1–Q4 모두 완전 답변. 공백 없음. |
| **C-score** | 3 / 3 | D1 batch 경계, DO SQLite, saga 패턴, 8단계 idempotency, 보상 흐름, user-facing 일관성 — 모든 관련 영역 탐색 완료. |
| **Depth Score** | **6 / 6** | — |
| **Verdict** | **PROCEED** | K≥2, C≥2 → SUFFICIENT. 다음 사이클(impl cycle 3 — Domain Services Port)으로 진행. |

### Rationale

R2 연구 산출물(009)은 Brief Decision 4 / Major #3 / R12 / In Scope 4를 단일 문서에서 종결한다. D1 환경에서 8단계 scoring 정합성 보장 전략이 명확한 winner(Pure Saga, D1 only Hybrid)로 결정되었으며, Cycle 3 구현 즉시 적용 가능한 TypeScript 의사코드와 보상 절차까지 포함한다. 1차 출처 인용 11건 이상, 비교 매트릭스 11개 차원 — 정량·정성 모두 기준 초과.

---

## Q1–Q4 커버리지

### Q1 — D1 batch atomicity 정확한 경계

**커버리지**: 완전 (3/3)

- `db.batch([s1, s2, …])`가 단일 transaction에서 BEGIN..COMMIT으로 wrap됨 — 공식 D1 API ref 직접 인용
- read-after-write feedback 불가능 — drizzle#2463 이슈 링크 + 구체적 시나리오(createdUser.id 사용 불가) 확인
- `BEGIN TRANSACTION` / Drizzle `db.transaction()` 금지 이유 — CF blog (2022-09) 아키텍처 rationale 1차 인용
- batch 하드 제약(30초·100KB·100KQ) + `db.exec()` atomicity 미보장 상세까지 커버
- **결론 도출**: "8단계 전체를 단일 batch로 묶을 수 없음 → 여러 batch 분할 + saga 또는 DO" 명확히 도출

### Q2 — 8단계 idempotency 분석

**커버리지**: 완전 (3/3)

- 8단계 × 4컬럼(작업·부수효과·Idempotency·근거) 테이블 제공
- 단계 1-4: read-only/in-memory — 자유롭게 retry 가능
- 단계 5, 8: `find_or_create_by!` / `find_or_initialize_by` — 이미 idempotent
- 단계 5b/6/8b: state machine guard — idempotent
- **단계 7만 비-idempotent** (`Profile.create!`) — 근거·보강 방법 명시 (`ON CONFLICT(assessment_id) DO UPDATE`)
- "8단계 전부 idempotent로 만들 수 있다 → forward-recovery가 안전함" 결론까지 연결

### Q3 — Saga vs DO 비교 매트릭스

**커버리지**: 완전 (3/3)

- 3개 옵션(Pure Saga·DO SQLite·Hybrid) × 11개 차원 매트릭스 제공
- 비교 차원: atomicity 단위, latency, storage 한도, throughput, 글로벌 routing, 운영 복잡도, 구현 LOC, Vitest 테스트 부담, cost, failure mode, vendor lock-in
- **Winner: Pure Saga (D1 only Hybrid)** — 근거 4가지 명시
  1. 8단계 모두 idempotent로 만들 수 있음 (step 7 schema 보강)
  2. DO 핵심 가치(globally singleton)가 본 도메인 무관
  3. 1인 운영 부담: ~150 LOC vs ~350 LOC (DO)
  4. D1 only → D1 → SQLite export 백업 portable (Brief Constraint 정합)
- DO가 과잉(over-engineering)인 근거 충분: cross-user lock 불필요, low throughput, sync 추가 비용

### Q4 — 보상 흐름 의사코드 + user-facing 일관성 패턴

**커버리지**: 완전 (3/3)

- TypeScript `runScoringPipeline()` 의사코드 — Phase A(pure compute) → B(D1 batch) → C(policy gate) → D(step-by-step) → E(finalize) 5단계로 구조화
- `compensateScoring()` 의사코드 — forward-recovery 전략 (행 삭제 안 함, status 마킹 + audit)
- user-facing 일관성 4패턴: status-gated read / no partial reveal / retry-safe link / audit trail
- 핵심 결정 근거("Profile/Insight 행을 삭제하지 않는다 — UPSERT 재실행이 동일 결과") 포함

---

## 1차 출처 품질

인용 기준 ≥5 충족 여부: **YES (11건 CF 공식 + 4건 패턴/이슈)**

| # | 출처 | 유형 | 관련 질문 |
|---|------|------|---------|
| 1 | `developers.cloudflare.com/d1/worker-api/d1-database/` | CF 공식 API ref | Q1 batch atomicity |
| 2 | `developers.cloudflare.com/d1/platform/limits/` | CF 공식 Limits | Q1 하드 제약 |
| 3 | `developers.cloudflare.com/d1/platform/release-notes/` | CF 공식 Release | Q1 변경 이력 |
| 4 | `developers.cloudflare.com/d1/best-practices/query-d1/` | CF 공식 Best practices | Q1 best practice |
| 5 | `blog.cloudflare.com/whats-new-with-d1` | CF 공식 Blog | Q1 BEGIN TRANSACTION 금지 rationale |
| 6 | `developers.cloudflare.com/durable-objects/api/sql-storage/` | CF 공식 DO SQLite API | Q3 DO 옵션 |
| 7 | `developers.cloudflare.com/durable-objects/api/storage-api/` | CF 공식 DO Storage | Q3 DO 옵션 |
| 8 | `developers.cloudflare.com/durable-objects/platform/limits/` | CF 공식 DO Limits | Q3 DO throughput |
| 9 | `developers.cloudflare.com/durable-objects/platform/pricing/` | CF 공식 DO Pricing | Q3 DO cost |
| 10 | `blog.cloudflare.com/sqlite-in-durable-objects/` | CF 공식 Blog | Q3 DO SQLite 선언 |
| 11 | `developers.cloudflare.com/changelog/post/2025-04-07-sqlite-in-durable-objects-ga/` | CF 공식 Changelog (GA) | Q3 DO SQLite GA 날짜 |
| 12 | `microservices.io/patterns/data/saga.html` | 업계 표준 패턴 정의 | Q4 saga 정형 정의 |
| 13 | `learn.microsoft.com/azure/architecture/patterns/saga` | MS Azure 아키텍처 가이드 | Q4 saga 정형 정의 |
| 14 | `github.com/drizzle-team/drizzle-orm/issues/2463` | 오픈소스 이슈 트래커 | Q1 read-after-write 제약 |
| 15 | `github.com/cloudflare/workers-sdk/issues/2733` | CF 공식 이슈 트래커 | Q1 D1 transaction 지원 상태 |

**평가**: 출처 다양성 우수. CF 공식 docs(11) + 업계 표준(2) + 오픈소스 이슈(2). 2026-04 시점 drizzle#2463 미해결 상태 명시 — 출처 신선도 적절.

---

## Recommended Changes

```yaml
recommended_changes: []
# Verdict: PROCEED — 추가 조치 없음. Cycle 3 (Domain Services Port) impl로 진행.
```

---

## Cross-axis Observations — R1 schema UNIQUE 제약 영향

R2 연구는 R1 deliverable에 아래 3개 UNIQUE 제약 추가를 명시적으로 요구한다. 이는 R2의 saga 전략이 DB 스키마에 직접 의존하는 사항이므로 **Cycle 2 (DB Layer) impl 전에 R1 eval이 이를 확인해야 한다**.

| 테이블 | 제약 | 요구 이유 | Finding ID |
|--------|------|---------|-----------|
| `domain_scores` | `UNIQUE(assessment_id, domain)` | Phase B batch UPSERT (`ON CONFLICT`) 필수 | R2-F6 (Major) |
| `profiles` | `UNIQUE(assessment_id)` | step 7 idempotent INSERT (`ON CONFLICT`) 필수 | R2-F2 (Critical) |
| `insights` | `UNIQUE(profile_id, context)` | step 8 idempotent INSERT (`ON CONFLICT`) 필수 | R2-F7 (Major) |

**영향 경로**: R1 스키마에 이 제약이 누락되면 Cycle 3 (Domain Services Port)의 saga 파이프라인이 런타임에서 UPSERT 실패함. R1 eval에서 이 3개 제약의 Drizzle schema 반영 여부를 확인해야 함.

**추가 cross-axis**: Cycle 8 (Compliance) — R2에서 saga 보상 기록에 `audit_log` 테이블을 사용한다. Cycle 8의 GDPR/PIPA audit 스키마와 동일 테이블을 공유하므로 칼럼 일관성(resource_type, resource_id, action, metadata, created_at) 확인 필요.

---

## Findings Preserved

R2 연구에서 도출된 주요 Finding을 Cycle 3 makeplan 단계 전달용으로 보존한다.

| ID | Severity | Finding | Cycle 3 Action |
|----|----------|---------|----------------|
| R2-F1 | Critical | `db.transaction()` (Drizzle 포함) 런타임 에러 | `db.batch()`만 사용. SQL `BEGIN`/`SAVEPOINT` 금지 |
| R2-F2 | Critical | step 7 (Profile create) 비-idempotent (`Profile.create!`) | `ON CONFLICT(assessment_id) DO UPDATE` 패턴 필수 — R1 schema UNIQUE 제약 선행 |
| R2-F3 | Major | DO SQLite 과잉 — cross-user lock 불필요, low throughput | DO 미채택. ~200 LOC + DO ↔ D1 sync 학습 절감 |
| R2-F4 | Major | saga state 별도 라이브러리(Temporal 등) 불필요 | `assessment.status` enum + `audit_log` 행으로 충분 |
| R2-F5 | Major | 보상 행 삭제 시 retry window inconsistency | forward-recovery — 행 삭제 대신 status 마킹 + UPSERT 재실행 |
| R2-F6 | Medium | `domain_scores` UNIQUE(assessment_id, domain) 누락 시 batch UPSERT 불가 | R1 deliverable에 반영 (cross-axis 영향) |
| R2-F7 | Medium | `insights` UNIQUE(profile_id, context) 누락 시 중복 insight | R1 deliverable에 반영 (cross-axis 영향) |
| R2-F8 | Medium | scoring 30s 한도 초과 시 무한 retry 가능 (현재 추정 < 1s, 100배 마진) | Cycle 3 makeplan에서 retry budget(3회 exponential backoff) 정의 |
| R2-F9 | Low | 미래 ToneFilter/Insights에 외부 LLM 추가 시 idempotency 재검토 필요 | 현재 phase 무관 — 향후 phase 트리거로 기록 |
| R2-F10 | Low | DO 미래 도입 reversal 비용 ~200 LOC + 학습 | 수용 가능 — 현 결정 유지 |

**Open Questions (Cycle 3 makeplan 위임)**:
1. Retry budget: 실패 시 자동 retry 횟수·간격 (제안: 3회 exponential backoff)
2. Audit log volume: 30K MAU × 1 scoring = 30K 행/년 — D1 10GB 영향 확인
3. Concurrent scoring: admin 재계산 도구의 force-rescore 플래그 여부
4. Vitest 테스트 패턴: saga 부분 실패 → 보상 → retry 시나리오 fixture 방법

---

```
== Eval: Research Cycle 2 Complete ==
Depth Score: 6/6 (K:3 C:3)
Critical gate: PASS
Verdict: PROCEED (SUFFICIENT)
Findings: D:0 C:0 A:0 S:3 (cross-axis UNIQUE 제약 3건)
Document: /Users/kampikrein/A/personality/docs/6_backend/02_cf_workers_rebuild/014_Eval_R2.md
```
