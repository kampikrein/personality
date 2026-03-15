---
id: "005"
title: "UI/UX 전문가 비평 — 사용자경험·감정흐름·접근성 분석"
category: agent
status: archived
created: 2026-03-13
summary: >
  personality 프로젝트의 프론트엔드 전체를 UI/UX 관점에서 분석했다.
  감정 흐름 설계와 Pretendard 폰트·커스텀 컬러 시스템은 훌륭하나,
  접근성(ARIA·색상 대비·키보드 포커스) 전반과 동의 페이지·검사 중 사용자 맥락 부재가 핵심 개선 과제다.
keywords: [agent-report, uiux, user-experience, accessibility, emotion-flow, mobile-first]
modules: [views, assets, layouts]
---

# UI/UX 전문가 비평 — 사용자경험·감정흐름·접근성 분석

## Progress
### Completed
- [x] 사용자 흐름 전체 분석 (동의→검사→결과)
- [x] 결과 페이지 UX 분석 (type_hero, spectrum, insights)
- [x] 감정 흐름 설계 평가
- [x] 모바일 퍼스트·반응형 디자인 점검
- [x] 접근성(WCAG 2.1) 점검
- [x] Tailwind CSS·디자인 시스템 일관성
- [x] Hotwire/Turbo/Stimulus 인터랙션 분석
- [x] 한국 시장 UX 적합성
### Remaining
- (없음)
### Current Status
분석 완료.

---

## Summary

전체적으로 Pretendard 폰트·온기 있는 컬러 팔레트·Turbo Frame 기반 즉각 응답 등 MZ 감성에 맞는 기초가 잘 갖춰져 있다. 결과 페이지의 순차 등장 애니메이션은 `기대→집중→흥분→성찰` 감정 흐름을 의도한 것으로 읽히며 방향성은 옳다. 그러나 (1) 접근성(ARIA 레이블 전무, 색상 대비 미검증, 라디오 버튼 sr-only로 시각적 포커스 없음), (2) 동의 페이지의 정보 빈곤, (3) 검사 중 네비게이션 부재, (4) spectrum 바의 의미 설명 부재, (5) 인사이트 탭의 패널 전환 애니메이션 없음이 주요 문제다.

---

## Details

### 1. 전체 사용자 흐름 (동의 → 검사 → 결과)

#### 1-1. 랜딩 / 시작 화면 (`sessions/new.html.erb`)

**현재 상태**
- "나를 이해하는 새로운 방법" 헤드라인 + gradient 텍스트, 4개 도메인 아이콘, 시작 CTA 버튼으로 구성.
- `min-h-[80vh]`로 세로 중앙 정렬. "회원가입 없이 바로 시작" 보조 문구 있음.

**UX 평가**
- 좋음: 단일 CTA, 충분한 여백, Pretendard 폰트 가독성.
- 문제: 4개 도메인 아이콘(에너지 흐름 / 판단 렌즈 / 연결 방식 / 충전 패턴)은 의미를 모르면 그냥 장식으로 보인다. 이 아이콘들이 검사 내용 미리보기임을 인지하는 사용자는 극소수.
- 문제: `form_with url: session_path, method: :post`로 구현된 버튼은 `<button>` 역할이지만 시각적으로 버튼이며 문제는 없음. 그러나 `active:scale-[0.98]`의 피드백은 0.02 스케일 차이라 거의 체감 안 됨.
- 문제: 폴드 아래에 아무 콘텐츠가 없어 스크롤 유도가 없다. 서비스 신뢰를 위한 소셜 프루프(예: "XX만 명이 완료") 완전히 부재.

**개선 건의**
- 4개 도메인 아이콘에 마이크로카피 한 줄 추가: "당신의 에너지는 어디서 오나요?" 식으로.
- `active:scale-[0.97]` + `active:shadow-inner`로 클릭 피드백 강화.
- 신뢰 지표 1-2개 추가(예: "약 5분 소요 · 데이터 최소 수집 · 저장 선택 가능").

#### 1-2. 동의 페이지 (`consents/new.html.erb`)

**현재 상태**
- h1 "데이터 처리 동의" + 체크박스 1개 + 제출 버튼 전부.
- 설명 텍스트: "검사 응답 데이터를 처리하여 성격 프로필을 생성합니다." (1줄).

