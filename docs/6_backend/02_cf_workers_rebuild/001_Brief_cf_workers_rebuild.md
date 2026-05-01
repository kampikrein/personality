---
id: "001"
type: brief
title: "Cloudflare Workers + Hono + D1 전면 리빌딩"
created: 2026-04-28
revised: 2026-04-28
status: completed
quality_profile: standard
priority_dimensions: [longevity, sustainability, cutover_safety, compliance, security]
deep_critique: true
critique_docs: ["002", "003", "004", "005"]
critique_synthesis: "006"
traces_research: "../01_cloudflare_migration_research/010_Research_cloudflare_migration.md"
decision_basis: "사용자 결정: Full Migration 선택 (연구 010의 default Partial 권고 대신)"
summary: >
  사용자가 Full Migration 시나리오를 선택했다. 현 Rails 8 + SQLite + Hotwire
  백엔드를 Cloudflare Workers + Hono + D1 + R2 + KV 스택으로 전면 재작성한다.
  TypeScript 단일 언어로 통일, 모바일 API 신설, Hono SSR로 admin 대체,
  Toss 우선 결제 통합. Rails 코드는 archive로 보존(cutover 안전). 본 Brief는
  결정 정리 Brief — 향후 모든 작업의 alignment anchor. **Deep Critique 반영본**
  — Critical 4 + Major 9 발견을 통합하여 In Scope 19개·Decision 15개로 확장.
keywords: [cloudflare, workers, hono, d1, rails-rebuild, full-migration, typescript, drizzle, cutover, betterauth, cloudflare-access, gdpr, security-baseline]
---

# Cloudflare Workers + Hono + D1 전면 리빌딩

## Intent

본 연구 [`010_Research_cloudflare_migration.md`](../01_cloudflare_migration_research/010_Research_cloudflare_migration.md)의 결과를 바탕으로, **사용자가 Full Migration 시나리오를 선택**했다. 현 Rails 8 + SQLite + Hotwire 백엔드를 **Cloudflare Workers + Hono + D1** 스택으로 전면 재작성한다.

선택의 함의:
- **단일 언어 통일** (TypeScript) — Ruby 폐기, Flutter는 그대로(Dart)
- **단일 인프라 통일** (Cloudflare 생태계)
- **Hotwire admin 폐기**, 새 admin UI 구축 (Hono SSR 권고)
- **모바일 API 신설** (현재 모바일이 서버를 사용하지 않음 — Greenfield)
- **결제 통합** (한국 우선: Toss → PortOne)
- **Rails 코드 archive 보존** (cutover 안전, 비상 회귀 가능)

본 Brief는 **결정 정리 Brief** — 향후 모든 scope/research/plan/implementation 단계의 alignment anchor가 된다. 결정 사항을 다시 ambiguity로 열지 않는다.

## Context

### 본 결정의 근거 (연구 결과 010 참조)

| 사실 | 함의 |
|------|------|
| 시스템이 Greenfield에 매우 가까움 | production data 0, API 0, mobile 미연결, Solid* 미사용, 결제 0 → Full의 진입 비용이 Brief 가정보다 낮음 |
| Hotwire admin이 2 템플릿에 한정 | 전면 재작성 부담 가벼움 |
| 핵심 도메인 = 1,850 LOC 순수 services | TypeScript 1:1 이식 가능 |
| MAN-WEEK 추정 | Full 30.5 MW (Stay 6.5 MW 대비 +24 MW) |
| 운영비 격차 | Low/Medium 시나리오에서는 노이즈 (CF가 약간 우위) |

### 본 결정의 떠안는 리스크 (연구 010 § Risk Matrix)

사용자가 명시적으로 수용:
- **R1**: 한국 ISP Seoul PoP 라우팅 불일치 (구조적, 600ms+ 패널티 가능)
- **R2**: D1 10GB/DB 하드캡 (70K MAU 추정 도달 → 샤딩)
- **R3**: D1 read replication 1년+ public beta
- **R5**: Stripe Korea 가맹점 부재 (글로벌 결제 단계적)
- **R7**: D1 단일 스레드 throughput 천장
- **R11**: CF 2025년 outage 3건 이력
- **R12**: D1 interactive transaction 부재
- 기타 6개 (R4, R6, R8, R9, R10, R13)

**리스크 회피책**: 연구 010 권고에 따라 Stay/Partial로 회귀 가능성을 위해 **Rails 코드 archive 보존** 필수.

### 현 시스템 인벤토리 (003_Agent_current_rails_assets.md 기준)

- 5,448 Ruby LOC + 1,788 ERB + 340 JS + 2,641 spec LOC
- 15 모델, 13 컨트롤러 + admin, 20 services (1,850 LOC), 27 ERB, 8 Stimulus, 18 RSpec
- 14 DB 테이블, 9 JSON 컬럼, 14 FK
- production DB **부재** (즉, 데이터 마이그레이션 ≈ 0)
- 모바일 ↔ 서버 API **미연결**
- 결제 **미구현**

## Boundaries

### In Scope

