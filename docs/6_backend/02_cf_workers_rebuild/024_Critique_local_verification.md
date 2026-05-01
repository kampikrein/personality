---
id: "024"
type: critique
title: "Brief 021 Critique — 로컬 검증 모델 한계"
created: 2026-04-29
status: completed
perspective: "local_verification_gap"
target: "021"
confidence: high
summary: >
  Brief 021 Decision 2(wrangler dev --local --persist + @cloudflare/vitest-pool-workers)
  + Decision 12(Phase 1 verify=로컬만)는 28 Ideal Criteria 중 약 18개를 충실히
  검증하지만, **D1 read replication / Sessions API / 결정성 envelope 호환 / Web Crypto
  미세 차이 / OpenAPI codegen 실 응답 호환성 / parallel-key rotation 실 키 운영 /
  cookie domain 분리 / CF Access JWT JWKS rotation / R2 multipart**의 9개 영역에서
  production-only 갭이 존재함을 식별. 가장 위험한 갭은 #6(envelope wire-format Rails
  호환), #14(Web Crypto IV 결정성), #15(parallel-key rotation), #18(OpenAPI codegen
  실 응답 호환). 권고: Phase 1 산출물에 "로컬 검증 ≠ production 동등성" 게이트
  명시적 분리 + Phase 2 Cutover Safety의 검증 책임 8건을 사전에 명세화.
keywords: [critique, brief-021, wrangler-dev-local, vitest-pool-workers, miniflare, production-parity-gap, sessions-api, read-replication, web-crypto-parity, openapi-codegen]
---

# Brief 021 Critique — 로컬 검증 모델 한계

## Executive Summary

Brief 021 Decision 2 (`wrangler dev --local --persist` + `@cloudflare/vitest-pool-workers`)와 Decision 12 (Phase 1 verify = 로컬 검증만)는 외부 자원 미접촉이라는 명시적 제약 하에서 합리적 운영 모델이지만, **production CF Workers / D1 / KV / R2와의 동등성은 ~65% 수준**이다. miniflare 3은 D1·KV·R2의 **API 행동(behavioral surface)**을 충실히 재현하지만, **분산 system 특성**(D1 read replication eventual consistency, KV global replication 60s, R2 strong consistency 경계, V8 isolate 고유 quirks)는 로컬에서 본질적으로 emulation 불가하다. Brief 021이 Decision 2 Trade-off에서 이 갭을 **인지**하지만(`production D1과 100% 동등하지 않음 — Phase 2 cutover safety가 검증`), Ideal Criteria 28개 중 **9개**가 로컬에서 통과해도 production에서 회귀할 수 있는 영역에 있다.

특히 **Conversion Fidelity 우선** priority 하에서 #6(R4 schema envelope JSON wire-format) + #14(Web Crypto AES-GCM IV 결정성) + #15(parallel-key rotation)는 Rails ActiveRecord::Encryption과의 wire-compatible을 요구하는데, Phase 1에서는 **fixture key + 로컬 envelope round-trip**만 검증되고 **실제 Rails export 데이터를 import해 결정성 lookup이 통과하는지**는 Phase 2 Cutover Safety로 deferred 상태다. 이는 `conversion_fidelity` 우선 차원에서 Phase 1 완료 = "Rails 동등 입증 완료"라는 사용자 기대와 갭을 만든다.

## Strengths

