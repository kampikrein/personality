---
id: "010"
type: research
title: "Cloudflare Workers + D1 + Hono 전환 검토 — 최종 연구 보고서"
created: 2026-04-26
traces_brief: "001"
traces_research: "002"
traces_synthesis: ["006", "009"]
summary: >
  현 Rails 8 + SQLite + Hotwire 백엔드를 Cloudflare Workers + D1 + Hono로
  전환할지 장기 관점(2026~2029)에서 평가한다. 5관점·2사이클 병렬 연구를 통해
  Brief 001의 7개 deliverable을 모두 산출했고, **Partial migration**(신규 모바일
  API만 CF Workers로, Rails 웹+admin은 유지)을 신뢰도 70-75%의 defensible
  default로 권고한다. 핵심 발견: 의사결정 변수는 운영비(3년 격차 $3K)가 아니라
  엔지니어 시간(3년 격차 $67K)이며, 100K MAU 시점에 CF가 Rails보다 17× 비싸진다.
  Stripe Korea 가맹점 부재(2026-04)로 Brief 결정 5의 "글로벌 병행"은
  "단계적 병행"으로 재해석된다.
keywords: [cloudflare, workers, d1, hono, rails, migration, partial-migration, korea, payment, decision]
---

# Cloudflare Workers + D1 + Hono 전환 검토 — 최종 연구 보고서

## Research Overview

### Background & Motivation

본 연구는 Brief 001에서 정의된 대로, 현 **Rails 8 + SQLite + Hotwire** 백엔드를 추천받은 **Cloudflare Workers + D1 + Hono** 스택으로 전환할지 **장기 관점(2026~2029)**에서 평가한다. 사용자는 외부에서 "Cloudflare가 서버 구동에 적절하다"는 추천을 받았고, 체계적 근거로 판단하고자 했다.

요구사항 3가지는 양 스택 모두 원리적 충족 가능:
- 외부 공개·접속 (인터넷 접근)
- 결제(과금) 처리

따라서 결정 변수는 "어떻게 구현하는가"가 아니라 **"전환의 비용·리스크·장기 정합성"**이다.

### Research Scope

Brief 001의 7개 In Scope deliverable을 5개 연구 관점·2개 사이클로 병렬 수행:

| Cycle | 관점 | 담당 | 출처 |
|-------|------|------|------|
| 1 | P1: 현 Rails 자산·제약 실측 | 내부 코드 분석 | [`003`](./003_Agent_current_rails_assets.md) |
| 1 | P2: CF 스택 역량·한계 (2026) | 외부 리서치 | [`004`](./004_Agent_cloudflare_stack_capabilities.md) |
| 1 | P3: 결제 통합 가능성 | 외부+내부 | [`005`](./005_Agent_payment_integration.md) |
| 2 | P4: 마이그비용 + 운영비 모델링 | 정량 분석 | [`007`](./007_Agent_migration_and_operating_cost.md) |
| 2 | P5: 리스크 매트릭스 + 3안 권고 | 종합 판단 | [`008`](./008_Agent_risk_and_recommendation.md) |

### Related Documents

- [`001_Brief_cloudflare_migration_research.md`](./001_Brief_cloudflare_migration_research.md) — 연구 방향 Brief
- [`002_Research_cloudflare_migration_checkpoint.md`](./002_Research_cloudflare_migration_checkpoint.md) — 연구 체크포인트
- [`006_Synthesis_cycle1.md`](./006_Synthesis_cycle1.md) — Cycle 1 종합
- [`009_Synthesis_cycle2.md`](./009_Synthesis_cycle2.md) — Cycle 2 종합

---

## Perspective 1: 현 Rails 스택 자산·제약 실측

### Status Analysis

