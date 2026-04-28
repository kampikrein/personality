---
id: "002"
type: critique
title: "Brief Critique — Feasibility (기술적 실현성)"
created: 2026-04-28
status: complete
perspective: "feasibility"
target: "001"
confidence: medium-high
model: "opus"
reasoning_depth: "deep"
summary: >
  Brief 001의 12개 자율결정과 1개 사용자결정을 코드베이스(server/) 실측과
  공식 문서(Drizzle, Hono, BetterAuth, Lucia, Workers Web Crypto, vitest-pool-workers)
  교차 확인으로 비평. 결론: 8개 핵심 질문 중 4개는 feasible-as-is, 3개는
  feasible-with-design-work, 1개는 underspecified. 가장 중요한 발견은 (a) Hono CSRF
  는 origin-check 기반이라 Rails CSRF token 모델을 1:1 대체하지 않으며, (b) Lucia
  v3가 2025-03 deprecate 됐는데 Brief가 여전히 후보로 둠, (c) Drizzle 마이그레이션과
  wrangler d1 migrations는 별개의 추적 시스템이며 Brief가 통합 패턴을 명시하지
  않음, (d) Hotwire Turbo Frame 모델을 Hono SSR + vanilla JS로 1:1 동등하게
  표현할 수 없으며 의식적인 다운그레이드(full reload) 또는 fetch+swap 디자인 결정이 필요.
keywords: [critique, brief, feasibility, drizzle, d1, hono, ssr, web-crypto, auth, cutover]
---

# Brief Critique — Feasibility

## Executive Summary

Brief 001의 13개 결정은 **대체로 기술적으로 실현 가능**하지만, "feasible"의 의미가 결정마다 다르다. 인프라(Workers/Hono/D1/R2/KV), Web Crypto AES-GCM, Vitest+Workers, Custom Domain은 1:1 매핑으로 실현 가능. 그러나 **Hono SSR로 Hotwire admin을 대체**하는 결정은 "동등 대체"가 아니라 "행동 변경을 수반한 재설계"이며 Brief가 이를 평탄화. **Drizzle ORM + D1 마이그레이션 통합**도 자동이 아니라 두 추적 시스템(`drizzle_migrations` vs `d1_migrations`)을 양자택일하는 명시적 결정이 필요. **Lucia 후보**는 2025-03 deprecate된 상태로 후보 자격이 깨졌으며 Brief가 이를 반영하지 않음. **Toss webhook HMAC** 가정도 공식 docs에서 확인 불가능 — Brief가 "50 LOC HMAC-SHA256"이라 단정한 근거(연구 005)는 별도 재검증 필요. 결정 수준의 중대 결함은 없으나, **5개 critical/major 이슈**가 향후 scope/plan 단계로 넘어가기 전에 보강돼야 한다.

## Findings

### Strengths

1. **인프라 결정(Decision 2)은 GA 성숙도와 한계가 정확히 정합** — Workers + Hono v4.12 + D1 + R2 + KV가 모두 GA(연구 004 § F)이고, Brief가 Out of Scope로 Hyperdrive를 제외한 결정도 D1 천장 모니터링과 호응.
2. **Drizzle ORM 채택(Decision 3)은 D1 + TypeScript 환경에서 Best Practice 합치** — `drizzle-orm/d1` 어댑터(공식 connect-cloudflare-d1 docs), `text({ mode: 'json' }).$type<T>()` 패턴이 schema.rb의 9개 JSON 컬럼을 타입 안전하게 표현 가능.
3. **`User.encrypts deterministic` 매핑 가능성(Decision 8 부분)** — Workers Web Crypto 공식 docs 확인: AES-GCM, HMAC-SHA256, `crypto.subtle.timingSafeEqual` 모두 지원. Rails 8.1의 deterministic mode가 `OpenSSL::HMAC.digest(SHA256.new, secret, clear_text)[0...iv_length]` 방식(Rails 소스 `aes256_gcm.rb` 확인)으로 IV를 도출 — Workers에서 동일하게 재현 가능. 단, 데이터 0이라 호환성 부담 없음.
4. **Vitest + Workers 테스트 도구(Decision 7)는 공식 지원** — `@cloudflare/vitest-pool-workers`가 D1, KV, Durable Objects, Queues, Workflows 모두 fixture 제공(workers-sdk/fixtures/vitest-pool-workers-examples). `applyD1Migrations` API + `readD1Migrations` config 헬퍼로 마이그 자동 적용 가능.
5. **Custom Domain(Decision 12)은 기계적 절차로 검증 가능** — Cloudflare 공식: zone이 Cloudflare DNS에 있으면 `api.<도메인>` + `admin.<도메인>` 둘 다 wrangler `routes` 또는 dashboard에서 추가, 자동 Advanced Certificate 발급. 동일 zone이면 cookie domain `.<도메인>` 공유로 단일 인증 가능.
6. **모바일 API 신설(In Scope 5, 11)은 Greenfield의 자유도 활용** — 003 보고서가 "API 0개, 모바일 미연결"을 확인했으므로 호환성 부담 없이 OpenAPI/Hono RPC 타입 설계 가능. Brief가 이를 정확히 반영.
7. **Rails 코드 archive 보존(Decision 10)은 cutover safety 원칙에 부합** — 현 git 이력 유지 + 디스크 비용 무시 가능 + 회귀 비상구라는 3중 가치, 연구 010의 70-75% 신뢰도 권고와 일관.
8. **결제 1순위 Toss(Decision 5)는 Workers + Web Crypto 호환** — Web Crypto에 HMAC-SHA256과 timingSafeEqual 모두 있어 webhook 검증 자체는 기술적으로 가능. (단, 아래 W4 참고: Toss 공식 webhook 검증 메커니즘 자체가 docs에서 명시 확인 안 됨.)

### Weaknesses

