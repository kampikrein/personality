---
id: "002"
type: research
title: "Cloudflare Workers + D1 + Hono 전환 검토 연구 (체크포인트)"
created: 2026-04-24
status: in-progress
traces_scope: "001"
summary: >
  Brief 001의 7개 deliverable을 5관점 2사이클 병렬 연구로 수행한다.
  Cycle 1은 현 Rails 실측·CF 외부 조사·결제 통합(독립 병렬),
  Cycle 2는 수치 모델링·리스크/권고(Cycle 1 의존).
keywords: [cloudflare, workers, d1, hono, rails, migration, research-checkpoint, parallel]
parallel_plan:
  total_perspectives: 5
  cycles:
    - cycle: 1
      perspectives: [1, 2, 3]
      depends_on: []
      status: completed
      agent_numbers: ["003", "004", "005"]
      synthesis_number: "006"
    - cycle: 2
      perspectives: [4, 5]
      depends_on: [1]
      status: completed
      agent_numbers: ["007", "008"]
      synthesis_number: "009"
  final_number: "010"
---

# Cloudflare Workers + D1 + Hono 전환 검토 연구 (체크포인트)

## Research Overview

### Background & Motivation

Brief 001에서 정의된 대로, 현 Rails 8 + SQLite + Hotwire 스택을 Cloudflare Workers + D1 + Hono 스택으로 전환할지 **장기 관점(2026~2029)**에서 평가한다. 사용자는 "Cloudflare가 서버 구동에 적절하다"는 외부 추천을 받았고, 체계적 근거로 판단하고자 한다.

### Research Scope

Brief 001의 **In Scope 7개 deliverable**을 커버:
1. 현 Rails 스택 역량·한계 분석
2. CF 스택 역량·한계 (2026년 기준)
3. 요구사항 매핑 (공개·접속·결제)
4. 마이그레이션 비용 시뮬레이션
5. 장기 운영비 비교
6. 위험·트레이드오프 분석
7. 권고안 도출 (Stay / Partial / Full)

### Research Perspectives

| # | 관점 | 담당 영역 | 타입 | 사이클 |
|---|------|----------|------|--------|
| 1 | **현 Rails 스택 자산·제약 실측** | SQLite 한도·Solid*·Hotwire admin·모델11·컨트롤러9+admin·Kamal 배포·RSpec | 내부 코드 | 1 |
| 2 | **Cloudflare 스택 역량·한계 (2026)** | Workers 런타임·D1·Hono·R2·KV·Queues·Durable Objects | 외부 리서치 | 1 |
| 3 | **결제 통합 가능성** | 토스페이먼츠·아임포트·Stripe × Rails/CF 각 스택 | 외부+내부 혼합 | 1 |
| 4 | **마이그비용 + 장기 운영비 모델링** | MAN-WEEK 추정 + 저/중/고 트래픽 × 1년/3년 비용 | 수치 분석 | 2 |
| 5 | **리스크 매트릭스 + 3안 권고** | 확률×영향도 + Stay/Partial/Full 선택 조건 | 종합 판단 | 2 |

### Related Documents

- Brief: [`001_Brief_cloudflare_migration_research.md`](./001_Brief_cloudflare_migration_research.md)
- Cycle 1 Agent reports: `003_Agent_current_rails_assets.md`, `004_Agent_cloudflare_stack_capabilities.md`, `005_Agent_payment_integration.md`
- Cycle 1 Synthesis: `006_Synthesis_cycle1.md`
- Cycle 2 Agent reports: `007_Agent_migration_and_operating_cost.md`, `008_Agent_risk_and_recommendation.md`
- Cycle 2 Synthesis: `009_Synthesis_cycle2.md`
- Final Research: `010_Research_cloudflare_migration.md`

## Preliminary Findings

Brief 001 작성 중 예비 확인됨:
- **현 DB = SQLite** (dev/test/production 전부, `server/config/database.yml` 확인)
- **도메인 모델 11개**: assessment, question, question_set, response, profile, user, anonymous_session, audit_log, consent, deletion_request, alert, domain_score, insight, personality_type
- **컨트롤러 9개 + admin**: sessions, accounts, assessments, assessment_questions, results, consents, deletion_requests + admin(dashboard, question_sets, alerts, audit_logs)
- **Hotwire 중심**: routes.rb 모두 HTML-first (API-first 아님)
- **결제 코드 미구현**
- **CF Workers 요금 $5/월 검증 완료** (Free: 일 100K 요청, 요청당 CPU 10ms)
- **D1 한도 검증 완료**: Free 500MB/DB, Paid 10GB/DB, 계정 5GB→1TB

## Parallel Execution Instructions

### Perspective 1: 현 Rails 스택 자산·제약 실측

**연구 질문**: 현 스택에서 **전환 시 버리거나 재작성해야 할 자산**과 **실측 제약**은 무엇인가?

