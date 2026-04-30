---
id: "042"
type: plan
title: "Cycle 4 Auth + Security Baseline GREEN Plan"
created: 2026-04-30
traces_brief: "021"
traces_scope: "026"
traces_red: "041"
traces_research: ["011"]
traces_synthesis: "018"
traces_cycle3_impl: "039"
cycle: 4
phase_scope: "phase-1-conversion"
status: completed
confidence: high
summary: >
  Cycle 4 Auth+Security GREEN plan. BetterAuth(D1+KV) + CF Access verifier + Web Crypto envelope
  + email_hash hook + parallel-key rotation + middleware 5종(CORS/CSP/HSTS/rate limit/CSRF) 구현.
  0 fail / 458 pass 목표 (370 cycle 1-3 유지 + 88 cycle 4 신규).
keywords: [plan, auth, security, betterauth, cf-access, crypto, middleware, cycle4]
---

## Goal

Cycle 4 GREEN phase 목표: RED 041에서 작성된 88 fail을 모두 통과시켜 **0 fail / 458 pass** 상태 달성.

- cycle 1-3 베이스 370 pass 회귀 없음 유지
- cycle 4 신규 88 fail → pass 전환 (2 skipped 포함 시 460 tests)

### Brief 021 Ideal Criteria 매핑

| Criterion # | 내용 | Cycle 4 구현 항목 |
|-------------|------|------------------|
| #6 | Encryption key Wrangler secret + 외부 백업 + rotation 절차 | parallel-key rotation 함수 구현 (실 키 등록은 Phase 2) |
| #17 | 보안 baseline 5종 (CORS/CSP/HSTS/rate limit/CSRF) | middleware 5종 구현 + Hono app.use 등록 |
| #18 | BetterAuth(D1+KV) User 인증 sign-up/in/out | betterAuth.ts D1+KV adapter 구현 |
| #19 | CF Access JWT verifier 미들웨어 (JWKS DI 패턴) | cfAccessVerifier.ts + jwksResolver.ts 구현 |

## Scope

### Included

| 항목 | 설명 | 근거 |
|------|------|------|
| BetterAuth(D1+KV) integration | `createAuth`, `signUp`, `signIn`, `signOut`, `getSession`, `lookupUserByEmailHash` 구현. D1 drizzle adapter + KV secondary storage thin wrapper | Brief 021 Decision 7, R4 011 § Active v1.6.9 |
| CF Access verifier (JWKS DI) | `createCFAccessVerifier` — jose 기반 JWT 검증, JWKS resolver DI 패턴 M1. test=fake, prod=fetch with cache | Brief 021 Decision 7, M1 보완 |
| Web Crypto envelope | `encryptEnvelope` / `decryptEnvelope` (AES-256-GCM), `deriveIV` (IV=HMAC-SHA256[:12]). `{ hmacKey, aesKey }` 분리 시그니처 | Synthesis 018 충돌 1 정합, R4 011 |
| email_hash hook | `generateEmailHash` (SHA-256 hex), `emailHashBeforeCreateHook` (BetterAuth `before` hook) | Synthesis 018 OQ-2 확정 |
| parallel-key rotation 함수 | `createRotationContext`, `selectKeyForVersion`, `addNewKey`, `reEncryptRow`, `retireKey`. encryption_version 기반 dual-read | R4 011 § R4-F3, Brief 021 #6 |
| middleware 5종 | CORS / CSP / HSTS / rate limit (KV sliding window) / CSRF (Origin + Sec-Fetch-Site 이중) | Brief 021 Criterion #17 |
| BetterAuth 추가 컬럼 확장 | schema.ts에 `name`, `emailVerified`, `image` on users + `account` 테이블 신규 정의 → 0001 migration | RED 041 § Risks BetterAuth schema 충돌 |
| index.ts middleware 등록 | `apps/workers/src/index.ts`에 `app.use(...)` 5종 순서 등록 | Brief 021 Criterion #17 |

### Excluded

| 항목 | 이유 | 담당 Phase |
|------|------|-----------|
| CF Access 실 SSO 연결 | 외부 자원 — 실 CF Team Domain 필요 | Phase 2 |
| 실 encryption key 등록 (`wrangler secret put`) | 외부 자원 — production secret | Phase 2 cutover |
| WAF rule 설정 | CF Dashboard 작업 — 외부 자원 | Phase 2 |
| CF JWKS 6주 rotation 실 검증 | 외부 자원 (CF JWKS endpoint) | Phase 2 |
| KV 60s eventual consistency 검증 | production 환경만 재현 가능 | Phase 2 (Brief 021 Decision 12) |
| BetterAuth admin separate instance | admin subdomain 실 SSO 미연결 | Phase 2 |

## Structural Decisions

