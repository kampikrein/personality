---
id: "031"
type: plan
title: "Plan — Cycle 5 홈 패널 3-그룹 재구성 + SnackBar undo + 드로우 순서 메뉴"
created: 2026-04-20
cycle: 5
traces_scope: "017"
traces_tdd_red: "030"
status: ready
summary: >
  cycle 5 impl 계획. `mobile/lib/features/home/presentation/pages/home_page.dart`
  의 `_DrawSettingsPanel` 을 3-group (기본 설정 / 모양 / 표시 옵션) 으로 재구성
  하고, `SpreadType` → `LayoutType` 전환, cardCount 동적 min/max + 범위 밖 값
  auto-reset, 10초 SnackBar "이전 값 복원" undo, tShape/grid3x3 시 cardsPerRow
  비활성, grid3x3 전용 "드로우 순서" 메뉴 (기본 활성 + 다른 순서 (준비 중) 비활성),
  레이아웃/카드수 전환 시 `shuffleStateProvider.clear()` 를 구현해
  030 의 T1~T4 4 테스트를 green 으로 전환한다. 패널은 `ConsumerStatefulWidget` 으로
  승격하여 SnackBar undo 용 이전 상태 스냅샷을 로컬에 보관한다.
keywords: [plan, cycle-5, home-panel, layout-type, snackbar-undo, grid3x3, draw-order, decision-4, decision-12]
---

# Plan — Cycle 5 홈 패널 3-그룹 재구성 + SnackBar undo + 드로우 순서 메뉴

## 1. Goal

Brief 011 Decision 4 (3-group 재배치 + 자동 조정 원칙 + SnackBar undo)
와 Decision 12 (grid3x3 드로우 순서 메뉴 자리 마련) 를 단일 파일
`mobile/lib/features/home/presentation/pages/home_page.dart` 수정으로 집행
한다. 현재 `_DrawSettingsPanel` 은 삭제된 `spread_type.dart` 를 import 하며
`SpreadType.single/threeCard/custom` 과 `defaultSpreadType` /
`updateDefaultSpreadType` API 를 호출하므로 compile 실패 상태이다 (cycle
1+2 에서 API 를 `LayoutType` / `defaultLayoutType` / `updateDefaultLayoutType`
으로 교체했기 때문). 이 plan 은 import 교체 + UI 재구성 + 상태 흐름
변경을 하나의 논리적 변경으로 묶어 030 의 T1~T4 를 통과시키는 최소 경로이다.

## 2. File Changes

### Modified (1 primary)

#### `mobile/lib/features/home/presentation/pages/home_page.dart`

##### (A) Import 교체
- L8 `import '../../../reading/domain/entities/spread_type.dart';`
  → `import '../../../reading/domain/entities/layout_type.dart';`
- 신규 추가: `import '../../../shuffle/presentation/providers/shuffle_providers.dart';`

##### (B) `_DrawSettingsPanel` 을 `ConsumerStatefulWidget` 으로 승격
- 현재 `ConsumerWidget` (L340-562) → `ConsumerStatefulWidget`
- State 필드 2개:
  - `({LayoutType layoutType, int cardCount, int cardsPerRow})? _previousSnapshot` — SnackBar undo 가능 시점 마지막 상태
  - `ScaffoldMessengerState? _messenger` — didChangeDependencies 시점 캡쳐 (선택, `ScaffoldMessenger.of(context)` 직접 호출도 가능하므로 State 필드 없이 구현도 허용)
- 기존 build(context, ref) 내용은 `build(context)` 로 이동, `ref` 는
  State 의 `ref` getter (Consumer State 제공) 로 대체

##### (C) 그룹 구조 재배치
현재 L388-519 순서:
1. 헤더 `_PanelSubheader('기본 설정')`
2. 덱 / 레벨 / 카드 수 / 스프레드 / 역방향 (5행)
3. 헤더 `_PanelSubheader('표시 옵션')`
4. 앞면 / 카드 이름 / 한 줄 카드 수 / 카드 크기 (4행)

