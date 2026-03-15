---
id: "007"
title: "타로 도메인 에이전트 필요성 검증"
category: agent
status: archived
created: 2026-03-15
summary: >
  타로 도메인 지식의 에이전트 분리 vs 참조 문서화 비교, 시장 검증, MBTI/애니어그램 에이전트와의 관계 분석.
  결론: 타로 전문 에이전트 신설을 권장하되, "행동 규칙 > 역할 선언" 원칙에 따라 도메인 지식은
  외부 참조 문서로, 에이전트에는 해석/생성/검증 행동 규칙만 내장하는 하이브리드 방식을 제안한다.
keywords: [agent-report, tarot-domain, agent-separation, domain-knowledge, market-analysis]
modules: [domain-design]
---

# 타로 도메인 에이전트 필요성 검증

## Progress
### Completed
- [x] 내부 에이전트 설계 원칙 분석 (도메인 지식 배치 방식)
- [x] 타로 도메인 지식 구조 및 범위 조사
- [x] MBTI/애니어그램 에이전트와의 관계 분석
- [x] 타로 시장 규모 및 트렌드 조사
- [x] 에이전트 분리 vs 문서화 비교 분석 및 권장안
### Remaining
- (없음)
### Current Status
조사 완료. 최종 권장안 도출됨.

---

## Summary

타로 도메인은 기존 MBTI/애니어그램 에이전트와 비교했을 때 **구조적으로 더 복잡하고, 생성적 활용 범위가 넓으며, 프로젝트의 핵심 차별화 기능(커스텀 셔플, 커스텀 덱, 소셜 바운티)과 직결**되는 도메인이다. 시장 측면에서도 글로벌 타로 카드 시장이 연 8.5% CAGR로 성장 중이며, 디지털 타로 앱 다운로드가 2년간 72% 증가하는 등 투자를 정당화하는 규모를 갖추고 있다.

기존 에이전트 설계 원칙("행동 규칙 > 역할 선언", 도메인 지식 외부 배치)을 준수하되, **별도 에이전트 신설**이 필요하다. 그 근거는 다음 세 가지이다:

1. **도메인 복잡도**: 78장 카드 체계(메이저/마이너 아르카나), 원소 대응, 수비학, 스프레드 위치별 의미, 정/역방향 해석, 셔플 의식 등이 얽힌 다층 구조
2. **생성적 판단 필요**: 카드 조합별 맥락 해석, 스프레드 설계, 커스텀 덱 검증, 해석 품질 평가 등은 정적 참조 문서로 처리할 수 없음
3. **교차 도메인 협업**: 성격 유형(MBTI/애니어그램) + 타로 해석 결합이 프로젝트의 핵심 차별점이며, 이를 위해 독립적 전문성이 필요

---

## Details

### 1. 내부 에이전트 설계 원칙 분석

#### 1-1. 기존 에이전트의 도메인 지식 배치 패턴

`.claude/agents/mbti-expert.md`와 `.claude/agents/enneagram-expert.md`를 분석한 결과, 기존 에이전트들은 다음 패턴을 따른다:

| 구성 요소 | 에이전트 내부 배치 | 외부 참조 |
|----------|------------------|----------|
| 핵심 원칙 (Core Principles) | 5개 이내 행동 원칙 | - |
| SOP (행동 루프) | Observe-Think-Act-Share 4단계 | - |
| 도메인 지식 상세 | - | `docs/05_agent_design/004_Agent_도메인지식.md` |
| 레드라인 (금지 사항) | 에이전트 파일에 명시 | - |
| 협업 규칙 | 에이전트 파일에 명시 | - |
| 기억 시스템 | `.claude/agent-memory/{agent}/` | - |

**핵심 관찰**: MBTI 에이전트와 애니어그램 에이전트 모두 **도메인 지식의 본체(유형 체계, 이론, 학파 비교 등)는 외부 문서에 배치**하고, 에이전트 파일에는 **행동 규칙, 판단 기준, 소통 스타일, 금지 사항**만 내장한다.

