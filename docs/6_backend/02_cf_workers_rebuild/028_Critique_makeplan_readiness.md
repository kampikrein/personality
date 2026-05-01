---
id: "028"
type: critique
title: "Scope 026 Critique — makeplan 진입 준비도"
created: 2026-04-29
status: completed
perspective: "makeplan_readiness"
target: "026"
confidence: high
summary: >
  Scope 026은 활성 7 사이클의 대분류·의존성·TDD 적용 범위를 명확히 묶었으나,
  makeplan agent가 추가 조사 없이 plan을 작성하기엔 5개 사이클이 미완 상태다.
  특히 (1) Scope 본문 "18 ERB" 수치가 실 코드 13 ERB와 불일치하고, (2) Cycle 5 routes 인벤토리가 13 controllers/22 public + 10 admin = 32 endpoints로 사전 매핑되지 않았으며, (3) saga Phase A-E 의사코드, BetterAuth/CF Access verifier 인터페이스, 14세 미만 흐름 결정 등이 사이클별 makeplan에 위임된 채 명세 부재. Plan 020에 비교했을 때 후속 사이클의 명세 수준이 1~2단계 낮다.
keywords: [critique, scope-026, makeplan-input, deliverable-specification, file-confidence, low-confidence-cycles]
---

# Scope 026 Critique — makeplan 진입 준비도

## Executive Summary

Scope 026은 Brief 021을 7 사이클로 잘 분해했고 (a) Foundation 한정형 정의, (b) Cycle 4가 Cycle 5보다 선행하는 의존 결정, (c) Pipeline DB interrupted 적용 완료, (d) confidence 라벨 자체 표시 등 **상위 구조는 정합**하다. 그러나 **개별 사이클 makeplan agent 입장**에서는 다음 5개 사이클(3, 4, 5, 6, 8)에서 추가 read-only 조사가 사실상 강제된다. 그중 Cycle 5(API+Mobile)와 Cycle 6(Admin+Public)은 정량 인벤토리(routes, ERB, Stimulus)를 makeplan이 직접 추출해야 하며, 본 critique 조사 결과 **실 인벤토리가 Scope 026 본문 수치와 불일치**(public ERB 18 → 13)한다. Cycle 1만 Plan 020 표본 수준의 명세를 갖췄다.

총 severity: **Critical 2 + Major 4 + Minor 3 = 9건**. 가장 큰 마찰점은 (1) 사이클 5 routes 인벤토리 부재 + (2) Scope 본문의 ERB 수치 불일치 + (3) saga Phase A-E 의사코드 위임처 불명.

## Strengths

1. **Cycle 1 한정형 정의 명확**: Plan 020의 외부 자원 step (U1-U8) skip + 14 file 목록 + compatibility_flags 명시. makeplan agent에게 "Plan 020에서 무엇을 빼라"가 분명.
2. **사이클 의존성 그래프**: 1→2→{3,4}→5→{6,8} 토폴로지 시각화. tail 합류 명확.
3. **Confidence 자기표시**: low confidence 사이클(5, 6)을 명시하고 makeplan에서 재검증 필수임을 단언 (라벨링 자체는 정직).
4. **TDD 적용 범위 명확**: cycles 2-6, 8. tdd-red sub-agent가 어디서 호출되는지 makeplan agent가 즉시 인지 가능.
5. **Pipeline DB 정렬 상태 표기**: 26개 step의 현재 status를 본문에 명시. dispatch 순서 ambiguity 0.
6. **사이클별 입력 표 (Brief 021 + Synthesis 018/025 통합)**: 각 사이클이 어느 Research/Critique 항목을 입력으로 받는지 mapping.

## Weaknesses

