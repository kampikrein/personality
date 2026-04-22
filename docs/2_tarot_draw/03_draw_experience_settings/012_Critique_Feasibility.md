---
id: "012"
type: critique
title: "Brief 011 Critique — Technical Feasibility"
created: 2026-04-20
status: completed
perspective: "feasibility"
target: "011"
confidence: high
summary: >
  Brief 011은 핵심 기술 주장(버전 매트릭스, 마이그레이션 패턴, GridView 렌더링,
  enhanced enum 호환성)이 실제 코드베이스와 정확히 일치한다. 단, Context 테이블의
  `SpreadType` 참조 분포는 불완전하여 UserSettings 도메인(`user_settings.dart`,
  `user_settings_repository_impl.dart`, `user_settings.g.dart`)과 실제 사용자
  코드 3곳(`animated_draw_page.dart`, `draw_result_page.dart`, `home_page.dart`
  `_DrawSettingsPanel`의 "스프레드" PillSelector)이 누락되었다. 또 홈 페이지의
  실제 구조는 Brief 004의 "기본 설정/모양/표시 옵션" 3그룹과 다르며(스프레드가
  이미 기본 설정에 있고 "한 줄 카드 수"는 표시 옵션에 있음), `cardsPerRow` DB
  컬럼이 **nullable int**이어서 회색 비활성 + 값 3 강제 구현이 LayoutType 런타임
  상태와 DB 상태 사이의 동기화 엣지를 만든다. 기타 파이프라인 메타데이터 경로
  오류(Scope 006의 `docs/15_...`)도 현존한다.
keywords: [critique, brief, feasibility, layout, codebase-verification]
---

# Brief 011 Critique — Technical Feasibility

## Executive Summary

Brief 011의 **핵심 기술 주장은 현 코드베이스에서 전부 실행 가능**하다. 버전 매트릭스, Drift v7 schemaVersion, 기존 6 사이클 customStatement 패턴, enhanced enum 호환성, GridView+CustomPaint 렌더링 접근이 실제 코드와 일치하며, 놀랍게도 **R-008의 prerequisite 6단계 중 schema dump/generate 2단계는 이미 완료**되어 있다(`mobile/drift_schemas/drift_schema_v7.json`, `mobile/test/generated_migrations/schema_v7.dart` 존재). 그러나 Brief의 Context `SpreadType 참조 분포` 표는 실제 callsite의 약 60%만 포착했으며, **핵심 사용자 코드 3곳(`animated_draw_page.dart:29,53,54`, `draw_result_page.dart:29,53,54`, `home_page.dart:456-464`의 "스프레드" PillSelector)과 UserSettings 도메인 전체**가 표에 없다. In Scope #4(홈 패널 재구성)는 현재 코드 구조를 잘못 기술하고 있다 — "한 줄 카드 수가 표시 옵션에서 모양 그룹으로 이동"이라는 문구는 실측 맞으나, 그 외 그룹 재배치 규모는 Brief 기술보다 크다(스프레드를 기본 설정에서 제거 → 모양으로 이동, 덱/레벨 사이 카드 수 위치 등). 종합: impl 사이클 1~3 실현 가능성은 high, 단 Brief Context 보강 + 엣지 케이스 2건 명시 권장.

## Findings

### Strengths

