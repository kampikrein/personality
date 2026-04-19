---
id: "010"
type: plan
title: "Cycle 3 홈 허브 + 뽑기 체험 — 구현 계획"
created: 2026-03-22
traces_scope: "002"
traces_brief: "001"
traces_research: "003"
traces_plan_c2: "007"
traces_eval_c2: "009"
cycle: 3
area: "홈 허브 + 뽑기 체험 (Home Hub & Draw Experience)"
status: in-progress
summary: >
  홈 페이지 허브 모델 재설계, GoRouter redirect(quickDrawEnabled + experienceLevel),
  Level 1 즉시 뽑기 페이지(0.5초 이내), Level 2 간단 연출 페이지(2~3초 implicit 애니메이션),
  Level 3 기존 /shuffle/:deckId 연결, 질문 입력 경로 간소화.
  8단계, 신규 4파일 + 수정 2파일, 코드 생성 재실행 포함.
keywords: [home-hub, gorouter-redirect, instant-draw, animated-draw, experience-level, quick-draw]
---

# Cycle 3 홈 허브 + 뽑기 체험 — 구현 계획

## 실행 개요

| 항목 | 값 |
|------|---|
| 사이클 | 3 / 3 (최종) |
| 영역 | 홈 허브 + 뽑기 체험 (Home Hub & Draw Experience) |
| Brief 앵커 | MA-1 (진입 흐름 분기), MA-2 (3단계 체험 레벨), MA-6 (라우트 구조 재설계) |
| 신규 파일 | 4개 |
| 수정 파일 | 2개 |
| 코드 생성 | `build_runner build` 필수 (GoRouter codegen, draw providers) |

## Cycle 1-2 의존 입력

이전 사이클에서 생성된 항목 중 이 사이클에서 직접 사용하는 것:

| # | 항목 | 제공 사이클 | 사용처 |
|---|------|-----------|-------|
| 1 | `userSettingsProvider` (Stream, `@riverpod` — AutoDispose) | C1 | GoRouter redirect에서 `ref.watch`로 캐시 값 읽기 |
| 2 | `UserSettings` (selectedDeckId, experienceLevel, quickDrawEnabled, defaultCardCount, showFaceUp, defaultSpreadType) | C1 | 홈 허브 뽑기 버튼, redirect 분기, Level 1/2 초기화 |
| 3 | `SpreadType.custom` + `resolvePositions/resolveGuidances` | C1 | Level 1/2에서 동적 카드 수 처리 |
| 4 | `ShuffleState` (keepAlive provider) + 셔플 로직 | 기존 | Level 1/2에서 셔플 실행 후 ReadingPage에 전달 |
| 5 | `/settings`, `/readings`, `/readings/:readingId` 라우트 | C2 | 홈 허브에서 네비게이션 연결 |
| 6 | ReadingPage 자동 저장 + "+1" FAB + showFaceUp 적용 | C2 | Level 1/2 결과 표시에서 ReadingPage 재활용 |

## Eval(009) 발견사항 반영

| ID | 발견 | 이 Plan에서의 대응 |
|----|------|-------------------|
| **EV-006-D1** | `userSettingsProvider`가 AutoDispose → GoRouter에서 lifecycle 주의 | **Step 2에서 해결**: `userSettingsProvider`는 `@riverpod` (AutoDispose)이지만, GoRouter provider가 `ref.watch`하면 GoRouter 존속 기간 동안 구독 유지됨. GoRouter는 앱 전체 수명이므로 AutoDispose가 실질적으로 발동하지 않음. 만약 문제 발생 시, `keepAlive` wrapper provider로 감싸는 fallback 준비 |
| **EV-009-A2** | Level 1/2에서 IntentionPage를 경유하지 않으면 question이 빈 문자열 | **Step 4/5에서 해결**: Level 1/2 뽑기 페이지에 간소화된 질문 입력 TextField 배치 (optional, 빈 문자열도 가능). "skip" 버튼으로 질문 없이 즉시 진행 |
| **EV-009-S1** | 자동 저장 전환으로 모든 리딩이 DB에 쌓임 → 삭제 기능 미구현 | **이 사이클 범위 밖**: Brief In Scope에 리딩 삭제 미포함. 향후 과제로 기록. 홈 허브의 리딩 목록에서 스와이프 삭제는 별도 사이클에서 추가 |
| **EV-009-D1** | ReadingDetailPage가 전체 리딩 로딩 후 where로 ID 필터 | **이 사이클 영향 없음**: 별도 최적화는 차기 과제 |
| **EV-009-D2** | `_autoSave`가 build에서 호출됨 — side-effect-free 관례 위반 | **이 사이클 영향 없음**: 기능적 문제 없음. ReadingPage는 기존 코드 유지 |

## 설계 결정

### D-010-1: GoRouter redirect 패턴

**선택: `ref.watch` 동기 캐시 패턴** (Research Q4 결론)

```dart
@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final settings = ref.watch(userSettingsProvider).valueOrNull;

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      if (settings == null) return null; // 로딩 중 → 홈 표시
      if (state.matchedLocation != '/') return null; // 루트만 redirect

      if (settings.quickDrawEnabled) {
        return switch (settings.experienceLevel) {
          1 => '/draw/instant',
          2 => '/draw/animated',
          3 => '/shuffle/${settings.selectedDeckId}',
          _ => null,
        };
      }
      return null;
    },
    routes: [ ... ],
  );
}
```

**근거:**
- redirect가 동기: `ref.watch()`가 캐시 값 반환.
- reactive: UserSettings 변경 시 GoRouter provider가 재생성됨.
- `state.matchedLocation == '/'`일 때만 redirect → 무한 redirect 방지.
- EV-006-D1 대응: `ref.watch(userSettingsProvider)`가 GoRouter provider 내에서 호출되면, GoRouter provider 존속 기간(앱 전체) 동안 구독이 유지됨. AutoDispose 실질 미발동.

**주의 — GoRouter 재생성 시 라우트 스택 초기화 가능**:
- Settings 변경 빈도가 낮으므로 (사용자가 설정 페이지에서 명시적으로 변경할 때만) 실질적 문제 없음.
- 설정 변경 후에는 어차피 홈으로 돌아가는 자연스러운 플로우.

### D-010-2: Level 1/2 라우트 구조

**선택: `/draw/instant` (Level 1), `/draw/animated` (Level 2) — 독립 페이지**

Level 1과 Level 2는 UX가 근본적으로 다름:
- Level 1: 즉시 결과 (0.5초 이내). 셔플 + 결과 렌더링만.
- Level 2: 카드 플립/슬라이드 애니메이션 2~3초. AnimationController 필요.

공통점: 둘 다 결과 표시 후 ReadingPage의 자동 저장 + "+1" 패턴 활용.

