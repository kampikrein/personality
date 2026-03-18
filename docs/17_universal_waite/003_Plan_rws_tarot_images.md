---
id: "003"
type: plan
title: "RWS Tarot 78장 카드 이미지 다운로드 및 에셋 배치"
created: 2026-03-18
traces_scope: "001"
traces_research: "002"
summary: >
  Internet Archive에서 원본 RWS 78장 PNG(1144x1919) 다운로드 → 700px 너비 리사이즈 →
  cardId 기반 WebP 명명 → mobile/assets/images/rws/ 배치 → rws_deck.json imagePath 업데이트
keywords: [rws, rider-waite-smith, tarot, download, resize, webp, asset-pipeline, cardid-mapping]
---

# 003 — RWS Tarot 78장 카드 이미지 다운로드 및 에셋 배치

## Goal

Research(002)에서 확인한 Internet Archive 소스로부터 원본 RWS 78장 + 카드 뒷면 이미지를 다운로드하고,
cardId 기반으로 명명하여 모바일 앱 에셋으로 배치한다. rws_deck.json의 imagePath도 업데이트.

## Scope

### Included
| # | Item | Description |
|---|------|-------------|
| 1 | 이미지 다운로드 | Internet Archive에서 78장 PNG + steve-p.org에서 card back |
| 2 | 리사이즈 | 1144×1919 → 700×1173 (너비 700, 비율 유지) |
| 3 | WebP 변환 + 명명 | cardId 기반 명명 (major-00.webp, wands-01.webp 등) |
| 4 | 에셋 배치 | mobile/assets/images/rws/ |
| 5 | pubspec.yaml | 에셋 디렉토리 추가 |
| 6 | rws_deck.json | 78장 imagePath 업데이트 |

### Excluded
| Item | Reason/Timeline |
|------|-----------------|
| Universal Waite 이미지 | 저작권 보호 중, 무료 고해상도 부재 |
| CardBodyComponent 통합 | 별도 태스크 |

## Structural Decisions

No structural decisions required — straightforward asset pipeline with name mapping.

---

## File Change Summary

### New Files
| # | File Path | Description |
|---|-----------|-------------|
| 1-78 | mobile/assets/images/rws/major-00.webp ~ pentacles-14.webp | 78장 카드 이미지 (700×1173, WebP) |
| 79 | mobile/assets/images/rws/card_back.webp | 카드 뒷면 이미지 |

### Modified Files
| # | File Path | Change Description |
|---|-----------|-------------------|
| 1 | mobile/pubspec.yaml | assets/images/rws/ 디렉토리 추가 |
| 2 | mobile/assets/data/rws_deck.json | 78장 imagePath 업데이트 |

---

## Step 1 — 원본 이미지 다운로드 (매핑 스크립트)

### Approach
Internet Archive 파일명 → cardId 매핑 딕셔너리를 사용하여 다운로드와 동시에 올바른 파일명으로 저장.

### Major Arcana Mapping (cardId → IA filename)
```
major-00 → major_arcana_fool
major-01 → major_arcana_magician
major-02 → major_arcana_priestess
major-03 → major_arcana_empress
major-04 → major_arcana_emperor
major-05 → major_arcana_hierophant
major-06 → major_arcana_lovers
major-07 → major_arcana_chariot
major-08 → major_arcana_strength
major-09 → major_arcana_hermit
major-10 → major_arcana_fortune
major-11 → major_arcana_justice
major-12 → major_arcana_hanged
major-13 → major_arcana_death
major-14 → major_arcana_temperance
major-15 → major_arcana_devil
major-16 → major_arcana_tower
major-17 → major_arcana_star
major-18 → major_arcana_moon
major-19 → major_arcana_sun
major-20 → major_arcana_judgement
major-21 → major_arcana_world
```

### Minor Arcana Mapping (number → rank)
```
01 → ace
02-10 → 2-10
11 → page
12 → knight
13 → queen
14 → king
```
Pattern: `{suit}-{nn}` → `minor_arcana_{suit}_{rank}`

### Script
```bash
BASE="https://archive.org/download/rider-waite-tarot"
DEST=".claude/tmp/rws_originals"
mkdir -p "$DEST"

# Major Arcana
declare -A MAJOR_MAP=(
  [major-00]=major_arcana_fool [major-01]=major_arcana_magician
  [major-02]=major_arcana_priestess [major-03]=major_arcana_empress
  [major-04]=major_arcana_emperor [major-05]=major_arcana_hierophant
  [major-06]=major_arcana_lovers [major-07]=major_arcana_chariot
  [major-08]=major_arcana_strength [major-09]=major_arcana_hermit
  [major-10]=major_arcana_fortune [major-11]=major_arcana_justice
  [major-12]=major_arcana_hanged [major-13]=major_arcana_death
  [major-14]=major_arcana_temperance [major-15]=major_arcana_devil
  [major-16]=major_arcana_tower [major-17]=major_arcana_star
  [major-18]=major_arcana_moon [major-19]=major_arcana_sun
  [major-20]=major_arcana_judgement [major-21]=major_arcana_world
)

for cardId in "${!MAJOR_MAP[@]}"; do
  iaFile="${MAJOR_MAP[$cardId]}"
  curl -sL "${BASE}/${iaFile}.png" -o "${DEST}/${cardId}.png"
  echo "${cardId} OK"
done

# Minor Arcana
declare -A RANK_MAP=([01]=ace [02]=2 [03]=3 [04]=4 [05]=5 [06]=6 [07]=7 [08]=8 [09]=9 [10]=10 [11]=page [12]=knight [13]=queen [14]=king)

for suit in wands cups swords pentacles; do
  for num in 01 02 03 04 05 06 07 08 09 10 11 12 13 14; do
    rank="${RANK_MAP[$num]}"
    cardId="${suit}-${num}"
    iaFile="minor_arcana_${suit}_${rank}"
    curl -sL "${BASE}/${iaFile}.png" -o "${DEST}/${cardId}.png"
    echo "${cardId} OK"
  done
done

# Card back from steve-p.org
curl -sL "https://steve-p.org/cards/pix/RWSa-X-BA.png" \
  -o "${DEST}/card_back.png"
echo "card_back OK"
```

