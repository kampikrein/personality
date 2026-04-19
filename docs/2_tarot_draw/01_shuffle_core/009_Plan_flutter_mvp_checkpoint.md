---
id: "009"
type: plan
title: "타로 셔플 앱 Flutter MVP 구현 플랜"
created: 2026-03-15
status: completed
phases: ["010", "011", "012"]
summary: >
  Flutter 타로 셔플 앱 Android MVP 구현. 리플 셔플 1종 + RWS 78장 기본 덱 +
  1장/3장 스프레드 + 센서 엔트로피 + Drift 오프라인 DB. 순수 Flutter(Flame 제외),
  Riverpod-only DI로 최소 복잡도 MVP.
keywords: [flutter, tarot, shuffle, mvp, riffle, drift, riverpod, sensor-entropy]
phase_plan:
  total_phases: 3
  phases:
    - phase: 1
      title: "프로젝트 기반 + 데이터 계층"
      depends_on: []
      parallel_with: []
      status: completed
      number: "010"
    - phase: 2
      title: "셔플 엔진 + 엔트로피 코어"
      depends_on: ["010"]
      parallel_with: []
      status: completed
      number: "011"
    - phase: 3
      title: "프레젠테이션 + 라우팅 통합"
      depends_on: ["010", "011"]
      parallel_with: []
      status: completed
      number: "012"
structural_decisions:
  - decision: "MVP 셔플 범위"
    chosen: "리플 1종만"
    rationale: "Research(008) 권장. 순수 Flutter로 핵심 가설(센서→셔플) 검증. Flame 의존성 제거로 복잡도 최소화. 오버핸드/워시는 Phase 2."
  - decision: "DI 프레임워크"
    chosen: "Riverpod-only"
    rationale: "get_it+injectable 제거. Riverpod 3.0이 DI 컨테이너 역할 수행. 코드 생성 도구 4→3개로 감소. 상태 관리+DI 통합."
  - decision: "스프레드 범위"
    chosen: "1장 + 3장"
    rationale: "핵심 흐름(셔플→드로우→배치→해석) 검증에 충분. 켈틱 크로스(10장)는 Phase 2."
traces_scope: "001"
traces_research: "008"
auto_run: true
---

# 타로 셔플 앱 Flutter MVP 구현 플랜

## Goal

PRD의 핵심 가설 — "사용자의 물리적 상호작용이 셔플 결과에 반영되는 제의적 경험" — 을 Android MVP로 검증한다. 리플 셔플 1종 + RWS 기본 덱 78장 + 1장/3장 스프레드로 최소 기능 제품을 구현하여 핵심 UX 흐름을 확인한다.

## Scope

### Included
| # | Item | Description |
|---|------|-------------|
| 1 | Flutter 프로젝트 초기화 | Android/iOS 플랫폼 파일 생성, 의존성 설정 |
| 2 | Drift 로컬 DB | 덱/카드/리딩 테이블, DAO, 마이그레이션 |
| 3 | freezed 도메인 모델 | DeckMetadata, TarotCard, CardMeanings, Reading, SpreadType |
| 4 | RWS 78장 시드 데이터 | JSON 형태 카드 메타데이터 (이미지는 placeholder) |
| 5 | 센서 엔트로피 시스템 | sensors_plus → SHA-256 풀 → FortunaRandom |
| 6 | 리플 셔플 전략 | ShuffleStrategy 인터페이스 + RiffleShuffleStrategy |
| 7 | 카드 렌더링 | CustomPainter + Ticker 게임 루프 (위젯 트리 스킵) |
| 8 | 스프레드 레이아웃 | 1장(단일 카드), 3장(과거-현재-미래) |
| 9 | Riverpod 상태 관리 | 앱 상태 전체를 @riverpod 코드 생성으로 관리 |
| 10 | go_router 라우팅 | 홈 → 덱 선택 → 셔플 → 리딩 화면 전환 |
| 11 | 다크 테마 | 타로 앱에 적합한 미스틱 다크 테마 |

