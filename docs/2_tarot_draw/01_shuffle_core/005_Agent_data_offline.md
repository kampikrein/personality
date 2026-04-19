---
id: "005"
title: "데이터 아키텍처 & 오프라인 기술 조사"
category: agent
status: archived
created: 2026-03-15
summary: >
  Flutter 로컬 DB 5종 비교, 커스텀 덱 JSON 스키마 관리(freezed + json_serializable + json_schema),
  카드 이미지 저장/캐싱/OOM 방지, 오프라인-퍼스트 설계(Repository 패턴 + 동기화 큐 + 충돌 해결)를 조사.
  결론: Drift(관계형 + JSON1) + freezed 모델 + 파일시스템 이미지 관리 + connectivity_plus 기반 동기화 큐.
keywords: [agent-report, database, sqflite, drift, hive, isar, objectbox, offline-first, json-schema, freezed, flutter, image-cache]
modules: [mobile]
---

# 데이터 아키텍처 & 오프라인 기술 조사

## Progress
### Completed
- [x] 로컬 DB 비교 (sqflite vs drift vs hive vs Isar vs ObjectBox)
- [x] 커스텀 덱 JSON 스키마 관리 조사
- [x] 이미지 관리 전략 조사
- [x] 오프라인-퍼스트 설계 조사
### Remaining
(없음)
### Current Status
조사 완료.

---

## Summary

타로 앱의 오프라인-퍼스트 로컬 데이터 관리를 위해 Flutter 로컬 DB 5종, JSON 스키마 직렬화 도구, 이미지 관리 전략, 오프라인-퍼스트 아키텍처 패턴을 조사했다.

**핵심 결론**: **Drift**(타입 안전 SQLite ORM)를 주 DB로, **freezed + json_serializable**로 Dart 모델을 관리하고, 카드 이미지는 **파일시스템 직접 저장 + DB에 경로만 기록**하며, **Repository 패턴 + 동기화 큐 + connectivity_plus**로 오프라인-퍼스트를 구현하는 전략을 권장한다.

---

## Details

### 1. 로컬 DB 비교

#### 1-1. sqflite

| 항목 | 내용 |
|------|------|
| **유형** | SQLite 래퍼 (관계형) |
| **성숙도** | Flutter 초기부터 존재, 가장 오래된 선택지 |
| **장점** | 트랜잭션, 배치, 백그라운드 실행(Android/iOS), raw SQL 직접 사용 가능, 마이그레이션 수동 제어 |
| **단점** | 타입 안전성 없음(raw SQL 문자열), 보일러플레이트 많음, 리액티브 쿼리 미지원 |
| **JSON 적합성** | TEXT 컬럼에 JSON 문자열 저장 가능하나, json1 확장 직접 로드가 복잡 |
| **Flutter 3.10+ 호환** | O |
| **커뮤니티** | 활발, pub.dev likes 5000+ |

**판단**: 단독 사용 시 보일러플레이트가 과다. Drift의 기반 엔진으로 역할하는 것이 최적.

#### 1-2. Drift (구 Moor) -- 권장

| 항목 | 내용 |
|------|------|
| **유형** | 타입 안전 SQLite ORM (코드 생성 기반) |
| **성숙도** | 2019년~, 활발한 유지보수 (작성자 Simon Binder 지속 관리) |
| **장점** | 컴파일 타임 쿼리 검증, 리액티브 스트림(Stream), 자동 마이그레이션 도구, ACID 트랜잭션, 대규모 데이터셋 관리, JSON1/FTS5 확장 내장 지원 |
| **단점** | 코드 생성(build_runner) 필요, 학습 곡선 sqflite보다 높음 |
| **JSON 적합성** | **우수** -- json1 확장으로 JSON 컬럼 쿼리 가능, TypeConverter로 Dart 객체 <-> JSON 자동 변환, v2.24.0부터 JSONB 내장 지원 |
| **마이그레이션** | 스키마 버전 관리 + stepByStep 마이그레이션 자동화, 테스트 도구 내장 |
| **Flutter 3.10+ 호환** | O (크로스 플랫폼: Android, iOS, macOS, Windows, Linux, Web) |
| **커뮤니티** | 활발, GitHub stars 2.5k+, 공식 문서 우수 (drift.simonbinder.eu) |
| **동기화 확장** | PowerSync(drift_sqlite_async) 통합 가능 -- Phase 3 클라우드 동기화 대비 |