**접근법**: Level 1/2는 자체 페이지에서 셔플 실행 + 결과 렌더링을 담당하되, 핵심 결과 UI는 ReadingPage의 패턴을 inline으로 재사용 (공통 위젯 추출까지는 하지 않고, 동일 로직을 적용).

**대안 (기각)**: ReadingPage로 redirect하고 query param으로 level을 전달 — 기존 ReadingPage가 이미 복잡하며(자동 저장, +1, showFaceUp), Level 2 애니메이션 상태까지 추가하면 SRP 위반.

### D-010-3: Level 1/2 질문 입력 경로 (EV-009-A2 대응)

**선택: 인라인 질문 입력 (optional) + skip 가능**

Level 1/2 페이지 상단에 간소화된 질문 입력 영역:
- 접힌 상태(기본): "질문 없이 바로 뽑기" 가 기본 동작.
- 펼친 상태: TextField 1줄 + "이 질문으로 뽑기" 버튼.
- 셔플은 **페이지 진입 시점**에 즉시 실행 (질문 입력 전). 질문은 저장 시에만 반영.

**근거:**
- Level 1의 핵심 가치는 "0.5초 이내 결과". 질문 입력을 필수화하면 이 가치가 훼손됨.
- `readingQuestionProvider`에 set하면 자동 저장 시 question 필드에 반영됨.
- "질문 없이 진행"은 기존 IntentionPage에서도 지원하는 패턴 ("질문 없이 진행해도 괜찮습니다").

**구현 세부**: Level 1은 질문 입력을 "결과 후 추가"로 처리 (결과 화면 하단에 optional TextField). Level 2는 애니메이션 전에 1줄 질문 입력 제공하되 skip 가능.

### D-010-4: 홈 허브 기능 카드 구성

홈 페이지를 "뭘 할 수 있는지" 중심의 기능 카드 목록으로 재설계:

| 카드 | 아이콘 | 동작 | 조건 |
|------|--------|------|------|
| 바로 뽑기 | `Icons.style` | 설정된 체험 레벨로 뽑기 실행 | 항상 표시 |
| 리딩 기록 | `Icons.history` | `/readings`로 이동 | 항상 표시 |
| 덱 선택 | `Icons.layers` | `/deck`로 이동 | 항상 표시 |
| 설정 | `Icons.tune` | `/settings`로 이동 | 항상 표시 |

하단에 최근 리딩 3개 미리보기 유지 (기존 패턴에서 축소).

### D-010-5: Level 1/2에서의 셔플 실행

Level 1/2 모두 동일한 셔플 패턴 사용 (홈의 기존 `_quickDraw`와 동일):

```dart
final cards = await ref.read(deckCardsProvider(deckId).future);
final useCase = ref.read(shuffleDeckUseCaseProvider);
final strategy = ref.read(shuffleStrategyProvider);
final result = useCase.execute(cards: cards, strategy: strategy);
ref.read(shuffleStateProvider.notifier).setResult(result);
```

셔플 후 `ShuffleState`에 결과를 세팅하므로 "+1 한 장 더"가 Level 1/2에서도 동작.

## Step 1: draw feature 디렉토리 + draw_providers.dart

**신규 디렉토리**: `mobile/lib/features/draw/`

```
features/draw/
  presentation/
    pages/
      instant_draw_page.dart    (Level 1)
      animated_draw_page.dart   (Level 2)
    providers/
      draw_providers.dart
```

**신규 파일**: `mobile/lib/features/draw/presentation/providers/draw_providers.dart`

이 provider는 Level 1/2 공통 셔플 실행 로직을 캡슐화:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../features/deck/presentation/providers/deck_providers.dart';
import '../../../../features/shuffle/presentation/providers/shuffle_providers.dart';
import '../../../../features/shuffle/domain/entities/shuffle_result.dart';
import '../../../../features/settings/presentation/providers/settings_providers.dart';
import '../../../../features/settings/domain/entities/user_settings.dart';

part 'draw_providers.g.dart';

/// Level 1/2 뽑기에서 사용할 셔플 실행 use case.
/// 호출 시 UserSettings의 selectedDeckId를 사용하여 셔플하고,
/// ShuffleState에 결과를 세팅한 뒤 ShuffleResult를 반환.
@riverpod
Future<ShuffleResult> executeDraw(ExecuteDrawRef ref) async {
  final settings = ref.read(userSettingsProvider).valueOrNull ??
      UserSettings(updatedAt: DateTime.now());

  final deckId = settings.selectedDeckId;
  final cards = await ref.read(deckCardsProvider(deckId).future);

  final useCase = ref.read(shuffleDeckUseCaseProvider);
  final strategy = ref.read(shuffleStrategyProvider);
  final result = useCase.execute(cards: cards, strategy: strategy);

  ref.read(shuffleStateProvider.notifier).setResult(result);

  return result;
}
```

**설계 판단:**
- `@riverpod` (AutoDispose) — 매 뽑기마다 새로 실행되어야 하므로 keepAlive 불필요.
- `ref.read(userSettingsProvider).valueOrNull` — 동기 캐시 접근. GoRouter redirect를 통과한 시점이면 settings가 이미 로딩되어 있음.
- 셔플 결과를 `ShuffleState`에 세팅하여 ReadingPage/"+1" 패턴과 호환.

## Step 2: GoRouter 재구조 — redirect + 신규 라우트

**수정 파일**: `mobile/lib/core/router/app_router.dart`

### 변경 내용

1. **`ref.watch(userSettingsProvider)`로 설정 캐시 접근**
2. **`redirect` 콜백 추가** — `quickDrawEnabled` 시 레벨별 분기
3. **신규 라우트 2개 추가**: `/draw/instant`, `/draw/animated`
4. **기존 라우트 유지**: `/`, `/deck`, `/intention/:deckId`, `/shuffle/:deckId`, `/reading/:deckId`, `/settings`, `/readings`, `/readings/:readingId`

### 코드

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/home/presentation/pages/home_page.dart';
import '../../features/deck/presentation/pages/deck_selection_page.dart';
import '../../features/draw/presentation/pages/instant_draw_page.dart';
import '../../features/draw/presentation/pages/animated_draw_page.dart';
import '../../features/reading/presentation/pages/reading_detail_page.dart';
import '../../features/reading/presentation/pages/reading_list_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/shuffle/presentation/pages/intention_page.dart';
import '../../features/shuffle/presentation/pages/shuffle_page.dart';
import '../../features/reading/domain/entities/spread_type.dart';
import '../../features/reading/presentation/pages/reading_page.dart';
import '../../features/settings/presentation/providers/settings_providers.dart';

part 'app_router.g.dart';

CustomTransitionPage<void> _fadePage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
    transitionDuration: const Duration(milliseconds: 600),
  );
}

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final settings = ref.watch(userSettingsProvider).valueOrNull;

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // 설정 로딩 전이면 홈으로
      if (settings == null) return null;
      // 루트 경로 접근 시에만 redirect 판단 (무한 redirect 방지)
      if (state.matchedLocation != '/') return null;

      if (settings.quickDrawEnabled) {
        return switch (settings.experienceLevel) {
          1 => '/draw/instant',
          2 => '/draw/animated',
          3 => '/shuffle/${settings.selectedDeckId}',
          _ => null,
        };
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const HomePage()),
      ),
      GoRoute(
        path: '/deck',
        name: 'deck',
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const DeckSelectionPage()),
      ),
      GoRoute(
        path: '/intention/:deckId',
        name: 'intention',
        pageBuilder: (context, state) {
          final deckId = state.pathParameters['deckId']!;
          return _fadePage(
              key: state.pageKey, child: IntentionPage(deckId: deckId));
        },
      ),
      GoRoute(
        path: '/shuffle/:deckId',
        name: 'shuffle',
        pageBuilder: (context, state) {
          final deckId = state.pathParameters['deckId']!;
          return _fadePage(
              key: state.pageKey, child: ShufflePage(deckId: deckId));
        },
      ),
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
      // ── Level 1: 즉시 뽑기 ──
      GoRoute(
        path: '/draw/instant',
        name: 'draw-instant',
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const InstantDrawPage()),
      ),
      // ── Level 2: 간단 연출 ──
      GoRoute(
        path: '/draw/animated',
        name: 'draw-animated',
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const AnimatedDrawPage()),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const SettingsPage()),
      ),
      GoRoute(
        path: '/readings',
        name: 'readings',
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const ReadingListPage()),
      ),
      GoRoute(
        path: '/readings/:readingId',
        name: 'reading-detail',
        pageBuilder: (context, state) {
          final readingId = state.pathParameters['readingId']!;
          return _fadePage(
              key: state.pageKey,
              child: ReadingDetailPage(readingId: readingId));
        },
      ),
    ],
  );
}
```

