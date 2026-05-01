---
id: "027"
type: critique
title: "Scope 026 Critique — Brief↔Scope 매핑 정합성"
created: 2026-04-29
status: completed
perspective: "scope_mapping_fidelity"
target: "026"
confidence: high
summary: >
  Scope 026은 Brief 021의 Phase 1 narrowing을 큰 구조에서 정확히 번역(7 활성 사이클 +
  tail, TDD 적용 사이클, 의존성, 영역 확장 흡수)했으나, **In Scope 2 (로컬 검증 인프라)
  미매핑 1건 Critical**, deferred 19항목(Out of Scope 10 + Carryover § 2.3 9)이 사이클 레벨
  참조로만 처리되어 인지 불완전(Major) 등 silent loss가 존재한다. 권고 13건(C1 즉시,
  M1-M6 Cycle 매핑 보강, m1-m3 frontmatter 일관성).
keywords: [critique, scope-026, brief-mapping, coverage, scope-creep]
---

# Scope 026 Critique — Brief↔Scope 매핑 정합성

## Executive Summary

Scope 026은 Brief 021의 Phase 1 narrowing 결과를 7 활성 사이클(1, 2, 3, 4, 5, 6, 8) + tail(10_tail, 99_retro)로 구체화한다. **macro structure는 정합적**: TDD 적용 사이클(Decision 10), Cycle 6 영역 확장(Decision 4 + EV-015-S1), R4 분리 컬럼 + R1 envelope 통합(Decision 3 + S-018-F1), Pipeline DB 재사용 + Cycle 7/9/10 interrupted(Decision 14 + C2)이 각각 사이클 frontmatter / note / 영역 식별 표에 추적 가능하게 반영됐다.

다만 **micro mapping에서 silent loss 1건 Critical + scope-level coverage gap 다수 Major**가 존재한다. 가장 심각한 누락은 **In Scope 2 "로컬 검증 인프라" (wrangler dev --local + vitest-pool-workers 운영 모델)** 가 Scope 026의 어떤 사이클 frontmatter `in_scope` 필드에도 매핑되지 않은 점이다 — 이는 Brief 021 Decision 2와 Constraints의 핵심 운영 모델인데도 cycle 단위 owner가 부재해 책임 공백이 생긴다. 또한 Brief 021 Out of Scope 10항목 + Phase 2 Carryover § 2.3 9항목(=합 19항목)이 Scope 026에서는 "Brief 021 Out of Scope"·"§ 2.3 9개 항목"의 인용 한 줄로만 처리되어, scope reader가 deferred 항목을 1:1 인지하려면 Brief 021을 다시 펼쳐야 한다.

## Strengths

1. **Macro 매핑 충실**: Brief 021 In Scope 9개 중 7개(1, 3, 4, 5, 6, 7, 8)가 cycle frontmatter `in_scope` + 영역 식별 표 + 의존성 맵 + 실행 순서표에 일관 반영됨. In Scope 9(Test Migration 분산)는 의도대로 Cycles 3·4·5·6·8 모두에 [9]로 분산 매핑되어 Brief 021의 "사이클 3·4·5·6·8에 분산" 명시와 정확히 일치.
2. **Decision 14 + C2 충실 흡수**: Pipeline DB 정렬 상태 코드블록(seq 35-38, 43-45, 46-48, 49-51)이 Brief 021 Decision 14·Anchor 12 문구를 그대로 복원. `pipeline.sh edit` 적용 완료 표기가 retraceable.
3. **Cycle 6 영역 확장(Decision 4 + S-018-F6) 보존**: Cycle 6 area 명("Admin UI + Public Assessment Flow SSR (영역 확장)") + note("18 ERB + 8 Stimulus 공개 평가 흐름") + 영역 식별 표 + 파일 목록 추정(`assessments/*.ts` (~18), `controllers/*.js`(8))가 모두 EV-015-S1 흡수를 명시.
4. **Decision 3(R4+R1) 통합 패턴**: Cycle 2 note ("R4 user 분리 컬럼 통합") + 영역 식별 표 ("R4 user 분리 컬럼 + R2 UNIQUE 제약 + R1 envelope") + 의존 관계 ("R2 + R1 + R4 통합 결정") 3 곳에서 일관 반복으로 정합.
5. **TDD 적용 사이클(Decision 10) 정확**: cycles[].tdd_red 플래그가 Brief Decision 10 ("Cycles 2-6, 8")과 1:1 일치. Cycle 1·10_tail·99_retro만 false. 실행 순서 표 TDD 컬럼도 동일.
6. **Cycle별 makeplan 입력 표**: Synthesis 018 R1/R2/R3/R4 + Synthesis 025 M1/M3/M5/M11 + EV-015-S1까지 cycle별 행으로 추적 가능. M1(JWKS DI), M3(CSRF caveat), M11(JWKS rotation fixture)이 Cycle 4 행에 명시.
7. **scope creep 0**: 검토 결과, Brief 021에 없는 새 결정·새 In Scope 도입 없음. Cycle 1의 "Foundation 한정형" 명명도 Brief 021 In Scope 1과 동어.