**판단**: 타로 앱의 주 DB로 최적. 관계형 쿼리(덱-카드 관계), JSON1 확장(meanings 필드 쿼리), 리액티브 UI 업데이트, 자동 마이그레이션 모두 충족. freezed 모델과 TypeConverter로 자연스럽게 통합.

#### 1-3. Hive / Hive CE

| 항목 | 내용 |
|------|------|
| **유형** | 경량 NoSQL (키-값 박스 기반) |
| **성숙도** | 원본 Hive: 2+ 년간 업데이트 중단, 사실상 deprecated. Hive CE(Community Edition): 커뮤니티 포크, 활발 유지보수 중 |
| **장점** | 순수 Dart 구현, 매우 빠른 읽기/쓰기(메모리 캐시), 암호화 지원, 설정 간편 |
| **단점** | 관계형 쿼리 불가, 복잡한 필터링/정렬 어려움, 대규모 데이터 시 메모리 사용 증가(전체 박스 메모리 로드), 원본 유지보수 불확실 |
| **JSON 적합성** | HiveObject로 단순 구조 저장 가능하나, 중첩 JSON 쿼리 미지원 |
| **Flutter 3.10+ 호환** | O (Hive CE 기준) |
| **커뮤니티** | Hive CE로 이전 중, 원본 대비 축소 |

**판단**: 앱 설정, 사용자 선호도 등 소규모 키-값 데이터에는 적합. 덱/카드의 관계형 데이터 주 저장소로는 부적합. 보조 저장소(설정/캐시)로 병행 사용 가능.

#### 1-4. Isar / Isar Plus

| 항목 | 내용 |
|------|------|
| **유형** | NoSQL (컬렉션 기반, Rust 코어) |
| **성숙도** | 원본: 작성자(Hive와 동일인)가 프로젝트 이탈, 사실상 방치. Isar Plus: 커뮤니티 포크, 유지보수 재개 |
| **장점** | ACID 지원, 풀텍스트 검색, 복합 인덱스, Isolate 지원, 성능 우수 |
| **단점** | Rust 코어로 네이티브 바이너리 의존, 유지보수 불확실성, v4.0이 dev 상태 장기 정체 |
| **JSON 적합성** | 컬렉션 기반으로 JSON 유사 구조 저장 가능, 인덱스 쿼리 강력 |
| **Flutter 3.10+ 호환** | 제한적 (v4 미완성, 커뮤니티 포크에 의존) |
| **커뮤니티** | 분산 (원본 vs Isar Plus), 안정성 불투명 |

**판단**: 유지보수 리스크가 프로덕션 앱에 치명적. 권장하지 않음.

#### 1-5. ObjectBox

| 항목 | 내용 |
|------|------|
| **유형** | NoSQL (객체 기반, C++ 코어) |
| **성숙도** | 상용 제품, 전담 팀 유지보수, v5.2.0 (2026년 초) |
| **장점** | 최고 수준 CRUD 성능(sqflite 대비 70x 쓰기 빠름), Dart API, 관계(ToOne/ToMany) 지원, 내장 동기화(ObjectBox Sync) |
| **단점** | **코어가 오픈소스 아님**(Dart binding만 오픈), Sync는 유료 라이센스, 네이티브 바이너리 의존, 빌드 크기 증가 |
| **JSON 적합성** | 객체 직렬화 자동, 중첩 구조 지원 |
| **Flutter 3.10+ 호환** | O |
| **커뮤니티** | 중간 (상용 제품 특성상 커뮤니티 규모 제한적) |

**판단**: 성능은 최고이나, 클로즈드 소스 코어 + 유료 Sync가 우리 프로젝트(Phase 3에서 Rails API 자체 구축)와 방향 불일치. 비용 및 종속성 리스크.

#### 1-6. DB 비교 요약표

| 기준 | sqflite | **Drift** | Hive CE | Isar Plus | ObjectBox |
|------|---------|-----------|---------|-----------|-----------|
| 타입 안전성 | X | **O** | X | O | O |
| 관계형 쿼리 | O | **O** | X | 제한적 | O |
| 리액티브 스트림 | X | **O** | 제한적 | O | O |
| JSON 쿼리 | 제한적 | **O (json1)** | X | 제한적 | X |
| 마이그레이션 자동화 | X | **O** | X | O | O |
| 유지보수 안정성 | O | **O** | 중간 | **X** | O |
| 오픈소스 | O | **O** | O | O | **X** |
| Phase 3 동기화 대비 | - | **PowerSync** | - | - | 유료 Sync |
| **종합 평점** | B | **A+** | B- | C | B+ |

