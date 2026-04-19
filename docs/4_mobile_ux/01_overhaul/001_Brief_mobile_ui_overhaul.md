---
id: "001"
type: brief
title: "Mobile UI 대대적 정리 — 사용자 중심 진입 흐름 재설계"
created: 2026-03-22
status: completed
summary: >
  메인 메뉴 허브 → 3단계 체험 레벨(즉시/간단연출/풀셔플) 선택 → 즉시 뽑기 모드.
  1~10장 자유 선택 + 덱별 고유 뽑기 규칙 + 타로 전통 스프레드 + 한 장 더 뽑기(점진적 추가).
  모든 리딩 자동 저장(DB) + 메모 + 유형 분류. 설정은 UserSettings DB 테이블에 persist.
keywords: [mobile, ui, home, card-draw, settings, reading-history, deck-selection, experience-level, spread-type]
---

# Mobile UI 대대적 정리 — 사용자 중심 진입 흐름 재설계

## Intent

앱을 열었을 때 사용자가 **"이 앱으로 뭘 할 수 있는지"** 즉시 파악하고, 원하는 카드 뽑기를 최소 탭으로 시작할 수 있도록 UI를 재구성한다.

핵심 시나리오:
1. **즉시 뽑기**: 앱 진입 → 설정된 방식(1장/3장/N장, 앞면/뒷면)으로 바로 카드가 뽑힘
2. **설정 변경**: 진입 화면에서 뽑기 유형, 덱 종류, 표시 방식을 변경
3. **리딩 기록**: 매 뽑기마다 자동 저장 + 메모 + 일시 + 유형 분류
4. **기록 열람**: 저장된 리딩 목록을 유형별로 조회

## Context

### 현재 라우트 구조
```
/ (HomePage) → /deck (DeckSelectionPage) → /intention/:deckId → /shuffle/:deckId → /reading/:deckId
```

### 현재 주요 파일
| 파일 | 역할 | 현재 상태 |
|------|------|----------|
| `mobile/lib/core/router/app_router.dart` | GoRouter 정의 | 5개 라우트, 선형 흐름 |
| `mobile/lib/features/home/presentation/pages/home_page.dart` | 홈 화면 | "바로 뽑기" + "셔플 시작" + 최근 리딩 |
| `mobile/lib/features/deck/presentation/pages/deck_selection_page.dart` | 덱 선택 | 리스트 형태, 홈에서 직접 연결 안 됨 |
| `mobile/lib/features/reading/domain/entities/spread_type.dart` | 스프레드 유형 | single, threeCard 2개만 |
| `mobile/lib/features/reading/domain/entities/reading.dart` | 리딩 엔티티 | notes 필드 있으나 UI 없음 |
| `mobile/lib/features/reading/presentation/pages/reading_page.dart` | 리딩 결과 | 카드 공개 → 성찰 → 저장 |
| `mobile/lib/features/shuffle/domain/entities/shuffle_config.dart` | 셔플 설정 | shuffleCount, useReversals만 |

### 현재 동작
- 홈 "바로 뽑기" → 항상 rws-standard 덱, 항상 threeCard 고정
- 홈 "셔플 시작" → rws-standard 셔플 페이지로 이동
- 최근 리딩 목록: spreadType + question + 날짜 표시
- 덱 선택 페이지는 /deck 라우트에 있지만 홈에서 직접 접근 경로 없음

## Boundaries

### In Scope
| # | Item | Description |
|---|------|-------------|
| 1 | 홈 화면 재설계 | "할 수 있는 것" 중심 메인 페이지 |
| 2 | 즉시 뽑기 기능 | 앱 진입 시 설정에 따라 자동 카드 뽑기 |
| 3 | 뽑기 유형 설정 | 1장 / 3장 / N장 선택 |
| 4 | 카드 표시 방식 설정 | 앞면/뒷면 초기 표시 선택 |
| 5 | 덱 종류 선택 | 사용할 카드 덱 변경 |
| 6 | 리딩 저장 | 매 뽑기 자동 저장 (카드, 일시, 유형) |
| 7 | 리딩 메모 | 저장된 리딩에 메모 추가/편집 |
| 8 | 리딩 목록 | 유형별 분류·조회 |
| 9 | 설정 메뉴 | 진입 화면에서 설정 변경 접근 |
| 10 | 한 장 더 뽑기 | 리딩 결과 화면에서 "+1" 버튼으로 카드를 1장씩 추가. 3장→4장→5장… 점진적 확장 |

