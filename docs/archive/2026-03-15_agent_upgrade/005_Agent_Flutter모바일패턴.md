---
id: "005"
title: "Flutter/모바일 개발 에이전트 패턴 조사"
category: agent
status: complete
created: 2026-03-15
summary: >
  Flutter 전문 AI 에이전트에 필요한 핵심 지식, 물리엔진/센서 분리 여부, 모바일 특수 영역 커버리지 조사
keywords: [agent-report, flutter, dart, mobile, physics-engine, sensor-api, offline-first, state-management]
modules: [mobile-development]
---

# Flutter/모바일 개발 에이전트 패턴 조사

## Progress
### Completed
- [x] Flutter 전문 에이전트 핵심 지식 영역 조사
- [x] 물리 엔진/애니메이션 분리 vs 통합 분석
- [x] 센서 API, 오프라인-퍼스트 등 모바일 특수 영역 조사
- [x] Flutter + Rails API 연동 에이전트 협업 포인트 분석
- [x] Flutter 생태계 최신 동향 (2025-2026) 조사
- [x] 에이전트 분리 권장안 및 최종 종합
### Remaining
- (없음 — 전체 조사 완료)
### Current Status
전체 조사 완료. 최종 보고서 작성됨.

## Summary

Flutter 전문 AI 에이전트 설계를 위한 포괄적 기술 조사 완료. 핵심 결론: (1) 물리 엔진/애니메이션은 별도 에이전트 분리 불필요, 단일 Flutter 에이전트에 통합 권장 (2) Riverpod 3.0 + MVVM + Clean Architecture가 PRD 요구사항에 최적 (3) 오프라인-퍼스트는 Drift+Hive 하이브리드 + Riverpod 3.0 내장 퍼시스턴스로 해결 (4) CSPRNG는 Random.secure() 또는 pointycastle FortunaRandom 필수 (5) Flutter+Rails 연동은 OpenAPI 스키마 기반 코드 생성(dart-dio)이 에이전트 간 협업 핵심 (6) 기존 coding-expert(Rails)와 새 flutter-expert 사이에 shared/ OpenAPI 스키마가 계약 경계.

## Details

### 1. Flutter 전문 에이전트 핵심 지식 영역

#### 1.1 Dart 언어 특성
- **Null Safety**: Sound null safety 필수. `!` 연산자 최소화, 패턴 매칭 적극 활용
- **비동기 패턴**: `Future`/`async`/`await` (단일 비동기), `Stream` (연속 이벤트), `Isolate` (CPU 집약 작업)
- **컴파일**: Debug=JIT(Hot Reload 지원), Release=AOT(네이티브 ARM 코드, 고성능)
- **타입 시스템**: Records(다중 반환), 패턴 매칭, exhaustive switch, sealed class

#### 1.2 위젯 시스템
- **불변성**: StatelessWidget은 반드시 불변. `const` 생성자로 리빌드 최소화
- **컴포지션 > 상속**: 작은 위젯 조합 선호, 큰 build() 메서드는 private Widget 클래스로 분리
- **성능**: ListView.builder/SliverList (lazy loading), compute() (별도 Isolate), build()에서 비용 큰 연산 금지

#### 1.3 상태관리 (2026년 기준)
| 라이브러리 | 포지션 | 보일러플레이트 | 학습곡선 | 테스트 | 추천 대상 |
|-----------|--------|-------------|---------|--------|----------|
| **Riverpod 3.0** | 모던 표준 | 낮음 | 중간 | 우수 | 신규 프로젝트, 오프라인-퍼스트 |
| **BLoC 9.0** | 엔터프라이즈 | 높음 | 가파름 | 우수 | 규제 산업, 감사 추적 필요 |
| **Signals 6.0** | 성능 특화 | 매우 낮음 | 완만 | 양호 | 실시간 시각화, 저사양 기기 |
| **Provider** | 레거시 안정 | 중간 | 완만 | 양호 | 학습용, 단순 앱 |
| **GetX** | **비추천** | 매우 낮음 | 완만 | 어려움 | 유지보수 위기, 단일 관리자 리스크 |

