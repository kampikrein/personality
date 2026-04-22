---
id: "015"
type: critique
title: "Brief 011 Critique — Alternatives"
created: 2026-04-20
status: completed
perspective: "alternatives"
target: "011"
confidence: high
summary: >
  Brief 011의 17 Decisions를 구체적 대안과 교차 검증한 결과, 12건은 현 선택이
  여전히 최선(단 일부는 Alternatives Considered 컬럼의 기각 근거를 보강해야 함),
  3건은 Toss-up이며, 2건은 대안이 더 우수해 보여 Brief 수정 권고(Decision 4의
  silent auto-reset, Decision 13의 enhanced enum vs sealed class). 특히 R-007
  결론을 그대로 상속한 Decision 13은 독립적 도전이 누락되었고, 프로젝트에 이미
  sealed class 선례(Failure)가 있다는 점에서 재고 가치가 있음.
keywords: [critique, brief, alternatives, design, sealed-class, enum, migration]
---

# Brief 011 Critique — Alternatives

## Executive Summary

- **검토 범위**: 17 Decisions 전체 + 3개 아키텍처 대안(전략 패턴·intEnum 전환·Stack placeholder 숨김) + 코드베이스 collision 조사
- **판정 분포**: Strong 12 / Toss-up 3 / Weak 2
  - **Strong (Brief 유지)**: Decisions 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 14
  - **Toss-up**: Decisions 15, 16, 17
  - **Weak (대안 권고)**: Decisions 4, 13
- **핵심 맥락**: Decisions 13~17은 Research 007~009에 의해 "해결됨"으로 상속되었고 Brief 단계에서 독립적 Alternatives 열을 형식적으로만 채웠다. 특히 Decision 13은 "enhanced enum은 호환된다"는 R-007 결론만 반영했을 뿐, "호환되므로 최적"은 아님에도 대안(sealed class) 비교가 누락되었다.
- **collision 조사 결과**: `mobile/lib` 전체에서 `LayoutType` 이름 사용처 0건, Flutter의 `Layout` 클래스 직접 import 0건, `class *Layout` 매칭은 `SpreadLayout` 한 건뿐 → Decision 2의 명명 충돌 우려는 실증적으로 낮음.

## Findings

### Strong Decisions (alternatives considered but Brief still wins)

#### Decision 1 — "단순 나열"의 한글 라벨 "나열"
- **Alternative 재검증**: "흐름", "기본", "일렬", "자유"는 Brief가 이미 합리적 기각 근거를 제시함.
- **추가 후보**: "한 줄" — 라벨이지만 `cardsPerRow=2` 설정 시 2행으로 렌더링되므로 라벨-실체 괴리 발생.
- **Verdict**: Brief 유지. "나열" 선택 근거 견고.

#### Decision 2 — enum 영문명 `LayoutType`
- **Alternative 1**: `LayoutKind` (suffix로 Type과 구분)
- **Alternative 2**: `CardArrangement` / `BoardLayout` (도메인 특이성 반영)
- **collision 실증**: `mobile/lib` 내 `LayoutType` 0건, Flutter `package:flutter/rendering.dart` 의 `Layout` 관련 타입 직접 import 0건, `LayoutBuilder`(위젯)는 spread_layout.dart 1곳뿐. 충돌 리스크 실질 없음.
- **Verdict**: Brief 유지. `LayoutType`은 Dart/Flutter 표준어와 일치하고 이미 SpreadType → LayoutType 교체 의도가 명확 (`...Type` 접미사 패턴). `LayoutKind`는 프로젝트 내 다른 enum들(`SpreadType`, `SyncStatus`, `CardSizePreset`)과 컨벤션 불일치.

#### Decision 3 — enum values `linear`, `tShape`, `grid3x3`
- **Alternative 1**: `tableau` (타로/솔리테어 용어) — 도메인 시적이지만 영어권/한국어권 모두 직관성 낮음
- **Alternative 2**: `grid` 단독 — Brief가 이미 모호성으로 기각
- **Dart 스타일 검증**: Dart 식별자는 알파벳/언더스코어로 시작해야 하며, `grid3x3`은 `g`로 시작하므로 합법. `analysis_options.yaml`의 `flutter_lints` 규칙도 digit 포함 camelCase를 금지하지 않음. `SyncStatus.pending`과 같이 flat camelCase 컨벤션 일관.
- **Verdict**: Brief 유지. `grid3x3`은 '크기 명세'가 도메인의 핵심 식별자이므로 숫자 포함이 오히려 명료.

