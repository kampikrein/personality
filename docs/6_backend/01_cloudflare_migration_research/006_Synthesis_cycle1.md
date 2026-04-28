---
id: "006"
type: synthesis
title: "Cycle 1 Synthesis — 현 스택·CF 스택·결제 통합 교차 분석"
created: 2026-04-26
status: completed
sources:
  - "003_Agent_current_rails_assets.md"
  - "004_Agent_cloudflare_stack_capabilities.md"
  - "005_Agent_payment_integration.md"
traces_brief: "001"
traces_research: "002"
summary: >
  Cycle 1의 3개 관점이 Brief의 보수적 가정을 두 방향으로 깨뜨렸다.
  마이그레이션 비용은 Brief 예상보다 낮고(현 코드의 60% 이상이 순수 로직 services + 0 API + 0 production data),
  플랫폼 운영 리스크는 Brief 예상보다 높다(D1 10GB 하드캡, 한국 ISP Seoul PoP 라우팅 불일치, 한국 메인스트림 채택 부재, Stripe Korea 가맹점 부재).
  Cycle 2는 이 비대칭(낮은 비용 vs 높은 리스크)을 정량화해야 한다.
keywords: [synthesis, cycle-1, rails, cloudflare, payment, asymmetry, decision-input]
---

# Cycle 1 Synthesis — 현 스택·CF 스택·결제 통합 교차 분석

본 종합은 Cycle 1의 3개 관점(P1: 현 Rails 자산, P2: CF 스택 역량, P3: 결제 통합)을 교차 분석하여 **Cycle 2가 출발해야 할 명제**를 정리한다. 개별 발견은 원본 보고서 참조; 본 문서는 **교차 발견·공통 패턴·상충점·Cycle 2 입력**에만 집중한다.

원본 보고서:
- [`003_Agent_current_rails_assets.md`](./003_Agent_current_rails_assets.md) — confidence: high
- [`004_Agent_cloudflare_stack_capabilities.md`](./004_Agent_cloudflare_stack_capabilities.md) — confidence: high
- [`005_Agent_payment_integration.md`](./005_Agent_payment_integration.md) — confidence: high

---

## 1. 핵심 비대칭의 발견

Brief 001은 마이그레이션 결정을 "비용 vs 가치" 균형으로 가정했다. Cycle 1은 이 균형이 **양 끝에서 모두 무너진 비대칭** 상태임을 발견했다.

### 비용 측 (Brief 예상보다 **낮음**)

| 발견 | 근거 | 함의 |
|------|------|------|
| **production DB 데이터 0** | P1: `server/storage/`에 production.sqlite3 부재 | 데이터 마이그레이션 비용 = 사실상 0. 16 PersonalityType seed만 재생성 |
| **JSON API 엔드포인트 0** | P1: 17개 라우트 모두 HTML 렌더링 | 보존해야 할 API 계약 없음 → CF로 갈 때 새 API 표면 자유 설계 가능 |
| **모바일이 서버 API를 사용 안 함** | P1 + Brief 001 Context | 클라이언트 호환성 부담 0. 모바일이 어차피 곧 새 API와 만나야 함 |
| **Solid Queue/Cache/Cable 모두 미사용** | P1: app/jobs/는 base class만, app/channels/ 없음, Rails.cache.* 호출 없음 | Brief가 "Rails 8 핵심 가치 제안"으로 평가한 자산이 실제로는 **dead weight**. 잃을 것이 없음 |
| **핵심 도메인 = 1,850 LOC 순수 services** | P1: app/services/의 scoring/tone-filter/restricted-terms/insights | TypeScript 이식이 깨끗 (외부 의존 없는 순수 로직) |
| **Hotwire Turbo Frame은 2 템플릿에 한정** | P1: assessment question flow 한 곳 | "Hotwire 자산 손실"이 Brief가 가정한 만큼 큰 손실이 아님 — 한 흐름의 설계 결정 |
| **결제 코드 0** | P1+P3: gem/model/controller 어디도 없음 | 결제 포팅 비용 = 0 (양 스택 동등 출발선) |

→ **합산 함의**: Brief가 가정한 마이그레이션 공수의 상당 부분이 **사실상 존재하지 않는 자산의 보존 비용**이었다. 실제 마이그 공수는 Brief 예상보다 **현저히 낮을 가능성**이 높다.

