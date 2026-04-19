---
id: "024"
title: "Flutter 통합 & 모바일 부담 분석"
category: agent
status: archived
created: 2026-03-16
summary: >
  Godot 4, Unity, Babylon.js, Flame의 Flutter 통합 방식별 APK 크기,
  GPU/CPU/배터리 오버헤드, 안정성 비교.
keywords: [agent-report, Flutter integration, APK size, GPU, CPU, battery, PlatformView, WebView]
modules: []
---

# Flutter 통합 & 모바일 부담 분석

## Progress
### Completed
- [x] flutter_unity_widget / flutter_embed_unity 통합 방식 및 APK 오버헤드
- [x] Godot 4 + Flutter 브리지 방식 조사 (flutter_godot, FlutDot)
- [x] Babylon.js + WebView 방식 오버헤드
- [x] Flame Flutter 네이티브 오버헤드 (baseline)
- [x] PlatformView vs WebView 성능 비교
- [x] 배터리/GPU/CPU 데이터 수집
- [x] 통합 안정성 (이슈 트래커, 업데이트 빈도)
- [x] 비교 표 작성
### Remaining
- (없음)
### Current Status
조사 완료. 보고서 작성 완료.

---

## Summary

Flutter 3.29+ 환경에서 3D 엔진을 모바일 앱에 통합할 때 가장 큰 리스크는 **APK 크기 폭증**과 **통합 안정성 결핍**이다. Unity(flutter_unity_widget/flutter_embed_unity)는 APK를 최소 60~200+ MB 수준으로 팽창시키며, Godot 4는 **Android 전용**이라는 치명적 제약이 있다. Babylon.js/WebView는 iOS에서 작동하지만 WebGL 렌더링 지연과 배터리 비효율이 크다. **Flame은 Flutter 네이티브 통합으로 APK 증가가 최소(+2~5 MB)이며** 60 FPS를 안정적으로 달성하지만 순수 3D 표현에 한계가 있다. 타로 셔플 앱의 요구사항(iOS+Android 동시, APK 합리적 크기, 안정적 운영)을 고려하면 **Flame이 현실적 최선**이며, Godot 4는 Android 전용 프로토타입에만 제한적으로 고려 가능하다.

---

## Details

### 1. Unity + flutter_unity_widget / flutter_embed_unity

#### 통합 방식
Unity는 원래 전체화면 단독 실행을 전제로 설계되어 있다. `flutter_unity_widget`(GitHub: juicycleff)과 `flutter_embed_unity`(learntoflutter.com)는 모두 "Unity as a Library" 기능을 활용해 Unity를 Flutter PlatformView 위젯으로 삽입한다.

- **Android**: Unity 프로젝트를 `unityLibrary` 모듈로 내보낸 뒤 Flutter의 `android/` Gradle 멀티모듈에 연결. GodotFragment 아닌 UnityPlayer를 Surface에 붙임.
- **iOS**: Unity 프로젝트를 Xcode 워크스페이스로 내보낸 뒤 `UnityFramework.framework`를 Flutter 앱에 임베드.
- **통신**: Flutter MethodChannel ↔ Unity SendMessage / C# callback.
- Hot Reload: 미지원. Flutter Hot Restart 시 Unity 뷰 사라짐.

#### APK/IPA 크기
| 시나리오 | 크기 |
|---------|------|
| 빈 Unity 프로젝트 단독 APK | ~20 MB (설치 후 ~62 MB) |
| Unity as Library (ARM64 전용 AAR) | ~17 MB, 최종 APK ~60 MB |
| Flutter + Unity 실제 배포 사례 | AAB 200 MB 초과 보고 다수 |
| 최소화 최적화 후 | ~30~50 MB 수준 가능 |

Google Play AAB 한도(150~200 MB)를 초과할 위험이 높다.

#### GPU 오버헤드
Unity와 Flutter는 **별도 렌더링 파이프라인**을 운영한다. Unity는 OpenGL ES 3(Android)/Metal(iOS)로 자체 렌더링하며, Flutter(Impeller)도 Vulkan/Metal을 별도 사용한다. 두 엔진이 GPU 컨텍스트를 동시에 점유하므로 **GPU 메모리 이중 점유** 구조다. PlatformView Hybrid Composition 하에서 Android 10 미만 기기는 프레임 데이터를 GPU→CPU→GPU로 두 번 복사하며, Android 14에서 Impeller + PlatformView 버그가 보고된 바 있다.