새 순서:
1. 헤더 `_PanelSubheader('기본 설정')`
   - 덱 (기존 행 유지)
   - 레벨 (기존 행 유지)
   - 역방향 (기존 행 유지)
   - **기본 카드 수 행 제거** (모양 그룹으로 이동)
   - **스프레드 행 제거** (모양 그룹으로 이동 + LayoutType 으로 교체)
2. 헤더 `_PanelSubheader('모양')` (신규)
   - 배치 (`_PillSelector<LayoutType>` — `linear` / `tShape` / `grid3x3`, 라벨은
     `LayoutType.displayName` 사용: `나열` / `T모양` / `3x3`)
   - 카드 수 (`_CountStepper`, min/max 는 `selectedLayoutType.cardCountMin/Max`
     동적)
   - 한 줄 카드 수 (`_PillSelector<int>`, tShape/grid3x3 선택 시 비활성
     — 아래 (E) 참고)
   - (조건) **드로우 순서** — `selectedLayoutType == LayoutType.grid3x3` 일
     때만 렌더. 아래 (G) 참고
3. 헤더 `_PanelSubheader('표시 옵션')`
   - 앞면으로 시작 (기존 유지)
   - 카드 이름 (기존 유지)
   - **한 줄 카드 수 행 제거** (모양 그룹으로 이동)
   - 카드 크기 (기존 유지)

##### (D) `_PillSelector<SpreadType>` → `_PillSelector<LayoutType>` 교체
현재 L456-464:
```
_PillSelector<SpreadType>(
  options: [ (SpreadType.single, '1장'), (SpreadType.threeCard, '3장'),
             (SpreadType.custom, '자유') ],
  selected: settings?.defaultSpreadType ?? SpreadType.custom,
  onSelect: (v) => repo.updateDefaultSpreadType(v.name),
)
```

새 본문:
```
_PillSelector<LayoutType>(
  options: [
    (value: LayoutType.linear, label: LayoutType.linear.displayName),   // '나열'
    (value: LayoutType.tShape, label: LayoutType.tShape.displayName),   // 'T모양'
    (value: LayoutType.grid3x3, label: LayoutType.grid3x3.displayName), // '3x3'
  ],
  selected: settings?.defaultLayoutType ?? LayoutType.linear,
  onSelect: (v) => _onLayoutChanged(v, settings, repo),
)
```

##### (E) 동적 cardCount 슬라이더 + 자동 조정
`_CountStepper` 호출부에서 선택된 LayoutType 을 `settings?.defaultLayoutType ?? LayoutType.linear` 로 해석한 후:
```
final lt = settings?.defaultLayoutType ?? LayoutType.linear;
_CountStepper(
  value: settings?.defaultCardCount ?? lt.defaultCardCount,
  min: lt.cardCountMin,
  max: lt.cardCountMax,
  onChanged: (v) {
    repo.updateDefaultCardCount(v);
    ref.read(shuffleStateProvider.notifier).clear();  // 014 Critique R4
  },
)
```

##### (F) cardsPerRow 비활성 상태
`_PillSelector<int>` 를 `IgnorePointer` + `Opacity(0.4)` 로 감싸 tShape/grid3x3
에서 비활성 시각 + 탭 무반응. 선택된 값은 3 으로 고정 표시:
```
final lt = settings?.defaultLayoutType ?? LayoutType.linear;
final cardsPerRowDisabled = lt.cardsPerRowOverride != null;
final effectiveCpr = lt.cardsPerRowOverride ?? (settings?.cardsPerRow ?? 3);

IgnorePointer(
  ignoring: cardsPerRowDisabled,
  child: Opacity(
    opacity: cardsPerRowDisabled ? 0.4 : 1.0,
    child: _PillSelector<int>(
      options: const [
        (value: 1, label: '1장'),
        (value: 2, label: '2장'),
        (value: 3, label: '3장'),
      ],
      selected: effectiveCpr,
      onSelect: (v) => repo.updateCardsPerRow(v),
    ),
  ),
)
```
(T3 는 `updateCardsPerRow` 가 호출되지 않는 것을 검증 — `IgnorePointer` 가
GestureDetector 의 onTap 을 무효화하므로 보장됨.)

