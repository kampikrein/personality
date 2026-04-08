---
id: "005"
type: agent
title: "전환 비용 + 생태계 건강성 — 플랫폼 비교"
created: 2026-03-19
perspective: "전환 비용 + 생태계 건강성"
agent: "general-purpose"
summary: >
  Flutter에서 다른 플랫폼으로의 전환 비용 산정 및 각 생태계 건강성·장기 지속 가능성 비교.
---

# 전환 비용 + 생태계 건강성 — 플랫폼 비교

## 현재 Flutter 기준선

| 항목 | 수치 |
|------|------|
| 비생성 .dart 파일 수 | 57개 |
| 총 LOC (비생성) | ~3,380줄 |
| 핵심 게임 엔진 (Flame/Forge2D) | ~419줄 (5개 파일) |
| 셔플 프레젠테이션 전체 | ~1,060줄 |
| 도메인 로직 (deck/reading/shuffle) | ~343줄 |
| 데이터 레이어 (DB/repository) | ~695줄 |
| UI/위젯 | ~814줄 |
| 인프라 (라우터/테마/에러/DevTuner) | ~426줄 |

**아키텍처 특성**:
- Feature-based 구조: deck, shuffle, reading, home 4개 feature
- Clean Architecture: domain → data → presentation 레이어 분리
- 상태관리: Riverpod + Freezed (코드 생성)
- 게임 엔진: Flame 1.19 + Forge2D (Box2D 물리) + Rive 애니메이션
- 로컬 DB: Drift (SQLite)
- 센서: sensors_plus (가속도계 → 엔트로피 수집)
- 핵심 차별점: 촉각적 카드 셔플 — 물리 시뮬레이션 + 센서 기반 중력 + 햅틱 피드백

**코드 레이어별 이식성 분류**:
- **이식 가능 (도메인 로직)**: ~343줄 — Fisher-Yates 셔플, 엔트로피 풀, 카드/덱/리딩 엔티티. 알고리즘/비즈니스 로직은 언어 무관하게 재구현 용이
- **부분 이식 (데이터 레이어)**: ~695줄 — DB 스키마와 리포지토리 패턴은 재활용 가능하나, Drift 특화 코드는 재작성 필요
- **완전 재작성 (게임 엔진 + UI)**: ~2,342줄 — Flame/Forge2D 컴포넌트, Rive 애니메이션, Flutter 위젯 전체. 타겟 플랫폼의 네이티브 도구로 재구현 필수

---

## 플랫폼별 조사 결과

### 1. React Native

#### 이식 난이도

**재사용 가능**: 도메인 로직의 알고리즘적 부분 (Fisher-Yates, 엔트로피 수집 로직)은 JS/TS로 직접 번역 가능. Clean Architecture 패턴과 DB 스키마도 개념적으로 재활용 가능.

**완전 재작성 필요**:
- **게임 엔진 레이어 (~1,060줄)**: Flame/Forge2D → React Native Game Engine + Matter.js 또는 React Native Skia로 전면 재작성. Matter.js는 2D 물리 엔진이지만 Forge2D(Box2D)와 API가 완전히 다르며, ECS(Entity-Component-System) 패턴으로의 구조 변환 필요
- **Rive 애니메이션**: React Native용 Rive 런타임 존재하나, Flame 통합 방식과 다르므로 애니메이션 컨트롤러 재작성 필요
- **센서 + 햅틱**: react-native-sensors + react-native-haptic-feedback으로 대체 가능하나 통합 코드 재작성
- **UI 전체**: Flutter 위젯 → React Native 컴포넌트로 완전 재작성

**예상 재작성 규모**: 전체 코드의 ~85-90% 재작성. 약 **3-4 인-월** (1인 기준). Dart → JS/TS 변환 + 게임 엔진 재구축이 핵심 병목.

**단계적 마이그레이션**: 불가능. Flutter와 React Native는 렌더링 엔진이 완전히 다르므로 빅뱅 재작성만 가능. 다만, feature 단위로 순차 구현은 가능 (deck → shuffle → reading 순).

#### 코드 공유율

iOS/Android 간 **~95% 코드 공유** 가능. React Native New Architecture(Fabric + JSI) 기반으로 브릿지 없이 네이티브 모듈 직접 호출 가능. 플랫폼별 코드는 햅틱/센서 네이티브 모듈 정도.

#### 커뮤니티/생태계

| 지표 | 수치 |
|------|------|
| GitHub Stars | ~121K (react-native repo) |
| npm 패키지 | 수십만 개 (JS 생태계 전체 활용) |
| Stack Overflow 태그 | 활발 (JS 생태계 최대) |
| 공식 후원 | Meta (Facebook) |
| 주요 사용 기업 | Instagram, Facebook, Shopify, Discord, Coinbase |

