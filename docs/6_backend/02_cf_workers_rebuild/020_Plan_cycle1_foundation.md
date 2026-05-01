---
id: "020"
type: plan
title: "Cycle 1 Foundation — CF Infra + Domain/TLS + Secrets + CI/CD"
created: 2026-04-29
traces_brief: "001"
traces_scope: "007"
traces_synthesis: "018"
cycle: 1
phase: impl
depends_on: []
parallel_with: []
summary: >
  Cycle 1은 후속 9 사이클의 토대 — Cloudflare 계정 위에 Workers project,
  D1 DB, R2 bucket, KV namespace, Custom Domain 2개(api·admin), 7+ secrets,
  GitHub Actions CI/CD를 깔고 cookie 격리(Synthesis Conflict 2)·secrets
  3중 백업·parallel-key rotation 절차(R4-F3)를 운영 모델로 못박는다. TDD
  미적용(procedural) — 검증은 wrangler dev / `/health` curl / GitHub Actions
  dry-run + secret list 점검.
keywords: [cycle1, foundation, cloudflare, wrangler, d1, r2, kv, custom-domain, tls, secrets, parallel-key-rotation, github-actions, ci-cd]
---

# 020 — Cycle 1 Foundation

## Goal

Brief In Scope **1, 2, 17, 10**을 Cycle 1에서 해소하여 **모든 후속 사이클이 의존하는 인프라 토대**를 가동한다.

가시적 결과:

1. `wrangler deploy --env production` 실행 → `https://api.<도메인>/health` HTTP 200, `https://admin.<도메인>/health` HTTP 200(CF Access challenge 또는 protected response).
2. `wrangler d1 list`, `wrangler r2 bucket list`, `wrangler kv namespace list`에서 production / staging 환경 binding 모두 노출.
3. GitHub Actions에서 PR 생성 시 자동으로 preview Worker URL이 코멘트로 부착.
4. `wrangler secret list --env production` 결과에 7개 secret 모두 등록(평문 값 노출 없음).
5. R2 sealed 백업 1개(`personality-secrets/key_1.age`) + 1Password vault entry "personality CF secrets" 존재.
6. D1 자동 export → R2 cron(주 1회) 동작(`wrangler.toml`의 `[triggers] crons` + 첫 1회 수동 dry-run 통과).

이 결과는 Brief Ideal Criteria **#1 (CF 인프라 가동)**, **#2 (Custom Domain + TLS)**, **#11 (CI/CD 3환경 자동 배포)**, **#20 (7개+ secrets 분리 관리)**에 직접 매핑된다.

## Scope

### Included

| # | Item | Description | Brief In Scope ref |
|---|------|-------------|------|
| 1 | CF account 사전 요구사항 | 계정 등록, billing, 도메인 nameserver 이전 또는 CNAME setup. 사용자 작업. | 1 |
| 2 | Workers project 초기화 | repo root에 `apps/workers-api` + `apps/workers-admin` 두 Worker (Hono) 또는 단일 Worker + route 분기. **Cycle 1은 단일 Worker + route 분기 채택** (1인 운영 단순성). | 1 |
| 3 | D1 DB 생성 | `wrangler d1 create personality-d1-prod`, `personality-d1-staging`. binding `DB`. | 1, 3 |
| 4 | R2 bucket 생성 | `personality-secrets`(sealed key 백업) + `personality-d1-backup`(자동 export) + `personality-uploads`(추후 사용 placeholder). | 1 (M14 보강) |
| 5 | KV namespace 생성 | `personality-kv-prod`, `personality-kv-staging`. binding `KV`. (BetterAuth secondary storage용) | 1, 6 |
| 6 | wrangler.toml 구조 | env: `production`, `preview`, `staging` × bindings (D1/R2/KV/secrets). routes 매핑(`api.<도메인>/*`, `admin.<도메인>/*`). | 1, 10 |
| 7 | Custom Domain | `api.<도메인>` (mobile API), `admin.<도메인>` (admin UI). DNS A/CNAME → Cloudflare Workers Routes. | 2 |
| 8 | TLS 자동화 | CF Universal SSL — DNS proxied 시 자동. 수동 작업 불요. | 2 |
| 9 | Cookie 도메인·SameSite 정책 | **Synthesis Conflict 2 결정 적용 (격리)** — `wrangler.toml` 또는 환경변수에 cookie domain 명시 (`api.<도메인>` host-scoped, `admin.<도메인>` host-scoped). 본 Cycle은 정책 명시만 — 실제 BetterAuth/CF Access 코드는 Cycle 4. | 2 (Med2) |
| 10 | Secrets 운영 모델 | 7개 secret 등록, R2 sealed 백업, 1Password entry. parallel-key rotation 절차 문서화(`docs/runbook/secret-rotation.md`). | 17 |
| 11 | D1 자동 export → R2 cron | `wrangler.toml` `[triggers]` cron(`0 17 * * 0` = 일요일 17:00 UTC) + Worker scheduled handler에서 `wrangler d1 export` 동등 SQL dump → `R2 put`. | 1 (M14) |
| 12 | CI/CD GitHub Actions | `.github/workflows/{deploy-prod.yml, preview.yml, staging.yml}` — production은 `main` push, preview는 PR, staging은 `staging` 브랜치. wrangler-action 사용. | 10 |
| 13 | GitHub Actions secret 주입 | `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID` GitHub repo secret 등록. Wrangler secret 자체는 GitHub Actions에서 set 안 함(이미 wrangler에 등록됨). | 17 |
| 14 | 최소 Hono `/health` 엔드포인트 | `apps/workers/src/index.ts` — `app.get('/health', ...)` 1개 라우트로 deploy 검증. | 5(prep) |

### Excluded

| Item | Reason/Timeline |
|------|-----------------|
| BetterAuth/CF Access 실제 코드 | Cycle 4 |
| Drizzle schema/migration | Cycle 2 |
| 도메인 services 이식 | Cycle 3 |
| 보안 baseline middleware (CORS/CSP/HSTS/rate limit) | Cycle 4 |
| 결제 endpoints | Cycle 7 |
| Workers Gradual Deployments(version overrides) | Cycle 10 위임 (Brief Med3) |
| WAF rule 세부 튜닝 | Cycle 4 / 운영 단계 |
| Logpush 활성화 | Cycle 10 monitoring |

## Structural Decisions

| # | Decision | Chosen Option | Rationale |
|---|----------|---------------|-----------|
| 1 | Worker 토폴로지 | **단일 Worker + route 분기** (`api.<도메인>/*` + `admin.<도메인>/*`) | 1인 운영자 단순성, 두 도메인이 동일 D1/KV/R2 binding 공유, deploy 1회. 향후 admin/api 분리가 필요해지면 별도 Worker로 분할 가능 (cost 작음). |
| 2 | Cookie 전략 | **격리 (host-scoped)** | Synthesis § 2 Conflict 2 결정. R4-F2. Brief Anchor 9 minor 정정 (synthesis가 흡수). 1인 운영자 + 모바일 주 클라이언트 환경에서 공유 가치 0, leakage 위험 제거. |
| 3 | Secrets 백업 위치 | **3중 (Wrangler secret + R2 sealed via age + 1Password)** | R4-F3. 키 분실 = 단일 실패점이므로 다중 백업 강제(Brief Constraint). |
| 4 | D1 backup 빈도 | **주 1회 cron + 분기 1회 복원 dry-run** | Brief Constraint M14. cron `0 17 * * 0` UTC = 한국시간 일요일 새벽 02:00. |
| 5 | CI/CD 환경 분리 | **production / preview / staging 3환경** | Brief Decision 11. preview = PR 단위 자동 URL, staging = 통합 검증, production = main. |
| 6 | wrangler.toml env 모델 | **`[env.production]` / `[env.staging]` 명시 + top-level은 development** | wrangler 권장 패턴. `--env preview`는 PR마다 동적 namespace로 staging env를 베이스로 사용. |