**PRD 기준 권장**: Riverpod 3.0 (오프라인 퍼시스턴스 내장, 컴파일 타임 안전성, MVVM 호환)
- Riverpod 3.0 신기능: 오프라인 퍼시스턴스(riverpod_sqflite), Mutations API, 자동 재시도, AsyncValue.isFromCache
- 기본 2일 캐시, 모든 Notifier 프로바이더에서 opt-in 지원

#### 1.4 아키텍처 패턴
- **MVVM + Clean Architecture**: Presentation / Domain / Data / Core 레이어
- **Feature-Based 구조**: 대규모 프로젝트에서 feature별 하위 폴더(presentation/domain/data) 구성
- **Repository 패턴**: 데이터 소스 추상화, 테스트 용이성 확보
- **SOLID 원칙**: 전체 코드베이스에 일관 적용

#### 1.5 빌드 시스템
- **Android**: Gradle → APK/AAB. Flutter가 Gradle 파일 생성 후 의존성 관리
- **iOS**: CocoaPods + Xcode → IPA. Podfile로 의존성 해결
- **플랫폼 채널**: MethodChannel(단발 호출), EventChannel(실시간 업데이트). 네이티브 SDK 연동 핵심

#### 1.6 테스팅 전략
- **테스트 피라미드**: Unit(다수) > Widget(중간) > Integration(소수)
- **TDD**: 코드 전 테스트 작성, 조기 버그 탐지
- **도구**: `package:test`, `package:flutter_test`, `integration_test`, Mockito/Mocktail
- **엣지 케이스**: 네트워크 실패, API 오류, 비정상 입력 필수 테스트

#### 1.7 Flutter 공식 AI 규칙
Flutter 팀이 공식 AI 규칙 파일 제공 (rules.md, rules_10k.md, rules_4k.md, rules_1k.md):
- PascalCase(클래스), camelCase(변수/함수), snake_case(파일), 80자 줄 제한
- 함수 20줄 이하, 단일 목적, 화살표 구문(1줄 함수)
- `///` doc 주석, `dart:developer`의 log() 사용 (print 금지)
- `const` 생성자 적극 활용, `json_serializable` + `build_runner` 코드 생성
- WCAG 2.1 접근성 기준 충족 (대비비 4.5:1)

---

### 2. 물리 엔진/애니메이션: 분리 vs 통합 분석

#### 2.1 Flame 게임 엔진 (v1.29.0)
- **정체**: Flutter 기반 경량 2D 게임 엔진, Google 공식 지원
- **핵심 기능**: 게임 루프, 스프라이트, 애니메이션, 충돌 감지, 입력 처리, 오디오, 파티클
- **컴포넌트 시스템**: Flutter 위젯과 유사한 컴포넌트 트리 구조
- **카드 게임**: Klondike 튜토리얼에서 카드 이동, 드래그, 플립, 딜 애니메이션 구현 예시 제공
- **Effect 시스템**: EffectController로 타이밍(duration, delay, Curve) 관리
- **Model-View 분리**: 게임 로직(_faceUp)과 렌더링(_isFaceUpView) 분리 패턴

#### 2.2 Forge2D (Box2D for Dart)
- **정체**: Box2D 물리 엔진의 Dart 포팅. flame_forge2d 브릿지 라이브러리로 Flame과 통합
- **기능**: 중력, 충돌, 힘, 마찰 등 복잡한 물리 시뮬레이션 (수학 계산 불필요)
- **통합 방식**: Forge2DGame 클래스가 BodyComponent(물리)와 일반 Flame 컴포넌트 동시 지원
- **성숙도**: Box2D 기반으로 안정적, Flutter 게임 물리에서 사실상 표준

#### 2.3 Flutter 네이티브 애니메이션 (Flame 없이)
- **3D 카드 플립**: Transform 위젯 + Matrix4.rotateY() + setEntry()(원근감) + Tween
- **Cubic Bezier**: Cubic 클래스로 커스텀 타이밍 곡선 (easeInBack, easeOutBack 등)
- **깊이감**: Matrix4.setEntry(3, 2, 0.001)로 Z축 원근 투영
- **카드 스왑**: 애니메이션 값 0.5 기준 앞면/뒷면 전환
- **필요 지식 수준**: 중급 (Transform, Matrix4, AnimationController, Tween 이해 필요)

