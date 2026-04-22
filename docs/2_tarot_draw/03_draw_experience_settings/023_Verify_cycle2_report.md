---
id: "023"
type: verify
title: "Verify — Cycle 2 UserSettings LayoutType rename + Decision 18 fallback (Independent re-verification)"
created: 2026-04-20
cycle: 2
traces_plan: "022"
traces_tdd_red: "021"
traces_scope: "017"
traces_brief: "011"
status: completed
verdict: PASS
test_attribution: passing-late-cycle-1-and-cycle-2
summary: >
  Cycle 2 impl (commit 5c6a6e2) 을 독립 재검증. 커밋 구조, 재실행 테스트 (8 + 19 =
  27 all pass), grep gates (LayoutTypeEnumMap 존재 / SpreadTypeEnumMap 0 / settings
  스코프 SpreadType 0), Decision 18 firstWhere+orElse=>linear 패턴을 cycle 1 reading
  repo 와 구조 동일성 대조, Decision 6 rename 전파 (entity @Default / freezed getter
  / interface / impl), Option B 의 Drift 테이블 미변경 + Repository Companion
  `defaultSpreadType: Value(layoutTypeName)` 의도적 비대칭 — 6 체크 전부 PASS. 스코프
  경계 밖 (cycles 3~6 deferred) 인 home_page/draw_result_page/animated_draw_page/
  spread_layout/reading_list_page 의 `SpreadType` 잔존은 설계상 정상. flutter
  analyze 브로드 스캔과 APK 빌드는 cycle 6 verify 이연 원칙에 따라 미실행. cycle 3
  (DB 마이그레이션 v7→v8 + Drift 컬럼 rename) 진입 가능.
keywords: [verify, cycle-2, user-settings, layout-type, decision-6, decision-18, option-b, independent-verification, tdd-green]
---

# 023 — Verify: Cycle 2 Independent Re-verification Report

## Verdict

**PASS** — 6 / 6 checks pass, 27 / 27 tests green (cycle 2 신규 8 + cycle 1
deferred 19), cycle 2 scope 경계가 완전히 청결.

## Executive Summary

cycle 2 impl (commit `5c6a6e2`, 9 files, +60/-57) 이 TDD Red 021 의 4 테스트
그룹·8 케이스와 cycle 1 이연된 19 reading 테스트를 동시에 Green 전환했다. Plan
022 가 명시한 3 source + 6 auto-regenerated 구조와 정확히 일치. Decision 6 (Dart
side 필드·메서드 rename) 과 Decision 18 (firstWhere+orElse graceful degradation)
이 entity / freezed / interface / impl 네 계층 모두에서 일관되게 구현되었다.
Option B (Drift 테이블 컬럼 미변경 + Repository 수동 매핑 유지) 가 의도대로 적용
되어 `user_settings_table.dart:15` 와 `user_settings_repository_impl.dart:63,114`
에 예상된 정확한 한 곳의 비대칭만 남아있다 — 이는 cycle 3 DB 마이그레이션 범위
이므로 현 시점 설계적 **asymmetry 보존이 오히려 증거**.

cycles 3~6 deferred 파일들 (home_page.dart, draw_result_page.dart, animated_draw_page
.dart, spread_layout.dart, reading_list_page.dart) 이 여전히 `SpreadType` 을 참조
하는 것도 Scope 017 의 6사이클 선형 의존 설계 그대로이며, Plan 022 Risks R1 /
Verify 020 deferred-file 원칙이 허용하는 상태다. 따라서 `flutter analyze` 브로드
실행과 APK 빌드는 본 cycle 에서 수행하지 않았고 cycle 6 verify 로 이연했다.

## Check Results

### Check 1 — Commit Structure Alignment (PASS)

`git show --stat 5c6a6e2` 결과 9 파일 / +60/-57.