### Out of Scope
| # | Item | Reason |
|---|------|--------|
| 1 | 셔플 애니메이션 개선 | 기존 Flame 물리엔진 셔플은 별도 주제 (docs/11_tarot_shuffle/). Level 3에서 기존 셔플을 연결만 함 |
| 2 | 서버 동기화 구현 | DB 구조만 대비, 실제 sync 로직은 미래 과제 |
| 3 | 스프레드 콘텐츠 설계 | 켈틱 크로스 등의 positions/guidances 내용은 타로 전문가 영역. UI 틀만 준비 |
| 4 | 카드 해석 콘텐츠 | 타로 전문 에이전트 영역 |
| 5 | I Ching 6효 뽑기 로직 구현 | 도메인 전문가 영역. 덱 메타데이터에 뽑기 유형을 명시하는 구조만 준비 |

## Decisions

| # | Decision | Chosen | Rationale |
|---|----------|--------|-----------|
| 1 | 즉시 뽑기 방식 | 다단계 체험 레벨 — 사용자가 뽑기 체험 수준을 여러 개 중 선택해 설정, 이후 진입 시 해당 수준으로 자동 실행 | 사용자마다 원하는 의식적 몰입도가 다름. 한 번 설정하면 매번 선택할 필요 없이 자동 적용 |
| 2 | 뽑기 카드 수 | 1~10장 자유 선택 + 대체 카드 뽑기 방식(I Ching 등 덱별 고유 방식) 준용 | 유연한 커스텀 + 덱마다 고유한 뽑기 규칙이 있을 수 있음 |
| 3 | 앱 진입 기본 동작 | 첫 진입은 메인 메뉴, "즉시 뽑기 모드" 설정 시 다음부터 바로 뽑기 | 첫 사용자에게 기능 오리엔테이션 제공 + 숙련자는 바로 뽑기 |
| 4 | 체험 레벨 구체안 | 3단계: Level 1 즉시 결과(0.5초), Level 2 간단 연출(2~3초 플립/슬라이드), Level 3 풀 셔플(Flame 물리엔진 → 카드 선택) | 극단에서 점진적으로, 구현 복잡도도 레벨별로 분리 가능 |
| 5 | 대체 뽑기 방식 | 둘 다: 덱별 고유 뽑기 규칙(I Ching 6효 등) + 타로 전통 스프레드 유형(켈틱 크로스, 호스슈 등) | 덱 다양성과 타로 전통 모두 수용 |
| 6 | 설정 저장 | DB 테이블 (UserSettings) — Drift 스키마에 추가 | 향후 서버 동기화 가능성 열어둠. 기존 Drift 인프라 활용 |
| 7 | 한 장 더 뽑기 | 리딩 결과 화면에 "+1" 버튼. 탭하면 셔플된 덱에서 다음 카드 1장 추가. 기존 리딩에 append되어 자동 저장 갱신 | 뽑고 나서 "좀 더 보고 싶다"는 자연스러운 욕구 수용. 초기 설정 장수에 부담 없이 진행 가능 |

## Open Questions

| # | Question | Impact | Status |
|---|----------|--------|--------|
| 1 | ~~"즉시 뽑기"의 의미~~ | — | resolved → Decision #1 |
| 2 | ~~"여러장 뽑기"의 범위~~ | — | resolved → Decision #2 |
| 3 | ~~설정 저장 위치~~ | — | resolved → Decision #6 (DB) |
| 4 | ~~뽑기 체험 레벨 구체안~~ | — | resolved → Decision #4 (3단계) |
| 5 | ~~"대체 뽑는카드방식" 범위~~ | — | resolved → Decision #5 (둘 다) |

## Constraints

- 기존 Drift DB 스키마(Readings, Decks, Cards, DrawnCards 테이블) 유지 호환
- Riverpod + GoRouter + Freezed 아키텍처 패턴 유지
- 현재 rws-standard + iching-holitzka 2개 덱 존재

## Exit Criteria

- [x] 진입 흐름 결정 → 첫 진입 메인 메뉴, 이후 설정에 따라 즉시 뽑기
- [x] 뽑기 유형 범위 확정 → 1~10장 자유 + 덱별 대체 방식
- [x] 뽑기 체험 레벨 구체화 → 3단계 (즉시/간단연출/풀셔플)
- [x] 대체 뽑기 방식 범위 확정 → 덱별 고유 규칙 + 타로 전통 스프레드 둘 다
- [x] 설정 저장 방식 결정 → DB 테이블 (UserSettings)
- [x] 모든 Open Questions resolved

## Model Anchors

