---
id: "008"
type: research
title: "타로 셔플 앱 기술 스택 연구"
created: 2026-03-15
traces_scope: "001"
summary: >
  Flutter 기반 타로 셔플 앱 MVP의 기술 스택을 4개 관점에서 조사.
  하이브리드 셔플 엔진(순수 Flutter + Flame), Riverpod + 게임 루프 이원화,
  Drift + freezed 데이터 계층, sensors_plus + FortunaRandom 엔트로피 시스템 권장.
keywords: [flutter, shuffle-engine, sensors, csprng, drift, riverpod, clean-architecture, offline-first]
---

# 타로 셔플 앱 기술 스택 연구

## Research Overview

### Background & Motivation
PRD(docs/003_gemini_deep_research.md)는 "사용자의 물리적 상호작용이 셔플 결과에 반영되는 제의적 경험"을 핵심 차별화 요소로 정의한다. 이를 Flutter Android MVP로 구현하기 위해 셔플 물리 엔진, 센서/난수, 데이터 계층, 앱 아키텍처의 기술 스택을 결정해야 한다.

현재 `mobile/`은 빈 Flutter 3.10+ 스켈레톤(MaterialApp만 존재)이므로 기술 선택의 자유도가 높다.

### Research Scope
**포함**: Flutter 생태계 내 물리 엔진, 센서 API, 난수 생성, 로컬 DB, 앱 아키텍처 패턴
**제외**: 서버 사이드(Rails API), 클라우드 동기화, 커뮤니티/바운티 시스템 (Phase 3-4 범위)

### Research Perspectives
1. **셔플 엔진 & 카드 애니메이션** — 물리 엔진 선택, 카드 모션 구현, 성능 최적화
2. **센서 통합 & 난수 생성** — 디바이스 센서, CSPRNG, 하이브리드 엔트로피, 햅틱
3. **데이터 아키텍처 & 오프라인** — 로컬 DB, JSON 스키마, 이미지 관리, 오프라인-퍼스트
4. **Flutter 앱 아키텍처 & 프로젝트 구조** — Clean Architecture, 상태 관리, 테스트 전략

### Related Documents
- Checkpoint: [002_Research_tarot_shuffle_tech.md](./002_Research_tarot_shuffle_tech.md)
- Agent reports: [003](./003_Agent_shuffle_engine.md), [004](./004_Agent_sensor_rng.md), [005](./005_Agent_data_offline.md), [006](./006_Agent_architecture.md)
- Synthesis: [007_Synthesis_tarot_shuffle_tech.md](./007_Synthesis_tarot_shuffle_tech.md)

---

## Perspective 1: 셔플 엔진 & 카드 애니메이션

### Status Analysis

Flutter에서 78장 카드의 물리 기반 셔플을 구현하는 방법은 크게 3가지:

| 접근법 | 도구 | 엔티티 한계 | 물리 충돌 | 적합 용도 |
|--------|------|-----------|---------|---------|
| 위젯 기반 | AnimatedPositioned/Stack | ~400개 | 없음 | 단순 UI 전환 |
| Canvas 직접 그리기 | CustomPainter + AnimationController | 수천 개 | 직접 구현 | 리플/오버핸드 셔플 |
| 게임 엔진 | Flame + Forge2D | ~3,600개 (60fps) | 내장 | 워시/메시 셔플 |

### Detailed Findings

#### 1. 하이브리드 접근법 (권장)

**리플/오버핸드 셔플** → 순수 Flutter:
- `AnimationController` + `CurvedAnimation` + `Tween<Offset>`
- 카드별 150-200ms 순차 딜레이 (Staggered Animation 패턴)
- cubic-bezier 커브로 호(arc) 경로 생성
- `flutter_physics` 패키지의 `PhysicsController`: 제스처→애니메이션 전환 시 속도 보존으로 자연스러운 연속성
- 오버핸드의 3D 깊이감: `Transform` + `Matrix4.setEntry(3,2,0.001)` perspective

**워시/메시 셔플** → Flame + Forge2D:
- 78장 각각 `Dynamic BodyComponent` (RigidBody)
- 화면 경계 `Static Body` (카드 이탈 방지)
- 손가락 터치 → `Kinematic Body` (원형, 좌표 추적)
- `ContactListener`로 충돌 이벤트 감지 → 햅틱 트리거
- Forge2D의 sweep-and-prune broad-phase가 불필요한 충돌 쌍 자동 제거