#### 배터리 소모
Unity 공식 권장 기준: 시간당 25% 배터리 소모 초과 시 앱 스토어 리뷰 악화. Unity가 별도 렌더 루프를 상시 구동하므로 Flutter 단독 대비 열 발생 및 배터리 소모가 유의미하게 증가.

#### 안정성 (2024~2025 실제 이슈)
- Flutter 3.22+ + Android API 32 이하: ARFoundation 사용 시 NoClassDefFoundError 크래시
- Unity 2023/Unity 6: Android 클래스 변경으로 플러그인 컴파일 오류 (미지원)
- iOS Xcode 14+ 업그레이드 후 메모리 초기화 오류 크래시
- Android 14 + Impeller + PlatformView 버그
- flutter_unity_widget 마지막 pub.dev 배포: **2024년 1월** (pub points 140, 주간 다운로드 ~1,000)
- flutter_embed_unity: **2025년 9월** 배포, 더 활발히 유지보수 중
- **핵심 인용**: "Unity was only intended to be used fullscreen, making embedding quite delicate, with the plugin calling undocumented functions and implementing workarounds that limit version compatibility."

---

### 2. Godot 4 + Flutter 통합

#### 통합 방식 현황

Godot 4의 Flutter 통합은 **공식 지원이 없으며**, 커뮤니티 플러그인 두 개가 존재한다:

**flutter_godot (pub.dev)**
- 버전: 0.0.3, 2025년 8월 24일 배포
- Godot 4.4.1 + Flutter 3.35+ 필요
- **Android 전용** (Godot 공식이 Android 라이브러리만 제공하기 때문)
- 4 likes, 57 주간 다운로드 — 극히 초기 단계
- Integrated Mode(assets 폴더 직접 배치) vs Standalone Mode(.pck 패키지 참조)
- Hot Restart 시 Godot 뷰 사라지는 알려진 버그

**FlutDot (GitHub: Celpear)**
- 현재는 Godot Web Export를 WebView에 임베드하는 방식으로만 동작
- Native iOS/Android 라이브러리 임베드는 **계획 중** (미구현)

#### iOS 상황
- Godot iOS 임베드는 SwiftUI/UIKit 앱에 SwiftGodotKit으로 삽입 가능 (2025년 5월 기준)
- **Flutter 앱에서 iOS Godot 임베드는 현재 지원 경로 없음**
- iOS 시뮬레이터 미지원 (실기기 필수, Metal 필요)

#### APK/IPA 크기
| 항목 | 크기 |
|------|------|
| Godot iOS 바이너리 추가량 | ~30 MB (Emerge Tools 실측, christianselig.com) |
| Godot Android .so (uncompressed) | ~8.5~37 MB (버전·아키텍처에 따라 상이) |
| Godot 빈 프로젝트 APK (설치 후) | ~20 MB APK → ~82 MB 설치 크기 |
| ARM64 단일 아키텍처 최적화 시 | 상당히 감소 가능 |

#### 핵심 통합 문제: SurfaceView 충돌
Godot Android는 내부적으로 SurfaceView를 사용해 별도 윈도우 레이어에 렌더링한다. Flutter 위젯 트리 위에 SurfaceView가 항상 최상위 레이어를 점유하므로, **Godot 뷰 위에 Flutter 위젯을 겹칠 수 없다** (Stack 내 오버레이 불가). TextureView 방식으로 전환하면 해결 가능하지만 Godot 기본 설정이 아니다.

---

### 3. Babylon.js + WebView (flutter_inappwebview / webview_flutter)

#### 통합 방식
- `webview_flutter`: 시스템 WebView(Android의 Chrome WebView, iOS의 WKWebView) 사용. 별도 런타임 번들 불필요.
- `flutter_inappwebview`: 동일한 시스템 WebView를 더 많은 API로 제어. APK 크기 증가 최소.
- Babylon.js 번들(~2~5 MB gzip)을 로컬 assets에 포함하거나 CDN에서 로드.
- 통신: Flutter ↔ JS는 `evaluateJavascript()` / `JavascriptChannel`로 구현.