### 리스크 측 (Brief 예상보다 **높음**)

| 발견 | 근거 | 함의 |
|------|------|------|
| **D1 10GB/DB는 하드캡 (상향 불가)** | P2: developers.cloudflare.com/d1/platform/limits | "장기 관점"에서 데이터 누적 시 **샤딩 설계가 강제**됨. PostgreSQL/MySQL의 "수십~수백 GB 단일 인스턴스" 사고방식이 적용 불가 |
| **D1 읽기 복제 = public beta (2025-04 이후 1년+)** | P2: 2025-04-10 발표, 2026-04 현재 GA 미달성 | 읽기 부하 분산이 **장기 안정 기능에 의존 못 함** |
| **Seoul (ICN) PoP 라우팅 불일치** | P2: 일부 한국 ISP가 Tokyo/Fukuoka로 라우팅, ~600ms 패널티 | "엣지 = 한국 사용자에게 빠르다"가 **항상 사실 아님**. Korea-local VPS 대비 우위 의문 |
| **한국 메인스트림 백엔드 채택 사례 부재** | P2: 토스/당근/쿠팡 등 사용 증거 없음. 사이드프로젝트 수준만 | 생태계 신호 약함 — 한국어 트러블슈팅 자료, 채용 가능 인력, 사례 학습 모두 제한적 |
| **D1 트랜잭션 = snapshot, interactive 트랜잭션 없음** | P2: D1 docs | Rails ActiveRecord의 `transaction do ... end` 블록 패턴 1:1 이식 불가. 배치 단위 재설계 필요 |
| **D1 단일 스레드 (DB당)** | P2: 1ms 쿼리 ≈ 1k qps, 100ms 쿼리 ≈ 10 qps | 무거운 쿼리가 throughput 천장을 결정. 인덱스/쿼리 튜닝 부담 ↑ |
| **Stripe Korea 가맹점 엔티티 부재 (2026-04)** | P3: NICEPay 파트너십만 있음 | 글로벌 결제 옵션이 한국 거주 운영자에게 **사실상 닫힘**. Brief 결정 5의 "글로벌 병행"이 근거 약화 |
| **Workers 6 outbound 동시 연결 제한** | P2 | 외부 PG 호출이 많은 흐름에서 큐 도입 필요 가능성 |

→ **합산 함의**: 단순한 "Cloudflare는 빠르고 싸다"의 일반론이 한국 컨텍스트에서 **역방향 신호**를 가질 수 있다. 장기 운영의 안정성이 Brief 예상보다 의문 신호가 많음.

---

## 2. 교차 발견 (Inter-Perspective)

### P1 × P2: Rails → CF 매핑의 정확한 격차

P2의 매핑 표와 P1의 실측 코드를 결합하면 **이식 비용 = 0** 항목과 **이식 비용 = 큼** 항목이 분명해진다.

| 영역 | P1 실측 | P2 매핑 | 격차 |
|------|---------|---------|------|
| ActiveRecord 모델·연관 | 15개, polymorphic/STI 없음, 14 FKs | Drizzle/Prisma + D1 | **작음** — 단순 매핑 |
| `User.encrypts :email, deterministic: true` | 1개 사용처 | 직접 대응 없음 — 수동 AES-GCM + deterministic IV | **중간** — 구현 + 테스트 |
| SQLite JSON 컬럼 | 9개 컬럼 | D1 JSON1 함수 지원, JSONB-style indexing 없음 | **중간** — 인덱싱 전략 재설계 |
| Solid Queue/Cache/Cable | **미사용** | Queues / KV / Durable Objects | **0** — dead weight |
| Hotwire Turbo Frame | 2 템플릿 | SSR(Hono) 또는 SPA 분리 | **중간** — 한 흐름 재설계 |
| Stimulus 컨트롤러 8개 | UI 상호작용 | Vanilla JS / Alpine / Solid 등 | **작음** — 라이브러리 교체 |
| RSpec 18 파일 / 2,641 spec LOC | 도메인 테스트 | Vitest / bun test 등 | **중간** — 테스트 재작성 (도메인 동등) |
| 도메인 services 1,850 LOC | 순수 로직 | 직접 TypeScript 이식 | **작음** — 함수 시그니처만 다름 |
| Kamal 배포 | docker + ssh | Wrangler deploy | **작음** — CI 재구성 |
| Active Storage / Action Text | **미사용** (P1: variant processing 없음) | R2 (대체 가능) | **0** — dead weight |
| ActiveRecord callback chains | (P1: 패턴 사용 있으나 단순) | Hono middleware / 수동 | **중간** — 패턴 재구현 |