## Weaknesses

| # | Severity | Finding | Evidence | Recommendation |
|---|---------|---------|----------|----------------|
| **C1** | **Critical** | **In Scope 2 (로컬 검증 인프라) 미매핑** — Brief 021 In Scope 2 ("wrangler dev --local --persist + vitest-pool-workers + miniflare DX")가 Scope 026의 어떤 cycle frontmatter `in_scope`에도 등장하지 않음. cycles[1].in_scope=[1], [2].in_scope=[3], 나머지 모두 In Scope 2 미포함. 영역 식별 표 7행에도 누락. | Scope 026 line 37·44·50·58·64·71·78·85·92 frontmatter; line 148-154 영역 식별 표 (In Scope 컬럼: 1/3/4,9/5,9/6,9/7,9/8,9 — `2` 부재) | Cycle 1 in_scope를 `[1, 2]`로 보강. 영역 식별 표 행 1 "Brief 021 In Scope" 컬럼을 "1, 2"로 갱신. wrangler dev --local + vitest-pool-workers 베이스 셋업이 Cycle 1 Foundation 한정형의 사실상 산출물이므로 매핑 명료화 필요. |
| **M1** | Major | **Out of Scope 10항목 미열거** — Brief 021 Out of Scope 10항목(Toss, Cutover safety, Cutover execution, Production monitoring, Foundation 외부 자원, CF Access 실 SSO, D1 cron, archive 이동, 글로벌 결제, 새 도메인 기능)이 Scope 026 deferred 섹션에서 "Cycle 7 Toss / Cycle 9 Cutover safety / Cycle 10 makeplan/impl/verify / Phase 2 Carryover § 2.3 9개 항목"의 4줄 압축으로만 표기. Out of Scope 10항목 중 4·5·6·7·9·10 (Production monitoring, 외부 자원, 실 SSO, D1 cron, 글로벌 결제, 새 도메인)이 cycle 매핑되지 않는 항목인데도 별도 인덱스 부재. | Scope 026 line 31-32 deferred_cycles + deferred_reason; line 116-120 deferred 섹션 4줄 | Scope 026에 "Out of Scope 매핑" 표 신설 — Brief 021 Out of Scope 10행 × {매핑 cycle / 매핑 없음(Phase 2 only)} 컬럼. 또는 deferred_reason frontmatter를 10항목 enumeration으로 확장. |
| **M2** | Major | **Phase 2 Carryover § 2.3 11항목 미인지** — Brief 021 Phase 2 Carryover § 2.3은 W3 #6/#14/#15/#18 + W3 M2/M3/M4/M5 + W2 M1/M3 = 11행(질문 텍스트 기준 9 unique이지만 row 11). Scope 026은 "§ 2.3 9개 항목"으로 단순 reference. Cycle별 makeplan 입력 표에 carryover 인지 행이 부재 (예: Cycle 4 #6 wire-format, Cycle 4 #14 Web Crypto byte-level, Cycle 4 #15 secret rotation flow, Cycle 5 #18 OpenAPI 실 응답 호환은 모두 Phase 1 verify 한계 항목인데도 cycle 표에 명시 부재). | Brief 021 line 268-279 § 2.3 표 11 row; Scope 026 line 257-266 cycle별 makeplan 입력 표에 carryover 컬럼 부재 | Cycle별 makeplan 입력 표에 "Phase 2 Carryover 인지" 컬럼 신설. Cycle 2 (R4 wire-format #6), Cycle 4 (#14, #15, M5 JWKS rotation), Cycle 5 (#18 OpenAPI), Cycle 8 (M2 D1 Sessions, M3 KV 60s) 매핑. Or: tail Cycle 10_tail note에 § 2.3 11항목 verify_scope=partial/production-only 점검 명시. |
| **M3** | Major | **Decision 11 (Toss BC2/BC3 보존) 미명시** — Brief 021 Decision 11은 "Synthesis BC2(webhook 모델 이중화) + BC3(idempotency key 명칭)이 Phase 2 Brief 022 입력 자료로 보존"을 결정. Scope 026은 deferred_reason에 "Cycle 7 Toss(seq 35-38) ... interrupted" 행위만 표기, BC2/BC3 보존(Phase 2 입력) 의도가 cycle 매핑 또는 Phase 2 Carryover 인지에 등장하지 않음. Brief 021 Ideal Criteria #27("Phase 2 재진입 시 ... Toss 정정사항(BC2/BC3)이 그대로 anchor로 활용 가능한가")의 검증 수단이 Cycle 10_tail note ("Brief 021 Ideal Criteria 28개 충족 점검")로만 위임됨. | Scope 026 line 32 deferred_reason; line 85-91 cycle 10_tail note; cycle별 makeplan 입력 표에 BC2/BC3 행 부재 | Cycle 10_tail note에 "Brief 021 Ideal Criteria #27 = BC2/BC3 anchor 보존 명시 점검" 추가. Or: cycle별 makeplan 입력 표에 별도 "Phase 2 Carryover 보존" 행 추가 (Toss BC2/BC3 = makeplan에서 작업하지 않음, 단 Phase 2 입력으로 보존). |
| **M4** | Major | **Decision 12 Local/Partial/Production-only 매트릭스 미반영** — Brief 021 Decision 12 (C1 보강)는 Ideal Criteria 28개를 19 local + 9 partial + 2 directional로 분류하고 #6/#14/#15/#18을 partial 명시. Scope 026은 "Brief 021 Ideal Criteria 28개 충족 점검"의 한 줄로만 압축, partial/production-only 항목별 verify 한계가 cycle 매핑되지 않음. Cycle 4·5의 makeplan 입력 표에 M4 항목 부재. | Brief 021 line 139·143·202-204 Decision 12 + Ideal Criteria; Scope 026 line 90 cycle 10_tail note 한 줄 | Scope 026 § "사이클별 makeplan 입력" 표에 "verify_scope" 컬럼 또는 별도 셀 추가, 9 partial + 2 directional 항목을 cycle별 매핑(예: Cycle 2: #6, Cycle 4: #14, #15, Cycle 5: #18). Or: cycle 10_tail note를 한 줄 → 표로 확장. |
| **M5** | Major | **Decision 7 JWKS DI / M11 rotation fixture 부분 매핑** — Cycle 4 note는 "BetterAuth + CF Access verifier(JWKS resolver DI 패턴 — M1)"로 M1 명시 ✓. cycle별 makeplan 입력 표 Cycle 4 행도 "M11 (JWKS rotation fixture test)" 명시 ✓. 다만 Cycle 4 frontmatter `in_scope: [5, 9]` 외 `decisions:` 필드 부재(반면 Cycle 5만 `decisions: [8, 9]` 보유). Decision 7 매핑이 frontmatter 차원에서 명시 안 됨. | Scope 026 line 56-62 Cycle 4 frontmatter (decisions 필드 없음); line 64-70 Cycle 5 frontmatter (decisions: [8, 9]) | 모든 cycle frontmatter에 `decisions:` 필드 일관 추가. Cycle 4 → `decisions: [3, 7]` (R4+R1 중 auth 부분 + 인증 패턴), Cycle 6 → `decisions: [4, 6]` (영역 확장 + Hono SSR), Cycle 8 → `decisions: []` (compliance 직접 In Scope), Cycle 1 → `decisions: [1, 2, 14, 15]` (Phase split + 외부 미접촉 + pipeline reentry + compatibility_flags). 또는 frontmatter 일관성 위해 모두 제거. |
| **M6** | Major | **Decision 5 Pure Saga (D1 only / No Durable Object) 명시 약함** — Cycle 3 note는 "scoring 8단계 Pure Saga (Phase A-E forward-recovery, step 7 UPSERT)"로 패턴은 명시했으나 **"D1 only / Durable Object 미사용"** (Brief 021 Decision 5 Trade-off + Anchor 6 "Durable Object 사용 금지")이 명시 안 됨. cycle별 makeplan 입력 표 Cycle 3 행도 "R2 (Pure Saga, 7/8 idempotent, Phase A-E, ~150 LOC)"로만 압축. | Scope 026 line 53-54 Cycle 3 note; line 261 Cycle 3 makeplan 입력 행 | Cycle 3 note에 "Durable Object 미사용 (Brief 021 Anchor 6)" 1구절 추가. Or: 영역 식별 표 행 3 "주요 파일/모듈" 컬럼에 "Durable Object 0" 명시. |
| **m1** | Minor | **frontmatter cycle 키 비일관** — `cycle: 1, 2, 3, 4, 5, 6, 8`은 정수, `cycle: 10_tail, 99_retro`는 문자열. Pipeline DB 또는 자동 도구 처리 시 type 분기 필요. | Scope 026 line 35-98 cycles 배열 | 일관성 위해 모두 문자열(`"1"`, `"2"`, ...) 또는 별도 `phase: tail/retro` 필드 신설. Or: 본 비일관이 의도(impl cycle vs tail/retro 구분) 임을 frontmatter 주석으로 명시. |
| **m2** | Minor | **Cycle 5 frontmatter `decisions: [8, 9]` 단독 명시** — 다른 cycle은 decisions 필드 없는데 Cycle 5만 보유. Mapping 추적 일관성 약화. | Scope 026 line 66 Cycle 5 frontmatter | M5 Recommendation에 통합 (모든 cycle에 추가 또는 모두 제거). |
| **m3** | Minor | **deferred_cycles 표기 `10_partial` vs frontmatter `10_tail`** — frontmatter `deferred_cycles: [7, 9, 10_partial]` (line 31) ↔ cycles 배열 `cycle: 10_tail` (line 85). "10_partial"과 "10_tail"의 의미 매핑이 명시되지 않음. | Scope 026 line 31, 85 | deferred_cycles 표기를 `[7, 9, "10_makeplan_impl_verify"]` 식 명확 어휘로 변경. Or: § Pipeline DB 정렬 상태 코드블록 위에 "10_partial = Cycle 10 makeplan/impl/verify 사이클 만 deferred, 10_tail = eval/qualify/push" 1줄 도입부 추가. |

