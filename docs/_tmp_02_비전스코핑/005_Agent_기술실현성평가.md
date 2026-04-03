---
id: "step-5"
workflow_id: "WF-20260315-비전스코핑"
step_slug: "기술실현성평가"
agent: "coding-expert"
created: "2026-03-15"
summary: >
  현재 Rails 코드베이스(Rails 8.1, 14테이블, 20서비스, 266테스트)는
  비전 V1(성격 포탈)의 기반이 완성 단계에 있다. V2(스와이프 UX)는
  Hotwire로 조건부 실현 가능하며, V3-V5는 점진적 기술 확장이 필요하다.
  7개 Insights 하위 서비스 미테스트가 현재 최대 기술 부채다.
key_findings:
  - "266개 테스트 전체 통과 확인 (2026-03-15 기준)"
  - "코드 점검 보고서(2026-02-22) 이후 Wave 1 수정 대부분 완료됨 — 트랜잭션/에러처리/Alert모델/Admin뷰 구현됨"
  - "실제 미테스트 서비스는 7개 (Insights 하위 모듈 6개 + TypeContentService)"
  - "현재 DB 스키마는 V1 전용 — V2~V5는 최소 8개 테이블 추가 필요"
  - "V1은 고난이도 부채 없이 4주 내 안정화 가능"
  - "V3 캐릭터(매크로)는 Rails만으로 구현 가능 — LLM 연동은 V5 단계"
confidence: high
next_steps:
  - "7개 미테스트 서비스 스펙 작성 (Wave 2 우선 과제)"
  - "content_cards/content_series 테이블 설계 — V2 전제조건"
  - "character_scripts 테이블 설계 — V3 전제조건"
  - "SQLite → PostgreSQL 전환 (production 준비 단계)"
---

# 기술 실현성 평가: 파운더 비전 vs 현재 코드베이스

> 분석일: 2026-03-15
> 기반: 코드 직접 탐색 + 테스트 실행 + 코드 점검 문서(docs/02_코드점검/)
> 테스트 실행 결과: 266 examples, 0 failures

---

## 1. 현재 코드베이스 아키텍처 평가

### 1-1. 프로젝트 기술 스택 현황

| 항목 | 현황 |
|------|------|
| Rails 버전 | 8.1.2 |
| DB (개발) | SQLite |
| DB (프로덕션) | PostgreSQL (pg gem 추가됨) |
| 프론트엔드 | Hotwire (Turbo + Stimulus) + Tailwind CSS |
| 백그라운드 잡 | Solid Queue (gem 추가됨, 미사용 중) |
| 캐시 | Solid Cache (gem 추가됨) |
| WebSocket | Solid Cable (gem 추가됨) |
| 테스트 | RSpec + FactoryBot + Faker |
| 보안 | Brakeman + bundler-audit |

**판단**: 비전의 단기 요소 대부분을 지원하는 스택이 이미 포함되어 있다.
Solid Queue/Cable은 미활성화 상태이지만 gem이 준비되어 있어 활성화 비용이 낮다.

### 1-2. 모델 레이어 (14개 테이블)

```
anonymous_sessions → assessments → responses → domain_scores
                                             → profiles → insights
users
question_sets → questions
personality_types
consents
deletion_requests
audit_logs
alerts
```

**정상 동작 확인 모델**: 14개 전체 — 마이그레이션 완료, 관계 설정 완료.

**이전 보고서(2026-02-22) 대비 수정 완료 항목**:
- Alert 모델: 당시 미존재 → 현재 `app/models/alert.rb` 구현 완료
- responses 복합 유니크 인덱스: `schema.rb` 기준 `index_responses_on_assessment_id_and_question_id` (unique: true) 존재
- domain_scores 복합 유니크 인덱스: `index_domain_scores_on_assessment_id_and_domain` (unique: true) 존재

**잔여 DB 이슈** (schema.rb 직접 확인):
- `consents.user_id`: schema.rb에서 null 허용으로 명시되어 있지 않음 — 재확인 필요
- `users.email` 유니크 인덱스: schema.rb에 `index_users_on_email, unique: true` 존재 → 이미 수정됨

### 1-3. 서비스 레이어 (20개)

