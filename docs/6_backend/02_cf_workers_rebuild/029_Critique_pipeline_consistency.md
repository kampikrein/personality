---
id: "029"
type: critique
title: "Scope 026 Critique — Pipeline DB 일관성"
created: 2026-04-29
status: completed
perspective: "pipeline_db_consistency"
target: "026"
confidence: high
summary: >
  Scope 026과 Pipeline DB(`007_cf_workers_rebuild_1c64.db`)는 cycle/seq/status/phase
  4축 모두 일치하며, gate next()는 의도 순서대로 Cycle 1 impl → … → Cycle 8 verify →
  Cycle 10 eval/qualify/push → Cycle 99 retro를 정확히 반환한다. 다만 (1) Scope
  frontmatter `auto_run:false` ↔ DB meta `auto_run:true` 불일치, (2) `planned_cycles:10`
  유지로 인한 CB L2 한계가 활성 7 사이클 대비 과도, (3) Scope의 `cycle:10_tail` 표기가
  DB의 `cycle=10`(integer)와 형식 차이라 운영자 혼동 위험이 잔존한다. 실행 위험은
  M·m 수준에서 모두 비차단(non-blocking).
keywords: [critique, scope-026, pipeline-db, gate-next, cycle-numbering, interrupted-state]
---

# Scope 026 Critique — Pipeline DB 일관성

## Executive Summary

Scope 026 § "Pipeline DB 정렬 상태"가 명세한 21행(seq 13–52)은 실제 DB와 **완전 일치**한다. cycle 7/9/10 partial interrupted, cycle 8 active, cycle 10 tail(eval/qualify/push) active, cycle 99 retro active 모두 검증됨. `pipeline.sh next`의 SQL `WHERE status='pending' AND phase='impl' ORDER BY cycle, sub_cycle, seq`는 interrupted를 자연스럽게 건너뛰므로 cycle 8 verify(seq 42) 직후 cycle 10 eval(seq 49)로 정확히 점프한다(seq 43–48 interrupted는 영향 없음). 실측 `pipeline.sh next cf_workers_rebuild` 호출은 `13|1|implementation`을 반환했다 — Scope 026 § 실행 순서 표 첫 줄과 일치.

다만 **frontmatter auto_run 불일치**(Scope=false, DB=true), **planned_cycles=10 잔존**, **cycle:10_tail 표기와 DB cycle=10(int) 형식 차이** 3건이 잠재 위험. 모두 실행을 차단하지는 않으나 운영자 오해와 CB 임계 왜곡 가능성이 있다.

---

## Strengths

1. **명세 ↔ DB 21행 1:1 일치** — Scope 026 § "Pipeline DB 정렬 상태"의 seq 13–52 매핑이 SELECT 결과와 행별로 정확히 일치 (cycle/sub_cycle/skill/status 4축 동시 검증).
2. **interrupted 분리 정확** — cycle 7 (seq 35–38, 4행), cycle 9 (seq 43–45, 3행), cycle 10 (seq 46–48, 3행) 총 10행이 정확히 `status='interrupted'` 처리됨. checklist_history에 reason='phase-2-deferred'가 changed_at 2026-04-29 14:25:06–07로 기록되어 감사 추적 가능.
3. **research-phase 잔여 행 차단** — checklist에 `phase='research'` 11행이 모두 done 상태로 잔존하지만 next()의 `phase='$current_phase'` 필터가 이를 제외 (`current_phase=impl`). cycle 99 retro가 phase별 1행씩 두 번 존재하나, 같은 이유로 impl 행(seq 52)만 활성.
4. **brief_path/scope_path/session_id 메타 정합** — Scope 026 frontmatter id=026, traces_brief=021. DB meta scope_path가 026, brief_path가 021을 가리킴. session_id `1c6449db-…`는 cf_workers_rebuild 단일 세션 (Scope 026 frontmatter에 session_id 명시 자체는 없으나 DB와 일관).
5. **cycle 10 tail 배치 무손상** — cycle 10 makeplan/impl/verify(interrupted)와 eval/qualify/push(pending)이 동일 cycle=10·sub_cycle=0에 공존하지만 ORDER BY cycle, sub_cycle, seq에서 seq 46→47→48→49→50→51 순으로 정렬되므로, pending 필터 적용 후 49→50→51만 남는다 (interrupted 3행이 ORDER BY를 깨뜨리지 않음).
6. **eval_history phase-scope 정확** — research phase eval 5행(R1–R5 SUFFICIENT, depth 5–6) 모두 `phase='research'`로 격리. CB L2가 `WHERE phase='impl'`로 카운트하므로 impl 사이클에 영향 없음 (현재 distinct cycle = 0).

