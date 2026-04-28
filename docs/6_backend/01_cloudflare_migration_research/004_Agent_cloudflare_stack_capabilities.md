---
id: "004"
title: "Cloudflare Workers + D1 + Hono Capabilities & Limits (2026-04)"
category: agent
status: completed
created: 2026-04-24
summary: >
  2026-04 기준 Cloudflare Workers + D1 + Hono 스택의 런타임/플랫폼 한계, 성숙도(GA/Beta), Rails 컴포넌트 대응 매핑, 한국 시장 사용 실태를 정리한다. Workers/D1/R2/Queues는 GA이며 Hono v4.12.x가 안정판. D1은 10GB/DB 하드 리밋과 단일 스레드 특성이 핵심 제약이며, 한국 프로덕션 백엔드 도입 사례는 스타트업/개인 프로젝트 수준에 머물러 주류 채택은 확인되지 않음. Node.js 호환은 부분적이며 `nodejs_compat` 플래그 필요.
model: "sonnet"
reasoning_depth: "standard"
confidence: high
keywords: [agent-report, cloudflare, workers, d1, hono, r2, kv, queues, durable-objects]
---

# Cloudflare Workers + D1 + Hono Capabilities & Limits (2026-04)

## Progress
### Completed
- [x] Workers runtime limits (Free/Paid)
- [x] Workers 가격 (Standard)
- [x] Workers Node.js 호환 현황
- [x] Cold start 실측 수치
- [x] D1 한계 및 가격
- [x] D1 트랜잭션 및 고립 수준
- [x] D1 읽기 복제 (public beta 2025-04)
- [x] D1 마이그레이션 및 백업 (Time Travel)
- [x] D1 GA 시점 (2024-04-01)
- [x] Hono v4.12.x 현황
- [x] R2/KV/Queues/DO GA 및 한계
- [x] 한국 시장 사용 근거
- [x] 2025-2026 주요 변경점 및 알려진 함정
### Remaining
(none)
### Current Status
Complete — 다음 사이클(Cycle 2: synthesis)이 참조할 수 있는 상태.

## Summary

- **Workers (GA)**: V8 isolate 모델. Standard 플랜 $5/월 기본에 10M req + 30M CPU-ms 포함. CPU 기본 30초(최대 5분). 128MB 메모리/isolate. Cold start 단일 자릿수 ms(~5ms) — 단, 스크립트 커지면 수십 ms까지 증가. ICN(서울) PoP 존재하지만 일부 ISP는 도쿄/후쿠오카로 라우팅되는 이슈 보고됨.
- **D1 (GA since 2024-04-01)**: SQLite 기반. **10GB/DB 하드 리밋**이 최대 핵심 제약. 단일 스레드(쿼리 1ms → ~1000 qps, 100ms → ~10 qps). snapshot isolation. `batch()` = transaction. **읽기 복제는 public beta(2025-04-10)** — 6개 지역, Sessions API 필수, 추가 비용 없음.
- **Hono v4.12.x (stable)**: Web Standards 기반 경량 프레임워크. RPC + Zod validator로 end-to-end type safety. Cloudflare Workers + D1 + Drizzle 스타터 템플릿 다수 존재.
- **주변 서비스**: R2(GA, egress 무료), KV(GA, 최종 일관성), Queues(GA 2024-09, 5000 msg/s), Durable Objects(GA, SQLite backend storage billing 2026-01 시작).
- **한국 시장**: 주류 채택 없음. velog/medium 포스트는 개인 사이드 프로젝트(부동산 크롤러, 포트폴리오, 웹훅 중계, MCP 서버 배포) 중심. 토스/당근/쿠팡 사용 사례 확인 불가.
- **5대 함정(severity high→low)**: (1) D1 10GB hard cap → 샤딩 필수, (2) 단일 DB 단일 스레드 → 큰 UPDATE/DELETE 배치 필수, (3) Node.js 부분 호환(`child_process`/`cluster`/SQLite 네이티브 미지원), (4) 서울 PoP 라우팅 비일관성, (5) 읽기 복제 여전히 beta + lag unbounded.

