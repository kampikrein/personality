---
id: "006"
type: plan
title: "결과 화면 앞면 이미지 + 덱 선택 비주얼 (Cycle 2)"
created: 2026-03-22
traces_scope: "002"
traces_research: ""
summary: >
  CardRevealWidget에 Image.asset(imagePath) 앞면 + card_back.webp 뒷면 이미지 적용,
  cacheWidth 기반 메모리 최적화, ShufflePage에 셔플 결과 설정 복원,
  DeckSelectionPage를 카드형 비주얼 프리뷰로 교체. 4개 파일 수정.
keywords: [card-image, cacheWidth, spread-view, deck-selection, visual-preview, EV-005-S1]
---

# 006 — 결과 화면 앞면 이미지 + 덱 선택 비주얼 (Cycle 2)

## Goal

Cycle 1에서 확립된 이미지 경로 규약(`assets/images/{deckId}/`)을 기반으로:
1. 결과 화면(`CardRevealWidget`)에서 실제 카드 앞면/뒷면 이미지 표시
2. `cacheWidth` 기반 런타임 다운스케일로 메모리 최적화
3. `ShufflePage` → `ReadingPage` 전환 시 셔플 결과 설정 복원 (EV-005-S1 해결)
4. `DeckSelectionPage`를 비주얼 카드 프리뷰로 업그레이드

## Scope

### Included
| # | Item | Description |
|---|------|-------------|
| 1 | CardRevealWidget 앞면 이미지 | `_buildFront()`: `Image.asset(card.imagePath)` + `cacheWidth` |
| 2 | CardRevealWidget 뒷면 이미지 | `_buildBack()`: `Image.asset('assets/images/$deckId/card_back.webp')` + `cacheWidth` |
| 3 | deckId 전파 | `SpreadLayout` → `CardRevealWidget`에 deckId 전달 |
| 4 | ShufflePage 셔플 결과 설정 | `_goToReading()`에서 `shuffleStateProvider.setResult()` 호출 복원 (EV-005-S1) |
| 5 | DeckSelectionPage 비주얼 프리뷰 | card_back 썸네일 + 대표 카드 2장 + 카드 수 표시 |
| 6 | cacheWidth 메모리 최적화 | 스프레드 뷰: 화면 너비의 1/3 수준, 덱 선택: 썸네일 사이즈 |

### Excluded
| Item | Reason/Timeline |
|------|-----------------|
| 카드 확대(full-screen) 뷰 | 향후 과제 — 현재 스프레드 뷰만 |
| 카드 해석 콘텐츠 변경 | 이미지 표시와 별도 영역 |
| dead code 정리 (entropy/sensor) | EV-005-A1 — Cycle 2 범위 외 |

## Structural Decisions

> No structural decisions required — straightforward implementation.
>
> 모든 접근 방식이 Brief Model Anchors (2~5)에 의해 결정되어 있다:
> - 앞면: `Image.asset(imagePath)` (Anchor 2)
> - 해상도 전략: 고해상도 원본 + `cacheWidth` 다운스케일 (Anchor 3)
> - 스프레드 뷰 cacheWidth: 화면 너비의 1/3~1/4 (Anchor 4)
> - 덱 선택: card_back + 대표 카드 + 카드 수 (Anchor 5)

---

## File Change Summary

### Modified Files
| # | File Path | Change Description |
|---|-----------|-------------------|
| 1 | `mobile/lib/features/shuffle/presentation/pages/shuffle_page.dart` | `_goToReading()`에 셔플 결과 설정 추가 (EV-005-S1) |
| 2 | `mobile/lib/features/reading/presentation/widgets/spread_layout.dart` | deckId 파라미터 추가, CardRevealWidget에 전달 |
| 3 | `mobile/lib/features/reading/presentation/widgets/card_reveal_widget.dart` | deckId 파라미터 추가, 앞면/뒷면 이미지 렌더링 교체, cacheWidth 적용 |
| 4 | `mobile/lib/features/deck/presentation/pages/deck_selection_page.dart` | 비주얼 카드 프리뷰 UI로 전면 교체 |

### New Files
| # | File Path | Description |
|---|-----------|-------------|
| — | 없음 | — |

---

## Step 1 — ShufflePage 셔플 결과 설정 복원 (EV-005-S1)

### Approach

`ShufflePage._goToReading()`에서 reading 화면으로 이동하기 전에, 덱의 전체 카드를 로드하고 `ShuffleDeckUseCase`를 실행하여 `shuffleStateProvider`에 셔플 결과를 설정한다.

