---
id: "004"
title: "데이터 모델 및 DB 스키마 분석"
category: agent
status: archived
created: 2026-03-11
summary: >
  personality 프로젝트의 13개 Rails 모델 역할, 관계 매핑, 마이그레이션 히스토리,
  익명 세션 지원 구조, GDPR 컴플라이언스 모델(Consent/DeletionRequest/AuditLog)을 초보자 관점에서 분석.
keywords: [agent-report, models, schema, migrations, ERD, GDPR, anonymous-session]
modules: [models, database, migrations]
---

# 데이터 모델 및 DB 스키마 분석

## 요약

personality 프로젝트는 14개 테이블(Alert 포함)로 구성된 SQLite 기반 Rails 8.1.2 앱이다. 핵심 설계 원칙은 "비로그인(익명) 사용자도 성격검사를 완전히 수행할 수 있다"는 것이며, AnonymousSession이 검사 흐름의 중심축이다. GDPR 컴플라이언스를 위해 Consent, DeletionRequest, AuditLog, Alert 4개 모델이 전용으로 존재한다. 마이그레이션 히스토리를 보면 초기 설계에서 실수(Consent의 null 제약, 누락된 타임스탬프 컬럼, 중복 방지 인덱스 누락)가 발생하여 2026-02-21~22 사이에 6개의 수정 마이그레이션이 추가 적용되었다.

## 상세 분석

### 1. 전체 모델 역할 개요 (테이블)

| 모델명 | 테이블명 | 역할 1줄 설명 | 주요 컬럼 |
|---|---|---|---|
| User | users | 등록 회원 (선택적 존재) | email, password_digest, deleted_at |
| AnonymousSession | anonymous_sessions | 비로그인 사용자 식별 세션 — 검사 흐름의 중심 | session_token, ip_hash, user_id |
| Consent | consents | GDPR 동의 항목 기록 | consent_type, granted, revoked_at |
| QuestionSet | question_sets | 질문 묶음 버전 관리 | version_code, status |
| Question | questions | 개별 검사 문항 | domain, position, body_ko, polarity |
| Assessment | assessments | 한 번의 검사 시도 세션 | status, current_question_index, completion_rate |
| Response | responses | 문항별 사용자 응답값 | value (1-5), response_time_ms |
| DomainScore | domain_scores | 도메인별 점수 계산 결과 | domain, raw_score, normalized_score |
| PersonalityType | personality_types | 16개 성격 유형 마스터 데이터 | code (ENFP 등), character_name_ko/en |
| Profile | profiles | 검사 완료 후 생성되는 최종 결과 | type_code, score_vector, policy_blocked |
| Insight | insights | 프로필 기반 맥락별 인사이트 | context, explanation, suggestions |
| DeletionRequest | deletion_requests | 개인정보 삭제 요청 처리 | request_token, status, sla_deadline |
| AuditLog | audit_logs | 모든 중요 행위 감사 기록 | action, actor_type/id, resource_type/id |
| Alert | alerts | 이상 탐지 및 시스템 경고 | alert_type, severity, status |

### 2. 모델별 상세 분석

#### User (`app/models/user.rb`)

**컬럼** (`schema.rb:196-204`):
- `email` — 암호화(deterministic) 저장, 유니크 인덱스
- `password_digest` — has_secure_password (bcrypt)
- `display_name` — 암호화 저장
- `deleted_at` — soft delete 구현용 datetime
- `created_at`, `updated_at`

**관계**:
- `has_many :anonymous_sessions, dependent: :nullify`
- `has_many :consents, dependent: :destroy`

**특이사항**:
- `encrypts :email, deterministic: true` — Rails 8 ActiveRecord Encryption 사용
- `soft_delete!` / `deleted?` 메서드로 논리 삭제 지원 (물리 삭제 없음)
- `scope :active` — `deleted_at: nil` 인 활성 사용자만 필터

#### AnonymousSession (`app/models/anonymous_session.rb`)

**컬럼** (`schema.rb:28-39`):
- `session_token` (null: false) — UUID, 유니크 인덱스
- `ip_hash` — IP 주소 해시 (원본 미저장)
- `ip_fingerprint` — 추가된 지문 정보 (2026-02-21 마이그레이션으로 추가)
- `user_agent_hash` — 브라우저 에이전트 해시
- `user_id` — nullable (비로그인이면 nil)
- `started_at` (2026-02-21 마이그레이션으로 추가)

