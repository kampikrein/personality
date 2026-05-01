---
id: "025"
type: synthesis
title: "Brief 021 Deep Critique Synthesis — 3 perspective"
created: 2026-04-29
target: "021"
critique_docs: ["022", "023", "024"]
severity_summary:
  critical: 2
  major: 11
  minor: 7
  missing: 3
phase_perspectives:
  W1: "Phase Split Feasibility (022) — 0C/4M/3m/3 missing"
  W2: "Phase 2 재진입 가능성 (023) — 1C/3M/2m"
  W3: "로컬 검증 모델 한계 (024) — 1C/4M/2m"
summary: >
  3 관점 모두 confidence: high. Brief 021 Phase 분리 전략은 구조적으로 타당하나
  3 영역에서 보강 필요: ① Phase 1 verify의 production 갭(W3 Critical, conversion_fidelity
  Exit Criteria 오버스테이트), ② pipeline.sh DB의 deferred 표기 부재(W2 Critical,
  status enum + 실제 행 처리), ③ "외부 자원 미접촉"의 정의 확장(W1 P2, build-time
  Java 의존성·codegen JAR 등). 권고 18건 중 13건을 Brief 021에 반영 (Critical 2 +
  Major 9 + Minor 2). Medium 5건은 makeplan/scope 위임.
keywords: [critique-synthesis, brief-021, phase-split, deferred-tracking, local-verification-gap]
---

# Brief 021 Deep Critique Synthesis

## 1. Severity Roll-up

| Perspective | Critical | Major | Minor | Missing | Confidence |
|------------|----------|-------|-------|---------|------------|
| W1 Phase Split Feasibility (022) | 0 | 4 | 3 | 3 | high |
| W2 Phase 2 재진입 가능성 (023) | 1 | 3 | 2 | — | high |
| W3 로컬 검증 모델 한계 (024) | 1 | 4 | 2 | — | high |
| **합계** | **2** | **11** | **7** | **3** | high |

## 2. Critical 2건 — 즉시 Brief 021 보강

### C1 [W3 W1] — Exit Criteria conversion_fidelity 오버스테이트

**발견**: Brief 021 Ideal Criteria #6, #14, #15, #18은 production-only 검증이 필요한 항목인데 conversion_fidelity 우선 차원에서 "Phase 1 동등 입증"으로 표기됨.

- **#6** R4 schema wire-format Rails 호환 → Rails 실 export 데이터 import 검증이 production 환경에서만 가능
- **#14** Web Crypto AES-GCM IV=HMAC 결정성 → workerd(local) vs production V8 byte-level 동일성 docs 보장 부재
- **#15** parallel-key rotation → 실 wrangler secret rotation flow 미검증
- **#18** OpenAPI 3 + Flutter codegen → compatibility flag + 실 응답 호환

**Brief 021 보강 (R1)**: Decision 12에 "Phase 1 verify = 로컬 검증만"의 한계를 명시. Ideal Criteria 표에 새 컬럼 `verify_scope: local | partial | production-only`를 추가. #6/#14/#15/#18은 `partial`로 재분류 + `Phase 2 Carryover` 섹션에서 명시.

### C2 [W2] — Pipeline DB deferred 표기 부재

**발견**: 현 `tmp/007_cf_workers_rebuild_1c64.db` 체크리스트에서 Cycle 7 (Toss) + Cycle 9/10 (Cutover safety/exec) 행이 모두 `status='pending'`. SQL status enum에 'deferred' 부재 (`pending`/`in-progress`/`done`/`interrupted`/`partial`만 허용). Brief 021 Decision 14는 "deferred 표기" 선언했으나 **실제 DB 작업 미수행** → No-Stop 자동 디스패치가 Cycle 7부터 그대로 진행 위험.

**Brief 021 보강 (R2)**: Decision 14에 "deferred = `pipeline.sh interrupt` 사용 (status='interrupted' + reason 필드에 'phase-2-deferred')" 명시. Anchor 12에 동일 표기. 본 Critique Synthesis 직후 실제 DB에 적용.

