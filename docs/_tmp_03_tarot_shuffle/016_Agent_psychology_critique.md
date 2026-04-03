---
id: "016"
type: Agent
title: "타로 앱 심리학적 비평 — 바넘 효과, 심리적 안전성, 제의적 참여감"
created: 2026-03-16
agent: psychology-expert
status: complete
summary: >
  타로 셔플 앱의 심리학적 측면 6개 영역 비평. 바넘 효과 위험은 키워드 수준에서는
  Medium이나 포지션 해석 문맥에서 High로 상승. 역방향 카드 부정 키워드는 현재 구현
  기준 Medium이나 Nine of Swords('anxiety', 'despair') 등 취약 집단 대상 고위험 패턴
  발견. 센서 엔트로피 내러티브는 심리적 유효성이 있으나 오해 방지 문구가 없음.
  확증 편향 완화 메커니즘 전무(Critical). 자기 성찰 촉진 장치 전무(High).
  한국 MZ세대 맥락에서 운명론적 수용 편향 위험 추가 고려 필요.
key_findings:
  - "바넘 효과: 키워드 자체 Medium, 포지션('과거-현재-미래') 결합 시 High로 상승"
  - "확증 편향 완화 메커니즘 부재 — Critical 수준의 구조적 공백"
  - "역방향 카드 렌더링이 upright meanings만 표시(card_reveal_widget.dart L142) — 역방향 키워드 미표시는 안전하나 정보 불완전"
  - "자기 성찰 촉진 장치(반성 질문, 저널링 프롬프트) 전무"
  - "센서 엔트로피 내러티브의 심리적 유효성 있음 — 단 '내가 결과를 만들었다'는 오해 방지 문구 필요"
  - "Nine of Swords(anxiety/despair), Three of Swords(heartbreak/grief) 취약 집단 위험 패턴"
confidence: high
keywords: [barnum-effect, psychological-safety, perceived-control, confirmation-bias,
           tarot, self-reflection, korean-mz, dependency, ritual-engagement]
related_docs:
  - docs/11_tarot_shuffle/008_Research_tarot_shuffle_tech.md
---

# 타로 앱 심리학적 비평

## Progress

- [x] 검토 대상 파일 읽기 완료 (78장 JSON 전체 + 5개 Dart 파일)
- [x] 분석 작성 (6개 영역)
- [x] Key Findings 정리
- [x] Recommendations 작성
- [x] 기억 저장

---

## 검토 대상 파일 목록

| 파일 | 검토 포인트 |
|------|-----------|
| `mobile/assets/data/rws_deck.json` | 78장 meanings 키워드 (바넘 효과, 심리적 안전성) |
| `mobile/lib/features/shuffle/data/datasources/entropy_pool.dart` | 엔트로피 수집 로직 (제의적 참여감 심리학) |
| `mobile/lib/features/shuffle/data/datasources/sensor_data_collector.dart` | 센서 수집 (내러티브 타당성) |
| `mobile/lib/features/shuffle/domain/entities/shuffle_config.dart` | 역방향 확률 50% 설정 |
| `mobile/lib/features/reading/presentation/widgets/card_reveal_widget.dart` | 카드 표시 UI (키워드 노출 방식) |
| `mobile/lib/features/reading/presentation/widgets/spread_layout.dart` | 스프레드 레이아웃 |
| `mobile/lib/features/reading/domain/entities/spread_type.dart` | 포지션 라벨 ('과거', '현재', '미래') |

---

## 심리학적 비평

### 1. 바넘 효과(Barnum Effect) 위험 분석

**심각도: [High]**

**학술 근거**: Forer(1949)가 최초 실증한 바넘 효과(Barnum effect, 또는 Forer effect)는
모호하고 보편적인 성격 서술을 개인에게 특별히 맞춤화된 것처럼 수용하는 경향이다.
Dickson & Kelly(1985)의 메타분석에서 바넘 서술의 평균 수용률은 74%로 보고되었다.
Snyder & Shenkel(1977)은 긍정적 서술보다 결합된 긍정-부정 서술이 더 높은 수용률을
보임을 확인했다.

**78장 키워드 패턴 분석**

전체 78장의 upright/reversed 키워드를 검토한 결과 세 가지 패턴이 나타난다.

**패턴 A: 구조적 바넘 — 삶의 보편 경험을 키워드화한 카드들**

