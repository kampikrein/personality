---
id: "003"
type: research
title: "AI 타로 해석 채팅 — 사전 연구"
created: 2026-04-07
status: in-progress
traces_scope: "002"
summary: >
  AI 타로 해석 채팅 기능 구현을 위한 3축 병렬 사전 연구.
  기술 구현 가능성, 사용자 기대·경험, 경쟁 서비스를 독립 조사한다.
keywords: [ai-chat, llm-api, tarot-interpretation, user-expectations, competitor-analysis]
parallel_plan:
  total_perspectives: 3
  cycles:
    - cycle: 1
      perspectives: [1, 2, 3]
      depends_on: []
      status: completed
      agent_numbers: ["004", "005", "006"]
  synthesis_number: "007"
  final_number: "008"
---

# AI 타로 해석 채팅 — 사전 연구

## Research Overview

### Background & Motivation
personality 타로 셔플 앱에 AI 기반 타로 해석 채팅 기능을 구현하기 위한 사전 연구.
`docs/11_global_tarot_market/` 글로벌 시장 조사에서 "AI + 맥락 지속성"이 글로벌 차별화 요인으로 식별됨.
현재 `mobile/lib/features/chat/`에 플레이스홀더만 존재.

### Research Scope
- **In**: LLM API 비교, 프롬프트 아키텍처, 멀티모달 출력, 맥락 지속성, 사용자 기대, 경쟁 서비스
- **Out**: 코드 구현, UI 설계, 수익 모델, 성격 유형 통합

### Research Perspectives
1. **기술 구현 가능성** — LLM API(Claude/GPT) 비교, 프롬프트 설계, 멀티모달, 맥락 지속성, 비용
2. **사용자 기대·경험** — AI 타로 해석 사용자 경험담, 기대 패턴, 해석 품질 기준
3. **경쟁 서비스 분석** — 선행 AI 타로 서비스 5~8개 심층, 기능·기술·UX·비즈니스 비교

### Dependency Analysis
3축 모두 독립 (서로 다른 질문에 독립적으로 답함) → 1사이클 병렬 실행.
교차 인사이트는 Synthesis에서 통합.

## Preliminary Findings
기존 코드베이스에서 확인된 AI 채팅 입력 데이터 구조:
- `Reading`: deckId, spreadType, question, drawnCards (cardId, position, isReversed)
- `TarotCard`: name, arcana, suit, number, imagePath, meanings (upright/reversed 키워드)
- `ReflectivePrompts`: 아케타입별 개방형 질문 22+4개 (확증 편향 완화)
- `UserSettings`: experienceLevel(1~5), selectedDeckId, allowReversed

기존 시장 조사 인사이트 (`docs/11_` Synthesis):
- "AI + 맥락 지속성 = 글로벌 차별화" — 모든 권역에서 AI 해석이 차세대 물결이나 세션 간 기억 부재가 공통 약점
- US 시장 AI 타로 33+개, 동질화 심각
- KR = 타로 전용 앱 공백 + MZ세대 72% 집중

## Parallel Execution Instructions

### Perspective 1: 기술 구현 가능성 (Technology Feasibility)

**목표**: LLM API로 개인화된 타로 해석 채팅을 구현하기 위한 기술적 선택지, 비용, 제약을 조사한다.

**조사 항목**:

1. **LLM API 비교 (Claude API vs OpenAI GPT)**
   - 타로 해석 텍스트 생성 품질: 시스템 프롬프트에 카드 데이터를 주입했을 때 해석의 깊이와 뉘앙스
   - 스트리밍 지원: SSE/WebSocket 방식, Flutter 클라이언트 연동 용이성
   - 비용 구조: input/output 토큰 단가, 배치 할인, 무료 티어
   - 레이턴시: 첫 토큰 시간(TTFT), 전체 응답 시간
   - 컨텍스트 윈도우: 카드 데이터 + 유저 맥락 + 대화 히스토리 수용 가능 크기
   - 오픈소스(Llama 3, Mistral) 보조 비교: 셀프 호스팅 비용 vs 품질

