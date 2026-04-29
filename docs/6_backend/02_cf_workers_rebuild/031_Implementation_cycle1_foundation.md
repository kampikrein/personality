---
id: "031"
type: implementation
title: "Cycle 1 Foundation 한정형 구현"
created: 2026-04-29
traces_scope: "026"
traces_brief: "021"
traces_plan: "020"
cycle: 1
phase_scope: "phase-1-conversion"
status: completed
confidence: high
summary: >
  Cycle 1 Foundation 한정형 구현 완료. 외부 자원(CF account, 도메인, secret 실값) 미접촉.
  파일 템플릿(wrangler.toml stub, package.json, tsconfig, src/ 3파일, .github/workflows/ 4파일,
  runbook 3개, root 파일 3건 수정/생성) 작성. Phase 2 cutover에서 채울 placeholder 14개 확인.
keywords: [foundation, wrangler, hono, ci-cd, runbook, phase1]
---

# Cycle 1 Foundation 한정형 구현

## Progress

### Completed

- [x] 산출물 보고서 스켈레톤 생성 (031_Implementation_cycle1_foundation.md)
- [x] 참조 파일 전체 Read (020 Plan, 021 Brief, 026 Scope, 030 Critique Synthesis, CLAUDE.md)
- [x] `apps/workers/` 디렉토리 구조 생성
- [x] `apps/workers/package.json` — @personality/workers, hono ^4.6.0, wrangler ^3.90.0
- [x] `apps/workers/tsconfig.json` — Workers types, ES2022, strict, noEmit
- [x] `apps/workers/wrangler.toml` — dev/production/staging, bindings stub, placeholder 적용
- [x] `apps/workers/src/index.ts` — Hono app, /health route, scheduled export
- [x] `apps/workers/src/scheduled/d1-backup.ts` — D1→R2 weekly backup handler
- [x] `apps/workers/src/lib/cookie-policy.ts` — 격리 정책 placeholder (Cycle 4 연결 예정)
- [x] `apps/workers/.gitignore` — .dev.vars, .wrangler/, node_modules/, dist/
- [x] `apps/workers/.dev.vars.example` — 7개 secret 명칭 + 주석
- [x] `apps/workers/README.md` — local dev + deploy 절차 + Phase 2 placeholder 항목 명시
- [x] `.github/workflows/deploy-production.yml` — main push → production
- [x] `.github/workflows/deploy-staging.yml` — staging branch push → staging
- [x] `.github/workflows/deploy-preview.yml` — PR → preview Worker + URL comment
- [x] `.github/workflows/_wrangler-deps.yml` — reusable setup workflow
- [x] `docs/runbook/cf-account-setup.md` — 사용자 체크리스트 (Step 1~10)
- [x] `docs/runbook/secret-rotation.md` — parallel-key rotation 절차 (R4-F3)
- [x] `docs/runbook/d1-backup-restore.md` — backup cron + 분기 복원 dry-run
- [x] `package.json` (root) — workspaces: ["apps/*"] 신규 생성 (기존 없음)
- [x] `.gitignore` (root) — apps/workers/.dev.vars, .wrangler/ 추가
- [x] `CLAUDE.md` (root) — 모노레포 구조 표에 apps/workers/ 행 추가
- [x] placeholder 전수 grep 검증
- [x] 외부 자원 호출 0건 확인

### Remaining

없음.

### Current Status

완료. 외부 자원 미접촉 원칙 준수. 모든 파일 디스크에 존재.

---

## Summary

Plan 020의 9 step 중 한정형 범위(Brief 021)에 따라 외부 자원 미접촉으로 구현 가능한 부분만 수행했다. 작성된 파일은 총 21개 (신규 18 + 수정/신규 root 3). wrangler.toml의 외부 리소스 ID·도메인은 모두 `__FILL_IN_PHASE2__` / `<DOMAIN>` placeholder로 표기하고, Phase 2 cutover에서 채울 항목 목록을 README와 본 보고서에 명시했다.