**Flame 도입 범위**: `GameWidget`을 워시 셔플 화면에만 임베드. 앱 전체를 게임 엔진으로 만들지 않음. `overlays` API로 Flutter 위젯(UI 컨트롤)과 혼합 가능.

#### 2. 카드 플립 애니메이션

400ms Y축 3D 회전: `Transform` + `Matrix4.rotateY(angle)` + perspective `setEntry(3,2,0.001)`
전반부(0-0.5): 뒷면 표시, 후반부(0.5-1.0): 앞면 표시 + 좌우 반전 보정

#### 3. 애니메이션 도구 평가

| 도구 | 평가 | 용도 |
|------|------|------|
| AnimationController + CustomPainter | ★★★★★ | 핵심 셔플 렌더링 |
| Flame + Forge2D | ★★★★☆ | 워시 셔플 전용 |
| flutter_physics | ★★★★☆ | 물리 기반 모션 (스프링, 마찰) |
| Rive | ★★☆☆☆ | 보조 이펙트만 (동적 물리 불가) |
| Lottie | ★☆☆☆☆ | 프리셋 이펙트만 (카드 위치 제어 불가) |

#### 4. 성능 최적화

- **Impeller** (Flutter 3.29+): AOT 셰이더 컴파일로 첫 애니메이션 jank 제거, 프레임 드롭 70%+ 감소
- **RepaintBoundary**: 카드 애니메이션 영역과 정적 UI를 분리. 과용 금지 (메모리/GPU 비용)
- **스프라이트 시트**: 기본 덱(RWS) 78장을 단일 텍스처 아틀라스로 → `drawAtlas()` 단일 호출
- **precacheImage**: 앱 시작 시 카드 이미지 사전 로드
- **cacheWidth/cacheHeight**: 카드 표시 크기에 맞춘 디코딩으로 메모리 절약

### Caveats & Risks
- Flame + 순수 Flutter 혼합 아키텍처의 복잡도 증가
- Forge2D 물리 파라미터(마찰, 반발) 튜닝에 반복 테스트 필요
- 구형 Android (API 28 이하): Impeller OpenGL ES 폴백 시 별도 성능 검증 필요

### Summary
**리플/오버핸드는 순수 Flutter(AnimationController + CustomPainter), 워시는 Flame+Forge2D**의 하이브리드 접근이 최적. 78장 60fps는 CustomPainter + Impeller 조합으로 충분히 달성 가능.

---

## Perspective 2: 센서 통합 & 난수 생성

### Status Analysis

PRD의 핵심 가설인 "사용자의 물리적 개입이 셔플에 반영"을 구현하려면:
1. 디바이스 센서 데이터 수집 (가속도계, 자이로스코프, 터치 타임스탬프)
2. 센서 데이터를 엔트로피로 변환
3. 암호학적으로 안전한 난수 생성기에 엔트로피 주입
4. 셔플 알고리즘(Fisher-Yates)에 난수 공급

### Detailed Findings

#### 1. 센서 API: sensors_plus 채택

| 항목 | 값 |
|------|------|
| 패키지 | sensors_plus ^5.0.0 (Flutter Community 유지보수) |
| 가속도계 | `accelerometerEventStream()` — BroadcastStream |
| 자이로스코프 | `gyroscopeEventStream()` — BroadcastStream |
| 샘플링 레이트 | `SensorInterval.gameInterval` (20ms, ~50Hz) 권장 |
| 플랫폼 | Android (SensorManager), iOS (CoreMotion), Web (제한적) |
| 주의 | Android 샘플링 레이트 보장 안 됨. 실제 측정 필요 |

터치 타임스탬프: `Listener` 위젯의 `PointerEvent.timeStamp` (Duration, 마이크로초 정밀도)

#### 2. CSPRNG: PointyCastle FortunaRandom

**`Random.secure()`의 한계**: OS CSPRNG(Android /dev/urandom, iOS SecRandomCopyBytes)을 사용하나 **외부 시드 주입 불가**. 설계상 시드 변경을 허용하지 않음.

**FortunaRandom 채택 이유**:
- `seed(KeyParameter(Uint8List))` 메서드로 32바이트 시드 주입 가능
- Re-seeding 지원 (센서 데이터 축적에 따라 반복 시드 갱신)
- `nextUint32()` 등 표준 난수 인터페이스 제공
- `Random` 인터페이스 래퍼를 만들면 Dart 내장 `List.shuffle(random)` 직접 사용 가능 → Fisher-Yates 직접 구현 불필요

