# Agent C: 서비스 & 테스트 분석

> 분석일: 2026-02-22
> 범위: `app/services/`, `spec/`

## 1. 서비스 계층 구조 (19개)

### Scoring (점수 산출 파이프라인)
| 서비스 | 라인 수 | 테스트 | 역할 |
|--------|---------|--------|------|
| DomainCalculator | ~80 | O | 도메인별 원시 점수 계산 |
| Normalizer | ~60 | O | 0-100 정규화 |
| TypeClassifier | ~100 | O | 타입 코드 분류 |
| ReliabilityAdjuster | ~203 | **X** | Pearson 상관계수 기반 신뢰도 |
| PolicyChecker | ~50 | O | 정책 위반 검사 |

### Compliance (법적 준수)
| 서비스 | 라인 수 | 테스트 | 역할 |
|--------|---------|--------|------|
| TextPolicyFilter | ~80 | O | 민감 표현 필터링 |
| DeletionProcessor | ~134 | **X** | GDPR 삭제 파이프라인 |
| RestrictedTerms | ~40 | O | 금지어 목록 |

### Insights (행동 가이드)
| 서비스 | 라인 수 | 테스트 | 역할 |
|--------|---------|--------|------|
| ContextEngine | ~150 | **X** | 컨텍스트별 인사이트 생성 허브 |
| ExplanationBuilder | ~100 | **X** | 설명 텍스트 구성 |
| CollaborationModule | ~80 | **X** | 협업 스타일 분석 |
| ConflictModule | ~80 | **X** | 갈등 대처 분석 |
| LearningModule | ~80 | **X** | 학습 스타일 분석 |
| CareerModule | ~80 | **X** | 커리어 힌트 |
| RecoveryModule | ~80 | **X** | 회복 패턴 분석 |

### Profiles (프로필 조합)
| 서비스 | 라인 수 | 테스트 | 역할 |
|--------|---------|--------|------|
| Composer | ~180 | **X** | 프로필 조합 |
| TypeContentService | ~60 | **X** | 타입별 콘텐츠 |
| ToneFilter | ~96 | **X** | 톤 필터링 |

### Quality (품질 검증)
| 서비스 | 라인 수 | 테스트 | 역할 |
|--------|---------|--------|------|
| BotDetector | ~80 | **X** | 봇 탐지 |
| SpeedAnalyzer | ~92 | **X** | 응답 속도 분석 |

## 2. 발견된 이슈

### C-8: 스코어링 에러 처리 없음 (CRITICAL)
- `ResultsController#run_scoring_pipeline!` — 전체 파이프라인에 rescue 없음
- 어떤 서비스에서든 예외 발생 시 500 에러 노출
- **수정**: `rescue StandardError` + `assessment.fail!` + 에러 리다이렉트

### H-6: 스코어링 트랜잭션 없음 (HIGH)
- 파이프라인 중간에 실패하면 부분 데이터가 남음
  - 예: domain_scores는 생성됐지만 profile은 미생성
- **수정**: `ActiveRecord::Base.transaction`으로 감싸기

### H-1: Alert 모델 미존재 (HIGH)
- `Admin::AlertsController`가 `Alert` 모델 참조
- Alert 모델 파일과 마이그레이션이 없음
- **영향**: admin/alerts 접근 시 `NameError: uninitialized constant Alert`

## 3. 테스트 커버리지 분석

### 테스트 존재
- `spec/models/`: assessment_spec, personality_type_spec
- `spec/services/scoring/`: domain_calculator, normalizer, type_classifier, policy_checker
- `spec/services/compliance/`: text_policy_filter, restricted_terms, snapshot
- `spec/requests/`: sessions, full_flow

### 테스트 미존재 (우선순위순)
1. **ReliabilityAdjuster** — Pearson 상관계수 수학적 정확성 검증 필요 (최우선)
2. **DeletionProcessor** — GDPR 파이프라인 정합성 (높음)
3. **Insights 모듈 전체** (7개) — 행동 가이드 정확성 (중간)
4. **Profiles 서비스** (3개) — 프로필 조합 로직 (중간)
5. **Quality 서비스** (2개) — 봇 탐지/속도 분석 (낮음)

## 4. 양호 사항

- 서비스 계층 분리 잘 되어 있음 (Single Responsibility)
- 기존 테스트가 있는 서비스는 edge case 커버 양호
- 팩토리(spec/factories.rb) + 헬퍼(assessment_helpers.rb) 인프라 갖춤
