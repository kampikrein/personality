---
id: "027"
type: research
title: "타로 셔플 3D 엔진 비교 연구 — 최종 보고서"
created: 2026-03-16
traces_scope: "018"
summary: >
  타로 셔플 앱을 위한 3D 엔진 후보 5개 관점 비교 결과. 최종 권장 아키텍처:
  Blender(무료, GPL) 오프라인 렌더링으로 고품질 손 셔플 MP4 생성 +
  Flutter 내 Flame/forge2d로 가속도계 기반 실시간 카드 물리 처리.
  Unity/Godot의 Flutter 통합 실용성 한계가 결정적 전환 근거.
keywords: [3D engine, Flutter, tarot shuffle, Blender, Flame, forge2d, pre-render, physics, sensors_plus]
---

# 타로 셔플 3D 엔진 비교 연구 — 최종 보고서

## Research Overview

### Background & Motivation
현재 타로 셔플 애니메이션(`riffle_animation_controller.dart`, `card_painter.dart`)은
Flutter `CustomPainter` 2D Canvas 기반이다. 사용자 요구사항:
1. 손이 등장해 카드를 섞는 3D 모션 (손가락 단위 표현)
2. 손가락-카드 물리 충돌 반응
3. 폰 기울이기/흔들기 → 가속도계 기반 실시간 물리 (카드 중력 쏠림)
4. 프리렌더 고품질 + 실시간 인터랙션 혼합
평가 기준 (우선순위): 무료 > 품질 > 모바일 부담

### Research Scope
- 조사 엔진: Unity URP, Godot 4, Flame+flame_3d, three_dart+flutter_gl, Babylon.js+WebView, Flutter 내장
- 5개 관점, 2페이즈 병렬 조사 (5개 에이전트 보고서)

### Research Perspectives
1. **라이선스 & 비용** — 상업 무료 조건 정확한 현황
2. **3D 품질 & 손/손가락 표현** — skeletal animation, bone rigging, 실제 사례
3. **물리 엔진 & 센서 연동** — rigid body, 가속도계→gravity, 모바일 성능
4. **Flutter 통합 & 모바일 부담** — APK 크기, GPU/CPU/배터리, 안정성
5. **프리렌더 vs 실시간 혼합 전략** — 고품질 프리렌더 + 실시간 인터랙션 타협점

### Related Documents
- Checkpoint: [019_Research_3d_engine_comparison.md](./019_Research_3d_engine_comparison.md)
- 020: [라이선스 & 비용](./020_Agent_license_cost.md)
- 021: [3D 품질 & 손 표현](./021_Agent_3d_quality_hand.md)
- 022: [물리 & 센서 연동](./022_Agent_physics_sensor.md)
- 023: [Phase 1 Synthesis](./023_Synthesis_3d_engine_phase1.md)
- 024: [Flutter 통합 & 모바일 부담](./024_Agent_flutter_integration.md)
- 025: [프리렌더 vs 실시간 혼합](./025_Agent_prerender_realtime.md)
- 026: [Phase 2 Synthesis](./026_Synthesis_3d_engine_phase2.md)

---

## 엔진별 종합 스코어카드

