---
id: "004"
title: "코딩 전문가 비평 — Rails 코드 품질·아키텍처·테스트 분석"
category: agent
status: archived
created: 2026-03-13
summary: >
  Rails 8.1 기반 personality 프로젝트를 시니어 개발자 관점에서 전수 분석.
  서비스 레이어와 모델 설계는 전반적으로 준수하나, ResultsController에 파이프라인
  로직이 혼재하는 Fat Controller 문제, HTTP Basic 인증의 프로덕션 보안 한계,
  테스트 커버리지의 중요 공백(컨트롤러/모델 다수 미커버)이 핵심 개선 과제다.
keywords: [agent-report, rails, code-quality, architecture, testing, performance, security]
modules: [models, controllers, services, views, config]
---

# 코딩 전문가 비평 — Rails 코드 품질·아키텍처·테스트 분석

## Progress
### Completed
- [x] 모델 레이어 분석 (14 모델, 관계/검증/스코프)
- [x] 컨트롤러 레이어 분석 (12 컨트롤러, RESTful 준수, Fat Controller)
- [x] 서비스 레이어 분석 (19 서비스, SOLID, 의존성)
- [x] 테스트 커버리지 분석 (spec/ 존재 여부 및 범위)
- [x] 성능 분석 (N+1, 인덱스, 트랜잭션)
- [x] 보안 분석 (인증/인가, 입력 검증, 개인정보)
- [x] 라우팅/설정 분석
### Remaining
- (없음)
### Current Status
분석 완료.

---

## Summary

personality 프로젝트는 Rails 8.1 + SQLite(dev)/PostgreSQL(prod) 구성으로,
14 모델 / 12 컨트롤러 / 19 서비스의 중간 규모 MVP다.
서비스 레이어는 모듈화가 잘 되어 있고 `frozen_string_literal` 적용, N+1 방어를 위한 eager loading 등
기본기가 갖추어져 있다. 그러나 **ResultsController의 파이프라인 로직 혼재**,
**HTTP Basic 인증의 프로덕션 한계**, **컨트롤러·뷰·다수 모델에 대한 테스트 부재**가 주요 위험 요소다.
아래 비평은 심각도 순서로 정리한다.

---

## Details

### 1. 모델 레이어 분석

#### 1-1. AnonymousSession
**현재 상태:** `belongs_to :user, optional: true`, `has_many` 4개, `before_validation :generate_session_token`.
**긍정:** `session_token` uniqueness + not-null, UUID 생성 로직이 콜백에 잘 캡슐화되어 있다.
**문제점 (Medium):** `ip_fingerprint` 컬럼(schema에 있음)에 DB 인덱스가 없다.
중복 핑거프린트 탐지 쿼리(`WHERE ip_fingerprint = ?`)가 느려질 수 있다.
또한 모델에 `scope :active` 같은 "삭제되지 않은 세션" 스코프가 없어
컨트롤러가 직접 `find_by`로 세션을 꺼내고 있다.

#### 1-2. Assessment
**긍정:** STATUSES 상수, 각 전이 메서드(`submit!`, `score!`, `complete!`, `fail!`), defaults 콜백이 명확하다.
**문제점 (High):** 상태 전이에 guard 없음. 예: `fail!` 이후에도 `complete!` 호출이 가능하다.
`AASM` 같은 상태 머신 gem 없이 수동 guard를 추가하지 않으면 상태 오염 위험이 있다.
**문제점 (Medium):** `all_questions_answered?`가 `responses.answered.count`와 `total_questions`를 각각 DB 호출한다.
`total_questions`는 `question_set.questions.active.count`로 별도 쿼리를 날린다.

#### 1-3. User
**긍정:** `has_secure_password`, `encrypts :email, deterministic: true`, soft delete(`deleted_at`).
**문제점 (Medium):** `scope :active` 는 있으나, soft delete된 사용자를 기본 스코프에서 자동 제외하지 않는다.
`default_scope { where(deleted_at: nil) }` 또는 `ApplicationRecord` 레벨 관례가 없으므로
쿼리에서 삭제된 사용자가 노출될 수 있다.

