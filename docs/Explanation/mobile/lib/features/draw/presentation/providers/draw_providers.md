---
id: "mobile-lib-features-draw-presentation-providers-draw_providers"
type: explanation
target: "mobile/lib/features/draw/presentation/providers/draw_providers.dart"
layer: file
version: 1
created: 2026-04-16
updated: 2026-04-16
last_explained_commit: "96a0c15dc43d5af2b98e32fec1f157eeacc1e8df"
functions: []
---

# draw_providers.dart — 해설

## 개요

`draw_providers.dart`는 뽑기(draw) 기능의 셔플 실행을 단일 Riverpod provider로 캡슐화한 파일이다. 사용자 설정에서 선택된 덱 ID를 읽고, 해당 덱의 카드를 로드한 뒤, 셔플을 실행하여 결과를 전역 상태에 세팅하고 반환하는 one-shot 비동기 오케스트레이터 역할을 한다.

## 역할 (Role)

이 파일은 뽑기 유즈케이스의 오케스트레이터이다. 여러 feature 모듈에 분산된 provider들을 하나의 실행 흐름으로 조합한다.

1. **설정 읽기**: `userSettingsProvider`에서 `UserSettings`를 읽어 선택된 덱 ID(`selectedDeckId`)를 추출한다. 값이 없으면 기본 설정(`selectedDeckId: 'rws-standard'`)으로 폴백한다.
2. **덱 로드**: `deckCardsProvider(deckId)`를 통해 해당 덱의 `List<TarotCard>`를 비동기로 가져온다.
3. **셔플 실행**: `shuffleDeckUseCaseProvider`와 `shuffleStrategyProvider`를 조합하여 `useCase.execute()`를 호출한다.
4. **상태 세팅**: 셔플 결과를 `shuffleStateProvider.notifier.setResult()`로 전역 `ShuffleState`에 저장한다.
5. **결과 반환**: `ShuffleResult`를 호출자에게 반환한다.

이 provider는 뽑기에 필요한 모든 준비 단계를 한 곳에서 처리하여, 페이지가 셔플 로직의 세부 사항을 알 필요 없도록 추상화하는 것이 설계 목적이다.

## 구조 (Structure)

파일은 단일 `@riverpod` 함수 하나로 구성된다.

```
draw_providers.dart
  └─ executeDraw(ExecuteDrawRef ref) → Future<ShuffleResult>
        @riverpod 어노테이션
```

`build_runner`에 의해 생성되는 `draw_providers.g.dart`에서 다음이 정의된다:

| 생성 요소 | 타입 | 설명 |
|-----------|------|------|
| `executeDrawProvider` | `AutoDisposeFutureProvider<ShuffleResult>` | provider 인스턴스 |
| `ExecuteDrawRef` | `AutoDisposeFutureProviderRef<ShuffleResult>` | ref 타입 별칭 (3.0에서 제거 예정) |
| `_$executeDrawHash()` | `String Function()` | 코드 변경 감지용 해시 |

`@riverpod` (소문자)로 선언되었으므로 `keepAlive: false`가 적용되며, 리스너가 모두 해제되면 상태가 자동 폐기(auto-dispose)된다.

## 동작 흐름 (Flow)

```
executeDraw 호출
  │
  ├─ 1. ref.read(userSettingsProvider)
  │     └─ .valueOrNull ?? UserSettings(updatedAt: now)
  │         → settings 확보
  │
  ├─ 2. settings.selectedDeckId
  │     → deckId 추출 (기본값 'rws-standard')
  │
  ├─ 3. await ref.read(deckCardsProvider(deckId).future)
  │     → List<TarotCard> 비동기 로드
  │
  ├─ 4. ref.read(shuffleDeckUseCaseProvider)
  │     → ShuffleDeckUseCase 인스턴스
  │
  ├─ 5. ref.read(shuffleStrategyProvider)
  │     → ShuffleStrategy (현재: FisherYatesShuffleStrategy)
  │
  ├─ 6. useCase.execute(cards, strategy)
  │     → ShuffleResult 생성
  │     (내부: 센서 엔트로피 수집 → Random.secure() → 전략 실행)
  │
  ├─ 7. ref.read(shuffleStateProvider.notifier).setResult(result)
  │     → 전역 ShuffleState에 결과 저장 + repository 캐시
  │
  └─ 8. return result
        → ShuffleResult 반환
```

