---
id: "002"
type: brief
title: "뽑기 설정 통합 — 유저/설정에서 뽑기 탭으로 메뉴 재배치"
created: 2026-04-17
status: in-progress
quality_profile: standard
deep_critique: false
critique_docs: []
summary: >
  유저 탭의 '설정' 페이지에 있는 9개 항목이 모두 뽑기 관련임을 활용해, 누락된 4개
  (앞면 시작 · 카드 이름 · 한 줄 카드 수 · 카드 크기) 를 뽑기 탭 하단 설정 패널로
  옮긴다. 유저 탭의 '설정' 진입점은 비-뽑기 환경설정 전용 '앱 설정' 자리표시자로
  대체한다. 라우트·데이터 모델·프로바이더는 변경하지 않는다.
keywords: [settings, navigation, ia, mobile, draw, profile]
---

# 뽑기 설정 통합 — 유저/설정에서 뽑기 탭으로 메뉴 재배치

## Intent

사용자는 "뽑기에 관한 모든 설정을 뽑기 탭 한 곳에서 관리"하고 싶어 한다. 현재
설정이 두 곳(뽑기 홈의 인라인 패널 + 유저/설정 페이지)에 분산되어 있고, 유저/설정
페이지 항목이 사실상 모두 뽑기 관련이라 정보구조가 중복·혼란스럽다. 이를 정리하여:

1. 뽑기 관련 설정은 뽑기 탭 한 곳에 통합
2. 유저 탭의 '설정' 자리는 비-뽑기 환경설정 (테마/햅틱/알림 등) 을 위한 '앱 설정'
   자리표시자로 대체 (현 시점에는 비어 있어도 무방)
3. 유저 탭에는 뽑기 관련 설정이 일절 보이지 않게 함

## Context

### 현재 정보구조 (코드 기반)

| 위치 | 파일 | 항목 |
|------|------|------|
| 뽑기 탭 (홈 패널) | `mobile/lib/features/home/presentation/pages/home_page.dart` `_DrawSettingsPanel` | 덱 / 체험 레벨 / 기본 카드 수 / 기본 스프레드 / 역방향 (5개) |
| 유저 탭 → 설정 | `mobile/lib/features/profile/presentation/pages/profile_page.dart` `_MenuTile('설정')` → `/settings` | 진입점 |
| `/settings` 페이지 | `mobile/lib/features/settings/presentation/pages/settings_page.dart` | 덱 / 체험 레벨 / 기본 카드 수 / 앞면으로 시작 / 카드 이름 표시 / 역방향 / 한 줄 카드 수 / 기본 스프레드 / 카드 크기 (9개, 카드 크기는 `/settings/card-size` 별도 페이지로 진입) |

### 항목 분류 (모든 항목 뽑기 관련 여부)

| 항목 | 분류 | 홈 패널 | /settings | 비고 |
|------|------|---------|-----------|------|
| 덱 선택 | 뽑기 | O | O | 중복 |
| 체험 레벨 (즉시/연출/2D/2.5D) | 뽑기 | O | O | 중복 |
| 기본 카드 수 | 뽑기 | O | O | 중복 |
| 기본 스프레드 (1장/3장/자유) | 뽑기 | O | O | 중복 |
| 역방향 허용 | 뽑기 | O | O | 중복 |
| 앞면으로 시작 | 뽑기 | — | O | **이전 대상** |
| 카드 이름 표시 | 뽑기 | — | O | **이전 대상** |
| 한 줄 카드 수 (1/2/3) | 뽑기 (결과 그리드) | — | O | **이전 대상** |
| 카드 크기 (별도 페이지 진입) | 뽑기 | — | O (진입) | **이전 대상 — 진입점만 이동** |

비-뽑기 항목: **0개**.

### 데이터 / 프로바이더 (변경 불필요)

- `UserSettings` 모델: `selectedDeckId`, `experienceLevel`, `defaultCardCount`,
  `showFaceUp`, `showCardName`, `allowReversed`, `cardsPerRow`,
  `defaultSpreadType`, `cardSizePreset` — 9개 필드 모두 그대로 사용
- `userSettingsProvider`, `userSettingsRepositoryProvider`: 그대로 재사용
- `/settings/card-size` 라우트와 `CardSizeSettingsPage`: 그대로 유지