**패키지 생태계**: JS/npm 생태계를 그대로 활용할 수 있어 양적으로 압도적. 다만 게임/물리 엔진 영역은 Flutter의 Flame 대비 성숙도가 낮음. React Native Game Engine (GitHub ~3.5K stars)은 Flame (~9K stars) 대비 커뮤니티 규모가 작음.

**2025-2026 동향**: New Architecture(Fabric + TurboModules + JSI)가 0.76부터 기본 활성화. React Native Skia가 GPU 가속 2D 렌더링을 제공하며 게임/커스텀 UI 영역을 강화 중. Expo SDK 55+ 와의 통합으로 개발 경험 크게 개선.

#### 인력 시장 (한국)

| 지표 | 수치 |
|------|------|
| 잡코리아 채용공고 | ~157건 ('react native') |
| LinkedIn 채용공고 | ~8건 |
| 신입 평균 연봉 | ~3,500만원 (프론트엔드 기준) |
| 프리랜서 가용성 | 높음 (JS 개발자 풀 활용) |

**채용 난이도**: Flutter 대비 약간 쉬움. JS/TS 개발자 풀이 훨씬 크므로 전환 교육 비용이 낮음. 웹 프론트엔드 개발자가 RN으로 전환하는 경로가 잘 확립됨.

**학습 곡선**: 기존 웹 개발자(React 경험) 기준 **1-2주**면 생산성 확보. Dart 경험 없는 개발자가 Flutter를 배우는 것(4-6주)보다 진입 장벽이 낮음.

#### 장기 전망

- **Meta 투자**: Instagram, Facebook 등 자사 앱에 적극 활용 중. New Architecture 완성으로 성능 격차 대폭 줄임
- **중단 리스크**: 낮음. Meta의 핵심 모바일 전략이며, Expo 등 서드파티 생태계도 독립적으로 성장 중
- **주요 동향**: React Native 0.83 + Expo SDK 55, React 19.2 통합, Hermes 엔진 고도화
- **대기업 채택**: Shopify, Microsoft (일부 앱), Bloomberg, Wix

#### 앱 특성 적합도

**적합도: 중하 (5/10)**

이 앱의 핵심은 "촉각적 카드 셔플"이라는 게임 엔진 레이어. React Native는 일반 앱 UI에 강하지만, 실시간 물리 시뮬레이션 + 60fps 게임 루프는 약점. React Native Game Engine + Matter.js 조합은 가능하나, Flame + Forge2D 대비 생태계 성숙도와 커뮤니티 지원이 부족. 단, React Native Skia가 2026년에 상당히 성숙해져 커스텀 렌더링 영역이 개선되고 있음.

---

### 2. Kotlin Multiplatform (KMP)

#### 이식 난이도

**재사용 가능**: Dart와 Kotlin은 문법적 유사성이 높아(null safety, 확장 함수, 코루틴/Future 등) 도메인 로직 이식이 비교적 수월. Clean Architecture 패턴은 거의 1:1 대응. Riverpod → Koin/Hilt, Freezed → data class, Drift → SQLDelight/Room으로 매핑.

**완전 재작성 필요**:
- **게임 엔진 레이어**: Flame/Forge2D → KorGE, Kubriko, 또는 LibGDX(KTX) + Box2D 직접 통합. KorGE는 KMP 네이티브 게임 엔진이나, Flame 대비 생태계 규모가 작음
- **UI 전체**: Flutter 위젯 → Compose Multiplatform (JetBrains)으로 재작성. Compose Multiplatform for iOS는 2025년 5월 stable 도달
- **Rive 애니메이션**: Android/iOS 각각 네이티브 Rive SDK 사용 (KMP 공유 불가, 플랫폼별 expect/actual 패턴)
- **센서/햅틱**: KMP expect/actual 패턴으로 플랫폼별 구현

**예상 재작성 규모**: 전체 코드의 ~80-85% 재작성. 약 **4-5 인-월**. 게임 엔진 생태계의 미성숙이 추가 리스크. Compose Multiplatform iOS의 stable은 최근이라 엣지 케이스 존재 가능.

**단계적 마이그레이션**: **부분적으로 가능**. KMP의 강점은 공유 로직부터 점진적 도입 가능하다는 점. 그러나 이 앱은 Flutter 위젯과 Flame 엔진이 밀접하게 결합되어 있어, 실질적으로는 빅뱅에 가까움. Compose Multiplatform + 게임 엔진을 동시에 구축해야 하므로.

#### 코드 공유율

- **비즈니스 로직**: ~90-95% 공유 (KMP shared 모듈)
- **UI (Compose Multiplatform)**: ~85-90% 공유 (iOS stable 이후)
- **게임 엔진**: KorGE 사용 시 ~80% 공유, 플랫폼별 렌더러 차이로 일부 분기
- **센서/햅틱**: 인터페이스만 공유, 구현은 플랫폼별 (expect/actual)
- **종합**: ~80-85% 코드 공유 예상

