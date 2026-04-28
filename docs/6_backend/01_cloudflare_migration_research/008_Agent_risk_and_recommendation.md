---
id: "008"
title: "Risk Matrix & 3-Option Recommendation"
category: agent
status: completed
created: 2026-04-26
summary: >
  Cycle 1의 비대칭(낮은 마이그 비용 vs 높은 운영 리스크)을 13개 리스크의
  확률×영향도 매트릭스로 정량화하고, Stay/Partial/Full 3안의 선택 조건과
  의사결정 테스트를 정의한다. 결론: Partial 마이그레이션(모바일 API만 CF Workers,
  Rails 웹+admin 유지)이 자산 보존·리스크 격리·결정 가역성을 동시에 충족하는
  defensible default다 — 신뢰도 medium-high(70-75%), 단 사용자 분포가
  한국 ≥80%이고 1년 내 MAU 수만 이내일 때. Stripe Korea 가맹점 부재로
  Brief 결정 5의 "글로벌 병행"은 운영 주체 분리 또는 글로벌 확장 시점
  연기로 재해석되어야 한다.
model: "sonnet"
reasoning_depth: "standard"
confidence: high
keywords: [agent-report, risk-matrix, recommendation, stay-partial-full, decision]
---

# Risk Matrix & 3-Option Recommendation

## Progress
### Completed
- [x] Read Cycle 1 synthesis + agent reports
- [x] Risk #1: Korean ISP routing
- [x] Risk #2: D1 10GB cap
- [x] Risk #3: D1 replication beta
- [x] Risk #4: Korean ecosystem
- [x] Risk #5: Stripe Korea
- [x] Risk #6: Vendor lock-in
- [x] Risk #7: D1 single-thread
- [x] Risk #8: Cold start
- [x] Risk #9: DX gap
- [x] Risk #10: Solo dev
- [x] Risk #11: CF outage exposure (added during research)
- [x] Risk #12: D1 interactive transaction absence (added)
- [x] Risk #13: Korean data residency 고지 의무 (added)
- [x] Option Stay
- [x] Option Partial
- [x] Option Full
- [x] Final recommendation

### Current Status
Completed.

## Summary

Cycle 1이 발견한 비대칭(마이그 비용은 Brief 예상보다 **낮고**, 운영 리스크는 **높음**)을 13개 리스크의 확률×영향도 매트릭스로 정량화했다. 매트릭스의 분포는 **고-영향·중확률 리스크가 한국 시장 + 결제 + D1 한도에 집중**되어 있고, **저-영향 리스크(콜드스타트, DX gap)는 Brief가 우려한 대비 가벼움**을 보여준다.

3안 권고:

- **B.1 Stay** — Brief 결정 1의 "현재 미배포 시스템"이라는 사실을 무시하지 않으면, 단기 안전성 외에 장기 가치 측면 약함. **사용자 분포 미정 + 인력 안정성 우선** 시나리오에서만 우위.
- **B.2 Partial** — **defensible default**. 모바일 API만 CF Workers로 그린필드 구축, Rails 웹+admin은 유지. P1의 "JSON API 0개·모바일 미연결" 발견이 Partial을 **무비용 강제**한다(애초에 모바일 API는 어디든 새로 만들어야 하므로). 결정 가역성·리스크 격리·자산 보존 동시 충족.
- **B.3 Full** — 비용은 Brief 예상보다 낮지만, **D1 10GB·한국 ISP·Stripe Korea·생태계** 4개 리스크를 한 번에 떠안음. 글로벌 확장 의도 + 단일 PG(Stripe) 수용 + 한국 사용자 비중 50% 이하 시나리오에서만 정당화.

**최종 권고**: Partial migration(B.2), 신뢰도 **medium-high (70-75%)**, 가정: (a) 한국 사용자 비중 ≥ 80%, (b) 1년 내 MAU 수만 이내, (c) 단일 개발자 ~ 2-3인 팀 유지, (d) Brief 001의 "장기 = 1-3년" 시야. 가정이 깨지면(예: 글로벌 확장 결정·팀 5인+ 확장·MAU 수십만+ 도달 임박) Stay 또는 Full로 재평가.

**Brief 결정 5 업데이트 시사**: Stripe Korea 가맹점 부재(2026-04 확인)로 "한국 우선 + 글로벌 병행"은 **단일 모먼트에 동시 실현 불가**. "Toss/PortOne 한국 1차 + Stripe 글로벌은 해외 법인 또는 BaaS 확보 시점에 병렬 도입"으로 재해석.

## Details

### Part A — Risk Matrix

#### A.1 평가 방법

확률(P): low(<20%) / med(20~60%) / high(>60%) — 1-3년 시야 내 발생할 확률.
영향도(I): low(완화 가능, 운영 비용 < 10% 영향) / med(설계 변경 필요, 비용 10~50%) / high(아키텍처 재설계 또는 비즈니스 영향).
점수(S): P × I 정성 등급 — Low / Med / High / Critical.

