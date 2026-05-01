---
id: "012"
type: research
title: "R5 — Toss 결제 7-stage 1차 출처 검증"
created: 2026-04-29
traces_brief: "001"
traces_scope: "007"
research_axis: "R5"
summary: >
  Toss 공식 docs 1차 출처 재검증 결과. (1) PAYMENT_STATUS_CHANGED·DEPOSIT_CALLBACK
  webhook은 Brief가 추정한 HMAC-SHA256 일괄 시그니처가 아니라 응답의 secret 필드
  단순 비교 모델, HMAC `tosspayments-webhook-signature`(v1: prefix, base64 두 값)는
  payout.changed/seller.changed 이벤트에 한정. (2) idempotency는 표준 헤더
  `Idempotency-Key` 사용, 최대 300자, 15일 유효 — D1 `UNIQUE(idempotency_key)` +
  `UNIQUE(event_id)` 이중 인덱스 권고. (3) 환불은 `POST /v1/payments/{paymentKey}/cancel`
  로 cancelAmount 부분/전체 분기, retry 정책 1·4·16·64·256·1024·4096분 지수,
  최대 7회·약 3일 19시간 윈도우. (4) 결제창은 Toss 호스팅 iframe(또는 모바일
  full-page redirect), card PAN은 Toss 도메인 안에서만 입력 — 가맹점 서버는
  paymentKey/orderId/amount만 수신하므로 SAQ-A 영역에 머문다. CF Workers
  Web Crypto는 HMAC-SHA256 importKey/sign/verify·timingSafeEqual 모두 지원.
keywords: [toss-payments, webhook, hmac, idempotency, refund, pci-dss, cloudflare-workers, web-crypto]
---

## Research Overview

Brief In Scope 9 (결제 7-stage)와 M2(Toss webhook HMAC 1차 출처 재검증)에 응답한다.
조사 결과 **Brief의 핵심 가정 1개가 부분적으로 어긋난다**: Toss는 모든 webhook에
HMAC-SHA256 시그니처를 강제하지 않는다. 일반 결제 이벤트는 응답 body에 포함된
`secret` 비교 모델, HMAC v1 시그니처는 정산(payouts) 계열 이벤트 전용이다. 이 차이는
Workers verify 코드 경로 분기를 요구하므로 Cycle 7 구현 계획에 직접 영향을 준다.

조사는 1차 출처(docs.tosspayments.com 한국어/영문) + Cloudflare Workers 공식
runtime docs로 한정했다. 보조 자료(블로그·SDK 저장소)는 1차 출처와 일치할 때만
인용한다. 모든 인용은 References 섹션에 URL을 남긴다.

`server/Gemfile`(Gemfile 50줄 head 확인)·`server/app/models/`(13개 모델, alert/assessment/
profile/personality_type/question/response/user 등)에 결제 관련 gem·모델이 0개인 것을
확인했다. CF Workers rebuild가 결제 도메인을 greenfield로 시작한다는 Brief 전제
재검증 완료.

## 7-stage 시퀀스 다이어그램

```
Flutter WebView                Workers (Hono)              Toss Payments
─────────────────────────────────────────────────────────────────────────
[1] intent
  POST /api/payments/intent ──▶ orders 행 생성 (READY)
                                amount, orderId, customerKey 응답
                                ◀── { orderId, amount }

[2] widget(client) hosting
  TossPayments(clientKey)
   .widgets({customerKey})
   .renderPaymentMethods(...)        (Toss 호스팅 iframe — PAN 입력)
   .requestPayment({successUrl})
                                                          [card data
                                                           Toss 도메인
                                                           내부에서만
                                                           처리]

[3] confirm  (successUrl redirect: ?paymentKey&orderId&amount)
  GET successUrl ─────────────▶ Workers
                                Authorization: Basic b64(secretKey:)
                                Idempotency-Key: <uuid>
                                POST /v1/payments/confirm ─────▶
                                                          승인 처리
                                ◀── Payment{ status:DONE, secret, ... }
                                payments 행 INSERT
                                  (idempotency_key UNIQUE)

[4] webhook (비동기·중복 가능)
                                ◀── POST /webhook/toss
                                    PAYMENT_STATUS_CHANGED
                                    body.data.secret == 저장된 secret?
                                    UNIQUE(transmission_id) → 중복 차단
                                    상태 sync, 200 응답 (10s 이내)

[5] refund / cancel
  POST /api/payments/refund ──▶ Workers
                                Idempotency-Key: <uuid>
                                POST /v1/payments/{paymentKey}/cancel ▶
                                  body: { cancelReason, cancelAmount? }
                                ◀── Payment{ cancels:[...] }
                                cancels 행 INSERT

[6] retry (webhook 미수신·5xx)
                                ◀── PAYMENT_STATUS_CHANGED (재시도)
                                재시도 헤더: tosspayments-webhook-
                                  transmission-retried-count
                                간격: 1, 4, 16, 64, 256, 1024, 4096 분
                                최대 7회 / 약 3일 19시간

[7] receipt / E2E
  GET /api/payments/{id}/receipt
                                ─── 가맹점 자체 영수증 발급 또는
                                    cash-receipt API 위임
                                    (POST /v1/cash-receipts)
  E2E: Toss 테스트 모드 시나리오
       (DONE, CANCELED, EXPIRED, 가상계좌 DEPOSIT_CALLBACK)
```

