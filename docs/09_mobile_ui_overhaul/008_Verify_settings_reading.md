---
id: "008"
type: verify
title: "Cycle 2 설정 + 리딩 기능 검증"
created: 2026-03-22
traces_plan: "007"
traces_scope: "002"
traces_brief: "001"
cycle: 2
commit: deca30a
status: pass-with-findings
summary: >
  dart analyze 0건. Plan(007)의 9개 검증 기준 중 8개 PASS, 1개 FINDING(showFaceUp).
  11파일 변경 (신규 4 + 수정 7), codegen 정상, 라우트 3개 등록 확인.
  showFaceUp 설정이 CardRevealWidget의 initState 미처리로 인해 실질적으로 미동작.
keywords: [verify, cycle-2, settings, reading, auto-save, incremental-draw]
---

# Cycle 2 검증 보고서 — 설정 + 리딩 기능

## 검증 환경

| 항목 | 값 |
|------|---|
| 대상 커밋 | `deca30a` |
| 변경 파일 | 11개 (신규 4, 수정 5, codegen 2) |
| dart analyze | **0 issues** |
| Plan 대조 | 007_Plan_settings_reading.md |

## 검증 기준별 결과

| # | 기준 | 결과 | 근거 |
|---|------|------|------|
| 1 | 설정 페이지 — 모든 설정 항목 표시 + DB 저장 | **PASS** | `settings_page.dart`: 덱(DropdownButtonFormField), 체험레벨(SegmentedButton), 카드수(Slider 1~10), 앞면/뒷면(SwitchListTile), 즉시뽑기(SwitchListTile), 스프레드(DropdownButtonFormField) 전부 구현. 각 onChanged에서 `userSettingsRepositoryProvider`의 개별 update 메서드 호출 확인 |
| 2 | 리딩 목록 — SpreadType 필터 동작 | **PASS** | `reading_list_page.dart`: FilterChip으로 null(전체) 또는 SpreadType 선택. `_filterType == null`이면 `watchReadingsProvider`, 아니면 `watchReadingsBySpreadTypeProvider(_filterType!)` 사용. DB-level 쿼리 필터 |
| 3 | 리딩 상세 — notes 인라인 편집 + 500ms debounce 자동 저장 | **PASS** | `reading_detail_page.dart`: `_onNotesChanged()` → `Timer(500ms)` → `readingRepositoryProvider.updateNotes()`. mounted 체크, debounce cancel, 저장 상태 UI("저장 중..." / "자동 저장됨") 구현 |
| 4 | ReadingPage 자동 저장 (allRevealed 시) | **PASS** | `reading_page.dart:140`: `if (allRevealed) _autoSave(drawnCards, question)`. `_autoSaved` 플래그로 중복 방지. `_savedReadingId` 보존으로 "+1" 시 기존 Reading에 카드 추가 가능 |
| 5 | "+1 한 장 더" FAB — 카드 append + Reading 갱신 | **PASS** | `_addOneMore()`: `_currentCardCount++` → `readingRepositoryProvider.addDrawnCard()`. FAB는 `allRevealed && hasMoreCards` 조건 충족 시만 표시 |
| 6 | showFaceUp 설정 → 카드 초기 reveal 상태 적용 | **FINDING** | 아래 상세 참조 |
| 7 | 3개 라우트 등록 | **PASS** | `app_router.dart`: `/settings`(name: settings), `/readings`(name: readings), `/readings/:readingId`(name: reading-detail) 등록. import 3개 추가 |
| 8 | dart analyze 에러 0건 | **PASS** | `dart analyze lib/` → "No issues found!" |
| 9 | Cycle 1 기능 회귀 없음 | **PASS** | Cycle 1 파일(settings_providers, user_settings entity, user_settings_repository, user_settings_repository_impl) 미변경. reading_dao/repository에 메서드 추가만 수행(기존 메서드 미수정). SpreadType enum 미변경 |

## FINDING: showFaceUp 설정 미동작 (F-008-01)

**심각도**: Medium (UX 결함, 런타임 에러 아님)

**현상**: `UserSettings.showFaceUp = true` 설정 후 ReadingPage 진입 시, 카드가 뒷면으로 표시됨 (기대: 앞면).

**원인 경로**:

1. `reading_page.dart:131-134`: `showFaceUp`이 true이면 `_revealedPositions`에 모든 위치를 추가 — **정상**
2. `spread_layout.dart:39`: `isRevealed: revealedPositions.contains(i)` → true 전달 — **정상**
3. `card_reveal_widget.dart:34`: `_showFront = false`로 초기화 — **문제 지점**
4. `card_reveal_widget.dart:52-57`: `didUpdateWidget`은 `isRevealed`가 false→true로 **변경**될 때만 애니메이션 시작. 위젯이 `isRevealed: true`로 **생성**되면 트리거 안 됨
5. 결과: 카드가 `_showFront = false` 상태로 남아 뒷면 표시

**Plan(007) 대조**: Step 5 파일 변경 요약에서 `card_reveal_widget.dart`를 "(조건부) — showFaceUp 시 초기 revealed 상태 지원 확인"으로 명시했으나, 실제 구현에서 수정 누락.

