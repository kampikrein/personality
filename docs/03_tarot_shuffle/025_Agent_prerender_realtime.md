---
id: "025"
title: "프리렌더 vs 실시간 혼합 전략 분석"
category: agent
status: archived
created: 2026-03-16
summary: >
  타로 셔플 앱을 위한 프리렌더(손 모션) + 실시간 물리(가속도계) 혼합 아키텍처 패턴.
  Unity 오프라인 렌더 도구 사용 라이선스, 혼합 전환 기법, 파일 크기 트레이드오프 분석.
keywords: [agent-report, pre-render, realtime, physics, hybrid, video, sprite-sheet, Flutter]
modules: []
---

# 프리렌더 vs 실시간 혼합 전략 분석

## Progress
### Completed
- [x] 프리렌더 방식 종류 및 파일 크기/품질 비교
- [x] Unity를 오프라인 도구로만 사용 시 라이선스 조사
- [x] Blender 무료 3D 렌더링 대안 조사
- [x] Flutter에서 프리렌더 + 실시간 물리 혼합 구현 패턴
- [x] 모드 전환 기법 (영상→물리 시뮬레이션 전환)
- [x] 실제 구현 사례 수집
- [x] 파일 크기 vs 품질 트레이드오프 분석
- [x] 저사양 기기 폴백 전략
### Remaining
- (없음)
### Current Status
조사 완료. 최종 보고서 작성됨.

---

## Summary

**핵심 결론: Blender(무료) + Flutter video_player + Flame/forge2d 혼합 아키텍처 권장.**

- Unity는 오프라인 렌더링 도구로 사용하더라도 **비게임 용도에 Unity Industry 플랜($4,950/년) 필요** → 소규모 앱에 과도한 비용
- Blender는 GPL이지만 **렌더 출력물(영상 파일)은 완전 자유 상업 사용** → 비용 없음
- 혼합 패턴: `손 모션 영상(mp4) → Stack 위에 Flame/forge2d 물리 레이어` + `AnimatedCrossFade` 전환
- 최적 전환 기법: 영상 마지막 프레임 → 물리 카드 초기 상태 연속 배치 → 크로스페이드 0.3s
- 5초 720p mp4 손 모션 영상 예상 크기: **약 2~5MB** (H.264 CRF 26~28)

---

## Details

### 1. Unity 라이선스 — 오프라인 렌더링 도구 전용 사용

#### 조사 결과

Unity의 라이선스 구조는 다음과 같다:

| 플랜 | 연매출 기준 | 용도 제한 | 가격 |
|------|-----------|---------|------|
| Unity Personal | $200K 미만 | **게임·엔터테인먼트 전용** | 무료 |
| Unity Pro | $200K~$25M | 게임 포함 | $2,310/년 |
| Unity Industry | $1M 이상 | **비게임 용도 포함** | $4,950/년 |
| Unity Enterprise | $25M+ | 전용 | 커스텀 |

**핵심 발견**: Unity 공식 제품 페이지(unity.com/products)에 명시 — "Unity Personal is for gaming and entertainment applications only."

즉, **타로 앱(비게임 영역에 포함될 수 있음)을 위한 Unity 오프라인 렌더링은 Personal 플랜으로 합법적이지 않을 가능성이 높다.** 단, 타로 앱 자체가 "게임 앱"으로 분류된다면 Personal이 허용될 여지는 있다.

#### Unity 런타임 배포 문제

2024년 9월, Unity는 논란이 된 Runtime Fee를 완전 폐기했다. 따라서 **Unity 런타임이 배포 앱에 포함되더라도 런타임 수수료는 없다.** 그러나 우리의 접근법(Unity로 영상 렌더 → Flutter 앱에 mp4만 포함)에서는 Unity 런타임이 배포 앱에 들어가지 않으므로 이 이슈 자체가 무관하다.

#### "Made with Unity" 로고 요건

"Made with Unity" 로고는 Unity로 만든 **게임 또는 소프트웨어 앱을 배포할 때** 표시할 수 있는(may) 권리지, 의무(must)가 아니다. 오프라인 렌더링 도구로만 사용하고 영상 파일만 배포 앱에 포함하면 로고 표시 의무 없다.

