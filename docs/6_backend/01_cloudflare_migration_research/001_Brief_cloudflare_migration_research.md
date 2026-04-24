---
id: "001"
type: brief
title: "Cloudflare Workers + D1 + Hono 전환 검토 연구"
created: 2026-04-24
status: completed
quality_profile: standard
priority_dimensions: [longevity, sustainability]
deep_critique: false
critique_docs: []
summary: >
  현재 Rails 8 + SQLite + Hotwire 스택을 장기 관점에서 Cloudflare Workers + D1 + Hono로
  전환할지 평가하는 연구 방향을 정한다. 5축(요구사항 커버리지·마이그레이션 비용·장기 운영비·
  리스크·확장성) 비교 프레임으로 Stay / Partial migration / Full migration 3안을 도출한다.
keywords: [cloudflare, workers, d1, hono, rails, migration, backend, infra, payment, research-brief]
---

# Cloudflare Workers + D1 + Hono 전환 검토 연구

## Intent

현재 Rails 8 + SQLite + Hotwire 기반 백엔드를 **Cloudflare Workers + D1 + Hono** 스택으로 전환할지 장기 관점에서 평가한다. 사용자는 "Cloudflare가 서버 구동에 적절하다"는 외부 추천을 받았고, 근거를 검토 없이 받아들이기보다 **자신의 프로젝트 맥락**에 맞는지 체계적으로 판단하려 한다.

Brief 산출 목적: 연구의 **방향·경계·평가 기준**을 정의하여 후속 `/research`가 근거 수집을 시작할 수 있도록 한다. 전환 결정은 연구 완료 후 내려진다.

요구사항 3가지 — 외부 공개(인터넷 접근 가능 URL), 외부 접속(누구나 접속 가능), 결제(과금 처리) — 는 두 스택 모두 원리적으로 지원하므로 **결정 요인이 아니며**, 연구는 "어떤 경로로 구현하는가 / 비용은 얼마인가"에 초점을 둔다.

## Context

### 현재 스택 (2026-04-24 실측)

**서버 (`server/`)**
- Rails 8.1.2 + Puma
- **SQLite (dev/test/production 전부)** — `config/database.yml` 확인, `storage/production.sqlite3` 사용
- Solid Queue / Solid Cache / Solid Cable — Rails 8의 DB 기반 통합 인프라
- Hotwire 3종(Turbo + Stimulus + importmap) + Tailwind CSS + Propshaft
- Kamal + Thruster 배포 구성
- RSpec/FactoryBot/Faker 테스트 스택
- Brakeman/Bundler-audit 보안 스택

**도메인 모델 (11개)**
`assessment` · `question` · `question_set` · `response` · `profile` · `user` · `anonymous_session` · `audit_log` · `consent` · `deletion_request` · `alert` · `domain_score` · `insight` · `personality_type`

**컨트롤러 (9개 + admin)**
- Public: sessions, accounts, assessments, assessment_questions, results, consents, deletion_requests
- Admin: dashboard (completion_rates, drop_off_analysis), question_sets, alerts, audit_logs

**라우트 특징**: 모두 HTML 중심 (resource :session, Hotwire 기반). **API-first 아님**. `shared/api-schema/`는 placeholder (비어있음).

**모바일 (`mobile/`)**: Flutter, 현 시점 서버 API 연결 **없음** — 로컬 동작 중심.

**결제 관련 구현**: 없음.

### 문서-실제 불일치

프로젝트 CLAUDE.md는 "Rails 8+ 백엔드 (PostgreSQL)"로 기재하나 실제는 SQLite. `docker-compose.yml`에 postgres:16 정의는 있지만 `database.yml`은 참조하지 않음. 이 Brief는 **실제 코드 상태**를 기준선으로 사용한다.

### 타깃 스택 (추천받은 구성 + 주변 서비스)

**핵심 3개 (사용자 언급)**
- **Cloudflare Workers**: V8 isolate 기반 엣지 런타임
- **D1**: Cloudflare의 분산 SQLite (읽기 복제, 트랜잭션 지원)
- **Hono**: TypeScript 기반 경량 웹 프레임워크 (Workers 런타임 최적화)

