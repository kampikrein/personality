---
id: "009"
type: plan
title: "Dev Tuner Screen Integration (Cycle 2)"
created: 2026-03-18
traces_scope: "001"
traces_research: "007"
summary: >
  4개 Flutter 화면에 Dev Tuner 변수 등록. 총 9개 tunable 변수를 StateProvider로
  선언하고 하드코딩 값 교체. Flame 컴포넌트는 별도 사이클로 분리.
keywords: [dev-tuner, screen-integration, tunable-variables, home, reading, intention, deck]
---

# 009 — Dev Tuner Screen Integration (Cycle 2)

## Goal

Cycle 1에서 구축한 Dev Tuner 인프라에 4개 화면의 튜닝 변수를 등록한다.
각 화면에서 하드코딩된 UI 파라미터를 StateProvider로 교체하여 Dev Tuner에서 실시간 조정 가능하게 한다.

## Scope

### Included
| # | Item | Description |
|---|------|-------------|
| 1 | Home Page 변수 4개 | gradientCenterY, gradientRadius, buttonHeight, titleIconSize |
| 2 | Reading Page 변수 2개 | cardHeightFactor, contentPadding |
| 3 | Intention Page 변수 2개 | iconSize, contentPadding |
| 4 | DeckSelection Page 변수 1개 | listPadding |

### Excluded
| Item | Reason/Timeline |
|------|-----------------|
| Flame 게임 컴포넌트 (card_body, tarot_game) | forge2d 실시간 반영 미확인 — 별도 사이클 |
| CardRevealWidget (flipDuration) | StatefulWidget → ConsumerWidget 변환 필요 — 별도 |
| ShufflePage (cameraRotateX) | Flame GameWidget 내부 — 별도 |
| int/bool/enum 타입 | TunableDouble만 지원 (Cycle 1 제약) |

## Structural Decisions

No structural decisions required — Cycle 1 패턴(StateProvider + registerIfAbsent) 반복 적용.

---

## File Change Summary

### Modified Files
| # | File Path | Change Description |
|---|-----------|-------------------|
| 1 | `mobile/lib/features/home/presentation/pages/home_page.dart` | 4개 StateProvider + 등록 + 하드코딩 교체 |
| 2 | `mobile/lib/features/reading/presentation/pages/reading_page.dart` | 2개 StateProvider + 등록 + 하드코딩 교체 |
| 3 | `mobile/lib/features/shuffle/presentation/pages/intention_page.dart` | 2개 StateProvider + 등록 + 하드코딩 교체 |
| 4 | `mobile/lib/features/deck/presentation/pages/deck_selection_page.dart` | 1개 StateProvider + 등록 + 하드코딩 교체 |

---

## Step 1 — Home Page (4 변수)

### Approach
파일 상단에 StateProvider 4개 선언. build() 시작부에 registerIfAbsent 호출.
하드코딩된 값을 ref.watch(provider)로 교체.

### Current Code
```dart
// home_page.dart:1-8 (imports)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// ... existing imports
```

### After Code
```dart
// home_page.dart (imports 추가)
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/dev_tuner/tunable_var.dart';
import '../../../../core/dev_tuner/tuner_registry.dart';
// ... existing imports

// ── Dev Tuner 변수 ──
final homeGradientCenterYProvider = StateProvider<double>((ref) => -0.3);
final homeGradientRadiusProvider = StateProvider<double>((ref) => 1.2);
final homeButtonHeightProvider = StateProvider<double>((ref) => 56);
final homeTitleIconSizeProvider = StateProvider<double>((ref) => 40);
```

### Current Code
```dart
// home_page.dart:34-46 (build 시작부)
  Widget build(BuildContext context) {
    final readingsAsync = ref.watch(watchReadingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.3),
            radius: 1.2,
            colors: [Color(0xFF2A1B3D), Color(0xFF0D0A14)],
```

