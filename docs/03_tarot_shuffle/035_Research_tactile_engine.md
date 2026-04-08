---
id: "035"
type: research
title: "타로 셔플 조작감 우선 엔진 재검토 — Rive + Flame + forge2d 기반"
created: 2026-03-16
status: in-progress
traces_scope: "018"
summary: >
  일러스트 손(Rive 2.5D) 확정 후 조작감 최우선 기준으로 Flame + forge2d 아키텍처를
  재검토. 물리 파라미터, Rive-forge2d 연동 latency, 대안 엔진, 카드 손맛 구현 사례,
  가속도계 응답성 5개 관점 병렬 조사.
keywords: [tactile, forge2d, Rive, Flame, physics, sensors_plus, haptic, card-game, latency]
parallel_plan:
  total_perspectives: 5
  phases:
    - phase: 1
      perspectives: [1, 2, 3]
      status: completed
      agent_numbers: ["036", "037", "038"]
    - phase: 2
      perspectives: [4, 5]
      status: completed
      agent_numbers: ["039", "040"]
  synthesis_number: "041"
  final_number: "042"
---

# 타로 셔플 조작감 우선 엔진 재검토

## Research Overview

### Background & Motivation
이전 연구(034)에서 경로 B 확정: Rive 2.5D 일러스트 손 + Flame + forge2d 단일 엔진.
사용자 최우선 가치: **조작감(tactile feel, interaction responsiveness)**.
- 포토리얼 포기 → 조작감이 콘텐츠의 핵심
- 카드를 손으로 밀었을 때의 "물리적 반응감"이 서비스 품질을 결정
- 이 조건에서 현재 선택한 Rive + Flame + forge2d가 최선인지, 더 나은 대안이 있는지 검토

### Research Scope
- 포함: forge2d 물리 파라미터, Rive-forge2d latency, 대안 물리 엔진, 카드 손맛 구현 기법, 가속도계 응답성
- 제외: Rive 손 디자인 상세, 서버/백엔드, UI 레이아웃

### Research Perspectives
1. **조작감의 물리 파라미터** — forge2d에서 "손맛"을 결정하는 핵심 수치와 튜닝 방법
2. **Rive ↔ forge2d 연동 latency** — bone 좌표 추출 → body 업데이트 루프의 실제 응답 지연
3. **조작감 특화 물리 엔진 대안** — forge2d vs 커스텀 스프링-댐퍼 vs 기타 Dart 물리 라이브러리
4. **카드 게임 손맛 구현 사례** — 실제 앱/게임의 카드 조작감 기법 (드래그 반응, 햅틱, 관성)
5. **sensors_plus 가속도계 응답성** — 샘플링 레이트, 필터링, forge2d gravity 실시간 업데이트

## Preliminary Findings
현재 프로젝트:
- `mobile/pubspec.yaml`: sensors_plus 포함, forge2d/Flame/Rive 미포함
- `mobile/lib/features/shuffle/`: CustomPainter 기반 2D (forge2d 미사용)
- 조작감 구현 코드 없음 — 완전 신규 설계 필요

## Parallel Execution Instructions

### Perspective 1: 조작감의 물리 파라미터 (Agent 036)
저장: docs/11_tarot_shuffle/036_Agent_physics_params.md

조사 목표: forge2d에서 "카드를 손으로 밀었을 때의 물리적 반응감"을 결정하는 파라미터와 실제 튜닝 값

WebSearch 키워드:
- "forge2d flutter physics parameters friction restitution card game"
- "Box2D card game physics feel tuning friction density"
- "flutter forge2d body linear damping angular damping feel"
- "Box2D 2D physics card flick feel parameters"
- "flutter forge2d impulse apply force card interaction"

기록 항목:
- friction (마찰계수): 카드-바닥, 카드-카드 권장 값 범위
- restitution (반발계수): 튕김 정도 — 타로 카드 느낌에 적합한 수치
- linearDamping / angularDamping: 카드가 멈추는 속도감 (너무 빨리/느리게 멈추면 조작감 저하)
- density (밀도): 카드 질량감 — 가볍게 vs 묵직하게
- applyLinearImpulse vs applyForce: 즉각적 충격 vs 지속력 — 셔플 조작에 맞는 방식
- 카드 스택(78장) 물리 처리 성능 — body 수 vs 성능 트레이드오프
- 핵심 결론: 조작감 튜닝에 가장 영향이 큰 파라미터 순위

### Perspective 2: Rive ↔ forge2d 연동 Latency (Agent 037)
저장: docs/11_tarot_shuffle/037_Agent_rive_forge2d_latency.md

조사 목표: Rive bone 위치를 forge2d body에 반영할 때 발생하는 응답 지연과 해결법

WebSearch 키워드:
- "flame_rive flutter rive component position sync forge2d"
- "flutter Rive artboard bone position extract runtime"
- "Flame forge2d kinematic body position update per frame"
- "flutter game loop update dt rive animation sync physics"
- "flame_rive RiveComponent forge2d BodyComponent integration"

