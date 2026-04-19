---
id: "mobile-lib-features-home-presentation-pages-home_page"
type: explanation
target: "mobile/lib/features/home/presentation/pages/home_page.dart"
layer: "file"
version: 1
created: 2026-04-19
updated: 2026-04-19
last_explained_commit: "5d5139756735ff09cd11cdae4d08cba0b987e501"
functions: []
---

# home_page.dart — 해설

## 개요
뽑기 탭(탭 0)의 루트 화면이다. 황금 오브 버튼을 중심으로 한 히어로 섹션과 뽑기 설정 패널, 최근 리딩 목록을 하나의 세로 스크롤로 구성한다. 파일 내부에서만 쓰이는 `_Private` 위젯들로 레이아웃을 분리하며, 외부 라우트나 별도 파일 없이 이 파일 하나가 뽑기 탭 전체 UI를 담당한다.

## 역할 (Role)
- **뽑기 진입점**: 체험 레벨(`experienceLevel`)에 따라 즉시 결과 → 연출 애니메이션 → 2D 셔플 → 2.5D 셔플 중 하나로 라우팅한다.
- **설정 인라인 편집**: 별도 설정 페이지 이동 없이 덱 선택·레벨·카드 수·스프레드·역방향·표시 옵션을 즉시 변경한다.
- **최근 리딩 요약**: 최대 3건을 노출하여 리딩 히스토리로 빠르게 접근할 수 있도록 한다.

## 구조 (Structure)

파일 내 클래스·위젯 목록 (공개 1개 + 비공개 14개):

| 클래스 | 역할 |
|--------|------|
| `HomePage` (`ConsumerStatefulWidget`) | 루트 화면 위젯. Riverpod 구독 + glow 애니메이션 관리 |
| `_HomePageState` | `initState`에서 덱 시드 + 애니메이션 컨트롤러 초기화 |
| `_StarfieldBackground` | 미스틱 방사형 그라디언트 + 별 CustomPaint 배경 |
| `_StarPainter` | 전역 `_starPositions` 기반 Canvas 별 렌더링 |
| `_HeroSection` | 앱 타이틀 + 오브 버튼 + "초기화 중" 텍스트 묶음 |
| `_AppTitle` | ShaderMask 골드 그라디언트 "PERSONALITY TAROT" 텍스트 |
| `_GlowOrb` | AnimatedBuilder + RadialGradient + BoxShadow 애니메이션 버튼 |
| `_DrawSettingsPanel` | "기본 설정" / "표시 옵션" 두 그룹으로 구성된 설정 패널 컨테이너 |
| `_SettingRow` | 아이콘 + 레이블 + 우측 컨트롤의 단일 설정 행 |
| `_GoldDropdown<T>` | 골드 테두리 드롭다운 (덱 선택) |
| `_PillSelector<T>` | 가로 pill 버튼 그룹 (레벨·스프레드 선택) |
| `_CountStepper` | − / 값 / + 스텝 버튼 (카드 수) |
| `_StepBtn` | 스텝퍼의 개별 원형 버튼 |
| `_GoldSwitch` | 골드 테마 Switch (역방향·앞면·카드 이름) |
| `_RecentReadingsSection` | 최근 리딩 최대 3건 목록 |
| `_ReadingCard` | 개별 리딩 카드 행 (스프레드 타입·질문·날짜) |
| `_PanelSubheader` | 설정 그룹 소제목 ("기본 설정" / "표시 옵션") |
| `_GoldHairline` | 골드 그라디언트 0.7px 구분선 (파일 내 전용, `mystical_scaffold.dart`의 `GoldHairline`과 별개) |

레이아웃 트리 (현재 구조):

```
Scaffold
└── Stack
    ├── _StarfieldBackground        ← 별 배경 (Positioned.fill)
    └── SafeArea
        └── SingleChildScrollView   ← 단일 스크롤
            └── Column
                ├── _HeroSection    ← Padding(vertical: 48)
                ├── _GoldHairline
                ├── _DrawSettingsPanel
                └── _RecentReadingsSection
```

