# @personality/workers

Cloudflare Workers 백엔드 — Hono + D1 + R2 + KV.
Phase 1 Foundation (Cycle 1) 한정형 구현.

## 로컬 개발

### 사전 요구사항

```bash
cd apps/workers
npm install          # Phase 2 cutover 전까지 로컬에서만 사용
cp .dev.vars.example .dev.vars
# .dev.vars에 실제 dev 값 입력 (git-ignored)
```

### 실행

```bash
# 로컬 D1/KV/R2 에뮬레이션 포함 (miniflare 기반)
npm run dev
# = wrangler dev
# --local 옵션은 wrangler v3.90+ 기본 로컬 모드

# 또는 영속성 유지 (로컬 D1 데이터 보존)
npx wrangler dev --local --persist
```

### 검증

```bash
curl http://localhost:8787/health
# {"ok":true,"plane":"dev","env":"development","timestamp":"..."}
```

### TypeScript 타입 검사

```bash
npm run type-check
# npm install 후에만 가능 — Phase 2 이전에는 설치 없음
```

## 배포

### 사전 요구사항 (Phase 2 cutover에서 수행)

1. `wrangler login` — CF 계정 인증
2. D1/R2/KV 리소스 생성 후 `wrangler.toml`의 `__FILL_IN_PHASE2__` placeholder 교체
3. `<DOMAIN>` placeholder를 실제 도메인으로 교체
4. GitHub Actions secrets 등록 (`CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`)
5. secrets 등록: `docs/runbook/cf-account-setup.md` 체크리스트 참조

### 배포 명령

```bash
npm run deploy:prod     # production
npm run deploy:staging  # staging
```

## Phase 2 Cutover — placeholder 채울 항목

`wrangler.toml`의 아래 항목을 Phase 2에서 교체:

| Placeholder | 교체 값 | 명령 |
|------------|---------|------|
| `account_id = "__FILL_IN_PHASE2__"` | CF account ID | `wrangler whoami` |
| D1 `database_id = "__FILL_IN_PHASE2__"` (×2) | D1 DB ID | `wrangler d1 create personality-d1-{prod,staging}` |
| KV `id = "__FILL_IN_PHASE2__"` (×2) | KV namespace ID | `wrangler kv namespace create ...` |
| `<DOMAIN>` (×8) | 실제 root domain | 사용자 결정 |

자세한 절차: `docs/runbook/cf-account-setup.md`

## 파일 구조

```
apps/workers/
├── src/
│   ├── index.ts              # Hono app entry + /health route
│   ├── scheduled/
│   │   └── d1-backup.ts      # D1 → R2 weekly backup cron handler
│   └── lib/
│       └── cookie-policy.ts  # Cookie 격리 정책 placeholder (Cycle 4에서 BetterAuth 결합)
├── wrangler.toml             # Workers config (dev/staging/production)
├── package.json
├── tsconfig.json
├── .gitignore
├── .dev.vars.example         # local secrets template (git-tracked)
└── .dev.vars                 # actual local secrets (git-IGNORED)
```

## 관련 문서

- `docs/runbook/cf-account-setup.md` — CF 계정·도메인·DNS 설정 체크리스트
- `docs/runbook/secret-rotation.md` — parallel-key rotation 절차
- `docs/runbook/d1-backup-restore.md` — D1 backup 동작 + 복원 dry-run
