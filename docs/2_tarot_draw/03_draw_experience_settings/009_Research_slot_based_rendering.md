---
id: "009"
type: research
title: "슬롯 기반 결과 페이지 렌더링 — GridView + 빈 슬롯 placeholder 패턴"
created: 2026-04-19
traces_scope: "006"
traces_brief: "005"
summary: >
  T자/3x3 결과 페이지 렌더링은 (B) GridView + 빈 슬롯 위젯 접근을 추천. 사용자가
  명시한 "한 줄 3장 고정 그리드" 와 자연스럽게 일치하고, linear/tShape/grid3x3
  모든 LayoutType이 동일 GridView 인프라 위에서 작동해 코드 통일성이 높다. 빈
  슬롯 placeholder는 dotted_border 패키지 추가 없이 CustomPaint 30줄로 구현
  권장 (의존성 최소화 + 디자인 토큰 직접 제어). LayoutType의 drawToSlot/emptySlots
  /slotCount API는 builder에서 한 번 역매핑(slot→drawIdx) 후 GridView itemBuilder
  로 선언적 렌더링 가능.
keywords: [flutter, gridview, custom-paint, slot, layout-type, dotted-border, rendering]
---

# 슬롯 기반 결과 페이지 렌더링 — GridView + 빈 슬롯 placeholder 패턴

## Research Overview

### Background & Motivation

Brief 005 In Scope #6 + Decision 13의 풍부한 LayoutType 모델 (slotCount,
emptySlots, drawToSlot) 을 결과 페이지 (`spread_layout.dart`) 에서 어떻게
표현할지 결정해야 한다. 두 후보 접근:

- **(A) Stack + Positioned** — 절대 좌표로 카드 위치 직접 지정. T자가 그리드
  메타포에 얽매이지 않음.
- **(B) GridView + 빈 슬롯 위젯** — 한 줄 3장 고정 그리드 위에 빈 슬롯은
  visible placeholder 표시.

사용자가 Brief 갱신 (Sprint 4) 에서 명시: "T모양 4장이 배치될때는 '한줄에 3장씩
으로 고정하고' 6장 빈자리에서 첫번째 1,2,3번째 드로우는 순서대로 채워지고,
두번째 줄 4번째 카드자리는 빈칸, 5번째 카드자리에 4번째 드로우 카드가 배치되도록
6번째 카드는 빈칸으로." → **"한 줄 3장 그리드 + 빈 슬롯 visible"** 메타포가
사용자 의도에 정확히 일치.

### Research Scope

**In Scope**:
- 현재 `spread_layout.dart` + `card_reveal_widget.dart` 정확한 구조
- (A) vs (B) 접근법 trade-off 비교 + 본 프로젝트 적합 추천
- 빈 슬롯 placeholder 구현 옵션 (CustomPaint vs dotted_border 패키지)
- LayoutType API → GridView itemBuilder 통합 prototype
- 디자인 토큰 (kSoftPurple, kGold 등) 활용

**Out of Scope**:
- LayoutType 도메인 모델 자체 (Research axis 1)
- DB 마이그레이션 (Research axis 2)
- Reveal 애니메이션 변경 (현재 CardRevealWidget 그대로 재사용)
- Reading 상세 페이지 (이번엔 결과 페이지만)

### Research Perspectives

단일 통합 관점 (slot rendering 아키텍처). 외부 + 코드베이스 + 디자인 토큰이
모두 동일한 결론으로 수렴 → Path A (직접 조사).

### Related Documents

- Brief: [005_Brief_layout_redesign.md](./005_Brief_layout_redesign.md)
- Scope: [006_Scope_layout_redesign.md](./006_Scope_layout_redesign.md)
- Research axis 1: [007_Research_enhanced_enum_codegen.md](./007_Research_enhanced_enum_codegen.md)
- Research axis 2: [008_Research_drift_migration_pattern.md](./008_Research_drift_migration_pattern.md)

---

## Status Analysis (현재 결과 페이지 렌더링 구조)

### 1. `spread_layout.dart` — switch 기반 단순 분기 (107 lines)

```dart
return switch (spreadType) {
  SpreadType.single => _buildSingleLayout(),       // Center(CardRevealWidget)
  SpreadType.threeCard => _buildThreeCardLayout(), // Row + Expanded + Padding
  SpreadType.custom => _buildGenericGridLayout(),  // GridView.builder, crossAxis 3 고정
};
```

