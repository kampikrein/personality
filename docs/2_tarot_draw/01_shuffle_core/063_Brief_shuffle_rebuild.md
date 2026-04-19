---
id: "063"
type: brief
title: "셔플 단계 리빌딩 — 2.5D 물리 고도화 + 2D 카드 선택 모드"
created: 2026-04-07
status: completed
deep_critique: false
critique_docs: []
summary: >
  체험 레벨을 4단계(즉시/연출/2D/2.5D)로 확장하고, Level 3(2D)과 Level 4(2.5D) 각각에
  셔플 + 카드 선택 기능을 구현한다. 2.5D는 기존 Forge2D 물리 엔진을 완성하고,
  2D는 부채꼴 카드 펼침/선택 인터랙션을 신규 구현한다.
keywords: [shuffle, rebuild, physics, 2.5d, 2d, card-selection, forge2d, sensor, hand-animation]
---

# 셔플 단계 리빌딩 — 2.5D 물리 고도화 + 2D 카드 선택 모드

## Intent

체험 레벨을 기존 3단계(즉시/연출/풀셔플)에서 **4단계(즉시/연출/2D/2.5D)**로 확장한다.

기존 "풀셔플"은 Forge2D 물리 엔진으로 카드가 산개되는 시각 연출만 있었고, 센서 중력·핸드 인터랙션은 미연결, 카드 직접 선택은 불가했다. 이를 두 개의 독립 모드로 분리·고도화한다:

- **Level 3 — 2D 셔플**: 카드가 화면에서 2D로 섞이고, 부채꼴/아크로 펼쳐져 사용자가 직접 한 장씩 터치 선택. 물리 시뮬레이션 없이 가볍고 직관적인 경험.
- **Level 4 — 2.5D 셔플**: 기존 Forge2D 물리 엔진을 완성(센서 중력, 터치→힘, 충돌 햅틱)하고, 셔플 후 카드를 직접 선택하는 단계까지 포함. 몰입형 의식 경험.

두 모드 모두 **"내가 이 카드를 골랐다"는 주체성 경험**을 핵심으로 한다. 셔플(섞기) + 선택(고르기)의 이중 구조.

## Context

### 현재 파일 구조 (shuffle feature)
- `lib/features/shuffle/presentation/pages/shuffle_page.dart` — 2.5D 셔플 화면 (GameWidget + Matrix4 Transform)
- `lib/features/shuffle/presentation/game/tarot_game.dart` — Forge2D 게임 루프 (45Hz 고정 타임스텝)
- `lib/features/shuffle/presentation/game/card_body_component.dart` — 물리 카드 바디 (Dynamic, 충돌 햅틱)
- `lib/features/shuffle/presentation/game/sensor_gravity_controller.dart` — 가속도계→중력 (구현됨, **미연결**)
- `lib/features/shuffle/presentation/game/hand_animation_component.dart` — Rive 핸드 + KinematicBody (구현됨, **미연결**, .riv 미보유)
- `lib/features/shuffle/presentation/widgets/riffle_animation_controller.dart` — 레거시 2D 리플 애니메이션 (**미사용**)
- `lib/features/shuffle/presentation/widgets/card_painter.dart` — 2D CustomPainter (**미사용**)
- `lib/features/shuffle/presentation/providers/shuffle_providers.dart` — Riverpod 상태 관리
- `lib/features/shuffle/domain/` — ShuffleConfig, ShuffleResult, strategies, usecases
- `lib/features/shuffle/data/` — EntropyPool, SensorDataCollector, HapticService

### 체험 레벨 구조 (변경 후)
| Level | 이름 | 흐름 |
|-------|------|------|
| 1 | 즉시 | Home → InstantDrawPage (셔플 불가시, 카드 앞면 즉시 표시) |
| 2 | 연출 | Home → AnimatedDrawPage (셔플 불가시, 슬라이드+페이드 연출) |
| 3 | 2D | Home → IntentionPage → **2D 셔플 + 카드 선택** → ReadingPage |
| 4 | 2.5D | Home → IntentionPage → **2.5D 물리 셔플 + 카드 선택** → ReadingPage |

