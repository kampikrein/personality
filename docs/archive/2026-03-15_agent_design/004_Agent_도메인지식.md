---
id: "004"
title: "도메인별 핵심 지식 체계"
category: agent
status: archived
created: 2026-03-11
summary: >
  5개 전문 에이전트의 도메인별 필수 지식 체계와 차별화 포인트 연구
keywords: [agent-report, 도메인지식, 심리학, MBTI, 애니어그램, Rails, UIUX, general-purpose]
modules: [.claude/agents]
---

# 도메인별 핵심 지식 체계

## Summary

5개 전문 에이전트(심리학, MBTI, 애니어그램, 코딩, UI/UX)가 프롬프트에 내장해야 할 핵심 도메인 지식을 체계적으로 정리하였다. 각 에이전트는 고유한 이론적 기반, 실무적 판단 기준, 프로젝트 특화 맥락을 갖추어야 하며, 5개 에이전트가 동일한 기능에 대해 서로 다른 축(학술적 근거, 문화적 맥락, 성장 모델, 구현 실용성, 사용자 경험)에서 의견을 제시할 수 있도록 차별화되어야 한다.

## Details

---

### 1. 심리학 전문가 에이전트 -- 필수 도메인 지식

#### 1-1. 성격심리학 주요 이론 체계

**Big Five (OCEAN) 모델 -- 핵심 프레임워크**:
- 5개 요인: Openness(개방성), Conscientiousness(성실성), Extraversion(외향성), Agreeableness(우호성), Neuroticism(신경증)
- 각 요인 아래 6개 하위 패싯(facet), 총 30개 세부 차원
- 연속 차원(continuous dimension) 기반 -- 이분법이 아닌 스펙트럼 모델
- 40개 이상 언어로 번역되어 30개 이상 문화권에서 동일한 5요인 구조 재현 (교차문화 보편성)
- NEO-PI-R의 내적 일관성: Cronbach alpha > 0.85, 장기 재검사 신뢰도 높음

**특성 이론(Trait Theory) 역사적 맥락**:
- Allport: 4,500개 특성 용어 분류, 중심 특성(central traits) 개념
- Cattell: 요인분석으로 16PF(16 Personality Factors) 도출
- Eysenck: 3요인 모델(외향성-신경증-정신증), 생물학적 기반 강조
- 현대적 합의: Big Five가 특성 이론의 주류로 자리잡음

**유형론(Typology) vs 특성론(Trait Theory) 비교 비판**:
- 유형론: 범주적(categorical) 분류, 직관적 이해 용이, 그러나 경계선 사례 처리 어려움
- 특성론: 연속적(dimensional) 측정, 통계적 정밀성 우수, 그러나 대중 소통 난이도 높음
- 현대 심리학 주류는 특성론을 지지하나, 대중적 활용에서는 유형론이 여전히 우세
- 이 프로젝트의 접근: 내부적으로 연속 벡터(0-100) 사용, 대외적으로는 유형 프레임으로 소통

#### 1-2. 심리측정학(Psychometrics) 기본 지식

**신뢰도(Reliability)**:
- 내적 일관성(Internal Consistency): Cronbach alpha -- 문항 간 상관관계 측정, 0.7 이상이 기준
- 재검사 신뢰도(Test-Retest Reliability): 시간 경과 후 동일 결과 재현성
- 반분 신뢰도(Split-half): 검사를 반으로 나눠 비교
- 프로젝트 적용: domain_scores의 reliability_coefficient, consistency_index 컬럼이 이를 반영

**타당도(Validity)**:
- 구성 타당도(Construct Validity): 검사가 측정하려는 구성 개념을 실제로 측정하는가
- 수렴 타당도(Convergent Validity): 유사 검사와의 상관 (높아야 함)
- 변별 타당도(Discriminant Validity): 비관련 검사와의 상관 (낮아야 함)
- 내용 타당도(Content Validity): 문항이 측정 영역을 대표하는가
- 안면 타당도(Face Validity): 응답자가 보기에 타당해 보이는가

**표준화와 규준(Standardization & Norms)**:
- 규준 집단(normative sample): 점수 해석의 기준 집단
- z-score, T-score 변환: 원점수를 의미 있는 비교 척도로 변환
- 한국 규준의 중요성: 문화적 응답 편향 보정 필요

#### 1-3. 성격 검사 도구 비교 지식

| 검사 도구 | 기반 모델 | 문항수 | 특징 | 프로젝트 관련성 |
|---|---|---|---|---|
| NEO-PI-R | Big Five | 240 | 30개 패싯, 교차문화 검증 최다, 금표준 | 가장 높음 -- 0-100 벡터 모델 참고 |
| HEXACO-PI-R | HEXACO (6요인) | 200 | Honesty-Humility 추가, Dark Triad 탐지 | 중간 -- 6번째 요인 참고 가능 |
| TCI | 기질과 성격 | 240 | Cloninger 모델, 기질 4차원 + 성격 3차원 | 낮음 -- 생물학적 기반 다름 |
| MMPI-2 | 임상 진단 | 567 | 임상 척도 중심, 성격이 아닌 정신병리 | 제외 -- 임상 도구는 서비스 범위 밖 |
| 16PF | Cattell 16요인 | 185 | 역사적 의미, 현재는 Big Five에 흡수 | 참고 수준 |

#### 1-4. 윤리적 고려사항 -- 반드시 내장해야 할 경고 체계

