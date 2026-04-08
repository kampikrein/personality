---
id: "004"
type: agent-report
title: "기술 구현 가능성 — AI 타로 해석 채팅"
created: 2026-04-07
status: completed
perspective: "tech-feasibility"
target: "003"
confidence: high
summary: >
  Claude Sonnet 4.6과 GPT-4.1을 양대 축으로 비교 분석한 결과, 타로 해석 채팅의 기술적 구현은
  충분히 가능하며, 1회 리딩당 텍스트 해석 비용은 $0.001~$0.05 수준으로 상업적으로 실현 가능하다.
  멀티모달(TTS/이미지/영상) 확장 시 비용이 10~100배 증가하므로 단계적 도입이 필수적이다.
keywords: [llm-api, claude, gpt, tts, multimodal, rag, cost-modeling, flutter, streaming, prompt-architecture]
---

# 기술 구현 가능성 — AI 타로 해석 채팅

## Executive Summary

LLM API를 활용한 개인화 타로 해석 채팅은 기술적으로 완전히 실현 가능하다. Claude Sonnet 4.6($3/$15/MTok)과 GPT-4.1($2/$8/MTok)이 비용 대비 품질 최적점이며, 두 모델 모두 1M 토큰 컨텍스트 윈도우를 지원하여 과거 리딩 히스토리까지 포함한 풍부한 맥락 주입이 가능하다. 1회 타로 리딩 해석의 텍스트 비용은 $0.003~$0.05 수준으로 매우 저렴하며, 프롬프트 캐싱을 활용하면 90% 비용 절감이 가능하다. Flutter 앱에서의 SSE 스트리밍 연동은 `flutter_client_sse`, `dio_sse_client` 등의 패키지로 모바일/데스크톱에서 안정적으로 지원된다. TTS(한국어), 이미지 생성, 영상 생성은 모두 API로 구현 가능하나, 비용이 텍스트 대비 10~100배 높으므로 텍스트 채팅 → 리포트 → TTS → 이미지 → 영상 순서의 단계적 확장이 권장된다.

---

## 1. LLM API 비교 (Claude vs GPT)

### 1.1 가격·성능·기능 비교 테이블

#### 주요 모델 비교 (2026년 4월 기준)

| 모델 | Input $/MTok | Output $/MTok | 캐시 읽기 $/MTok | 컨텍스트 | 특징 |
|------|-------------|--------------|-----------------|---------|------|
| **Claude Opus 4.6** | $5.00 | $25.00 | $0.50 | 1M | 최고 품질, 복잡한 추론 |
| **Claude Sonnet 4.6** | $3.00 | $15.00 | $0.30 | 1M | 균형 (품질/비용), SWE-bench 79.6% |
| **Claude Haiku 4.5** | $1.00 | $5.00 | $0.10 | 1M | 최저가, 고속, 분류/추출용 |
| **GPT-4.1** | $2.00 | $8.00 | $0.50 | 1M | OpenAI 권장 프로덕션 모델 |
| **GPT-4.1 mini** | $0.20 | $0.80 | $0.10 | 1M | 초저가, 경량 태스크 |
| **GPT-4.1 nano** | $0.10 | $0.40 | $0.025 | 1M | 최저가, 대량 처리용 |
| **GPT-4o** | $2.50 | $10.00 | $1.25 | 128K | 멀티모달(음성/이미지) |
| **GPT-4o-mini** | $0.15 | $0.60 | $0.075 | 128K | 경량 멀티모달 |
| **GPT-5.4** | $2.50 | $15.00 | $0.25 | — | OpenAI 최신 플래그십 |

#### 배치 API 할인 (50%)

| 모델 | Batch Input $/MTok | Batch Output $/MTok |
|------|-------------------|-------------------|
| Claude Sonnet 4.6 | $1.50 | $7.50 |
| Claude Haiku 4.5 | $0.50 | $2.50 |

#### 프롬프트 캐싱 비교

| 제공자 | 캐시 쓰기 비용 | 캐시 읽기 비용 | 캐시 유효 시간 |
|--------|-------------|-------------|-------------|
| **Anthropic** | 1.25x (5분) / 2x (1시간) | **0.1x** (90% 절감) | 5분 / 1시간 |
| **OpenAI** | 기본가 동일 | **0.5x** (50% 절감) | 자동 관리 |

> **핵심 인사이트**: Anthropic의 프롬프트 캐싱이 OpenAI 대비 캐시 히트 시 비용 절감률이 훨씬 높다(90% vs 50%). 타로 해석 시스템 프롬프트(카드 데이터, 덱 특성, 해석 사조 등)는 대부분 고정되므로, 프롬프트 캐싱의 효과가 극대화된다.

### 1.2 타로 해석 적합성 평가

#### Claude 계열 장점
- **뉘앙스 있는 텍스트 생성**: 상징적·시적 언어가 타로 해석에 적합한 Claude의 문체적 강점
- **긴 시스템 프롬프트 처리**: 1M 컨텍스트 + 90% 캐시 절감 → 상세한 카드 데이터·해석 사조·유저 맥락 주입에 유리
- **한국어 품질**: Claude 4.x 세대의 다국어 성능이 크게 향상됨
- **프로젝트 친숙도**: personality 프로젝트가 이미 Claude 생태계(Claude Code) 기반

