---
id: "009"
type: synthesis
title: "Cycle 2 Synthesis — 비용 모델 × 리스크 매트릭스 통합"
created: 2026-04-26
status: completed
sources:
  - "007_Agent_migration_and_operating_cost.md"
  - "008_Agent_risk_and_recommendation.md"
traces_brief: "001"
traces_research: "002"
traces_synthesis: "006"
summary: >
  Cycle 2의 두 관점을 통합하여 의사결정 변수의 우선순위를 확정한다.
  P4의 정량 결과(엔지니어 비용 격차 ~$67K vs 운영비 격차 ~$3K)와
  P5의 리스크 분포(Stripe Korea·D1 10GB·CF outage가 high score)가 동일한
  결론으로 수렴한다: Partial migration이 비용·리스크·결정 가역성을 동시에
  최적화하는 defensible default. 신뢰도 70-75%.
keywords: [synthesis, cycle-2, cost-model, risk-matrix, partial-migration, decision]
---

# Cycle 2 Synthesis — 비용 모델 × 리스크 매트릭스 통합

본 종합은 Cycle 2의 두 관점(P4 비용 모델, P5 리스크/권고)을 교차하여 **최종 권고를 뒷받침하는 결정적 변수**를 정리한다.

원본:
- [`007_Agent_migration_and_operating_cost.md`](./007_Agent_migration_and_operating_cost.md) — confidence: high
- [`008_Agent_risk_and_recommendation.md`](./008_Agent_risk_and_recommendation.md) — confidence: high
- 입력 종합: [`006_Synthesis_cycle1.md`](./006_Synthesis_cycle1.md)

---

## 1. 두 관점의 수렴 — Partial이 정답인 정량적·정성적 이유

P4(비용)와 P5(리스크)는 서로 다른 출발점에서 동일한 결론에 도달했다:

| 차원 | P4 결론 | P5 결론 | 수렴 |
|------|--------|--------|------|
| Stay vs Full 비용 격차 | 3년 ~$67K (엔지니어 인건비 압도) | Full은 모든 13개 리스크를 떠안음 | 둘 다 Full을 비추천 |
| Partial 위치 | Stay 대비 +8 MW, Full 대비 -16 MW | 자산 보존 + 리스크 격리 + 결정 가역성 | 둘 다 Partial이 중간 최적 |
| 고 트래픽 시 CF 우위 | 100K MAU에서 CF가 17× 비싸짐 | D1 10GB 하드캡 + 단일 스레드 + 한국 ISP 라우팅 | 둘 다 "CF가 일반적으로 싸다"의 통념 부정 |
| Stripe Korea 부재 | 결제 LOC는 양 스택 동등 | Brief 결정 5의 "글로벌 병행" 약화 | 둘 다 결제 = 스택 결정 변수 아님 |

→ **수렴된 권고: Partial migration**. 이는 두 독립적 분석(비용 / 리스크)이 **같은 답에 도달**했다는 점에서 신뢰도가 높다.

---

## 2. P4의 가장 중요한 발견 — 의사결정 변수의 재정의

P4는 다음 결과를 산출했다:

### 마이그레이션 비용 (MAN-WEEK + 환산 인건비)

| 시나리오 | 일회성 | 1년 유지 | 3년 총합 | 환산 인건비 |
|---------|--------|---------|---------|------------|
| **Stay** | 6.5 MW | 4.0 MW/yr | 18.5 MW | $59,200 |
| **Partial** | 14.5 MW | 5.0 MW/yr | 29.5 MW | $94,400 |
| **Full** | 30.5 MW | 3.0 MW/yr | 39.5 MW | $126,400 |

페이싱 가정: 시니어 백엔드 0.4 KLOC/wk 포팅, 0.7 KLOC/wk 그린필드.

### 운영비 (3년 총합, USD)

| 시나리오 | Rails-Kamal (Hetzner DE/FI) | CF Stack |
|---------|--------------------------|----------|
| Low (1K MAU) | $342 | $225 |
| Medium (10K MAU) | $500 | $229 |
| High (100K MAU) | $2,093 | $4,991 + 8 MW 샤딩 (~$25,600 일회성) |

