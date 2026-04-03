---
id: "002"
title: "프로젝트 구조 및 아키텍처 분석"
category: agent
status: archived
created: 2026-03-11
summary: >
  personality Rails 8.1 프로젝트의 MVC 아키텍처, Admin 네임스페이스 분리, 세션 기반 인증,
  라우팅 구조, 뷰 레이아웃, 서비스 레이어 패턴을 초보자 관점에서 상세 분석.
keywords: [agent-report, architecture, MVC, routing, authentication, admin, service-layer]
modules: [controllers, views, routes]
---

# 프로젝트 구조 및 아키텍처 분석

## 요약

personality는 Rails 8.1의 MVC 패턴을 충실히 따르면서도, 익명 세션 기반으로 회원가입 없이 성격검사를 진행할 수 있는 구조가 핵심 특징이다. Admin 기능은 별도 네임스페이스와 HTTP Basic Auth로 완전히 분리되어 있고, 결과 페이지에서 서비스 레이어(Scoring, Profiles, Insights)를 컨트롤러가 직접 순차 호출하는 인라인 파이프라인 패턴을 사용하고 있다.

---

## 상세 분석

### 1. Rails MVC 아키텍처 구현 방식

Rails MVC는 **Model(데이터) - View(화면) - Controller(요청 처리)** 세 계층으로 웹 애플리케이션을 구성한다. 이 프로젝트에서 각 계층이 어떻게 협력하는지 실제 흐름으로 설명한다.

**요청 흐름 예시 — 질문 답변 저장:**

1. 사용자가 질문에 답변 후 제출 → `PATCH /assessments/:assessment_id/questions/:id`
2. Rails 라우터가 `AssessmentQuestionsController#update`로 라우팅
3. 컨트롤러가 모델을 조작:

```ruby
# app/controllers/assessment_questions_controller.rb:17-24
response = @assessment.responses.find_or_initialize_by(question: @question)
response.assign_attributes(
  response_params.merge(sequence_number: @assessment.current_question_index)
)
if response.save
  next_question = @assessment.advance_to_next_question!
```

4. 저장 성공 시 다음 질문 뷰로 redirect, 실패 시 `:show` 뷰 재렌더링

**before_action으로 공통 전처리 분리:**

```ruby
# app/controllers/assessment_questions_controller.rb:2-3
before_action :set_assessment
before_action :set_question
```

`set_assessment`와 `set_question`이라는 private 메서드를 모든 액션 전에 자동 실행하여 `@assessment`, `@question` 인스턴스 변수를 세팅한다. 컨트롤러에서 설정한 인스턴스 변수(`@`로 시작)는 자동으로 뷰에서 접근 가능하다.

**strong parameters — 보안 필터링:**

```ruby
# app/controllers/assessment_questions_controller.rb:46-48
def response_params
  params.require(:response).permit(:value, :response_time_ms)
end
```

사용자 입력 중 `:value`, `:response_time_ms`만 허용하고 나머지는 자동 차단한다.

---

### 2. Admin 네임스페이스 분리

Rails의 `namespace`는 URL 접두사, 모듈(Ruby module), 디렉토리를 한 번에 분리하는 방법이다.

**BaseController의 역할 — 인증 + 레이아웃 통합:**

```ruby
# app/controllers/admin/base_controller.rb:1-13
module Admin
  class BaseController < ApplicationController
    skip_before_action :require_session!

    http_basic_authenticate_with(
      name: ENV.fetch("ADMIN_USERNAME", "admin"),
      password: ENV.fetch("ADMIN_PASSWORD") { Rails.env.production? ? (raise "ADMIN_PASSWORD is required") : "dev-admin-password" },
      realm: "Admin"
    )

    layout "admin"
  end
end
```

세 가지 핵심 역할:
- `skip_before_action :require_session!` — 일반 사용자용 익명 세션 체크를 건너뜀
- `http_basic_authenticate_with` — 브라우저 팝업 방식의 HTTP Basic Auth 적용. 환경변수 `ADMIN_USERNAME` / `ADMIN_PASSWORD`로 자격증명을 설정. 프로덕션에서 `ADMIN_PASSWORD`가 없으면 앱이 시작 자체를 거부
- `layout "admin"` — `app/views/layouts/admin.html.erb`를 사용하도록 강제

**상속 구조:**

```
ApplicationController
    └── Admin::BaseController       # admin 공통 인증/레이아웃
            ├── Admin::DashboardController
            ├── Admin::AlertsController
            ├── Admin::AuditLogsController
            └── Admin::QuestionSetsController
```

