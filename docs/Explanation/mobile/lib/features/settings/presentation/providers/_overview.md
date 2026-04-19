---
id: "mobile-lib-features-settings-presentation-providers-_overview"
type: explanation
target: "mobile/lib/features/settings/presentation/providers/"
layer: "folder"
version: 1
created: 2026-04-19
updated: 2026-04-19
last_explained_commit: "0336e4c341209b356a3138d22619cde2b7c40eef"
functions: []
---

# settings/presentation/providers/ — 해설

## 개요
설정 UI의 Riverpod 진입점 3개를 정의한다. Repository 싱글턴, 설정 스트림, 카드 종횡비 파생값으로 구성된다.

## 역할 (Role)
UI가 설정을 읽고 쓰기 위한 단일 접점. `userSettingsProvider`로 현재 설정을 구독하고, `userSettingsRepositoryProvider`로 변경한다.

## 구조 (Structure)

| 파일 | 제공 provider | 역할 |
|------|-------------|------|
| `settings_providers.dart` | `userSettingsRepositoryProvider` | Repository 싱글턴 |
| | `userSettingsProvider` | `AsyncValue<UserSettings>` 스트림 |
| | `cardAspectRatioProvider` | 종횡비 파생 `double` |

## 동작 흐름 (Flow)
DB 변경 → `watchSettings` 스트림 발화 → `userSettingsProvider` 갱신 → 구독 위젯 리빌드

## 의존성 (Dependencies)

| 대상 | 종류 | 역할 |
|------|------|------|
| `appDatabaseProvider` | 내부(core) | DB 인스턴스 |
| `UserSettingsRepositoryImpl` | 내부(data) | 구현체 |

## 주의사항 (Caveats)
- `userSettingsRepositoryProvider`는 `keepAlive: true`로 앱 수명 내내 유지된다.

## 하위 구성 (Contents)
| 구분 | 대상 | 해설 문서 | 한 줄 요약 |
|------|------|----------|-----------|
| 파일 | `settings_providers.dart` | [해설](settings_providers.md) | 설정 Repository·스트림·종횡비 provider 3개 |

## Changelog
### v1 (2026-04-19) — 최초 작성
- 최초 해설 문서 생성.
