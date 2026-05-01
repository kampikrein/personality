---
id: "010"
type: research
title: "R3 — Admin UI 패턴: Hono SSR vanilla vs Hono+HTMX vs Astro 6"
created: 2026-04-29
traces_brief: "001"
traces_scope: "007"
research_axis: "R3"
summary: >
  실측 결과 admin은 9 ERB 템플릿(293 LOC)·Stimulus 0개(8 컨트롤러는 모두
  공개 평가 흐름 전용)로 단순 CRUD다. Astro 6은 2026-03-10 GA + workerd
  dev 서버 + D1 binding direct(`Astro.locals.cfContext`/`cloudflare:workers env`)
  지원이지만 콘텐츠 사이트 지향이며 admin CRUD에는 추가 빌드 시스템·러닝
  곡선이 비대칭. Hono+HTMX는 Hono 창시자(Yusuke Wada) 권장 스택, 단일
  빌드, JSX 서버 전용, hx-boost로 진보적 향상. Hono SSR vanilla는 빌드
  최단·러닝 0이나 부분 갱신은 매 form full reload. **Winner: Hono SSR
  vanilla + 선택적 hx-boost(htmx 1줄 도입)** — admin 9 화면 + Stimulus 0의
  실측에서 추가 추상화는 비용 대비 무가치. Hotwire Turbo Frame 동등성은
  본 admin 범위에서 **무관**(Stimulus·Turbo Frame이 admin에서 사용되지 않음).
keywords: [hono, htmx, astro, admin-ui, ssr, hotwire, workerd, cloudflare]
---

# R3 — Admin UI 패턴: Hono SSR vanilla vs Hono+HTMX vs Astro 6

## Research Overview

### 조사 범위

Brief Decision 4(잠정)·M11이 본 axis에 winner 결정 권한을 위임. Scope R3 4개 핵심 질문:
1. Astro 6 (2026-01 CF 인수 후) workerd 어댑터 GA, D1 binding 직접 사용, 1인 운영자 학습 곡선
2. Hono+HTMX의 Hotwire 동등성
3. Hono SSR vanilla 27 화면 LOC/DX/유지비
4. 빌드 시스템 단일성

### Ground Truth — 실측 (가장 중요)

Brief의 "27 ERB + 8 Stimulus" 숫자는 **admin 범위 추정 오차**를 포함했다. 실측:

| 항목 | Brief 표기 | 실측 (admin 범위만) |
|------|-----------|---------------------|
| ERB 템플릿 | 27 | **9** (admin/) — `server/app/views/admin/`(dashboard 1, alerts 2, audit_logs 2, question_sets 4) + `layouts/admin.html.erb` |
| ERB LOC | 1,788 | **293** admin LOC (293 = 42+55+26+36+20+20+31+17+46) + 36 layout |
| Stimulus 컨트롤러 | 8 | **0 admin 사용** — 8개 모두 공개 평가 흐름(`assessments/`) 전용 (likert/autosave/countdown/progress/questionnaire/spectrum_bar/tabs/type_reveal) |
| Hotwire Turbo Frame | "2 템플릿에 한정" | **0 admin 사용** — admin layout은 `data-turbo-track: reload`만 사용, frame 0 |

근거 파일:
- `server/app/views/admin/dashboard/index.html.erb:1-20` — 카드 3개 정적 통계
- `server/app/views/admin/question_sets/index.html.erb:1-31` — 정적 테이블 + 링크
- `server/app/views/admin/question_sets/show.html.erb:1-46` — 정적 테이블 + 폼 링크
- `server/app/views/admin/question_sets/edit.html.erb:1-20` — 표준 폼
- `server/app/views/admin/alerts/index.html.erb:1-42` — 정적 테이블
- `server/app/views/admin/alerts/show.html.erb:1-55` — 폼(상태 업데이트)
- `server/app/views/admin/audit_logs/{index,show}.html.erb` — 정적 테이블/상세
- `server/app/views/layouts/admin.html.erb:8-9` — `stylesheet_link_tag :app, "data-turbo-track": "reload"` + `javascript_importmap_tags` (Stimulus는 import만, admin DOM에서 미사용)
- `server/app/javascript/controllers/likert_controller.js:1-23` (대표) — `assessments` 흐름의 form auto-submit 전용