**바넘 효과(Barnum Effect / Forer Effect)**:
- 1948년 Forer 실험: 누구에게나 맞는 모호한 진술을 자기 것으로 받아들이는 현상
- 성격 검사 결과의 "놀라운 정확성"이 실제로는 바넘 효과일 수 있음
- 대응: 구체적이고 행동 지향적인 결과 문구 작성, 모호한 보편 진술 회피

**확증 편향(Confirmation Bias)**:
- 자신의 유형에 맞는 정보만 선택적으로 기억하는 현상
- 대응: 결과에 "이 설명이 맞지 않을 수도 있습니다" 문구 포함

**라벨링 위험(Labeling Risk)**:
- 유형 결과가 자기예언적 효과(self-fulfilling prophecy)를 유발
- "나는 내향적이니까 사교 모임에 안 가도 돼" 같은 행동 제한
- 대응: "성향"이라는 표현 사용, "고정된 정체성"이 아님을 명시

**자기예언적 효과(Self-Fulfilling Prophecy)**:
- 검사 결과가 실제 행동을 그 방향으로 변화시키는 현상
- 대응: 성장 가능성과 변화 가능성을 항상 함께 제시

#### 1-5. 핵심 차별점

> "항상 학문적 근거를 제시하고, 근거 없는 주장을 절대 하지 않는다."

- 모든 주장에 이론/연구 출처를 동반
- "~라는 연구 결과가 있다" vs "~이다"의 차이를 엄격히 구분
- 불확실한 영역에서는 "현재 학계에서 합의가 이루어지지 않았다"고 명시
- 대중적 오해를 교정하는 역할 (예: "MBTI는 과학적으로 검증되지 않았다"는 과장된 주장도 교정)
- APA 스타일 인용 습관

---

### 2. MBTI 전문가 에이전트 -- 필수 도메인 지식

#### 2-1. MBTI 이론 체계

**Jung의 심리 유형론 원형**:
- Carl Jung, "Psychological Types" (1921)
- 태도(Attitude): 외향(Extraversion) vs 내향(Introversion)
- 기능(Function): 감각(Sensing) vs 직관(iNtuition), 사고(Thinking) vs 감정(Feeling)
- 판단(Judging) vs 인식(Perceiving): Myers-Briggs가 추가한 4번째 축

**Isabel Myers & Katharine Briggs의 발전**:
- 제2차 세계대전 시기, 여성의 적성 직업 매칭 목적으로 개발 시작
- Jung의 이론을 93개+ 문항의 표준화된 검사 도구로 발전
- The Myers-Briggs Company(구 CPP, Inc.)가 1975년부터 독점 출판권 보유

**4가지 선호 지표와 16유형**:
- E-I (외향-내향): 에너지 방향
- S-N (감각-직관): 정보 수집 방식
- T-F (사고-감정): 의사결정 방식
- J-P (판단-인식): 생활 양식
- 조합으로 16유형 생성 (ENFP, ISTJ 등)

#### 2-2. 인지 기능(Cognitive Functions) 체계

**8가지 인지 기능**:
- Se(외향 감각), Si(내향 감각)
- Ne(외향 직관), Ni(내향 직관)
- Te(외향 사고), Ti(내향 사고)
- Fe(외향 감정), Fi(내향 감정)

**기능 스택 (Function Stack)**:
- 주기능(Dominant): 가장 자연스럽게 사용하는 기능
- 부기능(Auxiliary): 주기능을 보조
- 3차 기능(Tertiary): 미성숙 상태, 성장 과정에서 발달
- 열등기능(Inferior): 스트레스 시 부정적으로 발현

**예시**: ENFP의 기능 스택 = Ne(주) - Fi(부) - Te(3차) - Si(열등)

#### 2-3. 한국 MBTI 트렌드 (2024-2025)

**문화 현상 수준의 확산**:
- 구글 트렌드 기준 국가별 MBTI 검색량 한국이 2018년 이후 글로벌 1위
- MZ세대의 자기표현 도구: 프로필에 MBTI 표기, 소개팅에서 MBTI 교환
- 코로나19 이후 온라인 약식 검사 확산이 유행 가속화
- 밈/유머 문화: MBTI별 행동 패턴 밈, "T vs F" 대결 콘텐츠

**2024-2025 키워드 트렌드**:
- INFJ: "조용한 리더십", "심리적 안정" 키워드와 함께 주목
- INFP: 자유롭고 이상주의적 성격, Z세대 감성과 부합
- 감정 공감, 자기표현, 심리 안정이 디지털 콘텐츠 시장 강세 키워드

**마케팅 활용**:
- 카카오톡 "MBTI 기획전" (유형별 선물 추천)
- 유통업계 MBTI 마케팅 다수 사례
- 기업 채용/팀빌딩에서 MBTI 활용 (학술적으로는 논란 있음)

#### 2-4. MBTI 비판과 한계 -- 반드시 숙지

**학술적 비판**:
- 재검사 신뢰도 문제: 5주 후 재검사 시 39~76%가 다른 유형으로 변경
- Virginia 표본 유형 일치율 55%, 공공기관 표본 66%
- 유형 기반 재검사 신뢰도 0.5-0.6 (5주), 0.4 (9개월 이상)
- 학계 평가: "중국의 포춘 쿠키와 다름없다", "현존하는 최악의 성격 검사 중 하나" 등 극단적 비판 존재

**구조적 한계**:
- 이분법적 분류: 실제 성격 분포는 정규분포(종형 곡선)인데, 중앙에서 인위적으로 둘로 나눔
- 경계선 사례 문제: E 51% vs I 49%인 사람이 E 90%인 사람과 같은 유형으로 분류
- Forer 효과: 유형별 설명이 충분히 모호하여 누구에게나 맞게 느껴질 수 있음

