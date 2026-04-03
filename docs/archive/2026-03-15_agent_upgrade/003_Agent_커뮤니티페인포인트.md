---
id: "003"
title: "타로 앱 커뮤니티 페인포인트 조사"
category: agent
status: archived
created: 2026-03-15
summary: >
  기존 타로 앱에 대한 사용자 불만, 커스텀 셔플/덱 수요, 소셜 기능 기대를 커뮤니티 조사로 파악
keywords: [agent-report, community-research, tarot-app, painpoints, user-demand]
modules: [community-research]
---

# 타로 앱 커뮤니티 페인포인트 조사

## Progress
### Completed
- [x] 기존 타로 앱 불만 사항 검색 및 수집
- [x] 영적 연결감 관련 불만 사례 조사
- [x] 커스텀 덱/셔플 수요 증거 수집
- [x] 소셜/커뮤니티 기능 기대와 우려 조사
- [x] 경쟁앱 분석 (Labyrinthos, Golden Thread, Galaxy Tarot 등)
### Remaining
(없음)
### Current Status
조사 완료.

---

## Summary

기존 타로 앱 사용자 커뮤니티에서 수집한 핵심 페인포인트는 5개 카테고리로 분류된다: (1) 영적 연결감 부족 -- 디지털 셔플이 "랜덤 넘버 제너레이터"처럼 느껴진다는 불만이 가장 보편적, (2) 셔플 알고리즘 불신 -- 비공개 가중치, 반복 카드 출현 등 투명성 부족, (3) 수익화 모델에 대한 반감 -- 저널/스프레드 등 핵심 기능의 공격적 페이월, (4) AI 해석의 일반성 -- 개인화 부족하고 인간 리더 대비 감정적 뉘앙스 부재, (5) 커스텀 덱/소셜 기능의 부재 -- 자신의 덱을 사용하거나 커뮤니티와 공유하는 기능이 극소수 앱에만 존재. 이 조사는 personality 프로젝트의 타로 앱이 커스텀 셔플(물리 엔진, CSPRNG), 커스텀 덱 등록, 소셜/바운티 시스템으로 차별화할 수 있는 실증적 근거를 제공한다.

---

## Details

### 1. 기존 타로 앱 일반 불만 사항

#### 1.1 디지털 vs 물리적 경험의 괴리

사용자들은 타로 앱을 사용할 때 "랜덤 넘버 제너레이터"처럼 느껴진다고 반복적으로 보고한다. The Tarot Forums에서 한 사용자는 "same digital cards but totally different vibes -- some feel dead while others somehow keep that mystical connection"이라고 표현했다. 핵심 불만은 물리적 카드의 촉각적 경험(셔플, 카드를 만지는 느낌)이 디지털에서 재현되지 않는다는 것이다.

- BiddyTarot: 컴퓨터 생성 리딩은 "인간 타로 리더의 직관이 부족하고, 에너지를 감지하거나 투시적으로 보거나, 공감적으로 연결할 수 없다"
- The Tarot Forums: Labyrinthos는 "too clinical -- like studying flashcards instead of reading tarot"
- The Tarot Forums: Galaxy Tarot의 daily draws는 "flat"하다고 평가됨
- 대부분의 숙련 사용자는 하이브리드 접근법 채택: 물리적 덱으로 실제 리딩, 앱은 학습/참조용

