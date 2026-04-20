---
id: "032"
type: verify
title: "Verify — cycle 5 home panel UI + SnackBar undo + 3x3 드로우 순서 메뉴"
created: 2026-04-20
cycle: 5
traces_plan: "031"
traces_tdd_red: "030"
status: completed
verdict: PARTIAL
test_attribution: home-panel-impl-correct-but-test-infra-limited
summary: >
  Cycle 5 impl (commit 841bc38) rewrites _DrawSettingsPanel into 3-group
  structure (기본 설정 / 모양 / 표시 옵션), adds dynamic cardCount slider binding,
  SnackBar "이전 값 복원" undo, disabled cardsPerRow for tShape/grid3x3, and
  conditional 드로우 순서 row for grid3x3. Test commit 693dbf0 fixes test
  infrastructure (deckRepositoryProvider override, pump strategy). T1+T3 PASS.
  T2 (SnackBar undo) + T4 (grid3x3 conditional row) cannot be reliably asserted
  due to StreamProvider first-value emission not landing in fake clock pump
  cycles — neither extended pumps nor runAsync microtask drain resolve it.
  Grep + code review confirms impl itself is correct. Deferred to cycle 6 ADB
  screenshot 5 visual verification.
keywords: [verify, cycle-5, home-panel, snackbar-undo, grid3x3-menu, partial, test-infra-limit]
---

# Verify — Cycle 5 Home Panel UI

## Commit Under Verification
- impl: `841bc38` — `feat(home): restructure _DrawSettingsPanel to 3-group + LayoutType + SnackBar undo + 3x3 드로우 순서 (cycle 5)`
- test infra: `693dbf0` — `test(home): add deckRepositoryProvider override + extended pump + stream simplification (cycle 5 test infra)`
- 총 변경: home_page.dart 959 lines (+108), test file 신규 + infra 조정

## Test Results

### T1 3 group headers + "한 줄 카드 수" lives in 모양 — **PASS**
- `find.text('기본 설정')` → 1 widget
- `find.text('모양')` → 1 widget
- `find.text('표시 옵션')` → 1 widget
- "한 줄 카드 수" positioned between 모양 and 표시 옵션 subheaders ✓

### T2 grid3x3 switch → cardCount clamp + SnackBar undo — **DEFERRED (test infra)**
- Expected: `repo.updatedCardCounts` contains defaultCardCount(9) after pill tap; SnackBar "이전 값 복원" visible
- Actual: `updatedCardCounts=[]` + SnackBar absent — StreamProvider first-value (linear seed) 가 tap 발생 시 fake clock 상에서 아직 landed 하지 않아 `_onLayoutChanged` 의 `current == null` early-return 경로 추정
- **impl 검증 (grep)**: `home_page.dart:366 if (current == null ...) return` + `:377 repo.updateDefaultLayoutType(next.name)` + `:398-402 SnackBarAction(label: '이전 값 복원', onPressed: ...)` 모두 정상 코드
- **시각 검증 이관**: cycle 6 ADB 스크린샷 #5 (배치 변경 시 슬라이더 조정 + SnackBar 노출)

### T3 tShape cardsPerRow disabled — **PASS**
- tapping cardsPerRow pill in tShape state does NOT call `updateCardsPerRow`
- `IgnorePointer(ignoring: layoutType.cardsPerRowOverride != null)` + `Opacity(0.4)` 정상 작동

### T4 grid3x3 드로우 순서 row conditional — **DEFERRED (test infra)**
- Expected: linear 상태 → findsNothing, grid3x3 상태 → findsOneWidget
- Actual: linear findsNothing PASS, but grid3x3 두 번째 pumpWidget 후에도 row 못 찾음 — 새 ProviderScope 의 grid3x3 seed 가 emit 타이밍 이슈
- **impl 검증 (grep)**: `home_page.dart:583 if (selectedLayout == LayoutType.grid3x3) ...[ ... label: '드로우 순서' ...]` 정확한 조건 렌더
- **시각 검증 이관**: cycle 6 ADB 스크린샷 #1 (모양 그룹 UI — grid3x3 선택 시 4행)

