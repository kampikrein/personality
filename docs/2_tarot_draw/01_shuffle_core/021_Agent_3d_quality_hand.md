---
id: "021"
title: "3D 품질 & 손/손가락 표현력 분석"
category: agent
status: archived
created: 2026-03-16
summary: >
  Unity, Godot 4, Flame, three_dart, Babylon.js의 skeletal animation, bone rigging,
  손 모션 표현력 및 타로 카드 시각 품질 비교.
keywords: [agent-report, 3D quality, hand animation, skeletal, rigging, PBR, tarot]
modules: []
---

# 3D 품질 & 손/손가락 표현력 분석

## Progress
### Completed
- [x] Unity 3D 품질/손 표현 조사
- [x] Godot 4 3D 품질/손 표현 조사
- [x] Flame/flame_3d 조사
- [x] three_dart+flutter_gl 조사
- [x] Babylon.js 조사
- [x] Flutter 내장 Matrix4 한계 조사
- [x] 실제 레퍼런스 사례 수집
- [x] 비교 표 작성
### Remaining
- (없음)
### Current Status
조사 완료. 보고서 작성 완료.

---

## Summary

타로 셔플 앱에서 손이 등장해 카드를 섞는 3D 애니메이션 구현을 위해 6개 접근법의 skeletal animation 지원 수준, 손가락 bone 제어 능력, PBR 렌더링 품질을 조사했다.

**핵심 결론:**
- **Unity(URP)** 가 손가락 bone 제어, PBR 렌더링, 모바일 최적화 모든 면에서 가장 완성도가 높다.
- **Godot 4** 는 Unity에 준하는 skeletal 시스템을 제공하나 모바일 PBR 렌더링 품질이 일부 미흡하다.
- **Babylon.js+WebView** 는 WebGL 기반으로 PBR 완전지원, skeletal animation 완전지원이나 WebView 레이어 오버헤드가 있다.
- **three_dart** 는 Three.js 기반으로 SkinnedMesh 이론상 지원하나 Dart 포트가 3년 이상 업데이트 없어 신뢰도 낮다.
- **flame_3d** 는 실험적이며 skeletal animation을 공식 지원하지 않는다.
- **Flutter Matrix4** 는 실제 3D 지오메트리 없는 pseudo-3D로 손 표현이 원천적으로 불가능하다.

---

## Details

### 1. Unity — 3D 품질 & 손/손가락 표현

#### 1.1 Humanoid Rig 구조 및 손가락 bone 제어

Unity의 Humanoid Avatar 시스템은 손가락 bone을 완전히 지원한다. 각 손가락은 **Proximal → Intermediate → Distal** 의 3절 구조(엄지는 2절)로, 양손 합계 최대 **30개** 의 손가락 bone을 제어할 수 있다. Unity 공식 가이드라인은 모바일에서 bone 수를 30개 이하로 유지할 것을 권장한다.

손 포즈 제어 방식은 두 가지다:
- **Muscle 시스템**: Humanoid Avatar의 근육 파라미터(-1~1)로 각 관절의 굴곡을 제어. 서로 다른 캐릭터 간에 애니메이션 재사용 가능.
- **Animation Rigging (com.unity.animation.rigging)**: 런타임에서 절차적으로 손 포즈를 생성. TwoBoneIK, MultiAim, Override Transform 등의 Constraint로 손가락 IK 구현 가능. 단, 모바일에서 매 프레임 관절 재계산으로 인한 성능 오버헤드 주의.

VoxHands, HumanoidHandPoseHelper 등 Unity Asset Store 플러그인이 손 포즈 제작을 보조한다. 손 추적(MediaPipe, LightBuzz)을 통한 실시간 손가락 제어도 iOS/Android에서 가능하다.

#### 1.2 렌더 파이프라인 — HDRP vs URP

| 파이프라인 | 모바일 적합성 | PBR 수준 | 카드 광택/홀로그램 |
|-----------|-------------|---------|----------------|
| HDRP | **불가** (고사양 PC/콘솔 전용) | 최고 | 최고 |
| URP | **최적** (iOS/Android 기본 권장) | 높음 | Shader Graph로 완전 구현 가능 |
| Built-in | 구식, 비권장 | 중간 | 제한적 |

