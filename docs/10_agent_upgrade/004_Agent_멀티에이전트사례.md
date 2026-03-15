---
id: "004"
title: "멀티에이전트 시스템 구성 사례 조사"
category: agent
status: completed
created: 2026-03-15
summary: >
  멀티에이전트 팀 구성 패턴, 오케스트레이션 전략, 에이전트 확장 사례를 외부 연구와 내부 문서 분석으로 조사.
  외부 사례 분석 결과: 전문화 에이전트가 범용 에이전트 대비 64.6% 성능 향상, 3-5개 팀원이 최적 균형,
  orchestrator-worker 패턴이 생산 환경 70% 차지, Generator-Critic 패턴이 품질 게이트의 표준.
  프로젝트 권장: 5→7개 확장 시 flutter-expert + tarot-domain-expert 추가, 평가 역할은 독립 에이전트 대신
  기존 psychology-expert의 검증 역할 강화로 대응.
keywords: [agent-report, multi-agent, orchestration, team-composition, agent-scaling, evaluation-pattern, specialization]
modules: [agent-design]
---

# 멀티에이전트 시스템 구성 사례 조사

## Progress
### Completed
- [x] 내부 에이전트 설계 문서 분석 (기존 5개 에이전트 구조 이해)
- [x] 외부 멀티에이전트 구성 패턴 조사
- [x] 모바일+서버 혼합 프로젝트 에이전트 분리 사례 조사
- [x] 에이전트 수 확장 시 오케스트레이션 관리 방법 조사
- [x] 평가/QA 에이전트 역할 정의 사례 조사
### Remaining
(없음)
### Current Status
전체 조사 완료. 내부 분석 + 외부 조사 결과 통합 및 권장안 도출 완료.

---

## Summary

멀티에이전트 시스템의 팀 구성, 오케스트레이션, 확장, 평가 패턴을 업계 사례/연구와 내부 문서 비교 분석하여 personality 프로젝트의 5→7~8개 에이전트 확장에 대한 구체적 권장안을 도출했다.

핵심 결론:
1. **전문화가 범용보다 압도적으로 우수** -- 연구에서 전문 에이전트 5개 팀이 2개 대비 64.6% 성능 향상, 범용 에이전트는 수 증가 시 오히려 8.7% 하락
2. **3-5개 팀원이 최적 균형** -- Claude Code Agent Teams 공식 문서도 3-5개 권장, 그 이상은 coordination overhead가 이득을 상쇄
3. **Orchestrator-Worker가 생산 환경 표준** -- 전체 배포의 약 70% 차지, 프로젝트의 기존 `--agent` 방식과 정확히 부합
4. **Generator-Critic 패턴이 품질 보장의 핵심** -- 별도 QA 에이전트보다 기존 전문가의 검증 역할 강화가 효과적
5. **에이전트 분리는 "기술 스택별"이 아닌 "도메인+기술 하이브리드"가 최선** -- 순수 기술 분리(frontend/backend)보다 도메인 전문성을 축으로 하되 기술 역량을 부가하는 구조

---

## Details

### 1. 멀티에이전트 구성 패턴 (외부 조사)

#### 1.1 에이전트 분리 유형학

업계에서 관찰되는 에이전트 분리 패턴을 3가지로 분류한다.

| 분리 축 | 설명 | 장점 | 단점 | 대표 사례 |
|---------|------|------|------|----------|
| **기술 스택별** | frontend agent, backend agent, DB agent | 구현 도구 집중, 충돌 최소화 | 도메인 맥락 단절, 크로스커팅 이슈 처리 어려움 | Goose 7-agent app builder, ChatDev |
| **도메인별** | 심리학 agent, MBTI agent, 타로 agent | 깊은 전문성, 일관된 관점 | 구현 능력 부재 시 병목 | personality 현재 구조 (자문 3 + 구현 2) |
| **기능/역할별** | researcher, engineer, reviewer, manager | 소프트웨어 팀 구조 미러링 | 도메인/기술 양쪽 깊이 부족 가능 | Agyn (SWE-bench 72.2%), MetaGPT |

