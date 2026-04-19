---
id: "006"
type: scope
title: "Scope — 배치(LayoutType) 재설계 3사이클"
created: 2026-04-19
status: completed
complexity: complex
research_needed: true
research_axes:
  - axis: "enhanced-enum-codegen"
    question: "LayoutType을 Dart enhanced enum (값별 computed properties/메서드) 으로 만들 때 freezed @JsonKey 및 Drift TextColumn + enum.byName 직렬화가 정상 작동하는가? prototype 검증이 가능한 최소 코드 형태와 알려진 충돌/회피 패턴"
    source: "Brief 005 Critical Review #3 + Decision 13"
  - axis: "drift-migration-pattern"
    question: "Drift schema v1 → v2 마이그레이션에서 (a) 트랜잭션 보장, (b) 실패 시 롤백, (c) v1 fixture → v2 변환을 검증하는 단위 테스트 작성 패턴. Drift 공식 onUpgrade / MigrationStrategy / beforeOpen 메커니즘의 표준 용법"
    source: "Brief 005 Critical Review #1 + Decision 5"
  - axis: "slot-based-rendering"
    question: "T자/3x3 배치의 슬롯 기반 렌더링을 Flutter에서 표현하는 방법. (a) Stack + Positioned 절대 좌표 vs (b) GridView + 빈 슬롯 위젯(visible placeholder) 두 접근법의 trade-off. 빈 슬롯 placeholder 디자인 (점선 사각형) 의 표준 구현 패턴 (CustomPaint, DottedBorder 패키지 등)"
    source: "Brief 005 In Scope #6 + Model Anchors 결과 페이지 렌더링 전략"
research_cycles: 3
impl_cycles: 3
effort_mode: standard
tdd_mode: true
auto_run: true
orchestrator_active: true
traces_brief: "docs/15_draw_experience_settings/005_Brief_layout_redesign.md"
summary: >
  Brief 005의 In Scope 9개 항목을 도메인 모델 진화 → DB 마이그레이션 → UI 통합의
  3사이클로 집행한다. Research 축 3개 (enhanced enum codegen, Drift migration
  트랜잭션, 슬롯 기반 렌더링) 를 선행 수행하여 Critical Review 리스크를 제거한다.
  effort_mode standard, tdd_mode true, 총 3 research 사이클 + 3 impl 사이클 + tail.
keywords: [scope, layout, domain-model, migration, rendering, complex, standard-effort, tdd]
---

# Scope — 배치(LayoutType) 재설계 3사이클

## Brief Reference

Brief 005 (`docs/15_draw_experience_settings/005_Brief_layout_redesign.md`, status:
in-progress, Decisions 13건 확정, Critical Review 3건) 를 변경 불가능한 정렬
앵커로 수용한다. /scope brief 005 --run 호출 자체가 Brief 확정 + Quality Profile
standard 수용 + CR #2 (grid3x3 +1 매핑 = 단순 좌→우) 암묵적 동의 의사 표시.

## Goal

"스프레드 → 배치" 도메인 정렬 + 3종 배치(나열/T모양/3x3) 도입 + 슬롯·드로우
매핑 모델 + DB 마이그레이션 + 홈 패널 "모양" 그룹 신설을 **3사이클 + tail**
구조로 실행한다.

## Research Phase (3 사이클, main agent Skill(research) 수행)

### 축 1 — enhanced-enum-codegen (Critical Review #3 해소)

**핵심 질문**: LayoutType을 Dart enhanced enum으로 만들되 값별 `cardCountMin/Max`,
`defaultCardCount`, `cardsPerRowOverride`, `slotCount(int)`, `emptySlots(int)`,
`drawToSlot(int, int)` computed properties/메서드를 부여했을 때:

1. Reading freezed entity의 `@JsonKey(fromJson/toJson)` 또는 기본 `.name`
   직렬화가 정상 작동하는가?
2. Drift `TextColumn` + Repository의 `SpreadType.values.byName(row.spreadType)`
   역직렬화 패턴이 enhanced enum에서도 동일하게 작동하는가?
3. codegen 충돌 사례 / 회피 패턴 / 최소 prototype 코드

**성공 조건**: "enhanced enum + computed properties + freezed + Drift"
조합의 작동 가능 여부 + 충돌 시 fallback 경로 (별도 `LayoutDefinition` 클래스)
명확한 결정 지침 확보

### 축 2 — drift-migration-pattern (Critical Review #1 해소)

**핵심 질문**: Drift schema v1 → v2 마이그레이션에서:

1. `MigrationStrategy.onUpgrade` 내 `await m.customStatement(...)` 또는
   `m.alterTable` 으로 TextColumn 값 변환을 안전하게 수행하는 표준 패턴
