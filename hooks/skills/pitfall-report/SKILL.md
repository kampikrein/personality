---
name: pitfall-report
description: "주어진 기술/라이브러리/패턴에 대해 웹에서 알려진 오류, 버그, 주의사항을 조사하고 예방 보고서를 생성합니다."
---

# Pitfall Report Generator

## Overview

기술/라이브러리/패턴 도입 시 시행착오를 줄이기 위해, 웹에서 알려진 오류·버그·주의사항을 폭넓게 조사하여 구조화된 예방 보고서를 생성한다.

## Usage

```
/pitfall-report <topic>
/pitfall-report <topic> --version <version>
/pitfall-report <topic> --focus <specific-area>
```

인자 없이 호출 시 → AskUserQuestion으로 주제를 질문한다.

## Execution Steps

### Step 0: 입력 분석

1. **topic 파싱**: 인자에서 topic, `--version`, `--focus` 옵션을 추출한다.
   - topic이 없으면 AskUserQuestion으로 "어떤 기술/라이브러리/패턴을 조사할까요?" 질문
   - topic이 모호하면(예: "JavaScript") 범위 좁히기 질문 (예: "JavaScript의 어떤 측면을 조사할까요?")
2. **검색 쿼리명 결정**: topic을 영어 검색 쿼리 키워드로 변환 (보고서 제목은 한국어)
3. **범위 판단**:
   - **broad** (프레임워크급: React, Vue, Express 등) → 6 에이전트
   - **specific** (특정 API, 단일 기능 등) → 4 에이전트
4. **글로벌 순번 결정**: `docs/` 디렉토리 전체에서 기존 `NNN_` 패턴 파일의 최대 번호를 찾아 +1

### Step 1: 병렬 에이전트 실행

Task tool로 에이전트를 **동시에** 실행한다. 모든 에이전트는 `subagent_type: "general-purpose"`로 실행한다.

| # | 역할 | 검색 대상 | 실행 조건 |
|---|------|----------|----------|
| 1 | **공식 문서 경고** | 공식 docs warnings, known issues, migration guide | 항상 |
| 2 | **GitHub Issues** | github.com 버그 리포트, 많이 반응된 이슈 | 항상 |
| 3 | **Stack Overflow** | 빈출 문제, 오해하기 쉬운 동작 | 항상 |
| 4 | **블로그/커뮤니티** | gotchas, lessons learned, 한국어 소스 포함 | 항상 |
| 5 | **Breaking Changes** | 버전별 비호환 변경, deprecated API | broad만 |
| 6 | **성능/보안 함정** | memory leak, CVE, 성능 bottleneck | broad만 |

#### 에이전트 프롬프트 템플릿

각 에이전트에 아래 구조의 프롬프트를 전달한다. `{topic}`, `{english_query}`, `{version}`, `{focus}`, `{role}`, `{queries}` 를 실제 값으로 치환한다.

```
You are pitfall research agent #{number} — {role}.

## Task
주제 "{topic}" 에 대해 {role} 관점에서 알려진 함정, 버그, 주의사항을 조사하라.
{version 있으면: 특히 버전 {version}에 집중하라.}
{focus 있으면: 특히 "{focus}" 영역에 집중하라.}

## 검색 쿼리 (아래를 시작점으로, 필요시 적응적 변형 가능)
{queries — 3-4개 사전 정의 쿼리}

## 조사 방법
1. WebSearch로 각 쿼리 검색
2. 검색 결과 중 가장 유용한 2-3개 페이지를 WebFetch로 정독
3. 검색 결과가 부족하면 쿼리를 변형하여 1회 재시도
4. WebFetch 실패 시 검색 스니펫만으로 정보 추출

## 출력 형식
반드시 아래 형식으로 반환하라. 마커를 정확히 포함할 것.
한국어로 작성하되, 기술 용어는 영어를 유지한다.

---START_REPORT---
## {섹션 제목}

### {N}.1 {함정 제목}
- **문제**: 구체적 설명
- **발생 조건**: 언제/왜 발생하는가
- **해결책**: 방지 또는 우회 방법
- **심각도**: Critical / High / Medium / Low
- **출처**: [링크텍스트](URL)

### {N}.2 {함정 제목}
...

(발견한 함정 모두 나열)
---END_REPORT---
```

#### 에이전트별 검색 쿼리 가이드

**에이전트 1 — 공식 문서 경고**:
- `{english_query} official documentation known issues`
- `{english_query} migration guide breaking changes`
- `{english_query} common mistakes official docs`
- `{english_query} caveats warnings documentation`

**에이전트 2 — GitHub Issues**:
- `site:github.com {english_query} bug label:bug sort:reactions`
- `site:github.com {english_query} issue gotcha unexpected behavior`
- `site:github.com {english_query} common issues workaround`

**에이전트 3 — Stack Overflow**:
- `site:stackoverflow.com {english_query} common mistakes`
- `site:stackoverflow.com {english_query} gotcha unexpected behavior`
- `site:stackoverflow.com {english_query} pitfall error`
- `{english_query} frequently asked questions problems`

**에이전트 4 — 블로그/커뮤니티**:
- `{english_query} gotchas lessons learned`
- `{english_query} mistakes to avoid tips`
- `{english_query} 주의사항 실수 함정` (한국어 검색)
- `{english_query} things I wish I knew before`