#### 1-4. QuestionSet
**긍정:** `activate!` 메서드가 트랜잭션으로 old active를 archived 처리한 후 신규 활성화한다. 잘 설계되어 있다.
**문제점 (Low):** `current` 클래스 메서드가 `nil`을 반환할 수 있는데, 호출 측(SessionsController, AssessmentsController)이 nil 체크 없이 `assessment = anonymous_session.assessments.create!(question_set: question_set, ...)` 로 진행한다.
`QuestionSet`이 없는 환경에서 500 에러 발생.

#### 1-5. DomainScore
**문제점 (Low):** `raw_score` 컬럼이 `float`인데 정수 스코어를 저장한다.
`integer`가 더 적절하며, DB 레벨 제약(0 이상)이 없다.

#### 1-6. Profile
**긍정:** `delegate`로 PersonalityType 필드를 위임한다.
**문제점 (Medium):** `score_vector`가 JSON 컬럼으로 저장되며, 타입 안전성이 없다.
키가 문자열인지 심볼인지 혼재 가능성이 있다
(factory에서는 `{ energy: 72, ... }` 심볼 키, 서비스에서는 `"energy"` 문자열 키).

#### 1-7. Consent
**문제점 (Medium):** `consent_params`에서 `:version` 파라미터를 허용하지만 모델에는 `consent_version` 컬럼이다.
이름 불일치로 인해 `consent_version`이 파라미터로 갱신되지 않는다 (ConsentsController#update 참조).

#### 1-8. 전반 모델 평가
**긍정:** 대부분 모델에 `STATUSES`/`TYPES` 상수 + `inclusion` 검증, `before_validation` 설정 전략, 의미 있는 스코프 등 Rails 관례가 잘 지켜져 있다. `frozen_string_literal`은 서비스에는 적용되어 있으나 모델 파일에는 없다(Low).

---

### 2. 컨트롤러 레이어 분석

#### 2-1. ResultsController — Fat Controller (Critical)

**현재 상태:** `show` 액션에서 `run_scoring_pipeline!`을 호출하며, 이 메서드가 약 50줄에 달하는
채점 파이프라인(8단계: raw score → normalize → classify → reliability → persist domain_scores → policy → compose profile → generate insights)을 직접 포함하고 있다.

**문제점:**
1. **SRP 위반:** 컨트롤러는 HTTP 요청/응답을 조율해야 하지, 도메인 로직을 실행하면 안 된다.
2. **테스트 불가:** `run_scoring_pipeline!`을 단독으로 단위 테스트할 방법이 없다.
3. **`redirect_to` in rescue 블록 위험:** `rescue StandardError`에서 `redirect_to`를 호출하면 컨트롤러 렌더 사이클에 의해 `AbstractController::DoubleRenderError`가 발생할 수 있다.
   `show` 액션의 정상 경로에서 이미 렌더가 일어난 후 rescue가 실행되면 이중 렌더 문제가 된다.

**개선 건의:**
```ruby
# app/services/scoring/assessment_pipeline.rb
class Scoring::AssessmentPipeline
  def initialize(assessment); @assessment = assessment; end
  def call; ...; end  # run_scoring_pipeline! 로직을 여기로 이전
end

# ResultsController#show
def show
  @assessment = current_session.assessments.find(params[:assessment_id])
  Scoring::AssessmentPipeline.new(@assessment).call if @assessment.status == "submitted"
  # ...
end
```
이중 렌더 문제 해결을 위해 rescue는 `show` 밖 `rescue_from`으로 이동하거나 `return` 후 렌더링해야 한다.

#### 2-2. AssessmentsController#create — 오류 처리 부재 (High)

**현재 상태:**
```ruby
assessment = current_session.assessments.create!(...)
first_question = assessment.question_set.questions.ordered.first
redirect_to assessment_question_path(assessment, first_question)
```
`create!`가 예외를 던지면 500 페이지가 노출된다.
`first_question`이 nil일 경우(빈 QuestionSet) `assessment_question_path`가 `nil`에 대해 라우트 에러를 낸다.

#### 2-3. SessionsController#create — 중복 로직 (Medium)

**현재 상태:** SessionsController와 AssessmentsController 둘 다 QuestionSet.current를 조회하고 첫 질문으로 redirect한다. 로직이 두 곳에 중복되어 있다.
Assessment 생성 흐름이 바뀌면 두 곳을 모두 수정해야 한다.

#### 2-4. ConsentsController — 파라미터 이름 불일치 (Medium)

```ruby
def consent_params
  params.require(:consent).permit(:consent_type, :version, :granted)
end
```
모델의 컬럼은 `consent_version`이지만 허용 파라미터는 `:version`이다. 폼에서 `consent_version`을 전송해도 strong parameters에서 걸러진다. 실질적으로 `consent_version`이 업데이트되지 않는다.

#### 2-5. Admin::BaseController — HTTP Basic 인증 (High, 보안)

**현재 상태:**
```ruby
http_basic_authenticate_with(
  name: ENV.fetch("ADMIN_USERNAME", "admin"),
  password: ENV.fetch("ADMIN_PASSWORD") { Rails.env.production? ? raise(...) : "dev-admin-password" }
)
```
**문제점:**
- HTTP Basic 인증은 HTTPS 없이는 Base64 인코딩만 되어 평문 노출된다.
- 단일 계정으로 모든 어드민이 공유 → 감사 추적 불가.
- 브루트포스 방어(rate limit, 잠금)가 없다.
- 프로덕션에서 `ADMIN_PASSWORD` 미설정 시 기동 실패 처리는 올바르나, 배포 파이프라인이 이를 검증해야 한다.

**개선 건의:** Devise + Role 기반 어드민 인증, 또는 최소한 IP Allowlist + HTTPS 강제.

#### 2-6. 전반 컨트롤러 평가
**긍정:**
- 모든 `before_action :set_*`가 `current_session.assessments.find`로 세션 스코핑 → 권한 확인이 implicit하게 처리됨.
- `permit`으로 strong parameters가 대부분 적용되어 있음.
- RESTful 설계 전반적으로 준수.

---

### 3. 서비스 레이어 분석

#### 3-1. 전반 평가 (긍정)
- 모든 서비스 파일에 `# frozen_string_literal: true` 적용.
- `initialize(resource)` + `#call` 인터페이스로 일관성 유지.
- 모듈별 네임스페이스(Scoring, Profiles, Insights, Compliance, Quality) 분리가 명확.
- 서비스 간 의존성 방향이 명확: Insights → Profiles → Scoring 순서로 단방향.
- 각 서비스 파일 상단에 Usage 예시 주석이 있어 가독성이 높다.

#### 3-2. ReliabilityAdjuster — N+1 방어 (긍정)
```ruby
def responses_with_questions
  @responses_with_questions ||= assessment.responses.includes(:question).to_a
end
```
`includes(:question)`로 eager loading + 메모이제이션. DomainCalculator도 동일 패턴. 잘 구현되어 있다.

#### 3-3. Insights 모듈 간 코드 중복 (Medium)
**현재 상태:** CollaborationModule, CareerModule, ConflictModule, LearningModule, RecoveryModule이 각각 동일한 패턴을 가진다:
- `score_vector`, `energy_score`, `relationship_score`, `decision_making_score`, `recovery_score` 메서드
- `build_suggestions` + `build_explanation` 패턴
- `ExplanationBuilder` 호출

**개선 건의:** `Insights::BaseModule`을 도입하고 공통 accessor를 추출하라.
```ruby
module Insights
  class BaseModule
    attr_reader :profile
    def initialize(profile); @profile = profile; end
    private
    def score_vector = profile.score_vector || {}
    def energy_score = score_vector["energy"].to_f
    # ...
  end
end
```

#### 3-4. Profiles::Composer — generate_suggested_actions 길이 (Low)
`generate_suggested_actions`가 40줄 이상이며, `strong_domain_action`과 `growth_domain_action`을 포함하면 해당 메서드들도 길다. 데이터(행동 텍스트)와 로직(스코어 임계값 판단)이 혼재되어 있다.
**개선 건의:** 텍스트 템플릿을 상수 해시로 분리하거나, `PersonalityType` 모델의 DB 데이터에서 가져오도록 이전.

#### 3-5. Scoring::PolicyChecker — 중복 계산 위험 (Low)
`PolicyChecker`가 `reliability_result`를 받지 않으면 `ReliabilityAdjuster.new(assessment).call`을 내부에서 재호출한다. `ResultsController`의 파이프라인에서는 이미 계산된 값을 전달하지만, 단독 호출 시 중복 계산이 발생할 수 있다.

#### 3-6. Compliance::DeletionProcessor — profiles 이중 삭제 위험 (Medium)
**현재 상태:**
```ruby
# Per-assessment children 루프
if assessment.profile
  # insight + profile 삭제
end
# 이후 session.profiles.find_each do |profile|
#   insight + profile 삭제
```
`assessment.profile`과 `session.profiles`가 겹칠 수 있다(Profile이 `anonymous_session_id`와 `assessment_id` 둘 다 가짐).
만약 Profile이 이미 assessment 루프에서 삭제되었는데 session.profiles에도 남아 있다면
`destroy!`가 RecordNotFound를 던져 트랜잭션 전체가 롤백된다.
실제로 schema상 `profiles.assessment_id`에 unique index가 있어 assessment당 하나의 profile만 존재하며
`session.profiles`는 같은 프로파일을 포함하므로, 위 이중 삭제 경로가 실행되면 에러가 발생한다.

**개선 건의:**
```ruby
# assessment.profile을 삭제한 profile_ids를 추적하고
# session.profiles에서 이미 삭제된 것은 건너뛰기
deleted_profile_ids = Set.new
```

---

### 4. 테스트 커버리지 분석

#### 4-1. 커버리지 현황
| 레이어 | 커버 여부 |
|--------|----------|
| 서비스 (Scoring 5개) | 모두 커버됨 (spec 존재) |
| 서비스 (Compliance 3개) | 모두 커버됨 |
| 서비스 (Profiles 2개) | composer_spec, tone_filter_spec 존재 |
| 서비스 (Quality 2개) | bot_detector_spec, speed_analyzer_spec 존재 |
| 서비스 (Insights 1개) | context_engine_spec만 존재; 개별 모듈 spec 없음 |
| 모델 | assessment_spec, personality_type_spec만 존재 |
| 요청/통합 | full_flow_spec (엔드투엔드), sessions_spec |
| 컨트롤러 | **없음** |
| 뷰 | **없음** |
| 라우팅 | **없음** |

#### 4-2. 핵심 공백 (High)
- **컨트롤러 spec 없음:** ResultsController의 `run_scoring_pipeline!`이 에러를 낼 때의 동작, DeletionRequestsController의 삭제 요청 흐름, ConsentsController의 파라미터 이름 불일치 버그 등이 테스트로 검증되지 않는다.
- **모델 spec 공백:** AnonymousSession, User, Consent, DeletionRequest, Response, Profile, Insight 모델에 spec이 없다. 특히 Consent의 `has_session_or_user` 커스텀 검증, User의 암호화 필드가 미검증.
- **Insights 모듈 개별 spec 없음:** CollaborationModule, CareerModule 등 5개 모듈의 분기 로직(점수 임계값에 따른 제안 텍스트 분기)이 context_engine_spec의 통합 경로로만 간접 테스트.

#### 4-3. full_flow_spec 평가 (긍정)
`spec/requests/full_flow_spec.rb`는 세션 생성 → 질문 응답 → 제출 → 결과 조회 전 과정을 실제 seeds 데이터로 검증한다. 엔드투엔드 커버리지로서 MVP에 필요한 핵심 경로를 잘 커버한다.
다만 `before(:all) { Rails.application.load_seed }`를 사용하여 테스트 간 상태가 공유될 수 있다. `before(:each)`로 변경하거나 DatabaseCleaner + 트랜잭션 전략이 필요하다.

---

### 5. 성능 분석

#### 5-1. N+1 쿼리 방어 (긍정)
- `Scoring::DomainCalculator`, `Scoring::ReliabilityAdjuster`가 모두 `assessment.responses.includes(:question).to_a`로 eager loading.
- `Scoring::Normalizer`가 `responses.answered.joins(:question).group("questions.domain").count`로 단일 집계 쿼리 사용.

#### 5-2. Admin::DashboardController — 인덱스 미활용 가능 (Medium)
```ruby
@rates = Assessment
  .group(:question_set_id)
  .select("question_set_id", "COUNT(*)", "SUM(CASE WHEN status = 'completed' ...)")
```
`assessments.question_set_id`에는 인덱스가 있다. 그러나 `status` 컬럼에는 인덱스가 없다.
`Assessment.where(status: :completed).count` 쿼리가 풀 테이블 스캔이 된다.
**개선 건의:** `add_index :assessments, :status` 추가.

#### 5-3. Admin::AuditLogsController — 페이지네이션 없음 (Medium)
```ruby
@audit_logs = AuditLog.order(created_at: :desc)
```
페이지네이션 없이 전체 audit_log를 로드한다. 운영 환경에서 수만 건이 되면 메모리 및 응답 시간 문제.
**개선 건의:** `pagy`, `kaminari` 등 페이지네이션 gem 도입 또는 `.limit(100)` 강제.

#### 5-4. Admin::AlertsController — 페이지네이션 없음 (Low)
동일 문제.

#### 5-5. ResultsController — 트랜잭션 범위 적절 (긍정)
`run_scoring_pipeline!` 전체가 `ActiveRecord::Base.transaction` 으로 묶여 있어, 파이프라인 중간 실패 시 부분 상태가 남지 않는다. 다만 이 트랜잭션이 컨트롤러에 있어야 하는지는 별개 문제(Fat Controller 참조).

#### 5-6. Assessment#current_question — 잠재적 N+1 (Low)
```ruby
def current_question
  question_set.questions.active.ordered.offset(current_question_index).first
end
```
`question_set`이 eager load되지 않은 컨텍스트에서 호출되면 N+1. AssessmentQuestionsController에서는 `set_assessment`로 단일 assessment를 로드하므로 실제 N+1은 아니지만, 배치 처리 시 위험.

---

### 6. 보안 분석

#### 6-1. 세션 스코핑 — 암묵적 인가 (긍정)
```ruby
@assessment = current_session.assessments.find(params[:assessment_id])
```
`current_session`을 통해 찾으므로, 다른 세션의 assessment에 접근하면 자동으로 RecordNotFound → 404.
컨트롤러 전반에 일관되게 적용되어 있다.

#### 6-2. AnonymousSession 세션 고정 공격 방어 없음 (High)
**현재 상태:** `SessionsController#create`에서 `session[:session_token] = anonymous_session.session_token`을 설정하지만, 이전 세션을 `reset_session`으로 무효화하지 않는다.
세션 고정(Session Fixation) 공격 가능성.
**개선 건의:**
```ruby
reset_session
session[:session_token] = anonymous_session.session_token
```

#### 6-3. IP 핑거프린팅 — 개인정보 처리 (Medium)
```ruby
fingerprint = Digest::SHA256.hexdigest("#{request.remote_ip}:#{request.user_agent}")
```
IP + User-Agent를 해시화하여 저장한다. SHA-256 단방향 해시이므로 역추적이 어렵지만,
Salt 없는 고정 해시이므로 Rainbow Table로 원래 IP를 추론 가능.
GDPR 관점에서 "개인정보"로 간주될 수 있다.
**개선 건의:** 랜덤 Salt 추가 또는 IP 저장 자체를 제거 (사업 요건에 따라).

#### 6-4. CSRF 보호 (긍정)
`ActionController::Base` 상속으로 Rails 기본 CSRF 보호(`protect_from_forgery with: :exception`) 적용. Turbo와 함께 사용 시 Rails 7+는 자동으로 CSRF 토큰을 처리한다.

#### 6-5. XSS 방어 (긍정)
ERB의 기본 HTML 이스케이프 + `Compliance::TextPolicyFilter`로 사용자 노출 텍스트를 필터링. 이중 방어.

#### 6-6. SQL Injection (긍정)
ActiveRecord ORM 사용, 직접 SQL 없음. `where` 절에 파라미터 바인딩 사용.

#### 6-7. `consent_text_snapshot` 미저장 문제 (Medium, 법적 위험)
**현재 상태:** ConsentsController에서 `consent_text_snapshot ||= default_consent_text(...)` 로 설정하나, `consent_params`에 `consent_text_snapshot`이 허용되어 있지 않아 폼에서 오는 실제 텍스트는 저장되지 않는다. `default_consent_text`로만 저장된다.
법적으로 사용자가 실제로 동의한 텍스트의 스냅샷을 저장해야 하는데, 동적으로 변하는 텍스트가 있을 경우 증거가 불충분해진다.

#### 6-8. 삭제 요청 처리 — 비동기 미구현 (Medium)
```ruby
# In production: DeletionJob.perform_later(@deletion_request.id)
```
현재 DeletionProcessor가 백그라운드에서 호출되지 않는다. SLA 7일 카운트다운이 시작되지만 실제 삭제는 수동 또는 job 없이는 실행되지 않는다. `scope :overdue`가 있지만 이를 처리하는 스케줄러/job이 없다.

---

### 7. 라우팅/설정 분석

#### 7-1. routes.rb 전반 평가
```ruby
resources :results, only: [:show], param: :assessment_id
```
**문제점 (Medium):** `results`를 `resources`로 선언했는데 실제로는 결과가 assessment의 하위 자원이다.
`resources :assessments do; resource :result, only: [:show]; end` 형태가 RESTful 관례에 더 부합한다.
현재 구조에서 `/results/:assessment_id`는 다소 어색하다.

```ruby
resource :session, only: [:new, :create]
resource :account, only: [:new, :create]
```
singular resource 사용은 적절하다.

```ruby
resources :assessments, only: [:create, :show] do
  member { patch :submit }
  resources :questions, only: [:show, :update], controller: "assessment_questions"
end
```
**긍정:** 중첩 라우팅과 커스텀 액션 설계가 명확하다.

#### 7-2. Gemfile 분석
**긍정:** Rails 8.1, Solid Cache/Queue/Cable(DB-backed), Propshaft, Turbo/Stimulus, Tailwind, bcrypt, 암호화를 위한 기본 설정.
**문제점 (Medium):** 개발/테스트 환경에서 `sqlite3`를 사용하고 프로덕션에서 `pg`를 쓰는 구성. DB 간 동작 차이(JSON 연산, 인덱스 동작 등)로 인해 로컬에서 통과된 쿼리가 프로덕션에서 다르게 동작할 수 있다.
**문제점 (Low):** `pagy`나 `kaminari` 같은 페이지네이션 gem이 없다. Admin 페이지에서 필요.
**문제점 (Low):** `simplecov`가 없어 테스트 커버리지 수치를 알 수 없다.

---

## Key Findings

- **Critical — Fat Controller:** `ResultsController#run_scoring_pipeline!` (50줄 파이프라인)이 컨트롤러에 위치. 단위 테스트 불가, SRP 위반, rescue 내 이중 렌더 위험.
- **High — 상태 전이 guard 없음:** `Assessment`의 상태 전이 메서드에 guard가 없어 `fail! → complete!` 같은 잘못된 전이가 허용된다.
- **High — 세션 고정 공격 방어 없음:** `SessionsController#create`에서 `reset_session`을 호출하지 않아 세션 고정 공격 가능성 존재.
- **High — HTTP Basic 인증:** Admin 전체가 HTTP Basic으로만 보호됨. HTTPS 미강제 환경에서 자격 증명 노출 위험, 브루트포스 방어 없음.
- **High — 컨트롤러 테스트 부재:** 12개 컨트롤러 중 request spec이 실질적으로 없음 (sessions_spec, full_flow_spec이 일부 경로만 커버).
- **Medium — ConsentsController 파라미터 이름 불일치:** `:version` vs `consent_version` 불일치로 consent_version이 업데이트되지 않는 버그.
- **Medium — DeletionProcessor 이중 삭제 위험:** assessment.profile과 session.profiles 중복 순회로 이미 삭제된 Profile에 destroy!를 재호출 가능.
- **Medium — SQLite(dev) vs PostgreSQL(prod) 불일치:** JSON 연산, 인덱스 동작 등에서 환경별 차이 발생 가능.
- **Medium — Admin 페이지 페이지네이션 없음:** AuditLog, Alert을 전체 로드.
- **Low — assessments.status 인덱스 없음:** `WHERE status = 'completed'` 쿼리가 풀 스캔.
- **Low — Insights 모듈 코드 중복:** 5개 모듈에 동일 패턴 반복.
- **Low — spec/factories.rb의 profile factory:** `score_vector`에 심볼 키 사용 (`{ energy: 72 }`). 서비스 코드는 문자열 키 `"energy"` 를 사용하여 불일치.

---

## Recommendations

### 즉시 수정 (Critical/High)

1. **`run_scoring_pipeline!`을 `Scoring::AssessmentPipeline` 서비스로 이전**
   `ResultsController`는 `Scoring::AssessmentPipeline.new(@assessment).call`만 호출.
   rescue 로직도 서비스 내부로 이동하거나 `rescue_from`으로 컨트롤러에서 처리.

2. **`SessionsController#create`에 `reset_session` 추가**
   ```ruby
   reset_session
   session[:session_token] = anonymous_session.session_token
   ```

3. **Admin 인증 강화**
   최소한 IP Allowlist + HTTPS 강제. 중기적으로 Devise + role 기반으로 전환.

4. **Assessment 상태 전이 guard 추가**
   각 전이 메서드에 현재 상태 검증 추가 또는 `AASM` gem 도입.

### 단기 수정 (Medium)

5. **ConsentsController `consent_params` 수정**
   `:version` → `:consent_version`으로 수정.

6. **DeletionProcessor 이중 삭제 방지**
   assessment 루프에서 삭제한 profile_id를 Set으로 추적하고 session.profiles에서 건너뛰기.

7. **결과 라우팅 재설계**
   `resources :assessments do; resource :result, only: [:show]; end`

8. **Admin 페이지에 페이지네이션 적용**
   AuditLogsController, AlertsController에 `.limit` 또는 pagy 적용.

### 중기 개선 (Low/Architecture)

9. **`Insights::BaseModule` 추출** — 5개 insight 모듈의 중복 accessor 제거.

10. **`simplecov` 추가** — 커버리지 측정 후 목표치(80%+) 설정.

11. **컨트롤러 request spec 추가** — 특히 DeletionRequestsController, ConsentsController, ResultsController 에러 경로.

12. **assessments.status 인덱스 추가**
    `add_index :assessments, :status`

13. **개발 환경 PostgreSQL 사용 통일** — docker-compose 또는 `.devcontainer` 구성으로 dev/prod DB 일치.

14. **profile factory의 score_vector 키 통일** — `{ "energy" => 72, ... }` 문자열 키로 수정.

---

## References

- `/Users/kampikrein/A/personality/app/controllers/results_controller.rb`
- `/Users/kampikrein/A/personality/app/controllers/sessions_controller.rb`
- `/Users/kampikrein/A/personality/app/controllers/consents_controller.rb`
- `/Users/kampikrein/A/personality/app/controllers/admin/base_controller.rb`
- `/Users/kampikrein/A/personality/app/controllers/admin/dashboard_controller.rb`
- `/Users/kampikrein/A/personality/app/controllers/admin/audit_logs_controller.rb`
- `/Users/kampikrein/A/personality/app/models/assessment.rb`
- `/Users/kampikrein/A/personality/app/models/anonymous_session.rb`
- `/Users/kampikrein/A/personality/app/models/user.rb`
- `/Users/kampikrein/A/personality/app/models/consent.rb`
- `/Users/kampikrein/A/personality/app/models/profile.rb`
- `/Users/kampikrein/A/personality/app/services/scoring/domain_calculator.rb`
- `/Users/kampikrein/A/personality/app/services/scoring/reliability_adjuster.rb`
- `/Users/kampikrein/A/personality/app/services/compliance/deletion_processor.rb`
- `/Users/kampikrein/A/personality/app/services/insights/collaboration_module.rb`
- `/Users/kampikrein/A/personality/app/services/insights/context_engine.rb`
- `/Users/kampikrein/A/personality/app/services/profiles/composer.rb`
- `/Users/kampikrein/A/personality/config/routes.rb`
- `/Users/kampikrein/A/personality/Gemfile`
- `/Users/kampikrein/A/personality/db/schema.rb`
- `/Users/kampikrein/A/personality/spec/factories.rb`
- `/Users/kampikrein/A/personality/spec/requests/full_flow_spec.rb`
- `/Users/kampikrein/A/personality/spec/models/assessment_spec.rb`
