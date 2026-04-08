---
id: "020"
title: "3D 엔진 라이선스 & 비용 분석"
category: agent
status: archived
created: 2026-03-16
summary: >
  Unity, Godot 4, Flame, three_dart, Babylon.js, Flutter 내장의 상업 라이선스 조건 비교.
  Flame(MIT)과 Flutter 내장(BSD-3-Clause)이 완전 무료 무제한 상업 사용 가능.
  Unity Personal은 $200K 수익 한도 조건부 무료.
  three_dart/flutter_gl은 2022년 이후 유지보수 중단으로 실질적 사용 불가.
keywords: [agent-report, license, cost, Unity, Godot, Flame, three_dart, BabylonJS]
modules: []
---

# 3D 엔진 라이선스 & 비용 분석

## Progress
### Completed
- [x] Unity 라이선스 조사
- [x] Godot 4 라이선스 조사
- [x] Flame 라이선스 조사
- [x] three_dart + flutter_gl 라이선스 조사
- [x] Babylon.js 라이선스 조사
- [x] flutter_unity_widget 라이선스 조사
- [x] 비교 표 작성
### Remaining
- (없음)
### Current Status
조사 완료. 보고서 작성 완료.

---

## Summary

Flutter 타로 앱의 상업적 무료 출시 기준으로 평가한 결과:

- **완전 무료 무제한**: Flame(MIT), Babylon.js(Apache 2.0), Godot 4(MIT), Flutter 내장(BSD-3-Clause)
- **조건부 무료**: Unity Personal — 연 수익/펀딩 $200K 미만 시 무료, 초과 시 유료 전환 필수
- **실질적 사용 불가**: three_dart + flutter_gl — 2022년 10~11월 이후 유지보수 중단

타로 앱의 규모(초기 수익 $200K 미만)를 감안하면 Unity도 단기적으로는 허용 범위 내이나, **정책 변경 리스크**와 **Flutter 통합 복잡도**를 고려할 때 추천하지 않는다.

---

## Details

### 1. Unity (Personal 플랜)

#### 라이선스 구조 (2025–2026 현재)
- Unity는 오픈소스가 아닌 **독점 소프트웨어(Proprietary)**. 플랜별 사용 조건이 계약으로 규정됨.
- **Personal 플랜**: 완전 무료, 단 아래 수익 조건 충족 시에만 사용 가능.

#### 수익 제한 (2025 기준)
- **개인/취미 개발자**: Unity 사용과 관련된 수익이 연 $200,000 USD 미만
- **소규모 사업체 (서비스 제공 없음)**: 총 매출 + 투자금 합산 연 $200,000 USD 미만
- **소규모 사업체 (서비스 제공 있음)**: 클라이언트의 매출 + 투자금 합산 연 $200,000 USD 미만
- $200K 초과 시 **Unity Pro ($2,310/년)** 또는 **Unity Enterprise** 구독 필수

> Unity 6 출시(2024년 10월 17일)와 함께 수익 한도가 기존 $100K → $200K로 상향 조정됨.

#### 2023 런타임 요금 사태 해결
- 2023년 9월 Unity가 설치 횟수당 요금을 부과하는 "Runtime Fee" 발표 → 개발자 커뮤니티 강력 반발
- 2024년 9월 Unity가 Runtime Fee 전면 철회 선언: "after deep consultation with our community, customers, and partners, we've made the decision to cancel the Runtime Fee, effective immediately."
- 현재는 **구독 요금만 적용**되며, 런타임 요금은 완전히 폐기됨
- 단, Pro 요금 8% 인상(2025년 1월), Enterprise 요금 25% 인상으로 보상
- **신뢰도 이슈**: 이 사태로 인해 Unity의 정책 변경 가능성에 대한 개발자 불신이 남아 있음

#### 스플래시 스크린
- **Unity 6 이후**: "Made with Unity" 스플래시 스크린이 **선택 사항(Optional)**으로 변경됨
- Unity 6 이전 버전: Personal 플랜 사용 시 Unity 로고 스플래시 스크린 의무 표시

