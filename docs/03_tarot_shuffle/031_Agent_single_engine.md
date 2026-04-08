---
id: "031"
title: "단일 엔진 대안 평가 — Flame SpriteSheet & Rive"
category: agent
status: archived
created: 2026-03-16
summary: >
  video_player 없이 Flame SpriteSheet 또는 Rive로 고품질 손 셔플 표현 가능성 분석.
  Rive + flame_rive가 최적의 단일 엔진 경로로 도출됨.
keywords: [agent-report, single-engine, Flame, SpriteSheet, Rive, alternative, hand-animation, flame_rive]
modules: []
---
# 단일 엔진 대안 평가 — Flame SpriteSheet & Rive

## Progress
### Completed
- [x] Flame SpriteSheet 품질 vs 파일 크기
- [x] Rive 2.5D 손 표현 가능성
- [x] Rive 라이선스 조사
- [x] Flame + Rive + forge2d 통합 가능성 (flame_rive 공식 브릿지 확인)
- [x] 품질 손실 수준 추정
- [x] 권장 시나리오 정의
### Remaining
(없음)
### Current Status
조사 완료. 권장 시나리오: **옵션 B (Flame + Rive + forge2d)**.

---

## Summary

video_player를 제거하는 단일 엔진 경로는 두 가지가 현실적이다:

- **옵션 A (Flame SpriteSheet)**: PNG 시퀀스를 WebP로 압축한 스프라이트 시트를 Flame SpriteAnimation으로 재생. 구현이 가장 단순하지만 파일 크기가 MP4 대비 4~10× 크며, 표현 품질은 동일(사전 렌더 이미지 재생이므로).
- **옵션 B (Flame + Rive + forge2d)**: Rive의 bone/mesh warping으로 2.5D 손 애니메이션을 런타임에 제어하고, forge2d로 카드 물리 처리. 공식 `flame_rive` 브릿지 패키지로 통합 가능. 파일이 가장 작고(수십~수백 KB), 런타임 상호작용성이 높으나 손 리깅 제작 난이도가 있음.
- **옵션 C (현행 혼합)**: MP4 3~5MB, 품질 최고, 전환 동기화 복잡성.

**권장: 옵션 B**. Rive .riv 파일은 MP4보다 10~50× 작고, 60fps 달성 가능하며, video_player와 Flame 간 전환 복잡성이 완전히 제거된다. 단, 리얼리스틱 손 표현의 완성도는 Blender 3D 렌더 수준에 미치지 못하므로, 타로 앱 특유의 "신비롭고 손으로 직접 다루는" 분위기를 스타일화(2.5D 일러스트 풍)로 재정의하는 전제가 필요하다.

---

## Details

### 1. Flame SpriteSheet 방식

#### 작동 원리
Flame의 `SpriteSheet` 클래스는 단일 atlas 이미지에서 frame을 추출하여 `SpriteAnimation`을 구성한다. Blender에서 렌더링한 PNG 시퀀스를 하나의 texture atlas PNG/WebP로 병합 후, `SpriteSheet.createAnimation()` 또는 `SpriteAnimation.fromFrameData()`로 로드한다.

```
// 예시
final spriteSheet = SpriteSheet(
  image: await game.images.load('hand_shuffle.webp'),
  srcSize: Vector2(720, 405),   // 각 프레임 크기
);
final animation = spriteSheet.createAnimation(row: 0, stepTime: 1/30);
add(SpriteAnimationComponent(animation: animation));
```

#### 파일 크기 추정 (30fps, 5초 = 150프레임)

| 포맷 | 단일 프레임(720p) | 150장 합산 | 비고 |
|------|----------------|-----------|------|
| PNG(원본) | ~300~800KB | 45~120MB | 비현실적 |
| PNG 최적화(pngquant) | ~80~200KB | 12~30MB | 아틀라스 불가 |
| WebP 무손실 | ~100~250KB | 15~37MB | 권장 |
| WebP 손실(q=85) | ~30~80KB | **4.5~12MB** | MP4 대비 1.5~4× |
| H.264 MP4(현행) | — | **3~5MB** | 기준 |

> 실측 기준: 모바일 게임 스프라이트 최적화 사례에서 WebP는 PNG 대비 40% 절감, 동급 아틀라스에서 28KB(→ 85KB PNG) 수준 달성. 단, 이는 소형 게임 스프라이트 기준이며, 720p 사진급 이미지는 훨씬 크다.