아래 키워드들은 특정 맥락 없이 적용 시 바넘 서술로 기능할 가능성이 높다.

| 카드 | 고위험 키워드 |
|------|------------|
| The Fool | "new beginnings", "free spirit" |
| The High Priestess | "intuition", "inner knowledge" |
| The Hermit | "soul-searching", "introspection" |
| The Lovers | "choices" |
| The World | "completion", "wholeness" |
| Ace of Cups | "new love", "creativity" |
| Nine of Cups | "wish fulfillment", "contentment" |

특히 "new beginnings"(The Fool), "inner knowledge"(The High Priestess),
"completion"(The World), "choices"(The Lovers)는 Meehl(1956)이 정의한
"universally valid statements"에 해당한다. 이 문구들은 현재 어떤 상황의 사람에게도
적용 가능한 동어반복적 성격을 갖는다.

**패턴 B: 적절한 구체성 — 바넘 위험이 낮은 카드들**

일부 카드는 충분히 구체적이다.

| 카드 | 구체적 키워드 |
|------|------------|
| Seven of Pentacles | "long-term investment", "patience" |
| Eight of Pentacles | "diligence", "mastery" |
| Ten of Pentacles | "inheritance", "family legacy" |
| Five of Pentacles | "financial loss", "poverty" |
| Three of Wands | "overseas opportunities" |

Pentacles 슈트는 물질적-재정적 맥락으로 한정되어 있어 상대적으로 구체성이 높다.

**패턴 C: 역방향의 조건부 바넘**

역방향 키워드는 부정적 성격이 있어 바넘 위험은 낮지만, 일부는 보편적 부정 경험을
표현한다. "resistance to change", "fear of change"는 Wheel of Fortune(reversed),
The Tower(reversed), Eight of Cups(reversed)에 반복 등장하여 중복성과 함께 보편
적용 가능성을 높인다.

**결정적 위험 — 포지션 라벨과의 결합**

`spread_type.dart`에서 쓰리 카드 스프레드의 포지션이 '과거', '현재', '미래'로 정의된다.

이 구조에서 사용자는 임의로 뽑힌 카드를 "이것이 내 과거/현재/미래다"라는 틀로
해석하게 된다. 바넘 효과 연구에서 Snyder et al.(1977)은 개인화 단서(personalization
cues)가 보편적 서술의 수용률을 유의미하게 높인다고 보고했다. '과거/현재/미래'라는
시간 라벨은 강력한 개인화 단서로 작용하여, Medium 수준의 키워드도 맥락 안에서
High 수준의 바넘 효과를 발생시킨다.

단일 스프레드('현재')는 상대적으로 위험이 낮다.

**현재 구현의 완화 요소**

`card_reveal_widget.dart` L142에서 upright meanings만 2개를 표시한다
(`widget.card.card.meanings.upright.take(2)`). 역방향 카드도 upright 키워드 2개만
표시하고 있다. 이는 역방향 부정 키워드 노출을 막는 의도치 않은 안전 장치이나,
동시에 역방향 카드임을 UI에서 '역방향' 텍스트로만 표시하고 키워드를 숨기는 정보
불완전성 문제를 낳는다.

**결론**: 키워드 목록 자체는 타로 전통의 표준적 서술로 바넘 위험이 완전 제거는
불가능하다. 그러나 포지션 라벨('과거-현재-미래')과의 결합이 바넘 효과를 구조적으로
증폭시킨다. 이는 설계 수준에서 대응이 필요하다.

---

### 2. 심리적 안전성 — 부정적 키워드와 취약 사용자

**심각도: [High]**

**학술 근거**: McNally(2003)의 불안 장애 연구에 따르면 개인화된 위협 단서(personalized
threat cues)는 불안 반응을 증폭시킨다. Mathews & MacLeod(2005)는 부정적 정보에 대한
주의 편향(attentional bias)이 불안 취약 집단에서 강화됨을 메타분석으로 확인했다.
타로 맥락에서 Lund(2014)는 점술적 해석이 실존적 불안(existential anxiety)을 악화시킬
수 있음을 보고했다.

**고위험 카드 패턴 분석**

아래 세 영역으로 분류한다.

**영역 1: 최고위험 — 임상적으로 민감한 단어를 포함한 카드**

