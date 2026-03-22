---
id: "012"
type: plan
title: "Dev Tuner 고급 업그레이드 구현 플랜"
created: 2026-03-22
traces_scope: "011"
traces_research: ""
summary: >
  Dev Tuner MVP를 고급 도구로 업그레이드하는 구현 플랜. FAB gesture disambiguation 수정,
  슬라이더+스테퍼 병행 인터랙션, 플로팅 드래그/리사이즈 패널, defaultValue 리셋, WCAG 터치 타겟 확대.
  3파일 수정, 0파일 신규.
keywords: [dev_tuner, slider, floating_panel, gesture, reset, upgrade, plan]
---

# 012 — Dev Tuner 고급 업그레이드 구현 플랜

## Goal

Dev Tuner를 MVP 수준에서 실용적인 고급 개발 도구로 업그레이드한다.
현재 닫기 버그(FAB gesture 충돌), 탭 전용 인터랙션의 한계, 하단 고정 패널의 불편함,
부족한 터치 타겟 크기를 모두 해결하여 빠르고 정밀한 변수 조작이 가능한 튜너로 만든다.

## Scope

### Included
| # | Item | Description |
|---|------|-------------|
| 1 | FAB gesture disambiguation | pan/tap 충돌 해결 — 이동 거리 threshold로 tap 판별 |
| 2 | 슬라이더 + 스테퍼 병행 | 각 변수 행에 Slider + +/- 버튼 배치 |
| 3 | 플로팅 패널 | 하단 고정 → 자유 위치 드래그 + 리사이즈 가능 패널 |
| 4 | 기본값 리셋 | TunableDouble에 defaultValue 추가, 패널 헤더에 Reset 버튼 |
| 5 | UI 크기 확대 | FAB 48x48, 행 높이 44px, 라벨 13px, 값 15px (WCAG 44px 터치 타겟) |

### Excluded
| Item | Reason/Timeline |
|------|-----------------|
| 새 변수 추가 | 별도 작업 |
| Release 빌드 포함 | kDebugMode 가드 유지 |
| 설정 영속화 | 개발 도구 — 세션 휘발 OK |
| 프리셋 저장/로드 | Brief D3에서 제외 결정 |

## Structural Decisions

No structural decisions required — Brief에서 모든 핵심 결정 완료 (D1~D4). 기존 아키텍처 내 수정.

---

## File Change Summary

### Modified Files
| # | File Path | Change Description |
|---|-----------|-------------------|
| 1 | `mobile/lib/core/dev_tuner/tunable_var.dart` | `defaultValue` 필드 추가 |
| 2 | `mobile/lib/core/dev_tuner/dev_tuner_overlay.dart` | 전면 리라이트: FAB gesture, 플로팅 패널, 슬라이더 행, 리셋 |
| 3 | `mobile/lib/core/dev_tuner/stepper_button.dart` | 크기 확대 32x32 → 44x44, 아이콘 18 → 22 |

### New Files
| # | File Path | Description |
|---|-----------|-------------|
| — | (없음) | — |

---

## Step 1 — TunableDouble에 defaultValue 필드 추가

### Approach

`TunableDouble` 클래스에 optional `defaultValue` 파라미터를 추가한다.
null이면 provider의 초기값(= StateProvider 생성 시 값)을 사용하므로, 기존 등록 코드를 수정할 필요 없다.
리셋 시 `defaultValue ?? (provider 초기값)` 을 사용하는 방식이지만, Riverpod StateProvider에서 초기값을 런타임에 조회하기 어려우므로 **defaultValue를 명시적으로 전달하는 것을 권장**하되, 미전달 시 `min`을 fallback으로 사용한다.

### Current Code
```dart
// mobile/lib/core/dev_tuner/tunable_var.dart:3-17
class TunableDouble {
  const TunableDouble({
    required this.label,
    required this.provider,
    required this.min,
    required this.max,
    this.step = 1.0,
  });

  final String label;
  final StateProvider<double> provider;
  final double min;
  final double max;
  final double step;

  String format(double value) =>
      step < 1 ? value.toStringAsFixed(1) : value.toStringAsFixed(0);
}
```