| # | Item | Description |
|---|------|-------------|
| 1 | **CF 인프라 셋업** | CF account, Workers project, D1 DB, R2 bucket, KV namespace, Wrangler 구성, GitHub repo 연동, secrets 관리. **D1 자동 export → R2 보관 (주 1회 이상)** 백업 정책 포함. (**보강 — M14**) |
| 2 | **도메인 + TLS** | Custom Domain 등록 (예: `api.{도메인}` for mobile, `admin.{도메인}` for admin), Workers Routes 매핑, 자동 TLS. **Cookie 도메인·SameSite 전략은 scope 단계에서 단일 도메인+path 분리 옵션과 비교 후 확정 (Med2)**. |
| 3 | **DB 스키마 (Drizzle)** | 14 테이블 → Drizzle schema, migrations, JSON 컬럼 매핑, FK 제약, seed (PersonalityType × 16). **drizzle-kit ↔ wrangler d1 migrations 통합 패턴은 scope에서 확정 (M1)**. |
| 4 | **도메인 services 이식** | 1,850 LOC services → TypeScript 포트 (scoring/tone-filter/restricted-terms/insights). 테스트(Vitest) 동행. **ResultsController scoring 8단계 transaction은 D1 interactive transaction 부재로 saga 패턴(batch 분할 + 보상) 또는 Durable Object 채택 — scope에서 결정 (M3)**. |
| 5 | **API 레이어 (Hono routes)** | 13 컨트롤러 + admin → Hono router. **새로 모바일 JSON API 신설** (현재 0 endpoint). 기존 HTML 라우트는 admin 영역에서 SSR로 재현 또는 폐기. |
| 6 | **인증·세션 (User 인증)** | `User.encrypts :email, deterministic: true` → Web Crypto API AES-GCM 수동 구현 (login-by-email 호환). 세션은 KV 또는 D1 기반. **암호화 키 별도 관리 (Wrangler secret + 외부 백업) + rotation 정책 (C3-W3)**. **Admin 인증과 분리 — In Scope 19 참조**. |
| 7 | **Admin UI 대체** | Hotwire 2 템플릿 + 8 Stimulus → **Hono SSR + 최소 vanilla JS**. **Hotwire Turbo Frame 시맨틱(progressive enhancement, optimistic update)은 1:1 이식하지 않고 full reload 또는 직접 fetch 분기로 단순화 — 사용자 행동 변화 수용 (C2)**. **Hono+HTMX 패턴(Hotwire 동등 DX) vs Astro 6(2026-01 CF 인수, workerd 구동) vs Hono SSR vanilla 비교는 scope에서 (M11)**. |
| 8 | **테스트 재작성** | 18 RSpec 파일 (2,641 LOC) → Vitest **+ `@cloudflare/vitest-pool-workers`** (D1 binding 통합 테스트 표준 — M10). 도메인 동등성 보장. TDD 흐름 유지. |
| 9 | **결제 통합 — 한국 우선 (7단계 cover)** **(C4 확장)** | <br>9.1 결제 intent 생성 + 클라이언트 결제창 호스팅 (Toss Widget)<br>9.2 결제 confirm + DB 기록<br>9.3 webhook 검증 (HMAC-SHA256, **Toss 공식 docs 1차 출처 재확인 필수 — M2**) + idempotency (D1 `UNIQUE(event_id)`)<br>9.4 환불·취소 처리<br>9.5 결제 실패·재시도 정책<br>9.6 영수증·정산·세금 처리 (간이 또는 위임)<br>9.7 결제 흐름 E2E 테스트 (Toss 테스트 모드) |
| 10 | **CI/CD** | GitHub Actions + Wrangler deploy. Production / Preview(PR 단위) / Staging 환경 분리. **CF Workers Gradual Deployments (Version Overrides)는 scope 위임 (Med3)**. |
| 11 | **모바일 통합** | Flutter 앱이 신규 API 호출 시작. shared/api-schema/ 정의 (**OpenAPI 3 + 코드 생성 도구 — Decision 14 참조**). 인증·결제 흐름 검증. |
| 12 | **Rails 폐기 (Cutover)** | server/ 디렉터리 → archive/rails-server/로 이동. **삭제 금지** (회귀 안전). 회귀 조건 발생 시 archive 활성화 가능. **단순 보존만으론 안전망 미흡 — In Scope 14·15 참조**. |
| 13 | **모니터링·로깅·백업** **(보강)** | Workers Analytics + 콘솔 로그 + 선택적 CF Logpush. 에러 알림 채널 연결. **D1 백업·복원 절차** (D1 export → R2, 주 1회 이상, 복원 테스트 분기 1회) **(M14)**. **로깅 표준 (structured logging, request ID, sampling)** 정의. |
| **14** | **archive smoke test 절차** **(C3-W1 신규)** | 월 1회 또는 분기 1회 archive Rails를 별도 환경에서 가동 검증 — Ruby 버전·gem·SQLite 호환성 부패 방지. archive 활성화 가능성을 실측으로 보장. |
| **15** | **Phase rollback 절차** **(C3-W2 신규)** | Phase A 가동 후 Flutter 사용자 의존 시점부터의 비가역 진입을 rollback 절차로 완화 — 모바일 client fallback 경로, admin URL 회귀, D1 → SQLite export 변환, encryption key Rails ↔ Workers 호환 절차 정의. |
| **16** | **GDPR / PIPA 컴플라이언스 흐름** **(M4 신규)** | 16.1 동의(consent) 수집·철회 흐름 (현 `consent` 모델 이전)<br>16.2 계정 삭제 요청·처리 (현 `deletion_request` 모델 이전)<br>16.3 감사 로그 (현 `audit_log` 모델 이전)<br>16.4 개인정보 국외 이전 고지·동의 (CF 글로벌 인프라 사용)<br>16.5 14세 미만 사용자 처리 (성격 검사 서비스 — 어린이 사용 가능성 대응) |
| **17** | **Secrets·환경변수 운영 모델** **(M6 신규)** | ≥7개 시크릿(D1 키, KV, R2, Toss API, encryption key, JWT secret, webhook secret 등) 관리. Wrangler secret + GitHub Actions secret + 회전 정책 + 접근 통제. |
| **18** | **보안 baseline** **(M7 신규)** | CORS (api ↔ Flutter, admin ↔ admin), CSP (admin SSR 응답), HSTS (양 도메인), Rate limiting (per-IP, per-user — Workers 미들웨어 또는 Durable Object), CSRF (Hono CSRF origin-check 기반 — per-session token 부재 사실 명시), CF의 무료 WAF 활성화. |
| **19** | **Admin 인증 분리 + 운영 baseline** **(M5 + M13 신규)** | **Admin 인증 = Cloudflare Access (SSO 위임)** — 1인 운영자에게 매력적, CF 단일 의존 강화. **User 인증 = BetterAuth** (D1 + KV). 두 도메인 인증 분리. **운영 baseline**: 단순 runbook + 비상 연락처 + CF 계정 접근 장애 시 절차. |