스택 영향: **Stay**(Rails 유지에 영향) / **Partial**(부분 전환에 영향) / **Full**(전면 전환에 영향). 한 리스크가 여러 안에 영향할 수 있다.

#### A.2 Risk Matrix Table

| # | 리스크 | P | I | Score | 근거 (출처/Cycle 1) | 완화 (Mitigation) | Stack 영향 |
|---|--------|---|---|-------|---------------------|-------------------|-----------|
| R1 | **한국 ISP의 Seoul PoP 라우팅 비일관성** (KT→LAX, SK Broadband→HKG, 일부 KR 트래픽 후쿠오카/도쿄/홍콩 경유, ~600ms 지연) | high | med | **High** | P2; CF Community thread 699407; Korea peering fee dispute 구조적 원인 (Internet Society 2022); KT/SK ISP routing 보고 다수 | (1) 한국 사용자 100% 시나리오면 Korea-local VPS(Rails) 우위. (2) Hybrid: 정적·읽기는 CF, 쓰기·민감 경로는 KR 직결. (3) 결제·webhook 등 사용자 미체감 경로는 PoP 영향 무관 | Partial·Full |
| R2 | **D1 10GB/DB 하드캡 → 샤딩 강제** | med | high | **High** | P2: developers.cloudflare.com/d1/platform/limits (상향 불가 명시). 영향 분석: assessment(13컬럼 + JSON) + responses(8 col) + audit_logs(누적) 합산. 추정 1유저 = ~10-30KB 누적 → 10GB ≈ 30-100만 활성 유저. **수만 MAU 시나리오는 안전, 수십만+ 도달 시 샤딩 필수** | (1) Schema 설계 시 tenant_id/quarter_id 분할 가능 키 미리 도입(`assessment_2026Q1` 등). (2) Audit log를 별도 D1 또는 R2 archival로 분리. (3) Time-boxed retention 정책. (4) 도달 직전 샤딩 마이그 = 4-8 MAN-WEEK 어림 | Partial·Full |
| R3 | **D1 read replication public beta 1년+ 지속** | med | med | **Med** | P2: 2025-04-10 도입, 2026-04 시점 GA 미선언. lag 바운드 없음, Sessions API로만 일관성 보장 | (1) 읽기 증가 전까지는 단일 region 사용. (2) 캐시 가능한 데이터(personality_types seed, question_set 등)는 KV 또는 Workers Cache API. (3) GA 지연 시 단일 D1 + 쿼리 튜닝(인덱스+`PRAGMA optimize`)으로 1k qps 수준 1년+ 운영 가능 | Partial·Full |
| R4 | **한국 메인스트림 백엔드 채택 부재** (인력·트러블슈팅·사례) | high | med | **High** | P2: 토스/당근/쿠팡 사용 증거 0, velog/tistory에 D1 production 후기 0건, 한국어 기술 블로그는 사이드프로젝트 수준 | (1) 영문 커뮤니티(CF Discord/Community/Stack Overflow) 의존. (2) 단일 개발자 ~ 소수 팀 유지 시 채용 부담은 발생 안 함. (3) 자가 학습 자료 풍부(공식 docs + Hono examples) | Partial·Full |
| R5 | **Stripe Korea 가맹점 엔티티 부재 (2026-04)** | high (현재) / med (2-3년 내 launch 가능성) | high | **High** | P3: docs.stripe.com/payments/countries/korea + NICEPay 파트너십 = 해외 merchant→KR 고객만, 한국 법인 직접 가입 경로 미개설. 검색 결과 2024-2026 사이 Stripe Korea entity 신규 발표 없음 | (1) Brief 결정 5 재해석: 한국 1차는 Toss/PortOne, Stripe는 글로벌 시점 분리. (2) 글로벌 강행 시 해외 법인 또는 BaaS(예: PaymentMaverick, Lemon Squeezy) 경유. (3) PortOne 다중 PG 추상화로 PG 교체 비용 최소화 | Stay·Partial·Full (모두 영향 — 결제 stack 무관) |
| R6 | **CF 벤더 락인 심화** (Brief에서 사용자 수용 명시) | high | med (수용 시) / high (deprecation·가격 변경 시) | **Med** (사용자 수용 전제) | Brief 001 Constraint 1: "Cloudflare 벤더 락인 수용". 단, CF의 가격 정책 변경(예: Workers Free→Standard 강제 2024-03) 사례 존재 | (1) D1 → SQLite export(`wrangler d1 export`)로 데이터 포터빌리티 보장. (2) 도메인 services는 순수 TypeScript이므로 다른 런타임(Bun/Node/Deno) 이식 가능. (3) Hono는 멀티 런타임 지원이라 Workers 외 호스팅으로 이동 가능 | Partial·Full |
| R7 | **D1 단일 스레드 throughput 천장** (1ms 쿼리 ≈ 1k qps) | med | med | **Med** | P2: HN 43572511, answeroverflow 1345869029906059305. 본 앱 query mix: 결과 페이지(8-step scoring + reads) + assessment 답변 저장. 평균 쿼리 5ms 가정 → ~200 qps 천장. 수만 MAU 분당 ~30 결과 산출 페이지 시 안전 | (1) 인덱스 튜닝 + `PRAGMA optimize`. (2) Read replicas(beta 후 GA 시) 또는 KV cache. (3) 무거운 집계(admin dashboard)는 별도 분석 D1 또는 cron 사전 계산 | Partial·Full |
| R8 | **Workers 콜드스타트** (~5ms baseline, 스크립트 크면 수십 ms) | high (every idle wake) | low | **Low** | P2; CF blog "Eliminating cold starts". 본 앱의 사용자 행동(assessment 1회 ~10분 세션) 첫 진입에 단발 노출. 결제·일반 페이지 영향 미미 | (1) 스크립트 슬림 유지(< 1MB compressed). (2) Cron Trigger keep-warm은 비용/이득 비효율. (3) UX 측 측정 지표만 monitoring | Partial·Full |
| R9 | **DX gap vs Rails console** (개발자 일일 생산성) | high | low | **Med** | P1+P2 통합: `bin/kamal console`/`bin/dbc` 같은 직접 production REPL 부재. wrangler tail + D1 console + miniflare로 대체 가능하지만 통합도 떨어짐 | (1) `wrangler dev` + miniflare local 환경. (2) D1 dashboard SQL 콘솔. (3) Drizzle Studio 또는 D1 직접 SQL. (4) Rails 자산이 도움 안 됨(미배포라 console로 살펴볼 prod 데이터 없음) | Partial·Full |
| R10 | **단일 개발자 유지보수 부담** (1-3년 내 인원 변동) | med | med (1인 우선) / high (이탈 시) | **Med** | Brief 001 + CLAUDE.md: 현 1인 운영 추정. Rails는 한국에서 채용 풀 큼 vs CF Workers/Hono는 거의 없음 (R4 연계) | (1) Stay 시 Rails 채용 우위. (2) Partial 시 CF 영역은 모바일 API에 한정 → 격리. (3) Full 시 채용 풀 좁아짐. (4) 단일 개발자 모드 유지 의도면 친숙한 스택 우선(여기서는 Rails) | Stay 우위·Partial 중립·Full 불리 |
| R11 | **CF 글로벌 outage 노출** (2025년 다수 사례) | med (2025-11, 2025-12, 2025-06 outage 기록) | high (전면 다운 시) | **High** | CF status history; blog.cloudflare.com 2025-11-18·12-05·06-12 outage 보고. 11월 outage = 4시간 10분, 12월 = 25분, 6월 = Workers KV/Access/Gateway/Stream 영향 | (1) **Stay = 단일 VM = 자기 outage 위험 동등** (낮은 트래픽 시 가용성은 비슷). (2) Partial 시 Rails 웹은 살아있음(자체 hosting). (3) Full 시 CF outage = 서비스 전면 다운 — 사용자 신뢰·결제 webhook miss. status page + retry 수용 | Full > Partial > Stay 위험 순 |
| R12 | **D1 interactive transaction 부재** | med | med | **Med** | P2: D1은 batch() 트랜잭션만, `BEGIN/COMMIT` 동적 SQL 패턴 없음. P1: ResultsController#show 8-step scoring을 `ActiveRecord::Base.transaction do` 안에서 실행 | (1) 8-step scoring을 batch statements 1번으로 재구성 가능(읽기→계산→batch write). (2) 또는 client에서 idempotency key + 부분 실패 재시도 패턴. (3) 본 앱 핵심 트랜잭션 = scoring + result 저장 한 곳 → 재설계 비용 small-medium | Partial·Full |
| R13 | **개인정보 국외 이전 고지 의무** (D1 자동 region 배치 시) | high | low | **Med** | P3: 개인정보보호법 제28조의8 — D1/R2 리전 해외 시 처리방침 고지 + 이용자 동의 필수. 원천 금지 아님 | (1) 가입 동의 체크박스 + 처리방침에 명시. (2) 2025-11 D1 jurisdiction 설정 활용해 EU/AU 등 제한 가능. (3) 한국 데이터 강제 보관 요건은 비금융 일반 상점에 적용 안 됨 | Partial·Full |

