---
id: "002"
title: "MBTI 전문가 비평 — 문화적 적합성·독자성·법적 안전성 분석"
category: agent
status: archived
created: 2026-03-13
summary: >
  전반적으로 법적 안전성 기반은 양호하나, 도메인명 일부가 MBTI 공식 축과 일치하고, 캐릭터명 품질이 불균일하며, 한국 MZ세대 공감도와 콘텐츠 깊이 면에서 경쟁사 대비 뚜렷한 차별화가 부족하다. 문항 20개는 법적으로 안전하나 심리측정 포맷 차별화가 미흡하다.
keywords: [agent-report, mbti, cultural-fit, originality, legal-safety, korean-trend]
modules: [seeds, profiles, compliance]
---

# MBTI 전문가 비평 — 문화적 적합성·독자성·법적 안전성 분석

## Progress
### Completed
- [x] 법적 안전성 점검 (문항/표현 유사성, 컴플라이언스 필터)
- [x] 16유형 캐릭터명·설명 독자성 분석
- [x] 문항 20개 한국어 자연스러움·문화 적합성
- [x] 16유형 콘텐츠 품질·차별화 분석
- [x] 경쟁사 대비 차별점 평가
- [x] 도메인명·코드 체계 독자성 평가
### Remaining
- (없음)
### Current Status
분석 완료. 최종 보고서 작성됨.

---

## Summary

전반적으로 법적 기반(RestrictedTerms + TrustNotice)은 잘 설계되어 있으며, 공식 MBTI 문항과의 직접적 중복 위험은 낮다. 그러나 도메인명(energy/decision_making/relationship/recovery)이 MBTI 공식 4축(E-I/N-S/F-T/J-P)과 1:1 대응하여 독자성 주장이 취약하고, 16유형 캐릭터명의 품질이 불균일하며, 콘텐츠 텍스트가 한국 MZ세대보다 직장인/취업 준비생을 타깃한 어조에 쏠려 있다. 경쟁사(16personalities, MBTI 공식, 어세스타) 대비 독자적 서사와 비주얼 아이덴티티가 부재하다.

---

## Details

### 1. 법적 안전성 점검

#### 1-1. 문항 20개 공식 MBTI 유사성

**현재 상태**

`db/seeds.rb`의 20개 문항을 공식 MBTI Form M/Q의 알려진 출제 방식과 비교한다.

공식 MBTI는 다음 특징을 갖는다:
- 두 선택지(A/B) 강제 선택 방식 (forced-choice)
- 특정 어휘쌍 대립: "scheduled" vs. "unplanned", "logical" vs. "sympathetic" 등
- 직접 행동 서술보다 가치 선호도를 묻는 형식

현 프로젝트 문항은:
- Likert 1-5 척도 (MBTI와 포맷 상 상이)
- 한국어 독자 서술
- 구체적 일상 행동 묘사

**구체적 유사성 검토 (위험 레벨별)**

| 위험 | 문항 | 유사 MBTI 표현 |
|------|------|----------------|
| 낮음 | "새로운 사람들을 만나는 모임에 참석하면 에너지가 충전되는 편이다" | 에너지원(E/I) 개념은 공유하나 표현은 독자적 |
| 낮음 | "마감 시한이 다가와야 집중력이 높아지는 편이다" | J/P 구분에서 자주 등장하는 소재이나 서술 방식이 다름 |
| 낮음 | "추상적인 개념이나 이론에 대해 생각하는 것이 흥미롭다" | N/S 구분 핵심 소재이나 공식 문항과 표현 불일치 |
| 낮음 | "논리적으로 옳은 결정이라면 누군가의 기분이 상하더라도 실행해야 한다고 생각한다" | F/T 구분의 핵심 개념이나 직접 번역이 아님 |

**평가**: 공식 MBTI와 직접 중복되는 표현은 없다. Likert 포맷은 forced-choice 방식과 명확히 구별된다. 법적 위험은 낮다.