모바일에서는 **URP가 표준**이다. URP는 Forward+, Decals, PBR(metallic/roughness), Shader Graph, Post-processing을 완전 지원한다.

#### 1.3 카드 광택 & 신비로운 효과

Unity URP Shader Graph로 구현 가능한 효과:
- **홀로그램 셰이더**: Fresnel, 스캔라인, 글리치 효과 (Unity 6 URP 공식 예제 존재)
- **글리터/반짝임**: URP Lit Shader Graph에 noise 기반 glitter 효과 추가
- **PBR 금박/금속**: metallic + roughness 조합으로 금박 표현
- **Glitz And Glitter PBR Material**: Asset Store에서 바로 사용 가능한 에셋 존재

#### 1.4 모바일 폴리곤 한계

- 손 모델: 모바일 권장 메시당 **300~1,500 폴리곤**
- bone 수: **30개 이하** 권장 (양손 전체)
- 스킨 웨이트: 최소화 권장

#### 1.5 실제 레퍼런스

- **Animated FPS Hands v3.0** (Unity Asset Store): 모바일 호환 손 애니메이션 에셋, 리깅된 5지 손 모델 포함
- **FluidCards**: Unity 카드 모션 관리 시스템 (카드 물리 애니메이션)
- **Card Plus 3D Card Game Engine** (2024년 12월 업데이트): Unity 3D 카드 게임 전용 엔진
- echo3D 타로 카드 게임 튜토리얼: Unity에서 3D 타로 카드를 AR 포함 구현 (손 애니메이션은 미포함)

---

### 2. Godot 4 — 3D 품질 & 손/손가락 표현

#### 2.1 Skeleton3D + BoneAttachment3D

Godot 4의 3D 스켈레탈 시스템은 다음 노드로 구성된다:

- **Skeleton3D**: bone 계층 전체 관리. `set_bone_pose_rotation()`, `set_bone_global_pose_override()` 등으로 코드에서 개별 bone 직접 제어 가능.
- **BoneAttachment3D**: 특정 bone에 자식 노드를 추가/동기화. 손에 오브젝트 부착 시 사용.
- **AnimationPlayer**: bone 키프레임 애니메이션 재생.
- **AnimationTree + AnimationStateMachine**: 복수 애니메이션 블렌딩/상태 전환.
- **SkeletonModifier3D** (Godot 4.3+): AnimationMixer 외부에서 Skeleton3D를 조작하는 새 기반 클래스. IK, Constraint, SpringBone 내장 예정(4.4).

손가락 bone 개수 제한은 없으며 이론상 5지 × 3절 = 15개 bone 완전 제어 가능. 단, **SkeletonIK3D는 Godot 4.x에서 deprecated** 되어 신규 프로젝트는 SkeletonModifier3D 사용 권장.

#### 2.2 렌더러 옵션

| 렌더러 | 모바일 적합성 | PBR 지원 | 특이사항 |
|-------|-------------|---------|---------|
| Forward+ | 데스크탑 최적화 | 완전 | 모바일 미권장 |
| Mobile | **모바일 기본** | 부분 PBR | Classic forward light list, Vulkan/Metal/D3D12 |
| Compatibility | 저사양 폴백 | 기본 | OpenGL ES 3.0, 제한적 효과 |

**모바일에서는 Mobile 렌더러가 기본 선택**. Vulkan(고사양 모바일), OpenGL ES(저사양) 자동 선택.

#### 2.3 StandardMaterial3D PBR 품질