### Out of Scope

| # | Item | Reason |
|---|------|--------|
| 1 | Hetzner/Vercel/AWS 등 대체 인프라 | CF로 결정됨 |
| 2 | 외부 DB (Hyperdrive + PostgreSQL) | D1 사용 결정 — 미래 옵션 (D1 천장 도달 시 재검토) |
| 3 | Stay 또는 Partial migration | Full 결정됨 |
| 4 | Stripe 결제 (글로벌) | Stripe Korea 부재로 단계적 — 한국 우선 후 별도 phase |
| 5 | 모바일 앱 (Flutter) 아키텍처 변경 | 별도 토픽 (서버 API 계약만 공통) |
| 6 | 새 도메인 기능 추가 | 마이그 자체에 집중 — 기능 추가는 별도 토픽 |
| 7 | Next.js / SPA 풀 도입 | Hono SSR로 충분 결정 |
| 8 | 데이터 마이그레이션 | production DB 부재 → seed 재생성으로 충분 |

## Decisions

| # | Decision | Chosen | Rationale | Trade-off | Alternatives |
|---|----------|--------|-----------|-----------|--------------|
| 1 | 마이그레이션 시나리오 | **Full Migration** | 사용자 결정 (연구 010 default Partial 대신). 장기 단일 코드베이스·단일 언어·단일 인프라 가치 | Partial 대비 +16 MW 일회성, 13 리스크 모두 수용 | Stay/Partial 기각 — 사용자 결정 |
| 2 | 인프라 | **CF Workers + Hono + D1 + R2 + KV** | 연구 P2에서 GA 성숙도 확인. Rails 주변 컴포넌트 1:1 매핑 가능 | 벤더 락인 심화 (사용자 수용) | Hetzner/Vercel/외부 DB 기각 — 사용자 결정 |
| 3 | ORM | **Drizzle ORM** | D1 공식 권장, TypeScript-first, 타입 안전 마이그, 가벼움. **drizzle-kit ↔ wrangler d1 migrations 통합 패턴은 scope에서 확정 (M1 비평)**. | Prisma보다 생태계 작음 | Prisma 기각 (D1 호환성 약함, 무거움), Kysely 기각 (마이그 도구 부재), 직접 SQL 기각 (타입 안전성 손실) |
| 4 | Admin UI 대체 전략 | **Hono SSR + vanilla JS** (잠정 — scope에서 Hono+HTMX·Astro 6과 비교 후 확정) | 별도 SPA 빌드 회피, 단일 코드베이스. **Hotwire Turbo Frame 1:1 동등 불가 — full reload 또는 직접 fetch 분기로 단순화 (C2 비평)**. | Hotwire의 progressive enhancement·optimistic update 손실, 사용자 행동 변화 수용 | **Hono+HTMX (Hotwire DX와 근접, Hono 창시자 추천)**, **Astro 6 (2026-01 CF 인수, workerd 구동, GA 어댑터)** — 둘 다 scope에서 명시 비교 후 결정. React SPA 기각 (두 빌드 시스템), Next.js 기각 (Vercel 종속). **Astro 기각 사유 갱신 (이전 "오버엔지니어링" → "scope 결정")**. |
| 5 | 결제 PG 1순위 | **Toss Payments** | 연구 P3에서 50 LOC 가장 가벼움. Web Crypto API HMAC-SHA256. 한국 표준. | PortOne의 다중 PG 추상화 미사용 | PortOne 기각 (이중 추상화), Stripe 기각 (Korea 부재), KCP 기각 (직접 통합 부담) |
| 6 | 결제 PG 2순위 | **PortOne 검토** | Toss 외 PG(KCP/이니시스 등) 추가 시 PortOne의 멀티 PG 추상화 활용 | Toss로 충분하면 도입 안 함 | KCP 직접 기각, 다중 SDK 기각 |
| 7 | 테스트 도구 | **Vitest + `@cloudflare/vitest-pool-workers`** **(M10 명시 추가)** | TypeScript-first, Jest 호환, Workers + D1 binding 통합 테스트 표준. Hono 공식 예제 패턴. | bun test보다 성숙 | bun test 기각 (Workers 호환 검증 추가 필요), Jest 기각 (느림), Playwright는 E2E 보완용 (별도 phase) |
| 8 | 인증 방식 **(C1 갱신 — Lucia 사실 오류 정정)** | **BetterAuth (User 인증) + Cloudflare Access (Admin 인증) hybrid** | BetterAuth는 Workers·D1·KV 호환 활발 개발. Cloudflare Access는 admin SSO 위임으로 1인 운영자에게 매력적, CF 단일 의존 강화. User.encrypts deterministic은 직접 구현 + 키 관리·rotation 정책 (In Scope 6, 17 참조). | OAuth는 단계적 추가, 두 인증 도메인 격리 운영 부담 | **Lucia 기각 (2024-Q4~2025-03 sunset 확정 — 메인테이너가 BetterAuth로 redirect 권장)**. Auth.js 기각 (Workers 호환 약함). Supabase/Clerk 기각 (외부 의존, CF 단일 의존 약화). |
| 9 | Cutover 전략 | **Phased (단계적 폐기)** | (1) CF 인프라 + 모바일 API 가동 → (2) admin Hono SSR 가동 → (3) Rails 폐기. 각 단계 검증 후 다음. | Big bang 대비 시간 증가 | Big bang cutover 기각 (회귀 어려움) |
| 10 | Rails 코드 처리 | **archive/rails-server/로 보존** | 삭제 시 비상 회귀 불가능. archive는 git 추적 유지. | 디스크 공간 약간 차지 (무시 가능) | 삭제 기각 (비가역), 별 repo 분리 기각 (이력 단절) |
| 11 | 환경 분리 | **Production / Preview / Staging** | wrangler 환경별 deploy. PR 단위 preview URL 자동. | 무료 티어 내 처리 가능 | 단일 환경 기각 (PR 검증 어려움) |
| 12 | 도메인 구조 | **`api.<도메인>` (모바일 API) + `admin.<도메인>` (admin UI)** | 두 라우트 분리로 관심사 분리, 각각 다른 Worker 가능 | 인증 도메인 간 공유 처리 필요 | 단일 도메인 + path 구분 기각 (admin 보호 약함) |
| 13 | 글로벌 결제 | **연기** (Stripe Korea 또는 해외 법인 시점까지) | 본 연구 결정 5 업데이트: "동시 병행" → "단계적 병행" | 단기 글로벌 결제 불가 | 즉시 Stripe 통합 기각 (Korea 가맹점 부재) |
| **14** | **API 스키마·codegen 도구** **(M8 신규)** | **OpenAPI 3 + 코드 생성 (Hono RPC 또는 별도 codegen으로 Flutter Dart 클라이언트 자동 생성)** | shared/api-schema/는 placeholder — 표준 스키마 도구가 없으면 Flutter ↔ Workers 계약이 ad-hoc 결정으로 굳어짐. | 스키마-코드 동기화 운영 부담 | 직접 Dart 핸드코딩 기각 (drift 위험), GraphQL 기각 (모바일 단일 클라이언트엔 오버킬) |
| **15** | **API 응답 envelope·error code 표준** **(M9 신규)** | **`{ success, data, error: { code, message, details } }` 일관 응답 + 에러 코드 카탈로그** | Hono router 전역 미들웨어로 강제. Flutter 클라이언트가 한 곳에서 처리. | 약간의 응답 크기 증가 (무시 가능) | RFC 7807 Problem Details 기각 (모바일 클라이언트 적합성 약함) |