**균형 잡힌 시각**:
- 한국 MBTI 연구소: "문항을 계속 바로잡아 높은 신뢰도와 타당도를 확보했다"고 주장
- 일부 심리학 교수: "신뢰도와 타당도를 보완했다면 비과학적인 검사라고 볼 수 없다"
- 대중적 유용성과 학술적 엄밀성은 다른 차원의 문제

#### 2-5. 저작권 및 법적 이슈

**상표 보호 (Trademark)**:
- "MBTI", "Myers-Briggs", "Myers-Briggs Type Indicator": USPTO 및 한국 등록 상표
- 항상 형용사로 사용 (예: "MBTI assessment"), 명사로 사용 금지
- 첫 등장 시 등록상표 기호(R) 표기 의무

**저작권 보호 (Copyright)**:
- 93개+ 문항: 고도로 설계된 독창적 표현물 -- 무단 복제 금지
- 결과 리포트: 전문가의 해석과 문학적 표현이 가미된 저작물
- 한국 대법원도 심리검사 문항의 저작물성 인정

**부정경쟁방지법 (한국 특수성)**:
- 부경법 제2조 제1호 파목: 타인의 상당한 투자/노력 성과의 무단 사용 금지
- MBTI의 수십 년간 축적된 데이터, 표준화 비용, 브랜드 인지도 = "상당한 투자"
- 공식 MBTI인 것처럼 오인하게 하는 행위는 금지

**프로젝트 우회 전략** (16Personalities 참고):
- MBTI 상표 직접 사용 불가 -- "성격 유형 탐색" 등 독자적 용어 사용
- 공식 문항 복제 불가 -- 독자적 문항 은행 개발 (현재 4도메인 x 5문항 = 20문항)
- Big Five 이론 기반 자체 문항 개발이 가장 안전한 접근
- SEO에서도 MBTI 키워드 사용 시 "혼동 야기 행위" 위험

#### 2-6. 한국 경쟁사 분석

| 서비스 | 유형 | 문항수 | 핵심 특징 |
|---|---|---|---|
| 16Personalities | 비공식, 글로벌 | 60 | NERIS Type Explorer, A/T 추가 축, 무료+프리미엄 |
| 어세스타(한국MBTI연구소) | 공식, 유료 | 93+ | 한국형 공식 MBTI, 전문가 자격 필요 |
| Truity TypeFinder | 비공식, 글로벌 | 130 | 23개 세부 요인, 기술문서 공개 |
| 테스트모아 | 비공식, 국내 | 48 | 무료, 광고 기반, 엔터테인먼트 성격 |
| 테스트하로 | 비공식, 국내 | 67 | 무료, 구식 UI, 학술 검증 없음 |
| 푸망 (나BTI) | 비공식, 국내 | 미정 | SNS 플랫폼, 5분 소요, 밈/트렌드 반영 |

#### 2-7. 핵심 차별점

> "한국 문화적 맥락에서의 MBTI 활용 전문성과 트렌드 감각"

- 한국 MZ세대의 MBTI 소비 패턴 이해
- 대중적 표현과 학술적 정확성 사이의 균형
- 저작권/법적 위험에 대한 실시간 경계
- 한국어 문항의 문화적 적합성 판단
- 경쟁사 대비 차별화 포인트 도출 능력

---

### 3. 애니어그램 전문가 에이전트 -- 필수 도메인 지식

#### 3-1. 애니어그램 9유형 체계

| 유형 | 핵심 동기 | 핵심 두려움 | 키워드 |
|---|---|---|---|
| 1 개혁가 | 올바름, 완벽 추구 | 부패, 결함 | 원칙, 정직, 자기 비판 |
| 2 조력가 | 사랑받기, 필요한 존재 | 사랑받지 못함 | 관계, 헌신, 자기희생 |
| 3 성취가 | 가치 인정, 성공 | 무가치함 | 효율, 이미지, 적응력 |
| 4 개성가 | 정체성, 의미 | 정체성 부재 | 감정 깊이, 창의성, 우울 |
| 5 탐구가 | 이해, 역량 | 무능함, 침범 | 분석, 독립, 지식 축적 |
| 6 충성가 | 안전, 지지 | 안전 부재, 버림받음 | 의심, 충성, 불안 |
| 7 열정가 | 자유, 만족 | 고통, 결핍 | 낙관, 계획, 회피 |
| 8 도전가 | 자기보호, 통제 | 취약함, 통제 상실 | 힘, 정의, 대립 |
| 9 평화가 | 내적 평화, 조화 | 갈등, 분리 | 수용, 게으름, 무관심 |

#### 3-2. 동적 시스템 -- 날개, 통합/분열

**날개(Wing) 시스템**:
- 각 유형은 인접한 두 유형 중 하나에 영향을 받음
- 예: 4유형은 4w3(성취 날개) 또는 4w5(탐구 날개)
- 날개는 핵심 유형의 "풍미"를 더하는 부차적 영향

**통합/분열 방향 (Integration/Disintegration)**:
- 성장(통합) 방향: 스트레스가 아닌 상태에서 이동하는 긍정적 방향
- 스트레스(분열) 방향: 압박 상태에서 이동하는 부정적 방향
- 예: 1유형 -- 성장 시 7번(유연함, 즐거움) 방향, 스트레스 시 4번(감정적, 우울) 방향
- 방향선: 1→7→5→8→2→4→1 (통합), 역방향 (분열) / 3→6→9→3 (삼각형)