**업계 추세**: 순수한 단일 축 분리보다 **하이브리드 분리**가 우세하다. MetaGPT는 역할별(PM, architect, engineer)이지만 각 역할이 도메인 지식을 가지고, Agyn은 역할별이지만 기술 도구가 역할에 따라 다르다. O'Reilly 기사는 "각 에이전트에 skill profile(강점, 약점, 적합한 역할)이 있다"며 **상호보완적 전문화**(complementary specialization)를 강조한다.

#### 1.2 전문화 vs 범용화 트레이드오프

ICLR 2025 Workshop 논문(Dynamic LLM-Agent Network)의 실증 결과:

| 팀 구성 | 2 에이전트 | 5 에이전트 | 변화 |
|---------|-----------|-----------|------|
| **전문화 에이전트** | 32.5% | 53.5% | **+64.6%** |
| **범용 에이전트** | 34.5% | 31.5% | **-8.7%** |

> "범용 에이전트를 추가하면 유사한 관점과 중복 정보만 생성되어 논의가 비효과적이 된다."

이 결과는 personality 프로젝트의 5축 차별화 구조(학술근거/문화적합/성장가능/구현실용/사용자경험)를 강력히 지지한다. 각 에이전트가 다른 "렌즈"를 가지고 있어야 추가할수록 성능이 향상된다.

**실전 사례 -- Agyn 코딩 에이전트 팀**:
- 구성: Manager + Researcher + Engineer + Reviewer (4역할)
- SWE-bench Verified: **72.2%** (단일 에이전트 GPT-5 기반 65.0% 대비 7.2%p 향상)
- 핵심 교훈: "조직 구조가 모델 품질만큼 중요하다. 중간 추론 모델의 전문화 팀이 고추론 단일 에이전트를 능가한다."

**Anthropic 자체 사례**:
- Opus 4 리드 + Sonnet 4 서브에이전트 병렬 구성으로 단일 에이전트 대비 **90.2% 성능 향상** (내부 평가)

#### 1.3 Google의 8가지 멀티에이전트 설계 패턴

Google이 2026년 1월 발표한 8가지 패턴을 personality 프로젝트 맥락에서 매핑한다.

| # | 패턴 | 설명 | personality 프로젝트 대응 |
|---|------|------|--------------------------|
| 1 | **Sequential Pipeline** | 조립 라인식 순차 전달 | Pattern A (파이프라인) -- 현재 사용 중 |
| 2 | **Coordinator/Dispatcher** | 중앙 디스패처가 요청 라우팅 | 오케스트레이터의 의사결정 트리 |
| 3 | **Parallel Fan-Out/Gather** | 병렬 실행 후 결과 종합 | Pattern C에서 자문 에이전트 병렬 단계 |
| 4 | **Hierarchical Decomposition** | 상위→하위 재귀 분해 | Claude Code 제약으로 1단계만 가능 |
| 5 | **Generator-Critic** | 생성자+비평자 쌍 | Pattern B (평가루프) -- 현재 사용 중 |
| 6 | **Iterative Refinement** | 생성→비평→개선 반복 | Pattern B의 max 3회 반복과 동일 |
| 7 | **Human-in-the-Loop** | 고위험 결정에 사용자 개입 | 사용자 개입 트리거 -- 현재 사용 중 |
| 8 | **Composite Pattern** | 위 패턴 조합 | Pattern C (하이브리드) -- 현재 사용 중 |

**평가**: personality 프로젝트의 기존 4가지 패턴(A/B/C/D)이 Google의 8가지 중 6가지를 이미 커버한다. 미커버는 #3(Fan-Out/Gather)과 #4(Hierarchical Decomposition)인데, #3은 Agent Teams 실험 기능 안정화 시 활용 가능하고, #4는 Claude Code의 서브에이전트 재귀 불가 제약으로 구조적 불가.

#### 1.4 O'Reilly 4가지 오케스트레이션 패턴

