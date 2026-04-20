// TDD Red — Cycle 2 (layout_redesign pipeline)
// Spec: docs/2_tarot_draw/03_draw_experience_settings/021_TDD_Red_settings_layout_fallback.md
// Scope: docs/2_tarot_draw/03_draw_experience_settings/017_Scope_layout_redesign.md
// Brief: docs/2_tarot_draw/03_draw_experience_settings/011_Brief_layout_redesign.md
//
// Purpose:
//   Cycle 2 migrates UserSettings from `SpreadType` to `LayoutType`.
//   Three behaviours must appear together when cycle 2 impl lands:
//     (a) Decision 6: `UserSettings.defaultSpreadType: SpreadType`
//         → `UserSettings.defaultLayoutType: LayoutType` (entity rename).
//     (b) Decision 18: Repository's translation of the persisted String
//         back into the domain enum must use the `firstWhere + orElse:
//         () => LayoutType.linear` fallback — identical pattern to the
//         reading repository cycle-1 reference at
//         `reading_repository_impl.dart:98`.
//     (c) Ideal Criteria #5b: legacy values like `'threeCard'`,
//         `'single'`, `'custom'` (all from pre-cycle-1 SpreadType) and
//         outright unknown strings must NOT raise ArgumentError at
//         hot-reload / legacy-device startup time.
//
// Until cycle 2 impl completes, these tests fail in at least one of:
//   - compile step (`UserSettings.defaultLayoutType` does not exist)
//   - runtime (`SpreadType.values.byName('threeCard')` throws
//     ArgumentError in the current repo `_toDomain`)
//   - assertion (returned enum value does not match expectation)
// Any of those constitutes the intended Red state.
//
// Green target (makeplan → impl):
//   1. `user_settings.dart` — rename field + switch import to LayoutType.
//   2. `user_settings_repository_impl.dart` — clone the cycle-1 fallback:
//      `LayoutType.values.firstWhere((e) => e.name == row.defaultSpreadType,
//      orElse: () => LayoutType.linear)`.
//   3. `settings_providers.dart` — rename `updateDefaultSpreadType` →
//      `updateDefaultLayoutType` (covered by Scope, not asserted here).
//
// NOTE: Cycle 3 (schema v7→v8) renamed the DB column to
// `default_layout_type`. These tests now write legacy enum strings
// (`'threeCard'`, `'single'`, `'random_garbage'`, …) to that renamed
// column via raw SQL — the fallback behaviour being verified is at the
// Dart-side decoder (`firstWhere + orElse`), which is agnostic to the
// physical column name.

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:personality_mobile/core/database/app_database.dart';
import 'package:personality_mobile/features/reading/domain/entities/layout_type.dart';
import 'package:personality_mobile/features/settings/data/repositories/user_settings_repository_impl.dart';
import 'package:personality_mobile/features/settings/domain/entities/user_settings.dart';

/// Forces the `default_layout_type` value of the single user_settings row
/// (id=1) via raw SQL, bypassing the DAO/Companion typing surface.
/// The row is created lazily by `UserSettingsDao.getSettings()` on first
/// read, so we invoke `getSettings()` once to materialise it, then patch
/// the column with an explicit raw string (including legacy enum names).
Future<void> _forceLegacyColumnValue(
  AppDatabase db,
  String rawValue,
) async {
  // Trigger default-row creation.
  await db.userSettingsDao.getSettings();
  await db.customStatement(
    "UPDATE user_settings SET default_layout_type = ? WHERE id = 1",
    <Object?>[rawValue],
  );
}

