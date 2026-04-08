---
id: "005"
title: "기존 화면별 하드코딩 변수 탐색"
category: agent
status: archived
created: 2026-03-18
confidence: high
summary: >
  5개 화면 + Flame 엔진 3개 + 위젯 3개 + 테마 + main.dart 총 11개 파일을 탐색하여
  하드코딩 숫자값 67개를 식별함. 이 중 튜닝 가능 변수 49개, 튜닝 불가 18개로 분류.
  가장 많은 튜닝 포인트는 카드 물리 엔진(card_body_component)과 카드 공개 애니메이션(card_reveal_widget).
keywords: [agent-report, flutter-expert, screen-variables, hardcoded-values, tunable-parameters]
modules: [mobile/lib/features, mobile/lib/core/theme]
---

# 기존 화면별 하드코딩 변수 탐색

## 분석 대상 파일

| 번호 | 파일 | 경로 |
|------|------|------|
| 1 | home_page.dart | mobile/lib/features/home/presentation/pages/ |
| 2 | shuffle_page.dart | mobile/lib/features/shuffle/presentation/pages/ |
| 3 | tarot_game.dart | mobile/lib/features/shuffle/presentation/game/ |
| 4 | card_body_component.dart | mobile/lib/features/shuffle/presentation/game/ |
| 5 | hand_animation_component.dart | mobile/lib/features/shuffle/presentation/game/ |
| 6 | reading_page.dart | mobile/lib/features/reading/presentation/pages/ |
| 7 | intention_page.dart | mobile/lib/features/shuffle/presentation/pages/ |
| 8 | deck_selection_page.dart | mobile/lib/features/deck/presentation/pages/ |
| 9 | spread_layout.dart | mobile/lib/features/reading/presentation/widgets/ |
| 10 | card_reveal_widget.dart | mobile/lib/features/reading/presentation/widgets/ |
| 11 | entropy_progress_indicator.dart | mobile/lib/features/shuffle/presentation/widgets/ |
| 12 | app_theme.dart | mobile/lib/core/theme/ |
| 13 | main.dart | mobile/lib/ |

---

## 1. Home Page (`home_page.dart`)

### 하드코딩 값 목록

| 줄 | 원본 코드 | 값 | 카테고리 |
|----|-----------|-----|----------|
| 42 | `center: Alignment(0, -0.3)` | -0.3 | 그라디언트 중심 Y |
| 43 | `radius: 1.2` | 1.2 | 그라디언트 반지름 |
| 44 | `Color(0xFF2A1B3D)` | 0xFF2A1B3D | 배경 그라디언트 내부 색 |
| 44 | `Color(0xFF0D0A14)` | 0xFF0D0A14 | 배경 그라디언트 외부 색 |
| 49 | `EdgeInsets.all(16)` | 16 | 전체 패딩 |
| 53 | `SizedBox(height: 16)` | 16 | 상단 여백 |
| 55 | `size: 40` | 40 | 아이콘 크기 |
| 56 | `SizedBox(height: 8)` | 8 | 아이콘-제목 여백 |
| 62 | `SizedBox(height: 24)` | 24 | 제목-버튼 여백 |
| 63 | `SizedBox(height: 56)` (버튼1) | 56 | 바로뽑기 버튼 높이 |
| 67 | `size: 20` | 20 | 버튼 아이콘 크기 |
| 69 | `fontSize: 18` | 18 | 버튼 텍스트 폰트 크기 |
| 72 | `SizedBox(height: 12)` | 12 | 버튼 사이 여백 |
| 73 | `SizedBox(height: 56)` (버튼2) | 56 | 셔플시작 버튼 높이 |
| 81 | `fontSize: 18` | 18 | 버튼2 폰트 크기 |
| 84 | `SizedBox(height: 32)` | 32 | 버튼-최근리딩 여백 |
| 86 | `SizedBox(height: 8)` | 8 | 최근리딩 타이틀-목록 여백 |

### 튜닝 가능 변수 (Home Page)

| 변수명 (제안) | 타입 | 현재값 | min | max | step | 설명 |
|--------------|------|--------|-----|-----|------|------|
| `homeBgGradientCenterY` | double | -0.3 | -1.0 | 1.0 | 0.05 | RadialGradient 중심 Y 위치 |
| `homeBgGradientRadius` | double | 1.2 | 0.5 | 3.0 | 0.1 | RadialGradient 반지름 |
| `homeBgInnerColor` | Color | 0xFF2A1B3D | - | - | - | 배경 그라디언트 내부 색 |
| `homeBgOuterColor` | Color | 0xFF0D0A14 | - | - | - | 배경 그라디언트 외부 색 |
| `homePagePadding` | double | 16 | 8 | 32 | 4 | Scaffold 전체 패딩 |
| `homeTopSpacing` | double | 16 | 0 | 48 | 4 | 상단 SafeArea 여백 |
| `homeTitleIconSize` | double | 40 | 24 | 64 | 4 | 타이틀 아이콘 크기 |
| `homeIconTitleSpacing` | double | 8 | 0 | 24 | 4 | 아이콘-제목 간격 |
| `homeTitleButtonSpacing` | double | 24 | 8 | 48 | 4 | 제목-버튼 간격 |
| `homePrimaryButtonHeight` | double | 56 | 40 | 72 | 4 | 주요 버튼 높이 |
| `homePrimaryButtonIconSize` | double | 20 | 14 | 28 | 2 | 버튼 아이콘 크기 |
| `homePrimaryButtonFontSize` | double | 18 | 14 | 24 | 1 | 버튼 폰트 크기 |
| `homeButtonGap` | double | 12 | 4 | 24 | 4 | 두 버튼 사이 간격 |
| `homeButtonSectionSpacing` | double | 32 | 16 | 64 | 4 | 버튼-리스트 섹션 간격 |
| `homeListHeaderSpacing` | double | 8 | 4 | 16 | 2 | 리스트 헤더-아이템 간격 |

### 튜닝 불가 (Home Page)

없음 — Home Page는 UI/레이아웃 값만 포함.

