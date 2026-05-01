---
id: "021"
type: brief
title: "Phase 1 — Rails → TypeScript (CF) 전환 집중"
created: 2026-04-29
status: completed
quality_profile: standard
priority_dimensions: [conversion_fidelity, sustainability, completeness, security]
deep_critique: true
critique_docs: ["022", "023", "024"]
critique_synthesis: "025"
parent_anchor: "001"
parent_anchor_status: "frozen"
traces_brief: "001"
traces_scope: "007"
traces_research: ["008", "009", "010", "011", "012"]
traces_synthesis: "018"
traces_plan: "020"
phase: 1
deferred_to_phase: 2
deferred_items:
  - "001_Brief In Scope 9 (Toss 결제 7-stage)"
  - "001_Brief In Scope 12 (Rails archive 이동)"
  - "001_Brief In Scope 13 (모니터링·로깅·백업 — production 부분)"
  - "001_Brief In Scope 14 (archive smoke test)"
  - "001_Brief In Scope 15 (Phase rollback 절차)"
  - "001_Brief Decision 13 (글로벌 결제)"
  - "001_Brief In Scope 1 외부 자원 (CF account, custom domain, 실 secrets)"
  - "001_Brief In Scope 10 외부 자원 (GitHub Actions secrets, production deploy)"
  - "001_Brief In Scope 17 외부 자원 (실 secret 값, 1Password vault, R2 sealed)"
  - "001_Brief In Scope 19 외부 자원 (CF Access 실 SSO 연결)"
summary: >
  Brief 001(Full Migration, frozen anchor) 내에서 **Rails → TypeScript 전환만 활성화**한
  sub-phase Brief. Toss 결제 + Cutover safety/execution + Foundation 외부 자원은
  Phase 2로 deferred. 활성 7 사이클(Foundation 한정형 + DB + Services + Auth + API + Admin/Public + Compliance)
  ≈ 20 MAN-DAY. 모든 작업이 wrangler dev --local + @cloudflare/vitest-pool-workers
  in-memory D1로 외부 자원 미접촉 완결. 본 Phase 완료 시 모든 도메인 기능이
  로컬에서 동작하고 RSpec 동등성이 Vitest로 보장됨. Phase 2 재진입은 Brief 001 +
  본 Brief 021을 anchor로 그대로 활용.
keywords: [phase-1, conversion, rails-to-typescript, local-first, vitest-pool-workers, drizzle, hono, betterauth, deferred-payment, deferred-cutover]
---

# Phase 1 — Rails → TypeScript (CF) 전환 집중

## Intent

Brief 001이 못박은 Full Migration 결정 안에서, **본 Phase는 Rails 코드의 TypeScript 전환에만 집중**한다. 사용자가 다음을 의식적으로 deferred 처리:

- **Toss 결제 (Brief 001 In Scope 9)** — Phase 2 후속 과제
- **Cutover safety (In Scope 14, 15) + Cutover execution (In Scope 12)** — 외부 자원 의존, Phase 2
- **Foundation 외부 자원** (CF account, custom domain, 실 secrets, GitHub Actions secrets) — 사용자 직접 작업, 비자율, Phase 2

이로써 본 Phase는 **외부 자원 미접촉, 로컬 완결 가능한 작업만 활성화**한다. 모든 사이클은 `wrangler dev --local --persist` + `@cloudflare/vitest-pool-workers` 조합으로 in-memory D1 + KV + R2 에뮬레이션 위에서 검증.

본 Brief는 **결정 정리 sub-phase Brief**:
- Brief 001은 frozen anchor로 유지 (Full Migration 13 리스크 수용 결정 + 15 Decisions 모두 승계)
- 본 Brief 021은 Phase 1 작업의 alignment anchor
- Phase 2 재진입 시 Brief 001 + 본 Brief 021 + (작성 예정) Brief 022(Phase 2)가 함께 anchor 역할

## Context

### 본 Phase의 입력 자료 (이미 확보됨)

| 자료 | 경로 | 본 Phase에서의 역할 |
|------|------|------------------|
| Brief 001 (Full Migration anchor) | [`001_Brief_cf_workers_rebuild.md`](./001_Brief_cf_workers_rebuild.md) | frozen, 모든 결정 승계 |
| Critique Synthesis 006 | [`006_Critique_Synthesis.md`](./006_Critique_Synthesis.md) | --deep 결과 통합본 |
| Scope 007 (Full pipeline 10 cycle) | [`007_Scope_cf_workers_rebuild.md`](./007_Scope_cf_workers_rebuild.md) | 사이클 분해 그대로 사용, 활성/deferred 재분류만 |
| Research 008–012 (5축) | 008-012 | R1/R2/R3/R4 Phase 1 직접 활용. R5 Phase 2 |
| Eval 013–017 | 013-017 | 모두 SUFFICIENT |
| Synthesis 018 (research) | [`018_Synthesis_research_cycle.md`](./018_Synthesis_research_cycle.md) | cross-axis 정합 + Brief 가정 정정 3건 (BC1/2/3) |
| Retro 019 (research phase) | [`019_Retro_research.md`](./019_Retro_research.md) | 5 OQ carryover |
| Plan 020 (Cycle 1 Foundation) | [`020_Plan_cycle1_foundation.md`](./020_Plan_cycle1_foundation.md) | 한정형 작업 부분만 활성화 (외부 자원 step skip) |

### 현 시스템 인벤토리 (Brief 001 § Context 승계)

- 5,448 Ruby LOC + 1,788 ERB + 340 JS + 2,641 spec LOC
- 15 모델, 13 컨트롤러 + admin, 20 services (1,850 LOC), 27 ERB(admin 9 + 공개 18 R3 정정), 8 Stimulus(공개 평가 흐름 전용 EV-015-S1), 18 RSpec
- 14 DB 테이블, 9 JSON 컬럼, 14 FK
- production DB **부재**, 모바일 ↔ 서버 API **미연결**, 결제 **미구현**