**UX 평가**
- 나쁨: 동의 페이지가 사용자에게 "이 서비스가 안전한가?"를 확인시켜줄 유일한 기회인데, 정보가 극도로 빈약하다. 수집 데이터 목록, 보유 기간, 사용 목적이 없다.
- 나쁨: 체크박스 레이블에 `for` 속성이 없고(묵시적 연결만), `required` 속성이 있지만 브라우저 기본 검증 메시지가 한국어가 아닐 수 있다.
- 나쁨: 랜딩에서 동의로 넘어오는 전환이 즉각적이라 사용자가 "내가 무엇에 동의하는 것인가"를 생각할 여지가 없다.
- 나쁨: 페이지 타이틀이 "동의 관리"인데 사용자는 무언가를 "관리"하러 온 것이 아니다. "시작 전 잠깐요" 같은 친근한 문구가 어울린다.

**개선 건의**
- 수집 항목, 목적, 보유 기간을 3줄 요약으로 추가(예: 삭제 요청 페이지의 "삭제되는 데이터" 블록 스타일 참조).
- 타이틀을 "시작 전 잠깐 확인해주세요"로 변경.
- 전문 개인정보처리방침 링크(별도 모달 또는 외부 링크) 제공.
- 체크박스에 명시적 `id`/`for` 연결.

#### 1-3. 검사 화면 (`assessment_questions/_question.html.erb`)

**현재 상태**
- Turbo Frame `current_question`으로 단일 페이지처럼 동작.
- 프로그레스 바 + 진행 숫자 + 도메인 표시 + 질문 텍스트 + 5점 Likert + 건너뛰기.
- 라디오 버튼 선택 즉시 200ms 딜레이 후 자동 제출.

**UX 평가**
- 좋음: 도메인별 색상 변화는 시각적 다양성을 준다.
- 좋음: 자동 제출은 터치 UX에서 버튼 탭 한 번으로 진행되어 빠름.
- 문제: 라디오 버튼이 `sr-only`로 숨겨져 있어 키보드 포커스 링이 전혀 없다. 키보드 사용자는 어떤 항목이 포커스됐는지 알 수 없다.
- 문제: 자동 제출 딜레이(200ms)와 Turbo Frame 전환 사이 로딩 인디케이터가 없다. 응답이 느린 환경에서 사용자가 이미 제출됐는지 모른다.
- 문제: `domain_colors`에 `"lavender"` 색이 포함되어 있으나 Tailwind config에는 `lavender`가 테마 컬러로 등록되어 있지 않다(→ JIT purge로 해당 클래스가 생성되지 않을 위험).
- 문제: 진행률이 `7 / 20 — 35%`처럼 숫자와 퍼센트 둘 다 나오는데 중복이다.
- 문제: "이 질문 건너뛰기" 링크는 `text-warm-gray/60`으로 대비가 매우 낮다. 시각장애인 및 시력 약한 사용자가 인식 불가.
- 문제: 뒤로 가기 기능 없음. 실수로 잘못 선택해도 수정 불가.

**개선 건의**
- 라디오 `sr-only` 제거 후 `focus-within:ring` 스타일을 label에 추가하거나, 커스텀 포커스 링 구현.
- Turbo Frame 요청 시 Turbo `data-turbo-submits-with` 속성 또는 간단한 로딩 오버레이 추가.
- `lavender` 색을 Tailwind theme에 명시적으로 등록할 것. (현재 `application.css`에 누락됨)
- 진행 표시는 `7 / 20` 하나만으로 충분. 퍼센트는 프로그레스 바로 시각 표현.
- 건너뛰기 버튼 대비 `text-warm-gray` 이상으로 올리고, 오른쪽 정렬로 분리해 실수 탭 방지.
- 이전 질문으로 돌아가기 버튼 추가(뒤로 가기 아이콘 + 숨김 처리된 이전 데이터 복원).

---

### 2. 결과 페이지 (`results/show.html.erb`) — 정보 구조 및 감정 흐름

**현재 상태**
섹션 순서: type_hero → spectrum → 강점/주의 → 추천 행동 → 인사이트 탭 → trust_notice → 액션 버튼

**감정 흐름 평가 (기대→집중→흥분→성찰)**

| 단계 | 의도된 감정 | 현재 UX | 평가 |
|------|------------|---------|------|
| type_hero | 흥분 (내가 뭔지 알게 됨!) | 순차 등장 애니메이션으로 기대 고조 | ✅ 양호 |
| spectrum | 집중 (나의 점수 확인) | 바 애니메이션으로 시각적 흥미 | ✅ 양호 |
| 강점/주의 | 흥분→성찰 | 2컬럼 그리드, 색 구분 | △ 보통 |
| 추천 행동 | 성찰 | 리스트 나열 | △ 약함 |
| 인사이트 탭 | 깊은 성찰 | 탭 UI, 건조한 불릿 | △ 약함 |
| trust_notice | 신뢰 재확인 | 중립적 문구 | △ 위치 부적절 |

