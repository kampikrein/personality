---
id: "011"
type: brief
title: "배치(LayoutType) 재설계 통합 브리프 — Research Synthesis 반영"
created: 2026-04-20
status: completed
quality_profile: standard
deep_critique: true
critique_docs: ["007", "008", "009", "010", "012", "013", "014", "015", "016"]
supersedes: "005"
traces_scope: "006"
summary: >
  005 Brief의 In Scope 9개 항목(LayoutType 도입, 3배치, 슬롯·드로우 매핑, DB
  마이그레이션, 홈 "모양" 그룹, 결과 페이지 슬롯 렌더링) 을 유지하되, Research
  3 axes (007 enum codegen / 008 drift migration / 009 slot rendering) + 010
  Synthesis + 012~016 Deep Critique 4 관점의 확정 결과를 반영한다. 주요 변경:
  schemaVersion v7→v8 정정, enhanced enum fallback 제거, GridView+CustomPaint
  렌더링 확정, 명시적 트랜잭션·SchemaVerifier·drift 스키마 스냅샷 패턴 도입,
  PRAGMA user_version 트랜잭션 내부 commit, byName ArgumentError 방어,
  UserSettings/draw pages 계단 rename 반영, Snackbar undo. Critical Review
  3건 + Critique 공통 발견 6건(P0~P1) 전부 반영. 20 Decisions / 10 In Scope /
  11 Out of Scope / Standard 프로필 Ideal Criteria 17건.
keywords: [layout, spread, domain, slot, draw-order, ia, mobile, draw, migration, v7-v8, enhanced-enum, gridview, synthesis]
---

# 배치(LayoutType) 재설계 통합 브리프 — Research Synthesis 반영

## Intent

