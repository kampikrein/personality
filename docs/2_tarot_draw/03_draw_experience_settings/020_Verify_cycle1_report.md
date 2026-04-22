---
id: "020"
type: verify
title: "Verify — Cycle 1 (LayoutType enum + Reading 레이어) 정적 검증"
created: 2026-04-20
cycle: 1
traces_plan: "019"
traces_tdd_red: "018"
traces_scope: "017"
traces_brief: "011"
status: completed
verdict: PASS
summary: >
  Cycle 1 구현 (commit `f88626d`) 을 정적 스코프로 검증. build_runner /
  flutter analyze / flutter test 는 Plan 019 Strategy 1 (cycle 2 UserSettings
  마이그레이션 완료 전에는 컴파일 실패 예정) 에 따라 cycle 2 verify 로 이연.
  (1) 파일 존재·삭제·구조, (2) LayoutType enum 계약 (3 values × 5 fields +
  5 methods, 매트릭스 일치), (3) Decision 18 fallback (firstWhere + orElse),
  (4) Decision 20 비대칭 (필드명 spreadType 유지 / 타입 LayoutType),
  (5) Cycle 1 범위 준수 (cycle 1 Modified 6 파일 이외의 SpreadType 잔존은
  Plan 019 Deferred 표에 명시된 cycle 2~6 예정 작업으로 확인), (6) TDD-Red
  테스트 파일 import 경로 해결 가능 — 6 개 정적 체크 모두 통과. Red→Green
  전이는 cycle 2 verify 에서 검증.
test_attribution: deferred-cycle-2
keywords: [verify, cycle-1, static-check, layout-type, deferred-green, scope-bounded]
---

# 020 — Verify: Cycle 1 LayoutType enum + Reading 레이어 정적 검증

## Verification Scope

Plan 019 Verification Assertions 중 L1-Build (`build_runner`, `flutter analyze`,
`flutter build apk`) 와 L2-CLI (`flutter test`, grep confirmation gates) 의
**실행 가능성 검증은 cycle 2 verify 로 명시적 이연**. 본 cycle 1 verify 는
**실행 없는 정적 스코프 검증 (파일 구조 · enum 계약 · 결정 사항 · 스코프 경계)**
만 수행한다.

**이연 사유** (Plan 019 § Deferred + § Risks + Strategy 1):
- `user_settings.dart` 가 여전히 `spread_type.dart` 를 import → build_runner
  실행 시 `package:personality_mobile/features/reading/domain/entities/spread_type.dart`
  경로 미해결로 컴파일 실패 예정
- 이 시나리오는 Scope 017 의 사이클 간 의존 설계 (cycle 2 → cycle 1) 와 Plan
  019 의 Deferred 전략에 **의도적** 으로 포함된 상태. cycle 2 impl 이
  UserSettings 레이어를 LayoutType 으로 전환하면 비로소 compile-clean 으로
  진입
- 따라서 Green 전이 확인 (`_$LayoutTypeEnumMap` grep, 18 테스트 통과) 은
  cycle 2 verify 에서 실시

---

## Static Verification Checklist (6 체크)

### Check 1 — 파일 존재·삭제·구조

| 항목 | 명령 | 결과 | 판정 |
|------|------|------|------|
| `layout_type.dart` 존재 | `test -f mobile/lib/features/reading/domain/entities/layout_type.dart` | EXISTS | PASS |
| `spread_type.dart` 삭제 | `test ! -f mobile/lib/features/reading/domain/entities/spread_type.dart` | DELETED | PASS |
| 커밋 변경 파일 수 | `git show --stat f88626d` | 6 files changed (1 new + 1 deleted + 4 modified) | PASS |

**판정**: PASS. 커밋 통계는 커밋 메시지의 "4 modified, 1 new, 1 deleted" 와
완전 일치 — 6 파일 경계 준수.