### 이전 흐름 (Experience Level 3 = 풀셔플)
IntentionPage → ShufflePage(2.5D 산개만) → "뽑기" 클릭 → 알고리즘 셔플 → ReadingPage

### 기존 연구 (03_tarot_shuffle 토픽 내 주요 참조)
- 035~042: 촉감 엔진 리서치 (물리 파라미터, Forge2D+Rive 레이턴시, 가속도계 응답)
- 043~046: 셔플 엔진 구현 Scope/Plan (Cycle 1~3)
- 047~056: RNG 최적화 리서치 및 구현

## Boundaries

### In Scope
| # | Item | Description |
|---|------|-------------|
| 1 | 체험 레벨 4단계 확장 | 설정/홈 메뉴를 즉시/연출/2D/2.5D 4단계로 변경, DB 마이그레이션 (✅ 완료) |
| 2 | Level 4: 2.5D 물리 엔진 완성 | SensorGravityController 연결, 물리 파라미터 튜닝, 카드 산개→정착 동역학 개선 |
| 3 | Level 4: 터치→힘 인터랙션 | Rive .riv 없이 사용자 터치로 물리적 힘 적용 (핸드 애니메이션 대안) |
| 4 | Level 3: 2D 셔플 화면 신설 | 카드가 2D로 섞이는 시각 연출 + 부채꼴/아크 펼침 + 터치 선택 |
| 5 | Level 3+4: 카드 선택 기능 | 두 모드 모두에서 사용자가 직접 카드를 한 장씩 터치 선택 |
| 6 | 선택 카드 상태 연결 | 사용자가 선택한 카드를 ReadingPage로 전달하는 상태 관리 |
| 7 | 셔플 횟수/반복 연출 | ShuffleConfig의 shuffleCount를 활용한 반복 셔플 연출 |
| 8 | 라우팅 분기 | Level 3과 4가 IntentionPage 이후 각각 다른 셔플 페이지로 분기 |

### Out of Scope
| # | Item | Reason |
|---|------|--------|
| 1 | Rive .riv 에셋 제작 | 디자인 에셋 제작은 별도 작업. 코드는 .riv 없이 동작하도록 설계 |
| 2 | Level 1/2 변경 | 즉시/연출 흐름은 이미 완성 |
| 3 | 카드 앞면 이미지 렌더링 개선 | 카드 이미지 파이프라인(08_card_image_pipeline)은 별도 토픽 |
| 4 | AI 해석 연동 | 12_ai_tarot_chat 토픽 영역 |
| 5 | 사운드/배경음악 | 오디오 레이어는 별도 기획 필요 |
| 6 | ReadingPage 자체 개선 | 카드 리딩 화면은 현행 유지, 입력 인터페이스만 변경 |

## Decisions

