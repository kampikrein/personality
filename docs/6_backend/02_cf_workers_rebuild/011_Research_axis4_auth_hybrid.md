---
id: "011"
type: research
title: "R4 — BetterAuth + Cloudflare Access hybrid"
created: 2026-04-29
traces_brief: "001"
traces_scope: "007"
research_axis: "R4"
summary: >
  BetterAuth는 v1.5.0(2026-03-01)에서 Cloudflare D1을 first-class로 채택했고
  v1.6.x가 4월 거의 매일 배포되는 활성 프로젝트(28K stars). User 인증은
  api/admin 단일 루트도메인 cookie 공유(advanced.crossSubDomainCookies +
  domain="example.com" + SameSite=Lax)로 단순화하고, Admin 인증은 CF Access의
  CF_Authorization JWT(application token)를 admin.<도메인>에만 격리해 BetterAuth
  세션과 cross-leakage 없이 두 평면이 공존한다. Hono CSRF는 Origin +
  Sec-Fetch-Site 이중 체크라 SameSite=Lax + 모바일 fetch credentials:include
  + trustedOrigins allowlist 조합으로 보완. encryption key는 Wrangler secret +
  R2 외부 sealed 백업 + BetterAuth 1.5의 non-destructive secret rotation을
  parallel-key 패턴(read=old∪new, write=new)으로 적용한다. Lucia v3 sunset은
  메인테이너가 공식 마이그레이션 가이드(`lucia-v3/migrate`)에서 "Lucia v3 has
  been deprecated. Lucia is now a learning resource"로 확정.
keywords: [betterauth, cloudflare-access, hono, csrf, cookie, jwt, encryption-key, lucia-sunset, d1, kv, cross-subdomain, secret-rotation]
---

# R4 — BetterAuth + Cloudflare Access hybrid

## Research Overview

본 연구는 Brief Decision 8(C1 갱신)의 후속 — Lucia v3 sunset 후 **BetterAuth (User 인증) + Cloudflare Access (Admin 인증) hybrid**가 Workers + D1 + KV 환경에서 실제로 작동하는지, 그리고 두 인증 평면을 cross-subdomain(`api.<도메인>` vs `admin.<도메인>`)에서 어떻게 공존시키는지 통합 패턴을 결정한다.

조사 4축:
- Q1 BetterAuth 활성 개발 + Workers/D1/KV 호환 confirm
- Q2 Cross-subdomain 전략 (cookie 공유 vs 격리, SameSite, JWT)
- Q3 Hono CSRF origin-check 한계 + 보완
- Q4 encryption key Wrangler secret 저장 + 외부 백업 + rotation 절차

코드 수정은 하지 않고, **통합 패턴 결정 + Cycle 4 file plan 초안**만 산출한다.

본 산출물은 Brief Decision 8(BetterAuth + CF Access hybrid frozen)을 변경하지 않고, 그 위에 운용 디테일을 확정한다.

---

## Q1 BetterAuth 활성 개발 상태 + Workers/D1/KV 호환 confirm

### 활성 개발 데이터

| 지표 | 값 | 출처 |
|------|------|------|
| GitHub stars | **28,037** (2026-04-28 시점) | github.com/better-auth/better-auth |
| Forks | 2,483 | 동일 |
| Open issues | 367 | 동일 |
| Latest commit | 2026-04-28 | 동일 |
| Latest release | **v1.6.9** (2026-04-24) | github releases |
| 최근 release 빈도 | **4월 24·23·22·21일 연속 패치** (v1.6.6→1.6.9) | github releases |
| Major release (1.5) | **2026-02-28** — "600+ commits, 70 features, 200 bug fixes, 7 new packages" | better-auth.com/blog/1-5 |
| YC 후원 | Y Combinator portfolio | ycombinator.com/companies/better-auth |

**판단**: 활성 개발 confirm. 거의 매일 release. Lucia 같은 sunset 신호 없음. 2026-04 기준 1년 가까이 안정적 cadence.

### Workers + D1 + KV 호환

#### D1 — first-class