**변경 내역**:
- NEW: `mobile/lib/features/reading/domain/entities/layout_type.dart` (+111)
- DELETED: `mobile/lib/features/reading/domain/entities/spread_type.dart` (-52)
- MODIFIED: `reading.dart` (4L), `reading_repository.dart` (4L),
  `reading_repository_impl.dart` (9L), `reading_providers.dart` (4L)

### Check 2 — LayoutType enum 계약

**Read `mobile/lib/features/reading/domain/entities/layout_type.dart` (111 lines)**:

| 계약 | 기대 | 실제 | 판정 |
|------|------|------|------|
| enum values | `linear`, `tShape`, `grid3x3` (3 개) | 정확히 3 values (7:`enum LayoutType`, 8/15/22) | PASS |
| final fields | `cardCountMin`, `cardCountMax`, `defaultCardCount`, `cardsPerRowOverride`, `displayName` | 5 final, 타입 `int`, `int`, `int`, `int?`, `String` (38-42) | PASS |
| methods | `drawToSlot`, `emptySlots`, `slotCount`, `resolvePositions`, `resolveGuidances` | 5 메서드 (51, 81, 94, 102, 108) | PASS |

**Brief 011 Model Anchors 매트릭스 일치** (Check 2 핵심):

| Enum | cardCountMin | cardCountMax | defaultCardCount | cardsPerRowOverride | displayName | 판정 |
|------|--------------|--------------|------------------|---------------------|-------------|------|
| linear | 1 | 10 | 3 | null | '나열' | PASS (9-13) |
| tShape | 4 | 10 | 4 | 3 | 'T모양' | PASS (16-20) |
| grid3x3 | 9 | 10 | 9 | 3 | '3x3' | PASS (23-27) |

**판정**: PASS. 15 매트릭스 셀 전수 일치. TDD Red 018 T1 그룹 3 케이스는 이
한 파일만 있으면 개념적으로 Green (실행은 cycle 2 verify).

### Check 3 — Decision 18 fallback (Repository)

**Target**: `mobile/lib/features/reading/data/repositories/reading_repository_impl.dart`

| 검증 | 결과 | 판정 |
|------|------|------|
| `SpreadType.values.byName` 제거 | grep 0 매칭 | PASS |
| `LayoutType.values.byName` 미존재 | grep 0 매칭 | PASS |
| `firstWhere` 존재 | `98: spreadType: LayoutType.values.firstWhere(` | PASS |
| `orElse: () => LayoutType.linear` 존재 | `100: orElse: () => LayoutType.linear,` | PASS |

**판정**: PASS. Brief Decision 18 의 graceful degradation 패턴 (legacy DB 값
`single`/`threeCard`/`custom` → `LayoutType.linear` fallback) 완전 구현.

### Check 4 — Decision 20 비대칭 rename (Reading entity)

**Target**: `mobile/lib/features/reading/domain/entities/reading.dart`

| 검증 | 결과 | 판정 |
|------|------|------|
| 필드명 `spreadType` 보존 | `13: required LayoutType spreadType,` | PASS |
| 필드 타입 `LayoutType` | 동일 라인 | PASS |
| `SpreadType` 심볼 0 매칭 | grep (reading.dart) 0 | PASS |

**판정**: PASS. Brief Decision 20 의 비대칭 rename (타입만 교체, 필드명 보존)
정확히 적용 — DB 컬럼 `spread_type` 과의 1:1 대응 관계 유지되어 cycle 3 DB
마이그레이션 범위 확대 방지.

### Check 5 — Cycle 1 범위 준수

#### 5a. `mobile/lib/features/reading/` — 핸드 작성 파일의 SpreadType 검사

grep 결과를 **식별자 카테고리** 로 분류 (단순 문자열 매칭은 Decision 20 의
비대칭 성격상 false positive 를 유발):