## Missing Elements

| # | What's Missing | Why It Matters | Action |
|---|---------------|----------------|--------|
| MS-α | "Brief Decision → Cycle 매핑 표" 부재 | Brief 021 15 Decisions 중 cycle-anchored vs scope-level vs deferred 구분이 reader에게 직접 노출되지 않음. cycle별 makeplan 입력 표는 R-axis + critique finding 기반이라 Decision 1·2·8·11·13·14·15가 어디로 매핑되는지 trace 어려움. | Scope 026에 "Brief 021 Decisions × Scope Cycles 매핑 표" 신설 (15 row × {Cycle 1-8, Phase 1 전반, deferred} 컬럼). |
| MS-β | "Out of Scope × deferred 사유 / Phase 2 진입 조건" 표 부재 | Brief 021 Out of Scope 10항목은 Phase 2 재진입 조건이 각각 다름. Scope 026에는 "Phase 2 deferred"의 4줄 압축으로 진입 조건 0 매핑. | Scope 026에 Out of Scope 10 × {Phase 2 진입 조건 / Brief 021 reference / 매핑 cycle 또는 N/A} 표 신설. |
| MS-γ | Brief 021 Ideal Criteria 28개 → Cycle 매핑 부재 | Cycle 10_tail note는 "28개 충족 점검"이지만 어느 Criteria가 어느 cycle verify에서 검증되는지 trace 불가. | Cycle 10_tail note 또는 별도 § "Ideal Criteria × Cycle 매핑" 표 추가. 28 row × {assertion/directional / 매핑 cycle / verify_scope}. |