1. **버전 매트릭스 완전 일치** — `mobile/pubspec.yaml:6,28,29,33-35,50-54`에서 모든 버전 정확: Dart `^3.6.0` (line 6), drift `^2.22.0` (28), drift_dev `^2.22.0` (54), freezed `^2.5.0` (52), json_serializable `^6.8.0` (53), sqlite3_flutter_libs `^0.5.0` (29), freezed_annotation `^2.4.0` (34), json_annotation `^4.9.0` (35). Brief 011 Constraints §환경·라이브러리 정확.
2. **`schemaVersion => 7` + 6 사이클 customStatement 패턴 실재** — `mobile/lib/core/database/app_database.dart:25` = `int get schemaVersion => 7;`. `app_database.dart:28-70`의 `MigrationStrategy.onUpgrade`는 `if (from < 2)` ~ `if (from < 7)` 6블록 누적이고 전부 `m.database.customStatement(...)` 패턴. R-008-F1, R-008-F2, Brief Context §DB 현황 전부 정확.
3. **`reading.g.dart`의 `_$SpreadTypeEnumMap` 자동 생성 확인됨** — `mobile/lib/features/reading/domain/entities/reading.g.dart:13,26,33-37` 에 `$enumDecode(_$SpreadTypeEnumMap, ...)` / `_$SpreadTypeEnumMap[instance.spreadType]!` / `const _$SpreadTypeEnumMap = { SpreadType.single: 'single', ... }` 구조가 Brief 011 + R-007-F1 예측 그대로 존재. enhanced enum 전환 시 동일 구조의 `_$LayoutTypeEnumMap` 생성 예측은 경험적으로 확실.
4. **Reading entity에 enum 필드는 `spreadType` 1개뿐** — `mobile/lib/features/reading/domain/entities/reading.dart:10-18`에서 enum 필드는 `SpreadType spreadType` 하나. DrawnCardInfo는 String/int/bool만. R-007 가정(enum 필드가 spreadType 단일) 성립.
5. **Repository의 수동 `.name`/`byName` 직렬화 패턴 실재** — `reading_repository_impl.dart:31` = `spreadType: reading.spreadType.name`, `:98` = `spreadType: SpreadType.values.byName(row.spreadType)`. R-007-F3 정확.
6. **`readings.spread_type` / `user_settings.default_spread_type` 컬럼 실재** — `readings_table.dart:8` = `TextColumn get spreadType => text()();` (TypeConverter 없음), `user_settings_table.dart:15-16` = `TextColumn get defaultSpreadType => text().withDefault(const Constant('custom'))();`. Brief 011 In Scope #3, Decision 5 정확.
7. **SQLite 3.25+ RENAME COLUMN 지원 실증** — `sqlite3_flutter_libs: ^0.5.0` (pubspec:29) 번들의 SQLite 3.40+가 Brief/R-008-F6의 ALTER TABLE RENAME COLUMN 지원 근거 제공.
8. **`CardRevealWidget` 부모 비종속 + AspectRatio 내부** — `card_reveal_widget.dart:124,167`에 `AspectRatio(aspectRatio: widget.cardAspectRatio, ...)` 존재, GridView cell에 그대로 투입 가능. R-009-F6 / Brief Constraints §컴포넌트 재사용 정확.
9. **`spread_layout.dart` 현 구조 = switch 분기 + GridView.builder crossAxisCount=3 (라인 80)** — `spread_layout.dart:29-33,82-103`. Brief 011 Context §SpreadType 참조 분포 (라인 107 claim) 거의 정확하나 실측은 106줄.
10. **디자인 토큰 존재** — `core/widgets/mystical_scaffold.dart:6-12`에 `kGold`, `kSoftPurple (0xFF6B5B95)`, `kDeepPurple`, `kDarkSurface` 등 전역 상수. Brief Model Anchors §빈 슬롯 placeholder 디자인 `Color(0x556B5B95)` 근거 성립.
11. **R-008 prerequisite 6단계 중 schema dump/generate 2단계는 이미 실행됨** — `mobile/drift_schemas/drift_schema_v7.json` (12,885 byte, line 1), `mobile/test/generated_migrations/schema_v7.dart` (82,262 byte), `mobile/test/generated_migrations/schema.dart` (GeneratedHelper + v7 케이스 포함). 즉 impl 사이클 2는 stage 1, 2, 3 건너뛰고 바로 schemaVersion bump + onUpgrade block + migration_v7_to_v8_test.dart 작성 가능. Brief Constraints §codegen의 prerequisite은 이미 수행된 작업을 나열한 셈 — 이는 Strength이자 Brief가 인지하지 못한 사실.
12. **Critical Review #3 (enhanced enum 호환성) 증거 뒷받침** — `mobile/lib/core/database/app_database.g.dart`의 `SyncStatus` enum은 이미 `intEnum<SyncStatus>().withDefault(Constant(SyncStatus.pending.index))()` 패턴(`readings_table.dart:14`)으로 Drift TypeConverter + enhanced-enum 유사 구조가 가동 중 — 프로젝트에서 enum codegen이 정상 작동하는 경험적 증거.

### Weaknesses