**개선 건의**:
- `seeds.rb` 첫 줄 주석 "All questions are original, not copied from any official assessment."는 법적 보호용으로 적절하나, 내부 문서에 '독자 개발 근거' 기록을 남겨두는 것을 권장한다.
- 향후 문항 추가 시 "에너지 충전" 같은 개념보다 한국적 맥락(직장 회식, SNS 소통 방식 등)에서 출발하면 독자성이 강해진다.

---

#### 1-2. 도메인명 독자성

**현재 상태**

4개 도메인과 MBTI 공식 4축의 대응:

| 이 프로젝트 도메인명 | MBTI 공식 축 | 평가 |
|---------------------|-------------|------|
| energy | Extraversion/Introversion (E/I) | 표현은 다르나 축 의미 동일 |
| decision_making | Intuition/Sensing (N/S) | 공식 명칭과 의미 괴리 있음 (N/S는 '인식' 기능) |
| relationship | Feeling/Thinking (F/T) | 의미 왜곡 가능성 있음 (T도 관계에 영향) |
| recovery | Judging/Perceiving (J/P) | 'recovery'는 공식 의미와 상당히 다름 |

**평가**: 도메인명이 MBTI 4축과 1:1 대응하므로 MBTI 프레임워크를 단순 재명명한 것이라는 인상을 준다. 특히 `decision_making`은 N/S축을 '결정'으로 해석하는 것이 심리학적으로도, 법적 독자성으로도 약한 지점이다. `recovery`는 J/P의 재해석으로 가장 창의적이나, 연결이 직관적으로 이해되지 않을 수 있다.

**개선 건의**:
- 도메인명을 행동/경험 중심으로 재정의하면 독자성 강화 가능.
  - `energy` → `connection_mode` (연결 방식)
  - `decision_making` → `focus_style` (탐구 방향)
  - `relationship` → `value_base` (가치 기반)
  - `recovery` → `rhythm_style` (생활 리듬)
- 혹은 4글자 코드 자체를 독자 조합으로 전환하는 중장기 옵션도 고려할 수 있다.

---

#### 1-3. RestrictedTerms / TextPolicyFilter 충분성

**현재 상태**

`restricted_terms.rb`의 차단 목록:
- 상표명: MBTI, Myers-Briggs, 마이어스-브릭스, Myers-Briggs Type Indicator
- 에니어그램 관련: 에니어그램, Enneagram
- 16personalities 한국어 유형명: 옹호자, 중재자, 논리학자, 건축가 등
- 공식 영문 유형명: The Inspector, The Protector 등

`trust_notice` 컨텍스트에서 MBTI/Myers-Briggs 허용 — 면책 고지를 위한 올바른 설계.

**평가**: 핵심 상표명 보호는 적절하다. 그러나 다음 누락 사항이 발견된다:

1. **"MBTI® 검사"류 변형 미포함**: "엠비티아이", "엠비티", "mbti검사" 등 한국 SNS에서 흔히 쓰는 변형이 필터를 통과할 수 있다.
2. **16personalities.com 고유 표현 미포함**: "성격 유형 검사" 자체는 일반 표현이라 무방하나, "당신의 성격 유형은..."과 같은 특정 UI 패턴이 확인될 경우 주의가 필요하다.
3. **Keirsey Temperament Sorter 관련 용어 미포함**: "아르티잔", "이상주의자" 같은 Keirsey 명칭이 빠져 있다.
4. **"DISC" 등 인접 도구 용어 미포함**: 서비스 확장 시 혼동 가능성이 있다.
5. **애니어그램 한자 표기 누락**: "에니어그램"은 있으나 "에너어그램"(오탈자 변형) 미포함.

**개선 건의**:
```ruby
# 추가 권장 제한 용어
"엠비티아이", "엠비티",
"DISC", "디스크 검사",
"강점혁명", "클리프턴",  # Gallup StrengthsFinder
"Keirsey", "키르세이",
"아르티잔", "가디언", "아이디얼리스트", "래셔널"  # Keirsey 4기질
```

