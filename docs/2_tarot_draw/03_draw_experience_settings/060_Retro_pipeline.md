---
id: "060"
type: retro
status: completed
pipeline: intent_placement_setting
---

# Retro — intent_placement_setting

Brief 040 → Scope 041 → 4 cycles (data layer, settings UI, flow integration, guide doc) → eval/qualify/push 완료. Final commit 6d92fae, qualify 92/100, eval depth 88 (COMPLETE).

## What Worked

- **Brief 040의 8개 사전 결정**이 intent-clarification 라운드를 0회로 만들었음. 파이프라인 전 구간에서 scope/의도 재질의가 한 번도 발생하지 않음.
- **Cycle 1 (데이터 레이어)**: 한 번의 이터레이션으로 깨끗하게 안착. UserSettings 확장 + 마이그레이션 + provider 배선이 계획대로 수렴.
- **TDD-red가 선행 설계가 놓친 버그를 드러냄**: `_questionController` 시딩 관련 누락을 cycle 1 red 단계에서 발견. Brief/Scope가 예측하지 못한 엣지였음.
- **Eval 1회 + qualify 92점**으로 tail chain이 재작업 없이 통과. 파이프라인 구성(4 cycles, tdd_mode)이 과/부족 없이 적정했다는 신호.
- **Guide doc cycle(4)을 별도 분리**한 결정이 효과적. 구현 드리프트를 문서에 반영할 수 있는 전용 지점을 확보.

## Friction Points

- **Cycle 1 verify 중단**: 사전 존재한 T4 실패(layout_redesign 파이프라인 잔여)에 verify 에이전트가 triage하느라 흐름이 일시 정지. 파이프라인 경계 밖 실패를 구분하는 규약이 없었음.
- **Cycle 2 impl**: SingleChildScrollView 내부 위젯 테스트에서 tap 전 `ensureVisible` 필요. widget test 관례가 plan에 없어 impl 단계에서 추가.
- **Cycle 3 tdd-red 간소화**: DrawResultPage 위젯 mock이 과중해서 full widget integration red가 비실용적. predicate-extraction helper로 다운그레이드하여 red 피드백 유효성 확보.
- **Cycle 3 impl 1차 실패**: IntentionPage redirect에서 `valueOrNull`이 AsyncLoading 동안 null 반환 → 첫 진입 시 오판. `initState` 기반 → `build + whenData` 패턴으로 재작성하여 loading 상태 명시 처리.
- **Push agent 중도 API 에러**: 세션 내 API 오류로 일시 중단, 수동 재개. 파이프라인 상태는 멱등적으로 복구됨.

## Emergent Learnings

- **StreamProvider 기반 settings는 AsyncLoading을 명시적으로 처리해야 함**. `valueOrNull` fallback은 "값 없음"과 "로딩 중"을 구분 못 해서 분기 로직에서 오동작. 분기 코드는 반드시 `when`/`whenData` 패턴으로 loading state를 따로 처리.
- **Widget test (SingleChildScrollView 내부)**: tap 전 `tester.ensureVisible(finder)` 관용구가 필요. Plan 단계에서 체크리스트 항목으로 포함할 가치 있음.
- **TDD-red는 predicate helper로 드롭 가능**: 위젯 통합이 과도하게 얽혀 있을 때 predicate-extraction으로 내려가면 red 피드백의 유용성을 유지하면서 scaffold 비대화를 막을 수 있음. "red가 실행 가능해야 의미가 있다" 원칙.
- **Guide doc은 plan이 아니라 실제 코드 기준으로 검증**: 구현은 plan에서 드리프트한다(예: initState→build 패턴 전환). Guide의 코드 참조는 post-impl에 맞춰 정합해야 함. Cycle 4가 이 정합 작업 전용인 설계가 맞았음.

## Follow-up Candidates

- **DrawResultPage `_questionController` beforeShuffle 시딩**: 현재 프로덕션 코드는 `readingQuestionProvider`에서 beforeShuffle 모드용 seed를 하지 않음. 실제로 Lv1은 beforeShuffle 경로가 없고 Lv3/4 beforeShuffle은 AnimatedDrawPage 경유라 현 시점 문제 없음. 다만 방어적 시딩을 추가하면 로버스트니스 향상 가능 — 별도 태스크로 분리.
- **선행 존재 실패 정리**: `migration_v7_to_v8` T1-T4, `draw_settings_panel` T2/T4는 layout_redesign 파이프라인 소관. 별도 cleanup 파이프라인에서 처리 권장.
- **Pipeline 경계 규약**: verify 에이전트가 현재 파이프라인 밖 실패를 만났을 때 "기존 실패로 주석 + skip"하도록 verify protocol에 규약 추가 고려.

## Numeric Summary

| 항목 | 값 |
|---|---|
| Cycles | 4 (tdd_mode=true, 3 TDD cycles + 1 guide cycle) |
| Pipeline items | 19 (all done) |
| Tests added | ~30+ |
| Commits | 6 (bb52950, ae72da3, 42e5339, 4d38d0e, push fixes, 6d92fae) |
| Qualify score | 92/100 |
| Eval depth | 88 (COMPLETE) |
| Eval rounds | 1 |
| Intent clarification rounds | 0 |
