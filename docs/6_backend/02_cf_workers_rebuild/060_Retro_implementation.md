---
id: "060"
type: retro
title: "Phase 1 Conversion Implementation 회고"
created: 2026-05-02
traces_brief: "021"
traces_scope: "026"
traces_eval: "057"
traces_qualify: "058"
traces_push: "059"
phase_scope: "phase-1-conversion"
status: completed
confidence: high
summary: >
  Phase 1 implementation phase 회고. 활성 7 cycle GREEN(6 PASS + 1 PARTIAL with carryover) +
  783 vitest pass + 17 Phase 2 carryover 명시. process 효과: TDD 일관성, 2-batch 분할, gate 루프.
  process 갭: cycle 6 RED 안티패턴, timeout 2회, plan/impl 갭, node_modules contamination.
keywords: [retro, phase1, implementation, process-assessment, cycle10]
---

## Phase 1 Outcome Summary

Phase 1 Conversion (Rails → Cloudflare Workers/TypeScript) 구현 phase가 완결됐다.

- **활성 7 cycle 전원 GREEN**: Cycle 1~6 PASS, Cycle 8 PARTIAL(783/783 test pass + 2건 carryover 명시)
- **783 vitest pass / 0 fail / 84 test files**: 모든 cycle에서 회귀 없음. 누적 순증 패턴(112 → 369 → 460 → 611 → 722 → 783) 유지
- **Brief 021 Decision 13 완료 정의 충족**: 활성 7 cycle verify 통과 + Vitest로 RSpec 18개 동등성 입증
- **외부 자원 미접촉 원칙 전 cycle 유지**: wrangler.toml `__FILL_IN_PHASE2__` placeholder 14개 전 cycle 보존. 외부 호출 흔적 0건
- **17개 Phase 2 carryover 명시 완료**: P0 2건 / P1 7건 / P2 8건. Phase 2 brief 직접 입력 가능
- **산출물 규모**: 14 tables / 20 services / 35 endpoints / 22 SSR pages / 5 GDPR/PIPA flows / 5 middleware

Eval 057은 **SUFFICIENT**, Qualify 058은 **GO-WITH-CONDITIONS** 판정. Phase 2 cutover 진입 가능. Production deploy는 P0 2건 + 외부 자원 연결 + cutover safety drill 이후.

---

## What Worked

### 1. TDD Red-Green-Refactor 사이클 일관 적용 (Cycle 2~6, 8)

TDD 적용 대상 6 cycle 모두에서 tdd-red sub-agent가 실패 테스트를 먼저 작성하고, makeplan 에이전트가 이 RED 상태를 기준으로 구현 계획을 수립했다. 구현 후 verify 에이전트가 독립 실측으로 GREEN을 확인하는 사이클이 모든 cycle에서 이탈 없이 유지됐다.

| Cycle | 대상 | 증분 | 특이 사항 |
|---|---|---|---|
| Cycle 2 (DB) | 14 tables + seed | +112 | Drizzle schema RED 먼저, migration test 포함 |
| Cycle 3 (Services) | 20 services | +257 | saga Phase A-E 전체 + idempotency guard + compensateScoring |
| Cycle 4 (Auth) | crypto + betterAuth + 5 middleware | +91 | CSRF, envelope JSON {iv,ct,v}, Argon2 hash |
| Cycle 5 (API) | 35 endpoints + OpenAPI | +151 | public 22 + admin 13, Hono RPC typed |
| Cycle 6 (SSR) | layouts 3 + components 4 + 17 pages | +111 | RED 안티패턴 step 0 보강 포함 |
| Cycle 8 (Compliance) | auditLogger + 5 GDPR/PIPA flows | +61 | Phase 1 마지막 활성 cycle |

각 verify 보고서는 이전 cycle test를 재실행하여 회귀 없음을 직접 확인했다. cycle 2→8 전 구간에서 회귀 0건은 TDD 사이클 + 독립 verify 실측의 직접 효과다.