> 주: 본 Cycle은 Brief Decisions를 새로 만들지 않는다. Synthesis가 정합한 결정(Conflict 2 격리)을 운영 차원에서 적용만 한다.

---

## File Change Summary

### New Files

| # | File Path | Description |
|---|-----------|-------------|
| 1 | `apps/workers/wrangler.toml` | Worker 설정 — env(prod/staging) + bindings (D1/R2/KV) + routes + crons |
| 2 | `apps/workers/package.json` | dependencies: hono, wrangler(devDep), @cloudflare/workers-types(devDep), typescript |
| 3 | `apps/workers/tsconfig.json` | TypeScript config (Workers types) |
| 4 | `apps/workers/src/index.ts` | Hono app entry — `/health` route + scheduled handler stub (D1 backup) |
| 5 | `apps/workers/src/scheduled/d1-backup.ts` | D1 → R2 export 핸들러(주 1회 cron) |
| 6 | `apps/workers/src/lib/cookie-policy.ts` | cookie domain 결정 함수 (host에 따라 `api.<도메인>` 또는 `admin.<도메인>` 반환) — placeholder, Cycle 4에서 BetterAuth와 결합 |
| 7 | `.github/workflows/deploy-production.yml` | main push → wrangler deploy --env production |
| 8 | `.github/workflows/deploy-preview.yml` | PR open/sync → wrangler deploy --env preview, preview URL을 PR comment에 부착 |
| 9 | `.github/workflows/deploy-staging.yml` | staging 브랜치 push → wrangler deploy --env staging |
| 10 | `.github/workflows/_wrangler-deps.yml` | reusable workflow — wrangler setup + deps (DRY) |
| 11 | `docs/runbook/secret-rotation.md` | parallel-key rotation 절차 (R4-F3 인용) |
| 12 | `docs/runbook/cf-account-setup.md` | 사용자 직접 작업 체크리스트(계정·도메인·DNS) |
| 13 | `docs/runbook/d1-backup-restore.md` | D1 backup cron 동작 + 분기 1회 복원 dry-run 절차 |
| 14 | `apps/workers/.gitignore` | `.dev.vars`, `.wrangler/`, `node_modules/` |
| 15 | `apps/workers/README.md` | local dev (`wrangler dev`) + deploy 절차 |

### Modified Files

| # | File Path | Change Description |
|---|-----------|-------------------|
| 1 | `package.json` (repo root) | workspaces에 `apps/workers` 추가 (이미 monorepo) |
| 2 | `.gitignore` (repo root) | `apps/workers/.dev.vars`, `apps/workers/.wrangler/` 패턴 추가 |
| 3 | `CLAUDE.md` (repo root) | 모노레포 구조 표에 `apps/workers/` (CF Workers 백엔드) 추가 |

### Reviewed Files (read-only)

| # | File Path | Purpose |
|---|-----------|---------|
| 1 | `package.json` | 기존 workspaces 구조 확인 |
| 2 | `CLAUDE.md` | 모노레포 구조 섹션 위치 확인 |
| 3 | `server/Gemfile.lock` | 참조만 — 환경변수 명칭 일관성 |
| 4 | `docs/6_backend/02_cf_workers_rebuild/011_Research_axis4_auth_hybrid.md` | R4-F3 rotation 절차 인용 |
| 5 | `docs/6_backend/02_cf_workers_rebuild/018_Synthesis_research_cycle.md` | § 2 Conflict 2, § 5 Cycle 1 input |

---

## 사용자 입력 필요 지점 (User-Required Actions)

본 Cycle은 사용자 직접 작업이 plan 실행 중간 여러 지점에 등장한다. **Claude는 직접 실행하지 않으며, 각 지점에서 사용자 작업 완료를 확인한 후 후속 단계로 진행한다.** 모든 지점은 `docs/runbook/cf-account-setup.md`에 체크리스트 형태로 기록된다.

| # | 지점 | 사용자 작업 | 산출 |
|---|------|------------|------|
| U1 | Step 1 시작 전 | Cloudflare 계정 가입(이미 있으면 skip), Workers Paid plan 활성화(D1 사용) | account ID, 결제 카드 |
| U2 | Step 1 | 도메인 등록(또는 보유 도메인 선택). Cloudflare에 nameserver 이전 또는 CNAME setup | 도메인 root, DNS proxied 상태 |
| U3 | Step 2 | `wrangler login` (브라우저 OAuth) — Claude 직접 실행 불가 | wrangler 인증 토큰 로컬 저장 |
| U4 | Step 5 | `api.<도메인>`, `admin.<도메인>` DNS 레코드 추가(CF dashboard) — Workers route는 wrangler.toml에서 매핑하지만 hostname 등록은 dashboard 작업 | DNS A 레코드(또는 자동 routes) |
| U5 | Step 6 | 7개 secret 초기 값 생성·입력. Claude는 명령어를 제시, 사용자가 `wrangler secret put` 대화형 prompt에 값 입력 | secret 등록 완료 |
| U6 | Step 6 | 1Password vault entry "personality CF secrets" 생성 + 7개 값 저장 | 1Password 백업 |
| U7 | Step 7 | GitHub repo settings → Actions secrets에 `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID` 등록. API Token은 dashboard에서 "Edit Cloudflare Workers" template로 생성 | GitHub Actions secret 2건 |
| U8 | Step 7 | (도메인 nameserver가 외부에 있으면) DNS provider 측 CNAME 추가 | DNS 활성화 |

> Claude의 역할: (a) 명령어 정확히 제시, (b) 사용자가 작업 완료 후 값(account ID, 도메인 등)을 알려주면 wrangler.toml에 반영, (c) 검증 명령(`wrangler d1 list` 등) 실행하여 사용자 작업 결과 검증.

---

## Step 1 — CF Account 사전 요구사항 (User U1, U2)

### Approach

사용자가 CF 계정·도메인·결제·DNS proxy를 활성화한다. Claude는 체크리스트 문서를 작성하고 결과 값(account ID, root domain)을 받는다.

### 산출

`docs/runbook/cf-account-setup.md` 작성 (체크리스트 형식):

```markdown
# CF Account Setup Runbook

## 1. 계정
- [ ] dash.cloudflare.com 가입
- [ ] account ID 확인 (Dashboard → 우측 사이드바 → Account ID)
- [ ] Workers Paid plan 활성화 ($5/month, D1 사용 전제)

## 2. 도메인
- [ ] root domain 결정: `____________` (예: `personality.app`)
- [ ] CF에 도메인 등록(zone 생성) 또는 nameserver 이전
- [ ] DNS proxied(orange cloud) 활성화

## 3. 결과 값 (Claude에 전달)
- account ID: `________________`
- root domain: `________________`
```

### 검증

`wrangler whoami` → account ID 확인.

### Impact Analysis
- **Imports/types**: 없음
- **Tests**: 없음
- **Config**: account ID·root domain은 Step 2의 wrangler.toml `account_id`와 routes에 반영
- **Cascade**: 모든 후속 step의 전제

---

## Step 2 — Workers Project 초기화 (User U3)

### Approach

`apps/workers/` 폴더에 Hono 기반 Workers 프로젝트를 만든다. 단일 Worker + route 분기 토폴로지(Decision 1).

### Commands (사용자 또는 Claude 실행)

```bash
# repo root에서
mkdir -p apps/workers/src/{routes,scheduled,lib}
cd apps/workers
npm init -y
npm install hono
npm install -D wrangler typescript @cloudflare/workers-types @types/node
```

### After Code

`apps/workers/package.json`:

