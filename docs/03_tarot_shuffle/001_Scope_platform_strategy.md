---
id: "001"
type: scope
title: "타로 셔플 앱 플랫폼 전략"
created: 2026-03-15
complexity: simple
research_needed: true
research_reason: "Flutter 셔플 엔진(물리 엔진 + 센서 API + CSPRNG) 구현 패턴, 기존 타로 앱 아키텍처 조사 필요"
auto_run: false
intent: >
  타로 셔플 앱의 플랫폼 전략 결정. 웹 데스크탑 먼저 개발 후 안드로이드로 갈지,
  안드로이드(Flutter) 먼저 완성 후 웹/iOS로 확장할지 최적 경로를 도출한다.
summary: >
  Android(Flutter) 먼저 개발 권장. PRD 핵심 차별화 요소(센서 기반 셔플, 햅틱 피드백)가
  모바일에서만 검증 가능하며, Flutter 크로스 플랫폼으로 iOS/Web 확장이 자연스럽다.
keywords: [tarot, shuffle, flutter, android, platform-strategy, mobile-first]
---

# 타로 셔플 앱 플랫폼 전략

## 작업 목표
- PRD(docs/003_gemini_deep_research.md) 기반 타로 셔플 앱 개발 시작
- 플랫폼 진입 순서 결정: Web Desktop → Android vs Android → Web/iOS
- 성공 기준: 핵심 가설(물리적 셔플 경험의 차별화)을 가장 빠르게 검증할 수 있는 경로 선택

## 접근 방향
**Android(Flutter) 먼저** → iOS → Web 순서.

근거:
1. PRD 핵심 가치(자이로스코프/가속도계 기반 셔플, 햅틱 피드백)는 모바일 하드웨어 전용
2. 웹에서는 핵심 가설 자체를 검증할 수 없음 (Web Sensor API 제한적, 데스크탑에선 무의미)
3. Flutter 단일 코드베이스로 Android → iOS(거의 무료) → Web(인터랙션 대체) 확장
4. 타로 앱 시장 자체가 모바일 중심 (MZ세대 타겟)

대안 검토:
- 웹 먼저: 빠른 반복 가능하나 핵심 차별화 미검증, 모바일 전환 시 인터랙션 레이어 전면 재구축
- 하이브리드: Flutter Web으로 비주얼 프로토타이핑 가능하나 초기 복잡도 증가, 반쪽짜리 프로토타입

## Research 판단
- **판단**: 필요
- **근거**: Flutter 물리 엔진(Flame/Forge2D 등) + 센서 API + CSPRNG 통합 구현 패턴 조사 필요. 프로젝트에 유사 패턴 없음 (mobile/은 빈 스켈레톤). 커스텀 셔플 알고리즘의 기술적 실현 가능성 검증 필요.
- **파이프라인**: S → R → P → I(V)

## 설계

### 개발 순서
```
Phase 1: Android MVP (Flutter)
  - 셔플 코어 엔진 (CSPRNG + 센서 엔트로피)
  - 기본 덱 (RWS 78장 데이터 + 이미지)
  - 3가지 셔플 모션 (리플, 오버핸드, 워시)
  - 기본 스프레드 (1장, 3장, 켈틱 크로스)
  - 오프라인 SQLite 저장소

Phase 2: 커스텀 덱 + 고도화
  - 커스텀 덱 등록 (JSON 스키마 기반)
  - 대량 업로드 UI
  - 하이브리드 덱 혼합

Phase 3: 서버 연동 + iOS
  - Rails API (클라우드 동기화)
  - iOS 빌드 (Flutter 크로스 플랫폼)

Phase 4: 웹 + 소셜
  - Flutter Web (셔플 인터랙션 → 마우스/키보드 대체)
  - 커뮤니티/바운티 시스템
```

### 변경 대상 파일/모듈
- `mobile/` — Flutter 앱 전체 (현재 빈 스켈레톤)
- `server/` — Phase 3에서 API 추가
- `shared/` — OpenAPI 스키마 (Phase 3)

### 핵심 기술 결정 포인트 (Research 대상)
1. Flutter 물리 엔진 선택: Flame vs Forge2D vs 자체 구현
2. 센서 API 패키지: sensors_plus 등
3. CSPRNG 구현: dart:math vs pointycastle
4. 로컬 DB: sqflite vs drift vs hive
5. 카드 애니메이션: Flutter 자체 AnimationController vs Rive

## 체크포인트 & 컨텍스트 관리

| 체크포인트 | 산출물 | 컨텍스트 조치 | 판단 기준 |
|-----------|--------|-------------|----------|
| /scope 완료 | 이 문서 | /clear | research가 독립적 넓은 탐색 수행 |
| /research 완료 | Research 문서 | /clear | research 광범위 탐색 → makeplan에 노이즈 |
| /makeplan 완료 | Plan 문서 | 매트릭스 판단 | plan에서 읽은 파일 = impl에서 수정할 파일이면 유지 |

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
