---
id: "008"
type: research
title: "R1 — Drizzle ORM + D1 통합 패턴"
created: 2026-04-29
traces_brief: "001"
traces_scope: "007"
research_axis: "R1"
summary: >
  SOT는 단일 — drizzle-kit generate가 schema의 source, wrangler d1 migrations
  apply가 실행·상태 추적(d1_migrations 테이블)을 전담. 9개 JSON 컬럼은 Drizzle
  text({ mode: 'json' }) + $type<T>()로 매핑하고 D1 JSON1 함수로 쿼리. 결정성
  email 컬럼은 Web Crypto AES-GCM + HMAC-SHA256(key, plaintext) IV(Rails 동등)
  로 ciphertext 자체에 UNIQUE INDEX. Rollback은 D1 Time Travel(30일 bookmark)을
  primary, 수동 reverse SQL을 secondary. drift 감지는 drizzle-kit check + CI에서
  wrangler d1 migrations list 비교.
keywords: [drizzle, d1, wrangler, json1, web-crypto, deterministic-encryption, migration, time-travel, rollback]
---

# R1 — Drizzle ORM + D1 통합 패턴

## Research Overview

### Background

Brief 001(Decision 3) + Scope 007(Cycle 2) 제약: D1 + Drizzle ORM 결정 후 통합 패턴 4개 미해결.
- **M1**: drizzle-kit ↔ wrangler d1 migrations 통합 SOT 미명시
- **JSON 9 컬럼**: server/db/schema.rb에서 9 컬럼 확인 — D1은 native JSON 타입 부재(SQLite 기반), JSON1 함수로 쿼리
- **결정성 암호화**: server/app/models/user.rb:4 `encrypts :email, deterministic: true` — login-by-email 호환 필수, Active Record Encryption은 Workers에 직접 호환 불가
- **Rollback / drift**: D1 production 환경에서 마이그 실패 시 회복 절차 미정의

### Scope

본 연구는 R1 4개 질문에 대한 결정 제시(권고 1건씩) + 코드 스케치 + CLI 명령 + 출처 인용으로 한정. 실제 schema.ts 작성은 Cycle 2(impl) 위임.

### Methodology

- **1차 출처**: `orm.drizzle.team/docs/*`, `developers.cloudflare.com/d1/*`, `guides.rubyonrails.org/active_record_encryption.html`, `api.rubyonrails.org/classes/ActiveRecord/Encryption/Cipher/Aes256Gcm.html`
- **2차 출처**: GitHub Discussions(drizzle-team), 실무 블로그(Medium/DEV/leaysgur)
- **프로젝트 측**: `server/db/schema.rb`(JSON 9 컬럼 실측), `server/app/models/user.rb:4`(encrypts 호출 실측)

---

## Q1 Findings: drizzle-kit ↔ wrangler SOT 전략

### 결론(권고)

**단일 SOT** — Drizzle을 schema source로, Wrangler를 migration runner + state tracker로 분리.

| 책임 | 도구 | 산출/상태 |
|------|------|----------|
| 1) TS Schema 정의 | `db/schema.ts` (Drizzle) | 코드 |
| 2) Schema → SQL 변환 | `drizzle-kit generate` | `drizzle/000X_*.sql` 파일 |
| 3) SQL → DB 적용 | `wrangler d1 migrations apply` | D1 변경 + `d1_migrations` 테이블 row |
| 4) 적용 이력 추적 | `wrangler d1 migrations list` | D1 내장 `d1_migrations` 테이블 (single state) |

`drizzle-kit migrate`(자체 실행기)는 D1과 함께 사용하지 **않는다**. 이유:
- D1은 binding 또는 d1-http 드라이버로만 접근 — drizzle-kit migrate는 별도 트래킹 테이블(`__drizzle_migrations`)을 만들어 **이중 추적** 발생.
- Wrangler는 `d1_migrations` 테이블을 자동 관리(D1 docs, 출처 [2]). Drizzle도 wrangler 통합 시 자체 테이블을 생성하지 않는 패턴이 community consensus(출처 [4]).

### 실측 명령