**구조적 문제**
- trust_notice가 결과 콘텐츠 바닥에 위치한다. 이 면책 고지는 신뢰를 주는 것이 아니라 흥분을 냉각시킨다. 사용자의 감정 여정 마지막에 "이건 진단이 아닙니다"가 나오면 성찰 모드가 깨진다.
- "다시 검사하기"와 "삭제 요청"이 같은 가로 줄에 놓여 있어 시각적 위계가 없다. 삭제 요청은 완전히 숨겨진 링크 수준이어야 한다.
- 결과 페이지에 공유(SNS) 기능이 없다. 한국 MZ의 결과 공유 욕구를 전혀 충족하지 못함.
- `space-y-12`의 섹션 간격이 모바일에서 지나치게 넓다. 스크롤이 길어져 "아직 더 있나" 의구심 유발.

**개선 건의**
- trust_notice를 type_hero 바로 아래, 또는 맨 위 우측 정보 아이콘으로 옮기거나 접이식으로 처리.
- 공유 버튼 추가: "내 유형 공유하기" (링크 복사 / 이미지 저장 / 카카오톡 공유).
- `space-y-12` → `space-y-8 sm:space-y-12`로 모바일 간격 축소.
- 하단 CTA를 "결과 저장하기 (계정 만들기)" 1개 주요 버튼으로 교체하고, 재검사·삭제는 텍스트 링크로 격하.

---

### 3. 결과 파셜 개별 분석

#### 3-1. `_type_hero.html.erb`

**현재 상태**
- 4글자 타입 코드를 색상별 타일로 순차 등장.
- CSS `@keyframes revealLetter` + `@keyframes fadeIn`을 파셜 내 `<style>` 태그에 인라인 정의.

**UX 평가**
- 좋음: 순차 등장 딜레이(i * 0.15s)는 드라마틱한 공개 효과를 준다.
- 나쁨: `<style>` 태그를 `<body>` 내 파셜에 직접 삽입하면 CSS를 중복 파싱한다. Turbo 캐시 재방문 시 `<style>` 태그가 중복될 수 있다.
- 나쁨: `opacity-0`으로 시작하는 요소들이 JS 없이(예: 저사양 기기, 느린 네트워크) 렌더링될 때 내용이 완전히 보이지 않는다. `prefers-reduced-motion` 미디어 쿼리 미지원.
- 나쁨: `data-type-reveal-target="letter"` 등이 있지만 `type_reveal_controller.js`의 `connect()`는 아무 동작도 하지 않는다. CSS 애니메이션만으로 동작하지만, 컨트롤러가 접근성 상태(aria-live)를 관리하지 않는다.
- 나쁨: h1이 `character_name_ko`인데 `lang="ko"` 문서 레벨에서 이미 처리됨. 하지만 영문명 `character_name_en`에 `lang="en"` 속성 없음.

**개선 건의**
- `<style>` 태그를 `app/assets/tailwind/application.css`로 이동.
- `@media (prefers-reduced-motion: reduce) { * { animation: none !important; opacity: 1 !important; } }` 추가.
- `type_reveal_controller.js`에 `aria-live="polite"` 설정 로직 추가: 타입 코드 등장 후 "당신의 유형은 INFJ입니다"를 스크린리더에 알림.
- `character_name_en`에 `lang="en"` 추가.

#### 3-2. `_spectrum.html.erb`

**현재 상태**
- 4개 도메인 바, 좌우 레이블, 중앙선, 색상 막대로 구성.
- JS에서 `connect()` 시 1600ms + index*200ms 딜레이로 막대 채우기.

**UX 평가**
- 좋음: 중앙선(`absolute left-1/2`)이 양극단 기준점을 명확히 제시.
- 나쁨: 스펙트럼 바가 항상 왼쪽(0%)에서 채워진다. 예를 들어 score가 30이면 막대가 왼쪽부터 30%를 채우는데, 이것이 "내향 30%"인지 "외향 30%"인지 레이블만으로 직관적으로 이해하기 어렵다. 중앙을 기준으로 방향성이 있는 바가 더 직관적이다.
- 나쁨: 막대 색상만 있고 수치 레이블(`score.round %`)이 중앙 위에 있어, 이 숫자가 어느 방향의 백분율인지 불분명하다.
- 나쁨: `opacity-0` + CSS `fadeIn` 동일 문제: `prefers-reduced-motion` 미지원.
- 나쁨: 색상 정보만으로 도메인을 구분하는 구조는 색맹 사용자에게 의미 없음.
- 나쁨: `lavender` 컬러가 `@theme`에 누락되어 있어 `bg-lavender` 클래스가 Tailwind v4 purge에서 제거될 가능성.