### 라우트 (변경 최소화)

- `/settings` (name: `settings`) — path/name 유지, 페이지 콘텐츠만 '앱 설정' 자리표시자로 교체
- `/settings/card-size` (name: `card-size-settings`) — 그대로 유지. 홈 패널에서 직접 진입
- 유저 탭의 `_MenuTile('설정')` → `_MenuTile('앱 설정')` 라벨/아이콘/서브타이틀 변경 (여전히 `pushNamed('settings')`)

## Boundaries

### In Scope

| # | Item | Description |
|---|------|-------------|
| 1 | 뽑기 탭 홈 패널에 4개 항목 추가 | 앞면으로 시작 · 카드 이름 표시 · 한 줄 카드 수 · 카드 크기(진입점). 기존 5개와 시각적으로 분리된 서브그룹("표시 옵션")으로 배치 |
| 2 | `/settings` 페이지를 '앱 설정' 자리표시자로 교체 | 기존 9개 항목 제거. 빈 상태 안내 ("준비 중인 환경설정 항목이 들어올 자리입니다" 정도) + 향후 카테고리 헤더 자리만 마련 |
| 3 | 유저 탭 `_MenuTile('설정')` → `_MenuTile('앱 설정')` | 라벨, 서브타이틀, 아이콘 갱신. 진입 라우트는 유지 (`pushNamed('settings')`) |
| 4 | 카드 크기 진입점을 홈 패널에 통합 | 기존 `/settings/card-size` 라우트로 직접 진입하는 ListTile 형태 (홈 패널 마지막 항목) |
| 5 | 라우트 / 데이터 모델 무변경 검증 | path/name/모델 필드/프로바이더 시그니처 모두 동일하게 유지되는지 grep으로 확인 |

### Out of Scope

| # | Item | Reason |
|---|------|--------|
| 1 | 새 비-뽑기 환경설정 항목 신규 도입 (테마/햅틱/알림/데이터 관리 등) | 사용자 요청은 메뉴 재배치이지 신규 기능이 아님. 자리표시자만 마련하고 콘텐츠는 별도 작업 |
| 2 | `CardSizeSettingsPage` 자체 변경 | 카드 크기 설정 UI는 그대로. 진입점만 이동 |
| 3 | `UserSettings` 모델/스키마/Drift 변경 | 필드 의미·이름·기본값 변경 없음. 이전은 UI 레이어에서만 발생 |
| 4 | `/settings` path/name 변경 또는 신규 라우트 | 기존 외부 참조(deeplink 등) 안전성을 위해 path 유지. 페이지 콘텐츠만 교체 |
| 5 | 뽑기 홈 패널의 시각 디자인 전면 개편 | 기존 `_SettingRow` / `_PillSelector` / `_GoldDropdown` 컴포넌트 재사용. 4개 항목 추가만 수행 |
| 6 | 유저 탭 다른 메뉴 (덱 관리 / 앱 정보) 변경 | 요청 범위 밖 |

## Decisions