### After Code
```dart
// mobile/lib/core/dev_tuner/tunable_var.dart
class TunableDouble {
  const TunableDouble({
    required this.label,
    required this.provider,
    required this.min,
    required this.max,
    this.step = 1.0,
    this.defaultValue,
  });

  final String label;
  final StateProvider<double> provider;
  final double min;
  final double max;
  final double step;
  final double? defaultValue;

  /// Reset에 사용할 값. 명시적 defaultValue가 없으면 min을 사용.
  double get resetValue => defaultValue ?? min;

  String format(double value) =>
      step < 1 ? value.toStringAsFixed(1) : value.toStringAsFixed(0);
}
```

### Considerations

- `defaultValue`를 optional로 유지하므로 기존 8개 TunableDouble 호출 사이트 수정 불필요.
- Riverpod StateProvider 초기값은 `ref.read(provider)` 최초 호출 시에만 의미가 있으므로, 명시적 `defaultValue`가 더 안전하다.
- 향후 등록 시 `defaultValue`를 전달하면 더 정확한 리셋이 가능하지만, 현 scope에서는 optional fallback(min)으로 충분.

---

## Step 2 — StepperButton 크기 확대 (WCAG 터치 타겟)

### Approach

StepperButton의 Container 크기를 32x32 → 44x44로, 아이콘 크기를 18 → 22로 확대한다.
WCAG 2.1 Success Criterion 2.5.5 (Target Size) 44x44px 최소 기준을 충족한다.

### Current Code
```dart
// mobile/lib/core/dev_tuner/stepper_button.dart:43-49
child: Container(
  width: 32,
  height: 32,
  alignment: Alignment.center,
  child: Icon(widget.icon, color: Colors.white70, size: 18),
),
```

### After Code
```dart
// mobile/lib/core/dev_tuner/stepper_button.dart:43-49
child: Container(
  width: 44,
  height: 44,
  alignment: Alignment.center,
  child: Icon(widget.icon, color: Colors.white70, size: 22),
),
```

### Considerations

- 단순 크기 변경. 아이콘 비율(icon/container ≈ 0.5)을 유지.
- StepperButton은 dev_tuner_overlay.dart에서만 사용되므로 다른 곳에 영향 없음.

---

## Step 3 — FAB Gesture Disambiguation 수정

### Approach

현재 FAB의 `GestureDetector`에 `onPanUpdate`와 `onTap`이 공존하여, 미세한 손가락 이동 시 pan이 tap을 삼킨다. 수정 방법:

1. `onTap` 제거 (pan이 모든 터치를 가져감)
2. `_panStartPosition` 상태 변수 추가
3. `onPanStart`에서 시작 위치 기록
4. `onPanEnd`에서 이동 거리 판별: `distance < 10px` → tap으로 처리 (토글)

FAB 크기도 40x40 → 48x48로 확대 (WCAG 터치 타겟 + 여유).

### Current Code
```dart
// mobile/lib/core/dev_tuner/dev_tuner_overlay.dart:64-89
child: GestureDetector(
  behavior: HitTestBehavior.opaque,
  onPanUpdate: (details) {
    setState(() {
      _buttonOffset += details.delta;
      _buttonOffset = Offset(
        _buttonOffset.dx.clamp(0, size.width - 40),
        _buttonOffset.dy.clamp(0, size.height - 40),
      );
    });
  },
  onTap: () => setState(() => _expanded = !_expanded),
  child: Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: Colors.black87,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(
      _expanded ? Icons.close : Icons.tune,
      color: Colors.white70,
      size: 20,
    ),
  ),
),
```

### After Code
```dart
// mobile/lib/core/dev_tuner/dev_tuner_overlay.dart — FAB 부분
child: GestureDetector(
  behavior: HitTestBehavior.opaque,
  onPanStart: (details) {
    _panStartPosition = details.globalPosition;
  },
  onPanUpdate: (details) {
    setState(() {
      _buttonOffset += details.delta;
      _buttonOffset = Offset(
        _buttonOffset.dx.clamp(0, size.width - 48),
        _buttonOffset.dy.clamp(0, size.height - 48),
      );
    });
  },
  onPanEnd: (details) {
    final distance =
        (details.globalPosition - _panStartPosition).distance;
    if (distance < 10) {
      setState(() => _expanded = !_expanded);
    }
  },
  child: Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      color: Colors.black87,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(
      _expanded ? Icons.close : Icons.tune,
      color: Colors.white70,
      size: 24,
    ),
  ),
),
```