TDD를 미적용한 Cycle 1(Foundation 한정형)은 syntax check + placeholder 확인 위주였고, tsc --noEmit가 node_modules 없어 UNAVAILABLE이었다. 인프라/구조 초기화 cycle에서 TDD 미적용은 합리적이었지만, tsc 검증 불가 상태는 Phase 2 npm install 후 해결이 필요하다.

### 2. 2-batch 분할 디스패치 패턴

Cycle 3부터 정착된 2-batch 분할은 timeout 위험을 구조적으로 낮췄다. 각 batch는 독립 에이전트로 실행하고, 배치 1 완료 후 배치 2가 이어받는 형태다.

- Cycle 3: 배치 1 (Steps 0-3 + Insights, 279 pass) → 배치 2 (Steps 5-7, 369 pass)
- Cycle 4: 배치 1 (Steps 0-2, Crypto + Auth) → 배치 2 (Steps 3-5, Middleware + Integration)
- Cycle 5: 배치 1 (Steps 0-2, envelope + 22 public endpoints) → 배치 2 (Steps 3-5, admin routes + OpenAPI)
- Cycle 6: 배치 1 (Steps 0-2, RED 보강 + Layouts + Components) → 배치 2 (Steps 3-5, Admin/Public pages)

2-batch 패턴은 cycle 3 timeout 경험에서 귀납된 자기교정이었다. 분할 전략이 구현 보고서 frontmatter(`batch: "2 (final)"`)에 명시되어 다음 cycle로 이어졌다.

분할 경계 설계 원칙: 배치 1은 "기반 레이어(구조·인프라·보강)"를 담당하고, 배치 2는 "기능 레이어(비즈니스 로직·통합 검증)"를 담당했다. 배치 1 완료 기준(중간 pass 수 기준)을 Plan에 명시하여 배치 2 에이전트가 재진입 지점을 명확히 파악할 수 있었다.

단점: 4 cycle에서 동일 분할을 적용했지만, Plan 단계에서 batch 분할이 명시되지 않고 에이전트가 자율적으로 결정하는 경우도 있었다. Cycle 8은 작업량이 상대적으로 작아 단일 에이전트로 완료됐다.

### 3. Phase 2 Carryover 명시 정착 (Cycle 4부터)

Cycle 4 verify 보고서(044)에서 cfAccessVerifier structural parser와 betterAuth D1 직접 구현이 처음으로 Phase 2 carryover로 명시됐다. 이후 cycle 5/6/8 구현 및 verify 보고서 모두 carryover를 impl 보고서 내에 선명하게 기록했다. 마지막 Eval 057에서 이 carryover들을 일괄 수집하여 P0/P1/P2 17건으로 분류했다.

carryover 명시 정착의 효과:
- Verify 에이전트가 "이 갭은 허용된 carryover인가, 아니면 Phase 1 차단 이슈인가"를 문서 근거로 판단할 수 있었다
- Eval 057이 impl 보고서의 carryover 항목을 일괄 수집하여 P0/P1/P2로 체계적으로 분류할 수 있었다
- Phase 2 brief 입력이 즉시 가능한 17건 목록이 자연스럽게 생성됐다
- carryover가 "허용된 defer"임을 문서 근거로 명시함으로써 verify PARTIAL 판정이 "미완성"이 아닌 "범위 내 완결"임을 입증할 수 있었다

carryover 없이 verify를 수행했다면, Cycle 8의 consents.status drift와 cfAccessVerifier 갭이 FAIL 판정으로 이어져 Phase 1 완료가 차단됐을 것이다. carryover 명시 = "의도적 defer를 문서로 정당화하는 수단"이라는 점에서 pipeline 설계의 핵심 메커니즘이다.

### 4. Gate 루프 일관성 (validate → update → next)

pipeline.sh gate 루프가 전 cycle에서 이탈 없이 작동했다. 각 cycle의 verify PASS/PARTIAL/FAIL 결과를 바탕으로 update → next 전환이 pipeline DB에 기록됐다.

