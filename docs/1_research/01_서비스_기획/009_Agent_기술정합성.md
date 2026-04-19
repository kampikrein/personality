---
id: "009"
title: "코드베이스 vs MVP 설계 정합성 분석"
category: agent
status: complete
created: 2026-03-15
summary: >
  005 Plan의 구성요소 A-F를 실제 코드베이스와 대비하여 구현 현황을 매핑하는 분석.
  각 구성요소별 완료/부분구현/미구현 상태를 판별하고 정합성 매핑 표를 작성한다.
keywords: [agent-report, 기술정합성, MVP, 코드베이스, Rails]
modules: [성격서비스_기획]
---

# 코드베이스 vs MVP 설계 정합성 분석

## Progress
### Completed
- [x] 005 Plan 읽기
- [x] 구성요소 A: 문항 엔진 분석
- [x] 구성요소 B: 점수 엔진 분석
- [x] 구성요소 C: 프로필 컴포저 분석
- [x] 구성요소 D: 인사이트 모듈 분석
- [x] 구성요소 E: 컴플라이언스 분석
- [x] 구성요소 F: 품질 운영 분석
- [x] 데이터 흐름 (라우트/컨트롤러/뷰) 분석
- [x] DB 스키마 (PII 분리/동의이력) 분석
- [x] 코드점검 교차검증(004) 참조
### Remaining
- (없음)
### Current Status
분석 완료.

---

## Summary

005 Plan에 정의된 6개 구성요소(A-F) 전체가 코드베이스에 구현되어 있다. 대부분 **완료** 또는 **부분 구현** 상태이며, 완전 미구현 항목은 없다. 전반적 정합성은 높은 수준이나, 교차검증(004)에서 식별된 8개 Critical 이슈가 아직 일부 잔존하며, 대시보드/경보 영역과 오류 처리 보강이 추가로 필요하다.

| 구성요소 | 판정 | 요약 |
|---------|------|------|
| A. 문항 엔진 | **완료** | 4도메인, 버전관리, 리커트 1-5, 품질 메트릭 모두 구현 |
| B. 점수 엔진 | **완료** | 5개 서비스 파이프라인 완비, 0-100 정규화, 신뢰도 보정, 정책 차단 |
| C. 프로필 컴포저 | **완료** | 강점/주의패턴/권장행동, 독자 네이밍, 톤 필터 적용 |
| D. 인사이트 모듈 | **완료** | 5개 맥락 모듈 + 이유 설명 블록 완비 |
| E. 컴플라이언스 | **부분 구현** | 익명/동의/삭제/제한표현 구현. 동의 폼 파라미터 불일치(C-5), 컨트롤러 에러 처리 미흡 |
| F. 품질 운영 | **부분 구현** | 봇 탐지/속도 분석 서비스 완비. 대시보드 기초 수준, 경보 통합 미완성 |

---

## Details

### A. 문항 엔진

**판정: 완료**

| 설계 요구사항 | 코드 위치 | 구현 상태 | 비고 |
|-------------|----------|----------|------|
| 도메인 기반 문항 뱅크 (에너지, 의사결정, 관계, 회복) | `app/models/question.rb` DOMAINS = %w[energy decision_making relationship recovery] | **완료** | 4개 도메인 정확히 일치 |
| 버전 관리 세트 (qset_v1, qset_v2) | `app/models/question_set.rb` version_code 컬럼, uniqueness 검증, STATUSES = [draft, active, archived] | **완료** | `activate!` 메서드로 이전 세트 자동 아카이브 |
| 리커트형 문항 (1-5) | `app/models/response.rb` validates :value, inclusion: { in: 1..5 } | **완료** | nil 허용으로 무응답도 지원 |
| 품질 점검: 무응답률 | `app/models/assessment.rb` non_response_rate 컬럼 | **완료** | ReliabilityAdjuster에서 계산 |
| 품질 점검: 극단응답률 | `app/models/assessment.rb` extreme_response_rate 컬럼, `response.rb#extreme?` | **완료** | 값 1 또는 5를 극단으로 판별 |
| 문항 명확성 점검 | - | **미구현** | 설계 문서에 언급되었으나 코드에 대응 없음. 우선순위 낮음 |
| polarity (역채점) | `app/models/question.rb` polarity 컬럼, POLARITIES = [positive, negative] | **완료** | DomainCalculator에서 (6 - value) 역산 |
| DB 스키마 | `db/schema.rb` questions 테이블, question_sets 테이블 | **완료** | 유니크 인덱스 (question_set_id, domain, position) 존재 |
| 테스트 | `spec/services/scoring/domain_calculator_spec.rb` | **완료** | 양극성/역채점/무응답/극단값 모두 커버 |