#### 결론

- Unity Personal → **비게임 앱 용도로는 TOS 위반 가능성** → 사용 회피 권장
- Unity Pro → $2,310/년 — 소규모 MVP에 과도
- **대안: Blender(무료) 사용으로 라이선스 이슈 완전 회피**

---

### 2. Blender — 무료 3D 렌더링 대안

#### GPL 라이선스와 렌더 출력물

Blender 공식 라이선스 문서(blender.org/about/license/)에 명확히 기재:

> "What you create with Blender is your sole property. All your artwork – images or movie files – including the .blend files and other data files Blender can write, is free for you to use as you like."

GPL은 **소프트웨어 배포에만 적용**된다. Blender를 도구로 사용해 렌더링한 결과물(mp4, PNG 시퀀스 등)은 GPL 적용을 받지 않으며, **완전히 자유롭게 상업 앱에 포함 가능**하다.

#### Blender의 손/손가락 리깅 수준

- Blender 4.x에 Advanced Hand Rigging 튜토리얼이 공식 커뮤니티에서 다수 제공됨
- IK(Inverse Kinematics) solver 기반 손가락 각 관절 제어 가능
- Sketchfab, Blend Swap 등에서 무료 리깅된 손 모델 다운로드 가능
- **Unity의 3D 손 표현과 동등한 수준** — 차이는 렌더러 품질에서 발생

#### Blender Cycles vs EEVEE 비교 (손 모션 렌더 기준)

| 항목 | Cycles | EEVEE |
|------|--------|-------|
| 렌더 원리 | 물리 기반 패스 트레이서 (광선 추적) | 래스터라이제이션 (실시간 근사) |
| 품질 | 최고 (그림자, 반사, 피부 SSS 완벽) | 중상 (빠른 근사, 약간 부자연스러운 조명) |
| 렌더 속도 | 느림 (550프레임 기준 ~5시간) | 빠름 (같은 조건 ~1시간 43분) |
| 하드웨어 요구 | GPU 권장 | 일반 노트북도 가능 |
| 모바일 영상 용도 | **권장** (최종 품질) | 프리뷰/빠른 반복 작업 용 |

**타로 앱 권장**: Cycles로 최종 렌더링 (1회성 오프라인 렌더, 속도보다 품질 우선)

---

### 3. 프리렌더 방식 종류별 비교

#### 방식 A: MP4 영상 파일 (H.264/H.265)