| 엔진 | 라이선스 | 3D 품질/손 | 물리/센서 | Flutter 통합 | 혼합 전략 | **최종** |
|------|---------|-----------|---------|------------|---------|--------|
| **Flame** | ✅ MIT | ❌ 3D 손 불가 | ✅ forge2d 최적 | ✅ +2~5MB, iOS/Android | ✅ 물리 레이어 | **채택** |
| **Blender** | ✅ GPL(출력물 자유) | ✅✅ Cycles 최고 | — | — | ✅ 프리렌더 도구 | **채택** |
| **Godot 4** | ✅ MIT | ✅ Skeleton3D | ✅ Jolt | ❌ **iOS 미지원**, SurfaceView 충돌 | — | **탈락** |
| **Unity URP** | ⚠️ 조건부 + 비게임 ❌ | ✅✅ 최고 | ✅ PhysX | ❌ APK +60~200MB | ❌ 비게임 라이선스 | **탈락** |
| **Babylon.js** | ✅ Apache 2.0 | ✅ PBR 완전 | ❌ iOS <16.4 Havok 불가 | ⚠️ WebView 불안정 | — | **보조** |
| **Flutter 내장** | ✅ BSD-3 | ❌ pseudo-3D | ❌ 78장 O(n²) | ✅ 네이티브 | ✅ 폴백 | **폴백** |
| **three_dart** | ✅ MIT | ❌ 3년 미업데이트 | ❌ cannon 미성숙 | ❌ | — | **탈락** |
| **flame_3d** | ✅ MIT | ❌ experimental | ❌ | — | — | **탈락** |

---

## Perspective 1: 라이선스 & 비용

### 상태 분석

**완전 무료 무제한 상업 사용 (4개):**
- Flame (MIT) — pub.dev 활발히 유지보수 중 (v1.36.0, 2026년 3월)
- Godot 4 (MIT) — 완전 무료이나 Flutter 통합 문제로 실용성 없음 (관점 4에서 탈락)
- Babylon.js (Apache 2.0) — 무료이나 모바일 물리 한계로 제한적 활용
- Flutter 내장 / Blender (BSD-3/GPL) — 출력물 상업 사용 자유

**조건부 또는 문제 있음:**
- Unity Personal: 연 $200K 수익 한도 + 비게임 앱 Industrial 플랜 요구($4,950/년) + 정책 변경 이력

**탈락:**
- three_dart/flutter_gl: MIT이지만 2022년 이후 유지보수 중단

### 핵심 발견
Blender는 GPL이지만 **렌더링 출력물(MP4, PNG)은 저작권자(개발자) 소유**로 상업 앱에 완전히 자유롭게 포함 가능 — Blender 공식 문서 명시.

---

## Perspective 2: 3D 품질 & 손/손가락 표현

### 상태 분석

**3D 손 표현 가능:**
- Unity URP: Humanoid rig 15 bone/hand, Muscle 시스템, Animation Rigging, Shader Graph PBR → 최고 품질이나 Flutter 통합 불가
- Godot 4: Skeleton3D, SkeletonModifier3D(4.4+), set_bone_pose_rotation() 직접 제어 → iOS 통합 불가
- Babylon.js: Bone API 완전 지원, GLTF auto-rig, PBRMaterial → 모바일 물리 불안정

**3D 손 표현 불가:**
- Flame/flame_3d: experimental, skeletal animation 미구현
- Flutter Matrix4: pseudo-3D, 실제 3D geometry 없음
- three_dart: 3년 미업데이트, GLTF 버그

**타로 카드 시각 효과 (홀로그램, 금박, 광택):**
- Blender Cycles: 오프라인 렌더링으로 최고 품질 구현 가능 (렌더 시간 제한 없음)
- 실시간에서는 Flame + FragmentShader (GLSL)로 shimmer/glow 효과 구현 가능

### 핵심 발견
현존 타로 앱 중 3D 손 애니메이션 구현 사례 없음 → **프리렌더 방식으로 구현 시 강력한 UX 차별화 포인트**.

---

## Perspective 3: 물리 엔진 & 센서 연동

### 상태 분석

**78장 카드 실시간 물리 가능 (모바일 60fps):**
- Flame/forge2d: Box2D Dart 포트, sensors_plus 스트림 → `world.setGravity()` 5줄 연동, 2D 전용
- Godot 4 (Jolt): GodotPhysics 대비 2-3× 성능, 3D rigid body 수백 개, `Input.get_gravity()` → PhysicsServer3D. 단, iOS Flutter 통합 불가

