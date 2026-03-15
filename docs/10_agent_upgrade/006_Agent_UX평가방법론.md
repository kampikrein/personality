---
id: "006"
title: "UX 평가/QA 에이전트 방법론 조사"
category: agent
status: archived
created: 2026-03-15
summary: >
  사용자 관점 품질 평가 에이전트의 역할 범위, 평가 체크리스트, 피드백 루프 설계를 조사
keywords: [agent-report, ux-evaluation, qa-agent, heuristic-evaluation, accessibility, emotional-design]
modules: [ux-evaluation]
---

# UX 평가/QA 에이전트 방법론 조사

## Progress
### Completed
- [x] UX 평가 자동화 도구 및 방법론 조사
- [x] 닐슨 히유리스틱/WCAG 에이전트화 가능성 분석
- [x] 평가-구현 피드백 루프 설계 패턴 조사
- [x] 타로 앱 특수 UX 평가 기준 도출 (영적 연결감, 몰입도, 제의적 UX)
- [x] 평가 에이전트 역할 정의안 및 체크리스트 프레임워크 작성
### Remaining
(없음)
### Current Status
조사 완료.

## Summary

UX 평가/QA 에이전트의 역할 범위, 방법론, 피드백 루프 설계를 조사한 결과, **별도의 평가 전용 에이전트를 신설하기보다 기존 uiux-expert의 역할을 확장하되, 평가 체크리스트와 도메인 특수 지식을 외부 파일로 분리하는 접근**이 현 프로젝트 규모에 적합하다고 판단한다. 핵심 근거: (1) 현재 시스템의 평가루프 프로토콜이 이미 Generator-Critic 패턴을 구현하고 있음, (2) uiux-expert가 이미 감정 흐름+접근성+모바일을 다루므로 역할 정의의 80%가 겹침, (3) 타로 앱 특수 평가 기준은 체크리스트 외부화로 해결 가능. 다만 모바일(Flutter) 전환에 따라 uiux-expert의 기술 스택 확장(Hotwire/Turbo → Flutter 위젯)과 타로 도메인 평가 기준 추가가 필수적이다.

## Details

### 1. UX 평가 자동화 도구 및 방법론 현황

#### 1.1 AI 기반 UX 평가 도구 생태계 (2025-2026)

**설계 평가 도구**:
- **UX Pilot**: 예측적 히트맵, 자동 UX 리뷰로 마찰점 식별. 시각적 명확성, 정보 위계, 네비게이션, CTA 효과, 접근성 준수를 평가
- **Figma AI Design Review**: 레이아웃 비평, 대안 제시, 마이크로카피 제안. 사용자 여정, 로직, 엣지 케이스에 대한 피드백
- **Figr**: 문제 → 플로우/엣지 케이스 사고 → UX 결정 리뷰 → 하이파이 프로토타입 자동 생성
- **Design Buddy**: AI 기반 설계 리뷰 및 피드백 도구
- **Attention Insight**: 90% 정확도의 주의력 패턴 예측, 시각적 히트맵 생성

**QA/테스팅 에이전트**:
- **TestSprite**: 자율적 IDE 네이티브 검증 루프. AI 생성 코드 검증에 특화. 제품 의도 이해 → 테스트 생성 → 실패 분류 → 구조화된 수정 피드백
- **Applitools**: Visual AI로 실제 UI 문제 감지, 노이즈 필터링. 웹/모바일/데스크톱 지원
- **Mabl**: 자동 치유 테스트, 시각적 회귀 감지
- **BrowserStack App Accessibility**: Spectra Rule Engine으로 20+ WCAG 성공 기준 자동 감지. 실제 iOS/Android 디바이스에서 테스트

**오픈소스 UX 리뷰 에이전트 (GitHub)**:
- veluthoor/ui-ux-design-review-agent: Gemini 2.0 기반. 5가지 차원 평가 (시각 디자인, 정보 아키텍처, 컴포넌트 품질, 접근성, 인터랙션 디자인). 6-8개 마크다운 파일로 평가 결과 출력 (색상 팔레트, 컴포넌트 리디자인, 애니메이션 가이드라인 포함)

#### 1.2 학술 동향
Liu (2025) 체계적 리뷰 — 55개 피어리뷰 논문 분석. AI 기술(ML, LLM, 생성AI)이 UX 평가에 기여하는 영역: 행동 모델링, 감정 분석, 피드백 생성, 사용자 시뮬레이션

#### 1.3 자동화 가능 vs 수동 필요 항목

