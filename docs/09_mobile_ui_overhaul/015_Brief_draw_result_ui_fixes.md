---
id: "015"
type: brief
title: "뽑기 결과 화면 UI 3건 수정"
created: 2026-04-04
status: completed
deep_critique: false
critique_docs: []
summary: >
  즉시/연출 뽑기 결과 화면의 바텀 오버플로우 수정, 덱 카드 이미지 미표시 문제 해결, '성찰의 시간' 해설 섹션 제거.
keywords: [draw, overflow, card-image, reflection, ui-fix]
---

# 뽑기 결과 화면 UI 3건 수정

## Intent
뽑기 결과 화면(InstantDrawPage, AnimatedDrawPage)에서 발생하는 3가지 UI 문제를 수정한다:
1. **바텀 오버플로우 3.3px** — 카드 위젯이 할당된 영역을 초과하여 노란-검정 경고 띠 표시
2. **덱 이미지 미사용** — 카드 앞면이 실제 이미지 대신 보라색 플레이스홀더+텍스트로 표시
3. **'성찰의 시간' 섹션 제거** — 카드 해설 섹션이 현 단계에서 불필요, 삭제 요청

## Context
- **InstantDrawPage**: `mobile/lib/features/draw/presentation/pages/instant_draw_page.dart` — 즉시 뽑기 결과
- **AnimatedDrawPage**: `mobile/lib/features/draw/presentation/pages/animated_draw_page.dart` — 연출 뽑기 결과
- **CardRevealWidget**: `mobile/lib/features/reading/presentation/widgets/card_reveal_widget.dart` — 카드 플립 위젯
- **SpreadLayout**: `mobile/lib/features/reading/presentation/widgets/spread_layout.dart` — 스프레드 배치
- **카드 이미지**: `mobile/assets/images/rws-standard/` — webp 파일 존재 확인됨 (major-00.webp 등)
- **이미지 경로**: JSON에 `assets/images/rws-standard/major-00.webp` 형태로 저장, 파일 실제 존재
- **오버플로우 원인 추정**: CardRevealWidget의 Column(mainAxisSize: min)이 GridView의 childAspectRatio: 0.65 할당 공간에서 label+card+gap이 미세하게 초과
- **이미지 미표시 원인 추정**: Image.asset errorBuilder가 트리거됨 → 에셋 번들 등록 문제 또는 경로 불일치 가능

## Boundaries

### In Scope
| # | Item | Description |
|---|------|-------------|
| 1 | 바텀 오버플로우 수정 | CardRevealWidget/SpreadLayout에서 3.3px 오버플로우 해소 |
| 2 | 카드 이미지 표시 | errorBuilder 대신 실제 카드 이미지가 렌더링되도록 수정 |
| 3 | 성찰 섹션 제거 | 두 페이지의 '성찰의 시간' 섹션 전체 삭제 |

### Out of Scope
| # | Item | Reason |
|---|------|--------|
| 1 | 성찰 기능 대체 UI | 제거만 요청됨, 새 기능 추가 아님 |
| 2 | 카드 이미지 해상도/퀄리티 개선 | 현재 이미지 파일 표시만 목표 |
| 3 | 다른 페이지 UI 수정 | 뽑기 결과 화면만 대상 |

## Decisions

| # | Decision | Chosen | Rationale |
|---|----------|--------|-----------|
| 1 | 성찰 섹션 제거 범위 | InstantDrawPage + AnimatedDrawPage 모두 | 사용자가 스크린샷에서 해당 섹션 제거 요청, 양쪽 동일 구조 |
| 2 | 안전 고지 유지 | 유지 | 정신건강 안내는 책임 있는 기본값, 제거 요청 없음 |
| 3 | Dead code 정리 | ReflectivePrompts import 및 미사용 코드 함께 제거 | 성찰 섹션 전용 코드이므로 표준 정리 관행 |

## Open Questions

| # | Question | Impact | Status |
|---|----------|--------|--------|
| 1 | ~~안전 고지 유지/제거~~ | ~~화면 하단 구성~~ | resolved → D2 |
| 2 | ~~Dead code 정리 여부~~ | ~~코드 정리 범위~~ | resolved → D3 |

## Constraints
- Flutter 앱 — 변경 후 빌드/핫리로드 검증 필요
- 두 페이지(instant/animated)의 동일 패턴 병렬 수정

## Exit Criteria
- 3개 이슈(오버플로우, 이미지, 성찰 제거) 방향 확정
- scope에서 기술 분석 진행 가능한 수준의 명세

## Model Anchors
- **MA-1**: CardRevealWidget 또는 SpreadLayout의 레이아웃 제약을 조정하여 3.3px 오버플로우 해소. `childAspectRatio` 또는 Column 내부 spacing 조정 범위.
- **MA-2**: `Image.asset(card.imagePath)` 실패 원인 규명 후 수정. pubspec.yaml 에셋 선언, 경로 일치 확인.
- **MA-3**: InstantDrawPage L253-296, AnimatedDrawPage L353-398의 '성찰의 시간' 블록 삭제.

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 0s | 0 |
| 2 | user-ai-exchange | 136s | 666184 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 1387s |
| Total Tokens | 666184 |
| Input Tokens | 18 |
| Output Tokens | 5480 |
| Cache Read | 613156 |
| Cache Creation | 47530 |