**불가:**
- Flutter 순수 물리: O(n²) 충돌 연산, iPhone6 CPU 90~100%, 30개 이하로 제한
- Babylon.js Havok: iOS <16.4 WASM SIMD 미지원
- three_dart + cannon_physics: GitHub 스타 6개, 프로덕션 위험

**가속도계 연동 복잡도 비교:**
- Flame: 🟢 최단 (sensors_plus 스트림 직접 연결, 동일 앱 내)
- Godot/Unity: 🟡 중간 (MethodChannel 경유)
- Babylon.js: 🔴 복잡 (Flutter→JS 브리지, DeviceMotion API)

### 핵심 발견
가속도계 노이즈 필터 (low-pass, alpha≈0.1~0.2) 및 `UserAccelerometerEvent`(중력 제외)와 `AccelerometerEvent` 구분이 모든 엔진 공통 필수 사항.

---

## Perspective 4: Flutter 통합 & 모바일 부담

### 상태 분석

| 엔진 | 통합 방식 | APK 증가 | iOS 지원 | 안정성 |
|------|---------|---------|---------|--------|
| Flame | Flutter Canvas 네이티브 | +2~5MB | ✅ | ✅ 88,400 주간 다운로드 |
| Babylon.js+WebView | PlatformView+WebGL | +수십KB+Babylon 번들 | ⚠️ 불안정 | ⚠️ Android 문제 |
| Unity+flutter_unity | PlatformView (UnityPlayer) | **+60~200MB** | ✅ | ❌ 크래시 다수 |
| Godot 4+flutter_godot | SurfaceView embed | +20~40MB | **❌ 미지원** | ❌ 초기 플러그인 |

**결정적 발견:**
- Godot 4: `flutter_godot`은 **Android 전용** (iOS 미구현, 계획 중). 이 프로젝트 요건(iOS/Android) 불충족으로 즉시 탈락
- Unity: AAB 200MB 초과 사례 다수. 타로 앱 규모에서 수용 불가
- Flame: iPad Air 4th gen 기준 60fps 유지 최대 **2,500 엔티티** (Unity ~5,000, Flutter vanilla ~200)

### 핵심 발견
PlatformView Hybrid Composition은 2025년에도 일부 Android 기기에서 심각한 성능 저하가 지속된다. Unity/Godot의 Flutter 통합이 의존하는 레이어에서 미해결 문제.

---

## Perspective 5: 프리렌더 vs 실시간 혼합 전략

### 상태 분석

**프리렌더 방식 비교:**
| 방식 | 도구 | 라이선스 | 파일 크기(5초) | 3D 손 | 투명도 |
|------|------|---------|-------------|------|--------|
| MP4 H.264 | Blender/FFmpeg | 무료 | **3~5MB** | ✅ | ❌ |
| WebM VP9 | Blender | 무료 | 3~10MB | ✅ | ✅ |
| WebP 시퀀스 | Blender | 무료 | 5~15MB | ✅ | ✅ |
| PNG 시퀀스 | Blender | 무료 | 150~300MB+ | ✅ | ✅ |
| Spine 2D | Spine ($299) | 유료 | 1~3MB | ❌ 2D만 | ✅ |
| Lottie | Adobe AE | 무료 | <2MB | ❌ 2D만 | ✅ |

**혼합 전환 패턴:**
```
IDLE → SHUFFLING (video_player, Blender 렌더 영상)
     → TRANSITIONING (AnimatedCrossFade 300ms)
     → PHYSICS_EXPLORE (Flame + forge2d + sensors_plus)
     → CARD_SELECTED
```

**핵심 구현 제약**: 영상 마지막 프레임의 카드 배치 위치 = Flame 물리 레이어 초기 카드 위치. **제작 단계에서 좌표 동기화 필수.**

### 핵심 발견
- Unity를 오프라인 렌더링 도구로만 사용하는 라이선스 회피 전략: 비게임 앱에 Industrial 플랜($4,950/년) 적용 — **사실상 불가**
- Blender: GPL이나 출력물(MP4) 저작권자 소유로 상업 사용 완전 자유
- video_player 물리 전환 후 즉시 `dispose()` 필수 (메모리 누수 알려진 이슈)