현재 `_goToReading()`는 셔플 결과 없이 바로 네비게이션하므로, `ReadingPage`가 `shuffleStateProvider`를 watch할 때 null → "셔플을 먼저 진행해주세요" 폴백이 표시된다.

### Current Code
```dart
// shuffle_page.dart:52-58
void _goToReading() {
  ref.read(hapticServiceProvider).mediumImpact();
  context.pushNamed(
    'reading',
    pathParameters: {'deckId': widget.deckId},
  );
}
```

### After Code
```dart
// shuffle_page.dart
Future<void> _goToReading() async {
  ref.read(hapticServiceProvider).mediumImpact();

  // 덱 카드 로드 + 셔플 실행
  final cards = await ref.read(deckCardsProvider(widget.deckId).future);
  final useCase = ref.read(shuffleDeckUseCaseProvider);
  final strategy = ref.read(shuffleStrategyProvider);
  final result = useCase.execute(cards: cards, strategy: strategy);
  ref.read(shuffleStateProvider.notifier).setResult(result);

  if (!mounted) return;
  context.pushNamed(
    'reading',
    pathParameters: {'deckId': widget.deckId},
  );
}
```

### Considerations

- `deckCardsProvider`는 `deck_providers.dart`에 이미 정의되어 있으므로 import만 추가하면 된다.
- `shuffleDeckUseCaseProvider`, `shuffleStrategyProvider`는 `shuffle_providers.dart`에 이미 정의되어 있고, 현재 `shuffle_page.dart`가 이미 import하고 있다.
- `deckCardsProvider`의 import는 `../../../deck/presentation/providers/deck_providers.dart`에서 가져온다 (이미 `deckRepositoryProvider`를 위해 import 중).
- `async` 전환 + `mounted` 체크로 비동기 안전성 확보.

---

## Step 2 — SpreadLayout에 deckId 전파

### Approach

`SpreadLayout`에 `deckId` 파라미터를 추가하고, 내부에서 생성하는 모든 `CardRevealWidget`에 전달한다.

### Current Code
```dart
// spread_layout.dart:7-19
class SpreadLayout extends StatelessWidget {
  const SpreadLayout({
    super.key,
    required this.spreadType,
    required this.cards,
    required this.revealedPositions,
    required this.onCardTap,
  });

  final SpreadType spreadType;
  final List<ShuffledCard> cards;
  final Set<int> revealedPositions;
  final ValueChanged<int> onCardTap;
```

### After Code
```dart
// spread_layout.dart
class SpreadLayout extends StatelessWidget {
  const SpreadLayout({
    super.key,
    required this.spreadType,
    required this.cards,
    required this.deckId,
    required this.revealedPositions,
    required this.onCardTap,
  });

  final SpreadType spreadType;
  final List<ShuffledCard> cards;
  final String deckId;
  final Set<int> revealedPositions;
  final ValueChanged<int> onCardTap;
```

`_buildSingleLayout()`과 `_buildThreeCardLayout()` 내부의 `CardRevealWidget` 생성에 `deckId: deckId`를 추가한다.

```dart
// _buildSingleLayout (변경 후)
Widget _buildSingleLayout() {
  return Center(
    child: CardRevealWidget(
      card: cards[0],
      deckId: deckId,
      position: 0,
      label: spreadType.positions[0],
      isRevealed: revealedPositions.contains(0),
      onTap: () => onCardTap(0),
    ),
  );
}

// _buildThreeCardLayout (변경 후)
Widget _buildThreeCardLayout() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: List.generate(3, (i) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: CardRevealWidget(
            card: cards[i],
            deckId: deckId,
            position: i,
            label: spreadType.positions[i],
            isRevealed: revealedPositions.contains(i),
            onTap: () => onCardTap(i),
          ),
        ),
      );
    }),
  );
}
```

호출자인 `ReadingPage`도 `SpreadLayout`에 `deckId` 전달:

```dart
// reading_page.dart:99 (변경 후)
child: SpreadLayout(
  spreadType: _spreadType,
  cards: drawnCards,
  deckId: widget.deckId,
  revealedPositions: _revealedPositions,
  onCardTap: (position) {
    setState(() => _revealedPositions.add(position));
  },
),
```

### Considerations

- `ReadingPage`는 이미 `widget.deckId`를 보유하고 있으므로 추가 파라미터 변경 불필요.
- `ReadingPage`도 Modified 파일에 해당하지만, 1줄 추가이므로 별도 Step으로 분리하지 않고 여기서 함께 처리.

