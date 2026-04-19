---
id: "mobile-lib-features"
type: explanation
target: "mobile/lib/features/"
layer: folder
version: 1
created: 2026-04-16
updated: 2026-04-16
last_explained_commit: "96a0c15dc43d5af2b98e32fec1f157eeacc1e8df"
---

# mobile/lib/features/ — 해설

## 개요

Flutter 앱의 모든 기능을 피처(feature) 단위로 수직 분리한 최상위 디렉토리다.
각 피처는 `domain / data / presentation` 3계층으로 자기완결적이며,
피처 간 의존은 provider와 도메인 엔티티를 통해서만 이루어진다.

## 역할 (Role)

앱의 모든 화면, 비즈니스 로직, 데이터 접근을 피처별로 캡슐화하여 제공한다.
"홈에서 뽑기 → 셔플 → 결과 저장 → 기록 조회"라는 타로 플로우 전체가
이 디렉토리 안의 8개 피처 협력으로 완성된다.

## 구조 (Structure)

```
mobile/lib/features/
├── home/        홈 화면 — 앱 진입점, 덱 초기화, 경험 레벨 분기
├── deck/        타로 덱 데이터 관리 — TarotCard, DeckMetadata, DeckRepository
├── shuffle/     셔플 엔진 — 센서 엔트로피, FisherYates, Flame 2.5D 물리 시뮬
├── draw/        뽑기 UX 오케스트레이션 — Lv1(즉시) / Lv2(연출) 분기
├── reading/     뽑기 기록 저장·조회 — Reading 엔티티, 목록·상세 화면
├── settings/    사용자 설정 — UserSettings (경험 레벨, 덱, 스프레드, 카드 크기)
├── chat/        채팅 기능 (미구현 placeholder)
└── profile/     유저 메뉴 — 현재 레벨 표시, 설정 진입
```

### 피처별 내부 레이어 구성

| 피처 | domain | data | presentation |
|------|--------|------|--------------|
| home | — | — | `pages/home_page.dart` |
| deck | entities(TarotCard·DeckMetadata·CardMeanings), repositories/DeckRepository | repositories/DeckRepositoryImpl | pages/DeckSelectionPage, providers/deck_providers |
| shuffle | entities(ShuffleResult·ShuffleConfig), strategies(FisherYates), usecases/ShuffleDeckUseCase, repositories/ShuffleRepository | datasources(SensorDataCollector·EntropyPool), repositories/ShuffleRepositoryImpl, services/HapticService | pages(ShufflePage·IntentionPage), game(TarotGame·CardBody·HandAnimation), providers/shuffle_providers, widgets(RiffleAnimationController·EntropyProgressIndicator·CardPainter) |
| draw | — | — | pages(DrawResultPage·AnimatedDrawPage), providers/draw_providers |
| reading | entities(Reading·DrawnCardInfo·SpreadType·ReflectivePrompts), repositories/ReadingRepository | repositories/ReadingRepositoryImpl | pages(ReadingListPage·ReadingDetailPage), providers/reading_providers, widgets(CardRevealWidget·SpreadLayout) |
| settings | entities(UserSettings·CardSizePreset), repositories/UserSettingsRepository | repositories/UserSettingsRepositoryImpl | pages(SettingsPage·CardSizeSettingsPage), providers/settings_providers |
| chat | — | — | `pages/chat_page.dart` (stub) |
| profile | — | — | `pages/profile_page.dart` |

## 동작 흐름 (Flow)

앱 시작부터 리딩 기록 저장까지의 전체 흐름:

1. **앱 진입 (`home`)** — `HomePage.initState`가 `DeckRepository.seedAllDecks()`를 호출하여 DB에 덱 데이터를 초기화한다.
2. **경험 레벨 분기 (`home → shuffle/draw`)** — `UserSettings.experienceLevel`에 따라 4개 경로로 분기된다:
   - Lv1: `/draw/result` → `DrawResultPage` (즉시 셔플 + 결과)
   - Lv2: `/draw/animated` → `AnimatedDrawPage` → `DrawResultPage` (슬라이드 연출 후 상태 인계)
   - Lv3/4: `IntentionPage` → `ShufflePage` (Flame 2D/2.5D 물리 셔플) → `DrawResultPage`