모든 Admin 컨트롤러가 `BaseController`를 상속하므로, HTTP Basic Auth 한 곳에만 정의해도 모든 admin 경로에 일괄 적용된다.

**파일 위치도 네임스페이스를 반영:**

```
app/controllers/
├── application_controller.rb
├── assessments_controller.rb
└── admin/
    ├── base_controller.rb
    ├── dashboard_controller.rb
    ├── alerts_controller.rb
    ├── audit_logs_controller.rb
    └── question_sets_controller.rb
```

---

### 3. 인증 흐름

이 프로젝트는 `has_secure_password` 기반의 일반 로그인이 **주요 흐름이 아니다**. 핵심은 **익명 세션 기반 인증**이다.

**흐름 단계별 분석:**

**Step 1 — 랜딩 페이지 진입:**

```ruby
# config/routes.rb:2
root "sessions#new"
```

사이트 루트(`/`)에 접근하면 `SessionsController#new`가 실행되어 랜딩 페이지를 렌더링한다.

**Step 2 — "시작하기" 버튼 → 익명 세션 생성:**

```ruby
# app/controllers/sessions_controller.rb:14-37
def create
  fingerprint = Digest::SHA256.hexdigest(
    "#{request.remote_ip}:#{request.user_agent}"
  )

  anonymous_session = AnonymousSession.create!(
    session_token: SecureRandom.uuid,
    ip_fingerprint: fingerprint,
    started_at: Time.current
  )

  session[:session_token] = anonymous_session.session_token
  ...
end
```

- UUID 기반 `session_token` 생성 후 DB에 `AnonymousSession` 레코드 저장
- IP + User-Agent를 SHA256으로 해싱하여 `ip_fingerprint` 저장 (개인정보 최소화)
- Rails 세션 쿠키에 `session_token`을 저장 → 이후 모든 요청에서 이 쿠키로 사용자 식별

**Step 3 — 세션 검증 (require_session!):**

```ruby
# app/controllers/application_controller.rb:8
before_action :require_session!

# app/controllers/application_controller.rb:25-30
def require_session!
  return if current_session.present?
  return if self.class == SessionsController

  redirect_to new_session_path, alert: "Please start a session first."
end
```

모든 컨트롤러 액션 전에 쿠키의 `session_token`으로 `AnonymousSession`을 조회한다. 세션이 없으면 랜딩 페이지로 리다이렉트. `SessionsController` 자체는 예외 처리(`return if self.class == SessionsController`)하여 무한 리다이렉트를 방지한다.

**선택적 계정 생성 (User 등록):**

```ruby
# app/controllers/accounts_controller.rb:12-17
def create
  @user = User.new(account_params)
  if @user.save
    current_session.update!(user: @user)
    redirect_to root_path, notice: "Account created successfully."
  end
end
```

검사 완료 후 사용자가 원하면 이메일+비밀번호로 계정을 만들고 기존 익명 세션에 연결할 수 있다. `has_secure_password`는 `User` 모델에 존재하지만 로그인은 선택 사항이다.

**Admin 인증은 별개:** HTTP Basic Auth (브라우저 팝업), 환경변수 기반.

---

### 4. 라우팅 패턴 전체 구조

```ruby
# config/routes.rb (전체)
Rails.application.routes.draw do
  root "sessions#new"
  resource :session, only: [:new, :create]

  resources :assessments, only: [:create, :show] do
    member { patch :submit }
    resources :questions, only: [:show, :update],
              controller: "assessment_questions"
  end

  resources :results, only: [:show], param: :assessment_id
  resource :account, only: [:new, :create]
  resources :consents, only: [:new, :create, :show, :update]
  resources :deletion_requests, only: [:new, :create, :show]

  namespace :admin do
    root "dashboard#index"
    resource :dashboard, only: [] do
      get :completion_rates
      get :drop_off_analysis
    end
    resources :question_sets
    resources :alerts, only: [:index, :show, :update]
    resources :audit_logs, only: [:index, :show]
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
```

**생성되는 라우트 전체 목록:**

