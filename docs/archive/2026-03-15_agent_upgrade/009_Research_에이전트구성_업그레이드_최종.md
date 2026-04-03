---
id: "009"
type: research
title: "에이전트 구성 업그레이드 — 타로 모바일 확장 연구 (최종)"
created: 2026-03-15
traces_scope: "001"
summary: >
  5개 관점 병렬 연구 결과: 현재 5개 에이전트를 7개로 확장(flutter-expert + tarot-expert 신규).
  별도 QA/물리엔진 에이전트 불필요. PRD의 커스텀 셔플·덱·소셜이 실제 커뮤니티 수요와 1:1 대응.
  Dart CSPRNG 32비트 취약점 발견, Random.secure() 의무화. Riverpod 3.0 + MVVM + Drift/Hive 확정.
keywords: [agent-upgrade, tarot-mobile, flutter, multi-agent, community-research, ux-evaluation, tarot-domain]
---

# 에이전트 구성 업그레이드 — 타로 모바일 확장 연구 (최종)

## Research Overview

### Background & Motivation

PRD(docs/003_gemini_deep_research.md)가 정의한 타로 모바일 앱은 Flutter/Dart, 물리 엔진, 센서 API, 커스텀 덱, 소셜/바운티 등 현재 5개 에이전트가 전혀 커버하지 못하는 7개 영역을 요구한다. 스코프 문서(001)의 갭 분석에서 9개 PRD 영역 중 7개가 완전 공백(🔴)으로 확인되었다.

### Research Scope

**포함**: 타로앱 커뮤니티 생태계, AI 멀티에이전트 구성 사례, Flutter 모바일 에이전트 패턴, UX 평가 자동화, 타로 도메인 에이전트 필요성
**제외**: 실제 에이전트 구현, 코드 작성, Rails 백엔드 변경

### Research Perspectives

1. 타로 앱 커뮤니티 페인포인트
2. 멀티에이전트 시스템 구성 사례
3. Flutter/모바일 개발 에이전트 패턴
4. UX 평가/QA 에이전트 방법론
5. 타로 도메인 에이전트 필요성 검증

### Related Documents

- Checkpoint: [002_Research_에이전트구성_업그레이드.md](./002_Research_에이전트구성_업그레이드.md)
- Agent reports: [003](./003_Agent_커뮤니티페인포인트.md), [004](./004_Agent_멀티에이전트사례.md), [005](./005_Agent_Flutter모바일패턴.md), [006](./006_Agent_UX평가방법론.md), [007](./007_Agent_타로도메인검증.md)
- Synthesis: [008_Synthesis_에이전트구성업그레이드연구.md](./008_Synthesis_에이전트구성업그레이드연구.md)

---

## Perspective 1: 타로 앱 커뮤니티 페인포인트

### Status Analysis

Reddit(r/tarot, r/tarotpractice), App Store/Play Store 리뷰, 타로 커뮤니티 포럼(The Tarot Forums), 블로그에서 실제 사용자 불만과 수요를 수집했다. 경쟁앱 7개(Labyrinthos, Golden Thread, Galaxy Tarot, Mystic Mondays, Co-Star, Deckible, Moonlight)를 분석했다.

### Detailed Findings

**사용자 불만 8대 카테고리 (우선순위순)**:

| # | 페인포인트 | severity | 증거 |
|---|----------|----------|------|
| 1 | 영적 연결감 부족 | Critical | "랜덤 넘버 제너레이터" 느낌, 촉각적/의식적 경험 부재 |
| 2 | 셔플 알고리즘 불투명성 | High | TarotFlow 가중치 편향 63/100, 비공개 PRNG, 반복 카드 |
| 3 | 공격적 수익화 | High | Galaxy Tarot 페이월, Mystic Mondays 구독 전환 반발 |
| 4 | AI 해석의 비개인성 | Medium | "generic card definitions", 공감 부재 |
| 5 | 커스텀 덱/스프레드 부재 | Medium | Alleyman's Tarot 20k 판매, Deckible 800+ 덱 |
| 6 | 소셜/커뮤니티 부재 | Medium | Moonlight가 유일한 소셜 타로 플랫폼 |
| 7 | 데이터 안전성/이식성 | Low-Medium | Golden Thread 앱스토어 제거 시 데이터 소실 |
| 8 | 접근성 | Low-Medium | 스크린리더용 설명 부재 |

**PRD 기능 ↔ 커뮤니티 수요 대응**:

| PRD 기능 | 대응 페인포인트 | 증거 강도 |
|----------|---------------|----------|
| 커스텀 셔플(물리엔진, CSPRNG, 센서) | 영적 연결감 + 셔플 불신 | **강함** |
| 커스텀 덱 등록(JSON Schema) | 커스텀 덱 부재 | **강함** |
| 소셜/바운티 시스템 | 소셜 부재 | **중간** (프라이버시 우려 병존) |

### Caveats & Risks

- 소셜 기능은 프라이버시 퍼스트 설계 필수 (타로 리딩 = 매우 개인적)
- 수익화 모델에서 핵심 기능(저널, 기본 스프레드) 페이월 금지
- Co-Star의 부정적 사례 — 부정적/조작적 메시지, trolling 인정

### Summary

PRD의 3대 차별화 기능(커스텀 셔플, 커스텀 덱, 소셜)이 실제 커뮤니티의 상위 페인포인트와 정확히 대응한다. 특히 셔플 알고리즘 투명성(CSPRNG 공개)은 어떤 경쟁앱도 하지 않는 영역으로, 강력한 차별화 포인트.

---

## Perspective 2: 멀티에이전트 시스템 구성 사례

### Status Analysis

외부 연구(ICLR 2025, Google 8패턴, O'Reilly, Anthropic, Agyn 사례)와 내부 문서(기존 에이전트 설계 원칙, 오케스트레이션 프로토콜)를 비교 분석했다.

### Detailed Findings

**에이전트 분리 3가지 축**:

| 분리 축 | 장점 | 단점 | personality 적합도 |
|---------|------|------|-------------------|
| 기술 스택별 | 충돌 최소 | 도메인 맥락 단절 | 낮음 |
| 도메인별 | 깊은 전문성 | 구현 병목 | 중간 |
| **하이브리드** | 도메인 깊이 + 기술 집중 | 에이전트 수 증가 | **높음** |

**실증 데이터**:
- ICLR 2025: 전문화 에이전트 팀 +64.6% vs 범용 -8.7%
- Agyn: 4역할 팀 SWE-bench 72.2% (단일 에이전트 65.0% 대비 +7.2%p)
- Anthropic: Opus+Sonnet 병렬 구성 단일 대비 +90.2%
- 생산 환경 70%가 Orchestrator-Worker 패턴

**5→7 확장 구성안**:

```
도메인 에이전트 (4개):
  psychology-expert  — 학술 검증, 윤리 (유지)
  mbti-expert        — MBTI 문화, 문항 (유지)
  enneagram-expert   — 9유형, 성장 (유지)
  tarot-expert       — 타로 도메인+콘텐츠 (신규)

기술 에이전트 (3개):
  coding-expert      — Rails 백엔드 (유지, 범위 축소)
  flutter-expert     — Flutter/Dart 모바일 (신규)
  uiux-expert        — UX 설계/평가 (유지, 확장)
```

**복잡도 관리**: hub-and-spoke 구조로 5→7은 통신 채널 선형 증가. 계층적 그룹화(도메인/구현), 동시 활성 3-5개 제한.

### Caveats & Risks

- 7→8개 이상은 coordination overhead가 이득을 상쇄할 위험
- Agent Teams 실험적 기능이 안정화되면 peer-to-peer 메시징으로 효율 향상 가능

### Summary

하이브리드 분리(도메인 4 + 기술 3)가 프로젝트에 최적. 기존 Orchestrator-Worker 패턴이 업계 표준(70%)과 정확히 부합.

---

## Perspective 3: Flutter/모바일 개발 에이전트 패턴

### Status Analysis

Flutter 생태계, 모바일 개발 패턴, 물리엔진/센서/CSPRNG/오프라인-퍼스트 등 PRD 요구사항별 기술 스택을 조사했다.

### Detailed Findings

**기술 스택 확정**:

| 레이어 | 선택 | 근거 |
|--------|------|------|
| 상태관리 | Riverpod 3.0 | 2026 모던 표준, 오프라인 퍼시스턴스 내장, MVVM 호환 |
| 아키텍처 | MVVM + Clean Architecture | Feature-Based 구조, Repository 패턴 |
| 로컬 DB | Drift(관계형) + Hive(캐시) | 하이브리드 접근, riverpod_sqflite 통합 |
| HTTP | Dio + Retrofit | openapi-generator dart-dio로 자동 생성 |
| 물리 엔진 | Forge2D (via flame_forge2d) | Box2D 기반 안정적, 셔플 물리 충분 |
| 게임 레이어 | Flame 1.29+ | 카드 게임 튜토리얼(Klondike) 존재 |
| 센서 | sensors_plus | 가속도계, 자이로스코프, 공식 추천 |
| CSPRNG | Random.secure() + pointycastle | **Random() 32비트 취약점 발견** |
| 햅틱 | HapticFeedback + haptic_feedback | 셔플/플립/결과별 강도 차별화 |
| 렌더링 | Impeller (기본) | 드롭 프레임 90% 감소, 래스터화 50% 감소 |

**물리 엔진 분리 판단: 통합 권장**
- 셔플 물리 = "제한된 물리 시뮬레이션" (풀스케일 게임 아님)
- Forge2D 기본 기능 + 파라미터 조정 수준
- 분리 시 에이전트 간 컨텍스트 공유 비용 > 구현 복잡도

**CSPRNG 보안 취약점 (Critical)**:
- Dart `Random()` 기본 생성자는 32비트 엔트로피만 제공 (64비트로 보이지만 내부 마스킹)
- 실제 취약점 사례: Proton Wallet(~16분 오프라인 공격), Dart Tooling Daemon(~10초 브루트포스)
- `Random.secure()` 또는 pointycastle FortunaRandom 필수

**에이전트 간 계약 경계**:
```
Rails API → rswag → shared/openapi.yaml → openapi-generator dart-dio → Flutter Client
```

### Caveats & Risks

- GetX는 유지보수 위기로 절대 비추천
- WebAssembly 환경에서 CSPRNG 시드 하드코딩 문제 (2024.09 패치 완료)
- Flutter 공식 AI 규칙(rules.md) 에이전트에 반드시 통합 필요

### Summary

단일 flutter-expert가 PRD 전체(물리, 센서, CSPRNG, 햅틱, 오프라인, 애니메이션)를 커버 가능. shared/openapi.yaml이 coding-expert와의 유일한 계약 경계.

---

## Perspective 4: UX 평가/QA 에이전트 방법론

### Status Analysis

UX 평가 자동화 도구, 닐슨 히유리스틱, WCAG 모바일 접근성, Generator-Critic 패턴, 타로 앱 특수 UX 기준을 조사했다.

### Detailed Findings

**닐슨 10대 히유리스틱 자동화 수준**:
- 높음(3개): 시스템 상태 가시성, 일관성/표준, 도움말/문서
- 중간(4개): 사용자 제어, 에러 방지, 미적 디자인, 에러 복구
- 낮음(3개): 시스템-실세계 매칭, 재인지>회상, 유연성

**3-Tier 평가 프레임워크**:
- Tier 1 (자동, CI/CD): 접근성(대비, 탭 타겟, 시맨틱 라벨), 디자인 시스템 lint
- Tier 2 (LLM 보조): 히유리스틱, 감정 흐름, 제의적 UX, 인지 부하
- Tier 3 (수동 필수): 영적 연결감, 문화적 적합성, 윤리, 감정 반응

**타로 앱 특수 평가 기준 (5개 범주)**:
- SC: 영적 연결감 (셔플 에이전시, 공명, 관련성)
- IM: 몰입도 (다크 모드, 점진적 공개, 애니메이션 타이밍)
- RT: 제의적 UX (준비→셔플→드로우→해석 4단계)
- CD: 커스텀 덱 UX (인지 부하, 대량 업로드)
- SO: 소셜 UX (프라이버시, 위기 인식, 게이미피케이션 균형)

**별도 평가 에이전트 vs uiux-expert 확장**:
- 역할 80% 중복 → 확장이 효율적
- 단, 평가 모드에서는 별도 스폰 (Producer ≠ Critic)
- 체크리스트를 `.claude/checklists/` 외부 파일로 분리

### Caveats & Risks

- AI 타로 앱의 윤리적 반응성 점수 2.1/5.0 — 위기 상황 인식이 blocker급
- 자동화 가능 범위가 넓지만 "영적 연결감" 평가는 수동 필수

### Summary

별도 QA 에이전트 불필요. uiux-expert를 확장하되, 평가 체크리스트(닐슨/WCAG/타로 특수)를 외부화하고 "평가 모드" 별도 스폰으로 Generator-Critic 원칙 준수.

---

## Perspective 5: 타로 도메인 에이전트 필요성 검증

### Status Analysis

내부 에이전트 설계 원칙(도메인 지식 외부 배치), 기존 MBTI/애니어그램 에이전트 패턴, 타로 도메인 구조, 시장 규모를 분석했다.

### Detailed Findings

**도메인 복잡도 비교**:

| 차원 | MBTI | 애니어그램 | 타로 |
|------|------|-----------|------|
| 핵심 구성 | 16유형 | 9유형+날개+본능 (27 하위) | 78카드 × 정/역 × 위치 × 맥락 |
| 조합 공간 | ~256 (16×16) | ~729 (27×27) | **~6,000+** (단일 3카드 스프레드) |
| 생성적 활용 | 유형 설명, 호환성 | 성장 방향, 동기 탐색 | **해석, 스프레드 설계, 덱 검증** |
| 외부 체계 | 공식 MBTI 체계 | Riso-Hudson 등 | RWS, 토트, 마르세유 + 무한 오라클 |

**시장 검증**:
- 글로벌 타로 카드 시장: $161억+ (2026), CAGR 8.5%
- 한국 "점신" 앱: 1700만 다운로드
- Gen Z: 51% 타로 경험
- 디지털 타로 앱 다운로드: 2년간 72% 증가

**에이전트 분리 vs 문서화 비교**:

| 기준 | 문서화만 | 에이전트 분리 | 판단 |
|------|---------|-------------|------|
| 도메인 복잡도 | 정적 참조 가능 | 동적 판단 필요 | **분리** (조합 공간 6,000+) |
| 생성적 활용 | 불가 | 해석/설계/검증 | **분리** |
| 교차 도메인 | 단방향 참조 | 양방향 협업 | **분리** |
| 업데이트 빈도 | 드묾 | 빈번 (오라클 덱) | **분리** |
| 프로젝트 중요도 | 보조적 | 핵심 차별화 | **분리** |

**tarot-expert 행동 규칙 5개**:
1. 해석은 내러티브이지 예측이 아니다
2. 카드 조합의 맥락을 항상 우선한다 (위치+인접+질문 삼각 교차)
3. 전통 체계와 현대 해석을 구분하여 제시한다
4. 커스텀 덱은 창작자의 의도를 존중한다
5. 심리학 영역을 침범하지 않는다 (psychology-expert 위임)

**MBTI/애니어그램과의 관계: 보완적 독립**
- 코트 카드 16장 ↔ MBTI 16유형 구조적 대응
- 메이저 아르카나 원형 여정 ↔ 애니어그램 성장 방향
- "divination-expert"로 통합 시 전문성 희석 + 학술 신뢰성 오염 → 반드시 독립

### Caveats & Risks

- 유사과학 오인 리스크: tarot-expert와 psychology-expert의 의도적 분리로 관리
- 저작권: 공식 MBTI/애니어그램 검사와 동일하게, 타로 카드 이미지 저작권 주의 (RWS는 퍼블릭 도메인)

### Summary

tarot-expert 신설이 필요하다. 도메인 복잡도(조합 공간 6,000+), 생성적 판단 필요성, 시장 규모($161억+), 프로젝트 핵심 차별화 기능과의 직결이 근거. 행동 규칙 5개로 에이전트 정의.

---

## Cross-Analysis

### Inter-Perspective Relationships

```
관점1(커뮤니티) ────→ 관점5(타로): "영적 연결감" 불만이 tarot-expert 행동규칙 1에 반영
관점1(커뮤니티) ────→ 관점3(Flutter): CSPRNG 투명성 요구 + Dart 취약점 발견
관점2(멀티에이전트) ─→ 관점4(UX평가): Generator-Critic = 3-Tier의 Tier 2
관점3(Flutter) ────→ 관점2(멀티에이전트): 물리엔진 통합 → flutter-expert 단일 신규로 충분
관점4(UX평가) ────→ 관점5(타로): 제의적 UX 체크리스트(RT)가 타로 도메인 지식 필요
관점5(타로) ─────→ 관점2(멀티에이전트): 도메인 복잡도가 별도 에이전트 정당화
```

### Common Patterns

1. **외부화 원칙의 일관성**: 5개 관점 모두 "지식/규칙을 에이전트에 하드코딩하지 말고 외부 파일로 분리"를 권장
   - Flutter: AI rules 외부 파일
   - UX 평가: 체크리스트 외부 YAML
   - 타로: 카드 의미 DB 외부 배치
   - 멀티에이전트: 구조화된 컨텍스트 객체

2. **"구현 + 평가" 분리 원칙**: Producer ≠ Critic (별도 스폰)
   - 멀티에이전트(Generator-Critic)
   - UX 평가(평가 모드 별도 스폰)
   - 타로(psychology-expert 교차 검증)

3. **에이전트 수 제어**: 확장하되 과도하지 않게
   - 물리 엔진 별도 분리 기각
   - QA 에이전트 별도 신설 기각
   - 동시 활성 3-5개 제한

### Conflicting Items

1. **평가 역할 주체**: 004(psychology-expert 강화) vs 006(uiux-expert 확장) → **해결**: 영역별 매트릭스 — 콘텐츠=psychology, UX=uiux, 코드=coding/flutter
2. **모바일 UX 담당**: 005(flutter-expert 포함) vs 006(uiux-expert 확장) → **해결**: 구현=flutter, 설계/평가=uiux

## Comprehensive Conclusion

### 핵심 발견 (우선순위 순)

1. **[Critical] R-009-F1: 에이전트 5→7 확장** — `flutter-expert`(Flutter/Dart 모바일 전체) + `tarot-expert`(타로 도메인+콘텐츠) 신규. 도메인:기술 = 4:3. 전문화 에이전트 +64.6% 성능 검증. *(관점 2, 3, 5)*

2. **[Critical] R-009-F2: PRD ↔ 커뮤니티 수요 1:1 대응** — 커스텀 셔플(영적 연결감 Critical), 커스텀 덱(수요 강함), 소셜(수요 중간+프라이버시 우려). 셔플 알고리즘 투명성이 핵심 차별화. *(관점 1)*

3. **[Critical] R-009-F3: CSPRNG 보안 의무** — Dart `Random()` 32비트 취약점. `Random.secure()`/FortunaRandom 사용 필수. 알고리즘 투명성 공개가 차별화. *(관점 1, 3)*

4. **[High] R-009-F4: 별도 QA/평가 에이전트 불필요** — Generator-Critic으로 기존 전문가 강화 + 3-Tier 체크리스트 외부화 + uiux-expert "평가 모드" 별도 스폰. *(관점 2, 4)*

5. **[High] R-009-F5: 물리 엔진 별도 에이전트 불필요** — 셔플 물리 = 중간 복잡도. Forge2D + Flame으로 flutter-expert에 통합. *(관점 3)*

6. **[High] R-009-F6: uiux-expert 역할 확장** — Flutter 위젯 평가 + 타로 특수 체크리스트(SC/IM/RT/CD/SO) 외부화. 평가 모드 별도 스폰으로 Producer≠Critic 준수. *(관점 4)*

7. **[High] R-009-F7: tarot-expert 행동 규칙 5개 확정** — 내러티브 해석, 맥락 우선, 전통/현대 구분, 커스텀 덱 존중, 심리학 비침범. *(관점 5)*

8. **[Medium] R-009-F8: 에이전트 간 계약 경계** — `shared/openapi.yaml`이 coding↔flutter 계약, psychology가 tarot 검증, `.claude/checklists/`가 평가 기준 저장소. *(관점 3, 5)*

9. **[Medium] R-009-F9: Code-based 평가 게이트 추가** — RSpec/Flutter test 통과를 평가루프 진입 전제 조건으로. pass@k(능력) vs pass^k(일관성) 구분. *(관점 2, 4)*

10. **[Medium] R-009-F10: 기술 스택 확정** — Riverpod 3.0, MVVM+Clean Architecture, Drift+Hive, Forge2D, sensors_plus, Impeller. Flutter 공식 AI rules 통합. *(관점 3)*

## Unresolved Items

None — 모든 조사 항목이 해결되었다. 구현 세부사항(에이전트 파일 작성, 오케스트레이션 업데이트)은 사이클 2(설계 & 구현)에서 다룬다.

## Referenced File List

| File Path | Related Perspective | Role/Content |
|-----------|-------------------|--------------|
| docs/003_gemini_deep_research.md | 전체 | PRD (타로 모바일 앱 요구사항) |
| docs/10_agent_upgrade/001_Scope_에이전트구성업그레이드.md | 전체 | Scope (갭 분석, 사이클 정의) |
| docs/05_agent_design/007_Research_전문에이전트_구성_최종.md | 관점 2 | 기존 에이전트 설계 원칙 |
| docs/07_organizational_agents/008_Research_조직아키텍처_오케스트레이터_최종.md | 관점 2 | 오케스트레이션 설계 |
| .claude/protocols/orchestration.md | 관점 2, 4 | 현행 오케스트레이션 프로토콜 |
| .claude/agents/mbti-expert.md | 관점 5 | MBTI 에이전트 패턴 참조 |
| .claude/agents/enneagram-expert.md | 관점 5 | 애니어그램 에이전트 패턴 참조 |
| docs/05_agent_design/004_Agent_도메인지식.md | 관점 5 | 도메인 지식 외부 배치 원칙 |