#### 1-2. docs/05_agent_design/004_Agent_도메인지식.md의 원칙

이 문서는 5개 에이전트의 도메인 지식을 체계적으로 정리하면서 다음 설계 원칙을 제시한다:

1. **계층적 내장**: "반드시 기억해야 할 원칙(5개 이내)" + "참조 가능한 상세 지식" + "절대 위반 금지 사항(3개 이내)"
2. **공통 기반 분리**: 프로젝트 철학, 법적 경계, DB 스키마는 공통 참조로 분리
3. **차별화 축 집중**: 각 에이전트는 고유한 판단 축(학술적 근거, 문화적 맥락, 성장 가능성, 구현 가능성, 사용자 경험)에 집중

#### 1-3. 타로 도메인에 적용 시 패턴

동일 원칙을 타로에 적용하면:
- **에이전트 내부**: 해석 규칙, 스프레드 설계 원칙, 커스텀 덱 검증 규칙, 셔플 의식 매핑 원칙
- **외부 참조**: 78장 카드 의미 DB, 원소/수비학 대응표, 스프레드 포지션 정의, RWS 상징 체계

---

### 2. 타로 도메인 지식 구조 및 범위

외부 조사 결과를 종합하면 타로 도메인은 다음 6개 하위 영역으로 구성된다:

#### 2-1. 카드 체계 (78장 구조)

**메이저 아르카나 (22장)**: 0번 The Fool ~ 21번 The World. 인생의 주요 사건, 영적 교훈, 원형적 주제를 표상한다. 융(Jung)의 집합적 무의식 원형과 직접 대응하며, 타로의 심장부이다.

**마이너 아르카나 (56장)**: 4개 수트(Wands, Cups, Swords, Pentacles) x 14장(Ace~10 + Page, Knight, Queen, King).
- Wands = 불(Fire): 에너지, 열정, 욕망
- Cups = 물(Water): 감정, 직관, 창의성
- Swords = 공기(Air): 지성, 소통, 지식
- Pentacles = 땅(Earth): 물질, 재정, 안정

**코트 카드 (16장)**: 4수트 x 4계급. MBTI 16유형과 1:1 대응 가능성이 연구되어 있음 (King/Knight = 외향, Queen/Page = 내향; King/Queen = 판단, Knight/Page = 인식).

#### 2-2. 해석 체계

- **정방향/역방향(Upright/Reversed)**: 같은 카드가 방향에 따라 다른 의미
- **위치별 의미**: 스프레드에서 카드가 놓인 위치가 해석 맥락 결정
- **카드 조합**: 인접 카드 간의 상호작용이 의미를 변형
- **도메인별 해석**: 사랑, 커리어, 건강, 영성 등 질문 맥락에 따라 같은 카드도 다르게 해석

#### 2-3. 스프레드 체계

| 스프레드 | 카드 수 | 용도 |
|---------|--------|------|
| 1장 드로우 | 1 | 일일 가이드, 빠른 인사이트 |
| 3장 스프레드 | 3 | 과거-현재-미래 (가장 대중적) |
| 켈틱 크로스 | 10 | 종합 분석 (서클/크로스 6장 + 스태프 4장) |

켈틱 크로스 10포지션: 현재 상황, 도전/장애, 과거 기반, 최근 과거, 가능한 미래, 가까운 미래, 자기 인식, 외부 영향, 희망/두려움, 최종 결과.

#### 2-4. 셔플 의식 체계

셔플은 "에너지의 악수(energetic handshake)"로, 의도 설정, 에너지 연결, 성스러운 공간 창출의 기능을 한다.

| 셔플 방식 | 특성 | PRD 매핑 |
|----------|------|---------|
| 리플 (Riffle) | 강한 에너지, 결단력, 빠른 전환 | 양쪽 엄지 스와이프 제스처 |
| 오버핸드 (Overhand) | 부드러움, 명상적, 가장 보편적 | 상하 스와이프/기기 흔들기 |
| 워시/메시 (Wash/Messy) | 직관 극대화, 무의식 접속, 완전한 무작위 | 흩뿌린 카드 드래그 |
| 파일 (Pile) | 체계적, 질서, 홀수 수트 덱에 적합 | (PRD 미포함, 확장 가능) |

