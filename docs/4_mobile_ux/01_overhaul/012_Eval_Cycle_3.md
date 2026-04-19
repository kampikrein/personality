---
id: "012"
type: eval
title: "Eval: Cycle 3 (FINAL) — 홈 허브 + 뽑기 체험"
created: 2026-03-22
cycle: 3
effort_mode: standard
persona: default
verdict: proceed
depth_score: 11
critical_gate: PASS
terminate: true
recommended_changes: []
summary: >
  3사이클 파이프라인 완료. Brief MA-1~MA-8 전량 충족, In Scope 10개 항목 전량 커버.
  Cycle 3 Verify 12/12 PASS, 전 사이클 합산 scope drift 0, critical issue 0.
  Depth Score 11/12로 proceed + 정상 종료 판정.
---

# Eval: Cycle 3 (FINAL) — 홈 허브 + 뽑기 체험

## 1. 시그널 수집 결과

### Scope 문서 (002)

| 항목 | 값 |
|------|---|
| Intent | 메인 메뉴 허브 → 3단계 체험 레벨 → 즉시 뽑기. 1~10장 자유 + 덱별 고유 뽑기 + 한 장 더. 설정은 UserSettings DB |
| Cycle 3 영역 | 홈 허브 + 뽑기 체험 — 홈 재설계, 라우터 재구조, Level 1/2/3 뽑기 |
| 의존관계 | Cycle 3은 Cycle 1, 2에 의존 |
| 파이프라인 | eval → Agent(P) → Agent(I) → Agent(V) [Cycle 3] |

### Verify 리포트 (011)

| 시그널 | 값 |
|--------|---|
| V3 (pass rate) | 12/12 = **100%** |
| V4 (critical issues) | **0건** |
| V5 (skip count) | **0건** |

### Implementation 결과

| 시그널 | 값 |
|--------|---|
| I1 (scope 외 변경 파일) | **0건** — 소스 5개 + codegen 2개 = 7파일, 모두 Plan(010) 명세 범위 내 |
| I2 (unresolved items) | **0건** — Plan 8 Step 전수 구현 완료 |

### Git diff vs Plan 파일 목록

**Plan 명세 파일 (신규 4 + 수정 2 + codegen)**:

| # | Plan 파일 | 커밋 포함 | 일치 |
|---|----------|----------|------|
| 1 | `draw/presentation/providers/draw_providers.dart` (NEW) | da5ed20 | O |
| 2 | `draw/presentation/pages/instant_draw_page.dart` (NEW) | da5ed20 | O |
| 3 | `draw/presentation/pages/animated_draw_page.dart` (NEW) | da5ed20 | O |
| 4 | `home/presentation/pages/home_page.dart` (REWRITE) | da5ed20 | O |
| 5 | `core/router/app_router.dart` (MODIFY) | da5ed20 | O |
| 6 | `draw/presentation/providers/draw_providers.g.dart` (codegen) | da5ed20 | O |
| 7 | `core/router/app_router.g.dart` (codegen) | da5ed20 | O |

**Plan 외 변경 파일**: 0건. 7파일 전부 Plan 명세 범위 내.

### 상위 Initiative 정렬 (S1/S2/S3)

| 시그널 | 값 | 근거 |
|--------|---|------|
| S1 (커버리지) | **100%** (3/3 사이클 완료) | 전 사이클 완료 |
| S2 (미구현 영역) | **없음** | Brief In Scope 10개 항목 모두 구현됨 (아래 상세) |
| S3 (잔여율) | N/A | 데이터 전환 과제 아님 |

### 문서 교차 대조

토픽 폴더 내 11개 문서(001~011) 전수 스캔 완료. 상세는 Section 4에 기술.

## 2. Critical Gate

**PASS** — V4 (critical issues) = 0건. Verify(011)에서 12개 검증 기준 전량 통과. 발견사항 2건 모두 경미(D-011-1, D-011-2).

## 3. Scoring

| 차원 | 원시값 | 점수 | 근거 |
|------|--------|------|------|
| **V-score** | 100% (12/12 PASS) | **3** | Verify(011)에서 전 기준 통과. dart analyze 0건 |
| **U-score** | 0건 unresolved | **3** | Plan(010) 8 Step 전수 구현 완료 |
| **D-score** | 0건 scope drift | **3** | 7파일 전부 Plan 명세 범위 내. 가중 drift = 0 |
| **T-score** | Verify가 12개 기준 + 코드 경로 추적 | **2** | Verify(011)가 검증 기준별 코드 라인 참조 + edge case 분석 수행. 자동화 verify-trace 미실행이나 수동 전수 검증 완료 |

