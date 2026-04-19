---
id: "mobile-lib-features-settings-domain-repositories-user_settings_repository"
type: explanation
target: "mobile/lib/features/settings/domain/repositories/user_settings_repository.dart"
layer: "file"
version: 1
created: 2026-04-19
updated: 2026-04-19
last_explained_commit: "0336e4c341209b356a3138d22619cde2b7c40eef"
functions: []
---

# user_settings_repository.dart — 해설

## 개요
설정 읽기·쓰기 계약을 정의하는 추상 인터페이스다. 읽기 2개(스트림·단건)와 개별 필드 업데이트 10개, 총 12개 메서드로 구성된다.

## 역할 (Role)
도메인과 데이터 레이어의 경계. UI/provider는 이 인터페이스에만 의존하므로, 구현체(`UserSettingsRepositoryImpl`)를 교체해도 상위 코드가 영향받지 않는다.

## 구조 (Structure)

```dart
abstract class UserSettingsRepository {
  Stream<UserSettings> watchSettings();
  Future<UserSettings> getSettings();
  Future<void> updateSelectedDeckId(String deckId);
  Future<void> updateExperienceLevel(int level);
  Future<void> updateDefaultCardCount(int count);
  Future<void> updateShowFaceUp(bool showFaceUp);
  Future<void> updateQuickDrawEnabled(bool enabled);
  Future<void> updateDefaultSpreadType(String spreadTypeName);
  Future<void> updateShowCardName(bool showCardName);
  Future<void> updateAllowReversed(bool allowReversed);
  Future<void> updateCardSizePreset(String presetName);
  Future<void> updateCustomCardSize(double widthMm, double heightMm);
  Future<void> updateCardsPerRow(int count);
}
```

| 메서드 | 반환 | 역할 |
|--------|------|------|
| `watchSettings` | `Stream<UserSettings>` | 실시간 구독 (Drift watch) |
| `getSettings` | `Future<UserSettings>` | 1회 조회 |
| `updateXxx` (×10) | `Future<void>` | 개별 필드 업데이트 |

## 동작 흐름 (Flow)
1. Riverpod `userSettingsRepositoryProvider` → `UserSettingsRepositoryImpl` 인스턴스 반환
2. `userSettingsProvider` → `repo.watchSettings()` 구독 → `AsyncValue<UserSettings>` 발행
3. UI는 `ref.read(userSettingsRepositoryProvider).updateXxx(value)` 직접 호출로 변경
4. DB 변경 → Drift watch 스트림 발화 → `userSettingsProvider` 자동 갱신

## 의존성 (Dependencies)

| 대상 | 종류 | 역할 |
|------|------|------|
| `UserSettings` | 내부 | 도메인 엔티티 |

## 주의사항 (Caveats)
- `updateDefaultSpreadType`·`updateCardSizePreset`은 `String` 파라미터를 받는다. 열거형 `.name`을 넘겨야 한다 (`SpreadType.custom.name` 등).
- `updateCustomCardSize`만 두 파라미터를 받는 유일한 메서드다.

## Changelog
### v1 (2026-04-19) — 최초 작성
- 최초 해설 문서 생성.