#### 2-5. 상징 체계 (Rider-Waite-Smith)

RWS 덱(1909, A.E. Waite + Pamela Colman Smith)은 카발라, 점성술, 연금술, 기독교 신비주의의 상징을 다층적으로 내장한다. 100개 이상의 반복 상징이 카드 전체에 걸쳐 사용되며, 수비학(0~21의 번호 체계)과 원형 에너지가 결합된다.

**저작권 상태**: 원본 RWS 덱은 미국에서 1966년 퍼블릭 도메인 진입. 흑백 선화는 완전 퍼블릭 도메인. 채색 버전은 U.S. Games Systems가 권리 주장 중이나 법적으로 논쟁적. 기본 타로 구조(78장, 수트, 아르카나)는 자유롭게 사용 가능.

#### 2-6. 오라클 덱 vs 타로 덱

| 비교 축 | 타로 | 오라클 |
|---------|------|--------|
| 카드 수 | 고정 78장 | 자유 (20~100+장) |
| 구조 | 메이저/마이너 아르카나, 4수트 | 규칙 없음, 테마 기반 |
| 해석 체계 | 표준화된 의미 체계 존재 | 창작자가 정의 |
| 학습 곡선 | 높음 (체계 학습 필요) | 낮음 (직관적) |

PRD의 커스텀 덱 시스템은 타로와 오라클 모두를 수용하는 `is_standard_tarot` 플래그를 사용한다.

---

### 3. MBTI/애니어그램 에이전트와의 관계 분석

#### 3-1. 도메인 특성 비교

| 비교 축 | MBTI | 애니어그램 | 타로 |
|---------|------|----------|------|
| **분류 기반** | 행동/선호 | 동기/두려움 | 상징/원형 |
| **체계 구조** | 4축 x 2 = 16유형 | 9유형 + 날개 + 본능 | 78장 + 스프레드 + 해석 맥락 |
| **결과 형태** | 고정 유형 라벨 | 동적 성장 방향 | 맥락 의존적 내러티브 |
| **학문적 지위** | 비학술적, 대중적 | 비학술적, 심리치료 활용 | 비학술적, 자기성찰 도구 |
| **저작권 상황** | 상표/저작권 강력 보호 | 기본 구조 퍼블릭 도메인 | RWS 기본 구조 퍼블릭 도메인 |
| **생성적 활용** | 유형 설명, 문항 설계 | 성장 가이드, 동기 탐색 | 해석 내러티브, 스프레드 설계, 덱 검증 |
| **데이터 복잡도** | 16유형 x 4도메인 | 9유형 x 2날개 x 3본능 x 9건강수준 | 78장 x 정/역 x 스프레드위치 x 도메인맥락 |

#### 3-2. 관계 유형: 보완적 독립

타로 에이전트는 MBTI/애니어그램 에이전트와 **보완적이되 독립적인** 관계이다:

**보완 관계의 근거**:
- 타로 코트 카드 16장 <-> MBTI 16유형의 구조적 대응 (Wands=직관, Cups=감정, Swords=사고, Pentacles=감각)
- 메이저 아르카나의 원형적 여정 <-> 애니어그램의 성장/퇴행 방향
- "왜 이 카드가 나왔는가"의 해석에 성격 유형 맥락 활용 가능
- 프로젝트 철학("자기 이해, 타인 수용, 자유 추구")에서 성격 유형과 타로가 모두 자기이해 도구

**독립성의 근거**:
- 타로의 해석 체계는 성격 유형론과 근본적으로 다른 인식론적 기반 (상징/직관 vs 분류/측정)
- 타로는 "예측/가이드" 성격이 강하고, 성격 유형은 "분류/이해" 성격이 강함
- 기술 구현 영역이 완전히 다름 (물리 엔진, 센서 API, 카드 렌더링 vs 문항 엔진, 점수 계산)
- 별도의 저작권/윤리 맥락 (유사과학 오인 리스크 관리 필요)

