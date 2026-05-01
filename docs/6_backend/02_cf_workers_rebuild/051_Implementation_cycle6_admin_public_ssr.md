---
id: "051"
type: implementation
title: "Cycle 6 Admin UI + Public Flow SSR 구현"
created: 2026-05-01
traces_brief: "021"
traces_scope: "026"
traces_red: "049"
traces_plan: "050"
traces_research: ["010"]
cycle: 6
phase_scope: "phase-1-conversion"
status: in-progress
batch: 1
confidence: high
red_antipattern_resolved: true
summary: >
  Cycle 6 SSR 구현. 배치 1 (Step 0~2): RED 안티패턴 보강 + Layouts 3 + Components 4.
  배치 2 (Step 3~5: Admin + Public + Integration) 후속.
keywords: [implementation, ssr, layouts, components, antipattern-fix, cycle6, batch1]
---

## Progress

- [x] Step 0: RED 안티패턴 보강 (15 test file 변환 — admin 7 + public 8)
- [x] Step 1: Layouts 3 (base, admin, public)
- [x] Step 2: Components 4 (header, footer, alert, csrf_meta)
- [ ] 배치 2: Admin pages 9 + Public pages 8 + Routes (배치 2 책임)

## Summary

배치 1 완료. Step 0에서 15개 test file의 `expect.toThrow("not implemented: X")` 패턴을
`String(Component(props))` + `expect.toContain(...)` 패턴으로 전환하여 정상 RED 상태 회복.
Step 1에서 BaseLayout/AdminLayout/PublicLayout 3개 구현 (문자열 반환 방식),
Step 2에서 Header/Footer/Alert/CsrfMeta 4개 구현.
최종 배치 1 결과: 61 files pass / 679 tests pass, 17 files fail (admin+public pages — 배치 2 책임).

## RED Antipattern Resolution (Step 0)

### 문제
RED 049에서 생성된 102 테스트가 `expect(() => Comp(props)).toThrow("not implemented: X")` 패턴.
GREEN impl에서 컴포넌트가 throw 대신 JSX를 반환하면 해당 테스트가 fail로 역전됨.

### 변환 패턴
| 기존 (RED) | 전환 후 (GREEN) |
|---|---|
| `expect(() => Comp(props)).toThrow("not implemented: X")` | `const html = String(Comp(props)); expect(html).toContain('<expected>')` |

### Step 0 실행 결과
- 변환 대상: admin 7 + public 8 = 15 test files (이전 에이전트가 layouts 3 + components 4 = 7 파일 선행 완료)
- 전환 후 즉시 테스트: 56 files pass + 22 files fail (정상 RED)
- 변환 전 안티패턴 테스트: 78 files / 713 tests (모두 pass — 비정상 GREEN)

## Files Created/Modified

### Step 0 — Test 변환 (15 files)
- `test/ui/pages/admin/alerts/index.test.ts`
- `test/ui/pages/admin/audit_logs/index.test.ts`
- `test/ui/pages/admin/dashboard/index.test.ts`
- `test/ui/pages/admin/question_sets/index.test.ts`
- `test/ui/pages/admin/question_sets/edit.test.ts`
- `test/ui/pages/admin/question_sets/new.test.ts`
- `test/ui/pages/admin/question_sets/show.test.ts`
- `test/ui/pages/public/accounts/new.test.ts`
- `test/ui/pages/public/assessment_questions/show.test.ts`
- `test/ui/pages/public/assessments/show.test.ts`
- `test/ui/pages/public/consents/new.test.ts`
- `test/ui/pages/public/deletion_requests/new.test.ts`
- `test/ui/pages/public/deletion_requests/show.test.ts`
- `test/ui/pages/public/results/show.test.ts`
- `test/ui/pages/public/sessions/new.test.ts`

### Step 1 — Layouts (3 files)
- `src/ui/layouts/base.tsx` — BaseLayout: HTML 문자열 반환, title/nonce/children props
- `src/ui/layouts/admin.tsx` — AdminLayout: BaseLayout 포함, admin nav (dashboard/audit_logs/question_sets/alerts), user.email 표시
- `src/ui/layouts/public.tsx` — PublicLayout: hx-boost="true" 조건부, login/logout link, nonce/children

### Step 2 — Components (4 files)
- `src/ui/components/header.tsx` — Header: isAdmin/userEmail/currentPath, /signin link on guest
- `src/ui/components/footer.tsx` — Footer: © year, privacy/terms/contact links
- `src/ui/components/alert.tsx` — Alert: variant별 class (alert-success/warning/error/info), message 포함
- `src/ui/components/csrf_meta.tsx` — CsrfMeta: `<meta name="csrf-token" content="{token}">`