#### WebGL 렌더링 경로
- WebView 내 WebGL은 시스템 GPU 드라이버를 **직접 사용** (OpenGL ES → Metal/Vulkan 변환).
- 단, WebView가 PlatformView로 구현되므로 Hybrid Composition 오버헤드가 적용됨.
- Android 일부 기기에서 composite layer 지연으로 WebGL이 Chrome보다 현저히 느림.
- iOS(WKWebView)에서는 상대적으로 안정적이나 WebGL 2.0 지원이 불완전했음 (Flutter 2.7에서 해결).

#### 성능 데이터
| 항목 | 측정값 / 관찰 |
|------|-------------|
| WebGL vs 네이티브 draw call throughput | 네이티브 대비 ~1/10 수준 (데스크탑 기준, 모바일은 더 열악) |
| WebView 초기화 시간 | Chromium V8 + Blink 초기화 수백 ms |
| JS ↔ Flutter 통신 지연 | 명시적 측정치 없음; IPC 경유로 수 ms~수십 ms 추정 |
| Android 애니메이션 성능 | 느림 다수 보고 (iOS는 정상) |
| Samsung Galaxy 일부 기기 | Flutter 3.27+ Impeller + WebView 렌더링 오류 |

#### APK 크기
webview_flutter/flutter_inappwebview는 시스템 WebView를 사용하므로 APK 증가는 **플러그인 코드 수십 KB 수준**. Babylon.js 번들을 assets에 포함 시 ~2~5 MB 추가.

#### 배터리 소모
WebGL 3D는 GPU 연속 구동이 필수. 30 FPS 타겟 설정으로 배터리 소모를 절반 수준으로 줄일 수 있으나, 네이티브 렌더링 대비 항상 비효율적 (추가 WebView 프로세스, JS 엔진 상시 구동).

---

### 4. Flame (Flutter 네이티브 — baseline)

#### 통합 방식
Flame은 Flutter 패키지로, 외부 엔진 임베딩 없이 Flutter 렌더링 파이프라인(Canvas API → Impeller/Skia → GPU) 내에서 동작한다. PlatformView나 WebView를 전혀 사용하지 않음.

- 버전: 1.36.0 (2026년 3월 6일 배포), 2,290 likes, 88,400 주간 다운로드
- 렌더링: Flutter Canvas → Skia/Impeller → Metal(iOS)/Vulkan(Android) GPU 직접 가속
- Impeller 호환: Flutter Impeller(3.10+ preview, 3.27 기본값)와 완전 호환 (동일 렌더링 스택)
- 3D: 실험적 `flame_3d` 패키지 존재 (Impeller + Flutter GPU 기반), 프로덕션 미성숙

#### APK 크기
| 항목 | 크기 |
|------|------|
| Flame 패키지 자체 | 소수 MB 미만 (Dart 코드만, 네이티브 라이브러리 없음) |
| 기존 Flutter 앱 대비 APK 증가 | +2~5 MB 수준 |
| Flame 게임 assets (스프라이트 등) | 추가되는 이미지 크기에 비례 |

#### 성능 벤치마크 (filiph.net, 2024년 8월 기준)
| 엔진 | iOS 최대 60FPS 유지 엔티티 수 | iOS CPU (Mc/5s) | 메모리 (Web, 1000 entities) |
|------|----------------------------|-----------------|-----------------------------|
| Flutter vanilla | ~200 | ~400-500 | ~180-200 MB |
| Flame | ~2,500 | ~600-700 | ~170-190 MB |
| Unity | ~5,000 | ~700-800 | ~130-150 MB |
| Godot | 측정 오류 (이상값) | ~750-850 | ~120-140 MB |

- Flame은 Flutter보다 엔티티 처리 10배 이상 효율적
- Unity/Godot보다 CPU는 적게 사용하지만 최대 엔티티 수는 절반 수준
- 타로 셔플 앱 규모(카드 78장, 3D 손 애니메이션 수준)에서는 Flame이 충분함

#### 배터리 소모
외부 런타임 없이 Flutter 단일 렌더 루프 내에서 동작하므로 배터리 효율 최고. 게임 루프가 상시 실행되므로 idle 상태에서 `pauseEngine()`으로 수동 절전 권장.

---

### 5. PlatformView vs WebView 성능 비교