**통합 에이전트("divination-expert") 불가 판단**: MBTI/애니어그램과 타로를 하나로 통합하면 에이전트의 전문성이 희석된다. 특히 docs/08_비전스코핑/003_Agent_학술차별화전략.md에서 경고한 "타로/사주 같은 운명 서비스와의 인접성이 심리학 콘텐츠의 학술 신뢰성을 오염시킬 위험"을 고려하면, 오히려 의도적 분리가 필요하다.

---

### 4. 타로 시장 규모 및 트렌드

#### 4-1. 글로벌 시장

| 지표 | 수치 | 출처 |
|------|------|------|
| 글로벌 타로 카드 시장 (2026) | USD 7.1억 | Business Research Insights |
| 2035 전망 | USD 14.1억 | Business Research Insights (CAGR 8.5%) |
| 글로벌 점성/타로 앱 시장 (2026) | USD 161억 | Econ Market Research |
| 앱 시장 2035 전망 | USD 271억 | Econ Market Research (CAGR 6%) |
| 디지털 타로 앱 다운로드 증가율 | 72% (2년간) | 산업 리포트 |
| 월간 활성 사용자 (상위 플랫폼) | 1.2억+ | 산업 리포트 |

#### 4-2. 인구통계

- Gen Z (13-25세) 51%가 타로/운세 경험 있음
- 이 중 17% 매일, 25% 주 1회, 27% 월 1회 이용
- Gen Z + 밀레니얼 61%가 타로를 자기성찰/마음챙김 도구로 사용
- 여성이 타로 카드 애호가의 다수 구성
- TikTok 타로 해시태그 조회수 5억~60억 회

#### 4-3. 한국 시장 특수성

- **점신 앱**: 누적 다운로드 1,700만건 돌파
- **포스텔러**: 가입자 750만명
- 타로 관련 민간자격증 발급기관: 475곳 (2024년 105곳 신규, 전년 대비 50% 증가)
- MZ세대 42.9%가 "성향/성격 파악"을 위해 운세를 봄
- 점집/철학관 → AI 기반 모바일 운세 서비스로 전환 트렌드

#### 4-4. 핵심 트렌드

1. **세속화 (Secularization)**: 영적 믿음이 아닌 자기성찰/마음챙김 도구로의 전환
2. **디지털화**: 40%+ 사용자가 디지털/앱 기반 타로 이용
3. **AI 통합**: AI 기반 개인화 해석, 챗봇 상담, 자동 태깅
4. **커스터마이제이션**: 테마별/개인화 덱 수요 급증, Print-on-Demand 시장 성장
5. **소셜화**: Instagram/TikTok 기반 타로 리딩 공유 문화
6. **아시아 태평양 주도**: 시장 성장의 54%가 APAC 지역

---

### 5. 에이전트 분리 vs 문서화 비교 분석

#### 5-1. 판단 기준 평가

| 판단 기준 | 참조 문서 | 별도 에이전트 | 평가 |
|----------|----------|-------------|------|
| **도메인 지식 복잡도** | 정적 DB로 충분한 경우 | 다층 구조, 맥락 의존적 해석 | **에이전트 우세**: 78장 x 정/역 x 스프레드위치 x 도메인맥락의 조합 폭발 |
| **생성적 활용 필요성** | 조회/참조만 필요한 경우 | 해석 생성, 스프레드 설계, 덱 검증 | **에이전트 우세**: 카드 조합 해석은 규칙 기반 생성 필요 |
| **업데이트 빈도** | 드물게 변경 | 자주 확장/수정 | **동등**: 기본 체계는 안정적이나, 커스텀 덱 지원으로 확장 필요 |
| **교차 에이전트 협업** | 단방향 참조 | 양방향 협업 | **에이전트 우세**: psychology-expert(윤리 검증), uiux-expert(UX 설계)와 밀접 협업 |
| **PRD 커버리지** | 기본 기능만 | 핵심 차별화 기능 | **에이전트 우세**: 커스텀 셔플, 커스텀 덱, 소셜 바운티 모두 타로 도메인 판단 필요 |
| **윤리/리스크 관리** | 일반 가이드라인 | 도메인 특화 리스크 관리 | **에이전트 우세**: 유사과학 오인, 의존성 조장, 불안 유발 리스크 |