### After Code
```dart
// home_page.dart (build 시작부 — 등록 + watch)
  Widget build(BuildContext context) {
    final readingsAsync = ref.watch(watchReadingsProvider);
    final theme = Theme.of(context);

    // Dev Tuner 등록
    if (kDebugMode) {
      ref.read(devTunerRegistryProvider.notifier).registerIfAbsent('home', [
        TunableDouble(label: 'gradCenterY', provider: homeGradientCenterYProvider, min: -1.0, max: 1.0, step: 0.1),
        TunableDouble(label: 'gradRadius', provider: homeGradientRadiusProvider, min: 0.5, max: 3.0, step: 0.1),
        TunableDouble(label: 'btnHeight', provider: homeButtonHeightProvider, min: 40, max: 72, step: 4),
        TunableDouble(label: 'iconSize', provider: homeTitleIconSizeProvider, min: 24, max: 64, step: 4),
      ]);
    }

    final gradCenterY = ref.watch(homeGradientCenterYProvider);
    final gradRadius = ref.watch(homeGradientRadiusProvider);
    final btnHeight = ref.watch(homeButtonHeightProvider);
    final iconSize = ref.watch(homeTitleIconSizeProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, gradCenterY),
            radius: gradRadius,
            colors: const [Color(0xFF2A1B3D), Color(0xFF0D0A14)],
```

### After Code (하드코딩 교체)
```dart
// home_page.dart — 아이콘 크기
Icon(Icons.nights_stay, color: theme.colorScheme.primary, size: iconSize),

// home_page.dart — 버튼 높이 (2곳)
SizedBox(height: btnHeight, child: FilledButton.icon(...)),
SizedBox(height: btnHeight, child: ElevatedButton(...)),
```

---

## Step 2 — Reading Page (2 변수)

### Approach
카드 스프레드 높이 비율과 콘텐츠 패딩을 튜닝 가능하게.

### After Code
```dart
// reading_page.dart (파일 상단 추가)
import 'package:flutter/foundation.dart';
import '../../../../core/dev_tuner/tunable_var.dart';
import '../../../../core/dev_tuner/tuner_registry.dart';

final readingCardHeightFactorProvider = StateProvider<double>((ref) => 0.45);
final readingContentPaddingProvider = StateProvider<double>((ref) => 16);
```

```dart
// reading_page.dart (build 시작부 — 등록)
    if (kDebugMode) {
      ref.read(devTunerRegistryProvider.notifier).registerIfAbsent('reading', [
        TunableDouble(label: 'cardHeight%', provider: readingCardHeightFactorProvider, min: 0.3, max: 0.7, step: 0.05),
        TunableDouble(label: 'padding', provider: readingContentPaddingProvider, min: 8, max: 32, step: 4),
      ]);
    }
    final cardHeightFactor = ref.watch(readingCardHeightFactorProvider);
    final contentPadding = ref.watch(readingContentPaddingProvider);
```

```dart
// reading_page.dart — 하드코딩 교체
// 기존: padding: const EdgeInsets.all(16),
padding: EdgeInsets.all(contentPadding),

// 기존: height: MediaQuery.of(context).size.height * 0.45,
height: MediaQuery.of(context).size.height * cardHeightFactor,
```

---

## Step 3 — Intention Page (2 변수)

### After Code
```dart
// intention_page.dart (파일 상단 추가, part 선언 아래)
import 'package:flutter/foundation.dart';
import '../../../../core/dev_tuner/tunable_var.dart';
import '../../../../core/dev_tuner/tuner_registry.dart';

final intentionIconSizeProvider = StateProvider<double>((ref) => 48);
final intentionPaddingProvider = StateProvider<double>((ref) => 24);
```

```dart
// intention_page.dart (build 시작부)
    if (kDebugMode) {
      ref.read(devTunerRegistryProvider.notifier).registerIfAbsent('intention', [
        TunableDouble(label: 'iconSize', provider: intentionIconSizeProvider, min: 32, max: 72, step: 4),
        TunableDouble(label: 'padding', provider: intentionPaddingProvider, min: 12, max: 48, step: 4),
      ]);
    }
    final iconSize = ref.watch(intentionIconSizeProvider);
    final contentPadding = ref.watch(intentionPaddingProvider);
```

