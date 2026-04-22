---
id: "018"
type: scope
title: "유저/뽑기 메뉴 정리 (선행 작업 점검 + 덱 관리 후속 정리 검토)"
created: 2026-04-20
status: blocked-on-user-decision
complexity: simple
research_needed: false
effort_mode: bypass
tdd_mode: false
auto_run: false
modules: ["mobile/features/profile", "mobile/features/home"]
prior_work:
  - id: settings_menu_relocation
    commit: a8c47f5
    date: 2026-04-19
    status: completed
summary: >
  사용자 ARGUMENTS의 5개 명시 변경 요구는 이미 commit a8c47f5에서 모두 충족됨을 확인.
  남은 잠재 정리 대상은 ProfilePage의 "덱 관리" 진입점 처리 1건(추정)이며,
  사용자 명시 요구가 아니므로 사용자 판단 대기 상태로 종결.
keywords: [navigation, menu, settings, profile, home, deck-management, prior-work]
---

# Scope 018 — 유저/뽑기 메뉴 정리 (재검토)

## Intent (사용자 발화)

> 현재 설정 메뉴가 뽑기, '유저'에 있는데 이걸 뽑기에 유저/설정 메뉴들을 이동시키자.
> 유저 메뉴의 설정은 '뽑기'에 관한 설정은 없는걸로.
> 유저 화면의 '설정'은 '앱 설정'으로 대체해줘.
> 그리고 유저/설정에 있던 뽑기 설정은 하단 메뉴 뽑기 화면의 아래쪽으로 배치시켜줘.

## 선행 작업 점검 — 사용자 ARGUMENTS 5개 요구는 이미 모두 완료됨

`git show a8c47f5` (2026-04-19, 6 files / +1166 / -287) 결과:

| # | 사용자 ARGUMENTS 발화 | 선행 작업 (a8c47f5) | 현재 코드 위치 |
|---|----------------------|---------------------|----------------|
| 1 | 뽑기에 유저/설정 메뉴들을 이동 | 4개 설정(앞면 시작·카드 이름·한 줄 카드 수·카드 크기 진입점)을 settings_page → home `_DrawSettingsPanel` 이동 | `home_page.dart:391~556` |
| 2 | 유저 메뉴의 설정에 뽑기 관련 없게 | settings_page 본문 → "환경설정 준비 중" placeholder로 교체 | `settings_page.dart:1~50` |
| 3 | 유저 화면 '설정' → '앱 설정' | ProfilePage `_MenuTile` title을 '설정'에서 '앱 설정'으로 변경 | `profile_page.dart:88` (`title: '앱 설정'`) |
| 4 | 뽑기 설정은 뽑기 화면 아래쪽 배치 | `_DrawSettingsPanel`을 home 히어로 섹션 아래에 위치 + "기본 설정" / "표시 옵션" 서브그룹 분리 (`_PanelSubheader`) | `home_page.dart:391, 482` |
| 5 | 통합 정합성 | route `/settings` 이름 'settings' 보존 (유저 → 진입 가능) | `app_router.dart:158~162` |

→ **선행 작업이 ARGUMENTS의 명시 요구를 100% 충족**. 추가 코드 변경 없이 이미 종결된 상태.

## 잠재 후속 정리 대상 (사용자 명시 X, 분석가 추정)

ProfilePage 메뉴 항목 분류 관점에서 한 가지만 어색함이 남는다:

| 메뉴 항목 | 현재 routes | 도메인 분류 | 정리 후보 여부 |
|-----------|-------------|-------------|----------------|
| 앱 설정 | `/settings` | 일반 앱 환경 (테마·햅틱·알림) | 유지 |
| **덱 관리** | `/deck` (DeckSelectionPage) | **뽑기 도메인** (덱 선택/탐색) | **이동 후보** |
| 앱 정보 | (no-op) | 메타 | 유지 |

