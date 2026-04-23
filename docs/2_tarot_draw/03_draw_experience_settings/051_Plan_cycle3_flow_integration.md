---
id: "051"
type: plan
cycle: 3
title: "Cycle 3 — Flow Integration (intent_placement_setting)"
created: 2026-04-21
status: completed
traces_scope: "041"
traces_brief: "040"
summary: >
  5개 RED 테스트를 GREEN으로 전환하는 flow integration 구현 플랜.
  ReadingRepository.updateQuestion 인터페이스/impl 추가,
  HomePage._startDraw + DeckSelectionPage 라우팅 분기, IntentionPage redirect,
  DrawResultPage 조건부 질문 토글 + updateQuestion 호출 총 6개 파일 변경.
keywords: [intent-placement, routing, redirect, draw-result, reading-repository]
---

# 051 — Cycle 3: Flow Integration Plan

## Goal

TDD-Red 050에서 확인된 5개 RED 테스트를 GREEN으로 전환한다.

| 테스트 ID | 파일 | 이유 |
|----------|------|------|
| T1/T2 | reading_repository_update_question_test.dart | `updateQuestion` 인터페이스 미존재 → `@override` warning |
| T4 | intent_placement_routing_test.dart | `afterDraw` + Lv4 → IntentionPage 스킵 안됨 |
| T5 | intent_placement_routing_test.dart | `disabled` + Lv4 → IntentionPage 스킵 안됨 |
| T6 | intention_page_redirect_test.dart | IntentionPage에 redirect 로직 없음 |
| T8b | draw_result_question_box_test.dart | `beforeShuffle` 시 질문 토글 숨김 안됨 |
| T8c | draw_result_question_box_test.dart | `disabled` 시 질문 토글 숨김 안됨 |

## Scope

### Included

| # | Item | Description |
|---|------|-------------|
| 1 | `ReadingRepository.updateQuestion` | 인터페이스에 메서드 시그니처 추가 |
| 2 | `ReadingRepositoryImpl.updateQuestion` | Dao `updateNotes` 패턴 미러 구현 |
| 3 | `ReadingDao.updateQuestion` | Drift update 쿼리 메서드 추가 |
| 4 | `HomePage._startDraw` 분기 | Lv3/4에서 `intentPlacement` 읽어 라우팅 분기 |
| 5 | `DeckSelectionPage.onTap` 분기 | `intentPlacement` 읽어 라우팅 분기 |
| 6 | `IntentionPage` redirect | `beforeShuffle`이 아닐 때 postFrameCallback으로 `/shuffle` redirect |
| 7 | `DrawResultPage` 조건부 질문 토글 | `afterDraw`일 때만 토글 렌더; `updateQuestion` 호출로 저장 정합성 |

### Excluded

| Item | Reason |
|------|--------|
| `_autoSave` 내부 mode별 question 처리 | T8a는 이미 GREEN. 현행 동작(question = `_questionController.text`)이 `beforeShuffle` 모드에서는 올바름. `afterDraw` 모드에서는 토글 숨김 후 입력이 없으면 null 저장됨 — 설계 의도와 일치 |
| `readingQuestionProvider` clear 라이프사이클 정비 | IS#6이지만 현행 테스트에서 RED 없음. 별도 리팩터링 |
| Lv1/Lv2 경로 변경 | 테스트 T3/T7/T8a가 GREEN — 변경 불필요 |
| `reading_dao.g.dart` 재생성 | `updateQuestion` 추가 후 `build_runner` 가 자동 재생성 — impl 단계에서 수행 |

## Structural Decisions

| # | Decision | Chosen Option | Rationale |
|---|----------|---------------|-----------|
| 1 | `ReadingDao.updateQuestion` 추가 여부 | 추가 | `updateNotes`와 동일한 Drift update 패턴. DAO가 없으면 Impl에서 raw SQL 직접 실행해야 하고 타입 안전성 상실 |
| 2 | `IntentionPage` redirect 시점 | `initState` > `addPostFrameCallback` | `build()`에서 직접 navigate 호출은 프레임 build 중 state 변경 금지 원칙 위반. postFrameCallback이 표준 패턴 |
| 3 | `DrawResultPage` 질문 토글 조건 | `intentPlacement == afterDraw`일 때만 렌더 | Brief Decision 5 직접 이행. `disabled`/`beforeShuffle` 모두 숨김. `updateQuestion` 호출도 `afterDraw` 가드 내부에서만 실행 |

