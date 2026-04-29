# CF Account Setup Runbook

Phase 2 cutover 전에 사용자가 직접 수행하는 Cloudflare 계정·도메인·DNS·리소스 생성 체크리스트.

> Claude Code는 아래 항목을 직접 실행하지 않는다 (외부 자원 미접촉 원칙).
> 각 항목 완료 후 결과 값(account ID, 도메인, D1/KV ID)을 메모하여 Phase 2 cutover 시 wrangler.toml에 기입.

---

## 1. CF 계정

- [ ] [dash.cloudflare.com](https://dash.cloudflare.com) 가입 (이미 있으면 skip)
- [ ] Workers Paid plan 활성화 ($5/month — D1 사용 전제)
- [ ] Account ID 확인: Dashboard → 우측 사이드바 → Account ID

```
account_id: ________________________________
```

## 2. 도메인 설정

- [ ] 서비스 root domain 결정 (예: `personality.app`)
- [ ] Cloudflare에 domain zone 등록 또는 nameserver 이전
- [ ] DNS proxied(orange cloud) 활성화 확인

```
root_domain: ________________________________
```

## 3. wrangler 인증

```bash
# 브라우저 OAuth — Claude Code 직접 실행 불가, 사용자가 직접 수행
wrangler login

# 확인
wrangler whoami
```

## 4. D1 DB 생성

```bash
cd apps/workers

wrangler d1 create personality-d1-prod
# 출력: database_id = "..." → 아래 기록

wrangler d1 create personality-d1-staging
# 출력: database_id = "..." → 아래 기록
```

```
prod_d1_database_id:    ________________________________
staging_d1_database_id: ________________________________
```

## 5. R2 bucket 생성

```bash
wrangler r2 bucket create personality-d1-backup
wrangler r2 bucket create personality-d1-backup-staging
wrangler r2 bucket create personality-secrets
wrangler r2 bucket create personality-uploads
wrangler r2 bucket create personality-uploads-staging
# personality-secrets는 prod 1개만 (sealed key 백업은 환경 무관)
```

## 6. KV namespace 생성

```bash
wrangler kv namespace create personality-kv-prod
# 출력: id = "..." → 기록

wrangler kv namespace create personality-kv-prod --preview
# 출력: preview_id = "..." → 기록

wrangler kv namespace create personality-kv-staging
wrangler kv namespace create personality-kv-staging --preview
```

```
prod_kv_id:         ________________________________
prod_kv_preview_id: ________________________________
staging_kv_id:      ________________________________
```

## 7. DNS 레코드 (Custom Domain)

CF Dashboard → DNS → Records:

```
A     api              192.0.2.1   Proxied   (Workers Route가 실제 라우팅)
A     admin            192.0.2.1   Proxied
A     staging-api      192.0.2.1   Proxied
A     staging-admin    192.0.2.1   Proxied
```

> 더 간결한 방법: Dashboard → Workers → Custom Domains에서 직접 추가 → DNS 레코드 자동 생성.

## 8. Secrets 등록

7개 secret 목록 및 생성 방법은 `docs/runbook/secret-rotation.md` § Phase 0 참조.

```bash
cd apps/workers

# production
for KEY in PERSONALITY_ENCRYPTION_KEY BETTERAUTH_SECRET JWT_SECRET TOSS_SECRET_KEY TOSS_WEBHOOK_SECRET CF_ACCESS_AUD; do
  echo "Enter value for $KEY (production):"
  wrangler secret put $KEY --env production
done

# staging
for KEY in PERSONALITY_ENCRYPTION_KEY BETTERAUTH_SECRET JWT_SECRET TOSS_SECRET_KEY TOSS_WEBHOOK_SECRET CF_ACCESS_AUD; do
  echo "Enter value for $KEY (staging):"
  wrangler secret put $KEY --env staging
done

# 확인
wrangler secret list --env production
```

- [ ] 7개 모두 등록 확인
- [ ] 1Password vault entry "personality CF secrets" 생성 (7개 값 + age private key 저장)

## 9. GitHub Actions Secrets 등록

GitHub repo → Settings → Secrets and variables → Actions → New repository secret:

| Secret Name | Value |
|-------------|-------|
| `CLOUDFLARE_API_TOKEN` | CF Dashboard → My Profile → API Tokens → "Edit Cloudflare Workers" template |
| `CLOUDFLARE_ACCOUNT_ID` | 위 1번에서 확인한 Account ID |

- [ ] `CLOUDFLARE_API_TOKEN` 등록
- [ ] `CLOUDFLARE_ACCOUNT_ID` 등록

## 10. wrangler.toml placeholder 교체

`apps/workers/wrangler.toml`에서 아래 placeholder를 실제 값으로 교체:

```bash
# 교체 대상 확인
grep -n "__FILL_IN_PHASE2__\|<DOMAIN>\|<ACCOUNT>" apps/workers/wrangler.toml
```

| Placeholder | 교체 값 |
|------------|---------|
| `account_id = "__FILL_IN_PHASE2__"` | 1번의 account_id |
| D1 `database_id = "__FILL_IN_PHASE2__"` (production) | 4번의 prod_d1_database_id |
| D1 `database_id = "__FILL_IN_PHASE2__"` (staging) | 4번의 staging_d1_database_id |
| KV `id = "__FILL_IN_PHASE2__"` (production) | 6번의 prod_kv_id |
| KV `preview_id = "__FILL_IN_PHASE2__"` (production) | 6번의 prod_kv_preview_id |
| KV `id = "__FILL_IN_PHASE2__"` (staging) | 6번의 staging_kv_id |
| `<DOMAIN>` (×8 in routes) | root_domain (2번) |

## Cookie 격리 정책 (Synthesis § 2 Conflict 2)

Deploy 후 쿠키 동작 확인 기준:

- `api.<DOMAIN>`: BetterAuth session cookie, `Domain=api.<DOMAIN>` (host-scoped), SameSite=Lax, Secure, HttpOnly
- `admin.<DOMAIN>`: CF_Authorization, `Domain=admin.<DOMAIN>` (host-scoped, CF Access 자동 발급)
- 두 평면 cookie 완전 격리 — 누출 0

## 완료 체크

- [ ] `wrangler deploy --env production --dry-run` 에러 없음
- [ ] `wrangler deploy --env staging --dry-run` 에러 없음
- [ ] GitHub Actions workflow PR 트리거 후 preview URL 코멘트 부착 확인
- [ ] `https://api.<DOMAIN>/health` HTTP 200 확인
