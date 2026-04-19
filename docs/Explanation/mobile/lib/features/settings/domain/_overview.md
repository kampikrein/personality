---
id: "mobile-lib-features-settings-domain-_overview"
type: explanation
target: "mobile/lib/features/settings/domain/"
layer: "folder"
version: 1
created: 2026-04-19
updated: 2026-04-19
last_explained_commit: "0336e4c341209b356a3138d22619cde2b7c40eef"
functions: []
---

# settings/domain/ — 해설

## 개요
설정 피처의 순수 도메인 계층이다. 값 객체 2개(`UserSettings`, `CardSizePreset`)와 추상 Repository 인터페이스 1개로 구성되며, Flutter·Drift 등 프레임워크에 의존하지 않는다.

## 역할 (Role)
설정 피처의 비즈니스 언어 정의. 외부 레이어(data, presentation)가 이 도메인 타입과 인터페이스에만 의존하도록 강제하여 구현 세부를 격리한다.

## 구조 (Structure)

```
domain/
├── entities/       — 값 객체 (UserSettings, CardSizePreset)
└── repositories/   — 추상 인터페이스 (UserSettingsRepository)
```

| 레이어 | 파일 수 | 역할 |
|--------|---------|------|
| `entities/` | 2 | 데이터 형태 정의 |
| `repositories/` | 1 | 계약 정의 |

## 동작 흐름 (Flow)
1. `CardSizePreset` → `UserSettings`에 내장 (필드 타입)
2. `UserSettingsRepository`(인터페이스) → `UserSettingsRepositoryImpl`(data)이 구현
3. Provider가 인터페이스 타입으로 노출 → UI는 도메인 레이어만 보고 data 레이어를 모름

## 의존성 (Dependencies)

| 대상 | 종류 | 역할 |
|------|------|------|
| `SpreadType` (reading/domain) | 내부 피처 간 | `UserSettings.defaultSpreadType` |
| `freezed_annotation` | external | 불변 클래스 코드 생성 |

## 주의사항 (Caveats)
- `UserSettings`가 `reading` 피처의 `SpreadType`에 의존하는 것은 피처 간 결합이다. 향후 분리 고려 가능.

## 하위 구성 (Contents)
| 구분 | 대상 | 해설 문서 | 한 줄 요약 |
|------|------|----------|-----------|
| 폴더 | `entities/` | [overview](entities/_overview.md) | 설정 도메인 값 객체 2개 |
| 폴더 | `repositories/` | [overview](repositories/_overview.md) | 설정 읽기·쓰기 추상 계약 |

## Changelog
### v1 (2026-04-19) — 최초 작성
- 최초 해설 문서 생성.
