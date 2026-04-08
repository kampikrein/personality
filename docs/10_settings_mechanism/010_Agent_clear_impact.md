---
title: "글로벌 상태 clear() 주입 영향 평가"
type: Agent
date: 2026-04-01
author: flutter-expert
confidence: high
summary: |
  shuffleStateProvider.clear()와 readingQuestionProvider.clear()를 뽑기 진입점에
  주입할 때 발생하는 직접/연쇄 영향을 2단계 깊이로 분석한다.
  결론: 올바르게 삽입하면 4개 시나리오 안전, 1개(시나리오 3) Medium 위험으로
  추가 가드가 필요하다. Level 3 진입 지점은 ShufflePage._goToReading() 직전이 최적.
key_findings:
  - "InstantDrawPage._executeDraw(): clear() 후 null 구간 없음 — async 내부에서 즉시 setResult() 호출"
  - "AnimatedDrawPage._startDraw(): readingQuestionProvider.clear() 후 74-78라인 set()이 조건부라 question='' 가능"
  - "ReadingPage:121 null 가드는 '셔플 먼저' 안내 — 시나리오 1 안전"
  - "시나리오 3(Level3 뒤로가기 재진입)은 Medium 위험: ReadingPage에 stale null 상태 표시됨"
  - "시나리오 5(+1 한 장 더 중 clear() 호출)는 발생 경로 없음 — 안전"
related_docs:
  - "docs/10_settings_mechanism/007_Brief_settings_fix.md"
  - "docs/10_settings_mechanism/004_Agent_draw_state.md"
---

# 글로벌 상태 clear() 주입 영향 평가

## 전제 — 변경 요약

```
삽입 대상 provider
  shuffleStateProvider  (keepAlive:true, ShuffleResult?)  → clear() = state = null
  readingQuestionProvider (keepAlive:true, String)         → clear() = state = ''

삽입 지점
  InstantDrawPage._executeDraw()   — initState()에서 호출
  AnimatedDrawPage._startDraw()    — 버튼 onPressed 시 호출
  Level 3 진입 함수               — 아래 L1에서 결정
```

---

## L1 — 직접 영향

### 1-A. ShuffleState.clear() 명세

`mobile/lib/features/shuffle/presentation/providers/shuffle_providers.dart:61`

```dart
@Riverpod(keepAlive: true)
class ShuffleState extends _$ShuffleState {
  @override
  ShuffleResult? build() => null;          // 초기값도 null

  void setResult(ShuffleResult result) {
    ref.read(shuffleRepositoryProvider).cacheLastResult(result);
    state = result;
  }

  void clear() => state = null;            // null로 전이
}
```

- `keepAlive: true` 이므로 앱 수명 내내 인스턴스가 유지된다.
- clear() 호출 직후 `ref.watch(shuffleStateProvider)`를 구독하는 모든 위젯이 즉시 재빌드된다.
- null을 소비하는 유일한 위젯: `ReadingPage:121-126`

```dart
// mobile/lib/features/reading/presentation/pages/reading_page.dart:121-126
if (shuffleResult == null) {
  return Scaffold(
    appBar: AppBar(title: const Text('리딩')),
    body: const Center(child: Text('셔플을 먼저 진행해주세요.')),
  );
}
```

- InstantDrawPage와 AnimatedDrawPage는 shuffleStateProvider를 `watch`하지 않고
  `read`(혹은 로컬 `_shuffleResult` 변수) 기반으로 동작한다.
  따라서 이 두 페이지에서 null이 표시될 위험은 없다.

### 1-B. InstantDrawPage._executeDraw() 삽입 시 null 구간 분석

`mobile/lib/features/draw/presentation/pages/instant_draw_page.dart:54-74`