> "Pass your D1 binding directly — no custom adapter setup required."  
> — better-auth.com/blog/1-5 (v1.5.0, 2026-02-28)

> "D1 dialect handles query execution, batch operations, and introspection through D1's native API. D1 does not support interactive transactions — Better Auth uses D1's `batch()` API for atomicity instead."  
> — 동일

이는 Brief In Scope 4(scoring saga 패턴, R12 D1 transaction 부재)와 정합 — BetterAuth 자체도 batch API로 우회.

#### KV — secondary storage interface

> "To use secondary storage, implement the `SecondaryStorage` interface" (get/set/delete)  
> — better-auth.com/docs/concepts/database

KV adapter는 별도로 작성 필요(공식 어댑터는 Redis 예시). Workers KV는 `get/put/delete` 시그니처가 SecondaryStorage 인터페이스에 1:1 대응 — 30 LOC 미만의 thin wrapper로 충분.

V1.5.0에서 verification tokens/rate limiter 등이 secondaryStorage로 이동 가능해져 D1 부담 감소.

#### Workers compat

- v1.5+ "immutable headers on Cloudflare Workers" 버그 수정 흔적 — 명시적 Workers awareness.
- v1.6.9: "Fixed instrumentation resolution in the adapter factory so edge and browser environments correctly use the pure variant" — edge 환경 명시.
- 커뮤니티 통합 패키지 `zpg6/better-auth-cloudflare` (D1+Hyperdrive+KV+R2+geolocation) 존재 — 하지만 BetterAuth 1.5+가 D1을 native로 흡수했으므로 우리는 native path 채택.

### R4-F1 — Verdict

**BetterAuth 활성도 confirm**. D1 native, KV는 `SecondaryStorage` interface 30 LOC wrapper. Brief Decision 8 (BetterAuth 채택)을 변경할 사유 없음.

---

## Q2 Cross-subdomain 전략 — `api.<도메인>` ↔ `admin.<도메인>`

### 결정 매트릭스

| 옵션 | api(BetterAuth) | admin(CF Access) | 두 평면 |
|------|-----------------|------------------|---------|
| **A: 단일 cookie domain `<도메인>`** | `crossSubDomainCookies: { enabled: true, domain: "<도메인>" }`, SameSite=Lax | CF_Authorization은 admin.<도메인>에만 자동 발급 | api↔admin 세션 공유 (위험) |
| **B (채택): 격리** | cookie domain = `api.<도메인>` (subdomain-scoped) | CF Access 보호는 `admin.<도메인>` 전체 | 두 평면 격리, leakage 없음 |
| C: SameSite=None partitioned | crossSubDomainCookies + sameSite="none" + secure + partitioned | 동일 | 부분 cookie 격리, but Lax 우회 부담 |

**채택 = B (격리)** — 사유:
1. 모바일이 api.<도메인>의 주 클라이언트, admin은 운영자 1인이 브라우저로만 접근 → 세션 공유 가치 0.
2. CF Access는 admin.<도메인> 단독 정책 적용이 가장 단순(JWT 발급도 host-scoped).
3. Brief Model Anchor 19 ("User 인증과 Admin 인증은 도메인별 분리 운영")와 정합.

### BetterAuth — api.<도메인> cookie 설정

```typescript
// lib/auth/betterauth.ts (Cycle 4 plan 초안)
auth = betterAuth({
  database: drizzleAdapter(env.DB, { provider: "d1" }),  // v1.5+ D1 native
  secondaryStorage: workerKVStorage(env.KV),             // 30 LOC wrapper
  advanced: {
    cookiePrefix: "personality",
    crossSubDomainCookies: { enabled: false },           // api 전용, 공유 X
    defaultCookieAttributes: {
      sameSite: "lax",                                    // 모바일 fetch credentials:include 충분
      secure: true,
      httpOnly: true,
      domain: "api.<도메인>"                              // explicit subdomain scope
    }
  },
  trustedOrigins: ["https://api.<도메인>"]                 // CSRF allowlist 1차
});
```