**wrangler.toml** (또는 wrangler.json):
```toml
[[d1_databases]]
binding = "DB"
database_name = "personality"
database_id = "<uuid>"
migrations_dir = "drizzle"           # Drizzle out 디렉토리를 직접 가리킴
# migrations_table = "d1_migrations" # 기본값, 변경 권고하지 않음
```

**drizzle.config.ts** (D1 binding 모드):
```ts
import { defineConfig } from 'drizzle-kit';
export default defineConfig({
  out: './drizzle',
  schema: './db/schema.ts',
  dialect: 'sqlite',                 // D1은 SQLite 호환
  // driver는 binding 사용 시 생략 가능. d1-http는 원격 schema introspection용.
});
```

**일상 워크플로우**:
```bash
# 1) Schema 변경 후 SQL 생성 (drift 검사 포함)
npx drizzle-kit generate
npx drizzle-kit check                # 충돌·일관성 검사 (출처 [10])

# 2) 로컬 D1 적용
npx wrangler d1 migrations apply personality --local

# 3) 원격 D1 적용 (CI)
npx wrangler d1 migrations apply personality --remote
```

### Trade-off

- **장점**: state 단일화, 워크플로우 짧음(generate → apply), wrangler가 production rollout · time travel 통합.
- **단점**: drizzle-kit migrate의 transactional safety(개별 migration 단위 BEGIN/COMMIT)는 wrangler에서 수동 관리 — 단, D1은 multi-statement transaction이 batch만 지원하므로 어차피 sequential apply.
- **위험**: worker 배포와 migration apply의 순서 불일치 시 schema mismatch 가능(출처 [4] 인용). 완화책 = CI에서 `wrangler d1 migrations apply --remote` → `wrangler deploy` 순서 강제.

---

## Q2 Findings: JSON 컬럼 매핑

### 9 컬럼 매핑 표 (server/db/schema.rb 기준)

| # | Table | Column | Ruby Default | Drizzle 정의 | $type<T> |
|---|-------|--------|-------------|--------------|----------|
| 1 | `alerts` | `metadata` | `{}` | `text({ mode: 'json' }).$default(() => ({})).$type<Record<string, unknown>>()` | `Record<string, unknown>` |
| 2 | `audit_logs` | `metadata` | `{}` | `text({ mode: 'json' }).$default(() => ({})).$type<AuditMetadata>()` | `AuditMetadata`(domain) |
| 3 | `personality_types` | `caution_patterns` | `[]` | `text({ mode: 'json' }).$default(() => []).$type<string[]>()` | `string[]` |
| 4 | `personality_types` | `strengths` | `[]` | `text({ mode: 'json' }).$default(() => []).$type<string[]>()` | `string[]` |
| 5 | `insights` | `suggestions` | `[]` | `text({ mode: 'json' }).$default(() => []).$type<Suggestion[]>()` | `Suggestion[]` |
| 6 | `profiles` | `caution_patterns` | `[]` | `text({ mode: 'json' }).$default(() => []).$type<string[]>()` | `string[]` |
| 7 | `profiles` | `score_vector` | `{}` | `text({ mode: 'json' }).$default(() => ({})).$type<ScoreVector>()` | `ScoreVector` (domain별 number) |
| 8 | `profiles` | `strengths` | `[]` | `text({ mode: 'json' }).$default(() => []).$type<string[]>()` | `string[]` |
| 9 | `profiles` | `suggested_actions` | `[]` | `text({ mode: 'json' }).$default(() => []).$type<SuggestedAction[]>()` | `SuggestedAction[]` |

### 핵심 결정

**`text({ mode: 'json' })` 채택 (blob 금지)**. 출처 [3]:
> "It's recommended to use `text('', { mode: 'json' })` instead of `blob('', { mode: 'json' })`"
> 이유: SQLite JSON1 함수는 BLOB 인자를 거부 — `"All JSON functions currently throw an error if any of their arguments are BLOBs"`.

`$type<T>()`는 컴파일 타임 안전성만 제공(런타임 검증 없음 — 출처 [3]). domain 객체(예: `Suggestion`, `ScoreVector`)는 별도 zod 스키마로 인입 시점 검증 권고(Cycle 3).

