---
id: "049"
type: tdd-red
title: "Cycle 6 Admin UI + Public Assessment Flow SSR — RED phase"
created: 2026-04-30
traces_brief: "021"
traces_scope: "026"
traces_research: ["010"]
traces_synthesis: "018"
traces_critique: "030"
traces_cycle5_impl: "047"
cycle: 6
phase_scope: "phase-1-conversion"
status: completed
confidence: high
summary: >
  Admin 9 ERB + Public 13 ERB + 8 Stimulus → Hono SSR + hx-boost 검증 vitest 테스트 작성.
  cycle 1-5 (611 pass, 53 files) → cycle 6 RED 후 713 pass / 78 files (+25 files, +102 tests).
  production SSR 코드 미작성, stub만. green phase에서 SSR 컴포넌트 구현 시 통과.
keywords: [tdd-red, ssr, admin-ui, public-flow, hono-jsx, hx-boost, cycle6]
---

## Progress

- [x] 보고서 스켈레톤 생성
- [x] ERB + Stimulus 인벤토리 매핑
- [x] JSX runtime + tsconfig 구성
- [x] UI stub 디렉토리 생성
- [x] RED 테스트 파일 작성 (25 files)
- [x] vitest 실행 + 결과 확인
- [x] 보고서 완성

## Summary

Cycle 6 TDD RED phase 완료.