#### 3-3. 본능 하위유형(Instinctual Variants)

**3가지 본능 하위유형**:
- 자기보존(Self-Preservation, SP): 물리적 안전, 건강, 재정, 환경 안정
- 사회적(Social, SO): 소속감, 집단 내 위치, 사회적 역할
- 일대일(Sexual/One-to-One, SX): 강렬한 일대일 관계, 매력, 화학적 끌림

**본능과 유형의 상호작용**:
- 9유형 x 3본능 = 27가지 하위유형
- 각 유형에 "반유형(countertype)"이 존재 (본능이 유형의 일반적 표현과 반대로 작용)
- 예: 사회적(SO) 6유형은 두려움을 극복하려 강해 보이려 함 -- 반유형

#### 3-4. 주요 학파 차이

**Riso-Hudson (The Enneagram Institute)**:
- 9단계 건강 수준 모델 (Level 1~9: 해방 → 자아 실현 → ... → 병리적)
- 본능 하위유형을 유형과 독립적으로 다룸
- 날개(wing)에 상대적으로 높은 비중
- 2유형을 "The Helper(조력가)"로 정의
- 체계적이고 구조화된 접근, 교육적 목적에 적합

**Claudio Naranjo**:
- 심리역동적(psychodynamic) 접근, 성격 장애와의 연결 강조
- 본능 하위유형이 핵심 유형의 표현을 근본적으로 변형시킨다고 봄
- 반유형(countertype)에 높은 비중 -- 모든 유형에서 반유형 존재 강조
- 2유형을 "The Seducer(유혹자)"로 정의 -- 타 학파와 크게 다름
- Oscar Ichazo로부터 직접 배운 후 심리학적 프로파일 정교화

**Helen Palmer (Narrative Tradition)**:
- 직관적/구전 전통 기반
- 각 유형의 내면 경험에 대한 자전적 서사를 강조
- 인터뷰 패널 방식으로 유형 탐구
- Arica Institute v. Palmer 판례에서 승소 -- 에니어그램 기본 구조가 공공 영역임을 확립

**Oscar Ichazo (Arica School)**:
- 에니어그램의 현대적 원류
- "에니어건(Enneagons)" 시스템 개발
- 영적/원형적 접근, 에니어그램을 "보편적 진리"로 선포
- 이 선포가 역설적으로 저작권 주장을 약화시킴 (금반언의 원칙)

#### 3-5. 건강 수준 모델 (Riso-Hudson)

| 수준 | 범위 | 상태 |
|---|---|---|
| Level 1-3 | 건강(Healthy) | 자기초월, 자아실현, 사회적 가치 |
| Level 4-6 | 보통(Average) | 자기 이미지 유지, 대인 갈등, 방어 기제 |
| Level 7-9 | 비건강(Unhealthy) | 심각한 대인 문제, 강박, 병리적 행동 |

각 유형의 성장 방향은 자신의 건강 수준을 높이는 것 + 통합 방향 유형의 긍정적 특질을 통합하는 것.

#### 3-6. 저작권 및 법적 이슈

**공유 도메인(Public Domain)인 것**:
- 에니어그램 심볼(9개 점 연결 도형)
- 9가지 유형의 기본 구조와 명칭
- 통합/분열 방향 체계
- Arica v. Palmer 판결 (미국 제2연방항소법원)에 의해 확립

**보호받는 것**:
- RHETI(Riso-Hudson Enneagram Type Indicator): 특정 검사 도구
- 각 학파의 독자적 교육 매뉴얼과 검사지
- 한국형 에니어그램 성격유형검사(KEPTI): 한국에니어그램교육연구소 저작권
- 특정 저자의 독창적인 서술, 해석, 메타포

**프로젝트 적용**:
- 9유형 구조 자체를 사용하는 것은 법적으로 안전
- 단, 특정 검사 도구(RHETI, KEPTI 등)의 문항 복제는 금지
- 독자적 문항, 독자적 해석 문구, 독자적 명명 체계 필요

#### 3-7. MBTI와의 핵심 차이

| 비교 축 | MBTI | 애니어그램 |
|---|---|---|
| 분류 기준 | 행동/선호 (무엇을 하는가) | 동기/두려움 (왜 하는가) |
| 변화 모델 | 유형 고정 (선호는 바뀌지 않는다) | 성장/퇴행 방향 포함 (변화 가능) |
| 구조 | 4축 x 2 = 16유형 | 9유형 + 날개 + 본능 + 건강 수준 |
| 학문적 지위 | 비학술적이나 대중적 | 비학술적이나 심리치료에서 활용 |
| 저작권 | 상표/저작권 강력 보호 | 기본 구조 공유 도메인 |

#### 3-8. 핵심 차별점

> "성장과 변화 가능성을 강조하는 동적 모델"

- 정적 분류가 아닌 동적 성장 경로 제시
- "당신은 X유형입니다" 대신 "당신의 성장 방향은 Y입니다"
- 동기(motivation) 기반 분석 -- 같은 행동도 다른 동기에서 비롯될 수 있음
- 건강 수준 개념을 통한 자기 점검 도구
- 통합/분열 방향을 통한 구체적 성장 가이드

---

### 4. 코딩 전문가 에이전트 -- 필수 도메인 지식

#### 4-1. Ruby on Rails 7+ 핵심 전문성

**Convention over Configuration (CoC)**:
- 파일 위치, 이름, 구조에 의한 자동 매핑
- 모델은 `app/models/`, 컨트롤러는 `app/controllers/`, 뷰는 `app/views/`
- 테이블명은 모델명의 복수형 (예: `User` → `users`)

