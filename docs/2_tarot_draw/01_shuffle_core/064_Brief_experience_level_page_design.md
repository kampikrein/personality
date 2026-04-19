---
id: "064"
type: brief
title: "체험 레벨별 페이지 디자인 — 4단계 UI/UX 명세"
created: 2026-04-10
status: completed
deep_critique: false
critique_docs: []
summary: >
  체험 레벨 4단계(즉시/연출/2D/2.5D) 각각의 페이지 UI/UX를 설계한다.
  Level 1/2는 기존 구현 현황을 검토하고 통일성 관점의 개선점을 식별하며,
  Level 3(2D 셔플+선택)과 Level 4(2.5D 물리+선택)는 신규 페이지를 시각·인터랙션 관점에서 완전히 설계한다.
keywords: [experience-level, page-design, ux, ui, 2d-shuffle, 2.5d-shuffle, card-selection, flutter]
---

# 체험 레벨별 페이지 디자인 — 4단계 UI/UX 명세

## Intent

타로 앱의 핵심 경험인 4단계 체험 레벨 각각에 대해 페이지 UI/UX를 구체적으로 설계한다.

기술 구현 방향은 Brief 063(셔플 단계 리빌딩)에서 확정됐다. 이 Brief는 그 위에서 **"각 레벨이 사용자에게 시각적·인터랙션 측면에서 어떤 경험을 제공해야 하는가"** 를 다룬다. 레이아웃, 컴포넌트 구성, 인터랙션 시나리오, 전환 흐름을 명세하여 구현(scope → makeplan) 단계의 설계 근거가 된다.

## Context

### 현재 구현 상태

| Level | 이름 | 파일 | 상태 |
|-------|------|------|------|
| 1 | 즉시 | `lib/features/draw/presentation/pages/instant_draw_page.dart` | ✅ 완성 |
| 2 | 연출 | `lib/features/draw/presentation/pages/animated_draw_page.dart` | ✅ 완성 |
| 3 | 2D | — (신규 필요) | ❌ 미구현 |
| 4 | 2.5D | `lib/features/shuffle/presentation/pages/shuffle_page.dart` | ⚠️ 물리 연결 미완성 |

### 각 레벨의 현재 흐름 (Brief 063 MA-2 기준)

- **Level 1**: Home → InstantDrawPage (셔플 불가시, 카드 앞면 즉시 표시 + SpreadLayout)
- **Level 2**: Home → AnimatedDrawPage (슬라이드+페이드 연출 → SpreadLayout)
- **Level 3**: Home → IntentionPage → **Shuffle2dPage** (2D 셔플+카드 선택 통합) → ReadingPage
- **Level 4**: Home → IntentionPage → **ShufflePage** (Forge2D 물리) → **CardSelectionPage** → ReadingPage

### 기존 코드 자산

- `instant_draw_page.dart`: ShuffleResult 즉시 생성, SpreadLayout 위젯으로 카드 표시
- `animated_draw_page.dart`: AnimationController 기반, 카드 슬라이드+페이드 인 연출
- `shuffle_page.dart`: GameWidget(Forge2D), Matrix4 Transform, GameWidget 충돌 햅틱
- `intention_page.dart`: Level 3/4 진입 전 질문/의도 입력 화면
- `card_painter.dart` (미사용): 2D 카드 CustomPainter — Level 3 구현 참조용

### 앱 스타일 현황

기존 앱은 dark 테마 기반 (배경: 어두운 보라/남색 계열). 카드는 사각형 이미지. SpreadLayout이 위치별 카드를 배치.

---

## Boundaries

### In Scope

| # | Item | Description |
|---|------|-------------|
| 1 | Level 3 — Shuffle2dPage 전체 설계 | 2D 셔플 연출 + 부채꼴 카드 펼침 + 터치 선택 — 레이아웃, 인터랙션, 상태 전환 전부 |
| 2 | Level 4 — ShufflePage 시각 설계 | 기존 Forge2D 화면의 UI 요소 배치 (진입 연출, 완료 버튼, 센서 활성 표시) |
| 3 | Level 4 — CardSelectionPage 신규 설계 | 2.5D → 2D 전환 후 부채꼴 선택 화면 (Level 3와 유사하나 별도 화면) |
| 4 | Level 1/2 UI 일관성 검토 | 기존 페이지가 전체 스타일 가이드와 정합하는지 검토, 개선점 식별 |
| 5 | 레벨 간 전환 UX | 각 레벨 진입/이탈 애니메이션 및 라우팅 흐름 명세 |
| 6 | 빈 상태·오류 상태 처리 | 카드 로딩 실패, 셔플 결과 없음, 선택 완료 조건 등 엣지 케이스 UI |