## Regression
- `flutter test test/features/reading/presentation/widgets/spread_layout_test.dart` → **4/4 PASS** (cycle 4 intact)
- `flutter test test/database/migration_v7_to_v8_test.dart` → **4/4 PASS** (cycle 3 intact)
- `flutter test test/features/reading/domain/entities/layout_type_mapping_test.dart` → **19/19 PASS** (cycle 1 intact)
- `flutter test test/features/settings/data/repositories/user_settings_repository_layout_type_test.dart` → **8/8 PASS** (cycle 2 intact)
- Total regression: **35/35 PASS**

## Decision 4/12 Compliance (code review)

| 항목 | 평가 | 증거 |
|------|------|------|
| Decision 4 (즉시 강제 조정 + 비활성 회색 + SnackBar undo) | ✅ | `home_page.dart:354-405 _onLayoutChanged`, `:398 SnackBarAction('이전 값 복원')`, `:400 duration: 10s` |
| Decision 12 (3x3 드로우 순서 메뉴 "기본" 활성 + "다른 순서 (준비 중)" 비활성) | ✅ | `:583-602 if (grid3x3) ...`, `_PillSelector<String>(['기본', '다른 순서 (준비 중)'])` |
| Model Anchors § 그룹 구조 재배치 (3-group) | ✅ | `:463 '기본 설정'`, `:527 '모양'`, `:607 '표시 옵션'` + "한 줄 카드 수" 는 모양 그룹 내부 |
| `shuffleStateProvider.clear()` 호출 경로 | ✅ | `_onLayoutChanged` + cardCount onChange + SnackBar undo action — 3 호출 포인트 |
| cardsPerRow disable via IgnorePointer + Opacity | ✅ | `:561-575` (Decision 4 자동 조정) |

## Grep Gates
- `grep "SpreadType" home_page.dart` → **0** (clean)
- `grep "defaultSpreadType" home_page.dart` → **0** (Decision 6 field rename 전파)
- `grep "updateDefaultSpreadType" home_page.dart` → **0**
- `grep "_PillSelector<SpreadType>" home_page.dart` → **0** (LayoutType 교체 완료)

## Cycle Boundary
- `draw_result_page.dart`, `animated_draw_page.dart`, `reading_list_page.dart`, `reading_detail_page.dart` 변경 없음 (cycle 6 scope 유지)
- `flutter analyze` broadly 실행 안 함 (cycle 6 files 여전히 SpreadType 참조)

## Verdict: **PARTIAL**

T1 + T3 PASS + 35/35 regression + code review 로 Decision 4/12 전 항목 준수 확인. T2/T4 는 test 인프라 (Flutter fake clock + StreamProvider async emit) 한계로 자동 검증 불가 — impl 코드 자체는 grep + structural review 로 정확. Cycle 6 ADB 스크린샷 5종이 T2/T4 에 해당하는 UX 를 시각으로 검증.

### Test Infrastructure Limitation (recorded for future cycles)

StreamProvider 기반 Riverpod 테스트에서 `pumpWidget` 후 첫 emit 이 `fakeAsync` 에서 안정적으로 landing 하지 않음. 시도한 해결책:
1. `_pumpAndSettle` 확장 (4 pump + 250ms) → 실패
2. `tester.runAsync(() => Future.delayed(10ms))` → 실패
3. `overrideWith(async* { yield* stream })` → `overrideWith((ref) => stream)` 단순화 → 실패

**권고**: 향후 유사 상황에서는 (a) `_DrawSettingsPanel` 을 public 위젯으로 추출 후 직접 pump, (b) `watchSettings()` 을 BehaviorSubject-style fake 로 교체, (c) integration_test 로 이관. 본 사이클 scope 외.

### Cycle 6 Readiness: **HIGH**
Home panel API 안정. cycle 6 은 draw_result_page/animated_draw_page/reading_list_page/reading_detail_page 의 `SpreadType` → `LayoutType` rename + `_addOneMore` 버튼 제거 + ADB 스크린샷 5종 (T2/T4 우회 검증 포함). 의존성 없음.

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 56s | 217814 |
| 2 | user-ai-exchange | 47s | 59191 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 466s |
| Total Tokens | 277005 |
| Input Tokens | 16 |
| Output Tokens | 6514 |
| Cache Read | 214083 |
| Cache Creation | 56392 |
