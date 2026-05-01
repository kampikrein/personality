---
id: "013"
type: eval
title: "Eval R1 — Drizzle + D1"
created: 2026-04-29
traces_research: "008"
verdict: sufficient
k_score: 3
c_score: 3
depth_score: 6
cycle: 1
phase: research
---

# Eval R1 — Drizzle ORM + D1 통합 패턴

## Verdict + Depth Score

**SUFFICIENT** | Depth Score: **6/6** (K:3 C:3)

4개 핵심 질문 전부 명확한 결정으로 답변됐으며, 15개 1차·커뮤니티 출처를 갖춘다. 미해결
항목은 모두 impl 사이클로 적절히 위임됐다. Cycle 2(DB Layer) 진행에 충분한 지식 기반.

---

## Q1–Q4 Coverage Analysis

### Q1: drizzle-kit ↔ wrangler SOT 전략

**답변됨 (K:3).** 단일 SOT — Drizzle(schema 정의) + Wrangler(migration runner + state 추적) 분리가
명확히 결정됐다. `drizzle-kit migrate` D1 혼용 시 이중 추적 문제(`__drizzle_migrations` vs
`d1_migrations`)를 구체적으로 설명하고, `wrangler.toml migrations_dir = "drizzle"` 설정 코드를
제공한다. 일상 워크플로우(generate → check → apply local → apply remote) 및 CI 순서 강제
(`apply --remote` → `deploy`) 까지 포함. 미결 사항 없음.

### Q2: JSON 컬럼 9개 D1 JSON1 매핑

**답변됨 (K:3).** `server/db/schema.rb`를 직접 실측해 9개 컬럼을 테이블/컬럼/기본값 단위로
매핑했다. `text({ mode: 'json' })` 선택 근거(JSON1 함수의 BLOB 거부)가 1차 출처로 입증됐다.
JSON1 16개 함수 목록, generated column 인덱싱 제약(ALTER TABLE은 VIRTUAL만), `$type<T>()` 런타임
검증 한계 + zod 보완 권고까지 포함. 완전 답변.

### Q3: 결정성 암호화 컬럼 패턴 (User.encrypts deterministic)

**답변됨 (K:3).** Rails ActiveRecord::Encryption의 정확한 동작(AES-256-GCM + HMAC-SHA256 IV
12바이트)이 Rails 공식 docs + API 레퍼런스 2개로 근거됐다. Web Crypto 포팅 코드 스케치
(`lib/crypto/deterministic.ts`)가 AES-GCM + HMAC 흐름을 구현하며, Rails envelope JSON
구조(`{p, h:{iv, at}}`)와의 wire-compatibility를 확인한다. UNIQUE INDEX 전략, login flow, Phase
rollback 호환성까지 망라. AES-SIV 부재 한계도 명시. 미결 사항은 Cycle 4 impl 위임으로 적절.

### Q4: 마이그레이션 Rollback / Production Drift 감지

**답변됨 (K:3).** 2-tier rollback(Time Travel primary + reverse SQL secondary) + R2 export(장기
보존 tier 3)가 CLI 명령과 함께 제시됐다. Drift 감지 3채널(drizzle-kit check, wrangler list
비교, drizzle-kit pull)과 CI YAML 단편도 포함. Time Travel 30일 한도가 Paid tier 전제임을 명시
(R1-F9). Production migration 절차(bookmark → apply → deploy → restore 시나리오)가 단계별로
정리됐다. 완전 답변.

---

## Source Quality

**1차 출처 인용: 15개 (기준 ≥5 충족)**

| # | 분류 | 출처 | 평가 |
|---|------|------|------|
| [1] | 1차 공식 | Drizzle: Get Started with D1 | D1 연동 시작점, 적합 |
| [2] | 1차 공식 | Cloudflare: D1 Migrations | d1_migrations 테이블, 핵심 |
| [3] | 1차 공식 | Drizzle: SQLite Column Types | text/blob mode json, 핵심 |
| [4] | 커뮤니티 | GitHub Discussions drizzle-orm/1388 | SOT 패턴 커뮤니티 consensus |
| [5] | 1차 공식 | Cloudflare: Query JSON | JSON1 16개 함수 목록 |
| [6] | 1차 공식 | Cloudflare: Generated Columns | VIRTUAL/STORED 제약 |
| [7] | 1차 공식 | Rails Guides: AR Encryption | deterministic IV 근거 |
| [8] | 1차 공식 | Rails API: Aes256Gcm | KEY/IV/AUTH_TAG 길이 근거 |
| [9] | 2차 블로그 | leaysgur text mode json 실측 | DEFAULT '[]' SQL emit 보완 |
| [10] | 1차 공식 | Drizzle: drizzle-kit check | 일관성 검사 명령 |
| [11] | 1차 공식 | Cloudflare: Web Crypto | AES-GCM HMAC 지원 확인 |
| [12] | 1차 공식 | Cloudflare: Time Travel | bookmark 30일 복원 |
| [13] | 1차 공식 | Cloudflare: Wrangler D1 Commands | wrangler 전체 명령 |
| [14] | 커뮤니티 | GitHub drizzle-orm/1339 | down migration 미지원 확인 |
| [15] | 1차 공식 | Drizzle: Cloudflare D1 connector | migrations_dir 설정 |

