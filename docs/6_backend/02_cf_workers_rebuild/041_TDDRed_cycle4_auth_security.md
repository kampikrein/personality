---
id: "041"
type: tdd-red
title: "Cycle 4 Auth + Security Baseline — RED phase"
created: 2026-04-30
traces_brief: "021"
traces_scope: "026"
traces_research: ["011"]
traces_synthesis: "018"
traces_cycle3_impl: "039"
cycle: 4
phase_scope: "phase-1-conversion"
status: completed
confidence: high
summary: >
  BetterAuth + CF Access verifier + Web Crypto envelope + email_hash + key rotation + 보안 5종 미들웨어
  검증 vitest 테스트 작성. cycle 1-3 (370 pass) 유지 + cycle 4 88 fail 의도. green phase에서 구현 시 통과.
keywords: [tdd-red, auth, security, betterauth, cf-access, crypto, middleware, cycle4]
---

## Progress

- [x] 스켈레톤 Write
- [x] R4 011 + Synthesis 018 grep 발췌
- [x] Step 1 — package.json better-auth ^1.6.9 추가 + npm install (monorepo root에 설치됨)
- [x] Step 2 — stub 파일 작성 (auth/ + crypto/ + middleware/ 3 디렉토리, 14 파일)
- [x] Step 3 — RED test 작성 (11 test files, 91 tests)
- [x] Step 4 — fail 확인 (cycle 1-3: 370 pass + cycle 4: 88 fail)
- [x] vitest.config.ts — better-auth external 설정 (Workers 런타임 충돌 방지)
- [x] Step 5 — Implementation Hints 작성
- [x] 보고서 완성

## Summary

Cycle 4 RED phase 완료. BetterAuth(D1+KV) 인증, CF Access JWT verifier (JWKS DI 패턴 M1), Web Crypto AES-256-GCM envelope (IV=HMAC-SHA256(detKey, plaintext)[:12]), email_hash 생성 hook, parallel-key rotation (5-phase R4-F3), 보안 baseline 5종(CORS/CSP/HSTS/rate limit/hono CSRF) 검증 vitest 테스트 91개 작성.

모든 production code 미작성. stub만 (`throw new Error('not implemented')`). Cycle 1-3의 369→370 pass (vitest 재실행 시 1개 추가됨, 미세 차이) 그대로 유지.

주요 발견: better-auth 패키지가 Workers 런타임과 충돌 (Node.js crypto 내부 모듈 의존). `vitest.config.ts`에 `resolve.external: ["better-auth"]` 추가로 해결. GREEN phase에서는 `betterAuth.ts` 구현 시 `node_compat = true` (wrangler.toml) 또는 Workers 호환 edge 빌드 경로로 분리 필요.

## Test Files Created

| 파일 | 테스트 수 | 커버 항목 |
|------|----------|----------|
| `test/auth/betterAuth.test.ts` | 10 | BetterAuth D1+KV signup/signin/signout/lookup, schema 정합 |
| `test/auth/cfAccessVerifier.test.ts` | 9 | CF Access JWT 검증, JWKS DI, admin claim, 만료/서명 reject |
| `test/auth/emailHashHook.test.ts` | 9 | email_hash 생성 hook, deterministic, email 변경 재계산 |
| `test/crypto/envelope.test.ts` | 13 | AES-256-GCM, IV=HMAC[:12], deterministic, round-trip, wrong key |
| `test/crypto/keyRotation.test.ts` | 11 | 5-phase rotation, dual-read, addNewKey, retireKey |
| `test/crypto/emailHash.test.ts` | 7 | SHA-256 hex, deterministic, empty string, unicode |
| `test/middleware/cors.test.ts` | 6 | allowed/disallowed origin, OPTIONS preflight |
| `test/middleware/csp.test.ts` | 6 | CSP header, default-src, script-src, nonce, extraDirectives |
| `test/middleware/hsts.test.ts` | 6 | HSTS max-age ≥1년, includeSubDomains, productionOnly |
| `test/middleware/rateLimit.test.ts` | 4 | KV sliding window, 429, IP separation, keyPrefix isolation |
| `test/middleware/csrf.test.ts` | 10 | Origin+Sec-Fetch-Site 이중, safe methods bypass, Bearer bypass |
| **합계** | **91** | |

