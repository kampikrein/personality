---
id: "002"
type: research
title: "타로 셔플 앱 기술 스택 연구"
created: 2026-03-15
status: in-progress
traces_scope: "001"
summary: >
  Flutter 기반 타로 셔플 앱 MVP 구현을 위한 기술 스택 연구.
  셔플 물리 엔진, 센서/난수 생성, 데이터 아키텍처, 앱 아키텍처 4개 관점 조사.
keywords: [flutter, shuffle-engine, sensors, csprng, offline-first, clean-architecture]
parallel_plan:
  total_perspectives: 4
  phases:
    - phase: 1
      perspectives: [1, 2, 3, 4]
      status: completed
      agent_numbers: ["003", "004", "005", "006"]
  synthesis_number: "007"
  final_number: "008"
---

# 타로 셔플 앱 기술 스택 연구

## Research Overview

### Background & Motivation
PRD(docs/003_gemini_deep_research.md)에서 정의한 타로 셔플 앱의 핵심 차별화 요소는
"사용자의 물리적 상호작용이 셔플 결과에 반영되는 제의적 경험"이다.
이를 Flutter Android MVP로 구현하기 위한 기술 스택 결정이 필요하다.

현재 `mobile/`은 빈 Flutter 스켈레톤(MaterialApp만 존재)이므로,
기술 선택의 자유도가 높은 동시에 참고할 내부 패턴이 없다.

### Research Scope
**포함**: Flutter 생태계 내 물리 엔진, 센서 API, 난수 생성, 로컬 DB, 앱 아키텍처 패턴
**제외**: 서버 사이드(Rails API), 클라우드 동기화, 커뮤니티/바운티 시스템 (Phase 3-4 범위)

### Research Perspectives
1. **셔플 엔진 & 카드 애니메이션** — 물리 엔진 선택, 카드 모션 그래픽 구현 방식, 성능 최적화
2. **센서 통합 & 난수 생성** — 디바이스 센서 데이터 수집, CSPRNG 구현, 하이브리드 엔트로피 모델
3. **데이터 아키텍처 & 오프라인** — 로컬 DB 선택, 커스텀 덱 JSON 스키마, 이미지 관리
4. **Flutter 앱 아키텍처 & 프로젝트 구조** — 아키텍처 패턴, 상태 관리, 프로젝트 구조, 테스트

## Preliminary Findings

### 현재 프로젝트 상태
- `mobile/pubspec.yaml`: Flutter 3.10+, Dart 3.0+, 의존성 없음 (flutter SDK만)
- `mobile/lib/main.dart`: 빈 MaterialApp 스켈레톤
- PRD가 명시한 프레임워크: Flutter (React Native 대안도 언급하나 Flutter 이미 선택됨)
- PRD가 명시한 아키텍처: Clean Architecture + MVVM, Strategy Pattern (셔플), Factory Pattern (카드)

### PRD 핵심 기술 요구사항 요약
- CSPRNG (crypto/rand 수준) 기반 난수 + 센서 엔트로피 하이브리드
- 3가지 셔플 모션: 리플(Riffle), 오버핸드(Overhand), 워시/메시(Wash/Messy)
- 각 카드 독립 X/Y/Z 좌표 + 회전각 상태 관리
- 2D 물리 엔진 충돌 처리 (워시 셔플)
- 햅틱 피드백 (카드 교차/낙하 시)
- 60fps 유지 (구형 디바이스 포함)
- 오프라인-퍼스트 (SQLite/Realm 등)
- JSON 스키마 기반 커스텀 덱

## Parallel Execution Instructions

### Perspective 1: 셔플 엔진 & 카드 애니메이션

**조사 목표**: Flutter에서 78장 카드의 물리 기반 셔플 애니메이션을 60fps로 구현하기 위한 최적 기술 스택 결정

**구체적 조사 항목**:
1. **물리 엔진 비교** (외부 조사):
   - Flame 게임 엔진: 2D 게임 프레임워크로서의 카드 게임 적합성, Forge2D(Box2D 포트) 물리 엔진
   - Flutter 자체 AnimationController + CustomPainter: 게임 엔진 없이 직접 구현
   - 각 방식의 성능 특성 (78장 동시 렌더링 시 fps)

2. **셔플 모션별 구현 방식**:
   - 리플 셔플: 두 덱 교차 애니메이션 (cubic-bezier, 150-200ms 딜레이)
   - 오버핸드 셔플: 청크 분리 + Z축 이동 3D 효과
   - 워시/메시: 2D RigidBody 충돌 처리, 드래그 궤적 추적

3. **애니메이션 도구 비교**:
   - Flutter implicit/explicit animations
   - Rive (구 Flare): 벡터 애니메이션
   - Lottie: After Effects 기반
   - CustomPainter + Canvas 직접 그리기

4. **성능 최적화**:
   - RepaintBoundary 활용
   - 구형 디바이스 테스트 전략
   - 카드 이미지 렌더링 최적화 (캐싱, 해상도 관리)

**검색 키워드**: "flutter card game engine", "flame engine card shuffle", "flutter 2d physics card", "flutter custom painter performance 60fps", "flutter forge2d tutorial", "flutter card flip animation"

### Perspective 2: 센서 통합 & 난수 생성