### MA-1: 진입 흐름 분기
- `initialLocation`은 UserSettings의 `quickDrawEnabled` 값에 따라 결정한다.
- `quickDrawEnabled == false` (기본값, 첫 사용자): GoRouter `initialLocation: '/'` → 메인 메뉴 허브 페이지.
- `quickDrawEnabled == true`: GoRouter `initialLocation`을 뽑기 결과 라우트로 설정하되, 체험 레벨(MA-2)에 따라 경유 라우트가 달라진다.
- 메인 메뉴 허브는 ShellRoute 또는 독립 페이지로, 기능 카드 목록(뽑기, 기록, 설정)을 표시한다.

### MA-2: 3단계 체험 레벨
- DB enum 또는 int 컬럼: `experienceLevel` ∈ {1, 2, 3}
- **Level 1 (즉시 결과)**: 셔플 로직만 실행, 애니메이션 없이 결과 카드를 즉시 렌더. 진입→결과 0.5초 이내.
- **Level 2 (간단 연출)**: 카드 플립/슬라이드 implicit 애니메이션 2~3초. Flutter 기본 AnimatedWidget 계열 사용. Flame 불필요.
- **Level 3 (풀 셔플)**: 기존 `/shuffle/:deckId` 라우트의 Flame 물리엔진 셔플 체험 전체를 경유. 기존 코드 재활용, 신규 구현 아님.

### MA-3: 카드 수 & 스프레드 확장
- `SpreadType` enum을 확장하거나 데이터 기반 모델로 전환. 기존 `single`, `threeCard` 유지하면서 `custom(N)` 추가.
- 1~10장 자유 선택 시 positions/guidances는 generic 텍스트 사용 (도메인 콘텐츠 생성은 Out of Scope).
- **덱별 고유 뽑기**: `DeckMetadata`에 `supportedDrawModes` 필드 추가. 타로 덱은 `[freeform, named_spread]`, I Ching 덱은 `[hexagram]` 등.
- **타로 전통 스프레드**: `NamedSpread` 모델 (name, cardCount, positions 리스트). 콘텐츠는 타로 전문가가 채움 → 데이터 구조만 준비.

### MA-4: 설정 persist — UserSettings 테이블
- Drift `UserSettings` 테이블: `id`, `selectedDeckId`, `experienceLevel`, `defaultCardCount`, `showFaceUp`, `quickDrawEnabled`, `defaultSpreadType`, `updatedAt`.
- 단일 row (id=1) 패턴. 없으면 기본값으로 생성.
- Riverpod provider로 reactive 노출: `userSettingsProvider` (Stream).

### MA-5: 리딩 저장 & 메모
- 현재 `Reading` 엔티티의 `notes` 필드 활용 — 스키마 변경 불필요.
- 리딩 결과 화면에서 자동 저장 (현재는 수동 저장 버튼) → Level 1/2는 결과 표시와 동시에 자동 저장, Level 3은 기존 방식 유지.
- 리딩 상세 페이지에서 `notes` 인라인 편집 가능.
- 리딩 목록: `spreadType` 기준 필터/그룹핑 UI 추가.

### MA-6: 라우트 구조 재설계
- 기존 선형 흐름을 허브 모델로 전환.
- 예상 라우트: `/` (메인 허브), `/draw` (즉시 뽑기 결과), `/shuffle/:deckId` (풀 셔플), `/readings` (리딩 목록), `/readings/:id` (리딩 상세+메모), `/settings` (설정 페이지), `/deck` (덱 선택).
- `quickDrawEnabled` 시 앱 시작 → 체험 레벨에 따라 `/draw` 또는 `/shuffle/:deckId`로 redirect.

### MA-7: 카드 표시 방식 (앞면/뒷면)
- UserSettings `showFaceUp: bool` (기본값 false = 뒷면).
- 뒷면 표시 시 탭하면 플립. 앞면 표시 시 바로 카드 이미지 노출.
- 이 설정은 Level 1/2에만 적용. Level 3은 셔플 체험 자체가 뒷면→공개 플로우.

### MA-8: 한 장 더 뽑기 (Incremental Draw)
- 리딩 결과 화면 하단에 "+1 한 장 더" 버튼 상시 표시.
- 탭 시 셔플된 덱(`ShuffleResult.cards`)에서 아직 사용하지 않은 다음 카드를 1장 가져와 기존 레이아웃에 append.
- 추가된 카드도 앞면/뒷면 설정(MA-7)을 따름.
- `Reading.drawnCards` 리스트에 즉시 추가되고, 이미 자동 저장된 리딩이면 DB update.
- 덱의 남은 카드가 0이면 버튼 비활성화 (타로 78장 기준, 최대 78장까지 가능하나 실제로는 10장 이내가 대부분).
- 추가 뽑기 시 `Reading.spreadType`은 원래 설정 유지 (custom 스프레드의 경우 "N+추가M" 형태로 기록).

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
