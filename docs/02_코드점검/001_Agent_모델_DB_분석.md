---
id: "001"
type: agent
title: "Agent A: 모델 & DB 레이어 분석"
created: 2026-02-22
summary: >
  성격 서비스 Rails 프로젝트의 모델 14개와 DB 레이어를 분석한 에이전트 리포트.
  핵심 관계, 인덱스, 잠재 이슈를 정리한다.
keywords: [Rails, 모델분석, DB, 코드점검]
---

# Agent A: 모델 & DB 레이어 분석

> 분석일: 2026-02-22
> 범위: `app/models/`, `db/migrate/`, `db/schema.rb`

## 1. 모델 목록 (14개)

| 모델 | 테이블 | 핵심 관계 |
|------|--------|----------|
| AnonymousSession | anonymous_sessions | has_many :assessments, :consents |
| User | users | has_many :consents |
| Consent | consents | belongs_to :anonymous_session (optional), :user (optional) |
| QuestionSet | question_sets | has_many :questions, :assessments |
| Question | questions | belongs_to :question_set |
| Assessment | assessments | belongs_to :anonymous_session, :question_set; has_many :responses, :domain_scores; has_one :profile |
| Response | responses | belongs_to :assessment, :question |
| DomainScore | domain_scores | belongs_to :assessment |
| PersonalityType | personality_types | has_many :profiles |
| Profile | profiles | belongs_to :assessment, :personality_type, :anonymous_session |
| Insight | insights | belongs_to :profile |
| DeletionRequest | deletion_requests | belongs_to :anonymous_session |
| AuditLog | audit_logs | 독립 (polymorphic actor/resource) |

## 2. 발견된 이슈

### C-4: consents 스키마-모델 불일치 (CRITICAL)
- **DB**: `user_id null: false`, `anonymous_session_id null: false`
- **모델**: `belongs_to :anonymous_session, optional: true`, `belongs_to :user, optional: true`
- **영향**: 익명 사용자가 동의를 생성할 수 없음 (user_id NOT NULL 제약 위반)
- **수정**: 마이그레이션으로 두 컬럼 모두 `null: true`로 변경 + foreign_key 유지

### C-6: responses 복합 유니크 인덱스 누락 (CRITICAL)
- **모델**: `validates :question_id, uniqueness: { scope: :assessment_id }` (앱 레벨만)
- **DB**: `assessment_id`, `question_id` 개별 인덱스만 존재
- **위험**: 레이스 컨디션에서 중복 응답 삽입 가능
- **수정**: `add_index :responses, [:assessment_id, :question_id], unique: true`

### C-7: domain_scores 복합 유니크 인덱스 누락 (CRITICAL)
- **모델**: `validates :domain, uniqueness: { scope: :assessment_id }` (앱 레벨만)
- **DB**: `assessment_id` 인덱스만 존재
- **위험**: 동일 assessment에 같은 domain 스코어 중복 삽입 가능
- **수정**: `add_index :domain_scores, [:assessment_id, :domain], unique: true`

### H-4: scope에서 find_by 사용 (HIGH)
- `DomainScore.for_domain` → `find_by(domain:)` — ActiveRecord::Relation이 아닌 단일 레코드 반환
- `Insight.for_context` → `find_by(context:)` — 체이닝 불가
- **수정**: `where(...)` 로 변경

### M-1: users.email 유니크 인덱스 없음 (MEDIUM)
- 이메일 중복 가입 가능
- **수정**: Wave 2에서 `add_index :users, :email, unique: true` 추가

## 3. 양호 사항

- Assessment 상태 머신 (STATUSES) 명확하게 정의됨
- Response 모델의 value 유효성 검사 (1..5) 적절
- QuestionSet 활성화 시 트랜잭션 사용 (activate!)
- Profile에 assessment_id unique 인덱스 존재
- Insight에 [profile_id, context] 복합 unique 인덱스 존재
