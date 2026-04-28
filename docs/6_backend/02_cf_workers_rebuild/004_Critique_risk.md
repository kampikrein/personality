---
id: "004"
type: critique
title: "Brief Critique — Risk Analysis (리스크)"
created: 2026-04-28
status: completed
perspective: "risk"
target: "001"
confidence: high
model: "opus"
reasoning_depth: "deep"
summary: >
  Brief 001은 13 R-risks를 "수용 명시" 형태로 다루지만 구체적 mitigation이
  부재한 영역이 다수. cutover safety는 phase 정의는 있으나 phase 간 rollback
  절차·비가역 시점·transition window 일관성 모델 미정의. archive 활성화
  실효성은 6개월 후 검증되지 않으면 종이 안전망. 보안(secrets rotation,
  rate limit, WAF, admin auth 분리), 법적(국외 이전 동의 UX, 14세 미만,
  약관 신규 작성), 운영(1인 부재, 결제 PG outage, D1 백업), 데이터(암호화 키
  관리, encryption rotation) 영역에 critical/major gap 8개 도출. 가정
  monitoring 5개는 트리거·재평가 비용·responsible party 미정의로 종이 약속.
  Brief 갱신 대신 scope에서 구체화 가능한 항목 vs Brief Constraints/Decision에
  추가 필요한 항목 분리 권고.
keywords: [critique, brief, risk, cutover-safety, security, compliance, gdpr, operational]
---

# Brief Critique — Risk Analysis

## Executive Summary

Brief 001은 본 연구 010의 13개 R-risks를 명시적으로 "수용"하고, Cutover Safety를 Priority Dimension에 추가했다. 그러나 **수용**과 **mitigation 정의**는 다른 일이다. 본 비평은 다음을 발견했다:

1. **Critical gaps (3건)**: ① archive 활성화 실효성 미검증(6개월 후 Ruby 버전·gem 호환성·Solid* 미사용 자산이 부패하면 archive는 종이 안전망), ② phase 간 rollback 절차 부재(Phase A 가동 후 모바일 사용자가 새 API 의존 시작 시 비가역성), ③ User.encrypts AES-GCM 수동 구현의 키 관리·rotation 전략 부재(키 분실 시 모든 사용자 lookup 불가, 단일 실패점).

2. **Major gaps (5건)**: ④ secrets rotation·접근 통제 미정의, ⑤ rate limiting·WAF 누락(비용 폭증·DDoS), ⑥ 개인정보 국외 이전 동의 UX·14세 미만 처리·약관 신규 작성이 In Scope 미명시, ⑦ D1 백업·복원 절차 부재(R2/R11 mitigation 누락), ⑧ 1인 개발자 부재 시(R10 강조됐으나) 운영 playbook·on-call·CF 계정 복수 인증·결제 카드 만료 등 비상 절차 부재.

3. **Minor gaps (4건)**: ⑨ Toss webhook 재시도 폭증 시 처리, ⑩ 마이그 진행 중 Rails 신규 기능 동결 명시, ⑪ 30.5 MW 50%+ 초과 대응 정책, ⑫ 가정 monitoring 5개 트리거·responsible party·재평가 비용 미정의.

4. **연구 010의 13 R-risks 매핑**: Brief가 "수용 명시"한 7개(R1, R2, R3, R5, R7, R11, R12)는 본질적으로 "장기 지표 모니터링" 외 추가 mitigation 부재. R4, R6, R8, R9, R10, R13는 Brief Constraints에 직접 다뤄지지 않음. 매핑 표는 §G 참조.

5. **권고**: Brief 갱신 시 ① archive 활성화 검증 절차(6·12개월 시점에 실제로 Rails를 켜보는 dry-run), ② D1 백업·키 관리 Constraint 추가, ③ 보안 baseline(rate limit, WAF, secrets rotation, admin auth 분리) Decision 신설, ④ 개인정보 컴플라이언스 In Scope 항목 추가(consent/deletion_request 동등 구현), ⑤ 가정 monitoring 5개에 트리거·responsible party·재평가 비용 정의 추가. 일부는 Brief가 아닌 scope/plan 단계로 위임 가능 — 분류 표는 §Recommendations 참조.

## Findings

### Strengths

