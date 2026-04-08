---
type: index
title: "글로벌 타로 앱 에이전트 페르소나 인덱스"
version: 1
persona_count: 13
summary: >
  5개 권역(KR/US/JP/CN/EU) 13개 에이전트 페르소나 마스터 인덱스.
---

# 에이전트 페르소나 인덱스

## 페르소나 목록

| ID | 파일명 | 이름 | 권역 | 평가유형 | 동기 | 스타일 |
|----|--------|------|------|----------|------|--------|
| KR-01 | KR-01_취준생.md | 불안한 취준생 | KR | 이벤트+위안 | 심리적 위안 | 이벤트형 |
| KR-02 | KR-02_연애탐색자.md | 연애 타로 탐색자 | KR | 소셜+호기심 | 호기심/오락 | 소셜형 |
| KR-03 | KR-03_경력전환.md | 경력 전환 고민자 | KR | 이벤트+의사결정 | 의사결정 보조 | 이벤트형 |
| US-01 | US-01_리추얼러.md | 셀프케어 리추얼러 | US | 일상+습관 | 자기 탐구 | 일상습관형 |
| US-02 | US-02_틱톡팬.md | TikTok 타로 팬 | US | 소셜+호기심 | 소셜/오락 | 소셜형 |
| US-03 | US-03_의미탐색자.md | 위기 시 의미 탐색자 | US | 이벤트+의사결정 | 심리적 위안 | 이벤트형 |
| JP-01 | JP-01_운세습관자.md | 아침 운세 습관자 | JP | 일상+습관 | 호기심/습관 | 일상습관형 |
| JP-02 | JP-02_연애심층.md | 연애 고민 심층 이용자 | JP | 이벤트+위안 | 심리적 위안 | 이벤트형 |
| CN-01 | CN-01_소홍슈탐색.md | 소홍슈 타로 탐색자 | CN | 이벤트+위안 | 심리적 위안 | 소셜형 |
| CN-02 | CN-02_AI얼리어답터.md | AI 점술 얼리어답터 | CN | 소셜+호기심 | 호기심/기술 흥미 | 이벤트형 |
| CN-03 | CN-03_깊은상담.md | 전환기 깊은 상담 이용자 | CN | 이벤트+의사결정 | 의사결정 보조 | 이벤트형 |
| EU-01 | EU-01_학습수집가.md | 타로 학습자/수집가 | EU | 학습+탐구 | 학습 | 학습형 |
| EU-02 | EU-02_영적실천자.md | 영적 실천자 | EU | 일상+습관 | 의식/영적 실천 | 일상습관형 |

## 평가 유형별 그룹

| 평가 유형 | 페르소나 | 공통 특성 |
|----------|---------|----------|
| 이벤트+위안 | KR-01, JP-02, CN-01 | 위기 상황에서 단발적으로 위안을 구함. AI 해석 품질(25%)과 UX 의식 경험(20%)이 핵심 |
| 일상+습관 | US-01, JP-01, EU-02 | 일상적으로 타로를 루틴에 통합. UX 의식 경험(25%)과 개인화/맥락 지속(20%)이 핵심 |
| 소셜+호기심 | KR-02, US-02, CN-02 | 재미·공유 중심 가벼운 이용. 가격 가치(30%)와 신뢰/프라이버시(25%)가 핵심 |
| 학습+탐구 | EU-01 | 타로 자체를 배우고 수집하는 학습 동기. 콘텐츠 깊이(30%)가 압도적 핵심 |
| 이벤트+의사결정 | KR-03, US-03, CN-03 | 중요 결정 앞에서 심층 해석을 구함. AI 해석 품질(25%)과 개인화(15%)+신뢰(15%)가 핵심 |

## 평가 실행 가이드

### 단일 페르소나 평가

```
Agent():
  1. Read("docs/11_global_tarot_market/personas/{페르소나_파일}.md")
  2. 페르소나 파일의 "## 4. 평가 프롬프트" 섹션의 프롬프트를 실행
  3. {서비스_설명} 자리에 평가 대상 서비스 정보를 주입
  4. 산출물을 YAML로 반환
```