## Q1 webhook HMAC-SHA256 명세 — Brief 가정 정정

### 1차 출처 결론

Toss는 webhook 검증을 **두 모델**로 운영한다.

**모델 A — secret 필드 매칭** (PAYMENT_STATUS_CHANGED, DEPOSIT_CALLBACK,
CANCEL_STATUS_CHANGED, BILLING_DELETED 등 결제 코어 이벤트):

- `POST /v1/payments/confirm` 또는 가상계좌 발급 응답의 `Payment.secret` 값을
  가맹점 DB에 저장.
- webhook body의 `secret` 또는 `data.secret`이 저장된 값과 동일한지 비교.
- 일치 시 신뢰. (가상계좌 글: "두 값이 같다면 토스페이먼츠에서 보낸 이벤트가 맞고
  믿을 수 있는 정보예요" — virtual-account-webhook docs.tosspayments.com)
- HMAC 키·헤더 시그니처를 **사용하지 않는다**.

**모델 B — HMAC-SHA256 v1 시그니처** (payout.changed, seller.changed):

- 헤더 `tosspayments-webhook-signature`: 형식 `v1:<base64hash>,<base64hash>`
  (값이 두 개인 이유 = 시크릿 회전 윈도우 동안 신·구 시크릿 모두로 서명).
- 서명 입력: `"{WEBHOOK_PAYLOAD}:{tosspayments-webhook-transmission-time}"`.
- 알고리즘: HMAC-SHA256, security key는 가맹점 측 발급.
- 검증: 가맹점이 동일 입력에 동일 알고리즘으로 hash → header의 `v1:` 뒤
  두 값(base64)을 디코드해 둘 중 하나와 일치하면 통과.
- 시크릿 회전: 두 값을 동시에 보내는 시그니처 디자인 자체가 **회전 시 신·구
  키가 동시 유효한 윈도우**를 의미한다(공식 문구 명시). 별도 회전 API 노출은
  문서화되지 않음 — 회전은 가맹점 콘솔에서 수동 발급 후 점진 교체.

### 공통 헤더 (모든 webhook)

| 헤더 | 의미 |
|------|------|
| `tosspayments-webhook-transmission-time` | ISO 시각, 모델 B 서명 입력에 포함 |
| `tosspayments-webhook-transmission-id` | 전송 단위 고유 ID — **idempotency anchor** |
| `tosspayments-webhook-transmission-retried-count` | 재시도 횟수 |
| `tosspayments-webhook-signature` | 모델 B 이벤트에서만 존재 (`v1:...`) |

### Brief 가정 차이

Brief In Scope 9.3은 "webhook 검증 (HMAC-SHA256, Toss 공식 docs 1차 출처
재확인 필수 — M2)" 으로 표현했다. 1차 출처 결과:

- **PAYMENT_STATUS_CHANGED는 HMAC이 아니다.** secret 비교가 표준.
- **HMAC-SHA256 verify 코드는 payouts 도입 시점에만 필요하다.** 본 phase는
  결제 코어이므로 HMAC verify 모듈은 향후 정산 위탁 시 도입.
