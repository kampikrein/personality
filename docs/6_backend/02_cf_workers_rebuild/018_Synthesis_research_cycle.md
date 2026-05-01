---
id: "018"
type: synthesis
title: "Research Phase Synthesis — 5축 정합 + Cross-axis 충돌 해소 + Brief 정정"
created: 2026-04-29
traces_brief: "001"
traces_scope: "007"
traces_research: ["008", "009", "010", "011", "012"]
traces_eval: ["013", "014", "015", "016", "017"]
phase: research
verdict_summary:
  R1: "SUFFICIENT (6/6)"
  R2: "SUFFICIENT (6/6)"
  R3: "SUFFICIENT (6/6)"
  R4: "SUFFICIENT (5/6)"
  R5: "SUFFICIENT (6/6)"
summary: >
  Research phase 5축 모두 PROCEED. Schema cross-axis 충돌(R1 wire-compat vs R4 분리 컬럼)은
  R4 우위 + R2 UNIQUE 제약 + R1 envelope 보존의 통합 패턴으로 정합. Brief 가정 정정 3건
  (Anchor 9 격리, Decision 5 webhook 모델 이중화, In Scope 9.3 idempotency key 명칭).
  Scope 누락 1건(공개 평가 흐름 Stimulus 8) → Cycle 6 영역 확장으로 흡수. 10 impl 사이클
  진입 준비 완료.
keywords: [research-synthesis, cross-axis, schema-conflict-resolution, brief-correction, impl-phase-input]
---

# Research Phase Synthesis — cf_workers_rebuild

## 1. Verdict Roll-up

| Axis | Verdict | Depth | 핵심 결정 |
|------|---------|-------|----------|
| R1 Drizzle + D1 | SUFFICIENT | 6/6 | Drizzle = schema, Wrangler = migration runner. JSON1 = `text({mode:'json'})`. 결정성 암호화 = AES-256-GCM + IV=HMAC. Rollback = D1 Time Travel + reverse SQL |
| R2 D1 saga vs DO | SUFFICIENT | 6/6 | **Pure Saga** (D1 only). 7/8 단계 idempotent — step 7 Profile만 UPSERT 보강. Forward-recovery (status=failed 마킹) |
| R3 Admin UI | SUFFICIENT | 6/6 | **Hono SSR vanilla** (+ hx-boost 1줄 옵셔널). Astro 6 / HTMX 모두 GA지만 9 ERB / 293 LOC admin에 과한 추상화 |
| R4 Auth hybrid | SUFFICIENT | 5/6 | BetterAuth Active(v1.6.9). Cross-subdomain **격리**. Parallel-key rotation + 3중 백업. 분리 컬럼 schema 권고 |
| R5 Toss 결제 | SUFFICIENT | 6/6 | Webhook 이중 모델(secret 비교 vs HMAC v1). 결제 webhook은 모델 A. SAQ-A 범위. Idempotency key = `tosspayments-webhook-transmission-id` |

## 2. Cross-axis 충돌 해소

### 충돌 1: User email schema 모델 (R1 vs R4)

| 측면 | R1 권고 | R4 권고 |
|------|--------|---------|
| 컬럼 모델 | 단일 결정성 컬럼 (envelope JSON) | 3 컬럼 분리 (`email_hash`, `email_enc`, `encryption_version`) |
| Phase rollback 호환 | Rails wire-compat 직접 가능 | export 변환 스크립트 필요 |
| Key rotation 부담 | high (전 row re-encrypt) | low (parallel-key + lazy migration) |
| 보안 격상 | medium | high (lookup ↔ cipher 분리) |
| Eval 판정 | — | **R4 우위** (운영 현실 논리: rotation 부담 낮아야 실제 실행) |

**정합된 결정**:
- 컬럼 모델: **R4 분리 패턴 채택** (`email_hash` + `email_enc` + `encryption_version`)
- envelope 형식: **R1 envelope JSON을 `email_enc` 컬럼 값으로 그대로 저장** (Rails ActiveRecord::Encryption::Message wire-format 보존)
- Phase rollback: In Scope 15 산출물에 **D1 → SQLite + 결정성 컬럼 변환 스크립트** 명시 포함 (Cycle 9 deliverable)
- key rotation: R4 parallel-key Phase 0~5 절차 (Wrangler secret + R2 sealed + 1Password)

이 통합 패턴이 R1+R4 두 권고를 모두 보존한다.

### 충돌 2: Cross-subdomain 인증 (Brief Anchor 9 vs R4)

- Brief Anchor 9 원문: "Domain 분리 = `api.<도메인>` + `admin.<도메인>`. **인증 토큰은 양 서브도메인 공유** (cookie domain 또는 JWT)."
- R4 권고: **격리** — api는 BetterAuth host-scoped cookie, admin은 CF Access JWT host-scoped, 두 도메인 disjoint
- Eval R4 판정: minor 운용 정정 (architectural 번복 아님)

**정합된 결정**: **격리 채택**. Brief Anchor 9의 "공유"는 Cookie domain 공유 옵션을 명시했지만, 1인 운영자 + 모바일이 api 주 클라이언트인 본 환경에서 공유 가치는 0이고 leakage 위험만 추가됨. Synthesis가 Anchor 9을 minor 정정한다.