## Details

### A. Workers Runtime

#### 한계 (출처: [Workers Limits](https://developers.cloudflare.com/workers/platform/limits/))

| 항목 | Workers Free | Workers Paid (Standard) |
|---|---|---|
| Daily Requests | 100,000/day | 무제한 |
| CPU time (HTTP) | 10 ms | 기본 30s, 최대 5분 (`limits.cpu_ms` 설정) |
| Memory/isolate | 128 MB | 128 MB |
| Subrequests | 50/request | 1,000/request (fetch/KV 등), (Cache API 50/1000) |
| Worker 크기 (압축) | 3 MB | 10 MB |
| Worker 크기 (원본) | 64 MB | 64 MB |
| Number of Workers | 100 | 500 |
| Env vars | 64/Worker | 128/Worker |
| Cron triggers | 5/account | 250/account |
| Duration 한계 | - | HTTP 무제한(클라 연결 유지 중), Cron/DO Alarm/Queue Consumer 15분 |
| URL 크기 | 16 KB | 동일 |
| Request body | Free/Pro 100 MB, Business 200 MB, Enterprise 500 MB | |
| Static assets | 20,000/version | 100,000/version (각 파일 25 MiB) |

#### 가격 (출처: [Workers Pricing](https://developers.cloudflare.com/workers/platform/pricing/))

- **Free**: 100k req/day, 10 ms CPU/req, 200k log events/day(3일 보존)
- **Paid (Standard, 기본값 2024-03-01부터)**: $5/월 account 베이스
  - 포함: 10M requests/month + 30M CPU-ms/month
  - 초과: $0.30/1M requests, $0.02/1M CPU-ms
- Bundled/Unbound 모델은 deprecated(신규 계정 Standard 강제)

#### Node.js 호환 (출처: [Workers Node.js compat](https://developers.cloudflare.com/workers/runtime-apis/nodejs/))

- **플래그**: `nodejs_compat` 필수, `compatibility_date >= 2024-09-23`
- **Full 지원**: Buffer, Crypto, DNS, Events, fs(부분 Web Crypto), HTTP/HTTPS, Net, Path, Process, Stream, String decoder, Timers, URL, Zlib
- **Partial/stub**: Console, Module, OS, Performance hooks, TLS/SSL, Child processes(stub), Cluster(stub), Async hooks(stub), HTTP/2(stub)
- **미지원**: SQLite(native module), Test runner, native Node addon

