---
id: "mobile-lib-features-settings-domain-entities-card_size_preset"
type: explanation
target: "mobile/lib/features/settings/domain/entities/card_size_preset.dart"
layer: "file"
version: 1
created: 2026-04-19
updated: 2026-04-19
last_explained_commit: "0336e4c341209b356a3138d22619cde2b7c40eef"
functions: []
---

# card_size_preset.dart — 해설

## 개요
실물 타로 카드 규격을 열거형으로 정의한다. 7개 프리셋(표준 타로, 미니, 라지, 오라클, Thoth, 포커, 커스텀)이 `widthMm`·`heightMm`을 보유하고, 렌더링에 실제로 쓰이는 `aspectRatio`를 게터로 노출한다.

## 역할 (Role)
카드 종횡비의 단일 진실 원천. UI가 카드 크기를 표시하거나 렌더링할 때 이 열거형 하나만 참조하면 mm 수치와 레이블, 종횡비를 모두 얻을 수 있다. `UserSettings.cardSizePreset`에 저장되어 전역으로 사용된다.

## 구조 (Structure)

```dart
enum CardSizePreset {
  standardTarot, mini, largeTarot, oracle, thoth, poker, custom
}
```

| 값 | label | mm (W×H) | aspectRatio |
|----|-------|----------|-------------|
| `standardTarot` | 표준 타로 | 70 × 120 | 0.583 |
| `mini` | 미니/포켓 | 44 × 73 | 0.603 |
| `largeTarot` | 라지 타로 | 89 × 146 | 0.610 |
| `oracle` | 오라클 | 89 × 127 | 0.701 |
| `thoth` | Thoth | 73 × 111 | 0.658 |
| `poker` | 포커 | 63.5 × 89 | 0.713 |
| `custom` | 커스텀 | 70 × 120 (기본값) | 사용자 입력 |

필드:
- `label` — UI 표시 이름
- `subtitle` — mm 치수 문자열 (UI 부제목)
- `widthMm`, `heightMm` — 물리적 치수
- `aspectRatio` (getter) — `widthMm / heightMm`

## 동작 흐름 (Flow)
1. `UserSettings.cardSizePreset`에 저장된 값이 Riverpod `cardAspectRatioProvider`에 전달됨
2. `UserSettings.cardAspectRatio` getter — `custom`이면 `customCardWidthMm / customCardHeightMm`, 아니면 `preset.aspectRatio` 반환
3. `CardSizeSettingsPage`에서 `CardSizePreset.values`를 순회해 프리셋 목록 렌더링
4. 선택 시 `UserSettingsRepository.updateCardSizePreset(preset.name)`으로 DB 저장

## 의존성 (Dependencies)

| 대상 | 종류 | 역할 |
|------|------|------|
| (없음) | — | 순수 열거형, 외부 의존 없음 |

## 주의사항 (Caveats)
- `custom` 프리셋의 `widthMm`·`heightMm` 기본값(70/120)은 실제 렌더링에 사용되지 않는다. `custom` 선택 시 `UserSettings.customCardWidthMm/Height`가 우선한다.
- DB 저장은 `preset.name`(문자열)으로 이루어지므로, 열거형 값의 이름을 변경하면 기존 저장값이 `orElse: standardTarot`으로 폴백된다.

## Changelog
### v1 (2026-04-19) — 최초 작성
- 최초 해설 문서 생성.