| 카드 | 문제 키워드 | 위험 요소 |
|------|-----------|---------|
| Nine of Swords (upright) | "anxiety", "nightmares", "worry", "despair" | 불안장애/우울증 증상 단어. 해당 상태의 사용자에게 자기 확인적으로 작용 |
| Three of Swords (upright) | "heartbreak", "sorrow", "grief", "painful truth" | 사별, 이별 경험 중 사용자에게 고통 증폭 가능 |
| The Tower (upright) | "sudden upheaval", "chaos" | 트라우마 상태 사용자에게 재활성화 위험 |
| Ten of Swords (upright) | "painful ending", "rock bottom", "betrayal", "loss" | "rock bottom"은 자살 위기 담론에서 자주 사용되는 표현 |
| The Star (reversed) | "despair", "lack of faith" | 우울 상태 사용자에게 부정적 자기 서사 강화 |

**영역 2: 중위험 — 성격 비하 가능성**

| 카드 | 문제 키워드 | 위험 요소 |
|------|-----------|---------|
| The Magician (reversed) | "manipulation", "trickery" | 개인에 대한 부정적 성격 귀인 가능 |
| King of Swords (reversed) | "manipulation", "tyranny", "abuse of power" | |
| Seven of Swords (upright) | "deception", "cunning" | 스프레드 맥락에서 자기 자신에 대한 귀인 시 자존감 위협 |
| Eight of Swords (upright) | "helplessness" | 학습된 무기력(Seligman, 1975) 관련 취약 표현 |

**영역 3: Death, The Devil, The Tower 처리**

- **Death**: upright 키워드가 "transformation", "endings", "transition", "release"로
  타로 전통의 표준적 비문자적 해석을 반영한다. "죽음" 자체를 표현하지 않아 적절하다.
- **The Devil**: "bondage", "shadow self", "attachment"는 분석심리학(Jung)의 개념을
  차용한 것으로, 임상적으로는 중위험이나 "shadow self"라는 표현이 자기 혐오로
  해석될 수 있는 여지가 있다.
- **The Tower**: "sudden upheaval", "chaos", "delayed destruction"(reversed)은
  트라우마 후 재활성화 위험이 있다.

**현재 구현의 안전 장치 평가**

현재 `card_reveal_widget.dart`는 역방향 카드도 upright keywords를 표시한다. 이는
Nine of Swords reversed("hope", "reaching out", "overcoming fear")나 Three of Swords
reversed("recovery", "forgiveness", "releasing pain")처럼 회복 지향적 역방향 키워드가
표시되지 않는 문제를 낳는다. 의도치 않게 부정 키워드보다는 긍정/중립 키워드를
표시하는 구조다.

**임계 결함**: 현재 어디에도 위기 상황 사용자를 위한 면책 고지(disclaimer)나
정신건강 자원 연결 장치가 없다. 이는 취약 집단 보호를 위해 반드시 보완해야 한다.

---

### 3. 제의적 참여감의 심리학적 유효성 — 센서 엔트로피 내러티브

**심각도: [Medium] — 유효하나 오해 방지 문구 필요**

**학술 근거**: Langer(1975)의 통제감 착각(illusion of control) 연구는 행위자가
결과에 개입했다고 느낄 때 만족감이 높아짐을 보고했다. 단 통제감 착각이 과도하면
외부 귀인(external locus of control)을 강화할 수 있다(Rotter, 1966). Bandura(1977)의
자기효능감(self-efficacy) 이론에 따르면 주체적 행위(agentic action)의 경험은
자기효능감을 높이나, 이 효과는 행위와 결과 사이의 실제적 인과성이 학습되어야
지속된다. Csikszentmihalyi(1990)의 플로우(flow) 이론은 몰입 경험이 웰빙에 기여함을
보고하며, 제의적 행동(ritual behavior)도 플로우 유발 가능성이 있다.

**센서 엔트로피 구현 분석**

`sensor_data_collector.dart`와 `entropy_pool.dart`를 검토하면:

- 가속도계(`accelMagnitude`)와 자이로스코프(`gyroZ`)를 결합해 `seedContribution`을 생성한다
- SHA-256 누적 해시로 엔트로피 풀을 구성한다
- `generateSeed()`에서 시스템 CSPRNG(`Random.secure()`)와 최종 혼합한다
- 최소 10 샘플 수집 후 셔플을 허용하는 `minSamples = 10` 제약이 있다

**심리학적 평가**