| # | 결정 | 선택 | 근거 |
|---|------|------|------|
| SD-1 | BetterAuth adapter | D1 drizzle adapter (`provider: "sqlite"`, `schema: { users }` 오버라이드) + KV secondary storage thin wrapper (~30 LOC) | R4 011 § Active v1.6.9 D1 first-class. D1 batch API로 interactive transaction 부재 보완 |
| SD-2 | BetterAuth version | `1.6.9` pin. `package.json`에 이미 `"better-auth": "^1.6.9"` (RED 041 Step 1) | 4월 연속 patch(v1.6.6→1.6.9), v1.6.9 edge 환경 fix 포함 (RED 041 § Summary) |
| SD-3 | nodejs_compat flag | `wrangler.toml` `compatibility_flags = ["nodejs_compat"]` 이미 존재(Cycle 1) → GREEN phase Step 0에서 활성 검증 | Brief 021 Decision 15 MS3. better-auth가 Node.js crypto 내부 모듈 의존 |
| SD-4 | vitest external 처리 | `vitest.config.ts` `resolve.external: ["better-auth"]` RED phase에서 추가됨. GREEN phase에서 nodejs_compat 완전 활성화 확인 후 external 제거 시도. 실패 시 external 유지 + § Risks 명시 | RED 041 § vitest.config.ts 설명 |
| SD-5 | BetterAuth schema 분리 migration | Cycle 2 `0000_*` migration과 격리. BetterAuth 추가 컬럼(`name`, `emailVerified`, `image` + `account` 테이블)을 `0001_betterauth_columns.sql`로 분리. drizzle-kit generate로 자동 산출 | RED 041 § Risks BetterAuth schema 충돌 |
| SD-6 | JWKS resolver DI 패턴 | `JwksResolver` 인터페이스 주입. test=`fakeJwksResolver` (로컬 JWKS), prod=`fetchJwksResolver` (fetch + 캐시). `cfAccessVerifier.ts`는 resolver 구현에 의존하지 않음 | Brief 021 M1 (Decision 7 JWKS DI 부재 보완) |
| SD-7 | envelope 함수 시그니처 | `encryptEnvelope(plaintext, { hmacKey, aesKey }, version)` — HMAC 키(IV 파생용)와 AES 키(암호화용) 분리. 동일 raw secret에서 HKDF로 두 키 파생 | RED 041 § Implementation Hints envelope 설계 결정 |
| SD-8 | envelope JSON 형식 | `{ iv: hexString, ct: base64String, v: number }` stringify → `email_enc` 컬럼 저장. R1 wire-format 보존 | Synthesis 018 충돌 1 정합 (R1 envelope JSON을 email_enc 컬럼 값으로 저장) |
| SD-9 | parallel-key rotation | `encryption_version` 컬럼 기반 dual-read. K_n 폐기는 모든 row의 version이 K_{n+1}으로 갱신된 후. `reEncryptRow`: decrypt(K_n) → encrypt(K_{n+1}) | R4 011 § R4-F3, Synthesis 018 |
| SD-10 | Cookie 격리 | `api.<DOMAIN>`: BetterAuth host-scoped cookie (sameSite=Strict, domain NOT set). `admin.<DOMAIN>`: CF Access JWT host-scoped. 두 도메인 disjoint. Cycle 1 `cookie-policy.ts`와 결합 | Synthesis 018 BC1 (Anchor 9 minor 정정) |
| SD-11 | middleware 등록 순서 | Hono `app.use(...)` 순서: HSTS → CSP → CORS → rateLimit → CSRF. 보안 헤더 먼저, rate limit 다음, state-mutation 차단(CSRF) 마지막 | 일반 보안 미들웨어 best practice |
| SD-12 | vitest pin | `3.0.5` 유지. Plan 038에서 확정된 pin. 변경 금지 | Plan 038 Step 0 (cycle 3 vitest pin 결정 계승) |

## File Change Summary

### New Files (15개)

| # | 경로 | 주요 export | Step |
|---|------|------------|------|
| 1 | `src/auth/betterAuth.ts` | `createAuth`, `signUp`, `signIn`, `signOut`, `getSession`, `lookupUserByEmailHash` | Step 2 |
| 2 | `src/auth/cfAccessVerifier.ts` | `createCFAccessVerifier`, `extractAdminClaim` | Step 2 |
| 3 | `src/auth/jwksResolver.ts` | `JwksResolver` interface, `fakeJwksResolver`, `createFetchJwksResolver` | Step 2 |
| 4 | `src/auth/emailHashHook.ts` | `generateEmailHash`, `emailHashBeforeCreateHook` | Step 2 |
| 5 | `src/crypto/envelope.ts` | `encryptEnvelope`, `decryptEnvelope`, `deriveIV` | Step 1 |
| 6 | `src/crypto/keyRotation.ts` | `createRotationContext`, `selectKeyForVersion`, `addNewKey`, `reEncryptRow`, `retireKey` | Step 1 |
| 7 | `src/crypto/emailHash.ts` | `sha256Hex` | Step 1 |
| 8 | `src/crypto/hmac.ts` | `createHmacKey`, `signHmac` (Web Crypto SubtleCrypto wrapper) | Step 1 |
| 9 | `src/middleware/cors.ts` | `createCorsMiddleware` | Step 3 |
| 10 | `src/middleware/csp.ts` | `createCspMiddleware` | Step 3 |
| 11 | `src/middleware/hsts.ts` | `createHstsMiddleware` | Step 3 |
| 12 | `src/middleware/rateLimit.ts` | `createRateLimitMiddleware` | Step 3 |
| 13 | `src/middleware/csrf.ts` | `createCsrfMiddleware` | Step 3 |