```dart
Future<void> _executeDraw() async {
  // ← 여기에 clear() 삽입 예정
  final repo = ref.read(deckRepositoryProvider);
  await repo.seedRwsDeck();                         // ← await 지점

  final cards = await ref.read(deckCardsProvider(_deckId).future);  // ← await 지점
  final useCase = ref.read(shuffleDeckUseCaseProvider);
  final strategy = ref.read(shuffleStrategyProvider);
  final result = useCase.execute(cards: cards, strategy: strategy);
  ref.read(shuffleStateProvider.notifier).setResult(result);        // null 해소

  setState(() { _shuffleResult = result; _loading = false; ... });
}
```

**null 구간 존재 여부:** clear() 직후 `seedRwsDeck`과 `deckCardsProvider` 두 개의
await 지점이 있다. 이 구간에서 shuffleStateProvider는 null 상태다.

**위험 판정:** InstantDrawPage 자체는 shuffleStateProvider를 watch하지 않는다.
`_loading = true`(initState 기본값)이므로 CircularProgressIndicator를 표시한다.
ReadingPage가 스택에 없으므로 null이 노출되지 않는다.

판정: **안전 (null 구간 존재하나 소비 위젯 없음)**

### 1-C. AnimatedDrawPage._startDraw() 삽입 시 null 구간 분석

`mobile/lib/features/draw/presentation/pages/animated_draw_page.dart:62-88`

```dart
Future<void> _startDraw() async {
  // ← 여기에 shuffleStateProvider.clear() + readingQuestionProvider.clear() 삽입 예정
  final repo = ref.read(deckRepositoryProvider);
  await repo.seedRwsDeck();

  final cards = await ref.read(deckCardsProvider(_deckId).future);
  final useCase = ref.read(shuffleDeckUseCaseProvider);
  final strategy = ref.read(shuffleStrategyProvider);
  final result = useCase.execute(cards: cards, strategy: strategy);
  ref.read(shuffleStateProvider.notifier).setResult(result);       // null 해소

  // 질문 세팅 (74-78라인)
  final question = _questionController.text;
  if (question.isNotEmpty) {                                       // ← 조건부 set
    ref.read(readingQuestionProvider.notifier).set(question);
  }
  ...
}
```

**readingQuestionProvider 경쟁 조건:**
- `clear()` 호출 → `state = ''`
- 이후 `question.isNotEmpty` 조건이 `true`이면 set() 호출 → 정상
- 조건이 `false`(질문 없음)이면 `state = ''` 유지 → 의도된 동작

clear()가 74-78라인 set()을 무효화할 수 있는가? 없다.
clear()는 _startDraw() 시작 시 호출되고, set()은 셔플 완료 후 호출된다.
순서: `clear() → await → setResult() → (조건부)set()`. 순서 보장됨.

**단, 주의 사항:** "질문 없이 바로 뽑기" 버튼(line 273-278)은
`_questionController.clear(); _startDraw();` 순서로 호출된다.
이 경우 clear() 후 `_questionController.text == ''` 이므로 `question.isNotEmpty == false`.
readingQuestionProvider는 `''`로 유지 → 의도된 동작.

판정: **안전 (순서 보장, 조건부 set은 clear 이후에 실행)**

### 1-D. Level 3 진입 함수 — clear() 삽입 위치 결정

Level 3 경로: `IntentionPage → ShufflePage → ReadingPage`

흐름도:
```
IntentionPage (진입)
  ↓ pushNamed('shuffle')
ShufflePage
  ↓ _goToReading() 버튼 클릭
    → shuffleDeckUseCase.execute()
    → shuffleStateProvider.setResult(result)   ← 여기서 새 결과 세팅
    → pushNamed('reading')
ReadingPage
  ↓ ref.watch(shuffleStateProvider)            ← 새 결과 표시
```

**IntentionPage 진입 시 clear() 삽입:**
- IntentionPage에서 clear() 호출 시, ShufflePage 탐색 중, _goToReading() 전까지
  shuffleStateProvider == null.