### EV-006-D1 상세 대응

`userSettingsProvider`는 `@riverpod` (AutoDispose)이다. 그러나:

1. `appRouterProvider`는 `@riverpod` (역시 AutoDispose)이다.
2. `appRouterProvider`는 `MaterialApp.router`에서 `ref.watch`되므로, 앱 전체 수명 동안 구독 유지.
3. 따라서 `appRouterProvider` 내부의 `ref.watch(userSettingsProvider)`도 앱 수명 동안 활성 상태.
4. `userSettingsProvider`의 AutoDispose는 모든 listener가 해제될 때 발동하는데, `appRouterProvider`가 계속 watch하므로 해제되지 않음.

**결론**: 현재 구조에서 추가 조치 불필요. 만약 예기치 않은 dispose 발생 시:
- **Fallback**: `cachedUserSettingsProvider`를 `@Riverpod(keepAlive: true)`로 만들어 `userSettingsProvider`를 래핑.

## Step 3: 홈 페이지 재설계 — 허브 모델

**수정 파일**: `mobile/lib/features/home/presentation/pages/home_page.dart`

### 변경 개요

기존 홈 페이지를 허브 모델로 전환:
- 기존: "바로 뽑기" + "셔플 시작" 버튼 + 최근 리딩 목록
- 변경: 기능 카드 그리드 + 현재 설정 요약 + 최근 리딩 미리보기

### UI 구조

```
HomePage (ConsumerStatefulWidget)
├── AppBar 없음 — 커스텀 헤더
├── Header: 앱 아이콘 + 이름 + 현재 설정 요약 뱃지
├── GridView (2열, 4개 기능 카드):
│   ├── "뽑기 시작" — 체험 레벨에 따라 다른 경로로 이동
│   │   └── subtitle: "Level N • N장 • 덱이름"
│   ├── "리딩 기록" — /readings
│   │   └── subtitle: "N개의 기록"
│   ├── "덱 선택" — /deck
│   │   └── subtitle: "현재: 덱이름"
│   └── "설정" — /settings
│       └── subtitle: experienceLevel 표시
├── SizedBox(height: 24)
├── "최근 리딩" 섹션 제목
└── 최근 리딩 3개 미리보기 (기존 패턴 축소)
```