#### GPT 계열 장점
- **더 낮은 단가**: GPT-4.1이 $2/$8로 Sonnet 4.6의 $3/$15 대비 약 47% 저렴
- **초저가 모델**: GPT-4.1 nano($0.10/$0.40)는 간단한 분류/라우팅 태스크에 최적
- **멀티모달 통합**: GPT-4o 계열이 음성·이미지 입출력을 단일 모델로 지원
- **파인튜닝**: GPT-4.1 mini에서 파인튜닝 지원 → 타로 해석 특화 가능

#### 타로 해석 요구사항 매핑

| 요구사항 | Claude Sonnet 4.6 | GPT-4.1 | 추천 |
|---------|-------------------|---------|------|
| 해석 텍스트 품질 (뉘앙스·깊이) | ★★★★★ | ★★★★ | Claude |
| 한국어 자연스러움 | ★★★★★ | ★★★★ | Claude |
| 비용 효율성 | ★★★★ | ★★★★★ | GPT |
| 스트리밍 성능 | ★★★★★ | ★★★★★ | 동등 |
| 캐싱 비용 절감 | ★★★★★ (90%) | ★★★ (50%) | Claude |
| 멀티모달 통합 | ★★★ | ★★★★★ | GPT |
| 파인튜닝 | ✗ (미지원) | ★★★★ | GPT |

### 1.3 스트리밍 & Flutter 연동

#### 아키텍처 설계

```
Flutter App ←→ Rails Backend ←→ LLM API
   (SSE)          (Proxy)       (SSE/WebSocket)
```

**왜 Rails Proxy가 필요한가:**
- API 키를 클라이언트에 노출하지 않음 (보안)
- 요청 제한(rate limiting), 사용량 추적, 과금 관리
- 프롬프트 주입 공격 방어
- 응답 필터링 (부적절 콘텐츠 차단)

#### Flutter SSE 스트리밍 구현

**사용 가능한 Dart 패키지:**
- `flutter_client_sse` — SSE 이벤트 파싱, 스트림 기반 API
- `dio_sse_client` — Dio HTTP 클라이언트 기반 SSE
- `sse` — 양방향 SSE 통신

**플랫폼별 지원 상태:**
| 플랫폼 | SSE 스트리밍 | 비고 |
|--------|-----------|------|
| Android | ✅ 안정 | Dart HttpClient 기반 |
| iOS | ✅ 안정 | Dart HttpClient 기반 |
| Web | ⚠️ 제한적 | 브라우저 fetch API 제약 — Flutter AI Toolkit 이슈 #172030 |
| Desktop | ✅ 안정 | Dart HttpClient 기반 |

> **Flutter AI Toolkit**: Flutter 공식 AI 채팅 위젯 세트. 추상 `LlmProvider` API로 LLM 제공자를 교체할 수 있으며, 실시간 스트리밍 표시를 지원한다. 단, 현재 Flutter Web에서 스트리밍이 작동하지 않는 제한이 있으나, 모바일 앱 우선 전략에서는 문제없다.

#### Rails 백엔드 SSE 중계

Rails 8+의 ActionController::Live를 활용하여 SSE 스트리밍 중계 가능:

```ruby
# 개념적 구조 — 실제 구현은 후속 scope
class Api::V1::ChatController < ApplicationController
  include ActionController::Live

  def stream
    response.headers['Content-Type'] = 'text/event-stream'
    sse = SSE.new(response.stream)

    client.messages.create(stream: true) do |event|
      sse.write(event.delta, event: 'message')
    end
  ensure
    sse.close
  end
end
```

### 1.4 추천

**1차 추천: Claude Sonnet 4.6 (메인) + Claude Haiku 4.5 (보조)**

- **Sonnet 4.6**: 타로 해석 본문 생성 — 뉘앙스 있는 한국어, 90% 캐시 절감, 1M 컨텍스트
- **Haiku 4.5**: 의도 분류, 대화 요약, 간단한 후속 질문 처리 등 경량 태스크
- **근거**: 프롬프트 캐싱 효과가 타로 해석처럼 고정 시스템 프롬프트가 큰 유스케이스에서 극대화됨

**2차 대안: GPT-4.1 (메인) + GPT-4.1 nano (보조)**

- 비용 최적화가 최우선일 경우 선택
- GPT-4.1 nano는 Haiku 4.5보다 10배 저렴 ($0.10 vs $1.00/MTok input)

**멀티 프로바이더 전략** (중장기):
- Rails 백엔드에 LLM Provider 추상화 레이어 구축
- 모델 성능·비용을 모니터링하며 동적으로 최적 모델 선택
- A/B 테스트로 사용자 만족도 기반 모델 선택

---

## 2. 프롬프트 아키텍처 설계 방향

### 2.1 시스템 프롬프트 구조

타로 해석 프롬프트는 **5개 레이어**로 구조화한다:

```
┌─────────────────────────────────────────┐
│ Layer 1: 페르소나 & 해석 사조           │ ← 캐시 대상 (고정)
│ - 해석자 역할 정의                       │
│ - 해석 사조 (심리학적/상징학적/영적)      │
│ - 윤리 가이드라인 (바넘 효과 회피 등)     │
├─────────────────────────────────────────┤
│ Layer 2: 덱 & 카드 레퍼런스 데이터       │ ← 캐시 대상 (덱별 고정)
│ - 덱 특성 (RWS, 마르세유 등)             │
│ - 78장 카드 기본 의미 데이터              │
│ - 아케타입/수트/번호 체계                 │
├─────────────────────────────────────────┤
│ Layer 3: 유저 프로필 & 맥락              │ ← 세션별 변동
│ - experienceLevel (1~5)                  │
│ - 과거 리딩 요약 (RAG 결과)              │
│ - 개인 성장 패턴                         │
├─────────────────────────────────────────┤
│ Layer 4: 현재 리딩 데이터                │ ← 요청별 변동
│ - 뽑힌 카드들 (정/역위치)                │
│ - 스프레드 타입 & 포지션 의미             │
│ - 유저의 질문                            │
├─────────────────────────────────────────┤
│ Layer 5: 대화 히스토리                   │ ← 턴별 증가
│ - 이전 대화 (sliding window)             │
│ - 대화 요약 (압축)                       │
└─────────────────────────────────────────┘
```

**캐싱 전략**: Layer 1~2는 Anthropic의 1시간 캐시($0.30/MTok 읽기)를 활용하여 비용을 90% 절감. Layer 3~5만 매 요청마다 새로 처리.

**예상 토큰 사용량:**

| 레이어 | 예상 토큰 | 캐시 여부 |
|--------|---------|---------|
| Layer 1: 페르소나 & 사조 | ~800 | ✅ 캐시 |
| Layer 2: 덱 & 카드 데이터 (78장 요약) | ~3,000 | ✅ 캐시 |
| Layer 3: 유저 프로필 | ~500 | 세션 캐시 |
| Layer 4: 현재 리딩 | ~300 | ✗ |
| Layer 5: 대화 히스토리 | ~1,000~5,000 | ✗ |
| **총 Input** | **~5,600~9,600** | — |
| **Output (해석 텍스트)** | **~1,000~2,000** | — |

### 2.2 유저 맥락 주입 전략

기존 코드베이스의 엔티티를 직접 활용하는 매핑:

**`UserSettings` → 해석 톤·깊이 조절:**

| `experienceLevel` | 해석 스타일 | 프롬프트 지시 |
|-------------------|-----------|-------------|
| 1 (입문) | 쉬운 언어, 일상 비유, 핵심만 | "타로를 처음 접하는 사람에게 설명하듯 간결하고 따뜻하게" |
| 2~3 (초중급) | 상징 설명 포함, 적당한 깊이 | "카드의 상징과 의미를 설명하되 전문 용어는 풀어서" |
| 4 (숙련) | 상징 체계 깊이, 카드 간 관계 | "아케타입과 수트 간의 관계, 수비학적 의미를 포함하여" |
| 5 (전문) | 전통 해석 + 학술적 관점 | "에소테릭 전통과 현대 심리학적 관점을 교차하여 깊이 있게" |

**`Reading` → 카드 데이터 주입:**

현재 `Reading` 엔티티 구조 (`mobile/lib/features/reading/domain/entities/reading.dart`):

```dart
Reading {
  id, deckId, spreadType, question?, notes?,
  drawnCards: [DrawnCardInfo { cardId, position, isReversed }],
  createdAt
}
```

이를 프롬프트용 구조화 텍스트로 변환:

```
[현재 리딩]
질문: "새 직장에서의 적응이 걱정됩니다"
스프레드: 과거-현재-미래 (3카드)
카드 1 (과거): The Hermit (정위치) — 위치: 과거
카드 2 (현재): Three of Swords (역위치) — 위치: 현재
카드 3 (미래): The Star (정위치) — 위치: 미래
```

**`CardMeanings` → 카드별 시드 데이터:**

```dart
CardMeanings {
  upright: List<String>,    // ["지혜", "내면 탐구", "고독의 가치"]
  reversed: List<String>,   // ["고립", "외로움", "과도한 은둔"]
  customNotes: String?      // 사용자 커스텀 메모
}
```

→ LLM에 키워드 리스트를 제공하되, "이 키워드를 출발점으로 유저의 질문과 상황에 맞게 해석을 발전시켜라"는 지시와 함께 주입.

### 2.3 해석 사조별 프롬프트 차이

동일한 카드(예: The Tower, 역위치)에 대해 3가지 사조별 프롬프트 분기:

**심리학적 해석 (Psychological)**
```
당신은 융 분석심리학에 기반한 타로 상담사입니다.
카드의 아케타입을 집단 무의식의 원형으로 해석하고,
유저의 현재 심리 상태와 연결하여 자기 이해를 돕습니다.
바넘 효과를 경계하여, 유저의 구체적 상황에 맞는 통찰을 제공합니다.
확증 편향을 방지하기 위해 개방형 질문을 포함합니다.
```

**상징학적 해석 (Symbolic/Esoteric)**
```
당신은 서양 에소테릭 전통에 기반한 타로 해석가입니다.
카드의 수비학, 카발라 대응, 점성술 연결, 원소 상징을 해석하고,
RWS(Rider-Waite-Smith) 이미지의 상징적 디테일을 분석합니다.
각 상징이 유저의 질문과 어떻게 연결되는지 설명합니다.
```