##### (G) grid3x3 전용 "드로우 순서" 행 (Decision 12)
`selectedLayoutType == LayoutType.grid3x3` 일 때만 `_SettingRow(label: '드로우 순서', ...)` 렌더:
```
if (lt == LayoutType.grid3x3) ...[
  _GoldHairline(opacity: 0.1),
  _SettingRow(
    label: '드로우 순서',
    icon: Icons.swap_horiz_outlined,
    child: _PillSelector<String>(
      options: const [
        (value: 'default', label: '기본'),
        (value: 'other', label: '다른 순서 (준비 중)'),
      ],
      selected: 'default',
      onSelect: (v) {
        if (v == 'other') {
          // 비활성 — 무반응 (Decision 12 정책). Optional toast 생략.
        }
      },
    ),
  ),
],
```
주의: `_PillSelector` 는 비활성 스타일을 지원하지 않으므로 비활성 옵션
탭은 onSelect 에서 no-op 처리. T4 는 `find.text('다른 순서 (준비 중)')`
존재만 검증하므로 시각적 회색은 현 스펙에서 필수 아님 (추후 개선
여지, cycle 6/향후). 본 plan 은 테스트 통과 최소 경로를 선택한다.

##### (H) `_onLayoutChanged` 핸들러 (SnackBar undo + auto-reset)
`_DrawSettingsPanelState` 에 private 메서드:
```
Future<void> _onLayoutChanged(
  LayoutType next,
  UserSettings? settings,
  UserSettingsRepository repo,
) async {
  final prev = settings;
  if (prev == null || prev.defaultLayoutType == next) return;

  // Snapshot 이전 상태 (SnackBar undo 용)
  final snapshot = (
    layoutType: prev.defaultLayoutType,
    cardCount: prev.defaultCardCount,
    cardsPerRow: prev.cardsPerRow,
  );

  // 1) LayoutType 갱신
  await repo.updateDefaultLayoutType(next.name);
  ref.read(shuffleStateProvider.notifier).clear();

  // 2) cardCount auto-reset (범위 밖이면 defaultCardCount 로)
  final currentCount = prev.defaultCardCount;
  if (currentCount < next.cardCountMin || currentCount > next.cardCountMax) {
    await repo.updateDefaultCardCount(next.defaultCardCount);
  }

  // 3) cardsPerRow 강제 적용 (override 있으면)
  final override = next.cardsPerRowOverride;
  if (override != null && prev.cardsPerRow != override) {
    await repo.updateCardsPerRow(override);
  }

  // 4) SnackBar "이전 값 복원" 10초
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text('배치 변경에 따라 설정이 조정되었어요'),
      duration: const Duration(seconds: 10),
      action: SnackBarAction(
        label: '이전 값 복원',
        onPressed: () async {
          await repo.updateDefaultLayoutType(snapshot.layoutType.name);
          await repo.updateDefaultCardCount(snapshot.cardCount);
          await repo.updateCardsPerRow(snapshot.cardsPerRow);
          ref.read(shuffleStateProvider.notifier).clear();
        },
      ),
    ),
  );
}
```

주의: `HomePage` 의 최상위에 `Scaffold` 가 있으므로 `ScaffoldMessenger.of`
가 존재한다. 테스트는 `MaterialApp(home: HomePage())` 로 감싸므로 기본
ScaffoldMessenger 가 자동으로 제공된다.

### Reviewed (변경 없음)

| 파일 | 확인 내용 |
|------|-----------|
| `mobile/lib/features/home/presentation/pages/home_page.dart:808-827` `_PanelSubheader` | 재사용 확인 |
| `mobile/lib/features/home/presentation/pages/home_page.dart:637-686` `_PillSelector<T>` | generic T 재사용 확인 — `LayoutType` / `String` 둘 다 동작 |
| `mobile/lib/features/reading/domain/entities/layout_type.dart` | `cardCountMin/Max`, `defaultCardCount`, `cardsPerRowOverride`, `displayName` 사용 |
| `mobile/lib/features/shuffle/presentation/providers/shuffle_providers.dart:52-61` `ShuffleState.clear()` | `state = null` — 호출부에서 `notifier.clear()` 호출 확인 |

