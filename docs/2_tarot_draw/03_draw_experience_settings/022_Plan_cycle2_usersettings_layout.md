---
id: "022"
type: plan
title: "Plan — Cycle 2: UserSettings 레이어 LayoutType 전환 + Decision 18 fallback (Green 설계)"
created: 2026-04-20
cycle: 2
traces_scope: "017"
traces_tdd_red: "021"
traces_brief: "011"
status: ready
summary: >
  TDD Red 021 의 8 실패 테스트 (4 그룹: 레거시 fallback / unknown fallback /
  canonical round-trip / Decision 6 필드 rename) 를 Green 으로 전환. UserSettings
  엔티티 필드·타입을 `defaultSpreadType: SpreadType` → `defaultLayoutType: LayoutType`
  rename (Decision 6), Repository `_toDomain` 의 `SpreadType.values.byName` 을
  cycle 1 reading_repository_impl 패턴을 복제한 `LayoutType.values.firstWhere +
  orElse: () => LayoutType.linear` 로 교체 (Decision 18), 도메인 인터페이스·
  구현체의 `updateDefaultSpreadType` → `updateDefaultLayoutType` rename. Drift
  테이블 (`user_settings_table.dart`) 과 DB 컬럼 (`default_spread_type`) 은
  cycle 3 스코프이므로 손대지 않음 — Drift DataClass 의 `row.defaultSpreadType`
  String 을 수동으로 `LayoutType` 도메인으로 번역하는 **Option B (manual
  `_toDomain` 매핑 유지)** 선택. 사이클 종료 시 `user_settings.dart` 는 삭제된
  `spread_type.dart` 를 더 이상 import 하지 않으므로 cycle 1 이 의도적으로
  이연한 build_runner 재생성이 settings 레이어까지 확장 가능.
keywords: [plan, cycle-2, user-settings, layout-type, decision-18, decision-6, firstWhere-fallback, tdd-green, drift-option-b]
---

# 022 — Plan: Cycle 2 UserSettings 레이어 LayoutType 전환 + Decision 18 fallback

## Goal

TDD Red 021 이 정의한 **8 실패 테스트** (4 동작 그룹: T1 legacy fallback × 2 / T2
unknown fallback × 1 / T3 canonical round-trip × 3 / T4 Decision 6 필드 rename ×
1+copyWith + immutability = 2 expectation pair) 를 단일 impl 패스로 Green 전환
한다. Brief 011 의 두 결정이 동시에 성립해야 한다:

- **Decision 6** (UserSettings 필드명 Dart 측 rename): `defaultSpreadType` →
  `defaultLayoutType`, 타입 `SpreadType` → `LayoutType`. DB 컬럼명 rename
  (`default_spread_type` → `default_layout_type`) 은 **cycle 3** (DB
  마이그레이션 v7→v8) 의 책임 (Scope 017 cycle 2 Note).
- **Decision 18** (Repository graceful degradation): `byName` 로 인한
  `ArgumentError` 를 `firstWhere + orElse: () => LayoutType.linear` 로 흡수.
  cycle 1 `reading_repository_impl.dart:98` 에 참조 구현이 있음 — 그대로 복제.

동시에 이 cycle 은 **cycle 1 verify 가 의도적으로 이연한 build_runner 재생성**
(Verify 020 § Deferred Items D1~D7) 을 실제로 실행 가능한 상태로 만드는 것이
핵심 부수 효과다. cycle 1 종료 시 `user_settings.dart` 가 삭제된
`spread_type.dart` 를 import 중이어서 build_runner 가 컴파일 실패했던 상태를
cycle 2 impl 이 해제한다. 단, cycles 3~6 범위 파일 (`home_page.dart`,
`draw_result_page.dart`, `animated_draw_page.dart`, `reading_list_page.dart`,
`spread_layout.dart`, DB schema) 은 여전히 `SpreadType` 참조 중이라 **부분적
컴파일 실패가 남는다** — 이는 Scope 017 의 6사이클 의존 설계상 정상.

## Scope

### Included (Scope 017 cycle 2 Modified 3 + Reviewed 2 + 발견된 1)