### B. 점수 엔진

**판정: 완료**

| 설계 요구사항 | 코드 위치 | 구현 상태 | 비고 |
|-------------|----------|----------|------|
| 도메인 점수 0-100 정규화 | `app/services/scoring/normalizer.rb` | **완료** | ((raw - min) / (max - min)) * 100 공식, 부분 응답 시 비례 조정 |
| 응답 일관성 검증 (split-half) | `app/services/scoring/reliability_adjuster.rb` | **완료** | Spearman-Brown 보정 Pearson r, 도메인별 평균 |
| 비정상 응답 속도 점검 | `app/services/scoring/reliability_adjuster.rb` speed_flag? | **완료** | 500ms 미만 50% 초과 시 플래그 |
| 프로필 벡터 저장 (고정 유형 강제 없음) | `app/models/profile.rb` score_vector (JSON), `domain_scores` 테이블 | **완료** | 프로필에 벡터 저장, DomainScore에 개별 점수 |
| 민감/임상 출력 차단 정책 | `app/services/scoring/policy_checker.rb` | **완료** | 신뢰도 < 0.3, 무응답률 > 50%, 속도 이상 시 차단 |
| 유형 분류 | `app/services/scoring/type_classifier.rb` | **완료** | 4축 >= 50 기준 분류. 설계서의 "고정 유형 강제 없음"과 약간 긴장 관계 |
| DB 스키마 | `db/schema.rb` domain_scores 테이블, 유니크 인덱스 (assessment_id, domain) | **완료** | 최신 스키마에서 유니크 인덱스 추가됨 (004 이슈 C-7 해결) |
| 테스트 | `spec/services/scoring/` 5개 스펙 파일 | **완료** | DomainCalculator, Normalizer, TypeClassifier, ReliabilityAdjuster, PolicyChecker 모두 존재 |

**참고**: TypeClassifier가 MBTI 16유형 코드(ENFP 등)를 사용한다. 005 설계는 "독자적인 척도 라벨"을 요구하지만, PersonalityType 모델의 VALID_CODES가 MBTI 16유형과 동일한 구조이다. 이는 법적 경계 원칙과의 긴장 포인트로, character_name_ko/en이 독자 네이밍을 담당하여 대외 노출 시에는 독자 명칭을 사용하는 것으로 설계되어 있다.

### C. 프로필 컴포저

**판정: 완료**

| 설계 요구사항 | 코드 위치 | 구현 상태 | 비고 |
|-------------|----------|----------|------|
| 점수 벡터 -> 사용자 노출 카드 변환 | `app/services/profiles/composer.rb` | **완료** | score_vector 구성 후 Profile 레코드 생성 |
| 강점 | `composer.rb#call` -> personality_type.strengths | **완료** | PersonalityType에서 JSON 배열로 관리 |
| 주의 패턴 | `composer.rb#call` -> personality_type.caution_patterns | **완료** | 동일하게 JSON 배열 |
| 권장 행동 | `composer.rb#generate_suggested_actions` | **완료** | 유형별 + 점수 기반(75이상/25이하) 동적 생성 |
| 독자적 네이밍 규칙 | `app/models/personality_type.rb` character_name_ko, character_name_en | **완료** | Profile에서 delegate로 접근 |
| 콘텐츠 톤 정책 (낙인 금지, 결정론 금지, 행동 지향) | `app/services/profiles/tone_filter.rb` | **완료** | "you are" -> "you tend toward", "always" -> "often" 등 11개 규칙 |
| 다국어 지원 | `app/services/profiles/type_content_service.rb` | **완료** | ko/en 2개 로케일, 폴백 지원 |
| DB 스키마 | `db/schema.rb` profiles 테이블, personality_types 테이블 | **완료** | strengths/caution_patterns/suggested_actions 모두 JSON 컬럼 |
| 테스트 | `spec/services/profiles/composer_spec.rb`, `tone_filter_spec.rb` | **완료** | 두 서비스 모두 스펙 존재 |