---

### 2. 16유형 캐릭터명 독자성·한국어 자연스러움

**현재 상태 — 전체 목록**

| 코드 | 캐릭터명 (한) | 영문 | 평가 |
|------|-------------|------|------|
| ENFP | 빛나는 탐험가 | Radiant Explorer | 우수 |
| ENFJ | 따뜻한 이끌림 | Warm Guide | 주의 |
| ENTP | 날카로운 발명가 | Sharp Inventor | 양호 |
| ENTJ | 결단의 항해사 | Decisive Navigator | 우수 |
| ESFP | 자유로운 무대 | Free Stage | 미흡 |
| ESFJ | 든든한 연결고리 | Steady Connector | 양호 |
| ESTP | 현장의 해결사 | Field Solver | 양호 |
| ESTJ | 믿음직한 기둥 | Reliable Pillar | 양호 |
| INFP | 고요한 몽상가 | Quiet Dreamer | 주의 |
| INFJ | 깊은 통찰자 | Deep Seer | 양호 |
| INTP | 조용한 설계자 | Quiet Architect | 주의 |
| INTJ | 먼 곳을 보는 눈 | Far-Seeing Eye | 우수 |
| ISFP | 감각의 예술가 | Sensory Artist | 양호 |
| ISFJ | 조용한 돌봄이 | Silent Guardian | 양호 |
| ISTP | 냉철한 장인 | Cool Craftsman | 양호 |
| ISTJ | 묵묵한 완성자 | Steady Finisher | 양호 |

**세부 평가**

**우수한 캐릭터명:**
- "결단의 항해사" (ENTJ): 항해사라는 은유가 ENTJ의 방향 제시력과 자연스럽게 연결. 한국어에서도 자연스러운 어감.
- "빛나는 탐험가" (ENFP): 밝은 에너지와 호기심을 동시에 표현. 젊은 세대에 공감 가능.
- "먼 곳을 보는 눈" (INTJ): 시적이고 독창적. 16personalities "건축가"와 명확히 차별화.

**주의가 필요한 캐릭터명:**
- "따뜻한 이끌림" (ENFJ): "이끌림"은 명사로 쓰기 어색함. "따뜻한 안내자" 또는 "따뜻한 이끄는 사람" 형태로 수정하거나, "이끄는 빛"처럼 명사형으로 교정 필요.
- "자유로운 무대" (ESFP): "무대"는 사람이 아닌 장소/공간. 캐릭터명이 인물이 아닌 공간을 가리키는 것은 정체성 혼란을 줄 수 있음. "자유로운 이야기꾼" 또는 "무대 위의 자유인"으로 수정 권장.
- "고요한 몽상가" (INFP): "몽상가"는 한국어에서 다소 부정적 뉘앙스(현실감 부족)를 가질 수 있음. "깊은 꿈꾸는 이" 또는 "조용한 이상가"가 더 긍정적.
- "조용한 설계자" (INTP): "조용한"이 INFJ의 묘사에도 유사하게 쓰이고(깊은 통찰자), ISFJ(조용한 돌봄이)와도 겹쳐 내향형 유형들이 "조용한"으로 수렴하는 경향이 있다.

**패턴 문제 — 형용사 반복:**
내향형 유형 캐릭터명에서 "조용한" (INTP: 조용한 설계자, ISFJ: 조용한 돌봄이)이 반복된다. 16개 유형이 뚜렷하게 구별되려면 각 캐릭터명의 형용사/명사가 겹치지 않아야 한다.

**개선 건의**:
- "따뜻한 이끌림" → "따뜻한 나침반" 또는 "사람을 잇는 불꽃"
- "자유로운 무대" → "빛나는 현장인" 또는 "순간을 사는 사람"
- "고요한 몽상가" → "내면의 여행자" 또는 "조용한 이상가"
- "조용한 설계자" → "차가운 설계자" 또는 "논리의 탐구자"
- 16개 캐릭터명 전체에서 형용사 중복이 없도록 검토 필요.