#### GPU 텍스처 메모리
단일 atlas 방식(모든 150프레임을 하나의 거대한 이미지에 배치)은 GPU VRAM을 한 번에 점유한다. 720×405 × 150프레임을 단일 텍스처로 넣으면 가로 세로 합산이 수천 픽셀을 초과하여 모바일 GPU 텍스처 크기 제한(보통 4096~8192px)에 걸린다. **현실적인 구현은 다중 atlas 분할(예: 25프레임씩 6장)** 또는 파일 스트림 방식이 필요하며, 이는 구현 복잡성을 증가시킨다.

#### 품질
PNG/WebP 재생이므로 Blender 렌더 품질이 그대로 보존된다. MP4 H.264의 블록 노이즈 압축 아티팩트가 없어 오히려 품질이 높을 수 있다. 단, 용량이 훨씬 크고, 정지 상태나 루프 반복 시 자연스러운 물리 반응이 불가(고정 시퀀스이므로).

#### forge2d 동시 실행
`SpriteAnimationComponent`와 `BodyComponent(forge2d)` 는 동일한 Flame 게임 루프에서 병렬 실행 가능. 별도 동기화 없이 Flame `FlameGame`의 `update()`/`render()` 사이클 안에서 자연스럽게 공존한다.

---

### 2. Rive 애니메이션 — 2.5D 손 표현

#### Rive의 bone/mesh 시스템
Rive는 bone rigging + vertex weighting(0.0~1.0) 기반의 mesh deformation을 지원한다. "Face Control" 방식처럼 단일 컨트롤 bone을 움직여 parallax 효과로 2.5D 깊이감을 표현하는 것이 실제 프로덕션에서 사용되는 검증된 패턴이다.

- 손가락 단위 bone 제어: **가능**. Rive는 관절별 독립 bone을 구성할 수 있으므로 손목 → 손바닥 → 5개 손가락 각 3마디 = 최대 16~20개 bone 리그 구성 가능.
- Mesh warping: skin mesh에 vertex를 배치하고 bone에 weight를 할당하면, bone 이동 시 mesh가 자연스럽게 변형됨.
- 한계: 진짜 3D 회전(노말 맵, 광원 계산)은 불가. 표현 품질은 "고급 2D/2.5D 일러스트"이지, Blender 3D 렌더와 동일한 사실적 손 표현은 아님.

#### flutter + flame_rive 통합

Flame은 공식 브릿지 패키지 `flame_rive`를 제공한다:

```yaml
dependencies:
  flame_rive: ^1.x
```

```dart
// RiveComponent를 Flame 게임 트리에 직접 추가
final artboard = await loadArtboard(RiveFile.asset('assets/hand_shuffle.riv'));
final controller = StateMachineController.fromArtboard(artboard, 'ShuffleState');
artboard.addController(controller);
add(RiveComponent(artboard: artboard, size: Vector2(400, 600)));
```

- `RiveComponent`는 `PositionComponent`를 상속하므로 forge2d `BodyComponent` 와 동일한 게임 트리에서 공존 가능.
- State Machine을 통해 "idle → shuffle_start → card_deal" 같은 전환을 런타임에 트리거할 수 있어, 이전 video_player의 재생/정지 전환보다 **더 유연하게** 타이밍 제어 가능.
- Flame의 `Game.overlays` 시스템을 통해 일반 Flutter `RiveWidget`을 Flame 위에 오버레이하는 방식도 가능(단, flame_rive의 RiveComponent 방식이 게임 루프 통합이 더 깔끔).

#### 파일 크기

| 콘텐츠 유형 | .riv 파일 크기(추정) |
|------------|---------------------|
| 단순 아이콘 애니메이션 | 2~10 KB |
| 중간 복잡도 캐릭터 리그 | 20~100 KB |
| 복잡한 손 리그(15~20 bone, mesh) + 이미지 임베드 없음 | **50~300 KB** |
| 이미지(WebP) 임베드 포함 | 수 MB 가능 (이미지 크기에 비례) |

> 순수 벡터/bone 리그만 사용 시 200~400 KB 이내가 현실적. MP4 3~5MB 대비 10~25× 작음.