---

## File Change Summary

### Modified Files

| # | File Path | Change Description |
|---|-----------|-------------------|
| 1 | `mobile/lib/features/reading/domain/repositories/reading_repository.dart` | `updateQuestion` 시그니처 추가 |
| 2 | `mobile/lib/features/reading/data/repositories/reading_repository_impl.dart` | `updateQuestion` impl 추가 |
| 3 | `mobile/lib/core/database/daos/reading_dao.dart` | `updateQuestion` Drift 쿼리 추가 |
| 4 | `mobile/lib/features/home/presentation/pages/home_page.dart` | `_startDraw` Lv3/4 분기에 intentPlacement 조건 추가 |
| 5 | `mobile/lib/features/deck/presentation/pages/deck_selection_page.dart` | `onTap` 분기 추가, `ConsumerWidget` → `ConsumerWidget` (ref 이미 있음) |
| 6 | `mobile/lib/features/shuffle/presentation/pages/intention_page.dart` | `initState`에 redirect 로직 추가 |
| 7 | `mobile/lib/features/draw/presentation/pages/draw_result_page.dart` | 질문 토글 조건부 렌더 + `updateQuestion` 호출 |

### New Files

없음.

---

## Step 1 — ReadingRepository: `updateQuestion` 인터페이스

### Approach

`reading_repository.dart`에 `updateNotes` 바로 아래에 `updateQuestion` 추가.
T1/T2 테스트의 Fake가 이미 `@override`로 구현하고 있으므로 인터페이스만 추가하면 warning 해소.

### Current Code

```dart
// mobile/lib/features/reading/domain/repositories/reading_repository.dart:9
  Future<void> updateNotes(String readingId, String? notes);
  Future<void> addDrawnCard(String readingId, DrawnCardInfo card, DateTime createdAt);
```

### After Code

```dart
// mobile/lib/features/reading/domain/repositories/reading_repository.dart
  Future<void> updateNotes(String readingId, String? notes);
  Future<void> updateQuestion(String readingId, String? question);
  Future<void> addDrawnCard(String readingId, DrawnCardInfo card, DateTime createdAt);
```

### Considerations

T1/T2는 FakeReadingRepository 내에서 이미 구현됨. 인터페이스 추가만으로 `@override` warning 해소 + 컴파일 안전성 확보.

---

## Step 2 — ReadingDao: `updateQuestion` Drift 쿼리

### Approach

`reading_dao.dart`의 `updateNotes` 메서드 직후에 `updateQuestion`을 동일 패턴으로 추가.
`question` 컬럼을 `Value(question)`으로 업데이트하고 `updatedAt`도 갱신.
Drift accessor는 `@DriftAccessor`로 이미 `Readings` 테이블을 포함하고 있어 추가 선언 불필요.

### Current Code

```dart
// mobile/lib/core/database/daos/reading_dao.dart:45-52
  /// 리딩의 notes 필드 업데이트.
  Future<void> updateNotes(String readingId, String? notes) async {
    await (update(readings)..where((r) => r.id.equals(readingId))).write(
      ReadingsCompanion(
        notes: Value(notes),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
```

### After Code

```dart
// mobile/lib/core/database/daos/reading_dao.dart — updateNotes 바로 아래에 삽입
  /// 리딩의 question 필드 업데이트 (afterDraw 모드에서 결과 화면 입력 시 호출).
  Future<void> updateQuestion(String readingId, String? question) async {
    await (update(readings)..where((r) => r.id.equals(readingId))).write(
      ReadingsCompanion(
        question: Value(question),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
```

### Considerations

`build_runner`로 `reading_dao.g.dart`가 재생성되어야 한다. 
`ReadingsCompanion`의 `question` 필드는 `readings_table.dart`에 이미 정의되어 있어 추가 작업 불필요.

---

## Step 3 — ReadingRepositoryImpl: `updateQuestion` 구현

### Approach

`updateNotes` impl 직후에 `updateQuestion` 추가. `db.readingDao.updateQuestion` 위임.

