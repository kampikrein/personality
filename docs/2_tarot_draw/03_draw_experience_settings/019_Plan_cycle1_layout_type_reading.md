---
id: "019"
type: plan
title: "Plan — Cycle 1: LayoutType enhanced enum + Reading 레이어 (Green 설계)"
created: 2026-04-20
cycle: 1
traces_scope: "017"
traces_tdd_red: "018"
traces_brief: "011"
status: ready
summary: >
  TDD Red 018 의 18개 실패 테스트를 Green 으로 전환하는 구현 설계. `SpreadType`
  → `LayoutType` 파일 교체 (enhanced enum + 8 computed properties/methods),
  Reading 도메인 6 파일의 타입 전환, Repository byName → firstWhere+orElse
  fallback 도입, build_runner 1회 재생성으로 `_$LayoutTypeEnumMap` 자동 생성
  confirmation gate 충족. Scope 017 cycle 1 의 Modified 6 / Reviewed 2 범위
  엄격 준수, 이외 15 파일의 `SpreadType` 참조는 cycle 2~6 에 위임.
keywords: [plan, cycle-1, layout-type, enhanced-enum, reading-layer, tdd-green, build-runner]
---

# 019 — Plan: Cycle 1 LayoutType enhanced enum + Reading 레이어 (Green 설계)

## Goal

TDD Red 018 이 정의한 18 실패 테스트 (T1: matrix 값 × 3 enum = 3 / T2: drawToSlot
매핑 = 5 / T3: emptySlots·slotCount·resolvePositions = 10) 를 단일 구현 패스로
Green 상태 전환한다. 근본 원인은 `package:personality_mobile/features/reading/domain/entities/layout_type.dart`
모듈이 존재하지 않아 컴파일 자체가 실패하는 Red 이므로, **LayoutType enhanced
enum 을 탄생시키고 Reading 도메인 전체가 새 타입을 사용하도록 전환**하는 것이
Green 경로다. Brief 011 Decision 18 의 Repository fallback (`firstWhere + orElse`)
과 Decision 20 의 비대칭 rename 정책 (`Reading.spreadType` 필드명 유지, 타입만
교체) 을 동시에 이번 cycle 에 도입하여 cycle 2 (UserSettings) 진입 시 repository
패턴을 재활용할 수 있는 참조 구현을 남긴다.

build_runner 재생성 결과물 (`reading.freezed.dart`, `reading.g.dart`) 은 직접
편집하지 않고 codegen 이 자동 갱신한다. `reading.g.dart:33-37` 에서
`_$SpreadTypeEnumMap` 이 `_$LayoutTypeEnumMap` 으로 갱신되는 것이 Brief
Constraints 의 "confirmation gate" 다.

## Scope

### Included (Scope 017 cycle 1 Modified 6 + Reviewed 2)

| # | Item | Description |
|---|------|-------------|
| 1 | `spread_type.dart` 제거 + `layout_type.dart` 생성 | 파일 교체 (rename 아님 — 심볼 이름·값·스키마가 전면 교체되어 `git mv` 의미 없음) |
| 2 | `reading.dart` 타입 교체 | import 경로 + `SpreadType` → `LayoutType`. 필드명 `spreadType` 유지 (Decision 20) |
| 3 | `reading_repository.dart` 인터페이스 타입 교체 | `watchReadingsBySpreadType(SpreadType)` → `(LayoutType)` |
| 4 | `reading_repository_impl.dart` 타입 교체 + byName → firstWhere/orElse | Decision 18 fallback 도입 |
| 5 | `reading_dao.dart` | 파라미터 타입 `SpreadType` → `LayoutType` (watchReadingsBySpreadType 의 호출부 시그니처). DAO 내부 컬럼명·쿼리 문자열은 유지 (Decision 20 비대칭: DB 컬럼 `spread_type` 는 cycle 3 에서만 건드림. 이 cycle 에서는 DAO 가 이미 `String` 을 받으므로 실제 변경은 최소) |
| 6 | `reading_providers.dart` | 필터 프로바이더 타입 교체 |
| 7 | `reading.freezed.dart` (Reviewed) | build_runner 자동 재생성 확인 |
| 8 | `reading.g.dart:33-37` (Reviewed) | `_$LayoutTypeEnumMap` 자동 생성 grep gate |

### Excluded (cycle 2~6 위임)

| Item | Reason/Deferred To |
|------|-------------------|
| UserSettings 레이어 (`user_settings.dart`, `user_settings_repository_impl.dart:113`, `settings_providers.dart`, `user_settings.g.dart`, `user_settings.freezed.dart`) | cycle 2 (Scope 017 cycle 2 Modified 범위) |
| DB 마이그레이션 (`app_database.dart:25,28-70`, `readings_table.dart`, `user_settings_table.dart:15`, `migration_v7_to_v8_test.dart` 신규) | cycle 3 |
| `spread_layout.dart` 전면 재작성 + `_empty_slot_placeholder.dart` 신규 | cycle 4 |
| 홈 패널 UI (`home_page.dart:447,456-464`) + `card_count_auto_adjust_test.dart` | cycle 5 |
| `reading_list_page.dart`, `reading_detail_page.dart`, `draw_result_page.dart`, `animated_draw_page.dart` | cycle 6 |
| `app_database.g.dart` codegen 갱신 | cycle 1 build_runner 가 간접 영향을 줄 수 있으나 **본 cycle 의 Reviewed 대상 아님**. cycle 3 에서 정식 재생성 검증 |
| `reading_providers.g.dart` codegen 갱신 | Reading 레이어 변경에 동반되어 재생성됨. 내용 확인은 flutter analyze 통과로 간접 검증 |

## Structural Decisions

