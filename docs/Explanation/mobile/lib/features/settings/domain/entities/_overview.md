---
id: "mobile-lib-features-settings-domain-entities-_overview"
type: explanation
target: "mobile/lib/features/settings/domain/entities/"
layer: "folder"
version: 1
created: 2026-04-19
updated: 2026-04-19
last_explained_commit: "0336e4c341209b356a3138d22619cde2b7c40eef"
functions: []
---

# settings/domain/entities/ — 해설

## 개요
설정 도메인의 값 객체 2개를 정의한다. `UserSettings`(불변 설정 집합체)와 `CardSizePreset`(카드 크기 열거형)으로 구성되며, 두 파일이 강하게 결합되어 함께 사용된다.

## 역할 (Role)
설정 피처 전체의 데이터 형태를 정의하는 최하위 도메인 계층. Repository, Provider, UI 모두 이 두 타입을 통해 설정을 표현한다.

## 구조 (Structure)

| 파일 | 타입 | 역할 |
|------|------|------|
| `card_size_preset.dart` | enum | 7개 카드 크기 프리셋 + aspectRatio |
| `user_settings.dart` | freezed class | 13개 필드 설정 집합체 + cardAspectRatio |

의존 방향: `UserSettings` → `CardSizePreset`

## 동작 흐름 (Flow)
- `UserSettings.cardSizePreset` 필드에 `CardSizePreset` 값 저장
- `UserSettings.cardAspectRatio` getter — `custom`이면 커스텀 치수, 아니면 `preset.aspectRatio` 사용
- Freezed 코드 생성: `.freezed.dart`, `.g.dart`는 편집 금지

## 의존성 (Dependencies)

| 대상 | 종류 | 역할 |
|------|------|------|
| `SpreadType` | 내부(reading/domain) | `UserSettings.defaultSpreadType` 타입 |
| `freezed_annotation` | external | 불변 클래스 생성 |

## 주의사항 (Caveats)
- `user_settings.dart`는 `reading` 피처의 `SpreadType`에 의존하므로, 피처 간 결합이 존재한다.

## 하위 구성 (Contents)
| 구분 | 대상 | 해설 문서 | 한 줄 요약 |
|------|------|----------|-----------|
| 파일 | `card_size_preset.dart` | [해설](card_size_preset.md) | 7개 타로 카드 크기 프리셋 열거형 |
| 파일 | `user_settings.dart` | [해설](user_settings.md) | 앱 전체 사용자 설정 불변 값 객체 |

## Changelog
### v1 (2026-04-19) — 최초 작성
- 최초 해설 문서 생성.
