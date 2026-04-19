---
id: "002"
type: research
title: "Universal Waite Tarot 78장 카드 이미지 소스 조사"
created: 2026-03-18
traces_scope: "001"
summary: >
  Universal Waite 전용 고해상도 이미지는 무료 소스 부재 (최대 197x342).
  대안으로 원본 RWS(공유 저작물) 78장을 Internet Archive(1144x1919) 또는
  steve-p.org(1086x1810)에서 고해상도 PNG로 확보 가능.
keywords: [universal-waite, rider-waite-smith, rws, image-source, internet-archive, steve-p.org, public-domain]
---

# Universal Waite Tarot 78장 카드 이미지 소스 조사

## Research Overview

### Background & Motivation
모바일 앱의 타로카드 이미지로 사용할 Universal Waite Tarot 78장의 고해상도 이미지를 확보하기 위해
웹에서 사용 가능한 이미지 소스를 조사함.

### Research Scope
- Universal Waite (Mary Hanson-Roberts 리컬러링) 전용 이미지 소스 탐색
- 원본 RWS (Pamela Colman Smith, 1909) 대안 소스 탐색
- 이미지 해상도, 포맷, 접근성, 저작권 상태 평가

### Research Perspective
1. **이미지 소스 가용성** — Universal Waite 및 원본 RWS의 고해상도 이미지 접근성 조사

---

## 핵심 발견: Universal Waite vs 원본 RWS

### 저작권 상태

| 덱 | 아티스트 | 출판년 | 저작권 상태 |
|----|---------|--------|-----------|
| **원본 RWS** | Pamela Colman Smith | 1909 | **Public Domain** (미국, 100년+ 경과) |
| **Universal Waite** | Mary Hanson-Roberts (리컬러링) | 1990 | **저작권 보호 중** (U.S. Games Systems) |

### Universal Waite 이미지 소스 (저작권 보호 중)

| 소스 | 카드 수 | 최대 해상도 | 평가 |
|------|---------|-----------|------|
| tarot.com full_size | 78/78 | 197×342 | **부족** — 모바일 앱에 최소 수준 미달 |
| tarot.com mid_size | 78/78 | 104×180 | 너무 작음 |
| aeclectic.net | 9/78 | 불명 | 불완전 |
| learntarot.com | 5/78 | 불명 (GIF) | 불완전 |
| Etsy (유료) | 78/78 | ~1100×1920 | 유료 디지털 다운로드 |

**결론**: Universal Waite 전용 무료 고해상도 이미지는 존재하지 않음.

---

## 대안 소스: 원본 RWS (Public Domain)

### 소스 1: Internet Archive (추천)

- **URL**: `https://archive.org/download/rider-waite-tarot/{filename}.png`
- **해상도**: 1144 × 1919 px (400+ DPI 스캔)
- **포맷**: PNG
- **카드 수**: 78장 전체
- **라이선스**: Public Domain Mark 1.0
- **총 크기**: ~263.5MB

**파일 명명 규칙**:

Major Arcana (22장):
```
major_arcana_fool.png
major_arcana_magician.png
major_arcana_priestess.png
major_arcana_empress.png
major_arcana_emperor.png
major_arcana_hierophant.png
major_arcana_lovers.png
major_arcana_chariot.png
major_arcana_strength.png
major_arcana_hermit.png
major_arcana_fortune.png
major_arcana_justice.png
major_arcana_hanged.png
major_arcana_death.png
major_arcana_temperance.png
major_arcana_devil.png
major_arcana_tower.png
major_arcana_star.png
major_arcana_moon.png
major_arcana_sun.png
major_arcana_judgement.png
major_arcana_world.png
```

Minor Arcana (56장) — 4개 suit × 14장:
```
minor_arcana_{suit}_{rank}.png
suit: cups, pentacles, swords, wands
rank: ace, 2, 3, 4, 5, 6, 7, 8, 9, 10, page, knight, queen, king
```

### 소스 2: steve-p.org

- **URL**: `https://steve-p.org/cards/pix/RWSa-{suit}-{rank}.png`
- **해상도**: 1086 × 1810 px
- **포맷**: PNG
- **카드 수**: 78장 + 추가 (card back, rules leaflet)
- **갤러리**: https://steve-p.org/cards/RWSa.html

