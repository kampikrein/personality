---
id: "mobile-lib-features-settings-domain-repositories-_overview"
type: explanation
target: "mobile/lib/features/settings/domain/repositories/"
layer: "folder"
version: 1
created: 2026-04-19
updated: 2026-04-19
last_explained_commit: "0336e4c341209b356a3138d22619cde2b7c40eef"
functions: []
---

# settings/domain/repositories/ — 해설

## 개요
설정 읽기·쓰기의 추상 계약을 담는 폴더다. `UserSettingsRepository` 인터페이스 단 하나로 구성된다.

## 역할 (Role)
도메인과 데이터 레이어의 경계 정의. UI와 Provider는 이 인터페이스 타입에만 의존하여 구현체 교체 가능성을 확보한다.

## 구조 (Structure)

| 파일 | 타입 | 역할 |
|------|------|------|
| `user_settings_repository.dart` | abstract class | 12개 메서드 계약 |

## 동작 흐름 (Flow)
- `UserSettingsRepositoryImpl`이 이 인터페이스를 구현
- `userSettingsRepositoryProvider`가 인터페이스 타입으로 반환하여 의존 역전 실현

## 의존성 (Dependencies)

| 대상 | 종류 | 역할 |
|------|------|------|
| `UserSettings` | 내부(domain/entities) | 메서드 반환/파라미터 타입 |

## 주의사항 (Caveats)
- 인터페이스만 존재하므로 직접 인스턴스화 불가. 항상 `userSettingsRepositoryProvider`를 통해 접근한다.

## 하위 구성 (Contents)
| 구분 | 대상 | 해설 문서 | 한 줄 요약 |
|------|------|----------|-----------|
| 파일 | `user_settings_repository.dart` | [해설](user_settings_repository.md) | 설정 읽기·쓰기 추상 계약 12개 메서드 |

## Changelog
### v1 (2026-04-19) — 최초 작성
- 최초 해설 문서 생성.
