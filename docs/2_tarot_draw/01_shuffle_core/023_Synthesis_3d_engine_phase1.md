---
id: "023"
title: "3D 엔진 비교 Phase 1 Synthesis — 라이선스·품질·물리"
category: report
status: archived
created: 2026-03-16
summary: >
  Phase 1 3개 에이전트 보고서(020~022) 교차 분석. 라이선스·3D 품질·물리 관점을
  종합하면 단일 엔진으로 모든 요구사항을 충족하는 옵션은 없음.
  Flutter 친화성과 3D 표현력이 반비례하는 구조적 긴장이 핵심 발견.
  Phase 2(통합 오버헤드·혼합 전략)가 최종 선택의 결정적 변수.
keywords: [synthesis, 3D engine, license, hand animation, physics, tarot, Flutter]
modules: []
---

# 3D 엔진 비교 Phase 1 Synthesis — 라이선스·품질·물리

## 팀 구성 & 개별 보고서

| # | 역할 | 보고서 | 상태 |
|---|------|--------|------|
| 1 | 라이선스 & 비용 분석가 | [020_Agent_license_cost.md](./020_Agent_license_cost.md) | 완료 |
| 2 | 3D 품질 & 손/손가락 표현 분석가 | [021_Agent_3d_quality_hand.md](./021_Agent_3d_quality_hand.md) | 완료 |
| 3 | 물리 엔진 & 센서 연동 분석가 | [022_Agent_physics_sensor.md](./022_Agent_physics_sensor.md) | 완료 |

---

## 엔진별 3-관점 통합 스코어카드

| 엔진 | 라이선스 | 3D 품질/손 표현 | 물리/센서 | Phase 1 종합 |
|------|---------|----------------|---------|------------|
| **Flame** | ✅ MIT 완전무료 | ❌ 3D 손 불가 | ✅ forge2d, sensors 직접 연동 | **중** — 물리 최적, 품질 한계 |
| **Godot 4** | ✅ MIT 완전무료 | ✅ Skeleton3D, PBR(일부 버그) | ✅ Jolt, Input.get_gravity() | **고** — 3관점 모두 양호 |
| **Unity (URP)** | ⚠️ 조건부($200K) | ✅✅ 최고 (Humanoid rig, Shader Graph) | ✅ PhysX, 검증된 패턴 | **고** — 품질 최고, 라이선스 위험 |
| **Babylon.js** | ✅ Apache 2.0 완전무료 | ✅ Bone API, PBR 완전지원 | ❌ Havok iOS<16.4 미지원, WebView 불안정 | **중하** — 라이선스 좋으나 모바일 물리 위험 |
| **Flutter 내장** | ✅ BSD-3 완전무료 | ❌ pseudo-3D, 손 불가 | ⚠️ 78장 O(n²) 불가 | **하** — 증강 한계 명확 |
| **three_dart** | ✅ MIT(유지보수 중단) | ❌ 3년 미업데이트, 버그 | ❌ cannon_physics 미성숙 | **탈락** — 즉시 제외 |
| **flame_3d** | ✅ MIT | ❌ experimental, skeletal 미구현 | ❌ 미검증 | **탈락** — 즉시 제외 |

---

## Cross-Analysis

### 1. 구조적 긴장: Flutter 친화성 ↔ 3D 표현력

```
Flutter 친화성 고 ◄───────────────────────────────► 3D 표현력 고
[Flutter 내장] [Flame] [Babylon.js+WV] [Godot 4] [Unity]
     BSD-3        MIT     Apache 2.0      MIT      조건부
```

- Flame은 Flutter 완전 네이티브 (sensors_plus 직접 연동, 지연 없음)이지만 3D 손 표현 원천 불가
- Unity는 3D 품질 최상 (Humanoid rig, Shader Graph)이지만 Flutter와 별도 엔진 프로세스 통합 필요
- **중간 지점**: Godot 4 — MIT 무료, Skeleton3D 완전 지원, Jolt 고성능 물리, Flutter 통합 가능성 있음

### 2. 공통 발견

- **three_dart/flame_3d 탈락 확정**: 라이선스와 무관하게 유지보수 중단 또는 experimental 상태로 프로덕션 불가
- **가속도계 → 물리 gravity 연동**: 모든 실용 엔진에서 가능하나 Flutter 네이티브일수록 구현이 단순
  - Flame: 5줄 (스트림 구독 → setGravity)
  - Godot 4: 중간 (MethodChannel 경유)
  - Unity: 중간 (flutter_unity_widget → MethodChannel)
  - Babylon.js: 복잡 (JS DeviceMotion API 또는 Flutter→JS 브릿지)