2. **프롬프트 아키텍처**
   - 시스템 프롬프트 설계: 카드 데이터(아케타입, 정/역위치, 수트) + 덱 특성(RWS 등) + 해석 사조(심리학적/상징학적/영적) 결합 방식
   - 유저 맥락 주입: experienceLevel에 따른 톤·깊이 조절, question 기반 포커싱
   - 해석 사조별 프롬프트 차이: 같은 카드를 심리학적/상징학적/영적으로 다르게 해석하는 프롬프트 구조
   - 기존 `ReflectivePrompts`의 개방형 질문과 AI 해석의 연계 방식

3. **멀티모달 출력 기술**
   - TTS: Eleven Labs, OpenAI TTS, Google Cloud TTS — 품질/비용/한국어 지원/레이턴시 비교
   - 이미지 생성: DALL-E 3, Midjourney API, Stable Diffusion — 타로 관련 이미지 생성 품질/비용
   - 영상: Runway, Pika — 실용성/비용 검토
   - 구조화 리포트: PDF 렌더링, 이미지 카드 리포트 기술

4. **맥락 지속성**
   - Conversation memory 패턴: sliding window, hierarchical summary, hybrid
   - RAG(검색 증강 생성): 과거 리딩 데이터를 벡터 DB에 저장 → 유사 리딩 검색·주입
   - 기존 `Reading` 엔티티 → AI 컨텍스트 변환: drawnCards + question + notes → 프롬프트
   - 토큰 비용 최적화: 긴 히스토리를 요약하여 컨텍스트 윈도우 내 유지

5. **비용 모델링**
   - 1회 타로 리딩 해석의 예상 토큰 소비 (input: 카드 데이터 + 유저 맥락 + 히스토리, output: 해석 텍스트)
   - 멀티모달 추가 비용: TTS/이미지 생성 단가
   - 사용자당 월간 예상 비용

**참조 파일**:
- `mobile/lib/features/reading/domain/entities/reading.dart`
- `mobile/lib/features/deck/domain/entities/card_meanings.dart`
- `mobile/lib/features/deck/domain/entities/tarot_card.dart`
- `mobile/lib/features/reading/domain/entities/reflective_prompts.dart`
- `mobile/lib/features/settings/domain/entities/user_settings.dart`

**웹 리서치 대상**: Claude API 문서, OpenAI API 문서, Eleven Labs 가격, TTS 비교, 타로 AI 프롬프트 사례

### Perspective 2: 사용자 기대·경험 (User Expectations)

**목표**: AI 타로 해석에 대한 실제 사용자의 기대, 경험담, 불만 패턴을 수집·구조화한다.

**조사 항목**:

1. **사용자 경험담 수집** (웹 리서치)
   - Reddit (r/tarot, r/divination, r/tarotreading 등)에서 AI 타로 해석 사용 경험 포스트
   - AI 타로 앱 리뷰 (App Store, Google Play)에서 긍정/부정 패턴
   - Twitter/X, TikTok 등 SNS에서 AI 타로 관련 반응
   - 긍정 경험: 무엇이 만족스러웠는가 (개인화, 깊이, 편의성, 접근성)
   - 부정 경험: 무엇이 실망스러웠는가 (바넘 효과, 피상적, 반복적, 감정 부족)

2. **기대 패턴 구조화**
   - 해석 깊이 기대: 키워드 나열 vs 내러티브 해석 vs 심리학적 분석
   - 개인화 기대: 일반 해석 vs "나의 상황에 맞는" 해석 — 어떤 개인정보를 공유하고 싶어하는가
   - 상호작용 기대: 일방향 해석 vs 대화형 탐구 (후속 질문, 카드 간 관계)
   - 감성적 기대: 위안, 통찰, 재미, 영적 경험 — 사용 동기별 기대 차이

3. **해석 품질 기준** (심리학적 관점)
   - 바넘 효과(Barnum Effect) 회피 전략: 구체적 vs 범용적 해석의 균형
   - 확증 편향: 사용자가 원하는 답만 찾는 경향 vs 개방형 해석의 가치
   - 학술적 근거 있는 해석 vs 전통적 직관 해석의 밸런스
   - `ReflectivePrompts`의 확증 편향 완화 접근(Arkes, 1991)과 AI 해석의 연계