**관계**:
- `belongs_to :user, optional: true`
- `has_many :assessments, dependent: :destroy`
- `has_many :profiles, dependent: :destroy`
- `has_many :consents, dependent: :destroy`
- `has_many :deletion_requests, dependent: :destroy`

**콜백**: `before_validation :generate_session_token, on: :create` — SecureRandom.uuid 자동 생성

#### Consent (`app/models/consent.rb`)

**컬럼** (`schema.rb:71-84`):
- `anonymous_session_id` — nullable (수정 마이그레이션으로 변경)
- `user_id` — nullable (수정 마이그레이션으로 변경)
- `consent_type` — 'data_processing' / 'account_linking' / 'analytics'
- `consent_version` — 동의서 버전 문자열 (예: "1.0")
- `consent_text_snapshot` — 동의 당시 약관 전문 스냅샷 (text)
- `granted` — boolean (동의/거부)
- `granted_at`, `revoked_at` — 시점 기록

**검증**: 커스텀 검증 `has_session_or_user` — anonymous_session_id와 user_id 중 하나 이상 필수

**메서드**: `revoke!` — revoked_at 기록 및 granted: false 설정

#### QuestionSet (`app/models/question_set.rb`)

**컬럼** (`schema.rb:161-167`):
- `version_code` — 유니크, 버전 식별자 (예: "qset_v1")
- `status` — 'draft' / 'active' / 'archived'

**메서드**:
- `current` — active 상태 중 가장 최신 반환
- `activate!` — 트랜잭션으로 기존 active를 archived로 바꾸고 본인만 active로

#### Question (`app/models/question.rb`)

**컬럼** (`schema.rb:169-181`):
- `domain` — 4개 도메인: energy, decision_making, relationship, recovery
- `position` — 도메인 내 순서 번호
- `body_ko` (null: false), `body_en` — 한국어/영어 문항
- `polarity` — 'positive' / 'negative' (역채점용)
- `active` — boolean, default: true

**유니크 인덱스**: `(question_set_id, domain, position)` — 같은 세트 내 같은 도메인+위치 중복 방지

#### Assessment (`app/models/assessment.rb`)

**컬럼** (`schema.rb:41-56`):
- `status` — in_progress / submitted / scored / completed / failed
- `current_question_index` — 현재 진행 문항 번호
- `completion_rate`, `non_response_rate`, `extreme_response_rate` — 품질 지표
- `retry_token` — 재시도용 토큰
- `started_at`, `completed_at` (2026-02-21 마이그레이션으로 추가)

**상태 전이 메서드**: `submit!` → `score!` → `complete!` / `fail!`

**기타 메서드**: `current_question`, `advance_to_next_question!`, `all_questions_answered?`, `progress_percentage`

#### Response (`app/models/response.rb`)

**컬럼** (`schema.rb:183-194`):
- `value` — 1~5 리커트 척도 (nil 허용 = 스킵)
- `response_time_ms` — 응답 소요 시간 (밀리초)
- `sequence_number` — 응답 순서

**유니크 인덱스**: `(assessment_id, question_id)` — 동일 검사에서 같은 문항 중복 응답 방지

#### DomainScore (`app/models/domain_score.rb`)

**컬럼** (`schema.rb:98-111`):
- `domain` — 4개 도메인 중 하나
- `raw_score` — 원점수
- `normalized_score` — 0~100 정규화 점수
- `reliability_coefficient` — 신뢰도 계수
- `consistency_index` — 일관성 지수
- `speed_flag` — 응답 속도 이상 여부
- `policy_blocked` — 정책에 의한 차단 여부

**유니크 인덱스**: `(assessment_id, domain)` — 검사당 도메인별 점수 1개만 허용

#### PersonalityType (`app/models/personality_type.rb`)

**컬럼** (`schema.rb:124-140`):
- `code` — ENFP~ISTJ 16개 코드, 유니크
- `character_name_ko`, `character_name_en` — 오리지널 캐릭터명
- `summary_ko`, `summary_en` — 유형 요약 설명
- `strengths`, `caution_patterns` — JSON 배열
- `collaboration_style`, `conflict_style`, `learning_style`, `career_hints`, `recovery_style` — 상황별 설명

**관계**: `has_many :profiles, dependent: :restrict_with_error`

