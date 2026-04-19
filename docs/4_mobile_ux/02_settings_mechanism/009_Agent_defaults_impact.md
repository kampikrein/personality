---
title: "설정 기본값 변경 사전 영향 평가"
type: Agent
date: 2026-04-01
author: flutter-expert
summary: "experienceLevel 1→3, defaultSpreadType threeCard→custom, DB migration 3가지 변경의 3단계 영향 분석"
key_findings:
  - "L1: 변경 대상 파일 11개, 핵심 라인 8개"
  - "L2: experienceLevel=3은 기존 홈 fallback(?? 1) 우회로 즉시 ShufflePage 라우팅 — 가장 큰 UX 변화"
  - "L2: SpreadType.custom은 cardCount=0이므로 custom fallback 분기(_spreadType.cardCount 사용 시 0장 버그) 존재"
  - "L3: migration 실패 시 앱이 crash하지 않고 기존 스키마로 동작 — 단 UPDATE 쿼리 없으면 기존 사용자 행에 변경 미적용"
confidence: high
---

# 설정 기본값 변경 사전 영향 평가

## 변경 대상 요약

| 변경 | 현재 값 | 변경 후 |
|------|--------|--------|
| `experienceLevel` 기본값 | `1` | `3` |
| `defaultSpreadType` 기본값 | `threeCard` | `custom` |
| DB migration | 없음 | 기존 사용자 행 일괄 UPDATE |

---

## L1 — 직접 영향: 변경 대상 파일 전수 파악

### experienceLevel 기본값 위치

| 파일 | 라인 | 계층 | 현재 값 |
|------|------|------|--------|
| `mobile/lib/features/settings/domain/entities/user_settings.dart:12` | L12 | Entity `@Default` | `@Default(1) int experienceLevel` |
| `mobile/lib/core/database/tables/user_settings_table.dart:7-8` | L7-8 | DB `withDefault` | `integer().withDefault(const Constant(1))` |
| `mobile/lib/features/settings/domain/entities/user_settings.g.dart:12` | L12 | JSON fallback `??` | `(json['experienceLevel'] as num?)?.toInt() ?? 1` |
| `mobile/lib/features/home/presentation/pages/home_page.dart:54` | L54 | UI fallback `??` | `settings?.experienceLevel ?? 1` |

### defaultSpreadType 기본값 위치

| 파일 | 라인 | 계층 | 현재 값 |
|------|------|------|--------|
| `mobile/lib/features/settings/domain/entities/user_settings.dart:16` | L16 | Entity `@Default` | `@Default(SpreadType.threeCard) SpreadType defaultSpreadType` |
| `mobile/lib/core/database/tables/user_settings_table.dart:15-16` | L15-16 | DB `withDefault` | `text().withDefault(const Constant('threeCard'))` |
| `mobile/lib/features/settings/domain/entities/user_settings.g.dart:17-18` | L17-18 | JSON fallback `??` | `?? SpreadType.threeCard` |
| `mobile/lib/features/draw/presentation/pages/animated_draw_page.dart:54` | L54 | draw fallback `??` | `settings?.defaultSpreadType ?? SpreadType.threeCard` |
| `mobile/lib/features/draw/presentation/pages/instant_draw_page.dart:47` | L47 | draw fallback `??` | `settings?.defaultSpreadType ?? SpreadType.threeCard` |

### grep 검증 결과

```
experienceLevel.*??.*1:
  user_settings.g.dart:12  → ?? 1
  home_page.dart:54        → ?? 1

defaultSpreadType.*??.*threeCard:
  user_settings.g.dart:17-18 → ?? SpreadType.threeCard
  animated_draw_page.dart:54  → ?? SpreadType.threeCard
  instant_draw_page.dart:47   → ?? SpreadType.threeCard
```

### 변경 필요 파일 목록 (위험도 포함)