### Current Code

```dart
// mobile/lib/features/reading/data/repositories/reading_repository_impl.dart:58-61
  @override
  Future<void> updateNotes(String readingId, String? notes) async {
    await db.readingDao.updateNotes(readingId, notes);
  }
```

### After Code

```dart
// mobile/lib/features/reading/data/repositories/reading_repository_impl.dart
  @override
  Future<void> updateNotes(String readingId, String? notes) async {
    await db.readingDao.updateNotes(readingId, notes);
  }

  @override
  Future<void> updateQuestion(String readingId, String? question) async {
    await db.readingDao.updateQuestion(readingId, question);
  }
```

### Considerations

Step 2에서 `ReadingDao.updateQuestion`이 추가된 후에야 컴파일 가능. 순서 의존성: Step 2 → Step 3.

---

## Step 4 — HomePage._startDraw: intentPlacement 분기

### Approach

`_startDraw` 메서드에서 case 3/4에서 `userSettingsProvider`를 read하여 `intentPlacement` 값에 따라 분기.
Lv1/Lv2는 그대로 유지. `intentPlacement == beforeShuffle`일 때만 `intention` 라우트, 그 외엔 `shuffle` 직행.

주의: `_startDraw`는 `_HomePageState` 메서드이므로 `ref`에 직접 접근 가능.

### Current Code

```dart
// mobile/lib/features/home/presentation/pages/home_page.dart:75-96
  void _startDraw(int experienceLevel, String deckId) {
    switch (experienceLevel) {
      case 1:
        context.push('/draw/result');
      case 2:
        context.push('/draw/animated');
      case 3:
        context.pushNamed(
          'intention',
          pathParameters: {'deckId': deckId},
          queryParameters: {'mode': ShuffleMode.flat.code},
        );
      case 4:
        context.pushNamed(
          'intention',
          pathParameters: {'deckId': deckId},
          queryParameters: {'mode': ShuffleMode.perspective.code},
        );
      default:
        context.push('/draw/result');
    }
  }
```

### After Code

```dart
// mobile/lib/features/home/presentation/pages/home_page.dart
  void _startDraw(int experienceLevel, String deckId) {
    final intentPlacement =
        ref.read(userSettingsProvider).valueOrNull?.intentPlacement ??
            IntentPlacement.beforeShuffle;

    switch (experienceLevel) {
      case 1:
        context.push('/draw/result');
      case 2:
        context.push('/draw/animated');
      case 3:
        if (intentPlacement == IntentPlacement.beforeShuffle) {
          context.pushNamed(
            'intention',
            pathParameters: {'deckId': deckId},
            queryParameters: {'mode': ShuffleMode.flat.code},
          );
        } else {
          context.pushNamed(
            'shuffle',
            pathParameters: {'deckId': deckId},
            queryParameters: {'mode': ShuffleMode.flat.code},
          );
        }
      case 4:
        if (intentPlacement == IntentPlacement.beforeShuffle) {
          context.pushNamed(
            'intention',
            pathParameters: {'deckId': deckId},
            queryParameters: {'mode': ShuffleMode.perspective.code},
          );
        } else {
          context.pushNamed(
            'shuffle',
            pathParameters: {'deckId': deckId},
            queryParameters: {'mode': ShuffleMode.perspective.code},
          );
        }
      default:
        context.push('/draw/result');
    }
  }
```

### Considerations

- `ref.read` 사용 이유: navigation 시점 1회 읽기이므로 `ref.watch` 불필요.
- `IntentPlacement` import가 이미 home_page.dart:9에 존재 (`import '../../../settings/domain/entities/intent_placement.dart'`).
- T4(afterDraw), T5(disabled) 모두 `else` 분기로 `/shuffle` 직행 → GREEN.

---

## Step 5 — DeckSelectionPage.onTap: intentPlacement 분기

### Approach

`DeckSelectionPage`는 `ConsumerWidget`이라 `ref`가 이미 `build` 파라미터로 존재.
`onTap` 람다 내부에서 `ref.read(userSettingsProvider).valueOrNull?.intentPlacement`를 읽어 분기.
필요 import: `settings_providers.dart`, `intent_placement.dart`, `shuffle_mode.dart`.

