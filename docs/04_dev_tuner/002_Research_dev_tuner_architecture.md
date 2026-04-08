---
id: "002"
type: research
title: "Dev Tuner 아키텍처 연구 — 라우트 감지·변수 레지스트리·오버레이 UI"
created: 2026-03-18
status: in-progress
traces_scope: "001"
summary: >
  Universal Dev Tuner 구현을 위한 아키텍처 연구. GoRouter 라우트 감지, Riverpod 변수 레지스트리,
  오버레이 UI 패턴, 기존 화면별 하드코딩 변수 탐색.
keywords: [gorouter, riverpod, overlay, stepper, debug-panel, route-detection]
parallel_plan:
  total_perspectives: 3
  phases:
    - phase: 1
      perspectives: [1, 2, 3]
      status: completed
      agent_numbers: ["003", "004", "005"]
  synthesis_number: "006"
  final_number: "007"
---

# Dev Tuner 아키텍처 연구

## Research Overview

### Background & Motivation
현재 Spring Tuner는 main.dart에 3개 스프링 물리 변수(mass, stiffness, damping)만 하드코딩되어 있다.
이를 범용 Dev Tuner로 확장하려면 화면별 변수 등록, 라우트 감지, 오버레이 UI 아키텍처가 필요하다.
프로젝트에 유사 패턴이 없으므로 Flutter+Riverpod 생태계에서의 최적 접근법을 조사한다.

### Research Scope
- 포함: GoRouter 라우트 감지, Riverpod 변수 관리, Flutter 오버레이, 스텝퍼 UI, 기존 화면 변수 탐색
- 제외: DevTools Extension, 외부 디버그 라이브러리, 서버 사이드 설정

### Research Perspectives
1. **GoRouter 라우트 감지 + 변수 레지스트리 설계** — 현재 화면 이름 추출, Riverpod 기반 변수 집합 관리
2. **오버레이 UI + 스텝퍼 컨트롤 패턴** — OverlayEntry vs builder, < N > 스텝퍼, kDebugMode 가드
3. **기존 화면별 하드코딩 변수 탐색** — 5개 화면의 튜닝 가능 변수 식별

## Preliminary Findings
Pending parallel investigation.

## Parallel Execution Instructions

### Perspective 1: GoRouter 라우트 감지 + 변수 레지스트리 설계

**조사 대상 파일:**
- `mobile/lib/core/router/app_router.dart` — 현재 GoRouter 설정, route names
- `mobile/lib/main.dart` — 현재 springMass/Stiffness/Damping StateProvider

**내부 코드 조사:**
1. GoRouter 인스턴스에서 현재 활성 route name을 추출하는 방법 조사
   - `GoRouter.of(context).routerDelegate.currentConfiguration`
   - `GoRouter.addListener()` 콜백
   - `GoRouterState` 활용법
2. 현재 app_router.dart의 route 구조 분석 (5개 route: home, deck, intention, shuffle, reading)
3. Riverpod에서 화면별 변수 집합을 관리하는 패턴 설계:
   - Map<String, List<TunableVariable>> 형태의 레지스트리
   - StateNotifier vs ChangeNotifier vs 단순 Map
   - Provider family로 화면별 분리 vs 단일 글로벌 레지스트리

**외부 조사:**
- GoRouter 공식 문서에서 route change listener 패턴 (WebSearch)
- Riverpod에서 동적 provider 등록 패턴 사례 (WebSearch)

**산출물:** `docs/15_dev_tuner/003_Agent_route_registry.md`

### Perspective 2: 오버레이 UI + 스텝퍼 컨트롤 패턴

**조사 대상 파일:**
- `mobile/lib/main.dart` — 현재 SpringDebugPanel (lines 113-258), PersonalityApp builder (lines 80-112)
- `mobile/lib/core/theme/app_theme.dart` — 테마 설정

**내부 코드 조사:**
1. 현재 Spring Tuner의 오버레이 구현 분석:
   - MaterialApp.builder의 Positioned.fill + Stack 패턴
   - 드래그 가능 FAB 구현 (onPanUpdate)
   - 커스텀 슬라이더 구현
2. OverlayEntry 기반 대안 vs 현재 builder 기반 비교:
   - 장단점, 히트 테스트 동작 차이
   - Overlay.of(context) 접근성
3. `< N >` 스텝퍼 컨트롤 구현 방안:
   - < 버튼으로 감소, > 버튼으로 증가
   - 중앙에 현재 값 표시 (탭하면 직접 입력?)
   - step 크기 설정 (변수별 다른 step)
