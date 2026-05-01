---
id: "016"
type: eval
title: "Eval R4 — Auth hybrid"
created: 2026-04-29
traces_research: "011"
verdict: proceed
depth_score: 5
k_score: 3
c_score: 2
cycle: 4
phase: research
brief_correction_signal: true
cross_axis_conflict: true
---

# Eval R4 — Auth hybrid

## Verdict + Depth

**Verdict: PROCEED**
**Depth Score: 5/6** (K:3 C:2)

K-score 3 — Q1~Q4 전부 핵심 질문에 완전히 답변. BetterAuth 활성도 실증, cross-subdomain 격리 결정, Hono CSRF 한계 + 보완, parallel-key rotation 절차 단계별 코드까지 제시.

C-score 2 — 대부분 영역 탐색 완료. Open Questions 4건을 explicit하게 식별·기록했으나 미해결 상태. 특히 Q2의 BetterAuth Bearer plugin 공식 패턴(모바일 flow), Q4 CF JWKS 캐시 만료 처리는 Cycle 4 makeplan에 위임된 상태 — minor 공백.

---

## Q1-Q4 커버리지

### Q1 BetterAuth 활성도 (K:3/3)

- GitHub stars 28,037, 2026-04-28 latest commit, v1.6.9(2026-04-24), 4월 거의 매일 패치 — 수치 실측.
- v1.5.0(2026-02-28) "D1 first-class", "600+ commits, 70 features" 공식 블로그 인용.
- YC 후원, Workers 호환 버그 수정 흔적("immutable headers on Cloudflare Workers") 명시.
- Lucia v3 sunset 메인테이너 공식 인용("deprecated. learning resource").
- **판정**: 완전 답변.

### Q2 Cross-subdomain (K:3/3)

- 옵션 A/B/C 결정 매트릭스를 표로 제시, B(격리) 채택 사유 3개.
- BetterAuth cookie 설정(TypeScript 코드 스니펫) + CF Access Application token 범위 공식 인용.
- Flutter `dio` credentials:include 명시.
- Cross-leakage 방지 원리 다이어그램으로 표현.
- **판정**: 완전 답변.

### Q3 Hono CSRF (K:3/3)

- Hono CSRF docs 직인용 — "Origin + Sec-Fetch-Site 이중 체크".
- 4가지 한계(Origin 헤더 부재, JSON content-type 미보호, per-session token 부재, Multi-origin) 구조화.
- 보완 패턴 4개(이중 allowlist, SameSite=Lax, 모바일 Bearer bypass, JSON admin strict origin) 제시.
- Brief In Scope 18("per-session token 부재 사실 명시") 정합성 확인.
- **판정**: 완전 답변.

### Q4 Encryption key rotation (K:3/3)

- 3중 저장(Wrangler secret + R2 sealed(age) + 1Password) — Brief Constraint 충족.
- parallel-key 패턴 Phase 0~5 의사코드(bash 명령 단위).
- lazy vs batch re-encrypt 옵션 모두 제시.
- `users.encryption_version` 컬럼 권고 + SQL.
- BetterAuth 1.5 non-destructive rotation native 인용.
- **판정**: 완전 답변.

---

## Source Quality

1차 출처 인용 수: **11개 이상** (요건 ≥5 충족)

| # | 출처 | 유형 |
|---|------|------|
| 1 | better-auth.com/blog/1-5 — v1.5 D1 native | 공식 블로그 |
| 2 | better-auth.com/docs/concepts/database — SecondaryStorage interface | 공식 docs |
| 3 | better-auth.com/docs/concepts/cookies — crossSubDomainCookies, trustedOrigins | 공식 docs |
| 4 | developers.cloudflare.com/cloudflare-one/identity/authorization-cookie/ | 공식 docs |
| 5 | developers.cloudflare.com/cloudflare-one/identity/authorization-cookie/validating-json/ | 공식 docs |
| 6 | hono.dev/docs/middleware/builtin/csrf | 공식 docs |
| 7 | lucia-auth.com/lucia-v3/migrate — "deprecated. learning resource" | 공식 docs |
| 8 | github.com/better-auth/better-auth/releases | 1차 release 이력 |
| 9 | better-auth.com/changelog | 공식 changelog |
| 10 | blog.cloudflare.com/access-wildcard-and-multi-hostname/ | CF 공식 블로그 |
| 11 | cloudflare.com/plans/zero-trust-services/ — 50 user free tier | 공식 pricing |

2차 출처(community) 3개(HonoGear, Wisp Blog, daily.dev)는 주석 수준으로 활용 — 1차 출처에 종속되지 않음.

품질 평가: **PASS**. 핵심 결정 전부에 1차 출처 직인용. 코드 스니펫은 공식 docs 패턴 기반.

---

## Cross-axis 충돌 평가: R1 schema vs R4 schema

### 충돌 내용

