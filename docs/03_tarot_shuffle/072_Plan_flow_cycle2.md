---
id: "072"
type: plan
title: "Cycle 2 Plan — 업스트림 통합 & ReadingPage 제거"
created: 2026-04-14
cycle: 2
traces_scope: "066"
traces_brief: "065"
traces_tdd_red: "071"
depends_on: ["068"]
parallel_with: []
summary: >
  Brief 065 Cycle 2의 행위 변경을 4-커밋 체인으로 수행한다: (C1) DrawResultPage initState에
  `shuffleStateProvider` 기반 재사용/자체셔플 분기 추가, (C2) AnimatedDrawPage의 결과 블록·저장
  로직 제거 + pushReplacement, (C3) ShufflePage 후단 라우트를 `reading` → `draw-result`,
  (C4) ReadingPage(draw-time) 파일·라우트·import 삭제 + intention_page 주석 갱신. 모든 커밋에서
  빌드 성공을 유지하며 TDD Red 071의 9개 Red 테스트를 Green으로 전환, A2/D3 Green-guard 2건은 유지.
keywords: [plan, cycle2, draw-result, animated-draw, shuffle-page, reading-page, push-replacement, initstate-branch]
---

# 072 — Cycle 2 Plan: 업스트림 통합 & ReadingPage 제거

## Goal

Cycle 1이 완료한 리네임(InstantDrawPage → DrawResultPage, `/draw/instant` → `/draw/result`)
위에서, Brief 065 MA-3/MA-4/MA-5/MA-6/MA-9가 요구하는 **행위 변경**을 완성한다:

1. DrawResultPage가 업스트림(AnimatedDrawPage, ShufflePage) 결과를 재사용한다 (MA-3, MA-9).
2. AnimatedDrawPage는 연출만 담당하고 결과는 DrawResultPage로 위임한다 (MA-4).
3. ShufflePage(Lv4) 후단이 ReadingPage 대신 DrawResultPage로 간다 (MA-5).
4. ReadingPage(draw-time)은 dead code이므로 파일·라우트·import를 제거한다 (MA-6).
   `reading_list_page`, `reading_detail_page` 및 `/readings` 하위 라우트는 그대로 유지한다
   (기록 조회용, D3 가드 대상).

TDD Red 071의 9개 Red → Green, 2개 Green-guard(A2 null smoke, D3 reading_list/detail) 유지.

## Scope

### Included

| # | Item | Description |
|---|------|-------------|
| 1 | DrawResultPage `_executeDraw` → 분기형으로 전환 | `shuffleStateProvider`가 비어있으면(`current == null`) 자체 셔플 + `clear()` 수행, 값이 있으면 `clear` 호출하지 않고 객체 재사용 (identity 유지). 분기 조건은 `initState`에서 단일 지점 1회 평가 (MA-9) |
| 2 | AnimatedDrawPage 결과 블록·저장 제거 | `_autoSave`, `_addOneMore`, `readingRepositoryProvider` import, `saveReading`/`addDrawnCard` 호출, 결과 버튼 바(다시/+N/리셋)와 스프레드 렌더 Column 모두 제거 |
| 3 | AnimatedDrawPage 후단 `pushReplacementNamed('draw-result')` | 애니메이션 종료 시점(`_playAnimations` 말단 혹은 `_animationComplete = true` 직후)에서 결과 페이지로 전환 |
| 4 | ShufflePage `_goToReading` → `draw-result` 전환 | `pushNamed('reading', ...)` → `pushReplacementNamed('draw-result', pathParameters: {'deckId': widget.deckId})`. 메서드명은 유지 또는 `_goToDrawResult`로 최소 리네임 (선택) |
| 5 | `reading_page.dart` 파일 삭제 | draw-time 용도의 ReadingPage는 기능이 DrawResultPage에 통합된 뒤 dead code |
| 6 | `app_router.dart`의 `/reading/:deckId` GoRoute + `reading_page.dart` import 삭제 | route name `reading`, path `/reading/:deckId`, `ReadingPage(...)` 위젯 참조, import 모두 삭제. `reading_list_page`, `reading_detail_page` import와 `/readings`·`:readingId` 라우트는 **보존** |
| 7 | `intention_page.dart:42` 주석 갱신 | "시나리오 3-A: 스택의 ReadingPage null 재빌드" 주석은 ReadingPage 삭제로 자연 해결 → 해당 주석 문장만 제거. `shuffleStateProvider.clear()` 금지 이유는 새 맥락("DrawResultPage가 업스트림 값을 소비해야 하므로 IntentionPage가 clear하면 안 됨")으로 갱신 |

### Excluded

| Item | Reason/Timeline |
|------|-----------------|
| DrawResultPage UI 재디자인 (질문 바, 버튼 텍스트, 질문 소스 통일 등) | Brief MA-8. UI는 별도 Brief로 분리 |
| AnimatedDrawPage 내부 연출/애니메이션 로직 개편 | 연출만 유지, 제거 대상은 "결과 섹션" 한정 |
| `readingQuestionProvider` 소스 통합 (TextEditingController vs provider) | DrawResultPage는 Lv1 직접 진입 시 `_questionController`, Lv2/Lv4 업스트림 진입 시 provider가 가진 값을 사용해야 하지만, 두 질문 소스를 UI로 통합하는 것은 본 Cycle의 관심사가 아님. 현 구현의 질문 입력 UI를 유지한 채 provider 값이 존재하면 컨트롤러에 반영하는 최소 보완은 추후 UI Brief에서 |
| ReadingPage의 `_addOneMore`와 DrawResultPage의 `_addOneMore` **UI 레벨** 통합 | Deviations 섹션에서 동치 분석으로 대체. 동치 불일치가 실사용에서 드러나면 별도 Brief |
| `reading_list_page.dart`, `reading_detail_page.dart`, `/readings` 라우트 | Brief MA-6 명시적 보존 대상 |
| Lv3 Shuffle2dPage 신규 구현 | Brief 064 후속 작업 |

## Structural Decisions

| # | Decision | Chosen | Rationale |
|---|----------|--------|-----------|
| 1 | `_executeDraw` 분기 지점 | `initState`에서 `ref.read(shuffleStateProvider)` 1회 읽기 → null 분기 | Brief MA-9 "단일 지점 1회 평가". Future.microtask 내부에서 분기하면 race 발생 여지. `initState` 동기 블록에서 미리 판단 + `_shouldSelfShuffle` bool flag를 `Future.microtask`가 소비 |
| 2 | DrawResultPage가 재사용 시 `clear()` 호출 여부 | 재사용 경로에서는 `clear` 호출하지 **않음** | `clear`하면 업스트림이 막 `setResult`한 값을 바로 지워 Test A1(identity 유지) 실패. Lv1 진입 시 `clear`는 필요(이전 재-진입 대비)하지만 그 경로는 null이므로 자체 셔플 분기에서 자연 수행 |
| 3 | AnimatedDrawPage의 pushReplacement 시점 | `_playAnimations()` 말단에서 `_animationComplete = true` 직후 `context.pushReplacementNamed('draw-result', pathParameters: {'deckId': _deckId})` | Brief IC #9 "끊김·깜빡임 없이 이어진다". 버튼 바 탭 대기가 없어진다 (결과 화면 조작은 DrawResultPage가 담당) |
| 4 | `showFaceUp = false` 시 탭으로 카드 뒤집는 기존 AnimatedDrawPage 동작 | Cycle 2에서는 **유지**. pushReplacement 시점을 "모든 카드 reveal + tap 완료" 뒤로 이동 | showFaceUp=false 경로에서 사용자가 탭하기 전에 결과 페이지로 이동하면 UX 악화. `_animationComplete && allRevealed` 조건으로 통합 |
| 5 | ShufflePage의 `shuffleStateProvider.clear()` 위치 | `_goToReading` 시작부의 `clear()` 호출은 **유지** (그 직후 `setResult`가 덮어쓰므로 race 없음) | 방어적으로 이전 상태 잔류 방지. `pushReplacementNamed` 이전에 `setResult`가 완료되는 순서 보장됨 |
| 6 | 파일 삭제 순서 | C3(호출부 교체) → C4(파일/route/import 삭제) | C4를 먼저 하면 C3 이전 상태에서 `app_router`가 없는 `reading_page.dart`를 import → 빌드 실패. 순서를 뒤집을 경우 중간 커밋의 빌드가 깨짐 |
| 7 | `_goToReading` 메서드명 | Cycle 2에서는 **유지** (내부 private 메서드, 외부 영향 없음) | 메서드명 리네임은 의미 보강일 뿐이고, C3의 핵심은 pushNamed 인자 교체. 스코프 확산 방지 |