#### PlatformView 구현 방식 (Android)
- **Hybrid Composition**: Flutter UI를 플랫폼 View의 onDraw에서 합성. GPU→CPU→GPU 메모리 복사 발생 (Android 10 미만에서 특히 심각). 2025년 4월 기준 일부 Android 기기에서 심각한 성능 저하 미해결.
- **Virtual Display**: 별도 오프스크린 Surface에 렌더링 후 Flutter texture로 변환. 터치 이벤트 정확도 저하.

#### Impeller와 PlatformView (2024~2025)
- Flutter 3.27 (2024년 12월): Impeller가 Android 기본값으로 승격
- Android 14의 Impeller + PlatformView API 버그가 발견됨 → 패치되었으나 배포된 Android 14 기기 다수가 구버전 유지
- Flutter 3.29에서 추가 개선이 있으나 Hybrid Composition 근본 성능 문제는 완전 해결되지 않음

#### WebView
- webview_flutter도 PlatformView(Hybrid Composition)로 구현되므로 동일 오버헤드 적용
- WebGL 렌더링 시 추가로 WebView 프로세스 + JS 엔진 오버헤드

---

### 6. 배터리 소모 종합

정량적 비교 데이터는 공개 레퍼런스가 제한적이나 구조적 분석:

| 방식 | 배터리 영향 요인 | 상대적 소모 |
|------|----------------|-----------|
| Flame (Flutter 네이티브) | 단일 렌더 루프, GPU 직접 가속 | 낮음 (baseline) |
| Babylon.js/WebView | WebGL + WebView 프로세스 + JS 엔진 상시 가동 | 중간~높음 |
| Unity (flutter_unity_widget) | Unity + Flutter 이중 렌더 루프 | 높음 |
| Godot/flutter_godot | Godot SurfaceView + Flutter 이중 렌더 | 높음 (Unity와 유사) |

Unity 공식 권장 기준: 시간당 배터리 25% 초과 소모 금지, 순간 전력 2W 초과 금지.

---

## Key Findings

1. **Unity Flutter 통합은 APK 크기가 파괴적**: 최소 구성에서도 APK 60 MB, 실제 배포 사례에서 AAB 200 MB 초과. Google Play 한도 위협.

2. **Godot 4 + Flutter는 iOS를 지원하지 않는다**: flutter_godot는 Android 전용. FlutDot의 네이티브 iOS 지원은 미구현(계획 중). iOS + Android 동시 지원이 필요한 이 프로젝트에는 적합하지 않음.

3. **Godot Android 통합의 SurfaceView 문제**: GodotFragment가 SurfaceView를 사용하므로 Flutter 위젯이 Godot 뷰 위에 오버레이 불가. 기본 UI 패턴이 깨짐.

4. **Babylon.js/WebView는 Android 성능이 불안정**: 여러 기기에서 WebGL 렌더링 지연, composite layer 문제, Samsung 기기에서 Impeller + WebView 충돌(Flutter 3.27+). iOS는 상대적으로 양호.

5. **Flame은 APK 증가 최소이며 안정성 최고**: +2~5 MB, Flutter 렌더 파이프라인 내 완전 통합, Impeller와 네이티브 호환, 2,290 likes + 88,400 주간 다운로드의 성숙한 생태계.

6. **PlatformView Hybrid Composition은 2025년에도 미해결 성능 문제**: Unity/Godot 임베딩이 의존하는 PlatformView 레이어가 일부 Android 기기에서 심각한 성능 저하 유발.

7. **Flame의 3D 한계**: 2D 게임 엔진이 기반이며 `flame_3d`는 실험적. 실사 수준 3D 손 표현은 불가능. 타로 셔플 앱에서 스타일라이즈드/아트적 3D 표현을 택하면 Flame으로 구현 가능.

---

## Recommendations

### 타로 셔플 앱 기준 권장

**1순위: Flame (Flutter 네이티브)**
- iOS + Android 동시 지원 완전
- APK 크기 영향 최소 (+2~5 MB)
- 안정성 최고 (성숙한 생태계, 활발한 유지보수)
- Flutter Impeller와 완전 호환, 60 FPS 안정 달성
- 제약: 포토리얼리스틱 3D 불가 → 스타일라이즈드 카드/손 표현으로 설계 방향 전환 필요

