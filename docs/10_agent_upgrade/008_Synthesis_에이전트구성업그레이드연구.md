---
id: "008"
title: "에이전트 구성 업그레이드 연구 — Synthesis Report"
category: report
status: archived
created: 2026-03-15
summary: >
  5개 관점(커뮤니티 페인포인트, 멀티에이전트 사례, Flutter 패턴, UX 평가, 타로 도메인)의 병렬 조사 결과를 종합.
  핵심 결론: 5→7개 에이전트 확장(flutter-expert + tarot-expert 신규), 별도 QA 에이전트 불필요,
  물리엔진은 flutter-expert에 통합, PRD 기능이 실제 커뮤니티 수요와 정확히 대응함.
keywords: [parallel-synthesis, research, agent-upgrade, tarot-mobile, multi-agent, flutter]
modules: [agent-design]
---

# 에이전트 구성 업그레이드 연구 — Synthesis Report

## Team Composition & Individual Reports

| # | Role | Agent Type | Report | Status |
|---|------|-----------|--------|--------|
| 1 | Community Pain Point Researcher | general-purpose | [003_Agent_커뮤니티페인포인트.md](./003_Agent_커뮤니티페인포인트.md) | complete |
| 2 | Multi-Agent Systems Researcher | general-purpose | [004_Agent_멀티에이전트사례.md](./004_Agent_멀티에이전트사례.md) | complete |
| 3 | Flutter Agent Pattern Researcher | general-purpose | [005_Agent_Flutter모바일패턴.md](./005_Agent_Flutter모바일패턴.md) | complete |
| 4 | UX Evaluation Researcher | general-purpose | [006_Agent_UX평가방법론.md](./006_Agent_UX평가방법론.md) | complete |
| 5 | Tarot Domain Validator | general-purpose | [007_Agent_타로도메인검증.md](./007_Agent_타로도메인검증.md) | complete |

---

## Cross-Analysis

### Common Findings

1. **5→7개 에이전트 확장 합의**: 004(멀티에이전트), 005(Flutter), 007(타로 도메인) 모두 독립적으로 `flutter-expert` + `tarot-expert` 신규 추가를 권장. 도메인:기술 = 4:3 비율.

2. **별도 QA/평가 에이전트 불필요**: 004(Generator-Critic 패턴으로 기존 전문가 검증 강화)와 006(uiux-expert 역할 확장 + 체크리스트 외부화) 모두 별도 평가 에이전트 미도입에 합의.

3. **물리 엔진 별도 에이전트 불필요**: 005가 상세 분석 후 "셔플 물리 = 중간 복잡도, Forge2D 기본 기능 수준"으로 판단. flutter-expert 단일 에이전트에 통합 가능.

4. **PRD 기능 ↔ 커뮤니티 수요 정확 대응**: 003의 커뮤니티 조사에서 영적 연결감 부족(Critical), 셔플 불신(High), 커스텀 덱 부재(Medium)가 PRD의 커스텀 셔플/CSPRNG, 커스텀 덱/JSON Schema, 소셜/바운티와 1:1 대응.

5. **"행동 규칙 > 역할 선언" 원칙의 일관적 적용**: 004(외부 검증), 005(Flutter AI rules 외부 파일), 006(체크리스트 외부화), 007(도메인 지식 외부 배치)이 모두 이 원칙을 따름.

### Conflicting Opinions

1. **평가 역할의 주체**:
   - 004: psychology-expert의 검증 역할 강화 + Code-based 게이트 추가
   - 006: uiux-expert의 "평가 모드" 별도 스폰 + 3-Tier 체크리스트
   - **Lead 판단**: 양립 가능. 콘텐츠 품질은 psychology-expert가, UX 품질은 uiux-expert가 담당하는 매트릭스 구조. 영역별 검증자를 지정하는 004의 "검증 매트릭스"가 006의 "평가 모드"와 결합 가능.

2. **uiux-expert의 모바일 확장 범위**:
   - 005: flutter-expert가 모바일 네이티브 UX도 포함 → uiux-expert는 웹 전용 유지
   - 006: uiux-expert의 기술 스택에 Flutter 위젯 추가
   - **Lead 판단**: uiux-expert는 "설계/평가"에 집중, flutter-expert는 "구현"에 집중하는 분리가 적절. uiux-expert가 Flutter 위젯 수준의 평가는 하되 구현은 flutter-expert에 위임.

### Synergy Effects

1. **커뮤니티(003) + 타로 도메인(007) 시너지**: 003에서 발견한 "영적 연결감 부족"이 007의 "의식적 행위로서의 셔플" 도메인 지식과 결합 → tarot-expert의 행동 규칙에 "해석은 내러티브이지 예측이 아니다"가 반영되어야 함.

