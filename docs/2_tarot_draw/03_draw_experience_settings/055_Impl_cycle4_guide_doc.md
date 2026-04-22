---
id: "055"
type: implementation
title: "Cycle 4 Impl: draw flow guide doc"
cycle: 4
status: completed
traces_plan: "054"
traces_brief: "040"
created: 2026-04-21
artifact: "docs/guide/001_draw_flow_guide.md"
---

# Cycle 4 Implementation Report: Draw Flow Guide

## 작성 완료 확인

`docs/guide/001_draw_flow_guide.md` 파일이 생성되었다 (신규 폴더 `docs/guide/` 포함).

## 섹션 작성 요약

| # | 섹션 | 내용 |
|---|------|------|
| 1 | Overview | IntentPlacement 배경(중복 입력 버그), 3가지 패턴의 필요성, Brief 040 링크 |
| 2 | Three Modes | 각 모드의 사용자 경험 3문장 (beforeShuffle / afterDraw / disabled) |
| 3 | Mermaid flow diagrams | 3개, 모드별 deck → (intention\|shuffle) → result → save 노드 포함. 의도 입력 위치 명시 |
| 4 | Code entry point table | 3 modes × 라우팅 분기/IntentionPage/DrawResultPage/question 설정 주체. 실제 파일:함수 매핑 |
| 5 | Save timing table | 초기 `_autoSave` vs 사후 `updateQuestion` 구분, 모드별 최종 reading.question 값 |
| 6 | Decision tree | 사용자 선호 3가지 → 각 모드 1줄 권고 |
| 7 | Implementation references | 커밋 3개 (bb52950/ae72da3/42e5339) + 핵심 파일 10개 |
| 8 | Testing entry points | 테스트 파일 2개 + 수동 검증 기준 3항목 |

## 코드 정확성 확인

가이드 작성 전 실제 코드를 직접 읽어 검증:

- `home_page.dart:_startDraw` L75–116: `intentPlacement` 읽어 Lv3/4에서 `intention` vs `shuffle` 분기 확인
- `intention_page.dart:_redirectChecked`/`_maybeRedirect`/`whenData` L46–88: redirect 로직 확인
- `draw_result_page.dart:_autoSave` L113–131, `_updateQuestion` L133–140: 저장 흐름 확인
- `draw_result_page.dart` L165–215: `intentPlacement == afterDraw` 조건부 렌더링 확인
- `intent_placement.dart`: enum 3값 + extension 확인

모든 파일 경로, 함수명, 라인 번호 기준이 실제 코드와 일치한다.

## 코드 변경

없음 (Cycle 4는 문서 전용).