## ⚠️ Critical Review Request

본 결정은 본 연구 010의 default 권고(**Partial**, 신뢰도 70-75%)와 다른 선택입니다. 사용자가 5개 가정을 자가 진단한 결과로서 Full을 선택한 것으로 받아들이지만, 다음 사항을 향후 진행 중 모니터링하기를 권장합니다:

- **Risk**: 5개 가정 중 일부가 미래에 깨질 경우 (예: 1년 내 100K MAU 도달, 글로벌 비중 ↑, TS 친숙 가정 약화), Full의 비용이 Stay/Partial로 회귀하기 어려운 위치에 있을 수 있음.
- Why Full is acceptable: 사용자가 의식적 선택, 단일 코드베이스/언어/인프라의 장기 운영 가치, archive 보존으로 회귀 비상구 확보.
- Mitigation: 6개월·12개월 시점에 5개 가정을 재검증하는 retrospective. **Calendar reminder 또는 GitHub issue를 통해 자동 트리거 — Brief 작성 시 등록 (Med8)**. 가정 깨짐 시 Stay/Partial 회귀 옵션은 archive smoke test (In Scope 14)로 실측 보장.
- **→ 이 진행 결정에 동의하는 것을 전제로 진행. 동의하지 않는다면 Brief 갱신 요청.**

### 13 R-risks Mitigation 매핑 (M12 보강)

본 연구 010의 13개 risk 각각의 처리 방식 — Brief 보강으로 전환:

| Risk | 처리 방식 | 위치 |
|------|---------|------|
| R1 한국 ISP routing | 수용 + 모니터링 | Constraint |
| R2 D1 10GB 하드캡 | 80% 도달 alert + 외부 PG (Hyperdrive) 옵션 재검토 | Constraint + In Scope 1 |
| R3 D1 read replication beta | 수용 + 캐시 레이어(KV) 활용 | scope 위임 |
| R4 Korean 메인스트림 부재 | 수용 (인력 1인 가정 정합) | Constraint |
| R5 Stripe Korea 부재 | Decision 13 (단계적 병행) | Decision 13 |
| R6 벤더 락인 | 수용 (사용자 명시) + D1→SQLite export 백업 | In Scope 13 |
| R7 D1 단일 스레드 | 인덱스 튜닝 + 무거운 쿼리 분할 | scope/implementation |
| R8 콜드 스타트 | 수용 (5ms baseline 무시 가능) | Constraint |
| R9 DX gap | wrangler dev + miniflare baseline 정의 | Med6 → scope 위임 |
| R10 1인 개발자 부담 | **In Scope 19 운영 baseline (M13)** | In Scope 19 |
| R11 CF outage | WAF + 재시도 + 외부 모니터링(uptime-kuma 등) | scope 위임 |
| R12 D1 interactive transaction 부재 | **In Scope 4 saga 패턴 결정 (M3)** | In Scope 4 |
| R13 개인정보 국외 이전 | **In Scope 16 GDPR/PIPA 흐름 (M4)** | In Scope 16 |

## Open Questions

없음 — 모든 핵심 결정은 위 Decisions 또는 Out of Scope로 정리됨. 구현 단계 세부 (라이브러리 버전, 폴더 구조, 테스트 패턴 등)는 `/scope` + `/makeplan` 단계에서 확정.

## Constraints

- **Rails archive 보존 필수** (`archive/rails-server/`) — 삭제 금지, 6개월 이상 유지. **archive smoke test는 In Scope 14에 정기 검증 포함 (C3-W1)**.
- **단계적 cutover + Phase rollback 절차 정의** — big bang 금지. **Phase A 가동 시점부터의 비가역 진입은 In Scope 15의 rollback 절차로 완화 (C3-W2)**.
- **한국 사용자 우선** — Toss/PortOne, Korean 시장 컨텍스트 적합성 우선
- **글로벌 결제 단계적** — 본 phase에서 Stripe 통합 안 함
- **벤더 락인 수용** (사용자 명시) — 회피 전략은 본 phase 범위 밖. 단 D1→SQLite export 백업은 유지 (R6).
- **단일 또는 매우 작은 개발팀** 가정 — 가독성·유지보수성 우선. **운영 baseline은 In Scope 19 (M13)**.
- **TypeScript 단일 언어** — 새 코드는 모두 TS, JS 사용 최소화 (강제 타입 안전)
- **장기 운영 = 2026-04 ~ 2029-04** (1-3년)
- **트래픽 가정 = 1년 내 수만 MAU 이내** (D1 10GB 천장 전). **D1 80% 도달 시 alert + 외부 PG(Hyperdrive) 옵션 재검토 트리거 (R2)**.
- **암호화 키 별도 관리** — Wrangler secret + 외부 백업, rotation 정책. **키 분실 = 모든 user lookup 불가 = 단일 실패점이므로 다중 백업 필수 (C3-W3)**.
- **30.5 MW 비용 초과 트리거** — 50% 초과 (= 45 MW) 시 Brief 재검토 또는 scope 분할 결정 (Med7).
- **6개월·12개월 retrospective** — 가정 5개 재검증 calendar reminder 등록 필수 (Med8).
- **D1 백업 빈도** — D1 export → R2 주 1회 이상, 복원 테스트 분기 1회 (M14).

## Exit Criteria (본 Brief의 완결 조건)

- [x] 사용자 Full Migration 결정 받음
- [x] 본 연구 010의 자산 인벤토리 + 리스크 매트릭스 traces
- [x] In Scope 13개 정의
- [x] Out of Scope 8개로 scope creep 차단
- [x] Decisions 13개 (사용자 결정 1 + autonomous 12) 명시
- [x] Critical Review Request로 가정 모니터링 명시
- [x] Quality Profile + Priority Dimensions (longevity, sustainability, cutover_safety) 설정
- [x] Ideal Criteria (아래)
- [x] Model Anchors (아래)

## Ideal Criteria

**Quality Profile**: Standard · **Priority Dimensions**: Longevity, Sustainability, **Cutover Safety**
(Cutover Safety가 추가되어 Robustness/Completeness 차원 criteria 1단계 상향)