#### 3. 하이브리드 엔트로피 모델

```
센서 수집 (sensors_plus)
  ├─ 가속도계: Ax, Ay, Az
  ├─ 자이로스코프: Gx, Gy, Gz
  └─ 터치 타임스탬프: Ti (μs)
          │
          ▼
PRD 시드 공식 적용
  S = Σ(√(Ax²+Ay²+Az²) × Gz) ⊕ Ti
          │
          ▼
SHA-256 누적 해시 (엔트로피 풀)
  pool = SHA256(pool || S)           ← avalanche effect로 편향 분산
          │
          ▼
시스템 CSPRNG 혼합
  finalSeed = SHA256(pool || Random.secure().bytes(32))
          │
          ▼
FortunaRandom 시드 주입
  fortuna.seed(KeyParameter(finalSeed))
          │
          ▼
Fisher-Yates 셔플
  cardList.shuffle(FortunaRandomWrapper(fortuna))
```

**편향 방지**: 센서 min-entropy는 3.4~4.5비트/센서로 낮음 (학술 연구). 반드시 시스템 CSPRNG 출력과 혼합 필수.
**최소 샘플**: 10~20개 센서 이벤트 축적 후 셔플 허용. 진행률 UI 표시.
**폴백**: 센서 없는 기기/에뮬레이터 → `Random.secure()` 단독 사용 + UX 알림.

#### 4. 햅틱 피드백

| 용도 | API | 비고 |
|------|-----|------|
| 카드 교차 틱 (MVP) | `HapticFeedback.selectionClick()` | Flutter 내장 |
| 카드 접촉 (MVP) | `HapticFeedback.lightImpact()` | Flutter 내장 |
| 셔플 완료 (MVP) | `HapticFeedback.mediumImpact()` | Flutter 내장 |
| 고도화 | haptic_feedback 패키지 | Android API 30+ high-fidelity 프리미티브 |

**50ms 쓰로틀링 필수**: 워시 셔플에서 다수 충돌 발생 시 과도한 햅틱 호출 방지.
**Android 버전별**: API <26 on/off만, 26-29 VibrationEffect, 30+ Composition 프리미티브.

### Caveats & Risks
- 센서 데이터만으로는 암호학적 안전성 미달 — 반드시 시스템 CSPRNG과 혼합
- Android 센서 샘플링 레이트 비보장 — 실측 기반 보정 필요
- FortunaRandom 초기화 시간 (첫 시드 주입까지 블로킹)

### Summary
**sensors_plus(센서 수집) + crypto(SHA-256 엔트로피 풀) + pointycastle(FortunaRandom 시드 가능 CSPRNG)** 조합. PRD 시드 공식은 Dart로 직접 구현 가능하며, `Random.secure()` 출력과 XOR 혼합하여 편향을 제거.

---

## Perspective 3: 데이터 아키텍처 & 오프라인

### Status Analysis

타로 앱의 데이터 요구사항:
- 덱 메타데이터 + 카드 배열 (관계형)
- 카드 meanings 필드 (구조화된 JSON — upright/reversed/custom_notes)
- 카드 이미지 (고해상도, 78장+)
- 리딩 히스토리 (스프레드 스냅샷)
- 오프라인 100% 동작 + 향후 클라우드 동기화 대비

### Detailed Findings

#### 1. 로컬 DB: Drift 채택

| DB | 평가 | 비고 |
|----|------|------|
| **Drift** | ★★★★★ | 타입 안전 SQL, 코드 생성, 리액티브 스트림, JSON1 확장, 마이그레이션 자동화 |
| sqflite | ★★★☆☆ | Drift의 기반 엔진. 직접 사용보다 Drift를 통해 사용 |
| Hive CE | ★★★☆☆ | 앱 설정/캐시 보조 저장소로만 사용. 메인 DB로는 쿼리 유연성 부족 |
| Isar | ★★☆☆☆ | **비추천** — 원저자 프로젝트 이탈, v4 dev 장기 정체, 유지보수 불확실 |
| ObjectBox | ★★★☆☆ | 성능 최고이나 클로즈드 소스 코어 + 유료 Sync가 Rails API 자체 구축 방향과 충돌 |

