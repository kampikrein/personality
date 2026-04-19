---
id: "077"
type: push
title: "Push — 뽑기 결과 페이지 통일 (unified_result_page)"
created: 2026-04-14
traces_brief: "065"
traces_scope: "066"
traces_eval: "075"
traces_qualify: "076"
output: "fbe2e96a94211aeae97f52ab64a1b9106282d183"
summary: >
  Qualify 076의 Push Criteria P-1(Must)과 P-2(Should)를 자동 수정으로 완료.
  _goToReading → _goToDrawResult 리네임 + try/catch 안전 이탈 도입. 단일 커밋(fbe2e96).
  flutter analyze clean(error 0), flutter test 15/15 PASS, flutter build apk --debug 성공.
  P-3~P-6 수동 E2E는 사용자 실행용 체크리스트로 본 문서에 보존. P-7(Lv3 deferred)·P-8(MA-8 제외) 기록.
---

# Push — 뽑기 결과 페이지 통일 (unified_result_page)

## 0. 요지

| 관점 | 결과 |
|------|------|
| Critic findings | 2 minor (자동 수정 가능), 4 manual (수동 관찰만), 2 deferred |
| Main auto-fixes | 1 commit (`fbe2e96`) — P-1 + P-2 동시 처리 |
| Writer summary | **완료**. Must/Should 자동 수정 종결, manual/deferred는 사용자 후속 |
| Build | PASS (`flutter build apk --debug`) |
| Tests | 15/15 PASS (regression 0) |

---

## 1. Critic Findings (독립 재검증)

Qualify 076 Push Criteria P-1..P-8 + Minor Hygiene H1/H2를 현 코드에 대해 독립 검증했다.

### P-1 (Must) — `_goToReading` 메서드명 leftover
- **severity**: minor (기능 영향 없음, 이름=진실 위반)
- **evidence (수정 전)**: `mobile/lib/features/shuffle/presentation/pages/shuffle_page.dart:52, 164`
- **verdict**: fail → **자동 수정 가능**

### P-2 (Should) — `_goToReading` unguarded async
- **severity**: minor (크래시 가능성 낮지만 예외 복구 명시 없음)
- **evidence (수정 전)**: 함수 본문에 try/catch 없음. `deckCardsProvider(widget.deckId).future`와 `useCase.execute`가 unguarded.
- **verdict**: fail → **자동 수정 가능**

### P-3 Lv1 수동 E2E, P-4 Lv2 수동 E2E, P-5 Lv4 수동 E2E, P-6 뒤로가기 UX
- **severity**: manual (코드 기반 검증 불가)
- **verdict**: 사용자 수동 실행 필요 — §4 체크리스트로 보존

### P-7 — IC #14 Lv3 Shuffle2dPage 참조
- **severity**: deferred (Brief 064 후속 Brief 작성 시점 검증)
- **verdict**: 본 push 범위 외 — §5 기록

### P-8 — H2 "즉시" AppBar 텍스트
- **severity**: out-of-scope (Brief 065 MA-8 "DrawResultPage 내부 UI 변경 금지")
- **evidence**: `draw_result_page.dart:216, 223, 233`
- **verdict**: 수정 금지 — §5 기록. 별도 Brief로 분리.

### H2 보충 critic 관찰 — home_page "즉시" 재확인
- `home_page.dart:68, 72`의 `'즉시'` 문자열은 **Lv1 모드명** (level name)이며 DrawResultPage 내부 문구가 아니다. 이는 UX 정합성 문제가 아닌 정상적 네이밍.
- H2의 실제 불일치 지점은 `draw_result_page.dart` 내부뿐이며 MA-8에 의해 수정 금지 확인. critic 동의.

---

## 2. Main Responses (자동 수정 구현)

### M-1. 단일 커밋으로 P-1 + P-2 동시 처리

**커밋 SHA**: `fbe2e96a94211aeae97f52ab64a1b9106282d183`
**메시지**: `chore(draw): rename _goToReading and guard navigation (quality push)`
**파일**: `mobile/lib/features/shuffle/presentation/pages/shuffle_page.dart` (1 file, +23/-14)

### 변경 1 — 메서드명 리네임 (P-1)
```diff
- Future<void> _goToReading() async {
+ Future<void> _goToDrawResult() async {
...
- onPressed: _goToReading,
+ onPressed: _goToDrawResult,
```

### 변경 2 — try/catch 안전 이탈 (P-2)
```dart
try {
  // 덱 카드 로드 + 셔플 실행
  final cards = await ref.read(deckCardsProvider(widget.deckId).future);
  final useCase = ref.read(shuffleDeckUseCaseProvider);
  final strategy = ref.read(shuffleStrategyProvider);
  final result = useCase.execute(cards: cards, strategy: strategy);
  ref.read(shuffleStateProvider.notifier).setResult(result);

  if (!mounted) return;
  context.pushReplacementNamed(
    'draw-result',
    pathParameters: {'deckId': widget.deckId},
  );
} catch (e) {
  // [예외 복구] 덱 로드/셔플 실패 시 크래시 대신 안전 이탈 (QG-075-2 P-2).
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('뽑기를 시작할 수 없습니다: $e')),
  );
  context.go('/');
}
```