2. **멀티에이전트(004) + UX 평가(006) 시너지**: 004의 "Generator-Critic 패턴"이 006의 "3-Tier 평가 프레임워크"와 결합 → Tier 1(자동) = Code-based 게이트, Tier 2(에이전트) = Generator-Critic, Tier 3(수동) = 사용자 테스트로 깔끔하게 매핑.

3. **Flutter(005) + 커뮤니티(003) 시너지**: 003의 "CSPRNG 투명성 요구" + 005의 "Dart Random() 32비트 취약점 발견" → flutter-expert가 이 보안 지식을 반드시 내장해야 하며, 이는 프로젝트의 핵심 차별화(셔플 알고리즘 공개)로 직결.

4. **타로(007) + MBTI/애니어그램 교차 활용**: 007에서 발견한 "코트 카드 16장 ↔ MBTI 16유형" 구조적 대응 → 성격 유형 + 타로 해석 결합이 프로젝트 고유 가치.

---

## Comprehensive Conclusion

5개 관점의 독립 연구가 놀라울 정도로 일관된 결론에 도달했다. **현재 5개 에이전트를 7개로 확장하되, flutter-expert(기술)와 tarot-expert(도메인)만 추가하고, 별도 QA/평가/물리엔진 에이전트는 신설하지 않는 것**이 최적이다.

### Key Findings

1. **[Critical] R-002-F1: 에이전트 5→7 확장** — flutter-expert + tarot-expert 신규. 도메인:기술 = 4:3. *(관점 2, 3, 5)*
2. **[Critical] R-002-F2: PRD 기능이 실제 수요와 1:1 대응** — 커스텀 셔플(영적 연결감 부족), 커스텀 덱(수요 증명), 소셜(Moonlight 사례). *(관점 1)*
3. **[Critical] R-002-F3: CSPRNG 보안 필수** — Dart Random() 32비트 취약점. Random.secure()/FortunaRandom 사용 의무. *(관점 1, 3)*
4. **[High] R-002-F4: 별도 QA 에이전트 불필요** — Generator-Critic 패턴으로 기존 전문가 강화 + 3-Tier 체크리스트 외부화. *(관점 2, 4)*
5. **[High] R-002-F5: 물리 엔진 별도 에이전트 불필요** — 셔플 물리 = 중간 복잡도, flutter-expert에 통합. *(관점 3)*
6. **[High] R-002-F6: uiux-expert 확장 필요** — Flutter 위젯 평가 + 타로 특수 UX 체크리스트(영적 연결감, 제의적 흐름). *(관점 4)*
7. **[High] R-002-F7: tarot-expert 행동 규칙 5개** — 내러티브 해석, 맥락 우선, 전통/현대 구분, 커스텀 덱 존중, 심리학 영역 비침범. *(관점 5)*
8. **[Medium] R-002-F8: 에이전트 간 계약 경계** — shared/openapi.yaml이 coding ↔ flutter 계약, psychology가 tarot 검증. *(관점 3, 5)*
9. **[Medium] R-002-F9: Code-based 평가 게이트 추가** — RSpec/Flutter test 통과를 평가루프 진입 전제. *(관점 2, 4)*
10. **[Medium] R-002-F10: 기술 스택 확정** — Riverpod 3.0 + MVVM + Drift/Hive + Forge2D + sensors_plus. *(관점 3)*

### Recommended Actions

1. flutter-expert 에이전트 정의 (Phase 1)
2. tarot-expert 에이전트 정의 (Phase 1)
3. uiux-expert 역할 확장 + 타로 체크리스트 외부화 (Phase 1)
4. 오케스트레이션 프로토콜 업데이트 — 에이전트 조합 가이드 4행 추가 (Phase 1)
5. Code-based 평가 게이트 구현 (Phase 2)
6. coding-expert 범위 축소 (Rails 전용 명시) (Phase 1)

---

## References

개별 보고서 참조 목록은 각 Agent 보고서에 포함. 중복 제거된 핵심 출처:

### 외부 연구
- ICLR 2025 Workshop: Dynamic LLM-Agent Network — 전문화 +64.6% vs 범용 -8.7%
- Google's Eight Multi-Agent Design Patterns (InfoQ, 2026.01)
- O'Reilly: Designing Effective Multi-Agent Architectures
- Anthropic: Demystifying Evals for AI Agents
- Zellic: Dart/Flutter CSPRNG Vulnerabilities

### 커뮤니티/시장
- The Tarot Forums (forum.thetarot.guru) — 다수 스레드
- TechCrunch: Moonlight Launch
- Deckible: 800+ 덱 생태계

### 기술
- Flutter AI Rules (docs.flutter.dev)
- Riverpod 3.0, Flame 1.29, Forge2D
- sensors_plus, pointycastle, Drift, Hive

### 내부 문서
- docs/05_agent_design/007_Research_전문에이전트_구성_최종.md
- docs/07_organizational_agents/008_Research_조직아키텍처_오케스트레이터_최종.md
- .claude/protocols/orchestration.md
- .claude/agents/mbti-expert.md, enneagram-expert.md
