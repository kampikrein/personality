---
id: "030"
type: synthesis
title: "Scope 026 Critique Synthesis — 3 perspective"
created: 2026-04-29
target: "026"
critique_docs: ["027", "028", "029"]
severity_summary:
  critical: 3
  major: 14
  minor: 9
  missing: 3
perspectives:
  S1: "Brief↔Scope 매핑 정합성 (027) — 1C/7M/3m/3 missing"
  S2: "makeplan 진입 준비도 (028) — 2C/4M/3m"
  S3: "Pipeline DB 일관성 (029) — 0C/3M/3m"
summary: >
  3 관점 confidence: high. Scope 026의 매크로 매핑은 정합적이나 (a) Brief In Scope 2
  "로컬 검증 인프라" 미매핑(C1 S1), (b) ERB 27 = admin 9 + 공개 13 + layouts/pwa 5의
  사실 정정 필요(C1 S2 — Scope/Brief의 "18 ERB" 오류), (c) Cycle 5 routes
  "≥10 endpoints" → 실측 32 (public 22 + admin 10) (C2 S2). DB는 100% 정합 — gate
  next 의도된 순서대로 작동(S3). 보강 후 7 cycle 모두 즉시 makeplan 가능.
keywords: [critique-synthesis, scope-026, makeplan-readiness, brief-mapping, pipeline-consistency, erb-fact-correction]
---

# Scope 026 Critique Synthesis

## 1. Severity Roll-up

| Perspective | Critical | Major | Minor | Missing | Confidence |
|------------|----------|-------|-------|---------|------------|
| S1 Brief↔Scope 매핑 (027) | 1 | 7 | 3 | 3 | high |
| S2 makeplan 진입 준비도 (028) | 2 | 4 | 3 | — | high |
| S3 Pipeline DB 일관성 (029) | 0 | 3 | 3 | — | high |
| **합계** | **3** | **14** | **9** | **3** | high |

## 2. Critical 3건 — Scope 026 즉시 보강

### C1 [S1] — Brief In Scope 2 "로컬 검증 인프라" Cycle 미매핑

**발견**: Brief 021 In Scope 2 (wrangler dev --local + vitest-pool-workers + miniflare DX)가 Scope 026 어떤 cycle frontmatter `in_scope`에도 매핑되지 않음. Cycle 1 in_scope=[1]만 표기. 책임 owner 공백 → makeplan에서 "wrangler dev 환경 누가 셋업?" 질문 부유.

**Scope 026 보강**: Cycle 1 in_scope를 `[1]` → `[1, 2]`로 확장. Cycle 1 area를 "Foundation 한정형 (CF infra 파일 템플릿 + 로컬 검증 인프라)"로 명칭 보강. note에 "wrangler dev --local --persist 셋업 + miniflare config + vitest-pool-workers 베이스 테스트 1건 (smoke)" 추가.

### C2 [S2] — ERB 27 = admin 9 + 공개 13 + layouts/pwa 5 사실 정정

**발견**: Scope 026 (Brief 021 계승) "공개 평가 흐름 18 ERB"는 단순 27-9=18 계산 오류. 실측:
- admin/ = 9 (alerts 2, audit_logs 2, dashboard 1, question_sets 4) — R3 일치
- 공개/사용자 흐름 = **13** (assessment_questions 2, assessments 1, consents 1, deletion_requests 2, accounts 1, sessions 1, results 5)
- layouts/pwa = 5 (전환 제외 — layouts/{admin, application, mailer.html, mailer.text} + pwa/manifest.json)

**Scope 026 보강**: 영역 식별 표 + Cycle 6 항목에서 "18 ERB"를 "**13 ERB (admin 9 외 공개 흐름) + layouts/pwa 5 제외**"로 정정. ERB → TSX 매핑 표를 makeplan 입력으로 사이클 6에 추가:

| 분류 | ERB count | TSX 매핑 위치 |
|------|----------|------------|
| admin | 9 | `app/routes/admin/*.tsx` |
| assessment_questions, assessments | 3 | `app/routes/assessments/*.tsx` |
| accounts, sessions | 2 | `app/routes/auth/*.tsx` (Cycle 4 + 5 공유) |
| consents, deletion_requests | 3 | `app/routes/api/{consents,deletion-requests}/*` (Cycle 8) + UI 분리 |
| results | 5 | `app/routes/results/*.tsx` |
| layouts/pwa | 5 | **전환 제외** (Hono 자체 layout, manifest는 별도 처리) |