## File Change Summary

### Modified Files

| # | File Path | Commit | Change Description |
|---|-----------|--------|-------------------|
| 1 | `mobile/lib/features/draw/presentation/pages/draw_result_page.dart` | C1 | `initState`에 `shuffleStateProvider` null 분기 flag 도입, `_executeDraw`를 "자체 셔플" / "재사용" 두 경로로 분기. 재사용 경로에서는 `clear()` 호출 금지, 업스트림 결과를 `_shuffleResult`로 대입 |
| 2 | `mobile/lib/features/draw/presentation/pages/animated_draw_page.dart` | C2 | `readingRepositoryProvider` import + `_autoSave` + `_addOneMore` + 결과 렌더 섹션(Column의 질문 표시 이후 / 하단 버튼 바 포함) 제거. `_playAnimations` 말단에 `context.pushReplacementNamed('draw-result', pathParameters: {'deckId': _deckId})` 추가. `Reading`·`DrawnCardInfo`·`Uuid` 관련 import 및 미사용 상태(`_savedReadingId`, `_autoSaved`) 제거. `dart:math` / `ShuffledCard` / 카드 렌더 위젯 등 연출 전용 코드는 유지. 연출 종료 대기 로직 재구성 (showFaceUp 분기) |
| 3 | `mobile/lib/features/shuffle/presentation/pages/shuffle_page.dart` | C3 | `_goToReading` 내 `pushNamed('reading', ...)` → `pushReplacementNamed('draw-result', pathParameters: {'deckId': widget.deckId})` |
| 4 | `mobile/lib/core/router/app_router.dart` | C4 | `reading_page.dart` import (line 14) 삭제, `/reading/:deckId` GoRoute 블록 (lines 140-151) 삭제. `SpreadType` 참조가 같은 GoRoute에서만 쓰인다면 import 라인도 같이 삭제 대상 확인 |
| 5 | `mobile/lib/features/shuffle/presentation/pages/intention_page.dart` | C4 | Line 42 주석의 "시나리오 3-A: 스택의 ReadingPage null 재빌드" 문구 제거. clear 금지 이유를 "DrawResultPage가 업스트림 shuffleStateProvider 값을 소비하므로 IntentionPage가 clear하면 안 됨"으로 갱신 |

### Deleted Files

| # | File Path | Commit | Reason |
|---|-----------|--------|--------|
| 1 | `mobile/lib/features/reading/presentation/pages/reading_page.dart` | C4 | draw-time 기능이 DrawResultPage에 통합되어 dead code. Brief MA-6 |

### New Files

| # | File Path | Description |
|---|-----------|-------------|
| — | (없음) | 모든 Cycle 2 변경은 기존 파일 수정 + 1 파일 삭제로 완료됨 |

---

## Step-by-step Plan

### C1 — DrawResultPage initState 분기 (TDD Red A1·A3 해결)

#### Approach

`initState`에서 `ref.read(shuffleStateProvider)`로 기존 결과 여부를 단일 지점에서 판단하고,
bool flag로 저장한 뒤 `Future.microtask`에서 분기 실행한다. null이면 기존처럼 `clear()` + 자체
셔플 + `setResult()`, non-null이면 **clear 금지** + 업스트림 객체를 그대로 `_shuffleResult`에
대입하여 identity를 유지한다(Test A1).

**Depends on**: 없음 (독립).

#### Current Code

```dart
// mobile/lib/features/draw/presentation/pages/draw_result_page.dart:48-100
@override
void initState() {
  super.initState();
  _initSettings();
  Future.microtask(() => _executeDraw());
}

void _initSettings() { /* ... */ }

Future<void> _executeDraw() async {
  try {
    // [이전 뽑기 상태 초기화] keepAlive provider 잔류 방지
    ref.read(shuffleStateProvider.notifier).clear();
    ref.read(readingQuestionProvider.notifier).clear();

    // 덱 시드 보장 (홈을 건너뛴 경우)
    final repo = ref.read(deckRepositoryProvider);
    await repo.seedAllDecks();

    final cards = await ref.read(deckCardsProvider(_deckId).future);
    final useCase = ref.read(shuffleDeckUseCaseProvider);
    final strategy = ref.read(shuffleStrategyProvider);
    final result = useCase.execute(
      cards: cards,
      strategy: strategy,
      config: ShuffleConfig(useReversals: _allowReversed),
    );
    ref.read(shuffleStateProvider.notifier).setResult(result);

    if (!mounted) return;
    setState(() {
      _shuffleResult = result;
      _loading = false;
      for (var i = 0; i < _currentCardCount; i++) {
        _revealedPositions.add(i);
      }
    });
  } catch (e, st) { /* ... */ }
}
```

#### After Code

```dart
// mobile/lib/features/draw/presentation/pages/draw_result_page.dart — C1

// (필드 섹션에 신규 flag 추가)
bool _reuseUpstreamResult = false; // ← NEW

@override
void initState() {
  super.initState();
  _initSettings();

  // ── MA-9: initState 단일 지점 분기 ──
  // shuffleStateProvider가 이미 결과를 가지고 있으면 재사용 (Lv2/Lv4 업스트림 경로),
  // null이면 자체 셔플 (Lv1 직접 진입 경로).
  final existing = ref.read(shuffleStateProvider);
  _reuseUpstreamResult = existing != null; // ← NEW

  Future.microtask(() => _executeDraw());
}

Future<void> _executeDraw() async {
  try {
    if (_reuseUpstreamResult) {
      // ── 재사용 경로: clear 금지. 업스트림 객체 identity 보존 ──
      final upstream = ref.read(shuffleStateProvider);
      if (upstream == null) {
        // 이론상 도달 불가 (initState에서 non-null 확정). 방어적 fallback.
        _reuseUpstreamResult = false;
      } else {
        if (!mounted) return;
        setState(() {
          _shuffleResult = upstream;
          _loading = false;
          for (var i = 0; i < _currentCardCount; i++) {
            _revealedPositions.add(i);
          }
        });
        return;
      }
    }

    // ── 자체 셔플 경로 (Lv1 직접 진입) ──
    ref.read(shuffleStateProvider.notifier).clear();
    ref.read(readingQuestionProvider.notifier).clear();

    // 덱 시드 보장 (홈을 건너뛴 경우)
    final repo = ref.read(deckRepositoryProvider);
    await repo.seedAllDecks();

    final cards = await ref.read(deckCardsProvider(_deckId).future);
    final useCase = ref.read(shuffleDeckUseCaseProvider);
    final strategy = ref.read(shuffleStrategyProvider);
    final result = useCase.execute(
      cards: cards,
      strategy: strategy,
      config: ShuffleConfig(useReversals: _allowReversed),
    );
    ref.read(shuffleStateProvider.notifier).setResult(result);

    if (!mounted) return;
    setState(() {
      _shuffleResult = result;
      _loading = false;
      for (var i = 0; i < _currentCardCount; i++) {
        _revealedPositions.add(i);
      }
    });
  } catch (e, st) {
    debugPrint('_executeDraw error: $e\n$st');
    if (!mounted) return;
    setState(() => _loading = false);
  }
}
```