---

## Cross-Analysis

### 구조적 긴장의 해소

Phase 1에서 발견한 "Flutter 친화성 ↔ 3D 표현력" 긴장은 Phase 2에서 **역할 분리**로 해소됐다:

```
오프라인 레이어 (개발·배포 전)    런타임 레이어 (앱 실행 중)
──────────────────────────    ──────────────────────────
Blender (3D 최고 품질)        Flame (Flutter 최적)
  → 손 셔플 MP4 생성           → 가속도계 물리
  → 조명, PBR, 그림자         → 78장 card rigid body
  → 일회성 오프라인 렌더        → sensors_plus 직결
```

두 레이어가 각자 강점 영역만 담당 → "무료 + 품질 + 모바일 부담" 3개 기준 동시 충족.

### Phase 1 → Phase 2 평가 역전

| 엔진 | Phase 1 위치 | Phase 2 결론 | 이유 |
|------|------------|------------|------|
| Godot 4 | "3관점 균형 최적점" | 탈락 | iOS Flutter 통합 미지원 |
| Unity | "품질 최고, 라이선스 위험" | 탈락 | APK 과대 + 비게임 라이선스 |
| Flame | "물리 최적, 3D 한계" | 채택 | 런타임 물리 레이어 담당 |
| Blender | (조사 전 언급 없음) | 채택 | 오프라인 렌더링 도구로 등장 |

### 공통 패턴
- **탈락 엔진 공통**: 외부 엔진 런타임을 Flutter에 임베딩 시도 → APK 폭증 또는 iOS 미지원
- **채택 경로 공통**: Flutter 네이티브(Flame) + 오프라인 도구(Blender) 조합으로 임베딩 없이 해결

---

## Comprehensive Conclusion

### 최종 권장 아키텍처

```
[오프라인 제작 도구] Blender 4.x (GPL, 완전 무료)
  ├─ 손 3D 모델: Rigify 또는 커뮤니티 무료 리깅 모델 활용
  ├─ 렌더러: Cycles (물리 기반 광선 추적, 최고 품질)
  └─ 출력: 720p MP4 H.264 CRF26 (~3~5MB, 5초 셔플 시퀀스)

[Flutter 앱 런타임] Flame + forge2d + sensors_plus
  ├─ 프리렌더 재생: video_player (손 셔플 시퀀스)
  ├─ 전환: AnimatedCrossFade 300ms
  ├─ 실시간 물리: Flame + forge2d (Box2D Dart 포트)
  │   └─ sensors_plus → world.setGravity() (가속도계 → 중력 방향)
  └─ 카드 효과: Flutter FragmentShader (GLSL shimmer/glow)

[폴백 전략] 저사양 기기 감지 시
  └─ Matrix4 + TweenAnimationBuilder 2D 셔플 (가속도계 물리는 유지)
```

### 핵심 발견 (우선순위 순)

1. **[Critical] R-027-F1: 단일 엔진으로 3개 기준 동시 충족 불가** — 라이선스·품질·Flutter 통합이 상충하여 어떤 단일 엔진도 해법이 되지 않음. 역할 분리(오프라인 렌더 + 런타임 물리)가 유일한 해법 *(관점 1~5)*

2. **[Critical] R-027-F2: Godot 4의 Flutter iOS 통합 미지원** — flutter_godot은 Android 전용. Phase 1 최우선 후보였으나 iOS/Android 동시 배포 요건에서 탈락 *(관점 4)*

3. **[Critical] R-027-F3: Blender + Flame 혼합이 최종 권장** — Blender(무료, 최고 3D 품질 오프라인 렌더) + Flame(MIT, Flutter 네이티브, forge2d 물리, sensors_plus 직결). 3개 평가 기준 모두 충족 *(관점 1, 3, 4, 5)*