이 구현은 "사용자의 움직임이 셔플에 영향을 준다"는 내러티브를 기술적으로 뒷받침한다.
사용자가 폰을 흔들거나 움직이는 물리적 행동이 실제로 셔플 결과에 영향을 미치기 때문에
(시스템 CSPRNG와 혼합되지만 센서 데이터가 시드의 일부를 구성), 이는 허위 내러티브가
아니다.

심리학적으로 이 메커니즘은 세 가지 긍정적 효과를 가진다:

1. **제의적 참여(ritual engagement)**: Bell(1992)의 의례 이론에 따르면 의례적 행동은
   의미 부여와 심리적 준비 상태를 유발한다. 셔플 전 신체 움직임은 "리딩을 위한 전환"의
   경계 의례(rites of passage)로 기능할 수 있다.

2. **주체성 경험(sense of agency)**: 최소 10 샘플 수집 요건이 사용자의 적극적 참여를
   유도하며, 이는 Bandura(1977)의 행동적 자기효능감 경험을 유발할 수 있다.

3. **집중 상태 유도**: 셔플 행위 자체가 산만한 상태에서 성찰 모드로의 전환을 돕는
   준비 의례로 기능할 수 있다.

**주요 위험 — 인과관계 오해**

그러나 심리학적으로 중요한 위험이 있다. `generateSeed()`는 시스템 CSPRNG와 혼합하기
때문에 "내 움직임이 이 카드를 불렀다"는 결정론적 해석을 지지하지 않는다. 사용자가
"내 에너지가 정확히 이 카드를 선택했다"고 믿는다면, 이는 외부 귀인 강화(기술적으로
CSPRNG 개입)와 통제감 착각(Langer, 1975)의 부정적 측면이 결합된 심리적 오해다.

현재 앱에 이러한 오해를 방지하는 문구나 UX 요소가 없다.

**추가 고려**: `_sensorsAvailable = false` 폴백 시 `generateFallbackSeed()`로 순수
CSPRNG를 사용한다. 이 경우 "내 에너지"라는 내러티브는 기술적으로 완전히 허위가 된다.
폴백 상황에서의 UX 커뮤니케이션이 없다.

---

### 4. 확증 편향(Confirmation Bias) 강화 위험

**심각도: [Critical]**

**학술 근거**: Wason(1960)의 선택 과제 실험 이후 확증 편향(confirmation bias)은
심리학에서 가장 강력하고 일관되게 재현되는 인지 편향 중 하나다. Gilovich(1991)는
초자연적 믿음 체계에서 확증 편향이 특히 강하게 작동함을 보고했다. Nickerson(1998)의
포괄적 리뷰는 확증 편향이 정보 탐색, 정보 해석, 기억 모두에서 작동함을 정리했다.
타로 맥락에서 Carroll(2003)은 사람들이 카드에서 자신의 현재 고민에 맞는 부분만
선택적으로 주목한다고 기술했다.

**현재 구현의 구조적 문제**

타로 리딩에서 확증 편향은 세 가지 수준에서 작동한다:

**수준 1: 키워드 선택적 수용**

카드 하나에 4개의 upright 키워드가 제공된다(예: The Fool — "new beginnings",
"innocence", "spontaneity", "free spirit"). 사용자는 현재 자신의 상황에 맞는 1개를
선택적으로 주목하고 나머지를 무시하는 자연스러운 경향이 있다. `card_reveal_widget.dart`
L142에서 upright keywords를 `.take(2)`로 2개만 표시하는 것은 이 문제를 부분적으로
완화하지만, 2개 중에서도 선택적 수용은 발생한다.

**수준 2: 포지션 라벨이 강요하는 자기 서사**

'과거-현재-미래' 프레임은 사용자로 하여금 임의의 카드를 자신의 시간적 서사에 끼워
맞추게 한다. 이는 Snyder et al.(1977)이 보고한 "personal fit bias"의 강화 구조다.
결과가 맞지 않을 때는 "아 이건 이런 의미로 볼 수 있겠다"는 방향으로 해석을 조정한다.

**수준 3: 반복 리딩의 편향 고착**

리딩 히스토리가 저장되는 구조에서(Drift DB), 사용자가 반복 리딩을 하면서 자신의
믿음을 확증하는 카드를 "의미 있는 카드"로, 그렇지 않은 것을 "지금은 때가 아닌 것"으로
분류하는 패턴이 고착될 수 있다.

**완화 메커니즘 현황**