### 검증

| 검증 항목 | 명령 | 결과 |
|----------|------|------|
| P-1 측정식 | `grep -rn "_goToReading" mobile/lib` | **0 hits** (PASS) |
| P-2 측정식 | 함수 내 `try` 블록 존재 | **존재** (PASS) |
| `flutter analyze` | - | 5 info, 0 warning/error (기존 info 모두 본 push 수정과 무관) |
| `flutter test` | 전체 15개 | **15/15 PASS** |
| `flutter build apk --debug` | - | **PASS** (`app-debug.apk` 생성) |
| 회귀 테스트 | `shuffle_page_navigation_test.dart` | **2/2 PASS** (C1, C2 모두 유효) |

---

## 3. Writer Summary

**최종 상태**: Must + Should 자동 수정 종결. manual 4건 + deferred 2건은 본 문서에 보존.

| Push Criteria | 상태 | 근거 |
|---------------|------|------|
| P-1 (Must) | **DONE** | 커밋 `fbe2e96`. grep 0 hits 확인. |
| P-2 (Should) | **DONE** | try/catch + `context.go('/')` fallback 구현. |
| P-3 Lv1 E2E | **MANUAL PENDING** | §4.1 체크리스트 6단계 사용자 실행 대기 |
| P-4 Lv2 E2E | **MANUAL PENDING** | §4.2 체크리스트 + QG-075-1 관찰 |
| P-5 Lv4 E2E | **MANUAL PENDING** | §4.4 체크리스트 + QG-075-3 관찰 |
| P-6 뒤로가기 UX | **MANUAL PENDING** | §4.5 Android 뒤로가기 시나리오 |
| P-7 Lv3 Shuffle2dPage | **DEFERRED** | Brief 064 후속 Brief 시점 검증. 본 077이 앵커 문서. |
| P-8 H2 "즉시" 문구 | **DEFERRED** | Brief MA-8 위반. 별도 Brief 분리 대상. |

**Push 성공 판정**: Must 전부 PASS, Should 1건 PASS, 수동 4건은 사용자 이관. **판정 PASS.**

---

## 4. Manual E2E Checklist (사용자 실행용 — 076에서 복사 보존)

### 사전 조건

- ADB 연결된 에뮬레이터 또는 실기기.
- 본 push 커밋 `fbe2e96` 포함 `flutter build apk --debug` 설치.
- 기존 reading_list 상태 무관.

### 4.1. Lv1 — 즉시 뽑기 (P-3)

1. [ ] 홈 진입 → 체험 레벨 `즉시` 선택
2. [ ] "바로 뽑기" 탭 → 라우트가 `/draw/result`로 이동 (URL 로그 확인)
3. [ ] DrawResultPage 진입 → 자체 셔플 실행 → 카드 N장 즉시 reveal
4. [ ] auto-save 동작 (`_savedReadingId` 생성). 저장 완료 토스트/인디케이터 (있다면)
5. [ ] 하단 `reading_list`로 이동 → 가장 최근 Reading 항목 존재, createdAt이 방금 시각
6. [ ] 해당 Reading 항목 탭 → reading_detail 진입 → 카드·질문 복원

### 4.2. Lv2 — 연출 뽑기 (P-4 + QG-075-1)

1. [ ] 홈 → 체험 레벨 `연출` 선택 → AnimatedDrawPage 진입
2. [ ] 질문 입력(선택) + "뽑기" 탭 → 연출 애니메이션 재생
3. [ ] 연출 종료 → 자동으로 DrawResultPage 전환 (`pushReplacement`)
4. [ ] DrawResultPage에서 카드 동일 집합, **재애니메이션 없음**, **배경 flash 없음**, **질문 텍스트 소실 없음** (QG-075-1 3회 반복 관찰)
5. [ ] reading_list에서 새 항목 확인
6. [ ] reading_detail에서 카드/질문 복원 확인

### 4.3. Lv3 — 2D 셔플 (**현재 미구현 — 규약만 확인**)

1. [ ] 홈 → 체험 레벨 `2D` 선택 → (구현되면) Shuffle2dPage 진입
2. [ ] 카드 선택 → `pushReplacementNamed('draw-result', pathParameters: {'deckId': ...})` 호출 확인
3. [ ] DrawResultPage 진입 → `_reuseUpstreamResult=true` 경로
4. [ ] auto-save 동작
5. [ ] reading_list 새 항목
6. [ ] reading_detail 복원