| # | Decision | Chosen | Rationale | Trade-off | Alternatives Considered |
|---|----------|--------|-----------|-----------|------------------------|
| 1 | `/settings` 페이지 처리 방식 | **리네임 (path 유지, 콘텐츠 교체)** | 사용자가 명시적으로 "'설정'은 '앱 설정'으로 대체"라고 함 → 폐지가 아닌 의미 전환. path/name 유지로 라우트 그래프 안정성 확보 | '앱 설정' 페이지가 초기에는 거의 비어 있어 사용자 혼란 가능 (빈 화면 인상). 자리표시자 텍스트로 의도 전달하여 완화 | (a) `/settings` 라우트 완전 삭제 → 라우트 그래프 침범, 나중에 비-뽑기 설정 도입 시 재추가 필요 — 기각. (b) path도 `/app-settings`로 변경 → 외부 참조 깨짐 위험 + 작업 불필요 — 기각 |
| 2 | 9개 항목을 뽑기 홈에 평면 인라인 vs 접기/펼치기 vs 별도 진입 | **평면 인라인 + 서브그룹 분리 (기본/표시)** | 사용자 요청이 "뽑기 화면의 아래쪽으로 배치"로 인라인을 함의. 9개는 스크롤 가능한 패널에서 충분히 수용. 기존 `_DrawSettingsPanel`은 이미 스크롤 가능 영역에 위치 | 패널 세로 길이 증가로 최근 리딩 섹션이 한 번에 안 보일 수 있음. `_GoldHairline` 서브헤더로 시각적 호흡을 만들어 완화 | (a) 접기/펼치기(고급 옵션) → 메뉴 발견성 저하. 사용자가 "전부 한곳에"를 원함 — 기각. (b) "더 많은 설정" 진입 별도 페이지 → 다시 두 곳으로 분산되는 셈 — 기각 |
| 3 | 카드 크기 (별도 페이지 진입) 를 홈 패널 어디에 둘지 | **패널 마지막 행, ListTile 스타일 (chevron + 진입)** | 카드 크기는 다른 토글/픽커와 다르게 별도 페이지 인터랙션 → 행 형태도 차별화 필요. 마지막 위치는 "여기서 더 들어갈 수 있다"는 시각적 동선 자연스러움 | 패널 안에 두 가지 인터랙션 형태(즉시 변경 vs 페이지 이동)가 공존 → 약간의 일관성 손실. 그러나 ListTile + chevron으로 명시적 구분 | (a) 카드 크기도 인라인 단계 선택으로 변환 → 기존 `CardSizeSettingsPage` 재설계 비용 발생, Out of Scope — 기각. (b) 카드 크기를 패널에 두지 않고 유저/앱 설정에 둠 → 사용자 요청 위반 — 기각 |
| 4 | 앱 설정 페이지 초기 콘텐츠 | **자리표시자 1개 + "준비 중" 안내** | 비-뽑기 설정이 코드에 0개. 빈 화면보다 "환경설정 영역이 준비 중"임을 명시하면 사용자가 의도를 파악 가능. 향후 항목 추가 시 자연스럽게 확장 | 출시 시점에 거의 빈 페이지 → "왜 만들었지" 인상. 자리표시자 카피로 완화 | (a) 즉시 비-뽑기 설정 (테마/햅틱) 신규 추가 → Out of Scope #1 위반, 별도 기능 설계 필요 — 기각. (b) 페이지 자체를 만들지 않고 메뉴 타일도 제거 → 유저 탭에서 '설정' 흔적이 사라짐. 사용자 요청은 "대체"이지 "삭제"가 아님 — 기각 |
| 5 | 서브그룹 헤더 명칭 | **"기본 설정" / "표시 옵션"** | 기존 5개(덱·레벨·카드 수·스프레드·역방향)는 뽑기 행위 자체에 영향, 추가 4개(앞면·카드 이름·한 줄·카드 크기)는 결과 표시 방식. 의미 분류로 그룹화 | 카드 크기를 "표시 옵션"에 묶지만 사실은 카드 자체 크기(시각). 무리 없는 분류 | (a) "기본/고급" → 4개를 "고급"으로 분류하면 잘 안 보이게 만드는 인상 — 기각. (b) 그룹 없이 한 덩어리 → 9행이 평탄해서 인지 부담 — 기각 |

## Open Questions

| # | Question | Impact | Status |
|---|----------|--------|--------|
| (없음) | 모든 결정이 자율 결정으로 해소됨 | — | — |

## Constraints

- **데이터/모델 무변경**: `UserSettings` 필드, Drift 스키마, `userSettingsProvider`/`userSettingsRepositoryProvider` 시그니처 모두 동일하게 유지
- **라우트 path/name 유지**: `/settings`, `/settings/card-size`, `name: 'settings'`, `name: 'card-size-settings'` 모두 유지. `/settings`의 페이지 클래스 콘텐츠만 교체
- **컴포넌트 재사용**: 홈 패널의 `_SettingRow`, `_PillSelector`, `_GoldDropdown`, `_GoldSwitch`, `_CountStepper`, `_GoldHairline` 그대로 사용. 새 위젯 추가는 자리표시자/서브헤더에 한정
- **빌드 검증 필수**: 코드 수정 후 `flutter build apk --debug` 성공 확인 (CLAUDE.md 정책)
- **시각 검증**: ADB 스크린샷으로 (a) 뽑기 탭 패널 9행 + 서브헤더, (b) 유저 탭에 '앱 설정' 표시, (c) 앱 설정 페이지 자리표시자 확인

## Exit Criteria

