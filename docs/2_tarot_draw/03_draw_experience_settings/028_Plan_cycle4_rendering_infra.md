---
id: "028"
type: plan
title: "Plan — cycle 4 SpreadLayout 렌더링 인프라 재작성"
created: 2026-04-20
cycle: 4
traces_scope: "017"
traces_tdd_red: "027"
traces_brief: "011"
traces_research: "009"
status: ready
summary: >
  cycle 4 impl (seq 15) 계획. `spread_layout.dart` 의 기존 switch 분기
  (single / threeCard / custom 3 내부 빌더) 를 단일 `GridView.builder`
  + 슬롯 기반 선언형 렌더링으로 전면 재작성한다. 생성자 파라미터를
  `spreadType: SpreadType` 에서 `layoutType: LayoutType` 로 교체하고
  (+ optional `cardsPerRow: int = 3`), `key: ValueKey(layoutType)` 를
  외곽 GridView 에 부착해 배치 전환 시 위젯 트리를 재생성한다.
  itemBuilder 는 3-branch: 도메인 `emptySlots` → `_EmptySlotPlaceholder`,
  `slotToDraw[slot] == null` (linear 자투리) → `SizedBox.shrink`, 그 외
  → `CardRevealWidget(key: ValueKey('card-$drawIdx'), ...)`. 009
  prototype 코드 ~95% 를 그대로 채택한다. 27 의 4 widget test 를 green
  으로 만들고 기 통과한 31 건 regression 영향 없음. 호출처
  `draw_result_page.dart` 1 곳 (line 229~) 은 cycle 6 범위로 남긴다.
keywords: [cycle-4, plan, spread-layout, gridview, empty-slot-placeholder, dashed-rect-painter, layout-type, impl]
---

# Plan — cycle 4 SpreadLayout 렌더링 인프라 재작성

## 1. Goal

현 `spread_layout.dart` (107 lines) 의 switch-dispatch 세 분기
(`_buildSingleLayout`, `_buildThreeCardLayout`, `_buildGenericGridLayout`)
를 제거하고, `LayoutType` 의 `drawToSlot / emptySlots / slotCount /
cardsPerRowOverride / resolvePositions` API 만으로 layout 을 추론하는
단일 `GridView.builder` 로 통일한다. Brief 011 Decision 14 (GridView
단일 인프라) + Decision 15 (CustomPaint placeholder) + Model Anchors §
결과 페이지 렌더링 전략 을 코드로 고정한다. 이로써 027 TDD Red 의 4
widget test (T1~T4) 가 전부 green 이 되고 Ideal Criteria #9 (tShape
4장 빈 슬롯 visible) / #10 (grid3x3 의식적 매핑) / #11 (tShape 확장
매핑) / #12 (linear 자투리 invisible) 가 구현 수준에서 충족된다.
호출처 갱신은 cycle 5/6 에 위임한다 (cycle 4 는 위젯 인프라만).

## 2. File changes

### Modified (1 file, 전면 재작성)

**`mobile/lib/features/reading/presentation/widgets/spread_layout.dart`**
— 107 lines → ~170 lines. 009 Finding D 패턴 1 prototype 을 채택.

변경 요점:

- Import:
  - 삭제: `import '../../domain/entities/spread_type.dart';`
  - 추가: `import '../../domain/entities/layout_type.dart';`
  - 유지: `flutter/material.dart`, `shuffle_result.dart`, `card_reveal_widget.dart`
- 생성자 파라미터:
  - 제거: `required this.spreadType` (+ field `final SpreadType spreadType;`)
  - 추가: `required this.layoutType` (+ field `final LayoutType layoutType;`)
  - 추가: `this.cardsPerRow = 3` (+ field `final int cardsPerRow;`) —
    linear 에서 사용자 설정 전달용. Brief Model Anchors § 결과 페이지
    렌더링 전략의 `layoutType.cardsPerRowOverride ?? cardsPerRow` 계산에
    필요.
  - 유지: `cards`, `deckId`, `revealedPositions`, `onCardTap`, `showCardName`,
    `cardAspectRatio`
