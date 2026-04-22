---
id: "047"
type: plan
title: "Plan: Cycle 2 — Settings UI (IntentPlacementSettingsPage + entry)"
created: 2026-04-21
cycle: 2
status: completed
traces_scope: "041"
traces_brief: "040"
depends_on: ["042"]
summary: >
  Cycle 2 Settings UI 영역 구현 플랜. IntentPlacement 3-way 선택 페이지 신규 생성,
  GoRouter 라우트 등록, HomePage._DrawSettingsPanel에 '의도 입력' 진입 행 추가의
  3단계로 RED 테스트 5개를 GREEN으로 전환한다.
keywords: [settings-ui, intent-placement, card-size-pattern, go-router, home-page]
---

# 047 — Plan: Cycle 2 — Settings UI (IntentPlacementSettingsPage + entry)

## Goal

TDD Red 046 문서에서 정의한 5개 failing 테스트(T1~T5)를 GREEN으로 전환한다.

- T1/T2/T3: `IntentPlacementSettingsPage` 신규 생성 — 3개 옵션 렌더링, 선택 표시기, 탭 시 repo 호출
- T4/T5: `HomePage._DrawSettingsPanel`에 '의도 입력' 진입 행 추가 + GoRouter 라우트 등록

Brief 040 In-Scope #2 항목("설정 페이지 진입점 + 옵션 선택 UI")을 이행한다.

## Scope

### Included
| # | Item | Description |
|---|------|-------------|
| 1 | `intent_placement_settings_page.dart` (신규) | ConsumerStatefulWidget, MysticalScaffold, 3-way 선택 UI |
| 2 | `app_router.dart` 라우트 등록 | `/settings/intent-placement` GoRoute 추가 |
| 3 | `home_page.dart` 진입 행 | `_DrawSettingsPanel` 카드 크기 행 직후 '의도 입력' 행 추가 |
| 4 | `IntentPlacement` extension | `displayLabel` / `shortLabel` / `description` 헬퍼 추가 (enum 파일 내) |

### Excluded
| Item | Reason |
|------|--------|
| 라우팅 분기 (home_page._startDraw, deck_selection_page) | Cycle 3 영역 |
| IntentionPage redirect 조건 | Cycle 3 영역 |
| DrawResultPage 입력 박스 조건부 | Cycle 3 영역 |
| Drift v9 마이그레이션 | Cycle 1 완료 |

## Structural Decisions

| # | Decision | Chosen Option | Rationale |
|---|----------|---------------|-----------|
| 1 | UI 패턴 | `CardSizeSettingsPage._PresetTile` 완전 복제 후 enum 교체 | Brief Model Anchor에 명시, 기존 코드와 시각 일관성 유지 |
| 2 | `IntentPlacement` 헬퍼 위치 | `intent_placement.dart` 내 extension으로 추가 | UI 문자열이 도메인 enum과 함께 위치, import 최소화 |
| 3 | shortLabel 표현 | `'뽑기 전'` / `'뽑은 후'` / `'비활성'` | HOME 패널의 좁은 가로 공간에 맞는 단축 레이블 |
| 4 | 진입 행 위치 | 카드 크기 행 직후, `_GoldHairline` 사이 | 표시 옵션 그룹의 흐름 유지, 카드 크기와 대칭 패턴 |

---

## File Change Summary

### New Files
| # | File Path | Description |
|---|-----------|-------------|
| 1 | `mobile/lib/features/settings/presentation/pages/intent_placement_settings_page.dart` | 3-way 의도 입력 위치 선택 페이지 |

### Modified Files
| # | File Path | Change Description |
|---|-----------|-------------------|
| 1 | `mobile/lib/features/settings/domain/entities/intent_placement.dart` | extension 3개 getter 추가 |
| 2 | `mobile/lib/core/router/app_router.dart` | `/settings/intent-placement` GoRoute + import 추가 |
| 3 | `mobile/lib/features/home/presentation/pages/home_page.dart` | `_DrawSettingsPanel` 진입 행 추가, `IntentPlacement` import 추가 |

---

## Step 1 — IntentPlacement extension 추가

### Approach

`intent_placement.dart`에 extension을 추가하여 UI 문자열을 enum과 함께 관리한다.
TDD Red에 정의된 라벨('뽑기 전 입력', '뽑은 후 입력', '의도 입력 비활성')을 그대로 사용한다.

