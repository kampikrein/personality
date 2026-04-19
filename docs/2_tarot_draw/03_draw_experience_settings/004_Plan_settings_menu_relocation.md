---
id: "004"
type: plan
title: "Plan — 뽑기 설정 통합 (메뉴 재배치)"
created: 2026-04-17
status: completed
traces_brief: "docs/15_draw_experience_settings/002_Brief_settings_menu_relocation.md"
traces_scope: "docs/15_draw_experience_settings/003_Scope_settings_menu_relocation.md"
summary: >
  3개 파일 위젯 트리 재배치를 코드 수준으로 구체화. 신규 위젯 1개(_PanelSubheader),
  4개 _SettingRow 추가, settings_page.dart 전면 교체, profile_page.dart _MenuTile
  단일 변경. 빌드·ADB 스크린샷 검증 명세 포함.
keywords: [plan, settings, navigation, mobile, flutter, ui]
---

# Plan — 뽑기 설정 통합 (메뉴 재배치)

## 사전 확인 결과 (Observe 단계)

### 색상 상수 네임스페이스 분리 — 중요 위험 사항

`home_page.dart`는 파일 로컬 언더스코어 상수를 사용한다:

```dart
// home_page.dart — 로컬 상수 (파일 내부 전용)
const _gold = Color(0xFFD4A84B);
const _goldLight = Color(0xFFE8C97A);
const _deepPurple = Color(0xFF1A1028);
const _darkSurface = Color(0xFF0D0A14);
const _softPurple = Color(0xFF6B5B95);
const _textPrimary = Color(0xFFE8E0F0);
const _textSecondary = Color(0xFF9B8FB8);
```

`settings_page.dart`와 `profile_page.dart`는 `mystical_scaffold.dart`의 공개 상수를 사용한다:

```dart
// mystical_scaffold.dart — 공개 상수
const kGold = Color(0xFFD4A84B);
const kDeepPurple = Color(0xFF1A1028);
const kDarkSurface = Color(0xFF0D0A14);
const kSoftPurple = Color(0xFF6B5B95);
const kTextPrimary = Color(0xFFE8E0F0);
const kTextSecondary = Color(0xFF9B8FB8);
```

값은 동일하지만 이름이 다르다. **home_page.dart 내 신규 위젯은 반드시 `_gold`, `_textPrimary`, `_textSecondary`, `_deepPurple`, `_darkSurface`, `_softPurple`(언더스코어 prefix)를 사용해야 한다.** `kGold` 등 k-prefix 사용 시 컴파일 오류.

### UserSettings 필드 확인

`showFaceUp` 기본값: `false` (코드 `@Default(false)`)
`showCardName` 기본값: `true` (코드 `@Default(true)`)
`cardsPerRow` 기본값: `3` (코드 `@Default(3)`)
`cardSizePreset` 타입: `CardSizePreset` (`.label` 속성 존재 확인됨)

### `_GoldSwitch` / `_PillSelector` 제네릭 확인

- `_GoldSwitch`: `bool value`, `ValueChanged<bool> onChanged` — 제네릭 없음. 그대로 사용 가능.
- `_PillSelector<T>`: 제네릭 타입 파라미터 보유. `int`로 사용 시 `_PillSelector<int>(...)` 명시 필요. 이미 `_PillSelector<int>`와 `_PillSelector<SpreadType>` 두 용례가 같은 파일에 공존하므로 문제 없음.

### `MysticalScaffold` API 확인

`MysticalScaffold(title: '앱 설정', body: ...)` — `title`과 `body`만으로 사용 가능. AppBar는 자동 생성된다. 추가 조정 불필요.

### 라우트 확인

`app_router.dart`에 `/settings`(name: `settings`), `/settings/card-size`(name: `card-size-settings`) 모두 존재 확인. 변경 불필요.

### go_router import 확인

`home_page.dart` 1번 라인: `import 'package:go_router/go_router.dart';` 이미 존재. `context.push('/settings/card-size')` 호출 가능.

---

## 파일 1: `home_page.dart`

**경로**: `mobile/lib/features/home/presentation/pages/home_page.dart`

### 1-A. 신규 위젯 `_PanelSubheader`

`_GoldHairline` 클래스 정의 바로 위(아래 `// ═══ 공통 유틸 위젯` 섹션)에 삽입한다.