#### 5-2. MBTI/애니어그램 선례 비교

| 비교 항목 | MBTI 에이전트 | 애니어그램 에이전트 | 타로 에이전트 (예상) |
|----------|-------------|-----------------|-------------------|
| 외부 참조 지식량 | 16유형 + 인지기능 + 한국 트렌드 | 9유형 + 날개 + 본능 + 건강수준 | 78장 카드 + 스프레드 + 상징 체계 |
| 에이전트 내 행동 규칙 | 저작권 안전, 문화 적합성, 스펙트럼 표현 | 성장 방향 강조, 학파 비교, 동기 탐색 | 해석 규칙, 셔플 의식 매핑, 덱 검증, 윤리 경계 |
| 생성 작업 | 문항 설계, 유형 설명 작성 | 성장 가이드, 동기 탐색 문항 | 카드 해석, 스프레드 설계, 커스텀 덱 스키마 검증 |
| 금지 사항 | 공식 MBTI 문항 복제, 유형 우열 | 병리적 서술, 결정론적 서술 | 예측 확신, 의존성 조장, 심리학 영역 침범 |

타로의 도메인 복잡도(78장 x 다중 맥락)는 MBTI(16유형)나 애니어그램(9유형)보다 명백히 크다. 그러나 기존 에이전트들이 도메인 지식 본체를 외부에 두고도 효과적으로 작동하는 선례를 따르면, 타로 에이전트도 동일 패턴으로 설계 가능하다.

#### 5-3. 최종 판단: 별도 에이전트 신설 (하이브리드 방식)

**결론**: 타로 전문 에이전트(`tarot-expert`)를 신설한다.

**근거**:
1. PRD의 핵심 차별화 기능 3개(커스텀 셔플, 커스텀 덱, 소셜 바운티)가 모두 타로 도메인 전문 판단을 요구
2. 카드 해석은 맥락 의존적 생성 작업이므로 정적 참조 문서로 불가
3. 성격 유형 에이전트와의 교차 협업(타로 코트 카드 + MBTI, 원형 여정 + 애니어그램 성장)에 독립적 전문성 필요
4. 유사과학 오인 리스크를 관리하기 위해 심리학 에이전트와의 명시적 역할 분리 필요
5. 시장 규모(글로벌 앱 시장 $161억+, 한국 1700만+ 다운로드)가 별도 에이전트 투자를 정당화

---

## Key Findings

1. **타로 도메인 복잡도는 MBTI/애니어그램보다 크다.** 78장 카드 x 정/역방향 x 스프레드 위치 x 해석 맥락(사랑/커리어/건강/영성)의 조합은 수천 가지에 달하며, 이는 MBTI 16유형이나 애니어그램 27 하위유형(9유형 x 3본능)을 상회한다.

2. **기존 에이전트 설계 원칙은 타로에도 적용 가능하다.** MBTI/애니어그램 에이전트가 "도메인 지식 본체는 외부, 행동 규칙은 내부"로 분리한 선례를 따르면, 타로 카드 의미 DB, 스프레드 정의, 상징 대응표는 외부 참조 문서(`docs/` 또는 `shared/`)에, 해석/검증/설계 규칙만 에이전트에 내장하는 구조가 적절하다.

3. **타로-MBTI 통합은 프로젝트의 핵심 차별점이다.** 타로 코트 카드 16장과 MBTI 16유형의 구조적 대응, 메이저 아르카나 원형 여정과 애니어그램 성장 방향의 연결은 경쟁 서비스에서 찾기 어려운 독특한 가치 제안이 될 수 있다. 그러나 이 통합은 의도적이고 전문적이어야 하며, "divination-expert"로 합치면 오히려 품질이 떨어진다.