**Rails 주변 컴포넌트 대체 필요 (연구 범위에 포함)**
- Active Storage → **R2** (S3 호환 객체 스토리지)
- Solid Queue → **Queues / Durable Objects**
- Solid Cache → **KV / Cache API**
- Solid Cable (웹소켓) → **Durable Objects + WebSocket**
- Hotwire admin dashboard → Workers 상 SSR 또는 별도 SPA 프론트엔드

## Boundaries

### In Scope

| # | Item | Description |
|---|------|-------------|
| 1 | 현 Rails 스택 역량·한계 분석 | SQLite production 한도(동시 쓰기, DB 크기), Solid 스택 통합 가치, Hotwire admin 자산, Kamal 배포 경험 정리 |
| 2 | Cloudflare 스택 역량·한계 (2026년 기준) | Workers 런타임 제약(CPU 시간, 메모리, 모듈 API), D1 스펙·한도, Hono DX, 주변 서비스(R2/KV/Queues) 매핑 |
| 3 | 요구사항 3개 구현 경로 비교 | 외부 공개·접속·**결제**(한국 토스/아임포트 + 글로벌 Stripe) 각 요구의 두 스택 구현 방식을 대조표로 |
| 4 | 마이그레이션 비용 시뮬레이션 | 도메인 모델(11개) + 컨트롤러(9개) + admin(Hotwire) 재작성 규모를 **MAN-WEEK** 단위로 추정 |
| 5 | 장기 운영비 비교 | 저/중/고 트래픽 시나리오(수천 / 수만 / 수십만 MAU)별 1년·3년 운영비 비교 (호스팅·DB·대역폭·잡·스토리지) |
| 6 | 위험·트레이드오프 분석 | CF 종속 심화, D1 성숙도, Hotwire 자산 손실, 한국 결제 PCI-DSS·webhook 제약 등 위험도를 확률·영향도로 |
| 7 | 권고안 도출 | **3안(Stay / Partial migration / Full migration)** 제시, 각 안의 선택 조건 명시 |

### Out of Scope

| # | Item | Reason |
|---|------|--------|
| 1 | 실제 마이그레이션 구현·코드 작성 | 이 Brief는 연구 방향 정의. 구현은 research→plan→implementation 이후 단계 |
| 2 | Cloudflare 벤더 락인 회피 전략 | 사용자가 "CF 종속은 현재 고민 아님" 명시 |
| 3 | 대체 프로바이더 비교 (Fly.io, Railway, Render, Vercel, AWS 등) | 사용자가 비교 대상을 Rails 유지 vs CF 전환으로 한정 |
| 4 | 모바일(Flutter) 아키텍처 변경 | 서버 스택 선택과 무관한 범위 (API 계약만 공통 관심사) |
| 5 | PostgreSQL로의 이전 검토 | 이 Brief는 현 SQLite vs D1 비교에 집중. PG 이전은 별도 주제 |
| 6 | 구체적 결제 제품(PG사) 선정 | 연구는 **연동 가능성**까지. 최종 PG사 선정은 구현 단계 |

## Decisions