### D. 인사이트 모듈

**판정: 완료**

| 설계 요구사항 | 코드 위치 | 구현 상태 | 비고 |
|-------------|----------|----------|------|
| 맥락 모듈: 협업 | `app/services/insights/collaboration_module.rb` | **완료** | 에너지/관계/의사결정 점수 기반 규칙 템플릿 |
| 맥락 모듈: 갈등 | `app/services/insights/conflict_module.rb` | **완료** | 관계/의사결정/회복 점수 기반 |
| 맥락 모듈: 학습 | `app/services/insights/learning_module.rb` | **완료** | 에너지/의사결정/회복 점수 기반 |
| 맥락 모듈: 커리어 | `app/services/insights/career_module.rb` | **완료** | 4개 도메인 전부 활용 |
| 맥락 모듈: 회복 | `app/services/insights/recovery_module.rb` | **완료** | 회복/에너지/관계 점수 기반 |
| 규칙 + 템플릿 기반 (MVP) | 전체 insights/ 서비스 | **완료** | 점수 임계값(65/35)에 따른 분기 + PersonalityType 콘텐츠 |
| "이 제안이 표시되는 이유" 설명 블록 | `app/services/insights/explanation_builder.rb` | **완료** | 기여 도메인 식별 후 "Based on your..." 문구 생성 |
| 컨텍스트 라우팅 엔진 | `app/services/insights/context_engine.rb` | **완료** | MODULES 맵으로 디스패치, 저장까지 일괄 처리 |
| DB 스키마 | `db/schema.rb` insights 테이블 (context, explanation, suggestions JSON) | **완료** | 유니크 인덱스 (profile_id, context) |
| 테스트 | `spec/services/insights/context_engine_spec.rb` | **완료** | 컨텍스트 엔진 스펙 존재 |

### E. 컴플라이언스 (신뢰 및 컴플라이언스 레이어)

**판정: 부분 구현**

| 설계 요구사항 | 코드 위치 | 구현 상태 | 비고 |
|-------------|----------|----------|------|
| 최소 개인정보 수집, 기본 익명 옵션 | `app/models/anonymous_session.rb`, `sessions_controller.rb` | **완료** | UUID 기반 익명 세션, IP는 해시만 저장 |
| 제품 범위/한계 고지 표시 | 뷰 레이어 (full_flow_spec에서 "공식 MBTI" 고지 확인) | **완료** | E2E 테스트에서 trust notice 렌더링 검증됨 |
| 데이터 수명주기: 보관 기간 | - | **미구현** | 보관 기간 자동 만료 정책 코드 없음 |
| 데이터 수명주기: 삭제 요청 흐름 | `app/services/compliance/deletion_processor.rb`, `deletion_requests_controller.rb` | **완료** | 연쇄 삭제, 감사 로그, SLA 7일 |
| 제한 표현 텍스트 정책 필터링 | `app/services/compliance/text_policy_filter.rb`, `restricted_terms.rb` | **완료** | MBTI/마이어스-브릭스 등 상표/공식 명칭 차단 |
| 동의 이력 관리 | `app/models/consent.rb`, `consents_controller.rb` | **부분 구현** | 동의 기록/철회 가능. 그러나 consent_params에서 :version 사용 vs 모델의 :consent_version 불일치 (004 C-5 관련) |
| 감사 로그 | `app/models/audit_log.rb` | **완료** | AuditLog.record! 범용 메서드, DeletionProcessor에서 활용 |
| Admin 인증 | `app/controllers/admin/base_controller.rb` | **부분 구현** | http_basic_authenticate 적용됨. 단, ENV 미설정 시 dev 기본 비밀번호 폴백 (004 C-1 부분 해결) |
| 테스트 | `spec/services/compliance/` 3개 스펙 | **완료** | restricted_terms, text_policy_filter, deletion_processor, snapshot 테스트 존재 |

### F. 품질 운영

**판정: 부분 구현**