> `src/auth/index.ts`, `src/crypto/index.ts`, `src/middleware/index.ts` — RED 041에서 stub barrel 이미 생성됨 (Modified에 포함).

### Modified Files

| 경로 | 변경 내용 | Step |
|------|----------|------|
| `src/auth/index.ts` | barrel re-export 완성 (stub → 실 export) | Step 2 |
| `src/crypto/index.ts` | barrel re-export 완성 | Step 1 |
| `src/middleware/index.ts` | barrel re-export 완성 | Step 3 |
| `apps/workers/src/db/schema.ts` | BetterAuth 컬럼 추가: `name`, `emailVerified`, `image` on users + `account` 테이블 신규 정의 | Step 0 |
| `apps/workers/migrations/0001_betterauth_columns.sql` | drizzle-kit generate 산출물. BetterAuth 확장 컬럼 + account 테이블 | Step 0 |
| `apps/workers/vitest.config.ts` | `resolve.external: ["better-auth"]` 제거 시도 (nodejs_compat 완전 활성화 시). 실패 시 유지 | Step 0 |
| `apps/workers/src/index.ts` | middleware 5종 `app.use(...)` 등록 (HSTS→CSP→CORS→rateLimit→CSRF 순) | Step 4 |

### Reviewed Files (Read-only)

| 경로 | 확인 목적 |
|------|----------|
| `apps/workers/wrangler.toml` | `nodejs_compat` flag + `compatibility_date` 활성 확인 |
| `apps/workers/src/db/schema.ts` (cycle 2 기존 부분) | `email_hash`, `email_enc`, `encryption_version`, `users` 테이블 기존 정의 확인 |
| `apps/workers/src/middleware/cookie-policy.ts` (cycle 1) | host-scoped cookie 정책 결합 지점 확인 |

## Step별 절차

### Step 0 — 사전 준비

#### Approach

wrangler.toml nodejs_compat 활성 검증, schema.ts BetterAuth 컬럼 확장, 0001 migration 생성, vitest external 제거 시도를 수행한다. 이 단계가 완료되어야 Step 1-4의 구현이 올바른 schema 기반 위에서 진행된다.

#### Commands

```bash
# nodejs_compat flag 확인 (이미 존재해야 함)
grep "nodejs_compat" apps/workers/wrangler.toml

# better-auth 설치 확인
ls apps/workers/node_modules/better-auth 2>/dev/null || ls node_modules/better-auth

# drizzle-kit generate (schema.ts 수정 후)
cd apps/workers && npx drizzle-kit generate
```

#### 수행 작업

1. `apps/workers/wrangler.toml` 확인: `compatibility_flags = ["nodejs_compat"]` 존재 여부 검증 (Cycle 1에서 추가됨, SD-3).
2. `apps/workers/src/db/schema.ts` 수정: BetterAuth 추가 컬럼 정의 추가.
   - `users` 테이블: `name text`, `emailVerified integer` (boolean 대용), `image text` (nullable) 컬럼 추가
   - `account` 테이블 신규: BetterAuth OAuth account 레코드 (accountId, providerId, userId FK, accessToken, refreshToken, expiresAt 등)
3. `npx drizzle-kit generate` → `migrations/0001_betterauth_columns.sql` 생성. Cycle 2 `0000_*.sql`과 격리 확인.
4. `vitest.config.ts` `resolve.external: ["better-auth"]` 제거 시도. `npx vitest run test/crypto/emailHash.test.ts` 1개로 smoke test. 실패 시 external 재복구 + § Risks R1 명시.
5. `npm install` (monorepo root) — jose 추가 필요 여부 확인 (`jose` 패키지가 better-auth 의존성으로 포함되지 않으면 별도 설치: `npm install jose`).

#### 검증

- `grep "nodejs_compat" apps/workers/wrangler.toml` → 출력 있음
- `ls apps/workers/migrations/0001_*.sql` → 파일 존재
- vitest smoke test 성공 또는 external 유지 결정 명시

#### Impact Analysis

| 항목 | 영향 |
|------|------|
| schema.ts 변경 | 0001 migration 산출 → test/setup.ts가 0000 + 0001 모두 apply |
| vitest external 제거 | GREEN phase 구현에서 better-auth import가 정상 로드됨. 실패 시 Step 1-3에서 dynamic import 분리 필요 |
| 의존성 | Step 1-4 전체의 crypto + auth 구현이 schema 기반 위에서 진행 |

---

### Step 1 — Crypto layer (의존 leaf)

#### Approach

다른 레이어에 의존하지 않는 순수 crypto 구현 먼저. `hmac.ts` → `emailHash.ts` → `envelope.ts` → `keyRotation.ts` 순서 (의존 트리 leaf → root). 모두 Web Crypto SubtleCrypto 기반이므로 Workers 런타임과 완전 호환.

#### 구현 상세