**개선 건의**
- 막대 방향: score > 50이면 오른쪽(high label 방향)으로, score < 50이면 왼쪽으로 확장하는 양방향 바 구현.
- 수치 표시를 "외향 쪽 67%" 같은 자연어로 변경하거나, 아이콘+텍스트 결합으로 직관적으로.
- `lavender`를 `@theme`에 추가: `--color-lavender: #D4C5E2;` (이미 CSS에 정의됨, 확인 필요).
- 각 도메인에 도메인명 아이콘(텍스트 기호) 추가하여 색맹 대응.

#### 3-3. `_insight_card.html.erb`

**현재 상태**
- 제안 불릿 리스트 + `<details>/<summary>`로 설명 접기/펼치기.
- `bg-white/50`으로 약한 흰색 배경, `border-light-gray` 테두리.

**UX 평가**
- 좋음: `<details>` 사용은 콘텐츠 밀도 조절에 효과적.
- 나쁨: `<details>` 열림/닫힘에 애니메이션이 없어 콘텐츠가 갑자기 나타남. 토스 스타일의 부드러운 확장을 기대하는 MZ 사용자에게 어색.
- 나쁨: 탭 전환 시 패널이 `hidden` 토글로만 처리되어 전환 애니메이션 없음.
- 나쁨: 불릿 아이콘이 `w-1.5 h-1.5 rounded-full bg-lavender`인데, 이 점이 너무 작아(6px) 시각 장애인뿐 아니라 일반 사용자도 거의 인지하지 못함.
- 나쁨: 인사이트 카드 안에 타이틀이 없다. 어떤 맥락(협업/갈등/학습...)의 인사이트인지 탭에서 확인해야 하며, 카드 자체는 익명적.

**개선 건의**
- `<details>` 패널에 CSS `max-height` transition 또는 Stimulus animate controller로 부드러운 열림 구현.
- 탭 전환에 `opacity`와 `translate-y` 트랜지션 추가 (`tabs_controller.js`에서 클래스 조작).
- 인사이트 카드 상단에 맥락 레이블 배지(예: "💼 협업 인사이트") 추가.
- 불릿 `w-1.5 h-1.5` → `w-2 h-2` 또는 아이콘 문자로 교체.

#### 3-4. `_trust_notice.html.erb`

**현재 상태**
- `bg-sand/20` 박스, 정보 아이콘, 2줄 법적 면책 문구.

**UX 평가**
- 나쁨: 감정 고조 후 마지막에 면책 문구가 나오면 성찰 분위기를 법적 텍스트로 마무리하게 됨. 사용자에게 "이 서비스는 믿을 수 없다"는 느낌을 줄 수 있음.
- 나쁨: `bg-sand/20 border-sand/40` 조합은 배경과 테두리 대비가 너무 낮아 WCAG 1.4.11(Non-text Contrast 3:1) 위반 가능.
- 좋음: 내용 자체는 MBTI®와 다름을 명확히 밝혀 법적 리스크를 최소화한다.

**개선 건의**
- trust_notice 위치를 type_hero 직후 또는 인라인 info 아이콘 툴팁으로 이동.
- 결과 페이지 마지막은 긍정적 CTA("다음 단계로 성장하기")로 끝내야 함.
- 테두리 대비 증가: `border-sand/40` → `border-sand/70` 또는 `border-warm-gray/20`.

---

### 4. 모바일 퍼스트·반응형 디자인

**현재 상태**
- `max-w-2xl mx-auto`가 전체 레이아웃 컨테이너.
- `sm:` 브레이크포인트 사용: type_hero 타일(`sm:w-20 sm:h-20`), 타이포그래피(`sm:text-2xl`, `sm:text-3xl`).
- 결과 강점/주의 그리드: `grid sm:grid-cols-2`.

