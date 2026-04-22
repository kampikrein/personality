---
id: "017"
type: scope
title: "Scope — 배치(LayoutType) 재설계 6사이클 (안정성 분할판)"
created: 2026-04-20
status: completed
complexity: complex
research_needed: false
research_axes: []
research_cycles: 0
impl_cycles: 6
effort_mode: standard
tdd_mode: true
auto_run: true
orchestrator_active: true
supersedes: "006"
traces_brief: "011"
source_docs:
  critique: ["012", "013", "014", "015"]
  synthesis: "016"
  research: ["007", "008", "009", "010"]
summary: >
  Brief 011 (20 Decisions, 10 In Scope) 을 6 impl 사이클로 안정 집행. Scope
  006 의 3사이클 구조를 critique 016 U6 권고 + 컨텍스트 오버플로 회피 원칙
  (cycle-design.md §7) 에 따라 6사이클로 분할. Research phase 는 007~010
  에 이미 완료 → scope 는 impl phase 만 관장. 사이클별 ≤6 파일로 context
  부담 제한. tdd-red 선행, standard effort, --run auto_run.
keywords: [scope, layout, 6-cycles, context-safety, impl-only, tdd, standard-effort, brief-011]
---

# Scope — 배치(LayoutType) 재설계 6사이클 (안정성 분할판)

## Brief Reference

**Brief 011** (`docs/2_tarot_draw/03_draw_experience_settings/011_Brief_layout_redesign.md`,
status: completed, Decisions 20건, Critical Reviews 전부 해소, Ideal Criteria
17건, quality_profile: standard, deep_critique: true with 4 관점) 를 불변
정렬 앵커로 수용한다.

`/scope 011 --run` 호출 자체가 Brief 확정 + 사이클 분할 방침 + auto_run 동의
의사 표시.

**자동으로 승계되는 분석**:
- Research 3 axes (007/008/009) + Synthesis (010) — impl 사이클별 prototype
  코드 준비 완료
- Critique 4 관점 (012 Feasibility / 013 Scope Balance / 014 Risk / 015
  Alternatives) + Synthesis (016) — 22 반영 항목 Brief 011 에 통합

## Goal

Brief 011 의 In Scope 10개 항목을 **6 impl 사이클 + tail chain** 구조로 집행한다.
Scope 006 (이 문서가 supersede) 의 3사이클 구성을 critique 016 U6 권고에 따라
세분화 — cycle 크기 ≤6 파일을 목표로 에이전트 컨텍스트 오버플로 방지.

## Scope 006 대비 변경점

| 항목 | Scope 006 | Scope 017 (본 문서) |
|------|-----------|---------------------|
| Research phase | 3 사이클 + synthesis (예정) | **이미 완료 (007/008/009/010)** — skip |
| Impl phase | 3 사이클 (도메인 / DB / UI) | **6 사이클** (도메인 Reading / 도메인 Settings / DB / 렌더링 / 홈 패널 / 주변 호환) |
| 총 체크리스트 | 23 (research 6 + synthesis 1 + impl 12 + tail 4) | **28** (impl 24 + tail 4) |
| traces_brief | "005" | "011" |
| effort_mode | standard | standard |
| tdd_mode | true | true |
| auto_run | true | true |

## Why 6 Cycles (분할 근거)

**Scope 006 의 원 cycle 3 (UI 통합)** 은 파일 9 + 위젯 2 신규 + 테스트 1 +
스크린샷 5종 = ~14 항목으로 XL 사이클에 근접. 단일 impl agent 호출 시 컨텍스트
오버플로 위험 (cycle-design.md §7 경고 영역).

**분할 원칙**:
1. **원자성 보존**: build_runner 로 freezed/drift 재생성 경계에서만 분할.
   Reading 레이어 (cycle 1) 와 UserSettings 레이어 (cycle 2) 는 각자 build_runner
   한 번을 소유하여 중간 컴파일 오류 회피
