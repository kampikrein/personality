---
id: "014"
title: "소통 프로토콜 & SOP — Synthesis Report"
category: report
status: archived
created: 2026-03-14
summary: >
  3개 관점(인계 포맷, SOP 행동 루프, 평가루프/HitL)의 병렬 조사 결과를 종합.
  핵심 결론: SOP의 Share 단계 = 인계 파일 생성으로 자연 통합. Analysis Framework을
  O→T→A→S 4단계로 확장. 평가루프에 severity 필드(blocker/major/minor) + HitL 7개 트리거.
  릴레이 감쇠 규칙으로 환각 캐스케이딩 구조적 차단.
keywords: [parallel-synthesis, research, SOP, 인계포맷, 평가루프, HitL, 환각방지]
modules: [.claude/agents, .claude/work-orders]
---

# 소통 프로토콜 & SOP — Synthesis Report

## Team Composition & Individual Reports

| # | 관점 | Agent Type | Report | Status |
|---|------|-----------|--------|--------|
| 1 | 인계 포맷 & 산출물 구조화 | general-purpose | [011_Agent_인계포맷설계.md](./011_Agent_인계포맷설계.md) | complete |
| 2 | SOP 행동 루프 인코딩 | general-purpose | [012_Agent_SOP행동루프.md](./012_Agent_SOP행동루프.md) | complete |
| 3 | 평가루프 & Human-in-the-Loop | general-purpose | [013_Agent_평가루프HitL.md](./013_Agent_평가루프HitL.md) | complete |

---

## Cross-Analysis

### Common Findings

3개 관점이 독립적으로 도달한 동일 결론:

1. **구조화 = 환각 방지** (관점 1, 2, 3): 자유 텍스트 소통 → 환각 캐스케이딩, 구조화된 포맷(verdict, confidence, SOP) → 방지. 사이클 1 연구(R-008)의 동일 결론을 3개 관점 모두에서 재확인.

2. **frontmatter 표준의 중심성** (관점 1, 2): 관점 1은 인계 파일의 필수 10필드를, 관점 2는 Share 단계의 산출물 frontmatter를 독립적으로 설계했으며, summary/key_findings/confidence/next_steps의 4개 핵심 필드가 정확히 일치.

3. **Think 단계 편중** (관점 2, 3): 현재 에이전트 프롬프트의 Analysis Framework은 Think만 다루고, 관점 2는 Observe/Share 부재를, 관점 3은 verdict 판정 기준의 Think 레벨 미정의를 각각 지적. 동일한 구조적 결함의 다른 측면.

### Conflicting Opinions

1. **인계 파일의 Markdown body 포함 여부**:
   - 관점 1: "YAML-only 포맷의 한계 → Markdown body 규정 필요" (복잡한 배경 설명을 담을 공간)
   - 관점 2: SOP Share의 산출물이 이미 Markdown + frontmatter이므로 인계 파일 자체는 YAML 메타데이터로 충분
   - **판단**: 인계 파일은 YAML-only로 유지하되, `full_document` 필드로 원본 산출물(Markdown body 포함)을 참조하는 관점 1의 설계를 채택. 인계 파일 = Level 3, 원본 = Level 1로 분리.

2. **confidence 감쇠 적용 범위**:
   - 관점 1: "릴레이마다 한 단계 감쇠" (모든 전달에 적용)
   - 관점 3: 평가루프 내에서는 검증자가 원본을 직접 읽으므로 감쇠 불필요
   - **판단**: 파이프라인(순차 전달)에서만 릴레이 감쇠 적용. 평가루프에서는 검증자가 원본에 직접 접근하므로 감쇠 미적용.

### Synergy Effects

1. **SOP Share + 인계 포맷 = 자동화된 인계**: 관점 2의 "Share 단계에서 산출물 저장" + 관점 1의 "인계 포맷 10필드"를 결합하면, **Share 단계의 산출물 frontmatter가 곧 인계 파일의 역할**을 한다. 별도의 인계 파일 생성 단계 불필요.

2. **역할별 검증 기준 + SOP Think 단계 = 정밀 평가**: 관점 3의 역할별 검증 기준 세트(PSY-01~07, CODE-01~05, UX-01~06)가 관점 2의 Think 단계 체크리스트를 **검증 관점에서 미러링**한다. 생성 에이전트의 Think 체크리스트와 검증 에이전트의 평가 기준이 동일 축을 공유.