#### iOS/Android 퍼블리싱
- Personal 플랜으로 iOS App Store, Google Play Store **상업 출시 허용**
- 콘솔 플랫폼(Nintendo Switch, PlayStation, Xbox)만 Pro 필수 — 모바일은 제한 없음
- 단, Apple Developer Program 연회비($99), Google Play 일회성 등록비($25)는 별도

#### 플러터 통합 방식
- `flutter_unity_widget` (BSD-3-Clause, 최신 버전 2022.2.1 — 2024년 1월 8일 업데이트)
- Unity를 별도 빌드하여 Flutter 앱에 임베드하는 방식 → 빌드 파이프라인 복잡도 높음
- **결론**: 플러그인 자체 라이선스는 무료이나 Unity 엔진 라이선스 조건 별도 준수 필요

---

### 2. Godot 4.x

#### 라이선스
- **MIT License** — 완전 오픈소스
- 영구 무료, 로열티 없음, 수익 제한 없음, 플랫폼 제한 없음
- 소스코드 수정·배포·상업 사용 모두 허용

#### 귀속 요건 (Attribution)
- Godot 엔진을 배포할 경우 저작권 고지 및 라이선스 문구 포함 필요
- 게임 자체의 라이선스는 개발자가 완전히 소유 — Godot 라이선스 적용 없음
- 실무: 게임 크레딧 또는 문서에 "Powered by Godot Engine (MIT)" 링크 포함으로 충분

#### iOS/Android 지원
- Godot 4.3+: Android 공식 지원
- iOS: SwiftUI/UIKit 앱에 Godot 게임 임베드 가능 (2025년 5월 공개된 네이티브 방식)
- Flutter 통합: 직접 위젯 임베드 방식은 미성숙 — 별도 브리지 구현 필요

#### 상업 앱 출시 조건
- **완전 무료 무제한** — 조건 없음

---

### 3. Flame (Flutter 게임 엔진)

#### 라이선스
- **MIT License** — 완전 오픈소스
- 상업 사용, 수정, 재배포 모두 허용
- 로열티 없음, 수익 제한 없음, 귀속 요건 최소 (라이선스 고지만)

#### 패키지 현황
- pub.dev 패키지명: `flame`
- 최신 버전: **1.36.0** (2026년 3월 6일 업데이트 — 현재 기준 최신, 활발히 유지보수됨)
- Flutter 네이티브 — 별도 런타임이나 브리지 불필요
- 주요 기능: 게임 루프, 컴포넌트 시스템(FCS), 스프라이트 애니메이션, 충돌 감지, 입력 처리

#### iOS/Android 지원
- Flutter 기반이므로 iOS/Android 완전 지원
- Flutter가 지원하는 모든 플랫폼에서 동작

#### 3D 지원 현황
- Flame은 주로 **2D 엔진**
- `flame_3d`: 실험적 3D 지원 패키지, Impeller 기반 — 아직 프로덕션 사용 권장 안됨
- 타로 카드 3D 효과: Flame의 2D 레이어 + Flutter 내장 Matrix4 조합으로 구현 가능

#### 상업 앱 출시 조건
- **완전 무료 무제한** — 조건 없음

---

### 4. three_dart + flutter_gl

#### 라이선스
- `three_dart`: **MIT License**
- `flutter_gl`: **MIT License**
- 라이선스 자체는 무제한 상업 사용 허용

#### 유지보수 상태 (치명적 문제)
| 패키지 | 최신 버전 | 마지막 업데이트 | 상태 |
|--------|----------|---------------|------|
| `three_dart` | 0.0.16 | 2022년 11월 19일 | 사실상 중단 |
| `flutter_gl` | 0.0.21 | 2022년 10월 4일 | 사실상 중단 |

