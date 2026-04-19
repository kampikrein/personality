---
id: "007"
type: research
title: "Enhanced Enum + Computed Properties × Freezed/Drift 호환성 조사"
created: 2026-04-19
traces_scope: "006"
traces_brief: "005"
summary: >
  LayoutType을 Dart enhanced enum + 값별 computed properties (cardCountMin/Max,
  drawToSlot 등) 으로 만들어도 freezed (json_serializable 6.x) 와 Drift (수동
  `.name`/`byName` 패턴) 모두 호환된다. 직렬화 경로가 enum 이름만 사용하고 computed
  properties와 직교(orthogonal)하기 때문이다. Brief CR#3의 fallback (별도
  LayoutDefinition 클래스 분리)은 불필요하며, impl 사이클 1에서 enhanced enum
  방향 그대로 진행해도 안전하다. 단 build_runner 첫 실행 후 reading.g.dart의
  `_$LayoutTypeEnumMap` 자동 재생성 + 단위 테스트 통과를 confirmation gate로
  설정한다.
keywords: [dart, enhanced-enum, freezed, drift, json_serializable, codegen, layout_type]
---

# Enhanced Enum + Computed Properties × Freezed/Drift 호환성 조사

## Research Overview

### Background & Motivation

Brief 005 Decision 13에서 `LayoutType`을 단순 enum이 아닌 **enhanced enum +
computed properties** (cardCountMin/Max, defaultCardCount, cardsPerRowOverride,
slotCount(int), emptySlots(int), drawToSlot(int, int), displayName) 형태로
설계했다. 이는 sub-enum 값별로 다른 동작·데이터를 가지는 풍부한 도메인 모델이며,
배치(나열/T모양/3x3) 의 매핑 로직을 enum 자체에 캡슐화하기 위함이다.

Brief Critical Review #3은 이 설계가 freezed `@JsonKey`/`fromJson` 및 Drift
`TextColumn` + `enum.values.byName()` 직렬화와 충돌할 가능성을 지적했다 — 충돌
시 fallback은 별도 `LayoutDefinition` 클래스 분리.

본 연구의 목적: 충돌 가능성을 코드/공식 문서/이슈 트래커 증거로 검증하고,
fallback 발동 여부를 결정한다.

### Research Scope

**In Scope**:
- 현재 `mobile/` 프로젝트의 enum 직렬화/역직렬화 정확한 호출 경로
- Dart enhanced enum 사양 (값별 멤버 구현)
- freezed + json_serializable의 enum 필드 처리 (특히 enhanced enum)
- Drift TextColumn + enum 매핑 패턴
- 알려진 충돌 사례 (GitHub issues 검색)
- 최소 prototype 코드 제안

**Out of Scope**:
- LayoutType의 도메인 매핑 정확성 (Brief 005에서 결정됨)
- 실제 build_runner 실행·테스트 (impl 사이클 1에서 수행)
- DB 마이그레이션 패턴 (Research axis 2 영역)

### Research Perspectives

단일 통합 관점 (호환성 조사) — 답이 좁고 4영역 (프로젝트 코드 / Dart 사양 /
freezed / Drift) 이 모두 동일한 결론으로 수렴하므로 multi-perspective 분리의
이득이 작다고 판단. Path A (직접 조사) 진행.

### Related Documents

- Brief: [005_Brief_layout_redesign.md](./005_Brief_layout_redesign.md)
- Scope: [006_Scope_layout_redesign.md](./006_Scope_layout_redesign.md)

---

## Status Analysis (현재 프로젝트의 enum 직렬화 메커니즘)

### 1. Freezed Entity의 enum 필드 (`reading.dart:13`)

```dart
@freezed
class Reading with _$Reading {
  const factory Reading({
    required String id,
    required String deckId,
    required SpreadType spreadType,        // ← 단순 enum 필드
    String? question,
    ...
  }) = _Reading;

  factory Reading.fromJson(Map<String, dynamic> json) =>
      _$ReadingFromJson(json);
}
```

`SpreadType`은 freezed factory parameter로 선언만 되어 있고 어떤 annotation도
없다. `@JsonKey`, `@JsonValue`, `@JsonEnum` 미사용 → freezed/json_serializable의
**기본 처리** 적용.

### 2. 자동 생성된 직렬화 코드 (`reading.g.dart`)

