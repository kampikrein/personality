---
id: "003"
type: scope
title: "Scope — 뽑기 설정 통합 (메뉴 재배치)"
created: 2026-04-17
status: completed
complexity: simple
research_needed: false
effort_mode: bypass
tdd_mode: false
auto_run: true
orchestrator_active: false
traces_brief: "docs/15_draw_experience_settings/002_Brief_settings_menu_relocation.md"
summary: >
  Brief 002의 5개 In Scope 항목을 단일 사이클로 실행. 3개 파일(home_page,
  settings_page, profile_page) 위젯 트리 재배치만 수행하며 라우트·데이터·프로바이더
  변경 없음. effort_mode=bypass로 makeplan→impl→verify 직행.
keywords: [scope, settings, navigation, ia, mobile, draw, simple, bypass]
---

# Scope — 뽑기 설정 통합 (메뉴 재배치)

## Brief Reference

이 Scope는 `docs/15_draw_experience_settings/002_Brief_settings_menu_relocation.md`
(status: in-progress, Decisions: 5건 확정, Open Questions: 0건, quality_profile: standard)
의 In Scope 5개 항목을 직접 실행한다. Brief의 Intent / Boundaries / Decisions /
Model Anchors는 변경 불가능한 입력으로 간주한다.

## Goal

뽑기 관련 설정을 뽑기 탭 한 곳에 통합하고, 유저 탭의 '설정' 자리는 비-뽑기
환경설정용 '앱 설정' 자리표시자로 의미 전환한다.

## Approach (단일 경로)

### 1. 뽑기 홈 패널 확장 — `home_page.dart`

기존 `_DrawSettingsPanel` (덱·레벨·카드 수·스프레드·역방향 5행) 을 두 개 서브그룹으로
분리하고, "표시 옵션" 그룹에 4행 신규 추가:

```
_DrawSettingsPanel
├─ 패널 헤더: '뽑기 설정' (기존)
├─ [기본 설정]                               ← 신규 그룹 헤더
│   ├─ 덱 선택 (기존)
│   ├─ 체험 레벨 (기존)
│   ├─ 기본 카드 수 (기존)
│   ├─ 기본 스프레드 (기존)
│   └─ 역방향 (기존)
├─ _GoldHairline (구분선, 두께 강조)         ← 신규
├─ [표시 옵션]                               ← 신규 그룹 헤더
│   ├─ 앞면으로 시작 (_GoldSwitch)          ← 신규 행
│   ├─ 카드 이름 표시 (_GoldSwitch)         ← 신규 행
│   ├─ 한 줄 카드 수 (_PillSelector 1/2/3)  ← 신규 행
│   └─ 카드 크기 (ListTile + chevron)       ← 신규 행 (별도 페이지 진입)
```

서브헤더용 작은 위젯 1개 (`_PanelSubheader` 정도) 를 신규 추가. 다른 모든 행은
기존 `_SettingRow` + (`_GoldSwitch` | `_PillSelector` | ListTile) 컴포넌트 재사용.

카드 크기 행은 다른 행과 다르게 ListTile 스타일(`Icons.aspect_ratio` + 현재 프리셋
라벨 + chevron) 로 표현해 "여기서 페이지로 이동" 동선을 시각적으로 구분.

### 2. `/settings` 페이지 자리표시자화 — `settings_page.dart`

`SettingsPage` 위젯 본체를 전면 교체:

```
SettingsPage(MysticalScaffold(title: '앱 설정'))
└─ Center
    ├─ Icon (Icons.tune_outlined or settings_suggest, 큰 사이즈, kGold)
    ├─ '환경설정 영역이 준비 중입니다'  (kTextPrimary, 안내 헤더)
    └─ '테마 · 햅틱 · 알림 등이 추가될 예정입니다'  (kTextSecondary, 부가 설명)
```

기존 9개 항목 위젯 (`_SettingsSection`, `_MysticalDropdown`, `_SwitchTile`) 모두 제거.
미사용 import (deck_providers, spread_type, settings_providers) 정리. 라우트 path/name
변경 없음 — `/settings`, `name: 'settings'` 그대로 유지.