1차 공식 출처 11개, 커뮤니티 출처 2개, 2차 블로그 1개, 프로젝트 실측 2건. 품질 양호.
커뮤니티 출처([4][14])가 1차로 확인되지 않는 SOT 패턴 및 rollback 미지원을 보완하는 역할로
적절히 사용됐다.

---

## Recommended Changes

```yaml
recommended_changes: []
# SUFFICIENT — 추가 조치 없음. Cycle 2 DB Layer로 진행.
```

---

## Cross-Axis Observations

### R1 → R2 (D1 saga/Durable Object) 영향

- Q4에서 확인된 **D1 multi-statement transaction = batch만 지원** 사실이 R2 saga 결정에 직접
  연결된다. D1 batch atomicity 범위를 R2 연구에서 Q1로 재검증할 필요.
- Time Travel이 `d1_migrations` 행까지 일괄 복원한다는 점은 saga compensate 실패 후 복원
  경로에도 관련 — R2 연구에서 "saga 실패 시 Time Travel 활용 가능성"을 Q3/Q4에 포함 권고.

### R1 → R4 (BetterAuth + CF Access) 영향

- Q3의 결정성 암호화(`deterministic_key` 분리, envelope version 필드, dual-read 패턴)가
  Cycle 4에서 BetterAuth와 통합될 때 Key 관리 인터페이스 설계에 선행 제약이 된다.
  R4 연구는 BetterAuth의 custom field provider / before-create hook 지원 여부를 확인해야
  `encryptDeterministic`을 어디에 끼울지 결정 가능.
- Cycle 4 makeplan이 R1-F8(rotation envelope versioning)과 R4 결과를 동시에 참조해야 한다.

### Schema 결정이 모든 하위 사이클에 미치는 영향

- 9개 JSON 컬럼 매핑 표와 users 테이블 스키마 스케치가 Cycle 2(DB Layer)에서 직접 사용 가능한
  수준으로 완성됐다. Cycle 3(Domain Services)의 `ScoreVector`, `Suggestion` 등 도메인 타입도
  Q2에서 식별됐으므로 zod 스키마 설계 시 출발점 확보.

---

## Findings Preserved

| ID | Finding | 심각도 | Cycle 사용처 |
|----|---------|--------|-------------|
| **R1-F1** | SOT = Drizzle(schema) + Wrangler(runner) 단일 추적. drizzle-kit migrate D1 혼용 금지. | Critical | Cycle 2 makeplan |
| **R1-F2** | 9 JSON 컬럼 모두 `text({ mode: 'json' }).$type<T>()`. blob mode 금지. 도메인 타입은 zod 검증. | Critical | Cycle 2 |
| **R1-F3** | 결정성 email = AES-256-GCM + HMAC-SHA256 IV + envelope JSON. UNIQUE INDEX. Rails wire-compatible. | Critical | Cycle 4 |
| **R1-F4** | Rollback 2-tier: Time Travel 30일(primary) + reverse SQL(secondary). R2 export 장기 보존. | Critical | Cycle 1, 9 |
| **R1-F5** | Drift 감지 3채널: drizzle-kit check + wrangler list 비교 + drizzle-kit pull. CI 통합. | Major | Cycle 1 CI, Cycle 2 |
| **R1-F6** | CI 순서 강제: `apply --remote` → `deploy`. 역순 = schema mismatch. | Major | Cycle 1 CI |
| **R1-F7** | JSON 인덱싱 = generated column + 별도 INDEX. ALTER TABLE은 VIRTUAL만. Cycle 2에서 실측 결정. | Medium | Cycle 2 makeplan |
| **R1-F8** | Key rotation: envelope `h.version` 추가 + dual-read. 전체 user.email 재암호화 스크립트 필요. | Medium | Cycle 4 |
| **R1-F9** | Time Travel 30일은 Paid + production tier 전제. `wrangler d1 info`로 확인 필수. | Medium | Cycle 1 |

---

## Terminal Output

```
== Eval: Research Cycle 1 Complete ==
Depth Score: 6/6 (K:3 C:3)
Critical gate: PASS
Verdict: SUFFICIENT
Findings: D:0 C:0 A:0 S:0 (0건) — all questions directly answered
Document: /Users/kampikrein/A/personality/docs/6_backend/02_cf_workers_rebuild/013_Eval_R1.md
```
