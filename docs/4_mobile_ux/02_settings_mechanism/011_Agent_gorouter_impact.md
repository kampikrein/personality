---
title: "GoRouter redirect 제거 + settings watch 제거 영향 평가"
type: Agent
date: 2026-04-01
author: flutter-expert
summary: "redirect 블록(39-54행) + ref.watch(userSettingsProvider) 제거는 안전하다. quickDrawEnabled는 라우터에서만 소비되므로 설정 UI 토글 + 레포지토리 메서드도 함께 제거해야 일관성이 유지된다."
key_findings:
  - "appRouterProvider = AutoDisposeProvider → settings Stream 변경마다 재생성 → GoRouter 인스턴스 교체 → routerConfig 변경 → 네비게이션 스택 초기화 위험"
  - "redirect 제거 후 '/' 접근 시 항상 HomePage 표시 — _startDraw()와 완전히 동일한 경로를 재현하므로 UX 손실 없음"
  - "quickDrawEnabled는 app_router.dart에서만 소비됨 — redirect 제거 시 참조 0개, 필드 제거 권장"
  - "context.go('/') 호출(draw 페이지 2곳) + redirect 제거 → 홈으로 이동 후 redirect 재발동 없음 — 무한 루프 위험 해소"
  - "DevTunerOverlay: ref.read(appRouterProvider)로 GoRouter 참조를 1회 획득 → watch 제거 후에도 영향 없음"
confidence: high
---

# GoRouter redirect 제거 + settings watch 제거 영향 평가

## 조사 대상

- 파일: `mobile/lib/core/router/app_router.dart`
- 제거 대상 1: `app_router.dart:35` — `ref.watch(userSettingsProvider)`
- 제거 대상 2: `app_router.dart:39-54` — redirect 블록 전체

---

## L1 — 직접 영향

### 1-1. redirect 블록 삭제 시 `'/'` 접근 동작 변화

현재 redirect 로직 (`app_router.dart:39-54`):

