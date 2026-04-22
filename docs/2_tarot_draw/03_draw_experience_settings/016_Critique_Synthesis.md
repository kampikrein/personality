---
id: "016"
type: synthesis
title: "Brief 011 Deep Critique 통합 — 4 관점 Synthesis"
created: 2026-04-20
status: completed
target: "011"
sources: ["012", "013", "014", "015"]
summary: >
  Feasibility / Scope Balance / Risk / Alternatives 4 관점 비평 통합. Critical
  발견 3건(Context 누락, PRAGMA user_version 크래시 시나리오, drift_schemas
  선행 존재), Major 7건, Minor 8건. Brief 011의 골조는 건재하나 6~8개 섹션에서
  정정·보강 필수. Scope 006도 2건 정정 필요 (traces_brief 경로 stale,
  cascading rename 누락).
keywords: [synthesis, critique, brief-011, feasibility, scope, risk, alternatives]
---

# Brief 011 Deep Critique 통합 — 4 관점 Synthesis

## 비평 문서 현황

| 관점 | Doc | Verdict | 발견 |
|------|-----|---------|------|
| Technical Feasibility | 012 | Actionable, confidence: high | 15 Weaknesses (2 critical / 5 major / 8 minor) + 7 Missing |
| Scope Balance | 013 | Actionable, confidence: high | 8 Weaknesses + 7 Missing |
| Risk | 014 | Actionable, confidence: high | 14 Risks (2 critical / 4 major / 8 minor) |
| Alternatives | 015 | Mostly confirmed | Strong 12 / Toss-up 3 / Weak 2 (D4, D13) |

## 공통 발견 (2+ 관점이 동일 지적)

### C1 — Context § SpreadType 참조 분포 표의 누락 [Critical]

**지적한 관점**: Feasibility (W1, W2, W5), Scope Balance (W5, W7), Risk (R9)

**누락 레이어**:
1. **UserSettings 도메인 전체**
   - `user_settings.dart:19` — `defaultSpreadType` Freezed 필드
   - `user_settings.g.dart:16-18, 49-53` — 별도 `_$SpreadTypeEnumMap` (두 번째 복제본)
   - `user_settings_repository_impl.dart:113` — `SpreadType.values.byName(...)` Repository 변환
   - `settings_providers.dart` — `updateDefaultSpreadType` 프로바이더
2. **Draw pages 2개 (가장 위험)**
   - `animated_draw_page.dart:29, 53-54` — `late SpreadType _spreadType; _spreadType.cardCount`
   - `draw_result_page.dart:29, 53-56, 133-146, 269-276` — 동일 + `_addOneMore`/`+N장` 버튼
   - **특히 `.cardCount` 직접 호출은 LayoutType API와 계약 불일치** (LayoutType은 `cardCount` 게터 없음)
3. **home_page.dart `_PillSelector<SpreadType>` (456~464)**
   - In Scope #4가 "3-group restructure"로 기술하지만 실제로는 **widget option 교체 + block relocation** 이 추가 작업

**영향**: In Scope #1, #4, #7 모두 과소 기술됨. impl 사이클 3이 과중.

### C2 — Drift `PRAGMA user_version` 트랜잭션 외부 실행 [Critical]

**지적한 관점**: Risk (R1, R6)

**메커니즘** (drift `engines.dart:485-521` + `versioned_schema.dart:114`):
```
1. onUpgrade 블록 내 transaction 실행 → COMMIT
2. transaction 외부에서 setSchemaVersion(8) 호출 (별도 PRAGMA user_version = 8)
3. 만약 1과 2 사이에 프로세스 강제 종료되면:
   - DB 스키마는 v8 형태 (columns renamed, values 변환됨)
   - PRAGMA user_version = 7 (미갱신)
4. 다음 실행 시 onUpgrade(from=7) 재실행
5. ALTER TABLE ... RENAME COLUMN default_spread_type TO default_layout_type 실행
   → `no such column: default_spread_type` (이미 rename된 상태)
6. 앱 시작 실패 (영구 crash loop)
```