#### 커뮤니티/생태계

| 지표 | 수치 |
|------|------|
| GitHub Stars | Kotlin ~50K, Compose Multiplatform ~18K |
| Maven Central 패키지 | Kotlin 생태계 전체 활용 (Java 호환) |
| Stack Overflow 태그 | 성장 중 (KMP 전용은 아직 작음) |
| 공식 후원 | JetBrains (Kotlin), Google (Android 공식 언어) |
| 주요 사용 기업 | Netflix, McDonald's, Duolingo, Google Docs iOS, AWS SDK |

**패키지 생태계**: Java/Kotlin 전체 생태계 (Maven Central)를 활용 가능하나, KMP-specific 라이브러리는 아직 성장 중. 게임 엔진 영역(KorGE ~2K stars, Kubriko ~신규)은 Flame 대비 현저히 작음.

**핵심 수치**:
- KMP 채택률: 2024년 7% → 2025년 18-23%로 급성장
- Compose Multiplatform for iOS: 2025년 5월 stable (96% 팀이 성능 이슈 없음 보고)
- K2 컴파일러: 40%+ 빌드 속도 향상
- Meta가 Kotlin Foundation Gold Member 가입

#### 인력 시장 (한국)

| 지표 | 수치 |
|------|------|
| 잡코리아 채용공고 (Kotlin) | ~500건+ (Android 포함) |
| KMP 전용 채용공고 | 극소수 (~5-10건 추정) |
| 신입 평균 연봉 | ~3,570만원 (Android 기준) |
| 프리랜서 가용성 | 중간 (Android Kotlin은 풍부, KMP 경험자는 희소) |

**채용 난이도**: Android Kotlin 개발자는 풍부하나, KMP + Compose Multiplatform 경험자는 한국에서 매우 희소. 채용보다는 기존 Android 개발자의 KMP 전환 교육이 현실적.

**학습 곡선**: Android Kotlin 개발자 기준 **2-4주** (KMP 개념 + Compose Multiplatform). iOS 경험이 없는 경우 플랫폼별 네이티브 코드(expect/actual) 작성에 추가 학습 필요.

#### 장기 전망

- **JetBrains + Google 투자**: Kotlin은 Android 공식 언어이며, JetBrains가 Compose Multiplatform에 집중 투자 중
- **중단 리스크**: 매우 낮음. Google(Android)과 JetBrains(IDE + 언어) 양사가 핵심 전략으로 추진
- **주요 동향**: Compose Multiplatform iOS stable (2025.05), K2 컴파일러 GA, Fleet IDE KMP 지원
- **대기업 채택**: Netflix (개발 시간 40% 단축), McDonald's (월 650만 주문), Duolingo (4000만+ 사용자), Airbnb (95% 코드 공유)

#### 앱 특성 적합도

**적합도: 중 (6/10)**

KMP의 강점은 공유 비즈니스 로직이지만, 이 앱의 핵심은 게임 엔진 레이어. KorGE/Kubriko 등 KMP 게임 엔진은 존재하나 Flame + Forge2D 대비 성숙도가 크게 떨어짐. 물리 시뮬레이션 + 센서 통합 + 햅틱이라는 조합을 KMP 생태계에서 구현하려면 상당한 자체 개발이 필요. 다만, Android 네이티브 게임 개발 경험을 직접 활용할 수 있다는 점은 장점.

---

### 3. Native (Swift + Kotlin)

#### 이식 난이도

**재사용 가능**: 도메인 로직의 알고리즘만 각 언어로 번역. Clean Architecture 패턴은 양 플랫폼 모두에서 널리 사용됨.

**완전 재작성 필요 (x2)**:
- **iOS**: Swift + SpriteKit(2D 게임 엔진, Apple 공식) + GameplayKit(물리) + Core Haptics(햅틱) + Core Motion(센서). SpriteKit은 Box2D 기반 물리 엔진 내장
- **Android**: Kotlin + LibGDX 또는 자체 Canvas/OpenGL 기반 게임 루프 + Box2D 직접 통합 + Vibrator API + SensorManager
- **UI**: SwiftUI / Jetpack Compose 각각 작성
- **DB**: Core Data / Room 각각 작성
- **Rive 애니메이션**: 각 플랫폼 네이티브 Rive SDK (잘 지원됨)

**예상 재작성 규모**: 두 개의 완전한 앱을 작성. iOS **3-4 인-월** + Android **3-4 인-월** = 총 **6-8 인-월**. 다만, 각 플랫폼의 네이티브 게임 프레임워크(SpriteKit, LibGDX)가 Flame보다 성숙하여 게임 엔진 구현 자체는 더 원활할 수 있음.