- 그러나 이 구간에 ReadingPage가 스택에 없으면 null 노출 없음.
- 문제: 사용자가 IntentionPage에서 뒤로가기를 하면 이전 ReadingPage가 pop 됐으므로 없음.
  단, 시나리오 3(뒤로가기 재진입) 상황에서는 별도 분석 필요.

**ShufflePage._goToReading() 직전 clear() 삽입 (권장):**

`mobile/lib/features/shuffle/presentation/pages/shuffle_page.dart:52-67`

```dart
Future<void> _goToReading() async {
  // ← 여기에 clear() 삽입 (가장 안전한 지점)
  ref.read(hapticServiceProvider).mediumImpact();
  final cards = await ref.read(deckCardsProvider(widget.deckId).future);
  ...
  ref.read(shuffleStateProvider.notifier).setResult(result);   // 즉시 해소
  ...
  await context.pushNamed('reading', ...);
}
```

- clear() 직후 바로 setResult()가 호출되는 구간이 최소화된다.
- null 구간 = `deckCardsProvider` 로딩 시간 뿐 (ReadingPage는 아직 스택에 없음).

판정: **ShufflePage._goToReading() 직전 삽입이 최적. IntentionPage 진입 시 삽입은 필요 없음.**

### 1-E. ReadingPage의 null 처리 확인

`mobile/lib/features/reading/presentation/pages/reading_page.dart:106-126`

```dart
final shuffleResult = ref.watch(shuffleStateProvider);   // line 106: null 가능

if (shuffleResult == null) {                             // line 121
  return Scaffold(
    appBar: AppBar(title: const Text('리딩')),
    body: const Center(child: Text('셔플을 먼저 진행해주세요.')),
  );
}
```

null 가드가 존재하며, null 시 안내 문구를 표시한다.
단, 이 화면이 스택에 남아 있는 상태에서 clear()가 호출되면 화면 전환이 발생한다.
자세한 시나리오는 L2에서 분석.

---

## L2 — 연쇄 영향 시나리오

### 시나리오 1: 뽑기 완료 → 홈 복귀 → 뒤로가기로 결과 재진입

경로:
```
Level 1/2: InstantDrawPage / AnimatedDrawPage → (홈 버튼) → context.go('/') → 홈
  → (뒤로가기 불가: go는 스택 교체) → 결과 페이지 없음
Level 3:   ReadingPage → (백 버튼) → ShufflePage → (백 버튼) → IntentionPage → ...
```

**Level 1/2 분석:**
- `context.go('/')` 호출 시 GoRouter 스택이 `[홈]`으로 교체된다.
- 이전 DrawPage는 dispose된다.
- 뒤로가기 pop으로 결과 페이지에 돌아가는 경로 자체가 없다.
- 다시 "뽑기 시작" 클릭 시 새로운 페이지 인스턴스가 push되고, initState에서
  `_executeDraw()` 또는 `_startDraw()` 준비 상태로 시작한다.
  (Level 1은 즉시 실행, Level 2는 사용자가 버튼을 눌러야 실행)
- clear() 삽입 후: _executeDraw()/_startDraw() 진입 시 state=null → setResult() → 결과 표시.

판정: **안전 (Low)** — 이전 결과 노출 경로 없음. clear() 정상 동작.

### 시나리오 2: 뽑기 진행 중 앱 백그라운드→포그라운드 전환

`shuffleStateProvider`와 `readingQuestionProvider` 모두 `keepAlive: true`.

- 앱이 백그라운드 전환 시 Flutter 위젯 트리는 유지되고 Riverpod provider는
  keepAlive 설정에 따라 메모리에 유지된다.
- 포그라운드 복귀 시 provider는 dispose/rebuild 되지 않는다.
- clear()는 사용자가 버튼을 눌러 _startDraw()/_executeDraw()를 **명시적으로 호출**할 때만 실행된다.