| # | Finding | Severity | Evidence | Recommendation |
|---|---------|----------|----------|----------------|
| 1 | Brief Context §SpreadType 참조 분포 표에서 **`UserSettings` 도메인 전체 누락**. `user_settings.dart:19` `@Default(SpreadType.custom) SpreadType defaultSpreadType`, `user_settings.g.dart:16-18,39,49-53` `_$SpreadTypeEnumMap` 2번째 복사본, `user_settings_repository_impl.dart:113` `defaultSpreadType: SpreadType.values.byName(row.defaultSpreadType)`, `user_settings.freezed.dart:28,59,89,119,122,169,197,227,230,272,302,326,344,345,371,403,427` 이 모두 LayoutType rename 시 동반 변경 대상 | critical | `mobile/lib/features/settings/domain/entities/user_settings.dart:3,19`, `user_settings.g.dart:16-18,49-53`, `user_settings_repository_impl.dart:4,113`, `user_settings.freezed.dart` 전역 | Context 표에 "Entity/Settings: `user_settings.dart` (SpreadType 필드)", "Repository/Settings: `user_settings_repository_impl.dart` (.name/byName)", "Generated (freezed+g)" 3행 추가. In Scope #1에 "UserSettings의 `defaultSpreadType: SpreadType` 필드도 `defaultLayoutType: LayoutType`으로 동반 변경" 명시 |
| 2 | Brief Context §SpreadType 참조 분포에서 **드로우 실행 페이지 2개 누락** — `animated_draw_page.dart:8,29,53,54,56` 과 `draw_result_page.dart:8,29,53,54,56`이 `late SpreadType _spreadType;` + `_spreadType = settings?.defaultSpreadType ?? SpreadType.custom;` + `_currentCardCount = _spreadType == SpreadType.custom ? ... : _spreadType.cardCount;` 사용. 이 로직은 LayoutType 전환 시 **`.cardCount` 삭제 + min/max 기반 클램프 + custom 특수 분기 제거** 리팩터 필요 — impl 사이클 1/3 범위에 영향 | critical | `mobile/lib/features/draw/presentation/pages/animated_draw_page.dart:29,53,54`, `mobile/lib/features/draw/presentation/pages/draw_result_page.dart:29,53,54` | Context 표에 "Draw page (연출): `animated_draw_page.dart`", "Draw page (즉시): `draw_result_page.dart`" 2행 추가. In Scope #1에 "`.cardCount` getter 제거 → `LayoutType.defaultCardCount` + UserSettings.defaultCardCount 병행 로직 정리" 명시 |
| 3 | Brief Context §SpreadType 참조 분포에서 **홈 패널 스프레드 PillSelector callsite 누락**. Brief는 "`home_page.dart` → `_DrawSettingsPanel` 모양 그룹 + 드로우 순서 메뉴"로만 기술하나, 실제 `home_page.dart:456-464` 는 이미 `_PillSelector<SpreadType>` (`single/threeCard/custom` 3옵션) 이 기본 설정 그룹에 있음. In Scope #4의 그룹 재배치가 사소한 수정이 아니라 PillSelector 옵션 3개를 `LayoutType` 3값으로 교체 + "기본 설정"에서 "모양"으로 블록 이동 | major | `mobile/lib/features/home/presentation/pages/home_page.dart:456-464` (PillSelector), `home_page.dart:452-466` 전체 "스프레드" SettingRow | In Scope #4에 "기존 `_PillSelector<SpreadType>` (single/threeCard/custom) → `_PillSelector<LayoutType>` (linear/tShape/grid3x3) 교체", "'스프레드' → '배치' 라벨 변경", "기본 설정 그룹에서 모양 그룹으로 블록 이동" 3단계 명시 |
| 4 | In Scope #4 §홈 패널 "모양" 그룹 신설 — "한 줄 카드 수가 표시 옵션에서 모양 그룹으로 이동"은 맞지만, **실제 홈 페이지의 현재 그룹 구조가 Brief 기술과 상이**. 현재 `home_page.dart:391-477`에 `_PanelSubheader('기본 설정')` 하나만 있고 그 안에 덱/레벨/카드 수/스프레드/역방향 5행 — Brief는 "(a) 기본 설정 = 덱·레벨·역방향 (3행)"이라 주장하나 실제는 5행. `_PanelSubheader('표시 옵션')`(line 482)은 앞면/카드 이름/한 줄 카드 수/카드 크기 4행. "카드 수"가 기본 설정에 있으나 Brief는 모양으로 이동시킨다. | major | `mobile/lib/features/home/presentation/pages/home_page.dart:391-521` | In Scope #4를 "기존 `_PanelSubheader('기본 설정')` 5행 (덱·레벨·카드 수·스프레드·역방향) → 덱·레벨·역방향 3행으로 축소", "카드 수·스프레드(→배치)를 '모양' 그룹으로 이동", "표시 옵션에서 한 줄 카드 수를 모양으로 이동" 으로 재기술 |
| 5 | In Scope #5 + Decision 4 §cardsPerRow 회색 비활성 고정 — **`user_settings_table.dart:27-28` `cardsPerRow = integer().nullable().withDefault(const Constant(3))()` 이 nullable int**. "tShape/grid3x3 선택 시 회색 비활성 + 값 3 고정" 은 UI 상태이지만 DB 값 자체는 사용자의 마지막 수동 설정값을 유지하거나 매번 3으로 덮어써야 함. LayoutType 런타임 오버라이드(`cardsPerRowOverride: 3`)와 DB 저장값의 동기화 정책 미명시 | major | `mobile/lib/core/database/tables/user_settings_table.dart:27-28`, `mobile/lib/features/settings/data/repositories/user_settings_repository_impl.dart:100-104` (`updateCardsPerRow`) | Decision 4 또는 Model Anchors에 "배치 tShape/grid3x3 선택 시 DB `cards_per_row` 는 **유지**(마지막 linear 설정값 기억) vs **3으로 덮어쓰기** 중 선택 명시" 추가. R-009의 `layoutType.cardsPerRowOverride ?? cardsPerRow` 패턴은 이 선택에 무관하게 작동하나 linear 복귀 시 동작이 갈림 |
| 6 | Brief Context §SpreadType 참조 분포 행 "`UI 설정 home_page.dart` `_DrawSettingsPanel` 모양 그룹 + 드로우 순서 메뉴"는 **미래 상태**를 기술 (현재 존재 X). 현재 상태와 목표 상태를 구분하지 않음 — impl 구현자가 혼동 가능 | minor | `home_page.dart` 전체에 "_DrawSettingsPanel"은 340행에 존재하나 "모양" 그룹·드로우 순서 메뉴 미존재 | Context 표에 "(현재)"/"(목표)" 열 추가 또는 행별로 "현: X / 목표: Y" 표기 |
| 7 | Brief §Pipeline Context (부록) `traces_scope: "006"` 는 일관되나, **Scope 006의 `traces_brief: "docs/15_draw_experience_settings/005_Brief_layout_redesign.md"` 가 실제 경로 `docs/2_tarot_draw/03_draw_experience_settings/` 와 불일치**. 003_Scope / 004_Plan 도 동일 오류. `2026-04-20` 자로 폴더 구조가 `docs/N_/NN_/NNN_` 레이아웃으로 재구성되었으나 (commit 9d11a36) 메타데이터 미갱신. Brief 011 자체에는 경로 오류가 없으나 상위 체인이 깨짐 | minor | `docs/2_tarot_draw/03_draw_experience_settings/006_Scope_layout_redesign.md:25`, `003_Scope_settings_menu_relocation.md:13`, `004_Plan_settings_menu_relocation.md:7-8` | 006 Scope 의 `traces_brief`, `_Brief 005_` 내부 링크를 `docs/2_tarot_draw/03_draw_experience_settings/005_Brief_layout_redesign.md` 로 정정. Brief 011 § Pipeline Context 부록에 "※ 상위 체인 경로 오류 해소는 별도 정리 작업" 메모 추가 |
| 8 | In Scope #7 §"`reading_detail_page.dart`의 `resolvePositions` 호출 호환 확인" — `reading_detail_page.dart:76-77` = `final resolvedPositions = reading.spreadType.resolvePositions(reading.drawnCards.length);`. LayoutType에는 R-007 prototype에 `resolvePositions` 가 **없음** — R-009의 spread_layout prototype만 호출하는 형태. 이를 LayoutType에 추가할지, 아니면 generic 라벨 로직을 spread_layout과 detail page에 각각 재작성할지 미결정 | major | `mobile/lib/features/reading/presentation/pages/reading_detail_page.dart:76,77,171`, R-007 Prototype Code에 `resolvePositions` 부재, R-009 Prototype Code `final positions = layoutType.resolvePositions(cardCount);` (prototype line 426, LayoutType 외부 호출로 가정했으나 메서드 정의 없음) | In Scope #1 또는 Decision 8에 "LayoutType에 `resolvePositions(int cardCount) → List<String>` (기본 `List.generate(n, (i) => '카드 ${i+1}')`) 메서드 추가" 명시. R-007 Prototype과 R-009 Prototype 간 메서드 계약 불일치 해소 |
| 9 | Brief In Scope #9 "+N 드로우 정책 cardCount 슬라이더 통합 ... 결과 페이지에 별도 +1 버튼 없음" — **현재 `draw_result_page.dart:133-146,269-276` 에 `_addOneMore()` + "+${_currentCardCount}장" 버튼이 존재**. In Scope #9 실행은 이 버튼/메서드 제거 포함 | major | `mobile/lib/features/draw/presentation/pages/draw_result_page.dart:133-146` (`_addOneMore`), `:269-276` ("+${_currentCardCount}장" ResultBtn) | In Scope #9 또는 In Scope #7에 "`draw_result_page.dart:133-146,269-276` 의 `_addOneMore` + 하단 '+N장' 버튼 제거" 명시. 이 변경은 자동 저장된 reading의 `addDrawnCard` 경로(`reading_repository_impl.dart:62-76`) 도 함께 영향 |
| 10 | `drift_schema_v7.json` 의 `readings` 테이블 스펙 확인: `spread_type` 컬럼은 `"default_dart":null` (no default) — **기존 reading 데이터에 `'single'/'threeCard'/'custom'` 외 값이 이미 있을 가능성**. Brief Decision 5 `UPDATE ... WHERE spread_type IN ('single','threeCard','custom')` 필터는 기타 값을 건너뛰므로 `linear/tShape/grid3x3` 값이 유입된 테스트 DB에서는 no-op (안전하나 의도와 다름) | minor | `mobile/drift_schemas/drift_schema_v7.json` (readings.spread_type entity) | Decision 5 / Model Anchors §DB 마이그레이션 policy 에 "WHERE 절 `NOT IN ('linear','tShape','grid3x3')` 형태로 보수적으로 변경 고려" 메모 추가, 또는 v8 이후 도입될 신 값을 고려한 방어 주석 |
| 11 | Brief Model Anchors §DB 마이그레이션 block 예시의 SQL: `UPDATE readings SET spread_type = 'linear' WHERE spread_type IN ('single', 'threeCard', 'custom')` — SQLite 에서 `'threeCard'` 는 case-sensitive literal. 정상 작동하지만 **`readings.spread_type` 이 `TextColumn` 이므로 대소문자 혼합 유입 가능성이 있다면 `COLLATE NOCASE` 고려 필요**. 현 `reading_repository_impl.dart:31`이 `reading.spreadType.name`으로 저장하므로 대소문자 일관 — Low | minor | `mobile/lib/features/reading/data/repositories/reading_repository_impl.dart:31`, Brief Model Anchors §DB 마이그레이션 | 저장 경로가 `.name` 단일이므로 현 형태 유지. 단 Exit Criteria 에 "Repository 저장 경로가 `.name` 단일임을 impl 사이클 2에서 재확인" 체크박스 추가 |
| 12 | In Scope #10 의 Prerequisite 6단계 중 **1,2,3 단계는 이미 완료** — 그러나 Brief Constraints §codegen 는 이를 impl 사이클 2 prerequisite 로 기술하여 불필요 작업 반복 유발 가능. `drift_schemas/drift_schema_v7.json` + `test/generated_migrations/schema_v7.dart` + `schema.dart` 실재 | minor | `mobile/drift_schemas/drift_schema_v7.json`, `mobile/test/generated_migrations/schema_v7.dart`, `mobile/test/generated_migrations/schema.dart` | Constraints §codegen 를 "※ Prerequisite 1~3 (schema dump, git commit, generate)는 이미 수행됨 — 재실행 시 no-op 또는 덮어쓰기. impl 사이클 2 는 4~6 단계부터 시작" 로 정정 |
| 13 | R-007 Prototype `LayoutType` 는 `displayName` getter만 제공. 현재 `SpreadType.displayName` 은 `'한 장 뽑기'/'쓰리 카드'/'자유 선택'` 이고 `reading_list_page.dart:46, 76, 182`와 `reading_detail_page.dart:82` 에서 직접 사용. Brief Decision 1~3 이 `'나열/T모양/3x3'` 으로 교체. **기존 reading 데이터는 `spreadType = 'single'/'threeCard'/'custom'` (마이그레이션으로 'linear' 로 변환) → 목록/상세에서 `.displayName` 은 전부 `'나열'` 로 표시되어 과거 구분 손실** | minor | `mobile/lib/features/reading/presentation/pages/reading_list_page.dart:46,76,182`, `reading_detail_page.dart:82`, Brief Out of Scope #6 "reading 마이그레이션 시 위치 의미 보존 — 기존 `threeCard`의 위치 의미는 손실됨" | Out of Scope #6 가 이를 이미 수용 (위치 의미 손실). 단 "`displayName` 도 일괄 `'나열'` 로 표시됨" 을 한 줄 명시해 리뷰어 혼동 제거 |
| 14 | Brief Decision 14/15 의 GridView 접근이 `SpreadLayout` 의 부모가 `Expanded(Padding(SpreadLayout))` (`draw_result_page.dart:226-239`) 이고 `Expanded`가 유한 높이 제공 → `shrinkWrap: true + physics: NeverScrollableScrollPhysics` 필요 없음 (R-009 Caveat에서 '필요 시'로 언급). **단 `reading_detail_page.dart` 는 SpreadLayout을 호출하지 않음** — 상세 페이지 카드 목록은 `ListView`/`Column` 에 텍스트 형태로만 표시. 배치 시각화는 결과 페이지에만 노출 | minor | `mobile/lib/features/reading/presentation/pages/reading_detail_page.dart:138-194` (텍스트 리스트만), `mobile/lib/features/draw/presentation/pages/draw_result_page.dart:226-239` | Out of Scope 또는 Model Anchors 에 "결과 페이지에만 SpreadLayout 노출, 상세 페이지는 텍스트 리스트 형태 유지" 명시 (revisit 방지) |
| 15 | `readings` 테이블의 **외래키 `readings.deck_id REFERENCES decks(id)` 존재** (`drift_schema_v7.json` readings entity `"foreign_key":{"to":{"table":"decks","column":"id"}}`). Brief Decision 16 의 "이번 작업에 외래키 영향 없음" 은 사실 **부분적으로 맞음**(작업이 spread_type 값 UPDATE + user_settings 컬럼 rename 이라 readings.deck_id 는 영향 없음). 단 PRAGMA foreign_keys OFF/ON 토글을 ALTER TABLE RENAME COLUMN 앞뒤에 두면 trigger/view 연쇄 영향을 자동 회피 — 그래서 R-008-F7 권장이 합리적 | minor | `mobile/drift_schemas/drift_schema_v7.json` readings.deck_id foreign_key 구조 | 현 Decision 16 유지. 추가 조치 없음 |

