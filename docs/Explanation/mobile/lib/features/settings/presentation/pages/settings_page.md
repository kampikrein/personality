---
id: "mobile-lib-features-settings-presentation-pages-settings_page"
type: explanation
target: "mobile/lib/features/settings/presentation/pages/settings_page.dart"
layer: "file"
version: 1
created: 2026-04-19
updated: 2026-04-19
last_explained_commit: "0336e4c341209b356a3138d22619cde2b7c40eef"
functions: []
---

# settings_page.dart — 해설

## 개요
`/settings` 라우트의 앱 설정 페이지 플레이스홀더다. 현재 "테마·햅틱·알림 등이 추가될 예정" 안내 텍스트만 표시하며 실질적인 기능은 없다.

## 역할 (Role)
프로필 탭 → "앱 설정" 메뉴 → `/settings` 라우트 목적지. 향후 테마·햅틱·알림·언어 등 전역 앱 설정이 이 페이지에 추가될 예정이다.

## 구조 (Structure)

```dart
class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MysticalScaffold(
      title: '앱 설정',
      body: Center(
        child: Column(
          // Icons.tune_outlined + 안내 텍스트 2줄
        ),
      ),
    );
  }
}
```

## 동작 흐름 (Flow)
1. `ProfilePage` → `_MenuTile('앱 설정')` 탭 → `context.pushNamed('settings')`
2. `app_router.dart` → `GoRoute(path: '/settings')` → `SettingsPage` 렌더링
3. 현재는 안내 텍스트만 표시, 뒤로가기 외 인터랙션 없음

## 의존성 (Dependencies)

| 대상 | 종류 | 역할 |
|------|------|------|
| `MysticalScaffold` | 내부(core/widgets) | 미스틱 배경 + AppBar 래퍼 |

## 주의사항 (Caveats)
- 뽑기 관련 설정(`_DrawSettingsPanel`)은 이 페이지와 분리되어 홈 탭에 인라인으로 존재한다.
- `card_size_settings_page.dart`(`/settings/card-size`)는 기능 구현이 완료된 하위 페이지이지만, 이 페이지 자체에서 진입할 수 없다 (홈 탭에서 직접 push).

## Changelog
### v1 (2026-04-19) — 최초 작성
- 최초 해설 문서 생성.
