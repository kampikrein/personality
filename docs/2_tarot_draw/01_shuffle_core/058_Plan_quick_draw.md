---
id: "058"
type: plan
title: "바로 뽑기 — 홈에서 3장 즉시 드로우"
created: 2026-03-18
traces_scope: "057"
summary: >
  홈 화면에 '바로 뽑기' 버튼 추가. 탭 시 Fisher-Yates 즉시 셔플 후
  SpreadType.threeCard로 리딩 페이지 진입. 3개 파일 수정.
keywords: [quick-draw, three-card, home-page, reading-page]
---

# 058 — 바로 뽑기

## Goal

홈 화면의 '셔플 시작' 버튼 위에 '바로 뽑기' 버튼을 추가한다. 셔플 의식(센서 수집, 리플 애니메이션) 없이 즉시 3장을 뽑아 리딩 페이지로 이동한다.

## Scope

### Included
| # | Item | Description |
|---|------|-------------|
| 1 | 바로 뽑기 버튼 | 홈 '셔플 시작' 위에 배치, threeCard 스프레드 |
| 2 | ReadingPage spreadType 파라미터 | 하드코딩 제거, 외부에서 전달 |
| 3 | 라우터 extra 전달 | GoRouter state.extra로 SpreadType 전달 |

### Excluded
| Item | Reason/Timeline |
|------|-----------------|
| 스프레드 선택 UI | YAGNI — 현재는 바로 뽑기(3장)만 |
| 바로 뽑기 애니메이션 | 의도적 생략 — "바로" = 즉시 |

## Structural Decisions

No structural decisions required — straightforward implementation.

---

## File Change Summary

### Modified Files
| # | File Path | Change Description |
|---|-----------|-------------------|
| 1 | `mobile/lib/features/home/presentation/pages/home_page.dart` | 바로 뽑기 버튼 + 즉시 셔플 로직 |
| 2 | `mobile/lib/features/reading/presentation/pages/reading_page.dart` | spreadType 파라미터 추가 |
| 3 | `mobile/lib/core/router/app_router.dart` | reading 라우트에 extra → spreadType 전달 |

---

## Step 1 — ReadingPage에 spreadType 파라미터 추가

### Approach
`SpreadType.single` 하드코딩을 제거하고 생성자 파라미터로 받는다. 기본값 `single`으로 기존 호출과 호환.

### Current Code
```dart
// reading_page.dart:15-16,24
class ReadingPage extends ConsumerStatefulWidget {
  const ReadingPage({super.key, required this.deckId});
  final String deckId;
// ...
class _ReadingPageState extends ConsumerState<ReadingPage> {
  final _spreadType = SpreadType.single;
```

### After Code
```dart
// reading_page.dart:15-17,25
class ReadingPage extends ConsumerStatefulWidget {
  const ReadingPage({super.key, required this.deckId, this.spreadType = SpreadType.single});
  final String deckId;
  final SpreadType spreadType;
// ...
class _ReadingPageState extends ConsumerState<ReadingPage> {
  late final _spreadType = widget.spreadType;
```

---

## Step 2 — 라우터에서 SpreadType extra 전달

### Approach
reading GoRoute의 pageBuilder에서 `state.extra`를 `SpreadType?`으로 캐스팅하여 ReadingPage에 전달.

### Current Code
```dart
// app_router.dart:62-68
GoRoute(
  path: '/reading/:deckId',
  name: 'reading',
  pageBuilder: (context, state) {
    final deckId = state.pathParameters['deckId']!;
    return _fadePage(
        key: state.pageKey, child: ReadingPage(deckId: deckId));
  },
),
```

### After Code
```dart
// app_router.dart:62-70
GoRoute(
  path: '/reading/:deckId',
  name: 'reading',
  pageBuilder: (context, state) {
    final deckId = state.pathParameters['deckId']!;
    final spreadType = state.extra as SpreadType? ?? SpreadType.single;
    return _fadePage(
        key: state.pageKey,
        child: ReadingPage(deckId: deckId, spreadType: spreadType));
  },
),
```

### Considerations
`import` 추가 필요: `import '../../features/reading/domain/entities/spread_type.dart';`

---

## Step 3 — 홈 페이지에 바로 뽑기 버튼 추가

### Approach
'셔플 시작' 버튼 위에 '바로 뽑기' 버튼 배치. 탭 시:
1. `deckCardsProvider('rws-standard')`로 카드 로드
2. `ShuffleDeckUseCase.execute()`로 Fisher-Yates 셔플
3. `shuffleStateProvider`에 결과 저장
4. `context.pushNamed('reading', ..., extra: SpreadType.threeCard)` 이동

### Current Code
```dart
// home_page.dart:61-71
SizedBox(
  height: 56,
  child: ElevatedButton(
    onPressed: () => context.pushNamed(
      'shuffle',
      pathParameters: {'deckId': 'rws-standard'},
    ),
    child: const Text('셔플 시작',
        style: TextStyle(fontSize: 18)),
  ),
),
```