| # | Decision | Chosen | Rationale | Trade-off | Alternatives Considered |
|---|----------|--------|-----------|-----------|------------------------|
| 1 | 아키텍처 접근 | **점진적 리빌딩** (Forge2D 유지 + 2D 레이어 추가) | 현재 Forge2D 엔진(TarotGame, CardBodyComponent)은 45Hz 물리, 충돌 햅틱, 좌표 유틸리티 등 상당한 기반이 구축되어 있다. SensorGravityController/HandAnimationComponent도 구현 완료 상태로 연결만 필요. 전면 재작성은 이 투자를 버리는 것. | Forge2D의 제약(2D 물리만 가능) 내에서 작업해야 하므로 3D 물리 효과(카드 공중 회전 등)는 시뮬레이션으로 대체 필요 | **전면 재작성**(새 엔진 도입) — Forge2D + Flame 생태계 학습 투자와 기존 코드 폐기 비용이 큼. **Unity/Unreal 임베딩** — 번들 크기, 빌드 복잡도, 플랫폼 종속성 과다 |
| 2 | 2.5D↔2D 모드 관계 | **순차 흐름** (2.5D 셔플 → 전환 애니메이션 → 2D 선택) | 타로 의식의 자연스러운 순서: 섞는 행위(셔플) → 고르는 행위(선택)를 분리하면 각 단계의 몰입감을 극대화할 수 있다. 사용자는 "충분히 섞었다"고 느낄 때 다음 단계로 진행하며, 이 전환 자체가 의식적 경험의 일부가 된다. | 두 번의 화면 전환이 필요하여 빠른 진행을 원하는 사용자에게는 길게 느껴질 수 있음. 하지만 이는 Level 3(의식형)의 의도와 부합. | **탭/토글 전환** — 셔플과 선택이 동일 화면에서 전환. 기술적으로 가능하나 각 모드의 화면 공간과 인터랙션이 충돌(2.5D는 틸트/핀치, 2D는 카드 터치). **셔플 없이 바로 선택** — 의식의 "섞기" 단계를 생략하면 타로 경험의 본질적 요소 훼손 |
| 3 | 2D 카드 선택 UX | **부채꼴 아크 펼침 + 터치 선택** | 타로 리딩에서 가장 보편적이고 직관적인 물리적 경험을 재현한다. 카드가 반원형으로 펼쳐지며 뒷면이 보이는 상태에서 사용자가 "끌리는" 카드를 터치하면 선택 영역으로 이동한다. CustomPainter 기반으로 구현하면 Forge2D 없이도 60fps 유지 가능. | 78장 전체를 부채꼴로 펼치면 카드 간격이 매우 좁아 터치 정확도가 떨어질 수 있음 → 스와이프로 아크를 회전시켜 현재 보이는 영역의 카드만 선택 가능하게 해결 | **그리드 배치** — 직관적이지만 타로 느낌이 없고 "목록에서 고르기" 느낌. **산개 배치**(Forge2D 연장) — 물리 시뮬레이션 위에서 선택하면 카드가 움직여서 정확한 터치가 어려움. **스크롤 목록** — 모바일 친화적이지만 타로 의식과 무관한 UI |
| 4 | 핸드 애니메이션 부재 대안 | **터치 드래그 → 물리 힘 적용** (사용자 손가락 = 물리적 힘의 원천) | .riv 파일 없이 HandAnimationComponent의 KinematicBody 아이디어를 "사용자 터치"로 대체한다. 사용자가 화면을 드래그하면 터치 지점에 물리적 힘이 가해져 주변 카드가 밀려난다. 이는 "내 손으로 섞는다"는 주체성 경험을 코드 한 줄 없이 Forge2D의 기존 물리로 구현할 수 있다. | 사전 안무된 셔플 연출(깔끔한 리플 셔플 등)은 불가. 대신 "자유롭게 흐트러뜨리는" 셔플이 됨 — 타로 의식의 자유로운 셔플과 오히려 부합 | **프로그래매틱 애니메이션**(미리 짜인 셔플 모션) — 항상 동일한 연출이라 반복 시 몰입감 저하. **Lottie/SVG 애니메이션** — 물리 엔진과 동기화 불가. **터치 없이 센서만** — 기울이기만으로 셔플하면 조작 범위가 제한적 |
| 5 | 센서 중력 활성화 방식 | **기본 활성화 + 토글 제공** | SensorGravityController는 이미 구현·튜닝 완료 상태(alpha=0.20, gravityScale=3.0, Research 040/041 기반). TarotGame.onLoad에서 game.add()로 연결하면 즉시 동작한다. 센서 부재 시 graceful degradation도 구현되어 있음(gravity 9.8 고정). 기본 ON이 물리 경험의 핵심이되, 멀미/불편 사용자를 위해 설정에서 끌 수 있어야 한다. | 센서 반응이 과도하면 카드가 한쪽으로 쏠려 산개 연출이 무너질 수 있음 → 중력 영향 범위를 카드 속도 기반으로 감쇠시켜 해결 (정착된 카드는 중력 영향 약화) | **기본 비활성** — 안전하지만 대부분의 사용자가 핵심 기능을 발견하지 못할 위험. **항상 활성(토글 없음)** — 센서 없는 기기나 불편한 사용자 대응 불가 |
| 6 | 셔플→선택 전환 연출 | **카드 수렴 → 뒤집어 쌓기 → 부채꼴 펼침 애니메이션** | 2.5D 흩어진 카드들이 중앙으로 모여 한 덱으로 쌓이는 수렴 애니메이션 후, 카메라가 2D 탑뷰로 전환되며 덱이 부채꼴로 펼쳐지는 연출. 이 전환이 "셔플 완료 → 선택 시작"이라는 의식적 구분점을 만든다. | 전환 애니메이션 구현에 추가 공수 필요. 하지만 두 모드를 자연스럽게 잇는 핵심 경험 요소 | **즉시 전환**(화면 전환 없이 새 화면) — 맥락 단절감. **페이드 전환** — 무난하지만 "카드가 실제로 이동했다"는 연속성 상실 |
| 7 | 기존 레거시 코드 처리 | **riffle_animation_controller + card_painter 제거하지 않고 참조용 유지** | 2D 선택 모드의 CardPainter 구현 시 기존 card_painter.dart의 패턴을 참조할 수 있다. 리빌딩 완료 후 정리 단계에서 제거 결정. | 사용하지 않는 코드가 남아있으나, 참조 가치가 정리 비용보다 큼 | **즉시 제거** — 깔끔하지만 구현 시 참조할 2D 카드 렌더링 패턴 소실 |
| 8 | ShuffleConfig 연결 | **리빌딩 시 ShuffleConfig를 UseCase에 정식 연결** | shuffleCount, reversalProbability가 이미 엔티티로 존재하나 UseCase에서 읽지 않는 상태. 반복 셔플 연출을 위해 shuffleCount가 실제로 동작해야 한다. | 기존 하드코딩된 동작이 변경되므로 기존 테스트 업데이트 필요 | **별도 Config 체계** — 중복. 이미 있는 것을 사용하는 것이 원칙 |

