---
id: "002"
type: scope
title: "카드 이미지 파이프라인 — Flame 뒷면 Sprite + Flutter 앞면 이미지 + 덱 선택 비주얼"
created: 2026-03-22
traces_brief: "001"
complexity: complex
research_needed: true
research_reason: "Flame Sprite를 Forge2D BodyComponent.render() 내에서 사용하는 패턴 검증 + webp cacheWidth 메모리 최적화 확인 필요"
auto_run: true
effort_mode: standard
uncertainty_level: medium
intent: >
  이칭(64장)·RWS(78장) 카드 이미지를 모바일 앱에 적용.
  셔플 중 card_back.webp Flame Sprite 렌더링, 결과 화면 Flutter 위젯 앞면 이미지 표시,
  덱 선택 비주얼 프리뷰 업그레이드. 성능 우선.
summary: >
  2개 영역, 1개 의존 관계, 2개 사이클.
  사이클 1: Flame 뒷면 Sprite + 동적 카드 수 (shuffle 영역).
  사이클 2: 결과 화면 앞면 이미지 + 덱 선택 비주얼 (reading + deck 영역).
keywords: [flame-sprite, card-image, forge2d, cacheWidth, deck-selection, spread-view]
cycles:
  - cycle: 1
    area: "Flame 뒷면 Sprite + 동적 카드 수"
    depends_on: []
    research_needed: true
  - cycle: 2
    area: "결과 화면 앞면 이미지 + 덱 선택 비주얼"
    depends_on: [1]
    research_needed: false
---

# 카드 이미지 파이프라인 — Scope

## 작업 목표

Brief(001)의 7개 결정사항을 구현한다:
1. Flame CardBodyComponent에 card_back.webp Sprite 렌더링 (현재 코드 드로잉 교체)
2. TarotGame 동적 카드 수 — 선택된 덱의 totalCards 반영 (현재 22장 하드코딩)
3. 결과 화면 CardRevealWidget에 실제 카드 이미지 표시 (현재 텍스트만)
4. DeckSelectionPage 비주얼 프리뷰 업그레이드 (현재 텍스트 리스트)
5. 성능 우선 해상도 전략 — cacheWidth 기반 런타임 다운스케일

**성공 기준**: 셔플 시 실제 카드 뒷면 이미지가 보이고, 결과 화면에서 앞면 카드 이미지가 표시되며, 덱 선택 시 비주얼 프리뷰가 동작.

## 접근 방향

**선택**: 영역 분리 (Flame 엔진 → Flutter 위젯) 순차 구현

- 사이클 1에서 Flame 엔진의 이미지 인프라(Sprite 로딩, 덱 정보 전달)를 확립
- 사이클 2에서 Flutter 위젯의 이미지 표시를 구현
- 대안: 모든 영역 동시 구현 → 디버깅 시 Flame/Flutter 혼재, 비추

## Research 판단
- **판단**: 필요 (사이클 1만)
- **근거**: Flame Sprite를 Forge2D BodyComponent.render(Canvas) 내에서 사용하는 패턴이 프로젝트에 없음. Sprite 공유(TarotGame → 다수 CardBodyComponent), webp 디코딩 성능, cacheWidth 메모리 절약 효과 검증 필요.
- **파이프라인**: S → R(사이클1) → Agent(P) → Agent(I) → Agent(V) → eval → Agent(P) → Agent(I) → Agent(V) → eval → retro

## 영역 식별

| # | 영역 | 주요 파일/모듈 | 설명 |
|---|------|-------------|------|
| 1 | Flame 뒷면 Sprite + 동적 카드 수 | shuffle/presentation/game/ | CardBodyComponent Sprite 렌더링, TarotGame 덱 정보 수신·Sprite 로딩, ShufflePage 덱 컨텍스트 전달 |
| 2 | 결과 화면 앞면 이미지 + 덱 선택 비주얼 | reading/presentation/widgets/, deck/presentation/pages/ | CardRevealWidget 이미지 표시, DeckSelectionPage 비주얼 프리뷰 |

### 영역 1: Flame 뒷면 Sprite + 동적 카드 수

**Modified (actual change):**
- `mobile/lib/features/shuffle/presentation/game/card_body_component.dart` — render()에서 코드 드로잉 → Sprite 렌더링으로 교체
- `mobile/lib/features/shuffle/presentation/game/tarot_game.dart` — Sprite 로딩, 덱 메타데이터 수신, 동적 cardCount
- `mobile/lib/features/shuffle/presentation/pages/shuffle_page.dart` — TarotGame에 덱 정보 전달

**Reviewed (check-only):**
- `mobile/lib/features/shuffle/presentation/game/tarot_coordinate_utils.dart` — 카드 크기 상수 확인
- `mobile/lib/features/deck/domain/entities/deck_metadata.dart` — 필드 구조 확인

파일 수 예측: Modified 3 | confidence: high

### 영역 2: 결과 화면 앞면 이미지 + 덱 선택 비주얼

**Modified (actual change):**
- `mobile/lib/features/reading/presentation/widgets/card_reveal_widget.dart` — _buildFront()에 Image.asset(imagePath), _buildBack()에 card_back.webp
- `mobile/lib/features/deck/presentation/pages/deck_selection_page.dart` — 비주얼 프리뷰 UI

**Reviewed (check-only):**
- `mobile/lib/features/reading/presentation/widgets/spread_layout.dart` — 이미지 크기 전달 확인
- `mobile/lib/features/reading/domain/entities/spread_type.dart` — 카드 수 참조
- `mobile/lib/features/deck/data/repositories/deck_repository_impl.dart` — getCardsByDeckId 확인

파일 수 예측: Modified 2 | confidence: high

## 의존성 맵

**다이어그램:**
```
[Cycle 1] Flame 뒷면 + 동적 카드 수
    │ (Sprite 로딩 패턴, 덱 이미지 경로 규약 확립)
    ▼
[Cycle 2] 결과 앞면 이미지 + 덱 선택 비주얼
```

**의존 관계 상세:**

| From | To | 의존 내용 | 근거 |
|------|----|---------|------|
| 영역 2 | 영역 1 | 이미지 경로 규약, 덱→셔플 데이터 흐름 | 사이클 1에서 확립된 덱 이미지 경로 패턴(assets/images/{deckId}/)을 사이클 2가 따름 |

## 실행 순서

| 사이클 | 영역 | 선행 조건 | Research | 파이프라인 |
|--------|------|---------|----------|-----------|
| 1 | Flame 뒷면 Sprite + 동적 카드 수 | 없음 | 필요 | R→Agent(P)→Agent(I)→Agent(V) |
| 2 | 결과 앞면 이미지 + 덱 선택 비주얼 | 사이클 1 | 불필요 | Agent(P)→Agent(I)→Agent(V) |

## 사이클별 연구 가이드

**사이클 1: Flame 뒷면 Sprite + 동적 카드 수**
- 조사 대상: Flame의 Sprite 로딩 API (images.load, Sprite.load), BodyComponent 내 Sprite 렌더링 방법
- 핵심 질문:
  1. Forge2D BodyComponent.render(Canvas)에서 Sprite.render()를 호출하는 올바른 패턴은?
  2. TarotGame.images에서 로딩한 이미지를 다수 CardBodyComponent가 공유하는 방법은?
  3. webp 이미지의 Flame 내 디코딩 성능 특성은? (78장 전체 로딩 불필요 — card_back 1장만)
  4. Flutter Image.asset의 cacheWidth/cacheHeight가 실제 메모리 사용량에 미치는 영향은?

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