| 패턴 | 최적 용도 | 강점 | 약점 |
|------|----------|------|------|
| **Supervisor-based** | 순차 추론, 컴플라이언스 | 통제와 명확성 | 단일 인지 병목 |
| **Blackboard-style** | 창의적 작업 | 공유 메모리를 통한 반복 정제 | 집약 규율 필요 |
| **Peer-to-peer** | 탐색, 웹 네비게이션 | 직접 정보 교환 | 표류와 루프 위험 |
| **Swarm** | 리서치, 창작 | 범위와 중복성 | 토큰 소모, 종료 조건 필수 |

**하이브리드 권장**: "소수의 빠른 전문가가 병렬 작업하고, 느리지만 신중한 에이전트가 주기적으로 결과를 집약하며 가정을 점검하고 시스템 계속 여부를 결정한다."

이는 personality 프로젝트의 오케스트레이터 구조(메인 스레드에서 의사결정 + 서브에이전트 워커 스폰)와 정확히 부합한다.

---

### 2. 모바일+서버 혼합 프로젝트 에이전트 분리

#### 2.1 업계 사례 분석

**Goose 7-Agent App Builder** (Block/Square): 7개 에이전트가 1시간에 앱 구축
- 각 에이전트가 다른 개발 작업 담당 (frontend, backend, testing 등)
- **기술 스택별 분리**가 주축이지만, 각 에이전트가 도메인 컨텍스트를 공유

**DevOps.com "Coding Agent Teams"**: "단일 풀스택 접근을 다수의 에이전트로 교체. 각 에이전트가 다른 개발 작업에 특화 -- 하나는 프론트엔드, 하나는 백엔드, 또 하나는 테스트 작성/실행."

**McKinsey "Agentic Organization"**: "교차 기능 전달 스쿼드" 구성 -- 비즈니스 도메인 전문가 + 프로세스 설계자 + AI/MLOps 엔지니어 + IT 아키텍트 + 소프트웨어 엔지니어 + 데이터 엔지니어

#### 2.2 personality 프로젝트 분리 전략 비교

| 전략 | 구성 | 장점 | 단점 | 적합도 |
|------|------|------|------|--------|
| **A: 순수 기술 분리** | rails-expert + flutter-expert + db-expert + test-expert | 기술 깊이, 충돌 최소 | 도메인 맥락 단절, 성격심리 전문성 없음 | 낮음 |
| **B: 순수 도메인 분리** | psychology + mbti + enneagram + tarot + coding + uiux | 도메인 깊이 유지 | coding이 Rails+Flutter 양쪽 커버 → 과부하 | 중간 |
| **C: 하이브리드 분리** (권장) | 도메인 3 + 기술 3~4 (rails-coding + flutter-coding 분리) | 도메인 깊이 + 기술 집중 | 에이전트 수 증가 (7~8개) | **높음** |

**전략 C 세부안**:

```
도메인 에이전트 (3개, 유지):
  psychology-expert  -- 학술 검증, 바넘 효과 검수, 윤리
  mbti-expert        -- MBTI 문화, 문항, MZ세대 맥락
  enneagram-expert   -- 9유형, 성장 방향, 동기 탐색

기술 에이전트 (2개 → 3개, 분리):
  coding-expert      -- Rails 8+ 백엔드 (기존)
  flutter-expert     -- Flutter/Dart 모바일 앱 (신규)
  uiux-expert        -- UX 설계, 접근성, 감정 흐름 (기존)

도메인+기술 하이브리드 (1개, 신규):
  tarot-domain-expert -- 타로 도메인 지식 + 콘텐츠 설계
```

**도메인 전문가 vs 기술 전문가 비율**: 업계 자료에서 "데이터를 아는 사람 1, 워크플로를 소유한 사람 1, 소프트웨어를 출시할 수 있는 사람 1, 최종 사용자를 대변하는 사람 1"이 기본 구성. personality 프로젝트에서는 도메인:기술 = 4:3 (도메인 3 + 타로 1 : coding 1 + flutter 1 + uiux 1) 이 균형점.