#### A.3 매트릭스 시각화 (P×I 분포)

```
                      Impact →
              Low          Med          High
       ┌──────────┬──────────────┬──────────────┐
  High │ R8       │ R1, R4       │ R5, R11      │
       │          │              │              │
       ├──────────┼──────────────┼──────────────┤
       │ R13      │ R3, R7, R9,  │ R2, R10(이탈)│
   Med │          │ R10, R12     │              │
       │          │              │              │
       ├──────────┼──────────────┼──────────────┤
   Low │          │ R6           │              │
       │          │              │              │
       └──────────┴──────────────┴──────────────┘
       ↑
       Probability
```

**고위험 군집 (High score, 우상단)**: R5(Stripe Korea), R11(CF outage), R2(D1 10GB)는 **장기 운영 안정성**을 직접 위협. R1(KR ISP)·R4(생태계)는 **한국 우선 시나리오에 반복적 마이너 패널티**.

**저위험 군집 (Low score, 좌하단)**: R8(콜드스타트)·R6(락인, 사용자 수용 전제)·R13(고지 의무)는 Brief가 우려한 대비 **실제 영향 작음**.

**중간 군집**: R3(D1 read replica)·R7(D1 throughput)·R9(DX)·R12(transaction)는 **설계로 회피 가능**한 수준.

