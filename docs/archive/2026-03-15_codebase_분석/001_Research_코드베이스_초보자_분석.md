---
id: "001"
type: research
title: "코드베이스 초보자 분석 보고서"
created: 2026-03-11
status: in-progress
summary: >
  personality 프로젝트(Ruby on Rails 성격검사 서비스)의 전체 코드베이스를 초보자 관점에서
  구조, 기술 스택, 데이터 모델, 비즈니스 로직, 설정 등 5개 관점으로 심층 분석하는 연구.
keywords: [rails, architecture, models, services, controllers, scoring, compliance]
parallel_plan:
  total_perspectives: 5
  phases:
    - phase: 1
      perspectives: [1, 2, 3]
      status: completed
      agent_numbers: ["002", "003", "004"]
    - phase: 2
      perspectives: [4, 5]
      status: pending
      agent_numbers: ["005", "006"]
  synthesis_number: "007"
  final_number: "008"
---

# 코드베이스 초보자 분석 보고서

## 연구 개요

### 배경 및 동기
personality 프로젝트는 Ruby on Rails로 개발된 성격검사 서비스다. 초보자가 이 코드베이스를
처음 접했을 때 "어디서부터 읽어야 하는가?", "어떤 파일이 무슨 역할인가?", "데이터는
어떻게 흐르는가?"를 이해할 수 있도록 세부 분석 보고서를 작성한다.

### 연구 범위
- `/app/` 전체 (controllers, models, services, views, javascript)
- `/config/` (routes, database, environments, initializers)
- `/db/` (schema, migrations, seeds)
- `/spec/` (테스트 구조)
- `Gemfile`, `Dockerfile`, `deploy.yml` (기술 스택 및 배포)
- 제외: `.git/`, `tmp/`, `log/`, `vendor/`

### 연구 관점
1. **프로젝트 구조 및 아키텍처** — 디렉토리 구성, Rails MVC 레이어, 서비스 레이어 설계
2. **기술 스택 및 의존성** — Ruby/Rails 버전, Gemfile 분석, JavaScript 스택, 배포 도구
3. **데이터 모델 및 DB 스키마** — 13개 모델 관계도, 마이그레이션 히스토리, 제약 조건
4. **핵심 비즈니스 로직** — 채점(Scoring), 인사이트(Insights), 프로파일(Profiles), 품질(Quality), 컴플라이언스(Compliance) 서비스 분석
5. **설정 및 환경** — 라우팅, 환경별 설정, CSP, Kamal 배포, 인증 흐름

### 관련 문서
- 기존 코드점검 보고서: `docs/02_코드점검/`

---

## 사전 조사 결과

### 프로젝트 루트 주요 파일
```
personality/
├── app/
│   ├── controllers/      # 8개 컨트롤러 + admin 네임스페이스
│   ├── models/           # 13개 모델
│   ├── services/         # 5개 도메인, 약 17개 서비스 객체
│   ├── views/            # ERB 뷰 (Tailwind CSS)
│   └── javascript/       # Stimulus.js 컨트롤러 8개
├── config/
│   ├── routes.rb
│   ├── database.yml      # SQLite
│   ├── deploy.yml        # Kamal 배포
│   └── environments/
├── db/
│   ├── schema.rb
│   ├── migrations/       # 15개 마이그레이션
│   └── seeds.rb
├── spec/                 # RSpec 테스트
├── Gemfile
└── Dockerfile
```

### 서비스 레이어 구성 (app/services/)
```
services/
├── scoring/              # 채점 파이프라인
│   ├── domain_calculator.rb
│   ├── normalizer.rb
│   ├── policy_checker.rb
│   ├── reliability_adjuster.rb
│   └── type_classifier.rb
├── insights/             # 인사이트 생성
│   ├── context_engine.rb
│   ├── explanation_builder.rb
│   ├── career_module.rb
│   ├── collaboration_module.rb
│   ├── conflict_module.rb
│   ├── learning_module.rb
│   └── recovery_module.rb
├── profiles/             # 프로파일 조합
│   ├── composer.rb
│   ├── tone_filter.rb
│   └── type_content_service.rb
├── quality/              # 응답 품질 검증
│   ├── bot_detector.rb
│   └── speed_analyzer.rb
└── compliance/           # GDPR/개인정보 컴플라이언스
    ├── deletion_processor.rb
    ├── restricted_terms.rb
    └── text_policy_filter.rb
```