**Brief 011 Decision 5/16에 누락됨**. 해결: `PRAGMA user_version = 8`을 transaction 블록 **내부에** 추가 — transaction과 함께 원자적으로 commit.

### C3 — `drift_schemas/v7` 이미 커밋됨 [Critical]

**지적한 관점**: Feasibility (Pleasant surprise #1), Scope Balance (W1), Risk (R5)

**사실 확인**:
- `mobile/drift_schemas/drift_schema_v7.json` (commit `5a62332 feat: mobile/drift_schemas`, 4월 20일 00:43)
- `mobile/test/generated_migrations/schema.dart` + `schema_v7.dart` 이미 존재

**Brief 011 In Scope #10 정정 필요**:
- ❌ "schema dump → git commit → schema generate → test 작성 → 검증" 5단계 미래 작업
- ✅ "test 작성 + 검증"만 남은 작업. dump/generate는 완료

**추가 위험 (R5)**: 다른 개발자가 `drift_dev schema dump` 재실행 시 출력 비결정성 가능성 — 드물지만 false-positive git diff 원인이 될 수 있음.

### C4 — `resolvePositions` / `resolveGuidances` 계약 불일치 [Major]

**지적한 관점**: Feasibility (W structural), Scope Balance (W2)

**현황**:
- `spread_type.dart:39-51` — 현재 `SpreadType`에 두 메서드가 존재, `this != SpreadType.custom` 분기 + `positions` final 필드 사용
- R-009 prototype (line 426) + `reading_detail_page.dart:76` — `layoutType.resolvePositions(cardCount)` 호출
- Brief 011 In Scope #1 method list: `slotCount`, `emptySlots`, `drawToSlot` 만 명시 — `resolvePositions`/`resolveGuidances` 빠짐
- Decision 8: "generic 라벨 자동 생성 (`'카드 1'`...)"

**계약 충돌**: 호출자는 위치별 라벨 리스트를 기대하지만 LayoutType에 메서드 정의가 없다. **In Scope #1에 두 메서드 추가 + 구현은 generic 라벨 생성자로 기본값** 필요.

### C5 — `byName` ArgumentError 방어 부재 [Major]

**지적한 관점**: Risk (R3)

Repository는 `SpreadType.values.byName(row.spreadType)` 패턴 사용 (`reading_repository_impl.dart:98`, `user_settings_repository_impl.dart:113`). 마이그레이션 중 legacy 값(single/threeCard/custom) 이 남아있다면 ArgumentError throw → 앱 크래시.

**해결**: 
```dart
LayoutType.values.firstWhere(
  (e) => e.name == row.spreadType,
  orElse: () => LayoutType.linear,
)
```

**Brief 011 추가 결정 필요** (신규 Decision).

### C6 — cascading rename scope 과소 [Major]

**지적한 관점**: Feasibility (W), Scope Balance (W6, M1), Alternatives (관련)

`UserSettings.defaultSpreadType` → `defaultLayoutType` 은 필드명 rename. 그러나 `Reading.spreadType` 필드명은 유지. 이 **비대칭을 명시적으로 결정** 하지 않아 impl 에이전트가 헷갈릴 수 있다.

**현황**: Brief 011 Decision 6은 UserSettings만 다룸. Reading은 Context 표의 "컬럼명 유지, 값만 변환" 각주로만 처리.

**해결**: 신규 Decision으로 승격.

## 상충 발견

### X1 — D13 (enhanced enum) 평가 상충

- **Feasibility 012 + Risk 014**: R-007 결과에 따라 "호환됨" 인정, 유지
- **Alternatives 015 — Weak**: "호환됨"이 "최적임"을 보장하지 않음. Dart 3 sealed class 가 (a) `failures.dart` 선례, (b) nullable `cardsPerRowOverride` 제거, (c) per-subclass state, (d) 확장성에서 우세

**종합 판단**: sealed class가 구조적으로 더 깨끗하지만 **본 작업에서 flip 비용 > 이득**:
- 사이클 1 구현이 이미 007 prototype 기준으로 설계됨
- Freezed/Drift 직렬화 경로 재검증 필요 (sealed class의 `runtimeType` 직렬화는 별도 패턴)
- 미래 배치 추가 시점에 재평가 가능 (enum → sealed class 마이그레이션은 1 cycle로 작음)

→ **Decision 13 유지 + Alternatives 섹션에 sealed class 기록** (post-v1 재평가 플래그).

### X2 — D4 (silent auto-reset) 평가 상충

- **Feasibility 012 + Risk 014**: 기술적 실현 가능, 이상 없음
- **Alternatives 015 — Weak**: 사용자가 "왜 슬라이더가 갑자기 리셋되지?" 당황 가능. 1-step undo Snackbar 권고 (10줄 구현)

**종합 판단**: UX 개선 효과가 비용보다 크다 — Snackbar undo는 Scaffold.messenger 한 번 호출 + `SnackBarAction(label: '이전 값 복원')` 수준.

→ **Decision 4 보강**: Snackbar undo 기본값으로 채택. Model Anchors에 UX 규격 추가.

## 고유 발견

### U1 — Pipeline folder path stale (Feasibility)

**영향 범위**: Scope 006, Plan 004 (가능성), Brief 002 (가능성)

`traces_brief: "docs/15_draw_experience_settings/005_Brief_layout_redesign.md"` — 실제 폴더는 `docs/2_tarot_draw/03_draw_experience_settings/` (commit 9d11a36에서 재구조화됨).

**Brief 011은 short ID `"005"` 사용** → 영향 없음. **Scope 006 정정 필요** (Brief 011 작업 외).

### U2 — `_addOneMore` / "+N장" 버튼 잔존 (Scope Balance, Feasibility)

`draw_result_page.dart:133-146, 269-276` — Decision 9는 "결과 페이지 +1 버튼 없음" 이라 선언하지만 **제거 명시가 In Scope에 없음**.

**해결**: In Scope #9 description에 "기존 `_addOneMore` 메서드 + `+N장` 버튼 삭제" 명시.

### U3 — `cardsPerRow` DB 저장 정책 (Feasibility)

`user_settings_table.dart:27-28` — `cardsPerRow` nullable int. tShape/grid3x3 선택 시 회색 비활성 + 값 3 고정 인데:
- 사용자가 linear 2장으로 설정 → grid3x3 전환 시 cardsPerRow=3 강제 → DB에 3 쓰는지, 원래 2 유지하는지?
- grid3x3 → linear 복귀 시 cardsPerRow가 2로 복구되는지?

**미결 정책**. Decision 4의 "이전 값 보존 안 함" 과 일관성 있게 "강제값 그대로 DB 저장" 으로 해석 가능.

→ Model Anchors에 명시.

### U4 — IntColumn 전환 (Alternatives M-2)

`decks_table.dart:15`, `readings_table.dart:14`, `cards_table.dart:20` — 이미 `intEnum<SyncStatus>()` 패턴 사용 중. R-007-F5가 "변경 표면 최소화" 로 기각했지만 **이번 작업 자체가 컬럼 rename + 값 변환** 이라 최소화 논거가 약함.

**판단**: Brief 011은 기존 TextColumn 유지 결정 보존 (migration 중복 부담 회피). **Decision 13 또는 신규 Decision의 Alternatives에 기록** — "IntColumn + intEnum<LayoutType>() 전환은 future cycle 재평가 대상".

### U5 — 크래시 복구 테스트 추가 (Risk)

Brief 011의 idempotency 테스트 케이스 3 ("v8 상태에서 migrateAndValidate(db, 8) no-op") 은 C2 시나리오를 **커버하지 않음**. 필요한 추가 테스트:

> **Case 4 — Phantom v7.5 recovery**: v7 DB에 single/threeCard reading 삽입 → 트랜잭션까지 완료된 상태 수동 시뮬레이션 (user_version=7 + 스키마는 v8) → AppDatabase 재오픈 → migrateAndValidate(db, 8) → 컬럼 이미 renamed 상태에서 rename 재시도 ArgumentError 검증 또는 graceful skip

### U6 — Cycle 3 과중 (Scope Balance W8)

Cycle 1: 6 파일 / Cycle 2: 7 파일 (그중 snapshot/generate 이미 완료 → 실제 ~3) / Cycle 3: 9 파일 + 위젯 2 신규 + 테스트 1 + 스크린샷 5종.

**제안 분할** (Scope 006 수정 권고, Brief 외 작업):
- 3a: LayoutType 매핑 단위 테스트 + SpreadLayout + _EmptySlotPlaceholder + _DashedRectPainter (렌더링 인프라)
- 3b: home_page `_DrawSettingsPanel` 재구성 + cardCount 자동 조정 + 3x3 드로우 순서 메뉴
- 3c: reading_list/detail 호환 + draw_result 버튼 제거 + 스크린샷 5종

## 우선순위 정렬

| 우선 | 발견 | 반영 섹션 |
|------|------|----------|
| P0 | C1 (Context 표 누락) | Context § SpreadType 참조 분포 |
| P0 | C2 (PRAGMA user_version 크래시) | Decision 5, 16 / Model Anchors / Constraints / Ideal Criteria (+Case 4) |
| P0 | C3 (drift_schemas 선행 커밋) | In Scope #10 (정정) + Decision 17 |
| P1 | C4 (resolvePositions 누락) | In Scope #1 메서드 목록 + 신규 Decision |
| P1 | C5 (byName 방어) | 신규 Decision + Constraints / Repository 패턴 |
| P1 | C6 (cascading rename 비대칭) | 신규 Decision (Reading 필드명 유지 공식화) |
| P2 | D4 Snackbar undo | Decision 4 보강 + Model Anchors |
| P2 | U2 (_addOneMore 버튼 제거) | In Scope #9 + Decision 9 |
| P2 | U5 (crash recovery test) | Constraints 테스트 목록 + Ideal Criteria |
| P2 | U6 (cycle 3 분할) | Scope 006 권고 (Brief 밖) |
| P3 | X1 (sealed class) | Decision 13 Alternatives 섹션 기록만 |
| P3 | U3 (cardsPerRow DB) | Model Anchors 한 줄 추가 |
| P3 | U4 (IntColumn) | Decision 13 Alternatives 기록 |

## 상호 참조

- [012_Critique_Feasibility.md](./012_Critique_Feasibility.md)
- [013_Critique_ScopeBalance.md](./013_Critique_ScopeBalance.md)
- [014_Critique_Risk.md](./014_Critique_Risk.md)
- [015_Critique_Alternatives.md](./015_Critique_Alternatives.md)
- [011_Brief_layout_redesign.md](./011_Brief_layout_redesign.md) (보강 대상)
- [006_Scope_layout_redesign.md](./006_Scope_layout_redesign.md) (U1, U6 정정 권고)

## 종합 권고

**Brief 011**: P0~P1 (6건) 반드시 반영, P2 (4건) 반영 권장, P3 (3건) 기록만.
**Scope 006**: U1 (traces_brief 경로) + U6 (cycle 3 분할) 권고 — 별도 사이클.
**Impl phase 재개 전제**: Brief 011 보강 완료 + crash recovery 테스트 케이스 Ideal Criteria 포함 확인.

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 0s | 0 |
| 2 | user-ai-exchange | 451s | 935162 |
| 3 | user-ai-exchange | 1554s | 4275267 |
| 4 | user-ai-exchange | 49s | 210710 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 31057s |
| Total Tokens | 5421139 |
| Input Tokens | 59 |
| Output Tokens | 77155 |
| Cache Read | 4817779 |
| Cache Creation | 526146 |
