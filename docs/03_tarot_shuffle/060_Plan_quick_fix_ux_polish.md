---
id: "026"
type: plan
title: "Cycle 1 — Quick Fix + UX Polish"
created: 2026-03-16
traces_scope: "025"
summary: >
  비평 보고서(013-017) Critical/High/Medium 이슈 중 기존 파일 수정만으로 해결 가능한 항목 일괄 적용.
  기술 보강(transaction, try-catch, cascade delete) + UX 개선(FadeTransition, easing, 카드 크기) +
  도메인/안전(역방향 0.33, 폴백 언어, 안전 고지, Semantics).
keywords: [quick-fix, ux-polish, critique-improvement, cycle-1]
---

# 026 — Cycle 1: Quick Fix + UX Polish

## Goal

4개 비평 보고서에서 도출된 기존 코드 수정 항목을 일괄 적용. 신규 파일 없이 ~12개 파일 수정으로 기술 품질, UX, 심리적 안전성을 동시에 개선.

## Scope

### Included
| # | Item | Source |
|---|------|--------|
| 1 | deleteReading transaction 래핑 | 013 Flutter [High] |
| 2 | _startShuffle try-catch + 에러 피드백 | 013 Flutter [High] |
| 3 | Cards FK cascade delete | 013 Flutter [Medium] |
| 4 | DrawnCards FK cascade delete | 013 Flutter [Medium] |
| 5 | shouldRepaint 최적화 | 013 Flutter [Low] |
| 6 | 카드 크기 0.15→0.22 | 014 UX [Medium] |
| 7 | GoRouter FadeTransition 600ms | 014 UX [High] |
| 8 | 리플 easing curve 적용 | 014 UX [Medium] |
| 9 | CardRevealWidget perspective 0.002 | 014 UX [Medium] |
| 10 | CardRevealWidget Semantics + 햅틱 | 014 UX [High] |
| 11 | EntropyProgressIndicator 반응형 너비 | 014 UX [Medium] |
| 12 | 센서 폴백 언어 재프레이밍 | 014 UX [High] + 016 심리학 |
| 13 | reversalProbability 0.5→0.33 | 015 타로 [Warning] + 016 심리학 |
| 14 | 역방향 라벨 안내 문구 | 016 심리학 [Medium] |
| 15 | 심리적 안전 고지 (면책 문구) | 016 심리학 [High] |

### Excluded
| Item | Reason |
|------|--------|
| ReadingSession 엔티티 | Cycle 2 |
| 반성 질문 시스템 | Cycle 2 |
| 홈 화면 앰비언스 | Cycle 2 |
| 의도 설정 화면 | Cycle 2 |

## Structural Decisions

> No structural decisions required — all changes are direct modifications guided by critique reports.

---

## File Change Summary

### Modified Files
| # | File Path | Change Description |
|---|-----------|-------------------|
| 1 | mobile/lib/core/database/daos/reading_dao.dart | deleteReading → transaction 래핑 |
| 2 | mobile/lib/core/database/tables/cards_table.dart | FK onDelete cascade |
| 3 | mobile/lib/core/database/tables/drawn_cards_table.dart | FK onDelete cascade |
| 4 | mobile/lib/core/router/app_router.dart | builder → pageBuilder + FadeTransition |
| 5 | mobile/lib/features/shuffle/presentation/pages/shuffle_page.dart | try-catch, 폴백 언어 |
| 6 | mobile/lib/features/shuffle/presentation/widgets/card_painter.dart | shouldRepaint, 카드 크기 |
| 7 | mobile/lib/features/shuffle/presentation/widgets/riffle_animation_controller.dart | CurvedAnimation |
| 8 | mobile/lib/features/shuffle/presentation/widgets/entropy_progress_indicator.dart | 반응형 너비, 폴백 문구 |
| 9 | mobile/lib/features/shuffle/domain/entities/shuffle_config.dart | reversalProbability 0.33 |
| 10 | mobile/lib/features/reading/presentation/widgets/card_reveal_widget.dart | Semantics, 햅틱, perspective, 역방향 문구 |
| 11 | mobile/lib/features/reading/presentation/pages/reading_page.dart | 안전 고지 면책 문구 |

---

## Step 1 — reading_dao.dart: deleteReading transaction

### Current Code
```dart
// mobile/lib/core/database/daos/reading_dao.dart:37-40
Future<int> deleteReading(String id) async {
  await (delete(drawnCards)..where((dc) => dc.readingId.equals(id))).go();
  return (delete(readings)..where((r) => r.id.equals(id))).go();
}
```

### After Code
```dart
Future<int> deleteReading(String id) async {
  return transaction(() async {
    await (delete(drawnCards)..where((dc) => dc.readingId.equals(id))).go();
    return (delete(readings)..where((r) => r.id.equals(id))).go();
  });
}
```

