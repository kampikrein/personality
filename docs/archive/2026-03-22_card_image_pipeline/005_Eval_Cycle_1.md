---
id: "005"
type: eval
title: "Eval: Cycle 1 — Flame 뒷면 Sprite + 동적 카드 수"
created: 2026-03-22
cycle: 1
effort_mode: standard
persona: default
verdict: proceed
depth_score: 9
critical_gate: PASS
terminate: false
recommended_changes: []
summary: >
  Cycle 1 핵심 목표(card_back.webp Sprite 렌더링 + 동적 카드 수)는 Brief/Scope intent에
  정확히 부합하여 구현됨. ShufflePage에서 entropy/sensor UI 제거는 Plan 범위 초과이나,
  셔플 연출 전환(중력 산란→방사형 산란)과 일관된 정리이며, 제거된 기능의 소스 파일과
  provider는 유지되어 복원 가능. Cycle 2 진행에 필요한 인프라(deckId 전달, 이미지 경로 규약) 확립 완료.
---

# Eval: Cycle 1 — Flame 뒷면 Sprite + 동적 카드 수

## 1. 시그널 수집 결과

### Scope 문서 (002) intent 대비

| Scope intent | 구현 여부 | 비고 |
|---|---|---|
| CardBodyComponent에 card_back.webp Sprite 렌더링 | O | SpriteComponent child 패턴 (R-003-F1) |
| TarotGame에서 Sprite 로딩, 덱 메타데이터 수신 | O | images.load() + deckId/cardCount 파라미터 |
| ShufflePage에서 덱 정보 전달 | O | _loadDeckAndCreateGame() + DeckMetadata.totalCards |
| 동적 cardCount (22→덱별) | O | cardCount 파라미터로 루프 동적화 |
| Modified 파일 3개 | O | 정확히 3개 일치 |

### Verify 리포트

Verify result: VERIFIED (5/5 checks passed). 별도 verify 문서 미생성.

- V3 (pass rate): 100%
- V4 (critical issues): 0건
- V5 (skip count): 0건

### Implementation 결과

**I1 — Scope 외 변경 파일**: 0개 (Modified 3개 모두 Scope 영역 1 파일 목록 내)

**I2 — Unresolved items**: 0개

### Git diff 분석 (35d4ae9..53d1f7a)

| 파일 | Plan 예측 | 실제 | 차이 |
|---|---|---|---|
| tarot_game.dart | Modified | Modified | gravity 9.8→0, SensorGravityController/HandAnimationComponent import 제거, backgroundColor 추가, 산란 로직 전면 교체 |
| card_body_component.dart | Modified | Modified | Plan과 일치 — SpriteComponent child, 코드 드로잉 제거, deckId 파라미터 |
| shuffle_page.dart | Modified | Modified | Plan 범위 초과 — entropy/sensor UI, ShufflePhase 상태머신, 스프레드 선택 전체 제거 + 인터랙티브 카메라 제어 추가 |

**Scope drift 가중 계산**:

| 변경 | 가중치 | 설명 |
|---|---|---|
| gravity 0 + 산란 로직 | x1 (같은 모듈) | 셔플 연출 방식 변경 — 카드 이미지 적용과 연관된 리팩토링 |
| SensorGravityController 제거 | x1 | import만 제거, 소스 파일 유지 |
| HandAnimationComponent 제거 | x1 | import만 제거, 소스 파일 유지 |
| ShufflePage entropy/sensor UI 제거 | x1 | 같은 모듈 내 UI 정리 |
| 인터랙티브 카메라 제어 추가 | x1 | 같은 파일 내 새 기능 |
| 물리 파라미터 변경 (damping, friction, restitution) | x1 | 같은 모듈 |
| backgroundColor 추가 | x1 | 같은 파일 |

**총 scope drift 가중 합계: 7** (모두 같은 모듈 x1)

### 상위 Initiative 정렬