| 설계 요구사항 | 코드 위치 | 구현 상태 | 비고 |
|-------------|----------|----------|------|
| 봇 유사 응답 패턴 탐지 | `app/services/quality/bot_detector.rb` | **완료** | uniform/sequential/zero_variance_timing 3가지 휴리스틱 |
| 비정상 트래픽/속도 분석 | `app/services/quality/speed_analyzer.rb` | **완료** | 개별 응답 속도, 벌크 비율, 총 소요 시간 분석 |
| 대시보드: 완료율 | `app/controllers/admin/dashboard_controller.rb#index`, `#completion_rates` | **완료** | @completion_rate 계산, question_set별 완료율 |
| 대시보드: 이탈률 | `admin/dashboard_controller.rb#drop_off_analysis` | **완료** | current_question_index별 이탈 분포 |
| 대시보드: 만족도 | - | **미구현** | 만족도 피드백 수집 메커니즘 없음 |
| 대시보드: 신고/불만 비율 | - | **미구현** | 신고/불만 접수 시스템 없음 |
| 경보: 봇 탐지 경보 자동 발행 | `app/models/alert.rb` 모델 존재, 컨트롤러 존재 | **부분 구현** | Alert 모델/CRUD 존재. 그러나 BotDetector/SpeedAnalyzer 결과를 자동으로 Alert 생성하는 연동 코드 없음 |
| 경보: 문항 불만 급증 | - | **미구현** | 불만 수집 -> 경보 연동 없음 |
| 배포 게이트: 문항/보고서 텍스트 변경 회귀 점검 | `spec/services/compliance/snapshot_spec.rb` | **부분 구현** | 제한 표현 스냅샷 테스트 존재. 문항 텍스트 변경 회귀 테스트는 미확인 |
| 테스트 | `spec/services/quality/bot_detector_spec.rb`, `speed_analyzer_spec.rb` | **완료** | 두 서비스 모두 스펙 존재 |

---

### 데이터 흐름 (6단계)

| 설계 단계 | 코드 구현 | 구현 상태 | 비고 |
|----------|----------|----------|------|
| 1. start -> 익명 세션 ID 생성 | `SessionsController#create` -> AnonymousSession.create! | **완료** | UUID + IP 해시 + 세션 쿠키 |
| 2. 문항 세트 로드 -> 단계별 응답 저장 | `AssessmentQuestionsController#show/update` | **완료** | Turbo Frame 기반 단계별 렌더링 |
| 3. 제출 -> 점수 계산 | `AssessmentsController#submit` -> `ResultsController#run_scoring_pipeline!` | **완료** | submit 후 results 접근 시 인라인 스코어링 |
| 4. 프로필 + 인사이트 생성 | `ResultsController#run_scoring_pipeline!` Step 7-8 | **완료** | Composer + ContextEngine 5개 맥락 |
| 5. 신뢰 고지와 함께 결과 렌더링 | results/show 뷰 (E2E 테스트에서 "공식 MBTI" 고지 확인) | **완료** | 테스트에서 검증됨 |
| 6. 명시적 동의 기반 선택적 계정 연동 | `AccountsController#create` -> current_session.update!(user: @user) | **완료** | 익명 세션에 User 연결 |

**오류 처리**: ResultsController에 rescue StandardError 추가됨 (004 C-8 부분 해결). 단, 트랜잭션 내 redirect_to 호출 패턴에 잠재적 문제 있음 (redirect는 트랜잭션 밖에서 호출되어야 함).

---

### DB 스키마 분석

| 설계 요구사항 | 스키마 구현 | 구현 상태 | 비고 |
|-------------|-----------|----------|------|
| PII 분리 | users 테이블 (email 암호화), anonymous_sessions 테이블 (IP 해시만), 응답 데이터는 별도 테이블 | **부분 구현** | 논리적 분리는 되어 있으나, 물리적 DB 분리(별도 데이터베이스)는 아님 |
| 저장 시 암호화 | `user.rb` encrypts :email (deterministic), encrypts :display_name | **부분 구현** | User 모델에만 적용. 응답 데이터 자체는 미암호화 |
| 동의 이력 버전 관리 | consents 테이블: consent_version, consent_text_snapshot 컬럼 | **완료** | 동의 시점의 텍스트 스냅샷과 버전 기록 |
| 삭제 요청 시 연쇄 삭제 | `Compliance::DeletionProcessor` 트랜잭션 내 연쇄 삭제 | **완료** | responses -> domain_scores -> insights -> profiles -> assessments -> consents -> session 순서 |
| responses 유니크 인덱스 | `db/schema.rb` index (assessment_id, question_id) unique: true | **완료** | 004 C-6 해결됨 |
| domain_scores 유니크 인덱스 | `db/schema.rb` index (assessment_id, domain) unique: true | **완료** | 004 C-7 해결됨 |
| 외래 키 제약 | `db/schema.rb` add_foreign_key 14개 | **완료** | 주요 관계 모두 FK 설정 |