### 의사결정 변수의 재정의

> **3년 엔지니어 인건비 격차 ~$67K (Stay vs Full)** ≫ **3년 운영비 격차 ~$3K** (low/med 시나리오)

이 격차의 비율이 **20× 이상**이라는 사실은 다음을 의미한다:
- "어느 스택이 운영비가 싼가"는 **결정 변수가 아니다** — 노이즈 수준
- 진짜 결정 변수는 **"누가 작성하고 유지하는가, 무엇이 가역적인가"**
- 사람의 시간이 클라우드 비용보다 비싸다 (이미 알려진 진실의 정량 확인)

### 100K MAU 반전점 — "엣지가 싸다"의 한계

P4는 통념과 반대 결과를 발견:
- 100K MAU 시점에서 CF Stack은 Rails-Kamal보다 **17배 비쌈** (3년 $4,991 vs $2,093, 샤딩 8 MW 별도)
- 원인 1: D1 10GB 하드캡 → 70K MAU에서 도달 → 샤딩 강제 → 8 MW 일회성 ($25,600)
- 원인 2: D1 쓰기 단가 $1/M writes (Workers 요청 단가 $0.30/M req의 3.3배)
- 원인 3: D1 단일 스레드 → 쿼리 튜닝 부담 ↑

→ **장기 관점의 함의**: 1-3년 내 100K MAU 도달이 현실적 시나리오라면, CF는 "지금 싸지만 나중에 비싸지는" 선택. Rails-on-Hetzner는 "지금도 충분히 싸고, 스케일에서 더 싸지는" 선택.

---

## 3. P5의 가장 중요한 발견 — 리스크의 정량화 + 외부 검증

P5는 13개 리스크를 채집(Brief의 5개 가설 + Cycle 1의 5개 발견 + P5가 추가 발견한 3개)하여 외부 evidence로 calibration:

### 추가 발견된 3개 리스크 (P5 디스커버리)

1. **R11 — CF 2025년 다수 outage**: 11월 4h10m, 12월 25min, 6월 Workers KV/Access 영향. CF 의존이 "완벽히 안정"하지 않음을 증명.
2. **R12 — D1 interactive transaction 부재**: P1이 발견한 ResultsController의 트랜잭션 패턴(Rails `transaction do ... end`)을 1:1 이식 불가. 배치 단위 재설계 필요.
3. **R13 — 개인정보 국외 이전 고지 의무**: 한국 사용자 데이터를 CF 글로벌 인프라에 저장 시 고지+동의 의무. 차단 사유는 아니나 운영 부담.

### High Score 리스크 군집 (확률 × 영향 ≥ med×high)

| # | 리스크 | 확률 | 영향 | 점수 | 영향 받는 안 |
|---|-------|------|------|------|------------|
| R5 | Stripe Korea 가맹점 부재 | 확정 (2026-04) | High | High | 모든 안 — Brief 결정 5 약화 |
| R11 | CF outage | Med (2025년 3건) | High | High | Partial, Full |
| R2 | D1 10GB 하드캡 | High (장기) | High | High | Partial(API DB), Full |

### Med Score 군집

| # | 리스크 | 점수 | 영향 받는 안 |
|---|-------|------|------------|
| R3 | D1 read replication beta 1년+ | Med | Partial, Full |
| R7 | D1 단일 스레드 throughput 천장 | Med | Partial, Full |
| R9 | DX gap (Rails console vs wrangler dev) | Med | Partial, Full |
| R10 | 단일 개발자 유지 부담 | Med | 모든 안 |
| R12 | D1 interactive transaction 부재 | Med | Partial, Full |

→ **합산 함의**: High/Med 리스크의 대부분이 "CF 도입에서 발생". Stay는 리스크가 없는 게 아니라 **이미 알려진 Rails 운영 리스크**(R10 단일 개발자, 결제 신규 작성)만 보유.

### 외부 Evidence Calibration