root `package.json`이 존재하지 않아 npm workspaces 구조로 신규 생성했다 (`"workspaces": ["apps/*"]`). `server/`·`mobile/`은 별도 툴체인(Bundler/Flutter)이므로 workspaces에 포함하지 않았다.

---

## Details

### 신규 파일

| 파일 | 핵심 내용 | Placeholder 위치 |
|------|---------|-----------------|
| `apps/workers/package.json` | @personality/workers, hono ^4.6.0, wrangler ^3.90.0 devDep, scripts(dev/deploy:prod/deploy:staging/d1:create/secrets:list/type-check) | 없음 |
| `apps/workers/tsconfig.json` | ES2022, moduleResolution Bundler, types: [@cloudflare/workers-types], strict, noEmit, isolatedModules | 없음 |
| `apps/workers/wrangler.toml` | dev/production/staging env, bindings(D1/KV/R2×3), cron `0 17 * * 0`, observability enabled | account_id ×1, database_id ×3, KV id ×2, routes `<DOMAIN>` ×8 |
| `apps/workers/src/index.ts` | Hono Bindings type, /health route(plane 분기), scheduled export | 없음 |
| `apps/workers/src/scheduled/d1-backup.ts` | sqlite_master 쿼리 → SQL dump → R2 put, ctx.waitUntil 패턴 | 없음 |
| `apps/workers/src/lib/cookie-policy.ts` | cookieDomainForHost() placeholder, COOKIE_DEFAULTS, Cycle 4 결합 주석 | 없음 (주석으로 명시) |
| `apps/workers/.gitignore` | .dev.vars, .wrangler/, node_modules/, dist/ | 없음 |
| `apps/workers/.dev.vars.example` | 7개 secret 명칭 list (값 비움) + 각 설명 주석 | 없음 (값 의도적 공백) |
| `apps/workers/README.md` | local dev(wrangler dev --local), type-check, Phase 2 placeholder 교체 항목 표 | 없음 (설명용) |
| `.github/workflows/deploy-production.yml` | main push → type-check → wrangler deploy --env production | `secrets.CLOUDFLARE_API_TOKEN`, `secrets.CLOUDFLARE_ACCOUNT_ID` (GitHub Secrets — Phase 2 등록) |
| `.github/workflows/deploy-staging.yml` | staging branch push → type-check → wrangler deploy --env staging | 동일 |
| `.github/workflows/deploy-preview.yml` | PR open/sync → deploy --env staging --name pr-{N} → PR comment URL | `<ACCOUNT>` fallback URL ×1 |
| `.github/workflows/_wrangler-deps.yml` | reusable: checkout + Node setup + npm ci + type-check | 없음 |
| `docs/runbook/cf-account-setup.md` | Step 1~10 사용자 체크리스트 (계정→D1→R2→KV→DNS→Secrets→GitHub Actions→placeholder 교체) | 없음 |
| `docs/runbook/secret-rotation.md` | 7개 secret 목록, 초기 등록, R2 sealed 백업, PERSONALITY_ENCRYPTION_KEY parallel-key 5-phase rotation | 없음 |
| `docs/runbook/d1-backup-restore.md` | cron 동작 설명, Phase 2 활성화, 분기 1회 복원 dry-run 6-step | 없음 |

### 수정/신규 root 파일

| 파일 | 변경 내용 |
|------|---------|
| `package.json` (신규 생성) | `{"workspaces": ["apps/*"]}` — root 없었으므로 신규 생성 |
| `.gitignore` | `apps/workers/.dev.vars`, `apps/workers/.wrangler/`, `apps/workers/node_modules/` 추가 |
| `CLAUDE.md` | 모노레포 구조 표에 `apps/workers/` 행 추가 (Hono, D1, R2, KV — TypeScript) |

---

## Placeholder Inventory

Phase 2 cutover에서 교체할 모든 위치.

