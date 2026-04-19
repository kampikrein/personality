---
id: "002"
type: scope
title: "AI 타로 해석 채팅 — 사전 연구 Scope"
created: 2026-04-07
traces_brief: "001"
complexity: simple
research_needed: true
research_reason: "3축(기술/시장·사용자/경쟁) 병렬 연구가 Brief의 전체 목적. LLM API, 시장 기대, 경쟁 서비스 등 외부 조사 필수."
auto_run: false
effort_mode: bypass
tdd_mode: false
uncertainty_level: medium
research_axes:
  - axis: "기술 구현 가능성"
    question: "LLM API(Claude/GPT)로 개인화된 타로 해석 채팅을 어떻게 구현할 수 있는가? 프롬프트 아키텍처, 멀티모달 출력, 맥락 지속성의 기술적 선택지와 비용은?"
    source: "Brief In Scope #1,2,3,4,7"
  - axis: "사용자 기대·경험"
    question: "AI 타로 해석에 대한 실제 사용자의 기대, 경험담, 불만 패턴은 무엇인가? 어떤 경험을 원하고 어떤 점에서 실망하는가?"
    source: "Brief In Scope #5,8"
  - axis: "경쟁 서비스 분석"
    question: "AI 타로 해석을 제공하는 선행 서비스들의 기능, 기술 스택, UX, 비즈니스 모델은? 차별화 기회는 어디에?"
    source: "Brief In Scope #6"
research_cycles: 1
intent: >
  personality 타로 셔플 앱에 AI 기반 타로 해석 채팅 기능을 구현하기 위한 사전 연구.
  기술 가능성(LLM API, 프롬프트, 개인화, 멀티모달), 시장·사용자 기대, 경쟁 서비스를 3축으로 조사한다.
summary: >
  docs-only 연구 태스크. 3개 연구 축(기술/시장·사용자/경쟁)을 병렬 사이클로 조사.
  기존 글로벌 시장 조사(docs/11_)를 기반으로 AI 해석 특화 심화.
  코드 변경 없음 — 연구 완료 후 별도 구현 scope 수립 예정.
keywords: [scope, ai-chat, research, llm-api, market, competitor, tarot-interpretation]
---

# AI 타로 해석 채팅 — 사전 연구 Scope

## 작업 목표

Brief(`001_Brief_ai_tarot_interpretation_chat.md`)에서 정의된 3축 병렬 연구를 실행하기 위한 연구 스코프.

**목표**: AI 타로 해석 채팅 기능의 기술적 구현 방향, 시장 내 사용자 기대, 경쟁 서비스 현황을 체계적으로 조사하여, 후속 구현 파이프라인의 의사결정 기반을 마련한다.

**제약**:
- 코드 변경 없음 (`docs/12_ai_tarot_chat/` 산출물만 생성)
- 기존 `docs/11_global_tarot_market/` 조사 결과를 기반으로 심화 — 중복 시장 조사 회피
- 전문 에이전트 위임: tarot-expert(해석 도메인), psychology-expert(해석 품질), uiux-expert(UX 관점)

**성공 기준**:
- 3축 각각에 대한 구조화된 연구 문서 생성
- LLM API 비교(Claude vs GPT)의 타로 해석 적합성 평가
- 사용자 기대·경험 패턴의 구조화
- 주요 경쟁 서비스 5~8개 심층 분석
- 기존 코드베이스(Reading, CardMeanings, UserSettings)와의 연결 지점 식별

## 접근 방향

**선택**: 3축 병렬 연구 (`/research` 스킬의 에이전트 파견 패턴)

각 축이 독립적 조사 방식을 요구하므로 병렬 실행이 최적:
- 축 1 (기술): 코드베이스 탐색 + API 문서/벤치마크 웹 리서치
- 축 2 (시장·사용자): 웹 리서치 (커뮤니티, 리뷰, 경험담)
- 축 3 (경쟁): 서비스 분석 + 웹 리서치 (앱 스토어, 기능 비교)