**Default 처리**: `$default(() => [])` 사용 — Drizzle ORM 레벨 기본값. SQL `DEFAULT '[]'`를 직접 쓰지 않는 이유는 D1 SQLite의 TEXT default literal이 JSON `[]`로 취급되지 않기 때문(출처 [9]).

### D1 JSON1 쿼리 패턴

D1은 16개 JSON 함수 지원(출처 [5]):
- 추출: `json_extract(col, '$.path')`, `col -> '$.path'`(JSON 반환), `col ->> '$.path'`(SQL 타입 반환)
- 검증: `json_valid(col)`, `json_type(col, '$.path')`
- 수정: `json_set`, `json_insert`, `json_replace`, `json_remove`, `json_patch`(RFC 7396)
- 펼치기: `json_each(col)`, `json_tree(col)`, `json_array_length(col)`

Drizzle에서 raw SQL 사용 예:
```ts
import { sql } from 'drizzle-orm';
// profiles.score_vector에서 특정 도메인 점수 추출
db.select({
  id: profiles.id,
  agreeableness: sql<number>`json_extract(${profiles.scoreVector}, '$.agreeableness')`,
}).from(profiles);
```

### JSON 인덱싱(고빈도 쿼리 시)

D1은 generated column + index를 지원(출처 [6]):
```sql
-- profiles에 자주 조회되는 type_code(이미 별도 컬럼이므로 예시는 score_vector 도메인)
ALTER TABLE profiles
ADD COLUMN agreeableness_idx
  GENERATED ALWAYS AS (json_extract(score_vector, '$.agreeableness')) VIRTUAL;
CREATE INDEX idx_profiles_agreeableness ON profiles(agreeableness_idx);
```
제약: ALTER TABLE로는 VIRTUAL만 추가 가능, STORED는 CREATE TABLE 시점에만(출처 [6]). 본 프로젝트는 9 컬럼 중 빈번 query 대상이 score_vector 정도 — Cycle 2 makeplan에서 실측 후 결정.

---

## Q3 Findings: 결정성 암호화 컬럼 패턴

### Rails 동작 분석 (출처 [7], [8])

`User.encrypts :email, deterministic: true`의 정확한 동작:
- **Cipher**: AES-256-GCM (key 32B, IV 12B, auth tag 16B)
- **IV 결정성**: `IV = HMAC-SHA256(deterministic_key, plaintext)`의 12바이트 prefix → 같은 (key, plaintext) → 같은 ciphertext
- **Key 분리**: `primary_key`(non-deterministic) ≠ `deterministic_key`(deterministic) — 두 키 별도 운영
- **Storage**: JSON envelope `{"p": base64(ciphertext), "h": {"iv": base64(iv), "at": base64(auth_tag)}}`
- **Index**: 단순 `UNIQUE INDEX(email)` — ciphertext 자체가 같으므로 동등 비교로 lookup 가능

### Workers 포팅 패턴

Web Crypto API는 AES-GCM, HMAC, PBKDF2, HKDF 모두 지원(출처 [11]). AES-SIV는 부재 — Rails 방식(HMAC IV)을 직접 재현해야 함.

**코드 스케치** (`lib/crypto/deterministic.ts` — Cycle 4 구현 대상):

