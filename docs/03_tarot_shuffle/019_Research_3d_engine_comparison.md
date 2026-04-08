---
id: "019"
type: research
title: "타로 셔플 3D 엔진 비교 연구"
created: 2026-03-16
status: in-progress
traces_scope: "018"
summary: >
  타로 카드 셔플 애니메이션의 3D 업그레이드를 위한 엔진 후보(Flame, three_dart, Unity,
  Godot, Babylon.js, Flutter 내장 등) 비교 연구. 평가 기준: 무료, 3D품질/손표현, 모바일 부담.
  프리렌더 vs 실시간 혼합 전략 타협점 포함.
keywords: [3D engine, Flutter, tarot, shuffle, physics, Unity, Godot, three_dart, Flame, Babylon.js]
parallel_plan:
  total_perspectives: 5
  phases:
    - phase: 1
      perspectives: [1, 2, 3]
      status: completed
      agent_numbers: ["020", "021", "022"]
    - phase: 2
      perspectives: [4, 5]
      status: completed
      agent_numbers: ["024", "025"]
  synthesis_number: "023"
  final_number: "027"
---

# 타로 셔플 3D 엔진 비교 연구 (Checkpoint)

## Research Overview

### Background & Motivation
현재 타로 셔플 애니메이션은 Flutter `CustomPainter` 2D Canvas 기반이다 (riffle_animation_controller.dart, card_painter.dart).
사용자 요구사항:
1. 손이 등장해 카드를 섞는 3D 모션 (손가락 단위 표현)
2. 손가락-카드 물리 충돌 반응
3. 폰 기울이기/흔들기 → 가속도계 기반 실시간 물리 (카드 중력 방향 쏠림)
4. 프리렌더 고품질 + 실시간 인터랙션 혼합 방식
5. Flutter 통합, 무료, 모바일 성능 우선

### Research Scope
- **포함**: Flame, three_dart+flutter_gl, Unity+flutter_unity_widget, Godot4+브리지, Babylon.js+WebView, Flutter내장(Matrix4+FragmentShader)
- **제외**: 구현 코드, 스크린샷, 성능 실측 (레퍼런스/공식문서 기반 분석)

### Research Perspectives
1. **라이선스 & 비용** — 상업 무료 조건, 수익 제한, 로열티, 플랫폼 제한 정확한 현황
2. **3D 품질 & 손/손가락 표현** — skeletal animation, bone rigging 지원 수준, 손 모션 레퍼런스
3. **물리 엔진 & 센서 연동** — rigid body collision, 가속도계→중력 연동, 모바일 실시간 성능
4. **Flutter 통합 & 모바일 부담** — 통합 방식(PlatformView/WebView/플러그인), APK 크기, GPU/CPU/배터리
5. **프리렌더 vs 실시간 혼합 전략** — 고품질 프리렌더 + 실시간 인터랙션 타협 패턴

### 현재 프로젝트 컨텍스트 (조사 전 사전 파악)
- Flutter 3.29+, Dart 3.6+
- sensors_plus 이미 포함 (가속도계 데이터 수집 가능)
- 2D CustomPainter 기반 → 완전 교체 또는 오버레이 방식 가능
- Drift SQLite, Riverpod 상태관리

## Preliminary Findings
병렬 조사 시작 전. 초기 가정:
- Unity는 Personal 플랜 기준 연 $10만 미만 무료 (변경 가능성 있음 — 확인 필요)
- three_dart는 pub.dev에 존재하나 유지보수 상태 불명확
- Flame은 2D 게임 엔진, flame_3d는 experimental

## Parallel Execution Instructions

### Phase 1 Perspectives

#### Perspective 1: 라이선스 & 비용 (Agent 020)
**조사 대상**: 각 엔진의 공식 라이선스 페이지 및 최신 정책 변경사항

**조사 엔진 목록:**
1. Unity (Unity Personal / Unity Student / Unity Free 플랜)
2. Godot 4.x (MIT License)
3. Flame (BSD-3-Clause)
4. three_dart (MIT)
5. Babylon.js (Apache 2.0)
6. Flutter 내장 (BSD-3-Clause)

