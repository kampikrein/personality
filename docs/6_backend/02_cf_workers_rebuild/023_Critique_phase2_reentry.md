---
id: "023"
type: critique
title: "Brief 021 Critique — Phase 2 재진입 가능성"
created: 2026-04-29
status: completed
perspective: "phase2_reentry"
target: "021"
confidence: medium
summary: >
  Brief 021은 Phase 2 deferred 항목 11건의 재진입 조건을 표 한 줄씩 명시했지만, **재진입 입력으로
  Phase 1 산출물이 그대로 사용 가능한지에 대한 검증 메커니즘은 directional Criterion 27 단 한 줄**로
  남아있다. Toss BC2/BC3 정정의 보존 위치, Plan 020의 cron/scheduled handler가 wrangler dev --local
  에뮬레이션과 production에서 갈라지는 지점, server/ Ruby 자산의 시간 함수 부패, pipeline DB의
  Cycle 7/9/10 deferred 표기 부재 등 **구체적 conflict 4건**이 식별됨. 종합: 재진입 호환성은
  '의도'로는 명시됐으나 '실측 가능한 보장'은 미정의 — Phase 1 시작 전 보강 권고 4건.
keywords: [critique, brief-021, phase-2, reentry, deferred-items, compatibility]
---

# Brief 021 Critique — Phase 2 재진입 가능성

## Executive Summary

Brief 021은 Phase 1을 "Rails → TypeScript 전환 집중"으로 좁히고 11 항목을 Phase 2로 deferred 처리했다. 본 비평의 관심사는 **deferred 항목들이 Phase 2 시점에 Phase 1 산출물을 입력으로 그대로 활용 가능한가** 이다.

검증 결과:

1. **명시적 강점**: Decision 11(BC2/BC3 보존), Decision 14(pipeline DB 재진입), Anchor 17(재진입 호환성), Criterion 27(directional)이 재진입을 의식적으로 다룸. Brief 001 frozen anchor 유지로 결정 재논의 차단.
2. **Critical 1건**: pipeline DB 실제 상태와 Brief 021 Anchor 12 선언이 **불일치** — Cycle 7/9/10이 DB에서 여전히 `pending`으로 남아 있어 Phase 1 진행 중 No-Stop 모드에서 활성 디스패치 위험.
3. **Major 3건**: ① Plan 020 Step 8(D1 cron + scheduled handler)이 외부 자원에 강하게 결합되어 있어 wrangler dev --local에서 검증 불가 영역이 누적; ② BC2/BC3가 Brief 021 Decision 11에만 inline 1줄로 보존 — Phase 2 Brief 022 작성 시 누락 위험; ③ server/ 디렉토리는 git log 기준 2026-03-15 이후 미수정이라 Phase 1 정책상으로는 안전하나, Brief 001 Critique 004 W1(Ruby/gem/SQLite 호환성 부패)은 시간 함수 — Phase 1 20 MAN-DAY 동안 부패 누적은 막을 수 없음.
4. **Minor 2건**: ① Phase 2 cutover에서 wrangler dev 에뮬레이션 동등성 검증 비용이 누적; ② CF Access verifier 코드만 작성 → SSO 연결 시 fixture JWT 의존성 conflict 가능성.

**합계 severity**: Critical 1, Major 3, Minor 2 (총 6건). 종합적으로 재진입 호환성은 **medium** 신뢰도.

## Strengths

1. **Brief 001 frozen anchor 명시 유지** (Anchor 1, Decision 1) — Phase 2 시점에 결정 재논의 차단, 13 Decisions 그대로 승계. Phase 2 Brief 022 작성 시 Phase 1 결정의 재논의가 발생하지 않음.

