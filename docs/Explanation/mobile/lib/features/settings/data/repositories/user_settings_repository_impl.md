---
id: "mobile-lib-features-settings-data-repositories-user_settings_repository_impl"
type: explanation
target: "mobile/lib/features/settings/data/repositories/user_settings_repository_impl.dart"
layer: "file"
version: 1
created: 2026-04-19
updated: 2026-04-19
last_explained_commit: "0336e4c341209b356a3138d22619cde2b7c40eef"
functions: []
---

# user_settings_repository_impl.dart — 해설

## 개요
`UserSettingsRepository` 인터페이스의 Drift 기반 구현체다. 모든 업데이트를 `UserSettingsTableCompanion`으로 패치하고, DB Row를 `UserSettings` 도메인 객체로 변환하는 `_toDomain` 매퍼를 포함한다.

## 역할 (Role)
설정 영속화의 단일 책임. `AppDatabase.userSettingsDao`를 래핑하여 도메인 언어(`updateExperienceLevel`)를 DB 언어(`UserSettingsTableCompanion`)로 번역한다.

## 구조 (Structure)

```dart
class UserSettingsRepositoryImpl implements UserSettingsRepository {
  final AppDatabase db;
  // watchSettings, getSettings — 읽기
  // updateXxx × 10 — 필드별 패치
  // _toDomain(UserSettingsTableData) → UserSettings — 매퍼
}
```

업데이트 패턴 (전형적 예):
```dart
Future<void> updateExperienceLevel(int level) async {
  await db.userSettingsDao.updateSettings(
    UserSettingsTableCompanion(experienceLevel: Value(level)),
  );
}
```

특수 케이스 — `updateCustomCardSize`:
```dart
await db.userSettingsDao.updateSettings(
  UserSettingsTableCompanion(
    cardSizePreset: const Value('custom'),  // preset도 함께 변경
    customCardWidthMm: Value(widthMm),
    customCardHeightMm: Value(heightMm),
  ),
);
```

`_toDomain` 매퍼 변환 포인트:
- `defaultSpreadType` — `SpreadType.values.byName(row.defaultSpreadType)`
- `cardSizePreset` — `firstWhere(name == ..., orElse: standardTarot)`
- `showCardName`, `allowReversed` — `?? true` null 방어

## 동작 흐름 (Flow)
1. `userSettingsRepositoryProvider` 생성 → `UserSettingsRepositoryImpl(db: appDatabase)` 반환
2. `watchSettings()` → `db.userSettingsDao.watchSettings().map(_toDomain)` — Drift watch 스트림 위임
3. `updateXxx()` → `db.userSettingsDao.updateSettings(Companion(...))` → Drift가 단건 upsert 실행
4. upsert 완료 → watch 스트림 자동 발화 → `userSettingsProvider` 갱신 → UI 리빌드

## 의존성 (Dependencies)

| 대상 | 종류 | 역할 |
|------|------|------|
| `AppDatabase` | 내부(core) | Drift DB 인스턴스 |
| `UserSettingsRepository` | 내부(domain) | 구현 대상 인터페이스 |
| `UserSettings` | 내부(domain) | 도메인 엔티티 |
| `CardSizePreset` | 내부(domain) | 프리셋 역직렬화 |
| `SpreadType` | 내부(reading) | 스프레드 타입 역직렬화 |
| `drift` | external | DB companion/value 타입 |

## 주의사항 (Caveats)
- `showCardName`, `allowReversed` 컬럼이 nullable(`?? true`)인 것은 스키마 마이그레이션 미적용 기기 호환성 때문이다.
- `updateCustomCardSize`는 `cardSizePreset`을 강제로 `'custom'`으로 변경한다. 커스텀 크기 저장 = 프리셋도 custom으로 전환.
- `_toDomain`에서 `cardSizePreset`이 알 수 없는 문자열이면 `standardTarot`으로 폴백한다 (DB 마이그레이션 불일치 방어).

## Changelog
### v1 (2026-04-19) — 최초 작성
- 최초 해설 문서 생성.