#### Impact Analysis

- **Imports to update**: 없음. 기존 import로 충분.
- **Type changes**: 없음.
- **Test updates**: TDD Red 071 Group A 자동 Green 전환 (A1, A3). A2(null smoke)는 Green 유지.
- **"다시" 버튼(`_executeDraw` 재호출)**: 버튼 탭 시 `_reuseUpstreamResult=true`로 시작했어도
  `setState`로 `_shuffleResult=null`로 리셋하기만 하고 `_reuseUpstreamResult` flag는 그대로라
  **재사용 경로를 다시 탄다** → 같은 upstream result를 다시 보여줌(무의미). "다시"는 자체
  재셔플 의도이므로, "다시" 핸들러에서 `_reuseUpstreamResult = false`를 함께 리셋해야 한다.
  → 버튼 onPressed 내부 setState 블록 앞에 `_reuseUpstreamResult = false;` 추가.

**보강 After code (build() 내 "다시" 버튼)**:

```dart
// mobile/lib/features/draw/presentation/pages/draw_result_page.dart:268-280 (C1 보강)
FilledButton.tonalIcon(
  onPressed: () {
    setState(() {
      _shuffleResult = null;
      _revealedPositions.clear();
      _savedReadingId = null;
      _autoSaved = false;
      _loading = true;
      _reuseUpstreamResult = false; // ← NEW: "다시"는 강제 재셔플
    });
    _executeDraw();
  },
  icon: const Icon(Icons.refresh, size: 18),
  label: const Text('다시'),
),
```

#### Commit Message

```
feat(draw): branch DrawResultPage init on shuffleStateProvider (Cycle 2 — 1/4)

Lv2/Lv4 업스트림 경로에서 이미 setResult된 결과를 재사용하도록
_executeDraw를 분기 처리. initState에서 단일 지점 1회 평가 (Brief MA-9).
Lv1 직접 진입 시는 기존처럼 clear + 자체 셔플.

- TDD Red 071 A1 (identity reuse), A3 (branch source) → Green
- A2 (null smoke) Green 유지
```

---

### C2 — AnimatedDrawPage 결과 블록 제거 + pushReplacement (TDD Red B1·B2·B3)

#### Approach

AnimatedDrawPage를 "연출 페이지"로 축소한다. 결과 렌더(카드 뒤집기는 유지하되, 제거 대상은
**"저장" / "+N장" / "다시" / "리셋" 하단 버튼 바와 저장 로직**), `_autoSave`, `_addOneMore`,
`readingRepositoryProvider` 사용을 삭제한다. 연출 종료 시 `pushReplacementNamed('draw-result', ...)`.

현 소스는 `SpreadLayout`을 쓰지 않고 `GridView.builder`로 카드를 렌더하므로 **"SpreadLayout 블록
제거"는 해당 없음** — 대신 하단 버튼 바(lines 339-385)와 저장 메서드 2개(lines 154-202)가 제거 대상.

**Depends on**: C1 (DrawResultPage가 업스트림 결과를 재사용할 수 있어야 pushReplacement 후 정상 동작).

#### Current Code

```dart
// mobile/lib/features/draw/presentation/pages/animated_draw_page.dart:1-17 (imports)
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../reading/domain/entities/reading.dart';
import '../../../reading/domain/entities/spread_type.dart';
import '../../../reading/presentation/providers/reading_providers.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../../shuffle/domain/entities/shuffle_config.dart';
import '../../../shuffle/domain/entities/shuffle_result.dart';
import '../../../shuffle/presentation/providers/shuffle_providers.dart';
import '../../../deck/presentation/providers/deck_providers.dart';
import '../../../shuffle/presentation/pages/intention_page.dart';
```

```dart
// mobile/lib/features/draw/presentation/pages/animated_draw_page.dart:127-152 (_playAnimations 현재)
Future<void> _playAnimations() async {
  for (var i = 0; i < _currentCardCount; i++) {
    if (!mounted) return;
    unawaited(_slideControllers[i].forward());
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  if (_slideControllers.isNotEmpty) {
    await _slideControllers.last.forward();
  }

  if (_showFaceUp && mounted) {
    setState(() {
      for (var i = 0; i < _currentCardCount; i++) {
        _revealedPositions.add(i);
      }
      _animationComplete = true;
    });
  } else if (mounted) {
    setState(() => _animationComplete = true);
  }
}
```

```dart
// mobile/lib/features/draw/presentation/pages/animated_draw_page.dart:154-202 (저장 메서드 — 제거 대상)
void _autoSave() { /* readingRepositoryProvider.saveReading */ }
void _addOneMore() { /* readingRepositoryProvider.addDrawnCard */ }
```

```dart
// mobile/lib/features/draw/presentation/pages/animated_draw_page.dart:213-389 (build 후단 — 결과 블록 포함)
// lines 217-219: allRevealed && _shuffleExecuted 시 _autoSave() 호출 (제거)
// lines 300-388: 셔플 후 Scaffold(카드 애니메이션 유지, 하단 버튼 바는 제거)
// lines 339-385: _animationComplete 시 "다시 / +N장 / 리셋" 버튼 바 (제거)
```

```dart
// mobile/lib/features/draw/presentation/pages/animated_draw_page.dart:424-432
void _revealCard(int index) {
  if (_revealedPositions.contains(index)) return;
  setState(() => _revealedPositions.add(index));

  if (_revealedPositions.length >= _currentCardCount) {
    _autoSave();
  }
}
```

#### After Code

**imports (제거 대상 표시)**:

```dart
// mobile/lib/features/draw/presentation/pages/animated_draw_page.dart — C2 imports
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// import 'package:uuid/uuid.dart';                                         // ← REMOVED
// import '../../../reading/domain/entities/reading.dart';                  // ← REMOVED
import '../../../reading/domain/entities/spread_type.dart';
// import '../../../reading/presentation/providers/reading_providers.dart'; // ← REMOVED
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../../shuffle/domain/entities/shuffle_config.dart';
import '../../../shuffle/domain/entities/shuffle_result.dart';
import '../../../shuffle/presentation/providers/shuffle_providers.dart';
import '../../../deck/presentation/providers/deck_providers.dart';
import '../../../shuffle/presentation/pages/intention_page.dart';
```

**상태 필드 정리 (lines 28-47 근방)**:

```dart
// 필드에서 제거: String? _savedReadingId;  ← REMOVED
// 필드에서 제거: bool _autoSaved = false;  ← REMOVED
// 나머지 상태(_shuffleResult, _currentCardCount, _spreadType, _deckId,
// _showFaceUp, _allowReversed, _showCardName, _revealedPositions,
// _shuffleExecuted, _animationComplete, AnimationController 리스트,
// _questionController)는 유지.
```

**`_playAnimations` 재작성 — pushReplacement 포함**:

```dart
// mobile/lib/features/draw/presentation/pages/animated_draw_page.dart — C2
Future<void> _playAnimations() async {
  for (var i = 0; i < _currentCardCount; i++) {
    if (!mounted) return;
    unawaited(_slideControllers[i].forward());
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  if (_slideControllers.isNotEmpty) {
    await _slideControllers.last.forward();
  }

  if (!mounted) return;
  setState(() => _animationComplete = true);

  // ── MA-4: 결과 페이지로 위임 ──
  // showFaceUp=true이면 즉시 reveal 후 전환.
  // showFaceUp=false이면 사용자가 모든 카드를 탭해 reveal할 때까지 대기 후 _maybeGoToResult()가 전환.
  if (_showFaceUp) {
    setState(() {
      for (var i = 0; i < _currentCardCount; i++) {
        _revealedPositions.add(i);
      }
    });
    _maybeGoToResult();
  }
}

void _maybeGoToResult() {
  if (!mounted) return;
  if (!_animationComplete) return;
  if (_revealedPositions.length < _currentCardCount) return;
  // pushReplacementNamed — 연출 페이지는 스택에서 제거
  context.pushReplacementNamed(
    'draw-result',
    pathParameters: {'deckId': _deckId},
  );
}
```

**`_revealCard` 갱신 — 저장 대신 전환 체크**:

```dart
// mobile/lib/features/draw/presentation/pages/animated_draw_page.dart — C2
void _revealCard(int index) {
  if (_revealedPositions.contains(index)) return;
  setState(() => _revealedPositions.add(index));

  // 모든 카드 reveal 시 결과 페이지로 전환
  if (_revealedPositions.length >= _currentCardCount) {
    _maybeGoToResult();
  }
}
```

**`_autoSave`, `_addOneMore` 메서드 전체 삭제**.

**`build()` 후단 정리 (lines 213-389)**:

```dart
// mobile/lib/features/draw/presentation/pages/animated_draw_page.dart — C2
@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);

  // ── 셔플 전: 질문 입력 화면 ── (기존 로직 유지, 변경 없음)
  if (!_shuffleExecuted) {
    return Scaffold(/* 기존 질문 입력 Scaffold 그대로 */);
  }

  // ── 셔플 후: 애니메이션 ── (결과 블록 제거, 카드 렌더만 유지)
  if (_shuffleResult == null) {
    return Scaffold(
      appBar: AppBar(title: const Text('카드 뽑기')),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  final drawnCards = _shuffleResult!.cards.take(_currentCardCount).toList();

  return Scaffold(
    appBar: AppBar(
      title: Text('${_spreadType.displayName} \u2014 연출'),
      leading: IconButton(
        icon: const Icon(Icons.home),
        onPressed: () => context.go('/'),
      ),
    ),
    body: Column(
      children: [
        // 질문 표시 (기존 유지)
        if (_questionController.text.isNotEmpty)
          Padding(/* 기존 질문 표시 Padding 그대로 */),

        // ── 애니메이션 카드 레이아웃 ── (기존 GridView 유지)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: _buildAnimatedCards(drawnCards),
          ),
        ),

        // ── 하단 버튼 바 제거됨 ──
        // (다시/+N장/리셋 버튼은 DrawResultPage에 존재)
      ],
    ),
  );
}
```

#### Impact Analysis

- **Imports to update**: `uuid`, `reading.dart`, `reading_providers.dart` 3개 import 제거.
  `dart:math`, `shuffle_result.dart`, `spread_type.dart`, `ShuffledCard` 사용은 카드 렌더에
  여전히 필요하므로 유지.
- **Type changes**: 없음.
- **Test updates**:
  - TDD Red B1/B2/B3 → Green 전환
  - 기존 `animated_draw_page`에 대한 widget test는 없음 (확인 완료). 있다면 저장/버튼 바 의존
    테스트는 수정 필요.
- **Config changes**: 없음.
- **잠재 회귀**: `showFaceUp=false` 경로에서 사용자가 한 장 reveal 후 나가면 `_maybeGoToResult`가
  조건 미충족으로 전환 않음 → 페이지에 갇힘 → `홈` 버튼이 AppBar에 있음으로 회복 가능.
  UX 저해는 있으나 Cycle 2 스코프 아님. 추후 UI Brief에서 "강제 reveal / 진행률 표시" 검토.

#### Commit Message

```
refactor(draw): AnimatedDrawPage delegates result to DrawResultPage (Cycle 2 — 2/4)

연출 완료 시 pushReplacementNamed('draw-result')로 전환. 내부의 저장·
한 장 더·하단 버튼 바 및 readingRepositoryProvider 의존을 제거해
연출 책임만 남긴다 (Brief MA-4).

- TDD Red 071 B1/B2/B3 → Green
- 연출 로직(_setupAnimations, _playAnimations, _buildAnimatedCards) 유지
```

---

### C3 — ShufflePage 후단 전환 (TDD Red C1·C2)

#### Approach

`_goToReading()` 내의 `pushNamed('reading', ...)`를 `pushReplacementNamed('draw-result', ...)`로
교체한다. 기존 `shuffleStateProvider.clear()` + `setResult(result)` 순서는 유지
(setResult가 clear를 덮어씀 — race 없음, DrawResultPage initState에서 non-null로 관찰됨).

**Depends on**: C1 (DrawResultPage가 업스트림 값 재사용 가능).

#### Current Code

```dart
// mobile/lib/features/shuffle/presentation/pages/shuffle_page.dart:52-71
Future<void> _goToReading() async {
  // [이전 셔플 상태 초기화] 새 뽑기 전 잔류 방지.
  // readingQuestionProvider는 IntentionPage.initState에서 이미 초기화됨 — 여기서 clear 금지.
  ref.read(shuffleStateProvider.notifier).clear();

  ref.read(hapticServiceProvider).mediumImpact();

  // 덱 카드 로드 + 셔플 실행
  final cards = await ref.read(deckCardsProvider(widget.deckId).future);
  final useCase = ref.read(shuffleDeckUseCaseProvider);
  final strategy = ref.read(shuffleStrategyProvider);
  final result = useCase.execute(cards: cards, strategy: strategy);
  ref.read(shuffleStateProvider.notifier).setResult(result);

  if (!mounted) return;
  await context.pushNamed(
    'reading',
    pathParameters: {'deckId': widget.deckId},
  );
}
```

#### After Code

```dart
// mobile/lib/features/shuffle/presentation/pages/shuffle_page.dart — C3
Future<void> _goToReading() async {
  // [이전 셔플 상태 초기화] 새 뽑기 전 잔류 방지.
  // readingQuestionProvider는 IntentionPage.initState에서 이미 초기화됨 — 여기서 clear 금지.
  ref.read(shuffleStateProvider.notifier).clear();

  ref.read(hapticServiceProvider).mediumImpact();

  // 덱 카드 로드 + 셔플 실행
  final cards = await ref.read(deckCardsProvider(widget.deckId).future);
  final useCase = ref.read(shuffleDeckUseCaseProvider);
  final strategy = ref.read(shuffleStrategyProvider);
  final result = useCase.execute(cards: cards, strategy: strategy);
  ref.read(shuffleStateProvider.notifier).setResult(result);

  if (!mounted) return;
  // MA-5: ReadingPage 대신 DrawResultPage로 수렴. pushReplacement로 셔플 페이지는 스택에서 제거.
  await context.pushReplacementNamed(
    'draw-result',
    pathParameters: {'deckId': widget.deckId},
  );
}
```