**ActiveRecord 패턴**:
- ORM: Ruby 객체와 DB 테이블의 1:1 매핑
- 관계: `has_many`, `belongs_to`, `has_one`, `has_many :through`
- 콜백: `before_validation`, `after_create`, `before_save`
- 스코프: `scope :active, -> { where(deleted_at: nil) }`
- Encryption (Rails 7+): `encrypts :email, deterministic: true`

**MVC 아키텍처**:
- Model: 비즈니스 로직, 검증, 관계
- View: 사용자 인터페이스 렌더링
- Controller: HTTP 요청 처리, 모델과 뷰 연결

**RESTful API 설계**:
- 7가지 표준 액션: index, show, new, create, edit, update, destroy
- 리소스 라우팅: `resources :assessments`
- 네스팅: `resources :assessments { resources :responses }`

#### 4-2. 프로젝트 기술 스택 상세

| 기술 | 역할 | 핵심 사용처 |
|---|---|---|
| Ruby on Rails 8.1.2 | 풀스택 웹 프레임워크 | 전체 앱 |
| SQLite (개발) / PostgreSQL (프로덕션) | 데이터베이스 | 14개 테이블 |
| RSpec + FactoryBot | 테스트 프레임워크 | 모델/요청/시스템 테스트 |
| Hotwire (Turbo + Stimulus) | 프론트엔드 인터랙션 | SPA-like 경험, 페이지 부분 갱신 |
| Tailwind CSS | 유틸리티 CSS | UI 스타일링 |
| bcrypt | 비밀번호 해싱 | User.has_secure_password |
| ActiveRecord Encryption | 필드 암호화 | email, display_name |

#### 4-3. 성격 서비스 특화 기술 지식

**문항 엔진 (Question Engine)**:
- 버전 관리: `QuestionSet` (qset_v1, qset_v2) -- `activate!`로 단일 active 보장
- 도메인 기반: energy, decision_making, relationship, recovery
- 역채점: `polarity: 'negative'` 문항은 점수 반전 필요
- 문항 순서: `position` 컬럼으로 도메인 내 순서 관리

**점수 엔진 (Scoring Engine)**:
- 원점수(raw_score) → 정규화 점수(normalized_score, 0-100)
- 정규화 공식: `(raw - min) / (max - min) * 100`
- 신뢰도 보정: `reliability_coefficient`, `consistency_index`
- 이상 탐지: `speed_flag` (응답 속도 비정상), 극단응답률, 무응답률
- 정책 차단: `policy_blocked` (민감한 출력 차단)

**프로필 벡터 (Profile Vector)**:
- `score_vector` (JSON): `{ "energy": 72, "decision_making": 45, "relationship": 88, "recovery": 31 }`
- 벡터 → 유형 매핑: 도메인 점수 조합으로 16유형 결정
- 고정 유형 강제 없음 -- 벡터 자체가 1차 결과

**인사이트 생성**:
- 5가지 맥락: collaboration, conflict, learning, career, recovery
- 규칙 + 템플릿 기반 (MVP 단계)
- `explanation` + `suggestions` (JSON 배열)

#### 4-4. DB 스키마 핵심 데이터 흐름

```
AnonymousSession (세션 생성)
     │
     ▼
Assessment (검사 시작, status: in_progress)
     │
     ├── Response x N (문항별 응답 저장)
     │
     ▼ (제출: status → submitted)
DomainScore x 4 (도메인별 점수 계산)
     │
     ▼ (채점: status → scored)
Profile (유형 결정, score_vector 저장)
     │
     ├── Insight x 5 (맥락별 인사이트 생성)
     │
     ▼ (완료: status → completed)
```

#### 4-5. 테스트 전략

**TDD/RSpec 관행**:
- 모델 스펙: 검증, 관계, 스코프, 콜백 테스트
- 요청 스펙(Request Specs): API 엔드포인트 테스트
- 시스템 스펙(System Specs): Capybara 기반 E2E
- FactoryBot: 14개 팩토리 정의 (`spec/factories.rb`)
- `personality_type` 팩토리의 uniqueness 충돌 주의 (code: "ENFP" 하드코딩)

**테스트 우선순위**:
1. 점수 계산 로직 (정규화, 역채점, 신뢰도 보정)
2. 상태 전이 (Assessment: in_progress → submitted → scored → completed)
3. 정책 필터 (policy_blocked 동작)
4. 삭제 요청 SLA (7일 이내 처리)

#### 4-6. 핵심 차별점

> "실용적 코드 구현 + Rails 컨벤션 철저 준수 + 성격 서비스 도메인 이해"

- 성격 서비스의 비즈니스 로직을 이해한 상태에서 코드 작성
- "동작하는 코드"가 아닌 "Rails Way에 맞는 코드"
- 테스트를 동반하지 않는 코드는 미완성
- DB 레벨 제약 (유니크 인덱스, FK)과 모델 레벨 검증의 이중 보장
- 마이그레이션 히스토리를 이해하고 실수를 반복하지 않는 코딩

---

### 5. UI/UX 전문가 에이전트 -- 필수 도메인 지식

#### 5-1. UX 설계 원칙

**사용자 리서치 (User Research)**:
- 페르소나 정의: 한국 MZ세대, MBTI에 관심 있는 20-30대
- 사용자 여정 지도(User Journey Map): 검사 시작 → 응답 → 결과 확인 → 인사이트 탐색
- 핵심 니즈: "나를 알고 싶다", "재미있어야 한다", "빠르게 결과를 보고 싶다"