- `build()` 단일 `GridView.builder` 로 통합:
  - `if (cardCount == 0) return const SizedBox.shrink();` 안전 가드
  - 사전 계산 4 변수: `cardCount`, `totalSlots = layoutType.slotCount(cardCount)`,
    `emptySlotsSet = layoutType.emptySlots(cardCount)`, `crossAxisCount =
    layoutType.cardsPerRowOverride ?? cardsPerRow`
  - `slotToDraw` 역매핑 1회 계산: `Map<int,int>` — `for (draw in 0..cardCount)
    slotToDraw[layoutType.drawToSlot(draw, cardCount)] = draw;` (Research
    009 Finding D 패턴 1 — itemBuilder O(1) 조회 보장)
  - `positions = layoutType.resolvePositions(cardCount)` — CardRevealWidget
    label 주입용
  - `GridView.builder`:
    - `key: ValueKey(layoutType)` — 배치 전환 시 트리 재생성 (T4 + Research
      009 Finding F + Caveats R5)
    - `shrinkWrap: true, physics: const NeverScrollableScrollPhysics()`
      — 호출처 `draw_result_page.dart` 가 `Expanded` 내부에 두고 있으나
      TDD test host 가 `SingleChildScrollView` 안에서 pump 하므로 중첩
      스크롤 회피 필요 (Research 009 Caveats R3)
    - `itemCount: totalSlots`
    - `gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount, crossAxisSpacing: 8,
      mainAxisSpacing: 8, childAspectRatio: cardAspectRatio * 0.9)`
    - `itemBuilder: (context, slot) { ... }` — 3-branch:
      1. `emptySlotsSet.contains(slot)` → `return _EmptySlotPlaceholder(
         key: ValueKey('empty-$slot'), aspectRatio: cardAspectRatio);`
      2. `final drawIdx = slotToDraw[slot]; if (drawIdx == null) return
         const SizedBox.shrink();` (linear 자투리)
      3. 그 외 → `return CardRevealWidget(key: ValueKey('card-$drawIdx'),
         card: cards[drawIdx], deckId: deckId, position: drawIdx,
         label: positions.length > drawIdx ? positions[drawIdx] : '카드
         ${drawIdx+1}', isRevealed: revealedPositions.contains(drawIdx),
         showCardName: showCardName, cardAspectRatio: cardAspectRatio,
         onTap: () => onCardTap(drawIdx));`
- 파일 내 같은 레벨에 private class 2개 신규:
  - `class _EmptySlotPlaceholder extends StatelessWidget` — `AspectRatio`
    감싼 `CustomPaint(painter: _DashedRectPainter(color: Color(0x556B5B95),
    dashWidth: 6, dashGap: 4, strokeWidth: 1, cornerRadius: 4))`. Brief
    011 Decision 15 디자인 스펙 정확히 반영.
  - `class _DashedRectPainter extends CustomPainter` — `RRect.fromRectAndRadius
    (Offset.zero & size, Radius.circular(cornerRadius))` path 를
    `Path.computeMetrics()` + `metric.extractPath(distance, distance +
    length)` dash/gap 반복으로 점선 변환. `shouldRepaint` 는 5개 필드 비교.
- 기존 `_buildSingleLayout / _buildThreeCardLayout / _buildGenericGridLayout`
  private 메서드 전부 제거 (dead code).

### No changes (cycle 4 경계 내)

- `mobile/lib/features/reading/presentation/widgets/card_reveal_widget.dart`
  — R-009-F6 부모 비종속. 생성자 파라미터 signature 이미 확인
  (§ 3. Call-site impact scan 하단 참고).
- `mobile/lib/features/reading/domain/entities/layout_type.dart`
  — cycle 1 에서 완성. API 5개 (`drawToSlot`, `emptySlots`, `slotCount`,
  `cardsPerRowOverride`, `resolvePositions`) 그대로 사용. 추가 메서드
  불필요 (R-009-F5).
- `mobile/lib/core/widgets/mystical_scaffold.dart` — 디자인 토큰
  (`kSoftPurple = 0xFF6B5B95`) 은 참고만 하고 `_EmptySlotPlaceholder`
  내부에 `Color(0x556B5B95)` (alpha 0.33) 리터럴로 고정. Brief 011 의
  정확한 스펙을 코드에 각인.