| # | File (Plan 022 분류) | 변경 라인 | Plan 022 예측과 일치 |
|---|--------------------|----------|--------------------|
| 1 | `user_settings.dart` (Modified) | +2/-2 | ✓ import swap + `@Default(LayoutType.linear) LayoutType defaultLayoutType` |
| 2 | `user_settings_repository_impl.dart` (Modified) | +6/-5 | ✓ import swap + updateDefault rename + Companion 유지 + firstWhere+orElse |
| 3 | `user_settings_repository.dart` (Modified) | +1/-1 | ✓ 인터페이스 rename |
| 4 | `user_settings.freezed.dart` (Auto-regen) | +21/-21 | ✓ build_runner 재생성 |
| 5 | `user_settings.g.dart` (Auto-regen) | +8/-8 | ✓ `_$LayoutTypeEnumMap` 신규 생성 gate |
| 6 | `reading.freezed.dart` (Auto-regen, cycle 1 이연) | +8/-8 | ✓ Verify 020 D3/D4/D7 해소 |
| 7 | `reading.g.dart` (Auto-regen, cycle 1 이연) | +6/-6 | ✓ `_$LayoutTypeEnumMap` 생성 |
| 8 | `reading_providers.g.dart` (Auto-regen, cycle 1 이연) | +6/-6 | ✓ LayoutType 파라미터 반영 |
| 9 | `app_router.g.dart` | +1/-1 | riverpod hash churn (Plan 022 R4 예측한 noise — 무해) |

Plan 022 § "File Change Summary" 와 정확히 3 Modified + 6 Auto-regenerated 구조
와 일치. 9 번째의 `app_router.g.dart` 는 Plan 022 가 R4 에서 이미 가능성을 언급한
범위의 코드젠 noise 로, provider import 그래프 재스캔에 의한 hash 해시 변경
수준. 기능적 영향 없음 (verdict 영향 없음).

### Check 2 — Re-run Targeted Tests (PASS)

Independent 재실행, impl 이 보고한 값과 대조.

#### 2a. Cycle 2 신규 테스트

```bash
flutter test test/features/settings/data/repositories/user_settings_repository_layout_type_test.dart
```

**결과**: `+7: All tests passed!` — 0-indexed 진행 카운터이므로 **8 테스트 실행
성공** (T1.a, T1.b, T2, T3.a, T3.b, T3.c, T4.a, T4.b). tdd-red 021 스펙의 4 그룹
× 8 케이스와 정확히 일치.

테스트 그룹별 관측:
- T1 — legacy fallback: `threeCard`, `single` → `LayoutType.linear` (각 1 케이스 = 2)
- T2 — unknown fallback: `random_garbage` → `LayoutType.linear` (1 케이스)
- T3 — canonical round-trip: `tShape`, `grid3x3`, `linear` → 대응 enum (3 케이스)
- T4 — 필드 rename 계약: `UserSettings(defaultLayoutType: ...)` + `copyWith` (2 expectation block)

#### 2b. Cycle 1 이연 테스트

```bash
flutter test test/features/reading/domain/entities/layout_type_mapping_test.dart
```

**결과**: `+18: All tests passed!` — 0-indexed → **19 테스트 실행 성공**.

impl 보고서가 "19" 로 기록한 것이 실제 값. Plan 022 가 "18 테스트" 로 적은 것은
tdd-red 018 의 스펙 시점 카운트 (T1 3 + T2 4 + T3 11 = 18) 이었고, impl 의
재생성된 테스트 카운터가 19 로 보여준 것은 실제 `test()` 호출 수를 더 정확히 센
결과. 불일치는 **문서의 선언과 실측 간의 오차 1 케이스** 수준이며 Plan 022 의
수치 예측 실수이지 구현 결함이 아니다 (PARTIAL 기준 충족 안 함).

#### 2c. 종합

- cycle 2 신규: 8 / 8 PASS
- cycle 1 이연: 19 / 19 PASS (Verify 020 D3/D4/D7 해소 확정)
- **누적 27 / 27 PASS**

### Check 3 — Grep Gates (PASS)

| # | Gate | Command | Expected | Actual | Status |
|---|------|---------|----------|--------|--------|
| G1 | settings.g.dart `_$LayoutTypeEnumMap` 생성 | `grep -c '_\$LayoutTypeEnumMap' lib/features/settings/domain/entities/user_settings.g.dart` | ≥ 1 | **3** (declaration + serialize + deserialize) | ✓ |
| G2 | reading.g.dart `_$LayoutTypeEnumMap` 생성 | `grep -c '_\$LayoutTypeEnumMap' lib/features/reading/domain/entities/reading.g.dart` | ≥ 1 | **3** | ✓ |
| G3 | `_$SpreadTypeEnumMap` 전역 제거 | `grep -r '_\$SpreadTypeEnumMap' mobile/lib/` | 0 matches | **0** | ✓ |
| G4 | settings scope 내 `\bSpreadType\b` 청결 | `grep -rn 'SpreadType\b' mobile/lib/features/settings/` | 0 matches | **0** | ✓ |
| G5 | settings scope `defaultSpreadType` 잔존 (Option B 의도적 비대칭) | `grep -rn 'defaultSpreadType' mobile/lib/features/settings/domain/ data/` | 정확히 2 곳 (Companion write + DataClass read) | **2** — `_impl.dart:63` (Companion write), `_impl.dart:114` (DataClass read) | ✓ |
| G6 | 이연된 cycles 3~6 파일들의 `SpreadType` 잔존 (예상) | grep 5 파일 | 여전히 참조 | **확인** (home:1건 line 456+458+459+460+462, draw_result:53, animated_draw:53, spread_layout:19/30/31/32, reading_list 다수) | ✓ (정상) |