| # | Criterion | References (In Scope #) | Type | Dimension |
|---|-----------|------------------------|------|-----------|
| 1 | CF Workers + Hono + D1 + R2 + KV 인프라가 Wrangler로 deploy 되어 작동하는가 | 1 | assertion | Function |
| 2 | Custom Domain + 자동 TLS가 활성화되어 외부에서 접근 가능한가 | 2 | assertion | Function |
| 3 | 14 DB 테이블이 Drizzle schema로 정의되고 D1에 마이그됐는가 | 3 | assertion | Function |
| 4 | 9 JSON 컬럼이 D1 JSON1 함수로 동등하게 동작하는가 | 3 | assertion | Edge |
| 5 | 도메인 services 1,850 LOC가 TypeScript로 이식되고 동등성 테스트 통과하는가 | 4 | assertion | Function |
| 6 | 모바일 API 엔드포인트가 신설되고 Flutter 앱이 호출 가능한가 | 5, 11 | assertion | Function |
| 7 | User.encrypts deterministic email이 AES-GCM 수동 구현으로 login-by-email 호환되는가 | 6 | assertion | Edge |
| 8 | Admin UI(Hono SSR)가 기존 Hotwire admin과 기능 동등한가 | 7 | assertion | Completeness |
| 9 | RSpec 테스트가 Vitest로 재작성되고 도메인 동등성을 검증하는가 | 8 | assertion | Function |
| 10 | Toss webhook(HMAC-SHA256)이 D1 idempotency와 함께 동작하는가 | 9 | assertion | Function |
| 11 | GitHub Actions + Wrangler로 production/preview/staging 자동 배포되는가 | 10 | assertion | Function |
| 12 | Rails 코드가 `archive/rails-server/`로 이동되고 git 이력 유지되는가 (삭제 X) | 12 | assertion | **Cutover Safety / Robustness** |
| 13 | Rails 폐기 후에도 archive 활성화로 Stay/Partial 회귀 가능한가 (가능성 보존) | 12 | directional | **Cutover Safety / Robustness** |
| 14 | Workers Analytics + 로그가 운영 가시성을 제공하는가 | 13 | assertion | Robustness |
| 15 | 단계적 cutover 3단계(인프라 → admin → 폐기)가 각각 검증 후 진행됐는가 | 9 (decision) | assertion | **Cutover Safety / Completeness** |
| 16 | 1-3년 운영 가정에서 D1 10GB 천장 도달 모니터링이 활성화됐는가 | constraint | directional | Longevity |
| 17 | archive smoke test가 정기적으로 실행되어 회귀 가능성이 실측 보장됐는가 | 14 | assertion | **Cutover Safety** |
| 18 | Phase rollback 절차가 문서화되고 실제 dry-run으로 검증됐는가 | 15 | assertion | **Cutover Safety** |
| 19 | GDPR/PIPA 흐름(consent·deletion·audit·국외 이전·14세 미만) 5개가 모두 구현됐는가 | 16 | assertion | **Compliance** |
| 20 | 7개+ secrets가 Wrangler/GitHub로 분리 관리되고 평문 커밋이 없는가 | 17 | assertion | **Security** |
| 21 | 보안 baseline 5개(CORS·CSP·HSTS·rate limit·WAF) 모두 활성화됐는가 | 18 | assertion | **Security** |
| 22 | Admin 인증(Cloudflare Access)과 User 인증(BetterAuth)이 도메인별로 분리되어 동작하는가 | 19 | assertion | **Security** |
| 23 | 1인 운영 baseline(runbook + 비상 연락처 + CF 접근 장애 절차)이 문서화됐는가 | 19 | assertion | Robustness |
| 24 | Decision 8 인증이 BetterAuth + Cloudflare Access hybrid로 구현됐는가 (Lucia 사용 0 확인) | Decision 8 | assertion | Function |
| 25 | Hono CSRF + Hotwire Turbo Frame 시맨틱 차이가 행동 변화로 수용되어 사용자 흐름이 동작하는가 | 7 | directional | UX |
| 26 | 결제 7단계(intent → confirm → webhook → 환불 → 실패 → 영수증 → E2E) 모두 구현됐는가 | 9.1-9.7 | assertion | Function |
| 27 | OpenAPI 3 스키마 + Flutter Dart 클라이언트 자동 생성 도구가 동작하는가 | Decision 14 | assertion | Function |
| 28 | API 응답 envelope·에러 코드 카탈로그가 일관 적용됐는가 | Decision 15 | assertion | Function |
| 29 | 13 R-risks 매핑 표대로 각 리스크에 처리(mitigation/위임) 적용됐는가 | Critical Review | directional | Robustness |
| 30 | 6개월·12개월 retrospective calendar reminder가 등록됐는가 | Critical Review | assertion | Longevity |

## Model Anchors

1. **이 Brief는 결정 정리 Brief이다**. Full Migration이 사용자 결정으로 못박혔다. Stay/Partial 재논의 금지. 진행 중 가정 변동이 발생해도 별도 Brief 갱신 요청 후 처리.

2. **인프라 = CF Workers + Hono + D1 + R2 + KV** (5종 + 필요 시 Queues/Durable Objects). 대체 인프라 검토 금지.

3. **언어 = TypeScript 단일**. 새 코드는 모두 TS. JavaScript 사용은 명시적 사유(라이브러리 호환 등) 시만.

4. **ORM = Drizzle**. Prisma/raw SQL 기각.

5. **Admin UI = Hono SSR + vanilla JS (잠정)**. scope 단계에서 **Hono+HTMX, Astro 6 (2026-01 CF 인수)와 명시 비교 후 확정**. 어느 옵션이든 Hotwire Turbo Frame 시맨틱(progressive enhancement, optimistic update)은 1:1 이식하지 않고 단순화. React SPA / Next.js / Vercel 종속 도입 금지.

6. **결제 = Toss 1순위, PortOne 2순위**. Stripe는 본 phase 제외(Korea 가맹점 부재).

7. **Cutover = 단계적**. 다음 3단계로 진행:
   - Phase A: CF 인프라 + 모바일 API + 결제 가동
   - Phase B: Hono SSR admin 가동
   - Phase C: Rails archive 이동
   각 단계 완료 후 검증 통과 시 다음 단계.

8. **Rails 코드 보존 = 강제**. `archive/rails-server/` 위치, git 이력 유지, 6개월 이상 유지. 삭제 금지.