P5가 외부 검증으로 보강한 사실:
- **한국 ISP 피어링 분쟁의 구조적 원인**: KT의 LAX 라우팅, SK의 HKG 라우팅은 한국→미국·홍콩 피어링비 분쟁의 결과 — 일시적 현상이 아니라 **구조적**.
- **Stripe Korea 신규 발표 부재 2024-2026**: 3년간 진전 없음 → 단기간 변화 기대 어려움.
- **CF 2025년 outage 3건**: vendor 안정성에 한계가 있음을 외부 evidence로 확인.

---

## 4. 통합 결론 — 권고와 그 한계

### 권고: Partial Migration, 신뢰도 70-75%

**Partial의 정의**: 신규 모바일 API만 Cloudflare Workers + Hono + D1로 작성. Rails 웹과 admin은 그대로 유지.

**Partial이 defensible default인 이유**:

1. **자산 보존**: P1이 발견한 dead weight(미사용 Solid*, 미사용 Active Storage, 1,850 LOC services)를 Rails로 유지 → 즉시 잃을 가치 없음.
2. **리스크 격리**: CF 13개 리스크 중 일부만 신규 API 영역에 한정. Rails admin은 영향 없음.
3. **결정 가역성**: Partial 도중 CF가 안 맞으면 Rails로 되돌리기 쉬움 (Rails 인프라 살아있음). Full은 비가역.
4. **현 시스템 = Greenfield 진실의 활용**: P1이 발견한 "API 0개, 모바일 미연결"은 신규 API를 어차피 작성해야 함을 의미. 이를 Workers로 작성하면 비용 증가가 +8 MW에 불과.
5. **장기 평가 가능**: Partial 1년 운영 후 데이터를 모아 Stay/Full 재결정 가능.

### 가정 (Partial이 깨지는 조건)

P5가 명시한 5개 가정:
1. **사용자 분포 한국 ≥ 80%** — 글로벌 사용자 비중이 크면 CF 엣지 가치 ↑, 그러나 Stripe Korea 부재
2. **1년 내 MAU 수만 이내** — 70K+ 시 D1 10GB 도달, Partial이 Stay 대비 비싸짐
3. **단일 또는 소수 개발자** — 풀팀이면 Full도 가능. 단일이면 Partial이 안전
4. **Ruby/Rails + TypeScript 양쪽 친숙** — 한쪽만 친숙하면 해당 안 강하게 우세
5. **결제 = 한국 우선** — 글로벌 우선이면 운영 주체 분리 필요 (해외 법인)

### Brief 결정 5 업데이트

P3+P5의 발견에 따라 Brief 001 Decision 5("결제 = 한국 우선 + 글로벌 병행")는 다음과 같이 재해석:
- **단기(2026~2027)**: 토스/포트원 한국 우선 → 글로벌 보류
- **중기(2028~2029)**: 해외 법인 또는 Stripe 대안 마련 시 글로벌 추가
- **결론**: "동시 병행"이 아닌 **"단계적 병행"**

---

## 5. Cycle 2 → Final 010에 전달할 항목

Final Research 010은 Brief의 7개 deliverable 전체를 자기완결적으로 다뤄야 하므로, Cycle 2가 Final에 전달하는 핵심:

1. **5축 비교 결과** (Brief 비교 프레임)
   - 요구사항 커버리지: 양 스택 모두 충족 (P3 6셀)
   - 마이그레이션 비용: Partial 14.5 MW (P4)
   - 장기 운영비: Low/Med 격차 미미, High 시 Rails 우위 17× (P4)
   - 리스크: Partial < Full, 한국 컨텍스트 특이 리스크 다수 (P5)
   - 확장성: D1 10GB가 강한 천장 → 70K+ MAU 시 재설계 (P4+P5)

2. **3안 권고와 선택 조건** (Brief Decision 6)
   - Partial = defensible default
   - Stay = 한국 100% + 1인 + Rails 친숙
   - Full = 글로벌 + 해외 법인 + TS 친숙