### Excluded
| Item | Reason/Timeline |
|------|-----------------|
| 오버핸드/워시 셔플 | Phase 2 — Flame+Forge2D와 함께 도입 |
| 켈틱 크로스 스프레드 | Phase 2 — 10장 배치 복잡도 높음 |
| 커스텀 덱 등록/업로드 | Phase 2 |
| 서버 동기화 (Rails API) | Phase 3 |
| iOS/Web 빌드 | Phase 3-4 |
| 커뮤니티/바운티 시스템 | Phase 4 |
| 실제 RWS 카드 이미지 | 저작권 확인 후 별도 진행. MVP는 placeholder |

## Structural Decisions

| # | Decision | Chosen Option | Rationale |
|---|----------|---------------|-----------|
| 1 | MVP 셔플 범위 | 리플 1종 | Research(008) 권장. Flame 없이 순수 Flutter로 핵심 가설 검증 |
| 2 | DI 프레임워크 | Riverpod-only | get_it+injectable 제거. 코드 생성 도구 감소, 상태 관리와 DI 통합 |
| 3 | 스프레드 범위 | 1장 + 3장 | 핵심 UX 흐름 검증에 충분. 켈틱 크로스는 Phase 2 |
| 4 | 상태 관리 이원화 | Riverpod(앱) + Ticker/CustomPainter(애니메이션) | R-008-F1: 78장 60fps 필수 조건 |
| 5 | 카드 이미지 | Placeholder (색상+텍스트) | 저작권 미확인. MVP 기능 검증에 이미지 불필요 |

## Investigation Results

### 현재 코드베이스 상태
- `mobile/pubspec.yaml`: Flutter SDK만 의존. 빈 스켈레톤.
- `mobile/lib/main.dart`: 빈 MaterialApp (PersonalityApp)
- `mobile/.gitignore`: 표준 Flutter gitignore
- **플랫폼 디렉토리 미생성**: android/, ios/ 없음 → `flutter create` 필요
- `app/assets/builds/tailwind.css`: 웹용 CSS (본 플랜 범위 외)

### Research(008) 핵심 발견 반영
| ID | Finding | 반영 방법 |
|----|---------|----------|
| R-008-F1 | 이원화 상태 관리 | Riverpod(앱) + Ticker/CustomPainter(애니메이션) |
| R-008-F2 | 하이브리드 셔플 엔진 | MVP는 순수 Flutter만 (리플). Strategy 인터페이스로 확장 대비 |
| R-008-F3 | FortunaRandom CSPRNG | PointyCastle + SHA-256 엔트로피 풀 |
| R-008-F4 | Drift DB | 관계형 + JSON1 + 리액티브 스트림 |
| R-008-F5 | 동기화 대비 필드 | syncStatus, version 초기 스키마에 포함 |
| R-008-F6 | Feature-first Hybrid | lib/features/{shuffle,deck,reading}/ 구조 |
| R-008-F7 | 센서 편향 방지 | Random.secure() 혼합, 최소 10샘플 후 셔플 허용 |
| R-008-F8 | 햅틱 쓰로틀링 | 50ms 쓰로틀링 (MVP는 Flutter 내장 HapticFeedback) |

### 통합 기술 스택 (Riverpod-only DI 반영)

```yaml
dependencies:
  flutter:
    sdk: flutter
  # 상태 관리 (앱 + DI)
  flutter_riverpod: ^2.6.0
  riverpod_annotation: ^2.6.0

  # 센서/난수
  sensors_plus: ^5.0.0
  pointycastle: ^3.7.0
  crypto: ^3.0.0

  # 데이터
  drift: ^2.22.0
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.1.0
  freezed_annotation: ^2.4.0
  json_annotation: ^4.9.0

  # 라우팅
  go_router: ^14.6.0

  # 이미지
  flutter_image_compress: ^2.3.0

dev_dependencies:
  build_runner: ^2.4.0
  riverpod_generator: ^2.6.0
  freezed: ^2.5.0
  json_serializable: ^6.8.0
  drift_dev: ^2.22.0

  # 테스트
  mocktail: ^1.0.0

  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
```