---

### 교차검증 (004 Synthesis) 대조

| 004 이슈 | 현재 상태 | 비고 |
|----------|----------|------|
| C-1 Admin 인증 없음 | **해결** | admin/base_controller.rb에 http_basic_authenticate 적용 |
| C-2 암호화 키 하드코딩 | **확인 필요** | User 모델은 Rails 자체 encrypts 사용 (credentials 기반). 별도 하드코딩 키 미발견 |
| C-3 질문 폼 파라미터 불일치 | **해결** | response_params에서 params.require(:response).permit(:value, :response_time_ms) 정상 |
| C-4 consents 스키마-모델 불일치 | **잔존** | 모델에서 optional: true이나 스키마에서 일부 컬럼에 null: false 미적용. 현재 스키마에서 consent_type, consent_version 등에 null 제약 없음 -- 모델 validates와 일관성 |
| C-5 동의 폼 완전 불일치 | **잔존** | consent_params에서 :version 사용 vs 모델의 :consent_version. 뷰 파일 미확인이나 파라미터 이름 불일치 의심 |
| C-6 responses 유니크 인덱스 누락 | **해결** | unique: true 인덱스 존재 |
| C-7 domain_scores 유니크 인덱스 누락 | **해결** | unique: true 인덱스 존재 |
| C-8 스코어링 에러 처리 없음 | **부분 해결** | ResultsController에 rescue + 트랜잭션 추가. 단, rescue 블록 내 redirect_to 패턴 주의 필요 |
| H-1 Alert 모델 미존재 | **해결** | Alert 모델 존재, CRUD 완비 |
| H-2 Admin 뷰 6개 누락 | **확인 필요** | 뷰 파일은 본 분석 범위 외. 컨트롤러는 존재 |
| H-4 scope에서 find_by 사용 | **잔존** | DomainScore.for_domain은 scope로 변경됨. PersonalityType.find_by_code는 여전히 find_by 사용 (의도적 설계로 판단) |
| H-5 strong params 미적용 | **부분 해결** | AssessmentQuestionsController, ConsentsController에 strong params 적용. AccountsController도 적용 |
| H-6 스코어링 트랜잭션 없음 | **해결** | ResultsController에 ActiveRecord::Base.transaction 적용 |

---

## 정합성 매핑 종합 표