| 파일 | 변경 내용 | 위험도 |
|------|----------|--------|
| `user_settings.dart:12` | `@Default(1)` → `@Default(3)` | Medium — freezed 재생성 필요 |
| `user_settings.dart:16` | `@Default(SpreadType.threeCard)` → `@Default(SpreadType.custom)` | Medium — freezed 재생성 필요 |
| `user_settings_table.dart:8` | `Constant(1)` → `Constant(3)` | Medium — DB migration 동반 필수 |
| `user_settings_table.dart:16` | `Constant('threeCard')` → `Constant('custom')` | Medium — DB migration 동반 필수 |
| `user_settings.g.dart:12` | `?? 1` → `?? 3` | Low — 재생성 파일, 수동 수정 불가 |
| `user_settings.g.dart:17-18` | `?? SpreadType.threeCard` → `?? SpreadType.custom` | Low — 재생성 파일, 수동 수정 불가 |
| `home_page.dart:54` | `?? 1` → `?? 3` | **High** — settings=null 시 즉시 ShufflePage 노출 위험 |
| `animated_draw_page.dart:54` | `?? SpreadType.threeCard` → `?? SpreadType.custom` | **High** — custom cardCount=0 버그 유발 가능 |
| `instant_draw_page.dart:47` | `?? SpreadType.threeCard` → `?? SpreadType.custom` | **High** — 동일 |

> **주의**: `*.g.dart`는 `flutter pub run build_runner build` 실행 시 자동 재생성된다.
> `user_settings.dart`와 `user_settings_table.dart` 두 파일만 수동 수정하면
> g.dart는 자동 반영된다.

---

## L2 — 연쇄 영향: 기본값 참조 위치의 동작 변화

### 2-1. experienceLevel=3 시 홈 페이지 라우팅 변화

**현재 (experienceLevel=1)**
```
_startDraw() → case 1: context.push('/draw/instant')
```

**변경 후 (experienceLevel=3)**
```
_startDraw() → case 3: context.pushNamed('shuffle', pathParameters: {'deckId': deckId})
```

**근거**: `home_page.dart:33-43`의 switch 구조

```dart
void _startDraw(BuildContext context, int experienceLevel, String deckId) {
  switch (experienceLevel) {
    case 1: context.push('/draw/instant');        // InstantDrawPage
    case 2: context.push('/draw/animated');       // AnimatedDrawPage
    case 3: context.pushNamed('shuffle', ...);    // ShufflePage (Forge2D 물리엔진)
    default: context.push('/draw/instant');
  }
}
```

**UX 변화**:

| 항목 | 변경 전 | 변경 후 |
|------|--------|--------|
| 홈 "뽑기 시작" 탭 | InstantDrawPage 즉시 뽑기 | ShufflePage 물리엔진 셔플 |
| 홈 subtitle | `즉시 • 3장 • rws-standard` | `풀셔플 • 3장 • rws-standard` |
| 홈 설정 카드 subtitle | `레벨 1 (즉시)` | `레벨 3 (풀셔플)` |
| quickDraw redirect | `/draw/instant` | `/shuffle/{deckId}` |

**quickDraw redirect 변화** (`app_router.dart:45-50`):
```dart
// 현재 — experienceLevel=1
return switch (settings.experienceLevel) {
  1 => '/draw/instant',  // ← 현재 진입점
  3 => '/shuffle/${settings.selectedDeckId}',  // ← 변경 후 진입점
};
```

**위험도: High** — 앱 첫 실행 경험이 물리엔진 페이지로 전환됨.
ShufflePage가 완전히 구현되지 않았거나 퍼포먼스 이슈가 있을 경우 첫인상 손상.

**fallback 위험** (`home_page.dart:54`):
```dart
final experienceLevel = settings?.experienceLevel ?? 1;  // 현재
```
settings가 null(DB 초기화 전)일 때 `?? 1` fallback은 변경해도 해당 코드 라인이 바뀌지 않는다.
`user_settings.dart`의 `@Default(3)` 변경만으로는 이 fallback 라인은 **자동 반영되지 않는다**.
개발자가 `home_page.dart:54`를 수동으로 `?? 3`으로 변경해야 한다.