#### Profile (`app/models/profile.rb`)

**컬럼** (`schema.rb:142-159`):
- `type_code` — 예: "ENFP"
- `score_vector` — JSON, 도메인별 점수 해시
- `strengths`, `caution_patterns`, `suggested_actions` — JSON 배열
- `policy_blocked` — 정책 차단 여부, default: false
- `fallback_message` — 차단 시 대체 메시지

**유니크 인덱스**: `assessment_id` — 검사 1개당 프로필 1개

#### Insight (`app/models/insight.rb`)

**컬럼** (`schema.rb:113-122`):
- `context` (null: false) — collaboration / conflict / learning / career / recovery
- `explanation` — 설명 text
- `suggestions` — JSON 배열

**유니크 인덱스**: `(profile_id, context)` — 프로필당 컨텍스트 1개만 허용

#### DeletionRequest (`app/models/deletion_request.rb`)

**컬럼** (`schema.rb:86-96`):
- `request_token` (null: false, 유니크) — SecureRandom.hex(16)
- `status` — pending / processing / completed / failed, default: "pending"
- `sla_deadline` — 처리 기한 (생성 시 7일 후 자동 설정)

**상태 전이**: `process!` → `complete!` / `fail!`
**스코프**: `pending` / `overdue` (sla_deadline 경과한 pending 건)

#### AuditLog (`app/models/audit_log.rb`)

**컬럼** (`schema.rb:58-69`):
- `action` (null: false) — 행위 설명 문자열
- `actor_type`, `actor_id` — 행위자 (polymorphic)
- `resource_type`, `resource_id` — 대상 리소스 (polymorphic)
- `metadata` — JSON, 추가 컨텍스트

**특이사항**: 특정 모델에 belong_to 없이 완전한 polymorphic 설계. `AuditLog.record!(...)` 클래스 메서드로 전 서비스에서 호출 가능

#### Alert (`app/models/alert.rb`)

**컬럼** (`schema.rb:14-26`):
- `alert_type` — bot_detected / policy_violation / anomaly_detected / system_error
- `severity` — low / medium / high / critical, default: "medium"
- `status` — open / acknowledged / resolved / dismissed, default: "open"
- `message`, `notes` — text
- `metadata` — JSON
- `resolved_at` — 해결 시점

---

### 3. 모델 관계 ERD (텍스트 다이어그램)

```
[User] ─────────────────────────────┐
  │ has_many (nullify)               │ has_many (destroy)
  ▼                                  ▼
[AnonymousSession] ◄────── (optional: true)
  │
  ├── has_many ──► [Assessment]
  │                    │
  │                    ├── has_many ──► [Response] ──► belongs_to ──► [Question]
  │                    │                                                    │
  │                    ├── has_many ──► [DomainScore]              belongs_to
  │                    │                                                    │
  │                    └── has_one  ──► [Profile]           [QuestionSet] ◄─┘
  │                                        │                     │
  │                                        ├── has_many ──► [Insight]
  │                                        └── belongs_to ──► [PersonalityType]
  │                                                               │
  │                                                        has_many (restrict)
  │
  ├── has_many ──► [Consent]  (also: User has_many Consents)
  ├── has_many ──► [DeletionRequest]
  └── has_many ──► [Profile]  (직접 참조도 유지)

[AuditLog]  ── 독립 테이블, polymorphic actor/resource
[Alert]     ── 독립 테이블, 어떤 모델에도 belongs_to 없음

QuestionSet ──► has_many ──► [Question]
QuestionSet ──► has_many ──► [Assessment] (restrict_with_error)
```

**관계 방향 요약 (belongs_to 기준)**:

| 모델 | belongs_to |
|---|---|
| AnonymousSession | User (optional) |
| Consent | AnonymousSession (optional), User (optional) |
| Assessment | AnonymousSession, QuestionSet |
| Response | Assessment, Question |
| DomainScore | Assessment |
| Profile | Assessment, AnonymousSession, PersonalityType |
| Insight | Profile |
| DeletionRequest | AnonymousSession |
| Question | QuestionSet |

---

### 4. 마이그레이션 히스토리

#### Phase 1 — 초기 생성 (2026-02-20, 타임스탬프 174720~174829)

15개 마이그레이션으로 전체 테이블 골격 구축:

| 타임스탬프 | 마이그레이션명 | 핵심 내용 |
|---|---|---|
| 174720 | CreateAnonymousSessions | session_token(unique), ip_hash, user_id(FK) |
| 174721 | CreateUsers | email, password_digest, deleted_at |
| 174722 | CreateConsents | **버그**: user_id/anonymous_session_id 모두 null: false |
| 174723 | CreateQuestionSets | version_code(unique), status |
| 174724 | CreateQuestions | domain, position, body_ko, polarity, unique(set+domain+pos) |
| 174744 | CreateAssessments | status, current_question_index, 품질 지표 3개 |
| 174745 | CreateResponses | value, response_time_ms, sequence_number |
| 174746 | CreateDomainScores | domain, raw/normalized score, 신뢰도 지표 |
| 174825 | CreatePersonalityTypes | code(unique), 16가지 설명 필드 |
| 174826 | CreateProfiles | assessment(unique FK), score_vector(JSON) |
| 174827 | CreateInsights | context, unique(profile+context) |
| 174828 | CreateDeletionRequests | request_token(unique), status, sla_deadline |
| 174829 | CreateAuditLogs | polymorphic actor/resource, action |

#### Phase 2 — 수정 마이그레이션 (2026-02-21~22)

**왜 수정이 필요했는가?** 초기 설계에서 발견된 3가지 버그:

**버그 1: 누락된 타임스탬프 컬럼** (`20260221000001`):
- `anonymous_sessions`에 `ip_fingerprint`, `started_at` 누락
- `assessments`에 `started_at`, `completed_at` 누락

**버그 2: Consent의 잘못된 null 제약** (`20260222000001`):
- 초기에 `user_id null: false`, `anonymous_session_id null: false`로 설정
- 익명 사용자는 user_id가 없고, 등록 사용자는 anonymous_session_id가 없음
- 실제로는 둘 중 하나만 있으면 됨 → 모두 null 허용으로 변경

**버그 3: 유니크 인덱스 누락** (`20260222000002`, `20260222000003`):
- `responses`에서 동일 검사+문항에 대한 중복 응답 방지 인덱스 누락
- `domain_scores`에서 동일 검사+도메인 중복 점수 방지 인덱스 누락
- DB 레벨 보장이 없었음

**추가 기능** (`20260222000004`, `20260222000005`):
- `CreateAlerts` — 이상 탐지 시스템 테이블 신규 추가
- `AddWave2Indexes` — users.email 유니크 인덱스, deletion_requests.sla_deadline 인덱스 추가

---

### 5. 인덱스 및 제약 조건

#### 유니크 인덱스 (`schema.rb` 직접 확인)

| 테이블 | 인덱스 컬럼 | 의미 |
|---|---|---|
| anonymous_sessions | session_token | 세션 토큰 중복 방지 |
| question_sets | version_code | 버전 코드 중복 방지 |
| questions | (question_set_id, domain, position) | 같은 세트 내 동일 위치 중복 방지 |
| responses | (assessment_id, question_id) | 동일 검사에서 같은 문항 중복 응답 방지 |
| domain_scores | (assessment_id, domain) | 검사당 도메인 점수 1개 보장 |
| personality_types | code | 유형 코드 중복 방지 |
| profiles | assessment_id | 검사당 결과 프로필 1개 보장 |
| insights | (profile_id, context) | 프로필당 컨텍스트 인사이트 1개 보장 |
| deletion_requests | request_token | 삭제 요청 토큰 중복 방지 |
| users | email | 이메일 중복 방지 |

#### 외래키 (`schema.rb:206-219`)

```
anonymous_sessions.user_id         → users
assessments.anonymous_session_id   → anonymous_sessions
assessments.question_set_id        → question_sets
consents.anonymous_session_id      → anonymous_sessions
consents.user_id                   → users
deletion_requests.anonymous_session_id → anonymous_sessions
domain_scores.assessment_id        → assessments
insights.profile_id                → profiles
profiles.anonymous_session_id      → anonymous_sessions
profiles.assessment_id             → assessments
profiles.personality_type_id       → personality_types
questions.question_set_id          → question_sets
responses.assessment_id            → assessments
responses.question_id              → questions
```

AuditLog와 Alert는 외래키 없음 (완전 독립 테이블).

---

### 6. 익명 사용자(AnonymousSession) vs 등록 사용자(User)

**비로그인 사용자도 검사를 진행할 수 있는가? → Yes, 완전히 지원된다.**