3. **셔플 실행 (`shuffle`)** — `ShuffleDeckUseCase.execute()`가 `SensorDataCollector` + `EntropyPool`의 엔트로피를 소비하여 `FisherYatesShuffleStrategy`로 카드를 섞는다. 결과는 `ShuffleStateProvider`(keepAlive)에 세팅된다.
4. **상태 인계 버스 (`shuffle → draw`)** — `shuffleStateProvider`가 페이지 간 직접 파라미터 전달 없이 셔플 결과를 공유한다. `DrawResultPage.initState`에서 `null` 여부로 자체 셔플(Lv1) / 업스트림 재사용(Lv2~4)을 분기한다.
5. **결과 저장 (`draw → reading`)** — `DrawResultPage._autoSave()`가 `Reading` 엔티티를 생성하고 `ReadingRepository.saveReading()`으로 SQLite에 persist한다.
6. **기록 조회 (`reading`)** — `ReadingListPage`가 `watchReadingsProvider`(Stream)를 구독하여 필터/정렬 후 표시한다.

```
HomePage
  └─ _startDraw(experienceLevel)
       ├─ Lv1 → DrawResultPage (자체 셔플)
       ├─ Lv2 → AnimatedDrawPage ─── shuffleStateProvider ──→ DrawResultPage
       └─ Lv3/4 → IntentionPage → ShufflePage ─── shuffleStateProvider ──→ DrawResultPage
                                                                               └─ _autoSave → ReadingRepository
```

## 의존성 (Dependencies)

| 대상 | 종류 | 역할 |
|------|------|------|
| `flutter_riverpod` / `riverpod_annotation` | external | 전역 상태 관리 (keepAlive/AutoDispose provider) |
| `go_router` | external | 선언적 라우팅 (`/draw/result`, `draw-result` named route 등) |
| `freezed` / `json_serializable` | external | 도메인 엔티티 불변 객체 + JSON 직렬화 코드 생성 |
| `flame` | external | `shuffle/game/` — 2.5D 물리 카드 셔플 시뮬레이션 |
| `sensors_plus` | external | `SensorDataCollector` — 가속도계 데이터 수집 (셔플 엔트로피 소스) |
| `sqflite` | external (추정) | `ReadingRepositoryImpl`, `DeckRepositoryImpl` — 로컬 SQLite 영속화 |
| `uuid` | external | `DrawResultPage._autoSave` — Reading ID 생성 |

## 주의사항 (Caveats)

- **`shuffleStateProvider`는 keepAlive**: 앱 세션 전체에 살아있으므로, 새 뽑기 시작 전 반드시 `.clear()`를 호출해야 이전 결과가 잔류하지 않는다. `DrawResultPage`(자체 셔플 경로)와 `AnimatedDrawPage._startDraw()` 모두 최상단에서 `clear()`를 수행한다.
- **Lv2 경로에서 `pushReplacementNamed`**: `AnimatedDrawPage`는 `DrawResultPage`로 *교체* 이동하므로 뒤로가기 시 홈으로 돌아간다. `pushNamed`를 쓰면 연출 화면이 스택에 남아 중복 렌더가 발생한다.
- **`_reuseUpstreamResult`는 `initState` 단일 지점 평가**: `DrawResultPage`가 rebuild되어도 분기가 재실행되지 않는다. "다시" 버튼 클릭 시 명시적으로 `_reuseUpstreamResult = false`를 세팅해야 강제 재셔플이 동작한다.
- **`chat/` 피처는 미구현**: `ChatPage`는 "준비 중입니다." 텍스트만 렌더하는 stub이다. 라우트는 연결되어 있으나 기능 없음.
- **도메인 계층 부재 피처**: `home/`, `draw/`, `chat/`, `profile/`에는 `domain/`, `data/` 디렉토리가 없다. 이들은 presentation 레이어만으로 구성되어 있으며, 각자가 필요한 로직은 `deck/`, `shuffle/`, `reading/`, `settings/` 피처의 provider를 직접 참조한다.
- **freezed 코드 생성 파일**: `*.freezed.dart`, `*.g.dart`는 `build_runner`로 자동 생성된다. 직접 편집 금지.

## Changelog

### v1 (2026-04-16) — 최초 작성
- 최초 해설 문서 생성. 8개 피처 전체 구조와 타로 뽑기 플로우 분석 수록.