```dart
// intention_page.dart — 하드코딩 교체
// 기존: padding: const EdgeInsets.all(24),
padding: EdgeInsets.all(contentPadding),
// 기존: size: 48
Icon(Icons.self_improvement, color: theme.colorScheme.primary, size: iconSize),
```

---

## Step 4 — Deck Selection Page (1 변수)

### After Code
```dart
// deck_selection_page.dart (파일 상단 추가)
import 'package:flutter/foundation.dart';
import '../../../../core/dev_tuner/tunable_var.dart';
import '../../../../core/dev_tuner/tuner_registry.dart';

final deckListPaddingProvider = StateProvider<double>((ref) => 16);
```

```dart
// deck_selection_page.dart (build 시작부 — ConsumerWidget이므로 ref 바로 사용)
    if (kDebugMode) {
      ref.read(devTunerRegistryProvider.notifier).registerIfAbsent('deck', [
        TunableDouble(label: 'listPad', provider: deckListPaddingProvider, min: 8, max: 32, step: 4),
      ]);
    }
    final listPadding = ref.watch(deckListPaddingProvider);
```

```dart
// deck_selection_page.dart — 하드코딩 교체
// 기존: padding: const EdgeInsets.all(16),
padding: EdgeInsets.all(listPadding),
```

---

## Step 5 — 빌드 검증

### Approach
`flutter analyze` — 정적 분석. 에뮬레이터에서 각 화면 진입 시 Dev Tuner에 해당 화면 변수 표시 확인.

---

## Considerations & Trade-offs

### Alternative Approaches
| 접근법 | 비채택 이유 |
|--------|-----------|
| 모든 49개 변수 한번에 등록 | Flame 컴포넌트 실시간 반영 미확인, 범위 과대 |
| CardRevealWidget 변환 | StatefulWidget → ConsumerStatefulWidget 변환 + 상위 로직 변경 필요 |

### Potential Risks
| 리스크 | 완화 |
|--------|------|
| build()에서 registerIfAbsent 반복 호출 | containsKey 체크로 1회만 실행 |
| const 제거 (BoxDecoration 등) | kDebugMode 가드로 릴리즈에서 const 최적화 유지 |

### Backward Compatibility
- StateProvider 기본값 = 기존 하드코딩 값 → 동작 변경 없음
- kDebugMode 가드 → 릴리즈 빌드에서 등록 코드 tree-shaking 제거

## Implementation Checklist

- [x] Step 1: Home Page 변수 4개 등록
- [x] Step 2: Reading Page 변수 2개 등록
- [x] Step 3: Intention Page 변수 2개 등록
- [x] Step 4: Deck Selection Page 변수 1개 등록
- [x] Step 5: 빌드 검증

## Verification Assertions

| Level | Assertion | Verification Method | Expected Result |
|-------|-----------|-------------------|-----------------|
| L1-Build | Dart 정적 분석 통과 | `flutter analyze` | 에러 0 |
| L3-Browser | Home에서 Dev Tuner 열기 | 에뮬레이터 | 4개 변수 (gradCenterY, gradRadius, btnHeight, iconSize) |
| L3-Browser | Reading 화면 Dev Tuner | 에뮬레이터 | 2개 변수 + global 3개 |
| L3-Browser | 화면 전환 시 변수 목록 변경 | 에뮬레이터 | 라우트별 다른 변수 표시 |

## References

| Resource | Path/URL | Related Content |
|----------|---------|-----------------|
| Cycle 1 Plan | docs/15_dev_tuner/008_Plan_tuner_system.md | DevTuner 인프라 |
| Research (변수 목록) | docs/15_dev_tuner/005_Agent_screen_variables.md | 화면별 하드코딩 값 |