**스택 (실측, 2026-04 기준)**
- Rails 8.1.2 + Puma + **SQLite** (dev/test/**production 전부** — `server/config/database.yml` 확인)
- Hotwire 3종 (Turbo + Stimulus + importmap) + Tailwind CSS + Propshaft
- Solid Queue / Cache / Cable (Rails 8 DB-backed infra)
- Kamal + Thruster 배포
- RSpec/FactoryBot/Faker

**실측 지표**
- 5,448 Ruby LOC + 1,788 ERB LOC + 340 JS LOC + 2,641 spec LOC
- 15 모델, 13 컨트롤러, 20 services, 27 ERB 뷰, 8 Stimulus, 18 RSpec
- 14 DB 테이블, 9 JSON 컬럼, 14 FK, polymorphic/STI/Active Storage **없음**
- 17 라우트, **모두 HTML** (JSON API 0개)

### Detailed Findings

**전환 비용을 낮추는 자산 결여 (Greenfield 신호)**

| 자산 | 실측 상태 | 함의 |
|------|----------|------|
| production DB | `server/storage/`에 `production.sqlite3` **부재** | 데이터 마이그레이션 비용 ≈ 0 |
| JSON API | 17 라우트 모두 HTML 렌더 | 보존할 API 계약 없음 |
| 모바일 ↔ 서버 API | `mobile/`이 서버 API **사용 안 함** | 클라이언트 호환성 부담 0 |
| Solid Queue | `app/jobs/`에 base class만, 실제 잡 0개 | 미사용 — 잃을 가치 없음 |
| Solid Cache | `Rails.cache.*` 호출 0개 | 미사용 |
| Solid Cable | `app/channels/` 디렉터리 **없음** | 미사용 |
| Active Storage / Action Text | 사용 0 | 미사용 |
| 결제 | gem/모델/컨트롤러 0 | 미구현 |

**전환 비용을 만드는 자산**

| 자산 | 위치 | 이식 난이도 |
|------|------|-----------|
| 도메인 services 1,850 LOC (scoring, tone-filter, restricted-terms, insights) | `server/app/services/` | **낮음** — 순수 로직, TS 1:1 이식 |
| 15 모델 (associations 단순) | `server/app/models/` | 낮음 — Drizzle/Prisma 매핑 |
| 13 컨트롤러 + admin | `server/app/controllers/` | 중간 — Hono 핸들러 신규 작성 |
| 27 ERB 뷰 | `server/app/views/` | 중간 — SPA 또는 Hono SSR |
| **Hotwire Turbo Frame**: 2 템플릿만 사용 (assessment question flow) | 1개 흐름 | 중간 — **국지적**, 전면 재설계 아님 |
| 8 Stimulus 컨트롤러 | `server/app/javascript/controllers/` | 낮음 — vanilla JS 또는 라이브러리 교체 |
| **`User.encrypts :email, deterministic: true`** | `app/models/user.rb` | 중간 — 수동 AES-GCM + deterministic IV (login-by-email 호환) |
| 9 SQLite JSON 컬럼 | 스키마 | 중간 — D1 JSON1 함수 가능, JSONB 인덱싱 부재 |
| 18 RSpec 파일 (2,641 LOC) | `server/spec/` | 중간 — Vitest/bun test 재작성 |
| Kamal 배포 | `server/config/deploy.yml` | 낮음 — Wrangler deploy로 교체 |

### Caveats & Risks

1. **CLAUDE.md 부정확**: "Rails 8+ 백엔드 (PostgreSQL)"로 기재돼있으나 실제는 SQLite(production 포함). 이는 의사결정 시 정확한 기준선 사용을 위해 별도 수정 필요.
2. **Solid* dead weight 보유**: Brief가 "Rails 8 핵심 가치"로 평가했으나 실제 미사용. 이는 마이그 비용을 낮추는 동시에 **현 Rails의 가치**도 약화시킨다.
3. **미배포 시스템에 가까움**: production data 0 + API 0 + 결제 0 = 사실상 베타 이전 상태.

### Summary

현 시스템은 **Greenfield에 매우 가까운 상태**. Brief가 가정한 "전면 재작성 부담"의 상당 부분이 사실상 존재하지 않는 자산의 보존 비용이었다. 동시에 Rails의 가치(Hotwire admin, Solid 통합)도 실제 사용량 기준으로는 제한적이다.

---

## Perspective 2: Cloudflare 스택 역량·한계 (2026-04)

### Status Analysis

**Workers Runtime (검증된 2026-04 수치)**
- Free: 일 100K 요청, 요청당 CPU 10ms
- Paid: $5/월 + 10M req + 30M CPU-ms 포함, 초과 $0.30/M req · $0.02/M CPU-ms
- CPU: 30s default (5min max), 메모리 128MB/isolate, 스크립트 10MB(압축), 동시 outbound 6 connections
- 콜드 스타트 ~5ms baseline (스크립트 크기에 따라 증가)

**D1 (검증된 2026-04 수치)**
- Free: 10 DBs/account, 500MB/DB, 5GB total
- Paid: **10GB/DB 하드캡 (상향 불가)**, 50,000 DBs/account, 1TB total
- Worker당 1k 쿼리, 100KB SQL stmt, 2MB row
- 25B reads + 50M writes/월 포함, 초과 reads $0.001/M, **writes $1/M**, 스토리지 $0.75/GB-month
- 단일 스레드 per DB: 1ms 쿼리 ≈ 1k qps, 100ms 쿼리 ≈ 10 qps
- 트랜잭션: snapshot isolation, **interactive transaction 없음**
- 읽기 복제: **public beta** (2025-04 발표 후 1년+ 지속, 2026-04 GA 미달성)

**Hono**: v4.12.15 (안정), Type-safe routing, RPC 기능, 미들웨어 생태계 (auth, CORS 등)

**주변 서비스**
| Rails 컴포넌트 | CF 대체 | GA 상태 (2026-04) |
|---------------|---------|------------------|
| Active Storage | R2 | GA |
| Rails.cache | KV | GA |
| Solid Queue | Queues / Cron Triggers | GA |
| Solid Cable | Durable Objects + WebSocket | GA |
| Hyperdrive | 외부 PG 가속 | GA |

### Detailed Findings

**Rails → CF 매핑의 격차**

| Rails 패턴 | CF 대체 | 격차 |
|-----------|---------|------|
| ActiveRecord `transaction do ... end` | D1 batch only (interactive 없음) | 패턴 재설계 필요 |
| Rails 콘솔 | wrangler dev / D1 query | DX 가벼워짐 |
| ActiveRecord encrypted attributes | 수동 AES-GCM | 보안 검증 부담 |
| SQLite JSON1 (현 9 컬럼) | D1 JSON1 (동일) | 인덱싱 전략 차이 |
| ActiveJob retry/scheduler | Queues + Cron Triggers (15min cap) | 수동 조립 |
| Native gem (image_processing, bcrypt) | Workers 전용 라이브러리 또는 Web Crypto | 라이브러리 교체 |
| ERB views | Hono SSR / 별도 SPA | 뷰 레이어 신설 |

**한국 컨텍스트 발견**

- **Seoul (ICN) PoP 라우팅 불일치**: 일부 한국 ISP가 KT→LAX, SK→HKG로 라우팅 (한국-미국·홍콩 피어링비 분쟁 결과). 600ms+ 패널티 가능.
- **한국 메인스트림 백엔드 채택 부재**: 토스/당근/쿠팡 등 사용 증거 없음. 사이드프로젝트(부동산 크롤러, 게스트북, 포트폴리오) 수준만 확인.
- **CF 2025년 outage 3건**: 11월 4h10m, 12월 25min, 6월 Workers KV/Access 영향 — vendor 안정성 한계.

### Caveats & Risks

1. **D1 10GB/DB 하드캡**은 장기 관점에서 강한 천장 — 상향 협의 불가능, 샤딩 강제.
2. **D1 단일 스레드** 특성으로 무거운 쿼리가 throughput 천장 결정.
3. **D1 read replication 1년+ beta**: 읽기 확장성을 미성숙 기능에 의존.
4. **한국 ISP 라우팅의 구조적 원인**: 일시적 현상이 아니라 피어링비 분쟁의 결과 → 단기 해소 기대 어려움.
5. **CF outage**: 가용성 SLA가 99.99%여도 2025년 실측 다수 사고. 의존 심화 시 영향 큼.

### Summary

CF 스택은 GA 성숙도가 양호하지만, **한국 컨텍스트에서 일반적 베스트 프랙티스의 단순 적용이 어렵다**. D1의 강한 천장과 ISP 라우팅 문제가 "엣지 = 빠르고 싸다"의 통념을 약화시킨다.

---

## Perspective 3: 결제 통합 가능성 (한국+글로벌)

### Status Analysis

**현 상태**: `server/`에 결제 관련 gem/모델/컨트롤러 **0** — 어느 스택을 선택하든 신규 작성.

### Detailed Findings

**6셀 매트릭스** (검증 완료)

| PG × Stack | Rails-Kamal | CF Workers+Hono | 비고 |
|-----------|-------------|------------------|------|
| **Toss Payments** | F | F | 50 LOC HMAC-SHA256 (Web Crypto API) — 가장 가벼움 |
| **PortOne (구 아임포트)** | FC | F | 공식 `@portone/server-sdk` (JS), Standard Webhooks 스펙 |
| **Stripe** | FC | FC | **Stripe Korea 가맹점 엔티티 부재 (2026-04)** — NICEPay 파트너십만 |

(F = Feasible, FC = Feasible with caveats)

**LOC 추정**
- Toss × Workers: 300-400 (가장 가벼움)
- Toss × Rails: 400-500
- PortOne × Workers: 500-700
- PortOne × Rails: 700-1,000 (Ruby SDK 부재, REST 직접)
- Stripe × Workers: 300-600 (Hono 공식 예제)
- Stripe × Rails: 400-800

**CF Workers 결제 결과**
- 콜드 스타트 ~5ms: webhook 처리에 영향 미미
- CPU 30s default: webhook 처리에 충분
- D1 idempotency: `UNIQUE(event_id)` 인덱스로 표준 구현
- Workers 6 outbound 동시 연결: 직렬 흐름은 무관, 병렬 정합성 검증 시 주의

**한국 규제**
- 전자금융거래법은 **PG 운영자**에게 적용 (가맹점이 아닌 PG측 규제)
- 가맹점이 PG-hosted 결제창을 쓰면 PCI-DSS 범위는 **SAQ A** (분기별 ASV 스캔)
- 개인정보 국외 이전: 고지+동의 의무 (CF 글로벌 인프라 사용 시)
- **서버 지리 위치 강제 조항 없음** (가맹점 → CF Workers 가능)

**Stripe Korea 부재의 함의**
- 2026-04 현재 한국 거주 운영자가 Stripe로 한국 사용자 결제 직접 받기 **불가능**
- 가능한 경로: 해외 법인 + 한국 사용자 NICEPay 경유 (제한적)
- 2024-2026 3년간 Stripe Korea 신규 발표 없음 → 단기 변화 어려움

### Caveats & Risks

1. **Stripe Korea**: 글로벌 결제 옵션이 한국 거주 운영자에게 닫혀있음. Brief 결정 5의 "글로벌 병행" 가정 약화.
2. **개인정보 국외 이전**: 차단 사유는 아니나 동의 UX + 고지 의무 운영 부담.
3. **결제 LOC는 스택 결정 변수가 아니다** — 6셀 격차 100~700 LOC 수준.

### Summary

결제 통합은 **양 스택 모두 실현 가능하며, 결제 자체가 스택 선택의 결정 변수는 아니다**. 단 Stripe Korea 부재로 한국 우선 시 토스/포트원만 실용 경로이며, 글로벌 병행은 단계적으로만 가능.

---

## Perspective 4: 마이그비용 + 장기 운영비 정량 모델링

### Status Analysis

3개 마이그레이션 시나리오 + 3개 트래픽 시나리오 × 2개 스택 × 2개 시점 정량 모델.

### Detailed Findings

**A. 마이그레이션 비용 (MAN-WEEK + 환산 인건비, 시니어 백엔드 $3,200/wk 가정)**

| 시나리오 | 일회성 | 1년 유지 | 3년 총합 | 환산 인건비 |
|---------|--------|---------|---------|------------|
| **Stay** (Rails 유지 + 모바일 API + 결제 신규) | 6.5 MW | 4.0 MW/yr | 18.5 MW | $59,200 |
| **Partial** (Rails 웹+admin 유지, 모바일 API만 CF) | 14.5 MW | 5.0 MW/yr | 29.5 MW | $94,400 |
| **Full** (전면 재작성) | 30.5 MW | 3.0 MW/yr | 39.5 MW | $126,400 |

**Stay 항목 (6.5 MW)**: 모바일 API 신설 2.5 + 결제(Toss+PortOne) 3.0 + 통합 1.0
**Partial 항목 (14.5 MW)**: Stay의 6.5 + Workers 신규 API 도메인 services 이식 4 + Auth 브릿지 2 + D1 스키마 + Wrangler CI/CD 2
**Full 항목 (30.5 MW)**: Partial의 14.5 + Hotwire admin 대체 6 + 13 컨트롤러 → Hono 핸들러 5 + 27 ERB 뷰 → SPA/SSR 4 + RSpec → Vitest 1

**B. 운영비 (3년 총합, USD)**

| 트래픽 시나리오 | Rails-Kamal (Hetzner DE/FI) | CF Workers Stack |
|---------------|--------------------------|------------------|
| **Low** (1K MAU, 30K req/월, 100MB DB) | $342 | $225 |
| **Medium** (10K MAU, 1M req/월, 2GB DB) | $500 | $229 |
| **High** (100K MAU, 30M req/월, 15GB DB) | $2,093 | **$4,991 + 8 MW 샤딩 (~$25,600 일회성)** |

**검증된 2026-04 가격**
- Hetzner CX23 €3.99 / CPX22 €7.99 / CPX42 €25.49 (DE/FI)
- Workers Paid $5/월 + 10M req + 30M CPU-ms 포함
- D1: 25B reads + 50M writes/월 포함, $0.001/M reads, **$1/M writes**, $0.75/GB-month

**C. 크로스오버 분석**

- **CF 우위 구간**: 0~30K MAU (Low/Medium 시나리오)
- **Break-even**: 30~70K MAU
- **Rails 우위 구간**: 70K+ MAU (D1 10GB 하드캡 + 쓰기 단가 + 샤딩 비용)
- **D1 10GB 도달 예상**: ~70K 사용자 (~150KB/user 도메인 누적 가정)
- **Workers Free → Paid**: Low 시나리오부터 강제

### Caveats & Risks

1. **MAN-WEEK 추정의 불확실성**: 페이싱(0.4-0.7 KLOC/wk)은 시니어 가정. 주니어/중급은 1.5-2배 가능.
2. **운영비는 의사결정 변수가 아님**: Low/Medium 격차 $200~300/3y는 노이즈.
3. **High 시나리오 도달의 불확실성**: 1-3년 내 100K MAU 도달은 시장·마케팅 변수 — 연구 범위 밖.

### Summary

**의사결정 변수의 재정의**: 3년 엔지니어 인건비 격차(~$67K Stay vs Full) ≫ 3년 운영비 격차(~$3K). 비율 20× 이상 → "어느 스택이 운영비가 싼가"는 결정 변수가 아니라 **노이즈**. 진짜 변수는 **사람의 시간**.

**100K MAU 반전점**: 통념과 반대로 CF가 17× 비싸짐. 장기 관점에서 "처음엔 싸도 나중엔 비싸지는" 선택.

---

## Perspective 5: 리스크 매트릭스 + 3안 권고

### Status Analysis

13개 리스크를 확률×영향도로 점수화하고 외부 evidence로 calibration.

### Detailed Findings

**A. 리스크 매트릭스 (High/Med 점수 추출)**

| # | 리스크 | 확률 | 영향 | 점수 | 영향 받는 안 |
|---|-------|------|------|------|------------|
| R5 | Stripe Korea 가맹점 부재 (2026-04) | 확정 | High | High | 모든 안 — Brief 결정 5 약화 |
| R11 | CF 2025 outage 3건 (총 4h35m+ 영향) | Med | High | High | Partial, Full |
| R2 | D1 10GB/DB 하드캡 (장기 누적) | High | High | High | Partial(API DB), Full |
| R3 | D1 read replication 1년+ beta | Med | Med | Med | Partial, Full |
| R7 | D1 단일 스레드 throughput 천장 | Med | Med | Med | Partial, Full |
| R9 | DX gap (Rails console vs wrangler dev) | High | Med | Med | Partial, Full |
| R10 | 단일 개발자 유지 부담 | High | Med | Med | 모든 안 |
| R12 | D1 interactive transaction 부재 | High | Med | Med | Partial, Full |
| R1 | 한국 ISP Seoul PoP 라우팅 불일치 | Med | Med | Med | Partial, Full |
| R4 | Korean 백엔드 메인스트림 부재 | High | Low | Med | Partial, Full |
| R8 | Workers 콜드 스타트 (~5ms+) | Med | Low | Low | Partial, Full |
| R6 | CF 벤더 락인 심화 | High (수용) | Low (사용자 수용) | Low | Partial, Full |
| R13 | 개인정보 국외 이전 고지 의무 | High | Low | Low | Partial, Full |

**외부 evidence calibration**
- **R11 (CF outage)**: Cloudflare Status 2025-11 4h10m, 2025-12 25min, 2025-06 Workers KV/Access. 추측 아닌 사실.
- **R1 (한국 ISP 라우팅)**: KT-LAX, SK-HKG 라우팅의 구조적 원인은 한국-해외 피어링비 분쟁. 일시적 현상 아님.
- **R5 (Stripe Korea)**: 2024-2026 3년간 신규 발표 없음 → 단기 해소 신호 부재.

**B. 3안 권고**

#### Stay (Rails 유지)

- **Definition**: 현 Rails 8 + SQLite + Hotwire 유지. 모바일 API와 결제만 Rails에 신설.
- **Selection conditions**:
  - 한국 사용자 100% 또는 거의 100%
  - 단일 또는 매우 작은 개발팀
  - Ruby/Rails 친숙도가 TS보다 우세
  - 1-3년 MAU 100K 미만 + 도메인 데이터 < 10GB
- **Realized risks**: R10(단일 개발자 부담), R5(결제 글로벌 보류) — 가장 적은 리스크
- **Mitigations**: 검증된 스택, 검증된 한국-호스팅 경로
- **Migration path**: Rails에 mobile API JSON 컨트롤러 추가 + Toss/PortOne 통합
- **Decision test**: "내가 이 코드를 1년 후에도 혼자 유지할 자신이 있는가?"

#### Partial (Strangler — 모바일 API만 CF, Rails 유지) — **권고 default**

- **Definition**: 신규 모바일 API를 Cloudflare Workers + Hono + D1에 작성. Rails 웹 + admin은 유지. 결제도 Workers에 작성.
- **Selection conditions** (Partial이 default가 되는 조건):
  - 사용자 분포 한국 ≥ 80%
  - 1년 내 MAU 수만 이내 (D1 10GB 도달 전)
  - 1-2명 개발 (Full 부담 큼)
  - Ruby/Rails + TypeScript 양쪽 친숙
  - 결제 = 한국 우선
- **Realized risks**: 신규 API 영역에 한해 R1, R2, R3, R7, R9, R12 일부. Rails admin은 영향 없음.
- **Mitigations**:
  - **자산 보존**: 미사용 자산도 잃을 가치 0이지만 결정 가역성 높음
  - **리스크 격리**: CF 의존이 모바일 API에만 한정
  - **결정 가역성**: 1년 운영 후 Stay 또는 Full로 전환 결정 가능
- **Migration path**:
  1. Workers + Hono + D1 + Drizzle 보일러플레이트 셋업
  2. 도메인 services 1,850 LOC TS 이식 (테스트 동행)
  3. 모바일 API JSON 엔드포인트 신설 (Hono router)
  4. Toss webhook + D1 idempotency 구현
  5. Flutter 앱이 새 API 소비 시작
  6. Rails 웹 + admin 그대로
- **Decision test**: "1년 후 데이터를 보고 Stay 또는 Full로 재결정할 의향이 있는가?"

#### Full (전면 재작성)

- **Definition**: 백엔드 전체를 CF Workers + D1 + Hono로 재작성. Rails 폐기.
- **Selection conditions**:
  - 글로벌 확장 의도 명확 + 해외 법인 자원
  - 풀팀 (3명+) 또는 TS 매우 친숙한 1인
  - Hotwire admin을 다른 프론트엔드(SPA/Astro)로 재구축 의지
  - 1년 내 MAU 100K 미만 (D1 천장 전)
  - **장기 관점에서 단일 코드베이스 유지의 가치 > 검증된 Rails 가치**
- **Realized risks**: 13개 리스크 모두. 비가역.
- **Mitigations**: 단일 스택 통합 운영, TS 단일 언어, CF 생태계 단일
- **Migration path**: 6-9개월 빌드 후 한 번에 cutover
- **Decision test**: "5년 후 Rails 8.x EOL 시점에 정정 비용이 지금 Full 비용보다 클 것이라 확신하는가?"

#### C. 최종 권고

**Partial migration, 신뢰도 medium-high (70-75%)**

**가정 5개** (가정이 깨지면 Stay 또는 Full로 회귀):
1. 사용자 분포 한국 ≥ 80%
2. 1년 내 MAU 수만 이내
3. 단일 또는 매우 작은 개발팀
4. Ruby/Rails + TypeScript 양쪽 친숙
5. 결제 = 한국 우선 (글로벌은 단계적)

**가정 깨짐 시 회귀 방향**

| 깨진 가정 | 회귀 방향 |
|----------|----------|
| 한국 ≥ 80% 깨짐 (글로벌 비중 확대) | Full 검토 (단 Stripe Korea 해결 필요) |
| 1년 내 100K+ MAU 명확 | Stay (CF 천장 도달 우려) 또는 Full (대규모 재설계) |
| 풀팀 확보 | Full 가능 |
| Ruby 친숙만 | Stay |
| TS 친숙만 | Full (단 Korea 가정 충족 시) |
| 글로벌 결제 시급 | Stay + 해외 법인 또는 Full + 해외 법인 |

### Caveats & Risks

1. **권고는 5개 가정 위에 서있음**. 사용자가 가정 검증 후 자기 상황에 맞게 재해석해야 함.
2. **Brief 결정 5 업데이트 시사**: Stripe Korea 부재로 "동시 병행" → **"단계적 병행"**으로.
3. **Brief Decision 6 존중**: Partial은 default이지 유일 정답이 아님. 사용자가 Stay 또는 Full을 선택해도 정당.

### Summary

13개 리스크 + Partial migration 권고(70-75% 신뢰도) + 5개 가정 + 깨짐 조건이 산출됨. **권고는 정량(P4)과 정성(P5) 양쪽이 같은 결론으로 수렴**한 결과.

---

## Cross-Analysis

### Inter-Perspective Relationships

**P1 ↔ P2**: 매핑 격차의 정확한 모양
- P1의 자산 부재(Solid* 미사용, API 0, prod data 0) × P2의 매핑 능력 → 마이그 비용을 **크게 낮춤**
- P1의 Hotwire 제한(2 템플릿) × P2의 SSR/SPA 필요성 → 국지적 재설계로 충분
- P1의 User.encrypts × P2의 Web Crypto → 수동 구현이지만 가능

**P1 ↔ P3**: 결제 = 양 스택 동등 출발
- P1: 결제 코드 0 → 어느 스택이든 신규
- P3: 6셀 모두 가능, LOC 격차 미미
- 결제는 스택 결정 변수에서 제거됨

**P2 ↔ P3**: CF Workers + 결제의 실측 적합성
- P2 한도(CPU 30s, 콜드 5ms) × P3 webhook 요구 → 적합
- P2 한국 ISP 라우팅 × P3 한국 결제 → 결제 webhook은 PG→백엔드 단방향이므로 영향 적음

**P4 ↔ P5**: 비용과 리스크의 동일 결론 수렴
- P4 정량(Partial 14.5 MW 중간 비용) × P5 정성(Partial 중간 리스크) → Partial이 양쪽에서 최적
- P4 100K 반전점 × P5 D1 천장 리스크 → 같은 사실의 두 표현
- P4 운영비 노이즈 × P5 권고 가정 → "운영비는 결정 변수 아님" 확정

### Common Patterns

| 패턴 | 모든 관점이 신호 |
|------|----------------|
| **현 시스템 = Greenfield에 가까움** | P1(자산 부재), P2(API-first 자연), P3(결제 0), P4(이식 비용 모듈화 가능), P5(결정 가역성 높음) |
| **한국 컨텍스트의 특수성** | P2(ISP 라우팅, 메인스트림 부재), P3(Stripe Korea 부재), P5(외부 evidence 한국 발) |
| **장기 천장은 D1**, 콜드 스타트나 CPU가 아님 | P2(10GB 하드캡), P4(70K MAU 도달), P5(샤딩 강제) |
| **사람의 시간 ≫ 클라우드 비용** | P4(20× 비율), P5(R10 단일 개발자), Brief의 "장기 관점" 정의 |

### Conflicting Items

**상충 1**: 마이그 비용 vs 운영 리스크
- 비용 측 (P1+P4): 전환은 싸다 ("지금이 골든 윈도우")
- 리스크 측 (P2+P5): 운영은 위험하다 ("검증된 스택 유지가 안전")
- **해소**: Partial이 양 신호를 동시에 수용 — 진입 비용 낮고 리스크 격리.

**상충 2**: "엣지 = 빠름" vs 한국 ISP 현실
- CF 일반 논리: 글로벌 엣지 → 사용자 가까움
- P2 발견: 한국 일부 ISP에서 600ms+ 패널티
- **해소**: 사용자 분포가 한국 100%면 엣지 가치 약화. 글로벌 비중 클수록 엣지 가치 ↑.

**상충 3**: D1 매력 vs D1 한계
- 매력: SQLite 호환 → 마이그 친화
- 한계: 10GB 하드캡, 단일 스레드, 트랜잭션 제약
- **해소**: 단기/중기 매력 + 장기 천장 → Partial로 안전하게 검증 후 결정.

---

## Comprehensive Conclusion

### 핵심 발견 (우선순위 순)

1. **[Critical] R-010-F1: 의사결정 변수는 운영비가 아니라 엔지니어 시간** — 3년 엔지니어 인건비 격차 ~$67K (Stay vs Full)가 운영비 격차 ~$3K를 20배 이상 압도. "어느 스택이 더 싼가"의 통념적 질문은 이 프로젝트 규모에서 **노이즈**. 진짜 질문: "누가 작성하고 유지하는가, 무엇이 가역적인가". *(P4)*

2. **[Critical] R-010-F2: 현 시스템은 Greenfield에 매우 가까움** — production data 0 + API 엔드포인트 0 + 모바일이 서버를 안 씀 + Solid Queue/Cache/Cable 미사용 + 결제 미구현. 이는 Partial migration의 진입 비용을 매우 낮추고, 동시에 현 Rails의 보존 가치도 약화시킴. *(P1)*

3. **[Critical] R-010-F3: Partial Migration이 defensible default** — P4(중간 비용) + P5(중간 리스크)가 같은 결론으로 수렴. 신뢰도 70-75%. 권고 가정 5개 위에 서있으며, 가정 깨질 때 Stay 또는 Full로 회귀. *(P4, P5)*

4. **[Critical] R-010-F4: 100K MAU 반전점 — CF가 Rails보다 17× 비싸짐** — D1 10GB 하드캡(70K MAU 도달) + 쓰기 단가 $1/M + 샤딩 비용 8 MW($25,600 일회성). "엣지 = 쌈"의 통념이 이 도메인에서 부정. 장기 관점에서는 처음엔 싸도 나중엔 비싸지는 선택이 될 수 있음. *(P4)*

5. **[High] R-010-F5: Stripe Korea 가맹점 부재 (2026-04)** — Brief 결정 5의 "글로벌 병행"이 운영 주체 분리(해외 법인) 없이는 불가능. 한국 우선 시 Toss/PortOne만 실용 경로. 2024-2026 3년간 진전 없음 → 단기 해소 어려움. **Brief 결정 5는 "단계적 병행"으로 재해석 필요**. *(P3, P5)*

6. **[High] R-010-F6: 한국 컨텍스트의 구조적 리스크 3종** — (a) ISP Seoul PoP 라우팅 불일치(피어링비 분쟁의 결과, 600ms+ 패널티), (b) CF 2025년 outage 3건 (총 4h35m+ 영향), (c) Korean 백엔드 메인스트림 채택 부재(인력·문서·사례 제한). 모두 외부 evidence로 검증. *(P2, P5)*

7. **[High] R-010-F7: D1 10GB/DB 하드캡은 상향 불가** — 장기 데이터 누적 시 샤딩 강제. 70K MAU 추정 도달. Rails-on-VPS의 "단일 인스턴스 수십~수백 GB" 사고방식 적용 불가. *(P2, P4)*

8. **[High] R-010-F8: Solid Queue/Cache/Cable 모두 dead weight** — Brief가 "Rails 8 핵심 가치"로 평가했으나 실제 사용 0개. 이는 Rails 유지 가치를 약화시키는 동시에 마이그 비용도 낮춤. *(P1)*

9. **[Medium] R-010-F9: Hotwire 자산 손실은 국지적** — Turbo Frame 2 템플릿 + Stimulus 8개. Brief가 가정한 "전면 재작성 부담"과 다름. 한 흐름의 설계 결정 수준. *(P1)*

10. **[Medium] R-010-F10: 결제 LOC는 스택 결정 변수가 아님** — 6셀 매트릭스 모두 실현 가능, 격차 100~700 LOC. 결제 통합 자체는 결정에 영향 미미. *(P3)*

11. **[Medium] R-010-F11: User.encrypts deterministic email은 수동 포팅 필요** — login-by-email 호환을 위한 deterministic IV 구현 + 테스트 부담. Partial/Full 시 발생. *(P1, P2)*

12. **[Medium] R-010-F12: D1 read replication 1년+ public beta 지속** — 읽기 확장성 의존이 미성숙 기능. 고 트래픽 시 읽기 분산 어려움. *(P2)*

### 5축 비교 결과 요약 (Brief 비교 프레임)

| 축 | 결과 |
|----|------|
| **요구사항 커버리지** (공개·접속·결제) | 양 스택 모두 충족. 결정 변수 아님. |
| **마이그레이션 비용** | Stay 6.5 MW / **Partial 14.5 MW** / Full 30.5 MW. 3년 인건비 격차 $67K. |
| **장기 운영비** | Low/Med 격차 $200~300/3y (노이즈). High에서 Rails 17× 우위. |
| **리스크** | Stay < Partial < Full. 한국 컨텍스트 특이 리스크 다수. |
| **확장성** | D1 10GB가 강한 천장 (70K MAU). Rails-VPS는 수직 확장 가능. |

### 3안 권고 + 선택 조건 요약

| 안 | 선택 조건 | 신뢰 |
|----|---------|------|
| **Stay** | 한국 100% + 1인 + Rails 친숙 + MAU 100K 미만 평생 | 보수적 안전 |
| **Partial (권고 default)** | 한국 ≥ 80% + 1년 내 수만 MAU + 1-2인 + 양쪽 친숙 + 한국 결제 우선 | **70-75%** |
| **Full** | 글로벌 + 해외 법인 + 풀팀 또는 TS 매우 친숙 1인 + 1년 내 100K 미만 | 조건부 정당 |

### 의사결정 테스트 (사용자 자가 진단)

권고 적용 전 사용자가 다음 5개를 확정해야 함:
1. **사용자 분포**: 한국 비중은? (≥80%? <80%?)
2. **1년 후 MAU 추정**: 수천? 수만? 수십만?
3. **개발 인력**: 1인? 2인? 3+인? Ruby와 TypeScript 친숙도는?
4. **글로벌 확장 의도**: 단기? 중기? 무한정 한국?
5. **결제 글로벌 시급도**: 1년 내? 3년 후? 하지 않음?

### 장기 관점 정량 정의

- **기간**: 2026-04 ~ 2029-04 (1~3년)
- **규모**: 저(1K) / 중(10K) / 고(100K) MAU 3단계
- **유지 공수**: Stay 4 MW/yr, Partial 5 MW/yr, Full 3 MW/yr (Full은 일회성 후 안정)
- **비용 임계**: 70K MAU = D1 10GB 하드캡 도달 = Partial→Full 또는 Stay 회귀 트리거
- **결정 가역성**: Stay > Partial > Full

---

## Incremental Summary

### 리서치 축
- **축 이름**: Cloudflare Workers + D1 + Hono 전환 검토 (전체)
- **핵심 질문**: 현 Rails → CF 전환의 비용·리스크·장기 정합성은? Stay/Partial/Full 중 어느 안인가?

### 핵심 발견 (우선순위 순)

1. **[Critical] R-010-F1: 의사결정 변수 = 엔지니어 시간** — 운영비 격차는 노이즈, 인건비 격차는 20× 더 큼.
2. **[Critical] R-010-F2: Greenfield 진실** — 시스템이 사실상 미배포 상태로 마이그 진입 비용 매우 낮음.
3. **[Critical] R-010-F3: Partial 권고** — 신뢰도 70-75%, 정량과 정성이 동일 결론으로 수렴.
4. **[Critical] R-010-F4: 100K MAU에서 CF 17× 비싸짐** — D1 하드캡 + 쓰기 단가 + 샤딩.
5. **[High] R-010-F5: Stripe Korea 부재** → Brief 결정 5는 "단계적 병행"으로 재해석.
6. **[High] R-010-F6: 한국 컨텍스트 구조적 리스크 3종** — ISP 라우팅, CF outage, 메인스트림 부재.
7. **[High] R-010-F7: D1 10GB 하드캡** — 장기 샤딩 강제.
8. **[High] R-010-F8: Solid* dead weight** — Rails 유지 가치 약화.
9. **[Medium] R-010-F9~F12**: Hotwire 국지적, 결제는 결정 변수 아님, User.encrypts 수동 포팅, D1 read replication beta.

### 결론

이 연구의 핵심 질문은 **부분 해결**: Stay/Partial/Full 3안의 정량 비용·정성 리스크·선택 조건이 모두 산출됨. 단 사용자의 5개 가정 검증(사용자 분포, MAU 추정, 인력, 글로벌 의도, 결제 시급)은 사용자 영역으로 이월. **Partial migration은 권고 default**이지만 사용자의 가정에 따라 Stay/Full도 정당.

### 미해결 사항

- **5개 가정의 사용자 검증** — 연구 범위 밖, 의사결정자 영역
- **CLAUDE.md의 "PostgreSQL" 기재 부정확** — 별도 수정 필요 (이 연구 산출물 아님)
- **Rails 8 EOL 시점에서의 정정 비용 vs Full 비용 비교** — 5년+ 시점 시뮬레이션은 본 연구 범위 초과 (Brief 정의 1-3년)

---

## Unresolved Items

| 항목 | 사유 | 처리 |
|------|------|------|
| 사용자의 5개 가정 검증 | 연구 범위 밖 (사용자 자기 상황 진단) | 의사결정 테스트로 사용자에게 이월 |
| Rails 8 EOL 후 5년+ 시점 시뮬레이션 | Brief 장기 정의(1-3년) 초과 | 본 연구 범위 외 |
| Stripe Korea 가맹점 등장 시점 | 외부 발표 의존 (확률 낮음) | 정기 모니터링 권장 |

---

## Referenced File List

| File Path | Related Perspective | Role/Content |
|-----------|-------------------|--------------|
| `001_Brief_cloudflare_migration_research.md` | All | 연구 방향·경계·평가 기준 정의 |
| `002_Research_cloudflare_migration_checkpoint.md` | All | 5관점·2사이클 실행 계획 |
| `003_Agent_current_rails_assets.md` | P1 | 현 Rails 자산·제약 실측 |
| `004_Agent_cloudflare_stack_capabilities.md` | P2 | CF 스택 역량·한계 (2026-04) |
| `005_Agent_payment_integration.md` | P3 | 결제 6셀 매트릭스 |
| `006_Synthesis_cycle1.md` | P1+P2+P3 | Cycle 1 교차 분석 (비대칭 발견) |
| `007_Agent_migration_and_operating_cost.md` | P4 | MAN-WEEK + 12셀 비용 매트릭스 |
| `008_Agent_risk_and_recommendation.md` | P5 | 13 리스크 + Partial 권고 |
| `009_Synthesis_cycle2.md` | P4+P5 | Cycle 2 통합 (비용·리스크 수렴) |
| `server/Gemfile`, `server/config/database.yml` | P1 | 현 스택 기준선 (실측) |
| `server/app/models/`, `server/app/controllers/` | P1 | 도메인 인벤토리 |
| `developers.cloudflare.com/workers/platform/limits` | P2 | Workers 한도 (2026-04) |
| `developers.cloudflare.com/d1/platform/limits` | P2 | D1 한도 (2026-04) |
| `docs.tosspayments.com`, `portone.io`, `stripe.com/docs` | P3 | PG API 문서 |

---

## 사용자에게 — 이 연구의 사용법

본 연구는 **결정을 내리지 않는다**. 결정은 5개 가정의 자가 진단에 달려있다.

**다음 단계 권장**:
1. 위 "의사결정 테스트" 5개 질문에 답한다.
2. 답에 따라 권고 표(`Comprehensive Conclusion § 3안 권고 + 선택 조건`)를 본다.
3. Stay/Partial/Full 중 자기 상황에 맞는 안을 선택한다.
4. 선택한 안을 `/scope`로 진입시켜 구현 설계를 시작한다 (예: `/scope` "Partial migration: 모바일 API on CF Workers").

**권고 default(Partial)를 따르는 경우**의 세부 진입 경로는 `Perspective 5 § Partial → Migration path`의 6단계 참조.

**Brief 결정 5 업데이트** (사용자 확인 권장):
- 기존: "결제 = 한국 우선 + 글로벌 병행"
- 신규: "결제 = 한국 우선 (Toss/PortOne) + 글로벌 단계적 병행 (Stripe Korea 등장 또는 해외 법인 마련 시)"