| 자동화 가능 | 반자동(AI 보조 + 사람 검증) | 수동 필수 |
|------------|--------------------------|----------|
| 색상 대비 검사 (WCAG) | 정보 위계 평가 | 감정적 반응 관찰 |
| 탭 타겟 크기 검사 | 네비게이션 흐름 분석 | 문화적 적절성 판단 |
| 시맨틱 라벨 존재 확인 | 마이크로카피 품질 평가 | 영적 연결감/몰입도 |
| 시각적 회귀 감지 | 예측적 히트맵/주의력 분석 | 의식적 흐름의 자연스러움 |
| 레이아웃 일관성 검사 | 에러 메시지 명확성 | 사용자 인터뷰/감정 질적 데이터 |
| 스크린 리더 호환성 | CTA 효과 평가 | 비즈니스 로직 뉘앙스 |
| 플렉스 오버플로우 감지 | 인지 부하 추정 | 콘텐츠의 심리적 안전성 |

### 2. 닐슨 히유리스틱 / WCAG 에이전트화 가능성

#### 2.1 닐슨 10대 히유리스틱 에이전트화 분석

| # | 히유리스틱 | 자동화 수준 | 에이전트 구현 접근법 |
|---|----------|-----------|-------------------|
| 1 | 시스템 상태 가시성 | **높음** | 로딩 인디케이터, 진행 바, 상태 메시지 존재 여부 자동 감지 |
| 2 | 시스템-실세계 매칭 | **낮음** | 도메인 특수 용어 사전 기반 검증 가능, 맥락 이해는 제한적 |
| 3 | 사용자 제어와 자유 | **중간** | 실행 취소/뒤로가기/취소 버튼 존재 자동 감지. 흐름 분석은 반자동 |
| 4 | 일관성과 표준 | **높음** | 디자인 시스템 규칙 기반 lint. 컴포넌트 사용 패턴 자동 검증 |
| 5 | 에러 방지 | **중간** | 폼 검증, 확인 다이얼로그 존재 확인. 위험 동작 감지는 반자동 |
| 6 | 재인지 > 회상 | **낮음** | 레이블 존재, 툴팁, 문맥 도움말 감지 가능. 인지 부하는 수동 평가 |
| 7 | 유연성과 효율성 | **낮음** | 단축키/커스터마이징 옵션 존재 확인 가능. 숙련 사용자 경험은 수동 |
| 8 | 미적이고 미니멀한 디자인 | **중간** | 정보 밀도, 시각적 복잡도 메트릭 가능. 미적 판단은 AI 보조 |
| 9 | 에러 복구 지원 | **중간** | 에러 메시지 존재/명확성 검사. 복구 경로 유효성은 반자동 |
| 10 | 도움말과 문서 | **높음** | 도움말 링크, FAQ, 온보딩 플로우 존재 자동 감지 |

