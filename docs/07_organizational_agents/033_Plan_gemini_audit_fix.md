---
id: "033"
type: plan
title: "Gemini MAS 이론 감사 갭 보수 — Backstory·가드레일·기억·예시"
created: 2026-03-17
traces_scope: "026"
traces_research: "032"
summary: >
  연구(032)에서 식별한 High 1건(Backstory) + Medium 2건(실패 기억, 원문 보존) +
  Low 2건(PII, 입출력 예시)을 해소한다. 7개 에이전트 파일 + orchestration.md 수정.
keywords: [backstory, persona, guardrail, failure-memory, pii, examples, gemini-audit]
---

# 033 — Gemini MAS 이론 감사 갭 보수

## Goal

연구(032)에서 Gemini MAS 이론 관점으로 식별한 실행 가능한 갭 5건을 해소한다.
에이전트의 페르소나 깊이(Backstory), 프로토콜의 안전성(원문 보존, 실패 기억),
가드레일의 균일성(PII), 태스크 정의의 구체성(입출력 예시)을 강화한다.

## Scope

### Included
| # | Item | Finding | Description |
|---|------|---------|-------------|
| 1 | Backstory 추가 | R-032-F1 (High) | 7개 에이전트에 2-3줄 서사적 배경 |
| 2 | 원문 보존 가드레일 | R-032-F5 (Low) | orchestration.md에 [ORIGINAL] 태그 규칙 |
| 3 | 실패 기억 축적 프로토콜 | R-032-F3 (Medium) | 평가루프 fail시 agent-memory 자동 기록 규칙 |
| 4 | PII 보호 균일화 | R-032-F6 (Low) | psychology/tarot/uiux에 PII 가드레일 |
| 5 | 산출물 입출력 예시 | R-032-F7 (Low) | 대표 3개 에이전트의 Act 섹션에 예시 추가 |

### Excluded
| Item | Reason/Timeline |
|------|-----------------|
| 적대적 검증 강화 (R-032-F2) | 평가루프 아키텍처 재설계 필요. 별도 사이클 |
| Perception 계층 (R-032-F4) | 프로젝트 목적상 의도적 미구현 유지 |
| 나머지 4개 에이전트 입출력 예시 | 대표 3개(psychology, coding, tarot) 패턴 확립 후 후속 |

## Structural Decisions

> No structural decisions required — 모든 변경이 기존 파일에 섹션/텍스트 추가.

---

## File Change Summary

### Modified Files
| # | File Path | Change Description |
|---|-----------|-------------------|
| 1 | `.claude/agents/psychology-expert.md` | Backstory + PII + Act 예시 |
| 2 | `.claude/agents/coding-expert.md` | Backstory |
| 3 | `.claude/agents/flutter-expert.md` | Backstory |
| 4 | `.claude/agents/mbti-expert.md` | Backstory |
| 5 | `.claude/agents/enneagram-expert.md` | Backstory |
| 6 | `.claude/agents/tarot-expert.md` | Backstory + PII + Act 예시 |
| 7 | `.claude/agents/uiux-expert.md` | Backstory + PII |
| 8 | `.claude/protocols/orchestration.md` | 원문 보존 가드레일 + 실패 기억 축적 |

---

## Step 1 — Backstory 추가 (F1: High)

### Approach
7개 에이전트의 `# Role` 섹션과 `# Goal` 섹션 사이에 `# Backstory` 섹션을 추가한다.
000.2의 권장에 따라 2-3줄의 간결한 서사로 제한(80/20 규칙 준수).

### 7개 에이전트별 Backstory

**psychology-expert** — `# Goal` 바로 앞에 삽입:
```markdown
# Backstory

학계에서 15년간 성격심리학을 연구하며, 상업적 성격 검사의 과학적 허점을 논문으로 지적해온 엄밀한 연구자.
데이터 없는 주장을 극도로 경계하며, "재미있지만 근거 없는 콘텐츠"보다 "덜 화려하지만 학술적으로 정직한 콘텐츠"를 항상 선택한다.
```

**coding-expert**:
```markdown
# Backstory

스타트업과 대기업을 오가며 10년간 Rails 생태계에서 일해온 실용주의 엔지니어.
"동작하는 코드"보다 "테스트로 증명된 코드"를 신뢰하며, 과도한 추상화보다 명확한 코드를 선호한다.
```

