---
id: "005"
type: verify
title: "Cycle 1 데이터 기반 — 검증 보고서"
created: 2026-03-22
traces_plan: "004"
traces_scope: "002"
cycle: 1
area: "데이터 기반 (Data Foundation)"
commit: 1efbd5e
verdict: PASS
summary: >
  Plan(004) 검증 기준 8개 모두 통과. dart analyze 에러 0건, build_runner 생성 코드 정상,
  UserSettings 테이블/DAO/Repository/Provider 체인 완비, SpreadType.custom exhaustive switch 통과,
  DeckMetadata.supportedDrawModes 정상 매핑. 기존 기능 호환성 유지됨.
keywords: [verify, cycle-1, user-settings, spread-type, deck-metadata, drift, riverpod]
---

# Cycle 1 데이터 기반 — 검증 보고서

## 검증 환경

- **커밋**: `1efbd5e` (feat: Cycle 1 데이터 기반 — UserSettings 테이블 + SpreadType.custom + DrawMode + Riverpod providers)
- **변경 파일**: 소스 12개 + 생성 코드 8개 = 총 20개 (Plan 예측 일치)
- **정적 분석**: `dart analyze lib/` — **No issues found!**

## 검증 기준별 결과

### 1. DB 마이그레이션 v1 -> v2 — PASS

**파일**: `mobile/lib/core/database/app_database.dart`

- `schemaVersion` = `2` (1에서 올림)
- `onUpgrade` 콜백: `from < 2` 조건으로 `m.createTable(userSettingsTable)` 실행
- `tables` 리스트에 `UserSettingsTable` 등록, `daos` 리스트에 `UserSettingsDao` 등록
- `app_database.g.dart`의 `allSchemaEntities`에 `userSettingsTable` 포함 확인
- 기존 4개 테이블(Decks, Cards, Readings, DrawnCards) 유지 — 삭제/변경 없음

### 2. UserSettings 기본 행 자동 생성 — PASS

**파일**: `mobile/lib/core/database/daos/user_settings_dao.dart`

- `_ensureDefaultRow()`: id=1 행 존재 확인 후 없으면 `UserSettingsTableCompanion.insert(updatedAt: DateTime.now())` 실행
- `watchSettings()`: `watchSingleOrNull()` + `asyncMap`으로 null일 때 자동 INSERT 후 재조회
- `getSettings()`: `getSingleOrNull()` + null 시 자동 INSERT 후 `getSingle()` 재조회
- **주의사항**: `_ensureDefaultRow()`는 race condition에 취약할 수 있으나, 단일 행(id=1) 패턴이며 앱 단일 프로세스 환경에서 실질적 문제 없음

**테이블 기본값 확인** (`user_settings_table.dart`):

| 필드 | 기본값 | Plan 명세 일치 |
|------|--------|---------------|
| selectedDeckId | `'rws-standard'` | O |
| experienceLevel | `1` | O |
| defaultCardCount | `3` | O |
| showFaceUp | `false` | O |
| quickDrawEnabled | `false` | O |
| defaultSpreadType | `'threeCard'` | O |
| updatedAt | (INSERT 시 `DateTime.now()`) | O |

### 3. SpreadType.custom exhaustive switch — PASS

**파일**: `mobile/lib/features/reading/presentation/widgets/spread_layout.dart`

```dart
return switch (spreadType) {
  SpreadType.single => _buildSingleLayout(),
  SpreadType.threeCard => _buildThreeCardLayout(),
  SpreadType.custom => _buildGenericGridLayout(),
};
```

- 3개 variant 모두 분기 처리됨
- `_buildGenericGridLayout()`: cards.length == 1이면 single 레이아웃 재사용, 3장 이하 가로 나열, 4장 이상 2열 그리드
- `dart analyze` 에러 0건 — exhaustive switch 통과 확인

### 4. SpreadType.values.byName('custom') 정상 — PASS

**파일**: `mobile/lib/features/reading/domain/entities/reading.g.dart`

```dart
const _$SpreadTypeEnumMap = {
  SpreadType.single: 'single',
  SpreadType.threeCard: 'threeCard',
  SpreadType.custom: 'custom',
};
```