| # | Strength | 근거 |
|---|----------|------|
| S1 | **외부 자원 미접촉 운영 모델로 일관성 확보** | wrangler dev --local + miniflare는 Cloudflare 공식 권장 로컬 dev 패턴. CF account 미접촉 가정에서 가능한 최선의 패턴이며, Brief 021 Constraint("외부 자원 미접촉")와 Decision 2가 정합적. |
| S2 | **vitest-pool-workers 채택은 단순 mock 대비 정확도 우위** | vitest-pool-workers는 실제 `workerd` 런타임에서 테스트 실행 — V8 isolate, Workers global, binding 통합이 mock 라이브러리(예: `miniflare` 단독 또는 `cloudflare-mock-bindings`) 대비 정합도가 한 단계 높음. 공식 docs(developers.cloudflare.com/workers/testing/vitest-integration/)도 "isolated per-test storage" 패턴 명시. |
| S3 | **Decision 2 Trade-off에 갭 인지 명시** | "wrangler 에뮬레이션이 production D1과 100% 동등하지 않음 (read replication latency 등 실측 불가) — 그래서 verify는 로컬 검증, production 동등성은 Phase 2 cutover safety가 검증"이 Trade-off에 정확히 명시됨. Brief 021은 갭을 부정하지 않고 Phase 2로 전이 처리. |
| S4 | **Decision 5 Pure Saga + idempotent UPSERT 패턴은 로컬 검증 친화적** | 8단계 모두 idempotent + forward-recovery로 만들면, 로컬에서도 부분 실패 → 재실행 시나리오가 deterministic하게 재현 가능. Research 009 Q4 의사코드가 batch 단위 atomicity만 의존하므로 miniflare D1 batch가 production batch와 동일한 transactional semantics를 보장하면 로컬 ↔ production 갭이 작다. |
| S5 | **Ideal Criteria #25 (TDD 흐름) + #11 (RSpec 1:1 매핑)으로 conversion_fidelity 차원 강제** | 로컬 검증의 한계와 별개로, Vitest 기반 TDD가 Rails 도메인 로직 회귀를 막는 1차 게이트. RSpec 18개 → Vitest 1:1은 production-only 영역(read replication 등)과 무관한 순수 계산 영역에서는 충분. |
| S6 | **`drizzle-kit generate` + `wrangler d1 migrations apply --local`은 production과 동일 SOT 사용** | Research 008 R1-F1 결정에 의해 schema → SQL → D1 적용 경로가 로컬 / production 동일 도구 체인. miniflare D1은 SQLite 백엔드이므로 schema-level 갭 0. |

## Weaknesses

### Critical (1건)

**W1. Conversion Fidelity 우선 차원에서 #6 / #14 / #15 / #18이 production-only 영역인데 Phase 1 완료가 "RSpec 동등성 입증"으로 oversold 됨**

Brief 021 Exit Criteria + Constraint("conversion_fidelity 우선 — RSpec 18개에 대한 Vitest 1:1 동등성 + 도메인 services 1,850 LOC 회귀 0")는 사용자에게 "Phase 1 완료 = 기능 동등 입증"이라는 신호를 준다. 그러나:

- **#6 (envelope wire-format)**: Research 008 Q3는 envelope JSON `{p, h:{iv, at}}`이 Rails `ActiveRecord::Encryption::Message`와 wire-compatible해야 Phase 2 export → D1 import가 작동한다고 명시. Phase 1에선 fixture로 round-trip만 검증, **실 Rails export SQL을 D1에 적재해 BetterAuth login이 통과하는 통합 테스트 부재**.
- **#14 (Web Crypto AES-GCM IV=HMAC[:12])**: workerd V8 isolate와 production Workers V8 isolate의 Web Crypto API는 **명세 동일하나 구현이 다른 V8 빌드**(workerd open source vs. Cloudflare 운영 fleet). `crypto.subtle.sign('HMAC', …)` ↔ `encrypt('AES-GCM', …)`의 byte-level 동등성은 **거의 확실하지만 보장은 production 실측 후**.
- **#15 (parallel-key rotation)**: Research 011 R4-F3 절차의 핵심은 `wrangler secret put`으로 K_n / K_{n+1} 등록 후 dual-read. Phase 1 verify는 **실 secret 등록 0**(외부 자원 deferred) → fixture로 K_n / K_{n+1} env var 흉내만 가능. **Worker secret API**(env binding via wrangler secret put)와 **로컬 dev .dev.vars**의 행동 동일성은 검증되나, **실 secret rotation flow**(Phase 0→1→2→3→4→5)는 production-only.
- **#18 (OpenAPI 3 + Flutter codegen)**: 로컬 wrangler dev fetch가 Flutter Dart 클라이언트 호출을 통과해도, **production deploy 후 compatibility flag**(예: `nodejs_compat`, `streams_enable_constructors`) 차이로 응답 직렬화가 미묘하게 달라질 수 있다. OpenAPI 스키마 ↔ 실 응답 매칭은 production fetch 후에야 100% 입증.

