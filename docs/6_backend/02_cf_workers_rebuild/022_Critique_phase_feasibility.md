---
id: "022"
type: critique
title: "Brief 021 Critique — Phase Split Feasibility"
created: 2026-04-29
status: completed
perspective: "phase_feasibility"
target: "021"
confidence: high
summary: >
  Brief 021의 "외부 자원 미접촉 + Phase 1 활성 9 / Phase 2 deferred 11" 분리는
  큰 틀에서 실행 가능하지만, **CF Access verifier 구현 모드(원격 JWKS 의존)**,
  **Flutter Dart codegen 도구의 1회 외부 의존(JAR + Java)**, **Hono CSRF Origin
  체크의 token-CSRF 미충족 위험** 3건이 "외부 자원 0" 가정과 충돌한다.
  보안 baseline 5종은 미들웨어 차원에서 강제 가능하지만 WAF deferred는
  Phase 1 검증 가능 항목 명시에서 보강이 필요하다.
keywords: [critique, brief-021, phase-split, feasibility, local-first, cf-access, vitest-pool-workers, openapi-codegen]
---

# 022 — Brief 021 Critique: Phase Split Feasibility

## 1. Executive Summary

**Verdict**: **Pass with revisions** — Brief 021의 Phase 분리 의도와 운영 모델(`wrangler dev --local --persist` + `@cloudflare/vitest-pool-workers`)의 큰 골격은 공식 문서로 확인된 사실 위에 서 있다. 그러나 "외부 자원 0" 제약을 글자 그대로 적용하면 **3개 In Scope 항목**(CF Access verifier, OpenAPI Flutter codegen, Hono CSRF의 강한 보장)이 부분적으로 deferred·재정의돼야 한다.

총 **0 critical / 4 major / 3 minor / 2 missing**. 모두 **Brief 021 수정 가능 범위**(Decision 5/7/9 본문 + Constraints 2~3 줄 추가).