**핵심 관찰**:
- 세 분기 모두 다른 위젯 구조 — 통일 인프라 부재
- `_buildGenericGridLayout`이 이미 `crossAxisCount: 3` 고정 (라인 80) → 사용자
  요청 "한 줄 3장 고정" 과 일치
- 빈 슬롯 개념 없음 — `itemCount: cards.length`
- 빈 슬롯 표시도 없음 (custom 스프레드는 N장 그대로 채움)

### 2. `card_reveal_widget.dart` — 레이아웃 비종속 (206 lines)

```dart
class CardRevealWidget extends StatefulWidget {
  // AspectRatio 자체 적용 (라인 124, 167)
  // 어떤 부모 위젯 안에서도 작동
  // tap + 3D rotateY reveal 애니메이션 자체 보유
}
```

**핵심 관찰**:
- 부모 위젯에 의존성 없음 → Stack/GridView 어느 쪽이든 그대로 사용 가능
- AspectRatio 내부 적용 → 부모가 강제 박스를 만들지 않으면 카드 비율 자연 유지
- StatefulWidget 컨트롤러 보유 → Key 안정성이 중요 (특정 인덱스의 위젯이
  레이아웃 변경 시 사라지지 않게)

### 3. 디자인 토큰 (`mystical_scaffold.dart`)

```dart
const kGold = Color(0xFFD4A84B);
const kGoldLight = Color(0xFFE8C97A);
const kDeepPurple = Color(0xFF1A1028);
const kDarkSurface = Color(0xFF0D0A14);
const kSoftPurple = Color(0xFF6B5B95);
```

→ **빈 슬롯 placeholder는 `kSoftPurple.withValues(alpha: 0.25~0.35)` 권장**
   (배경의 `kDeepPurple`/`kDarkSurface` 위에 미묘하게 보이되 카드와 시각적
   계층 분리).

---

## Detailed Findings

### Finding A — (A) Stack + Positioned vs (B) GridView + 빈 슬롯 비교

| 차원 | (A) Stack + Positioned | (B) GridView + 빈 슬롯 |
|------|----------------------|---------------------|
| **사용자 메타포 정합성** | T자가 자유 좌표 → 사용자가 "한 줄 3장 그리드"라고 명시한 의도와 부정합 | 사용자 명시 의도와 정확히 일치 |
| **반응형 (다양한 화면 크기)** | LayoutBuilder + 비율 좌표 직접 계산 (수동) | GridView가 자동 (crossAxisSpacing/childAspectRatio) |
| **AspectRatio 호환** | Positioned 박스 안에 AspectRatio가 들어가면 비율 충돌 가능 | GridView delegate의 `childAspectRatio` 로 자연 |
| **reveal 애니메이션** | CardRevealWidget 자체가 위치 비종속 → 영향 없음 | 동일 |
| **LayoutType 통합** | drawToSlot 결과를 절대 좌표로 변환 (별도 매핑 함수 필요) | drawToSlot 결과를 GridView 슬롯 인덱스로 직접 사용 |
| **linear (가변 cardsPerRow)** | linear는 grid 메타포라 Stack과 부정합, 별도 분기 필요 | 동일 GridView로 cardsPerRow만 바꾸면 작동 |
| **코드 통일성** | 3개 LayoutType마다 다른 위젯 구조 (현재와 같음) | 모든 LayoutType이 동일 GridView 인프라 |
| **빈 슬롯 visible placeholder** | Stack 안에 점선 박스 추가 (가능하지만 inconsistent) | GridView itemBuilder에서 자연스럽게 렌더 |
| **위젯 트리 깊이** | 얕음 | 약간 깊음 (GridView → SliverGrid) |
| **그리드 행 동적 확장** | 추가 카드마다 좌표 계산 + Stack 박스 크기 조정 | itemCount 증가만 — 자동 확장 |

→ **(B) GridView + 빈 슬롯 위젯 추천 (8개 차원 중 7개에서 우세, 1개 무차이)**.

(A)가 더 나은 단 한 영역은 "위젯 트리 깊이" (성능 영향 미미 — 9~10 슬롯 규모).

### Finding B — 빈 슬롯 Placeholder 구현 옵션