**평가**
- 좋음: `max-w-2xl`(672px)은 모바일에서 전체 너비, 데스크탑에서 중앙 컬럼으로 작동해 모바일 퍼스트 의도가 명확.
- 좋음: 검사 라이커트 옵션 `p-4 rounded-xl`은 44px 이상 터치 타겟 충족.
- 문제: 인사이트 탭 버튼 `px-4 py-2`는 약 32px 높이로 iOS 권장 터치 타겟(44px) 미달.
- 문제: 결과 페이지 하단 CTA `flex-col sm:flex-row`는 올바르나, 모바일에서 "다시 검사하기"와 "삭제 요청"이 세로로 나란히 같은 크기로 나와 위계 혼동.
- 문제: 진행 숫자 `text-sm`이 모바일 소형 화면(320px)에서 `px-4` 패딩과 `flex justify-between`으로 겹칠 수 있음.
- 문제: `md:` 브레이크포인트가 거의 사용되지 않음. 태블릿(768px~1024px) 레이아웃이 모바일 그대로.

**개선 건의**
- 인사이트 탭 버튼 최소 높이 `min-h-[44px]` 지정.
- 삭제 요청 링크를 CTA 영역에서 분리해 footer 영역 또는 최소화.
- `md:` 브레이크포인트로 태블릿 중간 크기 레이아웃 추가(예: 인사이트 탭 2열).

---

### 5. 접근성 (WCAG 2.1)

**전반적 평가: 미흡**

#### 5-1. 색상 대비

| 요소 | 전경색 | 배경색 | 추정 대비비 | 기준 | 판정 |
|------|--------|--------|------------|------|------|
| 본문 텍스트 | charcoal `#2D2D2D` | cream `#FFF8F0` | ~16:1 | 4.5:1 | ✅ 통과 |
| 보조 텍스트 | warm-gray `#6B6560` | cream `#FFF8F0` | ~5.5:1 | 4.5:1 | ✅ 통과 |
| 희미한 텍스트 | warm-gray/60 (투명도 60%) | cream | ~3.3:1 | 4.5:1 | ❌ 실패 |
| 건너뛰기 버튼 | warm-gray/60 | cream | ~3.3:1 | 4.5:1 | ❌ 실패 |
| 삭제 링크 | warm-gray/60 | cream | ~3.3:1 | 4.5:1 | ❌ 실패 |
| trust_notice 테두리 | sand/40 | sand/20 배경 | < 3:1 | 3:1 (non-text) | ❌ 실패 |

#### 5-2. ARIA 및 시맨틱

- `<html lang="ko">` ✅ — 언어 선언 있음.
- 결과 페이지 `<h1>`: character_name_ko ✅.
- 스펙트럼 바: 막대가 `<div>`로만 구성, `role="progressbar"` / `aria-valuenow` / `aria-valuemin` / `aria-valuemax` / `aria-label` 없음 ❌.
- 라이커트 폼: `role="radiogroup"` / `aria-labelledby` 미지정 ❌.
- 인사이트 탭: `role="tablist"` / `role="tab"` / `role="tabpanel"` / `aria-selected` / `aria-controls` 없음 ❌. 탭 패턴의 ARIA 명세를 전혀 구현하지 않음.
- 플래시 메시지: `role="alert"` / `aria-live="polite"` 없음 ❌.
- 건너뛰기 링크(Skip to main content): 완전히 부재 ❌.
- SVG 아이콘(trust_notice, insight_card): `aria-hidden="true"` 없음. 스크린리더가 path 데이터를 읽으려 시도함 ❌.

#### 5-3. 키보드 네비게이션

- 라이커트 라디오 버튼 `sr-only`: 키보드 포커스 시 시각적 표시 없음 ❌.
- 인사이트 탭 버튼: 키보드 Tab/Arrow 키 네비게이션 미구현 (WAI-ARIA Tabs 패턴: ←/→ 화살표 키 이동) ❌.
- `<details>/<summary>`: 브라우저 기본 키보드 동작 지원 ✅.
- 포커스 순서: `tabindex` 명시적 설정 없으나 DOM 순서가 논리적 ✅.

**개선 건의 (우선순위 순)**
1. 스펙트럼 바에 `role="meter"` / `aria-valuenow` / `aria-label` 추가 (예: `aria-label="외향 지수: 67%"`).
2. 인사이트 탭에 WAI-ARIA Tabs 패턴 구현: `role="tablist"`, `role="tab"`, `aria-selected`, `aria-controls`, `role="tabpanel"`, `aria-labelledby`, 키보드 ←/→ 이동.
3. `text-warm-gray/60` → `text-warm-gray` 이상으로 전환해 대비 확보.
4. 플래시 메시지에 `role="alert"` 추가.
5. SVG 아이콘 전체에 `aria-hidden="true"` 추가.
6. `<body>` 첫 자식에 Skip to main 링크 추가: `<a href="#main" class="sr-only focus:not-sr-only">본문으로 건너뛰기</a>`.
7. 라이커트 라디오 label에 `focus-within:ring-2 focus-within:ring-charcoal` 추가.