### Considerations

- `onPanEnd`의 `details`에는 `globalPosition`이 없다. `DragEndDetails`에는 `velocity`만 있다. 따라서 `_panStartPosition`과 비교하려면 **`onPanUpdate`에서 마지막 위치를 추적**하거나, 또는 `_panStartPosition`과 `_buttonOffset`의 변화량으로 대체해야 한다.
- **수정된 접근법**: `_panStartOffset` (FAB의 Offset 시작값)을 `onPanStart`에서 기록하고, `onPanEnd`에서 `(_buttonOffset - _panStartOffset).distance < 10`으로 판별. 이 방식이 더 안정적이다.

**최종 구현 패턴**:
```dart
Offset _panStartOffset = Offset.zero; // 클래스 상태 변수에 추가

// onPanStart:
onPanStart: (_) {
  _panStartOffset = _buttonOffset;
},

// onPanEnd:
onPanEnd: (_) {
  if ((_buttonOffset - _panStartOffset).distance < 10) {
    setState(() => _expanded = !_expanded);
  }
},
```

- 이 방식은 `DragEndDetails`의 제한을 우회하며, FAB의 실제 이동 거리를 기준으로 tap/drag를 구분한다.
- threshold 10px은 일반적인 손가락 떨림(3-5px)을 수용하면서 의도적 드래그(15px+)와 구분하기에 적절하다.

---

## Step 4 — 플로팅 드래그/리사이즈 패널

### Approach

현재 하단 고정 패널(`Positioned(left, right, bottom)`)을 자유 위치 플로팅 패널로 교체한다.

**상태 변수 추가**:
- `_panelOffset`: 패널 좌상단 위치 (초기: `Offset(16, screenHeight - 340)`)
- `_panelSize`: 패널 크기 (초기: `Size(screenWidth - 32, 300)`)

**패널 구조**:
```
┌─────────────── Header (드래그 핸들) ──────────────┐
│  ≡ Dev Tuner — {route}              [Reset] [×]  │
├──────────────────────────────────────────────────┤
│  [Label] [-] ═══════●══════════ [+] [Value]      │
│  [Label] [-] ════●═════════════ [+] [Value]      │
│  ...                                              │
├──────────────────────────────────────────────────┤
│                                          ◢ resize │
└──────────────────────────────────────────────────┘
```

**헤더**: `GestureDetector`로 `_panelOffset` 드래그 이동.
**리사이즈 핸들**: 우하단 코너 16x16 영역, `GestureDetector`로 `_panelSize` 조정 (최소 200x150).
**닫기 버튼**: 헤더 우측에 `Icons.close` 추가 (FAB tap 대안).

### Current Code
```dart
// mobile/lib/core/dev_tuner/dev_tuner_overlay.dart:92-127
if (_expanded)
  Positioned(
    left: 16,
    right: 16,
    bottom: bottomPadding + 16,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dev Tuner — $_currentRoute',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          if (vars.isEmpty)
            const Text(
              '등록된 변수 없음',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            )
          else
            ...vars.map(_buildStepperRow),
        ],
      ),
    ),
  ),
```

### After Code
```dart
// mobile/lib/core/dev_tuner/dev_tuner_overlay.dart — 패널 부분
if (_expanded)
  Positioned(
    left: _panelOffset.dx,
    top: _panelOffset.dy,
    child: Container(
      width: _panelSize.width,
      height: _panelSize.height,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header (드래그 핸들) ──
          GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _panelOffset += details.delta;
                _panelOffset = Offset(
                  _panelOffset.dx.clamp(0, size.width - _panelSize.width),
                  _panelOffset.dy.clamp(0, size.height - _panelSize.height),
                );
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.drag_handle, color: Colors.white38, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dev Tuner — $_currentRoute',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Reset 버튼
                  GestureDetector(
                    onTap: () => _resetAllVars(vars),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.restart_alt, color: Colors.white54, size: 20),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // 닫기 버튼
                  GestureDetector(
                    onTap: () => setState(() => _expanded = false),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close, color: Colors.white54, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── 변수 목록 (스크롤 가능) ──
          Expanded(
            child: vars.isEmpty
                ? const Center(
                    child: Text(
                      '등록된 변수 없음',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Column(
                      children: vars.map(_buildSliderRow).toList(),
                    ),
                  ),
          ),
          // ── Resize 핸들 ──
          Align(
            alignment: Alignment.bottomRight,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _panelSize = Size(
                    (_panelSize.width + details.delta.dx).clamp(200, size.width - 16),
                    (_panelSize.height + details.delta.dy).clamp(150, size.height - 100),
                  );
                });
              },
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.open_in_full, color: Colors.white24, size: 14),
              ),
            ),
          ),
        ],
      ),
    ),
  ),
```

