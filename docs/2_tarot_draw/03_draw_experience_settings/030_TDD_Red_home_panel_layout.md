---
id: "030"
type: tdd-red
title: "TDD Red — Cycle 5 홈 패널 '모양' 그룹 재구성 + SnackBar undo + 3x3 드로우 순서 메뉴"
created: 2026-04-20
cycle: 5
traces_scope: "017"
status: red
summary: >
  Brief 011 Decision 4 (SnackBar undo) + Decision 12 (grid3x3 드로우 순서 메뉴
  자리) + In Scope #4/#5/#8 + Model Anchors § 그룹 구조 재배치 + 자동 조정 원칙
  + Ideal Criteria #6/#7/#8/#14 를 encode 한 4 개의 widget 테스트. `_DrawSettingsPanel`
  을 HomePage 전체 pump 기반으로 검증한다. 현재 `home_page.dart` 는 (a) 삭제된
  `spread_type.dart` 를 import 하고 (b) `SpreadType.single/threeCard/custom` 을
  사용하며 (c) `defaultSpreadType` / `updateDefaultSpreadType` 를 호출하므로
  compile 실패로 red. 또한 의도 동작 ("모양" 그룹 헤더, SnackBar "이전 값 복원",
  "드로우 순서" 메뉴) 도 부재로 런타임 fail. Green 은 cycle 5 impl (seq 19) 에서.
test_files:
  - mobile/test/features/home/draw_settings_panel_test.dart
keywords: [tdd, red, home-panel, layout, snackbar, undo, grid3x3, draw-order, decision-4, decision-12, cycle-5]
---

# TDD Red — Cycle 5 홈 패널 "모양" 그룹 재구성

## Spec Reference

- **Brief**: `docs/2_tarot_draw/03_draw_experience_settings/011_Brief_layout_redesign.md`
  - Decision 4 (홈 패널 "모양" 그룹 신설)
  - Decision 12 (3x3 드로우 순서 메뉴: "기본" 활성 + "다른 순서 (준비 중)" 비활성)
  - In Scope #4 (홈 패널 "모양" 그룹 신설), #5 (배치 선행 선택 + 동적 슬라이더 제약), #8 (3x3 드로우 순서 메뉴)
  - Model Anchors § 그룹 구조 재배치 + 자동 조정 원칙 (SnackBar undo 10초)
  - Ideal Criteria #6 (3-group 구조), #7 (동적 min/max + SnackBar undo), #8 (cardsPerRow 비활성), #14 (드로우 순서 메뉴)
- **Scope**: `docs/2_tarot_draw/03_draw_experience_settings/017_Scope_layout_redesign.md` — cycle 5

## Red Expectation

1. **Compile fail**: `home_page.dart:8` 이 이미 삭제된 `spread_type.dart` 를 import
   → production 파일 자체가 compile 되지 않으므로 본 테스트 파일도 전파 실패.
2. **After home_page compile 복구되더라도** 아래 4 가지 의도 동작이 부재해
   test 가 런타임 fail:
   - "모양" 그룹 헤더 `_PanelSubheader(title: '모양')` 없음
   - 배치 변경 시 SnackBar `"이전 값 복원"` 액션 없음
   - grid3x3 선택 시에만 노출되는 "드로우 순서" 행 없음
   - cardsPerRow 슬라이더 비활성 로직 없음 (현재는 `_PillSelector<int>` 고정)

## Green Target (Cycle 5 Impl — seq 19)

`home_page.dart:447,456-464,478-520` 의 `_DrawSettingsPanel` 을 3-group 재구성
(`기본 설정` / `모양` / `표시 옵션`). Brief Model Anchors § 그룹 구조 재배치 +
자동 조정 원칙에 따라 SnackBar undo, 동적 슬라이더, cardsPerRow 비활성 추가.

## Test Strategy

