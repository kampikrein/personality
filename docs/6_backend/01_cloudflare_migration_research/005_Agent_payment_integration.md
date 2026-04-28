---
id: "005"
title: "Payment Integration Feasibility (Toss/PortOne/Stripe × Rails/CF Workers)"
category: agent
status: completed
created: 2026-04-24
summary: >
  6개 조합 모두 기술적으로 실현 가능. Toss/PortOne × Rails·Workers는 F(FC),
  Stripe는 한국 법인 가입 경로 부재(2026-04)로 전 스택 FC. CF Workers는 결제에
  구조적 블로커 없음 — webhook HMAC-SHA256 검증(Web Crypto), D1 idempotency,
  Hono 공식 Stripe 예제 + PortOne 공식 JS SDK로 표준 패턴 존재. 한국 규제상
  서버 지리 강제 조항 없음(PG-hosted 흐름 준수 시). 권고: Toss 직결(초기)
  또는 PortOne(다중 PG 유연성), Stripe는 글로벌 확장 시 병렬 도입.
model: "sonnet"
reasoning_depth: "standard"
confidence: high
keywords: [agent-report, payment, toss, portone, stripe, webhook, pci-dss, korea]
---

# Payment Integration Feasibility

## Progress
### Completed
- [x] Confirm no existing payment code (server/ grep)
- [x] Toss Payments API (위젯/Core/Brandpay, 웹훅 서명·재시도·IP·TLS)
- [x] PortOne API (V2, 다중 PG 추상화, Standard Webhooks 서명)
- [x] Stripe API + Korea availability (NICEPay 파트너십, 한국 법인 부재)
- [x] CF Workers + webhook patterns (Hono 예제·미들웨어, Web Crypto, D1 idempotency)
- [x] PCI-DSS scope decisions (SAQ A default, 2024+ ASV quarterly)
- [x] Korean regulatory review (전자금융거래법·개인정보보호법)
- [x] 6-cell feasibility matrix (verdict·LOC·제약·웹훅 전략)
- [x] LOC/MAN-DAY estimates (300-1,000 LOC 범위)
### Remaining
(none)
### Current Status
Completed.

## Summary

PG 3종(Toss/PortOne/Stripe) × 스택 2종(Rails/Kamal, CF Workers+Hono) 6개 조합을 조사했다. 결론:

1. **기술적 실현 가능성**: 6개 조합 모두 실현 가능. 블로커는 기술이 아닌 비즈니스(Stripe) 또는 구현 공수 수준.
2. **Stripe는 한국 법인 직접 가입 경로 부재 (2026-04)** — NICEPay 파트너십은 해외 merchant가 한국 고객 받을 때 가능. 따라서 한국 주체 서비스는 Toss 또는 PortOne이 1차 선택.
3. **CF Workers는 결제 블로커 없음**. 웹훅 HMAC-SHA256 검증은 Web Crypto API로 구현 가능 (50 LOC), Hono Stripe 공식 예제·PortOne JS SDK·D1 idempotency 표준 패턴 존재. 콜드스타트(~5-50ms)는 웹훅 10초 허용에 무관.
4. **한국 규제 블로커 없음 (PG-hosted 흐름 준수 시)**. 전자금융거래법은 PG사에 적용, 서버 지리 강제 조항 부재. 개인정보 국외 이전은 동의·고지로 해결.
5. **권고 조합**: **Toss × (Rails 또는 CF Workers) for 초기**, PortOne은 다중 PG 유연성 필요 시, Stripe는 글로벌 확장 시점 병렬 도입.

## Details

### A. Current State (internal)

**결론: 결제 구현 완전 부재.**

- `server/Gemfile` — 결제 관련 gem(stripe, iamport, tosspayments, payjp, kg_inicis, portone) 매칭 **0건**.
- `server/app/models/` — `Payment`/`Subscription`/`Billing`/`Invoice` 매칭 파일 **0건**.
- `server/app/controllers/` — `payment`/`billing`/`webhook` 이름 컨트롤러 **0건**.
- `server/app/` 트리에서 결제/빌링 키워드 grep 결과 **0건** (head -20 기준).

