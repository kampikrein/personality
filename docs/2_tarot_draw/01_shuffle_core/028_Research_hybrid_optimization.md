---
id: "028"
type: research
title: "타로 셔플 혼합 아키텍처 최적화 — video_player + Flame 동시 실행 부담"
created: 2026-03-16
status: in-progress
traces_scope: "018"
summary: >
  1차 연구 권장 아키텍처(Blender MP4 + video_player + Flame/forge2d)의 실제 모바일
  최적화 우려 검증. video_player + Flame 동시 실행 메모리/GPU 부담, 전환 병목 해결법,
  단일 엔진 대안 가능성을 4개 관점으로 병렬 조사.
keywords: [hybrid architecture, video_player, Flame, memory, GPU, optimization, transition]
parallel_plan:
  total_perspectives: 4
  phases:
    - phase: 1
      perspectives: [1, 2, 3, 4]
      status: completed
      agent_numbers: ["029", "030", "031", "032"]
  synthesis_number: "033"
  final_number: "034"
---

# 타로 셔플 혼합 아키텍처 최적화 (Checkpoint)

## Research Overview

### Background & Motivation
1차 연구에서 도출된 권장 아키텍처:
```
Blender(오프라인) → MP4 → video_player(셔플 영상)
                              ↓ 전환
                         Flame + forge2d (실시간 물리)
```
사용자 우려: "두 시스템이 한 모바일에서 동시에 동작 시 앱이 너무 무거워지는 것 아닌가?"
실제 우려 포인트 (Blender는 모바일에 없음):
- video_player + Flame 두 렌더링 시스템이 동시 메모리 상주 시 부담
- 영상→물리 전환 구간의 동기화 오류, 프레임 점프, 크래시 위험
- 이 복잡성이 감당 불가하면 단일 엔진 대안이 있는가?

### Research Scope
- **포함**: Flutter video_player 메모리 특성, Flame 런타임 footprint, 전환 패턴 오류 사례, 단일 엔진 대안(Flame sprite-sheet, Rive)
- **제외**: Blender 렌더 파이프라인 상세, 물리 엔진 내부 성능(1차 연구에서 완료)

### Research Perspectives
1. **메모리 & GPU 동시 부담** — video_player + Flame 동시 실행 실제 메모리 footprint, GPU 경합 여부
2. **전환 병목 & 동기화 오류** — 영상→물리 전환 타이밍 오류, 프레임 점프, 크래시 패턴과 해결법
3. **단일 엔진 대안 평가** — Flame sprite-sheet/절차적, Rive 2.5D 손 표현 가능성과 품질 트레이드오프
4. **실제 앱 구현 사례** — video + physics 전환 구현 앱/게임 레퍼런스와 업계 패턴

## Preliminary Findings
현재 프로젝트:
- `mobile/lib/features/shuffle/data/datasources/sensor_data_collector.dart` — 센서 수집 이미 구현
- `mobile/pubspec.yaml` — sensors_plus 이미 포함, video_player는 미포함
- Flame은 미포함 (현재 CustomPainter + AnimationController 사용)

## Parallel Execution Instructions

### Perspective 1: 메모리 & GPU 동시 부담 (Agent 029)
조사 목표: video_player + Flame 동시 실행이 실제로 얼마나 무거운가?
WebSearch 키워드:
- "flutter video_player memory usage MB mobile"
- "flutter Flame game memory footprint mobile"
- "flutter video_player + game engine simultaneous memory"
- "flutter widget render pipeline GPU sharing"
- "video_player flutter memory leak OOM Android iOS"
기록 항목:
- video_player 메모리 footprint (초기화 + 재생 중 MB 단위)
- Flame 런타임 메모리 footprint (엔진 초기화 + 78개 body 기준)
- 두 시스템 동시 활성화 시 누적 메모리 위험 수준
- Flutter Impeller 렌더러에서 video_player + Flame GPU 파이프라인 공유 방식
- video_player dispose() 타이밍과 메모리 해제 특성

### Perspective 2: 전환 병목 & 동기화 오류 (Agent 030)
조사 목표: 영상→물리 전환의 실제 오류 패턴과 해결 방법
WebSearch 키워드:
- "flutter video_player to animation transition glitch"
- "flutter AnimatedCrossFade video player transition"
- "mobile game video cutscene to gameplay transition synchronization"
- "flutter video_player frame callback last frame"
- "flutter state transition timing video player physics"
- "video player flutter black flash transition fix"
기록 항목:
- 알려진 video_player 전환 오류: 블랙 플래시, 프레임 점프, 타이밍 불일치
- 마지막 프레임 캡처/고정 방법 (전환 직전)
- AnimatedCrossFade vs AnimatedOpacity vs PageRouteBuilder 전환 방식 비교
- 영상 마지막 프레임 → Flame 초기 레이아웃 좌표 동기화 실제 구현 패턴
- video_player onComplete 콜백 신뢰성 (iOS/Android 차이)

### Perspective 3: 단일 엔진 대안 평가 (Agent 031)
조사 목표: video_player 없이 Flame 단독으로 고품질 손 셔플 표현 가능성
WebSearch 키워드:
- "Flame flutter sprite sheet animation hand 3D look"
- "Rive animation 3D hand flutter mobile"
- "flutter Rive 2.5D character animation"
- "Rive hand rigging animation app"
- "Flame flutter procedural animation card shuffle"
- "Flutter Rive vs video player animation quality"
- "Spine flutter card game animation"
기록 항목:
- Flame sprite-sheet: Blender 렌더 PNG 시퀀스를 Flame SpriteSheeet로 재생 → 품질 vs 파일 크기
- Rive: 2.5D 손 표현 가능 여부, Rive의 bone/mesh warping 기능, 모바일 성능
- Rive 라이선스: 상업 무료 조건
- Flame sprite-sheet + forge2d 물리 통합 방식 (video_player 제거)
- 단일 엔진(Flame only) 구현 시 품질 손실 수준 추정

### Perspective 4: 실제 앱 구현 사례 (Agent 032)
조사 목표: video + physics 전환을 실제 앱/게임에서 어떻게 구현했는가?
WebSearch 키워드:
- "mobile game flutter video player physics game loop"
- "Flutter app video cutscene realtime gameplay"
- "card game app video animation flutter production"
- "mobile game pre-rendered cutscene transition implementation"
- "flutter video_player game integration production app"
- "tarot app iOS Android video animation implementation"
기록 항목:
- 실제 Flutter 앱에서 video_player + 게임 엔진 혼합 사례
- 비Flutter 모바일 게임에서 컷신→게임플레이 전환 구현 패턴
- 앱스토어 성공 사례의 기술 스택 (video 재생 + 물리)
- 업계 표준: 어느 규모의 앱이 이 패턴을 사용하는가?
- 실패 사례와 회피 전략

## Remaining Work
- [ ] Perspective 1: 메모리 & GPU 동시 부담
- [ ] Perspective 2: 전환 병목 & 동기화 오류
- [ ] Perspective 3: 단일 엔진 대안 평가
- [ ] Perspective 4: 실제 앱 구현 사례
- [ ] Cross-Analysis
- [ ] Comprehensive Conclusion

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