**2순위: Babylon.js/WebView (iOS 우선 프로토타입)**
- iOS에서 상대적으로 안정적
- APK 크기 증가 최소 (시스템 WebView 활용)
- 실제 3D 표현 가능
- 제약: Android 성능/안정성 불확실, JS 브리지 지연, 배터리 비효율

**비권장: Unity (flutter_unity_widget/flutter_embed_unity)**
- APK 크기 폭증 (60~200 MB) — 타로 앱 규모에 과도
- 안정성 이슈 다수, 유지보수 부담 큼
- Unity 6000 미지원

**비권장: Godot 4 (flutter_godot)**
- iOS 미지원 (프로젝트 요건 불충족)
- SurfaceView 오버레이 문제
- 극초기 플러그인 (4 likes, 57 다운로드)

---

## Comparison Table

| 엔진 | 통합 방식 | APK 크기 증가 | GPU 오버헤드 | 배터리 영향 | Hot Reload | 안정성 | iOS 지원 | 추천 |
|------|---------|------------|------------|-----------|-----------|--------|---------|------|
| **Flame** | Flutter Canvas (네이티브) | +2~5 MB | 단일 파이프라인 (낮음) | 낮음 | 지원 | 매우 높음 | 완전 | **1순위** |
| **Babylon.js/WebView** | WebView PlatformView | +수십 KB (+Babylon 번들 ~2~5 MB) | WebGL+WebView 이중 (중간) | 중간~높음 | 미지원 | 중간 (Android 불안정) | 부분 | 2순위 |
| **Unity (flutter_embed_unity)** | PlatformView (UnityPlayer) | +60~200 MB | 이중 렌더 파이프라인 (높음) | 높음 | 미지원 | 낮음 (다수 크래시 이슈) | 완전 | 비권장 |
| **Godot 4 (flutter_godot)** | Android Library + SurfaceView | +20~40 MB (Android) | 이중 렌더 파이프라인 (높음) | 높음 | 미지원 | 매우 낮음 (초기 플러그인) | **미지원** | 비권장 |

---

## References

- filiph.net — Benchmarking Flutter, Flame, Unity and Godot (Aug 2024): https://filiph.net/text/benchmarking-flutter-flame-unity-godot.html
- pub.dev — flutter_embed_unity (v1.4.0, Sep 2025): https://pub.dev/packages/flutter_embed_unity
- pub.dev — flutter_unity_widget (v2022.3, Jan 2024): https://pub.dev/packages/flutter_unity_widget
- pub.dev — flutter_godot (v0.0.3, Aug 2025): https://pub.dev/packages/flutter_godot
- pub.dev — flame (v1.36.0, Mar 2026): https://pub.dev/packages/flame
- GitHub — flutter-unity-view-widget issues: https://github.com/juicycleff/flutter-unity-view-widget/issues
- GitHub — Celpear/FlutDot: https://github.com/Celpear/FlutDot
- christianselig.com — Godot iOS Interop (~30 MB binary, May 2025): https://christianselig.com/2025/05/godot-ios-interop/
- Godot Docs — Android Library: https://docs.godotengine.org/en/4.4/tutorials/platform/android/android_library.html
- Flutter GitHub — WebGL is slow inside WebView: https://github.com/flutter/flutter/issues/29892
- Flutter GitHub — PlatformView Hybrid Composition slow on Android: https://github.com/flutter/flutter/issues/167547
- Flutter GitHub — Impeller + PlatformView Android 14 bug context: (Flutter 3.27 release notes)
- Medium — The Evolution of Flutter PlatformView: https://medium.com/@GSYTech/the-evolution-of-flutter-platformview-8486e9cd86d3
- Unity Discussions — APK size with Unity as Library (60 MB empty): https://discussions.unity.com/t/size-problem-when-using-unity-as-library-in-a-native-android-app/863690
- flutter_inappwebview GitHub — GPUAUX error with WebGL: https://github.com/pichillilorenzo/flutter_inappwebview/issues/2124

## Communication Log
| # | 방향 | 상대 | 내용 요약 | 시점 |
|---|------|------|----------|------|
| 1 | 수신 | orchestrator | Flutter 통합 & 모바일 부담 분석 위임 | 2026-03-16 |
| 2 | 내부 | WebSearch×12 + WebFetch×6 | 엔진별 통합 방식·크기·성능·안정성 조사 | 2026-03-16 |

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
