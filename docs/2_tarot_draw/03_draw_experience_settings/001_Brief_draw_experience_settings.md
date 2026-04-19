---
id: "001"
type: brief
title: "뽑기 경험 설정 재편 — 의도 토글 + 레벨 축소 + 경험 트리"
created: 2026-04-17
status: completed
quality_profile: standard
deep_critique: false
critique_docs: []
summary: >
  뽑기 경험 레벨을 4단계에서 3단계(즉시/2D/2.5D)로 축소하고, '의도 설정' on/off 토글을 독립 설정으로 추가하며,
  '앞면으로 시작'을 설정 페이지에서 홈 뽑기 설정 패널로 이동한다. 조합별 경험 트리를 정의한다.
keywords: [draw, experience-level, intention, settings, experience-tree, navigation]
---

# 뽑기 경험 설정 재편 — 의도 토글 + 레벨 축소 + 경험 트리

## Intent
뽑기 경험의 설정 축을 재편하여 사용자가 자신의 선호에 맞는 경험 경로를 선택할 수 있게 한다.

현재 체험 레벨(1~4단계)에 의도 설정이 암묵적으로 포함되어 있어 사용자가 "의도는 쓰고 싶지만 셔플은 즉시"처럼 교차 조합을 할 수 없다. 의도 설정을 독립 토글로 분리하고, 레벨에서 '연출'을 제거하여 3단계로 단순화하며, '앞면으로 시작'을 뽑기 설정 패널로 이동시켜 체험에 직결되는 설정을 한 곳에 모은다.

## Context
### 현재 설정 구조
- **UserSettings** (`mobile/lib/features/settings/domain/entities/user_settings.dart`):
  - `experienceLevel` (int, 1~4): 1=즉시, 2=연출, 3=2D, 4=2.5D
  - `showFaceUp` (bool): 앞면으로 시작
  - `quickDrawEnabled` (bool): 미사용
- **홈 뽑기 설정 패널** (`mobile/lib/features/home/presentation/pages/home_page.dart`, L345-482):
  - 덱, 레벨(즉시/연출/2D/2.5D), 카드 수, 스프레드, 역방향
  - `showFaceUp`는 여기에 없음
- **설정 페이지** (`mobile/lib/features/settings/presentation/pages/settings_page.dart`):
  - 덱, 체험 레벨, 카드 수, 앞면으로 시작, 카드 이름, 역방향, 한 줄 카드 수, 스프레드, 카드 크기
  - `showFaceUp` 토글이 여기에 있음

### 현재 네비게이션 경로 (by level)
| Level | 경로 |
|-------|------|
| 1 (즉시) | Home → `/draw/result` |
| 2 (연출) | Home → `/draw/animated` (내장 의도 UI + 카드 애니메이션) |
| 3 (2D) | Home → `/intention/:deckId` → `/shuffle/:deckId` → draw-result |
| 4 (2.5D) | Home → `/intention/:deckId` → `/shuffle/:deckId` → draw-result |

### 관련 파일
- `mobile/lib/core/router/app_router.dart` — 라우트 정의
- `mobile/lib/features/shuffle/presentation/pages/intention_page.dart` — 의도 설정 페이지
- `mobile/lib/features/draw/presentation/pages/animated_draw_page.dart` — 연출 페이지 (제거 대상)
- `mobile/lib/features/settings/domain/repositories/user_settings_repository.dart` — 설정 저장소 인터페이스

## Boundaries

### In Scope
| # | Item | Description |
|---|------|-------------|
| 1 | 레벨 축소 (4→3) | '연출' 제거, 즉시/2D/2.5D 3단계로 단순화. experienceLevel 값 재매핑 |
| 2 | 의도 설정 독립 토글 | 새 `showIntention` 필드 추가, 홈 뽑기 설정 패널에 on/off 스위치 배치 |
| 3 | 앞면으로 시작 이동 | 설정 페이지에서 제거, 홈 뽑기 설정 패널에 추가 |
| 4 | 네비게이션 경로 재편 | `_startDraw` 로직을 의도×레벨 조합에 따라 분기 |
| 5 | 경험 트리 문서화 | 모든 설정 조합별 경험 경로를 Brief 내 정의 |
| 6 | 설정 페이지 정합성 | 설정 페이지(SettingsPage)에서도 레벨 3단계 반영, showFaceUp 제거 |

### Out of Scope
| # | Item | Reason |
|---|------|--------|
| 1 | AnimatedDrawPage 삭제 | 파일 유지, 라우트만 제거. 추후 정리 |
| 2 | 2D vs 2.5D 셔플 차이 구현 | 현재 동일 경로. 셔플 모드 분기는 별도 작업 |
| 3 | quickDrawEnabled 필드 정리 | 미사용 필드이나 이번 scope 밖 |
| 4 | UI 디자인 변경 | 기존 미스틱 테마 위젯 재사용, 새 디자인 불필요 |

## Decisions