**디스패치 프롬프트 예시**:
```
Read("docs/11_global_tarot_market/personas/KR-01_취준생.md")

이 파일은 타로 앱 서비스 평가용 에이전트 페르소나이다.
당신은 이 페르소나가 되어 아래 서비스를 평가한다.

## 평가 대상 서비스
{서비스 설명 — 기능 목록, UI 플로우, 가격 정보 등}

파일의 "## 4. 평가 프롬프트" 섹션에 있는 프롬프트를 실행하라.
{서비스_설명} 자리에 위 서비스 설명을 삽입하라.
산출물을 지정된 YAML 형식으로 반환하라.
```

### 전체 13개 페르소나 일괄 평가

```
메인 에이전트가 13개 Agent()를 디스패치:
  for each persona_file in personas/*-*.md:
    Agent():
      - Read(persona_file)
      - 평가 프롬프트 실행 (서비스 설명 주입)
      - YAML 산출물 반환
  메인 에이전트가 13개 YAML 결과를 통합
```

### 권역별 부분 평가

특정 권역만 평가할 때:
```
# KR 권역만 평가 (3개 페르소나)
for persona_file in [KR-01_취준생.md, KR-02_연애탐색자.md, KR-03_경력전환.md]:
  Agent(): Read + 평가 + YAML 반환

# 특정 평가 유형만 (예: 이벤트+위안)
for persona_file in [KR-01_취준생.md, JP-02_연애심층.md, CN-01_소홍슈탐색.md]:
  Agent(): Read + 평가 + YAML 반환
```

### 산출물 통합 구조

```yaml
evaluation_run:
  service: "{서비스명}"
  date: "{날짜}"
  results:
    - {KR-01 YAML}
    - {KR-02 YAML}
    - {KR-03 YAML}
    - {US-01 YAML}
    - {US-02 YAML}
    - {US-03 YAML}
    - {JP-01 YAML}
    - {JP-02 YAML}
    - {CN-01 YAML}
    - {CN-02 YAML}
    - {CN-03 YAML}
    - {EU-01 YAML}
    - {EU-02 YAML}
  summary:
    average_weighted_total: N.NN
    by_region:
      KR: N.NN
      US: N.NN
      JP: N.NN
      CN: N.NN
      EU: N.NN
    strongest_dimension: "D{N}"
    weakest_dimension: "D{N}"
    retention_positive: N/13
    retention_conditional: N/13
    retention_negative: N/13
```

## 참조 문서

- 평가 프레임워크 공통 정의: `_framework.md`
- 데이터 소스: `009_Synthesis_global_tarot_market.md`, `003_Research_market_overview.md`, `004_Research_service_taxonomy.md`, `005_Research_user_culture.md`
- 설계 근거: `010_Scope_persona_implementation.md`, `011_Plan_persona_implementation.md`

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 0s | 0 |
| 2 | user-ai-exchange | 273s | 444450 |
| 3 | user-ai-exchange | 217s | 617029 |
| 4 | user-ai-exchange | 54s | 485662 |
| 5 | user-ai-exchange | 9s | 147124 |
| 6 | user-ai-exchange | 95s | 881926 |
| 7 | user-ai-exchange | 13s | 250234 |
| 8 | user-ai-exchange | 8s | 169214 |
| 9 | user-ai-exchange | 18s | 258719 |
| 10 | user-ai-exchange | 46s | 728614 |
| 11 | user-ai-exchange | 21s | 93768 |
| 12 | user-ai-exchange | 70s | 1006865 |
| 13 | user-ai-exchange | 90s | 538958 |
| 14 | user-ai-exchange | 98s | 1083545 |
| 15 | user-ai-exchange | 77s | 1008374 |
| 16 | user-ai-exchange | 30s | 773186 |
| 17 | user-ai-exchange | 12s | 260951 |
| 18 | user-ai-exchange | 22s | 527531 |
| 19 | user-ai-exchange | 319s | 7708985 |
| 20 | user-ai-exchange | 101s | 1277108 |
| 21 | user-ai-exchange | 14s | 162116 |
| 22 | user-ai-exchange | 125s | 1579522 |
| 23 | user-ai-exchange | 14s | 311123 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 89640s |
| Total Tokens | 20315004 |
| Input Tokens | 221 |
| Output Tokens | 61167 |
| Cache Read | 19710177 |
| Cache Creation | 543439 |