StandardMaterial3D(BaseMaterial3D 상속)가 지원하는 PBR 속성:
- Metallic / Roughness (ORM 텍스처 지원)
- Clearcoat (카드 광택 표현에 유용) — 단, Mobile 렌더러에서 roughness=0일 때 버그 보고됨 (Issue #95207)
- Emission (빛 방출 효과)
- Subsurface Scattering

**주의**: Godot 4.0~4.1에서 roughness가 Blender/Substance 대비 덜 거칠게 표현되는 버그 보고됨. 최신 버전에서 개선.

#### 2.4 실제 레퍼런스

- FPS hand model for Godot (CGTrader, GLTF, 무료): Godot용 리깅된 손 모델 존재
- Godot 제작 모바일 게임 개발자 경험담: 2D는 원활, 3D 모바일은 UI 프레임워크 한계 지적
- 카드 게임 예시: Dungeons & Degenerate Gamblers, Retromine (itch.io), 주로 2D

---

### 3. Flame + flame_3d — 3D 품질 & 손 표현

#### 3.1 현재 상태

flame_3d는 Flutter GPU(Impeller 기반)를 활용하는 **실험적(experimental)** 패키지다.

**공식 상태 표명:**
> "This package is also experimental; it does not guarantee that it will follow correct semver versioning rules, nor does it assure that its APIs won't break."

지원 플랫폼: Android, iOS, macOS (Windows, Linux, Web **미지원**).

#### 3.2 Skeletal Animation 지원 여부

**공식 문서 및 pub.dev 페이지에서 skeletal animation, bone rigging, 손 애니메이션에 대한 언급 없음.**

현재 flame_3d가 문서화한 기능:
- Flutter GPU를 통한 기본 3D 렌더링
- SpatialMaterial (기본 셰이더)
- 친숙한 Flame API 스타일의 3D 오브젝트 배치

Flame 유지보수팀은 "Flutter의 Impeller와 셰이더 지원이 완전히 안정화되면 true 3D를 추가할 계획"이라고 밝혔으나, 현재(2025~2026)까지 skeletal animation은 미구현 상태.

#### 3.3 손 표현 가능 수준

**원천 불가.** 3D 메시 스키닝 자체가 미구현이므로 손/손가락 bone 제어는 불가능.

---

### 4. three_dart + flutter_gl — 3D 품질 & 손 표현

#### 4.1 패키지 현황

- **최신 버전**: 0.0.16 (3년 이상 업데이트 없음, 사실상 유지보수 중단)
- **기반**: Three.js r138의 Dart 포트, flutter_gl 위에서 동작
- **지원 플랫폼**: Web, iOS, Android, macOS, Windows

#### 4.2 Three.js 원본의 Skeletal Animation 아키텍처

Three.js(원본)는 완전한 skeletal animation 시스템을 보유한다:
- **Skeleton**: bone 계층 정의, 각 bone의 transform 행렬 관리
- **SkinnedMesh**: Skeleton을 참조해 GPU에서 vertex 변형 수행
- **AnimationMixer**: AnimationClip 재생/블렌딩
- **GLTF Loader**: GLB/glTF 파일에서 Skeleton + SkinnedMesh + AnimationClip 모두 로드

#### 4.3 Dart 포트(three_dart)에서의 구현 여부

three_dart는 Three.js r138 기반이나 **README에 "README && Document"가 TODO로 남아 있을 정도로 문서가 미비**. 실제 SkinnedMesh, GLTF skeletal animation이 Dart로 완전 포팅되었는지 GitHub 이슈에서 로딩 실패 보고가 있음(Issue #134).

**대안 패키지**: three_js_advanced_loaders, flutter_3d_controller가 three_dart를 개선/래핑하여 GLTF 애니메이션을 더 안정적으로 지원.

#### 4.4 PBR 지원

Three.js MeshStandardMaterial(PBR metallic/roughness)이 이론상 three_dart에 포팅되어 있으나, 모바일 WebGL 수준의 렌더링 성능에서 실제 품질은 검증 데이터 부족.

#### 4.5 손 표현 가능 수준

이론상 Three.js 원본과 동일한 SkinnedMesh 기반 손 애니메이션이 가능하나:
- 3년 이상 미업데이트로 버그/호환성 위험
- GLTF 로딩 자체가 불안정하다는 커뮤니티 보고
- 프로덕션 사용 레퍼런스 없음

실질적으로 **프로덕션 수준의 손 애니메이션 구현은 위험 높음**.

---

### 5. Babylon.js + WebView — 3D 품질 & 손 표현

#### 5.1 Skeleton / Bone 아키텍처

Babylon.js는 완전한 skeletal animation 시스템을 제공한다:

- **Skeleton**: bone 계층 관리. `Skeleton` 클래스와 `Bone` 클래스로 구성.
- **Bone 조작 메서드**: `rotate()`, `setAxisAngle()`, `setYawPitchRoll()`, `setRotation()`, `setRotationQuaternion()`, `translate()`, `setPosition()`, `scale()` — World 공간 및 Local 공간 모두 지원.
- **BoneLookController**: bone을 특정 타겟을 향해 회전.
- **BoneIKController**: 2-bone IK (현재 2 bone 체인 제한).
- **최대 bone 영향 per vertex**: 4개 (저사양 모바일에서는 3개로 감소).

#### 5.2 GLTF 지원

> "Every version of Babylon.js comes with updated support for the full glTF spec."

GLB/glTF 파일에서 skeletal animation, morph target, PBR 재질, animation group이 모두 로드된다. 손 3D 모델(GLB)을 임포트하면 뼈대와 애니메이션이 자동으로 세팅된다.

Babylon.js 7.0(2024)에서 WebXR hand tracking API 지원 추가 — WebXR 환경에서 실시간 손 추적 가능.

#### 5.3 PBR 렌더링

`PBRMaterial`이 Specular/Glossiness 및 Metallic/Roughness 두 워크플로를 모두 지원한다:
- metallic, roughness, albedo, normal, emission, ambient occlusion
- `useRadianceOverAlpha`: 투명면 반사 조절 (홀로그램 효과 가능)
- WebGL 2.0 Uniform Buffer 지원

카드 광택, 금박, 홀로그램 효과: ShaderMaterial 또는 PBRMaterial 확장으로 커스텀 셰이더 가능.

#### 5.4 Flutter WebView 통합

Flutter에서 Babylon.js를 사용하는 방법:
- **babylonjs_viewer** 패키지: WebView 안에서 Babylon.js Viewer를 실행, JS 코드 주입 가능
- **EvaluateJavascript**: Flutter→JS 통신으로 Babylon.js 씬 제어
- **BabylonNative**: Flutter Desktop 실험적 지원 (모바일 미완성)

#### 5.5 모바일 WebView 성능

커뮤니티 보고:
- 단순 씬에서 모바일 60fps 안정적으로 달성 가능
- 복잡한 skeletal mesh 다수 사용 시 성능 저하
- 최적화 기법: `computeBonesUsingShaders` 토글, baked animation 사용, idle 시 렌더링 중단
- WebView 레이어 + WebGL 렌더링의 이중 오버헤드가 네이티브 엔진 대비 약점

#### 5.6 실제 레퍼런스

- Babylon.js 공식 Viewer v2 (2024): 모바일 최적화된 3D 모델 뷰어
- babylonjs_viewer Flutter 패키지: 기본 GLB 뷰잉 가능, 커스텀 JS로 확장 가능

---

### 6. Flutter 내장 Matrix4 — 한계 분석

#### 6.1 현재 프로젝트 상태

현재 타로 앱은 2D CustomPainter 기반으로 카드 셔플을 구현하고 있으며, Matrix4의 perspective 변환으로 pseudo-3D 카드 뒤집기 효과를 낼 수 있다.

#### 6.2 Matrix4 Pseudo-3D의 표현 한계

| 항목 | 가능 여부 | 설명 |
|------|----------|------|
| 카드 뒤집기 (Y축 회전) | 가능 | `rotateY()` + perspective 설정으로 3D 착시 |
| 원근감 있는 카드 이동 | 가능 | Matrix4 perspective element 조정 |
| 실제 3D 지오메트리 | **불가** | 평면 위젯/이미지 변환만 가능, 실제 3D mesh 없음 |
| 손/손가락 3D 모델 | **원천 불가** | 3D 모델 임포트 및 렌더링 불가 |
| PBR 재질 (금속, 광택) | **불가** | 셰이더 없음 (FragmentShader로 일부 보완 가능) |
| 조명/그림자 | **불가** | 실시간 조명 시스템 없음 |
| 카드 양면 광택/홀로그램 | 부분 가능 | FragmentShader로 gradient shimmer 구현 가능 |
| 뒤집기 왜곡 버그 | 주의 | rotateX()에서 skew 버그 보고됨 (GitHub #18859) |

#### 6.3 FragmentShader로 보완 가능한 범위

Flutter FragmentShader(GLSL)를 활용하면:
- 카드 표면의 shimmer/gradient 효과: 가능
- 홀로그램 레인보우 효과: 가능
- 금속 광택 시뮬레이션 (정적): 가능

그러나 **동적 조명, 그림자, 반사 맵, 환경광**은 구현 불가 또는 수동 수식 코딩 필요.

**손/손가락 표현**: Matrix4로는 원천적으로 불가능. 기껏해야 손 이미지 스프라이트를 2D로 표시하는 수준.

---

### 7. 실제 레퍼런스 수집

#### 타로/카드 앱 관련

| 앱/프로젝트 | 엔진 | 3D 손 | 메모 |
|-----------|------|-------|------|
| echo3D Tarot Unity 튜토리얼 | Unity (URP) | 없음 | 3D 카드 오브젝트, AR 지원, 손 애니메이션 없음 |
| 일본 타로 앱 (AppStore) | OpenGL (native) | 없음 | "OpenGL로 제작, 카드 섞기 터치 지원"이라고 자체 기술 |
| Tarot! App Store 앱 다수 | 불명 (대부분 2D) | 없음 | 셔플 사운드, 2D 카드 플립 |

#### 3D 손 애니메이션 관련

| 레퍼런스 | 엔진 | 특이사항 |
|---------|------|---------|
| FPS Handy Hands (Unity Asset Store) | Unity URP | 리깅된 FPS 손 모델, 모바일 호환 |
| Animated FPS Hands v3.0 | Unity | 30bone 이내 손 애니메이션 |
| FPS hand model for Godot (CGTrader) | Godot | GLTF 포맷, 무료 |
| Godot 4 FPS 튜토리얼 (GDQuest) | Godot 4 | BoneAttachment3D 활용 총기 부착 |

**발견 사항**: 현재 앱스토어의 타로 앱 중 **실제 3D 손 애니메이션을 구현한 앱은 발견되지 않음**. 이는 기술적 도전과 함께 차별화 기회이기도 하다.

---

## Key Findings

1. **손가락 bone 제어 완성도**: Unity Humanoid rig(Mecanim + Muscle 시스템)가 업계 표준. 5지 × 3절 = 15 bone per hand를 Animator Controller + Animation Rigging(TwoBoneIK, Override Transform)으로 완전 제어.

2. **Godot 4도 충분한 skeletal 지원**: Skeleton3D + AnimationTree 조합으로 Unity에 준하는 손가락 애니메이션 구현 가능. SkeletonModifier3D(4.3+)가 더욱 유연한 런타임 제어를 제공.

3. **Babylon.js는 웹 표준 PBR + 완전한 skeletal 지원**: GLTF 완전 지원, 손가락 bone 직접 제어 API 존재. 단, Flutter 통합 시 WebView 오버헤드.

4. **flame_3d는 현재 사용 불가 수준**: skeletal animation 미구현, experimental 상태, 프로덕션 위험 높음.

5. **three_dart는 이론과 현실의 괴리**: Three.js 원본의 SkinnedMesh는 완전하나 Dart 포트는 3년 이상 미업데이트, GLTF 로딩 불안정 보고.

6. **Flutter Matrix4는 손 표현 완전 불가**: 2D 이미지 변환 레이어이며 3D 지오메트리 없음. 손/손가락 3D 표현을 위해서는 다른 엔진 필수.

7. **타로 앱 시장에서 3D 손 애니메이션은 차별화 기회**: 현존하는 타로 앱 중 실제 3D 손 애니메이션을 가진 앱이 없어, 구현 시 강력한 UX 차별화 포인트가 됨.

8. **모바일 폴리곤/bone 예산**: 손 모델은 1,000~1,500 폴리곤, bone 30개 이하가 iOS/Android 권장 상한선.

---

## Recommendations

### 3D 손/손가락 표현이 핵심이라면:

**1순위: Unity (URP)**
- Humanoid rig + Animation Rigging 패키지로 손가락 단위 완전 제어
- URP + Shader Graph로 카드 광택/홀로그램/금박 완전 구현
- FPS Hands 에셋 등 기존 레퍼런스 및 Asset Store 생태계 풍부
- 모바일 최적화 가이드라인(30 bone, ~1500 poly) 명확

**2순위: Godot 4 (Mobile 렌더러)**
- Skeleton3D + SkeletonModifier3D로 충분한 손가락 제어
- 오픈소스, 라이선스 비용 없음
- Mobile 렌더러의 PBR 품질은 Unity URP보다 소폭 낮음 (clearcoat 버그 존재)
- 모바일 3D 프로덕션 레퍼런스가 Unity보다 적음

**3순위: Babylon.js + WebView**
- PBR 완전지원 + skeletal animation + GLTF 완전지원
- WebGL 기반으로 플랫폼 독립적
- WebView 통합 오버헤드, JS-Flutter 통신 비용
- 모바일 60fps는 단순 씬에서는 달성 가능하나 복잡한 손 애니메이션에서 불확실

### 피해야 할 선택:

- **flame_3d**: skeletal animation 미구현, experimental, 프로덕션 부적합
- **three_dart**: 장기 미업데이트, GLTF 불안정, 프로덕션 위험
- **Flutter Matrix4**: 손 표현 원천 불가

---

## References

- [Unity Animation Rigging Manual](https://docs.unity3d.com/Manual//com.unity.animation.rigging.html)
- [Unity TwoBoneIK Constraint](https://docs.unity3d.com/Packages/com.unity.animation.rigging@1.0/manual/constraints/TwoBoneIKConstraint.html)
- [Unity Rig Optimization for Mobile](https://learn.unity.com/tutorial/rig-optimization-for-mobile)
- [Unity VoxHands — Humanoid Finger Controller](https://github.com/hiroki-o/VoxHands)
- [Unity Hand & Finger Tracking iOS+Android](https://assetstore.unity.com/packages/tools/ai-ml-integration/hand-finger-tracking-ios-android-284702)
- [Unity Modeling Characters for Optimal Performance](https://docs.unity3d.com/560/Documentation/Manual/ModelingOptimizedCharacters.html)
- [Unity URP Hologram Shader (Unity 6)](https://dirtycookstudio.itch.io/unity-hologram-shader)
- [Unity Glitter Effect in URP Shader Graph](https://danielilett.com/2021-11-06-tut5-19-glitter/)
- [Godot 4 Skeleton3D Docs](https://docs.godotengine.org/en/stable/classes/class_skeleton3d.html)
- [Godot 4 BoneAttachment3D Docs](https://docs.godotengine.org/en/stable/classes/class_boneattachment3d.html)
- [Godot 4 SkeletonModifier3D Design](https://godotengine.org/article/design-of-the-skeleton-modifier-3d/)
- [Godot 4 StandardMaterial3D PBR](https://docs.godotengine.org/en/stable/tutorials/3d/standard_material_3d.html)
- [Godot 4 Clearcoat Bug (Issue #95207)](https://github.com/godotengine/godot/issues/95207)
- [Godot Mobile Renderer on Arm GPUs](https://developer.arm.com/community/arm-community-blogs/b/mobile-graphics-and-gaming-blog/posts/optimizing-3d-scenes-in-godot-on-arm-gpus)
- [flame_3d pub.dev](https://pub.dev/packages/flame_3d)
- [flame_3d — Droidcon 2024](https://www.droidcon.com/2024/10/17/3d-games-with-flame/)
- [three_dart pub.dev](https://pub.dev/packages/three_dart)
- [Rendering 3D Models with three_dart](https://vibe-studio.ai/insights/rendering-3d-models-with-three-dart)
- [Babylon.js Bones and Skeletons Docs](https://doc.babylonjs.com/features/featuresDeepDive/mesh/bonesSkeletons)
- [Babylon.js 7.0 WebXR and Animation](https://blogs.windows.com/windowsdeveloper/2024/03/04/part-2-babylon-js-7-0-webxr-gltf-and-animation-advancement/)
- [babylonjs_viewer Flutter package](https://pub.dev/packages/babylonjs_viewer)
- [Flutter x BabylonNative](https://forum.babylonjs.com/t/flutter-x-babylonnative/34176)
- [flutter_scene GitHub](https://github.com/bdero/flutter_scene)
- [Flutter GPU Getting Started](https://blog.flutter.dev/getting-started-with-flutter-gpu-f33d497b7c11)
- [Flutter Matrix4 Perspective Transformations](https://blog.codemagic.io/flutter-matrix4-perspective-transformations/)
- [Flutter Matrix4 Perspective Bug (Issue #18859)](https://github.com/flutter/flutter/issues/18859)
- [Echo3D Unity Tarot Tutorial](https://dev.to/echo3d/make-a-tarot-card-game-in-unity-free-tutorial-37fo)
- [FPS hand model for Godot (CGTrader)](https://www.cgtrader.com/free-3d-models/character/other/fps-hand-model-for-godot)

---

## 비교 표

| 엔진 | Skeletal Animation | 손가락 bone 제어 | PBR 렌더링 | GLTF 임포트 | 모바일 품질 | 실제 사례 |
|------|:-----------------:|:---------------:|:---------:|:----------:|:---------:|:--------:|
| **Unity (URP)** | ✅ 완전지원 | ✅ 완전 (15 bone/hand, Muscle + Animation Rigging) | ✅ 완전 (Shader Graph, 홀로그램/글리터/금박) | ✅ 완전 | ✅ 최고 (명확한 가이드라인) | ✅ FPS Hands, Card Game Engine 등 다수 |
| **Godot 4** | ✅ 완전지원 | ✅ 완전 (Skeleton3D, SkeletonModifier3D) | ⚠️ 부분 (Mobile 렌더러 clearcoat 버그, roughness 이슈) | ✅ 완전 | ⚠️ 양호 (Unity 대비 소폭 낮음) | ⚠️ 소수 (FPS hand 에셋, 2D 중심) |
| **Babylon.js + WebView** | ✅ 완전지원 | ✅ 완전 (Bone API 직접 제어, GLTF auto-rig) | ✅ 완전 (PBRMaterial, 홀로그램 가능) | ✅ 완전 | ⚠️ 양호 (WebView 오버헤드 있음) | ⚠️ babylonjs_viewer 패키지, 모바일 3D 앱 소수 |
| **three_dart + flutter_gl** | ⚠️ 이론상 지원 | ⚠️ 이론상 가능 (SkinnedMesh Dart 포트, 불안정) | ⚠️ 이론상 지원 (MeshStandardMaterial) | ⚠️ 불안정 (GLTF 로딩 버그 보고) | ❌ 미검증 (3년 미업데이트) | ❌ 없음 |
| **flame_3d** | ❌ 미구현 | ❌ 불가 | ❌ 기본 SpatialMaterial만 | ❌ 불명 | ❌ experimental | ❌ 없음 |
| **Flutter Matrix4** | ❌ 없음 | ❌ 원천 불가 (2D 변환만) | ❌ 없음 (FragmentShader로 shimmer만) | ❌ 불가 | ❌ pseudo-3D 한계 | ⚠️ 현재 프로젝트 (카드 플립만) |

---

## Communication Log
| # | 방향 | 상대 | 내용 요약 | 시점 |
|---|------|------|----------|------|
| 1 | 조사 | Web | Unity mobile hand animation, finger rigging 검색 | 2026-03-16 |
| 2 | 조사 | Web | Godot 4 skeletal 3D, BoneAttachment3D 검색 | 2026-03-16 |
| 3 | 조사 | Web | flame_3d pub.dev, 실험적 상태 확인 | 2026-03-16 |
| 4 | 조사 | Web | three_dart skeletal animation, GLTF 지원 확인 | 2026-03-16 |
| 5 | 조사 | Web | Babylon.js Bones/Skeletons 공식 문서 분석 | 2026-03-16 |
| 6 | 조사 | Web | Flutter Matrix4 한계, pseudo-3D 버그 조사 | 2026-03-16 |
| 7 | 조사 | Web | 타로 앱/카드 게임 3D 손 애니메이션 레퍼런스 수집 | 2026-03-16 |

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