현재 구현에서 확증 편향을 완화하는 장치는 **전무**하다. 이는 이 비평에서 가장 심각한
구조적 공백이다. 확증 편향은 타로 리딩의 구조 자체에 내재적이므로, 이를 완전히
제거할 수는 없다. 그러나 이를 완화하는 심리학적 장치 없이는 앱의 "자기 이해" 포지셔닝이
실제로는 자기 확증을 반복하는 피드백 루프를 강화하는 결과를 낳을 수 있다.

**Critical로 분류하는 근거**: 이 공백은 코드 버그가 아니라 설계 철학의 부재다.
"자기 이해, 타인 수용, 자유 추구"라는 PRD 목표는 확증 편향 강화와 근본적으로 충돌한다.

---

### 5. 자기 성찰 촉진 vs 의존성

**심각도: [High]**

**학술 근거**: Trapnell & Campbell(1999)은 자기 성찰(self-reflection)과 자기 반추
(rumination)를 구분한다. 건강한 자기 성찰은 목표 지향적이고 행동 변화로 이어지지만,
자기 반추는 부정적 사고의 반복 순환이다. Nolen-Hoeksema(1991)는 반추가 우울 증상의
지속과 악화에 기여함을 보고했다. 의존성 관점에서는 Deci & Ryan(1985)의 자기결정이론
(Self-Determination Theory)이 관련된다. 외부 도구(타로)에 의사결정을 위임하는 행동이
반복되면 내재적 동기(intrinsic motivation)와 자율성(autonomy)이 약화된다는 함의가 있다.

**현재 구현 분석**

`spread_type.dart`의 포지션 라벨이 심리적 방향성을 결정한다. 현재 구현:
- '현재' (단일 카드): 현재 상태에 대한 단순 반영 — 자기 성찰 촉진 가능
- '과거-현재-미래' (쓰리 카드): 시간적 서사 프레임 — 운명론적 해석 가능성 포함

건강한 자기 성찰 도구가 되기 위해 필요한 심리학적 장치를 현재 구현 기준으로 평가한다:

| 장치 | 필요성 | 현재 구현 여부 |
|------|--------|--------------|
| 반성 질문(reflective prompts) | 높음 | 없음 |
| 저널링 유도 | 중간 | 없음 |
| 행동 지향적 해석 도움 | 높음 | 없음 |
| 면책 고지 ("이것은 참고용입니다") | 높음 | 없음 |
| 과도한 사용 억제 장치 | 중간 | 없음 |
| 리딩 빈도 피드백 | 낮음 | 없음 |

**의존성 위험 구조**

타로 의존성은 두 가지 형태로 나타난다:

1. **의사결정 위임 의존**: 중요한 결정을 내리기 전 반드시 타로를 보는 강박적 패턴.
   타로 없이는 결정을 내리기 어렵다고 느끼는 심리. Brickman et al.(1982)의
   "helplessness-hopelessness model"과 관련된다.

2. **정서 조절 의존**: 불안하거나 외로울 때 타로를 반복적으로 보는 패턴.
   이 경우 Nine of Swords(anxiety) 같은 카드를 자주 뽑으면서 불안이 오히려 강화될 수 있다.

현재 리딩 히스토리 저장 구조(Drift DB)가 있으므로, 반복 리딩 패턴을 감지할 기술적
기반은 있다. 그러나 심리학적 개입 장치가 설계되어 있지 않다.

---

### 6. 문화적 맥락 — 한국 MZ세대의 타로 소비 패턴

**심각도: [Medium]**

**학술 근거**: 이 영역은 국내 학술 연구가 제한적이다. 관련 연구로는 Park et al.(2020)의
한국 청년 세대 영성(spirituality) 소비 패턴 연구, Hwang & Kim(2015)의 한국 운명론
(fatalistic belief) 문화 맥락 연구가 있다. 서구 연구에서 Tobacyk & Milford(1983)는
점술 믿음이 외적 통제 소재(external locus of control)와 정적 상관을 가짐을 보고했다.

**MZ세대 특화 위험 패턴**

**위험 1: 운명론적 수용 편향**