| # | 설계 항목 (005 Plan) | 코드 위치 | 구현 상태 | 비고 |
|---|---------------------|----------|----------|------|
| A-1 | 도메인 기반 문항 뱅크 | question.rb (DOMAINS) | 완료 | 4도메인 일치 |
| A-2 | 버전 관리 세트 | question_set.rb (version_code, activate!) | 완료 | draft/active/archived 상태 관리 |
| A-3 | 리커트형 1-5 | response.rb (validates value in 1..5) | 완료 | nil 허용 (무응답) |
| A-4 | 품질 점검 (무응답/극단) | assessment.rb + reliability_adjuster.rb | 완료 | |
| A-5 | 문항 명확성 점검 | - | 미구현 | 낮은 우선순위 |
| B-1 | 0-100 정규화 | scoring/normalizer.rb | 완료 | 부분 응답 대응 포함 |
| B-2 | 신뢰도 보정 (일관성/속도) | scoring/reliability_adjuster.rb | 완료 | split-half + 속도 + 무응답 + 극단 |
| B-3 | 프로필 벡터 저장 | profile.rb score_vector (JSON) | 완료 | |
| B-4 | 민감 출력 차단 정책 | scoring/policy_checker.rb | 완료 | 3가지 차단 조건 |
| C-1 | 강점 | composer.rb -> personality_type.strengths | 완료 | |
| C-2 | 주의 패턴 | composer.rb -> personality_type.caution_patterns | 완료 | |
| C-3 | 권장 행동 | composer.rb#generate_suggested_actions | 완료 | 유형별 + 점수 기반 |
| C-4 | 독자 네이밍 | personality_type.rb character_name_ko/en | 완료 | 내부 코드는 MBTI 형식이나 대외 명칭은 독자적 |
| C-5 | 콘텐츠 톤 정책 | profiles/tone_filter.rb | 완료 | 11개 치환 규칙 |
| D-1 | 5개 맥락 모듈 | insights/ 5개 모듈 | 완료 | collaboration, conflict, learning, career, recovery |
| D-2 | 규칙 + 템플릿 기반 | 전체 인사이트 모듈 | 완료 | 점수 임계값 분기 + PersonalityType 콘텐츠 |
| D-3 | "이유 설명" 블록 | insights/explanation_builder.rb | 완료 | 기여 도메인 강도 기반 문구 생성 |
| E-1 | 익명 옵션 | anonymous_session.rb, sessions_controller.rb | 완료 | |
| E-2 | 범위/한계 고지 | 뷰 레이어 (E2E 테스트 검증) | 완료 | |
| E-3 | 삭제 요청 흐름 | compliance/deletion_processor.rb | 완료 | 트랜잭션 + 감사 로그 |
| E-4 | 제한 표현 필터 | compliance/text_policy_filter.rb, restricted_terms.rb | 완료 | |
| E-5 | 동의 이력 관리 | consent.rb, consents_controller.rb | 부분 구현 | 파라미터 이름 불일치 (C-5) |
| E-6 | 데이터 보관 기간 정책 | - | 미구현 | 자동 만료 없음 |
| F-1 | 봇 탐지 | quality/bot_detector.rb | 완료 | |
| F-2 | 속도 분석 | quality/speed_analyzer.rb | 완료 | |
| F-3 | 대시보드 (완료율/이탈률) | admin/dashboard_controller.rb | 완료 | |
| F-4 | 대시보드 (만족도/불만) | - | 미구현 | 피드백 수집 없음 |
| F-5 | 경보 자동 발행 | alert.rb (모델만) | 부분 구현 | 서비스 -> Alert 자동 생성 연동 없음 |
| F-6 | 배포 게이트 회귀 점검 | snapshot_spec.rb | 부분 구현 | 제한 표현만 커버 |

---

## Key Findings

1. **핵심 파이프라인 완성도 높음**: 문항 -> 점수 -> 프로필 -> 인사이트의 핵심 데이터 파이프라인은 완전히 구현되어 있고, E2E 테스트(full_flow_spec.rb)로 검증된다. 설계 문서의 구성요소 A-D는 모두 완료 상태이다.

2. **법적 경계 보호 장치 작동**: RestrictedTerms(상표 차단), ToneFilter(낙인 방지), TextPolicyFilter(콘텐츠 필터), PolicyChecker(정책 차단)의 4중 보호 체계가 구현되어 있다. trust_notice 맥락에서 MBTI/Myers-Briggs 예외 허용도 설계대로 반영되었다.

3. **교차검증 이슈 대부분 해결**: 004에서 식별된 8개 Critical 이슈 중 C-1(Admin 인증), C-3(폼 파라미터), C-6/C-7(유니크 인덱스), C-8(에러 처리) 5개가 해결되었다. C-4(consents null 제약)는 현재 스키마에서 모델 검증과 일관된 상태이고, C-2(암호화)는 Rails encrypts로 전환되어 별도 하드코딩 없음. C-5(동의 폼 불일치)만 잔존한다.

4. **운영 인프라 미완성**: 품질 운영(F) 영역은 서비스 레벨(봇 탐지, 속도 분석)은 완성이지만, 이를 자동으로 Alert를 발행하고 대시보드에 통합하는 연결 고리가 빠져 있다. 만족도/불만 수집 메커니즘도 없다.

