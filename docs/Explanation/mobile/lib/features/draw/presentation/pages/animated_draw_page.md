---
id: "mobile-lib-features-draw-presentation-pages-animated_draw_page"
type: explanation
target: "mobile/lib/features/draw/presentation/pages/animated_draw_page.dart"
layer: file
version: 1
created: 2026-04-16
updated: 2026-04-16
last_explained_commit: "813a1c34afc91b6289810a03b1644c8c34cce28c"
functions: []
---

# animated_draw_page.dart -- 해설

## 개요

타로 카드 뽑기의 **연출 단계(Lv2)** 를 담당하는 페이지이다. 사용자에게 질문 입력 화면을 먼저 보여준 뒤, 셔플을 실행하고 슬라이드/페이드 스태거 애니메이션으로 카드를 순차 공개한다. Cycle 2 리팩터링을 거쳐 결과 렌더링과 저장 책임은 `DrawResultPage`로 분리되었으며, 이 페이지는 연출이 끝나면 `pushReplacementNamed('draw-result')`로 상태만 인계하고 스택에서 사라진다.

## 역할 (Role)

- **셔플 실행**: 덱 시드 보장 -> 카드 로드 -> `ShuffleDeckUseCase.execute()` 호출로 셔플 수행
- **연출 애니메이션**: 카드별 슬라이드+페이드 스태거 애니메이션 재생
- **카드 공개 제어**: `showFaceUp` 설정에 따라 자동 전체 공개 또는 사용자 탭 공개 분기
- **상태 인계**: 셔플 결과를 `shuffleStateProvider`에 저장한 뒤 `DrawResultPage`로 전달
- **질문 수집**: 사용자가 입력한 질문을 `readingQuestionProvider`에 세팅

Cycle 2 이전에는 결과 렌더링, Reading 저장, "한 장 더" 기능까지 담당했으나, 현재는 **연출 전용** 으로 축소되었다.

## 구조 (Structure)

### 클래스 계층

| 클래스 | 역할 |
|--------|------|
| `AnimatedDrawPage` | `ConsumerStatefulWidget`. 진입점. 키만 전달. |
| `_AnimatedDrawPageState` | `ConsumerState` + `TickerProviderStateMixin`. 전체 로직 보유. |

`TickerProviderStateMixin`은 다수의 `AnimationController`에 `vsync`를 제공하기 위해 사용된다. 카드 수만큼 컨트롤러를 생성하므로 `SingleTickerProviderStateMixin`으로는 불충분하다.

### 상태 변수

| 변수 | 타입 | 역할 |
|------|------|------|
| `_shuffleResult` | `ShuffleResult?` | 셔플 결과 객체. null이면 셔플 전 또는 로딩 중. |
| `_currentCardCount` | `int` | 뽑을 카드 수. 스프레드 타입 또는 사용자 설정에서 결정. |
| `_spreadType` | `SpreadType` | 스프레드 종류 (single, threeCard, custom). |
| `_deckId` | `String` | 선택된 덱 ID. 기본값 `'rws-standard'`. |
| `_showFaceUp` | `bool` | true이면 애니메이션 후 자동 전체 공개. false이면 탭 공개. |
| `_allowReversed` | `bool` | 역방향 카드 허용 여부. `ShuffleConfig`에 전달. |
| `_showCardName` | `bool` | 카드 이름 표시 여부. |
| `_revealedPositions` | `Set<int>` | 현재까지 공개된 카드 인덱스 집합. |
| `_shuffleExecuted` | `bool` | 셔플 실행 완료 플래그. `build()`에서 질문 화면 / 애니메이션 화면 분기에 사용. |
| `_animationComplete` | `bool` | 모든 슬라이드 애니메이션 완료 플래그. |
| `_navigatedToResult` | `bool` | 결과 페이지 이동 중복 방지 가드. |
| `_slideControllers` | `List<AnimationController>` | 카드별 슬라이드 컨트롤러 목록. |
| `_slideAnimations` | `List<Animation<Offset>>` | 카드별 슬라이드 오프셋 애니메이션. |
| `_fadeAnimations` | `List<Animation<double>>` | 카드별 페이드 불투명도 애니메이션. |
| `_questionController` | `TextEditingController` | 질문 입력 필드 컨트롤러. |

### 메서드 목록