| 카테고리 | 파일 | 예시 | Cycle 1 범위 판정 |
|----------|------|------|-------------------|
| **(A) Decision 20 보존 식별자** (메서드명·참조 타입명·필드명 내 "SpreadType" 문자열) | `reading_repository_impl.dart:79,81`, `reading_repository.dart:11`, `reading_providers.dart:24,25,29` | `watchReadingsBySpreadType`, `WatchReadingsBySpreadTypeRef`, `.spreadType.name` | 의도된 보존 — SpreadType **타입 참조가 아니므로 위반 아님** |
| **(B) SpreadType 타입 잔존 (cycle 4 deferred)** | `widgets/spread_layout.dart:19,30,31,32` | `final SpreadType spreadType;`, `SpreadType.single => ...` | Plan 019 Deferred 표 (row "spread_layout.dart = cycle 4") 에 명시 — cycle 1 범위 **밖** |
| **(C) SpreadType 타입 잔존 (cycle 6 deferred)** | `pages/reading_list_page.dart:18,24,42,210-214` | `SpreadType? _filterType;`, `for (final type in SpreadType.values)`, `_spreadTypeIcon(SpreadType type)` | Plan 019 Deferred 표 (row "reading_list_page.dart = cycle 6") 에 명시 — cycle 1 범위 **밖** |
| **(D) 스테일 codegen** | `reading.g.dart`, `reading.freezed.dart`, `reading_providers.g.dart` | `_$SpreadTypeEnumMap` 등 | build_runner 미실행 상태 — cycle 2 에서 일괄 재생성 예정 (Plan 019 Strategy 1) |

**Cycle 1 Modified 6 파일 범위 엄격 검증**:
- `layout_type.dart` (new): OK
- `reading.dart`: 타입 = LayoutType, 필드명 = spreadType — OK
- `reading_repository.dart`: 인터페이스 타입 = LayoutType, 메서드명 = watchReadingsBySpreadType — OK
- `reading_repository_impl.dart`: 파라미터 타입 = LayoutType, fallback 적용 — OK
- `reading_dao.dart`: 미수정 (Plan 019 Decision 4 — 이미 `String` 파라미터 사용 중) — OK
- `reading_providers.dart`: 프로바이더 파라미터 타입 = LayoutType, 함수명 유지 — OK

#### 5b. `reading_dao.dart` 검증

```
63:  Stream<List<Reading>> watchReadingsBySpreadType(String spreadType) {
```

**판정**: PASS. Plan 019 § Decision 4 는 DAO 가 이미 `String` 파라미터를 사용
중이므로 실제 편집이 0 라인임을 승인. `SpreadType` 타입 참조 0 — 깨끗.

#### 5c. `mobile/lib/features/settings/` — Cycle 2 예정 파일

```
mobile/lib/features/settings/data/repositories/user_settings_repository_impl.dart
mobile/lib/features/settings/domain/repositories/user_settings_repository.dart
mobile/lib/features/settings/domain/entities/user_settings.freezed.dart
mobile/lib/features/settings/domain/entities/user_settings.dart
mobile/lib/features/settings/domain/entities/user_settings.g.dart
```

**판정**: PASS. Scope 017 cycle 2 에 명시적으로 위임된 파일. cycle 1 에서 건드리지
않은 것이 정상 (Plan 019 § Deferred 표와 일치). 이는 cycle 1 scope 위반이 아님.

**Check 5 종합 판정**: PASS.
- Cycle 1 Modified 6 파일 내부: SpreadType 타입 참조 0 (의도된 메서드명
  식별자 보존은 Decision 20 준수)
- Cycle 1 범위 밖 파일의 SpreadType 잔존: Plan 019 Deferred 표와 1:1 대응
- Plan 019 § Risks 의 "upstream grep verification" 이 예측한 deferred 파일
  목록 (spread_layout.dart cycle 4, reading_list_page.dart cycle 6,
  user_settings.dart cycle 2 등) 과 일치

### Check 6 — TDD-Red 테스트 파일 무결성

| 검증 | 결과 | 판정 |
|------|------|------|
| 테스트 파일 존재 | `test -f mobile/test/features/reading/domain/entities/layout_type_mapping_test.dart` → EXISTS | PASS |
| import 타겟 해결 가능성 | `import 'package:personality_mobile/features/reading/domain/entities/layout_type.dart';` (line 22). Target file 이 실제 존재 (Check 1) → 경로 해결 가능 | PASS |
| Red→Green 전이 확인 | **DEFERRED to cycle 2 verify** (build_runner 실행 필요) | DEFERRED |

