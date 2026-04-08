---
id: "025"
type: scope
title: "비평 기반 MVP 개선 — Quick Fix + 제의적 레이어"
created: 2026-03-16
complexity: complex
research_needed: false
research_reason: "비평 보고서(013-017)가 구체적 코드 위치와 수정 방안을 이미 제시. 추가 연구 불필요."
auto_run: true
intent: >
  4개 전문 에이전트 비평(Flutter 아키텍처, 제의적 UX, 타로 도메인, 심리학적 안전성)에서
  도출된 Critical/High/Medium 이슈를 2사이클로 구현. 기술적 품질 + 제의적 경험 + 심리적
  안전성을 동시에 개선.
summary: >
  2개 영역, 2개 사이클. Cycle 1: 기존 코드 Quick Fix + UX Polish (~12파일 수정).
  Cycle 2: 제의적 경험 레이어 추가 (신규 엔티티/화면 ~10파일). research 불필요.
keywords: [critique-improvement, quick-fix, ritual-layer, safety, ux-polish]
cycles:
  - cycle: 1
    area: "Quick Fix + UX Polish"
    depends_on: []
    research_needed: false
  - cycle: 2
    area: "제의적 경험 레이어"
    depends_on: [1]
    research_needed: false
---

# 비평 기반 MVP 개선

## 작업 목표
- 4개 비평 보고서(013-017)의 Critical/High/Medium 이슈 전체 적용
- 성공 기준: flutter analyze 0 이슈 + 에뮬레이터 E2E 통과 + 제의적 흐름 완성

## 접근 방향
2사이클 순차 실행. Cycle 1은 기존 파일 수정만(신규 파일 없음), Cycle 2는 신규 엔티티/화면 추가.

## Research 판단
- **판단**: 불필요
- **근거**: 비평 보고서가 코드 위치, 수정 코드, 학술 근거까지 모두 제시
- **파이프라인**: S → P → I(V) × 2 사이클

## 영역 식별

| # | 영역 | 주요 파일/모듈 | 설명 |
|---|------|-------------|------|
| 1 | Quick Fix + UX Polish | shuffle/, reading/, core/ 기존 파일 | 기술 수정 + UX 개선 (수정만) |
| 2 | 제의적 경험 레이어 | 신규 엔티티 + 화면 + 기존 수정 | ReadingSession, 반성질문, 앰비언스 |

## 실행 순서

| 사이클 | 영역 | 선행 조건 | Research | 파이프라인 |
|--------|------|---------|----------|-----------|
| 1 | Quick Fix + UX Polish | 없음 | 불필요 | P→I(V) |
| 2 | 제의적 경험 레이어 | 사이클 1 | 불필요 | P→I(V) |

### Cycle 1: Quick Fix + UX Polish (기존 파일 수정만)

**기술적 보강 (013 Flutter 비평)**:
- [ ] reading_dao.dart: deleteReading을 transaction()으로 래핑
- [ ] shuffle_page.dart: _startShuffle에 try-catch + SnackBar 에러 피드백
- [ ] cards_table.dart: FK에 onDelete: KeyAction.cascade 추가
- [ ] decks_table/readings_table: FK 관련 cascade 설정
- [ ] card_painter.dart: shouldRepaint 최적화 (cardPositions 비교)

**UX Polish (014 UX 비평)**:
- [ ] app_router.dart: 모든 route를 pageBuilder + FadeTransition(600ms)으로 교체
- [ ] riffle_animation_controller.dart: CurvedAnimation(easeInOut) 적용
- [ ] card_painter.dart: 카드 크기 0.15 → 0.22
- [ ] card_reveal_widget.dart: perspective 0.001 → 0.002 + 뒤집기 햅틱 추가
- [ ] card_reveal_widget.dart: Semantics 위젯 래핑
- [ ] entropy_progress_indicator.dart: 고정 200px → 반응형 너비

**도메인 + 안전 (015 타로, 016 심리학 비평)**:
- [ ] shuffle_config.dart: reversalProbability 0.5 → 0.33 기본값
- [ ] shuffle_page.dart: 센서 폴백 언어 재프레이밍 ("우주가 카드를 배열합니다")
- [ ] reading_page.dart: 심리적 안전 고지 면책 문구 + 위기상담 연결
- [ ] entropy_pool.dart: 투명성 문구용 주석/문서화
- [ ] card_reveal_widget.dart: 역방향 라벨에 안내 문구 추가 ("에너지가 내면으로 향합니다")

### Cycle 2: 제의적 경험 레이어 (신규 + 수정)

**신규 엔티티/모델**:
- [ ] reading_session.dart: ReadingSession freezed (question, intention, spread, closure)
- [ ] reflective_prompts.dart: 카드별 반성 질문 데이터
- [ ] spread_type.dart 확장: SpreadPosition에 해석 가이드 메타데이터

**신규 화면/위젯**:
- [ ] intention_page.dart: 질문/의도 설정 화면 (셔플 전 진입)
- [ ] reading_page.dart 대폭 수정: 반성 질문 표시 + 저널링 프롬프트
- [ ] home_page.dart: RadialGradient 배경 + 앰비언트 심볼

**기존 수정**:
- [ ] app_router.dart: /intention 라우트 추가
- [ ] spread_type.dart: 포지션 라벨 재설계 ('미래' → '에너지의 방향')
- [ ] shuffle_page.dart: "셔플 중..." → 절정 시각 표현
- [ ] main.dart: ReadingSession Provider 연결

## 체크포인트 & 컨텍스트 관리

| 체크포인트 | 산출물 | 컨텍스트 조치 | 판단 기준 |
|-----------|--------|-------------|----------|
| /scope 완료 | 이 문서 | 유지 | scope 탐색 파일 = makeplan 참조 파일 |
| Cycle 1 makeplan | Plan 문서 | 유지 | plan 읽은 파일 = impl 수정 파일 |
| Cycle 1 impl+verify | 커밋 | /compact | Cycle 2는 다른 영역 |
| Cycle 2 makeplan | Plan 문서 | 유지 | plan 읽은 파일 = impl 수정 파일 |
| Cycle 2 impl+verify | 커밋 | 완료 | — |

## 변경 대상 파일 요약

### Cycle 1 (~15 파일 수정)
| File | Changes |
|------|---------|
| reading_dao.dart | transaction 래핑 |
| shuffle_page.dart | try-catch, 폴백 언어, 엔트로피 투입 개선 |
| cards_table.dart | cascade delete |
| card_painter.dart | shouldRepaint, 카드 크기 |
| app_router.dart | FadeTransition |
| riffle_animation_controller.dart | easing curve |
| card_reveal_widget.dart | Semantics, 햅틱, perspective, 역방향 안내 |
| entropy_progress_indicator.dart | 반응형 너비 |
| shuffle_config.dart | reversalProbability 0.33 |
| reading_page.dart | 안전 고지 |
| app_theme.dart | 추가 TextStyle 정의 |

### Cycle 2 (~10 파일 신규+수정)
| File | Type |
|------|------|
| reading_session.dart | 신규 |
| reflective_prompts.dart | 신규 |
| intention_page.dart | 신규 |
| spread_type.dart | 대폭 수정 |
| reading_page.dart | 대폭 수정 |
| home_page.dart | 대폭 수정 |
| app_router.dart | 라우트 추가 |
| shuffle_page.dart | 절정 표현 |
| main.dart | Provider 추가 |

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