**파일 명명 규칙**:

| 카테고리 | 코드 | 범위 |
|---------|------|------|
| Major Arcana (Trumps) | T | T-00 ~ T-21 |
| Pentacles | P | P-0A, P-02~P-10, P-J1(Page), P-J2(Knight), P-QU, P-KI |
| Wands | W | W-0A, W-02~W-10, W-J1, W-J2, W-QU, W-KI |
| Cups | C | C-0A, C-02~C-10, C-J1, C-J2, C-QU, C-KI |
| Swords | S | S-0A, S-02~S-10, S-J1, S-J2, S-QU, S-KI |
| Extras | X | X-BA(back), X-RL(rules) |

### 소스 비교

| 기준 | Internet Archive | steve-p.org |
|------|-----------------|-------------|
| 해상도 | **1144×1919** | 1086×1810 |
| 라이선스 | Public Domain 명시 | 명시 없음 |
| 파일명 | 영문 카드명 (직관적) | 약어 코드 (매핑 필요) |
| 다운로드 | 302 redirect (약간 느림) | 직접 다운로드 |
| 카드 뒷면 | 없음 | 있음 (X-BA) |
| 추가 에셋 | 없음 | rules leaflet |

**추천**: Internet Archive — 더 높은 해상도 + 명시적 Public Domain + 직관적 파일명.
카드 뒷면이 필요하면 steve-p.org의 `RWSa-X-BA.png`을 보조로 사용.

---

## rws_deck.json과의 매핑

현재 `mobile/assets/data/rws_deck.json`의 cardId 체계:

| cardId 패턴 | 예시 | Internet Archive 파일 | 매핑 |
|-----------|------|---------------------|------|
| major-00 ~ major-21 | major-00 (The Fool) | major_arcana_fool.png | 이름 기반 매핑 필요 |
| wands-01 ~ wands-14 | wands-01 (Ace) | minor_arcana_wands_ace.png | rank 매핑 필요 |
| cups-01 ~ cups-14 | cups-01 (Ace) | minor_arcana_cups_ace.png | rank 매핑 필요 |
| swords-01 ~ swords-14 | swords-01 (Ace) | minor_arcana_swords_ace.png | rank 매핑 필요 |
| pentacles-01 ~ pentacles-14 | pentacles-01 (Ace) | minor_arcana_pentacles_ace.png | rank 매핑 필요 |

**매핑 스크립트가 필요함**: Internet Archive 파일명 → cardId 기반 파일명 변환.

---

## Comprehensive Conclusion

### 핵심 발견 (우선순위 순)

1. **[Critical] R-002-F1: Universal Waite 무료 고해상도 부재** — Universal Waite(1990)는 저작권 보호 중이며, 무료 고해상도 소스 없음. 최대 197×342(tarot.com). *(관점 1)*

2. **[Critical] R-002-F2: 원본 RWS 고해상도 확보 가능** — Internet Archive에서 78장 전체를 1144×1919 PNG, Public Domain으로 다운로드 가능. 모바일 앱에 충분한 해상도. *(관점 1)*

3. **[High] R-002-F3: 카드 뒷면 보조 소스** — steve-p.org에서 RWS 카드 뒷면(RWSa-X-BA.png, 1086×1810) 확보 가능. *(관점 1)*

4. **[Medium] R-002-F4: 파일명 매핑 필요** — Internet Archive 파일명(영문 카드명)과 rws_deck.json의 cardId(major-00 등) 간 매핑 스크립트가 필요함. *(관점 1)*

## Unresolved Items

None — 두 소스 모두 78장 전체 확인 완료.

## Referenced Sources

| 소스 | URL | 역할 |
|------|-----|------|
| Internet Archive | https://archive.org/details/rider-waite-tarot | 78장 400+ DPI PNG (Public Domain) |
| steve-p.org RWS | https://steve-p.org/cards/RWSa.html | 78장 + 카드 뒷면 PNG |
| tarot.com | https://www.tarot.com/tarot/decks/universal-waite | Universal Waite 78장 (저해상도) |
| learntarot.com | https://learntarot.com/uwdesc.htm | Universal Waite 5장 샘플 |
| aeclectic.net | https://www.aeclectic.net/tarot/cards/universal-waite/ | Universal Waite 9장 리뷰 |

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