9. **Domain 분리 = `api.<도메인>` + `admin.<도메인>`**. 인증 토큰은 양 서브도메인 공유 (cookie domain 또는 JWT).

10. **테스트 = Vitest**. 도메인 services 이식 시 RSpec 테스트의 동등 검증을 Vitest로 작성. 새 코드는 TDD 흐름.

11. **DB 한도 모니터링**: D1 10GB 천장 도달 모니터링 알림(80% 도달 시 경고). 도달 시 Brief 갱신하여 외부 PG(Hyperdrive) 옵션 검토.

12. **결제 글로벌 = 단계적**. 본 phase에서 Stripe 통합 금지. 별도 phase: 해외 법인 마련 또는 Stripe Korea 등장 후.

13. **인증 = BetterAuth (User) + Cloudflare Access (Admin) hybrid** (C1 갱신). **Lucia는 sunset됐으므로 사용 금지**. Supabase/Clerk 등 외부 인증 SaaS 의존 금지 (CF 단일 의존 유지). User 인증과 Admin 인증은 도메인별로 분리 운영.

14. **모니터링 = Workers Analytics 우선 + 필요 시 Logpush**. Sentry 같은 외부 APM은 별도 phase.

15. **벤더 락인 회피 전략 = 범위 밖**. 사용자 수용 명시. 다만 데이터 portability(D1 → SQLite export)는 백업 차원에서 유지.

16. **GDPR/PIPA 컴플라이언스는 별도 In Scope 16으로 격상** — implementation 단계의 ad-hoc 결정 금지. consent·deletion_request·audit_log·alert 모델 이전 + 국외 이전 고지 + 14세 미만 처리.

17. **Secrets 운영 = Wrangler secret + GitHub Actions secret + 회전 정책** (In Scope 17). 평문 커밋·하드코딩 금지. 키 분실 = 단일 실패점이므로 외부 백업 필수.

18. **보안 baseline 기본값 명시** (In Scope 18): CORS / CSP / HSTS / Rate limit / WAF 활성화. Hono CSRF는 origin-check 기반(per-session token 부재)이라는 사실을 implementation 시 명시 인지.

19. **Admin 인증 = Cloudflare Access (SSO 위임)**. 1인 운영자에게 매력적 + CF 단일 의존 강화. User 인증(BetterAuth)과 도메인별 분리 운영.

20. **archive 보존 + smoke test 정기 가동** (In Scope 14). 단순 디렉터리 보존만으론 회귀 보장 안 됨 — 월 1회 또는 분기 1회 archive Rails 별도 환경 가동 검증.

21. **Phase rollback 절차 정의 강제** (In Scope 15). Phase A 가동 후 Flutter 사용자 의존 시점부터의 비가역 진입은 rollback 절차로 완화 — 모바일 client fallback, admin URL 회귀, D1 → SQLite export 변환.

## Critique Integration

본 Brief는 **--deep 모드 적용 후 보강본**. 4개 비평 관점이 Critical 4 + Major 14 + Medium 8 발견을 도출 → Critical/Major 13개를 Brief에 직접 통합, Medium 8개는 scope 위임 명시.

원본 비평·종합:
- [`002_Critique_feasibility.md`](./002_Critique_feasibility.md)
- [`003_Critique_scope_balance.md`](./003_Critique_scope_balance.md)
- [`004_Critique_risk.md`](./004_Critique_risk.md)
- [`005_Critique_alternatives.md`](./005_Critique_alternatives.md)
- [`006_Critique_Synthesis.md`](./006_Critique_Synthesis.md)

### 반영 항목 (Critical / Major)