**삽입 위치**: `_GoldHairline` 클래스 정의 직전 (`// ═══════ 공통 유틸 위젯` 주석 바로 아래)

**전체 코드**:

```dart
// ── 패널 서브헤더 ─────────────────────────────────────────────
class _PanelSubheader extends StatelessWidget {
  const _PanelSubheader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
          color: _textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.8,
        ),
      ),
    );
  }
}
```

**Edit old_string**:
```
// ═══════════════════════════════════════════════════════════════
//  공통 유틸 위젯
// ═══════════════════════════════════════════════════════════════
class _GoldHairline
```

**Edit new_string**:
```
// ═══════════════════════════════════════════════════════════════
//  공통 유틸 위젯
// ═══════════════════════════════════════════════════════════════
// ── 패널 서브헤더 ─────────────────────────────────────────────
class _PanelSubheader extends StatelessWidget {
  const _PanelSubheader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
          color: _textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.8,
        ),
      ),
    );
  }
}

class _GoldHairline
```

### 1-B. `_DrawSettingsPanel.build()` 확장

현재 `_DrawSettingsPanel.build()`의 Column children 구조:

```
패널 헤더
_GoldHairline(opacity: 0.2)
덱 선택 (_SettingRow)
_GoldHairline(opacity: 0.1)
레벨 (_SettingRow)
_GoldHairline(opacity: 0.1)
카드 수 (_SettingRow)
_GoldHairline(opacity: 0.1)
스프레드 (_SettingRow)
_GoldHairline(opacity: 0.1)
역방향 (_SettingRow)    ← 마지막
```

변경 후 목표 구조:

```
패널 헤더
_GoldHairline(opacity: 0.2)
_PanelSubheader(title: '기본 설정')      ← 신규
덱 선택 (_SettingRow)
_GoldHairline(opacity: 0.1)
레벨 (_SettingRow)
_GoldHairline(opacity: 0.1)
카드 수 (_SettingRow)
_GoldHairline(opacity: 0.1)
스프레드 (_SettingRow)
_GoldHairline(opacity: 0.1)
역방향 (_SettingRow)
_GoldHairline(opacity: 0.3)             ← 신규 (그룹 간 강한 구분선)
_PanelSubheader(title: '표시 옵션')      ← 신규
앞면으로 시작 (_SettingRow + _GoldSwitch) ← 신규
_GoldHairline(opacity: 0.1)             ← 신규
카드 이름 표시 (_SettingRow + _GoldSwitch) ← 신규
_GoldHairline(opacity: 0.1)             ← 신규
한 줄 카드 수 (_SettingRow + _PillSelector<int>) ← 신규
_GoldHairline(opacity: 0.1)             ← 신규
카드 크기 (인라인 ListTile 스타일 행)   ← 신규
```

**Edit old_string** (`_DrawSettingsPanel.build()` 내 Column children 전체, `_GoldHairline(opacity: 0.2)` 이후부터 닫는 `]` 까지):

```
          _GoldHairline(opacity: 0.2),

          // ── 덱 선택 ──
          _SettingRow(
            label: '덱',
            icon: Icons.layers_outlined,
            child: decksAsync.when(
              loading: () => const SizedBox(
                width: 80,
                child: LinearProgressIndicator(color: _gold, backgroundColor: _deepPurple),
              ),
              error: (_, __) => const Text('오류', style: TextStyle(color: _textSecondary)),
              data: (decks) {
                final deckList = decks as List;
                return _GoldDropdown<String>(
                  value: settings?.selectedDeckId,
                  items: deckList
                      .map((d) => DropdownMenuItem<String>(
                            value: d.id as String,
                            child: Text(d.name as String),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) repo.updateSelectedDeckId(v);
                  },
                );
              },
            ),
          ),
          _GoldHairline(opacity: 0.1),

          // ── 체험 레벨 ──
          _SettingRow(
            label: '레벨',
            icon: Icons.speed_outlined,
            child: _PillSelector<int>(
              options: const [
                (value: 1, label: '즉시'),
                (value: 2, label: '연출'),
                (value: 3, label: '2D'),
                (value: 4, label: '2.5D'),
              ],
              selected: settings?.experienceLevel ?? 4,
              onSelect: (v) => repo.updateExperienceLevel(v),
            ),
          ),
          _GoldHairline(opacity: 0.1),

          // ── 기본 카드 수 ──
          _SettingRow(
            label: '카드 수',
            icon: Icons.style_outlined,
            child: _CountStepper(
              value: settings?.defaultCardCount ?? 3,
              min: 1,
              max: 10,
              onChanged: (v) => repo.updateDefaultCardCount(v),
            ),
          ),
          _GoldHairline(opacity: 0.1),

          // ── 기본 스프레드 ──
          _SettingRow(
            label: '스프레드',
            icon: Icons.grid_view_outlined,
            child: _PillSelector<SpreadType>(
              options: const [
                (value: SpreadType.single, label: '1장'),
                (value: SpreadType.threeCard, label: '3장'),
                (value: SpreadType.custom, label: '자유'),
              ],
              selected: settings?.defaultSpreadType ?? SpreadType.custom,
              onSelect: (v) => repo.updateDefaultSpreadType(v.name),
            ),
          ),
          _GoldHairline(opacity: 0.1),

          // ── 역방향 허용 ──
          _SettingRow(
            label: '역방향',
            icon: Icons.swap_vert_outlined,
            child: _GoldSwitch(
              value: settings?.allowReversed ?? true,
              onChanged: (v) => repo.updateAllowReversed(v),
            ),
          ),
        ],
```