#### Decision 5 — Drift migration with rename
- **Alternative**: 2단계 마이그레이션 (v8: 새 컬럼 `default_layout_type` 추가 + 복사, v9: 구 컬럼 drop)
- **비교**: 2단계는 (a) 각 단계가 단순/가역적, (b) 일시적 schema drift 수용, (c) 추가 schema snapshot 1개 더 관리. 현 1단계는 (a) ALTER TABLE RENAME COLUMN이 SQLite 3.25+ atomic, (b) m.database.transaction() wrap으로 부분 적용 방지됨, (c) pre-release 단계라 배포 창 분할 가치 없음.
- **Verdict**: Brief 유지. 출시 전(v0.1.1) + 개발자 데이터만 존재 + 단일 트랜잭션 원자성 보장이라는 3조건에서 2단계 분할의 실익 없음. 단 이 근거가 Brief의 Trade-off 열에 명시돼 있지 않으므로 **문서 보강 권고**: "출시 전 단계이므로 2단계 분할 불필요 — 출시 후라면 재평가" 주석 추가.

#### Decision 6 — `defaultSpreadType` → `defaultLayoutType` rename
- **대안 무실익**: 컬럼명만 유지는 코드/DB 용어 불일치, 모두 유지는 Brief 의도 위배. Brief 기각 근거 견고.
- **Verdict**: Brief 유지.

#### Decision 7 — T모양 4~10 가변
- **Alternative**: T모양 min=1 가변 (부분 T자 허용)
- **기각 근거 충분**: 사용자 명시 요청 + T자 의식적 형태 유지 하한. Brief 논리 견고.
- **Verdict**: Brief 유지.

#### Decision 8 — generic 라벨 `'카드 1'`
- **Alternative**: 영구 커뮤니티 번역 즉시 도입 — 도메인 합의 부재 상태에서 조기 lock-in 리스크.
- **Verdict**: Brief 유지. Out of Scope #1로 의도적 연기가 올바른 프레이밍.

#### Decision 9 — cardCount 슬라이더로 +N 통합
- **Alternative**: max=12 또는 별도 +1 버튼 — Brief가 폭 증가와 결과 페이지 인터랙션 확산으로 기각. 논리 견고.
- **Verdict**: Brief 유지.

#### Decision 10 — T모양 슬롯 매핑 {0,1,2,_,4,_}
- **Alternative**: +N을 빈 슬롯 패턴 유지로 확장 — 시각 복잡도 폭증으로 기각. 논리 견고.
- **Verdict**: Brief 유지.

#### Decision 11 — grid3x3 +1 단순 좌→우
- **Alternative 1**: +1 비허용 (cardCountMax=9) — 글로벌 max=10 비대칭 발생
- **Alternative 2**: +1도 4행 기둥 패턴 유지 — 1행으로 기둥 의미 성립 불가
- **추가 대안**: grid3x3 cardCountMax=9로 하되 Decision 9의 "글로벌 max=10"을 "배치별 max"로 리프레이밍 — 코드상 이미 `cardCountMax` 필드로 배치별 다르게 설정 가능하므로 "글로벌 max=10"은 사실상 UX 약속에 불과. 그러나 slider 상한이 배치 전환 시마다 변하는 건 이미 Decision 4로 수용됐으므로 비대칭이 실질 문제가 아님.
- **Verdict**: Brief 유지. 단 Brief의 근거 중 "의식적 일관성 결여"가 trade-off 열에 솔직히 기록돼 있어 문서 품질 양호.

#### Decision 12 — 3x3 드로우 순서 메뉴 (자리만)
- **Alternative**: 메뉴 완전 제외 — 사용자 명시 요청 위배
- **Verdict**: Brief 유지.