| # | Decision | Chosen Option | Rationale |
|---|----------|---------------|-----------|
| 1 | `spread_type.dart` 처리 방식 | **삭제 후 `layout_type.dart` 신규 생성** (git mv 아님) | enum 값 3 개가 모두 교체됨 (`single/threeCard/custom` → `linear/tShape/grid3x3`). 멤버 필드도 전면 교체 (`cardCount, positions, guidances` → `cardCountMin/Max, defaultCardCount, cardsPerRowOverride`). git rename 감지 역치(50%) 미달 예상 → 의미적 파일 교체가 더 정확. 의도도 더 분명 (reviewer 가 diff 를 naive rename 으로 오해하지 않음) |
| 2 | `resolveGuidances` 구현 | **빈 리스트 반환** (`return const <String>[];`) | Brief 011 Out of Scope #4 (guidance 콘텐츠 작성 제외). TDD Red 018 도 resolveGuidances 동작 검증을 생략. 메서드 시그니처는 Scope 017 cycle 1 Modified 에 명시되어 호환성 유지 필요 (`reading_detail_page.dart:76` 가 호출 가능) → 빈 리스트로 계약만 유지. placeholder 메시지는 cycle 6 UI 통합 시 재평가 |
| 3 | Repository fallback 구현 위치 | **`reading_repository_impl.dart:98` 의 `_toDomainReading`** 에서만 도입 (이 cycle). `user_settings_repository_impl.dart:113` 은 cycle 2 | Decision 18 의 fallback 패턴을 cycle 1 에서 확정 → cycle 2 는 동일 패턴 복제. 사전 참조 구현 효과 |
| 4 | DAO 파라미터 타입 변경 범위 | **public API (`watchReadingsBySpreadType(String spreadType)` 그대로 유지)** | DAO 는 이미 `String` 을 받고 있음 (reading_dao.dart:63). Scope 017 "파라미터 타입 `SpreadType` → `LayoutType`" 은 오해를 일으키는 표현 — 실제 DAO 에는 `SpreadType` 파라미터가 **없다**. Repository/Provider 층만 타입 전환하면 DAO 는 자연스럽게 호환. 변경 표면 최소화 |
| 5 | `reading_detail_page.dart:76` 의 `resolvePositions` 호출 호환 | **별도 조치 없음** (이 cycle) | `reading_detail_page.dart` 는 cycle 6 Modified 에 포함. LayoutType 에 `resolvePositions(int)` 메서드가 있으므로 컴파일 에러 없이 호출 가능. cycle 6 에서 spreadType → layoutType 변수명 정비 |

> 모든 결정은 Scope 017 의 Modified/Reviewed 범위 내에서 자율적으로 판단 가능한
> 구현 상세 수준. user 재확인 불필요.

---

## File Change Summary

### Modified Files (6)

| # | File Path | Change Description |
|---|-----------|-------------------|
| 1 | `mobile/lib/features/reading/domain/entities/spread_type.dart` | **삭제** (2 번 파일로 교체) |
| 2 | `mobile/lib/features/reading/domain/entities/reading.dart` | `import 'spread_type.dart'` → `import 'layout_type.dart'`. `required SpreadType spreadType` → `required LayoutType spreadType` (필드명 유지) |
| 3 | `mobile/lib/features/reading/domain/repositories/reading_repository.dart` | `import '../entities/spread_type.dart'` → `import '../entities/layout_type.dart'`. `watchReadingsBySpreadType(SpreadType spreadType)` → `watchReadingsBySpreadType(LayoutType spreadType)` (파라미터명 유지, 비대칭) |
| 4 | `mobile/lib/features/reading/data/repositories/reading_repository_impl.dart` | import 교체. `reading.spreadType.name` 호출부 그대로 (Dart Enum.name 은 모든 enum 공통). `_toDomainReading:98` 의 `SpreadType.values.byName(row.spreadType)` → `LayoutType.values.firstWhere((e) => e.name == row.spreadType, orElse: () => LayoutType.linear)`. `watchReadingsBySpreadType(SpreadType)` → `(LayoutType)` |
| 5 | `mobile/lib/core/database/daos/reading_dao.dart` | **실제 코드 변경 없음** 예상 (이미 `String spreadType` 파라미터 사용 중). 단 파일을 Reviewed 목록에서 Modified 로 분류한 이유는 Scope 017 이 이 파일을 Modified 로 선언했기 때문. 만약 codegen 의 `reading_dao.g.dart` 가 LayoutType 을 참조한다면 build_runner 재생성으로 자동 갱신. 실제 편집이 필요한지 확인만 수행 |
| 6 | `mobile/lib/features/reading/presentation/providers/reading_providers.dart` | import 교체. `watchReadingsBySpreadType(..., SpreadType spreadType)` → `LayoutType spreadType` 파라미터 교체. 함수명은 유지 (Decision 20 asymmetric) |

### New Files (1)

| # | File Path | Description |
|---|-----------|-------------|
| 1 | `mobile/lib/features/reading/domain/entities/layout_type.dart` | enhanced enum `LayoutType` 3 values + 5 final fields + 4 methods. Research 007 Prototype Code + TDD Red 018 의 expectation 전수 반영 |

### Auto-Regenerated (Reviewed, 2+)

| # | File Path | Gate |
|---|-----------|------|
| 1 | `mobile/lib/features/reading/domain/entities/reading.freezed.dart` | LayoutType 타입 반영 |
| 2 | `mobile/lib/features/reading/domain/entities/reading.g.dart:33-37` | **`_$LayoutTypeEnumMap` 자동 생성 — confirmation gate (Brief Constraints)** |
| 3 | `mobile/lib/features/reading/presentation/providers/reading_providers.g.dart` | `watchReadingsBySpreadType` 프로바이더 타입 시그니처 갱신 (LayoutType) |
| 4 | `mobile/lib/core/database/daos/reading_dao.g.dart` | 변경 없음 예상 (DAO String 파라미터 그대로) |

---

## Step 1 — `layout_type.dart` 생성 (18 테스트의 Green 핵심)