### New

없음. (030 의 테스트 파일 `mobile/test/features/home/draw_settings_panel_test.dart` 은 tdd-red 단계에서 이미 작성됨.)

## 3. Test → Code Mapping

| Test | 검증 대상 | 본 plan 에서 만족하는 변경 |
|------|-----------|-----------------------------|
| T1 | 3 그룹 헤더 + "한 줄 카드 수" 가 모양 그룹 내 | (C) 그룹 구조 재배치 |
| T2 | grid3x3 선택 → cardCount 9 로 auto-reset + SnackBar "이전 값 복원" 노출 | (H) `_onLayoutChanged` 의 auto-reset + SnackBar undo |
| T3 | tShape → cardsPerRow 비활성 → 탭 시 `updateCardsPerRow` 호출 없음 | (F) `IgnorePointer` wrap |
| T4 | linear → "드로우 순서" 없음 / grid3x3 → "드로우 순서" + "기본" + "다른 순서 (준비 중)" 렌더 | (G) 조건 렌더 |

추가 고려: T2 는 `_FakeSettingsRepo` 가 `updateDefaultCardCount` 호출을
기록하므로 `repo.updatedCardCounts.contains(9)` 검증. (H) 의 2 단계에서
`updateDefaultCardCount(9)` 호출 → 통과.

## 4. Risks

- **R1 (확정): `_DrawSettingsPanel` 은 현재 `ConsumerWidget`** (home_page.dart:340).
  → `ConsumerStatefulWidget` 으로 승격 필수. createState / State 클래스
  신규. `settings` / `decksAsync` 는 widget field 로 유지 (부모가 주입).
- **R2: SnackBar undo 는 위젯 State 가 필요.** State 필드 `_previousSnapshot`
  대신 `_onLayoutChanged` 의 지역 변수로 snapshot 캡처 → SnackBar 클로저
  에서 사용. State 자체는 SnackBar 를 띄우기 위한 `context` / `mounted`
  제공자 역할. 독립 pump 테스트 필요성 없음 (030 테스트는 HomePage 전체
  pump 기반).
- **R3: `_PillSelector<LayoutType>` generic 동작 확인.** L637-686 의 정의는
  `_PillSelector<T>` generic 이며 `opt.value == selected` 로 비교 —
  enhanced enum 은 identity 비교 가능하므로 작동. `LayoutType.displayName`
  을 label 로 전달하여 `'나열'` / `'T모양'` / `'3x3'` 이 렌더되어 T2 의
  `find.text('3x3')` 가 매칭됨.
- **R4: 동적 slider 범위.** 기존 `_CountStepper` 는 min=1 max=10 고정
  인자. (E) 에서 `lt.cardCountMin/Max` 로 주입 → 기존 linear (1,10) 은
  보존 + 비 linear 에서 새 범위 적용. `_CountStepper` 내부 로직은 이미
  min/max 를 받으므로 변경 불필요.
- **R5: 테스트 ProviderScope override.** 030 은 `userSettingsProvider`,
  `userSettingsRepositoryProvider`, `watchDecksProvider` 3 개를 override.
  본 plan 이 추가로 사용하는 `shuffleStateProvider` 는 override 되지
  않으므로 default 동작 (생성자 `state = null`) 이 된다. `.clear()` 호출
  시 fresh notifier 가 생성되어도 state 를 null 로 재설정할 뿐 side-effect
  없음 → 테스트 통과에 영향 없음.