### Missing Elements

| # | What's Missing | Why It Matters | Suggestion |
|---|---------------|----------------|------------|
| 1 | **UserSettings 도메인 (freezed + g.dart + repository + table) 의 LayoutType 전환 명시** | In Scope #3 은 DB 컬럼 rename만 언급하고 Dart-side freezed 필드 rename (`defaultSpreadType: SpreadType` → `defaultLayoutType: LayoutType`) + repository 매핑 (`SpreadType.values.byName(row.defaultSpreadType)` → `LayoutType.values.byName(row.defaultLayoutType)`) 은 함축적으로만 수용됨. build_runner 재실행으로 `user_settings.g.dart` 의 `_$SpreadTypeEnumMap` 2번째 복사본이 `_$LayoutTypeEnumMap` 으로 교체되는 것도 확인 필요 | In Scope #3 를 "readings.spread_type + user_settings.default_spread_type" 2경로로 분리. "**Dart 도메인: UserSettings.defaultSpreadType → defaultLayoutType, build_runner 재생성으로 g.dart 2곳 (`reading.g.dart`, `user_settings.g.dart`) 의 `_$SpreadTypeEnumMap` → `_$LayoutTypeEnumMap` 자동 교체 확인**" 행 추가 |
| 2 | **`draw_result_page.dart` + `animated_draw_page.dart` 의 `_spreadType.cardCount` 의존 제거 계획** | LayoutType 에는 `.cardCount` 가 **없음** (cardCountMin/Max + defaultCardCount만) — `_currentCardCount = _spreadType == SpreadType.custom ? settings?.defaultCardCount ?? 3 : _spreadType.cardCount` 로직은 "enum 값별 고정 cardCount" 를 전제. 전환 시 `_currentCardCount = settings?.defaultCardCount.clamp(layoutType.cardCountMin, layoutType.cardCountMax) ?? layoutType.defaultCardCount` 로 재작성 필요. Brief 에 이 로직 재설계 명시 없음 | In Scope #5 (배치 선행 선택 + 동적 슬라이더 제약) 에 "**draw page 2개 (`animated_draw_page.dart:53-56`, `draw_result_page.dart:53-56`) 의 cardCount 결정 로직을 `settings.defaultCardCount.clamp(layoutType.cardCountMin, layoutType.cardCountMax)` 로 통일**" 명시 |
| 3 | **`_$SpreadTypeEnumMap` 2곳 중복 처리 (`reading.g.dart:33`, `user_settings.g.dart:49`)** | json_serializable 는 각 freezed 엔티티별로 로컬 Enum Map 생성. rename 시 두 곳 모두 `_$LayoutTypeEnumMap` 으로 자동 교체되지만, grep confirmation gate 는 2곳 모두 확인해야 함 | Constraints §confirmation gate 에 "`grep -n '_\\$LayoutTypeEnumMap' mobile/lib/features/*/domain/entities/*.g.dart` 결과가 **2곳**(`reading.g.dart`, `user_settings.g.dart`) 확인" 명시 |
| 4 | **reading_dao.dart:63 `watchReadingsBySpreadType(String spreadType)` 의 쿼리는 String 파라미터 → LayoutType rename 무영향** 이나, reading_list_page 의 필터 chip loop (`for (final type in SpreadType.values)`, line 42) 은 enum 순회이므로 영향 | 필터 chip 아이콘 교체 In Scope #7 이 커버하나 "enum values 순회 교체" 는 명시 안 됨 | In Scope #7 에 "`reading_list_page.dart:42` `for (final type in LayoutType.values)` 로 enum 순회 자동 갱신" 명시 |
| 5 | **기존 reading 데이터의 `drawnCards[].position` 의미 보존/손실 명시** | Brief Out of Scope #6 "위치 의미 보존 안 함" 명시했으나, drawnCards 의 position 정수 자체는 유지됨. 단 마이그레이션 후 `LayoutType.linear.drawToSlot(i) = i` 이므로 시각적 배치는 기존 threeCard row 구조에서 linear 3-wide grid 로 **변경됨** — 사용자가 과거 리딩을 열어보면 레이아웃 변경 경험 | Out of Scope #6 에 "결과 페이지 재표시 시 과거 threeCard 리딩은 linear grid 로 렌더되어 row→grid 변경이 보임" 한 줄 명시 |
| 6 | **`drift_schemas/` + `test/generated_migrations/` 이 이미 존재함을 Brief가 인식하지 못함** | 불필요한 prerequisite 반복 또는 "이미 수행된 단계를 명령어로 기술" 하여 impl 사이클 2가 첫 실행 코드인 것처럼 보임. 실제는 **schemaVersion v7 기준** dump이므로 v8 전환 후 다시 dump 필요한 시점 확인 | Brief Constraints §codegen 에 "※ v7 schema snapshot 은 `mobile/drift_schemas/drift_schema_v7.json` 에 이미 존재 (2026-04-20 기준). impl 사이클 2 는 v8 전환 후 추가 v8 snapshot dump (`dart run drift_dev schema dump ... drift_schemas/`) 수행" 명시 |
| 7 | **실제 `Reading.freezed.dart` 의 `@JsonKey` 사용 분석 없음** | R-007-F1 이 "annotation 없음 → 기본 처리" 라 주장하나, 실제는 freezed 가 `@JsonKey(includeFromJson: false, includeToJson: false)` 를 자동 주입 (라인 36, 242, 249, 293, 313, 441, 447, 480). 이 annotation 은 freezed 내부 meta-field 용이라 SpreadType 필드 자체에는 annotation 없음 — R-007-F1 은 본질적으로 정확 | Brief 변경 불필요. 단 Critique 관점에서 "@JsonKey 존재 는 freezed 자동 주입, SpreadType 필드에는 annotation 없음" 을 Brief 또는 R-007 각주로 명시 권장 |