#### 2.4 분리 vs 통합 판단

**분석 결과: 통합 권장 (단일 Flutter 에이전트에 포함)**

근거:
1. **셔플 물리 복잡도 = 중간**: 카드 셔플은 풀스케일 게임 물리가 아님. Forge2D 기본 기능 + 커스텀 파라미터 조정 수준
2. **Flame 학습 곡선 = 중간**: 컴포넌트 시스템이 Flutter 위젯과 유사. 게임 전용 개념(게임 루프, Effect)만 추가 학습
3. **카드 애니메이션 = Flutter 네이티브로 충분**: 3D 플립, cubic-bezier는 Flame 없이 Transform+Matrix4로 구현 가능
4. **Forge2D 통합 = 간단**: flame_forge2d 브릿지가 물리 컴포넌트와 일반 컴포넌트 공존 지원
5. **분리 시 비용 > 이점**: 물리/애니메이션만 별도 에이전트로 분리하면 에이전트 간 컨텍스트 공유 비용이 구현 복잡도보다 큼

단, **셔플 물리 파라미터 튜닝**(마찰 계수, 중력 스케일, 충돌 반발)은 도메인 지식이 필요하므로 에이전트 지식에 Forge2D 물리 파라미터 가이드라인을 포함해야 함.

---

### 3. 모바일 특수 영역 조사

#### 3.1 센서 API

**sensors_plus** (공식 추천, 가장 활발한 유지보수):
- 가속도계(AccelerometerEvent): m/s² 단위, 중력 포함 원시 데이터
- 자이로스코프(GyroscopeEvent): 디바이스 회전 데이터
- 자기장(MagnetometerEvent), 기압계(BarometerEvent)
- BroadcastStream으로 이벤트 노출
- iOS: Info.plist에 NSMotionUsageDescription 필수 (크래시 방지)

**대안 패키지**:
- motion_sensors: 가속도계+자이로+자기장+방향 통합
- flutter_use_sensors: hooks 기반 센서 접근

**PRD 활용**: 자이로스코프/가속도계 → 셔플 제스처 감지, 디바이스 기울기 기반 카드 움직임

#### 3.2 오프라인-퍼스트 데이터베이스

| DB | 유형 | 강점 | 약점 | 적합 사례 |
|----|------|------|------|----------|
| **Hive** | Key-Value | 초고속, 최소 셋업 | 관계형 쿼리 불가, 대규모 부적합 | 설정, 캐시, 최근 목록 |
| **Drift** | SQLite 래퍼 | 컴파일타임 타입 안전, 마이그레이션 | 학습곡선 높음 | 금융, e커머스, 관계형 데이터 |
| **Floor** | SQLite ORM | Drift보다 단순, DAO 기반 | Drift보다 기능 제한 | 중간 규모 CRUD 앱 |
| **Isar** | 객체 저장소 | 대규모 인덱싱 우수 | 신생, 장기 검증 부족 | 채팅 앱, 분석 버퍼 |

**PRD 기준 권장**: **하이브리드 접근** — Drift(핵심 관계형: 타로 결과, 사용자 프로필) + Hive(경량 캐시: 설정, UI 상태)
- Riverpod 3.0의 riverpod_sqflite와 자연스럽게 통합
- Flutter 공식 오프라인-퍼스트 아키텍처: Repository 패턴 + Stream 기반 읽기 + 동기화 플래그

**동기화 패턴** (Flutter 공식 가이드):
- Stream 접근: 로컬 캐시 먼저 emit → 네트워크 데이터 업데이트 emit
- 동기화 플래그: `synchronized` 필드로 미전송 데이터 추적
- 백그라운드 동기: Timer.periodic, Workmanager 플러그인
- 네트워크 감지: connectivity_plus, 배터리 인식: battery_plus

#### 3.3 CSPRNG (암호학적 보안 난수)

**핵심 경고**: Dart의 `Random()` 기본 생성자는 32비트 엔트로피만 제공 (64비트로 보이지만 내부적으로 0xFFFFFFFF 마스킹)

