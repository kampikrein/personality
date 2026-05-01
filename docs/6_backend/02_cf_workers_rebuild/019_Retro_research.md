---
id: "019"
type: retro
title: "Research Phase Retrospective — cf_workers_rebuild"
created: 2026-04-29
phase: research
traces_synthesis: "018"
summary: >
  5축 연구 + 5 eval 사이클로 구성된 research phase가 모두 SUFFICIENT 판정으로 완결됐다.
  병렬 디스패치와 cross-axis eval 조정 메커니즘이 효과적으로 작동했으며,
  impl phase 진입을 위한 10 사이클 입력 매핑 및 5개 OQ가 확정됐다.
---

# Research Phase Retrospective — cf_workers_rebuild

## Phase Summary

5축(R1 Drizzle+D1, R2 D1 Saga, R3 Admin UI, R4 Auth Hybrid, R5 Toss Payment)을 각 1개 eval 사이클로 검증. 전 축 SUFFICIENT 판정. Cross-axis 충돌 1건(R1↔R4 schema 모델) 정합 해소. Brief 가정 정정 3건 흡수. Scope 누락 1건(Cycle 6 영역 확장)으로 흡수. Synthesis(018)에 전 결정 통합 완료.

## What Worked

**병렬 디스패치**: 5 research 에이전트가 독립 축 기준으로 병렬 실행됐고, 이후 5 eval 에이전트도 병렬 디스패치됐다. 단계 간 의존성이 명확히 정의돼 있어 불필요한 sequential wait 없이 진행됐다.

**Eval의 cross-axis 충돌 탐지**: EV-016(R4 Eval)이 R1 권고와의 schema 모델 충돌을 verdict에 명시, synthesis 단계에서 R4 우위 + R1 envelope 보존 통합 패턴으로 정합됐다. 에이전트 간 충돌이 파이프라인 설계대로 eval → synthesis 이중 관문을 통해 해소됐다.

**Scope의 영역 분리 명확성**: R1~R5의 탐구 범위가 scope에서 충분히 구분돼 있어 연구 에이전트 간 중복 탐구가 거의 없었다.

## What To Improve

**Brief의 합산 표기 → R3 disambiguation 비용**: Brief의 "27 ERB + 8 Stimulus" 표기가 admin + 공개 평가 흐름을 하나로 묶은 합산이었고, R3 에이전트가 이를 admin-only로 해석했다. EV-015(R3 Eval)의 S1 finding에서 이 구분이 처음 명시됐고, synthesis에서 Cycle 6 영역 확장으로 흡수됐다. **개선**: Brief 작성 시 UI 컴포넌트를 대상(admin vs 공개 흐름)별로 분리 표기하면 disambiguation 비용 제거 가능.

**Scope axis → Cycle 매핑의 단방향성**: Scope에서 연구 축(R1~R5)과 impl cycle(1~10) 매핑이 명시됐으나, research 에이전트가 Cycle 단위 deliverable을 의식하며 연구하지 않았다. 이로 인해 synthesis에서 역방향으로 cycle별 입력을 재매핑하는 단계가 추가됐다. **개선**: research 에이전트 프롬프트에 "이 연구 결과가 어느 impl cycle에 직접 연결되는지" 명시 항목 추가.

## Brief 가정 정정 추적

| # | 정정 대상 | 내용 | 처리 |
|---|----------|------|------|
| BC1 | Anchor 9 — 인증 토큰 공유 | "양 서브도메인 공유" → **격리** (BetterAuth host-scoped + CF Access disjoint) | Synthesis 흡수, Brief frozen 유지 |
| BC2 | Decision 5 / In Scope 9.3 — webhook 모델 단일화 가정 | "HMAC-SHA256" 일반화 → 모델 이중화 (A: secret 비교 / B: HMAC v1) | Synthesis 흡수 |
| BC3 | In Scope 9.3 — idempotency key 명칭 | `event_id` (추정) → `tosspayments-webhook-transmission-id` (1차 출처) | Synthesis 흡수 |

3건 모두 설계 방향 번복 없는 minor 정정. Brief frozen 상태 유지하면서 synthesis가 makeplan 입력 차원에서 흡수.

## Cross-axis 충돌 해소

**충돌**: R1 권고(단일 결정성 컬럼 envelope JSON) vs R4 권고(3 컬럼 분리: `email_hash` + `email_enc` + `encryption_version`).

**해소 경로**: EV-016이 R4 우위 판정(key rotation 부담 낮아야 실제 실행). Synthesis에서 통합 패턴 확정 — R4 분리 컬럼 + R1 envelope JSON을 `email_enc` 값으로 그대로 저장. 양 권고 보존.

**부수 효과**: R2의 saga forward-recovery가 요구하는 UNIQUE 제약 3건(`domain_scores`, `profiles`, `insights`)이 동일 schema 레이어에서 확정돼 Cycle 2 입력에 통합됐다.

## Carryover for Impl Phase (5 Open Questions)

| OQ | 확정 시점 |
|----|----------|
| OQ-1: Cycle 6 공개 평가 흐름 LOC + 인터랙션 매핑 (8 Stimulus → Hono SSR + hx-boost 또는 htmx) | Cycle 6 makeplan |
| OQ-2: BetterAuth `email_hash` 생성 hook 위치 (`before-create` vs mounter 미들웨어) | Cycle 4 makeplan |
| OQ-3: webhook 모델 B (HMAC v1) dormant 코드 선작성 여부 | Cycle 7 makeplan |
| OQ-4: Cycle 9 archive smoke test 자동화 빈도 (월 1회 vs 분기 1회) | Cycle 9 makeplan |
| OQ-5: Hono CSRF 미들웨어 분기 — 모바일(Bearer JWT bypass) vs admin(strict Origin) | Cycle 4/5 makeplan 통합 결정 |

10 impl 사이클 입력 매핑 완료. Synthesis(018) § 5가 사이클별 research 결정 참조 SOT.