| # | 항목 | 설명 |
|---|------|------|
| 1 | `user_settings.dart` 필드·타입 rename | `@Default(SpreadType.custom) SpreadType defaultSpreadType` → `@Default(LayoutType.linear) LayoutType defaultLayoutType`. import swap (`spread_type.dart` → `layout_type.dart`). Decision 6 Dart 측. 기본값 `LayoutType.linear` — TDD Red 021 Green 조건 #1 권장 + Decision 18 fallback 과 일관 |
| 2 | `user_settings_repository_impl.dart:113` — byName → firstWhere | cycle 1 `reading_repository_impl.dart:98-101` 패턴 복제. `row.defaultSpreadType` (Drift String 필드, 컬럼명 미변경) 을 `LayoutType.values.firstWhere((e) => e.name == row.defaultSpreadType, orElse: () => LayoutType.linear)` 로 번역 후 `defaultLayoutType:` 에 주입. Decision 18 graceful degradation |
| 3 | `user_settings_repository_impl.dart:61-65` — updateDefault 메서드 rename | `updateDefaultSpreadType(String spreadTypeName)` → `updateDefaultLayoutType(String layoutTypeName)`. Companion 은 여전히 `defaultSpreadType: Value(...)` — Drift 컬럼 getter 가 cycle 3 이전까지 미변경 (Option B 원칙) |
| 4 | `user_settings_repository.dart` (abstract interface) | `Future<void> updateDefaultSpreadType(String spreadTypeName)` → `updateDefaultLayoutType(String layoutTypeName)`. impl 과 시그니처 싱크 필요 — **Scope 017 본문에 명시되지 않았지만 접근 시 필수로 발견** (§ 미비점 #1) |
| 5 | build_runner 1회 실행 | `dart run build_runner build --delete-conflicting-outputs`. cycle 1 이 이연한 `user_settings.freezed.dart` / `user_settings.g.dart` / `settings_providers.g.dart` / cycle 1 `reading.g.dart` / `reading.freezed.dart` / `reading_providers.g.dart` 일괄 재생성 |
| 6 | Reviewed: `user_settings.freezed.dart` | build_runner 재생성 결과 타입 `LayoutType defaultLayoutType` 반영 확인 (수동 편집 없음) |
| 7 | Reviewed: `user_settings.g.dart:16-18, 49-53` | build_runner 재생성 후 `_$SpreadTypeEnumMap` 제거 + **`_$LayoutTypeEnumMap` 3 entries (linear/tShape/grid3x3) 자동 생성 확인** (012 Critique C1 해소 gate) |
| 8 | Reviewed: `settings_providers.g.dart` | 함수형 provider (`userSettingsRepository`, `userSettings`, `cardAspectRatio`) 는 메서드 rename 영향 없음 — 재생성 후 diff 가 0 또는 캐시 해시 변경 수준일 것으로 기대. 실측으로 확인 |

### Excluded (cycle 3~6 위임)

| Item | Reason/Deferred To |
|------|-------------------|
| `user_settings_table.dart:15` TextColumn `defaultSpreadType` → `defaultLayoutType` rename | **cycle 3** — Scope 017 cycle 2 Note "Drift 테이블 정의는 cycle 2 에서 손대지 않음" 엄격 준수. Decision 6 의 **DB 컬럼명 rename** 부분 |
| `app_database.dart:25, 28-70` schemaVersion 7→8 + onUpgrade | cycle 3 (Decision 5/16/19) |
| `readings_table.dart` 주석 갱신 | cycle 3 |
| `migration_v7_to_v8_test.dart` 4 케이스 신규 (phantom crash recovery 포함) | cycle 3 |
| `home_page.dart:462-463` 의 `settings?.defaultSpreadType` + `updateDefaultSpreadType(v.name)` 호출 | **cycle 5** — 이 cycle 종료 시 컴파일 실패 예정 (정상) |
| `draw_result_page.dart:53` + `animated_draw_page.dart:53` 의 `settings?.defaultSpreadType ?? SpreadType.custom` | cycle 6 — 컴파일 실패 예정 (정상) |
| `reading_list_page.dart`, `reading_detail_page.dart` | cycle 6 |
| `spread_layout.dart` 전면 재작성 | cycle 4 |
| `flutter analyze` 경고 0 달성 | **cycle 6 verify** 로 이연 — cycle 2 시점에는 cycles 3~6 파일이 여전히 `SpreadType` 참조 중이라 false positive 필연 |

## Structural Decisions

| # | Decision | Chosen Option | Rationale |
|---|----------|---------------|-----------|
| 1 | Drift 컬럼명과 Dart 필드명 불일치 처리 (이 cycle 의 핵심 판단) | **Option B — manual `_toDomain` 매핑** | 현재 repo 가 이미 이 패턴 (Reading repo 와 동일) 으로 동작 중. cycle 2 범위 내 필요한 변경은 번역 로직 한 곳 (`_toDomain` 내부 firstWhere) 뿐 — Drift 테이블 getter 를 건드리지 않음으로 cycle 3 DB 마이그레이션 원자성 보장 (§ Option A vs B 상세 참조). 또한 cycle 1 reading repo 와 완전히 대칭적인 패턴 유지 |
| 2 | `defaultLayoutType` 기본값 선택 | **`LayoutType.linear`** | (a) TDD Red 021 "Green 조건 #1 권장" 과 일치. (b) Decision 18 fallback 도 `linear` 로 강등 — 엔티티 기본값과 repo fallback 이 같은 값을 가리켜 **동일 의도** (가장 관대한 default, min=1 max=10). (c) 기존 `SpreadType.custom` 에 대응하는 LayoutType 이 없음 (Brief Decision 20 비대칭 — 의미 재설계). 대안 `tShape`/`grid3x3` 은 min cardCount 제약 (4 / 9) 때문에 초기 상태로 부적절 |
| 3 | Repository 메서드 rename 범위 (`updateDefaultSpreadType`) | **rename 수행** — interface + impl 양쪽 | Scope 017 cycle 2 Modified 표에 명시 (Provider 항목). 단 실제 위치는 **provider 가 아니라 repository interface + impl** 임을 발견 (§ 미비점 #1). home_page.dart 의 호출 (`repo.updateDefaultSpreadType(...)`) 은 cycle 5 범위이므로 이 cycle 종료 시 컴파일 실패 예정 — Verify 020 의 deferred-file 원칙에 따라 cycle 5 로 자연 이전 |
| 4 | `DrawnCardInfo` / `_empty 슬롯` 등 부수 확인 | **불필요** | cycle 2 는 settings 레이어 한정. reading 레이어는 cycle 1 에서 처리 완료 (verify 020 PASS) |
| 5 | `user_settings.freezed.dart` 에 남아있는 `SpreadType` 참조 (24+ 곳) | **build_runner 로 일괄 자동 갱신** | 수동 편집 금지. build_runner 실행 후 `_$UserSettings` mixin 의 모든 `SpreadType get defaultSpreadType` / `SpreadType defaultSpreadType` 이 `LayoutType defaultLayoutType` 로 갱신. Reviewed 카테고리 |

> 모든 결정은 Scope 017 Modified 범위 + Verify 020 deferred-file 원칙 내에서
> 자율적으로 판단 가능. user 재확인 불필요.

---

## Option A vs Option B — Drift 컬럼-필드 불일치 전략 (상세)

cycle 2 의 단일 가장 중요한 판단. 이 cycle 의 **핵심 제약**은 다음 두 가지가
동시에 성립해야 한다는 것:

- Dart 도메인 필드명 = `defaultLayoutType` (Decision 6 Dart 측, 즉시 적용)
- Drift 테이블의 Dart getter `defaultSpreadType` → SQL 컬럼 `default_spread_type`
  둘 다 **cycle 3 전까지 미변경** (Scope 017 cycle 2 Note)

### Option A — Drift `named()` 어노테이션으로 컬럼 mapping 유지

```dart
// user_settings_table.dart (수정 불가 — cycle 3 scope)
TextColumn get defaultLayoutType =>
    text().named('default_spread_type').withDefault(...)();
```

이렇게 하면 Drift 측 Dart getter 는 `defaultLayoutType`, SQL 컬럼은
`default_spread_type` 으로 어긋남 유지 가능.

**기각 사유**:
- `user_settings_table.dart` 을 건드려야 함 → **Scope 017 cycle 2 Note 정면 위반**
- cycle 3 DB 마이그레이션이 "컬럼 rename" 작업을 수행할 때, Dart getter 도 함께
  `defaultLayoutType` 으로 되돌리는 **중복 작업** 발생 (한 번 변경한 걸 다시
  되돌림)
- Drift `named()` 어노테이션은 이미 auto-snake_case 와 override 관계라 의도
  이해에 인지 부하

### Option B — Repository 수동 매핑 유지 (**채택**)

```dart
// user_settings_repository_impl.dart:106-123 (기존 _toDomain 패턴 유지)
UserSettings _toDomain(UserSettingsTableData row) {
  return UserSettings(
    ...
    // row.defaultSpreadType 은 Drift DataClass 의 String 필드 (컬럼 미변경)
    // → domain 의 LayoutType defaultLayoutType 으로 수동 번역
    defaultLayoutType: LayoutType.values.firstWhere(
      (e) => e.name == row.defaultSpreadType,
      orElse: () => LayoutType.linear,
    ),
    ...
  );
}
```

**채택 사유**:
- 현재 코드가 이미 이 manual `_toDomain` 패턴으로 동작 중 (`row.defaultSpreadType`
  String 읽기 → `SpreadType.values.byName(...)` 번역). byName 을 firstWhere+orElse
  로 교체하고 타겟 필드명만 `defaultLayoutType` 으로 바꾸면 완결
- **cycle 1 `reading_repository_impl.dart:98-101` 와 완전히 대칭적** — cycle 1
  이 남긴 참조 구현을 그대로 복제 (Verify 020 "Cycle 2 Readiness: HIGH" 평가의
  근거)
- `user_settings_table.dart` 미수정 → Scope 017 cycle 2 Note 준수
- cycle 3 DB 마이그레이션 시, 컬럼 rename 후 repo 의 `row.defaultSpreadType` →
  `row.defaultLayoutType` 한 줄 수정만 필요 (cycle 3 scope 에 이미 포함된 작업
  연속선)

**요지**: Option B 는 "아무 것도 새로 추가하지 않고, 이미 존재하는 패턴을 한
곳에서 한 메서드로 확장" — cycle 2 의 context 최소화 원칙 (Scope 017 § Context
Overflow 대응) 과 일치.

---

## File Change Summary

### Modified Files (3)

| # | File Path | Change Description |
|---|-----------|-------------------|
| 1 | `mobile/lib/features/settings/domain/entities/user_settings.dart` | Line 3: import `spread_type.dart` → `../../reading/domain/entities/layout_type.dart`. Line 19: `@Default(SpreadType.custom) SpreadType defaultSpreadType,` → `@Default(LayoutType.linear) LayoutType defaultLayoutType,`. 그 외 수정 없음 (card_size_preset import·다른 필드 유지) |
| 2 | `mobile/lib/features/settings/data/repositories/user_settings_repository_impl.dart` | Line 4: import `spread_type.dart` → `../../reading/domain/entities/layout_type.dart`. Line 61-65: `updateDefaultSpreadType(String spreadTypeName)` → `updateDefaultLayoutType(String layoutTypeName)`. Companion 내부는 `defaultSpreadType: Value(layoutTypeName)` 유지 (Drift 컬럼 getter 미변경 — Option B). Line 113: `defaultSpreadType: SpreadType.values.byName(row.defaultSpreadType),` → `defaultLayoutType: LayoutType.values.firstWhere((e) => e.name == row.defaultSpreadType, orElse: () => LayoutType.linear),` |
| 3 | `mobile/lib/features/settings/domain/repositories/user_settings_repository.dart` | Line 11: `Future<void> updateDefaultSpreadType(String spreadTypeName);` → `Future<void> updateDefaultLayoutType(String layoutTypeName);` — abstract 인터페이스 싱크 |

### New Files

| # | File Path | Description |
|---|-----------|-------------|
| — | — | **신규 파일 없음**. TDD Red 021 의 테스트 파일 (`user_settings_repository_layout_type_test.dart`) 은 seq=5 에서 이미 생성됨 |

### Auto-Regenerated (build_runner, Reviewed)

| # | File Path | Expected Gate |
|---|-----------|---------------|
| 1 | `mobile/lib/features/settings/domain/entities/user_settings.freezed.dart` | 24+ 곳의 `SpreadType` → `LayoutType`, `defaultSpreadType` → `defaultLayoutType` 자동 갱신 |
| 2 | `mobile/lib/features/settings/domain/entities/user_settings.g.dart` | **`_$SpreadTypeEnumMap` 삭제 + `_$LayoutTypeEnumMap = {LayoutType.linear: 'linear', LayoutType.tShape: 'tShape', LayoutType.grid3x3: 'grid3x3',}` 자동 생성 — C1 Critique 해소 gate** |
| 3 | `mobile/lib/features/settings/presentation/providers/settings_providers.g.dart` | 함수형 provider 만 있어 영향 적을 것으로 기대. diff 확인 (hash 변경 가능) |
| 4 | `mobile/lib/features/reading/domain/entities/reading.g.dart` | **cycle 1 이연분** — `_$LayoutTypeEnumMap` 이 비로소 생성되는 시점 (Verify 020 D7) |
| 5 | `mobile/lib/features/reading/domain/entities/reading.freezed.dart` | cycle 1 이연분 — 타입 갱신 |
| 6 | `mobile/lib/features/reading/presentation/providers/reading_providers.g.dart` | cycle 1 이연분 — LayoutType 파라미터 반영 |

---

## Step 1 — `user_settings.dart` 엔티티 rename (Decision 6 Dart 측)

### Approach

2 줄 변경: import 경로 + 필드 선언. `UserSettings.fromJson`·`_UserSettings._()`
private 생성자·`cardAspectRatio` getter 는 모두 유지. freezed annotation 그대로.

### Current Code

```dart
// mobile/lib/features/settings/domain/entities/user_settings.dart:3, 19
import '../../../reading/domain/entities/spread_type.dart';
...
const factory UserSettings({
  @Default('rws-standard') String selectedDeckId,
  ...
  @Default(SpreadType.custom) SpreadType defaultSpreadType,
  ...
}) = _UserSettings;
```

### After Code

```dart
// mobile/lib/features/settings/domain/entities/user_settings.dart:3, 19
import '../../../reading/domain/entities/layout_type.dart';
...
const factory UserSettings({
  @Default('rws-standard') String selectedDeckId,
  ...
  @Default(LayoutType.linear) LayoutType defaultLayoutType,
  ...
}) = _UserSettings;
```

### Considerations

- **기본값 선택 (Decision 2)**: `LayoutType.linear` 는 Decision 18 fallback 과
  동일 — "최대 관대한 default". T4 테스트가 `UserSettings(defaultLayoutType:
  LayoutType.tShape, ...)` 생성 시 기본값은 override 되므로 테스트 영향 없음.
- **`const factory` ↔ `@Default` 상수식 요구**: `LayoutType.linear` 는 const
  enum value → 허용.
- **freezed 재생성 필수**: `user_settings.freezed.dart` 가 24+ 곳에서 `SpreadType`
  을 가지고 있음 (Grep 결과). build_runner 1 회로 일괄 갱신. 수동 편집 금지.

---

## Step 2 — `user_settings_repository.dart` 인터페이스 rename

### Approach

Scope 017 Modified 표에는 "Provider" 항목으로 잡혀 있지만 실제 코드 상 abstract
interface 에 선언되어 있다 (§ 미비점 #1). impl 과 시그니처 싱크 필수.

### Current Code

```dart
// mobile/lib/features/settings/domain/repositories/user_settings_repository.dart:11
Future<void> updateDefaultSpreadType(String spreadTypeName);
```

### After Code

```dart
Future<void> updateDefaultLayoutType(String layoutTypeName);
```

### Considerations

- 파라미터는 여전히 `String` — Companion 이 String 을 요구하고, 호출부
  (home_page.dart, cycle 5) 가 `v.name` 으로 String 전달. 타입 변경 시 home_page
  까지 수정 영향 전파 → 이 cycle 범위 초과.
- 타입 안전성 개선 (`LayoutType` 직접 전달) 은 cycle 5 에서 home_page 수정 시
  동시 적용 검토 여지 (§ 미비점 #2).

---

## Step 3 — `user_settings_repository_impl.dart` impl 3 곳 변경

### Approach

1. import 교체
2. update 메서드 rename (interface 싱크)
3. `_toDomain:113` 의 Decision 18 fallback 도입 (Option B 핵심)

### Current Code

```dart
// mobile/lib/features/settings/data/repositories/user_settings_repository_impl.dart:4
import '../../../reading/domain/entities/spread_type.dart';
...
// :61-65
@override
Future<void> updateDefaultSpreadType(String spreadTypeName) async {
  await db.userSettingsDao.updateSettings(
    UserSettingsTableCompanion(defaultSpreadType: Value(spreadTypeName)),
  );
}
...
// :106-123
UserSettings _toDomain(UserSettingsTableData row) {
  return UserSettings(
    selectedDeckId: row.selectedDeckId,
    ...
    defaultSpreadType: SpreadType.values.byName(row.defaultSpreadType),
    ...
  );
}
```

### After Code

```dart
// mobile/lib/features/settings/data/repositories/user_settings_repository_impl.dart
import '../../../reading/domain/entities/layout_type.dart';
...
@override
Future<void> updateDefaultLayoutType(String layoutTypeName) async {
  await db.userSettingsDao.updateSettings(
    UserSettingsTableCompanion(defaultSpreadType: Value(layoutTypeName)),
  );
}
...
UserSettings _toDomain(UserSettingsTableData row) {
  return UserSettings(
    selectedDeckId: row.selectedDeckId,
    ...
    defaultLayoutType: LayoutType.values.firstWhere(
      (e) => e.name == row.defaultSpreadType,
      orElse: () => LayoutType.linear,
    ),
    ...
  );
}
```

### Considerations

- **Companion 내 `defaultSpreadType: Value(...)` 유지는 의도적** — Drift 생성
  `UserSettingsTableCompanion` 의 필드명은 테이블 getter 이름 (`defaultSpreadType`)
  과 1:1 대응. cycle 3 에서 Drift getter 가 `defaultLayoutType` 으로 바뀌면
  Companion 필드명도 자동 갱신 — 그 시점에 update 메서드의 Companion 호출 한 줄
  만 추가 수정하면 됨. Option B 의 cycle 간 원자성 핵심.
- **firstWhere 패턴은 cycle 1 reading repo 와 완전 대칭** — `row.defaultSpreadType`
  은 Drift DataClass 의 Dart 필드 (cycle 3 이전까지 String, getter 이름 미변경).
  cycle 3 impl 이 Drift getter rename 후에는 이 줄을 `row.defaultLayoutType` 로
  갱신 — 한 줄 변경의 예측 가능성.
- **컬럼 값이 legacy `'custom'` 인 상태에서 앱 시작** (기존 사용자 hot reload
  시나리오): `LayoutType.values.firstWhere((e) => e.name == 'custom', orElse:
  () => LayoutType.linear)` → `LayoutType.linear` 로 fallback. ArgumentError 방어
  (Ideal Criteria #5b). TDD Red 021 T1 의 `'threeCard'`·`'single'` 도 동일 경로.

---

## Step 4 — build_runner 재생성 (cycle 2 impl 의 마지막 단계)

### Approach

Step 1~3 모두 완료 후에만 실행. **cycle 2 Green 의 결정적 단계**.

```bash
cd /Users/kampikrein/A/personality/mobile
dart run build_runner build --delete-conflicting-outputs
```

### 예상 결과

**Settings 레이어**:
- `user_settings.freezed.dart` — 24+ `SpreadType` 참조가 `LayoutType` 으로 갱신,
  `defaultSpreadType` 필드명이 `defaultLayoutType` 으로 갱신
- `user_settings.g.dart` — `_$SpreadTypeEnumMap` 삭제, `_$LayoutTypeEnumMap`
  신규 생성 (3 entries)
- `settings_providers.g.dart` — 내용 diff 없을 가능성 (함수형 provider 만 있음)
  또는 hash 만 변경

**Reading 레이어 (cycle 1 deferred)**:
- `reading.g.dart` — `_$LayoutTypeEnumMap` 신규 생성 (Verify 020 D7 해소)
- `reading.freezed.dart` — LayoutType 반영
- `reading_providers.g.dart` — LayoutType 파라미터 반영

### 예상 부분 실패 (정상)

cycles 3~6 deferred 파일들이 여전히 `SpreadType` 참조 → build_runner 가 이들에
대해 경고나 에러 보고 가능:
- `home_page.dart:462-463` (cycle 5) — `settings?.defaultSpreadType ?? SpreadType.custom`
- `draw_result_page.dart:53` (cycle 6) — 동일 패턴
- `animated_draw_page.dart:53` (cycle 6) — 동일
- `reading_list_page.dart:18+` (cycle 6) — `_filterType` + `_spreadTypeIcon`
- `spread_layout.dart:19,30,31,32` (cycle 4) — `SpreadType.single => ...` switch
- `app_database.dart`, `app_database.g.dart` (cycle 3) — DB 마이그레이션 범위

**build_runner 의 부분 실패 기준**: codegen 은 파일 단위로 독립 실행되므로
cycle 2 범위 (`user_settings.*.dart`, `reading.*.dart`, 관련 `.g.dart`) 의 재생성
이 성공하고 해당 파일들이 생성/갱신되면 **cycle 2 impl 의 build_runner 는
성공으로 간주**. cycles 3~6 파일의 컴파일 에러는 해당 사이클이 수행할 작업이므로
현 cycle 의 실패로 취급하지 않음 (Verify 020 § Deferred Items 원칙).

build_runner 가 exit code ≠ 0 로 종료하더라도, **cycle 2 범위 generated 파일들이
실제 갱신되었는지 grep 으로 직접 검증** (§ Verification).

### Considerations

- **`--delete-conflicting-outputs` 필수** — 이전 `_$SpreadTypeEnumMap`·`part of`
  참조 제거 + 새 `_$LayoutTypeEnumMap` 으로 덮어쓰기 위해.
- **재생성 순서**: Step 1~3 이 모두 disk 에 반영된 **후** Step 4. 중간 상태로
  build_runner 실행 금지.
- **캐시 상태**: 이전 실행에서 cycle 1 의 build_runner 가 실패한 상태 (cycle 1
  verify 가 이연) → codegen 의 cache 가 stale 일 수 있음. `--delete-conflicting-outputs`
  로 대응. 그래도 실패 시 `rm -rf .dart_tool/build` 후 재실행 고려.

---

## Test → Code Mapping (TDD Red 021 의 8 테스트)

| Test ID | Test Name | Satisfying File(s) | Evidence / Mechanism |
|---------|-----------|---------------------|----------------------|
| T1.a | `row.default_spread_type == 'threeCard'` → `defaultLayoutType == LayoutType.linear` | `user_settings_repository_impl.dart:113` (firstWhere+orElse) + `user_settings.dart:19` (필드 rename) | `LayoutType.values` 에 `threeCard` 없음 → orElse 발동 → linear 반환. 필드 접근 `settings.defaultLayoutType` 는 rename 완료로 컴파일 통과 |
| T1.b | `row.default_spread_type == 'single'` → `LayoutType.linear` | 동상 | 동일 경로 |
| T2 | `row.default_spread_type == 'random_garbage'` → `LayoutType.linear` | 동상 | 동일 경로 — Ideal Criteria #5b |
| T3.a | `row.default_spread_type == 'tShape'` → `LayoutType.tShape` | `user_settings_repository_impl.dart:113` + `user_settings.dart:19` | firstWhere 가 `LayoutType.tShape.name == 'tShape'` 매칭 → tShape 반환 (orElse 미발동) |
| T3.b | `row.default_spread_type == 'grid3x3'` → `LayoutType.grid3x3` | 동상 | `LayoutType.grid3x3.name == 'grid3x3'` 매칭 |
| T3.c | `row.default_spread_type == 'linear'` → `LayoutType.linear` | 동상 | `LayoutType.linear.name == 'linear'` 매칭 — orElse 가 아닌 **정식 매치 경로** 로 도달 (해피 패스) |
| T4.a | `UserSettings(defaultLayoutType: LayoutType.tShape, ...)` 컴파일 + `.defaultLayoutType == LayoutType.tShape` + `isA<LayoutType>()` | `user_settings.dart:19` (필드 rename) + `user_settings.freezed.dart` (build_runner 재생성) | freezed 가 named parameter `defaultLayoutType` 수락, getter `defaultLayoutType` 이 `LayoutType` 반환 |
| T4.b | `settings.copyWith(defaultLayoutType: LayoutType.grid3x3)` 결과가 `LayoutType.grid3x3`, 원본 `settings.defaultLayoutType` 은 불변 `LayoutType.tShape` | `user_settings.freezed.dart` | freezed auto-generated `copyWith` 가 필드명 일치 수용 + 불변 보장 |

**요약**: 8 테스트 모두 **3 소스 변경 (Step 1~3) + build_runner 1 회 (Step 4)**
로 일괄 Green 전환. 추가 핫픽스 불필요.

---

## Risks & Mitigations

### R1 — `defaultSpreadType` → `defaultLayoutType` rename 전파 실패 (downstream consumer)

- **위험**: `home_page.dart:462-463` (cycle 5), `draw_result_page.dart:53` /
  `animated_draw_page.dart:53` (cycle 6) 가 `settings.defaultSpreadType` 직접
  호출 중. 이 cycle 종료 시 컴파일 실패 예정.
- **가능성**: 확정 (grep 확인 완료)
- **완화책**: Verify 020 의 deferred-file 원칙 적용 — **이는 cycle 2 의 실패가
  아니다**. Scope 017 의 사이클 간 선형 의존 설계상 정상 상태. 이 cycle 2 verify
  에서 `flutter analyze` 를 수행하지 않고 cycle 6 verify 로 이연 (§ Verification
  의 명시적 정책).
- **재난 시나리오**: 위 3 파일이 **cycle 5/6 이전에 실행** 되어야 할 경우 (예:
  cycle 3 test harness 가 home_page 의존성 로드 시도) → build_runner 가 더
  전역적으로 실패. 완화: cycle 3 의 `migration_v7_to_v8_test.dart` 는 DB 단독
  테스트 → home_page import 하지 않음. 위험 낮음.

### R2 — Drift DataClass 컬럼 getter 이름과 Dart 도메인 필드명 불일치 인지 부담

- **위험**: impl 엔지니어가 `UserSettingsTableCompanion(defaultSpreadType: ...)`
  (Companion 필드는 Drift getter 이름) vs `UserSettings(defaultLayoutType: ...)`
  (도메인 필드) 혼동 → 오타 또는 잘못된 필드 참조
- **가능성**: 중간 (네이밍이 비대칭이라 타자 시 실수 가능)
- **완화책**:
  (a) Plan Step 3 의 "After Code" 코드 스니펫을 **Companion 과 도메인 경계의
  양쪽 맥락을 같이 보여주는 형태**로 명시 → 변경 지점 명확화
  (b) impl agent 가 Step 3 완료 후 `cd mobile && dart analyze lib/features/settings/data/repositories/user_settings_repository_impl.dart` 로 **이 파일만** 부분 분석 → 변환 오류 즉시 포착 (cycle 2~6 deferred 파일 영향 배제)
  (c) Option B 의 특성을 § "Option A vs B" 섹션에 별도 상세 기록 → impl agent 가 이해 확보

### R3 — build_runner 부분 성공 — cycles 3~6 파일로 인한 exit code ≠ 0

- **위험**: build_runner 가 home_page/draw_result_page/animated_draw_page/
  reading_list_page/spread_layout 의 컴파일 에러로 전체 exit code 0 미달성
- **가능성**: 확정
- **완화책**: cycle 2 의 build_runner 성공 기준을 **"cycle 2 범위 generated
  파일이 올바르게 생성되었는지"** 로 재정의 (exit code 무관). § Verification 의
  grep-based gate 가 이 정책을 실행.
- **근거**: cycle 1 verify 020 이 이미 동일한 원칙 ("Strategy 1") 을 수립.
  cycle 2 는 그 선례를 그대로 이어받음.

### R4 — `settings_providers.g.dart` 재생성 diff 가 예상 외로 크게 발생

- **위험**: riverpod_generator 가 imports 재스캔 중 다른 이유로 provider hash
  변경 → 커밋 noise
- **가능성**: 낮음 (`settings_providers.dart` 는 import 변경 없음)
- **완화책**: `git diff settings_providers.g.dart` 확인 후 변화 크면 impl 에이전트
  가 판단 기록. 기능적 영향은 없을 것이므로 커밋 수용 가능.

### R5 — `UserSettings.defaultLayoutType` 기본값 `LayoutType.linear` 로 인한 기존 user_settings 레코드 의미 변화

- **위험**: 기존 사용자의 DB 에 `default_spread_type = 'custom'` 저장되어 있음
  → cycle 2 Green 상태에서 앱 기동 시 `LayoutType.linear` 로 표시됨 (fallback
  경로). 사용자 관점에서 "내가 custom 으로 설정했는데 linear 로 바뀌었다" 로
  인식 가능
- **가능성**: 중간 (출시 전 dev 환경에서는 낮음)
- **완화책**: cycle 3 DB 마이그레이션에서 `UPDATE user_settings SET
  default_spread_type = 'linear' WHERE default_spread_type IN ('single', 'threeCard',
  'custom')` 으로 DB 측 값을 일괄 치환 예정 (Decision 5/16/19 의 값 변환 블록).
  cycle 2 Green 상태는 **마이그레이션 실행 전의 일시 상태**이며 fallback 이
  crash 를 방지하는 안전망.

---

## Verification Plan (verify agent seq=8 용)

### 필수 실행

1. **build_runner 재생성 시도** (부분 실패 허용)

   ```bash
   cd /Users/kampikrein/A/personality/mobile
   dart run build_runner build --delete-conflicting-outputs
   ```

   exit code 무관하게 다음 파일이 갱신되었는지 확인.

2. **Settings 레이어 `_$LayoutTypeEnumMap` 생성 grep (핵심 gate)**

   ```bash
   grep '_\$LayoutTypeEnumMap' \
       mobile/lib/features/settings/domain/entities/user_settings.g.dart
   # 기대: const _$LayoutTypeEnumMap = { ... }
   ```
   PASS 조건: 1 건 이상 매칭.

3. **Reading 레이어 `_$LayoutTypeEnumMap` 생성 grep (cycle 1 이연분)**

   ```bash
   grep '_\$LayoutTypeEnumMap' \
       mobile/lib/features/reading/domain/entities/reading.g.dart
   ```
   PASS 조건: 1 건 이상 매칭 (Verify 020 D7 해소 증거).

4. **`_$SpreadTypeEnumMap` 잔존 확인 (제거 gate)**

   ```bash
   grep '_\$SpreadTypeEnumMap' mobile/lib/
   ```
   PASS 조건: 매칭 0. codegen 이 두 `.g.dart` 모두에서 구 EnumMap 을 제거했어야 함.

5. **cycle 2 TDD Red 021 의 8 테스트 실행**

   ```bash
   cd /Users/kampikrein/A/personality/mobile
   flutter test test/features/settings/data/repositories/user_settings_repository_layout_type_test.dart
   ```
   PASS 조건: `+8: All tests passed!`

6. **cycle 1 TDD Red 018 의 18 테스트 실행 (이연 Green)**

   ```bash
   cd /Users/kampikrein/A/personality/mobile
   flutter test test/features/reading/domain/entities/layout_type_mapping_test.dart
   ```
   PASS 조건: `+18: All tests passed!`. Verify 020 D3/D4 해소 증거.

7. **Repository 메서드 rename 확인**

   ```bash
   grep -n 'updateDefaultLayoutType' \
       mobile/lib/features/settings/domain/repositories/user_settings_repository.dart \
       mobile/lib/features/settings/data/repositories/user_settings_repository_impl.dart
   ```
   PASS 조건: 두 파일 각각 1 매칭.

### 실행하지 않음 (cycle 6 verify 로 이연)

- `flutter analyze` — cycles 3~6 deferred 파일 (home_page, draw_result_page,
  animated_draw_page, reading_list_page, spread_layout.dart, app_database.dart)
  이 `SpreadType` 잔존 + `defaultSpreadType` 잔존으로 분석 에러 폭주 예상.
  false positive 필연. cycle 6 verify 에서 일괄 검증.
- `flutter build apk --debug` — 동상 이유로 빌드 실패 필연. cycle 6 verify.

### 명시적 Deferred Items (cycle 2 → later)

| # | 작업 | 이연 대상 |
|---|------|-----------|
| DC2-1 | `flutter analyze` 경고 0 | cycle 6 verify |
| DC2-2 | `flutter build apk --debug` | cycle 6 verify |
| DC2-3 | `home_page.dart` 의 `settings?.defaultSpreadType` 참조 수정 | cycle 5 impl |
| DC2-4 | `draw_result_page.dart` / `animated_draw_page.dart` 의 `defaultSpreadType` 참조 | cycle 6 impl |
| DC2-5 | DB 컬럼 `default_spread_type` → `default_layout_type` rename + Drift 테이블 getter 갱신 | cycle 3 impl |
| DC2-6 | Repository `updateDefaultLayoutType` 의 파라미터를 `String` → `LayoutType` 으로 타입 강화 | cycle 5 검토 (home_page rename 시 동시) |

### 회귀 확인 (선택적)

cycle 1 reading 레이어 회귀 테스트 재실행:

```bash
cd /Users/kampikrein/A/personality/mobile
flutter test test/features/reading/
```

PASS 조건: 기존 reading 테스트가 Green 유지 (cycle 1 의 build_runner 이연분이
이제 Green 완료로 간주).

---

## Implementation Checklist

- [ ] Step 0 (사전): `grep -n 'spread_type.dart' mobile/lib/features/settings/` 로 import 참조 2 건 (user_settings.dart, user_settings_repository_impl.dart) 확인
- [ ] Step 1: `user_settings.dart` — import swap + `@Default(LayoutType.linear) LayoutType defaultLayoutType` 로 필드 rename
- [ ] Step 2: `user_settings_repository.dart` — `updateDefaultLayoutType(String)` 로 인터페이스 rename
- [ ] Step 3: `user_settings_repository_impl.dart` — import swap + `updateDefaultLayoutType` rename + Companion 내부 `defaultSpreadType: Value(...)` 유지 + `_toDomain:113` 의 firstWhere+orElse 도입
- [ ] Step 4: `cd mobile && dart run build_runner build --delete-conflicting-outputs` 실행
- [ ] Step 5: Gate 1 — `grep '_\$LayoutTypeEnumMap' mobile/lib/features/settings/domain/entities/user_settings.g.dart` 매칭 확인
- [ ] Step 6: Gate 2 — `grep '_\$LayoutTypeEnumMap' mobile/lib/features/reading/domain/entities/reading.g.dart` 매칭 확인 (cycle 1 이연분)
- [ ] Step 7: Gate 3 — `grep '_\$SpreadTypeEnumMap' mobile/lib/` 매칭 0 확인
- [ ] Step 8: `flutter test test/features/settings/data/repositories/user_settings_repository_layout_type_test.dart` → `+8 All tests passed`
- [ ] Step 9: `flutter test test/features/reading/domain/entities/layout_type_mapping_test.dart` → `+18 All tests passed` (cycle 1 이연 Green)
- [ ] Step 10: auto-commit (Scope 017 auto_run=true) — 커밋 메시지에 "cycle 2 settings LayoutType rename + Decision 18 fallback + cycle 1 build_runner deferred regen 완료" 명시

---

## Verification Assertions (verify agent 용)

| Level | Assertion | Verification Method | Expected Result |
|-------|-----------|-------------------|-----------------|
| L1-Build | build_runner 의 **cycle 2 범위 generated 파일들** 이 갱신 | 위 Verification § 2~4 | grep PASS |
| L2-CLI | cycle 2 TDD Red 의 8 테스트 Green | `flutter test ...user_settings_repository_layout_type_test.dart` | `+8 All tests passed` |
| L2-CLI | cycle 1 TDD Red 의 18 테스트 (이연 Green) | `flutter test ...layout_type_mapping_test.dart` | `+18 All tests passed` |
| L2-CLI | Repository `updateDefaultLayoutType` 메서드 rename 존재 | grep on `user_settings_repository.dart` + `_impl.dart` | 각 1 건 |
| L4-Trace | TDD Red 021 의 4 그룹 (T1~T4) 전수 Green | Test → Code Mapping 표 | 8/8 |
| L4-Trace | Decision 6 (Dart 측 필드 rename) 충족 | 엔티티 선언 grep + freezed 재생성 | `LayoutType defaultLayoutType` 매칭 |
| L4-Trace | Decision 18 (fallback 패턴) 충족 | `firstWhere` grep on `user_settings_repository_impl.dart` | `orElse: () => LayoutType.linear` 매칭 |
| L1-Build (DEFERRED) | `flutter analyze` 경고 0 | **cycle 6 verify 로 이연** | — |
| L1-Build (DEFERRED) | Flutter APK 빌드 | **cycle 6 verify 로 이연** | — |

---

## References

| Resource | Path | Related Content |
|----------|------|-----------------|
| Brief | `docs/2_tarot_draw/03_draw_experience_settings/011_Brief_layout_redesign.md` | Decision 6 (필드 rename), Decision 18 (fallback), Decision 20 (비대칭), Ideal Criteria #5b (byName 방어) |
| Scope | `docs/2_tarot_draw/03_draw_experience_settings/017_Scope_layout_redesign.md` | cycle 2 Modified 3 / Reviewed 2 / cycle 간 의존 |
| TDD Red | `docs/2_tarot_draw/03_draw_experience_settings/021_TDD_Red_settings_layout_fallback.md` | 8 failing tests, Green 조건 4 건 |
| Cycle 1 Plan | `docs/2_tarot_draw/03_draw_experience_settings/019_Plan_cycle1_layout_type_reading.md` | Decision 18 참조 구현 근거 |
| Cycle 1 Verify | `docs/2_tarot_draw/03_draw_experience_settings/020_Verify_cycle1_report.md` | 이연 항목 D1~D7 — 본 cycle 에서 D3/D4/D7 해소 |
| Reference impl (cycle 1) | `mobile/lib/features/reading/data/repositories/reading_repository_impl.dart:93-113` | firstWhere+orElse 패턴 원본 |
| Target file 1 | `mobile/lib/features/settings/domain/entities/user_settings.dart` | Step 1 |
| Target file 2 | `mobile/lib/features/settings/domain/repositories/user_settings_repository.dart` | Step 2 |
| Target file 3 | `mobile/lib/features/settings/data/repositories/user_settings_repository_impl.dart` | Step 3 |
| Test file (Red) | `mobile/test/features/settings/data/repositories/user_settings_repository_layout_type_test.dart` | 8 test cases |

---

## 미비점 및 확장 필요 영역

### Plan 미비점 (makeplan 기록)

| # | 항목 | 심각도 | 설명 |
|---|------|--------|------|
| 1 | Scope 017 의 "Provider" 분류 오기 (실제는 Repository interface/impl) | Medium | Scope 017 cycle 2 Modified 표가 `settings_providers.dart` — `updateDefaultSpreadType` → `updateDefaultLayoutType` 로 기록하였으나, 실제 소스 확인 결과 `settings_providers.dart` 는 riverpod 함수형 provider 만 정의 (userSettingsRepository, userSettings, cardAspectRatio) 로 `updateDefault*` 메서드가 존재하지 않음. 실제 위치는 **`user_settings_repository.dart` (abstract interface line 11)** + **`user_settings_repository_impl.dart:61-65` (impl)**. 본 Plan 은 이 둘을 정식 수정 대상에 포함 (File Change Summary #3 + Step 2). Scope 문서는 다음 Plan/Verify 에서 교정 기록 권장 |
| 2 | `updateDefaultLayoutType` 파라미터 타입 `String` 유지 vs `LayoutType` 강화 | Low | 타입 안전성 관점에서 `LayoutType` 직접 수용이 이상적. 그러나 호출부 `home_page.dart:463` 가 `v.name` (String) 전달 중 → 파라미터 타입 변경은 home_page 수정 영향. cycle 5 에서 home_page 수정 시 함께 `String` → `LayoutType` 타입 강화 검토 여지 기록 (DC2-6). 현 cycle 은 기존 `String` 시그니처 유지 |
| 3 | `LayoutType.linear` 를 기본값으로 선택 — 기존 사용자 `custom` 설정 의미 손실 | Low | cycle 2 Green 상태에서 기존 DB 의 `custom`·`threeCard`·`single` 값은 fallback 으로 `linear` 표시됨 (R5). cycle 3 DB 마이그레이션이 DB 값 변환을 수행하므로 최종적으로 일관되지만, cycle 2~3 사이 hot reload 시점의 UX 에 일시 왜곡. 출시 전 dev 시점이라 허용 수준 |
| 4 | cycles 3~6 deferred 파일의 컴파일 에러 범위 측정 부재 | Low | cycle 2 Green 이후 `flutter analyze` 가 실제로 몇 건의 에러를 보고하는지 사전 측정은 수행하지 않음. verify 에이전트가 cycle 2 verify 단계에서 실제 측정치를 기록하고 cycle 3 이후의 범위 축소 추적에 활용 권장 |
| 5 | `settings_providers.g.dart` 재생성 diff 예측 정확도 | Low | 함수형 provider 만 있어 변화 적을 것으로 기대하나 실측 이전에는 단정 불가. impl agent 가 `git diff` 결과에 따라 기록 |

### Implementation 미비점 (implementation 기록)

_impl 단계에서 발견된 이슈 기록 영역_

| # | 항목 | 심각도 | 설명 |
|---|------|--------|------|

### Verification 미비점 (verify 기록)

_verify 단계에서 발견된 문제 기록 영역_

| # | 항목 | 심각도 | 설명 |
|---|------|--------|------|

---

## Session Log (auto-appended)