**Edit new_string**:

```
          _GoldHairline(opacity: 0.2),

          // ── [기본 설정] 그룹 헤더 ──
          const _PanelSubheader(title: '기본 설정'),

          // ── 덱 선택 ──
          _SettingRow(
            label: '덱',
            icon: Icons.layers_outlined,
            child: decksAsync.when(
              loading: () => const SizedBox(
                width: 80,
                child: LinearProgressIndicator(color: _gold, backgroundColor: _deepPurple),
              ),
              error: (_, __) => const Text('오류', style: TextStyle(color: _textSecondary)),
              data: (decks) {
                final deckList = decks as List;
                return _GoldDropdown<String>(
                  value: settings?.selectedDeckId,
                  items: deckList
                      .map((d) => DropdownMenuItem<String>(
                            value: d.id as String,
                            child: Text(d.name as String),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) repo.updateSelectedDeckId(v);
                  },
                );
              },
            ),
          ),
          _GoldHairline(opacity: 0.1),

          // ── 체험 레벨 ──
          _SettingRow(
            label: '레벨',
            icon: Icons.speed_outlined,
            child: _PillSelector<int>(
              options: const [
                (value: 1, label: '즉시'),
                (value: 2, label: '연출'),
                (value: 3, label: '2D'),
                (value: 4, label: '2.5D'),
              ],
              selected: settings?.experienceLevel ?? 4,
              onSelect: (v) => repo.updateExperienceLevel(v),
            ),
          ),
          _GoldHairline(opacity: 0.1),

          // ── 기본 카드 수 ──
          _SettingRow(
            label: '카드 수',
            icon: Icons.style_outlined,
            child: _CountStepper(
              value: settings?.defaultCardCount ?? 3,
              min: 1,
              max: 10,
              onChanged: (v) => repo.updateDefaultCardCount(v),
            ),
          ),
          _GoldHairline(opacity: 0.1),

          // ── 기본 스프레드 ──
          _SettingRow(
            label: '스프레드',
            icon: Icons.grid_view_outlined,
            child: _PillSelector<SpreadType>(
              options: const [
                (value: SpreadType.single, label: '1장'),
                (value: SpreadType.threeCard, label: '3장'),
                (value: SpreadType.custom, label: '자유'),
              ],
              selected: settings?.defaultSpreadType ?? SpreadType.custom,
              onSelect: (v) => repo.updateDefaultSpreadType(v.name),
            ),
          ),
          _GoldHairline(opacity: 0.1),

          // ── 역방향 허용 ──
          _SettingRow(
            label: '역방향',
            icon: Icons.swap_vert_outlined,
            child: _GoldSwitch(
              value: settings?.allowReversed ?? true,
              onChanged: (v) => repo.updateAllowReversed(v),
            ),
          ),

          // ── 그룹 구분선 (강한) ──
          _GoldHairline(opacity: 0.3),

          // ── [표시 옵션] 그룹 헤더 ──
          const _PanelSubheader(title: '표시 옵션'),

          // ── 앞면으로 시작 ──
          _SettingRow(
            label: '앞면으로 시작',
            icon: Icons.flip_outlined,
            child: _GoldSwitch(
              value: settings?.showFaceUp ?? false,
              onChanged: (v) => repo.updateShowFaceUp(v),
            ),
          ),
          _GoldHairline(opacity: 0.1),

          // ── 카드 이름 표시 ──
          _SettingRow(
            label: '카드 이름',
            icon: Icons.label_outline,
            child: _GoldSwitch(
              value: settings?.showCardName ?? true,
              onChanged: (v) => repo.updateShowCardName(v),
            ),
          ),
          _GoldHairline(opacity: 0.1),

          // ── 한 줄 카드 수 ──
          _SettingRow(
            label: '한 줄 카드 수',
            icon: Icons.view_column_outlined,
            child: _PillSelector<int>(
              options: const [
                (value: 1, label: '1장'),
                (value: 2, label: '2장'),
                (value: 3, label: '3장'),
              ],
              selected: settings?.cardsPerRow ?? 3,
              onSelect: (v) => repo.updateCardsPerRow(v),
            ),
          ),
          _GoldHairline(opacity: 0.1),

          // ── 카드 크기 (별도 페이지 진입) ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GestureDetector(
              onTap: () => context.push('/settings/card-size'),
              child: Row(
                children: [
                  Icon(Icons.aspect_ratio, size: 14, color: _textSecondary),
                  const SizedBox(width: 8),
                  const Text(
                    '카드 크기',
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    settings?.cardSizePreset.label ?? '표준 타로',
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: _textSecondary.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),
        ],
```

