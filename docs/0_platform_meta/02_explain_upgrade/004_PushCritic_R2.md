---
type: push-critic
target: "docs/Explanation/mobile/lib/features/draw/presentation/_overview.md"
checkpoint: "docs/Explanation/mobile/lib/features/draw/presentation/010_PushCheckpoint.md"
round: 2
scores: { function: 2.5, edge: 2, ux: 2, robustness: 2, completeness: 2 }
depth_score: 4.2
---

# Critic 보고서 — Round 2

## Scores (Round 1 대비 변화)
| 축 | R1 | R2 | 변화 근거 |
|----|----|----|----------|
| Function | 2 | 2.5 | mermaid 2개 + 비교 표 추가로 시각화 요구 부분 충족 |
| Edge | 2 | 2 | 변동 없음 |
| UX | 1 | 2 | mermaid 전환으로 큰 폭 개선. 단, 흐름도에 Lv1 진입점 누락, 의존성/주의사항 개선 여지 |
| Robustness | 2 | 2 | 변동 없음 |
| Completeness | 2 | 2 | Lv3/4 추가됐으나 Lv1 직접 진입이 흐름도에서 암묵적 |

## Findings

### UX-R2-01 — Lv1 직접 진입 경로가 mermaid 흐름도에서 누락
- **severity**: major
- **status**: fail
- **evidence**: _overview.md 63~95행 mermaid flowchart
- **detail**: 흐름도에 Lv2(AnimatedDrawPage→DrawResultPage)와 Lv3/4(ShufflePage→DrawResultPage) 진입은 화살표로 표시되지만, Lv1(HomePage→DrawResultPage 직접 진입)은 진입 화살표가 없다. DrawResultPage 내부의 `B1 -->|false| B3["자체 셔플"]`로 간접 표현되지만, 진입점 자체가 누락되어 "어디서 오는가"를 알 수 없다. 3개 경험 레벨의 진입 경로를 모두 보여주는 것이 overview의 역할.
- **fix_suggestion**: mermaid에 HomePage 진입 노드 추가:
```mermaid
    HomePage["HomePage\n(Lv1 직접 진입)"] -->|"context.push\n('/draw/result')"| B1
```
HomePage 스타일을 ShufflePage와 동일한 외부 노드 색상(연한 녹색 등)으로 구분.
- **🏷 gate_verdict**: 동의
- **🏷 gate_reason**: "3개 경험 레벨의 진입 경로를 모두 보여주는 것이 overview 흐름도의 본질적 요건. HomePage는 draw/ 외부이므로 ShufflePage처럼 외부 노드 스타일 적용."

### UX-R2-02 — 의존성 테이블이 조감도 mermaid와 부분 중복
- **severity**: minor
- **status**: fail
- **evidence**: _overview.md 20~36행(조감도) vs 107~115행(의존성 테이블)
- **detail**: 조감도 mermaid의 4개 화살표(shuffle, deck, settings, reading)와 의존성 테이블의 상위 4행이 동일 정보. 독자가 같은 정보를 두 번 읽게 됨. 의존성 테이블은 mermaid가 담지 못하는 정보(구체적 provider 이름, 외부/SDK 의존성)에 집중해야 차별화됨.
- **fix_suggestion**: 의존성 테이블을 두 그룹으로 재구조화:

| 구분 | 대상 | 구체적 provider/심볼 |
|------|------|---------------------|
| 셔플 엔진 | `shuffle/` | `shuffleStateProvider`, `shuffleDeckUseCaseProvider`, `shuffleStrategyProvider` |
| 덱 데이터 | `deck/` | `deckCardsProvider`, `deckRepositoryProvider` |
| 사용자 설정 | `settings/` | `userSettingsProvider`, `cardAspectRatioProvider` |
| 저장·렌더 | `reading/` | `readingRepositoryProvider`, `readingQuestionProvider`, `SpreadLayout` |

| 외부 의존성 | 용도 |
|-----------|------|
| `go_router` | 페이지 간 네비게이션 |
| `TickerProviderStateMixin` | AnimatedDrawPage 애니메이션 vsync |
| `uuid` | Reading ID 자동 생성 |

이렇게 하면 조감도(어떤 피처에서 오는가)와 테이블(구체적으로 어떤 심볼인가)이 서로 다른 정보를 제공.
- **🏷 gate_verdict**: 동의
- **🏷 gate_reason**: "internal 의존성을 구체 provider 이름으로 풀어주면 코드 검색 시 즉시 활용 가능. 조감도와의 역할 분리가 명확해짐."

### UX-R2-03 — 주의사항이 텍스트 bullet만으로 구성, 시각적 강조 부재
- **severity**: minor
- **status**: fail
- **evidence**: _overview.md 117~121행
- **detail**: 3개 주의사항이 모두 동일한 bullet 형태. 심각도/영향도 구분이 없어 어떤 것이 가장 중요한지 한눈에 판단 불가. 핵심 경고("셔플 로직 3중 분산")가 매몰됨.
- **fix_suggestion**: 테이블로 전환:

| 주의사항 | 영향 범위 | 심각도 |
|---------|----------|-------|
| domain/data 부재 | 아키텍처 전체 | 설계 제약 |
| 셔플 로직 3중 분산 | 변경 시 3파일 동기화 | 유지보수 위험 |
| `shuffleStateProvider` 의존 | pages/ 전체 | 변경 영향 |

- **🏷 gate_verdict**: 동의
- **🏷 gate_reason**: "심각도 컬럼 추가로 '셔플 로직 3중 분산'이 가장 중요한 주의사항임을 시각적으로 강조."

### FUNC-R2-01 — Changelog v2 날짜가 v1보다 과거
- **severity**: minor
- **status**: fail
- **evidence**: _overview.md 132행 `v2 (2026-04-15)` vs 139행 `v1 (2026-04-16)`
- **detail**: v2가 v1보다 하루 먼저 작성된 것으로 표시됨. 단순 오타이지만 문서 신뢰도를 해침.
- **fix_suggestion**: `v2 (2026-04-15)` → `v2 (2026-04-16)` 수정
- **🏷 gate_verdict**: 동의
- **🏷 gate_reason**: "명백한 오타."

## Summary
Round 1의 mermaid 전환으로 큰 폭의 UX 개선이 이루어졌으나, 흐름도에서 Lv1 직접 진입 경로 누락(major 1건)과 의존성/주의사항 섹션의 시각 개선 여지(minor 3건)가 남아있다. major 1건 해소 + minor 구조화로 depth_score 5.0 이상 도달 가능.

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 0s | 0 |
| 2 | user-ai-exchange | 0s | 0 |
| 3 | user-ai-exchange | 18s | 60949 |
| 4 | user-ai-exchange | 0s | 0 |
| 5 | user-ai-exchange | 59s | 146973 |
| 6 | user-ai-exchange | 642s | 1681853 |
| 7 | user-ai-exchange | 423s | 3654116 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 94843s |
| Total Tokens | 5543891 |
| Input Tokens | 100 |
| Output Tokens | 55842 |
| Cache Read | 5280891 |
| Cache Creation | 207058 |