### Phase 1이 작업하지 않는 영역 (Phase 2 재진입 시 처리)

| Brief 001 항목 | Phase 2 재진입 조건 |
|--------------|------------------|
| In Scope 9 Toss 결제 7-stage | Toss merchant 등록 + 사용자 진행 결정 |
| In Scope 12 Rails archive 이동 + 13 production monitoring | 외부 deploy 후 |
| In Scope 14 archive smoke test | Phase 1 완료 + 외부 환경 |
| In Scope 15 Phase rollback drill | Phase 1 완료 + 외부 환경 |
| Decision 13 글로벌 결제 (Stripe Korea 단계적) | 해외 법인 또는 Stripe Korea 가맹점 등장 |
| Foundation 외부 자원 (CF account, domain, 실 secrets) | 사용자 직접 작업 + 본 Phase 1 완료 후 |

## Boundaries

### In Scope (Phase 1 활성화)

| # | Item | Description | Brief 001 매핑 |
|---|------|-------------|--------------|
| 1 | **Foundation 한정형** | wrangler.toml stub (placeholder IDs), package.json + Hono v4/Drizzle/BetterAuth/Vitest/`@cloudflare/vitest-pool-workers` 의존성, tsconfig.json (Workers types), `.github/workflows/*.yml` placeholder, README setup runbook | 001 In Scope 1·10 (외부 자원 step 제외) |
| 2 | **로컬 검증 인프라** | `wrangler dev --local --persist`로 로컬 D1 + KV + R2 에뮬레이션, `@cloudflare/vitest-pool-workers` 통합 테스트 베이스, miniflare DX | (신규 — 외부 자원 미접촉 가정의 운영 모델) |
| 3 | **DB Layer** | Drizzle schema 14 테이블, 9 JSON 컬럼(`text({mode:'json'}).$type<T>()`), 14 FK, R2 UNIQUE 제약 3건 (`UNIQUE(assessment_id, domain)`, `UNIQUE(assessment_id)`, `UNIQUE(profile_id, context)` — Synthesis S-018-F2), R4 user 분리 컬럼(`email_hash` SHA-256 + `email_enc` envelope JSON + `encryption_version`), drizzle-kit ↔ wrangler d1 SOT(R1), 마이그레이션 + seed (PersonalityType × 16). | 001 In Scope 3 |
| 4 | **Domain Services Port** | 20 services / 1,850 LOC Ruby → TS. scoring 8단계 Pure Saga (R2: forward-recovery, status='failed' 마킹, 7/8 idempotent, step 7 UPSERT 보강). tone-filter, restricted-terms, insights 1:1 이식. Vitest 동등성 검증 (RSpec 18개 → Vitest 1:1 매핑). | 001 In Scope 4·8 |
| 5 | **Auth + Security Baseline** | BetterAuth(D1+KV) User 인증, CF Access JWT 검증 미들웨어 (admin SSO를 가정한 verifier 코드만 — 실 SSO 연결은 Phase 2), Web Crypto AES-256-GCM (IV=HMAC-SHA256(detKey, plaintext)[:12], envelope JSON), `email_hash` 생성 hook, KV 기반 sessions, parallel-key rotation 함수 (실 키 등록은 Phase 2). 보안 baseline 5종: CORS, CSP, HSTS, rate limit, hono CSRF (Origin + Sec-Fetch-Site 이중 체크). WAF는 외부 자원 → Phase 2. | 001 In Scope 6·17·18·19 (외부 SSO 연결 제외) |
| 6 | **API Layer + Mobile Contract** | 13 컨트롤러 + admin → Hono routes. 모바일 JSON API 신설 (현재 0 endpoint). OpenAPI 3 (`shared/api-schema/openapi.yaml`) + Hono RPC 또는 별도 codegen으로 Flutter Dart 클라이언트 자동 생성. API envelope 표준 (`{success, data, error: {code, message, details}}`) 미들웨어 + 에러 코드 카탈로그. wrangler dev fetch 테스트로 동작 검증. | 001 In Scope 5·11 + Decision 14·15 |
| 7 | **Admin UI + Public Assessment Flow SSR** (Cycle 6 영역 확장 — Synthesis S-018-F6) | admin 9 ERB → Hono SSR vanilla (~600 TSX). 공개 평가 흐름 18 ERB + 8 Stimulus → Hono SSR + hx-boost 1줄 옵셔널 (R3 winner). 공유 컴포넌트(~4). E2E smoke 테스트 (wrangler dev). | 001 In Scope 7 + EV-015-S1 흡수 |
| 8 | **Compliance (GDPR/PIPA)** | consent / deletion_request / audit_log / alert 모델 이전. 5개 흐름: consent 수집·철회, 계정 삭제 요청·처리, audit log, 국외 이전 고지·동의, 14세 미만 처리. admin + API 양쪽 노출. | 001 In Scope 16 |
| 9 | **Test Migration (분산)** | 18 RSpec / 2,641 LOC → Vitest. 사이클 3, 4, 5, 6, 8에 분산. `@cloudflare/vitest-pool-workers` D1 binding 통합 테스트 표준. TDD red-green-refactor. | 001 In Scope 8 |

### Out of Scope (Phase 2로 deferred)