| 카테고리 | 서비스 | 테스트 | 상태 |
|----------|--------|--------|------|
| Scoring | DomainCalculator | O | 정상 |
| Scoring | Normalizer | O | 정상 |
| Scoring | TypeClassifier | O | 정상 |
| Scoring | ReliabilityAdjuster | O (168줄 스펙) | 정상 |
| Scoring | PolicyChecker | O | 정상 |
| Compliance | TextPolicyFilter | O | 정상 |
| Compliance | RestrictedTerms | O | 정상 |
| Compliance | DeletionProcessor | O | 정상 |
| Insights | ContextEngine | O (63줄 스펙) | 정상 |
| Insights | CollaborationModule | **X** | 미테스트 |
| Insights | ConflictModule | **X** | 미테스트 |
| Insights | LearningModule | **X** | 미테스트 |
| Insights | CareerModule | **X** | 미테스트 |
| Insights | RecoveryModule | **X** | 미테스트 |
| Insights | ExplanationBuilder | **X** | 미테스트 |
| Profiles | Composer | O (108줄 스펙) | 정상 |
| Profiles | ToneFilter | O | 정상 |
| Profiles | TypeContentService | **X** | 미테스트 |
| Quality | BotDetector | O (98줄 스펙) | 정상 |
| Quality | SpeedAnalyzer | O | 정상 |

**실제 미테스트 서비스**: 7개 (이전 보고서의 12개에서 감소)
- Insights 하위 모듈 5개 (각 ~100줄)
- ExplanationBuilder (84줄)
- TypeContentService (49줄)

### 1-4. 컨트롤러 레이어 현황

ResultsController `run_scoring_pipeline!` 확인:
- `ActiveRecord::Base.transaction` 적용됨
- `rescue StandardError` 적용됨
- `assessment.fail!` 호출됨
- 사용자 리다이렉트 포함

**이전 보고서 C-8(에러처리없음) + H-6(트랜잭션없음) 모두 해결 완료.**

### 1-5. 확장성 평가

현재 아키텍처의 **확장 적합도**:

| 확장 방향 | 적합도 | 이유 |
|-----------|--------|------|
| 콘텐츠 모델 추가 | 높음 | RESTful 구조, 별도 테이블 추가 용이 |
| 소셜 기능 | 중간 | users 테이블 최소화 상태 — 확장 설계 필요 |
| 캐릭터 인터랙션 | 중간 | 대화 상태 관리 테이블 미존재 |
| 실시간 기능 | 높음 | Solid Cable 준비 완료 |
| 백그라운드 처리 | 높음 | Solid Queue 준비 완료 |
| LLM 연동 | 중간 | HTTP 클라이언트 추가 필요, Solid Queue 활용 가능 |

---

## 2. 비전 요소별 기술 실현성 매핑

### V1. 성격 포탈 (콘텐츠 깊이)

**판정: 가능** — 현재 코드베이스가 이미 기반을 제공한다.

| 항목 | 현황 | 필요 작업 |
|------|------|-----------|
| 성격 유형 데이터 | personality_types 테이블 존재 | 시드 데이터 확충 (16개 유형) |
| 인사이트 5개 컨텍스트 | Insights 서비스 구현됨 | 7개 모듈 테스트 작성 |
| 콘텐츠 깊이 계층 | 없음 | content_cards/content_series 모델 신규 설계 |
| 정적 콘텐츠 | 없음 | 시드 데이터 또는 CMS 연동 |

**추가 인프라**: 없음 (현재 스택으로 가능)
**예상 공수**: 3~4주 (콘텐츠 모델 설계 + 시드 데이터 작성 포함)

### V2. 스와이프/쇼츠형 UX

**판정: 조건부 가능** — Hotwire가 준비되어 있으나 콘텐츠 모델과 UX 설계가 선행되어야 한다.

| 항목 | 현황 | 필요 작업 |
|------|------|-----------|
| Turbo Frame 기반 UI | 이미 질문 플로우에 사용 중 | 카드 뷰 컴포넌트로 확장 |
| 무한 스크롤 | 없음 | Stimulus + Turbo Stream 구현 |
| 프리로딩 | 없음 | Solid Cache 활용 또는 Turbo prefetch |
| 카드형 콘텐츠 모델 | 없음 | content_cards 테이블 설계 필수 |

**전제조건**: content_cards 테이블 + ContentCard 모델 설계가 V2 구현 전에 반드시 완료되어야 한다.
**추가 인프라**: CDN (이미지/미디어 콘텐츠 증가 시), Solid Cache 활성화
**예상 공수**: 4~6주 (콘텐츠 모델 포함)