**에이전트 5 — Breaking Changes** (broad만):
- `{english_query} breaking changes changelog`
- `{english_query} deprecated API removal`
- `{english_query} version upgrade migration issues`
- `{english_query} backward incompatible changes`

**에이전트 6 — 성능/보안 함정** (broad만):
- `{english_query} memory leak performance issues`
- `{english_query} security vulnerability CVE`
- `{english_query} performance bottleneck benchmark`
- `{english_query} security best practices common mistakes`

### Step 2: 결과 통합

1. 모든 에이전트의 응답을 수집한다.
2. 각 응답에서 `---START_REPORT---` / `---END_REPORT---` 사이의 내용을 추출한다.
   - 마커가 없으면 전체 응답을 보고서 본문으로 사용한다.
3. 에이전트가 실패한 경우, 해당 섹션에 "조사 실패 — 에이전트 응답 없음" 표시.
4. 중복 항목을 제거하고, 전체 함정에 섹션별 일련번호를 부여한다.
5. 각 함정의 심각도를 검증하고 일관성 있게 조정한다:
   - **Critical**: 데이터 손실, 보안 취약점, 프로덕션 장애 가능
   - **High**: 디버깅 어려운 버그, 성능 심각 저하
   - **Medium**: 예상과 다른 동작, 개발 경험 저하
   - **Low**: 사소한 불편, 문서 부족

### Step 3: 보고서 생성

**출력 경로**: `docs/research/NNN_pitfall_{topic_slug}.md`
- `docs/research/` 없으면 Bash로 `mkdir -p docs/research/` 실행
- `NNN` = docs/ 전체 글로벌 순번 (Step 0에서 결정)
- `topic_slug` = topic을 영어 lowercase, 공백→underscore, 특수문자 제거

#### 보고서 템플릿

```markdown
# NNN. {Topic} — 알려진 함정 및 주의사항 보고서

> **문서 유형**: Pitfall Research Report
> **작성일**: YYYY-MM-DD
> **주제**: {topic}
> **버전**: {version 또는 "최신"}
> **조사 범위**: {broad 또는 specific}
> **조사 에이전트**: {실행된 에이전트 수}개

---

## 요약

{3-5줄 요약. 가장 중요한 Top 3 함정을 강조한다.}

---

## 1. 공식 문서 경고

{에이전트 1 결과. 각 항목은 아래 형식:}

### 1.1 {함정 제목}
- **문제**: 구체적 설명
- **발생 조건**: 언제/왜
- **해결책**: 방지/우회 방법
- **심각도**: Critical / High / Medium / Low
- **출처**: [링크](URL)

## 2. GitHub 빈출 이슈

{에이전트 2 결과}

## 3. Stack Overflow 빈출 문제

{에이전트 3 결과}

## 4. 블로그/커뮤니티 Gotchas

{에이전트 4 결과}

## 5. 버전별 Breaking Changes

{broad인 경우 에이전트 5 결과, specific이면 이 섹션 생략}

## 6. 성능 및 보안 함정

{broad인 경우 에이전트 6 결과, specific이면 이 섹션 생략}

---

## 체크리스트: 도입 전 확인사항

{심각도 High 이상 항목만 추출하여 체크리스트로 정리}

- [ ] {함정 제목} — {한 줄 요약} (섹션 N.M)
- [ ] ...

---

## 전체 참고 자료

{모든 출처 URL을 중복 제거하여 나열}

1. [제목](URL)
2. ...
```

### Step 4: 사용자 보고

보고서 파일을 Write tool로 저장한 뒤, 사용자에게 아래 내용을 출력한다:

1. **파일 경로**: 생성된 보고서의 전체 경로
2. **함정 총 개수**: 발견된 함정의 총 수
3. **심각도 분포**: Critical / High / Medium / Low 각 몇 건
4. **Top 3 주의사항**: 가장 중요한 3가지를 간략히 제시

## Error Handling

| 상황 | 대응 |
|------|------|
| 에이전트 실패 | 나머지 에이전트 결과로 보고서 생성, 실패 섹션에 "조사 실패" 표시 |
| 검색 결과 부족 | 쿼리 변형 1회 재시도, 그래도 부족하면 "제한된 결과" 표시 |
| 주제 모호 | AskUserQuestion으로 범위 좁히기 질문 |
| WebFetch 실패 | 검색 스니펫만으로 정보 추출 |
| START/END 마커 누락 | 전체 응답을 보고서 본문으로 사용 |
| docs/ 디렉토리 없음 | Bash로 `mkdir -p docs/research/` 실행 |

## Key Principles

- **병렬 우선**: 모든 에이전트를 동시에 실행하여 속도를 극대화
- **한국어 보고서**: 기술 용어는 영어 유지, 나머지는 한국어로 작성
- **구조화된 출력**: 모든 함정은 동일한 5-field 형식 (문제/발생조건/해결책/심각도/출처)
- **내결함성**: 일부 에이전트 실패 시에도 나머지로 보고서 완성
- **글로벌 순번 준수**: docs/ 전체의 NNN 순번 체계를 따름
- **중복 제거**: 여러 에이전트가 같은 함정을 발견하면 하나로 통합