#### Decision 14 — GridView 단일 인프라
- **Alternative 1**: linear = Column/Wrap + tShape/grid3x3 = GridView 분기
- **Alternative 2**: Stack+Positioned 자유 좌표 (R-009에서 기각됨)
- **Alternative 3 추가 검토**: linear와 grid 계열을 별도 위젯 클래스로 분리 (`LinearSpreadLayout` / `GridSpreadLayout`) — 각 책임 명확하지만 LayoutType switch가 위젯 선택 레벨로 이동해 도메인 분기가 분산됨. 현 설계는 "LayoutType이 gridDelegate만 제어"로 분기 1개 → 코드 응집도 높음.
- **Verdict**: Brief 유지. 단일 GridView.builder + `crossAxisCount = layoutType.cardsPerRowOverride ?? cardsPerRow` 분기는 3 배치 통일 비용이 linear 가변 cardsPerRow 하나의 분기로 충분히 해결됨.

### Toss-up Decisions (alternative comparable, no clear winner)

#### Decision 15 — CustomPaint 점선 placeholder (~30줄)
- **Alternative A**: `BoxDecoration(border: Border.all(color: kSoftPurple.withValues(alpha: 0.25)))` solid faint border
  - **장점**: 0줄 + Flutter 표준. 디자인 토큰 직접. 기존 codebase의 `Border.all` 사용처 10개+와 일관.
  - **단점**: 솔리드 테두리는 "빈자리" 메타포가 약함. 사용자가 "여기 원래 뭐가 있어야 하나?" 직관적으로 해독 어려움. 점선은 서구/동양 UI 컨벤션 모두 "placeholder/dashed=empty" 의미가 확립돼 있음.
- **Alternative B**: Flutter SDK는 native dashed border 미지원 (BorderStyle enum은 `solid`/`none`만 있음; Material dashed는 InputDecorator 한정). Image.asset SVG는 래스터라이즈 비용 + 디자인 토큰 동적 적용 불가.
- **Trade-off 요약**: 코드 비용 30줄 vs UX 가독성 우세. 빈 슬롯은 T모양 4장 시 2개 눈에 띄는 요소이며 사용자 의식적 매핑 이해의 핵심. UX 비용이 30줄보다 비싸다는 판단이 합리적.
- **Verdict**: Toss-up이지만 Brief 선택이 약간 우세. 단 Brief가 "solid border 기각 근거를 시각적 구분 약함"으로만 써 뒀는데, **UX 관례(점선=placeholder) 근거 추가 보강 권고**.

#### Decision 16 — 명시적 `m.database.transaction()` wrap
- **Alternative**: DDL implicit commit + SQLite 자동 트랜잭션 의존
- **분석**: R-008-F3이 "drift onUpgrade가 자동 wrap되지 않음"을 확인했지만, 본 블록은 3개 statement(UPDATE, UPDATE, ALTER RENAME)로 간단. 중간 예외 시 SQLite가 statement 단위로 commit하므로 부분 적용 위험이 **이론적으로는** 있음. 그러나 UPDATE는 idempotent(동일 조건으로 재실행해도 같은 결과), ALTER RENAME COLUMN은 one-shot이라 재시도 시 "column not found" 오류로 식별 가능.
- **Alternative 이득**: verbose 감소 (try/finally + transaction 블록 제거) ~5줄 단축
- **Alternative 손실**: 미래 블록이 non-idempotent statement 포함 시 패턴 부재로 위험. 이번이 "첫 복합 마이그레이션"이므로 패턴 정립 가치 있음.
- **Verdict**: Toss-up. 현 Brief의 "패턴 정립 차원"이 타당하나 "항상 transaction wrap" 규칙으로 일반화하기엔 이번 블록 자체는 오버헤드. **Brief 문구 보강 권고**: "본 블록 자체는 idempotent하여 wrap 필수 아님. 향후 non-idempotent 마이그레이션 템플릿 정립 목적"으로 근거 명시.

#### Decision 17 — git-commit schema snapshot
- **Alternative**: CI 캐시 아티팩트로 schema snapshot 보관 (git 제외)
- **분석**: 
  - Git commit 방식은 (a) 체크아웃만으로 재현 가능, (b) schema 변경 PR이 diff로 보임 (review 가능), (c) merge 충돌 가능성 — 단 snapshot JSON은 SemVer 버전별 파일 분리(`drift_schema_v7.json`, `v8.json`...)이므로 동일 파일 동시 수정 가능성 거의 없음.
  - CI 아티팩트 방식은 (a) local setup에 CI 의존, (b) offline dev 시 테스트 불가, (c) 아티팩트 보존 기간 정책 필요, (d) 버전 히스토리는 있지만 review diff 불가.
