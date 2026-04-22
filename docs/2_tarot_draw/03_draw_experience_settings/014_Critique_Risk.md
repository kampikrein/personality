---
id: "014"
type: critique
title: "Brief 011 Critique — Risk Analysis"
created: 2026-04-20
status: completed
perspective: "risk"
target: "011"
confidence: high
summary: >
  Brief 011 은 Research 3축 (007/008/009) 이 식별한 일급 위험 (트랜잭션,
  enum codegen, 렌더링 접근)을 체계적으로 해소했으나, 다음 6 영역에 잠재
  리스크가 남아 있다: (1) Drift `user_version` 갱신과 onUpgrade 사이 crash
  지점, (2) migration 비-idempotency — `ALTER COLUMN RENAME` 2회 실행 시
  SQLite 에러, (3) In Scope #9 "슬라이더 변경 시 재셔플"이 현 코드 아키텍처
  (settings는 persist만, 재셔플은 페이지 재진입 시점)와 불일치, (4) 이미
  커밋된 `drift_schemas/` 스냅샷이 schemaVersion 이 여전히 7인 상태에서
  찍혔는지 개발자 로컬 DB 상태에 종속, (5) `byName()` parse 실패 경로
  (hot reload/race) 에서 사용자 설정 전체 crash, (6) `ValueKey('card-$drawIdx')`
  기반 애니메이션 보존이 cardCount 축소 (7→5) 케이스에서는 기대대로
  작동하나 GridView.builder의 itemCount 축소가 StatefulWidget 재빌드를
  트리거할 수 있음. 총 14개 구체 위험 식별.
keywords: [critique, brief, risk, migration, regression, data-safety, idempotency, drift, crash-recovery]
---

# Brief 011 Critique — Risk Analysis

## Executive Summary