- [x] 항목 분류표(모두 뽑기 관련) 확인 완료 → 결정 흐름 확정
- [x] 모든 Open Questions 자율 해소
- [x] In Scope 5개 항목 / Out of Scope 6개 항목 명세 완료
- [x] 라우트·데이터 무변경 제약 명시
- [ ] Quality Profile 확정 (Step 5b)
- [ ] Ideal Criteria 작성 완료 (Step 5b)

## Ideal Criteria

Quality Profile: **standard** (기본값 — Step 5b에서 사용자 응답에 따라 조정 가능)
Priority Dimensions: 미정 (Step 5b)

| # | Criterion | References (In Scope #) | Type | Dimension |
|---|-----------|------------------------|------|-----------|
| (Step 5b 완료 후 채워짐) | | | | |

## Model Anchors

- **Settings 통합 원칙**: 뽑기 관련 모든 설정은 단일 surface(뽑기 탭 홈 패널)에서 노출/조작한다. 유저 탭에서는 뽑기 관련 위젯이 0개여야 한다 (라벨·아이콘·subtitle 어디에도 "스프레드/카드/덱/레벨" 등의 표현이 등장하면 안 됨)
- **'앱 설정' 정의**: '앱 설정'은 비-뽑기 환경설정 전용 surface. 현 시점 콘텐츠는 자리표시자 1개. 향후 추가될 예시 카테고리 — 테마, 햅틱/사운드, 알림, 데이터 관리, 약관/정보. 이 Brief에서는 카테고리 자체도 추가하지 않고 빈 상태 안내만 둔다
- **라우트 보존**: `/settings` path와 name(`settings`)은 유지된다. `SettingsPage` 위젯 내부 구현만 교체된다. 외부에서 `pushNamed('settings')` 호출하는 코드는 모두 그대로 동작해야 한다
- **카드 크기 진입점**: 뽑기 홈 패널 마지막 행에 ListTile 스타일(chevron + 페이지 이동)로 배치한다. `context.push('/settings/card-size')` 호출 코드는 동일하게 유지
- **서브그룹 분리**: 뽑기 홈 패널은 두 그룹으로 분리된다 — (a) "기본 설정" 섹션 = 덱/레벨/카드 수/스프레드/역방향(5행), (b) "표시 옵션" 섹션 = 앞면 시작/카드 이름/한 줄 카드 수/카드 크기(4행). 그룹 사이는 `_GoldHairline` + 작은 헤더 텍스트로 시각 분리
- **컴포넌트 재사용 원칙**: 4개 신규 행은 기존 패널 위젯(`_SettingRow` + `_PillSelector` 또는 `_GoldSwitch`) 으로 구성한다. 새로운 디자인 토큰/스타일을 도입하지 않는다
- **데이터 변경 금지**: `UserSettings` 모델, Drift 마이그레이션, repository 메서드 시그니처는 일체 변경하지 않는다. 이전은 순수 위젯 트리 재배치
- **유저 탭 메뉴 라벨**: `_MenuTile`의 title은 `'앱 설정'`, subtitle은 비-뽑기를 암시하는 표현(예: `'앱 환경, 알림, 약관'` — 단, 실제 항목이 없으므로 `'환경설정'` 정도 중립 표현 권장), icon은 `Icons.settings_outlined` 등 일반 설정 아이콘 (현재 `Icons.tune_rounded`는 "조정/튜닝" 뉘앙스로 뽑기 설정과 의미 충돌 → 변경)

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 0s | 0 |
| 2 | user-ai-exchange | 0s | 0 |
| 3 | user-ai-exchange | 18s | 60949 |
| 4 | user-ai-exchange | 0s | 0 |
| 5 | user-ai-exchange | 59s | 146973 |
| 6 | user-ai-exchange | 642s | 1681853 |
| 7 | user-ai-exchange | 423s | 3654116 |
| 8 | user-ai-exchange | 0s | 0 |
| 9 | user-ai-exchange | 21s | 150544 |
| 10 | user-ai-exchange | 0s | 0 |
| 11 | user-ai-exchange | 39s | 463619 |
| 12 | user-ai-exchange | 207s | 355631 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 282874s |
| Total Tokens | 6513685 |
| Input Tokens | 133 |
| Output Tokens | 72433 |
| Cache Read | 5843386 |
| Cache Creation | 597733 |