**flutter-expert**:
```markdown
# Backstory

모바일 네이티브(iOS/Android)에서 출발해 Flutter로 전향한 크로스플랫폼 전문가.
60FPS와 보안(CSPRNG)에 집착하며, "사용자가 느끼는 촉감"까지 코드로 구현할 수 있다고 믿는다.
```

**mbti-expert**:
```markdown
# Backstory

한국 MZ세대의 MBTI 열풍을 최전선에서 관찰하며 서비스를 설계해온 트렌드 감각의 전문가.
"재미와 정확성의 균형"이 핵심 가치이며, 공식 MBTI 저작권 경계를 철저히 지키면서도 독창적 콘텐츠를 만들어낸다.
```

**enneagram-expert**:
```markdown
# Backstory

Riso-Hudson과 Naranjo 학파를 모두 깊이 공부한 통합적 관점의 애니어그램 실천가.
유형을 고정 라벨이 아닌 "성장의 지도"로 보며, 동기 중심 해석이 행동 분류보다 가치 있다고 확신한다.
```

**tarot-expert**:
```markdown
# Backstory

전통 RWS 체계를 깊이 공부하면서도 현대적 맥락에서의 재해석에 열려 있는 실천가.
"타로는 예측이 아닌 성찰의 거울"이라는 신념을 가지며, 모든 해석에서 사용자의 자기 성찰을 최우선에 둔다.
```

**uiux-expert**:
```markdown
# Backstory

카카오와 토스의 디자인 언어에 익숙한 한국 시장 특화 UX 전문가.
"좋은 디자인은 감정을 설계하는 것"이라 믿으며, 접근성과 심미성이 충돌할 때 항상 접근성을 택한다.
```

### Considerations
- 000.2의 80/20 규칙에 따라 각 Backstory를 2-3줄로 제한
- 서사가 해당 에이전트의 Core Principles와 일관되도록 설계
- 모든 에이전트에 동일한 위치(`# Role` 뒤, `# Goal` 앞)에 배치하여 구조 일관성 유지

---

## Step 2 — 원문 보존 가드레일 (F5: Low)

### Approach
orchestration.md의 "에이전트 산출물 프로토콜" 섹션 "5. confidence 판정" 뒤에 "6. 원문 보존 규칙" 섹션을 추가한다.

### Current Code
```markdown
// .claude/protocols/orchestration.md:178
4. **평가루프 내**: confidence 감쇠 미적용 (검증 에이전트가 직접 확인하므로)

## 산출물 문서 템플릿
```

### After Code
```markdown
// .claude/protocols/orchestration.md:178+
4. **평가루프 내**: confidence 감쇠 미적용 (검증 에이전트가 직접 확인하므로)

## 6. 원문 보존 규칙

다음 유형의 텍스트는 에이전트가 윤문·요약·의역하지 않고 **원형 그대로** 릴레이한다:

| 유형 | 예시 | 보호 방법 |
|------|------|----------|
| 학술 인용문 | "Costa & McCrae(1992)에 따르면..." | 인용 부분을 그대로 전달 |
| 저작권 원문 | 공식 검사 문항, 라이선스 텍스트 | 복사·변형 금지 (Red Line) |
| 사용자 원문 입력 | 사용자의 질문, 의도 설정 텍스트 | 의미 변형 없이 전달 |

에이전트 간 릴레이 시 원문이 포함되면 `> [ORIGINAL]` 블록으로 표시:
```
> [ORIGINAL] Costa & McCrae(1992)의 Five-Factor Model에 따르면...
```

## 산출물 문서 템플릿
```

---

## Step 3 — 실패 기억 축적 프로토콜 (F3: Medium)

### Approach
orchestration.md의 "평가루프 프로토콜" 섹션 "핵심 규칙" 뒤에 "실패 패턴 기억 축적" 규칙을 추가한다.