```json
{
  "name": "@personality/workers",
  "version": "0.0.1",
  "type": "module",
  "private": true,
  "scripts": {
    "dev": "wrangler dev",
    "deploy:prod": "wrangler deploy --env production",
    "deploy:staging": "wrangler deploy --env staging",
    "d1:create:prod": "wrangler d1 create personality-d1-prod",
    "d1:create:staging": "wrangler d1 create personality-d1-staging",
    "secrets:list:prod": "wrangler secret list --env production",
    "type-check": "tsc --noEmit"
  },
  "dependencies": {
    "hono": "^4.6.0"
  },
  "devDependencies": {
    "@cloudflare/workers-types": "^4.20260101.0",
    "@types/node": "^22.0.0",
    "typescript": "^5.6.0",
    "wrangler": "^3.90.0"
  }
}
```

`apps/workers/tsconfig.json`:

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ES2022",
    "moduleResolution": "Bundler",
    "lib": ["ES2022"],
    "types": ["@cloudflare/workers-types"],
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "isolatedModules": true,
    "resolveJsonModule": true
  },
  "include": ["src/**/*.ts"]
}
```

`apps/workers/src/index.ts` (entry, `/health` only):

```typescript
import { Hono } from "hono";

type Bindings = {
  DB: D1Database;
  KV: KVNamespace;
  R2_BACKUP: R2Bucket;
  R2_SECRETS: R2Bucket;
  R2_UPLOADS: R2Bucket;
  ENV: "production" | "staging" | "preview" | "development";
};

const app = new Hono<{ Bindings: Bindings }>();

app.get("/health", (c) => {
  const host = c.req.header("host") ?? "";
  const plane =
    host.startsWith("admin.") ? "admin" :
    host.startsWith("api.") ? "api" :
    "dev";
  return c.json({
    ok: true,
    plane,
    env: c.env.ENV,
    timestamp: new Date().toISOString(),
  });
});

// Cycle 1은 health만 — 실제 routes는 후속 cycles
app.notFound((c) => c.json({ error: "not found" }, 404));

export { scheduled } from "./scheduled/d1-backup";
export default app;
```

`apps/workers/src/lib/cookie-policy.ts` (placeholder, Cycle 4에서 BetterAuth와 결합):

```typescript
// Synthesis § 2 Conflict 2 — 격리 정책
// Cycle 4(BetterAuth/CF Access)에서 실제 cookie 발급 시 본 함수 사용

export function cookieDomainForHost(host: string): string | null {
  if (host.startsWith("api.")) return host;       // host-scoped
  if (host.startsWith("admin.")) return host;     // host-scoped (CF_Authorization도 자동)
  return null;                                     // dev / fallback
}

export const COOKIE_DEFAULTS = {
  sameSite: "Lax" as const,
  secure: true,
  httpOnly: true,
  path: "/",
};
```

### 검증

```bash
cd apps/workers
npm run type-check    # exit 0
npx wrangler dev --local --port 8787 &
curl http://localhost:8787/health  # {"ok":true,"plane":"dev",...}
```

### Impact Analysis
- **Imports/types**: hono, @cloudflare/workers-types — Workers 표준 환경
- **Tests**: 본 Cycle은 procedural — Vitest는 Cycle 2부터
- **Config**: monorepo `package.json` workspaces에 `"apps/workers"` 추가 필요
- **Cascade**: Cycle 2 (Drizzle schema)가 본 Worker 위에 D1 binding 사용

---

## Step 3 — D1 / R2 / KV 리소스 생성 (Claude + 사용자 wrangler login)

### Approach

`wrangler` CLI로 production·staging 환경의 D1·R2·KV 리소스를 만든다. 각 명령은 ID를 반환 — wrangler.toml에 기입한다.

### Commands

```bash
cd apps/workers

# D1
wrangler d1 create personality-d1-prod
# 출력: database_id = "abcd-1234-..." → 기록
wrangler d1 create personality-d1-staging

# R2
wrangler r2 bucket create personality-d1-backup
wrangler r2 bucket create personality-secrets
wrangler r2 bucket create personality-uploads
wrangler r2 bucket create personality-d1-backup-staging
wrangler r2 bucket create personality-uploads-staging
# secrets bucket은 prod 1개만 (sealed key는 환경 무관)

# KV
wrangler kv namespace create personality-kv-prod
# 출력: id = "xxxx" → 기록
wrangler kv namespace create personality-kv-staging
wrangler kv namespace create personality-kv-prod --preview
wrangler kv namespace create personality-kv-staging --preview
```

### Bash dialect 가정

본 Cycle의 모든 shell 명령은 zsh/bash 공통 사용. `wrangler` CLI 출력 파싱(`grep`/`sed`)은 사용하지 않음 — ID는 사용자가 수동 복사하여 wrangler.toml에 붙여넣는다.

### 검증

```bash
wrangler d1 list           # 2개 (prod + staging) 노출
wrangler r2 bucket list    # 5개 노출
wrangler kv namespace list # 4개 노출 (preview 포함)
```

### Impact Analysis
- **Cascade**: 본 ID들이 Step 4 wrangler.toml에 그대로 반영. Cycle 2(DB Layer)가 D1 binding 사용.
- **State**: CF 계정 측면에 영구 리소스 생성. 잘못 만들면 `wrangler d1 delete`로 제거 가능(파괴적, dry-run 없음).

---

## Step 4 — wrangler.toml 작성

### Approach

3환경(production / staging / development) + 2 routes(api·admin) + bindings(D1·R2·KV) + crons + observability를 하나의 toml에 표현. development는 top-level, prod/staging은 `[env.X]`로 격리.

### After Code

`apps/workers/wrangler.toml`:

```toml
name = "personality-workers"
main = "src/index.ts"
compatibility_date = "2026-04-01"
compatibility_flags = ["nodejs_compat"]
account_id = "<U1에서 받은 account ID>"

# top-level = development (wrangler dev 기본)
[vars]
ENV = "development"

[[d1_databases]]
binding = "DB"
database_name = "personality-d1-prod"
database_id = "<Step 3에서 받은 prod D1 ID>"

[[kv_namespaces]]
binding = "KV"
id = "<Step 3 prod KV ID>"
preview_id = "<Step 3 prod KV preview ID>"

[[r2_buckets]]
binding = "R2_BACKUP"
bucket_name = "personality-d1-backup"

[[r2_buckets]]
binding = "R2_SECRETS"
bucket_name = "personality-secrets"

[[r2_buckets]]
binding = "R2_UPLOADS"
bucket_name = "personality-uploads"

# observability — 운영 단계에서 logs 자동 수집
[observability]
enabled = true

# ─────────────────────────────────────────────
# production
# ─────────────────────────────────────────────
[env.production]
name = "personality-workers"
routes = [
  { pattern = "api.<도메인>/*", zone_name = "<도메인>" },
  { pattern = "admin.<도메인>/*", zone_name = "<도메인>" },
]

[env.production.vars]
ENV = "production"

[[env.production.d1_databases]]
binding = "DB"
database_name = "personality-d1-prod"
database_id = "<prod D1 ID>"

[[env.production.kv_namespaces]]
binding = "KV"
id = "<prod KV ID>"

[[env.production.r2_buckets]]
binding = "R2_BACKUP"
bucket_name = "personality-d1-backup"

[[env.production.r2_buckets]]
binding = "R2_SECRETS"
bucket_name = "personality-secrets"

[[env.production.r2_buckets]]
binding = "R2_UPLOADS"
bucket_name = "personality-uploads"

# D1 자동 backup 주 1회 (일요일 02:00 KST = 17:00 UTC 토)
[env.production.triggers]
crons = ["0 17 * * 0"]

# ─────────────────────────────────────────────
# staging
# ─────────────────────────────────────────────
[env.staging]
name = "personality-workers-staging"
routes = [
  { pattern = "staging-api.<도메인>/*", zone_name = "<도메인>" },
  { pattern = "staging-admin.<도메인>/*", zone_name = "<도메인>" },
]

[env.staging.vars]
ENV = "staging"

[[env.staging.d1_databases]]
binding = "DB"
database_name = "personality-d1-staging"
database_id = "<staging D1 ID>"