**Drift 선택 근거**:
- 관계형 쿼리: 덱-카드 FK 관계, 스프레드-카드 조인
- JSON1 확장: `meanings` JSON 필드 내부 쿼리 가능 (`jsonExtract`)
- TypeConverter: JSON ↔ Dart 객체 자동 변환 (freezed 모델과 연결)
- 리액티브 스트림: `watchAll()` → UI 자동 갱신
- 마이그레이션: 스키마 버전 관리 + 자동 마이그레이션 코드 생성

#### 2. 스키마 관리: freezed + json_serializable

PRD의 `deck.json` 스키마를 Dart 불변 모델로 변환:

```
DeckMetadata (freezed)
  ├─ id: String
  ├─ name: String
  ├─ isStandardTarot: bool
  ├─ totalCards: int
  ├─ creator: String?
  └─ createdAt / updatedAt / syncStatus / version  ← 동기화 대비

TarotCard (freezed)
  ├─ cardId: String
  ├─ deckId: String (FK)
  ├─ name: String
  ├─ suit: String?
  ├─ imageUrl: String
  └─ meanings: CardMeanings (JSON 컬럼)

CardMeanings (freezed)
  ├─ upright: List<String>
  ├─ reversed: List<String>
  └─ customNotes: String?
```

**저장 전략 (하이브리드)**:
- 덱 ↔ 카드 관계: 관계형 FK (`deck_id`)
- meanings 필드: JSON 컬럼 (Drift TypeConverter로 CardMeanings ↔ JSON 자동 변환)
- Import/Export 시: `json_schema` 패키지로 런타임 유효성 검증

#### 3. 이미지 관리

**저장**: DB에 경로만 저장, 이미지는 파일시스템 직접 관리
```
app_data/
  decks/{deck_id}/
    originals/   ← 원본
    thumbnails/  ← 300x450 썸네일
```

**업로드 파이프라인** (OOM 방지):
- 배치 분할 (5-10장씩)
- `Isolate`에서 리사이징 (1024x1536) + WebP 변환 (q85) + 썸네일 생성
- `flutter_image_compress` 패키지

**렌더링 최적화**:
- 기본 덱(RWS): 스프라이트 시트 + `drawAtlas()`
- 커스텀 덱: 개별 이미지 + `precacheImage` + `cacheWidth/cacheHeight`
- `GridView.builder` lazy loading (메타데이터 편집 UI)

#### 4. 오프라인-퍼스트 설계

**Phase 1부터 동기화 대비 필드 포함**:
```dart
// 모든 엔티티 공통
createdAt: DateTime
updatedAt: DateTime
syncStatus: SyncStatus  // pending, synced, conflict
version: int            // 낙관적 잠금
```

**Phase 3 확장 계획**:
- `sync_queue` 테이블: 오프라인 변경사항 누적
- `connectivity_plus` 패키지: 네트워크 상태 감지 → 큐 flush
- 충돌 해결: Last-Write-Wins (LWW) + 필드 레벨 병합 (CRDT는 단일 사용자에 과도)

### Caveats & Risks
- Drift 코드 생성 빌드 시간 증가 (build_runner)
- 78장 고해상도 이미지 동시 로드 시 저사양 기기 OOM 주의
- JSON1 확장은 SQLite 빌드 의존 — Flutter 기본 SQLite에 포함 여부 확인 필요

### Summary
**Drift(관계형 + JSON1) + freezed 모델 + 파일시스템 이미지 관리**. Phase 1부터 syncStatus/version 필드를 포함하여 Phase 3 클라우드 동기화 확장에 대비.

---

## Perspective 4: Flutter 앱 아키텍처 & 프로젝트 구조

### Status Analysis

PRD가 요구하는 아키텍처:
- Clean Architecture 3계층 (Data/Domain/Presentation)
- Strategy Pattern (셔플 알고리즘 런타임 교체)
- Factory Pattern (BaseCard → TarotCard, OracleCard, CustomCard)
- MVVM (리액티브 UI)
- 78장 카드 개별 상태의 60fps 관리

### Detailed Findings

#### 1. 이원화 상태 관리 (가장 중요한 발견)

**앱 상태**: Riverpod 3.0 (`@riverpod` 코드 생성)
- 덱 선택, 셔플 전략 선택, 리딩 히스토리, 사용자 설정
- 변경 빈도 낮음, 위젯 트리 rebuild 허용

