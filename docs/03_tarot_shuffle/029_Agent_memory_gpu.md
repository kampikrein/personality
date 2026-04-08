---
id: "029"
title: "video_player + Flame 메모리 & GPU 동시 부담 분석"
category: agent
status: archived
created: 2026-03-16
summary: >
  Flutter video_player와 Flame/forge2d 동시 실행 시 모바일 메모리·GPU 부담 분석.
  저사양(2GB) 기기에서 동시 활성화 시 OOM 위험 높음; 순차 전환 패턴으로 완화 가능.
keywords: [agent-report, memory, GPU, video_player, Flame, forge2d, Impeller, OOM]
modules: []
---
# video_player + Flame 메모리 & GPU 동시 부담 분석

## Progress
### Completed
- [x] video_player 메모리 footprint 조사
- [x] Flame + forge2d 78개 body 메모리 조사
- [x] 동시 실행 누적 부담 및 OOM 위험
- [x] Impeller GPU 파이프라인 공유 방식
- [x] dispose() 타이밍과 메모리 해제
- [x] 비교 표 작성
### Remaining
- (없음)
### Current Status
조사 완료.

---

## Summary

Flutter video_player(단일 720p)와 Flame+forge2d(78 bodies) 동시 실행 시 모바일 총 메모리 압력은 **180–320 MB RSS** 범위로 추정된다. 저사양 기기(2 GB RAM)에서는 안전 사용 가능 RAM이 약 700–900 MB에 불과해 OOM 위험이 실질적이다. 단, 영상 재생 후 video_player를 즉시 dispose()하고 Flame을 초기화하는 **순차 전환 패턴**을 사용하면 피크 메모리를 ~100–150 MB 줄일 수 있어 중급(4 GB) 이상 기기에서는 사실상 무위험 범주에 들어간다.

GPU 측면에서 Impeller + Vulkan(Android) 조합은 video_player 텍스처를 별도 GL 컨텍스트에서 Vulkan 이미지로 blit-copy하는 구조로 **GPU 파이프라인이 물리적으로 분리**된다. 따라서 video_player와 Flame이 동시에 활성화되면 GPU 커맨드 큐와 VRAM이 이중 소모된다. iOS(Metal)는 CVPixelBuffer → Metal 텍스처 경로로 더 효율적이지만 역시 별도 렌더 패스를 사용한다.

---

## Details

### 1. video_player 메모리 footprint

#### 플랫폼 구현
- **Android**: ExoPlayer 기반. SurfaceProducer API(2024 마이그레이션)를 통해 Vulkan/OpenGL 이중 경로 지원.
- **iOS**: AVPlayer 기반. CVPixelBuffer → Metal 텍스처 경로.

#### 메모리 소비 추정
공식 벤치마크 숫자는 존재하지 않으나, GitHub 이슈 및 커뮤니티 보고를 통해 추정:

| 상태 | Android (ExoPlayer) | iOS (AVPlayer) |
|------|--------------------|--------------:|
| 컨트롤러 초기화 직후 (idle) | ~20–40 MB 추가 | ~15–30 MB 추가 |
| 720p 재생 중 (디코더 + 텍스처 버퍼) | ~60–120 MB 추가 | ~50–100 MB 추가 |
| dispose() 완료 후 | ~0 (릴리즈, GC 지연 10–30초 가능) | ~0 (릴리즈) |

**근거:**
- Android 이슈 #129242: 4개 동시 재생 → heap 256 MB 도달 후 OOM 크래시 (기기당 ~64 MB/개 추정)
- 이슈 #139347: iPad 5th gen(2 GB) + 5개 1080p 동시 초기화 → iOS OOM Kill
- 버전 2.0.0→2.0.2 사이 iOS 11% 메모리 증가, Android 2–3% 증가 이력 있음
- 텍스처 버퍼: 720p RGBA = 1280×720×4 bytes = ~3.5 MB/프레임, 디코더는 보통 2–8 프레임 버퍼를 유지

#### Known Issues
- `dispose()` 없이 페이지 이동 시 메모리 누수 발생 (위젯 소멸 후에도 네이티브 플레이어 잔류)
- 리스트뷰 스크롤 중 복수 컨트롤러 누적은 heap 256 MB 초과로 OOM 유발
- iOS에서 장시간 재생 시 점진적 메모리 증가 (notification observing 누수는 패치됨)

---

### 2. Flame + forge2d 메모리 footprint