---

## Step 3 — CardRevealWidget 이미지 렌더링

### Approach

`CardRevealWidget`에 `deckId` 파라미터를 추가하고, `_buildFront()`를 `Image.asset(imagePath)`로, `_buildBack()`을 `Image.asset(card_back.webp)`로 교체한다. 두 메서드 모두 `cacheWidth`를 적용하여 메모리 최적화.

**cacheWidth 계산 로직** (Brief Anchor 3, 4):
- 스프레드 뷰에서 카드는 화면 너비의 1/3 수준 (threeCard) 또는 화면 너비의 2/3 수준 (single)
- `cacheWidth`는 카드가 표시될 물리적 너비(pixel) 기준으로 설정
- `MediaQuery.of(context).size.width`와 `devicePixelRatio`를 사용하여 실제 필요 픽셀 계산
- threeCard일 때 각 카드 너비 ≈ `screenWidth / 3`, 즉 `cacheWidth = (screenWidth / 3 * pixelRatio).toInt()`
- single일 때 카드 너비 ≈ 전체 width, `cacheWidth = (screenWidth * 0.7 * pixelRatio).toInt()`
- **간소화**: `LayoutBuilder`로 실제 부모 너비를 가져와서 `(constraints.maxWidth * pixelRatio).toInt()`로 계산하면 레이아웃 모드에 무관하게 정확

### Current Code — Constructor
```dart
// card_reveal_widget.dart:8-16
class CardRevealWidget extends StatefulWidget {
  const CardRevealWidget({
    super.key,
    required this.card,
    required this.position,
    required this.label,
    required this.isRevealed,
    required this.onTap,
  });

  final ShuffledCard card;
  final int position;
  final String label;
  final bool isRevealed;
  final VoidCallback onTap;
```

### After Code — Constructor
```dart
// card_reveal_widget.dart
class CardRevealWidget extends StatefulWidget {
  const CardRevealWidget({
    super.key,
    required this.card,
    required this.deckId,
    required this.position,
    required this.label,
    required this.isRevealed,
    required this.onTap,
  });

  final ShuffledCard card;
  final String deckId;
  final int position;
  final String label;
  final bool isRevealed;
  final VoidCallback onTap;
```

### Current Code — _buildBack
```dart
// card_reveal_widget.dart:115-132
Widget _buildBack(ThemeData theme) {
  return AspectRatio(
    aspectRatio: 2.5 / 3.5,
    child: Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D1B4E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.primary, width: 1.5),
      ),
      child: Center(
        child: Icon(Icons.auto_awesome,
            semanticLabel: '카드 뒷면',
            color: theme.colorScheme.primary,
            size: 32),
      ),
    ),
  );
}
```

### After Code — _buildBack
```dart
// card_reveal_widget.dart
Widget _buildBack(ThemeData theme) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final pixelRatio = MediaQuery.of(context).devicePixelRatio;
      final cacheW = (constraints.maxWidth * pixelRatio).toInt().clamp(1, 1024);
      return AspectRatio(
        aspectRatio: 2.5 / 3.5,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/images/${widget.deckId}/card_back.webp',
            cacheWidth: cacheW,
            fit: BoxFit.cover,
            semanticLabel: '카드 뒷면',
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFF2D1B4E),
              child: Center(
                child: Icon(Icons.auto_awesome,
                    color: theme.colorScheme.primary, size: 32),
              ),
            ),
          ),
        ),
      );
    },
  );
}
```

### Current Code — _buildFront
```dart
// card_reveal_widget.dart:134-169
Widget _buildFront(ThemeData theme) {
  return Transform(
    alignment: Alignment.center,
    transform: Matrix4.identity()..rotateY(math.pi),
    child: AspectRatio(
      aspectRatio: 2.5 / 3.5,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1028),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.primary, width: 1.5),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.card.card.name,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.card.card.meanings.upright.take(2).join(', '),
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}
```

### After Code — _buildFront
```dart
// card_reveal_widget.dart
Widget _buildFront(ThemeData theme) {
  return Transform(
    alignment: Alignment.center,
    transform: Matrix4.identity()..rotateY(math.pi),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final pixelRatio = MediaQuery.of(context).devicePixelRatio;
        final cacheW = (constraints.maxWidth * pixelRatio).toInt().clamp(1, 1024);
        return AspectRatio(
          aspectRatio: 2.5 / 3.5,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 카드 앞면 이미지
                Image.asset(
                  widget.card.card.imagePath,
                  cacheWidth: cacheW,
                  fit: BoxFit.cover,
                  semanticLabel: widget.card.card.name,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFF1A1028),
                    child: Center(
                      child: Text(
                        widget.card.card.name,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                // 카드 이름 오버레이 (하단)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Text(
                      widget.card.card.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
```

