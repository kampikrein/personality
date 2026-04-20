---
id: "027"
type: tdd-red
title: "TDD Red — SpreadLayout GridView + _EmptySlotPlaceholder 렌더링 (cycle 4)"
created: 2026-04-20
cycle: 4
traces_scope: "017"
traces_brief: "011"
status: red-confirmed
summary: >
  Cycle 4 impl (seq 15) 이전 Red 상태 고정. `spread_layout.dart` 를 단일
  `GridView.builder` 인프라로 전면 재작성하는 변경을 4 widget test 로
  고정한다. 현재 production 파일은 cycle 1 에서 삭제된 `spread_type.dart`
  를 여전히 import 하고 `SpreadType` 타입에 의존 → 컴파일 자체가 실패.
  이 compile-level 실패가 곧 red 상태. 4 테스트는 Ideal Criteria
  #9 (tShape 빈 슬롯 visible) / #10 (grid3x3 의식적 매핑) / #11/#12
  (linear 자투리 invisible) + Model Anchors § 결과 페이지 렌더링 전략
  (ValueKey(layoutType) 재생성) 을 assertion 으로 고정.
test_files:
  - mobile/test/features/reading/presentation/widgets/spread_layout_test.dart
keywords: [tdd-red, cycle-4, spread-layout, gridview, empty-slot-placeholder, layout-type, widget-test]
---

# TDD Red — SpreadLayout GridView + _EmptySlotPlaceholder 렌더링 (cycle 4)

## Brief / Scope 정렬

- **Brief**: `011_Brief_layout_redesign.md` — Decision 14 (GridView 기반
  단일 렌더링 인프라), Decision 15 (CustomPaint placeholder), Ideal
  Criteria #9/#10/#11/#12, Model Anchors § 결과 페이지 렌더링 전략
- **Scope**: `017_Scope_layout_redesign.md` — cycle 4 (결과 페이지 렌더링
  인프라)
- **Research**: `009_Research_slot_based_rendering.md` — Finding A/B/C/D/E/F
  의 prototype 코드가 impl 타겟 구조

## 대상 파일 (production, 아직 수정 금지)

- `mobile/lib/features/reading/presentation/widgets/spread_layout.dart`
  (현 107 lines, switch + `SpreadType` 분기) — cycle 4 impl (seq 15) 이
  전면 재작성

## Test Strategy

총 **4 widget tests** — 모두 `flutter_test` 의 `testWidgets` +
`tester.pumpWidget` 기반. `find.byType` / `find.byKey` /
`find.byWidgetPredicate` / `find.descendant` 로 단언.

### T1 — tShape 4장: slot 3, 5 에 visible `_EmptySlotPlaceholder`

Brief Ideal Criteria #9 고정.

- `SpreadLayout(layoutType: LayoutType.tShape, cards: _makeCards(4), ...)`
  를 `MaterialApp → Scaffold → SingleChildScrollView` 안에서 pump
- 검증:
  1. `find.byType(GridView)` → `findsOneWidget`
  2. `_EmptySlotPlaceholder` (private class → `runtimeType.toString()` 매칭)
     → `findsNWidgets(2)` (slot 3, 5)
  3. drawIdx 0~3 각각 `ValueKey('card-$draw')` 로 존재
  4. `CardRevealWidget` 총 4 개

### T2 — grid3x3 9장: 좌→우→중앙 의식적 매핑

Brief Ideal Criteria #10 고정.

- `SpreadLayout(layoutType: LayoutType.grid3x3, cards: _makeCards(9), ...)`
  pump
- 검증:
  1. `CardRevealWidget` 9 개, `_EmptySlotPlaceholder` 0 개
  2. 9 개 drawIdx (0~8) 모두 `ValueKey('card-$draw')` 로 존재
  3. Load-bearing 매핑 3 건 + 전체 9 매핑 확인:
     - draw 0 → slot 6 (좌 기둥 하단)
     - draw 2 → slot 0 (좌 기둥 상단)
     - draw 8 → slot 1 (중앙 기둥 상단)
     - 나머지 (1→3, 3→8, 4→5, 5→2, 6→7, 7→4) 도 map 단언

### T3 — linear 5장, cardsPerRow=2: 자투리 slot 5 는 `SizedBox.shrink`

Brief Ideal Criteria #12 고정.

- `SpreadLayout(layoutType: LayoutType.linear, cards: _makeCards(5),
  cardsPerRow: 2)` pump (slotCount = ceil(5/2)*2 = 6)
- 검증:
  1. `CardRevealWidget` 5 개
  2. `_EmptySlotPlaceholder` 0 개 (linear 는 visible placeholder 금지)
  3. `find.descendant(of: GridView, matching: SizedBox(width: 0,
     height: 0))` → `findsAtLeastNWidgets(1)` (자투리 slot 5)

### T4 — ValueKey(layoutType) 위젯 트리 재생성

Research 009 Finding F + Model Anchors § 렌더링 전략
(`key: ValueKey(layoutType)`) 고정.

- tShape 4장 pump → `find.byKey(ValueKey(LayoutType.tShape))` 1 개
- grid3x3 9장으로 재 pump → `find.byKey(ValueKey(LayoutType.grid3x3))`
  1 개, `ValueKey(LayoutType.tShape)` 0 개