**영적 해석 (Spiritual/Intuitive)**
```
당신은 직관적이고 영적인 타로 리더입니다.
카드의 에너지와 메시지를 따뜻하고 공감적인 어조로 전달하고,
유저의 내면 여정과 영적 성장의 맥락에서 해석합니다.
위안과 용기를 주되, 맹목적 긍정이나 예언적 단정은 피합니다.
```

### 2.4 기존 ReflectivePrompts와의 연계

현재 `ReflectivePrompts` 클래스 (`mobile/lib/features/reading/domain/entities/reflective_prompts.dart`)는 아케타입별 개방형 질문 22+4개를 제공하며, Arkes(1991)의 확증 편향 완화 전략에 기반한다.

**연계 방식:**

1. **AI 해석 후 반성 질문 제시**: AI가 해석을 마친 뒤, 해당 카드의 `ReflectivePrompts.getPrompt(cardId)`를 대화에 포함 → 사용자가 AI 해석에 수동적으로 수용하는 것이 아니라 자기 성찰로 이어지도록 유도

2. **프롬프트 내 바넘 효과 방어**: 시스템 프롬프트에 기존 반성 질문의 설계 철학을 주입:
   ```
   해석이 "누구에게나 해당될 수 있는 일반론"이 되지 않도록,
   유저의 구체적 질문과 상황에 직접 연결하라.
   해석 마지막에 확증 편향을 깨는 개방형 질문을 1개 포함하라.
   ```

3. **기존 프롬프트 확장**: 현재 22(메이저) + 4(수트)개의 정적 프롬프트를 AI가 동적으로 확장 → 카드 조합과 유저 맥락에 따라 맞춤형 반성 질문 생성

---

## 3. 멀티모달 출력 기술

### 3.1 TTS 비교 (한국어 중심)

#### 서비스 비교 테이블

| 서비스 | 한국어 | 가격 | 음질 | 레이턴시 | 특징 |
|--------|-------|------|------|---------|------|
| **ElevenLabs** Multilingual v2 | ✅ (29개 언어) | ~$0.30/1K자 (Creator) | ★★★★★ 최고 | 보통 | 가장 자연스러운 감정 표현, 음성 클론 |
| **ElevenLabs** Flash v2.5 | ✅ (32개 언어) | 동일 | ★★★★ | **75ms** 초저지연 | 실시간 대화용 최적 |
| **ElevenLabs** Eleven v3 | ✅ (74개 언어) | 동일 (8x 문자 제한) | ★★★★★ | 보통 | 최다 언어 지원 |
| **OpenAI** tts-1 | ✅ | $15/1M자 ($0.015/1K자) | ★★★ | 빠름 | 가장 저렴 |
| **OpenAI** tts-1-hd | ✅ | $30/1M자 ($0.030/1K자) | ★★★★ | 보통 | HD 품질 |
| **OpenAI** gpt-4o-mini-tts | ✅ | $12/MTok 오디오 출력 | ★★★★ | 빠름 | 감정/어조 프롬프트 제어 가능 |
| **Google Cloud** Standard | ✅ | $4/1M자 | ★★ | 빠름 | 첫 4M자/월 무료 |
| **Google Cloud** WaveNet/Neural2 | ✅ | $16/1M자 | ★★★★ | 보통 | 첫 1M자/월 무료 |
| **Google Cloud** Chirp 3 HD | ✅ | $30/1M자 | ★★★★★ | 느림 | 최신 고품질 |

#### 타로 해석 TTS 추천

**1차 추천: OpenAI tts-1-hd** ($0.030/1K자)
- 비용 효율적이면서 HD 품질
- 한국어 지원 확인됨
- OpenAI API 키 하나로 LLM + TTS 통합 관리 가능
- 1,000자 해석 텍스트 → 약 $0.03/회

**프리미엄 옵션: ElevenLabs Multilingual v2**
- 가장 자연스러운 감정 표현 — 타로 해석의 분위기 전달에 최적
- 비용이 약 10배 높음 ($0.30/1K자)
- 프리미엄 구독 사용자 전용으로 제공 시 차별화

**무료 티어 활용: Google Cloud Standard**
- 월 4M자 무료 → 초기 단계 프로토타이핑에 활용
- 품질은 가장 낮으나, 비용 제로

#### 비용 추정 (1,000자 한국어 해석 기준)

| 서비스 | 1회 비용 | 월 100회 | 월 1,000회 |
|--------|---------|---------|-----------|
| OpenAI tts-1 | $0.015 | $1.50 | $15.00 |
| OpenAI tts-1-hd | $0.030 | $3.00 | $30.00 |
| ElevenLabs (Creator) | $0.300 | $30.00 | $300.00 |
| Google WaveNet | $0.016 | $1.60 | $16.00 |
| Google Standard | **$0.004** | $0.40 | $4.00 |

### 3.2 이미지 생성

#### 서비스 비교