---

### 2. 커스텀 덱 JSON 스키마 관리

#### 2-1. Dart 모델 직렬화: freezed + json_serializable (권장 조합)

**freezed** (v3.5.0+, 2025 Q2):
- 불변(immutable) 데이터 클래스 자동 생성
- copyWith, == 연산자, hashCode, toString 자동 생성
- sealed class / union type 지원 (TarotCard vs OracleCard 다형성에 이상적)
- json_serializable와 완전 통합 (`@freezed` + `fromJson`/`toJson`)
- Flutter 3.10 + Dart 3.0 완벽 호환

**json_serializable** (v6.x):
- 코드 생성 기반 JSON 직렬화/역직렬화
- 중첩 객체, 리스트, nullable 필드 지원
- `@JsonKey` 어노테이션으로 필드명 매핑 제어

**PRD 스키마 -> Dart 모델 변환 예시 설계:**

```dart
// deck_model.dart
@freezed
class DeckMetadata with _$DeckMetadata {
  const factory DeckMetadata({
    required String id,
    required String name,
    required bool isStandardTarot,
    required int totalCards,
    String? creator,
    // 오프라인-퍼스트 동기화 필드
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(SyncStatus.pending) SyncStatus syncStatus,
  }) = _DeckMetadata;

  factory DeckMetadata.fromJson(Map<String, dynamic> json) =>
      _$DeckMetadataFromJson(json);
}

@freezed
class TarotCard with _$TarotCard {
  const factory TarotCard({
    required String cardId,
    required String name,
    String? suit,            // Optional: Wands, Cups, etc.
    required String imageUrl, // 로컬 파일 경로 또는 원격 URI
    CardMeanings? meanings,
  }) = _TarotCard;

  factory TarotCard.fromJson(Map<String, dynamic> json) =>
      _$TarotCardFromJson(json);
}

@freezed
class CardMeanings with _$CardMeanings {
  const factory CardMeanings({
    @Default([]) List<String> upright,
    @Default([]) List<String> reversed,
    String? customNotes,     // 개인 저널링
  }) = _CardMeanings;

  factory CardMeanings.fromJson(Map<String, dynamic> json) =>
      _$CardMeaningsFromJson(json);
}

enum SyncStatus { synced, pending, conflict }
```

#### 2-2. 런타임 JSON 스키마 유효성 검증

**json_schema** 패키지 (v2.2.1, Workiva 관리):
- JSON Schema Draft 7 지원
- `JsonSchema.create(schemaMap)` -> `schema.validate(instance)` 패턴
- 플랫폼 무관 (Web, Flutter, VM)
- 커스텀 덱 Import 시 스키마 무결성 검증에 활용 가능

**json_typedef_dart** (RFC 8927):
- JSON Type Definition 표준 기반
- json_schema 대비 경량, 빠른 검증
- 코드 생성 지원

**권장**: 커스텀 덱 Import/Export 시 `json_schema`로 런타임 유효성 검증. 내부 데이터 흐름은 freezed 모델의 컴파일 타임 타입 안전성에 의존.

#### 2-3. 관계형 vs 문서형 저장 전략

**하이브리드 접근 (권장)**:

```
[decks 테이블] 1 --- N [cards 테이블]
     |                      |
     |-- metadata (컬럼)     |-- card_id, name, suit, image_path (컬럼)
     |-- is_standard_tarot  |-- meanings (JSON 컬럼 via TypeConverter)
     |-- sync_status        |-- custom_notes (TEXT)
```

- **덱-카드 관계**: 관계형(외래키)으로 관리 -> Drift의 JOIN, WHERE 쿼리 활용
- **meanings 필드**: JSON 컬럼(TypeConverter)으로 저장 -> 유연한 구조 허용
  - upright/reversed 키워드 배열의 가변 길이 수용
  - json1 확장으로 JSON 내부 쿼리 가능 (예: "사랑" 키워드 포함 카드 검색)
- **장점**: 관계형의 무결성 + JSON의 유연성 동시 확보
- **Drift TypeConverter 활용**: `CardMeanings` freezed 모델을 JSON TEXT로 자동 변환