**Depth Score = 3 + 3 + 3 + 2 = 11 / 12**

## 4. 문서 미기재 발견사항

### 신규 발견

- **EV-012-D1**: `InstantDrawPage`와 `AnimatedDrawPage`가 `draw_providers.dart`의 `executeDrawProvider`를 사용하지 않고 인라인으로 셔플 로직을 실행. `seedRwsDeck()` 호출이 provider에 포함되지 않았기 때문. 기능 문제 없으나 유사 로직이 3곳(instant, animated, provider)에 중복. 향후 리팩터링 시 provider에 seedRwsDeck을 통합하거나 미사용 provider를 제거 권장.

- **EV-012-D2**: Level 1 `_autoSave()`가 `build()` 내에서 호출됨 (instant_draw_page.dart:161). Cycle 2 Eval(009)의 EV-009-D2와 동일 패턴. Level 1에서는 결과 즉시 표시 특성상 build 첫 호출에서 저장이 트리거되므로 기능적 문제 없으나, Flutter build 관례(side-effect-free) 위반. `WidgetsBinding.instance.addPostFrameCallback` 전환 고려.

- **EV-012-D3**: Level 2 `_addOneMore()` 호출 시 새 카드에 대한 AnimationController가 생성되지 않음 (기존 _slideControllers.length 이후 인덱스). `_animatedCard()`에서 `index >= _slideControllers.length`일 때 애니메이션 없이 즉시 표시하는 fallback이 있어 기능적 문제 없음 (animated_draw_page.dart:449-451). 의도된 동작이지만, "+1" 카드에도 슬라이드 애니메이션을 적용하면 UX가 더 일관적.

### 문서 간 불일치

- 없음. Brief(001) → Scope(002) → Research(003) → Plan(004/007/010) → Verify(005/008/011) → Eval(006/009) — 전 문서 체인의 일관성 확인 완료. 12개 문서 간 상호 참조(traces_*) 정확.

### 암묵적 가정

- **EV-012-A1**: GoRouter redirect에서 `ref.watch(userSettingsProvider).valueOrNull`이 앱 시작 시 초기값으로 null을 반환할 수 있음. 이 경우 redirect가 발동하지 않아 홈 표시. 이후 Stream이 첫 값을 emit하면 GoRouter가 재생성되지만, 사용자가 이미 홈에서 다른 페이지로 이동했을 수 있음. `matchedLocation != '/'` 가드 덕분에 다른 페이지에서는 redirect가 발생하지 않으므로 안전. 다만 `quickDrawEnabled == true`인 사용자가 앱 시작 시 홈을 잠깐 보게 될 수 있음 (Stream 초기 로딩 지연).

### 부수 효과

- **EV-012-S1**: 홈 페이지가 기존 `_quickDraw` (rws-standard 고정, threeCard 고정) 방식에서 UserSettings 기반 뽑기로 전환됨. 기존 동작(홈 "바로 뽑기" → rws-standard + threeCard)은 UserSettings 기본값이 `selectedDeckId: 'rws-standard'`, `defaultCardCount: 3`이므로 첫 사용자에게 동일 경험 제공. 기존 동작 호환성 유지.

- **EV-012-S2**: 홈 페이지에서 기존 "셔플 시작" 버튼이 사라지고, 4개 기능 카드 그리드로 대체됨. "뽑기 시작" 카드가 experienceLevel에 따라 Level 1/2/3으로 분기하므로, experienceLevel=3(풀 셔플) 설정 시에만 기존 셔플 체험 접근 가능. 기본값 experienceLevel=1이므로 기존 사용자가 Level 3 경험을 위해서는 설정 변경 필요.

## 5. Verdict 도출

### Scoring → Verdict 매핑

- Depth Score: **11/12**
- 0점 차원: **없음** (최저 T-score = 2)
- 판정 기준: 10-12 → **proceed**

### Brief Alignment — 전체 Model Anchors 평가