**정보 구조(Information Architecture)**:
- 성격 검사 플로우: 선형(linear) vs 비선형(non-linear)
- 결과 페이지 계층: 유형 요약 → 상세 도메인 점수 → 맥락별 인사이트
- 네비게이션: 최소한의 메뉴, 검사 중에는 불필요한 네비게이션 숨김

**인터랙션 디자인**:
- 마이크로인터랙션: 문항 전환 애니메이션, 응답 확인 피드백
- 로딩 상태: 점수 계산 중 의미 있는 대기 화면
- 에러 처리: 친절한 에러 메시지, 재시도 안내

#### 5-2. 성격 검사 UI 패턴

**문항 응답 UI**:
- 한 문항씩 표시 (Single Question Per Page) -- 집중도 향상
- 진행률 표시(Progress Bar): 전체 문항 대비 현재 위치
- 5단계 리커트 척도 UI: 슬라이더, 라디오 버튼, 이모지 기반 선택
- 스와이프 제스처 지원 (모바일)

**결과 시각화**:
- 레이더 차트(Radar Chart): 다차원 프로필 한눈에 비교
- 바 차트(Bar Chart): 도메인별 점수 직관적 표시
- 프로필 카드 디자인: SNS 공유용 시각적 요약
- 색상 코딩: 각 도메인/유형에 일관된 색상 체계

**결과 페이지 패턴**:
- 히어로 영역: 유형명 + 캐릭터 이미지 + 한 줄 요약
- 상세 섹션: 강점, 주의 패턴, 권장 행동
- 인사이트 탭: 협업, 갈등, 학습, 커리어, 회복
- CTA: "결과 저장하기", "다시 검사하기", "친구에게 공유하기"

#### 5-3. 한국 시장 UX 트렌드

**디자인 언어 참고**:
- 카카오: 둥근 모서리, 따뜻한 색상, 캐릭터 중심 감정 표현
- 네이버: 깔끔한 카드 UI, 정보 밀도 높음, 한국어 타이포그래피
- 토스: 미니멀, 대비 강한 CTA, 숫자 중심 정보 제시

**모바일 퍼스트**:
- 한국 스마트폰 보급률 97% -- 모바일이 1차 경험
- 터치 타겟 최소 44px
- 세로 스크롤 기반 레이아웃

**한글 타이포그래피**:
- 본문: Pretendard, Noto Sans KR (가독성 우선)
- 타이틀: 다양한 웹폰트 활용 가능하나 로딩 성능 고려
- 자간/행간: 한글 특성에 맞는 조정 (영문 대비 넓은 행간)

**감정적 디자인(Emotional Design)**:
- 성격 검사는 감정적 경험 -- 결과가 "나"에 대한 이야기
- 긍정적 프레이밍: 약점보다 강점 먼저 표시
- 부드러운 톤: 판단하지 않는 표현, 격려하는 문구
- 성장 지향: "고정된 유형"이 아닌 "탐색과 발전의 출발점"

#### 5-4. 접근성 (Accessibility)

**WCAG 2.1 가이드라인**:
- 색상 대비 비율: 텍스트 4.5:1 이상 (AA), 대형 텍스트 3:1
- 스크린리더 호환: 의미 있는 alt 텍스트, ARIA 라벨
- 키보드 네비게이션: 모든 인터랙션 키보드로 가능해야 함
- 포커스 표시: 현재 포커스된 요소 시각적으로 명확히 표시

**특별 고려사항**:
- 리커트 척도 접근성: 라디오 버튼 그룹 + 명확한 라벨
- 차트 접근성: 시각적 차트 + 텍스트 대안 제공
- 색맹 대응: 색상만으로 정보를 전달하지 않기 (패턴/아이콘 병용)

#### 5-5. 프론트엔드 기술 스택

**Hotwire/Turbo (Rails 연동)**:
- Turbo Drive: 페이지 전환 시 전체 리로드 없이 body만 교체
- Turbo Frames: 페이지의 특정 영역만 갱신 (문항 전환에 적합)
- Turbo Streams: 서버에서 실시간 DOM 업데이트 (결과 계산 후 표시)

**Stimulus**:
- HTML 기반 JavaScript 프레임워크
- 데이터 속성으로 컨트롤러 연결
- 리커트 척도 인터랙션, 진행률 표시, 애니메이션 제어

**Tailwind CSS**:
- 유틸리티 클래스 기반 스타일링
- 반응형: `sm:`, `md:`, `lg:` 접두사
- 커스텀 색상 팔레트: 프로젝트 브랜드 색상 정의
- 다크 모드: `dark:` 변형 지원

#### 5-6. 핵심 차별점

> "사용자 감정 흐름 설계 + 한국 시장 최적화 + 성격 검사 특화 UI"

- 성격 검사라는 특수한 사용자 여정의 감정 곡선 이해
- 검사 시작(기대) → 응답 중(집중/피로) → 결과 확인(흥분/기대) → 인사이트(성찰)
- 한국 MZ세대의 디자인 기대치 충족 (카카오/토스 수준)
- 공유 가능한 시각적 결과물 설계
- Hotwire + Tailwind 기술 스택 내에서의 최적 구현

---

## 차별화 매트릭스: 5개 에이전트 비교

### 관점 축별 차별화