---

### 6. Tailwind CSS 디자인 시스템 일관성

**현재 상태**
- `@theme`에 9개 커스텀 컬러 정의 (cream, blush, sage, sky, lavender, sand, charcoal, warm-gray, light-gray).
- Pretendard Variable 폰트 CDN 로드.

**평가**
- 좋음: 컬러 팔레트 자체는 일관성 있고 온기 있는 파스텔 계열로 MZ 감성 적합.
- 문제: `lavender`가 `@theme`에 명시되어 있으나 (`--color-lavender: #D4C5E2`), `_question.html.erb`의 `domain_colors`에서 `"lavender"`를 동적으로 보간한다. Tailwind v4는 JIT purge 시 `bg-lavender`, `hover:border-lavender/50`, `has-[:checked]:border-lavender` 등의 동적 클래스를 감지하지 못해 빌드에서 누락될 수 있다.
- 문제: `bg-white/50` (`_insight_card.html.erb`)이 컬러 시스템 외 원색을 사용. `bg-cream`을 써야 일관성 유지.
- 문제: 라운드 반경이 `rounded-xl` / `rounded-2xl` / `rounded-full`로 혼재하지만 섹션별로 일관되지 않음.
- 문제: `<style>` 인라인 태그(type_hero)에 정의된 keyframe이 전역 CSS 파일에 없어 유지보수 분산.
- 문제: `text-xs`로 정의된 보조 텍스트가 너무 많음. 한국어는 영어보다 획이 복잡해 같은 크기에서 더 작게 보임. 최소 `text-sm` 권장.

**개선 건의**
- 동적 Tailwind 클래스(`bg-${color}`, `border-${color}`)를 safelist에 등록하거나, 가능한 모든 조합을 미리 렌더링하는 hidden 블록(safelist 패턴) 추가.
- `bg-white/50` → `bg-cream/80`으로 교체.
- keyframe 애니메이션을 `application.css`로 이동.
- 한국어 텍스트 최소 폰트 크기 `text-sm` (14px) 적용, `text-xs`는 caption 용도로만 제한.

---

### 7. Hotwire/Turbo/Stimulus 인터랙션 분석

**현재 상태**
- Turbo Frame: `current_question` 프레임으로 검사 진행 SPA화.
- Stimulus controllers: likert, countdown, progress, spectrum_bar, type_reveal, questionnaire, autosave, tabs.

**평가**
- 좋음: Turbo Frame으로 검사 단계가 전체 페이지 리로드 없이 진행됨. 성능상 탁월한 선택.
- 좋음: `countdown_controller.js`로 응답 시간 측정이 서버로 전송됨.
- 문제: `likert_controller.js`의 `select()` 메서드가 비어 있음. CSS `:has(:checked)`로 처리되지만, 선택 즉시 JS 피드백(진동, 오디오 피드백, 로딩 상태)이 없음.
- 문제: 제출 후 Turbo Frame 응답 전 로딩 상태 없음. 서버 응답 지연 시 사용자는 아무 피드백 없이 대기.
- 문제: `type_reveal_controller.js`의 `connect()`가 완전히 빔. 컨트롤러 존재 이유가 없다. CSS 애니메이션만으로 동작 중.
- 문제: `questionnaire_controller.js`의 `restoreProgress()`가 빔. autosave_controller과의 연계가 설계만 있고 미구현.
- 문제: `tabs_controller.js`의 클래스 교체 로직 `tab.className.replace(/bg-\S+\s+text-\S+/, "")`이 취약함. 두 클래스 사이에 다른 클래스가 있으면 교체 실패. `classList.add/remove`로 개별 처리해야 함.
- 문제: `autosave_controller.js`가 sessionStorage에 저장하지만, 실제로 `save(data)`를 호출하는 곳이 없음(코드베이스 내 미연결).

