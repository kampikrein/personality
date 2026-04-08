---
id: "033"
title: "혼합 아키텍처 최적화 Synthesis — 4관점 교차 분석"
category: report
status: archived
created: 2026-03-16
summary: >
  4개 에이전트 교차 분석. iOS 블랙 플래시 버그(#41156)가 2개 독립 에이전트에서
  동시 발견 — 미해결 리스크 확인. flame_rive 공식 브릿지로 단일 엔진 경로가
  현실적 대안으로 부상. 혼합 유지 시 순차 전환+Flame overlay 패턴으로 최적화 달성 가능.
keywords: [synthesis, hybrid, video_player, Flame, Rive, optimization, iOS-bug, memory]
modules: []
---

# 혼합 아키텍처 최적화 Synthesis

## 팀 구성 & 개별 보고서

| # | 역할 | 보고서 | 상태 |
|---|------|--------|------|
| 1 | 메모리 & GPU 동시 부담 분석가 | [029_Agent_memory_gpu.md](./029_Agent_memory_gpu.md) | 완료 |
| 2 | 전환 병목 & 동기화 오류 분석가 | [030_Agent_transition_sync.md](./030_Agent_transition_sync.md) | 완료 |
| 3 | 단일 엔진 대안 평가 분석가 | [031_Agent_single_engine.md](./031_Agent_single_engine.md) | 완료 |
| 4 | 실제 앱 구현 사례 분석가 | [032_Agent_real_cases.md](./032_Agent_real_cases.md) | 완료 |

---

## Cross-Analysis

### 공통 발견 (2개+ 에이전트 독립 확인)

**iOS 블랙 플래시 버그 (#41156) — 관점 2, 4 동시 발견**
- flutter/flutter GitHub Issue #41156 — iOS AVPlayer 마지막/첫 프레임 블랙 렌더링
- 2026년 1월 현재 **미해결 (P2 등급)** — 40+ 인터랙션에도 방치됨
- 관점 2: 전환 오류 조사에서 발견 / 관점 4: 실제 사례 조사에서 독립 발견
- → **혼합 아키텍처에서 iOS 실기기 테스트가 반드시 선행 필요**

### Synergy 발견 (개별 보고서 조합에서 도출)

**메모리 문제(관점 1) + 단일 엔진(관점 3)의 연결**
- 관점 1: 동시 실행 시 RSS 피크 155~320 MB → 저사양 2GB 기기 HIGH 위험
- 관점 3: Flame + Rive로 video_player 제거 → 피크 RSS가 95~176 MB로 감소
- → **video_player 제거가 메모리 문제의 가장 근본적 해결책**

**전환 동기화(관점 2) + 단일 엔진(관점 3)의 연결**
- 관점 2: 전환 오류는 해결 가능하지만 "설계 의존형" (JSON 번들, 100ms 지연 필수)
- 관점 3: Rive State Machine → 전환 자체가 사라짐 (동일 게임 루프 내 상태 전환)
- → **Rive 채택 시 전환 병목 문제 구조적 제거**

**미개척 영역 확인(관점 4) + 신중한 접근 필요**
- Flutter video_player + Flame 혼합 프로덕션 사례: 존재하지 않음
- 타로 앱 업계 표준: 트윈/스프링 기반 수학 애니메이션 (영상 없음)
- → **이 아키텍처를 채택 시 선도적 구현 → 자체 파일럿 테스트 필수**

### 상충 발견

| 관점 | Flame + Rive 선호 | 현행 혼합 선호 | 이유 |
|------|:---:|:---:|------|
| 메모리(1) | ✅ | — | video_player 제거로 RSS 감소 |
| 전환(2) | ✅ | — | 전환 병목 구조적 제거 |
| 단일 엔진(3) | ✅ | — | flame_rive 브릿지 공식 지원 |
| 실제 사례(4) | — | — | 두 방식 모두 미개척 |
| **품질 우선** | — | ✅ | Blender 포토리얼 품질은 MP4만 가능 |

---

## Comprehensive Conclusion

**두 경로 모두 달성 가능하다. 결정 변수는 손 표현의 '품질 스타일'이다.**

### 경로 A: 혼합 유지 (video_player + Flame) — 최적화 달성 가능
최적화 패턴:
1. 순차 전환 (영상 종료 → dispose() → Flame 활성화, 절대 동시 활성화 금지)
2. Flame GameWidget overlay에 video_player 탑재 (Z-index 문제 제거)
3. isCompleted + 100ms 지연 후 AnimatedOpacity 페이드 아웃
4. Flame 텍스처 Lazy Loading (78장 사전 로딩 금지)
- **단, iOS 실기기 블랙 플래시 테스트 선행 필수**

### 경로 B: 단일 엔진 (Flame + Rive + forge2d) — 더 깔끔한 해법
- flame_rive 공식 브릿지로 Rive + forge2d 완전 공존
- 파일: 50~300 KB (.riv) — MP4 대비 10~25배 작음
- 전환 병목, iOS 버그, 메모리 피크 모두 제거
- **단, 손 표현이 "신비적 2.5D 스타일"로 제한 — 포토리얼리스틱 불가**

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