#### Flame 기반 메모리 구조
- **Flutter 엔진 베이스라인**: ~15 MB (Dart isolate + C++ 엔진, 공유 라이브러리 제외)
- **FlameGame + GameWidget 초기화**: 추가 ~20–40 MB (Flame 게임 루프, 컴포넌트 트리, Dart 힙)
- **스프라이트/텍스처 로딩**: 카드 이미지 수 × 크기에 따라 가변

#### forge2d 78개 rigid body 메모리
- **Box2D/forge2d 물리 월드 기본**: ~16–100 KB (b2BlockAllocator 고정 할당)
- **Body 1개당**: struct ~200–400 bytes (위치, 속도, 질량, 변환 행렬 등)
- **78개 bodies 순수 물리 데이터**: ~15–30 KB (무시할 수준)
- **타로 카드 78장 스프라이트 (256×448 RGBA)**: 약 ~110 KB/장 → 78장 합계 ~8.5 MB (미압축 GPU 텍스처)
- **타로 전용 추가 GPU 텍스처 메모리**: 78장 풀 해상도 유지 시 ~10–30 MB (mipmap 포함)

#### iOS 벤치마크 참조
- Filip Hracek 벤치마크(2024-08): Flutter+Flame vs Unity+Godot → Flame이 iOS에서 **더 낮은 RSS** 유지
- Flame으로 1000 엔티티 시뮬레이션 → iOS 60 FPS 유지 가능, 600–1,500 엔티티까지 성능 유지
- 78개 rigid body는 Flame 성능 한계의 5–13%에 불과 → 물리 연산 자체는 경량

#### Flame GameWidget 총 메모리 추정
| 구성요소 | 메모리 |
|---------|-------|
| Dart 힙 + Flame 프레임워크 | 30–50 MB |
| forge2d 물리 월드 (78 bodies) | <1 MB |
| 타로 카드 텍스처 (78장, GPU) | 10–30 MB |
| 셔플 애니메이션 버퍼 | 5–15 MB |
| **Flame 활성 실행 합계** | **~45–96 MB** |

---

### 3. 동시 실행 누적 부담 및 OOM 위험

#### 메모리 누적 시나리오

| 시나리오 | 예상 RSS |
|---------|---------|
| 앱 시작 (Flutter 엔진만) | ~50–80 MB |
| + video_player 초기화 + 720p 재생 | +60–120 MB → 총 **110–200 MB** |
| + Flame GameWidget 동시 활성화 | +45–96 MB → 총 **155–296 MB** |
| 피크 (디코더 버퍼 + Flame 텍스처 풀 로딩 시) | **최대 ~320 MB** |

#### 기기별 위험도 평가

Android Low Memory Killer(LMKD)는 여유 메모리가 임계값 이하로 떨어지면 프로세스를 종료한다. iOS는 메모리 경고(didReceiveMemoryWarning) 이후 OOM Kill한다.

| 기기 RAM | OS 점유 후 가용 RAM | 동시 실행 위험도 | 비고 |
|---------|-----------------|--------------|-----|
| 2 GB (저사양) | ~700–900 MB | **HIGH** - OOM 실질 위험 | 320 MB 피크는 백그라운드 앱 포함 시 50%+ 소비 |
| 4 GB (중급) | ~2,000–2,400 MB | **LOW–MEDIUM** | 여유 충분, 단 메모리 누수 주의 |
| 6–8 GB (고급) | ~4,000–5,500 MB | **NEGLIGIBLE** | 실질적 위험 없음 |

**핵심 위험 요소**:
- 복수 video_player 컨트롤러 동시 유지 (단일 컨트롤러 원칙 지켜야 함)
- Flame 텍스처 미리 로딩 + 영상 동시 재생
- dispose() 후 GC 지연 중 다음 할당이 겹치는 시점

---

### 4. Impeller GPU 파이프라인 공유 방식

#### Android (Impeller + Vulkan)

```
video_player (ExoPlayer)
  → SurfaceProducer API
  → [GL 컨텍스트] SurfaceTexture → GL 텍스처
  → [Blit Pass] GL_TEXTURE_EXTERNAL_OES → Vulkan Image (메모리 복사 발생)
  → Impeller Vulkan 렌더러 → 최종 합성

Flame (GameWidget)
  → Flutter Canvas API
  → Impeller Vulkan 렌더러 → 최종 합성
```

**핵심**: video_player는 GL + Vulkan 이중 GPU 컨텍스트를 사용. 텍스처 blit-copy 시 VRAM 중복 사용(원본 GL 텍스처 + 복사본 Vulkan 이미지 동시 존재). Flame은 Impeller Vulkan 단일 경로. **파이프라인이 공유되지 않음.**