**제안 변경 (사용자 승인 필요)**:
1. ProfilePage `_MenuTile("덱 관리")` 제거
2. HomePage `_DrawSettingsPanel` 맨 아래(카드 크기 진입 행 다음)에 "덱 관리하기" 진입 행 추가 → `context.push('/deck')`

이 변경은 **사용자 ARGUMENTS에 명시되지 않았으므로** scope 018에서 자동 실행하지 않는다. 사용자가 의도했다면 즉시 makeplan→impl→verify로 진행 가능 (effort_mode: bypass).

## 변경 설계

### 파일 분류

**Modified (actual change)** — confidence: high
| # | 파일 | 변경 |
|---|------|------|
| 1 | `mobile/lib/features/profile/presentation/pages/profile_page.dart` | "덱 관리" `_MenuTile` 제거 + 인접 `GoldHairline` 정리. 메뉴는 "앱 설정"·"앱 정보" 2개 항목만. |
| 2 | `mobile/lib/features/home/presentation/pages/home_page.dart` | `_DrawSettingsPanel` 맨 아래(카드 크기 행 아래)에 "덱 관리하기" 진입 행 추가. `GestureDetector` → `context.push('/deck')`. 기존 카드 크기 행과 동일 패턴(`Icons.layers_outlined`, "덱 탐색·미리보기" 부제). |

**Reviewed (check-only)** — 변경 없음 확인용
| # | 파일 | 확인 사항 |
|---|------|----------|
| 3 | `mobile/lib/features/settings/presentation/pages/settings_page.dart` | placeholder 카피 "환경설정 영역이 준비 중입니다" + "테마·햅틱·알림"이 일반 앱 설정 정체성에 부합 → 변경 없음 |
| 4 | `mobile/lib/core/router/app_router.dart` | `/deck` 라우트는 셸 밖 전체화면 라우트로 이미 존재 (line 116-120) → 변경 없음 |

### 결과 구조

**유저 탭 (ProfilePage) 메뉴 — 변경 후**:
```
┌─ 프로필 헤더 (탐험가 + Lv 배지)
├─ 앱 설정 (settings_outlined → /settings)
└─ 앱 정보 (info_outline, no-op)
```

**뽑기 탭 (HomePage `_DrawSettingsPanel`) — 변경 후**:
```
┌─ [기본 설정] 덱·레벨·카드수·스프레드·역방향
├─ [표시 옵션] 앞면으로 시작·카드 이름·한 줄 카드 수·카드 크기
└─ ★ 덱 관리하기 (신규 진입 행, → /deck)
```

## Out of Scope

- `/settings` placeholder 페이지의 실제 기능 구현 (테마·햅틱·알림) — 별도 작업
- _DrawSettingsPanel 내부 항목 재배치/재그룹핑 — 현재 그룹 헤더 구조 유지
- ProfilePage 프로필 헤더(탐험가/Lv 배지) 변경 — 영향 없음
- "앱 정보" 항목 활성화 (현재 no-op) — 별도 작업
- 라우트 트리 자체의 재구조화 (`/deck`을 셸 안 탭으로 옮기는 등) — 영향 없음

## Acceptance

1. `flutter analyze` 통과 (warning 0, error 0)
2. `flutter build apk --debug` 빌드 성공
3. ADB 스크린샷 검증:
   - 유저 탭 진입 → 메뉴 2개("앱 설정"/"앱 정보")만 표시
   - 뽑기 탭 진입 → 스크롤 → `_DrawSettingsPanel` 맨 아래에 "덱 관리하기" 행 표시
   - "덱 관리하기" 탭 → `/deck` 페이지(DeckSelectionPage) 정상 진입

## Pipeline

- Cycle 1: makeplan → implementation → verify
- Tail: 없음 (effort_mode: bypass, eval/qualify/push/retro 없음)
- Auto-commit: implementation 완료 후 자동 커밋

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 0s | 0 |
| 2 | user-ai-exchange | 451s | 935162 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 499s |
| Total Tokens | 935162 |
| Input Tokens | 21 |
| Output Tokens | 27853 |
| Cache Read | 778646 |
| Cache Creation | 128642 |
