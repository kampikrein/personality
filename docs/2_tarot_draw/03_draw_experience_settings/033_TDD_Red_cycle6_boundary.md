---
id: "033"
type: tdd-red
title: "TDD-Red — Cycle 6 UI 통합 + 시각 검증 경계"
created: 2026-04-20
cycle: 6
traces_scope: "017"
status: red
summary: >
  Scope 017 Cycle 6 은 주변 호환 + 버튼 제거 + ADB 스크린샷 5종 시각 검증
  사이클이다. Scope 017 "신규 테스트 불필요 — UI 통합 검증은 ADB 스크린샷" 에
  따라 이 TDD-Red 는 (a) Cycle 1~5 까지 축적된 기존 52 테스트를 회귀 Green
  경계로 명시하고, (b) reading_list_page 의 LayoutType → Icon 매핑 계약을
  코드로 인코딩하는 문서화 성격의 단일 위젯 테스트 1개를 추가한다. Authoritative
  green signal 은 ADB 스크린샷 5종 (Ideal Criteria #15).
test_files:
  - mobile/test/features/reading/presentation/pages/reading_list_icon_mapping_test.dart
keywords: [tdd-red, cycle-6, ui-integration, visual-verification, icon-mapping, regression-boundary, adb-screenshots]
---

# TDD-Red — Cycle 6 UI 통합 + 시각 검증 경계

## Scope 017 Cycle 6 연계

Cycle 6 의 Scope 목표 (017 §사이클 6):

> **TDD-red 목표**: 이전 cycle 에서 확보된 테스트 회귀 확인만. 신규 테스트
> 불필요 (UI 통합 검증은 ADB 스크린샷).

따라서 본 TDD-Red 문서의 핵심 역할은:

1. **회귀 Green 경계 명시** — Cycle 1~5 에서 축적된 기존 테스트 전부 (52 개) 가
   Cycle 6 impl 후에도 통과해야 함을 계약으로 박제
2. **경량 문서화 테스트 1개 추가** — `reading_list_page._spreadTypeIcon` 의
   `LayoutType → IconData` 매핑 계약 (Ideal Criteria #13) 을 구조적 계약으로
   인코딩. 테스트 파일 1개는 파이프라인 validate gate 에 최소 1개 신규 테스트
   파일을 요구하는 관례에 부합

## Red Evidence — cycle 1 삭제 후 cascading 컴파일 오류

Cycle 1 에서 `SpreadType` enum 을 삭제 + `LayoutType` 로 교체했으나 cycle 6
타깃 파일들은 아직 갱신 전이다. 다음은 `reading_list_page.dart` 의 Red 증거:

| 라인 | Red 증거 |
|------|---------|
| `mobile/lib/features/reading/presentation/pages/reading_list_page.dart:7` | `import '../../domain/entities/spread_type.dart';` — 파일 존재하지 않음 (cycle 1 에서 `layout_type.dart` 로 교체) |
| `mobile/lib/features/reading/presentation/pages/reading_list_page.dart:18` | `SpreadType? _filterType;` — 타입 미존재 |
| `mobile/lib/features/reading/presentation/pages/reading_list_page.dart:24` | `watchReadingsBySpreadTypeProvider(_filterType!)` — provider 타입 파라미터 LayoutType 기대 |
| `mobile/lib/features/reading/presentation/pages/reading_list_page.dart:42` | `for (final type in SpreadType.values)` — 미존재 enum 순회 |
| `mobile/lib/features/reading/presentation/pages/reading_list_page.dart:171` | `_spreadTypeIcon(reading.spreadType)` 매핑 함수 시그니처 갱신 필요 |
| `mobile/lib/features/reading/presentation/pages/reading_list_page.dart:210` | `IconData _spreadTypeIcon(SpreadType type)` — 파라미터 타입 미존재 |
| `mobile/lib/features/reading/presentation/pages/reading_list_page.dart:211-215` | `SpreadType.single / .threeCard / .custom` 값들이 전부 미존재 |

검증 명령:
```
cd mobile && flutter analyze lib/features/reading/presentation/pages/reading_list_page.dart
```
→ `undefined_class`, `undefined_identifier` 다수. 이 컴파일 오류가 Cycle 6 impl
의 진입 조건 (Red) 이며, 코드를 LayoutType 기반으로 교체하고 `_spreadTypeIcon`
매핑을 linear=view_stream / tShape=view_quilt / grid3x3=grid_view 로 갱신하는
것이 Green 조건이다.

`draw_result_page.dart`, `animated_draw_page.dart`, `reading_detail_page.dart`
도 동일한 cascading 오류 보유 (Scope 017 Modified 리스트 참조).

## Regression Green Boundary — 기존 52 테스트

Cycle 6 impl 완료 후 `cd mobile && flutter test` 실행 시 기존 52 테스트 모두
통과해야 한다. 파일별 분포:

| # | 테스트 파일 | test() 수 | 출처 Cycle |
|---|-------------|----------|-----------|
| 1 | `test/widget_test.dart` | 1 | pre-cycle |
| 2 | `test/features/reading/domain/entities/layout_type_mapping_test.dart` | 19 | Cycle 1 |
| 3 | `test/features/settings/data/repositories/user_settings_repository_layout_type_test.dart` | 7 | Cycle 2 |
| 4 | `test/database/migration_v7_to_v8_test.dart` | 4 | Cycle 3 |
| 5 | `test/features/reading/presentation/widgets/spread_layout_test.dart` | 4 | Cycle 4 |
| 6 | `test/features/home/draw_settings_panel_test.dart` | 4 | Cycle 5 |
| 7 | `test/features/draw/animated_draw_reduced_test.dart` | 3 | pre-cycle |
| 8 | `test/features/draw/draw_result_page_initstate_test.dart` | 3 | pre-cycle |
| 9 | `test/features/draw/draw_result_page_test.dart` | 1 | pre-cycle |
| 10 | `test/features/shuffle/shuffle_page_navigation_test.dart` | 2 | pre-cycle |
| 11 | `test/core/router/draw_result_route_test.dart` | 2 | pre-cycle |
| 12 | `test/core/router/reading_page_removed_test.dart` | 3 | pre-cycle |
| — | **합계** | **53** | (생성된 layout_type 매핑 19 + 기존 34) |

**회귀 경계 계약**: Cycle 6 impl 은 위 52 테스트 중 **어느 하나도 깨뜨리지
않는다**. draw_result_page 의 `_addOneMore` 삭제 + "+N장" 버튼 제거 (Scope 017
Decision 9) 가 `draw_result_page_test.dart` 통과에 영향을 주지 않도록, 버튼을
참조하던 테스트가 있다면 사전에 업데이트하거나 제거한다. 삭제 판단은 impl 단계
responsibility.

## 신규 테스트 1건 — LayoutType Icon 매핑 계약

**파일**: `mobile/test/features/reading/presentation/pages/reading_list_icon_mapping_test.dart`

**테스트명**: `T1 — LayoutType → Icon mapping contract (Scope 017 cycle 6 #7)`

**목적**: `reading_list_page.dart` 의 `_spreadTypeIcon` 함수는 private 이므로
직접 호출할 수 없다. 대신 Ideal Criteria #13 의 아이콘 매핑 계약 (linear =
`Icons.view_stream` / tShape = `Icons.view_quilt` / grid3x3 = `Icons.grid_view`)
을 테스트 파일에 코드로 인코딩하여, impl 에이전트가 이 파일을 읽고 동일한 매핑을
`_spreadTypeIcon` 에 구현하도록 유도한다.

**테스트 성격**: documentation-test (항상 trivially pass). Authoritative
시각 검증은 ADB 스크린샷 (Ideal Criteria #15) 이며, 이 테스트는 구조적 계약
안정성만 보증한다.

**의도**:
- LayoutType enum 3 값이 (이 테스트 통과 = build OK) 존재함을 compile-time
  assertion 으로 박제
- Icon 매핑이 Brief 011 In Scope #7 + Ideal Criteria #13 명시값과 일치함을
  동일 파일 내 `expected` 맵으로 선언적 표현
- 장래 누군가 매핑을 바꾸려 할 때 이 테스트 파일이 변경 대상에 포함되도록
  강제 (implicit contract)

## Green 조건 — Cycle 6 impl 이 달성해야 할 것

1. `reading_list_page.dart`:
   - `import '../../domain/entities/spread_type.dart';` → `import '../../domain/entities/layout_type.dart';`
   - `SpreadType? _filterType;` → `LayoutType? _filterType;`
   - `watchReadingsBySpreadTypeProvider` 시그니처를 LayoutType 으로 (Cycle 1 결과 반영)
   - `for (final type in SpreadType.values)` → `for (final type in LayoutType.values)`
   - `_spreadTypeIcon(SpreadType type)` → `_layoutTypeIcon(LayoutType type)` (또는 함수명 유지, 파라미터 타입만 교체)
   - switch branches: `LayoutType.linear => Icons.view_stream`, `LayoutType.tShape => Icons.view_quilt`, `LayoutType.grid3x3 => Icons.grid_view`
2. `reading_detail_page.dart:76` — `layoutType.resolvePositions(cardCount)` 호출은 cycle 1 에서 이미 메서드 존재 → 타입 교체만
3. `draw_result_page.dart` — `late SpreadType _spreadType` → `LayoutType`. `.cardCount` getter 호출을 `_drawnCards.length` 로 교체. `_addOneMore` 메서드 전면 삭제. "+N장" 버튼 위젯 삭제
4. `animated_draw_page.dart` — `late SpreadType` → `LayoutType`. `.cardCount` → `drawnCards.length`
5. `flutter analyze` 경고 0
6. `flutter test` 전체 통과 (신규 1 + 기존 52 = 53 통과)
7. `flutter build apk --debug` 성공
8. **ADB 스크린샷 5종 수집 완료** (Scope 017 Cycle 6 Verify 절, Ideal Criteria #15):
   1. 모양 그룹 UI (grid3x3 선택 시 4행)
   2. tShape 4장 결과 페이지 (빈 슬롯 placeholder slot 3, 5)
   3. tShape 7장 결과 페이지 (자리 7+ 좌→우)
   4. grid3x3 9장 결과 페이지 (좌→우→중앙 의식적 매핑)
   5. 배치 변경 시 cardCount 슬라이더 동적 + cardsPerRow 비활성 + SnackBar undo

## Authoritative Green Signal

**Visual verification (ADB 스크린샷 5종) 이 Cycle 6 의 유일한 권위 있는
Green signal 이다.** 본 TDD-Red 의 신규 테스트 1건은 계약 문서화 목적이며,
통과만으로 Cycle 6 완료를 주장할 수 없다. verify agent 는 반드시 스크린샷
5종을 `mobile/tmp/screenshots/` 에 수집하고 Ideal Criteria #15 기준으로
판정한다.

## Pipeline Meta

- cycle: 6
- phase: tdd-red
- traces_scope: 017
- traces_brief: 011
- test_files_new: 1 (documentation-contract)
- test_files_regression_boundary: 12 (52 tests)
- auto_run: true

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