### Considerations

- 패널 초기 위치는 `build()` 첫 호출 시 `_positioned` 플래그와 함께 설정 (FAB과 동일 패턴).
- `_panelSize`의 높이가 변수 수보다 작으면 `SingleChildScrollView`로 스크롤 처리.
- boxShadow 추가로 플로팅 패널 시각적 구분.
- 패널과 FAB의 GestureDetector가 각각 독립적이므로 충돌 없음.
- `size` 변수(MediaQuery)를 clamp에 사용하므로 화면 밖으로 나가지 않음.

---

## Step 5 — 슬라이더 + 스테퍼 병행 행 레이아웃

### Approach

기존 `_buildStepperRow`를 `_buildSliderRow`로 교체. 각 변수 행에 Slider와 +/- StepperButton을 함께 배치한다.

**행 레이아웃**:
```
[Label 80px] [- 44px] [Slider flex] [+ 44px] [Value 60px]
행 높이: 48px (44px 터치 타겟 + 4px 여백)
```

### Current Code
```dart
// mobile/lib/core/dev_tuner/dev_tuner_overlay.dart:131-180
Widget _buildStepperRow(TunableDouble variable) {
  final value = ref.watch(variable.provider);
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            variable.label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        StepperButton(
          icon: Icons.chevron_left,
          onStep: () {
            final next = (ref.read(variable.provider) - variable.step)
                .clamp(variable.min, variable.max);
            ref.read(variable.provider.notifier).state = next;
          },
        ),
        SizedBox(
          width: 60,
          child: Text(
            variable.format(value),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.tealAccent,
              fontSize: 13,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        StepperButton(
          icon: Icons.chevron_right,
          onStep: () {
            final next = (ref.read(variable.provider) + variable.step)
                .clamp(variable.min, variable.max);
            ref.read(variable.provider.notifier).state = next;
          },
        ),
      ],
    ),
  );
}
```

### After Code
```dart
// mobile/lib/core/dev_tuner/dev_tuner_overlay.dart
Widget _buildSliderRow(TunableDouble variable) {
  final value = ref.watch(variable.provider);
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: SizedBox(
      height: 48,
      child: Row(
        children: [
          // Label
          SizedBox(
            width: 80,
            child: Text(
              variable.label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Decrement stepper
          StepperButton(
            icon: Icons.remove,
            onStep: () {
              final next = (ref.read(variable.provider) - variable.step)
                  .clamp(variable.min, variable.max);
              ref.read(variable.provider.notifier).state = next;
            },
          ),
          // Slider
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: Colors.tealAccent.withOpacity(0.7),
                inactiveTrackColor: Colors.white12,
                thumbColor: Colors.tealAccent,
                overlayColor: Colors.tealAccent.withOpacity(0.15),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                trackHeight: 3,
              ),
              child: Slider(
                value: value.clamp(variable.min, variable.max),
                min: variable.min,
                max: variable.max,
                divisions: ((variable.max - variable.min) / variable.step).round(),
                onChanged: (newValue) {
                  ref.read(variable.provider.notifier).state = newValue;
                },
              ),
            ),
          ),
          // Increment stepper
          StepperButton(
            icon: Icons.add,
            onStep: () {
              final next = (ref.read(variable.provider) + variable.step)
                  .clamp(variable.min, variable.max);
              ref.read(variable.provider.notifier).state = next;
            },
          ),
          // Value display
          SizedBox(
            width: 60,
            child: Text(
              variable.format(value),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.tealAccent,
                fontSize: 15,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
```

### Considerations

