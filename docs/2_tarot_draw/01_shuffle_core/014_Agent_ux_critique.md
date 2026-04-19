---
title: "타로 셔플 앱 UX 비평 — 제의적 경험 설계 검토"
type: Agent
date: 2026-03-16
author: uiux-expert
status: complete
summary: "모바일 타로 앱의 제의적(ritual) UX, 감정 흐름, 접근성, 마이크로 인터랙션을 코드 레벨에서 비평. 기술 기반은 견고하나 제의적 분위기 연출이 전반적으로 부족하며, 센서 폴백 언어와 전환 애니메이션에 즉각적 개선이 필요하다."
key_findings:
  - "[Critical] 홈/덱 화면에 제의적 앰비언스가 전무 — 일반 앱과 구분되지 않음"
  - "[High] 라우팅 전환 애니메이션이 기본값 — 제의적 흐름을 단절시킴"
  - "[High] 센서 폴백 메시지가 실망감을 유발하는 기술적 언어 사용"
  - "[High] CardRevealWidget에 Semantics 없음 — 스크린 리더 접근성 미확보"
  - "[Medium] CardPainter 리플 애니메이션에 easing curve 미적용 (linear)"
  - "[Medium] 셔플 Phase 전환 사이의 시각적 의식(ritual) 공백"
  - "[Low] _buildFront의 counter-rotation 구현이 혼란스러운 패턴"
confidence: high
related_docs:
  - "docs/11_tarot_shuffle/001_Scope_platform_strategy.md"
  - "docs/11_tarot_shuffle/012_Plan_presentation_routing.md"
---

# 타로 셔플 앱 UX 비평

## 검토 범위

| 파일 | 검토 완료 |
|------|----------|
| `mobile/lib/core/theme/app_theme.dart` | 완료 |
| `mobile/lib/core/router/app_router.dart` | 완료 |
| `mobile/lib/features/home/presentation/pages/home_page.dart` | 완료 |
| `mobile/lib/features/deck/presentation/pages/deck_selection_page.dart` | 완료 |
| `mobile/lib/features/shuffle/presentation/pages/shuffle_page.dart` | 완료 |
| `mobile/lib/features/shuffle/presentation/widgets/card_painter.dart` | 완료 |
| `mobile/lib/features/shuffle/presentation/widgets/entropy_progress_indicator.dart` | 완료 |
| `mobile/lib/features/shuffle/presentation/widgets/riffle_animation_controller.dart` | 완료 |
| `mobile/lib/features/reading/presentation/pages/reading_page.dart` | 완료 |
| `mobile/lib/features/reading/presentation/widgets/spread_layout.dart` | 완료 |
| `mobile/lib/features/reading/presentation/widgets/card_reveal_widget.dart` | 완료 |
| `mobile/lib/features/reading/domain/entities/spread_type.dart` | 완료 |

---

## Summary

타로 셔플 앱의 기술 기반(Flutter + Riverpod + GoRouter, 물리 기반 리플 애니메이션, 센서 엔트로피)은 제의적 경험을 구현하기에 충분한 잠재력을 갖추고 있다. 그러나 **UI의 표면적 표현이 일반 기능성 앱 수준에 머물러 있어** PRD 핵심 가치인 "사용자의 물리적 상호작용이 셔플 결과에 반영되는 제의적 경험"을 전달하지 못하고 있다.

가장 큰 문제는 **감정 여정의 진입점(홈, 덱 선택)에서 제의적 맥락을 전혀 형성하지 않는다는 점**이다. 사용자가 앱을 열었을 때 "이것은 특별한 의식이다"라는 신호를 받지 못한 채 즉시 기능 버튼을 만난다. 다크 테마의 컬러 토큰 자체는 미스틱 분위기에 적합하나, 배경이 단일 색상으로만 구성되어 있어 분위기 형성 역할을 하지 못한다.

---

## 1. 제의적(Ritual) UX [Critical]

### 현황