[[env.staging.kv_namespaces]]
binding = "KV"
id = "<staging KV ID>"

[[env.staging.r2_buckets]]
binding = "R2_BACKUP"
bucket_name = "personality-d1-backup-staging"

[[env.staging.r2_buckets]]
binding = "R2_SECRETS"
bucket_name = "personality-secrets"

[[env.staging.r2_buckets]]
binding = "R2_UPLOADS"
bucket_name = "personality-uploads-staging"
```

### 비고

- `preview` 환경은 별도 `[env.preview]`를 만들지 않고 GitHub Actions(deploy-preview.yml)에서 `--name personality-workers-pr-{NUMBER}`로 동적 생성. PR마다 별도 Worker, staging의 D1/KV/R2 bindings 재사용.
- `compatibility_date = 2026-04-01` — 본 Cycle 작성 시점 기준 안정 date.
- `<도메인>` placeholder는 사용자가 U1에서 결정한 root domain으로 일괄 치환(예: `personality.app`).

### 검증

```bash
cd apps/workers
wrangler deploy --env production --dry-run
# "Total Upload: ... KiB" 출력, 에러 없음

wrangler deploy --env staging --dry-run
```

### Impact Analysis
- **Cascade**: bindings 이름(`DB`, `KV`, `R2_BACKUP`, `R2_SECRETS`, `R2_UPLOADS`)은 Cycle 2~7의 모든 코드에서 동일 식별자로 사용.
- **Tests**: 없음(설정 파일).

---

## Step 5 — Custom Domain + TLS (User U4)

### Approach

`api.<도메인>`, `admin.<도메인>`, `staging-api.<도메인>`, `staging-admin.<도메인>` 4개 hostname을 CF에 등록한다. wrangler.toml의 `routes`가 매칭되도록 zone에 DNS 레코드 추가.

### 사용자 작업 (U4)

CF Dashboard → DNS → Records:

```
A     api              192.0.2.1   Proxied  (placeholder, 실제 IP는 routes로 우회됨)
A     admin            192.0.2.1   Proxied
A     staging-api      192.0.2.1   Proxied
A     staging-admin    192.0.2.1   Proxied
```

> CF Workers Custom Domain은 DNS 레코드의 IP를 사실상 무시하고 Worker로 라우팅. proxied(orange cloud)만 보장하면 됨. 더 깔끔한 방법: Dashboard → Workers → Custom Domains에서 직접 도메인 추가(이 경우 DNS 레코드 자동 생성).

### TLS

Universal SSL이 zone 등록 직후 자동 발급. 별도 설정 불요. SSL/TLS 모드는 "Full (strict)" 권장 — Worker는 origin이 없으므로 어떤 모드든 영향 없지만 강한 모드가 안전.

### Cookie 정책 명시 (Synthesis Conflict 2)

Cookie 격리는 Cycle 4(BetterAuth/CF Access)에서 코드 레벨로 적용되지만, 본 Cycle에서 정책 문서로 못박는다:

`docs/runbook/cf-account-setup.md`에 추가:

```markdown
## Cookie 격리 정책 (Synthesis § 2 Conflict 2)

- api.<도메인>: BetterAuth session cookie, domain=api.<도메인> (host-scoped), SameSite=Lax, Secure, HttpOnly
- admin.<도메인>: CF_Authorization, domain=admin.<도메인> (host-scoped, CF Access 자동)
- 두 평면 cookie 격리 — 누출 0
```

### 검증

```bash
# DNS proxy 확인
dig api.<도메인> +short    # CF IP

# TLS 확인
curl -I https://api.<도메인>/health    # HTTP/2 200, TLSv1.3 (Worker deploy 후)

# admin은 CF Access 정책 적용 후 (Cycle 4)에서야 challenge 응답
```

### Impact Analysis
- **Cascade**: Cycle 4가 cookie domain 결정 시 본 정책 인용 (`cookie-policy.ts`).
- **사용자 작업**: U4 — DNS record 등록은 Claude 직접 불가.

---

## Step 6 — Secrets 운영 모델 (User U5, U6)

### Approach

7개 secret을 Wrangler에 등록 + R2 sealed 백업(age) + 1Password 기록. parallel-key rotation 절차는 R4-F3을 그대로 인용한 runbook에 정리.

### 7개 Secrets 목록

| # | Secret name | 용도 | 생성 방식 | 회전 주기 |
|---|-------------|------|----------|----------|
| 1 | `PERSONALITY_ENCRYPTION_KEY` | AES-256-GCM 결정성 암호화 (User.email) | `openssl rand -base64 32` | 12개월 |
| 2 | `PERSONALITY_ENCRYPTION_KEY_OLD` | parallel-key rotation Phase 1~5의 read-fallback | (회전 시점에만 set) | per-rotation |
| 3 | `BETTERAUTH_SECRET` | BetterAuth `secret` config (HMAC for sign session JWT) | `openssl rand -base64 32` | 12개월 |
| 4 | `JWT_SECRET` | (예비) 모바일 Bearer JWT 서명 (Cycle 4) | `openssl rand -base64 32` | 12개월 |
| 5 | `TOSS_SECRET_KEY` | Toss Payments 서버 키 | Toss 가맹점 콘솔 발급 | Toss 정책 |
| 6 | `TOSS_WEBHOOK_SECRET` | Toss 결제 webhook 서명 검증(모델 A: secret 비교) | Toss 가맹점 콘솔 발급 | Toss 정책 |
| 7 | `CF_ACCESS_AUD` | CF Access JWT audience tag (admin 검증 · 비밀은 아니지만 환경별 분리 위해 secret으로 보관) | CF Access Application 발급 | application 변경 시 |

> 추후 Cycle 4에서 admin operator 추가 시 `CF_ACCESS_TEAM_DOMAIN`도 추가 가능 (현재는 vars로 충분).

### 등록 명령 (U5 — 사용자 대화형 입력)

```bash
cd apps/workers

# production
for KEY in PERSONALITY_ENCRYPTION_KEY BETTERAUTH_SECRET JWT_SECRET TOSS_SECRET_KEY TOSS_WEBHOOK_SECRET CF_ACCESS_AUD; do
  echo "→ Enter value for $KEY (production):"
  wrangler secret put $KEY --env production
done

# staging — 운영자 1인 가정 → 동일 값 또는 별도 값 (테스트 환경에선 별도 권장)
for KEY in PERSONALITY_ENCRYPTION_KEY BETTERAUTH_SECRET JWT_SECRET TOSS_SECRET_KEY TOSS_WEBHOOK_SECRET CF_ACCESS_AUD; do
  echo "→ Enter value for $KEY (staging):"
  wrangler secret put $KEY --env staging
done
```

> `wrangler secret put`은 stdin 대화형. CI에서 비대화 등록은 `--env production` + stdin pipe(`echo "$VAL" | wrangler secret put KEY ...`) 가능하지만 본 Cycle에선 사용자 직접 입력 권장.

### R2 sealed 백업 (Decision 3)

`age`(<https://age-encryption.org/>) 사용. 운영자 1인의 age public key를 recipient로.

```bash
# 운영자 측에서 1회 (key 생성)
age-keygen -o ~/.config/age/personality-recovery.txt
# 출력: public key "age1xyz..." → 백업 시 -r flag

# 각 secret 값을 sealed로 R2에 저장 (회전 시 함께 갱신)
mkdir -p tmp/secrets-staging
echo "$VAL_K_1" > tmp/secrets-staging/PERSONALITY_ENCRYPTION_KEY.txt
age -e -r age1xyz... tmp/secrets-staging/PERSONALITY_ENCRYPTION_KEY.txt > tmp/secrets-staging/key_1.age
wrangler r2 object put personality-secrets/PERSONALITY_ENCRYPTION_KEY/v1.age \
  --file=tmp/secrets-staging/key_1.age \
  --env production