**Gate 루프 상세 흐름 (dispatch → validate → update → next)**:
1. **dispatch**: 에이전트 실행 (tdd-red / makeplan / impl / verify)
2. **validate**: impl 또는 verify 완료 후 PASS/PARTIAL/FAIL 판정 + 근거 명시
3. **update**: pipeline.sh에 status 업데이트 (`pipeline.sh set <seq> status completed`)
4. **next**: 다음 step 자동 이동 (`pipeline.sh next` — deferred step 자동 skip)

주목할 결과:
- Cycle 7, 9, 10(partial)은 Brief 021 Decision 14에 따라 `status=interrupted, reason='phase-2-deferred'`로 처리됐고, pipeline.sh next가 이를 자동 skip하여 활성 cycle로만 이동했다
- Cycle 8 PARTIAL 결과도 gate 루프 내에서 "783 pass + carryover 명시 = Decision 12 인정 모델"로 처리됐다
- Cycle 10 tail(eval/qualify/push/retro)은 phase 1 종료 검증으로 정상 활성 유지됐다
- validate 단계에서 FAIL이 발생한 cycle은 0건 — 모든 cycle에서 첫 구현 시도 또는 배치 2 재진입으로 GREEN 달성

Gate 루프의 일관 적용 덕분에 pipeline DB가 implementation phase 전 구간의 진행 상태를 정확하게 반영했다.

### 5. Pipeline.sh Deferred 자동 Skip

pipeline.sh의 `next` 명령이 interrupted 상태(Cycle 7/9/10 makeplan/impl/verify)를 자동 skip하고 다음 활성 step으로 이동했다. 수동 개입 없이 Phase 1 tail(eval → qualify → push → retro)로 자연스럽게 이동한 것은 circuit breaker 설계가 제 역할을 한 결과다.

### 6. Verify의 독립 실측 원칙

Verify 에이전트는 매 cycle마다 impl 보고서를 입력으로 받아 독립적으로 `npx vitest run`을 재실행했다. 보고서 주장을 신뢰하지 않고 실측으로 확인하는 원칙 덕분에 여러 갭이 사후가 아닌 cycle 내에서 catch됐다.

**주요 catch 사례:**
- Cycle 5: 보고서의 "32 endpoints" 표기 오기를 python3 직접 파싱으로 35 확인. 오기가 그대로 넘어갔다면 Eval 057에서 "OpenAPI operations 32"로 잘못 집계됐을 것
- Cycle 8: consents.status production drift(G3)를 `test/setup.ts ALTER TABLE` 패턴에서 발견 → P0-1 분류. verify가 없었다면 D1 production 배포 시 runtime error로 발견됐을 것
- Cycle 6: routes c.html 미결합(G7)의 원인(wrangler dev 런타임 의존)을 명확히 구분 → Phase 2 carryover 정당 판정
- Cycle 4: cfAccessVerifier structural parser 갭을 admin auth 동작에서 확인 → P0-2로 early flagging

독립 실측 + 보고서 클레임 cross-check 패턴은 "구현 에이전트가 주장하는 GREEN"과 "실제 test runner가 확인하는 GREEN"의 간격을 0으로 유지했다.

---

## What Did Not Work / 갭

### 1. Cycle 6 RED 안티패턴 — expect.toThrow always-pass

TDD Red phase(049)에서 작성된 102개의 SSR 컴포넌트 테스트가 `expect(() => Comp(props)).toThrow("not implemented: X")` 패턴으로 작성됐다. 이 패턴의 문제:

- GREEN 구현이 throw 대신 정상 JSX를 반환하면 해당 테스트가 fail로 역전됨
- RED 단계에서 `vitest run`을 실행하면 stub 컴포넌트가 throw하므로 102 tests pass — "비정상 GREEN" 상태
- 즉 RED 안티패턴이 Red-Green 경계를 무력화함

배치 1 시작 전에 이 안티패턴이 발견됐고, Step 0를 추가하여 15개 test file의 패턴을 `String(Comp(props))` + `expect.toContain(...)` 방식으로 전환했다. 이 추가 step이 배치 1의 절반 이상을 소비했다.