**판정**: PASS (정적 무결성) + DEFERRED (실행 검증).

**이연 사유**: TDD Red 018 가 의도한 Green 전이 (`+18: All tests passed!`)
확인은 `flutter test` 실행을 요구하며, 이는 build_runner 가 codegen 을 갱신한
후에만 가능. build_runner 는 `user_settings.dart → spread_type.dart` import 가
깨져 실패 예정 → cycle 2 impl 완료 후에만 Green 검증 가능.

---

## Deferred Items (Explicit Record)

Plan 019 Strategy 1 에 따라 **의도적으로 이연** 되는 실행 검증:

| # | 작업 | 이유 | 이연 대상 |
|---|------|------|-----------|
| D1 | `dart run build_runner build --delete-conflicting-outputs` | `user_settings.dart` 가 삭제된 `spread_type.dart` import → codegen 컴파일 실패 예정 | cycle 2 verify |
| D2 | `flutter analyze` | D1 와 동일 — 컴파일 깨짐으로 analyzer 에러 폭주 | cycle 2 verify |
| D3 | `flutter test test/features/reading/domain/entities/layout_type_mapping_test.dart` | D1 선행 필요 (freezed·json_serializable codegen 필요) | cycle 2 verify |
| D4 | TDD Red 018 의 Red → Green 전이 확인 | D3 실행 가능 상태여야 확인 | cycle 2 verify |
| D5 | `flutter build apk --debug` | D1 선행 필요 | cycle 2 verify |
| D6 | Repository fallback 단위 테스트 (Decision 18 검증) | Plan 019 미비점 #3 — cycle 6 smoke test 의존 | cycle 6 smoke test |
| D7 | `_$LayoutTypeEnumMap` grep confirmation gate | build_runner 재생성 후에만 의미 있음 | cycle 2 verify |

---

## Summary

```
== Cycle 1 Verify Report ==
Commit: f88626d
Mode: Static verification (no build_runner/analyze/test execution)
Planned deferrals: 7 (all recorded, all route to cycle 2/6)

Check 1 — File existence/structure: PASS
  - layout_type.dart created (111 lines)
  - spread_type.dart deleted (52 lines)
  - Commit delta: 1 new + 1 deleted + 4 modified = 6 (matches Scope 017 cycle 1)

Check 2 — LayoutType enum contract: PASS
  - 3 enum values (linear, tShape, grid3x3)
  - 5 final fields (cardCountMin, cardCountMax, defaultCardCount, cardsPerRowOverride, displayName)
  - 5 methods (drawToSlot, emptySlots, slotCount, resolvePositions, resolveGuidances)
  - Matrix values 15/15 match Brief 011 Model Anchors

Check 3 — Decision 18 fallback: PASS
  - SpreadType.values.byName removed
  - LayoutType.values.firstWhere + orElse: () => LayoutType.linear present

Check 4 — Decision 20 asymmetric rename: PASS
  - Reading.spreadType field preserved (type: LayoutType)

Check 5 — Cycle 1 scope compliance: PASS
  - Within 6 Modified files: 0 SpreadType TYPE references
  - Decision 20 preserved identifiers (watchReadingsBySpreadType method name,
    .spreadType field access) present as intended
  - Out-of-scope SpreadType leaks all match Plan 019 Deferred table:
    * spread_layout.dart (cycle 4)
    * reading_list_page.dart (cycle 6)
    * settings/** (cycle 2)

Check 6 — TDD-Red test integrity: PASS (static) / DEFERRED (execution)
  - Test file exists, import target resolvable in principle
  - Red→Green transition check DEFERRED to cycle 2 verify

Design Alignment: DA-score 3/3 (Decisions 18 and 20 fully aligned with Scope 017)
Test Attribution: deferred-cycle-2 (no test execution in this verify; gate
  should NOT trigger sub-cycle)

Verdict: PASS
Cycle 2 readiness: HIGH — cycle 1 artifacts provide clean handoff (LayoutType
  enum exists with full contract, Decision 18 fallback pattern established
  as reference for cycle 2 UserSettings repository, asymmetric rename policy
  applied consistently)
```