모든 의존성을 `ref.read()`로 읽는다. 이는 의도적 선택으로, `executeDraw`가 one-shot 실행 함수이기 때문이다. `ref.watch()`를 사용하면 의존성 변경 시 provider가 재실행되어 의도치 않은 중복 셔플이 발생할 수 있다.

## 의존성 (Dependencies)

| Provider | 출처 모듈 | 타입 | 접근 방식 | 용도 |
|----------|-----------|------|-----------|------|
| `userSettingsProvider` | settings | `StreamProvider<UserSettings>` | `ref.read().valueOrNull` | 선택된 덱 ID, 기본 설정 |
| `deckCardsProvider(deckId)` | deck | `FutureProvider<List<TarotCard>>` | `await ref.read(.future)` | 셔플 대상 카드 목록 |
| `shuffleDeckUseCaseProvider` | shuffle | `Provider<ShuffleDeckUseCase>` | `ref.read()` | 셔플 실행 로직 (센서 엔트로피 + 전략) |
| `shuffleStrategyProvider` | shuffle | `Provider<ShuffleStrategy>` | `ref.read()` | 셔플 알고리즘 (Fisher-Yates) |
| `shuffleStateProvider` | shuffle | `NotifierProvider<ShuffleState, ShuffleResult?>` | `ref.read(.notifier)` | 결과를 전역 상태에 세팅 |

의존성 흐름 요약: `settings → deck → shuffle(useCase + strategy) → shuffleState`

## 주의사항 (Caveats)

### 현재 미사용 상태

`executeDrawProvider`는 어떤 페이지에서도 import하거나 사용하지 않는다. 실제 뽑기를 수행하는 `DrawResultPage`는 `_executeDraw()` 메서드에서 동일한 로직을 인라인으로 구현하고 있으며, 추가로 `ShuffleConfig(useReversals:)` 옵션 전달, `shuffleStateProvider` 초기값 분기(MA-9), `seedAllDecks()` 호출, 에러 핸들링 등 페이지 전용 로직을 포함한다. 이 provider는 향후 페이지 로직을 provider 레이어로 끌어올릴 때 사용될 수 있는 설계 초안이다.

### AutoDispose 생명주기

`@riverpod` (소문자)로 선언되어 `AutoDispose`가 적용된다. 리스너가 없으면 즉시 폐기되므로, 결과를 캐시하려면 `shuffleStateProvider`(`keepAlive: true`)에 저장하는 현재 패턴이 필수적이다. provider 자체를 재호출하면 매번 새로운 셔플이 실행된다.

### ref.read() vs ref.watch() 선택

모든 의존성을 `ref.read()`로 접근한다. one-shot 실행에 적합한 선택이지만, 이는 provider가 실행 시점의 스냅샷만 반영함을 의미한다. 예를 들어 사용자가 설정을 변경해도 이미 실행 중인 `executeDraw`에는 반영되지 않는다.

### ShuffleConfig 미전달

`DrawResultPage._executeDraw()`와 달리 이 provider는 `useCase.execute()`에 `ShuffleConfig`를 명시적으로 전달하지 않아 기본값(`ShuffleConfig()`)이 사용된다. 즉 `useReversals` 설정이 반영되지 않는 차이가 있다.

### 생성 파일 편집 금지

`draw_providers.g.dart`는 `build_runner`가 자동 생성하는 파일이다. 직접 수정하면 다음 코드 생성 시 덮어씌워진다. 소스 파일(`draw_providers.dart`)만 편집하고 `dart run build_runner build`로 재생성해야 한다.

## Changelog

### v1 (2026-04-16) — 최초 작성

- `executeDraw` provider의 역할, 구조, 동작 흐름 해설
- 5개 의존 provider와의 관계 매핑
- 현재 미사용 상태, AutoDispose 생명주기, `ShuffleConfig` 미전달 차이 등 주의사항 기술