## Open Questions

| # | Question | Impact | Status |
|---|----------|--------|--------|
| — | — | — | 전부 Decisions에서 해소 |

## Constraints

1. **Forge2D 유지**: 기존 물리 엔진 투자를 보존. 2.5D 모드는 Forge2D 기반 유지.
2. **2D 선택은 Forge2D 외부**: 부채꼴 카드 펼침은 CustomPainter/위젯 기반. 물리 시뮬레이션 불필요.
3. **센서 graceful degradation**: 센서 없는 기기에서도 셔플이 동작해야 함 (이미 구현됨).
4. **78장 성능**: 전체 타로 덱 78장을 2D 펼침에서 60fps 유지 필요.
5. **Riverpod 상태 관리**: 기존 provider 패턴 유지. 새 상태는 기존 shuffle_providers에 추가.
6. **Level 3/4 전용**: Level 1(즉시)/2(연출) 흐름은 변경하지 않음.
7. **Rive 에셋 미보유**: .riv 파일 없이 동작하는 설계가 필수.

## Exit Criteria

- [x] 2.5D 물리 고도화 방향 확정 (센서 연결, 터치→힘, 셔플 반복)
- [x] 2D 카드 선택 UX 방향 확정 (부채꼴 아크, 터치 선택)
- [x] 두 모드 간 전환 흐름 확정 (순차 흐름 + 수렴→펼침 연출)
- [x] 기존 코드 활용/폐기 전략 확정
- [x] 기술적 제약 식별 완료

## Model Anchors