**현재 상태**: Lv3 Shuffle2dPage 미구현 → Brief 064 후속 구현 시 실행.

### 4.4. Lv4 — 2.5D 셔플 (P-5 + QG-075-3)

1. [ ] 홈 → 체험 레벨 `2.5D` 선택 → IntentionPage 진입
2. [ ] 질문 입력 → "다음" → ShufflePage(Lv4, Forge2D) 진입
3. [ ] 셔플 후 "뽑기" 탭 → DrawResultPage 전환 (`pushReplacementNamed('draw-result')`)
4. [ ] DrawResultPage에서 동일 카드 집합, auto-save 동작 (QG-075-2 센서 정상 경로 관찰, QG-075-3 백그라운드 복귀 관찰)
5. [ ] reading_list에서 새 항목
6. [ ] reading_detail에서 카드/질문 복원

### 4.5. 뒤로가기 UX 검증 (P-6 / IC #13)

- [ ] Lv2 완료 → DrawResultPage → Android 뒤로가기 → **홈**으로 복귀 (연출 페이지 재생 없음)
- [ ] Lv4 완료 → DrawResultPage → Android 뒤로가기 → **홈**으로 복귀 (ShufflePage 재진입 없음)

### 4.6. 백그라운드 복귀 검증 (IC #22, QG-075-3)

- [ ] Lv2 DrawResultPage 진입 → 홈 버튼(OS) → 2초 → 앱 아이콘 재탭 → DrawResultPage 그대로, 카드 재셔플 없음
- [ ] Lv4 동일 시나리오 반복

### 4.7. 예외 경로 (IC #12, QG-075-2 — P-2 구현 검증)

- [ ] 존재하지 않는 deckId 또는 덱 파일 없는 상태에서 Lv4 진입 → 크래시 대신 로딩 인디케이터 유지 또는 "뽑기를 시작할 수 없습니다" 스낵바 후 홈 복귀 (본 push P-2로 구현됨)
- [ ] ShufflePage에서 "뽑기" 탭 시점의 네트워크/DB 실패 재현 → 크래시 없이 스낵바 또는 홈 복귀

---

## 5. Deferred Items

### D-1. Lv3 Shuffle2dPage (Brief 064 의존 — P-7 / IC #14)

- **상태**: deferred
- **조건**: Brief 064 후속 Brief가 작성되고 Shuffle2dPage가 구현되면 §4.3 체크리스트 실행 + MA-5(`named route 'draw-result'`) 참조 확인.
- **앵커 문서**: 본 077 + Qualify 076 §5.3 P-7.

### D-2. H2 "즉시" AppBar 텍스트 정합성 (P-8 / MA-8)

- **상태**: out-of-scope, 별도 Brief 필요
- **현재 상태**: `draw_result_page.dart:216, 223, 233` `"즉시 뽑기"` / `"${_spreadType.displayName} — 즉시"` 잔존
- **영향**: Lv2~Lv4 경유 진입 시에도 "즉시" 뉘앙스 노출 → UX 인식 오차 (minor)
- **사유**: Brief 065 MA-8 "DrawResultPage 내부 UI 재디자인 금지" 에 의해 본 Brief 범위 외
- **후속 Brief 시 참조**: 077 §5 D-2, 076 §3 QG-075-6, 076 §5.3 P-8

---

## 6. Minor Hygiene Status

| ID | 위치 | 원 내용 | 본 push 처리 | 상태 |
|----|------|---------|------------|------|
| H1 | `shuffle_page.dart:52, 164` | `_goToReading` leftover | **자동 수정** (P-1 커밋 `fbe2e96`) | **완료** |
| H2 | `draw_result_page.dart:216, 223, 233` | `"즉시"` 뉘앙스 AppBar | **미조치** (MA-8 위반 — 별도 Brief 분리) | **deferred** |

---

## 7. Trace

- **Brief**: `docs/03_tarot_shuffle/065_Brief_unified_result_page.md`
- **Scope**: `docs/03_tarot_shuffle/066_Scope_unified_result_page.md`
- **Eval**: `docs/03_tarot_shuffle/075_Eval_Cycle_2.md`
- **Qualify**: `docs/03_tarot_shuffle/076_Qualify_unified_result_page.md`
- **Verify**: `docs/03_tarot_shuffle/070_Verify_rename_cycle1.md`, `074_Verify_flow_cycle2.md`
- **Impl**: `docs/03_tarot_shuffle/069_Impl_rename_cycle1.md`, `073_Impl_flow_cycle2.md`
- **Push commit**: `fbe2e96a94211aeae97f52ab64a1b9106282d183`

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
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 387s |
| Total Tokens | 24870 |
| Input Tokens | 3 |
| Output Tokens | 69 |
| Cache Read | 0 |
| Cache Creation | 24798 |