## 3. Major 11건 — 실행 권고

### M1 [W1 P1] — Decision 7 CF Access verifier DI 패턴

`createRemoteJWKSet(${TEAM_DOMAIN}/cdn-cgi/access/certs)`은 production 호출이 필요. 테스트는 `createLocalJWKSet(fixture)`를 주입할 수 있도록 verifier 함수 시그니처가 JWKS resolver를 파라미터로 받아야 함. **Brief 021 Decision 7에 DI 패턴 1단락 명시.**

### M2 [W1 P2] — Decision 9 OpenAPI codegen 외부 도구 의존성

Hono RPC는 TS-only이므로 Flutter Dart codegen은 별도 도구(예: openapi-generator JAR + Java + Maven Central) 필요 → "외부 자원 0" 위반 가능성. **Brief 021 Decision 9: spec-gen(Hono RPC TS 클라이언트, 외부 0) vs Dart codegen(JAR 1회 다운로드 1회 빌드, build-time 외부 허용 예외)을 분리. Anchor 2 "외부 자원 미접촉"의 정의 확장 — "런타임 외부 호출 0, build-time 검증된 도구 의존 허용".**

### M3 [W1 P3] — In Scope 5 CSRF caveat 약화

Brief 001 Anchor 18의 "Hono CSRF는 origin-check 기반(per-session token 부재) 사실 명시 인지" caveat가 Brief 021에서 약화됨. CVE-2024-48913 이력. **Brief 021 In Scope 5에 caveat 복원 + Anchor 8에 토큰 CSRF 부재 명시.**

### M4 [W1] — Decision 12 production-only 항목 표 부재

production-only 검증 필요 영역(D1 read replication latency, Workers cold start, 실 secret 운용)이 Brief 021에 표로 정리되지 않음. **Decision 12에 "Local-only" / "Partial" / "Production-only" 매트릭스 추가 (W3 deliverable 활용).**

### M5 [W2] — Plan 020 Step 8 D1 cron dormant code

Plan 020에 D1 자동 export → R2 cron + scheduled handler가 명시. wrangler dev에서 cron 미동작 (= Phase 1 검증 불가). Phase 2 Cycle 9/10 진입 시 첫 production 노출. **Brief 021 In Scope 1에 "D1 cron handler는 stub-only (Phase 2에서 활성화)" 명시. Plan 020 Step 8을 Phase 1 한정형 작업에서 제외.**

### M6 [W2] — BC2/BC3 추적 경로 3-hop

Synthesis 018 BC2(webhook 모델 이중화) + BC3(idempotency key 명칭) 정정사항이 Brief 021에서 Decision 11 한 줄로만 표기. Phase 2 Brief 022 작성자가 cross-reference 필요. **Brief 021에 "Phase 2 Carryover Inputs" 신규 섹션 추가하여 BC2/BC3 + 5 OQ + W1/W2/W3 carryover 모두 1곳에 인덱스화.**

### M7 [W2] — server/ 시간 함수 부패

Phase 1 동안 server/ read-only지만 Ruby 버전·gem·SQLite 호환성은 시간 함수로 부패 (Brief 001 Critique 004 W1 위험 누적). **Brief 021 Constraints에 "Phase 1 시작 시점 t0의 server/ baseline 기록 (Ruby 3.4.2, Gemfile.lock hash)" 추가. Phase 2 archive smoke test의 비교 기준으로 활용.**

### M8 [W3] — D1 Sessions API 결정 누락

Brief 021은 D1 Sessions API(read replication 일관성을 위한 bookmark 기반 세션) 결정 부재. **In Scope 3 또는 Decision에 명시 — Phase 1은 단일 region이므로 Sessions API 미사용, Phase 2에서 도입 검토.**

### M9 [W3] — KV eventual consistency 60s