---

## 병렬 실행 지시사항

### 관점 1: 프로젝트 구조 및 아키텍처
**조사 대상 파일:**
- `config/routes.rb` — 라우팅 전체 구조
- `app/controllers/application_controller.rb` — 베이스 컨트롤러
- `app/controllers/` 전체 컨트롤러 파일
- `app/views/layouts/application.html.erb` — 레이아웃
- `app/views/layouts/admin.html.erb`
- `Procfile.dev` — 개발 프로세스 구성

**분석 목표:**
1. Rails MVC 아키텍처가 이 프로젝트에서 어떻게 구현되었는가
2. Admin 네임스페이스 분리 방식 (admin/base_controller.rb)
3. 인증 흐름 (세션 기반인가? 토큰 기반인가?)
4. 라우팅 패턴 (RESTful? custom routes?)
5. 뷰 레이아웃 구조 (Tailwind 사용, 파셜 구조)
6. 서비스 레이어 존재 이유 및 Fat Model 방지 패턴

**핵심 질문:**
- 사용자 인증은 어떻게 처리되는가? (Sessions controller)
- anonymous_session 모델이 왜 존재하는가?
- 컨트롤러가 서비스를 어떻게 호출하는가?

**보고서 저장:** `docs/04_codebase_분석/002_Agent_구조_아키텍처.md`

---

### 관점 2: 기술 스택 및 의존성
**조사 대상 파일:**
- `Gemfile` 및 `Gemfile.lock` — 모든 gem 분석
- `.ruby-version` — Ruby 버전
- `Dockerfile` — 컨테이너 구성
- `config/deploy.yml` — Kamal 배포 설정
- `app/javascript/application.js` — JS 진입점
- `app/javascript/controllers/` — Stimulus 컨트롤러
- `config/importmap.rb` — Importmap 설정
- `app/assets/tailwind/application.css` — Tailwind 설정
- `Procfile.dev`

**분석 목표:**
1. Ruby 및 Rails 정확한 버전
2. 주요 gem 목록과 각각의 역할 (인증, 보안, 테스트 등)
3. 프론트엔드 스택: Tailwind + Stimulus.js + Importmap 조합 이해
4. Stimulus 컨트롤러 8개 각각의 역할
5. Kamal 배포 구성 (서버, 환경변수)
6. 개발 vs 프로덕션 환경 차이

**핵심 질문:**
- bcrypt/Devise 등 인증 관련 gem이 있는가?
- brakeman, bundler-audit 등 보안 도구 사용 여부
- Tailwind를 어떻게 빌드하는가? (dartsass? tailwindcss-rails?)

**보고서 저장:** `docs/04_codebase_분석/003_Agent_기술스택_의존성.md`

---

### 관점 3: 데이터 모델 및 DB 스키마
**조사 대상 파일:**
- `db/schema.rb` — 전체 스키마 (컬럼, 타입, 인덱스, 제약)
- `db/seeds.rb` — 초기 데이터
- `db/migrate/` 전체 15개 파일 — 마이그레이션 히스토리
- `app/models/` 전체 13개 모델 파일 — 관계, 검증, 스코프
- `spec/factories.rb` — 팩토리 구조

**분석 목표:**
1. 13개 모델 각각의 역할과 컬럼 목록 (line number 포함)
2. 모델 간 관계 (belongs_to, has_many, has_one) 전체 매핑
3. 마이그레이션 히스토리: 초기 설계 → 수정 과정
4. 유니크 인덱스, null 제약, 외래키 현황
5. anonymous_session vs user 구분 (비로그인 사용자 지원 여부)
6. GDPR 관련 모델 (DeletionRequest, AuditLog, Consent)

