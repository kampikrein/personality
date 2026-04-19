---
id: "008"
type: research
title: "Drift Schema Migration v7→v8 패턴 + 트랜잭션·테스트 가이드"
created: 2026-04-19
traces_scope: "006"
traces_brief: "005"
summary: >
  Brief 005 가정 정정: 현재 `schemaVersion = 7`이므로 마이그레이션은 v7→v8.
  기존 6번의 마이그레이션이 customStatement(ALTER/UPDATE) 패턴으로 잘 정립되어
  있어 동일 컨벤션을 그대로 확장하면 된다. 트랜잭션은 `m.database.transaction(...)`
  으로 명시적 wrap이 권장되며 (drift는 onUpgrade를 자동 트랜잭션으로 감싸지 않음),
  단위 테스트는 `SchemaVerifier` + `dart run drift_dev schema dump/generate` 로
  v7 fixture를 만들어 `migrateAndValidate(db, 8)`로 검증한다. Brief Critical
  Review #1의 (a) 트랜잭션 (b) 롤백 (c) 단위 테스트 모두 표준 패턴 확보.
keywords: [drift, migration, schema, sqlite, transaction, unit-test, schema-verifier]
---

# Drift Schema Migration v7→v8 패턴 + 트랜잭션·테스트 가이드

## Research Overview

### Background & Motivation

Brief 005 Decision 5 (DB 마이그레이션) + Critical Review #1은 Drift schema
v1→v2 마이그레이션이 (a) 트랜잭션 보장, (b) 실패 시 롤백, (c) v1 fixture →
v2 변환 단위 테스트의 표준 패턴 정립을 요구한다. impl 사이클 2가 작성하는
마이그레이션 코드는 영구 자산이 되므로 첫 사례에서 패턴을 정확히 정립해야
미래 v9, v10 등에 부채가 누적되지 않는다.

### Research Scope

**In Scope**:
- 현재 프로젝트의 `app_database.dart` 구조 + 기존 마이그레이션 패턴
- Drift `MigrationStrategy.onUpgrade` 표준 사용법
- 트랜잭션 자동 보장 여부 + 명시적 트랜잭션 패턴
- `SchemaVerifier` + drift_dev codegen 단위 테스트 패턴
- Schema snapshot dump 명령 (`drift_dev schema dump/generate`)
- v7→v8 마이그레이션 prototype 코드 + 단위 테스트 prototype

**Out of Scope**:
- 다른 테이블의 마이그레이션 (이번엔 readings + user_settings만)
- LayoutType 도메인 모델 자체 (Research axis 1에서 다룸)
- 결과 페이지 렌더링 (Research axis 3)

### Research Perspectives

단일 통합 관점 (Drift migration 패턴 조사). 외부 공식 문서 + 프로젝트 코드 +
이슈 트래커가 모두 동일한 답으로 수렴 → Path A (직접 조사).

### Related Documents

- Brief: [005_Brief_layout_redesign.md](./005_Brief_layout_redesign.md)
- Scope: [006_Scope_layout_redesign.md](./006_Scope_layout_redesign.md)
- Research axis 1: [007_Research_enhanced_enum_codegen.md](./007_Research_enhanced_enum_codegen.md)

---

## Status Analysis (현재 프로젝트의 Drift 마이그레이션 구조)

### 1. Schema Version 현황 — **v7** (Brief 005 가정 정정)

`mobile/lib/core/database/app_database.dart:25`:

```dart
@override
int get schemaVersion => 7;
```

→ **Brief 005 Decision 5의 "v1 → v2" 표현은 부정확**. 실제는 **v7 → v8** 이며,
이미 6번의 마이그레이션 사이클이 누적되어 있다. 이는 오히려 좋은 신호 —
프로젝트가 이미 마이그레이션 컨벤션을 잘 정립했고 새 사이클은 컨벤션 확장만
하면 된다.

### 2. 기존 마이그레이션 패턴 (`app_database.dart:28-70`)

