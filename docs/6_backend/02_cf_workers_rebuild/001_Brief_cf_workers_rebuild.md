---
id: "001"
type: brief
title: "Cloudflare Workers + Hono + D1 전면 리빌딩"
created: 2026-04-28
status: completed
quality_profile: standard
priority_dimensions: [longevity, sustainability, cutover_safety]
deep_critique: false
critique_docs: []
traces_research: "../01_cloudflare_migration_research/010_Research_cloudflare_migration.md"
decision_basis: "사용자 결정: Full Migration 선택 (연구 010의 default Partial 권고 대신)"
summary: >
  사용자가 Full Migration 시나리오를 선택했다. 현 Rails 8 + SQLite + Hotwire
  백엔드를 Cloudflare Workers + Hono + D1 + R2 + KV 스택으로 전면 재작성한다.
  TypeScript 단일 언어로 통일, 모바일 API 신설, Hono SSR로 admin 대체,
  Toss 우선 결제 통합. Rails 코드는 archive로 보존(cutover 안전). 본 Brief는
  결정 정리 Brief — 향후 모든 작업의 alignment anchor.
keywords: [cloudflare, workers, hono, d1, rails-rebuild, full-migration, typescript, drizzle, cutover]
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
| 1 | **CF 인프라 셋업** | CF account, Workers project, D1 DB, R2 bucket, KV namespace, Wrangler 구성, GitHub repo 연동, secrets 관리 |
| 2 | **도메인 + TLS** | Custom Domain 등록 (예: `api.{도메인}` for mobile, `admin.{도메인}` for admin), Workers Routes 매핑, 자동 TLS |
| 3 | **DB 스키마 (Drizzle)** | 14 테이블 → Drizzle schema, migrations, JSON 컬럼 매핑, FK 제약, seed (PersonalityType × 16) |
| 4 | **도메인 services 이식** | 1,850 LOC services → TypeScript 포트 (scoring/tone-filter/restricted-terms/insights). 테스트(Vitest) 동행. |
| 5 | **API 레이어 (Hono routes)** | 13 컨트롤러 + admin → Hono router. **새로 모바일 JSON API 신설** (현재 0 endpoint). 기존 HTML 라우트는 admin 영역에서 SSR로 재현 또는 폐기. |
| 6 | **인증·세션** | `User.encrypts :email, deterministic: true` → Web Crypto API AES-GCM 수동 구현 (login-by-email 호환). 세션은 KV 또는 D1 기반. |
| 7 | **Admin UI 대체** | Hotwire 2 템플릿 + 8 Stimulus → **Hono SSR + 최소 vanilla JS** (별도 SPA 빌드 회피). |
| 8 | **테스트 재작성** | 18 RSpec 파일 (2,641 LOC) → Vitest. 도메인 동등성 보장. TDD 흐름 유지. |
| 9 | **결제 통합 — 한국 우선** | Toss Payments 1순위 (50 LOC HMAC-SHA256, Web Crypto API), PortOne 2순위 검토. webhook idempotency = D1 `UNIQUE(event_id)`. |
| 10 | **CI/CD** | GitHub Actions + Wrangler deploy. Production / Preview(PR 단위) / Staging 환경 분리. |
| 11 | **모바일 통합** | Flutter 앱이 신규 API 호출 시작. shared/api-schema/ 정의. 인증·결제 흐름 검증. |
| 12 | **Rails 폐기 (Cutover)** | server/ 디렉터리 → archive/rails-server/로 이동. **삭제 금지** (회귀 안전). 회귀 조건 발생 시 archive 활성화 가능. |
| 13 | **모니터링·로깅** | Workers Analytics + 콘솔 로그 + 선택적 CF Logpush. 에러 알림 채널 연결. |

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
| 3 | ORM | **Drizzle ORM** | D1 공식 권장, TypeScript-first, 타입 안전 마이그, 가벼움 | Prisma보다 생태계 작음 | Prisma 기각 (D1 호환성 약함, 무거움), 직접 SQL 기각 (타입 안전성 손실) |
| 4 | Admin UI 대체 전략 | **Hono SSR + vanilla JS** | 별도 SPA 빌드 회피, 단일 코드베이스, Hotwire 2 템플릿 수준 복잡도엔 충분 | React/Svelte 같은 컴포넌트 모델 없음 | React SPA 기각 (두 빌드 시스템), Astro 기각 (오버엔지니어링), Next.js 기각 (Vercel 종속) |
| 5 | 결제 PG 1순위 | **Toss Payments** | 연구 P3에서 50 LOC 가장 가벼움. Web Crypto API HMAC-SHA256. 한국 표준. | PortOne의 다중 PG 추상화 미사용 | PortOne 기각 (이중 추상화), Stripe 기각 (Korea 부재), KCP 기각 (직접 통합 부담) |
| 6 | 결제 PG 2순위 | **PortOne 검토** | Toss 외 PG(KCP/이니시스 등) 추가 시 PortOne의 멀티 PG 추상화 활용 | Toss로 충분하면 도입 안 함 | KCP 직접 기각, 다중 SDK 기각 |
| 7 | 테스트 도구 | **Vitest** | TypeScript-first, Jest 호환, Workers 테스트 지원 | bun test보다 성숙 | bun test 기각 (Workers 호환 검증 추가 필요), Jest 기각 (느림) |
| 8 | 인증 방식 | **자체 구현** (BetterAuth 또는 Lucia 라이브러리 검토) | 단순한 email+password+session으로 시작. User.encrypts deterministic은 직접 구현 (검증 필요). | OAuth 미포함 (단계적 추가) | Supabase Auth 기각 (외부 의존), Clerk 기각 (비용·종속) |
| 9 | Cutover 전략 | **Phased (단계적 폐기)** | (1) CF 인프라 + 모바일 API 가동 → (2) admin Hono SSR 가동 → (3) Rails 폐기. 각 단계 검증 후 다음. | Big bang 대비 시간 증가 | Big bang cutover 기각 (회귀 어려움) |
| 10 | Rails 코드 처리 | **archive/rails-server/로 보존** | 삭제 시 비상 회귀 불가능. archive는 git 추적 유지. | 디스크 공간 약간 차지 (무시 가능) | 삭제 기각 (비가역), 별 repo 분리 기각 (이력 단절) |
| 11 | 환경 분리 | **Production / Preview / Staging** | wrangler 환경별 deploy. PR 단위 preview URL 자동. | 무료 티어 내 처리 가능 | 단일 환경 기각 (PR 검증 어려움) |
| 12 | 도메인 구조 | **`api.<도메인>` (모바일 API) + `admin.<도메인>` (admin UI)** | 두 라우트 분리로 관심사 분리, 각각 다른 Worker 가능 | 인증 도메인 간 공유 처리 필요 | 단일 도메인 + path 구분 기각 (admin 보호 약함) |
| 13 | 글로벌 결제 | **연기** (Stripe Korea 또는 해외 법인 시점까지) | 본 연구 결정 5 업데이트: "동시 병행" → "단계적 병행" | 단기 글로벌 결제 불가 | 즉시 Stripe 통합 기각 (Korea 가맹점 부재) |