**애니메이션 상태**: Ticker + CustomPainter 게임 루프
- 78장 카드 각각의 x/y/z/rotation/faceUp 상태
- 매 프레임(16.67ms) 업데이트 → Riverpod/BLoC으로 전파하면 rebuild 오버헤드로 60fps 불가
- CustomPainter의 `repaint` Listenable 사용 → build/layout 단계 스킵, paint만 호출

**연결 지점**: Riverpod Provider가 "어떤 셔플 전략을 사용할지" 결정 → 게임 루프가 해당 전략의 물리/애니메이션을 실행

#### 2. Clean Architecture + Feature-first Hybrid

```
lib/
  core/                        ← 공유 코드
    error/                     ← 에러 처리
    theme/                     ← 다크 모드 테마
    utils/                     ← 유틸리티
    di/                        ← get_it + injectable 설정
  features/
    shuffle/                   ← 셔플 기능
      data/
        datasources/           ← 센서 데이터 소스
        repositories/          ← ShuffleRepositoryImpl
      domain/
        entities/              ← ShuffleResult
        repositories/          ← ShuffleRepository (인터페이스)
        usecases/              ← ShuffleDeckUseCase
        strategies/            ← ShuffleStrategy 인터페이스 + 구현체
      presentation/
        pages/                 ← ShufflePage
        widgets/               ← CardPainter (CustomPainter)
        providers/             ← Riverpod providers
    deck/                      ← 덱 관리
      data/
      domain/
      presentation/
    reading/                   ← 리딩 (스프레드)
      data/
      domain/
      presentation/
    settings/                  ← 설정
```

#### 3. Strategy Pattern (Dart 구현)

```dart
// 셔플 전략 인터페이스
abstract class ShuffleStrategy {
  Future<List<TarotCard>> shuffle(List<TarotCard> cards, EntropySource entropy);
  ShuffleAnimationConfig get animationConfig;
}

// 구현체
class RiffleShuffleStrategy implements ShuffleStrategy { ... }
class OverhandShuffleStrategy implements ShuffleStrategy { ... }
class WashShuffleStrategy implements ShuffleStrategy { ... }  // Flame 내부 사용
```

#### 4. Factory Pattern (Dart 3 sealed class)

```dart
sealed class BaseCard {
  String get cardId;
  String get name;
  String get imageUrl;
}

class TarotCard extends BaseCard { ... }    // 78장 표준
class OracleCard extends BaseCard { ... }   // 비정형 오라클
class CustomCard extends BaseCard { ... }   // 사용자 생성
```

Dart 3 `sealed class` + 패턴 매칭으로 exhaustive check 보장.

#### 5. 기술 스택

| 영역 | 선택 | 비고 |
|------|------|------|
| 상태 관리 (앱) | Riverpod 3.0 | @riverpod 코드 생성, 테스트 용이 |
| 상태 관리 (애니메이션) | Ticker + CustomPainter | 게임 루프, 위젯 rebuild 스킵 |
| DI | get_it + injectable | 코드 생성 기반 등록 |
| 라우팅 | go_router | 선언적, 딥링킹 지원 |
| 직렬화 | freezed + json_serializable | 불변 모델, 코드 생성 |
| 테스트 모킹 | mocktail | verify/when 구문, 코드 생성 불필요 |
| Golden 테스트 | Alchemist | CI 환경 독립적 golden 테스트 |

#### 6. 테스트 전략

| 수준 | 대상 | 방법 |
|------|------|------|
| 단위 테스트 | 셔플 알고리즘 무작위성 | 시드 고정 + 분포 검증 (chi-squared) |
| 단위 테스트 | Use Case, Repository | mocktail 모킹 |
| 위젯 테스트 | 카드 플립, 스프레드 레이아웃 | `tester.pump()` + `find.byType()` |
| Golden 테스트 | 카드 렌더링 시각적 회귀 | Alchemist (CI 환경 폰트 독립) |
| 통합 테스트 | 셔플→드로우→스프레드 전체 흐름 | `flutter_test` integration |
| 물리 엔진 | 시뮬레이션 결정론적 재현 | FakeAsync + 시드 고정 |

### Caveats & Risks
- 이원화 상태 관리의 학습 곡선 (Riverpod + 게임 루프 패턴을 동시에 이해해야 함)
- 코드 생성 도구 다수 (freezed, riverpod, injectable, drift) → build_runner 실행 시간 증가
- GetX는 유지보수 위기 + 테스트 어려움으로 비추천