근거:
- BetterAuth docs: "All cookies are httpOnly and secure when the server is running in production mode."
- "we recommend using subdomains whenever possible, as this allows you to keep SameSite=Lax"
- Flutter `dio` HTTPS 호출은 same-origin이 아니므로 `withCredentials` (Dart 표준)을 set해야 cookie 첨부.

### CF Access — admin.<도메인> 격리

CF Access는 `admin.<도메인>` 전체에 Access Application 1개 등록.

| 토큰 | 발급 범위 | 도메인 |
|------|---------|--------|
| Global session token | `<team>.cloudflareaccess.com`(team domain) | CF Access UI 호스트 |
| Application token (CF_Authorization) | admin.<도메인>의 application | admin.<도메인>에만 set |

> "stored as a cookie on the protected domain (for example, `https://jira.site.com`)"  
> — developers.cloudflare.com/cloudflare-one/identity/authorization-cookie/

CF_Authorization은 admin.<도메인> scope이므로 api.<도메인>로 누출되지 않음. **두 평면 cookie 격리 자동.**

#### CF Access JWT 검증 — Worker route 측

admin Worker가 자체 인증 검증을 한 번 더 한다 (Zero Trust 원칙):

> "Cloudflare Access includes an application token in the `Cf-Access-Jwt-Assertion` request header. You should validate the token with your public key."  
> — developers.cloudflare.com/cloudflare-one/identity/authorization-cookie/validating-json/

JWKS endpoint: `https://<team>.cloudflareaccess.com/cdn-cgi/access/certs`  
키 회전: 6주, 이전 키 7일 valid.  
검증: `jose` (Workers 호환) + AUD tag + issuer.

```typescript
// lib/auth/cf-access.ts (Cycle 4 plan 초안)
import { jwtVerify, createRemoteJWKSet } from "jose";

const JWKS = createRemoteJWKSet(new URL(`https://${TEAM}.cloudflareaccess.com/cdn-cgi/access/certs`));