```dart
_$ReadingImpl _$$ReadingImplFromJson(Map<String, dynamic> json) =>
    _$ReadingImpl(
      ...
      spreadType: $enumDecode(_$SpreadTypeEnumMap, json['spreadType']),
      ...
    );

Map<String, dynamic> _$$ReadingImplToJson(_$ReadingImpl instance) =>
    <String, dynamic>{
      ...
      'spreadType': _$SpreadTypeEnumMap[instance.spreadType]!,
      ...
    };

const _$SpreadTypeEnumMap = {
  SpreadType.single: 'single',
  SpreadType.threeCard: 'threeCard',
  SpreadType.custom: 'custom',
};
```

**핵심**: 직렬화는 `_$SpreadTypeEnumMap` 이라는 정적 `Map<EnumValue, String>`을
조회하는 패턴. `enum.name` 자동 호출도 아니고, enum 인스턴스의 메서드/속성을
참조하지도 않는다. 단순 정적 매핑 lookup.

→ **enum이 enhanced enum이든 단순 enum이든 이 매핑 자체는 동일하게 생성된다.**
   value 이름 (`single`, `threeCard`...) 만 키로 사용되며 computed properties는
   무관.

### 3. Drift 저장 경로 (`reading_repository_impl.dart`)

Drift는 freezed JSON 경로를 거치지 **않는다** — Repository가 직접 enum을 String
으로 변환:

```dart
// 직렬화 (라인 31)
spreadType: reading.spreadType.name,                    // SpreadType → String

// 역직렬화 (라인 98)
spreadType: SpreadType.values.byName(row.spreadType),   // String → SpreadType
```

Drift TextColumn은 raw String 저장:
```dart
// readings_table.dart:8
TextColumn get spreadType => text()();   // TypeConverter 없음
```

→ Drift 경로는 Dart 내장 `Enum.name` getter (모든 enum 자동 제공) 와
   `EnumByName` extension의 `values.byName(String)` (Dart 2.15+) 만 사용.
   enhanced enum에서도 동일하게 작동.

### 4. UserSettings는 `defaultSpreadType: text()...` (`user_settings_table.dart:15`)

```dart
TextColumn get defaultSpreadType =>
    text().withDefault(const Constant('custom'))();
```

`UserSettingsRepository`도 동일한 `.name`/`byName` 패턴 사용 (확인 필요하지만
컨벤션 일관). LayoutType rename 시 이 컬럼도 함께 마이그레이션 (Scope 006 사이클 2).

### 5. 라이브러리 버전 매트릭스

| 패키지 | 버전 | enhanced enum 지원 | 비고 |
|--------|------|-------------------|------|
| Dart SDK | `^3.6.0` | ✅ 완전 지원 (2.17+ 도입) | enhanced enum + 모든 멤버 가능 |
| freezed | `^2.5.0` | ✅ enum 필드 지원 | freezed entity 내 enum 필드 처리 |
| freezed_annotation | `^2.4.0` | ✅ | `JsonEnum.valueField` 옵션 제공 |
| json_serializable | `^6.8.0` | ✅ enhanced enum 정식 지원 | issue #1110 해결됨 (≥ 6.x) |
| json_annotation | `^4.9.0` | ✅ | `@JsonEnum`, `@JsonValue` 지원 |
| drift | `^2.22.0` | ✅ EnumNameConverter, textEnum 제공 | enhanced enum도 byName 호환 |
| drift_dev | `^2.22.0` | ✅ | codegen 호환 |

모든 라이브러리가 enhanced enum 정식 지원 영역에 있다.

---

## Detailed Findings

### Finding A — Dart Enhanced Enum 사양 핵심 제약