#### 2.3 coding-expert 분리 근거

현재 coding-expert가 Rails + (향후) Flutter를 모두 담당하면:
- 도구 수 과잉 위험: "에이전트가 15-20개 도구에 접근하면 도구 선택 정확도가 80% 미만으로 하락" (GuruSup)
- 컨텍스트 윈도우 경쟁: Rails 서버 코드와 Flutter 위젯 코드가 동일 컨텍스트에서 충돌
- 에이전트 프롬프트 비대화: 두 스택의 컨벤션/패턴을 하나의 프롬프트에 담으면 안티패턴 #2(규칙 과잉)에 해당

따라서 **coding-expert(Rails) + flutter-expert(Dart/Flutter) 분리**가 전문화 원칙에 부합한다.

---

### 3. 에이전트 수 확장 시 오케스트레이션 관리

#### 3.1 확장의 수학적 복잡도

| 에이전트 수 | 잠재 연결 수 (N(N-1)/2) | 복잡도 증가 |
|------------|------------------------|-----------|
| 5 (현재) | 10 | 기준 |
| 7 (권장) | 21 | 2.1x |
| 8 (최대) | 28 | 2.8x |
| 10 | 45 | 4.5x |

**그러나** personality 프로젝트는 peer-to-peer가 아닌 **orchestrator-worker(hub-and-spoke)** 구조이므로, 실제 통신 채널은 N개(오케스트레이터↔각 워커)에 불과하다. 5→7은 오케스트레이터의 통신 채널이 5→7로 선형 증가할 뿐이다.

#### 3.2 복잡도 관리 전략

**전략 1: 계층적 그룹화**

Microsoft의 권장: "계층적 조직(supervisor → agent group)을 사용하여 명확성, 확장성, 의도 해석의 용이성을 유지."

personality 프로젝트 적용:
```
오케스트레이터
├── 도메인 그룹: psychology, mbti, enneagram, tarot-domain
└── 구현 그룹: coding, flutter, uiux
```

오케스트레이터의 의사결정 트리에서 "도메인 작업인가 구현 작업인가"를 먼저 분류하면 라우팅 복잡도가 줄어든다. 그룹 내 에이전트 조합은 그룹별 규칙으로 관리.

**전략 2: 구조화된 컨텍스트 객체**

GuruSup: "구조화된 컨텍스트 객체로 토큰 소비를 모놀리식 대비 60-70% 절감."

personality 프로젝트는 이미 3단계 압축 모델(Level 1 전문/Level 2 요약/Level 3 인계)을 설계했으므로, 에이전트 수 증가에도 컨텍스트 효율이 유지된다.

**전략 3: 에이전트별 도구 수 제한**

"에이전트당 3-5개 도구를 깊이 아는 것이 15-20개를 얕게 아는 것보다 낫다."

현재 프로젝트의 도구 배분:
- 자문 에이전트: Read, Glob, Grep, Edit, Write (5개) -- 적정
- 구현 에이전트: Read, Write, Edit, Bash, Glob, Grep (6개) -- 적정
- 에이전트 수가 늘어도 각 에이전트의 도구 수는 유지

**전략 4: Claude Code Agent Teams 활용 (미래)**

Claude Code Agent Teams가 안정화되면:
- 서브에이전트 간 직접 메시징 가능 → 오케스트레이터 병목 완화
- 공유 태스크 리스트로 작업 자동 분배
- Git Worktree 격리로 파일 충돌 방지
- 현재는 실험적 기능이므로 당장은 기존 `--agent` + Agent tool 방식 유지

#### 3.3 Claude Code Agent Teams 공식 권장 사항

Anthropic의 Agent Teams 문서에서 직접 인용한 핵심 권장:

- **"3-5개 팀원이 대부분의 워크플로우에 최적. 병렬 작업과 관리 가능한 조율의 균형."**
- **"팀원당 5-6개 태스크"**가 생산적 작업량
- **"3개의 집중된 팀원이 5개의 분산된 팀원을 능가한다"**
- 코드 수정이 겹치지 않도록 **각 팀원이 다른 파일 세트를 소유**

