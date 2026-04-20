// TDD Red — Cycle 1 (layout_redesign pipeline)
// Spec: docs/2_tarot_draw/03_draw_experience_settings/018_TDD_Red_layout_type_mapping.md
// Scope: docs/2_tarot_draw/03_draw_experience_settings/017_Scope_layout_redesign.md
// Brief: docs/2_tarot_draw/03_draw_experience_settings/011_Brief_layout_redesign.md
//
// Purpose:
//   This file asserts the EXISTENCE and BEHAVIOR of `LayoutType` — an
//   enhanced enum at
//   `lib/features/reading/domain/entities/layout_type.dart`
//   that replaces the legacy `SpreadType`. Until cycle 1 impl performs
//   the rename + enhanced-enum conversion, the import below will not
//   resolve and `flutter test` will fail compilation on this file.
//   That is the intended Red state.
//
// Green target (makeplan → impl): implement `LayoutType` exactly as
// the Brief 011 Model Anchors matrix + drawToSlot mapping specify.
// These tests encode the full contract for cycle 1.

import 'package:flutter_test/flutter_test.dart';

// RED: this URI does not exist yet. cycle 1 impl creates it.
import 'package:personality_mobile/features/reading/domain/entities/layout_type.dart';

void main() {
  // ------------------------------------------------------------------
  // T1 — enum 매트릭스 값 (Brief 011 Model Anchors 표 런타임 일치)
  // ------------------------------------------------------------------
  group('T1 — LayoutType matrix values', () {
    test('linear: min=1, max=10, default=3, override=null, displayName=나열', () {
      expect(LayoutType.linear.cardCountMin, 1);
      expect(LayoutType.linear.cardCountMax, 10);
      expect(LayoutType.linear.defaultCardCount, 3);
      expect(LayoutType.linear.cardsPerRowOverride, isNull);
      expect(LayoutType.linear.displayName, '나열');
    });

    test('tShape: min=4, max=10, default=4, override=3, displayName=T모양', () {
      expect(LayoutType.tShape.cardCountMin, 4);
      expect(LayoutType.tShape.cardCountMax, 10);
      expect(LayoutType.tShape.defaultCardCount, 4);
      expect(LayoutType.tShape.cardsPerRowOverride, 3);
      expect(LayoutType.tShape.displayName, 'T모양');
    });

    test('grid3x3: min=9, max=10, default=9, override=3, displayName=3x3', () {
      expect(LayoutType.grid3x3.cardCountMin, 9);
      expect(LayoutType.grid3x3.cardCountMax, 10);
      expect(LayoutType.grid3x3.defaultCardCount, 9);
      expect(LayoutType.grid3x3.cardsPerRowOverride, 3);
      expect(LayoutType.grid3x3.displayName, '3x3');
    });
  });

  // ------------------------------------------------------------------
  // T2 — drawToSlot 매핑 (의식적 패턴 + +N 동작)
  // ------------------------------------------------------------------
  group('T2 — drawToSlot mapping', () {
    test('linear: identity — drawToSlot(n, cardCount) == n', () {
      for (var n = 0; n < 10; n++) {
        expect(
          LayoutType.linear.drawToSlot(n, 10),
          n,
          reason: 'linear must be identity at drawIndex=$n',
        );
      }
    });

    test('tShape default 4 cards: [0, 1, 2, 4] (자리 4·6 빈칸)', () {
      final mapped = [
        for (var i = 0; i < 4; i++) LayoutType.tShape.drawToSlot(i, 4),
      ];
      expect(mapped, [0, 1, 2, 4]);
    });

    test('tShape +N (drawIndex=4, cardCount=7) → slot 6 (자리 7 좌→우)', () {
      expect(LayoutType.tShape.drawToSlot(4, 7), 6);
    });

    test(
      'grid3x3 9 cards: 좌 기둥 → 우 기둥 → 중앙 기둥 (각 아래→위) = '
      '[6, 3, 0, 8, 5, 2, 7, 4, 1]',
      () {
        final mapped = [
          for (var i = 0; i < 9; i++) LayoutType.grid3x3.drawToSlot(i, 9),
        ];
        expect(mapped, [6, 3, 0, 8, 5, 2, 7, 4, 1]);
      },
    );

    test('grid3x3 +1 (drawIndex=9, cardCount=10) → slot 9 (단순 좌→우)', () {
      expect(LayoutType.grid3x3.drawToSlot(9, 10), 9);
    });
  });

  // ------------------------------------------------------------------
  // T3 — emptySlots / slotCount / resolvePositions
  // ------------------------------------------------------------------
  group('T3 — emptySlots / slotCount / resolvePositions', () {
    test('linear.emptySlots(5) is empty', () {
      expect(LayoutType.linear.emptySlots(5), <int>{});
    });

    test('tShape.emptySlots(4) == {3, 5} (자리 4·6)', () {
      expect(LayoutType.tShape.emptySlots(4), {3, 5});
    });

    test('tShape.emptySlots(7) == {3, 5} (추가 카드가 와도 기본 빈칸 유지)', () {
      expect(LayoutType.tShape.emptySlots(7), {3, 5});
    });

    test('grid3x3.emptySlots(9) is empty', () {
      expect(LayoutType.grid3x3.emptySlots(9), <int>{});
    });

    test('tShape.slotCount(4) == 6 (2 rows × 3 cols)', () {
      expect(LayoutType.tShape.slotCount(4), 6);
    });

    test('tShape.slotCount(7) == 9 (3 rows × 3 cols)', () {
      expect(LayoutType.tShape.slotCount(7), 9);
    });

    test('grid3x3.slotCount(9) == 9', () {
      expect(LayoutType.grid3x3.slotCount(9), 9);
    });

    test('grid3x3.slotCount(10) == 12 (ceil(10/3)*3)', () {
      expect(LayoutType.grid3x3.slotCount(10), 12);
    });

    test('linear.resolvePositions(3) length == 3', () {
      expect(LayoutType.linear.resolvePositions(3).length, 3);
    });

    test('linear.resolvePositions(3)[0] == "카드 1" (Brief Decision 8 generic)', () {
      expect(LayoutType.linear.resolvePositions(3)[0], '카드 1');
    });

    test('tShape.resolvePositions(4) length == 4 (positions 수 = cardCount)', () {
      expect(LayoutType.tShape.resolvePositions(4).length, 4);
    });
  });
}