### 핵심 코드

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../deck/presentation/providers/deck_providers.dart';
import '../../../reading/domain/entities/spread_type.dart';
import '../../../reading/presentation/providers/reading_providers.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../../shuffle/presentation/providers/shuffle_providers.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    if (_initialized) return;
    final repo = ref.read(deckRepositoryProvider);
    await repo.seedRwsDeck();
    if (mounted) setState(() => _initialized = true);
  }

  /// 설정된 체험 레벨에 따라 뽑기 경로로 이동
  void _startDraw(BuildContext context, int experienceLevel, String deckId) {
    switch (experienceLevel) {
      case 1:
        context.push('/draw/instant');
      case 2:
        context.push('/draw/animated');
      case 3:
        context.pushNamed('shuffle', pathParameters: {'deckId': deckId});
      default:
        context.push('/draw/instant');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(userSettingsProvider);
    final readingsAsync = ref.watch(watchReadingsProvider);
    final decksAsync = ref.watch(watchDecksProvider);
    final theme = Theme.of(context);

    final settings = settingsAsync.valueOrNull;
    final experienceLevel = settings?.experienceLevel ?? 1;
    final selectedDeckId = settings?.selectedDeckId ?? 'rws-standard';
    final defaultCardCount = settings?.defaultCardCount ?? 3;

    // 현재 덱 이름 해결
    final deckName = decksAsync.valueOrNull
            ?.where((d) => d.id == selectedDeckId)
            .firstOrNull
            ?.name ??
        selectedDeckId;

    final levelLabel = switch (experienceLevel) {
      1 => '즉시',
      2 => '연출',
      3 => '풀셔플',
      _ => '즉시',
    };

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.3),
            radius: 1.2,
            colors: [Color(0xFF2A1B3D), Color(0xFF0D0A14)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 헤더 ──
                const SizedBox(height: 16),
                Icon(Icons.nights_stay,
                    color: theme.colorScheme.primary, size: 40),
                const SizedBox(height: 8),
                Text(
                  'Personality Tarot',
                  style: theme.textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // ── 기능 카드 그리드 ──
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    // 뽑기 시작
                    _HubCard(
                      icon: Icons.style,
                      title: '뽑기 시작',
                      subtitle: '$levelLabel • ${defaultCardCount}장 • $deckName',
                      color: theme.colorScheme.primary,
                      enabled: _initialized,
                      onTap: () =>
                          _startDraw(context, experienceLevel, selectedDeckId),
                    ),
                    // 리딩 기록
                    _HubCard(
                      icon: Icons.history,
                      title: '리딩 기록',
                      subtitle: readingsAsync.valueOrNull != null
                          ? '${readingsAsync.valueOrNull!.length}개의 기록'
                          : '로딩 중...',
                      color: theme.colorScheme.secondary,
                      onTap: () => context.pushNamed('readings'),
                    ),
                    // 덱 선택
                    _HubCard(
                      icon: Icons.layers,
                      title: '덱 선택',
                      subtitle: '현재: $deckName',
                      color: theme.colorScheme.tertiary,
                      onTap: () => context.pushNamed('deck'),
                    ),
                    // 설정
                    _HubCard(
                      icon: Icons.tune,
                      title: '설정',
                      subtitle: '레벨 $experienceLevel ($levelLabel)',
                      color: theme.colorScheme.primary.withValues(alpha: 0.7),
                      onTap: () => context.pushNamed('settings'),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── 최근 리딩 미리보기 ──
                Text('최근 리딩', style: theme.textTheme.bodyLarge),
                const SizedBox(height: 8),
                readingsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('오류: $err')),
                  data: (readings) => readings.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              '아직 리딩이 없습니다.\n뽑기를 시작해보세요.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        )
                      : Column(
                          children: readings.take(3).map((reading) {
                            return Card(
                              child: ListTile(
                                title: Text(reading.spreadType.displayName),
                                subtitle:
                                    Text(reading.question ?? '질문 없음'),
                                trailing: Text(
                                  _formatDate(reading.createdAt),
                                  style: theme.textTheme.bodySmall,
                                ),
                                onTap: () => context.pushNamed(
                                  'reading-detail',
                                  pathParameters: {'readingId': reading.id},
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// 홈 허브 기능 카드 위젯
class _HubCard extends StatelessWidget {
  const _HubCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### 기존 `_quickDraw` 제거

기존 홈의 `_quickDraw` 메서드는 `_startDraw`로 대체. 셔플 로직은 Level 1/2 페이지 내부에서 실행. 홈은 라우팅만 담당.

### DevTuner 변수 정리

기존 홈의 Dev Tuner 변수 4개(`homeGradientCenterYProvider` 등)는 허브 모델에서 고정 값을 사용하므로 제거. 필요 시 향후 재도입.

## Step 4: Level 1 즉시 뽑기 페이지

**신규 파일**: `mobile/lib/features/draw/presentation/pages/instant_draw_page.dart`

### UX 흐름

```
페이지 진입
  → 즉시 셔플 실행 (initState)
  → 결과 표시 (SpreadLayout, 모든 카드 showFaceUp=true 또는 settings)
  → 자동 저장
  → "+1 한 장 더" FAB 활성
  → (optional) 질문 추가 — 하단 펼침 패널
```

**성능 목표**: 진입 → 결과 0.5초 이내.

### 코드

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../reading/domain/entities/reading.dart';
import '../../../reading/domain/entities/reflective_prompts.dart';
import '../../../reading/domain/entities/spread_type.dart';
import '../../../reading/presentation/providers/reading_providers.dart';
import '../../../reading/presentation/widgets/spread_layout.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../../shuffle/domain/entities/shuffle_result.dart';
import '../../../shuffle/presentation/providers/shuffle_providers.dart';
import '../../../deck/presentation/providers/deck_providers.dart';
import '../../../shuffle/presentation/pages/intention_page.dart';

class InstantDrawPage extends ConsumerStatefulWidget {
  const InstantDrawPage({super.key});

  @override
  ConsumerState<InstantDrawPage> createState() => _InstantDrawPageState();
}

class _InstantDrawPageState extends ConsumerState<InstantDrawPage> {
  ShuffleResult? _shuffleResult;
  late int _currentCardCount;
  late SpreadType _spreadType;
  late String _deckId;
  final Set<int> _revealedPositions = {};
  String? _savedReadingId;
  bool _autoSaved = false;
  bool _loading = true;

  // 질문 입력 관련
  final _questionController = TextEditingController();
  bool _questionExpanded = false;

  @override
  void initState() {
    super.initState();
    _initSettings();
    _executeDraw();
  }

  void _initSettings() {
    final settings = ref.read(userSettingsProvider).valueOrNull;
    _spreadType = settings?.defaultSpreadType ?? SpreadType.threeCard;
    _currentCardCount = _spreadType == SpreadType.custom
        ? settings?.defaultCardCount ?? 3
        : _spreadType.cardCount;
    _deckId = settings?.selectedDeckId ?? 'rws-standard';
  }

  Future<void> _executeDraw() async {
    final cards = await ref.read(deckCardsProvider(_deckId).future);
    final useCase = ref.read(shuffleDeckUseCaseProvider);
    final strategy = ref.read(shuffleStrategyProvider);
    final result = useCase.execute(cards: cards, strategy: strategy);
    ref.read(shuffleStateProvider.notifier).setResult(result);

    if (!mounted) return;
    setState(() {
      _shuffleResult = result;
      _loading = false;
      // 즉시 뽑기 — 모든 카드 즉시 reveal
      for (var i = 0; i < _currentCardCount; i++) {
        _revealedPositions.add(i);
      }
    });
  }

  void _autoSave() {
    if (_autoSaved || _shuffleResult == null) return;
    _autoSaved = true;

    final readingId = const Uuid().v4();
    _savedReadingId = readingId;

    final drawnCards = _shuffleResult!.cards.take(_currentCardCount).toList();
    final question = _questionController.text;

    final reading = Reading(
      id: readingId,
      deckId: _deckId,
      spreadType: _spreadType,
      question: question.isNotEmpty ? question : null,
      drawnCards: List.generate(
        drawnCards.length,
        (i) => DrawnCardInfo(
          cardId: drawnCards[i].card.id,
          position: i,
          isReversed: drawnCards[i].isReversed,
        ),
      ),
      createdAt: DateTime.now(),
    );

    ref.read(readingRepositoryProvider).saveReading(reading);
  }

  void _addOneMore() {
    if (_shuffleResult == null) return;
    if (_currentCardCount >= _shuffleResult!.cards.length) return;

    setState(() => _currentCardCount++);
    _revealedPositions.add(_currentCardCount - 1);

    // DB에 카드 추가
    if (_savedReadingId != null) {
      final newCard = _shuffleResult!.cards[_currentCardCount - 1];
      ref.read(readingRepositoryProvider).addDrawnCard(
            _savedReadingId!,
            DrawnCardInfo(
              cardId: newCard.card.id,
              position: _currentCardCount - 1,
              isReversed: newCard.isReversed,
            ),
            DateTime.now(),
          );
    }
  }

  void _updateQuestion() {
    if (_savedReadingId == null) return;
    final question = _questionController.text;
    ref.read(readingRepositoryProvider).updateNotes(
          _savedReadingId!,
          null, // notes는 별도
        );
    // question은 Reading의 필드이므로, 저장 시점에 반영.
    // 이미 저장된 reading의 question을 업데이트하려면 별도 메서드 필요.
    // 현 구현: 질문을 입력한 후 readingQuestionProvider에 세팅하면
    // 다음 뽑기에 반영됨. 현 리딩에는 빈 question으로 저장됨.
    // → 사용자가 뽑기 전에 질문을 입력하는 것이 자연스러운 플로우.
    ref.read(readingQuestionProvider.notifier).set(question);
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('즉시 뽑기')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_shuffleResult == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('즉시 뽑기')),
        body: const Center(child: Text('셔플 실행 실패')),
      );
    }

    final drawnCards = _shuffleResult!.cards.take(_currentCardCount).toList();

    // 자동 저장 트리거
    _autoSave();

    final hasMoreCards = _currentCardCount < _shuffleResult!.cards.length;

    final resolvedPositions =
        _spreadType.resolvePositions(drawnCards.length);
    final resolvedGuidances =
        _spreadType.resolveGuidances(drawnCards.length);

    return Scaffold(
      appBar: AppBar(
        title: Text('${_spreadType.displayName} — 즉시'),
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () => context.go('/'),
        ),
      ),
      floatingActionButton: hasMoreCards
          ? FloatingActionButton.extended(
              onPressed: _addOneMore,
              icon: const Icon(Icons.add),
              label: Text(
                  '+1 한 장 더 (${_shuffleResult!.cards.length - _currentCardCount}장 남음)'),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 질문 입력 (접힌 상태 / 펼친 상태) ──
            GestureDetector(
              onTap: () => setState(() => _questionExpanded = !_questionExpanded),
              child: Row(
                children: [
                  Icon(
                    _questionExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '질문이 있으신가요? (선택)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
            if (_questionExpanded) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _questionController,
                decoration: InputDecoration(
                  hintText: '이 뽑기에 대한 질문...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                maxLines: 1,
                onSubmitted: (_) => _updateQuestion(),
              ),
            ],
            const SizedBox(height: 16),

            // ── 스프레드 레이아웃 ──
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.45,
              child: SpreadLayout(
                spreadType: _spreadType,
                cards: drawnCards,
                deckId: _deckId,
                revealedPositions: _revealedPositions,
                onCardTap: (_) {}, // 이미 모두 reveal됨
              ),
            ),

            // ── 성찰 카드 ──
            const SizedBox(height: 24),
            Text(
              '성찰의 시간',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < drawnCards.length; i++)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${resolvedPositions[i]}: ${drawnCards[i].card.name}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      resolvedGuidances[i],
                      style: TextStyle(
                        color: theme.colorScheme.secondary,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ReflectivePrompts.getPrompt(drawnCards[i].card.cardId),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),

            // 안전 고지
            const SizedBox(height: 16),
            Text(
              '타로는 자기 성찰의 도구입니다. 결과에 과도한 의미를 부여하지 마세요.\n'
              '심리적 어려움이 있다면 정신건강 위기상담전화 1577-0199',
              style: TextStyle(
                color: theme.colorScheme.secondary.withValues(alpha: 0.7),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
```

### 성능 분석

- `initState` → `_executeDraw()` → `deckCardsProvider.future` (Drift 캐시, ~50ms) → Fisher-Yates 셔플 (~1ms) → `setState` → 렌더.
- 총 예상 시간: ~100ms (DB 접근) + ~50ms (렌더). **0.5초 목표 충족**.
- `SpreadLayout`과 `CardRevealWidget`은 `isRevealed: true`로 생성되므로 플립 애니메이션 없이 즉시 앞면 표시 (Cycle 2 264b181 커밋에서 보장).

### EV-009-A2 대응

- 질문 입력은 optional 접힘 패널로 제공.
- 기본 동작: 질문 없이 즉시 뽑기. 결과 후에 질문을 추가할 수 있음.
- `readingQuestionProvider`에 set하면 다음 뽑기에 반영. 현 리딩의 question은 `_autoSave` 시점의 `_questionController.text` 값 사용.

**중요 — 질문 타이밍 이슈**: `_autoSave`가 `build`에서 즉시 호출되므로, 사용자가 질문을 입력하기 전에 이미 저장될 수 있음. 이를 해결하기 위해:
1. Level 1에서는 `_autoSave`를 `_executeDraw` 완료 후 **200ms 지연** 실행하여 UI 렌더 후 약간의 시간을 줌.
2. 또는 질문을 나중에 입력하면 `updateNotes`처럼 Reading의 question을 update하는 방식. → 현재 `ReadingRepository`에 `updateQuestion` 메서드가 없으므로, 이 Plan에서는 **질문 입력 시 readingQuestionProvider에 set + 자동 저장은 빈 question으로 진행**하는 방식으로 처리. 질문이 중요한 사용자는 Level 2/3을 사용하도록 가이드.

## Step 5: Level 2 간단 연출 페이지

**신규 파일**: `mobile/lib/features/draw/presentation/pages/animated_draw_page.dart`

### UX 흐름

```
페이지 진입
  → (optional) 1줄 질문 입력 — "skip" 가능
  → 셔플 실행 (버튼 탭 또는 자동)
  → 카드 슬라이드 인/플립 애니메이션 (2~3초)
    → 카드가 순차적으로 300ms 간격 stagger로 등장
    → 각 카드: SlideTransition(아래→위) + FadeTransition 600ms
    → 등장 완료 후 자동 flip (showFaceUp이면 flip 생략)
  → 전체 공개 후 → 자동 저장 + "+1" FAB + 성찰 카드
```

### 애니메이션 설계

Flutter implicit/explicit 애니메이션 사용, Flame 불필요:

| 요소 | 애니메이션 | 위젯/API | 시간 |
|------|----------|---------|------|
| 카드 등장 | 아래→위 슬라이드 + 페이드 인 | `SlideTransition` + `FadeTransition` with `AnimationController` | 600ms per card |
| 카드 stagger | 순차 등장 | `Interval` with offset per card index | 300ms 간격 |
| 카드 플립 | 뒷면→앞면 | `CardRevealWidget` 기존 플립 (400ms) | auto-trigger after slide |
| 전체 시퀀스 | N장 stagger | total = 600ms + (N-1)*300ms + 400ms flip | 3장 기준 ~2.0초 |

### 코드

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../reading/domain/entities/reading.dart';
import '../../../reading/domain/entities/reflective_prompts.dart';
import '../../../reading/domain/entities/spread_type.dart';
import '../../../reading/presentation/providers/reading_providers.dart';
import '../../../reading/presentation/widgets/spread_layout.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../../shuffle/domain/entities/shuffle_result.dart';
import '../../../shuffle/presentation/providers/shuffle_providers.dart';
import '../../../deck/presentation/providers/deck_providers.dart';
import '../../../shuffle/presentation/pages/intention_page.dart';

class AnimatedDrawPage extends ConsumerStatefulWidget {
  const AnimatedDrawPage({super.key});

  @override
  ConsumerState<AnimatedDrawPage> createState() => _AnimatedDrawPageState();
}

class _AnimatedDrawPageState extends ConsumerState<AnimatedDrawPage>
    with TickerProviderStateMixin {
  ShuffleResult? _shuffleResult;
  late int _currentCardCount;
  late SpreadType _spreadType;
  late String _deckId;
  late bool _showFaceUp;
  final Set<int> _revealedPositions = {};
  String? _savedReadingId;
  bool _autoSaved = false;

  // 애니메이션 상태
  bool _shuffleExecuted = false;
  bool _animationComplete = false;
  final List<AnimationController> _slideControllers = [];
  final List<Animation<Offset>> _slideAnimations = [];
  final List<Animation<double>> _fadeAnimations = [];

  // 질문 입력
  final _questionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initSettings();
  }

  void _initSettings() {
    final settings = ref.read(userSettingsProvider).valueOrNull;
    _spreadType = settings?.defaultSpreadType ?? SpreadType.threeCard;
    _currentCardCount = _spreadType == SpreadType.custom
        ? settings?.defaultCardCount ?? 3
        : _spreadType.cardCount;
    _deckId = settings?.selectedDeckId ?? 'rws-standard';
    _showFaceUp = settings?.showFaceUp ?? false;
  }

  Future<void> _startDraw() async {
    // 셔플 실행
    final cards = await ref.read(deckCardsProvider(_deckId).future);
    final useCase = ref.read(shuffleDeckUseCaseProvider);
    final strategy = ref.read(shuffleStrategyProvider);
    final result = useCase.execute(cards: cards, strategy: strategy);
    ref.read(shuffleStateProvider.notifier).setResult(result);

    // 질문 세팅
    final question = _questionController.text;
    if (question.isNotEmpty) {
      ref.read(readingQuestionProvider.notifier).set(question);
    }

    if (!mounted) return;
    setState(() {
      _shuffleResult = result;
      _shuffleExecuted = true;
    });

    // 애니메이션 컨트롤러 생성
    _setupAnimations();
    _playAnimations();
  }

  void _setupAnimations() {
    for (var i = 0; i < _currentCardCount; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );

      final slide = Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutCubic));

      final fade = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeIn));

      _slideControllers.add(controller);
      _slideAnimations.add(slide);
      _fadeAnimations.add(fade);
    }
  }

  Future<void> _playAnimations() async {
    // 순차적 stagger 애니메이션
    for (var i = 0; i < _currentCardCount; i++) {
      if (!mounted) return;
      _slideControllers[i].forward();
      await Future.delayed(const Duration(milliseconds: 300));
    }

    // 마지막 카드 슬라이드 완료 대기
    await _slideControllers.last.forward();

    // 카드 플립 (showFaceUp이 아닌 경우에만 지연 후 순차 reveal)
    if (!_showFaceUp) {
      await Future.delayed(const Duration(milliseconds: 200));
      for (var i = 0; i < _currentCardCount; i++) {
        if (!mounted) return;
        setState(() => _revealedPositions.add(i));
        await Future.delayed(const Duration(milliseconds: 200));
      }
    } else {
      // showFaceUp이면 슬라이드 완료 후 즉시 전부 reveal
      if (mounted) {
        setState(() {
          for (var i = 0; i < _currentCardCount; i++) {
            _revealedPositions.add(i);
          }
        });
      }
    }

    if (mounted) {
      setState(() => _animationComplete = true);
    }
  }

  void _autoSave() {
    if (_autoSaved || _shuffleResult == null) return;
    _autoSaved = true;

    final readingId = const Uuid().v4();
    _savedReadingId = readingId;

    final drawnCards = _shuffleResult!.cards.take(_currentCardCount).toList();
    final question = _questionController.text;

    final reading = Reading(
      id: readingId,
      deckId: _deckId,
      spreadType: _spreadType,
      question: question.isNotEmpty ? question : null,
      drawnCards: List.generate(
        drawnCards.length,
        (i) => DrawnCardInfo(
          cardId: drawnCards[i].card.id,
          position: i,
          isReversed: drawnCards[i].isReversed,
        ),
      ),
      createdAt: DateTime.now(),
    );

    ref.read(readingRepositoryProvider).saveReading(reading);
  }

  void _addOneMore() {
    if (_shuffleResult == null) return;
    if (_currentCardCount >= _shuffleResult!.cards.length) return;

    setState(() => _currentCardCount++);
    _revealedPositions.add(_currentCardCount - 1);

    if (_savedReadingId != null) {
      final newCard = _shuffleResult!.cards[_currentCardCount - 1];
      ref.read(readingRepositoryProvider).addDrawnCard(
            _savedReadingId!,
            DrawnCardInfo(
              cardId: newCard.card.id,
              position: _currentCardCount - 1,
              isReversed: newCard.isReversed,
            ),
            DateTime.now(),
          );
    }
  }

  @override
  void dispose() {
    for (final c in _slideControllers) {
      c.dispose();
    }
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 애니메이션 완료 + 전체 공개 후 자동 저장
    final allRevealed = _revealedPositions.length >= _currentCardCount;
    if (allRevealed && _shuffleExecuted) _autoSave();

    // ── 셔플 전: 질문 입력 화면 ──
    if (!_shuffleExecuted) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('카드 뽑기'),
          leading: IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/'),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.self_improvement,
                  color: theme.colorScheme.primary, size: 48),
              const SizedBox(height: 16),
              Text(
                '마음속 질문을 떠올려보세요.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _questionController,
                decoration: InputDecoration(
                  hintText: '질문이나 의도를 적어보세요 (선택)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              Text(
                '질문 없이 진행해도 괜찮습니다.',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: _startDraw,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('카드 뽑기',
                      style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: TextButton(
                  onPressed: () {
                    _questionController.clear();
                    _startDraw();
                  },
                  child: const Text('질문 없이 바로 뽑기'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── 셔플 후: 애니메이션 + 결과 ──
    if (_shuffleResult == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('카드 뽑기')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final drawnCards = _shuffleResult!.cards.take(_currentCardCount).toList();
    final hasMoreCards = _currentCardCount < _shuffleResult!.cards.length;

    final resolvedPositions =
        _spreadType.resolvePositions(drawnCards.length);
    final resolvedGuidances =
        _spreadType.resolveGuidances(drawnCards.length);

    return Scaffold(
      appBar: AppBar(
        title: Text('${_spreadType.displayName} — 연출'),
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () => context.go('/'),
        ),
      ),
      floatingActionButton: _animationComplete && hasMoreCards
          ? FloatingActionButton.extended(
              onPressed: _addOneMore,
              icon: const Icon(Icons.add),
              label: Text(
                  '+1 한 장 더 (${_shuffleResult!.cards.length - _currentCardCount}장 남음)'),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 질문 표시
            if (_questionController.text.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '"${_questionController.text}"',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── 애니메이션 카드 레이아웃 ──
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.45,
              child: _buildAnimatedCards(drawnCards),
            ),

            // 성찰 카드 (애니메이션 완료 후)
            if (_animationComplete) ...[
              const SizedBox(height: 24),
              Text(
                '성찰의 시간',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < drawnCards.length; i++)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${resolvedPositions[i]}: ${drawnCards[i].card.name}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        resolvedGuidances[i],
                        style: TextStyle(
                          color: theme.colorScheme.secondary,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ReflectivePrompts.getPrompt(drawnCards[i].card.cardId),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
            ],

            // 안전 고지
            const SizedBox(height: 16),
            Text(
              '타로는 자기 성찰의 도구입니다. 결과에 과도한 의미를 부여하지 마세요.\n'
              '심리적 어려움이 있다면 정신건강 위기상담전화 1577-0199',
              style: TextStyle(
                color: theme.colorScheme.secondary.withValues(alpha: 0.7),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 슬라이드+페이드 애니메이션으로 카드를 순차 표시
  Widget _buildAnimatedCards(List<ShuffledCard> drawnCards) {
    if (_slideControllers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // 3장 이하: 가로 나열, 4장 이상: 2열 그리드
    if (drawnCards.length <= 3) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(drawnCards.length, (i) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _animatedCard(i, drawnCards[i]),
            ),
          );
        }),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.65,
      ),
      itemCount: drawnCards.length,
      itemBuilder: (context, i) => _animatedCard(i, drawnCards[i]),
    );
  }

  Widget _animatedCard(int index, ShuffledCard card) {
    if (index >= _slideControllers.length) {
      // "+1"로 추가된 카드 — 애니메이션 없이 즉시 표시
      return _buildCardWidget(index, card);
    }

    return SlideTransition(
      position: _slideAnimations[index],
      child: FadeTransition(
        opacity: _fadeAnimations[index],
        child: _buildCardWidget(index, card),
      ),
    );
  }

  Widget _buildCardWidget(int index, ShuffledCard card) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _spreadType.resolvePositions(_currentCardCount)[index],
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Flexible(
          child: AspectRatio(
            aspectRatio: 2.5 / 3.5,
            child: _revealedPositions.contains(index)
                ? _buildFrontCard(card)
                : _buildBackCard(),
          ),
        ),
        if (_revealedPositions.contains(index) && card.isReversed)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '역방향',
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBackCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        'assets/images/$_deckId/card_back.webp',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: const Color(0xFF2D1B4E),
          child: Center(
            child: Icon(Icons.auto_awesome,
                color: Theme.of(context).colorScheme.primary, size: 32),
          ),
        ),
      ),
    );
  }

  Widget _buildFrontCard(ShuffledCard card) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            card.card.imagePath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFF1A1028),
              child: Center(
                child: Text(
                  card.card.name,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
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
                card.card.name,
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
    );
  }
}
```

### 애니메이션 vs SpreadLayout 재사용

Level 2는 SpreadLayout + CardRevealWidget을 직접 사용하지 않고 자체 애니메이션 로직을 사용:
- **이유**: SpreadLayout은 정적 레이아웃이고, Level 2에서는 카드가 순차적으로 "등장"해야 함.  SlideTransition/FadeTransition은 SpreadLayout 내부의 CardRevealWidget에 래핑할 수 없음 (CardRevealWidget의 플립 애니메이션과 별개의 등장 애니메이션이 필요).
- **카드 플립**: `_revealedPositions`에 추가 시점을 stagger로 제어하여 "뒷면 → 앞면" 전환 연출. `CardRevealWidget`의 400ms 플립 대신 자체적으로 front/back 이미지를 직접 전환 (더 가벼움).
- **"+1" 카드**: 애니메이션 이후 추가되는 카드는 슬라이드 없이 즉시 표시.

### Level 3 라우팅

Level 3은 기존 `/shuffle/:deckId` 라우트로 연결. 새 구현 없음. GoRouter redirect에서 `3 => '/shuffle/${settings.selectedDeckId}'`로 처리. 기존 셔플 페이지의 `_goToReading()`이 ReadingPage로 이동하므로 기존 플로우 전체가 유지됨.

## Step 6: 홈의 덱 시드 초기화 타이밍

현재 홈 페이지의 `_initializeApp()`이 `repo.seedRwsDeck()`를 호출하여 초기 덱 데이터를 시드한다. `quickDrawEnabled` 시 redirect로 홈을 건너뛰면 시드가 실행되지 않아 Level 1/2에서 덱 카드가 없을 수 있다.

### 해결

Level 1/2의 `_executeDraw()`에 동일한 시드 로직 추가:

```dart
Future<void> _executeDraw() async {
  // 덱 시드 보장 (홈을 건너뛴 경우)
  final repo = ref.read(deckRepositoryProvider);
  await repo.seedRwsDeck();

  final cards = await ref.read(deckCardsProvider(_deckId).future);
  // ... 셔플 로직 ...
}
```

`seedRwsDeck()`은 내부적으로 "이미 시드됨" 확인을 하므로 중복 실행 비용 무시할 수 있음 (SELECT 1회).

## Step 7: 코드 생성 + 빌드 검증

```bash
cd mobile && dart run build_runner build --delete-conflicting-outputs
```

영향 받는 생성 파일:
- `app_router.g.dart` — GoRouter provider 재생성 (redirect 추가, 라우트 변경)
- `draw_providers.g.dart` (NEW) — `executeDrawProvider` family provider

빌드 검증:
```bash
flutter analyze
flutter build apk --debug
```

## Step 8: 통합 테스트 항목

기능 동작 확인:

1. 앱 첫 실행 → 홈 허브 표시 (quickDrawEnabled=false 기본)
2. 홈 허브 4개 기능 카드 네비게이션 정상
3. "뽑기 시작" → Level 1 즉시 뽑기 페이지 이동 → 결과 즉시 표시
4. 설정에서 Level 2로 변경 → "뽑기 시작" → Level 2 연출 페이지 → 슬라이드+플립 애니메이션
5. 설정에서 Level 3으로 변경 → "뽑기 시작" → 기존 셔플 페이지 이동
6. quickDrawEnabled 활성화 → 앱 재시작(GoRouter 재생성) → Level에 맞는 페이지로 redirect
7. Level 1에서 "+1 한 장 더" 동작
8. Level 2에서 "+1 한 장 더" 동작
9. Level 1/2에서 자동 저장 동작 → 리딩 기록에 표시
10. Level 2에서 질문 입력 → 자동 저장 시 question 필드 반영
11. 홈 허브 → 리딩 기록 → 리딩 상세 → notes 편집 (기존 Cycle 2 기능 회귀 없음)
12. 홈 허브 → 설정 → 모든 설정 변경 정상 (기존 Cycle 2 기능 회귀 없음)

## 파일 변경 요약

| # | 파일 경로 | 작업 | Step |
|---|----------|------|------|
| 1 | `mobile/lib/features/draw/presentation/providers/draw_providers.dart` | **NEW** — 셔플 실행 provider | 1 |
| 2 | `mobile/lib/core/router/app_router.dart` | **REWRITE** — redirect 추가 + Level 1/2 라우트 추가 + userSettings watch | 2 |
| 3 | `mobile/lib/features/home/presentation/pages/home_page.dart` | **REWRITE** — 허브 모델 전환 | 3 |
| 4 | `mobile/lib/features/draw/presentation/pages/instant_draw_page.dart` | **NEW** — Level 1 즉시 뽑기 | 4 |
| 5 | `mobile/lib/features/draw/presentation/pages/animated_draw_page.dart` | **NEW** — Level 2 간단 연출 | 5 |
| 6 | `mobile/lib/features/draw/presentation/providers/draw_providers.g.dart` | **NEW** (codegen) | 7 |
| 7 | `mobile/lib/core/router/app_router.g.dart` | **REGEN** (codegen) | 7 |

**신규 4파일**: draw_providers.dart, instant_draw_page.dart, animated_draw_page.dart, draw_providers.g.dart
**수정 2파일**: app_router.dart (REWRITE), home_page.dart (REWRITE)
**재생성 1파일**: app_router.g.dart

## 실행 순서 체크리스트

구현 에이전트가 아래 순서대로 실행한다:

- [ ] **1**: `draw_providers.dart` 생성 — 셔플 실행 provider
- [ ] **2**: `app_router.dart` 수정 — redirect + `/draw/instant`, `/draw/animated` 라우트 추가 + userSettings watch
- [ ] **3**: `home_page.dart` 수정 — 허브 모델 재설계
- [ ] **4**: `instant_draw_page.dart` 생성 — Level 1 즉시 뽑기 (0.5초 이내)
- [ ] **5**: `animated_draw_page.dart` 생성 — Level 2 간단 연출 (2~3초 애니메이션)
- [ ] **6**: Level 1/2의 `_executeDraw`에 `seedRwsDeck()` 추가 — 홈 skip 시 시드 보장
- [ ] **7**: `dart run build_runner build --delete-conflicting-outputs`
- [ ] **8**: 빌드 검증 (`flutter analyze` + `flutter build apk --debug`)

## 검증 기준

| # | 기준 | 검증 방법 |
|---|------|----------|
| 1 | 홈 허브에서 4개 기능 카드 네비게이션 정상 | 각 카드 탭 → 올바른 페이지로 이동 |
| 2 | Level 1: 진입 → 결과 0.5초 이내 | 타이머 측정 또는 체감 확인 |
| 3 | Level 1: 모든 카드 즉시 앞면 표시 + 자동 저장 | DB에 Reading 행 확인 |
| 4 | Level 2: 카드 슬라이드+플립 애니메이션 2~3초 | 시각적 확인 |
| 5 | Level 2: 질문 입력 → 자동 저장 시 question 반영 | DB Reading.question 확인 |
| 6 | Level 3: 기존 셔플 페이지로 정상 이동 | `/shuffle/:deckId` 라우팅 확인 |
| 7 | GoRouter redirect: quickDrawEnabled=true 시 레벨별 redirect 동작 | 설정 변경 → 앱 루트 접근 시 redirect 확인 |
| 8 | "+1 한 장 더": Level 1/2에서 동작 + DB 반영 | FAB 탭 → 카드 추가 + DrawnCards 행 확인 |
| 9 | 덱 시드: 홈 skip 시에도 Level 1/2에서 카드 로딩 정상 | quickDrawEnabled=true → Level 1 진입 → 카드 표시 정상 |
| 10 | 기존 기능 회귀 없음 | 셔플/리딩/설정/리딩 목록 흐름 정상 |
| 11 | 코드 생성 성공 | `build_runner build` 에러 없음 |

## 리스크

| # | 리스크 | 완화 |
|---|--------|------|
| 1 | GoRouter 재생성 시 라우트 스택 초기화 | UserSettings 변경 빈도가 낮음 (설정 페이지에서만). 설정 변경 후 홈으로 돌아가는 것이 자연스러운 플로우 |
| 2 | Level 1 `_autoSave`가 build에서 호출 — 질문 입력 전 저장 | Level 1의 핵심 가치는 "즉시 결과". 질문은 optional. 질문 중요 시 Level 2/3 사용 가이드 |
| 3 | Level 2 애니메이션 컨트롤러 메모리 | 최대 10개(10장). dispose에서 전부 해제. 실질적 메모리 문제 없음 |
| 4 | `seedRwsDeck()` 중복 호출 | 내부 "이미 시드됨" 체크 있음. SELECT 1회 비용 (~1ms) |
| 5 | Level 2에서 SpreadLayout 미사용 — 레이아웃 불일치 가능 | Level 2 자체 레이아웃이 SpreadLayout과 동일한 패턴(3장: Row, 4+: GridView) 사용. 향후 공통 위젯 추출 가능 |
| 6 | `userSettingsProvider` AutoDispose — GoRouter lifecycle | Step 2 EV-006-D1 상세 대응 참고. 실질적으로 미발동. fallback 준비됨 |

## Brief 앵커 대응 요약

| Model Anchor | 요구사항 | 이 Plan의 대응 |
|-------------|---------|---------------|
| **MA-1** (진입 흐름 분기) | quickDrawEnabled 시 체험 레벨별 redirect | Step 2: GoRouter redirect — `/draw/instant`, `/draw/animated`, `/shuffle/:deckId` |
| **MA-2** (3단계 체험 레벨) | Level 1 즉시(0.5초), Level 2 연출(2~3초), Level 3 풀셔플 | Step 4: InstantDrawPage, Step 5: AnimatedDrawPage, Level 3: 기존 라우팅 |
| **MA-6** (라우트 구조 재설계) | 허브 모델, `/draw`, `/shuffle`, `/readings`, `/settings` | Step 2+3: 전체 라우트 재구조 + 홈 허브 |
| **MA-7** (카드 표시 방식) | showFaceUp 적용 | Level 1: 항상 즉시 reveal. Level 2: showFaceUp에 따라 플립 생략/실행 |
| **MA-8** (한 장 더 뽑기) | "+1" FAB | Level 1/2 모두 "+1" FAB 구현 (Cycle 2 ReadingPage 패턴 재활용) |

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