4. **기존 시장 조사 인사이트 심화**
   - `docs/11_global_tarot_market/009_Synthesis`의 13개 페르소나 중 AI 해석 관련 기대 심화
   - 권역별 AI 해석 수용도 차이 (KR: 위안, US: 웰니스, JP: 연애)
   - "이벤트형" vs "학습형" vs "일상형" 사용자별 AI 해석 기대 차이

**웹 리서치 대상**: Reddit AI tarot experiences, AI tarot app reviews, tarot AI chatbot user feedback, Barnum effect in tarot

**참조 문서**:
- `docs/11_global_tarot_market/009_Synthesis_global_tarot_market.md`
- `docs/11_global_tarot_market/005_Research_user_culture.md`
- `mobile/lib/features/reading/domain/entities/reflective_prompts.dart`

### Perspective 3: 경쟁 서비스 분석 (Competitor Analysis)

**목표**: AI 타로 해석을 제공하는 선행 서비스들의 기능, 기술, UX, 비즈니스 모델을 심층 분석한다.

**조사 항목**:

1. **주요 서비스 선별 (5~8개)**
   - 글로벌 AI 타로 앱/서비스 식별 (미국/한국/일본 중심)
   - 선별 기준: 사용자 수, 리뷰 점수, 기능 차별성, AI 활용도
   - `docs/11_` Synthesis에서 식별된 US AI 타로 33+개 앱을 기반으로 대표 선별

2. **서비스별 심층 분석 프레임워크**
   - AI 해석 방식: 어떤 LLM 사용 추정, 해석 깊이, 개인화 수준, 사조 반영 여부
   - 멀티모달 지원: 텍스트 외 음성/이미지/영상 지원 여부
   - 맥락 유지: 세션 간 기억 여부, 과거 리딩 참조 기능
   - UX: 채팅 인터페이스 형태, 카드 선택 → 해석 전달 플로우, 제의적 경험 유무
   - 비즈니스 모델: 과금 구조 (구독/크레딧/일회성), 무료 범위, 프리미엄 기능
   - 사용자 반응: 앱 스토어 리뷰에서 드러나는 강점/약점/불만

3. **차별화 기회 식별**
   - personality 앱의 고유 자산과의 결합 가능성:
     - 물리 셔플 엔진 (Flutter Flame 기반) — 경쟁사 대부분 "탭하여 선택"
     - 제의적 UX (의도 설정 → 셔플 → 카드 뽑기 의식)
     - `ReflectivePrompts`의 심리학적 접근
   - 경쟁 서비스가 놓치고 있는 영역:
     - 맥락 지속성 (대부분 단발 세션)
     - 해석 사조 다양성 (대부분 RWS 일원화)
     - 바넘 효과 인지/회피 (대부분 범용적 해석)

4. **기존 분석 활용**
   - `docs/11_global_tarot_market/004_Research_service_taxonomy.md` — 서비스 유형 택소노미의 "AI 해석형"
   - 기존 식별된 33+개 US AI 타로 앱 목록에서 대표 선별

**웹 리서치 대상**: AI tarot apps comparison, best AI tarot reading apps 2025 2026, tarot AI chatbot services, Co-Star, Sanctuary, Labyrinthos, Golden Thread, Tarot.com AI

**참조 문서**:
- `docs/11_global_tarot_market/009_Synthesis_global_tarot_market.md`
- `docs/11_global_tarot_market/004_Research_service_taxonomy.md`
- `docs/11_global_tarot_market/003_Research_market_overview.md`

## Remaining Work
- [ ] Perspective 1: 기술 구현 가능성
- [ ] Perspective 2: 사용자 기대·경험
- [ ] Perspective 3: 경쟁 서비스 분석
- [ ] Cross-Analysis
- [ ] Comprehensive Conclusion

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 450s | 293581 |
| 2 | user-ai-exchange | 247s | 1287291 |
| 3 | user-ai-exchange | 4s | 84842 |
| 4 | user-ai-exchange | 24s | 433132 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 4368s |
| Total Tokens | 2098846 |
| Input Tokens | 39 |
| Output Tokens | 22771 |
| Cache Read | 1981109 |
| Cache Creation | 94927 |
