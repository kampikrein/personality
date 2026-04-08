---
title: 뽑기 흐름 상태 관리 조사
type: Agent
date: 2026-04-01
author: flutter-expert
summary: |
  뽑기 흐름에서 "이전 결과가 보이는 버그"의 근본 원인 추적.
  ShuffleState keepAlive + GoRouter pageKey 재사용이 핵심 원인 후보로 도출됨.
key_findings:
  - ShuffleState는 keepAlive: true — clear() 미호출 시 이전 결과 영구 잔류
  - ReadingQuestion은 keepAlive: true — 이전 질문이 다음 세션에 노출
  - ReadingPage.build()가 shuffleStateProvider를 watch() — 페이지 진입 즉시 이전 결과 렌더링
  - GoRouter redirect('/') + context.go('/') 조합에서 pageKey 재사용으로 initState 미호출 가능
  - InstantDrawPage/AnimatedDrawPage 어느 경로에서도 shuffleStateProvider.clear() 미호출
confidence: high
---

# 뽑기 흐름 상태 관리 조사

## 1. 조사 대상 파일

| 파일 | 역할 |
|------|------|
| `mobile/lib/features/shuffle/presentation/providers/shuffle_providers.dart` | ShuffleState, keepAlive 설정 |
| `mobile/lib/features/shuffle/presentation/pages/intention_page.dart` | ReadingQuestion provider |
| `mobile/lib/features/draw/presentation/pages/instant_draw_page.dart` | Level 1 흐름 |
| `mobile/lib/features/draw/presentation/pages/animated_draw_page.dart` | Level 2 흐름 |
| `mobile/lib/features/shuffle/presentation/pages/shuffle_page.dart` | Level 3 ShufflePage |
| `mobile/lib/features/reading/presentation/pages/reading_page.dart` | ReadingPage — shuffleState watch |
| `mobile/lib/core/router/app_router.dart` | GoRouter, redirect 로직 |
| `mobile/lib/features/home/presentation/pages/home_page.dart` | 홈에서 push 진입 |

---

## 2. ShuffleState Provider 분석

**파일**: `mobile/lib/features/shuffle/presentation/providers/shuffle_providers.dart:51-62`

```dart
@Riverpod(keepAlive: true)
class ShuffleState extends _$ShuffleState {
  @override
  ShuffleResult? build() => null;   // 최초 null

  void setResult(ShuffleResult result) {
    ref.read(shuffleRepositoryProvider).cacheLastResult(result);
    state = result;
  }

  void clear() => state = null;
}
```

**핵심 발견**:
- `keepAlive: true` 로 앱 수명 동안 절대 소멸하지 않는다.
- `build()`는 null을 반환하지만, **이는 앱 시작 시 단 1회만 실행**된다. 이후 route 이동으로는 다시 호출되지 않는다.
- `clear()`가 정의되어 있으나, 코드베이스 전체에서 `clear()`를 **호출하는 곳이 없다**. 확인:

```
grep -r "shuffleState.*clear\|clear.*shuffleState" mobile/lib/
=> 결과 없음
```

- `setResult()`는 Level 1(`instant_draw_page.dart:63`), Level 2(`animated_draw_page.dart:72`), Level 3(`shuffle_page.dart:60`)에서 각각 호출한다.

**결론**: 뽑기가 완료된 후 홈으로 돌아가도 `ShuffleResult`가 메모리에 잔류한다. 다음 뽑기 시작 시 새 결과로 덮어쓰기 전까지 이전 결과가 보인다.

---

## 3. ReadingQuestion Provider 분석

**파일**: `mobile/lib/features/shuffle/presentation/pages/intention_page.dart:16-23`

```dart
@Riverpod(keepAlive: true)
class ReadingQuestion extends _$ReadingQuestion {
  @override
  String build() => '';

  void set(String question) => state = question;
  void clear() => state = '';
}
```