## ⚠️ Critical Review Request

본 결정은 본 연구 010의 default 권고(**Partial**, 신뢰도 70-75%)와 다른 선택입니다. 사용자가 5개 가정을 자가 진단한 결과로서 Full을 선택한 것으로 받아들이지만, 다음 사항을 향후 진행 중 모니터링하기를 권장합니다:

- **Risk**: 5개 가정 중 일부가 미래에 깨질 경우 (예: 1년 내 100K MAU 도달, 글로벌 비중 ↑, TS 친숙 가정 약화), Full의 비용이 Stay/Partial로 회귀하기 어려운 위치에 있을 수 있음.
- Why Full is acceptable: 사용자가 의식적 선택, 단일 코드베이스/언어/인프라의 장기 운영 가치, archive 보존으로 회귀 비상구 확보.
- Mitigation: 6개월·12개월 시점에 5개 가정을 재검증하는 retrospective 권장. 가정 깨짐 시 Stay/Partial 회귀 옵션이 archive 보존으로 유지됨.
- **→ 이 진행 결정에 동의하는 것을 전제로 진행. 동의하지 않는다면 Brief 갱신 요청.**

## Open Questions

없음 — 모든 핵심 결정은 위 Decisions 또는 Out of Scope로 정리됨. 구현 단계 세부 (라이브러리 버전, 폴더 구조, 테스트 패턴 등)는 `/scope` + `/makeplan` 단계에서 확정.

## Constraints

- **Rails archive 보존 필수** (`archive/rails-server/`) — 삭제 금지, 6개월 이상 유지 권장
- **단계적 cutover** — big bang 금지
- **한국 사용자 우선** — Toss/PortOne, Korean 시장 컨텍스트 적합성 우선
- **글로벌 결제 단계적** — 본 phase에서 Stripe 통합 안 함
- **벤더 락인 수용** (사용자 명시) — 회피 전략은 본 phase 범위 밖
- **단일 또는 매우 작은 개발팀** 가정 — 가독성·유지보수성 우선
- **TypeScript 단일 언어** — 새 코드는 모두 TS, JS 사용 최소화 (강제 타입 안전)
- **장기 운영 = 2026-04 ~ 2029-04** (1-3년)
- **트래픽 가정 = 1년 내 수만 MAU 이내** (D1 10GB 천장 전)

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

## Model Anchors

1. **이 Brief는 결정 정리 Brief이다**. Full Migration이 사용자 결정으로 못박혔다. Stay/Partial 재논의 금지. 진행 중 가정 변동이 발생해도 별도 Brief 갱신 요청 후 처리.

2. **인프라 = CF Workers + Hono + D1 + R2 + KV** (5종 + 필요 시 Queues/Durable Objects). 대체 인프라 검토 금지.

3. **언어 = TypeScript 단일**. 새 코드는 모두 TS. JavaScript 사용은 명시적 사유(라이브러리 호환 등) 시만.

4. **ORM = Drizzle**. Prisma/raw SQL 기각.

5. **Admin UI = Hono SSR + vanilla JS**. 별도 SPA 빌드(React/Svelte/Astro) 도입 금지. Hotwire 2 템플릿 수준 복잡도엔 SSR로 충분.

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

13. **인증 = 자체 구현 (BetterAuth/Lucia 라이브러리 활용 가능)**. Supabase/Clerk 등 외부 인증 SaaS 의존 금지 (CF 단일 의존 유지).

14. **모니터링 = Workers Analytics 우선 + 필요 시 Logpush**. Sentry 같은 외부 APM은 별도 phase.

15. **벤더 락인 회피 전략 = 범위 밖**. 사용자 수용 명시. 다만 데이터 portability(D1 → SQLite export)는 백업 차원에서 유지.

## Critique Integration

(--deep 모드 미적용. 본 Brief는 본 연구 010이 사실상 deep critique 역할을 하여 별도 비평 사이클 불필요.)

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
