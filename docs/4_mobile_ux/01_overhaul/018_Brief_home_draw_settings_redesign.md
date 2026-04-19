---
title: 홈(뽑기 메뉴) — 카드 설정 통합 & 디자인 개편
slug: home_draw_settings_redesign
type: Brief
status: completed
quality_profile: Showcase
topic: 09_mobile_ui_overhaul
created: 2026-04-16
summary: 홈 페이지(뽑기 탭)에 뽑기 직결 카드 설정 5종(덱·레벨·카드수·역방향·스프레드)을 인라인 조정 가능하게 통합하고, 미스틱 타로 감성의 Showcase급 디자인으로 홈 페이지를 전면 개편한다.
---

## Intent

뽑기를 시작하기 전 설정 페이지를 따로 열지 않고, 홈 페이지(뽑기 탭)에서 핵심 카드 설정을 바로 보고 조정할 수 있도록 구성한다. 동시에 홈 페이지 디자인을 /frontend-design 수준으로 전면 개편하여 타로 서비스의 첫인상을 Showcase급으로 끌어올린다.

## Context

| 항목 | 현황 |
|------|------|
| 홈 페이지 | 미스틱 다크 배경 + 원형 "바로 뽑기" 버튼 + infochip 3개(읽기 전용) + 최근 리딩 목록 |
| 설정 페이지 | 카드 설정 9종 + 카드 크기(별도 페이지). 홈에서 직접 조정 불가 |
| 상태 관리 | Riverpod + userSettingsRepositoryProvider. 변경 즉시 DB 반영 |
| 라우팅 | go_router, 홈 = `/` (StatefulShellBranch tab 0) |
| 테마 | darkTheme — gold #D4A84B, deepPurple #1A1028, darkSurface #0D0A14, softPurple #6B5B95 |

## Boundaries

### In Scope

1. **HomePage 디자인 전면 개편** — /frontend-design 수준, Showcase 품질
2. **뽑기 핵심 설정 5종 인라인 통합** — 홈 페이지에서 즉시 조정 가능:
   - 덱 선택 (selectedDeckId)
   - 체험 레벨 (experienceLevel: 즉시/연출/2D/2.5D)
   - 기본 카드 수 (defaultCardCount: 1~10)
   - 역방향 카드 허용 (allowReversed)
   - 기본 스프레드 (defaultSpreadType)
3. **설정 변경 즉시 반영** — 기존 userSettingsRepositoryProvider 재사용

### Out of Scope

- SettingsPage 변경 없음 (종합 설정 허브로 유지, 설정 항목 제거 안 함)
- 표시 설정 4종(앞면으로 시작·카드 이름·한 줄 카드 수·카드 크기) — SettingsPage 전용 유지
- IntentionPage, ShufflePage, DrawResultPage 디자인 변경 없음
- 새 라우트 추가 없음

## Decisions

| # | 결정 | 선택 | 이유 | Trade-off |
|---|------|------|------|-----------|
| 1 | Surface 대상 설정 | 뽑기 직결 5종만 | 덱·레벨·카드수·역방향·스프레드는 뽑기 전 매번 변경 가능성 高. 앞면·카드명·카드크기 등은 결과 표시 설정 — 뽑기 전 맥락과 무관 | 표시 설정은 홈에서 접근 불가. 설정 페이지 접근 경로 유지로 보완 |
| 2 | 설정 페이지 관계 | 중복 유지(퀵 액세스) | 설정 페이지는 모든 설정의 종합 허브 역할 유지. 홈은 "뽑기 전 빠른 조정" 맥락. 제거 시 표시 설정 접근 불가 | 5종 설정이 두 곳에 존재. 동기화는 같은 provider로 자동 처리 |
| 3 | UX 패턴 | 홈 내 카드형 설정 섹션 | 스크롤 가능한 섹션으로 배치 — 탭하면 즉시 편집. Bottom sheet 제외: 뽑기 플로우의 수직 스크롤과 제스처 충돌 우려. 별도 페이지 제외: 뽑기 전 화면 전환 비용 高 | 화면이 길어짐. SingleChildScrollView로 해결 |
| 4 | 디자인 방향 | 기존 테마 강화 | gold/deepPurple/darkSurface 팔레트 유지. 글로우 이펙트·그라디언트·세련된 카드 UI 추가. 타로 서비스 정체성과 일관성 유지 | 완전히 새 팔레트는 기존 페이지들과 불일치 발생 |
| 5 | Quality Profile | Showcase | 홈은 타로 앱의 첫인상. /frontend-design 스킬이 명시적으로 호출됨 — 고품질 의도 명확 | 구현 복잡도 증가. 홈 파일 규모 확대 |

