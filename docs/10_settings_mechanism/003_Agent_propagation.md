---
title: "설정 변경 전파 메커니즘 조사"
type: Agent
date: 2026-04-01
author: flutter-expert
summary: "userSettingsProvider(AutoDisposeStreamProvider) 변경이 GoRouter 재생성을 유발하며, 이로 인해 의도치 않은 네비게이션 스택 리셋이 발생할 수 있음"
key_findings:
  - "userSettingsProvider는 AutoDispose + keepAlive 없음 — 위젯 트리에서 사라지면 즉시 폐기"
  - "appRouterProvider가 userSettingsProvider를 ref.watch → 설정 변경마다 GoRouter 인스턴스 재생성"
  - "GoRouter 재생성 시 MaterialApp.router가 routerConfig를 교체 → 현재 네비게이션 스택 초기화 위험"
  - "InstantDrawPage, AnimatedDrawPage는 initState에서 ref.read 1회 — 이후 설정 변경 반영 안됨"
  - "ReadingPage:109는 build()에서 ref.watch — showFaceUp 변경 시 즉시 반영됨"
confidence: high
---

# 설정 변경 전파 메커니즘 조사

## 1. userSettingsProvider 구조

### 소스 정의

**파일**: `mobile/lib/features/settings/presentation/providers/settings_providers.dart`

```dart
// L10-13: Repository 레이어 (keepAlive: true)
@Riverpod(keepAlive: true)
UserSettingsRepository userSettingsRepository(UserSettingsRepositoryRef ref) {
  final db = ref.watch(appDatabaseProvider);
  return UserSettingsRepositoryImpl(db: db);
}

// L16-20: Stream 구독 레이어 (keepAlive 없음 = AutoDispose)
@riverpod
Stream<UserSettings> userSettings(UserSettingsRef ref) {
  final repo = ref.watch(userSettingsRepositoryProvider);
  return repo.watchSettings();
}
```

**생성된 Provider 타입** (`settings_providers.g.dart:32`):

```dart
final userSettingsProvider = AutoDisposeStreamProvider<UserSettings>.internal(...)
```

### keepAlive 여부

| Provider | 타입 | keepAlive |
|---|---|---|
| `userSettingsRepositoryProvider` | `Provider<UserSettingsRepository>` | **true** (영구 유지) |
| `userSettingsProvider` | `AutoDisposeStreamProvider<UserSettings>` | **false** (자동 폐기) |

`userSettingsProvider`는 AutoDispose이므로, 이 provider를 watch하는 위젯이 모두 트리에서 제거되면 Stream 구독이 즉시 종료된다. 단, `appRouterProvider`가 `userSettingsProvider`를 watch하고 있고 `PersonalityApp`이 `appRouterProvider`를 watch하므로, 앱 생존 기간 동안은 `userSettingsProvider`가 실질적으로 계속 활성 상태를 유지한다.

### AsyncValue 타입

`AsyncValue<UserSettings>` (StreamProvider이므로). `valueOrNull`로 동기 접근 가능.

---

## 2. 설정 변경 시 전파 경로

### 변경 발생 경로 (SettingsPage → DB → Stream → UI)

```
사용자 UI 조작 (예: SwitchListTile onChanged)
    │
    ▼
ref.read(userSettingsRepositoryProvider).updateQuickDrawEnabled(v)
    │  [settings_page.dart:95]
    ▼
UserSettingsRepositoryImpl.updateQuickDrawEnabled()
    │  [user_settings_repository_impl.dart:53-55]
    ▼
db.userSettingsDao.updateSettings(UserSettingsTableCompanion(...))
    │  [user_settings_dao.dart:41-47]
    ▼  (Drift가 SQLite UPDATE 실행)
UserSettingsDao.watchSettings() Stream에 새 행 emit
    │  [user_settings_dao.dart:15-27]
    ▼
UserSettingsRepositoryImpl.watchSettings().map(_toDomain)
    │  [user_settings_repository_impl.dart:14-15]
    ▼
userSettingsProvider (AutoDisposeStreamProvider) 가 새 UserSettings 방출
    │  [settings_providers.dart:17-20]
    ▼
이 provider를 ref.watch하는 모든 위젯/provider 재빌드
```

### SettingsPage 자체의 변경 호출 패턴