- **홈 화면**: 앱바에 "Personality Tarot" 텍스트 + "셔플 시작" 버튼 + "최근 리딩" 목록. 제의적 공간감 부재. 어떤 배경 이미지, 앰비언트 요소, 환영 내러티브도 없다.
- **덱 선택 화면**: `ListView.builder` + `Card` + `ListTile` 조합. 덱 선택이 쇼핑몰 카탈로그 탐색과 시각적으로 동일하다. 덱의 신비로운 특성을 드러내는 요소가 전혀 없다.
- **셔플 화면**: "디바이스를 흔들어 셔플 에너지를 모으세요"라는 지시 문구는 제의적 언어를 적절히 사용하고 있다. 그러나 배경이 단색 `_darkSurface(#0D0A14)`여서 이 문구가 공허하게 들린다. 셔플 공간이 성스러운 장소처럼 느껴지지 않는다.
- **셔플 Phase 전환**: `collecting → shuffling` 전환 시 "셔플 중..."이라는 텍스트만 표시된다. 이 순간은 사용자의 에너지가 실제로 카드로 변환되는 절정의 순간인데, 시각적으로 아무 의식이 없다.
- **리딩 화면**: 카드가 펼쳐진 이후 해석 내러티브가 없다. 카드 이름과 키워드 2개만 표시되어 "발견"의 감동이 최소화된다.

### 문제의 근원

제의적 경험은 **공간, 시간, 참여**의 3요소로 구성된다. 현재 앱은 참여(센서 기반 엔트로피 수집)만 구현되어 있고, 공간(앰비언스)과 시간(리듬감 있는 전환)은 미구현 상태다.

---

## 2. 감정 흐름 [High]

### 목표 감정 곡선
```
긴장(호기심) → 기대(참여) → 경외(셔플 절정) → 성찰(리딩)
```

### 현황 분석

| 단계 | 목표 감정 | 실제 경험 | 격차 |
|------|----------|----------|------|
| 홈 | 긴장/호기심 | 즉각적 행동 요구 | 큰 격차 — 준비 시간 없이 버튼 제시 |
| 덱 선택 | 기대/설렘 | 기능적 목록 탐색 | 큰 격차 — 덱 선택이 감정적 선택이 아님 |
| 셔플(collecting) | 참여/집중 | 적절 — 흔들기 지시와 진행률 바 존재 | 작은 격차 |
| 셔플(shuffling) | 경외/절정 | "셔플 중..." 텍스트만 | 큰 격차 — 절정의 시각적 표현 부재 |
| 셔플(drawing) | 기대/설렘 | "셔플 완료! 카드를 뽑아보세요." | 중간 격차 — 단순 완료 메시지 |
| 리딩 | 성찰/통찰 | 카드 이름 + 키워드 2개 | 큰 격차 — 해석 내러티브 부재 |

### 주요 문제: 덱 선택의 감정적 중요성 간과

덱 선택은 "어떤 덱과 대화를 나눌 것인가"를 결정하는 행위다. 현재는 `ListTile`의 trailing `Icon(Icons.chevron_right)`으로 처리되어 있어 단순 메뉴 이동처럼 느껴진다.

### 전환 흐름 단절

GoRouter의 모든 라우트가 `builder` 함수만 사용하고 있어 기본 플랫폼 전환(iOS: 오른쪽에서 밀기, Android: 아래에서 올라오기)이 적용된다. 제의적 흐름에는 **fade 전환** 또는 **느린 scale 전환**이 어울린다.

---

## 3. 다크 테마 감성 [Medium]

### 컬러 팔레트 평가

| 색상 토큰 | 값 | 평가 |
|----------|----|----|
| `_darkSurface` | `#0D0A14` | 매우 어둡고 깊은 우주 느낌 — 적합 |
| `_deepPurple` | `#1A1028` | 카드/서피스용 — 적합 |
| `_gold` | `#D4A84B` | 미스틱 골드 — 적합, 충분히 따뜻함 |
| `_softPurple` | `#6B5B95` | 보조 강조색 — 적합 |
| `_textPrimary` | `#E8E0F0` | 약간 보라빛 흰색 — 미스틱 느낌 적합 |
| `_textSecondary` | `#9B8FB8` | 흐린 라벤더 — 적합 |