[Dart Language Specification — Enhanced Enums](https://github.com/dart-lang/language/blob/main/accepted/2.17/enhanced-enums/feature-specification.md)
및 [Dart 공식 문서](https://dart.dev/language/enums) 기준:

| 가능 | 불가능 |
|------|-------|
| 값별 final instance variable | non-final instance variable (instance state mutable 금지) |
| const generative constructor | non-const constructor |
| 값별 인스턴스 메서드/getter (override 가능) | `index`, `hashCode`, `==` override |
| `with`, `implements` (mixin/interface) | `extends` 다른 클래스 |
| factory constructor (단, instance 반환은 enum 자체 값으로 제한) | 새 인스턴스 생성 |

**LayoutType의 모든 computed properties는 합법 영역에 있다**:
- `cardCountMin`, `cardCountMax`, `defaultCardCount`, `cardsPerRowOverride`,
  `displayName` → final instance variable ✅
- `emptySlots(int)`, `drawToSlot(int, int)`, `slotCount(int)` → instance
  method (no state mutation) ✅
- 모든 인스턴스 (linear, tShape, grid3x3) 가 enum 본체 시작에 선언 ✅

### Finding B — json_serializable의 Enum 처리 메커니즘

[json_serializable pub.dev 문서](https://pub.dev/packages/json_serializable)
및 [JsonEnum class API](https://pub.dev/documentation/freezed_annotation/latest/freezed_annotation/JsonEnum-class.html):

기본 동작 (annotation 없음):
- enum value의 **인스턴스 이름** (e.g., `SpreadType.single` → `'single'`) 을
  String 키로 사용
- 정적 `_$EnumNameEnumMap` 생성 후 `$enumDecode` 함수로 lookup

Annotation 옵션 (선택):
- `@JsonEnum(valueField: 'fieldName')` — enhanced enum의 특정 필드를 JSON 키로
  사용 (예: `cardCountMin`)
- `@JsonValue('custom-key')` — 개별 enum 값에 커스텀 키 부여

**LayoutType은 annotation 미사용 → 기본 동작 적용 → value 이름 (`linear`,
`tShape`, `grid3x3`) 이 JSON/DB 키가 됨**. 현재 SpreadType과 동일한 패턴.

### Finding C — json_serializable Issue #1110 (Enhanced Enums Breaking) 결착

[google/json_serializable.dart#1110 "Enhanced Enums breaks things"](https://github.com/google/json_serializable.dart/issues/1110):

- **이슈 시점**: Dart 2.17 enhanced enum 도입 직후 (2022년)
- **증상**: 초기 json_serializable이 enhanced enum의 추가 instance member를
  parsing하면서 codegen 충돌
- **해결 시점**: json_serializable 6.x (2022 후반) 에서 정식 지원
- **현재 우리 버전**: json_serializable `^6.8.0` → 안전 영역

→ 알려진 충돌은 모두 우리 버전 이전에 해결됨.

### Finding D — Drift의 Enum 처리 옵션

[Drift Type Converters 문서](https://drift.simonbinder.eu/type_converters/) 및
[EnumNameConverter API](https://pub.dev/documentation/drift/latest/drift/EnumNameConverter-class.html):

Drift는 enum 저장에 **세 가지 옵션** 제공:

| 옵션 | 패턴 | 우리 사용 |
|------|------|----------|
| (a) `IntColumn + intEnum<E>()` | enum index를 int로 저장 | `readings_table.dart:14` SyncStatus가 사용 |
| (b) `TextColumn + textEnum<E>()` | enum name을 String으로 저장 (자동 TypeConverter) | 미사용 |
| (c) `TextColumn + 수동 .name/byName` | Repository가 직접 변환 | **현재 spreadType 방식** |

(c)는 `EnumNameConverter` 의 수동 구현과 동일하다 — Drift는 단지 String을
저장/로드만 한다. enum이 enhanced여도 `.name`/`byName`은 모든 Dart enum의 표준
인터페이스이므로 영향 없음.

### Finding E — 우리 프로젝트의 직렬화 vs computed properties 직교성

직렬화 호출 그래프:

```
freezed Reading.fromJson(json)
  → reading.g.dart의 $enumDecode(_$SpreadTypeEnumMap, json['spreadType'])
  → _$SpreadTypeEnumMap (정적 lookup)
  → 결과: enum 인스턴스

Repository._toDomainReading(row)
  → SpreadType.values.byName(row.spreadType)
  → Dart 내장 EnumByName extension (lookup by name)
  → 결과: enum 인스턴스
```

이 두 경로 어디에도 enum 인스턴스의 메서드/속성을 호출하는 단계가 없다.

LayoutType을 enhanced enum으로 만들면 추가되는 것:
- `_$LayoutTypeEnumMap = { LayoutType.linear: 'linear', LayoutType.tShape: 'tShape', LayoutType.grid3x3: 'grid3x3' }` (자동 생성)
- `LayoutType.linear.cardCountMin` (사용자 코드에서 호출, 직렬화 무관)

→ 직렬화 경로와 computed properties는 완전히 분리된 두 차원. 충돌 가능성 부재.

---

## Caveats & Risks

### 위험 평가 (모두 LOW)

| 위험 | 가능성 | 완화책 |
|------|--------|--------|
| build_runner 첫 실행 시 알 수 없는 codegen 에러 | 낮음 (라이브러리 버전 호환 확인) | impl 사이클 1에서 build_runner 실행 + 결과 확인 |
| `_$LayoutTypeEnumMap` 자동 생성 누락 | 매우 낮음 (현재 SpreadType과 동일 패턴이므로 동일 출력 기대) | reading.g.dart 재생성 후 grep `_$LayoutTypeEnumMap` |
| Drift schema codegen이 enum 메서드를 잘못 파싱 | 낮음 (Drift는 LayoutType을 enum 타입으로만 인식, computed properties는 schema 외부) | drift_dev codegen 후 .g.dart 검토 |
| 향후 `@JsonEnum(valueField: ...)` 사용 시 충돌 | N/A (이번 작업에서 사용 안 함) | — |

### 잠재 트레이드오프

- **테스트 케이스 다수 필요**: enhanced enum의 값별 메서드는 단위 테스트가 enum 값 × 메서드 수만큼 필요. 예: `LayoutType.tShape.drawToSlot(0, 4) == 0`, `... drawToSlot(3, 4) == 4`, `... drawToSlot(4, 5) == 6` (총 8 enum 값별 케이스 × 3 메서드 ≈ 24+). Brief 005 Constraints의 "LayoutType 매핑 단위 테스트" 항목으로 이미 계획됨.
- **정적 분석 약간 복잡**: enum 값별 메서드 구현이 enum 본체에서 분기 (switch this) 되므로 IDE jump-to-definition이 약간 모호. 단 Dart 3.x switch expression은 명료한 분기 제공.

---

## Comprehensive Conclusion

### 핵심 발견 (우선순위 순)

1. **[Critical] R-007-F1: Enhanced Enum + Freezed + Drift 조합은 우리 프로젝트 환경(Dart 3.6+, freezed 2.5+, json_serializable 6.8+, drift 2.22+) 에서 정식 호환된다** — 직렬화 경로(`_$EnumMap` lookup, `.name`/`byName`) 가 enum 인스턴스 메서드를 호출하지 않으므로 computed properties와 직교한다 *(Status Analysis 1~5, Finding A~E)*

2. **[Critical] R-007-F2: Brief 005 Decision 13의 fallback (별도 `LayoutDefinition` 클래스 분리) 은 불필요하다** — Critical Review #3은 해소됨. impl 사이클 1에서 enhanced enum 방향 그대로 진행 안전 *(Finding C: json_serializable issue #1110은 우리 버전 이전에 해결, Finding E: 직렬화-computed 직교성)*

3. **[High] R-007-F3: 우리 프로젝트의 현재 enum 직렬화는 두 경로로 분리되어 있다** — (a) freezed.g.dart의 `_$EnumMap` lookup (JSON 직렬화), (b) Repository의 `.name`/`byName` (DB 직렬화). 두 경로 모두 enum value 이름만 사용하며 LayoutType rename 시 동일 패턴 유지 *(reading_repository_impl.dart:31,98 + reading.g.dart:13,26)*

4. **[High] R-007-F4: build_runner 첫 실행이 confirmation gate** — 호환성은 코드/문서 증거로 검증되었으나 실제 codegen 실행 후 `_$LayoutTypeEnumMap` 정상 생성 + 단위 테스트 통과 확인이 필수. impl 사이클 1 verify 단계 명시 *(Caveats — 위험 평가 행 1, 2)*

5. **[Medium] R-007-F5: Drift TypeConverter 도입은 선택사항** — `text().map(EnumNameConverter(LayoutType.values))()` 으로 Drift 자동 변환 사용 가능하지만, 현재 Repository 수동 변환 패턴이 잘 작동하므로 **유지 권장** (이번 작업의 변경 표면 최소화) *(Finding D)*

6. **[Medium] R-007-F6: Annotation 미사용 정책 유지** — `@JsonEnum(valueField: ...)` 같은 옵션은 LayoutType의 어느 computed property를 JSON 키로 만드는 용도. 우리는 enum value 이름을 키로 사용하는 현재 패턴이 적합하므로 annotation 추가 불필요 *(Finding B)*

7. **[Low] R-007-F7: 단위 테스트 커버리지 가이드** — LayoutType의 enum 값(3) × 주요 메서드(`drawToSlot`, `emptySlots`, `slotCount`) × 카드 수 시나리오 (min, default, max, +N) 매트릭스로 약 24~36개 테스트 케이스. Brief 005 Constraints의 "LayoutType 매핑 단위 테스트"로 이미 계획됨 *(Caveats — 잠재 트레이드오프)*

### Prototype Code (impl 사이클 1 시작 코드)

```dart
enum LayoutType {
  linear(
    cardCountMin: 1,
    cardCountMax: 10,
    defaultCardCount: 3,
    cardsPerRowOverride: null,    // 가변 (기존 cardsPerRow 사용)
    displayName: '나열',
  ),
  tShape(
    cardCountMin: 4,
    cardCountMax: 10,
    defaultCardCount: 4,
    cardsPerRowOverride: 3,       // 한 줄 3장 강제
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

  /// drawIndex (0-based) 가 들어갈 슬롯 인덱스 (0-based).
  int drawToSlot(int drawIndex, int cardCount) {
    return switch (this) {
      LayoutType.linear => drawIndex,

      LayoutType.tShape => switch (drawIndex) {
        0 => 0,            // 자리 1 (1행 1열)
        1 => 1,            // 자리 2 (1행 2열)
        2 => 2,            // 자리 3 (1행 3열)
        3 => 4,            // 자리 5 (2행 2열) — T자 4번째
        _ => drawIndex + 2, // +N: drawIndex 4 → slot 6, ... (자리 7부터 좌→우)
      },

      LayoutType.grid3x3 => switch (drawIndex) {
        // 좌측 기둥 (아래→위)
        0 => 6, 1 => 3, 2 => 0,
        // 우측 기둥 (아래→위)
        3 => 8, 4 => 5, 5 => 2,
        // 가운데 기둥 (아래→위)
        6 => 7, 7 => 4, 8 => 1,
        // +N (자리 10부터 단순 좌→우)
        _ => drawIndex,
      },
    };
  }

  /// 빈 슬롯 인덱스 집합 (visible placeholder 표시용).
  Set<int> emptySlots(int cardCount) {
    return switch (this) {
      LayoutType.linear => const {},
      LayoutType.tShape => const {3, 5},  // 자리 4, 6 영구 빈칸
      LayoutType.grid3x3 => const {},
    };
  }

  /// 그리드 총 슬롯 수 (cardCount + emptySlots를 cellsPerRow로 나눠 올림).
  int slotCount(int cardCount) {
    final cells = cardsPerRowOverride ?? 3;
    final visible = cardCount + emptySlots(cardCount).length;
    return ((visible + cells - 1) ~/ cells) * cells;
  }
}
```

### 결론 (Research Axis 1 핵심 질문에 대한 답)

**해결됨**. enhanced enum + computed properties + freezed + Drift 호환성은
코드 레벨/공식 문서/이슈 트래커 모두에서 충돌 부재가 확인되었다. Brief
Decision 13을 그대로 유지하며 fallback (LayoutDefinition 클래스) 은 불필요.
Critical Review #3 해소.

## Incremental Summary

### 리서치 축
- **축 이름**: enhanced-enum-codegen
- **핵심 질문**: Dart enhanced enum + 값별 computed properties (cardCountMin/Max,
  defaultCardCount, cardsPerRowOverride, slotCount, emptySlots, drawToSlot,
  displayName) 를 부여한 LayoutType이 freezed @JsonKey + Drift TextColumn +
  enum.values.byName() 직렬화와 호환되는가? 충돌 시 fallback (별도
  LayoutDefinition 클래스 분리) 권고 여부?

### 핵심 발견 (우선순위 순)

1. **[Critical] R-007-F1: 호환성 확인됨** — Dart 3.6+, freezed 2.5+, json_serializable 6.8+, drift 2.22+ 환경에서 enhanced enum + computed properties는 freezed/Drift 직렬화와 충돌 없이 작동. 직렬화 경로가 enum value 이름만 사용하고 computed properties와 직교한다.
2. **[Critical] R-007-F2: Fallback 불필요** — Brief 005 Decision 13의 alternative (a) 별도 LayoutDefinition 클래스 분리는 발동하지 않음. enhanced enum 방향 그대로 진행 안전.
3. **[High] R-007-F3: 두 직렬화 경로 정리됨** — (a) freezed.g.dart `_$EnumMap` lookup, (b) Repository 수동 `.name`/`byName`. 두 경로 모두 enum value 이름만 사용.
4. **[High] R-007-F4: build_runner 첫 실행이 confirmation gate** — impl 사이클 1 verify 단계에서 reading.g.dart 재생성 + `_$LayoutTypeEnumMap` 자동 생성 확인 + 단위 테스트 통과 필수.
5. **[Medium] R-007-F5: Drift TypeConverter 도입은 선택사항** — 현재 Repository 수동 변환 유지 권장 (변경 표면 최소화).
6. **[Medium] R-007-F6: Annotation 미사용 유지** — `@JsonEnum(valueField: ...)` 등 추가 annotation 불필요.
7. **[Low] R-007-F7: 단위 테스트 매트릭스 약 24~36 케이스** — enum 값(3) × 메서드(3) × 카드 수 시나리오(min/default/max/+N). Brief 005 Constraints에 이미 계획됨.

### 결론

**해결됨** — Brief CR#3 호환성 우려는 코드/문서/이슈 트래커 증거로 부재 확인. impl 사이클 1에서 enhanced enum + computed properties 그대로 적용 안전. 단 build_runner 첫 실행 후 codegen 결과 confirmation 필수.

### 미해결 사항

None.

## Unresolved Items

None — 본 축 (Critical Review #3) 의 모든 질문이 코드/공식 문서/이슈 트래커
증거로 해결됨. 실제 build_runner 실행은 impl 사이클 1 verify 단계의 confirmation
gate로 위임.

## Referenced File List

| File Path | Related Perspective | Role/Content |
|-----------|-------------------|--------------|
| `mobile/pubspec.yaml` | 라이브러리 버전 | Dart SDK / freezed / json_serializable / drift 버전 매트릭스 |
| `mobile/lib/features/reading/domain/entities/reading.dart` | freezed entity | SpreadType 필드 사용 패턴 |
| `mobile/lib/features/reading/domain/entities/reading.g.dart` | json_serializable 출력 | `_$SpreadTypeEnumMap` 정적 lookup 패턴 확인 |
| `mobile/lib/features/reading/data/repositories/reading_repository_impl.dart` | DB 직렬화 | `.name` / `SpreadType.values.byName(...)` 패턴 (라인 31, 98) |
| `mobile/lib/core/database/tables/readings_table.dart` | Drift schema | `TextColumn get spreadType => text()()` (TypeConverter 미사용) |
| `mobile/lib/core/database/tables/user_settings_table.dart` | Drift schema | `defaultSpreadType: text().withDefault('custom')` |
| `mobile/lib/features/reading/domain/entities/spread_type.dart` | 현 SpreadType enum | 변경 대상 — LayoutType으로 진화 |

## External Sources

- [Dart Language: Enumerated types](https://dart.dev/language/enums) — enhanced enum 공식 사양
- [Dart Enhanced Enum Classes (Language Spec)](https://github.com/dart-lang/language/blob/main/accepted/2.17/enhanced-enums/feature-specification.md) — feature specification
- [How to Use Enhanced Enums in Dart](https://www.freecodecamp.org/news/how-to-use-enhanced-enums-in-dart/) — 실용 예제
- [Deep dive into enhanced enums in Flutter 3.0](https://blog.logrocket.com/deep-dive-enhanced-enums-flutter-3-0/) — LogRocket 분석
- [How to Use Enhanced Enums with Members in Dart 2.17](https://codewithandrea.com/tips/dart-2.17-enums-with-members/) — Andrea Bizzotto
- [json_serializable pub.dev](https://pub.dev/packages/json_serializable) — 공식 패키지 문서
- [JsonEnum class API](https://pub.dev/documentation/freezed_annotation/latest/freezed_annotation/JsonEnum-class.html) — `valueField` 옵션
- [json_serializable Issue #1110: Enhanced Enums breaks things](https://github.com/google/json_serializable.dart/issues/1110) — 초기 충돌 이슈, 6.x에서 해결
- [freezed Issue #468: Enum FreezedUnionValue](https://github.com/rrousselGit/freezed/issues/468) — enum 사용 패턴 논의
- [Drift Type Converters](https://drift.simonbinder.eu/type_converters/) — 공식 가이드
- [Drift EnumNameConverter API](https://pub.dev/documentation/drift/latest/drift/EnumNameConverter-class.html) — name 기반 자동 컨버터
- [Drift Issue #478: Support for enums](https://github.com/simolus3/drift/issues/478) — enum 지원 논의
- [Drift Issue #521: enum column example](https://github.com/simolus3/drift/issues/521) — 사용 예제

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 117s | 344643 |
| 2 | user-ai-exchange | 235s | 1232689 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 786s |
| Total Tokens | 1577332 |
| Input Tokens | 32 |
| Output Tokens | 25030 |
| Cache Read | 1459873 |
| Cache Creation | 92397 |