핵심 발견 우선순위:
1. **Decision 7 CF Access verifier** — `developers.cloudflare.com/cloudflare-one/.../validating-json/`의 공식 패턴은 `${TEAM_DOMAIN}/cdn-cgi/access/certs` JWKS 원격 fetch 필수. **순수 unit-test로 verifier를 검증하려면 JWKS fixture를 mock해야 하며**, "fixture JWT만으로 검증/거부"라는 Ideal Criteria 13의 표현이 운영 verifier와 unit-test verifier의 분기를 모호하게 둔다.
2. **In Scope 6 Flutter codegen** — `openapi_generator`(Dart pub) + `openapi-generator` JAR이 표준이며, **첫 빌드 시 Java + 인터넷이 필수**(JAR 다운로드). 이후는 캐시 가능하나 "외부 자원 0"의 글자 그대로의 해석에 미세 균열.
3. **In Scope 5 보안 baseline의 CSRF** — Hono CSRF는 Origin + Sec-Fetch-Site **이중 체크만**. token-CSRF는 별도 구현 필요. Brief 001 In Scope 18이 "Hono CSRF는 origin-check 기반(per-session token 부재)이라는 사실을 implementation 시 명시 인지"라 못박았는데, Brief 021은 이 단서를 약화시킴.
4. **In Scope 7 hx-boost 정적 자원** — `wrangler dev`는 [assets binding](https://developers.cloudflare.com/workers/static-assets/) + `env.ASSETS.fetch()` 패턴으로 로컬에서 static asset 정상 서빙. 이 부분은 feasible — 다만 Plan 020/Cycle 6 makeplan에서 `assets.directory` 설정이 wrangler.toml에 명시돼야 함(현재 미언급).

권장 우선순위:
- **P1 (Decision 7 본문 보강)**: verifier 모드를 "production = 원격 JWKS / unit-test = JWKS fixture mock" 두 모드로 분기 명시
- **P2 (Decision 9 본문 보강)**: codegen 도구를 1차 후보(`@hono/zod-openapi` + `openapi-generator-cli` Dart 출력)로 명시 + "JAR 1회 다운로드는 외부 자원 0 예외 허용"을 Constraint에 추가
- **P3 (Decision 7 + Anchor 8)**: Hono CSRF의 token-CSRF 미보장을 다시 명시 (Brief 001 In Scope 18 표현 복원)

## 2. Findings — Strengths

**S1**. **운영 모델의 1차 출처 정합** — `wrangler dev --local`은 공식 문서에서 "the Worker code is running locally on your machine, all remote bindings are disabled, which behaves exactly as if they were configured with `remote: false`"라고 명시. Brief 021 Decision 2의 가정은 사실에 부합 ([Wrangler commands docs](https://developers.cloudflare.com/workers/wrangler/commands/)).

**S2**. **`@cloudflare/vitest-pool-workers`의 fully-local 실행이 공식 검증됨** — 공식 docs에 "Runs tests fully-locally using Miniflare", "Implements isolated per-test storage" 명시. D1 binding 단위 테스트 통과(Ideal Criteria 3)는 docs에서 `wrangler.configPath` + `miniflare.kvNamespaces` 설정 패턴으로 검증되며, D1 binding도 동일 인터페이스로 지원([Vitest integration docs](https://developers.cloudflare.com/workers/testing/vitest-integration/)).

**S3**. **D1 local-development의 외부 자원 무관성** — 공식 D1 best-practices 페이지: "Local development sessions create a standalone, local-only environment that mirrors the production environment D1 runs in so that you can test your Worker and D1 before you deploy to production." Brief 021의 "wrangler d1 migrations apply --local 성공"(Ideal Criteria 4)은 외부 자원 0 가정과 일치 ([D1 local development docs](https://developers.cloudflare.com/d1/best-practices/local-development/)).

**S4**. **Phase 분리 매핑이 Brief 001 frozen 결정과 일관** — In Scope 1·10·14·15·17·19의 외부 자원 부분만 Phase 2로 deferred했고, 나머지는 본 Brief 021에서 활성화. "anchor 2개 + 결정 재논의 금지" 원칙(Decision 1) 잘 보존. server/ read-only 점검 결과 Brief 021의 인벤토리(15 모델, 13 컨트롤러+admin, 20 services, 27 ERB, 8 Stimulus, 18 RSpec)는 실제 코드와 정합 (확인: 15 ruby 모델 파일, 9개 admin ERB + 18개 공개 ERB = 27, 8 Stimulus controllers, 18 spec 파일).

**S5**. **Cycle 6 영역 확장의 근거 견고** — server/app/views/admin/ 9 ERB + javascript/controllers/ 8 Stimulus 확인. Synthesis S-018-F6의 R3 winner가 그대로 적용됨. hx-boost는 [Cloudflare Static Assets](https://developers.cloudflare.com/workers/static-assets/)의 assets binding으로 로컬 서빙 가능 — feasible.

## 3. Findings — Weaknesses

| ID | Severity | Title | Evidence | Recommendation |
|----|----------|-------|----------|----------------|
| W1 | **major** | CF Access verifier의 unit-test 모드 미정의 | 공식 [Cloudflare Access JWT validation guide](https://developers.cloudflare.com/cloudflare-one/identity/authorization-cookie/validating-json/)는 "Validate tokens using the external endpoint rather than saving the public key as a hard-coded value", `${env.TEAM_DOMAIN}/cdn-cgi/access/certs` JWKS fetch 필수. **Brief 021 Ideal Criteria 13** "fixture JWT를 정확히 검증/거부"는 verifier가 production에서는 원격 JWKS, test에서는 mock JWKS를 받는 두 모드를 분기해야 가능. Brief 021 Decision 7 본문은 이 분기를 명시하지 않음. | Decision 7 + Anchor 8에 **"verifier 함수는 jose JWKS resolver를 인자로 받아 production은 `createRemoteJWKSet(${TEAM_DOMAIN}/cdn-cgi/access/certs)`, unit-test는 `createLocalJWKSet(fixture)` 주입한다"** 문장 추가. Cycle 4 makeplan에서 두 빌드의 jose 패턴 명시. |
| W2 | **major** | Flutter codegen의 1회 Java + 인터넷 의존 | `openapi_generator`(Dart pub)는 [pub.dev 공식](https://pub.dev/packages/openapi_generator) 페이지에서 "You must have java installed on your system for this library to work" 및 "Just to download the openapi jar initially. Once it is cached, you are good to go" 명시. **첫 빌드 시 Java 7.x+ + Maven Central 접근** 필요. Brief 021 Decision 9의 "OpenAPI 3 + 코드 생성 (Hono RPC 또는 별도 codegen)"은 Hono RPC가 Dart 비호환임을 인정하지 않음 — [Hono RPC docs](https://hono.dev/docs/guides/rpc)는 TypeScript 전용. 결국 Dart codegen은 외부 JAR 의존. | Decision 9를 두 단계로 분리: **(a)** spec 측: `@hono/zod-openapi`로 OpenAPI 3 문서를 코드에서 생성([npm](https://www.npmjs.com/package/@hono/zod-openapi)). 외부 자원 0. **(b)** Dart 측: `openapi-generator-cli` JAR 1회 다운로드(또는 [openapi-generator-dart](https://pub.dev/packages/openapi_generator)). Constraint에 "Phase 1 codegen은 JAR 1회 캐시 가능 시 외부 자원 0 가정의 예외로 인정"을 추가하거나, 그것이 어색하면 **Dart 클라이언트 생성을 Phase 2로 defer**하고 Phase 1은 OpenAPI 3 spec 생성까지만. |
| W3 | **major** | Hono CSRF가 token-CSRF 미보장 — Brief 021이 Brief 001 단서를 약화 | [Hono CSRF docs](https://hono.dev/docs/middleware/builtin/csrf): "This middleware protects against CSRF attacks by checking both the `Origin` header and the `Sec-Fetch-Site` header"; "Old browsers that do not send `Origin` headers, or environments that use reverse proxies to remove these headers, may not work well … use other CSRF token methods." Brief 001 In Scope 18 마지막 줄 "Hono CSRF는 origin-check 기반(per-session token 부재)이라는 사실을 implementation 시 명시 인지"는 명시적 단서. **Brief 021 Decision 7 본문**은 "보안 baseline 5종: CORS, CSP, HSTS, rate limit, hono CSRF (Origin + Sec-Fetch-Site 이중 체크)"라 단서 없이 강조. CVE-2024-48913(Hono CSRF middleware bypass) 이력도 있음. | Anchor 8 또는 Decision 7에 한 줄: **"Hono CSRF는 token-CSRF가 아니라 fetch-metadata 기반이며, Origin이 제거되는 reverse proxy 또는 비표준 클라이언트(=현 Flutter)에서는 Bearer 인증 + Sec-Fetch-Site=`none` 처리로 분기"**. Cycle 4 makeplan의 OQ-5는 이미 이 분기를 식별했지만, 결정이 verify 가능한 형태로 격상돼야 Ideal Criteria 16 ("CSRF 미들웨어 활성화 + 단위 테스트 통과")이 의미를 가짐. |
| W4 | **major** | "외부 자원 0"이 Phase 1 verify 모델과 충돌하는 지점 — production-only 회귀의 식별이 Decision 12에 한 줄로 머무름 | Brief 021 Decision 12: "production 동등성 검증은 Phase 2 cutover safety가 담당. production-only 회귀(D1 read replication latency 등) Phase 1에서 미발견." 그러나 read replication latency 외에도 **wrangler local emulation의 알려진 차이**가 있음 — D1 [local development docs](https://developers.cloudflare.com/d1/best-practices/local-development/)는 read replication 외 기타 production 차이를 명시하지 않으나, Time Travel rollback(R1 Q)·Workers limits(CPU time 30s, sub-request 50)·Durable Object alarm 정확도 등이 production-only. Brief 021은 R2 (saga forward-recovery)가 production CPU time/subrequest limit 위에서 실측되지 않음을 인정하지 않음. | Decision 12 본문 또는 Constraint에 **"local emulation이 검증하지 않는 production-only 항목 목록"**을 한 줄짜리 표로 명시: read replica latency / CPU time 30s 한도 / sub-request 50 한도 / Time Travel rollback / DO alarm 정확도. Phase 2 cutover safety의 verify 항목으로 직접 매핑. |
| W5 | **minor** | Decision 5 "보안 baseline 5종 강제" vs WAF Phase 2 | Brief 001 In Scope 18은 보안 baseline을 "CORS·CSP·HSTS·rate limit·**WAF**" 5종으로 정의(`Decision 7`의 "5종"은 CORS/CSP/HSTS/rate limit/CSRF로 다른 5종). **WAF는 외부 자원 → Phase 2** 분리는 합리적이나, Brief 021 Anchor에서 "5종" 정의 변경(WAF ↔ CSRF 교체)이 명시되지 않아 Brief 001의 5종 가정을 변경한 것인지 모호. | Anchor 8 또는 In Scope 5 본문에 **"Phase 1 보안 baseline 5종 = CORS/CSP/HSTS/rate-limit/CSRF (Hono fetch-metadata) — Brief 001의 WAF는 Phase 2로 deferred되어 5종 구성이 한 항목 swap"**이라 한 줄 명시. |
| W6 | **minor** | Plan 020에 `assets.directory` wrangler.toml 설정이 미언급 | Brief 021 In Scope 7의 hx-boost는 정적 자원(htmx.min.js)을 로컬 서빙해야 함. [Static Assets docs](https://developers.cloudflare.com/workers/static-assets/)는 `assets.directory` + 옵션 `assets binding`(env.ASSETS.fetch())이 표준. Plan 020 File Change Summary는 wrangler.toml에 D1/R2/KV binding은 명시했으나 **`assets`는 명시 안 함**. Cycle 6 makeplan에서 비로소 추가될 가능성이 있는데, 그러면 Cycle 1 → 6 사이의 wrangler.toml 진화 경로가 plan 안에 없음. | Plan 020에 메모 한 줄 추가, 또는 Brief 021 Anchor에 "Cycle 6 시 wrangler.toml에 `[assets] directory='./public'` 추가 — Cycle 1은 placeholder만". 그러나 이건 Plan 020 영역이라 Brief 021 직접 수정 대신 OQ로 등록 가능. |
| W7 | **minor** | Decision 14 (parallel-key rotation) 검증이 fixture로만 가능한가 | In Scope 5: "parallel-key rotation 함수 (실 키 등록은 Phase 2)". Ideal Criteria 15: "parallel-key rotation 함수가 K_n / K_{n+1} dual-read를 정확히 처리하는가 (실 키 등록 없이 fixture로 검증)". rotation 절차 자체(R4-F3)는 Wrangler secret + R2 sealed + 1Password 3중 백업을 요구. Phase 1에서 함수 unit-test는 가능하나, **rotation runbook이 dry-run되지 않음**(외부 자원 의존). Brief 021은 이 사실을 명시하지 않고 Ideal Criteria 15가 directional 아닌 assertion으로 등록됨. | Ideal Criteria 15의 type을 `assertion`에서 **`directional`**로 강등(또는 함수 동작은 assertion 유지하되 "rotation runbook end-to-end는 directional"로 분리). |

## 4. Findings — Missing Elements

| ID | Missing | Why It Matters | Recommendation |
|----|---------|----------------|----------------|
| M1 | **`@hono/zod-openapi` 또는 chanfana 명시** — In Scope 6의 OpenAPI 3 생성 도구 미특정 | Brief 021은 "OpenAPI 3 + Hono RPC 또는 별도 codegen"이라 두 옵션을 OR 처리. Hono RPC는 TS-only — 모바일 Flutter Dart 클라이언트엔 부적합. 결국 OpenAPI 3 spec generator가 필수인데, 1차 후보(`@hono/zod-openapi` 또는 `chanfana` — Cloudflare 공식 [GitHub](https://github.com/cloudflare/chanfana)) 미명시. | In Scope 6 본문에 **1차 후보 1개(예: `@hono/zod-openapi` v0.x — 공식 [hono.dev/examples/zod-openapi](https://hono.dev/examples/zod-openapi)) 명시 + Cycle 5 makeplan에서 최종 확정** 추가. |
| M2 | **vitest-pool-workers의 D1 binding 설정 패턴** — Ideal Criteria 3 verify 방법 미명시 | 공식 [vitest integration docs](https://developers.cloudflare.com/workers/testing/vitest-integration/)는 `wrangler.configPath` + `miniflare.kvNamespaces` 패턴 명시(KV). D1 binding도 동일 인터페이스(`miniflare.d1Databases`)이지만 Brief 021이 이를 명시하지 않음. Cycle 2 makeplan에서 `defineWorkersConfig({ test: { poolOptions: { workers: { wrangler: { configPath }, miniflare: { d1Databases: { DB: 'd1-test' } } } } } })` 패턴이 필요. | Cycle 2 plan에 D1 binding 테스트 fixture 패턴 명시(Brief 021 본문이 아닌 plan/makeplan 영역). Brief 021 Open Questions에 OQ-6: "vitest-pool-workers의 isolated D1 마이그레이션 적용 위치 (per-test vs per-suite)" 추가. |
| M3 | **archive smoke test 대안** — Phase 1 동안 Rails archive의 검증 부재 | Brief 001 In Scope 14는 "월 1회 또는 분기 1회 archive Rails를 별도 환경에서 가동 검증"을 명시. Phase 1이 server/ read-only이고 외부 자원 0이라 archive smoke test가 Phase 2로 deferred됨. 이 deferred는 합리적이나, **Phase 1 ≈ 20 MAN-DAY 진행 중 server/의 Ruby 8.x + gem 호환성이 부패**할 수 있음 — Phase 2 진입 시 archive smoke test 첫 실행이 실패할 위험. | Brief 021 Constraints에 "Phase 1 진행 중 server/ Ruby 호환성 부패 모니터링은 자동화된 GitHub Actions schedule로 분리 가능 — 단, 이 워크플로 자체는 외부 secret 불필요(public Ruby/gem만 사용)이므로 Phase 1에서 작성 가능"이라는 한 줄. 또는 Out of Scope에 "archive smoke test는 Phase 2"라고만 두고 Phase 2 첫 cycle의 risk로 명시. |

## 5. Detailed Analysis

### 5.1 Decision 7 (CF Access verifier) — 가장 깊은 가닥

**Brief 021 본문**: "BetterAuth(D1+KV) User + CF Access JWT verifier (실 SSO 연결 제외) Admin … Phase 1에선 admin 실 인증 흐름 미검증 (verifier unit test로 보완)"

**공식 문서 패턴** ([Validating JSON web tokens](https://developers.cloudflare.com/cloudflare-one/identity/authorization-cookie/validating-json/)):
```js
// 공식 예시 (요약 인용)
const JWKS = createRemoteJWKSet(
  new URL(`${env.TEAM_DOMAIN}/cdn-cgi/access/certs`)
);
const { payload } = await jwtVerify(token, JWKS, {
  issuer: env.TEAM_DOMAIN,
  audience: env.AUD,
});
```

핵심: **`createRemoteJWKSet`은 fetch를 발생시킨다.** Phase 1 unit-test에서 이를 그대로 호출하면:
- 환경변수 `TEAM_DOMAIN`이 placeholder → fetch 실패
- "외부 자원 0" 가정 위반 (CF Access 팀 도메인 호출)

**해법**: jose는 `createLocalJWKSet(jwks)`를 제공하므로, verifier 함수가 JWKS resolver를 인자로 받게 설계하면 두 모드 분기 가능:
```ts
type JwksResolver = (kid: string) => Promise<KeyLike>;
async function verifyAccessJwt(token: string, resolver: JwksResolver) { ... }

// production
const remote = createRemoteJWKSet(...);
const verifier = (t) => verifyAccessJwt(t, remote);

// unit-test
const local = createLocalJWKSet(testJwks);
const verifier = (t) => verifyAccessJwt(t, local);
```

이 분기가 **Brief 021 Decision 7 본문에 명시**돼야 Ideal Criteria 13의 "fixture JWT를 정확히 검증/거부"가 외부 자원 0 가정과 일관 검증된다. 현 Brief는 결정 1줄로 끝나서 Cycle 4 implementation 시 ad-hoc 결정으로 떠넘겨질 위험.

### 5.2 Decision 9 (OpenAPI codegen) — Phase 1 외부 의존의 회색지대

**Brief 001 Decision 14** + **Brief 021 In Scope 6**이 "Hono RPC 또는 별도 codegen"이라 OR 처리했으나, **Hono RPC는 TS-only**임이 [공식 docs](https://hono.dev/docs/guides/rpc)로 확인됨 ("export TypeScript types … TypeScript-specific concepts"). Flutter Dart 클라이언트는 RPC 경로 불가능 — 별도 codegen이 사실상 강제.

**Dart codegen 경로**:
- (a) `openapi_generator`(pub) — Java + 1회 JAR 다운로드 ([pub.dev](https://pub.dev/packages/openapi_generator))
- (b) `openapi-generator-cli` (npm wrapper) — 동일 JAR
- (c) `swagger-typescript-api` 등 TS 출력 → 수동 Dart 변환 (drift 위험, Brief 001 Decision 14 기각 사유)

(a)/(b)/(c) 모두 **외부 자원 1회 발생**(JAR 또는 Maven Central). **순수 외부 자원 0이려면 사전에 JAR을 repo에 vendoring**해야 하며, 이는 라이선스(Apache 2.0)·사이즈(~30MB) 부담. 

**해법**: Brief 021 Decision 9의 본문을 분리:
> Spec generation: `@hono/zod-openapi`로 코드 내 정의 → `/doc` endpoint or static file 출력 (외부 자원 0). 
> Dart client generation: `openapi-generator-cli` JAR 1회 다운로드 후 `apps/workers/tools/openapi-generator-cli.jar`로 vendoring 또는 첫 setup의 단발성 fetch. **이 한 번의 fetch는 "외부 자원 0" 제약의 의도된 예외**로 Constraint에 명시. 

또는 **Phase 1을 OpenAPI 3 spec 생성까지로 한정**하고 Dart 클라이언트는 "spec이 안정화된 후 Phase 2 또는 별도 mobile-side 작업"으로 분리. 이 경우 In Scope 6의 "Flutter Dart 클라이언트 자동 생성" 부분이 Phase 2 deferred로 이동. — Phase 1 활성 8 In Scope로 축소.

### 5.3 In Scope 5 보안 baseline — token-CSRF 부재의 명시 약화

**Brief 001 In Scope 18** (frozen anchor, 따옴표 그대로):
> Hono CSRF는 origin-check 기반(per-session token 부재)이라는 사실을 implementation 시 명시 인지.

**Brief 021 In Scope 5** (활성 항목):
> 보안 baseline 5종: CORS, CSP, HSTS, rate limit, hono CSRF (Origin + Sec-Fetch-Site 이중 체크). WAF는 외부 자원 → Phase 2.

**차이**: Brief 021은 "Origin + Sec-Fetch-Site 이중 체크"라는 강한 표현으로 끝나고, **token-CSRF 부재**라는 단서를 누락. 이중 체크가 GA 표준이지만:
- [CVE-2024-48913](https://www.miggo.io/vulnerability-database/cve/CVE-2024-48913): Hono CSRF middleware bypass 이력 — Content-Type 누락 요청이 safe로 처리됨
- 모바일 Flutter 클라이언트는 일반적으로 `Sec-Fetch-Site` 헤더를 보내지 **않음** (네이티브 HTTP 클라이언트). CSRF 미들웨어가 Bearer 인증 경로를 우회하도록 분기되지 않으면 false-positive 발생

**Ideal Criteria 16**(CSRF 미들웨어 활성화 + 단위 테스트 통과)이 verify 가능하려면 **분기 결정이 Brief 본문에 있어야** 한다. 현재는 OQ-5(Synthesis)에 식별만 되고 결정은 makeplan 위임. 그 위임이 Phase 1 verify의 의미를 약화.

**해법**: Anchor에 한 줄 — "Hono CSRF는 token-CSRF 미보장. 모바일 API 라우트는 Bearer JWT 인증으로 CSRF 우회. admin 라우트(SSR cookie)에만 CSRF 미들웨어 적용. 이 분기는 Cycle 4·5 makeplan에서 미들웨어 ordering으로 강제."

### 5.4 외부 자원 0 정의의 일관성

Brief 021은 "외부 자원 미접촉"을 다음과 같이 정의:
> wrangler dev --local --persist + @cloudflare/vitest-pool-workers 외 외부 호출 금지 (Anchor 2)

이 정의는 다음을 **암묵적 허용**한다:
- npm registry (npm install)
- GitHub (codepush, repo clone)
- Maven Central (JAR 다운로드, 위 W2)
- 공식 문서 fetch

이 자원들이 "외부 자원"의 정의에 포함되는지 모호. Brief 021은 대상이 "CF account · custom domain · 실 secrets · GitHub Actions secrets · 1Password vault · R2 sealed"인 것은 명시(Anchor 2). 그러나 npm/Maven 같은 빌드 시점 의존은 명시 외. 일관된 해석으로는 "**runtime에 CF 계정 자격증명을 요구하는 호출 0**"가 본 Brief의 진짜 제약 — 이를 직접 Anchor 2에 풀어 쓰는 게 권장.

**해법**: Anchor 2 본문에 "외부 자원 = CF 계정 자격증명 / 사용자 vault / production secret을 요구하는 호출. 빌드 시점의 npm·JAR·docker pull은 외부 자원이 아니다. 단, CF Access 팀 도메인 fetch는 production CF 자격증명에 해당하므로 외부 자원이며 unit-test는 mock JWKS 사용." 한 줄 추가.

### 5.5 Brief 021의 안정점 (변경 권장 안 함)

- Decision 1 (Phase 분리 전략) — 견고. 변경 권장 안 함.
- Decision 2 (운영 모델) — wrangler/vitest-pool-workers 조합은 공식 문서로 정합 검증.
- Decision 3 (User schema R4) — Synthesis cross-axis 정합으로 도출, 코드 차원에서 외부 자원 0.
- Decision 5 (Pure Saga) — D1 only, fully local-emulatable.
- Decision 6 (Hono SSR vanilla + hx-boost 옵셔널) — Static Assets binding으로 로컬 서빙 가능.
- Decision 13 (Phase 1 완료 정의) — 합리적.

## 6. Recommendations for Brief 021 Revision

순서대로(가장 영향 큰 것부터):

1. **Decision 7 본문 보강 (P1, 1 paragraph)** — verifier 두 모드 분기 명시:
   - Production: `createRemoteJWKSet(${TEAM_DOMAIN}/cdn-cgi/access/certs)`
   - Unit-test: `createLocalJWKSet(testJwks)` + 의존성 주입 패턴
   - Cycle 4 makeplan은 두 모드의 토글 메커니즘(env var vs 함수 인자) 결정.

2. **Decision 9 본문 분리 (P2, 1 paragraph)** — Spec gen ↔ Dart codegen 분리:
   - (a) Spec: `@hono/zod-openapi` 또는 `chanfana` 1차 후보 명시 (외부 자원 0)
   - (b) Dart codegen: JAR 1회 fetch는 "외부 자원 0의 의도된 예외"로 Constraint에 추가, 또는 Dart 부분만 Phase 2로 deferred (In Scope 6 축소).

3. **Anchor 8 보강 (P3, 1 line)** — Hono CSRF token-CSRF 미보장 명시 + 모바일 Bearer 우회 분기 결정 격상 (Brief 001 In Scope 18 단서 복원).

4. **Anchor 2 보강 (P3, 1 line)** — "외부 자원" 정의 명확화: CF 자격증명·사용자 vault·prod secret 요구 호출. 빌드시 npm/Maven은 비외부 자원으로 분류.

5. **Decision 12 본문 보강 (P4, 1 line table)** — local emulation이 검증하지 않는 production-only 항목 5개(read replica latency / CPU time 30s / sub-request 50 / Time Travel / DO alarm)를 한 줄 표.

6. **Constraint 추가 (P4, 1 line)** — "Phase 1 보안 baseline 5종 = CORS/CSP/HSTS/rate-limit/CSRF — Brief 001의 WAF는 Phase 2 deferred 1 swap" 명시.

7. **Ideal Criteria 15 type 재검토 (P5, 1 line)** — parallel-key rotation의 runbook end-to-end 부분은 directional로 분리(함수 unit-test는 assertion 유지).

8. **Open Questions 추가 (P5, 1 line)** — OQ-6: vitest-pool-workers의 D1 binding 격리 패턴(per-test vs per-suite) — Cycle 2 makeplan 결정.

모두 수정 범위는 **Brief 021 본문 +20 줄 이내** — anchor 2개 운영 부담 증가 없음.

## 7. References

| Resource | URL or path | Relevance |
|----------|------|-----------|
| Wrangler dev/local docs | [developers.cloudflare.com/workers/wrangler/commands/](https://developers.cloudflare.com/workers/wrangler/commands/) | Decision 2 운영 모델의 1차 출처 — `--local`의 정확한 의미 |
| Workers Vitest integration | [developers.cloudflare.com/workers/testing/vitest-integration/](https://developers.cloudflare.com/workers/testing/vitest-integration/) | "fully-locally using Miniflare" + binding 통합 테스트 |
| D1 local development | [developers.cloudflare.com/d1/best-practices/local-development/](https://developers.cloudflare.com/d1/best-practices/local-development/) | "standalone, local-only environment" — Ideal Criteria 4 |
| CF Access JWT validation | [developers.cloudflare.com/cloudflare-one/identity/authorization-cookie/validating-json/](https://developers.cloudflare.com/cloudflare-one/identity/authorization-cookie/validating-json/) | W1의 1차 근거 — JWKS 원격 fetch 필수 |
| Workers Static Assets | [developers.cloudflare.com/workers/static-assets/](https://developers.cloudflare.com/workers/static-assets/) | hx-boost 정적 자원 로컬 서빙 — In Scope 7 feasibility |
| Hono CSRF middleware | [hono.dev/docs/middleware/builtin/csrf](https://hono.dev/docs/middleware/builtin/csrf) | W3의 1차 근거 — Origin + Sec-Fetch-Site, token-CSRF 미보장 |
| Hono RPC | [hono.dev/docs/guides/rpc](https://hono.dev/docs/guides/rpc) | W2 Decision 9 근거 — TS-only, Dart 비호환 |
| Hono Zod OpenAPI | [hono.dev/examples/zod-openapi](https://hono.dev/examples/zod-openapi) | M1 1차 후보 |
| Cloudflare chanfana | [github.com/cloudflare/chanfana](https://github.com/cloudflare/chanfana) | M1 대안 후보 (Cloudflare 공식) |
| openapi_generator (pub.dev) | [pub.dev/packages/openapi_generator](https://pub.dev/packages/openapi_generator) | W2 1차 근거 — Java + JAR 1회 fetch |
| CVE-2024-48913 | [miggo.io vulnerability-database](https://www.miggo.io/vulnerability-database/cve/CVE-2024-48913) | W3 보강 — Hono CSRF bypass 이력 |
| Brief 001 (frozen anchor) | `/Users/kampikrein/A/personality/docs/6_backend/02_cf_workers_rebuild/001_Brief_cf_workers_rebuild.md` | 비교 대상 |
| Brief 021 (target) | `/Users/kampikrein/A/personality/docs/6_backend/02_cf_workers_rebuild/021_Brief_conversion_phase1.md` | 본 비평 대상 |
| Synthesis 018 | `/Users/kampikrein/A/personality/docs/6_backend/02_cf_workers_rebuild/018_Synthesis_research_cycle.md` | OQ-5 (CSRF 분기) 식별 |
| Plan 020 | `/Users/kampikrein/A/personality/docs/6_backend/02_cf_workers_rebuild/020_Plan_cycle1_foundation.md` | W6 (assets.directory 미언급) |
| Rails server inventory | `/Users/kampikrein/A/personality/server/app/{controllers,models,services,views,javascript/controllers}/` | S4·S5 인벤토리 read-only 검증 |
| Rails Gemfile / database.yml | `/Users/kampikrein/A/personality/server/{Gemfile,config/database.yml}` | S4 — Rails 8.1.2 + sqlite3 확인, M3 (Ruby 8.x 호환성 부패 위험) |

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
