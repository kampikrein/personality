---
id: "004"
type: agent
title: "네이티브 API 접근 + 개발 인프라 — 플랫폼 비교"
created: 2026-03-19
perspective: "네이티브 API 접근 + 개발 인프라"
agent: "general-purpose"
summary: >
  Flutter vs 네이티브 플랫폼의 네이티브 API 접근성 및 개발 인프라(센서, 파일, 빌드 도구) 비교 분석.
---

# 네이티브 API 접근 + 개발 인프라 — 플랫폼 비교

## 현재 Flutter 기준선

personality 타로 앱의 Flutter 스택은 다음 조합으로 구성되어 있다:

| 구성요소 | 라이브러리 | 핵심 특성 |
|---------|-----------|----------|
| 센서 | sensors_plus v5.0 | gameInterval (~20ms) 샘플링, 로우패스 필터(alpha=0.20), iOS/Android 통합 추상화 |
| 햅틱 | HapticFeedback (Flutter 내장) | selection/light/medium impact, 50ms 쓰로틀링, 크로스플랫폼 단일 API |
| 로컬 DB | Drift v2.22 | SQLite ORM, 코드 생성 DAO, 타입 안전 쿼리, 스키마 마이그레이션, 4개 테이블 |
| 상태관리 | Riverpod v2.6 | 컴파일 타임 안전, 코드 생성, 의존성 자동 추적, Provider 조합 |
| 데이터 모델 | Freezed v2.5 | 불변 데이터 클래스, union type, JSON 직렬화, copyWith 자동 생성 |
| 라우팅 | GoRouter v14.6 | 선언형 라우팅, 타입 안전 파라미터, 딥링크 |

**Flutter 조합의 강점**: 단일 코드베이스에서 센서-햅틱-DB-상태관리-데이터 모델이 모두 코드 생성 기반으로 타입 안전하게 연결된다. 특히 Drift+Riverpod+Freezed의 조합은 오프라인-퍼스트 아키텍처에서 DB 변경 -> 상태 반영 -> UI 갱신의 반응형 파이프라인을 컴파일 타임에 검증 가능하게 만든다.

---

## 플랫폼별 조사 결과

### 1. React Native (JavaScript/TypeScript)

#### 센서 API

**주요 라이브러리**:
- **expo-sensors** (Expo 공식): `Accelerometer`, `Gyroscope`, `Magnetometer`, `Pedometer` 등 제공
- **react-native-sensors** (커뮤니티): RxJS 기반 반응형 API, accelerometer/gyroscope/magnetometer/barometer

**샘플링 레이트 제어**:
- `Accelerometer.setUpdateInterval(ms)` — 밀리초 단위로 직접 지정 가능
- 20ms(gameInterval 동급) 설정 가능하나, **Android 12+(API 31) 제한**: 기본 200ms 제한, `HIGH_SAMPLING_RATE_SENSORS` 퍼미션 추가 시 해제
- 인터벌 설정은 **글로벌** — 마지막으로 렌더된 컴포넌트의 설정이 전체에 적용

**에뮬레이터 동작**:
- iOS 시뮬레이터: 센서 데이터 없음 (실기기 필요)
- Android 에뮬레이터: Extended Controls에서 가속도계/자이로 시뮬레이션 가능

**성숙도**: expo-sensors는 Expo 생태계의 핵심 패키지로 안정적. react-native-sensors는 유지보수 빈도 낮음.

#### 햅틱 피드백

**주요 라이브러리**:
- **expo-haptics**: `impactAsync(style)`, `notificationAsync(type)`, `selectionAsync()` — 3가지 카테고리 제공
- **react-native-haptic-feedback**: selection, impactLight/Medium/Heavy, notificationSuccess/Warning/Error — Flutter HapticFeedback과 거의 1:1 대응
- **react-native-haptics**: 경량 대안, Android 특화 진동 효과 지원

**세밀도**: iOS UIFeedbackGenerator 수준의 세밀도 완전 지원. Android도 VibrationEffect API 매핑.

**크로스플랫폼 추상화**: expo-haptics와 react-native-haptic-feedback 모두 단일 API로 iOS/Android 차이 처리. Flutter HapticFeedback과 동급.

#### 로컬 DB / 오프라인-퍼스트