#### A.4 매트릭스 해석 (3안에 영향)

- **Stay 영향 리스크**: R5(결제), R10(이탈) — 즉, "전환 안 해도 떠안는" 리스크는 결제 + 인력. 대부분의 CF 운영 리스크 회피.
- **Partial 영향 리스크**: R5 + R1·R2·R3·R7·R8·R9·R11·R12·R13(모바일 API에 한정). Rails 웹·admin이 살아있어 R10은 중립화.
- **Full 영향 리스크**: 위 모두 + Rails 자산 손실(Hotwire 흐름 재설계, 단 Cycle 1에서 2 템플릿으로 한정 확인됨).

핵심: **Partial은 Full의 운영 리스크를 모바일 API 영역으로 격리**하면서, **Stay의 단일 개발자 안전성을 Rails 웹+admin에서 보존**한다. 비대칭 자체에 대응하는 구조다.

---

### Part B — 3-Option Recommendation

#### B.1 Stay (Rails 유지)

**Definition**
- 현 Rails 8.1.2 + SQLite + Hotwire + Solid stack(미사용 자산 포함) + Kamal 배포 그대로 유지.
- 모바일 API는 필요해질 때 Rails 안에 `Api::V1::*` namespace로 신설 (Rails로 그린필드).
- 결제는 Toss × Rails (P3 G-1 = F, 600-900 LOC).
- Cloudflare 미도입.

**Selection conditions (when Stay wins)**
- 단일 개발자 + Ruby/Rails 친숙도 high + 1-3년 내 팀 확장 의도 없음.
- 한국 사용자 100% + 외부 PoP 의존이 명확한 disadvantage.
- D1 10GB + Korean ISP routing 등의 학습 비용을 치를 motivation 없음 (CF 도입 자체가 목적이 아닌 외부 추천 수용 검토 단계라는 Brief 001 Intent를 진지하게 받음).
- 인프라 단순성 = 운영 안정성 등식이 priority.
- 결제 + 모바일 API + 약간의 컨트롤러 추가 = 향후 1-3년 주요 작업 예상.
- Brief 001 quality_profile = Standard + Priority Longevity인데 "longevity" 해석이 "검증된 스택 유지"에 무게.

**Risks Realized (Part A)**
- **R5(Stripe Korea)**: 어느 안이든 동일하게 떠안음. Toss × Rails로 충분.
- **R10(개발자 이탈)**: Rails 채용 풀이 한국에서 큼 → 인력 위험 부분 완화.
- **R11(CF outage)**: 0 (CF 미사용).
- **부정적**: R1·R2·R3·R4·R6·R7·R8·R9·R12·R13 모두 N/A.

**Mitigations Active for free**
- Hotwire admin dashboard, Solid* 스택 그대로(미사용이라도 dead weight 부담 없음).
- Kamal `bin/console`/`bin/dbc` 등 production REPL 도구.
- RSpec 18 파일 + 2,641 LOC 테스트 자산 유지.
- 한국 채용 시장 친화도.

**Migration Path (high-level)**
1. **Step 1**: 모바일 API 설계 → Rails `Api::V1::*` namespace로 추가 (5-8 MAN-WEEK 어림, 단 P4 미완료라 정확하지 않음).
2. **Step 2**: 결제 모듈(Toss × Rails) 신규 구축 (P3 G-1: 600-900 LOC).
3. **Step 3**: SQLite production 한도(동시 쓰기 ~ 수백 wps, WAL mode + busy_timeout 튜닝 필수) 직면 시 PostgreSQL 마이그(Brief Out of Scope이므로 별도 의사결정).
4. **Step 4**: 단일 VM Kamal에서 부족 시 multi-server Kamal 또는 managed Rails(예: Heroku/Render) 검토.

**Decision Test (concrete questions)**
- Q1: 1-3년 내 사용자 100% 한국이 거의 확정인가? → YES면 Stay 유리, NO면 Partial/Full 검토.
- Q2: Ruby/Rails이 현 개발자에게 가장 친숙하고 모바일 API + 결제 추가가 6개월 내 가능한가? → YES면 Stay 유리.
- Q3: Cloudflare 학습 + 새 패러다임(엣지/D1 한도/wrangler) 도입 동기가 외부 추천 외에 있는가? → NO면 Stay 유리.

#### B.2 Partial (모바일 API on CF Workers, Rails 웹+admin 유지)