**기술 선택 이유**: Rails Hotwire(Turbo) vs React SPA 비교 시,
현재 팀 스택과 서버사이드 렌더링 이점을 고려하면 Hotwire가 MVP 단계에서 우선이다.
실시간성이 강화되는 V4~V5 단계에서 프론트엔드 분리를 재검토할 수 있다.

### V3. 캐릭터 인터랙션

**판정: 조건부 가능** — 매크로 단계는 Rails만으로 가능, AI 단계는 외부 의존성 추가 필요.

#### 단계 A: 매크로 수준 (초기 구현)
- 조건 분기 스크립트 기반 대화 엔진
- DB: `character_scripts` 테이블 (조건 트리 JSON 저장)
- 상태 관리: `character_sessions` 테이블 (유저별 대화 진행 상태)
- 기술: Rails + Stimulus (DOM 조작) + Turbo Stream (메시지 스트리밍 흉내)
- 예상 공수: 6~8주

#### 단계 B: AI 에이전트 수준 (중기)
- LLM API 연동 (OpenAI/Anthropic API)
- 유저별 컨텍스트 벡터 관리 (`user_contexts` 테이블)
- 대화 기록 영속화 (`conversations`, `messages` 테이블)
- Solid Queue로 LLM 응답 비동기 처리
- 예상 공수: 8~12주 + LLM API 비용 구조 설계

**추가 인프라 (B 단계)**: LLM API 키 관리 (Rails credentials), 응답 캐싱 (Solid Cache), 비동기 처리 (Solid Queue 활성화)

### V4. 소셜 커뮤니티

**판정: 조건부 가능** — 현재 users 테이블이 최소화 상태이며 소셜 스키마가 전무하다.

| 필요 테이블 | 현재 상태 | 예상 마이그레이션 복잡도 |
|-------------|-----------|------------------------|
| users 확장 (닉네임, 아바타, 프로필) | display_name만 존재 | 낮음 |
| posts / comments | 없음 | 중간 |
| likes / reactions | 없음 | 낮음 |
| communities / groups | 없음 | 높음 |
| follows / friendships | 없음 | 중간 |
| notifications | 없음 | 중간 |
| real-time chat | 없음 | 높음 (Solid Cable 활용) |

**전제조건**: 회원 시스템 강화 (소셜 기능은 익명 세션이 아닌 인증된 계정 기반)
**추가 인프라**: Solid Cable 활성화 (실시간 채팅), 이미지 저장 (Active Storage + CDN), 검색 (pg_search 또는 Elasticsearch)
**예상 공수**: 12~20주 (기능 범위에 따라 크게 달라짐)

### V5. 유저별 AI 에이전트

**판정: 조건부 가능** — 기술 자체는 가능하나 비용과 개인정보 보호가 핵심 변수다.

| 항목 | 과제 | 비고 |
|------|------|------|
| LLM API 비용 | 유저당 월 비용 모델 설계 | 프리미엄/구독 모델 필요 가능성 |
| 유저 컨텍스트 관리 | profiles.score_vector를 LLM 프롬프트에 주입 | 현재 구조 활용 가능 |
| 대화 기록 저장 | PII 분리 정책 적용 필요 | DeletionProcessor 확장 필요 |
| 개인화 수준 | 유저별 에이전트 "기억" 관리 | vector DB 또는 JSON 컨텍스트 |
| 법적 고지 | AI 생성 콘텐츠 고지 의무 | MVP 설계의 법적 경계 원칙 유지 |

**추가 인프라**: LLM API (OpenAI/Anthropic), Vector DB (pgvector 또는 Pinecone), 비용 모니터링
**예상 공수**: 16~24주 + 법무 검토

---

## 3. DB 스키마 확장 필요성

### 3-1. V1 완성을 위한 추가 필요 테이블

```sql
-- 콘텐츠 카드 (스와이프 가능한 단위 콘텐츠)
CREATE TABLE content_cards (
  id SERIAL PRIMARY KEY,
  title VARCHAR NOT NULL,
  body TEXT,
  depth_level INTEGER DEFAULT 1,  -- 1(가벼움) ~ 5(심층)
  card_type VARCHAR,               -- 'fact', 'quiz', 'reflection', 'action'
  personality_type_code VARCHAR,   -- null이면 공통 콘텐츠
  position INTEGER,
  published BOOLEAN DEFAULT false,
  created_at TIMESTAMP, updated_at TIMESTAMP
);

-- 콘텐츠 시리즈 (카드 묶음)
CREATE TABLE content_series (
  id SERIAL PRIMARY KEY,
  title VARCHAR NOT NULL,
  description TEXT,
  category VARCHAR,  -- 'mbti_deep', 'relationship', 'career' 등
  created_at TIMESTAMP, updated_at TIMESTAMP
);

-- 시리즈-카드 조인 테이블
CREATE TABLE series_cards (
  content_series_id INTEGER, content_card_id INTEGER,
  position INTEGER
);

-- 태그 (다형성)
CREATE TABLE tags (id, name, slug, created_at, updated_at);
CREATE TABLE taggings (tag_id, taggable_type, taggable_id, created_at);
```

