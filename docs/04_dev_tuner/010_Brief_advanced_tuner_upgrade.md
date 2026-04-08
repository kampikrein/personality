---
id: "010"
type: brief
title: "Dev Tuner 고급 업그레이드"
created: 2026-03-22
status: completed
summary: >
  Dev Tuner를 고급 도구로 업그레이드: 슬라이더+스테퍼 병행 인터랙션,
  플로팅 드래그/리사이즈 패널, 기본값 리셋 버튼, FAB 토글 버그 수정.
keywords: [dev_tuner, ux, slider, gesture, overlay, advanced]
---

# Dev Tuner 고급 업그레이드

## Intent
현재 Dev Tuner가 MVP 수준으로 너무 기본적이며, 실사용 시 다음 문제가 있다:
1. **닫기 버그** — 한번 열면 닫기가 안 됨 (gesture 충돌 추정)
2. **너무 작은 UI** — 40×40 FAB, 32×32 버튼, 11px 라벨. 터치 타겟 부족
3. **체감 부족** — stepper `<`/`>` 탭 방식은 연속 조정에 부적합. 실시간 피드백 없음
4. **인터랙션 빈약** — 슬라이더/드래그 없이 탭·롱프레스만 지원

고급 개발 도구로서 빠르고 정밀한 조작이 가능한 튜너로 업그레이드하고자 함.

## Context

### 현재 구조
- **오버레이**: `MaterialApp.builder` Stack 내 `DevTunerOverlay` (ConsumerStatefulWidget)
- **FAB**: 40×40px, 드래그 가능, 탭으로 패널 토글
- **패널**: 화면 하단 고정, 전폭 - 32px, black87 배경
- **컨트롤**: `StepperButton` — 탭 1회 = 1 step, 롱프레스 = 80ms 간격 연속 step
- **변수**: `TunableDouble` (label, provider, min, max, step)

### 핵심 파일
| 파일 | 역할 |
|------|------|
| `mobile/lib/core/dev_tuner/dev_tuner_overlay.dart` | 메인 오버레이 UI |
| `mobile/lib/core/dev_tuner/stepper_button.dart` | +/- 버튼 위젯 |
| `mobile/lib/core/dev_tuner/tunable_var.dart` | 변수 모델 |
| `mobile/lib/core/dev_tuner/tuner_registry.dart` | 변수 레지스트리 |

### 등록된 변수 (4개 화면)
- **Global**: mass, stiffness, damping (spring 파라미터)
- **Reading**: cardHeight%, padding
- **Intention**: iconSize, padding
- **Deck**: listPad

### 알려진 버그
- FAB의 `GestureDetector`에 `onPanUpdate`(드래그)와 `onTap` 공존
  → 미세 이동 시 pan이 tap을 먹음 → 닫기 불가

## Boundaries

### In Scope
| # | Item | Description |
|---|------|-------------|
| 1 | FAB 토글 버그 수정 | gesture disambiguation 해결, 안정적 열기/닫기 |
| 2 | 슬라이더 + 스테퍼 병행 | 슬라이더로 빠른 조정, ±버튼으로 미세 조정 |
| 3 | 플로팅 패널 | 자유 위치 드래그 + 리사이즈 가능 |
| 4 | UI 크기/가독성 개선 | 터치 타겟, 폰트, 여백 확대 |
| 5 | 기본값 리셋 | 변수별 또는 전체 기본값 복원 버튼 |

### Out of Scope
| # | Item | Reason |
|---|------|--------|
| 1 | 새 변수 추가 | 별도 작업 |
| 2 | Release 빌드 포함 | kDebugMode 가드 유지 |
| 3 | 설정 영속화 | 개발 도구 — 세션 휘발 OK |

## Decisions

| # | Decision | Chosen | Rationale |
|---|----------|--------|-----------|
| 1 | 인터랙션 방식 | 슬라이더 + 스테퍼 병행 | 슬라이더로 대략 조정 + ±버튼으로 정밀 조정. 양쪽 장점 결합 |
| 2 | 패널 레이아웃 | 플로팅 패널 | 자유 위치 드래그 + 리사이즈. 화면 구성에 방해 안 되게 이동 가능 |
| 3 | 리셋/프리셋 | 리셋만 | "기본값 복원" 버튼. 프리셋 저장은 과도한 복잡성 |
| 4 | FAB 토글 | gesture 충돌 수정 필수 | pan/tap 분리로 안정적 열기/닫기 보장 |

## Open Questions

| # | Question | Impact | Status |
|---|----------|--------|--------|
| 1 | 인터랙션 방식 | 핵심 UX 결정 | resolved → D1 |
| 2 | 패널 레이아웃 | 레이아웃 구조 결정 | resolved → D2 |
| 3 | 리셋/프리셋 | 기능 범위 결정 | resolved → D3 |

## Constraints
- debug 전용 — release 빌드에 흔적 없어야 함
- 기존 `TunableDouble` / `DevTunerRegistry` API 호환 유지
- 변수 등록 화면 코드 최소 변경

## Exit Criteria
- 닫기 버그 원인·해법 합의
- 인터랙션 방식 결정
- 패널 레이아웃 방향 결정
- 기능 범위 확정 (리셋, 프리셋 등)

## Model Anchors

1. **FAB gesture 수정**: `onPanUpdate` + `onTap` 충돌 해결. 방법: `onPanEnd`에서 이동 거리 < threshold(~10px)이면 tap으로 처리, 또는 별도 닫기 버튼 추가. 패널 열기/닫기가 100% 동작해야 함.

2. **슬라이더 + 스테퍼 병행**: 각 `TunableDouble` 행에 `Slider` (min~max, 연속) + 양쪽 `±` 버튼(step 단위) 배치. 기존 `StepperButton` 재활용 가능. 슬라이더 thumb 최소 44px 터치 타겟.

3. **플로팅 패널**: 하단 고정(`Positioned bottom`) → `Positioned`(left, top) 자유 배치. 패널 헤더 드래그로 이동. 패널 하단/우측 모서리 드래그로 리사이즈. FAB 드래그와 독립.

4. **리셋**: 패널 헤더에 "Reset" 아이콘 버튼. 현재 route의 모든 변수를 초기값으로 복원. `TunableDouble`에 `defaultValue` 필드 추가 필요.

5. **UI 크기 확대**: FAB 48×48 이상, 변수 행 높이 44px 이상, 라벨 13px 이상, 값 표시 15px 이상. WCAG 터치 타겟 44×44px 기준 준수.

6. **기존 API 호환**: `TunableDouble` 생성자에 `defaultValue` 파라미터만 추가 (optional, 기본값 = min). `DevTunerRegistry` API 변경 없음. 화면별 등록 코드 수정 불필요.

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