2. **deferred 11 항목별 재진입 조건 표 (§ Boundaries / Out of Scope #1-10)** — Phase 2 진입 시 트리거가 무엇인지(예: "Toss merchant 등록", "외부 deploy 후") 명시. ad-hoc 재진입 결정 차단.

3. **BC2/BC3 보존 결정 (Decision 11)** — Synthesis 정정사항이 Phase 1에서 코드로 작성되지 않음을 명시(`Phase 1에서 Toss 코드 0 작성`)하여 Phase 1 산출물에 대한 모순(Toss 미들웨어가 Phase 1 코드 안에 섞임) 차단. Anchor 10이 이를 강제.

4. **Pipeline DB 재사용 결정 (Decision 14)** — research+eval 완료 history 손실 방지. Phase 2 재진입 시 새 cycle을 같은 DB에 추가 가능하도록 설계됨.

5. **Anchor 17 (Phase 2 재진입 호환성 보존)** — "본 Phase 산출물(코드, schema, 테스트, runbook)은 Phase 2 Toss/Cutover 작업의 입력으로 그대로 사용 가능해야 함" 선언. archive 호환 변환 스크립트는 Phase 2에서 작성 명시.

6. **Synthesis Cycle 9 산출물 보강(분리 컬럼 → Rails 단일 컬럼 변환 스크립트)이 Phase 2 인풋으로 명시 보존됨** — Phase 2 cutover safety 작업이 Phase 1의 R4 schema 결정을 입력으로 사용 가능.

## Weaknesses

| # | Finding | Severity | Evidence | Recommendation |
|---|---------|----------|----------|----------------|
| W1 | **Pipeline DB 실제 상태와 Brief 021 Anchor 12가 불일치** — Anchor 12는 "Cycle 7/9/10은 deferred 표기"라 선언하나, `tmp/007_cf_workers_rebuild_1c64.db` checklist 테이블에서 cycle 7/9/10의 모든 step이 여전히 `status='pending'`. `pipeline.sh next`가 Cycle 6 완료 후 Cycle 7(Toss)으로 자동 디스패치할 위험. status enum에 'deferred'가 없어 단순 표기조차 불가능 (`CHECK(status IN ('pending','in-progress','done','interrupted','partial'))`). | **Critical** | DB schema: `CHECK(status IN ('pending','in-progress','done','interrupted','partial'))` — 'deferred' 미존재. 실측 cycle 7/9/10 = pending. Brief 021 Anchor 12 vs DB 상태 모순. | Phase 1 시작 직전: ① schema에 'deferred' status 추가 마이그레이션, ② Cycle 7 step 35-38, Cycle 9 step 43-45, Cycle 10 step 46-51을 'deferred'로 표기. 또는 ③ 우회책: `status='partial'` + meta 메모로 deferred 명시 후 `pipeline.sh next`가 partial을 skip하도록 보강. Brief 021에 이 표기 작업을 Cycle 1 implementation 첫 step으로 명시 필요. |
| W2 | **Plan 020 Step 8 (D1 cron + scheduled handler)이 wrangler dev --local에서 검증 불가** — `apps/workers/src/scheduled/d1-backup.ts` 파일 작성 + `wrangler.toml [triggers] crons` 등록 + `export { scheduled }`까지 Phase 1에 포함되나, miniflare가 cron trigger 일부를 에뮬레이션하지 못하고 R2 binding 백업 결과는 production에서만 검증됨. Plan 020 § Step 8 자체가 "Cycle 9에서 dry-run 시행, 본 Cycle은 절차 문서화만"이라 명시 — 즉 Phase 1에서 작성하는 코드는 verify 통과한 적 없는 dormant code가 됨. Phase 2 Cycle 9/10 진입 시 이 코드는 production D1과 첫 결합으로 회귀 위험 노출. | Major | Plan 020 line 951-952 ("Cycle 1 시점엔 D1에 테이블이 없을 수 있음 — handler는 0건도 정상 처리"), line 957 ("실제 dry-run은 Cycle 10 cutover safety에서 시행, 본 Cycle은 절차 문서화만"), line 995 (Cascade: Cycle 9·10에서 사용). Brief 021 Decision 12 "production-only 회귀(D1 read replication latency 등) Phase 1에서 미발견" 자인. | ① Brief 021 Out of Scope에 "D1 자동 export → R2 cron"을 #7로 분리(현재 Out of Scope #4 production monitoring에 묻혀있음 — 명시 필요), ② Plan 020 § File Change Summary의 `apps/workers/src/scheduled/d1-backup.ts` + `wrangler.toml [triggers]`를 Phase 1 산출물에서 stub-only로 격하(comment-only or `throw new Error("phase 2")`), ③ Cycle 9 Phase 2 재진입 시 첫 step에 "Phase 1 dormant code 회귀 검증" 명시. |
| W3 | **BC2/BC3 보존 메커니즘이 Brief 021 Decision 11 inline 1줄에만 의존** — Synthesis 018에서 정정된 webhook 모델 이중화(BC2)와 idempotency key 정확 명칭 `tosspayments-webhook-transmission-id`(BC3)는 Phase 2 Brief 022 작성 시 Brief 022 작성자(에이전트 또는 미래 사용자)가 Synthesis 018 + Brief 021 Decision 11 + Anchor 10을 모두 cross-reference 해야 발견 가능. 별도 deferred 노트 파일도 없고 Phase 2-feed forward 인덱스도 없음. Synthesis 018의 5 OQ carryover도 동일 — Cycle 7 OQ-3(웹훅 모델 B dormant 코드 작성 여부)이 Phase 2 makeplan에서 누락 위험. | Major | Brief 021 Decision 11 / Anchor 10 / Criterion 27 모두 BC2/BC3가 "Phase 2 Brief 022 입력"임만 명시. 별도 보존 노트 파일 부재. Synthesis 018 OQ-3는 Brief 021에서 미참조. | Phase 2 entry 인덱스 문서 신규 작성 권고: `docs/6_backend/02_cf_workers_rebuild/022a_Phase2_Inputs.md` 또는 Brief 021 § "Phase 2 Carryover Inputs" 섹션 추가. 다음을 한 곳에 인덱싱: ① BC2 webhook 이중 모델 출처 (Synthesis 018 § 3 BC2), ② BC3 idempotency key 정확 명칭 (Synthesis 018 § 3 BC3), ③ Cycle 9 Phase rollback 산출물 보강(Synthesis 018 § 4), ④ 5 OQ carryover (Retro 019). Brief 022 작성 skill이 단일 진입점을 Read하면 됨. |
| W4 | **server/ Ruby 자산 부패는 시간 함수 — Phase 1 read-only 정책으로도 차단 불가** — Brief 001 Critique 004 W1이 지적한 "archive 보존만으론 회귀 불가, Ruby 버전·gem·SQLite 호환성 부패"는 Phase 1이 server/를 read-only 처리해도 진행됨. git log 기준 server/ 마지막 수정 = 2026-03-15(약 6주 전). Phase 1 20 MAN-DAY + Phase 2 추가 기간 동안 RubyGems yanked, Bundler lock incompat, Rails 8.1 → 8.2 패치 불호환 등이 발생할 수 있음. Brief 021 Anchor 11 "archive Rails read-only"는 부패 자체를 막지 못함. | Major | Brief 001 Critique 004 § A.2 W1 5가지 검증 항목(Ruby/gem/Kamal/데이터/encryption key). server/Gemfile.lock = Rails 8.1.2 + Ruby 의존성 lock. Phase 1 동안 보안 패치된 Ruby 메이저 버전 발표 가능성 + bundler가 yanked gem fetch 실패 가능성. Brief 021 Out of Scope #2 "archive smoke test"가 Phase 2로 deferred되어 Phase 1 동안 부패 검증 0회. | ① Brief 021 Constraints에 "Phase 1 시작 시점 server/ Bundle install + RSpec 1회 가동(시간 t0 baseline)" 추가, ② 결과를 `docs/6_backend/02_cf_workers_rebuild/0XX_Memo_archive_baseline.md`에 기록(Ruby 버전, bundle install hash, rspec 통과 수). Phase 2 Cycle 9 archive smoke test 진입 시 t0 baseline 대비 부패 분량을 측정 가능. 비용 1 MAN-HOUR 이내. |
| W5 | **wrangler dev --local 의존이 Phase 2 cutover 동등성 검증 비용을 누적** — Brief 021 Decision 2 trade-off 자인: "wrangler 에뮬레이션이 production D1과 100% 동등하지 않음 (read replication latency 등 실측 불가)". Phase 1의 28 Ideal Criteria 중 #1-25는 모두 wrangler dev --local 또는 vitest-pool-workers 베이스. Phase 2 cutover 시점에 production D1 첫 노출에서 회귀 발견 가능성 — 발견된 회귀 1건당 Phase 1 산출물 재작업 발생. R3 D1 read replication beta + R7 D1 단일 스레드 + R12 interactive transaction 부재의 production-only 양상이 Phase 2에 누적. | Minor | Brief 001 R-risk 매핑 R3/R7/R12. Brief 021 Decision 12 "production 동등성 검증은 Phase 2 cutover safety가 담당" 명시. Plan 020 Step 8이 대표 사례. | Brief 021에 추가 권고: ① Phase 1 Cycle 3 saga 검증 시 R2 권고 외에 "real D1 read-after-write 재현 fixture" 작성(@cloudflare/vitest-pool-workers v0.5+ 부분 지원), ② Brief 022 (Phase 2)의 첫 cycle을 "production 동등성 검증" cycle로 정의 — Phase 1 산출물의 회귀 catch가 Phase 2 작업의 첫 단계임을 명시. |
| W6 | **CF Access verifier "코드만" 상태가 Phase 2 SSO 연결 시 fixture JWT 의존성 conflict 가능** — Brief 021 Decision 7 + In Scope 5 + Anchor 8: "CF Access JWT 검증 미들웨어 (admin SSO를 가정한 verifier 코드만 — 실 SSO 연결은 Phase 2)". Phase 1에서 verifier unit test는 fixture JWT(직접 서명)로 통과시키나, Phase 2에서 실 CF Access JWT는 (a) issuer URL이 다름, (b) signing key 회전, (c) team domain 종속, (d) `cf-access-authenticated-user-email` 헤더 검증 필요. fixture가 실 발급 JWT의 모든 claim 구조를 포함하지 못하면 Phase 2 SSO 연결 시 verifier 재작성 필요. | Minor | Brief 021 In Scope 5 / Decision 7 / Anchor 8. Plan 020에 verifier 구체 코드는 Cycle 4로 위임, 본 Plan에는 미정의. | ① Phase 1 Cycle 4 makeplan에서 verifier fixture JWT가 실 CF Access JWT 사양(`https://<team>.cloudflareaccess.com/cdn-cgi/access/certs` JWKS, audience tag, `email` + `identity_nonce` claim)을 충실히 모방하도록 강제(R4 보고서 참조), ② Brief 021 Anchor 8에 "verifier fixture는 실 CF Access JWT spec 1:1 반영" 한 줄 추가. |

## Missing Elements

| # | What's Missing | Why It Matters | Suggestion |
|---|----------------|----------------|------------|
| ME1 | **Phase 2 진입 트리거 구체화 부족** — Brief 021 § Boundaries Out of Scope의 "Phase 2 재진입 조건" 컬럼은 "사용자 진행 의사", "외부 deploy 후" 등 추상적. Phase 2 시작에 필요한 검증 가능한 조건(예: "Phase 1 Ideal Criteria 26개 assertion + 2 directional 통과 확인 자료") 부재. Phase 1 완료가 자동으로 Phase 2 시작이 아니므로, Phase 2 시작 게이트 정의 필요. | Phase 2 시작 시점에 Phase 1 산출물 회귀 점검 누락 가능. | Brief 021 § Exit Criteria에 "Phase 2 entry checklist" 추가: ① Phase 1 Ideal Criteria 28개 verify 결과, ② BC2/BC3/OQ carryover 인덱스 점검, ③ server/ baseline t0 vs t1 비교. |
| ME2 | **Phase 1 산출물 인벤토리 부재** — Brief 021은 활성 9 In Scope를 정의하나, Phase 1 종료 시점에 어떤 파일이 생성되어 Phase 2 입력으로 들어가는지 인벤토리 표가 없음. Plan 020은 Cycle 1만 다룸. Cycle 2-8 file tree는 makeplan 단계에서 결정됨. Phase 2 Brief 022 작성자는 Phase 1 commit 결과를 직접 grep해야 함. | Phase 2 Brief 022 작성 시 Phase 1 산출물 import 경로/이름이 ad-hoc 결정되면 Brief 022 ↔ Phase 1 코드 mismatch 발생. | Brief 021 종료 직후 Retrospective(Cycle 99 retro) 에 "Phase 1 출력 파일 트리 인벤토리" 산출물 명시. 또는 Phase 1 마지막 cycle(8 Compliance) verify에 "전체 src 트리 dump" step 추가. |
| ME3 | **Phase 2 Brief 022 작성 트리거 부재** — Brief 021은 "Phase 2 재진입 시 Brief 001 + 본 Brief 021 + (작성 예정) Brief 022가 함께 anchor"라 명시하나, Brief 022 작성을 누가/언제 트리거하는지 미정의. Phase 1 완료 자동 트리거인지, 사용자 별도 명령(`/brief --phase 2`)인지 불명확. | Phase 1 완료 후 Phase 2 진입 사이에 "공백 기간"이 발생하면 server/ 부패(W4)가 그동안 누적. | Brief 021 § Next Steps(현재 미존재) 또는 Exit Criteria에 "Phase 1 완료 → Cycle 99 retro → 즉시 `/brief cf_workers_rebuild_phase2` 트리거" 명시. |
| ME4 | **archive 부패 baseline 측정 step 부재** — W4 보강. Brief 001 Critique 004 § A.2가 5가지 검증 항목을 제시했으나, 그 중 어느 것이 Phase 1 시작 시점에 측정되어야 하는지 Brief 021에 미명시. | Phase 2 Cycle 9 archive smoke test에서 부패 정도를 측정할 baseline 부재. | Brief 021 Constraints에 "Phase 1 시작 시 server/ Ruby 환경 baseline 측정(bundle install + rspec 1회)" 추가. |

## Detailed Analysis

### A. deferred 11 항목별 재진입 매트릭스

| Out of Scope # | 재진입 조건 (Brief 021 명시) | Phase 1 산출물 영향 | Conflict 위험 | 비고 |
|----------------|--------------------------|------------------|---------------|------|
| 1 Toss 결제 | Toss merchant + 사용자 결정 | Anchor 10 "Toss 코드 0" 강제 → 충돌 0 | Low | Decision 11 BC2/BC3 보존 OK. W3 Phase 2 인덱싱 부재만 보강 필요. |
| 2 Cutover safety | Phase 1 완료 + 외부 환경 | Synthesis Cycle 9 deliverable 보강(분리 컬럼 변환 스크립트) Phase 2에 carryover | Low | OK |
| 3 Cutover execution | Phase 1 완료 + 사용자 결정 | wrangler dev 의존 → W5 누적 | Medium | W5 권고 적용 시 Low |
| 4 Production monitoring | 외부 deploy 후 | Plan 020 Step 8 cron + scheduled handler가 Phase 1 산출물에 포함 → W2 dormant code | High | W2 권고 적용 필요 |
| 5 Foundation 외부 자원 | 사용자 작업 | wrangler.toml stub(placeholder ID) → Phase 2 실 ID 치환만 필요. 깔끔 | Low | OK |
| 6 CF Access 실 SSO | Phase 2 | verifier 코드만 작성 → W6 fixture mismatch 위험 | Medium | W6 권고 적용 시 Low |
| 7 D1 자동 export R2 cron | Phase 2 (Out of Scope #4 일부) | Plan 020에 작성됨 — 실제로는 Out of Scope #4와 중복 | Medium | W2 권고와 동일 적용 |
| 8 Rails archive 이동 | Phase 1 완료 후 | server/ read-only → 시간 함수 부패 진행 | Medium | W4 baseline 측정 권고 |
| 9 글로벌 결제 (Stripe) | 해외 법인/Stripe Korea | Phase 1 산출물 무관 | None | OK |
| 10 새 도메인 기능 | 별도 phase | Phase 1 산출물 무관 | None | OK |
| 11 (deferred_items 중복) | — | — | — | Out of Scope 표와 deferred_items 표가 부분 중복 |

종합: 11 항목 중 **W2/W4/W6 적용 대상 4개**가 Phase 1 산출물 ↔ Phase 2 작업 충돌 위험을 갖고 있다. 나머지 7개는 의도된 분리로 깔끔.

### B. Pipeline DB 상태 검증

`tmp/007_cf_workers_rebuild_1c64.db` 실측:

```
12|1|0|makeplan|done|impl
13|1|0|implementation|pending|impl
...
35|7|0|tdd-red|pending|impl     ← 활성 상태
36|7|0|makeplan|pending|impl
37|7|0|implementation|pending|impl
38|7|0|verify|pending|impl
...
43|9|0|makeplan|pending|impl    ← 활성 상태
44|9|0|implementation|pending|impl
45|9|0|verify|pending|impl
46|10|0|makeplan|pending|impl   ← 활성 상태
...
51|10|0|push|pending|impl
52|99|0|retro|pending|impl
```

Brief 021 Anchor 12 "사이클 7(Toss) + 9(cutover safety) + 10(cutover execution)은 deferred 표기" 선언과 실측 상태 불일치. checklist 테이블 status enum도 'deferred' 미포함.

이는 **W1 Critical**의 근거. Phase 1 시작 시 첫 implementation step이 cycle 7/9/10/99의 모든 row를 'partial' 또는 신규 'deferred' status로 표기하는 마이그레이션을 수행해야 한다.

### C. BC2/BC3 추적 경로

Synthesis 018에서 정정된 3건 중 BC1(cookie 격리)은 Phase 1 Cycle 1 cookie-policy.ts에 즉시 반영(Plan 020 Step 2). BC2/BC3는 Phase 2 carryover.

현 상태에서 BC2/BC3를 발견하려면:
1. Brief 022 작성자가 Brief 021 Decision 11 또는 Anchor 10을 Read
2. → Synthesis 018 § 3 BC2/BC3 Read
3. → Toss 공식 docs cross-check

3-hop 추적 경로. Synthesis 018 전체를 Read해야 OQ-3 (Cycle 7 webhook 모델 B dormant 코드) 등 5 OQ carryover도 함께 발견됨.

권고: Brief 021에 "Phase 2 Carryover Inputs" 섹션을 신규 추가하여 BC2/BC3/OQ-1~5를 한 곳에 인덱싱(W3 권고).

### D. Plan 020 Step 8 dormant code 분석

Plan 020 § Step 8(D1 자동 backup → R2 cron):
- 산출 파일: `apps/workers/src/scheduled/d1-backup.ts`, `wrangler.toml [triggers] crons = ["0 17 * * 0"]`
- `apps/workers/src/index.ts` 마지막 줄에 `export { scheduled } from "./scheduled/d1-backup";`
- Plan 020 line 957: "실제 dry-run은 Cycle 10 cutover safety에서 시행, 본 Cycle은 절차 문서화만"
- Plan 020 line 995 Cascade: "Cycle 9(cutover safety)가 본 backup을 분기 1회 복원 dry-run 대상으로 사용"

문제:
- Phase 1에서 `scheduled` handler 코드가 작성되나 verify에서 검증되지 않음
- Phase 2 Cycle 9/10 진입 시 이 dormant code가 첫 production 노출 — 다른 Phase 1 코드와 달리 wrangler dev 또는 vitest로 동등성 검증된 적 없음
- Brief 021 Out of Scope #4(Production monitoring)와 #7(D1 자동 export R2 cron)이 Out of Scope 표에서 분리 명시되지 않음 — Anchor 12에는 "사이클 7+9+10 deferred"만 표기, scheduled handler는 Cycle 1 산출물

권고(W2): scheduled handler를 Phase 1에서 stub-only(`throw new Error("activated in Phase 2")`)로 격하 또는 `apps/workers/src/scheduled/d1-backup.ts` 파일 자체를 Phase 2로 이동.

### E. server/ 시간 함수 부패

`git log -1 -- server/` = 2026-03-15. Phase 1 시작(가정 2026-04-29) → +6주. Phase 1 20 MAN-DAY + Phase 2 진입 지연 가능.

Brief 001 Critique 004 W1 5 검증 항목:
1. Ruby 버전 호환 (현 8.1.2)
2. gem dependency (yanked gem 위험)
3. Kamal 배포 인프라
4. 데이터(D1 → SQLite 변환)
5. 결제 webhook 이력

Phase 1 정책상 server/ read-only는 2,3,4,5 영역 부패를 막지 못함(외부 환경 함수). 1,2는 Bundler.lock 환경 변경 시 발생.

권고(W4): Phase 1 시작 시점에 1회 baseline 측정 → Phase 2 Cycle 9 비교 baseline.

## Recommendations

### Brief 021 직접 보강

| # | 권고 | 위치 | 우선순위 |
|---|------|------|----------|
| R1 | **Pipeline DB schema에 'deferred' status 추가 + cycle 7/9/10 표기 마이그레이션을 Cycle 1 implementation 첫 step으로 명시** | Anchor 12 + Cycle 1 Plan 020 보강 | Critical |
| R2 | **Phase 1 Out of Scope에 "D1 자동 export → R2 cron의 scheduled handler 코드"를 명시 분리 + Plan 020 Step 8 산출물을 stub-only로 격하** | Brief 021 § Boundaries Out of Scope 표 + Plan 020 § File Change Summary | Major |
| R3 | **Phase 2 Carryover Inputs 섹션 신규 추가** (BC2/BC3/Cycle 9 deliverable/OQ-1~5 인덱싱) | Brief 021 신규 섹션 | Major |
| R4 | **server/ baseline t0 측정 step Constraint 추가** | Brief 021 § Constraints | Major |
| R5 | **CF Access verifier fixture JWT가 실 spec 1:1 반영** | Brief 021 Anchor 8 또는 Cycle 4 makeplan 강제 | Minor |
| R6 | **Phase 2 entry checklist + Brief 022 작성 트리거 명시** | Brief 021 § Exit Criteria 또는 Next Steps 신규 섹션 | Minor |

### scope/plan/implementation 위임 (Brief 갱신 불필요)

| # | Item | Phase |
|---|------|-------|
| S1 | Cycle 4 verifier fixture JWT를 R4 보고서 sample claim 구조에 맞춰 작성 | Cycle 4 makeplan |
| S2 | Cycle 8 Compliance verify에 "Phase 1 출력 파일 트리 인벤토리 dump" step 추가 | Cycle 8 makeplan |
| S3 | Cycle 99 retro에 Phase 2 Brief 022 작성 트리거(`/brief --phase 2`) 명시 | Cycle 99 retro skill |
| S4 | Phase 1 Cycle 3 saga 검증에 "real D1 read-after-write 재현 fixture" 추가 | Cycle 3 makeplan |

### 비평 외부 영역 (다른 비평 관점에 의존)

- **Conversion fidelity 차원** (RSpec 18개 → Vitest 1:1 동등성 메커니즘 자체의 견고성)
- **Scope 균형** (활성 9 In Scope의 균형, 20 MAN-DAY 추정 정확도)
- **Security baseline** (CORS/CSP/HSTS/rate limit/CSRF 미들웨어 구현 상세)

본 비평은 위 영역과 중복하지 않도록 Phase 2 재진입 호환성에만 집중.

## References

| Resource | Path | Relevance |
|----------|------|-----------|
| Brief 021 (target) | `./021_Brief_conversion_phase1.md` | 비평 대상 |
| Brief 001 (frozen anchor) | `./001_Brief_cf_workers_rebuild.md` | 13 Decisions 승계 검증 |
| Synthesis 018 | `./018_Synthesis_research_cycle.md` | BC1/2/3 정정사항 + Cycle 9 deliverable 보강 |
| Critique 004 (Risk) | `./004_Critique_risk.md` | W1 archive 부패, A.2 5 검증 항목 |
| Plan 020 (Cycle 1) | `./020_Plan_cycle1_foundation.md` | Step 8 dormant code, U1-U8 외부 자원 |
| Pipeline DB | `tmp/007_cf_workers_rebuild_1c64.db` | checklist 실측 (cycle 7/9/10 status=pending) |
| server/ git log | `2026-03-15 16:31:05` last commit | 시간 함수 부패 baseline |
| Brief 001 In Scope 9 (Toss) | Brief 001 line 90 | BC2/BC3 정정 대상 원문 |
| Brief 001 In Scope 12-15 (cutover) | Brief 001 lines 93-96 | Phase 2 재진입 대상 |

## Communication Log

| # | Direction | Peer | Summary | Stage |
|---|-----------|------|---------|-------|
| 1 | ← | Brief 021 | Decision 11/14, Anchor 17, Out of Scope 10항, Criterion 27 입력 | Cycle 비평 |
| 2 | ← | Brief 001 | frozen anchor 13 Decisions, Critical Review Request 입력 | Cycle 비평 |
| 3 | ← | Synthesis 018 | BC1/2/3 정정, Cycle 9 deliverable 보강, 5 OQ carryover | Cycle 비평 |
| 4 | ← | Critique 004 | W1 archive 부패 + A.2 5 검증 항목 | Cycle 비평 |
| 5 | ← | Plan 020 | Step 8 D1 cron + scheduled handler dormant code 식별 | Cycle 비평 |
| 6 | ← | Pipeline DB | cycle 7/9/10 status=pending 실측, 'deferred' status enum 부재 | Cycle 비평 |
| 7 | → | Brief 022 작성자 | W3 Phase 2 Carryover Inputs 인덱싱 부재 — Brief 021 보강 권고 | (간접) |
| 8 | → | Cycle 1 implementation skill | W1 Pipeline DB 마이그레이션을 첫 step으로 권고 | (간접) |

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