| # | Decision | Chosen | Rationale | Trade-off | Alternatives Considered |
|---|----------|--------|-----------|-----------|------------------------|
| 1 | Brief의 성격 | **Research-oriented Brief** (연구 방향 정의) | 사용자가 "연구주제로서 브리프"라고 명시. "검토해줘"는 결정이 아닌 근거 요구. 이 Brief가 이진 결정을 내리면 근거 없는 단정이 됨 | 이 Brief로 전환 결정 자체를 내리지 못함. 결정은 research 완료 이후로 이월 | **의사결정 Brief (기각)** — 근거 수집 전 결정 불가; 혼합 Brief (기각) — 역할 경계 흐림 |
| 2 | 비교 분석 축 | **5축**: 요구사항 커버리지 / 마이그레이션 비용 / 장기 운영비 / 리스크 / 확장성 | "전환 vs 유지"는 단기 비용 vs 장기 가치의 교환. 5축은 이 교환을 다각도로 가시화. 업계 마이그레이션 담론에서 반복되는 결정 프레임 | DX(개발자 경험)를 별도 축으로 분리하지 않음 — "장기 운영비"에 흡수 | **2축 (비용/성능)** 기각 — 리스크·마이그비용 누락; **10축 세분화** 기각 — Brief는 방향만, research가 세분화 |
| 3 | 현 스택 기준선 | **Rails 8 + SQLite(prod 포함) + Solid + Hotwire** (실측 기준) | `config/database.yml`은 production도 SQLite. CLAUDE.md의 "PostgreSQL"은 부정확. 기준선이 문서 오류 위에 쌓이면 비교 자체가 왜곡 | CLAUDE.md 업데이트 필요 (Brief 범위 밖) | **CLAUDE.md 그대로** 기각 — 부정확 전제; **PostgreSQL 가상 기준선** 기각 — 실제 마이그 비용 반영 못함 |
| 4 | 타깃 스택 범위 | **Workers + D1 + Hono + R2 + KV + Queues + Durable Objects** (주변 서비스 포함) | Rails 8은 Solid 스택으로 잡/캐시/웹소켓/스토리지를 통합. 3개만 1:1 매핑 시 주변 컴포넌트 대체 비용이 과소평가됨 | 연구 범위가 CF 생태계 전반으로 확장 | **3개만(Workers/D1/Hono)** 기각 — Rails 대체 불완전; **Workers+D1만** 기각 — Hono의 DX 기여 누락 |
| 5 | 결제 연동 조사 범위 | **한국(토스/아임포트) 우선 + 글로벌(Stripe) 병행** | 사용자가 결제 대상 지역을 명시하지 않음. 성격/타로 서비스는 한국 MZ 문화 특화 가능성 높고(서비스 기획 docs 존재), 동시에 글로벌 확장 여지도 있음. 두 시나리오 모두 포함이 안전 | 연구 범위 확장. 전환 결정 시 "대상 시장" 결정도 병행 필요 | **토스 only** 기각 — 글로벌 경로 닫음; **Stripe only** 기각 — 한국 UX·규제 미해결 |
| 6 | 권고안 구조 | **3안 (Stay / Partial / Full migration)** | "전환할지"는 이진 선택처럼 보이나 실무 판단은 **Strangler Pattern**(부분 전환) 경로가 흔함. 현재 모바일이 서버 API를 사용하지 않는 상태 → 신규 API 레이어만 CF로 분리하는 경로(Partial)가 유의미한 제3안 | 결론 복잡도 증가. 각 안의 선택 조건을 명시해야 유용 | **Go/No-go** 기각 — 점진 전환 경로 누락; **N안 스펙트럼** 기각 — 과도한 복잡성 |
| 7 | 트래픽 시나리오 단계 | **저/중/고 3단계**: 수천 / 수만 / 수십만 MAU | 장기 운영비는 트래픽에 비선형 반응(특히 CF 무료 티어→Workers Paid $5 전환점, D1 10GB 전환점). 단일 시나리오는 비용 비교를 왜곡 | 연구 부담 증가 — 3개 시나리오별 비용 모델링 필요 | **단일 시나리오** 기각 — 전환점 누락; **5단계 이상** 기각 — 과도 |
| 8 | Brief 품질 프로필 | **Standard + Priority: Longevity/Sustainability** | 사용자 요청에 "장기적 관점"이 명시. 키워드 "제대로/꼼꼼" 없어 Polish/Showcase는 과잉. Priority Dimension으로 지속가능성 축 criteria 1단계 상향 | Standard 기본 밀도(1-2/항목)보다 criteria 수 증가 | **MVP** 기각 — 장기 관점 경시; **Polish** 기각 — 과잉; **Priority 없음** 기각 — 사용자 명시 위반 |

## Open Questions

없음 — 모든 연구 방향 축은 자율 결정됨. Research 수행 중 발견되는 새 질문은 `/research` 스킬이 다룬다.

## Constraints

- **Cloudflare 벤더 락인 수용** — 사용자 명시. 락인 회피 전략은 범위 밖
- **대체 프로바이더 비교 금지** — Fly.io, Railway, Render, Vercel, AWS 등은 연구 대상 아님
- **연구 Brief 성격 유지** — 구현/전환 실행 제안 금지. 권고안까지
- **장기 = 2026-04 ~ 2029-04 (1~3년)** — 이 기간 내 운영 시나리오로 비용·리스크 평가
- **트래픽 시나리오** — 저(수천 MAU) / 중(수만 MAU) / 고(수십만 MAU) 3단계
- **결제 대상 시장** — 한국 우선 + 글로벌 병행 (autonomous 결정)
- **연구 언어** — 한국어 (`docs/` 일반 규칙)