**Level 1 (InstantDrawPage):**
- initState에서 _executeDraw() 호출 → 페이지 인스턴스 생성 시 1회만 실행.
- 백그라운드 전환 후 포그라운드 복귀는 페이지 재생성 없음 → initState 미호출 → clear() 미호출.
- `_shuffleResult` 로컬 변수는 메모리에 유지. `_loading = false`. 결과 그대로 표시.

판정: **안전 (Low)** — 진행 중인 뽑기 결과가 clear되지 않는다. keepAlive로 state 유지.

**Level 2 (AnimatedDrawPage):**
- _startDraw()는 버튼 클릭 시에만 호출. 백그라운드 전환 중 clear() 없음.
- 애니메이션 중 백그라운드 전환 시 `_playAnimations()` await 구간이 중단될 수 있으나,
  포그라운드 복귀 시 `mounted` 체크로 안전하게 처리된다(line 117, 146).

판정: **안전 (Low)**

### 시나리오 3: Level 3 — IntentionPage 진입 시 clear() → 뒤로가기로 이전 ReadingPage 재진입

**이 시나리오는 삽입 위치에 따라 위험도가 달라진다.**

**Case A: IntentionPage 진입 시 clear() 삽입 (권장하지 않는 패턴)**

```
ReadingPage (결과 표시 중)
  → 뒤로가기 → ShufflePage
  → 뒤로가기 → IntentionPage ← clear() 호출
  → 뒤로가기 → ReadingPage (스택에 살아있음)
```

ReadingPage가 네비게이션 스택에 남아 있는 경우, IntentionPage에서 clear()가 호출되면
`ref.watch(shuffleStateProvider) == null`이 되어 ReadingPage가 즉시 재빌드된다.
결과: "셔플을 먼저 진행해주세요." 표시. 사용자 경험 손상.

GoRouter `push` 기반 스택에서 이 경로가 실제로 발생하는가?

`app_router.dart` 분석:
- `/shuffle/:deckId` → ShufflePage: `_fadePage(key: state.pageKey, ...)`
- `/intention/:deckId` → IntentionPage: `_fadePage(key: state.pageKey, ...)`
- `/reading/:deckId` → ReadingPage: `_fadePage(key: state.pageKey, ...)`

ShufflePage._goToReading():
```dart
await context.pushNamed('reading', pathParameters: {'deckId': widget.deckId});
```
`push` 사용 → ReadingPage가 스택에 추가된다. pop 시 ShufflePage로 복귀 가능.

IntentionPage에서 ShufflePage로의 이동:
```dart
context.pushNamed('shuffle', pathParameters: {'deckId': widget.deckId});
```
`push` 사용 → IntentionPage도 스택에 유지.

따라서 스택이 `[..., IntentionPage, ShufflePage, ReadingPage]`가 될 수 있고,
ReadingPage에서 두 번 뒤로가기 하면 IntentionPage로 돌아간다.
이때 IntentionPage에 clear() 삽입 코드가 있다면 **ReadingPage가 백그라운드에서 null 재빌드된다.**

판정: **Medium 위험** — IntentionPage 진입 시 clear() 삽입은 하지 말 것.

**Case B: ShufflePage._goToReading() 직전 clear() 삽입 (권장 패턴)**

```
ReadingPage (결과 표시 중)
  → 뒤로가기 → ShufflePage
  → "뽑기" 버튼 클릭 → _goToReading() → clear() 호출 → setResult() → pushNamed('reading')
```

clear()가 실행되는 시점에 ReadingPage는 스택에 있지만 화면에 보이지 않는다(ShufflePage가 top).
clear() → setResult() 간격이 매우 짧다(동기 코드: execute()는 비동기 없음).

실제로 `deckCardsProvider` await만 있으며, 이 시간 동안 null 상태가 ReadingPage에
전달되어 재빌드될 수 있다. 그러나 ReadingPage는 화면에 표시되지 않으므로 사용자에게 보이지 않는다.
ShufflePage가 pop되고 새 ReadingPage가 push될 때 새 결과가 이미 세팅되어 있다.