---

### 3. 이미지 관리 전략

#### 3-1. 저장 아키텍처: DB 경로 참조 + 파일시스템 직접 관리

```
앱 디렉토리 (path_provider)
├── app_documents/
│   └── decks/
│       ├── {deck_id}/
│       │   ├── originals/     ← 원본 이미지
│       │   │   ├── card_001.webp
│       │   │   └── card_002.webp
│       │   └── thumbnails/    ← 생성된 썸네일
│       │       ├── card_001_thumb.webp
│       │       └── card_002_thumb.webp
│       └── {deck_id_2}/
│           └── ...
└── cache/                     ← 임시 캐시
```

- DB(cards 테이블)에는 **상대 경로만** 저장: `decks/{deck_id}/originals/card_001.webp`
- 절대 경로는 런타임에 `path_provider`의 `getApplicationDocumentsDirectory()`와 조합
- 장점: DB 크기 최소화, 이미지 독립적 백업/이동 가능, 파일시스템 직접 접근으로 성능 최적

#### 3-2. 이미지 리사이징 & 압축 (OOM 방지)

**flutter_image_compress** 패키지:
- 네이티브 코드로 압축 (Android: Kotlin, iOS: Objective-C)
- 주요 파라미터: `minWidth`, `minHeight` (리사이징), `quality` (0-100)
- WebP 출력 지원 (PNG 대비 30-50% 파일 크기 감소)

**대량 업로드 시 OOM 방지 전략:**

1. **Isolate 분리 처리**: `compute()` 함수로 이미지 리사이징을 별도 Isolate에서 실행
2. **순차 배치 처리**: 78장을 한번에 로드하지 않고, 5-10장 단위 배치로 처리
3. **해상도 제한**: 카드 이미지 최대 해상도를 1024x1536px (타로 카드 비율 2:3)로 제한
4. **WebP 강제 변환**: 업로드 시점에 WebP로 통일 (quality 85)
5. **썸네일 사전 생성**: 원본 저장과 동시에 300x450px 썸네일 자동 생성

**처리 파이프라인:**
```
사용자 이미지 선택 (다중)
  → 배치 분할 (5-10장씩)
  → Isolate에서 순차 처리:
      → 리사이징 (max 1024x1536)
      → WebP 변환 (quality 85)
      → 썸네일 생성 (300x450)
      → 파일시스템 저장
      → DB 경로 기록
  → UI 진행률 업데이트 (Stream)
  → 완료
```

#### 3-3. 메모리 최적화 (78장+ 카드 동시 표시)

| 전략 | 구현 방법 |
|------|----------|
| **Lazy Loading** | `GridView.builder`로 뷰포트 내 카드만 로드 |
| **cacheWidth/cacheHeight** | `Image.file()`에 `cacheWidth: 300` 지정 -> 디코딩 시 축소 |
| **썸네일 우선 표시** | 목록/그리드에서는 썸네일만 표시, 상세 보기에서 원본 로드 |
| **ImageCache 크기 제한** | `PaintingBinding.instance.imageCache.maximumSize = 50` |
| **메모리 해제** | 화면 이탈 시 `imageCache.evict(key)` 명시 호출 |
| **Progressive 로딩** | 블러 해시(blurhash) 플레이스홀더 → 썸네일 → 원본 |

#### 3-4. 패키지 선택

| 용도 | 패키지 | 비고 |
|------|--------|------|
| 로컬 경로 | **path_provider** | 앱 문서 디렉토리 접근 |
| 이미지 압축 | **flutter_image_compress** | 네이티브 압축, WebP 지원 |
| 네트워크 이미지 캐싱 | **cached_network_image** | Phase 3 클라우드 이미지에 활용 |
| 이미지 선택 | **image_picker** / **file_picker** | 갤러리/파일 다중 선택 |

---

### 4. 오프라인-퍼스트 설계

#### 4-1. 핵심 원칙

Flutter 공식 아키텍처 가이드 (`docs.flutter.dev/app-architecture/design-patterns/offline-first`)에서 제시하는 원칙:

1. **로컬 DB가 단일 진실의 원천(Single Source of Truth)**
2. **모든 읽기/쓰기는 로컬 DB를 통해 수행**
3. **네트워크는 enhancement, not prerequisite**
4. **동기화는 백그라운드에서 비동기 처리**

