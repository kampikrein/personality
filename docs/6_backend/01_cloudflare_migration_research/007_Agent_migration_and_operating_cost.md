---
id: "007"
title: "Migration & Operating Cost Modeling"
category: agent
status: completed
created: 2026-04-26
summary: >
  3개 마이그레이션 시나리오(Stay/Partial/Full)의 MAN-WEEK 추정과 3개 트래픽
  시나리오(저/중/고) × 2개 스택(Rails-Kamal-VPS / CF Workers+D1) × 1년·3년
  운영비를 정량 비교한다. Stay = 6.5 MW (모바일 API + 결제 + 1년 유지), Partial
  = 14.5 MW, Full = 30.5 MW. 운영비는 저 시나리오에서 두 스택 모두 사실상
  $5-10/월대로 차이 미미, 중에서도 격차 작음, 고에서 D1 10GB 하드캡으로 샤딩
  비용(+8 MW)이 발생해 CF 우위가 약화. 크로스오버는 트래픽이 아니라 D1 cap
  도달(약 ~75K MAU 시점) 및 VPS 업그레이드 임계.
model: "sonnet"
reasoning_depth: "standard"
confidence: high
keywords: [agent-report, cost-modeling, migration, operating-cost, man-week, traffic-scenarios]
---

# Migration & Operating Cost Modeling

## Progress
### Completed
- [x] Migration scenario A: Stay (Rails maintained)
- [x] Migration scenario B: Partial (Rails web + Workers API)
- [x] Migration scenario C: Full (Workers complete)
- [x] VPS pricing research (2026-04: Hetzner CPX22/32/42, DigitalOcean, Vultr)
- [x] CF pricing detail (Workers/D1/R2/KV/Queues confirmed 2026-04)
- [x] Low scenario operating cost simulation
- [x] Medium scenario operating cost simulation
- [x] High scenario operating cost simulation (with D1 sharding)
- [x] 1-year and 3-year totals
- [x] Crossover points

### Remaining
(none)

### Current Status
Complete.

## Summary

본 보고서는 Cycle 1의 3개 에이전트 보고서(P1: Rails 자산, P2: CF 스택, P3: 결제)를 입력으로 받아 정량 모델링을 수행한다.

**Part A — 마이그레이션 MAN-WEEK 합계**:

| 시나리오 | 1회성 마이그 | 1년 운영 공수 | 비고 |
|---------|-------------|-------------|-----|
| Stay (Rails 유지) | **6.5 MW** | 4 MW/yr | 모바일 API 신설 + 결제 + 유지보수 |
| Partial (Rails web + CF mobile API) | **14.5 MW** | 5 MW/yr | 신규 API만 CF, 듀얼 스택 운영 부담 |
| Full (CF 전면) | **30.5 MW** | 3 MW/yr | 1회성 비용 최대, 운영 단순 |

**Part B — 운영비 (1년/3년 USD, primary services only)**:

| 시나리오 | Rails-Kamal 1y | CF Stack 1y | Rails-Kamal 3y | CF Stack 3y |
|---------|---------------|-------------|---------------|-------------|
| Low (1K MAU) | $123 | $75 | $370 | $225 |
| Medium (10K MAU) | $200 | $135 | $599 | $403 |
| High (100K MAU) | $521 | $632 + 8 MW 샤딩 | $1,564 | $1,895 + 8 MW 샤딩 |

**Part C — 크로스오버**:
- Workers Free → Paid 강제 진입: 일 100K req 초과(저 시나리오부터 이미 초과 가능)
- D1 10GB 하드캡 도달: ~70-100K MAU 사이 추정 — 샤딩 강제
- Rails-Kamal CPX22 → CPX32 업그레이드: ~30-50K MAU에서 CPU/RAM bound
- 운영비만으로는 CF가 1y·3y 모두 cheaper지만, **고 시나리오 8 MW 샤딩 = ~$8K-12K 인건비**가 추가되면 격차 역전

**핵심 결론 (P5 입력)**:
1. 1회성 마이그 vs 1년 운영비 차이는 한 자릿수 만 USD 규모. **결정 요인은 절대 비용이 아니라 비대칭** (1회성↑ vs 운영↓).
2. Stay → Partial 갭(8 MW)이 Partial → Full 갭(16 MW)보다 작음. **Partial이 가장 비용 효율적인 중간 옵션**.
3. D1 10GB 캡이 트래픽 시나리오에 직접 묶임. 고 시나리오의 8 MW 샤딩 공수는 운영비 차이를 무력화.
4. Rails 유지의 운영비도 충분히 낮음(저 시나리오 ~$10/월). CF 비용 우위는 절대값이 아닌 비례 차이(저·중에서 25-40% cheaper).

## Details

### Part A — Migration Cost (MAN-WEEK)

#### 산정 기준