| 비교 축 | 심리학 전문가 | MBTI 전문가 | 애니어그램 전문가 | 코딩 전문가 | UI/UX 전문가 |
|---|---|---|---|---|---|
| **1차 판단 기준** | 학술적 근거 | 문화적 적합성 | 성장 가능성 | 구현 가능성 | 사용자 경험 |
| **참조 프레임** | 논문/연구 | 한국 트렌드/법률 | 학파별 이론 | Rails 컨벤션 | 디자인 패턴 |
| **위험 감지 초점** | 바넘효과, 라벨링 | 저작권 침해 | 유형 고착화 | 기술 부채 | 사용성 문제 |
| **품질 기준** | 타당도/신뢰도 | 대중적 공감 + 정확성 | 체계적 깊이 | 테스트 커버리지 | 접근성/반응성 |
| **소통 스타일** | 학술적, 인용 동반 | 대중적, 트렌드 인지 | 체계적, 성장 지향 | 기술적, 실용적 | 시각적, 감정 중심 |
| **"안 된다"고 말하는 상황** | 근거 없는 주장 시 | 상표/저작권 위반 시 | 유형 결정론 시 | 컨벤션 위반 시 | UX 해치는 기능 시 |

### MVP 구성요소별 기여도

| MVP 구성요소 | 심리학 | MBTI | 애니어그램 | 코딩 | UI/UX |
|---|---|---|---|---|---|
| **문항 엔진** | 문항 설계 원칙, 심리측정학 | 4축 기반 문항 방향 | 동기 기반 문항 설계 | QuestionSet/Question 구현 | 문항 응답 UI |
| **점수 엔진** | 정규화, 신뢰도 보정 이론 | 유형 분류 로직 자문 | 날개/본능 점수 체계 | DomainScore 계산 구현 | 로딩/계산 중 UI |
| **프로필 컴포저** | 결과 해석 윤리 가이드 | 유형별 설명 작성 | 성장 방향 설명 작성 | Profile/PersonalityType 구현 | 프로필 카드 디자인 |
| **인사이트 모듈** | 근거 기반 조언 검수 | 한국 맥락 인사이트 | 맥락별 성장 가이드 | Insight 모듈 구현 | 인사이트 탭 UI |
| **신뢰/컴플라이언스** | 윤리 가이드라인 | 저작권 컴플라이언스 | 공공 도메인 확인 | Consent/DeletionRequest 구현 | 고지 UI, 접근성 |

### 에이전트 간 잠재적 관점 충돌과 해소

| 충돌 시나리오 | 관련 에이전트 | 해소 원칙 |
|---|---|---|
| "이 문항이 학술적으로 부적절" vs "대중적으로 공감됨" | 심리학 vs MBTI | 학술적 최소 기준 충족 후 대중적 표현 허용 |
| "유형을 명확히 보여줘야" vs "스펙트럼으로 보여줘야" | MBTI vs 심리학 | 내부는 벡터, 대외는 유형 + 스펙트럼 병행 |
| "이 기능을 추가해야" vs "구현 복잡도가 높다" | UI/UX vs 코딩 | MVP 범위 내 우선순위로 판단 |
| "고정 유형 표시" vs "성장 방향 강조" | MBTI vs 애니어그램 | 프로젝트 철학(자기 이해, 자유 추구)에 부합하는 방향 |
| "더 많은 정보 표시" vs "깔끔한 UI" | 심리학/애니어그램 vs UI/UX | 정보 계층화 (요약 → 상세 펼치기) |

---

## Key Findings

1. **심리학 전문가의 핵심 가치는 "근거 없으면 말하지 않는다"이다.** Big Five 모델의 교차문화 검증 데이터(30개+ 문화권), NEO-PI-R의 alpha > 0.85 등 구체적 수치를 에이전트가 참조할 수 있어야 한다. 바넘 효과, 확증 편향, 라벨링 위험에 대한 경고 체계는 결과 문구 작성의 윤리적 안전장치로 기능한다.

2. **MBTI 전문가는 한국 시장 특수성과 법적 위험의 교차점에 있다.** 한국은 글로벌 MBTI 검색량 1위 국가이며 MZ세대 문화와 깊이 결합되어 있다. 동시에 상표권, 저작권, 부정경쟁방지법 3중 법적 리스크가 존재한다. 이 에이전트는 "대중적 매력"과 "법적 안전성"의 균형점을 찾는 데 특화되어야 한다.

3. **애니어그램 전문가의 차별적 가치는 "변화 가능성"이다.** MBTI가 정적 분류를 제공하는 반면, 애니어그램은 통합/분열 방향, 건강 수준, 본능 하위유형이라는 동적 요소를 갖추고 있다. 프로젝트 철학("자기 이해, 자유 추구")과 가장 직접적으로 정렬되는 체계이다. 학파별 차이(특히 Riso-Hudson vs Naranjo의 하위유형 해석 차이)를 인지해야 한다.

4. **코딩 전문가는 단순 Rails 개발자가 아니라 "성격 서비스 도메인을 이해하는 개발자"여야 한다.** 점수 정규화, 역채점, 신뢰도 보정, 정책 차단 같은 도메인 특화 로직을 이해한 상태에서 코딩해야 한다. 14개 테이블의 관계와 데이터 흐름(AnonymousSession → Assessment → Response → DomainScore → Profile → Insight)을 완전히 숙지해야 한다.

5. **UI/UX 전문가는 "감정 흐름 설계자"여야 한다.** 성격 검사는 단순 정보 입출력이 아니라 사용자의 자기 탐색이라는 감정적 여정이다. 기대(검사 시작) → 집중과 피로(응답 중) → 흥분(결과 확인) → 성찰(인사이트)이라는 감정 곡선을 UI로 지원해야 한다.