**핵심 질문:**
- User 없이 익명으로 검사 진행 가능한가?
- Consent 모델이 어떤 동의를 추적하는가?
- DomainScore와 PersonalityType의 관계는?

**보고서 저장:** `docs/04_codebase_분석/004_Agent_데이터모델_스키마.md`

---

### 관점 4: 핵심 비즈니스 로직 (채점 + 인사이트 파이프라인)
**조사 대상 파일:**
- `app/services/scoring/` 전체 5개 파일
- `app/services/insights/` 전체 7개 파일
- `app/services/profiles/` 전체 3개 파일
- `app/services/quality/` 전체 2개 파일
- `app/controllers/assessments_controller.rb`
- `app/controllers/results_controller.rb`
- `spec/services/scoring/` 전체 스펙
- `spec/services/insights/` 전체 스펙

**분석 목표:**
1. 채점 파이프라인 전체 흐름:
   DomainCalculator → Normalizer → ReliabilityAdjuster → PolicyChecker → TypeClassifier
2. 각 Scoring 서비스의 입/출력 파라미터
3. PersonalityType 분류 로직 (어떤 알고리즘?)
4. Insights 생성 과정: ContextEngine이 어떤 모듈을 조합하는가?
5. Quality 검증: BotDetector와 SpeedAnalyzer의 판단 기준
6. ResultsController가 데이터를 어떻게 조합하여 뷰에 전달하는가?

**핵심 질문:**
- MBTI 16유형을 직접 사용하는가, 독자적 유형 체계인가?
- 점수 계산이 실시간인가, 저장 후 처리인가?
- 신뢰도 조정(reliability_adjuster)은 어떤 경우에 발동되는가?

**보고서 저장:** `docs/04_codebase_분석/005_Agent_비즈니스로직_파이프라인.md`

---

### 관점 5: 설정, 환경, 컴플라이언스
**조사 대상 파일:**
- `config/routes.rb` — 전체 라우팅
- `config/application.rb` — 앱 설정
- `config/environments/development.rb`
- `config/environments/production.rb`
- `config/initializers/content_security_policy.rb`
- `config/initializers/filter_parameter_logging.rb`
- `config/database.yml`
- `config/puma.rb`
- `config/recurring.yml` — 반복 작업
- `app/services/compliance/` 전체 3개 파일
- `spec/services/compliance/` 전체 스펙
- `.env.example`
- `bin/ci` — CI 파이프라인 스크립트

**분석 목표:**
1. 라우팅 전체 구조 (모든 경로, 네임스페이스, 제약)
2. 환경별 설정 차이 (development vs production)
3. CSP (Content Security Policy) 설정 내용
4. 개인정보 필터링 설정 (filter_parameter_logging)
5. Compliance 서비스 3개의 구체적 동작:
   - DeletionProcessor: 삭제 요청 처리 방식
   - RestrictedTerms: 금지어 목록 및 검사 방식
   - TextPolicyFilter: 텍스트 정책 필터링
6. recurring.yml: 정기 작업이 있는가?
7. 환경 변수 목록 (.env.example)

**핵심 질문:**
- GDPR 삭제 요청이 실제로 어떻게 처리되는가?
- 프로덕션 보안 설정이 충분한가?
- 어떤 데이터가 로그에 남지 않도록 필터링되는가?

**보고서 저장:** `docs/04_codebase_분석/006_Agent_설정_환경_컴플라이언스.md`

---

## 남은 작업

- [ ] 관점 1: 프로젝트 구조 및 아키텍처
- [ ] 관점 2: 기술 스택 및 의존성
- [ ] 관점 3: 데이터 모델 및 DB 스키마
- [ ] 관점 4: 핵심 비즈니스 로직 (채점 + 인사이트 파이프라인)
- [ ] 관점 5: 설정, 환경, 컴플라이언스
- [ ] 교차 분석
- [ ] 종합 결론