- S1: Brief intent 대비 커버리지 — Cycle 1 영역(Flame 뒷면 + 동적 카드 수) **100%** 달성
- S2: 미구현 영역 — Cycle 2(결과 화면 앞면 이미지 + 덱 선택 비주얼) 잔여
- S3: N/A (데이터 전환 과제 아님)

## 2. Critical Gate

**PASS** — V4 critical issues 0건.

## 3. Scoring

| 차원 | 원시값 | 점수 | 근거 |
|---|---|---|---|
| **V-score** | 100% (5/5 pass) | 3 | 전체 통과 |
| **U-score** | 0개 unresolved | 3 | Plan 체크리스트 항목 전부 완료 |
| **D-score** | 가중 7 (같은 모듈 내) | 2 | 4-10 구간 — Scope 외 변경이 있으나 모두 동일 모듈 |
| **T-score** | verify-trace 미실행 | 1 | verify 문서 미생성 (구두 VERIFIED만), 기본값 2가 아닌 1 부여 — trace 부재 |

**Depth Score = 3 + 3 + 2 + 1 = 9**

## 4. 문서 미기재 발견사항

### 신규 발견

- **EV-005-D1**: **셔플 연출 패러다임 전환** — 중력 기반 낙하(gravity 9.8 + SensorGravityController)에서 무중력 방사형 산란(gravity 0 + initialVelocity)으로 전환되었다. 이는 Plan에 명시되지 않았으나, card_back.webp 이미지를 보여주는 산란 연출과 일관된 방향이다. SensorGravityController 소스 파일(`sensor_gravity_controller.dart`)과 HandAnimationComponent 소스 파일(`hand_animation_component.dart`)은 삭제되지 않고 유지되어 있어, 향후 다른 셔플 모드에서 복원 가능하다.

- **EV-005-D2**: **인터랙티브 카메라 제어 추가** — ShufflePage에 3D Transform 기반 카메라 제어(1핑거 회전, 2핑거 줌, 더블탭 리셋)와 좌표 디버그 오버레이가 추가되었다. Plan에 없는 기능이나, 카드 이미지가 실제로 렌더링되는 것을 확인하기 위한 개발 도구로서 합리적이다.

### 문서 간 불일치

- **EV-005-C1**: **Plan vs 구현 — ShufflePage 범위** — Plan Step 3은 "TarotGame에 deckId + cardCount 전달"만 명시했으나, 실제 구현은 ShufflePage를 전면 재작성했다. entropy/sensor UI, ShufflePhase 상태머신, _startShuffle() 로직, 스프레드 타입 선택기가 모두 제거되었다. 이 변경은 Plan의 "3-A, 3-B, 3-C" 세부 사항보다 광범위하다.

- **EV-005-C2**: **Scope "Reviewed" 파일 vs 실제** — Scope는 `tarot_coordinate_utils.dart`와 `deck_metadata.dart`를 "Reviewed (check-only)"로 지정했으나, 이들이 실제로 검토되었는지 verify 문서에 기록 없음.

### 암묵적 가정

- **EV-005-A1**: **entropy/sensor 기능 불필요 가정** — ShufflePage에서 entropy pool과 sensor data collection을 제거한 것은, 현재 셔플 연출이 물리적 흔들기 기반이 아닌 자동 산란 방식이므로 불필요하다는 암묵적 판단이다. 이 기능들의 provider(`shuffleProviders`)와 데이터소스(`entropy_pool.dart`, `sensor_data_collector.dart`)는 여전히 존재하며, `shuffle_deck_usecase.dart`에서도 참조된다. dead import/unused provider 경고가 발생할 수 있다.

- **EV-005-A2**: **물리 파라미터 변경 정당성** — linearDamping 2.0→3.5, angularDamping 1.2→2.0, friction 0.4→0.5, restitution 0.05→0.02 변경은 새로운 산란 연출에 맞춘 것으로 보이나, 근거 문서가 없다. Research R-003-F6이 "카드 수 증가 시 물리 조정 필요 가능"을 언급했고, Plan은 "이번 구현에서는 물리 파라미터를 변경하지 않는다"고 명시했다. 구현이 Plan을 초과하여 파라미터를 변경했다.

