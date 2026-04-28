---
id: "005"
type: critique
title: "Brief Critique — Alternatives (대안 탐색)"
created: 2026-04-28
status: completed
perspective: "alternatives"
target: "001"
confidence: high
model: "opus"
reasoning_depth: "deep"
summary: >
  Brief 001의 11개 autonomous 결정(3-13)을 대안 탐색 관점에서 비평한다.
  외부 evidence 기준으로 6개 결정은 "정당화 OK", 4개는 "약화 — Brief 명시 필요",
  1개는 "revision 권고". 핵심 발견: (1) Decision 8 인증의 "Lucia 라이브러리 검토"는
  부정확 — Lucia는 2024년 sunset됐다 (BetterAuth 단독 권고로 정정 필요),
  (2) Decision 4 Astro 기각 사유 부정확 — 2026-01 Cloudflare가 Astro 인수, Workers
  GA 어댑터 보유 (Astro 재검토 가치 있음), (3) Decision 7 Vitest 결정에
  @cloudflare/vitest-pool-workers 명시 누락 (Hono 공식 예제 패턴),
  (4) Decision 9 Cutover 순서 reordering 검토 가치 (admin 먼저 안전), (5) Decision 12
  멀티 서브도메인의 cookie/CORS 복잡도 trade-off 약하게 평가됨.
  나머지 결정(Drizzle, Toss, archive 보존, 환경 분리, 글로벌 결제 연기)은 정당화 OK.
keywords: [critique, brief, alternatives, drizzle, kysely, betterauth, lucia-sunset, astro, htmx, cloudflare-access, blue-green, vitest-pool-workers]
---

# Brief Critique — Alternatives

## Executive Summary

Brief 001은 Cloudflare Workers + Hono + D1 전면 리빌딩의 11개 autonomous 결정을 명확하게 표로 정리했다. 본 비평은 각 결정의 chosen option과 대안의 trade-off를 외부 2026-04 evidence와 비교했다.

**평가 결과**

| 평가 | Decisions | 비율 |
|------|-----------|------|
| 정당화 OK | 3 (Drizzle), 5 (Toss), 6 (PortOne 2순위), 10 (archive), 11 (환경), 13 (글로벌 연기) | 6/11 |
| 약화 — Brief 명시 필요 | 4 (Admin UI), 7 (테스트), 9 (Cutover), 12 (도메인) | 4/11 |
| revision 권고 | 8 (인증) | 1/11 |

**핵심 발견 5개**

1. **[Critical] Decision 8 인증 — "Lucia 검토" 부정확**: Lucia는 2024-Q4 sunset됨. 메인테이너가 BetterAuth로 redirect 권장 명시. Brief의 "BetterAuth 또는 Lucia 라이브러리 검토" 문구는 사실 오류 — BetterAuth 단독 권고로 정정 필요. BetterAuth는 D1 first-class 지원(Kysely D1 dialect 내장), Hono 공식 예제 보유.

2. **[High] Decision 4 Admin UI — Astro 기각 사유 약화**: Brief의 "Astro 기각 (오버엔지니어링)"은 2026-04 시점 부정확. **2026-01 Cloudflare가 Astro 인수**, Astro 6 dev server가 workerd 위에서 구동, Workers GA 어댑터 보유. SPA가 아니라 island architecture(SSR-first)이므로 Hotwire 대체 후보로 재평가 가치. 단 Hono SSR + JSX renderer + HTMX 조합도 강력(Hono 창시자 Yusuke Wada가 직접 추천 + 22KB Worker bundle 사례).