### P1 × P3: 결제 포팅 비용은 양 스택 동등

P1은 결제 코드 0 확인, P3는 6셀 매트릭스 모두 실현 가능 확인. 결합:
- **결제는 마이그레이션 비용의 변수가 아니다**. 어느 스택을 선택하든 새로 작성.
- 단, P3의 LOC 추정(300~1,000)은 스택 선택의 부산 비용 — **Workers+Stripe 300 LOC vs Rails+PortOne 700~1,000 LOC**의 격차는 인정해야 함.
- 다만 P3가 Stripe Korea 가맹점 부재를 확인했으므로, 한국 우선 시 실용 조합은 **{Toss, PortOne} × {Rails, Workers}** 4셀로 축소.

### P2 × P3: CF Workers + 한국 결제

P3는 CF Workers에 결제 구조적 블로커가 없다고 결론지었지만, P2의 운영 리스크가 결제 흐름에 영향:
- **콜드 스타트 ~5ms baseline**: webhook 처리 지연으로는 무시 가능
- **CPU 30s default**: webhook 처리에 충분
- **6 outbound 연결 제한**: PG 호출 + DB 쓰기가 직렬일 경우 무관, 병렬 정합성 검증 시 주의
- **Seoul PoP 라우팅 불일치**: 한국 사용자의 결제 위젯 응답 지연 가능성. 토스 위젯은 PG가 호스팅하므로 사용자 → PG는 직접 경로(영향 없음), 사용자 → 우리 백엔드 webhook 응답이 영향. 결제 완료 → 마이앱 confirm 호출이 600ms+ 라우팅을 타면 **사용자 체감 지연 발생 가능**.
- **D1 single-thread**: 동시 결제 폭증 시(이벤트성) 쓰기 throughput이 천장 — UNIQUE(event_id) idempotency 인덱스 활용 시 추가 부담

---

## 3. 공통 패턴

| 패턴 | 3개 관점 모두 동일하게 신호 |
|------|----------------------------|
| **현 시스템은 "사용자 1명도 본 적 없는" 미배포 상태에 가깝다** | P1(no prod data, no API), P2(maturity는 미래), P3(no payment yet) — **Greenfield에 매우 가까움** |
| **Korean 컨텍스트에서 CF는 글로벌 베스트 프랙티스의 단순 적용이 어렵다** | P2(메인스트림 부재, ISP 라우팅), P3(Stripe Korea 부재) — 한국 시장 특수성이 글로벌 일반론을 굴절 |
| **마이그레이션의 진짜 작업은 "코드 이식"이 아니라 "API 설계"** | P1(JSON API 0), P2(API-first가 CF의 자연스러운 모델), P3(결제 = API 신설) — 어느 스택이든 신설 API 작성 부담은 동등 |

---

## 4. 상충 발견 (Conflicting Items)

### 상충 1: 마이그 비용 vs 운영 리스크

- **P1 신호**: 비용 낮음 → "지금이 전환의 골든 윈도우"로 해석 가능
- **P2 신호**: 운영 리스크 있음 → "검증된 스택 유지가 안전"으로 해석 가능

**해소 방향**: Cycle 2의 P5가 두 신호를 정량화하여 **비용-가중 리스크**로 통합 평가.

### 상충 2: "엣지 = 빠름"의 가정

- **CF 일반 논리**: 글로벌 엣지 → 사용자 가까움 → 빠름
- **P2 발견**: 한국 ISP의 Seoul PoP 라우팅 불일치 → 600ms 패널티 가능

**해소 방향**: 사용자 분포(국내 비중)를 P5의 권고에 변수화. 100% 국내 한정 서비스라면 엣지 가치가 약화.