| Model Anchor | 요구사항 | 구현 사이클 | 구현 상태 | 평가 |
|-------------|---------|-----------|----------|------|
| **MA-1** (진입 흐름 분기) | quickDrawEnabled에 따른 initialLocation 분기, 메인 메뉴 허브 | C3 | GoRouter redirect: `quickDrawEnabled` + `experienceLevel` 분기. 홈 = GridView 4개 기능 카드 허브 | **완전 충족** |
| **MA-2** (3단계 체험 레벨) | Level 1 즉시(0.5초), Level 2 간단연출(2~3초), Level 3 풀셔플 | C3 | `/draw/instant` (initState에서 셔플→즉시 렌더), `/draw/animated` (stagger 애니메이션 ~2초), `/shuffle/:deckId` (기존 Flame 연결) | **완전 충족** |
| **MA-3** (카드 수 & 스프레드 확장) | SpreadType에 custom(N) 추가, DeckMetadata에 supportedDrawModes, NamedSpread 구조 | C1 | `SpreadType.custom` + `resolvePositions/Guidances`, `DrawMode` enum, `DeckMetadata.supportedDrawModes` | **완전 충족** |
| **MA-4** (UserSettings 테이블) | Drift 테이블 8필드, 단일 row, Riverpod Stream provider | C1 | `UserSettingsTable` 8컬럼 + `UserSettingsDao` + Repository + `userSettingsProvider` Stream | **완전 충족** |
| **MA-5** (리딩 저장 & 메모) | 자동 저장 + notes 인라인 편집 + spreadType 필터 목록 | C2 | `_autoSave()` allRevealed 시 자동 + `ReadingDetailPage` debounce notes + `ReadingListPage` FilterChip | **완전 충족** |
| **MA-6** (라우트 구조 재설계) | 허브 모델: /, /draw, /shuffle/:deckId, /readings, /readings/:id, /settings, /deck | C2+C3 | 10개 라우트 등록: /, /deck, /intention/:deckId, /shuffle/:deckId, /reading/:deckId, /draw/instant, /draw/animated, /settings, /readings, /readings/:readingId | **완전 충족** |
| **MA-7** (카드 표시 방식) | showFaceUp 설정 적용, Level 1/2에만 | C2+C3 | Level 1: 항상 즉시 reveal (설계 의도). Level 2: `_showFaceUp` 읽어 플립 생략/실행 분기. CardRevealWidget `initState`에서 `isRevealed` 체크 (264b181) | **완전 충족** |
| **MA-8** (한 장 더 뽑기) | "+1" FAB → 카드 append + DB 갱신 + 비활성화 | C2+C3 | ReadingPage, InstantDrawPage, AnimatedDrawPage 모두에 `_addOneMore()` + `addDrawnCard()` + FAB 조건부 표시 + 남은 카드 수 label | **완전 충족** |

**8/8 Model Anchors 완전 충족.**

### Scope In Scope 항목 커버리지

| # | In Scope 항목 | 구현 사이클 | 구현 증거 | 평가 |
|---|-------------|-----------|----------|------|
| 1 | 홈 화면 재설계 | C3 | `home_page.dart` → GridView.count 4개 기능 카드 + 최근 리딩 3개 미리보기 | **커버** |
| 2 | 즉시 뽑기 기능 | C3 | GoRouter redirect + `instant_draw_page.dart` (Level 1) + `animated_draw_page.dart` (Level 2) | **커버** |
| 3 | 뽑기 유형 설정 | C1+C2 | `SpreadType.custom` + SettingsPage `defaultCardCount` Slider (1~10장) | **커버** |
| 4 | 카드 표시 방식 설정 | C1+C2+C3 | UserSettings `showFaceUp` + SettingsPage SwitchListTile + Level 2 분기 + CardRevealWidget fix | **커버** |
| 5 | 덱 종류 선택 | C1+C2 | UserSettings `selectedDeckId` + SettingsPage DropdownButtonFormField + 홈 허브 "덱 선택" 카드 | **커버** |
| 6 | 리딩 저장 | C2+C3 | ReadingPage `_autoSave()` + InstantDrawPage `_autoSave()` + AnimatedDrawPage `_autoSave()` | **커버** |
| 7 | 리딩 메모 | C2 | ReadingDetailPage TextField + 500ms debounce → updateNotes() | **커버** |
| 8 | 리딩 목록 | C2 | ReadingListPage + FilterChip spreadType 필터 + 빈 목록 메시지 | **커버** |
| 9 | 설정 메뉴 | C2+C3 | SettingsPage 6개 항목 + 홈 허브 "설정" 카드 → `/settings` 네비게이션 | **커버** |
| 10 | 한 장 더 뽑기 | C2+C3 | ReadingPage/InstantDrawPage/AnimatedDrawPage `_addOneMore()` + FAB + DB addDrawnCard | **커버** |

**10/10 In Scope 항목 전량 커버.**

### Cross-Cycle Consistency (인계 정합성)