#### 4-2. Repository 패턴 구현

```
UI Layer (Widget)
    │
    ▼
State Management (Riverpod / BLoC)
    │
    ▼
Repository (단일 접근점)
    ├── LocalDataSource (Drift DB)      ← 항상 사용
    └── RemoteDataSource (Rails API)    ← 네트워크 가용 시만
```

- Repository가 로컬/원격 데이터 소스를 추상화
- UI는 네트워크 상태를 인지할 필요 없음
- Phase 1-2: LocalDataSource만 구현, RemoteDataSource는 인터페이스만 정의
- Phase 3: RemoteDataSource 구현 + 동기화 로직 추가

#### 4-3. 데이터 모델 동기화 대비 필드

모든 엔티티에 공통 필드 포함:

```dart
// 모든 동기화 대상 엔티티의 공통 mixin
mixin SyncableEntity {
  DateTime get createdAt;
  DateTime get updatedAt;
  SyncStatus get syncStatus;  // synced | pending | conflict
  String? get remoteId;       // 서버 측 ID (Phase 3)
  int get version;            // 낙관적 잠금용 버전 번호
}
```

Drift 테이블 정의 시:
```dart
class Decks extends Table {
  TextColumn get id => text()();           // UUID (로컬 생성)
  TextColumn get remoteId => text().nullable()();  // 서버 ID
  TextColumn get name => text()();
  BoolColumn get isStandardTarot => boolean()();
  IntColumn get totalCards => integer()();
  TextColumn get creator => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get syncStatus => intEnum<SyncStatus>()();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}
```

#### 4-4. 네트워크 상태 감지

**connectivity_plus** 패키지:
- WiFi, 모바일, 이더넷, VPN, Bluetooth, 없음 상태 감지
- `Connectivity().onConnectivityChanged` 스트림으로 실시간 감지
- 주의: 연결 상태만 감지, 실제 인터넷 접근 가능 여부는 별도 확인 필요

```dart
// 실제 인터넷 연결 확인
Future<bool> hasInternetAccess() async {
  try {
    final result = await InternetAddress.lookup('example.com');
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } on SocketException catch (_) {
    return false;
  }
}
```

#### 4-5. 동기화 큐 (Phase 3 대비 설계)

```
[sync_queue 테이블]
  - id (PK)
  - entity_type (deck | card | reading)
  - entity_id
  - operation (create | update | delete)
  - payload (JSON)
  - created_at
  - retry_count
  - status (pending | processing | failed | completed)
```

동기화 흐름:
```
1. 로컬 CRUD 발생
   → DB 즉시 반영
   → sync_queue에 작업 추가 (status: pending)

2. 네트워크 복구 감지 (connectivity_plus)
   → sync_queue에서 pending 작업 순차 처리
   → Rails API 호출
   → 성공: status → completed, syncStatus → synced
   → 실패: retry_count++, 3회 초과 시 status → failed

3. 주기적 폴링 (30초 간격, configurable)
   → 서버 변경사항 pull
   → 충돌 감지 시 해결 전략 적용
```

#### 4-6. 충돌 해결 전략

| 전략 | 설명 | 적합한 상황 |
|------|------|------------|
| **Last-Write-Wins (LWW)** | `updatedAt` 타임스탬프 비교, 최신 쓰기 우선 | 단일 사용자 다중 기기 (우리 앱 주 시나리오) |
| **필드 레벨 병합** | 변경된 필드만 비교하여 병합 | custom_notes 등 독립 필드 |
| **사용자 선택** | 충돌 시 UI에서 사용자에게 선택 요청 | 커스텀 덱 메타데이터 변경 |
| **CRDT** | 분산 합의 알고리즘 (자동 수렴) | 실시간 협업 (현재 불필요) |

**권장**: Phase 3에서 **LWW + 필드 레벨 병합** 조합. 단일 사용자 시나리오에서 CRDT는 과도한 복잡성. 커스텀 덱 메타데이터 충돌 시에만 사용자 선택 UI 제공.

#### 4-7. PowerSync 대안 검토

PowerSync: SQLite 기반 동기화 엔진, Postgres/MongoDB/MySQL 지원.
- Drift와 통합 가능 (drift_sqlite_async 패키지)
- 로컬 SQLite <-> 클라우드 DB 자동 동기화
- 우리 프로젝트: Phase 3에서 Rails API(PostgreSQL) 직접 구축 예정
- **판단**: Rails API 자체 구축 방향이므로 PowerSync 도입은 과도. 단, 동기화 구현 난도가 예상 초과 시 대안으로 재검토 가능.