| ID | Severity | Title | Cycle | Type |
|----|----------|-------|-------|------|
| W1 | **Critical** | Cycle 5 routes 인벤토리 makeplan에 위임 — 32 endpoints / 13 controllers 사전 매핑 부재 | 5 | spec missing |
| W2 | **Critical** | Scope 본문 "18 ERB + 8 Stimulus" 수치가 실 코드(13 ERB + 8 Stimulus)와 불일치 | 6 | factual error |
| W3 | Major | Cycle 3 saga Phase A-E 의사코드 위임처 불명 — Synthesis 018 R2-F는 분할만 명시, 코드 골격 부재 | 3 | spec missing |
| W4 | Major | Cycle 4 BetterAuth/CF Access/encryption/key_rotation 인터페이스 (export, params, return) 미정의 | 4 | spec missing |
| W5 | Major | Cycle 8 14세 미만 흐름 — 외부 정책(KYC) 의존 여부 미결정 | 8 | decision missing |
| W6 | Major | verify 단계가 어느 Ideal Criterion(Brief 021 #1~#28)을 검증하는지 사이클별 trace 부재 | 전 사이클 | trace missing |
| W7 | Minor | Cycle 1 cron handler stub-only 패턴 명세 부재 — Critique 023 M5만 인용, 실제 stub signature 미정 | 1 | spec missing |
| W8 | Minor | tdd-red agent에 도구 버전(vitest, vitest-pool-workers) 입력 경로 부재 | 2-6, 8 | toolchain leak |
| W9 | Minor | Cycle 6 EV-015-S1 흡수 후 ERB-by-ERB → TSX route 매핑 표 부재 | 6 | spec missing |

## Missing Elements

| # | What's missing | Where it should be | Impact on makeplan |
|---|----------------|--------------------|--------------------|
| ME1 | Cycle 5 endpoint 인벤토리 표 (32 endpoints × {HTTP method, controller, action, request schema, response schema, auth required?, mobile/admin/public}) | Scope § 영역 식별 표 5의 보조 표 | makeplan agent가 `bundle exec rails routes` 또는 routes.rb 직접 파싱 필요. 1회 추출하여 Scope에 고정하면 makeplan 진입 가속. |
| ME2 | Cycle 6 ERB-by-ERB 매핑 표 (admin 9 + public 13 → Hono route + TSX 컴포넌트 + hx-boost 적용 여부) | Scope § 영역 식별 표 6 보조 | "18 ERB" 수치 자체 수정 + 실제 13 ERB의 1:1 변환 표가 있어야 makeplan이 컴포넌트 결정 가능. |
| ME3 | Cycle 3 services 1:1 매핑 표 (20 .rb services × {대상 LOC, 대응 .ts 모듈, RSpec → Vitest 매핑}) | Scope § Cycle 3 makeplan 입력 보조 | 20 services × 18 specs 1:1 매핑이 Scope에 없으면 makeplan이 server/app/services 전수 탐색 + spec 매칭을 직접 수행. |
| ME4 | Cycle 3 saga Phase A-E 의사코드 (8단계 → A=read, B=score, C=normalize, D=classify, E=upsert+commit) | Scope § Cycle 3 note 또는 별도 부록 | "~150 LOC saga" 수치만으로는 makeplan이 step boundary를 결정 불가. |
| ME5 | Cycle 4 컴포넌트 인터페이스 명세 (BetterAuth init params, CF Access verifier signature, encryption wrap/unwrap, key_rotation phase enum) | Scope § Cycle 4 makeplan 입력 보조 | M1 (JWKS resolver DI 패턴)만 인용 — 다른 5개 컴포넌트 signature는 makeplan이 결정. |
| ME6 | Cycle 8 5 흐름 × Phase 1/2 분기 (consent / deletion / audit / 국외 이전 / 14세 미만 — 외부 정책 의존성 표시) | Scope § Cycle 8 note | 14세 미만 처리는 KYC API 외부 의존 가능성 → Phase 1/2 결정 부재 시 makeplan 위험. |
| ME7 | 사이클 × Ideal Criterion 매핑 표 | Scope § 사이클별 makeplan 입력 옆에 verify 기준 표 추가 | verify agent가 28 criteria 중 어느 것을 자기 사이클에서 검증할지 ad-hoc 결정 → 누락 위험. |
| ME8 | tdd-red agent 입력 (vitest 버전, vitest-pool-workers 버전, fixtures 위치) | Scope § Cycle 2-6, 8 makeplan 입력 | Brief 021 § 2.4의 도구 pin이 사이클 입력 표에 명시되지 않음 → tdd-red agent가 `package.json` 또는 Brief 직접 read 필요. |

## 사이클별 makeplan 진입 준비도 매트릭스

다음 5축으로 평가: **F**=파일 명세, **D**=deliverable 인터페이스, **I**=의존 입력, **V**=verify 기준, **T**=도구 버전.
점수: 3=완전, 2=부분, 1=요추가조사, 0=부재.

| Cycle | F (파일 명세) | D (인터페이스) | I (의존 입력) | V (verify 기준) | T (도구 버전) | Total | makeplan 즉시 가능? |
|-------|-------------|---------------|--------------|----------------|--------------|-------|--------------------|
| 1 Foundation | 3 (Plan 020 14 file) | 3 (cron handler stub 명시 — W7만 minor) | 3 (R4 secrets) | 2 (Plan 020 검증절 있음 + ME7 trace 부재) | 2 (wrangler 3.90.0 Plan 020에 명시, 그러나 Brief 021 § 2.4와 cross-ref 약함) | **13/15** | ✓ (Plan 020 보강만) |
| 2 DB | 2 (≥3 tests + schema 1 + migration 1) | 2 (R1/R2/R4 결정 명시, 14 테이블 schema 골격은 makeplan 산출) | 3 (R1, R2, R4) | 2 (#4-#8 매핑 추론 가능, ME7 부재) | 1 (drizzle-kit/orm 버전 Brief에만, Scope 입력 표 미참조) | **10/15** | △ |
| 3 Services | 1 (≥3 modules ≥18 tests — 20 services 1:1 매핑 표 부재) | 0 (saga Phase A-E 의사코드 부재 — ME4) | 2 (R2 saga 결정 명시, RSpec 18 → Vitest 매핑 위임) | 1 (#9-#11 매핑 추론, 20 services × 18 specs cross-ref 부재) | 1 (vitest 버전 cross-ref 부재) | **5/15** | ✗ |
| 4 Auth+Sec | 2 (lib 5 + middleware 5 + tests ≥6) | 1 (M1 JWKS DI만 명시, 다른 5 컴포넌트 signature 부재 — ME5) | 2 (R4 결정 + M1/M3/M11) | 1 (#12-#16 매핑 추론, JWKS rotation fixture test 명시 외 부재) | 1 (better-auth 1.6.9, Scope 입력 표 미참조) | **7/15** | ✗ |
| 5 API+Mobile | 1 (low confidence, ≥10 endpoints 추정 — 실 32 endpoints 인벤토리 부재 ME1) | 1 (envelope 미들웨어 결정만, OpenAPI schema 골격 부재) | 2 (Decision 8/9 + M2 Dart codegen 예외) | 1 (#17-#20 매핑 추론, 4 criteria 동시 적용 trace 부재) | 1 (hono 4.6.x, Scope 입력 표 미참조) | **6/15** | ✗ |
| 6 Admin+Public | 1 (low confidence, **본문 "18 ERB" 수치 오류 — 실 13** W2 + ME2) | 1 (R3 Hono SSR vanilla + hx-boost 결정만, TSX 컴포넌트 분할 부재 — ME9) | 2 (R3 + EV-015-S1 흡수) | 1 (#21-#22 매핑 추론, 27 ERB → SSR 동등성 metric 부재) | 1 (hono 4.6.x cross-ref 부재) | **6/15** | ✗ |
| 8 Compliance | 2 (lib ≥4 + routes 2개 + tests) | 2 (4 모델 명시, 5 흐름 명시) | 1 (Brief 021 In Scope 8 직접 — Phase 1/2 분기 부재 ME6) | 1 (#23-#24 매핑 추론, 14세 미만 외부 정책 의존성 미결정) | 1 (도구 버전 cross-ref 부재) | **7/15** | △ |

**즉시 makeplan 가능: Cycle 1만**. Cycle 2/8은 minor 추가 조사 후 가능. Cycle 3/4/5/6은 makeplan agent가 read-only 인벤토리 추출 + 인터페이스 결정을 직접 수행해야 함.

## Detailed Analysis

### W1 (Critical) — Cycle 5 routes 인벤토리 부재

Scope 026 § 영역 식별 표 5는 "13 컨트롤러 → Hono routes" + 파일 목록 추정 표는 "≥10 endpoints"로만 표기. 실 인벤토리:

| 영역 | 실 endpoint 수 | 비고 |
|------|--------------|------|
| Public (sessions, assessments, results, accounts, consents, deletion_requests, assessment_questions) | 22 | `/Users/kampikrein/A/personality/server/config/routes.rb` |
| Admin (dashboard + 2 dashboard custom + question_sets 7 + alerts 3 + audit_logs 2) | 10 | 동일 |
| **합계** | **32 unique controller#action** | (HTTP verb 중복 제외 시) |

`bundle exec rails routes`는 37개 라인, unique controller#action은 32개. Scope의 "≥10" 표기는 makeplan 입장에서 "최소 10개 + α"로 해석되며 정확한 endpoint 매핑(method/path/auth/envelope/mobile vs admin)을 makeplan이 직접 routes.rb를 파싱해야 한다.

**개선 방안**: Scope § 영역 식별 표 5 또는 파일 목록 표 옆에 **32 endpoints 인벤토리**(controller#action × 8 컬럼)를 1회 고정. makeplan agent는 이를 입력으로 받아 즉시 endpoint별 plan step 작성 가능.

근거: `/Users/kampikrein/A/personality/server/config/routes.rb`, `/Users/kampikrein/A/personality/server/app/controllers/`, `/Users/kampikrein/A/personality/server/app/controllers/admin/`.

### W2 (Critical) — Scope 본문 "18 ERB" 수치 오류

Scope 026 본문(여러 위치):
- § Cycle 6 note: "9 ERB admin → Hono SSR vanilla. 18 ERB + 8 Stimulus 공개 평가 흐름"
- § 영역 식별 표 6: "9 ERB admin + 18 ERB 공개 평가 + 8 Stimulus"
- § 파일 목록 추정 Cycle 6: "Reviewed: server/app/views/assessments/*.erb(18)"

실 검증 결과:
- 공개 ERB 13개 (layouts/pwa 제외): assessments/show, deletion_requests/{show,new}, consents/new, results/{show, _spectrum, _insight_card, _type_hero, _trust_notice}, sessions/new, accounts/new, assessment_questions/{show, _question}.
- 명령: `find server/app/views -name "*.erb" -not -path "*/admin/*" -not -path "*/layouts/*" -not -path "*/pwa/*"` → 13.

Brief 021/Synthesis 018에서 "R3 정정 18 ERB" 표기가 어느 정의인지 추적 필요(layouts 4 포함하면 17, pwa 1 포함하면 18 가능 — 실수 가능). 어느 쪽이든 Scope 본문 수치는 makeplan 입장에서 그대로 인용 시 4-5건 추가 ERB를 "찾아야" 한다는 false signal.

**개선 방안**: Scope에서 정확한 ERB 인벤토리 13건을 fileslist로 고정. layouts/pwa는 별도 분류(SSR layout 1건 + manifest.json.erb는 정적 파일).

근거: `/Users/kampikrein/A/personality/server/app/views/`.

### W3 (Major) — Cycle 3 saga Phase A-E 의사코드 위임처 불명

Scope 026 Cycle 3 note: "scoring 8단계 Pure Saga (Phase A-E forward-recovery, step 7 UPSERT)" + makeplan 입력 표: "R2 (Pure Saga, 7/8 idempotent, Phase A-E, ~150 LOC)".

문제: Phase A-E의 step 분할 자체가 Synthesis 018 R2-F에 정의되어 있어야 makeplan이 인용 가능하나, Scope 026은 "150 LOC"만 인용. 8단계의 어느 step이 A/B/C/D/E에 해당하는지(예: A=Response 읽기, B=DomainScore 계산+UPSERT, ...)는 R2-F 또는 별도 부록에 의사코드로 고정 필요.

**개선 방안**: Scope § Cycle 3 makeplan 입력 옆에 8단계 → Phase A-E 의사코드 (5-10 LOC 다이어그램) 인용. 또는 Synthesis 018 R2-F의 정확한 § 번호 + 인용 페이지 표시.

근거: Scope 026 § Cycle 3, Brief 021 Decision 5, Synthesis 018 (전체 read 필요).

### W4 (Major) — Cycle 4 컴포넌트 인터페이스 미정의

Scope 026 Cycle 4 파일 목록: 6 lib + 5 middleware + ≥6 tests. M1 (JWKS resolver DI 패턴)만 critique 보강으로 인용. 다른 컴포넌트:
- `betterauth.ts` — init param (D1 driver, KV namespace, secret env, hooks)
- `cf_access_verifier.ts` — verifier(jwt: string, opts) → Result<Claims, Err>
- `encryption.ts` — encrypt(plain, version) / decrypt(envelope) / wireFormat
- `email_hash.ts` — hashEmail(email, secret) → string
- `session.ts` — KV TTL, cookie 발급 (BC1 격리 적용)
- `key_rotation.ts` — Phase enum + readKey(envelope) / writeKey(plain) dual-read

이 6 컴포넌트 모두 Scope에서 인터페이스가 결정되지 않으면 makeplan이 직접 결정 → cycles 5/6/8에서 호출부와 mismatch 위험.

**개선 방안**: Scope § Cycle 4 makeplan 입력 표를 확장하여 6 컴포넌트의 export signature 1-line씩 명시 (예: `cf_access_verifier.ts: makeVerifier(opts: {jwksFetcher, aud, issuer}) -> (jwt) => Promise<Claims>`).

### W5 (Major) — Cycle 8 14세 미만 흐름 외부 의존성 미결정

Scope 026 Cycle 8 note: "5 흐름: consent 수집·철회, 계정 삭제, audit log, 국외 이전 고지·동의, 14세 미만." Brief 021 Ideal Criterion #23도 "5 흐름 모두 구현".

문제: 14세 미만 처리는 한국 PIPA에서 **법정대리인 동의 + 본인 확인** 필요. 본인 확인은 일반적으로 KYC API(나이스/SCI 등) 외부 의존. Phase 1은 외부 자원 미접촉 제약 → 14세 미만 흐름은 (a) Phase 2로 이연, (b) Phase 1에서 stub-only(나이 입력 + 차단 메시지), (c) Phase 1에서 부모 이메일 동의 only(외부 KYC 없이) 중 어느 것?

Scope/Brief에 결정 부재 → makeplan agent가 결정 부담을 떠안음.

**개선 방안**: Brief 021에 Decision 항목 추가하거나 Scope § Cycle 8 note에 "14세 미만은 stub-only — KYC 외부 API는 Phase 2"로 명시.

### W6 (Major) — verify 단계 Ideal Criteria trace 부재

Brief 021 Ideal Criteria 28개. 사이클별 verify가 어느 criterion 검증하는지는 verify agent가 ad-hoc mapping해야 함. 추론 가능하나(예: #1-#3 → Cycle 1, #4-#8 → Cycle 2 등) 명시 부재 시 누락 위험.

**개선 방안**: Scope § 사이클별 makeplan 입력 표 옆에 "verify에서 검증할 Ideal Criteria #" 컬럼 1개 추가.

### W7 (Minor) — Cycle 1 cron handler stub-only 패턴 부재

Critique 023 M5: "Plan 020 Step 8 D1 cron handler stub-only로 변경". Scope 026 § 사이클별 makeplan 입력 Cycle 1: "Plan 020 Step 8 cron handler를 stub-only로 변경 (M5)".

stub-only가 정확히 무엇인지(빈 handler 함수만 export? Phase 2 marker 주석? 1Password reference?)는 Scope에 명시 부재.

**개선 방안**: stub 패턴 1-line 의사코드 추가 — `export const scheduled = async (event, env, ctx) => { /* TODO Phase 2 — D1 export */ };`.

### W8 (Minor) — tdd-red agent 도구 버전 입력 부재

Brief 021 § 2.4: vitest-pool-workers ≥0.7.x, drizzle-kit ≥0.28.x 등. Scope 026 § 사이클별 makeplan 입력 표는 도구 버전 컬럼 부재. tdd-red agent가 fixture 작성 시 vitest version 호환 확인 필요.

**개선 방안**: 사이클별 입력 표에 "tooling" 컬럼 추가 또는 Brief 021 § 2.4 직접 인용 표시.

### W9 (Minor) — Cycle 6 ERB-by-ERB 매핑 표 부재

ME2 동일. Cycle 6 makeplan은 admin 9 + public 13 = 22 ERB를 1:1로 Hono SSR route + TSX 컴포넌트로 분해해야 하나 Scope에 매핑 표 부재. + Stimulus 8 → hx-boost 또는 client-side 결정.

**개선 방안**: ME2 표를 Scope § 영역 식별 표 6 또는 Cycle 6 makeplan 입력 옆에 추가.

## Recommendations (우선순위)

| 우선순위 | 권고 | 영향 사이클 | 수정 위치 |
|---------|------|----------|----------|
| **P1** | Scope 본문 ERB 수치 13으로 정정 + 13개 파일 인벤토리 명시 (W2) | 6 | § Cycle 6 note, § 영역 식별 표 6, § 파일 목록 표 |
| **P1** | Cycle 5 32 endpoints 인벤토리 표 추가 (ME1) | 5 | § 영역 식별 표 5 보조 |
| **P2** | Cycle 6 ERB-by-ERB 매핑 표 (admin 9 + public 13) (ME2, W9) | 6 | § Cycle 6 보조 |
| **P2** | Cycle 3 saga Phase A-E 의사코드 (ME4, W3) | 3 | § Cycle 3 note 또는 부록 |
| **P2** | Cycle 4 6 컴포넌트 export signature 1-line 명시 (W4, ME5) | 4 | § Cycle 4 makeplan 입력 |
| **P2** | Cycle 8 14세 미만 흐름 결정 (Phase 1 stub vs Phase 2) (W5, ME6) | 8 | Brief 021 Decision 추가 또는 Scope Cycle 8 note |
| **P3** | 사이클 × Ideal Criteria 매핑 컬럼 추가 (W6, ME7) | 전 사이클 | § 사이클별 makeplan 입력 |
| **P3** | Cycle 3 services 20개 1:1 매핑 표 (ME3) | 3 | § Cycle 3 보조 |
| **P3** | tdd-red 도구 버전 입력 컬럼 (W8, ME8) | 2-6, 8 | § 사이클별 makeplan 입력 |
| **P3** | Cycle 1 cron handler stub-only 패턴 의사코드 (W7) | 1 | § Cycle 1 makeplan 입력 |

P1 2건만 적용해도 Cycle 5/6 진입 가능. P2 4건 추가 시 7 사이클 모두 즉시 makeplan 가능.

## References

- Scope 026 (target): `/Users/kampikrein/A/personality/docs/6_backend/02_cf_workers_rebuild/026_Scope_conversion_phase1.md`
- Brief 021: `/Users/kampikrein/A/personality/docs/6_backend/02_cf_workers_rebuild/021_Brief_conversion_phase1.md`
- Plan 020 (Cycle 1 표본): `/Users/kampikrein/A/personality/docs/6_backend/02_cf_workers_rebuild/020_Plan_cycle1_foundation.md`
- Synthesis 018 (R2-F, S-018-F1/F2/F6): `/Users/kampikrein/A/personality/docs/6_backend/02_cf_workers_rebuild/018_Synthesis_research_cycle.md`
- Synthesis 025 (Brief 021 critique 통합): `/Users/kampikrein/A/personality/docs/6_backend/02_cf_workers_rebuild/025_Critique_Synthesis.md`
- 실 코드 인벤토리 검증:
  - `/Users/kampikrein/A/personality/server/config/routes.rb` (32 endpoints)
  - `/Users/kampikrein/A/personality/server/app/controllers/` (8 top-level + 5 admin = 13)
  - `/Users/kampikrein/A/personality/server/app/services/` (20 .rb)
  - `/Users/kampikrein/A/personality/server/app/views/admin/*.erb` (9)
  - `/Users/kampikrein/A/personality/server/app/views/{assessments,results,sessions,accounts,consents,deletion_requests,assessment_questions}/*.erb` (13 public, layouts/pwa 제외)
  - `/Users/kampikrein/A/personality/server/app/javascript/controllers/*_controller.js` (8)
  - `/Users/kampikrein/A/personality/server/spec/**/*_spec.rb` (18)

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
