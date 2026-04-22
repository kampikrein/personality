import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/user_settings_table.dart';

part 'user_settings_dao.g.dart';

@DriftAccessor(tables: [UserSettingsTable])
class UserSettingsDao extends DatabaseAccessor<AppDatabase>
    with _$UserSettingsDaoMixin {
  UserSettingsDao(super.db);

  /// 설정을 Stream으로 제공. 단일 행(id=1) 패턴.
  /// 행이 없으면 기본값으로 INSERT 후 반환.
  Stream<UserSettingsTableData> watchSettings() {
    return (select(userSettingsTable)
          ..where((s) => s.id.equals(1)))
        .watchSingleOrNull()
        .asyncMap((row) async {
      if (row != null) return row;
      await _ensureDefaultRow();
      return await (select(userSettingsTable)
            ..where((s) => s.id.equals(1)))
          .getSingle();
    });
  }

  /// 동기 조회용. 캐시 초기화에 사용.
  Future<UserSettingsTableData> getSettings() async {
    final row = await (select(userSettingsTable)
          ..where((s) => s.id.equals(1)))
        .getSingleOrNull();
    if (row != null) return row;
    await _ensureDefaultRow();
    return (select(userSettingsTable)
          ..where((s) => s.id.equals(1)))
        .getSingle();
  }

  /// 설정 업데이트. 단일 행(id=1)만 대상.
  Future<void> updateSettings(UserSettingsTableCompanion companion) async {
    await (update(userSettingsTable)
          ..where((s) => s.id.equals(1)))
        .write(companion.copyWith(
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// 의도 입력 배치 설정 업데이트. [value]는 IntentPlacement.name (e.g. 'beforeShuffle').
  Future<void> updateIntentPlacement(String value) async {
    await _ensureDefaultRow();
    await (update(userSettingsTable)
          ..where((s) => s.id.equals(1)))
        .write(UserSettingsTableCompanion(
      intentPlacement: Value(value),
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<void> _ensureDefaultRow() async {
    final exists = await (select(userSettingsTable)
          ..where((s) => s.id.equals(1)))
        .getSingleOrNull();
    if (exists != null) return;
    await into(userSettingsTable).insert(
      UserSettingsTableCompanion.insert(updatedAt: DateTime.now()),
    );
  }
}