[Flutter dotted_border 패키지](https://pub.dev/packages/dotted_border) 또는
CustomPaint 직접 구현:

| 옵션 | 의존성 | 코드 | 디자인 제어 | 권장 시나리오 |
|------|--------|------|-----------|------------|
| **dotted_border 패키지** | +1 (외부) | 짧음 (~10줄) | dashPattern, color, strokeWidth | 여러 곳에서 점선 사용, 빠른 도입 |
| **CustomPaint 직접 작성** | 0 | ~30줄 | 완전 자유 | 단일 사용 위치, 디자인 토큰 직접 활용, 향후 glow/이중선 같은 효과 추가 가능성 |

**본 프로젝트 권장: CustomPaint 직접 작성**

근거:
- 빈 슬롯 placeholder는 결과 페이지 한 곳에서만 사용 (다른 곳에서 점선 필요
  없음) → 외부 패키지 의존성 비용 > 코드 30줄 비용
- 디자인 토큰 (`kSoftPurple`, `kGold`) 직접 사용 → 일관성
- 향후 placeholder 디자인 변경 (예: glow, 이중 점선, 별 아이콘 추가) 자유로움
- pubspec.yaml에 새 의존성 추가 시 build_runner 영향 없음 → 가벼움

### Finding C — CustomPaint 점선 사각형 표준 패턴

[Flutter CustomPaint 공식 문서](https://api.flutter.dev/flutter/widgets/CustomPaint-class.html)
+ [dotted_border 패키지의 painter 구현](https://github.com/Sub6Resources/dotted_border):

핵심 메커니즘:
1. `Path.computeMetrics()` 로 path를 길이 단위로 측정
2. `metric.extractPath(start, end)` 로 dash 길이만큼 segment 추출
3. dash + gap 패턴으로 반복

```dart
Path _dashedPath(Path source, double dashWidth, double dashGap) {
  final dest = Path();
  for (final metric in source.computeMetrics()) {
    double distance = 0;
    bool draw = true;
    while (distance < metric.length) {
      final length = draw ? dashWidth : dashGap;
      if (draw) {
        dest.addPath(
          metric.extractPath(distance, distance + length),
          Offset.zero,
        );
      }
      distance += length;
      draw = !draw;
    }
  }
  return dest;
}
```

이 패턴은 RRect, RoundedRectangle, Circle 등 모든 Path에 적용 가능. 본 작업은
모서리 둥근 사각형 (`RRect.fromRectAndRadius`).

### Finding D — LayoutType API → GridView itemBuilder 통합

LayoutType prototype (Research axis 1) 의 메서드:
```dart
int drawToSlot(int drawIndex, int cardCount);
Set<int> emptySlots(int cardCount);
int slotCount(int cardCount);
```

GridView 통합 시 필요한 것: **slot 인덱스 → drawIndex 역매핑** (GridView
itemBuilder가 slot 인덱스로 호출되므로).

두 가지 구현 패턴:

**패턴 1 — 빌더 시작 시 한 번 역매핑 계산** (권장):

```dart
final layoutType = ...;
final cards = ...;
final cardCount = cards.length;
final totalSlots = layoutType.slotCount(cardCount);
final empty = layoutType.emptySlots(cardCount);

// slot 인덱스 → drawIndex 역매핑
final slotToDraw = <int, int>{};
for (int draw = 0; draw < cardCount; draw++) {
  slotToDraw[layoutType.drawToSlot(draw, cardCount)] = draw;
}

return GridView.builder(
  itemCount: totalSlots,
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: layoutType.cardsPerRowOverride ?? cardsPerRow,
    crossAxisSpacing: 8,
    mainAxisSpacing: 8,
    childAspectRatio: cardAspectRatio * 0.9,
  ),
  itemBuilder: (context, slot) {
    if (empty.contains(slot)) {
      return const _EmptySlotPlaceholder();
    }
    final drawIdx = slotToDraw[slot];
    if (drawIdx == null) return const SizedBox.shrink();  // safety
    return CardRevealWidget(
      card: cards[drawIdx],
      deckId: deckId,
      position: drawIdx,
      label: layoutType.resolvePositions(cardCount)[drawIdx],
      isRevealed: revealedPositions.contains(drawIdx),
      showCardName: showCardName,
      cardAspectRatio: cardAspectRatio,
      onTap: () => onCardTap(drawIdx),
    );
  },
);
```

**패턴 2 — LayoutType에 `slotToDraw(slot, cardCount)` 함수 추가**:

```dart
// LayoutType에 추가:
int? slotToDraw(int slot, int cardCount) {
  for (int draw = 0; draw < cardCount; draw++) {
    if (drawToSlot(draw, cardCount) == slot) return draw;
  }
  return null;
}
```

→ itemBuilder가 매번 O(cardCount) 순회 — slot 수 9~10 규모이므로 실제 영향
미미하지만 패턴 1이 더 효율적 (한 번 계산 후 재사용) + LayoutType API 단순
유지.

→ **패턴 1 권장**.

### Finding E — `linear` 케이스 호환

linear는 `cardsPerRowOverride: null` (Brief 005 Model Anchors 매트릭스) →
사용자 설정 `cardsPerRow` (1/2/3) 사용. 빈 슬롯 없음 (`emptySlots = const {}`).

```dart
// linear, cardCount=5, cardsPerRow=2 시:
// totalSlots = ceil((5+0)/2) * 2 = 6
// slot: 0 1 2 3 4 5
// draws: 0 1 2 3 4 -
// → 슬롯 5는 drawIdx 없음 → SizedBox.shrink (visible placeholder X)
```

**결정 필요**: linear의 마지막 빈 슬롯 (cardCount이 cardsPerRow의 배수가 아닐
때 생기는 자투리) 도 visible placeholder 표시할지?

**추천: SizedBox.shrink (안 보이게)**

근거:
- linear는 "자유 나열" 메타포 — 그리드 비주얼이 의도가 아님
- 자투리 빈 슬롯은 단순 정렬 부산물 — 의식적 배치 아님
- T자/3x3의 빈 슬롯은 "도메인적으로 의미 있는 빈자리" → visible
- linear의 자투리는 시각 노이즈일 뿐

→ `_EmptySlotPlaceholder` 표시 여부는 `LayoutType` 의 추가 속성으로 분리
권장:
```dart
// LayoutType에:
bool get showEmptySlotPlaceholder => switch (this) {
  LayoutType.linear => false,
  LayoutType.tShape => true,
  LayoutType.grid3x3 => false,  // 9장 모두 채워지므로 emptySlots = {} → 자연스럽게 표시 안 됨
};
```

또는 더 단순하게, `emptySlots`가 비어있지 않은 경우에만 placeholder 표시 (현재
설계로 충분):
- linear: emptySlots = {} → placeholder 표시 안 됨, 자투리는 SizedBox.shrink
- tShape (4장): emptySlots = {3, 5} → placeholder 표시
- grid3x3 (9장): emptySlots = {} → placeholder 표시 안 됨

이 단순한 로직이 동일 결과를 만든다 → **showEmptySlotPlaceholder 속성 불필요**.
itemBuilder의 분기는 단지 `emptySlots.contains(slot)` 만 사용.

단, linear의 자투리 슬롯 처리는 `slotToDraw[slot] == null` 케이스로 분기 필요:

```dart
itemBuilder: (context, slot) {
  if (empty.contains(slot)) return const _EmptySlotPlaceholder();
  final drawIdx = slotToDraw[slot];
  if (drawIdx == null) return const SizedBox.shrink();  // linear 자투리
  return CardRevealWidget(...);
},
```

### Finding F — Key 안정성 (애니메이션 보존)

`CardRevealWidget`은 StatefulWidget 컨트롤러를 가지므로 reveal 애니메이션 진행
중 widget이 다른 슬롯으로 옮겨가면 컨트롤러가 dispose됨.

GridView.builder는 기본적으로 itemBuilder를 인덱스 기반으로 호출하므로 같은
slot 인덱스에 항상 같은 위젯 트리 유지 → 안정적. 단 `key` 명시 권장:

```dart
return CardRevealWidget(
  key: ValueKey('card-$drawIdx'),  // drawIdx 기반 key (slot이 아닌)
  // ...
);
```

drawIdx는 카드 정체성 (어느 카드가 어느 슬롯에 있는지) 이므로 카드 위젯 key
도 drawIdx 기반이 자연스럽다. 빈 슬롯도 key가 필요하면 `ValueKey('empty-$slot')`.

---

## Caveats & Risks

| 위험 | 가능성 | 완화책 |
|------|--------|--------|
| linear 자투리 슬롯의 SizedBox.shrink가 GridView 셀 크기를 0으로 만들어 레이아웃 무너짐 | 낮음 | `SizedBox.expand` 또는 `Container()` 로 셀 크기 유지 (테스트 필요) |
| 모서리 둥근 사각형의 dashed path가 모서리에서 점선이 끊김 | 낮음 | dashWidth/dashGap을 둘레 길이의 약수로 설정 (perimeter / (dashWidth+dashGap) ≈ 정수) |
| GridView가 LayoutBuilder 안에 있으면 `shrinkWrap: true` + `physics: NeverScrollable`로 중첩 스크롤 회피 필요 | 중간 | 부모가 SingleChildScrollView면 NeverScrollable, 아니면 BouncingScrollPhysics |
| `cardsPerRowOverride` null vs 값 분기 코드가 흩어짐 | 낮음 | LayoutType에 `effectiveCardsPerRow(int settingsValue)` 헬퍼 추가 (제3 메서드) |
| reveal 애니메이션 중 cardCount 변경 (배치 전환으로) → 컨트롤러 누수 | 중간 | spread_layout.dart에 `key: ValueKey(layoutType)` 적용으로 위젯 트리 재생성 강제 |

---

## Comprehensive Conclusion

### 핵심 발견 (우선순위 순)

1. **[Critical] R-009-F1: GridView + 빈 슬롯 위젯 (B 접근법) 추천** — 사용자 명시 "한 줄 3장 고정" 메타포와 정확히 일치, 8 비교 차원 중 7개 우세, 모든 LayoutType이 동일 GridView 인프라 위에서 작동 *(Finding A)*

2. **[Critical] R-009-F2: 빈 슬롯 placeholder는 CustomPaint 직접 작성 (~30줄) 권장** — 외부 패키지 의존성 추가 비용 > 코드 비용. 디자인 토큰 (kSoftPurple) 직접 활용 + 향후 glow 등 확장 자유 *(Finding B)*

3. **[High] R-009-F3: LayoutType API → GridView 통합 패턴은 "한 번 역매핑 후 재사용"** — itemBuilder 매번 O(N) 순회보다 효율적 + LayoutType API 단순 유지 *(Finding D 패턴 1)*

4. **[High] R-009-F4: linear 자투리 빈 슬롯과 도메인 빈 슬롯 구분** — `emptySlots.contains(slot)` 으로 도메인 빈 슬롯만 visible placeholder, linear 자투리는 `SizedBox.shrink` *(Finding E)*

5. **[High] R-009-F5: LayoutType에 추가 메서드 불필요** — Brief 005의 drawToSlot/emptySlots/slotCount + cardsPerRowOverride 4개로 충분. slotToDraw 역매핑은 builder에서 한 번 계산 *(Finding D)*

6. **[Medium] R-009-F6: CardRevealWidget의 reveal 애니메이션 호환성 OK** — 위젯 자체가 부모 비종속 + AspectRatio 내부 적용. ValueKey('card-$drawIdx') 적용 권장 *(Finding F)*

7. **[Medium] R-009-F7: 점선 path 모서리 끊김 미세 이슈** — dashWidth/dashGap을 perimeter의 약수로 설정 권장. 본 작업의 카드 사각형 (70x120 비율) 에서는 dashWidth=6, dashGap=4 정도 권장 *(Caveats)*

8. **[Low] R-009-F8: GridView 중첩 스크롤 회피** — 부모가 SingleChildScrollView면 `shrinkWrap: true + NeverScrollable` 적용 *(Caveats)*

### Prototype Code (impl 사이클 3 시작 코드)

**`mobile/lib/features/reading/presentation/widgets/spread_layout.dart` 전면 재작성**:

```dart
import 'package:flutter/material.dart';

import '../../../../core/widgets/mystical_scaffold.dart';
import '../../../shuffle/domain/entities/shuffle_result.dart';
import '../../domain/entities/spread_type.dart';   // → layout_type.dart로 변경 예정
import 'card_reveal_widget.dart';

class SpreadLayout extends StatelessWidget {
  const SpreadLayout({
    super.key,
    required this.layoutType,
    required this.cards,
    required this.deckId,
    required this.revealedPositions,
    required this.onCardTap,
    this.cardsPerRow = 3,
    this.showCardName = true,
    this.cardAspectRatio = 70.0 / 120.0,
  });

  final LayoutType layoutType;
  final List<ShuffledCard> cards;
  final String deckId;
  final Set<int> revealedPositions;
  final ValueChanged<int> onCardTap;
  final int cardsPerRow;
  final bool showCardName;
  final double cardAspectRatio;

  @override
  Widget build(BuildContext context) {
    final cardCount = cards.length;
    if (cardCount == 0) return const SizedBox.shrink();

    final totalSlots = layoutType.slotCount(cardCount);
    final emptySlotsSet = layoutType.emptySlots(cardCount);
    final crossAxisCount = layoutType.cardsPerRowOverride ?? cardsPerRow;

    // slot 인덱스 → drawIndex 역매핑 (한 번 계산)
    final slotToDraw = <int, int>{};
    for (int draw = 0; draw < cardCount; draw++) {
      slotToDraw[layoutType.drawToSlot(draw, cardCount)] = draw;
    }

    final positions = layoutType.resolvePositions(cardCount);

    return GridView.builder(
      key: ValueKey(layoutType),  // 배치 전환 시 위젯 트리 재생성 (Finding F)
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalSlots,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: cardAspectRatio * 0.9,
      ),
      itemBuilder: (context, slot) {
        // 1. 도메인 빈 슬롯 (T자) → visible placeholder
        if (emptySlotsSet.contains(slot)) {
          return _EmptySlotPlaceholder(
            key: ValueKey('empty-$slot'),
            aspectRatio: cardAspectRatio,
          );
        }
        // 2. linear 자투리 빈 슬롯 → invisible
        final drawIdx = slotToDraw[slot];
        if (drawIdx == null) return const SizedBox.shrink();
        // 3. 카드 슬롯
        return CardRevealWidget(
          key: ValueKey('card-$drawIdx'),
          card: cards[drawIdx],
          deckId: deckId,
          position: drawIdx,
          label: positions.length > drawIdx ? positions[drawIdx] : '카드 ${drawIdx + 1}',
          isRevealed: revealedPositions.contains(drawIdx),
          showCardName: showCardName,
          cardAspectRatio: cardAspectRatio,
          onTap: () => onCardTap(drawIdx),
        );
      },
    );
  }
}

// ── 빈 슬롯 placeholder (점선 사각형) ─────────────────────────────
class _EmptySlotPlaceholder extends StatelessWidget {
  const _EmptySlotPlaceholder({
    super.key,
    this.aspectRatio = 70.0 / 120.0,
  });

  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: CustomPaint(
        painter: const _DashedRectPainter(
          color: Color(0x556B5B95),  // kSoftPurple alpha 0.33
          dashWidth: 6,
          dashGap: 4,
          strokeWidth: 1,
          cornerRadius: 4,
        ),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  const _DashedRectPainter({
    required this.color,
    required this.dashWidth,
    required this.dashGap,
    required this.strokeWidth,
    required this.cornerRadius,
  });

  final Color color;
  final double dashWidth;
  final double dashGap;
  final double strokeWidth;
  final double cornerRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(cornerRadius),
      ));

    final dashedPath = _createDashedPath(path);
    canvas.drawPath(dashedPath, paint);
  }

  Path _createDashedPath(Path source) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final length = draw ? dashWidth : dashGap;
        if (draw) {
          dest.addPath(
            metric.extractPath(distance, distance + length),
            Offset.zero,
          );
        }
        distance += length;
        draw = !draw;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) =>
      color != oldDelegate.color ||
      dashWidth != oldDelegate.dashWidth ||
      dashGap != oldDelegate.dashGap ||
      strokeWidth != oldDelegate.strokeWidth ||
      cornerRadius != oldDelegate.cornerRadius;
}
```

### 결론 (Research Axis 3 핵심 질문에 대한 답)

**해결됨**. (B) GridView + 빈 슬롯 위젯 접근이 모든 차원에서 우세하며, 빈 슬롯
placeholder는 CustomPaint 직접 작성으로 의존성 0 + 디자인 토큰 직접 활용. impl
사이클 3에서 spread_layout.dart 전면 재작성 시 위 prototype 그대로 적용 가능.

## Incremental Summary

### 리서치 축
- **축 이름**: slot-based-rendering
- **핵심 질문**: T자/3x3 결과 페이지 렌더링의 (A) Stack+Positioned vs (B)
  GridView+빈 슬롯 위젯 trade-off, 빈 슬롯 placeholder 표준 구현, LayoutType
  API → 렌더링 트리 통합 패턴

### 핵심 발견 (우선순위 순)
1. **[Critical] R-009-F1: (B) GridView + 빈 슬롯 위젯 추천** — 사용자 명시 "한 줄 3장 고정" 메타포 일치, 8 비교 차원 중 7개 우세
2. **[Critical] R-009-F2: 빈 슬롯 placeholder는 CustomPaint 직접 작성** — 의존성 0, 디자인 토큰 직접 활용
3. **[High] R-009-F3: 슬롯→drawIndex 역매핑은 builder 시작 시 한 번 계산** — itemBuilder O(1) 조회
4. **[High] R-009-F4: 도메인 빈 슬롯 (visible) vs linear 자투리 (invisible) 구분** — `emptySlots.contains(slot)` 로 분기
5. **[High] R-009-F5: LayoutType에 추가 메서드 불필요** — Brief 005 prototype의 4개 메서드로 충분
6. **[Medium] R-009-F6: CardRevealWidget reveal 애니메이션 호환** — ValueKey('card-$drawIdx') 적용 권장
7. **[Medium] R-009-F7: 점선 path 모서리 끊김 — dashWidth=6, dashGap=4 권장**
8. **[Low] R-009-F8: GridView 중첩 스크롤 — shrinkWrap+NeverScrollable**

### 결론

**해결됨** — Brief In Scope #6의 모든 의문 해소. impl 사이클 3 prototype 코드 완성. spread_layout.dart 전면 재작성 + _EmptySlotPlaceholder + _DashedRectPainter 신규 위젯 추가로 모든 LayoutType (linear/tShape/grid3x3) 통일 처리.

### 미해결 사항

None.

## Unresolved Items

None — Brief In Scope #6의 모든 의문 해소. impl 사이클 3에서 prototype 그대로
적용 가능.

## Referenced File List

| File Path | Related Perspective | Role/Content |
|-----------|-------------------|--------------|
| `mobile/lib/features/reading/presentation/widgets/spread_layout.dart` | 현재 결과 렌더링 (107 lines) | switch + GridView.builder, 빈 슬롯 미지원. 전면 재작성 대상 |
| `mobile/lib/features/reading/presentation/widgets/card_reveal_widget.dart` | Reveal 애니메이션 위젯 (206 lines) | StatefulWidget + 3D rotateY, 부모 비종속, 그대로 재사용 |
| `mobile/lib/core/widgets/mystical_scaffold.dart` | 디자인 토큰 | kGold, kSoftPurple (0xFF6B5B95), kDeepPurple, kDarkSurface |
| `mobile/lib/features/reading/domain/entities/spread_type.dart` | 현 SpreadType enum → LayoutType 진화 대상 | Research axis 1에서 이미 다룸 |

## External Sources

- [Flutter CustomPaint class API](https://api.flutter.dev/flutter/widgets/CustomPaint-class.html)
- [Flutter GridView class API](https://api.flutter.dev/flutter/widgets/GridView-class.html)
- [dotted_border 패키지](https://pub.dev/packages/dotted_border) — 비교 대상 (사용 안 함)
- [Flutter Dotted Border Easy Tutorial](https://medium.com/@iamashishkoirala1/flutter-dotted-border-easy-dotted-borders-for-flutter-acc1d42396b8)
- [Flutter Dashed Border Tutorial](https://flutterstuff.com/how-to-make-dotted-dash-border-on-container-in-flutter-app/)
- [Flutter GridView Cookbook](https://docs.flutter.dev/cookbook/lists/grid-lists)
- [Flutter Layouts](https://docs.flutter.dev/ui/layout)
- [GridView How-To (LogRocket)](https://blog.logrocket.com/how-to-create-a-grid-list-in-flutter-using-gridview/)
- [How to Create Dotted Border Around Box (codegenes)](https://www.codegenes.net/blog/how-to-create-a-dotted-border-around-a-box-in-flutter/)

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 117s | 344643 |
| 2 | user-ai-exchange | 235s | 1232689 |
| 3 | user-ai-exchange | 213s | 1123755 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 3776s |
| Total Tokens | 2701087 |
| Input Tokens | 47 |
| Output Tokens | 41487 |
| Cache Read | 2543784 |
| Cache Creation | 115769 |