2. 트랜잭션 자동 보장 범위 (Drift는 onUpgrade 전체를 트랜잭션으로 감싸는가?)
3. 실패 시 롤백 동작 (exception throw가 자동 롤백을 트리거하는가?)
4. 단위 테스트: v1 schema로 DB fixture 생성 → onUpgrade 실행 → v2 schema 검증
   하는 drift_dev 또는 NativeDatabase 기반 테스트 패턴

**성공 조건**: migration 함수 작성 + 롤백 보장 + 테스트 작성의 표준 패턴을
impl 사이클 2에서 바로 코드에 적용 가능한 수준의 가이드 확보

### 축 3 — slot-based-rendering (In Scope #6 구현 가이드)

**핵심 질문**: T자/3x3 결과 페이지 렌더링에서:

1. (A) Stack + Positioned 절대 좌표 접근법 vs (B) GridView + 빈 슬롯 위젯 접근법
   - 반응형(다양한 화면 크기) 대응
   - 카드 aspectRatio 유지
   - 애니메이션 (reveal transition) 호환성
   - 코드 가독성
2. 빈 슬롯 placeholder의 표준 구현:
   - CustomPaint로 점선 사각형 직접 그리기
   - `dotted_border` 패키지 사용
   - `DecoratedBox(dashed border)` 직접 표현 (DartPad 예제)
3. LayoutType.tShape.emptySlots(cardCount) 반환값을 렌더링 트리에 반영하는
   선언적 패턴 (Builder + mapped children)

**성공 조건**: (A) vs (B) 중 본 프로젝트에 적합한 접근법 선택 + 빈 슬롯
placeholder 최소 구현 스니펫 확보. impl 사이클 3에서 바로 적용 가능

### Research 사이클 실행 순서

| 순서 | 축 | 실행 방식 |
|------|----|----------|
| cycle-1 | enhanced-enum-codegen | Skill(research) — 1 사이클 (research + eval) |
| cycle-2 | drift-migration-pattern | Skill(research) — 1 사이클 |
| cycle-3 | slot-based-rendering | Skill(research) — 1 사이클 |
| cycle-99 | synthesis | pipeline.sh 자동 첨부 — 3 축 결과 통합 |

axis 간 의존성 없음 (독립적 지식 영역) — 순차 실행 필수 아님이지만 컨텍스트
관리 용이를 위해 순차로.

## Implementation Phase (3 사이클, Agent 디스패치)

### 사이클 1 — 도메인 모델 진화 (In Scope #1, #2)

**목표**: SpreadType → LayoutType rename + enhanced enum + computed properties
완성. DB 계층 이전 작업.

**Modified**:
| 파일 | 변경 |
|------|------|
| `mobile/lib/features/reading/domain/entities/spread_type.dart` | `SpreadType` → `LayoutType` rename + enhanced enum 변환 + 3 값 + computed properties 8개 (cardCountMin/Max, default, cardsPerRowOverride, slotCount, emptySlots, drawToSlot, displayName) + backward-compatible `resolvePositions`/`resolveGuidances` |
| `mobile/lib/features/reading/domain/entities/reading.dart` | `SpreadType` 참조 → `LayoutType` |
| `mobile/lib/features/reading/domain/repositories/reading_repository.dart` | interface의 `SpreadType` → `LayoutType` |
| `mobile/lib/features/reading/data/repositories/reading_repository_impl.dart` | `.name` 직렬화 / `byName` 역직렬화 (로직 변경 없이 타입 교체) |
| `mobile/lib/features/reading/presentation/providers/reading_providers.dart` | 필터 프로바이더 타입 교체 |
| `mobile/lib/core/database/daos/reading_dao.dart` | `spreadType` 파라미터 이름은 유지 (DB 컬럼명과 일치) |

**Reviewed**:
| 파일 | 확인 |
|------|------|
| `mobile/lib/features/reading/domain/entities/reading.freezed.dart` | build_runner 재생성 후 `LayoutType` 반영 확인 |
| `mobile/lib/features/shuffle/...` | SpreadType 직접 참조 없음 확인 (grep) |

**TDD-red 목표**: LayoutType enum 값 테스트 (`.cardCountMin`, `.drawToSlot(0, 4)` 등 기대값을 미리 작성)
**Verify**: `flutter analyze` + `dart test` (LayoutType 단위 테스트) 통과, 기존 reading 테스트 회귀 없음

**파일 수**: Modified 6 / Reviewed 2, confidence: **high**

### 사이클 2 — DB 마이그레이션 (In Scope #3 + UserSettings 필드명 #6)