### Out of Scope

| # | Item | Reason |
|---|------|--------|
| 1 | Flutter 코드 구현 | Brief 단계 — scope + makeplan이 처리 |
| 2 | Forge2D 물리 파라미터 튜닝 | 063 Brief + 기존 연구(035~042)에서 확정된 사항 |
| 3 | ReadingPage 설계 | 기존 완성 화면, 이 Brief 범위 밖 |
| 4 | IntentionPage 설계 | 기존 완성 화면, Level 3/4 공통 진입점으로 변경 없음 |
| 5 | 덱 선택 페이지 설계 | deck_selection_page 별도 주제 |
| 6 | 디자인 에셋(이미지/아이콘) 제작 | 코드 구현에서 기존 에셋 활용 |

---

## Decisions

| # | Decision | Chosen | Rationale | Trade-off | Alternatives Considered |
|---|----------|--------|-----------|-----------|------------------------|
| 1 | 설계 범위 — Level 1/2 처리 방식 | **현황 검토 + 통일성 권고안만** (재구현 없음) | Level 1/2는 완성 상태이고 사용자 요청의 핵심은 신규 Level 3/4 페이지 설계다. 기존 페이지를 이 Brief에서 재설계하면 범위가 불필요하게 확장된다. 대신 스타일 통일성(색상, 타이포, 간격) 관점에서 Level 3/4가 기존 페이지와 일관성을 유지하도록 가이드라인만 도출한다. | 기존 페이지의 UX 문제를 이 Brief에서 직접 해결하지 못함. 하지만 Level 3/4와 함께 리뷰 사이클을 별도로 계획하는 것이 더 효율적. | **전체 4레벨 재설계** — 완성된 기능을 건드리면 regression 위험. **Level 1/2 완전 무시** — 스타일 불일치가 사용자 혼란 유발 가능. |
| 2 | Level 3 페이지 구조 | **셔플 연출 + 선택을 단일 화면 상태머신으로** | Brief 063 MA-2에서 Level 3는 Shuffle2dPage 단일 화면에 셔플+선택이 통합된다고 확정됐다. 화면을 상태(SHUFFLING → SPREADING → SELECTING → DONE)로 관리하면 페이지 전환 없이 자연스러운 흐름을 만들 수 있고, Navigator stack 복잡도도 줄어든다. | 단일 화면에 여러 상태가 있어 위젯 복잡도 상승. 하지만 각 상태의 UI가 명확히 다르므로 조건부 렌더링으로 충분히 관리 가능. | **셔플/선택 별도 페이지** — Level 3의 "가볍고 빠른 경험" 컨셉과 어긋남. 페이지 전환 오버헤드가 경험을 끊음. |
| 3 | Level 4 CardSelectionPage — Level 3와 관계 | **공유 위젯 + 별도 페이지** (동일 부채꼴 선택 위젯, 다른 진입 맥락) | 두 레벨 모두 부채꼴 카드 선택 UX를 사용한다(Brief 063 D-3). 핵심 선택 로직과 UI를 `CardFanSelectorWidget` 등 공유 위젯으로 추출하면 코드 중복을 줄이고 일관성을 확보할 수 있다. 하지만 Level 4는 2.5D → 2D 전환 연출이 앞에 있으므로 별도 페이지(`card_selection_page.dart`)로 분리한다. | 공유 위젯의 인터페이스를 두 레벨 모두의 요구에 맞게 유연하게 설계해야 한다. 약간의 추상화 비용 발생. | **완전히 독립 구현(중복)** — 동일 UX를 두 번 구현하면 이후 변경 시 두 곳을 동시에 수정해야 함. **Level 4도 Level 3 페이지 재사용** — 진입 맥락(전환 연출 유무)이 다르므로 부자연스러움. |
| 4 | 부채꼴 카드 배치 접근 방식 | **단계적 표시 — 현재 중앙 영역 카드만 선명, 주변은 흐림** | 78장을 부채꼴로 완전히 펼치면 개별 카드 너비가 약 5-8px 수준으로 터치 불가. 스와이프로 아크를 회전시키되, 화면 중앙 가시 영역의 카드(7-11장)만 또렷하게 보이고 양 옆은 점점 흐려지는 방식이 터치 정확도와 미학적 완성도를 동시에 해결한다. "선택 중인 카드"는 살짝 위로 올라와 강조된다. | 78장을 한눈에 볼 수 없어 "내가 모든 카드를 보고 골랐다"는 느낌이 약해질 수 있음. 하지만 타로는 원래 뒷면 상태에서 고르므로 특정 카드를 보고 고르는 게 아님 — 이 약점은 실제로 문제가 아님. | **그리드 선택** — 모든 카드를 동시에 볼 수 있으나 타로 의식과 전혀 다른 UX. **페이지네이션 방식** — 여러 단계로 나눠 선택하면 선택 과정이 끊어짐. |
| 5 | 디자인 스타일 방향 | **기존 다크 미스티컬 계승 + 레벨별 강도 차별화** | 앱이 이미 다크 테마 기반으로 구현되어 있다. 이 스타일을 유지하되, Level에 따라 시각적 강도를 달리한다. Level 1(최소), Level 2(슬라이드+페이드), Level 3(2D 파티클+카드 펼침), Level 4(물리 시뮬레이션+글로우 효과). 레벨이 높을수록 "의식(ritual)"에 가까운 시각 언어 사용. | 레벨별 차별화에 추가 디자인 작업 필요. 하지만 사용자가 레벨을 올릴 때마다 더 몰입감 있는 경험을 기대하므로 차별화가 필수. | **레벨 무관 동일 스타일** — 레벨 선택의 의미가 희석됨. **레벨마다 완전히 다른 테마** — 앱 일관성 훼손. |
| 6 | Level 4 물리 셔플 화면의 UI 요소 | **최소 UI (진행 힌트 + 완료 버튼)** | Forge2D 물리 시뮬레이션 화면은 카드가 전체 화면을 채우는 게 몰입감의 핵심. UI 요소를 최소화하고 (1) 상단 반투명 힌트 텍스트 "기울이거나 터치해서 섞어보세요", (2) 하단 "카드 고르기" 버튼(반투명 오버레이)만 노출한다. 버튼은 일정 시간 셔플 후 나타나거나 사용자 제스처 감지 후 활성화. | 버튼이 작거나 반투명이면 사용자가 발견하기 어려울 수 있음 → 첫 진입 시 펄스 애니메이션으로 주의 유도. | **고정 상단/하단 바** — 카드 영역을 침범하여 몰입감 저하. **버튼 없음(자동 전환)** — 셔플 완료를 앱이 판단하면 사용자 주체성 훼손. |

