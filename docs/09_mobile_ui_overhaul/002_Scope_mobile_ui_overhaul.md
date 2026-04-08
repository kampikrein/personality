---
id: "002"
type: scope
title: "Mobile UI 대대적 정리 — 기술 스코프"
created: 2026-03-22
traces_brief: "001"
complexity: complex
research_needed: true
research_reason: "셔플→리딩 데이터 플로우(+1 기능), Drift 마이그레이션 v2, GoRouter redirect 패턴 — 3개 기술 통합 포인트 확인 필요"
auto_run: true
effort_mode: standard
uncertainty_level: medium
intent: >
  메인 메뉴 허브 → 3단계 체험 레벨(즉시/간단연출/풀셔플) → 즉시 뽑기 모드.
  1~10장 자유 + 덱별 고유 뽑기 + 한 장 더 뽑기. 모든 리딩 자동 저장 + 메모 + 분류.
  설정은 UserSettings DB 테이블.
summary: >
  3개 영역, 5개 의존 관계, 3개 사이클.
  Cycle 1: 데이터 기반(UserSettings 테이블, SpreadType 확장, DeckMetadata 확장).
  Cycle 2: 설정 + 리딩 기능(설정 페이지, 리딩 목록/상세, 자동 저장, +1 뽑기).
  Cycle 3: 홈 허브 + 뽑기 체험(홈 재설계, 라우터 재구조, Level 1/2/3 뽑기).
keywords: [mobile, ui, home, settings, reading, draw, drift, gorouter, riverpod]
cycles:
  - cycle: 1
    area: "데이터 기반 (Data Foundation)"
    depends_on: []
    research_needed: true
  - cycle: 2
    area: "설정 + 리딩 기능 (Settings & Reading)"
    depends_on: [1]
    research_needed: false
  - cycle: 3
    area: "홈 허브 + 뽑기 체험 (Home Hub & Draw Experience)"
    depends_on: [1, 2]
    research_needed: false
---

# Mobile UI 대대적 정리 — 기술 스코프

## 작업 목표

Brief(001)에서 확정된 7개 결정사항과 10개 In Scope 항목을 구현하기 위한 기술 스코프.

**성공 기준:**
- 앱 첫 진입 시 메인 메뉴 허브 표시
- `quickDrawEnabled` 설정 시 다음 진입부터 체험 레벨에 따른 즉시 뽑기
- 1~10장 자유 선택 + 덱별 뽑기 방식 구조 준비
- 매 뽑기 자동 저장 + 메모 + 유형별 리딩 목록
- "+1 한 장 더" 버튼으로 점진적 카드 추가
- 앞면/뒷면 표시 설정 적용

**제약:**
- Drift DB 하위 호환 (schemaVersion 1 → 2 마이그레이션)
- Riverpod + GoRouter + Freezed 패턴 유지
- 기존 셔플 엔진(Flame) 수정 없음 — 라우팅 연결만

## 접근 방향

**선택: 3사이클 Bottom-Up 빌드**

데이터 레이어(UserSettings, SpreadType 확장) → 기능 레이어(설정 UI, 리딩 강화) → 통합 레이어(홈 허브, 라우터, 뽑기 체험) 순서로 쌓아올림.

**대안 (기각):**
- 홈 먼저 → 데이터 나중: 홈이 UserSettings를 필요로 하므로 stub이 필요하고, 나중에 연결 시 재작업 발생
- 전체 일괄 구현: 20+ 파일이라 하나의 Plan이 너무 커지고, 검증 단위가 넓어짐

## Research 판단

- **판단**: 필요 (Cycle 1에서만)
- **근거**: Brief가 성숙하나(7결정, 8앵커), 3개 기술 통합 포인트(셔플→리딩 데이터 플로우, Drift migration v2, GoRouter redirect)는 코드 내부 조사 필요
- **파이프라인**: Skill(R) → eval → Agent(P) → Agent(I) → Agent(V) [Cycle 1] → eval → Agent(P) → Agent(I) → Agent(V) [Cycle 2] → eval → Agent(P) → Agent(I) → Agent(V) [Cycle 3]

## 영역 식별

| # | 영역 | 주요 파일/모듈 | 설명 |
|---|------|-------------|------|
| A | 데이터 기반 | `core/database/`, `features/*/domain/entities/` | UserSettings 테이블+DAO, SpreadType 확장, DeckMetadata 확장, settings 엔티티+리포지토리+프로바이더 |
| B | 설정 + 리딩 기능 | `features/settings/(NEW)`, `features/reading/` | 설정 페이지, 리딩 목록/상세, 자동 저장, +1 뽑기 |
| C | 홈 허브 + 뽑기 체험 | `features/home/`, `features/draw/(NEW)`, `core/router/` | 홈 재설계, 라우터 재구조, Level 1/2 뽑기 페이지, Level 3 라우팅 |

### 영역별 파일 목록

**영역 A: 데이터 기반** (confidence: high)