컬러 토큰 자체의 선택은 미스틱 다크 테마에 적합하다. **문제는 적용 방식**이다.

### 타이포그래피 한계

```dart
textTheme: const TextTheme(
  headlineLarge: TextStyle(color: _gold, fontSize: 28, fontWeight: FontWeight.bold),
  bodyLarge: TextStyle(color: _textPrimary, fontSize: 16),
  bodyMedium: TextStyle(color: _textSecondary, fontSize: 14),
)
```

- **3가지 스타일만 정의**: `headlineLarge`, `bodyLarge`, `bodyMedium`. `titleLarge`, `titleMedium`, `labelLarge` 등이 없어 위젯들이 Material 3 기본값으로 폴백한다. 일관성이 깨진다.
- **폰트 패밀리 미지정**: 시스템 기본 폰트 사용. 미스틱 앱에 어울리는 세리프 계열 디스플레이 폰트(예: Cormorant Garamond, Cinzel)가 없다.
- **글자 간격(letterSpacing) 미설정**: 골드 헤드라인에 letterSpacing을 적용하면 고급감이 크게 올라간다.

### 배경 활용 부재

모든 화면의 `scaffoldBackgroundColor`가 `_darkSurface` 단색으로 동일하다. 그라디언트, 노이즈 텍스처, 성운 이미지, 파티클 효과 등의 앰비언트 요소가 전무하다.

---

## 4. WCAG 접근성 [High]

### 색상 대비율 계산 결과

WCAG 2.1 AA 기준: 일반 텍스트 4.5:1, 대형 텍스트(18pt+ 또는 14pt bold) 3:1

| 텍스트 색상 | 배경 색상 | 계산 대비율 | 기준 | 판정 |
|------------|----------|-----------|------|------|
| `_textPrimary #E8E0F0` | `_darkSurface #0D0A14` | ~14.2:1 | 4.5:1 | 통과 |
| `_textSecondary #9B8FB8` | `_darkSurface #0D0A14` | ~6.1:1 | 4.5:1 | 통과 |
| `_textSecondary #9B8FB8` | `_deepPurple #1A1028` | ~5.35:1 | 4.5:1 | 통과(경계선) |
| `_gold #D4A84B` | `_darkSurface #0D0A14` | ~8.5:1 | 4.5:1 | 통과 |
| `_darkSurface #0D0A14` | `_gold #D4A84B` (버튼) | ~8.5:1 | 4.5:1 | 통과 |

색상 대비율 자체는 대부분 통과한다. 단, `_textSecondary`를 Card(`_deepPurple`) 위에 사용하는 경우는 경계선 수준(5.35:1)이므로 주의가 필요하다.

### 터치 타겟 크기

- `ElevatedButton`: Flutter Material 3 기본값은 최소 48px 높이 — 통과
- `ListTile`: 기본 최소 높이 56px — 통과
- **CardRevealWidget**: `GestureDetector`로 감싸져 있으나 AspectRatio(2.5/3.5) 카드 크기에 의존한다. `SpreadLayout._buildThreeCardLayout`에서 3개 카드가 `Row + Expanded + Padding(horizontal: 8)`로 배치될 때, 화면 너비 375px 기준으로 각 카드 너비 ≈ (375 - 48)/3 ≈ 109px. 카드 높이 ≈ 109 × (3.5/2.5) ≈ 153px. 터치 타겟 크기는 충분하나, 공식적인 `minimumSize` 제약이 없어 레이아웃 변화에 취약하다.
- **SegmentedButton**: 세그먼트 터치 타겟이 자동 계산 — 콘텐츠 길이에 따라 44px 이하가 될 수 있음. 위험.