**단계적 마이그레이션**: 가능. 한 플랫폼(예: iOS)부터 먼저 네이티브로 전환하고, 다른 플랫폼은 Flutter를 유지하다가 순차 전환. Flutter의 플랫폼 채널을 통해 네이티브 모듈을 점진적으로 교체하는 것도 이론적으로 가능.

#### 코드 공유율

**0% 코드 공유**. 두 개의 완전히 독립된 코드베이스를 유지해야 함. 도메인 로직도 각각 작성. API 계약과 테스트 스펙만 공유 가능.

유지보수 비용은 크로스플랫폼 대비 **1.8-2.0배**. 버그 수정, 기능 추가 시 양쪽 모두에 적용해야 하며, 플랫폼별 동작 차이로 인한 추가 QA 비용 발생.

#### 커뮤니티/생태계

| 지표 | iOS (Swift) | Android (Kotlin) |
|------|------------|-----------------|
| GitHub Stars | Swift ~68K | Kotlin ~50K |
| 패키지 생태계 | CocoaPods/SPM (수만 개) | Maven Central (수십만 개) |
| Stack Overflow 태그 | 최대 규모 | 최대 규모 |
| 공식 후원 | Apple | Google + JetBrains |
| 게임 프레임워크 | SpriteKit (Apple 공식) | LibGDX (~23K stars) |

**패키지 생태계**: 양 플랫폼 모두 가장 풍부하고 성숙한 생태계. 게임 영역도 SpriteKit(Apple 최적화)과 LibGDX(검증된 Java/Kotlin 게임 프레임워크)로 강력.

#### 인력 시장 (한국)

| 지표 | iOS | Android |
|------|-----|---------|
| 잡코리아 채용공고 | ~200건+ | ~500건+ |
| 신입 평균 연봉 | ~3,701만원 | ~3,570만원 |
| 5년차 평균 연봉 | ~4,862만원 | ~4,737만원 |
| 프리랜서 가용성 | 높음 | 높음 |

**채용 난이도**: 가장 쉬움. iOS/Android 네이티브 개발자 풀이 가장 크며, 인력 수급이 안정적. 다만 두 명 이상의 개발자(또는 양쪽 모두 가능한 시니어)가 필요.

**학습 곡선**: 각 플랫폼 경험자 기준 즉시 생산성 확보. 게임 엔진(SpriteKit/LibGDX) 학습은 **2-4주** 추가.

#### 장기 전망

- **Apple/Google 투자**: 각사의 핵심 플랫폼이므로 투자 지속 보장
- **중단 리스크**: 사실상 0%. 플랫폼이 존재하는 한 지원됨
- **주요 동향**: SwiftUI 6 (iOS 19), Jetpack Compose 2.0, Swift 6 동시성 모델, Kotlin 2.x
- **대기업 채택**: 거의 모든 대기업이 네이티브 앱 유지

#### 앱 특성 적합도

**적합도: 상 (8/10)**

이 앱의 핵심인 "촉각적 카드 셔플"에 가장 적합. **iOS**: SpriteKit의 내장 물리 엔진 + Core Haptics의 정밀한 햅틱 제어 + Core Motion의 저지연 센서 접근. **Android**: LibGDX/Box2D의 검증된 물리 + SensorManager 직접 접근. 각 플랫폼의 하드웨어 기능을 100% 활용 가능. **단점**: 두 배의 개발/유지보수 비용이라는 치명적 약점.

---

### 4. Unity

#### 이식 난이도

**재사용 가능**: 도메인 로직의 알고리즘만 C#으로 번역. Unity의 ECS/MonoBehaviour 패턴은 Flutter의 위젯 트리와 근본적으로 다름.

**완전 재작성 필요**:
- **게임 엔진 레이어**: Flame/Forge2D → Unity 2D Physics (Box2D 기반, 네이티브). Unity는 Box2D를 내장하므로 물리 시뮬레이션 이식이 가장 자연스러움
- **UI**: Flutter 위젯 → Unity UI Toolkit 또는 uGUI. UI Toolkit은 2025년에도 여전히 발전 중이며, 일반 앱 UI 구현에는 Flutter/SwiftUI/Compose 대비 개발 경험이 열악
- **데이터 레이어**: Drift → SQLite 직접 사용 또는 Unity용 ORM (제한적)
- **Rive 애니메이션**: Unity용 Rive 런타임 존재
- **센서/햅틱**: Unity Input System + Handheld.Vibrate() / 네이티브 플러그인

**예상 재작성 규모**: 전체 코드의 ~90% 재작성. 약 **4-6 인-월**. 게임 엔진 부분은 오히려 더 쉬워지나, 일반 앱 UI(홈, 덱 선택, 리딩 결과 등) 구현이 Unity에서는 불필요하게 복잡.