```dart
redirect: (context, state) {
  if (settings == null) return null;          // 로딩 중 → null(홈 유지)
  if (state.matchedLocation != '/') return null; // '/'가 아니면 skip
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

redirect가 실제로 발동하는 조건:
- `quickDrawEnabled == true` AND `state.matchedLocation == '/'` 인 경우만

**제거 후 동작**: `context.go('/')` 또는 cold start 시 항상 `HomePage` 표시.
- `quickDrawEnabled == false`인 기본 사용자는 현재도 홈이 표시되므로 변화 없음.
- `quickDrawEnabled == true`였던 사용자는 앱 시작 시 홈 → 뽑기 자동 진입이 사라지고, 대신 홈에서 "뽑기 시작" 버튼을 눌러야 함. **이것이 유일한 동작 차이다.**

### 1-2. `ref.watch(userSettingsProvider)` 제거 시 appRouterProvider 리빌드 패턴

```
app_router.g.dart:13
final appRouterProvider = AutoDisposeProvider<GoRouter>.internal(...)
```

`@riverpod` 어노테이션 → `AutoDisposeProvider` 생성. `ref.watch(userSettingsProvider)` 가 있는 현재:
- `userSettingsProvider`(Stream)가 emit할 때마다 `appRouterProvider`가 invalidate됨
- `main.dart:89` `ref.watch(appRouterProvider)` → `PersonalityApp` 리빌드 → `routerConfig: router` 새 인스턴스 주입

**제거 후**: `appRouterProvider`는 외부 의존성이 없으므로 앱 생존 주기 동안 1회만 평가됨. AutoDispose이지만, `main.dart:89`에서 `ref.watch`로 참조되므로 GC되지 않고 앱 전체 수명 동안 살아있음.

### 1-3. GoRouter 생성자에서 불필요해지는 코드

`ref.watch(userSettingsProvider)` 제거 후 사용되지 않는 코드:
- `app_router.dart:1` import — `settings_providers.dart` import (`userSettingsProvider` 참조가 사라지면 dead import)
- `app_router.dart:35` — `final settings = ref.watch(userSettingsProvider).valueOrNull;` 변수 자체
- redirect 클로저 내 `settings` 참조 전체

단, `settings_providers.dart`의 `userSettingsProvider`는 `home_page.dart:49`, `settings_page.dart:13`에서 각각 `ref.watch`하므로 **provider 자체는 유지된다.**

---

## L2 — 연쇄 영향

### 2-1. `quickDrawEnabled` 참조 전수 조사

grep 결과 기준 실제 런타임 소비 위치:

| 파일 | 행 | 역할 |
|---|---|---|
| `app_router.dart:45` | redirect 블록 내 조건 | **제거 대상** |
| `settings_page.dart:93` | SwitchListTile value | 설정 UI 토글 표시 |
| `settings_page.dart:94-98` | onChanged → updateQuickDrawEnabled | 설정 UI 토글 변경 |
| `user_settings_repository_impl.dart:55` | updateQuickDrawEnabled 구현 | DB write |
| `user_settings_repository_impl.dart:72` | _toDomain 매핑 | DB row → domain |

생성 코드 (`app_database.g.dart`, `user_settings.freezed.dart`, `user_settings.g.dart`)는 자동 생성이므로 소스 파일 수정 후 재생성되면 함께 제거됨.

**결론**: redirect 제거 후 `quickDrawEnabled`는 `settings_page.dart`의 UI 토글에만 남는다. 이 토글은 이제 아무 효과도 없는 항목이 된다. **사용자에게 노출하는 기능이 실제로는 동작하지 않는 dead feature가 된다 — High 위험도.**

### 2-2. 설정 페이지 토글 UI (`settings_page.dart:90-98`)

```dart
// settings_page.dart:90-98
SwitchListTile(
  title: const Text('앱 시작 시 바로 뽑기'),
  subtitle: const Text('다음 실행부터 설정된 방식으로 자동 카드 뽑기'),
  value: settings.quickDrawEnabled,     // :93
  onChanged: (v) {
    ref.read(userSettingsRepositoryProvider)
        .updateQuickDrawEnabled(v);     // :95-96
  },
),
```

redirect 제거 후 이 토글의 상태는 DB에 저장되지만 **라우팅 동작에 어떤 영향도 주지 않는다.** 사용자 혼란 방지를 위해 **토글 UI 제거 필요**.

### 2-3. 설정 변경 후 GoRouter 미재생성 → 앱 동작

현재 문제: `settings_page.dart`의 Slider(`defaultCardCount`)에서 드래그 이벤트마다 `updateDefaultCardCount()` → DB write → `userSettingsProvider` Stream emit → `appRouterProvider` invalidate → GoRouter 재생성 → `routerConfig` 교체.

이는 Slider 드래그 중 GoRouter가 연속으로 재생성되는 상황이다. watch 제거 후 이 연쇄가 완전히 차단된다.

### 2-4. `quickDrawEnabled` 필드 제거 필요성 판단

**판단: 제거 권장 (Medium 우선순위)**

근거:
- redirect 제거 후 유일한 소비처가 settings_page.dart의 dead toggle이 됨
- `UserSettings` entity에서 필드 제거 → Drift 마이그레이션 필요 (스키마 변경)
- DB 마이그레이션은 기존 사용자 데이터에 영향을 주지 않음 (컬럼 DROP)
- 단, 마이그레이션 파일 작성 필요

**단계적 접근 권장**:
1. 즉시: redirect 제거 + settings watch 제거 + 설정 페이지 토글 제거 (이번 사이클)
2. 이후: `quickDrawEnabled` 필드 제거 + Drift 마이그레이션 (다음 사이클, 선택적)

---

## L3 — 네비게이션 안정성

### 3-1. `context.go()` vs `context.push()` 사용 패턴

grep 결과 전수:

| 파일 | 패턴 | 행 |
|---|---|---|
| `animated_draw_page.dart:225` | `context.go('/')` | 홈 아이콘 버튼 |
| `animated_draw_page.dart:307` | `context.go('/')` | 결과 화면 홈 버튼 |
| `instant_draw_page.dart:175` | `context.go('/')` | 홈 버튼 |
| `home_page.dart:36,38,40,42` | `context.push(...)` | _startDraw 분기 |
| `home_page.dart:126,134,142,178` | `context.pushNamed(...)` | 각 기능 카드 |
| `deck_selection_page.dart:42` | `context.pushNamed(...)` | 덱 선택 후 |
| `reading_list_page.dart:109` | `context.pushNamed(...)` | 리딩 상세 |
| `shuffle_page.dart:63` | `context.pushNamed(...)` | reading으로 |
| `intention_page.dart:107` | `context.pushNamed(...)` | shuffle로 |

`context.go('/')` 3곳이 redirect와 상호작용하는 핵심 지점이다.

**현재 동작**: `context.go('/')` → redirect 발동 → `quickDrawEnabled && experienceLevel==3`이면 `/shuffle/...`로 이동. **이 경우 홈 버튼을 눌렀는데 홈이 아닌 셔플 페이지로 이동하는 UX 버그가 현재 존재한다.**

**제거 후 동작**: `context.go('/')` → 항상 `HomePage` 표시. 이것이 의도한 동작이며 UX 버그가 해소된다.

### 3-2. GoRouter 미재생성 시 push/pop 동작 안정성

`main.dart:89`에서 `ref.watch(appRouterProvider)`가 GoRouter 인스턴스를 받아 `MaterialApp.router(routerConfig: router)`에 주입한다.

GoRouter 인스턴스가 바뀌면 `MaterialApp.router`가 리빌드되면서 **현재 네비게이션 스택이 초기화될 위험**이 있다. 구체적으로:
- 설정 페이지에서 Slider를 드래그하면 DB write → Stream emit → GoRouter 재생성 → routerConfig 교체
- 이 시점에 네비게이션 스택이 리셋될 수 있음 (실험적으로 재현 가능)

**제거 후**: GoRouter는 앱 시작 1회만 생성. push/pop 동작이 안정적으로 유지된다.

### 3-3. Cold start 시 `initialLocation: '/'` 동작

`app_router.dart:38` `initialLocation: '/'` — redirect 제거 후에도 이 설정은 그대로 유지된다. Cold start 시 항상 `HomePage`(`/`) 로 진입. 정상.

### 3-4. Android 뒤로가기 버튼

GoRouter는 자체 `Navigator`를 관리하므로 Android 뒤로가기는 GoRouter의 스택 pop 이벤트로 처리된다. redirect 제거는 라우팅 함수에서 URI 재작성 로직을 제거할 뿐이며, GoRouter의 Navigator 스택 관리 자체에는 영향이 없다. **영향 없음**.

### 3-5. 딥링크

grep 결과 딥링크 관련 코드 없음 (`firebase_dynamic_links`, `uni_links`, `app_links` 의존성 미사용). 해당 없음.

---

## L4 — 성능/안정성 비교

### 4-1. GoRouter 생성 빈도 비교

| 항목 | 변경 전 | 변경 후 |
|---|---|---|
| GoRouter 생성 시점 | settings Stream emit마다 (Slider 드래그 시 연속) | 앱 시작 1회 |
| MaterialApp.router 리빌드 | settings 변경마다 | 없음 |
| 네비게이션 스택 초기화 위험 | 있음 (설정 변경 중) | 없음 |
| GoRouter 인스턴스 수명 | 짧음 (AutoDispose, 빈번 교체) | 앱 전체 수명 |

settings_page.dart의 Slider `onChanged`는 드래그 중 매 프레임마다 호출될 수 있다. 현재는 이 이벤트마다 GoRouter 재생성이 발생할 수 있다. Slider의 경우 1초에 수십 회 emit이 가능하며, 이는 성능 관점에서 명확한 문제다.

### 4-2. Riverpod 의존성 그래프 변화

변경 전:
```
appDatabaseProvider
  └─ userSettingsRepositoryProvider (keepAlive)
       └─ userSettingsProvider (AutoDispose Stream)
            └─ appRouterProvider (AutoDispose) ← watch 연결
                 └─ PersonalityApp (ConsumerWidget) ← watch
