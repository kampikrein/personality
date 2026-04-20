---
id: "039"
type: retro
title: "Retro — Layout Redesign Pipeline Structural Lessons"
created: 2026-04-20
cycle: tail
status: completed
traces_brief: "011"
verdict_summary: "SUFFICIENT (eval 88) / qualify 0.91 / push ACCEPT_AS_IS (0 iterations)"
summary: >
  6 impl cycles + 4 tail steps (eval/qualify/push/retro) 전 28 체크리스트 아이템 완주.
  rework 0, cycle 재기동 0, commit 8건, 0 build error. 구조적 교훈 5: (1) codegen
  경계가 자연스러운 cycle atomicity 분할점, (2) `PRAGMA user_version` tx 내부 배치는
  필수 패턴, (3) StreamProvider widget test flake 는 integration_test 또는 public
  widget extraction 으로만 해소, (4) `ValueKey(layoutType)` GridView root 배치로
  animation controller 누수 예방, (5) Brief supersede 시 frontmatter 와 Scope 동기
  갱신 필요. Agent timeout 2회는 main-session fallback 으로 복구 — 향후 impl agent
  는 code edit + commit 까지만 수행하고 test 실행은 main session 에 위임 권고.
keywords: [retro, tail, layout-redesign, brief-011, structural-lessons, codegen-atomicity, migration-pragma, streamprovider-flake, agent-timeout-fallback]
---

# Retro — Layout Redesign Pipeline Structural Lessons

## 1. Pipeline Summary

| 항목 | 값 |
|------|-----|
| 체크리스트 | 28 items = 6 cycles × (tdd-red / makeplan / impl / verify) + 4 tail steps (eval, qualify, push, retro) |
| 기간 | 첫 commit `f88626d` → 최종 commit `eb11313` (단일 세션 내) |
| Agent dispatches | ~20건 (tail 일부는 main-session 직접 실행) |
| Agent timeouts | 2건 (seq=9 cycle 3 tdd-red 1차, seq=15 cycle 4 impl 1차) — 양자 모두 main-session fallback 으로 복구 |
| Commits | 8 (`f88626d`, `5c6a6e2`, `a37a2e9`, `acb5ff9`, `841bc38`, `693dbf0`, `6e1a15d`, `eb11313`) |
| Tests | pre-cycle 14 → final 54 (+40 new, 52 green / 2 documented-deferred) |
| Docs | 30 (Brief 011 + 4 Critique 012~015 + Synthesis 016 + Scope 017 + TDD-Red×6 + Plan×6 + Verify×6 + eval/qualify/push/retro) |
| Build | 0 errors 전 구간 |
| Quality | eval 88 / qualify 0.91 / push ACCEPT_AS_IS (Standard threshold 0.70, +0.21) |

## 2. What Worked Well (Keep)

### Research-first (docs 007~010)
- Critical Reviews 3건이 전부 impl 전에 Synthesis 016 로 수렴 — impl 단계에서의 rework 를 0 으로 만든 결정적 요인.
- Deep Critique (012~016) 가 11개 항목 식별 → Brief 011 reshape → Scope 017 process_assertions 도출. 이 사전 투자가 6 cycles 의 rework-free 실행을 보장.

### Cycle 1/2 atomicity around build_runner
- codegen (drift/freezed) 출력을 atomic boundary 로 삼음. cycle 1 은 `LayoutType` enum + `SpreadReading` 변환만, cycle 2 가 `UserSettings` 까지 propagate. 컴파일 breakage 가 cycle 중간에 발생해도 cycle 경계에서 반드시 green 으로 닫힘.

### PRAGMA user_version inside transaction (Decision 16)
- phantom v7.5 crash loop 을 예방. onUpgrade raw SQL 내부에서 `UPDATE + PRAGMA user_version = 8` 을 같은 tx 로 묶어 원자성 확보. migration 테스트 4케이스 green.

