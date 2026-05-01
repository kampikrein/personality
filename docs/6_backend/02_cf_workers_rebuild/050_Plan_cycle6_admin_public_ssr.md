---
id: "050"
type: plan
title: "Cycle 6 Admin UI + Public Flow SSR GREEN Plan"
created: 2026-05-01
traces_brief: "021"
traces_scope: "026"
traces_red: "049"
traces_research: ["010"]
traces_synthesis: "018"
traces_critique: "030"
traces_cycle5_impl: "047"
cycle: 6
phase_scope: "phase-1-conversion"
status: completed
confidence: high
red_antipattern_acknowledged: true
summary: >
  Cycle 6 SSR GREEN plan. Admin 9 ERB + Public 13 ERB + 8 Stimulus → Hono SSR + hx-boost 옵셔널.
  RED 049의 expect.toThrow 안티패턴 보강 (component 동작 검증으로 전환). 0 fail / 713 pass 목표 + 테스트 의미성 회복.
keywords: [plan, ssr, admin-ui, public-flow, hono-jsx, hx-boost, cycle6, green, antipattern-fix]
---

## Goal

**주 목표**: 0 fail / 713 pass 달성. Cycle 1–5 회귀(611 tests) 없음 + Cycle 6 신규(102 tests) 모두 green.

**부 목표: RED 안티패턴 해소**

RED 049의 102 테스트 전부가 `expect(...).toThrow("not implemented: ...")` 패턴으로 pass 상태다. 이는 stub의 존재와 prop contract만을 검증하는 TDD RED 의도였으나, GREEN impl에서 component가 실제로 throw하지 않으면 해당 테스트들이 일제히 fail로 역전된다. 본 plan은 이 안티패턴을 제거하고 테스트 의미성을 회복하는 것을 GREEN의 선행 조건으로 설정한다.

**변환 목표**: `expect(() => Comp(props)).toThrow()` → `expect(html).toContain('<expected element>')` 패턴으로 전면 전환.

**Brief 021 Ideal Criteria 매핑**:
- **#7** (Admin 9 ERB Hono SSR 1:1 기능 동등): Step 3에서 달성
- **#10** (공개 평가 흐름 18 ERB + 8 Stimulus hx-boost 동작): Step 4에서 달성
- Ideal Criteria #21/#22 (assertion 7): wrangler dev direct fetch smoke (Step 5)로 검증

---

## Scope

### Included