### 3. 유저 탭 메뉴 라벨 변경 — `profile_page.dart`

```dart
// Before
_MenuTile(
  icon: Icons.tune_rounded,
  title: '설정',
  subtitle: '체험 레벨, 카드 수, 스프레드',
  onTap: () => context.pushNamed('settings'),
)

// After
_MenuTile(
  icon: Icons.settings_outlined,
  title: '앱 설정',
  subtitle: '환경설정',
  onTap: () => context.pushNamed('settings'),
)
```

`Icons.tune_rounded`는 "조정/튜닝" 뉘앙스라 뽑기 설정과 의미 충돌. 일반 설정
아이콘으로 교체.

## Files

### Modified (실제 변경)

| # | File | Change |
|---|------|--------|
| 1 | `mobile/lib/features/home/presentation/pages/home_page.dart` | `_DrawSettingsPanel` 확장: 서브그룹 헤더 2개 + 4행 추가 + 헤더 위젯 1개 신규 |
| 2 | `mobile/lib/features/settings/presentation/pages/settings_page.dart` | `SettingsPage` 본체 전면 교체 (자리표시자) + 미사용 위젯/import 제거 |
| 3 | `mobile/lib/features/profile/presentation/pages/profile_page.dart` | `_MenuTile('설정')` → `_MenuTile('앱 설정')` 라벨/아이콘/subtitle 변경 |

### Reviewed (확인만)

| # | File | Why |
|---|------|-----|
| 1 | `mobile/lib/core/router/app_router.dart` | `/settings`, `/settings/card-size` path/name 무변경 확인 (외부 호출 안전성) |
| 2 | `mobile/lib/features/settings/presentation/pages/card_size_settings_page.dart` | 카드 크기 페이지 자체는 변경 없음 — `/settings/card-size`로 진입 동작 확인 |

**총합**: Modified 3 / Reviewed 2 / confidence: high

## Out of Scope (Brief 002 Out of Scope 그대로 승계)

1. 신규 비-뽑기 환경설정 항목 도입 (테마/햅틱/알림 등)
2. `CardSizeSettingsPage` 자체 변경
3. `UserSettings` 모델 / Drift 스키마 변경
4. `/settings` path 또는 name 변경, 신규 라우트 추가
5. 뽑기 홈 패널 디자인 토큰 전면 개편
6. 유저 탭 다른 메뉴 (덱 관리 / 앱 정보) 변경

## Constraints

- 데이터 모델·프로바이더 시그니처 무변경
- 라우트 path/name 무변경 (`/settings`, `/settings/card-size`)
- 기존 패널 컴포넌트 (`_SettingRow`, `_PillSelector`, `_GoldDropdown`, `_GoldSwitch`,
  `_CountStepper`, `_GoldHairline`) 재사용
- `flutter build apk --debug` 성공 확인 필수 (CLAUDE.md 정책)
- ADB 스크린샷 시각 검증 필수

## Verification Plan

1. **빌드**: `cd mobile && flutter build apk --debug` → 성공
2. **라우트 무결성**: `app_router.dart`에서 `/settings`, `/settings/card-size`,
   `name: 'settings'`, `name: 'card-size-settings'` 모두 동일하게 존재
3. **데이터 무결성**: `UserSettings` 필드 9개 모두 동일, repository 메서드 시그니처 동일
4. **시각 검증** (ADB 스크린샷):
   - 뽑기 탭 홈 → 9행 패널 + 2개 서브헤더 (기본 설정 / 표시 옵션)
   - 유저 탭 → 메뉴 첫 타일이 "앱 설정"
   - 유저 탭 → "앱 설정" 탭 → 자리표시자 화면

## Pipeline

- effort_mode: **bypass**
- orchestrator_active: **false** (eval/qualify/push/retro 없음)
- 단일 사이클: `makeplan → implementation → verify`
- auto_run: **true** (`--run` 명시)