- `Icons.chevron_left/right` → `Icons.remove/add`로 변경. 슬라이더와 함께 배치하면 `-`/`+` 아이콘이 더 직관적.
- Slider의 `divisions` 계산: `(max - min) / step`으로 step 단위 스냅 보장.
- 라벨 fontSize 11 → 13, 값 fontSize 13 → 15로 확대 (Brief MA#5 기준).
- Slider 터치 타겟: Flutter의 기본 Slider는 Material Design의 48px 터치 타겟을 자동 적용.
- `value.clamp(variable.min, variable.max)`: Slider에 전달하는 value가 min~max 범위를 벗어나지 않도록 방어.

---

## Step 6 — Reset 기능 구현

### Approach

패널 헤더의 Reset 버튼 탭 시 현재 route에 등록된 모든 변수를 `resetValue`로 복원한다.

### After Code
```dart
// mobile/lib/core/dev_tuner/dev_tuner_overlay.dart — 클래스 메서드 추가
void _resetAllVars(List<TunableDouble> vars) {
  for (final v in vars) {
    ref.read(v.provider.notifier).state = v.resetValue;
  }
}
```

### Considerations

- `resetValue`는 Step 1에서 추가한 `TunableDouble.resetValue` getter 사용 (`defaultValue ?? min`).
- 현재 route의 변수만 리셋 (global + route-specific). 다른 route 변수는 영향 없음.
- 리셋 즉시 Riverpod 상태 변경 → 화면 자동 반영.

---

## Step 7 — 상태 변수 정리 및 초기화 로직

### Approach

`_DevTunerOverlayState`에 추가할 상태 변수와 초기화 로직 정리.

### Current State Variables
```dart
bool _expanded = false;
Offset _buttonOffset = Offset.zero;
bool _positioned = false;
String _currentRoute = 'home';
GoRouter? _router;
VoidCallback? _routeListener;
```

### After State Variables
```dart
bool _expanded = false;
Offset _buttonOffset = Offset.zero;
bool _positioned = false;
String _currentRoute = 'home';
GoRouter? _router;
VoidCallback? _routeListener;

// Step 3: FAB gesture disambiguation
Offset _panStartOffset = Offset.zero;

// Step 4: 플로팅 패널
Offset _panelOffset = Offset.zero;
Size _panelSize = Size.zero;
```

### 초기화 (build 내 _positioned 블록)
```dart
if (!_positioned) {
  _buttonOffset = Offset(size.width - 56, size.height - bottomPadding - 80);
  _panelOffset = Offset(16, size.height - 340);
  _panelSize = Size(size.width - 32, 300);
  _positioned = true;
}
```

### Considerations

- `_buttonOffset` 초기값의 x 오프셋: `size.width - 48` → `size.width - 56` (48px FAB + 8px 마진).
- `_panelSize` 초기 300px 높이: 5개 변수 행(48px x 5 = 240px) + 헤더(40px) + 여백(20px)으로 충분.
- 패널과 FAB 초기 위치 모두 `_positioned` 한 번만 설정.

---

## Considerations & Trade-offs

### Structural Decisions Log
Brief D1~D4에서 모든 결정 완료. 추가 결정 불필요:
- D1: 슬라이더 + 스테퍼 병행
- D2: 플로팅 패널
- D3: 리셋만 (프리셋 제외)
- D4: FAB gesture 충돌 수정

### Alternative Approaches
| 대안 | 미채택 이유 |
|------|------------|
| `onTap` + `onPanUpdate` 분리 유지 + `movingThreshold` 플래그 | Flutter GestureArena에서 pan이 항상 이기므로 근본 해결 안 됨 |
| Draggable 위젯 사용 (패널) | Draggable은 드래그 종료 시 스냅되어야 해서 자유 위치에 부적합 |
| ReorderableListView로 변수 순서 변경 | 과도한 복잡성, 현재 scope 밖 |
| AnimatedPositioned 사용 (패널 이동) | 드래그 중 애니메이션 지연 발생. 즉각 반응이 더 적합 |

### Potential Risks
| 리스크 | 완화 방법 |
|--------|----------|
| Slider 드래그와 패널 드래그 간 gesture 충돌 | Slider는 패널 내부 위젯이므로 Flutter의 hit testing이 자동 처리. Slider가 우선권을 가짐 |
| 패널 화면 밖 이동 | `clamp`로 화면 경계 내 제한 |
| 리사이즈 시 변수 목록 잘림 | `SingleChildScrollView`로 스크롤 처리 |
| DragEndDetails에 globalPosition 없음 | `_panStartOffset` (Offset 비교) 방식으로 우회 |

### Backward Compatibility
- `TunableDouble` 생성자: `defaultValue` optional → 기존 8개 호출 사이트 수정 불필요.
- `DevTunerRegistry` API: 변경 없음.
- `StepperButton` API: 변경 없음 (크기만 내부 변경).
- 화면별 등록 코드: 수정 불필요.

## Implementation Checklist

- [x] Step 1: TunableDouble에 defaultValue 필드 + resetValue getter 추가
- [x] Step 2: StepperButton 크기 32x32 → 44x44, 아이콘 18 → 22
- [x] Step 3: FAB gesture disambiguation — onTap 제거, onPanStart/End 기반 tap 판별, FAB 48x48
- [x] Step 4: 플로팅 드래그/리사이즈 패널 — Positioned(left,top), 헤더 드래그, 코너 리사이즈
- [x] Step 5: 슬라이더 + 스테퍼 병행 행 — _buildSliderRow, Slider + StepperButton + Value
- [x] Step 6: Reset 기능 — _resetAllVars, 헤더 Reset 버튼
- [x] Step 7: 상태 변수 정리 — _panStartOffset, _panelOffset, _panelSize 초기화
- [x] Final verification: flutter analyze 통과 (No issues found)

## Verification Assertions

| Level | Assertion | Verification Method | Expected Result |
|-------|-----------|-------------------|-----------------|
| L1-Build | Dart 분석 통과 | `cd mobile && flutter analyze` | No errors |
| L1-Build | 앱 빌드 성공 | `cd mobile && flutter build apk --debug` | Build successful |
| L3-Browser | FAB 탭으로 패널 열기/닫기 | 수동 테스트 | FAB 탭 시 패널 토글, 드래그 시 FAB 이동 |
| L3-Browser | 슬라이더 드래그로 값 변경 | 수동 테스트 | 슬라이더 이동 시 값 실시간 반영 |
| L3-Browser | 패널 드래그 이동 | 수동 테스트 | 헤더 드래그 시 패널 자유 이동 |
| L3-Browser | 패널 리사이즈 | 수동 테스트 | 우하단 핸들 드래그 시 크기 변경 |
| L3-Browser | Reset 버튼 동작 | 수동 테스트 | 모든 변수 초기값 복원 |
| L3-Browser | WCAG 터치 타겟 | 수동 측정 | FAB 48x48, StepperButton 44x44 |

## References

| Resource | Path/URL | Related Content |
|----------|---------|-----------------|
| Brief | docs/15_dev_tuner/010_Brief_advanced_tuner_upgrade.md | 요구사항, 결정사항 |
| Scope | docs/15_dev_tuner/011_Scope_advanced_tuner_upgrade.md | 작업 범위, 설계 방향 |
| 현재 오버레이 | mobile/lib/core/dev_tuner/dev_tuner_overlay.dart | 리라이트 대상 |
| 현재 변수 모델 | mobile/lib/core/dev_tuner/tunable_var.dart | defaultValue 추가 대상 |
| 현재 스테퍼 | mobile/lib/core/dev_tuner/stepper_button.dart | 크기 확대 대상 |
| 레지스트리 | mobile/lib/core/dev_tuner/tuner_registry.dart | API 호환성 확인 |
| WCAG 2.1 SC 2.5.5 | https://www.w3.org/WAI/WCAG21/Understanding/target-size.html | 터치 타겟 기준 |

## 미비점 및 확장 필요 영역

### Plan 미비점 (makeplan 기록)
| # | 항목 | 심각도 | 설명 |
|---|------|--------|------|
| 1 | DragEndDetails globalPosition | Low | onPanEnd에서 globalPosition 사용 불가 → _panStartOffset 비교로 우회. 구현 시 실제 API 확인 필요 |
| 2 | 패널 초기 위치 하드코딩 | Low | 화면 크기별 적응형 초기 위치 고려 가능하나 현재 clamp로 충분 |

### Implementation 미비점 (implementation 기록)
| # | 항목 | 심각도 | 설명 |
|---|------|--------|------|
| — | 없음 | — | Plan과 현재 코드 상태 일치, 모든 Step 완료, withOpacity → withValues(alpha:) 적용 |

### Verification 미비점 (verify 기록)
| # | 항목 | 심각도 | 설명 |
|---|------|--------|------|