| Method | Path | Controller#Action | 설명 |
|--------|------|-------------------|------|
| GET | `/` | sessions#new | 랜딩 페이지 |
| POST | `/session` | sessions#create | 익명 세션 생성 |
| POST | `/assessments` | assessments#create | 검사 생성 |
| GET | `/assessments/:id` | assessments#show | 검사 화면 |
| PATCH | `/assessments/:id/submit` | assessments#submit | 검사 제출 |
| GET | `/assessments/:assessment_id/questions/:id` | assessment_questions#show | 질문 표시 |
| PATCH | `/assessments/:assessment_id/questions/:id` | assessment_questions#update | 답변 저장 |
| GET | `/results/:assessment_id` | results#show | 결과 표시 |
| GET | `/account/new` | accounts#new | 계정 생성 폼 |
| POST | `/account` | accounts#create | 계정 생성 |
| GET | `/consents/new` | consents#new | 동의 폼 |
| POST | `/consents` | consents#create | 동의 저장 |
| GET | `/consents/:id` | consents#show | 동의 상세 |
| PATCH | `/consents/:id` | consents#update | 동의 수정 |
| GET | `/deletion_requests/new` | deletion_requests#new | 삭제 요청 폼 |
| POST | `/deletion_requests` | deletion_requests#create | 삭제 요청 생성 |
| GET | `/deletion_requests/:id` | deletion_requests#show | 삭제 요청 상태 |
| GET | `/admin` | admin/dashboard#index | 관리자 대시보드 |
| GET | `/admin/dashboard/completion_rates` | admin/dashboard#completion_rates | 완료율 분석 |
| GET | `/admin/dashboard/drop_off_analysis` | admin/dashboard#drop_off_analysis | 이탈 분석 |
| GET | `/admin/question_sets` | admin/question_sets#index | 문항 세트 목록 |
| GET | `/admin/question_sets/new` | admin/question_sets#new | 문항 세트 생성 폼 |
| POST | `/admin/question_sets` | admin/question_sets#create | 문항 세트 생성 |
| GET | `/admin/question_sets/:id` | admin/question_sets#show | 문항 세트 상세 |
| GET | `/admin/question_sets/:id/edit` | admin/question_sets#edit | 문항 세트 수정 폼 |
| PATCH | `/admin/question_sets/:id` | admin/question_sets#update | 문항 세트 수정 |
| DELETE | `/admin/question_sets/:id` | admin/question_sets#destroy | 문항 세트 삭제 |
| GET | `/admin/alerts` | admin/alerts#index | 알림 목록 |
| GET | `/admin/alerts/:id` | admin/alerts#show | 알림 상세 |
| PATCH | `/admin/alerts/:id` | admin/alerts#update | 알림 상태 변경 |
| GET | `/admin/audit_logs` | admin/audit_logs#index | 감사 로그 목록 |
| GET | `/admin/audit_logs/:id` | admin/audit_logs#show | 감사 로그 상세 |
| GET | `/up` | rails/health#show | 헬스 체크 |

**주요 라우팅 패턴:**

- **`resource` vs `resources`**: `resource :session`은 단수형(개인 고유 자원이므로 ID 없음, `/session`). `resources :assessments`는 복수형(ID 포함, `/assessments/:id`).
- **Nested routes**: `assessments` 안에 `questions`를 중첩. `/assessments/:assessment_id/questions/:id` 구조로 소속 관계를 URL에 표현.
- **Member route**: `member { patch :submit }` — 특정 리소스 하나에 대한 커스텀 액션. `/assessments/:id/submit`.
- **`param: :assessment_id`**: `results`의 URL 파라미터 이름을 기본 `:id` 대신 `:assessment_id`로 변경. `GET /results/:assessment_id`.
- **`only:`**: 7개 RESTful 액션(index, show, new, create, edit, update, destroy) 중 필요한 것만 노출.

---

### 5. 뷰 레이아웃 구조

**application.html.erb vs admin.html.erb 비교:**

| 항목 | application.html.erb | admin.html.erb |
|------|---------------------|----------------|
| 대상 | 일반 사용자 | 관리자 |
| 네비게이션 | 조건부(`content_for?(:navbar)`) | 고정 상단 nav바 (Dashboard, Question Sets, Audit Logs, Site) |
| 컨테이너 최대폭 | `max-w-2xl` (640px, 모바일 친화적) | `max-w-6xl` (1280px, 넓은 데이터 표시) |
| Flash 처리 | Stimulus `dismissable` 컨트롤러 포함 | 단순 div |
| Trust Notice | `content_for?(:trust_notice)` 조건부 슬롯 | 없음 |
| 배경 | 없음(기본) | `bg-cream` |
| 폰트 | Pretendard 외부 폰트 로드 | 없음 |

**`yield` 작동 방식 (초보자 설명):**

```erb
<%# app/views/layouts/application.html.erb:43 %>
<%= yield %>
```

