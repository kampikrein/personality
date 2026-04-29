# Secret Rotation Runbook

Cloudflare Workers 7개 secret의 parallel-key rotation 절차.
R4-F3 패턴 인용 (Brief 001/021 Research R4, Synthesis 018).

> Phase 1에서는 실 secret 등록 없음 — 절차 문서화만.
> Phase 2 cutover 시 이 runbook을 따라 초기 secret을 등록하고, 이후 회전 시 재사용.

---

## Secret 목록

| # | Secret Name | 용도 | 생성 방식 | 회전 주기 |
|---|-------------|------|----------|----------|
| 1 | `PERSONALITY_ENCRYPTION_KEY` | AES-256-GCM 결정성 암호화 (User.email) | `openssl rand -base64 32` | 12개월 |
| 2 | `PERSONALITY_ENCRYPTION_KEY_OLD` | parallel-key rotation Phase 1~5 read-fallback | 회전 시점에만 set | per-rotation |
| 3 | `BETTERAUTH_SECRET` | BetterAuth session JWT HMAC signing | `openssl rand -base64 32` | 12개월 |
| 4 | `JWT_SECRET` | 모바일 Bearer JWT 서명 (Cycle 4) | `openssl rand -base64 32` | 12개월 |
| 5 | `TOSS_SECRET_KEY` | Toss Payments 서버 키 | Toss 가맹점 콘솔 발급 | Toss 정책 |
| 6 | `TOSS_WEBHOOK_SECRET` | Toss webhook 서명 검증 (Model A: secret 비교) | Toss 가맹점 콘솔 발급 | Toss 정책 |
| 7 | `CF_ACCESS_AUD` | CF Access JWT audience tag (admin) | CF Access Application 발급 | application 변경 시 |

---

## 초기 등록 (Phase 2 cutover)

```bash
cd apps/workers

# secret 값 생성 (PERSONALITY_ENCRYPTION_KEY, BETTERAUTH_SECRET, JWT_SECRET)
openssl rand -base64 32   # 각 키마다 별도 실행

# production 등록
for KEY in PERSONALITY_ENCRYPTION_KEY BETTERAUTH_SECRET JWT_SECRET TOSS_SECRET_KEY TOSS_WEBHOOK_SECRET CF_ACCESS_AUD; do
  wrangler secret put $KEY --env production
done

# staging 등록
for KEY in PERSONALITY_ENCRYPTION_KEY BETTERAUTH_SECRET JWT_SECRET TOSS_SECRET_KEY TOSS_WEBHOOK_SECRET CF_ACCESS_AUD; do
  wrangler secret put $KEY --env staging
done

# 확인
wrangler secret list --env production
wrangler secret list --env staging
```

---

## R2 Sealed 백업

`age`(<https://age-encryption.org/>) 를 사용한 암호화 백업.

```bash
# 1회: 운영자 age key 생성
age-keygen -o ~/.config/age/personality-recovery.txt
# 출력: public key "age1xyz..." → 1Password에 반드시 저장

# 각 secret 값 sealed 백업 (회전 시 함께 갱신)
PUBKEY="age1xyz..."
echo "$SECRET_VALUE" | age -e -r $PUBKEY > /tmp/key_v1.age
wrangler r2 object put personality-secrets/PERSONALITY_ENCRYPTION_KEY/v1.age \
  --file=/tmp/key_v1.age --env production
rm /tmp/key_v1.age   # 평문 즉시 삭제
```

---

## PERSONALITY_ENCRYPTION_KEY 회전 (parallel-key 패턴)

### Phase 0 — 정상 운영

```
PERSONALITY_ENCRYPTION_KEY     = K_n   (write + read)
PERSONALITY_ENCRYPTION_KEY_OLD = (unset)
```

### Phase 1 — 새 키 생성 + dual-read 활성화

```bash
openssl rand -base64 32 > /tmp/K_new.txt

# K_n을 OLD에 보존
wrangler secret put PERSONALITY_ENCRYPTION_KEY_OLD --env production
# 프롬프트에 현재 K_n 값 입력

# K_new를 현재 키로 등록
wrangler secret put PERSONALITY_ENCRYPTION_KEY --env production
# 프롬프트에 /tmp/K_new.txt 내용 입력

rm /tmp/K_new.txt   # 평문 즉시 삭제
```

Worker 코드 (Cycle 4 `lib/auth/encryption.ts`) 동작:
- encrypt: K_new 사용
- decrypt: K_new 시도 → fallback K_old

### Phase 2 — 기존 ciphertext 재암호화

```bash
# 옵션 A (lazy): 사용자 next-login 시 자동 재암호화
# 옵션 B (batch): Cron Trigger 기반 1000 row/batch

# 진행 확인 — encryption_version이 구버전인 row 수
wrangler d1 execute personality-d1-prod --env production --command \
  "SELECT count(*) FROM users WHERE encryption_version = (현재_버전)"
# 0이 될 때까지 대기
```

### Phase 3 — 검증

```bash
wrangler d1 execute personality-d1-prod --env production --command \
  "SELECT count(*) FROM users WHERE encryption_version != (신버전)"
# 결과 = 0 이어야 Phase 4 진행
```

### Phase 4 — R2 sealed 백업 갱신

```bash
PUBKEY="age1xyz..."
echo "$K_NEW_VALUE" | age -e -r $PUBKEY > /tmp/key_v$(n+1).age
wrangler r2 object put personality-secrets/PERSONALITY_ENCRYPTION_KEY/v$(n+1).age \
  --file=/tmp/key_v$(n+1).age --env production
rm /tmp/key_v$(n+1).age
```

### Phase 5 — K_n 폐기

```bash
wrangler secret delete PERSONALITY_ENCRYPTION_KEY_OLD --env production
# K_n은 R2 sealed v_n.age에만 잔존 (포렌식·미회전 row 복구용)
```

### 1Password 갱신

vault entry "personality CF secrets":
- 새 K_{n+1} 값 갱신
- 갱신 일자 기록
- R2 object key (`personality-secrets/PERSONALITY_ENCRYPTION_KEY/v{n+1}.age`) 기록

---

## 기타 secret 회전

`BETTERAUTH_SECRET`, `JWT_SECRET`: 새 값 생성 후 `wrangler secret put`으로 교체.
세션 무효화 없이 교체 불가 — 운영 창(maintenance window) 설정 권장.

`TOSS_SECRET_KEY`, `TOSS_WEBHOOK_SECRET`: Toss 가맹점 콘솔에서 재발급 후 `wrangler secret put`.

`CF_ACCESS_AUD`: CF Access Application 재생성 시에만 변경.
