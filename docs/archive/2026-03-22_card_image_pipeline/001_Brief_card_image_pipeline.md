---
id: "001"
type: brief
title: "카드 이미지 파이프라인 — 멀티 덱 이미지 적용 & 성능 최적화"
created: 2026-03-21
status: completed
summary: >
  이칭 Holitzka(64장)·RWS 타로(78장) 카드 이미지를 모바일 앱에 적용한다.
  셔플 중엔 card_back.webp 뒷면 이미지(Flame Sprite), 결과 화면에선
  스프레드 뷰로 앞면 이미지(Flutter 위젯). 성능 우선, 앱 크기 최소화.
  덱 선택은 비주얼 프리뷰 포함.
keywords: [card-image, multi-resolution, deck-selection, performance, webp, flutter, flame-sprite]
---

# 카드 이미지 파이프라인 — 멀티 덱 이미지 적용 & 성능 최적화

## Intent
이칭 Holitzka(64장)·RWS 타로(78장, "유니버셜 타로"와 동일) 등 다양한 덱의
카드 이미지를 모바일 앱에 적용한다.

셔플 중엔 card_back.webp 뒷면 이미지를 Flame Sprite로 렌더링하고,
카드를 뽑은 후 결과 화면에서 스프레드 뷰(3장+)로 앞면 이미지를 Flutter 위젯으로 표시한다.

앱 크기는 가능하면 작게 유지하되, 크기 vs 성능 트레이드오프에서는 성능을 우선한다.
추가 덱은 다운로드 방식을 고려한다.
덱 선택 화면은 카드 프리뷰 이미지 포함 비주얼 선택으로 업그레이드한다.

## Context
- **에셋 현황**: `mobile/assets/images/rws/` (79 webp, 17MB), `mobile/assets/images/iching_holitzka/` (65 webp, 5.4MB)
- **도메인 모델**: `TarotCard` (freezed, `imagePath` 필드), `DeckMetadata` (`totalCards`, `isStandardTarot`)
- **렌더링**: `CardBodyComponent` — Flame/Forge2D 물리 카드, 현재 Canvas 코드 렌더링만 (이미지 미사용)
- **덱 선택**: `DeckSelectionPage` — 기본 ListView, 덱 선택 → intention 화면 이동
- **기존 문서**: `docs/16_iching_holitzka/` (이칭 이미지 에셋 추가), `docs/17_universal_waite/` (RWS 이미지 에셋 추가)
- **셔플 엔진**: `docs/11_tarot_shuffle/` — 물리 기반 셔플 구현 완료

## Boundaries

### In Scope
| # | Item | Description |
|---|------|-------------|
| 1 | Flame 뒷면 이미지 통합 | CardBodyComponent에 card_back.webp Sprite 렌더링 적용 |
| 2 | 결과 화면 앞면 이미지 | Flutter 위젯 스프레드 뷰로 뽑힌 카드 앞면 표시 |
| 3 | 이미지 해상도·캐싱 전략 | 성능 우선 해상도 관리, 메모리 효율적 로딩 (3~10장 동시) |
| 4 | 덱 선택 비주얼 UX | 카드 뒷면 + 샘플 카드 프리뷰 포함 비주얼 선택 화면 |
| 5 | 덱별 카드 수 대응 | 덱별 카드 수 차이에 따른 뽑기 로직·스프레드 대응 |

### Out of Scope
| # | Item | Reason |
|---|------|--------|
| 1 | 새 덱 에셋 추가 | 이미 docs/16, docs/17에서 완료 |
| 2 | 카드 해석 콘텐츠 | 이미지 표시와 별도 영역 |
| 3 | 서버 사이드 이미지 관리 | 현재 로컬 에셋 기반 |
| 4 | 덱 다운로드 시스템 구현 | 향후 과제, 이번에는 구조 고려만 |

## Decisions

