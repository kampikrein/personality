---
id: "054"
type: plan
title: "Cycle 4 Plan: draw flow guide doc"
cycle: 4
status: completed
traces_brief: "040"
traces_scope: "041"
created: 2026-04-21
---

# Cycle 4 Plan: docs/guide/001_draw_flow_guide.md

## 목적

Cycles 1–3에서 구현 완료된 IntentPlacement 3-way 옵션(beforeShuffle / afterDraw / disabled)의
실제 동작을 단일 페이지 가이드 문서로 정리한다. 대상 독자는 미래의 Claude 에이전트와 개발자다.
구현 코드와 1:1 대응이 검증 가능해야 한다.

## 가이드 섹션 아웃라인

| # | 섹션 | 목적 |
|---|------|------|
| 1 | Overview | IntentPlacement가 무엇인지, 왜 3가지 모드가 필요한지. Brief 040 링크. |
| 2 | Three modes | 각 모드의 사용자 경험 3문장 설명 (beforeShuffle / afterDraw / disabled). |
| 3 | Mermaid flow diagrams | 모드별 1개씩, deck 선택 → (의도 입력\|셔플) → 결과 → 저장 흐름. 의도 입력 위치 시각화. |
| 4 | Code entry point table | 3 modes × key touchpoints: 라우팅 분기 / IntentionPage 동작 / DrawResultPage 입력 박스 / reading.question 설정 주체. 실제 파일/함수명 명시. |
| 5 | Save timing table | 모드별 reading.question 저장 시점 상세. beforeShuffle / afterDraw / disabled 각각의 저장 흐름. |
| 6 | Decision tree | "어떤 모드를 추천하나?" — 사용자 선호(의식 중심 / 속도 우선 / 사후 성찰) 기반 1줄 권고. |
| 7 | Implementation references | 관련 커밋(bb52950, ae72da3, 42e5339)과 핵심 파일 목록. |
| 8 | Testing entry points | 모드별 동작을 커버하는 테스트 파일 목록. |

## 대상 독자

- **미래 Claude 에이전트**: 이 플로우를 수정할 때 어느 파일에서 무엇을 바꿔야 하는지 10분 내 파악 가능해야 한다.
- **개발자**: 코드를 읽지 않고 이 문서만으로 3가지 모드의 동작 차이와 저장 정합성을 이해할 수 있어야 한다.

## 정확성 요구사항

- 파일 경로: `mobile/lib/` 하위 실제 경로 기준.
- 함수명: home_page.dart의 `_startDraw`, intention_page.dart의 `_maybeRedirect`/`_redirectChecked`/`whenData`, draw_result_page.dart의 `_updateQuestion`/`_autoSave`.
- 라우팅: deck 선택 후 `intentPlacement` 읽어 `/intention/:deckId` vs `/shuffle/:deckId` 분기.
- 저장: `_autoSave` 시점(카드 공개 직후) vs `updateQuestion` 시점(사용자 입력 후) 구분.

## 산출물 경로

`docs/guide/001_draw_flow_guide.md` (신규 폴더 docs/guide/ 생성)

## 비코드 사이클 특성

Cycle 4는 코드 변경 없음. TDD-red skip. makeplan + impl 병합 실행.