- **idempotency 키 = `tosspayments-webhook-transmission-id`** (Brief가 막연히
  부른 `event_id`의 정확한 명칭).

### Workers verify 의사코드 (모델 A · 모델 B 분기)

```ts
// app/routes/api/webhook/toss.ts
import { timingSafeEqual } from 'cloudflare:workers'

export const onRequestPost = async ({ request, env }: Ctx) => {
  const tid  = request.headers.get('tosspayments-webhook-transmission-id')
  const ttime = request.headers.get('tosspayments-webhook-transmission-time')
  const sig   = request.headers.get('tosspayments-webhook-signature')
  const raw   = await request.text()

  // [1] D1 멱등성 — 어떤 모델이든 적용
  const seen = await env.DB.prepare(
    'INSERT OR IGNORE INTO webhook_events (transmission_id, received_at) VALUES (?, ?)'
  ).bind(tid, Date.now()).run()
  if (seen.meta.changes === 0) return new Response('duplicate', { status: 200 })

  // [2] 분기
  if (sig) {
    // 모델 B (payouts/seller)
    const key = await crypto.subtle.importKey(
      'raw', new TextEncoder().encode(env.TOSS_WEBHOOK_SECRET),
      { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']
    )
    const computed = new Uint8Array(await crypto.subtle.sign(
      'HMAC', key, new TextEncoder().encode(`${raw}:${ttime}`)
    ))
    const [, payload] = sig.split('v1:')
    const candidates = payload.split(',').map(b => Uint8Array.from(atob(b), c => c.charCodeAt(0)))
    const ok = candidates.some(c => c.length === computed.length && timingSafeEqual(c, computed))
    if (!ok) return new Response('bad signature', { status: 401 })
  } else {
    // 모델 A (PAYMENT_STATUS_CHANGED, DEPOSIT_CALLBACK, ...)
    const body = JSON.parse(raw)
    const incoming = body.secret ?? body?.data?.secret
    const stored   = await env.DB.prepare(
      'SELECT toss_secret FROM payments WHERE order_id = ?'
    ).bind(body.orderId ?? body.data?.orderId).first<{ toss_secret: string }>()
    if (!stored || incoming !== stored.toss_secret) {
      return new Response('bad secret', { status: 401 })
    }
  }

  // [3] 처리 (status sync) — ctx.waitUntil 권장
  await applyStatusUpdate(raw, env)
  return new Response('ok', { status: 200 })
}
```

핵심: **모델 A에서 `crypto.subtle.timingSafeEqual` 사용 권장** (단순 `===`도
secret이 entropy 충분한 난수이면 timing leak 위협이 낮으나 Workers는 표준
지원하므로 사용한다).

## Q2 idempotency key — 정확한 필드 명세

### Toss 측 (가맹점 → Toss 호출)

- **헤더**: `Idempotency-Key`
- **최대 길이**: 300자
- **유효 기간**: 15일
- **적용 API**: 모든 POST API. **특히 `POST /v1/payments/{paymentKey}/cancel`은
  필수**. confirm·billing·virtual-accounts에도 권장.
- **동작**: 동일 키 재요청 시 동일 응답 반환 (오류 응답이라도). 즉 retry
  안전성을 PG가 보장.

### 가맹점 측 (Toss → Workers webhook 수신)

- **유일 식별자**: `tosspayments-webhook-transmission-id` 헤더.
- D1 스키마 권고:
  ```sql
  CREATE TABLE webhook_events (
    transmission_id TEXT PRIMARY KEY,
    received_at     INTEGER NOT NULL,
    event_type      TEXT,
    payload         TEXT,
    processed_at    INTEGER
  );
  CREATE INDEX idx_webhook_events_received ON webhook_events(received_at);
  ```
  PRIMARY KEY = transmission_id로 중복 시 INSERT OR IGNORE → meta.changes=0 확인
  하면 즉시 200 반환 (Toss 재시도 윈도우 내 멱등 보장).

### 결제 단계 멱등성 (clientside double-submit 방어)

- **Cancel API 호출**: 가맹점 측에서 생성한 `Idempotency-Key`(uuid v4)를 헤더로
  넣고, 동일 키를 D1 `payment_cancels(idempotency_key UNIQUE)`에 INSERT 시도.