## Fake / Helper Setup

- `_fakeTarot(int i)` — 최소 `TarotCard` (id / deckId / cardId / name /
  arcana / number / imagePath / meanings).
- `_fakeMeanings()` — 최소 `CardMeanings` (upright / reversed /
  keywords). **참고**: `keywords` 파라미터가 현 CardMeanings 실제
  스키마와 일치하지 않으면 별도 오류로 red 를 보강 (실제 스키마 확인은
  impl 단계 green 에서 조정 — cycle 4 scope 내).
- `_makeCards(int n)` — `List<ShuffledCard>.generate(n, ...)`
- `_host(...)` — `MaterialApp → Scaffold → SingleChildScrollView`
  내부에 `SpreadLayout` 배치. `cardsPerRow` 옵션, `revealedPositions:
  {}`, `onCardTap: (_) {}`
- `_emptySlotFinder` — `find.byWidgetPredicate((w) =>
  w.runtimeType.toString() == '_EmptySlotPlaceholder', ...)`

## Red State 검증

**실행**:

```bash
cd mobile && flutter test test/features/reading/presentation/widgets/spread_layout_test.dart
```

**결과 요약**: `Compilation failed` — production `spread_layout.dart`
가 cycle 1 에서 삭제된 `spread_type.dart` 를 import 하고 `SpreadType`
타입을 쓰므로 테스트 파일 자체가 컴파일 실패. 추가로 테스트가 참조하는
`layoutType` 이 현 `SpreadLayout` 생성자 파라미터에 없음 ⇒ 2 차 Red.

**Raw output (핵심 추출)**:

```
lib/features/reading/presentation/widgets/spread_layout.dart:4:8:
  Error: Error when reading
  'lib/features/reading/domain/entities/spread_type.dart':
  No such file or directory
  import '../../domain/entities/spread_type.dart';

lib/features/reading/presentation/widgets/spread_layout.dart:19:9:
  Error: Type 'SpreadType' not found.
    final SpreadType spreadType;

test/features/reading/presentation/widgets/spread_layout_test.dart:89:11:
  Error: No named parameter with the name 'layoutType'.
            layoutType: layoutType,
  lib/features/reading/presentation/widgets/spread_layout.dart:8:9:
    Context: Found this candidate, but the arguments don't match.
      const SpreadLayout({

lib/features/reading/presentation/widgets/spread_layout.dart:30:7:
  Error: Not a constant expression.
        SpreadType.single => _buildSingleLayout(),
(... threeCard, custom 동일 ...)

00:00 +0 -1: Some tests failed.
Compilation failed for testPath=... spread_layout_test.dart
```

→ Red 상태 확정. 테스트는 1개도 실행되지 못함 — compile-level failure.

## Green Target (cycle 4 impl / seq 15)

다음 3 요소가 충족되면 이 4 test 가 전부 green.

1. `spread_layout.dart` 전면 재작성:
   - `import '../../domain/entities/spread_type.dart'` 삭제 →
     `'layout_type.dart'` 로 교체
   - 생성자 파라미터 `spreadType: SpreadType` → `layoutType: LayoutType`
     (+ optional `cardsPerRow` 추가)
   - `build()` 를 단일 `GridView.builder` 로 통합 (Research 009
     Finding D 패턴 1)
   - `key: ValueKey(layoutType)` (T4)
   - itemBuilder 3-분기: `emptySlotsSet.contains(slot)` →
     `_EmptySlotPlaceholder`, `slotToDraw[slot] == null` →
     `SizedBox.shrink()`, 그 외 → `CardRevealWidget(key:
     ValueKey('card-$drawIdx'), ...)`
2. `_EmptySlotPlaceholder` + `_DashedRectPainter` private class 신설
   (spread_layout.dart 내부 또는 별도 `_empty_slot_placeholder.dart`).
   Brief Model Anchors 색/dash 스펙 적용.
3. 호출처 (draw_result_page 등) 는 cycle 6 에서 갱신 — cycle 4 범위 밖.

## Cycle Boundary

- **DO NOT** modify `spread_layout.dart` — cycle 4 impl (seq 15) 이 수행
- **DO NOT** modify `home_page.dart`, `draw_result_page.dart`,
  `animated_draw_page.dart`, `reading_list_page.dart` — cycle 5/6 범위
- **DO NOT** run `flutter analyze` 전체 — compile broken 이라 잡음 큼.
  cycle 4 impl verify 에서 일괄

## Referenced Files

| File | Role |
|------|------|
| `mobile/lib/features/reading/presentation/widgets/spread_layout.dart` | 재작성 대상 (cycle 4 impl) |
| `mobile/lib/features/reading/presentation/widgets/card_reveal_widget.dart` | 재사용 위젯, 변경 없음 |
| `mobile/lib/features/reading/domain/entities/layout_type.dart` | cycle 1 에서 완성됨, 그대로 사용 |
| `mobile/lib/features/shuffle/domain/entities/shuffle_result.dart` | `ShuffledCard` / `ShuffleResult` 구조 참조 |
| `mobile/lib/features/deck/domain/entities/tarot_card.dart` | `TarotCard` 생성자 형태 |

## Session Log (auto-appended)
