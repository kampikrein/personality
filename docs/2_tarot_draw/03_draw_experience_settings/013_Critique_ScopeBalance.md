---
id: "013"
type: critique
title: "Brief 011 Critique — Scope Balance"
created: 2026-04-20
status: completed
perspective: "scope-balance"
target: "011"
confidence: high
summary: >
  Brief 011의 전체 범위 감각은 타당하나 (complex 문제를 10 In Scope + 11 Out of
  Scope로 적절히 분절) In Scope #7과 #10에 구체성이 비는 구멍이 있고, In Scope
  #5/#9는 각각 2~3개의 분리된 concern을 번들링하며, In Scope #10은 이미 수행된
  작업(drift_schemas/, test/generated_migrations/ 커밋 5a62332)을 미래 작업으로
  표기하고 있다. grid3x3 리스트 페이지 필터 칩 마이그레이션 경로와 positions
  라벨 생성 위치가 Out of Scope 가드에 의해 공백 상태로 남아 impl 사이클 3에서
  암묵적 결정이 필요하다.
keywords: [critique, brief, scope, boundaries, cycle-balance]
---

# Brief 011 Critique — Scope Balance

## Executive Summary

Brief 011은 complex 문제를 10 In Scope + 11 Out of Scope로 분절한 점, Research
007~010 결과를 Decision 14~17로 수용한 점, 파일 영향도 맵 (`SpreadType` 참조
분포) 을 선제적으로 조사한 점에서 **scope 범위 자체는 대체로 타당하다**. 그러나
세 가지 구조적 문제가 있다:

1. **확인 불가능한 In Scope 항목**: #7 "`resolvePositions` 호출 호환 확인"은 실제
   signature 충돌(enum → enhanced enum 메서드 시그니처 호환성 + T/3x3 기본 반환값)
   을 "확인"으로 퉁치고 암묵적 구현 작업을 은닉한다.
2. **번들링된 In Scope**: #5 (동적 제약)와 #9 (cardCount 슬라이더 통합)가 각각
   위젯 변경 + 셔플 재실행 연동 + 저장 연동까지 포함한 3개 concern이면서 단일
   항목으로 묶여 있다.