1. **Cutover Safety를 Priority Dimension에 명시 추가** (Robustness 1단계 상향). Brief가 cutover 위험을 의식했다는 신호.
2. **Decision 9 (단계적 cutover 3 phase) + Decision 10 (archive 보존) + Decision 11 (Production/Preview/Staging 환경 분리)** — cutover 안전망 의도가 일관됨.
3. **결제 idempotency (D1 UNIQUE event_id) 명시** (Decision 5). Toss webhook 재시도 7회·총 3일 19시간 대응의 첫 단계.
4. **개인정보 처리방침 고지 + D1 jurisdiction 활용 가능성**이 본 연구 P5 R13 mitigation에 정리됨. Brief가 직접 다루진 않지만 traces로 연결.
5. **벤더 락인 Constraint에 "데이터 portability(D1 → SQLite export) 백업 차원 유지" 명시** (Anchor 15). R6의 부분 mitigation.
6. **archive git 이력 유지 + 6개월 이상 유지 + 삭제 금지 강제** — 회귀 비상구의 의도는 명확.

### Weaknesses

| # | Finding | Severity | Evidence | Recommendation |
|---|---------|----------|----------|----------------|
| W1 | archive 활성화 실효성 미검증 — Ruby 버전·gem·SQLite·Solid* 호환성이 6~12개월 후 깨질 위험 | **Critical** | Anchor 8 "6개월 이상 유지"는 보존 기간만 명시. 6개월 후 archive를 켰을 때 작동하는지 검증 절차 부재. Ruby 보안 패치·gem dependency·SQLite 버전 drift 가능 | Brief에 "분기별 archive smoke test" Constraint 추가 또는 scope에서 dry-run 절차 정의 |
| W2 | Phase 간 rollback 절차·비가역 시점 미정의 | **Critical** | Anchor 7 "각 단계 완료 후 검증 통과 시 다음 단계" — forward 흐름만 정의. Phase A 가동 후 Flutter 사용자가 새 API에 의존 시작하면 회귀 시 사용자 영향 발생 | Brief에 "각 phase의 rollback trigger·절차·사용자 영향 범위" 명시 (또는 scope에 위임) |
| W3 | User.encrypts AES-GCM 수동 구현의 키 관리·rotation 전략 부재 | **Critical** | Decision 6 "Web Crypto API AES-GCM 수동 구현(login-by-email 호환)"은 알고리즘만 정의. 키 저장 위치·rotation 정책·키 분실 시 복구 절차 부재. deterministic IV 키 분실 = 모든 user lookup 불가 (단일 실패점) | Brief Constraints에 "암호화 키 KV/wrangler secret 분리 저장 + 분기 rotation 절차 정의" 추가 |
| W4 | secrets rotation·접근 통제·복구 절차 미정의 | Major | Decision 1 "secrets 관리"만 언급, rotation 정책·다중 계정 backup·CF 계정 침해 시 절차 부재 | scope에서 secrets baseline 정의: rotation 주기, KV vs wrangler secret 사용 기준, CF 계정 2FA + recovery codes |
| W5 | Rate limiting·WAF 부재 시 비용 폭증·DDoS 위험 | Major | In Scope 13항목에 rate limiting·WAF 명시 없음. CF 무료 WAF 활성화도 미정의. webhook endpoint·login endpoint가 무방비면 자동화 공격 시 D1 write 단가($1/M) 누적 가능 | Brief In Scope에 "보안 baseline (rate limit, WAF, CSRF, Origin 검증)" 항목 추가 |
| W6 | 개인정보 컴플라이언스 In Scope 미명시 (consent, deletion_request, audit_log 동등 구현) | Major | 현 Rails는 `consent.rb`, `deletion_request.rb` (SLA 7일 + status 추적), `audit_log.rb` 모델로 컴플라이언스 흐름 보유. Brief In Scope #3 "14 테이블 → Drizzle schema"에 묻혀있음 — 동작 동등성·국외 이전 동의 UX 미명시 | In Scope에 "컴플라이언스 흐름(consent grant/revoke, deletion SLA 7일, audit_log) 동등 구현" 별도 항목 |
| W7 | D1 백업·복원 절차 부재 | Major | Constraints "D1 → SQLite export 백업 차원 유지" 1줄. 백업 빈도·저장 위치·복원 검증 RPO/RTO 미정의. D1 corruption 시나리오에서 archive Rails로 복귀하려면 D1 데이터를 SQLite로 변환해야 하는데 schema·encryption 호환 미보장 | scope에서 "주간 D1 export → R2 저장 + 분기 복원 dry-run" 정의 |
| W8 | 1인 개발자 부재 시 운영 playbook 부재 | Major | R10 "단일 개발자 유지 부담"을 수용 명시하지만, 휴가·질병·이탈 시 누가 wrangler secret·CF 계정·결제 PG 계정에 접근하는지 미정의. CF 계정 정지·해킹 시 단일 vendor 의존이 전체 서비스 다운 | Brief Constraints에 "CF 계정 복수 admin + 결제 PG 계정 복수 owner + secrets 백업 위치" 명시 |
| W9 | Toss webhook 재시도 폭증 + signature 검증 실패 시 처리 미정의 | Minor | Toss 재시도 7회·총 3일 19시간(P3 B). signature 실패 시 4xx 반환 정책·alerting·dead letter queue 미정의 | scope에서 webhook 처리 baseline 정의 |
| W10 | 마이그 진행 중 Rails 신규 기능 동결 정책 미명시 | Minor | 마이그 30.5 MW 동안 Rails 기능 추가 시 양쪽 구현 부담. 비즈니스 압박 vs 마이그 일정의 trade-off 미정의 | Brief Constraints에 "마이그 진행 중 새 도메인 기능 동결" 추가 (Out of Scope #6은 미세하게 다른 함의) |
| W11 | 30.5 MW 50%+ 초과 시 대응 정책 부재 | Minor | Decision 1 "Partial 대비 +16 MW 일회성"만 언급. 실제 50% 초과(45+ MW) 도달 시 Stay/Partial 회귀 결정 트리거 미정의 | Critical Review Request에 "비용 초과 트리거" 항목 추가 |
| W12 | 가정 monitoring 5개 트리거·responsible party·재평가 비용 미정의 | Minor | "6개월·12개월 retrospective 권장" — 자동 알림인지·캘린더인지·누가 책임지는지 미정의. 가정 깨졌을 때 회귀 비용도 추정 없음 | Brief에 "monitoring 자동화 메커니즘 (캘린더 + scheduled cron + checklist)" 추가 |

### Missing Elements

| # | What's Missing | Why It Matters | Suggestion |
|---|----------------|----------------|------------|
| M1 | Admin과 user 인증 분리 정책 | `admin.<도메인>` 라우트가 동일 cookie domain 공유 시 escalation 위험. admin auth bypass 발견 시 user 데이터 전체 노출 | Brief Decision 12 "도메인 구조"에 "admin 별도 인증 + IP allowlist 또는 OAuth 강제" 추가 |
| M2 | CSRF token·SameSite cookie·Origin 검증 baseline | Hono SSR admin이 form submit 처리 시 Rails ActionController::Base의 CSRF 보호와 동등 보장 안 되면 CSRF 공격 가능 | scope에서 보안 baseline 명시 |
| M3 | 14세 미만 사용자 처리 정책 | 성격 검사 서비스의 어린이 사용 가능성. 한국 개인정보보호법 + GDPR-K 모두 14세(또는 16세) 미만 처리 별도 동의 요구 | Brief에 "연령 게이트 + 보호자 동의" 항목 추가 또는 Out of Scope로 명시 |
| M4 | 약관·개인정보 처리방침 신규 작성 명시 | Rails의 consent_text_snapshot은 이전 버전 추적용. 새 스택에서 약관 신규 작성·법무 검토·기존 consent migration 절차 미정의 | scope에서 "약관 v1 작성 + 기존 consent_version 호환" 정의 |
| M5 | D1 또는 Workers의 region failure 시 동작 | R11(CF outage) 수용했으나 region별 fallback·degraded mode·status page 운영 미정의 | scope에서 "outage 시 사용자 메시지 + 재시도 정책" 정의 |
| M6 | 결제 PG (Toss) outage 시 사용자 경험 | Toss outage 시 결제 흐름 차단·queued retry·사용자 fallback 메시지 미정의 | scope에서 "결제 outage 처리 baseline" 정의 |
| M7 | 80% D1 도달 알림이 실제 작동하는지 검증 절차 | Anchor 11 "80% 도달 시 경고"만 명시. Workers Analytics에서 D1 storage 메트릭 자동 alert 가능 여부·검증 절차 미정의 | scope에서 "D1 storage alert 구현 + 분기 테스트 발화" 정의 |
| M8 | 마이그 중 Rails ↔ CF transition window 데이터 일관성 모델 | Brief는 "production data 부재"로 마이그를 0 가정. 그러나 Phase A 가동 ~ Phase C 폐기 사이 시간이 있고, Phase A 사용자 데이터가 D1에 쌓이기 시작. archive Rails 활성화 시 이 데이터를 어떻게 import? | scope에서 "Phase A 이후 archive 활성화 시 D1 → SQLite 변환 절차" 정의 |
| M9 | CF 계정 복수 owner / 결제 카드 만료 / 도메인 갱신 카운트다운 | 단일 owner·단일 카드·단일 도메인이 1년 후 만료/정지 시 전체 서비스 다운. R10·R6·R11의 운영 측면 | Brief Constraints에 "billing·domain·account 갱신 자동 모니터링" 추가 |
| M10 | 모바일 앱 미준비 상태에서 API 신설 시 통합 검증 어려움 | Flutter 앱이 진행 중일 때 새 API spec 검증 어려움. shared/api-schema 정의되지만 실제 통합 테스트 환경·Mock server 미정의 | scope에서 "shared/api-schema OpenAPI + Mock server (Prism 등)" 정의 |

## Detailed Analysis

### A. Cutover Safety 충분성

**A.1 Phase 정의는 있으나 rollback 절차 부재**

Anchor 7은 forward 흐름만 정의:
- Phase A: CF 인프라 + 모바일 API + 결제 가동
- Phase B: Hono SSR admin 가동
- Phase C: Rails archive 이동

각 phase의 **rollback trigger·절차·사용자 영향 범위**가 미정의. 예:

- **Phase A 후 rollback이 필요한 시나리오**: 결제 webhook idempotency 버그 발견, D1 throughput 천장 도달, 한국 ISP 라우팅으로 모바일 사용자 600ms+ 지연 다발. 이때 Flutter 앱이 이미 새 API 호출 중이면 archive Rails로 복귀해도 Flutter 앱 측 코드 변경 필요(API 경로·인증 토큰 형식 차이). 즉 **Phase A 자체가 부분 비가역**.
- **Phase B 후 rollback**: admin 사용자가 Hono SSR admin에 적응. Hotwire 복귀 시 UX 차이.
- **Phase C 후 rollback**: archive 활성화 자체가 W1 검증 미통과 시 무효.

**A.2 archive 활성화 실효성 (W1 상세)**

Anchor 8 "archive/rails-server/, git 이력 유지, 6개월 이상 유지". 그러나 archive를 실제로 켜려면:

1. **Ruby 버전**: 현 Rails 8.1.2의 Ruby 호환 (3.3+ 추정). 6개월 후 보안 패치된 Ruby 버전과 호환성.
2. **gem dependency**: bundler install이 6개월 후 lock된 gem 버전을 가져올 수 있는지 (yanked gem 위험).
3. **Kamal 배포 인프라**: Hetzner 서버·도메인 DNS·TLS 인증서. archive 활성화 = 새 서버 띄우기.
4. **데이터**: Phase A 후 D1에 쌓인 사용자 데이터를 SQLite로 변환. encryption key 호환 (Rails ActiveRecord encrypted attribute vs Workers Web Crypto AES-GCM 수동 구현 — 같은 알고리즘이라도 키 derivation·IV 형식 다를 수 있음).
5. **결제 webhook 이력**: D1 webhook_events를 SQLite로 가져와 Toss/PortOne 재시도 idempotency 보장.

이 5가지가 검증되지 않으면 archive는 **종이 안전망**. Critical Review Request의 "회귀 비상구"는 6개월 후 작동 안 할 가능성 큼.

**A.3 권장 Mitigation**:

- **분기별 archive smoke test**: 6·9·12개월 시점에 archive를 별도 환경에 띄워보고 health check + minimal scenario 테스트 (예: 사용자 등록·로그인·assessment 완료).
- **D1 ↔ SQLite 변환 스크립트 사전 작성**: archive 활성화 시 즉시 사용 가능한 마이그 스크립트.
- **encryption key 호환 설계**: Rails encrypts vs Web Crypto AES-GCM의 키·IV 형식을 사전에 일치시킴.

### B. 데이터 일관성·정합성

**B.1 Transition window 데이터 일관성** (M8 상세)

Brief는 production data 부재를 기반으로 마이그 비용을 0 가정. 그러나:

- Phase A 가동 시점 = 새 D1에 첫 사용자 쓰기 시작.
- Phase B/C 진행 동안 D1 데이터 누적.
- 만약 archive Rails로 회귀해야 하면 D1 데이터를 SQLite로 import 필요. 이 경로 미검증 = **archive 활성화 시점에 사용자 데이터 손실 가능성**.

**B.2 User.encrypts 키 관리** (W3 상세)

Decision 6의 "Web Crypto API AES-GCM 수동 구현(deterministic IV)"은:
- **단일 실패점**: 키 분실 = 모든 user 이메일 lookup·로그인 불가. password reset도 이메일 확인 의존.
- **Rotation 부재**: 키 노출 시 모든 데이터 재암호화 필요. 절차 미정의.
- **저장 위치**: wrangler secret vs KV vs 환경변수 — 어디 저장하는지 미정의.
- **백업**: 키 자체가 백업되지 않으면 D1 백업도 무용지물 (decryption 불가).

**B.3 D1 백업·복원** (W7 상세)

`wrangler d1 export`로 dump 가능하나:
- **자동화 미정의**: 일/주/월 빈도?
- **저장 위치**: R2 또는 외부 S3?
- **복원 검증 RPO/RTO**: 어느 시점 데이터 손실 허용? 복원 시간 목표?
- **encryption key 백업과 동기화**: B.2와 연동 필수.

**권장 Mitigation**:

1. 키를 wrangler secret + KV 양쪽 + 외부 password manager (1Password 등) 3중 저장.
2. 키 rotation: 분기별 새 키 + dual-decrypt 기간 + 점진 재암호화.
3. D1 export: 일별 자동 (cron trigger) + R2 저장 + 분기 복원 dry-run.

### C. 보안 리스크

**C.1 Secrets 관리** (W4)

Brief In Scope #1 "secrets 관리" 1줄. baseline 부재:
- **wrangler secret put** 사용 표준
- **rotation 주기**: 결제 PG webhook secret·admin auth·DB encryption key
- **CF 계정 침해 시**: 모든 secret 즉시 rotation 절차

**C.2 Toss webhook signature 검증 실패 처리** (W9)

P3 B 명시: signature 실패 시 4xx 반환. 그러나:
- **재시도 폭증**: signature 키 mis-rotation 시 7회 재시도 × 3일 19시간 동안 spam.
- **idempotency 손상**: signature 실패가 일시적이면 process 안 되고 누적.
- **alerting**: signature 실패율 임계 초과 시 알림 미정의.

**C.3 Admin auth 분리** (M1)

Anchor 9 "인증 토큰 양 서브도메인 공유 (cookie domain 또는 JWT)" — admin과 user 동일 토큰 시 admin auth bypass 발견 시 user 영역 escalation. 권장: admin은 별도 OAuth (Google Workspace 등) 또는 IP allowlist + 강제 2FA.

**C.4 CSRF·SameSite·Origin** (M2)

Rails ActionController::Base의 CSRF 보호는 자동. Hono SSR에서 form submit 처리 시 동등 보장 명시 필요.

**C.5 Rate limiting·WAF** (W5)

CF 무료 plan WAF 활성화 + Workers 라이트 rate limit 사용 baseline:
- login endpoint: 5 req/min/IP
- webhook endpoint: 100 req/min/IP (Toss IP 화이트리스트)
- API endpoint: 60 req/min/IP

부재 시 자동화 공격으로 D1 write $1/M 누적 → 비용 폭증 + 정상 사용자 영향.

### D. 법적·규제 리스크

**D.1 개인정보 국외 이전** (W6, R13)

본 연구 P5 R13 "Med 점수, 동의 + 처리방침으로 해결 가능". 그러나 Brief In Scope에 "동의 UX 구현·D1 jurisdiction 설정"이 명시 안 됨. 현 Rails `consent.rb` 모델이 `data_processing` consent type 보유 — 이게 새 스택에서 어떻게 구현되는지 미정의.

**D.2 14세 미만** (M3)

성격 검사 서비스 — 청소년·어린이 사용자 가능성. 한국 개인정보보호법 14세 미만은 보호자 동의 필수. Brief는 이 항목 미언급. 
- 옵션 1: 연령 게이트 + 보호자 동의 흐름 추가
- 옵션 2: Out of Scope "14세 미만 사용자는 ToS에서 금지" 명시

**D.3 약관·처리방침 신규 작성** (M4)

Rails `consent_version` + `consent_text_snapshot`은 약관 버전 추적 위해 존재. 새 스택에서:
- 약관 v1 신규 작성 + 법무 검토 (1인 개발자라면 외부 법무사)
- 기존 consent_version 호환 (production data 부재로 0건이지만 형식 호환 필요)

**D.4 deletion_request SLA 7일** (W6)

Rails `deletion_request.rb`: SLA 7일 + status (pending/processing/completed/failed) + overdue scope. 새 스택에서 동등 구현 + 7일 자동 처리 cron + overdue alert 명시 필요.

**D.5 audit_log** (W6)

Rails `audit_log.rb`: action/actor/resource/metadata 추적. 새 스택에서 어떤 이벤트를 audit하는지 정책 + retention 기간 명시 필요. R2(D1 10GB) 관점에서 audit_log는 R2 archive로 분리 권장 (P5 R2 mitigation).

### E. 운영 리스크

**E.1 1인 개발자 부재 시** (W8, R10)

R10 "단일 개발자 유지 부담"을 Brief가 수용 명시. 그러나 구체 절차 부재:
- **CF 계정 복수 admin**: 가족·동업자에게 admin 권한 부여 (분실·이탈 시 backup)
- **결제 PG 계정 복수 owner**: Toss·PortOne 계정의 owner 분산
- **secrets 백업 위치**: 외부 password manager
- **on-call**: 1인 시스템에서 alerting → 누가 받는가 (slack·email·SMS)

**E.2 CF 계정 정지·해킹·카드 만료** (M9)

단일 vendor 의존이 R6보다 심각:
- CF 계정 정지 (TOS 위반·결제 카드 만료): 전체 서비스 다운 (D1, Workers, R2 동시 차단)
- CF 계정 해킹: 모든 secret 노출
- 도메인 갱신 누락: 사용자 접근 불가

권장:
- CF 결제 카드 + 도메인 결제 카드 자동 갱신 + 만료 30일 전 알림
- CF 계정 2FA + recovery codes 외부 저장
- 백업 도메인 사전 등록 (예: `<도메인>.io` 또는 `<도메인>.app`)

**E.3 D1/Workers region failure** (M5)

R11 (CF outage 2025년 3건). region별 fallback 미정의:
- D1 jurisdiction 설정 시 region pinning → 해당 region failure 시 전면 다운
- status page (CF status integration) 자동 노출
- degraded mode (read-only) 옵션

**E.4 결제 PG (Toss) outage** (M6)

Toss outage 시 사용자 결제 차단. 옵션:
- queued retry (Workers Queues) + 사용자 "결제 후 처리 중" 메시지
- PortOne fallback (Decision 6 PortOne 2순위 활용 — 단 다중 PG 추상화 도입 시점에)
- 결제 자체를 사용자 옵션으로 미루는 UX

**E.5 D1 80% 알림 검증** (M7)

Anchor 11 "80% 도달 시 경고". Workers Analytics가 D1 storage 메트릭 alert 지원 여부 검증·분기 발화 테스트 필요. 알림이 작동 안 하면 10GB 도달 = 갑작스런 write 실패.

### F. 마이그 진행 중 리스크

**F.1 30.5 MW 추정의 불확실성** (W11)

Decision 1 "Partial 대비 +16 MW 일회성". 본 연구 P4 페이싱 가정 0.4-0.7 KLOC/wk (시니어). 실제 진행 50% 초과 시:
- 45+ MW = 11+ 개월 1인 풀타임
- Stay/Partial 회귀 결정 트리거 부재

권장: Critical Review Request에 "마이그 비용 50% 초과 시 Stay/Partial 회귀 검토" 추가.

**F.2 Rails 신규 기능 동결** (W10)

Out of Scope #6 "새 도메인 기능 추가"는 미세하게 다른 의미 (마이그 자체 vs 동결). 마이그 진행 중 비즈니스 압박으로 Rails에 새 기능 추가 시 이중 구현 부담. 명시 필요.

**F.3 Flutter 미준비 상태에서 API 신설** (M10)

Flutter 앱이 미준비된 상태에서 새 API spec 정의 시 검증 어려움. shared/api-schema OpenAPI + Mock server (Prism 등)로 Flutter 사전 통합 가능.

### G. 본 연구 010의 13 risks 매핑

| # | 리스크 | Brief 처리 | Mitigation 명시도 | Gap |
|---|-------|-----------|-------------------|-----|
| R1 | 한국 ISP Seoul PoP 라우팅 | "수용 명시" (Context) | 부재 — "경로 영향 무관" P3 발견에 의존 | 모니터링 메트릭·임계 미정의 |
| R2 | D1 10GB/DB 하드캡 | Anchor 11 "80% 알림" | 부분 — alert 검증 부재(M7) | Schema 샤딩 키 사전 도입 미명시, audit_log R2 분리 미명시 |
| R3 | D1 read replication 1년+ beta | 수용 (Context) | 부재 | KV/Cache API fallback baseline 미정의 |
| R4 | Korean 백엔드 메인스트림 부재 | 미언급 | 부재 | 영문 커뮤니티 의존·자가 학습 자료 baseline 부재 |
| R5 | Stripe Korea 부재 | Constraint "글로벌 결제 단계적" + Decision 13 | **명시** — 본 phase Stripe 제외 | 가장 명확. Gap 없음 |
| R6 | CF 벤더 락인 | Constraint "수용 명시" + Anchor 15 D1 export | 부분 — D1 export만 | secrets·도메인·결제 PG·인증 portability 미정의 |
| R7 | D1 단일 스레드 throughput | 수용 (Context) | 부재 | 인덱스 튜닝·KV cache baseline 미정의 |
| R8 | Workers 콜드스타트 | 수용 (Context) | 부재 | 영향 작음(R8 = Low score)이라 OK |
| R9 | DX gap (Rails console) | 미언급 | 부재 | wrangler tail + D1 console 사용 baseline 부재 |
| R10 | 단일 개발자 유지 | Brief Constraints "단일 또는 매우 작은 개발팀 가정" | 부재 — 부재 시 절차 미정의(W8) | 가장 큰 운영 gap |
| R11 | CF 2025 outage 3건 | 수용 (Context) | 부재 | status page·degraded mode·결제 fallback 미정의 |
| R12 | D1 interactive transaction 부재 | 수용 (Context) | 부재 — P5 mitigation에 의존 | scoring batch 재구성 baseline 명시 안 됨 |
| R13 | 개인정보 국외 이전 고지 | 미언급 | 부재 | 동의 UX·D1 jurisdiction·약관 항목 미정의(W6, M3, M4) |

**매핑 요약**:
- **명시적 mitigation**: 1개 (R5)
- **부분 mitigation**: 2개 (R2 alert, R6 D1 export)
- **수용만 (mitigation 부재)**: 7개 (R1, R3, R7, R8, R11, R12, R10)
- **미언급**: 3개 (R4, R9, R13)

13개 중 10개가 mitigation 부재 또는 미언급. 이는 Brief가 "결정 정리 Brief"이고 "scope/plan 단계에서 구체화"한다는 가정 하에 일부 정당하지만, **Critical Review Request 5개 모니터링 항목 외**에 운영 baseline이 명시되어야 cutover safety가 실질적.

### H. 가정 monitoring 5개 실효성

Critical Review Request의 5개 가정:
1. 한국 사용자 비중 ≥ 80%
2. 1년 내 MAU 수만 이내
3. 단일 개발자 ~ 2-3인 팀 유지
4. Ruby/Rails + TypeScript 양쪽 친숙
5. 결제 한국 우선

**H.1 트리거 미정의**:
- 6·12개월 retrospective가 어떻게 발화되는가? 캘린더 reminder? cron trigger? checklist?
- 자동화 메커니즘 없으면 1인 개발자가 마이그 일정에 매몰되어 잊을 가능성 높음.

**H.2 Responsible party 미정의**:
- 1인 개발자 시 = 자기 자신. 그러나 점검을 누가 강제하는가?
- 외부 mentor·동업자·메모 시스템 (Notion·Obsidian 등) 활용 baseline 부재.

**H.3 가정 깨짐 시 회귀 비용 추정 부재**:
- 가정 1 깨짐 (글로벌 비중 ↑) → Full 검토 = 추가 MW 부재 (이미 Full)
- 가정 2 깨짐 (100K MAU 임박) → 샤딩 8 MW (P5 R2 mitigation)
- 가정 3 깨짐 (개발자 이탈) → ?
- 가정 4 깨짐 (TS 친숙 약화) → ?
- 가정 5 깨짐 (글로벌 결제 시급) → 해외 entity 또는 BaaS

각 가정 깨짐 시 비용·결정 트리·archive 활용 여부 미정의.

**H.4 권장 Mitigation**:
1. **자동 알림**: GitHub Issue (`/loop` 또는 Cron + GitHub Action) 6·12개월 시점 자동 생성 → checklist + 5개 가정 재평가 + 재평가 결과 docs/에 기록.
2. **재평가 비용 추정**: 각 가정 깨짐 시 회귀 시나리오·MW·운영 영향 표를 Brief 부록으로.
3. **archive smoke test와 통합**: 6·12개월 retrospective에서 archive smoke test도 동시 수행 (W1 mitigation 통합).

## Recommendations for Brief Revision

### Brief 자체에 추가 권고 (Constraint 또는 Decision)

| # | Recommendation | Action | Priority |
|---|----------------|--------|----------|
| 1 | **archive 활성화 검증 절차 명시** — 분기별 smoke test, dry-run 환경, 6·12개월 retrospective와 통합 | Brief Constraint 신설 또는 Anchor 8 확장 | Critical |
| 2 | **D1 백업·키 관리 baseline** — 일별 export → R2 + 키 3중 저장(wrangler secret + KV + 외부 PM) + rotation 분기 | Brief Constraint 추가 | Critical |
| 3 | **보안 baseline (rate limit, WAF, CSRF, Origin, admin auth 분리)** — In Scope #14 신설 | In Scope 항목 추가 | Major |
| 4 | **컴플라이언스 흐름 동등 구현 명시** — consent grant/revoke + deletion SLA 7일 + audit_log + R2 archive | In Scope #15 신설 | Major |
| 5 | **1인 개발자 부재 운영 baseline** — CF 계정 복수 admin, 결제 PG 복수 owner, billing 자동 알림, 도메인 갱신 카운트다운 | Brief Constraint 추가 | Major |
| 6 | **마이그 비용 50% 초과 트리거** — 45+ MW 도달 시 Stay/Partial 회귀 검토 절차 | Critical Review Request 보강 | Minor |
| 7 | **가정 monitoring 자동화** — GitHub Issue 6·12개월 자동 생성 + checklist + responsible party | Critical Review Request 보강 | Minor |
| 8 | **연령 게이트 또는 14세 미만 Out of Scope 명시** | Boundaries 보강 | Minor |

### scope 단계에서 구체화 권고 (Brief 갱신 불필요)

| # | Item | Phase |
|---|------|-------|
| S1 | Phase 간 rollback 절차·trigger·사용자 영향 범위 | scope/plan |
| S2 | Toss webhook signature 실패·재시도 폭증 처리 baseline | scope |
| S3 | D1 region failure·degraded mode·status page | scope |
| S4 | 결제 PG outage 처리 (queued retry, PortOne fallback) | scope |
| S5 | shared/api-schema OpenAPI + Mock server | scope |
| S6 | D1 → SQLite 변환 스크립트 (archive 활성화 시 데이터 import) | scope |
| S7 | encryption key Rails ↔ Workers 호환 설계 | scope |
| S8 | wrangler tail + D1 console 사용 baseline (R9 mitigation) | scope |

### 비평이 발견하지 못한 영역 (다른 비평 관점에 의존)

- **타당성 (002 Critique_feasibility)**: MW 추정 정확도, 라이브러리 선택 적합성
- **scope 균형 (003 Critique_scope_balance)**: In Scope 13 vs Out of Scope 8의 균형, deliverable 명확성

본 비평은 위 두 영역과 중복하지 않도록 risk·security·compliance·operational에 집중.

## References

| Resource | Path/URL | Relevance |
|----------|----------|-----------|
| Brief 001 | `../02_cf_workers_rebuild/001_Brief_cf_workers_rebuild.md` | 비평 대상 |
| Research 010 (final) | `../01_cloudflare_migration_research/010_Research_cloudflare_migration.md` | 13 R-risks 출처 |
| Agent 008 (P5 risk matrix) | `../01_cloudflare_migration_research/008_Agent_risk_and_recommendation.md` | risk evidence |
| Agent 005 (P3 payment) | `../01_cloudflare_migration_research/005_Agent_payment_integration.md` | webhook·PCI·규제 evidence |
| Rails User 모델 | `/Users/kampikrein/A/personality/server/app/models/user.rb` | encrypts deterministic 출처 |
| Rails Consent 모델 | `/Users/kampikrein/A/personality/server/app/models/consent.rb` | 컴플라이언스 동등 구현 대상 |
| Rails DeletionRequest 모델 | `/Users/kampikrein/A/personality/server/app/models/deletion_request.rb` | SLA 7일 + status flow |
| Rails AuditLog 모델 | `/Users/kampikrein/A/personality/server/app/models/audit_log.rb` | audit 흐름 |
| 한국 개인정보보호법 제28조의8 | (P3 reference) | 국외 이전 고지 의무 |
| CF 2025 outage 보고 | blog.cloudflare.com 2025-11-18·12-05·06-12 | R11 evidence |
| Toss webhook spec | docs.tosspayments.com/guides/v2/webhook | 재시도 7회·3일 19시간 |

## Communication Log

| # | Direction | Peer | Summary | Stage |
|---|-----------|------|---------|-------|
| 1 | ← | Brief 001 | Decision 9 (cutover phased), Decision 10 (archive 보존), Critical Review Request 5 가정, Constraints 9개 입력 | Cycle 비평 |
| 2 | ← | Research 010 | 13 R-risks 매핑 표 입력 | Cycle 비평 |
| 3 | ← | Agent 005 (P3) | Toss webhook 재시도·signature·idempotency baseline 입력 | Cycle 비평 |
| 4 | ← | Rails models | consent/deletion_request/audit_log/user 모델 검토하여 컴플라이언스 동등 구현 항목(W6) 도출 | Cycle 비평 |
| 5 | → | 002 Critique_feasibility | W3 (encryption key 관리)는 타당성 측에서도 다룰 수 있음 — 중복 영역 확인 권장 | (간접) |
| 6 | → | 003 Critique_scope_balance | M6 (PG outage), M10 (Mock server), W5 (보안 baseline)이 In Scope 누락 항목 — scope 균형 비평과 교차 | (간접) |
| 7 | → | Brief 갱신자 | Recommendations §1~8 (Brief 직접) + S1~S8 (scope 위임) 분리 권고 | Cycle 비평 |
