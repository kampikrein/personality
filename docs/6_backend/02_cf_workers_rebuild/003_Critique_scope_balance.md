---
id: "003"
type: critique
title: "Brief Critique — Scope Balance (범위 적정성)"
created: 2026-04-28
status: complete
perspective: "scope_balance"
target: "001"
confidence: high
model: "opus"
reasoning_depth: "deep"
summary: >
  Brief 001(In Scope 13 / Out of Scope 8)을 codebase 실측에 비추어 평가했다.
  In Scope의 도메인 인프라·DB·서비스·Hono routes·결제 webhook·CI/CD까지의
  골격은 견고하나, 조작가능한(operable) 시스템을 만들기에는 운영 횡단 기둥
  6개가 누락 또는 과소 정의됐다: (1) GDPR 모델(consent/deletion_request/
  audit_log)의 이전 명시, (2) admin 인증 분리(현재 HTTP Basic + ENV → CF에서
  세션·역할 모델 결정 부재), (3) secrets/환경변수·환경 분리 자동화의 표면적
  명시, (4) 결제 흐름의 webhook-only 스코핑(initiate/confirm/cancel/refund/
  receipt 부재), (5) shared/api-schema의 placeholder 상태와 OpenAPI/codegen
  계약 부재, (6) 보안 횡단(CORS·CSP·HSTS·rate limit·CSRF 재구현·security
  headers). 추가로 i18n(현 ERB 한글 하드코딩)·일관 API envelope·로깅 표준·
  알림 채널·백업·QuestionSet seed의 출처가 모두 unstated. 13개 항목의 의존
  관계가 묵시적이며 cutover Phase A/B/C 외에 항목 단위 의존 그래프 부재.
  10개 누락 영역과 8개 actionable Recommendations 제시.
keywords: [critique, brief, scope-balance, in-scope, out-of-scope, gdpr, monitoring, payment-flow, admin-auth, security-headers, i18n, api-contract]
---

# Brief Critique — Scope Balance

## Executive Summary