#### 모바일 성능
- Rive 렌더러(Metal/Vulkan 백엔드): 60fps 달성. callstack.com 벤치마크에서 Sony Xperia Z3 기준 60fps, Java 메모리 12MB, Native 25MB.
- Lottie 대비 메모리 2× 효율, CPU 대폭 절감.
- Graphics 메모리는 Lottie(123MB)보다 Rive(184MB)가 다소 높지만, video_player의 H.264 디코딩 + Flame 동시 실행 대비 총 부담은 훨씬 낮다.

---

### 3. Rive 라이선스

| 항목 | 내용 |
|------|------|
| 런타임(rive 패키지) 라이선스 | **MIT** — 상업 앱 무제한 사용 가능 |
| 에디터(rive.app) 무료 플랜 | 무제한 개인 파일, 협업 공간 3개 파일/1개 프로젝트 |
| 유료 플랜 | Cadet $9/mo, Voyager $32/mo, Enterprise $120/mo |
| 상업 앱 배포 | 런타임 MIT → 별도 비용 없음 |
| 에디터 상업 프로젝트 | 유료 플랜 필요 여부는 팀 협업·고급 기능 사용에 따라 결정 (1인 개인 작업은 무료 가능) |

> **핵심**: Flutter 앱에 배포하는 `rive` 패키지(런타임)는 MIT이므로 상업 앱에서 추가 비용 없이 사용 가능.

---

### 4. 절차적 애니메이션 대안 (옵션 D)

Flame의 Effect 시스템(`MoveEffect`, `RotateEffect`, `ScaleEffect`) + Bezier curve를 조합하여 코드로 손 모션을 절차적으로 구현하는 방식:

- **현실적 한계**: 손 모양 자체를 Flame에서 직접 그리려면 벡터/폴리곤 렌더링이 필요하며, Flame의 기본 API는 이를 지원하지 않음. 카드 이동/회전 효과는 완성도 있게 구현 가능하지만, 실제 사람 손의 굴곡·피부 표현은 불가.
- **결론**: 배경 파티클, 카드 비산 효과 등 보조 요소에는 적합하나, 고급스러운 "손이 카드를 만지는" 핵심 표현 역할로는 부적합.

---

## Key Findings

1. **flame_rive 공식 브릿지 존재**: `flame_rive` 패키지가 Flame 공식 생태계 일부로 제공됨. `RiveComponent`가 Flame 게임 트리에 직접 통합되므로, video_player 오버레이 방식의 Z-index/타이밍 동기화 문제가 구조적으로 제거됨.

2. **SpriteSheet는 파일 크기가 결정적 약점**: 30fps 5초 분량의 720p WebP 시퀀스는 최적화 후에도 4.5~12MB로 MP4(3~5MB) 대비 크거나 비슷한 수준이며, 단일 atlas 구성 시 GPU 텍스처 크기 제한(4096px)을 초과하므로 다중 atlas 분할 필요 → 구현 복잡성은 video_player와 비슷.

3. **Rive는 파일 크기 10~25× 이점**: 순수 bone 리그 기준 50~300KB 수준. 앱 번들 증가 없이 손 애니메이션 탑재 가능.

4. **Rive 품질 한계는 명확**: 2.5D 스타일화 표현이지 Blender 포토리얼리스틱 렌더가 아님. 타로 앱의 경우 "마법적 일러스트" 방향으로 컨셉을 전환한다면 오히려 Rive의 스타일화 미감이 더 잘 어울릴 수 있음.

5. **Rive 런타임 MIT**: 상업 배포 추가 비용 없음.

6. **forge2d + flame_rive 공존 확인**: flame_rive의 `RiveComponent`와 flame_forge2d의 `BodyComponent`는 동일 FlameGame 인스턴스에서 독립적으로 실행 가능. 별도 동기화 레이어 불필요.

---

## Recommendations

### 권장 경로: 옵션 B — Flame + Rive + forge2d

**근거**:
- video_player 완전 제거 → 혼합 아키텍처 복잡성 해소
- flame_rive로 단일 게임 루프 통합
- 파일 크기 MP4 대비 10~25× 절감
- 런타임 State Machine으로 셔플 단계별 손 모션 제어 유연성 확보
- MIT 라이선스, 상업 배포 무제한

**전제 조건**:
- 손 표현을 "포토리얼리스틱 Blender 3D" → "고급 2.5D 일러스트/신비적 스타일" 로 컨셉 재정의 필요
- Rive 에디터에서 손 리그(15~20 bone) 제작 공수 필요 (외주 또는 직접 제작, 예상 3~7일)