**주요 옵션**:
- **Drizzle ORM** (2025~2026 부상): TypeScript 네이티브 ORM, 타입 안전 쿼리, 마이그레이션 도구 내장, Expo SQLite와 통합. GitHub 25,000+ 스타, v1.0 베타 2025 초 출시.
- **WatermelonDB**: SQLite 기반 반응형 DB, React Native 최적화, 별도 네이티브 스레드에서 쿼리 실행, 동기화 프로토콜 내장
- **TypeORM**: TypeScript-first ORM, SQLite 지원, 데코레이터 기반 엔티티 정의, 마이그레이션 지원
- **PowerSync**: Drizzle ORM 통합 드라이버 (2025.09 알파), 오프라인-퍼스트 동기화

**Drift 동급 비교**: Drizzle ORM이 가장 가까움 — 타입 안전 쿼리, 스키마 기반 마이그레이션, 코드 생성. 단, Drift의 DAO 코드 자동 생성 수준에는 못 미침 (Drizzle은 스키마 정의 후 직접 쿼리 작성). WatermelonDB는 반응형 패턴이 강력하나 타입 안전성은 Drift보다 약함.

#### 상태관리

**주요 옵션 (2025~2026 기준)**:
- **Zustand** (~1KB): 최소 보일러플레이트, 셀렉터 기반 리렌더 방지, 가장 인기 있는 선택
- **Jotai** (~2.5KB): 원자적 상태, Recoil 영감, 복잡한 상태 의존성에 강점
- **Redux Toolkit** (~15KB): 엔터프라이즈 표준, 미들웨어, DevTools 지원
- **TanStack Query**: 서버 상태 전용 (클라이언트 상태와 분리하는 것이 2025 표준)

**Riverpod 동급 비교**: Jotai가 Riverpod의 원자적/반응형 모델에 가장 가까움. 그러나 Riverpod의 **컴파일 타임 안전성**에 대응하는 것은 없음 — TypeScript의 타입 추론이 런타임 안전성을 제공하지만 코드 생성 기반 검증은 아님.

**게임 루프 통합**: React Native의 JS 스레드는 게임 루프와 분리되어 있어, 고빈도 상태 업데이트(20ms 센서 데이터)에서 브릿지 오버헤드 발생. Reanimated + Worklets으로 UI 스레드 직접 접근 가능하나 아키텍처 복잡도 증가.

#### 코드 생성 / 타입 안전성

**Freezed 동급**:
- TypeScript의 `readonly` + `as const` — 불변성은 언어 레벨에서 지원하나 copyWith 자동 생성 없음
- **Zod**: 스키마 정의 -> TypeScript 타입 자동 추론, JSON 검증, 하지만 런타임 라이브러리 (컴파일 타임 코드 생성 아님)
- **io-ts** / **Effect Schema**: 타입 안전 인코딩/디코딩
- Union type: TypeScript discriminated union으로 자연스럽게 지원 (`type Card = TarotCard | OracleCard`)

**한계**: Freezed의 `copyWith`, `==` 자동 생성, JSON 직렬화 코드 생성을 한 패키지에서 해결하는 동등물이 없음. 여러 라이브러리 조합 필요.

---

### 2. Kotlin Multiplatform (KMP)

#### 센서 API

**접근 방법**: `expect`/`actual` 패턴으로 플랫폼별 구현 분리
- Android: `SensorManager` + `SENSOR_DELAY_GAME` (20ms)
- iOS: `CMMotionManager` + `accelerometerUpdateInterval` (초 단위, 0.02 = 20ms)
- 공통 코드: `SharedFlow<SensorData>` 기반 반응형 스트림

**커뮤니티 라이브러리**:
- **sensor-accelerometer-multiplatform** (GitHub): KMP용 가속도계 라이브러리, Flow 기반
- **basic-sensor** 등 소규모 라이브러리 존재하나 성숙도 낮음

**샘플링 레이트 제어**: 각 플랫폼 네이티브 API를 직접 사용하므로 **완전 제어 가능**
- Android: `SENSOR_DELAY_GAME` = 20,000us (20ms), 또는 커스텀 값 직접 지정
- iOS: `CMMotionManager.accelerometerUpdateInterval = 0.02` (20ms), 최대 100Hz(CMMotionManager) / 800Hz(CMBatchedSensorManager, iOS 17+)

**에뮬레이터 동작**:
- Android: 에뮬레이터 Extended Controls에서 시뮬레이션 가능. OI Sensor Simulator로 추가 시뮬레이션.
- iOS: 시뮬레이터에서 센서 사용 불가, 실기기 필요

**성숙도**: 통합 크로스플랫폼 센서 라이브러리는 미성숙. 각 플랫폼 네이티브 API가 매우 성숙하므로, expect/actual 패턴으로 직접 구현이 표준 접근법.

#### 햅틱 피드백