GPU 부담:
- video_player: 디코딩 버퍼(CPU) + GL 텍스처(VRAM) + Vulkan blit 대상(VRAM) = **VRAM 이중 점유**
- Flame: Impeller 렌더 패스 + 스프라이트 텍스처(VRAM)

#### iOS (Impeller + Metal)

```
video_player (AVPlayer)
  → CVPixelBuffer
  → [Metal] CVMetalTextureCacheCreateTextureFromImage → MTLTexture
  → Impeller Metal 렌더러

Flame (GameWidget)
  → Flutter Canvas API
  → Impeller Metal 렌더러
```

iOS는 CVPixelBuffer → Metal 텍스처 직접 매핑으로 Android보다 효율적. 별도 blit 불필요. 그러나 여전히 별도 렌더 패스를 사용하므로 GPU 커맨드 큐에 두 시스템의 명령이 순차 제출된다.

#### GPU VRAM 추정

| 항목 | Android (Vulkan) | iOS (Metal) |
|-----|----------------|-----------|
| 720p 비디오 GL 텍스처 | ~3.5 MB | - |
| 720p 비디오 Vulkan/Metal 텍스처 | ~3.5 MB | ~3.5 MB |
| blit 오버헤드 (Android만) | ~3.5 MB (중복) | 0 |
| Flame 타로 텍스처 (78장) | ~10–30 MB | ~10–30 MB |
| Impeller 렌더 타겟/MSAA 버퍼 | ~5–15 MB | ~5–15 MB |
| **GPU VRAM 합계** | **~25–55 MB** | **~18–48 MB** |

---

### 5. dispose() 타이밍과 최적화 패턴

#### 권장 패턴: 순차 전환 (Sequential Handoff)

```
[셔플 시작]
  ↓
video_player.initialize() + play()  ← 영상 단독 활성화
  ↓ (영상 종료 이벤트)
video_player.pause()
video_player.dispose()              ← 즉시 dispose (await 필수)
  ↓ (dispose 완료 후)
FlameGame.mount() / GameWidget 표시 ← Flame 단독 활성화
```

이 패턴의 메모리 피크:
- video_player 활성: ~110–200 MB
- 전환 중 (~1–2초): 두 시스템 중첩 → ~155–260 MB (과도기)
- Flame 활성: ~95–176 MB

#### 비권장 패턴: 동시 활성화

```
video_player (playing) + Flame (active) = ~155–320 MB 상시 유지
→ 저사양 기기에서 OOM 위험
```

#### Flame 워밍업 전략

```dart
// 권장: 영상 재생 중 Flame을 Offscreen에서 미리 초기화
// (텍스처 로딩만, 게임 루프 최소화)
// → 전환 지연 감소 + 메모리 피크 최소화
```

단, **동시 초기화는 메모리 압박을 높이므로** 워밍업을 사용할 경우 Flame 텍스처를 lazy-load로 제한하는 것이 안전하다.

#### dispose() 지연 주의

- `dispose()` 후 Dart GC가 실제 네이티브 메모리를 회수하기까지 10–30초 지연 발생 가능
- `await controller.dispose()` 직후 곧바로 Flame 대형 텍스처를 로딩하면 GC 전 피크가 발생
- 해결책: `dispose()` → 짧은 Frame delay (1–2 frames) → Flame mount

---

## Key Findings

1. **메모리 분리 원칙**: video_player와 Flame은 동시에 활성화하지 말 것. 영상 종료 후 즉시 dispose(), 그 후 Flame 활성화. 이것만으로 저사양 기기 OOM 위험을 크게 낮출 수 있다.

2. **GPU 파이프라인은 공유되지 않는다**: Android(Vulkan)에서 video_player는 GL + Vulkan 이중 컨텍스트를 사용하며 텍스처가 VRAM에 2중으로 점유된다. iOS(Metal)는 더 효율적이지만 여전히 별도 렌더 패스.

3. **78개 rigid body는 경량이다**: forge2d의 물리 데이터 자체는 ~30 KB 미만. 메모리 부담의 실질 원천은 타로 카드 텍스처(~10–30 MB)다.

4. **단일 video_player 컨트롤러 원칙 유지**: 복수 컨트롤러 동시 보유는 지수적 메모리 증가를 초래한다. 타로 셔플 앱에서는 한 번에 하나의 영상만 재생하면 된다.