- **Confirm API 호출**: orderId가 자연 unique이지만, 동시 요청 race 방어를 위해
  `payments(order_id UNIQUE)` + `Idempotency-Key` 헤더 동시 적용.

```sql
CREATE TABLE payments (
  id              INTEGER PRIMARY KEY,
  order_id        TEXT UNIQUE NOT NULL,           -- 가맹점 자연 unique
  payment_key     TEXT UNIQUE,                    -- Toss paymentKey
  toss_secret     TEXT,                           -- 모델 A 검증용
  status          TEXT NOT NULL,
  amount          INTEGER NOT NULL,
  idempotency_key TEXT UNIQUE NOT NULL,           -- confirm 호출 시 사용
  created_at      INTEGER NOT NULL
);
CREATE TABLE payment_cancels (
  id              INTEGER PRIMARY KEY,
  payment_id      INTEGER NOT NULL REFERENCES payments(id),
  idempotency_key TEXT UNIQUE NOT NULL,
  cancel_amount   INTEGER NOT NULL,
  reason          TEXT,
  created_at      INTEGER NOT NULL
);
```

이중 키 제약(`order_id` + `idempotency_key` + `payment_key`)으로 PG·DB 양측에서
중복을 차단한다.

## Q3 환불·취소 흐름 + webhook event + 재시도 정책

### Refund/Cancel API

- 엔드포인트: `POST /v1/payments/{paymentKey}/cancel`
- Body 필수: `cancelReason` (string ≤200).
- Body 선택:
  - `cancelAmount` — 미지정 시 전체 취소, 지정 시 부분 환불.
  - `refundReceiveAccount` (가상계좌 환불 필수): `bank`, `accountNumber`, `holderName`.
  - `taxFreeAmount` — 부분 면세 환불.