### 상충 3: D1 매력 vs D1 한계

- **D1 매력**: SQLite 호환, 현 SQLite 사용에서 마이그 친화적
- **D1 한계**: 10GB/DB 하드캡, 단일 스레드, 트랜잭션 제약, 읽기 복제 beta

**해소 방향**: P4의 운영비 모델에서 "10GB 도달 시기 = 샤딩 시점"을 트래픽 시나리오별로 추정. 고 시나리오(수십만 MAU)에서 도달 가능성 확인.

---

## 5. Cycle 2 입력 (P4·P5에 전달할 핵심 명제)

### P4 (마이그비용 + 운영비 모델링)에 전달

1. **마이그 비용 입력 (P1+P2 결과)**:
   - 도메인 모델: 15개 (단순 매핑) → MAN-WEEK 추정
   - 컨트롤러: 13개 + admin → 신규 API 설계 + Hono 핸들러
   - Hotwire Turbo Frame: 2 템플릿만 SPA 또는 SSR 재설계
   - Stimulus: 8개 → vanilla JS 또는 라이브러리 교체
   - Services 1,850 LOC: 직접 TypeScript 이식 (테스트 동행)
   - RSpec → Vitest: 18 파일 / 2,641 LOC 재작성
   - User.encrypts: AES-GCM 수동 구현 + 테스트
   - Solid* 대체: **0 비용** (미사용)
   - Active Storage: **0 비용** (미사용)
   - 결제: 양 스택 모두 신규 (P3의 LOC 범위 적용)

2. **운영비 입력 (P2 한도 데이터)**:
   - Workers Paid: $5/월 + 10M req + 30M CPU-ms 기본
   - D1 Paid: 10GB/DB 하드캡, 25B reads + 50M writes/월 기본
   - 트래픽 시나리오 3단계에서 각 한도 도달 시점 산출
   - **샤딩 비용 모델링** (D1 10GB 하드캡 도달 시): 코드 복잡도 + 운영 추가 비용

### P5 (리스크 + 3안 권고)에 전달

1. **리스크 입력**:
   - Korean ISP routing → 영향: 한국 사용자 응답 지연 가능
   - D1 maturity (read replication beta 1년+) → 영향: 읽기 확장성 의존
   - Korean ecosystem 부재 → 영향: 인력·문서·사례 부족
   - Stripe Korea 부재 → 영향: 글로벌 결제 경로 닫힘 (Brief 결정 5 약화)
   - D1 10GB 하드캡 → 영향: 장기 데이터 누적 시 샤딩 강제

2. **3안 권고 입력 (Strangler 경로 재해석)**:
   - **Stay**: Rails 유지. P1 발견("미배포 시스템") 감안 시 가장 보수적
   - **Partial**: P1 발견("API 0개, 모바일 미연결")이 **Partial을 강하게 시사** — 신규 모바일 API만 CF Workers로 시작하고 Rails 웹은 admin 전용으로 유지
   - **Full**: 현 코드 자체가 "버릴 게 별로 없는" 상태이므로 전면 재작성 비용이 Brief 가정보다 낮음 — 그러나 위 운영 리스크 모두 떠안음

3. **선택 조건 가설** (P5가 검증):
   - 한국 사용자 비중 ≥ 80% + 데이터 ≤ 10GB 1년 내 → Partial 유리
   - 글로벌 확장 의도 + 결제 글로벌 → Full 유리하지만 Stripe Korea 부재로 운영 주체 분리 필요
   - 변동성 큰 트래픽 + 단순 도메인 → Full 유리
   - 풀타임 1인 운영 + Ruby/Rails 친숙 → Stay 유리

---

## 6. Incremental Summary (synthesis 스킬 입력용)

### 리서치 축
- **축 이름**: 현 스택·CF 스택·결제 통합 교차 분석 (Cycle 1)
- **핵심 질문**: 전환의 비용·역량·결제 가능성 각각의 객관적 사실은?

### 핵심 발견 (우선순위 순)