### Cross-axis 영향 3: Schema UNIQUE 제약 (R2 → Cycle 2 input)

R2의 saga forward-recovery는 다음 UNIQUE 제약이 schema에 강제될 때만 작동:
- `domain_scores`: `UNIQUE(assessment_id, domain)`
- `profiles`: `UNIQUE(assessment_id)`
- `insights`: `UNIQUE(profile_id, context)`

**적용**: Cycle 2 (DB Layer) makeplan에서 R1 schema 권고에 위 3 제약 + R4 user 분리 컬럼을 모두 반영하여 schema.ts 작성.

## 3. Brief 가정 정정 / Minor Adjustment

| # | Brief 위치 | 원문 가정 | Research 정정 | 정정 근거 (출처) |
|---|----------|---------|-------------|---------------|
| BC1 | Anchor 9 | "인증 토큰은 양 서브도메인 공유" | **격리** | R4 Q2, EV-016 |
| BC2 | Decision 5 / In Scope 9.3 | "webhook = HMAC-SHA256" 일반화 | 모델 이중: A(secret 비교, 결제) / B(HMAC v1, payouts) | R5 Q1, docs.tosspayments.com/reference/using-api/webhook-events |
| BC3 | In Scope 9.3 (M2) | idempotency key 명칭 `event_id` (추정) | `tosspayments-webhook-transmission-id` (1차 출처 정확 명칭) | R5 Q2, Toss webhook docs |

**모든 정정은 Brief frozen 상태를 유지하면서 본 synthesis가 makeplan/impl 입력 차원에서 흡수한다.** Brief 직접 수정 없음.

## 4. Scope 누락 / 영역 정의 보정

### Scope 누락: 공개 평가 흐름 Stimulus 8 (EV-015-S1)

R3 실측 결과:
- admin = 9 ERB / 293 LOC / Stimulus 0 (Brief가 합산으로 "27 ERB + 8 Stimulus"라 표기)
- **Stimulus 8개 = 공개 평가 흐름 (`assessments/`)** — 사용자 직접 노출 SSR + 인터랙션

**해소 방향**: scope 작성 시 `Cycle 6 = Admin UI`로 한정한 게 좁았다. 가장 작은 수정:

**Cycle 6 영역 정의 확장** = "Admin UI + Public Assessment Flow SSR"
- Admin UI: 9 ERB → Hono SSR vanilla (~600 TSX LOC)
- Public Assessment Flow: 27 ERB - 9 ERB = 18 ERB / Stimulus 8 → Hono SSR + hx-boost 또는 동등 인터랙션 패턴
- 기존 R3 winner(Hono SSR vanilla + hx-boost 옵셔널) 그대로 적용 가능

Scope 007 frontmatter에 보정 메모는 추후 makeplan 단계에서 명시. 본 synthesis가 Cycle 6 영역 확장을 권고하고, 영역 변경은 cycle 1 진입 직전 또는 Cycle 6 makeplan에서 최종 확정.

### Scope 보강: Cycle 9 Phase rollback에 변환 스크립트 추가

In Scope 15 (Phase rollback 절차)의 산출물에 다음 추가:
- D1 → SQLite export
- 분리 컬럼 (`email_hash`/`email_enc`/`encryption_version`) → Rails 단일 결정성 컬럼 변환 스크립트
- key rotation 진척 검증 스크립트 (R4 K_n 폐기 전 사전 점검)

## 5. Cycle별 입력 (Impl Phase 진입 직전)

| Impl Cycle | 영역 | Research 입력 (decisions) | Cross-axis 영향 |
|-----------|------|------------------------|-----------------|
| 1 Foundation | CF infra + secrets + CI/CD | R4 secrets 운영 모델 (Wrangler + R2 sealed + 1Password) | — |
| 2 DB Layer | Drizzle schema | R1 (SOT, JSON1, envelope), R2 (UNIQUE 제약 3건), R4 (user 분리 컬럼), R3 (PersonalityType seed 포함) | 3축 통합 |
| 3 Domain Services | scoring saga + Vitest | R2 (Pure Saga, 7/8 idempotent, Phase A-E 분할, ~150 LOC) | R1 schema 적용 |
| 4 Auth + Security | BetterAuth + CF Access + 보안 baseline | R4 (BetterAuth v1.6.9, parallel-key rotation, CSRF 이중 체크), R1 (key 운용 + envelope) | — |
| 5 API + Mobile | Hono routes + OpenAPI + envelope | (R3 winner 무관 — API 자체) | — |
| 6 Admin UI + Public Flow | Hono SSR vanilla (영역 확장) | R3 (Pattern A + hx-boost 옵셔널, ~600 TSX admin + ~? 공개 흐름) | EV-015-S1 흡수 |
| 7 Payment 7-stage | Toss intent → confirm → webhook → refund → retry → receipt → E2E | R5 (모델 A 활성화, transmission-id idempotency, 12 file plan, retry 7회 1·4·16·64·256·1024·4096분, ctx.waitUntil) | R4 인증 (user_id) |
| 8 Compliance | GDPR/PIPA flows | R4 (encrypt 키 + admin SSO 분리), R5 (PCI SAQ-A 범위 정합) | — |
| 9 Cutover Safety | archive smoke + Phase rollback drill | **synthesis 추가**: D1 → SQLite + 컬럼 변환 스크립트, key rotation 검증 | R1+R4 schema 가역성 |
| 10 Cutover Execution | Phase A→B→C + monitoring + retro | (모든 선행 입력 종합) | — |