6. **5개 에이전트의 차별화는 "같은 기능을 다른 축에서 보는 것"이다.** 예를 들어 "문항 엔진"에 대해 심리학 전문가는 측정학적 타당성을, MBTI 전문가는 4축 커버리지를, 애니어그램 전문가는 동기 탐색 깊이를, 코딩 전문가는 버전 관리와 DB 설계를, UI/UX 전문가는 응답 경험의 흐름을 각각 평가한다.

---

## Recommendations

1. **에이전트 프롬프트에 도메인 지식을 계층적으로 내장하라.** 모든 지식을 나열하는 것이 아니라, "반드시 기억해야 할 원칙" (5개 이내), "참조할 수 있는 상세 지식" (필요 시 활성화), "절대 위반하면 안 되는 금지 사항" (3개 이내)으로 계층화한다.

2. **공통 기반 지식을 별도로 분리하라.** 프로젝트 철학, 법적 경계 원칙, DB 스키마 개요, MVP 구성요소는 5개 에이전트 모두에게 공통으로 필요하다. 이를 CLAUDE.md 또는 공통 참조 파일로 관리하고, 에이전트별 프롬프트는 차별화된 전문 지식에 집중한다.

3. **에이전트 간 관점 충돌 해소 규칙을 미리 정의하라.** 위의 "잠재적 관점 충돌과 해소" 테이블을 각 에이전트 프롬프트에 포함하여, 다른 에이전트의 관점과 충돌할 때 어떻게 행동할지 지침을 제공한다.

4. **법적 경계 원칙은 모든 에이전트에 최고 우선순위로 내장하라.** 어떤 도메인 판단보다 법적 안전성이 우선한다. 특히 MBTI 전문가와 애니어그램 전문가에게는 "절대 해서는 안 되는 것" 목록(상표 사용, 문항 복제, 공식 검사 사칭)을 명시적으로 포함한다.

5. **심리학 전문가를 "최종 윤리 검수자" 역할로 설정하라.** 문항 텍스트, 결과 문구, 인사이트 제안이 바넘 효과에 빠지지 않는지, 라벨링 위험이 없는지, 확증 편향을 조장하지 않는지를 심리학 전문가가 검수하는 워크플로우를 구성한다.

---

## References

### 프로젝트 내부 문서
- `/Users/kampikrein/A/personality/docs/01_성격서비스_기획/005_Plan_법률우선_MVP_설계.md`
- `/Users/kampikrein/A/personality/docs/01_성격서비스_기획/004_Memo_프로젝트_철학.md`
- `/Users/kampikrein/A/personality/docs/01_성격서비스_기획/002_Research_저작권_법적보호_조사.md`
- `/Users/kampikrein/A/personality/docs/01_성격서비스_기획/001_Research_MBTI_서비스_비교.md`
- `/Users/kampikrein/A/personality/docs/04_codebase_분석/004_Agent_데이터모델_스키마.md`
- `/Users/kampikrein/A/personality/docs/05_agent_design/001_Research_전문에이전트_구성.md`

### 외부 참고 자료
- [한국인이 MBTI를 좋아하는 이유 - DIGITAL iNSIGHT](https://ditoday.com/%ED%95%9C%EA%B5%AD%EC%9D%B8%EC%9D%B4-mbti%EB%A5%BC-%EC%A2%8B%EC%95%84%ED%95%98%EB%8A%94-%EC%9D%B4%EC%9C%A0/)
- [MBTI 트렌드 분석 - 트렌드모니터](https://www.trendmonitor.co.kr/tmweb/trend/allTrend/detail.do?bIdx=2101&code=0401&trendType=CKOREA)
- [MBTI는 유사과학일 뿐일까: 신뢰도와 타당도의 문제](https://brunch.co.kr/@kuy06154/4)
- [팩트체크넷 - MBTI 검사는 신뢰할 수 있는가?](https://factchecker.or.kr/fc_trainings/364)
- [Enneagram of Personality - Wikipedia](https://en.wikipedia.org/wiki/Enneagram_of_Personality)
- [No One Can Agree What Enneagram Subtypes Are - Truity](https://www.truity.com/blog/no-one-can-agree-what-enneagram-subtypes-are-heres-why)
- [Why We Need Claudio Naranjo - The Enneagram in Business](https://theenneagraminbusiness.com/trends/why-we-need-claudio-naranjo-helen-palmer-don-riso-and-others-more-than-ever/)
- [Big Five personality traits - Wikipedia](https://en.wikipedia.org/wiki/Big_Five_personality_traits)
- [Using the Big Five Personality Traits in Practice - Positive Psychology](https://positivepsychology.com/big-five-personality-theory/)
- [The NEO-PI-R: Assessing the Big Five - Psychology Town](https://psychology.town/psychodiagnostics/neo-pi-r-big-five-personality-traits/)
- [Big Five vs. HEXACO: In-depth Comparison](https://high5test.com/big-five-vs-hexaco/)
- [HEXACO model of personality structure - Wikipedia](https://en.wikipedia.org/wiki/HEXACO_model_of_personality_structure)
- [Top UI UX Design Best Practices for 2026 - UIDesignz](https://uidesignz.com/blogs/ui-ux-design-best-practices)
- [UI/UX Design in 2025: Principles, Process & Trends](https://dev.to/vrajparikh/uiux-design-in-2025-principles-process-trends-5dl5)
- [Arica Institute v. Palmer - Justia](https://law.justia.com/cases/federal/appellate-courts/F2/970/1067/269899/)
- [MBTI Guide to Permissions and Trademarks](https://www.myersbriggs.org/using-type-as-a-professional/mbti-permission-trademarks/)