---

### 3. 문항 20개 한국어 자연스러움·문화 적합성

**현재 상태**

총 20개 문항, 4도메인 × 5문항 구성.

**긍정적 평가:**
- 전반적으로 자연스러운 한국어 문어체를 사용하고 있음.
- "여행 계획" (recovery Q5), "주말 약속" (energy Q5) 등 한국 일상 맥락 반영.
- Likert 척도 문항으로서 적절한 단언 어미 사용 ("~는 편이다", "~고 생각한다").

**문화 적합성 이슈:**

1. **MZ세대 일상 반영 부족**: 문항들이 전통적인 성격 검사 언어에 머물러 있다. 한국 MZ세대가 공감하는 맥락(SNS 소통, 단톡방 vs 개인 DM, 유튜브/릴스 소비 패턴 등)이 없다.

2. **직장/팀 중심 편향**: energy Q4 ("팀 활동에서 자연스럽게 대화를 이끄는 역할"), relationship Q5 ("피드백을 줄 때") — 20대 초반 또는 학생 사용자에게는 거리감이 있는 표현.

3. **"생각을 정리할 때 혼자 고민하기보다 누군가와 이야기하는 것을 선호한다"** (energy Q2): 한국어에서 "누군가와"는 다소 격식체. "친구나 가까운 사람과"가 더 자연스럽다.

4. **"검증된 방법을 따르는 것이 새로운 시도보다 안전하다고 느낀다"** (decision_making Q2): "안전하다고 느낀다"는 표현이 다소 번역투. "더 편하다" 또는 "안심이 된다"가 한국어 감각에 더 맞다.

5. **"실제로 보고 만질 수 있는 구체적인 정보를 더 신뢰한다"** (decision_making Q5): "만질 수 있는"은 디지털 환경에서 MZ세대에게 낯선 표현. "직접 확인할 수 있는"이 더 현대적.

**개선 건의**:
- 1-2개 문항에 한국 MZ 맥락(SNS 소통 방식, 번아웃 경험, 취미 생활 방식 등)을 반영한 버전을 추가하거나 대체를 검토.
- 직장 맥락 문항(team, feedback)은 학생/취준생 버전으로 분기하는 문항 풀(question pool) 전략을 고려.
- 번역투 표현 3개를 구어체 한국어에 가깝게 수정.

---

### 4. 16유형 콘텐츠 품질·MZ세대 공감도

**현재 상태**

각 유형은 summary, strengths(4개), caution_patterns(3개), collaboration/conflict/learning/career/recovery_style 5개 필드를 제공한다.

**긍정적 평가:**
- 단순 강약점 나열을 넘어 협업·갈등·학습·커리어·회복 5가지 맥락 인사이트를 제공하는 구조는 경쟁사 대비 차별점이 있다.
- 진단보다 인사이트 지향 철학이 텍스트 어조에 비교적 잘 반영됨.
- "솔직한 감정 표현이 도움이 됩니다" (ENFP conflict_style) 같은 행동 제안형 표현은 긍정적.

**콘텐츠 품질 이슈:**

1. **요약문 길이와 깊이 불균일**: ENFP summary는 2문장이나 다소 일반적. "끝없는 호기심", "따뜻한 에너지"는 ENFP를 묘사하는 인터넷 글에 이미 포화상태인 표현. 독자적 서사가 필요.

2. **강점 4개가 지나치게 나열식**: "공감 능력이 뛰어남", "창의적 문제 해결", "팀 분위기 활성화", "빠른 적응력" — 16personalities에서도 볼 수 있는 수준. MZ세대가 "내 얘기네"라고 느끼는 구체적 디테일 부재.

3. **caution_patterns 표현이 부드럽지만 공허함**: "여러 프로젝트 동시 진행 시 완성도 저하 가능" — 알려진 사실의 반복. "왜 그런지", "언제 촉발되는지" 같은 심리적 맥락이 없으면 자기이해 기여가 낮다.