3. **의사결정 테스트** (Brief Ideal Criterion 11)
   - 1년 내 MAU 추정?
   - 한국 사용자 비중?
   - 개발 인력 친숙도?
   - 글로벌 확장 의도?
   - 결제 글로벌 시급도?

4. **장기 관점의 정량 정의** (Brief Ideal Criterion 12)
   - 기간: 2026-04 ~ 2029-04
   - 규모: 저(1K) / 중(10K) / 고(100K) MAU
   - 유지 공수: Stay 4 MW/yr, Partial 5 MW/yr, Full 3 MW/yr (Full은 일회성 후 안정)

---

## 6. Incremental Summary (synthesis 스킬 입력용)

### 리서치 축
- **축 이름**: 비용 모델 × 리스크 매트릭스 통합 (Cycle 2)
- **핵심 질문**: Stay/Partial/Full 각 안의 정량적 비용·리스크와 권고는?

### 핵심 발견 (우선순위 순)

1. **[Critical] R-009-F1: 의사결정 변수는 운영비가 아니라 엔지니어 시간** — 3년 엔지니어 인건비 격차(~$67K Stay vs Full)가 운영비 격차(~$3K)를 20× 이상 압도. *(P4)*
2. **[Critical] R-009-F2: 100K MAU 시점에 CF가 Rails보다 17× 비싸짐** — D1 10GB 하드캡 + 쓰기 단가 + 샤딩 비용. "엣지=쌈"의 통념이 이 프로젝트 규모에서 부정. *(P4)*
3. **[Critical] R-009-F3: Partial migration이 defensible default** — P4(중간 비용) + P5(중간 리스크) 양쪽이 같은 결론으로 수렴, 신뢰도 70-75%. *(P4, P5)*
4. **[High] R-009-F4: Stripe Korea 부재 + CF 2025 outage 3건 + 한국 ISP 구조적 라우팅 문제** — 모두 외부 evidence로 검증된 사실. 추측 아님. *(P5)*
5. **[High] R-009-F5: Brief 결정 5 업데이트 시사** — "동시 병행"에서 "단계적 병행"으로. Stripe Korea 부재가 단기간 해소될 신호 없음. *(P5)*
6. **[High] R-009-F6: D1 10GB 하드캡 도달 시점 = 약 70K MAU** — 이 시점이 Partial vs Stay 재평가 트리거. *(P4+P5)*
7. **[Medium] R-009-F7: 5가지 권고 가정** — 한국 ≥80% / 1년 내 수만 MAU / 1-2명 개발 / 양 스택 친숙 / 결제 한국 우선. 가정이 깨지면 Stay 또는 Full로 회귀. *(P5)*
8. **[Medium] R-009-F8: 운영비는 결정 변수 아님** — Low/Med 시나리오 격차 $200~300/3y 수준의 노이즈. 의사결정 시 무시 가능. *(P4)*

### 결론

이 축의 핵심 질문(Stay/Partial/Full 정량 비용·리스크 + 권고)은 **해결됨**: 3개 시나리오 × 3개 트래픽 × 두 시점의 12셀 비용 매트릭스 + 13개 리스크 점수 + Partial migration 권고 + 5개 깨짐 조건 + 의사결정 테스트가 모두 산출됨. Final 010이 이를 자기완결적으로 통합 보고.

### 미해결 사항

- 사용자가 권고의 5개 가정 중 어느 것을 만족/위반하는지는 사용자 본인만 알 수 있음 — 이는 연구 범위 밖, 의사결정자의 영역.

---

## Communication Log

| # | Direction | Peer | Summary | Stage |
|---|-----------|------|---------|-------|
| 1 | ← | P4 | 3 시나리오 MAN-WEEK + 12셀 비용 매트릭스 + 100K 반전점 | Cycle 2 종료 |
| 2 | ← | P5 | 13 리스크 매트릭스 + Partial 권고 70-75% + 5 가정 + Brief 결정 5 업데이트 | Cycle 2 종료 |
| 3 | → | Final 010 | 5축 비교 결과 + 3안 권고 + 의사결정 테스트 + 장기 관점 정량 정의 | 통합 단계 |