---

## Step 2 — 리사이즈 (700px 너비, 비율 유지)

### Approach
sips -Z로 비율 유지 리사이즈. 원본 1144×1919 → 너비 700 기준 높이 ~1173.

```bash
mkdir -p .claude/tmp/rws_resized
for f in .claude/tmp/rws_originals/*.png; do
  base=$(basename "$f")
  sips -Z 1173 "$f" --out ".claude/tmp/rws_resized/$base" 2>/dev/null
done
```

Note: sips -Z는 가로/세로 중 긴 쪽을 기준으로 비율 유지. 1919 → 1173은 약 0.611 배율, 너비는 1144 × 0.611 ≈ 700.

---

## Step 3 — WebP 변환

```bash
mkdir -p mobile/assets/images/rws

for f in .claude/tmp/rws_resized/*.png; do
  base=$(basename "$f" .png)
  cwebp -q 85 "$f" -o "mobile/assets/images/rws/${base}.webp"
done
```

---

## Step 4 — pubspec.yaml 업데이트

### Current Code
```yaml
# mobile/pubspec.yaml:61-63
  assets:
    - assets/data/
    - assets/images/iching_holitzka/
```

### After Code
```yaml
  assets:
    - assets/data/
    - assets/images/iching_holitzka/
    - assets/images/rws/
```

---

## Step 5 — rws_deck.json imagePath 업데이트

### Approach
Python 스크립트로 78장의 imagePath를 일괄 업데이트:
`"assets/images/placeholder.png"` → `"assets/images/rws/{cardId}.webp"`

```python
import json

with open('mobile/assets/data/rws_deck.json') as f:
    data = json.load(f)

for card in data['cards']:
    card['imagePath'] = f"assets/images/rws/{card['cardId']}.webp"

with open('mobile/assets/data/rws_deck.json', 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
```

---

## Step 6 — 검증

```bash
# 파일 수 확인 (79개: 78 cards + 1 back)
ls mobile/assets/images/rws/*.webp | wc -l

# 첫 번째 파일 해상도 확인
sips -g pixelHeight -g pixelWidth mobile/assets/images/rws/major-00.webp

# 총 크기 확인
du -sh mobile/assets/images/rws/

# rws_deck.json imagePath 확인
python3 -c "
import json
with open('mobile/assets/data/rws_deck.json') as f:
    data = json.load(f)
placeholder_count = sum(1 for c in data['cards'] if 'placeholder' in c['imagePath'])
print(f'Placeholder remaining: {placeholder_count}')
print(f'Sample: {data[\"cards\"][0][\"imagePath\"]}')
"
```

---

## Considerations & Trade-offs

### Alternative Approaches
| Approach | Pros | Cons | Decision |
|----------|------|------|----------|
| Universal Waite (tarot.com) | 정확한 덱 | 197×342 해상도 부족 | 불채택 |
| **원본 RWS (Internet Archive)** | **1144×1919, Public Domain** | **Universal Waite와 채색 차이** | **채택** |
| RWS (steve-p.org) | 1086×1810, card back 포함 | IA보다 약간 낮은 해상도 | 보조 (card back만) |

### Potential Risks
- Internet Archive 302 redirect로 다운로드 속도가 느릴 수 있음
- card_back은 steve-p.org에서 가져오므로 비율이 다를 수 있음 → sips -Z로 비율 유지

### Backward Compatibility
rws_deck.json의 imagePath 변경은 현재 placeholder이므로 영향 없음.

## Implementation Checklist

- [x] Step 1: 78장 + card_back 다운로드 (cardId 매핑 적용)
- [x] Step 2: 700×~1173 리사이즈 (실제: 699×1173)
- [x] Step 3: WebP 변환 → mobile/assets/images/rws/
- [x] Step 4: pubspec.yaml 에셋 디렉토리 추가
- [x] Step 5: rws_deck.json imagePath 업데이트 (78장, placeholder 0)
- [x] Step 6: 파일 수(79), 해상도(699×1173), 크기(17MB), imagePath 검증

## Verification Assertions

| Level | Assertion | Verification Method | Expected Result |
|-------|-----------|-------------------|-----------------|
| L2-CLI | 이미지 파일 수 | `ls *.webp \| wc -l` | 79 |
| L2-CLI | 첫 번째 카드 해상도 | `sips -g pixelWidth major-00.webp` | ~700 |
| L2-CLI | 총 에셋 크기 | `du -sh rws/` | < 15MB |
| L2-CLI | placeholder 제거 | python3 JSON 검사 | 0 remaining |
| L1-Build | pubspec.yaml 에셋 등록 | flutter pub get | 에러 없음 |

## References

| Resource | Path/URL | Related Content |
|----------|---------|-----------------|
| Scope 문서 | docs/17_universal_waite/001_Scope_universal_waite_images.md | 작업 목표 |
| Research 문서 | docs/17_universal_waite/002_Research_universal_waite_images.md | 이미지 소스, 매핑 |
| Internet Archive | https://archive.org/details/rider-waite-tarot | 78장 PNG 소스 |
| steve-p.org | https://steve-p.org/cards/RWSa.html | card back 소스 |
| rws_deck.json | mobile/assets/data/rws_deck.json | 카드 데이터 + imagePath |