**`src/crypto/hmac.ts`**
- `createHmacKey(rawKey: Uint8Array): Promise<CryptoKey>` — `crypto.subtle.importKey("raw", rawKey, {name: "HMAC", hash: "SHA-256"}, false, ["sign"])`
- `signHmac(key: CryptoKey, data: Uint8Array): Promise<ArrayBuffer>` — `crypto.subtle.sign("HMAC", key, data)`

**`src/crypto/emailHash.ts`**
- `sha256Hex(input: string): Promise<string>` — `crypto.subtle.digest("SHA-256", TextEncoder().encode(input))` → hex string
- email normalize: `input.toLowerCase().trim()`

**`src/crypto/envelope.ts`**
- `deriveIV(hmacKey: CryptoKey, plaintext: string): Promise<Uint8Array>` — `signHmac(hmacKey, encode(plaintext))` → `slice(0, 12)` (96-bit GCM IV)
- `encryptEnvelope(plaintext: string, keys: { hmacKey: CryptoKey, aesKey: CryptoKey }, version: number): Promise<EnvelopeJSON>`
  - IV = `deriveIV(hmacKey, plaintext)`
  - ciphertext = `crypto.subtle.encrypt({name:"AES-GCM", iv}, aesKey, encode(plaintext))`
  - return `{ iv: hexStr(iv), ct: base64(ct), v: version }`
- `decryptEnvelope(envelope: EnvelopeJSON, keys: { hmacKey: CryptoKey, aesKey: CryptoKey }): Promise<string>`
  - iv = `fromHex(envelope.iv)`
  - pt = `crypto.subtle.decrypt({name:"AES-GCM", iv}, aesKey, fromBase64(envelope.ct))`
  - return `decode(pt)`
- `EnvelopeJSON` type: `{ iv: string; ct: string; v: number }`

**`src/crypto/keyRotation.ts`**
- `RotationKey`: `{ version: number; key: CryptoKey }`
- `RotationContext`: `{ keys: RotationKey[]; currentVersion: number }`
- `createRotationContext(keys: RotationKey[]): RotationContext` — `currentVersion = max(version)`
- `selectKeyForVersion(ctx, version): CryptoKey` — find or throw `Key version ${version} not found`
- `addNewKey(ctx, newKey): RotationContext` — immutable, `currentVersion = newKey.version`
- `reEncryptRow(emailEnc: string, oldKeys, newKeys): Promise<string>` — parse JSON → decrypt → encrypt → stringify
- `retireKey(ctx, version): RotationContext` — filter out. throw if version === currentVersion

#### Commands

```bash
cd apps/workers
npx vitest run test/crypto/
```

#### 검증

- `test/crypto/emailHash.test.ts` 7 pass
- `test/crypto/envelope.test.ts` 13 pass
- `test/crypto/keyRotation.test.ts` 9 pass + 2 skipped (keyRotation beforeAll crypto key 생성 skip은 이제 실 구현으로 0 skipped 기대, 실패 시 확인)
- 소계: ~29 pass

#### Impact Analysis

| 항목 | 영향 |
|------|------|
| 파일 | `src/crypto/hmac.ts`, `emailHash.ts`, `envelope.ts`, `keyRotation.ts`, `index.ts` 수정 |
| 의존성 | auth layer(Step 2)의 emailHashHook + envelope이 crypto layer에 의존 |

---

### Step 2 — Auth layer

#### Approach

crypto layer 완료 후 진행. JWKS DI 패턴(M1) 먼저 구현하여 cfAccessVerifier가 resolver에만 의존하도록 분리. emailHashHook은 sha256Hex에만 의존하는 단순 wrapper. betterAuth.ts는 마지막 — D1+KV adapter 초기화가 복잡도 최고점.

#### 구현 상세

**`src/auth/jwksResolver.ts`**
```ts
export interface JwksResolver {
  resolve(): Promise<{ keys: JsonWebKey[] }>;
}
export const fakeJwksResolver: JwksResolver = {
  resolve: () => Promise.resolve({ keys: [] }),
};
export function createFetchJwksResolver(url: string): JwksResolver {
  return { resolve: () => fetch(url).then(r => r.json()) };
}
```

**`src/auth/cfAccessVerifier.ts`**
- `import { createLocalJWKSet, jwtVerify } from "jose"`
- `createCFAccessVerifier(jwksResolver: JwksResolver, teamDomain: string)`
  - resolver.resolve() → keys → createLocalJWKSet
  - jwtVerify(jwt, JWKS, { issuer: `https://${teamDomain}.cloudflareaccess.com` })
  - return `payload as CFAccessPayload`
- `extractAdminClaim(payload: CFAccessPayload): boolean` — `payload.email?.endsWith('@admin.domain')` 또는 `payload["custom_claim"]` 검사

**`src/auth/emailHashHook.ts`**
- `generateEmailHash(email: string): Promise<string>` — `sha256Hex(email.toLowerCase().trim())`
- `emailHashBeforeCreateHook`: BetterAuth before hook. ctx.path === `/sign-up/email` 매처.
  - `ctx.body.email` → `generateEmailHash` → `ctx.body.email_hash = hash` 주입
  - OQ-2 확정: BetterAuth v1.6.9 `hooks.before` 배열의 `{ matcher, handler }` 패턴 사용