**실제 취약점 사례**:
- Dart Tooling Daemon: 32비트 엔트로피로 ~10초 내 브루트포스 가능
- Proton Wallet: 복구 문구가 2^32 가능성으로 축소, ~16분 내 오프라인 공격 가능
- SelfPrivacy: 생성된 패스워드/API 토큰 엔트로피 부족

**올바른 구현**:
- `Random.secure()` 사용 필수 (플랫폼별 OS 엔트로피 소스 활용)
- **pointycastle** 패키지의 FortunaRandom: AES 기반 CSPRNG, 256비트 키 시딩
- WebAssembly 주의: 2024년 9월까지 초기 시드 하드코딩 문제 있었음
- 시드 초기화 시 엔트로피 폭 전체 보존 필수

**PRD 적용**: 타로 셔플의 CSPRNG는 반드시 `Random.secure()` 또는 FortunaRandom 사용. `Random()` 사용 금지.

#### 3.4 햅틱 피드백

**Flutter 내장 HapticFeedback**:
- `HapticFeedback.vibrate()`: 짧은 진동
- `HapticFeedback.lightImpact()`: 가벼운 충돌감
- `HapticFeedback.mediumImpact()`: 중간 충돌감
- `HapticFeedback.heavyImpact()`: 강한 충돌감
- iOS: UIImpactFeedbackGenerator (iOS 10+)

**고급 패키지**:
- **haptic_feedback**: Android API 30+ 고해상도 프리미티브, 하위 버전 폴백
- **flutter_vibrate**: 커스텀 패턴, 플랫폼별 피드백 상수(Impact, Selection, Success, Warning, Error)
- **gaimon**: .ahap 파일 지원 (Apple 커스텀 햅틱 패턴)

**PRD 적용**: 카드 셔플 시 mediumImpact, 카드 플립 시 lightImpact, 결과 공개 시 heavyImpact 조합

#### 3.5 이미지 처리 및 대량 업로드

**Isolate 기반 처리**:
- `compute()` 또는 `Isolate.spawn()`으로 UI Isolate에서 이미지 디코드/리사이즈/필터 분리
- `TransferableTypedData`/`Uint8List`로 효율적 데이터 전달 (복사 최소화)
- Isolate 풀: 소수 워커 또는 단일 워커 선호 (다수 Isolate 스폰은 리소스 과부하)

**메모리 관리**:
- `cacheWidth`/`cacheHeight`로 ImageCache 메모리 사용량 감소
- 30MB 이미지 × Isolate 전송 = 최소 90MB (3배 복사). TransferableTypedData로 소유권 이전 필요
- 대량 업로드: 백그라운드 Isolate에서 업로드, UI는 계속 반응 유지

#### 3.6 Strategy 패턴 (셔플 알고리즘)

Dart에서의 Strategy 패턴 구현:
- 공통 인터페이스 정의 → 알고리즘별 클래스 구현 → 런타임 교체
- Dart의 sealed class와 결합하여 exhaustive matching 가능
- **PRD 적용**: ShuffleStrategy 인터페이스 → RiffleShuffle, OverhandShuffle, HinduShuffle 등 구현체
- 컴포지션 기반으로 Context 클래스가 Strategy를 위임

---

### 4. Flutter + Rails API 연동 에이전트 협업 포인트

#### 4.1 OpenAPI 기반 코드 생성 파이프라인

**Rails 측 (coding-expert 영역)**:
- **rswag**: RSpec 테스트에서 OpenAPI 스펙 자동 생성. 테스트-문서 동기화 보장
- **rspec-openapi**: DSL 없이 request spec에서 OpenAPI 스펙 추출
- **grape-swagger**: Grape API 사용 시 자동 문서화
- 생성된 스펙은 `shared/` 디렉토리에 OpenAPI YAML/JSON으로 저장

**Flutter 측 (flutter-expert 영역)**:
- **openapi-generator (dart-dio)**: OpenAPI 스펙 → Dart Dio 클라이언트 코드 자동 생성
- **openapi_generator (pub 패키지)**: Flutter build_runner 통합, 어노테이션 기반 생성
- **openapi_freezed_dio_builder**: Freezed + Dio 기반 모델/API 클래스 생성
- **retrofit + dio**: 생성된 코드의 HTTP 클라이언트 레이어