| 서비스 | 가격/장 | 해상도 | 텍스트 렌더링 | 스타일 제어 | API 접근성 |
|--------|--------|-------|-------------|-----------|-----------|
| **DALL-E 3** (OpenAI) | $0.04 (표준) / $0.08 (HD) | 1024x1024~1792x1024 | ★★★★★ | ★★★ | ★★★★★ REST API |
| **GPT Image 1** (OpenAI) | 토큰 기반 | 다양 | ★★★★★ | ★★★★ | ★★★★★ |
| **Stable Diffusion** (API) | **$0.002~$0.01** | 다양 | ★★ | ★★★★★ | ★★★★ |
| **Stable Diffusion** (셀프호스팅) | GPU 비용만 | 다양 | ★★ | ★★★★★ | 직접 운영 |
| **Midjourney** API | 구독 기반 (~$0.05) | 1024+ | ★★ | ★★★★★ | ★★★ 제한적 |

#### 타로 이미지 생성 유스케이스

1. **리딩 시각화**: 뽑힌 카드 조합을 하나의 아트워크로 생성 → 리딩 기록 썸네일
2. **개인화 카드 아트**: 사용자의 질문/맥락을 반영한 커스텀 카드 이미지
3. **리포트 삽화**: 구조화 리포트에 삽입할 분위기 이미지

**추천**: 초기에는 이미지 생성을 포함하지 않음. 텍스트 해석이 핵심 가치이며, 이미지는 비용 대비 사용자 만족도 검증 후 도입. 도입 시 DALL-E 3(품질) 또는 Stable Diffusion API(비용)를 A/B 테스트.

### 3.3 영상 생성

#### 서비스 비교

| 서비스 | 가격/초 | 5초 영상 비용 | 품질 | API 상태 |
|--------|--------|-------------|------|---------|
| **Runway Gen-4.5** | $0.12/초 | $0.60 | ★★★★★ | ✅ API 제공 |
| **Runway Gen-4 Turbo** | $0.05/초 | $0.25 | ★★★★ | ✅ API 제공 |
| **Runway Gen-4 Aleph** | $0.15/초 | $0.75 | ★★★★★ | ✅ API 제공 |
| **Veo 3.1** (Google, Runway 경유) | $0.20~$0.40/초 | $1.00~$2.00 | ★★★★★ | ✅ Runway API |
| **Pika** (720p) | — | **$0.20** | ★★★ | 제3자 API |
| **Pika** (1080p) | — | $0.45 | ★★★★ | 제3자 API |

#### 타로 영상 유스케이스

- 카드 공개 애니메이션 (뒤집히면서 나타나는 효과)
- 해석 분위기 영상 (카드 상징에 맞는 추상적 모션 그래픽)
- 일일 카드 스토리 (SNS 공유용 15초 영상)

**추천**: 영상은 MVP에 포함하지 않음. 비용이 텍스트 대비 100배 이상이며, 생성 시간도 길다(수초~수분). 프리미엄 티어의 "특별 리딩" 기능으로 후속 검토. Runway Gen-4 Turbo($0.05/초)가 비용 면에서 가장 현실적.

### 3.4 구조화 리포트

**기술 옵션:**

| 방식 | 기술 | 장점 | 단점 |
|------|------|------|------|
| **PDF 생성** | Flutter `pdf` 패키지 + 서버 렌더링 | 공유 용이, 인쇄 가능 | 디자인 제약 |
| **이미지 리포트** | Flutter `RepaintBoundary` → PNG/JPG | SNS 공유 최적, 디자인 자유도 | 텍스트 검색 불가 |
| **HTML → PDF** | Rails `wicked_pdf` / `grover` | 서버 사이드 렌더링, 복잡한 레이아웃 | 서버 부하 |
| **인앱 렌더링** | Flutter 위젯 → 스크린샷 | 추가 서버 비용 없음 | 기기 성능 의존 |

**추천**: Flutter `RepaintBoundary`로 인앱 이미지 리포트 생성 → 추가 서버 비용 없이 즉시 구현 가능. 고급 PDF 리포트는 서버 사이드 렌더링으로 후속 개발.

---

## 4. 맥락 지속성

### 4.1 Conversation Memory 패턴

#### 3가지 메모리 전략 비교

| 패턴 | 방식 | 토큰 소비 | 정확도 | 구현 복잡도 |
|------|------|---------|-------|-----------|
| **Sliding Window** | 최근 N턴만 유지 | 예측 가능 | 최근 맥락 높음, 오래된 맥락 유실 | ★ 낮음 |
| **Hierarchical Summary** | 오래된 대화를 요약하여 압축 | 일정 유지 | 중간 (요약 시 디테일 손실) | ★★★ 중간 |
| **Hybrid (Window + Summary + RAG)** | 최근 N턴 + 이전 요약 + RAG 검색 | 유동적 | 높음 | ★★★★ 높음 |

#### 타로 해석 대화에 최적: Hybrid 패턴

```
┌─ 현재 세션 ─────────────────────────┐
│ 최근 5턴 원문 (Sliding Window)       │ ~2,000 토큰
├─────────────────────────────────────┤
│ 이전 대화 요약 (Hierarchical)        │ ~500 토큰
├─────────────────────────────────────┤
│ 관련 과거 리딩 (RAG 검색)            │ ~500 토큰
└─────────────────────────────────────┘
총 맥락: ~3,000 토큰 (Layer 5)
```