---

## Weaknesses

### Major

#### M1. auto_run 메타 불일치 (Scope=false, DB=true)

**증거**:
```
Scope 026 frontmatter: auto_run: false
DB meta: auto_run|true
```

**영향**: gate가 DB를 읽으면 auto_run=true로 동작, Circuit Breaker도 활성화 (`if [ "$auto_run" = "true" ]; then _circuit_breaker`). Scope 026 작성자가 "사용자 1단계씩 승인" 의도였다면 의도 위반. 반대로 DB가 의도라면 frontmatter 오기. 어느 쪽이든 두 source-of-truth가 갈라진 상태.

**Severity**: Major (실행 흐름 결정).
**해결**: 둘 중 하나를 정정. 현 프로젝트가 No-Stop Protocol을 기본 운용한다면 Scope frontmatter를 `auto_run: true`로 정정 (Scope 026이 Phase 1 alignment anchor라 frontmatter가 운용 의도의 명시적 기록 위치).

---

#### M2. planned_cycles=10 잔존 — CB L2 임계 왜곡

**증거**:
```
DB meta: planned_cycles=10
CB L2 limit (impl) = 10 × 3 = 30
distinct cycles in impl eval_history: 0
활성 사이클(scope 026): 7 + tail eval = 8 distinct cycle
```

**영향**: Brief 021/Scope 026는 활성 cycle 7개(1, 2, 3, 4, 5, 6, 8) + tail cycle 10 eval = 8 distinct cycle을 의도. CB L2 임계는 planned_cycles × 3 = 30이므로 30회 평가가 누적되어야 발동 — 사실상 무력화. Scope 007의 원본 10 cycle 가정이 잔존.

**Severity**: Major (Brief 021 § "20 MAN-DAY 한도" + Synthesis 025 C2 "활성 7 + tail" 정신을 CB가 보호하지 못함).
**해결**: `pipeline.sh set planned_cycles 8` (또는 7). 다만 add-subcycle/add-cycle 때 임계가 재계산되므로 향후 expansion 여지를 두려면 8 권장.

---

#### M3. cycle: 10_tail 표기 ↔ DB cycle=10 (integer) 형식 차이

**증거**:
```
Scope 026 cycles[]: cycle: 10_tail
DB checklist.cycle: INTEGER NOT NULL = 10
```

**영향**: Scope 026 운영자가 "10_tail은 별개 cycle"로 인식하면 cycle=10에 6행(makeplan/impl/verify interrupted + eval/qualify/push pending)이 공존하는 사실을 놓친다. 향후 add-cycle 시 cycle 11로 명명할지 cycle 10 sub_cycle로 추가할지 혼선 위험. 또한 add-subcycle 트리거 시 cycle=10 대상이 makeplan~verify interrupted까지 함께 묶이는 이상 동작 가능성.

**Severity**: Major (운영 혼선 + 동적 사이클 추가 시 잠재 버그).
**해결**: Scope 026 cycles[] 표기를 정수형 cycle: 10 + note에 "tail (eval/qualify/push only) — makeplan/impl/verify는 동일 cycle 내 interrupted"로 명시 변경. 또는 DB schema가 INTEGER인 한 Scope에서 `10_tail` 같은 가상 식별자를 만들지 않는다는 운영 룰 명문화.

---

### Minor

#### m1. cycle=99 retro 행이 phase별 1개씩 존재 (research done + impl pending)

**영향**: 현 next() 필터로 충돌 없으나, 향후 phase 전환 시 `current_phase=research` 재설정이 잘못 일어나면 done 행이 다시 진입 시도될 위험. 운영자가 retro = "최종 한 번만 실행"으로 가정하면 두 행 존재 자체가 직관에 반함.
**Severity**: Minor.
**해결**: 없음(설계상 의도). Scope 026 § 사이클 표에 "phase별 retro 1행씩, impl phase 행만 활성"을 1줄 명시.

#### m2. Scope 026 § "Pipeline DB 정렬 상태" 표기 vs DB 일치도 100% 이지만 형식 변환 위험

**영향**: Scope 026이 markdown 표가 아닌 사람이 읽기 좋게 정리한 텍스트 블록(`[cycle-1] makeplan: done (020)` 형식)으로만 기록 — 자동 검증 스크립트 부재. 향후 DB 변경 시 Scope 텍스트가 stale될 수 있다.
**Severity**: Minor.
**해결**: Scope에 `pipeline.sh status` 명령으로 재생성 가능함을 한 줄 명시. (Source-of-truth = DB.)