`mobile/lib/features/settings/presentation/pages/settings_page.dart`에서 설정 변경은 모두 `ref.read(userSettingsRepositoryProvider).updateXxx()` 패턴을 사용하며, **repository를 직접 호출**한다. provider를 통한 상태 변경이 아니라 DB 직접 업데이트 → Drift Watch Stream → provider 방출 경로를 밟는다.

---

## 3. watch/read 사용처 전수 목록

| 파일 | 라인 | 사용 방식 | 컨텍스트 |
|---|---|---|---|
| `core/router/app_router.dart` | 35 | `ref.watch` | GoRouter 생성 시 설정 읽기 → **redirect 로직용** |
| `features/settings/presentation/pages/settings_page.dart` | 13 | `ref.watch` | SettingsPage build() — UI 반영용 |
| `features/home/presentation/pages/home_page.dart` | 48 | `ref.watch` | HomePage build() — 체험 레벨/덱 이름 표시 |
| `features/reading/presentation/pages/reading_page.dart` | 45 | `ref.read` | initState에서 1회 — defaultCardCount 캡처 |
| `features/reading/presentation/pages/reading_page.dart` | 84 | `ref.read` | `_addOneMore()` 호출 시 — showFaceUp 1회 읽기 |
| `features/reading/presentation/pages/reading_page.dart` | 109 | `ref.watch` | build()에서 — showFaceUp 리액티브 감시 |
| `features/draw/presentation/pages/animated_draw_page.dart` | 53 | `ref.read` | initState에서 1회 — 설정 캡처 후 인스턴스 변수에 저장 |
| `features/draw/presentation/pages/instant_draw_page.dart` | 46 | `ref.read` | initState에서 1회 — 설정 캡처 후 인스턴스 변수에 저장 |
| `features/draw/presentation/providers/draw_providers.dart` | 16 | `ref.read` | executeDraw provider 실행 시 1회 |

**ref.watch 사용처 요약** (설정 변경에 즉각 반응하는 곳):
- `app_router.dart:35` — GoRouter 재생성 트리거
- `settings_page.dart:13` — SettingsPage UI 갱신
- `home_page.dart:48` — HomePage UI 갱신
- `reading_page.dart:109` — showFaceUp만 리액티브

**ref.read 사용처 요약** (설정 변경에 반응하지 않는 곳):
- `animated_draw_page.dart:53` — initState 1회 캡처
- `instant_draw_page.dart:46` — initState 1회 캡처
- `reading_page.dart:45,84` — initState 및 메서드 내 1회 읽기
- `draw_providers.dart:16` — executeDraw 실행 시 1회 읽기

---

## 4. GoRouter와 settings의 관계

### appRouterProvider가 userSettingsProvider를 watch하는 구조

`mobile/lib/core/router/app_router.dart:34-35`:

```dart
@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final settings = ref.watch(userSettingsProvider).valueOrNull;
  // ...
```

`appRouterProvider` 자체는 `@riverpod` 어노테이션으로 **AutoDispose**이다. `PersonalityApp`이 `ref.watch(appRouterProvider)`를 호출하므로 앱 생존 기간 동안 살아 있다.

### 설정 변경 시 GoRouter 재생성 여부

**재생성된다.** `userSettingsProvider`가 새 값을 방출하면 `appRouterProvider`의 `ref.watch`가 트리거되어 provider 함수 전체가 재실행된다. 즉, `GoRouter(...)` 생성자가 다시 호출되어 **새 GoRouter 인스턴스**가 반환된다.

`PersonalityApp.build()`의 `main.dart:89`:

```dart
final router = ref.watch(appRouterProvider);
// ...
return MaterialApp.router(
  routerConfig: router,
```

`routerConfig`가 교체되면 `MaterialApp.router`는 새 Router를 사용하기 시작한다.

### 재생성 시 네비게이션 스택 처리

GoRouter는 `GoRouter` 인스턴스 자체를 교체할 때 현재 위치(`RouteInformationProvider`의 현재 경로)를 기반으로 **초기 경로(`initialLocation: '/'`)부터 다시 navigate**한다. 이때 redirect 로직이 실행된다.

실질적인 결과:
- Settings 페이지에서 `quickDrawEnabled`를 켜면 → `userSettingsProvider` 방출 → `appRouterProvider` 재실행 → 새 GoRouter 인스턴스 → `MaterialApp.router` 교체 → GoRouter가 현재 경로(`/settings`)를 유지하려 시도
- GoRouter는 `redirect`를 `state.matchedLocation != '/'`일 때 `null` 반환하므로(`app_router.dart:43`) `/settings`에 있을 때는 redirect 발동하지 않음
- 그러나 GoRouter 인스턴스 교체 자체가 스택을 초기화할 수 있는 위험이 있음