| 메서드 | 역할 |
|--------|------|
| `initState()` | `_initSettings()` 호출로 설정 초기화. |
| `_initSettings()` | `userSettingsProvider`에서 스프레드 타입, 카드 수, 덱 ID, 공개/역방향/이름 설정을 읽어 로컬 변수에 저장. |
| `_startDraw()` | 이전 상태 초기화 -> 덱 시드 -> 셔플 실행 -> 질문 세팅 -> 애니메이션 준비 및 재생. |
| `_setupAnimations()` | `_currentCardCount`만큼 `AnimationController` + slide/fade `Animation` 생성. |
| `_playAnimations()` | 스태거 패턴으로 순차 재생 -> 완료 후 `showFaceUp` 분기. |
| `_maybeGoToResult()` | 4중 가드(네비게이션 중복, 애니메이션 완료, 전체 공개, mounted)를 통과하면 `pushReplacementNamed('draw-result')` 실행. |
| `_revealCard(int)` | 개별 카드 탭 시 해당 인덱스를 `_revealedPositions`에 추가하고 `_maybeGoToResult()` 호출. |
| `dispose()` | 모든 `AnimationController`와 `_questionController` dispose. |
| `build()` | `_shuffleExecuted` 플래그로 질문 입력 화면 / 애니메이션 화면 분기. |
| `_buildAnimatedCards()` | 3열 `GridView` 안에 스태거 애니메이션 카드 배치. |
| `_animatedCard()` | `SlideTransition` + `FadeTransition`으로 개별 카드 래핑. |
| `_buildCardWidget()` | 공개/미공개 분기, 역방향 이름 표시, 탭 제스처 처리. |
| `_buildCardName()` | 카드 이름 텍스트 위젯 생성. |
| `_buildBackCard()` | 카드 뒷면 이미지 (`card_back.webp`) 또는 에러 시 fallback 컨테이너. |
| `_buildFrontCard()` | 카드 앞면 이미지. 역방향이면 `Matrix4.rotationZ(pi)` 적용. |

## 동작 흐름 (Flow)

### Phase 1: 질문 입력 (pre-shuffle)

`build()`에서 `_shuffleExecuted == false`이면 질문 입력 Scaffold를 렌더링한다.

```dart
if (!_shuffleExecuted) {
  return Scaffold(/* 질문 입력 UI */);
}
```

사용자에게 두 가지 진입점을 제공한다:
- "카드 뽑기" 버튼: 질문 텍스트를 유지한 채 `_startDraw()` 호출
- "질문 없이 바로 뽑기" 버튼: `_questionController.clear()` 후 `_startDraw()` 호출

### Phase 2: _startDraw() -- 셔플 실행

```dart
Future<void> _startDraw() async {
  // 1. 이전 뽑기 상태 초기화 (keepAlive provider 잔류 방지)
  ref.read(shuffleStateProvider.notifier).clear();
  ref.read(readingQuestionProvider.notifier).clear();

  // 2. 덱 시드 보장 (홈을 건너뛴 경우)
  await repo.seedAllDecks();

  // 3. 셔플 실행
  final result = useCase.execute(cards: cards, strategy: strategy, config: ...);
  ref.read(shuffleStateProvider.notifier).setResult(result);

  // 4. 질문 세팅
  if (question.isNotEmpty) {
    ref.read(readingQuestionProvider.notifier).set(question);
  }

  // 5. 상태 전환 -> 애니메이션 화면으로
  setState(() { _shuffleResult = result; _shuffleExecuted = true; });

  // 6. 애니메이션 준비 및 재생
  _setupAnimations();
  unawaited(_playAnimations());
}
```

`shuffleStateProvider.notifier.setResult(result)` 호출 시점에 결과가 전역 provider에 저장된다. 이후 `DrawResultPage`가 이 provider를 읽어 결과를 재사용한다.

### Phase 3: _setupAnimations() -- 애니메이션 컨트롤러 생성

카드 수(`_currentCardCount`)만큼 반복하며, 각 카드에 대해:

```dart
final controller = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 600),  // 슬라이드 1장 = 600ms
);

final slide = Tween<Offset>(begin: Offset(0, 0.5), end: Offset.zero)
    .animate(CurvedAnimation(parent: controller, curve: Curves.easeOutCubic));

final fade = Tween<double>(begin: 0.0, end: 1.0)
    .animate(CurvedAnimation(parent: controller, curve: Curves.easeIn));
```

- **Slide**: 아래에서 위로 이동 (`Offset(0, 0.5)` -> `Offset.zero`). `easeOutCubic` 커브로 도착 시 감속.
- **Fade**: 투명에서 불투명으로. `easeIn` 커브로 시작 시 느리게 나타남.

### Phase 4: _playAnimations() -- 스태거 재생

```dart
for (var i = 0; i < _currentCardCount; i++) {
  if (!mounted) return;
  unawaited(_slideControllers[i].forward());     // 즉시 시작 (await 안 함)
  await Future<void>.delayed(Duration(milliseconds: 300));  // 300ms 간격
}
// 마지막 카드 완료 대기
await _slideControllers.last.forward();
```