**구현 전략:**
1. **세션 내**: 최근 5턴은 원문 유지. 5턴 초과 시 가장 오래된 턴부터 Haiku 4.5로 요약 ($0.001 미만)
2. **세션 간**: 세션 종료 시 전체 대화를 1~2문장 요약 + 핵심 인사이트 태그 추출 → DB 저장
3. **과거 참조**: 유사 질문/카드 조합의 과거 리딩을 RAG로 검색하여 "지난번에도 비슷한 질문을 하셨는데..." 형태로 연결

### 4.2 RAG 패턴

#### 타로 해석 RAG 아키텍처

```
                    ┌─────────────┐
유저 질문 ──────→  │ 임베딩 생성   │ ─────→ 벡터 검색
                    └─────────────┘         │
                                            ▼
┌──────────────────────────────────────────────────────┐
│                  벡터 DB (pgvector)                    │
│                                                        │
│  과거 리딩:                                            │
│  - 질문 텍스트 임베딩                                   │
│  - 뽑힌 카드 조합                                      │
│  - AI 해석 요약                                        │
│  - 사용자 메모/반응                                     │
│                                                        │
│  세션 요약:                                             │
│  - 대화 요약 임베딩                                     │
│  - 핵심 인사이트 태그                                   │
│  - 감정 상태 추적                                      │
└──────────────────────────────────────────────────────┘
         │
         ▼ 유사도 Top-3 리딩
     프롬프트에 주입
```

**기술 스택:**
- **벡터 DB**: PostgreSQL + `pgvector` 확장 → 기존 Rails + PostgreSQL 스택에 자연스럽게 통합
- **임베딩 모델**: OpenAI `text-embedding-3-small` ($0.02/MTok) 또는 로컬 임베딩 (Sentence Transformers)
- **검색 전략**: 질문 텍스트 유사도 + 카드 ID 매칭 + 시간 가중치 (최근 리딩 우선)

**pgvector 선택 근거:**
- 기존 PostgreSQL 인프라 활용 (별도 벡터 DB 운영 불필요)
- 소규모~중규모(수십만 건) 리딩 히스토리에 충분한 성능
- Rails `neighbor` gem으로 간편 통합

### 4.3 기존 Reading 엔티티 활용

현재 `Reading` 엔티티가 AI 맥락의 핵심 입력 데이터:

```
Reading (기존)                    AI 맥락 (변환)
──────────────                   ─────────────
deckId          ──→  덱 특성 (RWS/마르세유 등) 로드
spreadType      ──→  스프레드 포지션별 의미 매핑
question        ──→  해석 포커스 설정
drawnCards[]    ──→  각 카드의 meanings + 정/역위치 해석
  ├ cardId      ──→  TarotCard 엔티티에서 name, arcana, suit 조회
  ├ position    ──→  스프레드 내 위치 의미
  └ isReversed  ──→  upright/reversed meanings 분기
notes           ──→  사용자 맥락 추가 정보
createdAt       ──→  시간 순서 정렬, 과거 리딩 검색
```

**확장 제안** (후속 구현 시):

```dart
// Reading 엔티티에 AI 관련 필드 추가 (개념적)
class Reading {
  // ... 기존 필드 ...
  String? aiInterpretation;      // AI 해석 텍스트 저장
  String? aiSummary;             // 해석 1~2줄 요약 (RAG용)
  List<String>? insightTags;     // 핵심 인사이트 태그
  String? userFeedback;          // 사용자 피드백 (해석 품질 개선용)
  double? satisfactionScore;     // 만족도 점수 (1~5)
}
```

---

## 5. 비용 모델링

### 5.1 1회 리딩 해석 비용 추정

#### 시나리오: 3카드 스프레드, 2~3턴 대화

**Input 토큰 구성:**

| 구성 요소 | 토큰 수 | 캐시 여부 |
|----------|---------|---------|
| 시스템 프롬프트 (페르소나 + 사조) | 800 | ✅ 캐시 히트 |
| 카드 레퍼런스 데이터 (78장) | 3,000 | ✅ 캐시 히트 |
| 유저 프로필 | 500 | ✗ |
| 현재 리딩 데이터 (3카드) | 300 | ✗ |
| 대화 히스토리 (2~3턴) | 2,000 | ✗ |
| **캐시 히트 토큰** | **3,800** | **비용 90% 절감** |
| **일반 입력 토큰** | **2,800** | **정가** |
| **총 Input** | **6,600** | — |

**Output 토큰**: ~1,500 (해석 텍스트, 평균 3턴)

#### 모델별 1회 리딩 비용

| 모델 | 캐시 Input | 일반 Input | Output | **총 비용** |
|------|-----------|-----------|--------|-----------|
| **Claude Sonnet 4.6** | $0.00114 | $0.00840 | $0.02250 | **$0.032** |
| Claude Sonnet 4.6 (캐시 없이) | — | $0.01980 | $0.02250 | $0.042 |
| **Claude Haiku 4.5** | $0.00038 | $0.00280 | $0.00750 | **$0.011** |
| **GPT-4.1** | $0.00190 | $0.00560 | $0.01200 | **$0.020** |
| **GPT-4.1 mini** | $0.00038 | $0.00056 | $0.00120 | **$0.002** |
| **GPT-4.1 nano** | $0.00010 | $0.00028 | $0.00060 | **$0.001** |