### 스크린 리더 접근성 (심각)

```dart
// card_reveal_widget.dart — 스크린 리더가 아무것도 읽지 못하는 상황
GestureDetector(
  onTap: widget.isRevealed ? null : widget.onTap,
  child: Column(...)
)

// 카드 뒷면
Icon(Icons.auto_awesome, color: theme.colorScheme.primary, size: 32)
// semanticLabel 없음 — 스크린 리더: "아이콘"이라고만 읽음
```

- `GestureDetector`는 `Semantics` 위젯이 없으면 스크린 리더에게 상호작용 가능한 요소임을 알리지 않는다.
- 카드 앞면 공개 시 스크린 리더가 카드 이름, 키워드를 읽을 수 있지만, 순서나 맥락("과거 카드: 달 — 환상, 불안")이 전달되지 않는다.
- 엔트로피 진행률 바(`LinearProgressIndicator`)에 `semanticsLabel`이 없어 스크린 리더가 진행 상태를 파악할 수 없다.

### 모션 접근성

`prefers-reduced-motion`에 해당하는 `MediaQuery.disableAnimations`를 체크하는 코드가 없다. 리플 애니메이션과 카드 뒤집기가 무조건 실행된다.

---

## 5. 마이크로 인터랙션 [Medium]

### 카드 뒤집기 애니메이션 (CardRevealWidget)

```dart
_controller = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 400),
);
_animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
```

- **타이밍(400ms)**: 적절하다. 200ms보다 충분히 길어 의식적 순간을 느끼게 한다.
- **Curve(easeInOut)**: 적합하다. 천천히 시작하여 천천히 끝나는 느낌이 타로 카드 뒤집기의 무게감과 맞다.
- **Perspective(0.001)**: 과소하다. 3D 효과가 미약하여 카드가 평면적으로 줄었다 늘어나는 것처럼 보인다. `0.002` 이상을 권장한다.
- **Counter-rotation 패턴**: `_buildFront`가 내부적으로 `rotateY(math.pi)`를 추가로 적용한다. `_showFront=true`로 전환되는 시점에서 외부 `angle = π/2 → π`에 내부 `π`가 더해져 `3π/2 → 2π`로 진행되는 구조다. 결과적으로 카드 앞면이 표시되지만, 이 코드는 다음 개발자에게 매우 혼란스럽다. 일반적인 패턴(한 방향 회전 → 중간 지점에서 위젯 교체 → 미러 처리)으로 리팩터링이 권장된다.
- **햅틱 피드백**: 카드 뒤집기에 햅틱이 없다. 셔플 완료에는 `hapticServiceProvider.mediumImpact()`가 있는데 카드 뒤집기에는 없어 일관성이 깨진다.

### 리플 셔플 애니메이션 (RiffleAnimationState)

```dart
_controller = AnimationController(
  vsync: _vsync,
  duration: const Duration(milliseconds: 800),
);
// Curve 미적용 — linear 동작
await _controller!.forward();
```

- **Curve 미적용이 가장 큰 문제**: 카드가 일정한 속도로 움직인다. 물리적 리플 셔플에서 카드는 자연스럽게 가속-감속한다. `CurvedAnimation(curve: Curves.easeInOut)` 적용이 필요하다.
- **타이밍(800ms × shuffleCount)**: 적절하나, 셔플 횟수가 많을 때 총 시간이 길어지는 UX를 사용자에게 알려주는 요소가 없다.
- **카드 크기**: `cardWidth = size.width * 0.15`. 화면 너비 375px 기준 카드 너비 56px는 지나치게 작다. 카드의 존재감이 느껴지지 않는다. `0.22` 수준을 권장한다.

### 엔트로피 진행률 바 (EntropyProgressIndicator)