- **78장 물리 가능 엔진**: Flame(forge2d, 2D), Godot 4(Jolt, 3D), Unity(PhysX, 3D)
  - 불가: Flutter 순수 물리(O(n²) CPU 포화), Babylon.js(WebView 모바일 불안정)

### 3. 충돌하는 발견

| 충돌 | 라이선스 관점 | 품질 관점 | 물리 관점 | 결론 |
|------|-------------|---------|---------|------|
| Unity 사용 여부 | ⚠️ 위험 | ✅✅ 최고 | ✅ 검증됨 | Phase 2 통합 오버헤드 분석 후 최종 판단 |
| Babylon.js 실용성 | ✅ 완전무료 | ✅ 좋음 | ❌ iOS 물리 위험 | 물리 없이 프리렌더 전용으로만 고려 가능 |
| Flame 확장 한계 | ✅ 최적 | ❌ 3D 불가 | ✅ 최적 | 혼합 전략의 물리 레이어로만 활용 가능 |

### 4. 핵심 새 인사이트: 혼합 아키텍처 가능성

Phase 1 교차 분석에서 자연스럽게 도출된 가설:

> **"고품질 3D 손 모션 = 프리렌더 (Unity/Blender로 오프라인 생성)"**
> **"실시간 카드 물리 = Flame/forge2d (Flutter 네이티브, sensors_plus 직결)"**

이 혼합 전략이 성립하면:
- 라이선스: Unity 개발 도구로만 사용 (배포 바이너리에 Unity 런타임 없음 → 라이선스 회피 가능?)
- 품질: 오프라인 렌더링에서 최고 품질 영상 생성
- 모바일 부담: 실시간 물리는 Flutter/Flame이 처리 → 엔진 통합 오버헤드 없음

**이 가설의 검증이 Phase 2 관점 5의 핵심 연구 질문.**

---

## Phase 2 진입 우선순위 엔진

Phase 1 결과로 Phase 2 심화 조사 대상을 3개로 좁힘:

1. **Godot 4** — MIT, 3D 풀스택, Jolt 물리 → Flutter 통합 오버헤드가 유일한 미지수
2. **Unity** — 품질 최고, 물리 검증 → Flutter APK 크기·통합 방식이 결정적 변수
3. **Flame + 프리렌더 혼합** — Flutter 네이티브 물리 + 오프라인 렌더 → 혼합 아키텍처 실현 가능성

Babylon.js는 모바일 물리 약점으로 **프리렌더 전용 보조 옵션**으로 격하.

---

## Comprehensive Conclusion (Phase 1)

### 핵심 발견

1. **[Critical] R-019-F1: 단일 완전 무료 + 최고 3D 품질 엔진 없음** — 라이선스와 3D 품질·물리가 상충. 어떤 엔진도 3개 기준을 모두 만족하지 못함 *(관점 1, 2, 3)*
2. **[High] R-019-F2: Godot 4가 3관점 균형 최적점** — MIT 완전무료, Skeleton3D 완전 지원, Jolt 물리 성능. Flutter 통합 오버헤드만 미확인 *(관점 1, 2, 3)*
3. **[High] R-019-F3: 혼합 아키텍처 가설 도출** — 프리렌더(오프라인 고품질 영상) + 실시간 물리(Flame/forge2d)로 품질·성능·라이선스 동시 해결 가능성 *(관점 2, 3)*
4. **[High] R-019-F4: three_dart/flame_3d 즉시 탈락** — 유지보수 중단/experimental로 프로덕션 사용 불가 *(관점 1, 2, 3)*
5. **[Medium] R-019-F5: Unity 정책 리스크 실재** — 2024년 Runtime Fee 철회로 현재 조건($200K) 양호하나 과거 일방적 변경 이력으로 장기 신뢰도 낮음 *(관점 1)*
6. **[Medium] R-019-F6: Babylon.js 모바일 물리 실용성 낮음** — Havok iOS<16.4 WASM SIMD 미지원, WebView 78장 실시간 물리 불안정 → 프리렌더 전용으로만 고려 *(관점 3)*

### Phase 2 핵심 연구 질문
- Godot 4 + Flutter 통합 시 실제 APK 크기·GPU 오버헤드는?
- 프리렌더 손 모션 + Flame 실시간 물리 혼합이 시각적으로 자연스러운가?
- Unity를 런타임 없이 오프라인 렌더링 도구로만 사용 시 라이선스 문제 없는가?

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