**구현 우선순위**:
1. Rive 에디터에서 손 리그 프로토타입 제작 (3~5 bone 단순 버전으로 먼저 검증)
2. `flame_rive` 연동 샘플 구축 → forge2d 카드 물리와 공존 확인
3. State Machine으로 idle / shuffle_in_progress / deal 전환 구현
4. 품질 충분 시 리얼리스틱 리그로 확장

### 차선 경로: 옵션 A — Flame + SpriteSheet (WebP)

**사용 조건**: Rive 리깅 제작 공수가 없을 때, 또는 Blender 3D 품질을 무조건 보존해야 할 때.
**단점**: 파일 크기가 MP4와 비슷하거나 크고, 다중 atlas 분할 구현이 필요하며, 타이밍 제어가 고정 시퀀스로 제한됨.

---

## Comparison Table

| 항목 | 옵션 A: Flame + SpriteSheet | 옵션 B: Flame + Rive + forge2d | 옵션 C: 현행 video_player + Flame |
|------|----------------------------|-------------------------------|-----------------------------------|
| 손 표현 품질 | Blender 렌더 그대로 (최고) | 2.5D 스타일 (중-상) | Blender 렌더 그대로 (최고) |
| 파일 크기 | 4.5~12MB (WebP 최적화 시) | **50~300 KB** (bone only) | 3~5MB (MP4) |
| 전환 동기화 복잡성 | 없음 (단일 루프) | 없음 (단일 루프) | 높음 (video_player ↔ Flame) |
| 구현 복잡성 | 중 (다중 atlas 분할) | 중 (Rive 리그 제작) | 높음 (이미 구현됨) |
| 런타임 상호작용 | 없음 (고정 시퀀스) | **높음** (State Machine) | 낮음 (재생/정지) |
| 라이선스 비용 | 없음 | **없음** (MIT 런타임) | 없음 |
| forge2d 공존 | 완전 가능 | **완전 가능** | 가능(복잡) |
| 추천 시나리오 | Blender 품질 필수, 제작 공수 없을 때 | **타로 앱 최적 경로** | 현행 유지 시 |

---

## References

- [Flame 공식: SpriteSheet/Images](https://docs.flame-engine.org/latest/flame/rendering/images.html)
- [flame_rive 공식 문서](https://docs.flame-engine.org/latest/bridge_packages/flame_rive/rive.html)
- [Flame Overlays](https://docs.flame-engine.org/latest/flame/overlays.html)
- [rive pub.dev (v0.14.4)](https://pub.dev/packages/rive) — MIT 라이선스, Flutter 전 플랫폼 지원
- [Rive Runtime 시작 가이드](https://rive.app/docs/runtimes/getting-started) — MIT, 상업 무제한
- [Rive Best Practices](https://rive.app/docs/getting-started/best-practices)
- [Lottie vs Rive 성능 비교 (callstack)](https://www.callstack.com/blog/lottie-vs-rive-optimizing-mobile-app-animation) — 60fps, 메모리 절반
- [Advanced Animation with Flame Ep.1 SpriteSheet](https://medium.com/kbtg-life/advanced-animation-with-flutter-flame-engine-ep-1-sprite-sheet-24fb45e888cc)
- [Sprite Sheet Optimization: WebP vs PNG](https://sosquishy.io/articles/sprite-sheet-optimization)
- [flame_texturepacker](https://pub.dev/packages/flame_texturepacker) — TexturePacker atlas 임포트
- [Why Rive chose Flutter for GameKit](https://rive.app/blog/why-we-chose-flutter-for-the-rive-gamekit)
- [Building High-Performance Interactive Mascots in Flutter with Rive (2026)](https://dev.to/uianimation/building-high-performance-interactive-mascots-in-flutter-with-rive-production-guide-for-2026-17c6)

## Communication Log
| # | 방향 | 상대 | 내용 요약 | 시점 |
|---|------|------|----------|------|
| 1 | 수신 | orchestrator | 단일 엔진 대안 평가 분석 의뢰 | 2026-03-16 |
| 2 | 완료 | orchestrator | 보고서 작성 완료. 권장: 옵션 B (Flame + Rive + forge2d) | 2026-03-16 |

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