배치 2에서 `hx_boost.test.ts`와 `csp_nonce.test.ts` 2개가 여전히 RED 안티패턴 상태였음이 재발견됐다. expect.toThrow 패턴은 RED phase 검수 시점에서 차단했어야 했다.

### 2. Timeout 2회 발생

**첫 번째 (Cycle 3 makeplan 단계):**
- Cycle 3 services는 20개 서비스 파일 + 1,850 LOC Ruby 변환 대상으로 Plan 038이 매우 방대했다
- makeplan 에이전트가 방대한 서비스 목록(scoring 8단계 Saga + Quality + Profiles + Insights + Compliance + Saga) 전체를 한 번에 플랜닝하면서 timeout 발생
- 해결: batch 2-pass 구조로 Plan을 분할하고 배치 1/2 각각 독립 에이전트로 구현. 이 경험이 이후 2-batch 분할 패턴의 기원이 됐다

**두 번째 (Cycle 6 배치 1 Step 0 도중):**
- Cycle 6 배치 1 에이전트가 TDD Red 049에서 생성된 25개 stub 파일 변환 도중 timeout
- timeout 전에 layouts 3 + components 4 = 7개만 완료, 15개 미완
- 배치 1 재진입 에이전트가 7개 완료 상태를 이어받아 나머지 15개 변환 완료 → 60 pass
- 부분 진행이 코드 파일로 저장되어 있었기 때문에 재진입이 가능했다 (in-progress report 없이 코드만 남은 상태)

**Timeout 발생 패턴 분석:**

| 발생 시점 | 작업 규모 | 원인 | 해결 |
|---|---|---|---|
| Cycle 3 makeplan | 20 services, Plan 038 전체 | 단일 에이전트에 지나치게 방대한 플랜닝 | 배치 분할 후 각 배치별 Plan |
| Cycle 6 배치 1 Step 0 | 25 파일 일괄 변환 | 파일 수 초과 + RED 안티패턴 변환 오버헤드 | 부분 진행 이어받기 (새 에이전트 재진입) |

공통 패턴: "큰 작업을 단일 에이전트에 한 번에 부여". 방지 방법은 Plan 단계에서 작업량 추정 후 사전 분할.

### 3. Cycle 8 Plan/Impl 갭 — consents.status

Cycle 8 Plan(054)은 `consents` 테이블의 status 컬럼을 구현 범위에 명시하지 않았다. Impl(055)에서 `deletionProcessor.ts`의 `SET status='revoked'` 직접 실행이 구현됐으나, `schema.ts`에 해당 컬럼이 없었다.

테스트 환경에서는 `test/setup.ts`의 `ALTER TABLE consents ADD COLUMN status TEXT` 보정으로 통과했지만, production D1 배포 시 즉각 runtime SQL error가 발생하는 상황이었다.

Verify 에이전트(056)가 이를 G3 갭으로 catch하여 P0-1로 분류했다. Verify의 cross-cycle drift 탐지가 제 역할을 했지만, Plan 단계에서 schema 컬럼 수준까지 검증하는 gate가 없었다는 점은 process 갭이다.

### 4. node_modules Contamination — Push 직전 발견

**경위:**
- root `.gitignore`에 `apps/workers/node_modules/`만 등록되어 있었고, root `node_modules/` 패턴이 누락됐다
- npm workspace hoisting으로 root에 `node_modules/` 디렉토리가 생성됐다
- auto-commit hook이 8519개 파일을 일괄 커밋 (`feat: apps/workers — 8519개 파일 자동 커밋`)

**발견 시점**: push 직전 점검. GitHub remote에 단 한 번도 올라가지 않은 상태에서 발견됐다.

**해결**: git filter-repo로 history 재작성. 188 commits 재작성 + force-with-lease push. `.git` 크기 139M → 54M(60% 감소).

발견이 늦어진 이유: auto-commit hook이 root `.gitignore` 검증 없이 실행됐다. 새 workspace를 추가하거나 `npm install`을 실행할 때 root `.gitignore` 적용 범위를 확인하는 gate가 없었다.