**함의**: 마이그레이션 비용 계산에서 "기존 결제 코드 포팅" 항목은 0. 어느 스택을 선택하든 결제는 신규 구축이며, **스택 선택이 결제 구현 방식을 거의 완전히 결정**한다(선택 후 다른 스택으로의 이중 구현 비용이 따로 존재하지 않음).

### B. Toss Payments (토스페이먼츠)

**상품 라인업**
- **결제위젯/결제창 (PG-hosted)** — SDK 한 줄 통합, 토스 호스팅 UI, PCI 스코프 최소화 경로.
- **Core API** — 카드 직결, 직접 승인 요청. 서버 구현 필수.
- **Brandpay** — 간편결제 위젯 (고객 카드 저장은 토스가 관리).
- 지원 결제수단: 카드, 계좌이체, 가상계좌(입금 callback 필수), 간편결제, 휴대폰, 상품권.
- 출처: [Toss Payments 개발자센터](https://developers.tosspayments.com/).

**Webhook (핵심 기술 제약)**
- 등록: 대시보드에서 MID별 등록. URL은 공개 접근 가능해야 함 (localhost/ngrok은 개발용).
- 이벤트: `PAYMENT_STATUS_CHANGED`, `DEPOSIT_CALLBACK`(가상계좌), `CANCEL_STATUS_CHANGED`, `METHOD_UPDATED`, `CUSTOMER_STATUS_CHANGED`, `payout.changed`, `seller.changed`, `BILLING_DELETED`, `ORDER_PAYMENT_STATUS_CHANGED` — 총 9개.
- **재시도**: 최대 7회, exponential backoff (1·4·16·64·256·1024·4096분), 총 약 **3일 19시간**.
- **타임아웃**: 상점 서버가 **10초 이내 HTTP 200** 응답 필수. 시간 초과/비-2xx 시 재시도.
- **서명 검증**: `{WEBHOOK_PAYLOAD}:{tosspayments-webhook-transmission-time}` 문자열을 보안 키로 **HMAC-SHA256 해싱**. 헤더 `v1:` 뒤의 2개 값을 base64 디코드 후 해시값과 비교 (둘 중 하나 일치면 정상).
- 출처: [웹훅(Webhook) 연결하기](https://docs.tosspayments.com/guides/v2/webhook), [웹훅 이벤트](https://docs.tosspayments.com/reference/using-api/webhook-events).

**네트워크/보안 요구**
- Toss 아웃바운드 IP (상점 서버 → `api.tosspayments.com`): `103.182.251.2`, `103.182.250.2`, `210.98.141.21-22`. 상점이 Toss API 호출 시 방화벽 ACL에 허용 필요.
- Toss 웹훅 인바운드 IP (Toss → 상점): `13.124.18.147`, `13.124.108.35`, `3.36.173.151`, `3.38.81.32`, `115.92.221.121-127`. 상점 서버가 IP 화이트리스트를 쓰면 이들 허용 필요.
- **TLS 1.2 이상 필수**, TLS 1.3 권장. SSL/TLS 1.1 이하 거부.
- 출처: [보안](https://docs.tosspayments.com/reference/using-api/security).

**테스트/샌드박스**
- 테스트 클라이언트키/시크릿키 제공(공식 문서 명시), 샌드박스 환경에서 가입 없이 결제 흐름 테스트 가능.

**서버 위치 제약**
- 문서상 상점 서버의 **지리적 위치 강제 규정 없음**. 즉 해외/엣지 호스팅 금지 명문 조항은 확인되지 않음. 단, 전자금융거래법·개인정보보호법 측면은 F 섹션 참조.

### C. PortOne (포트원, 구 아임포트)

**플랫폼 특징**
- 16개+ PG(토스페이먼츠, NHN KCP, KG이니시스, PayPal, Eximbay 등)를 단일 SDK·API로 추상화.
- V2(현행 권장) vs V1(레거시). V2는 Webhook V2 체계 사용.
- 서버 SDK: JavaScript(`@portone/server-sdk` — npm/jsr), Python(`portone-server-sdk` — PyPI), Go/C#/Java(GitHub `portone-io/server-sdk`).
- 출처: [PortOne Docs](https://developers.portone.io/).

**Webhook 서명 검증 (V2)**
- **Standard Webhooks 사양 준수** — 업계 표준 사양 채택 (주: Stripe와 동일 계열 접근).
- 헤더: `webhook-id`, `webhook-signature`, `webhook-timestamp` 세 필드 필수.
- 알고리즘: Webhook V2 Secret으로 **HMAC-SHA256** 서명, 요청 헤더 값과 비교.
- PortOne 서버 SDK가 검증 로직 제공 → JS/Python 생태계에서는 한 함수 호출로 검증 완료.
- 출처: [웹훅 연동하기](https://developers.portone.io/opi/ko/integration/webhook/readme-v2?v=v2).

**서버 위치 제약**
- 명시적 서버 위치 요구사항 없음 (REST API 호출 + 웹훅 수신 모델이라 geographically flexible).
- 출처: [PortOne Docs 전체](https://developers.portone.io/).

### D. Stripe

**한국 상황 (2026-04)**
- **Stripe Korea (직접 entity) 없음**. Korean 법인이 Stripe에 직접 merchant로 가입하는 경로 아직 미개설 (2026-04 기준 검색 결과).
- **NICEPay 파트너십 (2024-08)**: 해외 merchant가 한국 고객에게 현지화된 결제 경험 제공 가능. 20+ 카드 브랜드, 4개 로컬 지갑(Kakao Pay, Naver Pay, Samsung Pay, PayCo), end-to-end settlement. **KRW 전표**, 최소 100 KRW.
- 함의: **서비스 주체(법인)가 한국인 경우 Stripe 단독은 원칙적 비권장**. 해외 법인/BaaS 경유 시에만 유의미.
- 출처: [South Korean payment methods](https://docs.stripe.com/payments/countries/korea), [Stripe + NICEPay 2024 발표](https://stripe.com/newsroom/news/tour-singapore-2024), [Stripe global availability](https://stripe.com/global).

**Webhook 서명 검증**
- 헤더: `Stripe-Signature` (타임스탬프 + v1 서명 포함 CSV 포맷).
- 알고리즘: `timestamp.payload`를 Webhook Signing Secret으로 **HMAC-SHA256** 후 비교.
- SDK: `stripe.webhooks.constructEvent(raw_body, sig_header, secret)` — raw body 필수.
- CF Workers 지원: Stripe JS SDK가 Workers에 GA (v11.10.0+는 `node_compat` 불필요).
- Hono 공식 예제 제공 (`c.req.text()`로 raw body 확보).
- 출처: [Stripe Webhook - Hono](https://hono.dev/examples/stripe-webhook), [Announcing Stripe SDK in Workers](https://blog.cloudflare.com/announcing-stripe-support-in-workers/).

**PCI-DSS**
- Stripe Checkout(호스팅) 사용 시 **SAQ A** 적격 — 카드 데이터가 상점 서버를 통과하지 않음.
- 2024+ 변경: SAQ A도 **ASV 분기 스캔** 요구 (90일마다). iframe/redirect 여부 무관.
- 출처: [Stripe PCI 가이드](https://stripe.com/guides/pci-compliance), [SAQ A 2025 Guide](https://www.linkedin.com/pulse/saq-simplified-2025-guide-easiest-pci-dss-compliance-path-uday-kumar-amilc).

### E. CF Workers Webhook Patterns

**Stripe + Workers + Hono**
- Hono 공식 예제와 두 개의 커뮤니티 미들웨어(`@nakanoaas/hono-stripe-webhook-middleware`, `...-lite`) 존재.
- Lite 버전은 Stripe SDK 미의존 → 번들 크기 작아 엣지/서버리스 친화.
- `stripe` npm 패키지 v11.10.0+ Workers GA.
- 출처: [Hono Stripe Webhook](https://hono.dev/examples/stripe-webhook), [Cloudflare × Stripe 발표](https://blog.cloudflare.com/announcing-stripe-support-in-workers/), [jross.me 가이드](https://jross.me/verifying-stripe-webhook-signatures-cloudflare-workers/).

**Toss + Workers**
- 공식 Workers 가이드/미들웨어 **없음**. 직접 구현 필요.
- HMAC-SHA256 검증은 Workers Web Crypto API (`crypto.subtle.importKey` + `crypto.subtle.sign`)로 구현 가능 (표준 패턴, 50 LOC 이내).
- 주의: `c.req.text()` 또는 `request.clone().arrayBuffer()`로 **raw body 확보 후** 검증 (파싱된 JSON은 공백·키 순서 문제로 서명 불일치).

**PortOne + Workers**
- `@portone/server-sdk` 공식 JS SDK — Workers 런타임 공식 지원 여부는 명시 미확인이나 npm ESM 패키지이므로 대체로 호환. 문제 시 Standard Webhooks 사양(HMAC-SHA256)을 직접 구현(30~60 LOC).

**Workers 제약**
- **CPU 시간**: Free 10ms/요청, Paid 기본 30초, 최대 **5분(300,000ms)**까지 증액 가능. 웹훅 단일 처리에는 과충분.
- **요청 body 크기**: Free/Pro 100MB, Business 200MB, Enterprise 500MB+. 결제 웹훅 페이로드(~수 KB)에는 무관.
- **콜드스타트**: V8 isolate 모델로 Lambda 대비 ~5ms 수준(일반적으로 <50ms). 결제 승인 10초 요구엔 영향 無.
- 출처: [Workers Limits](https://developers.cloudflare.com/workers/platform/limits/), [Workers Pricing](https://developers.cloudflare.com/workers/platform/pricing/).

**Idempotency 저장소 (웹훅 재시도 대비 중복 처리 방지)**
- **D1**: `UNIQUE(event_id)` 제약 + `INSERT OR IGNORE`. 쿼리 ~1-5ms. 영속적, 관계형. 기본 선택.
- **Durable Objects**: 이벤트 ID 단위 actor로 순서 보장 + 강한 일관성. 복잡도↑, 필요 시에만.
- **KV**: 최종 일관성 (쓰기 후 ~60초까지 stale 가능) — idempotency 용도 **부적합**.
- 권장: D1에 `webhook_events(event_id PK, provider, received_at, processed_at)` 테이블 + UPSERT 패턴.

**주의사항 (커뮤니티 보고)**
- Cloudflare 프록시가 웹훅 body를 수정하지 않는지 확인 필요(일반적으로 수정 없음; 일부 트랜스폼 옵션 활성화 시 주의).
- 출처: [Cloudflare Community — Stripe webhook integrity](https://community.cloudflare.com/t/does-cloudflare-alter-stripe-webhook-payloads-help-to-preserve-signature-integrity/786306).

### F. PCI-DSS & Korean Regulatory

**PCI-DSS 스코프 결정**

| 패턴 | PCI 스코프 | 추천도 |
|------|-----------|--------|
| PG-hosted redirect (Toss 결제창, Stripe Checkout, PortOne SDK 결제창) | **SAQ A** (최소) — 카드 데이터 상점 서버 미경유 | **최우선** |
| Iframe 임베드 (결제위젯) | SAQ A 또는 SAQ A-EP (iframe 소스 제어에 따라) | 양호 |
| 상점 서버가 카드 정보 수신 후 Core API 호출 | **SAQ D** (최대) — 전면 PCI-DSS 적용 | 비권장 |

- 2024+ SAQ A도 **분기 ASV 스캔** 요구 (iframe/redirect 공통). 공개 도메인 전체가 스캔 대상.
- 모바일 앱은 Flutter 내에서 PG SDK WebView 경로를 쓰면 서버는 거래 생성/승인 API만 처리 → **서버는 카드 데이터 접촉 없음 → SAQ A 유지**.
- 출처: [Stripe PCI 가이드](https://stripe.com/guides/pci-compliance), [SAQ A 2025 Guide](https://www.linkedin.com/pulse/saq-simplified-2025-guide-easiest-pci-dss-compliance-path-uday-kumar-amilc).

**한국 전자금융거래법·개인정보보호법 관점**

- **전자금융거래법 제28조** — 전자지급결제대행업은 **금융위원회 등록 의무**. 단, 자금 이동에 직접 관여하지 않고 정보 전달만 하면 등록 면제. **토스/포트원을 경유하면 PG사가 등록업자**이므로 상점(본 서비스)은 등록 불필요.
- **서버 지리적 위치 강제 조항 없음** — 전자금융거래법은 PG사(감독 대상 금융회사)에 대해 전산센터·물리적 보안·망분리 요구가 있으나, **비금융 일반 상점의 서버 위치를 한국에 묶는 명문 조항은 검색 결과에서 확인되지 않음**. PG를 통한 일반 전자상거래는 일반 정보통신망법 범위.
- **개인정보보호법**: 개인정보 **국외 이전** 시 동의 또는 예외 사유 필요 (제28조의8). Cloudflare 엣지 실행은 사용자 가까운 노드에서 이뤄지므로, D1 저장소가 해외 리전이면 개인정보 국외 저장에 해당 → **개인정보 처리방침에 국외 이전 사실 고지 및 이용자 동의 획득 필요**. 원천적 금지 아님.
- **카드정보·계좌번호는 상점 DB에 저장 금지** (PG가 보관). 이 원칙만 지키면 해외 클라우드 사용 자체는 규제 블로커 아님.
- 출처: [전자지급결제대행서비스 - 위키](https://ko.wikipedia.org/wiki/%EC%A0%84%EC%9E%90%EC%A7%80%EA%B8%89%EA%B2%B0%EC%A0%9C%EB%8C%80%ED%96%89%EC%84%9C%EB%B9%84%EC%8A%A4), [리걸타임즈 - 전자금융거래 제도](https://www.legaltimes.co.kr/news/articleView.html?idxno=51645).

**CF Workers 엣지 호스팅과 한국 결제의 실제 충돌 가능성**
- **충돌 없음 (일반 상점 기준)**: 상점 서버가 카드 데이터를 접촉하지 않고 PG-hosted 결제 흐름을 쓰는 한, CF Workers 엣지 실행은 규제상 블로커가 아니다.
- **주의점**:
  1. Toss 인바운드 IP 5블록(AWS ap-northeast-2 대역 + 자체 IP)에서 웹훅이 출발 — Workers는 IP 제한 없이 수신 가능하므로 문제 無.
  2. 상점 DB에 주문·회원 개인정보 저장 시 D1 리전(현재 자동 지역 선택)에 따라 해외 저장 가능 → 이용자 동의·처리방침 고지로 해결.
  3. 만약 추후 "본인확인"이나 "실명확인" 직접 처리 필요 시 추가 규제 개입 — 현재 타로/성격 서비스 범위엔 불필요.

### G. 6-Cell Feasibility Matrix

범례: **F** = Feasible · **FC** = Feasible with caveats · **NF** = Not feasible. LOC는 결제 모듈 신규 구축 어림치 (승인 API + 웹훅 수신 + 서명 검증 + idempotency + 주문/결제 상태 저장 + 최소 UI, 테스트 별도).

#### G-1. Toss × Rails on Kamal — **Feasible**
- **Verdict**: F. 한국 PG + 성숙 Rails 조합. 업계 레퍼런스 풍부(Toss Payments 공식 샘플, 다수 Rails/Django 사례).
- **Webhook 전략**: Rails 컨트롤러 `POST /webhooks/toss` + HMAC-SHA256 검증 모듈 (`OpenSSL::HMAC.digest`) + `webhook_events` 테이블(UNIQUE event_id). 10초 내 200 응답 → Solid Queue 비동기 후처리.
- **Constraints**: Toss 인바운드 IP 5블록을 Kamal 서버 방화벽에서 허용. Solid Queue로 후처리 시 동일 프로세스 내 처리이므로 지연 최소.
- **LOC 추정**: **~600-900 LOC** (모델 3개 + 컨트롤러 2개 + 서비스 2개 + 웹훅 핸들러 + 검증 로직 + RSpec 커버).
- **보안**: Rails credentials로 시크릿 키 관리, `Rack::Attack`으로 rate limit.

#### G-2. Toss × CF Workers+Hono — **Feasible with caveats**
- **Verdict**: FC. 기술적으로 완전 가능하나 공식 가이드 부재 → 자체 구현 책임.
- **Webhook 전략**: Hono 라우트 `app.post('/webhooks/toss', ...)` + Web Crypto API로 HMAC-SHA256 검증 (raw body는 `c.req.text()`). D1 `webhook_events` UNIQUE 제약으로 idempotency. 10초 제한은 Workers 기본 30초 CPU보다 여유 → 문제 無.
- **Constraints**:
  1. Toss 공식 Workers 예제 없음 — 자체 검증 코드 작성·테스트 필수.
  2. D1 단일 스레드 특성상 웹훅 폭주(예: 이벤트성 판촉) 시 처리량 bottleneck 가능 → Durable Objects 또는 Queues 조합 고려.
  3. 한국 사용자 대상 서비스에서 D1 리전을 선택할 수 없는 경우(자동 배치) 쓰기 지연이 사용자 체감에 영향 가능 — 결제 경로는 비동기라 대체로 무관.
- **LOC 추정**: **~500-800 LOC** (Hono 라우트 + TypeScript 타입 정의 + D1 스키마·쿼리 + Web Crypto 검증 + Vitest).
- **주의**: TypeScript + 수동 HMAC 구현의 오류 가능성 → `crypto.timingSafeEqual` 등가 구현 주의(Web Crypto엔 없으므로 수동 상수-시간 비교).

#### G-3. PortOne × Rails on Kamal — **Feasible**
- **Verdict**: F. PortOne Ruby SDK는 공식은 없으나 REST V2 API 직호출로 충분 (`Faraday`/`Net::HTTP`).
- **Webhook 전략**: Rails 컨트롤러 + Standard Webhooks 규격 검증 직접 구현 (JS/Python SDK와 동일 알고리즘 30~60 LOC).
- **Constraints**: Ruby 공식 SDK 미제공 → REST 직호출 + 자체 서명 검증. 단 Standard Webhooks는 공개 사양이라 난이도 낮음.
- **LOC 추정**: **~700-1,000 LOC** (PG 추상화 이점 활용 시 multi-PG 지원 포함).
- **이점**: PortOne 다중 PG 추상화로 토스 + KCP + 이니시스 전환이 런타임 설정 변경 수준 → 장기 유연성↑.

#### G-4. PortOne × CF Workers+Hono — **Feasible**
- **Verdict**: F. `@portone/server-sdk` 공식 JS SDK 존재 → Workers 런타임에서 바로 사용 가능성 높음 (ESM npm 패키지).
- **Webhook 전략**: SDK의 `verify` 함수 호출 + D1 idempotency. Standard Webhooks 규격이라 Hono 미들웨어 없이도 단순.
- **Constraints**: JS SDK의 Workers 런타임 공식 지원 문구는 명시 미확인 — 최초 도입 시 런타임 호환성 테스트 필요(1일 이내).
- **LOC 추정**: **~400-700 LOC** (JS SDK가 가장 많은 부분 처리).
- **이점**: PortOne 추상화 + Workers 엣지 지연 + TypeScript 타입 안전성 조합. **본 프로젝트 맥락에서 가장 균형 잡힌 조합**.

#### G-5. Stripe × Rails on Kamal — **Feasible with caveats**
- **Verdict**: FC. 기술은 완전 가능하나 **한국 법인 merchant 가입 경로 미확인**이 비즈니스 블로커.
- **Webhook 전략**: `stripe-ruby` gem (`Stripe::Webhook.construct_event`) — 성숙, 표준.
- **Constraints**:
  1. **서비스 주체가 한국 법인이면 Stripe 직접 가입 원칙적 불가** (2026-04 검색 기준). 해외 법인 설립 또는 BaaS 경유 필요.
  2. 한국 사용자 대상 KRW 결제는 NICEPay 파트너십 경유 → merchant는 비-한국 entity여야 함.
- **LOC 추정**: **~500-800 LOC** (Rails + stripe-ruby, Stripe Checkout 쓰면 프론트 단순).
- **PCI**: Stripe Checkout 호스팅 페이지 경로 → SAQ A.

#### G-6. Stripe × CF Workers+Hono — **Feasible (기술만) / FC (비즈니스)**
- **Verdict**: FC. 기술 조합은 **가장 문서화된 웹훅 경로** (Hono 공식 예제, CF 공식 블로그, 미들웨어 2개).
- **Webhook 전략**: `@nakanoaas/hono-stripe-webhook-middleware-lite` 또는 Hono 공식 예제. Stripe JS SDK Workers GA(v11.10.0+).
- **Constraints**: G-5와 동일한 한국 법인 가입 문제. 기술적 장애물은 전 조합 중 가장 낮음.
- **LOC 추정**: **~300-600 LOC** (미들웨어가 검증 자동화).

#### 요약 표

| PG × Stack | Verdict | LOC 어림 | 핵심 제약 |
|-----------|---------|----------|----------|
| Toss × Rails/Kamal | F | 600-900 | 인바운드 IP 방화벽 허용 |
| Toss × CF Workers | FC | 500-800 | 공식 예제 無 → 자체 구현 |
| PortOne × Rails/Kamal | F | 700-1,000 | Ruby SDK 無 (REST 직호출) |
| PortOne × CF Workers | F | 400-700 | JS SDK 런타임 호환 초기 검증 |
| Stripe × Rails/Kamal | FC | 500-800 | 한국 법인 가입 경로 미확정 |
| Stripe × CF Workers | FC | 300-600 | 상동 (기술은 최적) |

## Key Findings

**Critical**
- **K1. 기존 결제 코드 0 → 스택 선택 시점에서 결제 구현 경로가 자유롭게 결정된다.** 마이그레이션 관점에서 "결제 포팅 비용" 항목은 없다. (for P1/P4 참조)
- **K2. Stripe 단독은 한국 주체 서비스에 비적합 (2026-04).** Stripe Korea entity 부재. 해외 법인/BaaS 경유 없이는 Stripe-only 권고는 오판이다. Brief 5번 결정("한국 + 글로벌 병행")은 **Toss 또는 PortOne + Stripe(선택적 글로벌)** 이중 구조로 구체화되어야 한다.

**High**
- **K3. CF Workers에서 결제 웹훅 처리는 기술적으로 완전 가능.** CPU 30초(Paid, 최대 5분 증액), body 100MB, Hono 공식 Stripe 예제, PortOne 공식 JS SDK, Toss는 자체 HMAC-SHA256 (Web Crypto) 50 LOC. Brief Ideal Criteria #6의 "webhook·PCI-DSS·콜드스타트" 문제는 **모두 해소 가능**. (for P2)
- **K4. D1을 idempotency 스토어로 쓰는 패턴이 표준.** `UNIQUE(event_id)` 제약으로 중복 처리 차단. KV는 최종 일관성이라 부적합. (for P2)
- **K5. 한국 규제 블로커 없음 (PG-hosted 흐름 준수 시).** 전자금융거래법은 PG사에 적용되며, 일반 상점은 PG 경유로 규제 적용 대상 아님. 서버 지리적 위치 강제 조항 부재. 개인정보 국외 이전은 "동의·고지"로 해결 가능 영역.

**Medium**
- **K6. PortOne + CF Workers가 본 프로젝트 컨텍스트에서 가장 균형 조합.** 한국 PG 지원 + 공식 JS SDK + Standard Webhooks 규격 + 다중 PG 추상화로 전환 옵션 보존.
- **K7. PCI 스코프는 SAQ A가 디폴트 경로.** Flutter WebView → PG-hosted 결제창 사용 시 서버는 카드 데이터 미접촉. 단 2024+ ASV 분기 스캔 요구 존재.

**Low**
- **K8. Toss 인바운드 IP 5블록.** Kamal 방화벽 화이트리스트 운용 시만 의미. Workers는 해당 없음.
- **K9. CF Workers 콜드스타트 ~5-50ms.** 결제 웹훅 10초 허용에 영향 無.

## Recommendations

1. **1차 PG 선정은 Toss 또는 PortOne** (한국 사용자 우선이 Brief 5번 결정). Stripe는 글로벌 확장 시점에 병렬 도입.
2. **다중 PG 추상화 요구가 있으면 PortOne, 단일 PG 직결 + 최소 의존성이 우선이면 Toss**. 현 시점 서비스 규모(미구축)와 "간결 우선" 원칙 고려 시 **Toss 직결이 시작점으로 합리적**.
3. **스택 전환 시 결제가 CF 이점을 깎지 않는다**. 웹훅 처리·서명 검증·idempotency 모두 CF 환경에서 표준 패턴 존재. 결제가 "Rails 유지" 쪽 논거가 될 수 없음.
4. **Flutter WebView → PG 결제창 + 서버 승인 API + D1 idempotency** 패턴을 기본 아키텍처로. 이 패턴이 SAQ A 유지·규제 회피·기술 단순화를 동시 달성.
5. **개인정보 처리방침에 "Cloudflare 리전 국외 이전" 고지 + 가입 동의 체크박스** 반영 (D1/R2 리전이 국외일 때).

## References

| Source URL | Role |
|------------|------|
| https://developers.tosspayments.com/ | Toss 개발자센터 홈 |
| https://docs.tosspayments.com/guides/v2/webhook | Toss 웹훅 가이드 (재시도·타임아웃) |
| https://docs.tosspayments.com/reference/using-api/webhook-events | Toss 웹훅 이벤트 유형 |
| https://docs.tosspayments.com/reference/using-api/security | Toss 보안 (IP·TLS) |
| https://developers.portone.io/ | PortOne 개발자 문서 |
| https://developers.portone.io/opi/ko/integration/webhook/readme-v2?v=v2 | PortOne Webhook V2 (Standard Webhooks) |
| https://docs.stripe.com/payments/countries/korea | Stripe 한국 결제수단 |
| https://stripe.com/newsroom/news/tour-singapore-2024 | Stripe × NICEPay 파트너십 |
| https://docs.stripe.com/billing/subscriptions/kr-card | Stripe KRW 구독 |
| https://stripe.com/guides/pci-compliance | Stripe PCI-DSS 가이드 |
| https://hono.dev/examples/stripe-webhook | Hono Stripe webhook 공식 예제 |
| https://blog.cloudflare.com/announcing-stripe-support-in-workers/ | Stripe SDK Workers GA |
| https://github.com/nakanoasaservice/hono-stripe-webhook-middleware-lite | Hono Stripe webhook 경량 미들웨어 |
| https://jross.me/verifying-stripe-webhook-signatures-cloudflare-workers/ | Stripe + Workers HMAC 검증 블로그 |
| https://developers.cloudflare.com/workers/platform/limits/ | Workers 런타임 한도 |
| https://developers.cloudflare.com/workers/platform/pricing/ | Workers 요금 |
| https://developers.cloudflare.com/d1/platform/limits/ | D1 한도 |
| https://developers.cloudflare.com/durable-objects/platform/limits/ | Durable Objects 한도 |
| https://ko.wikipedia.org/wiki/%EC%A0%84%EC%9E%90%EC%A7%80%EA%B8%89%EA%B2%B0%EC%A0%9C%EB%8C%80%ED%96%89%EC%84%9C%EB%B9%84%EC%8A%A4 | 전자지급결제대행 정의 |
| https://www.legaltimes.co.kr/news/articleView.html?idxno=51645 | 전자금융거래 제도 개관 |
| https://www.linkedin.com/pulse/saq-simplified-2025-guide-easiest-pci-dss-compliance-path-uday-kumar-amilc | SAQ A (2025) 가이드 |
| https://community.cloudflare.com/t/does-cloudflare-alter-stripe-webhook-payloads-help-to-preserve-signature-integrity/786306 | CF가 웹훅 body 변조하는지 (결론: 일반적 無) |

## Communication Log
| # | Direction | Peer | Summary | Stage |
|---|-----------|------|---------|-------|
| 1 | → | P1 (current_rails_assets) | K1 공유: server/에 결제 관련 gem·모델·컨트롤러 0건 확인. 마이그 비용에서 "결제 포팅" 항목 제로. | Cycle 1 |
| 2 | → | P2 (cloudflare_stack) | K3/K4 공유: Workers CPU 30초(최대 5분 증액), body 100MB, D1 UNIQUE idempotency, Hono+Stripe 공식 예제·PortOne JS SDK — 웹훅 처리 구조적 블로커 無. | Cycle 1 |
| 3 | → | P4 (migration_cost) | LOC 어림치 6조합: 300-1,000 LOC. 결제가 스택 선택의 결정 요인이 아님(모두 실현 가능). | Cycle 2 |
| 4 | → | P5 (risk_recommendation) | K2 공유: Stripe Korea entity 부재(2026-04) — Stripe 단독 구성은 한국 주체 서비스에 적용 불가. 한국 규제상 CF Workers 사용 블로커 無. | Cycle 2 |