```dart
@override
MigrationStrategy get migration => MigrationStrategy(
      onCreate: (Migrator m) => m.createAll(),
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(userSettingsTable);
        }
        if (from < 3) {
          await m.database.customStatement(
            "UPDATE user_settings SET experience_level = 3, default_spread_type = 'custom'",
          );
        }
        if (from < 4) {
          await m.database.customStatement(
            'ALTER TABLE user_settings ADD COLUMN show_card_name INTEGER DEFAULT 1',
          );
          // ... 추가 ALTER
        }
        if (from < 5) {
          // ALTER TABLE user_settings ADD COLUMN card_size_preset TEXT DEFAULT 'standardTarot'
          // ALTER TABLE user_settings ADD COLUMN custom_card_width_mm REAL DEFAULT 70.0
          // ALTER TABLE user_settings ADD COLUMN custom_card_height_mm REAL DEFAULT 120.0
        }
        if (from < 6) {
          await m.database.customStatement(
            'ALTER TABLE user_settings ADD COLUMN cards_per_row INTEGER DEFAULT 3',
          );
        }
        if (from < 7) {
          // 기존 풀셔플(3) 사용자를 2.5D(4)로 마이그레이션
          await m.database.customStatement(
            'UPDATE user_settings SET experience_level = 4 WHERE experience_level = 3',
          );
        }
      },
    );
```

**기존 컨벤션**:
- 모든 사이클이 `if (from < N)` 가드로 단방향 누적
- `m.database.customStatement('SQL')` 패턴 일관 사용
- ALTER TABLE ADD COLUMN, UPDATE 양쪽 모두 customStatement
- 트랜잭션 명시 wrap 없음 (drift 기본 동작에 의존)
- 주석으로 의도 설명 (`// 기존 풀셔플(3) 사용자를 2.5D(4)로 마이그레이션`)

### 3. drift_dev / 테스트 인프라 현황

`mobile/test/` 디렉토리 (`mobile/test/widget_test.dart` 외 6개):
- 마이그레이션 테스트 0건 — 신규 도입
- `test/generated_migrations/` 디렉토리 없음 — 첫 schema dump 필요

→ **신규 작업 필수**:
1. `dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/` (v7까지의 schema snapshot 생성)
2. `dart run drift_dev schema generate --data-classes --companions drift_schemas/ test/generated_migrations/` (v7 data classes 생성)
3. `mobile/test/database/migration_v7_to_v8_test.dart` 신규 작성

---

## Detailed Findings

### Finding A — `MigrationStrategy.onUpgrade` 표준 사용법

