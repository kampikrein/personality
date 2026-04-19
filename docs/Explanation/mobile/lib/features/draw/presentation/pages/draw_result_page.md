---
id: "mobile-lib-features-draw-presentation-pages-draw_result_page"
type: explanation
target: "mobile/lib/features/draw/presentation/pages/draw_result_page.dart"
layer: file
version: 1
created: 2026-04-16
updated: 2026-04-16
last_explained_commit: "96a0c15dc43d5af2b98e32fec1f157eeacc1e8df"
functions: []
---

# draw_result_page.dart -- 해설

## 개요

Lv1(즉시 뽑기)부터 Lv4(셔플 체험)까지 모든 경험 수준의 뽑기 결과를 하나의 페이지에서 처리하는 통합 결과 페이지이다. 업스트림(AnimatedDrawPage, ShufflePage)이 셔플 결과를 `shuffleStateProvider`에 세팅한 채 라우팅하면 해당 결과를 재사용하고, 직접 진입하면 자체 셔플을 수행한다. 카드 결과 표시, 자동 저장, 추가 뽑기(+1), 재셔플(다시) 기능을 단일 위젯에서 제공한다.

## 역할 (Role)

DrawResultPage는 뽑기 플로우의 최종 목적지로서, 진입 경로와 무관하게 동일한 결과 UI를 렌더링한다.

- **Lv1 직접 진입**: 홈에서 `/draw/result`로 직접 네비게이션. 이 페이지가 스스로 덱 시드, 셔플, 상태 세팅을 모두 수행한다.
- **Lv2/Lv4 업스트림 위임**: AnimatedDrawPage 또는 ShufflePage가 셔플을 완료한 뒤 `shuffleStateProvider`에 결과를 세팅하고 `pushReplacement`로 이 페이지에 도착한다. 이 경우 재셔플 없이 기존 결과를 그대로 소비한다.

양쪽 경로 모두 도착 후에는 동일한 카드 레이아웃, 자동 저장, 추가 뽑기, 재셔플 UI를 공유한다. 이를 통해 이전에 InstantDrawPage, AnimatedDrawPage, ReadingPage에 분산되어 있던 결과 표시/저장 책임이 이 단일 페이지로 통합되었다(MA-1).

## 구조 (Structure)

### 클래스 계층

- **`DrawResultPage`** (`ConsumerStatefulWidget`): 상태 없는 외부 껍데기. `const` 생성자만 보유.
- **`_DrawResultPageState`** (`ConsumerState<DrawResultPage>`): 모든 상태와 로직을 담당.

### 상태 변수

| 변수 | 타입 | 역할 |
|------|------|------|
| `_shuffleResult` | `ShuffleResult?` | 현재 셔플 결과 객체. null이면 로딩 중이거나 실패 상태. |
| `_currentCardCount` | `int` | 현재 표시 중인 카드 수. `_addOneMore()`로 증가. |
| `_spreadType` | `SpreadType` | 스프레드 유형 (single, threeCard, custom). |
| `_deckId` | `String` | 사용 중인 덱 ID. 기본값 `'rws-standard'`. |
| `_allowReversed` | `bool` | 역방향 카드 허용 여부. |
| `_showCardName` | `bool` | 카드 이름 표시 여부. |
| `_revealedPositions` | `Set<int>` | 공개된 카드 위치 인덱스 집합. |
| `_reuseUpstreamResult` | `bool` | **핵심 분기 플래그**. `initState`에서 1회 판정. 전체 페이지 동작을 결정. |
| `_autoSaved` | `bool` | 자동 저장 1회 실행 보장 가드. |
| `_savedReadingId` | `String?` | 저장된 Reading의 UUID. `_addOneMore()`가 참조. |
| `_loading` | `bool` | 로딩 상태. build에서 3-state 분기에 사용. |
| `_questionController` | `TextEditingController` | 질문 입력 필드 컨트롤러. |
| `_questionExpanded` | `bool` | 질문 입력 영역 확장/축소 토글. |

### 메서드

| 메서드 | 반환 | 역할 |
|--------|------|------|
| `initState()` | `void` | 설정 초기화 + `_reuseUpstreamResult` 단일 지점 판정 + `_executeDraw()` 비동기 트리거. |
| `_initSettings()` | `void` | `userSettingsProvider`에서 spreadType, cardCount, deckId, allowReversed, showCardName을 읽어 로컬 변수에 캐시. |
| `_executeDraw()` | `Future<void>` | 이중 경로 셔플 실행. 업스트림 재사용 또는 자체 셔플. |
| `_triggerAutoSave()` | `void` | `_autoSave()`를 try-catch로 감싼 best-effort 래퍼. |
| `_autoSave()` | `void` | `_autoSaved` 가드 후 UUID 생성, `Reading` 엔티티 조립, `readingRepository.saveReading()` 호출. |
| `_addOneMore()` | `void` | `_currentCardCount` 1 증가, 새 카드 reveal, DB에 `addDrawnCard()` 호출. |
| `_updateQuestion()` | `void` | 입력된 질문을 `readingQuestionProvider`에 세팅. |
| `dispose()` | `void` | `_questionController` 해제. |
| `build()` | `Widget` | 3-state 분기(loading / error / normal) 후 Scaffold 구성. |