### Current Code

```dart
// mobile/lib/features/deck/presentation/pages/deck_selection_page.dart:40-48
            onTap: () {
                ref.read(selectedDeckProvider.notifier).select(deck);
                context.pushNamed(
                  'intention',
                  pathParameters: {'deckId': deck.id},
                );
              },
```

### After Code

```dart
// mobile/lib/features/deck/presentation/pages/deck_selection_page.dart
            onTap: () {
                ref.read(selectedDeckProvider.notifier).select(deck);
                final intentPlacement =
                    ref.read(userSettingsProvider).valueOrNull?.intentPlacement ??
                        IntentPlacement.beforeShuffle;
                if (intentPlacement == IntentPlacement.beforeShuffle) {
                  context.pushNamed(
                    'intention',
                    pathParameters: {'deckId': deck.id},
                  );
                } else {
                  context.pushNamed(
                    'shuffle',
                    pathParameters: {'deckId': deck.id},
                    queryParameters: {'mode': ShuffleMode.perspective.code},
                  );
                }
              },
```

필요 import 추가:
```dart
import '../../../settings/domain/entities/intent_placement.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../../shuffle/domain/entities/shuffle_mode.dart';
```

### Considerations

- DeckSelectionPage에서 mode를 별도로 받지 않으므로 `ShuffleMode.perspective`를 기본값으로 사용.
  `home_page.dart`의 Lv3/4 분기와 달리 DeckSelectionPage는 experienceLevel을 알지 못하므로 perspective 고정이 합리적.
  향후 DeckSelectionPage에서 mode를 파라미터로 받는 리팩터링은 별도 scope.
- TDD-Red 050의 T4/T5는 `home_page.dart`의 `_startDraw`를 테스트하므로 Step 4로 GREEN 처리됨.
  DeckSelectionPage는 별도 routing 테스트가 없지만 동일 분기 로직을 일관되게 적용.

---

## Step 6 — IntentionPage: redirect 로직

### Approach

`IntentionPage`의 `initState`에서 `addPostFrameCallback`을 추가하여 `intentPlacement != beforeShuffle`이면 `/shuffle`로 redirect.
redirect 중 한 프레임 깜빡임 방지를 위해 `build()`에서 redirect 예정 상태일 때 `const SizedBox.shrink()`를 반환.

구현 패턴:
1. `_shouldRedirect` bool 필드를 `_IntentionPageState`에 추가.
2. `initState`의 기존 `addPostFrameCallback` 블록을 확장하여 redirect 조건 확인.
3. `build()` 첫 줄에서 `_shouldRedirect`가 true이면 `const SizedBox.shrink()` 반환.

`userSettingsProvider` import 필요: `settings_providers.dart`.

### Current Code

```dart
// mobile/lib/features/shuffle/presentation/pages/intention_page.dart:40-51
class _IntentionPageState extends ConsumerState<IntentionPage> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(readingQuestionProvider.notifier).clear();
      }
    });
  }
```

### After Code

```dart
// mobile/lib/features/shuffle/presentation/pages/intention_page.dart
class _IntentionPageState extends ConsumerState<IntentionPage> {
  final _controller = TextEditingController();
  bool _shouldRedirect = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(readingQuestionProvider.notifier).clear();

      final settings = ref.read(userSettingsProvider).valueOrNull;
      final placement = settings?.intentPlacement ?? IntentPlacement.beforeShuffle;
      if (placement != IntentPlacement.beforeShuffle) {
        setState(() => _shouldRedirect = true);
        context.pushReplacementNamed(
          'shuffle',
          pathParameters: {'deckId': widget.deckId},
          queryParameters: {'mode': widget.mode.code},
        );
      }
    });
  }
```

`build()` 시작 부분에 guard 추가:

```dart
  @override
  Widget build(BuildContext context) {
    if (_shouldRedirect) return const SizedBox.shrink();

    if (kDebugMode) {
      // ... 기존 코드 그대로 ...
    }
```

필요 import 추가:
```dart
import '../../../settings/domain/entities/intent_placement.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
```

### Considerations

