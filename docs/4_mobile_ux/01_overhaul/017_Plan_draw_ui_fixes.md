---
id: "017"
type: plan
title: "뽑기 결과 화면 UI 3건 수정 — 구현 계획"
created: 2026-04-05
traces_scope: "016"
summary: >
  카드 위젯 오버플로우 수정(Flexible 래핑), 카드 이미지 로딩 복원(cacheWidth 디버깅), 성찰 섹션 삭제(양쪽 페이지). 4개 파일 수정.
---

# 뽑기 결과 화면 UI 3건 수정 — 구현 계획

## 변경 요약

3개 이슈를 4개 파일에서 수정한다. 모두 프레젠테이션 레이어 변경이며 도메인/데이터 레이어 변경 없음.

---

## Issue 1: 바텀 오버플로우 3.3px

### 원인 분석

`CardRevealWidget.build()`의 Column(mainAxisSize: min)이 GridView의 `childAspectRatio: 0.65` 할당 공간을 초과한다.

Column 내부 구성:
1. `Text(label)` — bodyMedium (~16px line height)
2. `SizedBox(height: 8)`
3. `AspectRatio(2.5/3.5)` — 이 위젯이 남은 공간 전체를 차지하려 하지만 Flexible 미적용
4. (조건부) `Padding(top:4) + Text('역방향...')` — 역방향 카드 시 추가 ~20px

Column이 min sizing이므로 모든 자식의 intrinsic height 합산이 GridView 셀 높이를 초과할 때 오버플로우 발생. 특히 역방향 텍스트가 있는 카드에서 3.3px 초과.

참고: AnimatedDrawPage의 `_buildCardWidget`은 이미 `Flexible` 래핑이 되어 있어 문제 없음 (L476). CardRevealWidget과 SpreadLayout 경유 경로만 문제.

### 수정 계획

**파일**: `mobile/lib/features/reading/presentation/widgets/card_reveal_widget.dart`

**변경 1**: Column의 AspectRatio(카드 이미지)를 `Flexible`로 래핑하여 GridView 셀 높이 내에서 축소 가능하게 한다.

```dart
// Before (L90-101):
AnimatedBuilder(
  animation: _animation,
  builder: ...
);

// After:
Flexible(
  child: AnimatedBuilder(
    animation: _animation,
    builder: ...
  ),
),
```

**근거**: AnimatedDrawPage의 _buildCardWidget(L476)이 동일 패턴으로 `Flexible` + `AspectRatio`를 사용하여 오버플로우 없음. 동일 해법 적용.

**변경 2** (보조): SizedBox(height: 8) -> SizedBox(height: 4)로 줄여 여유 확보. 역방향 텍스트의 padding도 top: 4 -> top: 2로 축소.

**SpreadLayout 변경 불필요**: childAspectRatio 0.65는 적정값. CardRevealWidget 내부에서 Flexible로 해결.

---

## Issue 2: 카드 이미지 미표시

### 원인 분석

`Image.asset(widget.card.card.imagePath)` 호출에서 errorBuilder가 트리거됨.

확인된 사실:
- 파일 존재: `mobile/assets/images/rws-standard/major-00.webp` 등 전체 78장 존재
- pubspec.yaml 등록: `assets/images/rws-standard/` 디렉토리 선언 정상
- imagePath 값: `assets/images/rws-standard/major-00.webp` (JSON -> DB -> TarotCard.imagePath)
- card_back.webp도 동일 경로 패턴이나 _buildBack에서는 LayoutBuilder + cacheWidth 사용

**의심 원인**: `_buildFront`의 LayoutBuilder가 `Transform(rotateY: pi)` 내부에 있어 `constraints.maxWidth`가 0 또는 비정상값일 수 있음. cacheWidth가 0이면 Image.asset 실패.

`_buildBack`은 Transform 없이 직접 LayoutBuilder를 사용하므로 정상 constraints를 받음. 반면 `_buildFront`는 `Transform > LayoutBuilder` 순서라 Transform이 constraints를 pass-through하지만, 플립 중간 상태에서 문제가 될 수 있음.

또한 `cacheWidth: 0`이면 Flutter Image는 에러를 발생시킨다 (`.clamp(1, 1024)` 처리는 되어있으나, constraints.maxWidth가 0이면 `(0 * pixelRatio).toInt() = 0`, clamp(1, 1024) = 1로 정상이어야 함).

**진짜 원인 후보**: Flutter 빌드 캐시가 에셋 번들에 이미지를 포함하지 않은 상태. `flutter clean` + rebuild로 해결 가능. 또는 constraints 문제.

### 수정 계획

**파일**: `mobile/lib/features/reading/presentation/widgets/card_reveal_widget.dart`

**단계 1** — 디버그 확인: `_buildFront`에서 errorBuilder의 error 객체를 `debugPrint`로 출력하여 실제 에러 메시지 확인.

```dart
errorBuilder: (_, error, ___) {
  debugPrint('Card image error: $error for ${widget.card.card.imagePath}');
  return Container(...);
},
```