**개선 건의**
- Turbo Frame 로딩 상태: `document.addEventListener("turbo:frame-load", ...)` 또는 `turbo:before-fetch-request`에서 스피너 표시/숨김 처리.
- `likert_controller.js`에 선택 확인 피드백 추가: `this.optionTargets.forEach(o => o.classList.add("pointer-events-none"))` (중복 제출 방지).
- `tabs_controller.js`의 정규식 교체 → `activeClasses`/`inactiveClasses` 배열로 개별 `toggle`.
- `type_reveal_controller.js`에 `aria-live` 알림 및 reduced-motion 처리 로직 추가 (아니면 컨트롤러 제거).
- `autosave_controller.js`를 실제 폼 이벤트에 연결하거나 제거.

---

### 8. 한국 시장 UX 적합성

**비교 기준: 카카오·토스 수준**

| 항목 | 현재 상태 | 카카오/토스 수준 | 평가 |
|------|----------|----------------|------|
| 폰트 | Pretendard Variable (CDN) | Pretendard (자체 호스팅) | ✅ 방향 옳음, 성능 개선 여지 |
| 컬러 감성 | 파스텔 웜 컬러 팔레트 | 브랜드 컬러 + 무채색 | ✅ MZ 감성 적합 |
| 마이크로카피 | "동의하고 계속", "시작하기" 등 자연어 | 토스: "네, 동의해요" 등 1인칭 공감형 | △ 더 친근하게 개선 가능 |
| 에러 메시지 | 서버 기본 메시지 | 한국어 친근한 오류 안내 | ❌ 미구현 |
| 결과 공유 | 없음 | 카카오: 핵심 기능 | ❌ 부재 |
| 로딩 피드백 | 없음 | 토스: 즉각적 스켈레톤 UI | ❌ 부재 |
| 한국어 줄바꿈 | `break-words` 미지정 | word-break: keep-all | ❌ 미적용 |
| 다크모드 | 없음 | 토스: 완전 지원 | △ (필수 아닌 개선) |
| 소셜 로그인 | 없음 | 카카오 로그인 | △ (MVP 이후 고려) |
| 접근성 | 미흡 | 양사 ARIA 적극 활용 | ❌ 크게 미달 |

**한국어 타이포그래피 특이 문제**
- `word-break: keep-all`이 미적용되어 한국어 단어가 행 끝에서 임의로 잘릴 수 있음. 특히 질문 텍스트(`<h2 class="text-xl sm:text-2xl font-medium leading-relaxed">`)에서 "하기가", "나는" 같은 조사 뒤 줄바꿈이 어색하게 발생.
- `leading-relaxed`(1.625) 사용은 한국어 행간으로 적절 ✅.
- `tracking-tight` (sessions/new h1)는 한국어 자간을 지나치게 좁히므로 한국어에는 `tracking-normal` 이하 권장.

**개선 건의**
- `body` 또는 prose 컨테이너에 `word-break: keep-all` 추가 (Tailwind 커스텀 유틸리티 또는 `@layer base`).
- `tracking-tight` → `tracking-normal` (한국어 헤드라인).
- 마이크로카피 개선: "동의하고 계속" → "네, 동의해요", "시작하기" → "지금 시작하기".
- 카카오 공유 SDK 연동 준비 (결과 페이지 공유 기능 MVP 다음 단계로 추가).

---

## Key Findings

1. **감정 흐름 설계의 방향은 옳으나 마무리가 약하다.** type_hero 애니메이션은 흥분 유도에 성공하지만, 인사이트 탭의 건조한 불릿과 trust_notice 법적 문구로 마무리되어 성찰 감정이 차갑게 끝남.
2. **접근성이 MVP 수준에도 미달한다.** 스펙트럼 바, 인사이트 탭, 라이커트 폼 모두 ARIA 없음. 특히 인사이트 탭은 WAI-ARIA Tabs 패턴 명세를 전혀 따르지 않는다.
3. **Tailwind 동적 클래스 purge 위험이 실재한다.** `bg-<%= domain_colors[...] %>` 패턴은 Tailwind v4 JIT에서 런타임에 클래스가 생성되지 않아 스타일 누락을 일으킬 수 있다.
4. **Stimulus 컨트롤러 여러 개가 미완성이다.** `type_reveal`, `questionnaire`, `autosave` 컨트롤러가 빈 메서드 상태로 존재한다.
5. **동의 페이지가 신뢰 구축 기회를 놓치고 있다.** 정보가 1줄뿐인 동의 페이지는 법적 요건을 채우지 못하고 신뢰도 구축하지 못한다.
6. **한국어 `word-break: keep-all` 미적용**으로 질문 텍스트와 결과 설명에서 어색한 줄바꿈 발생 가능.
7. **결과 공유 기능 부재.** 한국 MZ 사용자의 성격 유형 공유 욕구 충족 불가로 바이럴 기회 손실.