#### m3. had_interruption 메타 부재

**영향**: pipeline.sh next의 Warning 2(`had_interruption=true`)가 발동하지 않음. 운영자가 "phase-2-deferred는 interrupted이지만 재개되지 않을 의도적 잔존"임을 인지해야 하는데 next 출력에 경고가 없다. Scope 026 § "deferred"가 anchor이지만 gate console에는 표시 안 됨.
**Severity**: Minor.
**해결**: `pipeline.sh set had_interruption true` (의도적 deferred도 운영상 'interruption' 신호로 간주). 또는 pipeline.sh에 별도 신호 추가 — 현 범위에서는 set으로 충분.

---

## Missing Elements

1. **gate가 cycle 8 verify→cycle 10 eval로 점프할 때 인지 신호 부재**: Scope 026이 이 점프(seq 42 → seq 49, cycle 8 → cycle 10)를 "tail 진입"으로 명시하지만, pipeline.sh next는 단순히 다음 행을 반환하므로 gate 메인 에이전트가 "tail 단계 시작"임을 자각할 단서가 출력에 없다. eval 스킬 자체의 protocol이 "전체 사이클 종합 평가"임을 알기에 자연 발화하긴 하나, scope-tail 신호로 명시되면 더 robust.

2. **deferred_cycles의 audit-log 표현 미흡**: Scope 026 frontmatter `deferred_cycles: [7, 9, 10_partial]`가 의도이나, DB checklist_history는 `phase-2-deferred` reason 10건만 기록. "Brief 021 In Scope 9 → cycle 7" 같은 trace가 history reason에 없어 향후 Phase 2 재진입 시 어떤 cycle을 어떤 결정으로 deferred했는지 한 번 더 Scope 본문을 읽어야 함.

3. **cycle 10_partial 정의 모호**: deferred_cycles에 `10_partial`로 명시되어 있으나 partial은 DB status enum에는 없음 (CHECK status IN ('pending','in-progress','done','interrupted','partial')). 실제 DB는 cycle 10 행을 partial이 아닌 interrupted+pending 혼합으로 표현. Scope의 "10_partial"은 "cycle 10 일부만 deferred" 의미이지 DB 의 status='partial'과 무관 — 표기 충돌 위험.

---

## gate next() 5회 simulation 결과 표

ORDER BY cycle, sub_cycle, seq + WHERE status='pending' AND phase='impl' 기준.

| 순번 | next() 반환 (seq\|cycle\|skill) | Scope 026 의도 | 일치? |
|------|--------------------------------|---------------|-------|
| 1 | `13\|1\|implementation` | cycle-1 implementation (실측 확인됨) | ✓ |
| 2 | `14\|1\|verify` | cycle-1 verify | ✓ |
| 3 | `15\|2\|tdd-red` | cycle-2 tdd-red (TDD 모드) | ✓ |
| 4 | `16\|2\|makeplan` | cycle-2 makeplan | ✓ |
| 5 | `17\|2\|implementation` | cycle-2 implementation | ✓ |

**확장 점검 (cycle 8 → tail 점프 지점)**

| 순번 | next() 반환 | Scope 026 의도 | 일치? |
|------|------------|--------------|-------|
| 26 | `42\|8\|verify` | cycle-8 verify (마지막 활성 impl) | ✓ |
| 27 | `49\|10\|eval` | cycle 10_tail eval (tail 진입) | ✓ |
| 28 | `50\|10\|qualify` | cycle 10_tail qualify | ✓ |
| 29 | `51\|10\|push` | cycle 10_tail push | ✓ |
| 30 | `52\|99\|retro` | cycle 99 retro | ✓ |
| 31 | `DONE: no pending items` | 파이프라인 완료 | ✓ |

**핵심 검증**: seq 42 → seq 49 점프에서 seq 43–48 (interrupted) 6행은 `WHERE status='pending'` 필터로 자연 제외. cycle=10 내부 ORDER BY에서도 seq 46/47/48(interrupted) 제외 후 seq 49/50/51만 남으므로 순서 안전.

---

## DB ↔ Scope 명세 cross-table