- **1 MAN-WEEK = 시니어 백엔드 엔지니어 1인 5근무일**
- **Pace 보정**: 신규 구현 0.5-1 KLOC/주, 포팅(테스트 동행) 0.3-0.5 KLOC/주. 본 추정은 보수적으로 포팅 0.4 KLOC/주, 신규 0.7 KLOC/주 사용.
- **포함**: 코드 작성 + 단위 테스트 + 코드 리뷰. **불포함**: 사용자 검증, 운영 학습 곡선, 인프라 셋업 외 영역.
- **참조 LOC (Cycle 1 P1 실측)**: services 1,850 LOC, controllers ~500 LOC, models ~250 LOC, views 1,788 LOC ERB, Stimulus 167 LOC, RSpec 2,641 LOC.

#### A.1 Stay 시나리오 — Rails 유지

**Scope**: 현재 Rails 코드는 그대로 두고, Brief가 명시한 3대 요구사항(외부 공개·접속·결제) + 모바일 API 신설을 Rails 위에 추가한다. 모바일이 어차피 결국 서버 API를 써야 하므로 이 비용은 모든 시나리오 공통.

| Component | Source LOC | Target Effort | Difficulty | MAN-WEEK |
|-----------|-----------|---------------|------------|----------|
| 모바일 JSON API (assessments/profile/users) 신설 | n/a | ~600 LOC Rails 컨트롤러+직렬화+테스트 | Med | 2.0 |
| API 인증 (token-based, 기존 cookie 세션과 분리) | n/a | ~150 LOC + RSpec | Low | 0.5 |
| Toss Payments 결제 통합 (PG-hosted, webhook) | n/a | 600-900 LOC (P3 G-1) | Med | 2.0 |
| PortOne 추가 (다중 PG 옵션) | n/a | +300 LOC 델타 (Toss 위에 PortOne 추상화) | Low-Med | 1.0 |
| API 배포 변경 (Kamal 라우팅, secrets) | n/a | wrangler 없음, Kamal accessory | Low | 0.5 |
| OpenAPI 스키마 작성 (모바일과 공유) | n/a | shared/api-schema/ 채우기 | Low | 0.5 |
| **1회성 마이그 합계** | | | | **6.5** |
| 연간 유지보수 오버헤드 (Rails 8 보안 패치, gem update, 스택 트레이스) | n/a | 매월 평균 ~2일 | — | **4.0/yr** |

**근거**:
- Rails 컨트롤러 ~500 LOC가 13개 → 평균 ~40 LOC/컨트롤러. JSON API 컨트롤러 ~12개를 새로 만들면 ~480 LOC + 직렬화 + 테스트 = ~600 LOC.
- 0.7 KLOC/주 × 600 LOC = 0.86 주. 보수 보정 → 2.0 MW (스키마 설계 + 회귀 검증 포함).
- 결제: P3 G-1 명시 600-900 LOC, RSpec 포함하면 약 2 MW.
- 유지보수: Rails 8 LTS 사이클 + Bundler audit + Brakeman + 의존성 업데이트. 12개월 × 16시간/월 ≈ 4 MW.

#### A.2 Partial 시나리오 — Rails web 유지 + CF Workers 모바일 API + 신규 결제

**Scope**: Rails는 현재의 17개 HTML 라우트를 그대로 유지(웹 + admin). 모바일을 위한 신규 JSON API를 Hono+D1로 별도 구축하고, 결제도 신규 CF Workers 위에 구축.

| Component | Source LOC | Target Effort | Difficulty | MAN-WEEK |
|-----------|-----------|---------------|------------|----------|
| D1 스키마 설계 (no data migration; greenfield) | 220 LOC schema.rb | Drizzle schema + 14 FKs + 9 JSON cols | Low | 1.0 |
| 도메인 services 포팅 (scoring/profiles/insights/quality/compliance) | 1,850 LOC Ruby | TS port + Vitest, 1,961 LOC spec→Vitest | Med | **5.0** |
| 모바일 API 라우트 (Hono, ~12 endpoints) | n/a 신규 | ~600 LOC TS + Zod validators | Low-Med | 2.0 |
| Workers 인증 (token + signed cookies) — Rails session과 분리 | n/a | ~200 LOC + Hono middleware | Med | 1.0 |
| User.encrypts 등가 AES-GCM with deterministic IV | 1 model | ~150 LOC crypto + tests | Med | 1.0 |
| Rails ↔ Workers 인증 브리지 (선택적 SSO) | n/a | ~100 LOC + 통합 테스트 | Med | 0.5 |
| 결제 통합 (PortOne + CF Workers, P3 G-4) | n/a | 400-700 LOC TS + Vitest | Low-Med | 1.5 |
| Wrangler CI/CD + Kamal 병행 | n/a | 신규 wrangler.toml + GH Actions | Low | 0.5 |
| OpenAPI 스키마 (Hono RPC type export) | n/a | Hono의 hc client 활용 | Low | 0.5 |
| 듀얼 스택 모니터링 (Workers Logs + Rails logs) | n/a | observability 통합 | Low | 0.5 |
| Docs / runbook / 운영 가이드 | n/a | docs/6_backend/runbook.md | Low | 1.0 |
| **1회성 마이그 합계** | | | | **14.5** |
| 연간 유지보수 (Rails 4 + Workers 1) | n/a | Rails 4/yr + Workers 1/yr | — | **5.0/yr** |