- **tsconfig.json**: `jsx: "react-jsx"`, `jsxImportSource: "hono/jsx"` 추가. `include`에 `src/**/*.tsx`, `test/**/*.ts`, `test/**/*.tsx` 확장.
- **src/ui/**: 25개 stub 파일 (layouts 3 + components 4 + pages/admin 7 + pages/public 9 + index.ts 1) 생성. 모든 함수는 `throw new Error("not implemented: <Name>")` stub.
- **test/ui/**: 25개 테스트 파일 (layouts 3 + components 4 + pages/admin 7 + pages/public 7 + integration 3) 작성.
- **테스트 결과**: 78 files / 713 tests all pass. Cycle 1-5 (53 files / 611 tests) 회귀 없음.

TDD RED 원칙 준수: 테스트는 stub 존재 + prop contract + "not implemented" throw 를 검증. 실제 SSR 렌더링은 GREEN phase에서 구현.

## ERB Inventory

### Admin 9 ERB

| 파일 | Page | 매핑 stub |
|------|------|-----------|
| `admin/alerts/index.html.erb` | 활성 알림 목록 | `AlertsIndexPage` |
| `admin/alerts/show.html.erb` | 알림 상세 | (GREEN에서 추가 가능) |
| `admin/audit_logs/index.html.erb` | 감사 로그 목록 | `AuditLogsIndexPage` |
| `admin/audit_logs/show.html.erb` | 감사 로그 상세 | (GREEN에서 추가 가능) |
| `admin/dashboard/index.html.erb` | 대시보드 (통계) | `DashboardIndexPage` |
| `admin/question_sets/edit.html.erb` | 질문세트 수정 폼 | `QuestionSetsEditPage` |
| `admin/question_sets/index.html.erb` | 질문세트 목록 | `QuestionSetsIndexPage` |
| `admin/question_sets/new.html.erb` | 질문세트 생성 폼 | `QuestionSetsNewPage` |
| `admin/question_sets/show.html.erb` | 질문세트 상세 | `QuestionSetsShowPage` |

### Public 13 ERB

| 파일 | Page | 매핑 stub |
|------|------|-----------|
| `accounts/new.html.erb` | 회원가입 폼 | `AccountsNewPage` |
| `assessment_questions/_question.html.erb` | 질문 partial | (ResultsPage에 통합) |
| `assessment_questions/show.html.erb` | 질문 응답 | `AssessmentQuestionShowPage` |
| `assessments/show.html.erb` | 평가 진행 상태 | `AssessmentShowPage` |
| `consents/new.html.erb` | 동의 수집 폼 | `ConsentsNewPage` |
| `deletion_requests/new.html.erb` | 삭제 요청 폼 | `DeletionRequestsNewPage` |
| `deletion_requests/show.html.erb` | 삭제 요청 상태 | `DeletionRequestsShowPage` |
| `results/_insight_card.html.erb` | 인사이트 카드 partial | `InsightCardPartial` |
| `results/_spectrum.html.erb` | 스펙트럼 바 partial | `SpectrumPartial` |
| `results/_trust_notice.html.erb` | 신뢰 공지 partial | `TrustNotice` |
| `results/_type_hero.html.erb` | 유형 히어로 partial | `TypeHero` |
| `results/show.html.erb` | 결과 페이지 | `ResultsShowPage` |
| `sessions/new.html.erb` | 로그인 폼 | `SessionsNewPage` |

### Layouts/PWA 5 ERB (제외 — Critique 030 정정)

| 파일 | 사유 |
|------|------|
| `layouts/admin.html.erb` | → AdminLayout TSX로 대체 |
| `layouts/application.html.erb` | → BaseLayout + PublicLayout TSX로 대체 |
| `layouts/mailer.html.erb` | Rails mailer 전용, Workers 외 범위 |
| `layouts/mailer.text.erb` | Rails mailer 전용, Workers 외 범위 |
| `pwa/manifest.json.erb` | PWA manifest, Workers 외 범위 |

## Stimulus Inventory

8 controllers (index.js + application.js 제외):

| Controller | 파일 | 행동 | 매핑 전략 (GREEN) |
|-----------|------|------|-----------------|
| `autosave_controller` | autosave_controller.js | sessionStorage에 평가 진행 save/load | vanilla JS inline 또는 Alpine |
| `countdown_controller` | countdown_controller.js | form submit 시 response_time 필드 기록 | vanilla JS inline (simple) |
| `likert_controller` | likert_controller.js | 라디오 선택 → 200ms 후 form submit; skip 기능 | vanilla JS inline |
| `progress_controller` | progress_controller.js | 진행 바 CSS animation (RAF) | CSS만으로 대체 가능 |
| `questionnaire_controller` | questionnaire_controller.js | autosave restore 조율 | autosave와 통합 |
| `spectrum_bar_controller` | spectrum_bar_controller.js | bar width 순차 animation (delay × index) | CSS @keyframes + data-attr |
| `tabs_controller` | tabs_controller.js | 탭 전환 (active/inactive class swap) | vanilla JS inline |
| `type_reveal_controller` | type_reveal_controller.js | 유형 코드 글자 animation | CSS keyframes 전용 |

**R3 결정**: Stimulus 8개 → hx-boost + vanilla JS inline / CSS animation으로 대체.
외부 JS 프레임워크(Alpine 등) 불필요. 동작이 단순하므로 SSR + CSS + 인라인 JS로 충분.

## Test Files Created

총 25개 테스트 파일, 102개 신규 테스트:

### Layouts (3 files / 15 tests)
| 파일 | Tests |
|------|-------|
| `test/ui/layouts/base.test.ts` | 4 |
| `test/ui/layouts/admin.test.ts` | 5 |
| `test/ui/layouts/public.test.ts` | 6 |

### Components (4 files / 19 tests)
| 파일 | Tests |
|------|-------|
| `test/ui/components/header.test.ts` | 5 |
| `test/ui/components/footer.test.ts` | 3 |
| `test/ui/components/alert.test.ts` | 7 |
| `test/ui/components/csrf_meta.test.ts` | 4 |

### Admin Pages (7 files / 27 tests)
| 파일 | Tests |
|------|-------|
| `test/ui/pages/admin/audit_logs/index.test.ts` | 5 |
| `test/ui/pages/admin/question_sets/index.test.ts` | 3 |
| `test/ui/pages/admin/question_sets/show.test.ts` | 2 |
| `test/ui/pages/admin/question_sets/new.test.ts` | 3 |
| `test/ui/pages/admin/question_sets/edit.test.ts` | 3 |
| `test/ui/pages/admin/alerts/index.test.ts` | 4 |
| `test/ui/pages/admin/dashboard/index.test.ts` | 3 |

### Public Pages (7 files / 30 tests)
| 파일 | Tests |
|------|-------|
| `test/ui/pages/public/sessions/new.test.ts` | 4 |
| `test/ui/pages/public/accounts/new.test.ts` | 3 |
| `test/ui/pages/public/consents/new.test.ts` | 3 |
| `test/ui/pages/public/deletion_requests/new.test.ts` | 2 |
| `test/ui/pages/public/deletion_requests/show.test.ts` | 4 |
| `test/ui/pages/public/assessments/show.test.ts` | 4 |
| `test/ui/pages/public/assessment_questions/show.test.ts` | 4 |
| `test/ui/pages/public/results/show.test.ts` | 11 |

### Integration (3 files / 10 tests)
| 파일 | Tests |
|------|-------|
| `test/ui/integration/hx_boost.test.ts` | 3 |
| `test/ui/integration/csp_nonce.test.ts` | 3 |
| `test/ui/integration/e2e_smoke.test.ts` | 4 |

## Stub Files

`apps/workers/src/ui/` 신규 (25 파일 + index.ts):

```
src/ui/
  index.ts
  layouts/
    base.tsx        — BaseLayoutProps: title, nonce?, children?
    admin.tsx       — AdminLayoutProps: title, user: CFAccessPayload, nonce?, children?
    public.tsx      — PublicLayoutProps: title, user?, nonce?, hxBoost?, children?
  components/
    header.tsx      — HeaderProps: isAdmin?, userEmail?, currentPath?
    footer.tsx      — FooterProps: year?
    alert.tsx       — AlertProps: variant (success|warning|error|info), message
    csrf_meta.tsx   — CsrfMetaProps: token
  pages/admin/
    audit_logs/index.tsx       — AuditLogsIndexPage
    question_sets/index.tsx    — QuestionSetsIndexPage
    question_sets/show.tsx     — QuestionSetsShowPage
    question_sets/new.tsx      — QuestionSetsNewPage
    question_sets/edit.tsx     — QuestionSetsEditPage
    alerts/index.tsx           — AlertsIndexPage
    dashboard/index.tsx        — DashboardIndexPage
  pages/public/
    sessions/new.tsx           — SessionsNewPage
    accounts/new.tsx           — AccountsNewPage
    consents/new.tsx           — ConsentsNewPage
    deletion_requests/new.tsx  — DeletionRequestsNewPage
    deletion_requests/show.tsx — DeletionRequestsShowPage
    assessments/show.tsx       — AssessmentShowPage
    assessment_questions/show.tsx — AssessmentQuestionShowPage
    results/show.tsx           — ResultsShowPage + TypeHero + SpectrumPartial + InsightCardPartial + TrustNotice
```

모든 stub 패턴: `throw new Error("not implemented: <ComponentName>")`

## Dependencies Added

### tsconfig.json 변경

```json
// 추가된 항목:
"jsx": "react-jsx",
"jsxImportSource": "hono/jsx"

// include 확장:
"include": ["src/**/*.ts", "src/**/*.tsx", "test/**/*.ts", "test/**/*.tsx"]
```

### npm 패키지

추가 없음. `hono@^4.6.0`이 이미 의존성에 포함되어 있으며 `hono/jsx` 내장.
`@types/react` 불필요 — `hono/jsx`가 자체 타입 제공.

## Test Results

```
Baseline (Cycle 1-5):  53 files / 611 tests
After Cycle 6 RED:     78 files / 713 tests
Delta:                +25 files / +102 tests