4. kDebugMode 가드:
   - 릴리즈 빌드에서 튜너 완전 제거 (tree shaking)
   - `import 'package:flutter/foundation.dart'` → `kDebugMode`

**외부 조사:**
- Flutter OverlayEntry 공식 가이드 패턴 (WebSearch)
- Flutter debug overlay 구현 사례 (WebSearch)

**산출물:** `docs/15_dev_tuner/004_Agent_overlay_ui.md`

### Perspective 3: 기존 화면별 하드코딩 변수 탐색

**조사 대상 파일:**
- `mobile/lib/features/home/presentation/pages/home_page.dart` — 홈 화면
- `mobile/lib/features/shuffle/presentation/pages/shuffle_page.dart` — 셔플 화면
- `mobile/lib/features/reading/presentation/pages/reading_page.dart` — 리딩 화면
- `mobile/lib/features/shuffle/presentation/pages/intention_page.dart` — 의도 설정 화면
- `mobile/lib/features/deck/presentation/pages/deck_selection_page.dart` — 덱 선택 화면
- `mobile/lib/features/shuffle/presentation/game/tarot_game.dart` — Flame 게임 엔진
- `mobile/lib/features/shuffle/presentation/game/card_body_component.dart` — 카드 물리
- `mobile/lib/features/shuffle/presentation/game/hand_animation_component.dart` — 손 애니메이션
- `mobile/lib/features/reading/presentation/widgets/spread_layout.dart` — 스프레드 레이아웃
- `mobile/lib/features/reading/presentation/widgets/card_reveal_widget.dart` — 카드 공개 위젯
- `mobile/lib/core/theme/app_theme.dart` — 테마 변수

**내부 코드 조사:**
1. 각 화면에서 하드코딩된 숫자값 식별:
   - 크기 (width, height, fontSize)
   - 간격 (padding, margin, SizedBox)
   - 애니메이션 (duration, curve 파라미터)
   - 색상 (Color hex values)
   - 물리 파라미터 (Flame/forge2d 관련)
2. 어떤 값이 "튜닝 가능"한지 판별:
   - UI 레이아웃 파라미터 (padding, size) → 튜닝 가능
   - 애니메이션 속도/곡선 → 튜닝 가능
   - 물리 엔진 파라미터 → 튜닝 가능
   - 비즈니스 로직 상수 (카드 수 등) → 튜닝 불가
3. 변수별 적절한 타입 (double, int, bool, enum)과 범위(min/max) 제안

**산출물:** `docs/15_dev_tuner/005_Agent_screen_variables.md`

## Remaining Work
- [ ] Perspective 1: GoRouter 라우트 감지 + 변수 레지스트리 설계
- [ ] Perspective 2: 오버레이 UI + 스텝퍼 컨트롤 패턴
- [ ] Perspective 3: 기존 화면별 하드코딩 변수 탐색
- [ ] Cross-Analysis
- [ ] Comprehensive Conclusion

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 0s | 0 |
| 2 | user-ai-exchange | 19s | 76045 |
| 3 | user-ai-exchange | 11s | 40778 |
| 4 | user-ai-exchange | 10s | 42195 |
| 5 | user-ai-exchange | 9s | 44183 |
| 6 | user-ai-exchange | 14s | 46529 |
| 7 | user-ai-exchange | 5s | 48356 |
| 8 | user-ai-exchange | 9s | 50568 |
| 9 | user-ai-exchange | 13s | 105037 |
| 10 | user-ai-exchange | 12s | 54453 |
| 11 | user-ai-exchange | 11s | 55874 |
| 12 | user-ai-exchange | 12s | 57359 |
| 13 | user-ai-exchange | 14s | 58996 |
| 14 | user-ai-exchange | 13s | 60582 |
| 15 | user-ai-exchange | 8s | 61831 |
| 16 | user-ai-exchange | 11s | 63033 |
| 17 | user-ai-exchange | 29s | 202688 |
| 18 | user-ai-exchange | 11s | 140060 |
| 19 | user-ai-exchange | 11s | 71985 |
| 20 | user-ai-exchange | 9s | 147944 |
| 21 | user-ai-exchange | 14s | 76148 |
| 22 | user-ai-exchange | 19s | 0 |
| 23 | user-ai-exchange | 10s | 41780 |
| 24 | user-ai-exchange | 13s | 45110 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 341150s |
| Total Tokens | 1591534 |
| Input Tokens | 71 |
| Output Tokens | 8834 |
| Cache Read | 1202235 |
| Cache Creation | 380394 |