---

## 2. Shuffle Page (`shuffle_page.dart`)

### 하드코딩 값 목록

| 줄 | 원본 코드 | 값 | 카테고리 |
|----|-----------|-----|----------|
| 21 | `_rotateX = 0.65` | 0.65 | 카메라 초기 상하 기울기 (라디안) |
| 23 | `_zoom = 0.001` | 0.001 | 원근 강도 (perspective entry) |
| 34 | `_rotateX = 0.65` (reset) | 0.65 | 더블탭 리셋 기울기 |
| 36 | `_zoom = 0.001` (reset) | 0.001 | 더블탭 리셋 줌 |
| 63 | `* 0.005` (rotateX delta) | 0.005 | 드래그 → 기울기 감도 |
| 65 | `* 0.005` (rotateY delta) | 0.005 | 드래그 → 회전 감도 |
| 68 | `.clamp(0.0003, 0.003)` | 0.0003 / 0.003 | 줌 최소/최대 clamp |
| 95 | `left: 12` | 12 | 좌표정보 패널 왼쪽 위치 |
| 96 | `bottom: 80` | 80 | 좌표정보 패널 하단 위치 |
| 98 | `horizontal: 10, vertical: 8` | 10, 8 | 패널 내부 패딩 |
| 100 | `BorderRadius.circular(8)` | 8 | 패널 모서리 반지름 |
| 104 | `fontSize: 11` | 11 | 좌표 표시 폰트 크기 |
| 126 | `bottom: 24` | 24 | 하단 버튼 영역 bottom |
| 135 | `SizedBox(width: 16)` | 16 | 버튼 사이 가로 간격 |
| 132 | `size: 18` (아이콘) | 18 | 버튼 아이콘 크기 |
| 138 | `size: 18` (아이콘) | 18 | 버튼 아이콘 크기 |

### 튜닝 가능 변수 (Shuffle Page)

| 변수명 (제안) | 타입 | 현재값 | min | max | step | 설명 |
|--------------|------|--------|-----|-----|------|------|
| `cameraInitialRotateX` | double | 0.65 | 0.0 | 1.57 | 0.05 | 카메라 초기 상하 기울기 (라디안). 0=정면, π/2=완전 수평 |
| `cameraPerspectiveZoom` | double | 0.001 | 0.0003 | 0.003 | 0.0001 | Matrix4 perspective entry (3,2). 값이 클수록 원근감 강함 |
| `cameraDragSensitivity` | double | 0.005 | 0.001 | 0.02 | 0.001 | 1핑거 드래그 → 회전 변환 배율 |
| `cameraZoomMin` | double | 0.0003 | 0.0001 | 0.001 | 0.0001 | 핀치줌 최소값 (가장 멀리) |
| `cameraZoomMax` | double | 0.003 | 0.001 | 0.01 | 0.0005 | 핀치줌 최대값 (가장 가까이) |
| `debugPanelBottomOffset` | double | 80 | 60 | 120 | 4 | 좌표 표시 패널 하단 여백 |
| `shuffleButtonBottomOffset` | double | 24 | 8 | 48 | 4 | 하단 버튼 bottom 여백 |
| `shuffleButtonGap` | double | 16 | 8 | 32 | 4 | 재시작/뽑기 버튼 사이 간격 |

### 튜닝 불가 (Shuffle Page)

| 값 | 이유 |
|----|------|
| `Colors.black54`, `Colors.white70` | 디버그 오버레이 색상. 테마와 무관한 개발용 UI |
| `fontSize: 11` (monospace) | 디버그 폰트. 튜닝 대상 아님 |

---

## 3. Flame 게임 엔진 (`tarot_game.dart`)

### 하드코딩 값 목록

| 줄 | 원본 코드 | 값 | 카테고리 |
|----|-----------|-----|----------|
| 16 | `gravity: Vector2(0, 0)` | 0, 0 | 물리 세계 중력 벡터 |
| 21 | `Color(0xFF0D0818)` | 0xFF0D0818 | 게임 배경 색 |
| 30 | `const cardCount = 22` | 22 | 스폰 카드 수 |
| 35 | `speed = 2.0 + rng.nextDouble() * 4.0` | 2.0 / 4.0 | 초기 속도 최소/범위 |
| 38-40 | `(rng.nextDouble() - 0.5) * 0.3` | 0.3 | 초기 위치 산포 반경 |
| 46 | `(rng.nextDouble() - 0.5) * 8.0` | 8.0 | 초기 각속도 최대 |
| 55 | `kFixedDt = 1.0 / 45.0` | 45.0 | 물리 고정 타임스텝 (FPS 단위) |

### 튜닝 가능 변수 (tarot_game.dart)

| 변수명 (제안) | 타입 | 현재값 | min | max | step | 설명 |
|--------------|------|--------|-----|-----|------|------|
| `gameBackgroundColor` | Color | 0xFF0D0818 | - | - | - | Flame 게임 배경 색 |
| `cardSpawnSpeedMin` | double | 2.0 | 0.5 | 5.0 | 0.5 | 카드 방사 최소 속도 (m/s) |
| `cardSpawnSpeedRange` | double | 4.0 | 0.5 | 8.0 | 0.5 | 카드 방사 속도 무작위 범위 (m/s) |
| `cardSpawnPositionRadius` | double | 0.3 | 0.0 | 1.0 | 0.05 | 초기 위치 산포 반경 (m). 0=중앙 집결 |
| `cardSpawnAngularVelocityMax` | double | 8.0 | 1.0 | 20.0 | 1.0 | 초기 각속도 최대값 (rad/s) |
| `physicsFixedHz` | double | 45.0 | 30.0 | 120.0 | 5.0 | 물리 시뮬레이션 고정 주파수 (Hz) |
| `worldGravityX` | double | 0.0 | -10.0 | 10.0 | 0.5 | 물리 세계 X 중력 (센서 연동 전 기본값) |
| `worldGravityY` | double | 0.0 | -10.0 | 10.0 | 0.5 | 물리 세계 Y 중력 |