5. **iOS가 Android보다 GPU 효율적이다**: iOS는 Metal 직접 매핑으로 blit copy 없음. Android Impeller+Vulkan은 blit 오버헤드로 ~3.5 MB VRAM 추가 소비.

6. **저사양(2 GB) 기기는 OOM 실질 위험**: 동시 활성화 피크 ~320 MB + OS + 기타 앱 = 위험. 순차 전환 패턴 필수.

---

## Recommendations

### 우선순위 1: 순차 전환 아키텍처 채택

```
Phase A: video_player 단독 (셔플 영상 재생)
Phase B: dispose() 후 → Flame 단독 (실시간 물리)
```
두 Phase를 절대 동시에 활성화하지 않는다.

### 우선순위 2: 단일 VideoPlayerController 패턴

```dart
// ✅ 올바른 패턴
late VideoPlayerController _controller;
// 사용 후 반드시:
await _controller.dispose();
_controller = VideoPlayerController.asset(...); // 필요 시만 재생성
```

### 우선순위 3: Flame 텍스처 Lazy Loading

78장 전체 텍스처를 미리 로딩하지 말고, 실제 사용 직전에 로딩. 셔플 결과에서 선택된 3–5장만 유지하는 LRU 캐시 적용.

### 우선순위 4: 저사양 기기 감지 및 다운그레이드

```dart
// RAM 감지 후 품질 조정 (Android)
final memInfo = await DeviceInfoPlugin().androidInfo;
// < 3 GB RAM: 영상 해상도 480p로 제한
// ≥ 4 GB RAM: 720p 사용
```

### 우선순위 5: dispose() 후 프레임 지연

```dart
await _videoController.dispose();
await Future.delayed(Duration(milliseconds: 100)); // GC 트리거 여유
// 또는 WidgetsBinding.instance.addPostFrameCallback 활용
setState(() => _showFlame = true);
```

---

## 비교 요약 표

| 시스템 | 초기화 메모리 | 활성 실행 메모리 | 합계(동시) | 저사양(2GB) 위험도 |
|--------|------------|--------------|---------|----------------|
| Flutter 엔진 베이스라인 | ~50–80 MB | (포함) | - | - |
| video_player (720p 단독) | +20–40 MB | +60–120 MB | **~110–200 MB** | 낮음 |
| Flame + forge2d 78 bodies (단독) | +30–50 MB | +45–96 MB | **~95–176 MB** | 낮음 |
| **두 시스템 동시 활성화** | - | - | **~155–320 MB** | **HIGH** |
| 순차 전환 패턴 (피크) | - | - | **~155–260 MB** (과도기 1–2초) | MEDIUM |
| 순차 전환 패턴 (안정 상태) | - | - | **~95–200 MB** (단일 시스템) | 낮음 |

*모든 수치는 Flutter 엔진 베이스라인 포함, 앱 UI 위젯 메모리 제외. 실제값은 기기, OS 버전, 영상 코덱에 따라 ±30% 변동 가능.*

---

## References

- [flutter/flutter #129242 - video_player eating lot of memory on Android](https://github.com/flutter/flutter/issues/129242)
- [flutter/flutter #139347 - Multiple video players OOM on iPad](https://github.com/flutter/flutter/issues/139347)
- [flutter/flutter #78169 - memory usage increased in latest versions](https://github.com/flutter/flutter/issues/78169)
- [flutter/packages #6456 - SurfaceTexture→SurfaceProducer migration](https://github.com/flutter/packages/pull/6456)
- [flutter/flutter #137639 - Impeller: external texture support for Vulkan](https://github.com/flutter/flutter/issues/137639)
- [Filip Hracek - Benchmarking Flutter, Flame, Unity and Godot (Aug 2024)](https://filiph.net/text/benchmarking-flutter-flame-unity-godot.html)
- [Alibaba Cloud - Flutter External Texture Rendering Architecture](https://www.alibabacloud.com/blog/flutter-analysis-and-practice-same-layer-external-texture-rendering_596580)
- [Android LMKD Documentation](https://source.android.com/docs/core/perf/lmkd)
- [Flutter Impeller Documentation](https://docs.flutter.dev/perf/impeller)

## Communication Log
| # | 방향 | 상대 | 내용 요약 | 시점 |
|---|------|------|----------|------|
| 1 | 수신 | 오케스트레이터 | 메모리·GPU 동시 부담 분석 과제 수신 | 2026-03-16 |
| 2 | 완료 | 오케스트레이터 | 5개 항목 조사 완료, 보고서 저장 완료 | 2026-03-16 |

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