---

### 2-2. SpreadType.custom 시 cardCount 결정 로직 변화

**핵심 분기** (`animated_draw_page.dart:55-57`, `instant_draw_page.dart:48-51`):

```dart
void _initSettings() {
  final settings = ref.read(userSettingsProvider).valueOrNull;
  _spreadType = settings?.defaultSpreadType ?? SpreadType.threeCard;
  _currentCardCount = _spreadType == SpreadType.custom
      ? settings?.defaultCardCount ?? 3    // custom → 동적 (defaultCardCount 사용)
      : _spreadType.cardCount;              // named → 정적 (enum 상수 사용)
  ...
}
```

**변경 후 동작**:

| 상황 | 변경 전 (threeCard) | 변경 후 (custom) |
|------|-------------------|----------------|
| `_spreadType.cardCount` | `3` (정적) | `0` (SpreadType.custom.cardCount = 0) — **절대 진입 안 됨** |
| `_currentCardCount` 결정 | `_spreadType.cardCount = 3` | `settings?.defaultCardCount ?? 3` |
| settings=null fallback | 3장 | `3` (내부 `?? 3` 유지됨 — 안전) |
| settings 정상 | 3장 | `settings.defaultCardCount` 값 사용 |

**버그 가능성**: `SpreadType.custom.cardCount == 0` (`spread_type.dart:20`)

```dart
custom(
  displayName: '자유 선택',
  cardCount: 0,   // ← 명시적 0
  positions: [],
  guidances: [],
),
```

만약 코드가 `_currentCardCount = _spreadType.cardCount`를 직접 사용하는 경로가 있다면 0장 뽑기가 발생한다.
현재 두 페이지 모두 `_spreadType == SpreadType.custom ? ... : _spreadType.cardCount` 분기가 정확히 구현되어 있으므로
**이 경로는 안전**하다. 단, 향후 신규 draw 페이지 추가 시 이 패턴을 반드시 따라야 한다.

**위험도: Medium** — 현재 코드는 안전하나, custom 분기 누락 시 0장 버그 잠재.

---

### 2-3. 홈 페이지 UI 텍스트 변화

`home_page.dart:65-70` levelLabel switch:
```dart
final levelLabel = switch (experienceLevel) {
  1 => '즉시',
  2 => '연출',
  3 => '풀셔플',
  _ => '즉시',     // ← fallback도 '즉시'이므로 3 이외 값에서 여전히 '즉시' 표시
};
```

변경 후 홈 subtitle: `풀셔플 • 3장 • rws-standard`
변경 후 설정 카드 subtitle: `레벨 3 (풀셔플)`

설정 카드 (`settings_page.dart:49-60`) SegmentedButton은 현재 선택값 표시이므로 자동 반영됨.

---

### 2-4. draw 페이지의 spreadType/cardCount 해석 변화

**SpreadType.custom에서 resolvePositions/resolveGuidances**:

```dart
List<String> resolvePositions(int actualCardCount) {
  if (this != SpreadType.custom) return positions;        // named: 정적
  return List.generate(actualCardCount, (i) => '카드 ${i + 1}');  // custom: 동적 생성
}
```

**UI 변화**:

| 항목 | 변경 전 (threeCard) | 변경 후 (custom) |
|------|-------------------|----------------|
| 카드 위치 라벨 | '지나온 길', '현재', '가능성' | '카드 1', '카드 2', '카드 3' |
| 카드 guidance | 개별 지침 텍스트 | 'N번째 카드가 전하는 메시지입니다.' |
| AppBar title | '쓰리 카드 — 즉시' | '자유 선택 — 즉시' |

의미 있는 포지션 라벨이 제거되므로 **타로 해석의 내러티브 품질 저하** 가능성이 있다.
tarot-expert와 협의 권고.

**위험도: High** — 사용자 경험의 핵심 메타포(포지션 의미)가 사라짐.

---

## L3 — DB Migration 부작용