## Open Questions

| # | Question | Impact | Status |
|---|----------|--------|--------|
| — | — | — | 전부 Decisions에서 해소 |

---

## Constraints

1. **Brief 063 Model Anchors 계승**: MA-2(라우팅), MA-3(터치→힘), MA-5(부채꼴 아크), MA-6(전환 연출) 설계 결정을 이 Brief의 페이지 명세가 따른다.
2. **기존 Flutter 위젯 재사용**: SpreadLayout, ShuffleProviders, SettingsProviders 등 기존 자산을 활용.
3. **다크 테마 기준**: 앱 전체가 dark 테마. 페이지 배경은 기존 테마 색상 계승.
4. **78장 성능**: 부채꼴 선택 위젯은 78장 전체 렌더링을 60fps로 처리해야 함 (CustomPainter 기반).
5. **Riverpod 상태 관리**: 페이지 간 상태는 기존 shuffle_providers를 확장. 새 로컬 UI 상태만 StatefulWidget 내부.

---

## Page Specifications

### Level 1 — InstantDrawPage (현황 검토)

**현재 구조**: 페이지 진입 → ShuffleUseCase 즉시 실행 → SpreadLayout 표시. 카드 탭하면 앞면 공개.

**통일성 관점 개선 권고** (재구현 아님):
- 진입 시 로딩 인디케이터가 있다면 다크 테마 스피너로 통일
- SpreadLayout 주변 여백이 Level 2와 동일한 수직 패딩 기준을 따를 것

---

### Level 2 — AnimatedDrawPage (현황 검토)

**현재 구조**: 카드 슬라이드 진입 + 페이드 인 연출 → SpreadLayout.