4. **유사과학 오인 리스크는 의도적 분리로 관리해야 한다.** docs/08_비전스코핑/003_Agent_학술차별화전략.md가 경고한 대로, 타로와 심리학 콘텐츠가 같은 에이전트에서 나오면 학술 신뢰성이 오염된다. 별도 에이전트로 분리하고, psychology-expert가 교차 검증하는 구조가 필요하다.

5. **한국 MZ세대의 타로 소비는 "자기이해 도구"로 수렴하고 있다.** 점신 1700만 다운로드, 포스텔러 750만 가입, 타로 자격증 기관 475곳 등의 데이터는 한국 시장에서 타로가 단순한 유흥이 아닌 자기탐색 도구로 자리잡고 있음을 보여준다. 이는 프로젝트 철학("자기 이해, 타인 수용, 자유 추구")과 정확히 부합한다.

6. **커스텀 덱/오라클 체계는 표준 타로를 넘어선 도메인 확장을 요구한다.** PRD의 커스텀 덱 시스템은 비표준 카드 수, 수트 없는 구조, 사용자 정의 의미를 모두 수용해야 하므로, 에이전트는 "표준 타로 체계의 전문가"이면서 동시에 "비표준 체계의 검증자" 역할도 수행해야 한다.

7. **RWS 타로 기본 구조는 퍼블릭 도메인이다.** 78장 구조, 수트, 아르카나 체계, 원본 흑백 선화는 자유롭게 사용 가능하다. 이는 MBTI의 강력한 상표/저작권 보호와 대비되며, 타로 도메인에서는 저작권 리스크가 상대적으로 낮다.

---

## Recommendations

### 권장안 1: `tarot-expert` 에이전트 신설

**에이전트 프로필**:
```
name: tarot-expert
description: 타로 해석·스프레드 설계·커스텀 덱 검증 전문가. 전통 체계 이해 + 현대 세속적 활용 + 디지털 경험 설계.
model: sonnet
tools: [Read, Glob, Grep, Edit, Write]
```

### 권장안 2: 도메인 지식 외부 배치 구조

| 외부 참조 문서 | 내용 |
|-------------|------|
| `docs/tarot/card-meanings.yaml` | 78장 카드별 정방향/역방향 의미, 키워드, 원소 대응 |
| `docs/tarot/spreads.yaml` | 스프레드 정의 (포지션별 의미, 카드 수, 용도) |
| `docs/tarot/symbolism.md` | RWS 상징 체계, 수비학, 원소 대응표 |
| `docs/tarot/custom-deck-schema.json` | 커스텀 덱 JSON 스키마 + 검증 규칙 |
| `docs/tarot/shuffle-rituals.md` | 셔플 방식별 의식적 의미 + 디지털 매핑 |

### 권장안 3: 에이전트 행동 규칙 (Core Principles)

기존 에이전트의 "행동 규칙 > 역할 선언" 원칙에 따라, 타로 에이전트의 핵심 행동 규칙을 구체적으로 제시한다:

1. **해석은 내러티브이지 예측이 아니다.** "~할 것이다"가 아닌 "~를 성찰해보라"로 표현한다. 타로는 자기성찰 도구이며, 운명 예측 도구가 아니다.
2. **카드 조합의 맥락을 항상 우선한다.** 개별 카드 의미보다 스프레드 전체의 내러티브 흐름을 중시한다. 위치 의미 + 인접 카드 관계 + 질문 맥락의 삼각 교차 해석을 수행한다.
3. **전통 체계와 현대 해석을 구분하여 제시한다.** RWS 전통 의미를 기본으로 하되, 현대 세속적 해석(심리적 자기성찰)을 병행 제시한다. 어느 쪽이 "정답"인지 강제하지 않는다.
4. **커스텀 덱은 창작자의 의도를 존중한다.** 비표준 구조(카드 수, 수트 유무, 역방향 유무)를 허용하며, 창작자가 정의한 의미 체계를 우선한다. 단, JSON 스키마 무결성은 반드시 검증한다.
5. **심리학 영역을 침범하지 않는다.** 타로 해석에서 "당신은 우울증 경향이 있다"와 같은 진단적 표현을 절대 사용하지 않는다. 심리적 건강 관련 해석이 필요하면 psychology-expert에 위임한다.