함의: **admin은 순수 CRUD + Tailwind 정적 페이지**. progressive enhancement·optimistic update·Turbo Stream을 1:1 대응할 대상이 admin 범위에 **존재하지 않는다**. Brief Decision 4·M11이 가정한 "Hotwire 동등성 비교"의 실질적 부담이 평가 흐름(공개 페이지)으로 옮겨가야 하나, 본 R3는 admin scope 한정.

## Pattern A: Hono SSR vanilla

### 구조
- Hono `c.html()` + JSX(`hono/jsx`) 또는 `html` 태그 — 서버 렌더만, 하이드레이션 0
- 빌드 = Workers project 단일 (`tsconfig.jsx: "react-jsx", jsxImportSource: "hono/jsx"`) — 추가 도구 0
- D1 binding = Hono context `c.env.DB` 직접
- 인터랙션 = HTML form `<form method="POST" action="...">` + 브라우저 default full reload

### Hotwire 동등성
- admin 범위에서 동등 대상 0 → **N/A**
- form 제출 시 full reload는 9 화면 모두에서 사용자 행동 변화 0 (현 admin도 form 후 redirect → full render)
- alerts/show.erb의 status 업데이트 폼(서버 redirect_to 후 새 페이지 렌더)이 그대로 1:1

### LOC 추정 (9 화면)
- Layout 1개: ~50 LOC TSX (현 36 ERB + Tailwind import + nav 4개)
- Dashboard: ~30 LOC TSX (3 카드)
- QuestionSets index/show/new/edit: ~50/70/30/30 = 180 LOC
- Alerts index/show: ~60/80 = 140 LOC
- AuditLogs index/show: ~40/55 = 95 LOC
- 합계: **약 495 TSX LOC** (Ruby ERB 293 LOC 대비 +69%, JSX 명시 props 타입 + closing tags + className 등 boilerplate 영향)

### DX
- TypeScript `c.env.DB` 자동완성, JSX 타입 안전, hot reload(`wrangler dev`) 1초대
- 러닝 곡선: TypeScript + JSX 둘 다 사용자 친숙(Brief Constraint), 추가 0
- 디버깅 = 서버 로그 + curl로 충분 (DOM 변경 없음)

### 유지비
- 빌드 단일, deploy `wrangler deploy` 한 번
- 의존성 = Hono(1)
- 사이드 이펙트 0 — 1인 운영자 정합 최고

## Pattern B: Hono + HTMX