설계 근거:
1. `anonymous_sessions.user_id`는 nullable (`schema.rb:36`)
2. `assessments.anonymous_session_id`만 필수 (user_id 참조 없음)
3. `profiles.anonymous_session_id`만 필수 (user_id 참조 없음)
4. `AnonymousSession`의 `belongs_to :user, optional: true`

즉, 검사 흐름 전체(AnonymousSession → Assessment → Response → DomainScore → Profile → Insight)가 User 없이 완결된다.

**익명 세션이 나중에 User 계정으로 전환되는가?**

구조적으로 연결은 가능하지만, 자동 전환 로직은 모델 레벨에 없다.

```
비로그인 접속
     │
     ▼
AnonymousSession 생성 (user_id: nil)
     │
     ▼
검사 진행 → Assessment → Profile 완성
     │
     ▼ (선택: 회원가입)
User 생성 + AnonymousSession.user_id 업데이트
     │
     ▼
Consent(account_linking) 기록
```

---

### 7. GDPR 컴플라이언스 모델

#### Consent (동의 추적)

**추적하는 동의 항목** (`consent.rb:5`):
```ruby
TYPES = %w[data_processing account_linking analytics].freeze
```

| 동의 유형 | 의미 |
|---|---|
| `data_processing` | 개인정보 처리(성격검사 결과 생성)에 대한 동의 — 핵심 동의 |
| `account_linking` | 익명 세션을 회원 계정과 연결하는 동의 |
| `analytics` | 통계/분석 목적 데이터 활용 동의 |

**GDPR 준수 장치**:
- `consent_text_snapshot` — 동의 시점의 약관 전문을 DB에 저장 (나중에 약관이 바뀌어도 동의 당시 내용 보존)
- `consent_version` — 버전별 동의 이력 추적 가능
- `granted_at`, `revoked_at` — 동의/철회 시점 기록
- `revoke!` 메서드 — 언제든 동의 철회 가능

#### DeletionRequest (삭제 요청 상태 흐름)

**상태 흐름**:
```
pending (초기값)
    │
    ├── process!  ──► processing
    │                    │
    │              complete! ──► completed
    │              fail!    ──► failed
    │
    └── [sla_deadline 초과] ──► overdue 스코프로 감지
```

**SLA 관리** (`deletion_request.rb`):
- `SLA_DAYS = 7` — GDPR 기준 7일 내 처리 의무
- 생성 시 자동으로 `sla_deadline = 7.days.from_now` 설정
- `scope :overdue` — 기한을 넘긴 pending 건 조회

#### AuditLog (감사 로그)

**사용 패턴**:
```ruby
AuditLog.record!(
  action: "consent_revoked",
  actor_type: "AnonymousSession", actor_id: session.id,
  resource_type: "Consent", resource_id: consent.id,
  metadata: { consent_type: "data_processing" }
)
```

AuditLog는 어떤 모델에도 belongs_to 없이 완전히 독립적. 테이블이 삭제되어도 로그는 남는다.

---

### 8. Seeds 및 팩토리 구조

#### seeds.rb 분석

초기 데이터 두 가지를 투입:

**1) 16개 PersonalityType 마스터 데이터** (`seeds.rb:4-235`):
- ENFP~ISTJ 16개 유형 전체
- `find_or_initialize_by(code:)` 사용 — 중복 실행 시 업데이트 (idempotent)
- 캐릭터명은 공식 MBTI 명칭과 무관한 오리지널 이름 (저작권 고려)

**2) QuestionSet v1 — 20개 문항** (`seeds.rb:242-326`):
- 4개 도메인 x 5개 문항 = 총 20개 문항

| 도메인 | 측정 축 | 높은 점수 의미 |
|---|---|---|
| energy | E/I (외향/내향) | 외향(E) 성향 |
| decision_making | N/S (직관/감각) | 직관(N) 성향 |
| relationship | F/T (감정/사고) | 감정(F) 성향 |
| recovery | P/J (인식/판단) | 인식/유연(P) 성향 |

#### spec/factories.rb 구조

| 팩토리 | 주목할 점 |
|---|---|
| `anonymous_session` | ip_hash, user_agent_hash를 SHA256으로 해시화 |
| `user` | sequence로 이메일 자동 생성, password "password123" 고정 |
| `question_set` | `:with_questions` trait: 4도메인 x 5문항 20개 자동 생성 |
| `personality_type` | code: "ENFP" 하드코딩 — 테스트 간 uniqueness 충돌 주의 필요 |
| `profile` | score_vector에 4개 도메인 점수 포함 |