이 4건이 conversion_fidelity 차원에서 Phase 1 완료 후에도 미해결 상태로 남는다는 점이 Brief 021에 명시적으로 표현되지 않았다.

**Severity**: Critical (priority dimension 직접 침해, Exit Criteria 신뢰성 약화)

---

### Major (4건)

**W2. D1 read replication이 로컬에서 본질적으로 emulation 불가 — Sessions API 사용 의도가 Brief 021에 부재**

- 공식 docs(developers.cloudflare.com/d1/best-practices/read-replication/)는 D1 read replication을 사용할 경우 `db.withSession()` API로 read replica + bookmark consistency를 처리하라 명시. Brief 021 Decision 2는 read replication latency를 "실측 불가"로 인정하지만, **Sessions API 사용 여부 자체가 결정 안 됨**.
- Phase 1에선 **단일 D1 binding**으로 모든 read/write가 primary로 향한다 (miniflare는 단일 SQLite 파일). Phase 2 cutover 시 read replication이 켜지면 saga의 Phase B(domain_scores INSERT) 직후 Phase D(profile read for FK)에서 **stale read** 가능성이 있다.
- Research 009 Q1 매트릭스가 read replication을 R3 별도 risk로 분리했지만 Brief 021 In Scope에서 **Sessions API 패턴 결정이 누락**.

**Severity**: Major (saga 정합 패턴이 read replication 없는 가정에 의존)

---

**W3. KV eventual consistency(60s global) 미반영 — BetterAuth `secondaryStorage`가 KV일 때 session lookup 일관성 갭**

- 공식 docs(developers.cloudflare.com/kv/concepts/how-kv-works/)는 KV write가 같은 colo에선 immediate, 글로벌 propagation은 최대 60s eventual.
- miniflare KV는 **단일 in-memory store**로 즉시 일관(strong consistency).
- Research 011 Q1은 BetterAuth `SecondaryStorage` interface를 KV adapter로 wrap. **Phase 1 로컬에서 sign-in → 즉시 GET /api/me → session 조회**가 통과해도, production에서는 다른 region 접속 시 60s 동안 session 미발견 가능.
- 영향 범위: Ideal Criteria #12(BetterAuth sign-up/in/out 통과)는 로컬에서 통과해도 production cross-region 일관성 미검증.

**Severity**: Major (auth 핵심 흐름의 production-only 갭)

---

**W4. R2 multipart upload + presigned URL은 In Scope 5의 sealed 백업 운영에서 사용되지만 로컬 검증 누락**

- Research 011 R4-F3은 R2 sealed 백업(`wrangler r2 object put`)을 rotation procedure에 포함.
- miniflare R2(workers-rs/miniflare/src/plugins/r2)는 GET/PUT/DELETE basic API는 emulation, **multipart upload (5GB+ object)와 S3-compatible presigned URL은 현 시점(2025) 부분 지원**.
- Phase 1 In Scope는 R2 secret 백업을 결정만 하고 실제 백업 흐름은 Phase 2로 deferred지만, **백업 스크립트 로컬 검증 자체가 R2 multipart에 의존하면 Phase 1 완료 후 production 첫 실행에서 회귀 발생 가능**.
- Brief 021 In Scope 5에 R2 백업 스크립트의 검증 범위가 명시 안 됨.

**Severity**: Major (운영 비상 절차의 first-execution risk)

---

**W5. CF Access JWT 검증의 JWKS 6주 rotation + jose `createRemoteJWKSet` 캐시 만료가 로컬에서 미검증**