### Not created

- 별도 파일 분리 (`_empty_slot_placeholder.dart`) 안 함. Research 009
  prototype 이 inline 을 전제로 작성됐고, 027 TDD 도 `runtimeType.toString()
  == '_EmptySlotPlaceholder'` 로 private class 를 그대로 매칭하도록 설계됨.
  파일 분리 시 private class 접근성이 오히려 복잡해짐.

## 3. Test → code mapping

027 의 4 widget test 가 각각 구현 요소에 1:1 연결된다.

| Test | Assertion | 구현 매칭 |
|------|-----------|-----------|
| **T1** — tShape 4장 빈 슬롯 placeholder (#9) | `find.byType(GridView) == 1`, `_EmptySlotPlaceholder == 2` (slot 3, 5), `ValueKey('card-$draw')` (0~3), `CardRevealWidget == 4` | `LayoutType.tShape.emptySlots(4) == {3, 5}` + itemBuilder 분기 1 → `_EmptySlotPlaceholder(key: ValueKey('empty-$slot'))` 2개 + 분기 3 → `CardRevealWidget(key: ValueKey('card-$drawIdx'))` 4개 |
| **T2** — grid3x3 9장 의식적 매핑 (#10) | `CardRevealWidget == 9`, `_EmptySlotPlaceholder == 0`, drawIdx 0~8 모두 key 존재, 9 매핑 정확 (0→6, 2→0, 8→1, 1→3, 3→8, 4→5, 5→2, 6→7, 7→4) | `LayoutType.grid3x3.drawToSlot` 구현이 이미 009 Research 에서 좌→우→중앙 의식적 패턴으로 고정됨. 본 cycle 4 는 그 매핑을 itemBuilder 의 `slotToDraw` 역매핑으로 그대로 투영 |
| **T3** — linear 5장 cardsPerRow=2 자투리 invisible (#12) | `CardRevealWidget == 5`, `_EmptySlotPlaceholder == 0`, `find.descendant(of: GridView, matching: SizedBox(width: 0, height: 0)).findsAtLeastNWidgets(1)` | linear 의 `emptySlots(5) == {}` → 분기 1 미발동. `slotCount(5) = ceil((5+0)/2)*2 = 6` → slot 5 는 `slotToDraw[5] == null` → 분기 2 `SizedBox.shrink` (width=height=0) |
| **T4** — ValueKey(layoutType) 트리 재생성 | 초기 pump (tShape 4장) → `find.byKey(ValueKey(LayoutType.tShape)).findsOneWidget`; 재 pump (grid3x3 9장) → `tShape` 0 개, `grid3x3` 1 개 | 외곽 `GridView.builder(key: ValueKey(layoutType), ...)` |

모든 분기가 test 1 개 이상에 대응하며, 잉여 코드 없음.

## 4. Call-site impact scan

`SpreadLayout(` grep 결과 (cycle 4 작업 직전):

| 파일 | 라인 | 현 사용 | cycle 4 영향 |
|------|------|---------|--------------|
| `mobile/lib/features/draw/presentation/pages/draw_result_page.dart` | 229 | `SpreadLayout(spreadType: _spreadType, cards: drawnCards, deckId: _deckId, ...)` | **호환 깨짐 (예상됨)** — 생성자 파라미터 변경. **cycle 4 에서 건드리지 않음** (cycle 경계). cycle 6 impl 에서 `_spreadType` → `_layoutType` 필드 전환과 함께 호출부 업데이트. 그 동안 이 파일은 compile error 상태로 유지됨. |

cycle 4 범위 내 다른 호출처 없음 (grep 확인 완료). TDD test 파일
`test/features/reading/presentation/widgets/spread_layout_test.dart`
는 새 `layoutType:` 파라미터를 전제로 이미 작성되어 있어 green 전환
즉시 가능.

**중요**: cycle 4 impl 후 `draw_result_page.dart` compile error 는
의도된 cycle boundary. verify 단계에서 `spread_layout_test.dart` 단일
파일 테스트만 실행하고, `flutter analyze` 전체는 실행하지 않는다 (cycle
5/6 범위 파일이 broken 인 것을 surfacing 하지 않기 위해).

## 5. Risks & mitigations

| # | Risk | 가능성 | 완화 |
|---|------|--------|------|
| R1 | 027 test 의 `runtimeType.toString() == '_EmptySlotPlaceholder'` 매칭이 Dart mangling 으로 실패 | 낮음 | Dart 는 private class 의 `runtimeType.toString()` 에 언더스코어 prefix 그대로 반환 (Flutter 공식 widget inspector 도 이 방식). 009 prototype 도 `class _EmptySlotPlaceholder` 명명 채택. **최초 test run 시 실패하면 red 를 `findsNWidgets` 수정이 아닌 구현의 class name 불일치로 간주하고 검증** |
| R2 | `GridView` `shrinkWrap: true + NeverScrollable` 가 `draw_result_page.dart` 의 `Expanded` 맥락에서 layout 깨짐 | 낮음 | **cycle 4 에서는 test host (`SingleChildScrollView`) 만 검증**. draw_result_page 는 cycle 6 에서 `Expanded` → `Column` 구조 재검토 (cycle 6 scope 항목으로 이월). 현 cycle 4 verify 는 widget test 4 건만 green 확인 |
| R3 | linear 자투리 `SizedBox.shrink` 가 GridView 셀 size 0 으로 만들어 전체 레이아웃 파괴 | 낮음 | SliverGridDelegateWithFixedCrossAxisCount 는 셀 크기를 `gridDelegate` 가 계산하므로 자식이 `SizedBox.shrink` 여도 셀 박스 자체는 유지됨 (child 가 셀보다 작을 뿐). Research 009 Caveats R1 은 "가능성" 차원의 우려였고, SliverGrid 는 fixed 델리게이트에서 셀 크기 불변. 실패 시 `SizedBox.expand` 로 교체 (impl 내 fallback 준비) |
| R4 | `_DashedRectPainter` 의 dash 가 모서리에서 끊김 (시각 품질) | 중간 | cycle 4 verify 는 widget test 만 검사 — 시각 품질은 별도. Brief 011 스펙 (dashWidth=6, dashGap=4, cornerRadius=4) 그대로 반영하고 시각 튜닝은 cycle 6 ADB 스크린샷 단계에서 실측 |
| R5 | `CardRevealWidget` 생성자 파라미터 변경 (cycle 1~3 사이 누군가 수정) | 낮음 | `card_reveal_widget.dart` 정확히 skim 완료 (§ 하단 결과). 현 signature: `required card, deckId, position, label, isRevealed, onTap; optional showCardName, cardAspectRatio`. 009 prototype 과 동일 |
| R6 | 기존 통과 31 regression (layout_type_mapping 19, user_settings_repo 8, migration_v7_to_v8 4) 실패 | 낮음 | cycle 4 는 UI widget 파일만 수정 — domain/data/db 레이어는 touch 안 함. 회귀 영향 거의 없음. verify 에서 3 파일 명시적 재실행으로 확인 |

## 6. Verification plan (for verify seq=16)

impl 직후 다음 순서로 검증:

1. **주 타겟 테스트 (green 전환 확인)**:
   ```bash
   cd mobile && flutter test test/features/reading/presentation/widgets/spread_layout_test.dart
   ```
   기대: 4 tests passed (T1~T4).

2. **Regression (기 통과 3 파일 재실행)**:
   ```bash
   cd mobile && flutter test \
     test/features/reading/domain/entities/layout_type_mapping_test.dart \
     test/features/settings/data/repositories/user_settings_repository_layout_type_test.dart \
     test/database/migration_v7_to_v8_test.dart
   ```
   기대: all passed (carry-over 총합 — 이전 cycle 보고 합계 ~31 건; 실행
   결과를 verify 보고에서 정확히 기록).

3. **Static analysis (단일 파일 한정)**:
   ```bash
   cd mobile && flutter analyze lib/features/reading/presentation/widgets/spread_layout.dart
   ```
   기대: 0 warning, 0 error. **`flutter analyze` 전체 실행 금지** (cycle
   5/6 범위의 `draw_result_page.dart` 등이 아직 legacy API 를 참조해 의도된
   error 상태).

4. **Structural sanity (grep)**:
   ```bash
   grep -n 'SpreadType\|switch (spreadType)' \
     mobile/lib/features/reading/presentation/widgets/spread_layout.dart
   ```
   기대: no match (switch/SpreadType 잔재 0 건).

   ```bash
   grep -n 'GridView.builder\|_EmptySlotPlaceholder\|_DashedRectPainter\|ValueKey(layoutType)' \
     mobile/lib/features/reading/presentation/widgets/spread_layout.dart
   ```
   기대: 4 symbol 모두 1건 이상 match.

5. **빌드 확인 금지** (cycle 6 호출처 정리 전). `flutter build apk --debug`
   는 cycle 6 impl verify 에서 수행. cycle 4 완료 시점에 빌드 성공
   기대 불필요 (draw_result_page.dart compile error 가 예상됨).

## 7. Cycle boundary

**수정 금지**: `home_page.dart`, `draw_result_page.dart`,
`animated_draw_page.dart`, `reading_list_page.dart`, `reading_detail_page.dart`,
`card_reveal_widget.dart`, `layout_type.dart` (cycle 1 완료), migration
관련 파일, settings repository.

**실행 금지**: `flutter analyze` 프로젝트 전체, `flutter build apk`,
`flutter run`.

**cycle 4 산출물 범위**:
1. `spread_layout.dart` 전면 재작성 (인라인 `_EmptySlotPlaceholder` +
   `_DashedRectPainter` 포함)
2. `spread_layout_test.dart` 4 test green
3. 기존 3 test 파일 regression 유지

cycle 5 (세팅 UI) / cycle 6 (호출처 갱신 + 통합 검증) 로 나머지 이관.

---

## Appendix — CardRevealWidget signature 확인 결과

009 prototype 과 완전 일치, 변경 없음:

```dart
const CardRevealWidget({
  super.key,
  required ShuffledCard card,
  required String deckId,
  required int position,
  required String label,
  required bool isRevealed,
  required VoidCallback onTap,
  bool showCardName = true,
  double cardAspectRatio = 70.0 / 120.0,
});
```

impl 단계에서 추가 발견 불필요. itemBuilder 의 CardRevealWidget 호출은
prototype 그대로 채택하면 됨. prototype reuse 비율 ~95% (파일 구조 +
클래스 2개 + build() 알고리즘 전부 채택, 차이점은 오직 `cardsPerRow`
기본값 3 명시 및 주석 한국어 톤 조정 정도).

## Referenced Files

| File | Role |
|------|------|
| `/Users/kampikrein/A/personality/docs/2_tarot_draw/03_draw_experience_settings/009_Research_slot_based_rendering.md` | Prototype 코드 1차 출처 (Finding D/B/C) |
| `/Users/kampikrein/A/personality/docs/2_tarot_draw/03_draw_experience_settings/011_Brief_layout_redesign.md` | Decision 14/15 + Model Anchors § 결과 페이지 렌더링 전략 + Ideal Criteria #9~#12 |
| `/Users/kampikrein/A/personality/docs/2_tarot_draw/03_draw_experience_settings/017_Scope_layout_redesign.md` | cycle 4 scope |
| `/Users/kampikrein/A/personality/docs/2_tarot_draw/03_draw_experience_settings/027_TDD_Red_spread_layout_rendering.md` | 4 widget test 계약 |
| `mobile/lib/features/reading/presentation/widgets/spread_layout.dart` | 재작성 타겟 |
| `mobile/lib/features/reading/presentation/widgets/card_reveal_widget.dart` | 재사용 위젯 (변경 없음) |
| `mobile/lib/features/reading/domain/entities/layout_type.dart` | 소비 API |
| `mobile/lib/features/draw/presentation/pages/draw_result_page.dart` | 호출처 1건 — cycle 6 갱신 |
| `mobile/test/features/reading/presentation/widgets/spread_layout_test.dart` | green 전환 타겟 |

## Session Log (auto-appended)