- `pushReplacementNamed` 사용: 뒤로 가기 시 IntentionPage로 돌아오지 않아야 하므로 push 아닌 replacement.
- `mode` 파라미터 유지: `widget.mode.code`로 현재 모드를 그대로 전달.
- T6(afterDraw redirect) RED → GREEN 목표.
- T7(beforeShuffle 정상 렌더)은 redirect 분기에 진입하지 않아 기존 동작 유지.

---

## Step 7 — DrawResultPage: 조건부 질문 토글 + updateQuestion

### Approach

`DrawResultPage`의 `build()` 내부에서 `userSettingsProvider`를 watch하여 `intentPlacement`를 읽는다.
질문 입력 토글 섹션 전체를 `if (intentPlacement == IntentPlacement.afterDraw)` 로 감싼다.

`updateQuestion` 호출:
- `_updateQuestion()` 메서드를 수정: `_questionController.text`를 `readingQuestionProvider`에 set하는 기존 로직 대신 `readingRepository.updateQuestion()` 호출로 DB에 직접 갱신.
- `afterDraw` 모드에서만 호출 → `build()`에서 이미 `intentPlacement == afterDraw` 가드 내에 TextField가 있으므로 `onSubmitted`에서 `_updateQuestion()`을 호출하면 자연스럽게 조건 충족.

`readingRepositoryProvider` import: 이미 `draw_result_page.dart:9`에 존재.

### Current Code

```dart
// mobile/lib/features/draw/presentation/pages/draw_result_page.dart:132-135
  void _updateQuestion() {
    if (_savedReadingId == null) return;
    ref.read(readingQuestionProvider.notifier).set(_questionController.text);
  }
```

```dart
// mobile/lib/features/draw/presentation/pages/draw_result_page.dart:175-206 (build 내부)
          // ── 질문 입력 토글 ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: GestureDetector(
              onTap: () => setState(() => _questionExpanded = !_questionExpanded),
              child: Row(
                children: [
                  Icon(
                    _questionExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: kGold.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '질문이 있으신가요? (선택)',
                    style: TextStyle(color: kTextSecondary.withValues(alpha: 0.8), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          if (_questionExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: _questionController,
                decoration: mysticalInputDecoration(hintText: '이 뽑기에 대한 질문...', isDense: true),
                style: const TextStyle(color: kTextPrimary, fontSize: 13),
                maxLines: 1,
                onSubmitted: (_) => _updateQuestion(),
              ),
            ),
```

### After Code

`_updateQuestion` 메서드 수정:

```dart
  void _updateQuestion() {
    if (_savedReadingId == null) return;
    final text = _questionController.text;
    ref.read(readingRepositoryProvider).updateQuestion(
      _savedReadingId!,
      text.isEmpty ? null : text,
    );
  }
```

`build()` 내부 질문 토글 섹션 — `intentPlacement` watch 추가 후 조건부 렌더:

```dart
// build() 최상단에 추가 (MysticalScaffold 반환 직전)
    final intentPlacement = ref.watch(userSettingsProvider).valueOrNull?.intentPlacement
        ?? IntentPlacement.beforeShuffle;
```

질문 토글 섹션 전체를 조건부로 감싸기:

```dart
          // ── 질문 입력 토글 (afterDraw 모드 전용) ──
          if (intentPlacement == IntentPlacement.afterDraw) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: GestureDetector(
                onTap: () => setState(() => _questionExpanded = !_questionExpanded),
                child: Row(
                  children: [
                    Icon(
                      _questionExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: kGold.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '질문이 있으신가요? (선택)',
                      style: TextStyle(color: kTextSecondary.withValues(alpha: 0.8), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            if (_questionExpanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  controller: _questionController,
                  decoration: mysticalInputDecoration(hintText: '이 뽑기에 대한 질문...', isDense: true),
                  style: const TextStyle(color: kTextPrimary, fontSize: 13),
                  maxLines: 1,
                  onSubmitted: (_) => _updateQuestion(),
                ),
              ),
          ],
```

필요 import 추가:
```dart
import '../../../settings/domain/entities/intent_placement.dart';
```

### Considerations