## Brief↔Scope 매핑 매트릭스

### A. Brief 021 In Scope 9 × Scope 026 Cycles

| In Scope # | Item (요약) | Cycle 1 | Cycle 2 | Cycle 3 | Cycle 4 | Cycle 5 | Cycle 6 | Cycle 8 | Phase 2 deferred | Status |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Foundation 한정형 | ✓ (in_scope=[1], note: wrangler.toml stub + package.json + tsconfig + workflows placeholder + README + npm install) | | | | | | | | **fully mapped** |
| 2 | 로컬 검증 인프라 (wrangler dev --local + vitest-pool-workers + miniflare) | partial (Cycle 1 note에 "wrangler.toml stub", in_scope에는 미명시) | implicit (영역 식별 표에 `tests/db/*.test.ts`) | implicit | implicit | implicit | implicit | implicit | | **partial — C1 (Critical)** in_scope frontmatter에 한 번도 등장 안 함 |
| 3 | DB Layer | | ✓ (in_scope=[3]) | | | | | | | fully mapped |
| 4 | Domain Services Port | | | ✓ (in_scope=[4, 9]) | | | | | | fully mapped |
| 5 | Auth + Security Baseline | | | | ✓ (in_scope=[5, 9]) | | | | | fully mapped |
| 6 | API Layer + Mobile Contract | | | | | ✓ (in_scope=[6, 9]) | | | | fully mapped |
| 7 | Admin UI + Public Assessment Flow SSR | | | | | | ✓ (in_scope=[7, 9], 영역 확장 명시) | | | fully mapped |
| 8 | Compliance | | | | | | | ✓ (in_scope=[8, 9]) | | fully mapped |
| 9 | Test Migration (분산) | | (Cycle 2 tdd_red=true) | ✓ ([9]) | ✓ ([9]) | ✓ ([9]) | ✓ ([9]) | ✓ ([9]) | | fully mapped (Cycle 2도 tdd_red 반영, [9] 명시는 누락 — 의도일 수 있음) |

