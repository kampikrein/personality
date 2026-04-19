---
id: "076"
type: qualify
title: "Qualify — 뽑기 결과 페이지 통일 (unified_result_page)"
created: 2026-04-14
eval_verdict: proceed
gaps_total: 6
gaps_pushable: 2
traces_brief: "065"
traces_eval: "075"
summary: >
  Eval 075(verdict proceed, intent coverage full, 0 red flag)가 구조적 완결을 선언.
  Brief 26 IC 중 21건이 자동·정적 검증 완료, 5건(IC #9/#12/#22 directional,
  IC #26 manual E2E, IC #14 deferred)이 qualify 책임으로 이관됨.
  Minor hygiene 2건(`_goToReading` 잔존 메서드명, AppBar "즉시" 텍스트 Lv2~4 불일치) 포함.
  Push 단계로 측정 가능한 기준 8개 + 수동 E2E 체크리스트(Lv1~Lv4 × 6 단계) 전달.
---

# Qualify — 뽑기 결과 페이지 통일 (unified_result_page)

## 0. Track 중재 요지

- **Track 1 (Eval 075)**: verdict **proceed**, depth 9, intent coverage **full**, red flag 0.
  코드·라우트·문서 레벨에서 Brief 065의 8/8 Decisions, 9/9 MA, 8/8 In Scope 수렴 확인.
- **Track 2 (Brief 065 Ideal Criteria 26개)**: 21건은 eval 자동/정적 PASS, 5건은 수동/정성 영역.
- **Qualify 중재 결과**: structural gap 없음. directional 5건을 측정 가능한 기준으로 구체화하고,
  minor hygiene 2건을 push 선택 범위로 승격. 조정(adjust) 필요 항목 0건, 드롭(drop) 0건.

---

## 1. Track 1 현재 상태 (Eval 075 기반)

### 1.1 자동 검증 완료 (20건 assertion PASS)

IC #1, #2, #3, #4, #5, #6, #7, #8, #10, #11, #13, #15, #16, #17, #18, #19, #20, #21, #23, #24.

- 리네임 원자성 4건(C1, #1~#4) — Verify 070 PASS.
- 업스트림 규약 / initState 분기 / 테스트 격리 7건 — Verify 074 PASS + Eval RF-1 재확인.
- AnimatedDrawPage 축소 2건(#8, #10) — Verify 074 PASS (`−113` 라인).
- ShufflePage 후단·Lv3/Lv4 상수 공유 3건(#11, #13, #15) — 074 정적 PASS.
- ReadingPage 제거 · analyze · addOneMore 동치 · backward compat 4건(#16~#19) — 074 PASS.

### 1.2 정적 검증 완료 (1건 directional PASS)

- **IC #25** (딥링크 호환 전략 문서화) — Brief Constraints + Scope R5에서 "외부 진입점 없음" 명시.

### 1.3 Pending (5건)

| IC | Type | 상태 | Track 1 상태 |
|----|------|------|--------------|
| #9 | directional, UX | 수동 관찰 필요 | 연출 종료 → DrawResultPage 전환 시 깜빡임·재애니메이션 없음 — `pushReplacementNamed('draw-result')` 정적 검증만 완료 |
| #12 | directional, Robustness | 수동 관찰 필요 | 센서/Forge2D 예외 복구 — 현재 ShufflePage에 try/catch 미적용 |
| #22 | directional, Robustness | 수동 관찰 필요 | 백그라운드 복귀 시 `shuffleStateProvider` 보존 — Eval RF-1 정적 분석상 안전, 런타임 관찰 미수행 |
| #26 | assertion, manual | 수동 E2E | Lv1~Lv4 end-to-end 6단계 수동 |
| #14 | directional, Completeness | deferred | Brief 064 (Lv3 Shuffle2dPage) 후속 Brief가 MA-5 named route 참조해야 — 본 Brief 범위 외 |

### 1.4 Minor Hygiene (Eval 지적)

- **H1**: `mobile/lib/features/shuffle/presentation/pages/shuffle_page.dart:52` 메서드명 `_goToReading`.
  Cycle 2에서 타겟 라우트는 `draw-result`로 바꿨지만 메서드 식별자는 leftover. private 1회 호출(L164). 이름=진실 원칙 미세 위반.
- **H2**: `draw_result_page.dart:216/223/233` AppBar/버튼 텍스트 `"즉시 뽑기"` / `"${_spreadType.displayName} — 즉시"` — Lv2~Lv4 경유 진입 시에도 "즉시" 뉘앙스 표시.
  Brief MA-8("내부 UI 변경 금지")에 따라 본 qualify는 **기록만 하고 교정은 별도 Brief**로 분리.

---

## 2. Track 2 Refinement (Brief IC 26개 조정)

각 criterion의 조정 결과를 `pass-through | refine | adjust | drop`으로 분류.

| IC | Type | Dim | 조정 | 조정 사유 / 내용 |
|----|------|-----|------|-----------------|
| 1 | assertion | Function | **pass-through** | 자동 PASS. 측정식 유지: `grep -r "InstantDrawPage\|/draw/instant\|draw-instant" mobile/lib` = 0. |
| 2 | assertion | Robustness | **pass-through** | `flutter build apk --debug` 성공. 재빌드 측정 가능. |
| 3 | assertion | Completeness | **pass-through** | dartdoc L17-24 "Lv1~Lv4 공용 뽑기 결과 페이지" 명시 확인. |
| 4 | assertion | Robustness | **pass-through** | 회귀 없음 (074 Full suite 15/15). |
| 5 | assertion | Function | **pass-through** | `animated_draw_page.dart:87`, `shuffle_page.dart:64`, `intention_page.dart:120` setResult/set 존재. |
| 6 | assertion | Robustness | **pass-through** | `draw_result_page.dart:79-97` null fallback. |
| 7 | assertion | Edge | **pass-through** | Eval RF-1 clean. 업스트림 매 진입마다 clear+setResult. |
| 8 | assertion | Function | **pass-through** | grep 0 hits. |
| **9** | directional | UX | **refine** | 아래 QG-075-1에서 수동 관찰 시나리오로 구체화 (Lv2 연출 → DrawResultPage 전환 3회 반복 관찰). |
| 10 | assertion | Robustness | **pass-through** | leak 방지 확인 완료. |
| 11 | assertion | Function | **pass-through** | `pushReplacementNamed('draw-result', pathParameters: {'deckId': ...})` 확인. |
| **12** | directional | Robustness | **refine** | QG-075-2: Forge2D/센서 예외에 대한 **자동 테스트 불가능**(Forge2D는 실제 flame 런타임 필요) → 수동 시나리오 + 정적 코드 리뷰로 대체. ShufflePage 빌드 실패·덱 로드 실패 시 빈 화면/크래시 대신 안전 이탈하는지 확인. |
| 13 | assertion | UX | **pass-through** | pushReplacement 정적 검증. |
| **14** | directional | Completeness | **adjust → deferred** | Brief 064 후속 Brief가 MA-5 참조해야. 본 Brief 종결 시점에서 Lv3 Brief가 작성되지 않았으므로 **deferred 명시** — `docs/03_tarot_shuffle/065_Brief_unified_result_page.md` MA-5 및 본 076이 향후 Lv3 Brief/Scope가 참조할 앵커로 고정됨. push 단계에서는 평가하지 않는다. |
| 15 | assertion | Function | **pass-through** | 두 업스트림 모두 named route `'draw-result'` 사용. |
| 16 | assertion | Function | **pass-through** | `reading_page.dart` 파일 삭제, 라우트 삭제 확인. |
| 17 | assertion | Robustness | **pass-through** | `flutter analyze` unresolved import 0건. |
| 18 | assertion | Completeness | **refine** (수동 재현 필요) | 074가 정적 동치 확인. 수동 재현은 아래 E2E 체크리스트의 IC #26 단계에 포함 (3장 → 4장 추가 → 저장 → reading_detail). |
| 19 | assertion | Edge | **pass-through** | reading_list/detail 불변 (074 + backward compat 데이터 로드 확인). |
| 20 | assertion | Robustness | **pass-through** | `initState` L60-61 단일 평가, `_executeDraw` 소비만. |
| 21 | assertion | Edge | **pass-through** | `_initSettings`가 매 initState `ref.read(userSettingsProvider)` 호출. |
| **22** | directional | Robustness | **refine** | QG-075-3: 수동 시나리오 — Lv2/Lv4 경유 DrawResultPage 진입 직후 홈 버튼 → 2초 대기 → 복귀 시 카드·질문 동일하고 재셔플 발생 안 함 확인. |
| 23 | assertion | Robustness | **pass-through** | `ProviderContainer` override 테스트 작성 가능 확인. |
| 24 | assertion | Function | **pass-through** | `home_page.dart:36, 44`가 `/draw/result`로 교체됨. |
| 25 | directional | Completeness | **pass-through** | "외부 진입점 없음" 문서화로 충족. |
| **26** | assertion (manual) | Function | **refine** | 아래 E2E 체크리스트로 구체화. Lv1~Lv4 × (홈 → 진입 → 뽑기 → DrawResultPage 진입 → 저장 → reading_list 조회) 6단계. |

**집계**: pass-through 20, refine 5, adjust(→deferred) 1, drop 0.

---

## 3. Gap List (QG-075-N)

### QG-075-1 — IC #9 연출→DrawResultPage 시각적 연속성

| 항목 | 내용 |
|------|------|
| Criterion | 연출 종료 → DrawResultPage 전환 시 사용자가 보는 카드·질문이 끊김·재애니메이션·깜빡임 없이 이어진다 |
| 현재 상태 | `pushReplacementNamed('draw-result')` 정적 검증만 완료. Cycle 2 TDD Red 11/11 Green이지만 시각 관찰 미수행 |
| 목표 상태 | Lv2 홈→연출→DrawResultPage 왕복 3회 관찰, 각 회차에서 (a) 카드 뒤집기 재시작 없음 (b) 질문 텍스트 소실 없음 (c) 배경 flash 없음 |
| 측정 방법 | 수동 관찰 (E2E 체크리스트 Lv2 단계 병행). ADB 스크린샷 3컷(연출 마지막 프레임 / 전환 순간 / DrawResultPage 첫 프레임) 비교 |
| Push 가능 | **no** — 수동 UX 관찰 필요. push는 기준 통과 확인만 가능 (교정 작업 아님) |

### QG-075-2 — IC #12 센서/Forge2D 예외 복구

| 항목 | 내용 |
|------|------|
| Criterion | 카드 선택 도중 센서/Forge2D 예외 발생 시 앱이 크래시하지 않고 복구 가능하거나 안전하게 홈으로 이탈 |
| 현재 상태 | `shuffle_page.dart`에 명시적 try/catch 없음. `_loadDeckAndCreateGame`과 `_goToReading`이 각각 async unguarded. `TarotGame` (Forge2D) 내부는 flame runtime 책임 |
| 목표 상태 | (a) 덱 로드 실패 시 holders `_game == null` 상태 유지로 CircularProgressIndicator 표시 (현재 동작) (b) `_goToReading`의 셔플 실패 시 스택 트레이스 표시 대신 스낵바/홈 복귀 안내 |
| 측정 방법 | 자동 테스트 불가(flame 런타임 종속). 수동 시나리오 — (a) 존재하지 않는 deckId로 진입 (b) 네트워크 격리 상태에서 진입 각 1회. 크래시 없으면 PASS |
| Push 가능 | **partial yes** — `_goToReading`에 try/catch + 스낵바 추가는 코드 개선 가능 (push 범위). 센서 자체 예외는 flame 내부 |

### QG-075-3 — IC #22 백그라운드 복귀 시 상태 보존

| 항목 | 내용 |
|------|------|
| Criterion | Lv2/3/4 경로에서 DrawResultPage 진입 직전/직후 OS 백그라운드 전환 후 복귀 시 shuffleStateProvider 보존, 재셔플 발생 안 함 |
| 현재 상태 | Eval RF-1 정적 분석상 안전(`_reuseUpstreamResult` 1회 평가, OS 백그라운드는 state 유지). 런타임 관찰 미수행 |
| 목표 상태 | Lv2/Lv4 각 1회 수동 — (a) DrawResultPage 진입 (b) 홈 버튼 (c) 2초 대기 (d) 앱 재열기 → 카드/질문 동일하고 새로운 셔플 발생 안 함 |
| 측정 방법 | 수동 관찰. DrawResultPage의 카드 식별자(id) 비교. `debugPrint`를 `_executeDraw`에 임시 추가 후 복귀 시점에 호출 로그 0건 확인 |
| Push 가능 | **no** — 관찰만 가능. 현재 코드는 이미 목표 상태를 만족하는 설계 |

### QG-075-4 — IC #26 Lv1~Lv4 E2E 수동

| 항목 | 내용 |
|------|------|
| Criterion | Lv1~Lv4 전 모드에서 뽑기 → 저장 → reading_list 조회까지 end-to-end 성공 |
| 현재 상태 | 각 레벨의 라우트/업스트림/저장은 074에서 정적 PASS. 종합 흐름의 수동 재현 미수행 |
| 목표 상태 | 4레벨 모두 §4 체크리스트 통과 |
| 측정 방법 | §4 수동 E2E 체크리스트 |
| Push 가능 | **no** — 수동 실행 |

### QG-075-5 — H1 `_goToReading` 메서드명 leftover (Minor Hygiene)

| 항목 | 내용 |
|------|------|
| Criterion | 메서드명이 실제 타겟(draw-result)과 정합한다 — 이름=진실 원칙 |
| 현재 상태 | `shuffle_page.dart:52, 164`의 `_goToReading` 잔존. 라우트는 `draw-result`이지만 메서드명은 `Reading` |
| 목표 상태 | `_goToReading` → `_goToDrawResult` (또는 `_submitDraw` / `_proceedToResult`). private · 호출 1회 · 기능 영향 없음 |
| 측정 방법 | `grep -r "_goToReading" mobile/lib` = 0. `flutter build apk --debug` 성공 |
| Push 가능 | **yes** — 단일 파일 기계적 리네임 |

### QG-075-6 — H2 "즉시" 뉘앙스 AppBar 텍스트 (Brief 분리 대상)

| 항목 | 내용 |
|------|------|
| Criterion | DrawResultPage가 Lv2~Lv4 경유 진입 시에도 "즉시" 표시로 UX 인식 오차 발생 |
| 현재 상태 | `draw_result_page.dart:216` `'즉시 뽑기'`, `:223` 동일, `:233` `"${_spreadType.displayName} — 즉시"` |
| 목표 상태 | "뽑기 결과" 또는 모드별 분기 표시. 단 Brief MA-8("내부 UI 변경 금지")에 의해 본 Brief 범위 외 |
| 측정 방법 | N/A — 별도 Brief 분리 |
| Push 가능 | **no** — MA-8 위반. 본 qualify는 기록만 |

---

## 4. Manual E2E Checklist (IC #26)

### 사전 조건

- ADB 연결된 에뮬레이터 또는 실기기. `flutter build apk --debug` 성공 후 설치.
- 기존 reading_list는 초기 상태여도 무관(backward compat 별개 확인).

### Lv1 — 즉시 뽑기

1. [ ] 홈 진입 → 체험 레벨 `즉시` 선택
2. [ ] "바로 뽑기" 탭 → 라우트가 `/draw/result`로 이동 (URL 로그 확인)
3. [ ] DrawResultPage 진입 → 자체 셔플 실행 → 카드 N장 즉시 reveal
4. [ ] auto-save 동작 (`_savedReadingId` 생성). 상단에 저장 완료 토스트/인디케이터(있다면)
5. [ ] 하단 `reading_list`로 이동 → 가장 최근 Reading 항목 존재, createdAt이 방금 시각
6. [ ] 해당 Reading 항목 탭 → reading_detail 진입 → 카드·질문 복원

### Lv2 — 연출 뽑기

1. [ ] 홈 → 체험 레벨 `연출` 선택 → AnimatedDrawPage 진입
2. [ ] 질문 입력(선택) + "뽑기" 탭 → 연출 애니메이션 재생
3. [ ] 연출 종료 → 자동으로 DrawResultPage 전환 (`pushReplacement`)
4. [ ] DrawResultPage에서 카드 동일 집합, 재애니메이션 없음, auto-save 동작 (QG-075-1 관찰 병행)
5. [ ] reading_list에서 새 항목 확인
6. [ ] reading_detail에서 카드/질문 복원 확인

### Lv3 — 2D 셔플 (Brief 064 미구현 — 규약만 확인)

1. [ ] 홈 → 체험 레벨 `2D` 선택 → (구현되면) Shuffle2dPage 진입
2. [ ] 구현 시 카드 선택 → `pushReplacementNamed('draw-result', pathParameters: {'deckId': ...})` 호출 확인
3. [ ] DrawResultPage 진입 → `_reuseUpstreamResult=true` 경로
4. [ ] auto-save 동작
5. [ ] reading_list에서 새 항목
6. [ ] reading_detail 복원

**현재 상태**: Lv3 Shuffle2dPage 미구현 → 본 체크리스트는 Brief 064 후속 구현 시 실행. IC #14 deferred와 직결.

### Lv4 — 2.5D 셔플

1. [ ] 홈 → 체험 레벨 `2.5D` 선택 → IntentionPage 진입
2. [ ] 질문 입력 → "다음" → ShufflePage(Lv4, Forge2D) 진입
3. [ ] 셔플 후 "뽑기" 탭 → DrawResultPage 전환 (`pushReplacementNamed('draw-result')`)
4. [ ] DrawResultPage에서 동일 카드 집합, auto-save 동작 (QG-075-2 센서 정상 경로 관찰, QG-075-3 백그라운드 복귀 관찰)
5. [ ] reading_list에서 새 항목
6. [ ] reading_detail에서 카드/질문 복원

### 뒤로가기 UX 검증 (IC #13)

- Lv2 완료 → DrawResultPage → Android 뒤로가기 → **홈**으로 복귀해야 함 (연출 페이지 재생 없음)
- Lv4 완료 → DrawResultPage → Android 뒤로가기 → **홈**으로 복귀해야 함 (ShufflePage 재진입 없음)

### 백그라운드 복귀 검증 (IC #22, QG-075-3)

- Lv2 DrawResultPage 진입 → 홈 버튼(OS) → 2초 → 앱 아이콘 재탭 → DrawResultPage 그대로, 카드 재셔플 없음
- Lv4 동일 시나리오 반복

### 예외 경로 (IC #12, QG-075-2)

- (가능하면) 덱 파일이 없는 상태에서 Lv4 진입 → 크래시 대신 로딩 인디케이터 유지 확인
- ShufflePage에서 "뽑기" 탭 시점의 네트워크/DB 실패 재현 — 크래시 없이 스낵바 또는 홈 복귀

---

## 5. Push Criteria

Push 단계에 전달할 측정 가능한 기준. 각 기준은 `flutter build apk --debug` 성공을 전제로 한다.

### 5.1 기계적 교정 (Push 실행)

1. **P-1 (Must)**: `mobile/lib/features/shuffle/presentation/pages/shuffle_page.dart`의 메서드 `_goToReading` → `_goToDrawResult`로 리네임. 호출부(L164) 동시 교체. **측정**: `grep -rn "_goToReading" mobile/lib` = 0. 빌드 성공. (QG-075-5)

2. **P-2 (Should)**: `_goToDrawResult` 함수 본문에 try/catch 도입 — 덱 로드/셔플 실패 시 `ScaffoldMessenger.of(context).showSnackBar(...)` 표시 후 홈 복귀 (`context.go('/')`). **측정**: 함수 내 `try` 블록 존재. `flutter analyze` 0 warning. (QG-075-2 partial)

### 5.2 수동 관찰/검증 (Push 기록만)

3. **P-3**: §4 Lv1 체크리스트 6단계 전부 PASS 기록.
4. **P-4**: §4 Lv2 체크리스트 6단계 전부 PASS 기록 + QG-075-1 관찰(재애니메이션 없음, 끊김 없음) 기록.
5. **P-5**: §4 Lv4 체크리스트 6단계 전부 PASS 기록 + QG-075-3 관찰(백그라운드 복귀 재셔플 없음) 기록.
6. **P-6**: §4 뒤로가기 UX 검증(Lv2, Lv4) PASS 기록. Android 뒤로가기 → 홈 복귀.

### 5.3 보류/기록 (Push 제외)

7. **P-7 (Deferred)**: IC #14 — Lv3 Shuffle2dPage 미구현 상태에서는 검증 불가. Brief 064 후속 Brief가 작성되는 시점에 MA-5(`named route 'draw-result' 사용`) 참조를 확인한다. 본 qualify가 앵커 문서(076) 역할.
8. **P-8 (Out of MA-8)**: H2 "즉시" AppBar 텍스트 정합성은 별도 Brief로 분리. Push는 평가하지 않는다.

### 5.4 Push 성공 판정

- **Must 기준 전부 PASS**: P-1.
- **Should 1건 이상 PASS** 또는 **사유 기록**: P-2.
- **수동 관찰 P-3~P-6**: 4건 전부 "PASS 기록" 또는 "미실행 사유" 기록.

---

## 6. Minor Hygiene Register

| ID | 위치 | 내용 | Push 범위 | Brief 분리 |
|----|------|------|-----------|-----------|
| H1 | `shuffle_page.dart:52, 164` | `_goToReading` → `_goToDrawResult` 리네임 필요 (이름=진실) | **포함** (P-1) | — |
| H2 | `draw_result_page.dart:216, 223, 233` | `"즉시"` 뉘앙스가 Lv2~Lv4에도 표시 | **제외** | 필요 (MA-8) |

---

## 7. Trace

- **Brief**: `docs/03_tarot_shuffle/065_Brief_unified_result_page.md`
- **Scope**: `docs/03_tarot_shuffle/066_Scope_unified_result_page.md`
- **Eval**: `docs/03_tarot_shuffle/075_Eval_Cycle_2.md`
- **Verify**: `docs/03_tarot_shuffle/070_Verify_rename_cycle1.md`, `074_Verify_flow_cycle2.md`
- **Impl**: `docs/03_tarot_shuffle/069_Impl_rename_cycle1.md`, `073_Impl_flow_cycle2.md`

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 0s | 0 |
| 2 | user-ai-exchange | 56s | 309862 |
| 3 | user-ai-exchange | 250s | 953594 |
| 4 | user-ai-exchange | 45s | 0 |
| 5 | user-ai-exchange | 189s | 1107972 |
| 6 | user-ai-exchange | 454s | 420177 |
| 7 | user-ai-exchange | 219s | 1752315 |
| 8 | user-ai-exchange | 5410s | 8406509 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 8790s |
| Total Tokens | 12950429 |
| Input Tokens | 197 |
| Output Tokens | 102803 |
| Cache Read | 12570274 |
| Cache Creation | 277155 |
