---
id: "016"
type: scope
title: "뽑기 결과 화면 UI 3건 수정"
created: 2026-04-05
traces_brief: "015"
complexity: simple
research_needed: false
research_reason: "모든 이슈가 코드 표면에서 파악 가능, 기존 패턴 활용"
auto_run: true
effort_mode: bypass
tdd_mode: false
uncertainty_level: low
intent: >
  즉시/연출 뽑기 결과 화면의 바텀 오버플로우 수정, 카드 이미지 표시 복원, '성찰의 시간' 해설 섹션 제거.
summary: >
  단일 영역(뽑기 결과 UI) 4-5개 파일 수정. 오버플로우 레이아웃 조정, 이미지 로딩 원인 규명 및 수정, 성찰 섹션 삭제.
keywords: [draw, overflow, card-image, reflection, ui-fix]
---

# 뽑기 결과 화면 UI 3건 수정

## 작업 목표
Brief 015의 3가지 이슈를 수정한다:
1. 카드 위젯 바텀 오버플로우 3.3px 해소
2. 카드 앞면 이미지 errorBuilder 폴백 대신 실제 이미지 표시
3. '성찰의 시간' 카드 해설 섹션 제거 (안전 고지는 유지)

## 접근 방향
- **오버플로우**: CardRevealWidget의 Column 내부 spacing/Flexible 조정, 또는 SpreadLayout의 childAspectRatio 조정
- **이미지**: Image.asset 실패 원인 규명 (파일 존재 + pubspec 등록 확인됨 → cacheWidth/LayoutBuilder 이슈 또는 빌드 캐시 가능성). 에뮬레이터에서 디버그 로그 확인
- **성찰 제거**: InstantDrawPage L253-296, AnimatedDrawPage L353-398 블록 삭제. ReflectivePrompts import 제거 (reading_page.dart에서 사용 중이므로 클래스 자체는 유지)

## Research 판단
- **판단**: 불필요
- **근거**: UI 레이아웃 수정 + 에셋 로딩 디버깅 — 기존 패턴 내 변경, 외부 조사 없음
- **파이프라인**: S → Agent(P) → Agent(I) → Agent(V)

## 설계

### Issue 1: 바텀 오버플로우
- **원인 추정**: `CardRevealWidget.build()` — Column(mainAxisSize: min) 안에서 label(bodyMedium) + SizedBox(8) + AspectRatio(2.5/3.5) + 역방향 텍스트가 GridView의 childAspectRatio: 0.65 할당 공간을 미세하게 초과
- **수정 방향**: Column 내부에 Flexible/Expanded 적용하여 카드 이미지 영역을 제약 내에 맞추거나, childAspectRatio 조정

### Issue 2: 카드 이미지 미표시
- **상태**: 파일 존재(`major-00.webp` 등) + pubspec.yaml 등록 정상 → 런타임에서 errorBuilder 트리거
- **수정 방향**: 에뮬레이터에서 에러 로그 확인 → cacheWidth 계산 이슈 또는 빌드 캐시 무효화 필요 여부 판단. 필요 시 flutter clean + rebuild

### Issue 3: 성찰 섹션 제거
- **InstantDrawPage**: L253-296 ('성찰의 시간' 제목 + 카드별 Container 루프) 삭제
- **AnimatedDrawPage**: L353-398 (동일 구조) 삭제
- **import 정리**: 두 파일에서 `reflective_prompts.dart` import 제거
- **주의**: `reading_page.dart`에서 ReflectivePrompts 사용 중 → 클래스/파일 삭제 불가

### 변경 대상 파일

**Modified (actual change)** — confidence: high
| # | File | Change |
|---|------|--------|
| 1 | `mobile/lib/features/reading/presentation/widgets/card_reveal_widget.dart` | 오버플로우 수정 (Column 레이아웃 조정) |
| 2 | `mobile/lib/features/draw/presentation/pages/instant_draw_page.dart` | 성찰 섹션 삭제 + import 정리 |
| 3 | `mobile/lib/features/draw/presentation/pages/animated_draw_page.dart` | 성찰 섹션 삭제 + import 정리 |
| 4 | `mobile/lib/features/reading/presentation/widgets/spread_layout.dart` | childAspectRatio 조정 (필요 시) |

**Reviewed (check-only)**
| # | File | Purpose |
|---|------|---------|
| 1 | `mobile/lib/features/reading/presentation/pages/reading_page.dart` | ReflectivePrompts 사용 확인 (삭제 불가 검증) |
| 2 | `mobile/pubspec.yaml` | 에셋 등록 상태 확인 (변경 불필요 예상) |

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 131s | 302840 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 131s |
| Total Tokens | 302840 |
| Input Tokens | 12 |
| Output Tokens | 7226 |
| Cache Read | 250022 |
| Cache Creation | 45580 |
