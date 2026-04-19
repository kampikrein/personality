---
id: "005"
type: brief
title: "스프레드 → 배치 재설계: LayoutType 도입, 슬롯·드로우 매핑, 모양 그룹"
created: 2026-04-19
status: in-progress
quality_profile: standard
deep_critique: false
critique_docs: []
summary: >
  SpreadType ↔ 카드 수 차원 충돌을 LayoutType 도입으로 해소하고, 3종 배치(나열/
  T모양/3x3)를 정의한다. 단순 enum이 아니라 슬롯·빈 슬롯·드로우→슬롯 매핑·
  카드 수 min/max를 갖는 풍부한 도메인 모델로 진화한다. T모양·3x3은 한 줄 3장
  고정 그리드 위에 의식적 매핑으로 카드를 배치하며 +N 드로우로 하단부 확장
  가능하다. grid3x3에는 드로우 순서 설정 메뉴 자리만 마련(다른 순서는 미구현).
keywords: [layout, spread, domain, slot, draw-order, ia, mobile, draw, naming, conflict-resolution]
---

# 스프레드 → 배치 재설계: LayoutType 도입, 슬롯·드로우 매핑, 모양 그룹

## Intent

현재 홈 패널의 "스프레드"(1장/3장/자유) 와 "카드 수"(1~10) 가 같은 차원("몇 장
뽑을지")을 통제하면서 의미적으로 충돌한다. 사용자가 "스프레드: 3장 + 카드 수: 5"
같은 비정합 조합을 만들 수 있고, 코드에서는 어느 한쪽이 강제하거나 무시된다.

이 충돌의 근본 원인은 **"스프레드"라는 용어가 본래 의미인 "카드의 배치 모양"을
잃고 "수량 묶음"이 되어 카드 수와 차원 중첩이 일어났기 때문**이다.

해결: 용어를 "**배치**"로 교체하고 의미를 본래의 "배치 모양" 차원으로 좁힌다.
배치 종류 3가지(나열 / T모양 / 3x3) 를 정의하되 단순 enum이 아니라 다음 도메인
개념을 함께 가지는 **풍부한 모델**로 만든다:

| 새 도메인 개념 | 의미 |
|--------------|------|
| 슬롯(slot) | 그리드 상의 카드 자리 (T모양: 6 슬롯, 3x3: 9 슬롯, 추가 시 하단 확장) |
| 빈 슬롯(empty slot) | T모양 기본 4장 시 자리 4·6은 영구 빈칸 (visible placeholder) |
| 드로우 순서 → 슬롯 매핑 | "n번째 뽑힌 카드를 어느 슬롯에 놓을지" 함수. 배치 종류별로 다름 |
| cardCount min/max | 배치별로 동적 (linear 1~10, tShape 4~10, grid3x3 9~10) |
| 한 줄 카드 수 강제 | T모양·3x3은 cardsPerRow=3 고정 |

배치가 선행 선택이 되어 카드 수와 한 줄 카드 수의 가능 범위·매핑을 결정하는
단방향 의존 관계로 정리한다. grid3x3에는 "드로우 순서" 설정 자리만 마련하되
다른 순서 옵션은 미구현 보류한다.

## Context

### 현재 구조의 충돌 지점

| 설정 | 통제 차원 | 충돌 |
|------|----------|------|
| 카드 수 (1~10 스텝퍼) | 수량 | ↔ 스프레드 |
| 스프레드 (single/threeCard/custom) | 수량 + 위치 의미 | ↔ 카드 수 |
| 한 줄 카드 수 (1/2/3) | 표시 그리드 분할 | 스프레드 종류와 무관하게 항상 활성 |

`SpreadType.single.cardCount = 1`, `SpreadType.threeCard.cardCount = 3` 인데
별도 `defaultCardCount` 슬라이더가 1~10 임. 충돌 시 어느 것이 우선인지 코드에
명시 없음.

### SpreadType 참조 분포 (코드베이스 grep 결과)

| 레이어 | 파일 | 역할 |
|--------|------|------|
| 도메인 모델 | `mobile/lib/features/reading/domain/entities/spread_type.dart` | enum 정의 → 풍부한 모델로 진화 |
| DB 스키마 | `mobile/lib/core/database/tables/readings_table.dart` | `spreadType` TextColumn |
| DB 스키마 | `mobile/lib/core/database/tables/user_settings_table.dart` | `defaultSpreadType` TextColumn |
| DAO | `mobile/lib/core/database/daos/reading_dao.dart` | `watchReadingsBySpreadType` |
| Repository | `mobile/lib/features/reading/data/repositories/reading_repository_impl.dart` | `.name` 직렬화 / `byName` 역직렬화 |
| Entity (freezed) | `mobile/lib/features/reading/domain/entities/reading.dart` (+ .freezed.dart) | `spreadType` 필드 |
| Provider | `mobile/lib/features/reading/presentation/providers/reading_providers.dart` | 필터 프로바이더 |
| UI 결과 | `mobile/lib/features/reading/presentation/widgets/spread_layout.dart` | switch 렌더링 → 슬롯 모델 기반 재작성 |
| UI 목록 | `mobile/lib/features/reading/presentation/pages/reading_list_page.dart` | 필터 칩, 아이콘 |
| UI 상세 | `mobile/lib/features/reading/presentation/pages/reading_detail_page.dart` | `resolvePositions` 호출 |
| UI 설정 | `mobile/lib/features/home/presentation/pages/home_page.dart` | `_DrawSettingsPanel` 모양 그룹 + 드로우 순서 메뉴 |

→ 다중 모듈 변경 + DB 스키마 영향 + 도메인 모델 진화 + 새 결과 렌더링 → **complexity: complex**

### 출시 단계 가정

`pubspec.yaml` v0.1.1, profile에 placeholder "탐험가" — 출시 전 단계로 판단.
기존 사용자 reading 데이터는 마이그레이션 부담이 낮음 (개발 데이터만 존재).

### 슬롯·드로우 매핑 시각화 (사용자 명시)

**T모양 (4장 기본, 한 줄 3장 그리드)**:
```
자리:    1   2   3      드로우:    [1]  [2]  [3]
         _   5   _                  [_]  [4]  [_]
                              ↓ +N (자리 7~ 단순 좌→우)
         7   8   9                  [5]  [6]  [7]
        10  11  12                  [8]  [9]  [10]
```
- 드로우 1→자리 1, 드로우 2→자리 2, 드로우 3→자리 3, 드로우 4→자리 5 (자리 4·6 빈)
- 드로우 5+ → 자리 7부터 좌→우 단순 순서

**3x3 (9장 기본, 한 줄 3장 그리드, 좌→우→가운데 기둥별 아래→위 의식적 매핑)**:
```
자리:    1   2   3      드로우:    [3]  [9]  [6]
         4   5   6                  [2]  [8]  [5]
         7   8   9                  [1]  [7]  [4]
                              ↓ +1~ (자리 10~ 단순 좌→우)
        10  11  12                  [10] [11] [12]
```
- 드로우 1→자리 7, 드로우 2→자리 4, 드로우 3→자리 1 (좌측 기둥)
- 드로우 4→자리 9, 드로우 5→자리 6, 드로우 6→자리 3 (우측 기둥)
- 드로우 7→자리 8, 드로우 8→자리 5, 드로우 9→자리 2 (가운데 기둥)
- 드로우 10+ → 자리 10부터 좌→우 단순 순서

이 의식적 매핑은 카발라/타로 트리 오브 라이프의 "세 기둥(자비·균형·엄격)" 채움
패턴과 결이 통한다. 좌측 기둥(아래→위) → 우측 기둥(아래→위) → 중심 기둥(아래→위).

## Boundaries

### In Scope

| # | Item | Description |
|---|------|-------------|
| 1 | **도메인 모델 진화** | `SpreadType` enum → `LayoutType` 풍부 모델. enhanced enum으로 다음 computed properties 부여: `cardCountMin/Max`, `defaultCardCount`, `cardsPerRowOverride` (nullable), `slotCount(int cardCount)`, `emptySlots(int cardCount)`, `drawToSlot(int drawIndex, int cardCount)` |
| 2 | **3가지 배치 종류 + 제약 매트릭스** | linear (1~10장 가변, cardsPerRow 가변, 빈 슬롯 없음, 매핑은 idential) / tShape (4~10장, cardsPerRow=3 강제, 4장 기본 시 빈 슬롯 {4,6}, 매핑은 위 시각화) / grid3x3 (9~10장, cardsPerRow=3 강제, 빈 슬롯 없음, 매핑은 좌→우→중앙 기둥 의식적 패턴) |
| 3 | **DB 스키마/마이그레이션** | `readings.spreadType`, `user_settings.defaultSpreadType` TextColumn 값 마이그레이션. Drift schema version bump + migration 함수. 기존 값 매핑: `single`→`linear`+cardCount=1, `threeCard`→`linear`+cardCount=3, `custom`→`linear`+cardCount=가변 |
| 4 | **홈 패널 "모양" 그룹 신설** | (a) "기본 설정" = 덱·레벨·역방향 (3행), (b) "모양" = 배치·카드 수·한 줄 카드 수·(3x3 선택 시) 드로우 순서 (3~4행), (c) "표시 옵션" = 앞면·카드 이름·카드 크기 (3행). 한 줄 카드 수가 표시 옵션에서 모양 그룹으로 이동 |
| 5 | **배치 선행 선택 + 동적 슬라이더 제약** | "모양" 그룹 첫 행이 배치. 배치 변경 시 cardCount 슬라이더의 min/max가 즉시 변경됨 (linear: 1-10, tShape: 4-10, grid3x3: 9-10). 현재 값이 새 범위 밖이면 기본값으로 강제. cardsPerRow는 tShape/grid3x3에서 3 고정 + 비활성. 모든 비활성 항목은 회색 표시 |
| 6 | **결과 페이지 슬롯 기반 렌더링** | `spread_layout.dart` 전면 재작성. 한 줄 3장 고정 그리드 위에 슬롯 인덱스로 카드 배치. 빈 슬롯은 점선/회색 placeholder. 드로우→슬롯 매핑은 LayoutType의 `drawToSlot` 호출. linear는 cardsPerRow에 따라 N열, tShape/grid3x3은 항상 3열 |
| 7 | **목록/상세 페이지 호환** | `reading_list_page.dart`의 필터 칩 + `_spreadTypeIcon`을 `linear`/`tShape`/`grid3x3` 으로 갱신. `reading_detail_page.dart`의 `resolvePositions` 호출 호환 확인 |
| 8 | **3x3 드로우 순서 설정 메뉴 (자리만)** | "모양" 그룹에 grid3x3 선택 시에만 표시되는 행 추가. 옵션: "기본 (좌→우→중앙 의식적 패턴)" 단일 활성 + "다른 순서 (준비 중)" 비활성/회색. 미구현 라벨 명시. 선택해도 동작 변화 없음 |
| 9 | **+N 드로우 정책: cardCount 슬라이더로 통합** | 별도 "+1 카드 추가" 인터랙션을 만들지 않고, 모양 그룹의 cardCount 슬라이더로 통합. 사용자가 슬라이더로 (예: tShape 7장) 설정하면 셔플·드로우·결과 모두 7장으로 처리. 결과 페이지에서 별도 +1 버튼 없음 |

### Out of Scope

| # | Item | Reason |
|---|------|--------|
| 1 | T모양·3x3의 위치별 의미(positions) 한국어 카피 | 도메인 합의 별도 필요. 일단 generic 라벨 (`'카드 1'` ...) 사용 |
| 2 | 추가 배치 종류 (켈틱 크로스, 호스슈, 관계 스프레드 등) | 이번 사이클은 3종까지. 정통 타로 스프레드는 위치·시각 모두 별도 설계 |
| 3 | 사용자 커스텀 배치 (자유 위치 지정) | 스코프 외 |
| 4 | positions 기반 해석 가이드(guidances) 변경 | 콘텐츠 작업 (tarot-expert 영역) |
| 5 | 셔플 단계 UI 변경 | 셔플 화면은 그대로. 모양은 결과 페이지부터 적용 |
| 6 | reading 마이그레이션 시 위치 의미 보존 | 기존 `threeCard`의 위치 의미는 손실됨 (도메인 의미 변경) |
| 7 | **3x3 "다른 드로우 순서" 옵션 자체 구현** | UI 자리(비활성 라벨)만 노출. 다른 패턴(예: 좌→상→우 시계방향, 중심→외곽 등) 정의·구현은 별도 사이클 |
| 8 | **T모양 드로우 순서 변경 메뉴** | 사용자는 3x3에 대해서만 메뉴 추가 요청. T모양은 단일 매핑 고정 |
| 9 | **+N 드로우의 별도 인터랙션 UX** (결과 페이지 +1 버튼 등) | cardCount 슬라이더로 통합 (Decision 9). 별도 결과 페이지 인터랙션은 별도 사이클 |
| 10 | **+N 추가 슬롯의 의식적 매핑** | grid3x3 자리 10+ 는 단순 좌→우. 의식적 패턴(예: 4행도 기둥 채움) 적용은 별도 사이클 |

## Decisions

| # | Decision | Chosen | Rationale | Trade-off | Alternatives Considered |
|---|----------|--------|-----------|-----------|------------------------|
| 1 | "단순 나열"의 한글 라벨 | **"나열"** | 한 단어로 짧고 직관적. cardsPerRow와 결합하여 한 줄/여러 줄 모두 포함 가능 | 약간 무미건조 — 도메인의 시적 분위기와 결이 약함 | (a) "흐름" — 시간 순서 함의 강제. (b) "기본"/"표준" — 의미 약함. (c) "일렬" — cardsPerRow≥2일 때 모순. (d) "자유" — custom과 혼동 |
| 2 | enum 영문명 | **`LayoutType`** | Dart 표준 컨벤션. "Layout"은 Flutter 생태계 표준어 | UI 위젯 용어와 약간 겹침 | (a) `ArrangementType` 길음. (b) `BatchiType` 콩글리시. (c) `SpreadType` 유지 — 라벨/필드/문서 충돌 |
| 3 | enum value 영문명 | **`linear`, `tShape`, `grid3x3`** | linear는 줄 의미, tShape는 형태 직접, grid3x3은 크기 명세 | grid3x3은 숫자 포함으로 다소 기계적 | (a) `simple/tCross/grid` — grid 단독 모호. (b) `linear/cross/mandala` — mandala는 원형 함의. (c) `oneRow/...` — cardsPerRow≥2 시 모순 |
| 4 | 배치 변경 시 cardCount/cardsPerRow 처리 | **즉시 강제 조정 + 제약된 항목 비활성(회색)** | 가능 영역을 시각으로 보여주는 게 가장 명확. 비정합 시도 자체 차단 | 이전 카드 수 값 손실 (예: linear 7장 → grid3x3 → linear 복귀 시 9장 유지) | (a) 토스트 경고만 — 마찰 큼. (b) 비활성 없이 자동만 — 왜 슬라이더가 안 움직이는지 사용자 모름. (c) 배치별 cardCount 메모리 — UserSettings 복잡도 ↑, YAGNI |
| 5 | DB 마이그레이션 정책 | **Drift schema version bump + migration 함수 작성** ⚠️ | 출시 전이지만 마이그레이션 패턴은 영구 자산. v1→v2 사례를 정확히 정립 | migration 함수 작성·테스트 부담. positions 의미 손실 | (a) Schema reset — 모든 reading 손실, 출시 후 패턴 굳어지면 위험. (b) 신규 컬럼 + deprecated — 영구 부채 |
| 6 | UserSettings 필드명 | **`defaultSpreadType` → `defaultLayoutType`** | 도메인 용어 통일. enum 이름과 일치 | DB 컬럼명도 변경 → 마이그레이션에 컬럼 rename 추가 | (a) 컬럼 그대로 + Dart 필드만 변경 — 코드/DB 불일치. (b) 모두 그대로 + enum만 변경 — Brief 의도 위배 |
| 7 | T모양 카드 수 정책 | **4장 기본 + 4~10 가변 (cardCount 슬라이더로 +N 가능)** (사용자 직접 결정) | 사용자 표현 "+1 드로우 시 하단부 배치" 가능. T자 4장이 기본 의식적 형태이므로 min=4, 글로벌 max=10 유지로 일관성. 추가 카드는 자리 7+ 단순 좌→우 | tShape의 "T자 의식적 형태"가 +N으로 흐려질 수 있음 (5장 이상은 시각적으로 T+추가 행). 단 사용자가 명시적으로 +1 가능 요청 | (a) 4장 고정 (이전 결정) — 사용자 명시적 변경 요청으로 기각. (b) min=1 가변 — 부분 T자 어색 (사용자 이전에 기각). (c) +N 시 별도 영역에 표시 — 슬롯 모델 복잡 |
| 8 | 위치 의미(positions) 처리 | **generic 라벨 자동 생성 (`'카드 1'`...)** | T/3x3 의미 라벨링은 도메인 합의 필요 (Out of Scope #1) | 위치별 의미 깊이 감소 | (a) 임시 자율 텍스트 — 출시 후 변경 부담. (b) 라벨 숨김 — 정보 부족 |
| 9 | cardCount 슬라이더 max + +N 인터랙션 | **글로벌 max=10 유지, +N 인터랙션은 cardCount 슬라이더로 통합** | 기존 슬라이더 1~10 범위 그대로. 별도 "+1" 버튼·셔플 추가 인터랙션 도입 시 결과 페이지 UX·셔플 재실행·reading 저장 모두 영향 → 큰 별도 사이클. 슬라이더 통합이 단일 진실의 원천 | grid3x3은 +1만 가능 (10장), 비대칭. 단 grid3x3은 9가 의식적 완결이라 부수적 OK | (a) max=12 또는 15로 확장 — 모바일 화면 그리드 길이 부담, 다른 코드 영향. (b) 별도 +1 버튼 — 사이클 폭 폭증, Out of Scope #9 |
| 10 | T모양 슬롯 + 드로우 매핑 | **기본 4장 시 슬롯 [1,2,3,_,4,_], +N은 자리 7+ 단순 좌→우** | 사용자 원문 그대로. 자리 4·6 빈 슬롯은 visible placeholder. 추가 슬롯은 단순 그리드 채움 | 5장 이상에서 T자 의식적 형태가 흐려짐 | (a) +N 슬롯도 빈칸 패턴 — 시각 복잡도 ↑, 사용자 명시 없음. (b) +N은 별도 영역 (T자 옆/아래) — 슬롯 모델 비통일 |
| 11 | grid3x3 슬롯 + 드로우 매핑 | **기본 9장 의식적 매핑 (좌→우→중앙 기둥, 각 기둥 아래→위), +1+은 자리 10+ 단순 좌→우** ⚠️ | 사용자가 명시한 9장 의식적 패턴은 트리 오브 라이프 / 카발라 세 기둥 채움과 결이 통함. 추가 카드 매핑은 사용자 미명시 → 단순 좌→우 (T모양 +N과 일관) | 기본 9장 패턴과 +1 패턴이 의식적 일관성 결여 (기본은 의식적, 추가는 단순) | (a) +1도 4행 기둥 패턴 (자리 10→11→12 순) — "기둥별 아래→위"는 4행이 1행 추가라 무의미, 의식적 의미 없음. (b) +1을 별도 영역 — 슬롯 모델 비통일 |
| 12 | 3x3 드로우 순서 설정 메뉴 | **메뉴 자리 추가 + "기본" 활성, "다른 순서 (준비 중)" 비활성** | 사용자가 명시적 요청. 향후 다른 패턴(시계방향·나선·중심→외곽 등) 추가 자리 미리 마련 | UI에 미구현 라벨 노출 = 약간의 기대 불일치 ("준비 중" 명시로 완화) | (a) 메뉴 안 만들고 기본만 — 사용자 요청 위배. (b) 다른 순서 옵션 즉시 구현 — Out of Scope #7 위배, 별도 사이클 폭 |
| 13 | 도메인 모델 진화 형태 | **enhanced enum + computed properties** ⚠️ | Dart 2.17+ enhanced enum이 enum 값별 다른 메서드 구현을 지원. `LayoutType.tShape.drawToSlot(0, 4) == 0` 같은 깔끔한 호출. freezed/Drift는 `.name` 직렬화이므로 풍부 모델이어도 호환 | enum 값별 메서드는 정적 분석이 약간 복잡. 테스트 케이스 다수 필요 | (a) 별도 `LayoutDefinition` 클래스 + LayoutType enum이 factory — 추상화 층 추가, 호출부 verbose. (b) 단순 enum + 외부 함수 — 도메인 결합 약화 |

## ⚠️ Critical Review Request

세 건의 결정이 영구 부채/도메인 정합성에 영향을 미칩니다:

1. **⚠️ Decision 5 — DB 마이그레이션**:
   - **Risk**: Drift migration 함수 잘못 작성 시 reading/user_settings 레코드 손상 또는 첫 실행 crash. 출시 전이라 즉시 영향은 개발자 데이터 한정이지만 마이그레이션 패턴은 영구 자산
   - **여전히 최선인 이유**: Schema reset은 출시 후 매 schema 변경마다 사용자 신뢰 손상 누적. v1→v2가 첫 사례라면 패턴 정립이 미래 비용 절감
   - **→ makeplan/impl에서 (a) 트랜잭션 보장, (b) 마이그레이션 실패 롤백, (c) v1 fixture → v2 변환 단위 테스트 필수 포함 심층검토를 요청합니다**

2. **⚠️ Decision 11 — grid3x3의 +1 매핑 일관성 결여**:
   - **Risk**: 기본 9장은 의식적 매핑 (좌→우→중앙 기둥별 아래→위) 인데 자리 10+ 추가 매핑은 단순 좌→우 (의식 약화). 사용자가 +1 매핑을 명시하지 않았기에 자율 결정했지만 도메인 의도와 어긋날 가능성
   - **여전히 최선인 이유**: 4행은 1행 추가라 "기둥별 아래→위" 자체가 무의미 (각 열에 한 칸씩만). 의식적 패턴을 강제 적용하면 인위적 의미 부여
   - **Alternative**: grid3x3 자체에서 +N 비허용 (max=9 강제) → 별도 결정 #9의 글로벌 max=10 정책과 비대칭 + 사용자 표현 "T, 3x3 모양에서도 +1 장 드로우"와 충돌
   - **→ 사용자에게 grid3x3 +1 매핑 의도가 단순 좌→우인지, +1 자체를 비허용해야 하는지 심층검토를 요청합니다**

3. **⚠️ Decision 13 — 도메인 모델이 enum + computed properties**:
   - **Risk**: enhanced enum의 값별 메서드 구현은 freezed `@JsonKey` / Drift `TypeConverter` 와 미묘한 상호작용 가능성. 특히 `drawToSlot(int, int)` 같은 함수가 enum value별로 다르면 codegen 동작이 예측 어려움
   - **여전히 최선인 이유**: 별도 클래스 분리는 추상화 층 추가 + 호출부 verbose ↑. enhanced enum은 Dart 표준 패턴
   - **→ makeplan에서 enum + computed properties 형태가 freezed/Drift codegen과 충돌하지 않는지 prototype 검증을 요청합니다 (충돌 시 Decision 13의 alternative (a) 별도 클래스로 fallback)**

## Open Questions

| # | Question | Impact | Status |
|---|----------|--------|--------|
| (없음) | 모든 결정이 자율 결정 + Critical Review 3건으로 처리됨 | — | — |

## Constraints

- **출시 전 가정** (v0.1.1): 사용자 데이터는 개발자 테스트 한정. 단, 마이그레이션 패턴·도메인 모델은 영구 자산
- **Drift codegen 필수**: schema 변경 시 `dart run build_runner build --delete-conflicting-outputs`
- **Freezed codegen 필수**: Reading entity 필드 타입 변경 시 동일 명령
- **Enhanced enum 사용 검증**: Dart 2.17+ 필요 (확인). enum + computed properties + freezed/Drift 호환성 prototype 필수 (Critical Review 3)
- **컴포넌트 재사용 원칙**: 005 신규 위젯은 (a) 슬롯 placeholder, (b) 드로우 순서 메뉴 행, (c) 비활성 슬라이더에 한정. 002~004의 `_PanelSubheader`, `_GoldSwitch`, `_PillSelector` 등 재사용
- **빌드 검증 필수**: `cd mobile && flutter build apk --debug`
- **시각 검증 필수 (5종)**: ADB 스크린샷으로 (a) 모양 그룹 UI (배치 + 카드 수 + 한 줄 카드 수 + grid3x3 시 드로우 순서), (b) tShape 결과 페이지 (4장 + 빈 슬롯 placeholder), (c) tShape 결과 페이지 (+N, 예: 7장), (d) grid3x3 결과 페이지 (9장 의식적 매핑), (e) 배치 변경 시 cardCount min/max 변경 + 비활성
- **테스트 필수 (3종)**:
  - Drift migration 단위 테스트 (v1 fixture → v2 변환)
  - LayoutType enum 매핑 테스트 (각 배치별 `drawToSlot`, `emptySlots`, `slotCount` 검증)
  - cardCount 자동 조정 테스트 (배치 전환 시 min/max 강제)

## Exit Criteria

- [x] SpreadType ↔ 카드 수 충돌의 본질 명시
- [x] LayoutType 도메인 모델 결정 (enhanced enum + computed properties)
- [x] 3종 배치별 제약 매트릭스 (cardCount min/max, cardsPerRow, 빈 슬롯, 드로우 매핑)
- [x] +N 정책 (cardCount 슬라이더 통합)
- [x] 슬롯·드로우 매핑 시각화 (T모양·3x3 기본 + +N)
- [x] 3x3 드로우 순서 메뉴 정책 (기본 활성 + 다른 순서 비활성)
- [x] UI 그룹 재구성 안 (모양 그룹 신설, grid3x3 시 4행)
- [x] DB 마이그레이션 정책 (Critical Review 1)
- [x] In Scope 9개 / Out of Scope 10개 / Decisions 13개 명세
- [x] Critical Review 3건 명시
- [ ] Quality Profile 확정 (Step 5b)
- [ ] Ideal Criteria 작성 완료 (Step 5b)

## Ideal Criteria

Quality Profile: **standard** (기본값 — Step 5b에서 사용자 응답에 따라 조정)
Priority Dimensions: 미정 (Step 5b)

| # | Criterion | References (In Scope #) | Type | Dimension |
|---|-----------|------------------------|------|-----------|
| (Step 5b 완료 후 채워짐) | | | | |

## Model Anchors

- **용어 통일 원칙**: 사용자 라벨은 모두 "**배치**" (스프레드 금지). 코드/타입/필드/DB 컬럼명은 모두 "**Layout**" 계열. 한국어 라벨은 "배치", "나열", "T모양", "3x3"만 사용
- **차원 분리 원칙**: 배치(LayoutType)는 **모양** 차원, 카드 수는 **수량** 차원. 단방향 의존 (배치 → 수량 제약). 카드 수가 배치를 결정하지 않음
- **선행 선택 원칙**: "모양" 그룹 첫 행은 항상 **배치**. 배치가 cardCount 슬라이더 min/max 및 cardsPerRow 활성화 여부를 결정하는 게이트
- **자동 조정 원칙**: 배치 변경 시 cardCount는 새 min/max 범위로 강제 (현재 값이 범위 밖이면 defaultCardCount로 리셋), cardsPerRow는 강제 적용. 이전 값 보존 안 함. 비활성 항목은 회색 표시
- **3종 배치 풍부 모델 매트릭스**:
  | 배치 | cardCount min | cardCount max | defaultCardCount | cardsPerRow | 기본 빈 슬롯 (cardCount=min 시) | 기본 드로우 매핑 |
  |------|--------------|--------------|------------------|------------|------------------------------|---------------|
  | linear | 1 | 10 | 3 | 1~3 가변 | 없음 | identical (drawN→slotN) |
  | tShape | 4 | 10 | 4 | 3 강제 | {3, 5} (0-indexed: 자리 4·6) | {0→0, 1→1, 2→2, 3→4} + (n≥4: drawN→slot(n+2)) |
  | grid3x3 | 9 | 10 | 9 | 3 강제 | 없음 | {0→6, 1→3, 2→0, 3→8, 4→5, 5→2, 6→7, 7→4, 8→1} + (n=9: draw9→slot9) |
  ※ slot 인덱스는 0-based. 1-based로 표기한 사용자 원문과 매핑 일치 (자리 1 = slot 0)
- **그룹 구조 재배치**: (a) 기본 설정 = 덱·레벨·역방향 (3행), (b) 모양 = 배치·카드 수·한 줄 카드 수·(grid3x3 시) 드로우 순서 (3 또는 4행, 동적), (c) 표시 옵션 = 앞면·카드 이름·카드 크기 (3행)
- **드로우 순서 메뉴 정책**: grid3x3 선택 시에만 모양 그룹 마지막 행으로 추가. `_PillSelector` 사용. "기본" 활성 + "다른 순서 (준비 중)" 비활성. 비활성 옵션 탭 시 토스트 안내 ("아직 준비 중입니다") 또는 무반응
- **+N 인터랙션 정책**: cardCount 슬라이더로 통합. 별도 "+1 카드 추가" 버튼/제스처 미도입. 셔플 단계는 cardCount만큼 미리 셔플하므로 슬라이더 변경 시 새 셔플 트리거. 결과 페이지에서 카드 추가 인터랙션 없음
- **DB 마이그레이션 정책**: Drift schema v1 → v2. migration 함수에서 `single` → `linear`+cardCount=1, `threeCard` → `linear`+cardCount=3, `custom` → `linear`+cardCount은 reading의 경우 drawnCards.length로 추정. 트랜잭션 보장 + 단위 테스트 필수 (Critical Review 1)
- **위치 의미 정책**: T모양/3x3 positions는 generic 라벨 (`'카드 1'`...) 자동 생성. 의미 라벨링은 별도 콘텐츠 작업
- **결과 페이지 렌더링 전략**:
  - linear: 기존 generic grid (cardsPerRow 적용, 빈 슬롯 없음)
  - tShape: 한 줄 3장 그리드, `LayoutType.tShape.emptySlots(cardCount)` 가 반환하는 인덱스에는 visible placeholder (점선 회색 사각형) 표시
  - grid3x3: 한 줄 3장 그리드, `LayoutType.grid3x3.drawToSlot(drawIdx, cardCount)` 로 슬롯 배치 (의식적 매핑)
  - 모든 배치는 `slotCount(cardCount) = ceil(cardCount + emptySlots.length / 3) * 3` 로 그리드 행 수 결정
- **빈 슬롯 placeholder 디자인**: 점선 사각형 + 회색 (kSoftPurple alpha 0.2) + 카드와 동일 aspectRatio. 탭 비활성. "빈 자리" 라벨 등 텍스트 없음 (시각만으로 의미 전달)
- **시각 검증 5종 필수**: (a) 모양 그룹 UI (grid3x3 선택 시 4행), (b) tShape 결과 4장 (빈 슬롯 2개 보임), (c) tShape 결과 7장 (+N), (d) grid3x3 결과 9장 (의식적 매핑 좌→우→중앙), (e) 배치 변경 시 cardCount 슬라이더 동적 min/max + 비활성
- **테스트 3종 필수**: Drift migration 단위 테스트, LayoutType `drawToSlot`/`emptySlots`/`slotCount` 단위 테스트, cardCount 자동 조정 단위 테스트

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