Brief 001은 "현 Rails를 무엇으로 어떻게 갈아끼우는가"의 **공급측 매핑**(infra→DB→domain services→routes→admin UI→test→CI/CD)에 충실하다. 그러나 **운영가능한 시스템을 가동시키는 데 필요한 횡단 요소(operational cross-cutters)** 가 In Scope 13개에 흩어져 있거나 (#1, #6, #13에 한 줄로 압축) 빠져 있다. 이는 implementation 단계에서 "scope에 안 적혀 있으니 별도 토픽"으로 미뤄질 위험이 크고, 그 결과 Phase A 가동 시점에 GDPR 미준수·secrets 노출·admin 권한 분리 부재·결제 환불 미지원 같은 누수가 누적될 가능성이 높다.

특히 우려되는 4개 영역:

1. **GDPR/컴플라이언스 자산** — 현 Rails는 `consent`, `deletion_request`, `audit_log`, `Compliance::DeletionProcessor` (134 LOC, cascade delete)를 이미 보유한다. Brief는 "도메인 services 이식"(In Scope 4)에 묶어서 처리하려는 듯 보이나 명시 부재. GDPR/PIPA 의무 흐름이 Phase A에 가동되지 못하면 production 노출 시점에 즉시 컴플라이언스 리스크.

2. **admin 인증 분리** — 현재 admin은 `http_basic_authenticate_with` + ENV password 1개. CF로 가면 사용자 인증(In Scope 6)과 admin 인증의 동거 모델·역할 권한·세션 격리가 새로 결정돼야 하나 In Scope에 admin auth가 명시되지 않음. "admin user 모델 없음"의 현 상태를 그대로 가져갈지, 별도 admin user 도입할지가 미결.

3. **결제 흐름의 webhook-only 스코핑** — In Scope 9는 "Toss webhook idempotency"만 다룸. 실제 결제는 결제 시작 → 인증 → confirm API → webhook → 환불 → 영수증의 6단계이며 환불·취소·실패 재시도·영수증·세금계산서·정산 보고서 처리가 누락. 현 Rails는 결제 0이므로 "신규"이지만 Brief는 "통합"이라는 단어로 webhook 한 줄에 압축.

4. **shared/api-schema 명시 부재** — `shared/api-schema/`는 `README.md`만 있는 placeholder. In Scope 11(모바일 통합)은 "shared/api-schema/ 정의"를 한 줄 언급할 뿐 OpenAPI 스펙 정의 위치, codegen 흐름, 클라이언트 SDK 생성, 버전 관리 정책이 빠져있다. 모바일 빌드와 백엔드 배포의 contract 동기화가 implementation 단계에서 ad-hoc으로 굳어질 위험.

Out of Scope 8개는 적절하나 Out of Scope #6("새 도메인 기능 추가")이 GDPR/admin 같은 **컴플라이언스 횡단**을 "기능"으로 간주해 자동 배제하는 해석을 유발할 위험이 있다. 명시적 보호 문구 필요.

## Findings

### Strengths

- **In Scope 1, 3, 4, 8은 정량 근거가 분명**: 14 테이블, 1,850 LOC services, 18 RSpec 파일이 003 보고서로 traces.
- **Cutover 안전성을 별도 priority dimension으로 격상**: Ideal Criteria 12·13에 Cutover Safety 차원으로 구분하여 Rails archive 보존을 강제. 이 부분은 빠짐 없음.
- **Out of Scope의 결제 글로벌(Stripe Korea 부재) 이슈 명시**: Decision 13에서 "단계적"으로 reframing.
- **Decision 자체는 자기일관됨**: 13개 Decision이 13개 In Scope와 1:1 매핑 가능 (Decision 9 Phased = In Scope 12 Cutover, Decision 4 Hono SSR = In Scope 7, etc.).

### Weaknesses

| # | Finding | Severity | Evidence | Recommendation |
|---|---------|----------|----------|----------------|
| W1 | GDPR/컴플라이언스 모델(consent, deletion_request, audit_log)의 이전이 In Scope에 별도 항목으로 명시되지 않음. 4(services)에 implicit 흡수돼 우선순위 불명. | **High** | `server/app/models/{consent,deletion_request,audit_log,alert}.rb`, `server/app/services/compliance/deletion_processor.rb`(134 LOC cascade), `server/app/controllers/{consents,deletion_requests}_controller.rb` | In Scope에 별도 항목 "9.5 GDPR/컴플라이언스 흐름 이전"을 추가. consent 동의 UX(국외 이전 고지 포함), deletion_request SLA(7일), audit_log idempotent record, alert(bot/policy/anomaly/system) 4종 모두 명시. |
| W2 | admin 인증 분리·역할 모델이 In Scope에 부재. 현 `http_basic_authenticate_with`(`admin/base_controller.rb:5`)을 그대로 갈지, admin user 모델 도입할지 미결. | **High** | `server/app/controllers/admin/base_controller.rb` (Basic Auth + ENV) — admin user 테이블 없음 (스키마에 `users`만 있고 admin role 컬럼 없음) | Decision 추가: "Admin auth = Basic Auth on `admin.<도메인>` (단일 자격) 또는 admin role flag on User". In Scope 6(인증·세션)에서 admin/일반 분리 명시. |
| W3 | secrets·환경변수 관리(Wrangler secrets, GitHub Actions secrets, KEK 회전, 로컬 .dev.vars)의 운영 모델이 In Scope 1에 한 줄로만 압축. | **High** | 현 Rails는 `RAILS_MASTER_KEY`, `AR_ENCRYPTION_PRIMARY_KEY`, `AR_ENCRYPTION_DETERMINISTIC_KEY`, `AR_ENCRYPTION_KEY_DERIVATION_SALT`, `ADMIN_USERNAME/PASSWORD`, `TOSS_SECRET_KEY`(예정) 등 ≥ 7개 시크릿이 필요. CF에서 wrangler secret put + GH Actions Secrets + 환경별 분리(prod/preview/staging) 정책 미정. | In Scope 1을 분리: "1a CF 인프라 셋업"·"1b Secrets/환경변수 관리(Wrangler secrets, GH Actions Secrets, env mapping table, 회전 절차)" 항목으로 별도 명시. |
| W4 | 보안 횡단(CORS, CSP, HSTS, X-Frame-Options, security headers, rate limiting, DDoS 방어)이 In Scope에 부재. | **High** | `server/config/initializers/content_security_policy.rb`는 전체 주석 처리 — 현재 CSP 미적용. `Gemfile`에 rack-attack 등 rate limit gem 없음. CF Workers는 자동 DDoS 흡수하지만 application-level rate limit(예: webhook 폭주, login brute force)은 별도. | In Scope에 "보안 횡단" 항목 신설: CORS(api.<도메인> origin allowlist), CSP(admin.<도메인>), HSTS, X-Frame-Options, Hono 미들웨어 기반 rate limit, CF Turnstile 검토. |
| W5 | 결제 In Scope 9가 webhook idempotency만 다룸. 결제 시작 / 결제창 호출 / confirm API / 취소 / 환불 / 영수증 / 정산 보고서 / 재시도가 모두 미명시. | **High** | 003에 `server/app/services/payment/` 부재 확인 (결제 코드 0). 005 보고서가 PG-stack 매트릭스만 다루고 흐름 단계별 LOC 추정 없음. | In Scope 9를 결제 **흐름 7단계**(initiate / authorize / confirm / webhook / cancel / refund / receipt)로 풀어 명시. 환불 정책(부분/전액), 멱등 키 정책, 정산·세금계산서 처리도 phase 내/외 구분. |
| W6 | shared/api-schema/ placeholder 상태와 OpenAPI/codegen 계약 부재. In Scope 11이 "shared/api-schema/ 정의"만 언급. | **High** | `shared/api-schema/`는 빈 디렉터리 + `README.md` 한 줄. `mobile/lib/`에 HTTP 클라이언트 0 (drift, dio 등 import 0 — freezed/riverpod만). | Decision 추가: "API contract = OpenAPI 3.1 + openapi-typescript(서버) + openapi-generator-dart(모바일)" 또는 동등안. In Scope 11에 SDK 생성 흐름과 버전 관리(SemVer) 정책 명시. |
| W7 | 일관된 API 응답 envelope(JSON 표준 형태, error code 체계) 표준이 부재. | **Medium** | 현 Rails는 JSON API 0개 — Brief가 "신설"인데도 envelope 정책 미언급. Hono는 자유. 모바일이 일관된 error 처리하려면 표준 필요. | Decision 추가: "API envelope = `{data, error?, meta?}` + 에러 코드 enum 표준화". In Scope 5(API 레이어)에 명시. |
| W8 | 로깅 표준(structured logging, request ID, PII 필터)이 In Scope 13에 "콘솔 로그"로만 압축. | **Medium** | Rails는 `config/initializers/filter_parameter_logging.rb`로 PII 필터링 — CF로 가면 동등 정책 신규 작성 필요. | In Scope 13을 분리: "13a 모니터링(Workers Analytics + 알림 채널 — Sentry/Discord webhook 권장 또는 결정 보류 명시)"·"13b 로깅 표준(JSON structured, request_id 미들웨어, PII 필터 enum)". |
| W9 | i18n(한국어/영어 처리)이 In Scope에 부재. 현 ERB는 한국어 직접 하드코딩. | **Medium** | `server/config/locales/en.yml`은 placeholder("hello: Hello world")만. 모든 ERB 텍스트는 Korean 하드코딩 (003 § Views). | Decision 추가: "i18n = 한국어 single locale 우선, 향후 영어 추가 시 별도 토픽" — 명시적으로 단일 로케일 보존을 결정으로 못박음. 그러지 않으면 Phase A에서 admin SSR가 한국어/영어 mixed가 될 위험. |
| W10 | 백업·복구·DB 데이터 portability가 Constraints의 "D1 → SQLite export" 한 줄로만 압축. | **Medium** | `wrangler d1 export` 자동화·R2 versioning·복구 절차·시점 복구 가능성이 미정. CF 2025 outage 4h35m 이력 (008) 대응 절차 부재. | In Scope에 "백업·DR" 항목 추가: 일/주 D1 export → R2 보관, 보관 기간, 복구 RTO/RPO 목표(임시값이라도). |
| W11 | In Scope 13개의 의존 그래프 부재. 의존 순서가 묵시적. | **Medium** | Decision 9에서 Phase A/B/C 큰 갈래만 정의. 13개 항목의 항목 단위 선후 관계 미정. | Brief에 "Dependency map" 섹션 추가: 13개 항목의 의존 트리(예: 1 → 3 → 4 → 5 → 6, 6 → 9, 5+6 → 11, 1+10 → all). scope/makeplan 단계가 이 트리 위에서 사이클을 분해. |
| W12 | DB 인덱스·읽기 패턴 검토가 부재. D1 단일 스레드 제약(004 § R7)을 고려한 쿼리 프로파일링 항목 없음. | **Low** | 현 schema는 14 FK + 14개 정도 index. admin/dashboard의 raw SQL aggregate(`SUM(CASE...)`)는 읽기 무거움 — D1에서 측정 필요. | In Scope 8(테스트)에 "성능 회귀 테스트(주요 admin/results 쿼리 기준)" 추가 또는 별도 항목 신설. |
| W13 | "Rails 폐기 시점"의 정량 trigger가 모호. In Scope 12는 Phase C 진입 조건만 텍스트로 언급. | **Low** | Decision 9는 "각 단계 검증 후 다음"이지만 검증 기준이 없음. | Constraints에 "Phase C 진입 trigger = (a) 모바일 API SLO 30일, (b) admin SSR 기능 동등성 100% 통과, (c) 결제 flow 7단계 검증, (d) GDPR 흐름 production 검증" 같이 정량화. |

### Missing Elements

| # | What's Missing | Why It Matters | Suggestion |
|---|----------------|----------------|------------|
| M1 | **Email/SMS/Push 알림 채널** | deletion_request 7일 SLA 안내, 결제 완료/실패 안내, 비밀번호 reset 등 트랜잭셔널 메시지 발송 채널이 In Scope에 없음. CF는 자체 메일 서비스 미보유 → SES/Resend/Mailgun 등 외부 의존 필요 결정. | In Scope에 "알림 채널" 항목 추가 또는 Out of Scope에 "트랜잭셔널 이메일은 별도 phase"로 명시적 deferral. |
| M2 | **개인정보 국외 이전 고지·동의 UX** | CF 글로벌 인프라 사용 → 국외 이전 동의가 PIPA 의무. 005 § Caveats가 "차단 사유 아니나 운영 부담"으로 명시. Brief는 미언급. | In Scope에 "PIPA 국외 이전 동의 UX(consent 모델에 type 추가 또는 별도 컬럼)" 명시. |
| M3 | **회원 탈퇴·계정 삭제 흐름** | 현재 `User` 모델에 destroy 흐름 부재 (deletion_request는 anonymous_session 단위). 가입한 user의 계정 삭제 흐름이 미정. | In Scope에 "User 계정 삭제 흐름(GDPR Right to Erasure)"을 deletion_request 확장 또는 별도로 명시. |
| M4 | **검색·랭킹 및 PersonalityType seed 출처** | 003은 "16 PersonalityType 326 LOC seed가 도메인 콘텐츠"라고 명시. 이 콘텐츠의 출처·저작권·검토자가 Brief 어디에도 없음. | Constraints에 "PersonalityType seed = 기존 Rails seeds.rb 그대로 이식, 콘텐츠 검증은 별도 phase(personality 도메인 에이전트 영역)" 명시. |
| M5 | **Workers AI / R2 bucket의 실제 용도** | In Scope 1이 "R2 bucket"을 셋업 항목으로 포함했으나, **무엇을 보관할지** 미정. 현 Rails는 Active Storage 미사용(003). 즉 R2가 진짜 필요한지 자체가 불명. | Decision 추가: "R2 = (a) 백업 / (b) 정적 자산 / (c) 사용자 업로드 — 본 phase에서는 (a)만". 무용 셋업 회피. |
| M6 | **모바일 앱의 인증 토큰 라이프사이클** | 모바일은 cookie 세션 미사용 → JWT/OAuth 토큰. refresh, revoke, device-bound 정책 부재. | In Scope 6(인증)에 "모바일 토큰 = JWT (access 15분 + refresh 30일) + KV revocation list" 같은 결정. |
| M7 | **Worker → DB 트랜잭션 경계 정책** | 004 § R12: D1은 interactive transaction 부재. results_controller.rb의 8단계 inline transaction은 그대로 옮길 수 없음. | In Scope 4(서비스 이식) 또는 5(API)에 "트랜잭션 경계 = D1 batch only, 다단 워크플로우는 application-level saga + idempotency"라는 패턴 결정 명시. |
| M8 | **개발자 DX(Rails console 대체)** | 008 § R9: DX gap 명시. wrangler dev + d1 query만으로 production debug 어려움 (예: 특정 user GDPR 처리). admin SSR에 ad-hoc 조회 도구 필요. | In Scope 7(Admin UI)에 "운영 도구(특정 user GDPR 처리, alert 수동 트리거 등) 최소 셋" 명시. |
| M9 | **CSRF 토큰 재구현** | 003 § H5: Rails는 CSRF/세션 쿠키를 implicit 처리. Hono로 가면 표준 부재. admin SSR + 일반 user 세션 양쪽 다 필요. | In Scope 6(인증·세션) 또는 별도 항목에 "CSRF = Hono 미들웨어 + double submit cookie + admin SSR 별도 토큰" 명시. |
| M10 | **에러 모니터링·알림 라우팅** | "에러 알림 채널 연결"이라는 In Scope 13 한 줄 외에 채널·임계·on-call 정책 없음. CF 2025 outage 3건(008 § R11) 대응 매뉴얼도 없음. | In Scope 13에 "에러 임계(5xx 비율, p99 latency, D1 storage 80%)별 알림 채널 라우팅" 명시. on-call/runbook은 별도 phase로 분리. |

## Detailed Analysis

### A. In Scope 13 항목별 완전성 평가

| # | Item | 완전성 | 평가 |
|---|------|--------|------|
| 1 | CF 인프라 셋업 | **Partial** | account/Workers/D1/R2/KV/Wrangler/secrets 7요소 한 줄 압축. Secrets 회전·환경별(prod/preview/staging) 매핑·R2 buck 용도가 모두 미정. 3-4개 sub-items로 분리 권장. |
| 2 | 도메인 + TLS | **OK** | api/admin 두 서브도메인 + Workers Routes 매핑은 정확. DNS 등록 대상(CF/외부)·인증서 타입(SSL Universal vs Advanced)만 결정 추가하면 충분. |
| 3 | DB 스키마(Drizzle) | **OK** | 14 테이블 + 9 JSON 컬럼 + 14 FK + seed 명시. ON DELETE CASCADE·인덱스 전략(특히 D1 단일 스레드 고려)만 추가하면 견고. |
| 4 | 도메인 services 이식 | **OK** | 1,850 LOC + Vitest 동행 + TDD 명시. 단 compliance/deletion_processor의 cascade 트랜잭션이 D1에서 saga로 풀려야 하는 점이 묵시적. |
| 5 | API 레이어 | **Partial** | 13 컨트롤러 → Hono router는 명확하나, "기존 HTML 라우트는 admin 영역에서 SSR로 재현 또는 폐기"가 모호. 어떤 HTML 라우트가 SSR이고 어떤 것이 mobile JSON으로 이행되는지 매핑 표 필요. API envelope·error code 표준 부재. |
| 6 | 인증·세션 | **Partial** | login-by-email + AES-GCM 수동 구현 + KV/D1 세션은 명시. admin 인증 분리·모바일 JWT·CSRF·역할 모델·OAuth 단계가 모두 미정. |
| 7 | Admin UI 대체 | **OK** | Hotwire 2 + Stimulus 8 → Hono SSR + vanilla JS 전략 명확. 단 admin 5 컨트롤러(dashboard/alerts/audit_logs/question_sets/base) 모두 cover하는지 한 줄 명시 권장. dashboard의 raw SQL aggregate(SUM CASE) D1 호환은 검증 필요. |
| 8 | 테스트 재작성 | **OK** | 18 RSpec → Vitest. 도메인 동등성 보장 명확. 단 request spec 18개 중 현재 2개만 존재(full_flow + sessions) → 신규 mobile API용 contract 테스트 추가 명시 권장. |
| 9 | 결제 통합 | **Partial** | webhook idempotency만 명시. 결제 흐름의 7단계(initiate/authorize/confirm/webhook/cancel/refund/receipt) 미언급. 환불·정산은 phase 내인지 외인지 모호. |
| 10 | CI/CD | **OK** | GH Actions + Wrangler + 3환경 분리 명확. 단 "PR preview"는 Workers Preview URL의 유효 범위(D1 공유?, R2 공유?, secrets?)가 미정 — Phase A 가동 후 confusion 위험. |
| 11 | 모바일 통합 | **Weak** | shared/api-schema는 placeholder. 모바일 lib에 HTTP 클라이언트 0. OpenAPI/codegen·SDK·버전 관리가 모두 unstated. 인증·결제 흐름 검증의 정의도 모호. |
| 12 | Rails 폐기(Cutover) | **OK** | archive 보존 강제·삭제 금지·6개월 이상이 명확. 단 Phase C 진입의 정량 trigger 부재(W13). |
| 13 | 모니터링·로깅 | **Partial** | Workers Analytics + 콘솔 로그 + Logpush 우선순위는 OK. structured logging, request ID, 알림 채널 구체, PII 필터, 에러 임계가 모두 미정. |

### B. Out of Scope 8 항목 적절성

| # | Item | 적절성 | 평가 |
|---|------|--------|------|
| 1 | 대체 인프라 | **OK** | Hetzner/Vercel/AWS 명확히 차단. |
| 2 | Hyperdrive+PG | **OK** | D1 천장 도달 시 별도 토픽으로 미룸. 단 Constraints에 trigger(80%) 있음 — 일관됨. |
| 3 | Stay/Partial | **OK** | 사용자 결정 못박음. |
| 4 | Stripe 글로벌 | **OK** | Decision 13과 일관. 단 "단계적 병행" 구체 trigger(해외 법인 시점) 미정 — 본 phase에서는 제외 명확하므로 OK. |
| 5 | Flutter 아키텍처 변경 | **OK** | 모바일 변경은 별도 토픽. |
| 6 | **새 도메인 기능 추가** | **Risk** | 너무 광범위. GDPR consent 국외 이전 동의나 admin role 추가가 "기능 추가"로 해석돼 Phase A에서 누락될 위험. "기능 = 새 도메인 콘텐츠/검사 항목 추가" 같이 좁히기 필요. |
| 7 | Next.js/SPA | **OK** | Hono SSR로 충분. |
| 8 | 데이터 마이그레이션 | **OK** | production DB 부재 → seed 재생성 명확. PersonalityType seed 출처는 별도(M4). |

**총평**: 8개 중 7개가 적절. #6만 광범위하여 컴플라이언스·운영 횡단이 "기능"으로 분류돼 누락될 위험이 있다.

### C. 누락 의심 영역

10개 누락 영역(M1~M10)은 위 표 정리. 카테고리화:

- **법규/컴플라이언스**: M2(국외 이전 동의), M3(계정 삭제), W1(consent/deletion_request 명시)
- **보안 횡단**: W4(CORS/CSP/HSTS/rate limit), M9(CSRF)
- **운영 표면**: M1(알림 채널), M10(에러 임계·라우팅), W3(secrets), W10(백업)
- **API contract**: W6(OpenAPI/codegen), W7(envelope/error code), M6(JWT 라이프사이클)
- **개발자 DX**: M8(운영 도구), M7(트랜잭션 경계), W12(쿼리 프로파일)
- **콘텐츠/i18n**: W9(i18n), M4(PersonalityType seed 출처)
- **인프라 쓰임**: M5(R2 용도)
- **의존 그래프**: W11(13개 항목 의존 트리)

### D. 결제 흐름 완전성

In Scope 9(결제) + Decision 5/6/13만으로는 결제 전체 흐름을 가동할 수 없다. 다음 7단계 중 명시 = 1, 묵시 = 1, 미정 = 5:

| 단계 | Brief 명시 | 비고 |
|------|------------|------|
| 1. Initiate (주문 생성, 결제 의도) | 미정 | order/payment_intent 모델 미정 |
| 2. Authorize (PG 결제창 호출) | 미정 | Toss SDK init·redirect URL·환경별 분기 미정 |
| 3. Confirm (PG → 백엔드 confirm API) | 미정 | confirm endpoint·idempotency key 미정 |
| 4. Webhook (PG → 백엔드 비동기 통지) | **명시 (HMAC-SHA256, D1 UNIQUE(event_id))** | 유일하게 cover |
| 5. Cancel (사용자/관리자 취소) | 미정 | 권한·상태 전이 미정 |
| 6. Refund (부분/전액 환불) | 미정 | 환불 정책·정산 영향 미정 |
| 7. Receipt/Settlement (영수증, 세금계산서, 정산 보고서) | 묵시 | "한국 표준" 한 줄에 흡수, 영수증 발행/세금계산서/정산 미정 |

**위험**: Phase A에 결제가 가동되는 시점에 환불·취소가 미구현이면 사용자 분쟁 즉시 발생. 영수증/세금계산서는 한국 가맹점 의무.

**권장**: In Scope 9를 7단계 표로 분해하고, 각 단계의 phase 내/외 결정을 명시. 최소 1·2·3·4·5는 phase 내, 6은 phase 내(부분 환불 단순화), 7은 phase 외(별도 phase) 같은 기본 권고.

### E. 모바일 API contract 완전성

In Scope 11(모바일 통합) 평가 — **Weak**:

| 요소 | 상태 |
|------|------|
| `shared/api-schema/` 디렉터리 | **빈 디렉터리 + README.md만** (실측) |
| OpenAPI / Smithy / protobuf 선택 | 미정 |
| 서버측 codegen (router types) | 미정 |
| 모바일측 codegen (Dart SDK) | 미정 |
| 버전 관리 정책 (URI vs 헤더) | 미정 |
| Breaking change 정책 | 미정 |
| Mobile 현 상태 — HTTP 클라이언트 import | **0** (`mobile/lib/`에 dio/http import 없음, freezed/riverpod/drift만) |
| 인증 흐름 (모바일 ↔ api.<도메인>) | 미정 (W6, M6) |
| 결제 흐름 (모바일 → confirm → webhook) | 미정 (D) |

**권장**: Decision에 "API contract = OpenAPI 3.1 + openapi-typescript + openapi-generator-dart" 명시 + In Scope 11을 다음 sub-items로 분해:
- 11a OpenAPI 스펙 작성 (shared/api-schema/openapi.yaml)
- 11b 서버 codegen 통합 (Hono route types)
- 11c 모바일 SDK 생성 (Dart client + Riverpod provider 통합)
- 11d 인증 토큰 라이프사이클 구현
- 11e 결제 흐름 모바일 측 연동

### F. admin 기능 (audit_log/consent/deletion_request 등) 이전 명시성

현 Rails 자산을 In Scope 5(API) + 7(Admin UI) cover 여부 확인:

**현 admin 컨트롤러 5개** (`server/app/controllers/admin/`):

| 컨트롤러 | 액션 수 | In Scope 7 cover? | 비고 |
|---------|--------|------------------|------|
| `base_controller.rb` | (auth 가드) | **Implicit** | Basic Auth → Hono 미들웨어. 단 admin auth 모델 결정 필요(W2) |
| `dashboard_controller.rb` | 3 (index/completion_rates/drop_off_analysis) | **Implicit** | raw SQL aggregate D1 호환 검증 필요 |
| `alerts_controller.rb` | 3 (index/show/update) | **Implicit** | Alert.4 status 전이(open/ack/resolved/dismissed) 명시 부재 |
| `audit_logs_controller.rb` | 2 (index/show) | **Implicit** | filter 파라미터(action_filter, type_filter) 명시 부재 |
| `question_sets_controller.rb` | 7 (CRUD) | **Implicit** | 003 § M3 버그(strong params name/version/active vs 실제 status/version_code) 이전 시점에 수정 필요 |

**현 사용자 컨트롤러 중 GDPR 관련 2개** (admin이 아니지만 컴플라이언스 흐름):

| 컨트롤러 | 액션 | In Scope cover? | 비고 |
|---------|------|----------------|------|
| `consents_controller.rb` | 4 (new/create/show/update) | **Implicit** (4 services 또는 5 API) | 컴플라이언스 모델 이전이 명시되지 않음(W1) |
| `deletion_requests_controller.rb` | 3 (new/create/show) | **Implicit** | 7일 SLA + DeletionProcessor cascade 이전 명시 부재 |

**총평**: 13 컨트롤러 + admin 5 컨트롤러 = 18 컨트롤러를 In Scope 5·7이 묵시적으로 cover하나, **GDPR 흐름과 admin auth 분리가 별도 항목으로 격상**되지 않으면 Phase A에서 누락될 위험. 특히 `Compliance::DeletionProcessor` 134 LOC는 D1 트랜잭션 부재(004 § R12)로 인해 saga 패턴 재설계가 필요하며 이는 단순 "TS 1:1 이식"이 아니다.

### G. 항목 간 의존성·우선순위

Brief는 의존 그래프를 명시적으로 제공하지 않는다. 추정 가능한 의존 트리:

```
1 (CF 인프라)
 ├─ 2 (도메인 + TLS)
 ├─ 3 (DB 스키마)
 │    └─ 4 (services 이식)
 │         ├─ 5 (API 레이어)
 │         │    ├─ 6 (인증·세션)
 │         │    │    └─ 9 (결제) ← 6 + 5 + 3
 │         │    └─ 11 (모바일 통합) ← 5 + 6 + 9
 │         └─ 7 (Admin UI) ← 4 + 5 + 6
 │              └─ [admin auth 분리] ← 미명시
 ├─ 8 (테스트 재작성) ← 4·5와 병행
 └─ 10 (CI/CD) ← 1·2와 함께 초기

13 (모니터링) ← 1 이후 즉시
12 (Rails archive) ← 5·6·7·9·11 모두 검증 후
```

**평가**: 13개 항목 간 의존이 위처럼 단방향 트리이며, Brief의 Phase A/B/C 분류와 정합된다(A: 1·2·3·4·5·6·9·10·11·13, B: 7, C: 12). 다만 **항목 단위 의존 트리 명시가 Brief에 없어** scope/makeplan이 같은 작업을 다시 도출해야 한다. 본 critique의 위 트리를 Brief에 옮겨 적으면 충분.

**우선순위**: longevity/sustainability/cutover_safety 우선이라면 1·3·4·8(도메인 정합·테스트)·12(archive)가 최우선. 운영 안정 위해 13(모니터링)과 누락된 보안 횡단(W4)도 동급 우선.

## Recommendations for Brief Revision

| # | Recommendation | Priority |
|---|----------------|----------|
| R1 | **In Scope에 GDPR/컴플라이언스 항목 신설** (consent/deletion_request/audit_log/alert 4종 + DeletionProcessor 134 LOC saga 패턴 이전 + PIPA 국외 이전 동의). W1·M2·M3 통합. | **High** |
| R2 | **In Scope 6(인증)을 분해**: (a) 일반 user 인증·세션(KV) (b) admin 인증 분리(역할 모델 결정) (c) 모바일 JWT 라이프사이클 (d) CSRF 재구현. W2·M6·M9 통합. | **High** |
| R3 | **In Scope에 보안 횡단 항목 신설** (CORS/CSP/HSTS/X-Frame/security headers/Hono rate limit/CF Turnstile 검토). W4 대응. | **High** |
| R4 | **In Scope 9(결제)를 7단계로 풀어 명시** (initiate/authorize/confirm/webhook/cancel/refund/receipt) + 각 단계의 phase 내/외 결정. W5·D 대응. | **High** |
| R5 | **In Scope 11(모바일 통합)을 5 sub-items로 분해** + Decision 추가 "API contract = OpenAPI 3.1 + openapi-typescript + openapi-generator-dart"(또는 동등안). W6·E 대응. | **High** |
| R6 | **In Scope 1을 분리**: 1a CF 인프라 셋업 / 1b Secrets 관리(Wrangler secrets, GH Actions Secrets, env mapping table, 회전 절차). W3 대응. M5도 함께 정리(R2 용도 결정). | **Medium** |
| R7 | **In Scope 13을 분리**: 13a 모니터링·알림 채널·에러 임계 / 13b 로깅 표준(JSON structured + request_id + PII 필터). W8·M1·M10 통합. | **Medium** |
| R8 | **Brief에 Dependency Map 섹션 추가** (위 § G 트리). scope/makeplan 단계가 이 그래프 위에서 사이클 분해. W11 대응. | **Medium** |
| R9 | **Decision 추가 — 운영 횡단 4종**: i18n(한국어 single locale), API envelope, 백업·DR 정책, 트랜잭션 경계(D1 batch + saga). W7·W9·W10·M7 통합. | **Medium** |
| R10 | **Out of Scope #6 좁히기**: "새 도메인 기능 추가 = 새 검사/콘텐츠 추가, 단 GDPR/admin/security 같은 컴플라이언스 횡단은 In Scope에 포함"으로 명시. § B Risk 대응. | **Low** |

## References

| Resource | Path/URL | Relevance |
|----------|----------|-----------|
| Brief 001 | `/Users/kampikrein/A/personality/docs/6_backend/02_cf_workers_rebuild/001_Brief_cf_workers_rebuild.md` | 비평 대상 |
| Research 010 | `/Users/kampikrein/A/personality/docs/6_backend/01_cloudflare_migration_research/010_Research_cloudflare_migration.md` | 결정의 근거 |
| Rails inventory 003 | `/Users/kampikrein/A/personality/docs/6_backend/01_cloudflare_migration_research/003_Agent_current_rails_assets.md` | 자산 정량화 |
| 결제 통합 매트릭스 | `/Users/kampikrein/A/personality/docs/6_backend/01_cloudflare_migration_research/005_Agent_payment_integration.md` | 결제 흐름 (D 분석) |
| Rails admin base | `/Users/kampikrein/A/personality/server/app/controllers/admin/base_controller.rb` | W2 evidence (Basic Auth + ENV) |
| Rails admin dashboard | `/Users/kampikrein/A/personality/server/app/controllers/admin/dashboard_controller.rb` | F 평가 (raw SQL aggregate) |
| Rails admin alerts/audit/qsets | `/Users/kampikrein/A/personality/server/app/controllers/admin/{alerts,audit_logs,question_sets}_controller.rb` | F 평가 |
| GDPR 모델 | `/Users/kampikrein/A/personality/server/app/models/{consent,deletion_request,audit_log,alert}.rb` | W1·M2·M3 evidence |
| DeletionProcessor | `/Users/kampikrein/A/personality/server/app/services/compliance/deletion_processor.rb` | 134 LOC cascade — D1 saga 필요 |
| Application controller | `/Users/kampikrein/A/personality/server/app/controllers/application_controller.rb` | M9 evidence (cookie session implicit) |
| CSP initializer | `/Users/kampikrein/A/personality/server/config/initializers/content_security_policy.rb` | W4 evidence (전체 주석 처리) |
| Routes | `/Users/kampikrein/A/personality/server/config/routes.rb` | 17 HTML 라우트 (admin 4 + user 13) |
| shared/api-schema | `/Users/kampikrein/A/personality/shared/api-schema/` | E evidence (빈 placeholder) |
| shared README | `/Users/kampikrein/A/personality/shared/README.md` | E evidence |
| Mobile lib | `/Users/kampikrein/A/personality/mobile/lib/` | E evidence (HTTP 클라이언트 0) |
| en.yml locale | `/Users/kampikrein/A/personality/server/config/locales/en.yml` | W9 evidence (placeholder만) |
| ResultsController | `/Users/kampikrein/A/personality/server/app/controllers/results_controller.rb` | M7 evidence (8단계 inline transaction) |

## Communication Log

| # | Direction | Peer | Summary | Stage |
|---|-----------|------|---------|-------|
| 1 | → feasibility critique | — | In Scope 9(결제)의 7단계 분해는 feasibility(MAN-WEEK 추정)에도 영향. 환불·정산을 phase 내로 두면 +2-3 MW. | Findings 완료 |
| 2 | → risk-coverage critique | — | W1(GDPR), W2(admin auth), W4(보안 횡단)는 리스크 매트릭스에 직접 추가 가능 영역. 008의 13 리스크 외 신규 리스크 카테고리. | Findings 완료 |
| 3 | → next-step critique | — | W11(Dependency map) + R8은 scope/makeplan 단계의 cycle 분해 입력. Brief가 이를 명시하지 않으면 scope이 재발견 비용 발생. | Findings 완료 |
| 4 | → cutover-safety critique | — | W13(Phase C trigger 정량화), R9(트랜잭션 경계 saga)은 cutover safety의 "검증 후 다음" 기준에 직결. | Findings 완료 |
