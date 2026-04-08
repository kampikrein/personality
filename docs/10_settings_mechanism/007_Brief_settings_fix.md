---
id: "007"
type: brief
title: "설정 초기화 정비 & 뽑기 상태 버그 수정"
created: 2026-04-03
status: completed
deep_critique: false
critique_docs: []
summary: >
  연구 R-006 기반. experienceLevel 기본값 3 변경, 글로벌 상태 clear() 주입,
  GoRouter 과잉 재생성 방지를 통해 처음 사용자 경험과 뽑기 흐름 안정성을 확보한다.
keywords: [UserSettings, experienceLevel, ShuffleState, clear, GoRouter, 기본값]
---

# 설정 초기화 정비 & 뽑기 상태 버그 수정

## Intent

처음 앱을 설치한 사용자가 **풀셔플 체험(Level 3)**으로 시작하도록 기본 설정을 변경하고,
"뽑기 시작" 시 이전 뽑기 결과가 보이는 버그를 수정하며,
설정 변경 시 GoRouter 과잉 재생성을 방지한다.

연구 근거: `docs/10_settings_mechanism/006_Research_settings_mechanism_final.md`

## Context

| 영역 | 현재 상태 | 관련 파일 |
|------|----------|----------|
| UserSettings entity | experienceLevel 기본값=1 | `settings/domain/entities/user_settings.dart` |
| DB 테이블 | withDefault(Constant(1)) | `settings/data/tables/user_settings_table.dart` |
| Fallback | `?? 1` (home_page, draw pages) | `home_page.dart:54`, `instant_draw_page.dart:46` 등 |
| ShuffleState | keepAlive:true, clear() 호출 0회 | `shuffle/presentation/providers/shuffle_providers.dart` |
| ReadingQuestion | keepAlive:true, clear() 호출 0회 | `shuffle/presentation/pages/intention_page.dart` |
| GoRouter | settings watch → 변경마다 재생성 | `core/router/app_router.dart:35` |

## Boundaries

### In Scope
| # | Item | Description |
|---|------|-------------|
| 1 | experienceLevel 기본값 1→3 | entity @Default, DB withDefault, fallback ?? 3계층 동시 변경 |
| 2 | shuffleStateProvider.clear() 주입 | 뽑기 진입 시 이전 상태 초기화 |
| 3 | readingQuestionProvider.clear() 주입 | 뽑기 진입 시 이전 질문 초기화 |
| 4 | GoRouter 과잉 재생성 방지 | redirect 제거 + appRouterProvider의 settings watch 제거 |
| 5 | 기존 사용자 experienceLevel 초기화 | DB migration으로 기존 행 experienceLevel=3 일괄 변경 |
| 6 | defaultSpreadType → custom | Level 3 사용자에게 자유도 제공 |
| 7 | quickDrawEnabled 토글 UI 제거 | redirect 제거 시 dead feature — settings_page.dart SwitchListTile 삭제 |
| 8 | SpreadType.custom 포지션 라벨 설계 | "카드 1/2/3" 대신 의미 있는 기본 라벨 — tarot-expert 협의 |

### Out of Scope
| # | Item | Reason |
|---|------|--------|
| 1 | quickDrawEnabled pageKey 재사용 | 현재 기본값=false, 영향 제한적. 별도 이슈 |
| 2 | InstantDrawPage showFaceUp 미참조 | 설계 의도 확인 후 별도 처리 |
| 3 | server/ 백엔드 변경 | 클라이언트 전용 이슈 |
| 4 | ~~기존 사용자 데이터 마이그레이션~~ | → In Scope #5로 이동 |

## Decisions

| # | Decision | Chosen | Rationale |
|---|----------|--------|-----------|
| 1 | experienceLevel 기본값 | **3 (풀셔플)** | 사용자 요청. 처음 사용자에게 완전한 타로 체험 제공 |
| 2 | clear() 호출 시점 | **뽑기 페이지 진입 시** | 홈 복귀 시 clear하면 뒤로가기로 결과 재확인 불가. 새 뽑기 진입 시점이 적절 |
| 3 | clear() 대상 | **shuffleState + readingQuestion 양쪽** | 이전 뽑기의 카드와 질문 모두 초기화 |
| 4 | GoRouter 재생성 방지 | **redirect 제거 + settings watch 제거** | quickDrawEnabled 기본=false, 홈의 _startDraw()가 동일 기능 제공. redirect 불필요 |
| 5 | 기존 사용자 소급 적용 | **DB migration으로 일괄 변경** | 개발 단계, 기존 사용자=개발자 본인. experienceLevel=3으로 초기화 |
| 6 | defaultSpreadType | **custom** | Level 3 사용자에게 카드 장수 자유도 제공 |
| 7 | quickDrawEnabled 토글 UI | **제거** | redirect 제거로 dead feature. 영향 평가 불필요 — 자기완결적 삭제 |
| 8 | custom 포지션 라벨 | **tarot-expert 협의** | 코드 영향은 확인 완료. 콘텐츠 결정만 미결 |