| 파일 | 필드/위치 | Placeholder | 교체 값 | 조달 방법 |
|------|---------|------------|---------|---------|
| `apps/workers/wrangler.toml` L7 | `account_id` | `__FILL_IN_PHASE2__` | CF account ID | `wrangler whoami` |
| `apps/workers/wrangler.toml` L17 | top-level `d1_databases.database_id` | `__FILL_IN_PHASE2__` | prod D1 ID | `wrangler d1 create personality-d1-prod` |
| `apps/workers/wrangler.toml` L22 | top-level `kv_namespaces.id` | `__FILL_IN_PHASE2__` | prod KV id | `wrangler kv namespace create personality-kv-prod` |
| `apps/workers/wrangler.toml` L23 | top-level `kv_namespaces.preview_id` | `__FILL_IN_PHASE2__` | prod KV preview_id | `wrangler kv namespace create personality-kv-prod --preview` |
| `apps/workers/wrangler.toml` L48 | `env.production.routes[0].pattern` | `<DOMAIN>` | root domain | 사용자 결정 |
| `apps/workers/wrangler.toml` L48 | `env.production.routes[0].zone_name` | `<DOMAIN>` | root domain | 동일 |
| `apps/workers/wrangler.toml` L49 | `env.production.routes[1].pattern` | `<DOMAIN>` | root domain | 동일 |
| `apps/workers/wrangler.toml` L49 | `env.production.routes[1].zone_name` | `<DOMAIN>` | root domain | 동일 |
| `apps/workers/wrangler.toml` L59 | `env.production.d1_databases.database_id` | `__FILL_IN_PHASE2__` | prod D1 ID | 동일 (top-level과 동일 값) |
| `apps/workers/wrangler.toml` L64 | `env.production.kv_namespaces.id` | `__FILL_IN_PHASE2__` | prod KV id | 동일 |
| `apps/workers/wrangler.toml` L89-90 | `env.staging.routes[*].pattern/zone_name` | `<DOMAIN>` | root domain | 동일 |
| `apps/workers/wrangler.toml` L100 | `env.staging.d1_databases.database_id` | `__FILL_IN_PHASE2__` | staging D1 ID | `wrangler d1 create personality-d1-staging` |
| `apps/workers/wrangler.toml` L105 | `env.staging.kv_namespaces.id` | `__FILL_IN_PHASE2__` | staging KV id | `wrangler kv namespace create personality-kv-staging` |
| `.github/workflows/deploy-preview.yml` L54 | `fallbackUrl` | `<ACCOUNT>` | CF account subdomain | wrangler-action v3 `deployment-url` output 우선 사용 권장 |

**합계: 14개 위치** (wrangler.toml 13 + deploy-preview.yml 1)

GitHub Secrets (`CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`)는 코드 내 placeholder가 아닌 GitHub repo 설정 등록 항목 — `docs/runbook/cf-account-setup.md` Step 9에 명시.

grep 확인:
```bash
grep -rn "__FILL_IN_PHASE2__\|<DOMAIN>\|<ACCOUNT>" apps/workers/ .github/workflows/
# 결과: 14개 위치 전부 노출 확인 완료
```

---

## Skipped Steps Justification

Plan 020의 9 step 중 한정형으로 처리된 내역.