[Drift Migrations 공식 가이드](https://drift.simonbinder.eu/migrations/):

```dart
@override
MigrationStrategy get migration {
  return MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // 누적 가드 패턴
      if (from < 2) { /* v1 → v2 변경 */ }
      if (from < 3) { /* v2 → v3 변경 */ }
      // ...
    },
    beforeOpen: (details) async {
      // 매 DB open 시 실행 (마이그레이션 후 1회)
      // 데이터 시드, foreign keys 활성화 등
    },
  );
}
```

**핵심 메커니즘**:
- `Migrator` 객체는 `createTable`, `createIndex`, `addColumn`, `alterTable`,
  `deleteTable` 등 표준 메서드 + `customStatement`로 raw SQL 실행
- `from`/`to`는 `schemaVersion` 변경 전후 값. 누적 가드로 v1→v8 같은 다단계
  업그레이드도 자동 처리

### Finding B — 트랜잭션 자동 보장 부재 + 명시적 패턴

[Drift API 문서](https://pub.dev/documentation/drift/latest/drift/MigrationStrategy-class.html)
및 [GitHub issue #3174](https://github.com/simolus3/drift/issues/3174):

**기본 동작**:
- `onUpgrade` 자체는 자동 트랜잭션으로 감싸지지 **않는다**.
- 각 `customStatement('ALTER TABLE ...')` 는 SQLite의 자동 commit 모드에서
  즉시 적용됨 (DDL은 SQLite에서 implicit transaction).
- 마이그레이션 중간에 예외가 발생하면 이미 적용된 statement는 롤백되지 않고,
  `schemaVersion`은 갱신되지 않은 채 다음 앱 실행 시 같은 onUpgrade가 다시
  실행됨 → 일부 부분 적용 상태 가능성

**명시적 트랜잭션 패턴 (권장)**:

```dart
if (from < 8) {
  await m.database.transaction(() async {
    await m.database.customStatement('UPDATE readings SET ...');
    await m.database.customStatement('UPDATE user_settings SET ...');
    await m.database.customStatement('ALTER TABLE user_settings RENAME COLUMN ...');
  });
}
```

`m.database.transaction(() async { ... })` 으로 wrap 시:
- 블록 내 모든 statement가 단일 트랜잭션
- 블록 내 예외 throw 시 자동 ROLLBACK
- 블록 정상 종료 시 자동 COMMIT

**중요 제약**: SQLite는 **DDL (ALTER TABLE 등) 을 트랜잭션 안에서 지원하지만,
일부 DDL 작업은 implicit commit을 트리거할 수 있다**. 특히 `CREATE TABLE`은
기존 트랜잭션과 호환되지 않는 경우 있음. UPDATE/INSERT/DELETE 같은 DML은
완전 트랜잭션 호환.

→ **이번 v7→v8 작업의 ALTER TABLE RENAME COLUMN + UPDATE 조합은 SQLite 3.25+
   에서 트랜잭션 호환**. 단 PRAGMA foreign_keys 설정 권장 (외래키 강제 검증
   회피).

### Finding C — Foreign Key Pragma 패턴 (권장)

```dart
onUpgrade: (Migrator m, int from, int to) async {
  await m.database.customStatement('PRAGMA foreign_keys = OFF');
  try {
    if (from < 8) {
      await m.database.transaction(() async {
        // ... migration statements
      });
    }
  } finally {
    await m.database.customStatement('PRAGMA foreign_keys = ON');
  }
},
```

이 패턴은 ALTER TABLE이 외래키 제약을 일시적으로 깨뜨릴 수 있는 경우 안전.
이번 작업은 readings/user_settings 컬럼 변경만이라 외래키 영향 없음 (readings.deckId
는 그대로) → **PRAGMA foreign_keys 토글은 선택사항이지만 패턴 정립 차원에서
권장**.

### Finding D — `SchemaVerifier` 단위 테스트 패턴

[Drift Testing Migrations 공식 가이드](https://drift.simonbinder.eu/migrations/tests/):

**1단계 — Schema dump (앱 코드 변경 전 실행)**:
```bash
cd mobile
dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/
```

→ `drift_schemas/drift_schema_v7.json` 생성 (현재 schema 스냅샷). 이 파일을
git에 commit해야 향후 마이그레이션 테스트가 가능.

**2단계 — Data class generation**:
```bash
dart run drift_dev schema generate --data-classes --companions drift_schemas/ test/generated_migrations/
```

→ `test/generated_migrations/schema.dart`, `schema_v7.dart` 등 생성.
`schema_v7.dart`는 v7 시점의 모든 테이블 + Companion + DataClass 포함.

**3단계 — Migration test 작성**:

```dart
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personality_mobile/core/database/app_database.dart';

import 'generated_migrations/schema.dart';
import 'generated_migrations/schema_v7.dart' as v7;

void main() {
  late SchemaVerifier verifier;

  setUp(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('v7 → v8 migration', () {
    test('readings.spread_type values converted to linear', () async {
      // v7 schema로 connection 생성
      final schema = await verifier.schemaAt(7);

      // v7 data class로 fixture 데이터 삽입
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

      // 실제 AppDatabase로 v8 마이그레이션 실행 + schema 검증
      final db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, 8);

      // 데이터 변환 확인
      final readings = await db.select(db.readings).get();
      expect(readings, hasLength(3));
      expect(readings.every((r) => r.spreadType == 'linear'), isTrue);

      await db.close();
    });

    test('user_settings.default_spread_type → default_layout_type rename + value convert', () async {
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

      // v8에서는 컬럼명이 default_layout_type 이고 값은 'linear'
      final settings = await db.select(db.userSettingsTable).getSingle();
      expect(settings.defaultLayoutType, 'linear');
      // (실제 필드명은 v8 schema의 generate 출력에 따름)

      await db.close();
    });

    test('migration is idempotent (running v8 again on v8 = no-op)', () async {
      final schema = await verifier.schemaAt(7);
      final db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, 8);
      // 한 번 더 실행해도 에러 없음
      await verifier.migrateAndValidate(db, 8);
      await db.close();
    });
  });
}
```

**4단계 — CI에 schema dump 자동 검증** (선택, 향후 사이클):
- `beforeOpen` 콜백에서 `kDebugMode` 시 `validateDatabaseSchema()` 호출하여
  실행 시 schema가 generate된 reference와 일치하는지 확인.

### Finding E — pubspec.yaml에 `drift_dev` 이미 포함

`mobile/pubspec.yaml:54` `drift_dev: ^2.22.0` 이미 dev_dependencies에 포함.
schema dump/generate 명령 즉시 실행 가능.

### Finding F — SQLite ALTER TABLE RENAME COLUMN 지원

SQLite 3.25.0 (2018-09-15) 이상 지원. `sqlite3_flutter_libs ^0.5.0`은 SQLite
3.40+ 번들 → 안전하게 사용 가능.

```sql
ALTER TABLE user_settings RENAME COLUMN default_spread_type TO default_layout_type;
```

→ Brief 005 Decision 6 (UserSettings 필드명 + DB 컬럼명 변경) 실현 가능.

---

## Caveats & Risks

| 위험 | 가능성 | 완화책 |
|------|--------|--------|
| onUpgrade 자동 트랜잭션 미보장 → 부분 적용 | 중간 | `m.database.transaction(...)` 명시적 wrap |
| Schema dump 누락 시 테스트 작성 불가 | 높음 (현재 dump 0회) | 첫 작업으로 `drift_dev schema dump` 실행 + git commit |
| 컬럼 rename 후 Repository 코드 미동기 | 중간 | UserSettings repository의 모든 `default_spread_type` 참조 grep + 갱신 |
| reading.spreadType 컬럼명 비일관성 | 낮음 | 의도적 수용 — readings.spread_type 컬럼명 유지 (마이그레이션 부담 ↓), 도메인 코드는 LayoutType으로 통일 |
| v7 fixture에 v8 컬럼이 없어 generate 실패 | 낮음 | drift_dev가 자동 처리 (각 버전별 generate) |
| 다른 개발자 환경의 v7 DB가 fresh start되지 않음 | 낮음 (출시 전이므로 영향 작음) | 개발자별 로컬 DB 삭제 옵션 안내 |

---

## Comprehensive Conclusion

### 핵심 발견 (우선순위 순)

1. **[Critical] R-008-F1: Brief 005 Decision 5의 "v1 → v2" 표현은 정정 필요 — 실제는 v7 → v8** *(Status Analysis 1)*

2. **[Critical] R-008-F2: 기존 6 사이클의 마이그레이션 패턴(`m.database.customStatement('ALTER/UPDATE ...')`)이 정립되어 있어 동일 컨벤션 확장만 하면 된다** *(Status Analysis 2)*

3. **[Critical] R-008-F3: 트랜잭션은 자동 보장되지 않으므로 `m.database.transaction(...)` 명시적 wrap 필수. 예외 throw 시 자동 ROLLBACK** *(Finding B)*

4. **[High] R-008-F4: `SchemaVerifier` + drift_dev codegen으로 단위 테스트 패턴 표준화. `dart run drift_dev schema dump → generate` 가 prerequisite** *(Finding D)*

5. **[High] R-008-F5: drift_dev는 이미 dev_dependencies에 포함되어 있어 즉시 사용 가능** *(Finding E)*

6. **[High] R-008-F6: SQLite ALTER TABLE RENAME COLUMN은 SQLite 3.25+ 지원 — sqlite3_flutter_libs ^0.5.0이 충분히 최신 버전 번들** *(Finding F)*

7. **[Medium] R-008-F7: PRAGMA foreign_keys 토글 패턴은 이번 작업에서 선택사항이지만 미래 사이클을 위해 정립 권장** *(Finding C)*

8. **[Medium] R-008-F8: Brief Critical Review #1의 (a) 트랜잭션 (b) 롤백 (c) 단위 테스트 모두 표준 패턴 확보됨 — fallback (schema reset) 발동 안 함** *(Finding A~F 종합)*

### v7 → v8 마이그레이션 Prototype (impl 사이클 2 시작 코드)

`mobile/lib/core/database/app_database.dart:25` `schemaVersion 7 → 8` 변경 후:

```dart
@override
int get schemaVersion => 8;

@override
MigrationStrategy get migration => MigrationStrategy(
      onCreate: (Migrator m) => m.createAll(),
      onUpgrade: (Migrator m, int from, int to) async {
        // ... 기존 v1~v7 사이클 그대로 유지

        if (from < 8) {
          // SpreadType → LayoutType 도메인 정렬 마이그레이션
          // - readings.spread_type 컬럼명 유지 (값만 변환)
          // - user_settings.default_spread_type → default_layout_type 컬럼 rename + 값 변환
          // - 모든 기존 enum 값 (single/threeCard/custom) 을 'linear' 로 매핑
          // - 위치 의미(positions) 손실 수용 (도메인 변경)

          await m.database.customStatement('PRAGMA foreign_keys = OFF');
          try {
            await m.database.transaction(() async {
              // (1) readings 테이블의 spread_type 값 변환
              await m.database.customStatement(
                "UPDATE readings SET spread_type = 'linear' "
                "WHERE spread_type IN ('single', 'threeCard', 'custom')",
              );

              // (2) user_settings 테이블의 default_spread_type 값 변환
              await m.database.customStatement(
                "UPDATE user_settings SET default_spread_type = 'linear' "
                "WHERE default_spread_type IN ('single', 'threeCard', 'custom')",
              );

              // (3) user_settings 컬럼 rename (Brief Decision 6)
              await m.database.customStatement(
                'ALTER TABLE user_settings RENAME COLUMN default_spread_type '
                'TO default_layout_type',
              );
            });
          } finally {
            await m.database.customStatement('PRAGMA foreign_keys = ON');
          }
        }
      },
    );
```

### 결론 (Research Axis 2 핵심 질문에 대한 답)

**해결됨**. 표준 onUpgrade 패턴 + 명시적 트랜잭션 + SchemaVerifier 단위 테스트
모두 표준 패턴이 확보되었다. Brief 005 Decision 5의 "v1→v2" 표현은 "v7→v8"
로 정정 필요. 기존 마이그레이션 컨벤션을 그대로 확장하면 충분하며 fallback
(schema reset) 발동 불필요. Critical Review #1 해소.

**impl 사이클 2 prerequisite (실행 순서)**:
1. `cd mobile && dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/`
2. `git add drift_schemas/ && git commit -m "drift: snapshot v7 schema for migration testing"`
3. `dart run drift_dev schema generate --data-classes --companions drift_schemas/ test/generated_migrations/`
4. `app_database.dart` schemaVersion 8 + onUpgrade if-block 추가
5. `mobile/test/database/migration_v7_to_v8_test.dart` 작성
6. `dart test test/database/migration_v7_to_v8_test.dart` 통과 확인

## Incremental Summary

### 리서치 축
- **축 이름**: drift-migration-pattern
- **핵심 질문**: Drift schema v7→v8 (Brief 가정의 v1→v2 정정) 마이그레이션의
  (a) 트랜잭션 보장 범위, (b) onUpgrade 표준 패턴, (c) 실패 시 롤백, (d) v7
  fixture → v8 변환 단위 테스트 패턴

### 핵심 발견 (우선순위 순)
1. **[Critical] R-008-F1: Brief 가정 정정 — v1→v2가 아니라 v7→v8** (현재 schemaVersion = 7)
2. **[Critical] R-008-F2: 기존 6 사이클이 customStatement 패턴으로 컨벤션 정립** — 동일 컨벤션 확장만 하면 됨
3. **[Critical] R-008-F3: 트랜잭션 자동 보장 안 됨 → `m.database.transaction()` 명시적 wrap 필수** (예외 시 자동 ROLLBACK)
4. **[High] R-008-F4: SchemaVerifier + drift_dev codegen 표준 테스트 패턴** (`schema dump → generate → migrateAndValidate`)
5. **[High] R-008-F5: drift_dev 이미 포함됨, 즉시 사용 가능**
6. **[High] R-008-F6: SQLite ALTER RENAME COLUMN 지원 (SQLite 3.25+)** — sqlite3_flutter_libs 충분히 최신
7. **[Medium] R-008-F7: PRAGMA foreign_keys 토글 권장 패턴** (이번 작업 외래키 영향 없지만 패턴 정립 차원)
8. **[Medium] R-008-F8: Critical Review #1 모든 항목 (트랜잭션·롤백·테스트) 표준 패턴 확보 — fallback 불필요**

### 결론

**해결됨** — Brief CR#1의 모든 우려 항목이 표준 패턴으로 답해졌고, 가정 오류
(v1→v2 → v7→v8) 정정도 명확히 식별. impl 사이클 2 prerequisite 실행 순서
6단계 명세 완료. fallback (schema reset) 불필요.

### 미해결 사항

None.

## Unresolved Items

None — Brief CR#1의 모든 항목 해결 + Brief 가정 오류 (v1→v2) 정정 + impl 사이클
2 prerequisite 명세 완료.

## Referenced File List

| File Path | Related Perspective | Role/Content |
|-----------|-------------------|--------------|
| `mobile/lib/core/database/app_database.dart` | 현재 schemaVersion 7 + 기존 마이그레이션 패턴 | 라인 25 (schemaVersion), 28-70 (MigrationStrategy onUpgrade 6 사이클) |
| `mobile/lib/core/database/tables/readings_table.dart` | spread_type TextColumn | 마이그레이션 대상 컬럼 (값만 변환) |
| `mobile/lib/core/database/tables/user_settings_table.dart` | default_spread_type TextColumn | 마이그레이션 대상 컬럼 (값 변환 + 컬럼 rename) |
| `mobile/pubspec.yaml` | drift_dev ^2.22.0 dev_dep | schema dump/generate 명령 즉시 실행 가능 |
| `mobile/test/widget_test.dart` 외 6개 | 기존 테스트 디렉토리 | migration test 0건 — 신규 작성 필요 |

## External Sources

- [Drift Migrations 공식 가이드](https://drift.simonbinder.eu/migrations/) — onUpgrade 표준 사용법
- [MigrationStrategy class API](https://pub.dev/documentation/drift/latest/drift/MigrationStrategy-class.html) — 시그니처/동작 명세
- [Migrator class API](https://pub.dev/documentation/drift/latest/drift/Migrator-class.html) — createTable, addColumn, customStatement 등
- [Schema migration helpers](https://drift.simonbinder.eu/migrations/step_by_step/) — stepByStep 유틸 (선택사항)
- [Testing Drift Migrations](https://drift.simonbinder.eu/migrations/tests/) — SchemaVerifier 패턴
- [The migrator API](https://drift.simonbinder.eu/migrations/api/) — Migrator 메서드 전체
- [Drift FAQ](https://drift.simonbinder.eu/faq/) — 트랜잭션 행동 + 마이그레이션 FAQ
- [GitHub: drift issue #3174](https://github.com/simolus3/drift/issues/3174) — ALTER TABLE 마이그레이션 오류 사례
- [Database migration Drift flutter dart (Medium)](https://medium.com/@tagizada.nicat/migration-with-flutter-drift-c9e21e905eeb) — 실용 예제
- [Drift Local Database For Flutter (Medium)](https://r1n1os.medium.com/drift-local-database-for-flutter-part-1-intro-setup-and-migration-09a64d44f6df) — 실용 가이드

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 117s | 344643 |
| 2 | user-ai-exchange | 235s | 1232689 |
| 3 | user-ai-exchange | 213s | 1123755 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 3776s |
| Total Tokens | 2701087 |
| Input Tokens | 47 |
| Output Tokens | 41487 |
| Cache Read | 2543784 |
| Cache Creation | 115769 |
