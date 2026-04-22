// TDD Red — Cycle 1 (intent_placement_setting pipeline)
// Spec: docs/2_tarot_draw/03_draw_experience_settings/042_TDD_Red_cycle1_data_layer.md
// Scope: docs/2_tarot_draw/03_draw_experience_settings/041_Scope_intent_placement_setting.md
// Brief: docs/2_tarot_draw/03_draw_experience_settings/040_Brief_intent_placement_setting.md
//
// Purpose:
//   Cycle 1 adds IntentPlacement (3-way enum) to the data layer.
//   Five behaviours must appear together when cycle 1 impl lands:
//     (a) IntentPlacement enum exists with values: beforeShuffle, afterDraw, disabled.
//     (b) UserSettings.intentPlacement field defaults to IntentPlacement.beforeShuffle.
//     (c) UserSettings JSON serialization round-trips intentPlacement.
//     (d) UserSettingsRepository.updateIntentPlacement(IntentPlacement) updates the value.
//     (e) Drift v9 migration adds intent_placement TEXT column to user_settings table.
//
// Until cycle 1 impl completes, these tests fail with:
//   - compile step: 'IntentPlacement' not found, 'intentPlacement' not found,
//     'updateIntentPlacement' not found
// Any compile/runtime failure constitutes the intended Red state.
//
// Green target (makeplan → impl):
//   1. Create `mobile/lib/features/settings/domain/entities/intent_placement.dart`
//      with enum IntentPlacement { beforeShuffle, afterDraw, disabled }.
//   2. Add `@Default(IntentPlacement.beforeShuffle) IntentPlacement intentPlacement`
//      to `user_settings.dart` freezed factory, regenerate freezed/json.
//   3. Bump AppDatabase.schemaVersion 8→9, add migration step:
//      ALTER TABLE user_settings ADD COLUMN intent_placement TEXT NOT NULL DEFAULT 'beforeShuffle'.
//   4. Add `updateIntentPlacement(String value)` to UserSettingsTableCompanion path in DAO.
//   5. Add `updateIntentPlacement(IntentPlacement)` to UserSettingsRepository + impl.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:personality_mobile/core/database/app_database.dart';
import 'package:personality_mobile/features/settings/data/repositories/user_settings_repository_impl.dart';
import 'package:personality_mobile/features/settings/domain/entities/intent_placement.dart';
import 'package:personality_mobile/features/settings/domain/entities/user_settings.dart';

