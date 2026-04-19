---
id: "mobile-lib-features-draw-presentation-pages"
type: explanation
target: "mobile/lib/features/draw/presentation/pages/"
layer: folder
version: 1
created: 2026-04-16
updated: 2026-04-16
last_explained_commit: "96a0c15dc43d5af2b98e32fec1f157eeacc1e8df"
---

# draw/presentation/pages/ — 해설

## 개요

뽑기 피처의 두 화면 — 연출 뽑기(`AnimatedDrawPage`)와 통합 결과(`DrawResultPage`) —
을 담고 있는 페이지 디렉토리다. 두 페이지는 `shuffleStateProvider`를 매개로
연출 → 결과 단방향 상태 인계 관계를 형성한다.

## 역할 (Role)

이 디렉토리는 뽑기 경험의 전체 시각적 흐름을 담당한다.
`AnimatedDrawPage`가 셔플 실행 + 카드 공개 연출을 맡고,
`DrawResultPage`가 결과 렌더 + 자동 저장 + 추가 뽑기를 맡는다.
Cycle 2 이전에는 결과 렌더까지 연출 페이지가 담당했으나,
현재는 **단일 책임 원칙에 따라 연출/결과가 완전 분리**되어 있다.

## 구조 (Structure)

```
pages/
├── animated_draw_page.dart   Lv2 연출 — 질문 입력 → 셔플 → 스태거 애니메이션 → 결과 인계
└── draw_result_page.dart     Lv1~Lv4 통합 결과 — 자체 셔플 or 업스트림 재사용
```

| 파일 | 클래스 | Mixin | 주요 책임 |
|------|--------|-------|----------|
| `animated_draw_page.dart` | `AnimatedDrawPage` / `_AnimatedDrawPageState` | `TickerProviderStateMixin` | 셔플, 슬라이드+페이드 애니메이션, 카드 공개, 상태 인계 |
| `draw_result_page.dart` | `DrawResultPage` / `_DrawResultPageState` | — | 결과 렌더, 자동 저장, +1 카드, 재셔플 |

## 동작 흐름 (Flow)

두 페이지의 관계는 체인이 아니라 **분기 합류** 패턴이다:

```
HomePage._startDraw(experienceLevel)
  ├─ Lv1 ─────────────────────────── DrawResultPage (자체 셔플)
  │                                     _reuseUpstreamResult = false
  │
  └─ Lv2 → AnimatedDrawPage
              ├─ 질문 입력 화면
              ├─ _startDraw() → shuffleStateProvider.setResult()
              ├─ _playAnimations() → 스태거 300ms
              └─ _maybeGoToResult()
                    └─ pushReplacementNamed('draw-result')
                          └─ DrawResultPage (업스트림 재사용)
                               _reuseUpstreamResult = true
```

1. **Lv1 직접 진입**: `DrawResultPage`가 `shuffleStateProvider == null`을 감지 → 자체 셔플 경로
2. **Lv2 연출 진입**: `AnimatedDrawPage`가 셔플 → 연출 → 인계 → `DrawResultPage`가 `!= null` 감지 → 재사용 경로
3. **Lv3/4**: `ShufflePage`(shuffle 피처)가 셔플 후 동일하게 `DrawResultPage`로 인계

두 진입 경로 모두 `DrawResultPage` 도착 후에는 동일한 UI와 자동 저장 로직을 공유한다.

## 의존성 (Dependencies)

| 대상 | 종류 | 역할 |
|------|------|------|
| `shuffleStateProvider` | `shuffle/` 피처 | 두 페이지 간 셔플 결과 버스 (keepAlive) |
| `shuffleDeckUseCaseProvider` | `shuffle/` 피처 | 셔플 알고리즘 실행 |
| `deckCardsProvider` / `deckRepositoryProvider` | `deck/` 피처 | 덱 카드 로드 + 시드 |
| `userSettingsProvider` / `cardAspectRatioProvider` | `settings/` 피처 | 스프레드·카드수·덱ID·showFaceUp 등 설정 |
| `readingRepositoryProvider` / `readingQuestionProvider` | `reading/` 피처 | 결과 자동 저장 + 질문 공유 |
| `SpreadLayout` | `reading/` 위젯 | 스프레드별 카드 배치 렌더 (DrawResultPage에서 사용) |
| `go_router` | external | `pushReplacementNamed`, `context.go('/')` |
| `TickerProviderStateMixin` | Flutter SDK | AnimatedDrawPage 애니메이션 vsync |

## 주의사항 (Caveats)

- **`pushReplacementNamed` 필수**: `AnimatedDrawPage` → `DrawResultPage` 전환 시 `pushNamed`를 쓰면 연출 화면이 스택에 남아 뒤로가기 시 중복 셔플이 발생한다.
- **`_reuseUpstreamResult`는 `initState` 단 한 번 평가**: `DrawResultPage`가 rebuild되어도 분기가 바뀌지 않는다. "다시" 버튼은 명시적으로 `false`로 리셋한다.
- **업스트림 경로에서 `clear()` 금지**: 재사용 경로에서 `shuffleStateProvider.clear()`를 호출하면 셔플 결과가 소실된다.
- **AnimationController 수명 관리**: `AnimatedDrawPage.dispose()`에서 모든 컨트롤러를 해제해야 메모리 누수가 없다.

## 하위 구성 (Contents)

| 구분 | 대상 | 해설 문서 | 한 줄 요약 |
|------|------|----------|-----------|
| 파일 | `animated_draw_page.dart` | [해설](animated_draw_page.md) | Lv2 연출 뽑기 — 셔플 + 스태거 애니메이션 |
| 파일 | `draw_result_page.dart` | [해설](draw_result_page.md) | Lv1~Lv4 통합 결과 — 자체 셔플 or 업스트림 재사용 |

## Changelog

### v1 (2026-04-16) — 최초 작성
- 최초 해설 문서 생성. 두 페이지 간 분기 합류 패턴과 shuffleStateProvider 기반 상태 인계 분석 수록.