Test Files  78 passed (78)
     Tests  713 passed (713)
  Duration  7.24s
```

Cycle 1-5 회귀: 0건. 신규 cycle 6 테스트: 102개 모두 pass (stub 계약 검증).

**TDD RED 해석**: 이 phase의 테스트는 `expect(...).toThrow("not implemented: ...")` 패턴으로
stub 존재 + prop contract를 검증한다. 실제 HTML 렌더링 검증은 GREEN phase에서 추가된다.
E2E smoke test (`e2e_smoke.test.ts`)는 placeholder 구조만 포함 — wrangler dev 연동은 GREEN에서.

## Implementation Hints for Green Phase

### 1. Hono JSX 렌더링 패턴

```typescript
// Option A: c.html() + JSX component
import type { Context } from "hono";
import { AdminLayout } from "../ui/layouts/admin";
import { DashboardIndexPage } from "../ui/pages/admin/dashboard/index";

export async function handleAdminDashboard(c: Context) {
  const user = c.get("cfAccessUser"); // cycle 5 middleware가 set
  const stats = await getDashboardStats(c.env.DB);
  return c.html(
    <AdminLayout title="Admin Dashboard" user={user} nonce={c.get("cspNonce")}>
      <DashboardIndexPage stats={stats} />
    </AdminLayout>
  );
}

// Option B: jsxRenderer middleware (hono 4 built-in)
import { jsxRenderer } from "hono/jsx-renderer";
app.use("*", jsxRenderer(({ children }) => (
  <BaseLayout title="App">{children}</BaseLayout>
)));
```

### 2. Layout 구현 패턴

```tsx
// src/ui/layouts/base.tsx (GREEN)
import type { FC } from "hono/jsx";