`yield`는 각 액션의 뷰 파일(`assessments/show.html.erb` 등) 내용을 이 위치에 삽입한다. 레이아웃이 "틀"이고, 개별 뷰가 "내용"이라고 이해하면 된다.

**`content_for` / `yield :name` 패턴:**

```erb
<%# 개별 뷰에서 선언 %>
<% content_for(:title, "나를 이해하는 새로운 방법") %>

<%# 레이아웃에서 수신 %>
<title><%= content_for(:title) || "Personality Profile" %></title>
```

이름이 붙은 슬롯으로 레이아웃의 특정 위치에 콘텐츠를 주입한다. `trust_notice`, `navbar`, `head`, `title` 슬롯이 있다.

**파셜 구조 (results 페이지):**

```erb
<%# app/views/results/show.html.erb:5-8 %>
<%= render "results/type_hero", profile: @profile %>
<%= render "results/spectrum", profile: @profile %>
...
<%= render "results/insight_card", insight: insight %>
<%= render "results/trust_notice" %>
```

`_` 접두사 파일(`_type_hero.html.erb`)이 파셜. `render "results/type_hero"` 호출 시 자동으로 언더스코어 파일을 찾는다. `locals:` 또는 직접 키워드 인자로 변수를 전달한다.

**Turbo Frame 활용 (assessments/show.html.erb):**

```erb
<%# app/views/assessments/show.html.erb:10-24 %>
<turbo-frame id="current_question" class="block">
  ...
  <%= button_to "결과 확인하기",
      submit_assessment_path(@assessment),
      method: :patch,
      data: { turbo_frame: "_top" },
      ... %>
</turbo-frame>
```

Hotwire Turbo Frame을 사용하여 질문이 바뀔 때 전체 페이지 리로드 없이 프레임 영역만 교체한다.

**Stimulus.js 컨트롤러 연결:**

```erb
<%# app/views/results/_type_hero.html.erb:1 %>
<div class="..." data-controller="type-reveal">
```

```erb
<%# app/views/results/_spectrum.html.erb:10 %>
<div class="space-y-5" data-controller="spectrum-bar">
```

`data-controller` 속성으로 JavaScript Stimulus 컨트롤러를 HTML 요소에 연결한다. `type-reveal`은 타입 코드 글자 순차 애니메이션, `spectrum-bar`는 스펙트럼 바 채우기 애니메이션을 담당한다.

---

### 6. 서비스 레이어 패턴

컨트롤러가 비즈니스 로직을 직접 갖지 않고 `app/services/` 내의 클래스에 위임하는 패턴이다.

**ResultsController의 인라인 파이프라인 — 가장 복잡한 서비스 호출 예:**

```ruby
# app/controllers/results_controller.rb:20-67
def run_scoring_pipeline!(assessment)
  ActiveRecord::Base.transaction do
    # Step 1: 원점수 계산
    raw_scores = Scoring::DomainCalculator.new(assessment).call

    # Step 2: 0-100 정규화
    normalized_scores = Scoring::Normalizer.new(assessment, raw_scores).call

    # Step 3: 유형 코드 분류
    classification = Scoring::TypeClassifier.new(assessment, normalized_scores).call

    # Step 4: 신뢰도 체크
    reliability = Scoring::ReliabilityAdjuster.new(assessment).call

    # Step 5: 도메인 점수 DB 저장
    normalized_scores.each do |domain, score|
      assessment.domain_scores.find_or_create_by!(domain: domain) do |ds|
        ds.raw_score = raw_scores[domain]
        ds.normalized_score = score || 0
        ...
      end
    end

    assessment.score!

    # Step 6: 정책 체크 (부정 응답 탐지)
    policy_result = Scoring::PolicyChecker.new(assessment, reliability).call
    if policy_result[:blocked]
      assessment.domain_scores.update_all(policy_blocked: true)
      assessment.fail!
      return
    end

    # Step 7: 프로필 생성
    Profiles::Composer.new(assessment, type_code: classification[:type_code]).call

    # Step 8: 컨텍스트별 인사이트 생성
    Insight::CONTEXTS.each do |context|
      Insights::ContextEngine.new(assessment.profile, context).call
    end

    assessment.complete!
  end
end
```

**서비스 클래스 호출 패턴 규칙:**

모든 서비스 클래스가 동일한 인터페이스를 따른다:

```ruby
ServiceClass.new(필요한_인자들).call
```

