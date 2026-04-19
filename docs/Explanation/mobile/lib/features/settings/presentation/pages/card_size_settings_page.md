---
id: "mobile-lib-features-settings-presentation-pages-card_size_settings_page"
type: explanation
target: "mobile/lib/features/settings/presentation/pages/card_size_settings_page.dart"
layer: "file"
version: 1
created: 2026-04-19
updated: 2026-04-19
last_explained_commit: "0336e4c341209b356a3138d22619cde2b7c40eef"
functions: []
---

# card_size_settings_page.dart — 해설

## 개요
카드 크기 프리셋 선택과 커스텀 mm 직접 입력을 제공하는 전용 설정 페이지다. 현재 선택된 종횡비를 카드 미리보기로 시각화하며, `/settings/card-size` 라우트로 진입한다.

## 역할 (Role)
뽑기 화면의 "카드 크기" 항목 → `context.push('/settings/card-size')` 로 연결되는 전용 서브 페이지. `CardSizePreset` 7개를 라디오 목록으로 노출하고, `custom` 선택 시 mm 입력 필드를 동적으로 표시한다.

## 구조 (Structure)

| 클래스 | 역할 |
|--------|------|
| `CardSizeSettingsPage` | 루트 위젯. `userSettingsProvider` 구독, `_controllersInitialized` 로 TextEditingController 1회 초기화 |
| `_CardPreview` | `AspectRatio` 위젯으로 현재 종횡비를 140px 카드로 시각화 |
| `_PresetTile` | 프리셋 1개 행. 라디오 원형 + 레이블/subtitle + 체크 아이콘 |
| `_CustomSizeInput` | 가로/세로 TextField + "적용" 버튼. `FilteringTextInputFormatter`로 숫자·소수점만 허용 |

레이아웃:
```
MysticalScaffold (title: '카드 크기')
└── ListView
    ├── MysticalCard — _CardPreview (미리보기)
    ├── MysticalCard — _PresetTile × 7 (프리셋 목록)
    └── (custom 선택 시) MysticalCard — _CustomSizeInput
```

## 동작 흐름 (Flow)

### 진입
1. `_CardSizeSettingsPageState.initState` → `_widthController`, `_heightController` 빈 상태로 초기화
2. `build` 첫 호출 + settings 로드 → `_controllersInitialized == false` → controller에 현재 커스텀 크기 텍스트 주입, `_controllersInitialized = true`

### 프리셋 선택
1. `_PresetTile.onTap` → `userSettingsRepositoryProvider.updateCardSizePreset(preset.name)`
2. DB 저장 → `userSettingsProvider` 갱신 → `build` 리빌드 → `_CardPreview`의 `aspectRatio` 업데이트

### 커스텀 크기 입력
1. `currentPreset == CardSizePreset.custom` 일 때만 `_CustomSizeInput` 노출
2. 숫자 입력 후 "적용" 버튼 또는 키보드 submit → `_applyCustomSize()` 호출
3. `_applyCustomSize` — `double.tryParse` + 양수 검증 → `updateCustomCardSize(w, h)` 호출 → DB 저장 + `cardSizePreset = 'custom'` 동시 설정

## 의존성 (Dependencies)

| 대상 | 종류 | 역할 |
|------|------|------|
| `MysticalScaffold`, `MysticalCard`, `GoldHairline` 등 | 내부(core/widgets) | 공통 UI 컴포넌트 |
| `CardSizePreset` | 내부(domain) | 프리셋 열거형 |
| `settings_providers` | 내부(presentation) | `userSettingsProvider`, `userSettingsRepositoryProvider` |
| `flutter/services` | Flutter | `FilteringTextInputFormatter` |

## 주의사항 (Caveats)
- `_controllersInitialized` 패턴 — `build`는 여러 번 호출될 수 있으므로 이 플래그 없이 controller를 초기화하면 입력 중 값이 리셋된다.
- "적용" 없이 텍스트만 바꾸면 DB에 저장되지 않는다. `_applyCustomSize`를 명시적으로 호출해야 한다.
- `custom` 외 프리셋을 선택하면 `_CustomSizeInput`이 숨겨지지만 controller 값은 유지된다. 다시 `custom`으로 돌아오면 이전 입력값이 그대로 표시된다.

## Changelog
### v1 (2026-04-19) — 최초 작성
- 최초 해설 문서 생성.