**기각된 대안**:
- 단일 통합 연구: 범위가 넓어 에이전트 1개로는 깊이 부족
- 5축 세분화 (멀티모달/맥락지속성 별도): 오버헤드가 인사이트를 초과

## Research 판단

- **판단**: 필요 (전체 작업이 연구)
- **근거**: 외부 API/라이브러리 조사 (LLM API), 시장/사용자 데이터 수집, 경쟁 서비스 분석 — 모두 코드베이스 외부 정보 필요
- **파이프라인**: Research Phase (1사이클, 3축 병렬 에이전트 파견 + synthesis) → 완료 (impl phase 없음 — 구현은 별도 scope)

## 연구 축 상세

### 축 1: 기술 구현 가능성 (Technology Feasibility)

**핵심 질문**: LLM API로 개인화된 타로 해석 채팅을 어떻게 구현할 수 있는가?

**조사 항목**:
1. **LLM API 비교** (Claude API vs OpenAI GPT)
   - 타로 해석 텍스트 생성 품질, 스트리밍 지원, 비용 구조, 레이턴시
   - 시스템 프롬프트 길이 제한 및 컨텍스트 윈도우 활용 전략
   - 오픈소스(Llama, Mistral) 보조 비교
2. **프롬프트 아키텍처**
   - 카드 데이터(아케타입, 정/역위치, 수트) + 덱 특성 + 해석 사조를 결합하는 시스템 프롬프트 설계
   - 유저 맥락(experienceLevel, question, 과거 리딩) 주입 전략
   - 해석 톤·깊이 조절 메커니즘 (초보자 vs 숙련자)
3. **멀티모달 출력**
   - TTS: Eleven Labs, OpenAI TTS, Google Cloud TTS — 품질/비용/한국어 지원
   - 이미지 생성: DALL-E 3, Midjourney API, Stable Diffusion — 타로 카드 관련 이미지
   - 영상: Runway, Pika 등 — 비용/실용성 검토
   - 구조화 리포트: PDF/이미지 렌더링 기술
4. **맥락 지속성**
   - Conversation memory: sliding window, hierarchical summary
   - RAG 패턴: 과거 리딩 데이터 검색·주입
   - 기존 `Reading` 엔티티 → AI 컨텍스트 변환 방식
5. **비용 모델링**
   - 사용자당 평균 토큰 소비 추정
   - 멀티모달 추가 비용 영향

**참조 코드베이스**:
- `mobile/lib/features/reading/domain/entities/reading.dart` — Reading, DrawnCardInfo
- `mobile/lib/features/deck/domain/entities/card_meanings.dart` — CardMeanings (upright/reversed)
- `mobile/lib/features/deck/domain/entities/tarot_card.dart` — TarotCard (arcana, suit, number)
- `mobile/lib/features/reading/domain/entities/reflective_prompts.dart` — 정적 프롬프트 22+4개
- `mobile/lib/features/settings/domain/entities/user_settings.dart` — experienceLevel, selectedDeckId

### 축 2: 사용자 기대·경험 (User Expectations)

**핵심 질문**: AI 타로 해석에 대한 실제 사용자의 기대와 경험 패턴은?

**조사 항목**:
1. **사용자 경험담 수집**
   - Reddit, 앱 리뷰, SNS에서 AI 타로 해석 사용 경험 패턴
   - 긍정 경험: 무엇이 만족스러웠는가
   - 부정 경험: 무엇이 실망스러웠는가 (바넘 효과, 피상적 해석 등)
2. **기대 패턴 구조화**
   - 해석 깊이 기대 (키워드 나열 vs 내러티브 해석 vs 심리학적 분석)
   - 개인화 기대 (일반 해석 vs 나의 상황에 맞는 해석)
   - 상호작용 기대 (일방향 해석 vs 대화형 탐구)
   - 감성적 기대 (위안, 통찰, 재미, 영적 경험)
3. **해석 품질 기준**
   - 바넘 효과 회피 전략
   - 학술적 근거 있는 해석 vs 전통적 직관 해석 밸런스
   - `ReflectivePrompts`의 확증 편향 완화 접근과 AI 해석의 연계