**Depends on**: Cycle 1 (IntentPlacement enum 이미 존재)

### Current Code

```dart
// mobile/lib/features/settings/domain/entities/intent_placement.dart:1-15
import 'package:json_annotation/json_annotation.dart';

/// 뽑기 플로우에서 의도(질문) 입력이 나타나는 시점.
///
/// - [beforeShuffle]: 셔플 전 IntentionPage를 통과 (기존 동작, 기본값).
/// - [afterDraw]: deck 선택 후 shuffle로 직행, 결과 화면에서 입력.
/// - [disabled]: 의도 입력 없이 진행, reading.question = null.
///
/// JSON 직렬화 key는 enum 이름 그대로 (camelCase): "beforeShuffle", "afterDraw", "disabled".
@JsonEnum()
enum IntentPlacement {
  beforeShuffle,
  afterDraw,
  disabled;
}
```

### After Code

```dart
// mobile/lib/features/settings/domain/entities/intent_placement.dart — 전체 파일 교체
import 'package:json_annotation/json_annotation.dart';

/// 뽑기 플로우에서 의도(질문) 입력이 나타나는 시점.
///
/// - [beforeShuffle]: 셔플 전 IntentionPage를 통과 (기존 동작, 기본값).
/// - [afterDraw]: deck 선택 후 shuffle로 직행, 결과 화면에서 입력.
/// - [disabled]: 의도 입력 없이 진행, reading.question = null.
///
/// JSON 직렬화 key는 enum 이름 그대로 (camelCase): "beforeShuffle", "afterDraw", "disabled".
@JsonEnum()
enum IntentPlacement {
  beforeShuffle,
  afterDraw,
  disabled;
}

/// UI 표시 문자열 헬퍼. enum 파일에 co-locate하여 import 최소화.
extension IntentPlacementLabel on IntentPlacement {
  /// 설정 페이지 목록에 표시하는 전체 라벨.
  String get displayLabel => switch (this) {
        IntentPlacement.beforeShuffle => '뽑기 전 입력',
        IntentPlacement.afterDraw => '뽑은 후 입력',
        IntentPlacement.disabled => '의도 입력 비활성',
      };

  /// HomePage 패널의 좁은 공간용 단축 라벨.
  String get shortLabel => switch (this) {
        IntentPlacement.beforeShuffle => '뽑기 전',
        IntentPlacement.afterDraw => '뽑은 후',
        IntentPlacement.disabled => '비활성',
      };

  /// 설정 페이지 목록에서 옵션 설명으로 표시할 1줄 문장.
  String get description => switch (this) {
        IntentPlacement.beforeShuffle => '셔플 전에 의도/질문을 정리합니다',
        IntentPlacement.afterDraw => '카드를 먼저 보고 떠오른 질문을 적습니다',
        IntentPlacement.disabled => '의도 입력 없이 빠르게 진행합니다',
      };
}
```

### Impact Analysis

- **imports**: 변경 없음 (extension은 같은 파일 내)
- **기존 코드 참조**: `user_settings.dart`, `user_settings_repository.dart` 등이 `intent_placement.dart`를 import하고 있으므로 extension이 자동으로 노출됨
- **빌드**: `@JsonEnum()`에 영향 없음 (extension은 코드 생성 대상 외)

---

## Step 2 — IntentPlacementSettingsPage 신규 생성

### Approach

`CardSizeSettingsPage` 구조를 직접 차용. `ConsumerStatefulWidget` 상속, `MysticalScaffold` 제목 '의도 설정', `userSettingsProvider`로 현재값 읽기, `IntentPlacement.values`를 순회하며 `_IntentTile` 렌더링.

`_IntentTile`은 `CardSizeSettingsPage._PresetTile`과 동일한 시각 패턴:
- 왼쪽: 원형 선택 표시기 (filled + gold border when selected, empty circle when not)
- 가운데: `displayLabel` (primary) + `description` (secondary)
- 오른쪽: `Icons.check_rounded` (selected만 표시)

탭 시 `ref.read(userSettingsRepositoryProvider).updateIntentPlacement(value)` 호출.

**Depends on**: Step 1 (extension getter 사용)

### Current Code

```
(신규 파일 — Before 없음)
```

### After Code

