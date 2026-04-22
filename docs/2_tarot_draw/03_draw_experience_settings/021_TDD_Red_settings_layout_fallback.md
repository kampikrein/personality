---
id: "021"
type: tdd-red
title: "TDD Red: UserSettings LayoutType rename + Repository firstWhere fallback (cycle 2)"
created: 2026-04-20
cycle: 2
traces_scope: "017"
traces_brief: "011"
status: completed
test_count: 8
framework: flutter_test
summary: >
  Scope 017 cycle 2 (UserSettings 레이어 + Repository fallback) 의 Green 목표를
  정의하는 실패 테스트. Brief Decision 6 (필드·타입 rename: defaultSpreadType
  → defaultLayoutType / SpreadType → LayoutType) + Decision 18 (firstWhere +
  orElse: () => LayoutType.linear — reading repo 참조 패턴 복제) + Ideal
  Criteria #5b (byName ArgumentError 방어) 를 4 동작 그룹 × 8 케이스로 검증.
  in-memory Drift DB + 원시 SQL UPDATE 로 DB 컬럼명 `default_spread_type` (cycle
  3 이전 상태) 에 특정 값을 주입한 뒤 `repository.getSettings()` 호출 결과의
  `defaultLayoutType` 을 검증. UserSettings 엔티티가 아직 rename 되지 않아
  컴파일 실패 상태로 Red 확정.
test_files:
  - mobile/test/features/settings/data/repositories/user_settings_repository_layout_type_test.dart
keywords: [tdd-red, layout-type, user-settings, repository-fallback, decision-18, cycle-2]
---

# TDD Red: UserSettings LayoutType 전환 + Repository fallback (cycle 2)

## Test Strategy

Cycle 2 는 **3 동작** 을 동시에 성립시켜야 Green 이다:

1. **엔티티 rename (Decision 6)**: `UserSettings.defaultSpreadType: SpreadType`
   → `UserSettings.defaultLayoutType: LayoutType`.
2. **Repository 번역 (Decision 18)**:
   `user_settings_repository_impl.dart:113` 의
   `SpreadType.values.byName(row.defaultSpreadType)` 를
   `LayoutType.values.firstWhere((e) => e.name == row.defaultSpreadType,
   orElse: () => LayoutType.linear)` 로 교체. 이 패턴은 이미 cycle 1 에서
   `reading_repository_impl.dart:98` 에 참조 구현으로 정착되었다.
