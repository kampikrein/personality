---
id: "mobile-lib-features-settings-data-repositories-_overview"
type: explanation
target: "mobile/lib/features/settings/data/repositories/"
layer: "folder"
version: 1
created: 2026-04-19
updated: 2026-04-19
last_explained_commit: "0336e4c341209b356a3138d22619cde2b7c40eef"
functions: []
---

# settings/data/repositories/ — 해설

## 개요
`UserSettingsRepository` 인터페이스의 Drift 기반 구현체를 담는다. DB Row를 도메인 객체로 변환하고, 개별 필드 패치를 Companion 패턴으로 처리한다.

## 역할 (Role)
설정 영속화의 실제 구현. `AppDatabase.userSettingsDao`를 래핑하여 도메인 메서드를 DB 연산으로 번역한다.

## 구조 (Structure)

| 파일 | 타입 | 역할 |
|------|------|------|
| `user_settings_repository_impl.dart` | class | Repository 구현체 + `_toDomain` 매퍼 |

## 동작 흐름 (Flow)
- `Companion(field: Value(x))` 패턴으로 개별 필드만 패치
- `_toDomain`이 DB Row → `UserSettings` 변환 담당

## 의존성 (Dependencies)

| 대상 | 종류 | 역할 |
|------|------|------|
| `AppDatabase` | 내부(core) | Drift DB 인스턴스 |
| `UserSettingsRepository` | 내부(domain) | 구현 인터페이스 |

## 주의사항 (Caveats)
- `updateCustomCardSize`는 `cardSizePreset`을 `'custom'`으로 강제 변경한다.

## 하위 구성 (Contents)
| 구분 | 대상 | 해설 문서 | 한 줄 요약 |
|------|------|----------|-----------|
| 파일 | `user_settings_repository_impl.dart` | [해설](user_settings_repository_impl.md) | Drift 기반 설정 Repository 구현체 |

## Changelog
### v1 (2026-04-19) — 최초 작성
- 최초 해설 문서 생성.