**누락 / 불완전 매핑**: In Scope 2 (1건). In Scope 9의 Cycle 2 명시 누락은 "테스트는 Cycle 2도 작성"의 frontmatter 표현 차이로 minor.

### B. Brief 021 Decisions 15 × Scope 026 매핑

| Decision # | Brief 021 결정 | Scope 026 매핑 위치 | 매핑 방식 | Status |
|---|---|---|---|---|
| 1 | Phase 분리 (sub-phase Brief) | intent + summary + 작업 목표 (line 17-26, 105) | scope-level frontmatter | covered (scope-level) |
| 2 | wrangler dev --local + vitest-pool-workers | 제약 (line 108) | scope-level | partial — Cycle in_scope 미매핑 (C1 / In Scope 2 동일 사유) |
| 3 | R4 분리 컬럼 + R1 envelope 보존 | Cycle 2 note + 영역 식별 표 행 2 + 의존 관계 표 | cycle-anchored | covered |
| 4 | Cycle 6 영역 = Admin + Public Assessment | Cycle 6 area + note + 영역 식별 표 행 6 + cycle별 makeplan 입력 표 Cycle 6 행 | cycle-anchored | covered |
| 5 | Pure Saga (D1 only) | Cycle 3 note ("Pure Saga (Phase A-E forward-recovery, step 7 UPSERT)") | cycle-anchored | partial — "D1 only / Durable Object 미사용" 명시 약함 (M6) |
| 6 | Hono SSR vanilla + hx-boost | Cycle 6 note ("Hono SSR + hx-boost 옵셔널") | cycle-anchored | covered |
| 7 | BetterAuth + CF Access verifier | Cycle 4 note + 영역 식별 표 행 4 + cycle별 makeplan 입력 표 Cycle 4 행 (M1, M11 명시) | cycle-anchored | covered (M5: frontmatter decisions 필드 비일관) |
| 8 | API envelope `{success, data, error}` | Cycle 5 note ("envelope `{success,data,error}` 미들웨어") + Cycle 5 frontmatter `decisions: [8, 9]` + 영역 식별 표 | cycle-anchored | covered |
| 9 | OpenAPI 3 + codegen (JAR build-time 예외) | Cycle 5 note ("Dart codegen(JAR build-time 예외 — Decision 9)") + cycle별 makeplan 입력 표 Cycle 5 행 (M2 명시) | cycle-anchored | covered |
| 10 | TDD Cycles 2-6, 8 | cycles[].tdd_red 플래그 + 실행 순서 표 TDD 컬럼 + 핵심 원칙 4 | cycle-anchored | covered |
| 11 | Toss BC2/BC3 Phase 2 보존 | deferred_reason ("Cycle 7 Toss interrupted") | scope-level by reference only | **partial — M3** (BC2/BC3 보존 의도 명시 부재) |
| 12 | Phase 1 verify = Local + Partial 9 + Directional 2 | Cycle 10_tail note ("Brief 021 Ideal Criteria 28개 충족 점검") | scope-level by reference | **partial — M4** (L/P/P 매트릭스 미반영) |
| 13 | Phase 1 완료 정의 (활성 7 사이클 + 분산 테스트 + RSpec 동등성) | Cycle 10_tail "Phase 1 종료 검증" + 작업 목표 ("Brief 021 § Ideal Criteria 28개 충족이 본 scope의 성공 기준") | scope-level | covered |
| 14 | Pipeline 재진입 (interrupted + reason='phase-2-deferred') | deferred_cycles + deferred_reason + Pipeline DB 정렬 상태 코드블록 + 핵심 원칙 1 | scope-level | covered |
| 15 | wrangler.toml compatibility_flags | 영역 식별 표 행 1 ("compatibility_flags=nodejs_compat (Decision 15)") + cycle별 makeplan 입력 표 Cycle 1 행 (MS3 명시) | cycle-anchored | covered |