---

## 5. redirect 로직 분석

`mobile/lib/core/router/app_router.dart:39-54`:

```dart
redirect: (context, state) {
  if (settings == null) return null;             // 설정 로딩 전 pass-through
  if (state.matchedLocation != '/') return null; // '/' 이외 경로 pass-through

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

**redirect가 발생하는 조건**:
1. settings가 로딩 완료(`valueOrNull != null`)
2. 현재 경로가 정확히 `'/'`
3. `quickDrawEnabled == true`

**redirect 발생 시 페이지 State 처리**:
- GoRouter가 `'/'`에서 `/draw/instant` 등으로 redirect하면, `'/'`에 해당하는 `HomePage`는 스택에 존재하지 않게 된다
- 새 경로의 페이지(`InstantDrawPage`, `AnimatedDrawPage`, `ShufflePage`)가 새로 생성됨 → State는 새로 생성 (재사용 없음)
- 기존에 다른 경로(`/settings`, `/readings` 등)를 방문한 히스토리가 있더라도, GoRouter 인스턴스 교체 시 스택이 새로 빌드된다

---

## 6. GoRouter pageKey와 State 재사용 여부

`mobile/lib/core/router/app_router.dart:20-31`의 `_fadePage` 헬퍼:

```dart
CustomTransitionPage<void> _fadePage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: key,
    child: child,
    transitionsBuilder: ...,
  );
}
```

각 route의 `pageBuilder`에서 `key: state.pageKey`를 사용한다. 예:

```dart
// app_router.dart:59-62
pageBuilder: (context, state) =>
    _fadePage(key: state.pageKey, child: const HomePage()),
```

`state.pageKey`는 GoRouter가 경로 경로(path)를 기반으로 생성하는 `ValueKey<String>`이다. 같은 경로를 재방문하면 동일한 key가 반환된다.

**State 재사용 여부**:
- 동일 GoRouter 인스턴스 내에서: 같은 key를 가진 Page가 스택에 남아있으면 Flutter의 Element 재사용 메커니즘에 의해 State가 유지됨
- **GoRouter 인스턴스가 교체되면**: 이전 Router 인스턴스의 Navigator가 전체 unmount → 모든 페이지 State 소멸 → 새 Router의 Navigator로 교체 → State 새로 생성

즉, 설정 변경(특히 `quickDrawEnabled`, `experienceLevel`, `selectedDeckId`) 시 GoRouter가 재생성되면 현재 쌓여있던 페이지 스택의 모든 State가 소멸된다.

---

## 7. 부작용 식별

### 부작용 1: 설정 변경마다 GoRouter 재생성 (심각도: 높음)

**발생 조건**: `userSettingsProvider`가 새 값을 방출하는 모든 시점.
- SettingsPage에서 슬라이더 드래그 시 `updateDefaultCardCount`가 연속 호출됨
- 각 호출마다 DB UPDATE → Drift Stream emit → `userSettingsProvider` 방출 → `appRouterProvider` 재실행 → GoRouter 재생성

`mobile/lib/features/settings/presentation/pages/settings_page.dart:65-75`:
```dart
Slider(
  value: settings.defaultCardCount.toDouble(),
  onChanged: (v) {
    ref.read(userSettingsRepositoryProvider)
        .updateDefaultCardCount(v.round());  // 드래그 중 연속 호출
  },
),
```

**결과**: 슬라이더 드래그 1회에 수십 번의 GoRouter 재생성이 발생할 수 있다.

### 부작용 2: 네비게이션 스택 리셋 위험 (심각도: 높음)

SettingsPage는 `/settings` 경로에서 동작하고, redirect 로직은 `matchedLocation != '/'`이면 pass-through이므로 SettingsPage 자체는 유지된다. 그러나 GoRouter 인스턴스 교체 자체가 네비게이션 히스토리를 초기화할 가능성이 있다. 특히 `quickDrawEnabled`를 켜면 다음 `'/'` 접근 시 redirect가 발동되도록 설계되어 있으나, GoRouter 인스턴스 교체로 인해 예상치 못한 시점에 redirect가 실행될 수 있다.

### 부작용 3: InstantDrawPage/AnimatedDrawPage의 설정 스냅샷 문제 (심각도: 낮음)

`AnimatedDrawPage._initSettings()` (`animated_draw_page.dart:52-59`)와 `InstantDrawPage._initSettings()` (`instant_draw_page.dart:45-52`)는 `initState`에서 `ref.read`로 설정을 1회 캡처하여 인스턴스 변수에 저장한다:

```dart
void _initSettings() {
  final settings = ref.read(userSettingsProvider).valueOrNull;
  _spreadType = settings?.defaultSpreadType ?? SpreadType.threeCard;
  _currentCardCount = ...;
  _deckId = settings?.selectedDeckId ?? 'rws-standard';
  _showFaceUp = settings?.showFaceUp ?? false;  // animated_draw_page.dart:59
}
```

페이지가 열린 이후 설정이 변경되어도 이 페이지들의 동작에는 반영되지 않는다. 이는 의도된 동작으로 볼 수 있으나, GoRouter 재생성으로 인해 페이지가 재생성되면 새 설정이 반영된 상태로 초기화된다.

### 부작용 4: ReadingPage의 showFaceUp watch/read 혼용 (심각도: 낮음)

`reading_page.dart`:
- L45: `ref.read(userSettingsProvider)` — `initState`에서 `defaultCardCount` 캡처
- L84: `ref.read(userSettingsProvider)` — `_addOneMore()` 내에서 `showFaceUp` 읽기
- L109: `ref.watch(userSettingsProvider)` — `build()`에서 `showFaceUp` 리액티브 감시

`build()`에서 `showFaceUp`은 리액티브하게 반영되지만, `_addOneMore()` 메서드(L84)는 `ref.read`를 사용하므로 호출 시점의 최신 값을 읽는다. 이 자체는 문제가 없으나, 두 경로가 혼재한다는 점에서 일관성이 부족하다.

---

## 8. 전파 경로 다이어그램

```
[SettingsPage]
    │ ref.read(userSettingsRepositoryProvider).updateXxx()
    ▼
