topic: layout_redesign
scope: docs/2_tarot_draw/03_draw_experience_settings/017_Scope_layout_redesign.md
brief: docs/2_tarot_draw/03_draw_experience_settings/011_Brief_layout_redesign.md
session_id: (auto)
auto_run: true
effort_mode: standard
tdd_mode: true
orchestrator_active: true
supersedes_scope: "006"
impl_cycles: 6

# Research Phase: 이미 완료 (docs/007, 008, 009, 010). 생략.
# tdd-red 선행, standard effort, --run auto_run.
# 각 cycle 의 agent 는 Brief 011 + 해당 Plan 만 로드 (context overflow 방지)

[cycle-1] tdd-red       | (pending)  # LayoutType enum + Reading 레이어
[cycle-1] makeplan      | (pending)
[cycle-1] implementation| (pending)
[cycle-1] verify        | (pending)

[cycle-2] tdd-red       | (pending)  # UserSettings 레이어 + Repository fallback
[cycle-2] makeplan      | (pending)
[cycle-2] implementation| (pending)
[cycle-2] verify        | (pending)

[cycle-3] tdd-red       | (pending)  # DB 마이그레이션 v7→v8 (phantom v7.5 crash recovery 포함)
[cycle-3] makeplan      | (pending)
[cycle-3] implementation| (pending)
[cycle-3] verify        | (pending)

[cycle-4] tdd-red       | (pending)  # 렌더링 인프라 (GridView + CustomPaint)
[cycle-4] makeplan      | (pending)
[cycle-4] implementation| (pending)
[cycle-4] verify        | (pending)

[cycle-5] tdd-red       | (pending)  # 홈 패널 UI + cardCount 자동 조정 + SnackBar undo
[cycle-5] makeplan      | (pending)
[cycle-5] implementation| (pending)
[cycle-5] verify        | (pending)

[cycle-6] tdd-red       | (pending)  # 주변 호환 + 버튼 제거 + ADB 스크린샷 5종
[cycle-6] makeplan      | (pending)
[cycle-6] implementation| (pending)
[cycle-6] verify        | (pending)

[tail]    eval          | (pending)  # structural-gap 시 add-cycle 가능
[tail]    qualify       | (pending)
[tail]    push          | (pending)
[tail]    retro         | (pending)