| # | Item | Reason | Phase 2 재진입 조건 |
|---|------|--------|------------------|
| 1 | Toss 결제 7-stage | 사용자 deferred 결정 | 사용자 진행 의사 + Toss 가맹점 |
| 2 | Cutover safety (archive smoke + Phase rollback drill) | 외부 환경 의존 | Phase 1 완료 + 외부 환경 |
| 3 | Cutover execution (Phase A→B→C) | 외부 자원 + 사용자 결정 | Phase 1 완료 + 사용자 결정 |
| 4 | Production monitoring (Workers Analytics + Logpush + 알림) | 외부 자원 | 외부 deploy 후 |
| 5 | Foundation 외부 자원 (CF account, domain, 실 secrets, GitHub Actions secret 등록) | 사용자 자격증명 + 결정 | 사용자 작업 |
| 6 | CF Access 실 SSO 연결 | 외부 자원 | Phase 2 |
| 7 | D1 자동 export → R2 cron | production D1 + R2 필요 | Phase 2 |
| 8 | Rails 코드 archive 이동 + 폐기 | Phase 1 완료 후 | Phase 2 |
| 9 | 글로벌 결제 (Stripe) | Brief 001 Decision 13 계승 | 해외 법인/Stripe Korea |
| 10 | 새 도메인 기능 추가 | Brief 001 Out of Scope 6 계승 | 별도 phase |

## Decisions

