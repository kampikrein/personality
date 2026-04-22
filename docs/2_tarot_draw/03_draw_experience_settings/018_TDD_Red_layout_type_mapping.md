---
id: "018"
type: tdd-red
title: "TDD Red: LayoutType enum + 매트릭스/매핑 단위 테스트 (cycle 1)"
created: 2026-04-20
cycle: 1
traces_scope: "017"
traces_brief: "011"
status: completed
test_count: 18
framework: flutter_test
summary: >
  Scope 017 cycle 1 (LayoutType enum + Reading 레이어) 의 Green 목표를 정의하는
  실패 테스트. `SpreadType` → `LayoutType` 로 rename 되는 enhanced enum 에 대해
  3 배치 × {매트릭스 값, drawToSlot, emptySlots, slotCount, resolvePositions}
  핵심 동작을 검증. 현재는 `LayoutType` 심볼 자체가 존재하지 않아 컴파일 실패
  상태로 커밋 → Green 은 impl 에서 달성.
keywords: [tdd-red, layout-type, enhanced-enum, mapping, cycle-1]
test_files:
  - mobile/test/features/reading/domain/entities/layout_type_mapping_test.dart
---

# TDD Red: LayoutType enum + 매트릭스/매핑 (cycle 1)

## Test Strategy

Brief 011 Model Anchors 의 **3 배치 매트릭스** + **drawToSlot 매핑** + **빈
슬롯 패턴** + **슬롯 카운트 공식** + **generic `카드 N` positions** 를
런타임 검증한다. 모든 테스트는 **단일 enum `LayoutType`** 를 대상으로 하며,
현재 코드베이스에는 `SpreadType` 만 존재하므로 import 단계에서 컴파일 실패 →
Red 상태 확정.

`resolveGuidances` 는 Scope 017 cycle 1 Modified 에 명시되나 Brief 011 Out of
Scope #4 (guidance 콘텐츠 작성 제외) 로 인해 본 tdd-red 단계에서는 동작 검증
테스트를 작성하지 않는다 (placeholder 라는 반환 타입만 impl 단계에서 결정).

## Test Specifications

### T1: enum 매트릭스 값 (Model Anchors 매트릭스 런타임 일치)

- **동작**: `LayoutType.linear`, `.tShape`, `.grid3x3` 의 `cardCountMin`,
  `cardCountMax`, `defaultCardCount`, `cardsPerRowOverride`, `displayName`
  5개 computed property 가 Brief 011 Model Anchors 표의 값과 정확히 일치
- **입력**: 3 enum value 각각 property 접근
- **기대 결과**:
  - linear: min=1, max=10, default=3, cardsPerRowOverride=null, displayName='나열'
  - tShape: min=4, max=10, default=4, cardsPerRowOverride=3, displayName='T모양'
  - grid3x3: min=9, max=10, default=9, cardsPerRowOverride=3, displayName='3x3'
- **파일**: `mobile/test/features/reading/domain/entities/layout_type_mapping_test.dart`

### T2: drawToSlot 매핑 (의식적 패턴 + +N 동작)

- **동작**: drawIndex → slotIndex 매핑이 Brief 011 Model Anchors 의
  "기본 드로우 매핑" 및 Scope 017 cycle 1 tdd-red 목표에 일치
- **입력/기대 결과**:
  - linear: `drawToSlot(n, cardCount) == n` (identity, n ∈ [0, cardCount))
  - tShape 기본 4장: `drawToSlot(0,4)=0`, `(1,4)=1`, `(2,4)=2`, `(3,4)=4` (자리 5)
  - tShape +N (drawIndex ≥ 4): `drawToSlot(4, 7) == 6` (자리 7, 단순 좌→우 in drawIndex+2)
  - grid3x3 기본 9장: `drawToSlot(0..8, 9) == [6, 3, 0, 8, 5, 2, 7, 4, 1]`
    (좌 기둥 아래→위, 우 기둥 아래→위, 중앙 기둥 아래→위)
  - grid3x3 +1 (drawIndex=9, cardCount=10): `drawToSlot(9, 10) == 9` (단순 좌→우)
- **파일**: 상동

### T3: emptySlots / slotCount / resolvePositions