### 구조
- Hono JSX SSR + htmx CDN 1줄(`<script src="https://unpkg.com/htmx.org@2"></script>`)
- typed-htmx (dev dep) — JSX에서 `hx-get` `hx-post` 등 타입 보강 ([hono.dev/examples/htmx](https://hono.dev/examples/htmx))
- 인터랙션 = `hx-boost`(form/anchor 자동 AJAX + history) 또는 명시적 `hx-target`/`hx-swap`
- 빌드 = Workers project 단일, 추가 빌드 단계 0 (htmx는 런타임 CDN/번들)

### Hotwire 동등성 (참고)
- htmx 공식 마이그레이션 가이드([htmx.org/migration-guide-hotwire-turbo](https://htmx.org/migration-guide-hotwire-turbo/)):
  - Turbo Frame ≈ `hx-trigger="load,submit"` + `hx-target` (별도 element 필요, 명시적)
  - Turbo Stream ≈ `hx-swap-oob`/`hx-select-oob`
  - Stimulus ≈ `hx-on` 또는 hyperscript
- Radan Skoric([radan.dev/articles/hotwire-and-htmx](https://radan.dev/articles/hotwire-and-htmx)): "fundamentally different developer experiences" — Turbo는 magical 기본값, htmx는 explicit. **기능 동등하지만 의미 다름.**
- admin 범위에서는 Turbo Frame을 안 쓰므로 동등성 비교 자체가 **moot**. htmx 도입 가치는 hx-boost로 페이지 전환 SPA-like UX **추가**(현 Rails admin은 그것조차 없음).

### LOC
- Pattern A LOC 그대로 + `<script>` 1줄 + 선택적 `hx-boost` 속성 → 사실상 동일

### DX
- 학습 곡선 += htmx 속성 어휘(`hx-get`, `hx-post`, `hx-target`, `hx-swap`, `hx-trigger`, `hx-boost`, …) — 1인 운영자에게는 작은 추가 부담
- typed-htmx 도입 = `tsconfig` 수정 1회, `global.d.ts` 1회
- Yusuke Wada(Hono 창시자) 추천 스택([blog.yusu.ke/hono-htmx-cloudflare](https://blog.yusu.ke/hono-htmx-cloudflare/)): "JSX without React" + "feels like PHP/Rails" + 100ms latency, 22 KB worker — admin에 충분

### Workers 호환
- htmx는 client-side만, Worker 영향 0
- typed-htmx는 dev only, 런타임 영향 0

### 유지비
- 의존성 = Hono(1) + typed-htmx dev(1) + htmx CDN/static(1) — 경량
- htmx 메이저 버전 변경 시 검증 필요 (현 v2 안정)

## Pattern C: Astro 6

### 2026-01 CF 인수 후 상태
- 2026-01-16 Cloudflare가 Astro 인수 발표([blog.cloudflare.com/astro-joins-cloudflare](https://blog.cloudflare.com/astro-joins-cloudflare/), [astro.build/blog/joining-cloudflare](https://astro.build/blog/joining-cloudflare/))
- 2026-03-10 Astro 6.0 GA + `@astrojs/cloudflare` v13.0 GA([astro.build/blog/astro-6](https://astro.build/blog/astro-6/))
- 2026-04-29 시점 latest `@astrojs/cloudflare@13.1.8`(공개 약 2일 전)
- workerd 어댑터: dev/prerender/production 전 단계에서 workerd 실행 — Node↔workerd 갭 제거

### D1 / KV / R2 binding 직접 사용
- `import { env } from 'cloudflare:workers'` → `env.DB.prepare(...)` 직접([docs.astro.build/en/guides/integrations-guide/cloudflare](https://docs.astro.build/en/guides/integrations-guide/cloudflare/))
- 또는 `Astro.locals.cfContext` (구 `Astro.locals.runtime.ctx` 대체, v13 break)
- 세션 = Workers KV 자동 구성 (Astro Sessions API)
- wrangler.toml = 단순 프로젝트면 자동 생성, bindings 있으면 명시

### DX
- 파일 기반 라우팅(`src/pages/admin/*.astro`) — Hono 명시 라우팅 대비 admin CRUD에는 가독성↑
- Astro 컴포넌트 = HTML-first + frontmatter JS — JSX/TSX와 다른 문법 학습 필요
- Islands(Stimulus 대체) 가능 — 본 admin은 0 인터랙티브이므로 미사용
- Hot reload = Vite + workerd

### 빌드 시스템 단일성 — **본 axis에서 결정적 단점**
- Astro 빌드 = Vite 7 + Astro 자체 컴파일 → `dist/_worker.js/index.js` 산출
- Workers project = wrangler 단독 빌드(esbuild 기반)
- **두 빌드 도구가 한 repo에**: Astro app(admin) + Hono app(api/payment/auth) 분리 시 monorepo 의존성·CI·deploy 분기 발생
  - 옵션 1: admin만 Astro로, api는 Hono로 — 두 Worker, 두 wrangler.toml, 두 deploy job
  - 옵션 2: 단일 Worker에 Astro + Hono — Astro 어댑터가 entry를 잡으므로 Hono 경로는 Astro middleware로 위임 — **추가 추상화·러닝**
- 1인 운영자 시간 ÷ 단일 빌드 단순성 가치 = 큰 weight

### 1인 학습 곡선
- Astro 컴포넌트 문법 + frontmatter + content collections + zod 등 범위 큼
- admin 9 화면을 위해 framework 한 개 더 학습은 **비용 대비 효용 음수**
- 강점은 콘텐츠 사이트(블로그·랜딩)에 명확하나 admin CRUD에 매칭 약함

### Workers 호환
- @astrojs/cloudflare v13 GA + workerd dev — 호환은 안정. 호환성이 문제가 아니라 **적합성**이 문제

### 유지비
- 빌드 도구 +1, 의존성 +N(Vite, Astro core, adapter)
- Astro 메이저 변경 주기 빠름(5.x→6.x 13개월). v6 신규 → 버전 안정화 시간 필요

## 3 패턴 비교 매트릭스

| 차원 | A: Hono SSR vanilla | B: Hono + HTMX | C: Astro 6 |
|------|---------------------|----------------|------------|
| **DX (1인 운영자)** | 최고 — TS+JSX 단일 | 상 — htmx 어휘 +α | 중 — Astro 문법 + Vite 학습 |
| **Hotwire 동등성** | N/A (admin 0 사용) | 동등 가능, 의미 다름 | 동등 가능(Islands), 과한 추상화 |
| **빌드 시스템** | 단일 (wrangler) | 단일 (wrangler) | **이중 (Astro+Vite + wrangler)** |
| **1인 학습 곡선** | 0 (Hono 학습으로 끝) | 작음 (htmx attr) | 큼 (프레임워크 1개 추가) |
| **유지비** | 최저 — 의존성 1 | 낮음 — 의존성 2 | 중 — 의존성 다수 + 메이저 주기 |
| **27 화면 LOC** | N/A — **9 화면** ~495 TSX | ~495 TSX + hx-* 속성 | ~ 480 .astro (frontmatter 더 짧음, 추정) |
| **Workers 호환** | 네이티브 | 네이티브 | GA(v13.0 2026-03-10) |
| **D1 binding** | `c.env.DB` | `c.env.DB` | `env.DB`(cloudflare:workers) / `Astro.locals.cfContext` |
| **dev/prod 갭** | 없음 | 없음 | 없음(workerd dev) |
| **Cycle 6 file plan 영향** | `app/routes/admin/*.tsx` 9개 + layout | A와 동일 + script 1줄 | `src/pages/admin/*.astro` 9개 + 별도 빌드 설정 |

## Hotwire Turbo Frame 의미적 차이 흡수 전략

R3 핵심 질문 #2의 결론은 **admin 범위에서 흡수할 차이가 없다**:

1. **현 admin은 Turbo Frame을 사용하지 않는다** (`server/app/views/admin/**` grep 결과: `<turbo-frame>` 0건). admin layout(`layouts/admin.html.erb:8`)은 `data-turbo-track: reload`만 — 자산 변경 시 풀 리로드 트리거.
2. **현 admin은 Stimulus를 사용하지 않는다** (8 controller 모두 `assessments/` 공개 흐름 전용). admin form은 표준 Rails redirect 패턴.
3. **현 admin은 optimistic update를 사용하지 않는다** (controller 8개 어디에도 admin DOM 조작 코드 없음).

따라서 **Brief In Scope 7 / Decision 4의 "Hotwire Turbo Frame 시맨틱 1:1 이식 불가 → 행동 변화 수용"** 우려는 admin scope에서 자동 해결. 단, **공개 평가 흐름 (Cycle 5/Public 화면)에서는 Stimulus 8개가 실재**하며 거기서 동등성 분석 필요 — R3 범위 밖이므로 Open Question으로 이관.

추가: hx-boost를 Pattern A에 1줄 추가하면 admin 페이지 전환이 SPA-like가 되며, 이는 현 Rails admin보다도 **개선** (현 admin은 Turbo Drive만 적용 → hx-boost와 거의 동등). 즉 Pattern A에 htmx CDN 1줄을 옵셔널로 두면 비용 0으로 UX 동등 확보.

## Cross-Analysis

### Foundation Disruption Test
Brief alignment anchor(In Scope 7, Decision 4, M11) + 실측 ground truth(admin 9 화면, Stimulus 0)를 결합하면:
- **Brief의 가정**: admin은 27 ERB + 8 Stimulus → Hotwire 동등성이 결정 가지의 핵심
- **실측 사실**: admin은 9 ERB + 0 Stimulus → Hotwire 동등성은 admin scope에서 무관
- **결론**: Brief 가정의 본 axis 부분은 **부정확**. 그러나 Brief가 위임한 결정 권한 그대로 사용해 winner 산출.

### 패턴 매트릭스 ↔ Priority Dimensions(Brief)
- Longevity: Pattern A·B 우위 (의존성 적음, framework churn 적음). C는 Astro 메이저 주기 부담.
- Sustainability(1인): A 최고, B 근소 추가, C 비대칭 (학습 + 이중 빌드)
- Cutover Safety: 무관 (admin은 Phase B에서 신규 가동, archive 회귀 시 Rails로 복귀하므로 패턴 선택과 무관)

### 잠재적 반론 — "콘텐츠 사이트 확장성"
공개 페이지(타로/성격 콘텐츠)에 향후 SEO·정적 prerender 필요 시 Astro 6의 강점 발휘. 그러나:
- 본 axis = **admin** 범위 한정
- 공개 페이지는 별도 axis 또는 후속 brief 사안
- admin과 공개 페이지를 같은 framework로 통일할 강제 요건 없음

## Comprehensive Conclusion

### R3-F1 Winner: **Pattern A — Hono SSR vanilla** (선택적 hx-boost 1줄 추가 권장)

### 근거

1. **실측 우선 원칙**: admin 9 화면 + Stimulus 0 + Turbo Frame 0 → 추가 추상화의 한계효용 음수.
2. **빌드 단일성** (Brief Constraints "단일 또는 매우 작은 개발팀"·"Sustainability"): A·B만 Workers 단일 빌드 충족. C는 이중 빌드.
3. **Hotwire 동등성 우려 해소**: admin scope에서 1:1 이식 부담 0 — Brief In Scope 7 C2 비평이 admin에서는 무의미.
4. **러닝 곡선 최소**: 사용자가 이미 TS·Hono 채택. 추가 학습 0.
5. **htmx 옵셔널 도입의 안전성**: hx-boost 1줄로 SPA-like 전환을 비용 0으로 추가 가능. 도입 안 해도 admin UX 손실 없음 (form full reload는 admin CRUD에 충분).
6. **Astro의 강점이 작동하는 영역(콘텐츠 사이트)**이 본 admin scope와 정합하지 않음.

### 잔여 위험

| Risk | 평가 | 완화 |
|------|------|------|
| 향후 admin이 복잡 인터랙션 추가(차트·실시간 등) | 중 | hx-boost → 명시적 `hx-target` 점진 도입(Pattern B로 자연 확장). framework 교체 불필요 |
| Hono JSX 메이저 변경 | 낮음 | Hono v4 LTS, JSX API 안정 |
| 공개 평가 흐름은 Astro가 더 적합할 가능성 | — | 본 axis 범위 밖, Open Q로 이관 |
| LOC 증가(+69%) 우려 | 낮음 | 9 화면 × 평균 55 LOC = 절대값 작음. JSX 타입 안전이 비용 정당화 |
| htmx 의존 시 lock-in | 매우 낮음 | hx-* 속성 제거만으로 vanilla form 회귀 가능 |

### Cycle 6 File Plan 초안

```
app/routes/admin/
  ├── index.tsx              # GET /admin — dashboard
  ├── question-sets.tsx      # GET /admin/question-sets — index
  ├── question-sets/[id].tsx # GET /admin/question-sets/:id
  ├── question-sets/new.tsx  # GET/POST /admin/question-sets/new
  ├── question-sets/[id]/edit.tsx
  ├── alerts.tsx             # GET /admin/alerts
  ├── alerts/[id].tsx        # GET/POST /admin/alerts/:id
  ├── audit-logs.tsx         # GET /admin/audit-logs
  └── audit-logs/[id].tsx
app/components/admin/
  ├── Layout.tsx             # admin nav + main 레이아웃
  ├── Card.tsx
  ├── Table.tsx
  └── StatusBadge.tsx
```

추정 9 routes + 4 components ≈ 600 TSX LOC. tsconfig는 `jsx: "react-jsx"` + `jsxImportSource: "hono/jsx"` 1회 설정.

## Open Questions

1. 공개 평가 흐름(`assessments/` 화면 + Stimulus 8개)의 admin 외 axis 결정 — R3 범위 밖. 별도 결정 필요(Hono SSR + 명시적 htmx 또는 Astro Islands 또는 Stimulus 직접 이식).
2. Brief의 "27 ERB + 8 Stimulus" 표기는 전체 ERB(27) + Stimulus(8) 합계로, admin과 공개 흐름이 분리되지 않은 채 기록됨. Brief를 amend할지 말지는 사용자 판단.
3. hx-boost 도입 시 CSP nonce·CSRF origin-check와의 상호작용은 Cycle 4(Auth+Security)에서 검증 필요(htmx는 same-origin이므로 통상 무이슈).

## References

### 1차 (공식)
- Hono JSX Guide — [hono.dev/docs/guides/jsx](https://hono.dev/docs/guides/jsx)
- Hono + HTMX 예제 — [hono.dev/examples/htmx](https://hono.dev/examples/htmx)
- Astro Cloudflare Adapter — [docs.astro.build/en/guides/integrations-guide/cloudflare](https://docs.astro.build/en/guides/integrations-guide/cloudflare/)
- Astro 6 GA blog — [astro.build/blog/astro-6](https://astro.build/blog/astro-6/)
- Astro joins Cloudflare — [blog.cloudflare.com/astro-joins-cloudflare](https://blog.cloudflare.com/astro-joins-cloudflare/)
- Cloudflare Workers Astro framework guide — [developers.cloudflare.com/workers/framework-guides/web-apps/astro](https://developers.cloudflare.com/workers/framework-guides/web-apps/astro/)
- htmx Hotwire Migration Guide — [htmx.org/migration-guide-hotwire-turbo](https://htmx.org/migration-guide-hotwire-turbo/)

### 2차 (해설·실측)
- Yusuke Wada (Hono 창시자) — Hono+htmx+Cloudflare stack — [blog.yusu.ke/hono-htmx-cloudflare](https://blog.yusu.ke/hono-htmx-cloudflare/)
- Radan Skoric — Hotwire vs htmx 의미 비교 — [radan.dev/articles/hotwire-and-htmx](https://radan.dev/articles/hotwire-and-htmx)
- @astrojs/cloudflare CHANGELOG — [github.com/withastro/adapters/blob/main/packages/cloudflare/CHANGELOG.md](https://github.com/withastro/adapters/blob/main/packages/cloudflare/CHANGELOG.md)
- honojs/examples (htmx 전용 예제 폴더 0건 확인, jsx-ssr·hono-vite-jsx 존재) — [github.com/honojs/examples](https://github.com/honojs/examples)

### 프로젝트 (실측 ground truth)
- `server/app/views/admin/dashboard/index.html.erb:1-20`
- `server/app/views/admin/alerts/{index.html.erb:1-42, show.html.erb:1-55}`
- `server/app/views/admin/audit_logs/{index.html.erb:1-26, show.html.erb:1-36}`
- `server/app/views/admin/question_sets/{index.html.erb:1-31, show.html.erb:1-46, new.html.erb:1-17, edit.html.erb:1-20}`
- `server/app/views/layouts/admin.html.erb:1-36`
- `server/app/javascript/controllers/{likert,autosave,countdown,progress,questionnaire,spectrum_bar,tabs,type_reveal}_controller.js`(8개, admin DOM 미사용)

### 트레이스
- Brief: [`001_Brief_cf_workers_rebuild.md`](./001_Brief_cf_workers_rebuild.md) — Decision 4(잠정), In Scope 7, M11
- Scope: [`007_Scope_cf_workers_rebuild.md`](./007_Scope_cf_workers_rebuild.md) — R3 4개 핵심 질문

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