---

## Recommendations

### 즉시 수정 (Critical)

- [ ] `lavender` 동적 Tailwind 클래스 safelist 등록 또는 정적 클래스로 교체
- [ ] `text-warm-gray/60` 요소들 대비 4.5:1 이상 확보
- [ ] 스펙트럼 바에 `role="meter"` / `aria-valuenow` / `aria-label` 추가
- [ ] SVG 아이콘에 `aria-hidden="true"` 추가
- [ ] `@media (prefers-reduced-motion: reduce)` CSS 추가
- [ ] `body`에 `word-break: keep-all` 추가

### 단기 개선 (High)

- [ ] 인사이트 탭 WAI-ARIA Tabs 패턴 구현 (role, aria-selected, 키보드 ←/→)
- [ ] 라이커트 라디오 버튼 포커스 링 복원 (`focus-within:ring`)
- [ ] 탭 패널 전환 및 `<details>` 확장 애니메이션 추가
- [ ] Turbo Frame 로딩 상태 스피너 추가
- [ ] trust_notice 위치를 type_hero 직후 또는 접이식으로 이동
- [ ] 동의 페이지 정보 보강 (수집 항목, 목적, 보유 기간)
- [ ] 검사 중 뒤로 가기 버튼 추가
- [ ] `<style>` 인라인 keyframe → `application.css`로 이동

### 중기 개선 (Medium)

- [ ] 결과 공유 기능 (링크 복사 + 카카오 공유)
- [ ] 스펙트럼 바 양방향 표시 (중앙 기준 방향성)
- [ ] `tabs_controller.js` 클래스 교체 로직 안정화
- [ ] 플래시 메시지 `role="alert"` 추가
- [ ] 마이크로카피 1인칭 공감형으로 개선
- [ ] `tracking-tight` → `tracking-normal` (한국어 헤드라인)
- [ ] 검사 완료 화면 UX 개선 (확인 버튼 외 기대감 고조 요소 추가)

### 장기 개선 (Low/Future)

- [ ] 다크모드 지원
- [ ] 카카오 소셜 로그인
- [ ] 결과 이미지 저장 (카드형 OG 이미지)
- [ ] Pretendard 자체 호스팅 (CDN 의존도 제거)

---

## References

- `/Users/kampikrein/A/personality/app/views/layouts/application.html.erb`
- `/Users/kampikrein/A/personality/app/views/sessions/new.html.erb`
- `/Users/kampikrein/A/personality/app/views/consents/new.html.erb`
- `/Users/kampikrein/A/personality/app/views/assessment_questions/show.html.erb`
- `/Users/kampikrein/A/personality/app/views/assessment_questions/_question.html.erb`
- `/Users/kampikrein/A/personality/app/views/assessments/show.html.erb`
- `/Users/kampikrein/A/personality/app/views/results/show.html.erb`
- `/Users/kampikrein/A/personality/app/views/results/_type_hero.html.erb`
- `/Users/kampikrein/A/personality/app/views/results/_spectrum.html.erb`
- `/Users/kampikrein/A/personality/app/views/results/_insight_card.html.erb`
- `/Users/kampikrein/A/personality/app/views/results/_trust_notice.html.erb`
- `/Users/kampikrein/A/personality/app/views/accounts/new.html.erb`
- `/Users/kampikrein/A/personality/app/views/deletion_requests/new.html.erb`
- `/Users/kampikrein/A/personality/app/views/deletion_requests/show.html.erb`
- `/Users/kampikrein/A/personality/app/views/layouts/admin.html.erb`
- `/Users/kampikrein/A/personality/app/assets/tailwind/application.css`
- `/Users/kampikrein/A/personality/app/javascript/controllers/likert_controller.js`
- `/Users/kampikrein/A/personality/app/javascript/controllers/tabs_controller.js`
- `/Users/kampikrein/A/personality/app/javascript/controllers/type_reveal_controller.js`
- `/Users/kampikrein/A/personality/app/javascript/controllers/spectrum_bar_controller.js`
- `/Users/kampikrein/A/personality/app/javascript/controllers/countdown_controller.js`
- `/Users/kampikrein/A/personality/app/javascript/controllers/questionnaire_controller.js`
- `/Users/kampikrein/A/personality/app/javascript/controllers/autosave_controller.js`