---

## Step 2 — cards_table.dart + drawn_cards_table.dart: cascade delete

### Current Code — cards_table.dart:8
```dart
TextColumn get deckId => text().references(Decks, #id)();
```

### After Code
```dart
TextColumn get deckId => text().references(Decks, #id, onDelete: KeyAction.cascade)();
```

### Current Code — drawn_cards_table.dart:8-9
```dart
TextColumn get readingId => text().references(Readings, #id)();
TextColumn get cardId => text().references(Cards, #id)();
```

### After Code
```dart
TextColumn get readingId => text().references(Readings, #id, onDelete: KeyAction.cascade)();
TextColumn get cardId => text().references(Cards, #id, onDelete: KeyAction.cascade)();
```

---

## Step 3 — app_router.dart: FadeTransition 600ms

### Current Code
```dart
// mobile/lib/core/router/app_router.dart:15-42 (모든 GoRoute)
GoRoute(
  path: '/',
  name: 'home',
  builder: (context, state) => const HomePage(),
),
```

### After Code
```dart
import 'package:flutter/material.dart';
// ... existing imports ...

GoRoute(
  path: '/',
  name: 'home',
  pageBuilder: (context, state) => CustomTransitionPage(
    key: state.pageKey,
    child: const HomePage(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
    transitionDuration: const Duration(milliseconds: 600),
  ),
),
// 동일 패턴을 /deck, /shuffle/:deckId, /reading/:deckId에도 적용
```

---

## Step 4 — shuffle_page.dart: try-catch + 폴백 언어

### Current Code — _startShuffle (line 63-86)
```dart
Future<void> _startShuffle() async {
  setState(() => _phase = ShufflePhase.shuffling);
  final cards = await ref.read(deckCardsProvider(widget.deckId).future);
  // ... 에러 핸들링 없음
}
```

### After Code
```dart
Future<void> _startShuffle() async {
  setState(() => _phase = ShufflePhase.shuffling);
  try {
    final cards = await ref.read(deckCardsProvider(widget.deckId).future);
    final useCase = ref.read(shuffleDeckUseCaseProvider);
    final strategy = ref.read(shuffleStrategyProvider);
    final config = ref.read(shuffleConfigNotifierProvider);

    await _animState.playRiffle(
      cardCount: cards.length,
      shuffleCount: config.shuffleCount,
    );

    final result = useCase.execute(
      cards: cards,
      strategy: strategy,
      config: config,
    );

    ref.read(shuffleStateProvider.notifier).setResult(result);
    ref.read(hapticServiceProvider).mediumImpact();
    setState(() => _phase = ShufflePhase.drawing);
  } catch (e) {
    setState(() => _phase = ShufflePhase.collecting);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('셔플에 실패했습니다: $e')),
      );
    }
  }
}
```

### 폴백 언어 변경 (line 147)
```dart
// Before
'센서를 사용할 수 없습니다. 시스템 난수로 진행합니다.'

// After
'조용히 호흡을 가다듬으세요.\n우주가 카드를 배열합니다.'
```

---

## Step 5 — card_painter.dart: shouldRepaint + 카드 크기

### Current Code
```dart
final cardWidth = size.width * 0.15;  // line 18
// ...
bool shouldRepaint(CardPainter oldDelegate) => true;  // line 122
```

### After Code
```dart
final cardWidth = size.width * 0.22;  // 카드 크기 확대

@override
bool shouldRepaint(CardPainter oldDelegate) =>
    animationState.cardPositions != oldDelegate.animationState.cardPositions;
```

---

## Step 6 — riffle_animation_controller.dart: CurvedAnimation

### Current Code — _playOneRiffle (line 37-40)
```dart
_controller = AnimationController(
  vsync: _vsync,
  duration: const Duration(milliseconds: 800),
);

_controller!.addListener(() {
  final t = _controller!.value;
```

### After Code
```dart
_controller = AnimationController(
  vsync: _vsync,
  duration: const Duration(milliseconds: 800),
);

final curved = CurvedAnimation(parent: _controller!, curve: Curves.easeInOut);
curved.addListener(() {
  final t = curved.value;
```

동일하게 `_gatherCards`의 AnimationController에도 적용.

---

## Step 7 — card_reveal_widget.dart: Semantics + 햅틱 + perspective + 역방향 문구

### After Code (build method 전체 교체)
```dart
@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);

  return Semantics(
    label: widget.isRevealed
        ? '${widget.label} 포지션: ${widget.card.card.name}'
        : '${widget.label} 포지션: 탭하여 카드를 뒤집으세요',
    button: !widget.isRevealed,
    child: GestureDetector(
      onTap: widget.isRevealed ? null : () {
        widget.onTap();
        HapticFeedback.lightImpact();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.label, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final angle = _animation.value * math.pi;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.002)  // 0.001→0.002
                  ..rotateY(angle),
                child: _showFront ? _buildFront(theme) : _buildBack(theme),
              );
            },
          ),
          if (widget.isRevealed && widget.card.isReversed)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '역방향 — 이 카드의 에너지가 내면으로 향합니다',
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    ),
  );
}
```