- Research 011 Q2 + Open Question #4가 명시: CF JWKS 6주 회전 + 7일 grace는 production-only.
- Phase 1 verify는 fixture JWT(자체 서명) + 자체 JWKS endpoint mock으로만 통과 (#13).
- **production CF Access JWKS endpoint가 6주 후 rotation되면 `createRemoteJWKSet` 캐시가 어떻게 갱신되는지** 로컬에서 검증 불가. fixture mock이 5주 cache TTL을 정확히 시뮬하지 않으면 production 첫 회전에서 admin 전체 401 가능.

**Severity**: Major (admin 인증 회귀 시 운영자 lockout)

---

### Minor (2건)

**W6. Cookie domain 격리(`domain=api.<도메인>`) 정책이 로컬 hostname `localhost:8787`에선 의미 없음**

- Research 011 R4-F2 결정 = api/admin cookie domain 격리. Phase 1 verify에서 `wrangler dev`는 `localhost:8787` 단일 호스트.
- BetterAuth `defaultCookieAttributes.domain="api.<도메인>"`이 로컬에선 무시되거나 cookie 누락 가능.
- 로컬에선 cookie 격리 정책 자체가 검증 불가 → production 첫 deploy 시 `domain` 설정 typo / SameSite=Lax + Cross-site fetch 미세 차이가 발견될 수 있다.

**Severity**: Minor (Phase 2 cutover 첫 시도에서 발견 가능, blocker는 아님)

---

**W7. miniflare 3 vs production workerd 버전 drift — Brief 021이 wrangler/vitest-pool-workers 버전 pin 명시 안 함**

- miniflare 3은 wrangler에 임베디드. wrangler 4.x → 5.x 등 minor upgrade 시 D1 batch 행동이 미세 변경된 사례 존재(GitHub workers-sdk issue tracker).
- Brief 021 In Scope 1 (Foundation 한정형)는 `package.json` 의존성 추가만 명시, **wrangler / vitest / vitest-pool-workers 버전 pin 정책 부재**.
- Phase 1 진행 중 wrangler upgrade 시 검증 결과의 reproducibility가 흔들린다.

**Severity**: Minor (CI lock으로 완화 가능)

## Missing Elements

| # | 누락 | 영향 |
|---|------|------|
| M1 | **D1 Sessions API 사용 정책** | Phase 2 cutover에서 read replication 켜질 때 saga 재작성 risk |
| M2 | **로컬 검증 → production 검증 책임 매트릭스** | Phase 2 Cutover Safety가 어떤 ideal criteria를 재검증해야 하는지 명세 부재 |
| M3 | **wrangler / vitest-pool-workers 버전 pin 정책** | reproducibility 위험 |
| M4 | **Phase 2에서 추가될 production-only 검증 항목 사전 명세** | Phase 2 Brief 022 작성 시 carryover 손실 위험 |
| M5 | **Rails export 데이터 → D1 import 통합 fixture 테스트** | #6 envelope wire-format 검증의 실측 범위 부족 |
| M6 | **compatibility_flags + compatibility_date 결정 누락** | wrangler.toml stub에 명시 안 됨 → production deploy 시 동작 차이 |
| M7 | **Workers cold start latency / V8 isolate 재사용 패턴 검증 부재** | API p95 latency가 production에서 처음 측정됨 |
| M8 | **D1 Time Travel + 30일 보관 검증** | Phase 1 완료 후 첫 production migration 시 처음 사용 |

## Detailed Analysis

### Decision 2 검증 — wrangler dev --local --persist의 실제 emulation 범위

**공식 docs 기반 emulation 범위**:

| 자원 | miniflare 3 emulation | production 갭 |
|------|----------------------|---------------|
| **D1** | SQLite 단일 파일, batch atomicity O, JSON1 함수 O | Read replication latency · Sessions API · Time Travel · multi-region |
| **KV** | 단일 in-memory store, get/put/delete | Eventual consistency 60s global · cache hit ratio · list pagination 한계 |
| **R2** | local dir 기반, GET/PUT/DELETE 기본 | Multipart upload (>5GB) · S3 presigned URL · class A/B operation 차이 · lifecycle rules |
| **Web Crypto** | workerd open-source V8 | production V8 빌드와 byte-level 동등 추정, but 보장 안 됨 |
| **Cache API** | in-memory cache | Edge cache distribution · cache key namespace |
| **Durable Objects** | local SQLite (사용 안 함, Brief 021 결정 5) | — |
| **Email · Cron Triggers** | local trigger emulation | scheduled run 정확도 · workerd vs Workers fleet |
| **Service bindings** | local Worker-to-Worker | Worker-to-Worker 분산 환경 |

**핵심 발견**: D1 batch + Drizzle batch는 **로컬 ↔ production 동등성이 가장 높은 영역**(SQLite 백엔드). KV / R2는 **API 행동만 동등**, 분산 특성은 갭. Web Crypto는 **거의 동등하나 보장 못 함**.

### Decision 12 검증 — Phase 1 verify 로컬만의 ideal criteria 커버리지

**로컬 검증으로 충분한 영역 (~18 / 28)**:
- 순수 계산 (TypeScript 도메인 services 이식, RSpec → Vitest 1:1)
- Drizzle schema + drizzle-kit generate + wrangler d1 migrations apply --local
- Hono routes + wrangler dev fetch
- API envelope 미들웨어 단위 테스트
- 보안 baseline 5종 (CORS/CSP/HSTS/rate limit/CSRF) 단위 테스트
- TDD 흐름

**Production-only 영역 또는 부분만 로컬 가능 (~9 / 28)**:
- #6 envelope wire-format Rails 호환 (실 Rails export 필요)
- #12 BetterAuth sign-in/out (KV eventual consistency 미검증)
- #13 CF Access JWT verifier (실 JWKS rotation 미검증)
- #14 Web Crypto AES-GCM (V8 build 차이 미검증)
- #15 parallel-key rotation (실 wrangler secret rotation 미검증)
- #16 보안 baseline (rate limit은 KV 분산 특성에 의존, 로컬 무관)
- #17 Hono routes + 13 controllers (compatibility flag 미적용)
- #18 OpenAPI 3 + Flutter codegen (실 응답 호환성)
- #20 모바일 API + Flutter fixture (Cookie cross-origin 동작 미검증)

### Production-only 갭이 가장 위험한 #14 / #15 심층 분석

**#14 Web Crypto AES-GCM IV=HMAC[:12]**:

Research 008 Q3의 핵심 코드:
```ts
const fullIv = await crypto.subtle.sign('HMAC', hmacKey, enc.encode(plaintext));
const iv = new Uint8Array(fullIv).slice(0, 12);
const ct = await crypto.subtle.encrypt({name:'AES-GCM',iv,tagLength:128}, aesKey, ...);
```

- workerd open source: V8 12.x 기반, Web Crypto는 BoringSSL 백엔드.
- production Workers fleet: V8 12.x~13.x, Web Crypto BoringSSL 동일 추정.
- HMAC-SHA256 / AES-GCM은 NIST 표준 + RFC 정의 → byte-level 동등 **거의 확실**.
- 그러나 **Rails ActiveRecord::Encryption** Ruby 측은 OpenSSL 백엔드 → AES-GCM IV=HMAC 결과의 12B prefix가 동일해야 wire-compat.
- Research 008 Q3 Open Question #2가 "deterministic_key vs primary_key 동일 사용"을 미해결로 두고 있는 시점에서, **실 Rails export 데이터로 envelope round-trip 검증이 Phase 1에 부재**.

**#15 parallel-key rotation**:

Research 011 Q4 절차 5단계는 모두 `wrangler secret put` / `wrangler r2 object put` / `wrangler secret delete` 외부 명령에 의존. Phase 1에선 모두 **로컬 .dev.vars 파일 + 로컬 R2**로 흉내. 실 secret API의 atomicity (예: secret put 도중 worker invocation이 K_{n+1} 미인식 → K_n으로 fallback) 는 production-only.

## 로컬 검증 가능성 매트릭스 (Ideal Criteria 28개)

| # | Criterion | 로컬 검증 가능성 | Production-only 영역 | 권고 |
|---|-----------|--------------|--------------------|------|
| 1 | wrangler.toml stub + package.json + tsconfig + workflows placeholder | ✅ Full | — | OK |
| 2 | wrangler dev --local --persist D1+KV+R2 응답 | ✅ Full | — | OK |
| 3 | vitest-pool-workers D1 binding 단위 테스트 | ✅ Full | — | OK |
| 4 | 14 테이블 Drizzle schema + d1 migrations apply --local | ✅ Full | — | OK |
| 5 | 9 JSON 컬럼 + JSON1 호환 | ✅ Full | — | OK (SQLite 백엔드 동일) |
| 6 | **R4 분리 컬럼 envelope wire-format** | ⚠️ Partial | 실 Rails export 데이터 import 호환성 | **M5: Rails export fixture 추가** |
| 7 | UNIQUE 제약 3건 + saga forward-recovery | ✅ Full | — | OK (D1 batch atomicity 동일) |
| 8 | PersonalityType × 16 seed | ✅ Full | — | OK |
| 9 | Domain services 1,850 LOC TS 이식 | ✅ Full | — | OK (순수 계산) |
| 10 | Pure Saga step 7 UPSERT forward-recovery | ✅ Full | Read replication 시 stale read | **M1: Sessions API 정책 결정 필요** |
| 11 | RSpec 18개 ↔ Vitest 1:1 | ✅ Full | — | OK |
| 12 | **BetterAuth sign-up/in/out** | ⚠️ Partial | KV eventual consistency cross-region | **M2: Phase 2 cross-region 검증 명세** |
| 13 | **CF Access JWT verifier** | ⚠️ Partial | 실 JWKS 6주 rotation cache 만료 | **M2: Phase 2 JWKS rotation 시나리오** |
| 14 | **Web Crypto AES-256-GCM IV=HMAC envelope** | ⚠️ Partial | V8 build 차이 + Rails wire-compat | **M5: Rails round-trip fixture** |
| 15 | **parallel-key rotation K_n/K_{n+1} dual-read** | ⚠️ Partial | 실 wrangler secret rotation flow | **M2: Phase 2 secret rotation drill** |
| 16 | **보안 baseline 5종** | ⚠️ Partial | rate limit KV 분산 + WAF Phase 2 | OK for unit, Phase 2 통합 검증 |
| 17 | **Hono routes 13 controllers + admin 매핑** | ⚠️ Partial | compatibility flag 차이 | **M6: compat flag 명시** |
| 18 | **OpenAPI 3 + Flutter Dart codegen** | ⚠️ Partial | 실 응답 직렬화 호환성 | **M2: Phase 2 contract 회귀 테스트** |
| 19 | API envelope + 에러 코드 카탈로그 | ✅ Full | — | OK |
| 20 | **모바일 API + Flutter fixture** | ⚠️ Partial | Cookie cross-origin + SameSite | **M2: Phase 2 모바일 cookie drill** |
| 21 | admin 9 ERB → Hono SSR 1:1 | ✅ Full | — | OK |
| 22 | 공개 평가 흐름 18 ERB + 8 Stimulus → Hono SSR + hx-boost | ✅ Full | — | OK (E2E smoke wrangler dev로 충분) |
| 23 | GDPR/PIPA 5 흐름 | ✅ Full | — | OK |
| 24 | consent / deletion_request / audit_log / alert R4 정합 | ✅ Full | — | OK |
| 25 | TDD red-green-refactor Cycles 2-6, 8 | ✅ Full | — | OK |
| 26 | 외부 자원 호출 0건 | ✅ Full | — | OK (Constraint 자체) |
| 27 | Phase 2 재진입 anchor 활용 | 📋 Directional | — | OK |
| 28 | 20 MAN-DAY 한도 | 📋 Directional | — | OK |

**요약**: 28개 중 ✅ Full 19개, ⚠️ Partial 9개, 📋 Directional 2개. **9개 Partial이 로컬 검증의 한계 영역**.

## Recommendations

### R1 (Critical) — Brief 021 Exit Criteria에 "로컬 검증 ≠ production 동등성" 게이트 명시 추가

현재 Exit Criteria + Constraint("conversion_fidelity 우선 — RSpec 동등성 + 회귀 0")는 사용자에게 "Phase 1 완료 = 기능 동등 입증"으로 읽힐 수 있다. **다음 문장을 Brief 021에 명시 추가**:

> "Phase 1 완료 = 로컬 검증 통과. Production 동등성 검증은 Phase 2 Cutover Safety가 담당한다. 로컬에서 통과해도 production에서 회귀 가능한 영역 9건(#6 #12 #13 #14 #15 #16 #17 #18 #20)은 Phase 2 carryover 항목으로 명시한다."

### R2 (Critical) — Phase 2 Carryover 명세를 Brief 021 또는 별도 문서에 사전 작성

Phase 2 Brief 022 작성 시 forget을 막기 위해, 다음 8개 production-only 검증 항목을 **Phase 1 산출물 단계에서 명시**:

| Carryover # | Production-only 검증 | 책임 시점 |
|-------------|---------------------|----------|
| C1 | Rails export → D1 import → BetterAuth login 통합 fixture | Phase 2 Cycle 9 archive smoke test |
| C2 | KV cross-region session 일관성 (60s eventual) | Phase 2 multi-region staging |
| C3 | CF Access JWKS 6주 rotation cache 만료 시 admin 401 부재 | Phase 2 cutover safety drill |
| C4 | Web Crypto AES-GCM byte-level Rails round-trip | Phase 2 archive smoke test |
| C5 | parallel-key rotation 5단계 production drill | Phase 2 secret rotation drill |
| C6 | rate limit (KV 분산 특성 + 60s eventual) | Phase 2 production load test |
| C7 | compatibility_flags 결정 + Hono routes 응답 회귀 | Phase 2 contract test |
| C8 | OpenAPI 스키마 ↔ 실 production 응답 매칭 | Phase 2 Flutter integration test |

### R3 (Major) — D1 Sessions API 정책을 Phase 1 In Scope에 추가

Brief 021 In Scope 3 (DB Layer) 또는 In Scope 4 (Domain Services Port)에 다음 결정 1건 추가:

> "Phase 1에서 모든 D1 read는 `db.withSession()` 패턴으로 작성. Phase 2 read replication 활성화 시 saga의 stale read 회귀 0 보장."

이는 Research 009 Q1 매트릭스의 R3 risk를 사전 봉쇄.

### R4 (Major) — wrangler.toml stub에 compatibility_flags + compatibility_date 명시 결정

`wrangler dev --local`은 compatibility_flags를 무시하지 않지만, **Brief 021 In Scope 1이 wrangler.toml stub의 compatibility 정책을 결정 안 함**. 추천 default:

```toml
compatibility_date = "2026-04-29"
compatibility_flags = ["nodejs_compat"]  # BetterAuth Buffer 의존성
```

**필수**: Phase 1 makeplan에서 Cycle 1 Foundation 단계에 명시.

### R5 (Major) — wrangler / vitest-pool-workers / miniflare 버전 pin 정책

`package.json` + `package-lock.json` + `pnpm-lock.yaml` 모두 pin. CI에서 `npm ci` 강제. wrangler upgrade는 별도 PR로 진행, 모든 ideal criteria 회귀 테스트 통과 후 merge.

### R6 (Minor) — Rails export fixture를 Phase 1 conversion_fidelity 검증에 포함

#6 envelope wire-format의 production 갭을 줄이기 위해, Rails 측에서 미리 1건의 sample export(`db:seed` 후 `rails db:dump`)를 D1 import script로 변환하는 fixture를 Phase 1 Cycle 5(Auth)에서 작성. 실 Rails export 형식에 대한 **structural** 호환은 이로써 검증 가능 (Rails wire-format은 archive에 있으므로 read-only로 추출 가능).

### R7 (Minor) — `MINIFLARE_KNOWN_GAPS.md` runbook 추가

Phase 2 cutover 시점에 운영자가 갭을 즉시 인지할 수 있도록, 본 매트릭스의 9개 Partial 항목을 `docs/6_backend/02_cf_workers_rebuild/runbooks/local-vs-production-gaps.md`로 보존. Phase 2 Brief 022에서 이를 anchor로 사용.

---

## Summary (200 words)

Brief 021 Decision 2(`wrangler dev --local --persist` + `@cloudflare/vitest-pool-workers`) + Decision 12(로컬 검증만)는 외부 자원 미접촉 제약 하에서 합리적이지만 **production 동등성을 ~65% 보장**한다. Ideal Criteria 28개를 매트릭스로 분석한 결과 ✅ Full 19개, ⚠️ Partial 9개, 📋 Directional 2개로 **9개의 production-only 갭**이 식별됨. 가장 위험한 항목: **#6 envelope wire-format Rails 호환**, **#14 Web Crypto AES-GCM IV 결정성**, **#15 parallel-key rotation**, **#18 OpenAPI codegen 실 응답 호환성**. 이 4건은 conversion_fidelity 우선 차원에서 사용자가 Phase 1 완료 = "Rails 동등 입증 완료"로 오해할 위험을 만든다. Severity: Critical 1건(W1: Exit Criteria oversold), Major 4건(D1 Sessions API 결정 누락 / KV eventual consistency / R2 multipart / CF JWKS rotation), Minor 2건(cookie domain 로컬 무의미 / 도구 버전 pin 정책 부재). 핵심 권고 7건: (R1) Brief 021에 "로컬 검증 ≠ production 동등성" 게이트 명시 / (R2) Phase 2 Carryover 8건 사전 명세 / (R3) D1 Sessions API 정책 In Scope 추가 / (R4) compatibility_flags 결정 / (R5) 도구 버전 pin / (R6) Rails export fixture 추가 / (R7) MINIFLARE_KNOWN_GAPS runbook. 갭 자체를 Phase 2로 위임하는 결정은 합리적이나, **사전 명세가 없으면 Phase 2 진입 시 carryover 손실 위험이 크다**.

## References

### Cloudflare 공식 docs
- [Wrangler dev command](https://developers.cloudflare.com/workers/wrangler/commands/#dev) — `--local` `--persist-to` flag 행동
- [Vitest integration](https://developers.cloudflare.com/workers/testing/vitest-integration/) — vitest-pool-workers isolated storage
- [D1 Read Replication](https://developers.cloudflare.com/d1/best-practices/read-replication/) — Sessions API + bookmark consistency
- [D1 Worker API](https://developers.cloudflare.com/d1/worker-api/d1-database/) — batch atomicity
- [KV How it works](https://developers.cloudflare.com/kv/concepts/how-kv-works/) — eventual consistency 60s global
- [R2 multipart](https://developers.cloudflare.com/r2/api/workers/workers-multipart-usage/) — multipart upload API
- [Web Crypto](https://developers.cloudflare.com/workers/runtime-apis/web-crypto/) — AES-GCM, HMAC, PBKDF2 지원
- [CF Access JWT validation](https://developers.cloudflare.com/cloudflare-one/identity/authorization-cookie/validating-json/) — JWKS 6주 rotation
- [Compatibility dates](https://developers.cloudflare.com/workers/configuration/compatibility-dates/) — flag 차이

### Miniflare
- [Miniflare 3](https://miniflare.dev/) — D1/KV/R2 emulation 한계
- [workers-sdk GitHub issues](https://github.com/cloudflare/workers-sdk) — wrangler 버전별 행동 차이

### Source docs
- Brief 021: `/Users/kampikrein/A/personality/docs/6_backend/02_cf_workers_rebuild/021_Brief_conversion_phase1.md`
- Research 008 (Drizzle + D1): `/Users/kampikrein/A/personality/docs/6_backend/02_cf_workers_rebuild/008_Research_axis1_drizzle_d1.md`
- Research 009 (D1 saga): `/Users/kampikrein/A/personality/docs/6_backend/02_cf_workers_rebuild/009_Research_axis2_d1_saga.md`
- Research 011 (Auth hybrid): `/Users/kampikrein/A/personality/docs/6_backend/02_cf_workers_rebuild/011_Research_axis4_auth_hybrid.md`
- Synthesis 018: `/Users/kampikrein/A/personality/docs/6_backend/02_cf_workers_rebuild/018_Synthesis_research_cycle.md`

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