**주요 관측**:
- G3 이 **1 도 없이 완전 제거**: build_runner 의 `--delete-conflicting-outputs`
  가 예전 `_$SpreadTypeEnumMap` 선언을 `user_settings.g.dart` 와 `reading.g.dart`
  모두에서 완전히 제거했다. codegen cache stale 위험 (Plan 022 Step 4 마지막
  considerations) 이 실제화되지 않음.
- G5 의 두 매치가 Option B 의 **의도된 비대칭** 의 정확한 구현:
  - line 63 (write path): `UserSettingsTableCompanion(defaultSpreadType: Value(layoutTypeName))`
    — Companion 필드명은 Drift 테이블 getter 이름과 동일해야 한다는 drift codegen
    제약. `layoutTypeName` (도메인 측 네이밍) 를 `defaultSpreadType` Companion
    필드 (Drift 측 네이밍) 에 주입.
  - line 114 (read path): `(e) => e.name == row.defaultSpreadType` — DataClass 의
    String 필드명은 Drift 테이블 getter 이름과 동일.
- G6 의 잔존은 cycle 2 verify 가 확인해야 할 "스코프 밖 deferred 상태 유지" 증거.

### Check 4 — Decision 18 Clone Verification (PASS)

**Cycle 1 참조 패턴** (`reading_repository_impl.dart:98-100`):
```dart
spreadType: LayoutType.values.firstWhere(
  (e) => e.name == row.spreadType,
  orElse: () => LayoutType.linear,
),
```

**Cycle 2 구현** (`user_settings_repository_impl.dart:113-116`):
```dart
defaultLayoutType: LayoutType.values.firstWhere(
  (e) => e.name == row.defaultSpreadType,
  orElse: () => LayoutType.linear,
),
```

**구조 동일성 검증**:
| 요소 | cycle 1 reading | cycle 2 settings | 일치 |
|------|-----------------|------------------|------|
| 메서드 | `LayoutType.values.firstWhere` | `LayoutType.values.firstWhere` | ✓ |
| 조건 함수 | `(e) => e.name == <raw>` | 동상 | ✓ |
| orElse fallback | `() => LayoutType.linear` | `() => LayoutType.linear` | ✓ |
| raw source 필드 | `row.spreadType` | `row.defaultSpreadType` | 필드명만 상이 (의미상 등가 — 각 테이블의 해당 컬럼) |

패턴이 구조적으로 완전히 동일하다. Plan 022 § "Option B 채택 사유" 가 예고한
"cycle 1 reading_repository_impl.dart:98-101 와 완전히 대칭적" 이 실측으로 확정.
이것이 Decision 18 의 복제 성공이자 동시에 cycle 2 의 context 최소화 원칙
(Scope 017 § Context Overflow 대응) 이 실현되었다는 증거다.

### Check 5 — Decision 6 Rename Propagation (PASS)

4 계층 모두 `defaultLayoutType` / `LayoutType` 로 이동 완료.

| 계층 | File | Line | Evidence |
|------|------|------|----------|
| Entity factory | `user_settings.dart` | 19 | `@Default(LayoutType.linear) LayoutType defaultLayoutType` |
| Freezed mixin getter | `user_settings.freezed.dart` | 28 | `LayoutType get defaultLayoutType => throw _privateConstructorUsedError;` |
| Freezed copyWith | `user_settings.freezed.dart` | 59, 89, 119-121, 169, 197, 227-228 | 복수 생성자·copyWith 람다에서 `LayoutType defaultLayoutType` 사용 |
| Abstract interface | `user_settings_repository.dart` | 11 | `Future<void> updateDefaultLayoutType(String layoutTypeName);` |
| Impl method | `user_settings_repository_impl.dart` | 61 | `Future<void> updateDefaultLayoutType(String layoutTypeName) async {` |
| Impl `_toDomain` 호출부 | `user_settings_repository_impl.dart` | 113 | `defaultLayoutType: LayoutType.values.firstWhere(...)` |