| 영역 | 내용 |
|------|------|
| Admin SSR | 9 ERB → TSX: alerts/index, audit_logs/index, dashboard/index, question_sets/{index,show,new,edit} + GREEN 추가 2개(alerts/show, audit_logs/show) |
| Public SSR | 13 ERB → TSX: sessions/new, accounts/new, consents/new, deletion_requests/{new,show}, assessment_questions/show, assessments/show, results/show (+4 partials: TypeHero, SpectrumPartial, InsightCardPartial, TrustNotice) |
| 공유 컴포넌트 | header.tsx, footer.tsx, alert.tsx (variant: success/warning/error/info), csrf_meta.tsx |
| 레이아웃 | BaseLayout, AdminLayout, PublicLayout (3) |
| 8 Stimulus → vanilla | likert, countdown, autosave, questionnaire, progress, spectrum_bar, tabs, type_reveal |
| hx-boost attribute | PublicLayout body에 `hx-boost="true"` 조건부 + htmx CDN script 1줄 |
| CSP nonce 주입 | createCspMiddleware({ nonce: true }) 전환 + c.get("cspNonce") → layout → inline script nonce |
| Routes 결합 | Cycle 5 admin/*.ts + public/*.ts routes에서 c.html(<Page />) 호출 |
| E2E smoke | hono app.fetch() direct invoke (wrangler dev 없이 검증 가능) |
| 테스트 보강 (Step 0) | 25 test file의 expect.toThrow 패턴 → component 동작 검증으로 전환 |

### Excluded

| 영역 | 이유 |
|------|------|
| 실 wrangler dev 실행 | Phase 2 carryover (외부 런타임 의존) |
| Playwright 풀 E2E | Ideal Criteria #18 — Phase 2 검증 |
| Responsive design tuning | Phase 2 |
| admin SSR 인증 structural parser | cfAccessVerifier Phase 1에서 verifier-only; Phase 2 완전 대체 |
| Rails mailer 레이아웃 | Workers 범위 밖 |
| 새 의존성 추가 | hono@^4.6.0 기 포함, typed-htmx는 옵셔널(이미 검토 완료, 불필요) |

---

## RED Antipattern Acknowledgement

### 문제 요약

RED 049에서 생성된 102 테스트는 다음 패턴을 사용한다:

```typescript
// RED 049의 전형 패턴 (모든 25 test file에 걸쳐 반복)
it("renders html structure with title", () => {
  expect(() =>
    BaseLayout({ title: "Test Page" })
  ).toThrow("not implemented: BaseLayout");
});
```

stub이 `throw new Error("not implemented: BaseLayout")` 이기 때문에 위 테스트는 현재 모두 **pass**다. TDD RED 단계에서 stub 계약 검증으로는 적합하지만, GREEN impl이 실 컴포넌트를 작성하면 throw 대신 JSX를 반환하므로 위 테스트는 **fail로 역전**된다.

### 영향 분석

- 영향 범위: 25 test file × (거의 모든 it 블록) ≈ 80~90개의 토글 위험 테스트
- 역전 시점: Step 1 (Layouts) 구현 직후부터 연쇄 fail 발생
- 회귀처럼 보이는 false positive: 711 pass → 609 pass처럼 보이나, 실제로는 구현이 성공한 신호

### 해결 방안: 옵션 보강-A (권장)

테스트를 **component 동작 검증으로 전환**한다. GREEN impl보다 선행하는 **Step 0**으로 분리한다.

**전환 패턴표**:

| 기존 (RED 패턴) | 전환 후 (GREEN 패턴) |
|----------------|---------------------|
| `expect(() => Comp(props)).toThrow("not implemented: X")` | `const html = renderToString(Comp(props)); expect(html).toContain('<expected>')` |
| `expect(() => BaseLayout({ title: "T" })).toThrow(...)` | `expect(html).toContain('<title>T</title>')` |
| `expect(() => Alert({ variant: "error", message: "X" })).toThrow(...)` | `expect(html).toContain('class="alert-error"'); expect(html).toContain('X')` |
| `expect(() => PublicLayout({ ..., hxBoost: true })).toThrow(...)` | `expect(html).toContain('hx-boost="true"')` |
| `expect(() => BaseLayout({ nonce: "abc" })).toThrow(...)` | `expect(html).toContain('nonce="abc"')` |
| `expect(() => CsrfMeta({ token: "T" })).toThrow(...)` | `expect(html).toContain('name="csrf-token"'); expect(html).toContain('content="T"')` |

**renderToString 확보 방법**:

hono/jsx는 `hono/jsx/dom`의 `renderToString`보다 `hono/jsx`의 `jsxRenderer` 또는 hono 4.x의 `c.html(jsx)`를 경유한다. 테스트에서는 컴포넌트 함수를 직접 호출하면 JSXNode 객체가 반환되므로, `String()` 캐스팅 또는 hono's built-in `renderToString`을 사용한다.

```typescript
import { renderToString } from "hono/jsx/dom/server";
// 또는 hono가 제공하는 render 유틸리티

const html = await renderToString(BaseLayout({ title: "Test Page" }));
expect(html).toContain("<title>Test Page</title>");
```

검증할 핵심 assertion 카테고리:
1. **HTML 출력 포함 검증** (`expect(html).toContain(...)`)
2. **prop 반영** (title → `<title>`, nonce → `nonce="..."`, variant → CSS class)
3. **accessibility** (form fields: `aria-label`, `role`)
4. **CSP nonce 주입** (`<script nonce="...">`)
5. **Stimulus 대체 inline JS 내용** (`script` 태그 content grep)
6. **hx-boost attribute** (`hx-boost="true"` on body)

### Step 0 완료 기준

Step 0 후: 102 테스트가 **모두 fail** (component가 아직 stub throw → renderToString 시 error) — 이것이 올바른 TDD RED 상태의 회복이다. Cycle 1–5 테스트 611개는 0 fail 유지.

---

## Structural Decisions

### 1. hono/jsx runtime

`tsconfig.json`에 이미 적용된 설정 (RED 049 완료):
```json
{
  "compilerOptions": {
    "jsx": "react-jsx",
    "jsxImportSource": "hono/jsx"
  }
}
```

`@types/react` 불필요. hono@^4.6.0이 `hono/jsx` 내장 포함. 추가 의존성 0.

### 2. Layout / Component / Page 분리

```
src/ui/
  layouts/
    base.tsx      — BaseLayoutProps: { title, nonce?, children? }
    admin.tsx     — AdminLayoutProps: { title, user: CFAccessPayload, nonce?, children? }
    public.tsx    — PublicLayoutProps: { title, user?, nonce?, hxBoost?, children? }
  components/
    header.tsx    — HeaderProps: { user?, adminMode? }
    footer.tsx    — FooterProps: {}
    alert.tsx     — AlertProps: { variant: AlertVariant, message: string }
    csrf_meta.tsx — CsrfMetaProps: { token: string }
  pages/
    admin/
      audit_logs/{index,show}.tsx
      question_sets/{index,show,new,edit}.tsx
      alerts/{index,show}.tsx
      dashboard/index.tsx
    public/
      sessions/new.tsx
      accounts/new.tsx
      consents/new.tsx
      deletion_requests/{new,show}.tsx
      assessment_questions/show.tsx
      assessments/show.tsx
      results/show.tsx           — ResultsShowPage + TypeHero + SpectrumPartial + InsightCardPartial + TrustNotice
  index.ts                       — re-export all
```

### 3. hx-boost 통합

**방식**: PublicLayout의 `<body>` 태그에 조건부 속성 + htmx CDN script.

```tsx
// src/ui/layouts/public.tsx
export const PublicLayout: FC<PublicLayoutProps> = ({ title, nonce, hxBoost, children }) => (
  <BaseLayout title={title} nonce={nonce}>
    <body hx-boost={hxBoost ? "true" : undefined}>
      <Header />
      {children}
      <Footer />
      {hxBoost && (
        <script
          src="https://unpkg.com/htmx.org@2/dist/htmx.min.js"
          integrity="sha384-..."
          crossorigin="anonymous"
        />
      )}
    </body>
  </BaseLayout>
);
```

Phase 1에서는 attribute 존재 검증만. 실 SPA-like 전환은 Phase 2 #18 wrangler dev 검증.

### 4. CSP nonce 주입

현재 `createCspMiddleware({ nonce: false })`. GREEN에서 `nonce: true`로 전환.

```typescript
// src/index.ts 변경
app.use("*", createCspMiddleware({ nonce: true, extraDirectives: { ... } }));
```

모든 inline script에 nonce 주입 경로:
```
c.get("cspNonce") → c.html(<AdminLayout nonce={c.get("cspNonce")} />) → BaseLayout → <script nonce={nonce}>
```

### 5. Stimulus 8 → vanilla 대체

| Stimulus controller | GREEN 대체 전략 |
|---------------------|----------------|
| `likert_controller` | inline `<script nonce={nonce}>`: radio change event → 200ms 후 form.submit() |
| `countdown_controller` | inline `<script nonce={nonce}>`: Date.now() delta → hidden input |
| `autosave_controller` | inline `<script nonce={nonce}>`: sessionStorage save/restore on input |
| `questionnaire_controller` | autosave와 통합, 별도 controller 제거 |
| `progress_controller` | CSS only: `<div style={{ width: `${progress}%` }}>` — JS 불필요 |
| `spectrum_bar_controller` | `data-final-width={score}` + `@keyframes grow` CSS |
| `tabs_controller` | inline `<script nonce={nonce}>`: querySelectorAll('[data-tab]') class swap |
| `type_reveal_controller` | CSS `@keyframes typeReveal` only |

### 6. Admin SSR Route 결합 패턴 (Cycle 5 결합)

**옵션 A** (권장 — 간단): cycle 5 route handler에서 `c.html(<Page />)` 직접 호출.

```typescript
// apps/workers/src/api/routes/admin/dashboard.ts
import { Hono } from "hono";
import { DashboardIndexPage } from "../../ui/pages/admin/dashboard/index";
import type { CFAccessPayload } from "../../auth/cfAccessVerifier";

const dashboard = new Hono<{ Variables: { cfUser: CFAccessPayload; cspNonce: string } }>();

dashboard.get("/", (c) => {
  const user = c.get("cfUser");
  const nonce = c.get("cspNonce");
  return c.html(<DashboardIndexPage user={user} nonce={nonce} />);
});
```

**옵션 B**: jsxRenderer middleware 사용. 복잡도 추가 → 옵션 A 권장.

### 7. 테스트 검증 패턴 (Step 0 이후)

```typescript
import { renderToString } from "hono/jsx/dom/server";

describe("BaseLayout (GREEN phase)", () => {
  it("renders html structure with title", async () => {
    const html = await renderToString(
      BaseLayout({ title: "Test Page" })
    );
    expect(html).toContain("<title>Test Page</title>");
    expect(html).toContain("<html");
    expect(html).toContain("<body");
  });

  it("injects nonce into script tags", async () => {
    const html = await renderToString(
      BaseLayout({ title: "T", nonce: "abc123" })
    );
    expect(html).toContain('nonce="abc123"');
  });
});
```

---

## File Change Summary

### Modified (stub → 실 구현)

| 파일 경로 | 변경 유형 | Step |
|----------|----------|------|
| `src/ui/layouts/base.tsx` | stub → 구현 | Step 1 |
| `src/ui/layouts/admin.tsx` | stub → 구현 | Step 1 |
| `src/ui/layouts/public.tsx` | stub → 구현 | Step 1 |
| `src/ui/components/header.tsx` | stub → 구현 | Step 2 |
| `src/ui/components/footer.tsx` | stub → 구현 | Step 2 |
| `src/ui/components/alert.tsx` | stub → 구현 | Step 2 |
| `src/ui/components/csrf_meta.tsx` | stub → 구현 | Step 2 |
| `src/ui/pages/admin/audit_logs/index.tsx` | stub → 구현 | Step 3 |
| `src/ui/pages/admin/audit_logs/show.tsx` | 신규 생성 | Step 3 |
| `src/ui/pages/admin/question_sets/index.tsx` | stub → 구현 | Step 3 |
| `src/ui/pages/admin/question_sets/show.tsx` | stub → 구현 | Step 3 |
| `src/ui/pages/admin/question_sets/new.tsx` | stub → 구현 | Step 3 |
| `src/ui/pages/admin/question_sets/edit.tsx` | stub → 구현 | Step 3 |
| `src/ui/pages/admin/alerts/index.tsx` | stub → 구현 | Step 3 |
| `src/ui/pages/admin/alerts/show.tsx` | 신규 생성 | Step 3 |
| `src/ui/pages/admin/dashboard/index.tsx` | stub → 구현 | Step 3 |
| `src/ui/pages/public/sessions/new.tsx` | stub → 구현 | Step 4 |
| `src/ui/pages/public/accounts/new.tsx` | stub → 구현 | Step 4 |
| `src/ui/pages/public/consents/new.tsx` | stub → 구현 | Step 4 |
| `src/ui/pages/public/deletion_requests/new.tsx` | stub → 구현 | Step 4 |
| `src/ui/pages/public/deletion_requests/show.tsx` | stub → 구현 | Step 4 |
| `src/ui/pages/public/assessment_questions/show.tsx` | stub → 구현 + inline Stimulus 대체 | Step 4 |
| `src/ui/pages/public/assessments/show.tsx` | stub → 구현 + inline Stimulus 대체 | Step 4 |
| `src/ui/pages/public/results/show.tsx` | stub → 구현 (5 components) + CSS animation | Step 4 |
| `src/ui/index.ts` | re-export 보강 | Step 4 |
| `apps/workers/test/ui/**` (25 file) | expect.toThrow → 동작 검증 전환 | Step 0 |
| `apps/workers/src/api/routes/admin/alerts.ts` | c.html 결합 | Step 5 |
| `apps/workers/src/api/routes/admin/audit_logs.ts` | c.html 결합 | Step 5 |
| `apps/workers/src/api/routes/admin/dashboard.ts` | c.html 결합 | Step 5 |
| `apps/workers/src/api/routes/admin/question_sets.ts` | c.html 결합 | Step 5 |
| `apps/workers/src/api/routes/public/accounts.ts` | c.html 결합 | Step 5 |
| `apps/workers/src/api/routes/public/assessment_questions.ts` | c.html 결합 | Step 5 |
| `apps/workers/src/api/routes/public/assessments.ts` | c.html 결합 | Step 5 |
| `apps/workers/src/api/routes/public/consents.ts` | c.html 결합 | Step 5 |
| `apps/workers/src/api/routes/public/deletion_requests.ts` | c.html 결합 | Step 5 |
| `apps/workers/src/api/routes/public/results.ts` | c.html 결합 | Step 5 |
| `apps/workers/src/api/routes/public/sessions.ts` | c.html 결합 | Step 5 |
| `apps/workers/src/index.ts` | CSP nonce: false → true + host 분기 확인 | Step 5 |

**총 변경 파일**: 38개 (2 신규 생성 포함)

### Reviewed (변경 없음, 결합 지점 확인용)

| 파일 | 확인 목적 |
|------|----------|
| `src/middleware/csp.ts` | nonce 생성 패턴 + c.set("cspNonce") 경로 |
| `src/auth/cfAccessVerifier.ts` | CFAccessPayload 타입 + admin SSR auth 경로 |
| `src/api/routes/public/cookie-policy.ts` | host 분기 기준 (api. vs admin.) |
| Cycle 5 routes admin/public | 기존 응답 구조 (JSON/redirect) — c.html 추가 시 충돌 없음 확인 |

---

## Step별 절차

### Step 0 — RED 안티패턴 보강 (테스트 전환)

**Approach**:
25 test file 전체를 검토하여 `expect(...).toThrow("not implemented: ...")` 패턴을 모두 식별하고 component 동작 검증으로 전환한다. 이 step은 GREEN impl(Step 1~5) 이전에 완료해야 한다. Step 0 완료 후 테스트 결과가 102 fail + 611 pass (= Cycle 6 RED 상태 회복)임을 확인한다.

**Commands**:
```bash
cd /Users/kampikrein/A/personality/apps/workers

# 1. expect.toThrow 패턴 전수 확인
grep -rn "toThrow" test/ui/ | wc -l
grep -rn "toThrow" test/ui/ --include="*.test.ts"

# 2. renderToString import 가용성 확인
grep -rn "renderToString" node_modules/hono/dist/ 2>/dev/null | head -5

# 3. 테스트 보강 후 실행
npx vitest run test/ui/

# 기대: 102 fail (component throw 안 함 → renderToString 결과 검증 실패) + 611 pass
```

**전환 절차 (각 test file)**:
1. `expect(...).toThrow(...)` 라인 식별
2. 해당 컴포넌트가 반환해야 할 HTML 요소 결정 (컴포넌트명 + prop → 예상 output)
3. `renderToString` import 추가 + async/await 전환
4. `toContain` 기반 assertion으로 교체

**주요 전환 예시 (test/ui/layouts/base.test.ts)**:
```typescript
// BEFORE (RED 049)
it("renders html structure with title", () => {
  expect(() => BaseLayout({ title: "Test Page" })).toThrow("not implemented: BaseLayout");
});

// AFTER (Step 0 보강)
it("renders html structure with title", async () => {
  const html = await renderToString(BaseLayout({ title: "Test Page" }));
  expect(html).toContain("<title>Test Page</title>");
  expect(html).toContain("<html");
  expect(html).toContain("<body");
});
```

**검증**:
```bash
npx vitest run test/ui/
# 기대: 0 fail (cycle 1-5 회귀 없음) + 102 fail (cycle 6 RED 상태) = 102 fail / 611 pass
# cycle 1-5 711 아님 주의 — cycle 6 102 test는 이제 진짜 fail이어야 함
```

**Impact Analysis**:
- Cycle 1–5 테스트: 변경 없음 → 0 회귀
- Cycle 6 테스트: 102개 모두 fail로 전환 (stub throw → renderToString fail)
- 이후 Step 1~5 진행 시 테스트가 순차적으로 pass로 전환 = 올바른 TDD green 경로

---

### Step 1 — Layouts 3 구현

**Approach**:
`src/ui/layouts/base.tsx`, `admin.tsx`, `public.tsx` 3개를 stub에서 실 구현으로 교체한다. BaseLayout이 모든 레이아웃의 leaf이므로 가장 먼저 구현한다. hono/jsx FC 타입 사용, nonce prop을 script 태그에 전달.

**Commands**:
```bash
cd /Users/kampikrein/A/personality/apps/workers

# layouts 구현 후 테스트
npx vitest run test/ui/layouts/
# 기대: 0 fail (15 tests — base 4 + admin 5 + public 6)

# integration 테스트도 layouts 완료 후 부분 통과 확인
npx vitest run test/ui/integration/csp_nonce.test.ts test/ui/integration/hx_boost.test.ts
```

**핵심 구현 사항**:

BaseLayout (`base.tsx`):
- `<html lang="ko">`, `<head>`, `<title>{title}</title>`, `<meta charset="UTF-8">`, `<meta name="viewport">`
- `nonce` prop: `<script nonce={nonce}>` 에서 사용 (CSRF 토큰 fetch 등 전역 inline script)
- `children`: `<body>` 안에 렌더

AdminLayout (`admin.tsx`):
- BaseLayout 래핑 + admin nav (질문세트, 알림, 감사로그, 대시보드 링크)
- `user: CFAccessPayload` prop → nav에 `{user.email}` 표시
- cfAccessVerifier는 middleware에서 처리, layout은 user 표시만 담당

PublicLayout (`public.tsx`):
- BaseLayout 래핑 + Header + Footer 컴포넌트 포함
- `hxBoost?: boolean`: `<body hx-boost="true">` 조건부
- htmx CDN script: hxBoost true 시만 삽입

**검증**:
```bash
npx vitest run test/ui/layouts/
# 0 fail / 15 pass

# 누적 확인
npx vitest run test/ui/
# 0 fail / (611 + 15 = 626 pass) + 87 fail (나머지 cycle 6 미구현)
```

**Impact Analysis**:
- 의존: Cycle 4 csp.ts (c.set("cspNonce") 경로 확인 필요)
- 후행: Step 2 components가 layouts를 import하므로 Step 1 완료 후 진행

---

### Step 2 — Components 4 구현 (공유)

**Approach**:
`header.tsx`, `footer.tsx`, `alert.tsx`, `csrf_meta.tsx` 4개 공유 컴포넌트 구현. 모든 page가 이를 사용하므로 Step 3/4 전에 완료해야 한다.

**Commands**:
```bash
cd /Users/kampikrein/A/personality/apps/workers

npx vitest run test/ui/components/
# 기대: 0 fail (19 tests — header 5 + footer 3 + alert 7 + csrf_meta 4)
```

**핵심 구현 사항**:

Alert (`alert.tsx`):
- `variant: "success" | "warning" | "error" | "info"`
- variant별 CSS class: `alert-success`, `alert-warning`, `alert-error`, `alert-info`
- `message: string` → `<p>{message}</p>` 또는 `<span>{message}</span>`
- `role="alert"` (accessibility)

CsrfMeta (`csrf_meta.tsx`):
- `<meta name="csrf-token" content={token}>` — Hono middleware에서 주입된 token 전달

Header (`header.tsx`):
- 사이트 로고/브랜드 + 네비게이션
- `user` prop 선택적: 로그인 상태 표시

Footer (`footer.tsx`):
- 정적 footer (저작권, 링크)

**검증**:
```bash
npx vitest run test/ui/components/
# 0 fail / 19 pass

# 누적
npx vitest run test/ui/
# 0 fail / (626 + 19 = 645 pass) + 68 fail
```

**Impact Analysis**:
- csrf_meta: Hono middleware에서 CSRF 토큰을 c.var에 설정하는 경로 확인 필요
- alert: variant 타입은 RED 049에서 정의된 AlertVariant enum과 일치해야 함

---

### Step 3 — Admin SSR 9 Pages 구현

**Approach**:
Admin 9 ERB 대응 TSX page 구현. 모두 AdminLayout을 사용. stub에 미포함된 2개(alerts/show, audit_logs/show)는 GREEN에서 신규 추가. 각 page는 CRUD props를 받아 AdminLayout 내부에 table/form을 렌더링.

**Commands**:
```bash
cd /Users/kampikrein/A/personality/apps/workers

npx vitest run test/ui/pages/admin/
# 기대: 0 fail (28 tests)
```

**Page별 핵심 Props**:

| Page | Props |
|------|-------|
| `DashboardIndexPage` | `{ user, stats: { totalUsers, totalAssessments, ... }, nonce? }` |
| `AlertsIndexPage` | `{ user, alerts: Alert[], nonce? }` |
| `AlertsShowPage` (신규) | `{ user, alert: Alert, nonce? }` |
| `AuditLogsIndexPage` | `{ user, logs: AuditLog[], pagination, nonce? }` |
| `AuditLogsShowPage` (신규) | `{ user, log: AuditLog, nonce? }` |
| `QuestionSetsIndexPage` | `{ user, questionSets: QuestionSet[], nonce? }` |
| `QuestionSetsShowPage` | `{ user, questionSet: QuestionSet, nonce? }` |
| `QuestionSetsNewPage` | `{ user, csrfToken: string, nonce? }` |
| `QuestionSetsEditPage` | `{ user, questionSet: QuestionSet, csrfToken: string, nonce? }` |

**test/ui/pages/admin/ 신규 test 추가 (Step 0에서 전환 + Step 3 진행 시)**:
- `audit_logs/show.test.ts` 신규 (GREEN에서 추가)
- `alerts/show.test.ts` 신규 (GREEN에서 추가)

**검증**:
```bash
npx vitest run test/ui/pages/admin/
# 0 fail / 28 pass (기존 23 + 신규 5)

# 누적
npx vitest run test/ui/
# 0 fail / (645 + 28 = 673 pass) + 40 fail
```

**Impact Analysis**:
- cfAccessVerifier: admin routes middleware가 c.set("cfUser") → layout prop으로 전달 경로 검증
- 신규 show pages: test 신규 작성 필요 (Step 0 후 진행이므로 처음부터 동작 검증 패턴으로 작성)

---

### Step 4 — Public SSR 13 Pages 구현 (+ Stimulus 8 → vanilla)

**Approach**:
Public 13 ERB 대응 TSX page 구현. PublicLayout 사용. results/show.tsx는 5개 컴포넌트(ResultsShowPage + 4 partials)를 단일 파일에 포함. 8 Stimulus controller를 inline script/CSS로 대체 — 모든 inline script에 `nonce={nonce}` 필수.

**Commands**:
```bash
cd /Users/kampikrein/A/personality/apps/workers

npx vitest run test/ui/pages/public/
# 기대: 0 fail (38 tests)
```

**Page별 핵심 Props + Stimulus 대체**:

| Page | Props | Stimulus 대체 |
|------|-------|--------------|
| `SessionsNewPage` | `{ csrfToken, nonce? }` | 없음 |
| `AccountsNewPage` | `{ csrfToken, nonce? }` | 없음 |
| `ConsentsNewPage` | `{ csrfToken, assessmentId, nonce? }` | 없음 |
| `DeletionRequestsNewPage` | `{ csrfToken, nonce? }` | 없음 |
| `DeletionRequestsShowPage` | `{ request: DeletionRequest, nonce? }` | 없음 |
| `AssessmentShowPage` | `{ assessment, progress, nonce? }` | progress_controller → CSS `width: {progress}%` |
| `AssessmentQuestionShowPage` | `{ question, questionNumber, totalQuestions, csrfToken, nonce? }` | likert_controller + countdown_controller + autosave_controller + questionnaire_controller → inline script |
| `ResultsShowPage` | `{ typeHero, spectrum, insights, nonce? }` | type_reveal → CSS @keyframes; spectrum_bar → data-final-width + CSS; tabs → inline script |

**AssessmentQuestionShowPage inline script 패턴**:
```tsx
// likert_controller 대체
const likertScript = `
document.querySelectorAll('input[type="radio"]').forEach(r => {
  r.addEventListener('change', () => setTimeout(() => r.form.submit(), 200));
});
`;

// countdown_controller 대체
const countdownScript = `
const _t = Date.now();
document.querySelector('form').addEventListener('submit', function(e) {
  document.getElementById('response_time').value = Date.now() - _t;
});
`;

// In JSX:
<>
  <script nonce={nonce} dangerouslySetInnerHTML={{ __html: likertScript }} />
  <script nonce={nonce} dangerouslySetInnerHTML={{ __html: countdownScript }} />
</>
```

**results/show.tsx 5 components**:

```typescript
export type TypeHeroData = { typeName: string; typeCode: string; tagline: string };
export type SpectrumData = { domains: { name: string; score: number }[] };
export type InsightCard = { title: string; body: string };

export const TypeHero: FC<TypeHeroData> = ({ typeName, typeCode, tagline }) => (...)
export const SpectrumPartial: FC<SpectrumData> = ({ domains }) => (...)
export const InsightCardPartial: FC<InsightCard> = ({ title, body }) => (...)
export const TrustNotice: FC = () => (...)
export const ResultsShowPage: FC<ResultsShowProps> = (props) => (...)
```

**검증**:
```bash
npx vitest run test/ui/pages/public/
# 0 fail / 38 pass

# 누적
npx vitest run test/ui/
# 0 fail / (673 + 38 = 711 pass) + integration 2 fail 남음
```

**Impact Analysis**:
- dangerouslySetInnerHTML: hono/jsx에서 지원 여부 확인 필요. 대안: `innerHTML` prop 또는 raw string 처리
- autosave_controller: sessionStorage 접근 — SSR 렌더링 시 서버 사이드에서는 실행 안 됨, inline script로 클라이언트에서만 실행

---

### Step 5 — Routes 결합 + Integration + 통합 검증

**Approach**:
Cycle 5의 admin/public route handler에 `c.html(<Page />)` 호출 추가. CSP nonce: true 전환. host 분기 확인. Integration test 3개(e2e_smoke, hx_boost, csp_nonce) 완료. 전체 713 pass 달성.

**Commands**:
```bash
cd /Users/kampikrein/A/personality/apps/workers

# 1. CSP nonce 전환
# src/index.ts: createCspMiddleware({ nonce: true, ... })

# 2. Routes 결합 후 integration test
npx vitest run test/ui/integration/
# 기대: 0 fail (8 tests — csp_nonce 3 + e2e_smoke 4 + hx_boost 3 = 10, 일부는 structural placeholder)

# 3. 전체 테스트
npx vitest run
# 기대: 0 fail / 713 pass
```

**Routes 결합 절차**:

```typescript
// apps/workers/src/api/routes/admin/dashboard.ts 변경 예시
import { DashboardIndexPage } from "../../ui/pages/admin/dashboard/index";

// 기존 JSON 응답 GET handler 교체 또는 추가
dashboard.get("/", async (c) => {
  const user = c.get("cfUser");        // cfAccessVerifier middleware에서 설정
  const nonce = c.get("cspNonce");    // createCspMiddleware에서 설정
  const stats = await fetchStats(c);  // 기존 DB 조회 로직 재사용
  return c.html(
    <DashboardIndexPage user={user} stats={stats} nonce={nonce} />
  );
});
```

**e2e_smoke.test.ts 완전 구현** (placeholder → 실 fetch):
```typescript
import { app } from "../../../src/index";

it("GET /admin/dashboard → 200 HTML", async () => {
  const res = await app.request("/admin/dashboard", {
    headers: { host: "admin.personality.app" }
  });
  expect(res.status).toBe(200);
  expect(res.headers.get("content-type")).toContain("text/html");
  const body = await res.text();
  expect(body).toContain("<title>Admin Dashboard</title>");
});
```

**Index.ts host 분기 확인**:
- `api.<DOMAIN>` → Workers API routes
- `admin.<DOMAIN>` → admin SSR routes
- `<DOMAIN>` → public SSR routes
- cookie-policy.ts 결합 지점 (Cycle 1 패턴 유지)

**검증**:
```bash
npx vitest run
# 0 fail / 713 pass

# 빌드 성공 확인 (build policy 필수)
flutter build apk --debug  # 해당 없음 — Workers 프로젝트
npx wrangler deploy --dry-run  # 또는 vitest type-check
```

**Impact Analysis**:
- `c.html()` 반환 타입: Hono의 `Response` 반환, 기존 JSON 응답과 동일 인터페이스
- admin middleware 체인: cfAccessVerifier → csp → route handler 순서 유지 필요
- public routes에 auth 없는 경우: BetterAuth optional user (session 없으면 null)

---

## Implementation 분할 권장

### 옵션 A — 단일 배치 (Step 0~5 순차)

모든 단계를 하나의 implementation agent가 처리. 25 file 테스트 보강 + 26 file stub 구현 + 12 routes 결합 = 총 63개 파일 수정. 컨텍스트 포화 위험 있음.

### 옵션 B — 2-배치 분할 (권장)

**배치 1**: Step 0 (테스트 보강) + Step 1 (Layouts 3) + Step 2 (Components 4)
- 변경 파일: 25 test file + 7 src file = 32 file
- 완료 기준: 테스트 보강 완료 + 611 + 22 pass (layouts + components) + 80 fail 남음

**배치 2**: Step 3 (Admin 9 pages) + Step 4 (Public 13 pages) + Step 5 (Routes + Integration)
- 변경 파일: 22 src file + 12 routes = 34 file (신규 포함)
- 완료 기준: 0 fail / 713 pass

**권장 근거**:
- Cycle 3/4/5 분할 패턴과 일관
- RED 안티패턴 보강(Step 0)이 독립 작업이므로 배치 1의 집중도 확보
- 배치 1 완료 = "테스트가 진짜 RED"인 상태 달성 → 배치 2에서 clean TDD green 경험

---

## Cross-Reference Table

### Admin ERB ↔ TSX ↔ Test ↔ Step

| ERB 파일 | TSX (src/ui/pages/admin/) | Test 파일 | Tests | Step |
|----------|--------------------------|----------|-------|------|
| `admin/dashboard/index.html.erb` | `dashboard/index.tsx` → DashboardIndexPage | `pages/admin/dashboard/index.test.ts` | 3 | 3 |
| `admin/alerts/index.html.erb` | `alerts/index.tsx` → AlertsIndexPage | `pages/admin/alerts/index.test.ts` | 4 | 3 |
| `admin/alerts/show.html.erb` | `alerts/show.tsx` → AlertsShowPage | `pages/admin/alerts/show.test.ts` (신규) | ~3 | 3 |
| `admin/audit_logs/index.html.erb` | `audit_logs/index.tsx` → AuditLogsIndexPage | `pages/admin/audit_logs/index.test.ts` | 5 | 3 |
| `admin/audit_logs/show.html.erb` | `audit_logs/show.tsx` → AuditLogsShowPage | `pages/admin/audit_logs/show.test.ts` (신규) | ~3 | 3 |
| `admin/question_sets/index.html.erb` | `question_sets/index.tsx` → QuestionSetsIndexPage | `pages/admin/question_sets/index.test.ts` | 3 | 3 |
| `admin/question_sets/show.html.erb` | `question_sets/show.tsx` → QuestionSetsShowPage | `pages/admin/question_sets/show.test.ts` | 2 | 3 |
| `admin/question_sets/new.html.erb` | `question_sets/new.tsx` → QuestionSetsNewPage | `pages/admin/question_sets/new.test.ts` | 3 | 3 |
| `admin/question_sets/edit.html.erb` | `question_sets/edit.tsx` → QuestionSetsEditPage | `pages/admin/question_sets/edit.test.ts` | 3 | 3 |

### Public ERB ↔ TSX ↔ Test ↔ Step

| ERB 파일 | TSX (src/ui/pages/public/) | Test 파일 | Tests | Step | Stimulus |
|----------|---------------------------|----------|-------|------|----------|
| `sessions/new.html.erb` | `sessions/new.tsx` → SessionsNewPage | `sessions/new.test.ts` | 4 | 4 | - |
| `accounts/new.html.erb` | `accounts/new.tsx` → AccountsNewPage | `accounts/new.test.ts` | 3 | 4 | - |
| `consents/new.html.erb` | `consents/new.tsx` → ConsentsNewPage | `consents/new.test.ts` | 3 | 4 | - |
| `deletion_requests/new.html.erb` | `deletion_requests/new.tsx` → DeletionRequestsNewPage | `deletion_requests/new.test.ts` | 2 | 4 | - |
| `deletion_requests/show.html.erb` | `deletion_requests/show.tsx` → DeletionRequestsShowPage | `deletion_requests/show.test.ts` | 4 | 4 | - |
| `assessments/show.html.erb` | `assessments/show.tsx` → AssessmentShowPage | `assessments/show.test.ts` | 4 | 4 | progress → CSS |
| `assessment_questions/show.html.erb` | `assessment_questions/show.tsx` → AssessmentQuestionShowPage | `assessment_questions/show.test.ts` | 4 | 4 | likert + countdown + autosave + questionnaire → inline JS |
| `assessment_questions/_question.html.erb` | `results/show.tsx` (통합) | — | — | 4 | - |
| `results/show.html.erb` | `results/show.tsx` → ResultsShowPage | `results/show.test.ts` | 11 | 4 | type_reveal → CSS; spectrum_bar → CSS; tabs → inline JS |
| `results/_type_hero.html.erb` | `results/show.tsx` → TypeHero | `results/show.test.ts` | (포함) | 4 | type_reveal → CSS |
| `results/_spectrum.html.erb` | `results/show.tsx` → SpectrumPartial | `results/show.test.ts` | (포함) | 4 | spectrum_bar → CSS |
| `results/_insight_card.html.erb` | `results/show.tsx` → InsightCardPartial | `results/show.test.ts` | (포함) | 4 | - |
| `results/_trust_notice.html.erb` | `results/show.tsx` → TrustNotice | `results/show.test.ts` | (포함) | 4 | - |

### Layout ↔ ERB ↔ TSX ↔ Test ↔ Step

| ERB 레이아웃 | TSX | Test 파일 | Tests | Step |
|-------------|-----|----------|-------|------|
| `layouts/application.html.erb` | `layouts/base.tsx` + `layouts/public.tsx` | `layouts/base.test.ts` (4) + `layouts/public.test.ts` (6) | 10 | 1 |
| `layouts/admin.html.erb` | `layouts/admin.tsx` | `layouts/admin.test.ts` | 5 | 1 |

### Stimulus ↔ vanilla 대체 ↔ Step

| Stimulus controller | vanilla 대체 | 적용 Page | Step |
|--------------------|-------------|----------|------|
| likert_controller | inline `<script nonce>`: radio change → 200ms submit | AssessmentQuestionShowPage | 4 |
| countdown_controller | inline `<script nonce>`: Date.now() delta → hidden input | AssessmentQuestionShowPage | 4 |
| autosave_controller | inline `<script nonce>`: sessionStorage save/restore | AssessmentQuestionShowPage | 4 |
| questionnaire_controller | autosave 통합, 별도 controller 제거 | AssessmentQuestionShowPage | 4 |
| progress_controller | CSS only: `style={{ width: "...%" }}` | AssessmentShowPage | 4 |
| spectrum_bar_controller | `data-final-width` + `@keyframes grow` CSS | ResultsShowPage (SpectrumPartial) | 4 |
| tabs_controller | inline `<script nonce>`: querySelectorAll data-tab class swap | ResultsShowPage | 4 |
| type_reveal_controller | CSS `@keyframes typeReveal` | ResultsShowPage (TypeHero) | 4 |

---

## Verification Plan

### 단계별 검증 체크리스트

| 단계 | 명령 | 기대 결과 |
|------|------|---------|
| Step 0 완료 | `npx vitest run test/ui/` | 102 fail + 611 pass (RED 상태 회복) |
| Step 1 완료 | `npx vitest run test/ui/layouts/` | 0 fail / 15 pass |
| Step 1 누적 | `npx vitest run test/ui/` | 0 fail / 626 pass + 87 fail 남음 |
| Step 2 완료 | `npx vitest run test/ui/components/` | 0 fail / 19 pass |
| Step 2 누적 | `npx vitest run test/ui/` | 0 fail / 645 pass + 68 fail |
| Step 3 완료 | `npx vitest run test/ui/pages/admin/` | 0 fail / 28 pass (신규 포함) |
| Step 3 누적 | `npx vitest run test/ui/` | 0 fail / 673 pass + 40 fail |
| Step 4 완료 | `npx vitest run test/ui/pages/public/` | 0 fail / 38 pass |
| Step 4 누적 | `npx vitest run test/ui/` | 0 fail / 711 pass + 2~3 integration fail |
| Step 5 완료 | `npx vitest run` | **0 fail / 713 pass** |

### 검증 항목 상세

**HTML 렌더링 출력**:
- `BaseLayout({ title: "T" })` → `html.includes("<title>T</title>")` = true
- `AdminLayout({ title: "A", user: adminUser })` → `html.includes("admin@")` = true
- `PublicLayout({ title: "P", hxBoost: true })` → `html.includes('hx-boost="true"')` = true

**CSP nonce 주입**:
- `BaseLayout({ title: "T", nonce: "abc" })` → `html.includes('nonce="abc"')` = true
- 모든 inline script tag에 nonce 속성 포함 확인

**hx-boost attribute**:
- `PublicLayout({ hxBoost: true })` → `html.includes('hx-boost="true"')` = true
- `PublicLayout({ hxBoost: false })` → `html.not.includes('hx-boost')` = true
- `PublicLayout({})` → `html.not.includes('hx-boost')` = true

**Stimulus 8 → vanilla 동작**:
- AssessmentQuestionShowPage HTML에 inline script 포함 + `nonce` attribute 확인
- script 내용에 `'change'` (likert) + `Date.now()` (countdown) + `sessionStorage` (autosave) 포함
- SpectrumPartial HTML에 `data-final-width` attribute 포함
- CSS에 `@keyframes` 포함

**Cycle 1–5 회귀 없음**:
- `npx vitest run --exclude test/ui/` → 611 pass / 0 fail
- 또는 `npx vitest run` 전체 결과 확인

**E2E smoke (hono app.fetch direct)**:
- `GET /admin/dashboard` (host: admin.personality.app) → status 200, content-type: text/html
- `GET /signin` → status 200, content-type: text/html
- `GET /signup` → status 200, content-type: text/html

---

## Risks & Mitigations

| ID | 위험 | 영향 | 완화 |
|----|------|------|------|
| **R1** | Step 0 테스트 보강이 Cycle 1–5 회귀 유발 | 611 tests 중 일부 fail | **Step 0는 `test/ui/` 폴더만 수정**. Cycle 1–5 test file은 완전히 다른 경로(`test/api/`, `test/auth/` 등) — 교차 없음 |
| **R2** | hono/jsx renderToString이 vitest workers pool에서 미지원 | Step 0 전환 자체가 불가능 | RED 049에서 78 test file이 hono/jsx import 포함 상태로 pass. renderToString은 server-side 전용 API — pool 무관. 미지원 시 `String(jsx)` 캐스팅으로 fallback |
| **R3** | hx-boost SPA 전환이 wrangler dev 없이 검증 불가 | Ideal Criteria #22 partial | attribute 존재 검증 (Phase 1 범위). 실 form 전환은 Phase 2 #18에서 검증. 명시적 carryover |
| **R4** | CSP nonce를 모든 inline script에 주입하지 않으면 CSP violation | 브라우저에서 script 차단 | BaseLayout에서 전역 inline script nonce 강제. 각 page의 inline script는 `nonce={nonce}` prop 필수로 lint/type 강제 |
| **R5** | cfAccessVerifier가 admin SSR 요청에서 user를 c.set하지 않으면 AdminLayout user prop이 undefined | admin page crash | cfAccessVerifier는 Cycle 4에서 구현 완료. middleware 체인 순서 (cfAccessVerifier → route) 유지 확인 |
| **R6** | Stimulus → vanilla 대체의 행동 동등성 미보증 | 사용자 경험 차이 | Phase 2에서 실 사용자 테스트 carryover. Phase 1에서는 script 존재 + attribute 검증으로 구조 동등성만 확인 |
| **R7** | Step 5 routes 결합이 Cycle 5 기존 api test 회귀 유발 | cycle 5 테스트 fail | `c.html()` 추가는 GET handler에만. 기존 JSON POST/PATCH/DELETE routes 무변경. 결합 후 즉시 전체 vitest run으로 확인 |
| **R8** | dangerouslySetInnerHTML hono/jsx 미지원 | inline script 렌더 불가 | hono/jsx는 `dangerouslySetInnerHTML`를 `innerHTML` prop으로 처리. 미지원 시 `children`으로 raw string 전달 패턴 사용 |
| **R9** | alerts/show + audit_logs/show 신규 stub 없음 | test file 부재 | Step 3에서 test file도 함께 신규 작성. TDD 순서: test 먼저 → 구현 |

---

## References

- **RED 049**: `/Users/kampikrein/A/personality/docs/6_backend/02_cf_workers_rebuild/049_TDDRed_cycle6_admin_public_ssr.md`
  - § ERB Inventory, § Stimulus Inventory, § Test Files Created, § Implementation Hints for Green Phase, § Risks
- **Brief 021**: `/Users/kampikrein/A/personality/docs/6_backend/02_cf_workers_rebuild/021_Brief_conversion_phase1.md`
  - § Decision 6 (Admin UI = Hono SSR vanilla + hx-boost), § Decision 12 (Phase 2 verify model), § Ideal Criteria #7/#10/#21/#22
- **R3 010**: `/Users/kampikrein/A/personality/docs/6_backend/02_cf_workers_rebuild/010_Research_axis3_admin_ui.md`
  - § R3-F1 Winner: Pattern A — Hono SSR vanilla (+ hx-boost 1줄 옵셔널)
- **Synthesis 018**: `/Users/kampikrein/A/personality/docs/6_backend/02_cf_workers_rebuild/018_Synthesis_research_cycle.md`
  - § S-018-F6 Cycle 6 영역 확장 (Admin + Public)
- **Critique 030**: `/Users/kampikrein/A/personality/docs/6_backend/02_cf_workers_rebuild/030_Critique_Synthesis_scope.md`
  - § C1 (W3 Critical — conversion fidelity) → Brief 021 Decision 12 보강으로 해소
- **Cycle 5 Impl 047**: `/Users/kampikrein/A/personality/docs/6_backend/02_cf_workers_rebuild/047_Implementation_cycle5_api_mobile.md`
  - Admin/Public routes 결합 지점 (c.html 추가 대상)
- **Source**: `apps/workers/src/ui/` (25 stub files), `apps/workers/test/ui/` (25 test files)
- **Route targets**: `apps/workers/src/api/routes/admin/` (4 files), `apps/workers/src/api/routes/public/` (8 files)
- **Hono JSX Guide**: https://hono.dev/docs/guides/jsx
- **Hono JSX Renderer**: https://hono.dev/docs/middleware/builtin/jsx-renderer