```dart
// mobile/lib/features/settings/presentation/pages/intent_placement_settings_page.dart (신규)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/mystical_scaffold.dart';
import '../../domain/entities/intent_placement.dart';
import '../providers/settings_providers.dart';

class IntentPlacementSettingsPage extends ConsumerStatefulWidget {
  const IntentPlacementSettingsPage({super.key});

  @override
  ConsumerState<IntentPlacementSettingsPage> createState() =>
      _IntentPlacementSettingsPageState();
}

class _IntentPlacementSettingsPageState
    extends ConsumerState<IntentPlacementSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(userSettingsProvider);

    return MysticalScaffold(
      title: '의도 설정',
      body: settingsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: kGold)),
        error: (e, _) => Center(
            child: Text('오류: $e',
                style: const TextStyle(color: kTextSecondary))),
        data: (settings) {
          final current = settings.intentPlacement;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              MysticalCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ...IntentPlacement.values.map((placement) {
                      final isSelected = placement == current;
                      final isLast =
                          placement == IntentPlacement.values.last;
                      return Column(
                        children: [
                          _IntentTile(
                            placement: placement,
                            isSelected: isSelected,
                            onTap: () => ref
                                .read(userSettingsRepositoryProvider)
                                .updateIntentPlacement(placement),
                          ),
                          if (!isLast) GoldHairline(opacity: 0.1),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _IntentTile extends StatelessWidget {
  const _IntentTile({
    required this.placement,
    required this.isSelected,
    required this.onTap,
  });

  final IntentPlacement placement;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? kGold
                      : kSoftPurple.withValues(alpha: 0.4),
                  width: isSelected ? 1.5 : 1,
                ),
                color: isSelected
                    ? kGold.withValues(alpha: 0.15)
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.circle, color: kGold, size: 10)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    placement.displayLabel,
                    style: TextStyle(
                      color: isSelected ? kGold : kTextPrimary,
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  Text(
                    placement.description,
                    style: const TextStyle(
                        color: kTextSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_rounded, color: kGold, size: 18),
          ],
        ),
      ),
    );
  }
}
```

### Impact Analysis

- **imports**: `mystical_scaffold.dart`, `intent_placement.dart`, `settings_providers.dart` — 모두 기존 파일
- **MysticalScaffold 상수**: `kGold`, `kTextSecondary`, `kSoftPurple`, `kTextPrimary`, `GoldHairline`, `MysticalCard` — `mystical_scaffold.dart`에서 export됨 (`CardSizeSettingsPage`와 동일 패턴으로 확인)
- **test**: T1('뽑기 전 입력' 등 텍스트), T2(check icon 존재), T3(updateIntentPlacement 호출) → 모두 GREEN 예상

---

## Step 3 — app_router.dart 라우트 등록

### Approach

기존 `/settings/card-size` GoRoute 패턴을 그대로 복제하여 `/settings/intent-placement` 추가.
`_fadePage`를 사용하며 `name: 'intent-placement-settings'`로 네이밍.

**Depends on**: Step 2 (IntentPlacementSettingsPage 클래스 존재해야 import 가능)

### Current Code

```dart
// mobile/lib/core/router/app_router.dart:163-169
      GoRoute(
        path: '/settings/card-size',
        name: 'card-size-settings',
        pageBuilder: (context, state) => _fadePage(
            key: state.pageKey,
            child: const CardSizeSettingsPage()),
      ),
    ],  // ← routes 닫힘
  );   // ← GoRouter 닫힘
}
```

### After Code

```dart
// mobile/lib/core/router/app_router.dart — import 추가 (13번째 import 뒤)
import '../../features/settings/presentation/pages/intent_placement_settings_page.dart'; // ← NEW

// ...기존 코드 유지...

      GoRoute(
        path: '/settings/card-size',
        name: 'card-size-settings',
        pageBuilder: (context, state) => _fadePage(
            key: state.pageKey,
            child: const CardSizeSettingsPage()),
      ),
      GoRoute(                                                     // ← NEW
        path: '/settings/intent-placement',
        name: 'intent-placement-settings',
        pageBuilder: (context, state) => _fadePage(
            key: state.pageKey,
            child: const IntentPlacementSettingsPage()),
      ),
    ],
  );
}
```

### Impact Analysis

