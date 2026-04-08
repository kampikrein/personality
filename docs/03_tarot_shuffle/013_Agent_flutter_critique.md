---
id: "013"
title: "Flutter 아키텍처 비평 — Clean Architecture, 상태 관리, 엔트로피 파이프라인"
category: agent
status: archived
created: 2026-03-16
summary: >
  mobile/ Flutter 구현 전체 비평. Clean Architecture 레이어 분리 양호, 상태 관리 이원화에
  반응성 갭 존재, 엔트로피 파이프라인에 보안 취약점(단일 풀, 시드 스트레칭 미적용),
  Reading 삭제 트랜잭션 누락, 에러 핸들링 부재 등 Critical 3건, High 4건 발견.
keywords: [agent-report, flutter-critic, architecture, entropy, riverpod, drift, performance]
modules: [mobile]
---

# Flutter Architecture Critique: personality_mobile

## Summary

Clean Architecture + Feature-first 구조는 견고하나, 엔트로피 보안(Critical), 상태 관리 이원화 갭(High), 에러 핸들링 부재(High)가 즉각 수정 필요. CardPainter 60fps는 달성 가능하나 shouldRepaint 최적화 권장.

## Key Findings

| Severity | Count | Issues |
|----------|-------|--------|
| Critical | 3 | 엔트로피 풀 설계(단일 풀, 스트레칭 없음), 시드 생성(HKDF 미적용), 애니메이션 상태 Riverpod 미통합 |
| High | 4 | 상태 관리 이원화 갭, Reading 삭제 비트랜잭션, 셔플 에러 핸들링 없음, 타이머 폴링 취약 |
| Medium | 5 | Cascade delete 미설정, shouldRepaint 항상 true, 테스트 가능성, 셔플 결과 미영속, Provider 생명주기 |
| Low | 2 | DB 인덱스 누락, 애니메이션 프레임 최적화 |

## Details

### Architecture [Good]
- Clean Architecture 레이어 분리 적절 (domain→data→presentation)
- Feature-first 구조 일관성 유지
- 단, RiffleAnimationState가 Riverpod 그래프 외부에 위치하여 아키텍처 불일치

### State Management [Problematic - High]
- Riverpod + ChangeNotifier 이원화가 디버깅/테스트를 어렵게 함
- RiffleAnimationState 메모리 릭 위험 (auto-disposal 미보장)
- Timer.periodic 폴링으로 센서 상태 갱신 — StreamBuilder 전환 권장

### Drift DB [Solid - Minor Gaps]
- FK, unique constraints, SyncStatus, timestamps 적절
- Cascade delete 미설정 (Cards orphan 위험)
- Reading 삭제에 transaction() 미사용 (race condition)
- FK/쿼리 대상 컬럼에 인덱스 누락

### Entropy Pipeline [Critical]
- 단일 SHA-256 풀: Fortuna 10-pool 패턴 미적용
- 시드 생성에 HKDF/Argon2 미사용
- FortunaRandom 단일 시드, 재시딩 메커니즘 없음
- 동일 샘플 시 동일 해시 → 새 엔트로피 없음

### Performance [Good]
- RepaintBoundary 올바르게 적용
- shouldRepaint → true 항상 반환 (불필요한 repaint)
- 리플 800ms×3 + 수렴 400ms = ~3초 적절

### Code Quality [Medium]
- _startShuffle에 try-catch 없음
- Timer.periodic의 mounted 체크는 fragile
- SensorDataCollector/HapticService 테스트 더블 없음

## Recommendations

1. [Sprint 1] 엔트로피 파이프라인을 Fortuna 10-pool 또는 HKDF로 보강
2. [Sprint 1] RiffleAnimationState를 Riverpod Provider로 래핑
3. [Sprint 1] _startShuffle에 try-catch + 사용자 피드백 추가
4. [Sprint 1] Reading 삭제를 transaction()으로 래핑
5. [Sprint 2] Cascade delete, DB 인덱스 추가
6. [Sprint 2] shouldRepaint 최적화
7. [Sprint 3] Timer 폴링 → StreamBuilder/Riverpod Stream 전환

## References

- mobile/lib/core/database/
- mobile/lib/features/shuffle/data/datasources/
- mobile/lib/features/shuffle/presentation/
- mobile/lib/features/shuffle/domain/strategies/

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 0s | 0 |
| 2 | user-ai-exchange | 19s | 76045 |
| 3 | user-ai-exchange | 11s | 40778 |
| 4 | user-ai-exchange | 10s | 42195 |
| 5 | user-ai-exchange | 9s | 44183 |
| 6 | user-ai-exchange | 14s | 46529 |
| 7 | user-ai-exchange | 5s | 48356 |
| 8 | user-ai-exchange | 9s | 50568 |
| 9 | user-ai-exchange | 13s | 105037 |
| 10 | user-ai-exchange | 12s | 54453 |
| 11 | user-ai-exchange | 11s | 55874 |
| 12 | user-ai-exchange | 12s | 57359 |
| 13 | user-ai-exchange | 14s | 58996 |
| 14 | user-ai-exchange | 13s | 60582 |
| 15 | user-ai-exchange | 8s | 61831 |
| 16 | user-ai-exchange | 11s | 63033 |
| 17 | user-ai-exchange | 29s | 202688 |
| 18 | user-ai-exchange | 11s | 140060 |
| 19 | user-ai-exchange | 11s | 71985 |
| 20 | user-ai-exchange | 9s | 147944 |
| 21 | user-ai-exchange | 14s | 76148 |
| 22 | user-ai-exchange | 19s | 0 |
| 23 | user-ai-exchange | 10s | 41780 |
| 24 | user-ai-exchange | 13s | 45110 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 341150s |
| Total Tokens | 1591534 |
| Input Tokens | 71 |
| Output Tokens | 8834 |
| Cache Read | 1202235 |
| Cache Creation | 380394 |
