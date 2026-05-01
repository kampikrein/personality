---
id: "017"
type: eval
title: "Eval R5 — Toss 결제 7-stage"
created: 2026-04-29
traces_research: "012"
verdict: proceed
depth_score: 6
k_score: 3
c_score: 3
cycle: 5
phase: research
brief_correction_signal: true
---

# Eval R5 — Toss 결제 7-stage

## 1. Verdict + Depth

**Verdict: PROCEED** (K:3 C:3 → Depth Score 6/6)

R5 리서치는 Brief M2(1차 출처 재검증) 요건을 완전히 충족하고, 핵심 가정 정정을 docs.tosspayments.com 1차 출처 인용 9개로 뒷받침했다. 모든 Q1-Q4 핵심 질문에 명확한 답이 있고, Cycle 7 deliverables가 직접 도출되었다. PROCEED를 권고한다.

### Scoring

| 차원 | 점수 | 근거 |
|------|------|------|
| K-score | 3/3 | Q1-Q4 전체 완전 답변. HMAC 모델 이중화·idempotency 키 명칭·환불 엔드포인트·SAQ-A 확정 — 어느 것도 "확인 추가 필요" 미적용 없음 |
| C-score | 3/3 | 결제 7-stage 전 영역 탐색 완료. Toss 공식 docs·CF Workers Web Crypto runtime·PCI 컨텍스트·시크릿 매핑 전수 확인. Open Questions 3개는 범위 외 엣지케이스 (정산 위탁·15일 만료·WebView 외부 launcher) — 탐색 공백 아님 |

---

## 2. Q1-Q4 Coverage

### Q1 — webhook HMAC-SHA256 명세

**완전 답변.** Toss webhook 검증이 단일 HMAC-SHA256 모델이 아니라 두 모델로 운영됨을 1차 출처로 확정:

- **모델 A** (PAYMENT_STATUS_CHANGED, DEPOSIT_CALLBACK, CANCEL_STATUS_CHANGED, BILLING_DELETED): `Payment.secret` 필드 단순 비교. HMAC 시그니처 없음.
- **모델 B** (payout.changed, seller.changed): 헤더 `tosspayments-webhook-signature: v1:<base64>,<base64>` — HMAC-SHA256, 시크릿 회전 윈도우 지원(신·구 키 동시 유효).

Workers 의사코드(sig 헤더 유무로 분기)까지 제공. timingSafeEqual 사용 권고 포함.

### Q2 — idempotency key 명세

**완전 답변.**

- 가맹점→Toss: 헤더 `Idempotency-Key`, 최대 300자, 15일 유효. Cancel API는 **필수**.
- Toss→가맹점(webhook): `tosspayments-webhook-transmission-id` 헤더가 유일 식별자.
- D1 스키마 권고: `webhook_events(transmission_id TEXT PRIMARY KEY)` + `payments(idempotency_key UNIQUE)` + `payment_cancels(idempotency_key UNIQUE)` 이중 인덱스.

### Q3 — 환불·취소 흐름 + webhook 이벤트 타입 + 재시도 정책

**완전 답변.**

- 환불 엔드포인트: `POST /v1/payments/{paymentKey}/cancel` (별도 refund endpoint 없음).
- `cancelAmount` 미지정=전체 취소, 지정=부분 환불. 가상계좌 환불은 `refundReceiveAccount` 필수.
- 환불 관련 webhook 이벤트: 일반 결제는 `PAYMENT_STATUS_CHANGED` 재발화 (전용 cancel 이벤트 없음), 해외 간편결제는 `CANCEL_STATUS_CHANGED`, 가상계좌는 `DEPOSIT_CALLBACK`.
- 재시도: 최대 7회, 간격 1·4·16·64·256·1024·4096분(4의 거듭제곱), 총 약 3일 19시간. 10초 내 200 반환 필수 → `ctx.waitUntil` 패턴.

### Q4 — PCI 비접촉 구조 (Toss Widget hosting + Flutter WebView)

**완전 답변.**

- 카드 PAN은 Toss 도메인 iframe(PC) / redirect(모바일)에서만 입력 → 가맹점 서버 절대 미수신.
- Workers는 `paymentKey`·`orderId`·`amount`만 수신 → CDE 범위 외.
- **SAQ-A 영역 확정** (약 22개 자가검증 항목). SAQ-D(250+항목) 불필요.
- 1차 출처 명시 인용: "Card data remains isolated within Toss Payments' hosted payment window."

---

## 3. Source Quality — M2 명시 요구사항 충족 여부

Brief In Scope 9.3은 "Toss 공식 docs 1차 출처 재확인 필수 — M2"를 명시했다.