## Phase Breakdown

### Phase 1: 프로젝트 기반 + 데이터 계층
- **Scope**: Flutter 프로젝트 초기화, 의존성, Drift DB, freezed 모델, RWS 시드 데이터, 앱 부트스트랩
- **Target files**:
  - `mobile/pubspec.yaml` (modify)
  - `mobile/analysis_options.yaml` (new)
  - `mobile/lib/main.dart` (modify)
  - `mobile/lib/core/error/failures.dart` (new)
  - `mobile/lib/core/theme/app_theme.dart` (new)
  - `mobile/lib/core/database/app_database.dart` (new)
  - `mobile/lib/core/database/tables/decks_table.dart` (new)
  - `mobile/lib/core/database/tables/cards_table.dart` (new)
  - `mobile/lib/core/database/tables/readings_table.dart` (new)
  - `mobile/lib/core/database/daos/deck_dao.dart` (new)
  - `mobile/lib/core/database/daos/card_dao.dart` (new)
  - `mobile/lib/core/database/daos/reading_dao.dart` (new)
  - `mobile/lib/features/deck/domain/entities/deck_metadata.dart` (new)
  - `mobile/lib/features/deck/domain/entities/tarot_card.dart` (new)
  - `mobile/lib/features/deck/domain/entities/card_meanings.dart` (new)
  - `mobile/lib/features/reading/domain/entities/reading.dart` (new)
  - `mobile/lib/features/reading/domain/entities/spread_type.dart` (new)
  - `mobile/assets/data/rws_deck.json` (new)
- **Dependencies**: 없음 (첫 단계)
- **Approach summary**: Flutter 프로젝트를 완전히 초기화하고 Drift DB 스키마 + freezed 도메인 모델을 설정. RWS 78장 카드 시드 데이터를 JSON으로 준비. build_runner로 코드 생성 확인.

### Phase 2: 셔플 엔진 + 엔트로피 코어
- **Scope**: 센서 수집, 엔트로피 풀, CSPRNG, 셔플 전략 인터페이스/구현, 리포지토리 계층
- **Target files**:
  - `mobile/lib/features/shuffle/data/datasources/sensor_data_collector.dart` (new)
  - `mobile/lib/features/shuffle/data/datasources/entropy_pool.dart` (new)
  - `mobile/lib/features/shuffle/data/datasources/fortuna_random_wrapper.dart` (new)
  - `mobile/lib/features/shuffle/domain/entities/shuffle_result.dart` (new)
  - `mobile/lib/features/shuffle/domain/entities/shuffle_config.dart` (new)
  - `mobile/lib/features/shuffle/domain/strategies/shuffle_strategy.dart` (new)
  - `mobile/lib/features/shuffle/domain/strategies/riffle_shuffle_strategy.dart` (new)
  - `mobile/lib/features/shuffle/domain/repositories/shuffle_repository.dart` (new)
  - `mobile/lib/features/shuffle/domain/usecases/shuffle_deck_usecase.dart` (new)
  - `mobile/lib/features/shuffle/data/repositories/shuffle_repository_impl.dart` (new)
  - `mobile/lib/features/deck/domain/repositories/deck_repository.dart` (new)
  - `mobile/lib/features/deck/data/repositories/deck_repository_impl.dart` (new)
  - `mobile/lib/features/reading/domain/repositories/reading_repository.dart` (new)
  - `mobile/lib/features/reading/data/repositories/reading_repository_impl.dart` (new)
- **Dependencies**: Phase 1 (entities, DB)
- **Approach summary**: Research(008)의 하이브리드 엔트로피 모델을 구현. sensors_plus → SHA-256 누적 해시 → Random.secure() 혼합 → FortunaRandom 시드 → Fisher-Yates. ShuffleStrategy 인터페이스로 향후 오버핸드/워시 확장 대비.

