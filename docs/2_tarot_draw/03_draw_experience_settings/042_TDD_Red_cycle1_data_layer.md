---
id: "042"
type: tdd-red
title: "TDD Red: data layer — IntentPlacement enum + UserSettings field + Drift v9 migration"
created: 2026-04-21
cycle: 1
traces_scope: "041"
status: completed
test_count: 13
framework: "flutter_test + drift NativeDatabase.memory()"
summary: >
  Cycle 1 data layer를 위한 실패 테스트. IntentPlacement enum 3값 존재, UserSettings.intentPlacement
  필드 기본값 beforeShuffle, JSON 직렬화 round-trip, repository.updateIntentPlacement() 업데이트,
  Drift v9 마이그레이션 컬럼 존재 여부를 검증한다. 모두 Red 상태.
keywords: [tdd-red, intent-placement, drift-migration, user-settings, data-layer]
test_files:
  - mobile/test/features/settings/intent_placement_test.dart
---

# TDD Red: data layer — IntentPlacement enum + UserSettings field + Drift v9

## Test Strategy

Cycle 1의 핵심 동작 5가지:
1. `IntentPlacement` enum이 `beforeShuffle`, `afterDraw`, `disabled` 3값으로 존재한다.
2. `UserSettings.intentPlacement`의 기본값이 `IntentPlacement.beforeShuffle`이다.
3. `UserSettings` JSON 직렬화가 `intentPlacement`를 round-trip한다.
4. `UserSettingsRepository.updateIntentPlacement(IntentPlacement)` 호출 후 값이 갱신된다.
5. Drift v9 마이그레이션이 `user_settings` 테이블에 `intent_placement` 컬럼을 추가한다.

기존 패턴: `user_settings_repository_layout_type_test.dart` — `NativeDatabase.memory()` + raw SQL.

## Test Specifications

### T1: IntentPlacement enum 3값 존재
- **동작**: `IntentPlacement` enum이 `beforeShuffle`, `afterDraw`, `disabled` 3값을 가진다.
- **입력**: `IntentPlacement.values`
- **기대 결과**: 길이 3, 각 이름이 정확히 일치
- **파일**: `mobile/test/features/settings/intent_placement_test.dart`

### T2: UserSettings.intentPlacement 기본값
- **동작**: `UserSettings` 생성 시 `intentPlacement`가 기본값 `IntentPlacement.beforeShuffle`
- **입력**: `UserSettings(updatedAt: DateTime.now())`
- **기대 결과**: `settings.intentPlacement == IntentPlacement.beforeShuffle`
- **파일**: `mobile/test/features/settings/intent_placement_test.dart`

### T3: JSON round-trip
- **동작**: `UserSettings.toJson()` → `UserSettings.fromJson()` 시 `intentPlacement`가 보존된다.
- **입력**: `afterDraw` 값으로 생성한 UserSettings
- **기대 결과**: fromJson 후 `intentPlacement == IntentPlacement.afterDraw`
- **파일**: `mobile/test/features/settings/intent_placement_test.dart`

### T4: repository.updateIntentPlacement 업데이트
- **동작**: `repo.updateIntentPlacement(IntentPlacement.afterDraw)` 후 `getSettings()`가 갱신된 값을 반환한다.
- **입력**: `NativeDatabase.memory()` 기반 실제 DB, `updateIntentPlacement(afterDraw)` 호출
- **기대 결과**: `settings.intentPlacement == IntentPlacement.afterDraw`
- **파일**: `mobile/test/features/settings/intent_placement_test.dart`

### T5: Drift v9 마이그레이션 컬럼 존재
- **동작**: DB 초기화 후 `user_settings` 테이블에 `intent_placement` 컬럼이 존재한다.
- **입력**: `NativeDatabase.memory()`로 AppDatabase 생성
- **기대 결과**: `PRAGMA table_info(user_settings)` 결과에 `intent_placement` 포함
- **파일**: `mobile/test/features/settings/intent_placement_test.dart`

## Test Files
| # | File Path | Test Count | Status |
|---|-----------|-----------|--------|
| 1 | `mobile/test/features/settings/intent_placement_test.dart` | 13 | red-confirmed |

## Red State Verification

실행 명령: `cd mobile && flutter test test/features/settings/intent_placement_test.dart`

결과 (마지막 40줄 발췌):
```
  Try correcting the name to the name of an existing getter, or defining a getter or field named 'intentPlacement'.
          expect(restored.intentPlacement, IntentPlacement.disabled);
                          ^^^^^^^^^^^^^^^
  test/features/settings/intent_placement_test.dart:200:20: Error: The method 'updateIntentPlacement' isn't defined for the type 'UserSettingsRepositoryImpl'.
  Try correcting the name to the name of an existing method, or defining a method named 'updateIntentPlacement'.
          await repo.updateIntentPlacement(IntentPlacement.afterDraw);
                     ^^^^^^^^^^^^^^^^^^^^^
  test/features/settings/intent_placement_test.dart:204:20: Error: The getter 'intentPlacement' isn't defined for the type 'UserSettings'.
  Try correcting the name to the name of an existing getter, or defining a getter or field named 'intentPlacement'.
            settings.intentPlacement,
                     ^^^^^^^^^^^^^^^
  ...
  00:00 +0 -1: Some tests failed.
```

**Red 원인**: 
- `package:personality_mobile/features/settings/domain/entities/intent_placement.dart` 파일 미존재 → `IntentPlacement` 타입 미정의
- `UserSettings.intentPlacement` 필드 미존재 (freezed 재생성 미실행)
- `UserSettingsRepositoryImpl.updateIntentPlacement()` 메서드 미존재

**Green 전환을 위해 필요한 프로덕션 변경**:
1. `mobile/lib/features/settings/domain/entities/intent_placement.dart` 신규 생성 — `enum IntentPlacement { beforeShuffle, afterDraw, disabled }`
2. `mobile/lib/features/settings/domain/entities/user_settings.dart` — `@Default(IntentPlacement.beforeShuffle) IntentPlacement intentPlacement` 필드 추가 + freezed 재생성
3. `mobile/lib/core/database/app_database.dart` — `schemaVersion` 8→9, `onUpgrade` step 추가 (`ALTER TABLE user_settings ADD COLUMN intent_placement TEXT NOT NULL DEFAULT 'beforeShuffle'`)
4. `mobile/lib/core/database/tables/user_settings_table.dart` — `intentPlacement TextColumn` 추가
5. `mobile/lib/core/database/daos/user_settings_dao.dart` — `updateIntentPlacement` Companion 경로 추가
6. `mobile/lib/features/settings/domain/repositories/user_settings_repository.dart` — `updateIntentPlacement(IntentPlacement)` 시그니처 추가
7. `mobile/lib/features/settings/data/repositories/user_settings_repository_impl.dart` — `updateIntentPlacement` 구현 + `_toDomain`에 `intentPlacement` 필드 매핑 추가