### 3-1. 현재 Drift migration 패턴

**`app_database.dart:25-35`**:
```dart
@override
int get schemaVersion => 2;

@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (Migrator m) => m.createAll(),
  onUpgrade: (Migrator m, int from, int to) async {
    if (from < 2) {
      await m.createTable(userSettingsTable);
    }
  },
);
```

기존 사용자(schemaVersion=2) → 기본값 변경 migration 추가 시:
- `schemaVersion`을 `3`으로 올려야 한다.
- `onUpgrade`에 `from < 3` 분기로 UPDATE 쿼리 추가.

**migration 미추가 시 동작**:
- DB withDefault(`Constant(3)`) 변경은 새 INSERT에만 적용된다.
- **기존 행(id=1)은 변경되지 않는다** — 기존 사용자는 experienceLevel=1 유지.

---

### 3-2. UPDATE 쿼리로 기존 행 변경 시 다른 필드 영향 여부

migration에서 특정 필드만 업데이트하는 경우:

```sql
-- 권고 migration 코드 예시
UPDATE user_settings SET experience_level = 3 WHERE id = 1;
```

`UserSettingsDao.updateSettings()`는 `copyWith(updatedAt: Value(DateTime.now()))`를 항상 추가하므로
수동 SQL UPDATE로는 `updatedAt`이 갱신되지 않는다.
단, migration SQL은 DAO를 거치지 않고 직접 실행이므로 문제 없다.

**다른 필드 영향**: `UserSettingsTable`의 UPDATE는 지정된 컬럼만 변경. 나머지 필드는 그대로다.

**위험도: Low** — 의도대로 동작.

---

### 3-3. migration 실패 시 앱 초기화 동작

Drift의 migration 실패 시 동작:
- `onUpgrade` 내부에서 exception이 발생하면 해당 exception이 `AppDatabase` 생성 시 throw된다.
- Riverpod provider에서 `AppDatabase`를 생성하고, 이 provider를 watch하는 모든 위젯은 `AsyncError` 상태가 된다.
- 현재 코드에서 `userSettingsProvider`가 error 상태이면 홈 페이지 `settingsAsync.valueOrNull`은 `null`을 반환한다.
- `null` 반환 → fallback(`?? 1`, `?? SpreadType.threeCard`) 사용 → 앱 동작은 유지되나 설정이 모두 기본값으로 표시됨.

**crash 여부**: DB provider 자체가 throw하면 Riverpod가 error state로 처리한다.
현재 `userSettingsProvider`는 AsyncNotifier가 아닌 Stream provider이므로 UI에서 `when(error:...)` 분기로 처리 가능.
앱 crash는 발생하지 않는다. **단, settings UI가 오류 상태로 고착될 수 있다.**

**위험도: Medium** — 앱 동작 유지, 단 설정 UI 일부 기능 불가.

---

### 3-4. defaultSpreadType=custom 변경 시 기존 저장된 리딩 데이터와의 호환성

**리딩 저장 방식** (`reading_repository_impl.dart:28-31`):
```dart
spreadType: reading.spreadType.name,  // enum.name → 'threeCard', 'single', 'custom' 등 문자열
```

**리딩 읽기 방식** (`reading_repository_impl.dart:98`):
```dart
spreadType: SpreadType.values.byName(row.spreadType),
// 'threeCard' → SpreadType.threeCard
// 'single'    → SpreadType.single
// 'custom'    → SpreadType.custom
```

기존 사용자가 threeCard로 저장한 리딩 데이터:
- DB `readings.spread_type` 컬럼값: `'threeCard'`
- 변경 후 `byName('threeCard')` → `SpreadType.threeCard` 여전히 정상 매핑.
- **기존 리딩 데이터는 영향 없음**.

신규 사용자(defaultSpreadType=custom)가 뽑기 후 저장한 리딩:
- `spreadType: SpreadType.custom`으로 저장됨.
- 리딩 상세 화면에서 `resolvePositions()` 호출 → `'카드 1', '카드 2', ...` 동적 생성.
- `watchReadingsBySpreadType(SpreadType.threeCard)` 필터 사용 시 custom 리딩은 조회되지 않음.