| 인계 포인트 | From → To | 정합성 |
|-----------|----------|--------|
| UserSettings 엔티티 + Provider | C1 → C2, C3 | SettingsPage, 홈 redirect, Level 1/2 모두 `userSettingsProvider` 정상 사용 |
| SpreadType.custom + resolvePositions/Guidances | C1 → C2, C3 | ReadingPage, InstantDrawPage, AnimatedDrawPage에서 dynamic card count 처리 |
| DeckMetadata.supportedDrawModes | C1 → (향후) | 구조 준비 완료. 현재 덱 선택 시 직접 참조하지 않으나, 데이터 모델 ready |
| 설정 라우트 (/settings, /readings) | C2 → C3 | 홈 허브에서 `context.pushNamed('settings')`, `context.pushNamed('readings')` 연결 확인 |
| 자동 저장 패턴 (_autoSave + _autoSaved flag) | C2 → C3 | Level 1/2가 동일 패턴으로 자동 저장 구현. Reading 엔티티 생성 → saveReading 호출 |
| "+1 한 장 더" 패턴 | C2 → C3 | Level 1/2가 동일 패턴으로 _addOneMore + addDrawnCard + FAB 조건부 표시 구현 |
| showFaceUp 적용 | C2 fix(264b181) → C3 | Level 2의 `_showFaceUp` 분기가 CardRevealWidget fix와 정합 |
| Cycle 1-2 기존 라우트 보존 | C1, C2 → C3 | app_router.dart에 기존 7개 라우트 전량 보존 + C3 신규 2개 추가 (git diff 확인) |

**전 인계 포인트 정상.**

### Eval Finding Resolution (Cycle 1/2 발견사항 해소 현황)

| ID | 발견 | 해소 사이클 | 해소 방법 | 최종 상태 |
|----|------|-----------|----------|----------|
| **EV-006-D1** | userSettingsProvider AutoDispose → GoRouter lifecycle 주의 | C3 | Plan(010) D-010-1에서 분석: GoRouter provider가 `ref.watch`하면 앱 수명 동안 구독 유지. Verify(011)에서 동작 확인 | **해소** |
| **EV-006-D2** | _ensureDefaultRow autoIncrement 다중 행 가능성 | C2 | 모든 update가 `id.equals(1)` 패턴. 다중 행 존재해도 기능 문제 없음 | **허용된 리스크** |
| **EV-006-A1** | SpreadType.custom cardCount=0 sentinel 전파 위험 | C2 | `_currentCardCount = defaultCardCount ?? 3` fallback으로 0 sentinel 직접 미사용 | **해소** |
| **EV-006-A2** | DeckMetadata supportedDrawModes 확장성 | — | 현 2개 덱에서 동작. 향후 덱 다양화 시 확장 필요 | **허용된 리스크 (현 scope 밖)** |
| **EV-006-S1** | resolvePositions 매 빌드 호출 오버헤드 | — | 성능 영향 무시 가능 | **허용 (경미)** |
| **EV-009-D1** | ReadingDetailPage 전체 리딩 로딩 + where 필터 | — | 별도 최적화는 차기 과제 | **Deferred (경미)** |
| **EV-009-D2** | _autoSave가 build에서 호출 | — | 기능 문제 없음. 관례 위반이나 차단 사유 아님 | **허용 (경미)** |
| **EV-009-A1** | DropdownButtonFormField initialValue vs value | — | 기능 차이 없음 확인 | **해소 (문제 아님)** |
| **EV-009-A2** | Level 1/2에서 question 전달 경로 | C3 | Plan(010) D-010-3에서 해결: Level 1은 접힌 optional TextField, Level 2는 셔플 전 질문 입력 + skip 버튼 | **해소** |
| **EV-009-S1** | 자동 저장 전환 → 리딩 삭제 기능 미구현 | — | Brief In Scope에 미포함. 향후 과제 | **Deferred (scope 밖)** |

**10개 발견사항 중**: 해소 5건, 허용된 리스크 3건, Deferred 2건 (모두 scope 밖 또는 경미).

### Overall Quality 평가

**아키텍처 일관성:**
- 3사이클 모두 Riverpod + GoRouter + Freezed + Drift 패턴 일관 유지
- 각 사이클이 Bottom-Up 순서(데이터 → 기능 → 통합)를 정확히 따름
- 전 사이클 합산 36개 파일 변경(소스 + codegen), scope drift 0건

**코드 품질:**
- 3회 `dart analyze` 모두 0건
- codegen 정상 실행 3회
- 기존 기능 regression 0건 (각 Verify에서 확인)

**누락 사항:**
- Brief In Scope 10개 전량 커버
- Brief Out of Scope 5개 전량 미침범
- Model Anchor 8개 전량 충족

### 종료 판단

**핵심 질문: "scope의 intent가 충족되었는가?"**

Intent: "메인 메뉴 허브 → 3단계 체험 레벨 → 즉시 뽑기. 1~10장 자유 + 덱별 고유 뽑기 + 한 장 더. 설정은 UserSettings DB"