**통일성 관점 개선 권고**:
- 애니메이션 Duration이 Level 3/4 전환 속도와 일관성 있는지 검토 필요
- 배경 파티클/글로우 없음 — Level 3/4 대비 시각적 차이가 충분한지 확인 필요

---

### Level 3 — Shuffle2dPage (신규 설계)

**파일 경로**: `lib/features/shuffle/presentation/pages/shuffle_2d_page.dart`

#### 상태 머신

```
INIT → SHUFFLING → SPREADING → SELECTING → DONE
```

| 상태 | 화면 내용 |
|------|----------|
| INIT | 카드 덱 이미지(뒷면 쌓인 더미), "섞기 시작" 버튼 |
| SHUFFLING | 카드들이 2D 공간에서 흩어지고 다시 모이는 연출 (리플/산란 애니메이션, shuffleCount 반복) |
| SPREADING | 카드 덱이 부채꼴 아크로 펼쳐지는 애니메이션 (0.8~1.2초) |
| SELECTING | 부채꼴 카드 배열, 스와이프로 아크 회전, 탭으로 선택, 선택된 카드 상단 트레이 표시 |
| DONE | 선택 완료 → ReadingPage로 push |

#### 레이아웃 (SELECTING 상태 기준)

```
┌─────────────────────────────┐
│  [선택된 카드 트레이 - 상단] │  ← 선택 카드 뒷면 → 앞면 공개 예정 표시
│                             │
│                             │
│   [부채꼴 카드 아크 영역]    │  ← 화면 하단 2/3 차지
│   ━━━━━━━━━━━━━━━━━━━━━━━  │  ← 카드 손잡이 부분만 보임
│                             │
│  [좌 스와이프 힌트] [N/M 선택됨] [우 스와이프 힌트]  │
│  [리딩 시작 버튼 - 비활성/활성]  │
└─────────────────────────────┘
```

#### 인터랙션 상세

- **아크 회전**: 수평 스와이프 → 아크 전체가 좌/우로 회전. 속도 기반 관성(spring) 적용.
- **카드 선택**: 탭 → 선택된 카드가 상단 트레이로 이동하는 슬라이드 애니메이션. 이미 선택된 경우 탭하면 선택 취소.
- **중앙 강조**: 화면 중앙에 가까운 카드일수록 opacity 1.0, 크기 살짝 큼. 양 옆으로 갈수록 opacity 0.4로 점감.
- **선택 완료**: `SpreadType.cardCount`장 선택 시 "리딩 시작" 버튼 활성화 + 진동 햅틱.

#### 시각 스타일

- 배경: 앱 기본 다크 배경 + 미세한 별/파티클 레이어 (낮은 opacity)
- 카드 아크: 카드 뒷면 이미지, 선택된 카드는 골드 테두리 글로우
- SHUFFLING 상태: 카드들이 흩어지는 동안 배경 빛 파동 효과

---

### Level 4 — ShufflePage 고도화 (시각 명세)

**파일 경로**: `lib/features/shuffle/presentation/pages/shuffle_page.dart` (기존 확장)

#### 레이아웃

```
┌─────────────────────────────┐
│  [반투명 힌트: "기울이거나 터치해서 섞어보세요"]  │  ← 희미하게, 진입 후 5초 후 사라짐
│                             │
│                             │
│   [Forge2D GameWidget        │  ← 전체 화면 물리 시뮬레이션
│    — 물리 카드 산개]          │
│                             │
│                             │
│  [반투명 "카드 고르기" 버튼]  │  ← 하단 안전 영역 위, 셔플 감지 후 펄스 등장
└─────────────────────────────┘
```

#### 진입 연출

- IntentionPage에서 전환 시: 어두운 화면에서 fade-in, 카드들이 중앙에서 바깥으로 폭발적으로 산개
- 센서 활성 표시: 상단에 아주 작은 아이콘(기울기 심볼) — 활성이면 dim, 비활성이면 사라짐

#### "카드 고르기" 버튼 등장 조건

셔플 감지: 사용자가 터치 또는 기울기 입력을 3초 이상 한 경우 → 버튼 펄스 등장. 버튼 탭 → CardSelectionPage로 push.

---

### Level 4 — CardSelectionPage (신규 설계)

**파일 경로**: `lib/features/shuffle/presentation/pages/card_selection_page.dart`