## 동작 흐름 (Flow)

### 1. initState 분기 (MA-9)

```
initState()
  |
  +-- _initSettings()  // userSettingsProvider에서 설정 캐시
  |
  +-- ref.read(shuffleStateProvider) 읽기
  |     |
  |     +-- non-null --> _reuseUpstreamResult = true   (Lv2/Lv4 업스트림 경로)
  |     +-- null    --> _reuseUpstreamResult = false   (Lv1 자체 셔플 경로)
  |
  +-- Future.microtask(() => _executeDraw())
```

`_reuseUpstreamResult`는 initState에서 **단 1회** 평가되며, 이후 `_executeDraw()` 내부에서 소비된다. "다시" 버튼이 이 플래그를 `false`로 리셋하므로, 재셔플 시에는 항상 자체 셔플 경로를 탄다.

### 2. _executeDraw 이중 경로

#### 경로 A: 업스트림 재사용 (_reuseUpstreamResult == true)

```
_executeDraw()
  |
  +-- ref.read(shuffleStateProvider)  // clear 금지! 업스트림 객체 identity 보존
  |
  +-- setState: _shuffleResult = upstream, _loading = false
  |   + 모든 카드 즉시 reveal (업스트림에서 이미 공개된 상태)
  |
  +-- _triggerAutoSave()
```

**clear() 금지**: 업스트림이 세팅한 `shuffleStateProvider` 값을 지우면 결과가 소실된다. 업스트림 경로에서는 provider를 읽기만 하고 절대 초기화하지 않는다.

#### 경로 B: 자체 셔플 (_reuseUpstreamResult == false)

```
_executeDraw()
  |
  +-- shuffleStateProvider.clear()       // 이전 잔류 상태 제거
  +-- readingQuestionProvider.clear()     // 이전 질문 제거
  |
  +-- deckRepository.seedAllDecks()       // 홈을 건너뛴 경우 대비
  +-- deckCardsProvider(_deckId) await    // 덱 카드 로드
  +-- shuffleDeckUseCase.execute()        // Fisher-Yates 셔플 실행
  +-- shuffleStateProvider.setResult()    // 결과 provider에 세팅
  |
  +-- setState: _shuffleResult = result, _loading = false
  |   + 모든 카드 즉시 reveal
  |
  +-- _triggerAutoSave()
```

### 3. 자동 저장 흐름

```
_triggerAutoSave()
  |
  +-- try { _autoSave() } catch { debugPrint }  // best-effort
        |
        +-- _autoSaved == true? --> return (중복 방지)
        +-- _shuffleResult == null? --> return
        |
        +-- UUID v4 생성 --> _savedReadingId에 보관
        +-- Reading 엔티티 조립 (drawnCards, question, spreadType 등)
        +-- readingRepository.saveReading(reading)
        +-- _autoSaved = true
```

`_autoSaved` 가드가 저장을 정확히 1회로 제한한다. `_savedReadingId`는 이후 `_addOneMore()`가 DB에 카드를 추가할 때 참조한다.

### 4. "다시" 버튼 재셔플

```
"다시" 버튼 onPressed
  |
  +-- setState:
  |     _shuffleResult = null
  |     _revealedPositions.clear()
  |     _savedReadingId = null
  |     _autoSaved = false           // 자동 저장 리셋
  |     _loading = true
  |     _reuseUpstreamResult = false // 강제로 자체 셔플 경로 진입
  |
  +-- _executeDraw()  --> 경로 B(자체 셔플)를 타고 새 결과 생성
```

"다시"를 누르면 업스트림 결과 재사용 플래그가 리셋되므로, 원래 Lv2/Lv4 업스트림으로 진입했더라도 재셔플은 항상 이 페이지 자체에서 수행된다.

### 5. "+1" 카드 추가

```
_addOneMore()
  |
  +-- _currentCardCount >= total cards? --> return (더 이상 뽑을 카드 없음)
  |
  +-- setState: _currentCardCount++
  +-- _revealedPositions.add(새 인덱스)
  |
  +-- _savedReadingId != null?
        |
        +-- readingRepository.addDrawnCard(
              _savedReadingId,
              DrawnCardInfo(새 카드 정보),
              DateTime.now()
            )
```

## 의존성 (Dependencies)