KV는 production에서 60s eventual consistency. wrangler dev --local은 즉시 일관성. BetterAuth session(KV 기반) 동작에서 갭 가능. **Brief 021 In Scope 5에 "Phase 1 KV 사용은 즉시 일관성 가정, Phase 2에서 60s eventual 정책 검토" 명시.**

### M10 [W3] — R2 multipart upload 미검증

R2 multipart upload는 production에서만 정확한 동작. wrangler dev --local에서 emulation 한계. Phase 1에서 R2 사용 범위(현재는 Phase 2의 D1 backup, sealed secrets 등 모두 deferred)는 작아 직접 영향 적음. **Brief 021 Decision 12에 "R2 multipart는 Phase 2" 명시.**

### M11 [W3] — CF JWKS 6주 rotation 미검증

Decision 7 CF Access verifier의 JWKS는 6주마다 rotation. Phase 1 fixture로는 rotation 시나리오 미커버. **Brief 021 Decision 7에 "JWKS rotation 시나리오 unit test (fixture 2개 dual-read)" 추가. Phase 2에서 실 rotation 검증.**

## 4. Minor 7건 — 선택 반영

| # | Source | Finding | Action |
|---|--------|---------|--------|
| Mn1 | W1 minor 1 | Anchor 2 "외부 자원" 정의 명시 부족 | Anchor 2 1줄 추가 (M2와 함께) |
| Mn2 | W1 minor 2 | Ideal Criteria 15 type을 directional로 재분류 | criteria 표 수정 |
| Mn3 | W1 minor 3 | wrangler dev --local 환경변수 명시 | makeplan 위임 |
| Mn4 | W2 minor 1 | Plan 020 referenced 파일 갱신 (Cycle 1 한정형 후 deferred 재명시) | Plan 020 보강 |
| Mn5 | W2 minor 2 | Anchor 17 검증 메커니즘 directional 1줄 → 명시적 항목 추가 | Anchor 17 보강 |
| Mn6 | W3 minor 1 | cookie domain 로컬 무의미 | makeplan 위임 (테스트 시 hostname mock) |
| Mn7 | W3 minor 2 | 도구 버전 pin 부재 | Constraints에 핵심 도구 버전 pin 추가 (wrangler, vitest-pool-workers, drizzle-kit) |

Brief 반영: Mn1, Mn2, Mn5, Mn7만 반영. Mn3/Mn4/Mn6은 makeplan/scope 위임 명시.

## 5. Missing 3건 (W1) — Brief 021에 신규 추가

| # | What's Missing | Why It Matters | Action |
|---|---------------|----------------|--------|
| MS1 | Phase 2 Carryover Inputs 섹션 (M6과 통합) | 재진입 시 Brief 022가 입력으로 활용 | Brief 021에 신규 섹션 추가 |
| MS2 | tooling 버전 pin (Mn7과 통합) | 1년+ 작업 시 도구 호환성 변동 | Constraints에 추가 |
| MS3 | wrangler.toml `compatibility_flags` 결정 | nodejs_compat 등 명시 안 하면 build-time 변동 | Decision에 추가 |

## 6. Brief 021 보강 작업 목록 (우선순위)