4. **`docs/11_` 기존 인사이트 심화**
   - 13개 페르소나의 AI 해석 관련 기대 심화 분석
   - 권역별 AI 해석 수용도 차이

**전문 에이전트**: psychology-expert (바넘 효과, 해석 품질), tarot-expert (해석 깊이, 사조)

### 축 3: 경쟁 서비스 분석 (Competitor Analysis)

**핵심 질문**: AI 타로 해석 선행 서비스의 기능·모델·차별점은?

**조사 항목**:
1. **주요 서비스 선별 (5~8개)**
   - 글로벌 AI 타로 앱/서비스 식별 (미국/한국/일본 중심)
   - 선별 기준: 사용자 수, 리뷰 점수, 기능 차별성
2. **서비스별 심층 분석**
   - 기능: AI 해석 방식, 개인화 수준, 멀티모달 지원, 맥락 유지
   - 기술 스택: 사용 LLM 추정, 프롬프트 전략 추정
   - UX: 채팅 인터페이스, 카드 선택 → 해석 전달 플로우
   - 비즈니스 모델: 과금 구조 (구독/크레딧/일회성)
   - 사용자 반응: 앱 리뷰에서 드러나는 강점/약점
3. **차별화 기회 식별**
   - personality 앱의 고유 자산 (물리 셔플 엔진, 제의적 UX)과의 결합 가능성
   - 경쟁 서비스가 놓치고 있는 영역 (맥락 지속성, 해석 사조 다양성 등)
4. **`docs/11_` 기존 분석 활용**
   - 서비스 유형 택소노미의 "AI 해석형" 카테고리 심화
   - 기존 식별된 33+개 US AI 타로 앱에서 대표 선별

**전문 에이전트**: tarot-expert (서비스 도메인 평가), uiux-expert (UX 비교)

## 파일 목록

**Modified (actual change)**: 없음 — docs 산출물만 생성
**Reviewed (check-only)**:
- `mobile/lib/features/reading/domain/entities/reading.dart` — AI 입력 데이터 구조 확인
- `mobile/lib/features/deck/domain/entities/tarot_card.dart` — 카드 데이터 모델 확인
- `mobile/lib/features/deck/domain/entities/card_meanings.dart` — 의미 데이터 구조 확인
- `mobile/lib/features/reading/domain/entities/reflective_prompts.dart` — 기존 프롬프트 패턴 확인
- `mobile/lib/features/settings/domain/entities/user_settings.dart` — 개인화 입력 확인
- `mobile/lib/features/chat/presentation/pages/chat_page.dart` — 현재 플레이스홀더 상태 확인
- `docs/11_global_tarot_market/009_Synthesis_global_tarot_market.md` — 기존 시장 조사 인사이트
- `docs/11_global_tarot_market/004_Research_service_taxonomy.md` — 서비스 유형 분류

파일 수 confidence: **high** (코드 변경 없음, docs 생성만)

## 산출물 예상

| 축 | 산출물 | 위치 |
|----|--------|------|
| 기술 구현 가능성 | Research 문서 | `docs/12_ai_tarot_chat/003_Research_tech_feasibility.md` |
| 사용자 기대·경험 | Research 문서 | `docs/12_ai_tarot_chat/004_Research_user_expectations.md` |
| 경쟁 서비스 분석 | Research 문서 | `docs/12_ai_tarot_chat/005_Research_competitor_analysis.md` |
| 종합 | Synthesis 문서 | `docs/12_ai_tarot_chat/006_Synthesis_ai_chat_research.md` |

**실행 구조**: 1사이클 내 3개 에이전트 병렬 파견 → 각 축 독립 조사 → Synthesis에서 교차 통합.
축 간 의존성 없음 — eval 불필요.

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 450s | 293581 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 450s |
| Total Tokens | 293581 |
| Input Tokens | 9 |
| Output Tokens | 8883 |
| Cache Read | 233944 |
| Cache Creation | 50745 |