### Summary
**Riverpod(앱 상태) + Ticker+CustomPainter(애니메이션 상태) 이원화**가 핵심 아키텍처 결정. Feature-first hybrid 폴더 구조 + Strategy/Factory 패턴으로 모듈화.

---

## Cross-Analysis

### Inter-Perspective Relationships

```
[관점 4: 아키텍처]
  ShuffleStrategy 인터페이스
       │
       ├─ RiffleShuffleStrategy ──→ [관점 1] AnimationController + CustomPainter
       ├─ OverhandShuffleStrategy ─→ [관점 1] AnimationController + Transform (3D)
       └─ WashShuffleStrategy ────→ [관점 1] Flame + Forge2D
                                          │
                                          └─ ContactListener ──→ [관점 2] HapticFeedback

[관점 2: 센서/난수]
  SensorDataCollector (sensors_plus)
       │
       ├─ EntropyPool (SHA-256) ──→ FortunaRandom ──→ Fisher-Yates shuffle
       └─ AnimationParameterMapper ──→ [관점 1] 오버핸드 청크 크기, 워시 카드 속도

[관점 3: 데이터]
  Drift Repository
       │
       ├─ DeckRepository ──→ [관점 4] Clean Architecture Domain Layer
       ├─ freezed 모델 ───→ [관점 4] Entity/Model 분리
       └─ 이미지 관리 ───→ [관점 1] precacheImage + 스프라이트 시트
```

### Common Patterns

1. **코드 생성 수렴**: freezed(모델), @riverpod(상태), injectable(DI), drift(DB) — 모두 `build_runner` 기반. 통합 실행으로 효율화.
2. **CustomPainter 중심**: 관점 1(렌더링)과 관점 4(상태 관리) 모두 "위젯 트리 스킵, Canvas 직접 그리기"로 수렴.
3. **오프라인-퍼스트 관통**: 관점 3(Drift + sync 필드)과 관점 4(Repository 패턴)이 자연스럽게 결합.

### Conflicting Items

1. **센서 데이터의 이중 용도**: 난수 시드(관점 2) vs 애니메이션 파라미터(관점 1). → **해결**: SensorDataCollector가 수집 후 양쪽에 분배. 동일 데이터의 서로 다른 소비자.

2. **이미지 전략 분기**: 스프라이트 시트(관점 1, 기본 덱) vs 개별 파일(관점 3, 커스텀 덱). → **해결**: `CardImageProvider` 추상화가 덱 유형에 따라 전략 분기.

---

## Comprehensive Conclusion

### 핵심 발견 (우선순위 순)

1. **[Critical] R-008-F1: 이원화 상태 관리** — Riverpod(앱 상태) + Ticker/CustomPainter(애니메이션 상태) 분리가 60fps 달성의 전제 조건. Riverpod/BLoC 단독으로 매 프레임 78개 카드 상태를 전파하면 위젯 트리 rebuild 오버헤드로 60fps 불가. *(관점 1, 4)*

2. **[Critical] R-008-F2: 하이브리드 셔플 엔진** — 리플/오버핸드(순수 Flutter)와 워시(Flame+Forge2D)는 근본적으로 다른 렌더링 패러다임. 하이브리드만이 과잉 설계 없이 모든 셔플 유형을 지원. *(관점 1)*

3. **[Critical] R-008-F3: FortunaRandom으로 CSPRNG 재설계** — `Random.secure()`는 외부 시드 주입 불가. PRD의 센서 엔트로피 모델을 구현하려면 PointyCastle FortunaRandom + SHA-256 엔트로피 풀이 필수. *(관점 2)*

4. **[High] R-008-F4: Drift 유일 합리적 DB** — 관계형 쿼리 + JSON1 + 타입 안전 + 리액티브 + 마이그레이션이 모두 필요한 요구사항에서 대안 부재. Isar 유지보수 불확실, ObjectBox 클로즈드 소스. *(관점 3)*

5. **[High] R-008-F5: Phase 1부터 동기화 대비** — syncStatus/version 필드를 초기 스키마에 포함. 나중에 추가하면 마이그레이션 비용 발생. *(관점 3)*