1. **[Critical] R-006-F1: Brief의 "비용 vs 가치" 균형이 양 끝에서 깨짐** — 마이그 비용은 Brief 예상보다 낮고(0 prod data + 0 API + 미사용 Solid* + 1,850 LOC 순수 services), 운영 리스크는 예상보다 높다(D1 10GB 하드캡, 한국 ISP 라우팅, Korean 메인스트림 부재). *(관점 1, 2)*
2. **[Critical] R-006-F2: 시스템이 사실상 Greenfield 상태** — 모바일이 서버 API를 안 쓰고, 결제는 미구현, prod DB는 비어있음. 이는 Partial migration(신규 API만 CF) 또는 Full rewrite의 비용을 둘 다 크게 낮춤. *(관점 1, 3)*
3. **[High] R-006-F3: Stripe Korea 가맹점 엔티티 부재 (2026-04)** — Brief 결정 5의 "글로벌 병행"이 운영 주체 분리(해외 법인) 없이는 불가능. 한국 우선 시 Toss/PortOne 2개로 축소. *(관점 3)*
4. **[High] R-006-F4: D1 10GB/DB 하드캡은 장기 샤딩 강제** — 상향 불가. 고 트래픽 시나리오에서 샤딩 설계 필수, 코드 복잡도 + 운영비 증가. *(관점 2)*
5. **[High] R-006-F5: Solid Queue/Cache/Cable 모두 dead weight** — Brief가 "Rails 8 핵심 가치"로 평가했으나 실제 사용 0. 마이그 시 잃을 것 없음. *(관점 1)*
6. **[Medium] R-006-F6: Hotwire 자산 손실은 국지적** — Turbo Frame 2 템플릿 + Stimulus 8개에 한정. Brief가 가정한 "전면 재작성 부담"과 다름. *(관점 1)*
7. **[Medium] R-006-F7: 한국 ISP의 Seoul PoP 라우팅 불일치** — 일부 ISP에서 Tokyo/Fukuoka 라우팅으로 ~600ms 페널티. "엣지 = 빠름" 가정이 한국 100% 사용자 시나리오에서는 약화. *(관점 2)*
8. **[Medium] R-006-F8: D1 읽기 복제 1년+ public beta 지속** — 읽기 확장성 의존이 미성숙. 고 트래픽 시 read-heavy 워크로드 위험. *(관점 2)*
9. **[Medium] R-006-F9: 결제 포팅 비용은 스택 무관** — 6셀 매트릭스 모두 실현 가능, Workers + Stripe 조합이 LOC 최소(300~600). *(관점 3)*
10. **[Low] R-006-F10: Korean 백엔드 메인스트림 채택 부재** — 인력·트러블슈팅·사례 측면 생태계 신호 약함. 직접 운영 부담 ↑. *(관점 2)*

### 결론

이 축의 핵심 질문(전환의 비용·역량·결제 가능성)은 **부분 해결**: 6셀 결제 매트릭스, CF 한도 수치, 현 Rails 자산 인벤토리는 모두 확인됨. 하지만 "비용·리스크 비대칭이 정량적으로 어느 안을 가리키는가"는 Cycle 2(P4 수치 모델링 + P5 권고)에서 결정.

### 미해결 사항

- 마이그 공수 MAN-WEEK 정확 추정 → P4
- 운영비 시나리오별 시뮬레이션 → P4
- 리스크 확률·영향도 매트릭스 → P5
- 3안 권고 + 선택 조건 → P5

---

## Communication Log

| # | Direction | Peer | Summary | Stage |
|---|-----------|------|---------|-------|
| 1 | ← | P1 | 결제 코드 0 확인, payment 포팅 비용 = 0 baseline | Cycle 1 종료 |
| 2 | ← | P2 | D1 10GB 하드캡 + 한국 ISP 라우팅 + Korean 메인스트림 부재를 P5 리스크 입력으로 | Cycle 1 종료 |
| 3 | ← | P3 | Stripe Korea 가맹점 부재 → Brief 결정 5 약화, 한국 우선 시 Toss/PortOne만 | Cycle 1 종료 |
| 4 | → | P4 | 마이그 비용 입력(15모델/13컨/2템플릿/8stim/1,850 svc/18 spec) + 운영비 한도 데이터 | Cycle 2 디스패치 |
| 5 | → | P5 | 리스크 5종 + 3안 가설 + 선택 조건 후보 | Cycle 2 디스패치 |