**단계적 마이그레이션**: **하이브리드 가능**. Flutter 앱 내에 Unity를 임베딩하는 방식(flutter-unity-widget)으로 게임 엔진 부분만 Unity로 전환하고 나머지는 Flutter 유지 가능. 이 접근이 이 앱에 가장 현실적인 Unity 도입 경로.

#### 코드 공유율

iOS/Android 간 **~98% 코드 공유**. Unity의 최대 강점으로, C# 단일 코드베이스로 양 플랫폼을 커버. 플랫폼별 코드는 빌드 설정과 일부 네이티브 플러그인 정도.

#### 커뮤니티/생태계

| 지표 | 수치 |
|------|------|
| GitHub Stars | Unity Technologies (비공개 엔진, Asset Store 기반) |
| Asset Store | 100,000+ 에셋/플러그인 |
| Stack Overflow 태그 | 대규모 (게임 개발 최대) |
| 공식 후원 | Unity Technologies (IPO 기업) |
| 주요 사용 기업 | Pokémon GO, Among Us, Genshin Impact, 대부분의 모바일 게임 |

**패키지 생태계**: Asset Store가 게임 개발에 특화된 세계 최대 마켓플레이스. 카드 게임, 물리 시뮬레이션, 햅틱 관련 에셋 풍부. 그러나 **일반 앱 UI** 영역의 에셋/라이브러리는 빈약.

**라이선싱**:
- Personal: 무료 (연 매출 $200K 미만)
- Pro: $2,310/년/시트 (2026년 기준)
- Runtime Fee: 2023년 제안 후 철회, 현재 구독제만 적용

#### 인력 시장 (한국)

| 지표 | 수치 |
|------|------|
| 잡코리아 채용공고 | ~100건+ (게임 업계 중심) |
| 신입 평균 연봉 | ~3,200-3,800만원 (게임 업계) |
| 프리랜서 가용성 | 중간 (게임 업계에 집중) |

**채용 난이도**: Unity 개발자는 한국 게임 업계에 풍부하나, "앱 개발" 경험자는 드묾. 게임 개발자에게 앱 UX 감각을 요구하거나, 앱 개발자에게 Unity를 가르쳐야 하는 미스매치 발생 가능.

**학습 곡선**: C# 경험자 기준 **4-8주** (Unity 에디터 + 게임 개발 패턴). 웹/앱 개발자에게는 패러다임 전환이 큼 (선언적 UI → 게임 루프/씬 기반).

#### 장기 전망

- **Unity Technologies 투자**: 2023년 Runtime Fee 논란 이후 신뢰도 하락이 있었으나, 철회 후 안정화. Unity 6 출시로 기술적 진보 지속
- **중단 리스크**: 낮음. 모바일 게임 시장의 절대적 점유율. 다만 2023년 사태로 일부 개발자가 Godot 등으로 이탈
- **주요 동향**: Unity 6, UI Toolkit 개선, AI 통합, WebGPU 지원
- **대기업 채택**: 게임 업계 표준. 비게임 영역에서는 산업용(자동차, 건축, 디지털 트윈)

#### 앱 특성 적합도

**적합도: 중상 (7/10) — 단, 하이브리드 접근 시**

Unity는 게임 엔진으로서 물리 시뮬레이션 + 햅틱에 가장 강력. 그러나 이 앱은 "게임 요소가 있는 앱"이지 "게임"이 아님. 홈 화면, 덱 선택, 리딩 결과 표시 등 일반 앱 UI가 전체의 ~60%를 차지하며, 이 부분을 Unity로 구현하면 개발 생산성이 크게 떨어짐.

**최적 접근**: Flutter 앱 내에 Unity를 셔플 씬으로만 임베딩하는 하이브리드. 그러나 이는 "플랫폼 전환"이 아닌 "부분 보강"이며, 두 엔진의 빌드 파이프라인 관리라는 복잡성 추가.

---

### 5. .NET MAUI / Uno Platform

#### 이식 난이도

**재사용 가능**: 도메인 로직의 알고리즘만 C#로 번역. MVVM 패턴은 Clean Architecture와 개념적으로 유사.

**완전 재작성 필요**:
- **게임 엔진 레이어**: Flame/Forge2D에 대응하는 .NET MAUI 생태계의 게임 엔진이 **사실상 부재**. SkiaSharp으로 커스텀 렌더링 + Box2D C# 포트(Velcro Physics 등)를 직접 통합해야 함
- **UI**: Flutter 위젯 → XAML/C# (MAUI) 또는 WinUI XAML (Uno)
- **DB**: Drift → Entity Framework Core 또는 SQLite-net
- **Rive 애니메이션**: .NET용 Rive 런타임 지원이 제한적. Lottie 등 대안 검토 필요
- **센서/햅틱**: MAUI Essentials(가속도계, 진동) 제공하나, 정밀 햅틱 제어는 플랫폼 호출 필요