| Priority | Source | Brief 021 위치 | 변경 |
|----------|--------|--------------|------|
| **P1 (Critical)** | C1 (W1+W3) | Decision 12 + Ideal Criteria | verify_scope 컬럼 + Local/Partial/Production-only 매트릭스 |
| **P1 (Critical)** | C2 (W2) | Decision 14 + Anchor 12 + 본 Synthesis 직후 DB 작업 | "deferred = interrupted + reason" 명시 + 실제 DB 적용 |
| P2 (Major) | M1 | Decision 7 | JWKS DI 패턴 1단락 |
| P2 (Major) | M2+Mn1+MS3 | Decision 9 + Anchor 2 + Decision 신규 | spec-gen vs codegen 분리 + 외부 자원 정의 확장 + compatibility_flags |
| P2 (Major) | M3 | In Scope 5 + Anchor 8 | CSRF caveat 복원 |
| P2 (Major) | M5 | In Scope 1 + Plan 020 보강 | scheduled handler stub-only |
| P2 (Major) | M6+MS1 | 신규 섹션 "Phase 2 Carryover Inputs" | BC2/BC3 + 5 OQ + critique W1/W2/W3 carryover 인덱스 |
| P2 (Major) | M7 | Constraints | server/ baseline t0 |
| P2 (Major) | M8 | In Scope 3 | D1 Sessions API 결정 |
| P2 (Major) | M9 | In Scope 5 | KV eventual consistency 정책 |
| P2 (Major) | M10 | Decision 12 | R2 multipart Phase 2 |
| P2 (Major) | M11 | Decision 7 | JWKS rotation fixture test |
| P3 (Minor) | Mn2 | Ideal Criteria 15 | type=directional |
| P3 (Minor) | Mn5 | Anchor 17 | 검증 메커니즘 명시 |
| P3 (Minor) | Mn7+MS2 | Constraints | 도구 버전 pin |

**Medium 위임 (Brief 미수정)**: Mn3, Mn4, Mn6 — makeplan에서 처리.

## 7. 비평이 검증한 강점 (Brief 021 유지)

- **Phase 분리 결정 자체는 타당**: 3 관점 모두 W1/W2/W3 confidence high로 "구조적으로 sound"
- **External 자원 0 운영 모델**: wrangler dev + vitest-pool-workers 조합은 공식 docs로 뒷받침됨 (W1 strengths)
- **Brief 001 frozen + sub-phase Brief 021 활성**: anchor 2개 운영이 history 손상 0으로 합리적 (W1+W2 strengths)
- **R4 schema 패턴 채택 정합 보존**: Synthesis 018 결정이 Brief 021에 일관 반영됨 (W3 strengths)

## 8. 다음 작업

1. **Brief 021 Edit**: P1 + P2 + P3 권고 13건 반영
2. **Pipeline DB 작업**: Cycle 7 + 9 + 10 행을 `pipeline.sh interrupt` (또는 직접 status='interrupted' edit + reason 필드)로 deferred 표기
3. **Plan 020 Edit**: Step 8 cron handler stub-only로 변경 + Phase 1 한정형에서 외부 자원 step 명시 제외
4. **frontmatter 갱신**: Brief 021 `deep_critique: true`, `critique_docs: ["022", "023", "024"]`, `critique_synthesis: "025"`, `status: completed`
5. **Step 8 auto-chain**: --deep 모드는 scope 자동 호출 → /scope cf_workers_rebuild (단, scope 007이 이미 존재하므로 amend mode로 진입)

## 9. References

| Resource | Path |
|----------|------|
| Brief 021 (target) | [`021_Brief_conversion_phase1.md`](./021_Brief_conversion_phase1.md) |
| Brief 001 (frozen parent) | [`001_Brief_cf_workers_rebuild.md`](./001_Brief_cf_workers_rebuild.md) |
| Synthesis 018 (research) | [`018_Synthesis_research_cycle.md`](./018_Synthesis_research_cycle.md) |
| Plan 020 (Cycle 1) | [`020_Plan_cycle1_foundation.md`](./020_Plan_cycle1_foundation.md) |
| Critique 022 (W1) | [`022_Critique_phase_feasibility.md`](./022_Critique_phase_feasibility.md) |
| Critique 023 (W2) | [`023_Critique_phase2_reentry.md`](./023_Critique_phase2_reentry.md) |
| Critique 024 (W3) | [`024_Critique_local_verification.md`](./024_Critique_local_verification.md) |

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 25s | 43455 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 25s |
| Total Tokens | 43455 |
| Input Tokens | 6 |
| Output Tokens | 1821 |
| Cache Read | 0 |
| Cache Creation | 41628 |