### MA-1: 아키텍처 — 점진적 리빌딩
기존 Forge2D 기반(TarotGame, CardBodyComponent, TarotWorld)을 유지한다. 새 엔진 도입 금지. 2.5D 모드는 현재 Forge2D 코드를 확장하고, 2D 선택 모드는 별도 Flutter 위젯 레이어로 구현한다. 두 모드는 같은 ShufflePage 내에서 상태 전환되거나 별도 라우트로 분리될 수 있으나, 어느 쪽이든 카드 데이터(셔플 결과)는 단일 Riverpod provider를 통해 공유한다.

### MA-2: 체험 레벨 4단계 라우팅
Level 3(2D): IntentionPage → Shuffle2dPage(2D 셔플 연출 + 카드 선택 통합) → ReadingPage
Level 4(2.5D): IntentionPage → ShufflePage(기존 Forge2D 물리, 고도화) → CardSelectionPage(부채꼴 선택) → ReadingPage
Level 3은 셔플과 선택이 한 화면에서 이루어진다(가볍고 빠른 경험). Level 4는 물리 셔플→카드 선택을 분리하여 의식적 경험을 극대화한다. 두 모드의 최종 출력은 동일한 shuffleStateProvider를 통해 ReadingPage에 전달한다.

### MA-3: 물리 — 터치 = 힘의 원천
HandAnimationComponent의 KinematicBody 접근 대신, 사용자 터치 좌표를 Forge2D 월드 좌표로 변환하여 터치 주변 카드에 반발력(impulse)을 적용한다. 터치 드래그 시 연속적으로 힘이 가해져 카드가 밀려나는 효과. TarotCoordinateUtils의 기존 좌표 변환 유틸리티를 활용한다.

### MA-4: 센서 — 기본 ON, 설정 토글
SensorGravityController를 TarotGame.onLoad에서 조건부 add(). UserSettings에 센서 중력 활성화 플래그 추가. 기본값 true. 기존 graceful degradation 로직(센서 없으면 고정 중력) 유지.

### MA-5: 2D 선택 — 부채꼴 아크 + 스와이프 회전 + 터치 선택
78장의 카드를 반원형 아크로 배치한다. 카드 뒷면만 노출. 좌우 스와이프로 아크를 회전시켜 원하는 영역을 탐색하고, 카드를 탭하면 선택 영역(화면 상단 또는 하단)으로 이동한다. 선택된 카드 수가 SpreadType.cardCount에 도달하면 "리딩 시작" 버튼 활성화. CustomPainter 또는 Stack+Positioned 기반 구현.

### MA-6: 전환 연출 — Level 4 전용 2.5D→선택 브릿지
Level 4에서만 적용. 셔플 완료 시 카드 수렴 애니메이션(Forge2D 물리로 카드를 중앙 attractors로 당김) → GameWidget 숨기고 2D 위젯 노출(카드 위치를 Forge2D 최종 좌표에서 2D 위젯 좌표로 매핑하여 시각적 연속성 확보) → 부채꼴 펼침 애니메이션. Level 3(2D)은 한 화면에서 셔플→선택이 이루어지므로 별도 전환 불필요.

### MA-7: ShuffleConfig 정식 연결
ShuffleDeckUseCase.execute()에서 shuffleConfigNotifierProvider를 읽어 shuffleCount만큼 반복 셔플 실행. 각 라운드 사이에 카드 수렴→재산개 연출. reversalProbability도 실제 적용.

### MA-8: 레거시 코드
riffle_animation_controller.dart, card_painter.dart는 삭제하지 않는다. 구현 참조용으로 유지하되 import하지 않는다. 리빌딩 완료 후 별도 정리 커밋에서 제거 검토.

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 450s | 293581 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 450s |
| Total Tokens | 293581 |
| Input Tokens | 9 |
| Output Tokens | 8883 |
| Cache Read | 233944 |
| Cache Creation | 50745 |