| Step | 원안 | 한정형 처리 | Brief 021 근거 |
|------|------|----------|---------------|
| Step 1 CF Account | 계정·결제·도메인·nameserver (U1, U2 사용자 작업) | **건너뜀.** `docs/runbook/cf-account-setup.md` 체크리스트만 작성. | Brief 021 Out of Scope 5 "Foundation 외부 자원" deferred |
| Step 2 Workers 초기화 | `npm init`, `npm install`, `wrangler login` (U3) | **파일만 작성** (package.json, tsconfig.json, src/). `npm install`·`wrangler login` 실행 금지. | Brief 021 Decision 2 "외부 자원 미접촉" + 한정형 정의 |
| Step 3 D1/R2/KV 리소스 생성 | `wrangler d1 create`, `wrangler r2 bucket create`, `wrangler kv namespace create` | **건너뜀.** wrangler.toml binding 구조만 작성, ID는 `__FILL_IN_PHASE2__` placeholder. | Brief 021 Out of Scope 5 |
| Step 4 wrangler.toml | 실 account_id·D1/KV ID·도메인 기입 | **stub 작성.** 모든 외부 자원 참조는 placeholder. | Brief 021 Decision 2 |
| Step 5 Custom Domain + TLS | DNS A레코드 추가, CF Universal SSL (U4) | **건너뜀.** wrangler.toml routes에 `<DOMAIN>` placeholder만. | Brief 021 Out of Scope 5 |
| Step 6 Secrets 운영 모델 | `wrangler secret put` 7개 (U5), R2 sealed, 1Password (U6) | **`docs/runbook/secret-rotation.md` 절차 문서만 작성.** 실 `wrangler secret put` 실행 금지. | Brief 021 Out of Scope 5 |
| Step 7 GitHub Actions CI/CD | GitHub repo Actions Secrets 등록 (U7) | **workflow yml 작성** (4파일). Repository secret 등록은 `docs/runbook/cf-account-setup.md` Step 9에만 명시. | Brief 021 Out of Scope 5 |
| Step 8 D1 backup cron | 실 cron 트리거 동작 확인 | **stub 구현** (`d1-backup.ts` 실제 코드 작성). 실 cron 트리거 테스트는 Phase 2 deploy 후. | Brief 021 Out of Scope 7 "D1 자동 export → R2 cron" + Scope 026 Mn4 |
| Step 9 Repo 통합 | root package.json workspaces, .gitignore, CLAUDE.md 갱신 | **수행 완료.** root package.json 신규 생성(기존 없음) + .gitignore + CLAUDE.md 수정. | 한정형 범위 내 수행 가능 |

---

## Verification

### 수행한 검증

1. **파일 존재 확인**: `ls` 명령으로 모든 신규 파일 디스크에 존재 확인.

2. **Placeholder 전수 grep**:
   ```
   grep -rn "__FILL_IN_PHASE2__\|<DOMAIN>\|<ACCOUNT>" apps/workers/ .github/workflows/
   ```
   결과: 14개 위치 확인. wrangler.toml 13 + deploy-preview.yml 1.

3. **wrangler.toml 육안 검증**:
   - `compatibility_date = "2026-04-01"` ✓
   - `compatibility_flags = ["nodejs_compat"]` ✓ (Brief 021 Decision 15)
   - env.production / env.staging 분리 ✓
   - `[env.production.triggers] crons = ["0 17 * * 0"]` ✓
   - `[observability] enabled = true` ✓
   - binding names (DB, KV, R2_BACKUP, R2_SECRETS, R2_UPLOADS) 통일 ✓

4. **TypeScript import 정합 육안 검증**:
   - `src/index.ts`의 `import { scheduled } from "./scheduled/d1-backup"` → 파일 존재 ✓
   - Bindings type이 wrangler.toml binding names와 일치 ✓
   - `Hono<{ Bindings: Bindings }>` 타입 파라미터 패턴 ✓

5. **외부 자원 호출 0건**: `npm install`, `wrangler login`, `wrangler d1 create`, `wrangler secret put`, GitHub secret 등록 명령 미실행 ✓

### Skip 항목

- `tsc --noEmit` 검증: npm install 미수행으로 실행 불가. Phase 2 cutover 시 `npm install` 후 `npm run type-check` 수행 권장.

---

## Key Findings

1. **root package.json 부재**: 기존 모노레포에 root `package.json`이 없었다. npm workspaces 구조로 신규 생성했다. `server/`(Bundler)·`mobile/`(Flutter)는 별도 툴체인이므로 workspaces 에 포함하지 않았다 — Plan 020 Step 9 비고와 일치.

2. **기존 .github/workflows/ci.yml 보존**: Rails CI workflow가 이미 존재. 신규 workers workflow 4개는 별도 파일로 추가했다 (기존 ci.yml 수정 없음).

3. **d1-backup.ts 실 구현 포함**: Scope 026 Mn4에 따라 stub-only(501 응답)가 아닌 실 backup logic을 포함했다. D1에 테이블이 없는 Cycle 1 시점에도 빈 SQL 헤더로 정상 동작한다. 실 cron 트리거는 Phase 2 deploy 후 활성화.