**파이프라인 흐름**:
```
Rails API → rswag/rspec-openapi → shared/openapi.yaml → openapi-generator dart-dio → Flutter Dio Client
```

#### 4.2 인증 연동

**JWT 토큰 흐름** (Rails + Flutter):
- Rails: Devise-JWT, JTI 메커니즘, 리프레시 토큰 (15분 액세스 / 7일 리프레시)
- Flutter: Dio 인터셉터에서 토큰 자동 갱신 (proactive/reactive 접근)
- 토큰 저장: `flutter_secure_storage` 필수 (SharedPreferences 금지)
- 생체인증: Face ID / Fingerprint 통합 가능

#### 4.3 오프라인-퍼스트 동기화

**에이전트 협업 경계**:
- coding-expert: Rails API 엔드포인트 (동기화 delta 제공, conflict resolution 정책)
- flutter-expert: 로컬 저장소 + 동기화 큐 + 네트워크 상태 관리

**동기화 전략**:
- Stream 기반: 로컬 캐시 즉시 표시 → 네트워크 데이터 백그라운드 갱신
- Workmanager: 앱 종료 후에도 백그라운드 동기화
- connectivity_plus: 네트워크 상태 감지, 온라인 전환 시 자동 동기화

#### 4.4 에이전트 간 계약 경계

| 영역 | coding-expert (Rails) | flutter-expert (Flutter) | 공유 계약 |
|------|----------------------|------------------------|----------|
| API 정의 | 엔드포인트 구현, 스펙 생성 | 클라이언트 코드 생성, 호출 | shared/openapi.yaml |
| 인증 | JWT 발급/갱신/폐기 | 토큰 저장/자동갱신/생체인증 | JWT 스키마 |
| 데이터 모델 | DB 스키마, 시리얼라이저 | Dart 모델, 로컬 DB 스키마 | OpenAPI 모델 정의 |
| 에러 처리 | HTTP 상태코드, 에러 포맷 | 에러 UI, 오프라인 폴백 | 에러 응답 스키마 |

---

### 5. Flutter 생태계 최신 동향 (2025-2026)

#### 5.1 Impeller 렌더링 엔진 (기본값 전환)
- Flutter 3.27부터 iOS + Android(API 29+) 기본 렌더링 엔진
- **사전 컴파일 셰이더**: 런타임 셰이더 컴파일 제거 → "jank" 완전 해소
- **프레임 성능**: 복잡한 씬에서 평균 래스터화 시간 ~50% 감소
- **프레임 안정성**: Skia 16ms 스파이크 → Impeller 8ms 이하 (120Hz 디스플레이)
- **드롭 프레임**: 90% 감소
- **GPU 활용**: iOS=Metal, Android=Vulkan 직접 통신
- **카드 애니메이션 임팩트**: 반투명 효과(블러, 그림자, 클리핑) 프레임 드롭 없이 처리 가능

#### 5.2 Swift Package Manager 전환
- CocoaPods 대안으로 SPM 지원 추가 (Flutter 3.24+)
- 현재 opt-in, CocoaPods 병행 지원 중
- 장점: Ruby/CocoaPods 설치 불필요, Xcode 내장 SPM 활용
- 플러그인 개발자: SPM + CocoaPods 동시 지원 권장

#### 5.3 Flutter 3.38 / Dart 3.10 (2025.11)
- Impeller 최적화 지속
- Material Design 3 통합 강화
- 앱 사이즈 모듈화 축소

#### 5.4 Riverpod 3.0 (2025.09)
- 오프라인 퍼시스턴스 (experimental)
- Mutations API
- 자동 재시도 + 지수 백오프
- `@riverpod` 매크로로 보일러플레이트 추가 감소

#### 5.5 Flutter 공식 AI 규칙 파일
- Flutter 팀이 AI 에이전트용 공식 규칙 파일 배포
- 4가지 크기 변형 (rules.md, rules_10k, rules_4k, rules_1k)
- CLAUDE.md에 포함 가능 (Claude Code 전용 규칙과 합성)

#### 5.6 GenUI SDK
- Flutter 공식 AI-생성 UI SDK
- LLM이 텍스트 대신 Flutter 위젯 카탈로그로 UI 직접 생성