```ts
// Wrangler secret으로 주입: DETERMINISTIC_KEY (32B base64), PRIMARY_KEY (32B base64)
const enc = new TextEncoder();
const dec = new TextDecoder();

async function importHmacKey(rawKey: ArrayBuffer): Promise<CryptoKey> {
  return crypto.subtle.importKey(
    'raw', rawKey, { name: 'HMAC', hash: 'SHA-256' }, false, ['sign'],
  );
}
async function importAesKey(rawKey: ArrayBuffer): Promise<CryptoKey> {
  return crypto.subtle.importKey(
    'raw', rawKey, { name: 'AES-GCM' }, false, ['encrypt', 'decrypt'],
  );
}

export async function encryptDeterministic(plaintext: string, detKey: ArrayBuffer): Promise<string> {
  // 1) IV = HMAC-SHA256(detKey, plaintext)[:12] — Rails 동등
  const hmacKey = await importHmacKey(detKey);
  const fullIv = await crypto.subtle.sign('HMAC', hmacKey, enc.encode(plaintext));
  const iv = new Uint8Array(fullIv).slice(0, 12);

  // 2) AES-256-GCM encrypt with derived IV (same key for HMAC and AES OK; Rails uses same)
  const aesKey = await importAesKey(detKey);
  const ct = await crypto.subtle.encrypt(
    { name: 'AES-GCM', iv, tagLength: 128 }, aesKey, enc.encode(plaintext),
  );
  // 3) Storage envelope: 단일 컬럼 base64. iv는 plaintext에서 재생성 가능하지만,
  //    Rails 동등성 + Phase rollback(D1↔SQLite export 변환) 위해 동일 envelope 유지.
  const ctBytes = new Uint8Array(ct);
  const data = ctBytes.slice(0, ctBytes.length - 16);
  const authTag = ctBytes.slice(ctBytes.length - 16);
  return JSON.stringify({
    p: btoa(String.fromCharCode(...data)),
    h: { iv: btoa(String.fromCharCode(...iv)), at: btoa(String.fromCharCode(...authTag)) },
  });
}

export async function decryptDeterministic(envelope: string, detKey: ArrayBuffer): Promise<string> {
  const { p, h } = JSON.parse(envelope);
  const iv = Uint8Array.from(atob(h.iv), c => c.charCodeAt(0));
  const data = Uint8Array.from(atob(p), c => c.charCodeAt(0));
  const at = Uint8Array.from(atob(h.at), c => c.charCodeAt(0));
  const ctWithTag = new Uint8Array(data.length + at.length);
  ctWithTag.set(data); ctWithTag.set(at, data.length);
  const aesKey = await importAesKey(detKey);
  const pt = await crypto.subtle.decrypt({ name: 'AES-GCM', iv, tagLength: 128 }, aesKey, ctWithTag);
  return dec.decode(pt);
}
```

### Index 전략

```ts
// db/schema.ts 발췌
export const users = sqliteTable('users', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  email: text('email').notNull(),         // ciphertext envelope (≤512B 가정)
  displayName: text('display_name'),      // non-deterministic, 별도 envelope
  passwordHash: text('password_hash'),
  createdAt: integer('created_at', { mode: 'timestamp_ms' }).notNull(),
  deletedAt: integer('deleted_at', { mode: 'timestamp_ms' }),
}, (t) => ({
  emailUq: uniqueIndex('idx_users_email_unique').on(t.email),
}));
```

login flow:
1. 사용자 입력 email(plaintext) → `encryptDeterministic(email, DET_KEY)` → 동일 envelope 산출
2. `WHERE email = :envelope` → UNIQUE index 활용 lookup → user row
3. password 검증은 BetterAuth 위임(Cycle 4)

### Trade-off / 주의

- **AES-SIV 부재**: Web Crypto는 미지원. HMAC-IV 패턴은 Rails 동등성 우선 — 표준 RFC(8452 SIV)는 아니지만 검증된 운영 패턴.
- **키 회전(C3-W3)**: deterministic_key 회전 시 모든 user.email 재암호화 필요. envelope의 `h`에 `version` 필드 추가하여 dual-read 기간 운영 권고(Cycle 4 makeplan에서 확정).
- **Phase rollback 호환(In Scope 15)**: envelope JSON 구조가 Rails ActiveRecord::Encryption::Message와 동일하므로 D1→SQLite export 시 Rails가 그대로 복호화 가능. `--no-schema` export로 데이터만 추출 후 archive Rails에 적재.
- **Length 검증**: AES-GCM IV 12B + auth tag 16B는 Rails(`AUTH_TAG_LENGTH=16`)와 일치(출처 [8]).

---

## Q4 Findings: Rollback / production drift

### Rollback 전략(2-tier)