### Phase 3: 프레젠테이션 + 라우팅 통합
- **Scope**: 전체 UI 레이어, go_router, Riverpod providers, CardPainter, 스프레드 레이아웃
- **Target files**:
  - `mobile/lib/core/router/app_router.dart` (new)
  - `mobile/lib/features/home/presentation/pages/home_page.dart` (new)
  - `mobile/lib/features/deck/presentation/pages/deck_selection_page.dart` (new)
  - `mobile/lib/features/deck/presentation/providers/deck_providers.dart` (new)
  - `mobile/lib/features/shuffle/presentation/pages/shuffle_page.dart` (new)
  - `mobile/lib/features/shuffle/presentation/widgets/card_painter.dart` (new)
  - `mobile/lib/features/shuffle/presentation/widgets/riffle_animation_controller.dart` (new)
  - `mobile/lib/features/shuffle/presentation/widgets/entropy_progress_indicator.dart` (new)
  - `mobile/lib/features/shuffle/presentation/providers/shuffle_providers.dart` (new)
  - `mobile/lib/features/reading/presentation/pages/reading_page.dart` (new)
  - `mobile/lib/features/reading/presentation/widgets/spread_layout.dart` (new)
  - `mobile/lib/features/reading/presentation/widgets/card_reveal_widget.dart` (new)
  - `mobile/lib/features/reading/presentation/providers/reading_providers.dart` (new)
  - `mobile/lib/main.dart` (modify — 라우터 연결)
- **Dependencies**: Phase 1 + Phase 2
- **Approach summary**: 이원화 상태 관리 패턴 적용. Riverpod providers가 앱 상태(덱 선택, 셔플 전략 등)를, Ticker+CustomPainter가 카드 애니메이션 상태를 관리. CardPainter가 78장 카드를 Canvas에 직접 렌더링. 1장/3장 스프레드 레이아웃으로 리딩 화면 구성.

## File Change Summary (All Phases)

### Modified Files
| # | File Path | Phase | Change Description |
|---|-----------|-------|-------------------|
| 1 | mobile/pubspec.yaml | 1 | 전체 의존성 추가 (Riverpod, Drift, sensors_plus, pointycastle 등) |
| 2 | mobile/lib/main.dart | 1, 3 | Phase 1: ProviderScope 부트스트랩. Phase 3: 라우터 연결 |