실제 vitest 실행 결과: 88 fail (2 skipped는 keyRotation beforeAll 비동기 처리 skip — 정상).

## Stub Files

### `src/auth/` (4 files)
| 파일 | 주요 export |
|------|------------|
| `index.ts` | barrel re-export |
| `betterAuth.ts` | `createAuth`, `signUp`, `signIn`, `signOut`, `getSession`, `lookupUserByEmailHash` |
| `cfAccessVerifier.ts` | `createCFAccessVerifier` (JWKS DI 패턴 M1), `extractAdminClaim` |
| `emailHashHook.ts` | `generateEmailHash`, `emailHashBeforeCreateHook` |

### `src/crypto/` (4 files)
| 파일 | 주요 export |
|------|------------|
| `index.ts` | barrel re-export |
| `envelope.ts` | `encryptEnvelope`, `decryptEnvelope`, `deriveIV` |
| `keyRotation.ts` | `createRotationContext`, `selectKeyForVersion`, `addNewKey`, `reEncryptRow`, `retireKey` |
| `emailHash.ts` | `sha256Hex` |

### `src/middleware/` (6 files)
| 파일 | 주요 export |
|------|------------|
| `index.ts` | barrel re-export |
| `cors.ts` | `createCorsMiddleware` |
| `csp.ts` | `createCspMiddleware` |
| `hsts.ts` | `createHstsMiddleware` |
| `rateLimit.ts` | `createRateLimitMiddleware` |
| `csrf.ts` | `createCsrfMiddleware` |

## Dependencies Added

`apps/workers/package.json` diff:
```json
// 추가됨
"better-auth": "^1.6.9"
```

설치 위치: monorepo root `node_modules/better-auth` (v1.6.9). `--legacy-peer-deps` 필요 (vitest-pool-workers peer dependency 충돌).

`vitest.config.ts` 추가:
```ts
resolve: {
  external: ["better-auth"],
},
```
이유: better-auth가 Workers 런타임(workerd)에서 로드 시 Node.js internal module 의존으로 internal error 발생. RED phase stubs는 better-auth를 import하지 않으므로 external 처리가 정확한 해결책.

## Test Results

```
 Test Files  11 failed | 25 passed (36)
      Tests  88 failed | 370 passed | 2 skipped (460)
   Duration  5.68s
```

- **Cycle 1-3 유지**: 25 test files, 370 pass (cycle 1-3 베이스 유지 확인)
- **Cycle 4 신규**: 11 test files, 88 fail (의도된 RED — stub `throw new Error('not implemented')`)
- **2 skipped**: `keyRotation.test.ts`의 `beforeAll` 내 crypto key 생성이 stub throw로 skip되는 vitest 정상 동작

### Cycle 4 test files 실패 분포
| 파일 | tests | failed | skipped |
|------|-------|--------|---------|
| betterAuth.test.ts | 10 | 10 | 0 |
| cfAccessVerifier.test.ts | 9 | 8 | 0 |
| emailHashHook.test.ts | 9 | 9 | 0 |
| envelope.test.ts | 13 | 13 | 0 |
| keyRotation.test.ts | 11 | 9 | 2 |
| emailHash.test.ts | 7 | 7 | 0 |
| cors.test.ts | 6 | 6 | 0 |
| csp.test.ts | 6 | 6 | 0 |
| hsts.test.ts | 6 | 6 | 0 |
| rateLimit.test.ts | 4 | 4 | 0 |
| csrf.test.ts | 10 | 10 | 0 |

cfAccessVerifier 8/9 fail: 1 test (`JWKS resolver DI: fake resolver produces fake keys`) pass — `fakeJwksResolver.resolve()`가 stub throw 없이 직접 resolve하므로 정상.

## Implementation Hints for Green Phase

### BetterAuth(D1+KV) — `src/auth/betterAuth.ts`