**Tier 1 (primary): D1 Time Travel** — 출처 [12], [13]
```bash
# 마이그 직전 bookmark 확보
wrangler d1 time-travel info personality           # 현재 bookmark 출력
# … wrangler d1 migrations apply 실행 …
# 실패 시:
wrangler d1 time-travel restore personality --bookmark=<saved>
# 또는 timestamp:
wrangler d1 time-travel restore personality --timestamp=2026-04-29T12:00:00Z
```
- **보유 기간**: 30일 (Paid), 7일(Free). 본 프로젝트는 Workers Paid 가정(In Scope 1) → 30일.
- **destructive**: 복원은 in-place overwrite + 진행 중 쿼리 cancel(출처 [12]).
- **복원 후 d1_migrations 동기화**: time-travel은 d1_migrations row까지 같이 복원 → wrangler d1 migrations list가 자동으로 미적용 상태로 돌아감.

**Tier 2 (secondary): 수동 reverse SQL** — Drizzle 공식 입장(출처 [14])
> Drizzle Kit은 down migration 미지원. 권장 = 수동 reverse SQL or PITR.

본 프로젝트 절차:
1. `drizzle/000X_*.sql` 변경분 분석
2. 역방향 SQL 작성 (예: ADD COLUMN → DROP COLUMN, CREATE INDEX → DROP INDEX)
3. `wrangler d1 execute personality --remote --file=drizzle/rollback/000X_revert.sql`
4. `d1_migrations` row 수동 삭제(`DELETE FROM d1_migrations WHERE name = '000X_*'`)
- **보완**: tier 1으로 충분한 경우 tier 2 생략. 30일 초과 + 부분 rollback 필요 시 사용.

**Tier 3 (보강 — In Scope 1): R2 백업** — 주 1회 D1 export → R2
```bash
# wrangler d1 export로 SQL dump 생성
wrangler d1 export personality --remote --output=backup-$(date +%Y%m%d).sql
# R2 업로드 (별도 Workflow)
```
30일 초과 long-term 보존(Brief Constraint).

### Drift 감지

**시나리오 A: Schema ↔ migration 파일 불일치**
- 도구: `drizzle-kit check` — 다중 개발자 브랜치 충돌 감지(출처 [10]).
- CI 단계: PR open 시 `drizzle-kit generate --check`(또는 generate 후 git diff)로 schema 변경 후 generate 누락 감지.

**시나리오 B: Local D1 ↔ Remote D1 drift**
- 도구: `wrangler d1 migrations list --local` vs `--remote` diff.
- CI step:
  ```yaml
  - run: npx wrangler d1 migrations list personality --remote --json > remote.json
  - run: ls drizzle/*.sql | wc -l > local_count
  - run: |
      remote_applied=$(jq 'length' remote.json)
      [ "$remote_applied" -le "$(cat local_count)" ] || exit 1
  ```

**시나리오 C: Schema ↔ DB drift(외부 변경)**
- 도구: `drizzle-kit pull` — 원격 schema introspect 후 schema.ts와 비교.
- 운영 가드: D1 콘솔/wrangler execute로 DDL 직접 변경 **금지** runbook 명시(In Scope 13, 19).

### 권고 절차 (production migration)

```
[1] 로컬 검증
    drizzle-kit generate
    drizzle-kit check
    wrangler d1 migrations apply personality --local
    pnpm test (vitest-pool-workers)
[2] CI 검증 (PR)
    drizzle-kit check (실패 시 block)
    wrangler d1 migrations apply <preview-db> --remote
[3] Production
    wrangler d1 time-travel info personality > bookmark.txt   # PITR anchor
    wrangler d1 migrations apply personality --remote
    wrangler deploy                                           # 순서 강제
[4] 실패 시
    wrangler d1 time-travel restore personality --bookmark=<bookmark.txt>
    wrangler rollback                                         # worker도 회귀
```

---

## Cross-Analysis (Q1–Q4 일관성)

| 결정 축 | Q1 SOT | Q2 JSON | Q3 결정성 | Q4 Rollback |
|---------|--------|---------|----------|-------------|
| **State 단일성** | wrangler d1_migrations 테이블 단일 | `text({ mode: 'json' })` 단일 표현 | envelope JSON 단일 형식(Rails 동등) | Time Travel이 d1_migrations까지 같이 복원 |
| **Rails 호환** | drizzle SQL ≈ AR migration SQL | TEXT JSON ≈ Rails t.json (SQLite) | envelope = AR::Encryption::Message JSON | export SQL이 Rails db:seed/load 호환 |
| **Workers 호환** | binding 사용, HTTP 드라이버 부수적 | JSON1 함수가 D1에서 직접 동작 | Web Crypto AES-GCM + HMAC 1차 지원 | wrangler가 워커 단위 일관 처리 |
| **Cycle 의존** | Cycle 1·2 | Cycle 2 | Cycle 4(Auth) | Cycle 1·9 (Cutover Safety) |