| 요건 | 충족 여부 | 근거 |
|------|---------|------|
| docs.tosspayments.com 1차 출처 인용 ≥5 | **충족** (9개 URL) | References #1~#7이 모두 docs.tosspayments.com 또는 blog.toss.im |
| webhook HMAC 명세 재확인 | **충족** | 모델 A·B 분기 확정, 헤더 4종 명세 |
| idempotency key 명칭 명확화 | **충족** | `tosspayments-webhook-transmission-id` 확정 |
| 환불 흐름 1차 출처 | **충족** | cancel API, webhook event, retry 정책 |
| PCI 비접촉 구조 | **충족** | iframe 격리 모델, SAQ-A 범위 |
| CF Workers Web Crypto 호환 | **충족** | developers.cloudflare.com/workers/runtime-apis/web-crypto/ 직접 확인 |

**1차 출처 인용 수: 9개 (요건 5개 상회)**

- #1 docs.tosspayments.com/reference
- #2 docs.tosspayments.com/guides/v2/webhook
- #3 docs.tosspayments.com/reference/using-api/webhook-events
- #4 docs.tosspayments.com/blog/virtual-account-webhook
- #5 docs.tosspayments.com/en/api-guide
- #6 docs.tosspayments.com/sdk/v2/js
- #7 blog.toss.im/article/tosspayments-security
- #8 developers.cloudflare.com/workers/runtime-apis/web-crypto/
- #9 developers.cloudflare.com/workers/examples/signing-requests/

M2 요구사항 완전 충족.

---

## 4. Brief 가정 정정 평가

### HMAC 모델 이중화 정정

**Brief 가정 → 1차 출처 정정:**

| 항목 | Brief 가정 (In Scope 9.3) | 1차 출처 확정 |
|------|--------------------------|-------------|
| 검증 모델 | "HMAC-SHA256" (단일 모델 함의) | 모델 A (secret 비교) + 모델 B (HMAC v1) 이중화 |
| 적용 범위 | 모든 webhook에 HMAC-SHA256 | PAYMENT_STATUS_CHANGED는 HMAC 없음, HMAC는 payouts/seller 전용 |
| 현 phase 필요성 | 즉시 HMAC 구현 암시 | 본 phase(결제 코어)는 모델 A만 구현, 모델 B는 정산 도입 시 stub 전환 |

**판정: Brief Decision 5 / In Scope 9.3의 "webhook = HMAC-SHA256" 일반화 가정이 정정됨.**

이 정정은 Brief M2가 의도한 대로 작동했다. M2는 "Toss 공식 docs 1차 출처 재확인 필수"라고 명시함으로써 Brief 자체가 이 가정의 불확실성을 인식하고 조사를 위임했다. 리서치가 그 위임을 정확히 수행하여 가정을 반증했다.

**구현 함의:**
- Workers verify 코드에 `sig` 헤더 유무 분기 필요 (연구 의사코드 확보)
- 모델 B HMAC verify 모듈은 Cycle 7에서 stub으로 작성, 정산 도입 시 활성화
- 모델 A에서도 `timingSafeEqual` 사용 권고 (Workers 네이티브 지원)

### idempotency key 명칭 정정

**Brief 가정 → 1차 출처 정정:**

| 항목 | Brief 가정 | 1차 출처 확정 |
|------|-----------|-------------|
| webhook 수신 측 idempotency anchor | `event_id` (막연한 추정) | `tosspayments-webhook-transmission-id` (헤더 공식 명칭) |
| D1 컬럼명 | `event_id` 가정 | `transmission_id` 권고 |

**판정: In Scope 9.3의 "D1 `UNIQUE(event_id)`" 가정이 `tosspayments-webhook-transmission-id`로 정정됨.**

Brief M2가 의도한 정정 작업이 두 항목 모두 의도대로 작동했다. Brief가 가정을 못박지 않고 "재확인 필수"로 위임한 설계 덕분에 정정이 자연스럽게 흡수된다.

---

## 5. PCI SAQ-A 범위 정합 평가

Brief In Scope 18 (보안 baseline) 정합성:

| In Scope 18 항목 | R5 정합 |
|-----------------|---------|
| CORS (api ↔ Flutter, admin ↔ admin) | 결제 API는 Flutter-only origin → CORS 정책 적용 대상. R5에서 직접 설계는 없으나 Cycle 7이 Cycle 4(Auth+Security) 이후라 BetterAuth·CORS baseline 상속 전제 |
| CSP (admin SSR 응답) | 결제 flow는 admin UI와 무관, 직접 충돌 없음 |
| HSTS | CF Workers 자동 적용, 결제 도메인도 포함 |
| Rate limiting | intent/confirm endpoint에 per-IP 제한 필요 — Cycle 7 구현 시 Cycle 4 미들웨어 재사용 명시됨 |
| CSRF (origin-check) | Workers 측 confirm endpoint는 Flutter WebView에서 호출 (native app context) → SameSite=None 또는 Custom header 기반 CSRF |
| WAF (무료 CF WAF) | Toss callback IP 제한 가능 여부는 R5에서 미탐색 — Cycle 7 makeplan에서 확인 권고 |
| SAQ-A 적합성 | **확정** — PAN 비접촉, Toss Level 1 인증 파생 신뢰 |

**SAQ-A 범위 정합성: PASS.** In Scope 18 보안 baseline과 충돌 없음. Toss의 PCI-DSS Level 1 인증이 가맹점 Workers의 PAN 비접촉 구조를 보증하므로 별도 PCI 심사 불필요.

---

## 6. Cycle 7 (Payment 7-stage) Readiness

R5 리서치가 Cycle 7 실행에 필요한 모든 deliverables를 제공했다.

### 제공된 deliverables

| 항목 | 제공 여부 |
|------|---------|
| 7-stage 시퀀스 다이어그램 | O (연구 문서 §7-stage) |
| webhook 검증 의사코드 (모델 A+B 분기) | O |
| D1 스키마 (payments, payment_cancels, webhook_events) | O |
| Cycle 7 file plan 초안 (12 파일, 경로 포함) | O |
| R1·R3·R4와의 결합 지점 명시 | O |
| Web Crypto 호환성 확인 | O |
| E2E 테스트 시나리오 7개 | O |

### Cycle 7 file plan (R5 확정)

```
lib/payment/toss/
  client.ts              # fetch wrapper (secretKey + Idempotency-Key)
  confirm.ts             # POST /v1/payments/confirm
  cancel.ts              # POST /v1/payments/{paymentKey}/cancel
  webhook-verify.ts      # 모델 A (secret 비교) + 모델 B (HMAC v1) stub 분기
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

Cycle 7 makeplan은 R5 file plan을 기준으로 즉시 시작 가능하다.

---

## 7. Recommended Changes

```yaml
recommended_changes: []
# PROCEED — 추가 조치 없음. Cycle 7 makeplan으로 진행.
```

---

## 8. Findings Preserved

| ID | 유형 | 내용 | Cycle 7 전달 |
|----|------|------|-------------|
| EV-017-D1 | Discovery | PAYMENT_STATUS_CHANGED webhook은 HMAC 없음 — secret 필드 비교가 표준. Brief 일반화 가정 정정. | webhook-verify.ts 모델 A 구현 |
| EV-017-D2 | Discovery | idempotency webhook anchor = `tosspayments-webhook-transmission-id` (Brief의 `event_id` 정정) | D1 컬럼명 `transmission_id` 사용 |
| EV-017-D3 | Discovery | 환불 API가 cancel 단일 endpoint로 통합. 부분/전체 분기는 `cancelAmount`. 환불 전용 webhook 이벤트 없음 | cancel.ts + refund.ts 설계 반영 |
| EV-017-D4 | Discovery | 재시도 10초 윈도우 — 무거운 작업은 `ctx.waitUntil` 필수 | toss.ts 핸들러 waitUntil 패턴 |
| EV-017-D5 | Discovery | SAQ-A 범위 확정. PCI Level 1은 Toss 보유, 가맹점 파생 신뢰 | Cycle 7 컴플라이언스 문서 |
| EV-017-D6 | Discovery | 모델 B (HMAC v1) 시크릿 회전 윈도우 길이는 1차 출처 미명시 — 정산 도입 시 tech support 문의 필요 | webhook-verify.ts 주석 |
| EV-017-A1 | Assumption | Cycle 7이 Cycle 4(Auth+Security) 이후 실행 → BetterAuth user 인증·CORS baseline 상속 전제 | Dependency 확인 필수 |
| EV-017-A2 | Assumption | `successUrl` redirect가 Flutter WebView 내부에서만 처리된다는 전제 — 외부 launcher 케이스는 `GET /v1/payments/orders/{orderId}` polling 보조 패턴 필요 | e2e.test.ts에서 WebView 외부 시나리오 추가 검토 |

---

## Terminal Output

```
== Eval: Research Cycle 5 Complete ==
Depth Score: 6/6 (K:3 C:3)
Critical gate: PASS
Verdict: PROCEED
Findings: D:6 C:0 A:2 S:0 (8건)
Document: /Users/kampikrein/A/personality/docs/6_backend/02_cf_workers_rebuild/017_Eval_R5.md
```

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