**`src/auth/betterAuth.ts`**
```ts
import { betterAuth } from "better-auth";
import { drizzleAdapter } from "better-auth/adapters/drizzle";

export interface BetterAuthConfig {
  d1: D1Database;
  kv: KVNamespace;
}

export function createAuth(config: BetterAuthConfig) {
  return betterAuth({
    database: drizzleAdapter(config.d1, {
      provider: "sqlite",
      schema: { users },  // cycle 2 + 0001 확장 schema
    }),
    secondaryStorage: {
      get: (key) => config.kv.get(key),
      set: (key, value, ttl) =>
        config.kv.put(key, value, ttl ? { expirationTtl: ttl } : undefined),
      delete: (key) => config.kv.delete(key),
    },
    emailAndPassword: { enabled: true },
    hooks: {
      before: [{
        matcher: (ctx) => ctx.path === "/sign-up/email",
        handler: emailHashBeforeCreateHook,
      }],
    },
    advanced: {
      cookiePrefix: "ba",
      // api.<DOMAIN>: host-scoped (sameSite=Strict, domain NOT set) — BC1
    },
  });
}

// 편의 함수 (auth 인스턴스 래핑)
export async function signUp(auth: ReturnType<typeof createAuth>, email: string, password: string, name: string) { ... }
export async function signIn(auth, email, password) { ... }
export async function signOut(auth, sessionToken) { ... }
export async function getSession(auth, sessionToken) { ... }
export async function lookupUserByEmailHash(auth, emailHash: string) { ... }
```

#### Commands

```bash
cd apps/workers
npx vitest run test/auth/
```

#### 검증

- `test/auth/betterAuth.test.ts` 10 pass
- `test/auth/cfAccessVerifier.test.ts` 8 pass (+ 이미 pass된 1 = 9 pass)
- `test/auth/emailHashHook.test.ts` 9 pass
- 소계: ~27 pass

#### Impact Analysis

| 항목 | 영향 |
|------|------|
| 파일 | `src/auth/betterAuth.ts`, `cfAccessVerifier.ts`, `jwksResolver.ts`, `emailHashHook.ts`, `index.ts` |
| 의존성 | Step 1 crypto layer 완료 필수 (emailHashHook → sha256Hex) |
| 외부 패키지 | `jose` — better-auth 의존성 포함 여부 확인, 없으면 Step 0에서 별도 설치 |

---

### Step 3 — Middleware 5종

#### Approach

각 미들웨어는 독립 구현. CSRF만 cycle 1 cookie-policy.ts 결합 지점 확인 필요. Hono `MiddlewareHandler` 타입 준수.

#### 구현 상세

**`src/middleware/cors.ts`**
```ts
export function createCorsMiddleware(allowedOrigins: string[]): MiddlewareHandler {
  return async (c, next) => {
    const origin = c.req.header("Origin") ?? "";
    if (allowedOrigins.includes(origin)) {
      c.header("Access-Control-Allow-Origin", origin);
      c.header("Vary", "Origin");
    }
    if (c.req.method === "OPTIONS") {
      c.header("Access-Control-Allow-Methods", "GET,POST,PUT,DELETE,OPTIONS");
      c.header("Access-Control-Allow-Headers", "Content-Type,Authorization");
      return c.text("", 204);
    }
    await next();
  };
}
```

**`src/middleware/csp.ts`**
- nonce: `crypto.getRandomValues(new Uint8Array(16))` → base64
- 헤더: `Content-Security-Policy: default-src 'self'; script-src 'self' 'nonce-{nonce}'; ...`
- `extraDirectives` 옵션으로 확장 가능
- nonce를 `c.set("cspNonce", nonce)` 에 저장 (템플릿 참조용)

**`src/middleware/hsts.ts`**
- `productionOnly: boolean` (default true) — `c.env?.ENVIRONMENT === "production"` 또는 외부 주입
- 헤더: `Strict-Transport-Security: max-age=31536000; includeSubDomains` (≥1년)
- production이 아니면 헤더 생략

**`src/middleware/rateLimit.ts`**
- KV sliding window: key = `${keyPrefix}:${clientIp}`
- value = JSON 타임스탬프 배열 (`number[]`), `expirationTtl: windowSeconds`
- 요청마다 현재 window 밖 타임스탬프 제거 → 배열 길이 >= maxRequests이면 429
- `clientIp`: `c.req.header("CF-Connecting-IP")` || `c.req.header("X-Forwarded-For")` || "unknown"

**`src/middleware/csrf.ts`**
- Safe methods bypass: GET/HEAD/OPTIONS
- Bearer bypass: `Authorization` 헤더 존재 + `Cookie` 헤더 부재 (API client 패턴)
- 검증 1 — Origin 헤더: 허용 origin 목록과 비교
- 검증 2 — Sec-Fetch-Site: `same-origin` 또는 `same-site` 허용. 헤더 없으면(구형 브라우저) Origin만으로 검증
- Cycle 1 `cookie-policy.ts`와 결합: host-scoped cookie 정책(BC1) 준수 — sameSite=Strict이므로 CSRF 검증 중복이지만 Defense-in-depth로 유지