```

변경 후:
```
appDatabaseProvider
  └─ userSettingsRepositoryProvider (keepAlive)
       └─ userSettingsProvider (AutoDispose Stream)
            ├─ HomePage (ref.watch)
            └─ SettingsPage (ref.watch)

appRouterProvider (AutoDispose) ← 독립, settings 의존 없음
  └─ PersonalityApp (ConsumerWidget) ← watch
```

`appRouterProvider`가 `userSettingsProvider`를 watch하지 않으므로, settings Stream이 빠르게 emit해도 router에 전파되지 않는다. Riverpod 의존성 그래프가 단순해진다.

### 4-3. appRouterProvider AutoDispose + keepAlive 문제

`app_router.g.dart:13`: `AutoDisposeProvider<GoRouter>` — keepAlive 없음.

`main.dart:89` `ref.watch(appRouterProvider)` — `PersonalityApp`이 살아있는 한 참조 유지 → AutoDispose라도 GC되지 않음. 실질적으로 앱 수명 동안 1개 인스턴스 유지.

`dev_tuner_overlay.dart:36` `ref.read(appRouterProvider)` — ref.read이므로 watch하지 않음. `PersonalityApp`이 router를 watch하고 있으므로 이 read 시점에 캐시된 인스턴스를 반환함. watch 제거 후에도 `ref.read`는 동일하게 동작. **영향 없음**.

### 4-4. 변경 후 불필요해지는 import

`app_router.dart`에서 `settings_providers.dart` import가 dead import가 된다. 제거 필요:

```dart
// 제거 대상
import '../../features/settings/presentation/providers/settings_providers.dart';
```

---

## 위험도 종합 판정

| 항목 | 위험도 | 비고 |
|---|---|---|
| redirect 제거 자체 | **Low** | _startDraw()와 동일 경로, cold start 동작 정상 |
| `ref.watch` 제거 자체 | **Low** | 앱 시작 1회 생성으로 안정성 향상 |
| `context.go('/')` + redirect 제거 교차 | **Low** (개선) | 현재 UX 버그(홈 버튼→셔플) 해소 |
| settings_page.dart quickDrawEnabled 토글 남겨두기 | **High** | 동작하지 않는 UI 노출 — 사용자 혼란 |
| GoRouter 연속 재생성 (현재 상태) | **Medium** | Slider 드래그 중 스택 초기화 위험 |
| quickDrawEnabled 필드 즉시 제거 | **Medium** | Drift 마이그레이션 필요, 다음 사이클 권장 |
| dead import 잔류 | **Low** | 컴파일 경고 수준 |

---

## 최종 판단: quickDrawEnabled 필드 제거 여부

**이번 사이클에서 제거할 항목 (필수)**:
1. `app_router.dart:35` `ref.watch(userSettingsProvider)` 변수 선언
2. `app_router.dart:39-54` redirect 블록
3. `app_router.dart` `settings_providers.dart` import
4. `settings_page.dart:90-98` quickDrawEnabled SwitchListTile 블록

**이번 사이클에서 제거하지 않아도 되는 항목 (다음 사이클)**:
- `user_settings.dart:15` `quickDrawEnabled` 필드
- `user_settings_repository.dart` `updateQuickDrawEnabled` 메서드
- `user_settings_repository_impl.dart:53-57`, `:72` 관련 코드
- `user_settings_table.dart` `quickDrawEnabled` 컬럼
- Drift 마이그레이션 파일

이유: DB 스키마 변경은 마이그레이션 버전 관리가 필요하며, 현재 사이클의 router 안정성 개선과 독립적이다. 필드가 entity에 남아있어도 기능상 문제가 없으며, 다음 설정 리팩터링 사이클에서 일괄 정리하는 것이 안전하다.

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