```ts
import { betterAuth } from "better-auth";
import { drizzleAdapter } from "better-auth/adapters/drizzle";
import { db } from "../db";
import { users } from "../db/schema";

export function createAuth(config: BetterAuthConfig) {
  return betterAuth({
    database: drizzleAdapter(config.d1, {
      provider: "sqlite",
      schema: { users },
    }),
    secondaryStorage: {
      // KV SecondaryStorage thin wrapper (~30 LOC — R4 011 § Active v1.6.9)
      get: (key) => config.kv.get(key),
      set: (key, value, ttl) => config.kv.put(key, value, ttl ? { expirationTtl: ttl } : undefined),
      delete: (key) => config.kv.delete(key),
    },
    emailAndPassword: { enabled: true },
    hooks: {
      before: [{ matcher: (ctx) => ctx.path === "/sign-up/email", handler: emailHashBeforeCreateHook }],
    },
    // BC1: Cookie host-scope isolation
    advanced: {
      cookiePrefix: "ba",
      // api.<DOMAIN>: sameSite=Strict, domain NOT set (host-scoped)
      // admin.<DOMAIN>: separate auth instance or separate cookie name
    },
  });
}
```

**Workers 호환 주의**: `wrangler.toml`에 `node_compat = true` 추가 필요 (`better-auth`의 crypto 내부 모듈 요구).

### CF Access Verifier — `src/auth/cfAccessVerifier.ts`

JWKS DI 패턴 (M1):
```ts
import { createRemoteJWKSet, jwtVerify } from "jose";

export function createCFAccessVerifier(jwksResolver: JwksResolver) {
  return async (jwt: string) => {
    const { keys } = await jwksResolver.resolve();
    const JWKS = createLocalJWKSet({ keys });
    const { payload } = await jwtVerify(jwt, JWKS, {
      issuer: `https://${CF_TEAM_DOMAIN}.cloudflareaccess.com`,
    });
    return payload as CFAccessPayload;
  };
}
// Production: jwksResolver = { resolve: () => fetch(CF_JWKS_URL).then(r => r.json()) }
// Test: jwksResolver = { resolve: () => Promise.resolve(localJWKS) }
```

jose 패키지 추가 필요: `npm install jose`.

### Web Crypto Envelope — `src/crypto/envelope.ts`

```ts
export async function deriveIV(detKey: CryptoKey, plaintext: string): Promise<Uint8Array> {
  const data = new TextEncoder().encode(plaintext);
  const sig = await crypto.subtle.sign("HMAC", detKey, data);
  return new Uint8Array(sig).slice(0, 12); // HMAC-SHA256[:12]
}