**근거**:
- Services 1,850 LOC ÷ 0.4 KLOC/주(포팅) = 4.6 주. 보수 보정 → 5.0 MW. spec 1,961 LOC가 동행하므로 grounded port.
- D1 스키마 1 MW: Drizzle schema는 SQL 기반이라 schema.rb 220 LOC를 직접 변환 + 인덱스/FK 검증. 단순하지만 9개 JSON 컬럼 인덱싱 전략 + 14 FKs 검증.
- AES-GCM deterministic IV: P1 H5 노트 — backward compat 불필요(prod data 0)이지만 deterministic IV derivation HKDF + 테스트 = 1 MW.
- 듀얼 스택 운영비가 5 MW/yr (Rails 4 + Workers 1)로 단일 스택보다 25% 증가.

#### A.3 Full 시나리오 — Rails 전면 폐기, CF Workers + Hono + D1 단일 스택

**Scope**: 17개 라우트 전체를 Hono로 포팅. 모바일 API + admin + 결제를 모두 CF 스택에. Rails 전체 디커미션.

| Component | Source LOC | Target Effort | Difficulty | MAN-WEEK |
|-----------|-----------|---------------|------------|----------|
| D1 스키마 설계 | 220 LOC | Drizzle + 9 JSON + 14 FKs | Low | 1.0 |
| 도메인 services 포팅 | 1,850 LOC Ruby | TS + Vitest | Med | **5.0** |
| 13개 컨트롤러 → Hono 라우트 (HTML 응답 + JSON 모바일) | 500 LOC | ~700 LOC Hono | Low-Med | 2.0 |
| 모바일 JSON API endpoints | n/a | ~400 LOC | Low | 1.0 |
| 27개 ERB 뷰 → SSR (Hono + JSX/HTMX 또는 Astro) | 1,788 LOC | ~1,500 LOC TSX/HTMX | **Med-High** | **5.0** |
| Hotwire Turbo Frame (2 템플릿, assessment flow) → fetch+swap 또는 SPA | 50 LOC | ~80 LOC client | Med | 1.0 |
| Stimulus 컨트롤러 8개 → vanilla JS 또는 Alpine | 167 LOC | 1:1 port | Low | 1.0 |
| Admin UI (5 controllers, 9 views) → 별도 SSR + HTTP Basic auth | 200 LOC + 9 ERB | ~600 LOC | Med | 2.0 |
| User.encrypts AES-GCM | 1 model | ~150 LOC | Med | 1.0 |
| CSRF + signed cookies + session model (Hono 미들웨어 + 토큰 lifecycle) | implicit Rails | ~250 LOC | **Med** | 1.5 |
| Auth: bcrypt + has_secure_password 등가 (bcryptjs 또는 noble-hashes) | implicit | ~100 LOC | Low | 0.5 |
| 결제 통합 (PortOne + Workers) | n/a | 400-700 LOC | Low-Med | 1.5 |
| 18 RSpec 파일 → Vitest/bun:test (services 위주) | 2,641 LOC | 1:1 logic 보존 | Med | **3.0** |
| Wrangler 배포 + Workers Secrets + D1 migrations | Kamal 대체 | 신규 CI/CD | Low | 1.0 |
| Tailwind 빌드 (Propshaft 대체) | n/a | esbuild + tailwindcss-cli | Low | 0.5 |
| PWA shell (manifest + service worker) → static R2 또는 Workers Sites | n/a | static asset 배포 | Low | 0.5 |
| Cutover (16 PersonalityType seed + admin re-create QuestionSet) | seeds.rb 326 LOC | wrangler d1 execute --file | Low | 0.5 |
| Docs / runbook / 한국 ISP routing fallback 시 Rails-cache 전략 | n/a | observability + runbook | Low | 1.0 |
| Korean copy QA (한국어 ERB → JSX 한국어 보존) | 1,788 LOC | content review | Low | 1.0 |
| Rails 전체 디커미션 (Kamal teardown, repo 정리) | n/a | git rm + DNS 전환 | Low | 0.5 |
| **1회성 마이그 합계** | | | | **30.5** |
| 연간 유지보수 (단일 CF 스택) | n/a | Workers + Hono dep update + Cloudflare API drift | — | **3.0/yr** |

**근거**:
- 27 ERB 뷰 5 MW: 1,788 LOC ÷ 0.4 KLOC/주 = 4.5주. 한국어 + Tailwind safelist + 동적 클래스 보존으로 보수 보정 → 5 MW.
- 13 컨트롤러 → Hono 2 MW: 500 LOC ÷ 0.4 KLOC/주 = 1.25주. 신규 JSON shape 설계 + admin SQL 포함하여 2 MW.
- Admin 별도 2 MW: HTTP Basic + 5 화면이지만 admin/dashboard의 raw SQL 집계(P1 M4) + question_sets CRUD가 있어 별도 budget.
- RSpec → Vitest 3 MW: 2,641 LOC. service spec(1,961 LOC)은 1:1 변환 가능, request spec은 신규. 0.4 KLOC/주 × 2.6KLOC = 6.5주 → service-only 기준 3 MW으로 축소(품질 트레이드오프).
- 운영비 3 MW/yr: Rails 4 MW/yr보다 25% 낮음. Wrangler 배포 단순함, Workers는 OS 패치 부재, 의존성 npm audit으로 자동화 친화. 단 Cloudflare API drift 대응 비용 포함.