#### Commands

```bash
cd apps/workers
npx vitest run test/middleware/
```

#### 검증

- `test/middleware/cors.test.ts` 6 pass
- `test/middleware/csp.test.ts` 6 pass
- `test/middleware/hsts.test.ts` 6 pass
- `test/middleware/rateLimit.test.ts` 4 pass
- `test/middleware/csrf.test.ts` 10 pass
- 소계: 32 pass

#### Impact Analysis

| 항목 | 영향 |
|------|------|
| 파일 | `src/middleware/cors.ts`, `csp.ts`, `hsts.ts`, `rateLimit.ts`, `csrf.ts`, `index.ts` |
| 의존성 | Step 0 (index.ts middleware 등록)과 독립 구현 가능 — Step 4에서만 결합 |

---

### Step 4 — index.ts integration + 0001 migration apply

#### Approach

Step 1-3 완료 후 통합 단계. `apps/workers/src/index.ts`에 middleware 등록 순서 준수. test/setup.ts가 0000 + 0001 migration 모두 apply하도록 수정 필요 여부 확인.

#### 수행 작업

1. `apps/workers/src/index.ts` middleware 등록:
   ```ts
   import { createHstsMiddleware } from "./middleware/hsts";
   import { createCspMiddleware } from "./middleware/csp";
   import { createCorsMiddleware } from "./middleware/cors";
   import { createRateLimitMiddleware } from "./middleware/rateLimit";
   import { createCsrfMiddleware } from "./middleware/csrf";

   // 순서: HSTS → CSP → CORS → rateLimit → CSRF
   app.use("*", createHstsMiddleware({ productionOnly: true }));
   app.use("*", createCspMiddleware({ extraDirectives: {} }));
   app.use("*", createCorsMiddleware(env.ALLOWED_ORIGINS?.split(",") ?? []));
   app.use("*", createRateLimitMiddleware({ kv: env.KV, keyPrefix: "rl", maxRequests: 100, windowSeconds: 60 }));
   app.use("*", createCsrfMiddleware({ allowedOrigins: env.ALLOWED_ORIGINS?.split(",") ?? [] }));
   ```

2. `test/setup.ts` 확인: D1 migration apply 로직이 `0000_*.sql` 뿐 아니라 `0001_*.sql`도 glob하는지 확인. `fs.readdirSync("migrations").sort()` 패턴이면 자동 포함. 아니면 수동 추가.

3. cycle 2 db test 그대로 pass 회귀 확인: `npx vitest run test/db/`

#### Commands

```bash
cd apps/workers
npx vitest run test/db/        # cycle 2 회귀 확인
npx vitest run test/auth/ test/crypto/ test/middleware/  # cycle 4 전체
```

#### 검증

- cycle 2 db tests (7 files) 그대로 pass
- 0001 migration apply 후 schema 오류 없음

---

### Step 5 — 통합 검증

#### Approach

전체 vitest run으로 0 fail / 458 pass (+ 0 skipped) 확인. cycle 1-3 (370) 회귀 없음 최종 확인.

#### Commands

```bash
cd apps/workers
npx vitest run
```

#### 검증 기준

```
 Test Files  0 failed | 36 passed (36)
      Tests  0 failed | 458 passed | 0 skipped (458)
```

> keyRotation의 2 skipped는 실 CryptoKey 구현 후 0 skipped로 전환 기대. 실패 시 원인 분석 후 보고.

- cycle 1-3 기존 25 test files, 370 pass 회귀 없음
- cycle 4 신규 11 test files, 88 pass 전환

## Implementation 분할 권장

### 옵션 A — 단일 에이전트 순차 (권장)

Step 0 → 1 → 2 → 3 → 4 → 5 순차 실행. 단일 에이전트가 5단계 컨텍스트를 유지하며 의존 트리를 순서대로 구현.

**근거**:
- RED 041 88 fail은 cycle 3의 90 fail과 동일 규모 이하 — cycle 3 단일 에이전트 성공 사례 존재 (Plan 038 → 039 구현).
- crypto(leaf) → auth → middleware → integration의 의존 트리가 선형에 가까워 병렬화 이점 제한적.
- 도메인 지식(BetterAuth Workers 호환, JWKS DI, envelope 시그니처)이 단일 컨텍스트에서 누적되는 것이 오류 위험 감소.

### 옵션 B — Agent Teams (fallback)

3 병렬 멤버 + integration 멤버:
- Member A: crypto (Step 1)
- Member B: middleware (Step 3)
- Member C: auth (Step 2, Member A 완료 후)
- Integration (Step 4+5): A+B+C 완료 후

**사용 조건**: 단일 에이전트 Step 2(BetterAuth) 에서 Workers 호환 이슈로 블로킹 발생 시 fallback.

### 권장: 옵션 A

## Cross-Reference Table

RED 041 § Test Files Created 기반. 구현 파일 + Step 컬럼 추가.