3. **이미 수행된 작업이 In Scope에 포함**: #10은 `drift_schemas/` + `test/
   generated_migrations/` 생성을 prerequisite로 명세하나 실제 파일 시스템에는
   **이미 존재**(mtime Apr 20 00:43, commit 5a62332 "feat: mobile/drift_schemas").
   Brief가 현황을 반영하지 못하고 있다.

Cycle 분배는 Scope 006이 3사이클(도메인/DB/UI)을 명시했으나 Brief 011 기준으로
재측정하면 **Cycle 3이 가장 과중**하고 Cycle 2는 예상보다 가볍다 (schema dump
prerequisite가 이미 완료되었기 때문).

## Findings

### Strengths

1. **Research 통합 완결성**: Critical Review 3건 (CR#1 DB migration, CR#2 +1
   매핑, CR#3 enhanced enum 호환성) 이 모두 Decision 5/16/17, Decision 11,
   Decision 13으로 수용됨. Open Questions 0건은 실제 확신 있는 "0"으로 보임.
   [Brief 011:L186-194]
2. **파일 영향도 맵 선제 제시**: Context의 "SpreadType 참조 분포" 표가 12개 파일
   레이어별로 정리되어 있어 impl 사이클의 파일 목록 산정이 가능. 실제 grep 결과
   (23개 파일, .g.dart/.freezed.dart 제외 시 약 14개) 와 정합.
3. **도메인 모델 변경 경계 명시**: Decision 6이 "DB 컬럼명 `readings.spread_type`
   **유지** + `user_settings.default_spread_type` **rename**" 으로 비대칭을 명시
   적용. positions 의미 손실을 Out of Scope #6에 선언. 데이터 손실 범위가 명확.
4. **Out of Scope #11 묶음의 근거 명시**: dotted_border 패키지/Drift TypeConverter
   전환/Reveal 애니메이션 변경 3건이 각각 R-009-F2, R-007-F5, R-009-F6 근거로
   묶여 미도입 결정의 근거가 투명.
5. **Ideal Criteria 15건이 In Scope 1~10과 1:1 이상 매핑**: assertion-type만
   사용하고 Function/Edge/UX 3축 분산. standard 프로필 기본 원칙 준수.

### Weaknesses

| # | Finding | Severity | Evidence | Recommendation |
|---|---------|----------|----------|----------------|
| W1 | **In Scope #10이 이미 수행된 작업을 미래 작업으로 표기** | high | `mobile/drift_schemas/drift_schema_v7.json` 존재 (12885 bytes), `mobile/test/generated_migrations/schema.dart` + `schema_v7.dart` 존재. git log: `5a62332 feat: mobile/drift_schemas — 3개 파일 자동 커밋`. Brief 011 Constraints §codegen (L213-219) 와 In Scope #10 (L144) 은 이를 "impl 사이클 2 prerequisite" 로 명시 | #10을 분리: (a) **완료** — schema dump/generate (이미 수행됨, 확인만 필요), (b) **In Scope** — `migration_v7_to_v8_test.dart` 작성 (이것만 실제 미래 작업). Constraints에 "이미 커밋 5a62332로 수행됨, impl 사이클 2는 테스트 작성부터 시작" 명시 |
| W2 | **In Scope #7 "resolvePositions 호출 호환 확인"이 암묵 구현 작업을 은닉** | high | 현재 `spread_type.dart:39-51`의 `resolvePositions`/`resolveGuidances`는 `if (this != SpreadType.custom)` 분기로 `positions` final 필드 반환. LayoutType 진화 시 `positions` 필드 자체가 사라지거나 (linear에만 있음) generic 라벨 생성 로직이 다르게 분포됨. "호환 확인"이 아니라 **재설계**. Brief는 Out of Scope #1 "positions 한국어 카피 별도" + Decision 8 "generic 라벨 자동 생성 (`'카드 1'`...)" 만 명시 — 어디서 자동 생성할지 미지정 | #7을 둘로 분리: (a) 리스트/상세 페이지 **호출 사이트 adaptor** — 타입 변경만, (b) **LayoutType.resolvePositions(cardCount) 메서드 재정의** — 3 enum 모두 `List.generate(n, (i) => '카드 ${i+1}')` 반환하는 통일 메서드로 재설계. Decision에 명시 |
| W3 | **In Scope #5가 3개 concern 번들** | medium | "배치 변경 시 cardCount 슬라이더 min/max 즉시 변경" + "현재 값이 범위 밖이면 리셋" + "cardsPerRow는 tShape/grid3x3에서 3 고정 + 회색 비활성" 3개가 한 항목. 각각 `_CountStepper` 제약 재설계 / `updateDefaultCardCount` 강제 호출 / `_PillSelector` disabled state 추가 — 서로 다른 위젯 변경 | #5를 #5a (cardCount 동적 min/max + 리셋), #5b (cardsPerRow 동적 활성/비활성) 로 분리. Ideal Criteria #7, #8이 이미 2개로 분화되어 있으므로 In Scope도 동일하게 분리 권장 |
| W4 | **In Scope #9 "cardCount 슬라이더로 통합"이 셔플 재실행 연동을 함의하나 Out of Scope #5와 긴장** | medium | #9: "슬라이더 변경 시 셔플 재실행 + 결과 페이지 재렌더". OoS #5: "셔플 단계 UI 변경. 셔플 화면은 그대로". 결과 페이지의 `_executeDraw()` 재호출은 OoS가 가드하는 "셔플 화면 UI" 가 아니지만 경계가 모호. 현 `draw_result_page.dart:133` `_addOneMore()` 가 슬라이더와 결합되면 실제로 **별도 +1 버튼 삭제**가 필요 (지금 결과 페이지 하단에 `+${_currentCardCount}장` 버튼 존재, L272) | #9에 명시적으로 두 하위 액션 추가: (i) `_addOneMore` 버튼 및 `_ResultBtn` `+N장` 제거, (ii) cardCount 슬라이더 변경 시 `_executeDraw()` 재호출로 rewind. OoS #9 "별도 +1 버튼"과 연동 명시 |
| W5 | **Cascading rename scope 미전파 — animated_draw_page.dart 누락** | high | Context §SpreadType 참조 분포 표 (L68-80) 에 `draw_result_page.dart`, `animated_draw_page.dart` 누락. 실제 grep: `animated_draw_page.dart` L28-29, 53-56에 `_spreadType = settings?.defaultSpreadType ?? SpreadType.custom; _currentCardCount = _spreadType == SpreadType.custom ? settings?.defaultCardCount : _spreadType.cardCount;` — `.cardCount` 직접 참조. LayoutType 진화 시 `SpreadType.single.cardCount = 1` 같은 고정값이 없어지므로 이 초기화 로직 전면 재작성 필요. Scope 006은 `draw_result_page.dart`도 언급 안 함 | Context 표에 두 파일 추가: `draw_result_page.dart` (L29, 53-56), `animated_draw_page.dart` (L29, 53-56). In Scope #1 또는 #9에 "`_spreadType.cardCount` 직접 참조 제거 + `defaultCardCount` + `LayoutType.defaultCardCount` 로 단일화" 명시 |
| W6 | **Reading 엔티티의 `spreadType` 필드명 vs 도메인 "LayoutType" 비일관성 미해결** | medium | Decision 6: `defaultSpreadType → defaultLayoutType` (field + column rename). 그러나 `reading.dart:13` `required SpreadType spreadType` 는 **필드명 유지 + 타입만 교체**가 Scope 006 cycle 1의 계획 (L122). Brief 011에 이 비대칭이 명시적 Decision 되지 않음. `.fromJson`/`.toJson` 은 field 이름 `'spreadType'` 을 키로 사용 → 기존 reading JSON 파일/export 포맷 안정성 대가로 코드 내 용어 통일 포기. Ripple: `reading_list_page.dart:171` `reading.spreadType`, `reading_detail_page.dart:77,82` `reading.spreadType` | Decision에 "Reading 엔티티 필드 `spreadType` 은 **필드명 유지** (타입만 `SpreadType → LayoutType`)" 명시 + rationale (`_$ReadingEnumMap` 이름 'spreadType' 유지로 JSON 호환성). 대체 결정 "LayoutType 용어 완전 통일 → `layoutType` field rename" 은 Out of Scope로 명시. 현재는 미언급으로 남아 있음 |
| W7 | **Critique 통합이 Brief 메타데이터는 반영하지만 Brief 005 status 전환을 누락** | low | Brief 011 frontmatter `supersedes: "005"` 명시. 그러나 `005_Brief_layout_redesign.md` 는 `status: in-progress` 그대로. 파이프라인이 두 Brief 중 어느 것이 active 인지 앞으로도 혼동 가능 | Brief 005 frontmatter를 `status: superseded`, `superseded_by: "011"` 로 후속 업데이트 필요. Brief 011 completion 시 자동 트리거 또는 impl 사이클 시작 전 수동 전환 |
| W8 | **Cycle 분배 재측정 시 Cycle 3 편중** | medium | Scope 006: Cycle 1 Modified 6, Cycle 2 Modified 7, Cycle 3 Modified 7 (표면). 재측정: Cycle 2의 drift_schemas/generated_migrations은 이미 완료(5a62332) → 실질 Cycle 2 Modified ≈ 5 (app_database.dart schemaVersion bump, onUpgrade block, user_settings_table.dart rename, migration test 신규 1, user_settings.dart field rename). Cycle 3은 home_page.dart 대폭 (850L 중 panel section ~170L 재구조 + dynamic constraints 로직 신설) + spread_layout.dart 전면 재작성(106L) + draw_result_page.dart (+1 버튼 제거, 슬라이더 연동) + animated_draw_page.dart (init 로직 재작성) + reading_list_page.dart (필터 칩 + icon) + 신규 위젯 파일 (_EmptySlotPlaceholder, _DashedRectPainter) + 신규 테스트 파일 2 = **실질 Modified 6 + 신규 3 + 테스트 2**. UI 인프라 변화가 가장 리스크 높은 구간인데 cycle 수는 동일 | Cycle 3을 (a) Cycle 3a (settings panel restructure + home_page 변경), (b) Cycle 3b (결과 페이지 GridView 재작성 + spread_layout + 빈 슬롯 placeholder), (c) Cycle 3c (reading_list/reading_detail 필터·아이콘) 로 추가 분할 고려. 최소 Scope 006 의 cycle 분배 재검토 필요 |

### Missing Elements

| # | What's Missing | Why It Matters | Suggestion |
|---|---------------|----------------|------------|
| M1 | **Reading 엔티티 `spreadType` field의 JSON key 결정** | `reading.dart:13` freezed factory parameter가 `spreadType`이면 `_$ReadingImplToJson` 이 `'spreadType': _$LayoutTypeEnumMap[instance.spreadType]!` 생성. 기존 reading JSON export (있다면) 호환성 지대. Brief는 `freezed ^2.5.0` + `json_serializable ^6.8.0` 만 명시하고 필드 레벨 결정 미지정 | 명시적 Decision 추가: "Reading.spreadType 필드명 및 JSON 키 모두 유지, 타입만 LayoutType으로 교체 (이유: export 포맷 backward compat)". 또는 명시적 반대 결정 (`@JsonKey(name: 'layoutType')`) |
| M2 | **positions generic 라벨 생성의 "누가/어디서" 질문** | Decision 8: "generic 라벨 자동 생성(`'카드 1'`...)". 현재 `spread_type.dart:39-51`의 `resolvePositions(int)` 가 담당 — linear는 empty, custom은 generated, threeCard는 static. LayoutType 에서는 3 enum 모두 generic을 사용하는 통일 로직 필요. 이 메서드의 새 signature + 구현이 In Scope 어디에도 명시되지 않음. #7 "호환 확인" 으로 암묵 위임 | In Scope #1 `LayoutType` 메서드 리스트에 `resolvePositions(int cardCount) → List<String>` 추가 (linear/tShape/grid3x3 모두 `List.generate(n, (i) => '카드 ${i+1}')`) + Model Anchors에 통일 정책 추가 |
| M3 | **기존 reading 데이터의 `.position` 필드 vs 새 슬롯 개념 간극** | `DrawnCardInfo.position` 은 draw 순서 (0-based). 새 모델은 draw → slot 매핑이 LayoutType별 다름. reading 저장 시 `position = drawIndex` (저장 시점의 순서) 인지, `slotIndex` (배치 그리드 상 위치) 인지 불명확. Decision 없음. migration 로직도 position 필드는 미변경 | 명시적 Decision: "DrawnCardInfo.position 은 draw 순서 (drawIndex) 로 영구 고정. 슬롯 인덱스는 LayoutType.drawToSlot(position) 으로 렌더링 시 계산". Out of Scope #6 (positions 의미 보존) 과 별개 concern |
| M4 | **`watchReadingsBySpreadType` DAO 쿼리의 값 호환 정책** | `reading_repository_impl.dart:79-83`. v7 이전 데이터는 `'single'/'threeCard'/'custom'` 저장됨. migration 후 모두 `'linear'` 로 통일. 그러나 사용자가 DB를 downgrade or legacy dump에서 import할 때 filter UI가 `'single'` 값에 대해 어떻게 반응? reading_list_page.dart:42 `SpreadType.values` loop 는 마이그레이션 후 `LayoutType.values` 로 교체. legacy값 존재 시 `LayoutType.values.byName('single')` ArgumentError 발생 | Repository `_toDomainReading` 에 defensive mapping: `try { byName(row.spreadType) } catch { LayoutType.linear }`. Out of Scope #6 (위치 의미 보존 안 함)과 정합. Brief에 명시 필요 |
| M5 | **OoS로 선언해야 할 drift 테이블 rename 미포함** | `readings_table.dart` 테이블 자체는 그대로 `readings`, 컬럼 `spread_type` 유지. 그러나 `readings_table.dart:8` 의 Dart getter `spreadType` 은 유지하면서 Drift 타입만 TextColumn 그대로 — Dart 필드명 유지가 암묵 결정. 명시 필요 | OoS 추가 항목: "`readings` 테이블 컬럼명(`spread_type`) 및 `readings_table.dart`의 Dart getter(`spreadType`) 유지 — migration 부담 최소화". Decision 6 비대칭 이유 확장 |
| M6 | **OoS 사이에 "3x3 드로우 순서 저장" 부재** | In Scope #8: 3x3 드로우 순서 메뉴 자리. "기본" + "다른 순서(준비 중)". 그러나 "기본" 이외 옵션이 미래에 추가되면 `UserSettings.default3x3DrawOrder` 같은 필드가 필요. 현재 필드 없음. Brief는 저장 정책 미언급 → impl 사이클 3에서 "기본만 있으니 저장 안 함" 선택 시 미래 부채 | OoS 또는 Decision에 "메뉴의 '기본' 선택값 저장하지 않음 (선택이 1개뿐). 미래 다른 옵션 추가 시 `UserSettings` 필드 추가는 별도 사이클" 명시 |
| M7 | **시각 검증 5종 중 linear cardsPerRow 가변 시나리오 부재** | Constraints §시각 검증 5종: linear 관련 스크린샷 없음 (tShape 2건, grid3x3 1건, 모양 그룹 1건, 배치 변경 1건). Ideal Criteria #12는 linear 5장 cardsPerRow=2 `SizedBox.shrink` 엣지케이스만 assertion. 시각 확인이 Criteria에만 있고 Constraints에는 없음 | 시각 검증 6번 항목 추가: "(f) linear cardsPerRow=2, 5장 결과 페이지 — 마지막 행 1장 + 우측 2칸 shrink". Edge Criteria #12와 1:1 대응 |

## Detailed Analysis

### 1. 이미 수행된 작업의 In Scope 포함 (W1 상세)

Brief 011 In Scope #10 원문: "`dart run drift_dev schema dump` 로 v7 snapshot을
`mobile/drift_schemas/` 에 생성 + git commit. `drift_dev schema generate` 로
`mobile/test/generated_migrations/` 자동 생성. `mobile/test/database/
migration_v7_to_v8_test.dart` 작성".

파일 시스템 실측:
- `/Users/kampikrein/A/personality/mobile/drift_schemas/drift_schema_v7.json`
  (12885 bytes, mtime Apr 20 00:43)
- `/Users/kampikrein/A/personality/mobile/test/generated_migrations/schema.dart`
  + `schema_v7.dart` (82262 bytes)
- `/Users/kampikrein/A/personality/mobile/test/database/` — **존재하지 않음**

git log: `5a62332 feat: mobile/drift_schemas — 3개 파일 자동 커밋` (최근 커밋).

→ In Scope #10의 세 하위 항목 중 **2개는 이미 완료**, 1개(`migration_v7_to_v8_test.dart`)
만 진짜 미래 작업. Brief가 파이프라인 시작 시점에 이 현황을 반영하지 않으면 impl
cycle 2가 불필요한 재생성 시도를 하거나 "이미 존재" 에러로 혼동 발생 가능.

### 2. In Scope #7 "호환 확인"의 은닉 작업 (W2, M2 상세)

현 `spread_type.dart`:
```dart
List<String> resolvePositions(int actualCardCount) {
  if (this != SpreadType.custom) return positions;  // single: ['현재'], threeCard: ['지나온 길', '현재', '가능성']
  return List.generate(actualCardCount, (i) => '카드 ${i + 1}');
}
```

LayoutType 진화 시나리오:
- `positions` final 필드 자체가 LayoutType에 없음 (Decision 1/13에 없음)
- Decision 8: "generic 라벨 자동 생성 (`'카드 1'`...)" 는 **모든** LayoutType에 적용됨
  ("linear" 포함 — threeCard에 있던 '지나온 길/현재/가능성' 의미 라벨 소실이 OoS #6)
- → `resolvePositions` 의 새 구현은 "항상 generic" 이므로 `resolveGuidances` 도 동일

그러나 Brief 011 In Scope #1의 메서드 리스트: `cardCountMin/Max, defaultCardCount,
cardsPerRowOverride, displayName, slotCount, emptySlots, drawToSlot` — **`resolvePositions`
/ `resolveGuidances` 부재**.

호출 사이트: `spread_layout.dart:42,62,95` + `reading_detail_page.dart:77`. 이들은
Compile-time에 메서드 결여 시 즉시 fail. 따라서 Brief가 명시하지 않아도 반드시
구현되어야 하는 암묵 작업 — **In Scope의 투명성을 훼손**.

### 3. In Scope #5, #9 번들링 (W3, W4 상세)

In Scope #5 원문: "배치 변경 시 cardCount 슬라이더의 min/max가 즉시 변경 ... 현재
값이 새 범위 밖이면 `defaultCardCount`로 리셋. cardsPerRow는 tShape/grid3x3에서
3 고정 + 회색 비활성"

하위 작업 매트릭스:
| 하위 | 대상 위젯 | 변경 성격 |
|------|----------|----------|
| 5a | `_CountStepper` (또는 slider) | min/max props dynamic + `repo.updateDefaultCardCount` 강제 호출 |
| 5b | `_PillSelector<int>` (cardsPerRow) | disabled state 추가 + 비활성 시 값 3 강제 |

In Scope #9 원문: "... cardCount 슬라이더로 통합. 슬라이더 변경 시 셔플 재실행 +
결과 페이지 재렌더. 결과 페이지에 별도 +1 버튼 없음".

하위 작업 매트릭스:
| 하위 | 대상 | 변경 성격 |
|------|------|----------|
| 9a | `draw_result_page.dart` L133 `_addOneMore()` | 메서드 및 버튼 제거 (L270-277 `+${_currentCardCount}장` `_ResultBtn`) |
| 9b | `home_page.dart` 슬라이더 `onChanged` | `updateDefaultCardCount` + (조건부) 결과 페이지 재진입 트리거 |
| 9c | `draw_result_page.dart` rewind 경로 | cardCount 증감 시 `_executeDraw()` 재호출 대신 `_revealedPositions` 업데이트 only? shuffle 결과는 이미 `_shuffleResult.cards` 에 max로 존재 |

9c는 실제로 Decision 10의 "cardCount 슬라이더 통합" 과 셔플 재실행이 매번 새 결과를
내는지, 아니면 한 번 셔플 후 take(cardCount) 만 바꾸는지 모호. 현 `draw_result_page.dart:99`
`for (var i = 0; i < _currentCardCount; i++) _revealedPositions.add(i);` 가 존재 —
**셔플 재실행이 아니라 `_currentCardCount` 증가만으로 이미 처리 가능**.

→ In Scope #9의 "셔플 재실행" 어구가 실제 코드 동작(증분 update) 과 충돌 가능성.
   이를 decision 에서 명확히 하지 않으면 impl agent가 잘못된 경로를 택할 위험.

### 4. Cascading rename 전파 누락 (W5 상세)

Brief 011 Context § SpreadType 참조 분포 표에 나열된 12개 파일 vs 실제 grep 결과:

| 파일 | Brief에 명시 | grep 결과 SpreadType 라인 |
|------|-------------|--------------------------|
| `spread_type.dart` | yes | (정의) |
| `reading.dart` | yes | L13 |
| `reading_repository_impl.dart` | yes | L31, 79, 98 |
| `reading_repository.dart` | yes | L11 |
| `reading_providers.dart` | yes | L24-29 |
| `reading_dao.dart` | yes | (watchReadingsBySpreadType) |
| `user_settings_table.dart` | yes | L15 |
| `user_settings.dart` | yes | L19 |
| `spread_layout.dart` | yes | L10, 19, 29-32 |
| `reading_list_page.dart` | yes | L18, 42, 171, 210-214 |
| `reading_detail_page.dart` | yes | L77, 82 |
| `home_page.dart` | yes | L456-463 |
| **`draw_result_page.dart`** | **no** | **L8, 29, 53-56, 123, 180** |
| **`animated_draw_page.dart`** | **no** | **L28-29, 53-56, 241** |
| **`user_settings_repository_impl.dart`** | **no** | **L61-63, 113** |

3개 파일 누락. `user_settings_repository_impl.dart` 는 Scope 006 cycle 2에 있지만
Brief 011에는 없음. `draw_result_page.dart`, `animated_draw_page.dart` 는 **양쪽 모두
에서 누락** — Scope 006 cycle 3에도 없음. 이 두 파일은 `_spreadType.cardCount` 직접
참조(L55-56) 가 있어 LayoutType 진화 시 반드시 변경 필요.

### 5. Reading 필드 비대칭의 장기 부채 (W6, M1 상세)

Decision 6이 명시한 rename:
- `UserSettings.defaultSpreadType` → `defaultLayoutType` (Dart field + DB column)

미명시된 유지:
- `Reading.spreadType` (Dart field) — 유지
- `readings.spread_type` (DB column) — 유지

결과: 한 엔티티 내에서 같은 의미의 필드가 `UserSettings.defaultLayoutType` vs
`Reading.spreadType` 으로 갈라짐. Dart 코드에서 양쪽을 동시 다루는 위치가 있음:
- `draw_result_page.dart:53`: `_spreadType = settings?.defaultSpreadType ?? SpreadType.custom;`
  → migration 후: `_layoutType = settings?.defaultLayoutType ?? LayoutType.linear; ... reading.spreadType = _layoutType;`

이 비대칭 자체가 한 번은 합리적 ("reading 테이블 마이그레이션 최소화") 지만
Brief 011에 rationale 부재. 미래 개발자가 "Reading은 왜 `spreadType` 인가?" 라고
물으면 답을 Brief에서 찾을 수 없음.

### 6. Critique integration의 연쇄 효과 (W7 상세)

Brief 005 `status: in-progress` + Brief 011 `supersedes: "005"` 조합은 Git 상태의
DAG와 유사. 파이프라인이 `005`를 아직 참조하는 체크리스트 아이템이 있을 가능성
(Scope 006이 `traces_brief: "docs/15_draw_experience_settings/005_Brief_layout_redesign.md"`).

→ Scope 006의 `traces_brief` 도 011로 갱신 필요 (현재 005를 가리킴). 또는 Brief
  011에 `traces_scope: "006"` 외에 "005 Brief 및 006 Scope 모두 011의 transitive
  prerequisite" 명시.

## Cycle Workload Distribution

Scope 006 3 cycle 분배 vs Brief 011 재측정:

| Cycle | 목표 | Scope 006 Modified | 실제 재측정 | 신규 | 테스트 | 리스크 |
|-------|------|-------------------|------------|------|--------|--------|
| 1 (도메인) | SpreadType → LayoutType + enhanced enum | 6 (spread_type, reading, reading_repository i/f + impl, reading_providers, reading_dao) | **8** (추가: draw_result_page init, animated_draw_page init, user_settings_repository_impl의 byName) | 0 | 1 (`layout_type_mapping_test.dart`, 24+ 케이스) | medium — enhanced enum codegen 첫 시도. `resolvePositions` 재정의 누락 시 compile fail 연쇄 |
| 2 (DB) | v7→v8 migration + UserSettings rename | 7 (app_database, readings_table 주석, user_settings_table, user_settings.dart, user_settings_repository_impl, settings_providers, migration test) | **5** (drift_schemas/generated_migrations 이미 완료로 -2) | 0 | 1 (`migration_v7_to_v8_test.dart`, 3 케이스) | low — 기존 6 사이클 컨벤션 확장 + R-008 prototype 그대로 |
| 3 (UI) | 모양 그룹 + 동적 제약 + GridView 재작성 + 목록/상세 | 7 (home_page, spread_layout, reading_list_page, reading_detail_page, _EmptySlotPlaceholder 신규, layout_type_mapping test, card_count_auto_adjust test) | **9** (추가: draw_result_page `_addOneMore` 제거, animated_draw_page `_currentCardCount` 초기화 재작성, `_DashedRectPainter` 신규 파일) | 2 (`_EmptySlotPlaceholder`, `_DashedRectPainter`) | 1 (`card_count_auto_adjust_test.dart`) + 시각 검증 5종 | high — UI infra 재작성 + GridView + LayoutBuilder + 애니메이션 키 + 동적 비활성 |

**결론**: Cycle 2는 Brief 예상보다 **가볍고** (prerequisite 이미 수행), Cycle 3은
**무거움** (UI 중복 변화 + 시각 검증 부담). Scope 006의 "3 cycle 균등" 전제는
실측과 불일치. Cycle 3 재분할 (3a: settings panel + 동적 제약, 3b: 결과 페이지
GridView, 3c: 목록/상세 + 시각 검증) 고려 가치 있음.

## Recommendations for Brief Revision

1. **In Scope #10 분해**:
   - #10a: (완료) `drift_schemas/drift_schema_v7.json` + `test/generated_migrations/`
     이미 커밋 5a62332. 확인만.
   - #10b: (In Scope) `mobile/test/database/migration_v7_to_v8_test.dart` 작성.
     SchemaVerifier 기반 3 케이스.

2. **In Scope #1 메서드 리스트 확장**: `resolvePositions(int)`, `resolveGuidances(int)`
   추가. 3 enum 모두 `List.generate(n, (i) => '카드 ${i+1}')` 통일 구현 명시.

3. **In Scope #7 재작성**: "리스트/상세 페이지에서 `SpreadType` → `LayoutType`
   타입 교체 + `_spreadTypeIcon` 아이콘 매핑 갱신 + `spreadType.displayName` 호출
   호환 (`LayoutType` 도 `displayName` 유지 확정)".

4. **In Scope #5 분할** → #5a (cardCount 동적), #5b (cardsPerRow 비활성).

5. **In Scope #9 하위 액션 명시**: (i) `_addOneMore` 및 `+N장` 버튼 제거, (ii)
   cardCount 변경 시 `_revealedPositions` 증분 처리 (셔플 재실행 아님), (iii)
   `_shuffleResult.cards.take(cardCount)` 로 rewind.

6. **Context § SpreadType 참조 분포 표 확장**: `draw_result_page.dart`, `animated_draw_page.dart`,
   `user_settings_repository_impl.dart` 3 파일 추가.

7. **Decision 추가** (신규 18): "Reading.spreadType 필드명 및 JSON 키 유지, 타입만
   LayoutType으로 교체. Rationale: `_$ReadingEnumMap` JSON key 'spreadType' backward
   compat + `readings.spread_type` DB column 유지와 정합. UserSettings는 rename —
   Brief/앱에서는 사용자 노출 없으므로 용어 정화 우선."

8. **Decision 추가** (신규 19): "`DrawnCardInfo.position` = drawIndex (저장). 슬롯
   인덱스는 렌더 시점에 `LayoutType.drawToSlot(position, cardCount)` 로 계산. 저장
   모델 불변."

9. **OoS 추가**: "(12) `readings_table` 컬럼명 / `readings_table.dart` Dart getter
   이름 유지 — Decision 6과 비대칭 (reading 테이블 migration 부담 최소화). (13)
   legacy enum 값 (`single`/`threeCard`/`custom`) 의 reading 필터링 — migration
   로직이 모두 `linear` 로 변환, 사용자 import/downgrade 시나리오 미지원."

10. **시각 검증 추가**: 6번 항목 "linear cardsPerRow=2, 5장 결과 페이지" 추가.

11. **Brief 005 frontmatter 후속**: `status: superseded, superseded_by: "011"`
    자동/수동 전환 절차 명시.

12. **Scope 006 재조정 제안**: cycle 2 workload 감소 + cycle 3 workload 재분할
    (3a/3b/3c) 제안을 synthesis 후속 문서에 남김.

## References

| Resource | Path | Relevance |
|----------|------|-----------|
| Primary | `/Users/kampikrein/A/personality/docs/2_tarot_draw/03_draw_experience_settings/011_Brief_layout_redesign.md` | 주요 비평 대상 |
| Scope 006 | `/Users/kampikrein/A/personality/docs/2_tarot_draw/03_draw_experience_settings/006_Scope_layout_redesign.md` | cycle 분배 근거 |
| Research 007 | (enhanced enum codegen) | fallback 불필요 근거 |
| Research 008 | (drift migration) | prerequisite 목록 |
| Research 009 | (slot rendering) | GridView + placeholder 근거 |
| Synthesis 010 | (통합) | Brief 011 업데이트 근거 |
| Brief 002 | `/Users/kampikrein/A/personality/docs/2_tarot_draw/03_draw_experience_settings/002_Brief_settings_menu_relocation.md` | sibling scope 예시 — 5 In Scope / 6 OoS 정도의 simple complexity |
| Scope 003 | `/Users/kampikrein/A/personality/docs/2_tarot_draw/03_draw_experience_settings/003_Scope_settings_menu_relocation.md` | effort_mode=bypass 단일 사이클 예시 |
| `spread_type.dart` | `/Users/kampikrein/A/personality/mobile/lib/features/reading/domain/entities/spread_type.dart` | `resolvePositions`/`resolveGuidances` 현 구현 |
| `spread_layout.dart` | `/Users/kampikrein/A/personality/mobile/lib/features/reading/presentation/widgets/spread_layout.dart` | W2, W8 근거 |
| `home_page.dart` | `/Users/kampikrein/A/personality/mobile/lib/features/home/presentation/pages/home_page.dart` | L380-558 `_DrawSettingsPanel` 현 구조 |
| `draw_result_page.dart` | `/Users/kampikrein/A/personality/mobile/lib/features/draw/presentation/pages/draw_result_page.dart` | W4 `_addOneMore`, W5 cascading rename 근거 |
| `animated_draw_page.dart` | `/Users/kampikrein/A/personality/mobile/lib/features/draw/presentation/pages/animated_draw_page.dart` | W5 `_spreadType.cardCount` 직접 참조 |
| `reading.dart` | `/Users/kampikrein/A/personality/mobile/lib/features/reading/domain/entities/reading.dart` | W6, M1 근거 (field 이름 유지 비대칭) |
| `reading_repository_impl.dart` | `/Users/kampikrein/A/personality/mobile/lib/features/reading/data/repositories/reading_repository_impl.dart` | M4 근거 (byName ArgumentError 리스크) |
| `user_settings_repository_impl.dart` | `/Users/kampikrein/A/personality/mobile/lib/features/settings/data/repositories/user_settings_repository_impl.dart` | W5 누락 파일 |
| `drift_schemas/drift_schema_v7.json` | `/Users/kampikrein/A/personality/mobile/drift_schemas/drift_schema_v7.json` | W1 "이미 완료" 증거 (commit 5a62332) |
| `test/generated_migrations/` | `/Users/kampikrein/A/personality/mobile/test/generated_migrations/` | W1 "이미 완료" 증거 |
| git log | `5a62332 feat: mobile/drift_schemas — 3개 파일 자동 커밋` | W1 타임라인 |

## Completion

- [x] 10 In Scope 항목 평가 — 각 항목별 concern 번들링 + 은닉 작업 + 기존 상태
  오인식 분석
- [x] 11 Out of Scope 항목 평가 — 누락된 가드 2건 추가 제안 (M5, M6)
- [x] Cycle 분배 재측정 — Cycle 2 경감 / Cycle 3 편중 확인
- [x] Research 007~010 Critique 통합 반영 상태 검증 — Decision 5, 13, 14~17 1:1 대응
- [x] 코드베이스 실측 — grep SpreadType 23개 파일 중 Brief Context 표와 3 파일 불일치
- [x] 파일 시스템 실측 — drift_schemas/ 및 test/generated_migrations/ 이미 커밋됨 확인

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