4. **[High] R-027-F4: Unity 오프라인 렌더 우회 전략 불가** — 비게임 앱에 Industrial 플랜($4,950/년) 요구. Blender로 완전 대체 가능하며 Cycles 렌더러 품질이 실질적으로 동등 *(관점 1, 5)*

5. **[High] R-027-F5: 78장 물리 + 가속도계 연동 Flame으로 가능** — forge2d Box2D, sensors_plus 스트림 → world.setGravity() 5줄 연동, 중급 모바일 60fps 달성 가능 *(관점 3)*

6. **[High] R-027-F6: 프리렌더→물리 전환의 좌표 동기화 핵심** — 영상 마지막 프레임의 카드 배치와 Flame 물리 초기 레이아웃 일치가 전환의 자연스러움을 결정. 제작 단계에서 설계 필수 *(관점 5)*

7. **[Medium] R-027-F7: Flutter FragmentShader로 카드 시각 효과 보완** — 홀로그램, shimmer, glow는 GLSL fragment shader로 Flutter 네이티브에서 구현 가능. 별도 3D 엔진 불필요 *(관점 2)*

8. **[Medium] R-027-F8: 가속도계 필터 필수** — low-pass filter(alpha≈0.1~0.2) + UserAccelerometerEvent(중력 제외) 사용. 미적용 시 카드가 노이즈에 과반응 *(관점 3)*

### 향후 검토 사항
- **Blender 렌더 파이프라인 구축**: 손 3D 모델 소싱, Cycles 렌더 시간 추정 (GPU 렌더 시 수분 수준)
- **Flame + video_player 통합 프로토타입**: 전환 좌표 동기화 검증 필요
- **저사양 기기 기준선 정의**: 어떤 기기에서 폴백 트리거? (예: GPU tier 감지)

---

## Unresolved Items

1. **Blender 손 3D 모델 품질 기준**: 오픈소스 커뮤니티 손 리깅 모델의 실제 품질 미검증 (직접 테스트 필요)
2. **Flame + video_player 전환 시각 자연스러움**: 좌표 동기화가 실제로 얼마나 seamless한지 프로토타입 없이 검증 불가

---

## Referenced File List

| 파일 경로 | 관련 관점 | 역할 |
|----------|---------|------|
| mobile/pubspec.yaml | 전체 | 현재 프로젝트 의존성 |
| mobile/lib/features/shuffle/presentation/widgets/riffle_animation_controller.dart | 전체 | 현재 2D 셔플 엔진 |
| mobile/lib/features/shuffle/presentation/widgets/card_painter.dart | 전체 | 현재 2D 카드 렌더러 |
| mobile/lib/features/shuffle/data/datasources/sensor_data_collector.dart | 관점 3 | 가속도계 수집 현황 |
| docs/11_tarot_shuffle/019_Research_3d_engine_comparison.md | 전체 | 체크포인트 |
| docs/11_tarot_shuffle/020_Agent_license_cost.md | 관점 1 | 라이선스 상세 |
| docs/11_tarot_shuffle/021_Agent_3d_quality_hand.md | 관점 2 | 3D 품질 상세 |
| docs/11_tarot_shuffle/022_Agent_physics_sensor.md | 관점 3 | 물리/센서 상세 |
| docs/11_tarot_shuffle/023_Synthesis_3d_engine_phase1.md | 관점 1~3 | Phase 1 교차 분석 |
| docs/11_tarot_shuffle/024_Agent_flutter_integration.md | 관점 4 | Flutter 통합 상세 |
| docs/11_tarot_shuffle/025_Agent_prerender_realtime.md | 관점 5 | 혼합 전략 상세 |
| docs/11_tarot_shuffle/026_Synthesis_3d_engine_phase2.md | 관점 4~5 | Phase 2 교차 분석 |

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
