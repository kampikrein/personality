---
id: "078"
type: retro
title: "Retro — 뽑기 결과 페이지 통일 (unified_result_page)"
created: 2026-04-14
traces_brief: "065"
traces_scope: "066"
traces_eval: "075"
traces_qualify: "076"
traces_push: "077"
summary: >
  Brief 065의 DrawResultPage 수렴 목표를 Scope 066의 2-사이클 TDD 파이프라인이
  8커밋 체인으로 달성. IC 21/26 자동, 4 수동, 1 deferred. 구조적 결함 0.
  핵심 학습: (a) sub-agent return format 강제가 gate 신뢰성을 좌우한다.
  (b) output 필드의 데이터 타입을 프롬프트 계약으로 명시해야 auto_run 중단 예방.
  (c) Brief Context는 실제 코드 구조 확인 후 작성해야 실측 오차 감소.
  (d) grep-based assertion IC는 주석/dartdoc 포함 범위를 Brief에 명시.
keywords: [retro, process-assessment, pipeline, sub-agent, tdd, grep-assertion]
---

# Retro — 뽑기 결과 페이지 통일

## Overview

| 지표 | 값 |
|------|------|
| 파이프라인 단계 | Brief → Scope → (TDD Red → Plan → Impl → Verify) × 2 → Eval → Qualify → Push → Retro |
| 커밋 수 | 8 (C1 3 + C2 4 + Push 1) |
| 산출 문서 | 14 (065~078) |
| 자동화 테스트 | 15/15 PASS (Cycle 2 신규 11 + 기존 4) |
| Ideal Criteria | 26 → 자동 PASS 20, 정적 PASS 1, 수동 pending 4, deferred 1 |
| Effort mode | standard (Research 생략 판단 정확) |
| TDD mode | true (static code inspection 기반) |
| Discretion | L1 |
| 대략 실제 소요 | Brief 30분 + Scope 15분 + Cycle 1 15분 + Cycle 2 40분 + Tail 15분 ≈ 115분 |
| Verdict | proceed (Eval depth_score 9, structural-gap 0) |
| 주요 분기 | (1) D1/D8 명칭을 `Instant` 유지 vs `DrawResult` 리네임 (2) TDD Red가 GridView 발견 후 MA-4 본의만 유지하며 pivot (3) Push에 H1만 포함, H2는 MA-8로 분리 |

## What Worked

### 1. Static code inspection 기반 TDD Red (가장 큰 승리)