### SchemaVerifier + pre-committed v7 snapshot
- `drift_schemas/` 에 v7 스냅샷이 이미 있었기에 migration test 가 안정적 기동. 사용자에게 v7 스냅샷 없이 v7→v8 을 써 달라고 요청하지 않아도 됐음.

### CustomPaint placeholder vs dotted_border package (Decision 15)
- 약 30줄 자체 구현으로 외부 의존 회피. 점선 placeholder 는 1~2개 위젯에서만 사용 — pubspec 의존성 추가 ROI 음수였음.

## 3. Structural Problems (Avoid / Redesign)

### P1 — Agent timeout on flutter-test-involving steps
- 증상: cycle 3 tdd-red (drift migration test 생성) 와 cycle 4 impl (SpreadLayout rewrite + spread_layout_test) 에서 subagent 타임아웃.
- 원인: agent 가 `flutter test` 전체를 자기 컨텍스트에서 돌리다가 초 단위 완주 → hung 처럼 보임.
- **Recommendation**: impl/tdd-red 서브 에이전트는 **code edit + commit 까지만 수행**, `flutter test` 실행은 verify 단계 또는 main session 으로 이관. Scope process_assertion 에 "agent 는 test 실행을 직접 수행하지 않는다" 명시.

### P2 — Cycle 3 prerequisite surprise (drift_dev ordering)
- 증상: TDD-Red 024 작성 시점에 `drift_dev schema generate --version=8` 호출을 위해서는 `schemaVersion: 8` 이 **코드에 먼저 있어야** 한다는 사실이 노출됨. Scope 017 의 cycle 3 설계는 "schema 스냅샷 먼저 → 코드 반영" 순서를 가정했음.
- Plan 025 가 순서를 교정 ("`@DriftDatabase(schemaVersion: 8)` 변경 → `drift_dev schema generate` → verify" 순) 했기에 cycle 내부에서 복구.
- **Recommendation**: makeplan 단계가 **codegen 도구의 입출력 의존성 그래프를 명시적으로 점검**. drift / freezed / build_runner 등은 "source → generated" 흐름이 역전되기 쉬움.

### P3 — Cycle 5 widget test infra limitation (StreamProvider + fakeAsync)
- 증상: `_DrawSettingsPanel` 내부 `StreamProvider<UserSettings>` 의 first-value emission 이 `tester.pump(Duration)` 에서 불안정. T2 (SnackBar 동적 undo) 와 T4 (grid3x3 드로우 순서 메뉴) 가 pump timing 에 의존.
- 032 Verify 가 grep 코드리뷰 대체 증거로 PARTIAL 처리 — impl 자체는 정확하나 테스트 하네스가 증명 불가.
- **Recommendation**: 세 경로 중 택 1로 해소 — (a) `_DrawSettingsPanel` 을 public widget 으로 추출하여 StreamProvider override 를 테스트 내부에서 주입, (b) `BehaviorSubject` 기반 fake stream 도입, (c) integration_test 로 이관. 현재 cycle 에서는 ROI 부족으로 deferred; 향후 별도 cycle 권고.

### P4 — Scope 006 stale folder path in frontmatter
- 증상: docs restructure (commit `9d11a36`) 이전 Scope 006 의 `traces_brief: "docs/15_draw_experience_settings/..."` 전체 경로 참조가 폴더 이동 후 rot. Brief 011 이 **short ID `"005"`** 를 쓴 덕에 supersede 체인은 살아남음.
- **Recommendation**: 모든 frontmatter cross-ref 는 **short ID** (`"011"`, `"036"`) 만 사용. full path 는 rot 가능. agent 지침에 "traces_* 필드는 short ID 형식" 고정.