기록 항목:
- Rive bone 좌표 추출 API: 공식 방법 (artboard.bone(), StateMachineController)
- Flame update(dt) 내 Rive → forge2d 좌표 동기화 순서
- KinematicBody vs StaticBody: 손 충돌체로 어느 타입이 적합한가
- 프레임 지연 가능성: Rive 렌더와 forge2d 물리 계산 순서 차이
- 60fps 보장 조건: Rive + forge2d 동시 실행 시 성능 병목 지점
- 핵심 결론: latency가 조작감에 영향을 줄 수준인가, 무시 가능한가

### Perspective 3: 조작감 특화 물리 엔진 대안 (Agent 038)
저장: docs/11_tarot_shuffle/038_Agent_physics_alternatives.md

조사 목표: 조작감 우선 기준에서 forge2d 외 더 나은 대안이 있는가?

WebSearch 키워드:
- "flutter custom spring damper physics card animation"
- "dart physics engine alternative forge2d 2024"
- "flutter card game physics without game engine custom"
- "spring damping simulation flutter card feel"
- "flutter gesture physics velocity fling card interaction"
- "flutter Simulation class physics spring card drag"

기록 항목:
- Flutter 내장 Simulation 클래스 (SpringSimulation, FrictionSimulation): forge2d 없이 조작감 구현 가능성
- 커스텀 스프링-댐퍼: 단순 수식(Hooke's Law + 감쇠)으로 카드 1장 조작감 구현 난이도
- Dart용 대안 물리 라이브러리 현황 (2024~2025)
- forge2d 사용 vs 커스텀 구현: 78장 카드 동시 물리 처리 성능 비교
- 카드 드래그-릴리즈 시 "자연스러운 튕김" 구현 방식
- 핵심 결론: forge2d가 조작감 목적에 최선인가, 커스텀이 더 나은가

### Perspective 4: 카드 게임 손맛 구현 사례 (Agent 039)
저장: docs/11_tarot_shuffle/039_Agent_card_feel_cases.md

조사 목표: 실제 카드 게임 앱/게임에서 "손맛(tactile feel)"을 구현하기 위해 사용하는 기법

WebSearch 키워드:
- "mobile card game flutter haptic feedback swipe feel"
- "iOS HapticFeedback card game flutter implementation"
- "card game flutter drag physics snap animation feel"
- "mobile solitaire card game physics implementation flutter"
- "flutter card flip drag gesture physics spring feel"
- "hearthstone mobile card interaction physics feel implementation"

기록 항목:
- 실제 카드 게임 앱의 드래그 반응 구현 (velocity 기반 릴리즈, snap 포인트)
- 햅틱 피드백: HapticFeedback.mediumImpact() 등 — 카드 집을 때, 놓을 때, 충돌 시
- 카드 들어올리기 애니메이션: 그림자 효과, 크기 변화로 "집었다는 느낌" 주기
- Flutter GestureDetector + velocity 기반 fling 구현 패턴
- 카드 스택에서 한 장 분리 시 자연스러운 분리감 구현
- 핵심 결론: 조작감에 가장 기여하는 상위 3개 기법

### Perspective 5: sensors_plus 가속도계 응답성 (Agent 040)
저장: docs/11_tarot_shuffle/040_Agent_accelerometer_response.md

조사 목표: 폰 기울이기 → 카드 중력 방향 실시간 변경의 실제 응답성 측정

WebSearch 키워드:
- "sensors_plus flutter accelerometer sample rate Hz"
- "flutter accelerometer to game physics gravity update lag"
- "sensors_plus flutter accelerometer low pass filter smooth"
- "forge2d gravity update per frame flutter accelerometer"
- "flutter accelerometer response time game tilt control"
- "sensors_plus flutter iOS Android accelerometer difference"

기록 항목:
- sensors_plus 가속도계 샘플링 레이트: iOS/Android 기본값 (Hz)
- Flame update(dt)와 accelerometerEventStream 비동기 처리 방식
- 로우패스 필터(low-pass filter): 떨림 없는 자연스러운 기울기 반응 구현법
- forge2d World.gravity 실시간 변경 API와 성능
- "즉각적 반응" vs "부드러운 반응" 트레이드오프 — 타로 셔플에 맞는 설정
- iOS vs Android 가속도계 응답성 차이
- 핵심 결론: 기울이기 조작감이 즉각적으로 느껴지는 구성 조건

## Remaining Work
- [ ] Perspective 1: 조작감의 물리 파라미터
- [ ] Perspective 2: Rive ↔ forge2d 연동 latency
- [ ] Perspective 3: 조작감 특화 물리 엔진 대안
- [ ] Perspective 4: 카드 게임 손맛 구현 사례
- [ ] Perspective 5: sensors_plus 가속도계 응답성
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