import 추가: `import 'package:flutter/services.dart';`

---

## Step 8 — entropy_progress_indicator.dart: 반응형 너비 + 폴백 문구

### After Code (전체)
```dart
if (!sensorsAvailable) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.nights_stay, color: theme.colorScheme.primary, size: 24),
      const SizedBox(height: 4),
      Text('우주의 에너지로 배열합니다',
          style: theme.textTheme.bodyMedium),
    ],
  );
}

return Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: LinearProgressIndicator(
        value: progress,
        // ... 나머지 동일
      ),
    ),
    // ... 나머지 동일
  ],
);
```

---

## Step 9 — shuffle_config.dart: reversalProbability 0.33

### Current Code
```dart
@Default(0.5) double reversalProbability,
```

### After Code
```dart
@Default(0.33) double reversalProbability,
```

---

## Step 10 — reading_page.dart: 심리적 안전 고지

### After Code (body에 Column 추가)
```dart
body: Column(
  children: [
    Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SpreadLayout(
          spreadType: _spreadType,
          cards: drawnCards,
          revealedPositions: _revealedPositions,
          onCardTap: (position) {
            setState(() => _revealedPositions.add(position));
          },
        ),
      ),
    ),
    // 안전 고지
    Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Text(
        '타로는 자기 성찰의 도구입니다. 결과에 과도한 의미를 부여하지 마세요.\n'
        '심리적 어려움이 있다면 정신건강 위기상담전화 1577-0199',
        style: TextStyle(
          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.7),
          fontSize: 11,
        ),
        textAlign: TextAlign.center,
      ),
    ),
  ],
),
```

---

## Considerations & Trade-offs

### Alternative Approaches
- 센서 폴백: "센서 없음 → 터치 기반 엔트로피"도 고려했으나 Cycle 2 범위로 분리
- 역방향 확률: 0.0(역방향 없음) 옵션도 타로 전통 근거 있으나, 0.33으로 절충

### Potential Risks
- cascade delete 추가 시 기존 DB와 마이그레이션 필요 (schemaVersion 2)
- shouldRepaint 리스트 비교가 매 프레임 78개 객체 비교 → 성능 확인 필요

### Backward Compatibility
- DB 스키마 변경(cascade) → schemaVersion 증가 필요. 기존 데이터는 보존됨
- reversalProbability 기본값 변경은 신규 셔플에만 영향

## Implementation Checklist

- [ ] Step 1: deleteReading transaction 래핑
- [ ] Step 2: cascade delete (cards_table, drawn_cards_table)
- [ ] Step 3: GoRouter FadeTransition
- [ ] Step 4: shuffle_page try-catch + 폴백 언어
- [ ] Step 5: card_painter shouldRepaint + 카드 크기
- [ ] Step 6: riffle easing curve
- [ ] Step 7: card_reveal Semantics + 햅틱 + perspective + 역방향 문구
- [ ] Step 8: entropy_progress 반응형 + 폴백 문구
- [ ] Step 9: reversalProbability 0.33
- [ ] Step 10: reading_page 안전 고지
- [ ] build_runner 재생성 (shuffle_config 변경)
- [ ] flutter analyze 0 이슈 확인
- [ ] Final verification

## Verification Assertions

| Level | Assertion | Verification Method | Expected Result |
|-------|-----------|-------------------|-----------------|
| L1-Build | flutter analyze 통과 | `flutter analyze` | 0 이슈 |
| L1-Build | build_runner 성공 | `dart run build_runner build` | 에러 없음 |
| L2-CLI | flutter test 통과 | `flutter test` | All tests passed |

## References

| Resource | Path | Related Content |
|----------|------|-----------------|
| Flutter 비평 | docs/11_tarot_shuffle/013_Agent_flutter_critique.md | 기술 이슈 |
| UX 비평 | docs/11_tarot_shuffle/014_Agent_ux_critique.md | UI/접근성 이슈 |
| 타로 비평 | docs/11_tarot_shuffle/015_Agent_tarot_critique.md | 역방향 확률 |
| 심리학 비평 | docs/11_tarot_shuffle/016_Agent_psychology_critique.md | 안전 고지, 폴백 |
| Synthesis | docs/11_tarot_shuffle/017_Synthesis_mvp_critique.md | 우선순위 종합 |
| Scope | docs/11_tarot_shuffle/025_Scope_critique_improvements.md | 사이클 구조 |

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