> 메서드명 `_goToReading`은 Cycle 2에서 **유지**. 의미 확장은 선택 사항(별도 Brief).

#### Impact Analysis

- **Imports to update**: 없음.
- **Type changes**: 없음. `pushNamed` / `pushReplacementNamed` 모두 go_router 제공.
- **Test updates**: TDD Red C1/C2 → Green.
- **뒤로가기 UX**: `pushReplacement`로 ShufflePage가 스택에서 사라지므로 DrawResultPage에서
  뒤로가기 시 `/intention/:deckId` → `/deck` → `/`로 복귀 (기존 스택 기준). Brief IC #13
  ("ShufflePage로 돌아가지 않고 홈 복귀") 충족.
- **pathParameters 키 이름**: `'deckId'`로 유지 (DrawResultPage route는 pathParameters를 사용
  하지 않지만 go_router가 미사용 키는 무시 — 빌드 실패 없음). 확인: `app_router.dart:153`
  `/draw/result`는 path params 없음. `pushReplacementNamed('draw-result', pathParameters: {...})`
  에 미정의 path param을 전달해도 go_router는 무시한다 (문서화된 동작). 안전성을 위해
  `pathParameters: const {}`로 단순화하는 것이 더 깔끔하지만 Cycle 2 스코프 아님 (TDD Red 071
  C2 단언은 `'draw-result'` 문자열과 `pushReplacementNamed` 패턴만 본다).

**재검토**: TDD Red C2는 `pushReplacementNamed(` + `'draw-result'` 조합 존재만 요구하므로
`pathParameters: {'deckId': widget.deckId}` 포함도 무방. 위 After 코드대로 진행.

#### Commit Message

```
refactor(shuffle): redirect ShufflePage to DrawResultPage (Cycle 2 — 3/4)

ShufflePage(Lv4) 후단을 pushNamed('reading') → pushReplacementNamed('draw-result')로
전환해 ReadingPage 의존을 끊는다 (Brief MA-5).

- TDD Red 071 C1/C2 → Green
- setResult 후 pushReplacement 순서로 뒤로가기 시 홈 복귀 (IC #13)
```

---

### C4 — ReadingPage 삭제 + 라우트/import 정리 + intention 주석 갱신 (TDD Red D1·D2, D3 guard)

#### Approach

1. `app_router.dart`에서 `/reading/:deckId` GoRoute 블록 + `reading_page.dart` import 삭제.
2. `mobile/lib/features/reading/presentation/pages/reading_page.dart` 파일 삭제.
3. `intention_page.dart:42` 주석의 시나리오 3-A 문구 제거 + 사유 갱신.
4. `reading_list_page.dart` / `reading_detail_page.dart` import와 `/readings` + `:readingId`
   라우트는 **보존** (D3 가드 대상, Brief MA-6).

**Depends on**: C3 (ShufflePage가 `reading` 라우트에 의존하지 않아야 함).

#### Current Code

```dart
// mobile/lib/core/router/app_router.dart:1-20 (imports)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/chat/presentation/pages/chat_page.dart';
import '../../features/deck/presentation/pages/deck_selection_page.dart';
import '../../features/draw/presentation/pages/animated_draw_page.dart';
import '../../features/draw/presentation/pages/draw_result_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/reading/domain/entities/spread_type.dart';
import '../../features/reading/presentation/pages/reading_detail_page.dart';
import '../../features/reading/presentation/pages/reading_list_page.dart';
import '../../features/reading/presentation/pages/reading_page.dart';  // ← DELETE
import '../../features/settings/presentation/pages/card_size_settings_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/shuffle/presentation/pages/intention_page.dart';
import '../../features/shuffle/presentation/pages/shuffle_page.dart';
import 'main_shell.dart';
```

```dart
// mobile/lib/core/router/app_router.dart:140-151 (GoRoute — 삭제 대상)
GoRoute(
  path: '/reading/:deckId',
  name: 'reading',
  pageBuilder: (context, state) {
    final deckId = state.pathParameters['deckId']!;
    final spreadType =
        state.extra as SpreadType? ?? SpreadType.single;
    return _fadePage(
        key: state.pageKey,
        child: ReadingPage(deckId: deckId, spreadType: spreadType));
  },
),
```

```dart
// mobile/lib/features/shuffle/presentation/pages/intention_page.dart:38-48 (주석 갱신 대상)
@override
void initState() {
  super.initState();
  // 새 리딩 시작 시 이전 질문 초기화.
  // addPostFrameCallback 사용: initState 내에서 ref.read 호출 가능하나
  // provider 알림이 build 완료 후 안전하게 전파되도록 한다.
  // shuffleStateProvider.clear()는 여기서 금지 (시나리오 3-A: 스택의 ReadingPage null 재빌드)
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      ref.read(readingQuestionProvider.notifier).clear();
    }
  });
}
```

#### After Code

**`app_router.dart` — import 1줄 삭제 + GoRoute 블록 삭제**:

```dart
// mobile/lib/core/router/app_router.dart — C4 (imports)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/chat/presentation/pages/chat_page.dart';
import '../../features/deck/presentation/pages/deck_selection_page.dart';
import '../../features/draw/presentation/pages/animated_draw_page.dart';
import '../../features/draw/presentation/pages/draw_result_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
// import '../../features/reading/domain/entities/spread_type.dart';     // ← 아래 확인
import '../../features/reading/presentation/pages/reading_detail_page.dart';
import '../../features/reading/presentation/pages/reading_list_page.dart';
// reading_page.dart import 삭제됨                                         // ← REMOVED
import '../../features/settings/presentation/pages/card_size_settings_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/shuffle/presentation/pages/intention_page.dart';
import '../../features/shuffle/presentation/pages/shuffle_page.dart';
import 'main_shell.dart';
```

> **`spread_type.dart` import 확인**: `app_router.dart` 내 유일한 `SpreadType` 사용처는
> 삭제되는 GoRoute 블록 안이다. 블록 삭제 후 미사용 import가 되므로 **함께 삭제**한다.
> 제거 대상이 2개 import(파이썬식 표기: `reading_page.dart`, `spread_type.dart`)임을 명확히.

**GoRoute 블록 전체 삭제** (lines 140-151):

```dart
// (아예 삭제 — diff에서 12줄 사라짐)
```

**`intention_page.dart` — 주석 갱신**:

```dart
// mobile/lib/features/shuffle/presentation/pages/intention_page.dart — C4
@override
void initState() {
  super.initState();
  // 새 리딩 시작 시 이전 질문만 초기화.
  // addPostFrameCallback 사용: initState 내에서 ref.read 호출 가능하나
  // provider 알림이 build 완료 후 안전하게 전파되도록 한다.
  // shuffleStateProvider.clear()는 여기서 금지 —
  //   Cycle 2 이후 DrawResultPage가 업스트림 shuffleStateProvider 값을 소비하므로,
  //   IntentionPage가 셔플 결과를 지우면 DrawResultPage가 자체 셔플로 잘못 진입한다.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      ref.read(readingQuestionProvider.notifier).clear();
    }
  });
}
```

**파일 삭제**:

```bash
git rm mobile/lib/features/reading/presentation/pages/reading_page.dart
```

#### Impact Analysis

- **Imports to update**: `app_router.dart`에서 2개 import 삭제 (`reading_page.dart`,
  `spread_type.dart`).
- **Type changes**: 없음.
- **Test updates**:
  - TDD Red D1 (파일 부재) → Green (파일 삭제)
  - TDD Red D2 (라우트/import 부재) → Green
  - TDD Red D3 (reading_list/detail 라우트 유지) → Green 유지 (변경 없음)