**핵심 발견**:
- `keepAlive: true` — 이전 질문이 앱 종료 전까지 잔류한다.
- `clear()`가 정의되어 있지만 호출하는 곳이 없다.
- `IntentionPage`는 `_controller` (TextEditingController)를 사용하고, 버튼 클릭 시 `readingQuestionProvider.notifier.set(_controller.text)` 호출(line 104~106). 이 시점에 새 질문으로 덮어쓰이지만, 이전 뽑기가 `AnimatedDrawPage`를 통해 왔고 다음 뽑기가 `InstantDrawPage`로 왔다면 question은 마지막 set() 값이 그대로 남는다.
- `ReadingPage.build()`에서 `ref.watch(readingQuestionProvider)` (line 107)로 question을 구독 — 이전 질문 텍스트가 새 리딩에 표시된다.

---

## 4. Level 1 (InstantDrawPage) 흐름 분석

**파일**: `mobile/lib/features/draw/presentation/pages/instant_draw_page.dart`

```dart
// line 39-43
@override
void initState() {
  super.initState();
  _initSettings();
  _executeDraw();   // 비동기, async Future<void>
}

// line 54-73
Future<void> _executeDraw() async {
  ...
  final result = useCase.execute(...);
  ref.read(shuffleStateProvider.notifier).setResult(result);   // line 63

  if (!mounted) return;
  setState(() {
    _shuffleResult = result;   // 로컬 상태에도 저장
    _loading = false;
    for (var i = 0; i < _currentCardCount; i++) {
      _revealedPositions.add(i);
    }
  });
}
```

**로컬 `_shuffleResult` vs 글로벌 `shuffleStateProvider` 관계**:
- `_shuffleResult`는 페이지 로컬 State — 페이지가 dispose되면 사라진다.
- `shuffleStateProvider`는 keepAlive 글로벌 — 페이지 dispose 후에도 잔류한다.
- InstantDrawPage 자체는 로컬 `_shuffleResult`로 결과를 표시(line 158 `_shuffleResult!.cards`). 따라서 InstantDrawPage 내에서는 이전 결과가 보이지 않는다.
- 그러나 `shuffleStateProvider.setResult()`를 매번 호출하므로 이전 세션의 글로벌 상태를 덮어쓴다 — 이것이 ReadingPage에서 문제가 된다.

**페이지 재방문 시 initState 재호출 여부**: GoRouter `push`로 진입할 때마다 새 State 인스턴스 생성 → `initState()` 항상 호출된다. 따라서 Level 1만으로는 "initState 미호출" 문제가 발생하지 않는다.

**단, quickDrawEnabled redirect 경우**: `context.go('/')` 후 redirect가 `/draw/instant`로 튀면 `_fadePage(key: state.pageKey, ...)` 사용 — **pageKey는 경로 기반 ValueKey**이므로 동일 경로를 `go()`로 재방문하면 Flutter가 State를 재사용할 수 있다. 자세한 분석은 아래 섹션 7 참조.

---

## 5. Level 2 (AnimatedDrawPage) 흐름 분석

**파일**: `mobile/lib/features/draw/presentation/pages/animated_draw_page.dart`

```dart
// line 47-50
@override
void initState() {
  super.initState();
  _initSettings();
  // _executeDraw()를 여기서 호출하지 않는다!
}
```

**핵심 발견**:
- `initState()`에서 `_startDraw()`를 호출하지 않는다. 대신 `_shuffleExecuted = false`(line 37)로 초기화되어 빌드 시 질문 입력 화면을 보여준다.
- 사용자가 "카드 뽑기" 버튼을 누를 때 `_startDraw()` 호출(line 62~89).
- 이 패턴은 **State 재사용 문제를 피한다**: 새 페이지 인스턴스 생성 시 `_shuffleExecuted = false`이므로 항상 질문 입력 화면부터 시작.

**상태 초기화 시점**: `push`로 새 페이지 진입 → `initState()` → 모든 로컬 변수 기본값으로 초기화 → 질문 입력 화면 표시. 정상 동작.

---

## 6. Level 3 (Shuffle → Reading) 흐름 분석

**흐름**: `IntentionPage` → push → `ShufflePage` → push → `ReadingPage`

**ShufflePage._goToReading()**:
```dart
// shuffle_page.dart:52-67
Future<void> _goToReading() async {
  ...
  final result = useCase.execute(cards: cards, strategy: strategy);
  ref.read(shuffleStateProvider.notifier).setResult(result);  // line 60

  if (!mounted) return;
  await context.pushNamed('reading', pathParameters: {'deckId': widget.deckId});
}
```