| # | Decision | Chosen | Rationale | Trade-off | Alternatives Considered |
|---|----------|--------|-----------|-----------|------------------------|
| 1 | 레벨 값 재매핑 방식 | **1/2/3으로 재번호** | 연속된 번호가 코드 가독성과 UI 로직에서 자연스러움. 기존 사용자의 설정이 DB(drift)에 저장되어 있으므로 마이그레이션 필요하나, 초기 프로젝트라 영향 최소 | 기존 DB에 2가 저장된 사용자는 마이그레이션 없이 깨지나, 현재 사용자 수가 개발자 1명이므로 무시 가능 | 기존 값(1/3/4) 유지: 코드에 빈 번호가 남아 혼란. 신규 enum 도입: 과도한 리팩터링 |
| 2 | 의도 설정 필드 | **새 `showIntention` bool 추가 (default: true)** | `quickDrawEnabled`를 재사용할 수 있으나 의미가 불명확하고, 역방향(quick=true → 의도 생략)이라 혼동 유발 | 필드 하나 추가로 UserSettings 모델 변경 + freezed 재생성 필요 | `quickDrawEnabled` 재사용: 의미 불투명, 역방향 매핑으로 인한 버그 위험 |
| 3 | 의도 설정 토글 위치 | **홈 뽑기 설정 패널** | 의도 설정은 뽑기 직전에 결정하는 설정. 체험 레벨, 덱과 같은 뽑기 흐름 설정과 동일 계층. 설정 페이지는 카드 크기, 한 줄 수 등 표시 관련 설정에 집중 | 설정 페이지에도 미러링할 수 있으나, 한 곳에만 두는 게 혼동 방지 | 설정 페이지에만 배치: 뽑기 직전 접근성 떨어짐. 양쪽 모두: 중복 |
| 4 | 앞면으로 시작 이동 방향 | **설정 페이지에서 제거, 홈 패널에 추가** | 앞면 시작은 뽑기 체험에 직접 영향. 뽑기 설정 패널에 있으면 체험 전 바로 조정 가능. 설정 페이지에서 중복 유지 불필요 | 설정 페이지의 토글 섹션이 2개(카드 이름, 역방향)로 줄어듦 | 양쪽 유지: 동일 설정이 두 곳에 있으면 사용자 혼동 |
| 5 | 즉시 레벨 + 의도 ON 경로 | **Home → Intention → DrawResult** | 의도 페이지 후 셔플/애니메이션 없이 바로 결과. 의도를 적고 싶지만 빠르게 뽑고 싶은 사용자 니즈 충족 | 의도 페이지에서 결과로 직행하는 새 경로 필요 | 의도를 즉시에서 무시: 의도 토글의 존재 이유 훼손 |
| 6 | 연출(AnimatedDrawPage) 처리 | **라우트만 제거, 파일 보존** | 파괴적 삭제 회피. 추후 재활용 가능성 열어둠. app_router.dart에서 해당 GoRoute만 제거 | 데드코드가 남지만, Out of Scope에서 추후 정리 예정 | 파일 삭제: 불필요한 파괴적 작업 |

## Open Questions

| # | Question | Impact | Status |
|---|----------|--------|--------|
| — | — | — | 모두 해결됨 |

## Constraints
- **freezed 재생성 필요**: `showIntention` 필드 추가 시 `flutter pub run build_runner build` 실행 필수
- **drift 마이그레이션**: experienceLevel 값 변경(2→ 무효, 3→2, 4→3) 시 DB 마이그레이션 또는 앱 시작 시 보정 로직 필요
- **기존 미스틱 테마 위젯**: 홈 뽑기 패널의 `_GoldSwitch`, `_PillSelector` 등 기존 위젯 재사용

## Exit Criteria
- 의도 설정과 레벨이 독립 축으로 분리되어 모든 교차 조합이 가능함이 확인됨
- 경험 트리가 12개 경로(3레벨 × 2의도 × 2앞면)를 모두 커버
- 앞면으로 시작이 홈 패널에서만 제어됨

## Ideal Criteria

Quality Profile: **Standard**
Priority Dimensions: 없음

| # | Criterion | References (In Scope #) | Type | Dimension |
|---|-----------|------------------------|------|-----------|
| 1 | 레벨 선택지가 정확히 3개(즉시/2D/2.5D)이고, '연출' 옵션이 UI에 없다 | In Scope #1 | assertion | Function |
| 2 | 의도 설정 토글이 홈 뽑기 패널에서 on/off 동작하며, off 시 IntentionPage를 건너뛴다 | In Scope #2 | assertion | Function |
| 3 | 앞면으로 시작 스위치가 홈 뽑기 패널에 존재하고, 설정 페이지에는 없다 | In Scope #3 | assertion | Function |
| 4 | 모든 6가지 레벨×의도 조합에서 올바른 페이지 시퀀스로 네비게이션된다 | In Scope #4 | assertion | Edge |
| 5 | 앞면 시작 on/off에 따라 카드가 즉시 앞면 또는 뒤집기 필요 상태로 표시된다 | In Scope #3 | assertion | Function |
| 6 | 설정 페이지의 체험 레벨 SegmentedButton이 3단계로 업데이트되었다 | In Scope #6 | assertion | Completeness |