### 권장안 4: 에이전트 SOP (Observe-Think-Act-Share)

**Observe**: 스프레드 정의, 카드 배치, 질문 맥락, 사용자 페르소나(전통적 리더/세속적 사용자/하이브리드/소셜) 확인
**Think**: (1) 개별 카드 의미 → (2) 위치별 맥락 → (3) 카드 간 관계 → (4) 전체 내러티브 → (5) 사용자 맥락 반영
**Act**: 해석 내러티브 생성, 스프레드 설계, 커스텀 덱 스키마 검증, 셔플 의식 매핑
**Share**: 해석의 confidence 수준 명시, 심리학 검증 필요 플래그, 성격 유형 교차 인사이트 제안

### 권장안 5: 레드라인 (금지 사항)

1. **운명 예측 확언 금지**: "당신에게 ~이 일어날 것이다"와 같은 확정적 예측 표현
2. **의존성 조장 금지**: "중요한 결정 전에 반드시 타로를 봐야 한다"와 같은 의존 유도
3. **심리 진단 금지**: 타로 해석을 심리적 진단이나 치료 대안으로 제시
4. **특정 타로 도구의 보호된 콘텐츠 복제 금지**: 상업적 타로 앱/서적의 독창적 해석 문구 복제

### 권장안 6: 협업 관계 정의

| 협업 대상 | 관계 | 구체적 상호작용 |
|----------|------|---------------|
| psychology-expert | 윤리 검증자 | 타로 해석의 바넘 효과 점검, 의존성 리스크 검토, "자기성찰 도구" 프레이밍 검증 |
| mbti-expert | 교차 인사이트 | 코트 카드-MBTI 유형 대응 설계, 성격 유형별 맞춤 해석 톤 조정 |
| enneagram-expert | 성장 내러티브 | 메이저 아르카나 여정-성장 방향 연결, 동기 기반 해석 심화 |
| coding-expert | 구현 협업 | 카드 데이터 모델, JSON 스키마 구현, 셔플 알고리즘 요구사항 전달 |
| uiux-expert | UX 설계 협업 | 셔플 제스처-의식적 의미 매핑, 리딩 뷰어 정보 공개 방식, 다크 모드 디자인 방향 |
| mobile-expert (신규) | 기술 구현 | 물리 엔진 요구사항, 센서 API 활용 방식, 카드 렌더링 상태 관리 |

---

## References

### 프로젝트 내부 문서
- `.claude/agents/mbti-expert.md` — MBTI 에이전트 도메인 지식 배치 방식 분석
- `.claude/agents/enneagram-expert.md` — 애니어그램 에이전트 도메인 지식 배치 방식 분석
- `docs/05_agent_design/004_Agent_도메인지식.md` — 도메인 지식 외부 배치 원칙
- `docs/003_gemini_deep_research.md` — 타로 모바일 앱 PRD
- `docs/01_성격서비스_기획/004_Memo_프로젝트_철학.md` — 프로젝트 철학 (타로 확장 언급)
- `docs/08_비전스코핑/003_Agent_학술차별화전략.md` — 유사과학 오인 리스크
- `docs/10_agent_upgrade/001_Scope_에이전트구성업그레이드.md` — 에이전트 업그레이드 스코프

### 외부 조사 소스

