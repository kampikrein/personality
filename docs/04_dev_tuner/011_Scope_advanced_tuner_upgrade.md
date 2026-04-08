---
id: "011"
type: scope
title: "Dev Tuner 고급 업그레이드"
created: 2026-03-22
traces_brief: "010"
complexity: simple
research_needed: false
research_reason: "기존 Flutter Slider/GestureDetector 활용, 단일 모듈 내 변경, 유사 패턴 존재"
auto_run: true
effort_mode: bypass
uncertainty_level: low
intent: >
  Dev Tuner MVP를 고급 도구로 업그레이드: FAB 토글 버그 수정, 슬라이더+스테퍼 병행,
  플로팅 드래그/리사이즈 패널, 기본값 리셋, UI 크기 확대.
summary: >
  단일 영역(core/dev_tuner/) 4파일 수정. gesture disambiguation 수정 + 슬라이더 추가 +
  플로팅 패널 + 리셋 기능. research 불필요, bypass 모드.
keywords: [dev_tuner, slider, floating_panel, gesture, reset, upgrade]
---

# Dev Tuner 고급 업그레이드

## 작업 목표

Brief D1~D4 결정사항 구현:
1. **FAB 토글 버그 수정** — pan/tap gesture 충돌 해결 (이동 거리 threshold로 tap 판별)
2. **슬라이더 + 스테퍼 병행** — 각 변수에 Slider + ± 버튼 배치
3. **플로팅 패널** — 하단 고정 → 자유 위치 드래그 + 리사이즈
4. **기본값 리셋** — TunableDouble에 defaultValue 추가, 패널 헤더에 Reset 버튼
5. **UI 크기 확대** — FAB 48×48, 행 44px, 라벨 13px, 값 15px (WCAG 터치 타겟)

**제약**: kDebugMode 가드 유지, DevTunerRegistry API 변경 없음, 화면별 등록 코드 최소 변경.

## 접근 방향

단일 접근법 — 기존 4파일을 직접 수정:

1. `tunable_var.dart`: `defaultValue` 필드 추가 (optional, 기본값 = min과 동일하게 provider 초기값 사용)
2. `dev_tuner_overlay.dart`: 전면 리라이트
   - FAB: GestureDetector의 pan/tap 충돌 → `onPanStart`에서 시작 위치 기록, `onPanEnd`에서 이동 거리 < 10px이면 tap 처리
   - 패널: `Positioned(bottom)` → `Positioned(left, top)` 플로팅. 헤더 드래그로 이동, 하단 모서리로 리사이즈
   - 변수 행: 슬라이더 + 스테퍼 레이아웃
   - 헤더: Reset 아이콘 버튼 추가
3. `stepper_button.dart`: 크기 확대 (32→44px), 아이콘 크기 조정
4. 화면별 등록 코드: `defaultValue` 파라미터 추가 (optional이므로 기존 코드 동작 유지)

## Research 판단
- **판단**: 불필요
- **근거**: Flutter Slider/GestureDetector는 이미 익숙한 위젯. 단일 모듈 내 자기 완결적 변경. 기존 패턴 확장.
- **파이프라인**: S → Agent(P) → Agent(I) → Agent(V)

## 설계

### 변경 대상

**Modified (actual change)** — confidence: high
| # | 파일 | 변경 내용 |
|---|------|----------|
| 1 | `mobile/lib/core/dev_tuner/tunable_var.dart` | `defaultValue` 필드 추가 |
| 2 | `mobile/lib/core/dev_tuner/dev_tuner_overlay.dart` | 플로팅 패널, 슬라이더 행, FAB gesture 수정, 리셋 |
| 3 | `mobile/lib/core/dev_tuner/stepper_button.dart` | 크기 확대 (32→44px) |

**Reviewed (check-only)** — confidence: high
| # | 파일 | 확인 내용 |
|---|------|----------|
| 1 | `mobile/lib/core/dev_tuner/tuner_registry.dart` | API 호환성 확인 (변경 불필요 예상) |
| 2 | `mobile/lib/main.dart` | 변수 등록 코드 호환성 확인 |

### FAB Gesture 수정 설계
- `_panStartOffset` 상태 추가
- `onPanStart`: `_panStartOffset = details.globalPosition` 기록
- `onPanUpdate`: 기존 드래그 로직 유지
- `onPanEnd`: `(details.globalPosition - _panStartOffset).distance < 10` → `_expanded = !_expanded`
- `onTap` 제거 (pan이 모든 터치를 가져가므로)

### 플로팅 패널 설계
- `_panelOffset` 상태: 초기 위치 (16, screenHeight - 300)
- `_panelSize` 상태: 초기 크기 (screenWidth - 32, 280)
- 패널 헤더: 드래그로 `_panelOffset` 업데이트
- 패널 우하단 코너: 드래그로 `_panelSize` 업데이트 (최소 200×150)
- 변수 목록: `ListView` 또는 `SingleChildScrollView`로 스크롤 가능

### 슬라이더 + 스테퍼 행 설계
```
[Label 80px] [- btn 36px] [Slider flex] [+ btn 36px] [Value 60px]
```
- Slider: `SliderTheme` 커스텀 (tealAccent, thumb 20px)
- 스테퍼: 기존 StepperButton 재활용 (크기만 확대)
- 행 높이: 44px

### 리셋 설계
- `TunableDouble`에 `final double? defaultValue` 추가 (null이면 min 사용)
- 헤더에 `Icons.restart_alt` 버튼
- 탭 시 현재 route의 모든 변수를 defaultValue로 복원

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