**예상 재작성 규모**: 전체 코드의 ~95% 재작성. 약 **5-7 인-월**. 게임 엔진을 거의 자체 구축해야 하므로 최대 리스크.

**단계적 마이그레이션**: 불가능. Flutter와 MAUI/Uno는 완전히 다른 생태계.

#### 코드 공유율

- **MAUI**: iOS/Android/Windows/macOS 간 ~90% 공유. 단, 실제 모바일 앱에서는 플랫폼별 핸들러 커스터마이징이 빈번하여 체감 공유율은 ~80%
- **Uno Platform**: 6개 플랫폼(iOS/Android/Windows/macOS/Linux/Web) 지원으로 최대 범위. ~85-90% 공유

#### 커뮤니티/생태계

| 지표 | MAUI | Uno Platform |
|------|------|-------------|
| GitHub Stars | ~22K | ~9K |
| NuGet 패키지 | .NET 생태계 활용 (대규모) | .NET 생태계 + Uno 전용 |
| Stack Overflow 태그 | 중간 (성장 중) | 작음 |
| 공식 후원 | Microsoft | nventive (캐나다 기업) |
| 주요 사용 기업 | 엔터프라이즈 내부 도구 중심 | Uno Gallery, 엔터프라이즈 |

**핵심 문제점 (2025-2026)**:
- MAUI의 CarouselView가 "사실상 사용 불가" 수준의 버그
- Visual Studio 2026에서 Android 툴체인 불안정
- .NET 8 MAUI 지원이 2025년 5월 종료 → .NET 9 강제 업그레이드
- 일부 개발자들이 "Why I Don't Use .NET MAUI Anymore" 기사 후 이탈

**게임 엔진**: .NET 생태계에 모바일 2D 게임 엔진이 **사실상 없음**. MonoGame(~11K stars)이 있으나 MAUI와의 통합이 어렵고, SkiaSharp 기반 커스텀 렌더링이 유일한 현실적 경로.

#### 인력 시장 (한국)

| 지표 | 수치 |
|------|------|
| 잡코리아 채용공고 (MAUI) | ~5건 미만 (추정) |
| .NET 개발자 (전체) | ~300건+ (서버/엔터프라이즈 중심) |
| 프리랜서 가용성 | 매우 낮음 (MAUI 모바일 경험자 극소) |

**채용 난이도**: 한국에서 가장 어려움. .NET 개발자는 있으나 MAUI 모바일 경험자는 거의 전무. 엔터프라이즈 백엔드(.NET) 개발자에게 모바일 + 게임 엔진까지 요구하는 것은 비현실적.

**학습 곡선**: C# 경험자 기준 **4-6주** (MAUI 프레임워크 학습). 게임 엔진 자체 구축까지 포함하면 **8-12주** 이상.

#### 장기 전망

- **Microsoft 투자**: .NET 전략의 일부이나, MAUI에 대한 투자 강도는 Blazor/ASP.NET 대비 낮다는 평가. 엔터프라이즈 내부 도구용으로 포지셔닝
- **중단 리스크**: 중간. Microsoft는 MAUI를 유지하겠지만, Xamarin → MAUI 전환 과정에서 보여준 단절이 반복될 수 있음. Uno Platform은 독립 기업(nventive) 운영으로 추가 리스크
- **주요 동향**: .NET 10, MAUI 10, Uno 6.3, AI 통합
- **대기업 채택**: 엔터프라이즈 내부 도구 중심. 소비자 앱에서의 채택 사례는 희소

#### 앱 특성 적합도

**적합도: 하 (2/10)**

이 앱에 가장 부적합. 핵심 이유:
1. 게임 엔진 생태계 부재 — 물리 시뮬레이션을 자체 구축해야 함
2. Rive 애니메이션 지원 미흡
3. 한국 인력 시장에서 채용 거의 불가능
4. MAUI 자체의 안정성 이슈 (CarouselView 버그, VS 2026 호환성 등)
5. 이 앱의 타겟 사용자(MZ세대, 타로 관심층)와 .NET 생태계의 괴리

---

## 전환 비용 비교 매트릭스