**조사 방법:**
- WebSearch: "{엔진명} license commercial use 2024 2025"
- WebSearch: "Unity Personal plan revenue limit 2024 2025"
- WebSearch: "flutter_unity_widget license"
- WebFetch: 공식 라이선스 페이지

**기록할 항목:**
- 정확한 라이선스 종류 (MIT/Apache/BSD/상용 등)
- 상업적 무료 사용 조건 (수익 제한액, 유저 수, 플랫폼 제한)
- 로열티 조항 유무
- 플랫폼 제한 (iOS/Android 특이사항)
- 최근 정책 변경 이력 (Unity의 2023 런타임 요금 사태 등)
- 실제 인디/상업 앱 적용 사례에서의 비용 구조

**핵심 질문:**
- Unity는 2024-2025 기준 정확히 어떤 조건에서 무료인가?
- 플러터 통합 플러그인(flutter_unity_widget)의 라이선스는?
- 각 엔진을 앱스토어 상업 출시에 사용할 때 제약이 있는가?

#### Perspective 2: 3D 품질 & 손/손가락 표현 (Agent 021)
**조사 대상**: 각 엔진의 skeletal animation, 손 모션 구현 능력

**조사 방법:**
- WebSearch: "{엔진명} skeletal animation hand finger 3D mobile"
- WebSearch: "Unity hand animation mobile app card game"
- WebSearch: "Godot 4 hand animation rigging tutorial"
- WebSearch: "three_dart flutter 3D animation example"
- WebSearch: "Babylon.js WebView Flutter card animation"
- WebFetch: 실제 레퍼런스 프로젝트 GitHub, YouTube 영상 설명

**기록할 항목:**
- 각 엔진의 bone rigging / skeletal animation 지원 여부
- 손/손가락 수준의 세밀한 3D 표현 가능 여부 (폴리곤 수 제한 등)
- 실제 모바일 카드 게임 또는 손 모션 앱 레퍼런스 URL
- PBR (Physically Based Rendering) 지원 여부 (카드 광택 등)
- 셰이더/재질 지원 수준 (타로 카드의 신비로운 시각 효과)
- 프리렌더 애니메이션 (pre-baked animation clip) 지원 방식

**핵심 질문:**
- 손 + 손가락 수준의 3D 표현이 가능한 엔진은?
- 모바일에서 실제로 고품질 손 모션이 구현된 사례가 있는가?
- 카드 셔플 특유의 부채꼴 배치, 인터리빙, 컷 동작을 어떤 엔진이 가장 잘 표현하는가?

#### Perspective 3: 물리 엔진 & 센서 연동 (Agent 022)
**조사 대상**: 각 엔진의 물리 시뮬레이션 능력과 모바일 센서 연동

**조사 방법:**
- WebSearch: "{엔진명} physics engine rigid body collision mobile performance"
- WebSearch: "Unity physics mobile accelerometer gyroscope"
- WebSearch: "Godot 4 physics 3D mobile performance benchmark"
- WebSearch: "Flame physics flutter accelerometer card game"
- WebSearch: "flutter physics simulation accelerometer tilt cards"
- WebSearch: "Box2D Bullet physics mobile performance comparison"

**기록할 항목:**
- 내장 물리 엔진 종류 (Box2D, Bullet Physics, Jolt, 자체 등)
- 2D vs 3D 물리 분리 여부
- rigid body collision detection 정밀도 (카드 수십 장 동시 충돌)
- 가속도계 데이터 → 물리 엔진 gravity/force 입력 방식
- 모바일에서 카드 50-78장 동시 물리 시뮬레이션 성능 (FPS 데이터 있으면 포함)
- 물리 연산 CPU/GPU 분리 여부
- 충돌 레이어, 마찰, 탄성 계수 제어 수준

**핵심 질문:**
- 폰 기울이기 → 카드들이 중력 방향으로 쏠리는 효과를 가장 자연스럽게 구현 가능한 엔진은?
- 타로 카드 78장 동시 물리 시뮬레이션 시 모바일에서 60fps 가능한 엔진은?
- sensors_plus(Flutter)에서 수집한 가속도계 데이터를 각 엔진의 물리에 전달하는 방식은?