[UserSettingsDao.updateSettings()]  ← Drift SQLite UPDATE
    │
    ▼ Drift watchSingleOrNull() emit
[UserSettingsDao.watchSettings()]
    │
    ▼ map(_toDomain)
[UserSettingsRepositoryImpl.watchSettings()]
    │
    ▼ Stream<UserSettings>
[userSettingsProvider (AutoDisposeStreamProvider)]
    │
    ├─── ref.watch ──→ [appRouterProvider] ──→ GoRouter 재생성
    │                        │
    │                        ▼
    │                  [PersonalityApp] (main.dart:89)
    │                  MaterialApp.router(routerConfig: router)
    │
    ├─── ref.watch ──→ [SettingsPage.build()] — UI 갱신
    │
    ├─── ref.watch ──→ [HomePage.build()] — 레벨/덱 이름 갱신
    │
    └─── ref.watch ──→ [ReadingPage.build()] — showFaceUp만 갱신
```

---

## 9. 핵심 식별 사항 요약

1. `userSettingsProvider`는 **AutoDisposeStreamProvider** — keepAlive 없음, 소비자가 없으면 폐기됨 (`settings_providers.g.dart:32`)

2. `appRouterProvider`가 `userSettingsProvider`를 `ref.watch`하므로 **설정 변경마다 GoRouter 인스턴스가 재생성**된다 (`app_router.dart:35`)

3. GoRouter 재생성 시 `MaterialApp.router`의 `routerConfig`가 교체되어 **네비게이션 스택 초기화 위험**이 있다

4. redirect 로직은 `matchedLocation == '/'`일 때만 실행되어 과도한 리다이렉트를 방지하나, GoRouter 인스턴스 재생성 자체의 부작용은 막지 못한다 (`app_router.dart:43`)

5. `quickDrawEnabled` 변경은 다음 `'/'` 접근 시 redirect를 유발하며, 해당 페이지의 State는 **새로 생성**된다

6. `state.pageKey` 기반 key는 동일 GoRouter 인스턴스 내에서만 State 재사용을 보장하며, GoRouter 재생성 시에는 **모든 State가 소멸**된다

7. 슬라이더(`defaultCardCount`) 드래그 시 **연속 DB 업데이트 → 연속 GoRouter 재생성** 이슈가 존재한다 — debounce가 없음

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