Brief 011 은 research 3 축 결과를 반영해 Brief 005 의 주요 위험 (migration 트랜잭션, enum codegen 호환, 렌더링 분기) 을 해소했다. 트랜잭션 wrap + PRAGMA 토글 + SchemaVerifier 테스트 + 명시적 snapshot 관리 같은 "교과서적" 패턴이 잘 정립되어 있어 큰 그림은 견고하다. 다만 **crash 복구 경로**, **migration 재실행 idempotency**, **spec↔code 미스매치 (In Scope #9)**, **Dart 런타임 종속성 (`byName` throw)**, **이미 커밋된 snapshot 의 신선도** 에서 구체적 위험이 남는다.

가장 치명적인 위험은 다음 두 가지:

1. **Migration non-idempotency (Critical)** — Brief 의 Ideal Criteria #5 는 "롤백 동작"만 요구하고, 실제로 위험한 "crash 후 재실행" 시나리오에서 `ALTER TABLE ... RENAME COLUMN default_spread_type TO default_layout_type` 는 2번째 호출에서 `no such column: default_spread_type` 로 throw 한다. 즉 R-008-F8 "fallback 불필요" 결론이 너무 낙관적.
2. **`user_version` ↔ migration 간 크래시 창 (Critical)** — `engines.dart:514-518` 에서 `setSchemaVersion(8)` 은 onUpgrade 완료 *후* 별도 statement 로 실행된다. onUpgrade 트랜잭션 자체는 성공했지만 그 직후 프로세스 kill (OS) 시 DB 는 v8 schema, PRAGMA user_version 은 여전히 7 → 다음 실행 시 onUpgrade 재실행 → ALTER TABLE fail. Brief 의 트랜잭션 wrap 만으로는 이 창을 닫지 못한다.

---

## Findings

### Strengths (Brief 가 잘 처리한 위험 완화)

1. **명시적 트랜잭션 wrap (Decision 16)** — R-008-F3 의 "onUpgrade 는 자동 트랜잭션 아님" 이슈 해소.
2. **PRAGMA foreign_keys 토글 (Decision 16)** — 이번엔 불필요하지만 DrawnCards → Readings FK 가 존재하므로 미래 대비 가치 있음.
3. **SchemaVerifier + drift_schemas/ git commit (Decision 17, In Scope #10)** — 실제로 `5a62332` 커밋에서 v7 snapshot + generated_migrations 가 이미 체크인됨.
4. **Enhanced enum fallback 제거 (Decision 13)** — R-007 호환성 재확인으로 과도한 방어 코드 회피.
5. **결과 페이지 `ValueKey('card-$drawIdx')` 애니메이션 보존 (Constraints § 컴포넌트 재사용)** — StatefulWidget dispose/recreate 창 최소화.
6. **GridView `key: ValueKey(layoutType)` 로 배치 전환 시 트리 재생성 (Model Anchors § 렌더링 전략)** — reveal 컨트롤러 누수 회피.
7. **readings.spread_type 컬럼명 유지 + 값만 변환 (Decision 5)** — FK 연쇄 변경 회피.
8. **sqlite3_flutter_libs 0.5.0 = SQLite 3.40+ 확인 (Constraints § 환경)** — ALTER RENAME COLUMN (3.25+) 안전성 검증.

### Risks / Weaknesses

| # | Risk | Severity | Trigger Condition | Blast Radius | Mitigation |
|---|------|----------|-------------------|--------------|------------|
| R1 | `ALTER TABLE ... RENAME COLUMN default_spread_type TO default_layout_type` 2회 실행 시 SQLite 에러 `no such column: default_spread_type` | **critical** | onUpgrade 성공 후 `setSchemaVersion(8)` 실행 *전* 에 프로세스 kill (OS OOM, 앱 강제종료, SIGKILL), 다음 실행 시 `PRAGMA user_version`=7 → onUpgrade (from=7) 재실행 | Data (앱 시작 실패, 사용자 DB 손상 — 수동 복구 불가) | onUpgrade 블록에 `PRAGMA user_version=8` 을 트랜잭션 내부 *마지막*에 추가 (Drift 의 delegated setSchemaVersion 과 중복되지만 원자성 확보) OR 테이블 스키마 확인 후 조건부 RENAME (`SELECT COUNT(*) FROM pragma_table_info('user_settings') WHERE name='default_spread_type'`) |
| R2 | Ideal Criteria #5 "롤백 동작 확인"이 **crash 후 재실행 idempotency** 를 커버하지 않음 | **critical** | 마이그레이션 테스트 3 케이스 중 "Idempotency" 는 "v8 상태에서 migrateAndValidate(db, 8) 재실행" 인데, 실제 위험은 "v7→v8 중간 crash → v7로 다시 onUpgrade 재실행" 이다. 둘은 다른 시나리오 | Data (production crash 복구 실패) | Constraints § 테스트에 "crash recovery 시나리오" 케이스 추가: v7 fixture + mid-migration kill 시뮬레이션 → schemaVersion=7 재진입 → 재migration 성공 검증 |
| R3 | `SpreadType.values.byName(row.spreadType)` 는 DB 값이 enum 에 없을 때 `ArgumentError` throw — migration 실행 *직전* Dart 코드가 먼저 실행되는 race (예: hot reload, 앱 시작 초기화 순서) 시 앱 crash | **major** | Dart 쪽이 `SpreadType` → `LayoutType` 으로 rename 되었는데 DB 는 여전히 v7 값 (`single`/`threeCard`/`custom`) 인 창. 개발자 hot reload 시 발생 가능 | Dev (개발자 iteration 마찰) / UX (첫 앱 시작 시 crash) | Repository `_toDomain` 에 `orElse: LayoutType.linear` fallback 추가: `LayoutType.values.firstWhere((t) => t.name == row.spreadType, orElse: () => LayoutType.linear)`. `byName` 사용 금지 |
| R4 | In Scope #9 "슬라이더 변경 시 재셔플" 이 **현 코드 아키텍처와 불일치** — `home_page.dart:447` 은 `repo.updateDefaultCardCount(v)` 로 persist만 하고, `shuffleStateProvider.clear()` / 재셔플 호출 없음 | **major** | 사용자가 홈에서 배치 `linear → grid3x3` 전환 → cardCount 자동 3→9 클램프 → 기대: 셔플 재실행. 실제: 다음 뽑기 페이지 진입 시에만 셔플 | UX (사용자 기대 위배 + 이전 셔플 결과 재사용) | 홈 패널의 배치/카드수 `onChanged` 콜백에서 `ref.read(shuffleStateProvider.notifier).clear()` 명시 호출. Brief 에 "홈 설정 변경이 shuffle state invalidation 트리거" 조항 추가 |
| R5 | 이미 커밋된 `mobile/drift_schemas/drift_schema_v7.json` + `test/generated_migrations/schema_v7.dart` (5a62332) 가 **brief-pre 시점 스냅샷** — 다른 개발자가 로컬에서 dump 재실행 시 동일성 보장 안 됨 (dart/sqlite 버전, timestamp, 정렬 차이) | **major** | CI / 다른 개발자 머신에서 schema dump 재실행 → diff → 커밋 충돌 / 재생성 유혹 | Dev (팀 워크플로 혼란) / Data (v7 reference 변조 시 테스트 가짜통과) | Brief Constraints § codegen 에 "v7 snapshot 재생성 금지 (deterministic 보장 안 됨)" 명시 + `drift_dev schema dump` 를 CI 에서 검증만 (재커밋 금지) |
| R6 | Drift `user_version` 갱신과 onUpgrade 사이 crash 창 (R-008 에도 미논의) | **major** | `engines.dart:485-521` `_runMigrations`: onUpgrade 끝나고 `setSchemaVersion(8)` 은 *별도 PRAGMA statement*. 두 지점 사이 프로세스 kill 시 DB 는 v8 shape, PRAGMA 는 v7 → R1 재발 | Data (R1 과 동일) | Brief Model Anchors § DB 마이그레이션 블록의 트랜잭션 *내부* 에 `PRAGMA user_version = 8` 추가 statement. Drift 의 이후 setSchemaVersion(8) 은 no-op idempotent | 
| R7 | `build_runner build --delete-conflicting-outputs` 를 impl 사이클 1 (enum 변경) 과 사이클 2 (schema 변경) 에서 각각 실행하면 cycle 1 에서 생성된 `reading.g.dart` 의 `_$SpreadTypeEnumMap` 이 cycle 2 의 DB 스키마 변경 (컬럼 rename) 후에도 남아있을 수 있음 | minor | sync/clean 순서 실수. Dart dev_tool 의 부분 재생성 | Dev (test 시 enum map 불일치) | 사이클 2 시작 시 `flutter clean` + `build_runner build --delete-conflicting-outputs` 순서 명시. Brief 에 "사이클 간 build_runner 는 clean 상태에서 재실행" 추가 |
| R8 | `ValueKey('card-$drawIdx')` + cardCount 축소 (7→5) 시: GridView.builder 가 `itemCount` 7→5 로 바뀌면 slot 5, 6 의 위젯은 부모 트리에서 제거됨. CardRevealWidget 의 `_controller.dispose()` 호출 → 이후 cardCount 7 로 다시 늘릴 때 새 컨트롤러 생성 (이전 reveal 상태 유실) | minor | 사용자가 cardCount 축소→확대 연속 조작. T모양 기본 4→7→4 같은 애니메이션 중 slider drag | UX (reveal 진행 중이던 카드가 "reset") | 허용 가능 (Brief Out of Scope 성격) — 단 Ideal Criteria 에 "cardCount 변경 시 기존 reveal 은 유지되지 않음" 명시 권장 |
| R9 | Brief Model Anchors § DB 블록의 `ALTER TABLE user_settings RENAME COLUMN default_spread_type TO default_layout_type` 이후 **Drift 생성 코드 (`app_database.g.dart`) 의 컬럼명도 `defaultLayoutType` 으로 바뀜**. 따라서 migration 실행 중 `select(userSettingsTable)` 가 돌면 "no such column: default_layout_type" (migration 중간) 또는 "no such column: default_spread_type" (migration 실패 시) 양방향 에러 가능 | minor | migration 블록 내에서 DAO 호출 금지 (Brief 에 명시 없음) | Dev (패턴 오염) | Brief Constraints 에 "onUpgrade 블록 내 DAO 직접 호출 금지 — customStatement 만 허용" 명시 |
| R10 | `drawToSlot(int, int)` 가 GridView.builder itemBuilder 에서 slot→draw 역매핑 계산에만 사용되는 구조 — slotToDraw Map 을 builder 시작시 한 번 만든다. 그러나 reveal 애니메이션으로 60fps rebuild 발생 시 build() 자체가 재호출됨 → Map 재생성. `O(cardCount)` 에 불과해 성능 영향은 미미하나 (max 10), `StatelessWidget.build` 내에서 매 프레임 매 프레임 재할당 | minor | 최대 10 엔트리 Map × 60fps = 600 할당/s — 프로파일러 상 노이즈 | Performance (매우 경미) | 필요시 `SpreadLayout` 을 `StatefulWidget` 로 바꿔 slotToDraw 를 `didChangeDependencies` 에서 캐시. 지금은 YAGNI |
| R11 | `ValueKey(layoutType)` 로 GridView 트리 재생성 시 **reveal 중이던 카드의 `_controller` 전체 dispose** → 배치 전환만으로도 앞서 뒤집힌 카드가 "다시 뒷면" 으로 보임 | minor | 사용자가 linear 3장 뒤집는 중에 tShape 전환. Brief 의 Decision 11 "배치 변경 시 reshuffle" 정책과 정합하나 명시 없음 | UX (의도된 부작용이지만 사용자 놀람 가능) | Brief Ideal Criteria 에 "배치 전환 시 reveal 상태 초기화" 명시 |
| R12 | 회전 (device rotation) 시 GridView.builder 의 `childAspectRatio = cardAspectRatio * 0.9` 가 portrait/landscape 동일 값 → landscape 에서 카드가 세로로 찌그러짐 | minor | 사용자가 그리드 결과 페이지에서 기기 회전 | UX (시각 찌그러짐) | 시각 검증 5종에 rotation 케이스 미포함. Brief 에 "landscape/rotation 은 out of scope" 명시하거나 MediaQuery.orientation 분기 추가 |
| R13 | tShape 10장 렌더: `slotCount(10) = ceil((10+2)/3)*3 = 12` → 4행 x 3 그리드. 1행 = 3 카드, 2행 = empty-card-empty, 3행 = 3 카드, 4행 = 3 카드 = 9 카드. 10번째는? Model Anchors 매트릭스 `{0→0, 1→1, 2→2, 3→4} + (n≥4: drawN → slot(n+2))` 를 n=9 대입 → slot 11. 정상이지만 **시각적으로 T 형태 완전 상실**, 사용자 설정 허용 가능 영역 외인지 Brief 가 명시 없음 | minor | 사용자가 tShape + cardCount=10 조작 | UX (T 메타포 희석) | Brief Model Anchors 에 "tShape cardCount ≥ 7 는 +N 그리드 채움, T 형태 시각 유지 보장 안 됨" 명시. 또는 tShape max 를 6 으로 제한 |
| R14 | linear + cardsPerRow=1 + cardCount=10 → 10행 세로 그리드. 결과 페이지 `Expanded` 내부 GridView 는 shrinkWrap=true + NeverScrollable → 세로 높이가 스크롤 불가 콘텐츠로 10행 = overflow 위험 | minor | 사용자가 linear + cardsPerRow=1 + 큰 cardCount 조합 | UX (RenderFlex overflow 노란 경고) | Brief Caveats R-009 에 이미 언급되었으나 Brief 011 에는 반영 안 됨. `physics: ClampingScrollPhysics` + `shrinkWrap: false` 권장 or 부모를 `SingleChildScrollView` 내부로 배치 |

### Missing Mitigations

| # | What's Missing | What Could Go Wrong | Suggestion |
|---|---------------|---------------------|------------|
| M1 | **Migration 내부 PRAGMA user_version=8 write** | Drift 의 `setSchemaVersion(8)` 은 onUpgrade 트랜잭션 *외부* 에서 돌아 R1/R6 창 발생 | Brief Model Anchors 블록 trailing 에 `await m.database.customStatement('PRAGMA user_version = 8')` 추가 |
| M2 | **Crash recovery idempotency 테스트** | "v8 → v8 migrateAndValidate 재실행" 은 현실 crash 시나리오를 커버하지 않음 | Constraints § 테스트 첫 번째 케이스에 "v7 fixture + half-way 상태 (값 변환만 적용, 컬럼 rename 안 됨) 재migration" 추가 |
| M3 | **Repository 계층의 enum name orElse fallback** | `byName` throw 로 DB 값 하나 때문에 UserSettings/Reading 전체 조회 crash → 무한 crash loop | `SpreadType/LayoutType.values.firstWhere((e) => e.name == row.xxx, orElse: () => LayoutType.linear)` 패턴 명시 |
| M4 | **home_page 에서 setting 변경 시 shuffleStateProvider.clear()** | In Scope #9 "슬라이더 변경 시 재셔플" 위배 | Brief In Scope #9 를 구체 행동 (`ref.read(shuffleStateProvider.notifier).clear()` 호출 위치) 까지 명세 |
| M5 | **Drift schema dump deterministic guard** | 개발자마다 다른 snapshot JSON diff 발생 → git 충돌 | Constraints 에 "v7 snapshot 은 5a62332 기준 frozen. 재생성 금지. 재생성 필요 시 PR 검토" |
| M6 | **build_runner 실행 순서 / state 청소** | cycle 1 `reading.g.dart` 의 stale `_$SpreadTypeEnumMap` 이 cycle 2 에서 참조 오류 | Constraints § codegen 에 "cycle 간 `flutter clean` + 재생성" 추가 |
| M7 | **landscape/rotation overflow 대응** | 결과 페이지 시각 검증이 portrait 5종만 커버 | 6번째 시각 검증 추가 또는 Out of Scope 로 명시 |
| M8 | **tShape cardCount ≥ 7 의 "T 형태 상실" 경고** | 사용자가 10장 설정 → T 메타포 사라짐 | Brief Decision 10 에 "cardCount ≥ 7 은 T 형태 시각 보장 안 됨" 경고 라벨, 또는 UI 에 hint |

## Detailed Analysis

### R1·R6: Drift `user_version` 원자성 창 (Critical pair)

**증거**: `/Users/kampikrein/.pub-cache/hosted/pub.dev/drift-2.28.2/lib/src/runtime/executor/helpers/engines.dart:485-521`

```dart
Future<void> _runMigrations(QueryExecutorUser user) async {
  final versionDelegate = delegate.versionDelegate;
  // ...
  } else if (versionDelegate is DynamicVersionDelegate) {
    oldVersion = await versionDelegate.schemaVersion;
    // Note: We only update the schema version after migrations ran
  }
  // ...
  final openingDetails = OpeningDetails(oldVersion, currentVersion);
  await user.beforeOpen(_BeforeOpeningExecutor(this), openingDetails);  // ← onUpgrade 호출

  if (versionDelegate is DynamicVersionDelegate &&
      oldVersion != currentVersion) {
    // set version now, after migrations ran successfully
    await versionDelegate.setSchemaVersion(currentVersion);  // ← 별도 PRAGMA
  }
  // ...
}
```

그리고 `drift/lib/internal/versioned_schema.dart:114`:
```dart
await database.customStatement('pragma user_version = $newVersion');
```

즉 `PRAGMA user_version = 8` 은 **별도 statement**. onUpgrade 의 트랜잭션은 COMMIT 되었지만 이 PRAGMA 전에 process kill 이 나면:

| 시점 | DB 상태 | PRAGMA user_version | 다음 실행 |
|------|--------|---------------------|----------|
| onUpgrade 시작 | v7 | 7 | — |
| transaction 내 UPDATE | v7 (값 변환만) | 7 | — |
| transaction 내 ALTER RENAME | v8 shape (default_layout_type 존재) | 7 | — |
| **transaction COMMIT** | **v8 shape** | **7 ← still** | — |
| `setSchemaVersion(8)` **전** 프로세스 kill | v8 shape | 7 | 다음 시작 시 onUpgrade (from=7) 재실행 |
| 재실행: UPDATE (no-op) | v8 | 7 | — |
| 재실행: ALTER RENAME | **FAIL** — `no such column: default_spread_type` | — | **앱 시작 실패** |

**완화 (Brief 에 추가 권장)**:

```dart
await m.database.transaction(() async {
  await m.database.customStatement("UPDATE readings SET spread_type = 'linear' WHERE ...");
  await m.database.customStatement("UPDATE user_settings SET default_spread_type = 'linear' WHERE ...");
  await m.database.customStatement('ALTER TABLE user_settings RENAME COLUMN default_spread_type TO default_layout_type');
  // ↓ 트랜잭션 내부에서 user_version 을 원자적으로 갱신
  await m.database.customStatement('PRAGMA user_version = 8');
});
```

이후 Drift 가 호출하는 `setSchemaVersion(8)` 은 idempotent (이미 8 이라 no-op).

### R2: Idempotency 테스트의 시나리오 오해

**증거**: Brief 011 Constraints § 테스트 3 케이스 중 3번:
> 3. Idempotency (v8 상태에서 `migrateAndValidate(db, 8)` 재실행해도 no-op)

이건 "이미 v8 인 DB 에 v8 재적용" 테스트이고, `beforeOpen` 이 `hadUpgrade=false` 경로로 가서 onUpgrade 자체가 호출되지 않는다. 실제 현장 시나리오는:

1. 사용자 앱 launch → onUpgrade(from=7, to=8) 시작
2. transaction COMMIT 성공, PRAGMA user_version 업데이트 직전 crash
3. 다음 launch → PRAGMA 읽음 → still 7 → onUpgrade(from=7, to=8) **재실행**

이 상태를 테스트로 재현하려면:
- v7 fixture 만들고 → 수동으로 일부 migration 적용 (UPDATE + ALTER COLUMN RENAME) → PRAGMA user_version 은 7 로 유지 → migrateAndValidate(db, 8) 호출 → 어떻게 되어야 하는가?
- **정답은 "성공해야 한다"** — 그래야 crash-recovery safe

Brief Constraints 에 이 추가 케이스를 명시해야 R1 완화가 검증됨.

### R3: `byName` throw 경로의 무한 crash

**증거**: `/Users/kampikrein/A/personality/mobile/lib/features/reading/data/repositories/reading_repository_impl.dart:98`

```dart
spreadType: SpreadType.values.byName(row.spreadType),
```

Dart `EnumByName` 확장은 매치 없으면 `ArgumentError: No enum value with that name`.

**실제 trigger**:
- 개발자가 mobile/lib 쪽을 `LayoutType.linear/tShape/grid3x3` 로 rename (impl 사이클 1)
- hot reload → Dart 코드는 새 enum, 하지만 DB 의 v7 값은 여전히 `'custom'` / `'single'` / `'threeCard'`
- `watchSettings` stream → `_toDomain` → `LayoutType.values.byName('custom')` → throw → UserSettings 전체 stream error → UI crash loop

Brief 는 impl 사이클 1 (도메인 모델) 과 사이클 2 (DB 마이그레이션) 를 분리했기 때문에 **사이클 1 완료 후 사이클 2 전에 앱을 실행하면 100% crash**. Brief 는 이 순서 강제를 언급하지 않음.

**완화**: `byName` 대신 `values.firstWhere(..., orElse: () => LayoutType.linear)` 패턴.

### R4: In Scope #9 "슬라이더 변경 시 재셔플"의 구현 공백

**증거**:
- Brief 011 In Scope #9: "슬라이더 변경 시 셔플 재실행 + 결과 페이지 재렌더"
- `/Users/kampikrein/A/personality/mobile/lib/features/home/presentation/pages/home_page.dart:447`: `onChanged: (v) => repo.updateDefaultCardCount(v)` — persist 만 함
- `shuffleStateProvider` 는 home 에서 clear/trigger 되지 않음
- `draw_result_page.dart:27`: `_currentCardCount` 는 `initState` 에서만 초기화

즉 홈에서 슬라이더 조작 후 뽑기 페이지에 들어가면 **이전 셔플 결과** (있다면) 를 재사용하거나 (`_reuseUpstreamResult = true`) 새로 셔플. 홈 슬라이더 자체는 셔플 트리거를 하지 않는다.

**완화**: Brief 에 "홈 설정 변경 → `ref.read(shuffleStateProvider.notifier).clear()` 호출" 추가 요구.

### R5: 이미 커밋된 schema snapshot 의 신선도

**증거**:
- `git log -- mobile/drift_schemas/`: commit `5a62332` (2026-04-20 00:45) — "feat: mobile/drift_schemas — 3개 파일 자동 커밋"
- Brief 011 기준일: 2026-04-20 — Brief 작성 직전에 snapshot 이 이미 작성됨

Snapshot 은 "지금 schemaVersion=7 코드" 에서 dump 되었으므로 현재는 정확. 그러나:

- 다른 개발자가 로컬에서 `dart run drift_dev schema dump` 재실행 시 동일 JSON 이 나오는지 보장 안 됨 (dart 런타임 version, file ordering, pretty-print diff)
- Brief 는 "snapshot dump 명령 기억 필요" (Decision 17 Trade-off) 라고만 말하고 "재생성 금지" 를 명시하지 않음
- impl 사이클 2 verify 단계에서 CI 가 dump 를 재실행 후 diff 비교하면 false-positive diff 가능

**완화**: Brief Decision 17 에 "v7 snapshot 은 5a62332 기준 frozen; 재생성 금지" 추가.

### R9: Migration 진행 중 DAO 호출 금지

**증거**: Drift 의 `@DriftDatabase` 생성 코드는 현재 schemaVersion 의 컬럼 이름을 컴파일 타임에 pin. 즉 `app_database.g.dart` 가 schemaVersion 8 이 되면 `defaultSpreadType` 컬럼은 `defaultLayoutType` 으로 생성된다. Migration 블록 중간에 `select(userSettingsTable).get()` 이 돌면:

- migration UPDATE 후, ALTER RENAME 전: DAO 가 `SELECT default_layout_type FROM user_settings` 시도 → **column does not exist** (아직 rename 안 됨)
- migration ALTER 후: DAO 가 `SELECT default_layout_type FROM user_settings` → 성공

즉 **migration 블록 내부에서 DAO 호출은 컬럼 rename 전후로 다른 에러 발생**. Brief 는 이걸 명시하지 않음. 현재 컨벤션상 onUpgrade 는 `customStatement` 만 쓰므로 실무 위험 낮지만, 개발자가 "migration 후 데이터 검증" 목적으로 DAO 호출 실수 가능.

### R8: cardCount 축소 시 ValueKey 전략의 한계

**증거**: `card_reveal_widget.dart:68-71` — dispose() 에서 controller 해제.

시나리오: 사용자가 tShape + cardCount=7 로 7장 뒤집는 중 cardCount=4 로 축소
- GridView.builder `itemCount` 7 → 4 (정확히는 slotCount 축소)
- slot 6, 7, 8 의 CardRevealWidget (drawIdx 4, 5, 6) 이 unmount → `_controller.dispose()`
- 사용자가 다시 cardCount=7 로 복원 → drawIdx 4, 5, 6 은 재생성 (새 controller, `_showFront=false`)
- 기대: "이전에 뒤집은 카드는 여전히 앞면" — 실제: 뒷면으로 리셋

ValueKey('card-$drawIdx') 는 **같은 drawIdx 가 계속 존재할 때만** StatefulWidget 재사용을 보장. drawIdx 가 itemCount 축소로 사라지면 unmount 필연. Brief 는 이를 언급하지 않음.

**완화**: Brief Model Anchors 에 "reveal 상태는 cardCount 변경 시 초기화됨" 명시, 또는 reveal 상태를 부모 StatefulWidget 에 끌어올려 카드 unmount 와 독립.

## Risk Matrix Summary

| Category | Critical | Major | Minor |
|----------|----------|-------|-------|
| Data loss | R1, R6 | R2 | R9 |
| Codegen/Build | — | R5 | R7 |
| UX regression | — | R4 | R8, R11, R12, R13, R14 |
| Dev environment | — | R3, R5 | R7 |
| Performance | — | — | R10 |

합계: Critical 2, Major 4, Minor 8.

## Recommendations for Brief Revision

Brief 011 을 다음 6 점 업데이트하면 Risk 측 취약성을 닫을 수 있다.

### 1. Model Anchors § DB 마이그레이션 블록 트랜잭션 내부에 PRAGMA 추가

```dart
await m.database.transaction(() async {
  // ... 기존 3 customStatement ...
  await m.database.customStatement('PRAGMA user_version = 8');  // ← 추가
});
```

이유: R1/R6 (Critical) 의 crash 창을 닫음. Drift 의 setSchemaVersion 은 중복되지만 idempotent.

### 2. Constraints § 테스트에 "crash recovery" 케이스 추가

```
4. Crash recovery (v7 + partial state [UPDATE 적용, ALTER 미적용, PRAGMA=7] → migrateAndValidate(db, 8) 성공 + 최종 v8)
```

이유: R2 (Critical) — 현 Idempotency 테스트는 "v8→v8" 재실행만 커버, 실제 crash 시나리오 미커버.

### 3. Constraints § 환경에 Repository byName fallback 명시

> Repository 계층에서 enum decode 시 `EnumByName.byName()` 사용 금지. `values.firstWhere((e) => e.name == row.xxx, orElse: () => LayoutType.linear)` 패턴 사용. stale DB 값 대비.

이유: R3 (Major) — hot reload, migration-pre state 에서 무한 crash 회피.

### 4. In Scope #9 구체화

> 배치/카드수 슬라이더 `onChanged` 콜백에서 `ref.read(shuffleStateProvider.notifier).clear()` 를 호출해 다음 결과 페이지 진입 시 재셔플 강제. home_page.dart 의 관련 3 위젯 (배치 PillSelector, cardCount Stepper, cardsPerRow Stepper) 모두 적용.

이유: R4 (Major) — spec↔code 미스매치 해소.

### 5. Decision 17 snapshot frozen 명시

> v7 snapshot (`mobile/drift_schemas/drift_schema_v7.json` + `test/generated_migrations/schema_v7.dart`) 은 `5a62332` 커밋 기준 frozen. 재생성 금지. 개발자 간 schema dump 결정론 미보장으로 false-positive diff 방지.

이유: R5 (Major) — 팀 워크플로 혼란 방지.

### 6. Constraints § codegen 에 cycle 간 clean 명시

> impl 사이클 간 codegen 재실행은 `flutter clean && dart run build_runner build --delete-conflicting-outputs` 순서. 사이클 1 의 `_$SpreadTypeEnumMap` stale artifact 가 사이클 2 테스트에 잔존하지 않도록.

이유: R7 (Minor) — 개발자 실수 방지.

### (선택) Ideal Criteria 추가 3건

- CR#16: cardCount 축소→확대 시 reveal 상태 초기화 (UX) — R8
- CR#17: 배치 전환 시 모든 카드 reveal 상태 리셋 (UX) — R11
- CR#18: landscape rotation 케이스는 Out of Scope (UX) — R12

## References

| Resource | Path | Relevance |
|----------|------|-----------|
| Brief 011 | `/Users/kampikrein/A/personality/docs/2_tarot_draw/03_draw_experience_settings/011_Brief_layout_redesign.md` | 검토 대상 |
| Research 008 (drift migration) | `/Users/kampikrein/A/personality/docs/2_tarot_draw/03_draw_experience_settings/008_Research_drift_migration_pattern.md` | 트랜잭션 패턴, PRAGMA 토글, SchemaVerifier |
| Research 009 (rendering) | `/Users/kampikrein/A/personality/docs/2_tarot_draw/03_draw_experience_settings/009_Research_slot_based_rendering.md` | ValueKey 전략, CardRevealWidget 호환성 |
| AppDatabase | `/Users/kampikrein/A/personality/mobile/lib/core/database/app_database.dart` | 현 schemaVersion=7 + 6 사이클 migration 코드 |
| UserSettings table | `/Users/kampikrein/A/personality/mobile/lib/core/database/tables/user_settings_table.dart` | defaultSpreadType 컬럼 |
| Readings table | `/Users/kampikrein/A/personality/mobile/lib/core/database/tables/readings_table.dart` | spread_type + FK from DrawnCards |
| DrawnCards table | `/Users/kampikrein/A/personality/mobile/lib/core/database/tables/drawn_cards_table.dart` | readings → drawn_cards cascade FK (PRAGMA 토글 의의) |
| Reading repository | `/Users/kampikrein/A/personality/mobile/lib/features/reading/data/repositories/reading_repository_impl.dart` | `SpreadType.values.byName(row.spreadType)` — R3 |
| UserSettings repository | `/Users/kampikrein/A/personality/mobile/lib/features/settings/data/repositories/user_settings_repository_impl.dart` | `.byName` 패턴, spreadTypeName string API |
| Reading entity | `/Users/kampikrein/A/personality/mobile/lib/features/reading/domain/entities/reading.dart` | DrawnCardInfo.position 필드 (R3 관련) |
| SpreadType enum | `/Users/kampikrein/A/personality/mobile/lib/features/reading/domain/entities/spread_type.dart` | rename 대상 |
| SpreadLayout | `/Users/kampikrein/A/personality/mobile/lib/features/reading/presentation/widgets/spread_layout.dart` | 전면 재작성 대상 |
| CardRevealWidget | `/Users/kampikrein/A/personality/mobile/lib/features/reading/presentation/widgets/card_reveal_widget.dart` | dispose 경로 → R8 |
| DrawResultPage | `/Users/kampikrein/A/personality/mobile/lib/features/draw/presentation/pages/draw_result_page.dart` | `_currentCardCount` initState 캡처 → R4 |
| AnimatedDrawPage | `/Users/kampikrein/A/personality/mobile/lib/features/draw/presentation/pages/animated_draw_page.dart` | 동일 패턴 |
| HomePage | `/Users/kampikrein/A/personality/mobile/lib/features/home/presentation/pages/home_page.dart` | cardCount stepper 라인 447 → R4 |
| ReadingListPage | `/Users/kampikrein/A/personality/mobile/lib/features/reading/presentation/pages/reading_list_page.dart` | `_spreadTypeIcon` switch → rename 대상 |
| ReadingDetailPage | `/Users/kampikrein/A/personality/mobile/lib/features/reading/presentation/pages/reading_detail_page.dart` | `resolvePositions` 호출 |
| Drift engines.dart | `/Users/kampikrein/.pub-cache/hosted/pub.dev/drift-2.28.2/lib/src/runtime/executor/helpers/engines.dart:485-521` | R1/R6 증거: setSchemaVersion 별도 실행 |
| Drift versioned_schema.dart | `/Users/kampikrein/.pub-cache/hosted/pub.dev/drift-2.28.2/lib/internal/versioned_schema.dart:114` | `PRAGMA user_version = $newVersion` |
| Drift db_base.dart | `/Users/kampikrein/.pub-cache/hosted/pub.dev/drift-2.28.2/lib/src/runtime/api/db_base.dart:118-139` | beforeOpen → onUpgrade 호출 구조 |
| git commit 5a62332 | — | drift_schemas v7 snapshot 이미 체크인 (Brief 작성 직전) |

## Completion

- Completion criteria: 10+ concrete risks identified with trigger conditions — **달성 (14건 — R1~R14)**
- 위험 중 Critical 2 (R1, R6) 는 Brief 수정 없이 진입 시 실제 데이터 손상 가능성 있음. 권장 수정 6 점 적용 시 모두 닫힘.

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 0s | 0 |
| 2 | user-ai-exchange | 451s | 935162 |
| 3 | user-ai-exchange | 1554s | 4275267 |
| 4 | user-ai-exchange | 49s | 210710 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 31057s |
| Total Tokens | 5421139 |
| Input Tokens | 59 |
| Output Tokens | 77155 |
| Cache Read | 4817779 |
| Cache Creation | 526146 |