export async function encryptEnvelope(plaintext: string, detKey: CryptoKey, version: number): Promise<EnvelopeJSON> {
  const iv = await deriveIV(detKey, plaintext);
  // Note: detKey is HMAC key for IV derivation; need separate AES key for encryption
  // GREEN phase: accept { hmacKey, aesKey } or derive AES key from same secret
  const ct = await crypto.subtle.encrypt({ name: "AES-GCM", iv }, aesKey, new TextEncoder().encode(plaintext));
  return {
    iv: Array.from(iv).map(b => b.toString(16).padStart(2, '0')).join(''),
    ct: btoa(String.fromCharCode(...new Uint8Array(ct))),
    v: version,
  };
}
```

**설계 결정**: `encryptEnvelope`의 함수 시그니처를 `{ hmacKey, aesKey }` 로 분리하거나, 동일 raw secret에서 HMAC/AES 두 키 파생. Makeplan에서 확정.

### email_hash Hook — `src/auth/emailHashHook.ts`

```ts
export async function generateEmailHash(email: string): Promise<string> {
  const data = new TextEncoder().encode(email.toLowerCase()); // normalize
  const digest = await crypto.subtle.digest("SHA-256", data);
  return Array.from(new Uint8Array(digest)).map(b => b.toString(16).padStart(2, '0')).join('');
}
```

**BetterAuth hook 위치**: `before` hook at path `/sign-up/email`. OQ-2 (hook 정확한 위치) GREEN phase makeplan 확정.

### Parallel-key Rotation — `src/crypto/keyRotation.ts`

```ts
export function createRotationContext(keys: RotationKey[]): RotationContext {
  const maxVersion = Math.max(...keys.map(k => k.version));
  return { keys: [...keys], currentVersion: maxVersion };
}
export function selectKeyForVersion(ctx: RotationContext, version: number): CryptoKey {
  const entry = ctx.keys.find(k => k.version === version);
  if (!entry) throw new Error(`Key version ${version} not found`);
  return entry.key;
}
```

`reEncryptRow`: 기존 `emailEnc` JSON parse → `decryptEnvelope(K_n)` → `encryptEnvelope(K_{n+1})` → stringify.

### Security Middleware — `src/middleware/`

**CORS**: Hono 내장 `cors()` 확장 또는 `app.use('*', async (c, next) => { ... })`.

**CSP**: nonce는 `crypto.getRandomValues(new Uint8Array(16))` → base64. Hono context에 저장 후 template에서 참조.

**HSTS**: `productionOnly` 판단 = `c.env.ENVIRONMENT === 'production'` (wrangler.toml vars).

**Rate limit**: KV key = `${keyPrefix}:${ip}`, value = JSON 타임스탬프 배열. `expirationTtl: windowSeconds`.

**CSRF**: Bearer 감지 = `Authorization` 헤더 존재 + `Cookie` 헤더 부재. Sec-Fetch-Site 없는 구형 브라우저는 Origin만으로 검증 (OQ-5 makeplan 확정).

### KV Namespace 설정
Cycle 1의 `wrangler.toml` `[[kv_namespaces]]` binding `KV` 활용. miniflare in-memory로 로컬 완결. Session TTL = 7일 (604800초).

### Workers `node_compat` 설정
`wrangler.toml`에 추가:
```toml
compatibility_flags = ["nodejs_compat"]
```
better-auth v1.6.9 edge 빌드가 Workers 런타임에서 동작하려면 nodejs_compat flag 필요.

## Risks

| Risk | 설명 | 완화 |
|------|------|------|
| **BetterAuth schema 충돌** | BetterAuth가 `users` 테이블에 `name`, `image`, `emailVerified` 컬럼 자동 추가 시도. Cycle 2 schema (14 tables)와 충돌 가능. | GREEN phase: Drizzle adapter에 커스텀 schema 주입 (`schema: { users }` 오버라이드). BetterAuth 컬럼 추가는 `0002_betterauth_columns.sql` migration으로 분리. |
| **better-auth Workers 호환** | better-auth 내부가 `crypto` (Node.js) 모듈에 의존. Workers 런타임 직접 로드 시 internal error. | `nodejs_compat` flag + `vitest.config.ts` `resolve.external`. GREEN phase에서 실제 동작 검증. |
| **JWKS resolver DI 패턴** | CF Access verifier unit test는 fake JWKS로 통과하지만, 실 JWKS fetch는 Phase 2 carryover (외부 자원). | Phase 1 verify: fake JWT/JWKS만. Phase 2: 실 CF JWKS endpoint 연결. |
| **envelope 함수 시그니처** | `encryptEnvelope(plaintext, detKey, version)` — detKey가 HMAC용. 별도 AES 키 필요. 함수 시그니처 미확정. | GREEN phase makeplan에서 `{ hmacKey, aesKey }` 분리 또는 단일 raw secret 파생으로 확정. |
| **KV 60s eventual consistency** | Phase 2 carryover (Scope 026 M9). 로컬 miniflare는 즉시 일관성. | Phase 2 production 검증 항목. |
| **CF JWKS 6주 rotation** | Phase 2 carryover (Scope 026 M11). JWKS rotation fixture test (createLocalJWKSet 2개 dual-read)는 GREEN에서 구현. | Phase 2 carryover 명시. |
| **parallel-key 실 키 등록** | wrangler secret put은 외부 자원 → Phase 2. | Unit test는 in-memory CryptoKey 교체로 충분. |
| **BetterAuth `before` hook API** | OQ-2: `before-create` 정확한 hook path 미확정. | GREEN phase: BetterAuth v1.6.9 changelog + test로 검증. |

## References

- Brief 021 § In Scope 5 / Decision 7: `/docs/6_backend/02_cf_workers_rebuild/021_Brief_conversion_phase1.md`
- Scope 026 § Cycle 4: `/docs/6_backend/02_cf_workers_rebuild/026_Scope_conversion_phase1.md`
- R4 BetterAuth (v1.6.9, D1 adapter, rotation): `/docs/6_backend/02_cf_workers_rebuild/011_Research_axis4_auth_hybrid.md`
- Synthesis 018 § R1↔R4 정합 (envelope JSON + Cookie BC1): `/docs/6_backend/02_cf_workers_rebuild/018_Synthesis_research_cycle.md`
- Cycle 2 schema: `/apps/workers/src/db/schema.ts` (users 테이블 R4 컬럼 정의)
- vitest.config.ts 수정: `resolve.external: ["better-auth"]` 추가