---

## Key Findings

1. **단일 Flutter 에이전트가 PRD 전체 커버 가능**: 물리 엔진(Forge2D), 센서 API(sensors_plus), CSPRNG(Random.secure/pointycastle), 햅틱(HapticFeedback), 오프라인-퍼스트(Drift+Hive), 카드 애니메이션(Transform+Matrix4)은 모두 하나의 에이전트 전문 영역 내에서 통합 가능. 각 영역이 깊은 전문성보다 폭넓은 Flutter 생태계 이해를 요구함.

2. **물리 엔진 분리 불필요**: 타로 카드 셔플의 물리 시뮬레이션은 게임 수준이 아닌 "제한된 물리 시뮬레이션"으로, Forge2D 기본 기능 + 파라미터 조정 수준. Flame+Forge2D의 학습 곡선이 Flutter 위젯 시스템과 유사하여 별도 전문가 불필요.

3. **CSPRNG 보안 취약점 심각**: Dart의 `Random()` 기본 생성자가 실제로 32비트 엔트로피만 제공하는 심각한 보안 문제 발견. Proton Wallet 등 실제 취약점 사례 존재. 에이전트가 이 지식을 반드시 보유해야 함.

4. **Riverpod 3.0이 최적 선택**: 2026년 기준 모던 표준으로 자리잡음. 오프라인 퍼시스턴스 내장(riverpod_sqflite), 컴파일 타임 안전성, MVVM 호환, 낮은 보일러플레이트. GetX는 유지보수 위기로 절대 비추천.

5. **OpenAPI가 에이전트 간 계약 핵심**: Rails coding-expert와 Flutter flutter-expert 사이에 shared/openapi.yaml이 유일한 진실의 원천. rswag(Rails) → openapi-generator dart-dio(Flutter) 파이프라인이 자동 코드 생성 보장.

6. **Impeller가 카드 애니메이션 가능성 확장**: 프레임 래스터화 50% 감소, 드롭 프레임 90% 감소로 복잡한 카드 플립/셔플 애니메이션을 프레임 드롭 걱정 없이 구현 가능.

7. **Flutter 공식 AI 규칙 존재**: Flutter 팀이 AI 에이전트용 공식 코딩 규칙(rules.md)을 GitHub에 배포. 에이전트 CLAUDE.md에 통합하여 일관된 코드 품질 보장 가능.

---

## Recommendations

### R1. Flutter 전문 에이전트 역할 정의안

**이름**: `flutter-expert`

**전문 영역**: Flutter/Dart 모바일 앱 개발, 상태관리, 모바일 네이티브 기능, 물리 엔진/애니메이션

**핵심 지식 영역**:
| 카테고리 | 상세 기술 |
|---------|----------|
| Dart 언어 | Null safety, async/await, Stream, Isolate, Records, 패턴 매칭, sealed class |
| 위젯 시스템 | StatelessWidget, StatefulWidget, 컴포지션, const 생성자, 커스텀 위젯 |
| 상태관리 | Riverpod 3.0 (@riverpod 매크로, Notifier, AsyncNotifier, 오프라인 퍼시스턴스) |
| 아키텍처 | MVVM + Clean Architecture, Repository 패턴, Feature-Based 구조, SOLID |
| 물리/애니메이션 | Flame(Effect, EffectController), Forge2D(물리 시뮬레이션), Transform+Matrix4(3D 플립) |
| 센서 | sensors_plus (가속도계, 자이로스코프), motion_sensors |
| 보안 난수 | Random.secure(), pointycastle FortunaRandom, CSPRNG 취약점 인식 |
| 오프라인-퍼스트 | Drift(관계형), Hive(Key-Value), Riverpod 3.0 퍼시스턴스, 동기화 패턴 |
| 햅틱 | HapticFeedback(내장), haptic_feedback, gaimon(.ahap) |
| 이미지 처리 | Isolate 기반 리사이징, TransferableTypedData, 메모리 관리 |
| API 연동 | Dio + Retrofit, openapi-generator dart-dio, JWT 토큰 관리 |
| 빌드 | Gradle(Android), CocoaPods/SPM(iOS), build_runner, 코드 생성 |
| 테스팅 | TDD, unit/widget/integration test, Mockito/Mocktail |
| 디자인 패턴 | Strategy(셔플 알고리즘), Observer(센서 스트림), Repository(데이터 소스) |