이 수치는 personality 프로젝트의 7개 에이전트 구성에서, 동시에 활성화되는 에이전트를 3-5개로 제한하라는 운영 지침을 시사한다.

#### 3.4 확장 시 오케스트레이터 프롬프트 변경

에이전트가 5→7개로 늘어나면 오케스트레이터의 **에이전트 조합 가이드** 테이블을 확장해야 한다:

| 작업 유형 | 주 에이전트 | 검증 에이전트 |
|----------|-----------|-------------|
| 문항 개발/유형 설명 | mbti 또는 enneagram | psychology |
| 점수 엔진/로직 | coding | psychology |
| UI 컴포넌트 (웹) | uiux | -- |
| DB/API 구현 | coding | -- |
| 콘텐츠 + 구현 복합 | 도메인 + coding | psychology |
| **Flutter 모바일 UI** | **flutter** | **uiux** |
| **타로 카드/덱 콘텐츠** | **tarot-domain** | **psychology** |
| **모바일 + 서버 연동** | **flutter + coding** | -- |
| **타로 문항/해석** | **tarot-domain + mbti/enneagram** | **psychology** |

---

### 4. 평가/QA 에이전트 역할 정의

#### 4.1 업계 평가 에이전트 패턴

**패턴 A: 독립 Reviewer 에이전트**

Agyn 팀(SWE-bench 72.2%)에서 Reviewer는 4번째 독립 에이전트로:
- PR 평가 및 수락 기준 강제
- Engineer에게 작업 반려 가능
- 독립 샌드박스에서 실행

**패턴 B: Generator-Critic 쌍**