> **핵심 발견**: 1회 리딩 비용은 $0.001(GPT-4.1 nano) ~ $0.032(Claude Sonnet 4.6) 범위. Claude Sonnet 4.6 기준으로도 **1회 약 3.2원(₩)** 수준으로 매우 저렴.

### 5.2 월간 사용자당 비용

#### 사용 시나리오별 추정

**가정:**
- 경량 사용자: 월 4회 리딩 × 3턴 대화
- 일반 사용자: 월 8회 리딩 × 5턴 대화
- 헤비 사용자: 월 20회 리딩 × 8턴 대화

| 사용 패턴 | Claude Sonnet 4.6 | GPT-4.1 | GPT-4.1 mini | Haiku 4.5 |
|----------|-------------------|---------|-------------|-----------|
| 경량 (4회/월) | $0.13 | $0.08 | $0.01 | $0.04 |
| 일반 (8회/월) | $0.38 | $0.24 | $0.02 | $0.13 |
| 헤비 (20회/월) | $1.20 | $0.75 | $0.08 | $0.40 |

> **인사이트**: Claude Sonnet 4.6으로 헤비 사용자를 서빙해도 월 $1.20 — 월 구독 $5~$10 기준으로 텍스트 해석만으로는 **매우 높은 마진**을 확보할 수 있다.

### 5.3 멀티모달 추가 비용

#### 1회 리딩 + 멀티모달 확장 비용 (Claude Sonnet 4.6 기준)

| 기능 | 추가 비용 | 텍스트 대비 배율 | 비고 |
|------|---------|--------------|------|
| 텍스트 해석만 | $0.032 | 1x (기준) | — |
| + TTS (OpenAI tts-1-hd, 1,000자) | +$0.030 | +0.9x | 총 $0.062 |
| + TTS (ElevenLabs, 1,000자) | +$0.300 | +9.4x | 총 $0.332 |
| + 이미지 1장 (DALL-E 3 표준) | +$0.040 | +1.3x | 총 $0.072 |
| + 이미지 1장 (Stable Diffusion) | +$0.005 | +0.2x | 총 $0.037 |
| + 5초 영상 (Runway Gen-4 Turbo) | +$0.250 | +7.8x | 총 $0.282 |
| **풀 멀티모달** (텍스트+TTS+이미지+영상) | +$0.325 | +10.2x | **총 $0.357** |

#### 월간 멀티모달 비용 (일반 사용자 8회/월)

| 구성 | 월 비용 | 연 비용 |
|------|--------|--------|
| 텍스트만 | $0.38 | $4.56 |
| 텍스트 + TTS (OpenAI) | $0.62 | $7.44 |
| 텍스트 + TTS + 이미지 (DALL-E 3) | $0.94 | $11.28 |
| 풀 멀티모달 | $2.86 | $34.32 |

---

## Key Findings (우선순위 순)

### 1. 텍스트 해석 비용이 상업적으로 매우 유리 (확신도: 높음)
1회 리딩 $0.001~$0.032로, 월 구독 $5~$10 대비 COGS가 1~5%에 불과. 프롬프트 캐싱으로 추가 90% 절감 가능. **비용은 구현 장벽이 아니다.**

### 2. Claude Sonnet 4.6이 타로 해석 1차 추천 (확신도: 높음)
뉘앙스 있는 한국어, 90% 캐시 절감, 1M 컨텍스트. GPT-4.1이 47% 저렴하나, 텍스트 비용 자체가 워낙 낮아 품질 우선이 합리적. LLM Provider 추상화로 모델 교체 유연성 확보.

### 3. 프롬프트 5레이어 아키텍처 + 캐싱이 핵심 설계 (확신도: 높음)
고정 레이어(페르소나, 카드 데이터)를 캐시하고, 동적 레이어(유저 맥락, 리딩 데이터, 대화)만 매 요청 전송. 기존 `Reading`, `TarotCard`, `UserSettings` 엔티티가 이미 필요한 데이터 구조를 제공하므로 추가 모델링 부담이 적다.

### 4. Flutter SSE 스트리밍은 모바일에서 안정적 (확신도: 높음)
`flutter_client_sse` 등 검증된 패키지 존재. Rails 8+ ActionController::Live로 SSE 프록시 구현 가능. 웹 플랫폼은 제약이 있으나, 모바일 우선 전략에서 영향 없음.

### 5. 맥락 지속성은 Hybrid 패턴 + pgvector (확신도: 중간)
Sliding Window + Hierarchical Summary + RAG 결합. pgvector로 기존 PostgreSQL에 벡터 검색 추가. 구현 복잡도가 중간 수준이므로 MVP에서는 Sliding Window만 적용하고, 이후 RAG를 단계적 추가하는 전략이 현실적.

### 6. 멀티모달은 단계적 확장 필수 (확신도: 높음)
텍스트($0.03) → TTS($0.03 추가) → 이미지($0.04 추가) → 영상($0.25 추가)으로 비용이 급증. MVP는 텍스트 채팅 + 이미지 리포트(인앱 렌더링, 추가 비용 $0)로 시작. TTS는 OpenAI tts-1-hd($0.03/회)가 비용/품질 균형.

### 7. ReflectivePrompts 연계가 차별화 기회 (확신도: 중간)
기존 확증 편향 완화 설계(Arkes, 1991)를 AI 해석에 통합하면, 경쟁 서비스 대부분이 놓치고 있는 "바넘 효과 방어 + 자기 성찰 유도" 차별화가 가능하다.