### 튜닝 불가 (tarot_game.dart)

| 값 | 이유 |
|----|------|
| `cardCount = 22` | 메이저 아르카나 카드 수. 비즈니스 로직 상수 |
| `Random.secure()` | 보안 PRNG. 변경 금지 |

---

## 4. Card Body Component (`card_body_component.dart`)

### 하드코딩 값 목록

| 줄 | 원본 코드 | 값 | 카테고리 |
|----|-----------|-----|----------|
| 17 | `halfWidth = 0.3` | 0.3 | 카드 반너비 (m) |
| 18 | `halfHeight = 0.45` | 0.45 | 카드 반높이 (m) |
| 21 | `Color(0xFF3D2B5E)` | 0xFF3D2B5E | 카드 앞면 상단 색 |
| 22 | `Color(0xFF110820)` | 0xFF110820 | 카드 앞면 하단 색 |
| 23 | `Color(0xFFD4A84B)` | 0xFFD4A84B | 테두리(골드) 색 |
| 24 | `Color(0x996B5B95)` | 0x996B5B95 | 다이아몬드 패턴 색 |
| 25 | `Color(0xFF7A5AAE)` | 0xFF7A5AAE | 엣지 상단 색 |
| 26 | `Color(0xFF1A0830)` | 0xFF1A0830 | 엣지 하단 색 |
| 45 | `linearDamping: 3.5` | 3.5 | 선형 감쇠 |
| 46 | `angularDamping: 2.0` | 2.0 | 회전 감쇠 |
| 51 | `density: 1.0` | 1.0 | 밀도 |
| 51 | `friction: 0.5` | 0.5 | 마찰계수 |
| 51 | `restitution: 0.02` | 0.02 | 반발계수 (탄성) |
| 61 | `Radius.circular(0.04)` | 0.04 | 카드 모서리 반지름 (m) |
| 66 | `sOff = 0.04 + (speed * 0.012)` | 0.04 / 0.012 | 그림자 기본 오프셋 / 속도 배율 |
| 67 | `sBlur = 0.04 + (speed * 0.010)` | 0.04 / 0.010 | 그림자 기본 블러 / 속도 배율 |
| 67 | `.clamp(0.0, 0.10)` | 0.10 | 그림자 오프셋 최대값 |
| 67 | `.clamp(0.0, 0.08)` | 0.08 | 그림자 블러 최대값 |
| 71 | `Color.fromARGB((70 + (speed * 10)).clamp(0, 80)...)` | 70 / 10 / 80 | 그림자 알파 기본값/배율/최대 |
| 69 | `cardRect.translate(sOff, sOff * 1.3)` | 1.3 | 그림자 Y 오프셋 배율 |
| 92 | `strokeWidth = 0.013` | 0.013 | 골드 테두리 두께 |
| 98-100 | `h * 0.62`, `w * 0.55` | 0.62 / 0.55 | 다이아몬드 패턴 비율 |
| 106 | `strokeWidth = 0.010` | 0.010 | 다이아몬드 선 두께 |
| 112 | `-w + 0.02, -h + 0.02, w * 2 - 0.04, h * 0.28` | 0.02 / 0.28 | 하이라이트 패딩/높이 비율 |
| 115 | `Color(0x18FFFFFF)` | 0x18 (alpha=24) | 상단 하이라이트 색 |
| 119 | `h * 1.0`, `w * 2`, `0.08` | 0.08 | 두께 엣지 높이 |
| 121 | `Radius.circular(0.02)` | 0.02 | 엣지 모서리 반지름 |
| 134 | `strokeWidth = 0.008` | 0.008 | 엣지 골드 테두리 두께 |
| 132 | `Color(0x88D4A84B)` | 0x88 (alpha=136) | 엣지 골드 색 |

### 튜닝 가능 변수 (card_body_component.dart)

| 변수명 (제안) | 타입 | 현재값 | min | max | step | 설명 |
|--------------|------|--------|-----|-----|------|------|
| `cardHalfWidth` | double | 0.3 | 0.15 | 0.5 | 0.01 | 카드 반너비 (m). 종횡비에 영향 |
| `cardHalfHeight` | double | 0.45 | 0.25 | 0.7 | 0.01 | 카드 반높이 (m) |
| `cardCornerRadius` | double | 0.04 | 0.0 | 0.1 | 0.005 | 카드 모서리 둥글기 (m) |
| `cardLinearDamping` | double | 3.5 | 0.0 | 10.0 | 0.5 | 선형 감쇠. 클수록 빨리 멈춤 |
| `cardAngularDamping` | double | 2.0 | 0.0 | 8.0 | 0.5 | 회전 감쇠. 클수록 회전이 빨리 멈춤 |
| `cardDensity` | double | 1.0 | 0.1 | 5.0 | 0.1 | 카드 밀도 (kg/m²) |
| `cardFriction` | double | 0.5 | 0.0 | 1.0 | 0.05 | 카드 간 마찰계수 |
| `cardRestitution` | double | 0.02 | 0.0 | 0.5 | 0.01 | 충돌 반발계수. 0=완전 비탄성 |
| `cardFaceTopColor` | Color | 0xFF3D2B5E | - | - | - | 카드 앞면 그라디언트 상단 색 |
| `cardFaceBotColor` | Color | 0xFF110820 | - | - | - | 카드 앞면 그라디언트 하단 색 |
| `cardBorderColor` | Color | 0xFFD4A84B | - | - | - | 골드 테두리 색 |
| `cardBorderWidth` | double | 0.013 | 0.005 | 0.03 | 0.001 | 골드 테두리 두께 (m) |
| `cardPatternColor` | Color | 0x996B5B95 | - | - | - | 다이아몬드 패턴 색 |
| `cardPatternLineWidth` | double | 0.010 | 0.003 | 0.02 | 0.001 | 다이아몬드 선 두께 (m) |
| `cardPatternDiamondH` | double | 0.62 | 0.3 | 0.9 | 0.05 | 다이아몬드 수직 비율 (halfHeight 배수) |
| `cardPatternDiamondW` | double | 0.55 | 0.3 | 0.9 | 0.05 | 다이아몬드 수평 비율 (halfWidth 배수) |
| `cardHighlightAlpha` | double | 0.094 (0x18/255) | 0.0 | 0.3 | 0.01 | 상단 하이라이트 불투명도 |
| `cardHighlightHeightRatio` | double | 0.28 | 0.1 | 0.5 | 0.02 | 하이라이트 높이 비율 |
| `cardEdgeHeight` | double | 0.08 | 0.02 | 0.15 | 0.005 | 두께 엣지 높이 (m) |
| `cardEdgeTopColor` | Color | 0xFF7A5AAE | - | - | - | 두께 엣지 상단 색 |
| `cardEdgeBotColor` | Color | 0xFF1A0830 | - | - | - | 두께 엣지 하단 색 |
| `shadowBaseOffset` | double | 0.04 | 0.0 | 0.1 | 0.005 | 그림자 기본 오프셋 (속도 0일 때) |
| `shadowSpeedOffsetScale` | double | 0.012 | 0.0 | 0.05 | 0.001 | 속도에 따른 그림자 오프셋 증가 배율 |
| `shadowBaseBlur` | double | 0.04 | 0.0 | 0.1 | 0.005 | 그림자 기본 블러 |
| `shadowSpeedBlurScale` | double | 0.010 | 0.0 | 0.05 | 0.001 | 속도에 따른 블러 증가 배율 |
| `shadowYOffsetMultiplier` | double | 1.3 | 0.5 | 2.0 | 0.1 | 그림자 Y축 오프셋 배율 (그림자 기울기) |
| `shadowBaseAlpha` | int | 70 | 0 | 120 | 5 | 그림자 기본 알파 (0-255) |
| `shadowSpeedAlphaScale` | double | 10.0 | 0.0 | 30.0 | 1.0 | 속도에 따른 알파 증가 배율 |

