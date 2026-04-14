---
id: "068"
type: plan
title: "Cycle 1 Plan — 리네임 & 라우트 원자 교체"
created: 2026-04-14
cycle: 1
traces_scope: "066"
traces_brief: "065"
depends_on: []
parallel_with: []
summary: >
  Brief 065 Cycle 1의 리네임·라우트 원자 교체를 3-커밋 체인으로 실행한다.
  각 커밋 이후 flutter build가 성공하는 빌드 원자성을 유지하면서, TDD Red 067의
  3개 실패 테스트(T1 DrawResultPage smoke / T2 /draw/result 존재 / T3 /draw/instant 제거)를
  모두 Green으로 전환한다.
keywords: [cycle1, rename, draw-result-page, go-router, atomic-commit, tdd-green]
---

# 068 — Cycle 1 Plan: 리네임 & 라우트 원자 교체

## Goal

Brief 065 Cycle 1을 구현한다. 목적은 **두 가지**:

1. **이름 통일**: `InstantDrawPage`(Lv1 뉘앙스) → `DrawResultPage`(포괄 결과 페이지) 리네임. 파일·클래스·상태 클래스·import 경로·라우트 path·라우트 name·호출부까지 전역 일관.
2. **TDD Red → Green 전환**: 067이 정의한 3개 Red 테스트(T1 smoke, T2 path 존재, T3 legacy 제거)를 구현 완료 시 모두 Green으로 만든다.

**Cycle 1의 의도적 비범위**: 내부 로직 변경·initState 분기·AnimatedDrawPage / ShufflePage / ReadingPage 후단은 Cycle 2가 처리. Cycle 1은 **순수 기계적 리네임**만 수행하여 `DrawResultPage`의 동작이 리네임 이전 `InstantDrawPage`와 동일하게 유지되어야 한다(회귀 0).

## Scope

