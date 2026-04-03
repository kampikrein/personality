---
id: "002"
type: agent
title: "Agent B: 컨트롤러 & 뷰 분석"
created: 2026-02-22
summary: >
  성격 서비스 Rails 프로젝트의 컨트롤러, 뷰, 라우트를 분석한 에이전트 리포트.
  사용자 플로우별 인증 처리와 주요 액션을 정리한다.
keywords: [Rails, 컨트롤러, 뷰, 코드점검]
---

# Agent B: 컨트롤러 & 뷰 분석

> 분석일: 2026-02-22
> 범위: `app/controllers/`, `app/views/`, `config/routes.rb`

## 1. 컨트롤러 목록

### 사용자 플로우
| 컨트롤러 | 주요 액션 | 인증 |
|----------|---------|------|
| SessionsController | new, create | 없음 (진입점) |
| AccountsController | new, create | 없음 |
| ConsentsController | new, create, show, update | require_session! |
| AssessmentsController | create, show | require_session! |
| AssessmentQuestionsController | show, update | require_session! |
| ResultsController | show | require_session! |
| DeletionRequestsController | new, create, show | require_session! |

### Admin
| 컨트롤러 | 주요 액션 | 인증 |
|----------|---------|------|
| Admin::BaseController | — | **없음 (CRITICAL)** |
| Admin::DashboardController | index, completion_rates, drop_off_analysis | 없음 |
| Admin::QuestionSetsController | CRUD | 없음 |
| Admin::AlertsController | index, show, update | 없음 |
| Admin::AuditLogsController | index, show | 없음 |

## 2. 발견된 이슈

### C-1: Admin 인증 없음 (CRITICAL)
- `Admin::BaseController`에 `skip_before_action :require_session!`만 존재
- 인증 코드가 주석 처리되어 있음
- **영향**: 누구나 `/admin`으로 모든 관리 기능 접근 가능
- **수정**: HTTP Basic Auth (ENV 기반) 추가

### C-3: 질문 폼 파라미터 불일치 (CRITICAL)
- **뷰** (`_question.html.erb:33`): `name="value"` — 최상위 파라미터로 전송
- **컨트롤러** (`assessment_questions_controller.rb:20`): `params[:response][:value]` 기대
- **영향**: 폼 제출 시 `NoMethodError: undefined method '[]' for nil`
- **수정**: `name="response[value]"`, hidden fields도 `response[...]`로 변경

### C-5: 동의 폼 완전 불일치 (CRITICAL)
- **뷰**: `name="consents[data_processing]"` — 중첩 해시
- **컨트롤러**: `params.require(:consent).permit(:consent_type, :version, :granted)` 기대
- **영향**: 동의 폼 제출 시 강제 파라미터 누락 에러
- **수정**: 폼을 컨트롤러 기대에 맞게 재작성

### H-5: strong params 미적용 (HIGH)
- `AssessmentQuestionsController`에서 `params[:response][:value]`로 직접 접근
- 허용되지 않는 파라미터가 유입될 수 있음
- **수정**: `params.require(:response).permit(:value, :response_time_ms)` 적용

### H-2: Admin 뷰 6개 누락 (HIGH)
- 존재하지 않는 뷰:
  - `admin/question_sets/show.html.erb`
  - `admin/question_sets/edit.html.erb`
  - `admin/question_sets/new.html.erb`
  - `admin/alerts/index.html.erb`
  - `admin/alerts/show.html.erb`
  - `admin/audit_logs/show.html.erb`

### H-3: dashboard @completion_rate 누락 (HIGH)
- 뷰에서 `@completion_rate` 사용하지만 컨트롤러에서 설정하지 않음
- **영향**: 대시보드 접속 시 nil 표시

## 3. 양호 사항

- 라우팅 구조 깔끔 (RESTful)
- Turbo Frame 기반 질문 전환 설계 적절
- CSRF 보호 (ActionController::Base 상속)
- admin layout 분리 적절