### 튜닝 불가 (card_body_component.dart)

| 값 | 이유 |
|----|------|
| `allowSleep: true` | 물리 최적화 설정. 게임 성능에 영향 |
| `renderBody: false` | 디버그 body 렌더 비활성. 개발 설정 |

---

## 5. Hand Animation Component (`hand_animation_component.dart`)

### 하드코딩 값 목록

| 줄 | 원본 코드 | 값 | 카테고리 |
|----|-----------|-----|----------|
| 22 | `Vector2(0.0, -1.5)` | -1.5 | 손 초기 Y 위치 (m) |
| 34 | `CircleShape()..radius = 0.3` | 0.3 | 손 충돌 반지름 (m) |
| 66 | `position.setValues(-2.0, -2.0)` | -2.0 | Rive 컴포넌트 offset (m) |
| 67 | `size.setValues(4.0, 4.0)` | 4.0 | Rive 컴포넌트 크기 (m) |

### 튜닝 가능 변수 (hand_animation_component.dart)

| 변수명 (제안) | 타입 | 현재값 | min | max | step | 설명 |
|--------------|------|--------|-----|-----|------|------|
| `handInitialPositionY` | double | -1.5 | -3.0 | 0.0 | 0.1 | 손 초기 Y 위치. 음수=화면 위 |
| `handColliderRadius` | double | 0.3 | 0.1 | 0.8 | 0.05 | 손 충돌 감지 반지름 (m) |
| `handRiveSize` | double | 4.0 | 2.0 | 8.0 | 0.5 | Rive 애니메이션 렌더 크기 (m × m) |

### 튜닝 불가 (hand_animation_component.dart)

| 값 | 이유 |
|----|------|
| `BodyType.kinematic` | 물리 타입. 손 동작 로직에 필수 |
| `density: 0.0` | KinematicBody는 질량 없음. 로직 요구사항 |
| `StateMachine` (Rive SM 이름) | Rive 파일 내 State Machine 이름. 에셋 ID |

---

## 6. Reading Page (`reading_page.dart`)

### 하드코딩 값 목록

| 줄 | 원본 코드 | 값 | 카테고리 |
|----|-----------|-----|----------|
| 57 | `EdgeInsets.all(16)` | 16 | 스크롤뷰 전체 패딩 |
| 64 | `EdgeInsets.all(12)` | 12 | 질문 박스 패딩 |
| 66 | `BorderRadius.circular(8)` | 8 | 질문 박스 모서리 |
| 77 | `SizedBox(height: 16)` | 16 | 질문-스프레드 여백 |
| 82 | `size.height * 0.45` | 0.45 | 스프레드 레이아웃 높이 비율 |
| 95 | `SizedBox(height: 24)` | 24 | 스프레드-성찰 여백 |
| 103 | `SizedBox(height: 12)` | 12 | 성찰 제목-내용 여백 |
| 107 | `EdgeInsets.all(12)` | 12 | 성찰 카드 박스 패딩 |
| 108 | `EdgeInsets.only(bottom: 12)` | 12 | 성찰 카드 박스 하단 마진 |
| 110 | `BorderRadius.circular(8)` | 8 | 성찰 카드 박스 모서리 |
| 125 | `fontSize: 12` | 12 | guidance 텍스트 크기 |
| 143 | `SizedBox(height: 16)` | 16 | 성찰-안전고지 여백 |
| 148 | `alpha: 0.7` | 0.7 | 안전고지 텍스트 불투명도 |
| 149 | `fontSize: 11` | 11 | 안전고지 텍스트 크기 |

### 튜닝 가능 변수 (reading_page.dart)