| seq | cycle | sub_cycle | skill | status | phase | Scope 026 명세 | 일치 |
|-----|-------|-----------|-------|--------|-------|---------------|------|
| 12 | 1 | 0 | makeplan | done | impl | cycle-1 makeplan: done (020) | ✓ |
| 13 | 1 | 0 | implementation | pending | impl | cycle-1 implementation: pending ← 다음 | ✓ |
| 14 | 1 | 0 | verify | pending | impl | cycle-1 verify: pending | ✓ |
| 15–18 | 2 | 0 | tdd-red/makeplan/implementation/verify | pending | impl | cycle-2: pending (4행) | ✓ |
| 19–22 | 3 | 0 | tdd-red→verify | pending | impl | cycle-3: pending (4행) | ✓ |
| 23–26 | 4 | 0 | tdd-red→verify | pending | impl | cycle-4: pending (4행) | ✓ |
| 27–30 | 5 | 0 | tdd-red→verify | pending | impl | cycle-5: pending (4행) | ✓ |
| 31–34 | 6 | 0 | tdd-red→verify | pending | impl | cycle-6: pending (4행) | ✓ |
| 35–38 | 7 | 0 | tdd-red→verify | **interrupted** | impl | cycle-7: interrupted (phase-2-deferred) | ✓ |
| 39–42 | 8 | 0 | tdd-red→verify | pending | impl | cycle-8: pending (4행) | ✓ |
| 43–45 | 9 | 0 | makeplan→verify | **interrupted** | impl | cycle-9: interrupted (3행) | ✓ |
| 46–48 | 10 | 0 | makeplan→verify | **interrupted** | impl | cycle-10 makeplan/impl/verify: interrupted | ✓ |
| 49–51 | 10 | 0 | eval/qualify/push | pending | impl | cycle-10 tail: pending (3행) | ✓ |
| 52 | 99 | 0 | retro | pending | impl | cycle-99 retro: pending | ✓ |
| 1–11 | 1–5,99 | 0 | research/eval/retro | done | research | (Scope에 명시 없으나 phase 격리로 무관) | ✓ |

**Meta 항목 비교**

| meta key | DB value | Scope 026 frontmatter | 일치 |
|----------|---------|---------------------|------|
| topic | cf_workers_rebuild | (frontmatter엔 없음, 파일명 일관) | ✓ |
| current_phase | impl | (Scope intent: impl 사이클) | ✓ |
| effort_mode | deep | effort_mode: deep | ✓ |
| tdd_mode | true | tdd_mode: true | ✓ |
| auto_run | true | **auto_run: false** | ✗ M1 |
| planned_cycles | 10 | 활성 7 + tail (= 8 distinct) | ✗ M2 |
| brief_path | …/021_Brief_…md | traces_brief: "021" | ✓ |
| scope_path | …/026_Scope_…md | id: "026" | ✓ |
| session_id | 1c6449db-… | (frontmatter 미기재, 단일 세션 상속) | ✓ |
| orchestrator_active | true | (운용 신호) | ✓ |
| discretion_level | L1 | (Scope에 미기재, brief carryover) | ✓ |

---

## Detailed Analysis

### Cycle 8 → Cycle 10 점프 정합성 (핵심 위험 지점)

Scope 026이 가장 우려할 만한 지점은 cycle 8 verify(seq 42) 완료 후 next()가 cycle 10 eval(seq 49)을 정확히 반환하는가다. 분석:

1. SQL `ORDER BY cycle, sub_cycle, seq`는 cycle=10 행 6개를 seq 46→47→48→49→50→51 순으로 나열.
2. WHERE 절 `status='pending'`이 seq 46/47/48(interrupted)을 제외.
3. 따라서 seq 49가 첫 번째 pending → next()는 `49|10|eval` 반환.
4. cycle=99 retro(seq 52)는 cycle 번호가 더 크므로 마지막.

**결론**: pipeline.sh의 단순 ORDER BY+필터 조합이 Scope 026의 "활성 cycle 종료 → tail 진입 → retro" 의도를 정확히 구현. 추가 가드 불필요.

### eval_history phase 격리

research phase에서 R1–R5 5건 SUFFICIENT가 누적됐으나 모두 `phase='research'`. CB L2의 `WHERE phase='impl'` 필터로 impl 진행에 영향 없음. 다만 planned_cycles=10이 phase 공유 메타라 research phase에서 10×4=40 한도가 적용됐고, impl에서는 10×3=30 한도가 적용된다. **현 30 한도는 사실상 도달 불가** (활성 cycle 8 distinct, 사이클당 평균 1 eval 가정 시 8회). M2 해결 권고대로 8로 낮추면 한도 24 → 여전히 여유 있으나 structural-gap 보호 가능.