#### 4-8. 리딩 히스토리 (스프레드 스냅샷) 저장

```dart
@freezed
class ReadingSnapshot with _$ReadingSnapshot {
  const factory ReadingSnapshot({
    required String id,
    required String deckId,
    required String spreadType,     // single, three_card, celtic_cross
    required List<DrawnCard> cards,  // 카드 위치 + 방향 + 선택된 카드
    String? question,               // 사용자 질문
    String? emotion,                // 감정 태그
    String? interpretation,         // 개인 해석 노트
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(SyncStatus.pending) SyncStatus syncStatus,
  }) = _ReadingSnapshot;
}

@freezed
class DrawnCard with _$DrawnCard {
  const factory DrawnCard({
    required String cardId,
    required int position,         // 스프레드 내 위치 (0-9)
    required bool isReversed,      // 역방향 여부
    required String deckId,        // 하이브리드 리딩 시 출처 덱
  }) = _DrawnCard;
}
```

Drift 테이블: `readings` (메타데이터) + `drawn_cards` (관계형) 또는 `cards` 필드를 JSON 컬럼으로 저장.

---

## Key Findings

1. **Drift가 압도적 최적 선택**: 타입 안전성, 리액티브 쿼리, JSON1 확장, 마이그레이션 자동화, PowerSync 통합 가능성까지 모든 요구사항 충족. sqflite 위에 구축되므로 SQLite의 검증된 안정성도 확보.

2. **Hive/Isar는 주 DB로 부적합**: 관계형 쿼리 부재(Hive), 유지보수 불확실성(Isar). Hive CE는 설정/캐시 등 보조 저장소로만 활용 가능.

3. **ObjectBox는 성능 최고이나 종속성 리스크**: 클로즈드 소스 코어, 유료 Sync가 자체 Rails API 구축 방향과 충돌.

4. **freezed + json_serializable이 Dart 모델 표준**: 불변 모델, 타입 안전 직렬화, sealed class 다형성 모두 지원. Drift TypeConverter와 자연스럽게 통합.

5. **이미지는 DB 외부 파일시스템에 저장**: DB에 경로만 기록. flutter_image_compress + Isolate 배치 처리로 OOM 방지. WebP 포맷 + 썸네일 사전 생성이 핵심.

6. **오프라인-퍼스트는 Phase 1부터 설계**: Repository 패턴 + syncStatus/updatedAt 필드를 초기부터 포함. Phase 3에서 동기화 큐 + LWW 충돌 해결로 자연스럽게 확장.

---

## Recommendations

### Phase 1 (MVP) 기술 스택

| 레이어 | 기술 | 패키지 |
|--------|------|--------|
| **로컬 DB** | Drift (SQLite) | `drift`, `drift_dev`, `sqlite3_flutter_libs` |
| **Dart 모델** | freezed + json_serializable | `freezed`, `freezed_annotation`, `json_serializable`, `json_annotation` |
| **코드 생성** | build_runner | `build_runner` |
| **이미지 압축** | flutter_image_compress | `flutter_image_compress` |
| **파일 경로** | path_provider | `path_provider` |
| **이미지 선택** | file_picker | `file_picker` |
| **네트워크 감지** | connectivity_plus | `connectivity_plus` |
| **보조 캐시** | (선택) Hive CE | `hive_ce`, `hive_ce_flutter` |

### Phase 3 (클라우드 동기화) 추가 기술

| 레이어 | 기술 | 패키지 |
|--------|------|--------|
| **네트워크 이미지** | cached_network_image | `cached_network_image` |
| **JSON 스키마 검증** | json_schema | `json_schema` (Import/Export 시) |
| **동기화 엔진** | 자체 구현 (sync_queue) | 커스텀 |
| **대안** | PowerSync (난도 초과 시) | `powersync`, `drift_sqlite_async` |

### 설계 원칙