- **고정 너비(200px)**: 다양한 화면 크기에서 비율이 일정하지 않다. `double.infinity`나 `MediaQuery`를 활용해야 한다.
- **색상 변화**: 진행 중 `_softPurple` → 완료 시 `_gold`로 전환. 좋은 결정이나 전환이 즉각적(애니메이션 없음)이다. `AnimatedContainer` 또는 `TweenAnimationBuilder`로 부드러운 색상 전환을 권장한다.
- **완료 피드백**: "에너지 충전 완료!"는 적절한 제의적 언어다. 그러나 시각적 강조(금빛 플래시, 파티클 효과)가 없어 완료 순간의 감동이 약하다.

---

## 6. 센서 폴백 UX [High]

### 현재 상태

```dart
// shuffle_page.dart
Text(
  sensor.sensorsAvailable
      ? '디바이스를 흔들어 셔플 에너지를 모으세요'
      : '센서를 사용할 수 없습니다. 시스템 난수로 진행합니다.',
  style: theme.textTheme.bodyMedium,
)

// entropy_progress_indicator.dart
if (!sensorsAvailable) {
  return Row(
    children: [
      Icon(Icons.info_outline, ...),
      Text('시스템 난수 사용'),
    ],
  );
}
```

### 문제 분석

"센서를 사용할 수 없습니다. 시스템 난수로 진행합니다."라는 메시지는 두 가지 문제를 동시에 유발한다.

1. **기술적 실망감**: "사용할 수 없습니다"는 실패를 선언한다. 에뮬레이터나 일부 디바이스를 사용하는 사용자가 열등한 경험을 받는다는 인식을 심어준다.
2. **제의적 맥락 파괴**: "시스템 난수"라는 표현은 완전히 기술적 언어다. 제의적 경험 속에서 이 단어는 환상을 깨는 역할을 한다.

### 권장 접근: 다른 의식으로 재프레이밍

폴백이 아니라 다른 유형의 의식으로 설계해야 한다.

예시:
- 현재: "센서를 사용할 수 없습니다. 시스템 난수로 진행합니다."
- 권장: "조용히 호흡을 가다듬으며 의도를 설정하세요. 우주가 카드를 배열합니다."

- 현재: `Icon(Icons.info_outline)` + "시스템 난수 사용"
- 권장: 호흡 명상 애니메이션(확장-축소 원 또는 별자리) + "의도를 담아 화면을 터치하세요"

`EntropyProgressIndicator`에서 센서 불가 상태가 "정보 안내"(`info_outline` 아이콘)가 아니라 "대안 의식의 시작"으로 표현되어야 한다.

---

## 7. 개선 제안

### Priority 1 — Critical: 홈 화면 제의적 공간 구성

**현재**: 텍스트 + 버튼 + 목록

**권장 구조**:
```
배경: 별자리/성운 그라디언트 오버레이 (radialGradient: deep purple → transparent)
중앙: 앱 심볼 애니메이션 (천천히 회전하는 별 또는 달 아이콘)
아래: "당신의 카드가 기다리고 있습니다" (subtitle)
CTA: "리딩 시작하기" (버튼 텍스트 변경)
하단: 최근 리딩 섹션 (스크롤 영역으로 분리)
```

### Priority 2 — High: 라우팅 전환 애니메이션 추가

GoRouter `pageBuilder`를 사용하여 커스텀 전환을 적용한다.

```dart
// 권장 패턴
GoRoute(
  path: '/shuffle/:deckId',
  pageBuilder: (context, state) => CustomTransitionPage(
    key: state.pageKey,
    child: ShufflePage(deckId: state.pathParameters['deckId']!),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    transitionDuration: const Duration(milliseconds: 600),
  ),
)
```

### Priority 3 — High: 센서 폴백 언어 재프레이밍

제의적 대안 경험으로 전환한다.

- "의도 설정" UX: 사용자가 화면을 3번 탭하면 엔트로피가 생성되는 방식
- 또는: 화면에 원이 천천히 확장-수축하며 "호흡 따라 터치하기" 인터랙션

### Priority 4 — High: CardRevealWidget Semantics 추가