---

## Cycle 2 Readiness Assessment

| 항목 | 상태 | 비고 |
|------|------|------|
| LayoutType enum 존재 | READY | cycle 2 UserSettings 가 import 가능 (`layout_type.dart` 111 줄, 5 field + 5 method 완비) |
| Repository fallback 패턴 참조 구현 | READY | cycle 2 는 `reading_repository_impl.dart:98-100` 를 복제하여 `user_settings_repository_impl.dart:113` 에 적용 가능 |
| Deferred 상태 (user_settings.dart 의 stale import) | AS DESIGNED | cycle 2 impl 의 Step 1 = `user_settings.dart` import 교체 → build_runner 성공 진입 |
| cycle 2 TDD-Red 선행 필요성 | PENDING | cycle 2 tdd-red 가 UserSettings repository fallback 테스트 작성 필요 (Scope 017 cycle 2 TDD-red 목표) |
| codegen 재생성 윈도우 | 1 회 (cycle 2 impl 내부) | Plan 019 build_runner strategy 그대로 cycle 2 에서 실행 |

---

## 미비점 및 확장 필요 영역

### Verification 미비점 (verify 기록)

| # | 항목 | 심각도 | 설명 |
|---|------|--------|------|
| 1 | Red → Green 전이 미검증 (cycle 1 에서 실행 불가) | Medium | cycle 2 verify 가 반드시 18 테스트 통과 확인 수행 필요. 만약 cycle 2 에서 Red 유지되면 `tdd-red` (attribution: tdd-red) 또는 `makeplan/impl` 귀인 판단 |
| 2 | Repository fallback 동작 단위 테스트 부재 | Low | Plan 019 § Risks 에 기록된 Decision 18 fallback 의 행위 검증이 cycle 1 에서 제외됨. cycle 2 에서 UserSettings 의 동일 패턴 테스트로 간접 검증 + cycle 6 smoke test 에서 end-to-end 확인 |
| 3 | reading_dao.dart 변경 0 라인에 대한 정당성 기록 | Low | Plan 019 Decision 4 가 이미 충분히 정당화 — 문서상 미비점 없음. 보조 기록용 |
| 4 | 커밋 메시지에 "build_runner deferred" 명시 | Info | 커밋 메시지 line "build_runner·flutter analyze·flutter test 는 본 cycle 에서 실행하지 않음" 으로 deferral 명시 — 통과 |

### Plan 019 반영사항

Plan 019 § 미비점 표 "Plan 미비점" 4 건 중:
- #1 (build_runner 실패 가능성): **예상대로 실패 예정**, Strategy 1 로 대응 ✅
- #2 (reading_dao.dart 변경 0): **예상대로 변경 0**, Decision 4 정당화 확인 ✅
- #3 (Repository fallback 테스트 부재): cycle 2 로 이연 확인 ✅
- #4 (resolveGuidances placeholder 선택): 빈 리스트로 구현 확인 (line 108-110) ✅

---

## References

| Resource | Path |
|----------|------|
| Implementation commit | `f88626d` |
| Plan | `docs/2_tarot_draw/03_draw_experience_settings/019_Plan_cycle1_layout_type_reading.md` |
| TDD Red | `docs/2_tarot_draw/03_draw_experience_settings/018_TDD_Red_layout_type_mapping.md` |
| Scope | `docs/2_tarot_draw/03_draw_experience_settings/017_Scope_layout_redesign.md` |
| Brief | `docs/2_tarot_draw/03_draw_experience_settings/011_Brief_layout_redesign.md` |
| New artifact | `mobile/lib/features/reading/domain/entities/layout_type.dart` (111 lines) |
| Test file | `mobile/test/features/reading/domain/entities/layout_type_mapping_test.dart` |

---

## Session Log (auto-appended)
