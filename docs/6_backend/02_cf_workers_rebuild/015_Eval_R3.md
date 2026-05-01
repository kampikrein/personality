---
id: "015"
type: eval
title: "Eval R3 — Admin UI 패턴"
created: 2026-04-29
traces_research: "010"
verdict: proceed
depth_score: 6
k_score: 3
c_score: 3
cycle: 3
phase: research
brief_correction_signal: false
---

# Eval R3 — Admin UI 패턴

## Verdict + Depth

**Verdict: PROCEED**
**Depth Score: 6/6** (K: 3/3, C: 3/3)

Research 산출물 010이 R3 핵심 질문 4개에 완전 답변하고 3개 패턴의 winner를 명확하게 결정했다. 탐색 범위도 1차 출처 7건 + 2차 출처 4건 + 프로젝트 실측 14건으로 충분히 넓다.

---

## Q1–Q4 Coverage

| Q# | 질문 | 답변 품질 | 증거 |
|----|------|----------|------|
| Q1 | Astro 6 workerd 어댑터 GA 상태·D1 binding·학습 곡선 | **완전** | 2026-03-10 GA 날짜·v13.0 명시, `cloudflare:workers` env API 예시, 1인 운영자 학습 곡선 평가 |
| Q2 | Hono+HTMX Hotwire 동등성 | **완전 + 재정의** | htmx Hotwire Migration Guide 1차 인용, Radan Skoric 2차, "admin scope에서 동등성 비교 moot" 결론 |
| Q3 | Hono SSR vanilla LOC/DX/유지비 (9 화면) | **완전** | 495 TSX LOC 추정, 화면별 세분화, DX·유지비 평가 |
| Q4 | 빌드 시스템 단일성 | **완전** | A·B = wrangler 단일, C = Astro+Vite 이중 — 1인 운영자에게 C의 결정적 단점으로 명시 |

Q1은 Scope에서 "Astro 6 (2026-01 CF 인수)" 기준으로 묻는데, 실제 GA는 2026-03-10으로 확인해 갱신했다. CF 인수 발표(2026-01-16)와 GA(2026-03-10) 타임라인을 명확히 분리한 점이 Q1 답변의 신뢰도를 높인다.

---

## 1차 출처 인용 검증

R&E 총 인용 11건. 1차(공식) 7건:

1. `hono.dev/docs/guides/jsx` — Hono JSX 공식
2. `hono.dev/examples/htmx` — Hono+HTMX 공식 예제
3. `docs.astro.build/en/guides/integrations-guide/cloudflare` — Astro CF Adapter 공식
4. `astro.build/blog/astro-6` — Astro 6 GA 공식 블로그
5. `blog.cloudflare.com/astro-joins-cloudflare` — CF 인수 발표 공식
6. `developers.cloudflare.com/workers/framework-guides/web-apps/astro` — CF Workers Astro 공식
7. `htmx.org/migration-guide-hotwire-turbo` — htmx 공식 Hotwire 마이그레이션 가이드

**1차 출처 7건 ≥ 5건 기준 충족.**

2차(해설·실측) 4건도 신뢰할 수 있는 출처(Hono 창시자 Yusuke Wada, Radan Skoric, @astrojs/cloudflare CHANGELOG, honojs/examples).

---

## Clear Decision — 3 패턴 Winner

**Winner: Pattern A — Hono SSR vanilla (선택적 hx-boost 1줄 추가 권장)**

근거 6가지가 명시적이고 구체적:
1. 실측 ground truth: admin 9 화면 + Stimulus 0 → 추가 추상화 한계효용 음수
2. 빌드 단일성: A·B만 wrangler 단일, C는 이중
3. Hotwire 동등성 우려 해소: admin scope에서 1:1 이식 부담 0
4. 러닝 곡선 최소: 추가 학습 0
5. htmx 옵셔널의 안전성: hx-boost 1줄로 비용 0 UX 개선 가능
6. Astro 강점의 영역 불일치

Winner 결정은 역방향 위험(잔여 위험 5건 식별·평가)까지 포함해 충분히 견고하다.

---

## Brief 실측 정정 평가

### 발견 내용

Research 010이 실측한 수치:
- **Admin ERB**: Brief 표기 27 → 실측 **9** (admin/ 한정)
- **Admin LOC**: 1,788 전체 ERB → 실측 **293** (admin LOC)
- **Stimulus 컨트롤러**: Brief 표기 8 → admin 사용 **0** (8개 모두 공개 평가 흐름 전용)