3. **Graceful degradation (Ideal Criteria #5b)**: legacy 또는 알 수 없는
   raw String (`'threeCard'`, `'single'`, `'random_garbage'`, ...) 이 유입되어도
   ArgumentError 없이 `LayoutType.linear` 로 강등.

테스트는 4 동작 그룹으로 위 3 조건을 교차 검증한다.

**DB 컬럼명 주의**: Scope 017 cycle 2 Note 가 규정하듯 Drift 테이블 정의
(`user_settings_table.dart`) 는 cycle 2 에서 **손대지 않는다** — 실제 컬럼
rename (`default_spread_type` → `default_layout_type`) 은 cycle 3 DB 마이그레이션의
책임. 따라서 본 테스트는 cycle 2 Green 상태에서 여전히 컬럼명
`default_spread_type` 을 사용한다 (raw SQL UPDATE 로 주입). cycle 3 impl
이후 이 테스트 파일은 컬럼명 업데이트가 필요하다 (cycle 3 verify 에서 기록).

## Test Specifications

### T1 — Decision 18 fallback: legacy SpreadType 값 → LayoutType.linear

- **동작**: Repository 가 DB row 의 legacy pre-cycle-1 SpreadType 값을 읽을 때
  ArgumentError 없이 `LayoutType.linear` 로 fallback.
- **입력**: `UPDATE user_settings SET default_spread_type = 'threeCard'`,
  그 다음 `UPDATE ... = 'single'`.
- **기대 결과**: `repository.getSettings()` 결과의 `defaultLayoutType ==
  LayoutType.linear`.
- **Red 상태**: 현재 impl 이 `SpreadType.values.byName('threeCard')` 호출 →
  ArgumentError. + `UserSettings.defaultLayoutType` 필드 자체가 없어
  컴파일 실패.
- **파일**: `mobile/test/features/settings/data/repositories/user_settings_repository_layout_type_test.dart`

### T2 — 알 수 없는 값 → LayoutType.linear (Ideal Criteria #5b)

- **동작**: 완전히 알 수 없는 raw String 에 대해서도 crash 없이 linear fallback.
- **입력**: `UPDATE ... = 'random_garbage'`.
- **기대 결과**: `defaultLayoutType == LayoutType.linear`. Brief Ideal
  Criteria #5b "byName ArgumentError 방어" 직접 검증.
- **파일**: 상동

### T3 — Happy path: canonical LayoutType 값 보존

- **동작**: 유효 enum name 이 들어왔을 때 올바르게 매핑.
- **입력/기대 결과**:
  - `'tShape'` → `LayoutType.tShape`
  - `'grid3x3'` → `LayoutType.grid3x3`
  - `'linear'` → `LayoutType.linear`
- **Red 상태**: `UserSettings.defaultLayoutType` 부재로 컴파일 실패. cycle 2
  impl 후 Green 확정.
- **파일**: 상동

### T4 — Decision 6 필드 rename 계약 (freezed 엔티티)

- **동작**: `UserSettings` freezed factory 가 `defaultLayoutType: LayoutType`
  named parameter 를 수락하고, 접근자가 `LayoutType` 을 반환. `copyWith` 도
  같은 이름을 인식하며 불변성을 유지.
- **입력**: `UserSettings(defaultLayoutType: LayoutType.tShape, updatedAt: ...)`
  + `settings.copyWith(defaultLayoutType: LayoutType.grid3x3)`.
- **기대 결과**:
  - `settings.defaultLayoutType == LayoutType.tShape`
  - `settings.defaultLayoutType is LayoutType`
  - `mutated.defaultLayoutType == LayoutType.grid3x3`
  - 원본 `settings.defaultLayoutType` 은 여전히 `LayoutType.tShape` (freezed 불변)
- **Red 상태**: `No named parameter with the name 'defaultLayoutType'` +
  `The getter 'defaultLayoutType' isn't defined for the type 'UserSettings'`.
- **파일**: 상동

## Test Files

| # | File Path | Test Count | Status |
|---|-----------|-----------|--------|
| 1 | `mobile/test/features/settings/data/repositories/user_settings_repository_layout_type_test.dart` | 4 groups / 8 test cases | Red (compilation failure, verified) |

## Red State Verification

**실행**: `cd mobile && flutter test test/features/settings/data/repositories/user_settings_repository_layout_type_test.dart`

**실행 결과 (2026-04-20)**:

```
lib/features/settings/domain/entities/user_settings.dart:19:14:
  Error: Undefined name 'SpreadType'.
    @Default(SpreadType.custom) SpreadType defaultSpreadType,
             ^^^^^^^^^^
lib/features/settings/data/repositories/user_settings_repository_impl.dart:113:26:
  Error: The getter 'SpreadType' isn't defined for the type 'UserSettingsRepositoryImpl'.
    defaultSpreadType: SpreadType.values.byName(row.defaultSpreadType),
                       ^^^^^^^^^^
test/features/settings/data/repositories/user_settings_repository_layout_type_test.dart:94:31:
  Error: The getter 'defaultLayoutType' isn't defined for the type 'UserSettings'.
    ...
test/features/settings/data/repositories/user_settings_repository_layout_type_test.dart:197:11:
  Error: No named parameter with the name 'defaultLayoutType'.
            defaultLayoutType: LayoutType.grid3x3,
            ^^^^^^^^^^^^^^^^^
  ...
00:00 +0 -1: Some tests failed.
```

**Red 확정 분류**:

| 실패 유형 | 건수 | 근거 |
|-----------|------|------|
| 테스트 측 `defaultLayoutType` 미정의 | 8 (각 test 내부 expect 당 1건+) | cycle 2 impl 이 rename 수행 전 |
| 테스트 측 `UserSettings(defaultLayoutType: ...)` named param 없음 | 1 (T4) | cycle 2 impl 이 freezed factory 파라미터 rename 전 |
| 프로덕션 코드 측 `SpreadType` 미해결 | 다수 (`user_settings.dart`, `.freezed.dart`, `.g.dart`, `user_settings_repository_impl.dart`) | cycle 1 에서 `spread_type.dart` 삭제됨 (020 Check 5 에 기록) — cycle 2 가 `LayoutType` 으로 전환 예정 |
| 테스트 실행 결과 | `+0 -1` | 컴파일 실패로 테스트 1 개도 실행되지 못함 |

**Green 조건** (cycle 2 impl 이후):
1. `user_settings.dart` 의 `SpreadType defaultSpreadType` → `LayoutType
   defaultLayoutType` (기본값 `LayoutType.linear` 권장, cycle 6 Decision
   19 `_updateDefaultLayoutType` provider 와 일관)
2. `user_settings_repository_impl.dart:113` 을
   `LayoutType.values.firstWhere((e) => e.name == row.defaultSpreadType,
   orElse: () => LayoutType.linear)` 로 교체
3. build_runner 재생성 (`user_settings.freezed.dart`, `.g.dart` 의 `_$SpreadTypeEnumMap`
   → `_$LayoutTypeEnumMap`)
4. `flutter test test/features/settings/data/repositories/user_settings_repository_layout_type_test.dart`
   8 케이스 전부 통과 + `flutter analyze` 경고 0

## Mapping to Brief 011

| Test Group | Brief 011 Decisions | Brief 011 Ideal Criteria |
|------------|--------------------|-----------------------|
| T1 | Decision 18 (firstWhere + orElse fallback) | #5b (byName ArgumentError 방어) |
| T2 | Decision 18 | #5b |
| T3 | Decision 18 happy path | #3 (런타임 매트릭스 일치) |
| T4 | Decision 6 (필드 rename Dart + DB 모두) | #1 (도메인 용어 통일) |

## Cycle Boundary Guards (tdd-red 범위 준수)

- [x] 신규 테스트 파일만 생성 (`user_settings_repository_layout_type_test.dart`)
- [x] `user_settings.dart`, `user_settings_repository_impl.dart`, `user_settings_table.dart`
      **미수정** — cycle 2 impl (seq 7) 의 책임
- [x] `build_runner` 미실행 — cycle 2 impl 내부에서 1회 실행 예정
- [x] `flutter analyze` 미실행 — cycle 4~6 deferred 파일 잔존으로 false
      positive 예상. cycle 2 verify (seq 8) 에서 scope 내 analyze 수행
- [x] 테스트 코드가 아직 존재하지 않는 필드 (`defaultLayoutType`) 를 참조 —
      Red state 정의 (tdd-red 프로토콜 Step 5)

## In-Memory DB 전략 설명

테스트는 `drift/native` 의 `NativeDatabase.memory()` 로 AppDatabase 를 세팅.
DAO 의 `getSettings()` 가 단일행 (id=1) 자동 INSERT 패턴이므로, 먼저
`repository.getSettings()` 로 default row 를 materialise 한 뒤 `customStatement`
로 `default_spread_type` 컬럼만 덮어쓴다. 이렇게 하면:

1. **현재 컬럼명 그대로** (`default_spread_type`) 테스트 가능 — cycle 2 scope
   내에서 Drift 테이블 정의 미수정이라는 요구사항과 일치.
2. Compiletime type checking (Companion) 을 우회 → cycle 2 impl 이 Dart
   필드명을 rename 해도 테스트의 raw SQL 은 영향 없음.
3. cycle 3 DB 마이그레이션 완료 후 컬럼명이 `default_layout_type` 으로
   바뀌면 본 테스트 파일의 UPDATE 문 한 줄만 수정 필요 (cycle 3 verify
   에서 확인).

## Session Log

- 2026-04-20: tdd-red 스펙 문서 + 테스트 코드 작성. `flutter test ...`
  실행 → 컴파일 실패 + `+0 -1` 확정. 다음 단계: makeplan (seq 6) 이 4
  테스트 그룹을 Green 목표로 사용하여 cycle 2 impl 설계.

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