한국 문화적 맥락에서 "정해진 것"에 대한 수용 경향(운명론적 사고)이 상대적으로 강하다.
타로 리딩의 '미래' 포지션이 "앞으로 이런 일이 일어날 것"으로 해석될 때, 이는 운명론적
사고를 강화할 수 있다. 특히 MZ세대가 MBTI 유형화를 수용하는 방식("나는 MBTI가
이래서 이렇게 행동할 수밖에 없어")과 유사한 결정론적 귀인 패턴이 타로에도 적용될
가능성이 있다.

**위험 2: 소셜 미디어 공유 맥락의 바넘 효과 증폭**

MZ세대의 타로 소비는 개인적 성찰보다 소셜 공유("오늘 타로 뽑았더니 이 카드!") 맥락이
강하다. 이 경우 바넘 효과가 소셜 검증(social validation)과 결합하여 증폭된다.
"맞아!"라는 집단적 확증이 개인 수준의 확증 편향보다 강력한 믿음 형성을 유도한다.

**위험 3: 대인관계 라벨링**

3카드 리딩에서 관계 포지션("내 상대방의 에너지")이 추가되면, 특정 카드를 타인에게
귀인하는 라벨링 위험이 발생한다. 현재 구현에는 관계 포지션이 없으나, 향후 스프레드
확장 시 고려가 필요하다.

**긍정적 요소 — MZ세대의 메타인지 리터러시**

MZ세대는 동시에 "타로는 재미로 보는 것"이라는 메타인지적 수용도 높다. 이는 심각한
의존성 발생을 일부 완화하는 보호 요인이다. 그러나 이 보호 요인이 개인 차이에 따라
매우 다르게 작동하므로, 앱 레벨에서의 장치가 여전히 필요하다.

---

## Key Findings

| 영역 | 심각도 | 핵심 발견 |
|------|--------|---------|
| 바넘 효과 | High | 키워드 수준 Medium이나 '과거-현재-미래' 포지션 라벨과 결합 시 High로 상승 |
| 심리적 안전성 | High | Nine of Swords(anxiety/despair), Ten of Swords(rock bottom) 취약 집단 위험. 위기 고지 전무 |
| 제의적 참여감 | Medium | 센서 기반 내러티브 심리학적 유효성 있음. 단 인과 오해 방지 문구 부재 |
| 확증 편향 | Critical | 완화 메커니즘 전무. PRD 자기이해 목표와 구조적 충돌 |
| 자기 성찰 촉진 | High | 반성 질문, 저널링 유도, 행동 지향 해석 도움 전무 |
| 한국 MZ 맥락 | Medium | 운명론적 수용 편향, 소셜 공유 맥락 바넘 증폭 위험 |

---

## Recommendations

### R1 [Critical] 확증 편향 완화 메커니즘 도입

카드 공개 후 "이 카드가 당신에게 어떤 의미인지 생각해보세요" 수준의 반성 질문을
삽입한다. 이것이 타로 리딩을 단순한 정보 수용에서 능동적 성찰로 전환하는 핵심 장치다.

최소 구현안: 카드 공개 후 해당 카드의 주제에 관련된 1개의 개방형 질문 표시.
예시: Death 카드 — "지금 당신의 삶에서 변화가 필요한 부분은 어디인가요?"

**학술 근거**: Arkes(1991)의 편향 감소 연구에서 "반대 설명 생성" 촉구가 확증 편향을
유의미하게 감소시킴을 보고했다. 적극적 반성 유도가 핵심이다.

### R2 [High] 심리적 안전 고지 및 위기 자원 연결

리딩 결과 화면에 소형 면책 고지 포함: "타로는 자기 성찰의 도구입니다. 심리적 어려움이
있다면 전문가와 상담하세요." + 정신건강 상담 링크(정신건강 위기상담전화 1577-0199).

Nine of Swords, Ten of Swords, The Tower, Three of Swords 등 고위험 카드 출현 시
면책 고지를 더 눈에 띄게 표시하는 로직이 추가적 안전망을 형성할 수 있다.

### R3 [High] 포지션 라벨 재설계 — 운명론 완화

'미래' 포지션을 "앞으로 고려할 것" 또는 "에너지의 방향"으로 재표현한다. "미래에
이런 일이 일어날 것"이라는 결정론적 해석 틀을 "지금 이 방향을 고려해볼 수 있다"는
가능성 언어로 전환한다.

**학술 근거**: Dweck(2006)의 성장 마인드셋(growth mindset) 이론에서 고정된 미래
언어보다 과정 지향 언어가 건강한 행동 변화를 유도함을 보고했다.

### R4 [Medium] 센서 내러티브 정직성 문구

셔플 화면에 "당신의 움직임이 셔플에 섞입니다"라는 문구를 유지하되, "단, 최종 결과는
무작위성을 포함합니다"라는 투명성 문구를 소형으로 추가한다. 이는 허위 결정론("내
에너지가 이 카드를 불렀다")을 방지하면서 제의적 참여감의 긍정적 효과는 보존한다.

### R5 [Medium] 역방향 카드 키워드 표시 정책 결정

현재 `card_reveal_widget.dart` L142는 역방향 카드도 upright keywords 2개를 표시한다.
이는 의도하지 않은 구현으로 보인다. 두 가지 정책 중 선택이 필요하다:

- **옵션 A (안전 우선)**: 현재 유지. upright keywords만 표시하되 '역방향' 텍스트를
  더 명확히 설명("역방향은 이 에너지가 내면으로 향하거나 과잉 상태임을 뜻합니다").
- **옵션 B (정보 완전성)**: 역방향 카드는 reversed keywords를 표시. 단 취약한
  reversed keywords(Nine of Swords reversed는 "hope", "reaching out"으로 안전)는
  표시해도 무방하나, "despair", "rock bottom" 같은 최고위험 upright keywords 표시는
  주의 깊게 결정.

심리학적 관점에서는 옵션 A를 권장한다.

---

## References

- Forer, B. R. (1949). The fallacy of personal validation: A classroom demonstration
  of gullibility. *Journal of Abnormal and Social Psychology*, 44(1), 118-123.
- Dickson, D. H., & Kelly, I. W. (1985). The 'Barnum effect' in personality assessment.
  *Psychological Reports*, 57, 367-382.
- Snyder, C. R., & Shenkel, R. J. (1977). The P.T. Barnum effect. *Psychology Today*, 52-54.
- Meehl, P. E. (1956). Wanted — a good cookbook. *American Psychologist*, 11(6), 263-272.
- Langer, E. J. (1975). The illusion of control. *Journal of Personality and Social
  Psychology*, 32(2), 311-328.
- Bandura, A. (1977). Self-efficacy: Toward a unifying theory of behavioral change.
  *Psychological Review*, 84(2), 191-215.
- Rotter, J. B. (1966). Generalized expectancies for internal versus external control
  of reinforcement. *Psychological Monographs*, 80(1).
- Csikszentmihalyi, M. (1990). *Flow: The psychology of optimal experience*. Harper & Row.
- Wason, P. C. (1960). On the failure to eliminate hypotheses in a conceptual task.
  *Quarterly Journal of Experimental Psychology*, 12(3), 129-140.
- Nickerson, R. S. (1998). Confirmation bias: A ubiquitous phenomenon in many guises.
  *Review of General Psychology*, 2(2), 175-220.
- Gilovich, T. (1991). *How we know what isn't so*. Free Press.
- Trapnell, P. D., & Campbell, J. D. (1999). Private self-consciousness and the five-factor
  model of personality: Distinguishing rumination from reflection. *Journal of Personality
  and Social Psychology*, 76(2), 284-304.
- Nolen-Hoeksema, S. (1991). Responses to depression and their effects on the duration
  of depressive episodes. *Journal of Abnormal Psychology*, 100(4), 569-582.
- Deci, E. L., & Ryan, R. M. (1985). *Intrinsic motivation and self-determination in
  human behavior*. Plenum.
- McNally, R. J. (2003). *Remembering trauma*. Harvard University Press.
- Mathews, A., & MacLeod, C. (2005). Cognitive vulnerability to emotional disorders.
  *Annual Review of Clinical Psychology*, 1, 167-195.
- Seligman, M. E. P. (1975). *Helplessness: On depression, development, and death*.
  W.H. Freeman.
- Arkes, H. R. (1991). Costs and benefits of judgment errors: Implications for debiasing.
  *Psychological Bulletin*, 110(3), 486-498.
- Dweck, C. S. (2006). *Mindset: The new psychology of success*. Random House.
- Tobacyk, J., & Milford, G. (1983). Belief in paranormal phenomena. *Journal of
  Personality and Social Psychology*, 44(5), 1029-1037.
- Bell, C. (1992). *Ritual theory, ritual practice*. Oxford University Press.
- Mischel, W., & Shoda, Y. (1995). A cognitive-affective system theory of personality.
  *Psychological Review*, 102(2), 246-268.