| 테스트 파일 | Tests | Failed(RED) | 구현 파일 | Step |
|-------------|-------|-------------|----------|------|
| `test/auth/betterAuth.test.ts` | 10 | 10 | `src/auth/betterAuth.ts` | Step 2 |
| `test/auth/cfAccessVerifier.test.ts` | 9 | 8 | `src/auth/cfAccessVerifier.ts`, `jwksResolver.ts` | Step 2 |
| `test/auth/emailHashHook.test.ts` | 9 | 9 | `src/auth/emailHashHook.ts` | Step 2 |
| `test/crypto/envelope.test.ts` | 13 | 13 | `src/crypto/envelope.ts`, `hmac.ts` | Step 1 |
| `test/crypto/keyRotation.test.ts` | 11 | 9+2skip | `src/crypto/keyRotation.ts` | Step 1 |
| `test/crypto/emailHash.test.ts` | 7 | 7 | `src/crypto/emailHash.ts` | Step 1 |
| `test/middleware/cors.test.ts` | 6 | 6 | `src/middleware/cors.ts` | Step 3 |
| `test/middleware/csp.test.ts` | 6 | 6 | `src/middleware/csp.ts` | Step 3 |
| `test/middleware/hsts.test.ts` | 6 | 6 | `src/middleware/hsts.ts` | Step 3 |
| `test/middleware/rateLimit.test.ts` | 4 | 4 | `src/middleware/rateLimit.ts` | Step 3 |
| `test/middleware/csrf.test.ts` | 10 | 10 | `src/middleware/csrf.ts` | Step 3 |
| **합계** | **91** | **88** | | |

### 커버 항목 상세

| 테스트 파일 | 커버 항목 (RED 041 원문) |
|-------------|------------------------|
| `betterAuth.test.ts` | BetterAuth D1+KV signup/signin/signout/lookup, schema 정합 |
| `cfAccessVerifier.test.ts` | CF Access JWT 검증, JWKS DI, admin claim, 만료/서명 reject |
| `emailHashHook.test.ts` | email_hash 생성 hook, deterministic, email 변경 재계산 |
| `envelope.test.ts` | AES-256-GCM, IV=HMAC[:12], deterministic, round-trip, wrong key |
| `keyRotation.test.ts` | 5-phase rotation, dual-read, addNewKey, retireKey |
| `emailHash.test.ts` | SHA-256 hex, deterministic, empty string, unicode |
| `cors.test.ts` | allowed/disallowed origin, OPTIONS preflight |
| `csp.test.ts` | CSP header, default-src, script-src, nonce, extraDirectives |
| `hsts.test.ts` | HSTS max-age ≥1년, includeSubDomains, productionOnly |
| `rateLimit.test.ts` | KV sliding window, 429, IP separation, keyPrefix isolation |
| `csrf.test.ts` | Origin+Sec-Fetch-Site 이중, safe methods bypass, Bearer bypass |

## Verification Plan

### 주요 검증 항목

| # | 검증 항목 | 명령 / 방법 | 성공 기준 |
|---|----------|------------|----------|
| V1 | 전체 vitest 0 fail | `cd apps/workers && npx vitest run` | `0 failed | 458 passed` |
| V2 | cycle 1-3 회귀 없음 | 위 vitest run 결과에서 기존 25 test files pass 확인 | 370 pass 유지 |
| V3 | 0001 migration 멱등 dry-run | `npx drizzle-kit generate` 재실행 시 diff 없음 | no new migration generated |
| V4 | JWKS DI unit test | `npx vitest run test/auth/cfAccessVerifier.test.ts` | fakeResolver test 포함 9 pass |
| V5 | envelope 결정성 IV 검증 | `test/crypto/envelope.test.ts` deterministic 테스트 pass | 동일 입력 → 동일 IV |
| V6 | parallel-key dual-read | `test/crypto/keyRotation.test.ts` | dual-read (K_n + K_{n+1}) 9 pass |
| V7 | BetterAuth Workers 호환 | `test/auth/betterAuth.test.ts` 10 pass + vitest 오류 없음 | `better-auth` import 성공 또는 external 유지 판정 |
| V8 | middleware 순서 smoke | `test/middleware/` 32 pass | HSTS/CSP/CORS/rateLimit/CSRF 각 독립 pass |
| V9 | cycle 2 DB 회귀 | `npx vitest run test/db/` | 7 db test files 그대로 pass |

### 단계별 중간 검증 게이트

| Step | 중간 gate | 실패 시 |
|------|----------|--------|
| Step 0 완료 | `migrations/0001_*.sql` 존재 + wrangler.toml nodejs_compat 확인 | Step 1 진행 중단, R1 재점검 |
| Step 1 완료 | `npx vitest run test/crypto/` ~29 pass | envelope/keyRotation 구현 재검토 |
| Step 2 완료 | `npx vitest run test/auth/` ~27 pass | BetterAuth Workers 호환 R1 risk 재검토 |
| Step 3 완료 | `npx vitest run test/middleware/` 32 pass | 개별 middleware 오류 확인 |
| Step 4 완료 | `npx vitest run test/db/` 회귀 없음 | 0001 migration 충돌 분석 |
| Step 5 완료 | `npx vitest run` 0 fail / 458 pass | 잔여 fail 파일별 분류 + 재수정 |