**접근 방법**: expect/actual 패턴으로 플랫폼별 구현
- Android: `HapticFeedbackConstants` / `VibrationEffect`
- iOS: `UIImpactFeedbackGenerator`, `UISelectionFeedbackGenerator`

**커뮤니티 라이브러리**:
- **multihaptic**: KMP 햅틱 라이브러리, Compose Multiplatform 지원, 사전정의 효과 + 커스텀 효과, 플랫폼별 DSL
- **basic-haptic**: CLICK/TICK 2가지 기본 모드로 단순화

**세밀도**: 네이티브 API 직접 접근이므로 **최대 세밀도** 확보 가능. selection click, light/medium/heavy impact 모두 구현 가능.

**크로스플랫폼 추상화**: multihaptic이 가장 포괄적이나 Flutter HapticFeedback보다 생태계 규모 작음. 직접 구현 시 30~50줄 수준의 expect/actual 코드.

#### 로컬 DB / 오프라인-퍼스트

**주요 옵션**:
- **SQLDelight**: SQL-first 접근, SQL 파일에서 Kotlin 코드 자동 생성, KMP 공식 지원, 타입 안전, 마이그레이션 내장
- **Room KMP** (v2.7.0+, 2025.05 출시): Google Jetpack 공식, 어노테이션 기반 DAO 코드 생성, KMP 지원 추가
- **Realm Kotlin SDK**: 객체지향 DB, KMP 지원, 동기화 내장 (MongoDB Atlas)

**Drift 동급 비교**: **SQLDelight가 가장 가까움** — SQL 기반 코드 생성, 타입 안전 쿼리, 마이그레이션 지원. Room KMP는 Drift의 DAO 패턴과 유사한 어노테이션 기반 접근. 두 옵션 모두 Drift 수준의 타입 안전성 제공.

**장점**: Kotlin 네이티브 라이브러리이므로 KMP에서 완벽 통합. SQLDelight는 Drift보다 오래된 만큼 생태계가 더 넓음.

#### 상태관리

**주요 패턴**:
- **MVIKotlin** (Arkadii Ivanov): Model-View-Intent 패턴, KMP 공식 지원, 타임 트래블 디버깅, Decompose와 호환
- **Decompose** (같은 저자): 네비게이션 + 상태관리 통합, 라이프사이클 인식
- **FlowMVI**: 플러그인 기반 MVI 프레임워크
- **Orbit MVI**: 간결한 MVI 프레임워크

**Riverpod 동급 비교**: MVIKotlin + Decompose 조합이 Riverpod+GoRouter에 대응. 단방향 데이터 플로(Intent -> ViewModel -> State -> UI)로 컴파일 타임 안전성 확보. Kotlin의 타입 시스템이 강력하므로 Riverpod 수준의 안전성 달성 가능.

**게임 루프 통합**: Kotlin 코루틴 + Flow로 게임 루프와 자연스러운 통합. 센서 데이터 Flow -> 상태 변환 -> UI 갱신 파이프라인이 깔끔함.

#### 코드 생성 / 타입 안전성

**Freezed 동급**:
- Kotlin `data class` — **언어 레벨**에서 불변성, `copy()`, `equals()`/`hashCode()`, destructuring 기본 제공. Freezed가 해결하는 문제의 80%를 언어 자체가 해결.
- `sealed class` / `sealed interface` — union type을 언어 레벨에서 지원, `when` 표현식으로 exhaustive 패턴 매칭
- **kotlinx.serialization** — 컴파일러 플러그인 기반 직렬화 코드 생성, 리플렉션 불필요, KMP 완전 지원

**강점**: Freezed + json_serializable이 하는 일을 **Kotlin 표준 기능 + kotlinx.serialization**으로 추가 라이브러리 없이 달성. 코드 생성 의존성이 현저히 적음.

---

### 3. Native (Swift + Kotlin)

#### 센서 API

**iOS (Swift)**:
- **Core Motion** (`CMMotionManager`): 가속도계/자이로/자기계/기압계 통합
- `accelerometerUpdateInterval` = 0.02 (20ms) 직접 설정
- 최대 100Hz (CMMotionManager), 800Hz 가속도계 / 200Hz 디바이스 모션 (CMBatchedSensorManager, iOS 17+)
- 시뮬레이터에서 센서 시뮬레이션 불가

**Android (Kotlin)**:
- `SensorManager` + `registerListener(listener, sensor, SENSOR_DELAY_GAME)`
- `SENSOR_DELAY_GAME` = 20ms (20,000us)
- 커스텀 레이트: 마이크로초 단위 직접 지정 가능
- Android 12+: `HIGH_SAMPLING_RATE_SENSORS` 퍼미션 필요
- 에뮬레이터: Extended Controls에서 시뮬레이션 가능

