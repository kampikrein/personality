---
id: "034"
type: plan
title: "Plan — Cycle 6 주변 호환 + 버튼 제거 + ADB 스크린샷 5종"
created: 2026-04-20
cycle: 6
traces_scope: "017"
traces_tdd_red: "033"
status: ready
summary: >
  Scope 017 Cycle 6 의 impl 계획. 4 파일(SpreadType→LayoutType 로컬 타입 교체
  + `_addOneMore`/`+N장` 버튼 제거 + `SpreadLayout` callsite 파라미터명 전환)
  과 ADB 스크린샷 5종 캡처를 기계적 절차로 정리. 핵심 판단:
  (1) `watchReadingsBySpreadTypeProvider` 는 Cycle 1 에서 이미 LayoutType 을
  받도록 갱신됨 → 이름 유지 + 로컬 호출 타입만 교체 (Option A).
  (2) draw_result/animated_draw 의 `.cardCount` getter 는 LayoutType 에 없으므로
  `_drawnCards.length`/shuffleResult 기반으로 치환.
  (3) 5종 스크린샷은 에뮬레이터가 실행 중일 때만 캡처 가능하며, 미실행 시
  impl 은 "deferred to user-run" 로그 후 코드 커밋까지 진행.
keywords: [plan, cycle-6, layout-type, peripheral, button-removal, adb-screenshots, visual-verification]
---

# Plan — Cycle 6 주변 호환 + 버튼 제거 + ADB 스크린샷 5종

## 1. Goal

Cycle 1~5 에서 축적된 `LayoutType` 도메인/DB/렌더링/홈 패널 변경을 남아 있던
4개 주변 UI 파일에 기계적으로 전파한다: `reading_list_page.dart`,
`reading_detail_page.dart`, `draw_result_page.dart`, `animated_draw_page.dart`.
동시에 Brief 011 Decision 9 에 따라 `draw_result_page` 의 `_addOneMore` 메서드
와 "+N장" 버튼을 전면 삭제하고, `SpreadLayout(spreadType:)` callsite 를
`layoutType:` 로 교체한다. 최종 검증은 Brief Constraints § 시각 검증 5종 ADB
스크린샷 + 전체 `flutter analyze` 경고 0 + `flutter test` 53개 회귀 Green +
`flutter build apk --debug` 성공이다. 이 cycle 종료 후 tail chain (eval →
qualify → push → retro) 으로 진입한다.

## 2. File-by-file changes (4 Modified)

> **경로 정정**: Scope 017 은 `draw_result_page.dart`/`animated_draw_page.dart`
> 를 `features/reading/presentation/pages/` 로 표기했으나 실제 경로는
> `features/draw/presentation/pages/` 다. 아래 실제 경로 기준.

### A. `mobile/lib/features/reading/presentation/pages/reading_list_page.dart`

