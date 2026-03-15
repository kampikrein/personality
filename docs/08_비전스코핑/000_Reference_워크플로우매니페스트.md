---
summary: "파운더 비전 기반 제품 스코핑 워크플로우 매니페스트"
type: Reference
source: ".claude/work-orders/WF-20260315-비전스코핑/_manifest.yaml"
created: "2026-03-15"
status: completed
---

# 파운더 비전 기반 제품 스코핑

- **워크플로우 ID**: WF-20260315-비전스코핑
- **패턴**: A (파이프라인 — 병렬 스코핑 → 종합)
- **생성일**: 2026-03-15
- **상태**: completed

## 설명

파운더의 비전(docs/memo.md)을 기반으로 5개 전문 에이전트가 각자 관점에서
실행 가능한 스코프를 분석하고, 오케스트레이터가 종합하여 로드맵을 도출한다.

## 실행 단계

| Step | 파일 | 에이전트 | 설명 |
|------|------|---------|------|
| 1 | 001_Agent_콘텐츠깊이전략.md | mbti-expert | 가벼운→무거운 콘텐츠 깊이 단계 설계, 리텐션 콘텐츠 전략 |
| 2 | 002_Agent_동기기반콘텐츠전략.md | enneagram-expert | 애니어그램 동기 탐색을 활용한 깊이 콘텐츠, MBTI 보완 전략 |
| 3 | 003_Agent_학술차별화전략.md | psychology-expert | 심리학적 깊이로 차별화하는 콘텐츠 전략, 학술 근거 기반 리텐션 |
| 4 | 004_Agent_UX리텐션설계.md | uiux-expert | 스와이프/쇼츠형 UX, 캐릭터 인터랙션, 감정 흐름 기반 리텐션 |
| 5 | 005_Agent_기술실현성평가.md | coding-expert | 현재 코드베이스 대비 비전 실현 가능성, 기술 로드맵 |
| 6 | 006_Synthesis_종합스코프.md | orchestrator | 5개 분석 종합 → 단계별 실행 로드맵 도출 |