## Detailed Analysis

### In Scope 항목별 검증

**#1 도메인 모델 진화 (enhanced enum + computed properties)**
- `spread_type.dart` 현재는 이미 enhanced enum 패턴 (`cardCount`, `positions`, `guidances`, `resolvePositions(int)`, `resolveGuidances(int)` 메서드) — Brief 에 언급 없으나 구조적으로 이미 enhanced. LayoutType 전환은 필드 교체·메서드 이름/시그니처 교체 + R-007 prototype의 `emptySlots`, `drawToSlot`, `slotCount`, `displayName` 추가. `resolvePositions`/`resolveGuidances` 는 R-009 prototype에서 `positions` 호출은 있으나 (line 426) R-007 prototype 에 정의 없음 — **Weakness #8 근거**.
- DrawnCardInfo 는 enum 필드 없음 → 영향 없음.

**#2 3 배치 제약 매트릭스**
- Brief Model Anchors 매트릭스와 R-007 Prototype `LayoutType` final instance vars + `drawToSlot` switch 블록 완전 일치. 단위 테스트 가능.

**#3 DB 스키마 v7→v8 마이그레이션**
- `app_database.dart:25,28-70` 과 Brief Model Anchors §DB 마이그레이션 정책 완전 일치.
- `readings.spread_type` 은 `TextColumn get spreadType => text()();` (readings_table.dart:8) — TypeConverter/default 없음 확인.
- `user_settings.default_spread_type` 은 `TextColumn get defaultSpreadType => text().withDefault(const Constant('custom'))();` (user_settings_table.dart:15-16). Rename 후 `default_layout_type` 컬럼에 `withDefault(const Constant('linear'))` 필요 — Brief 에 명시 없음 (기본값 전환). 이는 Weakness 수준은 아니지만 Migration SQL 이후 `user_settings_table.dart` 의 `withDefault` 도 `'linear'` 로 갱신 필요.

