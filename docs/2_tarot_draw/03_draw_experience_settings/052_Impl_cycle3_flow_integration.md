---
id: "052"
type: implementation
topic: intent_placement_setting
cycle: 3
status: completed
commit: 42e5339
date: 2026-04-21
---

# Cycle 3 구현 보고서 — IntentPlacement Flow Integration

## 수정 파일

| 파일 | 변경 내용 |
|------|----------|
| `mobile/lib/features/shuffle/presentation/pages/intention_page.dart` | AsyncLoading 처리 + redirect 로직 리팩터링 (핵심 fix) |
| `mobile/lib/features/home/presentation/pages/home_page.dart` | `_startDraw` intentPlacement 분기 (T3/T4/T5) |
| `mobile/lib/features/reading/domain/repositories/reading_repository.dart` | `updateQuestion` 인터페이스 추가 |
| `mobile/lib/features/reading/data/repositories/reading_repository_impl.dart` | `updateQuestion` 구현 (T1/T2) |
| `mobile/lib/features/draw/presentation/pages/draw_result_page.dart` | afterDraw 질문 입력 박스 표시 (T8a-T8c) |
| `mobile/lib/features/deck/presentation/pages/deck_selection_page.dart` | 관련 변경 |
| `mobile/lib/core/database/daos/reading_dao.dart` | updateQuestion DAO 메서드 |
| `mobile/lib/core/router/app_router.g.dart` | 라우터 코드젠 갱신 |

## AsyncLoading 수정 (Option A — production fix)

### 문제
`initState` 내 `ref.read(userSettingsProvider).valueOrNull` 호출 시:
- `userSettingsProvider`는 `StreamProvider` → 첫 프레임에서 `AsyncLoading` 상태
- `valueOrNull`이 `null` 반환 → fallback `beforeShuffle`로 처리됨
- T6 (`afterDraw` → redirect to shuffle) 테스트 실패

### 수정 내용

`_redirectChecked` 플래그를 추가하고, `build`에서 `ref.watch(userSettingsProvider)`의 `whenData`로 데이터가 최초 resolve될 때 한 번만 `addPostFrameCallback`을 통해 redirect 평가:

```dart
bool _redirectChecked = false;

// build() 내부:
final settingsAsync = ref.watch(userSettingsProvider);
if (!_redirectChecked) {
  settingsAsync.whenData((settings) {
    _redirectChecked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeRedirect(settings.intentPlacement);
    });
  });
}
if (settingsAsync.isLoading && settingsAsync.valueOrNull == null) {
  return const Scaffold(body: Center(child: SizedBox.shrink()));
}
```

- AsyncLoading 중 → `SizedBox.shrink()` 렌더링
- 데이터 resolve 시 → `_maybeRedirect` 최초 1회 실행
- `Stream.value(settings)` override → 테스트에서 첫 rebuild 시 immediately data 상태 → redirect 정상 동작

### 테스트 override (Option B — test-side)
테스트에서 이미 `userSettingsProvider.overrideWith((ref) => repo.watchSettings())` + `Stream.value(settings)` 사용 중으로 충분.

## Cycle 3 테스트 결과

```
10/10 pass, 0 fail, 0 dropped

T1 — ReadingRepository.updateQuestion persists updated text         PASS
T2 — ReadingRepository.updateQuestion with null clears              PASS
T3 — Lv4 + beforeShuffle: _startDraw → /intention/:deckId          PASS
T4 — Lv4 + afterDraw: _startDraw → /shuffle/:deckId                PASS
T5 — Lv4 + disabled: _startDraw → /shuffle/:deckId                 PASS
T6 — IntentionPage afterDraw → redirect to ShufflePage             PASS
T7 — IntentionPage beforeShuffle → renders body                    PASS
T8a — DrawResultPage afterDraw renders question box                 PASS
T8b — DrawResultPage beforeShuffle hides question box               PASS
T8c — DrawResultPage disabled hides question box                    PASS
```

## Full Suite 결과

```
+79 -6: Some tests failed.
```

6개 pre-existing 실패 (변동 없음):
- migration_v7_to_v8_test T1-T4 (pre-existing, Cycle 3 범위 외)
- draw_settings_panel_test T2, T4 (pre-existing)

## Build

```
✓ Built build/app/outputs/flutter-apk/app-debug.apk
```

## Commit

SHA: `42e5339`