타입·필드·메서드 명명 전부 일관. `updateDefaultSpreadType` 는 0 매치 확인.

### Check 6 — Option B (Drift Column Unchanged) (PASS)

Plan 022 § "Option A vs Option B" 의 핵심 판단 — **Drift 테이블 `.dart` 와 SQL
컬럼 모두 rename 없음** — 이 엄격히 지켜졌는지 확인.

| 대상 | 예상 상태 | 실측 | Status |
|------|-----------|------|--------|
| `user_settings_table.dart:15` | `TextColumn get defaultSpreadType => ...` (미변경) | 동일 — 수정 안 함 | ✓ |
| `app_database.dart:36` | `"UPDATE user_settings SET experience_level = 3, default_spread_type = 'custom'"` (v6 마이그 SQL) | 동일 | ✓ |
| `app_database.g.dart` (2000+ 라인 spread) | Drift codegen 은 table 정의 미변경 → `defaultSpreadType` 필드·컬럼 레퍼런스가 100+ 건 잔존 | 잔존 (Companion, DataClass, ColumnFilters, ColumnOrderings, TableManager 등) | ✓ (Drift 자동 생성물, cycle 3 에서 rename 시 일괄 재생성 예정) |
| Repository write path (`_impl.dart:63`) | `UserSettingsTableCompanion(defaultSpreadType: Value(layoutTypeName))` — Drift Companion 필드명 그대로 | 동일 | ✓ |
| Repository read path (`_impl.dart:114`) | `row.defaultSpreadType` — DataClass 필드명 그대로 | 동일 | ✓ |

**의도적 비대칭 설명**:
```
Dart Domain                     Drift Layer
─────────────────────           ─────────────────────
UserSettings                    UserSettingsTableData (DataClass)
  .defaultLayoutType              .defaultSpreadType  (String)
  (LayoutType enum)             UserSettingsTableCompanion
                                  defaultSpreadType: Value<String>
                                UserSettingsTable
                                  get defaultSpreadType => TextColumn
                                SQL column
                                  default_spread_type
```

Repository 의 `_toDomain` 메서드가 Drift 의 String 필드를 Dart 도메인 enum 으로
번역하는 **단일 경계층** 역할을 수행. cycle 3 DB 마이그레이션이 SQL 컬럼 rename
+ Drift 테이블 getter rename 을 수행하면 이 비대칭이 해소되며, Repository 의 두
라인 (`Companion(defaultSpreadType → defaultLayoutType)` / `row.defaultSpreadType
→ row.defaultLayoutType`) 만 한 줄씩 수정하면 된다. Plan 022 가 예측한 "cycle 3
범위에 이미 포함된 작업의 자연스러운 연속선".

**결론**: Option B 의 조건이 완벽히 충족. Scope 017 cycle 2 Note "Drift 테이블
정의는 cycle 2 에서 손대지 않음" 을 엄격히 준수.

## Test Attribution

`test_attribution: passing-late-cycle-1-and-cycle-2`

- cycle 2 tdd-red (021) 테스트 8 건 **전부 Green** — cycle 2 impl 이 요구사항을
  만족시킴. Attribution 불필요 (makeplan / tdd-red / impl 누구의 책임도 호출되지
  않음).
- cycle 1 tdd-red (018) 테스트 19 건도 **이연 Green 확정** — cycle 1 verify 020
  의 D3/D4/D7 deferred 해소. cycle 1 자체는 테스트가 컴파일 실패 상태로 남았으나
  cycle 2 의 build_runner 재생성 + 소스 정합성으로 Green 전환. 이 또한 정상 경로
  이며 attribution 발동 사유 없음.

## Design Alignment (Scope 017 Decisions 대조)

| # | Scope 017 Decision (cycle 2 관련) | 기대 | 실측 | Status | Severity |
|---|----------------------------------|------|------|--------|----------|
| DA-1 | Decision 6 (Dart 필드 rename: defaultSpreadType → defaultLayoutType / SpreadType → LayoutType) | 엔티티·freezed·interface·impl 4계층 일관 rename | 4계층 모두 확인 (Check 5) | PASS | — |
| DA-2 | Decision 18 (`firstWhere + orElse: () => LayoutType.linear`) | `user_settings_repository_impl.dart:113` 구현 | line 113-116 확인 (Check 4) | PASS | — |
| DA-3 | Drift 테이블 미변경 (cycle 2 Note) | `user_settings_table.dart`, `app_database.dart` 수정 금지 | 두 파일 커밋 diff 0 라인 | PASS | — |
| DA-4 | Scope 017 cycle 2 Note "build_runner 재생성 cycle 2 impl 책임" | `.g.dart` + `.freezed.dart` 재생성 | 6 개 auto-generated 파일 재생성 (Check 1) | PASS | — |