현재 홈 패널의 "스프레드"(1장/3장/자유) 와 "카드 수"(1~10) 가 같은 차원("몇 장
뽑을지")을 통제하면서 의미적으로 충돌한다. 사용자가 "스프레드: 3장 + 카드 수:
5" 같은 비정합 조합을 만들 수 있고, 코드에서는 어느 한쪽이 강제하거나 무시된다.

충돌의 근본 원인은 **"스프레드"라는 용어가 본래 의미인 "카드의 배치 모양"을 잃고
"수량 묶음"이 되어 카드 수와 차원 중첩이 일어났기 때문**이다.

해결: 용어를 "**배치**"로 교체하고 의미를 본래의 "배치 모양" 차원으로 좁힌다.
배치 종류 3가지(나열 / T모양 / 3x3) 를 정의하되 단순 enum이 아니라 다음 도메인
개념을 함께 가지는 **풍부한 모델**로 만든다:

| 새 도메인 개념 | 의미 |
|--------------|------|
| 슬롯(slot) | 그리드 상의 카드 자리 (T모양: 6 슬롯, 3x3: 9 슬롯, 추가 시 하단 확장) |
| 빈 슬롯(empty slot) | T모양 기본 4장 시 자리 4·6은 영구 빈칸 (visible placeholder) |
| 드로우 순서 → 슬롯 매핑 | "n번째 뽑힌 카드를 어느 슬롯에 놓을지" 함수. 배치 종류별로 다름 |
| cardCount min/max | 배치별로 동적 (linear 1~10, tShape 4~10, grid3x3 9~10) |
| 한 줄 카드 수 강제 | T모양·3x3은 cardsPerRow=3 고정 |

배치가 선행 선택이 되어 카드 수와 한 줄 카드 수의 가능 범위·매핑을 결정하는
단방향 의존 관계로 정리한다. grid3x3에는 "드로우 순서" 설정 자리만 마련하되
다른 순서 옵션은 미구현 보류한다.

## Context

### 현재 구조의 충돌 지점

| 설정 | 통제 차원 | 충돌 |
|------|----------|------|
| 카드 수 (1~10 스텝퍼) | 수량 | ↔ 스프레드 |
| 스프레드 (single/threeCard/custom) | 수량 + 위치 의미 | ↔ 카드 수 |
| 한 줄 카드 수 (1/2/3) | 표시 그리드 분할 | 스프레드 종류와 무관하게 항상 활성 |

`SpreadType.single.cardCount = 1`, `SpreadType.threeCard.cardCount = 3` 인데
별도 `defaultCardCount` 슬라이더가 1~10 임. 충돌 시 어느 것이 우선인지 코드에
명시 없음.

### SpreadType 참조 분포 (코드베이스 grep 결과 — 012 Critique 반영 완전판)

| 레이어 | 파일 | 역할 |
|--------|------|------|
| 도메인 모델 | `mobile/lib/features/reading/domain/entities/spread_type.dart` | enum 정의 + `positions` final 필드 + `resolvePositions/resolveGuidances` 메서드 → `LayoutType` 풍부 모델로 진화 |
| DB 스키마 | `mobile/lib/core/database/tables/readings_table.dart` | `spreadType` TextColumn (컬럼명 유지, 값만 변환) |
| DB 스키마 | `mobile/lib/core/database/tables/user_settings_table.dart` | `defaultSpreadType` TextColumn → `defaultLayoutType` rename. `cardsPerRow` nullable IntColumn (Decision 20) |
| DAO | `mobile/lib/core/database/daos/reading_dao.dart` | `watchReadingsBySpreadType` |
| Repository (reading) | `mobile/lib/features/reading/data/repositories/reading_repository_impl.dart:31, 98` | `.name` 직렬화 / `byName` 역직렬화 → **fallback 패턴 필수** (Decision 18) |
| Repository (settings) | `mobile/lib/features/settings/data/repositories/user_settings_repository_impl.dart:113` | `SpreadType.values.byName(...)` 동일 패턴 |
| Entity (freezed — reading) | `mobile/lib/features/reading/domain/entities/reading.dart` (+ .freezed.dart, .g.dart) | `spreadType` 필드. `reading.g.dart:33-37` 의 `_$SpreadTypeEnumMap` 자동 생성 |
| Entity (freezed — settings) | `mobile/lib/features/settings/domain/entities/user_settings.dart:19` (+ .g.dart:16-18, 49-53) | `defaultSpreadType` 필드 + **두 번째 `_$SpreadTypeEnumMap` 복제본** → build_runner가 통합 재생성 |
| Provider (reading) | `mobile/lib/features/reading/presentation/providers/reading_providers.dart` | 필터 프로바이더 |
| Provider (settings) | `mobile/lib/features/settings/presentation/providers/settings_providers.dart` | `updateDefaultSpreadType` → `updateDefaultLayoutType` |
| UI 결과 — 렌더링 | `mobile/lib/features/reading/presentation/widgets/spread_layout.dart` (107 lines) | switch 렌더링 → GridView + 슬롯 모델 기반 재작성 |
| UI 결과 — 페이지 | `mobile/lib/features/reading/presentation/pages/draw_result_page.dart:29, 53-56, 133-146, 269-276` | `late SpreadType _spreadType; _spreadType.cardCount` 호출 + `_addOneMore` 메서드 + "+N장" 버튼 → LayoutType 전환 + 버튼 삭제 (Decision 9) |
| UI 드로우 (애니메이션) | `mobile/lib/features/reading/presentation/pages/animated_draw_page.dart:29, 53-54` | `late SpreadType _spreadType; _spreadType.cardCount` 호출 → LayoutType 전환 필요 |
| UI 목록 | `mobile/lib/features/reading/presentation/pages/reading_list_page.dart` | 필터 칩, `_spreadTypeIcon` |
| UI 상세 | `mobile/lib/features/reading/presentation/pages/reading_detail_page.dart:76` | `layoutType.resolvePositions(cardCount)` 호출 호환 |
| UI 설정 | `mobile/lib/features/home/presentation/pages/home_page.dart:447, 456-464` | `_DrawSettingsPanel` 그룹 + `_PillSelector<SpreadType>` → `_PillSelector<LayoutType>` 교체 + 3-group 재구성 |

**새로 밝혀진 의존성** (012 Feasibility + 013 Scope Balance critique):
- `.cardCount` getter 호출이 draw_result/animated_draw 2 파일에 존재 — LayoutType API 설계에 `cardCount` getter가 없으므로, **호출부를 `cards.length` 직접 사용으로 교체** (Decision 19)
- `_$SpreadTypeEnumMap` 정적 맵이 reading.g.dart + user_settings.g.dart **두 곳에 복제** → build_runner 재실행이 둘 다 LayoutType 이름으로 갱신해야 함 (confirmation gate에 두 파일 grep 모두 포함)

→ 다중 모듈 변경 + DB 스키마 영향 + 도메인 모델 진화 + 새 결과 렌더링 → **complexity: complex**

### DB 현황 (R-008-F1 Brief 가정 정정 + 012/013 Critique 반영)

- `mobile/lib/core/database/app_database.dart:25` **`schemaVersion => 7`** (현재)
- 기존 6 사이클 (v1→v2 … v6→v7) 이 이미 `m.database.customStatement` 패턴으로
  정립됨
- **본 작업의 마이그레이션은 `v7 → v8`** (005 Brief의 "v1→v2" 표현은 오류)
- `mobile/pubspec.yaml`: `drift ^2.22.0`, `drift_dev ^2.22.0`, `freezed ^2.5.0`,
  `json_serializable ^6.8.0`, Dart `^3.6.0`, `sqlite3_flutter_libs ^0.5.0` (SQLite
  3.40+ 번들)
- **Schema 스냅샷 선행 커밋 완료** (commit `5a62332 feat: mobile/drift_schemas`):
  - `mobile/drift_schemas/drift_schema_v7.json` ✅
  - `mobile/test/generated_migrations/schema.dart` + `schema_v7.dart` ✅
  - Decision 17 의 "dump → generate" 단계 불필요. **잔여 작업은 migration 테스트
    작성 + `PRAGMA user_version` 안전성 검증만**
- **Drift의 schemaVersion 추적 메커니즘** (014 Critique R1+R6):
  `drift engines.dart:485-521` + `versioned_schema.dart:114` — onUpgrade 트랜잭션
  **외부에서** `setSchemaVersion(8)` 별도 실행 → 프로세스 크래시 시 스키마는 v8
  형태인데 `PRAGMA user_version = 7` 잔존 가능. Decision 5/16 에서 `PRAGMA
  user_version = 8` 을 트랜잭션 **내부에** 추가로 설정하여 원자 commit 보장

### 출시 단계 가정

`pubspec.yaml` v0.1.1, profile에 placeholder "탐험가" — 출시 전 단계로 판단.
기존 사용자 reading 데이터는 마이그레이션 부담이 낮음 (개발 데이터만 존재).
단 마이그레이션 패턴은 v7→v8이 첫 복합 마이그레이션이므로 패턴이 영구 자산이
된다.

### 슬롯·드로우 매핑 시각화 (사용자 명시)

**T모양 (4장 기본, 한 줄 3장 그리드)**:
```
자리:    1   2   3      드로우:    [1]  [2]  [3]
         _   5   _                  [_]  [4]  [_]
                              ↓ +N (자리 7~ 단순 좌→우)
         7   8   9                  [5]  [6]  [7]
        10  11  12                  [8]  [9]  [10]
```
- 드로우 1→자리 1, 드로우 2→자리 2, 드로우 3→자리 3, 드로우 4→자리 5 (자리 4·6 빈)
- 드로우 5+ → 자리 7부터 좌→우 단순 순서

**3x3 (9장 기본, 한 줄 3장 그리드, 좌→우→가운데 기둥별 아래→위 의식적 매핑)**:
```
자리:    1   2   3      드로우:    [3]  [9]  [6]
         4   5   6                  [2]  [8]  [5]
         7   8   9                  [1]  [7]  [4]
                              ↓ +1~ (자리 10~ 단순 좌→우)
        10  11  12                  [10] [11] [12]
```
- 드로우 1→자리 7, 드로우 2→자리 4, 드로우 3→자리 1 (좌측 기둥)
- 드로우 4→자리 9, 드로우 5→자리 6, 드로우 6→자리 3 (우측 기둥)
- 드로우 7→자리 8, 드로우 8→자리 5, 드로우 9→자리 2 (가운데 기둥)
- 드로우 10+ → 자리 10부터 좌→우 단순 순서

이 의식적 매핑은 카발라/타로 트리 오브 라이프의 "세 기둥(자비·균형·엄격)" 채움
패턴과 결이 통한다. 좌측 기둥(아래→위) → 우측 기둥(아래→위) → 중심 기둥(아래→위).

## Boundaries

### In Scope

| # | Item | Description |
|---|------|-------------|
| 1 | **도메인 모델 진화** | `SpreadType` enum → `LayoutType` 풍부 모델. **enhanced enum + computed properties** (R-007 호환성 확인, fallback 불필요). final: `cardCountMin/Max`, `defaultCardCount`, `cardsPerRowOverride`, `displayName`. 메서드: `slotCount(int)`, `emptySlots(int)`, `drawToSlot(int, int)`, **`resolvePositions(int cardCount) → List<String>`** (generic 라벨 `'카드 N'` 생성, Decision 8), **`resolveGuidances(int cardCount) → List<String>`** (현재 SpreadType과 동일한 빈 리스트 또는 placeholder 반환 — positions 콘텐츠 작업은 OoS #4) |
| 2 | **3가지 배치 종류 + 제약 매트릭스** | linear (1~10장 가변, cardsPerRow 가변, 빈 슬롯 없음, 매핑은 identity) / tShape (4~10장, cardsPerRow=3 강제, 4장 기본 시 빈 슬롯 {3,5} 0-indexed, 매핑은 위 시각화) / grid3x3 (9~10장, cardsPerRow=3 강제, 빈 슬롯 없음, 매핑은 좌→우→중앙 기둥 의식적 패턴) |
| 3 | **DB 스키마 v7→v8 마이그레이션** | `readings.spread_type` 컬럼명 유지 + 값 변환 (`single`/`threeCard`/`custom` → `linear`). `user_settings.default_spread_type` 컬럼 rename → `default_layout_type` + 값 변환. `onUpgrade` 에 `if (from < 8)` 블록 추가. **명시적 트랜잭션 wrap + PRAGMA foreign_keys OFF/ON 토글**. `schemaVersion 7 → 8` |
| 4 | **홈 패널 "모양" 그룹 신설** | (a) "기본 설정" = 덱·레벨·역방향 (3행), (b) "모양" = 배치·카드 수·한 줄 카드 수·(3x3 선택 시) 드로우 순서 (3~4행), (c) "표시 옵션" = 앞면·카드 이름·카드 크기 (3행). 한 줄 카드 수가 표시 옵션에서 모양 그룹으로 이동 |
| 5 | **배치 선행 선택 + 동적 슬라이더 제약** | "모양" 그룹 첫 행이 배치. 배치 변경 시 cardCount 슬라이더의 min/max가 즉시 변경 (linear: 1-10, tShape: 4-10, grid3x3: 9-10). 현재 값이 새 범위 밖이면 `defaultCardCount`로 리셋. cardsPerRow는 tShape/grid3x3에서 3 고정 + 회색 비활성 |
| 6 | **결과 페이지 슬롯 기반 렌더링 (GridView + CustomPaint)** | `spread_layout.dart` 전면 재작성. **GridView.builder + `SliverGridDelegateWithFixedCrossAxisCount` 단일 인프라**로 3 배치 통일 처리. 한 줄 3장 고정 그리드 위에 슬롯 인덱스로 카드 배치. 빈 슬롯은 **CustomPaint 기반 `_DashedRectPainter` + `_EmptySlotPlaceholder` 위젯** (외부 `dotted_border` 패키지 미사용). 드로우→슬롯 매핑은 `LayoutType.drawToSlot` 호출, builder 시작 시 역매핑 `slotToDraw` 한 번 계산 후 O(1) 조회. `ValueKey('card-$drawIdx')` 로 reveal 애니메이션 보존 |
| 7 | **목록/상세 페이지 호환** | `reading_list_page.dart` 의 필터 칩 + `_spreadTypeIcon`을 `linear`/`tShape`/`grid3x3` 으로 갱신 (아이콘 view_stream/view_quilt/grid_view). `reading_detail_page.dart`의 `resolvePositions` 호출 호환 확인 |
| 8 | **3x3 드로우 순서 설정 메뉴 (자리만)** | "모양" 그룹에 grid3x3 선택 시에만 표시되는 행 추가. 옵션: "기본 (좌→우→중앙 의식적 패턴)" 단일 활성 + "다른 순서 (준비 중)" 비활성/회색. 미구현 라벨 명시 |
| 9 | **+N 드로우 정책: cardCount 슬라이더로 통합** | 별도 "+1 카드 추가" 인터랙션을 만들지 않고, 모양 그룹의 cardCount 슬라이더로 통합. 슬라이더 변경 시 셔플 재실행 + 결과 페이지 재렌더. **기존 `draw_result_page.dart:133-146` 의 `_addOneMore` 메서드 + `:269-276` 의 "+N장" 버튼 제거** (013 Critique W4). 제거 후 `shuffleStateProvider.clear()` 호출 경로를 home_page 슬라이더 onChange에 연결 (014 Risk R4) |
| 10 | **마이그레이션 테스트 작성** (drift_schemas 선행 커밋 완료) | `mobile/drift_schemas/drift_schema_v7.json` + `test/generated_migrations/schema_v7.dart` 는 **이미 commit `5a62332` 에 포함됨** — dump/generate 단계는 완료. **잔여 작업**: `mobile/test/database/migration_v7_to_v8_test.dart` 4 케이스 작성 (값 변환 / 컬럼 rename / idempotency / **phantom v7.5 crash recovery** — 014 Risk C2 대응) |

### Out of Scope

| # | Item | Reason |
|---|------|--------|
| 1 | T모양·3x3의 위치별 의미(positions) 한국어 카피 | 도메인 합의 별도 필요. 일단 generic 라벨 (`'카드 1'` ...) 사용 |
| 2 | 추가 배치 종류 (켈틱 크로스, 호스슈, 관계 스프레드 등) | 이번 사이클은 3종까지. 정통 타로 스프레드는 위치·시각 모두 별도 설계 |
| 3 | 사용자 커스텀 배치 (자유 위치 지정) | 스코프 외 |
| 4 | positions 기반 해석 가이드(guidances) 변경 | 콘텐츠 작업 (tarot-expert 영역) |
| 5 | 셔플 단계 UI 변경 | 셔플 화면은 그대로. 모양은 결과 페이지부터 적용 |
| 6 | reading 마이그레이션 시 위치 의미 보존 | 기존 `threeCard`의 위치 의미는 손실됨 (도메인 의미 변경 — 모두 `linear` 매핑) |
| 7 | 3x3 "다른 드로우 순서" 옵션 자체 구현 | UI 자리(비활성 라벨)만 노출. 다른 패턴(시계방향, 중심→외곽 등) 정의·구현은 별도 사이클 |
| 8 | T모양 드로우 순서 변경 메뉴 | 사용자는 3x3에 대해서만 메뉴 추가 요청. T모양은 단일 매핑 고정 |
| 9 | +N 드로우의 별도 인터랙션 UX (결과 페이지 +1 버튼 등) | cardCount 슬라이더로 통합 (Decision 9). 별도 결과 페이지 인터랙션은 별도 사이클 |
| 10 | +N 추가 슬롯의 의식적 매핑 | grid3x3 자리 10+ 는 단순 좌→우. 의식적 패턴(예: 4행도 기둥 채움) 적용은 별도 사이클 |
| 11 | `dotted_border` 패키지 도입 / Drift `TypeConverter` 전환 / Reveal 애니메이션 변경 | R-009-F2: CustomPaint ~30줄로 충분 (의존성 0). R-007-F5: 현 Repository 수동 `.name`/`byName` 유지 (변경 표면 최소화). R-009: CardRevealWidget 부모 비종속 — 그대로 재사용 |

## Decisions

005의 13 Decisions 유지 + Research 후속 4건 추가 = 17건.

| # | Decision | Chosen | Rationale | Trade-off | Alternatives Considered |
|---|----------|--------|-----------|-----------|------------------------|
| 1 | "단순 나열"의 한글 라벨 | **"나열"** | 한 단어로 짧고 직관적. cardsPerRow와 결합하여 한 줄/여러 줄 모두 포함 가능 | 약간 무미건조 — 도메인의 시적 분위기와 결이 약함 | (a) "흐름" — 시간 순서 함의 강제. (b) "기본"/"표준" — 의미 약함. (c) "일렬" — cardsPerRow≥2일 때 모순. (d) "자유" — custom과 혼동 |
| 2 | enum 영문명 | **`LayoutType`** | Dart 표준 컨벤션. "Layout"은 Flutter 생태계 표준어 | UI 위젯 용어와 약간 겹침 | (a) `ArrangementType` 길음. (b) `BatchiType` 콩글리시. (c) `SpreadType` 유지 — 라벨/필드/문서 충돌 |
| 3 | enum value 영문명 | **`linear`, `tShape`, `grid3x3`** | linear는 줄 의미, tShape는 형태 직접, grid3x3은 크기 명세 | grid3x3은 숫자 포함으로 다소 기계적 | (a) `simple/tCross/grid` — grid 단독 모호. (b) `linear/cross/mandala` — mandala는 원형 함의 |
| 4 | 배치 변경 시 cardCount/cardsPerRow 처리 | **즉시 강제 조정 + 제약된 항목 비활성(회색) + 1-step undo SnackBar** (015 Critique D4 반영) | 가능 영역을 시각으로 보여주는 게 가장 명확. 비정합 시도 자체 차단. 단 사용자가 "왜 슬라이더가 갑자기 리셋됐지?" 당황 가능성 → SnackBar `"이전 값 복원"` 액션 (SnackBarAction, ~10줄) 로 10초 동안 undo 허용 | SnackBar UI 공간 짧게 점유. 복원 후 또 배치 변경 시 undo 체인 없음 (단일 step) | (a) 토스트 경고만 — 마찰 큼. (b) 비활성 없이 자동만 — 왜 슬라이더가 안 움직이는지 사용자 모름. (c) 배치별 cardCount 메모리 — UserSettings 복잡도 ↑, YAGNI. (d) SnackBar 없이 silent auto-reset — UX 마찰 (015 Critique) |
| 5 | DB 마이그레이션 정책 (R-008 + 014 Critique 반영) | **Drift schema v7→v8 bump + onUpgrade if-block + `m.database.transaction()` 명시적 wrap + PRAGMA foreign_keys OFF/ON 토글 + `PRAGMA user_version = 8` 트랜잭션 내부 commit + SchemaVerifier 단위 테스트 (4 케이스 — idempotency + phantom v7.5 crash recovery 포함)** | 기존 6 사이클의 customStatement 컨벤션 그대로 확장. 명시적 트랜잭션 + 트랜잭션 내부 user_version 업데이트로 크래시 시 phantom 스키마 상태 방지 (014 C2). SchemaVerifier + drift_dev codegen 이 공식 권장 패턴 | migration 함수 작성·테스트 부담. Drift 내장 `setSchemaVersion` 중복 호출 (무해하지만 약간 verbose). positions 의미 손실 수용 | (a) Schema reset — 모든 reading 손실. (b) 신규 컬럼 + deprecated — 영구 부채. (c) 트랜잭션 wrap 생략 — 부분 적용 리스크. (d) user_version 업데이트 drift 기본 경로에 맡김 — 크래시 시 phantom 상태 위험 (014 Critique R1+R6) |
| 6 | UserSettings 필드명 | **`defaultSpreadType` → `defaultLayoutType`** (Dart 필드 + DB 컬럼명 모두) | 도메인 용어 통일. enum 이름과 일치. SQLite 3.25+ ALTER TABLE RENAME COLUMN 지원으로 실현 가능 (R-008-F6) | 마이그레이션에 컬럼 rename 추가 필요 | (a) 컬럼 그대로 + Dart 필드만 변경 — 코드/DB 불일치. (b) 모두 그대로 + enum만 변경 — Brief 의도 위배 |
| 7 | T모양 카드 수 정책 | **4장 기본 + 4~10 가변** (사용자 직접 결정) | 사용자 표현 "+1 드로우 시 하단부 배치" 가능. T자 4장이 기본 의식적 형태이므로 min=4, 글로벌 max=10 유지로 일관성. 추가 카드는 자리 7+ 단순 좌→우 | 5장 이상은 시각적으로 T+추가 행 (의식적 형태 흐려짐) — 단 사용자가 명시 요청 | (a) 4장 고정 (이전 결정) — 사용자 명시 변경으로 기각. (b) min=1 가변 — 부분 T자 어색 |
| 8 | 위치 의미(positions) 처리 | **generic 라벨 자동 생성 (`'카드 1'`...)** | T/3x3 의미 라벨링은 도메인 합의 필요 (Out of Scope #1) | 위치별 의미 깊이 감소 | (a) 임시 자율 텍스트 — 출시 후 변경 부담. (b) 라벨 숨김 — 정보 부족 |
| 9 | cardCount 슬라이더 max + +N 인터랙션 | **글로벌 max=10 유지, +N 인터랙션은 cardCount 슬라이더로 통합 + `draw_result_page.dart` 의 `_addOneMore`/"+N장" 버튼 전면 제거 + 슬라이더 onChange에 `shuffleStateProvider.clear()` 호출** (013, 014 Critique 반영) | 기존 슬라이더 1~10 범위 그대로. 별도 "+1" 버튼·셔플 추가 인터랙션 도입 시 결과 페이지 UX·셔플 재실행·reading 저장 모두 영향 → 큰 별도 사이클. 슬라이더 통합이 단일 진실의 원천. 기존 버튼 잔존은 "정책 실행 미완"이므로 반드시 제거 | grid3x3은 +1만 가능 (10장), 비대칭. 결과 페이지에서 즉시 "+1" UX 가 사라지는 것은 일부 사용자 습관에 마찰 가능 | (a) max=12 또는 15로 확장 — 모바일 화면 그리드 길이 부담. (b) 별도 +1 버튼 유지 — 사이클 폭 폭증 + 정책 모순. (c) 버튼만 숨기고 코드 잔존 — dead code |
| 10 | T모양 슬롯 + 드로우 매핑 | **기본 4장 시 슬롯 {0,1,2,_,4,_} (빈 슬롯 {3,5} 0-indexed), +N은 자리 7+ (slot 6+) 단순 좌→우** | 사용자 원문 그대로. 자리 4·6 (slot 3,5) 빈 슬롯은 visible placeholder. 추가 슬롯은 단순 그리드 채움 | 5장 이상에서 T자 의식적 형태가 흐려짐 | (a) +N 슬롯도 빈칸 패턴 — 시각 복잡도 ↑. (b) +N은 별도 영역 — 슬롯 모델 비통일 |
| 11 | grid3x3 슬롯 + 드로우 매핑 | **기본 9장 의식적 매핑 (좌→우→중앙 기둥, 각 기둥 아래→위), +1은 자리 10 (slot 9) 단순 좌→우** (사용자 `--run`으로 암묵 동의) | 9장 의식적 패턴은 트리 오브 라이프 세 기둥 채움과 결이 통함. +1 매핑은 사용자 미명시 → 4행 1행 추가는 "기둥별 아래→위" 자체가 무의미하므로 단순 좌→우 선택 (T모양 +N과 일관) | 기본 9장 패턴과 +1 패턴이 의식적 일관성 결여 (기본은 의식적, 추가는 단순) | (a) +1도 4행 기둥 패턴 — 의식적 의미 없음. (b) +1 비허용 (max=9) — Decision 9 글로벌 max=10 비대칭 + 사용자 표현 "T, 3x3 모양에서도 +1 장 드로우"와 충돌 |
| 12 | 3x3 드로우 순서 설정 메뉴 | **메뉴 자리 추가 + "기본" 활성, "다른 순서 (준비 중)" 비활성** | 사용자가 명시적 요청. 향후 다른 패턴 추가 자리 미리 마련 | UI에 미구현 라벨 노출 ("준비 중" 명시로 완화) | (a) 메뉴 안 만들고 기본만 — 사용자 요청 위배. (b) 다른 순서 옵션 즉시 구현 — 별도 사이클 폭 |
| 13 | 도메인 모델 진화 형태 | **enhanced enum + computed properties** (R-007 호환성 확인, fallback 제거, Dart 3 sealed class는 post-v1 재평가 플래그) | Dart 2.17+ enhanced enum이 enum 값별 다른 메서드 구현 지원. freezed/Drift 직렬화는 `_$EnumMap` lookup + `.name`/`byName` 이라 computed properties와 직교 (R-007-F1). json_serializable #1110 이슈는 6.x에서 해결됨 (R-007-F3). sealed class flip은 구조적으로 깨끗하지만 본 사이클 flip 비용 > 이득 (prototype 이미 설계 완료, 직렬화 재검증 필요) | enum 값별 메서드는 정적 분석 약간 복잡. 테스트 케이스 24~36개 필요. `cardsPerRowOverride` nullable 유지 (sealed class 라면 per-subclass 제거 가능) | (a) 별도 `LayoutDefinition` 클래스 — R-007에서 불필요 확정. (b) 단순 enum + 외부 함수 — 도메인 결합 약화. (c) **Dart 3 sealed class** (`sealed class Layout` + `Linear/TShape/Grid3x3` 서브클래스) — `core/error/failures.dart` 선례 존재 (015 Critique), exhaustive switch + per-subclass state 가능, 미래 배치 추가 용이. 본 사이클에서는 flip 않음 — 배치 추가 시점에 재평가 |
| 14 | **결과 페이지 렌더링 접근법** (R-009 신규) | **(B) GridView.builder + 빈 슬롯 위젯** (Stack+Positioned 기각) | 사용자 명시 "한 줄 3장 고정" 메타포와 정확히 일치. 8 비교 차원 중 7개 우세 (R-009-F1). 모든 LayoutType이 동일 GridView 인프라로 통일. linear의 가변 cardsPerRow도 delegate의 `crossAxisCount` 만 바꾸면 작동. AspectRatio/반응형/애니메이션 호환성 우세 | 위젯 트리 깊이 약간 증가 (SliverGrid) — 9~10 슬롯 규모에서 성능 영향 미미 | (a) Stack+Positioned — T자 자유 좌표 메타포, 사용자 의도와 부정합 + linear 별도 분기 필요. (b) Row+Expanded+Wrap — 빈 슬롯 지원 어려움 |
| 15 | **빈 슬롯 placeholder 구현** (R-009 신규) | **CustomPaint + `_DashedRectPainter` (~30줄 직접 작성)** | 외부 `dotted_border` 패키지 의존성 추가 비용 > 코드 30줄 비용 (단일 사용처). 디자인 토큰 (`kSoftPurple` alpha 0.33) 직접 활용 일관성. 향후 glow/이중선 등 확장 자유 (R-009-F2) | 패키지보다 코드량 많음 (~30줄) | (a) `dotted_border` 패키지 — 외부 의존성 + 디자인 토큰 indirection. (b) 단순 DecoratedBox solid border — 시각적 구분 약함 |
| 16 | **마이그레이션 트랜잭션 패턴** (R-008 신규) | **`m.database.transaction()` 명시적 wrap + PRAGMA foreign_keys OFF/ON 토글** | Drift `onUpgrade` 는 자동 트랜잭션이 **아니다** (R-008-F3, issue #3174). 예외 시 부분 적용 방지를 위해 명시적 wrap 필수. PRAGMA 토글은 이번 작업에 외래키 영향 없지만 미래 패턴 정립 차원 (R-008-F7) | migration 블록이 약간 verbose | (a) 트랜잭션 wrap 없이 customStatement 연속 — 부분 적용 리스크. (b) 단일 customStatement에 세미콜론으로 연결 — SQLite는 단일 statement만 실행, 패턴 불가 |
| 17 | **Schema 스냅샷 관리 정책** (R-008 + 012/013 Critique 반영) | **`drift_schemas/` 와 `test/generated_migrations/` 모두 git commit — commit `5a62332` 에 v7 snapshot 포함 완료** | `drift_dev schema dump` 로 v7 JSON snapshot 생성 후 git commit 하면 SchemaVerifier가 미래 마이그레이션에서도 v7 시점 DB를 재현 가능 (R-008-F4). 영구 회귀 방지 자산. **이번 사이클에서는 dump 재실행 불필요 — 기존 snapshot 그대로 사용** | 개발자가 schema 변경 시마다 snapshot dump 명령 기억 필요. `drift_dev schema dump` 가 출력 비결정성을 가질 가능성 (낮음, 014 Risk R5) → 재dump 시 git diff 검증 필요 | (a) snapshot git commit 안 함 — 미래 마이그레이션 테스트 작성 불가. (b) snapshot을 매번 수동 작성 — 사람 실수 위험. (c) CI 아티팩트로만 관리 — 개발자 로컬 테스트 시 snapshot 누락 위험 (015 Critique Toss-up) |
| 18 | **Repository `byName` → `firstWhere + orElse` fallback 패턴** (014 Critique R3 신규) | **`reading_repository_impl.dart:98` 및 `user_settings_repository_impl.dart:113` 의 `SpreadType.values.byName(...)` 를 `LayoutType.values.firstWhere((e) => e.name == row.spreadType, orElse: () => LayoutType.linear)` 로 교체** | 마이그레이션 중 legacy 값 (single/threeCard/custom) 이 DB에 남아있는 시점 (hot reload, impl 사이클 1~2 사이 개발 환경) 에서 `byName`은 ArgumentError throw → 앱 무한 크래시 루프. fallback으로 graceful degradation 확보 | 엄격성 감소 — 알 수 없는 값이 `linear` 로 빠질 수 있음 (단 마이그레이션 완료 후에는 도달 불가 경로) | (a) 마이그레이션 직후 그대로 `byName` 유지 — 예외 발생 시 crash (기각). (b) try/catch 로 감싸기 — Dart 관용구 아님, 가독성 ↓. (c) Repository 층에 enum 매핑 테이블 직접 유지 — boilerplate ↑ |
| 19 | **Migration `onUpgrade` 내부에서 DAO/Repository 호출 금지** (014 Critique R9 신규) | **onUpgrade if-block 내부는 `m.database.customStatement(SQL)` 만 사용. Dart 레이어 DAO/Repository/freezed 변환 호출 금지** | `app_database.g.dart` 는 LayoutType 기준으로 컴파일되지만 migration 실행 시점에는 아직 컬럼명이 legacy 상태 (`default_spread_type`) → DAO 호출 시 존재하지 않는 컬럼 SELECT → 크래시. Raw SQL 만이 스키마 버전과 독립적 | migration 로직이 raw SQL string 에 갇혀 타입 안전성 낮음 (단 테스트 4 케이스로 커버) | (a) DAO로 읽고 수정 — 스키마 상태와 코드 상태 불일치 시 크래시. (b) 트랜잭션 외부에서 DAO 사용 — schemaVersion 미갱신 상태에서 읽기도 동일 문제 |
| 20 | **`Reading.spreadType` 필드명 유지 (비대칭 공식화)** (013 Critique W6 신규) | **`Reading.spreadType` Dart 필드명 + `readings.spread_type` DB 컬럼명 **모두 유지** — 타입만 `LayoutType` 로 교체. `UserSettings.defaultSpreadType` → `defaultLayoutType` 만 rename (양 레이어)** | Reading은 저장된 수가 많을 수 있고 컬럼 rename 시 migration SQL 1문장 추가 + 외부 참조 (테스트, export, DAO) 갱신 비용이 이득보다 큼. UserSettings는 단일 row 테이블이라 rename 비용 무시 가능. **비대칭을 의도적 결정으로 공식화** — impl 에이전트가 "왜 한쪽만 rename?" 혼란 방지 | Dart 필드명 `Reading.spreadType` 이 타입 `LayoutType` 을 들고 있는 의미적 비대칭 잔존. grep 가독성 약간 ↓ | (a) Reading도 rename — 마이그레이션 SQL 1줄 + 전 모듈 grep 대체 (비용 ↑, 이득 미미). (b) 모두 그대로 + enum 타입만 — Brief 의도 ("용어 통일") 위배 |

## Critical Reviews — Resolved via Research

005 Brief의 Critical Review 3건이 Research 007~009에서 모두 해소되었다. 
| 원 CR | 확정 해소 근거 | 반영 위치 |
|-------|--------------|----------|
| **CR#1 DB 마이그레이션 안전성** | R-008 전체 — 명시적 트랜잭션 + PRAGMA 토글 + SchemaVerifier 단위 테스트 패턴 확보. Brief 가정 "v1→v2" 는 실제 "v7→v8" 로 정정 (R-008-F1) | Decision 5, 16, 17 + Constraints 전면 재작성 |
| **CR#2 grid3x3 +1 매핑 일관성** | 사용자가 `/scope brief 005 --run` 실행으로 Decision 11 (단순 좌→우) 암묵 동의 (006 Scope 서두 명시). 4행은 "기둥별 아래→위" 자체가 무의미하므로 합리적 선택 | Decision 11 유지 + Open Questions에서 제거 |
| **CR#3 Enhanced enum × Freezed/Drift 호환성** | R-007 전체 — Dart 3.6+, freezed 2.5+, json_serializable 6.8+, drift 2.22+ 환경에서 정식 호환. 직렬화는 `_$EnumMap` lookup + `.name`/`byName` 이라 computed properties와 직교. fallback (별도 `LayoutDefinition` 클래스) 발동 불필요 (R-007-F1, F2) | Decision 13 유지, fallback 문구 제거. Constraints에 "build_runner 첫 실행 시 `_$LayoutTypeEnumMap` 자동 생성 + 단위 테스트 통과가 confirmation gate" 추가 |

## Open Questions

| # | Question | Impact | Status |
|---|----------|--------|--------|
| (없음) | 모든 자율 결정 + Critical Review 3건 모두 해소됨 | — | — |

## Constraints

### 환경·라이브러리

- **Dart SDK ^3.6.0 / freezed ^2.5.0 / json_serializable ^6.8.0 / drift ^2.22.0 / drift_dev ^2.22.0 / sqlite3_flutter_libs ^0.5.0**
- **Enhanced enum 호환**: Dart 2.17+ 필요 (3.6+ 확인). json_serializable #1110 은 6.x 이전 해결됨. 연관 pubspec 변경 불필요
- **SQLite 3.25+ ALTER TABLE RENAME COLUMN 지원**: sqlite3_flutter_libs 0.5.0 이 3.40+ 번들 → 안전

### codegen 필수

- **Drift codegen**: schema 변경 시 `cd mobile && dart run build_runner build --delete-conflicting-outputs`
- **Freezed codegen**: Reading entity 필드 타입 변경 시 동일 명령
- **Schema snapshot dump (impl 사이클 2 prerequisite)**:
  ```
  cd mobile
  dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/
  git add drift_schemas/ && git commit -m "drift: snapshot v7 schema for migration testing"
  dart run drift_dev schema generate --data-classes --companions drift_schemas/ test/generated_migrations/
  ```
- **confirmation gate (impl 사이클 1 verify)**: build_runner 재생성 후 `reading.g.dart` 에 `_$LayoutTypeEnumMap` 자동 생성 + grep 확인 + 단위 테스트 통과

### 컴포넌트 재사용

- 005 신규 위젯은 (a) `_EmptySlotPlaceholder` + `_DashedRectPainter` (spread_layout.dart 내부 또는 별도 파일), (b) 드로우 순서 메뉴 행, (c) 비활성 슬라이더에 한정
- 002~004의 `_PanelSubheader`, `_GoldSwitch`, `_PillSelector` 등 재사용
- `CardRevealWidget` 부모 비종속 + AspectRatio 내부 적용 → GridView cell에 그대로 투입 가능 (R-009-F6). `ValueKey('card-$drawIdx')` 적용 필수 (애니메이션 보존)

### 빌드·시각 검증

- **빌드**: `cd mobile && flutter build apk --debug`
- **시각 검증 5종** (ADB 스크린샷):
  1. 모양 그룹 UI (grid3x3 선택 시 4행 + "다른 순서 (준비 중)" 비활성 라벨)
  2. tShape 결과 페이지 4장 (빈 슬롯 placeholder 2개: slot 3, 5 점선 사각형)
  3. tShape 결과 페이지 +N (예: 7장, 자리 7~ 좌→우)
  4. grid3x3 결과 페이지 9장 (좌→우→중앙 기둥 의식적 매핑)
  5. 배치 변경 시 cardCount 슬라이더 동적 min/max + 비활성 (예: linear 7장 상태 → grid3x3 전환 → 슬라이더가 9~10으로 클램프 + cardsPerRow 회색 3 고정)

### 테스트 3종 필수 (014 Critique 반영으로 케이스 확장)

- `mobile/test/database/migration_v7_to_v8_test.dart` — SchemaVerifier 기반 **4 케이스**
  1. `readings.spread_type` 값 변환 (single/threeCard/custom 3건 → 모두 `linear`)
  2. `user_settings` 컬럼 rename + 값 변환 (`default_spread_type` → `default_layout_type`, 값 `linear`)
  3. Idempotency (v8 상태에서 `migrateAndValidate(db, 8)` 재실행해도 no-op)
  4. **Phantom v7.5 crash recovery** (014 Critique C2): 스키마는 v8 형태 + `user_version=7` 상태를 수동 시뮬레이션 → AppDatabase 재오픈 → onUpgrade(from=7) 재실행 시 `no such column: default_spread_type` 예외가 발생하지 않고 graceful skip 또는 성공 검증. 해결책은 Decision 5의 트랜잭션 내부 `PRAGMA user_version = 8` commit
- `mobile/test/features/reading/domain/entities/layout_type_mapping_test.dart` — `drawToSlot`, `emptySlots`, `slotCount`, **`resolvePositions`** 24~36 케이스 (3 enum × 4 메서드 × 카드 수 시나리오)
- `mobile/test/features/home/card_count_auto_adjust_test.dart` — 배치 전환 시 cardCount min/max 강제 + defaultCardCount 리셋 + **SnackBar undo 액션 표시 검증** (Decision 4)
- **Repository fallback 검증** (inline in 기존 reading/user_settings repository 테스트 또는 신규 단위 테스트): `row.spreadType == 'legacy_unknown_value'` 시 `LayoutType.linear` 반환 (Decision 18)

### 출시 전 가정

- v0.1.1, 사용자 데이터는 개발자 테스트 한정. 단 마이그레이션 패턴·schema snapshot 은 영구 자산

## Exit Criteria

- [x] SpreadType ↔ 카드 수 충돌의 본질 명시
- [x] LayoutType 도메인 모델 결정 (enhanced enum + computed properties, fallback 제거)
- [x] 3종 배치별 제약 매트릭스 (cardCount min/max, cardsPerRow, 빈 슬롯, 드로우 매핑)
- [x] +N 정책 (cardCount 슬라이더 통합)
- [x] 슬롯·드로우 매핑 시각화 (T모양·3x3 기본 + +N)
- [x] 3x3 드로우 순서 메뉴 정책 (기본 활성 + 다른 순서 비활성)
- [x] UI 그룹 재구성 안 (모양 그룹 신설, grid3x3 시 4행)
- [x] DB 마이그레이션 정책 (v7→v8 정정 + 명시적 트랜잭션 + PRAGMA 토글 + SchemaVerifier)
- [x] 결과 페이지 렌더링 접근법 (GridView + CustomPaint, Decision 14, 15)
- [x] Schema snapshot 관리 정책 (Decision 17)
- [x] Critical Review 3건 전부 해소
- [x] In Scope 10개 / Out of Scope 11개 / Decisions **20개** 명세 (012~016 Critique 반영으로 18/19/20 신규)
- [x] Quality Profile 확정 (standard — Scope 006 `--run` 으로 암묵 동의)
- [x] Ideal Criteria 작성 완료 (**17건**, standard 프로필)
- [x] Deep Critique 4 관점 (Feasibility / Scope Balance / Risk / Alternatives) 적용 완료
- [x] Context § SpreadType 참조 분포 완전판 (UserSettings/draw pages/home PillSelector 포함)
- [x] Phantom v7.5 crash recovery 대응 (Decision 5 + 테스트 Case 4)
- [x] byName ArgumentError 방어 (Decision 18)

## Ideal Criteria

Quality Profile: **standard** (Scope 006 `--run` 호출로 확정 — Brief 005 Step 5b 대체)
Priority Dimensions: **Function + Edge + UX** (standard 프로필 기본 3축, 사용자 명시 dimension 없음)

In Scope 10개 항목 × 평균 1.5 criterion = 15 criteria. Function/Edge/UX 축 분산.

| # | Criterion | References (In Scope #) | Type | Dimension |
|---|-----------|------------------------|------|-----------|
| 1 | `LayoutType` enum 3 값 (`linear`, `tShape`, `grid3x3`) 이 computed properties 5개 (`cardCountMin`, `cardCountMax`, `defaultCardCount`, `cardsPerRowOverride`, `displayName`) + 메서드 3개 (`drawToSlot`, `emptySlots`, `slotCount`) 구현 완료 | #1 | assertion | Function |
| 2 | `layout_type_mapping_test.dart` 가 24+ 테스트 케이스 (enum 3 × 메서드 3 × 시나리오 min/default/max/+N) 통과 | #1 | assertion | Function |
| 3 | 3 배치 제약 매트릭스가 Model Anchors 명시 값과 런타임 일치 (단위 테스트로 검증) | #2 | assertion | Function |
| 4 | Drift schema v7→v8 마이그레이션 단위 테스트 **4 케이스** (값 변환 / 컬럼 rename / idempotency / **phantom v7.5 crash recovery**) 모두 통과 | #3 | assertion | Function |
| 5 | 마이그레이션 블록 내 예외 throw 시 트랜잭션 롤백 동작 확인 (명시적 `m.database.transaction()` wrap 존재) + 트랜잭션 내부 `PRAGMA user_version = 8` commit 검증 | #3 | assertion | Robustness |
| 5b | Repository 의 `byName` → `firstWhere + orElse: LayoutType.linear` fallback 패턴이 legacy 값 (`'threeCard'`) 에서 ArgumentError 대신 `LayoutType.linear` 반환 | #3 | assertion | Robustness |
| 5c | Migration `onUpgrade` 내부에서 DAO/Repository/freezed 변환 호출 부재 — 오직 `m.database.customStatement(SQL)` 만 사용 (코드 리뷰 gate) | #3 | assertion | Robustness |
| 6 | 홈 패널이 "기본 설정"(3행) + "모양"(linear/tShape 시 3행, grid3x3 시 4행) + "표시 옵션"(3행) 3-group 구조로 렌더 | #4 | assertion | Function |
| 7 | 배치 변경 시 cardCount 슬라이더 min/max 즉시 갱신 + 현재값이 범위 밖이면 `defaultCardCount`로 리셋 + **10초 SnackBar undo 액션 표시 + 탭 시 이전 배치·cardCount 복원** (`card_count_auto_adjust_test.dart` 통과) | #5 | assertion | UX |
| 8 | cardsPerRow 슬라이더가 tShape/grid3x3 선택 시 회색 비활성 + 값 3 고정 (사용자 조작 불가) | #5 | assertion | UX |
| 9 | tShape 4장 결과 페이지: slot 3, 5 에 `_EmptySlotPlaceholder` (점선 사각형) 2개 visible, 나머지 4 슬롯에 `CardRevealWidget` | #6 | assertion | Function |
| 10 | grid3x3 9장 결과 페이지: 드로우 1,2,3 → slot 6,3,0 (좌 기둥), 드로우 4,5,6 → slot 8,5,2 (우 기둥), 드로우 7,8,9 → slot 7,4,1 (중앙 기둥) 배치 | #6 | assertion | Function |
| 11 | tShape 7장 결과 페이지: 기본 4 슬롯 (0,1,2,4) + 빈 슬롯 (3,5) + 추가 드로우 5~7 → slot 6,7,8 단순 좌→우 | #6 | assertion | Edge |
| 12 | linear 5장 cardsPerRow=2 결과: 6 슬롯 중 앞 5개에 카드, slot 5는 `SizedBox.shrink` (visible placeholder 아님) | #6 | assertion | Edge |
| 13 | `reading_list_page` 필터 칩 아이콘이 linear (view_stream) / tShape (view_quilt) / grid3x3 (grid_view) 로 갱신 + 기존 reading 필터링 정상 | #7 | assertion | Function |
| 14 | 3x3 드로우 순서 메뉴: "기본 (좌→우→중앙 의식적 패턴)" 활성 + "다른 순서 (준비 중)" 회색 비활성 탭 무반응 | #8 | assertion | UX |
| 15 | 5종 ADB 스크린샷 검증 완료: (a) 모양 그룹 UI, (b) tShape 4장 빈 슬롯 visible, (c) tShape 7장 +N, (d) grid3x3 9장 의식적 매핑, (e) 배치 변경 시 슬라이더 동적 조정 | #4,5,6 | assertion | UX |

## Model Anchors

- **용어 통일 원칙**: 사용자 라벨은 모두 "**배치**" (스프레드 금지). 코드/타입/필드/DB 컬럼명은 모두 "**Layout**" 계열. 한국어 라벨은 "배치", "나열", "T모양", "3x3"만 사용
- **차원 분리 원칙**: 배치(LayoutType)는 **모양** 차원, 카드 수는 **수량** 차원. 단방향 의존 (배치 → 수량 제약). 카드 수가 배치를 결정하지 않음
- **선행 선택 원칙**: "모양" 그룹 첫 행은 항상 **배치**. 배치가 cardCount 슬라이더 min/max 및 cardsPerRow 활성화 여부를 결정하는 게이트
- **자동 조정 원칙**: 배치 변경 시 cardCount는 새 min/max 범위로 강제 (현재 값이 범위 밖이면 `defaultCardCount`로 리셋), cardsPerRow는 강제 적용. 비활성 항목은 회색 표시. **전환 시 SnackBar `"이전 값 복원"` 액션 10초 동안 노출 — 탭 시 이전 배치·cardCount·cardsPerRow 상태 복원** (Decision 4). SnackBar 체인 없음 (단일 step)
- **`cardsPerRow` DB 저장 정책** (U3 Critique): tShape/grid3x3 선택 시 UI 는 3 고정 + 회색 비활성. **DB (`user_settings.cards_per_row`) 에는 강제값 3 그대로 저장** — linear 복귀 시 이전 값 복구 안 함 (Decision 4 "이전 값 보존 안 함" 과 일관)
- **Repository fallback 원칙**: `reading_repository_impl.dart:98` + `user_settings_repository_impl.dart:113` 의 `byName(...)` 를 `firstWhere((e) => e.name == row.xxx, orElse: () => LayoutType.linear)` 로 교체 (Decision 18). legacy 값은 graceful degradation
- **3종 배치 풍부 모델 매트릭스**:
  | 배치 | cardCountMin | cardCountMax | defaultCardCount | cardsPerRowOverride | 기본 빈 슬롯 (cardCount=min 시, 0-indexed) | 기본 드로우 매핑 (drawToSlot) |
  |------|--------------|--------------|------------------|---------------------|-------------------------------------|----------------------------|
  | linear | 1 | 10 | 3 | null (가변, 사용자 cardsPerRow 사용) | {} | identity (drawN → slotN) |
  | tShape | 4 | 10 | 4 | 3 | {3, 5} | {0→0, 1→1, 2→2, 3→4} + (n≥4: drawN → slot(n+2)) |
  | grid3x3 | 9 | 10 | 9 | 3 | {} | {0→6, 1→3, 2→0, 3→8, 4→5, 5→2, 6→7, 7→4, 8→1} + (n=9: draw9 → slot9) |
  ※ slot 0-indexed. 사용자 원문의 "자리 N" = slot (N-1). `slotCount(cardCount) = ceil((cardCount + emptySlots.length) / cellsPerRow) * cellsPerRow`
- **도메인 모델 형태**: `LayoutType` 은 Dart enhanced enum. 3 값은 enum 본체 시작에 선언. final instance variables 로 매트릭스 데이터 보유. 메서드는 `switch (this) { ... }` 분기로 값별 구현. freezed/Drift codegen 은 enum value **이름**만 사용하므로 computed properties와 직교 — annotation 추가 불필요
- **그룹 구조 재배치**: (a) 기본 설정 = 덱·레벨·역방향 (3행), (b) 모양 = 배치·카드 수·한 줄 카드 수·(grid3x3 시) 드로우 순서 (3 또는 4행, 동적), (c) 표시 옵션 = 앞면·카드 이름·카드 크기 (3행)
- **드로우 순서 메뉴 정책**: grid3x3 선택 시에만 모양 그룹 마지막 행으로 추가. `_PillSelector` 사용. "기본" 활성 + "다른 순서 (준비 중)" 비활성. 비활성 옵션 탭 시 무반응
- **+N 인터랙션 정책**: cardCount 슬라이더로 통합. 별도 "+1 카드 추가" 버튼/제스처 미도입. 셔플 단계는 cardCount만큼 미리 셔플하므로 슬라이더 변경 시 새 셔플 트리거. 결과 페이지에서 카드 추가 인터랙션 없음. **`draw_result_page.dart:133-146` `_addOneMore` 메서드 + `:269-276` "+N장" 버튼 전면 제거** (Decision 9). 슬라이더 onChange 에 `shuffleStateProvider.clear()` 호출 경로 연결 (014 R4)
- **DB 마이그레이션 정책 (R-008 + 014 Critique 확정)**:
  - `app_database.dart:25` `schemaVersion 7 → 8` 변경
  - `onUpgrade` 에 `if (from < 8) { ... }` 블록 추가 (기존 6 블록 아래)
  - 블록 구조 (트랜잭션 **내부에 `PRAGMA user_version = 8`** 포함):
    ```dart
    await m.database.customStatement('PRAGMA foreign_keys = OFF');
    try {
      await m.database.transaction(() async {
        await m.database.customStatement(
          "UPDATE readings SET spread_type = 'linear' "
          "WHERE spread_type IN ('single', 'threeCard', 'custom')",
        );
        await m.database.customStatement(
          "UPDATE user_settings SET default_spread_type = 'linear' "
          "WHERE default_spread_type IN ('single', 'threeCard', 'custom')",
        );
        await m.database.customStatement(
          'ALTER TABLE user_settings RENAME COLUMN default_spread_type '
          'TO default_layout_type',
        );
        // ⚠ Decision 5 — phantom v7.5 방지: user_version 도 트랜잭션 내부에서 commit
        await m.database.customStatement('PRAGMA user_version = 8');
      });
    } finally {
      await m.database.customStatement('PRAGMA foreign_keys = ON');
    }
    ```
  - `readings.spread_type` 컬럼명은 **유지** (값만 변환, Decision 20 비대칭 공식화). `user_settings` 만 컬럼 rename
  - SchemaVerifier 기반 단위 테스트 **4 케이스** 필수 (Constraints § 테스트, C4 신규)
  - **onUpgrade 내부 DAO/Repository/freezed 변환 호출 금지** (Decision 19) — raw SQL 만 사용
- **위치 의미 정책**: T모양/3x3 positions는 generic 라벨 (`'카드 1'`...) 자동 생성. 의미 라벨링은 별도 콘텐츠 작업
- **결과 페이지 렌더링 전략 (R-009 확정)**:
  - 단일 `GridView.builder` 인프라로 3 배치 통일 처리 (Stack+Positioned 기각)
  - `gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: layoutType.cardsPerRowOverride ?? cardsPerRow, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: cardAspectRatio * 0.9)`
  - builder 시작 시 역매핑 `slotToDraw = <int,int>{}; for (draw in 0..cardCount) slotToDraw[drawToSlot(draw, cardCount)] = draw;` 한 번 계산
  - `itemCount: layoutType.slotCount(cardCount)`
  - `itemBuilder`: (1) `emptySlotsSet.contains(slot)` → `_EmptySlotPlaceholder` (점선 placeholder), (2) `slotToDraw[slot] == null` → `SizedBox.shrink` (linear 자투리), (3) 그 외 → `CardRevealWidget(key: ValueKey('card-$drawIdx'), ...)`
  - 부모가 스크롤 컨테이너면 `shrinkWrap: true, physics: NeverScrollableScrollPhysics()`
  - GridView 루트에 `key: ValueKey(layoutType)` 적용 → 배치 전환 시 위젯 트리 재생성 (애니메이션 컨트롤러 누수 방지)
- **빈 슬롯 placeholder 디자인 (R-009 확정)**: `CustomPaint + _DashedRectPainter` 클래스 직접 작성 (~30줄, dotted_border 패키지 미사용). 스펙: `color = Color(0x556B5B95)` (kSoftPurple alpha 0.33), `dashWidth=6, dashGap=4, strokeWidth=1, cornerRadius=4`, `RRect.fromRectAndRadius` + `Path.computeMetrics` + `extractPath` dash 반복. `AspectRatio(aspectRatio: cardAspectRatio)` 로 카드와 동일 비율
- **시각 검증 5종 필수**: (a) 모양 그룹 UI (grid3x3 선택 시 4행), (b) tShape 결과 4장 (빈 슬롯 placeholder slot 3,5), (c) tShape 결과 7장 (+N, 자리 7+ 좌→우), (d) grid3x3 결과 9장 (좌→우→중앙 의식적 매핑), (e) 배치 변경 시 cardCount 슬라이더 동적 min/max + cardsPerRow 회색 비활성
- **테스트 3종 필수**: `migration_v7_to_v8_test.dart` (SchemaVerifier 3 케이스), `layout_type_mapping_test.dart` (24+ 케이스), `card_count_auto_adjust_test.dart`

## Critique Integration

Research axes 007~010 이 (임시적으로) deep-critique 역할을 수행했다. 각 발견의 반영 결과:

| # | Source | Finding | Severity | Action | Rationale |
|---|--------|---------|----------|--------|-----------|
| 1 | R-008-F1 | Brief 005 Decision 5 문구 "v1→v2" 는 실제 `schemaVersion = 7` 이므로 "v7→v8" 로 정정 필요 | critical | **반영** — Decision 5, Context § DB 현황, Model Anchors § DB 마이그레이션, Constraints § codegen 전면 갱신 | 문구 오류는 impl 사이클 2에서 잘못된 if-block guard 생성으로 이어져 기존 v2~v7 사이클 손상 가능 |
| 2 | R-007-F1,F2 | enhanced enum × freezed × Drift 호환성 확인 — fallback (별도 LayoutDefinition 클래스) 발동 불필요 | critical | **반영** — Decision 13의 "alternative (a) fallback" 문구 제거, Constraints에 "build_runner `_$LayoutTypeEnumMap` 확인 gate" 추가 | 불필요한 fallback 경로 유지 시 impl 사이클 1에서 과도한 방어 코드 작성 위험 |
| 3 | R-008-F3 | Drift `onUpgrade` 는 자동 트랜잭션이 아니다 → `m.database.transaction()` 명시적 wrap 필수 | critical | **반영** — Decision 16 신규 추가, Model Anchors § DB 마이그레이션 block 예시에 명시 | 자동 트랜잭션 가정 시 migration 중간 예외로 부분 적용 상태 발생 — 영구 부채 위험 |
| 4 | R-009-F1 | 결과 페이지 렌더링은 GridView + 빈 슬롯 위젯이 8 비교 차원 중 7개 우세 | critical | **반영** — Decision 14 신규 추가, In Scope #6 업데이트 (Stack+Positioned 기각 명시), Model Anchors § 결과 페이지 렌더링 전략 | 렌더링 접근법 불확정 시 impl 사이클 3에서 방향 재설계 리스크 |
| 5 | R-009-F2 | 빈 슬롯 placeholder는 CustomPaint 직접 작성 권장 (dotted_border 패키지 불필요) | high | **반영** — Decision 15 신규 추가, Out of Scope #11 에 "dotted_border 미도입" 명시 | 외부 의존성 최소화 + 디자인 토큰 일관성 |
| 6 | R-008-F4 | SchemaVerifier + drift_dev schema dump/generate 가 공식 테스트 패턴 | high | **반영** — Decision 17 신규 추가, In Scope #10 신설, Constraints § codegen 에 6 단계 prerequisite 명세 | 첫 v7→v8 마이그레이션이 미래 패턴의 템플릿 |
| 7 | R-009-F3,F4,F5 | slotToDraw 역매핑은 builder 시작 시 한 번 계산 / 도메인 빈 슬롯 vs linear 자투리 구분 / LayoutType 추가 메서드 불필요 | high | **반영** — Model Anchors § 결과 페이지 렌더링 전략에 상세 알고리즘 명시 | impl 사이클 3 prototype 코드 일관성 확보 |
| 8 | R-008-F7 | PRAGMA foreign_keys OFF/ON 토글은 이번 작업에 외래키 영향 없지만 패턴 정립 차원 권장 | medium | **반영** — Decision 16, Model Anchors § DB 마이그레이션 block 예시에 포함 | 미래 외래키가 있는 테이블 마이그레이션의 템플릿 |
| 9 | R-009-F6 | CardRevealWidget은 부모 비종속 + AspectRatio 내부 적용 → ValueKey('card-$drawIdx') 필수 | medium | **반영** — Constraints § 컴포넌트 재사용, Model Anchors § 렌더링 전략에 `key: ValueKey` 명시 | 애니메이션 중 카드 위젯 교체 시 컨트롤러 누수 방지 |
| 10 | R-009 Caveats | GridView + linear 자투리 슬롯의 SizedBox.shrink 가 GridView 셀 크기 0으로 만들 위험 | low | **부분 반영** — Model Anchors § 렌더링 전략에 `SizedBox.shrink` 명시 (impl 사이클 3 verify 단계에서 레이아웃 깨짐 여부 실측) | 최종 위젯 선택은 실측 후 결정 (현 prototype은 shrink, 필요 시 `SizedBox.expand` 로 전환) |
| 11 | 012 Feasibility W1/W2/W5 + 013 Scope W5 | Context § SpreadType 참조 분포 표가 UserSettings 도메인 (`user_settings.dart:19`, `.g.dart:16-18,49-53`, repository:113), draw pages 2개 (animated_draw + draw_result 의 `_spreadType.cardCount`), home `_PillSelector<SpreadType>` (`home_page.dart:456-464`) 를 누락 | critical | **반영** — Context § SpreadType 참조 분포 완전판으로 재작성, 새로 밝혀진 의존성 섹션 추가 | 미반영 시 impl 사이클 1 에서 컴파일 에러 속출 + 사이클 3 UI 작업이 과소 추정됨 |
| 12 | 014 Risk R1 + R6 | Drift 의 `setSchemaVersion` 이 onUpgrade 트랜잭션 **외부에서** 별도 PRAGMA로 실행 → 마이그레이션 중 크래시 시 phantom v7.5 상태 (스키마=v8, user_version=7) 로 인한 영구 crash loop 가능 | critical | **반영** — Decision 5 재작성 (트랜잭션 내부 `PRAGMA user_version = 8` 추가), Model Anchors § DB 마이그레이션 블록 예시 갱신, Constraints 테스트 Case 4 (crash recovery) 추가, Ideal Criteria #4 업그레이드 | 크래시 복구 실패는 사용자 앱 영구 차단 — data loss 보다 심각 |
| 13 | 012 Feasibility + 013 W1 | `mobile/drift_schemas/drift_schema_v7.json` 과 `test/generated_migrations/schema_v7.dart` 는 commit `5a62332` 에 **이미 포함** — In Scope #10 의 "dump/generate" 단계 미래 작업 기술은 stale | critical | **반영** — In Scope #10 전면 재작성 ("이미 완료, 잔여는 migration test 만"), Context § DB 현황 추가, Decision 17 재작성 | stale 기술로 impl 사이클 2 가 이미 존재하는 파일을 재생성 시도 + git noise |
| 14 | 013 Scope Balance W2 + 012 Feasibility | `resolvePositions`/`resolveGuidances` 메서드가 In Scope #1 메서드 목록에 누락 — 현재 SpreadType 에 존재하고 `reading_detail_page.dart:76` + R-009 prototype 이 `layoutType.resolvePositions(cardCount)` 호출. 계약 불일치 | major | **반영** — In Scope #1 에 두 메서드 추가 + generic 라벨 구현 명세 | 누락 시 impl 사이클 1 후 detail 페이지 컴파일 실패 |
| 15 | 014 Risk R3 | `SpreadType.values.byName(row.spreadType)` 은 legacy 값에서 ArgumentError → 마이그레이션 중간 hot reload 시점에 crash loop | major | **반영** — 신규 Decision 18 추가 (`firstWhere + orElse: LayoutType.linear` fallback), Constraints 테스트 목록 확장, Ideal Criteria #5b 추가 | dev 환경 안정성 + 미래 legacy 값 유입 방어 |
| 16 | 014 Risk R9 | onUpgrade 내부에서 DAO 호출은 AppDatabase codegen 이 LayoutType 기준이지만 migration 실행 시점 스키마는 legacy 상태 → 컬럼 불일치 크래시 | major | **반영** — 신규 Decision 19 추가 (raw SQL 강제), Model Anchors 에 명시, Ideal Criteria #5c 추가 | migration 안전성 핵심 |
| 17 | 013 Scope Balance W6 | `UserSettings.defaultSpreadType` → `defaultLayoutType` rename vs `Reading.spreadType` 필드명 유지 비대칭이 명시적 결정으로 공식화되지 않음 → impl 에이전트 혼란 가능 | major | **반영** — 신규 Decision 20 추가 (비대칭 공식화), Context 테이블 각주 | impl 시 한쪽만 rename 하는 이유를 문서가 설명 |
| 18 | 013 Scope W4 + 012 | Decision 9 "결과 페이지 +1 버튼 없음" 이 선언적이지만 `draw_result_page.dart:133-146, 269-276` 의 `_addOneMore` + "+N장" 버튼 **제거 명시 부재** | major | **반영** — In Scope #9 + Decision 9 업데이트 ("전면 제거" 명시) + `shuffleStateProvider.clear()` 경로 연결 | Decision 선언만 있고 실행 명세 부재 → impl 누락 위험 |
| 19 | 015 Alternatives Weak D4 | 배치 변경 silent auto-reset 이 UX 마찰 ("왜 갑자기 리셋됐지?"). 1-step SnackBar undo 액션이 10줄로 구현 가능 | major | **반영** — Decision 4 업데이트 (SnackBar undo 채택), Model Anchors § 자동 조정 원칙 갱신, Ideal Criteria #7 Dimension `Function` → `UX` 변경 및 undo 검증 추가 | UX 개선 비용 < 이득 |
| 20 | 015 Alternatives Weak D13 | Dart 3 sealed class 가 enum 대비 구조적으로 우세 (선례 `failures.dart`, nullable 제거, per-subclass state). 단 본 사이클 flip 비용 > 이득 | medium | **부분 반영** — Decision 13 Alternatives 섹션에 sealed class 기록 (post-v1 재평가 플래그). flip 하지 않음 | 배치 추가 사이클 시점에 재평가 트리거 |
| 21 | 014 Risk R5 | `drift_dev schema dump` 재실행 시 출력 비결정성 가능성 (낮음) → false-positive git diff | minor | **기록** — Decision 17 Trade-off 에 명시 | 개발자 로컬 재dump 금지 원칙 (이미 commit 된 snapshot 사용) |
| 22 | 016 U6 Cycle 3 과중 | Cycle 3 파일 9개 + 위젯 2 신규 + 테스트 1 + 스크린샷 5종은 cycle 1/2 대비 과중. 3a/3b/3c 분할 권고 | minor | **미반영 (Brief 밖)** — Scope 006 의 impl 사이클 구조 권고로 별도 제출 | Brief 는 불변 앵커이므로 사이클 재분할은 scope 책임 |

---

## 부록 — Pipeline Context (Scope 006 참조)

본 Brief는 Scope 006의 파이프라인 입력으로 사용된다:
- **complexity**: complex
- **effort_mode**: standard
- **tdd_mode**: true (모든 impl 사이클 tdd-red 선행)
- **research_cycles**: 3 (007, 008, 009) + 1 synthesis (010) — **완료**
- **impl_cycles**: 3 (도메인 모델 → DB 마이그레이션 → UI 통합)
- **auto_run**: true
- **orchestrator_active**: true
- **총 체크리스트 아이템**: 23 (research 6 + synthesis 1 + impl 12 + tail 4)

Research phase 종료 상태. 이 Brief 011 은 impl phase 의 불변 정렬 앵커.

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 0s | 0 |
| 2 | user-ai-exchange | 451s | 935162 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 499s |
| Total Tokens | 935162 |
| Input Tokens | 21 |
| Output Tokens | 27853 |
| Cache Read | 778646 |
| Cache Creation | 128642 |