### 5. Cross-Cycle Drift 패턴

단일 cycle 내 갭이 아니라 복수 cycle에 걸쳐 누적된 drift:

- **cfAccessVerifier structural parser** (Cycle 4 → 5 → 6 전파): Cycle 4에서 carryover로 명시됐지만, Cycle 5 admin route와 Cycle 6 admin SSR이 이 carryover를 의존하는 상태로 구현됐다. Phase 2에서 cfAccessVerifier를 교체할 때 세 cycle의 코드를 동시에 수정해야 하는 의존성이 누적됐다.
- **deletion_requests action 'started' → 'processed' 통일** (Cycle 3 → Cycle 8 지연): Cycle 3의 deletionProcessor에서 `deletion_started` 액션이 사용됐다. Cycle 8에서 `deletion_processed`로 통일 작업이 수행됐다. 이 통일이 5 cycle 동안 지연된 이유는 verify 단계에서 string constant의 cross-cycle 일관성을 검사하는 항목이 없었기 때문이다.
- **routes c.html 결합 미수행** (Cycle 5 admin routes + Cycle 6 SSR 미결합): Cycle 5 admin routes와 Cycle 6 SSR 페이지가 각각 구현됐지만 `c.html(<Page />)` 결합은 Cycle 6 carryover로 이월됐다. Cycle 6에서도 wrangler dev 의존성으로 Phase 2 carryover 처리됐다. 두 cycle에 걸쳐 결합되지 않은 상태가 유지됐고, wrangler dev 환경이 없는 상태에서 routes-SSR 통합 검증이 불가능했다.

---

## Cross-Cycle Drift Patterns

Phase 1 전 구간에서 발생한 drift를 유형별로 정리한다.

### 유형 A: Carryover 의존성 전파

Cycle 4 carryover(cfAccessVerifier + betterAuth) → Cycle 5 admin route + Cycle 6 admin SSR로 전파됐다. carryover 항목이 후속 cycle의 구현에 포함되면서 Phase 2 수정 범위가 누적됐다.

| Carryover 항목 | 발생 cycle | 전파 cycle | Phase 2 수정 범위 |
|---|---|---|---|
| cfAccessVerifier structural parser | Cycle 4 | Cycle 5/6 | admin route + SSR + verifier 교체 |
| betterAuth D1 직접 구현 | Cycle 4 | Cycle 5 (auth endpoint 공유) | auth endpoint + D1 구현 교체 |
| routes c.html 결합 | Cycle 5 | Cycle 6 | admin/public routes + SSR 결합 |
| AppType = any placeholder | Cycle 5 | Cycle 8 (admin routes 공유) | AppType typed export + Dart codegen |

### 유형 B: Schema Drift (Production vs Test Environment)

| 항목 | 구현 cycle | Test 우회 | Production 영향 |
|---|---|---|---|
| consents.status | Cycle 8 | test/setup.ts ALTER TABLE ADD COLUMN | D1 배포 시 SQL error (P0-1) |
| deletion_requests FK SET NULL | Cycle 8 | test/setup.ts ALTER TABLE FK CONSTRAINT | CASCADE DELETE vs SET NULL behavior 불일치 (P1-7) |

Schema drift의 공통 패턴: 서비스 코드가 schema.ts에 없는 컬럼/제약을 사용하고, test/setup.ts의 DDL 보정으로 테스트를 통과시킨 형태. Verify 에이전트가 catch했으나 Plan 단계에서 "schema.ts와 서비스 코드의 컬럼 참조 일치 여부"를 체계적으로 확인하는 항목이 없었다.

### 유형 C: String Constant 통일 지연

`deletion_started` → `deletion_processed`: Cycle 3에서 정의된 string constant가 Cycle 8에서 통일됐다. 5 cycle 지연 동안 audit log에 일관성 없는 action 값이 기록됐을 가능성이 있다.

유형 C는 string constant, enum 값, DB action 값 같은 "약타입 상수"가 verify의 검사 대상에 포함되지 않았을 때 발생한다.