- **동작**: 슬롯 공간 계산 메서드 + generic 라벨 positions
- **입력/기대 결과**:
  - `linear.emptySlots(5) == <int>{}`
  - `tShape.emptySlots(4) == {3, 5}` (자리 4·6)
  - `tShape.emptySlots(7) == {3, 5}` (추가 카드 있어도 기본 빈 슬롯은 유지; Brief
    Model Anchors: "기본 빈 슬롯 (cardCount=min 시)" 정의 그대로)
  - `grid3x3.emptySlots(9) == <int>{}`
  - `tShape.slotCount(4) == 6` (ceil((4+2)/3)*3)
  - `tShape.slotCount(7) == 9` (ceil((7+2)/3)*3)
  - `grid3x3.slotCount(9) == 9`
  - `grid3x3.slotCount(10) == 12` (ceil(10/3)*3)
  - `linear.resolvePositions(3).length == 3`
  - `linear.resolvePositions(3)[0] == '카드 1'` (Brief Decision 8 — generic 라벨)
  - `tShape.resolvePositions(4).length == 4` (positions 수 = cardCount, 빈
    슬롯은 포함 안 됨)
- **파일**: 상동

## Test Files

| # | File Path | Test Count | Status |
|---|-----------|-----------|--------|
| 1 | `mobile/test/features/reading/domain/entities/layout_type_mapping_test.dart` | 3 groups / 18 test cases | Red (compilation failure, verified) |

## Red State Verification

**실행**: `cd mobile && flutter test test/features/reading/domain/entities/layout_type_mapping_test.dart`

**기대 실패 원인**: `package:personality_mobile/features/reading/domain/entities/layout_type.dart`
는 아직 존재하지 않음 (cycle 1 impl 에서 `spread_type.dart` → `layout_type.dart`
rename + enhanced enum 으로 재작성 예정). Dart 컴파일러가 import 를 해결하지
못해 `Target of URI doesn't exist` 오류로 테스트가 **실행 전 단계에서 실패**.

이것이 Red 상태의 핵심: 테스트가 "아직 구현되지 않았음" 을 명확히 가리킨다.

### 실행 결과 (2026-04-20)

```
$ cd mobile && flutter test test/features/reading/domain/entities/layout_type_mapping_test.dart
00:00 +0: loading .../layout_type_mapping_test.dart
test/features/reading/domain/entities/layout_type_mapping_test.dart:22:8:
  Error: Error when reading 'lib/features/reading/domain/entities/layout_type.dart':
  No such file or directory
import 'package:personality_mobile/features/reading/domain/entities/layout_type.dart';
       ^
... (Undefined name 'LayoutType' × 18) ...
00:00 +0 -1: Some tests failed.
```

- 컴파일 단계 실패: 1건 (URI 미해결)
- 참조 실패: 18건 (`Undefined name 'LayoutType'`)
- 테스트 실행 결과: `+0 -1` → Red 확정
- Green 조건: cycle 1 impl 이 `lib/features/reading/domain/entities/layout_type.dart`
  를 생성하고 prototype code (Research 007) 를 enhanced enum 형태로 반영하면
  18 케이스 전부 통과 예상

## Mapping to Brief 011

| Test Group | Brief 011 Ideal Criteria | Brief 011 Model Anchors |
|------------|--------------------------|-------------------------|
| T1 | #1 (enum 3 값 + computed 5개), #3 (매트릭스 런타임 일치) | 3 배치 매트릭스 표 |
| T2 | #10 (grid3x3 9장 의식적 매핑), #11 (tShape 7장 +N 좌→우) | 기본 드로우 매핑 (drawToSlot) |
| T3 | #9 (tShape 4장 빈 슬롯 2개), #12 (linear 자투리 슬롯) | 빈 슬롯 + slotCount 공식 + Decision 8 (generic 라벨) |

## Session Log

- 2026-04-20: tdd-red 스펙 문서 + 테스트 코드 작성 → `flutter test` 로 Red
  상태 (컴파일 실패 + 18 undefined-name 오류) 확정. 다음 단계: makeplan →
  impl 에서 `LayoutType` enhanced enum 구현.

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 56s | 217814 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 56s |
| Total Tokens | 217814 |
| Input Tokens | 10 |
| Output Tokens | 3434 |
| Cache Read | 160671 |
| Cache Creation | 53699 |