3. **3단계 압축 + HitL 개입 포맷 = 효율적 사용자 소통**: 관점 1의 Level 2 요약이 관점 3의 HitL 개입 요청 포맷(상황 요약 + 이력 테이블 + 선택지)에 직접 활용 가능. 오케스트레이터가 Level 2로 읽은 내용을 그대로 사용자에게 제시.

---

## Comprehensive Conclusion

### Key Findings (우선순위 순)

1. **[Critical] SOP O→T→A→S 4단계가 에이전트 프롬프트의 핵심 구조 변경**: Analysis Framework을 SOP 행동 루프로 확장. Observe(입력 읽기), Think(기존 체크리스트), Act(산출물 생성), Share(인계+기록)의 4단계를 명시적으로 인코딩. *(관점 2)*

2. **[Critical] Share = 인계의 자연 통합**: Share 단계의 산출물 frontmatter에 인계 필수 4필드(summary, key_findings, confidence, next_steps)를 포함시키면 별도 인계 파일 불필요. *(관점 1, 2)*

3. **[Critical] 평가루프에 severity 필드(blocker/major/minor) 추가**: verdict 자동 판정 규칙 — blocker/major가 있으면 fail, minor만이면 conditional_pass, 없으면 pass. *(관점 3)*

4. **[High] HitL 7개 트리거 + 구조화된 개입 포맷**: max_iterations 도달, 점수 미개선, 동일 실패 반복, 도메인 충돌, 파괴적 작업, 유형 불명확, 법적 판단. 개입 시 상황 요약 + 이력 + 4개 선택지 제시. *(관점 3)*

5. **[High] 릴레이 감쇠 규칙**: 파이프라인에서 에이전트 간 전달 시 confidence가 한 단계씩 감쇠(high→medium→low). 3단계 이상 릴레이된 정보는 원본 직접 확인 강제. *(관점 1)*

6. **[High] 역할별 검증 기준 세트**: 학술(PSY-01~07), 코드(CODE-01~05), UX(UX-01~06). 검증 에이전트에 명시적 체크리스트 제공. *(관점 3)*

7. **[Medium] overall_score 필드 + previous_iterations 이력**: 점수 미개선 자동 감지를 위한 정량 지표. evaluation.yaml에 추가. *(관점 3)*

8. **[Medium] 오케스트레이터 SOP 마스터 섹션**: 워커 SOP의 입력(Observe 재료)과 출력(Share 목적지)을 관리하는 메타 섹션. *(관점 2)*

### Recommended Actions (우선순위 순)

1. **사이클 2 Plan에 반영**: 5개 에이전트 프롬프트의 Analysis Framework → SOP 행동 루프 확장
2. **사이클 2 Plan에 반영**: 오케스트레이터 프롬프트에 SOP 마스터 + HitL 트리거 + severity 판정 규칙 추가
3. **사이클 2 Plan에 반영**: evaluation.yaml에 severity, overall_score, previous_iterations 확장
4. **사이클 2 Plan에 반영**: handover.yaml에 필수 필드 5개 추가 (status, created, constraints, context_level, full_document)
5. **사이클 3에 전달**: 역할별 검증 기준 세트를 에이전트 프롬프트에 인코딩
6. **사이클 3에 전달**: confidence 판정 기준을 에이전트 프롬프트에 인코딩

---

## References

- [011_Agent_인계포맷설계.md](./011_Agent_인계포맷설계.md) — 산출물 패턴, 인계 포맷, 환각 방지
- [012_Agent_SOP행동루프.md](./012_Agent_SOP행동루프.md) — MetaGPT SOP, 프롬프트 매핑, 역할별 변형
- [013_Agent_평가루프HitL.md](./013_Agent_평가루프HitL.md) — 평가루프, HitL, 비용/품질
- docs/002_gemini_deep_research.md — MetaGPT SOP, 안티 패턴, 가드레일
- docs/001_gemini_deep_research.md — 5개 핵심 계층
- .claude/agents/orchestrator.md — 현재 오케스트레이터 구조