| # | Finding | Severity | Evidence | Recommendation |
|---|---------|----------|----------|----------------|
| W1 | **Hono SSR + vanilla JS로 Hotwire Turbo Frame 동등 대체 불가능 (Decision 4 평탄화)** | **critical** | Hono CSRF 미들웨어 공식 docs: origin-check 기반이며 per-session token 발급/검증 모델 없음. Rails CSRF는 form_with가 자동 발급한 per-session token을 검증. `assessment_questions/_question.html.erb:32-34`의 `form_with ... data: { turbo_frame: "current_question" }` + `assessments/show.html.erb:14-19`의 `button_to ... data: { turbo_frame: "_top" }` 동작은 Turbo가 응답 HTML에서 `<turbo-frame id="...">` ID 매칭으로 부분 swap하는 클라이언트 시맨틱. Hono `html()` helper docs에서 streaming partial replacement / Turbo-Frame-like 미들웨어 부재 확인. | "Hono SSR + vanilla JS로 admin 동등 표현"을 "(a) full-page reload로 단순화 / (b) htmx 등 부분 swap 라이브러리 채택 / (c) 직접 fetch+innerHTML 30 LOC 작성" 3안 명시 후 결정. Decision 4를 단일 라인이 아니라 'Hotwire 행동 변화 수용' subdecision로 분기. |
| W2 | **Lucia 후보 채택이 deprecated 사실과 충돌 (Decision 8 후보 부정확)** | **major** | github.com/lucia-auth/lucia README 직접 확인: "Lucia v3 will be deprecated by March 2025. Lucia is now a learning resource on implementing auth from scratch." 2026-04 시점에서 Lucia는 학습자료. | Decision 8을 "BetterAuth 또는 자체 구현" 2안으로 축소. Lucia 제거. 단 Lucia 코드 패턴은 학습 참조로 유지 가능 명시. |
| W3 | **Drizzle migrations vs wrangler d1 migrations 통합 모델 미명시 (Decision 3 부분)** | **major** | `wrangler d1 migrations`는 자체 `d1_migrations` 테이블로 적용 상태 추적 (CF 공식 docs). `drizzle-kit generate`는 별도 SQL 출력 디렉토리(default `drizzle/`)에 `_meta` snapshots + `0000_xxx.sql` 파일 생성. Drizzle 공식 connect-cloudflare-d1 docs는 `drizzle-kit generate` 후의 적용 메커니즘을 D1에서 명시하지 않음. 두 시스템은 자동 통합되지 않음 — 사용자 패턴은 보통 (i) `drizzle-kit generate` SQL을 `wrangler.toml`의 `migrations_dir`로 가리켜 wrangler 적용, 또는 (ii) `d1-http` driver로 drizzle-kit이 직접 적용하되 wrangler 추적과 분리. Brief는 어느 쪽인지 미명시. | scope 단계에서 두 가지 중 하나 선택: "drizzle-kit generate → output_dir=drizzle/migrations + wrangler.toml migrations_dir=drizzle/migrations + wrangler d1 migrations apply" (단일 추적). Vitest 테스트는 `readD1Migrations`가 같은 dir 읽도록 설정. 결정 후 Brief의 Decision 3을 "Drizzle ORM (drizzle-kit + wrangler 단일 migrations dir)"로 정밀화. |
| W4 | **Toss webhook HMAC-SHA256 가정의 근거 불충분 (Decision 5 + In Scope 9)** | **major** | Brief: "Toss Payments 1순위. 50 LOC HMAC-SHA256, Web Crypto API." docs.tosspayments.com/guides/webhook 공식 페이지(접근 확인): retry policy/delivery log/registration은 다루나 **인증/검증 메커니즘 명시 없음**. github.com/tosspayments 공식 organization: browser-sdk/Android/iOS만 있고 **server-side SDK 부재**. 연구 005의 "50 LOC HMAC-SHA256" 주장이 어떤 1차 출처에서 온 것인지 본 critique 시점에 재확인 불가. | scope 단계에서 Toss 공식 문서 한국어 페이지 또는 파트너 콘솔에서 webhook 인증 방식을 1차 확인 (HMAC-Signature 헤더? Basic Auth? IP allowlist?). 근거 확보 후 In Scope 9의 LOC 추정 재계산. webhook 검증이 IP allowlist만일 경우 Workers의 다중 PoP 특성과 충돌하므로 Phase A 일정에 영향 가능. |
| W5 | **`api.<도메인>` + `admin.<도메인>` 인증 토큰 공유 모델 underspecified (Decision 12)** | **major** | Brief Anchor 9: "인증 토큰은 양 서브도메인 공유 (cookie domain 또는 JWT)". 두 옵션은 보안 모델이 크게 다르다. Cookie `Domain=.<도메인>` + `SameSite=Lax/Strict` + `Secure`는 brief의 Custom Domain 결정과 호환되나, JWT를 헤더로 전달하면 admin SSR + form POST에서 cookie 없이 JWT 운반이 어려움(Authorization 헤더는 form submit이 자동 송부 못 함). 즉 admin이 SSR이면 cookie 강제, 모바일 API면 JWT 가능. Brief는 이 비대칭을 평탄화. | Anchor 9를 "admin = cookie session (Domain=`.<도메인>`, HttpOnly, Secure, SameSite=Lax) / api(모바일) = Bearer JWT or session cookie / 두 도메인이 같은 zone일 때만 가능"으로 분리. CSRF는 admin 영역에 한해 origin check + double-submit cookie 패턴 채택 명시. |
| W6 | **`csrf_meta_tags` 자동 발급 모델의 대체 미설계 (Decision 4 + Decision 8 사각지대)** | **major** | 003 보고서 § "Idioms not portable": "Rails' auto-CSRF + cookie signing + form builder ... must be replicated end-to-end". Hono CSRF 미들웨어가 origin/Sec-Fetch-Site 검증만 하므로, **legacy 브라우저 또는 `Origin: null` 시나리오 또는 form-encoded cross-site POST에 대해 token 기반 fallback이 부재**. admin은 내부 사용이라 origin check가 실용상 충분할 수 있으나 Brief가 이를 명시 결정하지 않음. | Decision 4 또는 신규 Decision로 "admin CSRF = Hono cors+csrf middleware (origin check) + 신뢰 origin 화이트리스트, 모바일 API CSRF = Bearer JWT라 N/A" 명시. Token-based 패턴이 필요해지면 별도 미들웨어 작성 (~20 LOC) 비용 인지. |
| W7 | **D1 batch transaction의 `ResultsController#run_scoring_pipeline!` 8단계 호환성 (In Scope 4)** | **major** | `app/controllers/results_controller.rb:21-67` 확인: 단일 `ActiveRecord::Base.transaction do` 안에서 8 단계 — 그 중 step 4(reliability)와 step 6(policy_check) 결과로 step 5(persist)와 step 7(compose)이 분기. D1은 `db.batch([stmts])`만 지원하고 **interactive transaction 부재**(004 § B 확인). 즉 "step 6의 결과를 보고 step 7 또는 fail로 분기"하는 패턴은 batch 내 표현 불가능. 분기 후 commit, fail이면 별도 batch로 update 추가 필요. 비가역 분기지만 도메인상 step 5까지는 항상 commit, step 7이 conditional이므로 2-batch 분리로 해결 가능 — 단 atomicity 약화 (실패 시 inconsistent 상태 가능). | scope 단계에서 8 단계를 (i) batch1: step 1-5(point of no return, profile not yet composed) + (ii) policy 분기 후 batch2: step 6 fail update OR step 7-8 compose+insights로 재설계. 실패 시 cleanup 로직 명시. 또는 Durable Object SQLite로 옮겨 interactive transaction 유사 모델 사용. Decision 또는 plan 사이클 결정. |
| W8 | **Web Crypto AES-GCM의 deterministic IV 도출이 표준 함수 부재로 SubtleCrypto + 수동 HKDF (In Scope 6)** | **minor** | Workers Web Crypto가 AES-GCM과 HMAC-SHA256은 지원하나, "HKDF"는 별도 알고리즘으로 sign/verify 일부만 지원. Rails 방식(SHA256 HMAC of plaintext → first iv_length bytes)은 Workers에서 `crypto.subtle.sign('HMAC', key, plaintext)` 후 첫 12 bytes 슬라이싱으로 직접 구현 가능. 다만 32 bytes 출력 중 12 bytes만 사용하는 패턴은 Argon2/HKDF 같은 KDF 미사용이라 Rails와 cipher-text가 동일하지 않을 가능성 있음(데이터 0이므로 무관). | 새 스킴은 Rails와 호환 강제하지 않고 자체 정의로 시작. 문서 (cipher = AES-256-GCM, IV = HMAC-SHA256(deterministic_key, plaintext)[0..11], salt = key_derivation_salt, key = HKDF(primary_key, salt, info='email'))를 plan 단계에 작성. 003 보고서 권고 6과 동일. |
| W9 | **`Admin::DashboardController`의 raw SQL aggregate가 Drizzle 호환 미명시 (In Scope 5)** | **minor** | 003 § Controllers M4: `admin/dashboard_controller.rb:17-25`가 `SUM(CASE WHEN status='completed' ...)` raw SQL을 `.select()` 안에 사용. Drizzle은 `sql\`SUM(CASE WHEN status='completed' THEN 1 ELSE 0 END) as completed\`` template 패턴으로 동일 표현 가능(공식 magic sql 연산자). 단 D1의 SQLite 방언이 `CASE WHEN`을 그대로 지원하므로 호환성은 OK. | scope 단계에서 admin dashboard 쿼리 인벤토리 작성, Drizzle `sql` template 패턴 + 결과 `.then()` 캐스팅 명시. `Admin::QuestionSetsController`의 schema 미스매치(003 M3) 동시에 fix. |
| W10 | **TypeScript 단일 언어 + Rails Stimulus 8개 vanilla JS 이식 시 build 도구 결정 부재 (Decision 4 sub)** | **minor** | Brief: "Hono SSR + vanilla JS". 그러나 8 Stimulus controllers 중 일부(`autosave_controller.js`의 sessionStorage, `countdown_controller.js`의 form submit listener, `tabs_controller.js`의 dataset.index 분기)가 100 LOC를 넘어가면 빌드/번들링 결정이 필요. Workers는 정적 자산을 `assets` binding 또는 R2로 서빙하나, esbuild/vite/rsbuild 중 어느 것을 쓸지, 또는 Stimulus 자체를 유지(JS만 import map)할지 미결. | scope 단계에서 (a) Stimulus 그대로 유지(가장 가까운 1:1) + Hono가 `<script type="module">` 정적 서빙, (b) 8 컨트롤러 모두 vanilla 30 LOC씩 inline 재작성, (c) Alpine.js 같은 가벼운 라이브러리 채택 3안 비교. Brief의 "vanilla JS"가 어느 의미인지 anchor 5 보강. |
| W11 | **Phased Cutover의 Phase A→B 사이 Rails admin/모바일 API 공존기 인증 정책 미설계 (Decision 9)** | **minor** | Anchor 7: Phase A = CF 인프라+모바일 API+결제, Phase B = Hono SSR admin. A 완료 후 B 가동 전까지는 `Rails admin (server/)` + `Hono mobile API (workers/)`가 공존. 두 시스템이 같은 D1을 보지 않으므로(Rails는 SQLite primary, CF는 D1) **데이터 단절 또는 이중 쓰기 정책**이 필요. Brief는 이 공존기 운영을 평탄화. | scope에서 Phase A 시작과 함께 SQLite production을 사용하지 않는다는 점(P1 003 보고서: 어차피 prod DB 부재) 활용 — D1을 단일 진실 원천으로 두고, Phase A 동안 admin 운영이 필요하면 Rails dev 환경에서 D1을 read-only로 보거나, admin을 Phase B 완료까지 보류. anchor 7에 "Phase A 동안 admin 미가동 또는 read-only" 명시. |