### New Files
| # | File Path | Phase | Description |
|---|-----------|-------|-------------|
| 1 | mobile/analysis_options.yaml | 1 | Lint rules |
| 2 | mobile/lib/core/error/failures.dart | 1 | Failure sealed class |
| 3 | mobile/lib/core/theme/app_theme.dart | 1 | 미스틱 다크 테마 |
| 4 | mobile/lib/core/database/app_database.dart | 1 | Drift AppDatabase |
| 5 | mobile/lib/core/database/tables/decks_table.dart | 1 | Decks 테이블 정의 |
| 6 | mobile/lib/core/database/tables/cards_table.dart | 1 | Cards 테이블 정의 |
| 7 | mobile/lib/core/database/tables/readings_table.dart | 1 | Readings 테이블 정의 |
| 8 | mobile/lib/core/database/daos/deck_dao.dart | 1 | Deck DAO |
| 9 | mobile/lib/core/database/daos/card_dao.dart | 1 | Card DAO |
| 10 | mobile/lib/core/database/daos/reading_dao.dart | 1 | Reading DAO |
| 11 | mobile/lib/features/deck/domain/entities/deck_metadata.dart | 1 | DeckMetadata freezed |
| 12 | mobile/lib/features/deck/domain/entities/tarot_card.dart | 1 | TarotCard freezed |
| 13 | mobile/lib/features/deck/domain/entities/card_meanings.dart | 1 | CardMeanings freezed |
| 14 | mobile/lib/features/reading/domain/entities/reading.dart | 1 | Reading freezed |
| 15 | mobile/lib/features/reading/domain/entities/spread_type.dart | 1 | SpreadType enum |
| 16 | mobile/assets/data/rws_deck.json | 1 | RWS 78장 시드 데이터 |
| 17 | mobile/lib/features/shuffle/data/datasources/sensor_data_collector.dart | 2 | 센서 수집기 |
| 18 | mobile/lib/features/shuffle/data/datasources/entropy_pool.dart | 2 | SHA-256 엔트로피 풀 |
| 19 | mobile/lib/features/shuffle/data/datasources/fortuna_random_wrapper.dart | 2 | FortunaRandom→Random 어댑터 |
| 20 | mobile/lib/features/shuffle/domain/entities/shuffle_result.dart | 2 | ShuffleResult freezed |
| 21 | mobile/lib/features/shuffle/domain/entities/shuffle_config.dart | 2 | ShuffleConfig freezed |
| 22 | mobile/lib/features/shuffle/domain/strategies/shuffle_strategy.dart | 2 | Strategy 인터페이스 |
| 23 | mobile/lib/features/shuffle/domain/strategies/riffle_shuffle_strategy.dart | 2 | 리플 셔플 구현 |
| 24 | mobile/lib/features/shuffle/domain/repositories/shuffle_repository.dart | 2 | Repository 인터페이스 |
| 25 | mobile/lib/features/shuffle/domain/usecases/shuffle_deck_usecase.dart | 2 | 셔플 유스케이스 |
| 26 | mobile/lib/features/shuffle/data/repositories/shuffle_repository_impl.dart | 2 | Repository 구현 |
| 27 | mobile/lib/features/deck/domain/repositories/deck_repository.dart | 2 | Deck repository 인터페이스 |
| 28 | mobile/lib/features/deck/data/repositories/deck_repository_impl.dart | 2 | Deck repository 구현 |
| 29 | mobile/lib/features/reading/domain/repositories/reading_repository.dart | 2 | Reading repository 인터페이스 |
| 30 | mobile/lib/features/reading/data/repositories/reading_repository_impl.dart | 2 | Reading repository 구현 |
| 31 | mobile/lib/core/router/app_router.dart | 3 | go_router 설정 |
| 32 | mobile/lib/features/home/presentation/pages/home_page.dart | 3 | 홈 화면 |
| 33 | mobile/lib/features/deck/presentation/pages/deck_selection_page.dart | 3 | 덱 선택 화면 |
| 34 | mobile/lib/features/deck/presentation/providers/deck_providers.dart | 3 | Deck @riverpod providers |
| 35 | mobile/lib/features/shuffle/presentation/pages/shuffle_page.dart | 3 | 셔플 화면 |
| 36 | mobile/lib/features/shuffle/presentation/widgets/card_painter.dart | 3 | CustomPainter 카드 렌더러 |
| 37 | mobile/lib/features/shuffle/presentation/widgets/riffle_animation_controller.dart | 3 | 리플 애니메이션 상태 |
| 38 | mobile/lib/features/shuffle/presentation/widgets/entropy_progress_indicator.dart | 3 | 엔트로피 수집 진행률 |
| 39 | mobile/lib/features/shuffle/presentation/providers/shuffle_providers.dart | 3 | Shuffle @riverpod providers |
| 40 | mobile/lib/features/reading/presentation/pages/reading_page.dart | 3 | 리딩(결과) 화면 |
| 41 | mobile/lib/features/reading/presentation/widgets/spread_layout.dart | 3 | 1장/3장 스프레드 배치 |
| 42 | mobile/lib/features/reading/presentation/widgets/card_reveal_widget.dart | 3 | 카드 뒤집기 애니메이션 |
| 43 | mobile/lib/features/reading/presentation/providers/reading_providers.dart | 3 | Reading @riverpod providers |

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