**참고**: 카드 크기 행은 `_SettingRow`를 사용하지 않는다. `_SettingRow`는 `Spacer()`로 child를 오른쪽 끝에 밀지만, 카드 크기 행은 현재 값 + chevron이 오른쪽에 와야 하므로 인라인 `Padding > GestureDetector > Row`로 직접 구현한다. `context`는 `_DrawSettingsPanel.build(BuildContext context, WidgetRef ref)` 파라미터에서 받아오므로 사용 가능.

---

## 파일 2: `settings_page.dart` 전면 교체

**경로**: `mobile/lib/features/settings/presentation/pages/settings_page.dart`

전체 파일을 다음 내용으로 교체한다 (impl 에이전트는 Write tool 사용):

```dart
import 'package:flutter/material.dart';

import '../../../../core/widgets/mystical_scaffold.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MysticalScaffold(
      title: '앱 설정',
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tune_outlined,
                size: 56,
                color: kGold.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 20),
              const Text(
                '환경설정 영역이 준비 중입니다',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '테마 · 햅틱 · 알림 등이 추가될 예정입니다',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kTextSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**제거되는 import**:
- `flutter_riverpod` (ConsumerWidget 불필요)
- `go_router` (context.push 호출 없음)
- `deck/presentation/providers/deck_providers.dart`
- `reading/domain/entities/spread_type.dart`
- `settings/presentation/providers/settings_providers.dart`

**유지되는 것**:
- 클래스명 `SettingsPage` (라우터가 `const SettingsPage()` 참조)
- `mystical_scaffold.dart` import (`kGold`, `kTextPrimary`, `kTextSecondary` 사용)

**참고**: `settings_page.dart` 내 `_SettingsSection`, `_MysticalDropdown`, `_SwitchTile` 클래스도 모두 삭제된다. 새 파일에 포함하지 않으면 된다.

---

## 파일 3: `profile_page.dart` `_MenuTile` 단일 변경

**경로**: `mobile/lib/features/profile/presentation/pages/profile_page.dart`

**Edit old_string**:

```
                _MenuTile(
                  icon: Icons.tune_rounded,
                  title: '설정',
                  subtitle: '체험 레벨, 카드 수, 스프레드',
                  onTap: () => context.pushNamed('settings'),
                ),
```

**Edit new_string**:

```
                _MenuTile(
                  icon: Icons.settings_outlined,
                  title: '앱 설정',
                  subtitle: '환경설정',
                  onTap: () => context.pushNamed('settings'),
                ),