| # | Source | Finding | Severity | Action | Brief 반영 위치 |
|---|--------|---------|----------|--------|---------------|
| C1 | 002 W2 + 005 D8 | **Lucia v3 sunset (사실 오류)** — 두 비평 이중 발견 | Critical | Decision 8 갱신: BetterAuth + Cloudflare Access hybrid | Decision 8 |
| C2 | 002 W1 | Hono CSRF + Hotwire Turbo Frame 1:1 동등 불가 | Critical | In Scope 7 + Decision 4에 행동 변화 수용 명시 | In Scope 7, Decision 4 |
| C3-W1 | 004 W1 | archive 보존만으론 회귀 불가 (호환성 부패) | Critical | 새 In Scope 14 — archive smoke test | In Scope 14 |
| C3-W2 | 004 W2 | Phase rollback 절차 미정의 | Critical | 새 In Scope 15 — Phase rollback | In Scope 15 |
| C3-W3 | 004 W3 | 암호화 키 관리·rotation 부재 | Critical | In Scope 6 보강 + Constraint 추가 | In Scope 6, Constraints |
| C4 | 003 W5 | 결제 In Scope 9가 7단계 중 1단계만 cover | Critical | In Scope 9 → 9.1~9.7 확장 | In Scope 9 |
| M1 | 002 W3 | drizzle-kit ↔ wrangler d1 통합 패턴 미명시 | Major | Decision 3 보강 + scope 위임 | Decision 3, In Scope 3 |
| M2 | 002 W4 | Toss webhook HMAC 1차 출처 재검증 | Major | In Scope 9.3에 명시 | In Scope 9.3 |
| M3 | 002 W7 | scoring saga 패턴 결정 (D1 transaction 부재) | Major | In Scope 4 보강 + R12 매핑 | In Scope 4 |
| M4 | 003 W1 + 004 Major | GDPR/PIPA 컴플라이언스 흐름 In Scope 부재 | Major | 새 In Scope 16 | In Scope 16 |
| M5 | 003 W2 | admin 인증 분리·역할 모델 미정 | Major | In Scope 19 + Decision 8 | In Scope 19 |
| M6 | 003 W3 | secrets/환경변수 운영 모델 부족 | Major | 새 In Scope 17 | In Scope 17 |
| M7 | 003 W4 + 004 Major | 보안 횡단(CORS/CSP/HSTS/rate limit/WAF) 부재 | Major | 새 In Scope 18 | In Scope 18 |
| M8 | 003 W6 | shared/api-schema OpenAPI/codegen 미정 | Major | Decision 14 추가 + In Scope 11 보강 | Decision 14 |
| M9 | 003 W7 | API envelope·error code 표준 부재 | Major | Decision 15 추가 | Decision 15 |
| M10 | 005 D7 | `@cloudflare/vitest-pool-workers` 명시 누락 | Major | Decision 7 + In Scope 8 보강 | Decision 7 |
| M11 | 005 D4 | Astro 6 (CF 인수) + Hono+HTMX 검토 누락 | Major | Decision 4 + In Scope 7 보강 | Decision 4 |
| M12 | 004 §G | 13 R-risks 명시적 mitigation 부재 | Major | Critical Review에 매핑 표 추가 | Critical Review |
| M13 | 004 Major | 1인 개발자 부재 운영 playbook 부재 | Major | In Scope 19 신규 | In Scope 19 |
| M14 | 003 W11 + 004 Major | D1 백업·복원 전략 부재 | Major | In Scope 1, 13 보강 + Constraint | In Scope 1, 13 |

### scope/research 위임 (Medium)

| # | 발견 | 위임처 |
|---|------|--------|
| Med1 | Cutover 순서 B→A→C 검토 | scope (Decision 9 alternatives에 명시) |
| Med2 | Cookie 도메인 vs 단일 도메인+path 분리 | scope (In Scope 2) |
| Med3 | CF Workers Gradual Deployments | implementation 단계 (In Scope 10) |
| Med4 | 트랜잭셔널 이메일 | scope 별도 phase |
| Med5 | PersonalityType seed 콘텐츠 검증 | tarot/psychology 에이전트 |
| Med6 | wrangler dev DX baseline | scope/implementation |
| Med7 | 30.5 MW 비용 초과 트리거 | Constraint에 한 줄 명시됨 |
| Med8 | 가정 monitoring 5개 자동화 | Critical Review에 명시됨 |

### 비평이 검증한 강점 (Brief 유지)

- **In Scope 1·3·4·8 정량 근거 견고** (003 § Strengths)
- **Cutover Safety 별도 priority dimension 격상** (003 § Strengths)
- **Decision 13개와 In Scope 13개 1:1 매핑** (003 § Strengths) — 보강 후 19:15로 비대칭 (의도적, In Scope 14·15·16·17·18·19는 cutover/security/compliance 횡단이라 별도 Decision 없이 운영)

## Next Steps

1. **`/scope`** — 본 Brief를 입력으로 기술 분석 + 파이프라인 체크리스트 생성:
   ```
   /scope cf_workers_rebuild
   ```
   scope이 In Scope 13개를 의존성·우선순위에 따라 사이클로 분해.

2. **선택적 추가 research** (scope 결과 따라):
   - Drizzle ORM + D1 베스트 프랙티스 학습 (필요 시 별도 research)
   - Hono SSR 패턴 (Hotwire admin 동등성 확보 방안)
   - BetterAuth vs Lucia 비교 (인증 라이브러리)
   - 단계적 cutover 체크포인트 정의

3. **첫 implementation 사이클** (scope 후):
   - Phase A 인프라 셋업 (Cloudflare account → Wrangler → D1 → R2 → KV → Custom Domain)
   - Drizzle schema (14 테이블)
   - 도메인 services 이식 첫 모듈 (scoring 또는 tone-filter)
   - TDD로 동등성 검증

## References

| Resource | Path | Relevance |
|----------|------|-----------|
| 본 연구 최종 보고서 | `../01_cloudflare_migration_research/010_Research_cloudflare_migration.md` | Full 결정의 근거 |
| 현 Rails 자산 인벤토리 | `../01_cloudflare_migration_research/003_Agent_current_rails_assets.md` | 이식 대상 정확한 규모 |
| CF 스택 한도·역량 | `../01_cloudflare_migration_research/004_Agent_cloudflare_stack_capabilities.md` | 인프라 제약 |
| 결제 통합 가능성 | `../01_cloudflare_migration_research/005_Agent_payment_integration.md` | Toss/PortOne 통합 패턴 |
| 마이그 비용 모델 | `../01_cloudflare_migration_research/007_Agent_migration_and_operating_cost.md` | 30.5 MW 추정 근거 |
| 리스크 매트릭스 | `../01_cloudflare_migration_research/008_Agent_risk_and_recommendation.md` | 13 리스크 수용 |
| 현 Rails 코드 | `server/` | 이식 소스 |
| 모바일 클라이언트 | `mobile/` | API 소비자 |
| 공유 API 스키마 | `shared/api-schema/` | API 계약 정의 위치 |

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
