---
id: "002"
type: research
title: "I Ching Holitzka 64장 카드 이미지 소스 조사"
created: 2026-03-18
traces_scope: "001"
summary: >
  steve-p.org/cards/pix/ 에서 64장 전체 + 8장 추가 에셋을 1400×2424px PNG로 확보 가능.
  크롭 불필요 — 개별 고해상도 이미지가 모두 존재함.
keywords: [i-ching, holitzka, image-source, steve-p.org, high-resolution, 1400x2424]
---

# I Ching Holitzka 64장 카드 이미지 소스 조사

## Research Overview

### Background & Motivation
모바일 앱의 타로카드 이미지로 사용할 I Ching Holitzka 오라클 카드 64장의 고해상도 이미지를 확보하기 위해,
웹에서 사용 가능한 이미지 소스를 조사함.

### Research Scope
- 개별 카드 고해상도 이미지 소스 탐색 (공식 사이트, 갤러리, 리뷰, 판매 사이트)
- 이미지 해상도, 포맷, 접근성 평가
- 합본/그리드 이미지 대안 확인

### Research Perspective
1. **이미지 소스 가용성** — 공식/비공식 소스에서 개별 또는 합본 이미지의 해상도, 접근성, 다운로드 가능성 조사

---

## 핵심 발견: steve-p.org 고해상도 이미지 소스

### 소스 정보
- **URL 기본**: `https://steve-p.org/cards/`
- **갤러리 페이지**: `https://steve-p.org/cards/IHol.html`
- **원본 이미지 경로**: `https://steve-p.org/cards/pix/IHol-H-{NN}.png`
- **썸네일 경로**: `https://steve-p.org/cards/small/sm_IHol-H-{NN}.webp`

### 이미지 사양

| 항목 | 값 |
|------|-----|
| 포맷 | PNG |
| 해상도 | 1400 × 2424 px |
| 파일 크기 | 약 2~3.3MB/장 |
| 비율 | ~0.578 (물리 카드 70×120mm = 0.583과 일치) |
| 카드 수 | 64장 (hexagram 01~64) 전부 존재 |

### URL 패턴

**Hexagram 카드 (64장)**:
```
https://steve-p.org/cards/pix/IHol-H-01.png
https://steve-p.org/cards/pix/IHol-H-02.png
...
https://steve-p.org/cards/pix/IHol-H-64.png
```

번호: 01~64 (zero-padded 2자리)

**추가 에셋 (8장)**:
```
https://steve-p.org/cards/pix/IHol-X-L1.png   — 리플릿/안내 카드 (~1.4MB)
https://steve-p.org/cards/pix/IHol-X-B1.png   — 보너스 카드 1 (~3.2MB)
https://steve-p.org/cards/pix/IHol-X-B2.png   — 보너스 카드 2 (~1.3MB)
https://steve-p.org/cards/pix/IHol-X-B3.png   — 보너스 카드 3 (~675KB)
https://steve-p.org/cards/pix/IHol-X-B4.png   — 보너스 카드 4 (~476KB)
https://steve-p.org/cards/pix/IHol-X-B5.png   — 보너스 카드 5 (~247KB)
https://steve-p.org/cards/pix/IHol-X-B6.png   — 보너스 카드 6 (~448KB)
https://steve-p.org/cards/pix/IHol-X-BA.png   — 카드 뒷면 디자인 (~5.2MB)
```

### 검증 결과

64장 전체 HTTP 200 확인 (2026-03-18):
- H-01 ~ H-64: 모두 200 OK
- X-L1, X-B1~B6, X-BA: 모두 200 OK

### JavaScript 확대 메커니즘 (참고)

`commonnew.js`의 `dispbig()` 함수가 URL 변환 수행:
```javascript
var bigfile = "pix/" + thclicked.slice(thclicked.lastIndexOf("/sm_")+4).replace(".webp", ".png");
```
`small/sm_IHol-H-01.webp` → `pix/IHol-H-01.png`

---

## 대체 소스 조사 결과

| 소스 | 카드 수 | 해상도 | 평가 |
|------|---------|--------|------|
| **steve-p.org** | **64/64 + 8 추가** | **1400×2424** | **최적 — 완전한 고해상도 세트** |
| learntarot.com | 5/64 | 불명 (GIF) | 불완전, 저화질 |
| tarotworld.com | 5~6 (샘플 스프레드) | 600×~1000 | 개별 카드 아님, 스프레드 사진 |
| usgamesinc.com | 8 (제품 사진) | 제품 사진 | 개별 카드 아님 |
| aiching.app | 0 | - | 기사만, 이미지 없음 |
| Amazon/eBay/Etsy | 1~3 (제품 사진) | 다양 | 제품 사진만 |

**결론**: steve-p.org가 유일한 64장 완전 고해상도 소스.

---

## 구현 전략 제안 (상세는 Plan에서)

### 다운로드
- `curl`로 64장 + 뒷면(IHol-X-BA) 일괄 다운로드
- 총 약 160~200MB (64장 × ~2.5MB)

### 최적화 (모바일용)
- 원본 1400×2424는 앱 번들에 넣기엔 과대 → 리사이즈 필요
- 권장: 700×1212 (2x) 또는 525×909 (1.5x) + WebP 변환
- `sips` (macOS) 또는 ImageMagick으로 배치 리사이즈
- WebP 변환으로 파일 크기 ~80% 절감 가능

### 파일 명명 규칙
- `hexagram_01.webp` ~ `hexagram_64.webp` (앱 내부용)
- `card_back.webp` (뒷면)
- 배치 경로: `mobile/assets/images/iching_holitzka/`

---

## Comprehensive Conclusion

### 핵심 발견 (우선순위 순)

1. **[Critical] R-002-F1: 완전한 고해상도 소스 확보** — steve-p.org/cards/pix/ 에서 64장 전체가 1400×2424 PNG로 개별 다운로드 가능. 크롭 불필요. *(관점 1)*

2. **[High] R-002-F2: 카드 뒷면 포함** — IHol-X-BA.png (5.2MB)로 카드 뒷면 디자인도 확보 가능. 앱에서 카드 뒤집기 애니메이션에 활용 가능. *(관점 1)*

3. **[High] R-002-F3: 모바일 최적화 필요** — 원본 1400×2424 PNG (~2.5MB/장)는 앱 번들에 부적합. 리사이즈 + WebP 변환으로 ~50-100KB/장까지 축소 가능. *(관점 1)*

4. **[Medium] R-002-F4: URL 패턴 안정적** — 번호 체계가 단순 (01~64 zero-padded), curl 스크립트로 일괄 다운로드 용이. *(관점 1)*

## Unresolved Items

None — 64장 전체 + 추가 에셋 모두 확인 완료.

## Referenced Sources

| 소스 | URL | 역할 |
|------|-----|------|
| steve-p.org 갤러리 | https://steve-p.org/cards/IHol.html | 64장 카드 이미지 갤러리 |
| steve-p.org JS | https://steve-p.org/cards/commonnew.js | 이미지 확대 URL 패턴 발견 |
| U.S. Games Systems | https://www.usgamesinc.com/i-ching-holitzka-deck.html | 공식 출판사 제품 정보 |
| learntarot.com | http://www.learntarot.com/ihdesc.htm | 카드 설명 + 5장 샘플 |
| tarotworld.com | https://www.tarotworld.com/product/i-ching-by-klaus-holitzka/ | 제품 리뷰 + 스프레드 사진 |

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