### Approach

Research 007 Prototype Code + TDD Red 018 의 모든 expectation 을 반영한 enhanced
enum. 5 final field + 4 method (displayName·cardCountMin·cardCountMax·
defaultCardCount·cardsPerRowOverride · drawToSlot·emptySlots·slotCount·
resolvePositions·resolveGuidances) 를 정의. Scope 017 cycle 1 Modified 의
"resolveGuidances" 는 placeholder 로 빈 리스트 반환 (Decision 2).

### File Skeleton (enhanced enum 구조만 — 구체 값은 impl 이 TDD Red expectation 에서 추출)

```dart
// mobile/lib/features/reading/domain/entities/layout_type.dart
enum LayoutType {
  linear(
    cardCountMin: 1,
    cardCountMax: 10,
    defaultCardCount: 3,
    cardsPerRowOverride: null,
    displayName: '나열',
  ),
  tShape(
    cardCountMin: 4,
    cardCountMax: 10,
    defaultCardCount: 4,
    cardsPerRowOverride: 3,
    displayName: 'T모양',
  ),
  grid3x3(
    cardCountMin: 9,
    cardCountMax: 10,
    defaultCardCount: 9,
    cardsPerRowOverride: 3,
    displayName: '3x3',
  );

  const LayoutType({
    required this.cardCountMin,
    required this.cardCountMax,
    required this.defaultCardCount,
    required this.cardsPerRowOverride,
    required this.displayName,
  });

  final int cardCountMin;
  final int cardCountMax;
  final int defaultCardCount;
  final int? cardsPerRowOverride;
  final String displayName;

  int drawToSlot(int drawIndex, int cardCount) {
    return switch (this) {
      LayoutType.linear => drawIndex,
      LayoutType.tShape => switch (drawIndex) {
        0 => 0, 1 => 1, 2 => 2, 3 => 4,
        _ => drawIndex + 2,
      },
      LayoutType.grid3x3 => switch (drawIndex) {
        0 => 6, 1 => 3, 2 => 0,
        3 => 8, 4 => 5, 5 => 2,
        6 => 7, 7 => 4, 8 => 1,
        _ => drawIndex,
      },
    };
  }

  Set<int> emptySlots(int cardCount) {
    return switch (this) {
      LayoutType.linear => const <int>{},
      LayoutType.tShape => const {3, 5},
      LayoutType.grid3x3 => const <int>{},
    };
  }

  int slotCount(int cardCount) {
    final cells = cardsPerRowOverride ?? 3;
    final visible = cardCount + emptySlots(cardCount).length;
    return ((visible + cells - 1) ~/ cells) * cells;
  }

  List<String> resolvePositions(int actualCardCount) {
    return List.generate(actualCardCount, (i) => '카드 ${i + 1}');
  }

  List<String> resolveGuidances(int actualCardCount) {
    // Brief 011 Out of Scope #4: guidance 콘텐츠는 별도 cycle.
    // 계약 호환성을 위해 빈 리스트 반환 (placeholder).
    return const <String>[];
  }
}
```

### Considerations

- **cardCount 파라미터 유지**: `emptySlots(int cardCount)` 는 현재 구현에서
  파라미터를 사용하지 않지만 시그니처를 유지한다. Brief 011 Model Anchors 표의
  "기본 빈 슬롯 (cardCount=min 시, 0-indexed)" 정의와 매칭 + 향후 가변 빈 슬롯
  전략으로 확장 시 API 호환 유지.
- **`resolvePositions` — `linear` 도 generic 라벨**: TDD Red 018 T3 의
  `linear.resolvePositions(3)[0] == '카드 1'` 를 통과하려면 **전 배치 공통
  generic 라벨** 이어야 한다 (Brief Decision 8). 기존 SpreadType 의
  named spreads (`threeCard` 의 의미 positions) 는 없어짐.
- **switch expression exhaustiveness**: Dart 3 switch expression 이 enum 3
  값을 모두 처리하는지 컴파일러가 검증. default 케이스 불필요.

---

## Step 2 — `reading.dart` 의 타입 전환

### Approach

단 두 줄 변경: import 경로 + 필드 타입. 필드명 `spreadType` 은 Decision 20 에
따라 유지.

### Current Code
```dart
// mobile/lib/features/reading/domain/entities/reading.dart:3, 13
import 'spread_type.dart';
...
required SpreadType spreadType,
```

### After Code
```dart
// mobile/lib/features/reading/domain/entities/reading.dart:3, 13
import 'layout_type.dart';
...
required LayoutType spreadType,
```

### Considerations

- **freezed 재생성 필수**: `reading.freezed.dart` 가 `SpreadType` 참조를 18
  곳 (추정) 에서 가지고 있음. build_runner 1 회로 일괄 갱신.
- **필드명 비대칭**: `Reading.spreadType` 는 DB 컬럼명 `spread_type` 과 1:1
  대응. 필드명까지 rename 하면 `readings_table.dart` 의 TextColumn 이름도 함께
  바꿔야 하고 → DB 마이그레이션 스코프 확대. Decision 20 비대칭 공식화로
  억제.

---

## Step 3 — `reading_repository.dart` 인터페이스 타입 전환

### Approach

interface 파일의 import + 메서드 파라미터 타입 교체.

### Current Code
```dart
// mobile/lib/features/reading/domain/repositories/reading_repository.dart:2, 11
import '../entities/spread_type.dart';
...
Stream<List<Reading>> watchReadingsBySpreadType(SpreadType spreadType);
```

### After Code
```dart
// mobile/lib/features/reading/domain/repositories/reading_repository.dart:2, 11
import '../entities/layout_type.dart';
...
Stream<List<Reading>> watchReadingsBySpreadType(LayoutType spreadType);
```

### Considerations

메서드명 `watchReadingsBySpreadType` 는 Decision 20 비대칭에 따라 유지. cycle 6
에서 UI 통합 리뷰 시 메서드명 rename 여부 재평가 여지 (현 cycle 에서 다루지
않음).