- `ref.watch(userSettingsProvider)` — `DrawResultPage`는 `ConsumerStatefulWidget`이므로 `ref`에 접근 가능. `build()` 내부에서 watch로 reactivity 확보.
- `_updateQuestion`에서 `readingRepositoryProvider`는 이미 line:9에 import됨. `updateQuestion`이 Step 1~3에서 추가된 후 사용 가능.
- T8a(afterDraw 토글 표시) — `intentPlacement == afterDraw` 조건 충족 → GREEN 유지.
- T8b(beforeShuffle 숨김) — `intentPlacement != afterDraw` → 토글 미렌더 → GREEN.
- T8c(disabled 숨김) — 동일 → GREEN.

---

## Considerations & Trade-offs

### Structural Decisions Log

1. **DAO 추가 결정**: `ReadingDao.updateQuestion`을 추가하여 타입 안전한 Drift 쿼리 유지. Raw SQL이나 `update().write()` 직접 호출을 Impl에서 하지 않고 DAO로 캡슐화.

2. **redirect 시점**: `addPostFrameCallback` 사용으로 Flutter의 "build 중 setState 금지" 원칙 준수. `build()`에서 직접 navigate 호출은 `setState called during build` 예외 발생.

3. **DrawResultPage question 토글 조건**: `intentPlacement == afterDraw`만 표시. `beforeShuffle`에서 이미 IntentionPage에서 question을 입력했으므로 결과 화면 토글 불필요. `_autoSave`는 `_questionController.text`를 읽는데, `beforeShuffle` 모드에서는 question이 `readingQuestionProvider`에서 오는 것이 아니라 IntentionPage의 별도 컨트롤러에서 옴 — 이것은 기존 Lv1 경로의 동작이므로 그대로 유지.

### Alternative Approaches

- **`IntentionPage.build()`에서 redirect**: 매 rebuild마다 navigate 가능성이 있어 무한 루프 위험. postFrameCallback이 안전.
- **`app_router.dart`에서 redirect**: Brief Decision 6에서 "navigation 콜백에서 분기"로 결정. app_router에 redirect 로직 넣으면 라우트 정의가 비선언적이 됨.
- **`DrawResultPage._autoSave`에서 mode별 question 처리**: `afterDraw` 모드에서 `_autoSave` 시 question=null 저장 후 입력 시 `updateQuestion`으로 갱신하는 2단계 방식이 Brief Decision 5. 결과 화면에서 즉시 떠나면 question=null로 남는 것은 설계 허용 범위.

### Potential Risks

| # | 리스크 | 심각도 | 대응 |
|---|--------|--------|------|
| 1 | `reading_dao.g.dart` 미재생성 시 `updateQuestion` 컴파일 오류 | High | impl 단계에서 `build_runner` 실행 필수 |
| 2 | `IntentionPage` redirect 중 `widget.deckId`/`widget.mode` null | Low | 위젯 생성 시 required 파라미터 보장됨 |
| 3 | `DrawResultPage`에서 `ref.watch(userSettingsProvider)` 로딩 중 null | Low | `?? IntentPlacement.beforeShuffle` 기본값으로 안전 |

### Backward Compatibility

- **기존 사용자 (beforeShuffle 기본값)**: `_startDraw` 분기에서 `beforeShuffle`이면 기존과 동일하게 IntentionPage 경유 → 회귀 없음.
- **DeckSelectionPage**: `beforeShuffle`이면 기존과 동일 → 회귀 없음.
- **DrawResultPage**: `beforeShuffle`이면 질문 토글 미렌더 → 기존 동작에서 토글이 항상 보였으므로 UI 변화 있음. 그러나 Brief Decision 5에서 `beforeShuffle`에서는 IntentionPage에서 이미 입력 완료 → 결과 화면 중복 토글 불필요로 결정됨.

---

## Implementation Checklist