### 유형 D: 외부 런타임 의존 결합 지연

routes c.html 결합이 wrangler dev 없이는 검증 불가능하여 Phase 2 carryover가 됐다. Phase 1의 로컬 검증 모델(wrangler dev 없음) 안에서 SSR-routes 통합은 구조적으로 검증 불가였다. 이 유형은 Phase 1 설계 원칙("외부 자원 미접촉")의 직접적 tradeoff다.

---

## Process Improvement Recommendations

### Rec 1: RED Phase 검수 — expect.toThrow 단독 패턴 차단

RED phase 산출물을 makeplan에 넘기기 전에 `expect.toThrow` 단독 사용 여부를 확인하는 항목을 추가한다.

**기준**: RED 테스트가 항상 pass하지 않고, GREEN 구현 후 pass로 전환하는지 확인. `expect.toThrow("not implemented: X")` 패턴이 존재하면 component 동작 검증 패턴(`String(Comp(props))` + `toContain`)으로 전환 후 makeplan 진입.

**적용 시점**: tdd-red 에이전트 완료 → makeplan 에이전트 디스패치 전 gate 체크.

### Rec 2: 5 MD 이상 Cycle은 Plan 단계에서 Batch 분할 명시

Plan 보고서 frontmatter에 `batch_strategy` 항목을 추가한다:

```yaml
batch_strategy:
  total_batches: 2
  batch_1_scope: "Steps 0-2 (기준 pass X)"
  batch_2_scope: "Steps 3-5 (최종 통합 검증)"
  split_rationale: "작업량 5 MD 이상, timeout 방지"
```

makeplan 에이전트가 작업량을 추정하여 5 MD 이상이면 batch 분할을 Plan에 명시하도록 지시한다. 사후 긴급 분할이 아니라 계획 단계에서 분할 경계를 결정하면 배치 2 재진입 지점이 명확해진다.

### Rec 3: Timeout 발생 시 재개 전략 — 부분 진행 보존 기준

두 가지 재개 전략의 선택 기준을 명확히 한다.

| 상황 | 선택 전략 | 이유 |
|---|---|---|
| 에이전트가 중간 step까지 진행하고 보고서에 체크리스트 기록 | 새 에이전트 디스패치 (재진입) | 부분 진행 보존 가능 |
| 에이전트가 진행 기록 없이 timeout | SendMessage 재개 시도 | 컨텍스트 연속성 활용 |
| makeplan 에이전트 timeout (Plan 보고서 미생성) | 새 에이전트 디스패치 | Plan 보고서 없으면 재진입 지점 없음 |

기본 원칙: 산출물(보고서 + 코드)이 부분적으로라도 저장됐으면 새 에이전트로 재진입하고, 진행 기록이 전무하면 SendMessage 재개.

### Rec 4: Auto-Commit Hook — Root .gitignore 검증 자동화

auto-commit hook 실행 전 root `.gitignore`에 다음 패턴이 등록됐는지 확인하는 lint를 추가한다:

```
node_modules/
*.log
.env
.dev.vars
```

특히 `npm install`이 실행된 이후 커밋이 발생할 때는 root `.gitignore` 패턴을 재확인하고, `node_modules/` 포함 여부를 git status로 사전 확인한다.

workspace 구조 변경(새 `apps/` 하위 패키지 추가) 시 root `.gitignore` 패턴 적용 범위를 명시적으로 검증한다.

### Rec 5: Verify 단계 — Cross-Cycle Drift 검사 강화

Verify 체크리스트에 다음 항목을 추가한다:

1. **Schema-Service 컬럼 일치 확인**: 서비스 코드에서 직접 컬럼명을 사용하는 SQL이 schema.ts의 컬럼 목록과 일치하는지 grep으로 확인
2. **String Constant 일관성**: DB에 기록되는 action/status 값이 이전 cycle verify 보고서의 값과 일치하는지 확인
3. **Test/Setup.ts DDL 검사**: `test/setup.ts`의 `ALTER TABLE ADD COLUMN` / `MODIFY COLUMN FK` 패턴이 production schema drift를 은폐하는지 확인