---

## Step 4 — `reading_repository_impl.dart` 직렬화/역직렬화 + fallback

### Approach

3 곳 변경:
1. import 교체
2. `_toDomainReading:98` 의 `byName` → `firstWhere + orElse: LayoutType.linear`
3. `watchReadingsBySpreadType:79` 파라미터 타입 교체

`reading.spreadType.name` 호출부 (`saveReading:31`, `watchReadingsBySpreadType:81`)
는 Dart Enum 내장 `name` 속성이라 enhanced enum 에서도 동일 동작 → 변경 없음.

### Current Code
```dart
// mobile/lib/features/reading/data/repositories/reading_repository_impl.dart:4, 5, 79, 98
import '../../domain/entities/reading.dart' as domain;
import '../../domain/entities/spread_type.dart';
...
Stream<List<domain.Reading>> watchReadingsBySpreadType(SpreadType spreadType) {
  return db.readingDao
      .watchReadingsBySpreadType(spreadType.name)
      ...
}
...
spreadType: SpreadType.values.byName(row.spreadType),
```

### After Code
```dart
// mobile/lib/features/reading/data/repositories/reading_repository_impl.dart
import '../../domain/entities/reading.dart' as domain;
import '../../domain/entities/layout_type.dart';
...
Stream<List<domain.Reading>> watchReadingsBySpreadType(LayoutType spreadType) {
  return db.readingDao
      .watchReadingsBySpreadType(spreadType.name)  // 내장 Enum.name
      ...
}
...
spreadType: LayoutType.values.firstWhere(
  (e) => e.name == row.spreadType,
  orElse: () => LayoutType.linear,                 // Decision 18 fallback
),
```

### Considerations

- **legacy 값 graceful degradation**: 현재 DB 에 `single`/`threeCard`/`custom`
  레코드가 있어도 `ArgumentError` 대신 `LayoutType.linear` 반환 → 앱 crash 없음.
  DB 마이그레이션 (cycle 3) 이 완료되면 legacy 값이 사라지지만, 마이그레이션
  중간 hot reload 시점의 안전성 확보 (014 Risk R3 해소).
- **fallback 선택 근거**: Decision 18 은 linear 를 "가장 관대한 default"
  (min=1, max=10) 로 지정. 임의 cardCount 를 허용하므로 legacy 값 디스플레이 시
  cardCount 제약 위반 없음.

---

## Step 5 — `reading_dao.dart` 검증 (실제 수정 없음 예상)

### Approach

파일 Read → 파라미터 타입 재확인. 현재 `watchReadingsBySpreadType(String
spreadType)` 로 선언되어 있어 LayoutType 영향 없음. impl 이 실제 코드 수정이
필요 없다고 판단하면 파일을 건드리지 않고 통과. 만약 필요 시 주석/문서 갱신
정도 (e.g., `/// spreadType: LayoutType enum name (linear|tShape|grid3x3)`).

### Considerations

Scope 017 cycle 1 Modified 에 포함된 이유는 DAO public API 가 LayoutType 과
의미적으로 연결되어 있기 때문. Decision 4 에 따라 코드 변경 0 라인도 "검토 완료"
로 수용.

---

## Step 6 — `reading_providers.dart` 타입 전환

### Approach

import + 프로바이더 파라미터 타입 교체.

### Current Code
```dart
// mobile/lib/features/reading/presentation/providers/reading_providers.dart:6, 24-27
import '../../domain/entities/spread_type.dart';
...
@riverpod
Stream<List<Reading>> watchReadingsBySpreadType(
  WatchReadingsBySpreadTypeRef ref,
  SpreadType spreadType,
) {
  final repo = ref.watch(readingRepositoryProvider);
  return repo.watchReadingsBySpreadType(spreadType);
}
```

### After Code
```dart
// mobile/lib/features/reading/presentation/providers/reading_providers.dart
import '../../domain/entities/layout_type.dart';
...
@riverpod
Stream<List<Reading>> watchReadingsBySpreadType(
  WatchReadingsBySpreadTypeRef ref,
  LayoutType spreadType,
) {
  final repo = ref.watch(readingRepositoryProvider);
  return repo.watchReadingsBySpreadType(spreadType);
}
```

### Considerations

- 프로바이더 함수명 `watchReadingsBySpreadType` + `WatchReadingsBySpreadTypeRef`
  타입은 유지 (Decision 20). riverpod_annotation 이 `Ref` 타입명을 자동 생성
  하므로 rename 시 cascade 영향 (cycle 6 에서 전체 rename 검토).
- build_runner 재생성으로 `reading_providers.g.dart` 가 LayoutType 을 파라미터
  타입으로 반영하는지 grep 확인.

---

## Step 7 — build_runner 일괄 재생성

### Approach

Step 1~6 가 모두 소스 파일에 반영된 **후에만** 실행한다. 한 번의 `build_runner`
실행이 다음 4 개 파일을 자동 갱신:

1. `reading.freezed.dart` (freezed)
2. `reading.g.dart` (json_serializable — **`_$LayoutTypeEnumMap` 자동 생성**)
3. `reading_providers.g.dart` (riverpod_generator)
4. `reading_dao.g.dart` (drift_generator — 변경 없을 가능성)

### Command

```bash
cd /Users/kampikrein/A/personality/mobile
dart run build_runner build --delete-conflicting-outputs
```

`--delete-conflicting-outputs` 는 이전 codegen 출력 (예: 삭제된 `spread_type.dart`
에 대응하는 `part` 참조) 을 정리하기 위해 필수.

### Considerations

