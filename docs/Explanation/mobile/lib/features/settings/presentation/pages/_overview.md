---
id: "mobile-lib-features-settings-presentation-pages-_overview"
type: explanation
target: "mobile/lib/features/settings/presentation/pages/"
layer: "folder"
version: 1
created: 2026-04-19
updated: 2026-04-19
last_explained_commit: "0336e4c341209b356a3138d22619cde2b7c40eef"
functions: []
---

# settings/presentation/pages/ — 해설

## 개요
설정 관련 화면 2개를 담는 폴더다. 기능이 완성된 카드 크기 페이지와 플레이스홀더 앱 설정 페이지로 구성된다.

## 역할 (Role)
설정 피처의 화면 계층. 두 페이지 모두 `MysticalScaffold`를 사용하며 `app_router.dart`의 셸 외부 라우트(`/settings`, `/settings/card-size`)에 연결된다.

## 구조 (Structure)

| 파일 | 라우트 | 상태 |
|------|--------|------|
| `settings_page.dart` | `/settings` | 플레이스홀더 |
| `card_size_settings_page.dart` | `/settings/card-size` | 기능 완성 |

## 동작 흐름 (Flow)
- `ProfilePage` → `앱 설정` → `/settings` → `SettingsPage`
- 홈 탭 `_DrawSettingsPanel` → `카드 크기` 항목 → `/settings/card-size` → `CardSizeSettingsPage`

## 의존성 (Dependencies)

| 대상 | 종류 | 역할 |
|------|------|------|
| `MysticalScaffold` | 내부(core) | 공통 미스틱 화면 래퍼 |
| `settings_providers` | 내부(presentation) | 설정 읽기/쓰기 |
| `CardSizePreset` | 내부(domain) | 프리셋 목록 |

## 주의사항 (Caveats)
- `card_size_settings_page.dart`는 `settings_page.dart`에서 직접 진입할 수 없다. 홈 탭에서만 push된다.

## 하위 구성 (Contents)
| 구분 | 대상 | 해설 문서 | 한 줄 요약 |
|------|------|----------|-----------|
| 파일 | `settings_page.dart` | [해설](settings_page.md) | 앱 설정 플레이스홀더 페이지 |
| 파일 | `card_size_settings_page.dart` | [해설](card_size_settings_page.md) | 카드 크기 프리셋 선택 + 커스텀 입력 페이지 |

## Changelog
### v1 (2026-04-19) — 최초 작성
- 최초 해설 문서 생성.