## Exit Criteria

- [x] Intent 확정 — 연구 목적·경계 명확
- [x] Context 실측 기반 정리 — Rails 8 + SQLite + Hotwire 기준선 확인
- [x] In Scope 7개 연구 deliverable 나열됨
- [x] Out of Scope 6개로 scope creep 차단됨
- [x] 비교 축 5개 정의됨
- [x] Decisions 8개에 대안·트레이드오프 명시됨
- [x] Quality Profile + Priority Dimensions 설정됨
- [x] Ideal Criteria 12개 작성됨 (아래)
- [x] Model Anchors 11개 정의됨 (아래)

## Ideal Criteria

**Quality Profile**: Standard · **Priority Dimensions**: Longevity, Sustainability
(Priority 축은 Completeness/Robustness 차원 criteria를 1단계 상향)

| # | Criterion | References (In Scope #) | Type | Dimension |
|---|-----------|------------------------|------|-----------|
| 1 | 현 Rails 스택의 SQLite production 구체적 한도(동시 쓰기, DB 크기, 커넥션)가 2026년 기준 수치로 기재됐는가 | 1 | assertion | Function |
| 2 | 현 스택의 "버리기 어려운 자산"(Hotwire admin dashboard, Solid* 통합 인프라, Kamal 배포 경험)이 구체적으로 열거됐는가 | 1 | assertion | Completeness |
| 3 | CF Workers 런타임 제약(CPU 시간, 메모리, 모듈 API 한계, Node.js 호환성)이 2026년 기준 수치로 정리됐는가 | 2 | assertion | Function |
| 4 | D1 현 스펙(Storage 한도, 읽기 복제 지연, 트랜잭션 제약)이 현재 SQLite 용례에 **매핑 가능/불가 항목별**로 정리됐는가 | 2 | assertion | Function |
| 5 | 요구사항 3개(공개·접속·결제) 각각에 대해 Rails/CF 구현 경로가 나란히 대조표로 기재됐는가 | 3 | assertion | UX |
| 6 | 한국 결제(토스/아임포트) 연동 시 CF Workers의 webhook 처리·PCI-DSS·콜드스타트 이슈가 확인됐는가 | 3 | assertion | Edge |
| 7 | 현 도메인 모델(11개) + 컨트롤러(9개+admin) 재작성 예상 공수가 **MAN-WEEK** 단위로 추정됐는가 | 4 | assertion | Function |
| 8 | Hotwire admin dashboard의 Workers 대체 경로(SSR? 별도 프론트엔드?)가 구체적으로 제시됐는가 | 4 | assertion | Completeness |
| 9 | 1년·3년 운영비 시뮬레이션이 저/중/고 트래픽 3단계로 각각 금액 산출되어 비교됐는가 | 5 | assertion | Function |
| 10 | CF 종속 심화·D1 성숙도·Hotwire 손실·한국 결제 규제 각 리스크가 **발생 확률 × 영향도** 평가로 기록됐는가 | 6 | assertion | Robustness |
| 11 | 권고안 3개(Stay/Partial/Full)의 **선택 조건**(어떤 상황에서 어느 안인가)이 구체적 판단 기준으로 명시됐는가 | 7 | assertion | UX |
| 12 | 장기 관점의 "장기"가 기간(2026~2029) + 규모(MAU 3단계) + 유지보수 공수로 구체 정의됐는가 | 1-7 | assertion | Completeness |

## Model Anchors

1. **이 Brief는 연구 방향 Brief이다**. 후속 `/scope`·`/research`는 이 Brief의 5축 비교 프레임과 7개 deliverable을 따른다. 이 Brief는 전환 결정을 내리지 않는다 — 결정은 연구 완료 후.

2. **현 스택 기준선 = Rails 8.1.2 + SQLite (dev/test/production 전부) + Solid Queue/Cache/Cable + Hotwire(Turbo+Stimulus+importmap) + Tailwind + Kamal/Thruster**. CLAUDE.md의 "PostgreSQL" 기술은 **부정확** — `server/config/database.yml` 기준으로 판단. 연구 중 CLAUDE.md 수정 필요는 별도 안건.