- **UserSettings 미정리 경고**: `user_settings.g.dart` 에도
  `_$SpreadTypeEnumMap` 중복 복제본이 존재 (Brief 011 Context + Critique 012
  C1). 이 cycle 에서는 UserSettings 소스 파일이 여전히 `SpreadType` 을 참조
  하고 있으므로 codegen 이 이전 상태를 유지할 수 있음. **단, user_settings.dart
  가 `spread_type.dart` 를 import 하고 있다면 build_runner 가 컴파일 실패로
  종료** → 이 경우 cycle 2 를 기다리지 않고 긴급 대응 필요. 리스크 평가는 § Risks
  참조.
- **재생성 순서 엄격**: Step 1~6 모두 완료 후에만 build_runner. 중간 실행 시
  일관성 없는 상태로 codegen.

---

## Step 8 — Confirmation Gate (Brief Constraints)

### Approach

Scope 017 cycle 1 Reviewed 의 두 gate 를 명시적으로 수행:

```bash
cd /Users/kampikrein/A/personality/mobile

# Gate 1: _$LayoutTypeEnumMap 자동 생성 확인
grep '_\$LayoutTypeEnumMap' lib/features/reading/domain/entities/reading.g.dart

# Gate 2: 기대 3 entries (linear, tShape, grid3x3) 존재 확인
grep -E 'LayoutType\.(linear|tShape|grid3x3)' lib/features/reading/domain/entities/reading.g.dart

# Gate 3: 기존 SpreadType 심볼이 reading.g.dart 에서 완전 제거
! grep 'SpreadType' lib/features/reading/domain/entities/reading.g.dart
```

세 grep 모두 기대 결과가 나오지 않으면 build_runner 재실행 또는 impl 단계
롤백.

---

## build_runner Strategy

**한 번만** 실행한다. 이유:

- Dart codegen 은 dependency-aware — 한 번의 `build_runner build` 가 bitr 전체
  generator graph 를 계산. 재실행 불필요.
- `--delete-conflicting-outputs` 는 이전 `_$SpreadTypeEnumMap` (reading.g.dart
  상단) 를 `_$LayoutTypeEnumMap` 으로 덮어씌우기 위해 필수.

**순서**:
1. Step 1~6 소스 파일 모두 완료
2. `dart run build_runner build --delete-conflicting-outputs`
3. grep 3 건 confirmation (Step 8)
4. `flutter analyze` 경고 0 확인
5. `flutter test test/features/reading/domain/entities/layout_type_mapping_test.dart`
   18 case Green 확인

**Confirmation grep (Brief 011 Constraints)**:
```bash
grep '_\$LayoutTypeEnumMap' lib/features/reading/domain/entities/reading.g.dart
# 기대: const _$LayoutTypeEnumMap = {
```

**다른 .g.dart 확인** (보조 — 기대하지 않지만 파악):
```bash
grep -r '_\$LayoutTypeEnumMap' lib/
# reading.g.dart 만 매칭되면 정상. user_settings.g.dart 매칭되면 cycle 2 에서 다시 재생성 필요 (hybrid 상태 인지)
```

---

## Test → Code Mapping (18 tests)

| Test ID | Test Name | Satisfying File | Evidence |
|---------|-----------|-----------------|----------|
| T1.1 | `linear: min=1, max=10, default=3, override=null, displayName=나열` | `layout_type.dart` | enum `linear` 선언부의 5 final field 값 |
| T1.2 | `tShape: min=4, max=10, default=4, override=3, displayName=T모양` | `layout_type.dart` | enum `tShape` 선언부 |
| T1.3 | `grid3x3: min=9, max=10, default=9, override=3, displayName=3x3` | `layout_type.dart` | enum `grid3x3` 선언부 |
| T2.1 | `linear: identity — drawToSlot(n, cardCount) == n` | `layout_type.dart` | `drawToSlot` switch 의 `LayoutType.linear => drawIndex` |
| T2.2 | `tShape default 4 cards: [0, 1, 2, 4]` | `layout_type.dart` | `drawToSlot` 의 tShape switch `0→0, 1→1, 2→2, 3→4` |
| T2.3 | `tShape +N (drawIndex=4, cardCount=7) → slot 6` | `layout_type.dart` | tShape switch default `_ => drawIndex + 2` |
| T2.4 | `grid3x3 9 cards: [6, 3, 0, 8, 5, 2, 7, 4, 1]` | `layout_type.dart` | `drawToSlot` 의 grid3x3 9-case switch |
| T2.5 | `grid3x3 +1 (drawIndex=9, cardCount=10) → slot 9` | `layout_type.dart` | grid3x3 switch default `_ => drawIndex` |
| T3.1 | `linear.emptySlots(5) is empty` | `layout_type.dart` | `emptySlots` 의 linear `const {}` |
| T3.2 | `tShape.emptySlots(4) == {3, 5}` | `layout_type.dart` | `emptySlots` 의 tShape `const {3, 5}` |
| T3.3 | `tShape.emptySlots(7) == {3, 5}` | `layout_type.dart` | 동일 switch (cardCount 인자 미사용, 상수 반환) |
| T3.4 | `grid3x3.emptySlots(9) is empty` | `layout_type.dart` | grid3x3 `const {}` |
| T3.5 | `tShape.slotCount(4) == 6` | `layout_type.dart` | `slotCount`: cells=3, visible=4+2=6, ceil(6/3)*3=6 |
| T3.6 | `tShape.slotCount(7) == 9` | `layout_type.dart` | cells=3, visible=7+2=9, ceil(9/3)*3=9 |
| T3.7 | `grid3x3.slotCount(9) == 9` | `layout_type.dart` | cells=3, visible=9, ceil(9/3)*3=9 |
| T3.8 | `grid3x3.slotCount(10) == 12` | `layout_type.dart` | cells=3, visible=10, ceil(10/3)*3=12 |
| T3.9 | `linear.resolvePositions(3).length == 3` | `layout_type.dart` | `List.generate(actualCardCount, ...)` |
| T3.10 | `linear.resolvePositions(3)[0] == "카드 1"` | `layout_type.dart` | `'카드 ${i + 1}'` (i=0 → '카드 1') |
| T3.11 | `tShape.resolvePositions(4).length == 4` | `layout_type.dart` | 동일 `List.generate` (배치 무관 generic) |

