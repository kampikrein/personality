---
id: "mobile-lib-features-settings-domain-entities-user_settings"
type: explanation
target: "mobile/lib/features/settings/domain/entities/user_settings.dart"
layer: "file"
version: 1
created: 2026-04-19
updated: 2026-04-19
last_explained_commit: "0336e4c341209b356a3138d22619cde2b7c40eef"
functions: []
---

# user_settings.dart — 해설

## 개요
앱 전체 사용자 설정을 담는 불변 값 객체(freezed)다. 덱 선택·체험 레벨·카드 수·스프레드 타입·역방향 허용·카드 크기 등 뽑기 경험 전반을 제어하는 13개 필드를 하나로 묶는다.

## 역할 (Role)
설정의 도메인 표현. DB Row(`UserSettingsTableData`)와 UI 사이의 경계를 정의하며, `cardAspectRatio` 게터를 통해 렌더링에 필요한 파생값도 직접 제공한다. `UserSettingsRepository`가 이 타입을 Stream으로 발행하고, Riverpod `userSettingsProvider`가 UI에 전달한다.

## 구조 (Structure)

```dart
@freezed
class UserSettings with _$UserSettings {
  const factory UserSettings({
    @Default('rws-standard') String selectedDeckId,
    @Default(4) int experienceLevel,       // 1=즉시 2=연출 3=2D 4=2.5D
    @Default(3) int defaultCardCount,
    @Default(false) bool showFaceUp,
    @Default(false) bool quickDrawEnabled,
    @Default(SpreadType.custom) SpreadType defaultSpreadType,
    @Default(true) bool showCardName,
    @Default(true) bool allowReversed,
    @Default(3) int cardsPerRow,
    @Default(CardSizePreset.standardTarot) CardSizePreset cardSizePreset,
    @Default(70.0) double customCardWidthMm,
    @Default(120.0) double customCardHeightMm,
    required DateTime updatedAt,
  }) = _UserSettings;

  double get cardAspectRatio => ...;
  factory UserSettings.fromJson(...) => ...;
}
```

| 필드 | 기본값 | 의미 |
|------|--------|------|
| `selectedDeckId` | `'rws-standard'` | 활성 덱 ID |
| `experienceLevel` | `4` | 뽑기 플로우 depth (1~4) |
| `defaultCardCount` | `3` | 한 번 뽑을 카드 수 |
| `showFaceUp` | `false` | 앞면으로 시작 여부 |
| `quickDrawEnabled` | `false` | 즉시 뽑기 활성화 (현재 미사용) |
| `defaultSpreadType` | `SpreadType.custom` | 기본 스프레드 |
| `showCardName` | `true` | 카드 이름 표시 |
| `allowReversed` | `true` | 역방향 허용 |
| `cardsPerRow` | `3` | 결과 그리드 열 수 |
| `cardSizePreset` | `standardTarot` | 카드 크기 프리셋 |
| `customCardWidthMm/HeightMm` | `70/120` | 커스텀 크기 (preset=custom 시 사용) |
| `updatedAt` | required | 최종 수정 시각 |

## 동작 흐름 (Flow)
1. 앱 시작 → `UserSettingsRepositoryImpl.watchSettings()` → DB에서 Row 읽기
2. `_toDomain(row)` → `UserSettings` 생성 (SpreadType·CardSizePreset은 name 문자열로 역직렬화)
3. Riverpod `userSettingsProvider` 스트림으로 UI 구독
4. UI 변경 → `UserSettingsRepository.updateXxx()` 직접 호출 → DB 패치 → 스트림 재발행 → UI 자동 갱신

## 의존성 (Dependencies)

| 대상 | 종류 | 역할 |
|------|------|------|
| `freezed_annotation` | external | 불변 클래스 코드 생성 |
| `SpreadType` | 내부 | 스프레드 타입 열거형 |
| `CardSizePreset` | 내부 | 카드 크기 프리셋 열거형 |

## 주의사항 (Caveats)
- `quickDrawEnabled` 필드가 존재하지만 현재 어떤 화면에서도 노출되지 않는다 (dead field).
- `updatedAt`은 `required`이므로 생성 시 항상 명시해야 한다. DB DAO가 관리한다.
- Freezed로 생성된 `.freezed.dart`·`.g.dart`를 직접 편집하지 말 것.

## Changelog
### v1 (2026-04-19) — 최초 작성
- 최초 해설 문서 생성.