**위험도: Low** — 기존 리딩 데이터 호환성 문제 없음. 단 필터 조회 결과가 달라질 수 있음.

---

## 종합 위험도 판정

| 변경 항목 | 위험도 | 주요 사유 |
|----------|--------|----------|
| **experienceLevel 1→3 (entity/DB)** | **High** | 앱 첫 실행 UX가 InstantDraw → ShufflePage로 변경됨 |
| **home_page.dart fallback `?? 1`** | **High** | 수동 변경 필수, 누락 시 settings=null 상태에서 동작 불일치 |
| **draw_page fallback `?? SpreadType.threeCard`** | **High** | 수동 변경 필수, custom 분기 미누락 시 안전하나 코드 일관성 훼손 |
| **defaultSpreadType threeCard→custom** | **High** | 포지션 라벨 의미 소실, 타로 해석 품질 저하 |
| **DB migration experienceLevel=3 UPDATE** | **Medium** | 미추가 시 기존 사용자 미반영 — schemaVersion 증가 필수 |
| **SpreadType.custom.cardCount=0 버그** | **Medium** | 현재 코드는 안전, 신규 페이지 추가 시 잠재 버그 |
| **migration 실패 시 앱 동작** | **Medium** | crash 없음, 설정 UI 오류 상태 고착 가능 |
| **기존 리딩 데이터 호환성** | **Low** | 기존 데이터 이상 없음 |

---

## 권고 사항

### 필수 변경 (변경 결정 시 반드시 동반)

1. **3계층 동시 변경**: `user_settings.dart` + `user_settings_table.dart` 수정 후 `build_runner` 실행.
2. **UI fallback 수동 수정**: `home_page.dart:54` (`?? 1` → `?? 3`), draw 페이지 2곳 (`?? SpreadType.threeCard` → `?? SpreadType.custom`).
3. **schemaVersion 3 증가 + onUpgrade 분기 추가**:
   ```dart
   if (from < 3) {
     await customStatement(
       'UPDATE user_settings SET experience_level = 3, '
       "default_spread_type = 'custom' WHERE id = 1"
     );
   }
   ```

### 검토 권고

- **tarot-expert 협의**: SpreadType.custom 기본값이 포지션 의미 소실로 이어지는지 타로 도메인 관점 검토.
- **ShufflePage 완성도 확인**: experienceLevel=3이 기본값이 되면 ShufflePage가 첫 진입점이 됨. 물리엔진 초기화 퍼포먼스, 비정상 종료 처리 확인 필요.

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
| 25 | user-ai-exchange | 29s | 234056 |
| 26 | user-ai-exchange | 3s | 48718 |
| 27 | user-ai-exchange | 13s | 54002 |
| 28 | user-ai-exchange | 9s | 55309 |
| 29 | user-ai-exchange | 10s | 58339 |
| 30 | user-ai-exchange | 11s | 61129 |
| 31 | user-ai-exchange | 7s | 62416 |
| 32 | user-ai-exchange | 0s | 0 |
| 33 | user-ai-exchange | 10s | 63892 |
| 34 | user-ai-exchange | 22s | 67713 |
| 35 | user-ai-exchange | 9s | 69028 |
| 36 | user-ai-exchange | 21s | 215578 |
| 37 | user-ai-exchange | 174s | 517468 |
| 38 | user-ai-exchange | 418s | 1153988 |
| 39 | user-ai-exchange | 80s | 692099 |
| 40 | user-ai-exchange | 56s | 453585 |
| 41 | user-ai-exchange | 134s | 1054142 |
| 42 | user-ai-exchange | 587s | 979519 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 478862s |
| Total Tokens | 7432515 |
| Input Tokens | 166 |
| Output Tokens | 55553 |
| Cache Read | 6567656 |
| Cache Creation | 809140 |