- `$enumDecode(_$SpreadTypeEnumMap, json['spreadType'])` — 'custom' 문자열로 SpreadType 복원 가능
- `user_settings.g.dart`에도 동일한 `_$SpreadTypeEnumMap` 생성 확인
- DB 저장/복원 경로: `UserSettingsTableData.defaultSpreadType` (Text) -> `SpreadType.values.byName()` in `_toDomain()` — 정상

### 5. DeckMetadata.supportedDrawModes — PASS

**파일**: `mobile/lib/features/deck/domain/entities/deck_metadata.dart`

- `DrawMode` enum: `freeform`, `namedSpread`, `hexagram` — 3개 값 정의
- `@Default([DrawMode.freeform, DrawMode.namedSpread])` — Freezed 기본값 설정
- `deck_metadata.freezed.dart`: `supportedDrawModes` 필드가 `List<DrawMode>`로 올바르게 생성됨
- `deck_metadata.g.dart`: `$enumDecode(_$DrawModeEnumMap, e)` 매핑 정상

**파일**: `mobile/lib/features/deck/data/repositories/deck_repository_impl.dart`

```dart
supportedDrawModes: row.isStandardTarot
    ? [DrawMode.freeform, DrawMode.namedSpread]
    : [DrawMode.hexagram],
```

- 타로 덱(`isStandardTarot == true`) -> `[freeform, namedSpread]` — Plan 일치
- I Ching 덱(`isStandardTarot == false`) -> `[hexagram]` — Plan 일치

### 6. userSettingsProvider Stream 동작 — PASS

**파일**: `mobile/lib/features/settings/presentation/providers/settings_providers.dart`

- `userSettingsRepositoryProvider`: `@Riverpod(keepAlive: true)` — 앱 생존 기간 유지
- `userSettingsProvider`: `@riverpod Stream<UserSettings>` — AutoDisposeStreamProvider로 생성됨
- `settings_providers.g.dart` 확인: `AutoDisposeStreamProvider<UserSettings>` 올바르게 생성

**Provider 체인**: `appDatabaseProvider` -> `UserSettingsRepositoryImpl(db:)` -> `watchSettings()` -> `Stream<UserSettings>`

### 7. 코드 생성 성공 — PASS

생성된 파일 8개 모두 정상 확인:

| 생성 파일 | 상태 |
|----------|------|
| `app_database.g.dart` | UserSettingsTable + UserSettingsDao 등록 확인 |
| `user_settings_dao.g.dart` | `_$UserSettingsDaoMixin` 정상 |
| `deck_metadata.freezed.dart` | `supportedDrawModes: List<DrawMode>` 포함 |
| `deck_metadata.g.dart` | `DrawMode` enum map 포함 |
| `user_settings.freezed.dart` | 7개 필드 + `copyWith` + `==` + `hashCode` 정상 |
| `user_settings.g.dart` | `SpreadType` enum map + JSON serialization 정상 |
| `settings_providers.g.dart` | `keepAlive: true` repo + Stream provider 정상 |
| `reading.g.dart` | `SpreadType.custom: 'custom'` 추가됨 |

### 8. 기존 기능 호환성 — PASS

- `reading_page.dart`: `positions[i]` / `guidances[i]` 직접 접근 -> `resolvePositions(drawnCards.length)[i]` / `resolveGuidances(drawnCards.length)[i]` 교체
  - `single`/`threeCard`: `resolvePositions()`가 정적 `positions`를 그대로 반환 — 동작 무변경
  - `custom`: 동적 리스트 생성으로 IndexError 방지
- `spread_layout.dart`: 기존 `_buildSingleLayout()` / `_buildThreeCardLayout()` 내에서도 `resolvePositions(cards.length)` 사용으로 통일 — 명시적이지만 named 스프레드에서는 인자가 무시되므로 동작 동일
- 기존 테스트(`widget_test.dart`): placeholder smoke test — 영향 없음
- DB 마이그레이션: `onUpgrade`에서 새 테이블만 추가, 기존 테이블 변경 없음

## Edge Case 분석

### resolvePositions/resolveGuidances 안전성