**목표**: Drift schema v1 → v2 마이그레이션 + migration 함수 + v1 fixture →
v2 변환 단위 테스트. 사용자 데이터 안전성 보장.

**Modified**:
| 파일 | 변경 |
|------|------|
| `mobile/lib/core/database/app_database.dart` (또는 db 정의 파일) | `schemaVersion 1 → 2`, `migration: MigrationStrategy(onUpgrade: ...)` 추가 |
| `mobile/lib/core/database/tables/readings_table.dart` | TextColumn `spreadType` 의 의미 변경 안내 코멘트 (값이 `linear`/`tShape`/`grid3x3`) |
| `mobile/lib/core/database/tables/user_settings_table.dart` | `defaultSpreadType` → `defaultLayoutType` rename (컬럼명) |
| `mobile/lib/features/settings/domain/entities/user_settings.dart` | `defaultSpreadType` → `defaultLayoutType` + 타입 `LayoutType` |
| `mobile/lib/features/settings/data/repositories/user_settings_repository_impl.dart` | 필드명 rename 전파, migration 기간 backward 읽기 |
| `mobile/lib/features/settings/presentation/providers/settings_providers.dart` | `updateDefaultSpreadType` → `updateDefaultLayoutType` |
| 신규 테스트 파일: `mobile/test/database/migration_v1_to_v2_test.dart` | v1 schema DB fixture → onUpgrade → v2 schema 검증. reading `threeCard` → `linear`+cardCount=3, `single` → `linear`+cardCount=1 등 매핑 검증 |

**Reviewed**:
| 파일 | 확인 |
|------|------|
| `mobile/lib/core/database/*.g.dart` | build_runner 재생성 확인 (schema 코드 갱신) |

**TDD-red 목표**: migration 테스트 먼저 작성 (예: "v1 DB에 single reading 3건 삽입 → onUpgrade → all linear 타입 변환 + cardCount = drawnCards.length")
**Verify**: migration 테스트 통과, `flutter analyze`, 기존 settings 테스트 회귀 없음, 앱 수동 실행 시 첫 실행이 v2 스키마로 정상 동작 (개발자 DB 상에서 확인)

**파일 수**: Modified 7 (테스트 파일 포함) / Reviewed 1, confidence: **medium** (Drift migration 첫 사례라 research synthesis 결과에 따라 조정 가능)

### 사이클 3 — UI 통합 (In Scope #4, #5, #6, #7, #8, #9)

**목표**: 홈 패널 "모양" 그룹 신설 + 동적 cardCount 슬라이더 + 결과 페이지 슬롯
기반 렌더링 + 목록/상세 페이지 호환 + 3x3 드로우 순서 메뉴 + +N cardCount 통합

**Modified**:
| 파일 | 변경 |
|------|------|
| `mobile/lib/features/home/presentation/pages/home_page.dart` | `_DrawSettingsPanel` 그룹 재구성: "기본 설정"(3행) + "모양"(3~4행, 배치·카드 수·한 줄 카드 수·(grid3x3 시) 드로우 순서) + "표시 옵션"(3행). 배치 선택 시 cardCount min/max 동적 적용. cardsPerRow 동적 활성/비활성. 비활성 슬라이더 회색 표시. `_PillSelector<LayoutType>` 추가 |
| `mobile/lib/features/reading/presentation/widgets/spread_layout.dart` | 전면 재작성. linear/tShape/grid3x3 모두 한 줄 3장 고정 그리드 위에 `LayoutType.xxx.drawToSlot(i, cardCount)` 로 슬롯 배치. 빈 슬롯은 점선 placeholder 위젯. (구체 구현은 Research axis 3 synthesis 결과에 따름) |
| `mobile/lib/features/reading/presentation/pages/reading_list_page.dart` | 필터 칩의 `SpreadType` → `LayoutType`, `_spreadTypeIcon` 에 `linear`/`tShape`/`grid3x3` 아이콘 매핑 (예: view_stream/view_quilt/grid_view) |
| `mobile/lib/features/reading/presentation/pages/reading_detail_page.dart` | `resolvePositions` 호출 호환 확인. displayName 참조 호환 |
| 신규 위젯 파일: `mobile/lib/features/home/presentation/widgets/_empty_slot_placeholder.dart` (또는 spread_layout.dart 내부) | 점선 사각형 placeholder 위젯. research axis 3 결과에 따라 구현 |
| 신규 테스트 파일: `mobile/test/features/reading/domain/entities/layout_type_mapping_test.dart` | LayoutType의 `drawToSlot`, `emptySlots`, `slotCount` 단위 테스트 |
| 신규 테스트 파일: `mobile/test/features/home/card_count_auto_adjust_test.dart` | 배치 전환 시 cardCount 자동 조정 로직 단위 테스트 |