**Definition**
- Rails 웹(assessments, results, consents, deletion_requests, sessions, accounts, admin) 그대로 유지.
- **모바일 API만 CF Workers + Hono + D1로 그린필드 신설**: `/api/v1/assessments`, `/api/v1/profile`, `/api/v1/scoring`, `/api/v1/payments/*` 등.
- 도메인 services(1,850 LOC)는 **TypeScript로 이식**(Workers에서 mobile API가 호출). Rails는 Ruby version 그대로 사용.
- 결제는 Toss/PortOne × CF Workers (P3 G-2/G-4: 400-800 LOC).
- 데이터 정합성: 단기적으로 Rails SQLite와 D1을 **분리 운영** (모바일 = D1 source of truth, 웹 = Rails source of truth, 사용자가 모바일과 웹을 동시 사용 안 한다고 가정. Cycle 1은 현 모바일이 서버 미사용 상태이므로 분리 운영의 데이터 모델이 깨끗).
- 또는 D1을 단일 source로 하고 Rails가 D1을 read-only로 참조하는 변종 가능 (Hyperdrive 유사 패턴, 단 SQLite 기반이라 직접 미지원 — 별도 설계 부담).

**Why this is the most defensible default given asymmetry**
- **마이그 비용 절감**: P1이 발견한 "JSON API 0개 + 모바일 미연결"은 **Partial의 진입 비용을 거의 0으로 만든다**. 모바일 API를 어디든 새로 만들어야 하므로 CF로 가는 것이 추가 비용 아니라 **선택지**다.
- **리스크 격리**: R1·R2·R3·R7·R11·R12 등 CF 운영 리스크는 모바일 API 영역에 한정 → 모바일 트래픽이 다운돼도 웹+admin은 살아있음.
- **자산 보존**: Hotwire admin dashboard, RSpec 자산, Kamal 운영 경험을 잃지 않음.
- **결정 가역성**: Partial이 1년 후에도 효과적이면 Full 전환 검토(Strangler 다음 단계), 아니면 모바일 API를 Rails로 흡수(되돌리기). 양 방향 옵션 보존.
- **Brief 001 Decision 6의 "3안 체계"와 가장 일치**: Strangler Pattern은 산업 표준의 점진 전환 경로.
- **Brief 001 Decision 7과 정확히 일치**: "현재 모바일이 서버 API를 사용하지 않는 상태 → 신규 API 레이어만 CF로 분리하는 경로(Partial)가 유의미한 제3안" — Brief 작성 당시 가설이 Cycle 1에서 검증됨.

**Selection conditions (when Partial wins)**
- 모바일 앱이 향후 1년 내 서버와 연동될 계획.
- 한국 사용자 비중 ≥ 80%지만 모바일 사용자에게 약간의 글로벌 가능성 인정.
- 단일 개발자 ~ 2-3인 팀 유지.
- "아키텍처 학습 + 안전망"을 동시 원함 (CF 학습은 신규 API에서, 안전망은 Rails 유지).
- 1-3년 시야에서 "되돌리기 가능성"을 보존 가치로 봄.

**Risks Realized (Part A)**
- 부분적 CF 운영 리스크(R1·R2·R3·R7·R8·R9·R11·R12·R13)를 모바일 API 영역에 떠안음.
- R5(Stripe Korea)는 어느 안이든 동일.
- R10(개발자 이탈)은 두 스택 동시 운영 부담으로 약간 증가 — 단, Rails 영역은 채용 시장 큼.
- R4(생태계)는 모바일 API 트러블슈팅 시에 한정.

**Mitigations Active for free**
- Hotwire admin dashboard 유지 (Cycle 1: 9개 admin ERB 그대로).
- RSpec 자산 유지(웹 흐름).
- Kamal 운영 경험 유지.
- CF 학습 비용은 모바일 API 한정 → 설계·시간 통제 가능.
- D1 10GB 도달은 모바일 데이터에 한정 → 웹은 SQLite 그대로.

**Migration Path (high-level, ordinal)**
1. **Step 1**: 도메인 services(1,850 LOC) TypeScript 이식 — 테스트는 RSpec → Vitest 동등 변환. **scoring + insights + compliance 모듈 단위 검증**.
2. **Step 2**: D1 schema 설계 (15 모델 중 모바일 관련만 — 추정: assessment, question, question_set, response, profile, personality_type, anonymous_session, audit_log = 8 테이블). User.encrypts AES-GCM 등가 구현.
3. **Step 3**: Hono 라우팅 + 미들웨어 (auth, CORS, CSRF, rate-limit, request-id) — Brief Decision 7의 "API gateway 패턴".
4. **Step 4**: 결제 webhook + 승인 API (Toss 또는 PortOne, P3 G-2/G-4 패턴, ~500-800 LOC).
5. **Step 5**: Flutter 앱이 새 API 소비. PG-hosted 결제창 WebView로 SAQ A 유지.
6. **Step 6**: 운영 monitoring(Workers Logs + D1 metrics) 설정. Cron Trigger로 keep-warm 옵션.
7. **Step 7 (이후)**: Rails 웹 SQLite와 D1 정합성 모델 결정 — 분리 유지 or 통합 마이그(Full 전환).