### After Code
```dart
// home_page.dart — 새 imports 추가
import '../../../shuffle/presentation/providers/shuffle_providers.dart';
import '../../../deck/presentation/providers/deck_providers.dart';
import '../../../reading/domain/entities/spread_type.dart';

// home_page.dart — '셔플 시작' 위에 '바로 뽑기' 버튼 추가
SizedBox(
  height: 56,
  child: FilledButton.icon(
    onPressed: _initialized ? () => _quickDraw(context) : null,
    icon: const Icon(Icons.style, size: 20),
    label: const Text('바로 뽑기',
        style: TextStyle(fontSize: 18)),
  ),
),
const SizedBox(height: 12),
SizedBox(
  height: 56,
  child: ElevatedButton(
    onPressed: () => context.pushNamed(
      'shuffle',
      pathParameters: {'deckId': 'rws-standard'},
    ),
    child: const Text('셔플 시작',
        style: TextStyle(fontSize: 18)),
  ),
),
```

```dart
// home_page.dart — _quickDraw 메서드 추가 (_HomePageState 내)
Future<void> _quickDraw(BuildContext context) async {
  const deckId = 'rws-standard';
  final cards = await ref.read(deckCardsProvider(deckId).future);

  final useCase = ref.read(shuffleDeckUseCaseProvider);
  final strategy = ref.read(shuffleStrategyProvider);
  final result = useCase.execute(cards: cards, strategy: strategy);

  ref.read(shuffleStateProvider.notifier).setResult(result);

  if (mounted) {
    context.pushNamed(
      'reading',
      pathParameters: {'deckId': deckId},
      extra: SpreadType.threeCard,
    );
  }
}
```

### Considerations
- `FilledButton.icon` vs `ElevatedButton`: '바로 뽑기'는 강조(filled), '셔플 시작'은 보조(elevated). 시각적 위계 구분.
- `_initialized` 체크: 덱 시딩 전에는 버튼 비활성화.
- 센서 수집 없이 호출: `SensorDataCollector.samples`가 빈 리스트 → `usedSensorEntropy=false` → `Random.secure()` 직접 사용. 정상 동작.

---

## Step 4 — 코드 생성 + 빌드 검증

### Approach
1. `dart run build_runner build` — providers.g.dart / router.g.dart 변경 없음 (기존 프로바이더만 사용)
2. `flutter analyze` — 정적 분석 통과 확인

---

## Considerations & Trade-offs

### Alternative Approaches
| 접근법 | 비채택 이유 |
|--------|-----------|
| 별도 QuickDrawPage 생성 | YAGNI — ReadingPage에 spreadType 전달로 충분 |
| SpreadType을 쿼리 파라미터로 | 문자열 파싱 필요, enum extra가 더 타입안전 |
| 별도 quickDrawProvider 생성 | 기존 shuffleDeckUseCaseProvider로 충분 |

### Potential Risks
| 리스크 | 완화 |
|--------|------|
| 덱 로드 실패 시 | async/await로 처리, mounted 체크 |
| 셔플 후 빈 카드 리스트 | seedRwsDeck이 initState에서 보장 |

### Backward Compatibility
- ReadingPage: `spreadType` 기본값 `single` → 기존 호출 전부 호환
- 라우터: extra 없으면 `SpreadType.single` 폴백 → 기존 동작 유지

---

## Implementation Checklist

- [x] Step 1: ReadingPage spreadType 파라미터 추가
- [x] Step 2: 라우터 extra → spreadType 전달
- [x] Step 3: 홈 페이지 바로 뽑기 버튼 + 즉시 셔플 로직
- [x] Step 4: 빌드 검증

## Verification Assertions

| Level | Assertion | Verification Method | Expected Result |
|-------|-----------|-------------------|-----------------|
| L1-Build | Dart 정적 분석 통과 | `flutter analyze` | 에러 0 |
| L3-Browser | 홈에 바로 뽑기 버튼 표시 | 에뮬레이터 스크린샷 | 버튼 2개 (바로 뽑기 + 셔플 시작) |
| L3-Browser | 바로 뽑기 탭 → 3장 리딩 | 에뮬레이터 인터랙션 | 쓰리 카드 스프레드 (3장 표시) |

## References

| Resource | Path/URL | Related Content |
|----------|---------|-----------------|
| Scope | `docs/11_tarot_shuffle/057_Scope_quick_draw.md` | 작업 범위 |
| ShuffleDeckUseCase | `mobile/lib/features/shuffle/domain/usecases/shuffle_deck_usecase.dart` | 셔플 로직 |
| SpreadType | `mobile/lib/features/reading/domain/entities/spread_type.dart` | threeCard 정의 |

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