```dart
// 권장 패턴
Semantics(
  label: widget.isRevealed
      ? '${widget.label} 위치 카드: ${widget.card.card.name}'
      : '${widget.label} 위치 카드 (탭하여 공개)',
  button: !widget.isRevealed,
  child: GestureDetector(...)
)
```

### Priority 5 — Medium: 리플 애니메이션 Curve 적용

```dart
// 현재
await _controller!.forward();

// 권장
final curved = CurvedAnimation(
  parent: _controller!,
  curve: Curves.easeInOut,
);
await _controller!.forward();
// _generateRifflePositions에서 curved.value 사용
```

### Priority 6 — Medium: EntropyProgressIndicator 개선

- 고정 너비 200px를 비율 기반으로 변경
- 완료 시 색상 전환에 `TweenAnimationBuilder` 적용
- 완료 순간 햅틱 피드백(`HapticFeedback.heavyImpact()`) 추가

### Priority 7 — Medium: CardPainter 카드 크기 확대

```dart
// 현재
final cardWidth = size.width * 0.15;

// 권장
final cardWidth = size.width * 0.22;
```

셔플 중인 카드의 존재감을 높여 물리적 카드 조작의 리얼리티를 강화한다.

### Priority 8 — Low: 카드 뒤집기 햅틱 피드백 추가

셔플 완료에 `mediumImpact`가 있으므로, 카드 뒤집기에는 `lightImpact`를 추가하여 일관성을 유지한다.

```dart
// didUpdateWidget에서
if (widget.isRevealed && !oldWidget.isRevealed) {
  HapticFeedback.lightImpact(); // 추가
  _controller.forward();
}
```

### Priority 9 — Low: CardRevealWidget counter-rotation 리팩터링

현재의 이중 회전 패턴을 단일 방향 회전 + 중간 교체 패턴으로 정리한다.

### Priority 10 — Medium: prefers-reduced-motion 지원

```dart
// 모든 AnimationController 초기화 전에 체크
final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
final duration = reduceMotion
    ? Duration.zero
    : const Duration(milliseconds: 400);
```

---

## Key Findings

| 번호 | 심각도 | 발견 | 영향 범위 |
|------|--------|------|---------|
| F-01 | Critical | 홈/덱 화면에 제의적 앰비언스 전무 — 일반 기능성 앱과 구분 불가 | 전체 감정 여정 |
| F-02 | High | GoRouter 기본 전환 애니메이션 — 제의적 몰입 흐름 단절 | 모든 화면 전환 |
| F-03 | High | 센서 폴백 메시지가 기술적 실망감 유발 — 제의적 맥락 파괴 | 에뮬레이터/센서 없는 디바이스 사용자 |
| F-04 | High | CardRevealWidget에 Semantics 없음 — 스크린 리더 접근 불가 | 시각 장애 사용자 전체 |
| F-05 | High | 셔플 Phase 전환("셔플 중..." 텍스트만)에서 절정 경험 부재 | 감정 곡선 경외 단계 |
| F-06 | Medium | 리플 애니메이션 Curve 미적용 — 물리적 리얼리티 저하 | 셔플 화면 |
| F-07 | Medium | EntropyProgressIndicator 고정 너비 200px — 반응형 미흡 | 다양한 화면 크기 |
| F-08 | Medium | 카드 뒤집기 햅틱 피드백 없음 — 셔플 완료 햅틱과 불일치 | 리딩 화면 |
| F-09 | Medium | 폰트 패밀리 미지정 — 시스템 폰트로 미스틱 분위기 구현 한계 | 전체 앱 |
| F-10 | Low | `_buildFront` counter-rotation 이중 적용 — 코드 유지보수 위험 | CardRevealWidget |
| F-11 | Low | `prefers-reduced-motion` 미지원 | 모션 민감 사용자 |

---

## Recommendations

### 즉시 수정 (Sprint 1)