- **imports**: `intent_placement_settings_page.dart` import 1줄 추가 (파일 상단)
- **기존 라우트**: 영향 없음 — routes 리스트 끝에 append
- **GoRouter 재생성**: `app_router.g.dart`는 `@riverpod GoRouter appRouter(...)` 기반이므로 route 추가는 `.g.dart` 재생성 불필요 (GoRoute는 코드 생성 대상 외)
- **T5 테스트**: GoRouter mock에서 `/settings/intent-placement`로 navigate 가능해짐

---

## Step 4 — home_page.dart 진입 행 추가

### Approach

`_DrawSettingsPanel.build`의 카드 크기 행(라인 633~668) 직후, `],` 닫기 전에 `_GoldHairline`과 의도 입력 GestureDetector 행을 삽입한다.

패턴: 기존 카드 크기 행을 완전히 복제하고 아이콘·라벨·값·라우트만 교체.

**Depends on**: Step 1 (IntentPlacement.shortLabel 사용), Step 3 (라우트 등록)

### Current Code

```dart
// mobile/lib/features/home/presentation/pages/home_page.dart:631-672
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
        ],  // ← Column children 닫힘
      ),
    );
  }
}
```

### After Code

```dart
// mobile/lib/features/home/presentation/pages/home_page.dart
// import 추가 (파일 상단, 기존 settings import 그룹 내):
import '../../../settings/domain/entities/intent_placement.dart'; // ← NEW

// ...build 메서드 내 카드 크기 행 직후...

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
          _GoldHairline(opacity: 0.1),                             // ← NEW

          // ── 의도 입력 (별도 페이지 진입) ──                   // ← NEW
          Padding(                                                 // ← NEW
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GestureDetector(
              onTap: () => context.push('/settings/intent-placement'),
              child: Row(
                children: [
                  Icon(Icons.psychology_outlined,
                      size: 14, color: _textSecondary),
                  const SizedBox(width: 8),
                  const Text(
                    '의도 입력',
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    settings?.intentPlacement.shortLabel ?? '뽑기 전',
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
        ],  // ← Column children 닫힘
      ),
    );
  }
}
```

### Impact Analysis

- **imports**: `intent_placement.dart` import 1줄 추가 — `settings?.intentPlacement.shortLabel` 접근을 위해 필요
- **기존 위젯**: `_DrawSettingsPanel` 내 다른 행에 영향 없음
- **T4 테스트**: `find.text('의도 입력')` → findsOneWidget GREEN
- **T5 테스트**: `GestureDetector.onTap` → `context.push('/settings/intent-placement')` 호출 GREEN

---

## Considerations & Trade-offs

### Structural Decisions Log

1. **extension vs 별도 파일**: `IntentPlacement` 관련 UI 문자열을 `intent_placement.dart` 내부 extension으로 넣었다. 별도 파일(`intent_placement_labels.dart`)로 분리하면 도메인/표현 레이어 경계를 더 엄격하게 지킬 수 있지만, `CardSizePreset`이 `label`·`subtitle`을 enum 필드로 직접 갖는 기존 패턴(card_size_preset.dart)에 비춰 extension으로의 co-locate가 더 일관적이다.

2. **`_IntentTile` private 클래스 vs 파일 내 재사용**: `_PresetTile`을 `CardSizeSettingsPage` 외부로 끌어내어 두 페이지가 공유하는 방식도 있다. 그러나 현재 두 타일의 모양이 같더라도 추후 diverge할 여지가 있고, 공유 위젯 추출은 별도 리팩터링 사이클로 분리하는 것이 verify 단위를 좁힌다. Cycle 2에서는 private로 유지.

3. **`Icons.psychology_outlined`**: Brief에 아이콘이 명시되지 않아 자율 선택. 의도·사고를 상징하는 아이콘으로 선정. 변경 필요 시 구현 단계에서 쉽게 교체 가능.

### Alternative Approaches

- **`SettingsPage`에 진입 행 추가**: `home_page._DrawSettingsPanel` 대신 `settings_page.dart`에 추가하는 방법. TDD Red 046의 T4/T5가 `HomePage` 기반이므로 home_page에 추가해야 테스트 GREEN 조건 충족. `018_Scope_user_draw_menu_split.md` 결과가 확정되면 그쪽으로 이전 가능.

- **GoRoute를 Shell 내부로**: `/settings/intent-placement`를 탭 내 중첩 라우트로 넣는 방법. 현재 `/settings/card-size`가 Shell 외부 전체화면으로 등록되어 있으므로 패턴 일치를 위해 Shell 밖 전체화면 라우트로 등록.