```

`onTap` 람다 (`context.pushNamed('settings')`) 변경 없음.

---

## 검증 명령

### 빌드 (샌드박스 비활성화 필요 — flutter 빌드는 홈 디렉토리 접근 필요)

```bash
cd /Users/kampikrein/A/personality/mobile && flutter build apk --debug
```

> 이 명령은 `dangerouslyDisableSandbox: true` 모드에서 실행해야 한다. 빌드 툴체인이 `~/.gradle`, `~/.pub-cache` 등 홈 디렉토리 내 경로에 접근하기 때문이다.

빌드 성공 기준: `Built build/app/outputs/flutter-apk/app-debug.apk` 메시지 출력, exit code 0.

### ADB 스크린샷 — 검증 화면 3개

**전제조건**: 에뮬레이터가 실행 중이어야 한다. `$ANDROID_HOME/platform-tools/adb devices`로 연결 확인 후 앱 실행.

**화면 1: 뽑기 탭 홈 (패널 스크롤)**

```bash
SAVE_PATH="/Users/kampikrein/A/personality/mobile/tmp/screenshots/verify_01_draw_panel_top.png"
mkdir -p "$(dirname $SAVE_PATH)"
/Users/kampikrein/Library/Android/sdk/platform-tools/adb exec-out screencap -p > "$SAVE_PATH"
```

검증 포인트: `_DrawSettingsPanel` 내 "기본 설정" 서브헤더와 덱/레벨/카드 수/스프레드/역방향 5행 확인.

**화면 2: 뽑기 탭 홈 (아래로 스크롤 후 — 표시 옵션 그룹 확인)**

앱에서 패널을 아래로 스크롤한 뒤:

```bash
SAVE_PATH="/Users/kampikrein/A/personality/mobile/tmp/screenshots/verify_02_draw_panel_display.png"
/Users/kampikrein/Library/Android/sdk/platform-tools/adb exec-out screencap -p > "$SAVE_PATH"
```

검증 포인트: "표시 옵션" 서브헤더 + 앞면으로 시작/카드 이름/한 줄 카드 수/카드 크기(chevron) 4행 확인.

**화면 3: 유저 탭**

유저 탭 탭 후:

```bash
SAVE_PATH="/Users/kampikrein/A/personality/mobile/tmp/screenshots/verify_03_profile_menu.png"
/Users/kampikrein/Library/Android/sdk/platform-tools/adb exec-out screencap -p > "$SAVE_PATH"
```

검증 포인트: 메뉴 타일 첫 번째가 `Icons.settings_outlined` + "앱 설정" + "환경설정" 표시.

**화면 4: 앱 설정 페이지**

"앱 설정" 메뉴 탭 후:

```bash
SAVE_PATH="/Users/kampikrein/A/personality/mobile/tmp/screenshots/verify_04_app_settings_placeholder.png"
/Users/kampikrein/Library/Android/sdk/platform-tools/adb exec-out screencap -p > "$SAVE_PATH"
```

검증 포인트: `Icons.tune_outlined` 아이콘 + "환경설정 영역이 준비 중입니다" 텍스트 + "테마 · 햅틱 · 알림 등이 추가될 예정입니다" 텍스트.

---

## 리스크 정리

### R1: 색상 상수 네임스페이스 충돌 — 주의 필요

- **내용**: `home_page.dart`는 `_gold` (언더스코어), `settings_page.dart`/`profile_page.dart`는 `kGold` (k-prefix)를 사용. 완전히 다른 식별자이며 값은 동일하다.
- **fix**: `home_page.dart` 내 신규 위젯(`_PanelSubheader`, 카드 크기 인라인 행)은 `_gold`, `_textPrimary`, `_textSecondary` 등 언더스코어 상수만 사용. `settings_page.dart` 신규 코드는 `kGold`, `kTextPrimary`, `kTextSecondary`(mystical_scaffold에서 export) 사용. 혼용 금지.

### R2: `_PillSelector<int>` 제네릭 파라미터 — 문제 없음

- **내용**: `_PillSelector<int>` 사용은 동일 파일 내 기존 `_PillSelector<int>` (레벨 선택) 용례가 이미 존재하므로 타입 추론 문제 없음.
- **fix**: 불필요. `const` 리스트에 `int` 리터럴을 사용하면 타입 추론이 `int`로 자동 결정된다. `(value: 1, label: '1장')` 등의 리터럴은 암묵적으로 `({int value, String label})` 레코드.

### R3: 카드 크기 행에서 `_SettingRow` 미사용 — 의도적

- **내용**: 카드 크기 행은 `_SettingRow` 래퍼를 사용하지 않는다. `_SettingRow`는 `Spacer()`로 오른쪽에 단일 위젯만 배치하는 구조인데, 카드 크기 행은 현재 프리셋 라벨 + chevron이 오른쪽에 와야 하므로 커스텀 Row가 필요하다.
- **fix**: 인라인 `Padding > GestureDetector > Row` 구현으로 처리. `context`는 `_DrawSettingsPanel.build(BuildContext context, WidgetRef ref)` 파라미터에서 직접 사용 가능.

### R4: `const _PanelSubheader(...)` — 가능 여부

- **내용**: `_PanelSubheader`는 `required this.title` 파라미터를 `String`으로 받는다. `'기본 설정'`과 `'표시 옵션'`은 모두 컴파일 타임 상수이므로 `const _PanelSubheader(title: '기본 설정')` 사용 가능.
- **fix**: 불필요.

### R5: `settings_page.dart` 내 `GoldHairline` 클래스 — 삭제 무관

- **내용**: 기존 `settings_page.dart`는 `mystical_scaffold.dart`의 `GoldHairline`을 import해서 사용한다. 신규 파일에서는 사용하지 않으므로 import 자체가 제거된다.
- **fix**: 불필요.

### R6: `MysticalScaffold`의 `body` 파라미터 — required 확인

- **내용**: `MysticalScaffold`에서 `body`는 `required Widget body` 파라미터다. 신규 `SettingsPage`에서 `body: Center(...)` 형태로 전달하면 정상.
- **fix**: 불필요.

### R7: `showFaceUp` 기본값 `false` — Scope 명세와 일치

- **내용**: Brief/Scope는 `settings?.showFaceUp ?? false`를 사용하라고 명시. `UserSettings` 코드에서 `@Default(false)`로 확인됨. 일치.
- **fix**: 불필요.

---

## 구현 체크리스트 (impl 에이전트용)

```
[ ] 1. home_page.dart: `_PanelSubheader` 클래스 추가 (Edit #1-A)
[ ] 2. home_page.dart: `_DrawSettingsPanel.build()` Column children 확장 (Edit #1-B)
[ ] 3. settings_page.dart: 전면 교체 (Write tool — 전체 파일)
[ ] 4. profile_page.dart: `_MenuTile` 블록 단일 Edit (#3)
[ ] 5. flutter build apk --debug 실행 — 성공 확인
[ ] 6. ADB 스크린샷 4장 캡처 및 시각 검증
```

---

## 라우트 / 데이터 무변경 확인 (Reviewed 파일)

| 항목 | 확인 결과 |
|------|----------|
| `/settings` path | `app_router.dart` L158 에 존재 |
| `name: 'settings'` | `app_router.dart` L159 에 존재 |
| `/settings/card-size` path | `app_router.dart` L163 에 존재 |
| `name: 'card-size-settings'` | `app_router.dart` L164 에 존재 |
| `UserSettings.showFaceUp` | `user_settings.dart` L18, `@Default(false)` |
| `UserSettings.showCardName` | `user_settings.dart` L21, `@Default(true)` |
| `UserSettings.cardsPerRow` | `user_settings.dart` L22, `@Default(3)` |
| `CardSizePreset.label` | `card_size_preset.dart` L55, `final String label` |
| `userSettingsRepositoryProvider` | `settings_providers.dart` L10 에 존재 |

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 0s | 0 |
| 2 | user-ai-exchange | 0s | 0 |
| 3 | user-ai-exchange | 18s | 60949 |
| 4 | user-ai-exchange | 0s | 0 |
| 5 | user-ai-exchange | 59s | 146973 |
| 6 | user-ai-exchange | 642s | 1681853 |
| 7 | user-ai-exchange | 423s | 3654116 |
| 8 | user-ai-exchange | 0s | 0 |
| 9 | user-ai-exchange | 21s | 150544 |
| 10 | user-ai-exchange | 0s | 0 |
| 11 | user-ai-exchange | 39s | 463619 |
| 12 | user-ai-exchange | 207s | 355631 |
| 13 | user-ai-exchange | 807s | 2537084 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 283968s |
| Total Tokens | 9050769 |
| Input Tokens | 175 |
| Output Tokens | 102711 |
| Cache Read | 8210080 |
| Cache Creation | 737803 |
