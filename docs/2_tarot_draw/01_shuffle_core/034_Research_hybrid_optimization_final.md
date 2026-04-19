---
id: "034"
type: research
title: "타로 셔플 혼합 아키텍처 최적화 — 최종 보고서 (2차 연구)"
created: 2026-03-16
traces_scope: "018"
summary: >
  1차 연구 권장 아키텍처(Blender MP4 + video_player + Flame)의 모바일 최적화 우려
  검증 결과. 동시 실행 시 RSS 피크 155~320 MB (저사양 위험) → 순차 전환 패턴으로
  해소 가능. iOS 블랙 플래시 버그(#41156) 미해결로 실기기 테스트 필수.
  대안: Flame + Rive + forge2d 단일 엔진 — video_player 제거, 파일 10~25× 감소,
  전환 병목/iOS 버그 구조적 제거. 손 표현이 2.5D 스타일로 제한되는 트레이드오프 존재.
keywords: [hybrid, optimization, video_player, Flame, Rive, forge2d, memory, iOS-bug, transition]
---

# 타로 셔플 혼합 아키텍처 최적화 — 최종 보고서 (2차 연구)

## Research Overview

### Background & Motivation
1차 연구 결론: **Blender 오프라인 MP4 + video_player + Flame/forge2d 혼합 아키텍처**.
사용자 우려: "두 시스템이 한 모바일에서 동작 시 앱이 너무 무거워지지 않는가?"
*(명확화: Blender는 개발자 PC 도구 — 모바일에 없음. 실제 우려 대상: video_player + Flame 동시 실행)*

### Research Scope
- 포함: 메모리 footprint, GPU 파이프라인, 전환 오류 패턴, 단일 엔진 대안, 실제 사례
- 제외: Blender 렌더 파이프라인 상세, 물리 엔진 내부 (1차 연구 완료)

### Related Documents
- 체크포인트: [028_Research_hybrid_optimization.md](./028_Research_hybrid_optimization.md)
- 1차 연구 최종: [027_Research_3d_engine_final.md](./027_Research_3d_engine_final.md)
- 029: [메모리 & GPU](./029_Agent_memory_gpu.md) | 030: [전환 병목](./030_Agent_transition_sync.md)
- 031: [단일 엔진 대안](./031_Agent_single_engine.md) | 032: [실제 사례](./032_Agent_real_cases.md)
- 033: [Synthesis](./033_Synthesis_hybrid_optimization.md)

---

## Perspective 1: 메모리 & GPU 동시 부담

### 상태 분석

**메모리 footprint (실측 기반 추정)**

| 시스템 | 초기화 | 활성 실행 | RSS 합계 |
|--------|------|---------|---------|
| video_player 720p | +20~40 MB | +60~120 MB | ~110~200 MB |
| Flame + forge2d 78 bodies | +30~50 MB | +45~96 MB | ~95~176 MB |
| **동시 활성화 (Flutter 베이스 포함)** | | | **~155~320 MB 피크** |
| 순차 전환 (안정 상태) | | | **~95~200 MB** |

*모든 수치 ±30% 변동. 기기/OS/코덱 의존.*

**기기별 위험도:**
| RAM | 동시 실행 위험 | 순차 전환 후 |
|-----|------------|-----------|
| 2 GB | 🔴 HIGH | 🟡 주의 |
| 4 GB | 🟡 LOW~MED | 🟢 안전 |
| 6~8 GB | 🟢 무시 가능 | 🟢 안전 |

**GPU 파이프라인 분석 (Impeller):**
- Android: video_player는 `GL_TEXTURE_EXTERNAL_OES → Vulkan blit-copy` 경로 (VRAM ~7 MB 이중 사용)
- iOS: video_player는 `CVPixelBuffer → Metal 텍스처` 직접 매핑 (더 효율적)
- Flame: Impeller 단일 경로
- → **두 시스템은 GPU 파이프라인 공유 없음. 각자 독립 경로. 경합 없음.**

### 핵심 발견
`dispose()` 없이 컨트롤러 보유 시 네이티브 플레이어 잔류 → 메모리 누수.
78개 rigid body 물리 데이터 자체는 ~30 KB 미만 — 메모리 부담의 실질 원천은 카드 텍스처(10~30 MB).

### Caveats & Risks
- **저사양(2GB) 기기**: 동시 활성화 시 OOM Kill 실질 위험. 시장 점유율 고려 필요
- **GC 지연**: `dispose()` 후 메모리 해제까지 10~30초 지연 가능 (GC 비결정적)

### Summary
동시 실행은 저사양 기기에서 위험하지만, **순차 전환 패턴**(영상 종료→dispose→Flame 활성)으로 피크 RSS를 절반 수준으로 제어 가능하다.

---

## Perspective 2: 전환 병목 & 동기화 오류

### 상태 분석

**알려진 오류 패턴:**

| 오류 | 플랫폼 | 원인 | 상태 |
|------|--------|------|------|
| 블랙 플래시 (첫/마지막 프레임) | **iOS** | AVPlayer 렌더 파이프라인 지연 | **미해결 (#41156, P2)** |
| 프레임 점프 | 전체 | Flame 초기 좌표 ≠ 영상 마지막 프레임 배치 | 설계로 해결 가능 |
| onComplete 타이밍 오류 | iOS | isCompleted가 마지막 프레임 표시 전 발생 | 100ms 지연으로 회피 |
| dispose() 블랙 플래시 | 전체 | 페이드 완료 전 dispose() 호출 | onEnd 후 호출로 해결 |

**권장 전환 아키텍처:**

```dart
// Flame GameWidget에 video_player를 overlay로 탑재
GameWidget(
  game: _tarotGame,
  overlayBuilderMap: {
    'shuffleVideo': (ctx, game) => AnimatedOpacity(
      opacity: _videoOpacity,   // 1.0 → 0.0 (300ms)
      onEnd: () {
        game.overlays.remove('shuffleVideo');
        _controller.dispose();
      },
      child: VideoPlayer(_controller),
    ),
  },
  initialActiveOverlays: ['shuffleVideo'],
)

// isCompleted + 100ms 지연 후 페이드
_controller.addListener(() {
  if (_controller.value.isCompleted && !_transitioning) {
    _transitioning = true;
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() => _videoOpacity = 0.0);
    });
  }
});
```

**카드 좌표 동기화 — 사전 설계 의존형:**
```json
// assets/card_initial_positions.json
{ "cards": [{"id": 0, "x": 0.5, "y": 0.7, "angle": -15.0}, ...] }
```
Blender 렌더와 Flame 초기화 모두 이 파일을 참조. 좌표계 변환 주의: Blender Y↑ / Flame Y↓.

**안전 패턴 (영상 종료 200ms 전 Flame 워밍업):**
```dart
final remaining = _controller.value.duration - _controller.value.position;
if (remaining.inMilliseconds < 200 && !_warmedUp) {
  _warmedUp = true;
  _tarotGame.activatePhysics(); // 물리 월드 미리 활성화
}
```

### Summary
전환 오류는 **해결 가능한 수준**이다. 단, iOS 블랙 플래시 버그(#41156)가 미해결 상태로 실기기 테스트 필수.

---

## Perspective 3: 단일 엔진 대안 평가

### 상태 분석

video_player를 제거하는 두 가지 대안:

**옵션 A: Flame + SpriteSheet (Blender PNG → WebP)**
- WebP 손실 q=85 적용 시 4.5~12 MB (MP4 3~5 MB와 비슷하거나 큼)
- 품질: Blender 렌더 그대로 (압축 아티팩트 없음)
- 문제: 150프레임 atlas가 GPU 텍스처 제한(4096~8192px) 초과 → 다중 atlas 분할 필요
- 런타임 상호작용 불가 (고정 시퀀스)
- **결론: 파일 크기 이점 없음, 구현 복잡성 유사 — 비추천**

**옵션 B: Flame + Rive + forge2d ← 권장**

`flame_rive` **공식 브릿지 패키지** 존재:
```dart
final artboard = await loadArtboard(RiveFile.asset('assets/hand_shuffle.riv'));
final controller = StateMachineController.fromArtboard(artboard, 'ShuffleState');
artboard.addController(controller);
add(RiveComponent(artboard: artboard, size: Vector2(400, 600)));
// RiveComponent는 PositionComponent 상속 → forge2d BodyComponent와 동일 게임 트리 공존
```

| 비교 항목 | video_player + Flame | Flame + Rive + forge2d |
|---------|:---:|:---:|
| 손 표현 품질 | ✅ Blender 포토리얼 | ⚠️ 2.5D 스타일 |
| 파일 크기 | 3~5 MB (MP4) | **50~300 KB (.riv)** |
| 전환 복잡성 | 높음 | **없음 (State Machine)** |
| iOS 블랙 플래시 리스크 | 있음 (미해결) | **없음** |
| 메모리 피크 | 155~320 MB | ~95~176 MB |
| 런타임 상호작용 | 낮음 | **높음 (State Machine)** |
| 라이선스 | 무료 | **MIT (런타임 무료)** |

**Rive 품질 현실:**
- bone rigging + mesh warping으로 손가락 20개 bone 리그 구성 가능
- 포토리얼리스틱 3D 불가 → "신비적/마법 테마 2.5D 일러스트" 스타일
- 실제 모바일 60fps 달성 확인 (Metal/Vulkan 렌더러)
- 에디터 무료 플랜 (2024년 8월부터 무제한 개인 파일)

### Summary
**Flame + Rive + forge2d 단일 엔진이 혼합 아키텍처의 모든 문제(메모리, 전환, iOS 버그)를 구조적으로 제거**한다. 트레이드오프: 손 표현이 "신비적 2.5D 스타일"로 제한.

---

## Perspective 4: 실제 앱 구현 사례

### 상태 분석

**Flutter video_player + Flame 혼합:** 공개 프로덕션 사례 없음 (미개척 영역)

**Flutter + Flame 프로덕션 앱 (영상 없음):**
- Super Dash (Google 공식 데모, 2023) — 순수 스프라이트/물리
- Spacescape, Air Hockey Classic — Flame 단독
- 모든 공개 사례가 video_player 없이 구현됨

**타로/카드 앱 현황:**
- Labyrinthos (1M+ 다운로드) — 컴포넌트 트윈 애니메이션, 영상 없음
- React Native 타로 사례 — Reanimated 3 + 삼각함수 기반
- **영상 기반 셔플을 사용하는 타로 앱: 발견되지 않음**

**모바일 게임 컷신 업계 표준 (비Flutter):**
- AAA 모바일: Unity VideoPlayer → 물리 씬 전환 (블랙/페이드 + 이벤트 콜백)
- 인디 모바일: 영상 없이 스프라이트 애니메이션으로 처리

### Caveats & Risks
- 미개척 영역 → 예상치 못한 버그 가능성 높음
- iOS 블랙 프레임 버그 #41156: 40+ 인터랙션에도 미해결 (2026년 1월)
- `Texture` 레이어 충돌(video_player vs Flame canvas): 아직 직접 테스트 데이터 없음

### Summary
Flutter video_player + Flame 혼합은 업계 미검증 영역. 이 패턴을 채택하면 선도적 구현이며, 반드시 자체 파일럿 테스트가 선행되어야 한다.

---

## Cross-Analysis

### 문제 간 연쇄 구조

```
저사양 기기 메모리 위험 (관점 1)
      ↓
  동시 활성화 금지 → 순차 전환 필수
      ↓
  전환 시 iOS 블랙 플래시 위험 (관점 2)
      ↓
  100ms 지연 + Flame overlay 패턴으로 완화
      ↓
  BUT: 미개척 영역 — 실기기 테스트 없인 불확실 (관점 4)
```

```
이 문제 전체를 Rive로 회피 가능 (관점 3)
      ↓
  video_player 제거 → 메모리/전환/iOS 버그 구조적 제거
      ↓
  트레이드오프: 포토리얼 → 2.5D 스타일 전환 필요
```

### 공통 패턴
두 독립 에이전트(030, 032)가 iOS 블랙 플래시 버그 #41156을 별도 조사에서 동시 발견 → 이 리스크의 실재성 높음.

---

## Comprehensive Conclusion

### 핵심 발견 (우선순위 순)

1. **[Critical] R-034-F1: 동시 실행은 저사양(2GB) 기기에서 OOM 위험** — RSS 피크 155~320 MB. 순차 전환 패턴(영상→dispose→Flame)으로 피크를 95~200 MB로 제어 가능 *(관점 1)*

2. **[Critical] R-034-F2: iOS 블랙 플래시 버그 미해결** — flutter/flutter #41156, 2026년 1월 P2 미해결. 혼합 아키텍처 채택 전 iOS 실기기 파일럿 테스트 필수 *(관점 2, 4)*

3. **[Critical] R-034-F3: Flutter video_player + Flame 혼합은 미개척 영역** — 프로덕션 사례 없음. 타로 업계도 트윈 기반이 표준 *(관점 4)*

4. **[High] R-034-F4: Flame + Rive + forge2d 단일 엔진이 모든 문제를 구조적 제거** — flame_rive 공식 브릿지, 파일 50~300KB, 전환 병목 없음, iOS 버그 없음. 트레이드오프: 2.5D 스타일 *(관점 3)*

5. **[High] R-034-F5: 혼합 아키텍처는 최적화 달성 가능** — Flame overlay 탑재 + 순차 전환 + 100ms 지연 패턴. 단, iOS 블랙 플래시 회피 보장 안 됨 *(관점 1, 2)*

6. **[Medium] R-034-F6: GPU 경합 없음 확인** — video_player와 Flame은 독립 GPU 파이프라인 사용. 경합 아닌 VRAM 누적이 실제 문제 *(관점 1)*

7. **[Medium] R-034-F7: 좌표 동기화는 사전 설계 의존** — JSON 번들로 Blender 렌더와 Flame 초기 좌표 공유. 런타임 자동 동기화 API 없음 *(관점 2)*

---

### 최종 선택지 비교

| | 경로 A: 혼합 유지 | 경로 B: Flame + Rive |
|---|---|---|
| **손 품질** | ✅ Blender 포토리얼 | ⚠️ 2.5D 스타일 |
| **파일 크기** | MP4 3~5 MB | .riv 50~300 KB |
| **메모리 피크** | 순차 전환 시 95~200 MB | ~95~176 MB |
| **iOS 블랙 플래시** | ⚠️ 미해결 위험 | ✅ 없음 |
| **전환 복잡성** | 높음 | ✅ 없음 |
| **업계 검증** | ❌ 미개척 | ❌ 미개척 |
| **구현 리스크** | 중간 (iOS 실기기 테스트 필수) | 낮음 |
| **선택 기준** | "포토리얼 손 표현이 필수" | "안정성 + 효율 우선" |

---

### 추천 의사결정 트리

```
손 표현을 "포토리얼리스틱 3D 수준"으로 필수 판단?
  │
  ├─ YES → 경로 A (video_player + Flame)
  │         iOS 실기기 블랙 플래시 테스트 선행
  │         문제 없으면 채택 / 문제 있으면 → 경로 B
  │
  └─ NO / 2.5D 신비 스타일도 허용 → 경로 B (Flame + Rive + forge2d)
           가장 안정적, 파일 작음, 메모리 낮음
           flame_rive 프로토타입으로 빠른 검증 가능
```

---

## Unresolved Items

1. **iOS 실기기 블랙 플래시 재현 여부**: 파일럿 테스트 없이는 불확실. 해결 가능 여부 불명.
2. **Rive 2.5D 손 표현 실제 품질**: 프로토타입 없이 품질 수준 정확한 예측 불가.
3. **video_player + Flame Texture 레이어 충돌**: 실기기 테스트 데이터 없음.

---

## Referenced File List

| 파일 경로 | 관련 관점 | 역할 |
|----------|---------|------|
| mobile/pubspec.yaml | 전체 | 현재 의존성 (video_player, Flame 미포함 확인) |
| docs/11_tarot_shuffle/027_Research_3d_engine_final.md | 전체 | 1차 연구 최종 보고서 |
| docs/11_tarot_shuffle/029_Agent_memory_gpu.md | 관점 1 | 메모리/GPU 상세 |
| docs/11_tarot_shuffle/030_Agent_transition_sync.md | 관점 2 | 전환 오류 상세 |
| docs/11_tarot_shuffle/031_Agent_single_engine.md | 관점 3 | 단일 엔진 상세 |
| docs/11_tarot_shuffle/032_Agent_real_cases.md | 관점 4 | 실제 사례 상세 |
| flutter/flutter#41156 | 관점 2, 4 | iOS 블랙 플래시 미해결 버그 |
| pub.dev/packages/flame_rive | 관점 3 | Rive + Flame 공식 브릿지 |

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