rm -rf tmp/secrets-staging   # 평문 즉시 삭제
```

> R2 sealed 백업은 회전 시점에만 갱신. 일상 운영에선 Wrangler secret이 단일 진실의 원천(SOT).

### 1Password Backup (U6)

vault entry "personality CF secrets" 생성 (사용자 직접). 7개 항목 + age private key + recovery 절차 메모.

### Rotation 절차 (parallel-key — R4-F3 인용)

`docs/runbook/secret-rotation.md` 작성:

```markdown
# Secret Rotation Runbook

본 절차는 R4-F3 parallel-key 패턴 그대로. PERSONALITY_ENCRYPTION_KEY 예시.

## Phase 0 — 정상 운영
PERSONALITY_ENCRYPTION_KEY     = K_n        (write + read)
PERSONALITY_ENCRYPTION_KEY_OLD = (unset)

## Phase 1 — 새 키 생성 + dual-read 활성화
$ openssl rand -base64 32 > /tmp/K_new.txt
$ wrangler secret put PERSONALITY_ENCRYPTION_KEY_OLD --env production  # 현재 K_n 입력
$ wrangler secret put PERSONALITY_ENCRYPTION_KEY     --env production  # /tmp/K_new.txt 값 입력
# Worker 코드 (Cycle 4 encryption.ts):
#   encrypt(K_new); decrypt(try K_new → fallback K_old)

## Phase 2 — 기존 ciphertext 재암호화
# 옵션 A (lazy): 사용자 next-login 시 자동
# 옵션 B (batch): Cron Trigger 기반 — 1000 row/batch
$ wrangler d1 execute personality-d1-prod --command "
    SELECT count(*) FROM users WHERE encryption_version = $((n))
  "  # 0이 될 때까지 대기

## Phase 3 — 검증
$ wrangler d1 execute personality-d1-prod --command "
    SELECT count(*) FROM users WHERE encryption_version != $((n+1))
  "  # = 0 이어야 진행

## Phase 4 — 외부 백업 갱신 (R2 sealed)
$ age -e -r age1xyz... /tmp/K_new.txt > /tmp/key_$((n+1)).age
$ wrangler r2 object put personality-secrets/PERSONALITY_ENCRYPTION_KEY/v$((n+1)).age \
    --file=/tmp/key_$((n+1)).age --env production
$ rm /tmp/K_new.txt /tmp/key_$((n+1)).age   # 평문 즉시 삭제

## Phase 5 — K_n 폐기
$ wrangler secret delete PERSONALITY_ENCRYPTION_KEY_OLD --env production
# K_n은 R2 sealed 백업에만 잔존 — 포렌식 / 미회전 row 발견 시 복구용

## 1Password 갱신
- entry "personality CF secrets" — 새 K_{n+1}, 갱신 일자, age 파일 R2 키 기록
```

### 검증

```bash
wrangler secret list --env production
# 7개 secret 모두 노출 (이름만 — 값 안 보임)

wrangler r2 object list personality-secrets --env production
# 최소 1개 sealed 파일 노출

# 1Password — 사용자 자가 확인
```

### Impact Analysis
- **Cascade**: Cycle 4의 `lib/auth/encryption.ts`가 `PERSONALITY_ENCRYPTION_KEY` + `_OLD` 두 secret을 read하여 parallel-key 적용. Cycle 7(Toss webhook)이 `TOSS_WEBHOOK_SECRET` 사용.
- **Risk**: 1Password 백업이 안 되어 있고 Wrangler secret이 손실될 경우 R2 sealed로만 복구 가능. age private key는 운영자 PC에만 — 분실 시 복구 불가 → 1Password에 age key도 함께 저장 강제.

---

## Step 7 — GitHub Actions CI/CD (User U7)

### Approach

세 환경(production / preview / staging)별 워크플로 파일 + 공유 reusable workflow. wrangler-action(`cloudflare/wrangler-action@v3`) 사용.

### 사용자 작업 (U7)

GitHub repo settings → Secrets and variables → Actions → New repository secret:

| Name | Value |
|------|-------|
| `CLOUDFLARE_API_TOKEN` | CF Dashboard → My Profile → API Tokens → "Edit Cloudflare Workers" template로 생성 |
| `CLOUDFLARE_ACCOUNT_ID` | U1에서 받은 account ID |

> Wrangler secret 자체(7개)는 GitHub Actions에서 set하지 않음 — wrangler에 이미 등록되어 있고 deploy 시 자동 주입됨.

### After Code

`.github/workflows/deploy-production.yml`:

```yaml
name: Deploy Production
on:
  push:
    branches: [main]
    paths:
      - "apps/workers/**"
      - ".github/workflows/deploy-production.yml"

concurrency:
  group: deploy-production
  cancel-in-progress: false

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      deployments: write
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "22"
          cache: "npm"
          cache-dependency-path: apps/workers/package-lock.json
      - name: Install
        working-directory: apps/workers
        run: npm ci
      - name: Type check
        working-directory: apps/workers
        run: npm run type-check
      - name: Deploy
        uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          workingDirectory: apps/workers
          command: deploy --env production
```

`.github/workflows/deploy-staging.yml`:

```yaml
name: Deploy Staging
on:
  push:
    branches: [staging]
    paths:
      - "apps/workers/**"
      - ".github/workflows/deploy-staging.yml"

concurrency:
  group: deploy-staging
  cancel-in-progress: true

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "22"
          cache: "npm"
          cache-dependency-path: apps/workers/package-lock.json
      - run: npm ci
        working-directory: apps/workers
      - run: npm run type-check
        working-directory: apps/workers
      - uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          workingDirectory: apps/workers
          command: deploy --env staging
```

`.github/workflows/deploy-preview.yml`:

```yaml
name: Deploy Preview (PR)
on:
  pull_request:
    types: [opened, synchronize, reopened]
    paths:
      - "apps/workers/**"
      - ".github/workflows/deploy-preview.yml"

concurrency:
  group: preview-${{ github.event.pull_request.number }}
  cancel-in-progress: true

jobs:
  deploy-preview:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "22"
          cache: "npm"
          cache-dependency-path: apps/workers/package-lock.json
      - run: npm ci
        working-directory: apps/workers
      - run: npm run type-check
        working-directory: apps/workers
      - name: Deploy preview Worker
        id: deploy
        uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          workingDirectory: apps/workers
          # PR 번호 기반 동적 name + staging env 베이스
          command: >
            deploy
            --env staging
            --name personality-workers-pr-${{ github.event.pull_request.number }}
            --route ""
      - name: Comment preview URL on PR
        uses: actions/github-script@v7
        with:
          script: |
            const url = `https://personality-workers-pr-${context.issue.number}.<account>.workers.dev`;
            const body = `Preview deployed: ${url}/health`;
            await github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body,
            });
```

> `<account>`는 deploy 후 wrangler 출력 파싱하거나 정적으로 운영자 subdomain(`<운영자>.workers.dev`) 알고 있다면 직접 기입. 더 깔끔한 방식은 wrangler-action 출력 `deployment-url` step output을 사용 — wrangler-action v3가 출력 노출한다면 그것을 우선.

### 검증

- 본 PR을 만들어 preview workflow trigger → PR comment에 preview URL 부착 → curl로 `/health` 확인.
- `main`에 push → production workflow trigger → `https://api.<도메인>/health` HTTP 200.