**Coverage roll-up**: 15 Decisions 중 covered 11 + partial 4 (D2 = C1 동일, D5 = M6, D11 = M3, D12 = M4). Critical 0(scope-internal), Major 4 (D2/D5/D11/D12 partial).

### C. Brief 021 Out of Scope 10 × Scope 026 매핑

| Out of Scope # | Item | Scope 026 매핑 | Phase 2 재진입 조건 표기 |
|---|---|---|---|
| 1 | Toss 결제 7-stage | deferred_cycles=[7], "Cycle 7 Toss(seq 35-38) interrupted" | 부재 (Brief 021 § Out of Scope 표에는 있음) |
| 2 | Cutover safety | deferred_cycles=[9], "Cycle 9 Cutover safety(seq 43-45) interrupted" | 부재 |
| 3 | Cutover execution | deferred_cycles=[10_partial], "Cycle 10 makeplan/impl/verify(seq 46-48) interrupted" | 부재 |
| 4 | Production monitoring | "Phase 2 Carryover § 2.3 9개 항목" 한 줄 reference | 부재 (M1 적용) |
| 5 | Foundation 외부 자원 | Cycle 1 note: "외부 자원 step (U1-U8) skip" | partial 매핑 |
| 6 | CF Access 실 SSO 연결 | Cycle 4 note: "실 SSO ... Phase 2" | covered |
| 7 | D1 자동 export → R2 cron | M5 (Plan 020 Step 8 stub-only) — cycle별 makeplan 입력 Cycle 1 행 | covered |
| 8 | Rails archive 이동 | 부재 | **누락** (M1 적용 — Brief 021 명시) |
| 9 | 글로벌 결제 (Stripe) | 부재 | **누락** (M1 적용) |
| 10 | 새 도메인 기능 | 부재 (Brief 021도 "Brief 001 Out of Scope 6 계승") | acceptable (Brief 001 inheritance) |

**Out of Scope 매핑 결과**: 10항목 중 cycle-anchored 5(1, 2, 3, 5, 7) + scope-level reference 1(6) + 누락 3(4 Production monitoring, 8 archive 이동, 9 글로벌 결제) + acceptable 1(10).