## 동작 흐름 (Flow)

### 초기화
1. `initState` → `_initializeApp()` 비동기 실행: `deckRepository.seedAllDecks()` 완료 후 `_initialized = true`
2. `AnimationController` (2800ms, repeat+reverse) → `_glowAnim` (easeInOut) 시작

### 뽑기 시작 (`_startDraw`)
```dart
switch (experienceLevel) {
  case 1: context.push('/draw/result');         // 즉시 결과
  case 2: context.push('/draw/animated');       // 연출 애니메이션
  case 3: pushNamed('intention', mode: flat);   // 2D 셔플
  case 4: pushNamed('intention', mode: perspective); // 2.5D 셔플
}
```
`_GlowOrb.onTap` → `_initialized` 이전에는 null로 막힘.

### 설정 변경
각 컨트롤의 `onChanged` → `userSettingsRepository` 메서드 직접 호출 (별도 저장 버튼 없음):
- `updateSelectedDeckId`, `updateExperienceLevel`, `updateDefaultCardCount`
- `updateDefaultSpreadType`, `updateAllowReversed`, `updateShowFaceUp`
- `updateShowCardName`, `updateCardsPerRow`

카드 크기만 별도 페이지: `context.push('/settings/card-size')`

### 최근 리딩
`watchReadingsProvider` 스트림 → 비어 있으면 플레이스홀더, 있으면 최대 3건 `_ReadingCard` → 탭 시 `/readings/:id` push

## 의존성 (Dependencies)

| 대상 | 종류 | 역할 |
|------|------|------|
| `mystical_scaffold.dart` | 내부(core) | 색상 상수(`kGold` 등) 공유. **단, `MysticalScaffold` 위젯은 미사용** — `Scaffold` 직접 사용 |
| `deck_providers.dart` | 내부(feature) | `deckRepositoryProvider`, `watchDecksProvider` |
| `reading_providers.dart` | 내부(feature) | `watchReadingsProvider` |
| `settings_providers.dart` | 내부(feature) | `userSettingsProvider`, `userSettingsRepositoryProvider` |
| `shuffle_mode.dart` | 내부(feature) | `ShuffleMode.flat/perspective` 라우트 파라미터 |
| `spread_type.dart` | 내부(feature) | `SpreadType` 열거형 |
| `user_settings.dart` | 내부(feature) | `UserSettings` 엔티티 |
| `go_router` | external | `context.push`, `context.pushNamed` |
| `flutter_riverpod` | external | `ConsumerStatefulWidget`, `ref.watch` |

## 주의사항 (Caveats)

- **별 배경 코드 중복**: `_StarfieldBackground` + `_StarPainter` + `_starPositions`는 `mystical_scaffold.dart`의 `MysticalBackground`와 구현이 동일하다. `MysticalScaffold`를 쓰지 않고 독자 `Scaffold`를 사용하기 때문에 발생한 중복이다.
- **`_GoldHairline` 중복**: `mystical_scaffold.dart`의 `GoldHairline`(공개)과 이 파일의 `_GoldHairline`(비공개)은 코드가 동일하다. 임포트 없이 로컬 정의로 해결한 것.
- **`_initialized` 가드**: `seedAllDecks()`가 완료되기 전에는 오브 버튼이 비활성화(onTap = null). 완료 직후 `setState` → 리빌드로 활성화.
- **설정 즉시 저장**: 각 컨트롤마다 repository 메서드를 직접 호출하므로, 변경 즉시 DB에 반영된다. "저장" 버튼이 없으며 실수 취소 수단이 없다.
- **최근 리딩 상한 3건**: `list.take(3)`로 고정. 전체 목록은 저장 탭에서 확인해야 한다.
- **색상 상수 이중 정의**: 파일 상단(line 16~22)에 `_gold`, `_deepPurple` 등을 로컬 `const`로 선언하면서 `mystical_scaffold.dart`의 `kGold` 등과 값은 같지만 이름이 다르다.

## Changelog
### v1 (2026-04-19) — 최초 작성
- 최초 해설 문서 생성.