### R2. 에이전트 분리 권장안

```
┌─────────────────────────────────────────────────────┐
│                personality 프로젝트                    │
│                                                     │
│  ┌──────────────┐  shared/openapi.yaml  ┌──────────────┐
│  │ coding-expert│◄────────────────────►│flutter-expert │
│  │   (Rails)    │     (계약 경계)        │  (Flutter)    │
│  └──────────────┘                      └──────────────┘
│                                                     │
│  ┌──────────────┐                      ┌──────────────┐
│  │ uiux-expert  │                      │ (기존 유지)    │
│  │ (웹 전용 유지) │                      │ psychology-   │
│  └──────────────┘                      │ expert 등     │
│                                        └──────────────┘
└─────────────────────────────────────────────────────┘
```

**변경 사항**:
1. `flutter-expert` 신규 추가 — Flutter/Dart 모바일 전체 담당
2. `coding-expert` 기존 유지 — Rails 백엔드 전용
3. `uiux-expert` 기존 유지 — 웹(Hotwire/Turbo/Tailwind) 전용
4. 물리 엔진/애니메이션 별도 에이전트 **불필요** — flutter-expert에 통합
5. 모바일 UX 별도 에이전트 **불필요** — flutter-expert가 모바일 네이티브 UX 포함

**에이전트 간 협업**:
- coding-expert ↔ flutter-expert: shared/openapi.yaml 통한 API 계약
- flutter-expert ↔ uiux-expert: 모바일 UX는 flutter-expert, 웹 UX는 uiux-expert (경계 명확)
- flutter-expert ↔ psychology-expert/mbti-expert/enneagram-expert: 콘텐츠는 도메인 전문가 생성, flutter-expert는 구현만 담당

### R3. 기술 스택 요약

| 레이어 | 선택 기술 | 대안 |
|--------|----------|------|
| **상태관리** | Riverpod 3.0 | BLoC 9.0 (엔터프라이즈 필요 시) |
| **아키텍처** | MVVM + Clean Architecture | - |
| **로컬 DB (관계형)** | Drift | Floor (단순 요구사항 시) |
| **로컬 DB (캐시)** | Hive | SharedPreferences (최소한 데이터) |
| **HTTP 클라이언트** | Dio + Retrofit | http (단순 요청 시) |
| **API 코드 생성** | openapi-generator dart-dio | openapi_freezed_dio_builder |
| **물리 엔진** | Forge2D (via flame_forge2d) | 커스텀 물리 (단순한 경우) |
| **게임 레이어** | Flame 1.29+ | Flutter 네이티브 (게임 루프 불필요 시) |
| **센서** | sensors_plus | motion_sensors |
| **CSPRNG** | Random.secure() + pointycastle | - |
| **햅틱** | HapticFeedback (내장) + haptic_feedback | gaimon (.ahap 필요 시) |
| **인증** | flutter_secure_storage + Dio 인터셉터 | - |
| **오프라인 동기화** | Workmanager + connectivity_plus | - |
| **테스팅** | flutter_test + Mocktail + integration_test | Mockito |
| **렌더링** | Impeller (기본) | - |
| **iOS 의존성** | CocoaPods (현재) → SPM (점진 전환) | - |
| **코드 생성** | build_runner + json_serializable + freezed | - |

### R4. flutter-expert 에이전트 AI 규칙

Flutter 공식 AI 규칙(rules.md)을 에이전트 지식에 반드시 포함:
- 다운로드: https://raw.githubusercontent.com/flutter/flutter/refs/heads/main/docs/rules/rules.md
- CLAUDE.md 또는 에이전트 프롬프트에 통합
- PRD 특화 규칙 추가: CSPRNG 보안 가이드라인, Forge2D 물리 파라미터 가이드라인

---

## References