### D. Brief 021 Phase 2 Carryover § 2.3 11항목 × Scope 026 인지

| Carryover row | 출처 | Scope 026 cycle 인지 |
|---|---|---|
| W3 #6 R4 wire-format | Cycle 9 archive smoke (Phase 2) | implicit (Cycle 2 R4 통합) — Phase 1 verify 한계 명시 부재 |
| W3 #14 Web Crypto byte-level | Phase 2 staging | 부재 |
| W3 #15 secret rotation flow | Phase 2 Cycle 4 추가 또는 Cycle 9 drill | 부재 |
| W3 #18 OpenAPI 실 응답 | Phase 2 staging API | 부재 |
| W3 M2 D1 Sessions API | Phase 2 read replica 시점 | 부재 |
| W3 M3 KV 60s eventual | Phase 2 production session | 부재 |
| W3 M4 R2 multipart | Phase 2 D1 backup | 부재 |
| W3 M5 CF JWKS 6주 rotation | Phase 2 첫 rotation cycle | Cycle 4 makeplan 입력 표 M11 명시 (fixture만) — Phase 2 실 rotation은 부재 |
| W2 M1 Plan 020 Step 8 cron stub-only | Phase 1 + Phase 2 활성화 | covered (Cycle 1 makeplan 입력 표 M5) |
| W2 M3 server/ baseline t0 | Phase 1 시작 직전 측정 | 부재 |

**Carryover 인지 결과**: 11 row 중 covered 1 + partial 1 + 부재 9. M2 Recommendation 적용 시 Cycle별 매핑 명시 가능.

## Detailed Analysis

### D1. In Scope 2 누락의 의미 (C1 상세)

Brief 021 In Scope 2는 단순 인프라가 아니라 **Decision 2의 운영 모델 구체화**이다 — wrangler dev --local --persist 디렉토리 운영, vitest-pool-workers D1 binding 통합 테스트 표준, miniflare DX. 이 셋업은 Cycle 1 산출물(`wrangler.toml` stub + `package.json` 의존성)에 본질적으로 포함되지만, Scope 026 Cycle 1 in_scope=[1]만 표기하면 다음 문제가 발생한다.