- 메인 메뉴 허브: 4개 기능 카드 GridView로 구현 (**충족**)
- 3단계 체험 레벨: Level 1/2/3 라우트 + redirect 분기 (**충족**)
- 즉시 뽑기: quickDrawEnabled + experienceLevel 기반 redirect (**충족**)
- 1~10장 자유: defaultCardCount Slider + SpreadType.custom (**충족**)
- 덱별 고유 뽑기: DeckMetadata.supportedDrawModes 구조 준비 (**충족 — 구조 Ready, 콘텐츠는 Out of Scope**)
- 한 장 더: 3개 페이지 모두 "+1" FAB + DB 반영 (**충족**)
- 설정 UserSettings DB: Drift 테이블 + DAO + Repository + Provider + SettingsPage (**충족**)

**Intent 달성률: 100%**

| 종료 유형 | 조건 | 판단 |
|----------|------|------|
| **정상 종료** | Depth Score 10+ + 잔여 사이클 없음 | **해당** — Depth Score 11, 3/3 사이클 완료, 잔여 없음 |

**`terminate: true`**

### 대안 검토

- **adjust 고려**: T-score가 2이나, 3회 Verify 모두 수동 전수 검증 수행. 자동화 trace 부재가 유일한 감점 요인이며, 3사이클 합산 29/29 검증 기준 통과(F-008-01은 gate 수정 후 통과). 추가 사이클 불필요.
- **deepen 고려**: 해당 없음. 모든 차원 2점 이상, critical issue 0건.

## 6. 권고사항

### Verdict: PROCEED

### 체크리스트 변경 권고

```yaml
recommended_changes: []
```

파이프라인 정상 종료. 추가 사이클, 재작업, scope 수정 불필요.

### 향후 개선 후보 (이 파이프라인 scope 밖)

1. **리딩 삭제 UI** (EV-009-S1): 자동 저장으로 모든 리딩이 쌓이므로, 리딩 목록에서 스와이프 삭제 또는 삭제 버튼 추가
2. **draw_providers 리팩터링** (EV-012-D1): executeDrawProvider에 seedRwsDeck을 통합하여 Level 1/2 인라인 로직 중복 제거
3. **_autoSave 위치 개선** (EV-012-D2/EV-009-D2): build() 내 side-effect를 addPostFrameCallback으로 이동
4. **"+1" 카드 애니메이션** (EV-012-D3): Level 2에서 추가 카드에도 슬라이드 애니메이션 적용
5. **ReadingDetailPage 쿼리 최적화** (EV-009-D1): getReadingByIdProvider 도입으로 전체 목록 로딩 회피
6. **quickDrawEnabled 초기 로딩 지연** (EV-012-A1): 앱 시작 시 splash/loading 화면에서 UserSettings 프리로드 후 redirect 판단

### 파이프라인 산출물 총괄

| # | 문서 | 유형 | 사이클 |
|---|------|------|--------|
| 001 | Brief_mobile_ui_overhaul | Brief | — |
| 002 | Scope_mobile_ui_overhaul | Scope | — |
| 003 | Research_data_foundation | Research | 1 |
| 004 | Plan_data_foundation | Plan | 1 |
| 005 | Verify_data_foundation | Verify | 1 |
| 006 | Eval_Cycle_1 | Eval | 1 |
| 007 | Plan_settings_reading | Plan | 2 |
| 008 | Verify_settings_reading | Verify | 2 |
| 009 | Eval_Cycle_2 | Eval | 2 |
| 010 | Plan_home_draw | Plan | 3 |
| 011 | Verify_home_draw | Verify | 3 |
| 012 | Eval_Cycle_3 | Eval | 3 (FINAL) |

**커밋 이력:**

| 커밋 | 사이클 | 설명 |
|------|--------|------|
| 1efbd5e | 1 | feat: Cycle 1 데이터 기반 |
| deca30a | 2 | feat: Cycle 2 설정 + 리딩 기능 |
| 264b181 | 2 fix | fix: CardRevealWidget showFaceUp |
| da5ed20 | 3 | feat: Cycle 3 홈 허브 + 뽑기 체험 |

---

```
== Eval: Cycle 3 (FINAL) Complete ==
Depth Score: 11/12 (V:3 U:3 D:3 T:2)
Critical gate: PASS
Verdict: PROCEED
Persona: default
Findings: D:3 C:0 A:1 S:2 (6건)
Terminate: true (정상 종료 — 3/3 사이클 완료, Intent 100% 달성)
Document: docs/20_mobile_ui_overhaul/012_Eval_Cycle_3.md
```

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