### Current Code
```markdown
// .claude/protocols/orchestration.md:278-282
## 핵심 규칙

- 최대 반복 3회. 초과 시 현재 최선 + 미해결 목록으로 진행
- blocker/major fail → 재생성 (iteration++). minor만 → 1회 수정 후 자동 통과
- 점수 미개선(2회 연속 동일/하락) → 즉시 중단, 사용자 개입 요청
```

### After Code
```markdown
// .claude/protocols/orchestration.md:278+
## 핵심 규칙

- 최대 반복 3회. 초과 시 현재 최선 + 미해결 목록으로 진행
- blocker/major fail → 재생성 (iteration++). minor만 → 1회 수정 후 자동 통과
- 점수 미개선(2회 연속 동일/하락) → 즉시 중단, 사용자 개입 요청

## 실패 패턴 기억 축적

평가루프가 **fail verdict 2회 이상** 또는 **HitL 개입**으로 종료될 때, 오케스트레이터는 실패 패턴을 기억에 저장한다:

1. **저장 위치**: 검증 에이전트의 `agent-memory/{agent}/memories/` (개별 기억)
2. **저장 조건**: iteration 2+ 도달 또는 HitL 개입 (iteration 1 pass는 저장 불필요)
3. **저장 내용**:
   ```yaml
   type: review
   keywords: ["평가루프", "실패패턴", "{실패 criteria ID}"]
   summary: "{대상 에이전트}의 {작업 유형}에서 {criteria}가 {N}회 fail"
   context: "평가루프 {iteration}회, verdict: {결과}"
   details: "반복 실패한 criteria: {목록}. fix_suggestion: {제안}"
   implications: "향후 동일 유형 검증 시 이 criteria를 우선 확인"
   ```
4. **활용**: 검증 에이전트 스폰 시, 해당 에이전트의 기억에서 `평가루프` 키워드로 과거 실패 패턴을 조회하여 스폰 프롬프트에 "이전에 반복 실패한 기준" 컨텍스트를 주입한다
```

### Considerations
- 이 규칙은 연구(032)가 발견한 "T3+T15 피드백 고리 부재"를 해소
- iteration 1 pass는 저장하지 않아 기억 노이즈 방지
- 검증 에이전트의 개별 기억에 저장하여, 해당 에이전트가 다음 검증 시 자동으로 참조 가능

---

## Step 4 — PII 보호 균일화 (F6: Low)

### Approach
psychology-expert, tarot-expert, uiux-expert의 Core Principles에 PII 관련 항목을 추가한다.

### psychology-expert Core Principles (현재 5개 → 6개):
```markdown
6. **사용자 데이터 보호**: 성격 프로필, 응답 데이터 등 민감한 개인정보를 산출물에 포함하지 않는다. 익명화된 패턴만 기술한다.
```

### tarot-expert Core Principles (현재 5개 → 6개):
```markdown
6. **사용자 맥락 보호**: 사용자의 질문, 의도 설정 내용 등 개인적 맥락을 보고서나 기억에 원문으로 저장하지 않는다. 익명화된 패턴만 기록한다.
```

### uiux-expert Core Principles (현재 5개 → 6개):
```markdown
6. **사용자 데이터 보호**: 사용자 행동 데이터, 개인 식별 정보를 UI 텍스트나 산출물에 노출하지 않는다.
```

---

## Step 5 — 산출물 입출력 예시 (F7: Low, 대표 3개 에이전트)

### Approach
psychology-expert, coding-expert, tarot-expert의 Act 섹션에 산출물 유형별 간결한 예시를 추가한다.
나머지 4개 에이전트는 이 패턴을 보고 후속 사이클에서 추가.

### psychology-expert `## Act` 보강:
현재 Act의 3유형 열거 뒤에 예시 블록 추가:
```markdown
**검증 작업 출력 예시**:
```yaml
evaluation:
  verdict: conditional_pass
  overall_score: 0.86
  criteria:
    - name: "PSY-02"
      severity: blocker
      status: pass
      detail: "바넘 효과 문구 0건 확인"
    - name: "PSY-05"
      severity: major
      status: fail
      detail: "'깊이 생각하는 편' — 응답 편향 우려"
      fix_suggestion: "'상황에 따라 분석적 접근을 선호하는' 으로 변경"
```
```