| # | Test | Decision / Criteria | 관찰 대상 |
|---|------|---------------------|-----------|
| T1 | 3 그룹 헤더 렌더 + "한 줄 카드 수" 이동 | Decision 4, Criteria #6 | `find.text('기본 설정' / '모양' / '표시 옵션')`, "한 줄 카드 수" 행이 "모양" 그룹 내에 |
| T2 | 배치 전환 시 cardCount 범위 갱신 + `defaultCardCount` 클램프 + SnackBar `"이전 값 복원"` | Decision 4, Criteria #7 | `_CountStepper` min/max, SnackBar 텍스트 "이전 값 복원" |
| T3 | tShape 선택 시 cardsPerRow 슬라이더 회색 비활성 + 값 3 고정 | Criteria #8 | `_PillSelector<int>` onSelect == null 또는 visual 비활성 상태 |
| T4 | grid3x3 선택 시에만 "드로우 순서" 행 렌더 + "기본" 활성 + "다른 순서 (준비 중)" 비활성 | Decision 12, Criteria #14 | `find.text('드로우 순서')`, `find.text('기본')`, `find.text('다른 순서 (준비 중)')` |

### 테스트 접근법

`_DrawSettingsPanel` 이 private 클래스이므로 `HomePage` 전체를 pump 하여 패널이
렌더된 상태에서 text/key finder 로 검증. `userSettingsProvider` / `userSettingsRepositoryProvider` /
`watchDecksProvider` 를 `ProviderScope.overrides` 로 가짜 구현에 덮어쓰기.

## Red State Verification

다음은 `mobile/lib/features/home/presentation/pages/home_page.dart` 현 상태의
red 근거:

| line | 현재 상태 | Red 원인 |
|------|----------|---------|
| 8 | `import '../../../reading/domain/entities/spread_type.dart';` | 파일 삭제됨 (cycle 1 완료) → **compile fail** |
| 456 | `child: _PillSelector<SpreadType>(` | `SpreadType` symbol 미존재 → compile fail |
| 458-460 | `SpreadType.single` / `.threeCard` / `.custom` | enum 삭제됨 → compile fail |
| 462 | `settings?.defaultSpreadType ?? SpreadType.custom` | UserSettings 에 `defaultSpreadType` 필드 미존재 (현재 `defaultLayoutType`) → compile fail |
| 463 | `repo.updateDefaultSpreadType(v.name)` | Repository 에 `updateDefaultSpreadType` 미존재 (현재 `updateDefaultLayoutType`) → compile fail |
| 390-391 | `_PanelSubheader(title: '기본 설정')` 존재 | T1 의 3 그룹 중 "기본 설정" 은 통과하나 "모양" 헤더 부재 |
| 482 | `_PanelSubheader(title: '표시 옵션')` 존재 | T1 의 "모양" 헤더 누락 (2 그룹만 있고 3 번째 "모양" 없음) → T1 런타임 fail |
| 506-520 | "한 줄 카드 수" 가 "표시 옵션" 그룹 아래 | T1 의 "모양 그룹 내" 조건 미충족 → 런타임 fail |
| (없음) | SnackBar "이전 값 복원" 로직 전무 | T2 런타임 fail |
| (없음) | cardsPerRow 비활성 로직 전무 | T3 런타임 fail |
| (없음) | "드로우 순서" 행 전무 | T4 런타임 fail |

## 결론

production 파일이 compile 조차 되지 않아 4 테스트 모두 compile 단계에서 red.
impl 단계 (seq 19) 가 `SpreadType` 를 `LayoutType` 으로 교체하면 compile 은
복구되지만, 의도 동작 부재로 T1~T4 여전히 런타임 red. 실제 green 은 Brief
Decision 4/12 + Model Anchors 구현 후.

## Notes

- Brief Decision 4 의 "이전 값 보존 안 함" 원칙과 SnackBar undo 가 공존 — SnackBar
  탭으로만 복원 가능, 탭 안 하면 자동 폐기. 본 TDD 는 SnackBar 노출 여부만 검증
  (탭 후 복원 동작은 cycle 5 impl 에서 추가 검증 권장, 본 red 범위 외).
- `_DrawSettingsPanel` 을 별도 파일로 분리하여 props 기반 직접 pump 하는 refactor
  가 테스트 편의상 유리하지만, cycle 5 범위 밖 (scope 017 cycle 5 Modified 는
  `home_page.dart` 1 파일). 본 red 는 HomePage 전체 pump 로 검증.

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 56s | 217814 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 56s |
| Total Tokens | 217814 |
| Input Tokens | 10 |
| Output Tokens | 3434 |
| Cache Read | 160671 |
| Cache Creation | 53699 |