### 3-2. V3 캐릭터를 위한 추가 필요 테이블

```sql
-- 캐릭터 정의
CREATE TABLE characters (
  id, name, persona_description TEXT,
  script_version VARCHAR,   -- 매크로 버전 관리
  active BOOLEAN,
  created_at, updated_at
);

-- 매크로 스크립트 노드 (조건 분기 트리)
CREATE TABLE character_script_nodes (
  id, character_id,
  node_key VARCHAR,          -- 분기 식별자
  trigger_condition TEXT,    -- JSON: 트리거 조건
  response_text TEXT,
  next_node_key VARCHAR,     -- 다음 노드
  created_at, updated_at
);

-- 유저별 대화 세션
CREATE TABLE character_sessions (
  id, anonymous_session_id,
  character_id,
  current_node_key VARCHAR,
  context_data JSON,         -- 대화 진행 컨텍스트
  last_interacted_at TIMESTAMP,
  created_at, updated_at
);

-- 대화 기록 (AI 단계 전환 시 확장)
CREATE TABLE character_messages (
  id, character_session_id,
  role VARCHAR,              -- 'user' | 'character'
  content TEXT,
  created_at TIMESTAMP
);
```

### 3-3. V4 소셜을 위한 추가 필요 테이블 (요약)

- `communities` (그룹 공간)
- `posts` (게시글, polymorphic 대상)
- `comments` (댓글, polymorphic)
- `reactions` (좋아요/이모지, polymorphic)
- `follows` (팔로우 관계)
- `notifications` (알림)

### 3-4. 현재 스키마의 확장 친화적 설계 요소

- `anonymous_sessions.user_id` — 익명 → 계정 전환 지원 설계가 이미 존재
- `profiles.score_vector` (JSON) — LLM 프롬프트 주입에 바로 활용 가능
- `audit_logs` polymorphic 설계 — 소셜 활동 감사에 재사용 가능
- `consents` 버전 관리 — AI 기능 추가 시 별도 동의 항목 추가 용이

---

## 4. 기술 스택 확장 검토

### 4-1. 현재 스택으로 충분한 영역

| 기능 | 근거 |
|------|------|
| 성격 검사 플로우 | 완전 구현됨 |
| 콘텐츠 카드 뷰 (정적) | Turbo Frame으로 충분 |
| 관리자 대시보드 | 현재 구현 중 |
| 유저 인증/계정 | bcrypt + 현재 users 테이블 확장으로 충분 |
| 백그라운드 잡 | Solid Queue (gem 준비됨, 활성화만 필요) |
| 기본 캐싱 | Solid Cache (gem 준비됨) |

### 4-2. 추가 기술이 필요한 영역

| 필요 기능 | 추가 기술 | 도입 시점 |
|-----------|-----------|-----------|
| 무한 스크롤 / 프리로딩 | Stimulus 컨트롤러 커스텀 작성 | V2 |
| 이미지/미디어 콘텐츠 | Active Storage + 스토리지 서비스(S3 등) | V2 |
| 실시간 채팅 | Solid Cable (이미 gem 포함) | V4 |
| 전체 텍스트 검색 | `pg_search` gem 또는 PostgreSQL FTS | V4 |
| LLM API 연동 | `ruby-openai` 또는 `anthropic-sdk-ruby` gem | V3B/V5 |
| 벡터 유사도 검색 | `pgvector` PostgreSQL 확장 | V5 |
| 이메일 발송 | Action Mailer (이미 Rails에 포함) | V4 |

### 4-3. 인프라 확장 고려사항