**타이밍 분석** (카드 3장 기준):
- t=0ms: 카드 0 시작 (600ms 동안 슬라이드)
- t=300ms: 카드 1 시작
- t=600ms: 카드 0 완료, 카드 2 시작
- t=900ms: 카드 1 완료
- t=1200ms: 카드 2 완료

일반화하면 전체 소요 시간은 `600 + 300 * (N-1)` ms이다. N=3이면 1200ms, N=1이면 600ms.

`unawaited()`로 `forward()`를 fire-and-forget 처리하여 다음 카드의 지연과 겹치게(overlap) 한다. 마지막 카드만 `await`하여 전체 완료 시점을 정확히 잡는다.

### Phase 5: 공개 분기

애니메이션 완료 후 `_showFaceUp` 설정에 따라 분기한다.

**`showFaceUp == true` (자동 공개)**:
```dart
if (_showFaceUp && mounted) {
  setState(() {
    for (var i = 0; i < _currentCardCount; i++) {
      _revealedPositions.add(i);
    }
    _animationComplete = true;
  });
  _maybeGoToResult();  // 즉시 결과 페이지로 이동
}
```

**`showFaceUp == false` (탭 공개)**:
```dart
setState(() => _animationComplete = true);
// 카드가 뒷면으로 대기. 사용자가 각 카드를 탭하면 _revealCard()가 호출됨.
```

사용자가 카드를 탭할 때마다 `_revealCard(index)` -> `_revealedPositions.add(index)` -> `_maybeGoToResult()` 순으로 호출되며, 모든 카드가 공개되면 결과 페이지로 이동한다.

### Phase 6: _maybeGoToResult() -- 결과 페이지 전환

```dart
void _maybeGoToResult() {
  if (_navigatedToResult) return;                          // 가드 1: 중복 이동 방지
  if (!_animationComplete) return;                         // 가드 2: 애니메이션 미완료
  if (_revealedPositions.length < _currentCardCount) return;  // 가드 3: 미공개 카드 존재
  if (!mounted) return;                                    // 가드 4: 위젯 해제됨

  _navigatedToResult = true;
  context.pushReplacementNamed('draw-result');
}
```

4개의 가드를 모두 통과해야 네비게이션이 발생한다. `pushReplacementNamed`는 현재 페이지를 스택에서 제거하면서 `DrawResultPage`로 교체하므로 뒤로 가기가 이 페이지로 돌아오지 않는다. `DrawResultPage`는 `shuffleStateProvider`에서 이미 저장된 결과를 읽어 재사용한다.

### Phase 7: 카드 렌더링

`_buildCardWidget()`에서 공개 상태에 따라 앞면/뒷면을 분기한다:

- **미공개**: `_buildBackCard()` -- `assets/images/{deckId}/card_back.webp` 이미지
- **공개 + 정방향**: `_buildFrontCard()` -- 카드 이미지 그대로
- **공개 + 역방향**: `_buildFrontCard()` -- `Matrix4.rotationZ(math.pi)` 로 180도 회전
- **카드 이름**: 정방향이면 카드 아래에, 역방향이면 `Matrix4.rotationZ(pi)` 적용 후 카드 위에 표시

## 의존성 (Dependencies)

| 이름 | 타입 | 역할 |
|------|------|------|
| `shuffleStateProvider` | `Riverpod NotifierProvider<ShuffleState, ShuffleResult?>` (keepAlive) | 셔플 결과 전역 저장/공유. `DrawResultPage`로의 상태 인계 매개체. |
| `readingQuestionProvider` | `Riverpod NotifierProvider<ReadingQuestion, String>` (keepAlive) | 사용자 질문 전역 저장. |
| `userSettingsProvider` | `Riverpod StreamProvider<UserSettings>` | 스프레드 타입, 카드 수, 덱 ID, showFaceUp, allowReversed, showCardName 설정 조회. |
| `deckRepositoryProvider` | `Riverpod Provider<DeckRepository>` (keepAlive) | `seedAllDecks()` 호출로 덱 시드 보장. |
| `deckCardsProvider` | `Riverpod FutureProvider<List<TarotCard>>` | 덱 ID로 카드 목록 비동기 로드. |
| `shuffleDeckUseCaseProvider` | `Riverpod Provider<ShuffleDeckUseCase>` | 셔플 로직 실행 (센서 엔트로피 + Fisher-Yates). |
| `shuffleStrategyProvider` | `Riverpod Provider<ShuffleStrategy>` | 셔플 전략 객체 (기본: `FisherYatesShuffleStrategy`). |
| `cardAspectRatioProvider` | `Riverpod Provider<double>` | 카드 종횡비. 기본값 `70.0 / 120.0`. GridView와 AspectRatio 위젯에 사용. |
| `SpreadType` | `enum` | 스프레드 종류 정의 (single, threeCard, custom). `displayName`, `cardCount` 제공. |
| `ShuffleResult` / `ShuffledCard` | `freezed` 데이터 클래스 | 셔플 결과 + 개별 카드(TarotCard + isReversed) 보유. |
| `ShuffleConfig` | `freezed` 데이터 클래스 | 셔플 설정 (역방향 허용 여부 등). |
| `go_router` | 패키지 | `context.go('/')`, `context.pushReplacementNamed('draw-result')` 라우팅. |