4. **커리어 힌트가 직종 나열에 그침**: ENFJ career_hints: "교육, 상담, 팀 리딩 분야와 잘 맞습니다" — 16personalities와 동일 수준. "왜 이 역할인지"의 연결 설명이 없다.

5. **recovery_style과 도메인명 'recovery'의 혼동 가능성**: 도메인 `recovery` (J/P축)와 유형 콘텐츠의 `recovery_style` (에너지 회복 방식)이 같은 단어를 다른 의미로 사용. 사용자 혼란 가능.

**MZ세대 공감도 분석:**

| 유형 | MZ 공감 포인트 | 부족한 점 |
|------|--------------|---------|
| INFP | "조용하지만 깊은 아이디어" — 공감 가능 | "이상과 현실의 괴리" 표현이 클리셰 |
| ENFP | "끝없는 호기심" — 공감 가능 | SNS에서 이미 포화된 ENFP 서사와 차별 없음 |
| ISTJ | "꾸준함과 정확성" — 보편적 | 한국 직장 문화에서 과도하게 이상화된 모습 |
| ESTP | "리스크를 두려워하지 않습니다" — 긍정적 | 실제 MZ ESTP의 고민(번아웃, 방향 찾기) 미반영 |

**개선 건의**:
- 각 유형의 summary에 "이런 순간 고개가 끄덕여진다면" 형식의 공감 트리거 문장 1개를 추가하면 MZ세대 SNS 공유 유도에 효과적.
- caution_patterns를 "이럴 때 특히 주의" 형태의 맥락 서술로 업그레이드.
- 커리어 힌트에 직종 나열 대신 "이런 환경에서 에너지를 얻는다"는 환경 묘사 방식을 활용.
- recovery_style 도메인명과 콘텐츠 필드명 충돌 해소 필요 (e.g. 콘텐츠 필드를 `recharge_style`로 변경).

---

### 5. 컴플라이언스 시스템 전체 평가

**현재 상태**

- `RestrictedTerms` + `TextPolicyFilter` 이중 구조
- `:trust_notice` 컨텍스트에서 MBTI/Myers-Briggs 허용
- `_trust_notice.html.erb`에서 ® 표기와 함께 "공식 MBTI® 검사와 무관합니다" 문구 표시
- `Composer`에서 `ToneFilter` 적용 후 프로필 저장

**강점:**
- 두 가지 컨텍스트 분리(trust_notice vs content)는 법적으로 올바른 접근.
- 면책 고지문에 ® 표기 포함은 적절한 상표 존중 표현.
- 결과 페이지 하단에 면책 고지가 눈에 띄게 배치됨.

**보완 필요 사항:**

1. **면책 고지 텍스트의 법적 완전성**: 현재 "공식 MBTI® 검사와 무관합니다"는 좋으나, "본 서비스의 결과는 공식 MBTI® 검사를 대체하지 않으며, 자격증 취득·취업·임상 목적으로 사용될 수 없습니다" 같은 구체적 사용 제한 문구 추가를 권장.

2. **RestrictedTerms에 변형어 추가 필요**: 앞서 언급한 "엠비티아이", "엠비티" 등.

3. **ToneFilter 역할 불명확**: `Composer`에서 `ToneFilter`를 적용하나, `ToneFilter` 파일이 분석 범위에 없어 동작 확인 불가. TextPolicyFilter와의 역할 분리가 명확한지 확인 필요.

4. **scan() 메서드의 대소문자 처리**: `Regexp.escape(term)` + `/i` 플래그로 대소문자 무시하나, "mbti"처럼 소문자 단독 입력 시 정상 탐지 여부 확인 필요. (현재 RESTRICTED 배열에 "MBTI" 대문자만 있고 `/i` 플래그가 있으므로 이론상 작동하나, 테스트 커버리지 확인 권장)