### OK 판단 — Brief 정정 신호 아님 (`brief_correction_signal: false`)

Brief의 "27 ERB + 8 Stimulus" 표기는 **전체 Rails 자산 인벤토리** 기준 합계였으며, `003_Agent_current_rails_assets.md`를 출처로 명시했다. Brief Context 섹션 ("15 모델, 13 컨트롤러 + admin, 20 services (1,850 LOC), **27 ERB, 8 Stimulus**")은 전체 뷰 레이어 카운트이고, admin을 별도로 집계한 게 아니다.

Brief In Scope 7은 "Hotwire 2 템플릿에 한정"이라는 이전 연구(010 from 01_cloudflare_migration_research)를 인용해 이미 **범위가 좁다는 신호**를 포함하고 있었다. 또한 Brief Decision 4에서 "Hotwire admin이 2 템플릿에 한정 → 전면 재작성 부담 가벼움"이라고 명시되어 있어, Brief 자체가 admin이 작다는 사실을 내포하고 있었다.

따라서:
- **Brief의 27/8 숫자는 전체 자산 인벤토리 합계로서 맥락상 정확**하다.
- **admin scope 분리 집계(9 ERB / 293 LOC)**는 R3 research가 정밀화한 것으로, Brief의 오류가 아니다.
- Brief amend 불필요. Research 010 Open Question 2도 "Brief를 amend할지 말지는 사용자 판단"으로 유보했으나, **eval 관점에서는 정정 신호 없음**으로 판정한다.

---

## Open Question 이관 권고

Research 010의 Open Question 1:

> **공개 평가 흐름 (`assessments/` 화면 + Stimulus 8개)**의 admin 외 axis 결정

- Stimulus 8개(likert/autosave/countdown/progress/questionnaire/spectrum_bar/tabs/type_reveal)는 모두 공개 평가 흐름 전용이다.
- 이 흐름에서 Hono SSR + 명시적 htmx vs Astro Islands vs Stimulus 직접 이식 결정이 필요하다.
- **별도 사이클 추가 여부**: 현재 Cycle 5 (API Layer + Mobile Contract)와 Cycle 6 (Admin UI) 사이에서 공개 평가 흐름 UI 패턴은 명시적으로 다뤄지지 않는다. Cycle 5는 API 레이어 + OpenAPI codegen이며 공개 평가 흐름의 서버사이드 뷰 패턴은 포함 범위가 불명확하다.
- **권고**: 이 Open Question은 현재 파이프라인의 구현 사이클이 시작되기 전에 gate가 scope 담당자에게 전달해야 한다. 별도 research axis 추가가 필요한지 여부는 gate가 Scope 007과 대조하여 판단 범위다. Eval은 "Cycle 5 makeplan 진입 전 scope 확인 요청"을 권고사항으로 기록한다.

---

## Cross-Axis Observations

1. **Cycle 4 (Auth + Security) 연동**: hx-boost 도입 시 CSP nonce·CSRF origin-check 상호작용 검증 필요 — research 010이 이미 Cycle 4로 이관함. 별도 처리 불필요.
2. **Cycle 5 (API Layer) 연동**: admin UI (Hono SSR)가 admin API 또는 services 직접 호출 — R3 winner(Pattern A)는 `c.env.DB` 직접 또는 Hono 라우터를 통한 서비스 계층 호출이 모두 자연스럽다. Cycle 5 makeplan에서 admin과 API 분리 전략 명확화 필요.
3. **Astro 기각 사유 갱신**: Brief Decision 4 "Alternatives" 컬럼의 "Astro 기각 사유 갱신 (이전 '오버엔지니어링' → 'scope 결정')"이 research 010에서 **"빌드 이중화·학습 곡선 비대칭"으로 구체화**됐다. 이 구체화는 Brief가 위임한 결정 권한의 적절한 행사다.

---

## Recommended Changes

```yaml
recommended_changes: []
# PROCEED — 추가 조치 없음. Cycle 6 (Admin UI) 구현으로 진행.
# Gate 전달사항:
#   1. Open Question (공개 평가 흐름 Stimulus 8개 패턴)은
#      Cycle 5 makeplan 진입 전 Scope 담당자에게 전달할 것.
#      별도 research axis 추가 여부는 gate 판단.
#   2. Brief 정정 신호 없음 — Brief amend 불필요.
```

