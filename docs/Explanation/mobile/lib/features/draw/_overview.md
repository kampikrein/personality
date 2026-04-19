---
id: "mobile-lib-features-draw"
type: explanation
target: "mobile/lib/features/draw/"
layer: folder
version: 1
created: 2026-04-16
updated: 2026-04-16
last_explained_commit: "96a0c15dc43d5af2b98e32fec1f157eeacc1e8df"
---

# mobile/lib/features/draw/ — 해설

## 개요

타로 뽑기의 UX 진입 경로를 오케스트레이션하는 피처다.
경험 레벨(Lv1~Lv4)에 따라 "즉시 뽑기"와 "연출 뽑기" 두 흐름을 담당하며,
셔플 실행·결과 렌더·리딩 저장을 단일 결과 페이지(`DrawResultPage`)로 통합한다.

## 역할 (Role)

`draw/` 피처는 `shuffle/` 피처의 셔플 엔진 결과를 소비하여 사용자에게 뽑기 결과를
화면으로 제공하고, `reading/` 피처의 `ReadingRepository`에 결과를 자동 저장하는
**뽑기 UX 계층**이다. domain/data 레이어를 소유하지 않으며,
다른 피처의 provider를 조합하는 순수 presentation 피처로 설계되어 있다.

이 피처의 핵심 설계 결정:
1. **단일 결과 페이지**: Lv1~Lv4 모든 경험 수준이 `DrawResultPage` 하나로 합류 (MA-1)
2. **상태 인계 버스**: 페이지 간 셔플 결과 전달에 `shuffleStateProvider`(keepAlive) 사용
3. **연출과 결과 분리**: `AnimatedDrawPage`는 연출만, `DrawResultPage`는 결과만 (Cycle 2)

## 구조 (Structure)

```
draw/
└── presentation/           유일한 아키텍처 레이어 (domain/data 없음)
    ├── pages/
    │   ├── animated_draw_page.dart   Lv2 연출 — 질문 → 셔플 → 애니메이션 → 결과 인계
    │   └── draw_result_page.dart     Lv1~Lv4 통합 결과 — 자체 셔플 or 업스트림 재사용
    └── providers/
        ├── draw_providers.dart       executeDraw — one-shot 셔플 오케스트레이터 (예비)
        └── draw_providers.g.dart     codegen (편집 금지)
```

| 하위 폴더 | 역할 | 핵심 |
|----------|------|------|
| `presentation/pages/` | 두 화면: 연출(`AnimatedDrawPage`) + 통합 결과(`DrawResultPage`). `shuffleStateProvider`로 단방향 인계 | 분기 합류 패턴: 여러 진입 경로가 하나의 결과 페이지로 수렴 |
| `presentation/providers/` | `executeDraw` 셔플 provider. 설정→덱로드→셔플→상태세팅을 캡슐화 | 현재 미사용. 페이지들이 동일 로직을 인라인 구현 중 |

## 동작 흐름 (Flow)

앱의 뽑기 경험 전체가 이 피처를 거친다:

```
HomePage._startDraw(experienceLevel)
  │
  ├── Lv1 ──────── /draw/result ─────────────── DrawResultPage
  │                                              (자체 셔플, _reuseUpstreamResult=false)
  │
  ├── Lv2 ──────── /draw/animated ── AnimatedDrawPage
  │                                    ├─ 질문 입력 → _startDraw()
  │                                    ├─ 셔플 → shuffleStateProvider.setResult()
  │                                    ├─ 스태거 애니메이션 (600ms + 300ms gap)
  │                                    └─ pushReplacementNamed('draw-result')
  │                                          └── DrawResultPage
  │                                              (업스트림 재사용, _reuseUpstreamResult=true)
  │
  └── Lv3/4 ───── IntentionPage → ShufflePage (shuffle/ 피처)
                    └─ shuffleStateProvider.setResult()
                          └── DrawResultPage
                              (업스트림 재사용, _reuseUpstreamResult=true)
```

**결과 도착 후 공통 흐름** (DrawResultPage):
1. `_executeDraw()` — 재사용 or 자체 셔플 분기
2. `_triggerAutoSave()` → `Reading` 엔티티 생성 → `ReadingRepository.saveReading()`
3. UI: SpreadLayout 카드 렌더 + 하단 버튼 (다시 / +N장 / 리셋)

## 의존성 (Dependencies)

| 대상 | 종류 | 역할 |
|------|------|------|
| `shuffle/` 피처 | internal | `shuffleStateProvider`, `shuffleDeckUseCaseProvider`, `shuffleStrategyProvider` — 셔플 엔진 |
| `deck/` 피처 | internal | `deckCardsProvider`, `deckRepositoryProvider` — 덱 데이터 |
| `settings/` 피처 | internal | `userSettingsProvider`, `cardAspectRatioProvider` — 사용자 설정 |
| `reading/` 피처 | internal | `readingRepositoryProvider`, `readingQuestionProvider`, `SpreadLayout` — 저장·렌더 |
| `go_router` | external | 선언적 라우팅 (`pushReplacementNamed`, named route) |
| `uuid` | external | `Reading.id` 자동 생성 |
| `TickerProviderStateMixin` | Flutter SDK | AnimatedDrawPage 애니메이션 vsync |

## 주의사항 (Caveats)

- **`shuffleStateProvider` keepAlive 잔류**: 새 뽑기 시작 전 반드시 `.clear()` 호출. 재사용 경로(`_reuseUpstreamResult=true`)에서는 clear 금지.
- **셔플 로직 3중 분산**: `animated_draw_page`, `draw_result_page`, `draw_providers` 세 곳에 유사한 셔플 흐름이 존재한다. 변경 시 동기화 주의. 향후 `executeDraw` provider 통합이 권장된다.
- **`_reuseUpstreamResult` 단일 지점 평가**: `initState`에서 한 번만 결정. "다시" 버튼 시 `false`로 명시적 리셋 필수.
- **`pushReplacementNamed` 필수**: 연출→결과 전환 시 스택 교체. `pushNamed` 사용 시 뒤로가기 시 중복 렌더.
- **domain/data 부재**: 비즈니스 규칙은 모두 외부 피처에 위임. `draw/` 자체에 테스트 가능한 순수 로직이 없다.

## 하위 구성 (Contents)

| 구분 | 대상 | 해설 문서 | 한 줄 요약 |
|------|------|----------|-----------|
| 폴더 | `presentation/` | [overview](presentation/_overview.md) | 순수 presentation 피처 — pages 2개 + providers 1개 |

## Changelog

### v1 (2026-04-16) — 최초 작성
- bottom-up 방식으로 재구성. leaf 파일 → 하위 폴더 overview → target overview 순서로 작성하여 상위 문서에 하위 맥락이 자연스럽게 반영됨.