3. **타깃 스택 범위 = Cloudflare Workers + D1 + Hono + R2 + KV + Queues + Durable Objects**. 사용자가 언급한 3개만으로는 Rails 주변 컴포넌트(잡/캐시/스토리지/웹소켓) 대체 불완전. 연구는 주변 서비스 포함 범위로.

4. **비교 프레임 = 5축**: 요구사항 커버리지 / 마이그레이션 비용 / 장기 운영비 / 리스크 / 확장성. **다른 축 추가 금지**. DX는 "장기 운영비"에 흡수.

5. **결제 분석은 한국 시장 우선, 글로벌 병행**. Stripe 단독 결론 금지. 토스페이먼츠/아임포트 한국 PG와 CF Workers 조합의 webhook·PCI-DSS·지연 이슈를 포함.

6. **권고안은 3안 체계 (Stay / Partial migration / Full migration)**. Binary go/no-go 결론 금지. 각 안의 **선택 조건**을 명시.

7. **Partial migration의 정의**: 현 모바일이 서버 API를 사용하지 않는 상태를 활용, 신규 모바일 API 레이어만 CF Workers로 분리하고 Rails 웹은 유지하는 경로. API gateway 패턴.

8. **벤더 락인 회피 전략은 연구 범위 밖**. 사용자가 CF 종속 수용 명시. "만약 CF를 떠나야 한다면"에 대한 exit plan 작성 금지.

9. **비교 대안 프로바이더 배제**: Fly.io, Railway, Render, Vercel, Heroku, AWS, GCP, Azure — 모두 비교 대상 아님. CF vs Rails-유지 만.

10. **마이그레이션 비용 = MAN-WEEK 단위**. "크다/작다/상당한"의 추상 표현 금지. 도메인 모델(11개), 컨트롤러(9개+admin), Hotwire UI, 테스트 재작성, CI/CD 재구성 각 항목별 공수 추정.

11. **Hotwire SPA 자산 손실은 중대 리스크로 기록**. CF Workers는 SSR 가능하지만 Turbo-rails는 Ruby/Rails 결합 패턴이므로 직접 이식 불가. admin dashboard의 UX를 Workers에서 재현하려면 별도 프론트엔드(React/Svelte) 구축 또는 SSR 프레임워크(Remix/Astro) 도입 필요 — 이 비용을 마이그비용 추정에 포함.

## Next Research Cycle (for /research reference)

연구 사이클은 아래 순서로 진행이 권장된다 (이 Brief는 방향만 — 실제 사이클 설계는 `/research` 책임):

1. **현 스택 역량 실측** (In Scope 1): SQLite production 벤치마크·한도 조사, Solid 스택 가치 정량화
2. **타깃 스택 역량 조사** (In Scope 2): 2026년 기준 CF Workers/D1/Hono 최신 스펙·한도·사례
3. **요구사항 매핑** (In Scope 3): 공개·접속·결제 각 구현 경로 대조표
4. **마이그비용 추정** (In Scope 4): 도메인/컨트롤러/admin/테스트/CI 공수 MAN-WEEK
5. **운영비 모델링** (In Scope 5): 저·중·고 시나리오 × 1년·3년
6. **리스크 분석** (In Scope 6): 확률·영향도 매트릭스
7. **종합 (In Scope 7)**: 3안 권고 + 선택 조건

## References

| Resource | Path | Relevance |
|----------|------|-----------|
| 현 서버 Gemfile | `server/Gemfile` | 스택 구성 기준 |
| 현 DB 설정 | `server/config/database.yml` | SQLite 확정 근거 |
| 현 라우트 | `server/config/routes.rb` | HTML/SSR 중심 확인 |
| 도메인 모델 | `server/app/models/` | 재작성 규모 산정 입력 |
| 컨트롤러 | `server/app/controllers/` | 재작성 규모 산정 입력 |
| 모바일 현황 | `mobile/lib/` | API 계약 부재 확인 |
| 공유 API 스키마 | `shared/api-schema/` | placeholder 확인 |
| 프로젝트 CLAUDE.md | `CLAUDE.md` | 문서-실제 불일치(SQLite vs PG) 발견 지점 |