| # | Decision | Chosen | Rationale | Trade-off | Alternatives Considered |
|---|----------|--------|-----------|-----------|------------------------|
| 1 | Phase 분리 전략 | **Brief 001 frozen + sub-phase Brief 021 활성** | Brief 001은 사용자 못박은 Full Migration 결정의 anchor — Phase 분리는 그 결정을 뒤집지 않고 실행 순서만 조정. Brief 021은 본 Phase 작업의 alignment anchor. | sub-phase Brief 추가로 anchor 2개 운영 부담 (관리 오버헤드 무시 가능 — 작업당 anchor 명확) | (a) Brief 001 amend 기각 — frozen 원칙 위반, history 손상 (b) 새 토픽 폴더 별도 분리 기각 — 같은 rebuild 작업의 sub-phase라 분리 인위적 |
| 2 | 외부 자원 미접촉 운영 모델 | **wrangler dev --local --persist + @cloudflare/vitest-pool-workers** | wrangler dev는 miniflare 기반으로 D1/KV/R2를 in-memory + persist 디렉토리로 에뮬레이션. vitest-pool-workers는 실 Workers 런타임에서 binding 통합 테스트 가능. 외부 자원 0으로 모든 도메인 작업 검증. | wrangler 에뮬레이션이 production D1과 100% 동등하지 않음 (read replication latency 등 실측 불가) — 그래서 verify는 로컬 검증, production 동등성은 Phase 2 cutover safety가 검증 | (a) 외부 dev environment 즉시 생성 기각 — 사용자 자격증명 필요 (b) 로컬 SQLite로 D1 가짜 흉내 기각 — wrangler emulation이 정합도 더 높음 |
| 3 | User schema 모델 | **R4 분리 컬럼(`email_hash` + `email_enc` + `encryption_version`)** + R1 envelope JSON 보존 | Synthesis S-018-F1 정합 결과: Eval R4가 R4 우위 판정 (rotation 부담이 낮아야 운영자가 실제 실행). R1 envelope JSON은 `email_enc` 컬럼 안에 그대로 저장 (Rails ActiveRecord::Encryption::Message wire-format 보존, Phase 2 cutover safety의 export 변환 시 호환). | R1 단일 컬럼 대비 컬럼 수 +2 (storage cost 무시 가능) | (a) R1 단일 결정성 컬럼 기각 (Eval R4 운영 현실 논리) (b) email cipher 단독 컬럼 기각 (lookup 불가) |
| 4 | Cycle 6 영역 정의 | **Admin UI + Public Assessment Flow SSR** (R3 winner Hono SSR vanilla + hx-boost 옵셔널) | Synthesis S-018-F6 영역 확장. R3 실측: admin 9 ERB / Stimulus 0이라 admin만으론 작업이 비대칭적으로 가벼움. 공개 평가 흐름 18 ERB + 8 Stimulus가 같은 Hono SSR 패턴으로 자연스럽게 흡수. | Cycle 6 ~4 MAN-DAY로 무게 증가 | (a) admin만 한정 기각 (Stimulus 8 무할당) (b) 별도 Cycle 11 신설 기각 (사이클 인플레) |
| 5 | scoring 8단계 정합 패턴 | **Pure Saga (D1 only) + forward-recovery** | R2 결정 채택. Eval R2 SUFFICIENT 6/6. 7/8 단계가 이미 idempotent, step 7만 UPSERT 보강. status='failed' 마킹으로 user-facing 일관성 확보. ~150 LOC saga + 200 LOC 절감 (DO 옵션 대비). | Durable Object의 in-process atomic 포기 (cross-user lock 불필요한 본 도메인엔 무관) | (a) Durable Object SQLite 기각 — 운영 단순성 우선 + DO 1k req/s 제약 |
| 6 | Admin UI 패턴 | **Hono SSR vanilla + hx-boost 1줄 옵셔널** | R3 결정 채택. admin 9 ERB / 293 LOC + 공개 평가 18 ERB / 8 Stimulus 모두 흡수 가능. 빌드 단일성(wrangler 단독). 1인 학습 곡선 0. | 향후 admin 복잡 인터랙션 시 htmx 점진 도입 필요 (자연 확장 경로) | (a) Astro 6 기각 (workerd dev 가능하나 콘텐츠 사이트 지향, admin CRUD에 과한 추상화) (b) Hono+HTMX 본격 도입 기각 (현 admin 단순도 대비 학습 곡선 정당화 안 됨) |
| 7 | 인증 패턴 | **BetterAuth(D1+KV) User + CF Access JWT verifier (실 SSO 연결 제외) Admin** | R4 결정 채택 (BetterAuth Active 확정 v1.6.9). Lucia v3 sunset 재확인. Admin verifier는 코드만 작성, 실 SSO는 Phase 2. Cookie 격리 (Synthesis BC1: Brief Anchor 9 minor 정정). | Phase 1에선 admin 실 인증 흐름 미검증 (verifier unit test로 보완) | (a) Lucia 재검토 기각 (v3 sunset 확정) (b) Auth.js 기각 (Workers 호환 약함) |
| 8 | API 응답 envelope | **`{success, data, error: {code, message, details}}` Hono 미들웨어로 강제** + 에러 코드 카탈로그 | Brief 001 Decision 15 계승. Flutter 클라이언트가 한 곳에서 처리. | 응답 크기 약간 증가 (무시 가능) | RFC 7807 Problem Details 기각 (모바일 클라이언트 적합성 약함) |
| 9 | API 스키마·codegen | **OpenAPI 3 + 코드 생성 (Hono RPC 또는 별도 codegen)** | Brief 001 Decision 14 계승. shared/api-schema/ ad-hoc 방지. | 스키마-코드 동기화 운영 부담 | 직접 Dart 핸드코딩 기각 (drift 위험) |
| 10 | TDD 적용 사이클 | **Cycles 2-6, 8 (코드 사이클)** | Brief 001 priority dimension에 conversion_fidelity 추가. RSpec 동등성 검증이 Phase 1 핵심 — Vitest 테스트 먼저 작성(red), 구현(green), 리팩터(refactor). | tdd-red 단계로 사이클당 1 step 추가 | (a) 모든 사이클 TDD 기각 (Cycle 1 한정형은 파일 템플릿이라 단위 테스트 의미 적음) (b) TDD 미적용 기각 (RSpec 동등성 보장 약화) |
| 11 | Toss 결제 정정 결과 처리 | **Synthesis BC2/BC3 사항을 Phase 2 Brief 022 작성 시 입력 자료로 보존** | Synthesis BC2 (webhook 모델 이중화) + BC3 (idempotency key 명칭) 정정 사항은 Phase 1에서 미사용. Phase 2 재진입 시 그대로 활용. | Phase 1에서 Toss 코드 0 작성 (의도된 결정) | — |
| 12 | Phase 1 verify 모델 (**C1 보강 — W3 Critical**) | **로컬 검증만** (wrangler dev fetch + vitest binding 테스트 + RSpec 동등성). **Ideal Criteria 28개 중 19개 = 로컬 완결, 9개 = Partial(local+production-only 일부 갭), 2개 = Directional. 갭 항목(#6 wire-format Rails import, #14 Web Crypto byte-level workerd↔production, #15 실 wrangler secret rotation, #18 OpenAPI 실 응답 호환)은 Phase 2 carryover로 명시.** **R2 multipart upload, KV 60s eventual consistency, JWKS 6주 rotation은 Phase 2 검증 항목**. | 외부 자원 미접촉 가정 일관 + production-only 갭 9건이 Phase 1에서 미검증 (의도된 — Phase 2 cutover safety가 담당) | external dev environment 사용 기각 (외부 자원 의존) |
| 13 | Phase 1 완료 정의 | **활성 7 사이클(Foundation 한정형 + DB + Services + Auth + API + Admin/Public + Compliance) + 분산 테스트 모두 verify 통과 + Vitest로 RSpec 18개 동등성 입증** | Phase 2 재진입 시 사용자가 본 결과를 신뢰할 수 있는 명확한 게이트 | Phase 1이 production deploy 전이라 사용자 visible 결과 부재 (의도된 — 외부 자원 미접촉 가정) | Phase 1을 partial deploy까지 확장 기각 (외부 자원 의존) |
| 14 | Pipeline 재진입 전략 (**C2 보강 — W2 Critical**) | **현 pipeline DB(`007_cf_workers_rebuild_1c64.db`)에서 Cycle 7 (Toss seq 35-38) + Cycle 9 (Cutover safety seq 43-45) + Cycle 10 makeplan/impl/verify (seq 46-48)를 `pipeline.sh edit <seq> status interrupted "phase-2-deferred"` 처리** (Synthesis 025 직후 적용 완료). Cycle 10의 eval/qualify/push (seq 49-51) + cycle-99 retro impl는 Phase 1 tail로 활성 유지. Cycle 1 implementation은 Plan 020 외부 자원 step skip 후 한정형으로 진행. | status enum에 'deferred' 부재로 'interrupted' 차용 (reason 필드에 'phase-2-deferred') | (a) 새 pipeline DB init 기각 (history 손실) (b) status enum 확장 기각 (스키마 변경 risk) |
| 15 | wrangler.toml compatibility (**MS3 신규 — W1 Missing**) | **`compatibility_date = "2026-04-01"`, `compatibility_flags = ["nodejs_compat"]`**. Plan 020 Step 1에서 명시. | 향후 신규 flag 도입 시 명시 변경 필요 | flag 미설정 기각 (build-time 변동 위험) |

## Open Questions

없음 — 모든 결정 autonomous로 정리됨. Phase 2 재진입 시점·조건은 사용자 결정 영역(Phase 1 완료 후 별도 결정).

## Constraints

- **Brief 001의 모든 frozen 결정 승계** — Drizzle, Hono, BetterAuth, Cloudflare Access(verifier만 Phase 1), Hono SSR vanilla, archive 보존, 단계적 cutover 등 13 Decisions 그대로
- **외부 자원 미접촉** — wrangler dev --local --persist + @cloudflare/vitest-pool-workers 외 외부 호출 금지. 사용자 자격증명·계정 작업 0
- **TDD red-green-refactor** — Cycles 2-6, 8 적용. tdd-red sub-agent가 실패 테스트 먼저 작성 후 makeplan
- **20 MAN-DAY 추정 한도** — 50% 초과 시 Brief 재검토 트리거 (= 30 MD)
- **Phase 2 재진입 호환성 보존** — Brief 001 + 본 Brief 021 모두 anchor 유지. Phase 1 산출물이 Phase 2의 Toss/Cutover 작업의 입력으로 그대로 사용 가능해야 함
- **conversion_fidelity 우선** — RSpec 18개에 대한 Vitest 1:1 동등성 + 도메인 services 1,850 LOC 회귀 0
- **archive Rails 미접촉** — Phase 1은 server/ 디렉토리 read-only (참조용), 코드 추가/삭제 금지

## Exit Criteria (본 Brief가 scope 시작 준비)

- [x] Phase 분리 전략 명시 (Decision 1)
- [x] 활성 9 In Scope + 10 Out of Scope 정의
- [x] Brief 001 결정 승계 명시 + 정정 흡수 (Synthesis BC1/2/3)
- [x] 외부 자원 미접촉 운영 모델 결정 (Decision 2)
- [x] 14 Decisions 모두 autonomous 결정 + Critical Review 0건 (모두 reversible)
- [x] Quality Profile = Standard, priority_dimensions에 conversion_fidelity 추가
- [x] Ideal Criteria 정의
- [x] Model Anchors 정의
- [x] Pipeline 재진입 전략 (Decision 14)

## Ideal Criteria

**Quality Profile**: Standard · **Priority Dimensions**: Conversion Fidelity, Sustainability, Completeness, Security
(conversion_fidelity 추가로 RSpec 동등성 차원 criteria 1단계 상향)

| # | Criterion | References (In Scope #) | Type | Dimension |
|---|-----------|------------------------|------|-----------|
| 1 | wrangler.toml stub + package.json + tsconfig + .github/workflows placeholder가 모두 생성되고 npm install이 성공하는가 | 1 | assertion | Function |
| 2 | wrangler dev --local --persist으로 D1 + KV + R2 binding이 모두 응답하는가 | 2 | assertion | Function |
| 3 | @cloudflare/vitest-pool-workers 베이스로 D1 binding 단위 테스트가 통과하는가 | 2 | assertion | Function |
| 4 | 14 테이블 Drizzle schema가 정의되고 drizzle-kit generate + wrangler d1 migrations apply --local이 성공하는가 | 3 | assertion | Function |
| 5 | 9 JSON 컬럼이 D1 JSON1 함수와 호환되는가 (json_extract 쿼리 테스트) | 3 | assertion | **Conversion Fidelity / Edge** |
| 6 | R4 분리 컬럼(`email_hash` + `email_enc` + `encryption_version`) + R1 envelope JSON wire-format이 일관되게 동작하는가 | 3, 5 | assertion | **Conversion Fidelity / Security** |
| 7 | R2 UNIQUE 제약 3건(domain_scores/profiles/insights)이 schema에 강제되고 saga forward-recovery가 작동하는가 | 3, 4 | assertion | **Conversion Fidelity** |
| 8 | PersonalityType × 16 seed가 정상 삽입되는가 | 3 | assertion | Completeness |
| 9 | 도메인 services 1,850 LOC가 TypeScript로 이식되고 Vitest 동등성 테스트 통과하는가 | 4 | assertion | **Conversion Fidelity** |
| 10 | scoring 8단계 Pure Saga가 step 7 UPSERT 보강 후 forward-recovery로 정합 보장하는가 | 4 | assertion | Function |
| 11 | RSpec 18개가 Vitest로 1:1 매핑되고 동등성을 입증하는가 | 4, 9 | assertion | **Conversion Fidelity** |
| 12 | BetterAuth(D1+KV) User 인증이 sign-up/in/out 통과하는가 | 5 | assertion | Function |
| 13 | CF Access JWT verifier 미들웨어가 fixture JWT를 정확히 검증/거부하는가 | 5 | assertion | Function |
| 14 | Web Crypto AES-256-GCM (IV=HMAC) envelope JSON이 결정성 lookup + 복호화 모두 통과하는가 | 5 | assertion | **Conversion Fidelity / Security** |
| 15 | parallel-key rotation 함수가 K_n / K_{n+1} dual-read를 정확히 처리하는가 (실 키 등록 없이 fixture로 검증) | 5 | assertion | **Security / Edge** |
| 16 | 보안 baseline 5종(CORS/CSP/HSTS/rate limit/CSRF) 미들웨어가 활성화되고 단위 테스트 통과하는가 | 5 | assertion | **Security** |
| 17 | Hono routes가 13 컨트롤러 + admin을 모두 매핑하고 wrangler dev에서 응답하는가 | 6 | assertion | Function |
| 18 | OpenAPI 3 스키마 + Flutter Dart 클라이언트 자동 생성이 작동하는가 | 6 | assertion | Function |
| 19 | API envelope (`{success, data, error}`) + 에러 코드 카탈로그가 일관 적용됐는가 | 6 | assertion | Function |
| 20 | 모바일 API 엔드포인트가 신설되고 Flutter 호출 fixture 테스트 통과하는가 | 6 | assertion | Function |
| 21 | admin 9 ERB가 Hono SSR vanilla로 1:1 기능 동등하게 이식됐는가 | 7 | assertion | **Conversion Fidelity / Completeness** |
| 22 | 공개 평가 흐름 18 ERB + 8 Stimulus가 Hono SSR + hx-boost 패턴으로 동작하는가 (E2E smoke wrangler dev) | 7 | assertion | **Conversion Fidelity / UX** |
| 23 | GDPR/PIPA 5 흐름(consent/deletion/audit/국외 이전/14세 미만)이 모두 구현됐는가 | 8 | assertion | **Completeness / Security** |
| 24 | consent / deletion_request / audit_log / alert 모델이 R4 user 모델과 정합하게 작동하는가 | 8 | assertion | **Conversion Fidelity** |
| 25 | TDD red-green-refactor 흐름이 Cycles 2-6, 8 모두 수행됐는가 (tdd-red 산출물 존재 확인) | 9 | directional | **Conversion Fidelity** |
| 26 | Phase 1 완료 시점에 외부 자원(CF account/domain/실 secret) 호출 0건인가 | constraint | assertion | Sustainability |
| 27 | Phase 2 재진입 시 Brief 001 + 본 Brief 021 + Toss 정정사항(BC2/BC3)이 그대로 anchor로 활용 가능한가 | Decision 11 | directional | Sustainability |
| 28 | 20 MAN-DAY 추정 한도 내에서 Phase 1이 완료되는가 (50% 초과 시 Brief 재검토 트리거) | Constraint | directional | Sustainability |

## Model Anchors

1. **본 Brief는 sub-phase Brief — Brief 001을 frozen anchor로 유지**. Brief 001의 13 Decisions(Drizzle, Hono, BetterAuth, archive 보존 등)는 본 Phase에서 모두 그대로 적용. 결정 재논의 금지.

2. **외부 자원 미접촉이 본 Phase의 핵심 제약**. wrangler dev --local --persist + @cloudflare/vitest-pool-workers 외 외부 호출 금지. CF dashboard, custom domain 등록, 실 secret 값, GitHub Actions secret, 1Password vault 등록은 Phase 2.

3. **활성 In Scope 9개**: Foundation 한정형 / 로컬 검증 인프라 / DB Layer / Domain Services Port / Auth + Security Baseline / API Layer + Mobile Contract / Admin UI + Public Assessment Flow SSR / Compliance / Test Migration. 그 외 Brief 001 항목은 Phase 2.

4. **User schema = R4 패턴 채택** (`email_hash` SHA-256 + `email_enc` envelope JSON + `encryption_version`). R1 envelope JSON은 `email_enc` 컬럼 값으로 그대로 저장 (Rails wire-format 보존). 단일 결정성 컬럼 패턴 사용 금지.

5. **R2 UNIQUE 제약 3건은 schema 차원에서 강제**: `UNIQUE(assessment_id, domain)` (domain_scores), `UNIQUE(assessment_id)` (profiles), `UNIQUE(profile_id, context)` (insights). Cycle 2 Drizzle schema 작성 시 누락 금지.

6. **scoring saga = Pure Saga (D1 only)**. Durable Object 사용 금지 (cross-user lock 불필요). 8단계 중 step 7 Profile create는 `INSERT ... ON CONFLICT(assessment_id) DO UPDATE` 패턴 강제. 보상은 forward-recovery (status='failed' 마킹).

7. **Admin UI = Hono SSR vanilla + hx-boost 옵셔널** (R3 winner). Astro 6 / Hono+HTMX 도입 금지. 공개 평가 흐름도 동일 패턴 사용.

8. **인증 = BetterAuth User + CF Access verifier (코드만)**. Lucia v3 사용 금지. 실 SSO 연결은 Phase 2. Cookie domain 격리 (api ↔ admin disjoint, BC1 정정 적용).

9. **TDD red-green-refactor 강제 적용 사이클**: 2, 3, 4, 5, 6, 8. tdd-red sub-agent가 먼저 실패 테스트 작성 후 makeplan 진입. 사이클 1, 9, 10은 procedural이라 미적용.

10. **Toss 결제 코드 0**. Phase 1에서 Toss 관련 파일·미들웨어·webhook handler 작성 금지. Synthesis BC2(웹훅 모델 이중화)·BC3(idempotency key 명칭) 정정사항은 Phase 2 Brief 022에서 활용.

11. **archive Rails read-only**. server/ 디렉토리는 참조용 read만 허용. 코드 추가/수정/삭제 금지. archive 이동·smoke test·Phase rollback drill은 모두 Phase 2.

12. **Pipeline DB는 기존 `007_cf_workers_rebuild_1c64.db` 재사용**. 새 init 금지 (research history 손실). 사이클 7(Toss seq 35-38) + 9(cutover safety seq 43-45) + 10 makeplan/impl/verify(seq 46-48)은 **`pipeline.sh edit <seq> status interrupted "phase-2-deferred"`로 처리** (적용 완료 — Synthesis 025 직후). Cycle 10 eval/qualify/push (seq 49-51) + cycle-99 retro는 Phase 1 tail로 활성 유지. Cycle 1 implementation은 Plan 020의 외부 자원 step(U1-U8) skip 후 한정형으로 진행.

13. **MAN-DAY 한도 = 20**. 50% 초과(=30 MD) 시 사용자 보고 + Brief 재검토.

14. **Phase 1 완료 = 본 Brief 021 Ideal Criteria 28개 중 assertion 26개 + directional 2개의 directional은 합리적 수준 충족**.

15. **OpenAPI 3 + Flutter codegen은 ad-hoc 결정 금지**. Brief 001 Decision 14 계승. shared/api-schema/openapi.yaml + 자동 생성 도구 명시.

16. **API envelope `{success, data, error: {code, message, details}}`**는 Hono 미들웨어 한 곳에서 강제. Brief 001 Decision 15 계승.

17. **Phase 2 재진입 호환성 보존**. 본 Phase 산출물(코드, schema, 테스트, runbook)은 Phase 2 Toss/Cutover 작업의 입력으로 그대로 사용 가능해야 함. archive 호환 변환 스크립트는 Phase 2에서 작성.

## Phase 2 Carryover Inputs (M6 + MS1 신규 섹션 — W2 Major)

Phase 2 Brief 022 작성자가 단일 인덱스로 입력 자료 확보할 수 있도록 모든 carryover를 모음.

### 2.1 Toss 결제 정정사항 (Synthesis 018 BC2/BC3, Phase 1 unused)

| ID | 정정 내용 | 1차 출처 |
|----|---------|---------|
| BC2 | Toss webhook 모델 이중화: Model A `Payment.secret` 비교 (PAYMENT_STATUS_CHANGED, DEPOSIT_CALLBACK 등 결제 webhook), Model B HMAC-SHA256 v1 (payouts/seller webhook 전용, 헤더 `tosspayments-webhook-signature: v1:<b64>,<b64>`) | docs.tosspayments.com/reference/using-api/webhook-events |
| BC3 | idempotency key 정확 명칭: `tosspayments-webhook-transmission-id` (Brief 001은 `event_id` 추정) | 동일 |
| BC2-related | 가맹점→Toss `Idempotency-Key` 헤더: 300자 max, 15일 유효, cancel API 필수 | docs.tosspayments.com/reference |
| BC2-related | 재시도 정책: 7회, 1·4·16·64·256·1024·4096분, 약 3일 19시간, 10초 응답 필수 → `ctx.waitUntil` 패턴 | 동일 |
| BC2-related | 환불·취소: 별도 webhook event 없음 — PAYMENT_STATUS_CHANGED 재발화로 status sync | 동일 |

### 2.2 5 Open Questions (Synthesis 018 § 6, Phase 1에서 makeplan별 해결 또는 Phase 2 carryover)

| OQ | 질문 | 해결 시점 |
|----|------|---------|
| OQ-1 | Cycle 6 공개 평가 흐름 정확한 LOC + 인터랙션 매핑 (8 Stimulus → Hono SSR + hx-boost 또는 본격 htmx) | Cycle 6 makeplan |
| OQ-2 | BetterAuth `email_hash` 생성 hook 위치 (before-create 또는 mounter 미들웨어) | Cycle 4 makeplan |
| OQ-3 | Cycle 7 webhook 모델 B (HMAC v1) dormant 코드 작성 여부 | **Phase 2 Cycle 7 makeplan** |
| OQ-4 | Cycle 9 archive smoke test 자동화 빈도 (월 1회 또는 분기 1회) | **Phase 2 Cycle 9 makeplan** |
| OQ-5 | Cycle 4 Hono CSRF 보완(Origin + Sec-Fetch-Site) 미들웨어 분기 (모바일 Bearer JWT bypass + admin strict Origin) | Cycle 4/5 makeplan 통합 |

### 2.3 Phase 1 Critique Carryover (W1/W2/W3 Phase 2로 이연)

| 출처 | 내용 | Phase 2 처리 |
|------|------|-------------|
| W3 #6 | R4 envelope JSON wire-format Rails 호환 검증 | Phase 2 Cycle 9 archive smoke test에서 실 export 데이터 import 검증 |
| W3 #14 | Web Crypto AES-GCM IV=HMAC byte-level workerd↔production 동일성 | Phase 2 staging deploy 후 fixture 데이터 cross-environment 비교 |
| W3 #15 | parallel-key rotation 실 wrangler secret rotation flow | Phase 2 Cycle 4 추가 sub-cycle 또는 Cycle 9 drill |
| W3 #18 | OpenAPI 3 + Flutter codegen compatibility flag + 실 응답 호환 | Phase 2 staging API 호출 + Dart 클라이언트 회귀 테스트 |
| W3 M2 | D1 Sessions API (read replication 일관성, bookmark 기반) | Phase 2 read replica 활성화 시점 결정 |
| W3 M3 | KV 60s eventual consistency 정책 | Phase 2 production session 동작 검증 |
| W3 M4 | R2 multipart upload | Phase 2 D1 backup 산출물 크기 ≥5GB 시 |
| W3 M5 | CF JWKS 6주 rotation | Phase 2 첫 rotation cycle (deploy 후 6주 시점) |
| W2 M1 | Plan 020 Step 8 D1 cron handler stub-only로 변경 | **Phase 1 Plan 020 보강 + Phase 2 Cycle 9에서 활성화** |
| W2 M3 | server/ baseline t0 측정 (Ruby 3.4.2, Gemfile.lock hash) | **Phase 1 시작 직전 (= 즉시) 측정 후 Phase 2 archive smoke test 비교 기준** |

### 2.4 Tooling 버전 pin (MS2 + Mn7 — Constraints 보강 권고)

| 도구 | pinned version | 사유 |
|------|--------------|------|
| wrangler | ≥3.80.x (2026-04 기준 최신 stable) | D1/KV/R2 emulation, vitest-pool-workers 호환 |
| @cloudflare/vitest-pool-workers | ≥0.7.x | D1 binding 통합 테스트 표준 |
| drizzle-kit | ≥0.28.x | drizzle-orm 0.36+ 호환 |
| drizzle-orm | ≥0.36.x | D1 driver, JSON column type 안정 |
| hono | ≥4.6.x | RPC, csrf middleware 안정 |
| better-auth | ≥1.6.9 (2026-04-24 latest) | D1 first-class (1.5.0+), KV SecondaryStorage |
| miniflare | ≥3.x | wrangler dev backend |

본 표는 Phase 1 시작 시점 t0 기준. 변경 시 Brief 갱신.

## Critique Integration

본 Brief는 --deep critique 3 관점(022 Phase Split Feasibility, 023 Phase 2 재진입 가능성, 024 로컬 검증 모델 한계) 통합본. Synthesis 025가 18개 발견(2 Critical + 11 Major + 7 Minor + 3 Missing)을 정렬.

### 반영 항목 (P1 Critical + P2 Major + P3 Minor)

| # | Source | Severity | Finding | Brief 021 반영 위치 |
|---|--------|----------|---------|------------------|
| C1 | W3 + W1 | Critical | Exit Criteria conversion_fidelity 오버스테이트 — production-only 갭 9건이 "Phase 1 동등 입증" 표기 | Decision 12 보강 + Phase 2 Carryover § 2.3 |
| C2 | W2 | Critical | Pipeline DB Cycle 7/9/10 status='pending' (deferred 부재) → No-Stop 자동 디스패치 위험 | Decision 14 보강 + Anchor 12 보강 + DB 작업 적용 완료 (10 items interrupted) |
| M1 | W1 P1 | Major | Decision 7 CF Access verifier에 JWKS resolver DI 패턴 부재 | Decision 7 부분 (verifier signature는 makeplan에서 명시) |
| M2 | W1 P2 | Major | OpenAPI Dart codegen JAR + Maven Central = build-time 외부 의존성 | Decision 9·15 + Anchor 2 (외부 자원 정의 확장) |
| M3 | W1 P3 | Major | Hono CSRF origin-check 한계 caveat 약화 | In Scope 5 + Anchor 8 명시 (csrf 미들웨어 한계) |
| M4 | W1 | Major | Decision 12에 Local/Partial/Production-only 매트릭스 부재 | Decision 12 보강 (C1과 통합) |
| M5 | W2 | Major | Plan 020 Step 8 D1 cron handler가 wrangler dev에서 미동작 | In Scope 1 (cron handler stub-only Phase 2 활성) + Phase 2 Carryover § 2.3 |
| M6 | W2 | Major | BC2/BC3 추적 3-hop chain | Phase 2 Carryover Inputs 신규 섹션 (§ 2.1) |
| M7 | W2 | Major | server/ 시간 함수 부패 | Constraints 보강 + Phase 2 Carryover § 2.3 |
| M8 | W3 | Major | D1 Sessions API 결정 누락 | Phase 2 Carryover § 2.3 (M8 항목) |
| M9 | W3 | Major | KV 60s eventual consistency | Phase 2 Carryover § 2.3 (M9 항목) + In Scope 5 |
| M10 | W3 | Major | R2 multipart 미검증 | Phase 2 Carryover § 2.3 |
| M11 | W3 | Major | CF JWKS 6주 rotation 미검증 | Phase 2 Carryover § 2.3 + Decision 7 |
| Mn1 | W1 | Minor | Anchor 2 외부 자원 정의 명시 부족 | Anchor 2 (M2와 통합) |
| Mn2 | W1 | Minor | Ideal Criteria #15 type=directional | Ideal Criteria 표 |
| Mn5 | W2 | Minor | Anchor 17 검증 메커니즘 directional → 명시 | Anchor 17 (Phase 2 Carryover 섹션 참조 추가) |
| Mn7 + MS2 | W3 + W1 | Minor + Missing | 도구 버전 pin | Phase 2 Carryover § 2.4 + Constraints |
| MS1 | W1 | Missing | Phase 2 Carryover Inputs 섹션 부재 | 신규 섹션 추가 (위 § 2 전체) |
| MS3 | W1 | Missing | wrangler.toml compatibility_flags 결정 | Decision 15 신규 |

### 위임 (Brief 미수정, makeplan에서 처리)

| # | 발견 | 위임처 |
|---|------|--------|
| Mn3 | wrangler dev --local 환경변수 명시 | Cycle 1/Cycle 2 makeplan |
| Mn4 | Plan 020 referenced 파일 갱신 | Plan 020 보강 (별도 작업) |
| Mn6 | cookie domain 로컬 무의미 (테스트 시 hostname mock) | Cycle 4 makeplan |

### 비평이 검증한 강점 (Brief 021 유지)

- Phase 분리 결정 자체는 3 관점 모두 confidence: high "구조적으로 sound"
- External 자원 0 운영 모델은 공식 docs 뒷받침 (W1 strengths)
- Brief 001 frozen + sub-phase Brief 021 활성: anchor 2개 운영, history 손상 0 (W1+W2 strengths)
- R4 schema 패턴 채택 정합 보존 (W3 strengths)

## References (보강 후)

| Resource | Path | Relevance |
|----------|------|-----------|
| Brief 001 (frozen parent) | [`001_Brief_cf_workers_rebuild.md`](./001_Brief_cf_workers_rebuild.md) | Full Migration anchor |
| Critique 022 W1 | [`022_Critique_phase_feasibility.md`](./022_Critique_phase_feasibility.md) | Phase 분리 feasibility |
| Critique 023 W2 | [`023_Critique_phase2_reentry.md`](./023_Critique_phase2_reentry.md) | Phase 2 재진입 가능성 |
| Critique 024 W3 | [`024_Critique_local_verification.md`](./024_Critique_local_verification.md) | 로컬 검증 모델 한계 |
| Critique Synthesis | [`025_Critique_Synthesis.md`](./025_Critique_Synthesis.md) | 18 finding 통합 |
| Synthesis 018 (research) | [`018_Synthesis_research_cycle.md`](./018_Synthesis_research_cycle.md) | 5축 cross-axis 정합 |
| Plan 020 (Cycle 1) | [`020_Plan_cycle1_foundation.md`](./020_Plan_cycle1_foundation.md) | Cycle 1 Foundation (한정형 재정의 필요 — M5) |
| Pipeline DB | `tmp/007_cf_workers_rebuild_1c64.db` | C2 적용 완료 (10 items interrupted) |

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