**수정 방향**:
```dart
// card_reveal_widget.dart initState에 추가:
if (widget.isRevealed) {
  _showFront = true;
  _controller.value = 1.0; // 애니메이션 스킵
}
```

## 상세 코드 검증

### 1. ReadingDao 확장 (Step 1-1)

- `updateNotes()`: `Value(notes)` + `Value(DateTime.now())` — Plan 일치
- `addDrawnCard()`: `into(drawnCards).insert(card)` + Reading.updatedAt 갱신 — Plan 일치
- `watchReadingsBySpreadType()`: `where((r) => r.spreadType.equals(spreadType))` + `orderBy desc(createdAt)` — Plan 일치

### 2. ReadingRepository 인터페이스 (Step 1-2)

4개 메서드 추가: `updateNotes`, `addDrawnCard`, `watchReadingsBySpreadType`, `getReadingById` — Plan 일치

### 3. ReadingRepositoryImpl (Step 1-3)

- `addDrawnCard()`: DrawnCardsCompanion.insert 패턴, ID 생성 `$readingId-${card.position}` — Plan 일치
- `watchReadingsBySpreadType()`: `asyncMap` + `Future.wait` 패턴 — Plan 일치
- `getReadingById()`: 전체 로딩 후 `where` 필터 — Plan과 동일 (최적화 여지 있으나 현 단계 OK)

### 4. ReadingProviders (Step 1-4)

`watchReadingsBySpreadType` family provider 추가 — Plan 일치. codegen 결과(`reading_providers.g.dart`)에 `WatchReadingsBySpreadTypeFamily` + `WatchReadingsBySpreadTypeProvider` 정상 생성

### 5. SettingsPage (Step 2)

- 6개 설정 항목 전부 구현
- `DropdownButtonFormField`에서 `initialValue:` 사용 (Plan은 `value:` 명시). FormField의 `initialValue` 파라미터 사용으로 dart analyze 통과. `settingsAsync` watch로 rebuild 시 새 위젯 생성되므로 기능적 차이 없음
- EV-006-D2 반영: 모든 update가 `userSettingsRepositoryProvider` 경유 → DAO에서 `id.equals(1)` 패턴 유지

### 6. ReadingListPage (Step 3)

- FilterChip: 전체(null) + SpreadType.values 순회 — Plan 일치
- 토글 해제: 같은 칩 재선택 시 `_filterType = null` — Plan 일치
- 빈 목록 메시지: 필터 유무에 따라 분기 — Plan 일치
- `context.pushNamed('reading-detail', pathParameters: ...)` — 라우터 name과 일치

### 7. ReadingDetailPage (Step 4)

- notes 초기화: `_initialized` 플래그로 1회만 — Plan 일치
- debounce: `Timer(500ms)` + `mounted` 체크 — Plan 일치
- 저장 상태: AppBar 아이콘(spinner/check) + 하단 텍스트 — Plan 일치
- `watchReadingsProvider` 전체 로딩 후 `where` 필터 — Plan 인지(리스크 #4)

### 8. ReadingPage 변경 (Step 5)

- 자동 저장: `_autoSaved` 플래그 + `_savedReadingId` — Plan 일치
- "+1": `_currentCardCount++` + `addDrawnCard()` — Plan 일치
- FAB 비활성화: `_currentCardCount >= shuffleResult.cards.length` 시 FAB null — Plan 일치
- EV-006-A1: custom일 때 `defaultCardCount ?? 3` fallback — Plan 일치
- showFaceUp: `_revealedPositions` 추가 로직 정상, but `CardRevealWidget`에서 미반영 (F-008-01)

### 9. 라우트 (Step 6)

3개 라우트 + import 3개 추가 — Plan 일치. `_fadePage` transition 적용

## Edge Case 검증

| Edge Case | 결과 | 근거 |
|-----------|------|------|
| 덱 카드 소진 시 FAB 비활성화 | **OK** | `hasMoreCards = _currentCardCount < shuffleResult.cards.length`. false이면 FAB null |
| 자동 저장 중복 방지 | **OK** | `_autoSaved` 플래그. build 재실행 시에도 `if (_autoSaved) return;`으로 스킵 |
| "+1" 후 새 카드 showFaceUp 적용 | **부분** | `_addOneMore()`에서 `showFaceUp` 체크 후 `_revealedPositions.add()` — 로직은 정상이나 F-008-01로 인해 실질적 미동작 |
| notes debounce 중 페이지 이탈 | **OK** | `dispose()`에서 `_debounce?.cancel()`. Plan 리스크 #3 인지 |
| SpreadType.custom.cardCount == 0 sentinel | **OK** | `_currentCardCount` 초기화 시 `defaultCardCount` 사용, sentinel 직접 미사용 |

## Verdict

**PASS with findings**. 핵심 기능(설정 페이지, 리딩 목록/상세, 자동 저장, "+1 뽑기", 라우트 등록)은 Plan 대비 정합성 확보. dart analyze 0건. Cycle 1 회귀 없음.

showFaceUp 미동작(F-008-01)은 `CardRevealWidget.initState`에서 초기 `isRevealed` 상태 미처리가 원인. Cycle 3에서 수정하거나, 별도 hotfix 커밋으로 해결 가능 (2줄 수정).

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