### interrupted ↔ pending 전환 위험

`pipeline.sh resume`은 모든 interrupted를 pending으로 되돌리고 had_interruption=true를 설정한다. 운영자가 Phase 2 재진입 시 `resume`을 호출하면 cycle 7/9/10 makeplan/impl/verify가 pending이 되어 next()가 이를 반환하기 시작 — Phase 2 재개에 적절한 동작. 단, 같은 메커니즘이 Phase 1 진행 중 실수로 호출되면 deferred 의도가 깨진다. Scope 026 § deferred에 "Phase 1 종료 전 `pipeline.sh resume` 호출 금지" 1줄 명시 권고.

### Scope의 cycles[] frontmatter ↔ DB 매핑 누락

Scope 026 `cycles[]`에 cycle: 7/9는 등장하지 않는다 (deferred로 별도 분리). DB에는 cycle 7/9가 interrupted로 잔존. 따라서 Scope `cycles[]`만 보면 "cycle 7/9가 없는 것"처럼 보이지만 DB는 그 행을 보유. 이건 의도된 표기(deferred는 cycles[]에서 제외) 이나 frontmatter consumer(자동 도구) 기준에서는 DB 행이 더 풍부. 부정합은 아님 — Scope cycles[] = "이번 phase에 실행할 cycle만"이라는 운영 룰의 표명.

---

## Recommendations

### P0 (즉시)

1. **R-M1**: `pipeline.sh set auto_run` 또는 Scope 026 frontmatter `auto_run` 둘 중 하나로 통일. 현 운영(No-Stop Protocol 기본)에 맞추려면 Scope frontmatter를 `auto_run: true`로 정정.
2. **R-M2**: `pipeline.sh set planned_cycles 8` — 활성 7 cycle + tail cycle 10 = 8 distinct 반영. CB L2 임계 24로 정상화.

### P1 (다음 makeplan 전)

3. **R-M3**: Scope 026 cycles[] `cycle: 10_tail` → `cycle: 10` (integer) + note 강화 ("tail (eval/qualify/push) — makeplan/impl/verify는 동일 cycle 내 interrupted, deferred to Phase 2"). frontmatter consumer가 정수 cycle을 가정하는 다른 도구와 호환.
4. **R-m1/m2**: Scope § "Pipeline DB 정렬 상태"에 `pipeline.sh status cf_workers_rebuild`로 항상 재확인 가능함과 source-of-truth가 DB임을 한 줄 명시.

### P2 (선택)

5. **R-m3**: `pipeline.sh set had_interruption true` — gate next 출력에 "WARNING: pipeline was interrupted and resumed" 표시되도록. 의도적 deferred도 운영 신호로 노출.
6. **R-Missing 1**: Scope 026 § 실행 순서 표 마지막 행에 "[tail] 진입 = cycle 8 verify 완료 직후 자동" 명시 — gate가 별도 신호 없이 자연스럽게 점프함을 명문화.
7. **R-Missing 3**: deferred_cycles의 `10_partial` 표기를 `10_makeplan_impl_verify_only` 등으로 명료화 (status='partial' enum과 혼동 방지).

---

## References

- Scope 026: `/Users/kampikrein/A/personality/docs/6_backend/02_cf_workers_rebuild/026_Scope_conversion_phase1.md`
- Brief 021: `/Users/kampikrein/A/personality/docs/6_backend/02_cf_workers_rebuild/021_Brief_conversion_phase1.md`
- Pipeline DB: `/Users/kampikrein/A/personality/tmp/007_cf_workers_rebuild_1c64.db`
- pipeline.sh: `~/.claude/scripts/pipeline.sh` (next: L417–473, validate: L621–730, resume: L825–840)
- Auto-run protocol: `~/.claude/skills/scope/references/auto-run-steps.md`
- Gate protocol: `~/.claude/orchestration-system/docs/protocols/gate-protocol.md`
- 실측 명령:
  - `pipeline.sh next cf_workers_rebuild` → `13|1|implementation`
  - `sqlite3 … "SELECT … WHERE status='pending' AND phase='impl' ORDER BY cycle, sub_cycle, seq;"` → 30행, cycle 8 verify 직후 cycle 10 eval로 점프 확인

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 25s | 43455 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 25s |
| Total Tokens | 43455 |
| Input Tokens | 6 |
| Output Tokens | 1821 |
| Cache Read | 0 |
| Cache Creation | 41628 |