**결론**: 10개 중 3개(#1, #4, #10)는 높은 자동화 가능, 4개(#3, #5, #8, #9)는 중간, 3개(#2, #6, #7)는 낮음. LLM 기반 에이전트는 "중간" 영역을 "높음"으로 끌어올릴 잠재력이 있음.

#### 2.2 WCAG 모바일 접근성 에이전트화

**Flutter 특수 사항**:
- `accessibility_tools` 패키지: 최소 탭 영역, 시맨틱 라벨, 플렉스 오버플로우, 이미지 라벨 자동 검증
- Flutter Accessibility Guideline API: 텍스트 대비, 타겟 크기, 타겟 라벨 자동 검사
- flutter_driver / integration test + 접근성 브릿지로 WCAG 2.2 자동 검증 가능

**자동화 가능한 WCAG 기준**:
- 4.5:1 텍스트 대비 비율 (1.4.3)
- 48x48dp 최소 탭 타겟 (2.5.5)
- 시맨틱 라벨 존재 확인 (1.1.1)
- 다크 모드에서의 대비 비율 준수
- TalkBack/VoiceOver 호환성 검증 (반자동)

**POUR 원칙 기반 체크리스트 구조**:
- Perceivable: 텍스트 대안, 시간 기반 미디어 대안, 적응성, 구별 가능성
- Operable: 키보드 접근성, 충분한 시간, 발작 방지, 탐색 가능성
- Understandable: 읽기 쉬움, 예측 가능성, 입력 지원
- Robust: 호환성, 파싱

### 3. 평가-구현 피드백 루프 설계 패턴

#### 3.1 Producer-Critic (Generator-Critic) 패턴

**핵심 흐름**: Producer 생성 → Critic 평가 → 피드백 → Producer 수정 → 반복

**구현 원칙**:
- Critic은 반드시 독립적이어야 함 (다른 시스템 프롬프트, 가능하면 다른 LLM)
- Producer는 Critic의 지시를 볼 수 없어야 함 (편향 방지)
- 명시적 중지 조건 필수 (무한 루프 방지)
- 최대 반복 횟수 제한 설정

**평가 메트릭**:
| 메트릭 | 정의 |
|--------|------|
| Quality Delta | 초기 → 최종 출력의 품질 개선도 |
| Critique Precision | 유효 이슈 / 전체 비평 수 |
| Convergence Rate | 수용 품질까지 필요한 반복 횟수 |
| Cost Efficiency | 토큰 소비 대비 품질 향상 |
| Error Detection | 실제 에러 포착률 |

**Critic 구현 옵션**:
- LLM-as-Judge: 다른 LLM이 점수/순위 매김
- Rule-based: 결정론적 체크 및 검증 로직
- Human-in-loop: 전문가 인간 리뷰
- Hybrid: 복합 접근 (권장)

#### 3.2 OpenObserve Council of Sub Agents 사례 (실제 구현)

6단계 파이프라인 + 8개 전문 에이전트 (Claude Code 기반):
1. **Orchestrator** — 기능 라우팅, 파이프라인 관리
2. **Analyst** — 셀렉터 추출, 워크플로우 매핑, 엣지 케이스 식별
3. **Architect** — 우선순위화된 테스트 계획 (P0/P1/P2)
4. **Engineer** — Playwright 테스트 생성 (Page Object Model)
5. **Sentinel** — 품질 게이트. 코드 감사, 프레임워크 위반/안티패턴 감지. 치명적 이슈 시 파이프라인 차단
6. **Healer** — 테스트 실행, 실패 진단, 최대 5회 반복 수정
7. **Scribe** — 테스트 문서화
8. **Test Inspector** — GitHub PR 리뷰

**성과**: 분석 시간 6-10배 단축, 플레이키 테스트 85% 감소, 커버리지 84% 증가, 첫 성공 테스트까지 시간 12배 개선

#### 3.3 자율 테스팅 에이전트 아키텍처 (4계층)

1. **환경 스캐닝 계층**: DOM, API, DB 스키마, 앱 상태를 시맨틱 이해로 매핑
2. **테스트 발견 계층**: 모델 기반 테스팅 + 강화학습으로 핵심 경로, 경계 조건, 네거티브 시나리오 식별
3. **자기 치유 최적화 계층**: UI 변경 시 시각적 외관/레이블/위치 기반 요소 재인식
4. **CI/CD 통합 계층**: PR 트리거, 위험 평가, 릴리스 차단

**운영 루프**: Sense → Decide → Act → Learn (지각 → 판단 → 행동 → 학습)

### 4. 타로 앱 특수 UX 평가 기준

#### 4.1 영적 연결감 (Spiritual Connection)

타로 앱 사용자는 "정확성"을 사실적 예측이 아닌 세 가지 체험적 기준으로 평가한다:
- **공명(Resonance)**: 메시지가 내면 경험을 반영하는 느낌
- **관련성(Relevance)**: 현재 삶의 상황에 적용 가능한 정도
- **일관성(Coherence)**: 카드, 해석, 조언이 의미 있는 전체로 맞물리는 정도

**평가 체크리스트**:
| ID | 기준 | 측정 방법 |
|----|------|----------|
| SC-01 | 셔플 과정에서 사용자 물리적 개입(흔들기, 스와이프, 탭)이 존재하는가? | 인터랙션 존재 여부 자동 감지 |
| SC-02 | 카드 선택 시 "내가 선택했다"는 에이전시 감각이 있는가? | 사용자 입력과 결과의 직접적 연결 확인 |
| SC-03 | 해석 전달 시 조건부 어조(conditional phrasing)를 사용하는가? | 텍스트 패턴 분석 (자동) |
| SC-04 | 사용자 컨텍스트 입력(키워드, 질문) 기반 해석 커스터마이징이 있는가? | 기능 존재 여부 확인 |
| SC-05 | 12세션 이상 사용 시 accuracy 인식이 상승하는 피드백 루프가 설계되어 있는가? | 리텐션 메트릭 + 학습 루프 존재 확인 |

#### 4.2 몰입도 (Immersion)

**다크 모드 & 시각 환경**:
- 다크 테마가 기본값이며, 밝은 색상 액센트가 4.5:1 대비 비율을 준수하는가?
- 시각적-의미적 앵커링(high-fidelity 카드 이미지 + 동적 애니메이션)이 멀티센서리 처리를 활성화하는가? (연구: 최대 22% 인지된 진정성 향상)

**점진적 정보 공개 (Progressive Disclosure)**:
- 카드 해석이 한 번에 전체 공개되지 않고, 단계적으로 드러나는가?
- 모바일 화면에서 핵심 행동만 먼저 보이고, 부가 정보는 확장/탭으로 접근하는가?

**애니메이션 타이밍**:
- 카드 뒤집기/셔플 애니메이션이 물리적 카드 조작의 촉감적 만족감을 재현하는가?
- 의미 있는 순간(카드 오픈, 해석 도출)에서 적절한 지연(3초+ 멈춤)이 있는가? (연구: 3초+ 멈춤 후 41% 높은 "보여지는 느낌" 보고)
- `prefers-reduced-motion` 접근성 설정을 존중하는가?

**평가 체크리스트**:
| ID | 기준 | severity |
|----|------|----------|
| IM-01 | 다크 모드 기본, 액센트 대비 4.5:1+ | blocker |
| IM-02 | 카드 해석 점진적 공개 | major |
| IM-03 | 셔플/뒤집기 애니메이션 존재 및 물리 엔진 기반 | major |
| IM-04 | 의미 있는 순간에 의도적 지연/포즈 | minor |
| IM-05 | reduced-motion 접근성 존중 | blocker |

#### 4.3 제의적 UX (Ritual UX)

Ritual Design Canvas 기반 (Cowry Consulting / Interaction Foundry):

**의식의 4단계 흐름**:
1. **준비(Preparation)**: 질문 입력/의도 설정 → 마음의 전환 신호 (시각/청각 큐)
2. **셔플(Shuffle)**: 물리적 개입 (흔들기, 스와이프) → 무작위성의 의미 부여
3. **드로우(Draw)**: 카드 선택의 에이전시 → 선택의 순간 강조
4. **해석(Interpretation)**: 점진적 의미 공개 → 성찰 유도 → 다음 행동 제안

**Ritual Design의 핵심 요소**:
- **의도성(Intentionality)**: 습관이 아닌 의식적 참여 (습관 vs 의식의 차이)
- **감각적 경험**: 시각(카드 아트), 청각(사운드), 촉각(햅틱)의 통합
- **시퀀싱**: 사용자가 순서를 경험하되, 각 단계가 의미를 갖는 구조
- **스크립팅**: 정해진 단계를 따르되 선택의 여지를 제공
- **감정적 결과**: 감정 생성, 의미 창출, 변환 달성

**평가 체크리스트**:
| ID | 기준 | severity |
|----|------|----------|
| RT-01 | 준비→셔플→드로우→해석의 4단계 흐름이 명확히 구분되는가? | blocker |
| RT-02 | 각 단계 전환에 의도적인 경계 신호(시각/청각/햅틱)가 있는가? | major |
| RT-03 | 뒤로가기/건너뛰기가 의식 흐름을 깨뜨리지 않으면서도 가능한가? | major |
| RT-04 | 해석 후 성찰 시간/저널링 기회가 제공되는가? | minor |
| RT-05 | 반복 사용 시 개인화된 의식 패턴(시간대, 스프레드 선호)이 학습되는가? | minor |

#### 4.4 커스텀 덱 UX

**인지 부하 평가 기준**:
| ID | 기준 | severity |
|----|------|----------|
| CD-01 | 대량 업로드 시 진행 상태 표시 및 오류 복구가 명확한가? | blocker |
| CD-02 | 메타데이터 편집 시 한 화면에 의사결정 1-2개 이하인가? | major |
| CD-03 | 청킹(chunking): 78장 카드를 메이저/마이너 아르카나로 그룹화하는가? | major |
| CD-04 | 일괄 편집(batch operations) 패턴이 제공되는가? | minor |
| CD-05 | 미리보기에서 실제 리딩과 동일한 시각적 경험을 확인할 수 있는가? | minor |

#### 4.5 소셜/바운티 UX

**커뮤니티 안전성 평가 기준**:
| ID | 기준 | severity |
|----|------|----------|
| SO-01 | 익명화 옵션이 기본 제공되며 개인정보 노출을 방지하는가? | blocker |
| SO-02 | 위기 상황 인식: 자해/위험 키워드 감지 시 적절한 리소스를 안내하는가? | blocker |
| SO-03 | 바운티 시스템에서 금전적 압박감이 없는 건강한 참여 구조인가? | major |
| SO-04 | 신고/차단 메커니즘이 접근 가능하고 반응적인가? | major |
| SO-05 | 게이미피케이션 요소(뱃지, 레벨)가 강박적 사용을 조장하지 않는가? | major |
| SO-06 | 옵트아웃: 게이미피케이션/소셜 요소를 비활성화할 수 있는가? | minor |

### 5. 기존 uiux-expert와의 역할 중복/분리 분석

#### 5.1 현재 uiux-expert 역할 범위

| 항목 | 현재 상태 |
|------|----------|
| 감정 흐름 설계 | 호기심→몰입→발견→성찰 (성격 탐색 전용) |
| 접근성 | WCAG 2.1 AA, 색상 대비, 키보드, 스크린리더 |
| 기술 스택 | Hotwire/Turbo + Tailwind CSS + Stimulus (**웹 전용**) |
| 타겟 | 한국 MZ세대, 모바일 퍼스트 (브라우저 기반) |
| 역할 성격 | **구현(Implementation) + 검증(Evaluation) 겸임** |

#### 5.2 평가 에이전트 신설 시 역할 비교

| 평가 항목 | uiux-expert (현재) | 별도 평가 에이전트 (신설 시) |
|----------|-------------------|--------------------------|
| 닐슨 히유리스틱 | 암묵적 (SOP Think 단계에 내재) | 명시적 체크리스트 기반 |
| WCAG | UX-01, UX-02로 코드 레벨 확인 | 전용 도구(accessibility_tools) 통합 평가 |
| 감정 흐름 | UX-03으로 확인 | 타로 특수 의식적 흐름 평가 추가 |
| 타로 특수 기준 | 없음 | SC/IM/RT/CD/SO 체크리스트 |
| 기술 스택 | 웹 (Hotwire/Turbo) | Flutter 위젯 트리 분석 |
| 피드백 방식 | 구현 중 자체 검증 | 독립적 외부 평가 (Generator-Critic) |

#### 5.3 판단: 확장 vs 분리

**별도 에이전트 신설의 장점**:
- Producer-Critic 패턴의 순수 구현 (구현자 ≠ 평가자)
- 평가 전문화: 도메인 특수 체크리스트에 집중
- 병렬 실행 가능 (구현과 동시에 평가)

**별도 에이전트 신설의 단점**:
- 역할 80% 중복: 감정 흐름, 접근성, 모바일 퍼스트는 이미 uiux-expert 범위
- 조율 비용 증가: 6번째 에이전트 추가에 따른 오케스트레이션 복잡도
- 연구에 따르면 단일 에이전트가 소프트웨어 개발에서 더 효과적인 경우가 많음 (특히 코드 실행 가능성, 일관성)

**권장 접근: uiux-expert 역할 확장 + 평가 기준 외부화**

기존 uiux-expert를 확장하되, 평가 체크리스트를 외부 파일로 분리하여 "평가 모드"에서 로딩하는 하이브리드 접근:

```
현재 orchestration.md의 평가루프:
  uiux-expert(구현) → psychology-expert(검증) ← 이 패턴 유지

확장:
  uiux-expert(구현 + 자체 평가) → uiux-expert(크로스 평가 모드) ← 별도 스폰
  * 크로스 평가 시: 타로 특수 체크리스트 로딩
  * 자체 구현물에 대해서는 평가하지 않음 (Producer ≠ Critic 원칙)
```

### 6. 평가 에이전트 역할 정의안

#### 6.1 권장 구조: uiux-expert 확장

```yaml
# .claude/agents/uiux-expert.md 확장 사항

# 추가할 전문 영역
전문 영역 추가: Flutter 위젯 UX, 타로 의식적 흐름 평가

# 추가할 평가 모드
evaluation_mode:
  trigger: "오케스트레이터가 '평가 모드'로 스폰 시"
  behavior: "구현 행동 비활성, 체크리스트 기반 평가만 수행"
  checklists:
    - .claude/checklists/ux-heuristic.yaml      # 닐슨 10대 히유리스틱
    - .claude/checklists/ux-accessibility.yaml    # WCAG 2.2 + Flutter 접근성
    - .claude/checklists/ux-tarot-ritual.yaml     # 타로 특수 (SC/IM/RT/CD/SO)
  output_format: orchestration.md의 evaluation 포맷 준수
```

#### 6.2 평가 체크리스트 프레임워크 (통합)

**Tier 1 — 자동 검증 (Rule-based, CI/CD 통합 가능)**:
| ID | 카테고리 | 기준 | 도구/방법 |
|----|---------|------|----------|
| A-01 | 접근성 | 텍스트 대비 4.5:1+ | Flutter Accessibility Guideline API |
| A-02 | 접근성 | 탭 타겟 48x48dp+ | accessibility_tools 패키지 |
| A-03 | 접근성 | 시맨틱 라벨 존재 | accessibility_tools 패키지 |
| A-04 | 접근성 | 플렉스 오버플로우 없음 | accessibility_tools 패키지 |
| A-05 | 일관성 | 디자인 시스템 컴포넌트 사용 | 커스텀 lint 규칙 |
| A-06 | 상태 | 로딩/에러/빈 상태 처리 존재 | 위젯 트리 정적 분석 |

**Tier 2 — LLM 보조 평가 (에이전트가 코드/스크린샷 분석)**:
| ID | 카테고리 | 기준 | 평가 방법 |
|----|---------|------|----------|
| B-01 | 히유리스틱 | 시스템 상태 가시성 | 위젯 트리 + 상태 관리 코드 분석 |
| B-02 | 히유리스틱 | 에러 방지 및 복구 | 폼/입력 위젯의 검증 로직 분석 |
| B-03 | 감정 흐름 | 화면별 감정 단계 일치 | 색상/타이포/여백 분석 + 도메인 컨텍스트 |
| B-04 | 타로 의식 | 4단계 흐름 구분 명확성 | 네비게이션 그래프 + 전환 애니메이션 분석 |
| B-05 | 몰입도 | 점진적 정보 공개 | 위젯 빌드 로직 + 애니메이션 타이밍 분석 |
| B-06 | 인지 부하 | 화면당 의사결정 수 | UI 요소 카운팅 + 정보 밀도 메트릭 |

**Tier 3 — 수동/사용자 테스트 필수 (에이전트가 체크리스트만 생성)**:
| ID | 카테고리 | 기준 | 테스트 방법 |
|----|---------|------|-----------|
| C-01 | 영적 연결감 | 셔플 시 에이전시 감각 | 사용자 인터뷰, Likert 척도 |
| C-02 | 문화적 적합성 | 한국 MZ세대 UX 기대 부합 | A/B 테스트, 사용자 관찰 |
| C-03 | 윤리 | 위기 상황 인식 및 대응 | 시나리오 기반 수동 테스트 |
| C-04 | 감정 반응 | 결과 표현의 심리적 안전성 | 감정 설문, 인터뷰 |
| C-05 | 소셜 안전 | 커뮤니티 상호작용의 건강성 | 시뮬레이션 테스트, 모더레이션 리뷰 |

#### 6.3 피드백 루프 설계안

```
┌─────────────────────────────────────────────┐
│           오케스트레이터                       │
│                                             │
│  1. 구현 지시 → uiux-expert (구현 모드)       │
│     └── 산출물: Flutter 위젯/화면 코드         │
│                                             │
│  2. Tier 1 자동 평가 (CI/CD)                 │
│     └── accessibility_tools, lint            │
│     └── 실패 시 → 1로 회귀 (자동 수정)         │
│                                             │
│  3. Tier 2 에이전트 평가                      │
│     └── uiux-expert (평가 모드, 별도 스폰)     │
│     └── 체크리스트 로딩 → 코드 분석 → 평가 결과 │
│     └── verdict: pass/fail/conditional_pass  │
│     └── 실패 시 → 1로 회귀 (fix_suggestion)   │
│                                             │
│  4. Tier 3 체크리스트 생성 (수동 테스트용)       │
│     └── 사용자에게 수동 테스트 항목 제시         │
│                                             │
│  * 최대 3회 반복 (기존 프로토콜 준수)            │
└─────────────────────────────────────────────┘
```

**기존 orchestration.md와의 정합성**:
- 평가 결과 포맷: 기존 `evaluation:` YAML 포맷 그대로 사용
- severity 기반 verdict: 기존 blocker/major/minor 체계 유지
- 최대 반복 3회: 기존 규칙 준수
- UX 검증 기준(UX-01~06)을 확장하되 기존 ID 체계와 호환

## Key Findings

1. **자동화 가능 범위가 생각보다 넓다**: 닐슨 10대 히유리스틱 중 3개는 완전 자동화, 4개는 LLM 보조로 자동화 수준을 높일 수 있다. Flutter의 accessibility_tools 패키지만으로도 WCAG의 핵심 기준(대비, 탭 타겟, 시맨틱 라벨)을 자동 검증할 수 있다.

2. **Producer-Critic 패턴이 이미 프로젝트에 내재되어 있다**: 현재 orchestration.md의 평가루프 프로토콜(생성→검증→재생성, 최대 3회)은 Generator-Critic 패턴의 구현이다. 별도 평가 에이전트 신설보다 이 기존 구조를 활용하는 것이 효율적이다.

3. **타로 앱에는 범용 UX 기준으로 포착할 수 없는 고유 평가 차원이 존재한다**: 영적 연결감(Resonance/Relevance/Coherence), 제의적 UX(4단계 의식 흐름), 에이전시 감각은 표준 히유리스틱에 없는 도메인 특수 기준이다. 이를 외부 체크리스트로 명시적으로 코드화해야 한다.

4. **윤리적 안전성은 타로 앱의 blocker급 평가 기준이다**: 연구에 따르면 현재 AI 타로 앱의 윤리적 반응성 점수는 2.1/5.0으로, 위기 상황(자해 키워드 등) 인식이 치명적으로 부족하다. 이는 blocker severity로 반드시 평가해야 한다.

5. **별도 평가 에이전트보다 기존 uiux-expert 확장이 적합하다**: 역할 80% 중복, 6번째 에이전트에 따른 오케스트레이션 복잡도 증가, 단일 에이전트의 일관성 이점을 고려하면 확장 접근이 현 프로젝트 규모에 맞다. 단, 평가 모드에서는 반드시 별도 스폰하여 Producer-Critic 분리 원칙을 준수해야 한다.

6. **3-Tier 평가 프레임워크가 실용적이다**: 자동(CI/CD) → LLM 보조(에이전트) → 수동(사용자 테스트)의 3단계로 나누면, 자동화 가능한 것은 빠르게 잡고, 도메인 특수 판단은 에이전트가, 주관적/감정적 평가는 사람이 담당하는 효율적 분업이 가능하다.

## Recommendations

### R1. uiux-expert 에이전트 확장 (즉시 실행 가능)

기존 uiux-expert의 역할 범위를 다음과 같이 확장한다:
- **기술 스택 추가**: Hotwire/Turbo + Tailwind CSS → **Flutter 위젯/Material Design 3** 추가
- **평가 모드 추가**: 오케스트레이터가 "평가 모드"로 별도 스폰 시, 체크리스트 기반 순수 평가만 수행
- **UX 검증 기준 확장**: 기존 UX-01~06에 타로 특수 기준(SC/IM/RT/CD/SO) 추가

### R2. 평가 체크리스트 외부 파일 생성

`.claude/checklists/` 디렉토리에 3개 체크리스트 파일을 YAML로 관리:
- `ux-heuristic.yaml`: 닐슨 10대 히유리스틱 기반
- `ux-accessibility.yaml`: WCAG 2.2 + Flutter 접근성 기준
- `ux-tarot-ritual.yaml`: 타로 도메인 특수 기준 (SC/IM/RT/CD/SO)

### R3. orchestration.md 에이전트 조합 가이드 업데이트

| 작업 유형 | 주 에이전트 | 검증 에이전트 |
|----------|-----------|-------------|
| UI 컴포넌트 (기존) | uiux | — |
| **타로 화면 구현** | **uiux (구현 모드)** | **uiux (평가 모드, 별도 스폰)** |
| **타로 콘텐츠 + UI** | **도메인 + uiux** | **psychology + uiux (평가)** |

### R4. CI/CD에 Tier 1 자동 평가 통합

Flutter 프로젝트의 `integration_test/`에 접근성 자동 검증을 포함:
- `accessibility_tools` 패키지 통합
- `flutter test --accessibility` 커맨드 CI 파이프라인 등록
- 다크 모드 대비 비율 검증 추가

### R5. 도메인 특수 지식은 체크리스트에, 행동 규칙은 에이전트에

프로젝트 설계 원칙 "행동 규칙 > 역할 선언"에 따라:
- 에이전트 정의(`.claude/agents/uiux-expert.md`): SOP 행동 루프만
- 도메인 지식(`.claude/checklists/*.yaml`): 평가 기준, 점수 기준, severity
- 이렇게 하면 타로 외 다른 도메인(성격 검사 등)에도 체크리스트만 교체하여 재사용 가능

## References

### UX 평가 자동화 도구
- [6 Best AI Tools for UI/UX Testing (2026)](https://aqua-cloud.io/ai-tools-for-ux-ui-testing/)
- [Top AI Tools for UX Designers (Figma)](https://www.figma.com/resource-library/ai-tools-for-ux-designers/)
- [UI/UX Design Review Agent (GitHub)](https://github.com/veluthoor/ui-ux-design-review-agent)
- [AI in Automated and Remote UX Evaluation (Liu, 2025)](https://onlinelibrary.wiley.com/doi/10.1155/ahci/7442179)
- [AI Design Reviewer (Figma Plugin)](https://www.figma.com/community/plugin/1339202278007297015/ai-design-reviewer-ui-ux-accessibility-design-system-linter-prototypes)

### 닐슨 히유리스틱 / 평가 방법론
- [10 Usability Heuristics (NN/g)](https://www.nngroup.com/articles/ten-usability-heuristics/)
- [How to Conduct a Heuristic Evaluation (NN/g)](https://www.nngroup.com/articles/how-to-conduct-a-heuristic-evaluation/)
- [Heuristic Evaluation Checklist (Maze)](https://maze.co/guides/usability-testing/heuristic-evaluation/)
- [UX Audit Checklist (Eleken)](https://www.eleken.co/blog-posts/a-checklist-for-ux-design-audit-based-on-jakob-nielsens-10-usability-heuristics)

### WCAG / 접근성
- [Flutter Accessibility Testing](https://docs.flutter.dev/ui/accessibility/accessibility-testing)
- [Flutter Accessibility](https://docs.flutter.dev/ui/accessibility)
- [accessibility_tools Package](https://pub.dev/packages/accessibility_tools)
- [BrowserStack App Accessibility Testing](https://www.browserstack.com/app-accessibility-testing)
- [Mobile App Accessibility Guide (2026)](https://www.accessibilitychecker.org/guides/mobile-apps-accessibility/)
- [WCAG Testing Methods (2025)](https://www.equalweb.com/a/44536/11527/comprehensive_wcag_testing_methods_in_2025)

### 피드백 루프 / 에이전트 패턴
- [Producer-Critic Pattern (Agentic Design)](https://agentic-design.ai/patterns/reflection/producer-critic)
- [Google's Multi-Agent Design Patterns](https://www.infoq.com/news/2026/01/multi-agent-design-patterns/)
- [OpenObserve: AI Agents for QA (Claude Code)](https://openobserve.ai/blog/autonomous-qa-testing-ai-agents-claude-code/)
- [Autonomous Testing Revolution (DEV)](https://dev.to/qa-leaders/the-autonomous-testing-revolution-how-ai-agents-are-reshaping-quality-engineering-37c7)
- [Choose Design Pattern for Agentic AI (Google Cloud)](https://docs.google.com/architecture/choose-design-pattern-agentic-ai-system)
- [Anthropic: Demystifying Evals for AI Agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)

### 타로 앱 / 영적 UX / 의식 디자인
- [Ritual Design: An Underrated UX Design Tool (Cowry)](https://www.cowryconsulting.com/newsandviews/ritual-design)
- [Introducing Ritual Design (Ritual Design Lab)](https://medium.com/ritual-design/introducing-ritual-design-meaning-purpose-and-behavior-change-44d26d484edf)
- [AI Tarot Apps vs Intuitive Readers (User Studies)](https://www.alibaba.com/product-insights/ai-powered-tarot-reading-apps-vs-intuitive-readers-what-do-user-studies-say-about-perceived-accuracy.html)
- [UX Case Study: Spiritual Practices App](https://medium.com/@carem.work/ux-ui-case-study-designing-a-spiritual-practices-app-for-the-young-generation-d638ffd472e2)
- [Virtual Realities in Spiritual Practices (ResearchGate)](https://www.researchgate.net/publication/387601496_Virtual_Realities_in_Spiritual_Practices_Exploring_Immersive_Technologies_in_Digital_Rituals)

### 감정 디자인 / 게이미피케이션 / 인지 부하
- [Emotional Design in UX (HCI.org)](https://www.hci.org.uk/article/the-role-of-emotional-design-in-user-experience-a-comprehensive-analysis/)
- [Gamification in UI/UX Guide (Mockplus)](https://www.mockplus.com/blog/post/gamification-ui-ux-design-guide)
- [Cognitive Load (Laws of UX)](https://lawsofux.com/cognitive-load/)
- [Progressive Disclosure (NN/g)](https://www.nngroup.com/articles/progressive-disclosure/)
- [Dark Mode UX Design Principles](https://www.influencers-time.com/designing-dark-mode-for-ux-comfort-and-cognitive-ease/)