**일관성 검증**: 4개 결정 모두 "Wrangler/D1 1차 + Drizzle 보조" 원칙 일관. Drizzle은 schema·query 표현에만 책임. Migration runner / state / backup / rollback 전부 Wrangler 영역. 이 분리가 In Scope 15(Phase rollback)의 D1↔SQLite 변환 가능성을 보존.

---

## Comprehensive Conclusion

priority-ordered findings:

| ID | Finding | Severity | 근거 |
|----|---------|----------|------|
| **R1-F1** | **SOT = Drizzle(schema) + Wrangler(runner) 단일 추적**. drizzle-kit migrate는 D1과 함께 사용 금지. wrangler.toml `migrations_dir = "drizzle"` 설정으로 단일 경로 통합. | Critical | 출처 [1][2][4] |
| **R1-F2** | **9 JSON 컬럼 모두 `text({ mode: 'json' }).$default(() => default).$type<T>()`** — blob mode 금지(JSON1 함수 BLOB 거부). 도메인 타입은 별도 zod 스키마로 인입 검증. | Critical | 출처 [3][5] schema.rb 14:204 |
| **R1-F3** | **결정성 email 컬럼 = AES-256-GCM + HMAC-SHA256(detKey, plaintext)[:12] IV** + envelope `{p, h:{iv, at}}` JSON. UNIQUE INDEX(email) 단순 적용 — ciphertext 자체가 결정적. Rails Active Record Encryption과 wire-compatible → Phase rollback 가능. | Critical | 출처 [7][8][11] user.rb:4 |
| **R1-F4** | **Rollback 2-tier**: D1 Time Travel 30일(primary, in-place restore) + 수동 reverse SQL(secondary). R2 export 주 1회로 30일 초과 보존(Brief In Scope 1·13). | Critical | 출처 [12][13][14] |
| **R1-F5** | **Drift 감지 3채널**: drizzle-kit check(파일 일관성) + wrangler d1 migrations list 비교(local vs remote) + drizzle-kit pull(외부 DDL 감지). CI 통합. | Major | 출처 [10][15] |
| **R1-F6** | **CI 순서 강제**: `wrangler d1 migrations apply --remote` → `wrangler deploy`. 역순 시 worker code ↔ schema mismatch 발생(D1은 zero-downtime 미지원). | Major | 출처 [4] |
| **R1-F7** | **JSON 인덱싱은 generated column + 별도 INDEX**. `score_vector.<domain>` 빈번 쿼리 시만 적용(Cycle 2 makeplan에서 실측 결정). ALTER TABLE은 VIRTUAL만 추가 가능, STORED는 CREATE 시점에만. | Medium | 출처 [6] |
| **R1-F8** | **Key rotation 패턴**: envelope `h.version` 필드 추가하여 dual-read. deterministic_key 회전 시 모든 user.email 재암호화 → Cycle 4에서 마이그레이션 스크립트 작성. | Medium | C3-W3 (Brief Constraint) |
| **R1-F9** | **D1 production tier 강제**: Time Travel 30일 보유는 Paid + version: production 필요. `wrangler d1 info personality` 로 확인. | Medium | 출처 [12] |

---

## Open Questions