| 변수명 (제안) | 타입 | 현재값 | min | max | step | 설명 |
|--------------|------|--------|-----|-----|------|------|
| `readingPagePadding` | double | 16 | 8 | 32 | 4 | 전체 스크롤뷰 패딩 |
| `readingQuestionBoxPadding` | double | 12 | 8 | 24 | 2 | 질문 박스 내부 패딩 |
| `readingQuestionBoxRadius` | double | 8 | 4 | 16 | 2 | 질문 박스 모서리 반지름 |
| `readingSpreadHeightRatio` | double | 0.45 | 0.3 | 0.65 | 0.05 | 스프레드 레이아웃 높이 (화면 비율) |
| `readingReflectionSpacing` | double | 24 | 12 | 48 | 4 | 스프레드-성찰 섹션 간격 |
| `readingCardBoxPadding` | double | 12 | 8 | 20 | 2 | 성찰 카드 박스 패딩 |
| `readingCardBoxRadius` | double | 8 | 4 | 16 | 2 | 성찰 카드 박스 모서리 |
| `readingGuidanceFontSize` | double | 12 | 10 | 16 | 1 | 성찰 guidance 폰트 크기 |
| `readingDisclaimerOpacity` | double | 0.7 | 0.3 | 1.0 | 0.05 | 안전고지 텍스트 불투명도 |
| `readingDisclaimerFontSize` | double | 11 | 9 | 14 | 1 | 안전고지 폰트 크기 |

### 튜닝 불가 (reading_page.dart)

| 값 | 이유 |
|----|------|
| `_spreadType.cardCount` | 비즈니스 로직 (스프레드 타입별 카드 수) |
| `take(_spreadType.cardCount)` | 카드 추출 개수. 도메인 로직 |

---

## 7. Intention Page (`intention_page.dart`)

### 하드코딩 값 목록

| 줄 | 원본 코드 | 값 | 카테고리 |
|----|-----------|-----|----------|
| 42 | `EdgeInsets.all(24)` | 24 | 전체 패딩 |
| 45 | `SizedBox(height: 24)` | 24 | 상단 여백 |
| 46 | `size: 48` | 48 | 아이콘 크기 |
| 48 | `SizedBox(height: 16)` | 16 | 아이콘-텍스트 여백 |
| 54 | `SizedBox(height: 32)` | 32 | 텍스트-입력필드 여백 |
| 61 | `BorderRadius.circular(12)` | 12 | 입력 필드 모서리 (기본) |
| 64 | `BorderRadius.circular(12)` | 12 | 입력 필드 모서리 (enabled) |
| 70 | `BorderRadius.circular(12)` | 12 | 입력 필드 모서리 (focused) |
| 75 | `maxLines: 3` | 3 | 텍스트 입력 최대 줄 수 |
| 76 | `SizedBox(height: 8)` | 8 | 입력-힌트 여백 |
| 82 | `SizedBox(height: 32)` | 32 | 힌트-버튼 여백 |
| 83 | `SizedBox(height: 56)` | 56 | 버튼 높이 |
| 96 | `fontSize: 18` | 18 | 버튼 폰트 크기 |

### 튜닝 가능 변수 (intention_page.dart)

| 변수명 (제안) | 타입 | 현재값 | min | max | step | 설명 |
|--------------|------|--------|-----|-----|------|------|
| `intentionPagePadding` | double | 24 | 12 | 40 | 4 | 전체 패딩 |
| `intentionIconSize` | double | 48 | 32 | 72 | 4 | 상단 아이콘 크기 |
| `intentionIconTextSpacing` | double | 16 | 8 | 32 | 4 | 아이콘-텍스트 간격 |
| `intentionTextFieldSpacing` | double | 32 | 16 | 56 | 4 | 텍스트-입력필드 간격 |
| `intentionFieldBorderRadius` | double | 12 | 4 | 24 | 2 | 입력 필드 모서리 반지름 |
| `intentionButtonHeight` | double | 56 | 40 | 72 | 4 | CTA 버튼 높이 |
| `intentionButtonFontSize` | double | 18 | 14 | 24 | 1 | 버튼 폰트 크기 |

### 튜닝 불가 (intention_page.dart)

| 값 | 이유 |
|----|------|
| `maxLines: 3` | 질문 입력 UX 제약. 콘텐츠 로직 |

---

## 8. Deck Selection Page (`deck_selection_page.dart`)

### 하드코딩 값 목록

| 줄 | 원본 코드 | 값 | 카테고리 |
|----|-----------|-----|----------|
| 21 | `EdgeInsets.all(16)` | 16 | 리스트 패딩 |

### 튜닝 가능 변수 (deck_selection_page.dart)

| 변수명 (제안) | 타입 | 현재값 | min | max | step | 설명 |
|--------------|------|--------|-----|-----|------|------|
| `deckListPadding` | double | 16 | 8 | 32 | 4 | 덱 목록 좌우/상하 패딩 |

---

## 9. Spread Layout (`spread_layout.dart`)

### 하드코딩 값 목록

| 줄 | 원본 코드 | 값 | 카테고리 |
|----|-----------|-----|----------|
| 47 | `EdgeInsets.symmetric(horizontal: 8)` | 8 | 3카드 레이아웃 카드 사이 수평 패딩 |
| 44 | `List.generate(3, ...)` | 3 | 3카드 스프레드 카드 수 |

### 튜닝 가능 변수 (spread_layout.dart)

| 변수명 (제안) | 타입 | 현재값 | min | max | step | 설명 |
|--------------|------|--------|-----|-----|------|------|
| `threeCardHorizontalPadding` | double | 8 | 0 | 20 | 2 | 3카드 레이아웃 카드 사이 수평 패딩 |

### 튜닝 불가 (spread_layout.dart)

| 값 | 이유 |
|----|------|
| `List.generate(3, ...)` | SpreadType.threeCard 카드 수. 도메인 상수 |

---

## 10. Card Reveal Widget (`card_reveal_widget.dart`)

### 하드코딩 값 목록