- **R6: SnackBar 테스트 검증 타이밍.** T2 는 `tester.tap(grid3x3Pill)` →
  `_pumpAndSettle` → `find.text('이전 값 복원')`. `_onLayoutChanged` 가
  async 이므로 SnackBar 가 나타나려면 `pump` 후 frame 1~2 추가 필요.
  030 의 `_pumpAndSettle` 은 `pump()` + `pump(50ms)` → sufficient.
  다만 async 체인 (`await repo.updateDefaultLayoutType` → await
  `updateDefaultCardCount` → ...) 이 완료된 뒤 SnackBar 호출이므로, fake
  repo 의 Future 가 `async` 로 즉시 완료되기에 2 frame pump 로 충분.
- **R7: `_previousSnapshot` 불필요 가능성.** `_onLayoutChanged` 지역 변수로
  snapshot 을 캡쳐하여 SnackBar action 클로저가 참조하는 방식으로 충분 →
  State 필드 생략. 단 `mounted` 체크와 `context` 접근 때문에
  `ConsumerStatefulWidget` 승격은 유지.

## 5. Verification Plan (for verify seq=20)

Main session (verify skill) 이 실행:

- `cd /Users/kampikrein/A/personality/mobile && flutter test test/features/home/draw_settings_panel_test.dart`
  → 4/4 pass (T1~T4)
- 회귀 테스트 (cycle 1~4 누적):
  - `flutter test test/features/reading/presentation/widgets/spread_layout_test.dart`
  - `flutter test test/database/migration_v7_to_v8_test.dart`
  - `flutter test test/features/reading/domain/entities/layout_type_mapping_test.dart`
  - `flutter test test/features/settings/data/repositories/user_settings_repository_layout_type_test.dart`
  - → 기존 통과 수 유지 (cycle 4 까지 ~30 tests + cycle 5 신규 4 = 34/34)
- `flutter analyze lib/features/home/presentation/pages/home_page.dart` → 0 issues
- **Deferred**: 전역 `flutter analyze`, 전체 `flutter test` — cycle 6 파일
  이 여전히 `SpreadType` 을 참조하여 compile fail 이므로 cycle 6 verify
  까지 유예 (scope 017 Context Overflow 원칙).

## 6. Discovered Cycle 6 Impacts

cycle 5 작업 중 검토한 파일 중, cycle 6 범위로 확정된 항목 (스코프
017 cycle 6 Modified 리스트와 일치, 추가 발견 없음):

1. `mobile/lib/features/reading/presentation/pages/reading_list_page.dart`
   — `SpreadType` 필터 칩 미교체. cycle 6 처리.
2. `mobile/lib/features/reading/presentation/pages/draw_result_page.dart`
   — `late SpreadType _spreadType` + `_addOneMore` + "+N장" 버튼.
   cycle 6 에서 `LayoutType` 전환 및 버튼 삭제 (Brief Decision 9).
3. `mobile/lib/features/reading/presentation/pages/animated_draw_page.dart`
   — `late SpreadType` + `.cardCount`. cycle 6 에서 교체.
4. `mobile/lib/features/reading/presentation/pages/reading_detail_page.dart`
   — `resolvePositions` 호환 확인만. 변경 없을 가능성 높음.
5. **추가 신규 발견**: `mobile/lib/features/draw/presentation/pages/draw_result_page.dart`
   및 `animated_draw_page.dart` (경로가 `features/draw/` vs `features/reading/`
   중복 존재 가능) — grep 결과 `features/draw/` 경로에도 `shuffleStateProvider`
   참조 존재. cycle 6 impl 시 `features/reading/` 과 `features/draw/` 양쪽
   파일 경로 모두 확인 필요.

## 7. Cycle Boundary

- 본 plan 은 `mobile/lib/features/home/presentation/pages/home_page.dart` 1 파일만 수정한다.
- cycle 6 범위 파일 (draw_result_page / animated_draw_page / reading_list_page / reading_detail_page) 은 건드리지 않는다.
- 광역 `flutter analyze` / 광역 `flutter test` 실행 금지 — cycle 6 compile fail 이 아직 살아 있어 의미 있는 신호를 얻을 수 없다.

## 8. Pipeline Meta

- cycle: 5
- status: ready
- traces_scope: "017"
- traces_tdd_red: "030"
- next step: `pipeline.sh update 19 pending` (impl) → cycle 5 impl agent 호출

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
