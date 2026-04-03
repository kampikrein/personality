---
id: "001"
type: scope
title: "I Ching Holitzka 64장 카드 이미지 확보"
created: 2026-03-18
complexity: simple
research_needed: true
research_reason: "외부 웹에서 I Ching Holitzka 카드 이미지 소스를 찾아야 함"
auto_run: true
effort_mode: light
uncertainty_level: medium
intent: >
  I Ching Holitzka 오라클 카드 64장의 고해상도 이미지를 확보하여
  모바일 앱의 타로카드 이미지로 사용. 개별 고해상도 이미지를 우선 탐색하되,
  없으면 합본/그리드 이미지에서 크롭하는 방식도 허용.
summary: >
  외부 이미지 소스 탐색(research) → 다운로드/크롭 전략 수립(plan) → 에셋 배치(impl)
keywords: [i-ching, holitzka, oracle-cards, 64-hexagrams, card-images, asset-acquisition]
---

# I Ching Holitzka 64장 카드 이미지 확보

## 작업 목표
- I Ching Holitzka (Klaus Holitzka 일러스트) 64괘 오라클 카드 이미지 확보
- 타로카드 비율에 적합한 고해상도 이미지 (최소 300px 이상 너비 권장)
- 개별 이미지 우선, 불가 시 합본 이미지 크롭
- 최종 배치: `mobile/assets/images/iching_holitzka/`

## 접근 방향
1. **웹 탐색**: 개별 카드 고해상도 이미지 소스 탐색 (공식 사이트, 갤러리, 리뷰 등)
2. **대안**: 합본/그리드/전체덱 이미지 탐색 → 크롭 스크립트로 개별 분리
3. **에셋 정리**: 64장을 번호 체계로 명명하여 앱 에셋 디렉토리에 배치

## Research 판단
- **판단**: 필요
- **근거**: 외부 웹에서 이미지 소스를 찾아야 하며, 이미지 품질/해상도/가용성 조사 필요
- **파이프라인**: S → R → P → I(V)

## 설계
- 목표: 64장 개별 이미지 파일 확보
- 파일 명명: `hexagram_01.png` ~ `hexagram_64.png` (또는 원본 포맷)
- 배치 경로: `mobile/assets/images/iching_holitzka/`
- 크롭 필요 시: Python/Dart 스크립트로 그리드 이미지 분할

## 체크포인트 & 컨텍스트 관리

| 체크포인트 | 산출물 | 컨텍스트 조치 |
|-----------|--------|-------------|
| /scope 완료 | 이 문서 | /clear — research가 독립적 웹 탐색 |
| /research 완료 | Research 문서 | mid-eval 후 판단 |
| /makeplan 완료 | Plan 문서 | 유지 — impl에서 동일 파일 참조 |
| /implementation 완료 | 에셋 파일 + verify | 완료 |