**#4 홈 패널 "모양" 그룹 신설** — Weakness #3, #4 참조. 실제 `_DrawSettingsPanel` 는 이미 큰 규모 (line 340-562, 약 220줄). 재구성은 구조적 refactor 수준.

**#5 배치 선행 선택 + 동적 슬라이더 제약**
- 현재 카드 수는 `_CountStepper` (home_page.dart:443-448) 로 min=1, max=10 고정. 배치 변경 시 min/max 전달 값 동적 변경은 `_CountStepper` 재사용 가능.
- `_PillSelector<int>` (한 줄 카드 수, line 510-518) 회색 비활성 처리는 `_PillSelector` 자체에 `disabled` prop 없음 — **추가 prop 필요**. Brief Constraints §컴포넌트 재사용 의 "비활성 슬라이더에 한정" 은 이를 함축하나 명시 X.
- Missing Element #2 참조 — draw page 2개의 cardCount 결정 로직 재작성.

**#6 결과 페이지 슬롯 기반 렌더링 (GridView + CustomPaint)**
- `spread_layout.dart` 현재는 106줄 (Brief 107줄 claim과 1 차이, tolerable). switch 분기 3개 (single/threeCard/custom), custom 이 이미 `GridView.builder + crossAxisCount: 3` — Brief 의 "모든 LayoutType 이 동일 GridView 인프라" 전환은 threeCard 의 `Row+Expanded` 과 single 의 `Center` 를 버리고 custom 구조로 통일. 실현 가능.
- `CardRevealWidget` (card_reveal_widget.dart 205줄) StatefulWidget + AnimationController + `AspectRatio` 내부 (line 124, 167) — GridView cell 에 직접 투입 가능. R-009-F6 정확.

**#7 목록/상세 페이지 호환**
- `reading_list_page.dart:42,210-215` 필터 chip + `_spreadTypeIcon` switch 는 LayoutType enum 그대로 교체 가능.
- `reading_detail_page.dart:76-77,82,171,182` — Weakness #8 (resolvePositions 메서드) 참조.

**#8 3x3 드로우 순서 설정 메뉴** — 새 UI 위젯. `_PillSelector<String>` + disabled 옵션 추가 필요 (#5 와 동일 `_PillSelector` 확장 필요).

**#9 +N 드로우 정책: cardCount 슬라이더로 통합** — Weakness #9 참조. `_addOneMore` 제거 필수.

**#10 Drift schema 스냅샷 관리 + 마이그레이션 테스트 인프라** — Missing Element #6 참조. prerequisite 1~3 이미 수행됨.