Flutter 맥락에서 `File.readAsStringSync` + `.contains()` / `.doesNotContain()` 어설션은 **리네임·제거 계약에 overhead 극소, 결정력 극대**. Widget pumping 없이 즉시 Red→Green 전환이 기계적으로 검증됨. Cycle 1의 legacy grep 0건(IC #1), Cycle 2의 SpreadLayout/saveReading 제거(IC #8)가 모두 이 패턴으로 1줄 어설션화됐다.

**다음에도 적용**: 네이밍/제거/리팩터 계약 타입의 작업에는 우선 정적 어설션 TDD Red를 검토한다.

### 2. Green-guard 테스트로 overreach 방지

Cycle 1 A2 ("DrawResultPage 클래스는 여전히 존재한다")와 Cycle 2 D3 ("reading_detail_page는 삭제되지 않는다") 같은 **"실수로 지우면 안 되는 것"** 어설션이 포함됐다. 단순히 "삭제 계약"만 테스트하면 impl agent가 과도 삭제할 위험 → guard가 잡는다. 특히 ReadingPage 삭제 사이클에서 reading_list/detail이 의도대로 살아남음을 계약화.

**다음에도 적용**: 삭제/리팩터 작업 TDD Red에는 삭제 대상과 짝지어 "살아남아야 할 것" guard도 작성한다.

### 3. 빌드 가능한 커밋 체인 유지

C1(git rename + 파일 이동), C2(클래스 리네임), C3(라우트 교체)로 쪼갰지만 각 커밋이 독립적으로 빌드 성공(또는 C1 직후의 일시적 미빌드가 C2로 즉시 복원됨)을 유지. `git bisect` 친화, rollback 안전. Cycle 2도 4 커밋 체인으로 의존성 순서(initState 분기 → animated 축소 → shuffle 후단 → reading 삭제) 준수.

**다음에도 적용**: 원자성이 중요한 리팩터는 "단일 커밋"이 아니라 **각 커밋이 빌드 가능한 짧은 체인**으로 설계.

### 4. `shuffleStateProvider` 재사용으로 mock-free 테스트 격리

기존 전역 Riverpod 상태를 업스트림→결과 전달 메커니즘으로 재사용한 D2 결정이 테스트 설계에도 이득을 줌. `overrideWith`로 순수하게 상태만 주입하여 mock/stub 없이 initState 분기 양방향 테스트 가능(IC #23). 새 추상층 도입 비용 0, 테스트 격리 획득.

**다음에도 적용**: 새 데이터 전달 경로가 필요해 보일 때, 기존 provider 의미 확장 가능성을 먼저 검토.

## What Struggled

### a) Sub-agent return 단절 패턴 (가장 큰 비용)

Cycle 2 implementation agent가 **3차례에 걸쳐 완료 직전 중단**. C1은 완료, C2 직전 중단, 이후 C4 완료 후 return payload가 완료 요약이 아니라 내부 독백으로 끝남. 실제 작업은 `pipeline.sh next` 확인 시 성공했지만 gate 관점에서는 return을 신뢰할 수 없어 파이프라인 상태를 진실의 원천으로 취급해야 했다.

**원인 추정**: impl agent 프롬프트가 "strict return format"을 강제하지 않았고, effort가 누적되면서 마지막 return 생성에서 context 관리 실패.

**대응 (사후)**: Cycle 2 중반 이후 프롬프트에 `Return strict format: Commit: <sha> / Test: <n/n> / ...` 계약을 명시했더니 개선. 그러나 처음부터 강제했어야 함.

**시간 비용**: Cycle 2 impl agent 재시작 3회 ≈ 파이프라인 총 소요의 약 30% 추가 소비. 전체 115분 중 30분 이상이 여기.

### b) Push `output` 필드 포맷 불일치 (auto_run 정지 유발)

Push seq=11의 `pipeline.sh update ... done <output>`에서 full 40-char SHA `fbe2e96a94211aeae97f52ab64a1b9106282d183`를 저장 → pipeline.sh validate가 "40자 hex → 파일 경로로 오인" 또는 "path로 resolve 실패" → auto_run 자동 정지. 수동 재개 필요.

**원인**: sub-agent 프롬프트에 "output = 보고서 path OR short SHA(7자)"가 명확히 명시되지 않음. push는 문서 보고서를 output으로 넘길 수도 있고 commit SHA를 넘길 수도 있어 관례 불명확.

**교훈**: skill 프롬프트(retro.md, push.md 등)에 output 필드의 허용 타입을 강제 규격화.

### c) Brief와 코드 현실의 불일치 (GridView pivot)

Brief MA-4는 "AnimatedDrawPage의 SpreadLayout 결과 블록 제거"였지만 실제 코드는 `SpreadLayout`을 import하지 않고 `GridView.builder`를 썼다. Cycle 2 TDD Red agent가 소스 검사 단계에서 발견하고 pivot — 본의("결과 렌더/저장 책임 제거")는 유지, 수단(SpreadLayout → GridView 대응 블록)만 교체.

**원인**: Brief Context 섹션이 파일 줄 수와 라우트는 확인했지만, **위젯 트리 내부 렌더 구현**은 확인하지 않고 작성됨 (015 Brief의 기억에 의존).

**교훈**: Brief Context 작성 시 관련 파일의 `import` + `build()` 트리까지 실측 확인. `--deep` 모드의 critique가 이런 실측 오차를 잡는 장치로 설계됨을 재확인.

### d) 수동 검증 항목 5개 잔존 (directional IC의 근본 한계)

IC #9 (연출 시각적 연속성), #12 (Forge2D 예외 복구), #22 (백그라운드 복귀), #14 (Lv3 참조), #26 (Lv1~Lv4 E2E)가 자동화 불가 영역으로 qualify/push의 manual checklist로 전환됨. structural gap은 아니지만 "파이프라인 완료"의 의미에 미세 갭이 있음.

**원인**: directional criterion은 품질 의도를 잡지만 런타임 관찰을 요구. TDD Red가 이를 assertion으로 변환할 수 없는 케이스가 존재 (시각·센서·생명주기).

**교훈**: 다음 Brief 작성 시 directional criterion마다 "관찰 방법 + PASS 판정 기준"을 Brief 단계에서 미리 명시. Qualify가 이를 다시 정제하는 비용을 줄임. 또는 automated proxy (예: 재셔플 방지는 `_executeDraw` 호출 카운터 어설션)로 유도.

### e) Cycle 1의 dartdoc 치외법권 (grep-based assertion 범위 모호)

IC #1("`grep -r "InstantDrawPage|..."` 0건")을 엄격 해석하면 **문자열/주석/dartdoc까지** 정리가 필요. Cycle 1 Impl이 자율적으로 이 deviation을 선택하여 주석과 dartdoc의 legacy 레퍼런스까지 포괄 제거 (다행히 올바른 방향).

**원인**: Brief의 grep criterion이 코드·주석·문자열을 구분하지 않음. Impl agent의 해석에 맡겨짐.

**교훈**: grep-based IC를 쓸 때 Brief에 "대상 범위: 코드·import·주석·dartdoc 포함" 또는 "`-- '*.dart'` + 주석 제외" 중 하나를 명시. 해석 자율도가 클수록 impl variance가 커진다.

## Lessons Learned

1. **Sub-agent 프롬프트에 strict return format을 첫 시작부터 강제한다.** 후반에 추가하면 이미 context가 무거워 실패 확률이 높다. Template: `Commit: <short SHA> / Tests: <n/n> / Files: <count> / Red→Green: <before→after> / Report: <doc>`.

2. **Pipeline output 필드의 타입을 skill 프롬프트에서 규격화한다.** push는 "commit SHA short(7) OR 보고서 path", impl은 "commit SHA short(7)", 나머지 skill은 "보고서 path". 불명확하면 auto_run 정지 비용.

3. **Brief Context 섹션은 실측 기반으로 작성한다.** 파일 줄 수·라우트만이 아니라 해당 파일의 `import` + `build()` 렌더 트리까지 Read로 확인. 기억·이전 Brief 참조만으로는 pivot 리스크.

4. **grep-based assertion IC는 적용 범위를 명시한다.** 코드만인지, 주석·dartdoc·문자열 포함인지. 애매하면 impl agent의 해석이 variance의 원천.

5. **Directional criterion은 관찰 방법과 PASS 판정 기준을 Brief 단계에서 구체화한다.** qualify/push가 뒤늦게 "수동 E2E 체크리스트"로 정제하는 비용을 줄인다. 가능하면 automated proxy(호출 카운터, 상태 스냅샷 diff 등)로 전환 시도.

6. **삭제/리팩터 작업의 TDD Red에는 green-guard를 동봉한다.** "삭제되어야 할 것" 어설션과 "살아남아야 할 것" 어설션을 짝으로. overreach 방지 효과가 큼.

7. **원자성이 중요한 리팩터는 단일 거대 커밋이 아니라 "각 커밋이 빌드 가능한 짧은 체인"으로 설계한다.** 3~4 커밋 체인 + 각 커밋 빌드 성공 유지. git bisect 친화, rollback 안전. 본 파이프라인은 8 커밋 중 0개가 broken state.

## Action Items

### 즉시 (파이프라인 프로토콜/스킬 개선)

| # | 제안 | 대상 파일 | 근거 |
|---|------|---------|------|
| AI-1 | implementation agent 프롬프트에 **strict return format** 템플릿 삽입 (Commit / Tests / Files / Red→Green / Report) | `orchestration-system/agents/implementation.md` | What struggled (a) — Cycle 2 impl 3회 재시작 |
| AI-2 | `pipeline.sh update ... done <output>` output 필드 허용 타입을 **skill별로 명시**: push·impl = short SHA(7), 나머지 = 보고서 절대 경로 | `orchestration-system/agents/push.md`, `implementation.md` 및 pipeline.sh validate 로직 | What struggled (b) — fbe2e96 full SHA로 auto_run 정지 |
| AI-3 | Brief skill의 Context 섹션 작성 가이드에 **"대상 파일 `import` + `build()` 트리 Read 확인"** 체크리스트 추가 | `brief.md` Context 섹션 템플릿 | What struggled (c) — MA-4 GridView pivot |
| AI-4 | grep-based IC 작성 시 **"적용 범위 명시"** 규칙 추가 — 코드/주석/dartdoc 중 어디까지 | `brief.md` Ideal Criteria 섹션 | What struggled (e) — IC #1 해석 모호 |

### 후속 (deferred 재확인)

| # | 항목 | 출처 | 후속 계기 |
|---|------|------|---------|
| DR-1 | Lv3 Shuffle2dPage 구현 Brief 작성 시 MA-5(`named route 'draw-result'` 사용) 참조 확인 (IC #14) | Brief 064 + 065 MA-5 + Qualify 076 §5.3 P-7 + Push 077 D-1 | Brief 064 후속 구현 시점 |
| DR-2 | DrawResultPage의 AppBar/타이틀 "즉시" 뉘앙스 → 모드 중립 표기로 교체 (H2) | Push 077 D-2 / Qualify 076 QG-075-6 | 별도 Brief (MA-8 위반으로 본 Brief 범위 외). `draw_result_page.dart:216, 223, 233` |
| DR-3 | 수동 E2E 4건 실행: Lv1·Lv2·Lv4 × 6단계 + 뒤로가기 + 백그라운드 + 예외 경로 | Push 077 §4 체크리스트 | 사용자 에뮬레이터 실행 시점 |

### 장기

| # | 제안 | 근거 |
|---|------|------|
| AI-5 | TDD Red mode에서 static code inspection 패턴(`File.readAsStringSync` + contains/doesNotContain)을 **공식 권장 스니펫**으로 tdd-red.md에 명시. 특히 Flutter/Dart 도메인 | What worked (1) — 본 파이프라인에서 가장 효과적 |
| AI-6 | TDD Red에 **green-guard 테스트** 작성 규범을 tdd-red.md에 명시 ("삭제 대상 ↔ 생존 대상" 짝) | What worked (2) — overreach 방지 |

## Deferred Items 재확인

| 항목 | 출처 | 상태 | 다음 작업 |
|------|------|------|---------|
| Brief 064 Lv3 Shuffle2dPage 신규 구현 | Brief 064 + 065 MA-5 | deferred | Lv3 Brief 작성 시 본 077이 앵커. IC #14 검증 |
| H2 "즉시" AppBar 텍스트 정합성 | Push 077 D-2 | deferred (별도 Brief 필요) | Brief 065 MA-8 해제 후 `draw_result_page.dart` 내부 UI Brief로 분리 |
| 수동 E2E Lv1/Lv2/Lv4 × 6단계 + 뒤로가기 + 백그라운드 + 예외 경로 | Push 077 §4 | manual pending | 사용자 실행 (에뮬레이터 + `flutter build apk --debug` 설치 후) |

---

## Trace

- **Brief**: `docs/03_tarot_shuffle/065_Brief_unified_result_page.md`
- **Scope**: `docs/03_tarot_shuffle/066_Scope_unified_result_page.md`
- **Cycle 1**: 067 TDD Red → 068 Plan → 069 Impl → 070 Verify (`125c9dd` → `bdb9b95` → `abb049f`)
- **Cycle 2**: 071 TDD Red → 072 Plan → 073 Impl → 074 Verify (`aa3b116` → `813a1c3` → `6adb144` → `6731760`)
- **Tail**: 075 Eval → 076 Qualify → 077 Push (`fbe2e96`) → **078 Retro (this)**

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
