// TDD Red — v7 → v8 migration tests (Doc 024).
//
// 4 SchemaVerifier-based tests covering Brief 011 Constraints § 테스트 4 cases:
//   T1: readings.spread_type values converted to 'linear'
//   T2: user_settings.default_spread_type → default_layout_type rename + value convert
//   T3: idempotency — re-running migrateAndValidate(db, 8) is no-op
//   T4: phantom v7.5 crash recovery — schema=v8, user_version=7
//
// Pattern: Doc 008 Research Finding D (SchemaVerifier + drift_dev codegen).
// All four tests are expected to FAIL because:
//   - app_database.dart:25 still has `schemaVersion => 7`
//   - There is no `if (from < 8)` block in onUpgrade
//   → SchemaVerifier.migrateAndValidate(db, 8) throws / mismatches.

import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personality_mobile/core/database/app_database.dart';

import '../generated_migrations/schema.dart';
import '../generated_migrations/schema_v7.dart' as v7;

void main() {
  late SchemaVerifier verifier;

  setUp(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('v7 → v8 migration', () {
    test(
      'T1: readings.spread_type values converted to linear',
      () async {
        final schema = await verifier.schemaAt(7);

        final oldDb = v7.DatabaseAtV7(schema.newConnection());
        await oldDb.into(oldDb.readings).insert(
              v7.ReadingsCompanion.insert(
                id: 'r1',
                deckId: 'rws-standard',
                spreadType: 'single',
                createdAt: DateTime(2026, 4, 1),
                updatedAt: DateTime(2026, 4, 1),
              ),
            );
        await oldDb.into(oldDb.readings).insert(
              v7.ReadingsCompanion.insert(
                id: 'r2',
                deckId: 'rws-standard',
                spreadType: 'threeCard',
                createdAt: DateTime(2026, 4, 2),
                updatedAt: DateTime(2026, 4, 2),
              ),
            );
        await oldDb.into(oldDb.readings).insert(
              v7.ReadingsCompanion.insert(
                id: 'r3',
                deckId: 'rws-standard',
                spreadType: 'custom',
                createdAt: DateTime(2026, 4, 3),
                updatedAt: DateTime(2026, 4, 3),
              ),
            );
        await oldDb.close();

        final db = AppDatabase(schema.newConnection());
        await verifier.migrateAndValidate(db, 8);

        final rows =
            await db.customSelect('SELECT spread_type FROM readings').get();
        expect(rows, hasLength(3));
        expect(
          rows.every((r) => r.data['spread_type'] == 'linear'),
          isTrue,
        );

        await db.close();
      },
    );

    test(
      'T2: user_settings.default_spread_type renamed to default_layout_type with value conversion',
      () async {
        final schema = await verifier.schemaAt(7);

        final oldDb = v7.DatabaseAtV7(schema.newConnection());
        await oldDb.into(oldDb.userSettings).insert(
              v7.UserSettingsCompanion.insert(
                defaultSpreadType: const Value('threeCard'),
                updatedAt: DateTime(2026, 4, 1),
              ),
            );
        await oldDb.close();

        final db = AppDatabase(schema.newConnection());
        await verifier.migrateAndValidate(db, 8);

        final row = await db
            .customSelect('SELECT default_layout_type FROM user_settings')
            .getSingle();
        expect(row.data['default_layout_type'], 'linear');

        // Old column must no longer exist.
        await expectLater(
          db
              .customSelect('SELECT default_spread_type FROM user_settings')
              .get(),
          throwsA(anything),
        );

        await db.close();
      },
    );

    test(
      'T3: idempotency — re-running migrateAndValidate(db, 8) is no-op',
      () async {
        final schema = await verifier.schemaAt(7);
        final db = AppDatabase(schema.newConnection());
        await verifier.migrateAndValidate(db, 8);
        // Second invocation must not throw.
        await verifier.migrateAndValidate(db, 8);
        await db.close();
      },
    );

    test(
      'T4: phantom v7.5 crash recovery — schema=v8, user_version=7',
      () async {
        // Brief Decision 5/16 + Doc 014 Critique C2.
        //
        // Simulates: a previous migration applied DDL (RENAME COLUMN, value
        // updates) but crashed before user_version was bumped to 8. On next
        // launch Drift sees user_version=7 and re-invokes onUpgrade(from=7,
        // to=8). The block must be re-entrant: the second pass should NOT
        // throw on already-migrated schema (e.g. ALTER RENAME on a column
        // that no longer exists, or UPDATE matching 0 rows is fine).
        final schema = await verifier.schemaAt(7);
        final db = AppDatabase(schema.newConnection());
        await verifier.migrateAndValidate(db, 8);

        // Force user_version back to 7 while leaving schema at v8 (phantom
        // v7.5 state).
        await db.customStatement('PRAGMA user_version = 7');
        await db.close();

        // Re-open: Drift sees user_version=7, calls onUpgrade(from=7, to=8)
        // again. impl must guard against double-application.
        final db2 = AppDatabase(schema.newConnection());
        await expectLater(
          verifier.migrateAndValidate(db2, 8),
          completes,
        );

        final versionRow =
            await db2.customSelect('PRAGMA user_version').getSingle();
        expect(versionRow.data['user_version'], 8);

        await db2.close();
      },
    );
  });
}