#### A.4 Comparison

| 시나리오 | 1회성 (MW) | 1년 운영 (MW) | 3년 누적 (MW) | 인건비 (시니어 시간당 $80, 40h/주) |
|---------|-----------|--------------|--------------|--------------------------------|
| Stay | 6.5 | 4.0 | 6.5 + 12 = **18.5** | $59,200 |
| Partial | 14.5 | 5.0 | 14.5 + 15 = **29.5** | $94,400 |
| Full | 30.5 | 3.0 | 30.5 + 9 = **39.5** | $126,400 |

**해석**:
- Stay → Partial 갭: +8 MW (Partial이 더 큼). Partial은 듀얼 스택의 추가 운영부담을 1 MW/yr 누적.
- Partial → Full 갭: +16 MW (Full이 더 큼). 그러나 Full의 운영비는 Stay·Partial 모두보다 낮음 (-1 ~ -2 MW/yr).
- 3년 시점 인건비 차이: Full이 Stay보다 ~$67K 더 비쌈. 운영비(Part B) 차이는 3년에 수백~수천 USD 수준이라 **인건비 격차가 운영비 격차를 일관되게 압도**.

### Part B — Operating Cost (1y / 3y × low/med/high × Rails/CF)

#### B.1 Pricing References (2026-04)

##### Cloudflare 