Modified:
- `core/database/tables/user_settings_table.dart` (NEW)
- `core/database/daos/user_settings_dao.dart` (NEW)
- `core/database/app_database.dart` (modify — add table + DAO + schemaVersion 2)
- `features/reading/domain/entities/spread_type.dart` (modify — extend enum or convert)
- `features/deck/domain/entities/deck_metadata.dart` (modify — add supportedDrawModes)
- `features/settings/domain/entities/user_settings.dart` (NEW — Freezed)
- `features/settings/domain/repositories/user_settings_repository.dart` (NEW)
- `features/settings/data/repositories/user_settings_repository_impl.dart` (NEW)
- `features/settings/presentation/providers/settings_providers.dart` (NEW)

Reviewed: `core/database/daos/reading_dao.dart`, `features/deck/data/repositories/deck_repository_impl.dart`

**영역 B: 설정 + 리딩 기능** (confidence: medium)

Modified:
- `features/settings/presentation/pages/settings_page.dart` (NEW)
- `features/reading/presentation/pages/reading_list_page.dart` (NEW)
- `features/reading/presentation/pages/reading_detail_page.dart` (NEW)
- `features/reading/presentation/pages/reading_page.dart` (modify — auto-save + "+1" 버튼)
- `features/reading/presentation/providers/reading_providers.dart` (modify)
- `features/reading/presentation/widgets/spread_layout.dart` (modify — dynamic card count)

Reviewed: `features/reading/domain/entities/reading.dart`, `features/shuffle/domain/entities/shuffle_result.dart`

**영역 C: 홈 허브 + 뽑기 체험** (confidence: medium)

Modified:
- `features/home/presentation/pages/home_page.dart` (rewrite)
- `core/router/app_router.dart` (rewrite — new routes + redirect)
- `features/draw/presentation/pages/instant_draw_page.dart` (NEW — Level 1)
- `features/draw/presentation/pages/animated_draw_page.dart` (NEW — Level 2)
- `features/draw/presentation/providers/draw_providers.dart` (NEW)

Reviewed: `features/shuffle/presentation/pages/shuffle_page.dart` (Level 3 라우팅 확인)

## 의존성 맵

**다이어그램:**
```
     ┌─────────────────────┐
     │  A: 데이터 기반       │
     │  (UserSettings,      │
     │   SpreadType,        │
     │   DeckMetadata)      │
     └──────┬──────┬────────┘
            │      │
            ▼      ▼
  ┌─────────────┐  ┌───────────────────┐
  │ B: 설정 +    │  │ (B의 reading 변경 │
  │ 리딩 기능    │  │  도 A에 의존)      │
  └──────┬──────┘  └───────────────────┘
         │
         ▼
  ┌─────────────────────┐
  │ C: 홈 허브 +         │
  │ 뽑기 체험            │
  │ (A의 UserSettings +  │
  │  B의 설정 페이지 참조)│
  └─────────────────────┘
```

**의존 관계 상세:**

| From | To | 의존 내용 | 근거 |
|------|----|---------|------|
| B | A | UserSettings 엔티티 + provider | 설정 페이지가 UserSettings를 읽고 쓰기 |
| B | A | 확장된 SpreadType | 리딩 목록 필터가 새 SpreadType 사용 |
| C | A | UserSettings의 quickDrawEnabled, experienceLevel | 라우터 redirect 분기 |
| C | B | 설정 페이지 라우트 | 홈 허브에서 설정으로 네비게이션 |
| C | B | 리딩 목록 라우트 | 홈 허브에서 리딩 목록으로 네비게이션 |

## 실행 순서

| 사이클 | 영역 | 선행 조건 | Research | 파이프라인 |
|--------|------|---------|----------|-----------|
| 1 | 데이터 기반 (A) | 없음 | 필요 | R→eval→Agent(P)→Agent(I)→Agent(V) |
| 2 | 설정 + 리딩 기능 (B) | 사이클 1 | 불필요 | eval→Agent(P)→Agent(I)→Agent(V) |
| 3 | 홈 허브 + 뽑기 체험 (C) | 사이클 1, 2 | 불필요 | eval→Agent(P)→Agent(I)→Agent(V) |

## 사이클별 연구 가이드 (Cycle 1만)

**사이클 1: 데이터 기반**
- 조사 대상:
  - `core/database/app_database.dart` — Drift migration 패턴 (v1 → v2)
  - `core/database/daos/*.dart` — DAO 패턴 확인
  - `features/shuffle/domain/entities/shuffle_result.dart` — ShuffleResult.cards 구조 ("+1" 기능 설계 기반)
  - `features/reading/presentation/providers/reading_providers.dart` — 리딩 저장 플로우
  - `core/router/app_router.dart` — GoRouter redirect 지원 여부
- 핵심 질문:
  1. ShuffleResult에서 사용되지 않은 카드 풀을 어떻게 유지하고 ReadingPage에 전달하는가?
  2. Drift migration v2에서 UserSettings 테이블 추가 시 기존 데이터 보존 방법은?
  3. SpreadType을 enum으로 유지할 수 있는가, 아니면 데이터 클래스로 전환해야 하는가?
  4. GoRouter의 redirect에서 async DB 조회(UserSettings)를 사용할 수 있는가?

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
