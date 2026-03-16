---
id: "001"
type: scope
title: "pe(parallel-execute)와 op(orchestration) 통합 — 일원체계 전환"
created: 2026-03-16
complexity: simple
research_needed: false
research_reason: "두 시스템 모두 현재 세션에서 이미 완전히 분석 완료"
auto_run: true
intent: >
  pe(parallel-execute 스킬)와 op(orchestration protocol)의 이원 체계를
  op 중심 일원체계로 통합한다. pe의 기능(Agent Teams 병렬실행, 점진적 문서작성,
  Communication Log, 종합 보고서)을 op에 흡수하고, 모든 에이전트 사용 판단을
  오케스트레이터가 통합 관할하도록 한다.
summary: >
  3개 파일 수정. orchestration.md 대폭 개편(pe 흡수), parallel-execute SKILL.md
  리다이렉트화, CLAUDE.md 트리거/정책 갱신. 에이전트 점진적 문서작성 내재화.
keywords: [orchestration, parallel-execute, unification, agent-protocol]
---

# pe-op 통합 — 일원체계 전환

## 작업 목표
- 이원 체계(op + pe) → 일원체계(op only) 전환
- 모든 에이전트가 점진적 문서작성(skeleton-first) 전략을 내재화
- 오케스트레이터가 단일/순차/평가루프/병렬 등 모든 실행 패턴을 통합 판단
- pe의 Agent Teams 통신, Communication Log, 종합 보고서 구조를 op에 흡수

## 접근 방향
op의 기존 구조(워크플로우 패턴 A-D + 평가루프 + 검증 기준)를 유지하면서,
pe의 병렬 실행(Pattern E)과 에이전트 산출물 프로토콜을 op에 통합.
pe SKILL.md는 orchestration.md로의 리다이렉트 래퍼로 축소.

## Research 판단
- **판단**: 불필요
- **근거**: 현재 세션에서 두 시스템 원문 완전 분석 완료
- **파이프라인**: S → P → I(V)

## 설계

### 변경 대상 (3파일)

| 파일 | 변경 유형 | 설명 |
|------|----------|------|
| `.claude/protocols/orchestration.md` | **Major rewrite** | pe 기능 전체 흡수. 약 190→450줄 |
| `.claude/skills/parallel-execute/SKILL.md` | **Redirect** | 기존 로직 제거, orchestration.md 참조 래퍼로 축소 |
| `CLAUDE.md` | **Update** | 오케스트레이션 트리거에 병렬실행 추가, 에이전트 정책 갱신 |

### orchestration.md 통합 구조안

```
1. 워크플로우 패턴 (확장)
   A: 순차 파이프라인
   B: 평가루프
   C: 하이브리드
   D: 단일 위임
   E: 병렬 실행 (NEW — from pe)

2. 실행 모드 결정 (NEW — from pe)
   - 단일 에이전트 vs 서브에이전트 병렬 vs Agent Teams

3. 에이전트 스폰 프로토콜 (통합)
   - 기존 5 필수항목 + pe의 7 Required Sections 통합

4. 에이전트 산출물 프로토콜 (NEW — from pe)
   - 스켈레톤 즉시 생성
   - 점진적 업데이트
   - Communication Log
   - 보고서 템플릿
   - 컨텍스트 복구 절차
   - 업데이트 빈도 가이드

5. 평가루프 프로토콜 (유지)

6. 검증 기준 (유지)
   PSY / CODE / UX / TAROT

7. 병렬 실행 프로토콜 (NEW — Pattern E 전용)
   - 작업 분해 전략
   - Agent Teams 통신 프로토콜
   - 종합 보고서 (Cross-Analysis + Communication Timeline)

8. 사용자 개입 트리거 (유지+확장)
```

### CLAUDE.md 변경 사항

- 오케스트레이션 트리거에 **병렬 실행** 추가
- 위임 판단 플로우 유지 (3단계: 직접→단일위임→오케스트레이션)
- 에이전트 도구 정책 참조 갱신 (pe 대신 op 참조)

### parallel-execute SKILL.md 변경 사항

- 전체 로직 제거
- `/parallel-execute` 호출 시 orchestration.md를 Read하여 Pattern E 적용하도록 리다이렉트
- 약 515줄 → 약 30줄

## 체크포인트 & 컨텍스트 관리

| 체크포인트 | 산출물 | 컨텍스트 조치 |
|-----------|--------|-------------|
| /scope 완료 | 이 문서 | 유지 — 탐색 파일 = 수정 파일 |
| /makeplan 완료 | Plan 문서 | 유지 — plan에서 읽은 파일 = impl에서 수정할 파일 |
| /implementation 완료 | 수정된 3파일 | END |