**Reviewed**:
| 파일 | 확인 |
|------|------|
| `mobile/lib/features/settings/presentation/pages/settings_page.dart` | 사이클 2 작업(002 파이프라인 커밋 a8c47f5) 이후 placeholder 상태 유지 확인 |
| `mobile/lib/features/shuffle/...` | cardCount 변경이 셔플에 올바르게 전파되는지 호출 경로 확인 |

**TDD-red 목표**: LayoutType 매핑 + cardCount 자동 조정 테스트 먼저 작성
**Verify**: 전체 `flutter analyze` + `dart test`, `flutter build apk --debug`, ADB 스크린샷 5종 (Brief 005 Constraints 명세)

**파일 수**: Modified 7 (위젯 + 테스트 포함) / Reviewed 2, confidence: **medium**

## Dependencies & Execution Order

```
Research cycle-1 (enum codegen)
Research cycle-2 (drift migration)    ─┐ (독립, 순차 실행으로 컨텍스트 관리)
Research cycle-3 (slot rendering)      │
Research cycle-99 (synthesis)         ─┘
     ↓ (synthesis 경로가 impl phase 참고 자료)
Impl cycle-1 (도메인 모델 진화) — synthesis 축 1 적용
     ↓
Impl cycle-2 (DB 마이그레이션) — synthesis 축 2 적용
     ↓
Impl cycle-3 (UI 통합) — synthesis 축 3 적용
     ↓
[tail] eval → qualify → push → retro
```

## Total Surface

- **총 변경 파일**: 약 20 (Modified: 사이클 1 × 6 + 사이클 2 × 7 + 사이클 3 × 7 = 20, 중복 제거 후 18) / Reviewed: 5
- **신규 테스트 파일**: 3 (migration, layout_type_mapping, card_count_auto_adjust)
- **build_runner 실행 최소 2회**: 사이클 1 (LayoutType 적용), 사이클 2 (schema 변경)
- **confidence 종합**: 사이클 1 high, 사이클 2·3 medium — medium 사이클은 Plan 단계에서 research synthesis 결과 반영하여 파일 목록 재검증 필수

## Out of Scope (Brief 005 Out of Scope 승계 + 추가)

Brief 005 Out of Scope 10개 항목 전부 승계. 추가 scope 밖 항목:

1. T모양 5~10장의 슬롯 배치 검증을 research 사이클에 포함시키지 않음 — impl 단계에서 코드 작성 후 시각 확인 (research는 아키텍처 선택에 한정)
2. 기존 002~004 (settings_menu_relocation) 사이클의 UI 요소 디자인 리뷰는 본 scope 범위 외
3. Animation 마이크로 인터랙션 (배치 전환 시 트랜지션) 은 Polish 수준 이상에서만 고려 — 현재 standard 프로필에서는 미포함
4. 타 배치 종류 (켈틱 크로스, 호스슈, 만다라 등) 사전 설계 — 별도 사이클

## Verification Plan (Standard Profile)

- **빌드**: `cd mobile && flutter build apk --debug` (사이클별 impl 후)
- **테스트**: `dart test` 통과 (단위 테스트 3종)
- **정적 분석**: `flutter analyze` 경고 0
- **ADB 스크린샷 5종** (Brief 005 Constraints 명세):
  1. 모양 그룹 UI (grid3x3 선택 시 4행 메뉴)
  2. tShape 결과 페이지 4장 (빈 슬롯 placeholder 2개)
  3. tShape 결과 페이지 +N (예: 7장)
  4. grid3x3 결과 페이지 9장 (의식적 매핑 좌→우→중앙)
  5. 배치 변경 시 cardCount 슬라이더 동적 min/max + 비활성
- **마이그레이션 실전 검증**: 개발자 로컬 DB에 v1 reading 데이터 수동 삽입 → 앱 재실행 → v2 변환 확인

## Pipeline

- complexity: **complex**
- effort_mode: **standard** (eval + qualify + push + retro tail)
- tdd_mode: **true** (모든 impl 사이클 tdd-red 선행)
- research_needed: **true**, research_cycles: **3**
- impl_cycles: **3**
- auto_run: **true** (`--run` 명시)
- orchestrator_active: **true**
- 총 체크리스트 아이템: research 6 (3축 × [research+eval]) + synthesis 1 + impl 12 (3사이클 × [tdd-red+makeplan+impl+verify]) + tail 4 = **23 items**

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 117s | 344643 |
| 2 | user-ai-exchange | 235s | 1232689 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 786s |
| Total Tokens | 1577332 |
| Input Tokens | 32 |
| Output Tokens | 25030 |
| Cache Read | 1459873 |
| Cache Creation | 92397 |