| 항목 | Flutter (현재) | React Native | KMP | Native (Swift+Kotlin) | Unity | MAUI/Uno |
|------|:---:|:---:|:---:|:---:|:---:|:---:|
| **재작성 규모** | 0% | ~85-90% | ~80-85% | ~100% x2 | ~90% | ~95% |
| **예상 인-월** | 0 | 3-4 | 4-5 | 6-8 | 4-6 | 5-7 |
| **코드 공유율** | ~98% | ~95% | ~80-85% | 0% | ~98% | ~85-90% |
| **게임 엔진 성숙도** | ★★★★ | ★★☆☆ | ★★☆☆ | ★★★★★ | ★★★★★ | ★☆☆☆☆ |
| **앱 UI 생산성** | ★★★★★ | ★★★★☆ | ★★★★☆ | ★★★★★ | ★★☆☆☆ | ★★★☆☆ |
| **물리 시뮬레이션** | ★★★★ | ★★★☆ | ★★★☆ | ★★★★★ | ★★★★★ | ★★☆☆☆ |
| **센서/햅틱 접근** | ★★★★ | ★★★☆ | ★★★★ | ★★★★★ | ★★★★ | ★★★☆ |
| **생태계 규모** | ★★★★ | ★★★★★ | ★★★☆ | ★★★★★ | ★★★★ (게임) | ★★★☆ |
| **한국 인력 가용성** | ★★★☆ | ★★★★ | ★★☆☆ | ★★★★★ | ★★★☆ | ★☆☆☆☆ |
| **장기 전망 안정성** | ★★★★ | ★★★★ | ★★★★★ | ★★★★★ | ★★★☆ | ★★★☆ |
| **앱 특성 적합도** | ★★★★ | ★★★☆ | ★★★☆ | ★★★★ | ★★★★ (하이브리드) | ★☆☆☆☆ |
| **총 전환 비용 (상대)** | **0** (기준선) | **높음** | **높음** | **매우 높음** | **높음** | **매우 높음** |

> 별점 기준: ★ = 최하, ★★★★★ = 최상. "전환 비용"은 재작성 규모 + 인력 확보 + 학습 곡선 + 생태계 리스크의 종합.

---

## 핵심 발견

### 1. 전환 정당성 부재 — Flutter 유지가 압도적 최선

현재 Flutter 코드베이스(~3,380줄)는 어떤 플랫폼으로 전환하든 **최소 85% 이상 재작성**이 필요하며, 이는 **3-8 인-월의 순수 비용**을 의미한다. 그 대가로 얻는 것은:
- React Native: 더 넓은 JS 인력풀 (그러나 게임 엔진 열위)
- KMP: 더 나은 네이티브 통합 (그러나 게임 엔진 미성숙)
- Native: 최고의 플랫폼 접근 (그러나 2배의 유지보수)
- Unity: 최고의 게임 엔진 (그러나 앱 UI 열위)
- MAUI: 어떤 영역에서도 이점 없음

**이 앱의 핵심 기술 스택(Flame + Forge2D + sensors_plus + Rive)은 Flutter에서 가장 잘 통합되어 있다.** "게임 요소가 있는 앱"이라는 혼합 특성에 Flutter + Flame이 가장 균형 잡힌 해답.

### 2. 유일하게 고려 가치 있는 시나리오

| 시나리오 | 권장 전환 대상 | 조건 |
|---------|------------|------|
| 게임 엔진 품질이 사업적으로 치명적일 때 | Unity 하이브리드 (Flutter 내 임베딩) | 셔플 씬만 Unity, 나머지 Flutter 유지 |
| 팀 확장 시 JS 개발자만 채용 가능할 때 | React Native | 게임 엔진 품질 타협 감수 |
| 장기적으로 Android 네이티브 팀이 될 때 | KMP | Compose Multiplatform iOS stable 안정화 확인 후 |

### 3. 앱 특성 판단: "게임 아닌 앱, 게임적 순간이 있는"

이 앱은 4개 feature 중 1개(shuffle)만 게임 엔진을 사용. 나머지 3개(home, deck, reading)는 순수 앱 UI. 전체 LOC 기준으로도 게임 엔진 코드는 ~12%에 불과. 따라서:
- Unity처럼 게임 전문 플랫폼은 **과잉** (나머지 88%에서 생산성 손실)
- MAUI처럼 게임 지원이 없는 플랫폼은 **부족** (12%의 핵심 경험 구현 불가)
- **Flutter + Flame은 이 혼합 비율에 정확히 맞는 도구**

### 4. 생태계 건강성 순위 (2026년 기준)

1. **Native (Swift/Kotlin)** — 플랫폼 존속과 동의어. 중단 리스크 0%
2. **KMP** — 급성장 (7% → 23%), JetBrains + Google 이중 보증, 대기업 채택 가속
3. **Flutter** — 안정기 진입 (~46% 시장 점유), Google 내부 사용, Flutter 4.0 예고
4. **React Native** — New Architecture 완성, Meta + Expo 양축 지탱, JS 생태계 활용
5. **Unity** — 게임 영역 표준이나 2023년 Runtime Fee 사태로 신뢰도 손상
6. **MAUI/Uno** — Microsoft 지원이나 모바일 영역 채택률 저조, 안정성 이슈 지속