| 시점 | 인프라 항목 | 이유 |
|------|-------------|------|
| MVP 출시 전 | SQLite → PostgreSQL 전환 | production은 pg gem 사용 중, 개발 환경도 일치시켜야 함 |
| V2 | CDN (Cloudflare 등) | 콘텐츠 카드 이미지 서빙 |
| V2 | Solid Cache 활성화 | 콘텐츠 카드 캐싱으로 DB 부하 감소 |
| V3 | Solid Queue 활성화 | LLM API 응답 비동기 처리 |
| V4 | 별도 DB 인스턴스 | 소셜 기능으로 인한 쿼리 증가 |
| V5 | LLM API 비용 모니터링 | 유저별 에이전트는 비용이 선형 증가 |

---

## 5. 기술 로드맵 제안

### Phase 1: MVP 안정화 (2~4주)

**목표**: 현재 성격 검사 플로우가 오류 없이 E2E 동작하도록 보장

**작업 항목**:
1. 7개 미테스트 서비스 스펙 작성 (Insights 5개 모듈 + ExplanationBuilder + TypeContentService)
2. 개발 환경 SQLite → PostgreSQL 전환 (production 환경과 일치)
3. personality_types 시드 데이터 완성 (16개 MBTI 유형 전체)
4. consents 폼-컨트롤러 파라미터 불일치 수정 여부 최종 확인 (C-3, C-5)
5. Admin 대시보드 `@completion_rate` 변수 설정 확인

**완료 기준**:
- `bundle exec rspec` 전체 통과, 커버리지 80%+
- 수동 E2E: 랜딩 → 세션 → 질문 → 제출 → 결과 페이지 오류 없음
- 16개 PersonalityType 레코드 시드 완료

**복잡도**: 낮음 | **의존성**: 없음

### Phase 2: 콘텐츠 확장 (4~8주)

**목표**: 성격 포탈로서 "먹을거리" 제공 — 스와이프 가능한 콘텐츠 레이어

**작업 항목**:
1. ContentCard, ContentSeries 모델 설계 + 마이그레이션
2. 깊이 단계(depth_level 1~5) 구조 구현
3. 성격 유형별 콘텐츠 시드 데이터 작성
4. 결과 페이지에 관련 콘텐츠 카드 표시
5. 태그 시스템 구현

**완료 기준**:
- 결과 페이지에서 3개 이상의 관련 콘텐츠 카드 표시
- depth_level 1(입문) + 3(중급) 각 최소 10개 카드

**복잡도**: 중간 | **의존성**: Phase 1 완료

### Phase 3: 인터랙션 (6~10주)

**목표**: 스와이프 UX + 캐릭터 매크로 인터랙션

**작업 항목**:
1. Turbo Frame 기반 카드 스와이프 UX (Stimulus 컨트롤러 작성)
2. 무한 스크롤 / 프리로딩 구현
3. Character, CharacterScriptNode, CharacterSession 모델 설계
4. 매크로 기반 대화 엔진 구현 (조건 분기 트리 처리)
5. 캐릭터 UI 컴포넌트 (사이드바/팝업 형태)

**완료 기준**:
- 카드 스와이프 UX 동작
- 캐릭터가 최소 3개 분기 시나리오로 대화 가능

**복잡도**: 중간-높음 | **의존성**: Phase 2 완료

### Phase 4: 소셜 (10~20주)

**목표**: 커뮤니티 기반 조성 — 정보 사이트에서 교류 공간으로

**작업 항목**:
1. User 모델 확장 (아바타, 소개, 공개 프로필)
2. 회원가입/로그인 강화 (소셜 로그인 검토)
3. Post/Comment 모델 + 뷰
4. Reaction 시스템
5. 알림 시스템
6. Solid Cable 기반 실시간 채팅 (선택적)
7. 성격 유형별 커뮤니티 그룹

**완료 기준**:
- 유저가 게시글 작성/댓글/좋아요 가능
- 성격 유형별 그룹 페이지 존재

**복잡도**: 높음 | **의존성**: Phase 3 완료, 법무 재검토 필요

### Phase 5: AI 에이전트 (16~24주)

**목표**: 유저별 AI 에이전트 — character.ai 수준의 인격체 경험

**작업 항목**:
1. Solid Queue 활성화 + LLM API 연동 (`ruby-openai` 또는 Anthropic)
2. 유저 컨텍스트 벡터 관리 (`profiles.score_vector` 활용)
3. 대화 기록 영속화 + PII 분리 정책 적용
4. 유저별 AI 에이전트 페르소나 설정
5. 비용 제어 로직 (요청 수 제한, 과금 모델)
6. AI 생성 콘텐츠 법적 고지 강화
7. pgvector 도입 (유사 콘텐츠 검색, 컨텍스트 검색)