## 주의사항 (Caveats)

### 1. unawaited + mounted 체크

`_startDraw()`에서 `unawaited(_playAnimations())`를 사용한다. `_playAnimations()`는 내부적으로 `Future.delayed`와 `controller.forward()`를 `await`하므로 비동기 체인이 길다. 이 체인 중간에 위젯이 dispose될 수 있으므로, `_playAnimations()` 내부 루프에서 매 iteration마다 `if (!mounted) return` 가드를 건다. `_startDraw()` 본체에서도 `setState` 직전에 `if (!mounted) return`을 체크한다.

### 2. _navigatedToResult 가드

`_maybeGoToResult()`는 `showFaceUp == true`일 때 `_playAnimations()` 완료 직후 호출되고, `showFaceUp == false`일 때는 매 카드 탭마다 호출된다. 두 경로 모두 비동기 타이밍에 의해 중복 호출될 가능성이 있다. `_navigatedToResult` 불리언 가드가 `pushReplacementNamed`의 이중 실행을 방지한다. 이 가드가 없으면 GoRouter가 동일 라우트를 두 번 push하여 스택 오염이 발생할 수 있다.

### 3. AnimationController dispose

`dispose()`에서 `_slideControllers`의 모든 컨트롤러를 명시적으로 dispose한다. `_setupAnimations()`는 `_startDraw()` 성공 후에만 호출되므로, 사용자가 질문 화면에서 뒤로 가면 컨트롤러 목록이 비어 있어 dispose 루프가 아무 일도 하지 않는다. 그러나 셔플 실행 후 애니메이션 도중 홈 버튼 등으로 이탈하면, `forward()` 중인 컨트롤러가 dispose되면서 자동으로 중단된다.

### 4. pushReplacementNamed 요구사항

`context.pushReplacementNamed('draw-result')`은 현재 라우트를 스택에서 제거하고 `DrawResultPage`로 교체한다. 일반 `push`가 아닌 `pushReplacement`을 사용하는 이유:
- 연출 페이지는 일회성이므로 뒤로 가기로 돌아올 이유가 없다.
- `AnimationController`들이 이미 dispose된 상태에서 다시 이 페이지가 표시되면 크래시한다.
- `DrawResultPage`의 "다시" 버튼이 자체 재셔플을 수행하므로 이전 연출 상태가 불필요하다.

`GoRouter` 라우트 설정에서 이 페이지는 `/draw/animated` (name: `draw-animated`)로 등록되어 있고, 결과 페이지는 `/draw/result` (name: `draw-result`)로 등록되어 있다.

### 5. childAspectRatio * 0.85 매직 넘버

```dart
childAspectRatio: ref.watch(cardAspectRatioProvider) * 0.85,
```

`GridView`의 `childAspectRatio`에 `cardAspectRatioProvider` 값(기본 `70/120 = 0.583`)을 0.85로 곱한다. 결과값은 약 `0.496`이 된다. 이 보정은 카드 이미지 아래에 카드 이름 텍스트(`_buildCardName`)가 차지하는 세로 공간을 확보하기 위한 것이다. `AspectRatio` 위젯은 카드 이미지 자체에만 적용되고, `Column`으로 감싼 이름 텍스트는 별도 공간을 요구하므로 GridView 셀 전체의 종횡비를 이미지보다 세로로 더 길게(0.85배) 잡는다. 하드코딩된 매직 넘버이므로 폰트 크기나 카드 이름 길이에 따라 오버플로우가 발생할 수 있다.

## Changelog

### v1 (2026-04-16) -- 최초 작성

Cycle 2 리팩터링 완료 시점(`813a1c3`) 기준으로 작성. 결과 렌더/저장 책임이 `DrawResultPage`로 분리된 이후의 연출 전용 구조를 해설.