void main() {
  // ------------------------------------------------------------------
  // T1 — IntentPlacement enum 3값 존재
  // ------------------------------------------------------------------
  group('T1 — IntentPlacement enum values', () {
    test(
      'IntentPlacement has exactly 3 values: beforeShuffle, afterDraw, disabled',
      () {
        expect(IntentPlacement.values, hasLength(3));
        expect(
          IntentPlacement.values.map((e) => e.name),
          containsAll(['beforeShuffle', 'afterDraw', 'disabled']),
        );
      },
    );

    test(
      'IntentPlacement.beforeShuffle name is "beforeShuffle"',
      () {
        expect(IntentPlacement.beforeShuffle.name, 'beforeShuffle');
      },
    );

    test(
      'IntentPlacement.afterDraw name is "afterDraw"',
      () {
        expect(IntentPlacement.afterDraw.name, 'afterDraw');
      },
    );

    test(
      'IntentPlacement.disabled name is "disabled"',
      () {
        expect(IntentPlacement.disabled.name, 'disabled');
      },
    );
  });

  // ------------------------------------------------------------------
  // T2 — UserSettings.intentPlacement 기본값 beforeShuffle
  // ------------------------------------------------------------------
  group('T2 — UserSettings.intentPlacement default value', () {
    test(
      'UserSettings created without intentPlacement defaults to IntentPlacement.beforeShuffle',
      () {
        final settings = UserSettings(updatedAt: DateTime(2026, 1, 1));

        expect(
          settings.intentPlacement,
          IntentPlacement.beforeShuffle,
          reason:
              'Brief Decision 3: 기본값은 beforeShuffle — 기존 사용자 회귀 차단 및 '
              '현재 동작(IntentionPage 강제 통과)과 동일.',
        );
      },
    );

    test(
      'UserSettings.intentPlacement field is accessible and typed as IntentPlacement',
      () {
        final settings = UserSettings(
          intentPlacement: IntentPlacement.afterDraw,
          updatedAt: DateTime(2026, 1, 1),
        );

        expect(settings.intentPlacement, isA<IntentPlacement>());
        expect(settings.intentPlacement, IntentPlacement.afterDraw);
      },
    );

    test(
      'UserSettings.copyWith changes intentPlacement while keeping original immutable',
      () {
        final original = UserSettings(updatedAt: DateTime(2026, 1, 1));
        final mutated = original.copyWith(
          intentPlacement: IntentPlacement.disabled,
        );

        expect(mutated.intentPlacement, IntentPlacement.disabled);
        expect(
          original.intentPlacement,
          IntentPlacement.beforeShuffle,
          reason: 'Freezed entity must be immutable — original must not change.',
        );
      },
    );
  });

  // ------------------------------------------------------------------
  // T3 — JSON round-trip
  // ------------------------------------------------------------------
  group('T3 — UserSettings JSON serialization round-trips intentPlacement', () {
    test(
      'afterDraw survives toJson → fromJson round-trip',
      () {
        final original = UserSettings(
          intentPlacement: IntentPlacement.afterDraw,
          updatedAt: DateTime(2026, 4, 21),
        );

        final json = original.toJson();
        final restored = UserSettings.fromJson(json);

        expect(
          restored.intentPlacement,
          IntentPlacement.afterDraw,
          reason:
              'JSON serialization must preserve intentPlacement so that '
              'cached/serialized settings survive app restarts.',
        );
      },
    );

    test(
      'disabled survives toJson → fromJson round-trip',
      () {
        final original = UserSettings(
          intentPlacement: IntentPlacement.disabled,
          updatedAt: DateTime(2026, 4, 21),
        );

        final json = original.toJson();
        final restored = UserSettings.fromJson(json);

        expect(restored.intentPlacement, IntentPlacement.disabled);
      },
    );

    test(
      'toJson includes "intentPlacement" key with string value',
      () {
        final settings = UserSettings(
          intentPlacement: IntentPlacement.beforeShuffle,
          updatedAt: DateTime(2026, 4, 21),
        );

        final json = settings.toJson();

        expect(json, containsPair('intentPlacement', 'beforeShuffle'));
      },
    );
  });

  // ------------------------------------------------------------------
  // T4 — repository.updateIntentPlacement 업데이트
  // ------------------------------------------------------------------
  group('T4 — UserSettingsRepository.updateIntentPlacement persists value', () {
    late AppDatabase db;
    late UserSettingsRepositoryImpl repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = UserSettingsRepositoryImpl(db: db);
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'updateIntentPlacement(afterDraw) → getSettings().intentPlacement == afterDraw',
      () async {
        await repo.updateIntentPlacement(IntentPlacement.afterDraw);
        final settings = await repo.getSettings();

        expect(
          settings.intentPlacement,
          IntentPlacement.afterDraw,
          reason:
              'After calling updateIntentPlacement, the persisted value must '
              'be readable via getSettings() — end-to-end DB round-trip.',
        );
      },
    );

    test(
      'updateIntentPlacement(disabled) → getSettings().intentPlacement == disabled',
      () async {
        await repo.updateIntentPlacement(IntentPlacement.disabled);
        final settings = await repo.getSettings();

        expect(settings.intentPlacement, IntentPlacement.disabled);
      },
    );

    test(
      'updateIntentPlacement(beforeShuffle) after disabled → reverts to beforeShuffle',
      () async {
        await repo.updateIntentPlacement(IntentPlacement.disabled);
        await repo.updateIntentPlacement(IntentPlacement.beforeShuffle);
        final settings = await repo.getSettings();

        expect(settings.intentPlacement, IntentPlacement.beforeShuffle);
      },
    );
  });

  // ------------------------------------------------------------------
  // T5 — Drift v9 마이그레이션: intent_placement 컬럼 존재
  // ------------------------------------------------------------------
  group('T5 — Drift v9 migration adds intent_placement column', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'user_settings table has intent_placement column after DB initialization',
      () async {
        // Trigger table creation by reading settings.
        await db.userSettingsDao.getSettings();

        // PRAGMA table_info returns one row per column.
        final result = await db
            .customSelect("PRAGMA table_info(user_settings)")
            .get();

        final columnNames = result.map((row) => row.read<String>('name')).toList();

        expect(
          columnNames,
          contains('intent_placement'),
          reason:
              'Drift v8→v9 migration must ALTER TABLE user_settings ADD COLUMN '
              'intent_placement TEXT NOT NULL DEFAULT "beforeShuffle". '
              'If this fails, the migration step is missing from app_database.dart.',
        );
      },
    );

    test(
      'intent_placement column has default value "beforeShuffle" for new rows',
      () async {
        // Get the default row (created lazily).
        await db.userSettingsDao.getSettings();

        final result = await db
            .customSelect(
              "SELECT intent_placement FROM user_settings WHERE id = 1",
            )
            .getSingle();

        expect(
          result.read<String>('intent_placement'),
          'beforeShuffle',
          reason:
              'New rows must default to "beforeShuffle" per Brief Decision 3. '
              'Ensures zero regression for existing users on upgrade.',
        );
      },
    );
  });
}