## Model Anchors
- **레벨 값**: `experienceLevel` int 필드, 1=즉시 2=2D 3=2.5D. 기존 4단계에서 '연출'(2) 제거, 3→2, 4→3으로 재매핑.
- **의도 토글**: `showIntention` bool (default true). `_startDraw` 분기에서 `showIntention` 여부에 따라 IntentionPage 경유/우회 결정.
- **설정 위치 원칙**: 뽑기 직전 체험에 영향주는 설정(레벨, 덱, 의도, 앞면)은 홈 뽑기 패널. 표시/레이아웃 설정(카드 크기, 한 줄 수, 이름 표시)은 설정 페이지.
- **네비게이션 분기 로직**: `_startDraw(level, deckId)`에서 `showIntention` 체크 → true면 IntentionPage 경유, false면 레벨별 다음 단계로 직행.

## 경험 트리 (Experience Tree)

### 설정 축
| 설정 | 값 | 위치 |
|------|----|------|
| 레벨 | 즉시 / 2D / 2.5D | 홈 뽑기 패널 |
| 의도 설정 | ON / OFF | 홈 뽑기 패널 |
| 앞면으로 시작 | ON / OFF | 홈 뽑기 패널 |

### 전체 경로 맵 (12 경로)

```
[뽑기 버튼 탭]
  │
  ├── 의도 ON ──┬── 즉시 ──┬── 앞면 ON  → Intention → DrawResult(앞면)
  │             │          └── 앞면 OFF → Intention → DrawResult(뒤집기)
  │             │
  │             ├── 2D ────┬── 앞면 ON  → Intention → Shuffle(2D) → DrawResult(앞면)
  │             │          └── 앞면 OFF → Intention → Shuffle(2D) → DrawResult(뒤집기)
  │             │
  │             └── 2.5D ──┬── 앞면 ON  → Intention → Shuffle(2.5D) → DrawResult(앞면)
  │                        └── 앞면 OFF → Intention → Shuffle(2.5D) → DrawResult(뒤집기)
  │
  └── 의도 OFF ─┬── 즉시 ──┬── 앞면 ON  → DrawResult(앞면)
                │          └── 앞면 OFF → DrawResult(뒤집기)
                │
                ├── 2D ────┬── 앞면 ON  → Shuffle(2D) → DrawResult(앞면)
                │          └── 앞면 OFF → Shuffle(2D) → DrawResult(뒤집기)
                │
                └── 2.5D ──┬── 앞면 ON  → Shuffle(2.5D) → DrawResult(앞면)
                           └── 앞면 OFF → Shuffle(2.5D) → DrawResult(뒤집기)
```

### 경로 요약 테이블
| # | 의도 | 레벨 | 앞면 | 경로 |
|---|------|------|------|------|
| 1 | OFF | 즉시 | OFF | Home → DrawResult (뒤집기) |
| 2 | OFF | 즉시 | ON | Home → DrawResult (앞면) |
| 3 | ON | 즉시 | OFF | Home → Intention → DrawResult (뒤집기) |
| 4 | ON | 즉시 | ON | Home → Intention → DrawResult (앞면) |
| 5 | OFF | 2D | OFF | Home → Shuffle(2D) → DrawResult (뒤집기) |
| 6 | OFF | 2D | ON | Home → Shuffle(2D) → DrawResult (앞면) |
| 7 | ON | 2D | OFF | Home → Intention → Shuffle(2D) → DrawResult (뒤집기) |
| 8 | ON | 2D | ON | Home → Intention → Shuffle(2D) → DrawResult (앞면) |
| 9 | OFF | 2.5D | OFF | Home → Shuffle(2.5D) → DrawResult (뒤집기) |
| 10 | OFF | 2.5D | ON | Home → Shuffle(2.5D) → DrawResult (앞면) |
| 11 | ON | 2.5D | OFF | Home → Intention → Shuffle(2.5D) → DrawResult (뒤집기) |
| 12 | ON | 2.5D | ON | Home → Intention → Shuffle(2.5D) → DrawResult (앞면) |

### 핵심 분기 포인트
1. **의도 분기** (`showIntention`): 첫 번째 게이트. ON이면 IntentionPage 경유, OFF면 즉시 다음 단계.
2. **레벨 분기** (`experienceLevel`): 두 번째 게이트. 즉시=DrawResult 직행, 2D/2.5D=Shuffle 경유.
3. **앞면 분기** (`showFaceUp`): DrawResult 도달 후 카드 상태 결정. 네비게이션 경로 자체는 동일.

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 0s | 0 |
| 2 | user-ai-exchange | 317s | 912192 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 604s |
| Total Tokens | 912192 |
| Input Tokens | 5106 |
| Output Tokens | 13389 |
| Cache Read | 811795 |
| Cache Creation | 81902 |