1. **책임 공백**: Cycle 2 makeplan 작성자가 "vitest-pool-workers 통합 테스트 베이스가 어디서 들어오는가"를 trace할 때 Cycle 1 frontmatter는 In Scope 1만 가리키므로 In Scope 2 책임 owner가 부재. Cycle 1이 "한정형 = 파일 템플릿"으로 좁게 해석될 위험.
2. **TDD 의존성 깨짐**: Cycle 2 tdd_red는 vitest-pool-workers 베이스를 전제로 함 (Brief 021 Ideal Criteria #3). Cycle 1이 In Scope 2 owner가 아니면 Cycle 2 tdd_red 작성자가 베이스 셋업까지 떠안게 됨.
3. **Brief Decision 2 trace 손실**: Decision 2 (외부 자원 미접촉 운영 모델)는 Scope 026 제약 한 줄로만 표기. cycle 차원에서 anchor 안 됨.

해결: Cycle 1 in_scope를 `[1, 2]`로 보강 + Cycle 1 note에 "vitest-pool-workers 베이스 + miniflare 셋업" 추가.

### D2. Out of Scope 매핑 부재의 reader 비용

Brief 021 Out of Scope 10항목 중 4·8·9가 Scope 026에서 trace 안 됨. Reader가 "Production monitoring은 Phase 2인가?"를 확인하려면 Brief 021 line 116(Out of Scope #4)를 직접 펼쳐야 함. Scope 026이 "Phase 1 alignment anchor"를 자처(line 26)하면서 deferred 항목 enumerate가 1단계 indirection이면 anchor 자격이 부분 손상.

해결: Out of Scope 매핑 표 신설 (MS-β).

### D3. Phase 2 Carryover 인지 약함

§ 2.3 11항목 중 9항목이 Scope 026 cycle 매핑 안 됨. 이 중 #14·#15·#18은 Brief 021 Decision 12 (verify_scope=partial)와 직결 — Phase 1 cycle 4·5 verify 작성자가 "이 항목은 production-only 갭"을 인지해야 함. cycle 매핑 부재 → 작성자가 production-only 항목까지 Phase 1 verify에 강제로 포함시키려 시도할 위험. 사실 Brief 021 C1은 정확히 이 위험을 막기 위해 추가된 보강.

해결: Cycle별 makeplan 입력 표에 "verify_scope partial / Phase 2 carryover" 컬럼 신설 (M2/M4 통합).

### D4. scope creep 0 검증

Scope 026 모든 결정 / cycle 영역 / In Scope 매핑이 Brief 021 + Synthesis 018 + Synthesis 025에서 trace 가능. 새 결정 도입 0. Cycle 1 ~ 8 영역 명·파일 모듈은 모두 Brief 021 In Scope 1 ~ 8 + Synthesis 018 § 5 cycle 입력 표와 동어 또는 명세 보강. ✓

## Recommendations for Scope 026 Revision

우선순위:

1. **[Critical] C1**: Cycle 1 frontmatter `in_scope: [1, 2]`로 보강 + 영역 식별 표 행 1 "Brief 021 In Scope" 컬럼을 "1, 2"로 갱신 + Cycle 1 note에 "vitest-pool-workers + miniflare DX 베이스 셋업" 명시.
2. **[Major] M1 + MS-β**: "Out of Scope × Phase 2 진입 조건" 표 신설 — Brief 021 Out of Scope 10 row × {Scope 026 매핑 (cycle 또는 reference) / Phase 2 진입 조건} 컬럼.
3. **[Major] M2 + MS-γ**: cycle별 makeplan 입력 표에 "Phase 2 Carryover 인지" 컬럼 또는 별도 "Ideal Criteria × Cycle 매핑" 표 추가. § 2.3 11 row를 Cycle 2/4/5/8에 매핑.
4. **[Major] M3**: Cycle 10_tail note에 "Ideal Criteria #27 = BC2/BC3 anchor 보존" 명시.
5. **[Major] M4**: Decision 12 Local/Partial/Production-only 매트릭스를 Scope 026 § "사이클별 makeplan 입력" 표에 verify_scope 컬럼으로 도입.
6. **[Major] M5 + m2**: 모든 cycle frontmatter에 `decisions:` 필드 일관 추가 (또는 모두 제거). Cycle 4 → `[3, 7]`, Cycle 6 → `[4, 6]`, Cycle 8 → `[]`, Cycle 1 → `[1, 2, 14, 15]`.
7. **[Major] M6**: Cycle 3 note에 "Durable Object 미사용 (Brief 021 Anchor 6)" 1구절 추가.
8. **[Major] MS-α**: "Brief 021 Decisions × Scope 026 매핑 표" 신설 — 본 critique § B 표를 Scope 026에 직접 도입.
9. **[Minor] m1**: cycle 키 표기를 모두 문자열 또는 별도 `phase` 필드 신설로 일관화.
10. **[Minor] m3**: deferred_cycles 표기 명료화 (`10_partial` → `"10_makeplan_impl_verify"` 또는 도입부 1줄 정의).

## References

| Resource | Path |
|----------|------|
| Scope 026 (target) | [`026_Scope_conversion_phase1.md`](./026_Scope_conversion_phase1.md) |
| Brief 021 (parent anchor) | [`021_Brief_conversion_phase1.md`](./021_Brief_conversion_phase1.md) |
| Brief 001 (frozen ancestor) | [`001_Brief_cf_workers_rebuild.md`](./001_Brief_cf_workers_rebuild.md) |
| Synthesis 018 (research) | [`018_Synthesis_research_cycle.md`](./018_Synthesis_research_cycle.md) |
| Synthesis 025 (Brief 021 critique) | [`025_Critique_Synthesis.md`](./025_Critique_Synthesis.md) |
| Plan 020 (Cycle 1 Foundation) | [`020_Plan_cycle1_foundation.md`](./020_Plan_cycle1_foundation.md) |
| Pipeline DB | `tmp/007_cf_workers_rebuild_1c64.db` |