- **Verdict**: Toss-up이나 **Brief 선택이 우세**. `drift_schemas/drift_schema_v7.json`이 이미 커밋돼 있음을 확인했고(현 상태), 각 버전 파일이 분리되므로 merge 충돌 실질 리스크 낮음. CI 아티팩트는 이 프로젝트 규모에 과공학.

### Weak Decisions (alternative likely better)

| # | Decision | Brief's Choice | Proposed Alternative | Reason Alternative Wins | Severity |
|---|----------|----------------|---------------------|------------------------|----------|
| 4 | 배치 변경 시 cardCount/cardsPerRow 처리 | 즉시 강제 조정 + 비활성 회색 | **예고형(preview) 조정 + Undo 토스트** (또는 최소한 이전 값 스냅샷 1회분 보존) | silent auto-reset은 사용자가 "내가 설정한 7장이 왜 9장으로 바뀌었지?" 상실감 유발. 특히 linear 7장 → grid3x3 → linear 복귀 시 기본값 3으로 돌아감. Flutter/Material의 form 패턴은 일반적으로 auto-adjust에 Snackbar/toast로 알림 제공 | Medium |
| 13 | 도메인 모델 진화 형태 | enhanced enum + computed properties | **Dart 3 sealed class + 3 서브클래스** (`sealed class Layout { ... } class LinearLayout extends Layout ...`) | (1) 프로젝트에 이미 sealed class 선례 있음 (`core/error/failures.dart`). (2) linear는 `cardsPerRowOverride: null`이지만 tShape/grid3x3는 `3` 고정 — nullable 강제는 per-subclass state를 enum으로 뭉갠 징후. sealed class면 `LinearLayout(cardsPerRow: int)` vs `TShapeLayout()`로 state shape가 다름을 타입 시스템이 표현. (3) Dart 3.x switch expression은 sealed class도 exhaustive 검사 지원. (4) 향후 배치 추가(켈틱 크로스 등) 시 새 subclass 파일 1개만 추가 — enum은 한 파일 편집 집중화. (5) Drift `textEnum`/`intEnum`은 sealed class 직접 지원 안 하지만, Brief가 이미 수동 `.name`/`byName` 패턴 유지(R-007-F5) → 직렬화는 `layout.typeName`/`Layout.fromTypeName(str)` 동등. | Medium |

### Missing Architectural Alternatives

#### M-1. Strategy 패턴 (DI container 등록)
- **내용**: `abstract class LayoutStrategy { int drawToSlot(...); Set<int> emptySlots(...); }` + 3 구현체 + DI 등록(`GetIt` 등). 
- **잠재 이득**: 단위 테스트 시 mock strategy 주입 쉬움, 새 배치 추가 시 DI 등록만.
- **잠재 손실**: `riverpod` 기반 프로젝트에 GetIt 신규 도입 = 의존성 중복. enum 3 값은 "유한하고 고정"이라 전략 패턴의 OCP(Open/Closed) 이득 불필요.
- **Brief 비고려 사유 합리성**: 타당. YAGNI.

#### M-2. Persistence: IntColumn + `intEnum<LayoutType>()` 전환
- **내용**: Brief R-007-F5가 "수동 `.name`/`byName` 패턴 유지 권장"으로 결정. 그러나 `SyncStatus`는 이미 `intEnum<SyncStatus>()` 패턴(`decks_table.dart:15`, `readings_table.dart:14`, `cards_table.dart:20`)을 쓰고 있음 → 코드베이스 내 **2개 enum 직렬화 스타일이 공존하는 불일치**가 이미 존재.
- **rename 기회**: SpreadType → LayoutType 전환 시점이 TextColumn → IntColumn 전환의 자연스러운 창. v7→v8 마이그레이션에 `ALTER TABLE readings ADD COLUMN spread_type_int INTEGER; UPDATE ... SET spread_type_int = CASE spread_type WHEN 'linear' THEN 0 ... END; ALTER TABLE DROP COLUMN spread_type; RENAME ... TO spread_type` 패턴 가능. 단 SQLite는 DROP COLUMN이 3.35+ 이후에만 지원, 본 프로젝트(3.40+ 번들)에서는 가능.
- **잠재 이득**: (a) 코드베이스 일관성(SyncStatus와 같은 스타일), (b) enum 값 이름 변경 시 DB 값 영향 없음 (리팩토링 저항성), (c) 약간의 저장 공간 절약.
- **잠재 손실**: (a) DB 수동 조회 시 가독성 저하 (0/1/2 대신 'linear'/'tShape'/...), (b) 마이그레이션 단계 추가, (c) enum 값 순서 변경 시 기존 데이터 손상 — 이것이 치명적. "linear는 항상 index 0" 같은 순서 고정 주석이 강제 필요.
- **Verdict**: **재고 권고**. R-007-F5는 "변경 표면 최소화"를 근거로 TextColumn 유지를 추천했는데, 이번 작업 자체가 이미 컬럼명/값 모두 변경하므로 "최소화" 논거가 약화됨. IntColumn 전환은 Toss-up이며 Brief가 명시적으로 대안을 열거하지 않았다는 점에서 **Brief에 Alternative 항목 추가 권고**.