- 헤더: `Idempotency-Key` 권고(공식 가이드: refundableAmount deprecated → "Use
  IDEMPOTENCY_KEY in request header to cancel payments safely").
- 응답: Payment 객체의 `cancels` 배열에 cancel 트랜잭션 추가.

### 환불 관련 webhook 이벤트

- 일반 결제 수단(카드/계좌이체/휴대폰): `PAYMENT_STATUS_CHANGED`로 status 전이
  반영(DONE → PARTIAL_CANCELED / CANCELED). 별도 cancel 전용 이벤트 없음.
- 해외 간편결제: `CANCEL_STATUS_CHANGED` (별도 이벤트, data: Cancel object).
- 가상계좌 입금/환불: `DEPOSIT_CALLBACK`.

### 재시도 정책 (1차 출처 확정)

- **2xx 응답 윈도우**: 10초.
- **재시도**: 최대 **7회**, 누적 약 **3일 19시간**.
- **간격**: 1, 4, 16, 64, 256, 1024, 4096 (분, 4의 거듭제곱).
- **함의**:
  - Workers 핸들러는 10초 안에 200 반환해야 함 → 무거운 작업은
    `ctx.waitUntil(...)` 또는 Queues 위임.
  - retry 윈도우 내 동일 transmission_id 다회 도착 가능 → D1 PRIMARY KEY 충돌로
    멱등 보장.
  - 7회 모두 실패 시 가맹점 콘솔에서 수동 재발송 또는 `GET /v1/payments/orders/{orderId}`
    polling 보상.

### 보상 트랜잭션

```
status sync 실패(Workers→D1 update 실패) →
  background: ctx.waitUntil(retryUpdateWithBackoff(transmissionId)) →
  최종 실패 시 alerts 테이블 INSERT → admin 대시보드 표시
```

## Q4 PCI 비접촉 구조 — Toss Widget hosting + Flutter WebView

### 데이터 흐름 (1차 출처 확정)

1. **Flutter WebView**가 Workers가 발행한 결제 페이지(자체 호스팅) 또는 Toss
   호스팅 결제창을 로드.
2. 페이지가 `TossPayments(clientKey).widgets({customerKey}).renderPaymentMethods(...)`로
   결제 수단 UI를 렌더 → **Toss 도메인 iframe**(PC) 또는 **Toss 도메인 redirect**
   (모바일 기본).
3. 사용자는 **Toss 도메인 안에서만** 카드 PAN/유효기간/CVC를 입력.
4. 인증/3D-Secure 완료 후 Toss는 `successUrl`로 redirect, query에 `paymentKey`,
   `orderId`, `amount`만 전달.
5. Workers의 `/api/payments/confirm`이 `secretKey`로 `POST /v1/payments/confirm`
   호출 → Toss가 승인 처리. 가맹점 서버는 PAN을 절대 받지 않는다.

> 1차 출처 인용 (sdk/v2/js): "Card data remains isolated within Toss Payments'
> hosted payment window. Merchant servers never directly receive sensitive
> payment information — only payment confirmation data flows back after
> successful authorization via the success URL containing amount, orderId,
> and paymentKey parameters."

### Flutter WebView 추가 고려사항

- **clientKey**(공개)와 **secretKey**(서버 전용) 분리. clientKey만 mobile/Web에
  배포 가능. secretKey는 Workers 환경변수(M6).
- WebView 내 JavaScript bridge로 결제 결과를 Flutter로 통보 후 native에서
  Workers `/api/payments/{id}` polling으로 최종 상태 확정 권고 (성공 redirect
  유실 방지).
- iOS 추후 도입 시: WKWebView + `WKWebViewConfiguration.allowsInlineMediaPlayback`
  무관, 결제 입력 정상 동작.

### 키 / 시크릿 매핑

| 키 | 위치 | 노출 |
|----|------|------|
| `clientKey` (위젯 연동 키) | Flutter WebView · Workers public route | 공개 |
| `secretKey` (위젯 연동 키) | Workers env (`TOSS_SECRET_KEY`) | 비공개 |
| `WEBHOOK_SECRET` (모델 B 전용) | Workers env (`TOSS_WEBHOOK_SECRET`) | 비공개·회전 가능 |
| 결제별 `secret` 필드 (모델 A) | D1 `payments.toss_secret` (해시 X, 평문 OK — 응답 자체로 받은 값) | DB 내부 |

## Web Crypto AES/HMAC 호환성 검증 (Workers 환경)

`developers.cloudflare.com/workers/runtime-apis/web-crypto/` 1차 출처 확인:

| 알고리즘 | importKey | sign | verify | 용도 |
|---------|-----------|------|--------|------|
| HMAC-SHA256 | O | O | O | webhook 모델 B 검증, 자체 서명 토큰 |
| AES-GCM | O | encrypt/decrypt | — | secret 회전 시 KMS-less 봉인 (선택) |
| SHA-256 digest | (subtle.digest) | — | — | secret 비교용 hash |

**timingSafeEqual**(Workers 비표준 확장)도 제공 — 모델 A의 secret 단순 비교에서도
사용 가능.

**결론**: Brief의 "Web Crypto AES/HMAC 호환" 가정은 1차 출처에서 완전히 충족된다.
HMAC-SHA256 import/sign/verify가 모두 네이티브 빠른 경로로 동작한다.

## 한국 PCI-DSS 컨텍스트 (CF Workers 카드 정보 비접촉 정합성)

### 핵심 결론

Toss Payments hosted widget을 사용하는 한, **본 시스템은 SAQ-A 영역**에 머문다:

- **PAN을 저장·처리·전송하지 않음** — Toss 도메인 iframe/redirect에서 입력, Toss
  서버에서 vault.
- **Workers는 token(`paymentKey`) + 비민감 메타(`orderId`, `amount`)만 다룸** —
  CDE(Cardholder Data Environment) 범위 외부.
- 결과적으로 SAQ-A 자가검증 항목(약 22개) 수준의 컴플라이언스. SAQ-D(약 250+
  항목, full DSS) 불필요.

### Toss측 컴플라이언스

Toss Payments 자체는 **PCI-DSS Level 1 + ISMS 인증** 보유 (blog.toss.im/article/
tosspayments-security). 가맹점은 Toss의 인증을 의존(파생 신뢰)하므로 Workers
인프라가 별도 PCI 인증을 받을 필요 없다.

### CF Workers 정합성 위험 제로 항목

- 카드 정보 메모리 보관 X (Workers는 stateless, request-scoped).
- 카드 정보 로그 기록 X (paymentKey만 로깅).
- TLS 1.2+ 자동 적용 (CF 인프라).

### CF Workers 정합성 추가 점검 필요 항목

- **secretKey·WEBHOOK_SECRET 회전 정책 문서화** — Brief M6과 연결.
- **wrangler.toml의 vars vs secret 구분** — secretKey는 반드시 `wrangler secret put`,
  vars 평문 금지.
- **Wrangler tail / dashboard 로그에서 paymentKey 외 민감 정보 미노출 확인**.

## Cross-Analysis

### Brief 가정 vs 1차 출처 (정합성 표)

| Brief In Scope 9.3 추정 | 1차 출처 확정 | 영향 |
|------------------------|--------------|------|
| webhook = HMAC-SHA256 일괄 | 모델 A(secret 비교) + 모델 B(HMAC v1) 분기 | Workers verify 코드 분기 신설 |
| event_id로 idempotency | `tosspayments-webhook-transmission-id` | D1 컬럼명 명확화 |
| Web Crypto HMAC 호환 | 완전 호환 (timingSafeEqual 추가) | 변경 없음 |
| 결제창 호스팅 책임 | 100% Toss 도메인 iframe/redirect | SAQ-A 확정 |
| 환불 webhook 별도 이벤트 | 일반은 PAYMENT_STATUS_CHANGED 재발화 | 핸들러 단일화 가능 |

### R1·R3·R4 와의 결합

- **R1(Drizzle)**: `payments`, `payment_cancels`, `webhook_events` 스키마는
  Drizzle ORM으로 관리. `transmission_id` PRIMARY KEY로 unique 보장.
- **R3(Admin)**: 결제 실패·webhook 미수신 alert는 admin 대시보드에서 가시화.
  `alerts` 테이블에 INSERT.
- **R4(BetterAuth)**: 결제는 인증된 user 컨텍스트 필요(Brief Dependency Map 4·5→7).
  `customerKey`는 BetterAuth user.id를 결정적으로 매핑.

### Cycle 7 (Payment) file plan 초안

```
lib/payment/toss/
  client.ts              # fetch wrapper (secretKey + Idempotency-Key)
  confirm.ts             # POST /v1/payments/confirm
  cancel.ts              # POST /v1/payments/{paymentKey}/cancel
  webhook-verify.ts      # 모델 A (secret 비교) + 모델 B (HMAC v1) 분기
  types.ts               # Payment, Cancel, WebhookEvent 타입
  errors.ts              # TossApiError 매핑
app/routes/api/payment/
  intent.ts              # POST /api/payments/intent
  confirm.ts             # GET successUrl handler → confirm 호출
  refund.ts              # POST /api/payments/refund
app/routes/webhook/
  toss.ts                # POST /webhook/toss (분기 + D1 멱등)
tests/payment/
  confirm.test.ts
  refund.test.ts
  webhook.test.ts        # 모델 A·B 분기 커버
  e2e.test.ts            # Toss 테스트 모드
```

7개 모듈 (Scope 174줄 "≥7 modules" 충족).

## Comprehensive Conclusion

### R5-F1 — webhook 검증 코드 경로는 두 갈래로 분기한다
일반 결제 이벤트(PAYMENT_STATUS_CHANGED 등)는 응답 secret 단순 비교, payouts·
seller 이벤트는 HMAC-SHA256 v1 시그니처 검증. **현 phase에서는 모델 A만 구현
하고 모델 B는 정산 위탁 도입 시점까지 stub로 둔다.** 단 verify-stub의 시그니처
와 분기 테스트는 Cycle 7에서 작성.

### R5-F2 — idempotency는 양방향이다
가맹점→Toss는 `Idempotency-Key`(300자, 15일), Toss→가맹점은 `tosspayments-webhook-
transmission-id`. 두 키 모두 D1 UNIQUE 인덱스로 강제. cancel API는 idempotency
헤더 **필수**.

### R5-F3 — 환불은 단일 엔드포인트, 부분/전체 분기는 cancelAmount
별도 refund API 없음. cancel 전용 webhook 이벤트도 일반 결제에는 없으며 status
sync로 처리. 가상계좌 환불은 `refundReceiveAccount` 필수.

### R5-F4 — webhook 처리는 10초 안에 끝내고 무거운 작업은 waitUntil
재시도 윈도우(약 3일 19시간)는 충분히 길지만, 핸들러 자체는 10초 / 200 반환을
지켜야 한다. Workers `ctx.waitUntil`이 표준 패턴.

### R5-F5 — PAN은 Workers를 절대 통과하지 않는다 (SAQ-A)
Toss hosted widget이 카드 입력을 봉인하므로 본 시스템은 PCI-DSS SAQ-A 영역.
별도 PCI 인증·HSM·card vault 불필요. 단 secretKey/WEBHOOK_SECRET의 wrangler
secret 관리는 M6 Cycle에서 별도 설계.

### R5-F6 — Web Crypto는 본 phase 모든 요구를 충족
HMAC-SHA256 import/sign/verify, timingSafeEqual, AES-GCM 모두 네이티브.
nodejs_compat 불필요.

### R5-F7 — 7-stage E2E 테스트는 Toss 테스트 모드 + Workers Vitest
intent/confirm/webhook(모델 A)/refund(부분·전체)/retry(transmission-id 중복)/
receipt/E2E 7개 시나리오 전수 커버. Toss 테스트 카드(4242로 시작·VIRTUAL
ACCOUNT 시뮬레이션)로 실 통신 검증.

## Open Questions

1. **모델 B(payouts/seller) 시크릿 회전의 윈도우 길이는 가맹점 측이 정의할 수
   있는가, 콘솔 정책으로 고정인가?** — 1차 출처에 명시 없음. 정산 위탁 도입 시
   tech support 문의 필요.
2. **Idempotency-Key 15일 만료 후 동일 키 재사용 시 동작?** — 정확한 신규 처리
   동작은 명시 없음. 가맹점 측 키 생성 시점부터 15일 카운트 가정 안전.
3. **`successUrl` redirect가 모바일 브라우저 외부로 빠지는 케이스(Flutter
   WebView 외부 launcher)에서의 결제 결과 동기화** — Cycle 7 implementation에서
   `GET /v1/payments/orders/{orderId}` polling 보조 패턴 검증 필요.

## References (1차 출처 — Brief M2 만족 증거)

| # | URL | 추출 정보 |
|---|-----|-----------|
| 1 | https://docs.tosspayments.com/reference | 모든 코어 API 엔드포인트 (confirm, cancel, virtual-accounts, billing, transactions, settlements, cash-receipts), Authorization Basic 형식, Idempotency-Key 권고 |
| 2 | https://docs.tosspayments.com/guides/v2/webhook | webhook 이벤트 9종, 재시도 정책 (1·4·16·64·256·1024·4096분 / 7회 / 3일19시간), 10초 응답 윈도우 |
| 3 | https://docs.tosspayments.com/reference/using-api/webhook-events | 공통 헤더 4종 (transmission-time/id/retried-count/signature), 모델 B(payouts/seller) HMAC v1 형식, 모델 A 페이로드 스키마 (PAYMENT_STATUS_CHANGED, DEPOSIT_CALLBACK 등) |
| 4 | https://docs.tosspayments.com/blog/virtual-account-webhook | DEPOSIT_CALLBACK secret 비교 검증 (1차 출처 한국어 인용 확보) |
| 5 | https://docs.tosspayments.com/en/api-guide | Idempotency-Key 명세 (300자, 15일, cancel 권고), Authorization 형식, successUrl/failUrl flow |
| 6 | https://docs.tosspayments.com/sdk/v2/js | TossPayments(clientKey) 초기화, widgets() / setAmount() / requestPayment(), iframe 호스팅 모델, 카드 데이터 격리 명시 인용 |
| 7 | https://blog.toss.im/article/tosspayments-security | Toss Payments PCI-DSS Level 1 + ISMS 인증 |
| 8 | https://developers.cloudflare.com/workers/runtime-apis/web-crypto/ | HMAC-SHA256, AES-GCM, timingSafeEqual 지원 (Workers runtime 1차 출처) |
| 9 | https://developers.cloudflare.com/workers/examples/signing-requests/ | Workers HMAC-SHA256 verify 패턴 |

추가 보조 자료:
- https://docs.tosspayments.com/resources/faq — 일반 FAQ (보조)
- https://pages.tosspayments.com/terms/homepage/privacy/policy-240216/ — 개인정보
  처리방침 (보조)

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 25s | 43455 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 25s |
| Total Tokens | 43455 |
| Input Tokens | 6 |
| Output Tokens | 1821 |
| Cache Read | 0 |
| Cache Creation | 41628 |