1. **Repository 패턴 필수**: 모든 데이터 접근은 Repository를 통해. UI/비즈니스 로직이 DB 구현에 직접 의존하지 않도록.
2. **동기화 필드 초기부터 포함**: `createdAt`, `updatedAt`, `syncStatus`, `version`을 Phase 1 테이블에 포함. Phase 3 마이그레이션 비용 최소화.
3. **이미지 파이프라인 표준화**: 업로드 → 리사이징 → WebP 변환 → 썸네일 생성 → 파일시스템 저장 → DB 경로 기록. 이 순서를 Isolate에서 배치 실행.
4. **JSON 하이브리드 저장**: 덱/카드 관계는 관계형, meanings/drawn_cards 등 유연한 필드는 JSON 컬럼. Drift json1 확장으로 쿼리 가능성 유지.

---

## References

### 공식 문서
- [Flutter 오프라인-퍼스트 가이드](https://docs.flutter.dev/app-architecture/design-patterns/offline-first)
- [Drift 공식 문서](https://drift.simonbinder.eu/)
- [Drift JSON1 확장](https://drift.simonbinder.eu/sql_api/extensions/)
- [Drift TypeConverter](https://drift.simonbinder.eu/type_converters/)
- [freezed 패키지](https://pub.dev/packages/freezed)
- [json_serializable 패키지](https://pub.dev/packages/json_serializable)
- [json_schema 패키지](https://pub.dev/packages/json_schema)
- [flutter_image_compress 패키지](https://pub.dev/packages/flutter_image_compress)
- [connectivity_plus 패키지](https://pub.dev/packages/connectivity_plus)
- [cached_network_image 패키지](https://pub.dev/packages/cached_network_image)

### DB 비교 분석
- [Flutter databases overview 2025 (greenrobot.org)](https://greenrobot.org/database/flutter-databases-overview/)
- [Best Local Database for Flutter Apps (Dinko Marinac)](https://dinkomarinac.dev/best-local-database-for-flutter-apps-a-complete-guide)
- [Hive vs Drift vs Floor vs Isar 2025 (Quash)](https://quashbugs.com/blog/hive-vs-drift-vs-floor-vs-isar-2025)
- [Flutter Database Comparison (PowerSync)](https://www.powersync.com/blog/flutter-database-comparison-sqlite-async-sqflite-objectbox-isar)
- [ObjectBox Flutter 공식](https://objectbox.io/flutter-database/)
- [SQLite vs Hive Benchmark (Medium)](https://medium.com/full-struggle-developer/flutter-benchmark-tuesday-sqlite-vs-hive-how-popular-articles-deceive-us-cf6bbc0c7f93)

### Isar 상태
- [Isar GitHub (원본)](https://github.com/isar/isar)
- [Isar Plus (커뮤니티 포크)](https://pub.dev/packages/isar_plus)
- [Hive CE (커뮤니티 에디션)](https://pub.dev/packages/hive_ce)

### 오프라인-퍼스트 & 동기화
- [Offline-First Architecture Part 1 (DEV Community)](https://dev.to/anurag_dev/implementing-offline-first-architecture-in-flutter-part-1-local-storage-with-conflict-resolution-4mdl)
- [Offline-First Architecture Part 2 (DEV Community)](https://dev.to/anurag_dev/implementing-offline-first-architecture-in-flutter-part-2-building-sync-mechanisms-and-handling-4mb1)
- [Building Offline-First Apps with Conflict Resolution (Vibe Studio)](https://vibe-studio.ai/insights/building-offline-first-apps-with-conflict-resolution-logic)
- [PowerSync + Drift 통합 (Dinko Marinac)](https://dinkomarinac.dev/blog/building-local-first-flutter-apps-with-riverpod-drift-and-powersync/)

### 이미지 최적화
- [Flutter Memory 375MB 절감 사례 (Medium)](https://saropa-contacts.medium.com/how-we-reduced-flutter-memory-usage-by-375mb-image-optimization-strategies-5a097246ee0c)
- [Flutter Image Optimization (Alibaba)](https://www.alibabacloud.com/blog/xianyus-flutter-image-optimization-from-native-code-to-advanced-technology_596476)
- [Optimizing Image Loading in Flutter (Vibe Studio)](https://vibe-studio.ai/insights/optimizing-image-loading-and-caching-in-flutter-apps)

### 프로젝트 내부 참조
- `docs/003_gemini_deep_research.md` — PRD (deck.json 스키마 원본, 섹션 4.1)
- `docs/11_tarot_shuffle/001_Scope_platform_strategy.md` — 플랫폼 전략 (Phase 1-4 로드맵)

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