### C3 [S2] — Cycle 5 routes "≥10 endpoints" → 실측 32

**발견**: Scope 026 Cycle 5 파일 목록 "(≥10 endpoints), low confidence"로 표기. 실 routes.rb 분석: **32 unique controller#action** (public 22 + admin 10). low confidence가 makeplan agent에게 인벤토리 작성 부담 전가.

**Scope 026 보강**: Cycle 5 파일 목록에 32 endpoints 인벤토리 표 추가 (public 22 + admin 10 분류). confidence를 low → medium으로 격상.

## 3. Major 14건 — Scope 026 보강 권고

| # | Source | 발견 | Scope 보강 방향 |
|---|--------|------|--------------|
| M1 | S1 | Brief Out of Scope 10항목 cycle 매핑 부재 (4줄 reference로만 압축) | "deferred 처리 + Phase 2 carryover" 표 신규 — cycle별 영향 / Phase 2 재진입 시점 매핑 |
| M2 | S1 | Phase 2 Carryover § 2.3 11항목 cycle 인지 부재 | 같은 표에 carryover_input 컬럼 추가 (BC2/BC3 + W3 #6/#14/#15/#18 등 cycle별 인지 책임) |
| M3 | S1 | Decision 11 (Toss BC2/BC3 보존) cycle 매핑 부재 | "Phase 2 Cycle 7 makeplan 입력 (Synthesis 018 BC2/BC3 + Brief 021 § 2.1)" deferred 표에 명시 |
| M4 | S1 | Decision 12 (Local/Partial/Production-only) verify_scope 매트릭스 cycle 인지 부재 | Cycle 10_tail eval/qualify 입력에 verify_scope 매트릭스 적용 명시 |
| M5 | S1 | Decision 7 (JWKS DI 패턴) frontmatter `decisions` 비일관 (Cycle 5만 보유, 4가 없음) | Cycle 4 frontmatter `decisions: [7]` 추가 + makeplan 입력에 JWKS DI signature 의사코드 |
| M6 | S1 | Decision 5 (Pure Saga, DO 미사용) 명시 약함 | Cycle 3 makeplan 입력에 "DO 미사용 명시 — D1 only Phase A-E" 강조 |
| M7 | S1 | (보고서 § Major) | (위 M1~M6에 통합) |
| M8 | S2 | Cycle 3 saga Phase A-E 의사코드 위임처 불명 (Synthesis 018 R2-F 인용만) | Cycle 3 makeplan 입력에 Synthesis 018 R2 § Phase A-E 정확한 인용 + 상위 의사코드 1단락 |
| M9 | S2 | Cycle 4 6 컴포넌트 인터페이스 (export, props, return type) 부재 | Cycle 4 makeplan 입력에 6 모듈 export interface 표 (betterauth init / cf_access verifier signature / encryption envelope / email_hash / session / key_rotation) |
| M10 | S2 | Cycle 6 ERB → TSX 매핑 정확한 표 부재 | C2 보강과 통합 — ERB 분류 표 + 1:1 매핑 |
| M11 | S2 | Cycle 8 14세 미만 처리 정책 결정 부재 (외부 KYC API 의존 가능성) | Cycle 8 note에 "14세 미만 = 가입 차단 정책 (KYC 외부 API 미사용, 자체 가입 시 출생연도 기반 차단)" 명시 + Phase 2 carryover로 외부 KYC 검토 |
| M12 | S2 | tdd-red agent 도구 버전 명시 부재 | Brief 021 Phase 2 Carryover § 2.4 도구 pin을 사이클별 makeplan 입력 표에 인용 |
| M13 | S3 | auto_run 메타 mismatch (Scope frontmatter false, DB 실제 true 상태가 있을 수 있음) | Scope 026 frontmatter 명시 — `auto_run: false` (사용자가 --run 추가 호출 시 true로 토글). DB 메타 정렬 |
| M14 | S3 | planned_cycles=10 stale (실 활성 7) | DB 메타 `planned_cycles: 7` 갱신. Scope 026 frontmatter에 명시. CB L2 한도 재계산 (=21 vs 30 — 무력화 회피) |

## 4. Minor 9건 — 선택 반영

| # | Source | Finding | Action |
|---|--------|---------|--------|
| Mn1 | S1 | frontmatter `decisions` 필드 비일관 (Cycle 5만 표기) | 모든 cycle frontmatter에 `decisions` 필드 추가 (M5와 통합) |
| Mn2 | S1 | Cycle 6 EV-015-S1 매핑 1줄 → 명시 표 | C2 보강과 통합 |
| Mn3 | S1 | Synthesis 025 C1/C2 적용 위치 명시 약함 | Scope 026 § 사이클별 makeplan 입력 표에 C1/C2 column 추가 |
| Mn4 | S2 | Cycle 1 Plan 020 stub-only 정확한 패턴 정의 | Cycle 1 makeplan 입력에 "scheduled handler stub: `export default { scheduled() { return new Response('stub-only Phase 2', {status: 501}) } }`" 명시 |
| Mn5 | S2 | 사이클별 verify 기준 명시 부재 (Brief 021 Ideal Criteria 28 trace) | Scope 026 § "사이클별 ideal_criteria_owned" 표 추가 (예: Cycle 2 → #4, #5, #6, #7, #8) |
| Mn6 | S2 | tdd-red 도구 버전 명시 (M12와 통합) | Brief 021 § 2.4 인용 |
| Mn7 | S3 | cycle 99 dual-phase rows 명시 | Scope 026 § Pipeline DB 정렬 상태에 dual cycle-99 명시 (research done + impl pending) |
| Mn8 | S3 | Scope text manual sync (DB가 source of truth) | Scope 026 § 끝에 "DB가 source of truth — Scope 본문은 표시용" 명시 |
| Mn9 | S3 | had_interruption flag 누락 | DB에 보강 (Scope 외 작업) |

## 5. Missing 3건 (S1) — Scope 026에 추가

| # | What's Missing | Why Matters | Action |
|---|---------------|-------------|--------|
| MS1 | Decision-Cycle 매핑 표 (15 Decisions × 7 cycles) | trace 가능성 + scope creep 방지 | Scope 026 § 신규 표 |
| MS2 | Out of Scope - cycle 영향 표 (10 항목 × cycle 영향) | deferred 항목이 어느 cycle 작업에 영향을 주는지 명확 | Scope 026 § 신규 표 |
| MS3 | Phase 2 Carryover - cycle 인지 표 (11 항목 × cycle 인지 책임) | carryover 책임 ownership | Scope 026 § 신규 표 |

## 6. Scope 026 보강 작업 목록 (우선순위)

| Priority | Source | 변경 위치 | 변경 내용 |
|----------|--------|---------|---------|
| **P1 (Critical)** | C1 (S1) | Cycle 1 frontmatter + 영역 식별 표 | in_scope=[1, 2] + 영역 명칭 보강 + note 보강 |
| **P1 (Critical)** | C2 (S2) | Cycle 6 영역 식별 표 + note + ERB 매핑 표 신규 | "18 ERB" → "13 ERB + layouts/pwa 5 제외" + 분류표 |
| **P1 (Critical)** | C3 (S2) | Cycle 5 영역 식별 표 + 파일 목록 | 32 endpoints 인벤토리 + confidence low → medium |
| P2 (Major) | M1+M2+MS2+MS3 | Scope 026 § 신규 섹션 "Out of Scope cycle 영향 + Phase 2 Carryover cycle 인지" | 표 2개 (Out of Scope 10 항목 / Carryover 11 항목 × cycle 매핑) |
| P2 (Major) | M3 | 위 표에 BC2/BC3 carryover 책임 = Phase 2 Cycle 7 명시 | — |
| P2 (Major) | M4 | Cycle 10_tail eval 입력 | verify_scope 매트릭스 적용 명시 |
| P2 (Major) | M5+Mn1 | 모든 cycle frontmatter | `decisions` 필드 일관화 |
| P2 (Major) | M6 | Cycle 3 makeplan 입력 | Pure Saga D1 only 강조 |
| P2 (Major) | M8 | Cycle 3 makeplan 입력 | Phase A-E 의사코드 1단락 |
| P2 (Major) | M9 | Cycle 4 makeplan 입력 | 6 모듈 export interface 표 |
| P2 (Major) | M10 | C2 보강과 통합 | — |
| P2 (Major) | M11 | Cycle 8 note + Phase 2 Carryover | 14세 미만 정책 명시 |
| P2 (Major) | M12+Mn6 | 모든 사이클 makeplan 입력 | Brief 021 § 2.4 도구 pin 인용 |
| P2 (Major) | M13 | Scope 026 frontmatter | `auto_run: false` 명시 |
| P2 (Major) | M14 | Scope 026 frontmatter + DB | `planned_cycles: 7` 갱신 |
| P2 (Major) | MS1 | Scope 026 § 신규 표 | Decision-Cycle 매핑 |
| P3 (Minor) | Mn3 | 사이클별 makeplan 입력 표 | Synthesis 025 C1/C2 column |
| P3 (Minor) | Mn4 | Cycle 1 makeplan 입력 | stub-only 의사코드 |
| P3 (Minor) | Mn5 | Scope 026 § 신규 표 | ideal_criteria_owned per cycle |
| P3 (Minor) | Mn7 | Pipeline DB 정렬 상태 표 | dual cycle-99 명시 |
| P3 (Minor) | Mn8 | Scope 026 § 끝 | DB source of truth 명시 |

**위임 (Scope 미수정)**: Mn9 (DB had_interruption flag) — 별도 작업.

## 7. 비평이 검증한 강점 (Scope 026 유지)

- **Scope creep 0** ✓ — Brief 021 외 새 결정 도입 없음 (S1)
- **DB 100% 정합** ✓ — gate next() 의도된 순서대로 작동, 21행 cross-check, checklist_history 정확 (S3)
- **매크로 매핑 정합적** ✓ — 9 In Scope의 7개 cycle 매핑은 옳음, In Scope 2만 누락 (S1)
- **의존성 그래프 방향성** ✓ — Cycle 4 → 5 (보안 baseline 우선) 결정 안전 (S1, S2)
- **TDD 적용 사이클 결정** ✓ — Brief 021 Decision 10 일치 (S1)

## 8. 다음 작업

1. **Scope 026 보강 적용** (Critical 3 inline + Major 9 inline + Minor 4 inline + Missing 3 신규 섹션)
2. **DB 메타 갱신**: `pipeline.sh set planned_cycles 7 cf_workers_rebuild` (DB sync)
3. **frontmatter 갱신**: `deep_critique: true`, `critique_docs: ["027","028","029"]`, `critique_synthesis: "030"`
4. **Brief 021 ERB 정정** (참고용 메모): Brief frozen이지만 critique synthesis에 ERB 수치 정정 명시 (이미 본 Synthesis § 2 C2에 기록)
5. **Cycle 1 implementation 한정형 진입 가능** — 보강 완료 후 gate auto-run 가능

## 9. References

| Resource | Path |
|----------|------|
| Scope 026 (target) | [`026_Scope_conversion_phase1.md`](./026_Scope_conversion_phase1.md) |
| Brief 021 (parent anchor) | [`021_Brief_conversion_phase1.md`](./021_Brief_conversion_phase1.md) |
| Critique 027 (S1) | [`027_Critique_scope_mapping.md`](./027_Critique_scope_mapping.md) |
| Critique 028 (S2) | [`028_Critique_makeplan_readiness.md`](./028_Critique_makeplan_readiness.md) |
| Critique 029 (S3) | [`029_Critique_pipeline_consistency.md`](./029_Critique_pipeline_consistency.md) |
| Synthesis 018 (research) | [`018_Synthesis_research_cycle.md`](./018_Synthesis_research_cycle.md) |
| Synthesis 025 (Brief 021 critique) | [`025_Critique_Synthesis.md`](./025_Critique_Synthesis.md) |

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 25s | 43455 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 25s |
| Total Tokens | 43455 |
| Input Tokens | 6 |
| Output Tokens | 1821 |
| Cache Read | 0 |
| Cache Creation | 41628 |