판정: **안전 (Low)** — ShufflePage._goToReading() 직전 삽입이면 사용자 노출 없음.

### 시나리오 4: Level 2 — 질문 입력 후 _startDraw() 시 clear() vs set() 순서

`mobile/lib/features/draw/presentation/pages/animated_draw_page.dart:62-88`

실행 순서:
```
1. _startDraw() 시작
2. readingQuestionProvider.notifier.clear()     → state = ''
3. await repo.seedRwsDeck()
4. await deckCardsProvider.future
5. useCase.execute() [동기]
6. shuffleStateProvider.notifier.setResult(result)  → state = result
7. final question = _questionController.text          ← 컨트롤러에서 직접 읽음
8. if (question.isNotEmpty) {
9.   readingQuestionProvider.notifier.set(question)   → state = question
10. }
```

핵심: 7라인에서 readingQuestionProvider를 읽는 것이 아니라 `_questionController.text`를
직접 읽는다. readingQuestionProvider.clear()로 provider state가 ''가 되어도
`_questionController`는 영향을 받지 않는다.

따라서 사용자가 질문을 입력했다면 step 7에서 question.isNotEmpty == true이고
step 9에서 정상 세팅된다.

판정: **안전 (Low)** — clear()와 set()의 독립성이 보장됨. 데이터 소스가 다름.

### 시나리오 5: "+1 한 장 더" 버튼 사용 중 clear() 호출 여부

Level 1 (`InstantDrawPage._addOneMore`):
- `_executeDraw()`는 `initState()`에서 1회만 호출된다.
- `_addOneMore()`는 clear()를 호출하지 않는다.
- 사용자가 "+1" 버튼을 누르는 동안 다른 경로로 _executeDraw()가 재호출되지 않는다.

Level 2 (`AnimatedDrawPage._addOneMore`):
- `_startDraw()`는 버튼 클릭 시에만 호출된다.
- "+1" 버튼과 "카드 뽑기" 버튼은 서로 다른 UI 상태에 표시된다.
  (`_shuffleExecuted == false` → 뽑기 버튼 표시, `_shuffleExecuted == true` → "+1" 표시)
- 동시에 두 버튼이 활성화되는 경로 없음.

Level 3 (`ReadingPage._addOneMore`):
- _addOneMore()는 shuffleResult를 매개변수로 받는다(line 77).
- clear()를 호출하는 코드 없음.

판정: **안전 (Low)** — "+1 한 장 더" 사용 중 clear()가 호출되는 경로 없음.

---

## 종합 위험도 매트릭스

| 시나리오 | 위험도 | 판정 | 조건 |
|---------|--------|------|------|
| S1: 완료→홈→재진입 | Low | 안전 | go()로 스택 교체되어 재진입 경로 없음 |
| S2: 백그라운드→포그라운드 | Low | 안전 | keepAlive 유지, clear() 미호출 |
| S3-A: IntentionPage 진입 시 clear() | Medium | 위험 | 스택의 ReadingPage가 null 재빌드됨 |
| S3-B: ShufflePage._goToReading() 직전 clear() | Low | 안전 | 화면에 보이지 않는 상태에서 일시 null |
| S4: _startDraw() 내 clear() vs set() 순서 | Low | 안전 | 독립적 데이터 소스, 순서 보장 |
| S5: +1 중 clear() 호출 | Low | 안전 | 해당 경로 없음 |

---

## 권장 삽입 코드

### Level 1 — InstantDrawPage._executeDraw() 선두

```dart
Future<void> _executeDraw() async {
  // [추가] 이전 뽑기 상태 초기화
  ref.read(shuffleStateProvider.notifier).clear();
  ref.read(readingQuestionProvider.notifier).clear();

  final repo = ref.read(deckRepositoryProvider);
  await repo.seedRwsDeck();
  ...
}
```

### Level 2 — AnimatedDrawPage._startDraw() 선두