## Risks & Mitigations

| # | Risk | 설명 | 완화 | Phase |
|---|------|------|------|-------|
| R1 | better-auth Workers 호환 | nodejs_compat flag가 존재하지만 better-auth 실 import 시 Workers 런타임에서 Node.js 내부 모듈 참조 오류 가능. RED phase에서는 stub이라 미발현. | Step 0: `vitest.config.ts` external 제거 시도 + smoke test. 실패 시 external 유지. betterAuth.ts 구현 시 `import("better-auth")` dynamic import 분리 또는 Workers edge 빌드 경로 직접 지정 (`better-auth/edge`) | Phase 1 |
| R2 | 0001 migration이 0000과 충돌 | BetterAuth `name`, `emailVerified`, `image` 컬럼이 cycle 2 schema.ts의 users 정의와 중복/충돌. drizzle-kit이 ALTER TABLE을 잘못 생성하면 0000 migration과 분리 불가 | drizzle-kit generate 결과 SQL 수동 검토. `ADD COLUMN IF NOT EXISTS` 패턴 확인. 충돌 시 nullable 컬럼으로 선언 | Phase 1 |
| R3 | KV 60s eventual consistency | 로컬 miniflare는 즉시 일관성. production KV는 eventual consistency (최대 60s). session token 조회 시 stale read 가능 | Phase 2 carryover (Brief 021 Decision 12 Phase 2 항목). Phase 1 test는 miniflare로 완결 | Phase 2 |
| R4 | parallel-key 실 키 등록 | `wrangler secret put` = 외부 자원 → Phase 2 carryover. unit test는 in-memory CryptoKey 교체로 충분 | Phase 2 cutover 전 `rotate-encryption-key.sh` 작성 (R4 011 § R4-F3 참조) | Phase 2 |
| R5 | CF Access 실 SSO 미연결 | Phase 2 carryover. JWKS DI 패턴으로 Phase 1에서는 fakeJwksResolver unit test만 | Phase 2에서 실 CF Team Domain + JWKS endpoint 연결 | Phase 2 |
| R6 | Cookie 격리(BC1) + csrf.ts 결합 | Synthesis BC1 격리 정책이 cycle 1 `cookie-policy.ts` placeholder와 결합 필요. csrf.ts에서 sameSite=Strict + host-scoped 결합이 명확하지 않으면 이중 검증이 비일관적 | Step 3 csrf.ts 구현 시 cookie-policy.ts Read → host-scoped 정책 결합 지점 명시 | Phase 1 |
| R7 | BetterAuth `before` hook API (OQ-2) | v1.6.9 `hooks.before` 배열의 `{ matcher, handler }` 패턴이 실제 동작하지 않을 경우 emailHash hook 위치 재탐색 필요 | Step 2: betterAuth.test.ts의 email_hash 생성 테스트로 즉시 검증. 실패 시 hook → mounter middleware 대안 | Phase 1 |
| R8 | jose 패키지 미포함 | better-auth가 jose를 내부 의존성으로 포함하지 않을 경우 cfAccessVerifier.ts 빌드 실패 | Step 0: `ls node_modules/jose` 확인. 없으면 `npm install jose` | Phase 1 |

## References

| 문서 | 경로 | 참조 목적 |
|------|------|----------|
| RED 041 Cycle 4 TDD Red | `/docs/6_backend/02_cf_workers_rebuild/041_TDDRed_cycle4_auth_security.md` | Test Files Created, Stub Files, Implementation Hints, Risks (직접 입력) |
| Brief 021 Phase 1 Conversion | `/docs/6_backend/02_cf_workers_rebuild/021_Brief_conversion_phase1.md` | Decision 7 (BetterAuth + CF Access), Decision 15 (nodejs_compat), Ideal Criteria #6/17/18/19, M1 |
| Scope 026 Phase 1 Scope | `/docs/6_backend/02_cf_workers_rebuild/026_Scope_conversion_phase1.md` | Cycle 4 범위 확인 |
| R4 011 BetterAuth Auth Hybrid | `/docs/6_backend/02_cf_workers_rebuild/011_Research_axis4_auth_hybrid.md` | § Active v1.6.9, § R4-F3 Key rotation 절차, parallel-key 패턴 |
| Synthesis 018 Research Cycle | `/docs/6_backend/02_cf_workers_rebuild/018_Synthesis_research_cycle.md` | 충돌 1 정합 (R1 envelope + R4 분리 컬럼), BC1 Cookie 격리 |
| Cycle 2 schema.ts | `/apps/workers/src/db/schema.ts` | users 테이블 R4 컬럼 (email_hash, email_enc, encryption_version) |
| Cycle 1 wrangler.toml | `/apps/workers/wrangler.toml` | nodejs_compat flag 위치, KV binding |
| Plan 034 Cycle 2 DB | `/docs/6_backend/02_cf_workers_rebuild/034_Plan_cycle2_db.md` | 형식 참조 |
| Plan 038 Cycle 3 Services | `/docs/6_backend/02_cf_workers_rebuild/038_Plan_cycle3_services.md` | 형식 참조, vitest pin 3.0.5 |