void main() {
  late AppDatabase db;
  late UserSettingsRepositoryImpl repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = UserSettingsRepositoryImpl(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  // ------------------------------------------------------------------
  // T1 — Decision 18 fallback: legacy SpreadType value → LayoutType.linear
  // ------------------------------------------------------------------
  group('T1 — legacy value fallback', () {
    test(
      "row.default_spread_type == 'threeCard' → defaultLayoutType == LayoutType.linear "
      '(Decision 18 graceful degradation, NOT ArgumentError)',
      () async {
        await _forceLegacyColumnValue(db, 'threeCard');

        final UserSettings settings = await repo.getSettings();

        expect(
          settings.defaultLayoutType,
          LayoutType.linear,
          reason:
              "Legacy pre-cycle-1 SpreadType value 'threeCard' must gracefully "
              'degrade to LayoutType.linear per Brief Decision 18 + Ideal '
              'Criteria #5b. Current impl raises ArgumentError from '
              'SpreadType.values.byName — that is the Red failure.',
        );
      },
    );

    test(
      "row.default_spread_type == 'single' (another legacy SpreadType value) → "
      'defaultLayoutType == LayoutType.linear',
      () async {
        await _forceLegacyColumnValue(db, 'single');

        final UserSettings settings = await repo.getSettings();

        expect(settings.defaultLayoutType, LayoutType.linear);
      },
    );
  });

  // ------------------------------------------------------------------
  // T2 — Unknown/garbage value → LayoutType.linear (Ideal Criteria #5b)
  // ------------------------------------------------------------------
  group('T2 — unknown value fallback', () {
    test(
      "row.default_spread_type == 'random_garbage' → defaultLayoutType == "
      'LayoutType.linear (graceful degradation, no crash)',
      () async {
        await _forceLegacyColumnValue(db, 'random_garbage');

        final UserSettings settings = await repo.getSettings();

        expect(
          settings.defaultLayoutType,
          LayoutType.linear,
          reason:
              'Arbitrary legacy/corrupted DB values must NOT crash the repo. '
              'Brief Ideal Criteria #5b: "byName ArgumentError 방어".',
        );
      },
    );
  });

  // ------------------------------------------------------------------
  // T3 — Happy path: canonical LayoutType value round-trips
  // ------------------------------------------------------------------
  group('T3 — canonical value preserved', () {
    test(
      "row.default_spread_type == 'tShape' → defaultLayoutType == "
      'LayoutType.tShape',
      () async {
        await _forceLegacyColumnValue(db, 'tShape');

        final UserSettings settings = await repo.getSettings();

        expect(settings.defaultLayoutType, LayoutType.tShape);
      },
    );

    test(
      "row.default_spread_type == 'grid3x3' → defaultLayoutType == "
      'LayoutType.grid3x3',
      () async {
        await _forceLegacyColumnValue(db, 'grid3x3');

        final UserSettings settings = await repo.getSettings();

        expect(settings.defaultLayoutType, LayoutType.grid3x3);
      },
    );

    test(
      "row.default_spread_type == 'linear' → defaultLayoutType == "
      'LayoutType.linear',
      () async {
        await _forceLegacyColumnValue(db, 'linear');

        final UserSettings settings = await repo.getSettings();

        expect(settings.defaultLayoutType, LayoutType.linear);
      },
    );
  });

  // ------------------------------------------------------------------
  // T4 — Decision 6: field rename reflected in the freezed entity
  // ------------------------------------------------------------------
  group('T4 — UserSettings.defaultLayoutType field contract', () {
    test(
      'UserSettings(defaultLayoutType: LayoutType.tShape, ...) compiles and '
      'round-trips via freezed copyWith',
      () {
        final UserSettings settings = UserSettings(
          defaultLayoutType: LayoutType.tShape,
          updatedAt: DateTime(2026, 1, 1),
        );

        expect(settings.defaultLayoutType, LayoutType.tShape);
        expect(settings.defaultLayoutType, isA<LayoutType>());

        final UserSettings mutated = settings.copyWith(
          defaultLayoutType: LayoutType.grid3x3,
        );
        expect(mutated.defaultLayoutType, LayoutType.grid3x3);
        // Original must remain immutable.
        expect(settings.defaultLayoutType, LayoutType.tShape);
      },
    );
  });
}