| 줄 | 원본 코드 | 값 | 카테고리 |
|----|-----------|-----|----------|
| 39 | `Duration(milliseconds: 400)` | 400 | 카드 뒤집기 애니메이션 시간 |
| 41 | `Curves.easeInOut` | easeInOut | 애니메이션 곡선 |
| 43 | `_animation.value >= 0.5` | 0.5 | 앞면 전환 기준점 |
| 91 | `setEntry(3, 2, 0.002)` | 0.002 | 카드 뒤집기 원근감 강도 |
| 83 | `SizedBox(height: 8)` | 8 | 라벨-카드 간격 |
| 117-118 | `aspectRatio: 2.5 / 3.5` | 2.5 / 3.5 | 카드 종횡비 (뒷면) |
| 122 | `BorderRadius.circular(8)` | 8 | 카드 모서리 (뒷면) |
| 123 | `border width: 1.5` | 1.5 | 카드 테두리 두께 (뒷면) |
| 126 | `Color(0xFF2D1B4E)` | 0xFF2D1B4E | 카드 뒷면 배경색 |
| 128 | `size: 32` | 32 | 카드 뒷면 아이콘 크기 |
| 139 | `aspectRatio: 2.5 / 3.5` | 2.5 / 3.5 | 카드 종횡비 (앞면) |
| 141 | `BorderRadius.circular(8)` | 8 | 카드 모서리 (앞면) |
| 142 | `border width: 1.5` | 1.5 | 카드 테두리 두께 (앞면) |
| 144 | `Color(0xFF1A1028)` | 0xFF1A1028 | 카드 앞면 배경색 |
| 146 | `EdgeInsets.all(8)` | 8 | 카드 내부 패딩 (앞면) |
| 100 | `EdgeInsets.only(top: 4)` | 4 | 역방향 라벨 상단 마진 |
| 103 | `fontSize: 12` | 12 | 역방향 라벨 폰트 크기 |
| 160 | `.take(2)` | 2 | 표시할 meaning 수 |

### 튜닝 가능 변수 (card_reveal_widget.dart)

| 변수명 (제안) | 타입 | 현재값 | min | max | step | 설명 |
|--------------|------|--------|-----|-----|------|------|
| `cardFlipDurationMs` | int | 400 | 100 | 1200 | 50 | 카드 뒤집기 애니메이션 시간 (ms) |
| `cardFlipPerspective` | double | 0.002 | 0.0005 | 0.01 | 0.0005 | 뒤집기 애니메이션 원근감. 클수록 원근 왜곡 강함 |
| `cardFlipFrontThreshold` | double | 0.5 | 0.3 | 0.7 | 0.05 | 앞면 전환 타이밍 (0=즉시, 1=끝에서) |
| `cardLabelCardSpacing` | double | 8 | 0 | 20 | 2 | 라벨-카드 사이 간격 |
| `cardAspectRatioW` | double | 2.5 | 1.5 | 3.0 | 0.1 | 카드 너비 비율 (종횡비 분자) |
| `cardAspectRatioH` | double | 3.5 | 2.5 | 5.0 | 0.1 | 카드 높이 비율 (종횡비 분모) |
| `cardBorderRadius` | double | 8 | 0 | 20 | 2 | 카드 모서리 반지름 |
| `cardBorderWidth` | double | 1.5 | 0.5 | 4.0 | 0.5 | 카드 테두리 두께 |
| `cardBackColor` | Color | 0xFF2D1B4E | - | - | - | 카드 뒷면 배경색 |
| `cardFrontColor` | Color | 0xFF1A1028 | - | - | - | 카드 앞면 배경색 |
| `cardBackIconSize` | double | 32 | 20 | 56 | 4 | 카드 뒷면 아이콘 크기 |
| `cardFrontPadding` | double | 8 | 4 | 20 | 2 | 카드 앞면 내부 패딩 |
| `reversedLabelFontSize` | double | 12 | 10 | 16 | 1 | 역방향 표시 라벨 폰트 크기 |

### 튜닝 불가 (card_reveal_widget.dart)

| 값 | 이유 |
|----|------|
| `.take(2)` | 표시 meaning 수. 콘텐츠 UX 제약 |
| `Curves.easeInOut` | 현재는 하드코딩. enum 선택 가능하게 tunable로 승격 고려 가능 |

---

## 11. Entropy Progress Indicator (`entropy_progress_indicator.dart`)

### 하드코딩 값 목록

| 줄 | 원본 코드 | 값 | 카테고리 |
|----|-----------|-----|----------|
| 34 | `BoxConstraints(maxWidth: 280)` | 280 | 진행 바 최대 너비 |
| 43 | `SizedBox(height: 4)` | 4 | 진행 바-텍스트 간격 |
| 22 | `size: 24` | 24 | 센서없음 아이콘 크기 |
| 23 | `SizedBox(height: 4)` | 4 | 센서없음 아이콘-텍스트 간격 |

### 튜닝 가능 변수 (entropy_progress_indicator.dart)

| 변수명 (제안) | 타입 | 현재값 | min | max | step | 설명 |
|--------------|------|--------|-----|-----|------|------|
| `entropyBarMaxWidth` | double | 280 | 160 | 400 | 20 | 엔트로피 진행 바 최대 너비 |
| `entropyBarTextSpacing` | double | 4 | 0 | 12 | 2 | 진행 바-텍스트 간격 |
| `entropyFallbackIconSize` | double | 24 | 16 | 40 | 4 | 센서 불가 시 아이콘 크기 |

---

## 12. App Theme (`app_theme.dart`)

### 하드코딩 값 목록

| 줄 | 원본 코드 | 값 | 카테고리 |
|----|-----------|-----|----------|
| 6 | `Color(0xFF1A1028)` | 0xFF1A1028 | deepPurple (Surface) |
| 7 | `Color(0xFF0D0A14)` | 0xFF0D0A14 | darkSurface (배경) |
| 8 | `Color(0xFFD4A84B)` | 0xFFD4A84B | gold (Primary) |
| 9 | `Color(0xFF6B5B95)` | 0xFF6B5B95 | softPurple (Secondary) |
| 10 | `Color(0xFFE8E0F0)` | 0xFFE8E0F0 | textPrimary |
| 11 | `Color(0xFF9B8FB8)` | 0xFF9B8FB8 | textSecondary |
| 29 | `fontSize: 28` | 28 | headlineLarge 폰트 크기 |
| 31 | `fontSize: 16` | 16 | bodyLarge 폰트 크기 |
| 32 | `fontSize: 14` | 14 | bodyMedium 폰트 크기 |
| 43 | `BorderRadius.circular(12)` | 12 | Card 모서리 반지름 |
| 44 | `elevation: 4` | 4 | Card 기본 elevation |
| 50 | `BorderRadius.circular(8)` | 8 | ElevatedButton 모서리 |