**강점**: 최대 성능, 최대 제어력, 최신 OS API 즉시 접근. 단, 코드 공유 없음 — 2개 코드베이스 유지.

#### 햅틱 피드백

**iOS (Swift)**:
- `UIImpactFeedbackGenerator(style: .light/.medium/.heavy/.rigid/.soft)`
- `UISelectionFeedbackGenerator`
- `UINotificationFeedbackGenerator(type: .success/.warning/.error)`
- Core Haptics: 커스텀 햅틱 패턴 생성 (진폭, 주파수, 지속시간 세밀 제어)

**Android (Kotlin)**:
- `HapticFeedbackConstants`: KEYBOARD_TAP, LONG_PRESS, VIRTUAL_KEY 등
- `VibrationEffect.createOneShot(ms, amplitude)` (API 26+)
- `VibrationEffect.createPredefined(EFFECT_CLICK/TICK/HEAVY_CLICK/DOUBLE_CLICK)` (API 29+)

**세밀도**: **최대** — 모든 플랫폼별 햅틱 기능에 직접 접근. Core Haptics(iOS)로 커스텀 햅틱 시퀀스 생성 가능.

#### 로컬 DB / 오프라인-퍼스트

**iOS (Swift)**:
- **SwiftData** (iOS 17+): Apple 공식 ORM, Swift 매크로 기반 코드 생성, Core Data 후속
- **Core Data**: 레거시이지만 성숙, 마이그레이션 강력
- **GRDB.swift**: SQLite 직접 접근, Record 패턴, 타입 안전 쿼리

**Android (Kotlin)**:
- **Room**: Google 공식 ORM, 어노테이션 기반 DAO 코드 생성, 마이그레이션, Flow 통합
- **SQLDelight**: SQL-first, 코드 생성

**Drift 동급 비교**: Room(Android)과 SwiftData(iOS) 모두 Drift 수준 이상의 ORM 기능 제공. 단, 각 플랫폼별 별도 구현 필요.

#### 상태관리

**iOS (Swift)**:
- **SwiftUI @Observable** (iOS 17+): 매크로 기반 관찰 가능 객체, Observation 프레임워크
- **Combine**: 반응형 스트림 프레임워크
- **TCA (The Composable Architecture)**: 단방향 데이터 플로, 테스트 용이

**Android (Kotlin)**:
- **ViewModel + StateFlow**: Jetpack 공식 패턴
- **Jetpack Compose 상태**: `remember`, `mutableStateOf`, `derivedStateOf`

**컴파일 타임 안전성**: 양 플랫폼 모두 강타입 언어이므로 높음. 하지만 코드베이스가 2개.

#### 코드 생성 / 타입 안전성

**iOS (Swift)**:
- `struct` — 값 타입 + 불변성 기본
- `Codable` — JSON 직렬화 컴파일러 자동 합성
- `enum with associated values` — union type 네이티브 지원
- Swift Macros (5.9+): 커스텀 코드 생성

**Android (Kotlin)**:
- `data class`, `sealed class`, `kotlinx.serialization` — 위 KMP 섹션과 동일

**Freezed 동급**: 양 플랫폼 모두 **언어 수준에서 Freezed의 기능을 대부분 포함**. 추가 코드 생성 도구 불필요.

---

### 4. Unity (C#)

#### 센서 API

**접근 방법**:
- `Input.acceleration` — 가속도계 데이터 (레거시 Input System)
- `Gyroscope` 클래스 — `Input.gyro.enabled = true`로 활성화
- **New Input System** (권장): `Accelerometer.current`, `Gyroscope.current` 등 디바이스 기반 접근

**샘플링 레이트 제어**:
- `Gyroscope.current.samplingFrequency = 50` (Hz 단위)
- 기본 가속도계는 60Hz로 샘플링, CPU 부하 시 일정하지 않음
- 프레임 간 모든 측정값 접근 가능 (`InputSystem.EnableDevice`)

**에뮬레이터 동작**: 에뮬레이터/시뮬레이터 개념보다 Unity Remote(앱을 통한 실기기 미러링) 또는 빌드 후 실기기 테스트가 표준.

**성숙도**: Unity Input System은 게임 엔진의 핵심으로 **매우 성숙**. 센서 지원은 iOS/Android 모두 포함. 다만 모바일 앱(비게임) 맥락에서는 과도한 설정.

#### 햅틱 피드백

**기본 제공**: `Handheld.Vibrate()` — 단순 진동만 지원 (세밀도 없음)