**Decision Test (concrete questions)**
- Q1: 모바일 앱이 향후 1년 내 서버와 통신할 계획이 있는가? → YES면 Partial 진입 비용이 사실상 0(Stay에서도 어차피 신설).
- Q2: 결제·인증을 신규 API로 시작하면 도메인 services 1,850 LOC TypeScript 이식 비용을 받아들일 수 있는가? → P4 결과 대기 중이지만 어림 8-12 MAN-WEEK 추정 가능.
- Q3: Rails 웹+admin을 유지할 가치가 1-3년 시야에서 손실 비용보다 큰가? → Hotwire 자산이 2 템플릿(Cycle 1) + admin 9 ERB로 한정이므로 작음. **그러나 작아도 살아있는 코드를 굳이 버릴 이유가 없음** — Partial의 합리성.
- Q4: 6개월 후 모바일 API + 결제가 안정 운영되면 Rails 웹을 단계적으로 전환(→ Full)할 의사가 있는가? Or 분리 영구 유지? — 둘 다 Partial로부터 가능.

#### B.3 Full (Entire backend on CF stack)

**Definition**
- Rails 8.1.2 폐기. 현 라우트 17개(웹) + admin 9 ERB + 모바일 API 모두 CF Workers + Hono + D1 + R2 + KV로 재구축.
- Hotwire Turbo Frame 흐름(2 템플릿) 재설계: full reload, fetch-swap, 또는 SPA 중 택일.
- 도메인 services 1,850 LOC TypeScript 이식.
- 결제: Toss/PortOne × CF Workers + 글로벌 Stripe(별도 entity 확보 시).
- Kamal 배포 폐기 → wrangler.

**Selection conditions (when Full wins)**
- 한국 사용자 비중 ≤ 50% (글로벌 분포가 명확).
- 1-3년 내 트래픽 변동성이 크고 (서버리스 자동 스케일링 가치) Korea-local hosting의 우위가 사라짐.
- 모바일 + 웹 + 외부 API + B2B integrations 등 표면이 다중적 + API-first 진화 의도.
- 팀이 TypeScript 친숙하거나 향후 채용 풀을 TS 중심으로 전환하기로 결정.
- Brief 001 Constraint "벤더 락인 수용" + 결정 5의 "글로벌 병행"을 진짜로 실행할 의지 있음 + 해외 entity 또는 BaaS 사용 의향.
- **현재 미배포 + 0 데이터 + 0 API + 미사용 Solid***라는 P1의 발견을 "그린필드 절호의 기회"로 해석.

**Risks Realized (Part A)**
- R1·R2·R3·R4·R7·R8·R9·R11·R12·R13 모두 떠안음.
- R5는 한국 1차면 Toss/PortOne로 해결, 글로벌은 Stripe 별도 entity 필요.
- R10(개발자 이탈)이 가장 큰 — TS+CF 채용 풀 좁음.
- R6(락인) Brief 수용했으나 "fail catastrophic" 시나리오(CF 가격 정책 급변·서비스 deprecation)는 잠재 위험.

**Mitigations Active for free**
- Solid* dead weight 정리(어차피 미사용).
- Hotwire 학습/유지보수 부담 없음.
- 단일 stack(TypeScript 전체) — 1인 운영 시 컨텍스트 스위치 비용 절감.
- D1 한도 도달 시 샤딩이 강제되지만 schema 설계 시점에 미리 대비.
- CF의 글로벌 엣지·R2 무료 egress·Workers 가격 정찰 — 글로벌 시 비용 우위 가능.

**Migration Path (high-level, ordinal)**
1. **Step 1**: 도메인 services TypeScript 이식 + 테스트 동등 변환 (Partial과 동일).
2. **Step 2**: D1 전체 schema 설계 (15 모델 모두). Audit log retention 정책 + 샤딩 키 사전 도입(R2 완화).
3. **Step 3**: Hono 라우팅 17 + admin 9. Hotwire 흐름 재설계 결정 + 구현.
4. **Step 4**: 인증·세션·CSRF Hono middleware로 Rails 패턴 1:1 재구현 (P1 식별: cookie-session + AR encryption).
5. **Step 5**: 결제 모듈 (P3).
6. **Step 6**: 모바일 API.
7. **Step 7**: Production cutover + 모니터링 + 운영 playbook.
8. **Step 8 (이후)**: D1 read replica GA 시 활용, 트래픽 증가 시 샤딩 마이그.

**Decision Test (concrete questions)**
- Q1: 한국 사용자 비중이 향후 1-3년 50% 이하 또는 글로벌 확장이 명확히 결정됐는가? → NO면 Full 정당화 약함 (R1·R5 패널티가 한국 우선 시나리오에서 큼).
- Q2: 해외 entity 또는 BaaS 경유 Stripe 글로벌 결제를 설치할 자원이 있는가? → NO면 결정 5의 "글로벌 병행"이 종이 위 결의로 머묾.
- Q3: Hotwire 2 템플릿 + admin 9 ERB + Stimulus 8개를 SPA 또는 SSR로 재설계할 5-10 MAN-WEEK 추가 비용을 받아들이는가? — Partial은 이 비용을 회피.
- Q4: 1인 운영에서 TS+CF 단일 스택의 컨텍스트 절감 vs Rails 친숙도 손실 — 어느 쪽이 큰가?
- Q5: D1 10GB 도달 시점이 1-3년 시야 안에 들어올 가능성 평가 (P4 운영비 모델링이 도와야 정확) — 도달 임박 시 샤딩 설계를 처음부터 강제해야 함.