---

## Findings Preserved

| ID | 유형 | 내용 |
|----|------|------|
| EV-015-D1 | Discovery | admin 실측: 9 ERB / 293 LOC / Stimulus 0 / Turbo Frame 0 → Brief의 27/8 합계와 admin 세부 분리 명확화 |
| EV-015-D2 | Discovery | Astro 6.0 GA는 2026-01 CF 인수 발표(2026-01-16) 후 2026-03-10에 별도 릴리스됨. CF 인수가 GA를 가속했으나 인수 = GA 아님 |
| EV-015-D3 | Discovery | htmx는 hono/jsx와 동일 wrangler 빌드 내에서 CDN 1줄로 완전 통합 가능 — 별도 빌드 단계 불필요 |
| EV-015-C1 | Conflict | Brief "27 ERB + 8 Stimulus"는 전체 자산, Scope R3은 "27 ERB + 8 Stimulus admin"으로 조사 대상을 admin으로 한정 기술 — 숫자 동일하나 의미(전체 vs admin) 불일치. 실측으로 해소됨 |
| EV-015-A1 | Assumption | Scope R3가 "Hotwire 동등성"을 핵심 질문으로 설정한 것은 admin이 Hotwire를 사용한다는 암묵적 가정 위에 있었음. 실측으로 가정 부정됨 — R3 자체 내에서 해소 |
| EV-015-S1 | Side-effect | Stimulus 8개가 공개 평가 흐름 전용임이 확인됨 → Cycle 5 (공개 API + Flutter) 또는 별도 research axis에서 평가 흐름 UI 패턴 결정 필요. Scope 007에 명시된 사이클 중 이 영역이 명시적으로 포함된 곳 없음 |

---

## Cycle 6 (Admin UI) Deliverables

Winner 결정 근거에서 직접 도출:

### 구현 패턴
**Pattern A — Hono SSR vanilla** (선택적 hx-boost 1줄 포함)

### 파일 구성 (연구 010 초안 기반)
```
app/routes/admin/
  ├── index.tsx              # GET /admin — dashboard (3 카드, ~30 LOC)
  ├── question-sets.tsx      # GET /admin/question-sets — index (~50 LOC)
  ├── question-sets/[id].tsx # GET /admin/question-sets/:id (~70 LOC)
  ├── question-sets/new.tsx  # GET/POST /admin/question-sets/new (~30 LOC)
  ├── question-sets/[id]/edit.tsx (~30 LOC)
  ├── alerts.tsx             # GET /admin/alerts (~60 LOC)
  ├── alerts/[id].tsx        # GET/POST /admin/alerts/:id (상태 업데이트, ~80 LOC)
  ├── audit-logs.tsx         # GET /admin/audit-logs (~40 LOC)
  └── audit-logs/[id].tsx    (~55 LOC)
app/components/admin/
  ├── Layout.tsx             # admin nav + main (~50 LOC)
  ├── Card.tsx
  ├── Table.tsx
  └── StatusBadge.tsx
```
총 추정: **~600 TSX LOC** (9 routes + 4 components)

### tsconfig 설정
```json
{ "jsx": "react-jsx", "jsxImportSource": "hono/jsx" }
```
(기존 Workers project tsconfig에 2줄 추가, 별도 빌드 도구 불필요)

### 선택적 hx-boost
admin Layout.tsx에 `<script src="https://unpkg.com/htmx.org@2" defer></script>` 1줄.
`hx-boost="true"`를 nav `<a>` 또는 `<body>`에 추가하면 페이지 전환 SPA-like. 도입 안 해도 기능 손실 없음.

### Cycle 6 TDD 체크포인트
- 각 route GET 핸들러: 200 반환 + HTML body 포함 검증
- alerts POST: 상태 업데이트 후 D1 기록 확인 + redirect 검증
- Layout: CF Access 인증 헤더 없을 때 401/redirect (Cycle 4 auth middleware 연동)

---

## Terminal Output

```
== Eval: Research Cycle 3 Complete ==
Depth Score: 6/6 (K:3 C:3)
Critical gate: PASS
Verdict: PROCEED
Findings: D:3 C:1 A:1 S:1 (6건)
Document: docs/6_backend/02_cf_workers_rebuild/015_Eval_R3.md
```

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
