---
id: "015"
type: plan
title: "GoRouter 정리 — Cycle 1 구현 계획"
created: 2026-04-01
status: active
summary: >
  GoRouter 라우트 구조 정리 구현 계획. settings_fix Brief의 MA-3, MA-6 항목 대응.
references:
  - "007_Brief_settings_fix.md (MA-3, MA-6)"
  - "013_Research_impact_final.md"
  - "011_Agent_gorouter_impact.md"
---

# GoRouter 정리 — Cycle 1 구현 계획

## 목표

Brief MA-3과 MA-6에 따라 GoRouter의 설정 의존성을 제거하고
`quickDrawEnabled` dead feature UI를 삭제한다.

## 변경 파일

### 1. `mobile/lib/core/router/app_router.dart`

#### 제거 대상

| 위치 | 내용 |
|------|------|
| line 16 | `import '../../features/settings/presentation/providers/settings_providers.dart';` |
| line 14 | `import '../../features/reading/domain/entities/spread_type.dart';` (redirect에서만 사용) |
| line 35 | `final settings = ref.watch(userSettingsProvider).valueOrNull;` |
| lines 39–54 | `redirect: (context, state) { ... }` 블록 전체 |

#### 결과 구조

```dart
@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [ ... ],  // 기존 routes 그대로 유지
  );
}
```

- `ref` 파라미터는 `@riverpod` 매크로 시그니처이므로 유지
- `spread_type.dart` import는 `/reading/:deckId` 라우트의 `state.extra as SpreadType?` 에서도 사용되므로 **유지**

### 2. `mobile/lib/features/settings/presentation/pages/settings_page.dart`

#### 제거 대상

| 위치 | 내용 |
|------|------|
| lines 90–98 | `quickDrawEnabled` SwitchListTile 블록 전체 |

제거 대상 코드:
```dart
// 즉시 뽑기 토글
SwitchListTile(
  title: const Text('앱 시작 시 바로 뽑기'),
  subtitle: const Text('다음 실행부터 설정된 방식으로 자동 카드 뽑기'),
  value: settings.quickDrawEnabled,
  onChanged: (v) {
    ref.read(userSettingsRepositoryProvider)
        .updateQuickDrawEnabled(v);
  },
),
```

- entity/DB 필드(`quickDrawEnabled`)는 유지 (Brief: 별도 migration으로 추후 제거)
- 주변 코드(showFaceUp SwitchListTile, 기본 스프레드 섹션) 유지

## 검증

```bash
cd /Users/kampikrein/A/personality/mobile && \
dart analyze lib/core/router/app_router.dart lib/features/settings/presentation/pages/settings_page.dart
```

기대 결과: `No issues found!` 또는 기존 무관 경고만 존재.

## 영향 범위

- **GoRouter**: redirect 제거로 설정 변경 시 GoRouter 재생성 없음
- **settings_page**: quickDrawEnabled UI만 제거, 기능 로직 변경 없음
- **다른 파일**: 변경 없음 (Brief 지시에 따른 surgical 변경)

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 117s | 344643 |
| 2 | user-ai-exchange | 235s | 1232689 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 786s |
| Total Tokens | 1577332 |
| Input Tokens | 32 |
| Output Tokens | 25030 |
| Cache Read | 1459873 |
| Cache Creation | 92397 |