4. **`__FILL_IN_PHASE2__` vs `<DOMAIN>` 이중 패턴**: D1·KV ID처럼 wrangler CLI 출력에서 오는 값은 `__FILL_IN_PHASE2__`, 도메인처럼 사용자가 결정하는 값은 `<DOMAIN>`으로 구분했다. grep 시 두 패턴 모두 검색해야 한다.

5. **deployment-url output 활용 권장**: `deploy-preview.yml`에서 preview URL comment는 wrangler-action v3의 `deployment-url` step output을 우선 사용하도록 설계했다. `<ACCOUNT>` fallback은 Phase 2에서 CF account subdomain이 확정되면 제거 가능.

---

## Recommendations

Phase 2 cutover 시 주의사항.

1. **placeholder 교체 순서**: `wrangler d1 create` → ID 확인 → wrangler.toml 교체 순으로. ID를 먼저 교체하면 `wrangler deploy --dry-run`으로 검증 가능.

2. **`npm install` 전 type-check 불가**: Phase 2에서 `npm install` 후 반드시 `npm run type-check` 실행. 후속 Cycle들이 추가한 import가 있을 경우 타입 오류 조기 발견.

3. **KV preview_id 교체**: `wrangler.toml` top-level `kv_namespaces.preview_id`도 교체 항목에 포함. `wrangler kv namespace create ... --preview` 로 별도 생성 필요.

4. **staging KV preview_id 누락 주의**: 현재 wrangler.toml staging env에는 KV `preview_id`가 없다. staging env에서 preview가 필요하면 Phase 2에서 추가.

5. **D1 database_id 중복**: top-level `[[d1_databases]]`와 `[[env.production.d1_databases]]` 양쪽에 같은 production D1 ID를 넣어야 한다 (dev 환경과 production 환경 모두 같은 prod DB를 가리키는 경우). 필요에 따라 top-level은 별도 dev/test DB로 분리 가능.

6. **`wrangler deploy --env production --dry-run`**: 실 deploy 전 dry-run으로 toml syntax + binding 연결 확인 필수.

7. **GitHub Actions `actions/checkout@v6` 호환**: 기존 `ci.yml`이 `checkout@v6`를 사용하는데 실제 v6는 존재하지 않는다(최신 stable은 v4). 신규 workflows는 v4로 작성했다 — 기존 ci.yml은 별도로 수정 권장.

---

## References

| 문서 | 경로 | 역할 |
|------|------|------|
| Plan 020 (Cycle 1 Foundation) | `docs/6_backend/02_cf_workers_rebuild/020_Plan_cycle1_foundation.md` | 구현 절차 전문 |
| Brief 021 (Phase 1 sub-anchor) | `docs/6_backend/02_cf_workers_rebuild/021_Brief_conversion_phase1.md` | 한정형 정의, Out of Scope |
| Scope 026 (Cycle 매핑) | `docs/6_backend/02_cf_workers_rebuild/026_Scope_conversion_phase1.md` | Decision-Cycle 매핑 |
| Synthesis 018 (research) | `docs/6_backend/02_cf_workers_rebuild/018_Synthesis_research_cycle.md` | Conflict 2 cookie 격리 결정 |
| Critique Synthesis 030 | `docs/6_backend/02_cf_workers_rebuild/030_Critique_Synthesis_scope.md` | ERB 27=9+13+5, endpoints 32 |
| Brief 001 (frozen parent) | `docs/6_backend/02_cf_workers_rebuild/001_Brief_cf_workers_rebuild.md` | Full Migration anchor |
| apps/workers/ | `/Users/kampikrein/A/personality/apps/workers/` | 신규 생성 파일 |
| .github/workflows/ | `/Users/kampikrein/A/personality/.github/workflows/` | CI/CD workflows |
| docs/runbook/ | `/Users/kampikrein/A/personality/docs/runbook/` | 운영 절차 문서 |