### Impact Analysis
- **Cascade**: 모든 후속 cycle의 코드 변경이 본 workflow를 통해 자동 deploy.
- **Tests**: workflow 자체는 ad-hoc; act(<https://github.com/nektos/act>)로 로컬 dry-run 가능하지만 본 Cycle 검증은 실제 PR로 충분.

---

## Step 8 — D1 자동 backup → R2 cron (M14)

### Approach

`wrangler.toml`에 등록한 cron(`0 17 * * 0`)이 Worker `scheduled` handler를 호출. handler는 D1 → SQL dump → R2 put.

### After Code

`apps/workers/src/scheduled/d1-backup.ts`:

```typescript
// Cron handler: 주 1회 D1 → R2 export
// Brief In Scope 1 (M14 보강), Constraint "D1 export → R2 주 1회 이상"

type Bindings = {
  DB: D1Database;
  R2_BACKUP: R2Bucket;
  ENV: string;
};

export const scheduled: ExportedHandlerScheduledHandler<Bindings> =
  async (event, env, ctx) => {
    ctx.waitUntil(performBackup(env, event.scheduledTime));
  };

async function performBackup(env: Bindings, scheduledTime: number): Promise<void> {
  const ts = new Date(scheduledTime).toISOString().replace(/[:.]/g, "-");
  const key = `${env.ENV}/d1-backup-${ts}.sql`;

  // 1) 모든 테이블 목록 (Cycle 1 시점엔 schema 미존재 — empty 가능)
  const tablesRes = await env.DB.prepare(
    `SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE '_cf_%'`
  ).all<{ name: string }>();
  const tables = tablesRes.results ?? [];

  // 2) 각 테이블의 schema + data를 SQL 형태로 dump
  const lines: string[] = [];
  lines.push(`-- D1 Backup ${ts} | env=${env.ENV} | tables=${tables.length}`);
  for (const { name } of tables) {
    const schemaRes = await env.DB.prepare(
      `SELECT sql FROM sqlite_master WHERE type='table' AND name = ?`
    ).bind(name).first<{ sql: string }>();
    if (schemaRes?.sql) lines.push(`${schemaRes.sql};`);

    const rowsRes = await env.DB.prepare(`SELECT * FROM ${name}`).all();
    for (const row of rowsRes.results ?? []) {
      const cols = Object.keys(row).join(", ");
      const vals = Object.values(row)
        .map((v) =>
          v === null
            ? "NULL"
            : typeof v === "number"
            ? String(v)
            : `'${String(v).replace(/'/g, "''")}'`
        )
        .join(", ");
      lines.push(`INSERT INTO ${name} (${cols}) VALUES (${vals});`);
    }
  }

  // 3) R2 put
  const body = lines.join("\n");
  await env.R2_BACKUP.put(key, body, {
    httpMetadata: { contentType: "application/sql" },
    customMetadata: { env: env.ENV, scheduledTime: String(scheduledTime) },
  });
}
```

### 비고

- Cycle 1 시점엔 D1에 테이블이 없을 수 있음 — handler는 0건도 정상 처리(빈 SQL 헤더만).
- 본 dump는 **D1 단일 스레드 + Workers 30s CPU time** 한도 내에서 작동. row 수가 수천 단위까지 안전. 그 이상이면 chunk 또는 D1 export REST API로 전환(Cycle 10에서 재검토).
- `scheduled`는 `index.ts`의 `export { scheduled } from "./scheduled/d1-backup"`로 노출.

### 분기 1회 복원 dry-run (Brief Constraint M14)

`docs/runbook/d1-backup-restore.md` 작성. 실제 dry-run은 Cycle 10 cutover safety에서 시행, 본 Cycle은 절차 문서화만:

```markdown
# D1 Backup & Restore Runbook

## 자동 backup
- Cron: `0 17 * * 0` (UTC) = 한국 일요일 02:00 KST
- Source: D1 production
- Sink: R2 personality-d1-backup, key=`production/d1-backup-YYYY-MM-DDTHH-MM-SS.sql`

## 수동 검증 dry-run (Cycle 1 직후)
$ wrangler triggers cron --env production --cron "0 17 * * 0"
# CF dashboard → Workers → Triggers → Test
# 1분 내 R2 bucket에 새 파일 노출되어야 함

$ wrangler r2 object list personality-d1-backup --env production
# 최소 1개 객체 노출

## 분기 복원 dry-run (Cycle 10에서 시행)
1. 최신 backup 다운로드
2. staging D1에 신규 namespace 생성
3. SQL 파일을 wrangler d1 execute로 import
4. row count 비교: production vs restored
5. 결과 기록 (docs/runbook/restore-drill-YYYY-Q.md)
```

### 검증

```bash
# wrangler triggers schedule을 수동 트리거 (dashboard 또는 CLI)
# CF dashboard → Workers → personality-workers → Triggers → Cron Triggers → "Run now"

# 결과 확인
wrangler r2 object list personality-d1-backup --env production
# d1-backup-2026-04-29T... 파일 노출
```

### Impact Analysis
- **Cascade**: Cycle 9(cutover safety)가 본 backup을 분기 1회 복원 dry-run 대상으로 사용. Cycle 10에서 retro 시 backup 누적량 확인.
- **Tests**: 없음(scheduled 핸들러는 wrangler cron trigger 수동 실행으로 검증).

---

## Step 9 — Repo 통합 (root files 갱신)

### Approach

repo root의 `package.json`(workspaces)·`.gitignore`·`CLAUDE.md`(모노레포 구조 표)를 갱신하여 `apps/workers/`를 정식 멤버로 등록.

### Modified Code

repo root `package.json` 변경(workspaces 배열에 추가):

```json
{
  "workspaces": [
    "apps/*"
  ]
}
```

> 기존 root `package.json`이 monorepo workspaces 미설정이면 본 Cycle에서 추가. `apps/workers`는 그 첫 멤버가 됨. 다른 기존 패키지(`mobile/`, `server/`)는 별도 워크플로(Flutter, Bundler)이므로 워크스페이스에 안 넣음.

repo root `.gitignore` 추가:

```
# Cloudflare Workers
apps/workers/.dev.vars
apps/workers/.wrangler/
apps/workers/node_modules/
```

repo root `CLAUDE.md` 모노레포 구조 표에 추가 (위치: "## 모노레포 구조" 섹션):

```markdown
- `apps/workers/` — Cloudflare Workers 백엔드 (Hono, D1, R2, KV — 본 사이클 1부터 가동)
```

### 검증

```bash
git status   # apps/workers 외 root 갱신만 노출
npm install  # workspace 인식 확인 (root에서)
```

### Impact Analysis
- **Cascade**: 모든 향후 Cycle이 `apps/workers` 위에서 작업. CLAUDE.md가 alignment anchor — 다음 Cycle 진입 시 새 폴더 인지.
- **Tests**: 없음.

---

## Considerations & Trade-offs

### Structural Decisions Log

위 Structural Decisions 테이블(6건) 참조. 각 결정의 출처는 Synthesis(018) 또는 R4(011)이며, 본 Cycle은 결정을 운영 차원으로 적용만 한다.

### Alternative Approaches

| 대안 | 기각 사유 |
|------|----------|
| api/admin 별도 Worker (2개) | 1인 운영자에게 deploy 2배 + binding 중복 — Decision 1로 단일 Worker 채택. 향후 분리 가능. |
| Cookie 공유 (cross-subdomain) | Synthesis Conflict 2 정합 — 격리. R4-F2. |
| Secrets 단일 백업 (Wrangler만) | Brief Constraint "단일 실패점이므로 다중 백업" 위반. |
| D1 backup 일 1회 | Brief Constraint는 "주 1회 이상" — 일 1회는 over-engineering, R2 비용 ↑. 운영 단계에서 필요 시 상향. |
| GitHub Actions에서 7개 secret 모두 set | Wrangler secret이 SOT — GitHub Actions는 deploy만 담당, secrets 중복 관리는 drift 위험. |
| `act`로 workflow 로컬 dry-run | Cycle 1 검증엔 실제 PR이 더 신뢰 가능. `act` 채택은 Cycle 10 운영 단계 옵션. |

### Potential Risks

| # | Risk | 완화 |
|---|------|------|
| 1 | 사용자가 Workers Paid plan 미활성화 → D1 사용 불가 | runbook에 명시 + `wrangler d1 create` 시점에 즉시 발견 |
| 2 | 도메인 nameserver 이전 미완료 → routes 매핑 실패 | Step 1에서 zone status 확인 강제 |
| 3 | age private key 분실 → R2 sealed 백업 복구 불가 | 1Password에 age private key도 함께 저장 강제 (Step 6) |
| 4 | wrangler secret 평문이 셸 history에 잔존 | `wrangler secret put`은 stdin 대화형 + history-mask 권장 (`HISTCONTROL=ignorespace`로 스페이스 prefix) |
| 5 | preview Worker 누적 → CF 자원 한도 초과 | PR close 시 자동 cleanup workflow 추가는 Cycle 10에서 검토 |
| 6 | Cron trigger가 staging에 미설정 → staging backup 부재 | staging은 backup 불요(데이터 휘발 가능) — 의도적 |
| 7 | API Token 권한 과다 → 사고 시 영향 | "Edit Cloudflare Workers" 템플릿이 D1·R2·KV·Workers·Routes로 한정 — 충분 |
| 8 | Cycle 1 시점 D1 schema 부재 → backup이 빈 SQL | 정상 동작, Cycle 2에서 schema 마이그 후 다음 cron부터 의미 있는 dump |

### Backward Compatibility

- 기존 Rails 서버(`server/`) 변경 0. 새 폴더 추가만.
- 기존 Flutter 앱(`mobile/`) 변경 0. 본 Cycle은 API 미공개(`/health`만).
- 향후 사이클이 본 wrangler.toml binding 이름(`DB`, `KV`, `R2_*`)을 강제 의존 — 변경 시 모든 Cycle 재작업 risk → 본 Cycle에서 명명을 신중히 결정 (이미 충분히 보편적).

---

## Implementation Checklist

- [ ] Step 1: CF account 사전 요구사항 + cf-account-setup runbook 작성 (U1, U2)
- [ ] Step 2: `apps/workers` 프로젝트 초기화 (package.json, tsconfig, src/index.ts, cookie-policy.ts) (U3)
- [ ] Step 3: D1·R2·KV 리소스 생성 (prod + staging)
- [ ] Step 4: wrangler.toml 작성 (3환경 + 2 routes + bindings + cron)
- [ ] Step 5: Custom Domain DNS 등록 + cookie 격리 정책 runbook 추가 (U4)
- [ ] Step 6: 7개 secret 등록 + R2 sealed 백업 + 1Password 기록 + secret-rotation runbook (U5, U6)
- [ ] Step 7: GitHub Actions 3개 workflow + GitHub Actions secret 등록 (U7)
- [ ] Step 8: D1 backup cron handler 구현 + 수동 trigger 검증 + d1-backup-restore runbook
- [ ] Step 9: repo root package.json / .gitignore / CLAUDE.md 갱신
- [ ] Final: `https://api.<도메인>/health` HTTP 200 + `wrangler secret list` 7건 + R2 sealed 1건 + GitHub PR preview comment 부착 검증

