---
id: "003"
type: plan
title: "I Ching Holitzka 64장 카드 이미지 다운로드 및 에셋 배치"
created: 2026-03-18
traces_scope: "001"
traces_research: "002"
summary: >
  steve-p.org에서 64장 + 뒷면 PNG 다운로드 → sips로 700×1212 리사이즈 →
  cwebp로 WebP 변환 → mobile/assets/images/iching_holitzka/ 배치 → pubspec.yaml 업데이트
keywords: [i-ching, holitzka, download, resize, webp, asset-pipeline]
---

# 003 — I Ching Holitzka 64장 카드 이미지 다운로드 및 에셋 배치

## Goal

Research(002)에서 확인한 steve-p.org 소스로부터 I Ching Holitzka 64장 + 뒷면 이미지를 다운로드하고,
모바일 앱에 최적화된 형태로 가공하여 에셋 디렉토리에 배치한다.

## Scope

### Included
| # | Item | Description |
|---|------|-------------|
| 1 | 이미지 다운로드 | 64장 hexagram + 1장 card back PNG 다운로드 |
| 2 | 리사이즈 | 1400×2424 → 700×1212 (2x 레티나 대응) |
| 3 | WebP 변환 | PNG → WebP (quality 85) 파일 크기 최적화 |
| 4 | 에셋 배치 | mobile/assets/images/iching_holitzka/ 디렉토리에 배치 |
| 5 | pubspec.yaml | 에셋 디렉토리 등록 |

### Excluded
| Item | Reason/Timeline |
|------|-----------------|
| 덱 JSON 데이터 파일 | 별도 태스크 (카드 이름/의미 데이터 구성 필요) |
| 앱 코드 통합 | CardBodyComponent 이미지 렌더링은 별도 태스크 |
| 1x/3x 해상도 변형 | 우선 2x만 — 필요 시 추후 추가 |

## Structural Decisions

No structural decisions required — straightforward asset pipeline.

---

## File Change Summary

### New Files
| # | File Path | Description |
|---|-----------|-------------|
| 1-64 | mobile/assets/images/iching_holitzka/hexagram_01.webp ~ hexagram_64.webp | 64장 카드 이미지 (700×1212, WebP) |
| 65 | mobile/assets/images/iching_holitzka/card_back.webp | 카드 뒷면 이미지 |

### Modified Files
| # | File Path | Change Description |
|---|-----------|-------------------|
| 1 | mobile/pubspec.yaml | assets/images/iching_holitzka/ 디렉토리 추가 |

---

## Step 1 — 원본 이미지 다운로드

### Approach
curl로 65장(64 hexagram + 1 back) PNG 일괄 다운로드. 임시 디렉토리에 저장.

### Script
```bash
# 임시 다운로드 디렉토리
mkdir -p /tmp/iching_holitzka_originals

# 64장 hexagram 다운로드
for i in $(seq -w 1 64); do
  curl -sL "https://steve-p.org/cards/pix/IHol-H-${i}.png" \
    -o "/tmp/iching_holitzka_originals/IHol-H-${i}.png"
  echo "Downloaded H-${i}"
done

# 카드 뒷면 다운로드
curl -sL "https://steve-p.org/cards/pix/IHol-X-BA.png" \
  -o "/tmp/iching_holitzka_originals/IHol-X-BA.png"
echo "Downloaded card back"
```

### Considerations
- 총 ~165MB 다운로드 (64 × ~2.5MB + 5.2MB back)
- 네트워크 속도에 따라 2~5분 소요
- 다운로드 실패 시 개별 파일 재시도 가능

---

## Step 2 — 리사이즈 (1400×2424 → 700×1212)

### Approach
macOS `sips` 명령으로 일괄 리사이즈. 2x 레티나 해상도(700×1212)로 축소.

### Script
```bash
mkdir -p /tmp/iching_holitzka_resized

for i in $(seq -w 1 64); do
  sips -z 1212 700 "/tmp/iching_holitzka_originals/IHol-H-${i}.png" \
    --out "/tmp/iching_holitzka_resized/hexagram_${i}.png"
done

sips -z 1212 700 "/tmp/iching_holitzka_originals/IHol-X-BA.png" \
  --out "/tmp/iching_holitzka_resized/card_back.png"
```

### Considerations
- sips는 macOS 기본 도구 (추가 설치 불필요)
- 비율 유지: 1400/2424 ≈ 0.5776, 700/1212 ≈ 0.5776 — 동일
- card_back은 해상도가 다를 수 있으므로 sips -z 대신 비율 기반 리사이즈가 더 안전할 수 있음

---