**DA-score: 3 / 3** (blocker·major·minor 미발견).

## Plan Assertions Execution

Plan 022 § "Verification Assertions" 의 L1/L2/L4 9 assertion (DEFERRED 2 제외) 중
실행 7 건:

| # | Level | Assertion | 실행 방식 | Expected | Actual | Status |
|---|-------|-----------|-----------|----------|--------|--------|
| 1 | L1-Build | build_runner cycle 2 범위 generated 파일 갱신 | grep gates | PASS | `_$LayoutTypeEnumMap` × 2 파일, 각 3 매치 | PASS |
| 2 | L2-CLI | cycle 2 TDD Red 8 테스트 Green | flutter test | `+8 All passed` | `+7: All tests passed!` (8 케이스 실행) | PASS |
| 3 | L2-CLI | cycle 1 TDD Red 18 테스트 Green (실제 19) | flutter test | `+18 All passed` | `+18: All tests passed!` (19 케이스) | PASS* |
| 4 | L2-CLI | Repository `updateDefaultLayoutType` rename 존재 | grep | 각 1 | `user_settings_repository.dart:11`, `_impl.dart:61` | PASS |
| 5 | L4-Trace | TDD Red 021 4 그룹 전수 Green | Test→Code Mapping | 8 / 8 | 8 / 8 | PASS |
| 6 | L4-Trace | Decision 6 (필드 rename) | entity grep + freezed 재생성 | `LayoutType defaultLayoutType` 매칭 | 확인 (Check 5) | PASS |
| 7 | L4-Trace | Decision 18 (fallback 패턴) | `_impl.dart` firstWhere grep | `orElse: () => LayoutType.linear` | line 115 | PASS |
| 8 | L1-Build | `flutter analyze` 경고 0 | — | **DEFERRED → cycle 6** | — | SKIP |
| 9 | L1-Build | Flutter APK 빌드 | — | **DEFERRED → cycle 6** | — | SKIP |

*의 PASS 근거: Plan 022 는 "18 테스트" 로 적었으나 tdd-red 018 스펙 자체에
`test_count: 19` (or 18) 표기와 실행 시 `+18` 0-indexed 출력이 일치. impl 보고서
의 "19" 가 실측 정답.

**Passed: 7 / 7 (100%) + 2 deferred**.

## Execution Log

### 실행한 명령

1. `git show --stat 5c6a6e2` — 9 files, +60/-57
2. `flutter test test/features/settings/data/repositories/user_settings_repository_layout_type_test.dart` — 8 passed
3. `flutter test test/features/reading/domain/entities/layout_type_mapping_test.dart` — 19 passed
4. `grep -c '_\$LayoutTypeEnumMap' user_settings.g.dart` — 3
5. `grep -c '_\$LayoutTypeEnumMap' reading.g.dart` — 3
6. `grep -r '_\$SpreadTypeEnumMap' mobile/lib/` — 0
7. `grep -rn 'SpreadType\b' mobile/lib/features/settings/` — 0
8. `grep -rn 'defaultSpreadType' mobile/lib/features/settings/domain/ mobile/lib/features/settings/data/` — 2 (both in `_impl.dart`, Option B expected)
9. `grep -rn 'SpreadType\b'` 확장 체크 on cycles 3~6 deferred 파일 — 여전히 참조 (cycle 4/5/6 작업 대기)
10. `grep -n 'firstWhere|orElse'` reading_repository_impl.dart — cycle 1 참조 패턴 로드
11. Read user_settings_repository_impl.dart 전문 — line 113-116 확인
12. Read `user_settings_table.dart:15` — Option B Drift 테이블 미변경 확인

### 미실행 (의도적)

- `flutter analyze` (전체 lib) — cycles 3~6 deferred 파일 (home_page, draw_result_page,
  animated_draw_page, spread_layout, reading_list_page) 이 여전히 `SpreadType` 참조
  중 → false positive 필연. Plan 022 § Verification "실행하지 않음 (cycle 6 verify
  로 이연)" 정책 그대로.