**단계 2** — cacheWidth 제거 시도: cacheWidth 파라미터를 제거하고 이미지가 로드되는지 확인. cacheWidth 계산이 문제일 경우 이것으로 해결.

```dart
// cacheWidth 제거 (성능 최적화는 이미지 표시 확인 후 재적용)
Image.asset(
  widget.card.card.imagePath,
  fit: BoxFit.cover,
  semanticLabel: widget.card.card.name,
  errorBuilder: ...
),
```

**단계 3** — flutter clean: 에셋 번들 캐시 문제일 경우 `flutter clean && flutter pub get && flutter run`.

**단계 4** — 최종 확인 후 cacheWidth 재적용 여부 결정. 카드 이미지가 정상 표시되면 cacheWidth를 LayoutBuilder 바깥 또는 더 안전한 방식으로 재적용.

---

## Issue 3: '성찰의 시간' 섹션 제거

### 원인 분석

두 페이지 모두 동일 구조의 성찰 섹션이 있음:
- `InstantDrawPage`: L252-296 (SizedBox(24) + '성찰의 시간' Text + 카드별 Container 루프)
- `AnimatedDrawPage`: L352-398 (if (_animationComplete) 블록 내 동일 구조)

`ReflectivePrompts`는 `reading_page.dart:263`에서도 사용 중이므로 클래스/파일 자체는 삭제 불가.

### 수정 계획

**파일 1**: `mobile/lib/features/draw/presentation/pages/instant_draw_page.dart`

- **삭제 범위**: L252-296 (SizedBox(height: 24) 부터 마지막 Container 닫는 괄호+쉼표까지)
  ```
  // 삭제: '성찰 카드' 주석 ~ ReflectivePrompts.getPrompt 루프 끝
  ```
- **import 제거**: L6 `import '../../../reading/domain/entities/reflective_prompts.dart';`
- **안전 고지 유지**: L298-308 그대로 유지 (삭제 범위 아래에 위치)

**파일 2**: `mobile/lib/features/draw/presentation/pages/animated_draw_page.dart`

- **삭제 범위**: L352-398 (`if (_animationComplete) ...[` 블록 전체)
  - 주의: `],` 닫기가 안전 고지 이전에 위치 — 정확한 범위 확인 필요
  - `if (_animationComplete) ...[` 시작부터 해당 블록의 `],` 끝까지 삭제
- **import 제거**: L9 `import '../../../reading/domain/entities/reflective_prompts.dart';`
- **안전 고지 유지**: L400-410 그대로 유지

**검증**: `reading_page.dart`에서 ReflectivePrompts import 유지 확인 (변경 없음).

---

## 실행 순서

| Step | Action | File | 검증 |
|------|--------|------|------|
| 1 | Issue 3: 성찰 섹션 삭제 + import 제거 | instant_draw_page.dart, animated_draw_page.dart | 빌드 성공 |
| 2 | Issue 1: Flexible 래핑 + spacing 축소 | card_reveal_widget.dart | 오버플로우 경고 제거 확인 |
| 3 | Issue 2: 이미지 디버그 → cacheWidth 제거 시도 → flutter clean | card_reveal_widget.dart | 에뮬레이터에서 카드 이미지 표시 확인 |
| 4 | 최종 빌드 + 에뮬레이터 스크린샷 검증 | — | 3개 이슈 모두 해소 |

**순서 근거**: Issue 3(삭제)이 가장 안전하고 확실 → Issue 1(레이아웃)은 명확한 패턴 적용 → Issue 2(이미지)는 디버깅 필요하여 마지막.

---

## 변경 파일 목록

| # | File | Change Type | Issue |
|---|------|-------------|-------|
| 1 | `mobile/lib/features/reading/presentation/widgets/card_reveal_widget.dart` | modify | 1, 2 |
| 2 | `mobile/lib/features/draw/presentation/pages/instant_draw_page.dart` | modify | 3 |
| 3 | `mobile/lib/features/draw/presentation/pages/animated_draw_page.dart` | modify | 3 |

**변경 없음 (검증만)**:
- `mobile/lib/features/reading/presentation/widgets/spread_layout.dart` — childAspectRatio 변경 불필요
- `mobile/lib/features/reading/presentation/pages/reading_page.dart` — ReflectivePrompts 사용 유지 확인
- `mobile/pubspec.yaml` — 에셋 등록 정상 확인 완료

---

## 리스크

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| Issue 2가 cacheWidth가 아닌 다른 원인 | medium | debugPrint로 실제 에러 확인 → flutter clean → 경로 검증 순서로 대응 |
| Flexible 래핑이 1장/3장 레이아웃에서 사이드 이펙트 | low | SpreadLayout의 single/threeCard 모드도 같은 CardRevealWidget 사용하므로 함께 검증 |

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 131s | 302840 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 131s |
| Total Tokens | 302840 |
| Input Tokens | 12 |
| Output Tokens | 7226 |
| Cache Read | 250022 |
| Cache Creation | 45580 |