#### M-3. Placeholder 대안: Stack + 비대칭 4장 레이아웃 (빈 슬롯 숨김)
- **내용**: tShape 4장을 GridView 대신 Stack + Align으로 렌더링, 빈 슬롯 위젯 없음. T자 형상은 1행 3장 + 2행 중앙 1장으로 절대 좌표.
- **잠재 이득**: (a) 빈 슬롯이 "시각 노이즈"라는 주장이 참이라면 더 깔끔, (b) _DashedRectPainter 불필요(코드 30줄 절약).
- **잠재 손실**: (a) R-009이 이미 Stack 접근을 8 비교 차원 중 7개에서 열위로 판정, (b) 사용자 명시 "한 줄 3장 고정 그리드 + 빈자리 2개" 표현과 부정합 — 사용자가 빈자리를 "자리"로 인지하고 있음, (c) +N 시 그리드 아래로 행 추가하는 자연스러움 사라짐.
- **Verdict**: Brief 유지. 사용자 원문이 빈 슬롯을 명시했다는 점이 결정적.

## Detailed Analysis

### Decision 4 상세 — silent auto-reset 문제

Brief는 "이전 카드 수 값 손실"을 Trade-off 열에 솔직히 기록하고 "배치별 cardCount 메모리"를 "UserSettings 복잡도 ↑, YAGNI"로 기각했다. 그러나 제3 옵션 **"휘발성 메모리 1-step undo"**는 UserSettings 확장 없이 presentation 레이어에 단기 상태 보유로 구현 가능하며 YAGNI 해당 안 됨. 구체적으로:

- home_page의 `_DrawSettingsPanel` StatefulWidget에 `int? _previousCardCount` 1개 필드 + 배치 전환 시점 Snackbar("9장으로 자동 조정됨. 되돌리기") 버튼.
- 배치 재전환 시 previous 값이 새 범위 안이면 복원 시도.
- UserSettings/DB 변경 0건, 단위 테스트 1건 추가.

Brief의 "silent auto-reset"은 Material design의 예측 가능성 원칙(사용자 예상 밖 상태 변화에 피드백 제공)과 충돌한다. Severity Medium — 기능 동작은 정상이지만 UX 품질 하향.

### Decision 13 상세 — sealed class vs enhanced enum

R-007은 "enhanced enum이 freezed/Drift와 호환된다"를 증명했을 뿐 "enhanced enum이 sealed class보다 우월하다"를 증명하지 않았다. Brief Decision 13의 Alternatives 열은 `(a) 별도 LayoutDefinition 클래스`를 언급하지만 이는 "외부 참조 클래스" 개념이지 "sealed 계층"이 아니다. 즉 **진짜 대안(Dart 3 sealed hierarchy)이 누락**됨.

실질 비교:

```dart
// 현 Brief (enhanced enum)
enum LayoutType {
  linear(cardCountMin: 1, cardCountMax: 10, defaultCardCount: 3, cardsPerRowOverride: null, ...),
  tShape(cardCountMin: 4, cardCountMax: 10, defaultCardCount: 4, cardsPerRowOverride: 3, ...),
  grid3x3(cardCountMin: 9, cardCountMax: 10, defaultCardCount: 9, cardsPerRowOverride: 3, ...);

  const LayoutType({required this.cardCountMin, ..., required this.cardsPerRowOverride, ...});
  final int? cardsPerRowOverride;  // linear만 null

  int drawToSlot(int drawIndex, int cardCount) => switch (this) { ... };
}

// Alternative (sealed class)
sealed class Layout {
  const Layout();
  int get cardCountMin;
  int get cardCountMax;
  int get defaultCardCount;
  String get displayName;
  String get typeName;  // for persistence
  int drawToSlot(int drawIndex, int cardCount);
  Set<int> emptySlots(int cardCount);
  int slotCount(int cardCount);

  static Layout fromTypeName(String name) => switch (name) {
    'linear' => const LinearLayout(),
    'tShape' => const TShapeLayout(),
    'grid3x3' => const Grid3x3Layout(),
    _ => throw ArgumentError('Unknown layout: $name'),
  };
}

class LinearLayout extends Layout {
  const LinearLayout({this.cardsPerRow = 3});
  final int cardsPerRow;  // non-null, subclass-specific
  @override int get cardCountMin => 1;
  @override int get cardCountMax => 10;
  // ...
}
class TShapeLayout extends Layout { /* cardsPerRow = 3 상수로 캡슐화, 필드 없음 */ }
class Grid3x3Layout extends Layout { /* 동일 */ }
```

**sealed class 우위 근거**:
1. **Nullable 제거**: `cardsPerRowOverride: int?` → `LinearLayout`만 `cardsPerRow: int` 필드 보유. null 분기 제거.
2. **Per-subclass state 확장성**: 미래에 `LinearLayout`이 `alignment` 같은 linear 특유 상태를 가진다면 enum은 다른 값들도 null 필드를 갖게 됨. sealed class는 영향 없음.
3. **프로젝트 선례 존재**: `mobile/lib/core/error/failures.dart`의 `sealed class Failure` + `DatabaseFailure` 등. 해당 패턴 재사용.
4. **Exhaustive switch**: Dart 3의 `switch (layout) { LinearLayout() => ..., TShapeLayout() => ..., Grid3x3Layout() => ... }`는 enhanced enum switch와 동일하게 exhaustive.
5. **직렬화 비용 동등**: `.typeName`/`fromTypeName(str)` 페어로 enum `.name`/`byName`과 라인 수 거의 같음. freezed는 sealed class를 `@Freezed(unionValueCase: FreezedUnionCase.pascal)` 패턴으로 native 지원.

**sealed class 열위 근거**:
1. **codegen 생태계**: json_serializable의 enum 지원은 1급, sealed class는 freezed union으로 취급(추가 boilerplate 가능성). 단 R-007-F3이 확인한 "현 프로젝트는 수동 `.name`/`byName`" 패턴이면 codegen 차이 무관.
2. **3 값 고정 도메인의 미니멀리즘**: 3 값이 절대 늘지 않는다면 enum이 더 가볍다. 그러나 Out of Scope #2 "추가 배치 종류"가 미래 사이클로 이미 예견됨 → 확장 가능성 있음.
3. **학습 곡선**: 팀 관성 — 기존 도메인 모델이 enum 위주면 sealed class 전환에 팀 동기화 비용.

**판정**: Brief가 sealed class 대안을 Alternatives Considered 열에 명시적으로 비교하지 않은 것은 R-007의 "enhanced enum 호환"을 "enhanced enum 최적"으로 확대 해석한 결과. 본 프로젝트 환경(Dart 3.6, sealed class 선례 존재, 배치 추가 가능성)에서 sealed class가 약간 우세. Severity Medium — 기능 동작은 동등하지만 미래 확장성/타입 정밀성 차이.

## Recommendations for Brief Revision

### 우선순위 1 (flip 권고)

**R-1**. **Decision 4 재검토**: "즉시 강제 조정 + 비활성 회색 + Snackbar 1-step undo" 로 업그레이드. 구현 비용 ~10줄 + 단위 테스트 1건 추가. Brief의 Ideal Criteria #7에 "범위 밖 현재값 리셋 시 Snackbar 표시" 추가.

**R-2**. **Decision 13 재검토**: sealed class 대안을 Alternatives Considered 열에 정식 추가하고, 다음 중 하나 선택:
- **(선택 A)**: enhanced enum 유지하되 기각 근거 보강 — "sealed class 우수하나 직렬화/codegen boilerplate 추가 비용이 현 3 값 도메인에서 실익 상회 안 함". 
- **(선택 B)**: sealed class로 전환 — failure.dart 선례 재사용 + 미래 배치 추가 대비. impl 사이클 1 prototype 코드 변경 필요.