### Flutter 공식 문서
- [Flutter AI Best Practices](https://docs.flutter.dev/ai/best-practices)
- [Flutter AI Rules](https://docs.flutter.dev/ai/ai-rules)
- [Flutter Official AI Rules (rules.md)](https://raw.githubusercontent.com/flutter/flutter/refs/heads/main/docs/rules/rules.md)
- [Flutter Offline-First Architecture](https://docs.flutter.dev/app-architecture/design-patterns/offline-first)
- [Flutter Platform Channels](https://docs.flutter.dev/platform-integration/platform-channels)
- [Flutter Testing Overview](https://docs.flutter.dev/testing/overview)
- [Flutter Concurrency and Isolates](https://docs.flutter.dev/perf/isolates)
- [Impeller Rendering Engine](https://docs.flutter.dev/perf/impeller)
- [Flutter Swift Package Manager](https://docs.flutter.dev/packages-and-plugins/swift-package-manager)
- [Flutter Casual Games Toolkit](https://flutter.dev/games)

### 패키지 / 라이브러리
- [Flame Engine (v1.29+)](https://pub.dev/packages/flame) — [GitHub](https://github.com/flame-engine/flame)
- [Forge2D](https://pub.dev/packages/forge2d) — [Flame Bridge](https://docs.flame-engine.org/latest/bridge_packages/flame_forge2d/forge2d.html)
- [sensors_plus](https://pub.dev/packages/sensors_plus)
- [pointycastle](https://pub.dev/packages/pointycastle) — [FortunaRandom](https://pub.dev/documentation/pointycastle/latest/impl.secure_random.fortuna_random/FortunaRandom-class.html)
- [Drift (SQLite)](https://pub.dev/packages/drift)
- [Hive](https://pub.dev/packages/hive)
- [Riverpod 3.0](https://pub.dev/packages/flutter_riverpod) — [What's New](https://riverpod.dev/docs/whats_new)
- [Dio](https://pub.dev/packages/dio) + [Retrofit](https://pub.dev/packages/retrofit)
- [openapi-generator dart-dio](https://openapi-generator.tech/docs/generators/dart-dio/)
- [openapi_generator (Dart)](https://pub.dev/packages/openapi_generator)
- [HapticFeedback (Flutter SDK)](https://api.flutter.dev/flutter/services/HapticFeedback-class.html)
- [haptic_feedback](https://pub.dev/packages/haptic_feedback) / [gaimon](https://pub.dev/packages/gaimon)
- [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage)
- [connectivity_plus](https://pub.dev/packages/connectivity_plus)
- [Workmanager](https://pub.dev/packages/workmanager)

### 보안 연구
- [Dart/Flutter CSPRNG Vulnerabilities (Zellic)](https://www.zellic.io/blog/proton-dart-flutter-csprng-prng/)

### 생태계 동향
- [Riverpod vs Bloc 2026](https://foresightmobile.com/blog/best-flutter-state-management)
- [Hive vs Drift vs Floor vs Isar 2025](https://quashbugs.com/blog/hive-vs-drift-vs-floor-vs-isar-2025)
- [Impeller in 2026](https://dev.to/eira-wexford/how-impeller-is-transforming-flutter-ui-rendering-in-2026-3dpd)
- [Flutter 3.38 & Dart 3.10](https://foresightmobile.com/blog/flutter-3-38-dart-3-10-november-2025-update)
- [Make Games with Flutter 2025](https://dev.to/krlz/make-games-with-flutter-in-2025-flame-engine-tools-and-free-assets-1n6)
- [Flame Klondike Card Game Tutorial](https://docs.flame-engine.org/latest/tutorials/klondike/step5.html)

### Rails OpenAPI 생성
- [rswag](https://github.com/rswag/rswag)
- [rspec-openapi](https://github.com/exoego/rspec-openapi)
- [RSwag OpenAPI Guide (Speakeasy)](https://www.speakeasy.com/openapi/frameworks/rails)

### AI 에이전트 패턴
- [Flutter AI Rules](https://docs.flutter.dev/ai/ai-rules)
- [Create with AI (Flutter)](https://docs.flutter.dev/ai/create-with-ai)
- [Riverpod 3.0 Release](https://codewithandrea.com/newsletter/september-2025/)
- [Flutter Design Patterns: Strategy](https://kazlauskas.dev/blog/flutter-design-patterns-5-strategy/)