### 튜닝 가능 변수 (app_theme.dart)

| 변수명 (제안) | 타입 | 현재값 | min | max | step | 설명 |
|--------------|------|--------|-----|-----|------|------|
| `themeColorPrimary` | Color | 0xFFD4A84B | - | - | - | 주색상 (골드) |
| `themeColorSecondary` | Color | 0xFF6B5B95 | - | - | - | 보조색상 (소프트퍼플) |
| `themeColorSurface` | Color | 0xFF1A1028 | - | - | - | 서피스 색상 (딥퍼플) |
| `themeColorBackground` | Color | 0xFF0D0A14 | - | - | - | 배경 색상 (다크) |
| `themeColorTextPrimary` | Color | 0xFFE8E0F0 | - | - | - | 주 텍스트 색상 |
| `themeColorTextSecondary` | Color | 0xFF9B8FB8 | - | - | - | 보조 텍스트 색상 |
| `themeFontSizeHeadline` | double | 28 | 20 | 36 | 1 | 제목 폰트 크기 |
| `themeFontSizeBodyLarge` | double | 16 | 14 | 20 | 1 | bodyLarge 폰트 크기 |
| `themeFontSizeBodyMedium` | double | 14 | 12 | 18 | 1 | bodyMedium 폰트 크기 |
| `themeCardRadius` | double | 12 | 4 | 24 | 2 | Card 위젯 모서리 반지름 |
| `themeCardElevation` | double | 4 | 0 | 12 | 1 | Card 위젯 elevation |
| `themeButtonRadius` | double | 8 | 0 | 20 | 2 | ElevatedButton 모서리 반지름 |

---

## 13. Main / Spring Tuner (`main.dart`)

### 하드코딩 값 목록 (이미 Riverpod으로 관리 중)

| 줄 | 원본 코드 | 값 | 카테고리 | 현재 상태 |
|----|-----------|-----|----------|-----------|
| 25 | `StateProvider<double>((ref) => 0.5)` | 0.5 | 스크롤 스프링 질량 | **이미 튜너 등록** |
| 26 | `StateProvider<double>((ref) => 900.0)` | 900.0 | 스크롤 스프링 강성 | **이미 튜너 등록** |
| 27 | `StateProvider<double>((ref) => 1.3)` | 1.3 | 스크롤 스프링 감쇠 | **이미 튜너 등록** |
| 134 | `Offset(size.width - 48, ...)` | 48 | 튜너 버튼 크기/위치 오프셋 | UI 배치 |
| 134 | `size.height - bottomPadding - 80` | 80 | 튜너 버튼 하단 여백 | UI 배치 |
| 157 | `width: 40, height: 40` | 40 | 튜너 플로팅 버튼 크기 | UI 배치 |
| 159 | `BorderRadius.circular(8)` | 8 | 튜너 버튼 모서리 | UI 배치 |
| 163 | `size: 20` | 20 | 튜너 버튼 아이콘 크기 | UI 배치 |
| 189 | `'mass', mass, 0.1, 3.0` | 0.1 / 3.0 | mass 슬라이더 범위 | 슬라이더 범위 |
| 191 | `'stiffness', stiffness, 50, 3000` | 50 / 3000 | stiffness 슬라이더 범위 | 슬라이더 범위 |
| 193 | `'damping', damping, 0.1, 10.0` | 0.1 / 10.0 | damping 슬라이더 범위 | 슬라이더 범위 |

### 튜닝 가능 변수 (main.dart) — 신규 추가

| 변수명 (제안) | 타입 | 현재값 | min | max | step | 설명 |
|--------------|------|--------|-----|-----|------|------|
| `springMass` | double | 0.5 | 0.1 | 3.0 | 0.1 | 스크롤 스프링 질량 **(이미 등록)** |
| `springStiffness` | double | 900.0 | 50.0 | 3000.0 | 50.0 | 스크롤 스프링 강성 **(이미 등록)** |
| `springDamping` | double | 1.3 | 0.1 | 10.0 | 0.1 | 스크롤 스프링 감쇠 **(이미 등록)** |

---

## 통합 요약 테이블

### 화면별 튜닝 가능 변수 수

| 모듈 | 튜닝가능(O) | 튜닝불가(X) | 합계 |
|------|------------|------------|------|
| home_page.dart | 15 | 0 | 15 |
| shuffle_page.dart | 8 | 3 | 11 |
| tarot_game.dart | 8 | 2 | 10 |
| card_body_component.dart | 28 | 2 | 30 |
| hand_animation_component.dart | 3 | 3 | 6 |
| reading_page.dart | 10 | 2 | 12 |
| intention_page.dart | 7 | 1 | 8 |
| deck_selection_page.dart | 1 | 0 | 1 |
| spread_layout.dart | 1 | 1 | 2 |
| card_reveal_widget.dart | 13 | 2 | 15 |
| entropy_progress_indicator.dart | 3 | 0 | 3 |
| app_theme.dart | 12 | 0 | 12 |
| main.dart (신규) | 0 | 0 | 0 (이미 등록) |
| **합계** | **109** | **16** | **125** |

> 참고: 동일 값이 여러 줄에 중복 등장하는 경우(예: BorderRadius.circular(8) 반복)는 고유 "변수"로 집계. 위 수치는 의미 있는 고유 파라미터 기준.

### 카테고리별 분류