## Open Questions

| # | Question | Impact | Status |
|---|----------|--------|--------|
| 1 | ~~GoRouter 재생성 방지 방법~~ | ~~높음~~ | → Decision #4: redirect 제거 |
| 2 | ~~기존 사용자 소급 적용~~ | ~~중간~~ | → Decision #5: DB migration 일괄 변경 |
| 3 | ~~defaultSpreadType 변경~~ | ~~낮음~~ | → Decision #6: custom |

## Constraints

- **3계층 동시 변경 필수**: entity, DB table, fallback 값이 불일치하면 예측 불가 동작
- **freezed 코드젠**: entity 변경 시 `build_runner` 재실행 필요
- **Drift migration**: DB 기본값 변경은 새 행에만 적용. 기존 행은 영향 없음

## Exit Criteria

- [ ] experienceLevel 기본값 결정 (→ 3, 완료)
- [ ] clear() 호출 위치 결정 (→ 뽑기 진입 시, 완료)
- [x] GoRouter 재생성 방지 방법 결정 (→ redirect 제거)
- [x] 기존 사용자 소급 적용 여부 결정 (→ DB migration 일괄)
- [x] defaultSpreadType 변경 여부 결정 (→ custom)

## Model Anchors

1. **MA-1: experienceLevel 기본값 3**: `user_settings.dart`의 `@Default(1)` → `@Default(3)`, `user_settings_table.dart`의 `withDefault(Constant(1))` → `withDefault(Constant(3))`, 모든 `?? 1` fallback → `?? 3`. 검색: `experienceLevel.*1` 패턴으로 전수 확인.
2. **MA-2: 뽑기 진입 시 글로벌 상태 clear**: `_executeDraw()` (instant), `_startDraw()` (animated), Level 3 진입 함수 시작부에 `ref.read(shuffleStateProvider.notifier).clear()` + `ref.read(readingQuestionProvider.notifier).clear()` 2줄 추가. 이 외 위치에서는 clear하지 않음.
3. **MA-3: GoRouter 안정화**: `app_router.dart`에서 `ref.watch(userSettingsProvider)` 제거 + redirect 블록(quickDrawEnabled 분기) 전체 삭제. GoRouter는 settings에 의존하지 않는 순수 라우트 정의만 남긴다.
4. **MA-4: 기존 사용자 초기화**: Drift migration에서 `schemaVersion` 증가 + `UPDATE user_settings SET experience_level = 3`. 기존 행의 experienceLevel을 3으로 일괄 변경.
5. **MA-5: defaultSpreadType → custom**: entity @Default, DB withDefault, fallback 3계층에서 `SpreadType.threeCard` → `SpreadType.custom` 변경. MA-1과 동일 패턴으로 전수 확인.
6. **MA-6: quickDrawEnabled 토글 UI 제거**: `settings_page.dart`의 quickDrawEnabled SwitchListTile 삭제. entity/DB 필드는 유지 (별도 migration으로 추후 제거).
7. **MA-7: custom 포지션 라벨**: SpreadType.custom의 `resolvePositions()` 기본 반환값을 tarot-expert가 설계한 라벨로 교체. 현재 "카드 1/2/3" → 의미 있는 범용 타로 포지션명으로 변경.

## Critique Integration

(--deep 미적용)

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
| 25 | user-ai-exchange | 29s | 234056 |
| 26 | user-ai-exchange | 3s | 48718 |
| 27 | user-ai-exchange | 13s | 54002 |
| 28 | user-ai-exchange | 9s | 55309 |
| 29 | user-ai-exchange | 10s | 58339 |
| 30 | user-ai-exchange | 11s | 61129 |
| 31 | user-ai-exchange | 7s | 62416 |
| 32 | user-ai-exchange | 0s | 0 |
| 33 | user-ai-exchange | 10s | 63892 |
| 34 | user-ai-exchange | 22s | 67713 |
| 35 | user-ai-exchange | 9s | 69028 |
| 36 | user-ai-exchange | 21s | 215578 |
| 37 | user-ai-exchange | 174s | 517468 |
| 38 | user-ai-exchange | 418s | 1153988 |
| 39 | user-ai-exchange | 80s | 692099 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 477242s |
| Total Tokens | 4945269 |
| Input Tokens | 144 |
| Output Tokens | 35349 |
| Cache Read | 4169536 |
| Cache Creation | 740240 |
