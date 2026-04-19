---
id: "026"
title: "3D 엔진 비교 Phase 2 Synthesis — Flutter 통합 & 혼합 전략"
category: report
status: archived
created: 2026-03-16
summary: >
  Phase 2 에이전트 보고서(024~025) 교차 분석. Flutter 통합 관점에서 Phase 1 평가가
  역전됨. Godot 4: iOS 미지원 치명적 결함 확인. Unity 오프라인 도구 라이선스 우회:
  비게임 앱 조항으로 불가. 최종 권장: Blender(무료) + MP4 + video_player + Flame/forge2d.
keywords: [synthesis, Flutter integration, pre-render, hybrid, Blender, Flame, tarot]
modules: []
---

# 3D 엔진 비교 Phase 2 Synthesis — Flutter 통합 & 혼합 전략

## 팀 구성 & 개별 보고서

| # | 역할 | 보고서 | 상태 |
|---|------|--------|------|
| 4 | Flutter 통합 & 모바일 부담 분석가 | [024_Agent_flutter_integration.md](./024_Agent_flutter_integration.md) | 완료 |
| 5 | 프리렌더 vs 실시간 혼합 전략 분석가 | [025_Agent_prerender_realtime.md](./025_Agent_prerender_realtime.md) | 완료 |

---

## Cross-Analysis

### Phase 1 평가의 역전 (가장 중요한 발견)

| 엔진 | Phase 1 평가 | Phase 2 추가 발견 | 최종 판단 |
|------|------------|----------------|---------|
| **Godot 4** | "3관점 균형 최적점" | ❌ Flutter 통합: iOS 미지원, SurfaceView 충돌 | **탈락** |
| **Unity** | "품질 최고, 라이선스 위험" | ❌ APK +60~200MB, 통합 불안정, 비게임 라이선스 위험 | **탈락** |
| **Babylon.js** | "모바일 물리 위험, 프리렌더는 가능" | ❌ WebView 불안정, iOS WebGL 성능 문제 | **보조 옵션으로 격하** |
| **Flame** | "물리 최적, 3D 손 불가" | ✅ APK +2~5MB, iOS/Android 완전 지원, 안정 | **채택 (물리 레이어)** |

### 결정적 전환점: 프리렌더 + Flame 혼합

Phase 1 가설 "고품질 3D 손 모션 = 프리렌더 (Unity로 오프라인 생성)" → Phase 2에서 수정:
- **Unity 오프라인 렌더링 도구 사용**: 비게임 앱에는 Industrial 플랜($4,950/년) 필요 → **탈락**
- **Blender 대체**: GPL이지만 출력물(MP4) 상업 사용 완전 자유 → **채택**
- 결과: Blender의 3D 손 품질 (Cycles 렌더러 + 무료 손 리깅 모델)이 실용적 대안으로 성립

### 혼합 아키텍처 두 관점의 일치
- **관점 4** (통합): "Flame이 APK 크기·안정성·iOS 지원에서 현실적 최선"
- **관점 5** (혼합): "Blender MP4 + Flame/forge2d + sensors_plus가 최종 권장 아키텍처"

두 독립 에이전트가 동일한 결론(Flame + 프리렌더 혼합)에 도달 → 결론의 신뢰성 높음.

---

## Comprehensive Conclusion (Phase 2)

### 5초 손 셔플 영상 규모
- **720p MP4 H.264 CRF26**: 약 3~5MB (앱 번들에 포함 현실적)
- **주의**: 영상 마지막 프레임의 카드 배치 = Flame 물리 초기 레이아웃과 일치 필수 (제작 단계에서 좌표 동기화)

### 최종 권장 아키텍처 (Phase 2 확정)

```
[오프라인 제작] Blender 4.x + Cycles 렌더러
  → 720p MP4 H.264 (~3~5MB, 손 셔플 5초)

[Flutter 앱 런타임]
  IDLE state ──────────────────────────────────┐
  SHUFFLING state: video_player 재생            │
  TRANSITIONING: AnimatedCrossFade 300ms        │
  PHYSICS_EXPLORE: Flame + forge2d              │
    → sensors_plus 가속도계 → world.setGravity() │
    → 카드 78장 rigid body 충돌                  │
  CARD_SELECTED ───────────────────────────────┘

[폴백] 저사양 기기: Matrix4 2D 셔플 애니메이션
```

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
