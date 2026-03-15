import 'dart:io';

import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'app_database.dart';

Future<AppDatabase> constructDb() async {
  if (Platform.isAndroid) {
    await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
  }

  final dir = await getApplicationDocumentsDirectory();
  final file = File(p.join(dir.path, 'personality_tarot.db'));

  return AppDatabase(
    NativeDatabase.createInBackground(
      file,
      setup: (rawDb) {
        rawDb.execute('PRAGMA journal_mode = WAL');
        rawDb.execute('PRAGMA foreign_keys = ON');
        rawDb.execute('PRAGMA synchronous = NORMAL');
      },
    ),
  );
}
