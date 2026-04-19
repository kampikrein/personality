---
id: "010"
type: scope
title: "에이전트 페르소나 & 평가 프레임워크 구현"
created: 2026-04-07
traces_brief: "001"
complexity: simple
research_needed: false
research_reason: "009 Synthesis에 모든 데이터 확정됨 — 페르소나 프로필, 평가 차원, 가중치, 프롬프트 템플릿"
auto_run: false
effort_mode: bypass
tdd_mode: false
uncertainty_level: low
intent: >
  009 Synthesis에서 확정된 13개 페르소나와 7차원 평가 프레임워크를
  Agent() 디스패치로 즉시 실행 가능한 구조화된 파일로 구현한다.
summary: >
  13개 페르소나 MD 파일 + 평가 프레임워크 + 인덱스 생성. docs/11_global_tarot_market/personas/ 하위.
  코드 변경 없음. 구현 완료 시 Agent()로 13개 페르소나 평가를 바로 실행 가능.
keywords: [persona, agent, implementation, evaluation-framework]
---

# 에이전트 페르소나 & 평가 프레임워크 구현

## 작업 목표

009 Synthesis에서 확정된 13개 페르소나 + 7차원 평가 프레임워크를 실행 가능한 파일 구조로 구현.

**성공 기준**: Agent() 호출 시 페르소나 파일을 Read → 프롬프트에 주입 → 구조화된 평가 결과 산출 가능.

## 접근 방향

각 페르소나를 자기 완결적 MD 파일로 생성. 파일에 포함되는 정보:
1. 페르소나 프로필 (009 섹션 3.2 데이터)
2. 해당 권역 시장/서비스/문화 레퍼런스 요약 (003~005에서 추출)
3. 평가 프레임워크 (차원, 가중치, 점수 기준) (009 섹션 4)
4. 평가 프롬프트 템플릿 (009 섹션 4.4)

## Research 판단
- **판단**: 불필요
- **근거**: 009 Synthesis가 모든 설계를 완료. 파일 형식 변환만 필요.
- **파이프라인**: Agent(makeplan) → Agent(impl) → Agent(verify)

## 설계

### 파일 구조
```
docs/11_global_tarot_market/personas/
  _index.md           — 13개 페르소나 목록 + 평가 실행 가이드
  _framework.md       — 7차원 평가 프레임워크 (공통)
  KR-01_취준생.md
  KR-02_연애탐색자.md
  KR-03_경력전환.md
  US-01_리추얼러.md
  US-02_틱톡팬.md
  US-03_의미탐색자.md
  JP-01_운세습관자.md
  JP-02_연애심층.md
  CN-01_소홍슈탐색.md
  CN-02_AI얼리어답터.md
  CN-03_깊은상담.md
  EU-01_학습수집가.md
  EU-02_영적실천자.md
```

### 각 페르소나 파일 구조
```markdown
---
persona_id: "KR-01"
region: KR
name: "불안한 취준생"
service_type: "AI 해석형"
usage_style: "이벤트형"
motivation: "심리적 위안"
eval_type: "이벤트+위안"
---

# 페르소나 프로필
{전체 프로필 데이터 — 009 섹션 3.2}

# 권역 레퍼런스
{해당 권역 시장·서비스·문화 요약 — 003~005에서 추출, 평가 맥락용}

# 평가 가중치
{해당 eval_type의 7차원 가중치 — 009 섹션 4.2}

# 평가 프롬프트
{Agent() 디스패치 시 사용할 완전한 프롬프트 — 009 섹션 4.4 적용}
```

### 대상 파일
| 카테고리 | 파일 | 설명 |
|---------|------|------|
| New | `personas/_index.md` | 페르소나 목록 + 실행 가이드 |
| New | `personas/_framework.md` | 7차원 평가 프레임워크 공통 |
| New | `personas/KR-01_*.md` ~ `EU-02_*.md` (13개) | 개별 페르소나 |
| Reviewed | `009_Synthesis_global_tarot_market.md` | 데이터 소스 |
| Reviewed | `003~005_Research_*.md` | 권역 레퍼런스 소스 |

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 179s | 398342 |
| 2 | user-ai-exchange | 35s | 208410 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 427s |
| Total Tokens | 606752 |
| Input Tokens | 22 |
| Output Tokens | 7539 |
| Cache Read | 522247 |
| Cache Creation | 76944 |