---

## Verification Assertions

| Level | Assertion | Verification Method | Expected Result |
|-------|-----------|-------------------|-----------------|
| L1-Build | TypeScript 타입 체크 통과 | `cd apps/workers && npm run type-check` | exit 0, 에러 0건 |
| L1-Build | wrangler dry-run 성공 | `wrangler deploy --env production --dry-run` | "Total Upload" 출력, 에러 0 |
| L2-CLI | D1 prod/staging 노출 | `wrangler d1 list` | 2개 (`personality-d1-prod`, `personality-d1-staging`) |
| L2-CLI | R2 5개 bucket 노출 | `wrangler r2 bucket list` | `personality-d1-backup`, `personality-secrets`, `personality-uploads`, `personality-d1-backup-staging`, `personality-uploads-staging` |
| L2-CLI | KV 4 namespace 노출 | `wrangler kv namespace list` | prod·staging × main+preview |
| L2-CLI | Secrets prod 7건 | `wrangler secret list --env production` | 7 names: PERSONALITY_ENCRYPTION_KEY, BETTERAUTH_SECRET, JWT_SECRET, TOSS_SECRET_KEY, TOSS_WEBHOOK_SECRET, CF_ACCESS_AUD (+ optional KEY_OLD) |
| L2-CLI | api `/health` HTTP 200 | `curl -sk https://api.<도메인>/health` | `{"ok":true,"plane":"api","env":"production",...}` |
| L2-CLI | admin `/health` HTTP 200 (CF Access 미설정 시) | `curl -sk https://admin.<도메인>/health` | `{"ok":true,"plane":"admin","env":"production",...}` (Cycle 4 후엔 CF Access challenge) |
| L2-CLI | TLS 활성 | `curl -vI https://api.<도메인>/health 2>&1 \| grep -i "TLSv1.3"` | TLSv1.3 negotiated |
| L2-CLI | D1 cron handler 실측 | CF dashboard → Triggers → Cron → "Run now" | R2_BACKUP에 새 .sql 파일 1개 |
| L2-CLI | R2 sealed 백업 1건 | `wrangler r2 object list personality-secrets --env production` | `PERSONALITY_ENCRYPTION_KEY/v1.age` 노출 |
| L2-CLI | GitHub Actions PR preview | (테스트 PR open) | PR에 preview URL 코멘트 + `<url>/health` 200 |
| L2-CLI | GitHub Actions production deploy | main에 변경 push | workflow run "success" + 실제 production endpoint 갱신 |
| L4-Trace | Brief Ideal Criteria #1 | 본 plan + Verify | CF Workers + Hono + D1 + R2 + KV + Wrangler deploy 작동 |
| L4-Trace | Brief Ideal Criteria #2 | 본 plan + Verify | Custom Domain + 자동 TLS 외부 접근 가능 |
| L4-Trace | Brief Ideal Criteria #11 | 본 plan + Verify | GitHub Actions + Wrangler로 prod/preview/staging 자동 배포 |
| L4-Trace | Brief Ideal Criteria #20 | 본 plan + Verify | 7개+ secrets Wrangler/GitHub로 분리 관리, 평문 커밋 0 |
| L4-Trace | Synthesis § 5 Cycle 1 input | 본 plan + Verify | R4 secrets 운영 모델 (Wrangler + R2 sealed + 1Password) 적용 + parallel-key rotation 절차 문서화 |

> L3-Browser는 Cycle 1 범위 밖 (admin UI는 Cycle 6).

---

## Risks (Cycle 1 자체 + 후속 Cycle 영향)

### Cycle 1 자체

- **사용자 작업 의존도가 높음(U1~U8 8개 지점)** → 사용자가 단계별로 작업해야 진행. Claude는 명령어 정확히 제시하고 결과 값(account ID, 도메인)을 받는다.
- **`wrangler login` 인터랙티브** → Claude 직접 실행 불가. 사용자 1회 로그인 후 토큰 로컬 저장.
- **secrets 평문 history 잔존** → `HISTCONTROL` 안내. 또는 stdin 파일 redirect.

### 후속 Cycle 영향

- **binding 이름 변경 시 cascade**: `DB`, `KV`, `R2_BACKUP`, `R2_SECRETS`, `R2_UPLOADS` — Cycle 2~7 코드 전반에서 `c.env.DB` 등으로 참조. 본 Cycle 명명을 신중히 (이미 보편).
- **단일 Worker 토폴로지(Decision 1)** → admin/api 분리 필요 시 Worker 2개로 분할(routes 분리). 본 Cycle 결정이 후속에 영향 — 분리는 Cycle 6 또는 운영 단계에서 재검토.
- **D1 backup이 SQL dump 방식**: row 수가 수만 단위 도달 시 Workers 30s CPU 한도에 근접 → Cycle 10에서 D1 export REST API 또는 chunked 전략으로 교체.
- **Cookie 격리 정책(Decision 2)** → Cycle 4 BetterAuth/CF Access 코드가 본 정책 인용. 정책 변경 시 Cycle 4 코드 재작업.
- **secrets rotation 절차 문서화만** → 실제 rotation drill은 운영 단계 또는 Cycle 9(cutover safety)에서 1회 수행.