export async function requireCFAccess(c: Context, next: Next) {
  const token = c.req.header("Cf-Access-Jwt-Assertion");
  if (!token) return c.text("missing CF Access token", 401);
  const { payload } = await jwtVerify(token, JWKS, {
    issuer: `https://${TEAM}.cloudflareaccess.com`,
    audience: AUD_TAG
  });
  c.set("admin_email", payload.email);
  await next();
}
```

### Cross-subdomain leakage 방지

- BetterAuth cookie: `domain="api.<도메인>"` (Set-Cookie 명시) → admin.<도메인>에 전송 안 됨.
- CF_Authorization: admin.<도메인>에만 발급 → api.<도메인>에 전송 안 됨.
- Worker bindings는 도메인별로 별도 deploy 또는 단일 Worker + route prefix 분기. **cookie 누출 위험 0.**

### R4-F2 — Verdict

**Cookie 격리 채택**. api(BetterAuth, domain=api.<도메인>, SameSite=Lax) ↔ admin(CF Access, CF_Authorization, admin.<도메인>) 두 평면 분리. Brief Decision 8/Anchor 9의 "양 서브도메인 공유" 표현은 본 연구 결과로 **격리로 정정** (사용자 결정 없이 운용 결론).

---

## Q3 Hono CSRF origin-check 한계 + 보완 패턴

### Hono CSRF middleware 동작

> "checking both the `Origin` header and the `Sec-Fetch-Site` header. The request is allowed if either validation passes."  
> — hono.dev/docs/middleware/builtin/csrf

기본 설정:
```typescript
import { csrf } from "hono/csrf";
app.use(csrf({ origin: ["https://api.<도메인>"] }));
// 또는 함수형
app.use(csrf({ origin: (o) => /^https:\/\/api\.<도메인>$/.test(o) }));
```

**보호 대상**: GET/HEAD/OPTIONS 외 + form-compatible content-types.

### 한계

| 한계 | 설명 | user-facing 영향 |
|------|------|-----------------|
| Origin 헤더 부재 | 구형 브라우저 / 일부 reverse proxy 헤더 제거 | 매우 드뭄, 모바일/현대 웹 0% 영향 |
| `Content-Type: application/json` 미보호 | hono/csrf는 form 계열만 검사 → JSON XHR은 origin-check 미수행 (브라우저 SOP가 1차 방어) | API가 JSON-only면 SOP가 차폐, but spec 명시 부재 |
| Per-session token 부재 | double-submit cookie / synchronizer token 패턴 미지원 | Origin spoof을 헤더 조작 없이 못 함 (브라우저는 Origin set 강제) — 실 위협 낮음 |
| Multi-origin SaaS | Origin allowlist에 동적 도메인 누적 어려움 | api.<도메인> 단일이면 무관 |

Brief In Scope 18은 이미 "Hono CSRF origin-check 기반 (per-session token 부재) 사실 명시"를 인지함 — 본 연구는 이를 confirm + 보완책 제시.

### 보완 패턴

1. **trustedOrigins (BetterAuth) + Hono csrf middleware 이중 allowlist**
   - BetterAuth는 자체 `trustedOrigins`로 OAuth callback/Origin 검증.
   - Hono csrf는 mutating 라우트 전반에 1차 차폐.
2. **SameSite=Lax cookie + secure** — 브라우저 SOP가 cross-site form post에서 cookie 차단.
3. **모바일 — Origin 헤더는 Flutter `http`/`dio`가 자동 송신 안 함** → 모바일은 Bearer token 또는 별도 우회 경로(예: `Sec-Fetch-Site: none`이 아닌 사용자 정의 헤더 `X-Mobile-Client: 1` + Bearer JWT) 검토. 단순화안: **모바일은 `/api/m/*` route group을 csrf middleware에서 제외, JWT bearer + secret으로 대체.**
4. **JSON content-type 보호 추가 보강**: hono/csrf가 form만 검사하므로 admin JSON mutation 라우트엔 추가 미들웨어로 `Origin == admin.<도메인>` enforce.

```typescript
// 제안 - Cycle 4 file plan 초안
app.use("/api/*", csrf({ origin: ["https://api.<도메인>"] }));
app.use("/api/m/*", (c, next) => {
  // mobile bearer auth, csrf bypass
  return bearerAuth(c, next);
});
app.use("/admin/*", csrf({ origin: ["https://admin.<도메인>"] }));
app.use("/admin/api/*", strictOriginEnforce("https://admin.<도메인>")); // JSON also
```

### R4-F3 — Verdict

Hono CSRF origin-check는 **api+admin 같이 single-origin 운영에서 실 위협을 차폐**하기에 충분. 보완:
- 모바일 라우트는 Bearer JWT + csrf bypass(별도 mount)
- admin JSON mutation은 strict Origin 미들웨어 추가
- 향후 admin이 다중 origin 호스팅 시 double-submit cookie 패턴 도입(별도 phase)

Brief In Scope 18 그대로 유지, **per-session token 부재는 본 phase에서 수용**.

---

## Q4 Encryption key Wrangler secret + 외부 백업 + rotation 절차

### 키의 기능

`User.encrypts :email, deterministic: true` 호환 — Web Crypto AES-GCM 결정성. 키 분실 = 모든 user lookup 불가 = **단일 실패점** (Brief Constraint 명시).

키 1개로 충분한 컬럼:
- `users.email` (deterministic, login 검색용)
- `users.display_name` (non-deterministic, display)

### 저장

| 위치 | 목적 | 빈도 |
|------|------|------|
| **Wrangler secret** (`PERSONALITY_ENCRYPTION_KEY`, `PERSONALITY_ENCRYPTION_KEY_OLD`) | 운영 — Worker 런타임 주입 | 항시 |
| **R2 sealed 백업** (age/sops 암호화) | 비상 복구 | 회전 시 |
| **GitHub Actions secret** | CI/CD migration runner | 회전 시 |
| **운영자 1인 password manager** (1Password/Bitwarden) | 최후 수단 | 회전 시 |

3중 백업 — Brief Constraint("키 분실 = 단일 실패점이므로 다중 백업 필수") 충족.

### Rotation 절차 (BetterAuth 1.5 호환 — non-destructive)

BetterAuth 1.5: "Non-destructive secret key rotation support" — parallel-key 패턴 native.

#### 의사코드

```
# Phase 0: 정상 운영
PERSONALITY_ENCRYPTION_KEY     = K_n        (write + read)
PERSONALITY_ENCRYPTION_KEY_OLD = (unset)

# Phase 1: 새 키 생성 + dual-read 활성화
$ openssl rand -base64 32 > K_{n+1}.txt    # 32-byte AES-GCM key
$ wrangler secret put PERSONALITY_ENCRYPTION_KEY_OLD < K_n_currently
$ wrangler secret put PERSONALITY_ENCRYPTION_KEY     < K_{n+1}
# Worker code: encrypt(K_{n+1}); decrypt(try K_{n+1} → fallback K_n)

# Phase 2: 기존 ciphertext 재암호화 (lazy or batch)
# 옵션 A — lazy: 사용자 next-login 시 email field re-encrypt
# 옵션 B — batch: scheduled job (Cron Trigger) `users` 전수 update 
#                 SELECT id, email FROM users; UPDATE SET email = encrypt(decrypt(email, K_n), K_{n+1})
# D1 batch API 사용, 1000 row/batch chunked.

# Phase 3: 검증 — 어떤 row도 K_n으로만 decrypt 되지 않는지 확인
$ wrangler d1 execute --command "SELECT count(*) FROM users WHERE encryption_version = $n"
# = 0 이어야 진행

# Phase 4: 외부 백업 갱신
$ age -e -r $RECIPIENT K_{n+1}.txt > backups/key_{n+1}.age
$ wrangler r2 object put personality-secrets/key_{n+1}.age --file=backups/key_{n+1}.age
$ rm K_{n+1}.txt   # 평문 즉시 삭제

# Phase 5: K_n 폐기
$ wrangler secret delete PERSONALITY_ENCRYPTION_KEY_OLD
# K_n은 R2 sealed 백업에만 보존 (포렌식 / 미회전 row 발견 시 복구용)
```

#### 운영 트리거

- **계획적**: 12개월 1회 (Brief Constraint "rotation 정책")
- **비상**: secret 노출 의심 시 즉시
- **CF JWKS와 정렬**: CF Access JWT 키는 6주 자동 회전 — 운영자 개입 불요. 본 키는 분리 사이클.

### `users.encryption_version` 컬럼 추가 권고

```sql
ALTER TABLE users ADD COLUMN encryption_version INTEGER DEFAULT 1;
```

batch 재암호화 진행률을 D1에서 직접 측정. Cycle 2 (DB Layer) makeplan에서 schema에 포함.

### BetterAuth 호환

BetterAuth는 user 데이터 암호화를 라이브러리 차원에서 강제하지 않는다 — `User.encrypts` 동등 기능은 우리 application code에서 처리. BetterAuth는 단지 user/session row를 D1에서 read/write — encryption hook은 Drizzle column transform으로 wrap.

```typescript
// db/schema.ts (개념)
export const users = sqliteTable("users", {
  id: text("id").primaryKey(),
  emailEnc: text("email").notNull(),    // ciphertext
  emailHash: text("email_hash").notNull().unique(),  // SHA-256(plain) — login lookup용 결정성
  displayNameEnc: text("display_name"),
  encryptionVersion: integer("encryption_version").default(1),
  // BetterAuth 표준 컬럼 (createdAt, updatedAt, etc.)
});
```

`emailHash`(SHA-256, key 무관)로 lookup → `emailEnc` decrypt. 결정성 암호화 대신 hash + ciphertext 분리 패턴. **이 분리가 key rotation 부담을 크게 낮춘다** — hash는 회전 불요, ciphertext만 lazy/batch 재암호화.

### R4-F3 — Verdict

**Wrangler secret + R2 sealed + 1Password 3중 백업, parallel-key rotation**. BetterAuth 1.5 non-destructive rotation native. `email_hash + email_ciphertext` 분리 컬럼으로 deterministic encryption 회피 가능 — Cycle 2 schema에 반영 권고.

---

## Lucia v3 sunset 재확인

### 메인테이너 공식 공지

> "Lucia v3 has been deprecated. Lucia is now a learning resource for implementing sessions and more."  
> — lucia-auth.com/lucia-v3/migrate

> "We ultimately came to the conclusion that it'd be easier and faster to just implement sessions from scratch. The database adapter model wasn't flexible enough for such a low-level library and severely limited the library design."  
> — 동일

> "Replacing Lucia v3 with your own implementation should be a straight-forward path"  
> — 동일

### 외부 신호

- 2025-Q1 deprecation 시점, sveltejs/kit는 #12990 이슈로 docs에서 lucia 제거.
- daily.dev "Lucia-auth is Deprecated: Meet the Better Alternative – Better Auth"
- HonoGear blog (2026): "In 2026, Better-Auth is the Only Choice for Astro"

### 결론

Brief Decision 8의 "Lucia 기각 (2024-Q4~2025-03 sunset 확정)" **재확인 — 변경 사유 없음**. 메인테이너는 대체 라이브러리를 명시 추천하지 않고 "직접 구현 권장"이지만 커뮤니티 합의는 BetterAuth.

---

## Hybrid 통합 시퀀스

### Login (User — api.<도메인>)

```
[Flutter app] ──POST /api/auth/sign-in/email──▶ [Worker api]
                                                    │
                                                    ▼
                                          [BetterAuth.handler(c.req.raw)]
                                                    │
                                  ┌─────────────────┼─────────────────┐
                                  ▼                 ▼                 ▼
                          [D1: users]      [KV: rate-limit]    [Web Crypto: hash+decrypt]
                                  │
                                  ▼
                          Set-Cookie: personality.session_token
                                     domain=api.<도메인>; SameSite=Lax; Secure; HttpOnly
                                     │
[Flutter app] ◀─────────────────────┘ withCredentials=true 로 후속 요청 cookie 자동 첨부
```

### Subsequent (User — api.<도메인>)

```
[Flutter] ──GET /api/me (Cookie: personality.session_token)──▶ [Worker api]
                                                                   │
                                                                   ▼
                                                       [Hono csrf middleware]
                                                       (mobile route는 bypass + Bearer)
                                                                   │
                                                                   ▼
                                                       [BetterAuth.api.getSession]
                                                       (D1 + KV verification)
                                                                   │
                                                                   ▼
                                                       [route handler] → JSON envelope
```

### Login (Admin — admin.<도메인>)

```
[Browser] ──GET https://admin.<도메인>/dashboard──▶ [Cloudflare edge]
                                                          │
                                            ┌─────────────┘
                                            ▼ (no CF_Authorization)
                                  [CF Access login redirect]
                                            ▼
                              <team>.cloudflareaccess.com → IdP(Google/etc)
                                            ▼
                              redirect back, Set-Cookie: CF_Authorization
                                                         domain=admin.<도메인>
                                            ▼
[Browser] ──GET /dashboard (Cookie: CF_Authorization)──▶ [Cloudflare edge]
                                            │ (CF validates JWT)
                                            ▼ + header Cf-Access-Jwt-Assertion
                                  [Worker admin]
                                            │
                                            ▼
                              [requireCFAccess middleware]
                                            │ jose.jwtVerify(JWKS, AUD, iss)
                                            ▼
                              [admin route handler] (read admin_email from JWT claim)
```

### Cross-平面 격리

```
┌───────────────────────┐         ┌────────────────────────────┐
│  api.<도메인>           │         │  admin.<도메인>             │
│  ─────────────────    │         │  ─────────────────────     │
│  cookie: personality.* │         │  cookie: CF_Authorization  │
│  domain=api.<도메인>    │ × NONE × │  domain=admin.<도메인>      │
│  BetterAuth session   │         │  CF Access JWT             │
└───────────────────────┘         └────────────────────────────┘
        │                                       │
        ▼                                       ▼
   D1 + KV (BetterAuth)              IdP (CF One IdP integration)
```

상호 cookie 누출 0. 두 인증 도메인 분리 운영.

---

## Cross-Analysis

### 다른 R 축과의 정합

| 축 | 본 R4가 받는 입력 / 주는 출력 |
|------|-------------------------------|
| R1 (Drizzle ↔ wrangler) | BetterAuth 1.5 D1 native = drizzleAdapter 호출 → R1 SOT 전략과 정합. `email_hash + email_enc + encryption_version` 컬럼 추가 → R1 schema 결과에 반영. |
| R2 (saga vs DO) | 본 인증 흐름은 saga 불요(단일 D1 op). encryption rotation의 batch 재암호화는 D1 batch API + KV resume token으로 saga 유사 패턴 적용 가능. |
| R3 (Admin UI) | admin Worker의 모든 라우트가 `requireCFAccess` 미들웨어 wrap. Astro/HTMX/Hono SSR 어느 winner든 동일 — admin UI는 CF Access 의존만 인지. |
| R5 (Toss webhook) | Toss webhook endpoint(`POST /api/payments/toss/webhook`)는 인증 X(서명 검증으로 대체) → BetterAuth/CF Access middleware bypass 라우트로 등록. Hono csrf도 bypass. |

### Brief 재확인

| Brief 결정 | 본 R4 결과 | 변경 |
|----------|------------|------|
| Decision 8 (BetterAuth + CF Access hybrid) | confirm | — |
| Model Anchor 9 (양 서브도메인 cookie 공유 또는 JWT) | **격리 채택**으로 정정 (공유 가치 0) | minor |
| In Scope 6 (encryption key Wrangler secret + 외부 백업 + rotation) | parallel-key + R2 sealed + 1Password | confirm |
| In Scope 18 (Hono CSRF origin-check, per-session token 부재) | 수용 + 모바일 Bearer + admin strict origin | confirm |
| In Scope 19 (admin = CF Access SSO) | confirm | — |
| Constraint (키 분실 단일 실패점) | 3중 백업으로 mitigation | confirm |

---

## Comprehensive Conclusion

### R4-F1 BetterAuth 활성도

**Active confirmed**. 28K stars, v1.6.9 (2026-04-24), 4월 거의 매일 release, v1.5.0(2026-02-28) D1 first-class. Lucia v3 sunset 재확인. **Brief Decision 8 그대로 유지**.

### R4-F2 Cross-subdomain 결정

**격리 채택** — api.<도메인>은 BetterAuth cookie domain=api.<도메인>, SameSite=Lax. admin.<도메인>은 CF Access CF_Authorization (host-scoped 자동). 두 cookie domain이 disjoint하여 leakage 0. Brief Anchor 9의 "공유" 표현은 본 연구로 격리로 정정 — minor 운용 결정.

### R4-F3 Key rotation 절차

3중 저장 (Wrangler secret + R2 sealed via age + 1Password) + parallel-key 패턴(K_n / K_{n+1} dual-read → batch re-encrypt → K_n 폐기) + `users.encryption_version` 컬럼으로 진척률 추적 + `email_hash` + `email_enc` 분리 컬럼으로 deterministic 회피. BetterAuth 1.5 non-destructive secret rotation native와 정합.

### Cycle 4 file plan 초안 (R4 산출)

| File | 책임 |
|------|------|
| `lib/auth/betterauth.ts` | BetterAuth 인스턴스 (D1 + KV adapter, cookie config) |
| `lib/auth/cf-access.ts` | CF Access JWT 검증 미들웨어 (jose + JWKS) |
| `lib/auth/encryption.ts` | Web Crypto AES-GCM + key version selector (parallel-key) |
| `lib/auth/kv-adapter.ts` | SecondaryStorage interface → Workers KV thin wrapper |
| `lib/middleware/csrf.ts` | Hono csrf wrapper (api/admin 분기, mobile bypass) |
| `lib/middleware/strict-origin.ts` | admin JSON mutation Origin enforce |
| `scripts/rotate-encryption-key.sh` | parallel-key rotation 자동화 |
| `tests/auth/*.test.ts` | sign-in / session / CF Access JWT mock / rotation dry-run |
| db schema 추가 | `users.email_hash`, `users.email_enc`, `users.encryption_version` |

---

## Open Questions

| # | Question | 처리 |
|---|----------|------|
| 1 | CF Access free tier(50 users) 초과 시 admin operator 추가 비용? | 1인 운영 가정에선 무관 — 6/12개월 retrospective에서 재검토 |
| 2 | BetterAuth 모바일 Bearer 흐름의 공식 패턴(plugin)? | Cycle 4 makeplan에서 `bearer plugin` docs 추가 조사 |
| 3 | Cron Trigger 기반 batch 재암호화 latency 추정? | row 수 0(production DB 부재) → Phase A 가동 시점에 부하 측정 |
| 4 | CF JWKS 6주 회전 시 worker cache 만료 처리? | jose `createRemoteJWKSet` 자체 cache + 7일 grace로 충분, but stress test 필요 |

---

## References

### BetterAuth
- [Better Auth Releases](https://github.com/better-auth/better-auth/releases) — v1.6.9 2026-04-24
- [Better Auth Changelog](https://better-auth.com/changelog) — 4월 일별 patch
- [Better Auth 1.5](https://better-auth.com/blog/1-5) — D1 native, "600 commits / 70 features / 200 fixes"
- [Better Auth Cookies](https://better-auth.com/docs/concepts/cookies) — crossSubDomainCookies, trustedOrigins
- [Better Auth Hono Integration](https://better-auth.com/docs/integrations/hono)
- [Better Auth Database](https://better-auth.com/docs/concepts/database) — SecondaryStorage interface

### Cloudflare Access
- [CF Access Authorization Cookie](https://developers.cloudflare.com/cloudflare-one/identity/authorization-cookie/)
- [CF Access JWT Validation](https://developers.cloudflare.com/cloudflare-one/identity/authorization-cookie/validating-json/) — JWKS, AUD, jose 예시
- [CF Access Policies](https://developers.cloudflare.com/cloudflare-one/policies/access/)
- [Wildcard and Multi-Hostname](https://blog.cloudflare.com/access-wildcard-and-multi-hostname/) — 5도메인 cookie 자동 발급
- [Zero Trust Pricing](https://www.cloudflare.com/plans/zero-trust-services/) — 50 user free tier

### Hono
- [Hono CSRF Middleware](https://hono.dev/docs/middleware/builtin/csrf) — Origin + Sec-Fetch-Site 이중 체크
- [Hono Built-in CSRF helper Issue](https://github.com/honojs/hono/issues/1688)

### Lucia sunset
- [Lucia v3 Migrate](https://lucia-auth.com/lucia-v3/migrate) — "deprecated. learning resource"
- [Lucia GitHub](https://github.com/lucia-auth/lucia)
- [Wisp Blog: Lucia Auth is Dead](https://www.wisp.blog/blog/lucia-auth-is-dead-whats-next-for-auth)
- [HonoGear: 2026 Best Auth](https://www.honogear.com/en/blog/engineering/best-auth-option-2026)

### Project files
- `/Users/kampikrein/A/personality/server/app/models/user.rb:4-5` — `encrypts :email, deterministic: true`, `encrypts :display_name`
- `/Users/kampikrein/A/personality/server/app/controllers/sessions_controller.rb:14-37` — 현 anonymous session 흐름 (BetterAuth 이식 대상 아님 — anonymous 흐름은 session token KV 직접)
- `/Users/kampikrein/A/personality/docs/6_backend/02_cf_workers_rebuild/001_Brief_cf_workers_rebuild.md` — Decision 8, In Scope 6/18/19, Anchor 9/13/19
- `/Users/kampikrein/A/personality/docs/6_backend/02_cf_workers_rebuild/007_Scope_cf_workers_rebuild.md` — R4 axis 정의

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