### 부수 효과

- **EV-005-S1**: **_goToReading()에서 shuffleState 미설정** — 이전 코드에서 `_startShuffle()`이 `ref.read(shuffleStateProvider.notifier).setResult(result)`로 셔플 결과를 설정한 후 drawing 페이즈로 전환했다. 현재 코드는 셔플 결과 설정 없이 바로 reading 화면으로 이동한다. reading 화면이 shuffleState에 의존하는 경우 런타임 에러가 발생할 수 있다.

- **EV-005-S2**: **HandAnimationComponent 고아화** — `hand_animation_component.dart`가 존재하지만 어디에서도 import/사용되지 않는다 (TarotGame에서 제거됨). 향후 정리 대상.

## 5. Verdict 도출

### Scoring 분석

Depth Score **9** (V:3 U:3 D:2 T:1) — 7-9 구간.

0점 차원 존재 여부: **없음** (최저 T-score 1).

Protocol: 7-9 + 0점 차원 없음 → **proceed**.

### 대안 검토

**adjust를 고려한 이유**: ShufflePage의 entropy/sensor UI 제거가 Plan 범위를 상당히 초과하며(D-score 가중 7), 특히 EV-005-S1(shuffleState 미설정)이 reading 화면에 영향을 줄 가능성이 있다.

**proceed를 선택한 이유**:
1. 핵심 목표(card_back.webp Sprite + 동적 카드 수)가 100% 달성되었다
2. 제거된 코드의 원본 파일(entropy_pool, sensor_data_collector, providers)이 모두 유지되어 복원 가능하다
3. EV-005-S1의 reading 화면 영향은 Cycle 2에서 결과 화면을 구현할 때 자연스럽게 다뤄진다 — 현재 reading 화면도 아직 이미지 미적용 상태이므로 기존 동작이 변경되지 않을 가능성이 높다
4. 셔플 연출 패러다임 전환(gravity→scatter)은 카드 이미지를 실제로 보여주는 산란 연출에 적합한 방향이다

### 종료 판단

**terminate: false** — Cycle 2(결과 화면 앞면 이미지 + 덱 선택 비주얼) 잔여. intent 대비 달성률 약 50% (Cycle 1/2).

## 6. 권고사항

### Verdict: PROCEED

### 체크리스트 변경 권고

없음 — Cycle 2를 예정대로 진행.

### 다음 사이클 전달사항

- **EV-005-S1 확인 필수**: Cycle 2 Plan 작성 시, reading 화면이 `shuffleStateProvider`에 의존하는지 확인하고, 의존하면 ShufflePage→reading 전환 시 셔플 결과를 설정하는 로직을 복원 또는 대체 방안 마련. `Addresses: EV-005-S1`
- **EV-005-A1 dead code 정리 고려**: entropy_pool, sensor_data_collector, EntropyProgressIndicator 등이 더 이상 사용되지 않는다면, Cycle 2 또는 후속 정리에서 제거 검토. `Deferred: EV-005-A1 — Cycle 2 범위 외, 후속 정리 과제`
- **EV-005-D1 셔플 모드 확장 고려**: 현재 방사형 산란이 유일한 셔플 모드가 되었으므로, 향후 센서 기반 셔플을 복원할 경우 SensorGravityController와 HandAnimationComponent를 재활성화하는 경로를 기억할 것. `Deferred: EV-005-D1 — 향후 셔플 모드 확장 시 검토`
- **이미지 경로 규약 확정**: `$deckId/card_back.webp` 패턴이 Cycle 1에서 확립됨. Cycle 2 앞면 이미지는 `$deckId/$imagePath` 패턴을 따를 것.

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