**요약**: 18 tests 중 **전부 `layout_type.dart` 가 단독 충족**. Step 2~6 의
Reading 레이어 변경은 테스트 통과의 **전제조건** (import 해결) 이지만 테스트
로직 자체를 충족하는 것은 `layout_type.dart` 한 파일.

---

## Considerations & Trade-offs

### Structural Decisions Log

구조적 결정 § 참조. 5 건 중 Decision 1 (파일 교체), Decision 2 (빈 리스트
guidances) 는 대안이 있었으나 Scope/Brief 의 명시적 지침 + TDD Red 범위 최소화
원칙으로 자율 판단. Decision 3~5 는 mechanical.

### Alternative Approaches

1. **`sealed class` 로 전환 (Brief Decision 13 Alternatives)** — post-v1 cycle
   재평가. 이번 cycle 에서는 enhanced enum 유지.
2. **`LayoutDefinition` 별도 클래스 분리 (Brief CR#3 fallback)** — Research 007
   F2 에서 불필요 확인. 미채택.
3. **`@JsonEnum(valueField: ...)` annotation 추가** — 현재 value 이름이 JSON
   키이므로 불필요 (Research 007 F6).
4. **Drift `textEnum<LayoutType>()` 자동 컨버터** — 현재 수동
   `.name`/`firstWhere` 패턴 유지. 변경 표면 최소화 (Research 007 F5).

### Potential Risks

| 위험 | 가능성 | 완화책 |
|------|--------|--------|
| `user_settings.dart` 가 `spread_type.dart` import 중 → build_runner 컴파일 실패 | **중간** (Scope 017 Context 는 cycle 2 에서 UserSettings 레이어 변경을 명시 — 이는 cycle 1 종료 시점에 UserSettings 가 여전히 `SpreadType` 참조 중이라는 의미) | **필수 검증 — upstream grep 으로 확인**: `grep -rn 'import.*spread_type' mobile/lib/` 를 impl 시작 직전 실행. `user_settings.dart` 나 기타 파일이 참조 중이면 **cycle 1 에서 긴급 대응 (deferred → early promotion)**: (a) 해당 파일의 import 를 `layout_type.dart` 로 교체 + 일시적 type alias `typedef SpreadType = LayoutType;` 를 layout_type.dart 에 추가해 cycle 2 에서 제거. 또는 (b) UserSettings 전체를 cycle 1 로 병합 (scope 확대 — Scope 017 와 불일치, 위임 판단 필요) |
| `_$LayoutTypeEnumMap` 자동 생성 실패 | 낮음 (R-007-F4 에서 precedent 확인) | build_runner 수동 재실행 + `--delete-conflicting-outputs` 플래그 |
| Repository fallback `LayoutType.linear` 가 의도치 않게 모든 unknown 값을 흡수 | 낮음 | 이 cycle 의 단위 테스트에서 fallback 동작은 검증하지 않음 (cycle 2 에서 UserSettings repository 테스트로 inline 추가 — Scope 017 cycle 2 TDD Red 목표). 현 cycle 은 18 matrix 테스트만 통과 목표 |
| `reading_dao.g.dart` 가 LayoutType 심볼 참조 (예상 외) | 낮음 | build_runner 재생성 후 `grep LayoutType lib/core/database/daos/reading_dao.g.dart` 로 확인. 참조 있으면 정상 (자동 갱신), 컴파일 오류만 없으면 OK |
| `flutter analyze` warning 0 미달 | 낮음 | impl 단계에서 analyze 통과가 Verify gate. 실패 시 impl 이 해결 |

### Backward Compatibility

- **DB 스키마**: 본 cycle 은 DB 테이블에 손대지 않음 (cycle 3 영역). 기존
  `readings.spread_type` 컬럼의 `single`/`threeCard`/`custom` 값은 그대로 유지.
  Repository fallback 이 이들을 `LayoutType.linear` 로 읽어 앱 crash 없음
  (Decision 18).
- **JSON API**: Reading 의 JSON serialization 은 새 enum 값 이름 (`linear`/
  `tShape`/`grid3x3`) 을 사용. 외부 API 연동이 없는 로컬-퍼스트 앱이므로 파급 없음.
- **기존 reading 테스트**: `test/` 하위의 기존 reading 테스트가 `SpreadType`
  을 참조하는 경우 컴파일 실패. impl 단계에서 함께 타입 교체 (Scope 017 은 cycle 1
  에 "기존 reading 관련 테스트 회귀 없음" verify 조건 포함).

### Upstream Grep Verification (必須)

impl 시작 전 사전 검증:
```bash
cd /Users/kampikrein/A/personality/mobile

# 1. SpreadType import 참조 파일 목록
grep -rln "from '.*spread_type.dart'" lib/
grep -rln "import '.*spread_type.dart'" lib/

# 2. SpreadType 심볼 사용 파일 목록
grep -rln "SpreadType\b" lib/

# 3. cycle 1 범위 밖 파일 (cycle 2~6 deferred) 확인
# 기대 결과: 아래 파일만 매칭되어야 함 (cycle 1)
#   - reading.dart
#   - reading_repository.dart
#   - reading_repository_impl.dart
#   - reading_providers.dart
#   - reading_dao.dart (주석/코멘트만)
#   - spread_type.dart (삭제 예정)
# 이외 파일 (home_page.dart, user_settings.dart 등) 이 매칭되면 cycle 1 impl 주의:
#   - 컴파일 영향 있는 참조만 type alias 로 긴급 대응
#   - 순수 type 사용 (예: user_settings.dart 의 필드 타입) → cycle 2 에서 정식 처리
#     하되 build_runner 가 해당 파일의 codegen 을 깨지 않아야 함
```

**typedef 긴급 대응 스텁** (필요 시만):
```dart
// layout_type.dart 하단 (cycle 2 에서 제거 예정)
// @Deprecated('Use LayoutType. Removed in cycle 2 user_settings migration.')
// typedef SpreadType = LayoutType;
```
단 이 경우 enum value 이름 불일치 (`single` vs `linear`) 때문에 typedef 만으로
는 해결 불가. 현실적 대안: **cycle 1 impl 이 user_settings.dart 를 한 줄만
임시 수정** (예: 빈 기본값으로 해당 필드를 non-SpreadType 으로 stub) 또는
**user_settings 관련 소스가 컴파일 깨지는 것을 cycle 1 종료 상태로 수용** (cycle
2 Entry 에서 해결). 후자는 Scope 017 의 사이클 간 의존 (cycle 2 → cycle 1) 원칙
과 합치 → **후자 권장**. 단 build_runner 가 실패하면 확인 gate 를 통과 못 하므로
Risk 로 기록.

---

## Implementation Checklist

- [ ] Step 0 (사전): upstream grep 으로 cycle 1 범위 밖 참조 파악. Scope 017
      초과 참조 발견 시 § Deferred 섹션에 기록 후 계속 진행
- [ ] Step 1: `mobile/lib/features/reading/domain/entities/layout_type.dart`
      생성 (enhanced enum + 5 field + 4 method + resolveGuidances placeholder)
- [ ] Step 2: `mobile/lib/features/reading/domain/entities/spread_type.dart`
      삭제
- [ ] Step 3: `reading.dart` import + 타입 전환 (필드명 유지)
- [ ] Step 4: `reading_repository.dart` import + 메서드 시그니처 타입 전환
- [ ] Step 5: `reading_repository_impl.dart` import + Decision 18 fallback +
      watchReadingsBySpreadType 타입 전환
- [ ] Step 6: `reading_dao.dart` 검토 (실제 코드 변경 없음 예상. 필요 시 주석 갱신)
- [ ] Step 7: `reading_providers.dart` import + 파라미터 타입 전환
- [ ] Step 8: `dart run build_runner build --delete-conflicting-outputs`
- [ ] Step 9: Confirmation grep (`_$LayoutTypeEnumMap` × 3 entries)
- [ ] Step 10: `flutter analyze` — warnings = 0
- [ ] Step 11: `flutter test test/features/reading/domain/entities/layout_type_mapping_test.dart`
      — 18 Green
- [ ] Step 12: 기존 reading 회귀 테스트 실행 — regression 없음 확인
- [ ] Step 13: auto-commit (Scope 017 auto_run=true 프로토콜)

---

## Verification Assertions (verify agent 용)

| Level | Assertion | Verification Method | Expected Result |
|-------|-----------|-------------------|-----------------|
| L1-Build | freezed + json_serializable + riverpod codegen 재생성 성공 | `cd mobile && dart run build_runner build --delete-conflicting-outputs` | exit code 0, 에러 로그 없음 |
| L1-Build | `flutter analyze` 경고/에러 0 | `cd mobile && flutter analyze` | "No issues found!" |
| L1-Build | Flutter 빌드 성공 | `cd mobile && flutter build apk --debug` | APK 생성, 빌드 exit 0 |
| L2-CLI | `_$LayoutTypeEnumMap` 자동 생성 (Brief Constraints gate) | `grep '_\$LayoutTypeEnumMap' mobile/lib/features/reading/domain/entities/reading.g.dart` | `const _$LayoutTypeEnumMap = {` 라인 매칭 |
| L2-CLI | 3 enum value 정확히 매핑 | `grep -E 'LayoutType\.(linear\|tShape\|grid3x3)' mobile/lib/features/reading/domain/entities/reading.g.dart` | 3 lines 매칭 |
| L2-CLI | SpreadType 심볼이 reading.g.dart 에서 제거 | `! grep 'SpreadType' mobile/lib/features/reading/domain/entities/reading.g.dart` | 매칭 없음 |
| L2-CLI | 18 TDD Red test Green | `cd mobile && flutter test test/features/reading/domain/entities/layout_type_mapping_test.dart` | `+18: All tests passed!` |
| L2-CLI | 기존 reading 테스트 회귀 없음 | `cd mobile && flutter test test/features/reading/` | 실패 없음 (Scope 017 cycle 1 범위 밖 파일이 깨져도 이 테스트는 통과 필요) |
| L4-Trace | TDD Red 018 의 18 테스트 전부 Green | Test → Code Mapping 표 | 18/18 |

---

## References

| Resource | Path | Related Content |
|----------|------|-----------------|
| Brief | `docs/2_tarot_draw/03_draw_experience_settings/011_Brief_layout_redesign.md` | Decisions 8/18/20, Model Anchors 매트릭스, Constraints confirmation gate |
| Scope | `docs/2_tarot_draw/03_draw_experience_settings/017_Scope_layout_redesign.md` | cycle 1 Modified 6 / Reviewed 2 범위 |
| TDD Red | `docs/2_tarot_draw/03_draw_experience_settings/018_TDD_Red_layout_type_mapping.md` | 18 failing tests, T1/T2/T3 grouping |
| Research | `docs/2_tarot_draw/03_draw_experience_settings/007_Research_enhanced_enum_codegen.md` | Prototype Code, F4 confirmation gate, F5 TypeConverter 선택 |
| Test File (Red) | `mobile/test/features/reading/domain/entities/layout_type_mapping_test.dart` | 18 test cases |
| Target (New) | `mobile/lib/features/reading/domain/entities/layout_type.dart` | cycle 1 핵심 산출물 |

---

## Deferred to Cycle 2 (upstream grep 에서 발견 시 기록)

아래는 Scope 017 이 이미 cycle 2~6 로 위임한 `SpreadType` 참조 파일 (grep 사전
조사 결과). Scope 와 일치하므로 cycle 1 impl 은 **손대지 않는다**:

| File | Cycle | Impact on cycle 1 build |
|------|-------|--------------------------|
| `mobile/lib/features/settings/domain/entities/user_settings.dart` | cycle 2 | **중간 리스크** — `user_settings.dart` 가 `spread_type.dart` import 중이면 build_runner 가 실패할 수 있음. § Risks 의 "upstream grep verification" 참조 |
| `mobile/lib/features/settings/domain/entities/user_settings.g.dart` | cycle 2 (auto-regen) | build_runner 가 user_settings.dart 에 의존 → cycle 1 build_runner 가 user_settings 관련 codegen 도 갱신 시도 |
| `mobile/lib/features/settings/domain/entities/user_settings.freezed.dart` | cycle 2 (auto-regen) | 동일 |
| `mobile/lib/features/settings/data/repositories/user_settings_repository_impl.dart` | cycle 2 | 컴파일 실패 가능. flutter analyze 에서 에러. **Scope 017 의 cycle 1 verify 는 "경고 0" 이므로 user_settings 가 SpreadType 참조 유지 시 flutter analyze 가 에러 보고할 가능성 있음** |
| `mobile/lib/features/settings/presentation/providers/settings_providers.dart` | cycle 2 | 동일 |
| `mobile/lib/core/database/tables/user_settings_table.dart` | cycle 3 | SpreadType 을 직접 참조하지 않음 (text 컬럼만) — 영향 낮음 |
| `mobile/lib/core/database/app_database.dart` | cycle 3 | 동일 |
| `mobile/lib/core/database/app_database.g.dart` | cycle 3 (auto-regen) | 동일 |
| `mobile/lib/features/reading/presentation/widgets/spread_layout.dart` | cycle 4 | SpreadType 직접 참조 시 컴파일 영향. 확인 필요 |
| `mobile/lib/features/home/presentation/pages/home_page.dart` | cycle 5 | SpreadType 사용 시 컴파일 영향. `_PillSelector<SpreadType>` 을 cycle 5 에서 교체 |
| `mobile/lib/features/reading/presentation/pages/reading_list_page.dart` | cycle 6 | 동일 |
| `mobile/lib/features/draw/presentation/pages/draw_result_page.dart` | cycle 6 | 동일 |
| `mobile/lib/features/draw/presentation/pages/animated_draw_page.dart` | cycle 6 | 동일 |

**대응 전략**: impl 에이전트는 위 파일들을 **건드리지 않는다**. 그러나 만약
`flutter analyze` 가 위 파일들에서 컴파일 에러를 보고하면 다음 중 하나를 선택:

1. **cycle 1 verify 통과 기준 완화** (해당 파일들의 에러는 "known deferred" 로
   간주) — 권장. Scope 017 의 cycle 1 verify 목표는 "cycle 1 범위 파일" 의 분석
   경고 0 이므로 의미적으로 일관.
2. **일시 stub 도입** — layout_type.dart 에 `// ignore_for_file: deprecated_member_use`
   를 추가하고 deprecated `typedef SpreadType = LayoutType;` 를 cycle 2 에서
   제거. 단 enum value 이름이 달라 typedef 만으로 해결 안 됨 → **비권장**.
3. **cycle 1 범위 확대** (cycle 2 의 UserSettings 를 조기 병합) — Scope 017 에
   반하므로 **금지**.

**impl 에이전트 의사결정 규칙**: 전략 1 (완화) 을 기본으로 채택. verify 에이전트
에 본 문서의 Deferred 표를 전달하여 해당 파일의 에러는 "cycle 2~6 예정 작업" 로
주석 처리.

---

## 미비점 및 확장 필요 영역

### Plan 미비점 (makeplan 기록)

| # | 항목 | 심각도 | 설명 |
|---|------|--------|------|
| 1 | cycle 1 build_runner 가 UserSettings 의존성으로 실패할 가능성 | Medium | Scope 017 은 cycle 2 의 UserSettings 변경이 cycle 1 에 의존한다고 명시하지만, cycle 1 build_runner 를 성공시키기 위해 UserSettings 를 **얼마나 먼저 손대야 하는지** 의 경계가 명확히 선언되지 않음. 본 Plan 의 § Deferred § Risks 에 세 가지 대응 전략 기록, impl 에이전트가 런타임에서 사전 grep 결과를 보고 판단 |
| 2 | `reading_dao.dart` 의 실제 코드 변경 필요성 | Low | Scope 017 이 이 파일을 Modified 로 분류했지만 현 소스코드 검토 결과 변경 라인이 0 일 가능성 높음. Decision 4 로 "검토 후 변경 0 도 OK" 로 처리 |
| 3 | Repository fallback 단위 테스트 부재 (cycle 1) | Low | Decision 18 fallback 의 동작은 TDD Red 018 에 테스트가 없음. Scope 017 cycle 2 TDD Red 가 UserSettings repository fallback 을 검증하는데, Reading repository fallback 은 별도 테스트 없이 impl 됨. 회귀 검증은 cycle 6 smoke test 의존 |
| 4 | `resolveGuidances` 의 placeholder 선택 (빈 리스트 vs ["..."]) | Low | Scope 017 cycle 1 Modified 가 "빈 리스트 또는 placeholder" 로 양자택일 허용. 본 Plan 은 빈 리스트 선택 (Decision 2). cycle 6 UI 통합 시 재평가 여지 |

### Implementation 미비점 (implementation 기록)

_impl 단계에서 발견된 이슈 기록 영역_

| # | 항목 | 심각도 | 설명 |
|---|------|--------|------|

### Verification 미비점 (verify 기록)

_verify 단계에서 발견된 문제 기록 영역_

| # | 항목 | 심각도 | 설명 |
|---|------|--------|------|

---

## Session Log (auto-appended)