**타로 도메인 구조**:
- [Major Arcana vs Minor Arcana: Complete Guide to Tarot Structure](https://freetarotcardreadings.com/blog/major-vs-minor-arcana/)
- [Rider-Waite-Smith Tarot: Revolutionary Symbolism (1909)](https://mysticryst.com/blogs/the-mystic-journal/rider-waite-smith-tarot-revolutionary-symbolism-1909)
- [Rider-Waite Tarot - Wikipedia](https://en.wikipedia.org/wiki/Rider%E2%80%93Waite_Tarot)

**스프레드 체계**:
- [The Celtic Cross Tarot Spread - Labyrinthos](https://labyrinthos.co/blogs/learn-tarot-with-labyrinthos-academy/the-celtic-cross-tarot-spread-exploring-the-classic-10-card-tarot-spread)
- [How to Read The Celtic Cross Tarot Spread - Biddy Tarot](https://biddytarot.com/blog/how-to-read-the-celtic-cross-tarot-spread/)

**셔플 의식**:
- [How to Shuffle Tarot Cards: 7 Powerful Methods Revealed](https://explaintarot.com/how-to-shuffle-tarot-cards/)
- [Using Ritual to Centre & Empower Your Tarot Readings](https://tarotelements.com/using-ritual-to-centre-and-empower-your-tarot-readings/)

**시장 분석**:
- [Tarot Cards Market Size, Share & Growth By 2035 - Business Research Insights](https://www.businessresearchinsights.com/market-reports/tarot-cards-market-122379)
- [Global Astrology App Market to Triple in Value - Yahoo Finance](https://finance.yahoo.com/news/global-astrology-app-market-triple-103800115.html)
- [Tarot Trend Updates 2025 - Accio](https://www.accio.com/business/tarot-trend-updates)

**세속적 타로/인구통계**:
- [Why Gen Z Is Turning to Tarot: Inside the Mystical Economy of Modern Ritual](https://www.curationedit.com/post/tarot-and-the-theatre-of-belief-how-gen-z-is-redesigning-ritual-for-the-social-era)
- [Tarot and Psychology: Jung's Archetypal Interpretation](https://mysticryst.com/blogs/the-mystic-journal/tarot-and-psychology-jungs-archetypal-interpretation)
- [The Mirror, Not the Crystal Ball: A Psychological Analysis of Tarot](https://www.researchgate.net/publication/392424835_The_Mirror_Not_the_Crystal_Ball_A_Psychological_Analysis_of_Tarot_as_a_Self-Reflection_Tool)
- [Study: Gen Z doubles down on spirituality - National Catholic Reporter](https://www.ncronline.org/news/study-gen-z-doubles-down-spirituality-combining-tarot-and-traditional-faith)

**오라클 vs 타로**:
- [Oracle Cards vs Tarot Cards: Important Differences](https://www.sherylwagnermedium.com/blog/difference-between-tarot-cards-and-oracle-cards)

**타로-MBTI 통합**:
- [MBTI Types and Corresponding Tarot Court Cards - Angelorum](https://angelorum.co/learn-tarot/the-tarot-court-cards-mbti-types/)
- [16 MBTI Personality types in Tarot Court cards - TarotX](https://tarotx.net/16-mbti-personality-court-cards/)

**저작권**:
- [The Rider-Waite-Smith Tarot Card Copyright FAQ](https://sacred-texts.com/tarot/faq.htm)
- [The Copyright Battle Over a Tarot Card Deck - Plagiarism Today](https://www.plagiarismtoday.com/2024/02/28/the-copyright-battle-over-a-tarot-card-deck/)

**타로 데이터 구조**:
- [tarot-api card_data.json - GitHub](https://github.com/ekelen/tarot-api/blob/main/static/card_data.json)
- [tarot_interpretations.json - dariusk/corpora](https://github.com/dariusk/corpora/blob/master/data/divination/tarot_interpretations.json)

**한국 시장**:
- [MZ세대, 점집 대신 AI 운세 서비스로 - EBN뉴스](https://www.ebn.co.kr/news/articleView.html?idxno=1700000)
- [너도나도 자격증?...타로·사주 배우는 MZ세대 실상 - 굿뉴스](https://www.goodnews1.com/news/articleView.html?idxno=452102)