**출처**: [The Tarot Forums - Favorite App](https://forum.thetarot.guru/t/your-favorite-tarot-reading-app/339), [BiddyTarot](https://www.biddytarot.com/are-computer-generated-tarot-readings-the-real-deal/), [Sage and Shadow](https://sageandshadow.com/are-tarot-apps-just-as-good-as-a-real-reading/)

#### 1.2 수익화 모델에 대한 반감

- **Galaxy Tarot**: "you can barely do anything on the app without paying." 저널 기능(리딩 저장)이 유료 잠금. 인기 스프레드 대부분 유료
- **Mystic Mondays**: 기존 무료 카드 리뷰 기능이 구독 모델로 전환. 포인트 시스템으로 언락한 기능이 프리미엄 구독 없이 사용 불가로 변경
- **Labyrinthos**: 저널 엔트리에 제한을 둠 (스토리지 비용 이유). 계정 없이는 저널/레슨/리딩 전체 접근 불가
- **Tarot.com**: 카드 의미 정의만 제공하고 $10 청구. 공격적 이메일 마케팅으로 감정 조작
- **Co-Star**: 오랜 기간 무료였다가 유료 구독 모델로 전환하여 장기 사용자 불만

**출처**: [Galaxy Tarot Review](https://mywanderingfool.com/tarot/tarot/galaxy-tarot-app-review/), [JustUseApp - Labyrinthos](https://justuseapp.com/en/app/1155180220/labyrinthos-tarot-reading/reviews), [Trustpilot - Tarot.com](https://www.trustpilot.com/review/tarot.com)

#### 1.3 기술적 버그 및 데이터 손실

Labyrinthos 사용자들이 보고한 구체적 기술 이슈:
- 앱 크래시: "My only downside...is that they tend to crash for me at times"
- 리딩 삭제: 노트가 사라지거나, 한 리딩이 다른 리딩의 사본으로 대체됨
- 타이핑 글리치: 글자 수 제한에 도달하면 나갔다 다시 들어와야 함
- 카드 리셋 버그: 데일리 카드가 저장 후 다른 카드로 변경됨
- 커스텀 스프레드 레이아웃: 설정한 것과 다르게 저장됨

Golden Thread Tarot 사용자들:
- 앱이 앱스토어에서 경고 없이 사라짐
- "All those saved spreads and journal notes were just gone" -- 백업 옵션 없이 데이터 손실
- 데스크톱/웹 동기화 부재

**출처**: [JustUseApp - Labyrinthos Reviews](https://justuseapp.com/en/app/1155180220/labyrinthos-tarot-reading/reviews), [The Tarot Forums - Golden Thread Alternative](https://forum.thetarot.guru/t/golden-thread-tarot-alternative-needed/479)

---

### 2. 영적 연결감 관련 불만 사례

#### 2.1 "코드가 보인다" 문제

The Tarot Forums의 Labyrinthos 리뷰 스레드에서 사용자들은 디지털 리딩이 "illusory"하고 "the intuitive spark"이 부족하다고 표현. 구체적으로:
- "like the cards are just pictures on a screen"
- 알고리즘 뒤의 코드가 보여서 랜덤성이 훼손되는 느낌
- "데이터베이스에서 뽑히는 것을 아는 상태"에서 신비감이 사라짐

#### 2.2 의식적 행위(ritual)의 부재

물리적 타로에서는 셔플이 "의식적 행위(act of ritual and intent)"로 기능한다. 디지털 앱에서는:
- 촉각적 피드백 부재: 카드를 섞고, 느끼고, 고르는 물리적 과정이 없음
- 명상적 일시정지 부재: "the screen-based format removes the 'pause' needed for mindful reflection"
- 일부 앱(Mystic Mondays)은 부드러운 카드 애니메이션과 조절 가능한 리딩 속도로 의식적 느낌을 시도하지만, 대부분은 이를 무시

#### 2.3 해결 시도와 한계

일부 사용자는 디지털 타로도 영적으로 유효하다고 반박: "the real magic of tarot isn't in the cards themselves. It's about the connection between the reader and the universe -- a connection that can happen with digital formats just as much as traditional ones." 그러나 이는 소수 의견이며, 대다수는 디지털 경험이 물리적 경험에 미치지 못한다고 느낀다.

AstroEye의 분석에 따르면, 신규 디지털 타로 앱 디자인 트렌드로 "soft themes, muted haptics, gentle soundscapes -- so every tap becomes ritual, every card a candle"이 제안되지만, 현재 이를 실현한 앱은 거의 없다.

**출처**: [The Tarot Forums - Labyrinthos Reviews](https://forum.thetarot.guru/t/labyrinthos-app-reviews/545), [AstroEye - Tarot's Digital Awakening](https://astroeye.io/whispers-of-tomorrow-tarots-digital-awakening/), [The Tarot Forums - Digital Decks](https://forum.thetarot.guru/t/who-else-uses-digital-tarot-decks/364?page=2)

---

### 3. 커스텀 덱/셔플 수요 증거

#### 3.1 셔플 알고리즘에 대한 불신

사용자들이 가장 민감하게 반응하는 영역. 구체적 사례:

- **가중치 알고리즘 발각 사례**: 한 웰니스 블로거가 TarotFlow를 테스트한 결과, The Hermit이 "Insight" 포지션에 100회 리딩 중 63회 출현 (기대값 33.3% 대비 극단적 편향)
- **비공개 가중치 문제**: 일부 앱이 사용자 키워드에 따라 카드에 가중치를 부여하면서도 이용약관에 공개하지 않음. 사용자는 랜덤하게 뽑힌다고 믿었으나 실제로는 "curated ranking masked as chance"
- **PRNG 투명성 부족**: 대부분의 앱이 셔플 알고리즘을 설명하지 않음. "Fisher-Yates", "cryptographically secure PRNG", "uniform distribution" 같은 기술 용어를 사용하는 앱은 거의 없고, "advanced AI shuffle" 같은 모호한 표현만 사용
- **Labyrinthos 반복 카드**: 한 사용자가 "Three of Swords all the time" 출현을 보고

이는 personality 프로젝트의 CSPRNG + 물리 엔진 기반 셔플이 핵심 차별화 요소가 될 수 있음을 강력히 시사한다.

#### 3.2 커스텀 덱에 대한 수요

- **Deckible**: 800+ 덱을 지원하며, 크리에이터가 자신의 덱을 업로드/판매 가능. 멀티 덱 스프레드 지원. 그러나 타로 리딩 자체보다는 덱 퍼블리싱 플랫폼에 가까움
- **The Alleyman's Tarot**: Kickstarter 최고 판매 타로/오라클 덱 (20k 사전 판매). 100+ 덱의 카드를 믹스한 덱. Facebook 그룹(3.9k 멤버)에서 카드를 우편으로 교환해 자신만의 믹스 덱을 만드는 문화 형성 -- 커스텀 덱 수요의 강력한 증거
- **Taroter**: 물리적 카드를 스캔하는 앱이 존재하지만, Rider-Waite 덱만 인식하는 한계
- **Quora 질문**: "Is there a website or a tarot app that lets you enter what tarot cards were drawn from a real deck into the spread?" -- 물리적 리딩을 디지털로 기록하고 싶은 수요
- **Labyrinthos**: 기존에 long-press로 카드 변경/물리적 카드 입력 기능이 있었으나 제거됨 -- 사용자 불만 야기
- **Golden Thread Alternative 스레드**: 사용자들이 "non-Rider-Waite decks, elemental dignities, and custom positional meanings" 지원을 요청

#### 3.3 커스텀 스프레드 수요

- Golden Thread 사용자: "Limited Spreads -- wanted more spreads to choose from"
- 여러 앱 리뷰에서 커스텀 스프레드 템플릿 요청이 반복적으로 등장
- Deckible이 커스텀 스프레드 생성 기능을 제공하지만, 리딩 경험 자체는 제한적

**출처**: [Deckible](https://cards.deckible.com/tarot-oracle-digital-card-deck-publishing-apps-leap-ahead-with-deckible/), [Taroter - App Store](https://apps.apple.com/us/app/taroter-tarot-cards-scanner/id1597650532), [The Tarot Forums - Labyrinthos](https://forum.thetarot.guru/t/labyrinthos-app-reviews/545), [The Tarot Forums - Golden Thread Alternative](https://forum.thetarot.guru/t/golden-thread-tarot-alternative-needed/479)

---

### 4. 소셜/커뮤니티 기능 기대와 우려

#### 4.1 현재 소셜 기능 현황

**기존 앱의 소셜 기능은 거의 없거나 외부 공유에 국한됨**:
- 대부분의 앱: 소셜 미디어 공유 버튼만 제공 (리딩 결과를 Instagram/Twitter에 공유)
- Tarot Journal: 커뮤니티 섹션 존재하지만 기본적
- Golden Thread: 이메일로 리딩 공유 시 앱 웹사이트 링크만 전달되어 실제 리딩 내용이 전달되지 않는 버그

**Moonlight -- 소셜 타로의 선구적 사례**:
- 최대 6명이 참여할 수 있는 멀티플레이어 타로 방
- 검증된 전문 리더와의 유료 세션 ($50-$300)
- 인디 덱 마켓플레이스
- 2023년 출시, 2025년 iOS 앱 런칭
- 15% 플랫폼 수수료 모델

#### 4.2 커뮤니티 수요의 증거

타로 커뮤니티는 이미 활발한 포럼 생태계를 보유:
- Aeclectic Tarot Forum (100,000+ 토론)
- Tarot, Tea, & Me (리딩 교환 활발)
- The Tarot Forums (forum.thetarot.guru)
- Reddit r/tarot, r/tarotpractice

이 커뮤니티에서 사용자들은 "community spaces to connect with others on the same path"을 앱 내에서 원한다고 표현. 그러나 현재 대부분의 앱은 이를 충족하지 못하고, 별도의 포럼/소셜미디어에 의존.

#### 4.3 프라이버시 우려

- 타로 리딩은 매우 개인적인 내용을 담음 -- 공유 시 프라이버시 보호가 필수
- 타로 리더 윤리 강령: "never disclose information about a reading to anybody else without the person's permission"
- AstroEye 분석: "biometric locks to seal the altar", "local-only encrypted journaling", "ephemeral sessions" 같은 프라이버시 중심 디자인 제안
- 일부 앱은 저널 데이터를 디바이스에만 저장한다고 명시하나, 대부분은 투명하지 않음

**출처**: [Moonlight](https://moonlight.world/), [TechCrunch - Moonlight](https://techcrunch.com/2024/04/16/silicon-valley-prankster-danielle-baskin-launches-moonlight-an-online-tarot-platform/), [Boing Boing - Moonlight](https://boingboing.net/2023/04/24/moonlight-new-tarot-social-platform-is-definitely-worth-a-look.html), [The Tarot Forums](https://forum.thetarot.guru/t/your-favorite-tarot-reading-app/339)

---

### 5. 경쟁앱 분석

#### 5.1 Labyrinthos (4.9/5, 22k+ App Store 리뷰)

| 항목 | 내용 |
|------|------|
| **강점** | 최고의 학습 도구. 게이미파이드 레슨, 퀴즈, 멀티 덱 지원. 비주얼 스토리텔링. Catssandra(AI 고양이) 캐릭터 |
| **약점** | "Too clinical" -- 학습 도구지 리딩 도구가 아님. 디지털 리딩이 "illusory" 느낌. 반복 퀴즈 문제. 기능 제거(long-press 카드 변경). 저널 엔트리 제한 |
| **수익화** | 프리미엄 덱 구매, 계정 필수 |
| **차별화 기회** | 학습이 아닌 "체험"에 집중하면 차별화 가능 |

#### 5.2 Golden Thread Tarot (서비스 중단)

| 항목 | 내용 |
|------|------|
| **강점** | 클린하고 광고 없는 인터페이스. 무료/구매 없음. 초보자 친화적 해석. 감정 패턴 추적 저널링 |
| **약점** | 앱스토어에서 제거됨(Labyrinthos로 통합). 데이터 백업 없이 사용자 데이터 소실. 제한된 레슨/스프레드. 역방향 카드 토글 미지원(가장 많이 요청된 기능) |
| **시사점** | 이 앱의 빈자리를 노릴 수 있음. 사용자들이 대안을 적극 탐색 중 |

#### 5.3 Galaxy Tarot (Android 전용)

| 항목 | 내용 |
|------|------|
| **강점** | 포괄적 카드 설명/상징 깊이. 원소/별자리/행성/차크라별 카드 그룹핑. 유연한 카드 선택(수동/셔플/컷) |
| **약점** | Android 전용. 공격적 페이월(저널/인기 스프레드 유료). Daily draws가 "flat" 느낌. 해석 신뢰도 낮음 |
| **수익화** | 핵심 기능 페이월로 사용자 반감 큼 |

#### 5.4 Mystic Mondays

| 항목 | 내용 |
|------|------|
| **강점** | 밝고 현대적 비주얼 디자인. 부드러운 카드 애니메이션. 라이프스타일 카테고리별 저널링. 패턴 인사이트 데이터 |
| **약점** | 무료에서 구독 모델로 전환하면서 기존 사용자 반발. 포인트 시스템 제거. 광고 시청 요구. 카드 정보 앱에서 제거 |
| **시사점** | 비주얼 디자인의 중요성 확인. 수익화 모델 전환의 위험 |

#### 5.5 Co-Star (점성술 중심, 타로 인접)

| 항목 | 내용 |
|------|------|
| **강점** | 소셜 기능(친구 추가/비교). 개인화된 일일 메시지. 대규모 사용자 베이스 |
| **약점** | 사용자 "trolling" 인정(부정적/불안 유발 메시지). 점성술팀 부재. Porphyry System 사용(점성술사 5%만 사용). AI가 빈칸만 채우는 일반적 콘텐츠. 유료 구독 전환으로 장기 사용자 불만 |
| **시사점** | 소셜 기능의 중독성 입증. 그러나 부정적 톤/조작적 메시지는 반면교사 |

#### 5.6 Deckible

| 항목 | 내용 |
|------|------|
| **강점** | 800+ 덱. 크리에이터 업로드/판매 마켓플레이스. 멀티 덱 스프레드. 오디오/비디오 지원. 커스텀 스프레드. 저널링 |
| **약점** | 덱 퍼블리싱 플랫폼 성격이 강해 리딩 경험 자체는 부차적. 타로 전문이 아닌 범용 카드 덱 앱 |
| **시사점** | 커스텀 덱 생태계의 수요 증명. 그러나 "영적 경험"보다는 "콘텐츠 플랫폼"에 가까움 |

#### 5.7 Moonlight

| 항목 | 내용 |
|------|------|
| **강점** | 유일한 소셜 타로 플랫폼. 멀티플레이어 방(최대 6명). 인디 덱 큐레이션. 검증된 전문 리더 연결 |
| **약점** | 주로 웹 기반(iOS 앱 2025 런칭). 소규모 팀. 리딩 자체보다 세션 관리 도구에 가까움 |
| **시사점** | 소셜 타로의 시장 가능성 검증. 15% 수수료 모델 참고 |

---

## Key Findings

### 페인포인트 우선순위 (영향도/빈도 기준)

1. **영적 연결감 부족 (Critical)** -- 디지털 타로의 근본적 한계. "랜덤 넘버 제너레이터" 느낌이 가장 보편적 불만. 물리적 셔플의 촉각적/의식적 경험을 재현하는 앱이 없음
2. **셔플 알고리즘 불투명성 (High)** -- 가중치 알고리즘 의심, 반복 카드 출현, 기술적 투명성 부재. 사용자가 PRNG 방식을 확인할 수 없음
3. **공격적 수익화 (High)** -- 저널/스프레드 등 핵심 기능 페이월, 무료→구독 전환 시 기존 사용자 반발, 감정 조작적 마케팅
4. **AI 해석의 비개인성 (Medium)** -- "generic card definitions" vs 실제 상황 맞춤 해석. 인간 리더 대비 감정적 뉘앙스와 공감적 연결 부재
5. **커스텀 덱/스프레드 부재 (Medium)** -- 자신의 물리적 덱을 디지털로 사용하고 싶은 수요. 커스텀 스프레드 템플릿 요청. Alleyman's Tarot 성공이 수요 증명
6. **소셜/커뮤니티 부재 (Medium)** -- 앱 내 커뮤니티 기능이 거의 없음. 외부 포럼에 의존. Moonlight가 유일한 시도
7. **데이터 안전성/이식성 (Low-Medium)** -- 앱 서비스 종료 시 데이터 소실. 백업/내보내기 기능 부재. 크로스 플랫폼 동기화 미지원
8. **접근성 (Low-Medium)** -- 스크린 리더용 plain text 설명 부재. 시각장애 사용자를 위한 고려 부족

### PRD와의 정합성

personality 프로젝트 PRD의 핵심 기능이 실제 사용자 페인포인트와 정확히 대응함:

| PRD 기능 | 대응하는 페인포인트 | 증거 강도 |
|----------|-------------------|----------|
| 커스텀 셔플(물리 엔진, CSPRNG, 센서) | 영적 연결감 부족 + 셔플 불신 | **강함** -- TarotFlow 편향 사례, 반복 카드 보고, "코드가 보인다" 불만 |
| 커스텀 덱 등록(JSON Schema) | 커스텀 덱 부재 | **강함** -- Alleyman's Tarot 20k 판매, Deckible 800+ 덱 생태계, 물리→디지털 브릿지 수요 |
| 소셜/바운티 시스템 | 소셜/커뮤니티 부재 | **중간** -- Moonlight가 소셜 타로 가능성 검증, 기존 포럼 생태계 활발, 그러나 프라이버시 우려도 존재 |
| 4가지 페르소나 기반 설계 | 다양한 사용자 유형의 상이한 니즈 | **강함** -- 전통적 리더(영적 연결감), 크리에이터(커스텀 덱), 하이브리드(물리+디지털), 소셜 탐구자(커뮤니티) |

---

## Recommendations

### personality 타로 앱 설계를 위한 시사점

1. **셔플 투명성을 최우선 차별화로**: CSPRNG 기반 셔플 알고리즘을 공개하고, 사용자가 검증 가능하게 만들 것. "Fisher-Yates + CSPRNG" 등 기술 용어를 사용자 친화적으로 설명하는 UI 필요. 이는 기존 앱 중 어떤 것도 하지 않는 영역

2. **물리적 의식(ritual) 경험의 디지털 재현**: 단순 "shuffle 버튼"이 아닌, 센서(가속도계/자이로스코프) 기반 물리 셔플, 햅틱 피드백, 사운드스케이프, 조절 가능한 리딩 속도를 통해 의식적 경험 구현. AstroEye의 "every tap becomes ritual" 디자인 철학 참고

3. **커스텀 덱 생태계 구축**: JSON Schema 기반 덱 등록은 강력한 차별화. 다만 Deckible의 교훈 참고 -- "콘텐츠 플랫폼"이 아닌 "리딩 경험"에 집중할 것. 물리 카드 스캔 + 디지털 기록 브릿지 기능 고려

4. **소셜 기능은 프라이버시 퍼스트로**: 리딩 공유 시 기본값은 비공개. 선택적 공유(익명/실명). 로컬 암호화 저널링. Moonlight의 멀티플레이어 방 개념 참고하되, Co-Star의 부정적 사례(trolling, 조작적 메시지) 회피

5. **수익화 모델 주의**: 저널/기본 스프레드 등 핵심 기능은 무료로 유지. Galaxy Tarot, Mystic Mondays의 페이월 반발 사례를 반면교사로. 커스텀 덱 마켓플레이스/프리미엄 덱/바운티 시스템으로 수익화

6. **하이브리드 리더 페르소나 적극 지원**: 물리적 덱으로 리딩하고 결과를 앱에 기록하는 워크플로우. Labyrinthos에서 제거된 long-press 카드 입력 기능을 부활/개선. 물리↔디지털 브릿지가 숙련 사용자의 핵심 니즈

7. **접근성 내장**: Golden Thread Alternative 스레드에서 명시적으로 요청된 "plain text descriptions for screen readers". 시각 장애 사용자를 위한 WCAG 접근성 기본 탑재

---

## References

### 커뮤니티 포럼
- [The Tarot Forums - Your Favorite Tarot Reading App?](https://forum.thetarot.guru/t/your-favorite-tarot-reading-app/339)
- [The Tarot Forums - Labyrinthos App Reviews](https://forum.thetarot.guru/t/labyrinthos-app-reviews/545)
- [The Tarot Forums - Golden Thread Tarot Alternative Needed](https://forum.thetarot.guru/t/golden-thread-tarot-alternative-needed/479)
- [The Tarot Forums - Who Else Uses Digital Tarot Decks?](https://forum.thetarot.guru/t/who-else-uses-digital-tarot-decks/364?page=2)

### 앱 리뷰 및 비교
- [TarotLingo - Best Tarot Apps 2026](https://tarotlingo.com/best-tarot-apps)
- [JustUseApp - Labyrinthos Reviews](https://justuseapp.com/en/app/1155180220/labyrinthos-tarot-reading/reviews)
- [Trustpilot - Tarot.com Reviews](https://www.trustpilot.com/review/tarot.com)
- [My Wandering Fool - Galaxy Tarot Review](https://mywanderingfool.com/tarot/tarot/galaxy-tarot-app-review/)
- [Sage and Shadow - Are Tarot Apps Just as Good?](https://sageandshadow.com/are-tarot-apps-just-as-good-as-a-real-reading/)
- [JustUseApp - Co-Star Reviews](https://justuseapp.com/en/app/1264782561/co-star-personalized-astrology/reviews)

### 셔플 알고리즘 및 기술
- [Spiral Sea Tarot - Shuffling as Ritual](https://www.spiralseatarot.com/blog/2016/4/16/shuffling)
- [AstroEye - Tarot's Digital Awakening](https://astroeye.io/whispers-of-tomorrow-tarots-digital-awakening/)

### 소셜/커뮤니티
- [TechCrunch - Moonlight Launch](https://techcrunch.com/2024/04/16/silicon-valley-prankster-danielle-baskin-launches-moonlight-an-online-tarot-platform/)
- [Boing Boing - Moonlight Social Tarot](https://boingboing.net/2023/04/24/moonlight-new-tarot-social-platform-is-definitely-worth-a-look.html)
- [Deckible - Digital Deck Publishing](https://cards.deckible.com/tarot-oracle-digital-card-deck-publishing-apps-leap-ahead-with-deckible/)
- [Tarot Journal - Share Readings](https://tarotjournal.com/record-tarot-readings/share-tarot-readings/)

### Co-Star 비판
- [Medium - Co-Star Trolls Users](https://medium.com/illumination/i-learned-the-co-star-app-trolls-their-users-two-days-after-i-downloaded-the-app-d2f8d836fb74)
- [Unpublished Zine - Co-Star Criticism](https://www.unpublishedzine.com/astrology/costar-the-astrology-app-everyone-has-that-no-one-should-be-using)
- [Valley Magazine - Delete Co-Star](https://www.valleymagazinepsu.com/its-about-time-to-delete-co-star/)

### 기타
- [Liz Worth - ChatGPT Tarot Scam?](https://www.lizworth.com/blog/is-chatgpt-the-new-tarot-scam)
- [EIN Presswire - Online Tarot Platform Failures](https://www.einpresswire.com/article/880476939/why-most-online-tarot-platforms-fail-to-protect-users)
- [MysteryLores - Free Tarot Scam Analysis](https://mysterylores.com/news/free-tarot-readings-or-paid-offers/)
- [The Haptic Tarot - Kickstarter](https://www.kickstarter.com/projects/pageofcups/the-haptic-tarot)