1. `new(...)` — 서비스 인스턴스 생성, 필요한 데이터 주입
2. `.call` — 서비스 실행, 결과 반환

이 패턴은 Rails 커뮤니티의 관례적 서비스 오브젝트 패턴이다.

**관련 서비스 모듈 목록:**

| 모듈 | 클래스 | 역할 |
|------|--------|------|
| `Scoring::` | `DomainCalculator` | 도메인별 원점수 계산 |
| `Scoring::` | `Normalizer` | 0-100 정규화 |
| `Scoring::` | `TypeClassifier` | MBTI-like 유형 코드 분류 |
| `Scoring::` | `ReliabilityAdjuster` | 응답 신뢰도 계산 |
| `Scoring::` | `PolicyChecker` | 부정 응답/정책 위반 탐지 |
| `Profiles::` | `Composer` | 성격 프로필 생성 |
| `Insights::` | `ContextEngine` | 컨텍스트별 인사이트 생성 |

**트랜잭션으로 감쌈:**

```ruby
# results_controller.rb:21
ActiveRecord::Base.transaction do
  ...
end
```

8단계 파이프라인 전체를 하나의 DB 트랜잭션으로 처리. 중간에 오류가 발생하면 모든 변경이 롤백된다.

---

### 7. 익명 사용자 지원 여부

**결론: 회원가입/로그인 없이 검사 완전 가능.**

```erb
<%# app/views/sessions/new.html.erb:23-25 %>
<p class="text-sm text-warm-gray/70">
  회원가입 없이 바로 시작할 수 있어요
</p>
```

"시작하기" 버튼 클릭 한 번으로 `POST /session` → 익명 세션 생성 → 첫 질문 화면으로 이동.

모든 검사, 응답, 동의, 삭제 요청 데이터가 `AnonymousSession`에 귀속된다. `User` 계정은 없어도 전체 흐름이 작동한다.

---

## 핵심 발견

- `AnonymousSession`이 전체 아키텍처의 중심 엔티티. User 없이 모든 기능이 작동하는 설계
- Admin 인증(`http_basic_authenticate_with`)과 일반 인증(`require_session!`)이 완전히 독립적으로 구현됨
- `ResultsController#run_scoring_pipeline!`이 8개 서비스를 순차 호출하는 단일 메서드. MVP에서 인라인 실행이며, 코드 주석에 Job 분리 계획이 명시됨
- `resource :session` (단수) vs `resources :assessments` (복수) 구분이 명확
- `app/helpers/application_helper.rb`가 완전히 비어 있음. 모든 뷰 헬퍼 로직이 파셜과 Stimulus로 처리됨
- `Procfile.dev`에 Rails 서버와 Tailwind CSS 워처 두 프로세스만 존재

---

## 초보자를 위한 핵심 포인트

1. **Rails는 "규칙이 설정"이다**: `resources :assessments`만 선언해도 Rails가 자동으로 7개 RESTful URL을 생성한다.

2. **`before_action`은 공통 전처리기다**: `require_session!`, `set_assessment` 같은 메서드를 각 액션에 반복하지 않고 한 번 선언으로 모든 액션 전에 자동 실행한다.

3. **`@`변수는 컨트롤러와 뷰를 연결한다**: 컨트롤러에서 `@assessment = ...`로 설정하면 뷰에서 자동으로 `@assessment`를 사용할 수 있다.

4. **Admin 네임스페이스 = URL + 모듈 + 디렉토리 분리**: `namespace :admin`은 단순히 URL에 `/admin`을 붙이는 것뿐 아니라, Ruby `module Admin`, 파일 경로 `controllers/admin/`까지 한 번에 분리한다.

5. **서비스 오브젝트는 "두꺼운 모델, 날씬한 컨트롤러"의 해법이다**: 복잡한 비즈니스 로직을 `app/services/` 클래스로 분리하고 `ServiceClass.new(args).call` 패턴으로 호출한다.

---

## 참조 파일

- `config/routes.rb`
- `app/controllers/application_controller.rb`
- `app/controllers/sessions_controller.rb`
- `app/controllers/assessments_controller.rb`
- `app/controllers/assessment_questions_controller.rb`
- `app/controllers/accounts_controller.rb`
- `app/controllers/results_controller.rb`
- `app/controllers/admin/base_controller.rb`
- `app/views/layouts/application.html.erb`
- `app/views/layouts/admin.html.erb`
- `app/views/sessions/new.html.erb`
- `app/views/assessments/show.html.erb`
- `app/views/results/show.html.erb`