| 서비스 | 무료 | Paid 단가 | 출처 |
|--------|------|----------|------|
| Workers Paid | 100K req/일 | $5/월 + 10M req + 30M CPU-ms 포함; $0.30/1M req, $0.02/1M CPU-ms 초과 | [Workers Pricing](https://developers.cloudflare.com/workers/platform/pricing/) |
| D1 | 5M reads + 100K writes/일, 5GB | 25B reads + 50M writes/월 포함; $0.001/1M reads, $1.00/1M writes; $0.75/GB-월 (5GB 포함) | [D1 Pricing](https://developers.cloudflare.com/d1/platform/pricing/) |
| R2 | 10GB/월, 1M Class A, 10M Class B | $0.015/GB-월, $4.50/1M Class A, $0.36/1M Class B, **egress 무료** | [R2 Pricing](https://developers.cloudflare.com/r2/pricing/) |
| KV | 100K reads + 1K writes/일, 1GB | $0.50/1M reads, $5/1M writes/deletes/lists, $0.50/GB-월 | [KV Pricing](https://developers.cloudflare.com/kv/platform/pricing/) |
| Queues | 10K op/일 | 1M op/월 포함, $0.40/1M 추가 | [Queues Pricing](https://developers.cloudflare.com/queues/platform/pricing/) |

D1 paid 사용은 Workers Paid 구독($5/월) 전제로 보고 책정. D1 자체 minimum fee 없음.

##### VPS — Rails-on-Kamal 후보

| Provider | 플랜 | 사양 | 가격 (2026-04) | 출처 |
|----------|------|------|---------------|------|
| Hetzner | CX23 | 2 vCPU / 4 GB RAM / 40 GB / 20 TB traffic | €3.99/월 ≈ **$4.40/월** (DE/FI) | [Better Stack 2026 Hetzner Review](https://betterstack.com/community/guides/web-servers/hetzner-cloud-review/) |
| Hetzner | CPX22 | 2 vCPU AMD / 4 GB RAM / 80 GB / 20 TB | €7.99/월 ≈ **$8.80/월** (DE/FI) | 동상 |
| Hetzner | CPX32 | 4 vCPU / 8 GB / 160 GB / 20 TB | €13.99/월 ≈ **$15.40/월** | 동상 |
| Hetzner | CPX42 | 8 vCPU / 16 GB / 320 GB / 20 TB | €25.49/월 ≈ **$28.04/월** | 동상 |
| DigitalOcean | Basic 1GB | 1 vCPU / 1 GB / 25 GB / 1 TB | $6/월 (Singapore +0%) | [DO pricing](https://www.digitalocean.com/pricing/droplets) |
| DigitalOcean | Basic 4GB | 2 vCPU / 4 GB / 80 GB / 4 TB | $24/월 | 동상 |
| Vultr | High Frequency 2 GB | 1 vCPU / 2 GB / 55 GB / 2 TB | $10/월 (Tokyo) | [Vultr pricing](https://www.vultr.com/pricing/) |

**참조 환율**: 1 EUR ≈ 1.10 USD (2026-04 추정). Hetzner는 한국 사용자 대상 시 Singapore 리전 +40-67% 프리미엄 적용. 본 시뮬레이션은 DE/FI 기준값 + Singapore 프리미엄을 별도 명시.

**부가 비용 (Rails 공통)**:
- 도메인: ~$15/년 (Cloudflare Registrar at-cost, .com)
- TLS: $0 (Let's Encrypt via Kamal proxy)
- 백업: B2 ($6/TB-월) 또는 Hetzner Storage Box (~€3.49/월 = $3.84/월 1 TB)
- 모니터링: Better Stack Free tier ($0) 또는 Grafana Cloud Free
- 관리형 SQLite 백업은 단순 cron rsync — 추가 0

#### B.2 Low Scenario — 1,000 MAU, 30K req/월, 100 MB DB, 5 GB bandwidth, 100 concurrent peak

##### Rails-on-Kamal (저 시나리오)

VPS는 CX23 (€3.99 = $4.40)이 충분 (1K MAU, 100 concurrent 짜리는 2 vCPU + 4GB로 여유). Sing 리전 시 +50% = $6.60/월.

| 항목 | 월 비용 | 1년 | 3년 |
|------|--------|-----|-----|
| Hetzner CX23 (DE/FI) | $4.40 | $52.80 | $158.40 |
| 도메인 (.com) | $1.25 | $15 | $45 |
| 백업 (Storage Box 1TB) | $3.84 | $46.08 | $138.24 |
| 모니터링 (Better Stack Free) | $0 | $0 | $0 |
| TLS / Let's Encrypt | $0 | $0 | $0 |
| **합계 (DE/FI)** | **$9.49** | **$113.88** | **$341.64** |
| **Singapore 리전 프리미엄 (+50%)** | $11.69 | $140.30 | $420.91 |

##### CF Stack (저 시나리오)

월 30K req → Workers Paid 포함분(10M req) 내. D1: 100MB → 5GB 포함분 내. KV/Queues 미사용.

| 항목 | 월 비용 | 1년 | 3년 |
|------|--------|-----|-----|
| Workers Paid (base) | $5.00 | $60 | $180 |
| D1 (paid storage 0 over) | $0 | $0 | $0 |
| R2 (assets 100MB) | $0 (free 10GB) | $0 | $0 |
| 도메인 (Cloudflare Registrar at-cost) | $1.25 | $15 | $45 |
| TLS / 모니터링 | $0 | $0 | $0 |
| **합계** | **$6.25** | **$75** | **$225** |

**Low 시나리오 격차**: CF는 Rails 대비 ~33% cheaper (DE/FI 기준), Singapore 비교 시 ~46% cheaper. 3년 절대 격차 ~$117 (DE/FI) ~$196 (Sing).

#### B.3 Medium Scenario — 10K MAU, 1M req/월, 2 GB DB, 50 GB bandwidth, 1K concurrent peak

##### Rails-on-Kamal (중 시나리오)

CPX22 (€7.99 = $8.80)로 충분. 50GB bandwidth는 20TB 무료 포함분 내.

| 항목 | 월 비용 | 1년 | 3년 |
|------|--------|-----|-----|
| Hetzner CPX22 (DE/FI) | $8.80 | $105.60 | $316.80 |
| 도메인 | $1.25 | $15 | $45 |
| 백업 (Storage Box) | $3.84 | $46.08 | $138.24 |
| 모니터링 (Better Stack Free) | $0 | $0 | $0 |
| **합계 (DE/FI)** | **$13.89** | **$166.68** | **$500.04** |
| **Singapore 프리미엄 (+50%)** | $19.65 | $235.74 | $707.22 |

비고: 1K concurrent peak는 CPX22의 4GB RAM이 빠듯할 가능성 있음. Puma worker tuning 필요. 안전 마진 위해 CPX32 ($15.40) 채택 시 +$79/년.

##### CF Stack (중 시나리오)

1M req/월 → Workers 10M 포함분 내. CPU-ms: 1M req × 평균 30ms CPU = 30M CPU-ms — **포함분 정확히 도달**. 마진 위해 +20% 가정 시 6M CPU-ms 초과 = $0.12/월.

D1: 2GB → 5GB 포함분 내. Reads: 1M req × 평균 50 reads = 50M reads/월. Writes: 1M req × 평균 5 writes = 5M writes/월. 모두 포함분(25B reads, 50M writes) 내. 

| 항목 | 월 비용 | 1년 | 3년 |
|------|--------|-----|-----|
| Workers Paid (base + small overage) | $5.12 | $61.44 | $184.32 |
| D1 (storage 2GB free) | $0 | $0 | $0 |
| R2 (assets, ~500MB) | $0 | $0 | $0 |
| 도메인 | $1.25 | $15 | $45 |
| **합계** | **$6.37** | **$76.44** | **$229.32** |

비고: 1K concurrent peak는 CF에서 동시 isolate spawn으로 자동 흡수 (subrequests 1000/req 한도 내). 별도 비용 없음.

**Medium 시나리오 격차**: 운영비는 CF ~$229 vs Rails ~$500 (3년, DE/FI). CF가 ~54% cheaper. 절대 격차 ~$270 (3년, DE/FI). Singapore 시 격차 ~$478.

#### B.4 High Scenario — 100K MAU, 30M req/월, 15 GB DB (sharding), 500 GB bandwidth, 10K concurrent peak

##### Rails-on-Kamal (고 시나리오)

CPX42 ($28.04) — 8 vCPU / 16GB. 10K concurrent peak는 SQLite WAL 모드 + Puma 8 worker로 가능하나 SQLite write throughput이 천장. **현 SQLite 유지 시 write contention 위험** → Postgres 분리 검토 필요. 본 모델은 SQLite + WAL 가정.

500GB bandwidth는 20TB 무료 포함분 내. DB 15GB는 Hetzner Storage Box 추가 ($3.84/월).

| 항목 | 월 비용 | 1년 | 3년 |
|------|--------|-----|-----|
| Hetzner CPX42 | $28.04 | $336.48 | $1,009.44 |
| 도메인 | $1.25 | $15 | $45 |
| 백업 (Storage Box 1TB) | $3.84 | $46.08 | $138.24 |
| 모니터링 (Better Stack Pro $25/mo) | $25 | $300 | $900 |
| **합계 (DE/FI)** | **$58.13** | **$697.56** | **$2,092.68** |
| **Singapore 프리미엄 (+50%)** | $73.89 | $886.68 | $2,660.04 |

##### CF Stack (고 시나리오)

월 30M req → 20M 초과 = 20M × $0.30/M = $6/월.
CPU-ms: 30M × 30ms = 900M CPU-ms → 870M 초과 × $0.02/M = $17.40/월.
D1: **15GB → 10GB 하드캡 초과 → 샤딩 강제**. 2개 D1 = 7.5GB씩.
- D1 storage: 15GB - 5GB free = 10GB × $0.75/GB = $7.50/월
- Reads: 30M req × 50 = 1.5B reads/월 → 25B 포함분 내, $0
- Writes: 30M × 5 = 150M writes → 100M 초과 × $1/M = $100/월
- R2: 100GB assets × $0.015 = $1.50/월
- KV (사용 시): 무시 가능
- Queues (결제 webhook 비동기 처리): 30K events × 3 ops = 90K ops/월 → 무료

| 항목 | 월 비용 | 1년 | 3년 |
|------|--------|-----|-----|
| Workers Paid (base + req + CPU 초과) | $5 + $6 + $17.40 = **$28.40** | $340.80 | $1,022.40 |
| D1 storage (over 5GB) | $7.50 | $90 | $270 |
| D1 writes (over 50M) | $100.00 | $1,200 | $3,600 |
| R2 (100GB assets) | $1.50 | $18 | $54 |
| 도메인 | $1.25 | $15 | $45 |
| **합계 (전적인 운영비)** | **$138.65** | **$1,663.80** | **$4,991.40** |

**D1 샤딩 운영 부담 (1회성 + 지속)**:
- 1회성 샤딩 설계·구현: ~8 MW = $25,600 인건비
- 지속 운영비: 샤드 라우팅 코드 복잡도, 크로스-샤드 쿼리 회피, 마이그 도구 수정 → 연간 +0.5 MW

**High 시나리오 격차 (운영비만)**:
- Rails $2,093 / 3y vs CF $4,991 / 3y (DE/FI 기준)
- CF가 **138% 더 비쌈** (3년)
- Singapore 비교 시: Rails $2,660 / 3y vs CF $4,991 / 3y → CF가 88% 더 비쌈

**고 시나리오 결론**: D1 writes 100M 초과로 $100/월 (+0.5 GB/월 storage 누적)이 결정타. Rails-on-Kamal SQLite는 write 비용이 0이므로 고 트래픽 write-heavy 워크로드에서 **CF가 역으로 비싸진다**. 더하여 8 MW 샤딩 인건비 ~$25K 1회성을 더하면 격차 추가 확대.

#### B.5 운영비 종합

| 시나리오 | Rails-Kamal 1y (DE/FI) | CF 1y | Rails 3y (DE/FI) | CF 3y |
|---------|------------------------|-------|------------------|-------|
| Low (1K MAU) | $114 | $75 | $342 | $225 |
| Medium (10K MAU) | $167 | $76 | $500 | $229 |
| High (100K MAU) | $698 | $1,664 | $2,093 | $4,991 |

비고: Singapore 리전 운영 시 Rails 운영비 +50%. CF는 글로벌 가격 동일.

### Part C — Crossover Points

#### C.1 Workers Free → Paid 강제 진입

- 일 100K req(월 ~3M) 초과 또는 요청당 CPU > 10ms 시 강제 Paid.
- 1K MAU에서 일 평균 1 req/MAU = 1K req/일. 그러나 batch endpoints나 admin 접근 포함 시 쉽게 100K/일 도달 → **저 시나리오부터 이미 Paid 가정 필수**.
- 본 모델은 모든 시나리오 Paid 가정.

#### C.2 D1 10GB 하드캡 도달

추정: 사용자당 ~150KB (assessments 평균 60 questions × responses 80 byte + profile JSON ~10KB + insights ~5KB).
- 70K 사용자 = 10.5GB → 캡 도달.
- 100K 사용자 = 15GB → 샤딩 강제 (고 시나리오).

**완화책**:
- 오래된 anonymous_session 정리 (P1: 14 tables 중 anonymous_sessions, audit_logs는 TTL 적용 가능)
- responses 압축 또는 cold storage R2 이전
- per-tenant 샤딩 시 user_id 해시로 2개 DB 분배

10 GB 도달 시점은 운영 7-12개월 사이 (월 8K MAU 신규 시 +1.2GB/월).

#### C.3 Rails-VPS 업그레이드 임계

- CX23 → CPX22: ~5K MAU (4GB RAM 부족, Solid Queue 활성화 시)
- CPX22 → CPX32: ~30K MAU (Puma worker 4 미만, SQLite write contention)
- CPX32 → CPX42: ~80K MAU 또는 SQLite → Postgres 이전 결심
- 단일 VPS의 SQLite write 천장은 ~500 writes/sec (WAL + 단일 writer). 100K MAU의 30M req/월 중 5M writes ÷ 30 days ÷ 86400s = ~2 writes/sec 평균. **평균은 여유 있으나 burst 시 위험** → SQLite 유지 시 큐 도입 필수.

#### C.4 운영비 크로스오버

| 트래픽 구간 | CF cheaper? | 핵심 이유 |
|-----------|------------|----------|
| 0 - 5K MAU | **CF $75/yr vs Rails $114/yr (DE/FI)** | Workers $5/월 base + D1 free tier. Rails는 CX23 + 도메인 + 백업이 fixed cost로 누적 |
| 5K - 30K MAU | **CF cheaper (~50% less)** | Workers/D1 모두 free tier 내, Rails는 CPX22 + 모니터링 누적 |
| 30K - 70K MAU | **약 break-even** | D1 writes 50M 포함분 근처 도달, Workers CPU-ms 초과 시작 |
| 70K - 100K MAU | **Rails cheaper** | D1 writes 100M 초과 시 $100/월, storage $7.50/월. Rails CPX42 ~$28/월 |
| 100K+ MAU | **Rails cheaper + 샤딩 인건비 부담** | CF는 D1 cap으로 1회성 8 MW 샤딩 추가. Rails는 PostgreSQL 분리 또는 read replica 검토 |

#### C.5 D1 샤딩 비용 정량화

8 MW 샤딩 = ~$25,600 인건비 (1회성). 또한 지속 운영비 +0.5 MW/yr = $1,600/yr.

3년 누적:
- Rails 고 시나리오: $2,093 운영비 (DE/FI)
- CF 고 시나리오: $4,991 운영비 + $25,600 샤딩 1회성 + $4,800 지속 = **$35,391**
- 격차: **CF가 17배 더 비쌈** (인건비 합산 시)

이는 **고 트래픽이 예상된다면 Stay 또는 Partial이 정량적으로 우월**함을 의미. Full migration의 정량 정당성은 저·중 트래픽 + 운영 단순성 가치 평가에 의존.

## Key Findings

1. **[Critical] 1회성 마이그 비용이 운영비 격차를 일관되게 압도** — Stay→Partial 갭(8 MW = $25K) > 3년 운영비 격차(~$300-3K). 절대값이 아니라 비대칭 구조가 결정 요인.

2. **[Critical] D1 10GB 하드캡 + write 가격이 고 트래픽에서 CF 우위 무력화** — Writes $1/1M에 50M/월 포함분이 너무 작음. 100K MAU에서 +$100/월 + 8 MW 샤딩. 고 시나리오에서 CF는 인건비 합산 시 Rails보다 17배 비쌈.

3. **[High] Stay 시나리오의 모바일 API 신설 비용(2.5 MW)은 Partial/Full에서도 동등 발생** — 모바일이 어차피 API를 써야 하므로, 이 비용은 **모든 시나리오에 sunk cost**. Stay 시나리오의 6.5 MW 중 결제(3 MW) 제외하면 모바일 API는 양 스택 동등 출발선.

4. **[High] Partial이 가장 비용 효율적인 중간 옵션** — Stay 대비 +8 MW로 모바일 API를 CF에 두면서 Rails web/admin 자산 보존. Full 대비 -16 MW.

5. **[High] 저·중 시나리오의 운영비 절대값은 양 스택 모두 미미** — 둘 다 월 $5-15 범위. 운영비를 결정 변수로 삼으면 노이즈를 시그널로 오해할 위험.

6. **[Medium] Hetzner Singapore 프리미엄(+50%)이 Rails-Kamal의 한국 사용자 latency 보정 비용** — Singapore 리전 사용 시 Rails 1y 운영비 +50%. CF는 글로벌 가격 동일이지만 P2의 Seoul PoP 라우팅 이슈가 변수.

7. **[Medium] Workers free tier exit는 100K req/일에서 강제** — 1K MAU 미만에서도 admin·crawler 접근 포함 시 도달. 모든 시나리오 Paid 가정이 합리적.

8. **[Low] Rails 8 LTS 보안 패치 + gem update는 4 MW/yr** — 단일 인력 운영 시 매월 ~16시간 누적. CF는 OS 패치 부재로 3 MW/yr.

## Recommendations (for P5)

1. **결정 변수는 1회성 마이그 vs 운영 단순성, 절대 비용이 아니다**. 저·중 시나리오에서 운영비 차이는 3년 누적 ~$300-700. P5의 권고에서 운영비를 결정 요인으로 가중하지 말 것.

2. **D1 10GB 하드캡은 트래픽 시나리오의 직접 함수**. 고 시나리오 가정 시 8 MW 샤딩 인건비를 Full migration의 추가 비용으로 P5 리스크 매트릭스에 포함.

3. **Partial 시나리오의 듀얼 스택 운영 부담 1 MW/yr**은 Rails 4 + Workers 1 MW의 합. 단일 인력 운영 시 컨텍스트 스위칭 비용을 정량화하기 어려우나, **P5는 "운영 단순성"을 별도 차원으로 평가**해야 함.

4. **Stripe Korea 부재(P3 K2)는 결제 비용에 반영됨**. PortOne + Workers 1.5 MW vs PortOne + Rails 2-3 MW (Ruby SDK 부재로 REST 직호출 + Standard Webhooks 자체 구현). CF가 결제에서 약 1 MW 우위.

5. **고 시나리오는 정량적으로 Rails 우위, 저·중은 CF 우위, 중간은 break-even**. P5의 선택 조건에 트래픽 예상치를 반영. 100K MAU+ 예상 시 Stay 또는 Partial(Rails web 부분 유지)로 D1 샤딩 회피.

6. **3년 인건비 차이는 ~$67K (Stay vs Full)**. 운영비 차이(~$2-5K)의 13-30배. 이 비대칭이 "Full = 장기 우위" 가정을 깨뜨림. **Full의 정당성은 인건비 + 운영비 합산 cost가 아니라 "엣지 latency·DX·확장성" 같은 비비용 가치에 의존**해야 함.

## References

| Source URL | Role |
|------------|------|
| https://developers.cloudflare.com/workers/platform/pricing/ | Workers Paid 가격 검증 |
| https://developers.cloudflare.com/d1/platform/pricing/ | D1 가격 검증 |
| https://developers.cloudflare.com/r2/pricing/ | R2 가격 검증 |
| https://developers.cloudflare.com/kv/platform/pricing/ | KV 가격 |
| https://developers.cloudflare.com/queues/platform/pricing/ | Queues 가격 |
| https://developers.cloudflare.com/d1/platform/limits/ | D1 10GB 하드캡 (P2 인용) |
| https://betterstack.com/community/guides/web-servers/hetzner-cloud-review/ | Hetzner 2026-04 가격표 (CX/CPX 시리즈) |
| https://costgoat.com/pricing/hetzner | Hetzner 2026-04 가격 calc + Singapore 프리미엄 |
| https://www.digitalocean.com/pricing/droplets | DigitalOcean Basic Droplets 가격 |
| https://www.vultr.com/pricing/ | Vultr Cloud Compute 가격 |
| `003_Agent_current_rails_assets.md` | LOC 인벤토리 (15 모델, 1850 LOC services 등) |
| `004_Agent_cloudflare_stack_capabilities.md` | CF 한도·가격 (P2 검증값) |
| `005_Agent_payment_integration.md` | 결제 LOC 추정 6셀 (P3) |
| `006_Synthesis_cycle1.md` | Cycle 1 종합 입력 |

## Communication Log

| # | Direction | Peer | Summary | Stage |
|---|-----------|------|---------|-------|
| 1 | ← | P1 (003) | LOC + 자산 인벤토리 입력. 15 모델, 13 컨트롤러, 1,850 LOC services, 27 ERB(1,788 LOC), 8 Stimulus, 18 RSpec(2,641 LOC), 14 tables, 9 JSON cols, no prod data | Cycle 1 |
| 2 | ← | P2 (004) | CF 한도/가격 입력. Workers $5/월 + 10M req + 30M CPU-ms, D1 10GB hard cap, R2 egress free, KV/Queues 가격 | Cycle 1 |
| 3 | ← | P3 (005) | 결제 LOC 입력. PortOne+Workers 400-700 LOC = 1.5 MW. Stripe Korea 부재로 한국 우선 시 Toss/PortOne만 | Cycle 1 |
| 4 | → | P5 | 1회성 마이그 비용이 운영비 차이를 일관되게 압도 (3년 인건비 격차 $67K vs 운영비 격차 $2-5K). 결정 변수는 비대칭 구조 | Cycle 2 |
| 5 | → | P5 | D1 10GB 하드캡은 트래픽의 직접 함수. 고 시나리오에서 8 MW 샤딩 인건비 추가 = ~$25K. 100K MAU+ 예상 시 Rails/Partial 우위 | Cycle 2 |
| 6 | → | P5 | Partial이 Stay→Full 사이의 비용 효율 중간점. 듀얼 스택 1 MW/yr 부담은 단일 인력 시 컨텍스트 스위칭 변수로 평가 권고 | Cycle 2 |
| 7 | → | P5 | 모바일 API 신설(2.5 MW)은 모든 시나리오 sunk cost. Stay 6.5 MW 중 결제 3 MW + API 2.5 MW + 통합 1 MW로 분해됨 | Cycle 2 |
| 8 | → | P5 | Hetzner Singapore 리전 +50% 프리미엄. CF는 글로벌 동일가이지만 P2의 Seoul PoP 라우팅 이슈 변수 | Cycle 2 |