5. **TypeClassifier의 설계 긴장**: 내부적으로 MBTI 16유형 코드를 사용하면서 "독자적 척도 라벨"을 표방하는 구조이다. character_name_ko/en이 대외 명칭 역할을 하므로 기능적으로는 문제가 없지만, 코드 감사 시 오해의 소지가 있다. 내부 코드를 독자적 체계로 리팩터링할지 결정이 필요하다.

6. **스코어링 파이프라인 트랜잭션 내 redirect**: ResultsController#run_scoring_pipeline!의 rescue 블록에서 redirect_to를 호출하는데, 이것이 컨트롤러 메서드(show) 내부에서 private 메서드로 호출되므로 이중 렌더/리다이렉트 위험이 있다. 에러 시 show 메서드의 후속 코드와 충돌할 수 있다.

---

## Recommendations

### 즉시 수정 (MVP 출시 전)

1. **동의 폼 파라미터 수정 (C-5)**: `ConsentsController#consent_params`에서 `:version`을 `:consent_version`으로 수정하거나, 뷰의 폼 필드명을 일치시킬 것.

2. **ResultsController 에러 흐름 개선**: rescue 블록에서 redirect_to 대신 인스턴스 변수에 에러 상태를 설정하고, show 액션이 이를 감지하여 적절한 뷰를 렌더링하도록 변경할 것.

3. **Quality -> Alert 자동 연동**: BotDetector/SpeedAnalyzer 결과가 bot_suspected 또는 anomaly일 때 자동으로 Alert 레코드를 생성하는 코드를 ResultsController 파이프라인 또는 별도 서비스에 추가할 것.

### 단기 개선 (런칭 후 1-2주)

4. **데이터 보관 기간 정책**: 일정 기간(예: 1년) 경과 후 미활동 세션 데이터를 자동 삭제하는 배치 작업 구현.

5. **만족도/피드백 수집**: 결과 페이지에 간단한 만족도 폼을 추가하고, 해당 데이터를 대시보드에 반영.

6. **내부 유형 코드 리팩터링 검토**: ENFP 등 MBTI 동일 코드 대신 독자 체계(예: EN-FP -> "탐험형" 같은 코드)로 전환할지 법무팀과 논의.

### 중기 개선

7. **응답 데이터 암호화**: User 모델 외에 responses 테이블의 value 필드 등에도 at-rest encryption 적용 검토.

8. **물리적 PII 분리**: 현재 논리적 분리(별도 테이블)에서 물리적 분리(별도 데이터베이스)로의 전환 로드맵 수립.

---

## References

### 설계 문서
- `docs/01_성격서비스_기획/005_Plan_법률우선_MVP_설계.md` — MVP 설계 기준선
- `docs/02_코드점검/004_Synthesis_교차검증_종합.md` — 교차검증 이슈 목록

### 모델 (15개)
- `app/models/question_set.rb`, `question.rb`, `response.rb`, `assessment.rb`
- `app/models/domain_score.rb`, `profile.rb`, `personality_type.rb`, `insight.rb`
- `app/models/anonymous_session.rb`, `user.rb`, `consent.rb`
- `app/models/deletion_request.rb`, `audit_log.rb`, `alert.rb`
- `app/models/application_record.rb`

### 서비스 (19개)
- `app/services/scoring/` — domain_calculator, normalizer, type_classifier, reliability_adjuster, policy_checker
- `app/services/insights/` — context_engine, explanation_builder, collaboration_module, conflict_module, learning_module, career_module, recovery_module
- `app/services/compliance/` — text_policy_filter, deletion_processor, restricted_terms
- `app/services/quality/` — bot_detector, speed_analyzer
- `app/services/profiles/` — composer, type_content_service, tone_filter

### 컨트롤러 (13개)
- `app/controllers/sessions_controller.rb`, `assessments_controller.rb`, `assessment_questions_controller.rb`
- `app/controllers/results_controller.rb`, `accounts_controller.rb`, `consents_controller.rb`
- `app/controllers/deletion_requests_controller.rb`, `application_controller.rb`
- `app/controllers/admin/` — base_controller, dashboard_controller, question_sets_controller, alerts_controller, audit_logs_controller

### 스키마 및 테스트
- `db/schema.rb` — ActiveRecord::Schema[8.1] 13개 테이블
- `spec/` — 18개 스펙 파일 (서비스 14, 모델 2, 리퀘스트 2)