#### 진입 연출 (Brief 063 MA-6 기준)

1. ShufflePage에서 "카드 고르기" 탭
2. Forge2D 카드들이 중앙으로 수렴 (0.6초)
3. GameWidget 페이드 아웃, CardSelectionPage 페이드 인
4. 수렴된 덱이 부채꼴로 펼쳐짐 (0.8초)
5. SELECTING 상태 활성

#### 레이아웃 및 인터랙션

Level 3의 SELECTING 상태와 동일한 `CardFanSelectorWidget` 재사용.
**차이점**: 상단 힌트 텍스트가 "물리적으로 섞인 카드에서 고르세요" 등 Level 4 맥락에 맞는 문구.

---

## Exit Criteria

- [x] 4개 레벨 각각의 페이지 구조와 상태 흐름 확정
- [x] Level 3 Shuffle2dPage 상태 머신 정의 완료
- [x] 부채꼴 카드 선택 UX 상세 명세 완료
- [x] Level 4 ShufflePage UI 요소 명세 완료
- [x] Level 4 CardSelectionPage 진입 연출 흐름 확정
- [x] 공유 위젯(CardFanSelectorWidget) 추출 전략 확정

---

## Model Anchors

### MA-1: Level 1/2 — 코드 수정 없음
이 Brief를 구현하는 과정에서 Level 1/2(`instant_draw_page.dart`, `animated_draw_page.dart`)는 수정하지 않는다. 스타일 통일성 이슈가 발견되면 별도 이슈로 등록한다.

### MA-2: Level 3 — Shuffle2dPage 상태 머신
`Shuffle2dPage`는 단일 StatefulWidget으로 `_Shuffle2dState { init, shuffling, spreading, selecting, done }` 열거형으로 상태를 관리한다. 각 상태 전환은 `setState`로 처리. 상태마다 다른 child 위젯을 Stack으로 교체. AnimatedSwitcher로 상태 전환 페이드.

### MA-3: CardFanSelectorWidget — 공유 위젯
`lib/features/shuffle/presentation/widgets/card_fan_selector_widget.dart`를 신규 생성. Level 3(Shuffle2dPage 내부)와 Level 4(CardSelectionPage)가 모두 이 위젯을 사용. 입력: `List<TarotCard>`, `int requiredCount`, `ValueChanged<List<TarotCard>> onSelectionComplete`. 구현: CustomPainter 기반 아크 렌더링.

### MA-4: 부채꼴 아크 — CustomPainter
78장 카드를 반원형 아크에 배치. 카드 중심 간격 = π / 78 라디안 (균등 배분). 화면 중앙 ±30도 범위 내 카드만 opacity 1.0, 그 외는 opacity 선형 감소 (최소 0.35). 스와이프 gestureDetector로 아크 회전 각도(offsetAngle) 업데이트 → repaint. 선택된 카드는 화면 상단 트레이(SelectedCardTray) 위젯으로 이동 애니메이션.

### MA-5: Level 4 ShufflePage 버튼 등장
`_interactionDetected` 플래그를 TarotGame 또는 GestureDetector에서 감지. 3초 이상 입력 시 `setState(() => _showSelectButton = true)`. 버튼은 AnimatedOpacity로 등장. 버튼 탭 시 수렴 애니메이션 시작 → `context.push('/card-selection')`.

### MA-6: 전환 연출 — 카드 수렴
Level 4 전용. TarotWorld에 `convergenceMode` 플래그 추가 → 모든 카드 body에 중앙 attractor force 적용 (Linear impulse toward world center). 수렴 완료(속도 임계값 이하) 감지 후 onConverged 콜백 → 화면 전환.

### MA-7: 힌트 텍스트 자동 소거
ShufflePage 진입 시 힌트 텍스트("기울이거나 터치해서 섞어보세요")는 `Timer(Duration(seconds: 5))` 또는 첫 입력 감지 시 `AnimatedOpacity`로 페이드 아웃. 재진입 시 다시 표시.

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 14s | 71894 |
| 2 | user-ai-exchange | 8s | 50236 |
| 3 | user-ai-exchange | 25s | 109611 |
| 4 | user-ai-exchange | 229s | 504450 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 671s |
| Total Tokens | 736191 |
| Input Tokens | 27 |
| Output Tokens | 15808 |
| Cache Read | 654431 |
| Cache Creation | 65925 |