3. **[High] Decision 7 테스트 — `@cloudflare/vitest-pool-workers` 명시 누락**: Brief는 "Vitest"로 끝났으나 Workers 환경에서 D1 binding 통합 테스트는 `@cloudflare/vitest-pool-workers`(Workers Vitest pool, 2026-04 still beta) 명시가 필요. Hono 공식 예제 [Cloudflare Testing](https://hono.dev/examples/cloudflare-vitest)도 이를 사용. Brief의 Model Anchor 10에 추가 권고.

4. **[Medium] Decision 9 Cutover 순서 — A→B→C 정당성 약함**: "API 먼저 → admin 나중(B 단계)"은 사용자 영향이 큰 영역을 먼저 노출시킨다. **admin 먼저(B→A→C)** 또는 **Cloudflare Workers의 Gradual Deployments(traffic shift)** 활용을 검토하지 않았다. CF Workers는 Version Overrides + @100 syntax로 blue/green/canary 지원(GA 2024+) — Phase B와 결합하면 부분 회귀가 가능.

5. **[Medium] Decision 12 도메인 — 멀티 서브도메인 cookie/CORS trade-off 약화**: `api.<도메인>` + `admin.<도메인>` 분리는 cookie를 `.<도메인>`으로 설정하면 공유 가능하나 서드파티 cookie 정책(Chrome 2024+)으로 인해 cross-site 시나리오에서 깨질 가능성. 단일 도메인 + path 분리(`/api/`, `/admin/`)가 cookie complexity 감소 + same-origin 보안. Brief가 후자를 "admin 보호 약함"으로 기각했지만 path 기반 + Workers route + Cloudflare Access 조합으로 동등하거나 더 강한 보호 가능.

**비평이 약화시키지 못한 결정**

- **Decision 3 (Drizzle)**: D1 1순위 ORM, Prisma는 D1 미지원(Accelerate 유료 우회만), Kysely는 D1 가능하지만 schema-first 마이그 부재. Brief 선택 정당.
- **Decision 5 (Toss 1순위)**: 50 LOC, Web Crypto API 호환, 한국 표준. 정당.
- **Decision 10 (archive 보존)**: same-repo 디렉터리 보존이 별도 repo·branch보다 git history 단절 없음. 정당.
- **Decision 11 (환경 3개)**: CF Workers Free 티어 내 처리 가능, PR 단위 preview 자동. 정당.
- **Decision 13 (글로벌 결제 연기)**: Stripe Korea 부재 사실. 정당.

**Recommendations 수**: 7개 actionable.

## Findings

### Strengths

1. **결정 표 형식의 명확성** — "Decision / Chosen / Rationale / Trade-off / Alternatives" 5컬럼이 비평 가능한 형태로 명시됐다. 비평을 위한 정보 비대칭이 적다.
2. **사용자 결정과 autonomous 결정의 구분** — Decision 1·2가 사용자 결정으로 명시돼 비평 대상에서 제외됨이 명확.
3. **Out of Scope 8개로 scope creep 차단** — Hetzner/Vercel/Stripe/Next.js/SPA/external DB 등 대안이 명시적으로 기각됨 (재논의 부담 감소).
4. **Critical Review Request 섹션** — Full vs Partial 결정의 가정 monitoring 명시. 비평 친화적 구조.

### Weaknesses

| # | Finding | Severity | Evidence | Recommendation |
|---|---------|----------|----------|----------------|
| W1 | "Lucia 라이브러리 검토"는 2024-Q4 sunset된 라이브러리 참조 | Critical | [pkgpulse 2026 better-auth vs Lucia](https://www.pkgpulse.com/blog/better-auth-vs-lucia-vs-nextauth-2026): Lucia 메인테이너가 BetterAuth로 redirect 권장 | Decision 8 + Model Anchor 13에서 "Lucia" 제거, "BetterAuth"만 명시 |
| W2 | Astro 기각 사유 "오버엔지니어링"이 2026-04 사실과 어긋남 | High | [Cloudflare Workers Astro docs](https://developers.cloudflare.com/workers/framework-guides/web-apps/astro/), [Astro 6 + workerd](https://alexbobes.com/programming/a-deep-dive-into-astro-build/): 2026-01 CF가 Astro 인수, Astro 6 dev server가 workerd | Decision 4 alternatives에서 Astro 재평가 또는 명시적 trade-off 보완 |
| W3 | `@cloudflare/vitest-pool-workers` 명시 부재 | High | [Vitest integration docs](https://developers.cloudflare.com/workers/testing/vitest-integration/), [Hono Cloudflare Testing example](https://hono.dev/examples/cloudflare-vitest) | Decision 7과 Model Anchor 10에 "@cloudflare/vitest-pool-workers" 명시 (D1 binding integration test 필수) |
| W4 | Cutover 순서 A→B→C의 정당성 약함 (admin이 사용자 영향 적음) | Medium | CF Workers Gradual Deployments GA: Version Overrides + @100 syntax로 blue/green 가능 | Decision 9에 reordering 옵션 또는 traffic-shift 접근 명시 |
| W5 | 멀티 서브도메인의 cookie/CORS 복잡도 trade-off 약함 | Medium | [MDN Cross-Site Cookies](https://docs.descope.com/security-best-practices/crossite-cookies): `.<root>` cookie 가능하나 cross-site 정책으로 약함 | Decision 12에 path-based 단일 도메인 옵션 명시적 비교 (특히 admin은 Cloudflare Access 적용) |
| W6 | "결제 LOC 50 LOC" 추정의 함의 약함 | Low | 부분 환불·정기결제 추가 시 LOC 급증 가능 | Decision 5에 "50 LOC는 1회 결제 + webhook 한정. 정기결제·부분환불은 +α" 명시 |
| W7 | "글로벌 결제 연기"의 재검토 시점 불명확 | Low | Stripe Korea 발표 monitoring 권고만 있음 | Decision 13에 "6개월·12개월 시점 재검토" + PayPal/Adyen/Wise 등 대안 PG 한 줄 명시 |

### Missing Elements

| # | What's Missing | Why It Matters | Suggestion |
|---|----------------|----------------|------------|
| M1 | Cloudflare Access for admin auth 옵션 미검토 | 1인 개발자에 admin 인증 위임은 매력적. Free tier 사용 가능 | Decision 8 alternatives에 "Cloudflare Access (admin only) + 자체 구현 (mobile API)" hybrid 명시 |
| M2 | Hono SSR JSX vs HTML template 선택 미정 | Hono는 둘 다 지원. 결정 미루면 일관성 없는 코드 발생 | Decision 4 또는 scope 단계에서 "JSX renderer 채택" 명시 |
| M3 | HTMX 도입 여부 미명시 | Hotwire 대체 패턴으로 가장 유사한 DX. Yusuke Wada 직접 추천 | Decision 4에 HTMX 옵션 + 기각/채택 사유 명시 |
| M4 | feature flag 또는 traffic shift 도구 미언급 | Cutover 안전성 강화 | Decision 9 또는 Constraint에 "Workers Versions API 활용" 명시 |
| M5 | 글로벌 결제 대안 PG (PayPal, Adyen, Wise) 미언급 | Stripe만 글로벌 옵션이 아님 | Decision 13에 "Stripe 외 글로벌 PG 후보 한 줄 명시" |
| M6 | Quality Profile = Standard의 적정성 평가 없음 | 30.5 MW 작업에 Polish가 적절할 수 있음 | Brief 메타: Polish 채택 + 추가 critique cycle 검토 |
| M7 | In Scope 13개의 phase 분리 검토 부재 | Phase A/B/C가 Cutover에 한정, In Scope 자체는 한 phase | Brief 분리 또는 In Scope 우선순위 그룹화 |

## Detailed Analysis

### Decision 3 — ORM (Drizzle vs Prisma vs Kysely vs raw)

**Brief 선택**: Drizzle. 정당화: D1 공식 권장, TypeScript-first, 가벼움.

**대안 비교**

| 옵션 | D1 호환 | Bundle | 마이그 도구 | DX | 2026 상태 |
|------|---------|--------|-------------|----|----|
| **Drizzle** | Native (D1Database 어댑터) | ~5KB gzip | drizzle-kit (schema-first auto-gen) | SQL-close | Stable, CF 권장 |
| Prisma | **미지원 (Accelerate 유료 프록시 필요)** | ~1.6 MB | Prisma Migrate | Higher abstraction | D1 Edge 부적합 |
| Kysely | Native (`kysely-d1`, Hono creator endorsed) | ~8KB gzip | 수동 (BYO migration) | Type-safe SQL builder | Stable, BetterAuth 내장 dialect로 채택 |
| Raw SQL + Zod | Native | ~0KB | 수동 | Type-safe via parse() | Trade-off: 마이그·schema 일관성 책임 |

**평가**: **정당화 OK**.

**근거**:
- Prisma는 D1 native 지원 부재(2026-04 기준), Accelerate 유료 프록시는 edge 가치 약화 ([Prisma D1 docs comparison](https://www.prisma.io/docs/orm/more/comparisons/prisma-and-drizzle))
- Kysely는 매력적 옵션이지만 schema-first 마이그 부재 — Drizzle Kit이 14 테이블 마이그 자동 생성에 우위
- Raw SQL + Zod는 14 테이블 수기 schema 관리 부담

**약점 (Brief가 명시 안 함)**:
- Drizzle은 query builder가 invalid query를 runtime까지 못 잡는 경우 있음 (Prisma 대비 type safety gap)
- 한국어 자료/사례가 Prisma보다 적음 (Brief 가정과 일치하지만 명시는 안 됨)

**권고**: Brief 유지. 단 Drizzle relational query builder 채택 시 학습 곡선 + invalid query runtime 감지 한계 1줄 명시.

**Source**: [Drizzle vs Kysely 2025-06](https://marmelab.com/blog/2025/06/26/kysely-vs-drizzle.html), [Drizzle vs Prisma 2026](https://encore.dev/articles/drizzle-vs-prisma)

---

### Decision 4 — Admin UI (Hono SSR vs HTMX vs Astro vs SPA)

**Brief 선택**: Hono SSR + vanilla JS. 정당화: SPA 빌드 회피, 단일 코드베이스, Hotwire 2 템플릿 수준에 충분.

**대안 비교**

| 옵션 | DX | 빌드 시스템 | Hotwire 친화도 | 2026 CF 호환 | 평가 |
|------|----|----|----|----|----|
| **Hono SSR + JSX renderer + vanilla JS** | 단일 코드베이스, JSX 컴포넌트 재사용 | 1 빌드 | 중간 | 완벽 | Brief 선택 |
| Hono SSR + HTML template (handlebars 등) | 더 단순 | 1 빌드 | 약함 | 완벽 | JSX 대비 컴포넌트 재사용 약함 |
| **Hono SSR + JSX + HTMX** (Yusuke Wada 직접 추천) | server-driven, partial update | 1 빌드 | **강함 (Hotwire 동등 DX)** | 완벽 (22KB worker 사례) | Brief 미검토 |
| **Astro on Workers** | Island architecture, SSR-first | 별도 빌드 (workerd 호환) | 부분 | **완벽 (CF가 Astro 인수)** | Brief 기각 사유 부정확 |
| React SPA + Hono API | 풀 컴포넌트 모델 | 두 빌드 | 약함 | 완벽 | Brief 기각 (정당) |
| Next.js | RSC + SSR | OpenNext 어댑터 | 중간 | 양호 (벤더 종속 약함) | Brief 기각 (Vercel 종속 우려) |

**평가**: **약화 — Brief 명시 필요**.

**핵심 약점**

1. **Astro 기각 사유 "오버엔지니어링"이 부정확**:
   - 2026-01 [Cloudflare가 Astro 인수](https://alexbobes.com/programming/a-deep-dive-into-astro-build/) — 단일 벤더로 통합됨
   - Astro 6 dev server는 workerd 위에서 구동 — 로컬·프로덕션 동일 런타임
   - Astro는 SSR-first + island architecture (SPA 아님)
   - 27 ERB 뷰 → Astro pages 매핑은 SPA보다 자연스러울 수 있음
   - 단 별도 빌드 시스템은 사실 — Brief의 "단일 빌드 시스템" 가치와 trade-off

2. **HTMX 도입이 검토 대상에서 누락**:
   - Hono 창시자 Yusuke Wada가 [Hono+HTMX+Cloudflare 직접 추천](https://blog.yusu.ke/hono-htmx-cloudflare/)
   - server-driven, partial update — Hotwire Turbo Frame과 가장 가까운 DX
   - 22 KB worker bundle 실측, ~100ms TTFB
   - 8 Stimulus 컨트롤러 → HTMX hx-* attribute 매핑 자연스러움

3. **JSX vs HTML template 선택이 결정에 부재**:
   - Hono는 둘 다 지원 — 미결정 시 코드 일관성 저하
   - JSX renderer middleware는 component reusability + streaming Suspense 지원
   - Brief는 "vanilla JS"라고 모호하게 표현 — JSX 채택 여부 결정 필요

**권고**:
- Decision 4를 **"Hono SSR + JSX renderer + HTMX (Hotwire 동등 DX) + vanilla JS 보조"**로 구체화
- Astro 재검토는 별도 implementation 사이클에서 prototype 비교 후 결정 (옵션 열어두기)

**Source**: [Hono+HTMX+Cloudflare](https://blog.yusu.ke/hono-htmx-cloudflare/), [Cloudflare Astro adapter](https://developers.cloudflare.com/workers/framework-guides/web-apps/astro/), [Hono JSX renderer](https://hono.dev/docs/middleware/builtin/jsx-renderer)

---

### Decision 5 — 결제 1순위 (Toss vs PortOne 직접)

**Brief 선택**: Toss Payments. 정당화: 50 LOC HMAC-SHA256, Web Crypto API, 한국 표준.

**대안 비교**

| 옵션 | LOC | 다중 PG | 정기결제 | 부분환불 | 추가 추상화 |
|------|-----|---------|---------|---------|----|
| **Toss 직접** | 50 (1회 결제) ~ 200 (정기·부분환불) | 단일 | Toss 정기결제 API 직접 | 직접 | None |
| PortOne v2 직접 | 100 (1회) ~ 300 (정기·부분환불) | 멀티 PG 추상화 | PortOne 통합 | 통합 | 멀티 PG 자유 전환 |
| Toss SDK + 다중 PG SDK 병행 | 150~500 | 수동 라우팅 | 각 PG 별 | 각 PG 별 | None |

**평가**: **정당화 OK**.

**근거**:
- Toss 직접의 50 LOC는 **1회 결제 + webhook idempotency 한정**
- 정기결제·부분환불·취소·재결제 시 LOC 200 수준으로 증가하지만 PortOne 대비 여전히 가벼움
- PortOne은 [Toss를 PG로 포함](https://portone.gitbook.io/docs-en/payment-integration-by-pg/payment-gateways/toss) — 후속 추가 시 마이그레이션 가능
- "단일 PG로 충분" 시나리오가 한국 우선 service에 다수임

**약점 (Brief가 명시 안 함)**:
- "50 LOC"는 1회 결제 한정 — Brief에 "+ 정기결제/부분환불 시 추가 LOC 발생" 명시 필요
- "다중 PG 시 재작성" 비용이 Brief에 명시되지 않음 (Decision 6 PortOne 2순위로 일부 다룸)

**권고**: Decision 5에 LOC 추정 범위 + 정기결제 시 PortOne 검토 트리거 1줄 명시.

---

### Decision 6 — 결제 2순위 (PortOne 도입 트리거)

**Brief 선택**: Toss 외 PG 추가 시 PortOne. 정당화: 멀티 PG 추상화 활용.

**평가**: **정당화 OK** (단 트리거 명시 약함).

**근거**:
- PortOne 2026 시점 3,000+ 가맹점 보유, Toss/KCP/이니시스/NICE 등 6 PG 통합 ([PortOne docs 2026](https://docs.portone.cloud/docs/portone-korea))
- Toss 직접만으로 충분한 시나리오가 다수면 PortOne은 영원히 불필요할 가능성

**약점**:
- "Toss 외 PG 추가 시" 트리거가 모호 — 어떤 조건에서 추가가 발생하는가? (예: 특정 카드사 미지원, 사용자 결제수단 다양화 요구, 해외 PG 통합 등)

**권고**: Decision 6에 PortOne 도입 트리거 3개 명시 (예: ① Toss 미지원 결제수단 사용자 ≥ 5%, ② 해외 사용자 + Stripe 통합, ③ 부분 환불·정기결제 운영 부담 ↑).

**Source**: [PortOne disintermediation 분석 Sacra 2026](https://sacra.com/c/portone/)

---

### Decision 7 — 테스트 (Vitest vs bun:test vs Workers 전용)

**Brief 선택**: Vitest. 정당화: TypeScript-first, Jest 호환, Workers 테스트 지원.

**대안 비교**

| 옵션 | Workers binding 통합 테스트 | 속도 | TypeScript | 2026 상태 |
|------|----|----|----|----|
| **Vitest + `@cloudflare/vitest-pool-workers`** | **공식 지원 (workerd 위에서 실행)** | 빠름 | First-class | Open beta |
| Vitest (단순) | 없음 (Miniflare 별도 셋업) | 빠름 | First-class | Stable |
| bun:test | 없음 (Miniflare 별도 셋업) | 매우 빠름 | First-class | Stable (Bun 본체 GA) |
| Jest | Miniflare로 가능 | 느림 | 변환 필요 | Legacy |
| Playwright | E2E (browser 통합) | 느림 (browser 부팅) | First-class | E2E 전용 |

**평가**: **약화 — Brief 명시 필요**.

**핵심 약점**:

1. **`@cloudflare/vitest-pool-workers` 명시 부재**:
   - Workers + D1 binding 통합 테스트는 단순 Vitest로 부족
   - [Cloudflare 공식 통합](https://developers.cloudflare.com/workers/testing/vitest-integration/): Vitest 4.1+ 필수, `cloudflareTest()` plugin
   - [Hono 공식 예제](https://hono.dev/examples/cloudflare-vitest)도 이를 사용
   - 2026-04 시점 still **open beta** — 안정성 caveat 명시 필요

2. **Playwright (E2E) 결정 부재**:
   - 모바일 API + admin UI 전체 흐름 검증에는 단위 테스트 부족
   - admin UI(Hono SSR)는 browser 기반 검증이 적합

3. **bun:test는 Workers 직접 호환 아님**:
   - Bun은 별도 런타임 — Workers는 V8 isolate
   - bun:test 활용 시 Miniflare/workerd로 별도 통합 필요 → Brief의 "Workers 호환 검증 추가 필요" 정당

**권고**:
- Decision 7을 **"Vitest + @cloudflare/vitest-pool-workers (binding 통합) + Playwright (E2E, optional)"**로 구체화
- Model Anchor 10에 "테스트 = Vitest + cloudflare/vitest-pool-workers" 명시

**Source**: [Cloudflare Vitest integration](https://developers.cloudflare.com/workers/testing/vitest-integration/), [Hono Cloudflare Testing](https://hono.dev/examples/cloudflare-vitest)

---

### Decision 8 — 인증 (BetterAuth vs Lucia vs Auth.js vs Cloudflare Access vs SaaS)

**Brief 선택**: 자체 구현 (BetterAuth 또는 Lucia 라이브러리 검토). 정당화: 단순 email+password+session.

**대안 비교 (2026-04 GA 상태 검증)**

| 옵션 | D1 호환 | 2026-04 상태 | Workers 호환 | 비용 |
|------|---------|--------------|--------------|------|
| **BetterAuth** | **First-class (built-in Kysely D1 dialect)** | Active dev, ~3 releases/wk | 완벽 | Free OSS |
| Lucia | SQLite 어댑터 가능 | **2024-Q4 sunset (메인테이너가 BetterAuth로 redirect)** | 가능 | Free OSS (deprecated) |
| Auth.js (NextAuth) | D1 어댑터 있음 | Edge runtime 지원 | 양호 | Free OSS |
| **Cloudflare Access (admin only)** | N/A (CF 자체 인증) | GA, Free tier | 완벽 (CF 네이티브) | Free up to 50 users |
| Clerk | 외부 service | GA, Edge 지원 | 완벽 | Free 10K MAU, then $25+/mo |
| Supabase Auth | 외부 service | GA | 양호 | Free 50K MAU, then $25+/mo |
| Stack Auth | 외부 service | GA 2026 | 양호 | Free tier |

**평가**: **revision 권고**.

**핵심 발견**:

1. **Lucia는 2024-Q4 sunset됨** (Critical):
   - [Lucia 메인테이너 발표](https://www.pkgpulse.com/blog/better-auth-vs-lucia-vs-nextauth-2026): "BetterAuth가 Lucia를 surpass했다, 신규 프로젝트는 BetterAuth 사용 권장"
   - Brief의 "BetterAuth 또는 Lucia 라이브러리 검토" 문구는 **사실 오류** — 2026-04 시점 Lucia는 deprecated
   - Brief의 가정 "BetterAuth/Lucia 양자 비교 후 선택"은 가능하지 않음

2. **BetterAuth가 D1 first-class**:
   - 2026-04 [@better-auth/cloudflare 공식 통합](https://github.com/zpg6/better-auth-cloudflare): D1, KV, R2, Hyperdrive
   - [Hono 공식 예제](https://hono.dev/examples/better-auth-on-cloudflare) 보유
   - Built-in Kysely D1 dialect — 별도 어댑터 불필요

3. **Cloudflare Access for admin auth는 매력적 미검토 옵션**:
   - 1인 개발자에 admin 인증 위임은 운영 부담 ↓
   - Free tier (subscription tier 무관) 50 users
   - admin.<도메인> 라우트에 ZTNA 적용으로 자체 인증 코드 0
   - mobile API는 자체 BetterAuth로 분리 (hybrid)

**권고**:
- **Decision 8 revision**: "**BetterAuth (mobile API 자체 인증) + Cloudflare Access (admin UI 인증 위임)** hybrid"
- Model Anchor 13에서 "Lucia" 제거
- Brief 결정 "Supabase/Clerk 외부 의존 금지"는 유지하되 Cloudflare Access는 CF 단일 의존 유지 원칙과 호환

**Source**: [BetterAuth vs Lucia vs NextAuth 2026](https://www.pkgpulse.com/blog/better-auth-vs-lucia-vs-nextauth-2026), [Hono Better Auth example](https://hono.dev/examples/better-auth-on-cloudflare), [Cloudflare Access docs](https://developers.cloudflare.com/cloudflare-one/), [@better-auth/cloudflare GitHub](https://github.com/zpg6/better-auth-cloudflare)

---

### Decision 9 — Cutover 순서 (A→B→C vs B→A→C vs traffic shift)

**Brief 선택**: Phase A (인프라+모바일 API) → Phase B (admin SSR) → Phase C (Rails archive).

**대안 비교**

| 순서 | 사용자 영향 | 회귀 안전성 | 검증 단계 |
|------|----|----|----|
| **A→B→C (Brief)** | 모바일 사용자 즉시 노출 | API 회귀 어려움 (Flutter 앱 deploy) | API 우선 검증 |
| B→A→C | 내부 admin 먼저 | 외부 영향 없음 | admin은 안전 검증 sandbox |
| 병렬 A+B → C | 동시 노출 | big bang에 가까움 | 자원 부담 |
| **Traffic shift (Workers Versions)** | gradual % rollout | 즉시 회귀 가능 | A/B/canary 자유 |

**평가**: **약화 — Brief 명시 필요**.

**핵심 약점**:

1. **admin이 사용자 영향 적음 — B→A→C가 안전할 수 있음**:
   - admin은 운영자(1인 개발자) 본인만 접근 — 영향 범위 ≈ 0
   - admin SSR을 먼저 가동하여 Hono SSR 패턴, 인증, D1 통합을 internal 검증
   - 검증 후 mobile API 가동 (사용자 영향 큰 부분)
   - Brief 가정 "API 먼저"가 cutover safety에 역행할 가능성

2. **Cloudflare Workers Gradual Deployments 미언급**:
   - [Versions and Deployments](https://developers.cloudflare.com/workers/configuration/versions-and-deployments/): GA 2024+
   - Version Overrides + @100 syntax — blue/green/canary 지원
   - Version Affinity로 user/session 단위 routing — A/B 테스트 가능
   - Phase A 내부에서 traffic shift 가능 (예: 0% → 5% → 50% → 100%)

3. **Feature flag 또는 환경 분리 활용 부재**:
   - Phase B (admin)와 Phase A (mobile API)가 서로 독립이라면 병렬 가능

**권고**:
- Decision 9 alternatives에 "B→A→C 순서 검토" 또는 "각 phase 내부에서 Workers traffic shift 활용" 추가
- Cutover Safety Quality dimension과 정렬

**Source**: [CF Workers Gradual Deployments](https://blog.cloudflare.com/workers-production-safety/), [Versions & Deployments](https://developers.cloudflare.com/workers/configuration/versions-and-deployments/)

---

### Decision 10 — Rails archive (same repo vs separate repo, 기간)

**Brief 선택**: same-repo `archive/rails-server/`, 6개월 이상 유지.

**대안 비교**

| 옵션 | Git history | 디스크 | 회귀 비용 | 복잡도 |
|------|----|----|----|----|
| **same-repo `archive/`** | 단일 history 유지 | 약간 ↑ | 낮음 (디렉터리 이동만) | 낮음 |
| separate repo | 분리 (단 git filter-repo로 commit 보존 가능) | 모노레포 ↓ | 중간 (clone + cd) | 중간 |
| branch 보존 | 단일 history, branch 분리 | 모노레포 ↓ | 낮음 (checkout) | 낮음 |
| git bundle | 외부 파일 (.bundle) | 모노레포 ↓↓ | 높음 (unbundle 필요) | 높음 |
| 삭제 | 0 | 가장 작음 | 비가역 | 매우 위험 |

**평가**: **정당화 OK**.

**근거**:
- same-repo 디렉터리 보존이 별도 repo·branch보다 git history 단절 없음 (단일 commit log)
- 모노레포 정책 (`server/`, `mobile/`, `shared/`, `docs/`)와 정합
- 디스크 부담 ≈ 무시 가능 (6 KB Ruby + ERB)
- 회귀 시 디렉터리 이동만으로 활성화 — 가장 가역

**약점 (Brief가 명시 안 함)**:
- "6개월 이상" 기간이 모호 — 어떤 조건에서 영구 삭제 가능?
- branch 보존 (`archive/rails`)도 동등 옵션 — same-repo 대비 working tree 가벼움

**권고**:
- Decision 10에 "12개월 시점 가정 재검증 후 영구 삭제 여부 결정" 명시
- 또는 6개월·12개월 retrospective 트리거 명시 (Critical Review Request와 정렬)

---

### Decision 11 — 환경 분리 (Production / Preview / Staging)

**Brief 선택**: 3환경. 정당화: PR 단위 preview 자동.

**대안 비교**

| 옵션 | DB 격리 | 비용 | PR 검증 |
|------|----|----|----|
| **3환경 (Production/Preview/Staging)** | 환경별 D1 분리 | Free tier 처리 가능 | PR preview URL 자동 |
| 2환경 (Production/Preview) | Production + Preview 공유 또는 분리 | 저렴 | PR preview 가능 |
| 1환경 (Production만) | 단일 D1 | 가장 저렴 | PR 검증 어려움 |

**평가**: **정당화 OK** (단 Staging 필요성 명시 약함).

**근거**:
- Wrangler 환경별 deploy + D1 binding 분리 — Free tier 내 처리 가능
- PR preview는 [`workers.dev` subdomain 자동](https://developers.cloudflare.com/workers/configuration/previews/)
- Staging은 Production 전 final smoke test에 유용 (특히 Cutover 단계)

**약점**:
- Staging vs Preview 차이가 모호 — Preview는 PR 단위 ephemeral, Staging은 long-lived?
- 환경별 D1 분리 시 schema migration 동기화 부담

**권고**:
- Decision 11에 "Preview = PR 단위 ephemeral, Staging = long-lived smoke test 환경" 명시
- 또는 Staging 생략 후 "Production 직전 smoke test는 Preview에서" 단순화

---

### Decision 12 — 도메인 (multi-subdomain vs path)

**Brief 선택**: `api.<도메인>` + `admin.<도메인>`. 정당화: 관심사 분리, 각각 다른 Worker 가능.

**대안 비교**

| 옵션 | Cookie 공유 | CORS | Same-origin 보안 | 운영 복잡도 |
|------|----|----|----|----|
| **api.<도메인> + admin.<도메인>** | `.<root>` cookie 또는 JWT | preflight 필요 | Cross-site (Chrome 2024+ SameSite=None+Secure 필수) | 중간 |
| 단일 도메인 + path (`/api/`, `/admin/`) | Same-origin 자동 | 불필요 | Same-origin (강함) | 낮음 |
| api.<도메인> (mobile) + Cloudflare Access (admin path) | N/A (Access SSO) | N/A | Access 보호 | 중간 (Access 학습) |

**평가**: **약화 — Brief 명시 필요**.

**핵심 약점**:

1. **멀티 서브도메인의 cookie complexity 약하게 평가됨**:
   - `.<도메인>` cookie 공유는 가능하나 [Chrome Cross-Site Cookies 정책](https://docs.descope.com/security-best-practices/crossite-cookies)으로 인해 third-party context에서 깨짐
   - SameSite=None+Secure 강제 — admin → API XHR 시 추가 설정
   - JWT는 가능하나 mobile API에는 적합, admin SSR에는 cookie session이 더 자연스러움

2. **단일 도메인 + path 분리의 강점 명시 부재**:
   - same-origin 자동 — cookie/CORS 복잡도 0
   - Workers Routes는 path-level 라우팅 지원 — 단일 도메인 + path별 다른 Worker 가능
   - admin 보호는 Cloudflare Access (Free tier) + path 필터로 가능 (Brief 가정 "admin 보호 약함" 약함)

3. **Hybrid 옵션 미고려**:
   - api.<도메인> (mobile, public) + 단일 도메인 + /admin path + Cloudflare Access (admin)
   - admin은 운영자만 접근 → public 노출 없음

**권고**:
- Decision 12에 path-based 단일 도메인 옵션 명시적 비교
- 또는 hybrid (mobile = subdomain, admin = path + Access) 검토
- 결정 유지 시 "cookie domain `.<root>` + SameSite=None+Secure" 운영 가이드 명시

**Source**: [MDN cross-site cookies](https://docs.descope.com/security-best-practices/crossite-cookies)

---

### Decision 13 — 글로벌 결제 (대안 PG)

**Brief 선택**: 연기. 정당화: Stripe Korea 부재.

**대안 비교**

| 옵션 | 한국 가맹점 | 글로벌 카드 | 통화 | 검토 가치 |
|------|----|----|----|----|
| **Stripe (해외 법인)** | 불가 | 강함 | 다중 | 해외 법인 시점에 |
| Stripe via NICEPay 파트너십 | 제한적 | 부분 | 한국 원화 위주 | 낮음 |
| PayPal | 한국 사업자 가능 | 강함 | 다중 | **검토 가치** |
| Adyen | 한국 가능 (대규모) | 매우 강함 | 다중 | 대형 사업자 시점 |
| Wise (TransferWise) | 가능 | 송금 강함 | 다중 | 송금/sub만 |
| Toss + 별도 글로벌 PG 이중 운영 | 가능 | 가능 | 다중 | 운영 부담 ↑ |

**평가**: **정당화 OK** (단 대안 PG 명시 약함).

**근거**:
- Stripe Korea 가맹점 부재는 사실 (연구 010 P3 검증)
- 한국 우선 service는 Toss로 충분 — 글로벌 결제 즉시 도입은 over-engineering

**약점**:
- "연기"의 시점 정의 부재 — 6개월? 12개월? 무한정?
- Stripe 외 글로벌 PG (PayPal, Adyen) 검토 부재 — Stripe만 글로벌 옵션 아님
- 한국 사용자 = Toss + 글로벌 사용자 = 별도 PG 동시 운영 시나리오 미언급

**권고**:
- Decision 13에 "재검토 시점 (예: 6개월·12개월 retrospective)" 명시
- "Stripe 외 글로벌 PG (PayPal/Adyen) — 한국 사업자로 가능, 별도 phase 검토" 1줄 추가

**Source**: [Stripe Korea 부재 연구 010 P3](../01_cloudflare_migration_research/005_Agent_payment_integration.md)

---

### Meta — Phase 분리 / Quality Profile

**Brief 메타 결정**:
- Quality Profile = Standard
- In Scope 13개 단일 phase
- deep_critique = false (별도 critique 사이클 없음)

**평가**: **약화 — Brief 명시 필요**.

**핵심 약점**:

1. **30.5 MW 작업에 Quality Profile = Standard는 약함**:
   - 비교: 6개월~9개월 빌드 + 13 리스크 수용 = 고위험 작업
   - Polish 채택 시 추가 critique cycle, eval 횟수 ↑
   - Cutover Safety가 priority dimension에 추가됐지만 Quality Profile 자체는 Standard

2. **In Scope 13개의 단일 phase 부담**:
   - Phase A (인프라+API+결제), Phase B (admin), Phase C (archive)는 Cutover 한정
   - In Scope 자체는 13개 동시 작업 가정 — 우선순위·의존성 그래프 부재
   - scope 단계에서 분해되겠지만 Brief 단계에서 핵심 클러스터 (인프라 / 도메인 이식 / API / admin / 결제 / 테스트 / cutover)는 그룹화 가능

3. **deep_critique = false의 정당성**:
   - 연구 010이 "deep critique 역할"을 한다는 가정 — 그러나 010은 Stay/Partial/Full 결정에 집중, autonomous 결정 11개에는 검증 약함
   - 본 critique 005가 W1 (Lucia sunset)을 발견 — deep critique의 가치 입증

**권고**:
- Brief 메타: Quality Profile을 Polish로 상향 또는 deep_critique = true로 변경
- In Scope를 우선순위 그룹 (인프라 → 도메인 이식 → API/admin → 결제 → 테스트 → cutover)으로 표시
- 또는 In Scope를 Phase A/B/C에 정렬 (현재 Decision 9 phase와 In Scope 13개의 매핑이 약함)

---

## Recommendations for Brief Revision

| # | Recommendation | Rationale | Affected Decision/Anchor |
|---|----------------|-----------|--------------------------|
| R1 | **Decision 8 + Model Anchor 13에서 "Lucia" 제거**, "BetterAuth + Cloudflare Access (admin) hybrid"로 정정 | Lucia 2024-Q4 sunset 사실 (Critical) | Decision 8, Anchor 13 |
| R2 | **Decision 4를 "Hono SSR + JSX renderer + HTMX + vanilla JS 보조"로 구체화**, Astro 기각 사유 정정 ("CF 인수, GA 어댑터 보유, 단 별도 빌드 시스템 trade-off") | Astro 2026-01 CF 인수 + Hono+HTMX 강력 evidence | Decision 4 |
| R3 | **Decision 7에 `@cloudflare/vitest-pool-workers` 명시** + Playwright (E2E, optional) 추가 | Workers + D1 binding 통합 테스트 표준 | Decision 7, Anchor 10 |
| R4 | **Decision 9에 traffic shift / B→A→C 순서 옵션 명시** | CF Workers Gradual Deployments GA, Cutover Safety 강화 | Decision 9 |
| R5 | **Decision 12에 path-based 단일 도메인 옵션 비교** + admin은 Cloudflare Access hybrid 검토 | cookie/CORS 복잡도 trade-off 명시 | Decision 12 |
| R6 | **Decision 5/6에 결제 LOC 범위 + PortOne 도입 트리거 3개 명시** | "50 LOC"는 1회결제 한정, PortOne 트리거 모호 | Decision 5, 6 |
| R7 | **Brief 메타: Quality Profile = Polish 상향 또는 deep_critique = true** | 30.5 MW + 13 리스크 작업, Lucia sunset 같은 사실 오류 발견 가능 | Brief metadata |

## References

| Resource | Path/URL | Relevance |
|----------|----------|-----------|
| Brief 001 (대상) | `./001_Brief_cf_workers_rebuild.md` | 비평 대상 |
| 연구 010 | `../01_cloudflare_migration_research/010_Research_cloudflare_migration.md` | 결정 근거 traces |
| CF 스택 capability | `../01_cloudflare_migration_research/004_Agent_cloudflare_stack_capabilities.md` | Workers/D1 한도 |
| Drizzle vs Prisma 2026 | https://encore.dev/articles/drizzle-vs-prisma | Decision 3 |
| Drizzle vs Kysely 2025 | https://marmelab.com/blog/2025/06/26/kysely-vs-drizzle.html | Decision 3 |
| Prisma D1 미지원 | https://www.prisma.io/docs/orm/more/comparisons/prisma-and-drizzle | Decision 3 |
| Hono+HTMX+Cloudflare (Yusuke Wada) | https://blog.yusu.ke/hono-htmx-cloudflare/ | Decision 4 |
| Hono JSX renderer middleware | https://hono.dev/docs/middleware/builtin/jsx-renderer | Decision 4 |
| Cloudflare Astro adapter (2026) | https://developers.cloudflare.com/workers/framework-guides/web-apps/astro/ | Decision 4 |
| Astro 6 + workerd (CF 인수) | https://alexbobes.com/programming/a-deep-dive-into-astro-build/ | Decision 4 |
| PortOne docs 2026 | https://docs.portone.cloud/docs/portone-korea | Decision 5, 6 |
| PortOne disintermediation | https://sacra.com/c/portone/ | Decision 5, 6 |
| Cloudflare Vitest integration | https://developers.cloudflare.com/workers/testing/vitest-integration/ | Decision 7 |
| Hono Cloudflare Testing example | https://hono.dev/examples/cloudflare-vitest | Decision 7 |
| BetterAuth vs Lucia vs NextAuth 2026 | https://www.pkgpulse.com/blog/better-auth-vs-lucia-vs-nextauth-2026 | Decision 8 (Critical) |
| @better-auth/cloudflare | https://github.com/zpg6/better-auth-cloudflare | Decision 8 |
| Hono Better Auth on Cloudflare | https://hono.dev/examples/better-auth-on-cloudflare | Decision 8 |
| Cloudflare Access (Zero Trust) | https://developers.cloudflare.com/cloudflare-one/ | Decision 8 |
| CF Workers Gradual Deployments | https://blog.cloudflare.com/workers-production-safety/ | Decision 9 |
| Versions & Deployments | https://developers.cloudflare.com/workers/configuration/versions-and-deployments/ | Decision 9 |
| Cross-Site Cookies (Descope) | https://docs.descope.com/security-best-practices/crossite-cookies | Decision 12 |

## Communication Log

| # | Direction | Peer | Summary | Stage |
|---|-----------|------|---------|-------|
| 1 | OUT | Critique (sustainability) | Decision 8 Lucia sunset → 양쪽 비평 모두 발견 가능 (다른 비평 발견 시 cross-confirm) | initial |
| 2 | OUT | Critique (cutover_safety) | Decision 9 traffic shift / B→A→C 순서 — cutover safety 관점과 겹침 | initial |
| 3 | OUT | Critique (longevity) | Decision 4 Astro 재평가 — 장기 단일 벤더(CF가 Astro 인수) 정합 관점과 겹침 | initial |