---

## References

### LLM API 가격 & 모델
- [Anthropic Claude API Pricing (공식)](https://platform.claude.com/docs/en/about-claude/pricing)
- [Claude API Pricing 2026 — MetaCTO](https://www.metacto.com/blogs/anthropic-api-pricing-a-full-breakdown-of-costs-and-integration)
- [Claude Models Overview](https://platform.claude.com/docs/en/about-claude/models/overview)
- [OpenAI API Pricing (공식)](https://developers.openai.com/api/docs/pricing)
- [OpenAI API Pricing 2026 — PricePerToken](https://pricepertoken.com/pricing-page/provider/openai)
- [GPT-4.1 API Pricing 2026](https://pricepertoken.com/pricing-page/model/openai-gpt-4.1)
- [AI API Pricing Comparison 2026 — IntuitionLabs](https://intuitionlabs.ai/articles/ai-api-pricing-comparison-grok-gemini-openai-claude)

### TTS 서비스
- [ElevenLabs API Pricing](https://elevenlabs.io/pricing/api)
- [ElevenLabs Korean TTS](https://elevenlabs.io/text-to-speech/korean)
- [ElevenLabs Models Documentation](https://elevenlabs.io/docs/overview/models)
- [OpenAI TTS API Pricing Calculator](https://costgoat.com/pricing/openai-tts)
- [OpenAI Text to Speech Guide](https://developers.openai.com/api/docs/guides/text-to-speech)
- [Google Cloud TTS Pricing](https://cloud.google.com/text-to-speech/pricing)
- [Google Cloud TTS Supported Voices](https://docs.cloud.google.com/text-to-speech/docs/list-voices-and-types)
- [Best TTS APIs 2026 — Speechmatics](https://www.speechmatics.com/company/articles-and-news/best-tts-apis-in-2025-top-12-text-to-speech-services-for-developers)

### 이미지 & 영상 생성
- [DALL-E vs Stable Diffusion 2026 — ToolPilot](https://www.toolpilot.dev/compare/dall-e-vs-stable-diffusion/)
- [Best AI Image Generation APIs 2026 — CrazyRouter](https://crazyrouter.com/en/blog/best-ai-image-generation-apis-2026)
- [AI Image Pricing 2026 — IntuitionLabs](https://intuitionlabs.ai/articles/ai-image-generation-pricing-google-openai)
- [Runway API Pricing](https://docs.dev.runwayml.com/guides/pricing/)
- [Complete Guide to AI Image APIs 2026 — WaveSpeedAI](https://wavespeed.ai/blog/posts/complete-guide-ai-image-apis-2026/)

### RAG & 메모리 패턴
- [Design Patterns for Long-Term Memory in LLM Architectures — Serokell](https://serokell.io/blog/design-patterns-for-long-term-memory-in-llm-powered-architectures)
- [How Does LLM Memory Work? — Sara Zan (2026)](https://www.zansara.dev/posts/2026-02-04-how-does-llm-memory-work/)
- [Powering Long-Term Memory with LangGraph & MongoDB](https://www.mongodb.com/company/blog/product-release-announcements/powering-long-term-memory-for-agents-langgraph)
- [From RAG to Context — 2025 Year-End Review — RAGFlow](https://ragflow.io/blog/rag-review-2025-from-rag-to-context)
- [Advanced RAG Techniques — Neo4j](https://neo4j.com/blog/genai/advanced-rag-techniques/)

### Flutter & 스트리밍
- [Flutter AI Toolkit](https://docs.flutter.dev/ai/ai-toolkit)
- [Flutter SSE Packages — Flutter Gems](https://fluttergems.dev/server-sent-events/)
- [flutter_client_sse — pub.dev](https://pub.dev/packages/flutter_client_sse)
- [dio_sse_client — GitHub](https://github.com/CitaSpace/dio_sse_client)

### 타로 AI 프롬프트
- [ChatGPT Tarot Card Reader Prompt — PromptsNinja](https://promptsninja.com/chatgpt-tarot-card-reader/)
- [AI-assisted Tarot Reading GPT Prompt — PromptBase](https://promptbase.com/prompt/ai-assisted-tarot-reading)
- [Tarot Card Interpreter AI Prompt — DocsBot](https://docsbot.ai/prompts/creative/tarot-card-interpreter)

### 코드베이스 참조
- `mobile/lib/features/reading/domain/entities/reading.dart` — Reading, DrawnCardInfo 엔티티
- `mobile/lib/features/deck/domain/entities/tarot_card.dart` — TarotCard 엔티티
- `mobile/lib/features/deck/domain/entities/card_meanings.dart` — CardMeanings 엔티티
- `mobile/lib/features/reading/domain/entities/reflective_prompts.dart` — ReflectivePrompts (확증 편향 완화)
- `mobile/lib/features/settings/domain/entities/user_settings.dart` — UserSettings (experienceLevel 등)

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 0s | 0 |
| 2 | user-ai-exchange | 12s | 26042 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 38s |
| Total Tokens | 26042 |
| Input Tokens | 3 |
| Output Tokens | 267 |
| Cache Read | 0 |
| Cache Creation | 25772 |