**서드파티 플러그인**:
- **Nice Vibrations** (More Mountains): 9개 프리셋 (light/medium/heavy/rigid/soft/failure/success/selection/warning), Core Haptics(iOS) + VibrationEffect(Android) 래핑, 게임패드 럼블 지원. **가장 완성도 높은 옵션**.
- **Vibration Plugin** (BenoitFreslon): 오픈소스, Pop/Peek/Nope 패턴
- **CandyCoded HapticFeedback**: 오픈소스 경량 래퍼

**세밀도**: Nice Vibrations 사용 시 Flutter HapticFeedback 동급 이상. 기본 API만으로는 **매우 부족**.

#### 로컬 DB / 오프라인-퍼스트

**주요 옵션**:
- **SQLite-net**: ORM 래퍼, 멀티플랫폼 지원. 단, Unity 환경에서 플랫폼별 네이티브 라이브러리(DLL) 관리 필요.
- **PlayerPrefs**: 키-값 저장 (단순 설정용)
- **JSON 파일 직렬화**: `Application.persistentDataPath`에 JSON 저장 — 2024~2026 가벼운 프로젝트에서 권장

**Drift 동급 비교**: **동등물 없음**. SQLite-net이 가장 가깝지만, Drift의 코드 생성 DAO, 타입 안전 쿼리, 스키마 마이그레이션 수준에 크게 못 미침. Unity 생태계는 관계형 DB보다 JSON/ScriptableObject 기반 데이터 관리에 최적화.

**오프라인-퍼스트**: Unity는 기본적으로 로컬 실행이므로 "오프라인-퍼스트"가 기본값. 서버 동기화가 필요한 경우 직접 구현.

#### 상태관리

**Unity 고유 패턴**:
- **ECS (Entity Component System)**: Unity DOTS, 데이터 지향 설계, 고성능 게임 루프에 최적
- **ScriptableObject**: 데이터 컨테이너, 이벤트 시스템 구현 가능, 에디터 통합
- **MonoBehaviour 상태 패턴**: 전통적 게임 오브젝트 기반 상태 관리
- **UniRx** (커뮤니티): 반응형 프로그래밍 패턴

**Riverpod 동급 비교**: Unity의 상태관리는 **앱 아키텍처보다 게임 아키텍처** 패러다임. ECS는 성능은 극대화하지만 Riverpod의 선언적/반응형 패턴과는 철학이 다름. UniRx가 가장 가깝지만 생태계 규모 작음.

**게임 루프 통합**: **최강** — Unity 자체가 게임 엔진이므로 Update()/FixedUpdate() 루프, 물리 엔진, 렌더링 파이프라인이 통합.

#### 코드 생성 / 타입 안전성