| 카테고리 | 변수 수 | 대표 변수 |
|---------|---------|----------|
| 물리 파라미터 (forge2d) | 12 | linearDamping, friction, restitution, worldGravity |
| 카드 렌더 시각 | 23 | halfWidth/Height, cornerRadius, 색상, 패턴 비율 |
| 그림자/동적 효과 | 8 | shadowBaseOffset, shadowSpeedScale, shadowAlpha |
| 애니메이션 타이밍 | 4 | cardFlipDurationMs, physicsFixedHz, cardSpawnSpeed |
| 카메라/뷰 변환 | 5 | cameraRotateX, cameraPerspective, cameraZoom |
| 색상 (테마) | 12 | themeColorPrimary, cardBackColor 등 |
| 레이아웃 간격 | 30 | padding, margin, spacing, SizedBox 계열 |
| 폰트/타이포 | 8 | fontSize 계열 |
| 비율/배수 | 7 | spreadHeightRatio, cardAspectRatio, shadowYMultiplier |

### 우선순위 TOP 15 (Dev Tuner 즉시 등록 권고)

물리 엔진 파라미터와 핵심 시각 효과 위주:

| # | 변수명 | 파일 | 현재값 | 이유 |
|---|--------|------|--------|------|
| 1 | `cardLinearDamping` | card_body | 3.5 | 카드 정지 속도에 직접 영향. 사용자 체감 1순위 |
| 2 | `cardAngularDamping` | card_body | 2.0 | 카드 회전 멈춤 속도. 물리감 핵심 |
| 3 | `cardSpawnSpeedMin/Range` | tarot_game | 2.0 / 4.0 | 카드 방사 속도 = 셔플 에너지감 |
| 4 | `cardSpawnAngularVelocityMax` | tarot_game | 8.0 | 카드 회전 강도 = 셔플 역동성 |
| 5 | `cardRestitution` | card_body | 0.02 | 충돌 탄성. 0.1+면 튕기는 느낌 |
| 6 | `cardFriction` | card_body | 0.5 | 카드 간 마찰. 겹침 움직임에 영향 |
| 7 | `cameraInitialRotateX` | shuffle_page | 0.65 | 초기 카메라 앵글. 테이블 시점 |
| 8 | `cameraPerspectiveZoom` | shuffle_page | 0.001 | 원근감 강도 |
| 9 | `cameraDragSensitivity` | shuffle_page | 0.005 | 터치 드래그 응답성 |
| 10 | `cardFlipDurationMs` | card_reveal | 400 | 카드 뒤집기 속도. 리딩 UX |
| 11 | `cardFlipPerspective` | card_reveal | 0.002 | 뒤집기 원근감 |
| 12 | `physicsFixedHz` | tarot_game | 45.0 | 물리 시뮬레이션 정밀도 vs 성능 |
| 13 | `cardHalfWidth/Height` | card_body | 0.3/0.45 | 카드 크기 비율 |
| 14 | `shadowSpeedOffsetScale` | card_body | 0.012 | 속도감 표현 그림자 동적 효과 |
| 15 | `readingSpreadHeightRatio` | reading_page | 0.45 | 스프레드 레이아웃 화면 점유율 |

---

## Summary

총 11개 파일에서 하드코딩 숫자값 125개(중복 포함)를 식별하였고, 의미 있는 고유 튜닝 파라미터로 109개를 분류함. 가장 많은 변수를 보유한 파일은 `card_body_component.dart`(28개)로, 카드 물리/렌더 파라미터가 집중되어 있음.

기존 Spring Tuner(`main.dart`)는 스크롤 물리 3개 변수를 이미 관리 중이며, 이번 탐색에서 추가된 109개 변수 전체를 Dev Tuner 레지스트리에 등록하면 실시간 조정이 가능해짐.

## Key Findings

1. **forge2d 물리 파라미터가 핵심**: `card_body_component`의 linearDamping(3.5), angularDamping(2.0), restitution(0.02), friction(0.5) 4개 값이 셔플 물리감 전체를 결정. 실시간 조정 시 가장 극적인 UX 변화를 만든다.

2. **카메라 변환 변수 3개가 몰입감 결정**: `shuffle_page`의 cameraInitialRotateX(0.65 rad), cameraPerspectiveZoom(0.001), cameraDragSensitivity(0.005)가 테이블뷰 몰입감을 제어. 이 값들은 디바이스 폼팩터에 따라 조정 필요.

3. **그림자 동적 효과 8개**: `card_body_component`의 속도 연동 그림자(shadowSpeedOffsetScale, shadowSpeedBlurScale, shadowBaseAlpha 등)가 카드 운동감을 시각화. 현재 값이 미세하여 조정 여지가 큼.

4. **카드 종횡비 하드코딩**: `card_reveal_widget`의 `2.5 / 3.5`(표준 타로 비율)와 `card_body_component`의 `halfWidth(0.3) / halfHeight(0.45)` = `2:3` 비율이 일치하지 않음. 통일 필요.

5. **레이아웃 변수 과다**: 30개 이상의 padding/spacing 값이 모두 개별 하드코딩. Dev Tuner 등록보다 테마 토큰화(spacing scale)가 더 효율적인 접근.

## Recommendations

1. **즉시 등록 (P0)**: forge2d 물리 12개 변수 + 카메라 변환 5개 변수를 Dev Tuner에 우선 등록. 실시간 조정으로 셔플 UX 최적화.

2. **카드 종횡비 통일**: `card_body_component.halfWidth(0.3)/halfHeight(0.45)` = 2:3 비율과 `card_reveal_widget.aspectRatio(2.5/3.5)` = 5:7 비율이 다름. 타로 표준(2.75:4.75 ≈ 7:12) 기준으로 통일 검토.

3. **레이아웃 토큰화**: 30개+ spacing 값은 Dev Tuner 개별 등록보다 `AppSpacing` 클래스로 토큰화(xs=4, sm=8, md=16, lg=24, xl=32)하는 것이 유지보수에 유리. Dev Tuner에는 배율 변수 1개(`spacingScale: 1.0`)로 일괄 제어.

4. **Color 변수 처리**: Color 타입 변수는 Dev Tuner 슬라이더보다 컬러피커 UI가 필요. P2 이후 고려.

5. **physicsFixedHz 범위 주의**: 30Hz 미만은 물리 불안정, 120Hz 초과는 성능 문제. 실제 튜너 min=30, max=90으로 제한 권고.

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