### Considerations

- **cacheWidth 계산**: `LayoutBuilder`를 사용하면 단일 카드/3장 카드 레이아웃에 무관하게 실제 할당된 너비에 맞춰 자동 조정된다. `clamp(1, 1024)`로 최소 1px, 최대 1024px로 제한하여 극단 케이스 방지.
- **errorBuilder**: 이미지 로드 실패 시 기존 텍스트 표시로 graceful fallback.
- **카드 이름 오버레이**: 이미지 위에 반투명 그라디언트 + 텍스트로 카드 이름 표시. 이미지만으로는 카드 식별이 어려울 수 있으므로 이름 표시 유지.
- **역방향 카드**: `isReversed` 표시는 기존 로직(위젯 하단 텍스트)을 유지하므로 이미지 자체는 회전하지 않는다. 역방향은 텍스트 안내로만 표시하는 현재 설계를 따른다.
- **`Image.asset`의 `cacheWidth`**: Flutter의 `ResizeImage`를 내부적으로 사용하여 디코딩 시점에 원본보다 작은 크기로 디코딩. 표시 크기보다 큰 이미지의 메모리를 즉시 절약한다.

---

## Step 4 — DeckSelectionPage 비주얼 프리뷰

### Approach

`DeckSelectionPage`의 `ListView`+`ListTile`을 카드형 비주얼 프리뷰로 교체한다.

각 덱 항목 구성:
- card_back.webp 썸네일 (왼쪽)
- 대표 카드 2장 미리보기 (첫 번째, 두 번째 카드) — `deckCardsProvider`로 로드
- 덱 이름 + 카드 수

카드 이미지는 `cacheWidth`를 80px 수준(썸네일)으로 제한하여 메모리 효율적.

### Current Code
```dart
// deck_selection_page.dart:28-57
return Scaffold(
  appBar: AppBar(title: const Text('덱 선택')),
  body: decksAsync.when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (err, _) => Center(child: Text('오류: $err')),
    data: (decks) => ListView.builder(
      padding: EdgeInsets.all(listPadding),
      itemCount: decks.length,
      itemBuilder: (context, index) {
        final deck = decks[index];
        return Card(
          child: ListTile(
            title: Text(deck.name, style: theme.textTheme.bodyLarge),
            subtitle: Text('${deck.totalCards}장'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ref.read(selectedDeckProvider.notifier).select(deck);
              context.pushNamed(
                'intention',
                pathParameters: {'deckId': deck.id},
              );
            },
          ),
        );
      },
    ),
  ),
);
```

### After Code
```dart
// deck_selection_page.dart
return Scaffold(
  appBar: AppBar(title: const Text('덱 선택')),
  body: decksAsync.when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (err, _) => Center(child: Text('오류: $err')),
    data: (decks) => ListView.builder(
      padding: EdgeInsets.all(listPadding),
      itemCount: decks.length,
      itemBuilder: (context, index) {
        final deck = decks[index];
        return _DeckPreviewCard(
          deck: deck,
          onTap: () {
            ref.read(selectedDeckProvider.notifier).select(deck);
            context.pushNamed(
              'intention',
              pathParameters: {'deckId': deck.id},
            );
          },
        );
      },
    ),
  ),
);
```

**_DeckPreviewCard 위젯** (같은 파일 내 private 위젯):