### Included
| # | Item | Description |
|---|------|-------------|
| 1 | Git rename | `instant_draw_page.dart` → `draw_result_page.dart` (git mv, 리네임 이력 보존) |
| 2 | 클래스 리네임 | `InstantDrawPage` → `DrawResultPage`, `_InstantDrawPageState` → `_DrawResultPageState` |
| 3 | docstring 부여 | `DrawResultPage` 클래스 위 "Lv1~Lv4 공용 결과 페이지" 의도 주석 (Brief IC #3) |
| 4 | Router import | `app_router.dart` import 경로 교체 |
| 5 | Router 경로·name | path `/draw/instant` → `/draw/result`, name `draw-instant` → `draw-result` |
| 6 | Home 호출부 | `home_page.dart:36, :44`의 `context.push('/draw/instant')` → `context.push('/draw/result')` |
| 7 | 테스트 통과 확인 | `flutter test` + `flutter build apk --debug` 전체 Green |

### Excluded
| Item | Reason/Timeline |
|------|-----------------|
| `DrawResultPage.initState` 분기(null→자체 셔플, 값있음→재사용) | Cycle 2 (Scope 066 Cycle 2 섹션 + Brief MA-3) |
| `AnimatedDrawPage` 결과 블록 제거 | Cycle 2 (Brief MA-4) |
| `ShufflePage` 후단 navigation 교체 | Cycle 2 (Brief MA-5) |
| `ReadingPage`(draw-time) 파일/라우트 삭제 | Cycle 2 (Brief MA-6) |
| 내부 UI/UX 변경 | Brief MA-8 (Scope 확장 금지) |
| reading_list / reading_detail 수정 | 유지 (기록 조회 도메인) |

## Structural Decisions

| # | Decision | Chosen Option | Rationale |
|---|----------|---------------|-----------|
| 1 | **커밋 분할 전략** | 3-커밋 체인 (C1: git mv only, C2: 클래스·import·docstring 리네임, C3: 라우트 path/name + home 호출부) | Scope 066 R4(rename tracking 손실) 회피 + 각 커밋 경계에서 빌드 성공을 유지. C1만으로는 빌드 성공(파일 내용 변경 無 + import 경로만 교체하면 되지만, 안전을 위해 C1+C2를 원자 쌍으로 취급 — 아래 "원자성 보강" 참조) |
| 2 | **C1+C2 원자 쌍** | C1(git mv)과 C2(내용 리네임·import 갱신)를 **연속된 두 커밋**으로 수행하되, C1 직후에는 `git mv`만 들어간 상태 — 이 상태에서는 `app_router.dart`의 `import '...instant_draw_page.dart'`가 깨진다. 따라서 **C1+C2를 한 PR/세션 단위로 묶어** main에 C1만 단독으로 존재하지 않도록 한다 | Git이 rename을 인식하려면 "이동만" 커밋과 "내용 변경" 커밋을 분리하는 것이 가장 확실(변경량 임계값 회피). 단 중간 상태에서 빌드가 깨지므로 main에는 둘을 함께 푸시 |
| 3 | **리네임 도구** | 수동 Edit (클래스명 4회·파일 헤더 경로 코멘트 0회) + `git mv` 1회 + `context.push` 2곳 | 파일 내 `InstantDrawPage` / `_InstantDrawPageState` 출현 지점은 3군데(선언·생성자·state 선언)로 IDE 자동 리팩터링 없이 수작업 Edit가 더 간결 |
| 4 | **라우트 name 교체** | `draw-instant` → `draw-result` (명시적 리네임, 하위 호환 alias 없음) | Brief MA-0 "리네임 일괄". 내부 호출부는 `context.push('/draw/instant')`(path 기반)만 있고 `context.pushNamed('draw-instant')` 사용처는 0건(grep 확인) → alias 불필요 |
| 5 | **docstring 위치** | `DrawResultPage` 클래스 선언 직전에 `///` dartdoc 블록 3줄 | Brief IC #3 "Lv1~Lv4 공용 결과 페이지 역할 명시". 클래스 선언부가 파일 최상단 근처라 발견성 우수 |

---

## File Change Summary

### Modified Files
| # | File Path | Change Description |
|---|-----------|-------------------|
| 1 | `mobile/lib/features/draw/presentation/pages/instant_draw_page.dart` | **git mv** → `draw_result_page.dart`. 내부 `InstantDrawPage`/`_InstantDrawPageState` → `DrawResultPage`/`_DrawResultPageState`, dartdoc 추가 |
| 2 | `mobile/lib/core/router/app_router.dart` | import 경로(line 8), path(line 153), name(line 154), 위젯 생성자(line 156) 교체 |
| 3 | `mobile/lib/features/home/presentation/pages/home_page.dart` | `context.push('/draw/instant')` (line 36, 44) → `context.push('/draw/result')` |

### New Files
(없음 — 기존 파일 rename + edit)

### Deleted Files
(없음 — Cycle 1 범위에서 ReadingPage 삭제는 Cycle 2로 이관)

---

## Step-by-step Plan

### Step 1 — Pre-flight (sanity grep)

**Purpose**: 리네임 시작 전 현 상태의 참조 지점이 Scope 066과 일치하는지 확인.

```bash
cd /Users/kampikrein/A/personality
grep -rn "InstantDrawPage\|draw/instant\|draw-instant\|instant_draw_page" mobile/lib mobile/test
```

**Expected (Scope 066 기준)**:
- `mobile/lib/features/draw/presentation/pages/instant_draw_page.dart` (파일 자체)
- `mobile/lib/core/router/app_router.dart:8, :153, :154, :156`
- `mobile/lib/features/home/presentation/pages/home_page.dart:36, :44`
- `mobile/test/core/router/draw_result_route_test.dart` — 주석 및 문자열 리터럴 (테스트가 legacy의 **부재**를 확인하는 용도이므로 수정하지 않음)

**Stop 조건**: 예상 목록 외 파일에서 참조가 발견되면 중단하고 Scope에 missing 항목 추가 요청.

### Step 2 — Commit C1: `git mv` only

**Purpose**: Git이 rename을 추적 가능한 형태(순수 이동, 내용 변경 0%)로 첫 커밋 확보.

```bash
cd /Users/kampikrein/A/personality
git mv mobile/lib/features/draw/presentation/pages/instant_draw_page.dart \
       mobile/lib/features/draw/presentation/pages/draw_result_page.dart
```

**이 시점의 빌드 상태**: **깨짐**. `app_router.dart:8`이 `instant_draw_page.dart`를 import 중. 따라서 이 커밋을 단독으로 main에 남기지 않는다(Decision 2).

**커밋 메시지** (예시):
```
refactor(draw): git mv instant_draw_page.dart → draw_result_page.dart

Pure file move to preserve git rename history.
Build intentionally broken at this point; Step 3 restores build.
Part of Cycle 1 (Brief 065).
```

### Step 3 — Commit C2: 클래스·import·docstring 리네임 (빌드 복원)

**Purpose**: C1으로 깨진 빌드를 이 커밋 하나로 복원. 클래스명·참조·import를 일괄 교체.

#### 3a. `draw_result_page.dart` 클래스 리네임 + docstring

**Current Code** (`mobile/lib/features/draw/presentation/pages/draw_result_page.dart:17-24` — rename 직후 내용은 구 `instant_draw_page.dart`와 동일):
```dart
class InstantDrawPage extends ConsumerStatefulWidget {
  const InstantDrawPage({super.key});

  @override
  ConsumerState<InstantDrawPage> createState() => _InstantDrawPageState();
}

class _InstantDrawPageState extends ConsumerState<InstantDrawPage> {
```

**After Code**:
```dart
/// Lv1~Lv4 공용 뽑기 결과 페이지.
///
/// Cycle 1에서는 기존 `InstantDrawPage`의 행동을 그대로 유지한다.
/// 업스트림(AnimatedDrawPage, ShufflePage)과의 상태 인계 및
/// `shuffleStateProvider` 초기값 분기는 Cycle 2에서 도입된다.
/// 참조: docs/03_tarot_shuffle/065_Brief_unified_result_page.md
class DrawResultPage extends ConsumerStatefulWidget {
  const DrawResultPage({super.key});

  @override
  ConsumerState<DrawResultPage> createState() => _DrawResultPageState();
}

class _DrawResultPageState extends ConsumerState<DrawResultPage> {
```

**Impact**: 파일 내부에서 `InstantDrawPage` 출현 라인(17, 18, 21) + `_InstantDrawPageState` 출현 라인(21, 24)을 모두 교체. `ConsumerState<InstantDrawPage>` 제네릭 인자도 함께 교체됨.

#### 3b. `app_router.dart` import 경로 교체

**Current Code** (`mobile/lib/core/router/app_router.dart:8`):
```dart
import '../../features/draw/presentation/pages/instant_draw_page.dart';
```

**After Code**:
```dart
import '../../features/draw/presentation/pages/draw_result_page.dart';
```

#### 3c. `app_router.dart` 위젯 생성자 교체

**Current Code** (`mobile/lib/core/router/app_router.dart:155-157`):
```dart
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const InstantDrawPage()),
      ),
```

**After Code** (동일 위치, path/name은 아직 legacy 유지 — Step 4에서 교체):
```dart
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const DrawResultPage()),
      ),
```

#### 3d. 검증 (커밋 전)

```bash
cd /Users/kampikrein/A/personality/mobile
flutter analyze lib/
flutter build apk --debug
```

**Expected**: 0 errors, build success. 이 시점에서 라우트 path는 아직 `/draw/instant`이지만 위젯 클래스·import는 모두 `DrawResultPage`로 통일됨. 앱 실행 시 홈→바로 뽑기(`/draw/instant`)는 `DrawResultPage`를 렌더하여 기존 동작 유지.

**커밋 메시지** (예시):
```
refactor(draw): rename InstantDrawPage → DrawResultPage class/imports

- Rename class & state in draw_result_page.dart
- Update app_router.dart import and widget constructor
- Add dartdoc describing Lv1~Lv4 unified result page role (Brief 065 IC #3)
- Path/name '/draw/instant' still intact; replaced in next commit
Part of Cycle 1 (Brief 065).
```

### Step 4 — Commit C3: 라우트 path/name + home 호출부 교체 (TDD Green)

**Purpose**: 라우트 path·name을 `/draw/result` / `draw-result`로 교체하고, 호출부 2곳을 동시에 교체. **이 커밋이 T2·T3를 Green으로 전환**.

#### 4a. `app_router.dart` 라우트 path & name 교체

**Current Code** (`mobile/lib/core/router/app_router.dart:152-157` — C2 적용 후):
```dart
      GoRoute(
        path: '/draw/instant',
        name: 'draw-instant',
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const DrawResultPage()),
      ),
```

**After Code**:
```dart
      GoRoute(
        path: '/draw/result',
        name: 'draw-result',
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const DrawResultPage()),
      ),
```

#### 4b. `home_page.dart` 호출부 교체 (2곳)

**Current Code** (`mobile/lib/features/home/presentation/pages/home_page.dart:32-46`):
```dart
  /// 설정된 체험 레벨에 따라 뽑기 경로로 이동
  void _startDraw(BuildContext context, int experienceLevel, String deckId) {
    switch (experienceLevel) {
      case 1:
        context.push('/draw/instant');
      case 2:
        context.push('/draw/animated');
      case 3: // 2D 셔플 (TODO: 전용 페이지 구현 후 분기)
        context.pushNamed('intention', pathParameters: {'deckId': deckId});
      case 4: // 2.5D 물리 셔플
        context.pushNamed('intention', pathParameters: {'deckId': deckId});
      default:
        context.push('/draw/instant');
    }
  }
```

**After Code**:
```dart
  /// 설정된 체험 레벨에 따라 뽑기 경로로 이동
  void _startDraw(BuildContext context, int experienceLevel, String deckId) {
    switch (experienceLevel) {
      case 1:
        context.push('/draw/result');
      case 2:
        context.push('/draw/animated');
      case 3: // 2D 셔플 (TODO: 전용 페이지 구현 후 분기)
        context.pushNamed('intention', pathParameters: {'deckId': deckId});
      case 4: // 2.5D 물리 셔플
        context.pushNamed('intention', pathParameters: {'deckId': deckId});
      default:
        context.push('/draw/result');
    }
  }
```

**주의 (MA-7)**: Lv2/3/4 분기는 건드리지 않는다. Lv1 + default만 교체.

#### 4c. 최종 검증

```bash
cd /Users/kampikrein/A/personality/mobile
# (1) 잔존 참조 0건 확인 (IC #1)
grep -rn "InstantDrawPage\|draw/instant\|draw-instant\|instant_draw_page" lib/
# (2) 빌드 (IC #2)
flutter build apk --debug
# (3) TDD Red → Green 확인
flutter test test/features/draw/draw_result_page_test.dart \
             test/core/router/draw_result_route_test.dart
# (4) 전체 테스트 회귀 확인 (IC #4)
flutter test
# (5) 정적 분석
flutter analyze
```

**Expected**:
- (1): 0건 (단 `test/core/router/draw_result_route_test.dart`의 문자열 리터럴은 legacy 부재를 assert하는 용도이므로 `grep`에 걸릴 수 있음 — `lib/` 범위만 0건이면 통과)
- (2): `Built build/app/outputs/flutter-apk/app-debug.apk`.
- (3): `+3 -0` (T1·T2·T3 모두 Green)
- (4): pre-cycle1 baseline 대비 pass/fail 동일 (IC #4 회귀 없음)
- (5): 0 errors

**커밋 메시지** (예시):
```
refactor(router): replace /draw/instant with /draw/result

- app_router.dart: path '/draw/instant'→'/draw/result', name 'draw-instant'→'draw-result'
- home_page.dart: context.push('/draw/instant') → '/draw/result' (lines 36, 44)
- Satisfies Brief 065 MA-0 (rename atomicity) and MA-7 (home branch preserved)
- Turns TDD Red T2/T3 → Green (docs/03_tarot_shuffle/067)
Closes Cycle 1 of Brief 065.
```

### Step 5 — 수동 회귀 (Lv1 smoke)

1. 에뮬레이터에 APK 설치: `adb install -r build/app/outputs/flutter-apk/app-debug.apk`
2. 홈 → 설정에서 체험 레벨 1 선택 → 바로 뽑기 탭
3. 결과 카드 정상 렌더 + 저장 + "한 장 더" 정상 (IC #24, 기존 InstantDrawPage 기능 동치)
4. 뒤로가기로 홈 복귀

기록: `mobile/tmp/screenshots/`에 타임스탬프 스크린샷 1장 저장.

---

## Test Strategy — Red → Green Mapping

067이 정의한 3개의 Red 테스트가 본 Plan의 어느 단계에서 Green이 되는지:

| Test | 파일 | Red 상태 | Green 전환 단계 | 이유 |
|------|------|---------|----------------|------|
| **T1** DrawResultPage smoke | `mobile/test/features/draw/draw_result_page_test.dart` | 컴파일 실패 (`draw_result_page.dart` 파일 미존재 + `DrawResultPage` 심볼 미존재) | **Step 3 커밋 C2 직후** | C1(`git mv`)로 파일 경로가 존재 + C2로 `DrawResultPage` 클래스명이 존재. 이 두 조건이 모두 충족되면 import 해석 성공 → `pumpWidget` 성공 → `find.byType(DrawResultPage)` 1건. |
| **T2** `/draw/result` path 라우트 존재 | `mobile/test/core/router/draw_result_route_test.dart` | assertion fail (경로 매칭 0건) | **Step 4 커밋 C3 직후** | C3에서 `app_router.dart`의 GoRoute path를 `/draw/result`, name을 `draw-result`로 교체하면 `_collectGoRoutes(...)`가 해당 GoRoute를 반환 → `isNotEmpty` 통과. |
| **T3** legacy `/draw/instant` 제거 | `mobile/test/core/router/draw_result_route_test.dart` | assertion fail (legacy 1건 발견) | **Step 4 커밋 C3 직후** | T2와 동일 커밋에서 legacy path/name이 replace되므로 `stale`이 `isEmpty`가 됨. |

**중간 상태의 테스트 동작**:
- **C1만 적용** (Step 2 직후, main에는 존재하지 않는 transient state): 빌드 깨짐. 모든 테스트가 컴파일 단계에서 실패.
- **C1+C2 적용** (Step 3 직후): 빌드 OK. T1 Green, T2·T3 Red 유지.
- **C1+C2+C3 적용** (Step 4 직후): 빌드 OK. T1·T2·T3 모두 Green.

**회귀 테스트 (IC #4)**: Cycle 1 시작 전 baseline `flutter test` 결과를 메모하고, Step 4 완료 후 동일 명령의 pass/fail 카운트가 일치해야 한다. 불일치 시 Cycle 1 impl이 의도하지 않은 변경을 유발했다는 신호 → 중단하고 diff 재검토.

---

## Verification Assertions

| Level | Assertion | Verification Method | Expected Result |
|-------|-----------|-------------------|-----------------|
| L1-Build | Flutter 정적 분석 통과 | `cd mobile && flutter analyze lib/` | 0 errors |
| L1-Build | 디버그 APK 빌드 성공 (IC #2) | `cd mobile && flutter build apk --debug` | `Built build/app/outputs/flutter-apk/app-debug.apk` |
| L1-Build | 잔존 심볼 0건 (IC #1) | `grep -rn "InstantDrawPage\|draw/instant\|draw-instant\|instant_draw_page" mobile/lib` | 0 lines |
| L1-Build | 테스트 회귀 없음 (IC #4) | `cd mobile && flutter test` — pre/post 카운트 비교 | pass/fail counts identical |
| L2-CLI | TDD Red T1 Green 전환 | `cd mobile && flutter test test/features/draw/draw_result_page_test.dart` | `+1 -0: All tests passed.` |
| L2-CLI | TDD Red T2·T3 Green 전환 | `cd mobile && flutter test test/core/router/draw_result_route_test.dart` | `+2 -0: All tests passed.` |
| L2-CLI | Git rename 추적 보존 (R4 대응) | `git log --follow --oneline -- mobile/lib/features/draw/presentation/pages/draw_result_page.dart` | C1의 `git mv` 커밋 + C2의 내용 리네임 커밋이 히스토리에 연결됨 |
| L3-Browser | Lv1 "바로 뽑기" end-to-end (IC #24, #26 일부) | 에뮬레이터 수동: 홈 → 체험 레벨 1 → 바로 뽑기 버튼 | DrawResultPage 렌더, 카드 3장 뒤집기, 저장 후 `/readings`에서 조회 가능 |
| L4-Trace | IC #3 docstring 명시 | `grep -A 3 "class DrawResultPage" mobile/lib/features/draw/presentation/pages/draw_result_page.dart` | dartdoc에 "Lv1~Lv4 공용" 문구 포함 |
| L4-Trace | Brief MA-0 원자성 (Scope R4) | 각 커밋 체크아웃 후 빌드 시도 — C2·C3 경계만 (C1 단독은 의도적 미검증) | C2 이후 빌드 성공, C3 이후 빌드 성공 |

---

## Risk & Rollback

### Potential Risks

| # | Risk | Severity | Mitigation |
|---|------|----------|------------|
| R1 | C1 단독 커밋이 main에 푸시되면 빌드 깨짐 | High | C1+C2를 동일 push 단위로 묶음(Decision 2). CI가 C1 단독 브랜치 상태에서 빌드 실행 시 빨간 신호가 뜨는 것은 예상 동작 — merge 전 C2까지 포함된 상태에서만 CI 통과 |
| R2 | Git이 rename을 인식하지 못하고 "delete + add"로 처리 | Medium | C1을 **순수 이동**으로 수행 → Git의 rename threshold(50% 유사도) 이하 변경으로 rename 인식. `git log --follow` 후속 검증 (L4 assertion) |
| R3 | `test/core/router/draw_result_route_test.dart` 내 문자열 `'/draw/instant'`가 grep IC #1에 걸림 | Low | Verification grep 범위를 `mobile/lib`으로 제한 (테스트는 legacy 부재를 assert하는 용도) |
| R4 | 내가 놓친 참조가 있어 빌드 깨짐 | Low | Step 1의 pre-flight grep이 Scope 066 예상 목록과 일치함을 사전 확인. 불일치 시 Step 2 진입 전 중단 |
| R5 | `ConsumerState<InstantDrawPage>` 제네릭 제약으로 일부 인스턴스 교체 누락 | Low | Step 3a에서 파일 전체를 `InstantDrawPage` / `_InstantDrawPageState` 완전 grep 후 교체 (`replace_all` Edit 권장) |
| R6 | home_page.dart의 `context.pushNamed('draw-instant')` 호출 누락 | Very Low | grep 확인 결과 0건 — 호출부는 path 기반 `context.push('/draw/instant')`만 존재 |

### Rollback Strategy

- **C3 실패**: `git reset --hard HEAD~1` — C2까지의 상태로 복귀 (빌드 OK, 라우트는 legacy). TDD Red는 T2·T3만 유지.
- **C2 실패**: `git reset --hard HEAD~2` — 구 `instant_draw_page.dart` 복원. Cycle 1 전체 되돌림.
- **C1+C2 push 이후 문제 발견**: `git revert` 2회(C2→C1 역순). `git mv` revert는 파일을 원래 이름으로 복구.

### Backward Compatibility

- **딥링크**: 앱 외부에서 `/draw/instant`로 진입하는 경로 없음 (Brief 065 IC #25에서 "미사용" 명시 가능). 하위 호환 alias 라우트 불필요.
- **저장된 Reading**: 결과 페이지 교체와 무관 (DB 스키마·Reading 엔티티 불변).
- **테스트 파일**: `draw_result_page_test.dart`, `draw_result_route_test.dart`는 Cycle 1 구현 완료 후 Green이 되므로 변경 불필요.

---

## Implementation Checklist

- [ ] Step 1: pre-flight grep으로 참조 지점이 Scope 066과 일치함을 확인
- [ ] Step 2 (C1): `git mv instant_draw_page.dart draw_result_page.dart` 커밋
- [ ] Step 3a (C2): `draw_result_page.dart` 내 `InstantDrawPage`/`_InstantDrawPageState` → `DrawResultPage`/`_DrawResultPageState` 리네임 + dartdoc 추가
- [ ] Step 3b (C2): `app_router.dart:8` import 경로 교체
- [ ] Step 3c (C2): `app_router.dart:156` 위젯 생성자 `InstantDrawPage` → `DrawResultPage`
- [ ] Step 3d (C2): `flutter analyze` + `flutter build apk --debug` 성공 확인 → 커밋
- [ ] Step 4a (C3): `app_router.dart:153-154` path `/draw/instant` → `/draw/result`, name `draw-instant` → `draw-result`
- [ ] Step 4b (C3): `home_page.dart:36, :44`의 `context.push('/draw/instant')` → `context.push('/draw/result')`
- [ ] Step 4c (C3): grep 0건 / build 성공 / TDD 3개 Green / flutter test 전체 회귀 없음 / analyze 0 errors 확인
- [ ] Step 5: 에뮬레이터 Lv1 수동 회귀 + 스크린샷 저장
- [ ] 최종 커밋 후 pipeline.sh로 다음 cycle(verify)에 바통 인계

## References

| Resource | Path/URL | Related Content |
|----------|---------|-----------------|
| Brief | `docs/03_tarot_shuffle/065_Brief_unified_result_page.md` | MA-0, MA-7, MA-8, MA-9, Ideal Criteria #1-4, #23, #24 |
| Scope | `docs/03_tarot_shuffle/066_Scope_unified_result_page.md` | Cycle 1 섹션, 리스크 R4 (rename tracking), 의존성 맵 |
| TDD Red | `docs/03_tarot_shuffle/067_TDD_Red_rename_cycle1.md` | T1/T2/T3 테스트 명세, Red 실측 결과 |
| Target file (before) | `mobile/lib/features/draw/presentation/pages/instant_draw_page.dart` | Step 2·3의 리네임 대상 |
| Target file (after) | `mobile/lib/features/draw/presentation/pages/draw_result_page.dart` | Step 3·4 이후의 정본 |
| Router | `mobile/lib/core/router/app_router.dart:8, :153-157` | Step 3b·3c·4a |
| Home | `mobile/lib/features/home/presentation/pages/home_page.dart:36, :44` | Step 4b |
| Test (smoke) | `mobile/test/features/draw/draw_result_page_test.dart` | T1 Green 전환 대상 |
| Test (route) | `mobile/test/core/router/draw_result_route_test.dart` | T2·T3 Green 전환 대상 |

## 미비점 및 확장 필요 영역

### Plan 미비점 (makeplan 기록)
| # | 항목 | 심각도 | 설명 |
|---|------|--------|------|
| 1 | C1 단독 상태의 CI 처리 | Medium | C1(`git mv` only)만 적용된 스냅샷은 빌드 실패. 로컬 작업 흐름에서는 C1+C2를 연속 커밋 후 함께 push하여 main에 C1 단독이 존재하지 않도록 한다. CI가 rebase/squash 정책에 따라 C1을 독립 검사할 가능성이 있다면 squash merge 사용 권장 — 본 Plan은 squash 여부를 규정하지 않음 |
| 2 | `git log --follow` 인식 검증 | Low | Git rename 인식은 diff 유사도에 의존. C1을 순수 이동으로 수행하면 거의 확실히 인식되지만, 일부 툴(GitHub web UI)이 follow 미지원 — 구현 완료 후 실측 필요 |
| 3 | Lv1 외 레벨 수동 회귀 | Medium | Cycle 1은 Lv1 플로우만 직접 변경. Lv2 `/draw/animated`, Lv3/Lv4 `/intention/:deckId`는 이번 Cycle에서 건드리지 않지만, home_page의 switch 전체가 영향 범위에 들어가므로 최소 Lv2 push 동작은 확인 권장 (Step 5에서 cover 가능) |

### Implementation 미비점 (implementation 기록)
| # | 항목 | 심각도 | 설명 |
|---|------|--------|------|

### Verification 미비점 (verify 기록)
| # | 항목 | 심각도 | 설명 |
|---|------|--------|------|