- 두 패키지 모두 **3년 이상 업데이트 없음** (2022년 이후)
- 미인증(unverified) 퍼블리셔, 불완전한 패키지 분석 경고
- `flutter_gl`: "Linux TODO" 등 미완성 기능 존재
- Flutter 및 Dart SDK 버전 업데이트와의 호환성 불명확

#### 대안
- `flutter_scene` (Impeller 기반 3D, Flutter 네이티브) — 초기 프리뷰 단계
- Thermion (Google Filament 바인딩) — FFI 기반, 더 성숙된 3D

#### 상업 앱 출시 조건
- 라이선스는 무료이나 **실질적 사용 불가** (유지보수 중단으로 프로덕션 리스크 과대)

---

### 5. Babylon.js (WebView 통합)

#### 라이선스
- **Apache License 2.0**
- 상업 사용, 수정, 배포 허용
- 로열티 없음, 수익 제한 없음
- 요건: 원본 라이선스 및 저작권 고지 포함, 변경 사항 명시

#### Apache 2.0 vs MIT 차이
- MIT보다 명시적으로 **특허 허여(patent grant)** 포함 → 더 강력한 법적 보호
- 독점 소프트웨어에 포함 가능, 소스 공개 의무 없음

#### Flutter WebView 통합
- Flutter에서 Babylon.js 사용 방법: `webview_flutter` + `inappwebview` + Babylon.js HTML 번들
- `babylonjs_viewer` 패키지: MIT 라이선스, `webview_flutter` 의존
- 통합 라이선스 이슈: WebView 자체 및 관련 패키지 모두 허용적 라이선스 — 추가 제한 없음
- 단, WebView 방식은 네이티브 성능 대비 렌더링 오버헤드 발생 (라이선스 문제는 아님)

#### iOS/Android 지원
- Babylon.js: JavaScript + WebGL 기반 — WebGL 지원 WebView에서 동작
- iOS WKWebView, Android WebView 모두 WebGL 지원 (단, 구형 디바이스 제외)

#### 상업 앱 출시 조건
- **완전 무료 무제한** — 조건 없음

---

### 6. Flutter 내장 (Matrix4 + FragmentShader + sensors_plus)

#### 라이선스
- Flutter SDK: **BSD-3-Clause License** (Google)
- `sensors_plus`: **BSD-3-Clause** (Flutter Community)
- Dart SDK: **BSD-3-Clause**
- 모두 상업 사용 무제한 허용

#### 이미 프로젝트에 포함
- 현재 타로 셔플 앱 MVP에 이미 사용 중
- 추가 의존성 없음, 별도 런타임 없음

#### 상업 앱 출시 조건
- **완전 무료 무제한** — 조건 없음

---

## Key Findings

### 비교 표

| 엔진 | 라이선스 | 상업 무료 조건 | 수익 제한 | 로열티 | iOS/Android | 2025 현재 추천? |
|------|---------|--------------|---------|--------|-------------|----------------|
| **Flutter 내장** | BSD-3-Clause | 무조건 무료 | 없음 | 없음 | ✅ 완전 지원 | ✅ 완전 무료 |
| **Flame** | MIT | 무조건 무료 | 없음 | 없음 | ✅ 완전 지원 | ✅ 완전 무료 |
| **Godot 4** | MIT | 무조건 무료 | 없음 | 없음 | ✅ 완전 지원 | ✅ 완전 무료 (Flutter 통합 복잡) |
| **Babylon.js** | Apache 2.0 | 무조건 무료 | 없음 | 없음 | ✅ WebView 필요 | ✅ 완전 무료 |
| **Unity Personal** | 독점(Proprietary) | 수익 $200K 미만 | **$200K/년** | 없음 | ✅ 가능 | ⚠️ 조건부 (정책 변경 리스크) |
| **Unity Pro** | 독점(Proprietary) | 유료 | 없음 | 없음 | ✅ 가능 | ⚠️ $2,310/년 |
| **three_dart** | MIT | 무조건 무료 | 없음 | 없음 | ❓ 불명확 | ❌ 유지보수 중단 |
| **flutter_gl** | MIT | 무조건 무료 | 없음 | 없음 | ❓ 불명확 | ❌ 유지보수 중단 |

