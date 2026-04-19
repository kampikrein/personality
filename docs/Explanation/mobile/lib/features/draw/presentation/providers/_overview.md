---
id: "mobile-lib-features-draw-presentation-providers"
type: explanation
target: "mobile/lib/features/draw/presentation/providers/"
layer: folder
version: 1
created: 2026-04-16
updated: 2026-04-16
last_explained_commit: "96a0c15dc43d5af2b98e32fec1f157eeacc1e8df"
---

# draw/presentation/providers/ — 해설

## 개요

뽑기 피처 전용 Riverpod provider를 모아둔 디렉토리다.
현재는 `executeDraw` 단일 provider만 존재하며,
사용자 설정 기반 one-shot 셔플 실행을 캡슐화한다.

## 역할 (Role)

`pages/`의 페이지들이 셔플 로직을 직접 인라인하는 대신
이 provider를 호출하여 셔플을 수행하도록 추상화하는 것이 설계 목적이다.
다만 현재 `AnimatedDrawPage`와 `DrawResultPage`는 각자 셔플 로직을 직접 포함하고 있어,
이 provider는 **예비 use case** 형태로 존재한다.

## 구조 (Structure)

```
providers/
├── draw_providers.dart     @riverpod executeDraw — one-shot 셔플 오케스트레이터
└── draw_providers.g.dart   riverpod_generator 자동생성 (직접 편집 금지)
```

| 파일 | 심볼 | 종류 | 역할 |
|------|------|------|------|
| `draw_providers.dart` | `executeDraw` | `@riverpod` 함수 | 설정 읽기 → 덱 로드 → 셔플 → 상태 세팅 → 결과 반환 |
| `draw_providers.g.dart` | `executeDrawProvider` | `AutoDisposeFutureProvider<ShuffleResult>` | `executeDraw`의 codegen 생성물 |

## 동작 흐름 (Flow)

`executeDraw`의 실행 흐름:

```
ref.read(userSettingsProvider) → selectedDeckId 추출
  ↓
ref.read(deckCardsProvider(deckId).future) → List<TarotCard> 로드
  ↓
ref.read(shuffleDeckUseCaseProvider) + ref.read(shuffleStrategyProvider)
  ↓
useCase.execute(cards, strategy) → ShuffleResult 생성
  ↓
ref.read(shuffleStateProvider.notifier).setResult(result) → 전역 상태 세팅
  ↓
return result
```

전체 흐름이 `ref.read()`만 사용하며, `ref.watch()`는 없다.
이는 one-shot 실행(호출 시점에 현재 값만 읽기)을 의도한 설계이다.

## 의존성 (Dependencies)

| 대상 | 종류 | 역할 |
|------|------|------|
| `userSettingsProvider` | `settings/` 피처 | `selectedDeckId` 추출 |
| `deckCardsProvider(deckId)` | `deck/` 피처 | 덱 카드 목록 비동기 로드 |
| `shuffleDeckUseCaseProvider` | `shuffle/` 피처 | 셔플 알고리즘 실행 |
| `shuffleStrategyProvider` | `shuffle/` 피처 | FisherYates 전략 제공 |
| `shuffleStateProvider` | `shuffle/` 피처 | 셔플 결과 전역 세팅 (keepAlive) |

## 주의사항 (Caveats)

- **현재 미사용**: `executeDrawProvider`는 어떤 페이지에서도 호출되지 않는다. `DrawResultPage`와 `AnimatedDrawPage`가 동일한 셔플 로직을 각자 인라인으로 구현 중이다. 향후 리팩터링 시 이 provider로 통합될 수 있다.
- **`ShuffleConfig` 미전달**: 페이지 인라인 코드는 `ShuffleConfig(useReversals: _allowReversed)`를 전달하지만, 이 provider는 `ShuffleConfig`를 전달하지 않아 기본값만 사용된다. 실제 사용 시 config 파라미터 추가가 필요하다.
- **AutoDispose 수명**: `executeDrawProvider`는 `AutoDispose`이므로 구독이 해제되면 자동 소멸된다. 결과는 `shuffleStateProvider`(keepAlive)에도 저장되므로 provider 소멸 후에도 결과는 유지된다.
- **`.g.dart` 직접 편집 금지**: `executeDraw` 시그니처 변경 시 `flutter pub run build_runner build` 필수.

## 하위 구성 (Contents)

| 구분 | 대상 | 해설 문서 | 한 줄 요약 |
|------|------|----------|-----------|
| 파일 | `draw_providers.dart` | [해설](draw_providers.md) | one-shot 셔플 실행 오케스트레이터 provider |

## Changelog

### v1 (2026-04-16) — 최초 작성
- 최초 해설 문서 생성. executeDraw provider의 미사용 상태 및 페이지 인라인 코드와의 차이 분석 수록.