| Provider / 위젯 | 출처 | 용도 |
|-----------------|------|------|
| `shuffleStateProvider` | `shuffle_providers.dart` | `keepAlive: true`. 업스트림 결과 수신 및 자체 셔플 결과 세팅. |
| `readingQuestionProvider` | `intention_page.dart` | `keepAlive: true`. 질문 문자열 관리. 자체 셔플 경로에서 clear, `_updateQuestion()`에서 set. |
| `readingRepositoryProvider` | `reading_providers.dart` | `keepAlive: true`. `saveReading()`, `addDrawnCard()` 호출. |
| `userSettingsProvider` | `settings_providers.dart` | 사용자 설정(spreadType, cardCount, deckId, allowReversed, showCardName) 읽기. |
| `cardAspectRatioProvider` | `settings_providers.dart` | 카드 종횡비 설정. `build`에서 `ref.watch`로 반응형 구독. |
| `deckRepositoryProvider` | `deck_providers.dart` | 덱 시드 보장(`seedAllDecks`). 자체 셔플 경로에서만 사용. |
| `deckCardsProvider` | `deck_providers.dart` | 특정 덱의 카드 목록 로드. family provider (deckId 파라미터). |
| `shuffleDeckUseCaseProvider` | `shuffle_providers.dart` | 셔플 유스케이스 실행. |
| `shuffleStrategyProvider` | `shuffle_providers.dart` | Fisher-Yates 셔플 전략 주입. |
| `SpreadLayout` | `spread_layout.dart` | 스프레드 유형별 카드 레이아웃 위젯 (single / threeCard / custom grid). |
| `Uuid` | `uuid` 패키지 | Reading ID 생성용. `_autoSave()`에서 `v4()` 호출. |
| `GoRouter` | `go_router` 패키지 | `context.go('/')`로 홈 복귀. |
| `ShuffleConfig` | `shuffle_config.dart` | 셔플 설정 엔티티 (useReversals). |
| `Reading`, `DrawnCardInfo` | `reading.dart` | 저장 엔티티. freezed 기반. |
| `SpreadType` | `spread_type.dart` | 스프레드 enum (single, threeCard, custom). |

## 주의사항 (Caveats)

### _reuseUpstreamResult 단일 지점 평가

`_reuseUpstreamResult`는 `initState`에서 **정확히 1회** `ref.read(shuffleStateProvider)`의 null 여부로 판정된다. 이 판정은 이후 `_executeDraw()`가 어떤 경로를 탈지를 결정하는 유일한 분기점이다. `Future.microtask`로 `_executeDraw()`를 호출하므로, initState 시점의 provider 값이 microtask 실행 시점까지 유지된다는 가정에 의존한다. 업스트림 페이지가 `pushReplacement` 직후 provider를 비우는 등의 시나리오에서는 race condition이 발생할 수 있으나, 현재 아키텍처에서는 업스트림이 clear를 호출하지 않으므로 안전하다.

### clear() 금지 -- 업스트림 경로

업스트림 재사용 경로에서 `shuffleStateProvider.notifier.clear()`를 호출하면 업스트림이 세팅한 셔플 결과가 소실된다. 이 제약은 코드 내 주석과 IntentionPage의 `initState` 주석(Brief MA-3)에서도 명시되어 있다. 자체 셔플 경로에서만 clear가 허용된다.

### best-effort _triggerAutoSave

`_triggerAutoSave()`는 `_autoSave()`를 try-catch로 감싼다. `readingRepositoryProvider`가 override되지 않은 테스트 환경이나, DB 접근이 실패하는 상황에서 예외가 발생하더라도 페이지 렌더링에는 영향을 주지 않도록 설계되었다. 자동 저장은 "있으면 좋고 없어도 페이지는 동작하는" best-effort 기능이다.

### _autoSaved 가드의 단방향성

`_autoSaved`는 `true`로 세팅된 뒤 "다시" 버튼에서만 `false`로 리셋된다. 따라서 한 번의 셔플 결과에 대해 `saveReading()`은 정확히 1회만 호출된다. `_addOneMore()`는 이미 저장된 Reading에 카드를 추가하는 방식이므로 `_autoSaved`와 무관하게 동작한다.

### question 업데이트 흐름

질문 입력 필드의 `onSubmitted` 콜백은 `_updateQuestion()`을 호출하며, 이 메서드는 `readingQuestionProvider`에 값을 세팅한다. 그러나 이미 저장된 Reading 엔티티의 question 필드를 DB에서 업데이트하지는 않는다. `readingQuestionProvider`에 세팅된 값은 다음 뽑기 세션에서 참조될 수 있으나, 현재 세션의 이미 저장된 Reading에는 반영되지 않는 점에 주의해야 한다.

### build 3-state 분기

`build()`는 `_loading`, `_shuffleResult == null`, 정상의 3가지 상태를 순차적으로 검사한다. 로딩 중과 실패 상태에서는 각각 `CircularProgressIndicator`와 에러 텍스트를 표시하며, 정상 상태에서만 전체 결과 UI(질문 입력, SpreadLayout, 하단 버튼 바)를 렌더링한다.

## Changelog

### v1 (2026-04-16) -- 최초 작성

대상 커밋 `96a0c15`까지의 DrawResultPage 전체 구조, 이중 경로 분기(MA-9), 자동 저장 흐름, 상태 변수, 의존성, 주의사항을 포함한 최초 해설 문서.