### 5. 한국 시장 특수성

한국에서의 모바일 개발자 채용 현실:
- **iOS/Android 네이티브**: 가장 풍부한 인력풀, 안정적 수급
- **React Native**: JS 개발자 전환 경로 확립, 공고 ~157건
- **Flutter**: 공고 ~165건으로 RN과 비슷하나, Dart 전용 인력은 제한적
- **KMP**: Android Kotlin 개발자는 많으나 KMP 경험자는 극소수
- **Unity**: 게임 업계에 집중, 앱 개발 맥락의 Unity 개발자는 드묾
- **MAUI**: 사실상 채용 불가능

**결론**: 현재 Flutter 코드베이스를 유지하면서 Flame/Forge2D 게임 엔진을 고도화하는 것이 비용, 리스크, 앱 특성 모든 면에서 최적. 전환은 명확한 사업적 불가피성이 발생했을 때만 재검토할 사안이다.

---

## Sources

- [Flutter vs React Native in 2026 — TechAhead](https://www.techaheadcorp.com/blog/flutter-vs-react-native-in-2026-the-ultimate-showdown-for-app-development-dominance/)
- [KMP vs Flutter vs React Native: 2026 Cross-Platform Reality — Java Code Geeks](https://www.javacodegeeks.com/2026/02/kotlin-multiplatform-vs-flutter-vs-react-native-the-2026-cross-platform-reality.html)
- [Kotlin Multiplatform: 2025 Updates and 2026 Predictions — Aetherius Solutions](https://www.aetherius-solutions.com/blog-posts/kotlin-multiplatform-in-2026)
- [State of Kotlin 2026 — devnewsletter](https://devnewsletter.com/p/state-of-kotlin-2026/)
- [Is KMP Production-Ready in 2026? — Volpis](https://volpis.com/blog/is-kotlin-multiplatform-production-ready/)
- [Flutter & Dart's 2026 Roadmap — Flutter Blog](https://blog.flutter.dev/flutter-darts-2026-roadmap-89378f17ebbd)
- [State of Flutter 2026 — devnewsletter](https://devnewsletter.com/p/state-of-flutter-2026/)
- [The State of .NET MAUI in 2025 — Appisto](https://appisto.app/blog/state-of-dotnet-maui)
- [State of .NET 2026 — devnewsletter](https://devnewsletter.com/p/state-of-dot-net-2026/)
- [VS 2026 MAUI Issues — Microsoft Q&A](https://learn.microsoft.com/en-us/answers/questions/5651444/vs-2026-development-of-maui-apps-for-mobile-is-not)
- [Bridgeless React Native: TurboModules + Fabric + JSI in 2026](https://medium.com/@Sofia52/bridgeless-react-native-turbomodules-fabric-jsi-in-2026-b1cab33e2b2f)
- [React Native in 2026 — Nucamp](https://www.nucamp.co/blog/react-native-in-2026-build-ios-and-android-apps-with-javascript)
- [Build 2D Game Physics with Matter.js and React Native Skia — Expo](https://expo.dev/blog/build-2d-game-style-physics-with-matter-js-and-react-native-skia)
- [Cross-Platform Dev Tools Comparison 2026 — CodeNote](https://codenote.net/en/posts/cross-platform-dev-tools-comparison-2026/)
- [5 Best Cross Platform Frameworks 2026 — Uno Platform](https://platform.uno/articles/best-cross-platform-frameworks-2026/)
- [Native vs Cross-Platform 2026 Guide — SparkOut](https://www.sparkouttech.com/native-vs-cross-platform/)
- [2025 개발자 연차별 평균연봉 — GroupBy](https://groupby.careers/%EC%A7%81%EB%AC%B4%EB%B3%84-%EC%84%B8%EB%B6%80-%EC%97%B0%EB%B4%89-%EB%B6%84%EC%84%9D-1%ED%83%84-2025-%EA%B0%9C%EB%B0%9C%EC%9E%90-%EC%97%B0%EB%B4%89-%ED%98%84%EC%8B%A4-%EC%97%B0%EC%B0%A8%EB%B3%84/)
- [KorGE — Kotlin Multiplatform Game Engine](https://korge.org/)
- [Unity UI Toolkit Milestones — Unity Discussions](https://discussions.unity.com/t/ui-toolkit-development-status-and-next-milestones-november-2025/1698009)
- [Flutter vs Unity for Game Dev — BrianKayFitz](https://briankayfitz.com/developing-games-in-flutter-vs-unity/)
- [JobKorea Flutter 채용공고](https://www.jobkorea.co.kr/Search/?stext=flutter)
- [JobKorea React Native 채용공고](https://www.jobkorea.co.kr/Search/?stext=react+native)

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
