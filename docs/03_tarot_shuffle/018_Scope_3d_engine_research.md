---
id: "018"
type: scope
title: "타로 셔플 3D 엔진 비교 연구"
created: 2026-03-16
complexity: simple
research_needed: true
research_reason: "Flutter 외부 3D 엔진(Flame, three_dart, Unity, Godot 등) 상세 비교 — 프리렌더 vs 실시간, 모바일 성능 실측 데이터, Flutter 통합 방식까지 조사 필요"
auto_run: true
intent: >
  타로 카드 셔플 애니메이션을 고급 3D로 업그레이드하기 위한 엔진 후보 비교 연구.
  손이 등장해 카드를 섞는 모션(손가락 표현 포함), 손가락-카드 물리 충돌,
  폰 기울이기/흔들기 기반 실시간 물리(가속도계), 프리렌더+실시간 혼합 방식까지 고려.
  평가 기준: 무료(라이선스), 품질(3D/물리), 모바일 기기 부담(GPU/CPU/배터리/APK).
summary: >
  단일 연구 영역. 외부 3D 엔진 5~7개 후보를 무료/품질/모바일 성능 기준으로
  정량+정성 비교. 프리렌더 vs 실시간 렌더 방식 타협점도 분석.
keywords: [3D engine, Flutter, tarot shuffle, physics, pre-render, real-time, mobile performance]
---

# 타로 셔플 3D 엔진 비교 연구

## 작업 목표

현재 타로 셔플 애니메이션(2D CustomPainter 기반)을 3D로 업그레이드하기 위한
엔진 선택 근거를 확립한다. 연구 결과는 향후 구현 방향 결정의 단일 진실 원천이 된다.

**핵심 요구사항:**
1. **손 모션**: 손이 등장해 카드를 섞는 리얼한 3D 애니메이션 (손가락 단위 표현)
2. **물리 충돌**: 손가락이 카드를 밀면 카드들이 물리적으로 반응 (충돌, 겹침, 튕김)
3. **센서 연동**: 폰 기울이기/흔들기 → 가속도계 기반 실시간 카드 물리 (중력 방향 쏠림)
4. **렌더 혼합**: 프리렌더 고품질 + 실시간 물리 인터랙션 혼합 방식
5. **Flutter 통합**: 기존 Flutter 앱에 통합 가능해야 함

**평가 기준 (우선순위 순):**
- 🔑 **무료**: 완전 오픈소스 또는 무제한 무료 티어 (수익 제한 없음)
- 🔑 **품질**: 3D 렌더링 품질, 물리 정확도, 손/손가락 표현력
- 🔑 **모바일 부담**: GPU/CPU 사용량, 배터리, APK 크기, 저사양 기기 대응

## 접근 방향

**웹 리서치 기반 정량+정성 비교 분석**

후보 엔진 목록 (초기):
- `three_dart` + `flutter_gl` (Three.js Dart 포트)
- `Flame` + `flame_3d` (Flutter 게임 엔진)
- `Unity` + `flutter_unity_widget` (업계 표준, 무료 조건 확인 필요)
- `Godot` + WebView/Flutter 브리지 (MIT 라이선스)
- `Babylon.js` + WebView (WebGL 기반)
- Flutter 내장 `Matrix4` + `FragmentShader` (pseudo-3D)
- `flutter_animate` + 물리 라이브러리 조합

**비교 프레임워크:**
1. 엔진별 라이선스/무료 조건 정확한 확인
2. 3D 품질 벤치마크 (렌더링, 물리, 애니메이션 정밀도)
3. 모바일 성능 실측/레퍼런스 데이터
4. 프리렌더 vs 실시간 방식별 Flutter 통합 패턴
5. 실제 유사 구현 사례 (카드 게임, 손 모션 앱)
6. **타협점 분석**: 고품질 프리렌더 + 경량 실시간 인터랙션 혼합 최적 패턴

## Research 판단
- **판단**: 필요
- **근거**: 외부 3D 엔진 5~7개의 최신 라이선스, 성능 벤치마크, Flutter 통합 방식은
  프로젝트 코드베이스에서 파악 불가. 웹 조사 + 공식 문서 분석 필수.
- **파이프라인**: S → R (연구 완료 후 종료)

## 연구 가이드

### 조사 대상 엔진
1. `three_dart` + `flutter_gl` — Three.js Dart 포트, pub.dev 패키지
2. `Flame` 3.x + `flame_3d` experimental
3. `Unity` (Personal/Student 플랜) + `flutter_unity_widget` 3.x
4. `Godot 4.x` + Dart/Flutter 브리지 방식
5. `Babylon.js` + `flutter_inappwebview` / `webview_flutter`
6. Flutter 내장: `Matrix4` + `FragmentShader` + `sensors_plus` 조합

### 핵심 연구 질문
1. **라이선스**: 각 엔진의 상업적 무료 사용 조건은? (수익 제한, 로고 의무, 플랫폼 제한)
2. **손 모션 표현**: skeletal animation, 손가락 bone rigging 지원 수준?
3. **물리 엔진**: 내장 물리 엔진 종류, rigid body collision 지원, 모바일 성능?
4. **센서 연동**: 가속도계 데이터를 물리 엔진 gravity/force로 연결하는 방식?
5. **프리렌더 통합**: 고품질 프리렌더 영상을 실시간 인터랙션과 어떻게 합치는가?
6. **Flutter 통합**: 통합 방식 (PlatformView, WebView, 네이티브 플러그인) 별 오버헤드?
7. **APK 크기**: 엔진 추가 후 APK 증가량?
8. **실제 사례**: 모바일 카드 게임, 타로/마법 테마 앱 레퍼런스?

## 체크포인트 & 컨텍스트 관리

| 체크포인트 | 산출물 | 컨텍스트 조치 |
|-----------|--------|-------------|
| /scope 완료 | 이 문서 | /clear 권장 (research가 독립 넓은 탐색) |
| /research 완료 | Research 문서 (019_) | 종료 (연구까지만) |

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