### 엔진별 요약 판정

| 엔진 | 판정 |
|------|------|
| Flutter 내장 | ✅ 완전 무료 상업 사용 가능 |
| Flame | ✅ 완전 무료 상업 사용 가능 |
| Godot 4 | ✅ 완전 무료 상업 사용 가능 (Flutter 통합 미성숙) |
| Babylon.js | ✅ 완전 무료 상업 사용 가능 |
| Unity Personal | ⚠️ 조건부 무료 ($200K 수익 한도, 정책 변경 리스크) |
| three_dart + flutter_gl | ❌ 라이선스 무료이나 유지보수 중단으로 실질적 사용 불가 |

---

## Recommendations

### 우선순위 1: Flutter 내장 (Matrix4 + FragmentShader)
- 이미 프로젝트에 포함됨
- BSD-3-Clause, 수익/플랫폼 제한 없음
- 별도 의존성 없어 빌드 복잡도 최소
- 타로 카드 3D 플립 등 기본 효과 구현 가능

### 우선순위 2: Flame (MIT)
- Flutter 네이티브, 활발히 유지보수됨 (2026년 3월 최신 업데이트)
- MIT 라이선스, 완전 무료 무제한 상업 사용
- 게임 루프, 스프라이트 애니메이션에 최적화

### 우선순위 3: Babylon.js (Apache 2.0) — 고급 3D 필요 시
- WebView 방식이지만 가장 강력한 3D 렌더링
- Apache 2.0, 완전 무료 무제한 상업 사용
- 성능 오버헤드 감안 필요

### 비추천
- **Unity**: 라이선스 정책 변경 리스크, Flutter 통합 복잡도, $200K 수익 한도 부담
- **three_dart / flutter_gl**: 2022년 이후 유지보수 중단, 프로덕션 리스크

---

## References

- [Unity Pricing Updates (Official)](https://unity.com/products/pricing-updates)
- [Unity Personal Plan (Official)](https://unity.com/products/unity-personal)
- [Unity Runtime Fee Cancellation Announcement](https://unity.com/blog/unity-is-canceling-the-runtime-fee)
- [Unity scraps Runtime Fee — CG Channel](https://www.cgchannel.com/2024/09/unity-scraps-controversial-runtime-fee-but-raises-prices/)
- [Unity Pricing Changes 2025 — Appverse](https://www.appverse.io/unity-pricing-changes-explained-what-developers-need-to-know-in-2025.php)
- [Godot License (Official)](https://godotengine.org/license/)
- [Godot Docs — Complying with Licenses](https://docs.godotengine.org/en/stable/about/complying_with_licenses.html)
- [Embedding Godot in iOS apps (2025)](https://christianselig.com/2025/05/godot-ios-interop/)
- [flame — pub.dev](https://pub.dev/packages/flame)
- [flame license — pub.dev](https://pub.dev/packages/flame/license)
- [three_dart — pub.dev](https://pub.dev/packages/three_dart)
- [flutter_gl — pub.dev](https://pub.dev/packages/flutter_gl)
- [flutter_unity_widget — pub.dev](https://pub.dev/packages/flutter_unity_widget)
- [babylonjs_viewer — pub.dev](https://pub.dev/packages/babylonjs_viewer)
- [Babylon.js License (GitHub)](https://github.com/BabylonJS/Babylon.js/blob/master/license.md)
- [Babylon.js Forum — Commercial Code Questions](https://forum.babylonjs.com/t/commercial-code-questions/2105)
- [Cross-platform 3D Rendering in Flutter (blog)](https://blog.mqhamdam.pro/flutter-three-d-crossplatform-rendering/)

## Communication Log
| # | 방향 | 상대 | 내용 요약 | 시점(단계) |
|---|------|------|----------|-----------|
| 1 | → | 오케스트레이터 | 라이선스 조사 완료, 보고서 작성 완료 | 조사 완료 |

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