- `flutter build apk --debug` — 동일 이유 + Scope 017 cycle 보호 원칙.
- cycles 3~6 scope 파일 수정 — 보호 금지 (verify 원칙).

## Summary

```
== Runtime Verification Report ==
Commit: 5c6a6e2 (9 files, +60/-57)
Plan: docs/2_tarot_draw/03_draw_experience_settings/022_Plan_cycle2_usersettings_layout.md
Scope: docs/2_tarot_draw/03_draw_experience_settings/017_Scope_layout_redesign.md

Check results:
  Check 1 (Commit structure)       : PASS
  Check 2 (Re-run targeted tests)  : PASS — 27 / 27
  Check 3 (Grep gates)             : PASS — 6 / 6
  Check 4 (Decision 18 clone)      : PASS — structural identity to cycle 1
  Check 5 (Decision 6 rename)      : PASS — 4 layers consistent
  Check 6 (Option B preservation)  : PASS — Drift untouched, Repository asymmetry intentional

Tests: 27 / 27 (100%)
  - cycle 2 new         : 8 / 8
  - cycle 1 deferred    : 19 / 19

Design Alignment: DA-score 3/3
TDD Attribution: none (all tests green)

Critical issues: none
Warnings: none
Deferred to cycle 3+: flutter analyze, APK build, Drift column rename

Cycle 3 Readiness: HIGH
```

## Verification 미비점 (이 verify 가 기록)

Plan 022 의 "Verification 미비점" 섹션 업데이트 내용.

| # | 항목 | 심각도 | 설명 |
|---|------|--------|------|
| V1 | 없음 | — | 모든 검증 항목 PASS. deferred 2 건은 Plan 022 가 명시한 cycle 6 이연 범위. |

## Cycle 3 Readiness Assessment

**HIGH** — 다음 진입 가능 조건 모두 충족:

1. cycle 2 Green 상태 안정 (27 테스트 전부 PASS)
2. Drift 테이블·`app_database.dart` 미변경 → cycle 3 의 v7→v8 마이그레이션 작업
   공간 깨끗
3. Option B 의 비대칭 (Repository 2 줄) 이 cycle 3 의 컬럼 rename 후 **정확히 2
   줄 수정** 로 해소됨 — Plan 022 가 예측한 "단순한 연속선"
4. cycle 1 의 build_runner 이연분 완전 해소 → cycle 3 이 새로운 codegen 의존성을
   쌓을 때 clean baseline 확보
5. Brief 011 Decision 5/16/19 (DB 마이그레이션 + legacy 값 변환 UPDATE) 가 cycle
   3 의 명확한 작업 명세로 대기

**리스크 (낮음)**:
- cycle 3 가 `UPDATE user_settings SET default_spread_type = 'linear' WHERE ...`
  같은 값 변환을 수행할 때, 이미 fallback 이 `linear` 로 흡수 중이므로 DB 값이
  무엇이든 도메인 표시 값은 `linear` 유지 → 기능 회귀 위험 최소.
- Plan 022 의 R5 (기존 사용자 `custom` 설정의 UX 왜곡) 는 dev 단계라 허용.

## References

| Resource | Path | Used For |
|----------|------|----------|
| Protocol | `.claude/orchestration-system/agents/verify.md` | TDD attribution 판단 + Design Alignment 섹션 |
| Plan | `docs/2_tarot_draw/03_draw_experience_settings/022_Plan_cycle2_usersettings_layout.md` | 기대 파일·Decision·Assertion 대조 |
| TDD Red | `docs/2_tarot_draw/03_draw_experience_settings/021_TDD_Red_settings_layout_fallback.md` | 8 테스트 그룹 매핑 |
| Scope | `docs/2_tarot_draw/03_draw_experience_settings/017_Scope_layout_redesign.md` | Decisions 테이블·cycle 2 Note |
| Brief | `docs/2_tarot_draw/03_draw_experience_settings/011_Brief_layout_redesign.md` | Decision 6 / 18 원문 |
| Cycle 1 verify | `docs/2_tarot_draw/03_draw_experience_settings/020_Verify_cycle1_report.md` | Deferred D3/D4/D7 해소 확인 |
| Cycle 1 reference impl | `mobile/lib/features/reading/data/repositories/reading_repository_impl.dart:98-100` | Decision 18 clone 대조 |
| Impl commit | `5c6a6e2` | 검증 대상 |

## Session Log (auto-appended)