## 6. Open Questions (Impl Phase 관찰)

1. **OQ-1**: Cycle 6 공개 평가 흐름의 정확한 LOC + 인터랙션 매핑 (현 8 Stimulus → Hono SSR + hx-boost 또는 본격 htmx) — Cycle 6 makeplan에서 결정.
2. **OQ-2**: BetterAuth `email_hash` 생성 hook 위치 — sign-up flow에서 server-side 강제 (BetterAuth `before-create` 또는 mounter 미들웨어). R4 보고서가 코드 스케치 제공, makeplan에서 정확한 BetterAuth API 매핑 확정.
3. **OQ-3**: Cycle 7 webhook 모델 B (HMAC v1)의 dormant 코드 작성 여부 — 현 phase는 결제만이므로 모델 A만 활성화. 모델 B 코드를 미리 두느냐 (Y) vs payouts 추가 시점에 작성하느냐 (N) — Cycle 7 makeplan 결정.
4. **OQ-4**: Cycle 9 archive smoke test 자동화 빈도 (Brief: 월 1회 또는 분기 1회) — Cycle 9 makeplan에서 1개 확정.
5. **OQ-5**: Cycle 4의 Hono CSRF 보완(Origin + Sec-Fetch-Site 이중 체크)이 모바일 클라이언트(Bearer JWT, csrf bypass)와 admin(strict Origin)을 어떤 미들웨어 분기로 구현할지 — Cycle 4/5 makeplan 통합 결정.

## 7. Findings ID 정렬 (Impl Phase 추적용)

```
S-018-F1 [Critical]  R4 schema 패턴 채택 + R1 envelope 보존 (충돌 1 정합)
S-018-F2 [Critical]  R2 UNIQUE 제약 3건 schema 적용 (R1+R2 cross-axis)
S-018-F3 [High]      Brief Anchor 9 minor 정정 — 격리
S-018-F4 [High]      Brief Decision 5/In Scope 9.3 정정 — webhook 모델 이중화 (M2 흡수)
S-018-F5 [High]      Brief In Scope 9.3 정정 — idempotency key 정확 명칭
S-018-F6 [High]      Cycle 6 영역 확장 — Admin UI + Public Assessment Flow SSR
S-018-F7 [Medium]    Cycle 9 산출물 보강 — 분리 컬럼 변환 스크립트
S-018-F8 [Medium]    BetterAuth Active 확정 (Lucia v3 sunset 재확인)
S-018-F9 [Medium]    Pure Saga 채택 — Durable Object 미선택 (운영 단순성 우선)
S-018-F10 [Low]      Astro 6 GA 확인 (2026-03-10) — admin에 미채택 (과한 추상화)
```

## 8. Impl Phase Readiness

✅ 5축 모두 PROCEED 판정
✅ Cross-axis 충돌 (1건) 정합 결정
✅ Brief 가정 정정 3건 흡수 (Brief frozen 유지)
✅ Scope 누락 1건 해소 (Cycle 6 영역 확장)
✅ 10 impl 사이클 입력 매핑 완료
✅ 5 Open Questions 식별 (impl 단계에서 makeplan별 해결)

**다음 단계**: cycle-99 retro → impl phase init (`pipeline.sh init cf_workers_rebuild --phase impl`로 10 사이클 + tail 추가) → gate loop sequential 실행.

## 9. References

| 문서 | Path |
|------|------|
| Brief | [001_Brief_cf_workers_rebuild.md](./001_Brief_cf_workers_rebuild.md) |
| Scope | [007_Scope_cf_workers_rebuild.md](./007_Scope_cf_workers_rebuild.md) |
| R1 Research | [008_Research_axis1_drizzle_d1.md](./008_Research_axis1_drizzle_d1.md) |
| R2 Research | [009_Research_axis2_d1_saga.md](./009_Research_axis2_d1_saga.md) |
| R3 Research | [010_Research_axis3_admin_ui.md](./010_Research_axis3_admin_ui.md) |
| R4 Research | [011_Research_axis4_auth_hybrid.md](./011_Research_axis4_auth_hybrid.md) |
| R5 Research | [012_Research_axis5_toss_payment.md](./012_Research_axis5_toss_payment.md) |
| R1 Eval | [013_Eval_R1.md](./013_Eval_R1.md) |
| R2 Eval | [014_Eval_R2.md](./014_Eval_R2.md) |
| R3 Eval | [015_Eval_R3.md](./015_Eval_R3.md) |
| R4 Eval | [016_Eval_R4.md](./016_Eval_R4.md) |
| R5 Eval | [017_Eval_R5.md](./017_Eval_R5.md) |

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