### Potential Risks

- `MysticalScaffold`가 `kGold`, `GoldHairline`, `MysticalCard` 등을 export하는지 확인 필요. `CardSizeSettingsPage`가 동일 패턴으로 동작 중이므로 위험도 Low.
- `settings?.intentPlacement` — `UserSettings.intentPlacement` 필드가 Cycle 1에서 추가되었음을 전제. Cycle 1 미완료 시 컴파일 에러 발생.

### Backward Compatibility

- `_DrawSettingsPanel`에 행 추가만이므로 기존 설정 행 동작에 영향 없음.
- `intent_placement.dart` extension 추가는 purely additive — 기존 코드 영향 없음.
- 라우트 추가는 기존 라우트에 영향 없음.

---

## Implementation Checklist

- [ ] Step 1: `intent_placement.dart`에 `IntentPlacementLabel` extension 추가 (displayLabel, shortLabel, description)
- [ ] Step 2: `intent_placement_settings_page.dart` 신규 생성 (ConsumerStatefulWidget, MysticalScaffold, _IntentTile)
- [ ] Step 3: `app_router.dart` — import + GoRoute `/settings/intent-placement` 추가
- [ ] Step 4: `home_page.dart` — import + `_DrawSettingsPanel` 진입 행 추가
- [ ] 테스트 실행: `flutter test test/features/settings/intent_placement_settings_page_test.dart test/features/home/intent_placement_entry_test.dart`
- [ ] 빌드 검증: `cd mobile && flutter build apk --debug`

---

## Verification Assertions

| Level | Assertion | Verification Method | Expected Result |
|-------|-----------|-------------------|-----------------|
| L1-Build | 컴파일 에러 없음 | `flutter build apk --debug` | 빌드 성공 (exit 0) |
| L2-CLI | T1: 3개 옵션 텍스트 렌더링 | `flutter test .../intent_placement_settings_page_test.dart` | T1 pass — '뽑기 전 입력', '뽑은 후 입력', '의도 입력 비활성' 각 1개 |
| L2-CLI | T2: 선택 표시기 (check icon) | 동일 테스트 파일 | T2 pass — Icons.check_rounded 1개 |
| L2-CLI | T3: 탭 시 updateIntentPlacement 호출 | 동일 테스트 파일 | T3 pass — repo.capturedValue == IntentPlacement.afterDraw |
| L2-CLI | T4: '의도 입력' 행 존재 | `flutter test .../intent_placement_entry_test.dart` | T4 pass — find.text('의도 입력') findsOneWidget |
| L2-CLI | T5: 탭 시 라우트 이동 | 동일 테스트 파일 | T5 pass — location contains '/settings/intent-placement' |
| L3-Browser | 의도 설정 페이지 시각 확인 | ADB 스크린샷 (선택) | MysticalScaffold '의도 설정' 타이틀, 3개 행, 첫 행 gold 선택 표시기 |

---

## References

| Resource | Path | Related Content |
|----------|------|-----------------|
| TDD Red 명세 | `docs/2_tarot_draw/03_draw_experience_settings/046_TDD_Red_cycle2_settings_ui.md` | T1~T5 기대값 |
| Brief | `docs/2_tarot_draw/03_draw_experience_settings/040_Brief_intent_placement_setting.md` | Model Anchors, In-Scope #2 |
| Scope | `docs/2_tarot_draw/03_draw_experience_settings/041_Scope_intent_placement_setting.md` | Cycle 2 영역 정의 |
| 패턴 참조 | `mobile/lib/features/settings/presentation/pages/card_size_settings_page.dart` | _PresetTile, MysticalScaffold 패턴 |
| 라우터 | `mobile/lib/core/router/app_router.dart` | 기존 GoRoute 구조 |

---

## 미비점 및 확장 필요 영역

### Plan 미비점 (makeplan 기록)
| # | 항목 | 심각도 | 설명 |
|---|------|--------|------|
| 1 | `IntentionPage` 공유 import 경로 확인 | Low | `mystical_scaffold.dart`가 `kGold` 등 상수를 export하는지 `CardSizeSettingsPage`와 동일 경로로 확인 필요. 구현 시 빌드 에러로 즉시 확인 가능. |

### Implementation 미비점 (implementation 기록)
<!-- 구현 중 채움 -->

### Verification 미비점 (verify 기록)
<!-- 검증 중 채움 -->