### Phase 2 Perspectives

#### Perspective 4: Flutter 통합 & 모바일 부담 (Agent 024)
**조사 대상**: 각 엔진의 Flutter 통합 방식과 실제 모바일 부담

**조사 방법:**
- WebSearch: "flutter_unity_widget integration guide 2024 2025"
- WebSearch: "flutter three_dart flutter_gl integration example"
- WebSearch: "flutter Godot integration native platform view"
- WebSearch: "flutter_inappwebview Babylon.js performance mobile"
- WebSearch: "Flame game engine APK size overhead"
- WebSearch: "Unity Flutter APK size increase"
- WebFetch: flutter_unity_widget GitHub README
- WebFetch: flutter_gl pub.dev

**기록할 항목:**
- 통합 방식: PlatformView / MethodChannel / WebView / 동일 프로세스 / 별도 엔진 프로세스
- APK 크기 증가량 (엔진 추가 전후 비교 데이터 있으면 포함)
- GPU 메모리 사용량 (VRAM 기준)
- CPU 오버헤드 (렌더링 스레드 분리 여부)
- 배터리 소모 패턴 (실제 측정값 있으면 포함)
- Hot reload / Hot restart 지원 여부 (개발 편의성)
- 저사양 기기 대응 (안드로이드 중저가 폰 기준)
- 통합 안정성 (이슈 트래커, 마지막 업데이트 날짜)

**핵심 질문:**
- 어떤 통합 방식이 Flutter 앱과 가장 낮은 오버헤드로 결합하는가?
- PlatformView vs WebView 방식의 실제 성능 차이는?
- APK 크기가 50MB 이하를 유지할 수 있는 엔진은?

#### Perspective 5: 프리렌더 vs 실시간 혼합 전략 (Agent 025)
**조사 대상**: 고품질 프리렌더 + 실시간 인터랙션 혼합 구현 패턴

**조사 방법:**
- WebSearch: "pre-rendered animation realtime interaction hybrid mobile game"
- WebSearch: "Unity pre-baked animation realtime physics blend mobile"
- WebSearch: "Godot AnimationPlayer blend realtime physics"
- WebSearch: "video texture overlay physics Flutter mobile"
- WebSearch: "tarot card shuffle animation 3D mobile app implementation"
- WebSearch: "card game hand animation pre-rendered realtime hybrid"
- WebSearch: "flutter video player physics overlay card animation"
- WebFetch: 관련 개발자 블로그, GDC Talk 자료

**기록할 항목:**
- 프리렌더 방식 종류: 영상 파일(.mp4/.webm), 스프라이트 시트, 골격 애니메이션 클립
- 실시간 물리와 프리렌더 합성 기법 (오버레이, blend tree, state machine)
- 각 엔진별 pre-baked animation + realtime physics 조합 지원 방식
- Flutter에서 프리렌더 영상 + 실시간 위젯 오버레이 패턴 (video_player + CustomPainter)
- 타로/카드 게임 앱에서의 실제 적용 사례
- 저사양 기기를 위한 폴백 전략 (고품질 ↔ 저품질 전환)
- 파일 크기 vs 품질 트레이드오프 (영상 파일 vs 실시간 렌더)

**핵심 질문:**
- 손이 등장하는 고품질 셔플 시퀀스는 프리렌더가 맞는가, 실시간이 맞는가?
- 프리렌더 손 모션 + 실시간 물리 카드 인터랙션을 가장 자연스럽게 합치는 방법은?
- Flutter 앱에서 이 혼합 방식을 구현하는 실증된 패턴은?

## Remaining Work
- [ ] Perspective 1: 라이선스 & 비용
- [ ] Perspective 2: 3D 품질 & 손/손가락 표현
- [ ] Perspective 3: 물리 엔진 & 센서 연동
- [ ] Perspective 4: Flutter 통합 & 모바일 부담
- [ ] Perspective 5: 프리렌더 vs 실시간 혼합 전략
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
