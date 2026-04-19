---
id: "010"
type: synthesis
title: "Research Synthesis — Layout Redesign 3 Axes 통합"
created: 2026-04-19
traces_scope: "006"
traces_brief: "005"
sources: ["007", "008", "009"]
summary: >
  3개 Research axis 모두 SUFFICIENT (depth_score 92~95). Brief 005 Critical
  Review 3건 모두 해소되었고 fallback 발동 불필요. 한 가지 Brief 가정 정정
  필요 — schemaVersion은 v1→v2가 아니라 v7→v8 (기존 6 사이클 누적). impl
  3 사이클 모두 prototype 코드 확보 상태로 진행 가능.
keywords: [synthesis, layout, research-summary, brief-correction]
---

# Research Synthesis — Layout Redesign 3 Axes 통합

## Cross-Cycle Status

| Cycle | Axis | Doc | Verdict | Depth | Brief CR 해소 |
|-------|------|-----|---------|-------|--------------|
| 1 | enhanced-enum-codegen | 007 | SUFFICIENT | 95 | CR#3 ✓ |
| 2 | drift-migration-pattern | 008 | SUFFICIENT | 92 | CR#1 ✓ |
| 3 | slot-based-rendering | 009 | SUFFICIENT | 94 | (구현 가이드) |

3 axes 모두 핵심 질문이 코드/문서/이슈 트래커 증거로 해소되었고, impl 사이클별
prototype 코드가 준비되었다.

## 통합 핵심 발견 (Brief 005 → impl 사이클 영향)

### 1. fallback 발동 없음 — Brief Decisions 그대로 유지

| Brief Decision | Research 검증 결과 | 영향 |
|---------------|------------------|------|
| Decision 5 (DB migration v1→v2) | R-008: 표준 패턴 확보, **단 v1→v2가 아니라 v7→v8** | 코드 차이 없음 (if-block 가드만 v8 기준), 문구 정정 |
| Decision 6 (defaultSpreadType → defaultLayoutType) | R-008: SQLite 3.25+ ALTER RENAME COLUMN 지원 (sqlite3_flutter_libs 충분 최신) | 그대로 |
| Decision 13 (enhanced enum + computed properties) | R-007: 호환성 확인, fallback (별도 LayoutDefinition 클래스) 불필요 | enhanced enum 유지 |

### 2. 추가 도메인 명세 (impl 사이클 1에서 LayoutType API에 반영)

R-009-F5에 따라 LayoutType의 메서드 시그니처는 Brief 005 prototype 그대로 유지
(slotToDraw 같은 추가 메서드 불필요):
- `cardCountMin`, `cardCountMax`, `defaultCardCount`, `cardsPerRowOverride` (final)
- `displayName` (final)
- `drawToSlot(int drawIndex, int cardCount) → int`
- `emptySlots(int cardCount) → Set<int>`
- `slotCount(int cardCount) → int`

Builder에서 한 번 역매핑 (`slotToDraw[slot] = drawIdx`) 후 GridView itemBuilder
가 O(1) 조회 (R-009-F3).

### 3. impl 사이클별 prerequisite 명세

**사이클 1 (도메인 모델 진화)**:
- R-007 prototype (LayoutType enhanced enum, drawToSlot 매핑 표) 그대로 적용
- build_runner 실행 후 `_$LayoutTypeEnumMap` 자동 생성 확인 + 단위 테스트 통과
  → confirmation gate

**사이클 2 (DB 마이그레이션)**:
- 사이클 시작 전 prerequisite 6 단계 (R-008 결론):
  1. `dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/`
  2. `git add drift_schemas/ && git commit`
  3. `dart run drift_dev schema generate --data-classes --companions drift_schemas/ test/generated_migrations/`
  4. `app_database.dart` schemaVersion 7 → 8 + onUpgrade if-block 추가
  5. `mobile/test/database/migration_v7_to_v8_test.dart` 작성
  6. `dart test test/database/migration_v7_to_v8_test.dart` 통과 확인
- 마이그레이션 코드 prototype: R-008 "v7 → v8 마이그레이션 Prototype" 섹션 그대로

**사이클 3 (UI 통합)**:
- R-009 prototype (GridView + _EmptySlotPlaceholder + _DashedRectPainter) 그대로 적용
- `spread_layout.dart` 전면 재작성 (107 lines → 비슷한 규모)
- `card_reveal_widget.dart` 변경 없음
- 단위 테스트: LayoutType 매핑 매트릭스 + cardCount 자동 조정

## Brief 005 정정 사항

Brief 005 Decision 5에 한 줄 메모 추가 권장:
> ※ R-008-F1 정정: 실제 schemaVersion은 v7 (현 시점). 마이그레이션은 v7→v8.
>   기존 6 사이클의 customStatement 패턴 그대로 확장.

## Impl Phase 진행 가능 여부

✅ **모든 prerequisite 충족**:
- Brief Critical Review 3건 모두 해소
- 사이클별 prototype 코드 준비
- 의존성 분석 완료 (사이클 1 → 2 → 3 순차)
- 테스트 패턴 정립 (Drift migration, LayoutType 매핑, cardCount 조정)

→ Impl Phase init (gate가 수행) 후 사이클 1 (tdd-red → makeplan → impl → verify)
   디스패치 가능.

## Referenced Documents

- [007_Research_enhanced_enum_codegen.md](./007_Research_enhanced_enum_codegen.md)
- [008_Research_drift_migration_pattern.md](./008_Research_drift_migration_pattern.md)
- [009_Research_slot_based_rendering.md](./009_Research_slot_based_rendering.md)
- [005_Brief_layout_redesign.md](./005_Brief_layout_redesign.md)
- [006_Scope_layout_redesign.md](./006_Scope_layout_redesign.md)

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 117s | 344643 |
| 2 | user-ai-exchange | 235s | 1232689 |
| 3 | user-ai-exchange | 213s | 1123755 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 3776s |
| Total Tokens | 2701087 |
| Input Tokens | 47 |
| Output Tokens | 41487 |
| Cache Read | 2543784 |
| Cache Creation | 115769 |