## Step 3 — WebP 변환

### Approach
`cwebp` (Google WebP 도구)로 PNG → WebP 변환. quality 85로 파일 크기 최적화.

### Script
```bash
# cwebp 설치 확인 (없으면 brew install webp)
mkdir -p mobile/assets/images/iching_holitzka

for i in $(seq -w 1 64); do
  cwebp -q 85 "/tmp/iching_holitzka_resized/hexagram_${i}.png" \
    -o "mobile/assets/images/iching_holitzka/hexagram_${i}.webp"
done

cwebp -q 85 "/tmp/iching_holitzka_resized/card_back.png" \
  -o "mobile/assets/images/iching_holitzka/card_back.webp"
```

### Considerations
- WebP quality 85: 시각적 손실 거의 없음, PNG 대비 ~70-80% 크기 절감
- 예상 결과: 각 파일 ~30-80KB, 총 ~2-5MB
- cwebp 미설치 시: `brew install webp` 선행 필요
- 대안: cwebp 불가 시 sips로 JPEG 변환도 가능하나 WebP 권장

---

## Step 4 — pubspec.yaml 업데이트

### Current Code
```yaml
# mobile/pubspec.yaml:61-62
flutter:
  uses-material-design: true
  assets:
    - assets/data/
```

### After Code
```yaml
# mobile/pubspec.yaml
flutter:
  uses-material-design: true
  assets:
    - assets/data/
    - assets/images/iching_holitzka/
```

---

## Step 5 — 검증

### Approach
다운로드된 파일 수, 리사이즈 결과, WebP 변환 결과를 확인.

```bash
# 파일 수 확인 (65개 예상: 64 hexagram + 1 back)
ls mobile/assets/images/iching_holitzka/*.webp | wc -l

# 첫 번째 파일 해상도 확인
sips -g pixelHeight -g pixelWidth mobile/assets/images/iching_holitzka/hexagram_01.webp

# 파일 크기 합계 확인
du -sh mobile/assets/images/iching_holitzka/
```

---

## Considerations & Trade-offs

### Alternative Approaches
| Approach | Pros | Cons | Decision |
|----------|------|------|----------|
| 원본 PNG 그대로 사용 | 최고 화질 | ~165MB 번들 크기 | 불채택 |
| JPEG 변환 | 범용, 별도 도구 불필요 | WebP 대비 ~30% 큰 파일 | 대안 |
| **WebP 700×1212** | **최적 크기+화질 균형** | **cwebp 필요** | **채택** |
| 350×606 (1x) | 최소 크기 | 레티나 디스플레이에서 흐릿 | 불채택 |

### Potential Risks
- cwebp 미설치 시 brew 설치 필요 (네트워크 필요)
- steve-p.org 서버 일시 다운 가능성 (낮음 — 2026-03-18 전체 200 OK 확인)
- card_back 이미지 비율이 다를 수 있음 → sips -Z (비율 유지 리사이즈) 사용 권장

### Backward Compatibility
기존 앱 코드에 영향 없음 — 에셋 추가만 수행.

## Implementation Checklist

- [x] Step 1: 64장 + card_back PNG 다운로드 (/tmp/)
- [x] Step 2: 700×1212 리사이즈
- [x] Step 3: WebP 변환 → mobile/assets/images/iching_holitzka/
- [x] Step 4: pubspec.yaml 에셋 디렉토리 추가
- [x] Step 5: 파일 수(65), 해상도(700×1212), 총 크기(5.4MB) 검증

## Verification Assertions

| Level | Assertion | Verification Method | Expected Result |
|-------|-----------|-------------------|-----------------|
| L2-CLI | 이미지 파일 수 | `ls *.webp \| wc -l` | 65 |
| L2-CLI | 첫 번째 카드 해상도 | `sips -g pixelWidth hexagram_01.webp` | 700 |
| L2-CLI | 총 에셋 크기 | `du -sh iching_holitzka/` | < 10MB |
| L1-Build | pubspec.yaml 에셋 등록 | Flutter 빌드 | 에러 없음 |

## References

| Resource | Path/URL | Related Content |
|----------|---------|-----------------|
| Scope 문서 | docs/16_iching_holitzka/001_Scope_iching_holitzka_images.md | 작업 목표, 접근 방향 |
| Research 문서 | docs/16_iching_holitzka/002_Research_iching_holitzka_images.md | 이미지 소스, URL 패턴, 해상도 |
| steve-p.org | https://steve-p.org/cards/IHol.html | 이미지 소스 갤러리 |
| pubspec.yaml | mobile/pubspec.yaml | Flutter 에셋 등록 |