---

### 6. 경쟁사 대비 차별점 분석

#### 경쟁 서비스 비교

| 항목 | 이 프로젝트 | 16personalities | 어세스타 MBTI | MBTI 공식 |
|------|------------|----------------|-------------|---------|
| 문항 수 | 20개 | 60개 | 93개 | 93개 |
| 척도 | Likert 5점 | Likert 7점 | forced-choice | forced-choice |
| 유형명 | 독자 캐릭터명 | 역할명 (건축가 등) | 공식 4글자 코드 | 공식 4글자 코드 |
| 한국어 콘텐츠 | 독자 제작 | 번역 제공 | 한국어 전문 | 제한적 |
| 인사이트 영역 | 5개 맥락 | 5-7개 탭 | 직업/관계 중심 | 없음 |
| 법적 안전성 | 높음 | 보통(상표 논쟁) | 공식 라이선스 | — |
| MZ 타깃 | 부분적 | 강함 | 약함 | 없음 |

**이 프로젝트의 실질적 차별점:**
1. 독자 캐릭터명 부여 — 상표 독립성과 브랜드 아이덴티티를 동시에 확보하는 전략으로 방향성은 올바름.
2. 5개 맥락 인사이트(협업/갈등/학습/커리어/회복) — 16personalities의 단순 설명보다 구조적으로 우월.
3. 삭제 요청 기능 — 프라이버시 우선 서비스임을 명시적으로 표방.
4. Likert 척도 + 독자 도메인명 — 법적 위험 최소화 설계.

**부족한 점:**
1. **콘텐츠 깊이**: 16personalities는 유형당 5-8페이지 분량의 세부 설명. 현 프로젝트는 summary 2문장 수준.
2. **SNS 공유 최적화 부재**: MZ세대의 MBTI 문화는 "공유"가 핵심. 결과 카드 이미지 생성, 복사 가능한 요약 텍스트 등 공유 유도 기능 없음.
3. **관계 호환성/궁합 콘텐츠 부재**: 한국 MZ세대에서 MBTI의 최대 인기 콘텐츠는 "MBTI 궁합". 완전히 없음.
4. **비주얼 아이덴티티**: 16personalities는 유형별 아바타 이미지로 강렬한 시각적 차별화. 현 프로젝트는 4글자 코드만 표시.
5. **유형별 유명인/캐릭터 연결**: 한국에서 MBTI 관심의 상당 부분은 "내가 어떤 연예인과 같은 유형인지"에서 온다. 그러나 이는 저작권·초상권 이슈로 신중한 접근 필요.

---

## Key Findings

- **법적 안전성 (양호)**: 20개 문항은 공식 MBTI 문항과 직접 중복되지 않으며, Likert 포맷으로 명확히 구별된다. RestrictedTerms + TextPolicyFilter 구조는 상표 보호 기반이 잘 갖춰져 있다.

- **도메인명 취약점 (주의)**: 4개 도메인이 MBTI 4축과 1:1 대응하여 "독자 체계"라는 주장이 약하다. 특히 `decision_making`(N/S축)과 `recovery`(J/P축)는 MBTI 해석과 의미가 다르므로 혼란을 줄 수 있다.

- **캐릭터명 품질 불균일 (주의)**: "따뜻한 이끌림", "자유로운 무대" 등 문법·개념상 어색한 명칭이 존재하며, 내향형 유형에 "조용한" 형용사가 반복된다.

- **MZ세대 공감도 부족 (개선 필요)**: 문항과 콘텐츠가 한국 MZ 일상보다 일반적 심리검사 어조에 머물러 있다. SNS 소통 맥락, 번아웃 경험 등 구체적 MZ 맥락 반영이 필요하다.

- **콘텐츠 깊이 부족 (개선 필요)**: 5개 맥락 구조는 차별점이 있으나, 각 필드의 텍스트가 일반적 설명 수준에 머물러 있다. 16personalities 대비 콘텐츠 분량과 심도가 현저히 낮다.