**C# 언어 기능**:
- `record` 타입 (C# 9+): 불변 데이터 클래스, 값 기반 동등성, `with` 표현식 (copyWith 동급)
- `sealed` 클래스/인터페이스: 제한된 상속 계층
- **System.Text.Json** + Source Generator: 컴파일 타임 직렬화 코드 생성, 리플렉션 불필요
- **MemoryPack**: Unity 지원, JsonUtility 대비 3~10배 빠름, Source Generator 기반

**Freezed 동급**: C# `record` + System.Text.Json Source Generator로 Freezed의 핵심 기능 대부분 커버. **언어 수준 지원이 강력**.

**한계**: Unity의 C# 버전은 .NET 최신보다 늦게 따라오므로, 최신 C# 기능 사용에 제약이 있을 수 있음 (Unity 6에서 .NET 8/C# 12 지원 예정).

---

### 5. .NET MAUI / Uno Platform (C#)

#### 센서 API

**MAUI (Microsoft 공식)**:
- `Microsoft.Maui.Devices.Sensors` 네임스페이스 (구 Xamarin.Essentials)
- `IAccelerometer`, `IGyroscope` 인터페이스 + Default 프로퍼티
- `ReadingChanged` 이벤트로 데이터 수신

**샘플링 레이트 제어 (SensorSpeed enum)**:
| SensorSpeed | 인터벌 | 비고 |
|------------|--------|------|
| Default | 200ms | 일반 용도 |
| UI | 60ms | UI 반응 |
| **Game** | **20ms** | **Flutter gameInterval 동급** |
| Fastest | 5ms | 고정밀 센서 |

- .NET 8부터 인터벌이 **모든 플랫폼에서 동일** (이전에는 플랫폼별 차이 존재)
- Game/Fastest 속도의 이벤트 핸들러는 UI 스레드 보장 없음 — `MainThread.BeginInvokeOnMainThread()` 필요
- Fastest 사용 시 Android `HIGH_SAMPLING_RATE_SENSORS` 퍼미션 필요

**에뮬레이터 동작**: Android 에뮬레이터 Extended Controls 시뮬레이션 가능. iOS 시뮬레이터 미지원.

**Uno Platform**: MAUI Essentials API를 그대로 사용하거나, 플랫폼별 조건부 컴파일로 네이티브 접근.

**성숙도**: Xamarin.Essentials에서 진화한 API로 **매우 성숙**. Microsoft 공식 지원.

#### 햅틱 피드백

**MAUI API**:
- `HapticFeedback.Default.Perform(HapticFeedbackType.Click)` — 클릭 햅틱
- `HapticFeedback.Default.Perform(HapticFeedbackType.LongPress)` — 롱프레스 햅틱
- `Vibration.Default.Vibrate(TimeSpan)` — 커스텀 시간 진동
- .NET 10: `IsSupported` 프로퍼티 추가

**세밀도**: **Click과 LongPress 2가지만 제공** — Flutter의 selection/light/medium/heavy에 비해 **현저히 부족**. iOS UIFeedbackGenerator의 다양한 스타일에 접근하려면 플랫폼별 코드 필요.

**크로스플랫폼 추상화**: 기본 API는 단순하지만 세밀도 부족. 플랫폼별 핸들러로 확장 가능하나 추가 작업 필요.

#### 로컬 DB / 오프라인-퍼스트

**주요 옵션**:
- **Entity Framework Core + SQLite**: .NET 공식 ORM, LINQ 쿼리, 마이그레이션 자동 생성, 코드-퍼스트/DB-퍼스트 모두 지원
- **sqlite-net-pcl**: 경량 SQLite ORM, 어트리뷰트 기반 매핑
- **LiteDB**: NoSQL 임베디드 DB, BSON 기반
- **Realm .NET**: 객체지향 DB, 동기화 내장

**Drift 동급 비교**: **EF Core가 가장 가까움** — LINQ 기반 타입 안전 쿼리, 코드-퍼스트 마이그레이션, DbContext가 DAO 역할. Drift보다 더 성숙하고 강력한 마이그레이션 도구. 다만 Drift의 코드 생성 접근과 달리 리플렉션/Source Generator 혼합 사용.

**오프라인-퍼스트**: EF Core + SQLite로 완전한 오프라인-퍼스트 구현 가능. 동기화는 직접 구현 또는 Azure Mobile Apps SDK.

#### 상태관리

**주요 패턴**:
- **CommunityToolkit.MVVM**: Microsoft 공식 MVVM 툴킷, Source Generator로 보일러플레이트 제거
  - `ObservableObject`, `ObservableProperty`, `RelayCommand` 자동 생성
  - `INotifyPropertyChanged` / `INotifyDataErrorInfo` 지원
- **MVU (Model-View-Update)**: Comet 프레임워크 (실험적)
- **ReactiveUI**: Rx 기반 MVVM, 크로스플랫폼 반응형 프로그래밍

**Riverpod 동급 비교**: CommunityToolkit.MVVM이 가장 가까움 — Source Generator 기반 코드 생성, 자동 알림. 그러나 Riverpod의 Provider 의존성 자동 추적/무효화 패턴에 대한 직접 대응은 없음. DI 컨테이너(Microsoft.Extensions.DependencyInjection)와 조합하여 유사한 아키텍처 구성 가능.

**게임 루프 통합**: MAUI는 앱 프레임워크이므로 게임 루프 통합에 추가 작업 필요. `Dispatcher.CreateTimer()` 또는 SkiaSharp 커스텀 렌더링으로 구현 가능하나 Flutter/Unity 대비 불편.

#### 코드 생성 / 타입 안전성

**C# 언어 기능** (Unity와 동일하나 최신 버전 사용 가능):
- `record` 타입: 불변 데이터, 값 동등성, `with` 표현식
- `sealed` 클래스: 제한된 상속
- **System.Text.Json Source Generator**: 컴파일 타임 직렬화 코드 생성
- **.NET 10** XAML Source Generator: XAML 컴파일 타임 코드 생성 (시작 시간 개선)

**Freezed 동급**: C# `record` + System.Text.Json으로 Freezed 핵심 기능 커버. .NET 최신 버전이므로 C# 최신 기능 즉시 사용 가능 (Unity보다 유리).

---

## 비교 매트릭스

### A. 센서 API

| 항목 | Flutter | React Native | KMP | Native | Unity | MAUI |
|------|---------|-------------|-----|--------|-------|------|
| 가속도계/자이로 | sensors_plus | expo-sensors | expect/actual | CMMotion / SensorManager | Input System | Maui.Essentials |
| 20ms 샘플링 | O (gameInterval) | O (setUpdateInterval) | O (네이티브 직접) | O (네이티브 직접) | O (samplingFrequency) | O (SensorSpeed.Game) |
| 레이트 제어 단위 | enum (4단계) | ms (자유) | us/초 (자유) | us/초 (자유) | Hz (자유) | enum (4단계) |
| 크로스플랫폼 추상화 | 단일 API | 단일 API | 수동 (expect/actual) | 없음 (2 코드베이스) | 단일 API | 단일 API |
| 에뮬레이터 시뮬레이션 | Android O / iOS X | Android O / iOS X | Android O / iOS X | Android O / iOS X | Unity Remote | Android O / iOS X |
| 성숙도 | 높음 | 높음 (Expo) | 낮음 (커뮤니티) | 최고 | 높음 | 높음 |

### B. 햅틱 피드백

| 항목 | Flutter | React Native | KMP | Native | Unity | MAUI |
|------|---------|-------------|-----|--------|-------|------|
| API 세밀도 | 4단계 | 7단계+ | 네이티브 전체 | 최대 | 기본1 / 플러그인9+ | 2단계 |
| selection click | O | O | O | O | O (플러그인) | X (Click 근사) |
| light/medium/heavy | O | O | O | O | O (Nice Vibrations) | X |
| 커스텀 패턴 | X | X (제한적) | O (네이티브) | O (Core Haptics) | O (Nice Vibrations) | O (Vibration API) |
| 크로스플랫폼 추상화 | 단일 API | 단일 API | 수동 / multihaptic | 없음 | 플러그인 의존 | 단일 API (제한적) |

### C. 로컬 DB / 오프라인-퍼스트

| 항목 | Flutter (Drift) | RN (Drizzle) | KMP (SQLDelight) | Native (Room/SwiftData) | Unity (SQLite-net) | MAUI (EF Core) |
|------|----------------|-------------|-----------------|----------------------|-------------------|---------------|
| 코드 생성 DAO | O | 부분적 | O | O | X | Source Generator |
| 타입 안전 쿼리 | O | O | O | O | 부분적 | O (LINQ) |
| 스키마 마이그레이션 | O | O | O | O | 수동 | O (자동) |
| 반응형 쿼리 | O (Stream) | O (WatermelonDB) | O (Flow) | O (Flow/Combine) | X | O (INotify) |
| 오프라인-퍼스트 패턴 | O | O (WatermelonDB) | O | O | 기본값 | O |

### D. 상태관리

| 항목 | Flutter (Riverpod) | RN (Zustand/Jotai) | KMP (MVIKotlin) | Native | Unity (ECS) | MAUI (MVVM Toolkit) |
|------|-------------------|-------------------|----------------|--------|-------------|-------------------|
| 컴파일 타임 안전 | O (코드 생성) | 부분적 (TS) | O (Kotlin 타입) | O | O | O (Source Generator) |
| 반응형 패턴 | O (Provider) | O (Selector) | O (StateFlow) | O | 부분적 | O (INotifyPropertyChanged) |
| 코드 생성 | O | X | X | 부분적 | X | O |
| 게임 루프 통합 | 보통 | 약함 (JS 브릿지) | 좋음 (코루틴) | 최고 | 최고 (내장) | 약함 |
| 보일러플레이트 | 낮음 | 매우 낮음 (Zustand) | 보통 | 보통~높음 | 높음 (ECS) | 낮음 (Toolkit) |

### E. 코드 생성 / 타입 안전성

| 항목 | Flutter (Freezed) | RN (TS/Zod) | KMP (data class) | Native (struct/record) | Unity (record) | MAUI (record) |
|------|------------------|------------|-----------------|---------------------|---------------|--------------|
| 불변 데이터 클래스 | O (코드 생성) | 부분적 (readonly) | O (언어 내장) | O (언어 내장) | O (언어 내장) | O (언어 내장) |
| copyWith/with | O (자동 생성) | X (수동) | O (copy()) | O (with) | O (with) | O (with) |
| 값 동등성 | O (자동 생성) | X (수동) | O (자동) | O (자동) | O (자동) | O (자동) |
| union type | O (Freezed union) | O (TS discriminated) | O (sealed class) | O (enum/sealed) | O (sealed) | O (sealed) |
| JSON 코드 생성 | O (json_serializable) | 부분적 (Zod 런타임) | O (kotlinx.serialization) | O (Codable/kotlinx) | O (Source Generator) | O (Source Generator) |
| 추가 도구 필요 | build_runner 필수 | Zod 선택적 | 컴파일러 플러그인 | 없음 / 플러그인 | 없음 | 없음 |

---

## 핵심 발견

### 1. Flutter의 상대적 위치

Flutter의 sensors_plus + HapticFeedback + Drift + Riverpod + Freezed 조합은 **단일 프레임워크에서 모든 요구사항을 코드 생성 기반으로 통합하는 유일한 스택**이다. 다른 플랫폼은 개별 영역에서 Flutter를 능가하지만, 전체 통합 비용에서 Flutter가 유리하다.

### 2. 센서 API — 모든 플랫폼이 20ms 가능

5개 플랫폼 모두 gameInterval(20ms) 샘플링을 지원한다. 차이는 제어 세밀도:
- **가장 유연**: Native(직접 마이크로초/초 단위) > KMP(네이티브 직접) > RN(밀리초) > Unity(Hz)
- **가장 간편**: Flutter(enum) = MAUI(enum) — 4단계 프리셋으로 단순화
- **Android 12+ 제한**: 모든 크로스플랫폼(Flutter/RN/MAUI)에서 동일하게 퍼미션 추가 필요

### 3. 햅틱 피드백 — MAUI가 약점, Native가 최강

- **MAUI의 Click/LongPress 2단계**는 타로 앱의 selection/light/medium 요구에 부족. 플랫폼별 핸들러 직접 구현 필수.
- **React Native(react-native-haptic-feedback)**이 Flutter HapticFeedback과 가장 유사한 API 세밀도 제공.
- **Native(Core Haptics)**만이 커스텀 햅틱 시퀀스(진폭+주파수+지속시간 조합)를 완전 지원.

### 4. 로컬 DB — KMP(SQLDelight/Room)와 MAUI(EF Core)가 강력

- **SQLDelight**(KMP)와 **EF Core**(MAUI)는 Drift와 동급 이상의 타입 안전 ORM 제공.
- **Drizzle ORM**(RN)이 2025~2026 급부상하며 Drift에 가장 가까운 TypeScript 대안이 됨.
- **Unity**는 관계형 DB 지원이 가장 약함 — JSON 직렬화 기반 접근이 주류.

### 5. 상태관리 — Riverpod의 "컴파일 타임 의존성 추적"은 고유 강점

- Riverpod의 Provider 의존성 자동 추적 + 무효화 + 코드 생성 조합은 다른 플랫폼에 직접 대응물이 없음.
- **Zustand/Jotai**(RN)는 간결하지만 컴파일 타임 안전성 없음.
- **MVIKotlin**(KMP)는 아키텍처적으로 견고하나 Riverpod만큼 자동화되지 않음.
- **게임 루프 통합**: Unity > Native > KMP > Flutter > MAUI > RN 순서.

### 6. 코드 생성 / 타입 안전성 — Kotlin/Swift가 언어 수준에서 Freezed를 대체

- Kotlin `data class` + `sealed class` + `kotlinx.serialization`은 Freezed가 해결하는 문제를 **추가 라이브러리 없이** 해결.
- C# `record` + System.Text.Json Source Generator도 마찬가지.
- Flutter/Dart는 언어 수준 지원이 상대적으로 약해 Freezed + build_runner에 의존 — 빌드 시간 비용이 있음.
- **React Native(TypeScript)**은 런타임 타입 안전만 제공, 컴파일 타임 코드 생성이 가장 약함.

### 7. 종합 우선순위

타로 앱의 기술 요구사항(센서 + 햅틱 + 오프라인 DB + 반응형 상태 + 타입 안전성) 기준:

1. **Flutter (현행)**: 통합 완성도 최고. 각 영역 "충분히 좋은" 수준에서 마찰 없이 연결됨.
2. **KMP**: 센서/햅틱 네이티브 직접 접근 + SQLDelight/Room + Kotlin 타입 시스템. 개별 영역에서 Flutter보다 강하나 통합 비용 높음.
3. **Native (Swift+Kotlin)**: 모든 API 최대 접근. 2배 코드베이스 유지 비용.
4. **React Native**: 센서/햅틱/DB 모두 가능하나 JS 브릿지 오버헤드와 타입 안전성 한계. 게임 루프 통합 최약.
5. **MAUI**: 센서/DB 강력하나 햅틱 세밀도 부족, 게임 루프 통합 약함. 모바일 생태계 규모 작음.
6. **Unity**: 게임 루프/센서 최강이나 앱 인프라(DB, 상태관리, 라우팅) 극도로 약함. 타로 "앱"보다 타로 "게임"에 적합.

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