1. **JSON 컬럼 `default()` SQL emit 거동**: `$default(() => [])`는 ORM 레벨 — INSERT 시 대입. SQL DDL의 `DEFAULT '[]'` 자동 emit 여부는 drizzle-kit 버전별 차이 — Cycle 2 impl에서 generated SQL 실측.
2. **deterministic_key vs primary_key 동일 사용**: 본 스케치는 단순화 위해 동일 키 가정. Rails는 별도 키. 운영 단계에서 Wrangler secret 2개로 분리(`DET_KEY`, `PRIMARY_KEY`) 권고 — Cycle 4 확정.
3. **Time Travel + 마이그 atomicity**: 다중 statement 마이그가 부분 실패 시, time-travel restore가 정확히 pre-migration bookmark로 복원되는지 — 실측 권고(Cycle 9 archive smoke test 포함).
4. **9개 외 잠재 JSON 후보**: `responses.value`(integer)는 Likert 척도 — JSON 불필요. `assessments.completion_rate` 등 float — JSON 외. 9 컬럼 외 추가 JSON 없음 확인.
5. **drizzle-kit check D1 dialect 지원도**: SQLite dialect 일반 적용 — D1 특이 케이스(JSON1 generated column)에 대한 검사 한계는 pull 도구 보완.

---

## References

| # | Source | URL / Path | Relevance |
|---|--------|-----------|-----------|
| [1] | Drizzle: Get Started with D1 | https://orm.drizzle.team/docs/get-started/d1-new | drizzle.config.ts d1-http driver |
| [2] | Cloudflare: D1 Migrations | https://developers.cloudflare.com/d1/reference/migrations/ | `d1_migrations` 테이블, PRAGMA defer_foreign_keys |
| [3] | Drizzle: SQLite Column Types | https://orm.drizzle.team/docs/column-types/sqlite | text/blob mode json, $type<T>() |
| [4] | GitHub: How to run Drizzle migrations on D1 | https://github.com/drizzle-team/drizzle-orm/discussions/1388 | community SOT consensus + sync risk |
| [5] | Cloudflare: Query JSON | https://developers.cloudflare.com/d1/sql-api/query-json/ | JSON1 함수 16개 목록 |
| [6] | Cloudflare: Generated Columns | https://developers.cloudflare.com/d1/reference/generated-columns/ | VIRTUAL/STORED, JSON path index |
| [7] | Rails Guides: Active Record Encryption | https://guides.rubyonrails.org/active_record_encryption.html | deterministic IV = HMAC-SHA256(key, plaintext) |
| [8] | Rails API: Aes256Gcm | https://api.rubyonrails.org/classes/ActiveRecord/Encryption/Cipher/Aes256Gcm.html | KEY/IV/AUTH_TAG length |
| [9] | Drizzle JSON 패턴 (leaysgur) | https://leaysgur.github.io/posts/2024/03/06/102549/ | text mode json + sql helper 실측 |
| [10] | Drizzle: drizzle-kit check | https://orm.drizzle.team/docs/drizzle-kit-check | 일관성 검사 명령 |
| [11] | Cloudflare: Web Crypto | https://developers.cloudflare.com/workers/runtime-apis/web-crypto/ | AES-GCM, HMAC, PBKDF2 지원 |
| [12] | Cloudflare: Time Travel | https://developers.cloudflare.com/d1/reference/time-travel/ | bookmark, 30일, restore |
| [13] | Cloudflare: Wrangler D1 Commands | https://developers.cloudflare.com/d1/wrangler-commands/ | migrations/time-travel/export 전체 명령 |
| [14] | GitHub: Migrations Rollback | https://github.com/drizzle-team/drizzle-orm/discussions/1339 | down migration 미지원, manual reverse |
| [15] | Drizzle: Cloudflare D1 connector | https://orm.drizzle.team/docs/connect-cloudflare-d1 | wrangler.json migrations_dir 설정 |
| — | 프로젝트 schema | `/Users/kampikrein/A/personality/server/db/schema.rb:14-204` | JSON 9 컬럼 실측 |
| — | 프로젝트 user 모델 | `/Users/kampikrein/A/personality/server/app/models/user.rb:4` | `encrypts :email, deterministic: true` 실측 |
| — | Brief 결정 | `/Users/kampikrein/A/personality/docs/6_backend/02_cf_workers_rebuild/001_Brief_cf_workers_rebuild.md` Decision 3, In Scope 3·6, Constraint C3-W3 | 통합 패턴 위임 근거 |
| — | Scope R1 정의 | `/Users/kampikrein/A/personality/docs/6_backend/02_cf_workers_rebuild/007_Scope_cf_workers_rebuild.md` Cycle 2, R1 axis | 본 연구 범위 |

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
