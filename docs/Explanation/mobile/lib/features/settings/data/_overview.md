---
id: "mobile-lib-features-settings-data-_overview"
type: explanation
target: "mobile/lib/features/settings/data/"
layer: "folder"
version: 1
created: 2026-04-19
updated: 2026-04-19
last_explained_commit: "0336e4c341209b356a3138d22619cde2b7c40eef"
functions: []
---

# settings/data/ — 해설

## 개요
설정 도메인의 데이터 레이어다. Drift DB와의 연결을 담당하는 `UserSettingsRepositoryImpl` 하나로 구성된다.

## 역할 (Role)
도메인 인터페이스를 실제 DB 연산으로 구현하는 계층. `AppDatabase.userSettingsDao`를 래핑하여 domain ↔ DB 간 변환을 처리한다.

## 구조 (Structure)

```
data/
└── repositories/
    └── user_settings_repository_impl.dart
```

## 동작 흐름 (Flow)
1. `userSettingsRepositoryProvider` → `UserSettingsRepositoryImpl(db)` 생성
2. 모든 업데이트는 `UserSettingsTableCompanion(field: Value(x))`로 단일 필드 패치
3. `_toDomain` → DB Row → `UserSettings` 변환

## 의존성 (Dependencies)

| 대상 | 종류 | 역할 |
|------|------|------|
| `AppDatabase` | 내부(core) | Drift DB |
| `domain/` | 내부 | 구현 대상 인터페이스·엔티티 |

## 주의사항 (Caveats)
- 현재 `repositories/` 하위 폴더 하나만 존재. `datasources/` 등이 필요해지면 이 레벨에 추가된다.

## 하위 구성 (Contents)
| 구분 | 대상 | 해설 문서 | 한 줄 요약 |
|------|------|----------|-----------|
| 폴더 | `repositories/` | [overview](repositories/_overview.md) | Drift 기반 설정 Repository 구현체 |

## Changelog
### v1 (2026-04-19) — 최초 작성
- 최초 해설 문서 생성.
