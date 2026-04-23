---
id: "046"
type: tdd-red
title: "TDD Red: Settings UI (IntentPlacementSettingsPage + entry)"
created: 2026-04-21
cycle: 2
traces_scope: "041"
status: completed
test_count: 5
framework: "flutter_test"
summary: >
  Cycle 2 Settings UI 영역의 failing 위젯 테스트. IntentPlacementSettingsPage
  3-way 선택 UI, HomePage._DrawSettingsPanel 진입 행, 라우터 등록 여부를 검증한다.
keywords: [tdd-red, settings-ui, intent-placement, widget-test, cycle-2]
test_files:
  - mobile/test/features/settings/intent_placement_settings_page_test.dart
  - mobile/test/features/home/intent_placement_entry_test.dart
---

# TDD Red: Settings UI (IntentPlacementSettingsPage + entry)

## Test Strategy

Cycle 2의 핵심 동작 3가지를 검증한다:
1. `IntentPlacementSettingsPage`가 3개 옵션 행을 렌더링하고 선택 표시기를 노출
2. 다른 행 탭 시 `updateIntentPlacement` 호출
3. `HomePage._DrawSettingsPanel`에 '의도 입력' 진입 행이 존재하고 `/settings/intent-placement`로 이동

## Test Specifications

### T1: IntentPlacementSettingsPage — 3 options visible
- **동작**: 페이지가 3개 IntentPlacement 옵션 라벨을 렌더링
- **입력**: userSettingsProvider override (현재값 beforeShuffle)
- **기대 결과**: '뽑기 전 입력', '뽑은 후 입력', '의도 입력 비활성' 텍스트 각 1개 존재
- **파일**: mobile/test/features/settings/intent_placement_settings_page_test.dart

### T2: IntentPlacementSettingsPage — selected indicator visible
- **동작**: 현재 선택된 옵션에 선택 표시기(gold icon)가 표시됨
- **입력**: userSettingsProvider override (현재값 beforeShuffle)
- **기대 결과**: '뽑기 전 입력' 행에 check icon 존재
- **파일**: mobile/test/features/settings/intent_placement_settings_page_test.dart

### T3: IntentPlacementSettingsPage — tap calls updateIntentPlacement
- **동작**: 다른 옵션 탭 시 repo.updateIntentPlacement 호출
- **입력**: '뽑은 후 입력' 탭 (현재 beforeShuffle)
- **기대 결과**: repo.capturedValue == IntentPlacement.afterDraw
- **파일**: mobile/test/features/settings/intent_placement_settings_page_test.dart

### T4: HomePage._DrawSettingsPanel — '의도 입력' entry row exists
- **동작**: DrawSettingsPanel에 '의도 입력' 텍스트를 가진 행이 존재
- **입력**: HomePage ProviderScope 오버라이드
- **기대 결과**: find.text('의도 입력') findsOneWidget
- **파일**: mobile/test/features/home/intent_placement_entry_test.dart

### T5: HomePage — tapping '의도 입력' navigates to /settings/intent-placement
- **동작**: 진입 행 탭 시 GoRouter push('/settings/intent-placement') 호출
- **입력**: mockGoRouter 또는 observer
- **기대 결과**: navigated location contains '/settings/intent-placement'
- **파일**: mobile/test/features/home/intent_placement_entry_test.dart

## Test Files
| # | File Path | Test Count | Status |
|---|-----------|-----------|--------|
| 1 | mobile/test/features/settings/intent_placement_settings_page_test.dart | 3 | red |
| 2 | mobile/test/features/home/intent_placement_entry_test.dart | 2 | red |

## Red State Verification

```
# intent_placement_settings_page_test.dart
test/features/settings/intent_placement_settings_page_test.dart:29:8:
  Error: Error when reading 'lib/features/settings/presentation/pages/intent_placement_settings_page.dart':
  No such file or directory
  import 'package:personality_mobile/features/settings/presentation/pages/intent_placement_settings_page.dart';
  → Compilation failed (T1/T2/T3 all RED — import 실패)

# intent_placement_entry_test.dart
T4: Expected: exactly one matching widget
  Actual: Found 0 widgets with text "의도 입력"
  → RED (진입 행 미존재)

T5: The finder "Found 0 widgets with text "의도 입력"" could not find any matching widgets
  → RED (tap 대상 미존재)

00:00 +0 -3: Some tests failed.
```

**실패 원인 분류**:
- T1/T2/T3: `IntentPlacementSettingsPage` 클래스 미존재 → import 컴파일 에러
- T4/T5: `_DrawSettingsPanel`에 '의도 입력' 행 미추가

**Green을 위해 필요한 변경**:
1. `mobile/lib/features/settings/presentation/pages/intent_placement_settings_page.dart` 신규 생성
   - 3개 옵션 행: '뽑기 전 입력'(beforeShuffle), '뽑은 후 입력'(afterDraw), '의도 입력 비활성'(disabled)
   - 선택된 항목에 `Icons.check_rounded` 표시
   - 탭 시 `repo.updateIntentPlacement(value)` 호출
2. `mobile/lib/features/home/presentation/pages/home_page.dart`
   - `_DrawSettingsPanel`에 '의도 입력' GestureDetector 행 추가 (카드 크기 행 패턴 참조)
   - `context.push('/settings/intent-placement')` 호출
3. `mobile/lib/core/router/app_router.dart`
   - `GoRoute(path: '/settings/intent-placement', ...)` 등록

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