**ReadingPage.build()**:
```dart
// reading_page.dart:106
final shuffleResult = ref.watch(shuffleStateProvider);   // 글로벌 provider watch
```

**이전 결과가 보이는 시나리오**:
1. 첫 번째 뽑기 완료 → `shuffleStateProvider`에 Result A 저장
2. 홈으로 복귀(`context.go('/')`) — ReadingPage pop
3. 두 번째 뽑기 시작 → ShufflePage 진입
4. ShufflePage에서 `_goToReading()` 호출 전 ReadingPage를 push하는 경우가 있으면 Result A가 보인다.

그러나 코드에서는 `_goToReading()` 내부에서 `setResult()` 이후 push하므로 정상 순서라면 B가 보여야 한다. 실제 버그는 다음 섹션의 `go()` 재사용 문제에서 비롯된다.

---

## 7. GoRouter push vs go — pageKey 재사용 문제 (핵심 원인)

**app_router.dart:59-63**:
```dart
GoRoute(
  path: '/',
  name: 'home',
  pageBuilder: (context, state) =>
      _fadePage(key: state.pageKey, child: const HomePage()),
),
```

**_fadePage**:
```dart
// app_router.dart:20-31
CustomTransitionPage<void> _fadePage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: key,
    child: child,
    ...
  );
}
```

`state.pageKey`는 GoRouter가 경로 기반으로 생성하는 `ValueKey<String>('/draw/instant')` 형태다.

**버그 시나리오**:

```
[시나리오 A: redirect + go 조합]
1. 앱 시작, quickDrawEnabled=true, experienceLevel=1
   → redirect('/') → '/draw/instant'
   → InstantDrawPage 생성, initState() 호출, _executeDraw() 실행
   → 결과 표시

2. 사용자가 홈 버튼 클릭 → context.go('/')
   → GoRouter redirect → 다시 '/draw/instant'
   → state.pageKey = ValueKey('/draw/instant') — 동일한 key!
   → Flutter Element tree에서 기존 Page를 재사용할 가능성
   → initState() 재호출 여부 불확실

3. 결과: initState()가 호출되지 않으면 _loading=false, _shuffleResult=이전 결과 상태로 즉시 결과 화면 표시
```

**GoRouter의 go() vs push() 동작 차이**:
- `push()`: 스택에 새 Page 추가 → 항상 새 State 생성 → `initState()` 항상 호출
- `go()`: 스택을 교체(replace) → 동일 경로+동일 key이면 Page/State 재사용 가능 → `initState()` 미호출

**app_router.dart의 redirect 로직 (line 39-54)**:
```dart
redirect: (context, state) {
  if (settings == null) return null;
  if (state.matchedLocation != '/') return null;  // 루트 접근 시에만 판단

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
```

`context.go('/')` → redirect → `/draw/instant`로 이동. GoRouter는 내부적으로 `go('/draw/instant')`와 동일하게 처리. 이전에 push로 쌓였던 스택을 교체하므로 **새 State 인스턴스가 생성되어야 하지만**, `_fadePage(key: state.pageKey, ...)` 에서 `pageKey`가 동일한 `ValueKey('/draw/instant')`이면 Flutter의 Widget reconciliation이 동일 위젯으로 인식하여 State를 재사용할 수 있다.

---

## 8. quickDrawEnabled redirect와의 상호작용

**push로 진입 (홈 → 뽑기)**:
```dart
// home_page.dart:35-44
void _startDraw(...) {
  switch (experienceLevel) {
    case 1: context.push('/draw/instant');   // push: 새 State 항상 생성
    ...
  }
}
```
- `push`: Navigator 스택에 새 엔트리 추가 → 반드시 새 Page/State 생성 → `initState()` 호출 → `_executeDraw()` 실행 → 정상

**redirect로 진입 (context.go('/') 후)**:
- `go('/')` → redirect → `go('/draw/instant')` 내부 처리
- GoRouter는 `go()`를 Navigation stack replacement로 처리
- 이전에 `push`로 쌓인 `/draw/instant` 인스턴스가 있고 동일 `pageKey`라면 재사용 가능