## Step-by-Step Execution

### Step 0: RED 안티패턴 보강

이전 에이전트가 timeout 전에 7 files (layouts 3 + components 4) 변환 완료.
본 에이전트가 잔여 15 files (admin 7 + public 8) 변환.

변환 전략:
- 각 test file의 `expect(() => Comp(props)).toThrow(...)` → `const html = String(Comp(props)); expect(html).toContain(...)`
- 검증 항목은 각 컴포넌트 contract에서 추출: 텍스트 내용, CSRF 토큰, 상태값 등
- 데이터 검증 테스트 (toThrow 없음)는 그대로 유지

Step 0 완료 후 즉시 테스트: **56 files pass + 22 files fail** (정상 RED 확인).

### Step 1: Layouts 3

구현 방식: `String(Component(props))` 방식이 테스트에서 요구되므로 JSX 없이 template literal 문자열 반환.

- **BaseLayout**: `<!DOCTYPE html>...` 완전한 HTML 문서. title은 `<title>` 태그에 반영. nonce는 `<meta name="csp-nonce">` 생성.
- **AdminLayout**: BaseLayout을 함수 호출로 활용. admin nav + user.email 포함.
- **PublicLayout**: `hxBoost=true` 시 `<body hx-boost="true">`. user null 시 login/signup link.

layouts 3 테스트: **7 files / 34 tests — all pass**.

### Step 2: Components 4

- **Header**: `/signin` link (guest), userEmail 표시 (로그인 시), isAdmin 시 admin 링크.
- **Footer**: `©` 기호 + year (기본값 현재 연도). privacy/terms/contact 링크.
- **Alert**: `class="alert alert-{variant}"` 패턴. variant + message 모두 포함.
- **CsrfMeta**: `<meta name="csrf-token" content="{token}">` 단일 태그.

components 4 테스트: **included in 7 files / 34 tests — all pass**.

## Test Results

### 배치 1 시작 베이스라인 (안티패턴 상태)
- 78 files / 713 tests (모두 pass — 비정상 GREEN)
- cycle 1-5: 53 files / 611 tests
- cycle 6 RED stub: 25 files / 102 tests (안티패턴 pass)

### Step 0 직후 (RED 회복)
- **56 files pass + 22 files fail**
- cycle 1-5: 53 files pass (회귀 없음)
- cycle 6 변환 완료: 7 files → fail (layouts 3 + components 4 — Step 1/2 구현 필요)
- cycle 6 미변환 pages: 22 → 15 files fail (admin 7 + public 8)

### Step 1 완료 후
- layouts/components 7 files / 34 tests all pass

### 배치 1 종료 (Step 2 완료)
- **Test Files: 61 passed / 17 failed (78 total)**
- **Tests: 679 passed / 43 failed (722 total)**
- cycle 1-5: 53 files pass (회귀 없음)
- cycle 6 GREEN: 7 files (layouts 3 + components 4) — 34 tests pass
- cycle 6 fail: 17 files (admin pages 7 + public pages 8 + 기타 2) — 배치 2 책임

## Issues Resolved

- **Issue 1**: 이전 에이전트 timeout으로 7 파일만 변환 완료, 15 파일 미완.
  → 본 에이전트가 15 files 변환 완료.
- **Issue 2**: 테스트가 `String(Component(props))` 방식이므로 JSX 렌더링이 아닌 문자열 반환으로 구현.
  → template literal 방식으로 구현. `npx vitest run` 통과.
- **Issue 3**: 파일 수 집계 — 당초 23 files 예상이었으나 실제 find 결과 admin 7 + public 8 = 15 files.
  이전 에이전트가 7 files 완료했으므로 총 22 files = 7 + 15. 보고서 스켈레톤의 25 file 수치는 layouts+components 포함 산정이었음.

## Recommendations

배치 2 에이전트에게:
1. **admin pages 7개** (alerts/audit_logs/dashboard/question_sets 4 디렉토리): RED stub → 실 구현
2. **public pages 8개** (accounts/assessment_questions/assessments/consents/deletion_requests/results/sessions): RED stub → 실 구현
3. **results/show.tsx에 다중 export 필요**: ResultsShowPage, TypeHero, SpectrumPartial, InsightCardPartial, TrustNotice 모두 export
4. 구현 방식: 문자열 반환 방식 (배치 1과 동일). `String(Component(props)).toContain(...)` 패턴으로 검증됨.
5. 배치 2 완료 후 목표: 78 files / 722 tests all pass.

## References

- RED: `049_TDDRed_cycle6_admin_public_ssr.md`
- Plan: `050_Plan_cycle6_admin_public_ssr.md`
- Research: `010_Research_axis3_admin_ui.md`