### 우선순위 2 (문서 보강만)

**R-3**. **Decision 5**: Alternatives Considered 열에 "2단계 분할 마이그레이션(v8 add + v9 drop)" 추가, 기각 근거 명시 ("출시 전 단계 + 단일 트랜잭션 원자성 → 분할 실익 없음").

**R-4**. **Decision 15**: Alternatives Considered 열에 "BoxDecoration solid faint border" 추가, 기각 근거를 "점선=placeholder는 확립된 UX 관례, solid 테두리는 빈자리 의미 전달 약함"으로 강화.

**R-5**. **Decision 16**: Trade-off 열에 "본 블록 자체는 idempotent UPDATE 2 + ALTER 1으로 wrap 필수 아님. 미래 non-idempotent 마이그레이션 템플릿 정립 목적"을 명시.

**R-6**. **Missing Alternatives — M-2 (IntColumn 전환)**: Decision 5 또는 별도 Decision으로 "TextColumn 수동 매핑 유지 vs IntColumn `intEnum<LayoutType>()` 전환" 비교 추가. 프로젝트 내 SyncStatus가 이미 IntColumn 패턴이라는 사실 명시. Brief가 명시적 재고 후 결정했음을 문서에 남기는 것만으로도 가치.

### 우선순위 3 (유지)

Decisions 1, 2, 3, 6, 7, 8, 9, 10, 11, 12, 14, 17 은 현 선택 유지. Decision 2는 collision 실증 조사 결과 추가 근거 확보.

## References

| Resource | Path | Relevance |
|----------|------|-----------|
| Brief 011 | `/Users/kampikrein/A/personality/docs/2_tarot_draw/03_draw_experience_settings/011_Brief_layout_redesign.md` | 비평 대상 |
| Research 007 (enhanced enum) | `/Users/kampikrein/A/personality/docs/2_tarot_draw/03_draw_experience_settings/007_Research_enhanced_enum_codegen.md` | Decision 13 근거 — 호환성만 증명, 최적성 미증명 지점 |
| Research 008 (drift migration) | `/Users/kampikrein/A/personality/docs/2_tarot_draw/03_draw_experience_settings/008_Research_drift_migration_pattern.md` | Decision 5, 16, 17 근거 |
| Research 009 (slot rendering) | `/Users/kampikrein/A/personality/docs/2_tarot_draw/03_draw_experience_settings/009_Research_slot_based_rendering.md` | Decision 14, 15 근거 |
| 기존 sealed class 선례 | `/Users/kampikrein/A/personality/mobile/lib/core/error/failures.dart` | Decision 13 sealed class 대안의 프로젝트 내 precedent |
| intEnum 패턴 선례 | `/Users/kampikrein/A/personality/mobile/lib/core/database/tables/decks_table.dart:15` (+ readings_table, cards_table) | M-2 IntColumn 전환 대안의 선례 |
| 현 SpreadType enum | `/Users/kampikrein/A/personality/mobile/lib/features/reading/domain/entities/spread_type.dart` | 진화 대상 |
| 현 spread_layout | `/Users/kampikrein/A/personality/mobile/lib/features/reading/presentation/widgets/spread_layout.dart` | Decision 14 재작성 대상 |
| readings_table | `/Users/kampikrein/A/personality/mobile/lib/core/database/tables/readings_table.dart` | TextColumn vs intEnum 패턴 대비 |
| user_settings_table | `/Users/kampikrein/A/personality/mobile/lib/core/database/tables/user_settings_table.dart` | Decision 6 rename 대상 |
| analysis_options | `/Users/kampikrein/A/personality/mobile/analysis_options.yaml` | Decision 3 digit 식별자 lint 규칙 부재 확인 |
| Existing drift snapshot | `/Users/kampikrein/A/personality/mobile/drift_schemas/drift_schema_v7.json` | Decision 17 이미 커밋된 상태 확인 |

## Completion

- Decisions 17개 전수 검토 완료 + 아키텍처 대안 3건 (strategy 패턴, IntColumn, Stack placeholder) 추가 검토
- Weak 2 + Toss-up 3 + Strong 12 분류
- Brief 수정 권고 6건 (flip 2건 + 문서 보강 4건)
- 코드베이스 collision/precedent 실증 조사 완료 (sealed class 선례, intEnum 선례, LayoutType 이름 충돌 0건 확인)

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