6. **[High] R-008-F6: Feature-first Hybrid 구조** — `lib/features/{shuffle,deck,reading}/` 각각 내부에 data/domain/presentation. 모듈 경계가 명확하여 향후 패키지 분리 용이. *(관점 4)*

7. **[Medium] R-008-F7: 센서 편향 방지 필수** — 센서 min-entropy 3.4~4.5비트로 낮음. 반드시 시스템 CSPRNG 출력과 혼합. 최소 10-20 샘플 축적 후 셔플 허용. *(관점 2)*

8. **[Medium] R-008-F8: 햅틱 50ms 쓰로틀링** — 워시 셔플 다수 충돌 시 과도한 햅틱 호출 방지. MVP는 Flutter 내장 HapticFeedback, 고도화 시 haptic_feedback 패키지. *(관점 2)*

### 통합 기술 스택 (pubspec.yaml 의존성)

```yaml
dependencies:
  # 상태 관리
  flutter_riverpod: ^2.6.0
  riverpod_annotation: ^2.6.0

  # 물리/애니메이션
  flame: ^1.22.0              # 워시 셔플 전용
  flame_forge2d: ^0.18.0      # 워시 셔플 물리
  flutter_physics: ^1.1.0     # 물리 기반 모션

  # 센서/난수
  sensors_plus: ^5.0.0        # 가속도계/자이로스코프
  pointycastle: ^3.7.0        # FortunaRandom CSPRNG
  crypto: ^3.0.0              # SHA-256 엔트로피 풀

  # 데이터
  drift: ^2.22.0              # 로컬 DB
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.1.0       # 파일 경로
  freezed_annotation: ^2.4.0  # 불변 모델
  json_annotation: ^4.9.0     # JSON 직렬화
  connectivity_plus: ^6.1.0   # 네트워크 상태

  # DI/라우팅
  get_it: ^8.0.0              # 의존성 주입
  injectable: ^2.5.0
  go_router: ^14.6.0          # 라우팅

  # 이미지
  flutter_image_compress: ^2.3.0  # 이미지 압축

dev_dependencies:
  # 코드 생성
  build_runner: ^2.4.0
  riverpod_generator: ^2.6.0
  freezed: ^2.5.0
  json_serializable: ^6.8.0
  drift_dev: ^2.22.0
  injectable_generator: ^2.6.0

  # 테스트
  mocktail: ^1.0.0
  alchemist: ^0.10.0          # Golden 테스트

  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
```

## Unresolved Items

1. **Flame + Riverpod 연동 구체적 패턴** — Flame GameWidget 내부 상태와 Riverpod Provider 간의 브릿지 패턴은 구현 단계에서 프로토타이핑 필요. 공식 문서에 명확한 가이드 부재.
2. **Flutter 기본 SQLite의 JSON1 확장 포함 여부** — `sqlite3_flutter_libs`가 JSON1을 포함하여 빌드되는지 플랫폼별 확인 필요 (대부분 포함하나 보장은 없음).
3. **Android API 28 이하 Impeller OpenGL ES 폴백 성능** — 구형 기기에서 78장 렌더링 시 실제 fps 측정은 프로토타이프 단계에서만 가능.

## Referenced File List

| File Path | Related Perspective | Role/Content |
|-----------|-------------------|--------------|
| mobile/pubspec.yaml | 전체 | 현재 의존성 (비어 있음) |
| mobile/lib/main.dart | 전체 | 현재 앱 엔트리포인트 (빈 스켈레톤) |
| docs/003_gemini_deep_research.md | 전체 | PRD 원본 |
| docs/11_tarot_shuffle/001_Scope_platform_strategy.md | 전체 | 플랫폼 전략 Scope |
| docs/11_tarot_shuffle/002_Research_tarot_shuffle_tech.md | 전체 | Research 체크포인트 |
| docs/11_tarot_shuffle/003_Agent_shuffle_engine.md | 관점 1 | 셔플 엔진 상세 조사 |
| docs/11_tarot_shuffle/004_Agent_sensor_rng.md | 관점 2 | 센서/난수 상세 조사 |
| docs/11_tarot_shuffle/005_Agent_data_offline.md | 관점 3 | 데이터/오프라인 상세 조사 |
| docs/11_tarot_shuffle/006_Agent_architecture.md | 관점 4 | 아키텍처 상세 조사 |
| docs/11_tarot_shuffle/007_Synthesis_tarot_shuffle_tech.md | 종합 | Synthesis 보고서 |

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