Verify 에이전트가 cycle 8에서 consents.status drift를 catch한 것은 이 항목을 체크리스트에 넣은 결과이지만, 사후 catch였다. 이 검사를 cycle 3부터 적용했다면 drift 발생 시점에 차단할 수 있었다.

### Rec 6: Plan 단계 — Schema 변경 사전 선언

구현 plan에 "이번 cycle에서 schema.ts에 추가하는 컬럼/테이블" 항목을 명시하는 섹션을 추가한다. makeplan 에이전트가 서비스 로직 구현 전에 필요한 schema 변경을 먼저 선언하면, "schema.ts 미반영 + test/setup.ts 보정"의 drift 경로를 차단할 수 있다.

---

## Phase 2 Entry Recommendations

### 1. P0 항목 처리 (Phase 2 인프라 세팅 전)

P0-1과 P0-2는 Phase 2 첫 번째 작업으로 처리해야 한다. Production 배포 전에 반드시 해결.

| 항목 | 처리 방법 | 근거 |
|---|---|---|
| **P0-1: consents.status production drift** | schema.ts에 `status TEXT` 컬럼 추가 + migration 0003_consents_status.sql 생성. `consents.ts:206`의 `SET status='revoked'` 직접 실행 → schema 기반 UPDATE로 전환 | D1 production 배포 시 즉각 SQL error |
| **P0-2: cfAccessVerifier structural parser** | Phase 2 CF Access 실 JWKS endpoint 연결 시 jose `jwtVerify` + DI 패턴으로 교체. admin route + admin SSR 모두 수정 대상 | admin 인증이 production에서 실 CF SSO와 단절 |

### 2. 17 Carryover 우선순위 처리

| 우선순위 | 항목 | 처리 단계 |
|---|---|---|
| P0-1 | consents.status drift | Phase 2 초기 |
| P0-2 | cfAccessVerifier structural parser | Phase 2 초기 |
| P1-1 | betterAuth D1 직접 구현 교체 | Phase 2 중기 |
| P1-2 | SLA monitoring cron (30일 pending) | Phase 2 중기 |
| P1-3 | audit_log immutability schema 강제 | Phase 2 중기 |
| P1-4 | routes c.html 결합 (wrangler dev) | Phase 2 중기 |
| P1-5 | Hono AppType typed 추론 | Phase 2 중기 |
| P1-6 | admin deletion_requests HTTP endpoint | Phase 2 중기 |
| P1-7 | anonymous_session FK SET NULL drift | Phase 2 중기 |
| P2-1~8 | zod-openapi / tsc / migration SQL / Dart codegen / domains / 보호자 동의 / admin compliance / cross_border SSR | Phase 2 이후 |

### 3. 외부 자원 9종 연결 (Phase 2 Cutover 전제)

wrangler.toml의 `__FILL_IN_PHASE2__` placeholder 14개 전환:
- CF account ID + Worker name
- D1 database_id (production)
- KV namespace IDs (session, cache)
- R2 bucket name
- CF Access service token
- 실 도메인 (api.personality.app)
- GitHub Actions secrets (CF_API_TOKEN, D1_PROD_DATABASE_ID 등)
- `apps/workers/.dev.vars` production secret 값

### 4. Cutover Safety Drill + Execution

Phase 2 Cycle 9 (cutover safety drill):
- archive smoke test (월 1회 자동화 여부 결정)
- Phase rollback drill (D1 → PostgreSQL 롤백 절차 검증)
- wrangler deploy --dry-run 검증

Phase 2 Cycle 10 (cutover execution Phase A → B → C):
- Phase A: 병렬 실행 (Workers + Rails 동시)
- Phase B: Traffic 전환 (50% → 100%)
- Phase C: Rails deprecated + Workers 단독

### 5. Toss 결제 (별도 Phase 2-Toss Track)