**조사 목표**: 디바이스 센서 데이터를 엔트로피 소스로 활용하는 하이브리드 난수 생성 시스템 구현 방법

**구체적 조사 항목**:
1. **센서 API 패키지**:
   - sensors_plus: 가속도계, 자이로스코프 지원 범위, 샘플링 레이트, 배터리 영향
   - motion_sensors: 대안 패키지
   - 터치 이벤트 타임스탬프 정밀도 (GestureDetector)

2. **CSPRNG 구현**:
   - `dart:math` Random.secure(): 내부 구현, 플랫폼별 차이 (Android/iOS)
   - pointycastle: Fortuna 등 알고리즘
   - PRD의 시드 공식: S = Σ(√(Ax²+Ay²+Az²) × Gz) ⊕ Ti 구현 실현 가능성

3. **하이브리드 엔트로피 모델**:
   - 센서 데이터 → 엔트로피 풀 → CSPRNG 시드 주입 아키텍처
   - 센서 데이터 부족 시 폴백 (에뮬레이터, 센서 없는 기기)
   - Fisher-Yates 셔플 알고리즘 + 커스텀 시드

4. **햅틱 피드백**:
   - flutter_vibrate / haptic_feedback 패키지
   - 카드 교차/충돌 시점의 미세한 햅틱 틱 구현
   - Android 플랫폼별 햅틱 지원 차이

**검색 키워드**: "flutter sensors_plus gyroscope accelerometer", "dart secure random csprng", "flutter haptic feedback vibration", "mobile sensor entropy random number", "fisher-yates shuffle dart"

### Perspective 3: 데이터 아키텍처 & 오프라인

**조사 목표**: 커스텀 덱 JSON 스키마 데이터와 카드 이미지를 오프라인-퍼스트로 관리하기 위한 최적 로컬 스토리지 전략

**구체적 조사 항목**:
1. **로컬 DB 비교**:
   - sqflite: SQLite 래퍼, 관계형 쿼리 지원, 마이그레이션
   - drift (구 moor): 타입 안전 SQL, 코드 생성, 리액티브 쿼리
   - hive: 경량 NoSQL, 빠른 읽기/쓰기, 박스 기반
   - Isar: Hive 후속, 고성능 NoSQL (현재 상태 확인)
   - 각 DB의 JSON 구조 데이터 저장 적합성

2. **커스텀 덱 스키마 관리**:
   - PRD의 deck.json 스키마를 Dart 모델로 변환하는 방법
   - json_serializable / freezed 코드 생성
   - 스키마 유효성 검증 (json_schema 패키지 등)

3. **이미지 관리**:
   - 카드 이미지 저장 전략: DB에 경로만 vs 파일시스템 직접
   - 대량 이미지 로딩 최적화 (78장+ 동시 표시)
   - cached_network_image vs 로컬 에셋 관리
   - 이미지 리사이징/압축 (image 패키지)

4. **오프라인-퍼스트 설계**:
   - 네트워크 없이 100% 기능 동작 보장 방법
   - 향후 클라우드 동기화를 위한 설계 고려 (Phase 3 대비)

**검색 키워드**: "flutter local database comparison 2025", "drift vs hive vs sqflite", "flutter offline first architecture", "flutter json schema validation", "flutter image cache management"

### Perspective 4: Flutter 앱 아키텍처 & 프로젝트 구조

**조사 목표**: PRD가 요구하는 모듈화된 Clean Architecture를 Flutter에서 구현하기 위한 아키텍처 패턴과 프로젝트 구조 결정

**구체적 조사 항목**:
1. **아키텍처 패턴**:
   - Clean Architecture in Flutter: 3계층(Data/Domain/Presentation) 구현 방법
   - MVVM vs BLoC vs Riverpod 기반 아키텍처
   - PRD가 명시한 Strategy Pattern (셔플 엔진)의 Dart 구현

2. **상태 관리 비교**:
   - Riverpod 2.x: Provider 후속, 코드 생성, 테스트 용이성
   - flutter_bloc: 이벤트-상태 패턴, 엄격한 단방향 흐름
   - GetX: 간편하지만 관심사 분리 약함
   - 78장 카드 개별 상태(위치, 회전, 뒤집힘) 관리에 적합한 패턴

3. **프로젝트 폴더 구조**:
   - feature-first vs layer-first 구조
   - 모듈화 전략 (셔플 엔진, 덱 빌더, 리딩 뷰어 분리)
   - 추천 패키지 구조 예시

4. **테스트 전략**:
   - 물리 엔진/셔플 알고리즘 단위 테스트
   - 위젯 테스트 (카드 플립, 스프레드 레이아웃)
   - 통합 테스트 (셔플 → 드로우 → 스프레드 전체 흐름)
   - Golden 테스트 (시각적 회귀 방지)

**검색 키워드**: "flutter clean architecture 2025", "riverpod vs bloc flutter", "flutter project structure best practices", "flutter game architecture pattern", "flutter widget test animation"

## Remaining Work
- [ ] Perspective 1: 셔플 엔진 & 카드 애니메이션
- [ ] Perspective 2: 센서 통합 & 난수 생성
- [ ] Perspective 3: 데이터 아키텍처 & 오프라인
- [ ] Perspective 4: Flutter 앱 아키텍처 & 프로젝트 구조
- [ ] Cross-Analysis
- [ ] Comprehensive Conclusion

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