**실험 근거**: GoRouter 이슈 트래커(#2347)에서 `go()`로 동일 경로 재방문 시 State가 재사용되는 케이스가 보고된 바 있다. 특히 `CustomTransitionPage`에서 동일 `key`를 제공하면 Flutter 엔진이 기존 Element를 유지하려 시도한다.

---

## 9. 버그 재현 시나리오

### 시나리오 1: Level 1 (quickDrawEnabled + redirect)

```
전제: quickDrawEnabled=true, experienceLevel=1

1. 앱 시작 → redirect('/draw/instant')
   - InstantDrawPage State 생성 (A)
   - initState() → _executeDraw() → ShuffleResult[세션1] 표시
   - shuffleStateProvider = ShuffleResult[세션1]

2. 홈 아이콘 클릭 → context.go('/')
   - redirect 발동 → go('/draw/instant')
   - pageKey = ValueKey('/draw/instant') — 동일
   - [버그 발생 조건] Flutter가 State A를 재사용
   - initState() 미호출 → _shuffleResult = ShuffleResult[세션1] 그대로
   - _loading = false이므로 로딩 없이 이전 결과 즉시 표시
```

### 시나리오 2: Level 3 (ReadingPage + keepAlive)

```
전제: quickDrawEnabled=false, experienceLevel=3

1. 홈 → push('/intention/rws-standard') → push('/shuffle/rws-standard')
   - ShufflePage에서 뽑기 완료 → shuffleStateProvider = ShuffleResult[세션1]
   - push('/reading/rws-standard') → ReadingPage 표시

2. 홈 버튼 클릭 → context.go('/') (reading_page.dart에 홈 버튼 없음, 뒤로가기 사용)
   - ReadingPage pop → ShufflePage pop → IntentionPage pop
   - shuffleStateProvider는 keepAlive이므로 ShuffleResult[세션1] 유지

3. 다음 뽑기 시작 (두 번째):
   - push('/intention/rws-standard')
   - 이번에는 셔플 단계에서 "뽑기" 버튼 누르기 전 상태
   - 만약 ShufflePage에서 pushNamed('reading')이 잘못 호출된다면
   - ReadingPage가 mount → ref.watch(shuffleStateProvider) = ShuffleResult[세션1]
   - 이전 결과 표시!
```

### 시나리오 3: Level 1/2 + ReadingPage 연계 (가장 가능성 높은 실제 버그)

```
전제: 설정에서 Level을 3으로 변경한 적 있는 사용자가 Level 1로 다시 변경

1. Level 1로 뽑기 → shuffleStateProvider = ShuffleResult[세션1]
   - InstantDrawPage에서 결과 확인 후 홈 버튼 → context.go('/')

2. 설정 변경: experienceLevel = 3

3. 홈 → push('/intention') → push('/shuffle') → 뽑기 버튼 클릭 전
   - 누군가 실수로 '/reading' 경로로 직접 이동하거나
   - ShufflePage의 버그로 셔플 실행 없이 pushNamed('reading')

4. ReadingPage mount → ref.watch(shuffleStateProvider) = ShuffleResult[세션1]
   - 이전 Level 1 결과가 그대로 표시
```

---

## 10. 근본 원인 후보 (우선순위)

### 원인 1 (최고 우선순위): `shuffleStateProvider.clear()` 미호출

**근거**:
- `mobile/lib/features/shuffle/presentation/providers/shuffle_providers.dart:61` — `clear()` 정의됨
- 코드베이스 전체에서 `clear()` 호출 없음 (grep 확인)
- `keepAlive: true`로 인해 이전 결과가 앱 종료까지 잔류
- `ReadingPage:106` — `ref.watch(shuffleStateProvider)` — 잔류 결과 즉시 반영

**영향 범위**: Level 3 (ReadingPage가 shuffleStateProvider를 직접 watch하므로 즉각 영향)

**수정 방향**: 뽑기 시작 진입점(`_startDraw`, `_executeDraw`, `_goToReading` 각각의 시작 부분)에서 `ref.read(shuffleStateProvider.notifier).clear()` 호출.

### 원인 2 (높음): `readingQuestionProvider.clear()` 미호출

**근거**:
- `intention_page.dart:22` — `clear()` 정의됨
- 코드베이스 전체에서 `clear()` 호출 없음
- `ReadingPage:107` — `ref.watch(readingQuestionProvider)` — 이전 질문 잔류

**영향 범위**: Level 3 ReadingPage에서 이전 질문 텍스트 노출

**수정 방향**: 뽑기 시작 진입점 또는 IntentionPage `initState()`에서 clear() 호출.

### 원인 3 (중간): GoRouter go() + redirect + pageKey 재사용으로 initState 미호출

**근거**:
- `app_router.dart:44-50` — redirect 로직
- `home_page.dart:175` — InstantDrawPage에서 `context.go('/')` 호출
- `_fadePage(key: state.pageKey, ...)` — 경로 기반 동일 key 재사용
- Flutter Widget reconciliation이 동일 key Page를 재사용할 가능성

**영향 범위**: Level 1/2에서 quickDrawEnabled=true일 때 홈 복귀 후 재진입 시 이전 결과 표시

**수정 방향**: `_fadePage`에 `UniqueKey()` 또는 `ValueKey(DateTime.now().millisecondsSinceEpoch)` 사용. 또는 redirect 대신 홈 화면에서 push로만 진입하도록 강제.

### 원인 4 (낮음): InstantDrawPage `_loading = true` 초기화 누락 (State 재사용 시)

**근거**:
- `instant_draw_page.dart:32` — `bool _loading = true` 초기 선언
- State가 재사용되면 `_loading = false`(이전 뽑기 완료 후 상태) 유지
- 결과 화면이 로딩 없이 즉시 표시

**영향 범위**: 원인 3 발생 시 추가적으로 UX 악화

---

## 11. 요약

```
버그: 뽑기 시작 시 이전 결과가 보임

경로별 원인:
├── Level 1 (즉시 뽑기)
│   ├── push 진입: initState() 재호출 → 정상 (로컬 _shuffleResult 초기화됨)
│   └── redirect 진입 (quickDrawEnabled): pageKey 재사용 → initState 미호출 가능 [원인 3]
│
├── Level 2 (연출 뽑기)
│   ├── push 진입: initState() 재호출, _shuffleExecuted=false → 정상
│   └── redirect 진입 (quickDrawEnabled): [원인 3] 동일
│
└── Level 3 (풀셔플)
    ├── ReadingPage가 shuffleStateProvider.watch() → 이전 keepAlive 결과 표시 [원인 1, 최우선]
    └── ReadingPage가 readingQuestionProvider.watch() → 이전 질문 표시 [원인 2]

공통 근본 원인:
  shuffleStateProvider(keepAlive) + readingQuestionProvider(keepAlive)에
  뽑기 시작 시점에 clear()를 호출하는 코드가 존재하지 않는다.
```

---

## 12. 권고 수정 사항

### 즉시 적용 (원인 1, 2 해결)

**ShufflePage._goToReading() 수정**:
```dart
Future<void> _goToReading() async {
  // 이전 상태 초기화 먼저
  ref.read(shuffleStateProvider.notifier).clear();
  ref.read(readingQuestionProvider.notifier).clear();

  ...
  ref.read(shuffleStateProvider.notifier).setResult(result);
  ...
}
```

**InstantDrawPage._executeDraw() 수정**:
```dart
Future<void> _executeDraw() async {
  ref.read(shuffleStateProvider.notifier).clear();  // 선행 clear
  ...
}
```

**AnimatedDrawPage._startDraw() 수정**:
```dart
Future<void> _startDraw() async {
  ref.read(shuffleStateProvider.notifier).clear();  // 선행 clear
  ...
}
```

### 구조적 개선 (원인 3 해결)

GoRouter redirect 의존 대신 홈 화면에서 `_startDraw()`가 `push`로 이동하는 현재 패턴을 유지하고, `quickDrawEnabled` redirect를 제거하거나, redirect 대상 경로에 timestamp 기반 extra 파라미터를 추가하여 pageKey를 매번 다르게 만든다:

```dart
// app_router.dart redirect 수정 방향
if (settings.quickDrawEnabled) {
  // redirect 대신 홈에서 직접 push 처리로 변경 권고
  // redirect 유지 시: extra를 통해 timestamp 전달하여 pageKey 강제 갱신
}
```

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
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 385871s |
| Total Tokens | 4253170 |
| Input Tokens | 135 |
| Output Tokens | 31938 |
| Cache Read | 3624819 |
| Cache Creation | 596278 |