## Constraints

- 기존 `userSettingsRepositoryProvider` API 그대로 사용 (updateSelectedDeckId, updateExperienceLevel, updateDefaultCardCount, updateAllowReversed, updateDefaultSpreadType)
- Flutter Material 3 + Riverpod 패턴 준수
- `--disable-dds` 환경 (hot reload 가능, DevTools 프로파일링 불가)

## Ideal Criteria

| # | Criterion | References | Type | Dimension |
|---|-----------|-----------|------|-----------|
| 1 | 홈 페이지에서 덱·레벨·카드수·역방향·스프레드 5종을 수정하면 동일 설정이 설정 페이지에도 즉시 반영된다 | In Scope #2, #3 | assertion | Function |
| 2 | 뽑기 버튼이 항상 화면에서 즉시 인지 가능한 위치에 있다 (스크롤 없이 보임) | In Scope #1 | assertion | UX |
| 3 | 설정 섹션이 뽑기 버튼과 시각적으로 명확히 구분된다 | In Scope #1, #2 | assertion | UX |
| 4 | 타로 미스틱 감성(다크·골드·글로우)이 시각적으로 강화되어 Showcase 수준의 완성도를 보인다 | In Scope #1 | directional | UX |
| 5 | 최근 리딩 목록이 설정 아래에 자연스럽게 이어진다 (정보 위계 명확) | In Scope #1 | assertion | UX |
| 6 | 빌드 성공(flutter build apk --debug) 및 기존 기능 회귀 없음 | In Scope #1-3 | assertion | Robustness |

## Model Anchors

- **MA-1**: HomePage는 단일 파일로 유지. 위젯 분리는 동일 파일 내 private class로.
- **MA-2**: 설정 변경은 `ref.read(userSettingsRepositoryProvider).updateXxx(v)` 패턴 그대로.
- **MA-3**: `userSettingsProvider`는 AsyncValue — `.when()` 또는 `.valueOrNull`로 처리. 로딩 중 UI는 shimmer 또는 placeholder.
- **MA-4**: `/frontend-design` 수준 디자인 — glowEffect, 섬세한 그라디언트, 골드 액센트. AI slop 패턴(과도한 shadow, 무의미한 gradient stack) 지양.
- **MA-5**: SettingsPage 수정 없음. 홈의 설정 UI는 HomePage 내 self-contained.
- **MA-6**: 뽑기 버튼은 시각적 anchor point — 화면 상단 절반 내에 위치하거나 고정.

## Open Questions

(없음 — 모두 자율 결정)

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 0s | 0 |
| 2 | user-ai-exchange | 0s | 0 |
| 3 | user-ai-exchange | 0s | 0 |
| 4 | user-ai-exchange | 0s | 0 |
| 5 | user-ai-exchange | 0s | 0 |
| 6 | user-ai-exchange | 3s | 24870 |
| 7 | user-ai-exchange | 35s | 104466 |
| 8 | user-ai-exchange | 19s | 28455 |
| 9 | user-ai-exchange | 23s | 29829 |
| 10 | user-ai-exchange | 527s | 1932903 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 120944s |
| Total Tokens | 2120523 |
| Input Tokens | 54 |
| Output Tokens | 35429 |
| Cache Read | 1960565 |
| Cache Creation | 124475 |