### Decisions 항목별 검증

Decision 1~3 (용어/enum 명): 충돌 없음.
Decision 4 (배치 변경 시 즉시 강제): Weakness #5 — DB 값 동기화 정책 미명시.
Decision 5 (DB 마이그레이션): Weakness #10, #11 — 필터 SQL 보수성.
Decision 6 (UserSettings 필드명): Missing Element #1 — 전체 Dart side 동반 변경 함의 누락.
Decision 7 (T모양 카드 수): 충돌 없음.
Decision 8 (positions generic): Weakness #8 — resolvePositions 메서드 부재.
Decision 9 (cardCount 슬라이더 통합): Weakness #9 — 결과 페이지 기존 `_addOneMore` 제거 누락.
Decision 10,11 (슬롯 매핑): R-007 prototype 과 일치. 단위 테스트 매트릭스 근거.
Decision 12 (3x3 드로우 순서 메뉴): `_PillSelector` 확장 필요.
Decision 13 (enhanced enum + computed properties): R-007-F1~F7 로 뒷받침, Strength #3, #12.
Decision 14 (GridView): Strength #8, Weakness #14.
Decision 15 (CustomPaint DashedRect): Strength #10.
Decision 16 (트랜잭션 wrap): Strength #2.
Decision 17 (Schema snapshot): Strength #11 + Missing Element #6.

### Context 클레임 검증

- Brief Context §현재 구조의 충돌 지점 — 정확. (현재 홈 패널은 카드 수 + 스프레드 + 한 줄 카드 수 모두 별도 행 존재.)
- Brief Context §DB 현황 — Strength #2, Missing Element #6.
- Brief Context §출시 단계 가정 — `pubspec.yaml:3` `version: 0.1.0` (Brief claim `0.1.1` 과 **0.1.0 불일치**). 경미.
- Brief Context §슬롯·드로우 매핑 시각화 — R-007 prototype switch 와 일치.

### Pipeline 메타데이터 검증

- Brief 011 frontmatter `traces_scope: "006"` 는 짧은 ID 참조 — Scope 006 실재 (`006_Scope_layout_redesign.md`). Valid.
- Scope 006 frontmatter `traces_brief: "docs/15_draw_experience_settings/005_Brief_layout_redesign.md"` — **경로 오류**. 실제 경로 `docs/2_tarot_draw/03_draw_experience_settings/005_Brief_layout_redesign.md`. Weakness #7.
- 003, 004 문서도 동일 오류. 11개 중 3개 문서의 `traces_brief` 가 구 경로.
- commit 9d11a36 (chore(docs): restructure to 3-level N_/NN_/NNN_ layout) 에서 폴더 재구성 시 frontmatter 미갱신.

## Recommendations for Brief Revision

1. **In Scope #1 에 "UserSettings 도메인 동반 변경" 추가** — `defaultSpreadType → defaultLayoutType`, `user_settings.g.dart`/`user_settings_repository_impl.dart:113`/`user_settings.dart:19` 3 callsite 리스트. Missing Element #1.

2. **In Scope #5 에 "draw page 2개의 cardCount 결정 로직 재작성" 추가** — `animated_draw_page.dart:53-56` 과 `draw_result_page.dart:53-56` 의 `_currentCardCount = _spreadType == SpreadType.custom ? ... : _spreadType.cardCount` 로직을 `defaultCardCount.clamp(...)` 로 교체. Missing Element #2.

3. **In Scope #7 에 "draw_result_page.dart 의 `_addOneMore` 메서드 + '+N장' 버튼 제거" 추가** — Weakness #9. Decision 9 가 이를 함축하나 파일/라인 명시 필요.

4. **Context §SpreadType 참조 분포 표 보강** — 누락 행 3개 추가: UserSettings/Settings repository/Draw page 2개. "현재"/"목표" 열 추가. Weakness #1, #2, #3.

5. **In Scope #4 를 실측 기반으로 재작성** — 현재 `_DrawSettingsPanel` 의 실제 구조(덱·레벨·카드 수·스프레드·역방향 5행 + 앞면·카드 이름·한 줄 카드 수·카드 크기 4행)를 앞단에 명시한 뒤, 목표 3그룹 구조로 재구성. Weakness #4.

6. **Decision 13 또는 In Scope #1 에 "LayoutType.resolvePositions(int) → List<String>" 메서드 추가** — R-009 prototype이 이 메서드를 호출하나 R-007 prototype 에 없음. `reading_detail_page.dart:76` 도 의존. Weakness #8.

7. **Decision 4 또는 Model Anchors 에 "tShape/grid3x3 선택 시 DB cards_per_row 값 정책(유지/덮어쓰기)" 명시** — Weakness #5.

8. **Constraints §codegen 를 "이미 수행된 prerequisite" 로 업데이트** — `drift_schemas/drift_schema_v7.json` + `test/generated_migrations/schema_v7.dart` 이미 존재. Missing Element #6.

9. **Scope 006 의 `traces_brief` 메타데이터 경로 정정** — 별도 작업으로 분리 가능. Weakness #7.

10. **Constraints §confirmation gate 에 `_$LayoutTypeEnumMap` 2곳 확인 명시** — Missing Element #3.

11. **Context §출시 단계 가정의 `pubspec.yaml v0.1.1` → `v0.1.0` 정정** — 경미.

12. **Exit Criteria 에 "draw page 2개의 cardCount 로직 재작성", "`_addOneMore` 제거", "UserSettings 동반 rename" 3개 체크박스 추가** — 위 1~3 수용 시 자동 파생.

## References