**설계 관찰**: `audit_log`, `alert` 팩토리가 없음. 이 모델들은 보통 서비스 레이어에서 직접 생성하므로 팩토리 필요성이 낮음.

---

## 핵심 발견

1. **익명 우선 설계**: 모든 검사 데이터(Assessment, Response, Profile)는 User 없이 AnonymousSession만으로 완결된다.

2. **Consent 초기 설계 버그**: `CreateConsents` 마이그레이션에서 두 컬럼 모두 필수로 설정했으나, "익명 또는 사용자 중 하나" 구조와 충돌. `FixConsentsNullConstraints` (2026-02-22)로 수정.

3. **타임스탬프 누락 후 추가**: `started_at`, `completed_at`, `ip_fingerprint`가 초기 마이그레이션에 없어서 별도 마이그레이션으로 추가됨.

4. **DomainScore와 Response의 유니크 인덱스 지연 추가**: 비즈니스 로직만 있고 DB 레벨 유니크 인덱스가 없으면 동시성 상황에서 중복 삽입이 가능하다. 2026-02-22에 DB 레벨 보장을 추가하여 방어를 완성했다.

5. **Alert 모델의 독립성**: Alert는 어떤 모델에도 FK가 없다. 특정 세션이나 사용자와 연결되지 않은 시스템 레벨 경보다.

6. **PersonalityType은 마스터 데이터**: `restrict_with_error`로 Profile이 있으면 삭제 불가. seeds.rb가 유일한 데이터 원천이며, 코드로 관리된다.

---

## 초보자를 위한 핵심 포인트

1. **"세션이 곧 사용자다" — AnonymousSession이 핵심**: 이 프로젝트는 회원가입 없이도 검사를 할 수 있도록 `AnonymousSession`이 사실상 "사용자" 역할을 한다. User는 선택적으로 연결되는 부가 정보다.

2. **마이그레이션은 "DB 변경 히스토리 파일"이다**: `schema.rb`는 최종 결과, 마이그레이션 파일들은 그 결과에 도달하는 과정이다. 실수가 생기면 새 마이그레이션으로 수정한다.

3. **JSON 컬럼은 배열/해시를 DB에 저장하는 방법이다**: `strengths`, `caution_patterns`, `score_vector` 등이 JSON 타입이다. Ruby 배열/해시가 그대로 DB에 저장되고 읽힌다.

4. **soft_delete vs 물리 삭제**: User의 `deleted_at` 컬럼이 있으면 "논리 삭제(soft delete)"다. DB에서 row가 사라지지 않고 deleted_at 날짜만 채워진다.

5. **유니크 인덱스는 "중복 방지 자물쇠"다**: `(assessment_id, question_id)` 유니크 인덱스가 있으면, 같은 검사에서 같은 문항에 두 개의 응답을 저장하려고 할 때 DB가 직접 에러를 낸다. 모델의 `validates uniqueness`만으로는 동시 요청(race condition)에서 중복이 생길 수 있다.

---

## 참조 파일

- `db/schema.rb` — 최종 DB 구조 (버전: 2026_02_22_000005)
- `db/seeds.rb` — 16개 PersonalityType + qset_v1 20문항 초기 데이터
- `app/models/anonymous_session.rb` — 검사 흐름 중심 모델
- `app/models/user.rb` — 등록 사용자, ActiveRecord Encryption 적용
- `app/models/consent.rb` — GDPR 동의 3종 추적
- `app/models/assessment.rb` — 검사 세션, 상태 전이 메서드
- `app/models/deletion_request.rb` — 7일 SLA 삭제 요청
- `app/models/audit_log.rb` — polymorphic 감사 로그
- `app/models/alert.rb` — 이상 탐지 경고
- `db/migrate/20260222000001_fix_consents_null_constraints.rb` — Consent null 제약 수정
- `db/migrate/20260221000001_add_missing_columns_to_anonymous_sessions_and_assessments.rb` — 타임스탬프 컬럼 추가
- `db/migrate/20260222000002_add_unique_index_to_responses.rb` — Response 유니크 인덱스 추가
- `spec/factories.rb` — 테스트 팩토리 14개