```dart
Future<void> _startDraw() async {
  // [추가] 이전 뽑기 상태 초기화
  ref.read(shuffleStateProvider.notifier).clear();
  ref.read(readingQuestionProvider.notifier).clear();

  final repo = ref.read(deckRepositoryProvider);
  await repo.seedRwsDeck();
  ...
  // 기존 질문 세팅(74-78) 코드는 그대로 유지 — _questionController 기반이므로 충돌 없음
}
```

### Level 3 — ShufflePage._goToReading() 선두

```dart
Future<void> _goToReading() async {
  // [추가] 이전 뽑기 상태 초기화
  ref.read(shuffleStateProvider.notifier).clear();
  // readingQuestionProvider는 IntentionPage에서 set()이 이미 완료된 상태.
  // _goToReading에서 clear()하면 질문이 사라지므로 여기서는 shuffleState만 clear.

  ref.read(hapticServiceProvider).mediumImpact();
  final cards = await ref.read(deckCardsProvider(widget.deckId).future);
  ...
  ref.read(shuffleStateProvider.notifier).setResult(result);  // 즉시 해소
  await context.pushNamed('reading', pathParameters: {'deckId': widget.deckId});
}
```

**Level 3에서 readingQuestionProvider.clear() 위치:**
- IntentionPage에서 set()을 호출한 후 ShufflePage로 이동하고, _goToReading() 시점에는
  질문이 이미 세팅되어 있어야 한다.
- _goToReading()에서 readingQuestionProvider.clear()를 호출하면 질문이 사라진다.
- 따라서 Level 3에서 readingQuestionProvider.clear()는 **IntentionPage 초기화 시점**
  (build() 또는 initState())에 호출하는 것이 의미상 올바르다.
  단, 위에서 분석한 시나리오 3-A 위험이 있으므로 initState에서만 호출한다.

```dart
// IntentionPage._IntentionPageState.initState() — 추가 권장
@override
void initState() {
  super.initState();
  // 새 리딩 시작 시 이전 질문 초기화
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(readingQuestionProvider.notifier).clear();
  });
}
```

---

## 최종 판단

1. shuffleStateProvider.clear() 삽입은 Level 1/2/3 모두 해당 함수 선두에서 안전.
2. readingQuestionProvider.clear() 삽입 시 Level 1/2는 함수 선두 삽입이 안전.
   Level 3에서는 IntentionPage initState(addPostFrameCallback)에 삽입하며,
   ShufflePage._goToReading()에는 삽입하지 않는다.
3. IntentionPage 진입 시 shuffleStateProvider.clear() 삽입은 불필요하고
   시나리오 3-A 위험을 유발하므로 권장하지 않는다.
4. "+1 한 장 더" 동작에는 영향 없음.

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
| 25 | user-ai-exchange | 29s | 234056 |
| 26 | user-ai-exchange | 3s | 48718 |
| 27 | user-ai-exchange | 13s | 54002 |
| 28 | user-ai-exchange | 9s | 55309 |
| 29 | user-ai-exchange | 10s | 58339 |
| 30 | user-ai-exchange | 11s | 61129 |
| 31 | user-ai-exchange | 7s | 62416 |
| 32 | user-ai-exchange | 0s | 0 |
| 33 | user-ai-exchange | 10s | 63892 |
| 34 | user-ai-exchange | 22s | 67713 |
| 35 | user-ai-exchange | 9s | 69028 |
| 36 | user-ai-exchange | 21s | 215578 |
| 37 | user-ai-exchange | 174s | 517468 |
| 38 | user-ai-exchange | 418s | 1153988 |
| 39 | user-ai-exchange | 80s | 692099 |
| 40 | user-ai-exchange | 56s | 453585 |
| 41 | user-ai-exchange | 134s | 1054142 |
| 42 | user-ai-exchange | 587s | 979519 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 478862s |
| Total Tokens | 7432515 |
| Input Tokens | 166 |
| Output Tokens | 55553 |
| Cache Read | 6567656 |
| Cache Creation | 809140 |