---

### Part C — Final Recommendation

#### C.1 권고: **Partial migration (B.2)**

**신뢰도**: medium-high (70-75%)

**가정**:
1. 한국 사용자 비중 ≥ 80% (1-3년 시야).
2. 1년 내 MAU 수만 이내 (D1 한도 여유).
3. 단일 개발자 ~ 2-3인 팀 유지 (인력 다변화 부담 회피).
4. 모바일 앱이 향후 1년 내 서버와 통신할 계획 (Cycle 1 컨텍스트 가정).
5. Brief 001 Constraint "장기 = 1-3년" 시야 유지.

#### C.2 근거

1. **비대칭 발견(Cycle 1 §1)이 Partial을 가리킨다**:
   - 마이그 비용은 Brief 예상보다 낮음 → Stay의 보수성 정당성 약화.
   - 운영 리스크는 Brief 예상보다 높음 → Full의 적극성 정당성 약화.
   - **양쪽 끝이 약화된 상태에서 가운데가 강해진다.**
2. **P1의 "JSON API 0개·모바일 미연결" 발견이 Partial 진입 비용을 사실상 0으로 만든다.** 모바일 API는 어느 안에서든 어차피 신설.
3. **결정 가역성**: Partial은 6-12개월 후 Full 전환 또는 Rails 흡수 양 방향으로 진행 가능.
4. **리스크 격리**: R11(CF outage), R2(D1 10GB), R7(throughput), R12(transaction) 등을 모바일 API에 한정.
5. **자산 보존**: Hotwire admin + RSpec + Kamal 운영 경험 유지.
6. **Brief 001 Decision 6+7과 직접 정합**: Strangler + 모바일 API 분리 패턴이 Brief에서 명시적으로 언급됨.

#### C.3 Brief 결정 5 업데이트

원문: "한국(토스/아임포트) 우선 + 글로벌(Stripe) 병행".

**Cycle 1 발견 반영 후 재해석**:
> "한국 1차 = Toss × Workers (또는 Toss × Rails 단계, Partial이면 Workers로 일원화). 글로벌(Stripe) 병행은 **시점 분리** — 한국 사용자 안정화 후 + (해외 entity 확보 또는 BaaS 도입) 이후. 2026-04 시점에서 한국 법인이 단일 모먼트에 한국+글로벌 결제 동시 실현은 Stripe Korea 부재로 불가."

이는 Brief의 "한국 우선" 부분은 유지하면서, "병행"의 시간축을 "동시"가 아니라 "단계적"으로 명확히 한다. Brief 001 자체를 부정하지 않고 정확화하는 업데이트.

#### C.4 가정이 깨지면

| 가정 깨짐 | 재평가 방향 |
|----------|------------|
| 글로벌 확장 결정 (한국 ≤ 50%) | **Full** 검토. 단 R5 + 해외 entity 자원 확인 선행. |
| 팀 5인+ 확장 + 채용 시작 | Rails 채용 풀 우위 → **Stay** 또는 Partial 유지(CF 영역 좁게 제한). |
| MAU 수십만+ 도달 임박 (1년 내) | D1 샤딩 비용 + R7 throughput 검토. 미리 schema 설계가 안 돼있으면 **Stay** 안전. |
| 모바일 앱 연동 계획 무기 연기 | Partial의 동기 약화 → **Stay**가 더 합리적. |
| 단일 개발자 이탈 위험 현실화 | R10 영향 확대 → 친숙한 스택(Rails) 유지 = **Stay**. |

#### C.5 Brief 001 "3안 체계" 존중

Brief 001 Decision 6: "권고안은 3안 체계, no go/no-go". 본 보고서는 Stay/Partial/Full 셋 모두를 동등 가능 옵션으로 정의하고 선택 조건을 명시했다. **Partial은 "추천 default"이지 "유일 정답"이 아니다**. C.4의 가정이 다르다고 판단되면 Stay 또는 Full이 정답. 사용자가 자신의 시장·팀·시야 가정을 적용해 최종 선택.

#### C.6 다음 단계 권고 (P5 → 최종 synthesis 009)

1. P4 운영비 모델링 결과(007)와 통합되면 D1 10GB 도달 시점·CF vs Rails 비용 크로스오버를 C.4 표에 정량 추가.
2. Brief 001 Ideal Criteria 9·10을 만족시키는 P4의 시뮬레이션이 Partial vs Full 사이의 비용 차이를 분명히 하면 본 권고의 신뢰도 75% → 80%+로 상향 가능.
3. Final research(010)는 본 권고 + P4 비용 + Cycle 1 발견을 통합하여 사용자 의사결정 보드 형식으로 제시.