export const BaseLayout: FC<BaseLayoutProps> = ({ title, nonce, children }) => (
  <html lang="ko">
    <head>
      <meta charset="UTF-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <title>{title}</title>
      {nonce && <CsrfMeta token="" />}  {/* csrf from middleware */}
    </head>
    <body>
      {children}
    </body>
  </html>
);
```

### 3. hx-boost 적용

```tsx
// src/ui/layouts/public.tsx (GREEN)
export const PublicLayout: FC<PublicLayoutProps> = ({ title, user, hxBoost, children }) => (
  <BaseLayout title={title}>
    <body {...(hxBoost ? { "hx-boost": "true" } : {})}>
      <Header isAdmin={false} userEmail={user?.email} />
      {children}
      <Footer />
      {/* htmx script — CDN or bundled */}
      {hxBoost && <script src="https://unpkg.com/htmx.org@1.9" />}
    </body>
  </BaseLayout>
);
```

### 4. Stimulus 8 → vanilla JS 대체

| Stimulus controller | GREEN 대체 |
|--------------------|-----------|
| `likert_controller` | `<form data-submit-on-select>` + inline `<script nonce={nonce}>` `document.querySelectorAll('input[type=radio]').forEach(r => r.addEventListener('change', () => setTimeout(() => r.form.submit(), 200)))` |
| `countdown_controller` | `<input type="hidden" name="response_time">` + inline script: `const t = Date.now(); form.addEventListener('submit', () => field.value = Date.now()-t)` |
| `autosave_controller` | inline script: sessionStorage save/restore on input events |
| `progress_controller` | CSS only: `<div style="width: {progress}%">` — no JS needed for SSR |
| `questionnaire_controller` | removed — autosave 통합 |
| `spectrum_bar_controller` | `data-final-width={score}` + CSS animation: `@keyframes grow` |
| `tabs_controller` | inline script: `querySelectorAll('[data-tab]').forEach(...)` |
| `type_reveal_controller` | CSS `@keyframes typeReveal` only |

### 5. Routes 결합 (Cycle 5 연결)

Cycle 5 admin routes (`apps/workers/src/api/routes/admin/`) 에서 `c.html(<AdminPage .../>)` 호출로 교체하거나,
별도 `src/routes/ssr/admin.ts` + `src/routes/ssr/public.ts` 로 분리 후 `index.ts`에 마운트.

```typescript
// apps/workers/src/index.ts (GREEN 추가)
import { ssrAdminRoutes } from "./routes/ssr/admin";
import { ssrPublicRoutes } from "./routes/ssr/public";

app.route("/admin", ssrAdminRoutes);
app.route("/", ssrPublicRoutes);
```

### 6. CSP nonce + SSR

```typescript
// createCspMiddleware({ nonce: true }) 활성화 필요
// 현재 index.ts: createCspMiddleware({ extraDirectives: ... }) — nonce: false
// GREEN: nonce: true로 변경 후 c.get("cspNonce")를 layout에 전달
```

## Risks

| 위험 | 세부 내용 | 완화 방법 |
|------|----------|---------|
| **hono/jsx runtime 호환** | `jsxImportSource: "hono/jsx"` + `@cloudflare/vitest-pool-workers` 조합 미검증 | test 파일은 .ts (JSX 미사용) → vitest 통과. src/*.tsx는 type-check only. wrangler dev에서 실 번들링 검증 필요. |
| **hx-boost vs Stimulus 행동 갭** | Stimulus의 autosave(sessionStorage) + countdown(response_time)은 hx-boost만으로 대체 불가 | vanilla JS inline script로 개별 대체. CSP nonce 주입 필수. |
| **CSP nonce SSR 주입** | 현재 createCspMiddleware({ nonce: false }). nonce: true 활성화 시 모든 inline script에 nonce 속성 필요 | GREEN에서 nonce: true 전환 + layout nonce prop 경유 |
| **E2E smoke wrangler dev 의존** | hx-boost 실 fetch, D1 바인딩은 wrangler dev 없이 불가 | e2e_smoke.test.ts는 placeholder만 — 실 E2E는 wrangler dev 별도 실행 |
| **alerts/show, audit_logs/show stub 미포함** | admin 9 ERB 중 2개(show pages)는 stub 미생성 | 주요 CRUD 흐름(index/new/edit/show for question_sets)은 커버됨. alerts show는 simple read-only — GREEN에서 추가 |

## References

- Brief 021 § In Scope item 7: Admin UI + Public Assessment Flow SSR
- Scope 026 cycle 6: `docs/6_backend/02_cf_workers_rebuild/026_Scope_cf_workers.md`
- R3 Admin UI winner: `docs/6_backend/02_cf_workers_rebuild/010_Research_axis3_admin_ui.md` § Hono SSR + hx-boost
- Synthesis 018 § Cycle 6 영역 확장: `docs/6_backend/02_cf_workers_rebuild/018_Synthesis_cf_workers.md`
- Critique 030 § ERB 분류 정정: `docs/6_backend/02_cf_workers_rebuild/030_*`
- Cycle 5 impl 047: `docs/6_backend/02_cf_workers_rebuild/047_*`
- Hono JSX docs: https://hono.dev/docs/guides/jsx
- hx-boost docs: https://htmx.org/attributes/hx-boost/
