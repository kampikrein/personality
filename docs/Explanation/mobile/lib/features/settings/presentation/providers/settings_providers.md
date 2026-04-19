---
id: "mobile-lib-features-settings-presentation-providers-settings_providers"
type: explanation
target: "mobile/lib/features/settings/presentation/providers/settings_providers.dart"
layer: "file"
version: 1
created: 2026-04-19
updated: 2026-04-19
last_explained_commit: "0336e4c341209b356a3138d22619cde2b7c40eef"
functions: []
---

# settings_providers.dart — 해설

## 개요
설정 기능의 Riverpod 진입점. Repository 인스턴스 provider, 설정 스트림 provider, 카드 종횡비 파생 provider 세 개를 정의한다.

## 역할 (Role)
UI와 Repository 사이의 접착제. 화면에서 `ref.watch(userSettingsProvider)`만 호출하면 DB 스트림이 연결되고, `ref.read(userSettingsRepositoryProvider).updateXxx()`로 변경한다. `cardAspectRatioProvider`는 카드 렌더링 위젯이 직접 종횡비를 구독할 수 있도록 한다.

## 구조 (Structure)

```dart
// 1. Repository 인스턴스 (keepAlive — 앱 수명 내내 유지)
@Riverpod(keepAlive: true)
UserSettingsRepository userSettingsRepository(ref) { ... }

// 2. 설정 스트림 (auto-dispose)
@riverpod
Stream<UserSettings> userSettings(ref) {
  return repo.watchSettings();
}

// 3. 카드 종횡비 파생값 (auto-dispose)
@riverpod
double cardAspectRatio(ref) {
  return settings?.cardAspectRatio ?? (70.0 / 120.0);
}
```

| Provider | 타입 | keepAlive | 역할 |
|----------|------|-----------|------|
| `userSettingsRepositoryProvider` | `UserSettingsRepository` | ✓ | Repository 싱글턴 |
| `userSettingsProvider` | `AsyncValue<UserSettings>` | ✗ | 설정 스트림 |
| `cardAspectRatioProvider` | `double` | ✗ | 종횡비 파생값 |

## 동작 흐름 (Flow)
1. `appDatabaseProvider`로 DB 인스턴스 획득 → `UserSettingsRepositoryImpl` 생성
2. `userSettingsProvider` 구독 → `watchSettings()` 스트림 연결 → `AsyncValue<UserSettings>` 발행
3. DB 변경 발생 → 스트림 갱신 → `userSettingsProvider` 자동 리빌드
4. `cardAspectRatioProvider` — `userSettingsProvider` 변경 시 자동 재계산, 기본값 `70/120 ≈ 0.583`

## 의존성 (Dependencies)

| 대상 | 종류 | 역할 |
|------|------|------|
| `appDatabaseProvider` | 내부(core) | Drift DB provider |
| `UserSettingsRepositoryImpl` | 내부(data) | 구현체 |
| `UserSettingsRepository` | 내부(domain) | 인터페이스 타입 |
| `UserSettings` | 내부(domain) | 반환 엔티티 |
| `riverpod_annotation` | external | 코드 생성 어노테이션 |

## 주의사항 (Caveats)
- `userSettingsRepositoryProvider`가 `keepAlive: true`이므로, 앱 실행 중 폐기되지 않는다. 테스트에서 override 시 명시적으로 제공해야 한다.
- `cardAspectRatioProvider`의 기본값(`70/120`)은 설정 로드 전 첫 프레임에만 적용된다. 로딩 중 카드 렌더링 위젯이 잘못된 비율로 깜박일 수 있다.

## Changelog
### v1 (2026-04-19) — 최초 작성
- 최초 해설 문서 생성.