- [ ] Step 1: `reading_repository.dart`에 `updateQuestion` 시그니처 추가
- [ ] Step 2: `reading_dao.dart`에 `updateQuestion` Drift 쿼리 추가
- [ ] Step 3: `reading_repository_impl.dart`에 `updateQuestion` 구현
- [ ] Step 4: `home_page.dart` `_startDraw` Lv3/4 분기 수정
- [ ] Step 5: `deck_selection_page.dart` `onTap` 분기 추가 + imports 추가
- [ ] Step 6: `intention_page.dart` `initState` redirect 로직 + `_shouldRedirect` guard
- [ ] Step 7: `draw_result_page.dart` 질문 토글 조건부 + `_updateQuestion` 수정 + intentPlacement watch
- [ ] `flutter pub run build_runner build --delete-conflicting-outputs` 실행
- [ ] `flutter test mobile/test/features/reading/reading_repository_update_question_test.dart` GREEN 확인
- [ ] `flutter test mobile/test/features/home/intent_placement_routing_test.dart` GREEN 확인
- [ ] `flutter test mobile/test/features/shuffle/intention_page_redirect_test.dart` GREEN 확인
- [ ] `flutter test mobile/test/features/draw/draw_result_question_box_test.dart` GREEN 확인
- [ ] `flutter build apk --debug` 성공

## Verification Assertions

| Level | Assertion | Verification Method | Expected Result |
|-------|-----------|-------------------|-----------------|
| L1-Build | Dart analyze 경고 없음 | `flutter analyze` | 0 warnings (updateQuestion @override 해소) |
| L1-Build | build_runner 성공 | `flutter pub run build_runner build` | 에러 없음 |
| L2-CLI | T1/T2 GREEN | `flutter test ...reading_repository_update_question_test.dart` | 2 tests passed |
| L2-CLI | T4/T5 GREEN | `flutter test ...intent_placement_routing_test.dart` | 4 tests passed (T3 유지 포함) |
| L2-CLI | T6 GREEN | `flutter test ...intention_page_redirect_test.dart` | 2 tests passed |
| L2-CLI | T8b/T8c GREEN | `flutter test ...draw_result_question_box_test.dart` | 3 tests passed (T8a 유지 포함) |
| L1-Build | APK 빌드 성공 | `flutter build apk --debug` | 빌드 성공 |

## References

| Resource | Path/URL | Related Content |
|----------|---------|-----------------|
| TDD Red 050 | `docs/2_tarot_draw/03_draw_experience_settings/050_TDD_Red_cycle3_flow_integration.md` | RED 테스트 목록 및 프로덕션 헬퍼 정의 |
| Brief 040 | `docs/2_tarot_draw/03_draw_experience_settings/040_Brief_intent_placement_setting.md` | 설계 결정 (Decision 4, 5, 6) |
| Scope 041 | `docs/2_tarot_draw/03_draw_experience_settings/041_Scope_intent_placement_setting.md` | 사이클 3 영역 정의 |

## 미비점 및 확장 필요 영역

### Plan 미비점 (makeplan 기록)

| # | 항목 | 심각도 | 설명 |
|---|------|--------|------|
| 1 | `DeckSelectionPage`의 `ShuffleMode` 기본값 | Low | DeckSelectionPage가 experienceLevel을 모르므로 `perspective` 고정. 실제 사용자 설정 experienceLevel과 무관한 mode가 전달될 수 있음. 향후 DeckSelectionPage에 `experienceLevel` 파라미터 추가 필요하면 별도 작업 |
| 2 | `_autoSave`의 `beforeShuffle` mode에서 question 소스 | Low | `_autoSave`는 `_questionController.text`를 읽는데, `beforeShuffle`에서 질문은 `readingQuestionProvider`에서 옴. 현행 코드에서 `_questionController.text`는 항상 빈 문자열이고, `readingQuestionProvider`를 별도로 읽지 않음. 이로 인해 `beforeShuffle` 모드에서도 `reading.question = null`로 저장될 가능성 있음 — 이는 Brief IS#6의 완전한 정합성 구현으로 Cycle 3 이후 추가 작업 필요 |

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
| 2 | user-ai-exchange | 0s | 0 |
| 3 | user-ai-exchange | 0s | 0 |
| 4 | user-ai-exchange | 0s | 0 |
| 5 | user-ai-exchange | 0s | 0 |
| 6 | user-ai-exchange | 0s | 0 |
| 7 | user-ai-exchange | 196s | 462019 |
| 8 | user-ai-exchange | 105088s | 8988850 |
| 9 | user-ai-exchange | 196s | 2025463 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 112172s |
| Total Tokens | 11476332 |
| Input Tokens | 197 |
| Output Tokens | 70885 |
| Cache Read | 10450461 |
| Cache Creation | 954789 |