Google 패턴 #5. 생성 에이전트와 비평 에이전트를 쌍으로 구성:
- Generator가 콘텐츠/코드 생성
- Critic이 검증하고 피드백 제공
- 반복 정제(패턴 #6)와 결합 가능

**패턴 C: 다차원 병렬 리뷰**

Claude Code Agent Teams 사례 -- PR 리뷰를 3개 팀원이 병렬 수행:
- 보안 담당 리뷰어
- 성능 담당 리뷰어
- 테스트 커버리지 담당 리뷰어
- 리드가 결과 종합

**패턴 D: Hooks 기반 품질 게이트**

Claude Code Agent Teams의 `TeammateIdle`/`TaskCompleted` 훅:
- 팀원이 작업 완료 시 자동 검증
- exit code 2로 피드백 전달 + 재작업 지시
- 프로그래밍적 품질 게이트

#### 4.2 Anthropic 공식 평가 프레임워크 (핵심)

Anthropic의 "Demystifying Evals for AI Agents"에서 도출한 3유형 평가자:

| 평가자 유형 | 강점 | 약점 | personality 적용 |
|------------|------|------|-----------------|
| **Code-based** (정규식, 테스트, 린팅) | 빠름, 저렴, 객관적, 재현 가능 | 유효한 변형에 취약, 뉘앙스 부재 | RSpec 테스트 통과, 린팅 |
| **Model-based** (LLM 루브릭, 비교) | 유연, 확장 가능, 뉘앙스 포착 | 비결정적, 비용, 교정 필요 | 바넘 효과 검수, 콘텐츠 품질 |
| **Human** (전문가 리뷰) | 골드 스탠다드 | 느림, 비용 | 저작권/윤리 최종 판단 |

**핵심 원칙**: "에이전트가 생산한 것을 평가하라, 경로를 평가하지 마라" -- 창의적이지만 유효한 해결책을 벌점 주지 않기 위함.

**pass@k vs pass^k 지표**:
- pass@k: k회 시도 중 1번 이상 성공할 확률 (능력 측정)
- pass^k: k회 시도 모두 성공할 확률 (일관성 측정)
- 품질 게이트는 pass^k(일관성)에 초점을 맞춰야 함

#### 4.3 personality 프로젝트에 대한 평가 전략 권장

**독립 QA 에이전트를 만들지 않는 이유**:

1. Claude Code 제약: 서브에이전트 재귀 불가로, 별도 QA 에이전트는 오케스트레이터가 직접 스폰해야 함 → 턴 예산 소모 증가
2. 프로젝트 규모: 7~8개 에이전트에서 QA 전담 에이전트 추가 시 8~9개 → 관리 복잡도 급증
3. 기존 구조의 활용: psychology-expert가 이미 학술 검증자 역할, coding-expert의 TDD가 코드 품질 보장

**대안: 기존 에이전트의 검증 역할 강화**

```
검증 매트릭스 (개선안):

콘텐츠 품질     → psychology-expert (Generator-Critic 패턴, 기존)
코드 품질       → coding-expert의 TDD + 린팅 (Code-based 평가)
UX 품질        → uiux-expert (접근성 + 감정 흐름 검증)
타로 콘텐츠     → psychology-expert (학술 검증) + tarot-domain (도메인 정합)
Flutter 코드   → flutter-expert의 테스트 + coding-expert (크로스 리뷰)
```

**오케스트레이션 프로토콜 개선안**: 기존 평가루프 프로토콜(verdict: pass/fail, max_iterations: 3)에 Anthropic 평가 프레임워크의 요소를 추가:

1. **Code-based 게이트**: 모든 구현 산출물에 RSpec/Flutter 테스트 통과를 전제 조건으로 추가 (평가루프 진입 전 필터)
2. **능력 vs 일관성 구분**: 새 기능은 pass@3(한 번이라도 성공하면 진행), 회귀 방지는 pass^3(항상 성공해야 함)
3. **평가 포화 모니터링**: 특정 검증 기준이 항상 통과하면 더 어려운 기준으로 확장

---

### 5. 내부 설계와 외부 사례 비교 분석

#### 5.1 프로젝트의 기존 강점 (외부 검증)

| 프로젝트 현행 원칙 | 외부 검증 |
|-------------------|----------|
| "행동 규칙 > 역할 선언" | O'Reilly: "잘못된 역할의 강력한 모델은 마찰을 적극적으로 도입한다" |
| 5축 차별화 (학술/문화/성장/구현/UX) | ICLR 연구: 전문화 에이전트만 수 증가 시 성능 향상 |
| 파일 기반 상태 관리 | Agyn: "파일시스템 지속성으로 토큰 예산 절약" |
| 3단계 컨텍스트 압축 | Vellum: "구조화된 컨텍스트 객체로 60-70% 토큰 절감" |
| 평가루프 max 3회 | Anthropic: "능력 평가는 반복으로 향상, 회귀 평가는 100% 유지" |
| 오케스트레이터 + Agent tool 화이트리스트 | GuruSup: "orchestrator-worker가 생산 환경 70% 차지" |

#### 5.2 프로젝트의 개선 필요 영역

| 외부 베스트프랙티스 | 프로젝트 현황 | 격차 |
|-------------------|-------------|------|
| Goal/Backstory로 사고 편향 고정 | 전면 부재 (R-008-F3) | Critical |
| Code-based 평가 게이트 (테스트 통과 전제) | 평가루프에 미포함 | High |
| 에이전트당 3-5개 도구 제한 | 이미 적정 (5-6개) | 없음 |
| 에이전트 간 직접 메시징 | 파일 기반만 가능 (제약) | Agent Teams 안정화 대기 |
| 인계 프로토콜 표준화 | 설계 완료, 미구현 (R-008-F3) | High |
| 기억 체계 활성화 | 구조만 있고 0건 (R-008-F3) | Critical |

---

## Key Findings

1. **[Critical] 전문화가 범용을 압도**: 전문 에이전트 팀은 수 증가 시 +64.6% 성능 향상, 범용 에이전트는 -8.7% 하락. personality의 5축 차별화 구조는 외부 연구에서 강력히 검증됨.

2. **[Critical] 3-5개가 동시 활성 최적점**: Claude Code 공식 문서와 업계 사례 모두 3-5개 동시 활성을 권장. 7개 에이전트를 보유하되 동시 활성은 3-5개로 제한하는 운영 전략이 필요.

3. **[High] 하이브리드 분리가 최선**: 순수 기술/순수 도메인 분리보다 도메인 축을 기본으로 하되 기술 역량을 부가하는 구조. coding-expert + flutter-expert 분리, tarot-domain-expert 신설이 이 원칙에 부합.

4. **[High] Orchestrator-Worker가 프로젝트에 최적**: 생산 환경 70%가 이 패턴. 프로젝트의 기존 `--agent` + Agent tool 구조가 정확히 부합하며, 5→7 확장에도 통신 채널이 선형(5→7)으로만 증가.

5. **[High] Generator-Critic이 평가의 핵심 패턴**: 별도 QA 에이전트보다 기존 전문가의 검증 역할 강화가 프로젝트 규모에 적합. psychology-expert의 검증 역할을 코드화된 게이트와 결합.

6. **[Medium] 조직 구조가 모델 품질만큼 중요**: Agyn 사례에서 "중간 추론 모델의 전문화 팀 > 고추론 단일 에이전트". 비용 효율적 확장의 근거.

7. **[Medium] Code-based 평가 게이트가 누락됨**: 현재 평가루프는 LLM 기반 판정만 포함. RSpec/Flutter 테스트 통과를 평가루프 진입 전제로 추가해야 함.

8. **[Info] Agent Teams는 차세대 옵션**: 안정화 시 peer-to-peer 메시징, 공유 태스크 리스트, 자동 작업 분배 활용 가능. 현재는 실험적.

---

## Recommendations

### 권장안 1: 에이전트 구성 (5→7)

```
현재 (5개)                    권장 (7개)
─────────────────            ─────────────────
psychology-expert      →     psychology-expert     (유지)
mbti-expert           →     mbti-expert           (유지)
enneagram-expert      →     enneagram-expert      (유지)
coding-expert         →     coding-expert         (Rails 전용으로 범위 축소)
uiux-expert           →     uiux-expert           (유지)
                      +     flutter-expert        (신규: Flutter/Dart 모바일)
                      +     tarot-domain-expert   (신규: 타로 도메인+콘텐츠)
```

**도메인:기술 비율 = 4:3** (psychology, mbti, enneagram, tarot-domain : coding, flutter, uiux)

### 권장안 2: 오케스트레이션 확장

1. **에이전트 조합 가이드 확장**: 위 테이블의 신규 4행 추가
2. **계층적 그룹화 도입**: 의사결정 트리에 "도메인 그룹 / 구현 그룹" 1차 분류 추가
3. **동시 활성 제한**: 하나의 워크플로우에서 동시 스폰 에이전트 수를 3-5개로 제한 (오케스트레이터 프롬프트에 명시)
4. **maxTurns 조정**: 오케스트레이터 30턴 유지, 신규 에이전트(flutter 25, tarot-domain 15)

### 권장안 3: 평가 체계 강화

1. **Code-based 게이트 추가**: `RSpec 통과` / `Flutter test 통과`를 평가루프 진입 전제 조건으로
2. **검증 매트릭스 확장**: tarot-domain → psychology 검증, flutter → uiux 크로스 리뷰 추가
3. **독립 QA 에이전트는 미도입**: 기존 전문가의 검증 역할 강화로 대응 (프로젝트 규모에 적합)

### 권장안 4: 단계적 실행

| 단계 | 작업 | 근거 |
|------|------|------|
| Phase 1 | flutter-expert 정의 및 테스트 | coding-expert 과부하 방지가 급선무 |
| Phase 2 | tarot-domain-expert 정의 및 테스트 | 타로 콘텐츠 작업 시작 시 |
| Phase 3 | 오케스트레이터 조합 가이드 확장 | 신규 에이전트 검증 후 |
| Phase 4 | Code-based 평가 게이트 구현 | 구현 작업 본격화 시 |
| Phase 5 | Agent Teams 실험 (안정화 시) | Anthropic 기능 안정화 모니터링 |

---

## References

### 내부 문서
- `docs/05_agent_design/007_Research_전문에이전트_구성_최종.md` -- 5개 에이전트 설계 원칙
- `docs/07_organizational_agents/008_Research_조직아키텍처_오케스트레이터_최종.md` -- 오케스트레이션 패턴
- `.claude/protocols/orchestration.md` -- 현행 오케스트레이션 프로토콜

### 외부 소스
- [O'Reilly: Designing Effective Multi-Agent Architectures](https://www.oreilly.com/radar/designing-effective-multi-agent-architectures/) -- 4가지 오케스트레이션 패턴, "prompting fallacy", 확장 법칙
- [Google's Eight Essential Multi-Agent Design Patterns (InfoQ)](https://www.infoq.com/news/2026/01/multi-agent-design-patterns/) -- 8가지 설계 패턴
- [Google Developers Blog: Multi-Agent Patterns in ADK](https://developers.googleblog.com/developers-guide-to-multi-agent-patterns-in-adk/) -- Coordinator, Fan-Out/Gather
- [Vellum: Best Practices for Building AI Multi Agent Systems](https://www.vellum.ai/blog/multi-agent-systems-building-with-context-engineering) -- 컨텍스트 엔지니어링, Anthropic 90.2% 성능 향상 사례
- [Anthropic: Demystifying Evals for AI Agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents) -- 3유형 평가자, pass@k/pass^k, 평가 통합
- [Claude Code Docs: Agent Teams](https://code.claude.com/docs/en/agent-teams) -- 3-5 팀원 권장, 팀원당 5-6 태스크, 공식 제약사항
- [Coding Agent Teams Outperform Solo Agents: 72.2% on SWE-bench](https://dev.to/nikita_benkovich_eb86e54d/coding-agent-teams-outperform-solo-agents-722-on-swe-bench-verified-4of5) -- Agyn 4역할 팀 구조
- [Microsoft: Designing Multi-Agent Intelligence](https://developer.microsoft.com/blog/designing-multi-agent-intelligence) -- 계층적 조직, 도메인 전문화
- [GuruSup: Multi-Agent Orchestration Guide](https://gurusup.com/blog/multi-agent-orchestration-guide) -- orchestrator-worker 70%, 도구 15-20개 임계점
- [ICLR 2025 Workshop: Dynamic LLM-Agent Network](https://openreview.net/forum?id=i43XCU54Br) -- 전문화 +64.6% vs 범용 -8.7%
- [Language Model Teams as Distributed Systems (arXiv)](https://arxiv.org/html/2603.12229) -- 중앙집중 vs 분산 트레이드오프
- [McKinsey: The Agentic Organization](https://www.mckinsey.com/capabilities/people-and-organizational-performance/our-insights/the-agentic-organization-contours-of-the-next-paradigm-for-the-ai-era) -- 교차 기능 스쿼드, M자형/T자형 역할
- [DevOps.com: Coding Agent Teams](https://devops.com/coding-agent-teams-the-next-frontier-in-ai-assisted-software-development/) -- frontend/backend/test 분리 패턴
- [Azure Architecture Center: AI Agent Orchestration Patterns](https://learn.microsoft.com/en-us/azure/architecture/ai-ml/guide/ai-agent-design-patterns) -- 대규모 에이전트 패턴
- [DEV Community: How to Build Multi-Agent Systems 2026 Guide](https://dev.to/eira-wexford/how-to-build-multi-agent-systems-complete-2026-guide-1io6) -- "75%의 기업이 복잡한 에이전트 구조 구축 실패"
- [Goose: 7 AI Agents Built an App in One Hour](https://block.github.io/goose/blog/2025/08/10/vibe-coding-with-goose-building-apps-with-ai-agents/) -- 7 에이전트 앱 빌더 사례