---

## Key Findings

### Critical
- **F1. 비대칭 자체가 Partial을 가리킨다.** 마이그 비용 ↓ + 운영 리스크 ↑ → 양 끝 약화 → 가운데(Strangler/Partial) 강해짐.
- **F2. Stripe Korea 부재(R5)는 Brief 결정 5의 "동시 병행"을 "단계적 병행"으로 재해석 강제.** 어느 안이든 동등 영향이지만, Full에서 글로벌 확장 명분의 절반 약화.

### High
- **F3. R1(Korean ISP routing) + R4(생태계 부재)의 결합이 한국 100% 사용자 시나리오에서 CF의 일반론적 우위를 약화한다.** 구조적 원인(Korea peering fee 분쟁 + Tokyo/HK rerouting)이 단기 해결되지 않음.
- **F4. R2(D1 10GB)는 schema 설계 시점에 미리 sharding key를 도입하면 1-3년 시야에서 통제 가능**하지만, 도달 임박 시 4-8 MAN-WEEK의 마이그 부담.
- **F5. R11(CF outage 2025년 다수)** — Stay에서는 0 노출, Partial에서는 모바일 한정, Full은 전면 영향. 트래픽 시나리오와 SLA 기대치에 따라 weight 변화.

### Medium
- **F6. R6(벤더 락인) 사용자 수용 명시했으나 "deprecation 또는 가격 급변" tail risk 존재.** Hono 멀티 런타임 + D1 export로 부분 완화.
- **F7. R8(콜드스타트)·R13(고지 의무)는 Brief 우려 대비 영향 작음** — 실제 매트릭스에서 Low 군집.

### Low
- **F8. R12(D1 interactive transaction 부재)는 본 앱 핵심 트랜잭션이 ResultsController 1곳에 집중**되어 batch() 1번으로 재구성 가능 (Cycle 1 P1 분석).

---

## References

| Source URL | Role |
|------------|------|
| https://developers.cloudflare.com/d1/platform/limits/ | D1 한도(R2 evidence) |
| https://developers.cloudflare.com/d1/best-practices/read-replication/ | D1 replication beta(R3 evidence) |
| https://community.cloudflare.com/t/clients-from-south-korea-connect-via-fukuoka-tokyo-osaka-instead-of-seoul/699407 | KR ISP routing(R1 evidence) |
| https://www.internetsociety.org/resources/doc/2022/internet-impact-brief-south-koreas-interconnection-rules/ | Korea peering fee dispute (R1 structural cause) |
| https://github.com/cdnjs/cdnjs/issues/3395 | KT/SK ISP routing(R1 corroborating) |
| https://blog.cloudflare.com/18-november-2025-outage/ | CF 2025-11 outage(R11) |
| https://blog.cloudflare.com/5-december-2025-outage/ | CF 2025-12 outage(R11) |
| https://blog.cloudflare.com/cloudflare-service-outage-june-12-2025/ | CF 2025-06 outage Workers KV/Access(R11) |
| https://blog.cloudflare.com/fail-small-resilience-plan/ | CF Code Orange resilience plan(R11 mitigation context) |
| https://docs.stripe.com/payments/countries/korea | Stripe KR NICEPay only(R5) |
| https://stripe.com/newsroom/news/tour-singapore-2024 | Stripe × NICEPay 발표(R5) |
| https://news.ycombinator.com/item?id=39498484 | "Why isn't Stripe operating in South Korea" HN(R5 corroborating) |
| https://news.ycombinator.com/item?id=43572511 | D1 single-thread throughput(R7) |
| https://www.answeroverflow.com/m/1345869029906059305 | D1 scaling 한계(R2/R7) |
| Cycle 1 003_Agent_current_rails_assets.md | P1 발견 baseline |
| Cycle 1 004_Agent_cloudflare_stack_capabilities.md | P2 발견 baseline |
| Cycle 1 005_Agent_payment_integration.md | P3 발견 baseline |
| Cycle 1 006_Synthesis_cycle1.md | 비대칭 발견·3안 시드 |

## Communication Log

| # | Direction | Peer | Summary | Stage |
|---|-----------|------|---------|-------|
| 1 | ← | P1 (003) | API 0·결제 0·prod data 0 → Partial 진입 비용 0의 근거 | Cycle 2 |
| 2 | ← | P2 (004) | D1 10GB·KR ISP·생태계·outage·throughput 리스크 시드 | Cycle 2 |
| 3 | ← | P3 (005) | Stripe Korea 부재 + Toss/PortOne × CF Workers feasibility | Cycle 2 |
| 4 | ← | P4 (007) | (P4 미완료 — operating cost 통합은 synthesis 009에서) | Cycle 2 |
| 5 | → | Synthesis (009) | 13개 리스크 매트릭스 + 3안 권고(Partial 70-75%) + Brief 결정 5 업데이트 시사 | Cycle 2 |
| 6 | → | Final (010) | C.4 가정 깨짐 표를 사용자 의사결정 보드로 활용 | Cycle 2 |