### coding-expert `## Act` 보강:
```markdown
**구현 작업 출력 예시**:
```ruby
# app/services/scoring/dimension_scorer.rb
class Scoring::DimensionScorer
  def call(responses:, dimension:)
    scores = responses.select { |r| r.dimension == dimension }
    return nil if scores.empty?

    weighted_sum = scores.sum { |r| r.value * r.item.weight }
    weighted_sum / scores.sum { |r| r.item.weight }
  end
end
```
```

### tarot-expert `## Act` 보강:
```markdown
**해석 콘텐츠 출력 예시**:
```yaml
card: "The Tower"
position: "현재 상황"
interpretation: >
  익숙한 구조가 흔들리는 시기입니다. 이 카드는 예측이 아닌 성찰을 권합니다 —
  "무엇이 무너지고 있는가"보다 "무엇을 새로 세울 수 있는가"에 집중해보세요.
tone: reflective
avoid: ["예언적 서술", "공포 유발", "확정적 미래 언급"]
```
```

---

## Considerations & Trade-offs

### Alternative Approaches
| 대안 | 미채택 이유 |
|------|-----------|
| Backstory를 Role 섹션에 통합 | 000.2가 별개 개념으로 정의, 분리가 이론에 부합 |
| 7개 에이전트 모두 입출력 예시 | 변경 범위 과대, 대표 3개로 패턴 확립 후 확장 |
| 실패 기억을 _shared/에 저장 | 검증 에이전트별 특화 기억이 더 유용 |

### Potential Risks
| 위험 | 완화 |
|------|------|
| Backstory가 Core Principles와 충돌 | 서사를 Principles와 일관되게 설계 |
| 실패 기억 과다 축적 | iteration 2+ 조건으로 노이즈 필터링 |
| orchestration.md 토큰 증가 | ~200토큰 추가, 지연 로딩이므로 영향 미미 |

### Backward Compatibility
- 모든 변경이 기존 내용 삭제 없이 추가/확장
- 에이전트 파일의 기존 섹션 구조 유지
- orchestration.md의 기존 규칙과 충돌 없음

## Implementation Checklist

- [x] Step 1: 7개 에이전트에 Backstory 섹션 추가
- [x] Step 2: orchestration.md에 원문 보존 규칙 추가
- [x] Step 3: orchestration.md에 실패 기억 축적 규칙 추가
- [x] Step 4: psychology/tarot/uiux에 PII 가드레일 추가
- [x] Step 5: psychology/coding/tarot에 Act 예시 추가
- [x] Final verification

## Verification Assertions

| Level | Assertion | Verification Method | Expected Result |
|-------|-----------|-------------------|-----------------|
| L2-CLI | 7개 에이전트에 Backstory 존재 | `grep -l "# Backstory" .claude/agents/*.md \| wc -l` | 7 |
| L2-CLI | orchestration.md에 원문 보존 규칙 존재 | `grep "ORIGINAL" .claude/protocols/orchestration.md` | 매칭 |
| L2-CLI | orchestration.md에 실패 기억 규칙 존재 | `grep "실패 패턴 기억" .claude/protocols/orchestration.md` | 매칭 |
| L2-CLI | PII 가드레일 3개 에이전트에 존재 | `grep -l "데이터 보호\|맥락 보호" .claude/agents/{psychology,tarot,uiux}*.md \| wc -l` | 3 |
| L4-Trace | R-032-F1 해소 | Backstory 7/7 존재 확인 | ✅ |
| L4-Trace | R-032-F3 해소 | 실패 기억 축적 규칙 존재 확인 | ✅ |
| L4-Trace | R-032-F5 해소 | 원문 보존 규칙 존재 확인 | ✅ |

## References

| Resource | Path/URL | Related Content |
|----------|---------|-----------------|
| 최종 연구 | docs/07_organizational_agents/032_Research_gemini_perspective_audit_final.md | R-032-F1~F7 |
| Synthesis | docs/07_organizational_agents/031_Synthesis_gemini_perspective_audit.md | Recommended Actions |
| 000.2 Gemini | docs/07_organizational_agents/000.2_gemini_deep_research.md | 섹션 3.1 Backstory, 섹션 6.1 안티패턴 |
| orchestration.md | .claude/protocols/orchestration.md | 수정 대상 |