- **Config changes**: 없음.
- **회귀 검사**:
  - `reading_providers.dart` (`saveReading`, `addDrawnCard`, `readingQuestionProvider`):
    DrawResultPage가 여전히 사용 → 보존 확인 필요.
  - `reading_list_page.dart`, `reading_detail_page.dart`: 독립 동작. 검증은 `/readings` 홈탭
    이동 → 리스트 렌더 확인 (C4 post-build).
  - `grep -r "ReadingPage\|/reading/:deckId" mobile/lib`: 0 (reading_list/detail 제외) 검증.

#### Commit Message

```
refactor: remove ReadingPage(draw-time) and /reading/:deckId route (Cycle 2 — 4/4)

draw-time용 ReadingPage는 DrawResultPage로 통합되어 dead code. 파일·라우트·
import를 제거하고 intention_page 주석의 "시나리오 3-A" 문구를 갱신한다.
reading_list_page / reading_detail_page / /readings 라우트는 보존 (기록 조회).

- TDD Red 071 D1/D2 → Green
- D3 (reading_list/detail 라우트 유지) Green 유지

Brief MA-6.
```

---

## Test Strategy

### Red → Green Matrix

| Test | Cycle 1 상태 | C1 후 | C2 후 | C3 후 | C4 후 |
|------|:------------:|:-----:|:-----:|:-----:|:-----:|
| A1 `reuses_existing_result` (런타임) | Red | **Green** | Green | Green | Green |
| A2 `null_smoke` (Green-guard) | Green | Green | Green | Green | Green |
| A3 `initState_branch_source` (정적) | Red | **Green** | Green | Green | Green |
| B1 `no_readingRepositoryProvider` (정적) | Red | Red | **Green** | Green | Green |
| B2 `no_saveReading` (정적) | Red | Red | **Green** | Green | Green |
| B3 `delegates_via_pushReplacement` (정적) | Red | Red | **Green** | Green | Green |
| C1 `no_reading_navigation` (정적) | Red | Red | Red | **Green** | Green |
| C2 `navigates_to_draw_result` (정적) | Red | Red | Red | **Green** | Green |
| D1 `reading_page_file_deleted` (정적) | Red | Red | Red | Red | **Green** |
| D2 `reading_route_removed` (정적) | Red | Red | Red | Red | **Green** |
| D3 `reading_list_and_detail_preserved` (Green-guard) | Green | Green | Green | Green | Green |

**핵심 관찰**:

- C1~C4 순서를 거치며 Red → Green으로 단조 증가 (regression 없음).
- A2 / D3는 전 구간 Green 유지 — Green-guard 성격 준수.
- 각 커밋 시점의 빌드 성공은 Red State Verification 섹션에서 검증.

### 빌드 중간 상태 무결성

| Commit | 빌드 성공 조건 |
|--------|----------------|
| C1 | DrawResultPage가 자체 셔플 + 재사용 모두 기존 import로 충족. `flutter analyze` 신규 오류 0건 |
| C2 | `uuid`, `reading.dart`, `reading_providers.dart` import 제거 후 사용처 없음 확인. `_savedReadingId`, `_autoSaved` 필드와 사용처 동기 삭제 확인. GridView 렌더 유지 → 빌드 가능 |
| C3 | `go_router`는 그대로, 함수 시그니처 불변 |
| C4 | `app_router.dart` 미사용 import (`reading_page.dart`, `spread_type.dart`) 동기 삭제. 파일 `reading_page.dart` 삭제 후 호출부 없음 (C3에서 정리 완료) → unresolved import 없음 |

### 수동 회귀 (C4 완료 후)

Cycle 2 완료 후 각 레벨에서 end-to-end를 수동으로 1회씩 확인:

1. **Lv1 (직접)**: 홈 → "바로 뽑기" → 자체 셔플 + 카드 표시 + `/readings`에서 저장 확인
2. **Lv2 (연출)**: 홈 → Lv2 → 연출 진행 → 모든 카드 reveal → DrawResultPage 전환 → 저장 확인
3. **Lv4 (2.5D)**: 홈 → Lv4 → IntentionPage → ShufflePage → "뽑기" → DrawResultPage 전환 → 저장 확인
4. **뒤로가기**: DrawResultPage에서 뒤로가기 → 홈 복귀 (중간 단계 스택에 없어야 함)
5. **/readings 리스트**: 리스트에서 직전 3개 기록 항목 확인

## Deviations from Brief

### 1. GridView vs SpreadLayout (AnimatedDrawPage)

Brief 065 IC #8은 "AnimatedDrawPage에서 `SpreadLayout` / `saveReading` / '한 장 더' UI 블록이
제거되었다 (grep으로 확인)"로 적혀 있으나, 실제 소스는 `SpreadLayout`을 **사용하지 않는다**.
AnimatedDrawPage는 `GridView.builder` (line 397)로 카드를 직접 렌더하고, stagger 슬라이드 +
페이드 애니메이션을 위한 개별 `_animatedCard` 위젯을 쓴다.

**Plan 해석**: Brief의 본의는 "결과 렌더 + 저장 로직 전체"이므로 실제 제거 대상을 다음으로
재해석한다:

- `readingRepositoryProvider` 의존 (`saveReading`, `addDrawnCard` 호출 전체)
- `_autoSave`, `_addOneMore` 메서드
- 하단 버튼 바 (다시 / +N장 / 리셋)
- 관련 필드 (`_savedReadingId`, `_autoSaved`)

**유지 대상**:

- `_buildAnimatedCards`, `_animatedCard`, `_buildCardWidget`, `_buildFrontCard`, `_buildBackCard`,
  `_revealCard` (카드 탭/공개 연출)
- `GridView.builder` 레이아웃
- 질문 입력 + 셔플 전 화면

**근거**: Brief MA-8 ("Scope 확장 금지")이 "AnimatedDrawPage 연출 자체는 변경 대상이 아니다"를
함의. 렌더 수단(SpreadLayout vs GridView)은 연출의 일부이며, 결과 페이지 통일 목적과는 직교.

### 2. `_addOneMore` ↔ `_addDrawnCard` 기능 동치 분석