| 시나리오 | positions.length | cardCount 결정 | 안전 여부 |
|---------|-----------------|---------------|----------|
| single (정상) | 1 | `_spreadType.cardCount` = 1 | 안전 — 1:1 매칭 |
| threeCard (정상) | 3 | `_spreadType.cardCount` = 3 | 안전 — 3:3 매칭 |
| custom (동적) | 0 (빈 리스트) | `shuffleResult.cards.length` | 안전 — `resolvePositions(N)`이 N개 생성 |

**named 스프레드에서 cardCount > positions.length 가능성**: `reading_page.dart` L57-58에서 named 스프레드는 `_spreadType.cardCount`를 사용하며 이 값은 `positions.length`와 항상 동일(single=1, threeCard=3). Plan 설계상 불일치 불가.

### _ensureDefaultRow race condition

단일 행(id=1) 패턴에서 두 번의 `getSingleOrNull` + `insert` 사이에 다른 INSERT가 끼어들 수 있으나:
- Flutter 앱 = 단일 isolate의 단일 DB 연결
- `autoIncrement()`이므로 중복 INSERT 시 id=2가 생성될 수 있으나, 이후 조회는 항상 `id.equals(1)`로 필터하므로 기능적 문제 없음

## 파일 매핑 — Plan vs 구현

| Plan Step | 예정 파일 | 구현 상태 |
|-----------|----------|----------|
| 1-1 | `tables/user_settings_table.dart` | NEW — 일치 |
| 1-2 | `daos/user_settings_dao.dart` | NEW — 일치 |
| 1-3 | `app_database.dart` | MODIFY — 일치 |
| 2 | `spread_type.dart` | MODIFY — 일치 |
| 2-1 | `spread_layout.dart` | MODIFY — 일치 |
| 2-2 | `reading_page.dart` | MODIFY — 일치 |
| 3 | `deck_metadata.dart` | MODIFY — 일치 |
| 3+ | `deck_repository_impl.dart` | MODIFY — 일치 |
| 4-1 | `settings/domain/entities/user_settings.dart` | NEW — 일치 |
| 4-2 | `settings/domain/repositories/user_settings_repository.dart` | NEW — 일치 |
| 4-3 | `settings/data/repositories/user_settings_repository_impl.dart` | NEW — 일치 |
| 4-4 | `settings/presentation/providers/settings_providers.dart` | NEW — 일치 |

**Plan 명세와 100% 일치. 누락/추가 파일 없음.**

## 최종 판정: PASS

8개 검증 기준 모두 통과. Cycle 2 진행 차단 요소 없음.

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 0s | 0 |
| 2 | user-ai-exchange | 19s | 76045 |
| 3 | user-ai-exchange | 11s | 40778 |
| 4 | user-ai-exchange | 10s | 42195 |
| 5 | user-ai-exchange | 9s | 44183 |
| 6 | user-ai-exchange | 14s | 46529 |
| 7 | user-ai-exchange | 5s | 48356 |
| 8 | user-ai-exchange | 9s | 50568 |
| 9 | user-ai-exchange | 13s | 105037 |
| 10 | user-ai-exchange | 12s | 54453 |
| 11 | user-ai-exchange | 11s | 55874 |
| 12 | user-ai-exchange | 12s | 57359 |
| 13 | user-ai-exchange | 14s | 58996 |
| 14 | user-ai-exchange | 13s | 60582 |
| 15 | user-ai-exchange | 8s | 61831 |
| 16 | user-ai-exchange | 11s | 63033 |
| 17 | user-ai-exchange | 29s | 202688 |
| 18 | user-ai-exchange | 11s | 140060 |
| 19 | user-ai-exchange | 11s | 71985 |
| 20 | user-ai-exchange | 9s | 147944 |
| 21 | user-ai-exchange | 14s | 76148 |
| 22 | user-ai-exchange | 19s | 0 |
| 23 | user-ai-exchange | 10s | 41780 |
| 24 | user-ai-exchange | 13s | 45110 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 341150s |
| Total Tokens | 1591534 |
| Input Tokens | 71 |
| Output Tokens | 8834 |
| Cache Read | 1202235 |
| Cache Creation | 380394 |