| 축 | 권고 패턴 | 컬럼 수 | 특성 |
|----|----------|---------|------|
| **R1** (Drizzle D1 통합) | `email` 단일 컬럼 — ciphertext envelope 자체가 UNIQUE INDEX | 1 | Rails wire-compat 우선, Phase rollback D1→SQLite export 호환 |
| **R4** (Auth hybrid) | `email_hash`(SHA-256) + `email_enc`(ciphertext) + `encryption_version` 분리 | 3 | 보안 격상, key rotation 부담 최소화(hash는 rotation 불요) |

### 분석

**R1 입장의 근거**:
- Rails `ActiveRecord::Encryption::Message` JSON envelope 구조를 그대로 유지 → Phase rollback(In Scope 15 Critical) 시 D1→SQLite export 후 archive Rails가 직접 복호화 가능.
- `UNIQUE INDEX(email)` — ciphertext 자체가 결정성이므로 동등 비교 가능.
- 단일 컬럼으로 schema 단순성.

**R4 입장의 근거**:
- HMAC-SHA256(key, plaintext) 기반 결정성 암호화는 **plaintext-ciphertext mapping이 predictable** — key 노출 시 offline dictionary attack 가능. SHA-256(plaintext) hash는 key 없이 lookup만 하므로 공격 면적 분리.
- Key rotation 시 `email_enc`만 재암호화하면 되고 `email_hash`는 그대로 — 회전 비용 대폭 절감.
- BetterAuth 1.5 non-destructive rotation과 자연스럽게 정합.

### 트레이드오프 핵심

| 기준 | R1(단일 컬럼) | R4(분리 컬럼) |
|------|-------------|-------------|
| Phase rollback 호환(In Scope 15) | ★★★ Rails 직접 복호화 | ★★ export 변환 시 email_hash 처리 추가 필요 |
| 보안 모델 | ★★ 결정성 AES-GCM | ★★★ hash/enc 분리, key 노출 영향 최소화 |
| Key rotation 부담 | ★★ 전 row email re-encrypt | ★★★ enc만 재암호화 |
| Schema 단순성 | ★★★ | ★★ 컬럼 3개 |

### 우위 판정

**R4 분리 컬럼 우위 — 이유**: In Scope 15 Phase rollback의 핵심 요건은 "D1→SQLite export 변환 + archive Rails 가동"이다. R4 패턴에서도 export 시 `email_enc` 컬럼을 Rails envelope 형식으로 변환하는 단계가 추가될 뿐, 구조적으로 불가능하지 않다. 반면 R1의 단일 결정성 컬럼 방식은 key 노출 시 보안 위협이 더 크고, rotation 부담이 높다. **생산 환경에서 key rotation은 결국 시행되고, 비용이 높은 패턴은 운영자가 미루게 된다** — 이는 정보 보안에서 가장 위험한 결과다.

단, R4 분리 패턴이 Phase rollback 호환을 보장하려면 **export 변환 스크립트(`email_hash + email_enc` → Rails envelope)를 In Scope 15 rollback drill에 포함**해야 한다. 이것을 Cycle 4 makeplan에 명시적으로 반영하는 것을 권고한다.

**Synthesis 단계에서의 정합화 방향**: R1 schema.ts는 `email` 단일 컬럼 → `emailHash` + `emailEnc` + `encryptionVersion` 3 컬럼으로 업데이트. R1 결정성 암호화 패턴(HMAC IV AES-GCM)은 `emailEnc` 컬럼에 그대로 적용. R4의 `emailHash`는 `SHA-256(plaintext)` (key 무관) — R1의 deterministic_key를 사용한 HMAC IV 방식과 별개 필드.

---

## Brief Anchor 9 정정 평가

**Brief Anchor 9**: "api ↔ admin 인증 토큰 공유" (양 서브도메인 cookie 공유 또는 JWT 공유 표현)

**R4 정정**: api(BetterAuth, domain=`api.<도메인>`)와 admin(CF Access, domain=`admin.<도메인>`)은 **격리** — cookie leakage 0, 세션 공유 없음. Brief Anchor 9의 "공유" 표현은 운용 결론으로 정정됨.

**Brief Correction Signal 평가: `true`**

이 정정은 Brief Decision 8의 큰 틀("BetterAuth + CF Access hybrid")은 변경하지 않고, 세부 운용 방식("공유" → "격리")을 바로잡는 minor 정정이다. Brief Model Anchor 19("User 인증과 Admin 인증은 도메인별 분리 운영")와 일관성 있게 정합된다.

정정 유형: **운용 결론 정정** (architectural decision 번복 아님). Synthesis 단계에서 Brief Anchor 9를 "격리" 표현으로 업데이트할 것을 권고한다.

---

## Cycle 4 Deliverables

R4가 Cycle 4(Auth + Security Baseline) 구현에 제공하는 명확한 산출물:

| File | 내용 |
|------|------|
| `lib/auth/betterauth.ts` | BetterAuth 인스턴스 (D1 native + KV wrapper, cookie config) |
| `lib/auth/cf-access.ts` | `requireCFAccess` 미들웨어 (jose JWKS, AUD, issuer) |
| `lib/auth/encryption.ts` | Web Crypto + parallel-key selector (K_n/K_{n+1} dual-read) |
| `lib/auth/kv-adapter.ts` | SecondaryStorage → Workers KV 30 LOC wrapper |
| `lib/middleware/csrf.ts` | Hono csrf wrapper (api/admin 분기, mobile Bearer bypass) |
| `lib/middleware/strict-origin.ts` | admin JSON mutation Origin enforce |
| `scripts/rotate-encryption-key.sh` | Phase 0~5 rotation 자동화 |
| `tests/auth/*.test.ts` | sign-in / session / CF Access JWT mock / rotation dry-run |
| db schema 추가 | `users.email_hash`, `users.email_enc`, `users.encryption_version` |

Cycle 4 선행 조건(Scope 007):
- Cycle 1(Foundation) — Wrangler/D1/KV binding, secrets 셋업
- Cycle 2(DB Layer) — users 테이블 schema (`email_hash + email_enc + encryption_version` 포함)

두 선행 조건 모두 R4가 명확한 인터페이스를 정의했으므로 Cycle 4 tdd-red → makeplan 진행 가능.

---

## Recommended Changes

```yaml
recommended_changes:
  - action: note
    target: cycle_4_makeplan
    content: >
      email_hash + email_enc + encryption_version 3-column schema를 Cycle 2 makeplan에서
      반영 요청. R1 schema.ts의 단일 email 컬럼 권고를 override. R4 우위 근거: rotation
      비용, 보안 격상 (상세: 016_Eval_R4.md Cross-axis 충돌 평가).
  - action: note
    target: cycle_9_rollback_drill
    content: >
      Phase rollback(In Scope 15) drill에 email_hash + email_enc → Rails envelope 변환
      스크립트 포함. R4 분리 컬럼 패턴의 rollback 호환성 보장용.
  - action: brief_correction
    anchor: "Anchor 9"
    old: "api ↔ admin 인증 토큰 공유"
    new: "api ↔ admin 인증 격리 (BetterAuth cookie domain=api vs CF_Authorization domain=admin)"
    note: "Synthesis 단계에서 반영 권고"
```

---

## Findings Preserved

| ID | Type | 내용 | 처리 |
|----|------|------|------|
| EV-016-D1 | Discovery | BetterAuth 1.5 KV SecondaryStorage는 공식 어댑터 부재 — 30 LOC thin wrapper 직접 작성 필요 | Cycle 4 makeplan에 kv-adapter.ts 포함 |
| EV-016-D2 | Discovery | CF Access free tier 50 users — 1인 운영 가정에선 무관하나 팀 확장 시 비용 발생 | Open Question 1로 기록 (6/12개월 retro에 위임) |
| EV-016-D3 | Discovery | BetterAuth Bearer plugin 공식 패턴 — 공식 docs에 상세 미기재, Cycle 4 makeplan에서 추가 조사 필요 | Open Question 2 |
| EV-016-C1 | Conflict | R1(단일 email 결정성 컬럼) vs R4(email_hash + email_enc + encryption_version 분리) — 본 eval에서 R4 우위 판정 | Cycle 2/4 makeplan에서 3-column 채택으로 정합화 |
| EV-016-C2 | Conflict | Brief Anchor 9 "공유" 표현 vs R4 격리 결정 — R4로 정정 | Synthesis 단계 brief_correction 권고 |
| EV-016-A1 | Assumption | 모바일 Flutter 클라이언트가 `withCredentials=true` 설정을 구현한다 (BetterAuth cookie session 동작 전제) | Cycle 5 API + Flutter call test에서 검증 |
| EV-016-A2 | Assumption | CF Access 팀 도메인(`<team>.cloudflareaccess.com`)이 1인 운영자에게 이미 존재 또는 신규 생성 예정 | Cycle 1(Foundation) 셋업 시 명시적 포함 확인 필요 |
| EV-016-S1 | Side-effect | `email_hash` 컬럼 추가 → Cycle 2 DB schema.ts 수정 + Cycle 9 rollback drill 스크립트 확장 | recommended_changes에 반영 |

---

## Scoring

| 차원 | 값 | 점수 | 근거 |
|------|---|------|------|
| K-score | 3/3 | 3 | Q1~Q4 전부 핵심 질문에 완전히 답변. 결정 1건씩 + 코드 + 인용 |
| C-score | 2/3 | 2 | 대부분 영역 탐색. Open Questions 4건(Bearer plugin, JWKS cache, CF Access free tier 한계, Cron Trigger latency) explicit 기록 — minor 미완 |
| **Depth Score** | **5/6** | — | K+C 합산 |

---

```
== Eval: Research Cycle 4 Complete ==
Depth Score: 5/6 (K:3 C:2)
Critical gate: PASS
Verdict: PROCEED
Findings: D:3 C:2 A:2 S:1 (8건)
Document: /Users/kampikrein/A/personality/docs/6_backend/02_cf_workers_rebuild/016_Eval_R4.md
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