- Flutter 패키지: `video_player` (pub.dev 공식)
- 장점: 최고 품질 (Blender Cycles 조명, 피부 재질 표현), 파일 크기 대비 최고 화질
- 단점: 투명도(알파 채널) 미지원 (H.264 기준), 메모리 이슈 보고 있음
- 실제 이슈: video_player는 **반복 초기화 시 메모리 누수** 사례 보고됨 (flutter/flutter#129242)
- 크기 추정:
  - 720p / 30fps / 5초 / CRF 26 → **약 2~4MB**
  - 1080p / 30fps / 5초 / CRF 26 → **약 4~8MB**
  - 30초 이하 영상은 압축 후 일반적으로 1~5MB 범위
- 알파 채널이 필요하면: WebM(VP8/VP9) 포맷 사용 — Flutter에서 `video_player` 지원

#### 방식 B: PNG 시퀀스 (스프라이트 시트)

- Flutter 접근: Flame SpriteSheet, flutter_sprite, CustomPainter
- 장점: GPU 텍스처 직접 렌더링, 투명도(알파) 완벽 지원, 프레임 단위 제어
- 단점: **파일 크기 매우 큼** (무손실 PNG)
  - 5초 / 30fps = 150프레임
  - 720p 프레임 하나 = ~1~2MB (무손실) → **총 150~300MB** (실사용 불가)
  - 실사용: 720x720 크기 이하, 15fps로 낮추거나, WebP 손실 압축 적용
  - 현실적 크기: 512px / 15fps / 5초 = 75프레임 → WebP 50~80KB/프레임 → **~5MB**
- 스프라이트 시트 최대 이슈: 1장 이미지에 모든 프레임 → 4096px 한계 내 배치 필요

#### 방식 C: Spine 2D 스켈레탈 애니메이션

- Flutter 패키지: `spine_flutter` (EsotericSoftware 공식, pub.dev 존재 확인)
- 라이선스 이슈 **치명적**: 앱을 배포하려면 Spine Editor 라이선스 구매 필요
  - Spine Pro: 약 $299 (1회성) — 소규모에서 수용 가능하나 3D 손 표현 불가
  - **Spine는 2D 전용** → 3D 렌더링된 손 모션에 직접 사용 불가
- 결론: 타로 앱에서 3D 손 표현에는 부적합

#### 방식 D: Lottie 애니메이션

- Flutter 패키지: `lottie` (pub.dev)
- 라이선스: 무료, MIT
- **근본적 한계**: Flutter의 CustomPainter는 2D 캔버스 — Lottie는 After Effects에서 만든 2D 벡터 애니메이션만 지원
- 3D 렌더링된 손 모션 → Lottie 변환 불가
- 커뮤니티 보고: "3D Lottie animation is rendering in 2D" — 3D 효과가 2D로 평탄화됨
- 결론: 타로 손 모션에 부적합

#### 방식 E: Rive 애니메이션 (추가 검토)

- Flutter 패키지: `rive` (pub.dev)
- 라이선스: 무료 개인 플랜 / 팀 플랜 $14/월
- Lottie보다 강력한 상태 머신 지원, Flutter 통합 뛰어남
- **동일 한계**: 2D 벡터 기반 — Blender/Unity 렌더 수준의 3D 손 표현 불가
- 결론: 카드 UI 인터랙션에는 우수하나 손 모션 렌더링에는 부적합

---

**표 1: 프리렌더 방식 비교**

| 방식 | 라이선스 | 파일 크기(5초) | 품질 | Flutter 통합 | 3D 손 표현 | 투명도 | 추천 |
|------|---------|-------------|------|------------|----------|--------|------|
| MP4 H.264 | 무료 | 2~8MB | 최고 | video_player | O (Blender 렌더) | X (알파 없음) | **1순위** |
| WebM VP9 | 무료 | 3~10MB | 최고 | video_player | O (Blender 렌더) | O (알파 지원) | 투명도 필요 시 |
| PNG 시퀀스 | 무료 | 50~300MB+ | 최고 | Flame/CustomPainter | O | O | X (크기 과대) |
| WebP 시퀀스 | 무료 | 5~15MB | 높음 | CustomPainter | O | O | 2순위(저용량) |
| Spine 2D | $299 (1회) | 1~3MB | 중 (2D) | spine_flutter | X (2D만) | O | X |
| Lottie | 무료 | 0.1~2MB | 낮음 | lottie | X (2D만) | O | X |
| Rive | 무료 | 0.5~3MB | 중 (2D) | rive | X (2D만) | O | 카드 UI 용 |

---

### 4. 혼합 아키텍처 구현 패턴

#### 시나리오 요약

```
[Phase 1] 셔플 시퀀스 (3~5초)
  → 손 등장 + 카드 섞기
  → 프리렌더 영상 재생 (video_player)
  → 사용자 입력 없음, 시각적 몰입

[전환점] 영상 종료 (videoController.addListener)
  → 마지막 프레임 정지 or 크로스페이드

[Phase 2] 탐색 모드 (사용자 주도)
  → 폰 기울이기 → 카드 쏠림
  → sensors_plus 가속도계 + Flame/forge2d 물리
  → 실시간 물리 시뮬레이션 활성화
```

#### 패턴 A: Stack 레이어 + 영상 종료 이벤트

```dart
// Flutter Stack 구조
Stack(
  children: [
    // 하단: 프리렌더 영상 레이어
    VideoPlayer(videoController),

    // 상단: Flame 물리 게임 레이어 (초기 opacity: 0)
    AnimatedOpacity(
      opacity: _physicsActive ? 1.0 : 0.0,
      duration: Duration(milliseconds: 300),
      child: GameWidget(game: cardPhysicsGame),
    ),
  ],
)

// 영상 종료 감지 → 물리 활성화
videoController.addListener(() {
  if (videoController.value.position >= videoController.value.duration) {
    setState(() => _physicsActive = true);
    _sensorSubscription = accelerometerEventStream().listen(_onAccelerometer);
  }
});
```

- 장점: 구조 단순, Flutter 네이티브 위젯 조합
- 단점: video_player 위에 위젯 렌더링 시 일부 기기에서 렌더 순서 이슈 (flutter/flutter#135589)
- 해결: `VideoPlayer`를 `Texture` 위젯으로 감싸고 Stack 최하단 배치

#### 패턴 B: 상태 머신 전환 (권장)

```
AppState:
  IDLE → SHUFFLE_PRERENDER → TRANSITION → PHYSICS_EXPLORE → CARD_SELECT
```

- `state_machine_animation` 패키지 활용 가능
- 전환 트리거:
  - IDLE → SHUFFLE: 사용자 탭 (셔플 시작)
  - SHUFFLE → TRANSITION: 영상 완료 이벤트
  - TRANSITION → PHYSICS: 크로스페이드 완료 (300ms)
  - PHYSICS → CARD_SELECT: 카드 탭 감지
- 각 상태에서 센서 구독/해제 명확히 관리 → 배터리 절약

```
SHUFFLE_PRERENDER 상태:
  - videoController.play()
  - sensorSubscription = null (센서 OFF)

TRANSITION 상태:
  - AnimatedCrossFade (영상 위젯 ↔ 물리 위젯)
  - duration: 300ms
  - 물리 초기 카드 위치 = 영상 마지막 프레임의 카드 위치와 일치시킴

PHYSICS_EXPLORE 상태:
  - sensorSubscription = accelerometerEventStream().listen(...)
  - forge2d/Flame 물리 활성
  - videoController.dispose() (메모리 해제)
```

- 장점: 전환 자연스러움, 메모리 관리 명확, 센서 생명주기 통제
- 단점: 구현 복잡도 중간

#### 패턴 C: 동적 텍스처 교체 (고급)

- 영상 마지막 프레임 → `renderRepaintBoundary`로 캡처
- 캡처된 이미지를 Flame의 카드 초기 텍스처로 사용
- 두 레이어가 시각적으로 동일한 상태에서 물리 레이어 활성화 → **완전 이음새 없는 전환**
- 구현 난이도: 높음
- 실제 필요 여부: 영상 마지막 프레임이 "카드들이 테이블에 펼쳐진 정적 상태"라면 정적 이미지로도 충분

**표 2: 혼합 아키텍처 패턴 비교**

| 패턴 | 전환 자연스러움 | 구현 복잡도 | 모바일 부담 | 메모리 관리 | 추천 시나리오 |
|------|--------------|-----------|-----------|-----------|------------|
| A: Stack + Opacity | 중 (깜빡임 가능) | 낮음 | 낮음 | 수동 | 빠른 프로토타입 |
| B: 상태 머신 + CrossFade | 높음 | 중간 | 낮음 | 자동(상태별) | **MVP 권장** |
| C: 동적 텍스처 교체 | 최고 | 높음 | 중간 | 수동 | 고품질 프로덕션 |

---

### 5. 실제 구현 사례

#### 타로/카드 앱에서 발견된 접근법

- **TrueTaroT** (Google Play): 3D 가상 덱 구현 — "정밀한 디테일, 색감, 텍스처의 몰입형 비주얼" 설명. 구체적 기술 스택 미공개
- **Behance 3D 타로 모션 디자인** (Maksim Solodkov): Cinema 4D + Redshift 렌더러 사용 — Blender 대안으로 Cinema 4D도 사용 사례 있음
- **HTML/JS 기반 타로 셔플**: CSS 애니메이션 + JavaScript 물리 — 모바일 Flutter에는 직접 적용 불가

#### 게임 앱의 컷신→인게임 전환 기법

- **Unreal Engine 사례**: 인엔진 컷신(실시간) → 게임플레이 전환이 사전렌더 영상보다 자연스러움
- **일반 모바일 게임**: 영상 비트레이트가 낮으면 블로키해져 게임플레이와 품질 차이 노출 → **영상 품질과 실시간 렌더 품질 매칭이 핵심**
- Flutter 커뮤니티: flutter_unity_widget으로 Unity를 Flutter에 임베드하는 사례 있음 — 단, Unity 런타임 배포 포함되므로 라이선스 필요

#### Flutter Flame + forge2d 가속도계 물리

- forge2d는 Box2D의 Dart 포트, Flame 공식 지원
- Google I/O 2024에서 Flutter + Flame 2D 물리 게임 세션 발표됨
- `sensors_plus`의 `accelerometerEventStream()`으로 가속도 값 → forge2d 중력 벡터 직접 제어 가능
- 카드 쏠림: `world.gravity = Vector2(ax * scale, ay * scale)` 실시간 업데이트

---

### 6. 파일 크기 & 저사양 폴백

#### 파일 크기 추정 (손 셔플 5초 시퀀스)

| 포맷 | 해상도 | fps | 품질 | 예상 크기 | 비고 |
|------|--------|-----|------|---------|------|
| MP4 H.264 | 1080p | 30 | CRF 26 | ~6~10MB | 최고 품질 |
| MP4 H.264 | 720p | 30 | CRF 26 | ~3~5MB | **권장 (균형)** |
| MP4 H.264 | 720p | 30 | CRF 28 | ~2~3MB | 약간 품질 손실 |
| WebM VP9 | 720p | 30 | 중간 | ~4~7MB | 알파채널 필요 시 |
| WebP 시퀀스 | 512px | 15 | 손실 80% | ~5~10MB | 투명 배경 필요 시 |
| PNG 시퀀스 | 720p | 30 | 무손실 | ~150~300MB | 실사용 불가 |

참고: 30초 이하 영상은 압축 후 보통 1~5MB 범위 (Cloudinary 문서 기준). 5초 고품질 손 모션은 720p CRF 26에서 3~5MB 현실적.

#### 저사양 기기 폴백 전략

**기준**: GPU 성능, RAM, Flutter DeviceInfo로 감지

```
고사양 기기 (RAM ≥ 4GB, 최근 3년 이내):
  → MP4 720p + forge2d 물리 전체 활성

중간 기기:
  → MP4 480p 다운그레이드 + 단순화된 forge2d (카드 수 감소)

저사양 기기 (RAM < 3GB, 또는 video_player 성능 미달):
  → Flutter 내장 Matrix4 + TweenAnimationBuilder로 2D 셔플 애니메이션
  → 가속도계는 유지하되 forge2d 없이 단순 Transform 적용

```

폴백 감지 방법:
- `video_player` 첫 프레임 렌더 시간 측정 (300ms 초과 시 저사양 분기)
- `device_info_plus` 패키지로 Android API level, iOS version 확인
- 앱 초기 실행 시 벤치마크 프레임 1회 실행 → 결과 SharedPreferences 캐시

---

## Key Findings

1. **Unity 오프라인 렌더 전용 사용은 비용 문제**: Personal 플랜이 "게임 전용"이며 비게임 앱에는 Industry 플랜($4,950/년) 요구. 소규모 MVP에 비현실적.

2. **Blender는 완전 무료 대안**: GPL이지만 렌더 출력물(mp4, PNG)은 상업 사용 자유. 3D 손 리깅 수준은 Unity와 동등. Cycles 렌더러로 최고 품질 오프라인 렌더 가능.

3. **MP4 방식이 최적의 프리렌더 포맷**: 5초 720p → 3~5MB. 최고 품질. Flutter video_player로 통합 용이. 단, 알파 채널이 필요하면 WebM VP9.

4. **Spine/Lottie/Rive는 3D 손 표현에 부적합**: 모두 2D 기반. 3D 렌더링된 손 모션을 표현 불가.

5. **혼합 전환의 핵심은 마지막 프레임-물리 초기 상태 일치**: 영상이 끝난 후 카드 위치가 물리 레이어의 카드 초기 위치와 동일해야 전환이 자연스러움. 영상 제작 단계에서 "마지막 프레임 카드 배치"를 Flame 초기 배치와 맞추는 설계가 필요.

6. **AnimatedCrossFade가 가장 현실적인 전환 구현**: 300ms 크로스페이드로 영상 → 물리 레이어 전환. state_machine_animation 패키지로 전체 앱 상태 관리.

7. **forge2d + sensors_plus 조합은 검증된 스택**: Flutter Flame 공식 지원, Google I/O 2024 발표 사례. 카드 중력 방향을 가속도계 값으로 실시간 제어 가능.

---

## Recommendations

### 권장 혼합 전략 (타로 앱 최종안)

```
[렌더링 도구] Blender (무료, Cycles 렌더러)
  └─ 손 모션 시퀀스 오프라인 렌더 → 720p MP4 H.264 (약 3~5MB)

[Flutter 아키텍처]
  ├─ Phase 1: video_player로 MP4 재생 (손 셔플 시퀀스)
  ├─ 전환: AnimatedCrossFade 300ms (영상 마지막 프레임 ↔ Flame 초기 상태)
  └─ Phase 2: Flame + forge2d + sensors_plus (가속도계 물리 카드)

[상태 관리]
  IDLE → SHUFFLING → TRANSITIONING → PHYSICS_EXPLORE → SELECTED

[폴백]
  저사양 → Matrix4 TweenAnimation (영상 없이 2D 애니메이션)
```

### 구현 우선순위

1. **Blender 손 리그 세팅** (무료 Rigged Hand blend 파일 활용)
2. **Blender Cycles 렌더링** → 720p MP4 출력
3. **Flutter: 영상 재생 + 마지막 프레임 정지**
4. **Flame + forge2d 초기 카드 레이아웃** (영상 마지막 프레임과 일치)
5. **AnimatedCrossFade 전환 구현**
6. **sensors_plus 가속도계 → forge2d gravity 연동**
7. **저사양 폴백 분기 추가**

### 주의 사항

- video_player 메모리 누수 이슈 → 물리 전환 후 즉시 `videoController.dispose()`
- WebM VP9 알파 채널: Android 지원 良, iOS는 일부 버전에서 제한 → 확인 필요
- Blender 렌더 시간: Cycles 720p 5초(150프레임) = 일반 노트북에서 1~3시간 → GPU 활용 권장

---

## References

- Blender 라이선스: https://www.blender.org/about/license/
- Unity 플랜 및 가격: https://unity.com/products
- Unity Runtime Fee 폐기 (2024.09): https://unity.com/blog/unity-is-canceling-the-runtime-fee
- spine_flutter pub.dev: https://pub.dev/packages/spine_flutter
- Blender Cycles vs EEVEE 비교: https://renderguide.com/blender-eevee-vs-cycles-tutorial/
- Flutter video_player 메모리 이슈: https://github.com/flutter/flutter/issues/129242
- Flutter AnimatedCrossFade: https://api.flutter.dev/flutter/widgets/AnimatedCrossFade-class.html
- Flame forge2d 공식 문서: https://docs.flame-engine.org/latest/bridge_packages/flame_forge2d/forge2d.html
- Flutter + Flame 2D 물리 게임 (Google I/O 2024): https://io.google/2024/explore/c47e984b-af2f-4f5f-bcde-e148a5a626bf/
- state_machine_animation 패키지: https://pub.dev/documentation/state_machine_animation/latest/
- 비디오 최적화: https://www.smashingmagazine.com/2021/02/optimizing-video-size-quality/
- 게임 컷신→게임플레이 전환: https://www.resetera.com/threads/smooth-real-time-transitions-into-gameplay-the-thread.838761/
- Blender 고급 손 리깅 (4.5 LTS): https://blenderartists.org/t/advanced-hand-rigging-tutorial-in-blender-4-5-lts-part1-part-2-part-3-part-4-part-5-rig-overview/1603936

## Communication Log
| # | 방향 | 상대 | 내용 요약 | 시점 |
|---|------|------|----------|------|
| 1 | 수신 | 오케스트레이터 | 프리렌더 vs 실시간 혼합 전략 분석 위임 | 2026-03-16 |
| 2 | 송신 | 오케스트레이터 | 조사 완료. Blender+MP4+Flame/forge2d 혼합 전략 권장 | 2026-03-16 |

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