---

## Acceptance Criteria

본 Cycle은 **Brief Ideal Criteria #1, #2, #11, #20** 4건을 충족하면 완료. 매핑:

| Brief Criterion | 본 Cycle 산출 | 검증 방법 |
|-----------------|--------------|----------|
| **#1** CF Workers + Hono + D1 + R2 + KV 인프라 deploy 작동 | Step 2~4 + Step 7 production deploy | L2-CLI `wrangler d1 list`, `wrangler r2 bucket list`, `wrangler kv namespace list`, `curl /health` 200 |
| **#2** Custom Domain + 자동 TLS 외부 접근 가능 | Step 5 | L2-CLI `curl -vI https://api.<도메인>/health` TLSv1.3 |
| **#11** GitHub Actions + Wrangler prod/preview/staging 자동 배포 | Step 7 | L2-CLI 테스트 PR + main push로 3 workflow run 성공 |
| **#20** 7개+ secrets Wrangler/GitHub 분리 관리, 평문 커밋 0 | Step 6 | L2-CLI `wrangler secret list` 7건 + `git log -p \| grep -E "(PERSONALITY_ENCRYPTION|BETTERAUTH_SECRET|TOSS_)"` 0건 |

추가 (Synthesis 입력 적용 검증):
- **Synthesis Conflict 2**: cookie 격리 정책 runbook 명시 (`docs/runbook/cf-account-setup.md` "Cookie 격리 정책" 섹션 존재)
- **Synthesis § 5 Cycle 1 input**: R4 secrets 운영 모델 — 3중 백업(Wrangler + R2 sealed + 1Password) + parallel-key rotation runbook (`docs/runbook/secret-rotation.md` 존재)
- **Brief Constraint M14**: D1 backup cron 동작 + restore runbook (`docs/runbook/d1-backup-restore.md` 존재)

---

## Dependencies

**Prerequisite cycles**: 없음 — 본 Cycle은 첫 impl 사이클이며 모든 후속 Cycle이 본 Cycle 산출에 의존.

**Outputs (Cycle 2 입력)**:
- D1 binding 이름: `DB`
- R2 bindings: `R2_BACKUP`, `R2_SECRETS`, `R2_UPLOADS`
- KV binding: `KV`
- production D1 ID, staging D1 ID, KV namespace ID(전부) — wrangler.toml에 기재되어 있고 Cycle 2의 drizzle-kit migration 적용 시 `--remote --env production` flag로 사용
- env keys: `ENV`(`production` | `staging` | `preview` | `development`)
- secrets 등록 완료: `PERSONALITY_ENCRYPTION_KEY`, `BETTERAUTH_SECRET`, `JWT_SECRET`, `TOSS_SECRET_KEY`, `TOSS_WEBHOOK_SECRET`, `CF_ACCESS_AUD`
- cookie 격리 정책 (Synthesis Conflict 2 적용)

---

## Time Estimate

| Step | 작업 종류 | MAN-DAY (1인 운영) |
|------|----------|-------------------|
| 1 | CF account / domain (사용자 작업) | 0.5 (도메인 nameserver 전파 대기 포함) |
| 2 | Workers project init + Hono `/health` | 0.3 |
| 3 | D1·R2·KV 리소스 생성 | 0.2 |
| 4 | wrangler.toml 작성 | 0.3 |
| 5 | Custom Domain + cookie 정책 runbook | 0.3 |
| 6 | 7개 secret + R2 sealed + 1Password + rotation runbook | 0.7 |
| 7 | GitHub Actions 3 workflows + secret 등록 + 테스트 PR | 0.7 |
| 8 | D1 backup cron handler + 수동 검증 + restore runbook | 0.5 |
| 9 | repo root 갱신 | 0.1 |
| Verify | L1+L2 assertions 일괄 | 0.4 |
| **합계** | | **~4.0 MAN-DAY** |

> Brief MAN-WEEK 추정 30.5 MW = ~152.5 MAN-DAY 중 본 Cycle은 약 2.6%. 후속 Cycle 2~10이 토대 위에서 빠르게 진행 가능하도록 본 Cycle에 디테일 투자.

---

## References

| Resource | Path/URL | Related Content |
|----------|---------|-----------------|
| Brief | [`001_Brief_cf_workers_rebuild.md`](./001_Brief_cf_workers_rebuild.md) | In Scope 1, 2, 17, 10 / Decisions 11, 12 / Anchor 9, 17 / Constraint M14 |
| Scope | [`007_Scope_cf_workers_rebuild.md`](./007_Scope_cf_workers_rebuild.md) | Cycle 1 영역 정의, file 목록 추정 |
| Synthesis | [`018_Synthesis_research_cycle.md`](./018_Synthesis_research_cycle.md) | § 2 Conflict 2 (cookie 격리), § 5 Cycle 1 input (R4 secrets 운영 모델) |
| R4 Research | [`011_Research_axis4_auth_hybrid.md`](./011_Research_axis4_auth_hybrid.md) | R4-F3 parallel-key rotation 절차 (Step 6 직접 인용) |
| Cloudflare Wrangler | <https://developers.cloudflare.com/workers/wrangler/configuration/> | wrangler.toml 환경별 bindings 패턴 |
| Cloudflare Custom Domains | <https://developers.cloudflare.com/workers/configuration/routing/custom-domains/> | api/admin DNS routes |
| Cloudflare D1 Time Travel | <https://developers.cloudflare.com/d1/reference/time-travel/> | backup 추가 안전망 (R2 외) |
| wrangler-action | <https://github.com/cloudflare/wrangler-action> | GitHub Actions deploy step |
| age encryption | <https://age-encryption.org/> | R2 sealed 백업 도구 |

---

## 미비점 및 확장 필요 영역

### Plan 미비점 (makeplan 기록)

| # | 항목 | 심각도 | 설명 |
|---|------|--------|------|
| 1 | preview workflow의 `<account>` subdomain 자동화 | Medium | wrangler-action v3가 deployment-url을 step output으로 노출하는지 추가 확인 필요 — 현재 plan은 정적 기입 fallback. 첫 PR에서 실측 후 자동화로 교체. |
| 2 | D1 backup의 row count 한도 | Medium | Workers 30s CPU 한도 — production row가 수만 도달 시 chunk 전환. Cycle 10 retro에서 baseline 측정 후 임계 정의. |
| 3 | age private key 분실 시 복구 절차 | High | 1Password에 저장 강제는 명시했으나, 1Password 자체 분실 시 fallback 부재 — 운영 단계에서 Shamir's Secret Sharing 검토 권고 (Cycle 10). |
| 4 | wrangler login 자동화 | Low | OAuth flow는 인터랙티브 — CI에서는 API Token으로 우회(현재 GitHub Actions가 그렇게). 로컬 dev에선 사용자 1회 로그인으로 충분. |
| 5 | preview Worker 누적 cleanup | Medium | PR close 시 자동 삭제 workflow 부재 — 본 Cycle 범위 밖, Cycle 10에서 추가. |
| 6 | wrangler.toml에 `<도메인>` placeholder 잔존 | Critical (impl 시점) | 사용자 U2 결과(root domain)를 받은 직후 일괄 sed 치환 필요 — implementation skill에서 명시 처리. |
| 7 | api/admin 별도 cookie 정책 코드 미적용 | Medium | 본 Cycle은 정책 runbook 명시만. Cycle 4가 BetterAuth/CF Access와 결합하여 실제 코드 적용. |

### Implementation 미비점 (implementation 기록)
<!-- implementation skill이 채움 -->
| # | 항목 | 심각도 | 설명 |
|---|------|--------|------|

### Verification 미비점 (verify 기록)
<!-- verify skill이 채움 -->
| # | 항목 | 심각도 | 설명 |
|---|------|--------|------|

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
