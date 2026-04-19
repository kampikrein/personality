---
id: "017"
type: plan
title: "Cycle 3 실행 계획 — 설정 기본값 변경"
created: 2026-04-01
traces_brief: "007"
traces_scope: "014"
traces_research: "013"
summary: >
  experienceLevel 기본값 1→3, defaultSpreadType threeCard→custom, DB migration schemaVersion 2→3.
  3계층(entity @Default / DB withDefault / fallback ??) 동시 변경 + build_runner 재실행.
keywords: [experienceLevel, defaultSpreadType, migration, build_runner, defaults]
---

# Cycle 3 실행 계획 — 설정 기본값 변경

## 목표

Brief 007 MA-1, MA-4, MA-5 구현:
- experienceLevel 기본값 1 → 3 (풀셔플 기본 체험)
- defaultSpreadType threeCard → custom (자유도 제공)
- DB migration으로 기존 사용자 행 일괄 업데이트

## 사전 조건

- Cycle 1 (GoRouter 정리): 완료 여부 확인 불필요 (독립 사이클)
- Cycle 2 (State clear 주입): instant_draw_page, animated_draw_page에 clear() 이미 삽입 확인됨

## 변경 파일 목록

| # | 파일 | 변경 내용 |
|---|------|---------|
| 1 | `settings/domain/entities/user_settings.dart` | @Default(1)→@Default(3), @Default(SpreadType.threeCard)→@Default(SpreadType.custom) |
| 2 | `core/database/tables/user_settings_table.dart` | withDefault(Constant(1))→withDefault(Constant(3)), 'threeCard'→'custom' |
| 3 | `core/database/app_database.dart` | schemaVersion 2→3, onUpgrade(from<3) UPDATE 쿼리 추가 |
| 4 | `home/presentation/pages/home_page.dart:54` | ?? 1 → ?? 3 |
| 5 | `draw/presentation/pages/instant_draw_page.dart:47` | ?? SpreadType.threeCard → ?? SpreadType.custom |
| 6 | `draw/presentation/pages/animated_draw_page.dart:54` | ?? SpreadType.threeCard → ?? SpreadType.custom |

## 검증된 fallback 위치

grep 결과 `?? 1` / `?? SpreadType.threeCard` 출현:
- `home_page.dart:54` — experienceLevel fallback
- `instant_draw_page.dart:47` — defaultSpreadType fallback
- `animated_draw_page.dart:54` — defaultSpreadType fallback
- `user_settings.g.dart` — build_runner 자동 재생성 대상, 수동 변경 불필요

## DB Migration 전략

```
schemaVersion: 2 → 3
onUpgrade(from < 3):
  UPDATE user_settings SET experience_level = 3, default_spread_type = 'custom'
```

- 기존 행: experienceLevel=1 → 3, defaultSpreadType='threeCard' → 'custom' 일괄 변경
- 신규 행: withDefault 변경으로 자동 적용
- 실패 시 crash 없음 (Drift fallback), 설정 고착만 발생

## 실행 순서

1. `user_settings.dart` — entity @Default 변경
2. `user_settings_table.dart` — DB withDefault 변경
3. `app_database.dart` — schemaVersion + onUpgrade 추가
4. `home_page.dart` — fallback ?? 3
5. `instant_draw_page.dart` — fallback ?? SpreadType.custom
6. `animated_draw_page.dart` — fallback ?? SpreadType.custom
7. `dart run build_runner build --delete-conflicting-outputs`
8. `dart analyze`

## 리스크

- **[High] SpreadType.custom 포지션 라벨**: "카드 1/2/3" generic 라벨. tarot-expert 협의 필요 (별도 사이클).
- **[Medium] build_runner 실패**: freezed 코드젠 충돌 시 --delete-conflicting-outputs 옵션으로 해결.
- **[Low] DB migration UPDATE 범위**: user_settings 테이블 전체 행 업데이트. 개발 단계이므로 기존 사용자=개발자 본인.

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
| 40 | user-ai-exchange | 56s | 453585 |
| 41 | user-ai-exchange | 134s | 1054142 |
| 42 | user-ai-exchange | 587s | 979519 |
| 43 | user-ai-exchange | 44s | 619876 |
| 44 | user-ai-exchange | 451s | 4893580 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 479586s |
| Total Tokens | 12945971 |
| Input Tokens | 197 |
| Output Tokens | 67463 |
| Cache Read | 12030837 |
| Cache Creation | 847474 |
