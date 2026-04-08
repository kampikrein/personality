---
id: "001"
type: scope
title: "Universal Waite Tarot 78장 카드 이미지 확보"
created: 2026-03-18
complexity: simple
research_needed: true
research_reason: "외부 웹에서 Universal Waite Tarot 78장 카드 이미지 소스를 찾아야 함"
auto_run: true
effort_mode: light
uncertainty_level: medium
intent: >
  Universal Waite Tarot 78장의 고해상도 이미지를 확보하여 모바일 앱의
  타로카드 이미지로 사용. 개별 고해상도 이미지를 우선 탐색하되,
  없으면 합본/그리드 이미지에서 크롭하는 방식도 허용.
summary: >
  외부 이미지 소스 탐색(research) → 다운로드/크롭 전략 수립(plan) → 에셋 배치(impl)
keywords: [universal-waite, tarot, 78-cards, card-images, asset-acquisition, rws]
---

# Universal Waite Tarot 78장 카드 이미지 확보

## 작업 목표
- Universal Waite Tarot (Mary Hanson-Roberts 리컬러링) 78장 이미지 확보
- Major Arcana 22장 + Minor Arcana 56장 (Wands, Cups, Swords, Pentacles × 14)
- 타로카드 비율에 적합한 고해상도 이미지 (최소 300px 이상 너비 권장)
- 개별 이미지 우선, 불가 시 합본 이미지 크롭
- 최종 배치: `mobile/assets/images/universal_waite/`

## 접근 방향
1. **웹 탐색**: 개별 카드 고해상도 이미지 소스 탐색
2. **대안**: 합본/그리드 이미지 탐색 → 크롭 스크립트로 개별 분리
3. **에셋 정리**: 78장을 rws_deck.json의 cardId 체계에 맞춰 명명

## Research 판단
- **판단**: 필요
- **근거**: 외부 웹에서 이미지 소스를 찾아야 하며, 해상도/가용성 조사 필요
- **파이프라인**: S → R → P → I(V)

## 설계
- 목표: 78장 개별 이미지 파일 확보
- 배치 경로: `mobile/assets/images/universal_waite/`
- 참고: rws_deck.json에 이미 78장의 cardId 정의 있음

## 체크포인트 & 컨텍스트 관리

| 체크포인트 | 산출물 | 컨텍스트 조치 |
|-----------|--------|-------------|
| /scope 완료 | 이 문서 | /clear — research가 독립적 웹 탐색 |
| /research 완료 | Research 문서 | mid-eval 후 판단 |
| /makeplan 완료 | Plan 문서 | 유지 — impl에서 동일 파일 참조 |
| /implementation 완료 | 에셋 파일 + verify | 완료 |

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