### Missing Elements

| # | What's Missing | Why It Matters | Suggestion |
|---|---------------|----------------|------------|
| M1 | **Workers Free vs Paid 결정** | Brief가 "production/preview/staging" 3환경(Decision 11)을 권장하나 Workers Free는 1 account 100K req/day 공유, Paid는 $5/월. Decision 11이 Free에서 가능한가? Preview Worker가 자동 생성될 때 quota 영향은? | Anchor 또는 Decision로 "초기 Paid $5/월 가입 명시 + preview/staging은 동일 account workers" 추가. preview URL 자동 생성은 Pages 또는 Workers 환경 기능 활용 명시. |
| M2 | **R2 사용 시점 부재** | In Scope 1에 R2 bucket 셋업, Anchor 2에 R2 명시. 그러나 Rails 측 Active Storage 미사용(003 H4) → R2의 실제 use case가 Brief에 없음. PWA 정적 자산? Profile 이미지? | scope 단계에서 R2 사용 시점 명시: (a) PWA 정적 자산 호스팅 (현재 Rails Propshaft 대체), (b) Future image upload, (c) D1 백업 dump 보관. 사용 안 하면 In Scope 1에서 R2 제거. |
| M3 | **세션 저장소 선택의 trade-off 미비** | Brief: "세션은 KV 또는 D1 기반"(In Scope 6). KV는 최종 일관성 60s, D1은 단일 스레드 throughput 천장. 모바일 API의 세션 lookup이 매 요청 발생하므로 D1 = write 폭증 위험, KV = revoke 즉시성 부족. | scope에서 세션 저장 결정: (a) JWT stateless (revocation 어려움) / (b) KV with short TTL + D1 revocation_list 보조 / (c) D1 + read replica beta 활용. Anchor 13에 결정 추가. |
| M4 | **CF outage 대응 SLA 정책 부재** | 연구 010 R11: CF 2025년 outage 3건. Brief가 리스크 수용했으나 운영 정책(예: outage 시 정적 fallback 페이지, 사용자 공지 채널) 미정의. | Anchor 14 모니터링에 추가: "Workers 5분+ outage 시 사용자 공지 메커니즘 (status 페이지 또는 모바일 앱 내 안내), Sentry 미사용이라 알림은 CF status webhook → 운영자 채널". |
| M5 | **Wrangler secrets 관리 + GitHub Actions secrets 흐름 미정의** | In Scope 1: "secrets 관리". In Scope 10: GitHub Actions + Wrangler deploy. 그러나 Toss 시크릿, AR encryption 키 3종, 세션 시그니처 키, admin password 등 secret 인벤토리와 환경별(prod/preview/staging) 분리 정책 미명시. | scope 사이클에서 secrets 인벤토리: (1) Toss client_key/secret_key, (2) Web Crypto encryption keys × 3 (deterministic, primary, salt), (3) session signing key, (4) admin basic auth password, (5) GH Actions Cloudflare API token. 각각 wrangler secret 또는 .dev.vars 분리. |
| M6 | **모바일 API 인증 흐름 (signup/login/refresh) 명시 부재** | Anchor 9: "인증 토큰은 양 서브도메인 공유". 모바일 앱이 어떻게 처음 토큰을 획득하는가? signup/login 엔드포인트 = api.<도메인>/auth/* on Workers, password 검증은 BetterAuth or 자체? token refresh 흐름? | scope에서 mobile auth flow 정의: POST /auth/signup → POST /auth/login → returns {access, refresh} → refresh on 401 → DELETE /auth/session for logout. password = bcryptjs (Workers 호환, 003 Gemfile 확인). |
| M7 | **로그·관측 가시성의 구체 항목 부재** | Anchor 14: "Workers Analytics 우선 + 필요 시 Logpush". 그러나 어떤 이벤트(scoring pipeline 실패, webhook 검증 실패, login 실패율, D1 query latency p95)를 추적하는지 미정의. | scope에서 관측 항목 인벤토리: scoring pipeline 8단계 각각의 timing, webhook idempotency 충돌율, 인증 실패율, D1 단일 쿼리 latency p95, slow query 알림. Workers Analytics Engine custom metric 사용 명시. |
| M8 | **모바일 클라이언트 (Flutter)의 OpenAPI 스키마 자동 생성 정책 부재** | In Scope 11: "shared/api-schema/ 정의". Hono RPC가 자체 type export 가능하지만, Flutter는 Dart라 TS RPC를 직접 사용 불가. OpenAPI 또는 .proto 또는 수동 정의 중 무엇? | scope에서 결정: "Hono OpenAPI 미들웨어(`@hono/zod-openapi`)로 스키마 자동 export → openapi-generator로 Dart 클라이언트 생성 → mobile/lib/api/ 자동 갱신". CI hook 검토. |

## Detailed Analysis

### A. Drizzle ORM + D1 (Decision 3, In Scope 3, 4)

**Question 1 답변**: D1의 9 JSON 컬럼·14 FK·SQLite 함수 활용이 Drizzle에서 동등 표현되는가?

- **9 JSON 컬럼**: Drizzle SQLite docs 확인. `text({ mode: 'json' }).$type<{ foo: string }>()` 패턴이 표준. Rails `t.json "metadata", default: {}` 동등 표현은 `text('metadata', { mode: 'json' }).$type<MetadataShape>().default({})` (default 값은 column 정의 시 가능). 9개 컬럼 모두 1:1 매핑 OK. **단점**: Drizzle은 JSON path 기반 인덱스/where를 1급 지원하지 않음 → `sql\`json_extract(metadata, '$.key')\`` template로 fallback. 현 schema.rb에서 JSON 컬럼에 인덱스 부재(003 schema 분석)이므로 영향 없음.
- **14 FK**: Drizzle의 `references(() => parent.id)` + `onDelete: 'cascade'`로 1:1 매핑 가능. schema.rb의 모든 FK가 단순 belongs_to → Drizzle에서 직접 표현 가능.
- **SQLite 함수 활용**: `Admin::DashboardController:17-25`의 `SUM(CASE WHEN ...)`는 Drizzle `sql` template로 표현. `find_or_create_by`/`find_or_initialize_by`는 Drizzle native 미지원 → `db.select().where(...).then(r => r ?? db.insert().values(...))` 헬퍼로 작성. 이식 시 ~20 LOC 추가.

**Question 1 답변**: Drizzle migrations가 wrangler migrations와 매끄럽게 통합되는가?

- **자동 통합되지 않음** (W3 참조). 두 시스템 모두 SQL 파일을 디렉토리에서 읽고 `_migrations` 테이블에 추적하지만 테이블명/스냅숏 메타가 다름. **통합 패턴 = `drizzle-kit generate --out=drizzle/migrations` + `wrangler.toml`의 `migrations_dir = "drizzle/migrations"` 통일**. 단, drizzle-kit이 생성하는 `_meta/0000_snapshot.json` 같은 메타는 wrangler가 무시하지만 drizzle-kit 자체는 필요로 함 → 두 도구 간 동거 OK.

**평가**: feasible-with-design-work. Brief는 "Drizzle 권장"만 단정하나 plan 단계에서 통합 패턴 명시 필요.

### B. Hono SSR — Hotwire admin 동등성 (Decision 4, In Scope 7)

**Question 2 답변**: 현재 Hotwire Turbo Frame 2 템플릿과 8 Stimulus 컨트롤러가 Hono SSR + vanilla JS로 1:1 동등하게 표현 가능한가?

- **Hotwire Turbo Frame**: `assessment_questions/_question.html.erb:1, 66` (`<turbo-frame id="current_question">`) + `show.html.erb:10-22` (`turbo_frame: "_top"` data attribute). Turbo의 시맨틱 = "form submit 응답 HTML에서 동일 ID frame을 추출해 in-place swap". Hono `html()` helper docs 확인: streaming/partial replacement 미들웨어 부재. Hono JSX docs도 component-focused로 frame 시맨틱 없음. 즉 **1:1 동등 불가능**.
- **대체 옵션**:
  - (a) **full-page reload**: 현재 흐름이 redirect_to → Turbo Frame swap이라, redirect 후 일반 GET → 전체 HTML 렌더로 단순화. UX 차이: 진행률 progress bar 깜박임 + 스크롤 점프. assessment 흐름 30~40 question 반복이라 누적 영향 가능.
  - (b) **htmx**: htmx의 `hx-target` + `hx-swap="outerHTML"`이 Turbo Frame 시맨틱과 가장 근접. ~14 KB 라이브러리, Anchor 5 "별도 SPA 빌드 회피"와 호환.
  - (c) **vanilla fetch + innerHTML swap**: 30~50 LOC 직접 작성. likert form submit → fetch POST → response.text() → DOM swap.
- **8 Stimulus controllers**: 모두 ~10-30 LOC pure DOM, Workers에서 정적 JS 자산 서빙으로 그대로 동작 가능 (Stimulus 자체는 클라이언트 라이브러리). `application.js` boot 코드만 importmap → ESM import로 변경.
- **CSRF**: Hono CSRF middleware는 origin/Sec-Fetch-Site만 검증, Rails per-session token 모델 부재. admin 영역은 origin check로 충분(내부 사용자, 신뢰 origin만 화이트리스트), 모바일 API는 JWT라 CSRF N/A. progressive enhancement는 origin check가 동작하면 OK이나 Origin 헤더가 누락되는 환경(일부 fetch credential mode, sandbox iframe)에 fallback 부재.

**평가**: **claim 부정확** (W1). Brief가 "Hono SSR + vanilla JS"라 단순화한 결정은 "Hotwire 행동 변화를 수용하거나 추가 라이브러리(htmx)/직접 코드(~50 LOC)" 결정이며 plan 사이클에서 분기 결정 필요.

### C. Web Crypto AES-GCM (User.encrypts) (In Scope 6)

**Question 3 답변**: ActiveRecord deterministic encryption(login-by-email)을 호환하게 만드는 정확한 방법은?

- **Rails 8.1 알고리즘 (rails/rails activerecord/lib/active_record/encryption/cipher/aes256_gcm.rb 직접 확인)**:
  - `CIPHER_TYPE = "aes-256-gcm"`
  - 기본 모드: `cipher.random_iv`
  - **Deterministic 모드**: `iv = OpenSSL::HMAC.digest(OpenSSL::Digest::SHA256.new, @secret, clear_text)[0...iv_length]`  (iv_length = 12 bytes for GCM)
  - key derivation: `key_derivation_salt`로 PBKDF2/HKDF 파생(별도 KeyProvider)
- **Workers Web Crypto 매핑**:
  - AES-GCM: `crypto.subtle.encrypt({name: 'AES-GCM', iv}, key, plaintext)` ✓
  - HMAC-SHA256 IV 도출: `crypto.subtle.sign('HMAC', hmacKey, plaintext)` 후 첫 12 bytes 슬라이싱 ✓
  - timing-safe compare: `crypto.subtle.timingSafeEqual` (Workers 비표준 확장) ✓
  - HKDF: `crypto.subtle.deriveBits({name:'HKDF', salt, info, hash:'SHA-256'}, baseKey, length)` 가능
- **호환성 부담**: 003 보고서: production DB 부재 → 호환 의무 없음. 새 스킴 정의 자유. 단 schema.rb의 `users.email`이 평문 string 컬럼이고 Rails encrypted attribute가 base64-encoded ciphertext를 그대로 저장하므로, 동일한 column type(TEXT)에 저장 가능.
- **이슈**: Rails encrypted payload 포맷은 **헤더 + IV + ciphertext + auth_tag**의 직렬화 형태(Rails Encryptor 클래스). 새 스킴은 자체 형식 정의 가능 — 003 권고 H5와 일치.

**평가**: **feasible**. 새 스킴 + 문서화로 충분. Brief 부정확 부분 없으나 "정확한 알고리즘 명세"는 plan 단계에서 작성.

### D. BetterAuth / Lucia 검증 (Decision 8)

**Question 4 답변**: 두 라이브러리 모두 Workers 환경에서 동작 검증됐는가?

- **BetterAuth (better-auth.com docs 확인)**:
  - "framework-agnostic, universal authentication and authorization framework for TypeScript"
  - Database adapters: Kysely(SQLite/D1), Prisma, Drizzle 모두 지원
  - **D1 명시 지원**: `@better-auth/drizzle-adapter` + `provider: 'sqlite'` 패턴, programmatic migrations via `getMigrations` (서버리스 환경용)
  - Hono 통합 docs 존재 (`/api/auth/*` 라우트 mount)
  - **Cloudflare Workers 전용 docs 페이지는 부재** (404 확인) — Hono 통합 docs는 `@hono/node-server` 기반 예제만
  - Password hashing 알고리즘 = better-auth core 자체에서 처리(`ctx.context.password` API), 구체 알고리즘 docs 미명시 → 소스 확인 필요. 기본은 scrypt로 알려져 있으나 본 critique에서 1차 검증 못 함.
- **Lucia**: **deprecated** (W2). 후보 자격 박탈.
- **세션 저장**: BetterAuth는 secondary storage에 KV-like(get/set/delete) 인터페이스 지원. Workers KV로 어댑터 작성 가능. 또는 D1만으로 stateful session 가능.
- **CSRF**: BetterAuth가 자체 CSRF 모델 제공하는지 docs에서 미확인. Hono CSRF middleware와 조합하는 패턴이 일반적.

**평가**: BetterAuth는 feasible-with-verification (Workers 전용 가이드 부재로 첫 셋업 시 시행착오 가능). Lucia 후보 제거 필요. **자체 구현 30-50 LOC**가 가장 검증 가능한 fallback — bcryptjs + signed cookie + D1 sessions table.

### E. Toss webhook + Web Crypto (Decision 5, In Scope 9)

**Question 5 답변**: HMAC-SHA256 검증을 Workers의 `crypto.subtle`로 구현 시 timing-safe compare 처리 가능한가?

- **Web Crypto + timing-safe**: 가능 (Workers `crypto.subtle.timingSafeEqual` 비표준 확장 공식 docs 확인).
- **Toss webhook 검증 메커니즘 자체**: 공식 문서(docs.tosspayments.com/guides/webhook + reference/webhook + 4종 URL 시도) **모두 검증 메커니즘 명시 부재**. Github tosspayments organization에 server-side SDK 부재. → Brief의 "50 LOC HMAC-SHA256" 가정의 1차 출처가 본 critique 시점에 재확인 안 됨.
- **함의**: 만약 Toss가 IP allowlist 또는 fixed Authorization header만 사용한다면 HMAC 검증 자체가 불필요. 만약 HMAC-SHA256이 맞다면 Workers Web Crypto로 50 LOC 가능. **결정 변수**: 첫 1차 출처 검증 후 LOC 추정 갱신.

**평가**: feasible-pending-verification. 본 critique은 Workers 능력만 검증, Toss 측 사양은 1차 출처 확인 필요 (W4).

### F. Vitest + Workers 테스트 환경 (Decision 7, In Scope 8)

**Question 6 답변**: `@cloudflare/vitest-pool-workers`로 D1·KV·Durable Objects를 테스트 가능한가? Mock vs 실제 wrangler env?

- **공식 지원 (workers-sdk 공식 fixtures 확인)**:
  - D1 + migrations: `applyD1Migrations()` API + `readD1Migrations()` config 헬퍼
  - KV, R2, Cache API: 통합 테스트 가능
  - Durable Objects: direct access 패턴
  - Queues, Workflows, Hyperdrive(TCP server), Workers AI, Vectorize: 모두 fixture 제공
- **실행 모델**: 두 가지 — (a) `exports.default.fetch()` self-contained (테스트 컨텍스트 공유, global mock 가능), (b) auxiliary worker (production 유사 환경, ahead-of-time build 필요)
- **Vitest 4.1+ 필요**

**평가**: feasible-as-is. Brief Decision 7 정확. plan 단계에서 vitest.config.ts에 `@cloudflare/vitest-pool-workers` + `wrangler.toml` 참조 + `applyD1Migrations` setup hook 명시.

### G. Phased Cutover (도메인 분리 + 인증 공유) (Decision 9, 12, Anchor 7, 9)

**Question 7 답변**: api/admin 도메인 분리 시 인증 토큰 공유는 어떻게? cookie SameSite·domain·secure 조합. JWT의 token revocation은?

- **Cookie 공유 모델 (admin SSR + api 모바일 동시 충족)**:
  - `Set-Cookie: session=xxx; Domain=.<도메인>; Secure; HttpOnly; SameSite=Lax; Path=/`
  - `api.<도메인>` + `admin.<도메인>` 모두 같은 쿠키 송수신
  - 단점: SameSite=Lax는 cross-origin POST에서 admin form 동작은 OK, 모바일 앱은 cookie jar 관리 필요
  - 장점: revocation 즉시 (D1 sessions table에서 row 삭제)
- **JWT 모델**:
  - 모바일 앱은 Authorization header로 자연스럽게 작동
  - admin SSR은 form submit이 자동으로 Authorization 헤더 못 송부 → admin도 결국 cookie 필요
  - revocation 어려움 (refresh token 회전 + revoke list 조합)
- **추천 패턴**: hybrid — admin = signed cookie, api = JWT bearer + signed cookie 둘 다 허용. session revocation은 D1 sessions table.

**Phase 사이 인증 인프라**: Phase A는 mobile API + 결제만 가동, admin은 Phase B까지 미가동 또는 Rails admin이 임시 사용 (003: SQLite production 부재라 어차피 prod data 없음). Brief는 이 구체 정책 미명시 (W11).

**평가**: feasible-with-design-work. Anchor 9 보강 필요 (W5).

### H. Custom Domain + DNS (In Scope 2, Decision 12)

**Question 8 답변**: 도메인 등록 → CF Registrar/외부 → nameserver → Workers Routes 정확한 단계.

- **공식 절차 (developers.cloudflare.com/workers/configuration/routing/custom-domains/)**:
  1. 도메인 소유 (Cloudflare Registrar 또는 외부 registrar)
  2. **Cloudflare DNS zone 활성화** 필수 — 외부 registrar면 nameserver를 CF로 변경, CF Registrar면 자동
  3. zone에 `api.<도메인>`, `admin.<도메인>` 둘 다 등록 (CNAME 미존재 상태여야 함 — 기존 CNAME 있으면 Custom Domain 충돌)
  4. wrangler.toml: `routes = [{ pattern = "api.<도메인>", custom_domain = true }, { pattern = "admin.<도메인>", custom_domain = true }]` 또는 dashboard에서 추가
  5. Cloudflare가 자동 Advanced Certificate 발급 (수 분~수 시간)
- **제약**: wildcard 미지원 (`api.<도메인>`은 `www.api.<도메인>` 매칭 안 함), zone 소유 필수
- **두 도메인이 같은 zone일 때만 cookie domain `.<도메인>`로 공유 가능** (W5와 일관)

**평가**: feasible-as-is, 절차 기계적. plan 단계에서 도메인 등록자(CF Registrar 권장 for 단순화) + DNS 마이그 일정 명시.

## Recommendations for Brief Revision

1. **(Critical, W1) Decision 4 분리**: "Hono SSR + vanilla JS"를 (a) full-page reload 수용 / (b) htmx 도입 / (c) 직접 fetch+swap 30-50 LOC 3안 중 1안 선택. anchor 5에 명시. UX 다운그레이드 수용 정도가 결정의 함의.

2. **(Major, W2) Decision 8 갱신**: "BetterAuth/Lucia 라이브러리 검토" → "BetterAuth 또는 자체 구현". Lucia 제거(2025-03 deprecate). 자체 구현 fallback의 LOC 추정 (bcryptjs + signed cookie + D1 sessions ≈ 100 LOC).

3. **(Major, W3) Decision 3 정밀화**: "Drizzle ORM"을 "Drizzle ORM (drizzle-kit + wrangler 통합 migrations dir)"로 명시. Anchor 4 또는 새 In Scope 항목으로 마이그 통합 패턴 추가.

4. **(Major, W4) In Scope 9 + Decision 5 재근거화**: scope 진입 전 Toss 공식 webhook 인증 메커니즘 1차 확인. HMAC-SHA256 가정이 검증되거나 다른 방식으로 갱신. LOC 추정 재계산.

5. **(Major, W5+W6) Anchor 9 확장**: 인증 토큰 공유 모델 명시 — admin = signed cookie (Domain=`.<도메인>`, HttpOnly, Secure, SameSite=Lax), api = signed cookie 또는 Bearer JWT 둘 다 허용, CSRF는 admin에 한해 origin check + 신뢰 origin 화이트리스트.

6. **(Major, W7) In Scope 4 또는 plan 사이클 ResultsController 재설계 명시**: 8단계 scoring pipeline을 D1 batch 2분할(step 1-5 / step 6 분기 / step 7-8) 또는 Durable Object 결정. atomicity 약화 수용 명시.

7. **(Missing M3) Anchor 13 확장**: 세션 저장소 결정 (KV vs D1 vs JWT) trade-off 명시.

8. **(Missing M5) scope 사이클 첫 작업으로 secrets 인벤토리** 작성: Toss + Web Crypto keys × 3 + session signing + admin password + GH Actions API token, 환경별(prod/preview/staging) 분리 정책.

9. **(Missing M6) Anchor 9 또는 신규 항목**: 모바일 auth flow (signup/login/refresh/logout 엔드포인트 + 토큰 lifecycle) 정의.

10. **(Missing M2) In Scope 1 R2 사용 시점 명시 또는 제거**: Active Storage 미사용이라 R2 default use case 없음. PWA 정적 자산 또는 D1 백업 dump 보관 등 명시 안 하면 In Scope 1에서 제거.

## References

| Resource | Path/URL | Relevance |
|----------|----------|-----------|
| Brief 001 | `/Users/kampikrein/A/personality/docs/6_backend/02_cf_workers_rebuild/001_Brief_cf_workers_rebuild.md` | 비평 대상 |
| Research 010 | `/Users/kampikrein/A/personality/docs/6_backend/01_cloudflare_migration_research/010_Research_cloudflare_migration.md` | 결정 기반 사실 |
| Rails 자산 003 | `/Users/kampikrein/A/personality/docs/6_backend/01_cloudflare_migration_research/003_Agent_current_rails_assets.md` | 코드베이스 인벤토리 |
| CF 한계 004 | `/Users/kampikrein/A/personality/docs/6_backend/01_cloudflare_migration_research/004_Agent_cloudflare_stack_capabilities.md` | 인프라 제약 |
| User 모델 | `/Users/kampikrein/A/personality/server/app/models/user.rb:4-5` | encrypts deterministic 사용처 |
| 스키마 | `/Users/kampikrein/A/personality/server/db/schema.rb` | 14 테이블 + 9 JSON + 14 FK |
| Gemfile | `/Users/kampikrein/A/personality/server/Gemfile` | bcrypt, has_secure_password 의존 |
| ResultsController | `/Users/kampikrein/A/personality/server/app/controllers/results_controller.rb:21-67` | 8단계 scoring transaction |
| AssessmentQuestion 뷰 | `/Users/kampikrein/A/personality/server/app/views/assessment_questions/_question.html.erb:1,32-34,66` | Turbo Frame + form_with |
| Assessment show 뷰 | `/Users/kampikrein/A/personality/server/app/views/assessments/show.html.erb:10-22` | turbo_frame: "_top" |
| Stimulus likert | `/Users/kampikrein/A/personality/server/app/javascript/controllers/likert_controller.js` | requestSubmit 패턴 |
| Stimulus controllers | `/Users/kampikrein/A/personality/server/app/javascript/controllers/` | 8 컨트롤러 (autosave, countdown, likert, progress, questionnaire, spectrum_bar, tabs, type_reveal) |
| application.rb | `/Users/kampikrein/A/personality/server/config/application.rb:43-45` | AR encryption 키 3종 ENV |
| Drizzle D1 connect | https://orm.drizzle.team/docs/connect-cloudflare-d1 | drizzle/d1 어댑터 |
| Drizzle SQLite types | https://orm.drizzle.team/docs/column-types/sqlite | text({mode:'json'}).$type<T>() 확인 |
| Drizzle Kit | https://orm.drizzle.team/docs/kit-overview | drizzle-kit generate/migrate/push |
| Drizzle migrations | https://orm.drizzle.team/docs/migrations | 마이그 워크플로우 |
| Wrangler D1 migrations | https://developers.cloudflare.com/d1/reference/migrations/ | wrangler d1 migrations apply (별도 추적) |
| Workers Web Crypto | https://developers.cloudflare.com/workers/runtime-apis/web-crypto/ | AES-GCM, HMAC, timingSafeEqual 지원 |
| Hono JSX | https://hono.dev/docs/guides/jsx | JSX SSR (component-focused) |
| Hono html helper | https://hono.dev/docs/helpers/html | tagged template, partial replacement 미들웨어 부재 |
| Hono CSRF | https://hono.dev/docs/middleware/builtin/csrf | origin/Sec-Fetch-Site 기반 (token 기반 아님) |
| BetterAuth | https://www.better-auth.com/docs | framework-agnostic, D1 지원 |
| BetterAuth DB | https://www.better-auth.com/docs/concepts/database | D1 명시, secondary storage KV-like |
| BetterAuth Hono | https://www.better-auth.com/docs/integrations/hono | Hono mount 패턴 (Workers 전용 가이드 부재) |
| BetterAuth Drizzle | https://www.better-auth.com/docs/adapters/drizzle | drizzleAdapter(db, {provider:'sqlite'}) |
| Lucia | https://github.com/lucia-auth/lucia | **2025-03 deprecate**, 학습자료화 |
| Rails AES256GCM | https://github.com/rails/rails/blob/main/activerecord/lib/active_record/encryption/cipher/aes256_gcm.rb | deterministic IV = HMAC-SHA256(secret, plaintext)[0..iv_length] |
| vitest-pool-workers | https://developers.cloudflare.com/workers/testing/vitest-integration/test-apis/ | applyD1Migrations + readD1Migrations |
| vitest-pool-workers fixtures | https://github.com/cloudflare/workers-sdk/tree/main/fixtures/vitest-pool-workers-examples | D1, KV, R2, DO, Queues, Workflows |
| Workers Custom Domain | https://developers.cloudflare.com/workers/configuration/routing/custom-domains/ | zone 소유 + 자동 cert + wildcard 미지원 |
| Toss webhook docs | https://docs.tosspayments.com/guides/webhook | retry/log은 명시, **검증 메커니즘 미명시** |
| Toss org github | https://github.com/tosspayments | browser-sdk + Android/iOS만, server SDK 부재 |

## Communication Log

| # | Direction | Peer | Summary | Stage |
|---|-----------|------|---------|-------|
| 1 | OUT | Scope perspective | (Hand-off) Decision 4 "Hono SSR + vanilla JS"는 Hotwire Turbo Frame과 1:1 동등 아님 — full-reload/htmx/직접 작성 3안 중 1안 결정 필요. plan 사이클에서 분기. | Critique complete |
| 2 | OUT | Scope perspective | (Hand-off) ResultsController 8단계 scoring pipeline은 D1 batch 단일로 표현 불가. 2-batch 분할 + 실패 cleanup 또는 Durable Object 채택 결정 필요. | Critique complete |
| 3 | OUT | Risk perspective | (Hand-off) Toss webhook 검증 메커니즘이 공식 docs에서 명시되지 않음. 1차 출처 확인 후 LOC/공수 재검증 — "50 LOC HMAC-SHA256" 가정의 위험. | Critique complete |
| 4 | OUT | Alternatives perspective | (Hand-off) Lucia v3는 2025-03 deprecated. Decision 8의 후보에서 제거 필요. BetterAuth + 자체 구현 2안만 유효. | Critique complete |
| 5 | OUT | Risk perspective | (Hand-off) Drizzle migrations와 wrangler d1 migrations는 자동 통합되지 않음. 통합 패턴(공유 디렉토리 + 단일 추적 시스템) 결정 누락 시 plan 단계에서 충돌 가능. | Critique complete |
| 6 | OUT | Scope perspective | (Hand-off) `api.<도메인>` + `admin.<도메인>` 인증 모델이 cookie/JWT 비대칭. admin SSR은 cookie 강제, mobile은 JWT 가능 — Anchor 9 분리 필요. | Critique complete |