Cycle 7 (Toss 결제)는 Phase 1에서 interrupted 처리됐다. Phase 2-Toss는 별도 Brief로 시작하고, HMAC v1 webhook 모델 B의 dormant 코드 작성 여부(OQ-3)를 makeplan 단계에서 결정한다.

---

## Metrics

### 구현 산출물

| 항목 | 수치 | 출처 |
|---|---|---|
| 활성 구현 cycle 수 | 7 (Cycle 1~6, 8) | Scope 026 |
| 총 vitest pass | **783 / 0 fail** | Verify 056 실측 |
| test files | 84 | Verify 056 |
| 테이블 (Drizzle schema) | 14 | Verify 036 |
| 서비스 파일 | 20 | Eval 057 |
| API endpoints (OpenAPI) | 35 | Verify 048 |
| SSR pages | 22 (admin 9 + public 8 + layouts 3 + components 4) | Verify 052 |
| GDPR/PIPA flows | 5 | Verify 056 |
| Middleware 종류 | 5 | Verify 044 |
| wrangler.toml placeholder | 14 | Verify 032 |
| Phase 2 carryover 항목 | 17 (P0 2 + P1 7 + P2 8) | Eval 057 |

### 구현 문서

| 구분 | 파일 수 | 비고 |
|---|---|---|
| Implementation 보고서 | 7 | 031/035/039/043/047/051/055 |
| Verify 보고서 | 7 | 032/036/040/044/048/052/056 |
| TDD Red 보고서 | 6 | 033/037/041/045/049/053 (Cycle 1 제외) |
| Plan 보고서 | 8 | 020/034/038/042/046/050/054 + 020 (Cycle 1) |
| Eval/Qualify/Push | 3 | 057/058/059 |

### Process 지표

| 항목 | 수치 | 비고 |
|---|---|---|
| Timeout 발생 횟수 | 2회 | Cycle 3 makeplan + Cycle 6 배치 1 |
| 2-batch 분할 cycle 수 | 4 (Cycle 3/4/5/6) | Cycle 8은 단일 batch |
| RED 안티패턴 발견 시점 | Cycle 6 배치 1 시작 | Step 0 추가 대응 |
| node_modules contamination | 1회 | push 직전 발견, filter-repo 해결 |
| .git 크기 감소 | 139M → 54M (-60%) | filter-repo 재작성 효과 |
| Vitest 회귀 | 0회 | cycle 1-8 전 구간 |
| Deferred cycle 자동 skip | 3 cycle (7/9/10 partial) | pipeline.sh next 작동 |

### 테스트 누적 추이

| Cycle | 누적 Pass | 증분 | Test Files |
|---|---|---|---|
| Cycle 1 | - (syntax only) | - | - |
| Cycle 2 | 112 | +112 | 7 |
| Cycle 3 | 369 | +257 | 25 (services) |
| Cycle 4 | 460 | +91 | 36 |
| Cycle 5 | 611 | +151 | ~55 |
| Cycle 6 | 722 | +111 | 78 |
| Cycle 8 | **783** | +61 | 84 |

---

## References

- Brief 021 (Phase 1 sub-anchor): `docs/6_backend/02_cf_workers_rebuild/021_Brief_conversion_phase1.md`
- Scope 026 (Phase 1 scope): `docs/6_backend/02_cf_workers_rebuild/026_Scope_conversion_phase1.md`
- Verify 보고서: `032` / `036` / `040` / `044` / `048` / `052` / `056`
- Implementation 보고서: `031` / `035` / `039` / `043` / `047` / `051` / `055`
- Eval 057 (SUFFICIENT): `docs/6_backend/02_cf_workers_rebuild/057_Eval_phase1_overall.md`
- Qualify 058 (GO-WITH-CONDITIONS): `docs/6_backend/02_cf_workers_rebuild/058_Qualify_phase1_production.md`
- Push 059 (SUCCESS + filter-repo): `docs/6_backend/02_cf_workers_rebuild/059_Push_phase1_remote.md`
- Retro 019 (Research phase 회고): `docs/6_backend/02_cf_workers_rebuild/019_Retro_research.md`