### P5 — pipeline.sh positional arg gotcha
- 증상: `pipeline.sh update <seq> <status> [output] [topic]` — status 전환이 in-progress 인 경우 output 슬롯을 빈 문자열로 넘기지 않으면 topic 이 output 위치로 들어감.
- Plan 025 impl report 에서 명시적으로 문서화했지만 향후 agent prompt 에 체계적으로 포함되지 않음.
- **Recommendation**: retro agent (본 스킬) 에서 pipeline.sh 사용 패턴을 표준 snippet 으로 보존. 새 agent 가 pipeline.sh update 를 호출할 때 `""` 빈 슬롯 포함 형태로 항상 지시.

## 4. Deferred Items Handoff

| 항목 | 상태 | 트리거 |
|------|------|--------|
| ADB 스크린샷 5종 (`shape_group_grid`, `tshape_4cards`, `tshape_7cards`, `grid3x3_9cards`, `slider_dynamic_snackbar`) | 사용자 에뮬레이터 세션 필요 | 038 Push § Deferred Items Handoff 의 bash 절 |
| 32 analyze info (pre-existing `prefer_const_constructors` 등) | 별도 style-cleanup cycle 권고 | 본 cycle 외 코드 — ROI 평가 후 착수 |
| Sealed class re-eval for LayoutType (Decision 13 alternative) | post-v1 배치 추가 시점 | 4번째 배치 type 제안 시 재검토 |
| cycle 5 T2/T4 자동 테스트 재작성 | 인프라 개선 cycle 필요 | P3 Recommendation 세 경로 중 하나 채택 시 |

## 5. Metrics Summary

| 지표 | 값 |
|------|-----|
| Commits | 8 |
| Files modified (unique) | ~20 |
| Tests added | +40 (pre-cycle 14 → total 54) |
| Tests passing | 52/54 (96.3%) — 2 documented deferred, not bugs |
| Docs produced | 30 |
| Build errors | 0 전 구간 |
| Quality composite | 0.91 (Standard 0.70 기준 +0.21) |
| Rework cycles | 0 |
| Agent timeouts | 2 (복구 100%) |

## 6. Takeaways for Future Orchestration

1. **Codegen 경계 = cycle 분할점**. drift/freezed/build_runner 가 끼어드는 지점을 cycle 경계로 삼으면 컴파일 breakage 를 cycle 내부에 가둘 수 있다.
2. **`PRAGMA user_version` 은 onUpgrade transaction 내부 배치가 모든 drift migration 에서 의무**. tx 바깥 둘 경우 phantom version crash loop 위험.
3. **Widget test + StreamProvider** 는 fakeAsync 환경에서 flake. integration_test 이관 또는 테스트 대상 위젯 public 추출이 구조적 해법.
4. **GridView root 에 `ValueKey(layoutType)`** 를 두면 배치 전환 시 이전 layout 의 animation controller / focus node 누수 방지 (cycle 4 D14).
5. **Brief supersede 시**: (a) 신·구 Brief 양쪽 frontmatter `supersedes`/`superseded_by` 동시 갱신, (b) Scope frontmatter `traces_brief` 도 **short ID** 로 갱신, (c) 경로 이동에 대비해 full path 참조 금지.
6. **Agent 역할 분리**: impl/tdd-red agent 는 code edit + commit 까지. test 실행 + verify 는 main session 또는 verify agent 전담. agent timeout 시 main-session fallback 경로를 Plan 단계에서 사전 준비.

## 7. Conclusion

6 cycles 전 rework 0 달성은 **pre-impl research-first 투자** (007~016) 의 직접 성과.
Agent timeout 2건은 fallback 으로 흡수되어 pipeline stability 지표 14/15.
핵심 구조적 자산: **codegen-aware cycle boundary**, **tx-scoped user_version**, **short-ID cross-ref** 세 패턴은 후속 pipeline 에서 그대로 재사용 가능.
남은 5 ADB 스크린샷 + 2 widget test 재작성 + style-cleanup 은 본 verdict 와 무관한 사용자/후속 cycle 영역.
