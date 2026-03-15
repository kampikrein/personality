---
id: "005"
type: plan
title: "최종 수정 계획 (Wave 1~N)"
created: 2026-02-22
summary: >
  교차 검증 종합 분석(004)에 기반한 Rails 코드 수정 계획.
  Wave 1 사용자 테스트 전 필수 수정 항목(DB 마이그레이션 등)부터 단계적으로 정리한다.
keywords: [수정계획, Rails, 코드점검, 마이그레이션]
---

# 최종 수정 계획

> 작성일: 2026-02-22
> 기반: 교차 검증 종합 분석 (004)

## Wave 1: 사용자 테스트 전 필수 수정

### Step 1: DB 마이그레이션 (C-4, C-6, C-7)

```ruby
# C-4: consents null 제약 완화
change_column_null :consents, :user_id, true
change_column_null :consents, :anonymous_session_id, true

# C-6: responses 복합 유니크 인덱스
add_index :responses, [:assessment_id, :question_id], unique: true

# C-7: domain_scores 복합 유니크 인덱스
add_index :domain_scores, [:assessment_id, :domain], unique: true
```

### Step 2: 보안 수정 (C-1, C-2, H-5)

- C-1: `Admin::BaseController`에 `http_basic_authenticate_with` 추가
- C-2: `config/application.rb` 하드코딩된 기본값 제거, ENV 필수화
- H-5: `AssessmentQuestionsController`에 strong params 메서드 추가

### Step 3: 폼 수정 (C-3, C-5)

- C-3: `_question.html.erb` 내 input name을 `response[...]`로 통일
- C-5: `consents/new.html.erb` 폼 구조를 컨트롤러 기대에 맞게 재작성

### Step 4: 스코어링 안정화 (C-8, H-6)

- C-8 + H-6: `ResultsController#run_scoring_pipeline!`에 transaction + rescue 추가

### Step 5: scope 수정 (H-4)

- `DomainScore.for_domain` → `where(domain: domain)`
- `Insight.for_context` → `where(context: ctx)`

### Step 6: Admin 기능 복구 (H-1, H-2, H-3)

- H-1: `Alert` 모델 + 마이그레이션 생성
- H-2: 누락된 admin 뷰 6개 생성
- H-3: `DashboardController#index`에 `@completion_rate` 계산 추가

## Wave 2: 런칭 전 수정

### 테스트 작성 (우선순위순)
1. `Scoring::ReliabilityAdjuster` — Pearson 상관계수 정확성
2. `Compliance::DeletionProcessor` — GDPR 삭제 흐름
3. `Insights::ContextEngine` + 5개 모듈 — 행동 가이드
4. `Profiles::Composer`, `ToneFilter` — 프로필 조합
5. `Quality::SpeedAnalyzer`, `BotDetector` — 품질 검증

### 추가 DB 인덱스
- `users.email` 유니크 인덱스
- `deletion_requests.sla_deadline` 인덱스

## Wave 3: 런칭 후 개선

- 스코어 임계값 통일 (Composer 75/25 vs Insights 65/35)
- 컨트롤러 `rescue_from` 공통 에러 핸들링
- ToneFilter 문법 개선
- `Assessment.total_questions` 메모이제이션
- 하드코딩된 상수 → 설정 파일 추출

## 검증 방법

1. `bundle exec rspec` — 전체 통과
2. 수동 플로우: 랜딩 → 질문 → 제출 → 결과
3. `/admin` 인증 프롬프트 확인
4. Rails console에서 anonymous 동의 생성 확인