| # | Decision | Chosen | Rationale |
|---|----------|--------|-----------|
| 1 | 앞면 이미지 표시 시점 | 결과 화면에서만 (셔플 중 뒷면만) | Flame 엔진은 뒷면 렌더링에 집중, 이미지 로딩을 결과 시점까지 지연 |
| 2 | 유니버셜 타로 = RWS | 동일 덱 (rws/ 폴더) | 별도 에셋 추가 불필요 |
| 3 | 렌더링 아키텍처 분리 | Flame=뒷면, Flutter 위젯=앞면 | 셔플 중 앞면 불필요 → 관심사 분리 명확 |
| 4 | 앱 크기 vs 성능 | 성능 우선, 크기는 가능하면 작게 | 추가 덱은 다운로드 방식 고려 |
| 5 | 결과 화면 레이아웃 | 스프레드 뷰 (3장+ 동시 표시) | 타로 리딩 경험에 부합, 동시 로딩 수 제한적(3~10장) |
| 6 | Flame 카드 뒷면 | card_back.webp 이미지 사용 | 실제 카드 뒷면 디자인 반영, 덱당 1장이라 메모리 부담 없음 |
| 7 | 덱 선택 UI | 비주얼 프리뷰 포함 | 카드 뒷면 + 샘플 카드 이미지로 덱 특성 직관적 전달 |

## Open Questions

| # | Question | Impact | Status |
|---|----------|--------|--------|
| — | 모든 질문 해결됨 | — | — |

## Constraints
- 모바일 디바이스 메모리: 스프레드 뷰에서 동시 3~10장 앞면 이미지 로딩
- 앱 번들 크기: 현재 rws 17MB + iching 5.4MB, 추가 덱마다 증가
- Flame/Forge2D 렌더링 파이프라인 내 Sprite 로딩 호환성
- card_back.webp는 덱당 1장 — 모든 CardBodyComponent 인스턴스가 공유

## Exit Criteria
- [x] 이미지 렌더링 통합 방식 결정 → Flame=뒷면(card_back.webp Sprite), Flutter 위젯=앞면
- [x] 카드 확대 시나리오 범위 확정 → 결과 화면 스프레드 뷰에서만
- [x] 결과 화면 레이아웃 확정 → 스프레드 뷰 (3장+)
- [x] 뒷면 렌더링 방식 확정 → card_back.webp 이미지
- [x] 덱 선택 UX 방향 확인 → 비주얼 프리뷰 포함

## Model Anchors

1. **Flame 뒷면 렌더링**: `CardBodyComponent.render()`에서 현재 코드 드로잉(그라디언트/패턴)을 제거하고, 선택된 덱의 `card_back.webp`를 Flame `Sprite`로 로딩하여 렌더링. 덱당 1개 Sprite를 공유 — `TarotGame` 레벨에서 로딩 후 각 CardBodyComponent에 참조 전달.

2. **앞면 이미지는 Flame 외부**: 앞면 카드 이미지는 Flame 게임 영역 밖 Flutter 위젯 트리에서 표시. `Image.asset(imagePath)`로 로딩. 결과 화면 진입 시 뽑힌 카드(3~10장)만 로딩.

3. **해상도 전략 — 성능 우선**: 고해상도 원본 1장 저장 + Flutter `cacheWidth`/`cacheHeight`로 런타임 다운스케일. 멀티 해상도 에셋 미생성 (앱 크기 최소화). 스프레드 뷰 썸네일과 단일 카드 확대 시 같은 원본 사용, `cacheWidth`만 조정.

4. **스프레드 뷰**: 결과 화면은 스프레드 뷰(3장+)가 기본. 카드 배치는 스프레드 타입별로 다름. 스프레드 뷰에서 카드 크기가 작으므로 `cacheWidth`를 화면 너비의 1/3~1/4 수준으로 제한하여 메모리 절약.

5. **덱 선택 비주얼 UI**: `DeckSelectionPage`를 리스트에서 카드형 비주얼 선택으로 교체. 각 덱 항목에 card_back.webp 썸네일 + 대표 카드 1~2장 프리뷰 + 카드 수 표시.

6. **덱별 카드 수 대응**: `DeckMetadata.totalCards`를 기준으로 뽑기 로직(가능한 스프레드 종류, 최대 뽑기 수) 결정. 64장 덱과 78장 덱에서 사용 가능한 스프레드가 다를 수 있음.

7. **향후 확장 고려**: 추가 덱 에셋은 앱 번들에 포함하지 않고 다운로드 방식을 위한 구조만 고려. 현재는 `assets/images/{deckId}/` 경로 규약 유지.

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