```dart
// deck_selection_page.dart — 파일 하단에 추가

class _DeckPreviewCard extends ConsumerWidget {
  const _DeckPreviewCard({
    required this.deck,
    required this.onTap,
  });

  final DeckMetadata deck;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cardsAsync = ref.watch(deckCardsProvider(deck.id));
    // 썸네일 cacheWidth: 80 logical px * pixelRatio
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final thumbCacheW = (80 * pixelRatio).toInt().clamp(1, 320);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 카드 뒷면 이미지 (왼쪽)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/images/${deck.id}/card_back.webp',
                  width: 60,
                  height: 84,
                  cacheWidth: thumbCacheW,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 60,
                    height: 84,
                    color: const Color(0xFF2D1B4E),
                    child: const Icon(Icons.auto_awesome, color: Colors.white54, size: 24),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 덱 정보 (중앙)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(deck.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${deck.totalCards}장',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              // 대표 카드 2장 프리뷰 (오른쪽)
              cardsAsync.when(
                loading: () => const SizedBox(width: 68),
                error: (_, __) => const SizedBox(width: 68),
                data: (cards) {
                  final previewCards = cards.take(2).toList();
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < previewCards.length; i++) ...[
                        if (i > 0) const SizedBox(width: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.asset(
                            previewCards[i].imagePath,
                            width: 32,
                            height: 45,
                            cacheWidth: thumbCacheW,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 32,
                              height: 45,
                              color: const Color(0xFF1A1028),
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: theme.colorScheme.secondary),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Considerations

- **`deckCardsProvider` 재사용**: `deck_providers.dart`에 이미 `deckCardsProvider(deckId)`가 FutureProvider로 정의되어 있다. 덱 목록 화면에서 각 덱의 카드 2장만 필요하지만, 전체 카드를 로드하는 것은 캐싱 이점이 있다 (같은 provider를 셔플에서도 사용하므로).
- **대표 카드 선택**: `cards.take(2)` — DB 순서대로 첫 2장. 일반적으로 major-00 (The Fool), major-01 (The Magician)이 된다. 덱의 대표성을 잘 보여준다.
- **thumbCacheW**: 80px 기준 x pixelRatio. 320px 상한으로 3x 디스플레이까지 커버.
- **ConsumerWidget**: `deckCardsProvider`를 watch하기 위해 `ConsumerWidget`으로 선언. `DeckSelectionPage` 자체는 이미 `ConsumerWidget`.
- **import 추가 필요**: `../../domain/entities/deck_metadata.dart` (이미 deck_providers.dart에서 간접 접근 가능하나 타입 사용을 위해 명시적 import).

---

## Considerations & Trade-offs

### Alternative Approaches

| 대안 | 미채택 이유 |
|------|-----------|
| `CachedNetworkImage` 사용 | 로컬 에셋이므로 불필요. `Image.asset` + `cacheWidth`로 충분 |
| `precacheImage()` 사전 로딩 | 스프레드 뷰 진입 시 카드 수가 1~3장이므로 즉시 로딩으로 충분. 10장+ 스프레드 추가 시 재검토 |
| 덱 선택 시 GridView 카드 레이아웃 | 현재 덱이 2개뿐이므로 ListView 유지. 5개+ 시 GridView 전환 고려 |
| 역방향 카드 이미지 회전 | 텍스트 안내 방식 유지. 이미지 180도 회전은 직관적이지 않을 수 있음 |

### Potential Risks

| 위험 | 완화 방안 |
|------|---------|
| imagePath가 null이거나 파일 없음 | errorBuilder로 텍스트 폴백 |
| deckCardsProvider 로딩 실패 | 덱 선택 카드 프리뷰: 빈 영역 표시. 셔플 결과: 기존 코드 패스는 따로 에러 처리 |
| cacheWidth 과도한 축소로 이미지 품질 저하 | clamp(1, 1024)로 최소/최대 보장. pixelRatio 반영으로 고밀도 디스플레이 대응 |
| ShuffleDeckUseCase.execute()가 예외 throw | _goToReading()에 try-catch 추가 고려. 단, 현재 use case는 예외를 throw하지 않는 구조 |

### Backward Compatibility

- `SpreadLayout`과 `CardRevealWidget`에 `deckId` 파라미터가 추가되므로, 이 위젯을 사용하는 모든 곳에서 `deckId` 전달 필요. 현재 사용 위치: `ReadingPage` → `SpreadLayout` → `CardRevealWidget` (단일 체인).
- `DeckSelectionPage` UI 변경은 시각적 변경만 — 라우팅/상태 로직은 동일.
- `ShufflePage._goToReading()`의 셔플 결과 설정 복원은 기존 동작(Cycle 1 이전)의 복원이므로 회귀 아님.

---

## Implementation Checklist

- [ ] Step 1: ShufflePage._goToReading()에 셔플 결과 설정 복원 (import 추가 + async 전환)
- [ ] Step 2: SpreadLayout에 deckId 파라미터 추가 + CardRevealWidget 전달 + ReadingPage 호출부 수정
- [ ] Step 3: CardRevealWidget — deckId 파라미터, _buildBack() 이미지, _buildFront() 이미지, cacheWidth
- [ ] Step 4: DeckSelectionPage — _DeckPreviewCard 위젯 추가, ListView에서 사용
- [ ] Final verification: 빌드 성공, 셔플→리딩 전환 시 이미지 표시, 덱 선택 비주얼 확인

## Verification Assertions

| Level | Assertion | Verification Method | Expected Result |
|-------|-----------|-------------------|-----------------|
| L1-Build | Dart 분석 통과 | `cd mobile && dart analyze` | 에러 0건 |
| L1-Build | Flutter 빌드 성공 | `cd mobile && flutter build apk --debug` | BUILD SUCCESSFUL |
| L2-CLI | shuffleStateProvider에 결과 설정됨 | 코드 리뷰 — _goToReading() 내 setResult() 호출 존재 | setResult() 호출 확인 |
| L3-Browser | CardRevealWidget 앞면에 Image.asset 표시 | 앱 실행 → 셔플 → 뽑기 → 카드 탭 | 카드 이미지 표시 |
| L3-Browser | CardRevealWidget 뒷면에 card_back.webp 표시 | 앱 실행 → 셔플 → 뽑기 → 리딩 화면 진입 시 | 뒷면 이미지 표시 |
| L3-Browser | DeckSelectionPage 비주얼 프리뷰 | 앱 실행 → 덱 선택 | card_back + 대표 카드 + 카드 수 표시 |
| L4-Trace | Brief Anchor 2 (Image.asset) | 코드 리뷰 | _buildFront()에 Image.asset(imagePath) |
| L4-Trace | Brief Anchor 3 (cacheWidth) | 코드 리뷰 | cacheWidth 파라미터 사용 |
| L4-Trace | Brief Anchor 4 (1/3~1/4 제한) | 코드 리뷰 | LayoutBuilder + constraints.maxWidth 기반 계산 |
| L4-Trace | Brief Anchor 5 (덱 선택 비주얼) | 코드 리뷰 | _DeckPreviewCard에 card_back + 대표 카드 + 카드 수 |
| L4-Trace | EV-005-S1 해결 | 코드 리뷰 | _goToReading()에 shuffleStateProvider.setResult() 호출 |

## References

| Resource | Path/URL | Related Content |
|----------|---------|-----------------|
| Brief | `docs/19_card_image_pipeline/001_Brief_card_image_pipeline.md` | Model Anchors 2-5 |
| Scope | `docs/19_card_image_pipeline/002_Scope_card_image_pipeline.md` | 영역 2 파일 목록 |
| Eval Cycle 1 | `docs/19_card_image_pipeline/005_Eval_Cycle_1.md` | EV-005-S1 부수 효과 |
| CardRevealWidget | `mobile/lib/features/reading/presentation/widgets/card_reveal_widget.dart` | 현재 텍스트 전용 |
| SpreadLayout | `mobile/lib/features/reading/presentation/widgets/spread_layout.dart` | deckId 미전달 |
| DeckSelectionPage | `mobile/lib/features/deck/presentation/pages/deck_selection_page.dart` | 현재 텍스트 ListView |
| ShufflePage | `mobile/lib/features/shuffle/presentation/pages/shuffle_page.dart` | _goToReading() 셔플 결과 미설정 |
| ReadingPage | `mobile/lib/features/reading/presentation/pages/reading_page.dart` | shuffleStateProvider watch |
| TarotCard | `mobile/lib/features/deck/domain/entities/tarot_card.dart` | imagePath 필드 |
| shuffle_providers | `mobile/lib/features/shuffle/presentation/providers/shuffle_providers.dart` | ShuffleState.setResult() |
| deck_providers | `mobile/lib/features/deck/presentation/providers/deck_providers.dart` | deckCardsProvider |

## 미비점 및 확장 필요 영역

### Plan 미비점 (makeplan 기록)
| # | 항목 | 심각도 | 설명 |
|---|------|--------|------|
| 1 | precacheImage 미적용 | Low | 현재 스프레드가 1~3장이므로 불필요하나, 10장+ 스프레드 추가 시 사전 로딩 고려 필요 |
| 2 | deckCardsProvider 전체 로드 | Low | 덱 선택에서 2장만 필요하지만 전체 카드를 로드함. 덱이 많아지면 별도 `previewCardsProvider` 고려 |

### Implementation 미비점 (implementation 기록)
| # | 항목 | 심각도 | 설명 |
|---|------|--------|------|

### Verification 미비점 (verify 기록)
| # | 항목 | 심각도 | 설명 |
|---|------|--------|------|

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