| 라인 | 변경 |
|------|------|
| L7 | `import '../../domain/entities/spread_type.dart';` → `import '../../domain/entities/layout_type.dart';` |
| L18 | `SpreadType? _filterType;` → `LayoutType? _filterType;` |
| L24 | `watchReadingsBySpreadTypeProvider(_filterType!)` 호출은 **그대로 유지**. provider signature 가 Cycle 1 에서 이미 `LayoutType` 수용하도록 갱신됐으므로 로컬 타입만 교체되면 자동 정상 (확인 근거: `reading_providers.dart:24-30` 에서 `LayoutType spreadType` 인자 선언). |
| L42 | `for (final type in SpreadType.values)` → `for (final type in LayoutType.values)` |
| L76 | `'${_filterType!.displayName} 리딩이 없습니다.'` — `.displayName` getter 는 LayoutType 에 존재 (Cycle 1), 그대로 유지 |
| L171 | `_spreadTypeIcon(reading.spreadType)` — `reading.spreadType` 필드 타입은 이미 LayoutType (Cycle 1 freezed 갱신됨), 호출 그대로 유지. **함수명 `_spreadTypeIcon` 유지** (문서화 테스트 033 이 함수명을 assert 하지 않으므로 rename 불필요. 단, 필요 시 `_layoutTypeIcon` rename 허용) |
| L182 | `reading.spreadType.displayName` — LayoutType 의 `displayName` 호출 그대로 유지 |
| L210-215 | `IconData _spreadTypeIcon(SpreadType type)` → `IconData _spreadTypeIcon(LayoutType type)`. switch branches 전면 교체: <br> - `SpreadType.single => Icons.looks_one` → `LayoutType.linear => Icons.view_stream` <br> - `SpreadType.threeCard => Icons.looks_3` → `LayoutType.tShape => Icons.view_quilt` <br> - `SpreadType.custom => Icons.grid_view` → `LayoutType.grid3x3 => Icons.grid_view` <br> (Brief 011 Ideal Criteria #13 + TDD-Red 033 계약) |

**Provider Naming Decision (R1 해소)**: **Option A — provider 이름 유지**.
근거: `reading_providers.dart:23-30` 은 이미 `watchReadingsBySpreadType(ref, LayoutType spreadType)` 로 Cycle 1 에서 갱신됐다. DB 컬럼명 `spread_type` 유지 (Brief Decision 20) 와 정합. Codegen 재실행 불필요.

### B. `mobile/lib/features/draw/presentation/pages/draw_result_page.dart`

| 라인 | 변경 |
|------|------|
| L8 | `import '../../../reading/domain/entities/spread_type.dart';` → `import '../../../reading/domain/entities/layout_type.dart';` |
| L29 | `late SpreadType _spreadType;` → `late LayoutType _layoutType;` (필드명도 rename; 본 파일 내 참조 5곳 동시 갱신) |
| L53 | `settings?.defaultSpreadType ?? SpreadType.custom` → `settings?.defaultLayoutType ?? LayoutType.linear`. **중요**: `defaultSpreadType` 필드명은 Cycle 2 에서 `defaultLayoutType` 으로 rename 됨. fallback 값은 `linear` (Brief Decision 18). |
| L54-56 | `_spreadType == SpreadType.custom ? settings?.defaultCardCount ?? 3 : _spreadType.cardCount` → `settings?.defaultCardCount ?? _layoutType.defaultCardCount`. **핵심**: LayoutType 에는 `cardCount` getter 없음 (Scope 017 §사이클 6 Note). 대신 `defaultCardCount` 사용하거나 userSettings 의 cardCount 우선. |
| L123 | `spreadType: _spreadType` (Reading 엔티티 필드명 유지) → `spreadType: _layoutType`. Reading.spreadType 필드 타입은 LayoutType (Cycle 1 갱신). |
| L133-146 | **`_addOneMore` 메서드 전면 삭제** (Brief 011 Decision 9, Scope 017 §사이클 6) |
| L176 | `final hasMoreCards = _currentCardCount < _shuffleResult!.cards.length;` — 로컬 변수 사용처(L271) 삭제로 인해 이 변수도 삭제 |
| L180 | `'${_spreadType.displayName} \u2014 즉시'` → `'${_layoutType.displayName} \u2014 즉시'` |
| L229-230 | `SpreadLayout(spreadType: _spreadType, ...)` → `SpreadLayout(layoutType: _layoutType, ...)`. 파라미터명 `spreadType` → `layoutType` 변경 (Cycle 4 에서 `spread_layout.dart` 가 `layoutType` 파라미터로 재작성됨). |
| L269-276 | **"+N장" 버튼 `Expanded` 블록 전면 삭제** (Brief 011 Decision 9). 남는 버튼은 "다시" + "홈" 2개 → `const SizedBox(width: 8)` 구분자 1개 유지, 다른 1개 삭제. |

**Note on `_currentCardCount`**: `_addOneMore` 삭제로 이 필드는 `initState` 이후 불변. `late int _currentCardCount` → `late final int _currentCardCount` 로 승격 가능 (선택적 정돈).

### C. `mobile/lib/features/draw/presentation/pages/animated_draw_page.dart`

| 라인 | 변경 |
|------|------|
| L10 | `import '../../../reading/domain/entities/spread_type.dart';` → `import '../../../reading/domain/entities/layout_type.dart';` |
| L29 | `late SpreadType _spreadType;` → `late LayoutType _layoutType;` (필드 rename + 본 파일 내 참조 3곳 동시 갱신) |
| L53 | `settings?.defaultSpreadType ?? SpreadType.custom` → `settings?.defaultLayoutType ?? LayoutType.linear` |
| L54-56 | `_spreadType == SpreadType.custom ? settings?.defaultCardCount ?? 3 : _spreadType.cardCount` → `settings?.defaultCardCount ?? _layoutType.defaultCardCount`. 동일한 `.cardCount` getter 부재 이슈 (B와 동일 해법). |
| L241 | `'${_spreadType.displayName} \u2014 연출'` → `'${_layoutType.displayName} \u2014 연출'` |

### D. `mobile/lib/features/reading/presentation/pages/reading_detail_page.dart`

| 라인 | 변경 |
|------|------|
| L76 | `reading.spreadType.resolvePositions(reading.drawnCards.length)` — **변경 불필요**. `reading.spreadType` 필드 타입이 이미 LayoutType (Cycle 1 freezed 갱신), `resolvePositions` 메서드도 Cycle 1 에서 추가됨 (layout_type.dart). 호출 그대로. |
| L82 | `reading.spreadType.displayName` — 변경 불필요 (LayoutType 에 `displayName` 존재) |

**Verify**: 이 파일은 **수정 0 라인**. `flutter analyze` 결과 경고가 없는지 확인만 하면 된다. Scope 017 Modified 리스트에 포함됐으나 실질 수정은 없음 — 이는 Cycle 1 freezed 재생성이 Reading 엔티티의 `spreadType` 필드를 LayoutType 으로 전환했기 때문에 호환 자동 보장.

## 3. Build + Test plan

```bash
cd mobile && flutter analyze
cd mobile && flutter test
cd mobile && flutter build apk --debug
```

기대치:
- `flutter analyze` 경고 0 (Cycle 4/5 에서 deferred 된 reading_list/detail/draw_result/animated_draw 의 undefined_class/undefined_identifier 전면 해소)
- `flutter test` 53 tests pass (Cycle 1~5 축적 + TDD-Red 033 의 신규 1 추가분. 033 의 icon mapping test 는 documentation-contract 성격)
- `flutter build apk --debug` APK 생성 성공

회귀 경계: TDD-Red 033 의 "기존 52 테스트 어느 하나도 깨지지 않는다" 계약 엄수.
특히 `draw_result_page_test.dart` (3 tests), `draw_result_page_initstate_test.dart`
(3 tests) 가 "+N장" 버튼 또는 `_addOneMore` 를 참조하지 않는지 impl 이 사전
grep 확인 — 만약 참조 시 테스트 업데이트 포함 (현 grep 결과 test/ 하위 0건
참조, 안전).

## 4. ADB 스크린샷 5종 (Brief Constraints § 시각 검증 + Ideal Criteria #15)

Plan 은 목록만 정의, impl 이 실행. CLAUDE.md Flutter workflow 기준:

```bash
# 전제: 에뮬레이터 실행 중 + adb devices 확인
$ANDROID_HOME/platform-tools/adb devices

# 각 스크린샷:
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SAVE_PATH="/Users/kampikrein/A/personality/mobile/tmp/screenshots/cycle6_${LABEL}_${TIMESTAMP}.png"
mkdir -p "$(dirname $SAVE_PATH)"
$ANDROID_HOME/platform-tools/adb exec-out screencap -p > "$SAVE_PATH"
```

**5종 리스트** (Brief 011 Constraints, Scope 017 §사이클 6 Verify):

| # | LABEL | 시나리오 | 검증 항목 |
|---|-------|---------|-----------|
| 1 | `shape_group_grid` | 홈 뽑기 패널에서 "모양" 그룹의 배치 선택 → grid3x3 클릭 → 4행 표시 (배치/카드 수/한 줄 카드 수/드로우 순서) | Cycle 5 T4 시각 검증 (fallback) |
| 2 | `tshape_4cards` | 설정 tShape + 4장 뽑기 → 결과 페이지 | 빈 슬롯 placeholder 가 slot 3, 5 에 표시 (dashed rect, `0x556B5B95`) |
| 3 | `tshape_7cards` | 설정 tShape + 7장 뽑기 → 결과 페이지 | +N 자투리(slot 7~) 가 좌→우 순서로 linear 배치 |
| 4 | `grid3x3_9cards` | 설정 grid3x3 + 9장 뽑기 → 결과 페이지 | 좌→우→중앙 의식적 매핑 (slot 0=좌상 … slot 8=중앙) |
| 5 | `slider_dynamic_snackbar` | 홈 패널에서 배치 전환 (linear 10장 → tShape 4장) | cardCount 슬라이더 min/max 동적 갱신 + cardsPerRow 회색 비활성 + **SnackBar "이전 값 복원" 노출** (Cycle 5 T2 시각 검증) |

**에뮬레이터 미실행 시 대응**: `adb devices` 결과가 "List of devices attached" 뒤
비어 있으면 impl agent 는 다음을 수행:
1. Plan 수행 가능한 모든 코드 변경 + 빌드 + analyze + test 완료
2. 스크린샷 단계는 `docs/2_tarot_draw/03_draw_experience_settings/035_Verify_cycle6_report.md` (verify agent 가 생성할 리포트) 내 "deferred to user-run" 로 기록
3. 사용자가 에뮬레이터 실행 후 `/flutter-dev screenshot` 스킬 수동 수집
4. 파이프라인은 계속 진행 (seq 24 impl 완료 처리)

이 fallback 은 Scope 017 의 auto_run=true + Brief Constraints 의 시각 검증
5종 요구를 동시에 만족. 에뮬레이터는 사용자 책임 (CLAUDE.md "에뮬레이터:
사용자가 Android Studio / AVD Manager 에서 별도 실행").

## 5. Risks

| ID | 내용 | 완화 |
|----|------|------|
| R1 | `watchReadingsBySpreadTypeProvider` 가 codegen (.g.dart) → 이름 변경 시 재생성 필요 | **해소**: provider 이름 유지 (Option A). Cycle 1 에서 signature 가 이미 LayoutType 수용하므로 로컬 타입 교체만으로 정상. |
| R2 | `draw_result_page._addOneMore` callsite 가 테스트에 존재 가능 | **검증 완료**: `grep _addOneMore test/` → 0건. 안전 삭제. |
| R3 | `SpreadType.cardCount` getter 호출 (draw_result L56, animated_draw L56) 를 `.cardCount` 로 교체 시 LayoutType 에 해당 getter 없음 | **해소**: `.defaultCardCount` 사용 또는 `settings?.defaultCardCount` fallback. Scope 017 §사이클 6 이 명시. |
| R4 | 에뮬레이터 미실행 중 impl 실행 | 섹션 4 의 "deferred to user-run" fallback 경로로 대응. 코드 커밋은 계속. |
| R5 | `reading_detail_page.dart` 는 Modified 리스트에 있으나 실질 수정 0 | Plan 에 명시 — `flutter analyze` 로 경고 0 확인만. |
| R6 | "+N장" 버튼 삭제 후 하단 버튼 바 레이아웃 (Row + Expanded × 3) 에서 Expanded 가 2개만 남으면 버튼이 너무 넓어질 수 있음 | impl 이 Expanded 유지 (2개로 나눠 갖는 Row) 또는 `mainAxisAlignment: spaceEvenly` 로 조정 판단. UI 미세 조정 범위, 스크린샷 2/3/4 에서 하단 버튼 바 확인. |

## 6. Verification plan

**Primary**:
1. `cd mobile && flutter analyze` — 경고 0 (프로젝트 전역)
2. `cd mobile && flutter test` — 53 tests green
3. `cd mobile && flutter build apk --debug` — APK 빌드 성공
4. ADB 스크린샷 5종 `mobile/tmp/screenshots/` 에 수집 (파일명 `cycle6_<LABEL>_<TIMESTAMP>.png`)

**Secondary** (verify agent 책임):
- 수동 smoke test: 전 배치 (linear / tShape / grid3x3) × 2~3 카드 수 × 뽑기 플로우 1회 — 크래시 없음, 빈 슬롯 정상 렌더, +N 자투리 정상
- reading_list 필터 칩 3종 모두 탭 가능 + 아이콘 매핑 정상 (view_stream / view_quilt / grid_view)

## 7. Cycle Boundary

본 cycle 이후 **추가 impl cycle 없음**. Tail chain 순서:
```
cycle 6 impl (본 plan) → verify (035 리포트) → eval (036) → qualify (037) → push (038) → retro (039)
```

## 8. Execution Summary for Impl Agent

Impl agent 는 다음 순서로 기계적으로 집행한다:
1. 파일 B (draw_result_page.dart) — 가장 많은 변경 (rename + 삭제). 먼저 수행해 cascading 오류 소거.
2. 파일 C (animated_draw_page.dart) — 유사 패턴, B 직후 수행.
3. 파일 A (reading_list_page.dart) — icon 매핑 교체.
4. 파일 D (reading_detail_page.dart) — 실질 수정 0, analyze 확인만.
5. `flutter analyze` — 경고 0 확인. 실패 시 순회.
6. `flutter test` — 53 tests 확인.
7. `flutter build apk --debug` — APK 생성 확인.
8. `adb devices` 체크 → 에뮬레이터 있으면 스크린샷 5종 캡처, 없으면 "deferred" 로그.
9. `~/.claude/scripts/pipeline.sh update 24 done <commit_sha> layout_redesign` (impl step 에서 처리).

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 56s | 217814 |
| 2 | user-ai-exchange | 47s | 59191 |
| 3 | user-ai-exchange | 64s | 65650 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 666s |
| Total Tokens | 342655 |
| Input Tokens | 22 |
| Output Tokens | 10056 |
| Cache Read | 270188 |
| Cache Creation | 62389 |
