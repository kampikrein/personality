---
id: "mobile-lib-features-settings-_overview"
type: explanation
target: "mobile/lib/features/settings/"
layer: "folder"
version: 1
created: 2026-04-19
updated: 2026-04-19
last_explained_commit: "0336e4c341209b356a3138d22619cde2b7c40eef"
functions: []
---

# settings/ — 해설

## 개요
사용자 설정 전체를 관리하는 피처 모듈이다. 덱 선택·체험 레벨·카드 수·스프레드 타입·역방향 허용·카드 크기 등 뽑기 경험 전반의 설정을 Drift DB에 영속화하고 Riverpod으로 반응형 제공한다.

## 역할 (Role)
앱 전역 설정의 단일 진실 원천. `userSettingsProvider`가 홈 탭·결과 페이지·카드 렌더러 등 여러 피처에서 구독되며, 설정 변경은 `userSettingsRepositoryProvider`를 통해 즉시 DB에 반영된다.

## 구조 (Structure)

```
settings/
├── domain/
│   ├── entities/          — UserSettings (freezed), CardSizePreset (enum)
│   └── repositories/      — UserSettingsRepository (abstract)
├── data/
│   └── repositories/      — UserSettingsRepositoryImpl (Drift)
└── presentation/
    ├── providers/          — userSettingsRepositoryProvider, userSettingsProvider, cardAspectRatioProvider
    └── pages/              — SettingsPage (placeholder), CardSizeSettingsPage (완성)
```

클린 아키텍처 레이어 구조:

| 레이어 | 역할 | 프레임워크 의존 |
|--------|------|----------------|
| `domain/` | 타입·계약 정의 | 없음 |
| `data/` | Drift DB 연동 | Drift |
| `presentation/` | Riverpod + Flutter UI | Riverpod, Flutter |

## 동작 흐름 (Flow)

### 읽기 (설정 구독)
```
appDatabaseProvider
  → userSettingsRepositoryProvider (keepAlive)
  → userSettingsProvider (Stream<UserSettings>)
  → AsyncValue<UserSettings> → UI
```

### 쓰기 (설정 변경)
```
UI.onChanged
  → ref.read(userSettingsRepositoryProvider).updateXxx(value)
  → UserSettingsRepositoryImpl.updateXxx
  → db.userSettingsDao.updateSettings(Companion(...))
  → Drift watch 스트림 발화 → userSettingsProvider 갱신 → UI 리빌드
```

### 카드 크기 설정 흐름
```
홈 탭 "카드 크기" 탭 → /settings/card-size → CardSizeSettingsPage
  → 프리셋 선택 → updateCardSizePreset(preset.name)
  → custom 선택 시 → mm 입력 → _applyCustomSize → updateCustomCardSize(w, h)
  → cardAspectRatioProvider 자동 갱신 → 카드 렌더러 즉시 반영
```

## 의존성 (Dependencies)

| 대상 | 종류 | 역할 |
|------|------|------|
| `AppDatabase` / `appDatabaseProvider` | 내부(core) | Drift DB 인스턴스 |
| `SpreadType` | 내부(reading/domain) | UserSettings 필드 타입 |
| `MysticalScaffold`, `MysticalCard` 등 | 내부(core/widgets) | 공통 UI 컴포넌트 |
| `freezed_annotation` | external | 불변 클래스 코드 생성 |
| `riverpod_annotation` | external | Provider 코드 생성 |
| `drift` | external | DB companion/value 타입 |

## 주의사항 (Caveats)
- **피처 간 결합**: `UserSettings`가 `reading` 피처의 `SpreadType`에 의존한다.
- **설정 즉시 저장**: 모든 변경이 별도 저장 버튼 없이 즉시 DB에 기록된다. 실수 취소 수단 없음.
- **`quickDrawEnabled` 미사용 필드**: DB와 도메인 모델에 존재하지만 현재 어떤 UI에도 노출되지 않는다.
- **`SettingsPage` 플레이스홀더**: `/settings` 라우트는 내용이 없으며, 뽑기 설정은 홈 탭에 인라인으로 존재한다. 두 진입점의 역할이 분리되어 있다.
- **`cardAspectRatioProvider` 기본값**: 설정 로드 전 `70/120 ≈ 0.583`을 반환한다.

## 하위 구성 (Contents)
| 구분 | 대상 | 해설 문서 | 한 줄 요약 |
|------|------|----------|-----------|
| 폴더 | `domain/` | [overview](domain/_overview.md) | 값 객체·인터페이스 순수 도메인 계층 |
| 폴더 | `data/` | [overview](data/_overview.md) | Drift 기반 영속화 계층 |
| 폴더 | `presentation/` | [overview](presentation/_overview.md) | Riverpod provider + 설정 화면 |

## Changelog
### v1 (2026-04-19) — 최초 작성
- 최초 해설 문서 생성.