**완료 기준**:
- 유저가 캐릭터와 연속 대화 가능 (세션 간 기억 유지)
- LLM 비용이 예산 내 통제됨 (모니터링 대시보드)

**복잡도**: 매우 높음 | **의존성**: Phase 3 완료, 수익 모델 확정 필요

---

## 6. 즉시 해결해야 할 기술 부채

### 우선순위 1: 미테스트 서비스 (Wave 2 과제)

코드 점검 보고서(2026-02-22) 이후 상당 부분 테스트가 추가됐지만,
Insights 하위 모듈 6개와 TypeContentService는 여전히 미테스트 상태다.

| 서비스 | 줄 수 | 위험 | 테스트 우선순위 |
|--------|-------|------|----------------|
| CollaborationModule | 100줄 | 행동 가이드 오동작 시 무증상 | 높음 |
| ConflictModule | 99줄 | 동일 | 높음 |
| LearningModule | 103줄 | 동일 | 높음 |
| CareerModule | 111줄 | 동일 | 높음 |
| RecoveryModule | 100줄 | 동일 | 중간 |
| ExplanationBuilder | 84줄 | 설명 텍스트 오생성 | 중간 |
| TypeContentService | 49줄 | 타입별 콘텐츠 오매핑 | 낮음 |

**이 7개 서비스가 현재 테스트되지 않은 채 프로덕션 코드 경로에 있다.
비전 V1 출시 전 반드시 해결해야 한다.**

### 우선순위 2: 개발/프로덕션 DB 불일치

현재 개발 환경은 SQLite, 프로덕션은 PostgreSQL(pg gem 포함)을 사용한다.
이 불일치는 다음 문제를 야기할 수 있다:
- PostgreSQL 전용 기능(JSON 연산자, 배열 타입 등) 개발 중 테스트 불가
- V2~V5에서 pgvector, Full-Text Search 도입 시 개발 환경 재설정 비용

**권고**: 개발 환경도 PostgreSQL로 전환 (Docker Compose 또는 로컬 설치)

### 우선순위 3: personality_types 시드 데이터 부재

현재 `PersonalityType` 테이블이 비어 있으면 점수 계산 후 `Profiles::Composer`에서
`ArgumentError: Unknown personality type` 이 발생한다.
실제 사용자 테스트 전에 16개 MBTI 유형 데이터 시드가 필수다.

### 우선순위 4: Admin 인증 최종 확인

C-1 (Admin 인증 없음)이 수정 계획에 포함됐으나, 실제 `Admin::BaseController`에
HTTP Basic Auth가 적용됐는지 별도 확인이 필요하다.
프로덕션 배포 전 미완료 상태라면 전체 관리 데이터가 노출되는 심각한 보안 이슈다.

### 우선순위 5: Insights 5개 모듈의 콘텐츠 완성도

각 Insights 모듈(Collaboration, Conflict, Learning, Career, Recovery)은
`PersonalityType`의 텍스트 필드에서 콘텐츠를 가져온다.
시드 데이터 없이 또는 빈 텍스트 필드 상태에서는 의미 없는 결과가 반환된다.

---

## 요약: 비전 요소별 실현성 판정

| 비전 요소 | 판정 | 핵심 전제조건 | 예상 Phase |
|-----------|------|---------------|-----------|
| V1 성격 포탈 (콘텐츠 깊이) | 가능 | 시드 데이터 + 미테스트 7개 해결 | Phase 1~2 |
| V2 스와이프/쇼츠 UX | 조건부 가능 | ContentCard 모델 + Stimulus 커스텀 작성 | Phase 2~3 |
| V3 캐릭터 인터랙션 (매크로) | 조건부 가능 | 대화 상태 관리 테이블 + 스크립트 엔진 | Phase 3 |
| V3 캐릭터 (AI) | 조건부 가능 | LLM API + Solid Queue 활성화 | Phase 5 |
| V4 소셜 커뮤니티 | 조건부 가능 | User 모델 확장 + 소셜 스키마 전체 | Phase 4 |
| V5 유저별 AI 에이전트 | 조건부 가능 | LLM 비용 구조 + 개인정보 보호 설계 | Phase 5 |

**"불가" 판정은 없다.** 현재 Rails 8.1 + Hotwire + Solid 스택은
모든 비전 요소를 기술적으로 수용 가능하다.
핵심 변수는 기술이 아니라 **콘텐츠 생산 역량**(V1~V2)과
**비용 모델 설계**(V5)다.