DrawResultPage(기존 InstantDrawPage 내용 보존)와 ReadingPage(삭제 예정) 모두 "+1 한 장 더"를
구현한다. Brief D7의 우려("`addOneMore` 등 ReadingPage 고유 기능이 DrawResultPage로 마이그레이션
되어야 함")에 대한 코드 비교:

| 측면 | DrawResultPage `_addOneMore` | ReadingPage `_addOneMore(shuffleResult)` |
|------|------------------------------|------------------------------------------|
| 카드 수 증가 | `setState(() => _currentCardCount++)` | `setState(() => _currentCardCount++)` |
| reveal 처리 | 무조건 `_revealedPositions.add` | `showFaceUp`일 때만 `_revealedPositions.add` |
| 저장 연동 | `_savedReadingId != null`이면 `addDrawnCard` 호출 | `_savedReadingId != null`이면 `addDrawnCard` 호출 |
| 질문 소스 | `_questionController.text` | `readingQuestionProvider` (watch) |
| 저장 트리거 | `build()` 내 `_autoSave()` 매 프레임 호출 (flag로 1회) | `allRevealed` 시점 `_autoSave()` |

**동치성**: 저장 연동(`addDrawnCard`) · 카드 수 증가는 동치. reveal 처리는 **의도된 차이**:

- DrawResultPage(Lv1)는 즉시 모든 카드 reveal이 기본 UX → 추가 카드도 즉시 reveal.
- ReadingPage(Lv3/4 경로)는 사용자가 카드를 탭해 뒤집는 제의적 경험이 기본 → `showFaceUp`에 따른
  조건부 reveal.

**Cycle 2에서의 해석**: Lv2/Lv4로 진입한 사용자가 "+1"을 눌렀을 때 DrawResultPage가 무조건
reveal하는 건 Lv1 플로우에 맞춘 동작. Lv4/Lv2 연출 문화와는 미세하게 어긋나지만,

- (a) Lv2/Lv4는 이미 AnimatedDrawPage/ShufflePage에서 모든 카드를 공개한 상태로 DrawResultPage에 도착
  (AnimatedDrawPage의 `_revealedPositions` 누적은 DrawResultPage에 인계되지 않지만, DrawResultPage
  initState에서 `for (i < _currentCardCount) revealedPositions.add(i)`로 모든 초기 카드를 공개).
- (b) 추가 카드(+1)도 동일 UX가 더 일관적 (숨김 → 탭 의식은 Lv2/Lv4에서 이미 종료됨).

→ **이관 없이 DrawResultPage의 현 `_addOneMore`로 충분** 판단. Brief MA-8 ("DrawResultPage UI
변경 금지") 원칙과도 부합. 질문 소스 차이는 "Excluded"에서 명시한 대로 별도 UI Brief로 분리.

### 3. 질문 소스(TextEditingController vs readingQuestionProvider) 통합 보류

ReadingPage는 `readingQuestionProvider`를 watch하고, DrawResultPage는 자체 `_questionController`를
사용한다. Lv2/Lv4 경로에서 IntentionPage가 `readingQuestionProvider.set(question)`으로 질문을
기록했는데 DrawResultPage는 그 값을 UI에 반영하지 않고 자체 입력 필드만 보여준다.

**Cycle 2 결정**: Brief MA-8 ("DrawResultPage UI/UX 변경 금지")에 따라 현 상태 유지. 질문 표시
누락은 별도 UI Brief에서 "`readingQuestionProvider`를 초기값으로 컨트롤러에 주입"하는 단순 보강
으로 해결 가능하나, 범위 확산 방지. Deviations 기록으로 남긴다.

## Risk

| # | Risk | 대응 |
|---|------|------|
| R1 | C2에서 AnimatedDrawPage `showFaceUp=false` 경로의 `_maybeGoToResult`가 모든 카드 탭될 때까지 대기 → 사용자가 일부만 탭하고 이탈 시 DrawResultPage로 안 감 | AppBar 홈 버튼으로 회복. Cycle 2 스코프 아님. 별도 UI Brief에서 진행률 표시/자동 reveal 검토 |
| R2 | C1 "다시" 버튼에서 `_reuseUpstreamResult` 리셋 누락 시 무한 재사용 루프 | Impact Analysis에서 명시. 버튼 onPressed에 `_reuseUpstreamResult = false` 추가 |
| R3 | C4 직후 `flutter analyze`에 미사용 import 경고 | `spread_type.dart` import 동기 삭제로 방지. C4 commit 전 `flutter analyze` 실행으로 확인 |
| R4 | C3의 `pathParameters: {'deckId': ...}`가 path 없는 라우트에 전달되어 경고 또는 오류 | go_router는 미정의 path param을 무시. 경고 없음 확인 (C3 commit 전 `flutter run --debug`로 셔플 → 결과 1회 수동 테스트) |
| R5 | IntentionPage `shuffleStateProvider.clear()` 금지 조건이 실제로 어기면 Lv4 플로우 전체 깨짐 | 주석 갱신 시 "금지" 원칙만 명확히. 실질 동작 변경 없음 (코드 변화 0줄) |
| R6 | `reading_providers.dart`의 `addDrawnCard` / `saveReading`이 ReadingPage에서만 호출되지 않는지 확인 필요 | DrawResultPage도 사용 중 (확인 완료). Provider 자체는 보존 |
| R7 | Lv2(AnimatedDrawPage) `pushReplacementNamed` 후 DrawResultPage initState에서 재사용 경로로 들어갔으나 `readingQuestionProvider`가 clear되어 질문 표시 안 됨 | AnimatedDrawPage의 `_startDraw`가 진입 시 `ref.read(readingQuestionProvider.notifier).clear()`를 호출 후 `_questionController.text`로 다시 set — Lv2 경로에서 readingQuestionProvider에 질문이 저장됨. DrawResultPage는 재사용 경로에서 `readingQuestionProvider.clear()`를 **호출하지 않도록** C1 After code에 이미 반영 (기존 `clear`가 자체 셔플 분기로 이동) |

## Rollback

각 커밋은 독립 revert 가능하나, 의존 역순으로 되돌려야 한다:

- **C4만 revert**: ReadingPage 파일과 `/reading/:deckId` 라우트가 복원되나 ShufflePage(C3 이후)는
  여전히 `draw-result`로 감 → 라우트는 죽은 코드가 되나 빌드는 성공.
- **C3만 revert** (C4 유지 상태): ShufflePage가 `reading` 라우트로 가려고 하나 C4에서 이미 삭제됨
  → 런타임 오류. **이 조합 금지**.
- **권장 rollback 순서**: C4 → C3 → C2 → C1 (LIFO).
- **Emergency**: C4까지 완료 후 문제 발견 시 `git revert <C4-SHA> <C3-SHA>`를 단일 revert 커밋으로
  생성하면 라우트/파일 복원 + ShufflePage 호출부 원복이 원자적으로 수행됨.

## Implementation Checklist

- [ ] **C1**: DrawResultPage `_executeDraw` 분기 + `_reuseUpstreamResult` flag 도입
  - [ ] `initState`에서 `ref.read(shuffleStateProvider)` 단일 지점 판단
  - [ ] 재사용 경로: `clear()` 금지, upstream 객체 `_shuffleResult`에 대입 (identity 유지)
  - [ ] 자체 셔플 경로: 기존 로직 유지
  - [ ] "다시" 버튼 onPressed에 `_reuseUpstreamResult = false` 추가
  - [ ] `flutter test test/features/draw/draw_result_page_initstate_test.dart` → A1/A2/A3 all PASS
  - [ ] `flutter analyze`, `flutter build apk --debug` 성공
  - [ ] Commit: `feat(draw): branch DrawResultPage init on shuffleStateProvider (Cycle 2 — 1/4)`

- [ ] **C2**: AnimatedDrawPage 결과 블록 제거 + pushReplacement
  - [ ] `uuid`, `reading.dart`, `reading_providers.dart` import 삭제
  - [ ] `_autoSave`, `_addOneMore` 메서드 삭제
  - [ ] `_savedReadingId`, `_autoSaved` 필드 삭제
  - [ ] build() 내 결과 시 호출 `_autoSave()` 2개 지점 삭제
  - [ ] 하단 버튼 바 (`_animationComplete` 조건 Padding) 삭제
  - [ ] `_playAnimations` 말단에 `_maybeGoToResult()` 호출
  - [ ] `_revealCard`의 저장 분기를 `_maybeGoToResult` 호출로 교체
  - [ ] `_maybeGoToResult` 신규 메서드 추가 (pushReplacementNamed)
  - [ ] `flutter test test/features/draw/animated_draw_reduced_test.dart` → B1/B2/B3 PASS
  - [ ] `flutter analyze`, `flutter build apk --debug` 성공
  - [ ] Commit: `refactor(draw): AnimatedDrawPage delegates result to DrawResultPage (Cycle 2 — 2/4)`

- [ ] **C3**: ShufflePage `_goToReading` pushReplacementNamed 전환
  - [ ] `pushNamed('reading', ...)` → `pushReplacementNamed('draw-result', pathParameters: {'deckId': widget.deckId})`
  - [ ] `flutter test test/features/shuffle/shuffle_page_navigation_test.dart` → C1/C2 PASS
  - [ ] `flutter analyze`, `flutter build apk --debug` 성공
  - [ ] Commit: `refactor(shuffle): redirect ShufflePage to DrawResultPage (Cycle 2 — 3/4)`

- [ ] **C4**: ReadingPage 삭제 + 라우트/import 정리 + intention 주석 갱신
  - [ ] `git rm mobile/lib/features/reading/presentation/pages/reading_page.dart`
  - [ ] `app_router.dart`에서 `reading_page.dart` import 삭제
  - [ ] `app_router.dart`에서 `spread_type.dart` import 삭제 (미사용 확인 후)
  - [ ] `app_router.dart`에서 `/reading/:deckId` GoRoute 블록 삭제
  - [ ] `intention_page.dart:42` 주석 갱신 (시나리오 3-A 문구 제거 + 새 사유)
  - [ ] `flutter test test/core/router/reading_page_removed_test.dart` → D1/D2/D3 PASS
  - [ ] `flutter analyze`: unresolved import 0건
  - [ ] `grep -rE "ReadingPage|/reading/:deckId" mobile/lib | grep -v reading_list_page | grep -v reading_detail_page` → 0건
  - [ ] `flutter build apk --debug` 성공
  - [ ] Commit: `refactor: remove ReadingPage(draw-time) and /reading/:deckId route (Cycle 2 — 4/4)`

- [ ] **최종 검증**:
  - [ ] 전체 TDD Red 071 테스트 스위트: `flutter test test/features/draw/draw_result_page_initstate_test.dart test/features/draw/animated_draw_reduced_test.dart test/features/shuffle/shuffle_page_navigation_test.dart test/core/router/reading_page_removed_test.dart` → **+11 -0**
  - [ ] `flutter analyze` 회귀 없음 (Cycle 1 baseline 3 info → 유지 또는 감소)
  - [ ] `flutter build apk --debug` 성공
  - [ ] (수동) Lv1/Lv2/Lv4 end-to-end 회귀 — /verify-trace 단계에서 수행

## Verification Assertions

| Level | Assertion | Verification Method | Expected Result |
|-------|-----------|-------------------|-----------------|
| L1-Build | 각 커밋 직후 APK 빌드 | `cd mobile && flutter build apk --debug` | `✓ Built build/app/outputs/flutter-apk/app-debug.apk` |
| L1-Build | analyze 회귀 없음 | `cd mobile && flutter analyze` | 0 errors, info ≤ Cycle 1 baseline (3) |
| L2-CLI | TDD Red 071 9개 Green 전환 | `cd mobile && flutter test <071 4 files>` | `+11 -0` |
| L2-CLI | legacy 심볼 0건 | `grep -rE "ReadingPage\|/reading/:deckId\|name: 'reading'" mobile/lib \| grep -v reading_list_page \| grep -v reading_detail_page` | 0 hits |
| L2-CLI | AnimatedDrawPage의 readingRepositoryProvider 참조 부재 | `grep -n "readingRepositoryProvider\|saveReading(\|addDrawnCard(" mobile/lib/features/draw/presentation/pages/animated_draw_page.dart` | 0 hits |
| L2-CLI | ShufflePage의 `reading` 내비 부재 | `grep -n "pushNamed(.reading.\|pushReplacementNamed(.reading.\|context\.pushNamed(..reading.." mobile/lib/features/shuffle/presentation/pages/shuffle_page.dart` | 0 hits |
| L2-CLI | `reading_page.dart` 파일 부재 | `ls mobile/lib/features/reading/presentation/pages/reading_page.dart` | No such file |
| L3-Browser | Lv1 홈 → 결과 진입 smoke | 수동 `flutter run` → "바로 뽑기" 탭 → 카드 3장 표시 | DrawResultPage mount + `/readings`에 1개 항목 |
| L3-Browser | Lv4 홈 → IntentionPage → ShufflePage → DrawResultPage | 수동 `flutter run` → Lv4 플로우 1회 | 뒤로가기 1회로 홈 복귀 (ShufflePage 미노출) |
| L4-Trace | Brief MA-3 (upstream→DrawResultPage 상태 인계) | `draw_result_page_initstate_test.dart` A1 | identity 유지 PASS |
| L4-Trace | Brief MA-9 (initState 1회 분기) | 소스 grep + A3 테스트 | 분기 존재, 1지점만 판단 |

## References

| Resource | Path/URL | Related Content |
|----------|---------|-----------------|
| Brief 065 | `docs/03_tarot_shuffle/065_Brief_unified_result_page.md` | MA-3, MA-4, MA-5, MA-6, MA-8, MA-9; IC #5–#22 |
| Scope 066 | `docs/03_tarot_shuffle/066_Scope_unified_result_page.md` | Cycle 2 분해 |
| TDD Red 071 | `docs/03_tarot_shuffle/071_TDD_Red_flow_cycle2.md` | 9 Red + 2 Green-guard 테스트 |
| Cycle 1 Impl 069 | `docs/03_tarot_shuffle/069_Impl_rename_cycle1.md` | 리네임 완료 기준선 |
| Cycle 1 Verify 070 | `docs/03_tarot_shuffle/070_Verify_rename_cycle1.md` | Cycle 2 시작 전제 |

## 미비점 및 확장 필요 영역

### Plan 미비점 (makeplan 기록)

| # | 항목 | 심각도 | 설명 |
|---|------|--------|------|
| 1 | AnimatedDrawPage `showFaceUp=false` 이탈 가능성 | Medium | 사용자가 모든 카드를 탭하기 전에 뒤로가기 시 DrawResultPage로 안 감. 홈 버튼으로 회복 가능하나 UX 저하. 별도 UI Brief로 분리 권장 |
| 2 | 질문 소스 불일치 (controller vs provider) | Medium | Lv2/Lv4로 DrawResultPage 진입 시 `readingQuestionProvider` 값이 UI에 반영되지 않음. MA-8에 따라 Cycle 2 스코프 아님. 별도 UI Brief |
| 3 | Brief IC #22 (백그라운드 복귀 시 결과 보존) 검증 수단 부재 | Low | 수동 시나리오만 가능. 자동 테스트 추가는 Riverpod `keepAlive` 동작 가정 검증으로 별도 |
| 4 | Brief IC #23 (mock 가능성) | Low | DrawResultPage 자체 테스트 격리는 A1/A2/A3으로 커버되나 전체 mock 시나리오는 별도 |
| 5 | `_goToReading` 메서드명 잔존 | Low | 내부 private이라 리팩터는 선택. 의미 명확화는 추후 |
| 6 | AnimatedDrawPage 삭제 후 `_shuffleExecuted` / `_animationComplete` 필드의 UX상 용도는 Cycle 2에서 유지되나, 향후 "연출만 담당"이 확정되면 이들 조건을 더 단순하게 재구성 가능 | Low | Cycle 2 스코프 아님 |

### Implementation 미비점 (implementation 기록)

| # | 항목 | 심각도 | 설명 |
|---|------|--------|------|

### Verification 미비점 (verify 기록)

| # | 항목 | 심각도 | 설명 |
|---|------|--------|------|