2. **독립성 극대화**: 후속 사이클이 이전 사이클 결과물에 선형 의존하되, 각
   사이클 내부는 자기완결적
3. **사이클당 ≤6 파일 목표** (critique 016 U6 권고)
4. **tdd-red 선행**: 각 cycle 시작에서 실패 테스트 먼저 작성 (Brief
   Constraints § 테스트)

## Impl Phase (6 사이클)

### 사이클 1 — LayoutType enum + Reading 레이어 (도메인 기반)

**목표**: `SpreadType` → `LayoutType` rename + enhanced enum + computed
properties 8개 + Reading 엔티티/리포지토리/DAO/프로바이더 타입 전환. 이 cycle
끝에서 Reading 레이어가 완전히 LayoutType 기준으로 컴파일.

**Modified**:
| 파일 | 변경 |
|------|------|
| `mobile/lib/features/reading/domain/entities/spread_type.dart` | `SpreadType` → `LayoutType` rename. enhanced enum 변환. 3 values (`linear`, `tShape`, `grid3x3`). final: `cardCountMin/Max`, `defaultCardCount`, `cardsPerRowOverride`, `displayName`. 메서드: `slotCount(int)`, `emptySlots(int)`, `drawToSlot(int, int)`, **`resolvePositions(int)`** (generic `'카드 N'` 라벨, Brief Decision 8), **`resolveGuidances(int)`** (빈 리스트 또는 placeholder, OoS #4) |
| `mobile/lib/features/reading/domain/entities/reading.dart` | `SpreadType` 필드 타입 → `LayoutType`. **필드명 `spreadType` 유지** (Brief Decision 20 — 비대칭 공식화) |
| `mobile/lib/features/reading/domain/repositories/reading_repository.dart` | interface 의 `SpreadType` → `LayoutType` |
| `mobile/lib/features/reading/data/repositories/reading_repository_impl.dart` | 직렬화: `.name` 유지. **역직렬화**: `SpreadType.values.byName(row.spreadType)` → `LayoutType.values.firstWhere((e) => e.name == row.spreadType, orElse: () => LayoutType.linear)` (Brief Decision 18) |
| `mobile/lib/core/database/daos/reading_dao.dart` | 파라미터 타입 `SpreadType` → `LayoutType`. `spreadType` 이름 유지 (DB 컬럼명과 일치) |
| `mobile/lib/features/reading/presentation/providers/reading_providers.dart` | 필터 프로바이더 타입 교체 |

**Reviewed**:
| 파일 | 확인 |
|------|------|
| `mobile/lib/features/reading/domain/entities/reading.freezed.dart` | build_runner 재생성 후 `LayoutType` 반영 |
| `mobile/lib/features/reading/domain/entities/reading.g.dart:33-37` | `_$LayoutTypeEnumMap` 자동 생성 (confirmation gate — Brief Constraints) |

**TDD-red 목표** (`mobile/test/features/reading/domain/entities/layout_type_mapping_test.dart` 신규):
- `LayoutType.linear.cardCountMin == 1`, `.cardCountMax == 10` 등 매트릭스 값
- `LayoutType.tShape.drawToSlot(3, 4) == 4`, `.emptySlots(4) == {3, 5}`
- `LayoutType.grid3x3.drawToSlot(0, 9) == 6` (좌 기둥 하단)
- `.resolvePositions(cardCount)` 길이 = cardCount, `'카드 N'` 패턴
- 실패 상태로 커밋 (green 은 impl 단계에서)

**Verify**:
- `cd mobile && dart run build_runner build --delete-conflicting-outputs` 성공
- `reading.g.dart` 에서 `_$LayoutTypeEnumMap` grep 확인
- `flutter analyze` 경고 0
- `dart test test/features/reading/domain/entities/layout_type_mapping_test.dart` 통과
- 기존 reading 관련 테스트 회귀 없음

**파일 수**: Modified 6 / Reviewed 2 / Test 1 신규 — **confidence: high**

---

### 사이클 2 — UserSettings 레이어 + 필드 rename + Repository fallback

**목표**: UserSettings 도메인 (엔티티 + repo + 프로바이더 + freezed .g.dart
에 중복된 `_$SpreadTypeEnumMap`) 을 LayoutType 으로 전환. **Dart 필드 + DB
컬럼명 모두 rename** (Brief Decision 6).

**Modified**:
| 파일 | 변경 |
|------|------|
| `mobile/lib/features/settings/domain/entities/user_settings.dart:19` | `defaultSpreadType` 필드 → `defaultLayoutType`, 타입 `LayoutType` |
| `mobile/lib/features/settings/data/repositories/user_settings_repository_impl.dart:113` | `SpreadType.values.byName(...)` → `LayoutType.values.firstWhere(..., orElse: LayoutType.linear)` (Decision 18) + 필드명 rename 전파 |
| `mobile/lib/features/settings/presentation/providers/settings_providers.dart` | `updateDefaultSpreadType` → `updateDefaultLayoutType` |

**Reviewed**:
| 파일 | 확인 |
|------|------|
| `mobile/lib/features/settings/domain/entities/user_settings.g.dart:16-18, 49-53` | **두 번째 `_$SpreadTypeEnumMap` 복제본** → build_runner 재생성 후 `_$LayoutTypeEnumMap` 로 갱신 확인 (012 Critique C1) |
| `mobile/lib/features/settings/domain/entities/user_settings.freezed.dart` | build_runner 후 타입 갱신 확인 |

**TDD-red 목표** (UserSettings repository 단위 테스트 내 inline 추가 또는 신규 파일):
- Repository 의 legacy 값 처리: `row.defaultSpreadType == 'threeCard'` 일 때 `LayoutType.linear` 반환 (fallback)
- ArgumentError 발생하지 않음 검증 (Brief Ideal Criteria #5b)

**Verify**:
- build_runner 성공 + `user_settings.g.dart` 의 EnumMap 갱신 grep
- `flutter analyze`
- Settings 관련 기존 테스트 회귀 없음

**파일 수**: Modified 3 / Reviewed 2 / Test 추가 — **confidence: high**

**Note on DB 컬럼명 rename**: 실제 DB `ALTER TABLE user_settings RENAME COLUMN
default_spread_type TO default_layout_type` 은 cycle 3 (DB 마이그레이션) 에서
수행. 이 시점까지는 `user_settings_table.dart` 의 Dart 필드명이 `defaultSpreadType`
또는 `defaultLayoutType` 중 어느 것이든 Drift codegen 이 column name 매핑을
통해 SQL 컬럼명을 결정하므로, **cycle 2 에서는 Drift 테이블 정의 파일은 손대지
않고 엔티티/리포지토리/프로바이더만 교체**. Drift 테이블 변경은 cycle 3 에서
일괄 처리하여 원자적 마이그레이션 보장.

---

### 사이클 3 — DB 마이그레이션 (v7 → v8)

**목표**: Brief Decision 5/16/19 의 마이그레이션 블록 + test case 4 건 (값 변환
/ 컬럼 rename / idempotency / **phantom v7.5 crash recovery**) 구현.

**Modified**:
| 파일 | 변경 |
|------|------|
| `mobile/lib/core/database/app_database.dart:25, 28-70` | `schemaVersion 7 → 8`. `onUpgrade` 에 `if (from < 8) { ... }` 블록 추가. 트랜잭션 내부 `PRAGMA user_version = 8` commit (014 Critique R1+R6). PRAGMA foreign_keys OFF/ON 토글. **onUpgrade 내부 DAO/Repository 호출 금지 — raw `m.database.customStatement()` 만** (Brief Decision 19) |
| `mobile/lib/core/database/tables/readings_table.dart` | TextColumn `spreadType` 의미 변경 주석 (값이 `linear`/`tShape`/`grid3x3`). 컬럼명 유지 |
| `mobile/lib/core/database/tables/user_settings_table.dart:15` | `defaultSpreadType` → `defaultLayoutType` TextColumn. column name 매핑 `@Default` 갱신 |

**New**:
| 파일 | 변경 |
|------|------|
| `mobile/test/database/migration_v7_to_v8_test.dart` | SchemaVerifier 기반 **4 케이스**: (1) readings.spread_type 값 변환, (2) user_settings 컬럼 rename + 값 변환, (3) idempotency, (4) **phantom v7.5 crash recovery** — 스키마=v8 + user_version=7 수동 시뮬레이션 → 재오픈 → 정상 동작 검증 |

**Reviewed**:
| 파일 | 확인 |
|------|------|
| `mobile/drift_schemas/drift_schema_v7.json` | **이미 commit `5a62332` 에 커밋됨** — 재생성 불필요 (012/013 Critique C3) |
| `mobile/test/generated_migrations/schema_v7.dart` + `schema.dart` | **이미 존재** — 그대로 사용 |
| `mobile/lib/core/database/*.g.dart` | build_runner 재생성 확인 (schema 갱신) |

**TDD-red 목표**:
- Case 4 (phantom) 가 **가장 중요** — Brief CR 해소의 핵심. 기존 구현이
  해당 시나리오를 처리하지 못해 실패해야 함 (tdd-red 의 목적)
- Case 1~3 도 실패 상태로 선작성

**Verify**:
- `dart test test/database/migration_v7_to_v8_test.dart` 4 케이스 모두 통과
- `flutter analyze`
- 개발자 로컬 DB 에서 수동 실행 검증 (개발자 DB v7 상태 → 앱 실행 → v8 전환 정상)
- 기존 settings 테스트 회귀 없음

**파일 수**: Modified 3 / New 1 (테스트) / Reviewed 3 — **confidence: medium**
(crash recovery 테스트의 fixture 구성이 새 패턴, impl 중 세부 조정 가능)

---

### 사이클 4 — 결과 페이지 렌더링 인프라 (GridView + CustomPaint)

**목표**: Brief Decision 14/15 의 GridView 기반 단일 렌더링 인프라 + 빈 슬롯
placeholder. `spread_layout.dart` 전면 재작성.

**Modified**:
| 파일 | 변경 |
|------|------|
| `mobile/lib/features/reading/presentation/widgets/spread_layout.dart` (현 107 lines) | 전면 재작성. `GridView.builder` + `SliverGridDelegateWithFixedCrossAxisCount` 단일 인프라. builder 시작 시 역매핑 `slotToDraw` 한 번 계산. `itemBuilder` 3-branch (emptySlot / linear 자투리 shrink / CardRevealWidget). `key: ValueKey(layoutType)` 로 배치 전환 시 위젯 트리 재생성 (R-009-F6). `CardRevealWidget` 은 `ValueKey('card-$drawIdx')` |

**New**:
| 파일 | 변경 |
|------|------|
| `mobile/lib/features/reading/presentation/widgets/_empty_slot_placeholder.dart` (또는 spread_layout.dart 내부 private 클래스) | `_EmptySlotPlaceholder` + `_DashedRectPainter` (~30 줄). `AspectRatio` + CustomPaint. Color `0x556B5B95` (kSoftPurple alpha 0.33), dashWidth=6, dashGap=4, strokeWidth=1, cornerRadius=4. `Path.computeMetrics` + `extractPath` 대시 반복 |

**Reviewed**:
| 파일 | 확인 |
|------|------|
| `mobile/lib/features/reading/presentation/widgets/card_reveal_widget.dart` (206 lines) | 부모 비종속 + AspectRatio 내부 적용 확인 (R-009-F6). 변경 없음 |
| `mobile/lib/core/widgets/mystical_scaffold.dart` | 디자인 토큰 (kSoftPurple) 재확인 |

**TDD-red 목표**: widget 테스트 (선택) — `spread_layout_test.dart` 가 이미
있으면 확장, 없으면 cycle 4 skip (단위 테스트는 cycle 1 에서 LayoutType
매핑으로 커버됨). UI 회귀는 cycle 6 ADB 스크린샷으로 검증.

**Verify**:
- `flutter analyze` 경고 0
- `flutter test test/features/reading/presentation/widgets/` (있다면) 통과
- 빌드 성공: `flutter build apk --debug`
- 중간 스크린샷 1종: tShape 4 장 결과 페이지 (빈 슬롯 2 visible)

**파일 수**: Modified 1 / New 1 / Reviewed 2 — **confidence: medium**
(spread_layout 전면 재작성의 edge case 파악 필요)

---

### 사이클 5 — 홈 패널 "모양" 그룹 + 동적 슬라이더 + SnackBar undo

**목표**: Brief In Scope #4/#5/#8 + Decision 4 (SnackBar undo) + Decision 9
일부 (`shuffleStateProvider.clear()` 경로) + 3x3 드로우 순서 메뉴.

**Modified**:
| 파일 | 변경 |
|------|------|
| `mobile/lib/features/home/presentation/pages/home_page.dart:447, 456-464` | `_DrawSettingsPanel` 3-group 재구성: (a) 기본 설정 3행 (덱·레벨·역방향), (b) **모양** 3~4행 (배치·카드 수·한 줄 카드 수·grid3x3 시 드로우 순서), (c) 표시 옵션 3행. `_PillSelector<SpreadType>` → `_PillSelector<LayoutType>` 교체 (Brief Decision 2/3). cardCount 슬라이더 min/max 를 선택된 LayoutType 에 동적 바인딩. cardsPerRow 슬라이더는 tShape/grid3x3 시 회색 비활성 + 값 3 고정. **배치 변경 시 SnackBar `"이전 값 복원"` 액션 10초 노출** (Brief Decision 4). **슬라이더 onChange 에서 `shuffleStateProvider.clear()` 호출** (014 R4). grid3x3 선택 시에만 "드로우 순서" 행 조건 렌더 ("기본" 활성 + "다른 순서 (준비 중)" 비활성) |

**New**:
| 파일 | 변경 |
|------|------|
| `mobile/test/features/home/card_count_auto_adjust_test.dart` | (a) 배치 전환 시 cardCount min/max 갱신, (b) 범위 밖 값 `defaultCardCount` 리셋, (c) cardsPerRow 강제값 3 + 비활성 상태 렌더, (d) SnackBar undo 액션 표시 + 탭 시 이전 상태 복원, (e) shuffleStateProvider.clear() 호출 검증 |

**Reviewed**:
| 파일 | 확인 |
|------|------|
| `mobile/lib/features/home/presentation/widgets/_PanelSubheader.dart` + `_GoldSwitch.dart` + `_PillSelector.dart` (002~004 사이클 산출물) | 재사용 확인, 변경 없음 |

**TDD-red 목표**: 5 테스트 케이스 선작성, 실패 커밋.

**Verify**:
- `dart test test/features/home/card_count_auto_adjust_test.dart` 통과
- `flutter analyze`
- 중간 스크린샷 2종: 모양 그룹 UI (grid3x3 선택 시 4행), 배치 변경 시 슬라이더 동적 조정 + 비활성

**파일 수**: Modified 1 / New 1 / Reviewed 3 — **confidence: medium**
(SnackBar undo state 관리 경로 설계 유연성 필요)

---

### 사이클 6 — 주변 호환 + 버튼 제거 + 시각 검증

**목표**: 목록/상세 페이지 호환 + draw_result/animated_draw 타입 전환 및 버튼
제거 + Brief Constraints § 시각 검증 5종 완료.

**Modified**:
| 파일 | 변경 |
|------|------|
| `mobile/lib/features/reading/presentation/pages/reading_list_page.dart` | 필터 칩 `SpreadType` → `LayoutType`. `_spreadTypeIcon` 매핑: linear=view_stream / tShape=view_quilt / grid3x3=grid_view |
| `mobile/lib/features/reading/presentation/pages/reading_detail_page.dart:76` | `layoutType.resolvePositions(cardCount)` 호환 확인 (cycle 1 에서 메서드 추가됨) |
| `mobile/lib/features/reading/presentation/pages/draw_result_page.dart:29, 53-56, 133-146, 269-276` | `late SpreadType _spreadType` → `LayoutType`. `_spreadType.cardCount` → `_drawnCards.length` (LayoutType API 에 cardCount getter 없음, 012 Critique 반영). **`_addOneMore` 메서드 전면 삭제**. **"+N장" 버튼 위젯 삭제** (Brief Decision 9) |
| `mobile/lib/features/reading/presentation/pages/animated_draw_page.dart:29, 53-54` | `late SpreadType` → `LayoutType`. `.cardCount` 호출을 `drawnCards.length` 로 교체 |

**Reviewed**:
| 파일 | 확인 |
|------|------|
| `mobile/lib/features/shuffle/...` | `shuffleStateProvider.clear()` 호출 경로 동작 확인. cardCount 변경이 셔플에 올바르게 전파되는지 grep + 수동 확인 |

**TDD-red 목표**: 이전 cycle 에서 확보된 테스트 회귀 확인만. 신규 테스트
불필요 (UI 통합 검증은 ADB 스크린샷).

**Verify**:
- **ADB 스크린샷 5종 (Brief Constraints § 시각 검증)** 전부 캡처:
  1. 모양 그룹 UI (grid3x3 선택 시 4행)
  2. tShape 결과 페이지 4장 (빈 슬롯 placeholder slot 3, 5)
  3. tShape 결과 페이지 +N (예: 7장, 자리 7+ 좌→우)
  4. grid3x3 결과 페이지 9장 (좌→우→중앙 의식적 매핑)
  5. 배치 변경 시 cardCount 슬라이더 동적 min/max + cardsPerRow 회색 비활성 + **SnackBar undo 액션 노출**
- `flutter analyze`
- 전체 `flutter test`
- `flutter build apk --debug`
- 개발자 수동 smoke test: 전 배치 × 뽑기 플로우 1회씩

**파일 수**: Modified 4 / Reviewed 1 — **confidence: medium**
(draw_result 의 `.cardCount` 호출 교체는 로직 문맥 파악 필요)

---

## Dependencies & Execution Order

```
Research Phase (007/008/009/010): ✅ 완료

Impl Phase (6 cycles):

Cycle 1 (LayoutType enum + Reading 레이어)
     ↓ (build_runner 1회)
Cycle 2 (UserSettings 레이어 + Repository fallback)
     ↓ (build_runner 2회차 — user_settings.g.dart 갱신)
Cycle 3 (DB 마이그레이션 v7→v8)
     ↓ (마이그레이션 테스트 통과 확인)
Cycle 4 (렌더링 인프라 — GridView + CustomPaint)
     ↓ (LayoutType.drawToSlot 호출 검증)
Cycle 5 (홈 패널 UI + SnackBar undo)
     ↓ (UI 동작 검증)
Cycle 6 (주변 호환 + 버튼 제거 + 스크린샷 5종)
     ↓
[tail] eval → qualify → push → retro
```

**사이클 간 의존**:
- Cycle 2 → Cycle 1: LayoutType enum 필요 (타입 참조)
- Cycle 3 → Cycle 1+2: Dart 타입이 LayoutType 상태여야 AppDatabase codegen 일치
- Cycle 4 → Cycle 1: LayoutType 의 `drawToSlot`/`emptySlots`/`slotCount`/`resolvePositions` 호출
- Cycle 5 → Cycle 1: `_PillSelector<LayoutType>` + computed properties
- Cycle 6 → Cycle 1~5: 전반 통합 + 시각 검증

순차 실행 필수. 병렬 불가 (선형 의존).

## Total Surface

- **총 변경 파일** (Modified): ~18 (cycle 1: 6, cycle 2: 3, cycle 3: 3, cycle 4: 1, cycle 5: 1, cycle 6: 4)
- **Reviewed**: ~11
- **신규 테스트 파일**: 3 (layout_type_mapping, migration_v7_to_v8, card_count_auto_adjust) + Repository fallback inline 테스트
- **신규 위젯 파일**: 1 (`_empty_slot_placeholder.dart` 또는 spread_layout.dart 내부)
- **build_runner 실행**: 2회 (cycle 1 + cycle 2) — cycle 3 은 DB 스키마만이라 자동 포함
- **ADB 스크린샷**: 5종 (cycle 6 에서 일괄 수집) + 중간 3종 (cycle 4/5 검증용)
- **confidence 종합**:
  - high: cycle 1, 2 (rename + typing 기계적)
  - medium: cycle 3, 4, 5, 6 (각각 crash recovery / 전면 재작성 / state 관리 / 시각 검증 세부 조정 여지)

## Out of Scope (Brief 011 Out of Scope 11 항목 승계 + 추가)

Brief 011 Out of Scope 11개 그대로 승계. 추가:

1. **Scope 006 이 있던 traces_brief 경로 정정 (stale: `docs/15_draw_experience_settings/`)** — 006 이
   supersede 되므로 본 cycle 은 006 무시, 017 만 활성
2. **T모양 5~10장의 슬롯 배치 시각 검증** — impl 사이클 4/6 에서 스크린샷
   (research 없이 코드 작성 후 확인)
3. **Animation 마이크로 인터랙션** (배치 전환 트랜지션) — standard 프로필 범위 외
4. **sealed class 재평가 실험** — Brief Decision 13 의 alternative. post-v1
   cycle 으로 연기
5. **`drift_dev schema dump` 재실행** — 014 Risk R5 에 따라 이번 cycle 에서는
   기존 v7 snapshot 그대로 사용, 재 dump 금지

## Verification Plan (Standard Profile)

- **빌드**: `cd mobile && flutter build apk --debug` (각 cycle verify 단계)
- **정적 분석**: `flutter analyze` 경고 0 (모든 cycle)
- **단위 테스트**: `dart test` (3 테스트 파일)
- **마이그레이션 테스트**: `dart test test/database/migration_v7_to_v8_test.dart` 4 케이스 (cycle 3)
- **ADB 스크린샷**: 5종 (cycle 6) + 중간 3종 (cycle 4/5)
- **수동 smoke test**: cycle 6 완료 후 전 배치 × 카드 수 × 드로우 순서 매트릭스

## Pipeline Meta

- complexity: **complex**
- effort_mode: **standard** (eval + qualify + push + retro tail)
- tdd_mode: **true** (모든 impl 사이클 tdd-red 선행 — cycle 4 는 widget 테스트 선택, cycle 6 은 회귀만)
- research_needed: **false** (007~010 완료)
- research_cycles: 0
- impl_cycles: **6**
- auto_run: **true**
- orchestrator_active: **true**
- 총 체크리스트 아이템: impl 24 (6 cycles × 4 [tdd-red + makeplan + impl + verify]) + tail 4 (eval + qualify + push + retro) = **28**

## Context Overflow 대응

각 cycle 의 impl agent 호출 시, 다음 원칙을 makeplan agent 에 전달:
1. **이 cycle 범위 파일만** Modified 리스트 참조 — 타 cycle 파일 건드리지 말 것
2. **Brief 011 + 이 cycle 의 Plan 문서** 만 로드 — 007~010 Research, 012~016
   Critique 은 이미 Brief 에 녹아있으므로 원본 로드 불필요
3. **정적 prototype 코드** (007 LayoutType enum 초안, 008 migration block, 009
   _DashedRectPainter) 를 Plan 문서가 사이클별로 발췌하여 전달

이 3원칙이 agent 컨텍스트를 사이클당 ~50K 토큰 이하로 제한 (Brief 011 ~25K
+ Plan ~10K + 코드 참조 ~15K).

---

## Session Log (auto-appended)