- **SNS 공유·관계 콘텐츠 부재 (전략적 공백)**: 한국 MBTI 문화의 핵심인 "공유"와 "궁합" 콘텐츠가 전무하다. 서비스 바이럴리티의 가장 큰 리스크.

- **컴플라이언스 변형어 누락 (보완 필요)**: "엠비티아이", "엠비티" 등 SNS 변형 표현이 제한어 목록에 없다.

- **suggested_actions 영어 텍스트 혼입 (버그)**: `Composer#generate_suggested_actions`에서 영어 문자열이 직접 생성된다 ("In teamwork: ...", "When facing friction: ..."). 한국어 서비스에서 이 텍스트가 그대로 표시된다면 심각한 UX 이슈.

---

## Recommendations

### 즉시 수정 (Critical)

1. **`Composer#suggested_actions` 한국어화**: `generate_suggested_actions`의 영어 접두사("In teamwork:", "When facing friction:" 등)를 한국어로 변경하거나, DB 필드에서 직접 읽어 locale-aware하게 처리.

2. **캐릭터명 문법 교정**:
   - "따뜻한 이끌림" → "따뜻한 안내자" 또는 "따뜻한 나침반"
   - "자유로운 무대" → "빛나는 현장인" 또는 "순간의 예술가"
   - "고요한 몽상가" → "내면의 여행자"

3. **RestrictedTerms에 변형어 추가**: "엠비티아이", "엠비티", Keirsey 명칭 등.

### 단기 개선 (High Priority)

4. **문항 번역투 표현 수정**: "안전하다고 느낀다" → "안심이 된다", "만질 수 있는" → "직접 확인할 수 있는" 등 3-5개 자연스러운 한국어로 교정.

5. **recovery 용어 충돌 해소**: 도메인 `recovery`와 콘텐츠 필드 `recovery_style` 중 하나를 rename. 콘텐츠 필드를 `recharge_style`로 변경 권장.

6. **면책 고지 강화**: "자격증 취득·취업·임상 목적으로 사용 불가" 등 구체적 사용 제한 추가.

### 중장기 전략 (Medium Priority)

7. **도메인명 재설계 검토**: energy/decision_making/relationship/recovery를 MBTI 축과 덜 직접적으로 대응하는 독자 용어로 전환.

8. **콘텐츠 깊이 강화**: 각 유형 summary를 MZ 공감 트리거 문장 포함 3-4문장으로 확장. caution_patterns에 맥락 설명 추가.

9. **SNS 공유 기능 설계**: 결과 카드 이미지 생성, 카카오톡 공유 버튼 추가 — 바이럴리티를 위한 최우선 기능.

10. **비주얼 아이덴티티 개발**: 16개 유형별 아이콘/아바타 도입으로 시각적 차별화.

---

## References

- `/Users/kampikrein/A/personality/db/seeds.rb` — 16유형 정의 및 20개 문항
- `/Users/kampikrein/A/personality/app/services/compliance/restricted_terms.rb` — 제한어 목록
- `/Users/kampikrein/A/personality/app/services/compliance/text_policy_filter.rb` — 텍스트 필터 로직
- `/Users/kampikrein/A/personality/app/services/profiles/type_content_service.rb` — 유형 콘텐츠 서비스
- `/Users/kampikrein/A/personality/app/services/profiles/composer.rb` — 프로필 생성 로직
- `/Users/kampikrein/A/personality/app/views/results/show.html.erb` — 결과 페이지 메인
- `/Users/kampikrein/A/personality/app/views/results/_trust_notice.html.erb` — 면책 고지
- `/Users/kampikrein/A/personality/app/views/results/_type_hero.html.erb` — 유형 히어로 섹션
- `/Users/kampikrein/A/personality/app/views/results/_spectrum.html.erb` — 스펙트럼 바
- `/Users/kampikrein/A/personality/app/views/results/_insight_card.html.erb` — 인사이트 카드