| Resource | Path | Relevance |
|----------|------|-----------|
| Brief 011 | `/Users/kampikrein/A/personality/docs/2_tarot_draw/03_draw_experience_settings/011_Brief_layout_redesign.md` | Primary target |
| Research 007 | `.../007_Research_enhanced_enum_codegen.md` | Decision 13 근거, Prototype |
| Research 008 | `.../008_Research_drift_migration_pattern.md` | Decision 5, 16, 17 근거 |
| Research 009 | `.../009_Research_slot_based_rendering.md` | Decision 14, 15 근거 |
| Synthesis 010 | `.../010_Synthesis_layout_redesign_research.md` | 3 축 통합 |
| Scope 006 | `.../006_Scope_layout_redesign.md` | 파이프라인 상위, `traces_brief` 경로 오류 원천 |
| pubspec.yaml | `/Users/kampikrein/A/personality/mobile/pubspec.yaml` | 버전 매트릭스 (Strength #1) |
| app_database.dart | `/Users/kampikrein/A/personality/mobile/lib/core/database/app_database.dart` | schemaVersion + onUpgrade 6 블록 (Strength #2) |
| readings_table.dart | `/Users/kampikrein/A/personality/mobile/lib/core/database/tables/readings_table.dart` | spread_type 컬럼 (Strength #6) |
| user_settings_table.dart | `/Users/kampikrein/A/personality/mobile/lib/core/database/tables/user_settings_table.dart` | default_spread_type + cardsPerRow nullable (Weakness #5) |
| spread_type.dart | `/Users/kampikrein/A/personality/mobile/lib/features/reading/domain/entities/spread_type.dart` | 현 enum (이미 enhanced 구조) |
| reading.dart + freezed + g.dart | `/Users/kampikrein/A/personality/mobile/lib/features/reading/domain/entities/reading.{dart,freezed.dart,g.dart}` | _$SpreadTypeEnumMap 위치 #1 (Strength #3) |
| reading_repository_impl.dart | `/Users/kampikrein/A/personality/mobile/lib/features/reading/data/repositories/reading_repository_impl.dart` | `.name`/`byName` 패턴 (Strength #5) |
| reading_dao.dart | `/Users/kampikrein/A/personality/mobile/lib/core/database/daos/reading_dao.dart` | watchReadingsBySpreadType (String 파라미터 → 영향 없음) |
| reading_providers.dart | `/Users/kampikrein/A/personality/mobile/lib/features/reading/presentation/providers/reading_providers.dart` | Provider 필터 (SpreadType 의존) |
| reading_list_page.dart | `/Users/kampikrein/A/personality/mobile/lib/features/reading/presentation/pages/reading_list_page.dart` | 필터 chip + icon switch (In Scope #7) |
| reading_detail_page.dart | `/Users/kampikrein/A/personality/mobile/lib/features/reading/presentation/pages/reading_detail_page.dart` | resolvePositions 호출 (Weakness #8) |
| spread_layout.dart | `/Users/kampikrein/A/personality/mobile/lib/features/reading/presentation/widgets/spread_layout.dart` | switch 렌더링 106줄 (In Scope #6) |
| card_reveal_widget.dart | `/Users/kampikrein/A/personality/mobile/lib/features/reading/presentation/widgets/card_reveal_widget.dart` | AspectRatio 내부 (Strength #8) |
| home_page.dart | `/Users/kampikrein/A/personality/mobile/lib/features/home/presentation/pages/home_page.dart` | _DrawSettingsPanel PillSelector (Weakness #3, #4) |
| user_settings.dart + freezed + g.dart | `/Users/kampikrein/A/personality/mobile/lib/features/settings/domain/entities/user_settings.{dart,freezed.dart,g.dart}` | defaultSpreadType 필드 + _$SpreadTypeEnumMap #2 (Missing Element #1, #3) |
| user_settings_repository_impl.dart | `/Users/kampikrein/A/personality/mobile/lib/features/settings/data/repositories/user_settings_repository_impl.dart` | byName 매핑 line 113 (Missing Element #1) |
| animated_draw_page.dart | `/Users/kampikrein/A/personality/mobile/lib/features/draw/presentation/pages/animated_draw_page.dart` | `_spreadType.cardCount` 의존 (Weakness #2) |
| draw_result_page.dart | `/Users/kampikrein/A/personality/mobile/lib/features/draw/presentation/pages/draw_result_page.dart` | `_addOneMore` + `_spreadType.cardCount` (Weakness #9, #2) |
| mystical_scaffold.dart | `/Users/kampikrein/A/personality/mobile/lib/core/widgets/mystical_scaffold.dart` | kSoftPurple 디자인 토큰 (Strength #10) |
| drift_schema_v7.json | `/Users/kampikrein/A/personality/mobile/drift_schemas/drift_schema_v7.json` | schema snapshot 이미 존재 (Strength #11) |
| generated_migrations | `/Users/kampikrein/A/personality/mobile/test/generated_migrations/{schema.dart,schema_v7.dart}` | v7 data classes 이미 존재 (Strength #11) |

## Completion

- Completion criteria: All 10 In Scope items + 17 Decisions + Context claims verified against codebase with file:line evidence — **충족**. 10 In Scope 항목, 17 Decisions, Context 의 버전 매트릭스/DB 현황/SpreadType 참조 분포/출시 단계 가정 각 항목을 실제 `.dart`, `.json`, `.yaml` 파일의 라인 번호로 검증했다. 미충족 항목은 모두 Weakness 테이블에 severity/evidence/recommendation 으로 기록.

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 0s | 0 |
| 2 | user-ai-exchange | 451s | 935162 |
| 3 | user-ai-exchange | 1554s | 4275267 |
| 4 | user-ai-exchange | 49s | 210710 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 31057s |
| Total Tokens | 5421139 |
| Input Tokens | 59 |
| Output Tokens | 77155 |
| Cache Read | 4817779 |
| Cache Creation | 526146 |