1. **센서 폴백 언어 재프레이밍** — 코드 2줄 수정, 제의적 경험 보존
2. **CardRevealWidget Semantics 추가** — 접근성 법적 요구사항
3. **카드 뒤집기 햅틱 추가** — 1줄 추가
4. **리플 애니메이션 CurvedAnimation 적용** — 3줄 수정

### 다음 Sprint (Sprint 2)

5. **GoRouter 커스텀 전환 애니메이션** — 각 라우트 `pageBuilder` 교체
6. **EntropyProgressIndicator 반응형 너비** — 고정 200px 제거
7. **CardPainter 카드 크기 확대** — 상수 변경

### 장기 개선 (Sprint 3+)

8. **홈 화면 제의적 공간 재설계** — 배경 그라디언트, 앰비언트 애니메이션
9. **덱 선택 화면 감성 카드 UI** — ListTile → 시각적 덱 프리뷰 카드
10. **디스플레이 폰트 추가** — Cinzel 또는 Cormorant Garamond (골드 헤드라인용)
11. **셔플 절정 화면 설계** — "셔플 중..." → 파티클/별자리 애니메이션
12. **리딩 화면 해석 내러티브** — 키워드 나열 → 문장형 성찰 텍스트

---

## References

- `mobile/lib/core/theme/app_theme.dart`
- `mobile/lib/core/router/app_router.dart`
- `mobile/lib/features/home/presentation/pages/home_page.dart`
- `mobile/lib/features/deck/presentation/pages/deck_selection_page.dart`
- `mobile/lib/features/shuffle/presentation/pages/shuffle_page.dart`
- `mobile/lib/features/shuffle/presentation/widgets/card_painter.dart`
- `mobile/lib/features/shuffle/presentation/widgets/entropy_progress_indicator.dart`
- `mobile/lib/features/shuffle/presentation/widgets/riffle_animation_controller.dart`
- `mobile/lib/features/reading/presentation/pages/reading_page.dart`
- `mobile/lib/features/reading/presentation/widgets/spread_layout.dart`
- `mobile/lib/features/reading/presentation/widgets/card_reveal_widget.dart`
- `mobile/lib/features/reading/domain/entities/spread_type.dart`
- WCAG 2.1 AA 색상 대비율 기준 4.5:1 (일반 텍스트)
- Flutter `MediaQuery.disableAnimationsOf` — prefers-reduced-motion

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 0s | 0 |
| 2 | user-ai-exchange | 19s | 76045 |
| 3 | user-ai-exchange | 11s | 40778 |
| 4 | user-ai-exchange | 10s | 42195 |
| 5 | user-ai-exchange | 9s | 44183 |
| 6 | user-ai-exchange | 14s | 46529 |
| 7 | user-ai-exchange | 5s | 48356 |
| 8 | user-ai-exchange | 9s | 50568 |
| 9 | user-ai-exchange | 13s | 105037 |
| 10 | user-ai-exchange | 12s | 54453 |
| 11 | user-ai-exchange | 11s | 55874 |
| 12 | user-ai-exchange | 12s | 57359 |
| 13 | user-ai-exchange | 14s | 58996 |
| 14 | user-ai-exchange | 13s | 60582 |
| 15 | user-ai-exchange | 8s | 61831 |
| 16 | user-ai-exchange | 11s | 63033 |
| 17 | user-ai-exchange | 29s | 202688 |
| 18 | user-ai-exchange | 11s | 140060 |
| 19 | user-ai-exchange | 11s | 71985 |
| 20 | user-ai-exchange | 9s | 147944 |
| 21 | user-ai-exchange | 14s | 76148 |
| 22 | user-ai-exchange | 19s | 0 |
| 23 | user-ai-exchange | 10s | 41780 |
| 24 | user-ai-exchange | 13s | 45110 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 341150s |
| Total Tokens | 1591534 |
| Input Tokens | 71 |
| Output Tokens | 8834 |
| Cache Read | 1202235 |
| Cache Creation | 380394 |