**조사 대상**:
- `server/Gemfile` + `server/Gemfile.lock` 전체 (gem 조합·버전 의존)
- `server/config/database.yml`, `server/config/cache.yml`, `server/config/queue.yml`, `server/config/cable.yml`
- `server/config/routes.rb` — 라우트 전수 카운트 및 HTML vs JSON 분류
- `server/app/models/*.rb` — 11개 모델의 스키마·associations·validations·callbacks 분석
- `server/db/schema.rb` 또는 `server/db/migrate/*` — DB 스키마 복잡도
- `server/app/controllers/*.rb` + `server/app/controllers/admin/*.rb` — 9개+admin 컨트롤러 로직 깊이
- `server/app/views/**/*.erb`, `server/app/javascript/controllers/*.js` — Hotwire admin UI 복잡도
- `server/spec/**/*.rb` — 테스트 커버리지
- `server/config/deploy.yml` (Kamal) — 배포 구성
- `server/Procfile.dev`, `server/bin/dev` — 개발 인프라

**산출**:
- 자산 인벤토리 (파일 수, LOC, 의존 gem, Ruby-결합 패턴 식별)
- SQLite production 실측 (현 DB 크기, 테이블·인덱스 수)
- Hotwire admin 복잡도 평가 (stimulus 컨트롤러 수, Turbo Frame/Stream 사용)
- Solid* 실제 사용 여부 (설정만 있는지 실제 job/cache 정의가 있는지)
- 재작성 난이도 항목별 평가 (easy/medium/hard)

### Perspective 2: Cloudflare 스택 역량·한계 (2026년)

**연구 질문**: Workers + D1 + Hono + 주변 서비스의 2026-04 기준 정확한 **기능·한도·성숙도**는?

**조사 대상** (WebFetch/WebSearch):
- `developers.cloudflare.com/workers/platform/limits/` — Workers 런타임 상세 한도
- `developers.cloudflare.com/workers/runtime-apis/` — Node.js 호환성 목록
- `developers.cloudflare.com/d1/` — D1 기능 (읽기 복제, 트랜잭션, backup, import)
- `developers.cloudflare.com/d1/worker-api/` — D1 쿼리 API, 배치 처리
- `hono.dev/` — Hono v4 기준 기능·라우팅·미들웨어·RPC
- `developers.cloudflare.com/r2/`, `/kv/`, `/queues/`, `/durable-objects/` — 주변 서비스
- **국내 사례**: velog/tistory/DEV.to에서 한국 개발자의 CF Workers + D1 프로덕션 후기
- CF Workers + Hono 프레임워크 조합 사례 (특히 Rails/Django에서 온 사례)

**산출**:
- Workers 런타임 완전 스펙 (V8 isolate 제약, CPU/메모리, Node compat 목록, 콜드스타트 측정)
- D1 완전 스펙 (쿼리 처리량, 읽기 복제 지연, 트랜잭션 격리, 마이그 도구, backup/restore)
- Hono DX 평가 (타입 안전성, 라우팅 DX, 미들웨어 생태계)
- 주변 서비스 매핑 (Rails 각 구성요소의 CF 대체)
- 2026-04 현재 성숙도 (GA/Beta/알파 구분)
- 2026년 기준 한국 시장에서 CF Workers를 백엔드 스택으로 쓰는 실제 사례 존재 여부

### Perspective 3: 결제 통합 가능성 (한국+글로벌)

**연구 질문**: 토스페이먼츠·아임포트(포트원)·Stripe 각 PG가 Rails/CF Workers 스택과 조합 시 **실현 가능한가**, 어떤 제약이 있는가?

**조사 대상** (WebFetch/WebSearch):
- `docs.tosspayments.com/` — 토스 결제 API (결제창, webhook, 가상계좌 등)
- `portone.io/korea/ko/readme` — 포트원(아임포트) API
- `stripe.com/docs/` — Stripe API (Checkout, Payment Intents, webhook)
- **CF Workers 결제 사례**: Stripe + Workers, 토스 + Workers 블로그/포럼
- PCI-DSS compliance — CF Workers에서 카드 정보 접촉 여부
- Webhook 처리 — 서명 검증, idempotency, 재시도
- 한국 전자금융거래법 관련 (서버 위치 제약 있는지)

**조사 대상 (코드)**:
- `server/Gemfile` — 현재 결제 관련 gem 없음 확인
- `server/app/models/` — 결제 관련 모델 없음 확인

**산출**:
- PG 3개 × 스택 2개 = 6개 조합 매트릭스 (실현 가능성·제약·권장)
- 한국 결제 규제 상 CF Workers (엣지) 사용 시 주의점
- Webhook 처리의 콜드스타트/idempotency 영향
- 결제창 호스팅 책임 (PG? 앱 서버? CF?)
- 각 조합의 실장 복잡도 (LOC/MAN-DAY 어림)

## Remaining Work

- [ ] Cycle 1 — Perspective 1: 현 Rails 스택 실측
- [ ] Cycle 1 — Perspective 2: CF 스택 역량·한계
- [ ] Cycle 1 — Perspective 3: 결제 통합 가능성
- [ ] Cycle 1 — Synthesis (006)
- [ ] Cycle 2 — Perspective 4: 마이그비용 + 운영비 모델링
- [ ] Cycle 2 — Perspective 5: 리스크 매트릭스 + 3안 권고
- [ ] Cycle 2 — Synthesis (009)
- [ ] Final Research document (010)

## Referenced File List

| File Path | Role |
|-----------|------|
| `docs/6_backend/01_cloudflare_migration_research/001_Brief_cloudflare_migration_research.md` | 연구 방향 Brief |
| `server/Gemfile` · `server/config/database.yml` | 현 스택 기준선 |
| `server/app/models/` · `server/app/controllers/` | 재작성 규모 산정 입력 |