#### Cold start & V8 isolate 제약
- Cold start 5 ms baseline(단, 스크립트 크기 및 startup CPU 증가 시 수십 ms); Cloudflare는 TLS ClientHello 시점 eager-load로 cold start 제거 작업 진행 중 (출처: [Eliminating cold starts](https://blog.cloudflare.com/eliminating-cold-starts-with-cloudflare-workers/))
- V8 isolate 제약:
  - 파일시스템 없음 (`fs` 동작 제한적, R2/KV로 대체)
  - `child_process` 불가
  - 네이티브 모듈(.node) 불가 → Rails의 `image_processing`, `libvips` 대체 필요
  - Isolate 단위 격리, 메모리 공유 불가
  - 단일 스레드 — Worker 인스턴스가 region PoP에 다수 존재하지만 동일 객체 공유 없음 → 공유 상태는 Durable Object/KV/D1 필요

### B. D1

#### 한계 (출처: [D1 Limits](https://developers.cloudflare.com/d1/platform/limits/))

| 항목 | Free | Paid |
|---|---|---|
| Databases/account | 10 | 50,000 |
| Max DB 크기 | 500 MB | **10 GB (hard cap, 증가 불가)** |
| Storage/account | 5 GB | 1 TB |
| Queries/invocation | 50 | 1,000 |
| SQL statement 길이 | 100 KB | 동일 |
| Query timeout | 30s | 동일 |
| Bound params/query | 100 | 동일 |
| Max string/BLOB/row | 2 MB | 동일 |
| Columns/table | 100 | 동일 |
| SQL function args | 32 | 동일 |
| 동시 연결 | Worker invocation당 6 | 동일 |
| Time Travel | 7 days | 30 days |

#### 가격 (출처: [D1 Pricing](https://developers.cloudflare.com/d1/platform/pricing/))

- **Free**: 5M rows read/day, 100k rows written/day, 5 GB storage
- **Paid**:
  - rows read: 25B/month 포함 + $0.001/1M rows
  - rows written: 50M/month 포함 + $1.00/1M rows
  - storage: 5 GB 포함 + $0.75/GB-month
- 2025-02-10부터 Free tier 초과 시 쿼리 에러 반환 (이전 soft-limit에서 변경)

#### 트랜잭션 의미 (출처: [D1 Database Worker API](https://developers.cloudflare.com/d1/worker-api/d1-database/), [Building D1](https://blog.cloudflare.com/building-d1-a-global-database/))

- **Isolation**: SQLite의 **snapshot isolation** (sequential consistency when using Sessions API)
- **Transaction API**: `db.batch([...stmts])` — 배치 내 statements는 sequential/non-concurrent 실행, 한 개 실패 시 전체 롤백
- **ACID**: auto-commit + batch transaction. 단일 DB 내 일반적 ACID 만족. 명시적 `BEGIN/COMMIT` syntax는 제한적 (batch() 권장).
- **인터랙티브 트랜잭션 없음** — Rails의 `ActiveRecord::Base.transaction do ... end` 패턴이 동적 SQL 구성에 의존하면 재설계 필요.

#### 읽기 복제 (출처: [D1 Read Replication](https://developers.cloudflare.com/d1/best-practices/read-replication/), [Release Notes](https://developers.cloudflare.com/d1/platform/release-notes/))

- **상태**: **Public Beta (2025-04-10 도입)**. 2026-04 시점 GA 미발표.
- **리전**: ENAM, WNAM, WEUR, EEUR, APAC, OC (6개 자동 생성)
- **Lag**: 바운드 없음 — Sessions API 없이 읽으면 stale read 가능
- **Sessions API**: bookmark 기반 consistency 모델 3종 (no constraints / primary-first / bookmark-based)
- **가격**: 추가 compute/storage 비용 없음, rows read/written 과금 그대로
- **enable**: Dashboard > D1 > Settings > Enable Read Replication, 또는 REST API `read_replication.mode: auto`

#### 마이그레이션 도구

- `wrangler d1 migrations create/apply` — 파일 기반 .sql 마이그레이션. Rails Active Record migrations 대비 DSL 부재(순수 SQL).
- `wrangler d1 execute --file=schema.sql` — 단건 실행
- `wrangler d1 export/import` — SQLite dump 포맷 지원
- 마이그레이션 상태는 내부 `d1_migrations` 테이블로 추적

#### 백업 (출처: [D1 Backups](https://developers.cloudflare.com/d1/reference/backups/))

- **Time Travel**: point-in-time recovery, Paid 30일 / Free 7일
- 레거시 alpha DB의 `wrangler d1 backup`은 deprecated (2025-07-01 제거)
- `wrangler d1 export --output=backup.sql` 수동 덤프 가능

#### 성능 특성 (출처: [HN thread](https://news.ycombinator.com/item?id=43572511), [Answeroverflow](https://www.answeroverflow.com/m/1345869029906059305))

- **단일 스레드**: 각 D1 DB가 단일 SQLite primary로 처리 → 쿼리 지속시간으로 throughput 결정
  - 평균 1 ms 쿼리 → ~1,000 qps
  - 평균 100 ms 쿼리 → ~10 qps
  - 초과 시 큐 포화 → "overloaded" 에러
- 대량 UPDATE/DELETE는 반드시 배치 분할 필요 (single query 한계 초과)

### C. Hono

#### 버전 (출처: [hono releases](https://github.com/honojs/hono/releases), [npm hono](https://www.npmjs.com/package/hono))

- **현재 안정판**: v4.12.15 (2026-04-24 기준). v4 시리즈 장기 안정.
- 주요 v4 기능: 개선된 RPC, helper 분리, static asset 핸들러.

#### 타입 안정성 (출처: [Hono RPC docs](https://hono.dev/docs/guides/rpc))

- **AppType 제네릭**으로 server→client 전체 타입 공유
- **Validator 통합**: `zValidator`(Zod), `valibot`, `arktype` 지원 → `c.req.valid('json')`로 typed access
- `parseResponse()` 헬퍼로 typed 응답 추출
- `ApplyGlobalResponse`로 글로벌 에러 응답 타입 병합
- Rails로 치면 strong params + jbuilder/alba를 타입 시스템이 자동화

#### 미들웨어 생태계

- 내장: CORS, Basic/Bearer/JWT 인증, Compress, ETag, Timing, Logger, CSRF, Secure Headers, Rate Limit
- Validator: zod/valibot/arktype/typia
- 배포 타깃: **Cloudflare Workers, Deno, Bun, Node.js, Vercel, AWS Lambda, Lambda@Edge, Fastly, Netlify** — 런타임 lock-in 없음
- Rails DSL 대응:
  - `resources :foo` → `app.route('/foo', fooApp)` 모듈화 + factory 패턴
  - Strong params → `zValidator('json', schema)`
  - callbacks(`before_action`) → `app.use('*', middleware)`

#### 스타터 템플릿

- `pnpm create hono@latest` → Cloudflare Workers 타깃 선택 시 기본 스캐폴드 제공
- 공식 예제: [Better Auth on Cloudflare](https://hono.dev/examples/better-auth-on-cloudflare), [yusukebe/cloudflare-d1-drizzle-honox-starter](https://github.com/yusukebe/cloudflare-d1-drizzle-honox-starter)
- 커뮤니티: `naserdehghan/workers-d1-hono-drizzle-template`, `alwalxed/hono-openapi-template` (Zod + Drizzle + D1 + OpenAPI)

### D. Surrounding Services (Rails Mapping)

| Rails Component | CF Equivalent | GA Status | 주요 한계 | Price Model | Mapping Gap |
|---|---|---|---|---|---|
| ActiveRecord + PostgreSQL | **D1** | GA (2024-04-01) | 10 GB/DB hard cap, 단일 스레드, snapshot isolation only | $0.75/GB-mo, $0.001/1M rows read | 인터랙티브 트랜잭션 없음; Postgres JSONB/partial index/pg_trgm 부재; 읽기 복제 beta |
| Active Storage | **R2** | GA | 5 TiB/object, 1/s same-key write | $0.015/GB-mo, $4.50/1M Class A, egress 무료 | S3-compat; Active Storage variant(image_processing) 직접 대응 없음 — Workers + external image resize 필요 |
| Rails.cache (Solid Cache) | **KV** | GA | 25 MiB value, 1 write/s same key, 최종 일관성(60s 내 전파) | Free 100k reads+1k writes/day, Paid 무제한 읽기 | 즉시 일관 필요한 캐시엔 부적합 → Durable Object SQLite로 대체 |
| Solid Queue / Sidekiq | **Queues** | GA (2024 Birthday Week) | 128 KB/msg, 5,000 msg/s, 100 msg/batch, 최대 14일 보존 | 10k op/day Free, 1M/month Paid + $0.40/1M | Sidekiq의 retry policy/scheduler/cron 기능은 직접 구현 필요(Cron Triggers 조합) |
| Solid Cable / ActionCable | **Durable Objects** (WebSocket hibernation) | GA | 1 DO당 10 GB(SQLite) / 50 GB(KV); 32 MiB WS 수신 | $0.15/1M req, $12.50/1M GB-s, SQLite storage billing 2026-01부터 | pub/sub broadcast는 fan-out 패턴 수동 구현 필요; Rails Channel의 `stream_for` 같은 추상화 없음 |
| Rails.logger + Lograge | **Workers Logs / Logpush** | GA | 256 KB log/request, Free 200k events/day(3일 보존) | Logpush Enterprise, Workers Logs 표준 포함 | 구조화 로그 가능하지만 Lograge 레벨의 ActiveSupport::Notifications 통합 필요 시 커스텀 |
| Sidekiq/Rufus cron | **Cron Triggers** | GA | 5/Free, 250/Paid; 최대 15분 duration | Workers 가격에 포함 | 분 단위 최소 주기 |
| Rails middleware (Rack) | **Hono middleware** | (Hono 자체는 OSS) | - | - | 직접 대응, 거의 1:1 |

### E. Korean Market Usage Evidence

한국 시장에서 Cloudflare Workers + D1 스택의 **주류 프로덕션 백엔드 도입 사례는 확인되지 않음**. 대부분의 한국어 콘텐츠는 개인/사이드 프로젝트 또는 소개성 글이다.

#### 확인된 한국어 사례 (개인/사이드 프로젝트 수준)

1. [CloudFlare Workers로 매일 매일 부동산 가격 체크하기](https://velog.io/@gh4777/CloudFlare-Workers%EB%A1%9C-%EB%B6%80%EB%8F%99%EC%82%B0-%EA%B0%80%EA%B2%A9-%EC%B2%B4%ED%81%AC%ED%95%98%EA%B8%B0) — 크롤러 + Discord 웹훅
2. [Cloudflare worker - Websocket 구현](https://velog.io/@jihyeonjeong11/Cloudflare-worker-Websocket-%EA%B5%AC%ED%98%84) — Durable Object + WebSocket PoC
3. [Cloudflare Workers & KV로 Guestbook 개발하기](https://miryang.dev/blog/develop-guestbook-with-cloudflareworkers) — 개인 블로그 방명록
4. [Cloudflare Workers Rust SDK 사용기](https://blog.cro.sh/posts/cloudflare-workers-rust/) — 개인 실험
5. [BGP Works — Cloudflare Workers 서버리스](https://medium.com/bgpworks/cloudflare-workers-%EC%84%9C%EB%B2%84%EB%A6%AC%EC%8A%A4-4de0d9d6aeb2) — 기업 기술 블로그이나 소개성 글
6. [Cloudflare Workers 소개 — Morgenrøde](https://ryanking13.github.io/2020/07/26/introducing-cf-workers-1.html/) — 개인 블로그 소개
7. [Cloudflare Workers - 나무위키](https://namu.wiki/w/Cloudflare%20Workers) — 백과사전 항목

#### Negative evidence

- **토스/당근/쿠팡 등 주요 IT 기업의 Cloudflare Workers 프로덕션 백엔드 사용 사례 검색 결과 없음** (기술 블로그, 발표 자료 탐색 기준)
- **velog/tistory에 D1 프로덕션 후기 포스트 없음** — 검색어 `Cloudflare Workers D1 후기 site:velog.io`, `Cloudflare D1 후기 프로덕션 한국 site:tistory.com`
- 한국 CF 커뮤니티 활동은 영어권(CF Community forum) 대비 약함

#### 한국 특유 운영 이슈

- **서울(ICN) PoP 라우팅 불안정**: 일부 ISP 사용자가 도쿄/후쿠오카/홍콩 PoP로 라우팅되어 ~600ms 지연 케이스 보고 ([Community thread](https://community.cloudflare.com/t/clients-from-south-korea-connect-via-fukuoka-tokyo-osaka-instead-of-seoul/699407))
- 2026-04-23, 2025-12-01 ICN 관련 status 이벤트 기록 존재

### F. 2026 Status Reality Check

#### GA/Beta 현황 요약 (2026-04)

| 서비스 | 상태 | 마일스톤 |
|---|---|---|
| Workers | GA | Standard pricing 2024-03-01 |
| D1 | **GA (2024-04-01)** | 10 GB DB, 50k DB/account; 성능 개선 continuous |
| D1 Read Replication | **Public Beta (2025-04-10)** | 6 regions, Sessions API 기반 |
| R2 | GA | 2022-09 |
| KV | GA | 오래됨 |
| Queues | GA (2024 Birthday Week) | 5000 msg/s, 250 consumers, pull/push, DLQ, message delay |
| Durable Objects | GA | SQLite backend 2024, storage billing 2026-01-07 시작 |
| Workers Analytics Engine | GA (2024-04-01) | |
| Hyperdrive | GA (2024-04-01) | Postgres connection pooling |

#### 2025-2026 주요 변경점

- 2025-01-07: Worker API → D1 latency 40-60% 감소
- 2025-02-10: D1 Free tier 초과 시 에러 반환 시작 (이전 soft limit)
- 2025-02-19: `PRAGMA optimize` 지원
- 2025-04-10: D1 Read Replication public beta
- 2025-05-30: REST API 인증 경로 최적화로 50-500 ms 감소
- 2025-07-01: D1 Paid storage 1 TB/account로 상향; 레거시 alpha 백업 제거
- 2025-09-11: D1 자동 read-only 재시도
- 2025-11-05: D1 jurisdiction 설정 (데이터 로컬라이제이션)
- 2026-01-07: DO SQLite storage billing 시작

#### Top 5 Pitfalls (severity 순)

| # | Severity | Pitfall | 출처 |
|---|---|---|---|
| 1 | Critical | **D1 10 GB/DB hard cap** — 샤딩 없이 스케일 불가. 초기 설계부터 per-tenant/per-entity split 고려 필수 | [Community thread](https://www.answeroverflow.com/m/1345869029906059305), [D1 Limits](https://developers.cloudflare.com/d1/platform/limits/) |
| 2 | High | **D1 단일 스레드 throughput** — 쿼리 duration이 그대로 qps 결정. 큰 UPDATE/DELETE/JOIN은 배치 분할 필수 | [HN 43572511](https://news.ycombinator.com/item?id=43572511) |
| 3 | High | **Node.js 부분 호환** — `child_process`, `cluster`, `async_hooks` stub; native addon(.node) 불가; SQLite native 미지원 → Rails gem(`image_processing`, `redis-client`, `bcrypt` native) 대체 필요 | [Workers Node.js compat](https://developers.cloudflare.com/workers/runtime-apis/nodejs/) |
| 4 | Medium | **D1 Read Replication 여전히 Beta + lag 바운드 없음** — Sessions API 미사용 시 stale read | [Read Replication docs](https://developers.cloudflare.com/d1/best-practices/read-replication/) |
| 5 | Medium | **서울 PoP 라우팅 비일관성** — 한국 일부 ISP 사용자 도쿄/후쿠오카 경유 (~600ms 지연 케이스) | [Community forum](https://community.cloudflare.com/t/clients-from-south-korea-connect-via-fukuoka-tokyo-osaka-instead-of-seoul/699407) |

#### 추가 고려 사항

- **인터랙티브 트랜잭션 없음**: Rails `transaction do` 블록에서 동적 SQL 구성 시 batch API로 재작성 필요
- **Postgres 전용 기능 상실**: JSONB, partial index, materialized view, pg_trgm, full-text search(ts_vector), LISTEN/NOTIFY 등 D1(SQLite)에는 부재
- **Background job retry/scheduler**: Sidekiq의 retry/backoff 정책, 주기 실행(sidekiq-cron), 우선순위 큐 등은 Queues + Cron Triggers 조합으로 수동 구현
- **파일 처리 파이프라인**: Active Storage variant(ImageMagick/libvips)는 Worker 내 실행 불가 → R2 put 후 별도 이미지 리사이즈 Worker 또는 외부 서비스(Cloudflare Images, Imgix) 필요

## Key Findings

### Critical
- **D1 10 GB/DB hard cap + 단일 스레드** (출처: [D1 Limits](https://developers.cloudflare.com/d1/platform/limits/), [Community](https://www.answeroverflow.com/m/1345869029906059305))  
  → Rails+Postgres에서 단일 DB로 운영하던 개인 스키마가 10 GB를 넘으면 샤딩 설계가 강제된다. personality 프로젝트는 현시점에서 규모가 크지 않지만, 성격 테스트 세션 로그/타로 스프레드 기록이 유저당 수 KB 단위로 축적되면 수십만 유저 구간에서 접근 가능. 초기 스키마 설계 시 tenant-scoped 분할 가능성 고려 필요.

### High
- **한국 프로덕션 레퍼런스 부재** (E 섹션 출처들)  
  → 한국어 운영 노하우/장애 대응 커뮤니티 풀이 얕음. 영문 커뮤니티 의존 필수.
- **Hono v4 + Drizzle + D1 조합은 생태계 성숙** ([Hono docs](https://hono.dev/), [starter templates](https://github.com/yusukebe/cloudflare-d1-drizzle-honox-starter))  
  → 마이그레이션 자체의 기술적 난이도는 낮음; 스타터 템플릿과 공식 예제 풍부.
- **Node.js 부분 호환**으로 Rails gem 대부분 재구현 필요 ([Workers Node.js compat](https://developers.cloudflare.com/workers/runtime-apis/nodejs/))

### Medium
- **읽기 복제 여전히 Beta** (2025-04-10 도입 후 1년 경과 시점 beta 유지)  
  → production SLA 기대 가능하지만 공식 GA 미선언 상태.
- **서울 PoP 라우팅 이슈**  
  → 국내 최적화 니즈가 큰 서비스는 위험; 성격/타로 앱은 ms 단위 latency 민감도 낮아 실용상 문제 없음.

### Low
- R2 egress 무료는 Rails+S3 대비 확실한 비용 이점 ([R2 Pricing](https://developers.cloudflare.com/r2/pricing/))
- Cold start ~5 ms는 Rails 부팅 초 단위 대비 이점

## Recommendations

Cycle 2 (synthesis)가 반영할 포인트:

1. **D1 샤딩 전략 우선 결정**: 마이그레이션 타당성 논의 시 "유저당 DB 분리" vs "공용 DB + tenant_id" vs "기능별 DB 분리(성격/타로)" 세 축의 의사결정이 선행되어야 함. 10 GB cap을 설계 제약으로 고정해서 검토.
2. **Rails 트랜잭션 패턴 인벤토리 필요**: Perspective 1(Rails codebase 분석)이 "interactive transaction 필요 지점"을 식별해야 함. 단순 CRUD + after_save callback 수준이면 D1 batch()로 대체 가능, 조건부 UPDATE가 있으면 재설계 필요.
3. **Active Storage 사용 현황 인벤토리**: variant 기반 image processing 패턴이 있으면 Cloudflare Images 서비스 또는 별도 image resize worker 설계 필요 — Perspective 1과 공유할 포인트.
4. **한국 프로덕션 레퍼런스 부족은 위험 요소로 명시**: 장애 시 국내 커뮤니티 지원 얕음. 영문 커뮤니티/서포트 플랜 의존 전제.
5. **Perspective 3 (결제)에 넘기는 정보**: Workers의 outbound fetch 제한(simultaneous connections 6), 15분 cron/queue duration 상한, CPU time 기본 30s → 토스페이먼츠/카카오페이 웹훅 처리에는 문제 없으나 retry/재시도 로직은 Queues 사용 권장.

## References

| Source URL | Role |
|------------|------|
| https://developers.cloudflare.com/workers/platform/limits/ | Workers 한계 공식 |
| https://developers.cloudflare.com/workers/platform/pricing/ | Workers 가격 |
| https://developers.cloudflare.com/workers/runtime-apis/nodejs/ | Node 호환성 |
| https://blog.cloudflare.com/eliminating-cold-starts-with-cloudflare-workers/ | Cold start 공식 |
| https://developers.cloudflare.com/d1/platform/limits/ | D1 한계 |
| https://developers.cloudflare.com/d1/platform/pricing/ | D1 가격 |
| https://developers.cloudflare.com/d1/platform/release-notes/ | D1 GA 타임라인 |
| https://developers.cloudflare.com/d1/best-practices/read-replication/ | D1 읽기 복제 |
| https://developers.cloudflare.com/d1/worker-api/d1-database/ | D1 트랜잭션 |
| https://developers.cloudflare.com/d1/reference/backups/ | D1 백업/Time Travel |
| https://blog.cloudflare.com/making-full-stack-easier-d1-ga-hyperdrive-queues/ | D1 GA 발표 |
| https://news.ycombinator.com/item?id=43572511 | D1 성능 특성 |
| https://www.answeroverflow.com/m/1345869029906059305 | D1 10GB 스케일 한계 |
| https://hono.dev/ | Hono 프레임워크 공식 |
| https://hono.dev/docs/guides/rpc | Hono RPC type safety |
| https://github.com/honojs/hono/releases | Hono 버전 |
| https://www.npmjs.com/package/hono | Hono npm |
| https://github.com/yusukebe/cloudflare-d1-drizzle-honox-starter | Hono+D1+Drizzle 스타터 |
| https://developers.cloudflare.com/r2/platform/limits/ | R2 한계 |
| https://developers.cloudflare.com/r2/pricing/ | R2 가격 |
| https://developers.cloudflare.com/kv/platform/limits/ | KV 한계 |
| https://developers.cloudflare.com/queues/platform/limits/ | Queues 한계 |
| https://developers.cloudflare.com/queues/platform/pricing/ | Queues 가격 |
| https://developers.cloudflare.com/durable-objects/platform/limits/ | DO 한계 |
| https://developers.cloudflare.com/durable-objects/platform/pricing/ | DO 가격 |
| https://community.cloudflare.com/t/clients-from-south-korea-connect-via-fukuoka-tokyo-osaka-instead-of-seoul/699407 | 서울 PoP 라우팅 이슈 |
| https://velog.io/@gh4777/CloudFlare-Workers%EB%A1%9C-%EB%B6%80%EB%8F%99%EC%82%B0-%EA%B0%80%EA%B2%A9-%EC%B2%B4%ED%81%AC%ED%95%98%EA%B8%B0 | 한국 사이드프로젝트 사례 |
| https://velog.io/@jihyeonjeong11/Cloudflare-worker-Websocket-%EA%B5%AC%ED%98%84 | 한국 WS PoC |
| https://miryang.dev/blog/develop-guestbook-with-cloudflareworkers | 한국 개인 사례 |
| https://medium.com/bgpworks/cloudflare-workers-%EC%84%9C%EB%B2%84%EB%A6%AC%EC%8A%A4-4de0d9d6aeb2 | 한국 기업 기술 블로그 |
| https://ryanking13.github.io/2020/07/26/introducing-cf-workers-1.html/ | 한국 개인 블로그 |

## Communication Log
| # | Direction | Peer | Summary | Stage |
|---|-----------|------|---------|-------|
| 1 | OUT | Perspective 1 (Rails analysis) | (share) Rails transaction/Active Storage 인벤토리 필요성 — D1 batch 전환 지점 식별 | Cycle 1 |
| 2 | OUT | Perspective 3 (Payment) | (share) Workers outbound limit 6 connections, cron 15분 상한 — webhook 재시도는 Queues 권장 | Cycle 1 |
